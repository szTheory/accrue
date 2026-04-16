defmodule AccrueHost.InstallBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :phase10
  @host_root Path.expand("..", __DIR__)
  @billing_path Path.join(@host_root, "lib/accrue_host/billing.ex")
  @handler_path Path.join(@host_root, "lib/accrue_host/billing_handler.ex")
  @router_path Path.join(@host_root, "lib/accrue_host_web/router.ex")
  @runtime_path Path.join(@host_root, "config/runtime.exs")
  @webhook_route ~r/accrue_webhook\s*\(?\s*"\/stripe",\s*:stripe\s*\)?/
  @admin_mount ~r/accrue_admin\s*\(?\s*"\/billing",\s*session_keys:\s*\[:user_token\],\s*allow_live_reload:\s*false\s*\)?/

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
    assert count_occurrences(router, "pipeline :accrue_webhook_raw_body do") == 1
    assert count_regex_occurrences(router, @webhook_route) == 1
    assert count_regex_occurrences(router, @admin_mount) == 1
  end

  test "runtime config keeps fake-backed defaults instead of live-only setup" do
    runtime = File.read!(@runtime_path)

    assert runtime =~ "config :accrue, :processor, Accrue.Processor.Fake"
    assert runtime =~ ~S|System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")|
    refute runtime =~ "config :accrue, :processor, Accrue.Processor.Stripe"
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
