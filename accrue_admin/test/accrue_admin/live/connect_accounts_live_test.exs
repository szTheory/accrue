defmodule AccrueAdmin.ConnectAccountsLiveTest do
  use AccrueAdmin.LiveCase, async: false

  alias Accrue.Connect.Account
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

    _match =
      insert_account(%{
        stripe_account_id: "acct_match",
        owner_type: "Team",
        owner_id: "team_123",
        type: "express",
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true,
        data: %{"platform_fee_override" => %{"percent" => "1.5"}}
      })

    _other =
      insert_account(%{
        stripe_account_id: "acct_other",
        owner_type: "User",
        owner_id: "user_456",
        type: "standard",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false
      })

    :ok
  end

  test "filters connect account rows and shows override state", %{conn: conn} do
    conn = Phoenix.ConnTest.init_test_session(conn, admin_token: "admin")

    assert {:ok, _view, html} =
             live(conn, "/billing/connect?type=express&charges_enabled=true&q=acct_match")

    assert html =~ "Connected accounts and payout readiness"
    assert html =~ "acct_match"
    assert html =~ "Override saved"
    assert html =~ "/billing/connect/"
    refute html =~ "acct_other"
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
