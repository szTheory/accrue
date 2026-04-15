defmodule AccrueAdmin.E2E.Plug do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  alias AccrueAdmin.E2E.Fixtures

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    json(conn, 200, %{ok: true})
  end

  get "/login" do
    target = conn.params["to"] || "/billing"

    conn
    |> fetch_session()
    |> put_session(:admin_token, "admin")
    |> put_resp_header("location", target)
    |> send_resp(302, "")
  end

  post "/reset" do
    Fixtures.reset!()
    json(conn, 200, %{ok: true})
  end

  post "/seed/dashboard" do
    json(conn, 200, Fixtures.seed_dashboard!())
  end

  post "/seed/operator-flows" do
    json(conn, 200, Fixtures.seed_operator_flows!())
  end

  get "/counts" do
    json(conn, 200, Fixtures.current_counts())
  end

  match _ do
    json(conn, 404, %{error: "not_found"})
  end

  defp json(conn, status, payload) do
    body = Jason.encode!(payload)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end
end
