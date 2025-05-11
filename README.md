# 🎶 Choire - gleam dependency tooling

[![Package Version](https://img.shields.io/hexpm/v/choire)](https://hex.pm/packages/choire)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/choire/)

## Introduction

**FYI: works for both javascript and erlang target!**

Choire works in a gleam monorepo or singular project. It does two things for you:
- Check for outdated dependencies
- Check for different version of the same dependency across different gleam apps

Importantly, this package does not perform any modifications or updates for you.
This design is intentional as to not mess up your project in any way.

## Usage

```sh
$ gleam add choire@1
```

```sh
$ gleam run -m choire

# if you are hitting hex api ratelimits
$ HEXAPI_KEY=... gleam run -m choire
```

## Hex API and Ratelimits

At the time of this writing, you can make 100 requests per minute to the HEX api as an
unauthenticated user and 500 per minute as an authenticated user
(https://hexpm.docs.apiary.io/#introduction/rate-limiting).

Since the limit resets after 60 seconds, this library will simply hold and wait for the limit
to reset and continue fetching the package information.

## Development

```sh
./bin/test.sh # Run choire with the sample repositories
```

## License
[Apache License, Version 2.0](./LICENSE)
