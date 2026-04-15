defmodule Accrue.Webhook.MultiEndpointTest do
  use Accrue.RepoCase

  @primary_secret "whsec_primary_test_secret"
  @connect_secret "whsec_connect_test_secret"

  defmodule TestRouter do
    @moduledoc false
    use Plug.Router

    plug Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason,
      body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}

    plug :match
    plug :dispatch

    # Order matters: more specific prefixes must be declared first
    # (Plug.Router matches in declaration order).
    forward "/webhooks/stripe/connect",
      to: Accrue.Webhook.Plug,
      init_opts: [endpoint: :connect, processor: :stripe]

    forward "/webhooks/stripe/missing",
      to: Accrue.Webhook.Plug,
      init_opts: [endpoint: :unconfigured, processor: :stripe]

    forward "/webhooks/stripe",
      to: Accrue.Webhook.Plug,
      init_opts: [endpoint: :primary, processor: :stripe]

    match _ do
      send_resp(conn, 404, "not found")
    end
  end

  defmodule NoRawBodyRouter do
    @moduledoc false
    use Plug.Router

    plug Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason

    plug :match
    plug :dispatch

    get "/api/hello" do
      send_resp(conn, 200, Jason.encode!(%{raw_body_present: conn.assigns[:raw_body] != nil}))
    end

    match _ do
      send_resp(conn, 404, "not found")
    end
  end

  @payload Jason.encode!(%{
             "id" => "evt_multi_endpoint_1",
             "object" => "event",
             "type" => "customer.created",
             "created" => 1_700_000_000,
             "livemode" => false,
             "data" => %{"object" => %{"id" => "cus_multi_1", "object" => "customer"}}
           })

  setup do
    Application.put_env(:accrue, :webhook_endpoints,
      primary: [secret: @primary_secret],
      connect: [secret: @connect_secret, mode: :connect]
    )

    on_exit(fn ->
      Application.delete_env(:accrue, :webhook_endpoints)
    end)

    :ok
  end

  test "primary endpoint accepts signature signed with primary secret" do
    sig = LatticeStripe.Webhook.generate_test_signature(@payload, @primary_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 200
  end

  test "connect endpoint accepts signature signed with connect secret" do
    payload = Jason.encode!(%{
      "id" => "evt_multi_endpoint_connect",
      "object" => "event",
      "type" => "customer.created",
      "created" => 1_700_000_000,
      "livemode" => false,
      "data" => %{"object" => %{"id" => "cus_multi_2", "object" => "customer"}}
    })
    sig = LatticeStripe.Webhook.generate_test_signature(payload, @connect_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe/connect", payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 200
  end

  test "primary endpoint REJECTS connect-secret signature (no cross-fallback)" do
    sig = LatticeStripe.Webhook.generate_test_signature(@payload, @connect_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 400
  end

  test "missing endpoint config returns 400 (fail closed)" do
    sig = LatticeStripe.Webhook.generate_test_signature(@payload, @primary_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe/missing", @payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 400
  end

  test "connect endpoint persists endpoint: :connect on the webhook_events row (D5-01)" do
    payload =
      Jason.encode!(%{
        "id" => "evt_persist_connect_1",
        "object" => "event",
        "type" => "account.updated",
        "created" => 1_700_000_000,
        "livemode" => false,
        "data" => %{"object" => %{"id" => "acct_connected_1", "object" => "account"}}
      })

    sig = LatticeStripe.Webhook.generate_test_signature(payload, @connect_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe/connect", payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 200

    row =
      Accrue.TestRepo.get_by!(Accrue.Webhook.WebhookEvent,
        processor_event_id: "evt_persist_connect_1"
      )

    assert row.endpoint == :connect
  end

  test "primary endpoint persists endpoint: :default (non-connect names collapse) (D5-01)" do
    payload =
      Jason.encode!(%{
        "id" => "evt_persist_primary_1",
        "object" => "event",
        "type" => "customer.created",
        "created" => 1_700_000_000,
        "livemode" => false,
        "data" => %{"object" => %{"id" => "cus_primary_1", "object" => "customer"}}
      })

    sig = LatticeStripe.Webhook.generate_test_signature(payload, @primary_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestRouter.call(TestRouter.init([]))

    assert conn.status == 200

    row =
      Accrue.TestRepo.get_by!(Accrue.Webhook.WebhookEvent,
        processor_event_id: "evt_persist_primary_1"
      )

    assert row.endpoint == :default
  end

  test "raw body capture stays scoped to webhook routes" do
    conn =
      Plug.Test.conn(:get, "/api/hello")
      |> NoRawBodyRouter.call(NoRawBodyRouter.init([]))

    assert conn.status == 200
    assert %{"raw_body_present" => false} = Jason.decode!(conn.resp_body)
  end
end
