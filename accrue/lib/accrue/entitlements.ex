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
  `%{feature, result, resolver, reason, subject_type, subject_id}`.
  `subject_id` is the internal customer/billable id only — never email/name
  or any PII. Per-check decisions are **telemetry only**; this module NEVER
  writes to the `accrue_events` audit ledger.
  """

  alias Accrue.Entitlements.Resolver

  @doc """
  Returns `true` iff `billable`'s resolved active feature set contains
  `feature`. Fail-closed `false` otherwise.
  """
  @spec entitled?(term(), atom()) :: boolean()
  def entitled?(billable, feature) do
    {result, reason} =
      case resolve(billable) do
        {:ok, %{features: features} = resolved} ->
          cond do
            MapSet.member?(features, feature) -> {true, :entitled}
            empty?(resolved) -> {false, :no_active_subscription}
            true -> {false, :not_entitled}
          end

        :error ->
          {false, :error}
      end

    span(billable, feature, result, reason, fn -> result end)
  end

  @doc """
  Returns `true` iff `billable` holds `plan` among its active plans. `plan`
  is a plan atom or a `price_id` string (reverse-indexed to its plan atom).
  Tests membership in the SET of ALL active plans — multi-active-plan
  correct. Fail-closed `false` otherwise.
  """
  @spec has_active_plan?(term(), atom() | String.t()) :: boolean()
  def has_active_plan?(billable, plan) do
    {result, reason, feature} =
      case resolve(billable) do
        {:ok, %{active_plans: active_plans} = resolved} ->
          case plan_atom(plan) do
            {:ok, plan_atom} ->
              cond do
                MapSet.member?(active_plans, plan_atom) -> {true, :entitled, plan_atom}
                empty?(resolved) -> {false, :no_active_subscription, plan_atom}
                true -> {false, :not_entitled, plan_atom}
              end

            :error ->
              {false, :unmapped_plan, plan}
          end

        :error ->
          {false, :error, plan}
      end

    span(billable, feature, result, reason, fn -> result end)
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

    span(billable, nil, features != [], reason, fn -> features end)
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

    span(billable, quota_key, quantity > 0, reason, fn -> quantity end)
  end

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
  # must already be known.
  defp span(billable, feature, result, reason, fun) do
    metadata = %{
      feature: feature,
      result: result,
      resolver: resolver_tag(),
      reason: reason,
      subject_type: subject_type(billable),
      subject_id: subject_id(billable)
    }

    Accrue.Telemetry.span([:accrue, :entitlements, :check], metadata, fun)
  end
end
