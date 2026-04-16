defmodule Mix.Tasks.Accrue.InstallUATTest do
  use Accrue.RepoCase, async: false

  import ExUnit.CaptureIO

  alias Accrue.Test.InstallFixture

  @install_budget_ms 30_000

  setup do
    Mix.shell(Mix.Shell.Process)
    on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
    :ok
  end

  @tag :install_uat
  test "fixture install reaches Stripe test-mode-ready wiring within the UAT budget" do
    app = phoenix_fixture!(:fresh_timing)

    {duration_us, output} =
      :timer.tc(fn ->
        with_env(
          %{
            "STRIPE_SECRET_KEY" => "sk_test_fixture_123",
            "STRIPE_WEBHOOK_SECRET" => "whsec_fixture_123"
          },
          fn ->
            run_install(app, ["--yes", "--billable", "MyApp.Accounts.User"])
          end
        )
      end)

    duration_ms = System.convert_time_unit(duration_us, :microsecond, :millisecond)

    assert duration_ms < @install_budget_ms
    assert output =~ "Stripe test-mode"
    assert output =~ "changed"
    assert output =~ "STRIPE_SECRET_KEY"
    assert output =~ "STRIPE_WEBHOOK_SECRET"
    refute output =~ "sk_test_fixture_123"
    refute output =~ "whsec_fixture_123"

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app/billing.ex",
             "defmodule MyApp.Billing"
           )

    assert InstallFixture.assert_contains!(
             app,
             "lib/my_app_web/router.ex",
             "accrue_webhook \"/stripe\", :stripe"
           )

    assert InstallFixture.assert_contains!(
             app,
             "config/runtime.exs",
             "System.fetch_env!(\"STRIPE_SECRET_KEY\")"
           )
  end

  @tag :install_uat
  test "generated AccrueCase compiles and imports fake mail PDF and event assertions" do
    app = phoenix_fixture!(:host_copy_paste)

    run_install(app, ["--yes"])

    generated = InstallFixture.read!(app, "test/support/accrue_case.ex")

    assert generated =~ "use Accrue.Test"
    assert generated =~ "#   config :accrue, :processor, Accrue.Processor.Fake"
    assert generated =~ "#   config :accrue, :mailer, Accrue.Mailer.Test"
    assert generated =~ "#   config :accrue, :pdf_adapter, Accrue.PDF.Test"
    refute generated =~ "\nconfig :accrue"

    Code.compile_string(generated)

    Code.compile_string("""
    defmodule Accrue.InstallUAT.GeneratedHostProbe do
      use ExUnit.Case
      use AccrueCase

      def run do
        setup_fake_processor([])
        setup_mailer_test([])
        setup_pdf_test([])

        Accrue.Mailer.Test.deliver(:receipt, %{to: "uat@example.test", customer_id: "cus_uat"})
        assert_email_sent(:receipt, to: "uat@example.test")

        Accrue.PDF.Test.render("<h1>Invoice INV-UAT</h1>", invoice_id: "inv_uat")
        assert_pdf_rendered(contains: "INV-UAT", invoice_id: "inv_uat")

        {:ok, _event} =
          Accrue.Events.record(%{
            type: "subscription.created",
            subject_type: "Subscription",
            subject_id: "sub_install_uat",
            actor_type: "system",
            data: %{"customer_id" => "cus_uat"}
          })

        assert_event_recorded(type: "subscription.created", subject_id: "sub_install_uat")
        :ok
      end
    end
    """)

    with_app_env([:processor, :mailer, :pdf_adapter, :env], fn ->
      assert :ok = apply(Accrue.InstallUAT.GeneratedHostProbe, :run, [])
    end)
  end

  @tag :install_uat
  test "admin mount is protected by generated helper and custom mount reruns stay idempotent" do
    app = phoenix_fixture!(:admin_mount)

    run_install(app, ["--yes", "--admin-mount", "/ops/billing"])
    run_install(app, ["--yes", "--admin-mount", "/ops/billing"])

    router = InstallFixture.read!(app, "lib/my_app_web/router.ex")

    assert router =~ "import AccrueAdmin.Router"
    assert router =~ "Protect this mount with AccrueAdmin.AuthHook via accrue_admin/2."

    assert router =~
             "Hosts with custom routers may also pipe through Accrue.Auth.require_admin_plug()."

    assert router =~ ~s(accrue_admin "/ops/billing")
    assert count_occurrences(router, ~s(accrue_admin "/ops/billing")) == 1
  end

  defp phoenix_fixture!(name) do
    app = InstallFixture.tmp_app!(name)

    InstallFixture.write_mix_project!(app, [
      "{:phoenix, \"~> 1.8\"}",
      "{:accrue, path: \"../accrue\"}",
      "{:accrue_admin, path: \"../accrue_admin\"}"
    ])

    InstallFixture.write_router!(app)
    InstallFixture.write_config!(app)
    app
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

  defp count_occurrences(content, pattern) do
    content
    |> String.split(pattern)
    |> length()
    |> Kernel.-(1)
  end

  defp with_app_env(keys, fun) do
    previous = Map.new(keys, fn key -> {key, Application.get_env(:accrue, key)} end)

    try do
      fun.()
    after
      Enum.each(previous, fn
        {key, nil} -> Application.delete_env(:accrue, key)
        {key, value} -> Application.put_env(:accrue, key, value)
      end)
    end
  end
end
