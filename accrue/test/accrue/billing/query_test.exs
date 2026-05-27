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

    past = DateTime.add(now, -1, :day)

    statuses_with_attrs = [
      {:trialing, %{}},
      {:active, %{}},
      {:active, %{cancel_at_period_end: true, current_period_end: future}},
      # The paused fail-open gap row: status :active but a non-nil
      # pause_collection. entitling?/1 must refute this, and Query.entitling/1
      # must exclude it (twin invariant).
      {:active, %{pause_collection: %{"behavior" => "void"}}},
      # Terminal-via-ended_at row: status :active but a past ended_at.
      {:active, %{ended_at: past}},
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

  test "entitling/1 excludes paused (status:active + pause_collection) and ended rows" do
    rows = Query.entitling() |> Repo.all()

    # No paused row (legacy :paused status OR a non-nil pause_collection on an
    # otherwise-active row) survives the entitling fragment.
    refute Enum.any?(rows, &(&1.status == :paused))
    refute Enum.any?(rows, &(not is_nil(&1.pause_collection)))
    # No ended row survives.
    refute Enum.any?(rows, &(not is_nil(&1.ended_at)))
    # Only active/trialing statuses remain.
    assert Enum.all?(rows, &(&1.status in [:active, :trialing]))
  end

  # Predicate <-> fragment twin invariant (the strongest drift guard): for EVERY
  # seeded row, Subscription.entitling?(row) must agree with the row's presence
  # in Query.entitling() |> Repo.all(). Drift between the in-memory predicate and
  # the SQL fragment silently grants/denies on one path only.
  test "entitling?/1 and Query.entitling/1 are twins (per-row agreement)" do
    all_rows = Repo.all(Subscription)
    entitling_ids = Query.entitling() |> Repo.all() |> Enum.map(& &1.id) |> MapSet.new()

    # Sanity: the seed includes the gap rows so the invariant is non-trivial.
    assert Enum.any?(all_rows, &(not is_nil(&1.pause_collection)))
    assert Enum.any?(all_rows, &(not is_nil(&1.ended_at)))

    for row <- all_rows do
      predicate = Subscription.entitling?(row)
      in_fragment = MapSet.member?(entitling_ids, row.id)

      assert predicate == in_fragment,
             "twin drift for status=#{inspect(row.status)} " <>
               "pause_collection=#{inspect(row.pause_collection)} " <>
               "ended_at=#{inspect(row.ended_at)}: " <>
               "entitling?/1=#{predicate} but in Query.entitling/1=#{in_fragment}"
    end
  end

  describe "in_active_dunning_campaign/1" do
    setup %{customer: customer} do
      now = Accrue.Clock.utc_now()

      # Subscription in an active dunning campaign (non-nil anchor).
      {:ok, dunning_sub} =
        %Subscription{}
        |> Subscription.changeset(%{
          customer_id: customer.id,
          processor: "fake",
          processor_id: "sub_dunning_active_#{Ecto.UUID.generate() |> binary_part(0, 8)}",
          status: :past_due,
          dunning_campaign_started_at: now
        })
        |> Repo.insert()

      %{dunning_sub: dunning_sub}
    end

    test "returns subscriptions with non-nil dunning_campaign_started_at", %{dunning_sub: dunning_sub} do
      result = Query.in_active_dunning_campaign() |> Repo.all()

      # The dunning fixture is in the result.
      assert Enum.any?(result, &(&1.id == dunning_sub.id))

      # Every element has a non-nil dunning_campaign_started_at.
      assert Enum.all?(result, &(not is_nil(&1.dunning_campaign_started_at)))
    end

    test "composes correctly when piped after an existing query", %{dunning_sub: dunning_sub} do
      import Ecto.Query, only: [from: 2]

      result =
        from(s in Subscription, where: s.status == :past_due)
        |> Query.in_active_dunning_campaign()
        |> Repo.all()

      # The dunning+past_due fixture appears in the result.
      assert Enum.any?(result, &(&1.id == dunning_sub.id))

      # Every result row is both :past_due AND in an active campaign.
      assert Enum.all?(result, &(&1.status == :past_due))
      assert Enum.all?(result, &(not is_nil(&1.dunning_campaign_started_at)))
    end
  end
end
