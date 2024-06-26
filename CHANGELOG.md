# Changelog

## v1.1.0

- Add support for Elixir 1.17 and OTP 27
- Drop support for Elixir 1.10

## v1.0.1

- Configure `Goth.fetch/2` timeout via configuration key `:goth_timeout`

## v1.0.0

- Upgrade Goth to ~> 1.3
- Switch http client from httpoison to finch (which is already bundled with goth)
- Upgrade hush to 1.0

## v0.2.2

- Bugfix: save application env when loading configuration in Provider mode.

## v0.2.1

- Relax version constraint on Hush to ~> 0.2

## v0.2.0

- Support Hush v0.2.0

## v0.1.1

- Ensure ability to load config from parameter as well as runtime

## v0.1.0

- Announced public release
