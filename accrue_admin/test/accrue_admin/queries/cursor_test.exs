defmodule AccrueAdmin.Queries.CursorTest do
  use ExUnit.Case, async: true

  alias AccrueAdmin.Queries.Cursor

  test "round-trips signed timestamp and id tuples" do
    timestamp = ~U[2026-04-15 12:00:00.123456Z]
    id = Ecto.UUID.generate()

    cursor = Cursor.encode(timestamp, id)

    assert {:ok, {^timestamp, ^id}} = Cursor.decode(cursor)
  end

  test "rejects tampered payloads" do
    cursor = Cursor.encode(~U[2026-04-15 12:00:00Z], Ecto.UUID.generate())

    [payload, signature] = String.split(cursor, ".", parts: 2)
    tampered_payload = Base.url_encode64("bad-payload", padding: false)

    assert :error = Cursor.decode(tampered_payload <> "." <> signature)
    assert :error = Cursor.decode(payload <> ".bogus")
  end
end
