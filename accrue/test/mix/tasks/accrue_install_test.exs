defmodule Mix.Tasks.Accrue.InstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Accrue.Test.InstallFixture

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  @tag :install_options
  test "adds Igniter dependency and documents required non-interactive flags" do
    app = InstallFixture.tmp_app!(:options)
    InstallFixture.write_mix_project!(app, ["{:phoenix, \"~> 1.8\"}"])
    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output = run_install(app, ["--dry-run", "--non-interactive", "--manual"])

    assert output =~ "{:igniter, \"~> 0.7.9\", runtime: false}"
    assert output =~ "--dry-run"
    assert output =~ "--yes"
    assert output =~ "--non-interactive"
    assert output =~ "--manual"
    assert output =~ "--force"
    assert output =~ "--check"
  end

  @tag :install_templates
  test "generates fingerprinted Billing facade, handler, migrations, config docs, and runtime snippets" do
    app = InstallFixture.tmp_app!(:templates)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])

    assert InstallFixture.read!(app, "lib/my_app/billing.ex") =~ "# accrue:generated"

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app/billing.ex",
             "defmodule MyApp.Billing"
           )

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app/billing_handler.ex",
             "defmodule MyApp.BillingHandler"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/config.exs",
             "config :accrue, :auth_adapter, Accrue.Auth.Default"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "config :accrue, :processor, Accrue.Processor.Stripe"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "System.fetch_env!(\"STRIPE_SECRET_KEY\")"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "System.get_env(\"STRIPE_WEBHOOK_SECRET\")"
           )
  end

  @tag :install_patches
  test "patches router with webhook, admin, auth, test support, and Oban snippets when dependencies are present" do
    app = InstallFixture.tmp_app!(:patches)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}",
      "{:accrue_admin, path: \"../accrue_admin\"}",
      "{:sigra, \"~> 0.1\"}",
      "{:oban, \"~> 2.21\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output = run_install(app, ["--yes"])

    assert output =~ "/webhooks/stripe"

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app_web/router.ex",
             "accrue_webhook \"/stripe\", :stripe"
           )

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app_web/router.ex",
             "accrue_admin \"/billing\""
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/config.exs",
             "config :accrue, :auth_adapter, Accrue.Integrations.Sigra"
           )

    assert InstallFixture.assert_contains!(app, "test/support/accrue_case.ex", "use Accrue.Test")

    assert InstallFixture.assert_contains!(
             app,
             "test/support/accrue_case.ex",
             "config :accrue, :mailer, Accrue.Mailer.Test"
           )

    InstallFixture.refute_contains!(
      app,
      "test/support/accrue_case.ex",
      "config :accrue, :mailer_adapter, Accrue.Mailer.Test"
    )

    assert output =~ "Oban"
  end

  @tag :install_patches
  test "does not mount admin or Sigra auth when optional dependencies are absent" do
    app = InstallFixture.tmp_app!(:fallback_patches)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])

    InstallFixture.refute_contains!(app, "lib/my_app_web/router.ex", "accrue_admin \"/billing\"")
    InstallFixture.refute_contains!(app, "config/config.exs", "Accrue.Integrations.Sigra")

    assert InstallFixture.assert_contains!(
             app,
             "config/config.exs",
             "config :accrue, :auth_adapter, Accrue.Auth.Default"
           )
  end

  @tag :install_stripe_test_mode
  test "fresh fixture app gets Stripe test-mode runtime readiness without leaking raw secrets" do
    app = InstallFixture.tmp_app!(:stripe_test_mode)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output =
      with_env(
        %{
          "STRIPE_SECRET_KEY" => "sk_test_fixture_123",
          "STRIPE_WEBHOOK_SECRET" => "whsec_fixture_123"
        },
        fn ->
          run_install(app, ["--dry-run", "--yes"])
        end
      )

    assert output =~ "Stripe test-mode"
    assert output =~ "STRIPE_SECRET_KEY"
    assert output =~ "STRIPE_WEBHOOK_SECRET"
    refute output =~ "sk_test_fixture_123"
    refute output =~ "whsec_fixture_123"

    run_install(app, ["--yes"])

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "config :accrue, :processor, Accrue.Processor.Stripe"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "System.fetch_env!(\"STRIPE_SECRET_KEY\")"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "System.get_env(\"STRIPE_WEBHOOK_SECRET\")"
           )

    InstallFixture.refute_contains!(app, "config/runtime.exs", "sk_test_fixture_123")
    InstallFixture.refute_contains!(app, "config/runtime.exs", "whsec_fixture_123")
  end

  @tag :install_stripe_test_mode
  test "Stripe readiness accepts sk_test keys and rejects or masks live and missing keys" do
    app = InstallFixture.tmp_app!(:stripe_readiness)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    test_output =
      with_env(%{"STRIPE_SECRET_KEY" => "sk_test_fixture_123"}, fn ->
        run_install(app, ["--dry-run", "--yes"])
      end)

    assert test_output =~ "sk_test_"
    refute test_output =~ "sk_test_fixture_123"

    live_output =
      with_env(%{"STRIPE_SECRET_KEY" => "sk_live_fixture_123"}, fn ->
        run_install(app, ["--dry-run", "--yes"])
      end)

    assert live_output =~ "STRIPE_SECRET_KEY"
    refute live_output =~ "sk_live_fixture_123"
    assert live_output =~ "test-mode"

    missing_output =
      with_env(%{"STRIPE_SECRET_KEY" => nil}, fn -> run_install(app, ["--dry-run", "--yes"]) end)

    assert missing_output =~ "STRIPE_SECRET_KEY"
    assert missing_output =~ "missing"
  end

  @tag :install_orchestration
  test "full installer entrypoint reports changed, skipped, manual follow-up, and redacted readiness" do
    app = InstallFixture.tmp_app!(:orchestration)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output =
      with_env(
        %{
          "STRIPE_SECRET_KEY" => "sk_test_fixture_123",
          "STRIPE_WEBHOOK_SECRET" => "whsec_fixture_123"
        },
        fn ->
          run_install(app, ["--yes", "--billable", "MyApp.Accounts.User"])
        end
      )

    assert output =~ "created"
    assert output =~ "manual"
    assert output =~ "STRIPE_SECRET_KEY"
    assert output =~ "STRIPE_WEBHOOK_SECRET"
    refute output =~ "sk_test_fixture_123"
    refute output =~ "whsec_fixture_123"
  end

  @tag :install_templates
  test "re-run updates pristine fingerprinted files and skips user-edited files even with --force" do
    app = InstallFixture.tmp_app!(:fingerprints)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])
    pristine = InstallFixture.read!(app, "lib/my_app/billing.ex")
    assert pristine =~ "# accrue:generated"

    run_install(app, ["--yes"])
    assert InstallFixture.read!(app, "lib/my_app/billing.ex") =~ "# accrue:generated"

    InstallFixture.write!(app, "lib/my_app/billing.ex", pristine <> "\n# user-edited\n")
    output = run_install(app, ["--yes", "--force"])

    assert output =~ "skipped"
    assert output =~ "user-edited"
    assert InstallFixture.assert_contains!(app, "lib/my_app/billing.ex", "# user-edited")
  end

  @tag :install_conflicts
  test "enforces no-clobber summary taxonomy and write-conflicts artifact contract" do
    app = InstallFixture.tmp_app!(:conflict_contract)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    run_install(app, ["--yes"])
    billing_pristine = InstallFixture.read!(app, "lib/my_app/billing.ex")

    InstallFixture.write!(app, "lib/my_app/billing.ex", billing_pristine <> "\n# host edit\n")
    InstallFixture.write!(app, "config/runtime.exs", "# unmarked host file\n")
    InstallFixture.write!(app, "test/support/accrue_case.ex", "defmodule AccrueCase do\nend\n")
    output = run_install(app, ["--yes", "--force", "--write-conflicts"])

    assert output =~ "created"
    assert output =~ "updated pristine"
    assert output =~ "skipped user-edited"
    assert output =~ "skipped exists"
    assert output =~ "manual"
    assert output =~ "conflict artifact"
    assert output =~ "--write-conflicts"

    refute output =~ "overwrote user-edited"

    assert File.exists?(Path.join(app, ".accrue/conflicts/templates/lib/my_app/billing.ex.new"))

    assert File.exists?(
             Path.join(app, ".accrue/conflicts/patches/test/support/accrue_case.ex.snippet")
           )

    rendered_replacement =
      InstallFixture.read!(app, ".accrue/conflicts/templates/lib/my_app/billing.ex.new")

    manual_snippet =
      InstallFixture.read!(app, ".accrue/conflicts/patches/test/support/accrue_case.ex.snippet")

    assert rendered_replacement =~ "target: lib/my_app/billing.ex"
    assert rendered_replacement =~ "reason: skipped user-edited"
    assert rendered_replacement =~ "# accrue:generated"
    assert manual_snippet =~ "target: test/support/accrue_case.ex"
    assert manual_snippet =~ "reason: test support exists"
    assert manual_snippet =~ "use Accrue.Test"
  end

  @tag :install_templates
  test "unmarked files stay skipped exists unless --force is present" do
    app = InstallFixture.tmp_app!(:unmarked_force)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)
    InstallFixture.write!(app, "config/runtime.exs", "# host-owned runtime\n")

    skipped_output = run_install(app, ["--yes"])
    assert skipped_output =~ "skipped exists: config/runtime.exs"
    assert InstallFixture.read!(app, "config/runtime.exs") == "# host-owned runtime\n"

    forced_output = run_install(app, ["--yes", "--force"])
    assert forced_output =~ "changed (overwrote unmarked): config/runtime.exs"
    assert InstallFixture.read!(app, "config/runtime.exs") =~ "# accrue:generated"
  end

  @tag :install_check
  test "--check reports shared diagnostics for missing webhook route admin mount auth and Oban wiring" do
    app = InstallFixture.tmp_app!(:check_missing_wiring)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}",
      "{:accrue_admin, path: \"../accrue_admin\"}",
      "{:oban, \"~> 2.21\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)

    output = run_install(app, ["--check", "--yes"])

    assert output =~ "check: installer preflight mode"
    assert output =~ "ACCRUE-DX-WEBHOOK-ROUTE-MISSING"
    assert output =~ "ACCRUE-DX-ADMIN-MOUNT-MISSING"
    assert output =~ "ACCRUE-DX-AUTH-ADAPTER"
    assert output =~ "ACCRUE-DX-OBAN-NOT-CONFIGURED"
    assert output =~ "/guides/troubleshooting.html#accrue-dx-webhook-route-missing"
  end

  @tag :install_check
  test "--check reports raw body and pipeline diagnostics for browser-mounted webhooks" do
    app = InstallFixture.tmp_app!(:check_bad_webhook_pipeline)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}"
    ])

    InstallFixture.write_router!(app, """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      import Accrue.Router

      pipeline :browser do
        plug :accepts, [\"html\"]
        plug :fetch_session
        plug :protect_from_forgery
      end

      scope \"/webhooks\", MyAppWeb do
        pipe_through [:browser, :require_authenticated_user]
        accrue_webhook \"/stripe\", :stripe
      end
    end
    """)

    InstallFixture.write_config!(app, "import Config\nconfig :accrue, :auth_adapter, MyApp.Auth\n")

    output = run_install(app, ["--check", "--yes"])

    assert output =~ "ACCRUE-DX-WEBHOOK-RAW-BODY"
    assert output =~ "ACCRUE-DX-WEBHOOK-PIPELINE"
  end

  defp run_install(app, argv) do
    Mix.Task.clear()

    capture_io(fn ->
      InstallFixture.cd_preserving_code_path!(app, fn ->
        apply(Mix.Tasks.Accrue.Install, :run, [argv])
      end)
    end)
  end

  defp with_env(env, fun) do
    previous = Map.new(env, fn {key, _value} -> {key, System.get_env(key)} end)

    Enum.each(env, fn
      {key, nil} -> System.delete_env(key)
      {key, value} -> System.put_env(key, value)
    end)

    try do
      fun.()
    after
      Enum.each(previous, fn
        {key, nil} -> System.delete_env(key)
        {key, value} -> System.put_env(key, value)
      end)
    end
  end
end
