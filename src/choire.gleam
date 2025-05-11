import choire/cli/colored
import choire/files
import gleam/dict
import gleam/io
import gleam/list

pub fn main() -> Nil {
  io.println(colored.yellow("Hello from colored!") <> " Hello")

  let tomls =
    files.walk(".")
    |> dict.to_list()
    |> list.filter(fn(dic) {
      let #(_, files) = dic
      case files {
        [] -> False
        _ -> True
      }
    })
  echo tomls

  // todo as throw warning if package has no manifest.toml
  // todo errors: hex ratelimiting

  Nil
}
