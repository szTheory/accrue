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
      preferred_envs: [precommit: :test, verify: :test, "verify.full": :test]
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
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"},
      accrue_dep(),
      accrue_admin_dep(),
      sigra_dep(),
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

  defp sigra_dep do
    # Sigra is on Hex (~> 0.2). Default to the Hex package so dep resolution
    # stays clean — Mailglass declares `{:sigra, "~> 0.2", optional: true}`
    # and would conflict with a non-versioned `github:` source. To point at a
    # local Sigra working tree for development:
    #   export ACCRUE_SIGRA_PATH=../../../sigra
    # (path is relative to this `mix.exs` unless absolute).
    path =
      System.get_env("ACCRUE_SIGRA_PATH")
      |> to_string()
      |> String.trim()

    if path == "" do
      {:sigra, "~> 0.2"}
    else
      {:sigra, path: Path.expand(path, __DIR__)}
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
      "verify.install": [
        "deps.get",
        "accrue.install --yes --billable AccrueHost.Accounts.User --billing-context AccrueHost.Billing --admin-mount /billing --webhook-path /webhooks/stripe"
      ],
      verify: [verify_command()],
      "verify.full": [
        "verify.install",
        "verify",
        "compile --warnings-as-errors",
        "assets.build",
        verify_regression_command(),
        verify_dev_boot_command(),
        verify_browser_command()
      ],
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

  defp verify_command do
    cmd_run_script("accrue_host_verify_test_bounded.sh")
  end

  defp verify_regression_command do
    cmd_run_script("accrue_host_verify_test_full.sh")
  end

  defp verify_dev_boot_command do
    cmd_run_script("accrue_host_verify_dev_boot.sh")
  end

  defp verify_browser_command do
    cmd_run_script("accrue_host_verify_browser.sh")
  end

  # `mix cmd bash -lc '…multiline…'` is unsafe in aliases: `OptionParser.split/1` strips the
  # outer single quotes, then `mix cmd` joins argv with spaces, so `System.shell/1` ends up
  # running unquoted shell metacharacters through `/bin/sh -c` (breaks on `$(…)` / `if`).
  # Run repo-checked-in scripts instead, with a single-quoted absolute path for `mix cmd`.
  defp cmd_run_script(name) when is_binary(name) do
    path = Path.expand(Path.join("..", Path.join("..", Path.join("scripts/ci", name))), __DIR__)

    unless File.exists?(path) do
      Mix.raise("missing host verify script #{path} (expected scripts/ci/#{name})")
    end

    quoted = "'" <> String.replace(path, "'", "'\"'\"'") <> "'"
    "cmd bash #{quoted}"
  end
end
