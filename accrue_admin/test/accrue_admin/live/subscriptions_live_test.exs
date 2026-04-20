defmodule AccrueAdmin.SubscriptionsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing
  alias Accrue.Processor.Fake
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy

  defmodule AuthAdapter do
    @behaviour Accrue.Auth

    @impl Accrue.Auth
    def current_user(%{"admin_token" => "admin"}), do: %{id: "admin_1", role: :admin}
    def current_user(_session), do: nil

    @impl Accrue.Auth
    def require_admin_plug, do: fn conn, _opts -> conn end

    @impl Accrue.Auth
    def user_schema, do: nil

    @impl Accrue.Auth
    def log_audit(_user, _event), do: :ok

    @impl Accrue.Auth
    def actor_id(user), do: user[:id]
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

    %{subscription: paused_subscription} = Factory.active_subscription(%{owner_id: "sub-paused"})

    {:ok, _paused_processor} =
      Fake.pause_subscription_collection(paused_subscription.processor_id, :void, %{}, [])

    %{subscription: active_subscription} = Factory.active_subscription(%{owner_id: "sub-active"})
    {:ok, _canceling_subscription} = Billing.cancel_at_period_end(active_subscription)

    :ok
  end

  test "filters subscription rows and renders lifecycle-safe links", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/subscriptions?status=canceling")

    assert html =~ "Lifecycle-safe subscription search"
    assert html =~ "cancel at period end"
    assert html =~ "/billing/subscriptions/"
    assert html =~ "ax-chip ax-label"
  end

  test "renders Copy-backed empty index when search excludes all subscriptions", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/subscriptions?q=___accrue_empty_fixture___")

    assert html =~ Copy.subscriptions_index_empty_title()
    assert html =~ Copy.subscriptions_index_empty_copy()
  end
end
