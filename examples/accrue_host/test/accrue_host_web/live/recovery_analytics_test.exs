defmodule AccrueHostWeb.RecoveryAnalyticsTest do
  use AccrueHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import AccrueHost.AccountsFixtures

  alias AccrueHost.Repo

  setup do
    # Run the seed script so we have the deterministic data
    Code.require_file("priv/repo/seeds.exs")

    :ok
  end

  test "renders recovery dashboard with deterministic seeded data", %{conn: conn} do
    user = user_fixture()
    user = Repo.update!(Ecto.Changeset.change(user, billing_admin: true))
    
    conn = log_in_user(conn, user)

    assert {:ok, _view, html} = live(conn, "/admin/analytics/recovery")

    # Assert KPI cards render the multi-currency data from seeds
    assert html =~ "Recovered MRR (USD)"
    assert html =~ "Exhausted MRR (JPY)"

    assert html =~ "$120.00" # 12000 cents in USD
    assert html =~ "¥30,000" # 30000 cents in JPY
    
    # Assert funnel chart
    assert html =~ "Recovery Funnel"

    # Assert At-Risk table
    assert html =~ "At-Risk Subscriptions"
  end
end
