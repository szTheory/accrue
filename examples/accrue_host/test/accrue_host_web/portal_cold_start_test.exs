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

  alias AccrueHost.Accounts.User
  alias AccrueHost.Repo
  alias AccrueHostWeb.Router

  @checkout_sessions_table Accrue.Migration.qualified_table(:accrue_checkout_sessions)

  describe "phase 101 cold start" do
    test "accrue_checkout_sessions schema is applied" do
      result = Repo.query!("SELECT 1 FROM #{@checkout_sessions_table} LIMIT 1")
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
      assert body =~ "Cadence billing"
    end

    test "anonymous GET /billing redirects to host login and stores the return path", %{
      conn: conn
    } do
      conn = get(conn, ~p"/billing")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert get_session(conn, :user_return_to) == ~p"/billing"
    end
  end

  describe "seeded Cadence portal walkthrough" do
    setup :seed_hero_accounts

    test "healthy customer sees subscriptions, payment methods, and invoices in /billing", %{
      conn: conn
    } do
      user = Repo.get_by!(User, email: "healthy@example.com")
      conn = log_in_user(conn, user)

      dashboard =
        conn
        |> get(~p"/billing")
        |> html_response(200)

      assert dashboard =~ AccruePortal.Copy.home_heading()
      refute dashboard =~ AccruePortal.Copy.home_empty_body()
      assert dashboard =~ "Status: active"
      assert dashboard_metric_count(dashboard, 1) == 3

      payment_methods =
        conn
        |> recycle()
        |> log_in_user(user)
        |> get(~p"/billing/payment-methods")
        |> html_response(200)

      assert payment_methods =~ "Visa"
      assert payment_methods =~ "ending in 4242"
      assert payment_methods =~ AccruePortal.Copy.payment_methods_default_badge()

      invoices =
        conn
        |> recycle()
        |> log_in_user(user)
        |> get(~p"/billing/invoices")
        |> html_response(200)

      assert invoices =~ "PORTAL-LAUNCH-001"
      assert invoices =~ "Status: paid"
    end
  end

  defp seed_hero_accounts(_context) do
    case Accrue.Processor.Fake.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok = Accrue.Processor.Fake.reset()

    previous_env = Application.get_env(:accrue, :env)
    Application.put_env(:accrue, :env, :dev)

    Code.compiler_options(ignore_module_conflict: true)
    Code.eval_file("priv/repo/seeds.exs")
    Code.compiler_options(ignore_module_conflict: false)

    on_exit(fn -> Application.put_env(:accrue, :env, previous_env) end)

    :ok
  end

  defp dashboard_metric_count(html, expected_count) do
    ~r/<p class="portal-metric">\s*#{expected_count}\s*<\/p>/
    |> Regex.scan(html)
    |> length()
  end
end
