defmodule AccrueHostWeb.PortalColdStartTest do
  @moduledoc """
  Cold-start smoke proof for Phase 101.

  Replaces the human "boot the host, click /billing" UAT step with three
  fail-closed assertions: the new `accrue_checkout_sessions` migration
  applied, every portal route the LiveView shell exposes is registered on
  the host router, and `GET /billing` renders the dashboard for a freshly
  signed-in customer. If any of these regress, this test blocks the merge
  before a human ever has to spin up the example host.
  """

  use AccrueHostWeb.ConnCase, async: false

  alias AccrueHost.Repo
  alias AccrueHostWeb.Router

  describe "phase 101 cold start" do
    test "accrue_checkout_sessions schema is applied" do
      result = Repo.query!("SELECT 1 FROM accrue_checkout_sessions LIMIT 1")
      assert %Postgrex.Result{} = result
    end

    test "every portal route the LiveView shell exposes is registered on the host router" do
      paths = MapSet.new(Router.__routes__(), & &1.path)

      expected = [
        "/billing",
        "/billing/checkout/:token",
        "/billing/subscriptions",
        "/billing/subscriptions/:id",
        "/billing/payment-methods",
        "/billing/payment-methods/new",
        "/billing/invoices"
      ]

      for path <- expected do
        assert MapSet.member?(paths, path),
               "expected portal route #{inspect(path)} to be registered on AccrueHostWeb.Router"
      end
    end

    test "GET /billing renders the portal dashboard for a signed-in customer", %{conn: conn} do
      user = AccrueHost.AccountsFixtures.user_fixture()
      conn = log_in_user(conn, user)

      conn = get(conn, ~p"/billing")

      body = html_response(conn, 200)
      assert body =~ AccruePortal.Copy.home_heading()
      assert body =~ AccruePortal.Copy.home_body()
    end
  end
end
