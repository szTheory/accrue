defmodule CadenceSubscriptionFacts do
  @moduledoc false

  @now ~U[2026-10-25 12:00:00Z]
  @organization_id "b7c77d8c-c167-4eac-b977-4f835a5947bd"
  @customer_id "3a632d30-37d1-4c08-a5bf-2b14f2862520"
  @subscription_id "ea26f232-b276-42bb-b862-d5c1b7d9d457"
  @item_id "d10a5f31-fc93-4ad0-bb2c-c0e23e6c79cb"

  @launch_ids %{
    owner: "98199a4c-9198-4b4c-94aa-a95d6f0e7c42",
    customer: "ac653cb3-8487-459f-bb2a-e0707e869e47",
    subscription: "c134aee0-b71a-44f5-a030-f6146577dba5",
    item: "55e45432-b3f4-48cb-a6c3-d6e4e2dc047f",
    slug: "cadence-launch",
    owner_name: "Northstar Research",
    actor_id: "admin_cadence_launch",
    processor_suffix: "launch"
  }
  @team_ids %{
    owner: "e24b181a-768c-4b05-9cb5-eaf41c0a57dd",
    customer: "d5b66fa8-9d31-4d60-ae80-5c024f6b587b",
    subscription: "84824c8b-2821-4df8-b32a-b92958c8c80c",
    item: "51a294fa-5be9-46b2-80de-3f8c497935d7",
    slug: "cadence-team",
    owner_name: "Juniper Labs",
    actor_id: "admin_cadence_growing_team",
    processor_suffix: "growing_team"
  }

  @ordinary_scenarios [
    :active,
    :launch,
    :growing_team,
    :scheduled_cancellation,
    :incomplete_evidence,
    :populated,
    :braintree_pruned,
    :dunning_active
  ]

  @doc "Lists the stable ordinary scenario identifiers without deriving atoms from input."
  def list, do: @ordinary_scenarios

  @doc "Returns deterministic, database-free facts for one retained subscription situation."
  def fetch!(:active),
    do: base_facts(:active, "stripe", :active, default_ids(), "Acme Research", 12)

  def fetch!(:populated), do: fetch!(:active)

  def fetch!(:braintree_pruned),
    do: base_facts(:braintree_pruned, "braintree", :active, default_ids(), "Acme Research", 12)

  def fetch!(:launch),
    do: base_facts(:launch, "stripe", :active, @launch_ids, "Northstar Research", 1)

  def fetch!(:growing_team),
    do: base_facts(:growing_team, "stripe", :active, @team_ids, "Juniper Labs", 12)

  def fetch!(:scheduled_cancellation) do
    :scheduled_cancellation
    |> base_facts("stripe", :active, default_ids(), "Acme Research", 12)
    |> put_in([:subscription, :cancel_at_period_end], true)
  end

  def fetch!(:incomplete_evidence) do
    :incomplete_evidence
    |> base_facts("stripe", :active, default_ids(), "Acme Research", 12)
    |> put_in([:subscription, :current_period_start], nil)
    |> put_in([:subscription, :current_period_end], nil)
    |> put_in([:subscription, :items, Access.at(0), :price_id], nil)
  end

  def fetch!(:dunning_active) do
    :dunning_active
    |> base_facts("stripe", :past_due, default_ids(), "Acme Research", 12)
    |> put_in(
      [:subscription, :dunning_campaign_started_at],
      DateTime.add(@now, -86_400, :second)
    )
  end

  def fetch!(scenario) do
    raise ArgumentError, "unsupported Cadence subscription scenario: #{inspect(scenario)}"
  end

  @doc "Returns separately labelled held-out text stress input, never an ordinary variation."
  def held_out!(:long_text) do
    :held_out_long_text
    |> base_facts("stripe", :active, @launch_ids, String.duplicate("Northstar Research ", 9), 1)
    |> Map.put(:lane, :held_out)
    |> Map.put(:held_out_case, :long_text)
    |> put_in([:customer, :name], String.duplicate("Northstar Research billing contact ", 7))
  end

  def held_out!(case_name) do
    raise ArgumentError, "unsupported held-out Cadence subscription case: #{inspect(case_name)}"
  end

  defp base_facts(scenario, provider, status, ids, customer_name, quantity) do
    period_start = DateTime.add(@now, -86_400, :second)
    period_end = DateTime.add(@now, 30 * 86_400, :second)
    owner_id = ids.owner
    customer_id = ids.customer
    subscription_id = ids.subscription
    item_id = ids.item
    processor_suffix = ids.processor_suffix

    %{
      scenario: scenario,
      actor: %{type: :admin, id: ids.actor_id},
      owner: %{
        type: "Organization",
        id: owner_id,
        slug: ids.slug,
        name: ids.owner_name
      },
      lane: :ordinary,
      provider: provider,
      capability: :swap_plan,
      now: @now,
      billing: %{amount_minor: 12_500, currency: :usd},
      customer: %{
        id: customer_id,
        owner_type: "Organization",
        owner_id: owner_id,
        processor: provider,
        processor_id: "cus_cadence_#{processor_suffix}",
        name: customer_name,
        email: "billing@example.test"
      },
      subscription: %{
        id: subscription_id,
        customer_id: customer_id,
        processor: provider,
        processor_id: "sub_cadence_#{processor_suffix}",
        status: status,
        cancel_at_period_end: false,
        current_period_start: period_start,
        current_period_end: period_end,
        dunning_campaign_started_at: nil,
        items: [
          %{
            id: item_id,
            subscription_id: subscription_id,
            processor: provider,
            processor_id: "si_cadence_#{processor_suffix}",
            price_id: if(provider == "braintree", do: "bt_team_annual", else: "pro_monthly_2026"),
            quantity: quantity
          }
        ]
      }
    }
  end

  defp default_ids do
    %{
      owner: @organization_id,
      customer: @customer_id,
      subscription: @subscription_id,
      item: @item_id,
      slug: "cadence-demo",
      owner_name: "Cadence Demo",
      actor_id: "admin_cadence_story",
      processor_suffix: "active"
    }
  end
end
