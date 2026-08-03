defmodule Accrue.Entitlements.Compatibility do
  @moduledoc "Fail-closed compatibility lane between legacy LocalMap and canonical projection."

  @behaviour Accrue.Entitlements.Resolver

  import Ecto.Query

  alias Accrue.Entitlements.Resolver.{Canonical, LocalMap}
  alias Accrue.Entitlements.{CompatibilityAudit, CompatibilityState}

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
          if local_map_override?(opts),
            do: {:ok, LocalMap, Map.put(config, :authority, :local_map)},
            else: enabled_authority(billable, opts, config)

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

        blockers =
          Keyword.get(opts, :forced_blockers) || parity_blockers(local, canonical, billable)

        persist_comparison(opts, compatibility_config_value(), blockers, canonical)

        if blockers == [] do
          {:ok, %{disposition: :match, blockers: [], local: local, canonical: canonical}}
        else
          {:ok,
           %{
             disposition: :mismatch,
             blockers: blockers,
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
           :ok <- no_window_blockers?(opts[:account_id], config),
           :ok <- clean_window_ok?(config, opts),
           {:ok, %{blockers: []}} <- compare(billable, opts),
           :ok <- persist_authority(opts, :canonical, config, :enabled) do
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
    with_telemetry(:rollback, opts, fn ->
      case Keyword.get(opts, :account_id) do
        nil ->
          :ok

        account_id ->
          config = compatibility_config_value()
          :ok = persist_authority([account_id: account_id], :local_map, config, :rolled_back)
      end

      :ok
    end)
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

  @doc false
  def audit_entries(account_id, opts \\ []) when is_binary(account_id) do
    action = Keyword.get(opts, :action)

    CompatibilityAudit
    |> where([audit], audit.account_id == ^account_id)
    |> maybe_filter_action(action)
    |> order_by([audit], asc: audit.inserted_at, asc: audit.id)
    |> Accrue.Repo.repo().all()
    |> Enum.map(&audit_view/1)
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
         true <- window_matches_current_config?(window, config),
         true <- clean_shadow_evidence?(opts[:account_id], window, config) do
      :ok
    else
      _ -> {:error, :clean_window_blocked}
    end
  end

  defp normalize(resolved), do: Map.take(resolved, [:active_plans, :features, :quantities])

  # Reads legacy records in a total legacy-item order and converts each mapped
  # item into a qualified observation. The projector remains the only writer
  # of current grants, revisions, audit events, and follow-up jobs.
  defp do_backfill(cursor, opts) do
    alias Accrue.Billing.{Customer, Query, Subscription, SubscriptionItem}
    alias Accrue.Entitlements.{Account, Observation, Projector}

    repo = Accrue.Repo.repo()
    limit = Keyword.get(opts, :limit, 100)
    after_cursor = cursor || Keyword.get(opts, :cursor)
    after_key = decode_cursor(after_cursor)

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
      |> order_by([subscription, customer, item],
        asc: customer.owner_type,
        asc: customer.owner_id,
        asc: customer.id,
        asc: subscription.id,
        asc: item.id
      )
      |> select([subscription, customer, item], {customer, subscription, item})
      |> repo.all()
      |> Enum.filter(fn row ->
        is_nil(after_key) or cursor_key(row) > after_key
      end)
      |> Enum.take(limit)

    result =
      Enum.reduce(
        rows,
        %{processed: 0, inserted: 0, skipped: 0, cursor: after_cursor},
        fn {customer, subscription, item} = row, acc ->
          next_cursor = encode_cursor(cursor_key(row))

          case mapped_plan(item.price_id) do
            nil ->
              %{
                acc
                | processed: acc.processed + 1,
                  skipped: acc.skipped + 1,
                  cursor: next_cursor
              }

            _plan ->
              with {:ok, account} <-
                     Account.fetch_or_create(repo, customer.owner_type, customer.owner_id),
                   {:ok, observation} <-
                     Observation.insert_idempotently(
                       repo,
                       backfill_observation(account, subscription, item)
                     ) do
                case Projector.project(observation) do
                  {:ok, _snapshot} ->
                    %{
                      acc
                      | processed: acc.processed + 1,
                        inserted: acc.inserted + 1,
                        cursor: next_cursor
                    }

                  {:noop, _reason} ->
                    %{acc | processed: acc.processed + 1, cursor: next_cursor}

                  _ ->
                    %{
                      acc
                      | processed: acc.processed + 1,
                        skipped: acc.skipped + 1,
                        cursor: next_cursor
                    }
                end
              else
                _ ->
                  %{
                    acc
                    | processed: acc.processed + 1,
                      skipped: acc.skipped + 1,
                      cursor: next_cursor
                  }
              end
          end
        end
      )

    persist_backfill_audit(result, opts)
    {:ok, Map.put(result, :blockers, [])}
  rescue
    _ -> {:error, :backfill_failed}
  end

  defp backfill_observation(account, subscription, item) do
    source_id = to_string(item.processor_id || item.id)
    lineage = to_string(subscription.processor_id || subscription.id)

    observed_at =
      subscription.current_period_start || subscription.inserted_at || DateTime.utc_now()

    %{
      account_id: account.id,
      rail: :stripe,
      environment: stripe_environment(),
      provider_event_id: "compatibility-backfill:#{source_id}",
      provider_transaction_id: "compatibility-backfill:#{source_id}",
      kind: "grant",
      provider_lineage_id: lineage,
      provider_product_id: item.price_id,
      provider_order: 0,
      observed_at: observed_at,
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest:
        :crypto.hash(:sha256, "compatibility-backfill:#{source_id}")
        |> Base.encode16(case: :lower)
    }
  end

  defp cursor_key({customer, subscription, item}),
    do: {customer.owner_type, customer.owner_id, customer.id, subscription.id, item.id}

  defp encode_cursor(key),
    do: key |> :erlang.term_to_binary() |> Base.url_encode64(padding: false)

  defp decode_cursor(nil), do: nil

  defp decode_cursor(cursor) when is_binary(cursor) do
    with {:ok, binary} <- Base.url_decode64(cursor, padding: false),
         {key, []} <- :erlang.binary_to_term(binary, [:safe]),
         true <- is_tuple(key) and tuple_size(key) == 5 do
      key
    else
      _ -> nil
    end
  end

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
        digest(Accrue.Config.entitlement_product_catalog()) and
      Keyword.get(config.clean_window || [], :config_digest) ==
        digest(Map.drop(config, [:clean_window, :mode])) and
      window.comparison_count > 0
  end

  defp digest(value),
    do: :crypto.hash(:sha256, :erlang.term_to_binary(value)) |> Base.encode16(case: :lower)

  @doc false
  def clean_window_digests(cohort, config) do
    cohort = normalize_cohort(cohort)
    config = Map.put(config, :cohort, cohort)

    %{
      cohort_digest: digest(cohort),
      catalog_digest: digest(Accrue.Config.entitlement_product_catalog()),
      config_digest: digest(Map.drop(config, [:clean_window, :mode]))
    }
  end

  defp normalize_cohort({:accounts, accounts}),
    do: {:accounts, accounts |> Enum.uniq() |> Enum.sort()}

  defp normalize_cohort(cohort), do: cohort

  defp parity_blockers(local, canonical, billable) do
    unmapped =
      case customer_for(billable) do
        nil -> []
        customer -> Accrue.Entitlements.Resolver.LocalMap.unmapped_entitling_price_ids(customer)
      end

    cond do
      unmapped != [] -> [:unmapped_legacy]
      local != canonical -> [:normalized_mismatch]
      true -> []
    end
  rescue
    _ -> [:comparison_unavailable]
  end

  defp customer_for(%{__struct__: module, id: id}) when not is_nil(id) do
    import Ecto.Query
    alias Accrue.Billing.Customer

    Accrue.Repo.one(
      from(customer in Customer,
        where:
          customer.owner_type == ^module.__accrue__(:billable_type) and
            customer.owner_id == ^to_string(id),
        limit: 1
      )
    )
  rescue
    _ -> nil
  end

  defp customer_for(_), do: nil

  defp local_map_override?(opts) do
    case opts[:account_id] do
      account_id when is_binary(account_id) ->
        case Accrue.Repo.repo().get_by(CompatibilityState, account_id: account_id) do
          %{authority: :local_map} -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  defp compatibility_config_value do
    case compatibility_config() do
      {:ok, config} -> config
      _ -> %{mode: :disabled, cohort: nil, clean_window: nil}
    end
  end

  defp clean_shadow_evidence?(account_id, window, config)
       when is_binary(account_id) and byte_size(account_id) == 36 do
    digests = clean_window_digests(config.cohort, config)

    count =
      Accrue.Repo.repo().aggregate(
        from(audit in CompatibilityAudit,
          where:
            audit.account_id == ^account_id and audit.action == :compare and
              audit.disposition == :match and audit.blocker_count == 0 and
              audit.inserted_at >= ^window.started_at and audit.inserted_at < ^window.ended_at and
              audit.cohort_digest == ^digests.cohort_digest and
              audit.catalog_digest == ^digests.catalog_digest and
              audit.config_digest == ^digests.config_digest
        ),
        :count,
        :id
      )

    count >= window.comparison_count
  end

  defp clean_shadow_evidence?(_, _, _), do: false

  defp no_window_blockers?(account_id, config)
       when is_binary(account_id) and byte_size(account_id) == 36 do
    digests = clean_window_digests(config.cohort, config)

    case Accrue.Repo.repo().aggregate(
           from(audit in CompatibilityAudit,
             where:
               audit.account_id == ^account_id and audit.action == :compare and
                 audit.blocker_count > 0 and audit.cohort_digest == ^digests.cohort_digest and
                 audit.catalog_digest == ^digests.catalog_digest and
                 audit.config_digest == ^digests.config_digest
           ),
           :count,
           :id
         ) do
      0 -> :ok
      _ -> {:error, :parity_blocked}
    end
  end

  defp no_window_blockers?(_, _), do: {:error, :parity_blocked}

  defp persist_comparison(opts, config, blockers, canonical) do
    account_id = opts[:account_id]

    if is_binary(account_id) do
      digests = clean_window_digests(config.cohort, config)
      reason = List.first(blockers) || :none

      %CompatibilityAudit{}
      |> CompatibilityAudit.changeset(%{
        account_id: account_id,
        action: :compare,
        disposition: if(blockers == [], do: :match, else: :blocked),
        reason: reason,
        blocker_count: length(blockers),
        comparison_count: 1,
        cohort_digest: digests.cohort_digest,
        catalog_digest: digests.catalog_digest,
        config_digest: digests.config_digest,
        state_digest: digest(normalize(canonical))
      })
      |> Accrue.Repo.repo().insert!()
    end
  end

  defp persist_authority(opts, authority, config, disposition) do
    case opts[:account_id] do
      account_id when is_binary(account_id) ->
        digests = clean_window_digests(config.cohort, config)
        repo = Accrue.Repo.repo()

        state = %{
          account_id: account_id,
          authority: authority,
          transition_digest: digest({authority, digests.config_digest})
        }

        repo.insert(CompatibilityState.changeset(%CompatibilityState{}, state),
          on_conflict: [
            set: [
              authority: authority,
              transition_digest: state.transition_digest,
              updated_at: DateTime.utc_now()
            ]
          ],
          conflict_target: [:account_id]
        )

        %CompatibilityAudit{}
        |> CompatibilityAudit.changeset(%{
          account_id: account_id,
          action: if(disposition == :enabled, do: :enable, else: :rollback),
          disposition: disposition,
          reason: :none,
          blocker_count: 0,
          comparison_count: 0,
          cohort_digest: digests.cohort_digest,
          catalog_digest: digests.catalog_digest,
          config_digest: digests.config_digest,
          state_digest: state.transition_digest
        })
        |> repo.insert!()

        :ok

      _ ->
        :ok
    end
  end

  defp persist_backfill_audit(result, opts) do
    %CompatibilityAudit{}
    |> CompatibilityAudit.changeset(%{
      account_id: opts[:account_id],
      action: :backfill,
      disposition: :completed,
      reason: :none,
      blocker_count: 0,
      comparison_count: 0,
      state_digest: digest(Map.take(result, [:processed, :inserted, :skipped]))
    })
    |> Accrue.Repo.repo().insert!()
  end

  defp maybe_filter_action(query, nil), do: query
  defp maybe_filter_action(query, action), do: where(query, [audit], audit.action == ^action)

  defp audit_view(audit) do
    Map.take(audit, [
      :action,
      :disposition,
      :reason,
      :blocker_count,
      :comparison_count,
      :cohort_digest,
      :catalog_digest,
      :config_digest,
      :state_digest
    ])
  end

  defp with_telemetry(operation, opts, fun) do
    metadata =
      %{
        action: operation,
        mode: safe_mode(),
        account_id: hashed(opts[:account_id]),
        actor_id: hashed(opts[:actor_id])
      }
      |> Map.take(@metadata_keys)

    Accrue.Telemetry.span_private(
      [:accrue, :entitlements, :compatibility, operation],
      metadata,
      fn ->
        if Keyword.get(opts, :raise, false), do: raise("compatibility telemetry probe")
        fun.()
      end
    )
  end

  defp safe_mode do
    Accrue.Config.multi_rail().mode
  rescue
    _ -> :invalid
  end

  defp hashed(nil), do: nil
  defp hashed(value), do: :crypto.hash(:sha256, to_string(value)) |> Base.encode16(case: :lower)
end
