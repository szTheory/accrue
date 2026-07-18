defmodule AccrueHost.FakeHydration do
  @moduledoc """
  Rehydrates the in-memory `Accrue.Processor.Fake` from durable DB rows on boot.

  The demo seeds run in a *separate BEAM node* from the server (`mix run
  priv/repo/seeds.exs` then `mix phx.server`), so the Fake's in-memory
  customers/subscriptions — and its sequential id counters — are lost while the
  seeded Postgres rows (and their `processor_id`s) survive. Without this, the
  running server boots a fresh Fake whose counter restarts at 0, so:

    * the first `subscribe` re-mints a `sub_fake_00001` that already exists in
      the DB → `Ecto.ConstraintError`, and
    * `swap_plan`/`cancel` on a seeded subscription hit `resource_missing`
      because the Fake never knew that `processor_id`.

  `run/0` mirrors the seeded `processor == "fake"` customers and subscriptions
  back into the running Fake and raises its counters past the seeded ids. It
  runs on every boot, is idempotent, and no-ops unless the Fake is the
  configured processor. Failures are logged and swallowed so they can never
  block application start.
  """

  import Ecto.Query
  require Logger

  alias Accrue.Billing.Customer
  alias Accrue.Billing.Subscription
  alias Accrue.Processor
  alias AccrueHost.Repo

  # Matches the Fake's own deterministic ids, e.g. "cus_fake_00007" / "sub_fake_00012".
  @fake_counter_id ~r/^[a-z_]+_fake_(\d{5})$/

  @spec run() :: :ok
  def run do
    if Processor.__impl__() == Processor.Fake do
      hydrate()
    else
      :ok
    end
  rescue
    error ->
      Logger.warning("FakeHydration skipped: #{Exception.message(error)}")
      :ok
  end

  defp hydrate do
    customers = Repo.all(from(c in Customer, where: c.processor == "fake"))

    subscriptions =
      Repo.all(
        from(s in Subscription,
          where: s.processor == "fake",
          preload: [:customer, :subscription_items]
        )
      )

    :ok =
      Processor.Fake.load_fixtures(%{
        customers: Enum.map(customers, &customer_descriptor/1),
        subscriptions: Enum.map(subscriptions, &subscription_descriptor/1),
        counters: %{
          customer: max_counter(customers),
          subscription: max_counter(subscriptions)
        }
      })

    Logger.info(
      "FakeHydration loaded #{length(customers)} customers and " <>
        "#{length(subscriptions)} subscriptions into the Fake processor"
    )

    :ok
  end

  defp customer_descriptor(%Customer{} = customer) do
    %{
      id: customer.processor_id,
      name: customer.name,
      email: customer.email,
      metadata: customer.metadata || %{}
    }
  end

  defp subscription_descriptor(%Subscription{} = subscription) do
    item = List.first(subscription.subscription_items)

    %{
      id: subscription.processor_id,
      customer_id: subscription.customer && subscription.customer.processor_id,
      item_id: item && item.processor_id,
      price_id: item && item.price_id,
      product_id: item && item.processor_product_id,
      quantity: (item && item.quantity) || 1,
      status: subscription.status,
      metadata: subscription.metadata || %{},
      current_period_start: subscription.current_period_start,
      current_period_end: subscription.current_period_end
    }
  end

  defp max_counter(rows) do
    rows
    |> Enum.map(&counter_suffix(&1.processor_id))
    |> then(&Enum.max([0 | &1]))
  end

  defp counter_suffix(processor_id) when is_binary(processor_id) do
    case Regex.run(@fake_counter_id, processor_id) do
      [_, digits] -> String.to_integer(digits)
      _ -> 0
    end
  end

  defp counter_suffix(_processor_id), do: 0
end
