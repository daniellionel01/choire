import choire/internal/hex
import choire/internal/project.{DependencyName, DependencyVersion}
import gleam/dict

pub fn fetch_version_test() {
  assert hex.fetch_version(DependencyName("sqlc_gen_gleam")) == Ok("0.0.1")
}

pub fn fetch_constraints_test() {
  assert hex.fetch_constraints(
      DependencyName("wayfinder"),
      DependencyVersion("1.2.1"),
    )
    == Ok(dict.from_list([#("gleam_stdlib", ">= 0.44.0 and < 2.0.0")]))
}

pub fn version_matches_constraint_test() {
  assert hex.version_matches_constraint("2.0.0", "> 1.0.0") == True
  assert hex.version_matches_constraint("2.0.0", "== 1.0.0") == False
  assert hex.version_matches_constraint("2.1.6-dev", ">= 2.1.2 and < 2.2.0")
    == True
}

pub fn match_fetched_constraints_test() {
  let assert Ok(constraints) =
    hex.fetch_constraints(
      DependencyName("wayfinder"),
      DependencyVersion("1.2.1"),
    )
  let assert [#("gleam_stdlib", constraints)] = dict.to_list(constraints)

  assert hex.version_matches_constraint("1.0.0", constraints) == True
}
