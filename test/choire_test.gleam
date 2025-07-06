import choire/internal/cmd
import choire/internal/project.{DependencyName}
import filepath
import gleam/bit_array
import gleam/crypto
import gleam/dict
import gleam/list
import gleam/string
import gleeunit
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn create_and_run_gleam_project_test() {
  use dir <- with_tmp_dir()

  let pkg_a = filepath.join(dir, "sample_a")
  create_gleam_app(dir, "sample_a")

  let run =
    cmd.exec(run: "gleam", with: ["run", "--no-print-progress"], in: pkg_a)
  assert run == Ok("Hello from app!\n")
}

pub fn no_mismatches_test() {
  use dir <- with_tmp_dir()

  let pkg_a = filepath.join(dir, "sample_a")
  let pkg_b = filepath.join(dir, "sample_b")

  create_gleam_app(dir, "sample_a")
  create_gleam_app(dir, "sample_b")

  install_gleam_dep(pkg_a, "lustre")
  install_gleam_dep(pkg_b, "lustre")

  let assert Ok(project_a) = project.parse_gleam_project(pkg_a)
  let assert Ok(project_b) = project.parse_gleam_project(pkg_b)

  let lookup = project.dependency_version_lookup([project_a, project_b])

  let mismatches = project.mismatched_dependencies(lookup)
  assert mismatches == []
}

pub fn mismatched_dependency_test() {
  use dir <- with_tmp_dir()

  let pkg_a = filepath.join(dir, "sample_a")
  let pkg_b = filepath.join(dir, "sample_b")

  create_gleam_app(dir, "sample_a")
  create_gleam_app(dir, "sample_b")

  install_gleam_dep(pkg_a, "lustre@4")
  install_gleam_dep(pkg_b, "lustre@5")

  let assert Ok(project_a) = project.parse_gleam_project(pkg_a)
  let assert Ok(project_b) = project.parse_gleam_project(pkg_b)

  let lookup = project.dependency_version_lookup([project_a, project_b])

  let mismatches = project.mismatched_dependencies(lookup)
  assert mismatches == [DependencyName("lustre")]
}

pub fn version_conflict_test() {
  use dir <- with_tmp_dir()

  let pkg_a = filepath.join(dir, "sample_a")
  let pkg_b = filepath.join(dir, "sample_b")

  create_gleam_app(dir, "sample_a")
  create_gleam_app(dir, "sample_b")

  install_gleam_dep(pkg_a, "lustre@4")
  install_gleam_dep(pkg_b, "lustre@5")

  let assert Ok(project_a) = project.parse_gleam_project(pkg_a)
  let assert Ok(project_b) = project.parse_gleam_project(pkg_b)

  todo
}

// === UTILITIES ===

fn create_gleam_app(parent_dir: String, name: String) {
  let assert Ok(_) =
    cmd.exec(run: "gleam", with: ["new", name, "--name", "app"], in: parent_dir)
  Nil
}

fn install_gleam_dep(dir: String, dependency: String) {
  let assert Ok(_) = cmd.exec(run: "gleam", with: ["add", dependency], in: dir)
  Nil
}

fn with_tmp_dir(callback: fn(String) -> Nil) {
  let random =
    crypto.strong_random_bytes(8)
    |> bit_array.base16_encode
    |> string.lowercase

  let dir = "/tmp/choire_test_" <> random
  let assert Ok(_) = simplifile.create_directory_all(dir)

  let _ = callback(dir)

  simplifile.delete_all([dir])
}
