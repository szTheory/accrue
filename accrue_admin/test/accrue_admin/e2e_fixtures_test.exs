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

  Phase 191 adds the page-flow fixture matrix contract:
  - seed_phase191_matrix!/0 returns deterministic route IDs for every page-flow
    detail route placeholder in baseline-manifest.js
  - e2e_phase191 namespaced rows cover null optional fields, boundary counts,
    high counts, non-ASCII names, webhook failure, and at-risk recovery
  - POST /__e2e__/seed/phase191-matrix returns the same route contract
  """

  use AccrueAdmin.LiveCase, async: false

  import Ecto.Query

  @moduletag :phase178

  alias Accrue.Billing.{Charge, Coupon, Customer, Invoice, PromotionCode, Subscription}
  alias Accrue.Connect.Account
  alias Accrue.Events.Event
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.E2E.Fixtures
  alias AccrueAdmin.TestRepo

  @phase191_route_keys [
    :customer_id,
    :subscription_id,
    :jpy_invoice_id,
    :charge_id,
    :coupon_id,
    :promo_code_id,
    :connect_account_id,
    :source_event_id,
    :single_webhook_id,
    :at_risk_sub_id
  ]

  @phase191_plan_keys [
    :phase191_customer_id,
    :phase191_subscription_id,
    :phase191_invoice_id,
    :phase191_charge_id,
    :phase191_coupon_id,
    :phase191_promo_code_id,
    :phase191_connect_account_id,
    :phase191_event_id,
    :phase191_webhook_id,
    :phase191_at_risk_sub_id
  ]

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

  # ---------------------------------------------------------------------------
  # seed_phase191_matrix!/0 — D-09/D-10/D-11 fixture matrix
  # ---------------------------------------------------------------------------

  @tag :phase191
  test "seed_phase191_matrix!/0 returns deterministic route IDs for every Phase 191 manifest detail placeholder" do
    result = Fixtures.seed_phase191_matrix!()

    for key <- @phase191_route_keys ++ @phase191_plan_keys do
      assert Map.has_key?(result, key), "Expected Phase 191 fixture result to include #{key}"
      refute is_nil(result[key]), "Expected Phase 191 fixture result #{key} to be non-nil"
    end

    assert result.namespace == "e2e_phase191"
    assert result.phase191_customer_id == result.customer_id
    assert result.phase191_subscription_id == result.subscription_id
    assert result.phase191_invoice_id == result.jpy_invoice_id
    assert result.phase191_charge_id == result.charge_id
    assert result.phase191_coupon_id == result.coupon_id
    assert result.phase191_promo_code_id == result.promo_code_id
    assert result.phase191_connect_account_id == result.connect_account_id
    assert result.phase191_event_id == result.source_event_id
    assert result.phase191_webhook_id == result.single_webhook_id
    assert result.phase191_at_risk_sub_id == result.at_risk_sub_id

    assert TestRepo.get!(Customer, result.customer_id).processor_id == "cus_e2e_phase191_customer"
    assert TestRepo.get!(Subscription, result.subscription_id).processor_id == "sub_e2e_phase191_active"
    assert TestRepo.get!(Invoice, result.jpy_invoice_id).processor_id == "in_e2e_phase191_boundary"
    assert TestRepo.get!(Charge, result.charge_id).processor_id == "ch_e2e_phase191_boundary"
    assert TestRepo.get!(Coupon, result.coupon_id).processor_id == "coupon_e2e_phase191_unicode"
    assert TestRepo.get!(PromotionCode, result.promo_code_id).processor_id == "promo_e2e_phase191_unicode"
    assert TestRepo.get!(Account, result.connect_account_id).stripe_account_id == "acct_e2e_phase191"
    assert TestRepo.get!(Event, result.source_event_id).idempotency_key == "e2e_phase191_event"
    assert TestRepo.get!(WebhookEvent, result.single_webhook_id).processor_event_id == "evt_e2e_phase191_dead"
    assert TestRepo.get!(Subscription, result.at_risk_sub_id).processor_id == "sub_e2e_phase191_at_risk"
  end

  @tag :phase191
  test "seed_phase191_matrix!/0 persists non-ASCII names and null optional fields for Phase 191 page states" do
    result = Fixtures.seed_phase191_matrix!()

    customer = TestRepo.get!(Customer, result.customer_id)
    invoice = TestRepo.get!(Invoice, result.jpy_invoice_id)
    coupon = TestRepo.get!(Coupon, result.coupon_id)
    promo_code = TestRepo.get!(PromotionCode, result.promo_code_id)
    account = TestRepo.get!(Account, result.connect_account_id)

    assert customer.name =~ "株式会社"
    assert customer.name =~ "Café"
    assert coupon.name =~ "Crème"
    assert promo_code.code == "ÉTÉ191"
    assert promo_code.metadata["phase191_fixture"] == "non_ascii"

    assert is_nil(customer.default_payment_method_id)
    assert is_nil(invoice.hosted_url)
    assert is_nil(invoice.pdf_url)
    assert account.requirements["currently_due"] == ["external_account"]
  end

  @tag :phase191
  test "seed_phase191_matrix!/0 includes boundary pagination, high-count, webhook failure, and recovery references" do
    result = Fixtures.seed_phase191_matrix!()

    zero_count =
      Customer
      |> where([customer], customer.processor_id == "cus_e2e_phase191_zero")
      |> TestRepo.aggregate(:count, :id)

    one_row_count =
      Customer
      |> where([customer], customer.processor_id == "cus_e2e_phase191_one")
      |> TestRepo.aggregate(:count, :id)

    multi_page_count =
      Customer
      |> where([customer], like(customer.processor_id, "cus_e2e_phase191_page_%"))
      |> TestRepo.aggregate(:count, :id)

    assert result.boundary_counts.zero_rows == zero_count
    assert result.boundary_counts.one_row == one_row_count
    assert result.boundary_counts.more_than_one_page == multi_page_count
    assert result.boundary_counts.zero_rows == 0
    assert result.boundary_counts.one_row == 1
    assert result.boundary_counts.more_than_one_page >= 26
    assert result.boundary_counts.high_count >= 100_000

    webhook = TestRepo.get!(WebhookEvent, result.single_webhook_id)
    at_risk_sub = TestRepo.get!(Subscription, result.at_risk_sub_id)

    assert webhook.status == :dead
    assert webhook.raw_body =~ "evt_e2e_phase191_dead"
    assert at_risk_sub.status == :past_due
    assert at_risk_sub.dunning_campaign_started_at != nil
  end

  @tag :phase191
  test "seed_phase191_matrix!/0 resets before seeding so route IDs and counts are deterministic" do
    first = Fixtures.seed_phase191_matrix!()
    first_counts = phase191_fixture_counts()

    second = Fixtures.seed_phase191_matrix!()
    second_counts = phase191_fixture_counts()

    assert Map.take(first, @phase191_route_keys) == Map.take(second, @phase191_route_keys)
    assert first.boundary_counts == second.boundary_counts
    assert first_counts == second_counts
  end

  @tag :phase191
  test "POST /__e2e__/seed/phase191-matrix returns the one-click Phase 191 route contract" do
    conn =
      Plug.Test.conn(:post, "/__e2e__/seed/phase191-matrix")
      |> AccrueAdmin.E2E.Plug.call([])

    assert conn.status == 200,
           "Expected 200 from POST /__e2e__/seed/phase191-matrix, got #{conn.status}"

    payload = Jason.decode!(conn.resp_body)

    assert payload["namespace"] == "e2e_phase191"

    for key <- @phase191_route_keys do
      assert payload[Atom.to_string(key)], "Expected endpoint payload to include #{key}"
    end
  end

  defp phase191_fixture_counts do
    %{
      customers: TestRepo.aggregate(Customer, :count, :id),
      subscriptions: TestRepo.aggregate(Subscription, :count, :id),
      invoices: TestRepo.aggregate(Invoice, :count, :id),
      charges: TestRepo.aggregate(Charge, :count, :id),
      coupons: TestRepo.aggregate(Coupon, :count, :id),
      promo_codes: TestRepo.aggregate(PromotionCode, :count, :id),
      connect_accounts: TestRepo.aggregate(Account, :count, :id),
      events: TestRepo.aggregate(Event, :count, :id),
      webhooks: TestRepo.aggregate(WebhookEvent, :count, :id)
    }
  end
end
