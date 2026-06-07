defmodule AccrueHost.DemoBrand do
  @moduledoc """
  Host-owned visible identity for the checked-in example SaaS.

  Accrue remains the billing library and operator/admin product. CohortFlow is
  the fictional customer-facing SaaS that demonstrates how a real Phoenix app
  would use Accrue.
  """

  @product_name "CohortFlow"
  @demo_password "accrue-demo-password"

  @personas [
    %{
      email: "healthy@example.com",
      label: "Program Owner",
      workspace: "Northstar Academy",
      state: "Active workspace",
      route: "/app/billing",
      description: "A paid cohort program with a healthy subscription and no recovery notices."
    },
    %{
      email: "past-due@example.com",
      label: "Finance Lead",
      workspace: "Summit Workshop",
      state: "Payment recovery",
      route: "/billing",
      description:
        "A customer account with a past-due subscription and active recovery messaging."
    },
    %{
      email: "enterprise@example.com",
      label: "Scale Customer",
      workspace: "Atlas Learning Group",
      state: "Scale plan",
      route: "/app/billing",
      description: "A larger program account with richer billing history and invoice examples."
    },
    %{
      email: "admin@example.com",
      label: "Billing Operator",
      workspace: "Accrue Admin",
      state: "Operator console",
      route: "/admin",
      description:
        "An admin-only operator account for reviewing customers, invoices, and webhooks."
    }
  ]

  @doc "Customer-facing product name for the example host."
  @spec product_name() :: String.t()
  def product_name, do: @product_name

  @doc "Short customer-facing positioning line."
  @spec tagline() :: String.t()
  def tagline do
    "Run live cohorts, paid memberships, and alumni communities from one workspace."
  end

  @doc "Compact product promise used in headings and nav."
  @spec short_tagline() :: String.t()
  def short_tagline, do: "Cohort operations and subscriptions in one place."

  @doc "Seeded password shared by local demo personas."
  @spec demo_password() :: String.t()
  def demo_password, do: @demo_password

  @doc "Customer-facing support email for the example SaaS."
  @spec support_email() :: String.t()
  def support_email, do: "support@cohortflow.test"

  @doc "Customer-facing billing sender email for the example SaaS."
  @spec billing_email() :: String.t()
  def billing_email, do: "billing@cohortflow.test"

  @doc "Seeded evaluator personas shown in the local demo UI."
  @spec personas() :: [map()]
  def personas, do: @personas
end
