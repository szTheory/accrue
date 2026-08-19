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

  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.Reconcile
  alias Accrue.Test.Factory
  alias AccrueAdmin.Copy
  alias AccrueAdmin.TestRepo

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

    assert html =~ "Access and entitlements"
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

  test "a contradictory pull snapshot is advisory while canonical access remains local", %{
    conn: conn
  } do
    prior_entitlements = Application.get_env(:accrue, :entitlements)

    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(@entitlements, :stripe_native_sync, :advisory)
    )

    on_exit(fn -> Application.put_env(:accrue, :entitlements, prior_entitlements) end)

    %{customer: customer} = Factory.active_subscription(%{price_id: "price_pro"})

    assert {:ok, _summary} =
             Reconcile.write_pull(
               customer,
               ~U[2026-07-31 12:34:56Z],
               [%{"lookup_key" => "priority-support", "feature" => "feature_priority"}],
               "/v1/entitlements/active_entitlements"
             )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    assert html =~ "Accrue access (canonical)"
    assert html =~ "Stripe observation (advisory)"
    assert html =~ "Stripe advisory snapshot — does not change access."
    assert html =~ "Reports"
    assert html =~ "priority-support"
    assert html =~ "2 active access grants"
    assert html =~ "Pull refresh"
    assert html =~ "Complete"
    refute html =~ "match"
    refute html =~ "mismatch"
    refute html =~ "in sync"
    refute html =~ "healthy"
  end

  test "advisory state copy distinguishes every non-authoritative observation state" do
    assert Copy.entitlements_advisory_not_observed_title() == "No snapshot yet."

    assert Copy.entitlements_advisory_not_observed_copy() ==
             "No advisory snapshot has been recorded for this customer."

    assert Copy.entitlements_advisory_age_unknown_title() == "Snapshot time unavailable."

    assert Copy.entitlements_advisory_age_unknown_copy() ==
             "This advisory snapshot has no recorded observation time."

    assert Copy.entitlements_advisory_incomplete_title() == "Incomplete snapshot."

    assert Copy.entitlements_advisory_incomplete_copy() ==
             "This webhook snapshot contains only the first reported entitlements. Local access above is unchanged."

    assert Copy.entitlements_advisory_unavailable_title() == "Snapshot unavailable."

    assert Copy.entitlements_advisory_unavailable_copy() ==
             "We couldn't load the Stripe advisory snapshot. Local access above is unchanged."

    assert Copy.entitlements_advisory_preview_more(2) == "+2 more"
    assert Copy.entitlements_advisory_count(0) == "0 entitlements observed"
  end

  test "every advisory state renders with text, contained metadata, and unchanged local access",
       %{
         conn: conn
       } do
    %{customer: disabled_customer} = Factory.active_subscription(%{price_id: "price_pro"})
    disabled_html = render_entitlements(conn, disabled_customer)

    assert_advisory_state(disabled_html, "Not enabled.", "ax-status-badge-slate")

    assert disabled_html =~
             "Stripe advisory sync is off for this host. Local access above is unchanged."

    assert_local_access(disabled_html)

    enable_advisory!()

    %{customer: absent_customer} = Factory.active_subscription(%{price_id: "price_pro"})
    absent_html = render_entitlements(conn, absent_customer)

    assert_advisory_state(absent_html, "No snapshot yet.", "ax-status-badge-slate")
    assert absent_html =~ "No advisory snapshot has been recorded for this customer."
    refute absent_html =~ "0 entitlements observed"
    assert_local_access(absent_html)

    %{customer: empty_customer} = Factory.active_subscription(%{price_id: "price_pro"})

    insert_summary!(empty_customer, %{
      "entitlements" => %{"data" => []},
      "_accrue" => %{"source" => "pull"}
    })

    empty_html = render_entitlements(conn, empty_customer)

    assert_advisory_state(empty_html, "Snapshot recorded.", "ax-status-badge-slate")
    assert empty_html =~ "0 entitlements observed"
    assert empty_html =~ "Pull refresh"
    assert empty_html =~ "Complete"
    assert_local_access(empty_html)

    %{customer: unknown_time_customer} = Factory.active_subscription(%{price_id: "price_pro"})

    insert_summary!(
      unknown_time_customer,
      %{"entitlements" => %{"data" => [%{"lookup_key" => "reports-shadow"}]}},
      synced_at: nil,
      last_stripe_event_ts: nil,
      last_stripe_event_id: nil
    )

    unknown_time_html = render_entitlements(conn, unknown_time_customer)

    assert_advisory_state(
      unknown_time_html,
      "Snapshot time unavailable.",
      "ax-status-badge-slate"
    )

    assert unknown_time_html =~ "This advisory snapshot has no recorded observation time."
    assert_local_access(unknown_time_html)

    %{customer: incomplete_customer} = Factory.active_subscription(%{price_id: "price_pro"})

    insert_summary!(
      incomplete_customer,
      %{
        "_accrue" => %{"source" => "webhook"},
        "entitlements" => %{
          "data" => [%{"lookup_key" => "partial-observation"}],
          "has_more" => true
        }
      },
      truncated: true
    )

    incomplete_html = render_entitlements(conn, incomplete_customer)

    assert_advisory_state(incomplete_html, "Incomplete snapshot.", "ax-status-badge-amber")

    assert incomplete_html =~
             "This webhook snapshot contains only the first reported entitlements. Local access above is unchanged."

    assert incomplete_html =~ "Webhook"
    assert incomplete_html =~ "Incomplete"
    assert_local_access(incomplete_html)

    %{customer: unavailable_customer} = Factory.active_subscription(%{price_id: "price_pro"})

    insert_summary!(unavailable_customer, %{
      "entitlements" => %{"data" => [%{"lookup_key" => "valid"}, "malformed"]}
    })

    unavailable_html = render_entitlements(conn, unavailable_customer)

    assert_advisory_state(unavailable_html, "Snapshot unavailable.", "ax-status-badge-ink")

    assert unavailable_html =~
             "load the Stripe advisory snapshot. Local access above is unchanged."

    refute unavailable_html =~ "Observed entitlements"
    assert_local_access(unavailable_html)
  end

  test "lookup preview is bounded while lazy Raw data retains complete normalized evidence", %{
    conn: conn
  } do
    enable_advisory!()
    %{customer: customer} = Factory.active_subscription(%{price_id: "price_pro"})

    lookup_keys = Enum.map(1..10, &"entitlement-key-#{String.pad_leading(to_string(&1), 2, "0")}")

    assert {:ok, _summary} =
             Reconcile.write_pull(
               customer,
               ~U[2026-07-31 16:00:00Z],
               Enum.map(Enum.reverse(lookup_keys), &%{"lookup_key" => &1}),
               "/v1/entitlements/active_entitlements"
             )

    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    assert html =~ "10 entitlements observed"
    assert html =~ "+2 more"

    for key <- Enum.take(lookup_keys, 8), do: assert(html =~ key)
    refute html =~ Enum.at(lookup_keys, 8)
    refute html =~ Enum.at(lookup_keys, 9)
    refute html =~ "customer-raw-data"

    raw_html = render_click(element(view, "[data-ax-lazy-json]"))

    assert raw_html =~ "customer-raw-data"
    for key <- lookup_keys, do: assert(raw_html =~ key)
    assert raw_html =~ "stripe_advisory"
    refute raw_html =~ "last_stripe_event_id"
  end

  defp enable_advisory! do
    current = Application.get_env(:accrue, :entitlements, [])

    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(current, :stripe_native_sync, :advisory)
    )
  end

  defp render_entitlements(conn, customer) do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/customers/#{customer.id}?tab=entitlements")

    html
  end

  defp assert_advisory_state(html, title, tone_class) do
    assert html =~ title
    assert html =~ tone_class

    [state_markup] =
      Regex.run(~r/<span data-role="stripe-advisory-state">.*?<\/span>/s, html)

    refute state_markup =~ ~s(role="status")
  end

  defp assert_local_access(html) do
    assert html =~ "Reports"
    assert html =~ "2 active access grants"

    {canonical_position, _} = :binary.match(html, ~s(data-role="accrue-access-canonical"))
    {advisory_position, _} = :binary.match(html, ~s(data-role="stripe-observation-advisory"))
    assert canonical_position < advisory_position
  end

  defp insert_summary!(customer, data, opts \\ []) do
    synced_at = Keyword.get(opts, :synced_at, ~U[2026-07-31 15:00:00Z])

    %EntitlementSummary{}
    |> EntitlementSummary.force_changeset(%{
      customer_id: customer.id,
      stripe_customer_id: customer.processor_id,
      livemode: false,
      entitlement_count: length(get_in(data, ["entitlements", "data"]) || []),
      truncated: Keyword.get(opts, :truncated, false),
      data: data,
      synced_at: synced_at,
      last_stripe_event_ts: Keyword.get(opts, :last_stripe_event_ts, synced_at),
      last_stripe_event_id:
        Keyword.get(opts, :last_stripe_event_id, "evt_#{System.unique_integer([:positive])}")
    })
    |> TestRepo.insert!()
  end
end
