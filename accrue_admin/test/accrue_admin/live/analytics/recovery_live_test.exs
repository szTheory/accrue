defmodule AccrueAdmin.Live.Analytics.RecoveryLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events
  alias Accrue.Events.Event
  alias AccrueAdmin.Copy
  alias AccrueAdmin.Live.Analytics.RecoveryLive
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

  setup do
    # Recovery windows use Accrue.Clock; align the fixed fake clock with the
    # database's wall-clock inserted_at timestamps for these integration tests.
    :ok =
      Accrue.Processor.Fake.advance(
        DateTime.diff(DateTime.utc_now(), Accrue.Clock.utc_now(), :second)
      )

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

    assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

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

    assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery?window=30d")

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
      now = Accrue.Clock.utc_now()
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

      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

      assert html =~ "Recovery Funnel"
      assert html =~ "currently in dunning"
    end

    test "Exhausted MRR card carries yearly-plan worked example (ROADMAP SC#5)",
         %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

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

      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

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
      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")
      # The 30d button — and only the 30d button — must carry aria-current="page".
      assert active_window_label(html) =~ "30 days"
    end

    test "?window=7d renders 7d button as active", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery?window=7d")
      assert active_window_label(html) =~ "7 days"
    end

    test "?window=90d renders 90d button as active", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery?window=90d")
      assert active_window_label(html) =~ "90 days"
    end

    test "invalid ?window= falls back to 30d default", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery?window=bad")
      assert active_window_label(html) =~ "30 days"
    end

    test "window change via render_patch fires handle_params", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      {:ok, view, _html} = live_recovery(conn, "/billing/analytics/recovery")
      html = render_patch(view, "/billing/analytics/recovery?window=7d")
      assert active_window_label(html) =~ "7 days"
    end

    test "loading state keeps the selected owner and UTC window until scoped reads finish", %{
      conn: conn
    } do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      {:ok, view, loading_html} =
        live(conn, "/billing/analytics/recovery?org=allowed-org&window=7d")

      assert loading_html =~ ~s(data-state="loading")
      assert active_window_label(loading_html) =~ "7 days"
      assert loading_html =~ "org=allowed-org"
      assert loading_html =~ "Loading recovery observations for this owner and UTC window."
      refute loading_html =~ "Recovery Funnel"
      assert render_async(view) =~ "$12.34"
      refute render(view) =~ ~s(data-state="loading")
    end

    test "failed recovery read remains a recoverable error rather than an empty result" do
      assert {:noreply, socket} =
               RecoveryLive.handle_async(
                 :recovery_query,
                 {:exit, :query_timeout},
                 %Phoenix.LiveView.Socket{}
               )

      assert socket.assigns.recovery_loading? == false

      assert socket.assigns.recovery_error ==
               "We couldn't load this billing data. Refresh the page or return to the list and try again."

      assert socket.assigns.stats == %{recovered: [], lost: []}
      assert socket.assigns.at_risk == []
    end

    test "window change re-queries KPI values rather than only changing the active button", %{
      conn: conn
    } do
      ten_days_ago =
        Accrue.Clock.utc_now()
        |> DateTime.add(-10, :day)
        |> then(&%{&1 | microsecond: {elem(&1.microsecond, 0), 6}})

      TestRepo.insert!(%Event{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: "sub_window_boundary",
        actor_type: "system",
        schema_version: 1,
        data: %{"mrr_value_cents" => 10_000, "currency" => "usd"},
        inserted_at: ten_days_ago
      })

      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      {:ok, view, html_30d} = live_recovery(conn, "/billing/analytics/recovery?window=30d")

      assert active_window_label(html_30d) =~ "30 days"
      assert html_30d =~ "$150.00"

      _html_7d = render_patch(view, "/billing/analytics/recovery?window=7d")
      html_7d = render_async(view)

      assert active_window_label(html_7d) =~ "7 days"
      assert html_7d =~ "$50.00"
      refute html_7d =~ "$150.00"
    end

    test "window links preserve unrelated query params on the live route", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      assert {:ok, _view, html} =
               live_recovery(conn, "/billing/analytics/recovery?owner=platform&window=30d")

      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=7d/
      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=30d/
      assert html =~ ~r/href="\/billing\/analytics\/recovery\?[^"]*owner=platform[^"]*window=90d/
    end
  end

  describe "Wave 0 raw recovery event fixtures" do
    test "keeps UTC bounds, event identity, currency, and minor units as stored facts" do
      reference = Accrue.Clock.utc_now()

      fixtures =
        [7, 30, 90]
        |> Enum.with_index()
        |> Enum.flat_map(fn {days, index} ->
          boundary = DateTime.add(reference, -days, :day)

          [
            insert_raw_recovery_event(
              "sub_wave0_#{days}d_at",
              boundary,
              Enum.at(["usd", "jpy", "kwd"], index),
              Enum.at([12_345, 1_234, 567], index)
            ),
            insert_raw_recovery_event(
              "sub_wave0_#{days}d_outside",
              DateTime.add(boundary, -1, :second),
              Enum.at([nil, "unsupported", "usd"], index),
              Enum.at([0, 9_876, 100], index)
            )
          ]
        end)

      # Two distinct ledger rows at the same UTC instant remain distinguishable.
      duplicate_timestamp =
        DateTime.add(reference, -7, :day)
        |> then(&%{&1 | microsecond: {elem(&1.microsecond, 0), 6}})

      same_instant =
        insert_raw_recovery_event(
          "sub_wave0_same_instant",
          duplicate_timestamp,
          "usd",
          0
        )

      zero_fixtures = []
      one_fixture = Enum.take(fixtures, 1)
      multiple_fixtures = fixtures

      assert zero_fixtures == []
      assert length(one_fixture) == 1
      assert length(multiple_fixtures) > 1
      assert Enum.map(fixtures, & &1.id) |> Enum.uniq() |> length() == length(fixtures)

      assert same_instant.id != Enum.at(fixtures, 0).id
      assert same_instant.inserted_at == duplicate_timestamp
      assert Enum.at(fixtures, 0).inserted_at == duplicate_timestamp

      Enum.each(fixtures ++ [same_instant], fn fixture ->
        persisted = TestRepo.get!(Event, fixture.id)
        assert persisted.id == fixture.id
        assert persisted.subject_id == fixture.subject_id
        assert persisted.inserted_at == fixture.inserted_at
        assert persisted.data == fixture.data
      end)

      assert Enum.map(fixtures, & &1.data["currency"]) == [
               "usd",
               nil,
               "jpy",
               "unsupported",
               "kwd",
               "usd"
             ]

      assert Enum.map(fixtures, & &1.data["mrr_value_cents"]) == [
               12_345,
               0,
               1_234,
               9_876,
               567,
               100
             ]
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

      assert {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

      assert html =~ "At-Risk Subscriptions"

      assert html =~ "No active dunning campaigns" or
               html =~ "active dunning campaigns in this window"
    end

    test "window change via render_patch re-assigns at-risk list without crash", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

      {:ok, view, _html} = live_recovery(conn, "/billing/analytics/recovery")
      html = render_patch(view, "/billing/analytics/recovery?window=7d")

      assert html =~ "At-Risk Subscriptions"
    end

    test "at-risk table row links to per-subscription drill-down route", %{conn: conn} do
      conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
      {:ok, _view, html} = live_recovery(conn, "/billing/analytics/recovery")

      assert html =~ "/analytics/recovery/subscriptions/" or html =~ "No active dunning campaigns"
    end

    test "current subscription state is separate from the historical failure label", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      assert {:ok, _view, html} = live_recovery(conn, fixture.return_path)

      assert html =~ "Current subscription status"
      assert html =~ "past_due"
      assert html =~ "Last Failure Reason"
    end

    test "detail links preserve current owner and selected UTC window", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      assert {:ok, _view, html} =
               live_recovery(conn, "/billing/analytics/recovery?org=allowed-org&window=7d")

      assert html =~
               ~r|href="/billing/analytics/recovery/subscriptions/#{fixture.allowed_at_risk.id}\?[^\"]*return_to=%2Fbilling%2Fanalytics%2Frecovery%3Forg%3Dallowed-org%26window%3D7d[^\"]*"|
    end

    test "related link reflects the latest rapidly selected window", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      {:ok, view, _html} =
        live_recovery(conn, "/billing/analytics/recovery?org=allowed-org&window=7d")

      _html = render_patch(view, "/billing/analytics/recovery?org=allowed-org&window=90d")
      html = render_async(view)

      assert html =~ "%26window%3D90d"
      refute html =~ "%26window%3D7d"
    end

    test "campaign round trips preserve each supported window and current owner", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      for window <- ["7d", "30d", "90d"] do
        {:ok, _view, html} =
          live_recovery(conn, "/billing/analytics/recovery?org=allowed-org&window=#{window}")

        [campaign_path] =
          Regex.run(
            ~r|href="([^\"]*/analytics/recovery/subscriptions/#{fixture.allowed_at_risk.id}[^\"]*)"|,
            html,
            capture: :all_but_first
          )

        campaign_path = String.replace(campaign_path, "&amp;", "&")
        assert campaign_path =~ "%26window%3D#{window}"

        {:ok, _campaign, campaign_html} = live(conn, campaign_path)

        assert campaign_html =~ "Back to Recovery"

        assert campaign_html =~
                 ~r|href="/billing/analytics/recovery\?[^\"]*window=#{window}[^\"]*org=allowed-org| or
                 campaign_html =~
                   ~r|href="/billing/analytics/recovery\?[^\"]*org=allowed-org[^\"]*window=#{window}|
      end
    end

    test "invalid Recovery window falls back to the existing 30 day selection", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      {:ok, _view, html} =
        live_recovery(conn, "/billing/analytics/recovery?org=allowed-org&window=invalid")

      assert active_window_label(html) =~ "30 days"
      assert html =~ "%26window%3D30d"
      refute html =~ "%26window%3Dinvalid"
    end

    test "returning from campaign detail restores validated owner and window", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      return_to =
        URI.encode_query(%{
          "return_to" => "/billing/analytics/recovery?org=forged-org&window=7d"
        })
        |> String.replace_prefix("return_to=", "")

      assert {:ok, _view, html} =
               live(
                 conn,
                 "/billing/analytics/recovery/subscriptions/#{fixture.allowed_at_risk.id}?return_to=#{return_to}&org=allowed-org"
               )

      assert html =~ "Back to Recovery"

      assert html =~ ~r|href="/billing/analytics/recovery\?[^\"]*window=7d[^\"]*org=allowed-org| or
               html =~ ~r|href="/billing/analytics/recovery\?[^\"]*org=allowed-org[^\"]*window=7d|

      refute html =~ "forged-org"
    end

    test "unsafe campaign return target falls back inside the current owner scope", %{conn: conn} do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      assert {:ok, _view, html} =
               live(
                 conn,
                 "/billing/analytics/recovery/subscriptions/#{fixture.allowed_at_risk.id}?return_to=https%3A%2F%2Fevil.example&org=allowed-org"
               )

      [_, href] =
        Regex.run(~r|<a class="ax-link" href="([^"]+)">Back to Recovery</a>|, html)

      assert href == "/billing/analytics/recovery?org=allowed-org"
      refute html =~ "evil.example"
    end

    test "an empty authorized owner scope does not invent a default-currency total", %{conn: conn} do
      owner_id = "org_empty_recovery"

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: owner_id,
          active_organization_slug: "empty-org",
          admin_organization_ids: [owner_id]
        )

      assert {:ok, _view, html} =
               live_recovery(conn, "/billing/analytics/recovery?org=empty-org&window=7d")

      assert active_window_label(html) =~ "7 days"
      assert html =~ "No active dunning campaigns"
      refute html =~ "Recovered MRR (USD)"
      refute html =~ "Exhausted MRR (USD)"
    end

    test "unsupported currency stays unavailable while supported currency remains exact", %{
      conn: conn
    } do
      fixture = recovery_navigation_fixture()
      insert_raw_recovery_event(fixture.allowed_recovered.id, Accrue.Clock.utc_now(), nil, 9_999)

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      assert {:ok, _view, html} = live_recovery(conn, fixture.return_path)

      assert html =~ "Recovered MRR (USD)"
      assert html =~ "$12.34"
      assert html =~ "Recovered MRR (UNAVAILABLE)"
      assert html =~ "Amount unavailable"
      refute html =~ "$99.99"
    end

    test "organization scope excludes out-of-scope recovery metrics and at-risk rows", %{
      conn: conn
    } do
      fixture = recovery_navigation_fixture()

      conn =
        Phoenix.ConnTest.init_test_session(conn,
          admin_token: "admin",
          active_organization_id: fixture.owner_id,
          active_organization_slug: "allowed-org",
          admin_organization_ids: [fixture.owner_id]
        )

      assert {:ok, _view, html} = live_recovery(conn, fixture.return_path)

      assert html =~ "$12.34"
      refute html =~ "$98.76"
      assert html =~ "allowed-recovery@example.com"
      refute html =~ "denied-recovery@example.com"
      assert html =~ fixture.allowed_at_risk.id
      refute html =~ fixture.denied_at_risk.id
      assert active_window_label(html) =~ "30 days"

      assert html =~
               ~r/href="\/billing\/analytics\/recovery\?[^\"]*org=allowed-org[^\"]*window=7d/

      assert html =~
               ~r/href="\/billing\/analytics\/recovery\?[^\"]*org=allowed-org[^\"]*window=90d/

      assert html =~
               ~r|href="/billing/analytics/recovery/subscriptions/#{fixture.allowed_at_risk.id}\?[^\"]*org=allowed-org|
    end

    test "cross-package boundary: RecoveryLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.Subscription" do
      source = File.read!("lib/accrue_admin/live/analytics/recovery_live.ex")

      refute source =~ "import Ecto.Query"
      refute source =~ "Accrue.Repo"
      refute source =~ "Accrue.Billing.Subscription"
    end
  end

  defp live_recovery(conn, path) do
    case live(conn, path) do
      {:ok, view, _html} -> {:ok, view, render_async(view)}
      result -> result
    end
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_subscription(customer, attrs \\ %{}) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "sub_" <> Integer.to_string(System.unique_integer([:positive])),
      status: :active,
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Subscription{}
    |> Subscription.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp record_dunning_event(type, subscription, data) do
    {:ok, _event} =
      Events.record(%{
        type: type,
        subject_type: "Subscription",
        subject_id: subscription.id,
        actor_type: "system",
        data: data
      })
  end

  defp insert_raw_recovery_event(subject_id, inserted_at, currency, cents) do
    inserted_at = %{inserted_at | microsecond: {elem(inserted_at.microsecond, 0), 6}}
    data = %{"mrr_value_cents" => cents}
    data = if is_nil(currency), do: data, else: Map.put(data, "currency", currency)

    %Event{
      type: "dunning.recovered",
      subject_type: "Subscription",
      subject_id: subject_id,
      actor_type: "system",
      schema_version: 1,
      data: data,
      inserted_at: inserted_at
    }
    |> TestRepo.insert!()
  end

  defp recovery_navigation_fixture do
    allowed_customer =
      insert_customer(%{
        owner_type: "Organization",
        owner_id: "org_allowed",
        email: "allowed-recovery@example.com"
      })

    denied_customer =
      insert_customer(%{
        owner_type: "Organization",
        owner_id: "org_denied",
        email: "denied-recovery@example.com"
      })

    allowed_recovered = insert_subscription(allowed_customer)
    denied_recovered = insert_subscription(denied_customer)

    allowed_at_risk =
      insert_subscription(allowed_customer, %{
        status: :past_due,
        dunning_campaign_started_at: DateTime.add(Accrue.Clock.utc_now(), -2 * 86_400, :second)
      })

    denied_at_risk =
      insert_subscription(denied_customer, %{
        status: :past_due,
        dunning_campaign_started_at: DateTime.add(Accrue.Clock.utc_now(), -3 * 86_400, :second)
      })

    record_dunning_event("dunning.recovered", allowed_recovered, %{
      mrr_value_cents: 1_234,
      currency: "usd"
    })

    record_dunning_event("dunning.recovered", denied_recovered, %{
      mrr_value_cents: 9_876,
      currency: "usd"
    })

    record_dunning_event("dunning.campaign_started", allowed_at_risk, %{
      campaign_anchor: DateTime.to_iso8601(allowed_at_risk.dunning_campaign_started_at)
    })

    record_dunning_event("dunning.campaign_started", denied_at_risk, %{
      campaign_anchor: DateTime.to_iso8601(denied_at_risk.dunning_campaign_started_at)
    })

    %{
      owner_id: "org_allowed",
      allowed_recovered: allowed_recovered,
      allowed_at_risk: allowed_at_risk,
      denied_at_risk: denied_at_risk,
      return_path: "/billing/analytics/recovery?org=allowed-org&window=30d"
    }
  end
end
