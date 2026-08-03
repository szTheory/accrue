defmodule Accrue.Entitlements.PurchaseDecision do
  @moduledoc """
  Revision-bound, rail-neutral purchase preflight decisions.

  The value deliberately contains only host-renderable decision facts.  It
  never carries provider evidence, customer identity, or a mutation authority.
  """

  alias Accrue.Billing.SubscriptionActions
  alias Accrue.Entitlements.PurchaseOperation
  alias Accrue.Entitlements.Snapshot

  @statuses [:eligible, :block, :warn]
  @reasons [
    :no_equivalent_grant,
    :equivalent_other_rail,
    :missing_snapshot,
    :stale_snapshot,
    :repairing_snapshot,
    :ambiguous_snapshot,
    :unmapped_target,
    :changed_revision
  ]

  @enforce_keys [:status, :reason, :target_rail, :logical_plan, :sources, :revision, :guidance]
  defstruct [:status, :reason, :target_rail, :logical_plan, :sources, :revision, :guidance]

  @type status :: :eligible | :block | :warn
  @type reason ::
          :no_equivalent_grant
          | :equivalent_other_rail
          | :missing_snapshot
          | :stale_snapshot
          | :repairing_snapshot
          | :ambiguous_snapshot
          | :unmapped_target
          | :changed_revision
  @type t :: %__MODULE__{
          status: status(),
          reason: reason(),
          target_rail: atom(),
          logical_plan: atom() | nil,
          sources: [Snapshot.source()],
          revision: non_neg_integer() | nil,
          guidance: String.t()
        }

  @spec evaluate(Snapshot.t() | nil, atom(), String.t(), keyword()) :: t()
  def evaluate(snapshot, target_rail, product_id, opts \\ [])
      when is_atom(target_rail) and is_binary(product_id) and is_list(opts) do
    catalog = Keyword.get(opts, :catalog) || Accrue.Config.entitlement_product_catalog()
    environment = Keyword.get(opts, :environment, :production)
    logical_plan = Map.get(catalog, {target_rail, environment, product_id})

    case snapshot_reason(snapshot) do
      nil when is_nil(logical_plan) ->
        decision(:block, :unmapped_target, target_rail, nil, [], nil)

      nil ->
        evaluate_live(snapshot, target_rail, logical_plan, catalog)

      reason ->
        decision(:block, reason, target_rail, logical_plan, [], snapshot_revision(snapshot))
    end
  end

  @spec override(t(), String.t(), term(), keyword()) :: t()
  def override(decision, reason, actor_id, opts \\ [])

  def override(%__MODULE__{status: :block} = decision, reason, actor_id, opts)
      when is_binary(reason) and byte_size(reason) <= 280 and is_list(opts) do
    snapshot = Keyword.get(opts, :snapshot)

    current =
      evaluate(snapshot, decision.target_rail, target_product_id(decision, opts),
        catalog: Keyword.get(opts, :catalog) || Accrue.Config.entitlement_product_catalog(),
        environment: Keyword.get(opts, :environment, :production)
      )

    if current.status == :block and current.reason == decision.reason and
         current.revision == decision.revision do
      warn = %{current | status: :warn, guidance: warning_copy(current)}
      maybe_audit(warn, reason, actor_id, opts)
      warn
    else
      %{current | reason: :changed_revision}
    end
  end

  def override(%__MODULE__{} = decision, _reason, _actor_id, _opts), do: decision

  @doc "Rechecks a decision immediately before delegating a controllable Stripe command."
  @spec continue(t(), term(), term(), keyword()) ::
          {:ok, term()} | {:error, atom() | map() | term()}
  def continue(%__MODULE__{target_rail: :apple}, _billable, _price_spec, opts) do
    {:error,
     %{
       reason: :externally_managed,
       operation_id: Keyword.get(opts, :operation_id),
       guidance: "Manage this subscription in Apple."
     }}
  end

  def continue(%__MODULE__{target_rail: :stripe} = decision, billable, price_spec, opts) do
    snapshot = current_snapshot(decision, opts)

    current =
      evaluate(snapshot, :stripe, Keyword.fetch!(opts, :product_id),
        catalog: Keyword.get(opts, :catalog) || Accrue.Config.entitlement_product_catalog(),
        environment: Keyword.get(opts, :environment, :production)
      )

    cond do
      current.status == :block and approved_warning_current?(decision, current) ->
        operation_id = Keyword.fetch!(opts, :operation_id)
        subscribe = Keyword.get(opts, :subscribe, &SubscriptionActions.subscribe/3)

        continue_operation(
          current,
          billable,
          price_spec,
          operation_id,
          subscribe,
          Keyword.merge(opts, billable: billable, price_spec: price_spec)
        )

      current.status == :block ->
        maybe_record_apple_conflict(decision, current, opts)
        {:error, :purchase_blocked}

      current.revision != decision.revision ->
        {:error, :changed_revision}

      true ->
        operation_id = Keyword.fetch!(opts, :operation_id)
        subscribe = Keyword.get(opts, :subscribe, &SubscriptionActions.subscribe/3)

        continue_operation(
          current,
          billable,
          price_spec,
          operation_id,
          subscribe,
          Keyword.merge(opts, billable: billable, price_spec: price_spec)
        )
    end
  end

  def continue(%__MODULE__{}, _billable, _price_spec, _opts), do: {:error, :unsupported_rail}

  defp evaluate_live(snapshot, target_rail, logical_plan, _catalog) do
    sources =
      Enum.filter(snapshot.sources, fn source ->
        source.rail != target_rail and source.logical_plan == logical_plan
      end)

    if sources == [] do
      decision(:eligible, :no_equivalent_grant, target_rail, logical_plan, [], snapshot.revision)
    else
      decision(
        :block,
        :equivalent_other_rail,
        target_rail,
        logical_plan,
        sources,
        snapshot.revision
      )
    end
  end

  defp snapshot_reason(nil), do: :missing_snapshot

  defp snapshot_reason(%Snapshot{authorization_bounds: state})
       when state in [:stale, :repairing, :ambiguous], do: String.to_atom("#{state}_snapshot")

  defp snapshot_reason(%Snapshot{}), do: nil
  defp snapshot_reason(_), do: :missing_snapshot
  defp snapshot_revision(%Snapshot{revision: revision}), do: revision
  defp snapshot_revision(_), do: nil

  defp decision(status, reason, rail, plan, sources, revision)
       when status in @statuses and reason in @reasons do
    %__MODULE__{
      status: status,
      reason: reason,
      target_rail: rail,
      logical_plan: plan,
      sources: sources,
      revision: revision,
      guidance: guidance(reason)
    }
  end

  defp guidance(:equivalent_other_rail), do: "Review the existing subscription before continuing."
  defp guidance(:missing_snapshot), do: "Fetch the entitlement account before continuing."
  defp guidance(:stale_snapshot), do: "Refresh entitlement state before continuing."
  defp guidance(:repairing_snapshot), do: "Wait for entitlement repair before continuing."
  defp guidance(:ambiguous_snapshot), do: "Resolve entitlement state before continuing."

  defp guidance(:unmapped_target),
    do: "Configure the requested subscription product before continuing."

  defp guidance(:changed_revision), do: "Recheck the purchase decision before continuing."
  defp guidance(_), do: "No equivalent subscription is active."

  defp warning_copy(%__MODULE__{logical_plan: :pro, sources: [%{rail: :apple} | _]}),
    do: "This account already has Pro through Apple. Continuing creates another subscription."

  defp warning_copy(decision),
    do:
      "This account already has #{plan_label(decision.logical_plan)} through another rail. Continuing creates another subscription."

  defp plan_label(plan), do: plan |> Atom.to_string() |> String.capitalize()
  defp target_product_id(_decision, opts), do: Keyword.fetch!(opts, :product_id)

  defp current_snapshot(decision, opts) do
    case Keyword.get(opts, :snapshot_fetch) do
      fetch when is_function(fetch, 1) -> fetch.(decision)
      _ -> Keyword.get(opts, :snapshot)
    end
  end

  defp reconcile_required(operation_id) do
    {:error,
     %{
       reason: :reconcile_required,
       operation_id: operation_id,
       guidance: "Reconcile this purchase before retrying."
     }}
  end

  defp maybe_record_apple_conflict(
         %__MODULE__{status: status},
         %__MODULE__{reason: :equivalent_other_rail, sources: sources} = current,
         opts
       )
       when status != :block do
    if Enum.any?(sources, &(&1.rail == :apple)) do
      case Keyword.get(opts, :diagnostic) do
        diagnostic when is_function(diagnostic, 1) ->
          diagnostic.(%{
            action: :concurrent_apple_completion,
            disposition: :diagnostic_conflict,
            reason: :equivalent_other_rail,
            target_rail: current.target_rail,
            revision: current.revision,
            sources: Enum.map(sources, &Map.take(&1, [:rail, :environment]))
          })

        _ ->
          :ok
      end
    end
  end

  defp maybe_record_apple_conflict(_decision, _current, _opts), do: :ok

  # A warning is an audited approval of one precise, still-current block. It
  # cannot be forged from a different decision or carried across a revision.
  defp approved_warning_current?(%__MODULE__{status: :warn} = warning, %__MODULE__{} = current) do
    warning.reason == current.reason and warning.target_rail == current.target_rail and
      warning.logical_plan == current.logical_plan and warning.revision == current.revision and
      warning.sources == current.sources
  end

  defp approved_warning_current?(_, _), do: false

  # A pending operation is a hard retry barrier. The original provider call may
  # have succeeded after its response was lost, so a retry must reconcile the
  # same durable identity before it can ever issue another create command.
  defp continue_operation(decision, billable, price_spec, operation_id, subscribe, opts) do
    case operation_for(decision, operation_id, opts) do
      {:completed, operation} ->
        {:ok,
         %{
           status: :already_completed,
           subscription_id: operation.subscription_id,
           operation_id: operation_id
         }}

      {:pending, operation} ->
        reconcile_operation(operation, operation_id, opts)

      :none ->
        claim_and_dispatch(decision, billable, price_spec, operation_id, subscribe, opts)
    end
  end

  defp claim_and_dispatch(decision, billable, price_spec, operation_id, subscribe, opts) do
    case claim_pending(decision, operation_id, opts) do
      {:claimed, _operation} ->
        dispatch_operation(decision, billable, price_spec, operation_id, subscribe, opts)

      {:completed, operation} ->
        {:ok,
         %{
           status: :already_completed,
           subscription_id: operation.subscription_id,
           operation_id: operation_id
         }}

      {:pending, operation} ->
        reconcile_operation(operation, operation_id, opts)

      :none ->
        # No durable account is available for this continuation. Preserve the
        # existing in-memory compatibility behavior, but never bypass a claim
        # when an account identifier is present.
        dispatch_operation(decision, billable, price_spec, operation_id, subscribe, opts)

      :error ->
        reconcile_required(operation_id)
    end
  end

  defp dispatch_operation(decision, billable, price_spec, operation_id, subscribe, opts) do
    case subscribe.(billable, price_spec, operation_id: operation_id) do
      {:error, :ambiguous} ->
        pending_reconcile(decision, operation_id, opts)

      {:error, {:ambiguous, _}} ->
        pending_reconcile(decision, operation_id, opts)

      {:ok, subscription} = result ->
        case complete_operation(decision, operation_id, subscription, opts) do
          :ok -> result
          :error -> reconcile_required(operation_id)
        end

      result ->
        result
    end
  end

  defp reconcile_operation(operation, operation_id, opts) do
    reconcile =
      Keyword.get(opts, :reconcile, fn _operation ->
        SubscriptionActions.reconcile_subscription_create(
          Keyword.fetch!(opts, :billable),
          Keyword.fetch!(opts, :price_spec),
          operation_id
        )
      end)

    case reconcile.(operation) do
      {:ok, subscription} ->
        case complete_persisted_operation(operation, subscription, opts) do
          {:ok, _} -> {:ok, subscription}
          _ -> reconcile_required(operation_id)
        end

      _ ->
        reconcile_required(operation_id)
    end
  end

  defp pending_reconcile(_decision, operation_id, _opts), do: reconcile_required(operation_id)

  defp complete_operation(decision, operation_id, subscription, opts) do
    if persisted_account?(decision, opts) do
      with {:pending, operation} <- operation_for(decision, operation_id, opts),
           {:ok, _} <- complete_persisted_operation(operation, subscription, opts),
           do: :ok,
           else: (_ -> :error)
    else
      :ok
    end
  end

  defp complete_persisted_operation(operation, subscription, opts) do
    subscription_id = Map.get(subscription, :id) || Map.get(subscription, "id")

    if is_binary(subscription_id),
      do: PurchaseOperation.complete(repo(opts), operation, subscription_id),
      else: {:error, :missing_subscription_id}
  end

  defp operation_for(%__MODULE__{revision: _revision} = decision, operation_id, opts) do
    with true <- persisted_account?(decision, opts),
         %PurchaseOperation{} = operation <-
           PurchaseOperation.fetch(repo(opts), decision_account_id(decision, opts), operation_id) do
      if operation.status == :completed, do: {:completed, operation}, else: {:pending, operation}
    else
      _ -> :none
    end
  end

  defp claim_pending(decision, operation_id, opts) do
    if persisted_account?(decision, opts) do
      case PurchaseOperation.claim_pending(
             repo(opts),
             decision_account_id(decision, opts),
             operation_id,
             Keyword.fetch!(opts, :product_id)
           ) do
        {:claimed, operation} ->
          {:claimed, operation}

        {:existing, %PurchaseOperation{status: :completed} = operation} ->
          {:completed, operation}

        {:existing, %PurchaseOperation{} = operation} ->
          {:pending, operation}

        _ ->
          :error
      end
    else
      :none
    end
  end

  defp persisted_account?(%__MODULE__{} = decision, opts),
    do: Ecto.UUID.cast(decision_account_id(decision, opts)) != :error

  defp decision_account_id(_decision, opts), do: Keyword.get(opts, :account_id)
  defp repo(opts), do: Keyword.get(opts, :repo, Accrue.Repo.repo())

  defp maybe_audit(decision, reason, actor_id, opts) do
    case Keyword.get(opts, :audit) do
      audit when is_function(audit, 1) ->
        audit.(%{
          action: :purchase_override,
          reason: bounded_reason(reason),
          target_rail: decision.target_rail,
          logical_plan: decision.logical_plan,
          sources: Enum.map(decision.sources, &Map.take(&1, [:rail, :environment])),
          revision: decision.revision,
          outcome: decision.status,
          actor_id: hashed_actor_id(actor_id)
        })

      _ ->
        :ok
    end
  end

  defp bounded_reason(reason), do: String.slice(reason, 0, 280)
  defp hashed_actor_id(nil), do: nil

  defp hashed_actor_id(actor_id),
    do: :crypto.hash(:sha256, to_string(actor_id)) |> Base.encode16(case: :lower)
end
