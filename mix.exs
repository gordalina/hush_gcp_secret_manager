defmodule HushGcpSecretManager.MixProject do
  use Mix.Project

  @version "0.1.2"
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
      preferred_cli_env: [coveralls: :test, "coveralls.github": :test],
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
      {:goth, "~> 0.11 or ~> 1.0"},
      {:httpoison, "~> 0.13 or ~> 1.0"},
      {:hush, ">= 0.1.0 and <= 0.2.0"},
      {:jason, "~> 1.0"},
      {:mox, "~> 0.5", only: :test},
      {:ex_check, "~> 0.12.0", only: :dev, runtime: false},
      {:credo, "~> 1.4.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0", only: :dev, runtime: false},
      {:sobelow, "~> 0.10.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:inch_ex, "~> 2.0.0", only: :docs}
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
