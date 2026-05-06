defmodule Accrue.Billing.MeteredRenewalActions do
  @moduledoc """
  Opens immutable metered renewal windows from canonical Braintree renewal evidence.
  """

  alias Accrue.Billing.{
    Invoice,
    MeteredChargeAttempt,
    MeteredChargeAttempts,
    MeterDefinitions,
    MeteredRenewal,
    MeteredRenewalInvoice,
    PaymentMethod,
    Subscription,
    SubscriptionProjection
  }

  alias Accrue.Processor.Idempotency
  alias Accrue.{Events, Processor, Repo}
  alias Accrue.Telemetry.Ops

  @processor "braintree"

  @spec open_braintree_renewal_window(
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          String.t()
        ) ::
          {:ok, MeteredRenewal.t() | :ignored}
          | {:error, term()}
  def open_braintree_renewal_window(subscription_processor_id, evt_ts, evt_id, raw_type)
      when is_binary(subscription_processor_id) and is_binary(raw_type) do
    with %Subscription{} = subscription <-
           Repo.get_by(Subscription,
             processor: @processor,
             processor_id: subscription_processor_id
           ),
         {:ok, canonical} <- Processor.__impl__().fetch(:subscription, subscription_processor_id),
         {:ok, canonical_attrs} <-
           SubscriptionProjection.decompose(canonical, processor: :braintree),
         {:ok, renewal_attrs} <-
           renewal_attrs(subscription, canonical_attrs, evt_ts, evt_id, raw_type) do
      case renewal_attrs do
        :ignored -> {:ok, :ignored}
        attrs -> persist_renewal(subscription, attrs)
      end
    else
      nil -> {:ok, :ignored}
      {:ok, :ignored} -> {:ok, :ignored}
      other -> other
    end
  end

  @spec author_local_invoice(Ecto.UUID.t()) ::
          {:ok, %{invoice: Invoice.t(), renewal: MeteredRenewal.t()}} | {:error, term()}
  def author_local_invoice(metered_renewal_id) when is_binary(metered_renewal_id) do
    MeteredRenewalInvoice.author_invoice(metered_renewal_id)
  end

  @spec process_metered_renewal(Ecto.UUID.t()) ::
          {:ok, %{attempt: MeteredChargeAttempt.t() | nil, renewal: MeteredRenewal.t()}}
          | {:error, term()}
  def process_metered_renewal(metered_renewal_id) when is_binary(metered_renewal_id) do
    with {:ok, %{renewal: renewal}} <- author_local_invoice(metered_renewal_id),
         {:ok, result} <- settle_metered_renewal(renewal.id) do
      {:ok, result}
    end
  end

  @spec settle_metered_renewal(Ecto.UUID.t(), keyword()) ::
          {:ok, %{attempt: MeteredChargeAttempt.t(), renewal: MeteredRenewal.t()}}
          | {:error, term()}
  def settle_metered_renewal(metered_renewal_id, opts \\ []) when is_binary(metered_renewal_id) do
    with %MeteredRenewal{} = renewal <- Repo.get(MeteredRenewal, metered_renewal_id),
         :ok <- ensure_invoice_authored(renewal),
         {:ok, attempt, subject_uuid} <- settlement_attempt(renewal) do
      case resolve_payment_method(renewal) do
        {:ok, customer, payment_method} ->
          case create_settlement_charge(renewal, subject_uuid, customer, payment_method, opts) do
            {:ok, charge} ->
              with {:ok, paid_attempt} <-
                     MeteredChargeAttempts.mark_paid(attempt, charge, payment_method),
                   {:ok, paid_renewal} <-
                     mark_settled(renewal, charge, paid_attempt, payment_method) do
                {:ok, %{attempt: paid_attempt, renewal: paid_renewal}}
              end

            {:error, %Accrue.CardError{} = error, payment_method} ->
              {:ok, failed_attempt} =
                MeteredChargeAttempts.mark_failed_exhausted(attempt, error, payment_method)

              {:ok, _} =
                mark_retry_state(metered_renewal_id, :failed_exhausted, failed_attempt, error)

              {:error, error}

            {:error, error, payment_method} ->
              {:ok, retry_attempt} =
                MeteredChargeAttempts.mark_retryable(attempt, error, payment_method)

              {:ok, _} =
                mark_retry_state(metered_renewal_id, :retry_scheduled, retry_attempt, error)

              {:error, error}
          end

        {:error, %Accrue.Error.NoDefaultPaymentMethod{} = error} ->
          {:ok, awaiting_attempt} =
            MeteredChargeAttempts.mark_awaiting_payment_method(attempt, error)

          {:ok, _} =
            mark_retry_state(
              metered_renewal_id,
              :awaiting_payment_method,
              awaiting_attempt,
              error
            )

          {:error, error}
      end
    else
      {:already_paid, attempt} ->
        renewal = Repo.get!(MeteredRenewal, metered_renewal_id)
        {:ok, %{attempt: attempt, renewal: renewal}}

      nil ->
        {:error, :not_found}

      {:error, _} = error ->
        error
    end
  end

  @spec mark_invoice_authored(MeteredRenewal.t(), Invoice.t(), map()) ::
          {:ok, MeteredRenewal.t()} | {:error, term()}
  def mark_invoice_authored(%MeteredRenewal{} = renewal, %Invoice{} = invoice, attrs \\ %{})
      when is_map(attrs) do
    now = DateTime.utc_now()

    summary =
      attrs
      |> Map.new()
      |> Map.new(fn {key, value} -> {to_string(key), value} end)
      |> Map.put("invoice_id", invoice.id)
      |> Map.put("invoice_status", "authored")

    with {:ok, updated} <-
           renewal
           |> MeteredRenewal.changeset(%{
             invoice_id: invoice.id,
             invoice_status: "authored",
             invoice_authored_at: now,
             data: Map.merge(renewal.data || %{}, summary)
           })
           |> Repo.update(),
         {:ok, _event} <- record_invoice_authored_event(updated, invoice, attrs) do
      {:ok, updated}
    end
  end

  defp renewal_attrs(%Subscription{} = subscription, canonical_attrs, evt_ts, evt_id, raw_type) do
    local_start = subscription.current_period_start
    local_end = subscription.current_period_end
    next_start = canonical_attrs[:current_period_start]
    next_end = canonical_attrs[:current_period_end]

    cond do
      is_nil(local_start) or is_nil(local_end) or is_nil(next_start) or is_nil(next_end) ->
        {:ok, :ignored}

      evt_ts && DateTime.compare(evt_ts, local_end) == :lt ->
        {:ok, :ignored}

      DateTime.compare(next_start, local_end) == :lt ->
        {:ok, :ignored}

      DateTime.compare(next_end, local_end) != :gt ->
        {:ok, :ignored}

      true ->
        snapshot = build_snapshot(subscription)

        {:ok,
         %{
           subscription_id: subscription.id,
           customer_id: subscription.customer_id,
           processor: @processor,
           state: :pending,
           period_start: local_start,
           period_end: local_end,
           trigger_source: "braintree_webhook",
           snapshot: snapshot,
           last_processor_event_id: evt_id,
           last_processor_event_ts: evt_ts,
           data: %{
             "raw_event_type" => raw_type,
             "next_period_start" => maybe_iso8601(next_start),
             "next_period_end" => maybe_iso8601(next_end)
           }
         }}
    end
  end

  defp persist_renewal(%Subscription{} = subscription, attrs) do
    case Repo.transact(fn ->
           case Repo.get_by(MeteredRenewal,
                  subscription_id: subscription.id,
                  period_start: attrs.period_start,
                  period_end: attrs.period_end
                ) do
             %MeteredRenewal{} = existing ->
               {:ok, existing}

             nil ->
               with {:ok, renewal} <-
                      %MeteredRenewal{}
                      |> MeteredRenewal.changeset(attrs)
                      |> Repo.insert(),
                    {:ok, _event} <- record_opened_event(renewal, subscription, attrs),
                    {:ok, _job} <- enqueue_processing(renewal) do
                 {:ok, renewal}
               end
           end
         end) do
      {:ok, %MeteredRenewal{} = renewal} -> {:ok, renewal}
      {:ok, {:ok, %MeteredRenewal{} = renewal}} -> {:ok, renewal}
      {:ok, {:error, err}} -> {:error, err}
      {:error, err} -> {:error, err}
    end
  end

  defp build_snapshot(%Subscription{} = subscription) do
    definitions = MeterDefinitions.active_definitions_for_subscription(subscription.id)

    definition_snapshots =
      Enum.map(definitions, fn definition ->
        item = definition.subscription_item

        %{
          "meter_definition_id" => definition.id,
          "event_name" => definition.event_name,
          "subscription_item_id" => definition.subscription_item_id,
          "price_id" => definition.price_id,
          "processor_plan_id" => item && item.processor_plan_id,
          "aggregation_mode" => definition.aggregation_mode,
          "billing_snapshot" => definition.billing_snapshot
        }
      end)

    first = List.first(definition_snapshots) || %{}

    %{
      "subscription_id" => subscription.id,
      "subscription_processor_id" => subscription.processor_id,
      "subscription_item_id" => Map.get(first, "subscription_item_id"),
      "price_id" => Map.get(first, "price_id"),
      "processor_plan_id" => Map.get(first, "processor_plan_id"),
      "meter_definitions" => definition_snapshots
    }
  end

  defp record_opened_event(%MeteredRenewal{} = renewal, %Subscription{} = subscription, attrs) do
    Events.record(%{
      type: "metered_renewal.opened",
      subject_type: "MeteredRenewal",
      subject_id: renewal.id,
      data: %{
        source: "webhook",
        processor: @processor,
        subscription_id: subscription.id,
        subscription_processor_id: subscription.processor_id,
        period_start: maybe_iso8601(attrs.period_start),
        period_end: maybe_iso8601(attrs.period_end),
        processor_event_id: attrs.last_processor_event_id
      },
      idempotency_key:
        "metered-renewal-opened:" <>
          subscription.id <>
          ":" <> maybe_iso8601(attrs.period_start) <> ":" <> maybe_iso8601(attrs.period_end)
    })
  end

  defp record_invoice_authored_event(%MeteredRenewal{} = renewal, %Invoice{} = invoice, attrs) do
    Events.record(%{
      type: "metered_renewal.invoice_authored",
      subject_type: "MeteredRenewal",
      subject_id: renewal.id,
      data: %{
        source: "worker",
        processor: renewal.processor,
        invoice_id: invoice.id,
        invoice_processor_id: invoice.processor_id,
        matched_event_count: Map.get(attrs, :matched_event_count, 0),
        unmatched_event_count: Map.get(attrs, :unmatched_event_count, 0),
        unusable_event_count: Map.get(attrs, :unusable_event_count, 0)
      },
      idempotency_key: "metered-renewal-invoice-authored:" <> renewal.id
    })
  end

  defp enqueue_processing(%MeteredRenewal{} = renewal) do
    %{metered_renewal_id: renewal.id}
    |> Oban.Job.new(
      worker: "Accrue.Jobs.ProcessMeteredRenewal",
      queue: :accrue_meters,
      unique: [fields: [:worker, :args], keys: [:metered_renewal_id], period: 60]
    )
    |> Oban.insert()
  end

  defp maybe_iso8601(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp maybe_iso8601(_), do: nil

  defp ensure_invoice_authored(%MeteredRenewal{
         invoice_status: "authored",
         invoice_id: invoice_id
       })
       when is_binary(invoice_id),
       do: :ok

  defp ensure_invoice_authored(%MeteredRenewal{} = renewal) do
    {:error,
     %Accrue.Error.MeteredSettlementMissingPrerequisite{
       metered_renewal_id: renewal.id,
       prerequisite: :invoice_authored
     }}
  end

  defp settlement_attempt(%MeteredRenewal{} = renewal) do
    subject_uuid = Idempotency.subject_uuid(:metered_renewal_charge, renewal.id)

    with {:ok, attempt} <- MeteredChargeAttempts.ensure_attempt(renewal, subject_uuid) do
      if attempt.status == :paid do
        {:already_paid, attempt}
      else
        {:ok, attempt, subject_uuid}
      end
    end
  end

  defp resolve_payment_method(%MeteredRenewal{} = renewal) do
    customer =
      renewal.customer_id
      |> then(&Repo.get!(Accrue.Billing.Customer, &1))
      |> Repo.preload(:default_payment_method)

    case customer.default_payment_method do
      %PaymentMethod{} = payment_method ->
        {:ok, customer, payment_method}

      _ ->
        {:error,
         %Accrue.Error.NoDefaultPaymentMethod{
           customer_id: customer.id,
           message:
             "metered renewal #{renewal.id} requires the customer's current default payment method before settlement"
         }}
    end
  end

  defp create_settlement_charge(renewal, subject_uuid, customer, payment_method, opts) do
    invoice = Repo.get!(Invoice, renewal.invoice_id)
    idem_key = Idempotency.key(:create_charge, subject_uuid, renewal.id)

    request_opts = Keyword.put_new(opts, :idempotency_key, idem_key)

    params = %{
      amount: invoice.total_minor,
      currency: invoice.currency,
      customer: customer.processor_id,
      payment_method: payment_method.processor_id,
      description:
        "Metered renewal #{Date.to_iso8601(DateTime.to_date(renewal.period_start))} - " <>
          "#{Date.to_iso8601(DateTime.to_date(renewal.period_end))}",
      metadata: %{
        "accrue_subject_uuid" => subject_uuid,
        "metered_renewal_id" => renewal.id,
        "invoice_id" => invoice.id
      }
    }

    case Keyword.get(opts, :processor_error) do
      :transient_gateway_timeout ->
        {:error,
         %Accrue.APIError{
           code: "gateway_timeout",
           http_status: 502,
           message: "Gateway timeout while creating sale"
         }}

      :hard_decline ->
        {:error,
         %Accrue.CardError{
           code: "card_declined",
           decline_code: "do_not_honor",
           message: "Processor Declined: Do Not Honor"
         }}

      nil ->
        Processor.__impl__().create_charge(params, request_opts)
    end
    |> normalize_charge_result(payment_method)
  end

  defp normalize_charge_result({:ok, charge}, _payment_method), do: {:ok, charge}

  defp normalize_charge_result(
         {:error, %Accrue.Error.NoDefaultPaymentMethod{} = error},
         _payment_method
       ),
       do: {:error, error}

  defp normalize_charge_result({:error, %Accrue.CardError{} = error}, payment_method),
    do: {:error, error, payment_method}

  defp normalize_charge_result({:error, %Accrue.APIError{} = error}, payment_method),
    do: {:error, error, payment_method}

  defp normalize_charge_result({:error, error}, payment_method),
    do: {:error, error, payment_method}

  defp mark_settled(%MeteredRenewal{} = renewal, charge, attempt, payment_method) do
    now = DateTime.utc_now()

    renewal
    |> MeteredRenewal.changeset(%{
      state: :paid,
      paid_at: now,
      data:
        Map.merge(renewal.data || %{}, %{
          "processor_charge_id" => charge[:id] || charge["id"],
          "charge_attempt_id" => attempt.id,
          "payment_method_id" => payment_method.processor_id,
          "paid_at" => DateTime.to_iso8601(now)
        })
    })
    |> Repo.update()
  end

  defp mark_retry_state(metered_renewal_id, state, attempt, error) do
    renewal = Repo.get!(MeteredRenewal, metered_renewal_id)
    previous_state = renewal.state

    with {:ok, updated} <-
           renewal
           |> MeteredRenewal.changeset(%{
             state: state,
             data:
               Map.merge(renewal.data || %{}, %{
                 "charge_attempt_id" => attempt.id,
                 "settlement_error" => Exception.message(error),
                 "settlement_state" => Atom.to_string(state)
               })
           })
           |> Repo.update() do
      maybe_emit_metered_state_transition(previous_state, updated, attempt)
      {:ok, updated}
    end
  end

  defp maybe_emit_metered_state_transition(previous_state, renewal, _attempt)
       when previous_state == renewal.state,
       do: :ok

  defp maybe_emit_metered_state_transition(_previous_state, renewal, attempt)
       when renewal.state == :awaiting_payment_method do
    Ops.emit(:metered_charge_awaiting_payment_method, %{count: 1}, %{
      processor: renewal.processor,
      state: renewal.state,
      metered_renewal_id: renewal.id,
      subscription_id: renewal.subscription_id,
      failure_class: attempt.failure_class
    })
  end

  defp maybe_emit_metered_state_transition(_previous_state, renewal, attempt)
       when renewal.state == :failed_exhausted do
    Ops.emit(:metered_charge_failed_exhausted, %{count: 1}, %{
      processor: renewal.processor,
      state: renewal.state,
      metered_renewal_id: renewal.id,
      subscription_id: renewal.subscription_id,
      failure_class: attempt.failure_class
    })
  end

  defp maybe_emit_metered_state_transition(_previous_state, _renewal, _attempt), do: :ok
end
