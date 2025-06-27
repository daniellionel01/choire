import choire/internal/cmd
import filepath
import gleam/bit_array
import gleam/crypto
import gleam/string
import gleeunit
import simplifile

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
}
