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
        eyebrow: "For a small team",
        summary: "Track issues and plan work for one team, with billing and receipts.",
        features: [
          "One active team workspace",
          "Issue tracking and project boards",
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
        eyebrow: "For a growing team",
        summary: "Multiple projects with team seats, automations, and plan changes.",
        featured: true,
        features: [
          "Multiple active projects",
          "Team seats and roles",
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
        eyebrow: "For larger orgs",
        summary: "Usage-based capacity for automations and API, plus advanced controls.",
        features: [
          "Usage-based automation runs",
          "Advanced permissions and audit",
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
