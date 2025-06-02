# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.6] - 2025-06-02

- Bumped `tom` version.

## [1.0.5] - 2025-05-24

- Relaxed version constraints to allow upgrading.

## [1.0.4] - 2025-05-22

- Bumped `gleam_json` version.

## [1.0.3] - 2025-05-14

- Added ability to provide path as the first argument of the cli to run in different root directory
  For example:
  ```sh
  $ gleam run -m choire .. # runs in parent directory
  ```

## [1.0.2] - 2025-05-11

- Bumped version to get around invalid caching.

## [1.0.1] - 2025-05-11

- Fixed a bug where empty dev dependencies would cause a panic.

## [1.0.0] - 2025-05-11

🎶 Initial release!
