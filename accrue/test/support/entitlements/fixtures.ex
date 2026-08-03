defmodule Accrue.Test.EntitlementFixtures do
  @moduledoc """
  Deterministic, privacy-bounded fixtures for the additive entitlement rails.

  The fixtures model normalized records only. They intentionally contain no
  provider payloads, credentials, adopter identities, or physical-device data.
  """

  @timestamp ~U[2026-08-02 15:00:00.000000Z]
  @expiry ~U[2026-08-03 15:00:00.000000Z]
  @pairs for(
           rail <- [:stripe, :apple],
           environment <- [:production, :sandbox],
           do: {rail, environment}
         )

  @spec legacy_config() :: keyword()
  def legacy_config do
    [
      repo: Accrue.TestRepo,
      processor: Accrue.Processor.Fake,
      branding: [from_email: "billing@example.test", support_email: "support@example.test"],
      entitlements: [plans: [legacy: [price_ids: ["price_fake_legacy"]]]]
    ]
  end

  @spec multi_rail_config() :: keyword()
  def multi_rail_config do
    [
      repo: Accrue.TestRepo,
      processor: Accrue.Processor.Stripe,
      branding: [from_email: "billing@example.test", support_email: "support@example.test"],
      rails: [
        stripe: [
          source: :stripe,
          processor: Accrue.Processor.Stripe,
          environments: [:production, :sandbox],
          default_environment: :production
        ],
        apple: [
          source: :apple,
          environments: [:production, :sandbox],
          default_environment: :production
        ]
      ],
      default_rail: :stripe,
      entitlements: [
        plans: [
          pro: [
            products: [
              stripe: [production: ["price_fake_stripe_pro"], sandbox: ["price_fake_stripe_pro"]],
              apple: [production: ["product_fake_apple_pro"], sandbox: ["product_fake_apple_pro"]]
            ]
          ]
        ]
      ]
    ]
  end

  @spec account_attrs(String.t()) :: map()
  def account_attrs(owner_id) when is_binary(owner_id) do
    %{
      id: "21600000-0000-4000-8000-000000000001",
      owner_type: "test_owner",
      owner_id: owner_id,
      revision: 0
    }
  end

  @spec observation_attrs(String.t(), {atom(), atom()}) :: map()
  def observation_attrs(account_id, {rail, environment}) when {rail, environment} in @pairs do
    suffix = suffix(rail, environment)

    %{
      account_id: account_id,
      rail: rail,
      environment: environment,
      provider_event_id: "evt_fake_#{suffix}",
      provider_transaction_id: "txn_fake_#{suffix}",
      kind: "entitlement_observation",
      provider_lineage_id: "lineage_fake_#{suffix}",
      provider_product_id: "product_fake_#{suffix}",
      provider_order: provider_order(rail, environment),
      observed_at: @timestamp,
      state: :qualified,
      retry_count: 0,
      metadata: %{"source" => "fake_observer"},
      evidence_digest: digest(rail, environment),
      evidence_ref: "opaque://fixture/#{suffix}",
      evidence_expires_at: @expiry
    }
  end

  @spec grant_attrs(String.t(), {atom(), atom()}) :: map()
  def grant_attrs(account_id, {rail, environment}) when {rail, environment} in @pairs do
    suffix = suffix(rail, environment)

    %{
      account_id: account_id,
      rail: rail,
      environment: environment,
      provider_lineage_id: "lineage_fake_#{suffix}",
      provider_product_id: "product_fake_#{suffix}",
      logical_plan: "pro",
      source_item_id: "item_fake_#{suffix}",
      quantity: 1,
      provider_order: provider_order(rail, environment),
      account_revision: 0,
      effective_at: @timestamp
    }
  end

  @spec device_attrs(String.t(), {atom(), atom()}) :: map()
  def device_attrs(account_id, {rail, environment}) when {rail, environment} in @pairs do
    suffix = suffix(rail, environment)

    %{
      account_id: account_id,
      installation_id: "installation_fake_#{suffix}",
      key_thumbprint: "thumbprint_fake_#{suffix}",
      state: :active,
      registered_at: @timestamp,
      last_seen_at: @timestamp,
      last_accepted_revision: 0
    }
  end

  @spec scenario(atom()) :: [map()] | map()
  def scenario(:all), do: scenarios()
  def scenario(name) when is_atom(name), do: Enum.find(scenarios(), &(&1.name == name))

  @spec apple_host_outcomes() :: [map()]
  def apple_host_outcomes do
    [
      %{name: :management, disposition: :externally_managed, next_action: :manage_in_apple},
      %{name: :family_sharing, disposition: :deferred, next_action: :review_policy},
      %{name: :offer_authoring, disposition: :deferred, next_action: :review_policy},
      %{name: :reconciliation, disposition: :pending, next_action: :retry_reconciliation}
    ]
  end

  defp scenarios do
    [
      %{
        name: :account_switched_installation_reuse,
        rail: :apple,
        environment: :sandbox,
        outcome: :rejected
      },
      %{
        name: :current_grant_supersession,
        rail: :stripe,
        environment: :production,
        outcome: :replacement_current
      },
      %{
        name: :duplicate_observation_converges,
        rail: :apple,
        environment: :production,
        outcome: :idempotent
      },
      %{
        name: :qualified_tuple_collision_rejected,
        rail: :stripe,
        environment: :production,
        outcome: :collision
      },
      %{
        name: :revoked_device_reregistration_history,
        rail: :apple,
        environment: :sandbox,
        outcome: :history_retained
      }
    ]
  end

  defp suffix(rail, environment), do: "#{rail}_#{environment}"
  defp provider_order(:stripe, :production), do: 1
  defp provider_order(:stripe, :sandbox), do: 2
  defp provider_order(:apple, :production), do: 3
  defp provider_order(:apple, :sandbox), do: 4

  defp digest(rail, environment),
    do: :crypto.hash(:sha256, suffix(rail, environment)) |> Base.encode16(case: :lower)
end
