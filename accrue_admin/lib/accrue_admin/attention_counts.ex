defmodule AccrueAdmin.AttentionCounts do
  @moduledoc false

  import Ecto.Query

  alias Accrue.Billing.{Query, Subscription}
  alias Accrue.Repo
  alias Accrue.Webhook.WebhookEvent

  @spec compute(any()) :: %{recovery: non_neg_integer(), developer: non_neg_integer()}
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
