defmodule Accrue.Test.Factory do
  @moduledoc """
  Phase 3 test factories (D3-79..85).

  First-class subscription-state factories that route through the
  `Accrue.Processor.Fake` adapter and derive timestamps from
  `Accrue.Clock.utc_now/0`. Nine states are covered:

    * `customer/1`
    * `subscription/1` — primitive, takes a `:status` override
    * `trialing_subscription/1`
    * `active_subscription/1`
    * `past_due_subscription/1`
    * `incomplete_subscription/1`
    * `canceled_subscription/1`
    * `canceling_subscription/1` (active + cancel_at_period_end)
    * `grace_period_subscription/1` (canceled but within period)
    * `trial_ending_subscription/1` (trial_end within 72h)

  Factories live in `lib/` (not `test/`) so the Phase 8 `mix accrue.seed`
  task can use them in `:dev`. They have no side effects beyond calling
  the configured processor, which in test/dev is the in-memory Fake.

  ## Usage

      %{subscription: sub} = Accrue.Test.Factory.active_subscription()

  Every factory returns a map with `:customer`, `:subscription`, and
  `:items` keys (except `customer/1` which returns `%{customer:, owner_id:}`).

  ## Test-clock safety

  All timestamps derive from `Accrue.Clock.utc_now/0`, which in the test
  env routes through `Accrue.Processor.Fake.now/0`. Advancing the fake
  clock therefore advances all factory-produced timestamps in the same
  direction — no hidden wall-clock calls that would skew relative to
  the test clock.
  """

  alias Accrue.Billing
  alias Accrue.Billing.{Customer, Subscription, SubscriptionProjection}
  alias Accrue.Clock
  alias Accrue.Processor.Fake
  alias Accrue.Repo

  @default_price "price_basic"

  @doc """
  Creates a `Customer` row backed by a freshly-minted Fake customer.

  Returns `%{customer: %Customer{}, owner_id: String.t()}`. Accepts an
  optional `attrs` map with `:owner_id`, `:owner_type`, and `:email`
  overrides.
  """
  @spec customer(map()) :: %{customer: Customer.t(), owner_id: String.t()}
  def customer(attrs \\ %{}) do
    owner_id = Map.get(attrs, :owner_id, Ecto.UUID.generate())
    owner_type = Map.get(attrs, :owner_type, "User")
    email = Map.get(attrs, :email, "factory-#{owner_id}@example.com")

    {:ok, stripe_customer} =
      Fake.create_customer(%{email: email, name: Map.get(attrs, :name)})

    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: owner_type,
        owner_id: owner_id,
        processor: "fake",
        processor_id: Map.get(stripe_customer, :id),
        email: email,
        metadata: Map.get(attrs, :metadata, %{}),
        data: %{}
      })
      |> Repo.insert()

    %{customer: customer, owner_id: owner_id}
  end

  @doc """
  Primitive subscription factory. Use the status-named variants below
  in tests; this is the underlying dispatch point.

  Accepts `:status`, `:price_id`, `:owner_id`, and `:trial_end` (a
  Duration tuple understood by `Accrue.Billing.subscribe/3`).
  """
  @spec subscription(map()) :: %{
          customer: Customer.t(),
          subscription: Subscription.t(),
          items: [struct()]
        }
  def subscription(attrs \\ %{}) do
    status = Map.get(attrs, :status, :trialing)
    price = Map.get(attrs, :price_id, @default_price)
    trial_end = Map.get(attrs, :trial_end, {:days, 14})

    %{customer: c} = customer(attrs)

    {:ok, sub} = Billing.subscribe(c, price, trial_end: trial_end)

    sub =
      case status do
        :trialing ->
          sub

        other ->
          {:ok, _} = Fake.transition(sub.processor_id, other, synthesize_webhooks: false)
          reproject(sub)
      end

    %{customer: c, subscription: sub, items: sub.subscription_items || []}
  end

  @doc "Trialing subscription (14-day trial)."
  def trialing_subscription(attrs \\ %{}),
    do: subscription(Map.put(attrs, :status, :trialing))

  @doc "Active subscription (post-trial)."
  def active_subscription(attrs \\ %{}),
    do: subscription(Map.put(attrs, :status, :active))

  @doc "Past-due subscription (failed renewal)."
  def past_due_subscription(attrs \\ %{}),
    do: subscription(Map.put(attrs, :status, :past_due))

  @doc "Incomplete subscription (initial payment not confirmed)."
  def incomplete_subscription(attrs \\ %{}),
    do: subscription(Map.put(attrs, :status, :incomplete))

  @doc """
  Fully-canceled subscription. Builds an active sub and then calls
  `Accrue.Billing.cancel/2`, so the state transitions through the real
  cancel path (not just a raw status flip).
  """
  @spec canceled_subscription(map()) :: %{
          customer: Customer.t(),
          subscription: Subscription.t(),
          items: [struct()]
        }
  def canceled_subscription(attrs \\ %{}) do
    %{customer: c, subscription: sub} = active_subscription(attrs)
    {:ok, canceled} = Billing.cancel(sub)
    canceled = Repo.preload(canceled, :subscription_items)
    %{customer: c, subscription: canceled, items: canceled.subscription_items || []}
  end

  @doc """
  "Canceling" subscription — active with `cancel_at_period_end: true`
  and a future `current_period_end`. Passes `Subscription.canceling?/1`.
  """
  @spec canceling_subscription(map()) :: %{
          customer: Customer.t(),
          subscription: Subscription.t(),
          items: [struct()]
        }
  def canceling_subscription(attrs \\ %{}) do
    %{customer: c, subscription: sub} = active_subscription(attrs)
    {:ok, canceling} = Billing.cancel_at_period_end(sub)

    # Ensure current_period_end is in the future so canceling?/1 holds.
    future = DateTime.add(Clock.utc_now(), 14 * 86_400, :second)

    {:ok, canceling} =
      canceling
      |> Subscription.changeset(%{current_period_end: future})
      |> Repo.update()

    canceling = Repo.preload(canceling, :subscription_items)
    %{customer: c, subscription: canceling, items: canceling.subscription_items || []}
  end

  @doc """
  "Grace period" subscription — canceled, but `current_period_end`
  still in the future so the host app can keep granting access.
  """
  @spec grace_period_subscription(map()) :: %{
          customer: Customer.t(),
          subscription: Subscription.t(),
          items: [struct()]
        }
  def grace_period_subscription(attrs \\ %{}) do
    %{customer: c, subscription: sub} = canceled_subscription(attrs)
    future = DateTime.add(Clock.utc_now(), 7 * 86_400, :second)

    {:ok, grace} =
      sub
      |> Subscription.changeset(%{current_period_end: future})
      |> Repo.update()

    grace = Repo.preload(grace, :subscription_items)
    %{customer: c, subscription: grace, items: grace.subscription_items || []}
  end

  @doc """
  Trialing subscription with `trial_end` within 72 hours, for testing
  the `trial.ending_soon` notifier path.
  """
  @spec trial_ending_subscription(map()) :: %{
          customer: Customer.t(),
          subscription: Subscription.t(),
          items: [struct()]
        }
  def trial_ending_subscription(attrs \\ %{}) do
    %{customer: c, subscription: sub} = trialing_subscription(attrs)
    ending_dt = DateTime.add(Clock.utc_now(), 2 * 86_400, :second)

    {:ok, ending} =
      sub
      |> Subscription.changeset(%{trial_end: ending_dt})
      |> Repo.update()

    ending = Repo.preload(ending, :subscription_items)
    %{customer: c, subscription: ending, items: ending.subscription_items || []}
  end

  # ---------------------------------------------------------------------------
  # Internals
  # ---------------------------------------------------------------------------

  defp reproject(sub) do
    {:ok, stripe_sub} = Fake.retrieve_subscription(sub.processor_id, [])
    {:ok, attrs} = SubscriptionProjection.decompose(stripe_sub)

    {:ok, updated} =
      sub
      |> Subscription.changeset(attrs)
      |> Repo.update()

    Repo.preload(updated, :subscription_items)
  end
end
