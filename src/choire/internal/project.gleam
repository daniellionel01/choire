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
      let name = dep.0
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
      let name = dep.0
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
      ManifestPackage(name:, version:)
    })

  let manifest = Manifest(manifest_path, manifest_pkgs)

  let project = GleamProject(toml:, manifest:)

  Ok(project)
}

pub fn exact_dep_version(
  project: GleamProject,
  dep: Dependency,
) -> Result(String, Nil) {
  let package =
    list.find(project.manifest.packages, fn(pkg) { pkg.name == dep.name })
  case package {
    Error(_) -> Error(Nil)
    Ok(pkg) -> Ok(pkg.version)
  }
}

pub type GleamProject {
  GleamProject(toml: GleamToml, manifest: Manifest)
}

pub type GleamToml {
  GleamToml(name: String, deps: List(Dependency), dev_deps: List(Dependency))
}

pub type Dependency {
  Dependency(name: String, constraint: String)
}

pub type ManifestPackage {
  ManifestPackage(name: String, version: String)
}

pub type Manifest {
  Manifest(path: String, packages: List(ManifestPackage))
}
