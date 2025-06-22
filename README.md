# 🎶 Choire - gleam dependency tooling

[![Package Version](https://img.shields.io/hexpm/v/choire)](https://hex.pm/packages/choire)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/choire/)
![erlang](https://img.shields.io/badge/target-erlang-a2003e)

## Introduction

Choire works in a gleam monorepo or singular project. It does multiple things for you:
- Check for outdated dependencies
- Check for different version of the same dependency across different gleam apps
- Check if there will be a version conflict, if you want to upgrade a dependency

Importantly, this package does not perform any modifications or updates for you.
This design is intentional as to not mess up your project in any way.

## Usage

```sh
$ gleam add choire@1 --dev
```

```sh
$ gleam run -m choire    # runs in current directory
$ gleam run -m choire .. # runs in parent directory
```

## Example

```sh
$ gleam run -m choire

> found 3 packages

> found a mismatch for: lustre
  v5.0.3 (./sample/sample_b/gleam.toml)
  v4.6.4 (./sample/sample_a/gleam.toml)

fetching latest stable dependency versions...

> found 1 upgradable dependencies in ./sample/sample_a/gleam.toml
  lustre v4.6.4 -> v5.0.3

```

## Hex API and Ratelimits

At the time of this writing, you can make 100 requests per minute to the HEX api as an
unauthenticated user and 500 per minute as an authenticated user
(https://hexpm.docs.apiary.io/#introduction/rate-limiting).

Since the limit resets after 60 seconds, this library will simply hold and wait for the limit
to reset and then continue fetching the package information.

## Acknowledgements

- This package was heavily inspired by https://github.com/QuiiBz/sherif.

## Future Work

- [ ] spinner during step
- [ ] "can i upgrade?" - attempts to find out if traverse dependency will conflict
- [ ] attempt to fetch changelog of dependencies
- [ ] support `--json` flag
- [ ] support javascript target
- [ ] support custom hex api key
- [ ] cache latest dependency version for 24h
  - [ ] `--force` to ignore cache
- [ ] additional configuration
  - [ ] log level
  - [ ] include exclude patterns
  - [ ] toggle dev deps
