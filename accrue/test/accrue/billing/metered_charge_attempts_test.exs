defmodule Accrue.Billing.MeteredChargeAttemptsTest do
  @moduledoc """
  Phase 103 Plan 03 RED tests for durable metered-renewal settlement state.
  """
  use Accrue.BillingCase, async: false

  import Ecto.Query

  alias Accrue.Billing.{
    Customer,
    Invoice,
    MeteredChargeAttempt,
    MeteredRenewal,
    MeteredRenewalActions,
    PaymentMethod,
    Subscription
  }

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "braintree",
        processor_id:
          "cus_metered_charge_" <> Integer.to_string(System.unique_integer([:positive])),
        email: "metered-charge@example.com"
      })
      |> Repo.insert()

    {:ok, failed_payment_method} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "pm_metered_failed_" <> Integer.to_string(System.unique_integer([:positive])),
        type: "card",
        fingerprint: "fp-failed-" <> Integer.to_string(System.unique_integer([:positive])),
        card_brand: "Visa",
        card_last4: "1111",
        card_exp_month: 12,
        card_exp_year: 2035
      })
      |> Repo.insert()

    {:ok, repaired_payment_method} =
      %PaymentMethod{}
      |> PaymentMethod.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "pm_metered_fixed_" <> Integer.to_string(System.unique_integer([:positive])),
        type: "card",
        fingerprint: "fp-fixed-" <> Integer.to_string(System.unique_integer([:positive])),
        card_brand: "Mastercard",
        card_last4: "4242",
        card_exp_month: 1,
        card_exp_year: 2038
      })
      |> Repo.insert()

    {:ok, customer} =
      customer
      |> Customer.changeset(%{default_payment_method_id: failed_payment_method.id})
      |> Repo.update()

    {:ok, subscription} =
      %Subscription{}
      |> Subscription.changeset(%{
        customer_id: customer.id,
        processor: "braintree",
        processor_id:
          "sub_metered_charge_" <> Integer.to_string(System.unique_integer([:positive])),
        status: :active,
        current_period_start: ~U[2026-05-01 00:00:00Z],
        current_period_end: ~U[2026-06-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, invoice} =
      %Invoice{}
      |> Invoice.changeset(%{
        customer_id: customer.id,
        subscription_id: subscription.id,
        processor: "braintree",
        processor_id: "mrinv_" <> Ecto.UUID.generate(),
        status: :open,
        currency: "usd",
        subtotal_minor: 2400,
        total_minor: 2400,
        billing_reason: "metered_cycle",
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z]
      })
      |> Repo.insert()

    {:ok, renewal} =
      %MeteredRenewal{}
      |> MeteredRenewal.changeset(%{
        subscription_id: subscription.id,
        customer_id: customer.id,
        processor: "braintree",
        state: :pending,
        period_start: ~U[2026-04-01 00:00:00Z],
        period_end: ~U[2026-05-01 00:00:00Z],
        trigger_source: "worker",
        invoice_id: invoice.id,
        invoice_status: "authored",
        invoice_authored_at: ~U[2026-05-01 00:05:00Z],
        snapshot: %{
          "subscription_id" => subscription.id,
          "subscription_processor_id" => subscription.processor_id,
          "meter_definitions" => []
        },
        data: %{"invoice_id" => invoice.id, "invoice_status" => "authored"}
      })
      |> Repo.insert()

    %{
      customer: customer,
      failed_payment_method: failed_payment_method,
      repaired_payment_method: repaired_payment_method,
      renewal: renewal
    }
  end

  test "retryable processor failures schedule replay while preserving one renewal-owned charge unit",
       %{renewal: renewal, failed_payment_method: failed_payment_method} do
    assert {:error, %Accrue.APIError{}} =
             MeteredRenewalActions.settle_metered_renewal(renewal.id,
               processor_error: :transient_gateway_timeout
             )

    attempt =
      Repo.one!(from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id))

    assert attempt.status == :retry_scheduled
    assert attempt.failure_class == "retryable"
    assert attempt.attempted_payment_method_id == failed_payment_method.processor_id
    assert is_binary(attempt.subject_uuid)
    assert %DateTime{} = attempt.retry_at

    reloaded = Repo.get!(MeteredRenewal, renewal.id)
    assert reloaded.state == :retry_scheduled
  end

  test "missing or repaired payment methods reuse the same charge unit and preserve the original failure audit",
       %{customer: customer, renewal: renewal, repaired_payment_method: repaired_payment_method} do
    {:ok, _customer} =
      customer
      |> Customer.changeset(%{default_payment_method_id: nil})
      |> Repo.update()

    assert {:error, %Accrue.Error.NoDefaultPaymentMethod{customer_id: customer_id}} =
             MeteredRenewalActions.settle_metered_renewal(renewal.id)

    assert customer_id == customer.id

    first_attempt =
      Repo.one!(from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id))

    assert first_attempt.status == :awaiting_payment_method
    assert first_attempt.failure_class == "payment_method_required"
    assert is_nil(first_attempt.attempted_payment_method_id)

    {:ok, _customer} =
      Repo.get!(Customer, customer.id)
      |> Customer.changeset(%{default_payment_method_id: repaired_payment_method.id})
      |> Repo.update()

    assert {:ok, _result} = MeteredRenewalActions.settle_metered_renewal(renewal.id)
    assert Repo.aggregate(MeteredChargeAttempt, :count, :id) == 1

    repaired_attempt =
      Repo.one!(from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id))

    assert repaired_attempt.status == :paid
    assert repaired_attempt.attempted_payment_method_id == repaired_payment_method.processor_id
    assert repaired_attempt.original_failed_payment_method_id == nil
    assert repaired_attempt.original_failure_class == "payment_method_required"
    assert repaired_attempt.subject_uuid == first_attempt.subject_uuid

    reloaded = Repo.get!(MeteredRenewal, renewal.id)
    assert reloaded.state == :paid
  end

  test "hard declines exhaust the renewal into operator-visible terminal state", %{
    renewal: renewal
  } do
    assert {:error, %Accrue.CardError{decline_code: "do_not_honor"}} =
             MeteredRenewalActions.settle_metered_renewal(renewal.id,
               processor_error: :hard_decline
             )

    attempt =
      Repo.one!(from(a in MeteredChargeAttempt, where: a.metered_renewal_id == ^renewal.id))

    assert attempt.status == :failed_exhausted
    assert attempt.failure_class == "hard_decline"
    assert attempt.failure_code == "do_not_honor"

    reloaded = Repo.get!(MeteredRenewal, renewal.id)
    assert reloaded.state == :failed_exhausted
  end
end
