defmodule Accrue.Plug.PutOperationIdTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Accrue.Plug.PutOperationId

  setup do
    Accrue.Actor.put_operation_id(nil)
    :ok
  end

  test "reads request_id from conn.assigns" do
    conn =
      :get
      |> conn("/")
      |> Plug.Conn.assign(:request_id, "req-abc-123")

    PutOperationId.call(conn, [])
    assert Accrue.Actor.current_operation_id() == "req-abc-123"
  end

  test "falls back to x-request-id header" do
    conn =
      :get
      |> conn("/")
      |> Plug.Conn.put_req_header("x-request-id", "req-header-456")

    PutOperationId.call(conn, [])
    assert Accrue.Actor.current_operation_id() == "req-header-456"
  end

  test "generates http- prefix fallback when both missing" do
    conn = conn(:get, "/")
    PutOperationId.call(conn, [])
    assert Accrue.Actor.current_operation_id() =~ ~r/^http-[0-9a-f]{16}$/
  end

  test "Accrue.Oban.Middleware.put/1 formats oban-<id>-<attempt>" do
    Accrue.Oban.Middleware.put(%{id: 42, attempt: 3})
    assert Accrue.Actor.current_operation_id() == "oban-42-3"
  end
end
