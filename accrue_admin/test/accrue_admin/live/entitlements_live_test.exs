defmodule AccrueAdmin.EntitlementsLiveTest do
  @moduledoc """
  Wave 0 LiveView test for the read-only entitlements tab on `CustomerLive`
  (`/billing/customers/:id?tab=entitlements`, ENT-11).

  Covers the three ENT-11 render states: resolved features render, the
  "⚠ Unmapped plan" drift badge for an entitling sub on an unconfigured
  price, and the Copy-backed empty state for a customer with no entitling
  subscription. `async: false` — mutates `:auth_adapter` and `:entitlements`
  app env with on_exit restore.
  """

  use AccrueAdmin.LiveCase, async: false

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

  @entitlements [
    plans: [
      pro: [features: [:reports], limits: [seats: 5], price_ids: ["price_pro"]]
    ],
    unmapped_action: :deny
  ]

  setup do
    prior_auth = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    prior_entitlements = Application.get_env(:accrue, :entitlements)
    Application.put_env(:accrue, :entitlements, @entitlements)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior_auth)

      if prior_entitlements do
        Application.put_env(:accrue, :entitlements, prior_entitlements)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    :ok
  end

  test "resolved features render for a customer on a mapped price", %{conn: conn} do
    %{customer: customer} = Factory.active_subscription(%{price_id: "price_pro"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    assert html =~ Copy.entitlements_section_title()
    assert html =~ Copy.entitlements_features_label()
    # granted feature + active plan render by name
    assert html =~ "Reports"
    assert html =~ "Pro"
  end

  test "an entitling sub on an unconfigured price shows the unmapped drift badge", %{conn: conn} do
    # "price_basic" is the factory default and is NOT in @entitlements, so the
    # resolver structurally discards it and the seam surfaces it as drift.
    %{customer: customer} = Factory.active_subscription(%{price_id: "price_basic"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    assert html =~ Copy.entitlements_drift_section_title()
    assert html =~ Copy.entitlements_unmapped_badge()
    assert html =~ "price_basic"
    # The hint contains an apostrophe (subscription's), which HEEx HTML-escapes
    # to &#39; in the rendered output — assert on the apostrophe-free tail so
    # the check is escaping-robust while still pinning the self-explaining hint.
    assert html =~ "config, so the resolver drops it."
  end

  test "empty state renders for a customer with no entitling subscription", %{conn: conn} do
    %{customer: bare_customer} = Factory.customer(%{email: "bare-ent@example.com"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{bare_customer.id}?tab=entitlements")

    assert html =~ Copy.entitlements_empty_copy()
    assert html =~ Copy.entitlements_no_drift_copy()
  end

  test "the tab renders the fail-closed error copy (no crash) under unmapped_action: :raise (WR-03/CR-01)",
       %{conn: conn} do
    # Under :raise an unmapped entitling price_id makes the resolver raise
    # mid-resolution. The CR-01 guard must collapse that to the fail-closed
    # error state (status 200, error copy) instead of crashing the LiveView.
    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(@entitlements, :unmapped_action, :raise)
    )

    # "price_basic" is the factory default and is NOT in @entitlements, so under
    # :raise the resolver raises rather than dropping it.
    %{customer: customer} = Factory.active_subscription(%{price_id: "price_basic"})
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    # The fail-closed error branch rendered (data-role marker + copy), so the
    # process did NOT crash. The error copy contains an apostrophe ("couldn't")
    # which HEEx HTML-escapes to &#39;, so assert on the apostrophe-free tail to
    # stay escaping-robust while still pinning the fail-closed message.
    assert html =~ ~s(data-role="entitlements-error")
    assert html =~ "The gate fails closed, so no access is granted on error"
    # The normal happy-path drift section must NOT render on the error branch.
    refute html =~ Copy.entitlements_no_drift_copy()
  end
end
