defmodule AccrueAdmin.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/szTheory/accrue"

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
      source_url: @source_url,
      docs: docs(),
      dialyzer: [plt_local_path: "priv/plts", plt_add_apps: [:mix]]
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
      accrue_dep(),
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.2"},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{},
      files: ~w(lib config guides priv/static mix.exs README* LICENSE* CHANGELOG*)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "guides/admin_ui.md"],
      groups_for_extras: [Guides: ["guides/admin_ui.md"]]
    ]
  end

  defp accrue_dep do
    if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
      {:accrue, "~> #{@version}"}
    else
      {:accrue, path: "../accrue"}
    end
  end
end
