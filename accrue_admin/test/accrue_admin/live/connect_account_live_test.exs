defmodule AccrueAdmin.ConnectAccountLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Connect.Account
  alias Accrue.Events.Event
  alias AccrueAdmin.TestRepo

  import Ecto.Query

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

    @impl Accrue.Auth
    def step_up_challenge(_user, _action), do: %{kind: :totp, message: "Verify fee override"}

    @impl Accrue.Auth
    def verify_step_up(_user, %{"code" => "123456"}, action) do
      case Application.get_env(:accrue_admin, :expected_step_up_subject_id) do
        nil -> :ok
        expected when action.subject_id == expected -> :ok
        _expected -> {:error, :wrong_subject_id}
      end
    end

    def verify_step_up(_user, _params, _action), do: {:error, :invalid_code}
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)

    on_exit(fn ->
      Application.put_env(:accrue, :auth_adapter, prior)
      Application.delete_env(:accrue_admin, :expected_step_up_subject_id)
    end)

    account =
      insert_account(%{
        stripe_account_id: "acct_override",
        owner_type: "Team",
        owner_id: "team_override",
        type: "express",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        capabilities: %{"transfers" => "active"},
        requirements: %{"currently_due" => ["external_account"]}
      })

    {:ok, account: account}
  end

  test "D-09 D-13 D-14 D-15 D-16 D-17 renders connect summary and fee drawer contract",
       %{conn: conn, account: account} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    assert heading_count(html, "h1") == 1
    assert data_attr_count(html, "data-ax-summary-list") == 1
    assert data_attr_count(html, "data-ax-action-band") == 1
    assert data_attr_count(html, "data-ax-primary-action") == 1
    assert data_attr_count(html, "data-ax-related-resources") == 1
    assert data_attr_count(html, "data-ax-lazy-activity") == 1
    assert data_attr_count(html, "data-ax-lazy-json") == 1

    for label <- [
          "Account readiness",
          "Owner",
          "Country",
          "Charges enabled",
          "Payouts enabled",
          "Onboarding / details submitted",
          "Platform fee override"
        ] do
      assert html =~ label
    end

    assert html =~ "Capabilities / requirements"
    assert html =~ "Platform fee policy"

    assert has_element?(view, "[data-ax-primary-action]", "Edit platform fee override")
    refute has_element?(view, "form[phx-submit='save_override']")
    refute has_element?(view, "[data-role='save-override']")
    refute html =~ ~s(class="ax-kpi-grid")
  end

  test "renders RelatedResources card with events link", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/connect/#{account.id}")

    # Related resources card must be present
    assert html =~ ~s(class="ax-card ax-related")
    # Events filtered by ConnectAccount subject in related resources
    assert html =~ "subject_type=ConnectAccount"
    assert html =~ "subject_id=#{account.id}"
  end

  test "previews and saves a platform fee override on the local account data", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")
    Application.put_env(:accrue_admin, :expected_step_up_subject_id, account.id)

    {:ok, view, _html} = live(conn, "/billing/connect/#{account.id}")

    html = render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    assert html =~ "Save a per-account fee policy"
    assert html =~ "Default policy"

    html =
      render_change(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        %{
          "override" => %{
            "percent" => "1.9",
            "fixed_cents" => "30",
            "min_cents" => "",
            "max_cents" => "",
            "preview_amount_minor" => "10000",
            "preview_currency" => "usd"
          }
        }
      )

    assert html =~ "$2.20"

    html =
      render_submit(
        element(view, "form[data-ax-action-drawer-form][phx-submit=\"save_override\"]"),
        %{
          "override" => %{
            "percent" => "1.9",
            "fixed_cents" => "30",
            "min_cents" => "",
            "max_cents" => "",
            "preview_amount_minor" => "10000",
            "preview_currency" => "usd"
          }
        }
      )

    assert html =~ "Step-up required"

    html = render_submit(view, "step_up_submit", %{"code" => "123456"})

    assert html =~ "Platform fee override saved."
    assert html =~ "1.9% percent"

    updated = TestRepo.get!(Account, account.id)
    assert updated.data["platform_fee_override"] == %{"percent" => "1.9", "fixed_cents" => "30"}

    audit_event =
      TestRepo.one!(
        from(event in Event,
          where:
            event.type == "admin.connect.platform_fee_override.updated" and
              event.subject_id == ^account.id
        )
      )

    assert audit_event.actor_type == "admin"
  end

  test "applies ax-measure to platform-fee description prose", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} = live(conn, "/billing/connect/#{account.id}")

    # ax-measure must appear on the platform-fee description paragraph
    assert html =~ ~s(class="ax-body ax-measure")
  end

  test "D-09 preserves save_override form only after Edit platform fee override intent", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    refute html =~ ~s(phx-submit="save_override")
    refute html =~ ~s(data-role="save-override")

    html = render_click(element(view, "[data-ax-primary-action]", "Edit platform fee override"))

    assert html =~ ~s(phx-submit="save_override")
    assert html =~ ~s(data-role="save-override")
    assert html =~ ~s(data-ax-action-drawer-form)
  end

  defp insert_account(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      type: "standard",
      country: "US",
      email: "owner@example.com",
      data: %{},
      capabilities: %{},
      requirements: %{},
      lock_version: 1
    }

    %Account{}
    |> Account.changeset(Map.merge(defaults, attrs))
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
