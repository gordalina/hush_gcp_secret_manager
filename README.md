# GCP Secret Manager Hush Provider

[![Build Status](https://img.shields.io/github/workflow/status/gordalina/hush_gcp_secret_manager/ci?style=flat-square)](https://github.com/gordalina/hush_gcp_secret_manager/actions?query=workflow%3A%22ci%22)
[![Coverage Status](https://img.shields.io/codecov/c/github/gordalina/hush_gcp_secret_manager?style=flat-square)](https://app.codecov.io/gh/gordalina/hush_gcp_secret_manager)
[![hex.pm version](https://img.shields.io/hexpm/v/hush_gcp_secret_manager?style=flat-square)](https://hex.pm/packages/hush_gcp_secret_manager)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/hush_gcp_secret_manager?style=flat-square)]([LICENSE](https://hex.pm/packages/hush_gcp_secret_manager))

This package provides a [Hush](https://github.com/gordalina/hush) Provider to resolve Google Cloud Platform's [Secret Manager](https://cloud.google.com/secret-manager) secrets.

Documentation can be found at [https://hexdocs.pm/hush_gcp_secret_manager](https://hexdocs.pm/hush_gcp_secret_manager).

## Installation

The package can be installed by adding `hush_gcp_secret_manager` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hush, "~> 1.0.0"},
    {:hush_gcp_secret_manager, "~> 1.0.0-rc.0"}
  ]
end
```

This module relies on `goth` to fetch secrets from the Google Cloud Platform API. As such you need to configure goth which is used in `hush_gcp_secret_manager`, the configuration is the same as if you were to configure achild_spec as per [their documentation](https://github.com/peburrows/goth).

As the provider needs to start both applications, it needs to registered as a provider in `hush`, so that it gets loaded during startup.

```elixir
# config/config.exs

alias Hush.Provider.GcpSecretManager

# ensure hush loads GcpSecretManager during startup
config :hush,
  providers: [GcpSecretManager]

config :hush_gcp_secret_manager,
  project_id: "my_project_id",
  goth: [name: MyApp.Goth, source: ...]
```

### GCP Authorization

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
