defmodule AccruePortal.MixProject do
  use Mix.Project

  @version "1.5.1"
  @source_url "https://github.com/szTheory/accrue"

  def project do
    [
      app: :accrue_portal,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      package: package(),
      description: "Customer portal UI for Accrue billing.",
      source_url: @source_url,
      docs: docs(),
      test_coverage: [summary: [threshold: 75]]
    ]
  end

  def cli do
    [preferred_envs: [test: :test, "test.ci": :test]]
  end

  defp aliases do
    [
      "test.ci": [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "test --warnings-as-errors",
        "cmd env MIX_ENV=dev mix hex.audit"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp deps do
    [
      accrue_dep(),
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.2"},
      {:plug, "~> 1.16"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib priv/static mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "accrue_portal-v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp accrue_dep do
    if System.get_env("ACCRUE_PORTAL_HEX_RELEASE") == "1" do
      {:accrue, "== #{@version}"}
    else
      {:accrue, path: "../accrue"}
    end
  end
end
