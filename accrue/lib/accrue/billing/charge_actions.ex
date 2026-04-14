defmodule Accrue.Billing.ChargeActions do
  @moduledoc """
  Phase 3 Plan 06 charge / payment intent / setup intent write surface
  (BILL-20, BILL-21, BILL-22).

  Ships three public entry points, all exposed on `Accrue.Billing` via
  `defdelegate` in Plan 01 Task 4:

    * `charge/3` — atomic charge creation with SCA-safe tagged returns.
      Resolves payment method from `opts[:payment_method]` or the
      customer's `default_payment_method` association. Returns typed
      `{:error, %Accrue.Error.NoDefaultPaymentMethod{}}` when neither is
      set (BILL-21) — never silently falls back to the first attached PM
      (Cashier footgun, D3-58).
    * `create_payment_intent/2` — thin wrapper with `IntentResult.wrap/1`
      on the result.
    * `create_setup_intent/2` — BILL-22 off-session card-on-file parallel.

  Every mutation runs inside `Accrue.Repo.transact/2` with an
  `accrue_events` row written in the same transaction (EVT-04 invariant).
  """

  alias Accrue.Actor
  alias Accrue.Billing.{Charge, Customer, IntentResult, PaymentMethod}
  alias Accrue.Events
  alias Accrue.Money
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # charge/3 (BILL-20, BILL-21)
  # ---------------------------------------------------------------------

  @doc """
  Charges a customer a fixed amount of `%Accrue.Money{}`. Returns
  `intent_result(Charge.t())`:

    * `{:ok, %Charge{}}` — happy path
    * `{:ok, :requires_action, pi}` — SCA / 3DS required (BILL-20)
    * `{:error, %Accrue.Error.NoDefaultPaymentMethod{}}` — no PM resolved
      (BILL-21 — typed, loud, pattern-matchable; never silently falls
      back to "first attached PM")
    * `{:error, other}` — anything else

  ## Options

    * `:payment_method` — processor-side payment method id (e.g.
      `"pm_..."`). If absent, resolves to the customer's
      `default_payment_method` via the schema association.
    * `:description` — charge description (string).
    * `:operation_id` — deterministic idempotency seed. Defaults to
      `Accrue.Actor.current_operation_id!/0`.
  """
  @spec charge(Customer.t() | struct(), Money.t(), keyword()) ::
          {:ok, Charge.t()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def charge(billable_or_customer, %Money{} = amount, opts \\ []) do
    case resolve_customer(billable_or_customer) do
      {:ok, customer} -> do_charge(customer, amount, opts)
      {:error, _} = err -> err
    end
  end

  @doc """
  Raising variant of `charge/3`. Raises `Accrue.ActionRequiredError` on
  `{:ok, :requires_action, pi}`, re-raises typed errors otherwise.
  """
  @spec charge!(Customer.t() | struct(), Money.t(), keyword()) :: Charge.t()
  def charge!(billable_or_customer, %Money{} = amount, opts \\ []) do
    case charge(billable_or_customer, amount, opts) do
      {:ok, %Charge{} = c} -> c
      {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "charge!/3 failed: #{inspect(other)}"
    end
  end

  defp do_charge(%Customer{} = customer, %Money{} = amount, opts) do
    customer = Repo.preload(customer, :default_payment_method)
    pm_id = Keyword.get(opts, :payment_method) || default_pm_processor_id(customer)

    if is_nil(pm_id) do
      {:error,
       %Accrue.Error.NoDefaultPaymentMethod{
         customer_id: customer.id,
         message:
           "Accrue.Billing.charge/3 requires an explicit :payment_method or " <>
             "customer.default_payment_method_id. Call " <>
             "Accrue.Billing.set_default_payment_method/2 first, or pass " <>
             "opts[:payment_method]. Accrue never silently falls back to the " <>
             "first attached PM — see BILL-21."
       }}
    else
      run_charge(customer, amount, pm_id, opts)
    end
  end

  defp run_charge(%Customer{} = customer, %Money{} = amount, pm_id, opts) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    subject_uuid = Idempotency.subject_uuid(:create_charge, op_id)
    idem_key = Idempotency.key(:create_charge, subject_uuid, op_id)

    params =
      %{
        amount: amount.amount_minor,
        currency: Atom.to_string(amount.currency),
        customer: customer.processor_id,
        payment_method: pm_id,
        confirm: true,
        expand: ["balance_transaction", "payment_intent"]
      }
      |> put_if_present(:description, Keyword.get(opts, :description))

    stripe_opts = [idempotency_key: idem_key] ++ sanitize_opts(opts)

    # Call the processor OUTSIDE the Repo.transact so we can branch on
    # SCA/3DS shape without persisting a half-baked Charge row for a
    # PaymentIntent that still needs customer action. BILL-20.
    case Processor.__impl__().create_charge(params, stripe_opts) do
      {:ok, stripe_ch} ->
        case IntentResult.wrap({:ok, stripe_ch}) do
          {:ok, :requires_action, pi} ->
            {:ok, :requires_action, pi}

          {:error, _} = err ->
            err

          {:ok, _} ->
            Repo.transact(fn ->
              with {:ok, charge_row} <-
                     insert_or_fetch_charge(subject_uuid, customer, stripe_ch, amount),
                   {:ok, _} <-
                     record_event(charge_event_type(stripe_ch), charge_row, %{
                       amount_cents: amount.amount_minor,
                       currency: amount.currency
                     }) do
                {:ok, charge_row}
              end
            end)
        end

      {:error, _} = err ->
        err
    end
  end

  # ---------------------------------------------------------------------
  # create_payment_intent/2
  # ---------------------------------------------------------------------

  @doc """
  Thin wrapper over `Processor.create_payment_intent/2`. Returns
  `intent_result(map())` so SCA paths surface via
  `{:ok, :requires_action, pi}`.
  """
  @spec create_payment_intent(map(), keyword()) ::
          {:ok, map()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def create_payment_intent(params, opts \\ []) when is_map(params) do
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    # WR-01: Pre-generate a deterministic subject_uuid (D3-60/61) —
    # previously the idempotency key was keyed on (op_id, op_id), which
    # collapsed two different PaymentIntents in the same operation to
    # the same Stripe key.
    subject_uuid = Idempotency.subject_uuid(:create_payment_intent, op_id)
    idem_key = Idempotency.key(:create_payment_intent, subject_uuid, op_id)

    Processor.__impl__().create_payment_intent(
      params,
      [idempotency_key: idem_key] ++ sanitize_opts(opts)
    )
    |> IntentResult.wrap()
  end

  @doc "Raising variant of `create_payment_intent/2`."
  @spec create_payment_intent!(map(), keyword()) :: map()
  def create_payment_intent!(params, opts \\ []) do
    case create_payment_intent(params, opts) do
      {:ok, pi} -> pi
      {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "create_payment_intent!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # create_setup_intent/2 (BILL-22)
  # ---------------------------------------------------------------------

  @doc """
  BILL-22 off-session card-on-file parallel. Creates a SetupIntent with
  `usage: "off_session"` so the resulting PaymentMethod can be charged
  off-session later (e.g. subscription renewals with SCA pre-authorized).
  Returns `intent_result(map())`.
  """
  @spec create_setup_intent(Customer.t() | struct(), keyword()) ::
          {:ok, map()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def create_setup_intent(customer_or_billable, opts \\ []) do
    case resolve_customer(customer_or_billable) do
      {:ok, %Customer{} = customer} ->
        op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
        idem_key = Idempotency.key(:create_setup_intent, customer.id, op_id)
        params = %{customer: customer.processor_id, usage: "off_session"}

        Processor.__impl__().create_setup_intent(
          params,
          [idempotency_key: idem_key] ++ sanitize_opts(opts)
        )
        |> IntentResult.wrap()

      {:error, _} = err ->
        err
    end
  end

  @doc "Raising variant of `create_setup_intent/2`."
  @spec create_setup_intent!(Customer.t() | struct(), keyword()) :: map()
  def create_setup_intent!(customer_or_billable, opts \\ []) do
    case create_setup_intent(customer_or_billable, opts) do
      {:ok, si} -> si
      {:ok, :requires_action, si} -> raise Accrue.ActionRequiredError, payment_intent: si
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "create_setup_intent!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------

  defp resolve_customer(%Customer{} = c), do: {:ok, c}
  defp resolve_customer(billable), do: Accrue.Billing.customer(billable)

  defp default_pm_processor_id(%Customer{default_payment_method: %PaymentMethod{processor_id: id}}),
    do: id

  defp default_pm_processor_id(_), do: nil

  # Deterministic insert: if a charge row already exists for the derived
  # subject_uuid (retried call with the same operation_id), return the
  # existing row instead of inserting a duplicate.
  defp insert_or_fetch_charge(subject_uuid, customer, stripe_ch, amount) do
    case Repo.get(Charge, subject_uuid) do
      %Charge{} = existing ->
        {:ok, existing}

      nil ->
        insert_charge(subject_uuid, customer, stripe_ch, amount)
    end
  end

  defp insert_charge(id, %Customer{} = customer, stripe_ch, %Money{} = amount) do
    bt = get_field(stripe_ch, :balance_transaction) || %{}
    fee_minor = get_field(bt, :fee)
    fees_settled_at = if is_integer(fee_minor), do: Accrue.Clock.utc_now(), else: nil

    status =
      case get_field(stripe_ch, :status) do
        s when is_atom(s) -> Atom.to_string(s)
        s when is_binary(s) -> s
        _ -> nil
      end

    attrs = %{
      customer_id: customer.id,
      processor: processor_name(),
      processor_id: get_field(stripe_ch, :id),
      amount_cents: amount.amount_minor,
      currency: Atom.to_string(amount.currency),
      status: status,
      stripe_fee_amount_minor: fee_minor,
      stripe_fee_currency: Atom.to_string(amount.currency),
      fees_settled_at: fees_settled_at,
      data: stringify(stripe_ch),
      metadata: get_field(stripe_ch, :metadata) || %{}
    }

    %Charge{id: id}
    |> Charge.changeset(attrs)
    |> Ecto.Changeset.force_change(:id, id)
    |> Repo.insert()
  end

  defp charge_event_type(stripe_ch) do
    case get_field(stripe_ch, :status) do
      :succeeded -> "charge.succeeded"
      "succeeded" -> "charge.succeeded"
      :failed -> "charge.failed"
      "failed" -> "charge.failed"
      _ -> "charge.created"
    end
  end

  defp record_event(type, %Charge{} = charge, data) do
    Events.record(%{
      type: type,
      subject_type: "Charge",
      subject_id: charge.id,
      data: data
    })
  end

  defp processor_name do
    case Processor.__impl__() do
      Accrue.Processor.Fake -> "fake"
      Accrue.Processor.Stripe -> "stripe"
      other -> other |> Module.split() |> List.last() |> String.downcase()
    end
  end

  defp get_field(%{} = m, key) when is_atom(key) do
    Map.get(m, key) || Map.get(m, Atom.to_string(key))
  end

  defp get_field(_, _), do: nil

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp sanitize_opts(opts) do
    Keyword.drop(opts, [:payment_method, :description, :operation_id])
  end

  # Convert an atom-keyed map (from Fake) to string-keyed for deterministic
  # jsonb round-trip. Matches SubscriptionProjection.to_string_keys pattern.
  defp stringify(value) when is_map(value) and not is_struct(value) do
    for {k, v} <- value, into: %{} do
      key = if is_atom(k), do: Atom.to_string(k), else: k
      {key, stringify(v)}
    end
  end

  defp stringify(value) when is_list(value), do: Enum.map(value, &stringify/1)
  defp stringify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp stringify(value) when is_atom(value) and not is_nil(value) and not is_boolean(value),
    do: Atom.to_string(value)
  defp stringify(value), do: value
end
