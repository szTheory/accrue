defmodule AccrueAdmin.Live.Analytics.RecoveryLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Events

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
    Events.record(%{
      type: "dunning.recovered",
      subject_type: "Subscription",
      subject_id: "sub_123",
      data: %{
        mrr_value_cents: 5000,
        currency: "usd"
      }
    })

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

    assert html =~ "Revenue Recovery"
    assert html =~ "Recovered MRR"
    assert html =~ "$50.00"
    assert html =~ "Exhausted MRR"
    refute html =~ "Lost MRR"
    assert html =~ "$20.00"
  end

  describe "funnel rendering (DAN-09)" do
    test "renders funnel chart below KPI grid", %{conn: conn} do
      # Seed a cycled-dunning fixture (in addition to the file-level setup) so the
      # funnel has structural strings to render. Distinct campaign_anchor values
      # exercise the DISTINCT-(subject_id, campaign_anchor) tuple semantics of
      # Dunning.funnel/1 at the rendering boundary (ground-truth math is enforced
      # by Plan 01's unit tests).
      now = DateTime.utc_now()
      anchor_a = DateTime.to_iso8601(now)
      anchor_b = DateTime.to_iso8601(DateTime.add(now, -1, :day))

      Events.record(%{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: "sub_cycle",
        data: %{campaign_anchor: anchor_a}
      })

      Events.record(%{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: "sub_cycle",
        data: %{campaign_anchor: anchor_a, mrr_value_cents: 1000, currency: "usd"}
      })

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
  end
end
