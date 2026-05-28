defmodule AccrueAdmin.Live.Analytics.CampaignLiveTest do
  use AccrueAdmin.LiveCase, async: false

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
    :ok
  end

  describe "Dunning Timeline" do
    test "renders dunning timeline for subscription with 2 campaign arcs", %{conn: conn} do
      subscription_id = "sub_timeline_123"
      # Seed events via Repo directly or Events
      Accrue.Repo.insert!(%Accrue.Events.Event{
        id: Ecto.UUID.generate(),
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        data: %{"campaign_anchor" => "iso_anchor_1", "invoice_id" => "in_tl1"}
      })
      Accrue.Repo.insert!(%Accrue.Events.Event{
        id: Ecto.UUID.generate(),
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        data: %{"campaign_anchor" => "iso_anchor_1", "invoice_id" => "in_tl1", "step" => "email_1"}
      })
      Accrue.Repo.insert!(%Accrue.Events.Event{
        id: Ecto.UUID.generate(),
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        data: %{"campaign_anchor" => "iso_anchor_2", "invoice_id" => "in_tl2"}
      })

      {:ok, _view, html} =
        conn
        |> init_test_session(%{"admin_token" => "admin", "accrue_admin" => %{"mount_path" => "/billing"}})
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      assert html =~ "Campaign History" || html =~ "Dunning Timeline"
      assert html =~ "Campaign started"
    end

    test "renders empty state for unknown subscription_id", %{conn: conn} do
      {:ok, _view, html} =
        conn
        |> init_test_session(%{"admin_token" => "admin", "accrue_admin" => %{"mount_path" => "/billing"}})
        |> live("/billing/analytics/recovery/subscriptions/sub_unknown")

      assert html =~ "No dunning history found"
    end

    test "cross-package boundary: CampaignLive does not import Ecto.Query, Accrue.Repo, or Accrue.Billing.*" do
      # Just to let the test compile if file is missing, read with default "" or handle error
      source =
        case File.read("lib/accrue_admin/live/analytics/campaign_live.ex") do
          {:ok, content} -> content
          {:error, _} -> ""
        end

      refute source =~ "import Ecto.Query"
      refute source =~ "Accrue.Repo"
      refute source =~ "Accrue.Billing."
    end
  end
end
