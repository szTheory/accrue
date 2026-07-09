defmodule AccrueAdmin.AttentionCounts do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Invoice, Query, Subscription}
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.OwnerScope

  @open_invoice_statuses [:draft, :open]

  @spec compute(OwnerScope.t() | any()) :: %{
          invoices: non_neg_integer(),
          recovery: non_neg_integer(),
          developer: non_neg_integer()
        }
  def compute(%OwnerScope{mode: :organization, organization_id: org_id}) do
    %{
      invoices:
        Invoice
        |> join(:inner, [invoice], customer in Customer, on: customer.id == invoice.customer_id)
        |> where(
          [invoice, customer],
          customer.owner_type == "Organization" and customer.owner_id == ^org_id and
            invoice.status in ^@open_invoice_statuses
        )
        |> Repo.aggregate(:count, :id),
      recovery:
        Subscription
        |> join(:inner, [sub], customer in Customer, on: customer.id == sub.customer_id)
        |> where(
          [_sub, customer],
          customer.owner_type == "Organization" and customer.owner_id == ^org_id
        )
        |> Query.past_due()
        |> Repo.aggregate(:count, :id),
      developer:
        WebhookEvent
        |> where([e], e.status in [:failed, :dead])
        |> Repo.aggregate(:count, :id)
    }
  end

  def compute(_owner_scope) do
    %{
      invoices:
        Invoice
        |> where([invoice], invoice.status in ^@open_invoice_statuses)
        |> Repo.aggregate(:count, :id),
      recovery: Subscription |> Query.past_due() |> Repo.aggregate(:count, :id),
      developer:
        WebhookEvent
        |> where([e], e.status in [:failed, :dead])
        |> Repo.aggregate(:count, :id)
    }
  end
end
