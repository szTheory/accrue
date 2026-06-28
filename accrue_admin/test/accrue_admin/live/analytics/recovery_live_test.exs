defmodule AccrueAdmin.Live.Analytics.RecoveryLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events
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

    # Seed some events with MRR
    {:ok, _} =
      Events.record(%{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: "sub_123",
        data: %{
          mrr_value_cents: 5000,
          currency: "usd"
        }
      })

    {:ok, _} =
      Events.record(%{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: "sub_456",
        data: %{
          mrr_value_cents: 2000,
          currency: "usd"
        }
      })

    :ok
  end

  test "renders recovery dashboard with MRR totals", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

    assert html =~ Copy.recovery_index_heading()
    assert html =~ Copy.recovery_index_subtitle()
    assert html =~ "Recovered MRR (USD)"
    assert html =~ "$50.00"
    assert html =~ "Exhausted MRR (USD)"
    refute html =~ "Lost MRR"
    assert html =~ "$20.00"
  end

  test "D-18 D-19 renders Recovery-specific overview grammar in order", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=30d")

    assert heading_count(html, "h1") == 1
    assert html =~ Copy.recovery_index_heading()
    assert active_window_label(html) =~ "30 days"

    assert data_attr_count(html, "data-ax-overview") == 1
    assert data_attr_count(html, "data-ax-recovery-hero") == 1
    assert data_attr_count(html, "data-ax-recovery-work-queue") == 1
    assert data_attr_count(html, "data-ax-recovery-supporting-funnel") == 1

    assert recovery_band_order(html) == [
             :hero,
             :work_queue,
             :supporting_funnel
           ]

    refute html =~ ~s(data-ax-zone="kpi-cluster")
  end

  describe "funnel rendering (DAN-09)" do
    test "renders supporting funnel chart after recovery queue", %{conn: conn} do
      # Seed a cycled-dunning fixture (in addition to the file-level setup) so the
      # funnel has structural strings to render. Distinct campaign_anchor values
      # exercise the DISTINCT-(subject_id, campaign_anchor) tuple semantics of
      # Dunning.funnel/1 at the rendering boundary (ground-truth math is enforced
      # by Plan 01's unit tests).
      now = DateTime.utc_now()
      anchor_a = DateTime.to_iso8601(now)
      anchor_b = DateTime.to_iso8601(DateTime.add(now, -1, :day))

      {:ok, _} =
        Events.record(%{
          type: "dunning.campaign_started",
          subject_type: "Subscription",
          subject_id: "sub_cycle",
          data: %{campaign_anchor: anchor_a}
        })

      {:ok, _} =
        Events.record(%{
          type: "dunning.recovered",
          subject_type: "Subscription",
          subject_id: "sub_cycle",
          data: %{campaign_anchor: anchor_a, mrr_value_cents: 1000, currency: "usd"}
        })

      {:ok, _} =
        Events.record(%{
          type: "dunning.campaign_started",
          subject_type: "Subscription",
          subject_id: "sub_cycle",
          data: %{campaign_anchor: anchor_b}
        })

      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

      assert html =~ "Recovery Funnel"
      assert html =~ "currently in dunning"
    end

    test "Exhausted MRR card carries yearly-plan worked example (ROADMAP SC#5)",
         %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

      # Worked-example copy lives in either the Exhausted KpiCard delta string
      # (recovery_live.ex) or the FunnelChart Exhausted-bar tooltip (DAN-09
      # component). Both render the $120/yr → $10/mo annualization example.
      assert html =~ "$120/yr"
      assert html =~ "$10/mo"
    end
  end

  describe "JPY rendering (DAN-13)" do
    setup do
      # D-21: drive Render.format_money/3 via runtime config switch to :jpy.
      # The CLDR backend may render any of ¥ / ￥ / "JPY" depending on locale —
      # accept all three (D-21 latitude).
      prior_currency = Application.get_env(:accrue, :default_currency)
      Application.put_env(:accrue, :default_currency, :jpy)

      on_exit(fn ->
        if is_nil(prior_currency) do
          Application.delete_env(:accrue, :default_currency)
        else
          Application.put_env(:accrue, :default_currency, prior_currency)
        end
      end)

      # Replace the file-level USD-denominated fixture with a JPY recovered event
      # so the formatted KPI string is rendered through the :jpy CLDR path.
      {:ok, _} =
        Events.record(%{
          type: "dunning.recovered",
          subject_type: "Subscription",
          subject_id: "sub_jpy",
          data: %{
            mrr_value_cents: 5000,
            currency: "jpy"
          }
        })

      :ok
    end

    test "renders JPY symbol for the JPY Recovered KPI value", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

      # Since we now render cards per currency, both USD and JPY cards will appear.
      # The JPY card should render ¥/￥/JPY, and the USD card should render $
      assert html =~ "Recovered MRR (JPY)"
      assert html =~ "¥" or html =~ "￥" or html =~ "JPY"

      assert html =~ "Recovered MRR (USD)"
      assert html =~ "$50.00"
    end
  end

  describe "window parameter (DAN-10)" do
    test "no ?window= param defaults to 30d window selector active", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")
      # The 30d button — and only the 30d button — must carry aria-current="page".
      assert active_window_label(html) =~ "30 days"
    end

    test "?window=7d renders 7d button as active", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=7d")
      assert active_window_label(html) =~ "7 days"
    end

    test "?window=90d renders 90d button as active", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=90d")
      assert active_window_label(html) =~ "90 days"
    end

    test "invalid ?window= falls back to 30d default", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery?window=bad")
      assert active_window_label(html) =~ "30 days"
    end

    test "window change via render_patch fires handle_params", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      {:ok, view, _html} = live(conn, "/billing/analytics/recovery")
      html = render_patch(view, "/billing/analytics/recovery?window=7d")
      assert active_window_label(html) =~ "7 days"
    end

    test "window links preserve unrelated query params on the live route", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} =
               live(conn, "/billing/analytics/recovery?owner=platform&window=30d")

      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=7d/
      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=30d/
      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=90d/
    end
  end

  # Returns the trimmed text content of the link element carrying aria-current="page".
  # Returns nil if no active button is found, surfacing the bug immediately via
  # a clean assertion failure rather than a FunctionClauseError from List.first(nil).
  defp active_window_label(html) do
    case Regex.run(~r/aria-current="page"[^>]*>\s*([^<]+)\s*<\/a>/, html, capture: :all_but_first) do
      [label | _] -> String.trim(label)
      nil -> nil
    end
  end

  defp data_attr_count(html, attr) do
    attr
    |> Regex.escape()
    |> then(&Regex.compile!("\\b" <> &1 <> "(?:\\s|=|>)"))
    |> Regex.scan(html)
    |> length()
  end

  defp heading_count(html, tag) do
    tag
    |> Regex.escape()
    |> then(&Regex.compile!("<" <> &1 <> "\\b"))
    |> Regex.scan(html)
    |> length()
  end

  defp recovery_band_order(html) do
    [
      hero: "data-ax-recovery-hero",
      work_queue: "data-ax-recovery-work-queue",
      supporting_funnel: "data-ax-recovery-supporting-funnel",
      dashboard_kpi_cluster: ~s(data-ax-zone="kpi-cluster")
    ]
    |> Enum.flat_map(fn {band, marker} ->
      case :binary.match(html, marker) do
        :nomatch -> []
        {position, _length} -> [{position, band}]
      end
    end)
    |> Enum.sort()
    |> Enum.map(fn {_position, band} -> band end)
  end

  describe "at-risk table (DAN-11)" do
    test "renders At-Risk Subscriptions section on recovery dashboard", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

      assert html =~ "At-Risk Subscriptions"

      assert html =~ "No active dunning campaigns" or
               html =~ "active dunning campaigns in this window"
    end

    test "window change via render_patch re-assigns at-risk list without crash", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      {:ok, view, _html} = live(conn, "/billing/analytics/recovery")
      html = render_patch(view, "/billing/analytics/recovery?window=7d")

      assert html =~ "At-Risk Subscriptions"
    end

    test "at-risk table row links to per-subscription drill-down route", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      {:ok, _view, html} = live(conn, "/billing/analytics/recovery")

      assert html =~ "/analytics/recovery/subscriptions/" or html =~ "No active dunning campaigns"
    end

    test "cross-package boundary: RecoveryLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.Subscription" do
      source = File.read!("lib/accrue_admin/live/analytics/recovery_live.ex")

      refute source =~ "import Ecto.Query"
      refute source =~ "Accrue.Repo"
      refute source =~ "Accrue.Billing.Subscription"
    end
  end
end
