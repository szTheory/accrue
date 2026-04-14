defmodule Accrue.Billing.SubscriptionActions do
  @moduledoc """
  Phase 3 Plan 04 subscription write surface (BILL-03/04/06/07/08/09/10).

  Every function here is exposed on `Accrue.Billing` via `defdelegate`
  (wired in Plan 01 Task 4). All public functions follow the dual-API
  `foo/n` + `foo!/n` pattern and emit an `accrue_events` row inside the
  same `Repo.transact/2` as the DB mutation (EVT-04 invariant).

  The intent_result tagged return (D3-06..12) is used for ops that can
  surface a requires_action PaymentIntent (`subscribe`, `swap_plan`,
  `cancel` when `invoice_now: true`). Non-intent ops return plain
  `{:ok, %Subscription{}}`.
  """

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Accrue.Actor
  alias Accrue.Billing.Customer
  alias Accrue.Billing.IntentResult
  alias Accrue.Billing.Subscription
  alias Accrue.Billing.SubscriptionItem
  alias Accrue.Billing.SubscriptionProjection
  alias Accrue.Billing.Trial
  alias Accrue.Billing.UpcomingInvoice
  alias Accrue.Events
  alias Accrue.Processor
  alias Accrue.Processor.Idempotency
  alias Accrue.Repo

  # ---------------------------------------------------------------------
  # subscribe/2..3 (BILL-03, BILL-04, BILL-07)
  # ---------------------------------------------------------------------

  @doc """
  Creates a subscription for the given billable (or `%Customer{}`) against
  the configured processor. Returns `intent_result(Subscription.t())`.
  """
  @spec subscribe(term(), term(), keyword()) ::
          {:ok, Subscription.t()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def subscribe(billable, price_spec, opts \\ [])

  def subscribe(%Customer{} = customer, price_spec, opts) do
    do_subscribe(customer, price_spec, opts)
  end

  def subscribe(billable, price_spec, opts) do
    with {:ok, customer} <- Accrue.Billing.customer(billable) do
      do_subscribe(customer, price_spec, opts)
    end
  end

  @doc "Raising variant of `subscribe/3`."
  @spec subscribe!(term(), term(), keyword()) :: Subscription.t()
  def subscribe!(billable, price_spec, opts \\ []) do
    case subscribe(billable, price_spec, opts) do
      {:ok, %Subscription{} = sub} -> sub
      {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "subscribe!/3 failed: #{inspect(other)}"
    end
  end

  defp do_subscribe(%Customer{} = customer, price_spec, opts) do
    {price_id, quantity} = normalize_price_spec(price_spec)
    op_id = resolve_operation_id(opts)
    idem_key = Idempotency.key(:create_subscription, customer.id, op_id)

    {item_params, trial_end} = build_subscribe_params({price_id, quantity}, opts)

    stripe_params =
      %{
        customer: customer.processor_id,
        items: [item_params],
        payment_behavior: "default_incomplete",
        expand: ["latest_invoice.payment_intent"]
      }
      |> put_if(:trial_end, trial_end)
      |> maybe_put_default_pm(opts)

    result =
      Repo.transact(fn ->
        with {:ok, stripe_sub} <-
               Processor.__impl__().create_subscription(
                 stripe_params,
                 [idempotency_key: idem_key] ++ sanitize_opts(opts)
               ),
             {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
             {:ok, sub} <- insert_subscription(customer.id, attrs),
             {:ok, _items} <- upsert_items(sub, stripe_sub),
             {:ok, _} <- record_event("subscription.created", sub, %{price_id: price_id}) do
          sub = Repo.preload(sub, :subscription_items, force: true)
          {:ok, sub}
        end
      end)

    IntentResult.wrap(result)
  end

  # ---------------------------------------------------------------------
  # get_subscription/1..2
  # ---------------------------------------------------------------------

  @spec get_subscription(String.t(), keyword()) ::
          {:ok, Subscription.t()} | {:error, :not_found}
  def get_subscription(id, opts \\ []) when is_binary(id) do
    case Repo.one(from(s in Subscription, where: s.id == ^id)) do
      nil ->
        {:error, :not_found}

      %Subscription{} = sub ->
        if Keyword.get(opts, :preload, true) do
          {:ok, Repo.preload(sub, :subscription_items)}
        else
          {:ok, sub}
        end
    end
  end

  @spec get_subscription!(String.t(), keyword()) :: Subscription.t()
  def get_subscription!(id, opts \\ []) do
    case get_subscription(id, opts) do
      {:ok, sub} -> sub
      {:error, :not_found} -> raise "subscription #{id} not found"
    end
  end

  # ---------------------------------------------------------------------
  # swap_plan/3 (BILL-09)
  # ---------------------------------------------------------------------

  @swap_schema [
    proration: [
      type: {:in, [:create_prorations, :none, :always_invoice]},
      required: true
    ],
    proration_date: [type: :any, default: nil],
    billing_cycle_anchor: [
      type: {:in, [:unchanged, :now]},
      default: :unchanged
    ],
    payment_behavior: [
      type:
        {:in,
         [
           :default_incomplete,
           :pending_if_incomplete,
           :error_if_incomplete,
           :allow_incomplete
         ]},
      default: :default_incomplete
    ],
    quantity: [type: {:or, [:pos_integer, nil]}, default: nil],
    metadata: [type: {:or, [:map, nil]}, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil],
    stripe_api_version: [type: {:or, [:string, nil]}, default: nil]
  ]

  @required_proration_msg "Accrue.Billing.swap_plan/3 requires an explicit :proration option " <>
                            "(:create_prorations, :none, or :always_invoice). Accrue never " <>
                            "inherits Stripe defaults — see BILL-09."

  @spec swap_plan(Subscription.t(), String.t(), keyword()) ::
          {:ok, Subscription.t()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def swap_plan(%Subscription{} = sub, new_price_id, opts) when is_binary(new_price_id) do
    validated = validate_swap_opts!(opts)
    sub = Repo.preload(sub, :subscription_items)
    assert_single_item!(sub, "swap_plan/3")

    [existing_item | _] = sub.subscription_items
    op_id = validated[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:swap_plan, sub.id, op_id)

    item_params =
      %{id: existing_item.processor_id, price: new_price_id}
      |> maybe_put_quantity(validated[:quantity])

    stripe_params = %{
      items: [item_params],
      proration_behavior: Atom.to_string(validated[:proration]),
      expand: ["latest_invoice.payment_intent"]
    }

    result =
      Repo.transact(fn ->
        with {:ok, stripe_sub} <-
               Processor.__impl__().update_subscription(
                 sub.processor_id,
                 stripe_params,
                 idempotency_key: idem_key
               ),
             {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
             {:ok, updated} <- update_subscription_row(sub, attrs),
             {:ok, _items} <- upsert_items(updated, stripe_sub),
             {:ok, _} <-
               record_event("subscription.plan_swapped", updated, %{
                 new_price_id: new_price_id,
                 proration: validated[:proration]
               }) do
          {:ok, Repo.preload(updated, :subscription_items, force: true)}
        end
      end)

    IntentResult.wrap(result)
  end

  @spec swap_plan!(Subscription.t(), String.t(), keyword()) :: Subscription.t()
  def swap_plan!(sub, price, opts) do
    case swap_plan(sub, price, opts) do
      {:ok, %Subscription{} = s} -> s
      {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "swap_plan!/3 failed: #{inspect(other)}"
    end
  end

  defp validate_swap_opts!(opts) do
    case NimbleOptions.validate(opts, @swap_schema) do
      {:ok, v} ->
        v

      {:error, %NimbleOptions.ValidationError{key: :proration} = err} ->
        cond do
          String.contains?(err.message, "required") ->
            raise ArgumentError, @required_proration_msg

          true ->
            raise ArgumentError, err.message
        end

      {:error, %NimbleOptions.ValidationError{message: msg}} ->
        if String.contains?(msg, "proration") and String.contains?(msg, "required") do
          raise ArgumentError, @required_proration_msg
        else
          raise ArgumentError, msg
        end
    end
  end

  # ---------------------------------------------------------------------
  # preview_upcoming_invoice/1..2 (BILL-10)
  # ---------------------------------------------------------------------

  @spec preview_upcoming_invoice(Subscription.t() | Customer.t(), keyword()) ::
          {:ok, UpcomingInvoice.t()} | {:error, term()}
  def preview_upcoming_invoice(sub_or_customer, opts \\ [])

  def preview_upcoming_invoice(%Subscription{} = sub, opts) do
    sub = Repo.preload(sub, [:subscription_items, :customer])
    new_price_id = Keyword.get(opts, :new_price_id)
    proration = Keyword.get(opts, :proration, :create_prorations)

    items =
      case new_price_id do
        nil ->
          Enum.map(sub.subscription_items, fn si ->
            %{id: si.processor_id, price: si.price_id}
          end)

        pid ->
          [item | _] = sub.subscription_items
          [%{id: item.processor_id, price: pid}]
      end

    stripe_params = %{
      customer: sub.customer.processor_id,
      subscription: sub.processor_id,
      subscription_details: %{
        items: items,
        proration_behavior: Atom.to_string(proration)
      }
    }

    with {:ok, preview} <-
           Processor.__impl__().create_invoice_preview(stripe_params, sanitize_opts(opts)),
         {:ok, upcoming} <- decompose_upcoming(preview, sub) do
      {:ok, upcoming}
    end
  end

  @spec preview_upcoming_invoice!(Subscription.t() | Customer.t(), keyword()) ::
          UpcomingInvoice.t()
  def preview_upcoming_invoice!(sub_or_customer, opts \\ []) do
    case preview_upcoming_invoice(sub_or_customer, opts) do
      {:ok, %UpcomingInvoice{} = u} -> u
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "preview_upcoming_invoice!/2 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # update_quantity/2..3 (single-item invariant, D3-33)
  # ---------------------------------------------------------------------

  @spec update_quantity(Subscription.t(), pos_integer(), keyword()) ::
          {:ok, Subscription.t()} | {:error, term()}
  def update_quantity(sub, new_quantity, opts \\ [])

  def update_quantity(%Subscription{} = sub, new_quantity, opts)
      when is_integer(new_quantity) and new_quantity > 0 do
    sub = Repo.preload(sub, :subscription_items)
    assert_single_item!(sub, "update_quantity/3")

    [item | _] = sub.subscription_items
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:update_quantity, sub.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().update_subscription(
               sub.processor_id,
               %{items: [%{id: item.processor_id, quantity: new_quantity}]},
               idempotency_key: idem_key
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           {:ok, updated} <- update_subscription_row(sub, attrs),
           {:ok, _} <- upsert_items(updated, stripe_sub),
           {:ok, _} <-
             record_event("subscription.updated", updated, %{quantity: new_quantity}) do
        {:ok, Repo.preload(updated, :subscription_items, force: true)}
      end
    end)
  end

  @spec update_quantity!(Subscription.t(), pos_integer(), keyword()) :: Subscription.t()
  def update_quantity!(sub, new_quantity, opts \\ []) do
    case update_quantity(sub, new_quantity, opts) do
      {:ok, s} -> s
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "update_quantity!/3 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # cancel / cancel_at_period_end / resume / pause / unpause (Task 3)
  # ---------------------------------------------------------------------

  @cancel_schema [
    invoice_now: [type: :boolean, default: false],
    prorate: [type: :boolean, default: false],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @spec cancel(Subscription.t(), keyword()) ::
          {:ok, Subscription.t()}
          | {:ok, :requires_action, map()}
          | {:error, term()}
  def cancel(sub, opts \\ [])

  def cancel(%Subscription{} = sub, opts) do
    {:ok, v} = NimbleOptions.validate(opts, @cancel_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:cancel_subscription, sub.id, op_id)
    params = %{invoice_now: v[:invoice_now], prorate: v[:prorate]}

    result =
      Repo.transact(fn ->
        with {:ok, stripe_sub} <-
               Processor.__impl__().cancel_subscription(
                 sub.processor_id,
                 params,
                 idempotency_key: idem_key
               ),
             {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
             {:ok, updated} <- update_subscription_row(sub, attrs),
             {:ok, _} <-
               record_event("subscription.canceled", updated, %{
                 mode: "immediate",
                 invoice_now: v[:invoice_now]
               }) do
          {:ok, Repo.preload(updated, :subscription_items, force: true)}
        end
      end)

    if v[:invoice_now], do: IntentResult.wrap(result), else: result
  end

  @spec cancel!(Subscription.t(), keyword()) :: Subscription.t()
  def cancel!(sub, opts \\ []) do
    case cancel(sub, opts) do
      {:ok, %Subscription{} = s} -> s
      {:ok, :requires_action, pi} -> raise Accrue.ActionRequiredError, payment_intent: pi
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "cancel!/2 failed: #{inspect(other)}"
    end
  end

  @spec cancel_at_period_end(Subscription.t(), keyword()) ::
          {:ok, Subscription.t()} | {:error, term()}
  def cancel_at_period_end(sub, opts \\ [])

  def cancel_at_period_end(%Subscription{} = sub, opts) do
    at_dt = Keyword.get(opts, :at)
    op_id = Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
    idem_key = Idempotency.key(:cancel_at_period_end, sub.id, op_id)

    {stripe_params, local_attrs_patch, mode_payload} =
      case at_dt do
        nil ->
          {%{cancel_at_period_end: true}, %{cancel_at_period_end: true},
           %{mode: "at_period_end"}}

        %DateTime{} = dt ->
          {%{cancel_at: DateTime.to_unix(dt)}, %{cancel_at: dt},
           %{mode: "scheduled", at: DateTime.to_iso8601(dt)}}
      end

    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().update_subscription(
               sub.processor_id,
               stripe_params,
               idempotency_key: idem_key
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           merged <- Map.merge(attrs, local_attrs_patch),
           {:ok, updated} <- update_subscription_row(sub, merged),
           {:ok, _} <- record_event("subscription.canceled", updated, mode_payload) do
        {:ok, Repo.preload(updated, :subscription_items, force: true)}
      end
    end)
  end

  @spec cancel_at_period_end!(Subscription.t(), keyword()) :: Subscription.t()
  def cancel_at_period_end!(sub, opts \\ []) do
    case cancel_at_period_end(sub, opts) do
      {:ok, s} -> s
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "cancel_at_period_end!/2 failed: #{inspect(other)}"
    end
  end

  @spec resume(Subscription.t(), keyword()) :: {:ok, Subscription.t()} | {:error, term()}
  def resume(sub, opts \\ [])

  def resume(%Subscription{} = sub, _opts) do
    unless Subscription.canceling?(sub) do
      raise Accrue.Error.InvalidState,
        current: sub.status,
        attempted: :resume,
        message:
          "Accrue.Billing.resume/1 requires a canceling subscription " <>
            "(cancel_at_period_end=true with a future current_period_end). " <>
            "For paused subs use unpause/1."
    end

    op_id = Actor.current_operation_id!()
    idem_key = Idempotency.key(:resume_subscription, sub.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().update_subscription(
               sub.processor_id,
               %{cancel_at_period_end: false},
               idempotency_key: idem_key
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           merged <- Map.merge(attrs, %{cancel_at_period_end: false, cancel_at: nil}),
           {:ok, updated} <- update_subscription_row(sub, merged),
           {:ok, _} <-
             record_event("subscription.resumed", updated, %{from: "canceling"}) do
        {:ok, Repo.preload(updated, :subscription_items, force: true)}
      end
    end)
  end

  @spec resume!(Subscription.t(), keyword()) :: Subscription.t()
  def resume!(sub, opts \\ []) do
    case resume(sub, opts) do
      {:ok, s} -> s
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "resume!/1 failed: #{inspect(other)}"
    end
  end

  @pause_schema [
    behavior: [
      type: {:in, [:void, :mark_uncollectible, :keep_as_draft]},
      default: :void
    ],
    resumes_at: [type: :any, default: nil],
    operation_id: [type: {:or, [:string, nil]}, default: nil]
  ]

  @spec pause(Subscription.t(), keyword()) :: {:ok, Subscription.t()} | {:error, term()}
  def pause(sub, opts \\ [])

  def pause(%Subscription{} = sub, opts) do
    {:ok, v} = NimbleOptions.validate(opts, @pause_schema)
    op_id = v[:operation_id] || Actor.current_operation_id!()
    idem_key = Idempotency.key(:pause_subscription, sub.id, op_id)

    params =
      case v[:resumes_at] do
        nil -> %{}
        %DateTime{} = dt -> %{resumes_at: DateTime.to_unix(dt)}
      end

    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().pause_subscription_collection(
               sub.processor_id,
               v[:behavior],
               params,
               idempotency_key: idem_key
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           # Fake may store pause_collection atom-keyed; SubscriptionProjection
           # handles that, but we also force it locally to be safe.
           merged <-
             Map.put(attrs, :pause_collection, %{
               "behavior" => Atom.to_string(v[:behavior])
             }),
           {:ok, updated} <- update_subscription_row(sub, merged),
           {:ok, _} <-
             record_event("subscription.paused", updated, %{
               behavior: Atom.to_string(v[:behavior])
             }) do
        {:ok, Repo.preload(updated, :subscription_items, force: true)}
      end
    end)
  end

  @spec pause!(Subscription.t(), keyword()) :: Subscription.t()
  def pause!(sub, opts \\ []) do
    case pause(sub, opts) do
      {:ok, s} -> s
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "pause!/2 failed: #{inspect(other)}"
    end
  end

  @spec unpause(Subscription.t(), keyword()) :: {:ok, Subscription.t()} | {:error, term()}
  def unpause(sub, opts \\ [])

  def unpause(%Subscription{} = sub, _opts) do
    unless Subscription.paused?(sub) do
      raise Accrue.Error.InvalidState,
        current: sub.status,
        attempted: :unpause,
        message:
          "Accrue.Billing.unpause/1 requires a paused subscription " <>
            "(non-nil pause_collection). For canceling subs use resume/1."
    end

    op_id = Actor.current_operation_id!()
    idem_key = Idempotency.key(:unpause_subscription, sub.id, op_id)

    Repo.transact(fn ->
      with {:ok, stripe_sub} <-
             Processor.__impl__().update_subscription(
               sub.processor_id,
               %{pause_collection: nil},
               idempotency_key: idem_key
             ),
           {:ok, attrs} <- SubscriptionProjection.decompose(stripe_sub),
           merged <- Map.put(attrs, :pause_collection, nil),
           {:ok, updated} <- update_subscription_row(sub, merged),
           {:ok, _} <-
             record_event("subscription.resumed", updated, %{from: "paused"}) do
        {:ok, Repo.preload(updated, :subscription_items, force: true)}
      end
    end)
  end

  @spec unpause!(Subscription.t(), keyword()) :: Subscription.t()
  def unpause!(sub, opts \\ []) do
    case unpause(sub, opts) do
      {:ok, s} -> s
      {:error, err} when is_exception(err) -> raise err
      {:error, other} -> raise "unpause!/1 failed: #{inspect(other)}"
    end
  end

  # ---------------------------------------------------------------------
  # internals
  # ---------------------------------------------------------------------

  defp normalize_price_spec(price) when is_binary(price), do: {price, 1}

  defp normalize_price_spec({price, qty})
       when is_binary(price) and is_integer(qty) and qty > 0,
       do: {price, qty}

  defp normalize_price_spec(list) when is_list(list) do
    raise ArgumentError,
          "Accrue.Billing.subscribe/2 expects a single price_id or {price_id, quantity} " <>
            "tuple; for multi-item subs use Phase 4 update_items/3. Got: #{inspect(list)}"
  end

  defp normalize_price_spec(other) do
    raise ArgumentError,
          "Accrue.Billing.subscribe/2 price_spec must be a binary price_id or " <>
            "{price_id, quantity} tuple; got #{inspect(other)}"
  end

  defp build_subscribe_params({price, qty}, opts) do
    trial_end =
      case Keyword.get(opts, :trial_end) do
        nil -> nil
        val -> Trial.normalize_trial_end(val)
      end

    {%{price: price, quantity: qty}, trial_end}
  end

  defp put_if(map, _key, nil), do: map
  defp put_if(map, key, val), do: Map.put(map, key, val)

  defp maybe_put_default_pm(params, opts) do
    case Keyword.get(opts, :default_payment_method) do
      nil -> params
      pm_id -> Map.put(params, :default_payment_method, pm_id)
    end
  end

  defp maybe_put_quantity(item, nil), do: item
  defp maybe_put_quantity(item, qty), do: Map.put(item, :quantity, qty)

  defp sanitize_opts(opts) do
    Keyword.drop(opts, [
      :trial_end,
      :operation_id,
      :default_payment_method,
      :new_price_id,
      :proration,
      :proration_date,
      :billing_cycle_anchor,
      :payment_behavior,
      :quantity,
      :metadata,
      :at,
      :invoice_now,
      :prorate,
      :behavior,
      :resumes_at,
      :preload
    ])
  end

  defp resolve_operation_id(opts) do
    Keyword.get(opts, :operation_id) || Actor.current_operation_id!()
  end

  defp insert_subscription(customer_id, attrs) do
    %Subscription{customer_id: customer_id, processor: processor_name()}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  defp update_subscription_row(sub, attrs) do
    sub
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  defp upsert_items(sub, stripe_sub) do
    items =
      stripe_sub
      |> SubscriptionProjection.get(:items)
      |> case do
        nil -> []
        %{} = m -> SubscriptionProjection.get(m, :data) || []
        list when is_list(list) -> list
      end

    Enum.each(items, fn si ->
      upsert_item(sub, si)
    end)

    {:ok, :upserted}
  end

  defp upsert_item(sub, si) when is_map(si) do
    stripe_id = SubscriptionProjection.get(si, :id)
    price = SubscriptionProjection.get(si, :price) || %{}
    price_id = SubscriptionProjection.get(price, :id) || price_from_string(price)

    attrs = %{
      subscription_id: sub.id,
      processor: processor_name(),
      processor_id: stripe_id,
      price_id: price_id,
      processor_plan_id: price_id,
      processor_product_id: SubscriptionProjection.get(price, :product),
      quantity: SubscriptionProjection.get(si, :quantity) || 1,
      data: stringify(si),
      metadata: SubscriptionProjection.get(si, :metadata) || %{}
    }

    case Repo.one(from(i in SubscriptionItem, where: i.processor_id == ^stripe_id)) do
      nil ->
        %SubscriptionItem{}
        |> SubscriptionItem.changeset(attrs)
        |> Repo.insert!()

      existing ->
        existing
        |> SubscriptionItem.changeset(attrs)
        |> Repo.update!()
    end
  end

  defp price_from_string(price) when is_binary(price), do: price
  defp price_from_string(_), do: nil

  defp stringify(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp stringify(%{__struct__: _} = s), do: s |> Map.from_struct() |> stringify()

  defp stringify(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {to_string(k), stringify(v)}
  end

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
  defp stringify(other), do: other

  defp record_event(type, %Subscription{} = sub, data) when is_binary(type) do
    Events.record(%{
      type: type,
      subject_type: "Subscription",
      subject_id: sub.id,
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

  defp assert_single_item!(%Subscription{subscription_items: items} = sub, op) do
    if is_list(items) and length(items) > 1 do
      raise Accrue.Error.MultiItemSubscription,
        subscription_id: sub.id,
        item_count: length(items),
        message:
          "Accrue.Billing.#{op} supports single-item subscriptions only; " <>
            "for multi-item subs use Phase 4 update_items/3."
    end
  end

  defp decompose_upcoming(preview, sub) do
    currency =
      (SubscriptionProjection.get(preview, :currency) || "usd")
      |> to_string()
      |> String.to_atom()

    lines =
      for line <- (SubscriptionProjection.get(preview, :lines) || %{})
                  |> then(&(SubscriptionProjection.get(&1, :data) || [])) do
        %UpcomingInvoice.Line{
          description: SubscriptionProjection.get(line, :description),
          amount: Accrue.Money.new(SubscriptionProjection.get(line, :amount) || 0, currency),
          quantity: SubscriptionProjection.get(line, :quantity),
          period: period_tuple(SubscriptionProjection.get(line, :period)),
          proration?: SubscriptionProjection.get(line, :proration) == true,
          price_id: line |> SubscriptionProjection.get(:price) |> price_id_of()
        }
      end

    {:ok,
     %UpcomingInvoice{
       subscription_id: sub.processor_id,
       currency: currency,
       subtotal: Accrue.Money.new(SubscriptionProjection.get(preview, :subtotal) || 0, currency),
       total: Accrue.Money.new(SubscriptionProjection.get(preview, :total) || 0, currency),
       amount_due:
         Accrue.Money.new(SubscriptionProjection.get(preview, :amount_due) || 0, currency),
       starting_balance:
         Accrue.Money.new(SubscriptionProjection.get(preview, :starting_balance) || 0, currency),
       period_start: SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(preview, :period_start)),
       period_end: SubscriptionProjection.unix_to_dt(SubscriptionProjection.get(preview, :period_end)),
       proration_date:
         SubscriptionProjection.unix_to_dt(
           SubscriptionProjection.get(preview, :subscription_proration_date)
         ),
       lines: lines,
       fetched_at: Accrue.Clock.utc_now()
     }}
  end

  defp price_id_of(nil), do: nil
  defp price_id_of(str) when is_binary(str), do: str
  defp price_id_of(%{} = m), do: SubscriptionProjection.get(m, :id)

  defp period_tuple(nil), do: nil

  defp period_tuple(%{} = m) do
    start = SubscriptionProjection.get(m, :start)
    ending = SubscriptionProjection.get(m, :end)

    case {SubscriptionProjection.unix_to_dt(start), SubscriptionProjection.unix_to_dt(ending)} do
      {%DateTime{} = s, %DateTime{} = e} -> {s, e}
      _ -> nil
    end
  end
end
