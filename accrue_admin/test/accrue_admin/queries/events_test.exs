defmodule AccrueAdmin.Queries.EventsTest do
  use AccrueAdmin.RepoCase, async: false

  alias Accrue.Billing.{Charge, Customer}
  alias AccrueAdmin.OwnerScope
  alias AccrueAdmin.Queries.Cursor
  alias AccrueAdmin.TestRepo

  # Note the module-name collision: `Accrue.Events` is the core context that
  # *records* events into the append-only ledger, while
  # `AccrueAdmin.Queries.Events` is the admin *query* module under test. Both
  # are referenced by their fully-qualified names below to avoid alias ambiguity.

  setup do
    # Seed 30 events so the list overflows the 25-row page limit and forces the
    # paginate/3 → Cursor.encode boundary to handle the integer event PK.
    # Sequential inserts yield ascending integer ids; the query's desc-id
    # tiebreak guarantees a stable, non-overlapping page split even when several
    # rows share the same read_after_writes inserted_at timestamp.
    for n <- 1..30 do
      {:ok, _event} =
        Accrue.Events.record(%{
          type: "subscription.updated.#{n}",
          subject_type: "Subscription",
          subject_id: "sub_#{n}",
          actor_type: "admin",
          actor_id: "admin_1"
        })
    end

    :ok
  end

  test "paginates >25 integer-PK events with a non-nil integer-id cursor and no overlap" do
    {rows1, next_cursor} = AccrueAdmin.Queries.Events.list(limit: 25)

    assert length(rows1) == 25
    assert is_binary(next_cursor)

    assert {:ok, {%DateTime{}, id}} = Cursor.decode(next_cursor)
    assert is_integer(id)

    # Second page must load (pre-fix this raises FunctionClauseError at the
    # paginate/3 → Cursor.encode boundary because the event id is an integer).
    {rows2, _next} = AccrueAdmin.Queries.Events.list(limit: 25, cursor: next_cursor)

    assert rows2 != []

    assert MapSet.disjoint?(
             MapSet.new(rows1, & &1.id),
             MapSet.new(rows2, & &1.id)
           )
  end

  test "organization scope includes in-scope Charge subject events in list and detail" do
    allowed_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_allowed"})
    denied_customer = insert_customer(%{owner_type: "Organization", owner_id: "org_denied"})
    allowed_charge = insert_charge(allowed_customer, %{processor_id: "ch_query_allowed"})
    denied_charge = insert_charge(denied_customer, %{processor_id: "ch_query_denied"})

    {:ok, allowed_event} =
      Accrue.Events.record(%{
        type: "charge.succeeded.allowed_org",
        subject_type: "Charge",
        subject_id: allowed_charge.id,
        actor_type: "system"
      })

    {:ok, denied_event} =
      Accrue.Events.record(%{
        type: "charge.succeeded.denied_org",
        subject_type: "Charge",
        subject_id: denied_charge.id,
        actor_type: "system"
      })

    scope = organization_owner_scope("org_allowed")

    {rows, _next_cursor} =
      AccrueAdmin.Queries.Events.list(
        owner_scope: scope,
        filter: %{subject_type: "Charge"},
        limit: 25
      )

    assert Enum.any?(rows, &(&1.id == allowed_event.id))
    refute Enum.any?(rows, &(&1.id == denied_event.id))

    allowed_event_id = allowed_event.id

    assert {:ok, %{id: ^allowed_event_id}} =
             AccrueAdmin.Queries.Events.detail(allowed_event_id, scope)

    assert :not_found = AccrueAdmin.Queries.Events.detail(denied_event.id, scope)
  end

  defp insert_customer(attrs) do
    defaults = %{
      owner_type: "User",
      owner_id: Ecto.UUID.generate(),
      processor: "stripe",
      processor_id: "cus_" <> Integer.to_string(System.unique_integer([:positive])),
      preferred_locale: "en",
      metadata: %{},
      data: %{}
    }

    %Customer{}
    |> Customer.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp insert_charge(customer, attrs) do
    defaults = %{
      customer_id: customer.id,
      processor: "stripe",
      processor_id: "ch_" <> Integer.to_string(System.unique_integer([:positive])),
      amount_cents: 1_000,
      currency: "usd",
      status: "succeeded",
      metadata: %{},
      data: %{},
      lock_version: 1
    }

    %Charge{}
    |> Charge.changeset(Map.merge(defaults, attrs))
    |> TestRepo.insert!()
  end

  defp organization_owner_scope(organization_id) do
    %OwnerScope{
      mode: :organization,
      current_admin: %{id: "admin_1", role: :admin},
      organization_id: organization_id,
      organization_slug: "allowed-org",
      platform_admin?: false,
      admin_org_ids: [organization_id],
      active_organization_id: organization_id,
      active_organization_slug: "allowed-org"
    }
  end
end
