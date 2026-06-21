defmodule AccrueAdmin.Queries.EventsTest do
  use AccrueAdmin.RepoCase, async: false

  alias AccrueAdmin.Queries.Cursor

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
end
