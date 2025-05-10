import choire/cli/colored
import gleam/io

pub fn main() -> Nil {
  io.println(colored.red("Hello from colored!") <> " Hello")
  // walk everything except build directories
}
