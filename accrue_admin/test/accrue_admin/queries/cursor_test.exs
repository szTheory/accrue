defmodule AccrueAdmin.Queries.CursorTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Queries.Cursor

  test "round-trips signed timestamp and id tuples" do
    timestamp = ~U[2026-04-15 12:00:00.123456Z]
    id = Ecto.UUID.generate()

    cursor = Cursor.encode(timestamp, id)

    assert {:ok, {^timestamp, ^id}} = Cursor.decode(cursor)
  end

  test "round-trips signed timestamp and integer id tuples" do
    # The append-only event ledger uses an integer primary key, so the cursor
    # must accept integer ids (not just binary UUIDs) and round-trip them intact.
    timestamp = ~U[2026-04-15 12:00:00.123456Z]
    id = 16

    cursor = Cursor.encode(timestamp, id)

    assert {:ok, {^timestamp, decoded_id}} = Cursor.decode(cursor)
    assert is_integer(decoded_id)
    assert decoded_id == 16
  end

  test "rejects tampered payloads" do
    cursor = Cursor.encode(~U[2026-04-15 12:00:00Z], Ecto.UUID.generate())

    [payload, signature] = String.split(cursor, ".", parts: 2)
    tampered_payload = Base.url_encode64("bad-payload", padding: false)

    assert :error = Cursor.decode(tampered_payload <> "." <> signature)
    assert :error = Cursor.decode(payload <> ".bogus")
  end
end
