//// Copy pasted from https://github.com/giacomocavalieri/squirrel/blob/main/src/squirrel/internal/project.gleam
//// Thank you https://www.github.com/giacomocavalieri
////

import filepath
import gleam/dict
import gleam/list
import gleam/result
import simplifile
import tom

pub fn root() -> String {
  find_root(".")
}

pub fn src() -> String {
  filepath.join(root(), "src")
}

fn find_root(path: String) -> String {
  let toml = filepath.join(path, "gleam.toml")

  case simplifile.is_file(toml) {
    Ok(False) | Error(_) -> find_root(filepath.join("..", path))
    Ok(True) -> path
  }
}

pub type GleamProjectError {
  ParseError(tom.ParseError)
  FileError(simplifile.FileError)
}

pub fn parse_gleam_project(
  root_path: String,
) -> Result(GleamProject, GleamProjectError) {
  let toml_path = filepath.join(root_path, "gleam.toml")
  let manifest_path = filepath.join(root_path, "manifest.toml")

  use toml <- result.try(
    result.map_error(simplifile.read(toml_path), fn(e) { FileError(e) }),
  )
  use toml <- result.try(
    result.map_error(tom.parse(toml), fn(e) { ParseError(e) }),
  )

  let assert Ok(tom.String(name)) = dict.get(toml, "name")

  let dev_deps: List(Dependency) =
    case dict.get(toml, "dev-dependencies") {
      Error(_) -> dict.new()
      Ok(tom.Table(e)) -> e
      Ok(tom.InlineTable(e)) -> e
      Ok(_) -> dict.new()
    }
    |> dict.to_list()
    |> list.map(fn(dep) {
      let name = DependencyName(dep.0)
      let assert tom.String(constraint) = dep.1
      Dependency(name:, constraint:)
    })
  let deps =
    case dict.get(toml, "dependencies") {
      Error(_) -> dict.new()
      Ok(tom.Table(e)) -> e
      Ok(tom.InlineTable(e)) -> e
      Ok(_) -> dict.new()
    }
    |> dict.to_list()
    |> list.map(fn(dep) {
      let name = DependencyName(dep.0)
      let assert tom.String(constraint) = dep.1
      Dependency(name:, constraint:)
    })

  let toml = GleamToml(name:, deps:, dev_deps:)

  use manifest <- result.try(
    result.map_error(simplifile.read(manifest_path), fn(e) { FileError(e) }),
  )
  use manifest <- result.try(
    result.map_error(tom.parse(manifest), fn(e) { ParseError(e) }),
  )
  let assert Ok(tom.Array(tables)) = dict.get(manifest, "packages")
  let manifest_pkgs: List(ManifestPackage) =
    tables
    |> list.map(fn(table) {
      let assert tom.InlineTable(table) = table
      let assert Ok(tom.String(name)) = dict.get(table, "name")
      let assert Ok(tom.String(version)) = dict.get(table, "version")
      let assert Ok(tom.Array(requirements)) = dict.get(table, "requirements")
      let requirements =
        list.map(requirements, fn(requirement) {
          let assert tom.String(requirement) = requirement
          DependencyName(requirement)
        })

      let name = DependencyName(name)
      let version = DependencyVersion(version)
      ManifestPackage(name:, version:, requirements:)
    })

  let manifest = Manifest(manifest_path, manifest_pkgs)

  let project = GleamProject(root_path:, toml:, manifest:)

  Ok(project)
}

pub fn exact_dep_version(
  project: GleamProject,
  dep: Dependency,
) -> Result(DependencyVersion, Nil) {
  let package =
    list.find(project.manifest.packages, fn(pkg) { pkg.name == dep.name })
  case package {
    Error(_) -> Error(Nil)
    Ok(pkg) -> Ok(pkg.version)
  }
}

/// Given a gleam project's manifest, we can cross reference dependency versions
/// and figure out wether or not the constraints of a package that we might want to
/// upgrade will conflict with any other package constraints.
pub fn conflicting_constraints(
  project: GleamProject,
  dependency_name: DependencyName,
  dependency_constraints: Constraints,
) -> Constraints {
  // go through project manifest packages
  // filter packages that have the dependencies in the constraints as requirements
  //   (but is not the dependency to be upgraded)
  // fetch constraints of those packages
  // validate that latest version will not conflict with any of those constraints

  let package_constraints = dict.new()

  dependency_constraints
  |> dict.to_list()
  |> list.filter(fn(constraint) {
    let #(name, version) = constraint

    let package =
      list.find(project.manifest.packages, fn(pck) { pck.name == name })

    case package {
      Error(_) -> False
      Ok(package) -> {
        todo
      }
    }
  })
  |> dict.from_list()

  todo
}

pub fn mismatched_dependencies(
  lookup: DependencyVersionLookup,
) -> List(DependencyName) {
  lookup
  |> dict.to_list()
  |> list.filter_map(fn(entry) {
    let #(name, projects_with_version) = entry

    let versions =
      list.map(projects_with_version, fn(pv) { pv.1 })
      |> list.unique()

    case versions {
      [_] -> Error(Nil)
      _ -> Ok(name)
    }
  })
}

pub fn dependency_version_lookup(
  projects: List(GleamProject),
) -> DependencyVersionLookup {
  let dependency_names =
    projects
    |> list.flat_map(fn(project) {
      list.append(project.toml.deps, project.toml.dev_deps)
    })
    |> list.map(fn(dep) { dep.name })
    |> list.unique()

  dependency_names
  |> list.map(fn(name) {
    let projects_with_version =
      list.filter_map(projects, fn(project) {
        let deps = list.append(project.toml.deps, project.toml.dev_deps)
        let dep = list.find(deps, fn(dep) { dep.name == name })
        case dep {
          Error(_) -> Error(Nil)
          Ok(dep) -> {
            let assert Ok(version) = exact_dep_version(project, dep)
            Ok(#(project, version))
          }
        }
      })

    #(name, projects_with_version)
  })
  |> list.filter(fn(tup) {
    case tup.1 {
      [] -> False
      _ -> True
    }
  })
  |> dict.from_list()
}

pub type Constraints =
  dict.Dict(DependencyName, DependencyVersion)

pub type DependencyVersionLookup =
  dict.Dict(DependencyName, List(#(GleamProject, DependencyVersion)))

pub type DependencyName {
  DependencyName(value: String)
}

pub type DependencyVersion {
  DependencyVersion(value: String)
}

pub type GleamProject {
  GleamProject(root_path: String, toml: GleamToml, manifest: Manifest)
}

pub type GleamToml {
  GleamToml(name: String, deps: List(Dependency), dev_deps: List(Dependency))
}

pub type Dependency {
  Dependency(name: DependencyName, constraint: String)
}

pub type ManifestPackage {
  ManifestPackage(
    name: DependencyName,
    version: DependencyVersion,
    requirements: List(DependencyName),
  )
}

pub type Manifest {
  Manifest(path: String, packages: List(ManifestPackage))
}
