defmodule Accrue.Billing.QueryTest do
  @moduledoc """
  D3-04 composable query fragments. Every predicate in
  `Accrue.Billing.Subscription` has a mirror fragment in
  `Accrue.Billing.Query` that composes via `|>` in a `where` clause.
  """
  use Accrue.BillingCase, async: false

  alias Accrue.Billing.{Customer, Query, Subscription}

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake"
      })
      |> Repo.insert()

    now = Accrue.Clock.utc_now()
    future = DateTime.add(now, 7, :day)

    statuses_with_attrs = [
      {:trialing, %{}},
      {:active, %{}},
      {:active, %{cancel_at_period_end: true, current_period_end: future}},
      {:past_due, %{}},
      {:unpaid, %{}},
      {:canceled, %{}},
      {:incomplete, %{}},
      {:incomplete_expired, %{}},
      {:paused, %{}}
    ]

    for {status, attrs} <- statuses_with_attrs do
      suffix = Ecto.UUID.generate() |> binary_part(0, 8)

      {:ok, _sub} =
        %Subscription{}
        |> Subscription.changeset(
          Map.merge(
            %{
              customer_id: customer.id,
              processor: "fake",
              processor_id: "sub_#{status}_#{suffix}",
              status: status
            },
            attrs
          )
        )
        |> Repo.insert()
    end

    %{customer: customer}
  end

  test "active/1 returns trialing + active rows" do
    statuses = Query.active() |> Repo.all() |> Enum.map(& &1.status)
    assert :trialing in statuses
    assert :active in statuses
    refute :past_due in statuses
    refute :canceled in statuses
  end

  test "canceling/1 requires cancel_at_period_end + future period end" do
    rows = Query.canceling() |> Repo.all()
    assert length(rows) == 1
    assert hd(rows).cancel_at_period_end == true
  end

  test "canceled/1 returns :canceled and :incomplete_expired" do
    statuses = Query.canceled() |> Repo.all() |> Enum.map(& &1.status) |> Enum.sort()
    assert :canceled in statuses
    assert :incomplete_expired in statuses
  end

  test "past_due/1 returns :past_due and :unpaid" do
    statuses = Query.past_due() |> Repo.all() |> Enum.map(& &1.status) |> Enum.sort()
    assert statuses == [:past_due, :unpaid]
  end

  test "trialing/1 narrow" do
    statuses = Query.trialing() |> Repo.all() |> Enum.map(& &1.status)
    assert statuses == [:trialing]
  end

  test "composes with an existing from/where query" do
    %Customer{id: customer_id} = Repo.one!(from(c in Customer, limit: 1))

    result =
      from(s in Subscription, where: s.customer_id == ^customer_id)
      |> Query.active()
      |> Repo.all()

    assert Enum.all?(result, &(&1.status in [:active, :trialing]))
  end
end
