defmodule Accrue.Entitlements.Compatibility do
  @moduledoc "Fail-closed compatibility lane between legacy LocalMap and canonical projection."

  @behaviour Accrue.Entitlements.Resolver

  alias Accrue.Entitlements.Resolver.{Canonical, LocalMap}

  @metadata_keys [
    :revision,
    :action,
    :rail,
    :environment,
    :disposition,
    :reason,
    :cohort,
    :mode,
    :account_id,
    :actor_id
  ]

  @impl true
  def resolve(billable, opts \\ []) do
    with {:ok, resolver, _decision} <- authority(billable, opts) do
      resolver.resolve(billable, opts)
    end
  end

  @spec authority(term(), keyword()) :: {:ok, module(), map()} | {:error, atom()}
  def authority(billable, opts \\ []) do
    with_telemetry(:authority, opts, fn ->
      case compatibility_config() do
        {:ok, %{mode: :disabled} = config} ->
          {:ok, LocalMap, Map.put(config, :authority, :local_map)}

        {:ok, %{mode: :shadow} = config} ->
          shadow_authority(billable, opts, config)

        {:ok, %{mode: :enabled} = config} ->
          enabled_authority(billable, opts, config)

        {:error, _} = error ->
          error
      end
    end)
  end

  @spec compare(term(), keyword()) :: {:ok, map()} | {:error, atom()}
  def compare(billable, opts \\ []) do
    with_telemetry(:compare, opts, fn ->
      with {:ok, _config} <- compatibility_config(),
           {:ok, local} <- LocalMap.resolve(billable, opts),
           {:ok, canonical} <- Canonical.resolve(billable, opts) do
        local = normalize(local)
        canonical = normalize(canonical)

        if local == canonical do
          {:ok, %{disposition: :match, blockers: [], local: local, canonical: canonical}}
        else
          {:ok,
           %{
             disposition: :mismatch,
             blockers: [:normalized_mismatch],
             local: local,
             canonical: canonical
           }}
        end
      end
    end)
  end

  @spec enable(term(), keyword()) :: :ok | {:error, atom()}
  def enable(billable, opts \\ []) do
    with_telemetry(:enable, opts, fn ->
      with {:ok, %{mode: :enabled} = config} <- compatibility_config(),
           :ok <- cohort_admits?(billable, opts, config.cohort),
           :ok <- clean_window_ok?(config, opts),
           {:ok, %{blockers: []}} <- compare(billable, opts) do
        :ok
      else
        {:ok, %{blockers: _}} -> {:error, :parity_blocked}
        {:ok, %{mode: _}} -> {:error, :not_enabled}
        {:error, _} = error -> error
      end
    end)
  end

  @spec rollback(keyword()) :: :ok
  def rollback(opts \\ []) do
    with_telemetry(:rollback, opts, fn -> :ok end)
  end

  @spec backfill(keyword(), keyword()) :: {:ok, map()} | {:error, atom()}
  def backfill(cursor \\ nil, opts \\ []) do
    with_telemetry(:backfill, opts, fn -> do_backfill(cursor, opts) end)
  end

  @spec validate_clean_window(keyword()) :: {:ok, map()} | {:error, :invalid_clean_window}
  def validate_clean_window(window) when is_list(window) do
    with %DateTime{} = started_at <- Keyword.get(window, :started_at),
         %DateTime{} = ended_at <- Keyword.get(window, :ended_at),
         count when is_integer(count) and count > 0 <- Keyword.get(window, :comparison_count),
         :lt <- DateTime.compare(started_at, ended_at) do
      {:ok, %{started_at: started_at, ended_at: ended_at, comparison_count: count}}
    else
      _ -> {:error, :invalid_clean_window}
    end
  end

  defp shadow_authority(billable, opts, config) do
    with :ok <- cohort_admits?(billable, opts, config.cohort),
         {:ok, comparison} <- compare(billable, opts) do
      {:ok, LocalMap,
       config |> Map.put(:authority, :local_map) |> Map.put(:comparison, comparison)}
    else
      {:error, :excluded_cohort} -> {:ok, LocalMap, Map.put(config, :authority, :local_map)}
      {:error, _} = error -> error
    end
  end

  defp enabled_authority(billable, opts, config) do
    case enable(billable, opts) do
      :ok -> {:ok, Canonical, Map.put(config, :authority, :canonical)}
      {:error, :excluded_cohort} -> {:ok, LocalMap, Map.put(config, :authority, :local_map)}
      {:error, _} = error -> error
    end
  end

  defp compatibility_config do
    {:ok, Accrue.Config.multi_rail()}
  rescue
    error in Accrue.ConfigError ->
      message = Exception.message(error)

      if String.contains?(message, "requires an explicit cohort"),
        do: {:error, :missing_cohort},
        else: {:error, :invalid_config}
  end

  defp cohort_admits?(_billable, _opts, nil), do: {:error, :missing_cohort}

  defp cohort_admits?(_billable, opts, {:accounts, accounts}) do
    if opts[:account_id] in Enum.sort(Enum.uniq(accounts)),
      do: :ok,
      else: {:error, :excluded_cohort}
  end

  defp cohort_admits?(billable, _opts, {module, function, extra_args}) do
    if apply(module, function, [billable | extra_args]) === true,
      do: :ok,
      else: {:error, :excluded_cohort}
  rescue
    _ -> {:error, :excluded_cohort}
  end

  defp clean_window_ok?(config, opts) do
    with {:ok, window} <- validate_clean_window(config.clean_window || []),
         true <- Keyword.get(opts, :clean_window_verified, false),
         true <- window_matches_current_config?(window, config) do
      :ok
    else
      _ -> {:error, :clean_window_blocked}
    end
  end

  defp normalize(resolved), do: Map.take(resolved, [:active_plans, :features, :quantities])

  # Reads legacy records in a stable owner identity order and writes only the
  # canonical account/grant projection. It deliberately has no processor or
  # advisory-summary dependency; repeats converge through the partial current
  # grant identity installed by Phase 216.
  defp do_backfill(cursor, opts) do
    import Ecto.Query

    alias Accrue.Billing.{Customer, Query, Subscription, SubscriptionItem}
    alias Accrue.Entitlements.{Account, Grant}

    repo = Accrue.Repo.repo()
    limit = Keyword.get(opts, :limit, 100)
    after_cursor = cursor || Keyword.get(opts, :cursor)

    rows =
      Subscription
      |> Query.entitling()
      |> where([subscription], subscription.processor == "stripe")
      |> join(:inner, [subscription], customer in Customer,
        on: customer.id == subscription.customer_id
      )
      |> join(:inner, [subscription, _customer], item in SubscriptionItem,
        on: item.subscription_id == subscription.id
      )
      |> order_by([_subscription, customer],
        asc: customer.owner_type,
        asc: customer.owner_id,
        asc: customer.id
      )
      |> select([subscription, customer, item], {customer, subscription, item})
      |> repo.all()
      |> Enum.filter(fn {customer, _subscription, _item} ->
        is_nil(after_cursor) or customer_cursor(customer) > after_cursor
      end)
      |> Enum.take(limit)

    result =
      Enum.reduce(
        rows,
        %{processed: 0, inserted: 0, skipped: 0, cursor: after_cursor},
        fn {customer, subscription, item}, acc ->
          case mapped_plan(item.price_id) do
            nil ->
              %{
                acc
                | processed: acc.processed + 1,
                  skipped: acc.skipped + 1,
                  cursor: customer_cursor(customer)
              }

            plan ->
              case repo.transact(fn transaction_repo ->
                     {:ok, account} =
                       Account.fetch_or_create(
                         transaction_repo,
                         customer.owner_type,
                         customer.owner_id
                       )

                     attrs = %{
                       account_id: account.id,
                       rail: :stripe,
                       environment: stripe_environment(),
                       provider_lineage_id: subscription.processor_id || subscription.id,
                       provider_product_id: item.price_id,
                       logical_plan: Atom.to_string(plan),
                       source_item_id: item.processor_id || item.id,
                       quantity: item.quantity || 1,
                       provider_order: 0,
                       account_revision: account.revision,
                       effective_at:
                         subscription.current_period_start || subscription.inserted_at ||
                           DateTime.utc_now()
                     }

                     case transaction_repo.insert(Grant.changeset(%Grant{}, attrs),
                            on_conflict: :nothing,
                            conflict_target:
                              {:unsafe_fragment,
                               "(account_id, rail, environment, provider_lineage_id, provider_product_id, source_item_id) WHERE superseded_at IS NULL"}
                          ) do
                       {:ok, _grant} ->
                         {:ok, :inserted}

                       {:error, changeset} ->
                         transaction_repo.rollback({:invalid_grant, changeset})
                     end
                   end) do
                {:ok, :inserted} ->
                  %{
                    acc
                    | processed: acc.processed + 1,
                      inserted: acc.inserted + 1,
                      cursor: customer_cursor(customer)
                  }

                {:error, _} ->
                  %{
                    acc
                    | processed: acc.processed + 1,
                      skipped: acc.skipped + 1,
                      cursor: customer_cursor(customer)
                  }
              end
          end
        end
      )

    {:ok, Map.put(result, :blockers, [])}
  rescue
    _ -> {:error, :backfill_failed}
  end

  defp customer_cursor(customer), do: {customer.owner_type, customer.owner_id, customer.id}

  defp mapped_plan(price_id) do
    Accrue.Config.entitlements()
    |> Keyword.get(:plans, [])
    |> Enum.find_value(fn {plan, entry} ->
      if price_id in Keyword.get(entry, :price_ids, []), do: plan
    end)
  end

  defp stripe_environment do
    Accrue.Config.rails()
    |> Keyword.get(:stripe, [])
    |> Keyword.get(:default_environment, :production)
  end

  defp window_matches_current_config?(window, config) do
    Keyword.get(config.clean_window || [], :cohort_digest) == digest(config.cohort) and
      Keyword.get(config.clean_window || [], :catalog_digest) ==
        digest(Accrue.Config.entitlements()) and
      Keyword.get(config.clean_window || [], :config_digest) == digest(config) and
      window.comparison_count > 0
  end

  defp digest(value),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(value)) |> Base.encode16(case: :lower)

  defp with_telemetry(operation, opts, fun) do
    metadata =
      %{
        action: operation,
        mode: safe_mode(),
        account_id: opts[:account_id],
        actor_id: hashed(opts[:actor_id])
      }
      |> Map.take(@metadata_keys)

    Accrue.Telemetry.span([:accrue, :entitlements, :compatibility, operation], metadata, fun)
  end

  defp safe_mode do
    Accrue.Config.multi_rail().mode
  rescue
    _ -> :invalid
  end

  defp hashed(nil), do: nil
  defp hashed(value), do: :crypto.hash(:sha256, to_string(value)) |> Base.encode16(case: :lower)
end
