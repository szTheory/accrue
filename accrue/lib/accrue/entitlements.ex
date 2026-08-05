defmodule Accrue.Entitlements do
  @moduledoc """
  Public, fail-closed entitlement gate API.

  Four boolean/scalar functions answer "what has this billable paid for?"
  from **local subscription state only** (via the configured
  `Accrue.Entitlements.Resolver`, default
  `Accrue.Entitlements.Resolver.LocalMap`):

    * `entitled?/2` — does the billable have a given feature?
    * `has_active_plan?/2` — does the billable hold a given plan (by atom or
      `price_id` string)?
    * `features_for/1` — the sorted, deduped list of granted features.
    * `entitlement_quantity/2` — the seat/quota count for a quota key.

  ## Fail-closed contract

  Every function fails closed: `nil`/non-billable/no-customer/no-active-sub/
  unmapped/raising-resolver all collapse to `false` / `[]` / `0`. `{:ok,
  true}` (a present affirmative match) is the SOLE path to `true`. Errors,
  exceptions, throws, and exits are caught and collapse to the fail-closed
  value — a billing/availability hiccup never grants a paid feature for free.

  ## Multi-active-plan

  `has_active_plan?/2` tests membership in the resolved `active_plans` SET
  (ALL active plan atoms), never the representative `:plan` — so a billable
  holding two active subscriptions on two different mapped plans answers
  `true` for BOTH, consistent with the UNION semantics of `entitled?/2` and
  `features_for/1`.

  ## Telemetry (per-check, NOT the audit ledger)

  Each check emits `[:accrue, :entitlements, :check, :start | :stop |
  :exception]` via `Accrue.Telemetry.span/3` with metadata
  `%{feature, result, resolver, reason, surface, subject_type, subject_id}`.
  `subject_id` is the internal customer/billable id only — never email/name
  or any PII. Per-check decisions are **telemetry only**; this module NEVER
  writes to the `accrue_events` audit ledger.

  `surface: :plug | :live` is an additive, guard-supplied metadata dimension
  (D-18): `entitled?/3` and `has_active_plan?/3` accept an optional
  `opts` keyword list whose `:surface` is merged onto the same `:check`
  span, so a deny/allow from the Plug guard is distinguishable from one from
  the LiveView `on_mount` guard. It defaults to `nil` for direct (non-guard)
  callers and is internal telemetry only — the public `Accrue.entitled?/2` /
  `Accrue.has_active_plan?/2` facade delegates stay arity 2.
  """

  alias Accrue.Entitlements.{Account, PurchaseDecision, Resolver, Snapshot}
  alias Accrue.Entitlements.Apple.{Admission, Intake, Lineage, Reconciliation}
  alias Accrue.Entitlements.Source.Registry, as: SourceRegistry

  @doc "Returns the bounded Apple purchase context for an authenticated entitlement account."
  def apple_purchase_context(%Account{} = account, opts \\ []) do
    apple_span(:purchase_context, account, Keyword.get(opts, :environment, :production), fn ->
      %{
        app_account_token: account.id,
        environment: Keyword.get(opts, :environment, :production),
        bundle_id: Keyword.get(opts, :bundle_id, "com.accrue.app")
      }
    end)
  end

  @doc "Returns the exact, externally-managed Apple subscription guidance."
  @spec apple_management() :: {:ok, Accrue.Entitlements.Source.Outcome.t()}
  def apple_management do
    SourceRegistry.outcome(:apple, :management)
  end

  @doc "Returns an explicit policy deferral for Apple Family Sharing."
  @spec apple_family_sharing() :: {:ok, Intake.Outcome.t()}
  def apple_family_sharing do
    {:ok, deferred_apple_outcome(:family_sharing_deferred, :review_policy)}
  end

  @doc "Returns an explicit policy deferral for Apple offer authoring."
  @spec apple_offer_authoring() :: {:ok, Intake.Outcome.t()}
  def apple_offer_authoring do
    {:ok, deferred_apple_outcome(:offer_authoring_deferred, :review_policy)}
  end

  @doc "Observes opaque signed Apple evidence through host-configured verification."
  def observe_apple_evidence(account, signed_transaction, opts \\ [])

  def observe_apple_evidence(%Account{} = account, signed_transaction, opts)
      when is_binary(signed_transaction) and is_list(opts) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :apple, :observe],
      apple_metadata(:observe, account, Keyword.get(opts, :environment, :production)),
      fn ->
        case Application.get_env(:accrue, :apple_reconciliation) do
          config when is_list(config) ->
            Admission.observe_purchase_or_restore(
              account,
              signed_transaction,
              opts,
              Keyword.get(config, :admission)
            )

          _ ->
            {:error, :config_invalid}
        end
      end
    )
  end

  def observe_apple_evidence(_, _, _), do: {:error, :invalid_input}

  @doc "Repairs an authorized, currently unbound Apple lineage without exposing ownership details."
  @spec repair_apple_lineage(Account.t(), binary(), keyword()) ::
          {:ok, Intake.Outcome.t()} | {:error, :unauthorized | :verification_failed}
  def repair_apple_lineage(%Account{} = account, lineage_ref, opts \\ [])
      when is_binary(lineage_ref) do
    apple_span(:repair, account, Keyword.get(opts, :environment, :production), fn ->
      authorize = Keyword.get(opts, :authorize)

      if is_function(authorize, 2) and authorize.(account, :repair_apple_lineage) == true do
        with {:ok, %Intake.VerifiedEvidence{} = evidence} <-
               reverify_apple_lineage(lineage_ref, opts),
             true <- evidence.app_account_token == account.id,
             %Lineage{} = lineage <- Accrue.Repo.repo().get(Lineage, lineage_ref),
             true <-
               lineage.environment == evidence.environment and
                 lineage.original_transaction_id == evidence.original_transaction_id do
          Intake.repair(account, lineage_ref, evidence, opts)
        else
          false -> {:error, :verification_failed}
          _ -> {:error, :verification_failed}
        end
      else
        {:error, :unauthorized}
      end
    end)
  end

  @doc "Queues bounded Apple lineage reconciliation without exposing provider history state."
  @spec reconcile_apple_lineage(Account.t(), binary(), keyword()) ::
          {:ok, Intake.Outcome.t()} | {:error, :unauthorized | :reconciliation_unavailable}
  def reconcile_apple_lineage(%Account{} = account, lineage_ref, opts \\ [])
      when is_binary(lineage_ref) do
    apple_span(:reconcile, account, Keyword.get(opts, :environment, :production), fn ->
      authorize = Keyword.get(opts, :authorize)
      repo = Keyword.get(opts, :repo, Accrue.Repo.repo())

      with true <-
             is_function(authorize, 2) and authorize.(account, :reconcile_apple_lineage) == true,
           %Lineage{account_id: account_id, environment: environment}
           when account_id == account.id <-
             repo.get(Lineage, lineage_ref),
           {:ok, _} <-
             Reconciliation.enqueue(lineage_ref, environment, :host_requested, repo: repo) do
        {:ok,
         %Intake.Outcome{
           disposition: :pending,
           reason: :reconciliation_requested,
           next_action: :retry_reconciliation
         }}
      else
        false -> {:error, :unauthorized}
        nil -> {:error, :unauthorized}
        {:error, _} -> {:error, :reconciliation_unavailable}
      end
    end)
  end

  defp reverify_apple_lineage(lineage_ref, opts) do
    case Keyword.get(opts, :reverify) do
      callback when is_function(callback, 1) -> callback.(lineage_ref)
      callback when is_function(callback, 0) -> callback.()
      _ -> {:error, :verification_failed}
    end
  end

  defp deferred_apple_outcome(reason, next_action) do
    %Intake.Outcome{disposition: :deferred, reason: reason, next_action: next_action}
  end

  defp apple_span(action, account, environment, fun) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :apple, action],
      apple_metadata(action, account, environment),
      fun
    )
  end

  defp apple_metadata(action, %Account{id: account_id}, environment) do
    %{
      action: action,
      rail: :apple,
      environment: environment,
      account_correlation: opaque_account_id(account_id)
    }
  end

  @doc "Returns a typed, revision-bound purchase preflight decision."
  @spec purchase_decision(Account.t() | String.t(), atom(), String.t(), keyword()) ::
          PurchaseDecision.t()
          | {:error, :unauthorized_billable_reference | :account_fetch_failed}
  def purchase_decision(account, rail, product_id, opts \\ []) do
    metadata = purchase_decision_metadata(account, rail, opts)

    Accrue.Telemetry.span_private([:accrue, :entitlements, :purchase_decision], metadata, fn ->
      case decision_snapshot(account, opts) do
        {:ok, snapshot} ->
          PurchaseDecision.evaluate(snapshot, rail, product_id,
            catalog: Keyword.get(opts, :catalog) || Accrue.Config.entitlement_product_catalog(),
            environment: Keyword.get(opts, :environment, :production)
          )

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  @doc "Explicitly converts a still-current block to a bounded warning decision."
  @spec override_purchase_decision(PurchaseDecision.t(), String.t(), term(), keyword()) ::
          PurchaseDecision.t()
  def override_purchase_decision(decision, reason, actor_id, opts \\ []) do
    metadata = %{
      revision: decision.revision,
      action: :override_purchase_decision,
      rail: decision.target_rail,
      environment: Keyword.get(opts, :environment, :production),
      disposition: decision.status,
      reason: decision.reason,
      account_id: opaque_account_id(Keyword.get(opts, :account_id)),
      actor_id: hashed_actor_id(actor_id)
    }

    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :override_purchase_decision],
      metadata,
      fn ->
        PurchaseDecision.override(decision, reason, actor_id,
          snapshot: Keyword.get(opts, :snapshot),
          account_id: Keyword.get(opts, :account_id),
          repo: Keyword.get(opts, :repo, Accrue.Repo.repo()),
          product_id: Keyword.fetch!(opts, :product_id),
          catalog: Keyword.get(opts, :catalog) || Accrue.Config.entitlement_product_catalog(),
          environment: Keyword.get(opts, :environment, :production),
          audit: Keyword.get(opts, :audit)
        )
      end
    )
  end

  @doc "Reads a canonical entitlement snapshot without provisioning or provider I/O."
  @spec snapshot(Account.t() | term(), keyword()) :: {:ok, Snapshot.t()} | {:error, :not_found}
  def snapshot(account_or_billable, opts \\ []) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :snapshot],
      snapshot_metadata(account_or_billable, opts),
      fn ->
        case snapshot_account(account_or_billable) do
          nil -> {:error, :not_found}
          account -> {:ok, Snapshot.fetch(Accrue.Repo.repo(), account, opts)}
        end
      end
    )
  end

  @doc "Explicitly provisions the stable account for an authenticated host owner."
  @spec provision_account(String.t(), String.t(), keyword()) ::
          {:ok, Account.t()} | {:error, term()}
  def provision_account(owner_type, owner_id, opts \\ [])
      when is_binary(owner_type) and is_binary(owner_id) do
    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :provision_account],
      %{
        action: :provision_account,
        disposition: :requested,
        reason: nil,
        revision: nil,
        account_id: nil,
        actor_id: hashed_actor_id(Keyword.get(opts, :actor_id))
      },
      fn -> Account.fetch_or_create(Accrue.Repo.repo(), owner_type, owner_id) end
    )
  end

  @doc """
  Returns `true` iff `billable`'s resolved active feature set contains
  `feature`. Fail-closed `false` otherwise.

  `opts` is an additive, internal keyword list; `surface: :plug | :live`
  (guard-supplied, D-18) is merged onto the `:check` span metadata. All
  existing 2-arity callers (incl. the `Accrue.entitled?/2` facade delegate)
  are unaffected.
  """
  @spec entitled?(term(), atom(), keyword()) :: boolean()
  def entitled?(billable, feature, opts \\ []) do
    {result, reason} =
      case resolve(billable) do
        {:ok, %{features: features} = resolved} ->
          cond do
            MapSet.member?(features, feature) ->
              {true, grant_reason(resolved, grace_features(resolved), feature)}

            expired_grace?(resolved) ->
              {false, :past_due_expired}

            empty?(resolved) ->
              {false, :no_active_subscription}

            true ->
              {false, :not_entitled}
          end

        :error ->
          {false, :error}
      end

    span(billable, feature, result, reason, opts, fn -> result end)
  end

  @doc """
  Returns `true` iff `billable` holds `plan` among its active plans. `plan`
  is a plan atom or a `price_id` string (reverse-indexed to its plan atom).
  Tests membership in the SET of ALL active plans — multi-active-plan
  correct. Fail-closed `false` otherwise.

  `opts` is an additive, internal keyword list; `surface: :plug | :live`
  (guard-supplied, D-18) is merged onto the `:check` span metadata. All
  existing 2-arity callers (incl. the `Accrue.has_active_plan?/2` facade
  delegate) are unaffected.
  """
  @spec has_active_plan?(term(), atom() | String.t(), keyword()) :: boolean()
  def has_active_plan?(billable, plan, opts \\ []) do
    {result, reason, feature} =
      case resolve(billable) do
        {:ok, %{active_plans: active_plans} = resolved} ->
          case plan_atom(plan) do
            {:ok, plan_atom} ->
              cond do
                MapSet.member?(active_plans, plan_atom) ->
                  {true, plan_grant_reason(resolved, plan_atom), plan_atom}

                MapSet.member?(expired_grace_plans(resolved), plan_atom) ->
                  {false, :past_due_expired, plan_atom}

                empty?(resolved) ->
                  {false, :no_active_subscription, plan_atom}

                true ->
                  {false, :not_entitled, plan_atom}
              end

            :error ->
              {false, :unmapped_plan, plan}
          end

        :error ->
          {false, :error, plan}
      end

    span(billable, feature, result, reason, opts, fn -> result end)
  end

  @doc """
  Returns the sorted, deduped list of features granted by `billable`'s
  active plans. Always a plain `[atom]`, never a `MapSet`. Fail-closed `[]`.
  """
  @spec features_for(term()) :: [atom()]
  def features_for(billable) do
    {features, reason} =
      case resolve(billable) do
        {:ok, %{features: features} = resolved} ->
          list = features |> MapSet.to_list() |> Enum.sort()
          {list, if(empty?(resolved), do: :no_active_subscription, else: :entitled)}

        :error ->
          {[], :error}
      end

    span(billable, nil, features != [], reason, [], fn -> features end)
  end

  @doc """
  Returns the seat/quota count for `quota_key` (`min(cap, quantity)` where a
  cap exists, else the raw quantity). Fail-closed `0`.
  """
  @spec entitlement_quantity(term(), atom()) :: non_neg_integer()
  def entitlement_quantity(billable, quota_key) do
    {quantity, reason} =
      case resolve(billable) do
        {:ok, %{quantities: quantities} = resolved} ->
          case Map.fetch(quantities, quota_key) do
            {:ok, qty} -> {qty, :entitled}
            :error -> {0, if(empty?(resolved), do: :no_active_subscription, else: :not_entitled)}
          end

        :error ->
          {0, :error}
      end

    span(billable, quota_key, quantity > 0, reason, [], fn -> quantity end)
  end

  defp decision_snapshot(account, opts) do
    case Keyword.get(opts, :snapshot) do
      %Snapshot{} = snapshot ->
        {:ok, snapshot}

      nil ->
        decision_snapshot_for_account(account, opts)
    end
  end

  # Provisioning is deliberately an explicit authenticated branch of purchase
  # orchestration, never part of `snapshot/2`. A billable reference must opt in
  # with `authenticated?: true`; callers cannot create an entitlement account by
  # merely supplying a struct that looks billable.
  defp decision_snapshot_for_account(%{__struct__: mod, id: id} = billable, opts)
       when not is_nil(id) do
    with true <- Keyword.get(opts, :authenticated?, false),
         true <- authorized_billable?(billable, opts),
         owner_type when is_binary(owner_type) <- mod.__accrue__(:billable_type),
         owner_id <- to_string(id),
         account <- Accrue.Repo.get_by(Account, owner_type: owner_type, owner_id: owner_id),
         {:ok, account} <- provision_if_absent(account, owner_type, owner_id, opts),
         %Account{} = fetched <- Accrue.Repo.get(Account, account.id) do
      {:ok, Snapshot.fetch(Accrue.Repo.repo(), fetched)}
    else
      false -> {:error, :unauthorized_billable_reference}
      _ -> {:error, :account_fetch_failed}
    end
  rescue
    _ -> {:error, :unauthorized_billable_reference}
  end

  defp decision_snapshot_for_account(account, opts) do
    case snapshot(account, opts) do
      {:ok, %Snapshot{} = snapshot} -> {:ok, snapshot}
      {:error, _} -> {:ok, nil}
    end
  end

  defp provision_if_absent(%Account{} = account, _owner_type, _owner_id, _opts),
    do: {:ok, account}

  defp provision_if_absent(nil, owner_type, owner_id, opts),
    do: provision_account(owner_type, owner_id, actor_id: Keyword.get(opts, :actor_id))

  defp authorized_billable?(billable, opts) do
    case Keyword.get(opts, :authorize) do
      fun when is_function(fun, 1) -> fun.(billable) == true
      _ -> true
    end
  end

  defp purchase_decision_metadata(account, rail, opts) do
    %{
      revision: Keyword.get(opts, :revision),
      action: :purchase_decision,
      rail: rail,
      environment: Keyword.get(opts, :environment, :production),
      disposition: :requested,
      reason: nil,
      account_id: opaque_account_id(account),
      actor_id: hashed_actor_id(Keyword.get(opts, :actor_id))
    }
  end

  defp hashed_actor_id(nil), do: nil

  defp hashed_actor_id(actor_id),
    do: :crypto.hash(:sha256, to_string(actor_id)) |> Base.encode16(case: :lower)

  defp snapshot_account(%Account{} = account), do: account

  defp snapshot_account(%{id: id, __struct__: mod}) when not is_nil(id) do
    owner_type = mod.__accrue__(:billable_type)
    Accrue.Repo.get_by(Account, owner_type: owner_type, owner_id: to_string(id))
  rescue
    _ -> nil
  end

  defp snapshot_account(account_id) when is_binary(account_id),
    do: Accrue.Repo.get(Account, account_id)

  defp snapshot_account(_), do: nil

  defp snapshot_metadata(account_or_billable, opts) do
    %{
      action: :snapshot,
      disposition: :requested,
      reason: nil,
      revision: nil,
      account_id: opaque_account_id(account_or_billable),
      actor_id: hashed_actor_id(Keyword.get(opts, :actor_id))
    }
  end

  defp opaque_account_id(%Account{id: id}), do: opaque_account_id(id)
  defp opaque_account_id(account_id) when is_binary(account_id), do: hashed_actor_id(account_id)
  defp opaque_account_id(_), do: nil

  # --------------------------------------------------------------------------
  # internals
  # --------------------------------------------------------------------------

  # Dispatches to the configured resolver, collapsing any error/exception/
  # throw/exit to :error (the fail-closed sentinel). `{:ok, resolved}` is the
  # only non-error outcome.
  defp resolve(billable) do
    case Resolver.__impl__().resolve(billable, []) do
      {:ok, resolved} -> {:ok, resolved}
      _ -> :error
    end
  rescue
    _ -> :error
  catch
    _ -> :error
    _, _ -> :error
  end

  defp empty?(%{active_plans: active_plans}), do: MapSet.size(active_plans) == 0
  defp empty?(_), do: true

  # --- Past-due grace reason selection (ENT-09, D-19) -----------------------
  # The grace fields are additive and OPTIONAL on the resolved map; a resolver
  # that does not implement the grace overlay simply omits them, and these
  # readers treat absent fields as empty sets (fail-safe: no spurious grace
  # reason). The `:reason` atom is already OTel-allowlisted (only the VALUES
  # change) — no new telemetry event, and no ops-ledger emission: per-check
  # decisions stay telemetry-only (D-19/D-21).
  defp grace_features(resolved), do: Map.get(resolved, :grace_features, MapSet.new())
  defp grace_plans(resolved), do: Map.get(resolved, :grace_plans, MapSet.new())

  defp expired_grace_plans(resolved),
    do: Map.get(resolved, :expired_grace_plans, MapSet.new())

  # A feature grant is decided BY grace when the feature is granted ONLY by a
  # past-due grace plan (`grace_features` already excludes any feature a normal
  # active plan also grants). Otherwise it is a normal `:entitled` grant.
  defp grant_reason(_resolved, grace_features, feature) do
    if MapSet.member?(grace_features, feature), do: :past_due_grace, else: :entitled
  end

  # A plan grant is decided BY grace when the matched plan was admitted via the
  # grace window (it is in `grace_plans`).
  defp plan_grant_reason(resolved, plan_atom) do
    if MapSet.member?(grace_plans(resolved), plan_atom), do: :past_due_grace, else: :entitled
  end

  # True when the resolved state has at least one plan whose past-due grace
  # window lapsed — used to surface the distinct `:past_due_expired` deny reason
  # (vs the generic `:no_active_subscription`).
  defp expired_grace?(resolved), do: MapSet.size(expired_grace_plans(resolved)) > 0

  # Reverse-index a price_id string to its plan atom; pass atoms through.
  defp plan_atom(plan) when is_atom(plan), do: {:ok, plan}

  defp plan_atom(plan) when is_binary(plan) do
    case Map.fetch(reverse_index(), plan) do
      {:ok, plan_atom} -> {:ok, plan_atom}
      :error -> :error
    end
  end

  defp plan_atom(_), do: :error

  defp reverse_index do
    plans =
      Accrue.Config.entitlements()
      |> Keyword.get(:plans, [])

    Enum.reduce(plans, %{}, fn {plan_atom, entry}, acc ->
      entry
      |> Keyword.get(:price_ids, [])
      |> Enum.reduce(acc, fn price_id, inner -> Map.put(inner, price_id, plan_atom) end)
    end)
  rescue
    _ -> %{}
  end

  # Tag for telemetry: :local_map for the default resolver, else a snake-cased
  # module-tail tag.
  defp resolver_tag do
    case Resolver.__impl__() do
      Accrue.Entitlements.Resolver.LocalMap -> :local_map
      other -> other |> Module.split() |> List.last() |> Macro.underscore() |> String.to_atom()
    end
  rescue
    _ -> :local_map
  end

  defp subject_type(%{__struct__: mod}), do: inspect(mod)
  defp subject_type(_), do: nil

  # Total — NEVER raises out of a gate function. `to_string/1` is only safe
  # for terms that implement `String.Chars` (binaries, integers, atoms);
  # tuples, maps, PIDs, structs without the protocol, and non-charlist lists
  # would raise (Protocol.UndefinedError / ArgumentError) and escape the
  # fail-closed contract because `span/5` runs OUTSIDE `resolve/2`'s rescue.
  # `inspect/1` never raises, so we fall back to it for any other shape.
  defp subject_id(%{id: id}) when is_binary(id) or is_integer(id) or is_atom(id),
    do: to_string(id)

  defp subject_id(%{id: id}) when not is_nil(id), do: inspect(id)
  defp subject_id(_), do: nil

  # Build the fully-resolved D-18 metadata BEFORE opening the span — the span
  # helper reuses one base_metadata map for :start and :stop, so the decision
  # must already be known. `:surface` (guard-supplied, Phase 124 / D-18) is
  # the ONLY key merged from `opts`; it defaults to `nil` for direct callers.
  defp span(billable, feature, result, reason, opts, fun) do
    metadata = %{
      feature: feature,
      result: result,
      resolver: resolver_tag(),
      reason: reason,
      surface: Keyword.get(opts, :surface),
      subject_type: subject_type(billable),
      subject_id: subject_id(billable)
    }

    Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fun)
  end
end
