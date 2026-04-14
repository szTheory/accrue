defmodule Accrue.Test.StripeFixtures do
  @moduledoc """
  Canned Stripe API response payloads for Phase 3 tests.

  Each function returns a plain map that looks like what the Stripe API
  would send on the wire: string keys, Unix-seconds timestamps, the
  `"object"` discriminator. Every fixture accepts an `overrides` map so
  individual tests can customize specific fields without hand-rolling
  an entire payload.

  Fixtures deliberately use `DateTime.utc_now/0` (not `Accrue.Clock`)
  because they emulate the external Stripe wire and should not be
  sensitive to the in-memory Fake clock.
  """

  @spec subscription_created(map()) :: map()
  def subscription_created(overrides \\ %{}) do
    now = DateTime.utc_now()
    customer_id = "cus_test_" <> rand()
    sub_id = "sub_test_" <> rand()

    base = %{
      "id" => sub_id,
      "object" => "subscription",
      "customer" => customer_id,
      "status" => "trialing",
      "cancel_at_period_end" => false,
      "pause_collection" => nil,
      "trial_start" => DateTime.to_unix(now),
      "trial_end" => DateTime.to_unix(DateTime.add(now, 14, :day)),
      "current_period_start" => DateTime.to_unix(now),
      "current_period_end" => DateTime.to_unix(DateTime.add(now, 30, :day)),
      "created" => DateTime.to_unix(now),
      "items" => %{
        "object" => "list",
        "data" => [
          %{
            "id" => "si_test_" <> rand(),
            "object" => "subscription_item",
            "price" => %{"id" => "price_test_basic", "product" => "prod_test_basic"},
            "quantity" => 1
          }
        ]
      },
      "latest_invoice" => %{
        "id" => "in_test_" <> rand(),
        "object" => "invoice",
        "status" => "paid",
        "payment_intent" => nil
      },
      "metadata" => %{}
    }

    deep_merge(base, overrides)
  end

  @spec subscription_updated(String.t(), map()) :: map()
  def subscription_updated(sub_id, overrides \\ %{}) when is_binary(sub_id) do
    subscription_created()
    |> Map.put("id", sub_id)
    |> deep_merge(overrides)
  end

  @spec invoice(map()) :: map()
  def invoice(overrides \\ %{}) do
    now = DateTime.utc_now()

    base = %{
      "id" => "in_test_" <> rand(),
      "object" => "invoice",
      "status" => "open",
      "customer" => "cus_test_" <> rand(),
      "subscription" => "sub_test_" <> rand(),
      "subtotal" => 1000,
      "tax" => 0,
      "total" => 1000,
      "amount_due" => 1000,
      "amount_paid" => 0,
      "amount_remaining" => 1000,
      "currency" => "usd",
      "number" => "TEST-001",
      "hosted_invoice_url" => "https://invoice.stripe.com/test",
      "invoice_pdf" => "https://invoice.stripe.com/test.pdf",
      "period_start" => DateTime.to_unix(now),
      "period_end" => DateTime.to_unix(DateTime.add(now, 30, :day)),
      "due_date" => nil,
      "collection_method" => "charge_automatically",
      "billing_reason" => "subscription_create",
      "finalized_at" => nil,
      "paid_at" => nil,
      "voided_at" => nil,
      "lines" => %{
        "object" => "list",
        "data" => [
          %{
            "id" => "il_test_" <> rand(),
            "object" => "line_item",
            "description" => "Basic Plan",
            "amount" => 1000,
            "currency" => "usd",
            "quantity" => 1,
            "period" => %{"start" => 0, "end" => 0},
            "proration" => false,
            "price" => %{"id" => "price_test_basic"}
          }
        ]
      },
      "metadata" => %{}
    }

    deep_merge(base, overrides)
  end

  @spec payment_intent_requires_action(map()) :: map()
  def payment_intent_requires_action(overrides \\ %{}) do
    base = %{
      "id" => "pi_test_" <> rand(),
      "object" => "payment_intent",
      "status" => "requires_action",
      "client_secret" => "pi_test_secret_" <> rand(),
      "next_action" => %{"type" => "use_stripe_sdk"},
      "amount" => 1000,
      "currency" => "usd"
    }

    deep_merge(base, overrides)
  end

  @spec payment_intent_succeeded(map()) :: map()
  def payment_intent_succeeded(overrides \\ %{}) do
    payment_intent_requires_action()
    |> deep_merge(%{"status" => "succeeded", "next_action" => nil})
    |> deep_merge(overrides)
  end

  @spec setup_intent_requires_action(map()) :: map()
  def setup_intent_requires_action(overrides \\ %{}) do
    payment_intent_requires_action()
    |> Map.put("object", "setup_intent")
    |> deep_merge(overrides)
  end

  @spec charge(map()) :: map()
  def charge(overrides \\ %{}) do
    base = %{
      "id" => "ch_test_" <> rand(),
      "object" => "charge",
      "amount" => 10_000,
      "currency" => "usd",
      "status" => "succeeded",
      "paid" => true,
      "refunded" => false,
      "balance_transaction" => %{
        "id" => "txn_test_" <> rand(),
        "object" => "balance_transaction",
        "fee" => 320,
        "fee_details" => [
          %{"amount" => 320, "type" => "stripe_fee", "currency" => "usd"}
        ],
        "net" => 9_680,
        "amount" => 10_000,
        "fee_refunded" => 0
      },
      "created" => DateTime.to_unix(DateTime.utc_now())
    }

    deep_merge(base, overrides)
  end

  @spec refund(map()) :: map()
  def refund(overrides \\ %{}) do
    base = %{
      "id" => "re_test_" <> rand(),
      "object" => "refund",
      "amount" => 10_000,
      "currency" => "usd",
      "charge" => "ch_test_" <> rand(),
      "status" => "succeeded",
      "balance_transaction" => %{
        "id" => "txn_test_" <> rand(),
        "object" => "balance_transaction",
        "fee" => 0,
        "net" => -10_000
      }
    }

    deep_merge(base, overrides)
  end

  @spec payment_method_card(map()) :: map()
  def payment_method_card(overrides \\ %{}) do
    base = %{
      "id" => "pm_test_" <> rand(),
      "object" => "payment_method",
      "type" => "card",
      "card" => %{
        "fingerprint" => "fp_" <> rand(),
        "brand" => "visa",
        "last4" => "4242",
        "exp_month" => 12,
        "exp_year" => 2030
      },
      "customer" => nil
    }

    deep_merge(base, overrides)
  end

  @spec meter_event_created(map()) :: map()
  def meter_event_created(overrides \\ %{}) do
    now = DateTime.utc_now()

    base = %{
      "id" => "mev_test_" <> rand(),
      "object" => "billing.meter_event",
      "event_name" => "api_call",
      "identifier" => "mev_ident_" <> rand(),
      "payload" => %{
        "stripe_customer_id" => "cus_test_" <> rand(),
        "value" => "1"
      },
      "timestamp" => DateTime.to_unix(now),
      "created" => DateTime.to_unix(now),
      "livemode" => false
    }

    deep_merge(base, overrides)
  end

  @spec meter_event_error_report_triggered(map()) :: map()
  def meter_event_error_report_triggered(overrides \\ %{}) do
    now = DateTime.utc_now()

    base = %{
      "id" => "mere_test_" <> rand(),
      "object" => "billing.meter.error_report",
      "meter" => "mtr_test_" <> rand(),
      "identifier" => "mev_ident_" <> rand(),
      "reason" => %{
        "error_code" => "meter_event_customer_not_found",
        "error_message" => "customer not found"
      },
      "validation_start" => DateTime.to_unix(now),
      "validation_end" => DateTime.to_unix(now)
    }

    deep_merge(base, overrides)
  end

  @spec subscription_schedule(map()) :: map()
  def subscription_schedule(overrides \\ %{}) do
    now = DateTime.utc_now()
    sched_id = "sub_sched_test_" <> rand()
    customer_id = "cus_test_" <> rand()

    phase_a_start = DateTime.to_unix(now)
    phase_a_end = DateTime.to_unix(DateTime.add(now, 30, :day))
    phase_b_end = DateTime.to_unix(DateTime.add(now, 60, :day))

    base = %{
      "id" => sched_id,
      "object" => "subscription_schedule",
      "customer" => customer_id,
      "status" => "not_started",
      "end_behavior" => "release",
      "phases" => [
        %{
          "start_date" => phase_a_start,
          "end_date" => phase_a_end,
          "items" => [%{"price" => "price_intro", "quantity" => 1}]
        },
        %{
          "start_date" => phase_a_end,
          "end_date" => phase_b_end,
          "items" => [%{"price" => "price_regular", "quantity" => 1}]
        }
      ],
      "current_phase" => nil,
      "released_at" => nil,
      "canceled_at" => nil,
      "created" => DateTime.to_unix(now),
      "metadata" => %{}
    }

    deep_merge(base, overrides)
  end

  @spec webhook_event(String.t(), map(), map()) :: map()
  def webhook_event(type, object_payload, overrides \\ %{})
      when is_binary(type) and is_map(object_payload) do
    base = %{
      "id" => "evt_test_" <> rand(),
      "object" => "event",
      "type" => type,
      "created" => DateTime.to_unix(DateTime.utc_now()),
      "data" => %{"object" => object_payload}
    }

    deep_merge(base, overrides)
  end

  # --- helpers -------------------------------------------------------

  defp rand do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)
  end

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _k, l, r -> deep_merge(l, r) end)
  end

  defp deep_merge(_left, right), do: right
end
