defmodule AccrueAdmin.Queries.Dunning do
  @moduledoc """
  Owner-scoped Dunning analytics queries for admin LiveViews.
  """

  import Ecto.Query, only: [from: 2, subquery: 1, where: 3]

  alias Accrue.Analytics.Dunning, as: CoreDunning
  alias Accrue.Billing.{Customer, Subscription}
  alias Accrue.Events.Event
  alias Accrue.Repo
  alias AccrueAdmin.OwnerScope
  alias Oban.Job

  @recovered_type "dunning.recovered"
  @exhausted_type "dunning.exhausted"
  @dunning_lifecycle_types ~w[dunning.campaign_started dunning.step_sent dunning.recovered dunning.exhausted]

  @customers_table Accrue.Migration.qualified_table(:accrue_customers)
  @subscriptions_table Accrue.Migration.qualified_table(:accrue_subscriptions)
  @events_table Accrue.Migration.qualified_table(:accrue_events)
  @invoices_table Accrue.Migration.qualified_table(:accrue_invoices)

  @subscription_scope_sql """
  EXISTS (
    SELECT 1
    FROM #{@subscriptions_table} subscriptions
    JOIN #{@customers_table} customers ON customers.id = subscriptions.customer_id
    WHERE subscriptions.id::text = ?
      AND customers.owner_type = 'Organization'
      AND customers.owner_id = ?
  )
  """

  @terminal_exists_sql "NOT EXISTS (SELECT 1 FROM #{@events_table} WHERE type IN ('dunning.recovered','dunning.exhausted') AND subject_id = ?::text AND inserted_at >= ?)"
  @step_count_sql "(SELECT COUNT(*) FROM #{@events_table} WHERE type = 'dunning.step_sent' AND subject_id = ?::text AND inserted_at >= ?)"
  @failure_reason_sql """
  (SELECT e.data FROM #{@events_table} e
     JOIN #{@invoices_table} i ON i.id::text = e.subject_id
     JOIN #{@events_table} cs ON cs.type = 'dunning.campaign_started'
                          AND cs.subject_id = ?::text
                          AND cs.data->>'invoice_id' = i.processor_id
   WHERE e.type = 'invoice.payment_failed'
     AND e.inserted_at >= ?
   ORDER BY e.inserted_at DESC
   LIMIT 1)
  """

  @spec recovered_vs_lost_mrr(OwnerScope.t() | nil, keyword()) :: %{
          recovered: [%{currency: String.t(), cents: non_neg_integer()}],
          lost: [%{currency: String.t(), cents: non_neg_integer()}]
        }
  def recovered_vs_lost_mrr(owner_scope, opts \\ [])

  def recovered_vs_lost_mrr(owner_scope, opts) when is_list(opts) do
    if global_scope?(owner_scope) do
      CoreDunning.recovered_vs_lost_mrr(opts)
    else
      Event
      |> where([event], event.type in [@recovered_type, @exhausted_type])
      |> scope_events(owner_scope)
      |> apply_window(opts)
      |> group_by_recovery_currency()
      |> Repo.all()
      |> Enum.reduce(%{recovered: [], lost: []}, fn {type, currency, cents}, acc ->
        entry = %{currency: currency || "usd", cents: cents || 0}

        case type do
          @recovered_type -> Map.update!(acc, :recovered, &[entry | &1])
          @exhausted_type -> Map.update!(acc, :lost, &[entry | &1])
          _type -> acc
        end
      end)
    end
  end

  @spec funnel(OwnerScope.t() | nil, keyword()) :: %{
          entered: non_neg_integer(),
          recovered: non_neg_integer(),
          exhausted: non_neg_integer(),
          active: non_neg_integer()
        }
  def funnel(owner_scope, opts \\ [])

  def funnel(owner_scope, opts) when is_list(opts) do
    if global_scope?(owner_scope) do
      CoreDunning.funnel(opts)
    else
      per_campaign =
        Event
        |> where([event], event.type in ^@dunning_lifecycle_types)
        |> scope_events(owner_scope)
        |> apply_window(opts)
        |> group_by_campaign()

      from(campaign in subquery(per_campaign),
        select: %{
          entered: count(),
          recovered: filter(count(), campaign.has_recovered),
          exhausted: filter(count(), campaign.has_exhausted and not campaign.has_recovered),
          active: filter(count(), not campaign.has_recovered and not campaign.has_exhausted)
        }
      )
      |> Repo.one()
      |> Kernel.||(%{entered: 0, recovered: 0, exhausted: 0, active: 0})
    end
  end

  @spec at_risk_subscriptions(OwnerScope.t() | nil, keyword()) :: [map()]
  def at_risk_subscriptions(owner_scope, opts \\ [])

  def at_risk_subscriptions(owner_scope, opts) when is_list(opts) do
    if global_scope?(owner_scope) do
      CoreDunning.at_risk_subscriptions(opts)
    else
      now = Accrue.Clock.utc_now()

      from(subscription in Subscription,
        join: customer in Customer,
        on: customer.id == subscription.customer_id,
        left_join: job in Job,
        on:
          job.worker == "Accrue.Workers.DunningStep" and
            fragment("? ->> 'subscription_id' = ?::text", job.args, subscription.id) and
            fragment(
              "? ->> 'campaign_started_at' = to_char(?, 'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"')",
              job.args,
              subscription.dunning_campaign_started_at
            ) and job.state in ["available", "scheduled", "retryable"],
        where: not is_nil(subscription.dunning_campaign_started_at),
        where:
          fragment(
            @terminal_exists_sql,
            subscription.id,
            subscription.dunning_campaign_started_at
          ),
        group_by: [
          subscription.id,
          subscription.customer_id,
          customer.email,
          customer.name,
          subscription.dunning_campaign_started_at
        ],
        order_by: [desc: subscription.dunning_campaign_started_at],
        select: %{
          subscription_id: subscription.id,
          customer_id: subscription.customer_id,
          customer_label: fragment("COALESCE(?, ?)", customer.email, customer.name),
          days_in_campaign:
            fragment(
              "EXTRACT(EPOCH FROM (? - ?))::integer / 86400",
              ^now,
              subscription.dunning_campaign_started_at
            ),
          current_step:
            fragment(@step_count_sql, subscription.id, subscription.dunning_campaign_started_at),
          next_step_eta: min(job.scheduled_at),
          failure_reason:
            fragment(
              @failure_reason_sql,
              subscription.id,
              subscription.dunning_campaign_started_at
            )
        }
      )
      |> scope_subscriptions(owner_scope)
      |> apply_campaign_window(opts)
      |> Repo.all()
    end
  end

  defp group_by_recovery_currency(query) do
    from(event in query,
      group_by: [event.type, fragment("?->>'currency'", event.data)],
      select:
        {event.type, fragment("?->>'currency'", event.data),
         sum(
           fragment(
             "CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END",
             event.data,
             event.data
           )
         )}
    )
  end

  defp group_by_campaign(query) do
    from(event in query,
      group_by: [
        event.subject_id,
        fragment("COALESCE(?->>'campaign_anchor', '__legacy__')", event.data)
      ],
      select: %{
        has_recovered: fragment("bool_or(? = 'dunning.recovered')", event.type),
        has_exhausted: fragment("bool_or(? = 'dunning.exhausted')", event.type)
      }
    )
  end

  defp scope_events(query, %OwnerScope{mode: :organization, organization_id: organization_id}) do
    where(
      query,
      [event],
      event.subject_type == "Subscription" and
        fragment(@subscription_scope_sql, event.subject_id, ^organization_id)
    )
  end

  defp scope_events(query, _owner_scope), do: query

  defp scope_subscriptions(
         query,
         %OwnerScope{mode: :organization, organization_id: organization_id}
       ) do
    where(
      query,
      [_subscription, customer, _job],
      customer.owner_type == "Organization" and customer.owner_id == ^organization_id
    )
  end

  defp scope_subscriptions(query, _owner_scope), do: query

  defp apply_window(query, opts) do
    query
    |> maybe_since(opts[:since])
    |> maybe_until(opts[:until])
  end

  defp maybe_since(query, %DateTime{} = since),
    do: where(query, [event], event.inserted_at >= ^since)

  defp maybe_since(query, _since), do: query

  defp maybe_until(query, %DateTime{} = until),
    do: where(query, [event], event.inserted_at <= ^until)

  defp maybe_until(query, _until), do: query

  defp apply_campaign_window(query, opts) do
    query
    |> maybe_since_campaign(opts[:since])
    |> maybe_until_campaign(opts[:until])
  end

  defp maybe_since_campaign(query, %DateTime{} = since),
    do: where(query, [subscription], subscription.dunning_campaign_started_at >= ^since)

  defp maybe_since_campaign(query, _since), do: query

  defp maybe_until_campaign(query, %DateTime{} = until),
    do: where(query, [subscription], subscription.dunning_campaign_started_at <= ^until)

  defp maybe_until_campaign(query, _until), do: query

  defp global_scope?(nil), do: true
  defp global_scope?(%OwnerScope{mode: :global}), do: true
  defp global_scope?(_owner_scope), do: false
end
