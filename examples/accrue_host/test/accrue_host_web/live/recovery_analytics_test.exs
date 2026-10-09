defmodule AccrueHostWeb.RecoveryAnalyticsTest do
  use AccrueHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import AccrueHost.AccountsFixtures

  alias Accrue.Events
  alias AccrueHost.Repo

  setup do
    # The recovery window uses Accrue.Clock, while Events.record timestamps
    # rows from the database clock. Align the fake clock so these fixtures are
    # inside the selected 30-day window, then restore it for neighboring tests.
    clock_shift = DateTime.diff(DateTime.utc_now(), Accrue.Clock.utc_now(), :second) + 2
    :ok = Accrue.Processor.Fake.advance(clock_shift)
    on_exit(fn -> Accrue.Processor.Fake.advance(-clock_shift) end)

    # Insert only the handful of `dunning.*` ledger events this test asserts on,
    # rather than running the full demo seed script (which registers/confirms
    # users, creates orgs, and subscribes via the Fake processor) — those
    # account/billing side effects are unrelated to a recovery-KPI render
    # assertion and would couple this test to the entire seed path.
    {:ok, _} =
      Events.record(%{
        type: "dunning.recovered",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        data: %{mrr_value_cents: 12000, currency: "usd"}
      })

    {:ok, _} =
      Events.record(%{
        type: "dunning.exhausted",
        subject_type: "Subscription",
        subject_id: Ecto.UUID.generate(),
        data: %{mrr_value_cents: 30000, currency: "jpy"}
      })

    :ok
  end

  test "renders recovery dashboard with deterministic seeded data", %{conn: conn} do
    user = user_fixture()
    user = Repo.update!(Ecto.Changeset.change(user, billing_admin: true))

    conn = log_in_user(conn, user)

    assert {:ok, view, _html} = live(conn, "/admin/analytics/recovery")
    html = render_async(view)

    # Assert KPI cards render the multi-currency data from seeds
    assert html =~ "Recovered MRR (USD)"
    assert html =~ "Exhausted MRR (JPY)"

    # 12000 cents in USD
    assert html =~ "$120.00"
    # 30000 cents in JPY
    assert html =~ "¥30,000"

    # Assert funnel chart
    assert html =~ "Recovery Funnel"

    # Assert At-Risk table
    assert html =~ "At-Risk Subscriptions"
  end
end
