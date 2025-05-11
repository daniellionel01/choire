import filepath
import gleam/bool
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import simplifile

/// Finds all `gleam.toml` directories and lists the full path files
/// https://github.com/giacomocavalieri/squirrel/blob/main/src/squirrel.gleam
///
pub fn walk(from: String) -> Dict(String, List(String)) {
  let matches = case filepath.base_name(from) {
    "build" | "node_modules" | ".git" -> dict.new()
    _ -> {
      let assert Ok(files) = simplifile.read_directory(from)
      let files = {
        use file <- list.filter_map(files)
        use <- bool.guard(when: file != "gleam.toml", return: Error(Nil))
        let file_name = filepath.join(from, file)
        case simplifile.is_file(file_name) {
          Ok(True) -> Ok(file_name)
          Ok(False) | Error(_) -> Error(Nil)
        }
      }
      dict.from_list([#(from, files)])
    }
  }

  let assert Ok(files) = simplifile.read_directory(from)
  let directories = {
    use file <- list.filter_map(files)
    let file_name = filepath.join(from, file)
    case
      file_name,
      string.contains(file_name, "build"),
      string.contains(file_name, "node_modules"),
      string.contains(file_name, ".git")
    {
      file_name, False, False, False ->
        case simplifile.is_directory(file_name) {
          Ok(True) -> Ok(file_name)
          Ok(False) | Error(_) -> Error(Nil)
        }
      _, _, _, _ -> Error(Nil)
    }
  }

  list.map(directories, walk)
  |> list.fold(from: dict.new(), with: dict.merge)
  |> dict.merge(matches)
}
