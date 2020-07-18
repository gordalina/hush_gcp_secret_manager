defmodule HushGcpSecretManager.MixProject do
  use Mix.Project

  @version "0.0.1"
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
      {:hush, "~> 0.0.4"},
      {:httpoison, ">0.0.0"},
      {:goth, "~> 1.1.0"},
      {:mox, "~> 0.5", only: :test},
      {:ex_check, "~> 0.12.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:sobelow, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.12", only: :test},
      {:inch_ex, ">= 0.0.0", only: :docs}
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
        "README.md"
      ],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
