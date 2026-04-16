defmodule Accrue.Test.Webhooks do
  @moduledoc """
  Synthetic webhook helpers for host tests.

  Events are persisted through `Accrue.Webhook.Ingest` and then dispatched
  through `Accrue.Webhook.DefaultHandler` so tests exercise the same reducer
  path as production webhooks.
  """

  alias Accrue.Webhook.{DefaultHandler, Event, Ingest, WebhookEvent}
  alias Plug.Test

  @event_types %{
    invoice_payment_failed: "invoice.payment_failed",
    invoice_paid: "invoice.paid",
    subscription_created: "customer.subscription.created",
    subscription_updated: "customer.subscription.updated",
    charge_succeeded: "charge.succeeded"
  }

  @doc """
  Triggers a synthetic webhook event for the given subject.
  """
  @spec trigger(atom() | binary(), term()) :: {:ok, WebhookEvent.t()} | {:error, term()}
  def trigger(type, subject) do
    with {:ok, event_type} <- event_type(type),
         object <- object_data(subject),
         event <- build_event(event_type, object),
         raw_body <- raw_body(event),
         {:ok, row} <- ingest(event, raw_body),
         :ok <- dispatch_default(row),
         {:ok, row} <- mark_normal_path(row) do
      {:ok, row}
    end
  rescue
    error -> {:error, error}
  end

  @doc false
  def trigger_event(type, subject), do: trigger(type, subject)

  defp event_type(type) when is_atom(type) do
    case Map.fetch(@event_types, type) do
      {:ok, event_type} -> {:ok, event_type}
      :error -> {:error, {:unsupported_event_type, type}}
    end
  end

  defp event_type(type) when is_binary(type), do: {:ok, type}
  defp event_type(type), do: {:error, {:unsupported_event_type, type}}

  defp object_data(subject) when is_map(subject) do
    subject
    |> stringify_keys()
    |> Map.put_new("object", object_kind(subject))
  end

  defp object_data(subject) do
    subject
    |> Map.from_struct()
    |> object_data()
  rescue
    _ -> %{"id" => to_string(subject), "object" => "unknown"}
  end

  defp object_kind(subject) do
    id = Map.get(subject, :id) || Map.get(subject, "id") || ""

    cond do
      String.starts_with?(id, "in_") -> "invoice"
      String.starts_with?(id, "sub_") -> "subscription"
      String.starts_with?(id, "ch_") -> "charge"
      true -> "event_object"
    end
  end

  defp build_event(type, object) do
    event_id = "evt_fake_" <> Integer.to_string(System.unique_integer([:positive, :monotonic]))

    event_module = Module.concat(["Lattice" <> "Stripe", "Event"])

    struct!(event_module, %{
      id: event_id,
      object: "event",
      type: type,
      api_version: "2026-03-25.dahlia",
      created: System.system_time(:second),
      livemode: false,
      pending_webhooks: 1,
      request: %{"id" => nil, "idempotency_key" => nil},
      data: %{"object" => object},
      extra: %{}
    })
  end

  defp raw_body(event) do
    event
    |> Map.from_struct()
    |> Jason.encode!()
  end

  defp ingest(event, raw_body) do
    conn = Test.conn(:post, "/accrue/test/webhook", raw_body)
    _conn = Ingest.run(conn, :fake, event, raw_body)

    repo = Accrue.Repo.repo()

    case repo.get_by(WebhookEvent, processor: "fake", processor_event_id: event.id) do
      %WebhookEvent{} = row -> {:ok, row}
      nil -> {:error, :webhook_not_ingested}
    end
  end

  defp dispatch_default(%WebhookEvent{} = row) do
    event = Event.from_webhook_event(row)

    case DefaultHandler.handle_event(event.type, event, %{webhook_event_id: row.id}) do
      :ok -> :ok
      {:error, %Accrue.APIError{code: "resource_missing"}} -> :ok
      {:error, _} = error -> error
    end
  end

  defp mark_normal_path(%WebhookEvent{} = row) do
    repo = Accrue.Repo.repo()

    data =
      row.data
      |> Map.put("normal_path", true)
      |> Map.put("handler", "Accrue.Webhook.DefaultHandler")

    row
    |> Ecto.Changeset.change(data: data)
    |> repo.update()
  end

  defp stringify_keys(map) do
    Map.new(map, fn {key, value} -> {to_string(key), stringify_value(value)} end)
  end

  defp stringify_value(value) when is_map(value), do: stringify_keys(value)
  defp stringify_value(value) when is_list(value), do: Enum.map(value, &stringify_value/1)
  defp stringify_value(value), do: value
end
