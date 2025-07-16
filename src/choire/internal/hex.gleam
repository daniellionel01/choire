import choire/internal/cli/colored
import choire/internal/project.{
  type DependencyName, type DependencyVersion, DependencyName, DependencyVersion,
}
import gleam/dict
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result

@external(erlang, "Elixir.Version", "match?")
pub fn version_matches_constraint(version: String, constraint: String) -> Bool

pub fn fetch_constraints(
  name: DependencyName,
  version: DependencyVersion,
) -> Result(project.Constraints, Nil) {
  let name = name.value
  let version = version.value

  let assert Ok(req) =
    request.to(
      "https://www.hex.pm/api/packages/" <> name <> "/releases/" <> version,
    )
  use resp <- result.try(httpc.send(req) |> result.replace_error(Nil))

  use rl_remaining_header <- result.try(response.get_header(
    resp,
    "x-ratelimit-remaining",
  ))
  let rl_remaining = case int.parse(rl_remaining_header) {
    Error(_) -> 0
    Ok(e) -> e
  }
  case rl_remaining {
    0 -> {
      "got ratelimited by hex api. waiting 60 seconds..."
      |> colored.yellow()
      |> io.println()
      process.sleep(60_000)
    }
    _ -> Nil
  }

  let requirements_decoder = {
    use requirement <- decode.field("requirement", decode.string)
    decode.success(requirement)
  }
  let decoder = {
    use requirements <- decode.field(
      "requirements",
      decode.dict(decode.string, requirements_decoder),
    )
    decode.success(requirements)
  }
  use requirements <- result.try(
    json.parse(resp.body, decoder)
    |> result.replace_error(Nil),
  )
  let requirements = dict.to_list(requirements)

  list.map(requirements, fn(r) {
    let #(name, version) = r
    #(DependencyName(name), DependencyVersion(version))
  })
  |> dict.from_list()
  |> Ok()
}

pub fn fetch_version(name: DependencyName) -> Result(String, Nil) {
  let name = name.value

  let assert Ok(req) = request.to("https://www.hex.pm/api/packages/" <> name)
  use resp <- result.try(httpc.send(req) |> result.replace_error(Nil))

  use rl_remaining_header <- result.try(response.get_header(
    resp,
    "x-ratelimit-remaining",
  ))
  let rl_remaining = case int.parse(rl_remaining_header) {
    Error(_) -> 0
    Ok(e) -> e
  }
  case rl_remaining {
    0 -> {
      "got ratelimited by hex api. waiting 60 seconds..."
      |> colored.yellow()
      |> io.println()
      process.sleep(60_000)
    }
    _ -> Nil
  }

  let decoder = {
    use latest_version <- decode.field("latest_stable_version", decode.string)
    decode.success(latest_version)
  }
  use version <- result.try(
    json.parse(resp.body, decoder)
    |> result.replace_error(Nil),
  )

  Ok(version)
}
