defmodule AccrueAdmin.E2EFixturesTest do
  @moduledoc """
  Wave-0 RED scaffold for SEED-01 and SEED-02 requirements.

  All tests in this module FAIL until Plan 178-02 implements
  `Fixtures.seed_edge_states!/0` and `Fixtures.seed_overflow!/0`.

  These tests define the contract that Plan 178-02 must satisfy:
  - seed_edge_states! inserts at-risk, canceling, JPY, and long-string entities
  - seed_overflow! inserts 26+ rows across entity types to trigger "Load more" pagination
  - POST /__e2e__/seed/edge-states returns 200
  - POST /__e2e__/seed/overflow returns 200
  """

  use AccrueAdmin.LiveCase, async: false

  @moduletag :phase178

  alias Accrue.Billing.{Customer, Invoice, Subscription}
  alias AccrueAdmin.E2E.Fixtures
  alias AccrueAdmin.TestRepo

  setup do
    # Reset all fixture tables before each test to ensure a clean slate.
    # reset!/0 is already defined and calls TRUNCATE ... RESTART IDENTITY CASCADE.
    Fixtures.reset!()
    :ok
  end

  # ---------------------------------------------------------------------------
  # seed_edge_states!/0 — dunning/at-risk subscription
  # ---------------------------------------------------------------------------

  test "seed_edge_states!/0 inserts at-risk subscription with :past_due status and dunning_campaign_started_at set" do
    result = Fixtures.seed_edge_states!()

    sub = TestRepo.get!(Subscription, result.at_risk_sub_id)

    assert sub.status == :past_due,
           "Expected at_risk_sub to have status :past_due, got #{inspect(sub.status)}"

    assert sub.dunning_campaign_started_at != nil,
           "Expected dunning_campaign_started_at to be set on at_risk_sub"
  end

  # ---------------------------------------------------------------------------
  # seed_edge_states!/0 — canceling subscription
  # ---------------------------------------------------------------------------

  test "seed_edge_states!/0 inserts canceling subscription (active + cancel_at_period_end: true)" do
    result = Fixtures.seed_edge_states!()

    sub = TestRepo.get!(Subscription, result.canceling_sub_id)

    assert sub.status == :active,
           "Expected canceling_sub to have status :active, got #{inspect(sub.status)}"

    assert sub.cancel_at_period_end == true,
           "Expected canceling_sub to have cancel_at_period_end: true"

    assert DateTime.compare(sub.current_period_end, DateTime.utc_now()) == :gt,
           "Expected canceling_sub current_period_end to be in the future"
  end

  # ---------------------------------------------------------------------------
  # seed_edge_states!/0 — JPY invoice
  # ---------------------------------------------------------------------------

  test "seed_edge_states!/0 inserts JPY invoice with currency jpy" do
    result = Fixtures.seed_edge_states!()

    invoice = TestRepo.get!(Invoice, result.jpy_invoice_id)

    assert invoice.currency == "jpy",
           "Expected jpy_invoice to have currency 'jpy', got #{inspect(invoice.currency)}"

    assert invoice.total_minor == 55_000,
           "Expected jpy_invoice total_minor to be 55_000 (¥55,000), got #{invoice.total_minor}"
  end

  # ---------------------------------------------------------------------------
  # seed_edge_states!/0 — long-name customer
  # ---------------------------------------------------------------------------

  test "seed_edge_states!/0 inserts long-name customer with name > 100 characters" do
    result = Fixtures.seed_edge_states!()

    customer = TestRepo.get!(Customer, result.long_name_customer_id)

    assert String.length(customer.name) > 100,
           "Expected long_name_customer.name length > 100, got #{String.length(customer.name)}"
  end

  # ---------------------------------------------------------------------------
  # seed_overflow!/0 — overflow counts
  # ---------------------------------------------------------------------------

  test "seed_overflow!/0 inserts at least 26 customers" do
    Fixtures.seed_overflow!()

    count = TestRepo.aggregate(Customer, :count, :id)

    assert count >= 26,
           "Expected at least 26 customers after seed_overflow!, got #{count}"
  end

  test "seed_overflow!/0 inserts at least 26 subscriptions" do
    Fixtures.seed_overflow!()

    count = TestRepo.aggregate(Subscription, :count, :id)

    assert count >= 26,
           "Expected at least 26 subscriptions after seed_overflow!, got #{count}"
  end

  # ---------------------------------------------------------------------------
  # HTTP POST /__e2e__/seed/edge-states — plug route
  # ---------------------------------------------------------------------------

  test "POST /__e2e__/seed/edge-states returns 200" do
    conn =
      Plug.Test.conn(:post, "/__e2e__/seed/edge-states")
      |> AccrueAdmin.E2E.Plug.call([])

    assert conn.status == 200,
           "Expected 200 from POST /__e2e__/seed/edge-states, got #{conn.status}"
  end

  # ---------------------------------------------------------------------------
  # HTTP POST /__e2e__/seed/overflow — plug route
  # ---------------------------------------------------------------------------

  test "POST /__e2e__/seed/overflow returns 200" do
    conn =
      Plug.Test.conn(:post, "/__e2e__/seed/overflow")
      |> AccrueAdmin.E2E.Plug.call([])

    assert conn.status == 200,
           "Expected 200 from POST /__e2e__/seed/overflow, got #{conn.status}"
  end
end
