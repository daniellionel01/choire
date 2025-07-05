import choire/internal/project
import gleam/list

pub fn gleam_project_parse_test() {
  let gleam_project = project.parse_gleam_project(".")

  assert gleam_project
    == Ok(project.GleamProject(
      project.GleamToml(
        "choire",
        [
          project.Dependency("argv", ">= 1.0.2 and < 2.0.0"),
          project.Dependency("filepath", ">= 1.1.2 and < 2.0.0"),
          project.Dependency("gleam_crypto", ">= 1.5.0 and < 2.0.0"),
          project.Dependency("gleam_erlang", ">= 0.34.0 and < 2.0.0"),
          project.Dependency("gleam_fetch", ">= 1.3.0 and < 2.0.0"),
          project.Dependency("gleam_http", ">= 4.0.0 and < 5.0.0"),
          project.Dependency("gleam_httpc", ">= 4.1.0 and < 5.0.0"),
          project.Dependency("gleam_json", ">= 3.0.1 and < 4.0.0"),
          project.Dependency("gleam_stdlib", ">= 0.59.0 and < 2.0.0"),
          project.Dependency("simplifile", ">= 2.2.1 and < 3.0.0"),
          project.Dependency("tom", ">= 2.0.0 and < 3.0.0"),
        ],
        [project.Dependency("gleeunit", ">= 1.0.0 and < 2.0.0")],
      ),
      project.Manifest("./manifest.toml", [
        project.ManifestPackage("argv", "1.0.2"),
        project.ManifestPackage("filepath", "1.1.2"),
        project.ManifestPackage("gleam_crypto", "1.5.0"),
        project.ManifestPackage("gleam_erlang", "0.34.0"),
        project.ManifestPackage("gleam_fetch", "1.3.0"),
        project.ManifestPackage("gleam_http", "4.0.0"),
        project.ManifestPackage("gleam_httpc", "4.1.1"),
        project.ManifestPackage("gleam_javascript", "1.0.0"),
        project.ManifestPackage("gleam_json", "3.0.1"),
        project.ManifestPackage("gleam_stdlib", "0.60.0"),
        project.ManifestPackage("gleam_time", "1.2.0"),
        project.ManifestPackage("gleeunit", "1.4.0"),
        project.ManifestPackage("simplifile", "2.2.1"),
        project.ManifestPackage("tom", "2.0.0"),
      ]),
    ))
}

pub fn exact_dep_version_test() {
  let assert Ok(project) = project.parse_gleam_project(".")
  let deps = project.toml.deps

  let assert Ok(argv) = list.find(deps, fn(dep) { dep.name == "argv" })
  assert project.exact_dep_version(project, argv) == Ok("1.0.2")

  let assert Ok(simplifile) =
    list.find(deps, fn(dep) { dep.name == "simplifile" })
  assert project.exact_dep_version(project, simplifile) == Ok("2.2.1")
}
