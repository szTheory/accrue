defmodule AccrueAdmin.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jon/accrue"

  def project do
    [
      app: :accrue_admin,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: "Admin LiveView UI for Accrue billing.",
      source_url: @source_url
    ]
  end

  def application do
    [
      mod: {AccrueAdmin.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  def cli do
    [preferred_envs: [test: :test]]
  end

  defp deps do
    [
      # Dev monorepo path; at publish time this flips to "~> 1.0" per D-43.
      # Do NOT add both forms now.
      {:accrue, path: "../accrue"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.2"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib config priv/static mix.exs README* LICENSE* CHANGELOG*)
    ]
  end
end
