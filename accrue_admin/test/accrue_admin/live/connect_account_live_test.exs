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
  end

  setup do
    prior = Application.get_env(:accrue, :auth_adapter)
    Application.put_env(:accrue, :auth_adapter, AuthAdapter)
    on_exit(fn -> Application.put_env(:accrue, :auth_adapter, prior) end)

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

  test "previews and saves a platform fee override on the local account data", %{
    conn: conn,
    account: account
  } do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    {:ok, view, html} = live(conn, "/billing/connect/#{account.id}")

    assert html =~ "Save a per-account fee policy"
    assert html =~ "Default policy"

    html =
      render_change(element(view, "form"), %{
        "override" => %{
          "percent" => "1.9",
          "fixed_cents" => "30",
          "min_cents" => "",
          "max_cents" => "",
          "preview_amount_minor" => "10000",
          "preview_currency" => "usd"
        }
      })

    assert html =~ "$2.20"

    html =
      render_submit(element(view, "form"), %{
        "override" => %{
          "percent" => "1.9",
          "fixed_cents" => "30",
          "min_cents" => "",
          "max_cents" => "",
          "preview_amount_minor" => "10000",
          "preview_currency" => "usd"
        }
      })

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
end
