import argv
import choire/internal/cli/colored
import choire/internal/files
import choire/internal/hex
import choire/internal/project.{
  type DependencyName, type DependencyVersion, type ManifestPackage,
  DependencyName, DependencyVersion, ManifestPackage,
}
import filepath
import gleam/bool
import gleam/dict
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import simplifile
import tom

const usage = "Usage:
  gleam run -m choire help
  gleam run -m choire
  gleam run -m choire <path>
"

pub fn main() -> Nil {
  case argv.load().arguments {
    [] -> run(".")
    ["help"] -> io.println(usage)
    [path] -> run(path)
    _ -> io.println(usage)
  }
  Nil
}

pub fn run(path: String) -> Nil {
  // we walk from the current directory to look for all directories
  // that contain a gleam.toml file
  // (we skip dirs like 'build' or '.git')
  let gleam_tomls =
    files.walk(path)
    |> dict.to_list()
    |> list.filter(fn(dic) {
      // filter out dirs with no gleam.toml
      let #(_, files) = dic
      case files {
        [] -> False
        _ -> True
      }
    })
    |> list.map(fn(dic) {
      // we assert that there's only one gleam.toml
      // file inside of each dir
      let #(_, files) = dic
      let assert [path] = files
      path
    })

  // We now need to look through all directories with a gleam.toml
  // and check if they have a manifest.toml and put them together
  let packages =
    gleam_tomls
    |> list.map(fn(toml) {
      let path =
        toml
        |> filepath.directory_name()
        |> filepath.join("manifest.toml")
      #(toml, path)
    })
    |> list.filter_map(fn(paths) {
      let #(toml, manifest) = paths
      case simplifile.is_file(manifest) {
        Error(_) -> Error(Nil)
        Ok(False) -> Error(Nil)
        Ok(True) -> Ok(Package(toml, manifest))
      }
    })

  // we create a dict that maps every package we found (as in a directory
  // that has a manifest.toml) with all of its dependencies and versions
  let dep_map: DepMap =
    packages
    |> list.map(fn(package) {
      let Package(toml_path, manifest_path) = package

      // Parse gleam.toml
      use toml <- result.try(
        result.map_error(simplifile.read(toml_path), fn(e) {
          Error(FileError(e))
        }),
      )
      use toml <- result.try(
        result.map_error(tom.parse(toml), fn(e) { Error(ParseError(e)) }),
      )

      // Parse manifest.toml
      use manifest <- result.try(
        result.map_error(simplifile.read(manifest_path), fn(e) {
          Error(FileError(e))
        }),
      )
      use manifest <- result.try(
        result.map_error(tom.parse(manifest), fn(e) { Error(ParseError(e)) }),
      )

      // we parse all of the versions for the deps in the manifest.toml
      let assert Ok(tom.Array(tables)) = dict.get(manifest, "packages")
      let manifest_deps: List(ManifestPackage) =
        tables
        |> list.map(fn(table) {
          let assert tom.InlineTable(table) = table
          let assert Ok(tom.String(name)) = dict.get(table, "name")
          let assert Ok(tom.String(version)) = dict.get(table, "version")
          ManifestPackage(DependencyName(name), DependencyVersion(version))
        })

      // we parse all of the deps in the gleam.toml
      let gleam_dev_deps = case dict.get(toml, "dev-dependencies") {
        Error(_) -> dict.new()
        Ok(tom.Table(e)) -> e
        Ok(tom.InlineTable(e)) -> e
        Ok(_) -> dict.new()
      }
      let gleam_deps = case dict.get(toml, "dependencies") {
        Error(_) -> dict.new()
        Ok(tom.Table(e)) -> e
        Ok(tom.InlineTable(e)) -> e
        Ok(_) -> dict.new()
      }

      // since the manifest.toml also contains the transitive deps
      // (as in all deps of our deps) we only want to include
      // the deps found in our gleam.toml
      let deps =
        manifest_deps
        |> list.filter(fn(dep) {
          let name = dep.name.value
          dict.has_key(gleam_dev_deps, name) || dict.has_key(gleam_deps, name)
        })

      Ok(#(package, deps))
    })
    |> list.filter_map(function.identity)
    |> dict.from_list

  let info_packages = dep_map |> dict.keys |> list.length |> int.to_string()
  io.println("")
  io.println("> found " <> info_packages <> " packages")
  io.println("")

  // we're now going to look for packages that share the same dep
  // but have different versions in their respective manifest.toml

  // for this we'll create an inverted dict of our dep map
  // where we have the dep name as the key and the packages with
  // version that use it as the value
  let inverted_dep_map: InvDepMap =
    dep_map
    |> dict.to_list()
    |> list.map(fn(map) {
      let #(pck, deps) = map
      list.map(deps, fn(dep) { #(dep, pck) })
    })
    |> list.flatten()
    |> list.fold(dict.new(), fn(acc, cur) {
      let #(dep, pck) = cur
      let ex = case dict.get(acc, dep.name) {
        Error(_) -> []
        Ok(v) -> v
      }
      let entry = #(pck, dep.version)
      dict.insert(acc, dep.name, [entry, ..ex])
    })

  let res_mismatches =
    inverted_dep_map
    |> dict.to_list()
    |> list.fold(0, fn(acc, dep) {
      let #(dep_name, usage) = dep

      let versions =
        usage
        |> list.map(fn(u) { u.1 })
        |> list.unique()

      // only 1 version is used across packages -> we're fine
      use <- bool.guard(when: list.length(versions) <= 1, return: acc)

      let name = dep_name.value
      io.println("> found a mismatch for: " <> colored.red(name))
      list.each(usage, fn(u) {
        let v = { u.1 }.value
        io.println("  v" <> v <> " (" <> { u.0 }.gleam_toml_path <> ")")
      })
      io.println("")

      acc + 1
    })
  case res_mismatches {
    0 -> {
      io.println(colored.green("no mismatched dependencies found"))
      io.println("")
    }
    _ -> Nil
  }

  // we're now going to look for outdated deps by checking for the latest
  // version via the hex api

  // to prevent fetching a dependency multiple times, we'll fetch every latest
  // version beforehand so we can reuse it in our outdated check

  io.println(colored.yellow("fetching latest stable dependency versions..."))
  io.println("")

  let dep_latest_versions =
    inverted_dep_map
    |> dict.keys()
    |> list.map(fn(dep_name) {
      use version <- result.try(hex.fetch_version(dep_name))
      Ok(#(dep_name, version))
    })
    |> list.filter_map(function.identity)
    |> dict.from_list

  let outdated =
    dep_map
    |> dict.to_list
    |> list.map(fn(entry) {
      list.filter_map(entry.1, fn(dep) {
        case dict.get(dep_latest_versions, dep.name) {
          Error(_) -> Error(Nil)
          Ok(latest) -> {
            let v = dep.version.value
            case v != latest {
              False -> Error(Nil)
              True -> Ok(#(entry.0, dep, latest))
            }
          }
        }
      })
    })
    |> list.unique()
    |> list.flatten()

  let res_outdated =
    dep_map
    |> dict.to_list
    |> list.fold(0, fn(acc, entry) {
      let outdated_deps = list.filter(outdated, fn(tup) { entry.0 == tup.0 })

      // no need to print anything if there are no outdated deps
      let has_outdated = case outdated_deps {
        [] -> False
        _ -> True
      }
      use <- bool.guard(when: !has_outdated, return: acc)

      io.println(
        "> found "
        <> int.to_string(list.length(outdated_deps))
        <> " upgradable dependencies in "
        <> { entry.0 }.gleam_toml_path,
      )
      list.each(outdated_deps, fn(dated) {
        let #(_, dep, latest) = dated
        let name = dep.name.value
        let v = dep.version.value
        io.println("  " <> colored.red(name) <> " v" <> v <> " -> v" <> latest)
      })
      io.println("")
      acc + 1
    })
  case res_outdated {
    0 -> io.println(colored.green("no outdated dependencies found"))
    _ -> Nil
  }
  io.println("")

  // we are now going to check wether potential new versions would violate any
  // version constraints of (traverse) dependencies:
  // 1. we look at what dependencies can be upgraded
  // 2. we parse the requirements of the packages of those dependencies
  // 3. we check if our upgradable package appears in any of the other package dependencies
  // 4. if not, we're clear. if it does, we have to check if the new version would violate the version constraints

  // let outdated_by_pkg =
  //   outdated
  //   |> list.group(fn(entry) { entry.0 })
  //   |> dict.to_list()

  // list.each(outdated_by_pkg, fn(group) {
  //   list.each(group.1, fn(entry) {
  //     let #(pkg, dep, latest) = entry

  //     let manifest = pkg.manifest_toml_path
  //   })
  // })
  // io.println("")

  Nil
}

pub type Error {
  FileError(simplifile.FileError)
  ParseError(tom.ParseError)
}

pub type Package {
  Package(gleam_toml_path: String, manifest_toml_path: String)
}

pub type DepMap =
  dict.Dict(Package, List(ManifestPackage))

pub type InvDepMap =
  dict.Dict(DependencyName, List(#(Package, DependencyVersion)))

pub type VersionMismatch {
  VersionMismatch(
    package_a: String,
    package_b: String,
    dep_name: DependencyName,
  )
}
