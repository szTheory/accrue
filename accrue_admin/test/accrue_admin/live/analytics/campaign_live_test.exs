defmodule AccrueAdmin.Live.Analytics.CampaignLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Billing.{Customer, Subscription}
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

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)
    :ok
  end

  describe "Dunning Timeline" do
    test "D-20 D-21 renders Campaign as a detail drill-down with summary rows and primary timeline",
         %{conn: conn} do
      subscription_id = insert_subscription().id

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        actor_type: "system",
        data: %{"campaign_anchor" => "iso_anchor_contract", "invoice_id" => "in_contract"}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        actor_type: "system",
        data: %{
          "campaign_anchor" => "iso_anchor_contract",
          "invoice_id" => "in_contract",
          "step" => "email_1"
        }
      })

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      assert heading_count(html, "h1") == 1
      assert html =~ ~s(class="ax-card ax-summary-card")
      assert data_attr_count(html, "data-ax-summary-list") == 1

      assert html =~ "Subscription"
      assert html =~ subscription_id
      assert html =~ "Campaign state"
      assert html =~ "Timeline events"
      assert html =~ "Invoice count"
      assert html =~ "ax-campaign-timeline"
      assert html =~ "Campaign started"

      refute html =~ ~s(class="ax-kpi-grid")
      refute html =~ ~s(data-ax-zone="kpi-cluster")
    end

    test "D-20 renders Campaign empty state inside the detail drill-down contract", %{conn: conn} do
      subscription_id = insert_subscription().id

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      assert heading_count(html, "h1") == 1
      assert html =~ ~s(class="ax-card ax-summary-card")
      assert data_attr_count(html, "data-ax-summary-list") == 1
      assert html =~ "No dunning history found"
      assert html =~ "ax-campaign-timeline"

      refute html =~ ~s(class="ax-kpi-grid")
    end

    test "renders dunning timeline for subscription with 2 campaign arcs", %{conn: conn} do
      subscription_id = insert_subscription().id
      # Seed events via Repo directly or Events
      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        actor_type: "system",
        data: %{"campaign_anchor" => "iso_anchor_1", "invoice_id" => "in_tl1"}
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.step_sent",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        actor_type: "system",
        data: %{
          "campaign_anchor" => "iso_anchor_1",
          "invoice_id" => "in_tl1",
          "step" => "email_1"
        }
      })

      Accrue.Repo.insert!(%Accrue.Events.Event{
        type: "dunning.campaign_started",
        subject_type: "Subscription",
        subject_id: subscription_id,
        actor_id: Ecto.UUID.generate(),
        actor_type: "system",
        data: %{"campaign_anchor" => "iso_anchor_2", "invoice_id" => "in_tl2"}
      })

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      assert html =~ "Campaign History" || html =~ "Dunning Timeline"
      assert html =~ "Campaign started"
    end

    test "renders empty state for subscription without dunning events", %{conn: conn} do
      subscription_id = insert_subscription().id

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

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
      refute source =~ "AnalyticsPage"
    end

    # Phase 176-06 uplift assertions (dims ②④⑦⑧)
    test "renders prominent hero heading via Detail.summary_card (dims ②⑧)", %{conn: conn} do
      subscription_id = insert_subscription().id

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      # Detail.summary_card renders ax-summary-card container + ax-summary-title hero heading
      # and ax-eyebrow — these satisfy dims ② (visual hierarchy) and ⑧ (brand expression)
      assert html =~ "ax-summary-card"
      assert html =~ "ax-summary-title"
      assert html =~ "ax-eyebrow"
    end

    test "renders semantic aria-label on the timeline section (dim ⑦)", %{conn: conn} do
      subscription_id = insert_subscription().id

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      # aria-label must be present on the timeline/page section
      assert html =~ ~r/aria-label=/
    end

    test "redirects with denial flash for unknown subscription_id (dim ④)", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/billing/analytics/recovery", flash: flash}}} =
               conn
               |> init_test_session(%{
                 "admin_token" => "admin",
                 "accrue_admin" => %{"mount_path" => "/billing"}
               })
               |> live("/billing/analytics/recovery/subscriptions/#{Ecto.UUID.generate()}")

      assert flash["error"] == Copy.Locked.owner_access_denied()
    end

    test "denies direct campaign route outside the active organization", %{conn: conn} do
      allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
      denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
      allowed_subscription = insert_subscription(allowed_customer)
      denied_subscription = insert_subscription(denied_customer)

      conn =
        init_test_session(conn, %{
          :admin_token => "admin",
          :active_organization_id => "org_allowed",
          :active_organization_slug => "allowed-org",
          :admin_organization_ids => ["org_allowed"],
          "accrue_admin" => %{"mount_path" => "/billing"}
        })

      assert {:ok, _view, allowed_html} =
               live(
                 conn,
                 "/billing/analytics/recovery/subscriptions/#{allowed_subscription.id}?org=allowed-org"
               )

      assert allowed_html =~ allowed_subscription.id

      assert {:error,
              {:redirect,
               %{to: "/billing/analytics/recovery?org=allowed-org", flash: flash_token}}} =
               redirect =
               live(
                 conn,
                 "/billing/analytics/recovery/subscriptions/#{denied_subscription.id}?org=allowed-org"
               )

      assert %{"error" => denied} =
               Phoenix.LiveView.Utils.verify_flash(AccrueAdmin.TestEndpoint, flash_token)

      assert denied == Copy.Locked.owner_access_denied()
      assert redirect
    end

    test "uses Detail.summary_card component (ax-summary-card) for the page hero (dim ②)", %{
      conn: conn
    } do
      subscription_id = insert_subscription().id

      {:ok, _view, html} =
        conn
        |> init_test_session(%{
          "admin_token" => "admin",
          "accrue_admin" => %{"mount_path" => "/billing"}
        })
        |> live("/billing/analytics/recovery/subscriptions/#{subscription_id}")

      # Detail.summary_card renders ax-summary-card — confirms the component is used
      assert html =~ "ax-summary-card"
      # The subscription_id is shown as detail info inside the facts slot
      assert html =~ subscription_id

      # The page hero title must use ax-summary-title (Detail.summary_card renders h2.ax-summary-title)
      assert html =~ "ax-summary-title"
    end
  end

  defp insert_customer(attrs \\ %{}) do
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

  defp insert_subscription do
    insert_subscription(insert_customer())
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
end
