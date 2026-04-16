defmodule AccrueHost.InstallBoundaryTest do
  use ExUnit.Case, async: true

  @moduletag :phase10
  @host_root Path.expand("..", __DIR__)
  @billing_path Path.join(@host_root, "lib/accrue_host/billing.ex")
  @handler_path Path.join(@host_root, "lib/accrue_host/billing_handler.ex")
  @router_path Path.join(@host_root, "lib/accrue_host_web/router.ex")
  @runtime_path Path.join(@host_root, "config/runtime.exs")

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
    assert router =~ ~S|accrue_webhook("/stripe", :stripe)|
    assert router =~ ~S|accrue_admin("/billing")|
  end

  test "runtime config keeps fake-backed defaults instead of live-only setup" do
    runtime = File.read!(@runtime_path)

    assert runtime =~ "config :accrue, :processor, Accrue.Processor.Fake"
    assert runtime =~ ~S|System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")|
    refute runtime =~ "config :accrue, :processor, Accrue.Processor.Stripe"
  end
end
