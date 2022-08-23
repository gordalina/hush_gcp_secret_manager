defmodule HushGcpSecretManager.MixProject do
  use Mix.Project

  @version "0.2.2"
  @source_url "https://github.com/gordalina/hush_gcp_secret_manager"

  def project do
    [
      app: :hush_gcp_secret_manager,
      version: @version,
      elixir: "~> 1.9",
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:hush, "~> 0.2"},
      {:finch, "~> 0.9"},
      {:goth, "~> 1.3"},
      {:jason, "~> 1.0"},
      {:mock, "~> 0.3", only: :test},
      {:ex_check, "~> 0.12", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:sobelow, "~> 0.10", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test, runtime: false}
    ]
  end

  defp description do
    """
    A Google Secret Manager Provider for Hush
    """
  end

  defp package() do
    [
      name: "hush_gcp_secret_manager",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
