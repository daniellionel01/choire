import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn hello_world_test() {
  1
  |> should.equal(1)
}
