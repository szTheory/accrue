defmodule Accrue.Portal.Checkout.CompletionJob do
  @moduledoc """
  Asynchronously records and reduces the synthetic local-portal checkout
  completion event after a successful Braintree subscribe handoff.
  """

  use Oban.Worker, queue: :accrue_webhooks, max_attempts: 3

  alias Accrue.Billing.Subscription
  alias Accrue.Checkout.LocalSession
  alias Accrue.Repo
  alias Accrue.Webhook.DefaultHandler
  alias Accrue.Webhook.Event, as: WebhookEventStruct
  alias Accrue.Webhook.WebhookEvent

  @spec enqueue(Ecto.UUID.t(), Ecto.UUID.t()) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def enqueue(checkout_session_id, subscription_id)
      when is_binary(checkout_session_id) and is_binary(subscription_id) do
    %{checkout_session_id: checkout_session_id, subscription_id: subscription_id}
    |> new()
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt, max_attempts: max_attempts}) do
    checkout_session_id =
      Map.get(args, "checkout_session_id") || Map.get(args, :checkout_session_id)

    subscription_id = Map.get(args, "subscription_id") || Map.get(args, :subscription_id)

    with %LocalSession{} = checkout <- Repo.get(LocalSession, checkout_session_id),
         %Subscription{} = subscription <- Repo.get(Subscription, subscription_id),
         {:ok, row} <- fetch_or_insert_webhook_row(checkout, subscription),
         :ok <- maybe_reduce(row, checkout, subscription),
         {:ok, _updated} <- update_status(row, :succeeded) do
      :ok
    else
      nil ->
        {:error, :not_found}

      {:error, _reason} = error ->
        mark_failed_or_dead(checkout_session_id, subscription_id, attempt, max_attempts)
        error

      other ->
        mark_failed_or_dead(checkout_session_id, subscription_id, attempt, max_attempts)
        {:error, other}
    end
  end

  defp maybe_reduce(%WebhookEvent{status: :succeeded}, _checkout, _subscription), do: :ok

  defp maybe_reduce(%WebhookEvent{} = row, checkout, subscription) do
    with {:ok, row} <- update_status(row, :processing) do
      Accrue.Actor.put_current(%{type: :webhook, id: row.processor_event_id})

      event = %WebhookEventStruct{
        type: row.type,
        object_id: checkout.id,
        livemode: false,
        created_at: row.received_at,
        processor_event_id: row.processor_event_id,
        processor: :braintree
      }

      ctx = %{
        webhook_event_id: row.id,
        endpoint: :default,
        portal_checkout_object: portal_checkout_object(checkout, subscription)
      }

      case DefaultHandler.handle_event(event.type, event, ctx) do
        :ok -> :ok
        {:error, _} = error -> error
        other -> {:error, other}
      end
    end
  end

  defp fetch_or_insert_webhook_row(checkout, subscription) do
    processor_event_id = processor_event_id(checkout.id, subscription.id)

    case Repo.get_by(WebhookEvent, processor: "braintree", processor_event_id: processor_event_id) do
      %WebhookEvent{} = row ->
        {:ok, row}

      nil ->
        attrs = %{
          processor: "braintree",
          processor_event_id: processor_event_id,
          type: "accrue.portal.checkout.completed",
          livemode: false,
          endpoint: :default,
          raw_body: "{}",
          received_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
          data: %{
            "id" => processor_event_id,
            "type" => "accrue.portal.checkout.completed",
            "source" => "accrue.portal",
            "data" => %{"object" => portal_checkout_object(checkout, subscription)}
          }
        }

        WebhookEvent.ingest_changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, row} ->
            {:ok, row}

          {:error, changeset} ->
            case Repo.get_by(WebhookEvent,
                   processor: "braintree",
                   processor_event_id: processor_event_id
                 ) do
              %WebhookEvent{} = row -> {:ok, row}
              nil -> {:error, changeset}
            end
        end
    end
  end

  defp portal_checkout_object(checkout, subscription) do
    customer = Repo.preload(subscription, :customer).customer

    %{
      "id" => checkout.id,
      "customer" => customer.processor_id,
      "customer_id" => customer.id,
      "subscription" => subscription.processor_id,
      "subscription_id" => subscription.id,
      "checkout_session_id" => checkout.id
    }
  end

  defp update_status(%WebhookEvent{} = row, status) do
    row
    |> WebhookEvent.status_changeset(status)
    |> Repo.update()
  end

  defp mark_failed_or_dead(checkout_session_id, subscription_id, attempt, max_attempts) do
    status = if attempt >= max_attempts, do: :dead, else: :failed
    processor_event_id = processor_event_id(checkout_session_id, subscription_id)

    case Repo.get_by(WebhookEvent, processor: "braintree", processor_event_id: processor_event_id) do
      %WebhookEvent{} = row ->
        _ = update_status(row, status)
        :ok

      nil ->
        :ok
    end
  end

  defp processor_event_id(checkout_session_id, subscription_id) do
    "portal_checkout_completed:" <> checkout_session_id <> ":" <> subscription_id
  end
end
