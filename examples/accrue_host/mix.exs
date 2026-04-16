defmodule AccrueHost.MixProject do
  use Mix.Project

  def project do
    [
      app: :accrue_host,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AccrueHost.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.5"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.0"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      accrue_dep(),
      accrue_admin_dep(),
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"}
    ]
  end

  defp accrue_dep do
    if hex_release?() do
      {:accrue, "~> #{accrue_version()}"}
    else
      {:accrue, path: "../../accrue"}
    end
  end

  defp accrue_admin_dep do
    if hex_release?() do
      {:accrue_admin, "~> #{accrue_admin_version()}"}
    else
      {:accrue_admin, path: "../../accrue_admin"}
    end
  end

  defp hex_release?, do: System.get_env("ACCRUE_HOST_HEX_RELEASE") == "1"

  defp accrue_version, do: sibling_package_version!("../../accrue/mix.exs")

  defp accrue_admin_version, do: sibling_package_version!("../../accrue_admin/mix.exs")

  defp sibling_package_version!(relative_path) do
    relative_path
    |> Path.expand(__DIR__)
    |> File.read!()
    |> case do
      contents ->
        case Regex.run(~r/@version\s+"([^"]+)"/, contents, capture: :all_but_first) do
          [version] -> version
          _ -> raise "could not parse @version from #{relative_path}"
        end
    end
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["compile", "tailwind accrue_host", "esbuild accrue_host"],
      "assets.deploy": [
        "tailwind accrue_host --minify",
        "esbuild accrue_host --minify",
        "phx.digest"
      ],
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
