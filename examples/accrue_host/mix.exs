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
      {:telemetry_metrics, "~> 1.0"},
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
    if hex_release?() do
      {:sigra, "~> #{sigra_version()}"}
    else
      {:sigra, path: "../../../sigra"}
    end
  end

  defp hex_release?, do: System.get_env("ACCRUE_HOST_HEX_RELEASE") == "1"

  defp accrue_version, do: sibling_package_version!("../../accrue/mix.exs")

  defp accrue_admin_version, do: sibling_package_version!("../../accrue_admin/mix.exs")

  defp sigra_version, do: sibling_package_version!("../../../sigra/mix.exs")

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
    test_files = [
      "test/install_boundary_test.exs",
      "test/accrue_host/billing_facade_test.exs",
      "test/accrue_host_web/subscription_flow_test.exs",
      "test/accrue_host_web/webhook_ingest_test.exs",
      "test/accrue_host_web/trust_smoke_test.exs",
      "test/accrue_host_web/admin_webhook_replay_test.exs",
      "test/accrue_host_web/admin_mount_test.exs",
      "test/accrue_host_web/org_billing_access_test.exs",
      "test/accrue_host_web/org_billing_live_test.exs"
    ]

    quoted_files = Enum.join(test_files, " ")

    bash_command("""
      MIX_ENV=test mix ecto.drop --quiet || true
      MIX_ENV=test mix ecto.create --quiet
      MIX_ENV=test mix ecto.migrate --quiet
      MIX_ENV=test mix test --warnings-as-errors #{quoted_files}
    """)
  end

  defp verify_regression_command do
    bash_command("""
      MIX_ENV=test mix test --warnings-as-errors
    """)
  end

  defp verify_dev_boot_command do
    bash_command("""
      if [ "${ACCRUE_HOST_SKIP_DEV_BOOT:-}" = "1" ]; then
        echo "--- dev boot smoke skipped (ACCRUE_HOST_SKIP_DEV_BOOT=1) ---"
        exit 0
      fi

      port="${ACCRUE_HOST_PORT:-4100}"
      log_file="$(mktemp)"

      cleanup() {
        if [ -n "${server_pid:-}" ] && kill -0 "$server_pid" >/dev/null 2>&1; then
          kill "$server_pid" >/dev/null 2>&1 || true
          wait "$server_pid" >/dev/null 2>&1 || true
        fi

        rm -f "$log_file"
      }

      trap cleanup EXIT

      MIX_ENV=dev mix ecto.create --quiet
      MIX_ENV=dev mix ecto.migrate --quiet

      PORT="$port" MIX_ENV=dev mix phx.server >"$log_file" 2>&1 &
      server_pid=$!

      for _ in $(seq 1 30); do
        if ! kill -0 "$server_pid" >/dev/null 2>&1; then
          echo "Phoenix server exited early"
          cat "$log_file"
          exit 1
        fi

        if curl --fail --silent --show-error "http://127.0.0.1:${port}/" >/dev/null; then
          echo "Phoenix boot smoke passed on http://127.0.0.1:${port}/"
          exit 0
        fi

        sleep 1
      done

      echo "Phoenix server did not become ready"
      cat "$log_file"
      exit 1
    """)
  end

  defp verify_browser_command do
    bash_command("""
      if [ "${ACCRUE_HOST_SKIP_BROWSER:-}" = "1" ]; then
        echo "--- browser smoke skipped (ACCRUE_HOST_SKIP_BROWSER=1) ---"
        exit 0
      fi

      repo_root="$(cd ../.. && pwd)"
      browser_port="${ACCRUE_HOST_BROWSER_PORT:-4101}"
      fixture_file="$(mktemp)"
      browser_log_file="${ACCRUE_HOST_BROWSER_LOG:-$(mktemp)}"
      browser_failed=0

      cleanup() {
        if [ -n "${browser_server_pid:-}" ] && kill -0 "$browser_server_pid" >/dev/null 2>&1; then
          kill "$browser_server_pid" >/dev/null 2>&1 || true
          wait "$browser_server_pid" >/dev/null 2>&1 || true
        fi

        rm -f "$fixture_file"

        if [ -z "${ACCRUE_HOST_BROWSER_LOG:-}" ] && [ "$browser_failed" != "1" ]; then
          rm -f "$browser_log_file"
        fi
      }

      trap cleanup EXIT

      MIX_ENV=test mix ecto.drop --quiet || true
      MIX_ENV=test mix ecto.create --quiet
      MIX_ENV=test mix ecto.migrate --quiet
      ACCRUE_HOST_E2E_FIXTURE="$fixture_file" MIX_ENV=test mix run "$repo_root/scripts/ci/accrue_host_seed_e2e.exs"

      bash "$repo_root/scripts/ci/verify_e2e_fixture_jq.sh" "$fixture_file"

      (cd "$repo_root/accrue_admin" && mix accrue_admin.assets.build)
      mix deps.compile accrue_admin --force

      npm ci
      npm run e2e:install

      PORT="$browser_port" PHX_SERVER=true MIX_ENV=test mix phx.server >"$browser_log_file" 2>&1 &
      browser_server_pid=$!

      for _ in $(seq 1 30); do
        if ! kill -0 "$browser_server_pid" >/dev/null 2>&1; then
          echo "Phoenix browser-smoke server exited early"
          browser_failed=1
          echo "Phoenix browser-smoke server log: $browser_log_file"
          cat "$browser_log_file"
          exit 1
        fi

        if curl --fail --silent --show-error "http://127.0.0.1:${browser_port}/" >/dev/null; then
          set +e
          ACCRUE_HOST_REUSE_SERVER=1 \
            ACCRUE_HOST_BROWSER_PORT="$browser_port" \
            ACCRUE_HOST_E2E_FIXTURE="$fixture_file" \
            npm run e2e
          e2e_status=$?
          set -e

          if [ "$e2e_status" -ne 0 ]; then
            browser_failed=1
            echo "Phoenix browser-smoke server log: $browser_log_file"
            cat "$browser_log_file"
          fi

          exit "$e2e_status"
        fi

        sleep 1
      done

      echo "Phoenix browser-smoke server did not become ready"
      browser_failed=1
      echo "Phoenix browser-smoke server log: $browser_log_file"
      cat "$browser_log_file"
      exit 1
    """)
  end

  defp bash_command(script) do
    escaped =
      script
      |> String.trim()
      |> String.replace("'", ~s('"'"'))

    "cmd bash -lc '#{escaped}'"
  end
end
