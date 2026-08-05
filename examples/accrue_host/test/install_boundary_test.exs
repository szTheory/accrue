defmodule AccrueHost.InstallBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :phase10
  @host_root Path.expand("..", __DIR__)
  @billing_path Path.join(@host_root, "lib/accrue_host/billing.ex")
  @handler_path Path.join(@host_root, "lib/accrue_host/billing_handler.ex")
  @router_path Path.join(@host_root, "lib/accrue_host_web/router.ex")
  @runtime_path Path.join(@host_root, "config/runtime.exs")
  @readme_path Path.join(@host_root, "README.md")
  @webhook_route ~r/accrue_webhook\s*\(?\s*"\/stripe",\s*:stripe\s*\)?/
  @apple_forward ~r/forward\s*\(?\s*"\/apple",\s*AccrueHost\.AppleNotificationIngress\s*\)?/
  @admin_mount ~r/accrue_admin\s*\(?\s*"\/admin",\s*session_keys:\s*\[:user_token\],\s*allow_live_reload:\s*false\s*\)?/
  @portal_mount ~r/accrue_portal\s*\(?\s*"\/billing",\s*session_keys:\s*\[:user_token\],\s*login_path:\s*"\/users\/log-in"\s*\)?/

  test "installer-generated billing facade stays at the public boundary" do
    billing = File.read!(@billing_path)
    handler = File.read!(@handler_path)

    assert billing =~ "# accrue:generated"
    assert billing =~ "defmodule AccrueHost.Billing do"
    assert billing =~ "alias Accrue.Billing"
    assert billing =~ "def subscribe(billable, price_id, opts \\\\ []) do"
    assert billing =~ "def swap_plan(subscription, price_id, opts) do"
    assert billing =~ "def cancel(subscription, opts \\\\ []) do"
    assert billing =~ "def customer_for(billable) do"

    assert handler =~ "# accrue:generated"
    assert handler =~ "defmodule AccrueHost.BillingHandler do"
    assert handler =~ "use Accrue.Webhook.Handler"
  end

  test "router keeps installer-owned webhook and admin patches at the public boundaries" do
    router = File.read!(@router_path)

    assert router =~ "import Accrue.Router"
    assert router =~ "import AccrueAdmin.Router"
    assert router =~ "pipeline :accrue_webhook_raw_body do"
    assert router =~ "body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}"
    assert router =~ ~s(scope "/webhooks" do)
    assert router =~ @webhook_route
    assert router =~ @admin_mount
    assert router =~ @portal_mount
    assert count_occurrences(router, "pipeline :accrue_webhook_raw_body do") == 1
    assert count_regex_occurrences(router, @webhook_route) == 1
    assert count_regex_occurrences(router, @admin_mount) == 1
    assert count_regex_occurrences(router, @portal_mount) == 1
  end

  test "runtime config keeps fake-backed defaults instead of live-only setup" do
    runtime = File.read!(@runtime_path)

    assert runtime =~ "config :accrue, :processor, Accrue.Processor.Fake"
    assert runtime =~ ~S|System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")|
    refute runtime =~ "config :accrue, :processor, Accrue.Processor.Stripe"
  end

  test "Apple ingress keeps one dedicated bounded pipeline and wrapper route beside Stripe" do
    router = File.read!(@router_path)

    assert count_occurrences(router, "pipeline :accrue_apple_notifications_raw_body do") == 1
    assert count_occurrences(router, "length: 262_144") == 1
    assert count_occurrences(router, "Accrue.Webhook.CachingBodyReader") == 2
    assert count_regex_occurrences(router, @apple_forward) == 1
    assert count_regex_occurrences(router, @webhook_route) == 1
    assert router =~ "pipe_through(:accrue_apple_notifications_raw_body)"
    refute router =~ "accrue_webhook(\"/apple\", :stripe)"
  end

  test "Apple runtime configuration pins one production verifier identity for ingress and admission" do
    runtime = File.read!(@runtime_path)

    for name <- [
          "APPLE_TRUST_ROOTS_PEM_PATH",
          "APPLE_BUNDLE_ID",
          "APPLE_APP_ID",
          "APPLE_VERIFIER_CONFIG_VERSION",
          "APPLE_SERVER_API_BEARER_TOKEN",
          "APPLE_PRODUCT_MAP_JSON"
        ] do
      assert runtime =~ name
    end

    assert count_occurrences(runtime, "verifier_config = %Verifier.Config{") == 1
    assert count_occurrences(runtime, "verifier_config: verifier_config") == 2
    assert runtime =~ "verifier: Verifier.Production"
    assert runtime =~ "Client.Production.new"
    assert runtime =~ "environment: :production"
    assert runtime =~ "max_body_bytes: 262_144"
    assert runtime =~ "rate_limiter: &AccrueHost.AppleRatePolicy.check/1"
    assert runtime =~ "APPLE_TRUSTED_PROXY_IPS"
    assert runtime =~ "AppleRatePolicy.parse_trusted_proxies!"
    assert runtime =~ "trusted_proxies: trusted_proxies"
    assert runtime =~ "config :accrue, :apple_reconciliation"
    assert runtime =~ "Application.fetch_env!(:entitlements)"
    assert runtime =~ "configured_plan_keys"
    assert runtime =~ "decode_product_map!("
    assert runtime =~ "configured_plan_keys"
  end

  test "Apple rate guidance defines the trusted-edge contract and local scope" do
    readme = File.read!(@readme_path)

    assert readme =~ "APPLE_TRUSTED_PROXY_IPS"
    assert readme =~ "x-forwarded-for"
    assert readme =~ "strip and"
    assert readme =~ "overwrite inbound `x-forwarded-for`"
    assert readme =~ "direct clients"
    assert readme =~ "single-node"
    assert readme =~ "backstop only"
  end

  test "bounded verification registers every Apple Wave 0 proof with warnings as errors" do
    script =
      File.read!(Path.expand("../../../scripts/ci/accrue_host_verify_test_bounded.sh", __DIR__))

    for test_file <- [
          "test/accrue_host_web/apple_notification_ingest_test.exs",
          "test/accrue_host/apple_rate_policy_test.exs",
          "test/accrue_host/recovery_wiring_test.exs"
        ] do
      assert script =~ test_file
    end

    assert script =~ "MIX_ENV=test mix ecto.drop --quiet || true"
    assert script =~ "MIX_ENV=test mix ecto.migrate --quiet"
    assert script =~ "MIX_ENV=test mix test --warnings-as-errors"
  end

  defp count_occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp count_regex_occurrences(content, pattern) do
    pattern
    |> Regex.scan(content)
    |> length()
  end
end
