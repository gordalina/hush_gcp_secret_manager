# GCP Secret Manager Hush Provider

[![Build Status](https://github.com/gordalina/hush_gcp_secret_manager/workflows/ci/badge.svg)](https://github.com/gordalina/hush_gcp_secret_manager/actions?query=workflow%3A%22ci%22)
[![Coverage Status](https://coveralls.io/repos/gordalina/hush_gcp_secret_manager/badge.svg?branch=master)](https://coveralls.io/r/gordalina/hush_gcp_secret_manager?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/hush_gcp_secret_manager.svg)](https://hex.pm/packages/hush_gcp_secret_manager)

This package provides a [Hush](https://github.com/gordalina/hush) Provider to resolve Google Cloud Platform's [Secret Manager](https://cloud.google.com/secret-manager) secrets.

Documentation can be found at [https://hexdocs.pm/hush_gcp_secret_manager](https://hexdocs.pm/hush_gcp_secret_manager).

## Installation

The package can be installed by adding `hush_gcp_secret_manager` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hush, "~> 0.1.0"},
    {:hush_gcp_secret_manager, "~> 0.2.0"}
  ]
end
```

This module relies on `goth` and `httpoison` to talk to the Google Cloud Platform API. As such you need to configure goth, below is an example, but you can read alternative ways of configuring it in [their documentation](https://github.com/peburrows/goth).

As the provider needs to start both applications, it needs to registered as a provider in `hush`, so that it gets loaded during startup.

```elixir
# config/config.exs

alias Hush.Provider.GcpSecretManager

config :goth,
  json: "service-account-key.json" |> File.read!

# ensure hush loads GcpSecretManager during startup
config :hush,
  providers: [GcpSecretManager]

config :hush_gcp_secret_manager,
  project_id: "my_project_id"
```

**GCP Authorization**

In order to retrieve secrets from GCP, ensure the service account you use has the Secret Manager Secret Accessor role (`roles/secretmanager.secretAccessor`).

## Usage

The following example reads the password and the pool size for CloudSQL from secret manager into the ecto repo configuration.

```elixir
# config/prod.exs

alias Hush.Provider.GcpSecretManager

config :app, App.Repo,
  password: {:hush, GcpSecretManager, "CLOUDSQL_PASSWORD"},
  pool_size: {:hush, GcpSecretManager, "ECTO_POOL_SIZE", cast: :integer, default: 10}
```

## License

Hush is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
