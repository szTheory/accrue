defmodule AccrueAdmin.E2E.Plug do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  alias AccrueAdmin.E2E.Fixtures

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    identity = Application.get_env(:accrue_admin, :phase252_e2e_identity)

    payload =
      case identity do
        %{nonce: nonce} when is_binary(nonce) ->
          Map.merge(
            %{ok: true},
            Map.take(identity, [
              :nonce,
              :database,
              :role,
              :address,
              :port,
              :partition,
              :pid,
              :ready
            ])
          )

        _ ->
          %{ok: true}
      end

    json(conn, 200, payload)
  end

  get "/login" do
    target = conn.params["to"] || "/billing"

    conn
    |> fetch_session()
    |> put_session(:admin_token, "admin")
    |> put_resp_header("location", target)
    |> send_resp(302, "")
  end

  get "/login-member" do
    login_member(conn)
  end

  get "/__e2e__/login-member" do
    login_member(conn)
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

  post "/seed/advisory-entitlements" do
    json(conn, 200, Fixtures.seed_advisory_entitlements!())
  end

  post "/seed/edge-states" do
    json(conn, 200, Fixtures.seed_edge_states!())
  end

  post "/__e2e__/seed/edge-states" do
    json(conn, 200, Fixtures.seed_edge_states!())
  end

  post "/seed/overflow" do
    json(conn, 200, Fixtures.seed_overflow!())
  end

  post "/__e2e__/seed/overflow" do
    json(conn, 200, Fixtures.seed_overflow!())
  end

  post "/seed/phase191-matrix" do
    json(conn, 200, Fixtures.seed_phase191_matrix!())
  end

  post "/__e2e__/seed/phase191-matrix" do
    json(conn, 200, Fixtures.seed_phase191_matrix!())
  end

  post "/seed/phase199-interactions" do
    json(conn, 200, Fixtures.seed_phase199_interactions!())
  end

  post "/seed/phase199-interaction-matrix" do
    json(conn, 200, Fixtures.seed_phase199_interaction_matrix!())
  end

  post "/__e2e__/seed/phase199-interactions" do
    json(conn, 200, Fixtures.seed_phase199_interactions!())
  end

  post "/__e2e__/seed/phase199-interaction-matrix" do
    json(conn, 200, Fixtures.seed_phase199_interaction_matrix!())
  end

  post "/__e2e__/seed/phase241-review-matrix" do
    json(conn, 200, Fixtures.seed_phase241_review_matrix!())
  end

  post "/seed/phase241-review-matrix" do
    json(conn, 200, Fixtures.seed_phase241_review_matrix!())
  end

  post "/__e2e__/reset" do
    Fixtures.reset!()
    json(conn, 200, %{ok: true})
  end

  post "/phase240/hold-subscription-cancel" do
    case Fixtures.hold_phase240_subscription_cancel!(conn.params["subscription_id"]) do
      {:ok, hold} -> json(conn, 200, hold)
      {:error, :action_already_held} -> json(conn, 409, %{error: "action_already_held"})
    end
  end

  get "/phase240/action-status" do
    case Fixtures.phase240_action_status(conn.params["token"]) do
      nil -> json(conn, 404, %{error: "unknown_action_hold"})
      observation -> json(conn, 200, observation)
    end
  end

  post "/phase240/release-action" do
    case Fixtures.release_phase240_action!(conn.params["token"]) do
      :ok -> json(conn, 200, %{ok: true})
      {:error, :unknown_action_hold} -> json(conn, 404, %{error: "unknown_action_hold"})
    end
  end

  post "/__e2e__/seed/dashboard" do
    json(conn, 200, Fixtures.seed_dashboard!())
  end

  post "/__e2e__/seed/operator-flows" do
    json(conn, 200, Fixtures.seed_operator_flows!())
  end

  post "/__e2e__/seed/advisory-entitlements" do
    json(conn, 200, Fixtures.seed_advisory_entitlements!())
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

  defp login_member(conn) do
    target = conn.params["to"] || "/billing"

    conn
    |> fetch_session()
    |> put_session(:admin_token, "member")
    |> put_resp_header("location", target)
    |> send_resp(302, "")
  end
end
