defmodule Accrue.Webhook.PlugTest do
  use Accrue.RepoCase

  @moduledoc """
  Integration tests for the webhook plug pipeline:
  CachingBodyReader + Signature verification + Plug dispatch.

  Tests use LatticeStripe.Webhook.generate_test_signature/3 to produce
  valid Stripe-Signature headers and verify behavior end-to-end through
  a test Plug.Router.

  Note: Since Plan 04, the Plug routes through Accrue.Webhook.Ingest
  which performs DB writes, so these tests require RepoCase for the
  Ecto sandbox.
  """

  # --- Test router that mimics a host app's webhook pipeline ---------------

  defmodule TestWebhookRouter do
    @moduledoc false
    use Plug.Router

    plug(Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason,
      body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
    )

    plug(:match)
    plug(:dispatch)

    forward("/webhooks/stripe", to: Accrue.Webhook.Plug, init_opts: [processor: :stripe])

    match _ do
      send_resp(conn, 404, "not found")
    end
  end

  # A second router WITHOUT CachingBodyReader to verify scoping (Test 5)
  defmodule TestNonWebhookRouter do
    @moduledoc false
    use Plug.Router

    plug(Plug.Parsers,
      parsers: [:json],
      pass: ["*/*"],
      json_decoder: Jason
    )

    plug(:match)
    plug(:dispatch)

    get "/api/hello" do
      raw = conn.assigns[:raw_body]
      send_resp(conn, 200, Jason.encode!(%{raw_body_present: raw != nil}))
    end

    match _ do
      send_resp(conn, 404, "not found")
    end
  end

  # --- Test helpers -------------------------------------------------------

  @test_secret "whsec_test_secret_for_plug_tests"
  @test_secret_a "whsec_secret_a"
  @test_secret_b "whsec_secret_b"

  @valid_event_payload Jason.encode!(%{
                         "id" => "evt_test_123",
                         "object" => "event",
                         "type" => "customer.created",
                         "created" => 1_700_000_000,
                         "livemode" => false,
                         "data" => %{
                           "object" => %{
                             "id" => "cus_test_456",
                             "object" => "customer"
                           }
                         }
                       })

  setup do
    Code.ensure_loaded!(Plug.Crypto)
    # Configure webhook signing secrets for the :stripe processor
    Application.put_env(:accrue, :webhook_signing_secrets, %{stripe: [@test_secret]})

    on_exit(fn ->
      Application.delete_env(:accrue, :webhook_signing_secrets)
    end)

    :ok
  end

  # --- Test 1: Valid signature returns 200 (T-2-01 happy path) ------------

  test "POST with valid signature returns 200" do
    sig = LatticeStripe.Webhook.generate_test_signature(@valid_event_payload, @test_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @valid_event_payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestWebhookRouter.call(TestWebhookRouter.init([]))

    assert conn.status == 200
    assert %{"ok" => true} = Jason.decode!(conn.resp_body)
  end

  # --- Test 2: Tampered body returns 400 (T-2-01 security) ----------------

  test "POST with tampered body returns 400" do
    # Sign with the original payload, then send a different body
    sig = LatticeStripe.Webhook.generate_test_signature(@valid_event_payload, @test_secret)

    tampered_body = Jason.encode!(%{"id" => "evt_evil", "type" => "charge.captured"})

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", tampered_body)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestWebhookRouter.call(TestWebhookRouter.init([]))

    assert conn.status == 400
    assert %{"error" => "signature_verification_failed"} = Jason.decode!(conn.resp_body)
  end

  # --- Test 3: Rotation -- signed with secret_b, secrets = [a, b] (T-2-05)

  test "POST signed with secret_b when secrets = [secret_a, secret_b] returns 200" do
    Application.put_env(:accrue, :webhook_signing_secrets, %{
      stripe: [@test_secret_a, @test_secret_b]
    })

    sig = LatticeStripe.Webhook.generate_test_signature(@valid_event_payload, @test_secret_b)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @valid_event_payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestWebhookRouter.call(TestWebhookRouter.init([]))

    assert conn.status == 200
  end

  # --- Test 4: Raw body is populated in assigns (T-2-02) ------------------

  test "POST to webhook route has conn.assigns[:raw_body] populated and persists event" do
    sig = LatticeStripe.Webhook.generate_test_signature(@valid_event_payload, @test_secret)

    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @valid_event_payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("stripe-signature", sig)
      |> TestWebhookRouter.call(TestWebhookRouter.init([]))

    assert conn.status == 200

    # Since Plan 04, the Plug delegates to Ingest which persists the event.
    # Verify the webhook event was persisted with correct data.
    events = Accrue.TestRepo.all(Accrue.Webhook.WebhookEvent)
    assert length(events) == 1
    [event] = events
    assert event.processor == "stripe"
    assert event.processor_event_id == "evt_test_123"
    assert event.type == "customer.created"
  end

  # --- Test 5: Non-webhook route does NOT have raw_body (WH-01 scoping) ---

  test "POST to non-webhook route does NOT have raw_body in assigns" do
    conn =
      Plug.Test.conn(:get, "/api/hello")
      |> TestNonWebhookRouter.call(TestNonWebhookRouter.init([]))

    assert conn.status == 200
    assert %{"raw_body_present" => false} = Jason.decode!(conn.resp_body)
  end

  # --- Test 6: Missing stripe-signature header returns 400 ----------------

  test "missing stripe-signature header returns 400" do
    conn =
      Plug.Test.conn(:post, "/webhooks/stripe", @valid_event_payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> TestWebhookRouter.call(TestWebhookRouter.init([]))

    assert conn.status == 400
    assert %{"error" => "signature_verification_failed"} = Jason.decode!(conn.resp_body)
  end
end
