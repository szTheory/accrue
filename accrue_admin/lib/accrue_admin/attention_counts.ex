defmodule AccrueAdmin.AttentionCounts do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Customer, Query, Subscription}
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent
  alias AccrueAdmin.OwnerScope

  @spec compute(OwnerScope.t() | any()) :: %{
          recovery: non_neg_integer(),
          developer: non_neg_integer()
        }
  def compute(%OwnerScope{mode: :organization, organization_id: org_id}) do
    %{
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
      recovery: Subscription |> Query.past_due() |> Repo.aggregate(:count, :id),
      developer:
        WebhookEvent
        |> where([e], e.status in [:failed, :dead])
        |> Repo.aggregate(:count, :id)
    }
  end
end
