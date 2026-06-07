defmodule AccrueHost.Billing.Plans do
  @moduledoc """
  Deterministic Fake-backed plan definitions for the host billing UI.
  """

  @ids %{basic: "price_basic", pro: "price_pro", metered: "price_metered"}
  @labels %{basic: "Launch", pro: "Studio", metered: "Scale"}
  @amounts %{basic: 1_500, pro: 3_000, metered: 0}

  def ids, do: @ids

  def all do
    [
      %{
        key: :basic,
        id: @ids.basic,
        label: @labels.basic,
        eyebrow: "First paid cohort",
        summary: "Launch a paid cohort with subscriptions, invoices, and member access.",
        features: [
          "One active cohort workspace",
          "Subscription billing and receipts",
          "Self-serve invoice and payment history"
        ],
        unit_amount_minor: @amounts.basic,
        currency: "USD",
        billing_cycle: %{unit: :month, count: 1}
      },
      %{
        key: :pro,
        id: @ids.pro,
        label: @labels.pro,
        eyebrow: "Growing program team",
        summary: "Run multiple cohorts with team seats, alumni spaces, and plan changes.",
        featured: true,
        features: [
          "Multiple active cohorts",
          "Team seats for facilitators",
          "Plan changes and checkout recovery"
        ],
        unit_amount_minor: @amounts.pro,
        currency: "USD",
        billing_cycle: %{unit: :month, count: 1}
      },
      %{
        key: :metered,
        id: @ids.metered,
        label: @labels.metered,
        eyebrow: "Larger cohort operations",
        summary: "Add usage-based capacity for high-volume programs and enterprise workflows.",
        features: [
          "Usage-based learner activity",
          "Advanced recovery workflows",
          "Billing data ready for operators"
        ],
        unit_amount_minor: @amounts.metered,
        currency: "USD",
        billing_cycle: %{unit: :month, count: 1}
      }
    ]
  end

  def get(price_id) when is_binary(price_id) do
    Enum.find(all(), &(&1.id == price_id))
  end
end
