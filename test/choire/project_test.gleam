import choire/internal/project.{DependencyName, DependencyVersion}
import gleam/list

pub fn gleam_project_parse_test() {
  let gleam_project = project.parse_gleam_project(".")

  assert gleam_project
    == Ok(project.GleamProject(
      ".",
      project.GleamToml(
        "choire",
        [
          project.Dependency(DependencyName("argv"), ">= 1.0.2 and < 2.0.0"),
          project.Dependency(DependencyName("filepath"), ">= 1.1.2 and < 2.0.0"),
          project.Dependency(
            DependencyName("gleam_crypto"),
            ">= 1.5.0 and < 2.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_erlang"),
            ">= 0.34.0 and < 2.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_fetch"),
            ">= 1.3.0 and < 2.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_http"),
            ">= 4.0.0 and < 5.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_httpc"),
            ">= 4.1.0 and < 5.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_json"),
            ">= 3.0.1 and < 4.0.0",
          ),
          project.Dependency(
            DependencyName("gleam_stdlib"),
            ">= 0.59.0 and < 2.0.0",
          ),
          project.Dependency(
            DependencyName("simplifile"),
            ">= 2.2.1 and < 3.0.0",
          ),
          project.Dependency(DependencyName("tom"), ">= 2.0.0 and < 3.0.0"),
        ],
        [project.Dependency(DependencyName("gleeunit"), ">= 1.0.0 and < 2.0.0")],
      ),
      project.Manifest("./manifest.toml", [
        project.ManifestPackage(
          DependencyName("argv"),
          DependencyVersion("1.0.2"),
          [],
        ),
        project.ManifestPackage(
          DependencyName("filepath"),
          DependencyVersion("1.1.2"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_crypto"),
          DependencyVersion("1.5.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_erlang"),
          DependencyVersion("0.34.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_fetch"),
          DependencyVersion("1.3.0"),
          [
            DependencyName("gleam_http"),
            DependencyName("gleam_javascript"),
            DependencyName("gleam_stdlib"),
          ],
        ),
        project.ManifestPackage(
          DependencyName("gleam_http"),
          DependencyVersion("4.0.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_httpc"),
          DependencyVersion("4.1.1"),
          [
            DependencyName("gleam_erlang"),
            DependencyName("gleam_http"),
            DependencyName("gleam_stdlib"),
          ],
        ),
        project.ManifestPackage(
          DependencyName("gleam_javascript"),
          DependencyVersion("1.0.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_json"),
          DependencyVersion("3.0.1"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleam_stdlib"),
          DependencyVersion("0.60.0"),
          [],
        ),
        project.ManifestPackage(
          DependencyName("gleam_time"),
          DependencyVersion("1.2.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("gleeunit"),
          DependencyVersion("1.4.0"),
          [DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("simplifile"),
          DependencyVersion("2.2.1"),
          [DependencyName("filepath"), DependencyName("gleam_stdlib")],
        ),
        project.ManifestPackage(
          DependencyName("tom"),
          DependencyVersion("2.0.0"),
          [DependencyName("gleam_stdlib"), DependencyName("gleam_time")],
        ),
      ]),
    ))
}

pub fn exact_dep_version_test() {
  let assert Ok(project) = project.parse_gleam_project(".")
  let deps = project.toml.deps

  let assert Ok(argv) =
    list.find(deps, fn(dep) { dep.name == DependencyName("argv") })
  assert project.exact_dep_version(project, argv)
    == Ok(DependencyVersion("1.0.2"))

  let assert Ok(simplifile) =
    list.find(deps, fn(dep) { dep.name == DependencyName("simplifile") })
  assert project.exact_dep_version(project, simplifile)
    == Ok(DependencyVersion("2.2.1"))
}
