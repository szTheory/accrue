defmodule CadenceSubscriptionFacts do
  @moduledoc false

  @now ~U[2026-10-25 12:00:00Z]
  @organization_id "b7c77d8c-c167-4eac-b977-4f835a5947bd"
  @customer_id "3a632d30-37d1-4c08-a5bf-2b14f2862520"
  @subscription_id "ea26f232-b276-42bb-b862-d5c1b7d9d457"
  @item_id "d10a5f31-fc93-4ad0-bb2c-c0e23e6c79cb"

  @doc "Returns deterministic, database-free facts for one retained subscription situation."
  def fetch!(:active), do: base_facts("stripe", :active)
  def fetch!(:populated), do: base_facts("stripe", :active)
  def fetch!(:braintree_pruned), do: base_facts("braintree", :active)

  def fetch!(:dunning_active) do
    facts = base_facts("stripe", :past_due)

    put_in(
      facts,
      [:subscription, :dunning_campaign_started_at],
      DateTime.add(@now, -86_400, :second)
    )
  end

  def fetch!(scenario) do
    raise ArgumentError, "unsupported Cadence subscription scenario: #{inspect(scenario)}"
  end

  defp base_facts(provider, status) do
    period_start = DateTime.add(@now, -86_400, :second)
    period_end = DateTime.add(@now, 30 * 86_400, :second)

    %{
      scenario: status,
      actor: %{type: :admin, id: "admin_cadence_story"},
      owner: %{
        type: "Organization",
        id: @organization_id,
        slug: "cadence-demo",
        name: "Cadence Demo"
      },
      lane: :ordinary,
      provider: provider,
      now: @now,
      customer: %{
        id: @customer_id,
        owner_type: "Organization",
        owner_id: @organization_id,
        processor: provider,
        processor_id: "cus_cadence_demo",
        name: "Acme Research",
        email: "billing@example.test"
      },
      subscription: %{
        id: @subscription_id,
        customer_id: @customer_id,
        processor: provider,
        processor_id: "sub_cadence_active",
        status: status,
        cancel_at_period_end: false,
        current_period_start: period_start,
        current_period_end: period_end,
        dunning_campaign_started_at: nil,
        items: [
          %{
            id: @item_id,
            subscription_id: @subscription_id,
            processor: provider,
            processor_id: "si_cadence_active",
            price_id: if(provider == "braintree", do: "bt_team_annual", else: "pro_monthly_2026"),
            quantity: 12
          }
        ]
      }
    }
  end
end
