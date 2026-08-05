defmodule AccrueHostWeb.AppleNotificationIngestTest do
  use AccrueHost.HostFlowProofCase, async: false

  alias Accrue.Entitlements.Apple.{Intake, ReconciliationWakeup}
  alias AccrueHost.AppleNotificationIngress
  alias AccrueHost.Repo

  defmodule FakeVerifier do
    def verify_notification(body, %{test_pid: test_pid} = config) do
      send(test_pid, {:apple_notification_bytes, body})

      Map.get(config, :result, {:ok, valid_facts()})
    end

    def verify_transaction(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}

    defp valid_facts do
      %{
        notification: %{"notificationUUID" => "host-apple-notification-001"},
        transaction: %{
          "originalTransactionId" => "host-apple-lineage-001",
          "transactionId" => "host-apple-transaction-001",
          "productId" => "host-apple-product-001"
        }
      }
    end
  end

  defmodule FailingRepo do
    def transact(_fun), do: {:error, :injected_failure}
  end

  setup do
    prior_ingress = Application.get_env(:accrue_host, :apple_notification_ingress)

    Application.put_env(:accrue_host, :apple_notification_ingress,
      verifier: FakeVerifier,
      verifier_config: %{
        test_pid: self(),
        environment: :production,
        verifier_version: "fake-v1",
        config_version: "host-test-v1"
      },
      repo: Repo,
      max_body_bytes: 262_144
    )

    on_exit(fn -> restore_env(:accrue_host, :apple_notification_ingress, prior_ingress) end)
  end

  test "POST /webhooks/apple preserves exact bytes before durable intake and wakeup" do
    payload = ~s({"opaque":"host-router-apple-notification"})

    conn =
      Plug.Test.conn(:post, "/webhooks/apple", payload)
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> AccrueHostWeb.Router.call(AccrueHostWeb.Router.init([]))

    assert_receive {:apple_notification_bytes, ^payload}
    assert conn.status == 200
    assert conn.resp_body == ""

    intake = Repo.get_by!(Intake, provider_event_id: "host-apple-notification-001")
    assert intake.environment == :production
    assert intake.disposition == "verified"
    assert intake.evidence_digest == digest(payload)

    assert %ReconciliationWakeup{lineage_id: lineage_id, environment: :production} =
             Repo.one!(ReconciliationWakeup)

    assert lineage_id == intake.lineage_id
  end

  test "Apple source keeps a dedicated bounded raw-body pipeline and shared production verifier config" do
    router = File.read!(Path.expand("../../lib/accrue_host_web/router.ex", __DIR__))
    runtime = File.read!(Path.expand("../../config/runtime.exs", __DIR__))

    assert router =~ "pipeline :accrue_apple_notifications_raw_body do"
    assert router =~ "length: 262_144"
    assert router =~ "forward(\"/apple\", AccrueHost.AppleNotificationIngress)"
    assert router =~ "accrue_webhook(\"/stripe\", :stripe)"
    assert router =~ "length: 1_000_000"

    assert runtime =~ "environment: :production"
    assert runtime =~ "verifier_version: \"apple-production-v1\""
    assert runtime =~ "verifier_config: verifier_config"
  end

  test "product maps admit only configured entitlement plan keys" do
    assert %{"com.example.scale" => :scale} =
             AppleNotificationIngress.decode_product_map!(
               ~s({"com.example.scale":"scale"}),
               [:scale]
             )

    assert_raise ArgumentError, "APPLE_PRODUCT_MAP_JSON contains an unknown plan", fn ->
      AppleNotificationIngress.decode_product_map!(
        ~s({"com.example.pro":"production"}),
        [:scale]
      )
    end
  end

  test "product map loader fails closed for invalid catalog and map inputs" do
    for {json, catalog} <- [
          {"", [:scale]},
          {"{}", [:scale]},
          {~s({"":"scale"}), [:scale]},
          {~s({"com.example.scale":""}), [:scale]},
          {~s({"com.example.scale":"scale"}), []},
          {~s({"com.example.scale":"scale"}), ["scale"]}
        ] do
      assert_raise ArgumentError, fn ->
        AppleNotificationIngress.decode_product_map!(json, catalog)
      end
    end
  end

  test "router maps verification, rate, and quarantine outcomes to empty response classes" do
    assert_response_class({:error, :invalid_payload}, :allow, 400)
    assert_response_class({:ok, valid_facts()}, {:deny, 15}, 429)
    assert_response_class({:error, :provider_unavailable}, :allow, 503)
    assert_response_class({:error, :wrong_bundle}, :allow, 200)

    assert %Intake{disposition: "quarantined", reason: "wrong_bundle"} =
             Repo.get_by!(Intake, provider_event_id: "quarantine:" <> digest(payload()))
  end

  test "serial and concurrent router duplicates converge to one intake and wakeup" do
    assert 200 == post_apple(payload()).status
    assert 200 == post_apple(payload()).status

    parent = self()

    deliveries =
      for _ <- 1..2 do
        Task.async(fn ->
          send(parent, {:apple_delivery_ready, self()})
          receive do: (:deliver -> post_apple(payload()).status)
        end)
      end

    delivery_pids = for _ <- deliveries, do: receive(do: ({:apple_delivery_ready, pid} -> pid))
    Enum.each(delivery_pids, &send(&1, :deliver))
    concurrent_statuses = Enum.map(deliveries, &Task.await(&1, 5_000))

    assert concurrent_statuses == [200, 200]
    assert Repo.aggregate(Intake, :count) == 1
    assert Repo.aggregate(ReconciliationWakeup, :count) == 1
  end

  test "router rejects an Apple body above the shared 262,144-byte boundary" do
    oversized = ~s({"opaque":"#{String.duplicate("x", 262_145)}"})

    assert_raise Plug.Conn.WrapperError, fn -> post_apple(oversized) end
  end

  test "wrapper preserves missing-capture, plug-overflow, and persistence retry responses" do
    configure_ingress({:ok, valid_facts()}, :allow)

    missing_capture = Plug.Test.conn(:post, "/webhooks/apple", "")
    assert 503 == AppleNotificationIngress.call(missing_capture, []).status

    plug_overflow =
      Plug.Test.conn(:post, "/webhooks/apple", "")
      |> Plug.Conn.assign(:raw_body, String.duplicate("x", 262_145))

    assert 413 == AppleNotificationIngress.call(plug_overflow, []).status

    configure_ingress({:ok, valid_facts()}, :allow, FailingRepo)
    assert 503 == post_apple(payload()).status
  end

  test "responses, logs, and notification telemetry exclude synthetic evidence" do
    marker = "opaque-body-token-should-never-escape"
    handler_id = "apple-notification-privacy-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        [:accrue, :entitlements, :apple, :notification],
        fn _event, _measurements, metadata, test_pid ->
          send(test_pid, {:apple_notification_telemetry, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    conn =
      ExUnit.CaptureLog.capture_log(fn ->
        post_apple(~s({"opaque":"#{marker}"}))
      end)

    assert_receive {:apple_notification_telemetry, metadata}
    refute inspect(metadata) =~ marker
    refute conn =~ marker
    refute Enum.any?(Repo.all(Intake), &(inspect(&1) =~ marker))
  end

  defp assert_response_class(verifier_result, rate_limiter, expected_status) do
    configure_ingress(verifier_result, rate_limiter)
    conn = post_apple(payload())

    assert conn.status == expected_status
    assert conn.resp_body == ""
  end

  defp configure_ingress(verifier_result, rate_limiter, repo \\ Repo) do
    Application.put_env(:accrue_host, :apple_notification_ingress,
      verifier: FakeVerifier,
      verifier_config: %{
        test_pid: self(),
        result: verifier_result,
        environment: :production,
        verifier_version: "fake-v1",
        config_version: "host-test-v1"
      },
      rate_limiter: fn _conn -> rate_limiter end,
      repo: repo,
      max_body_bytes: 262_144
    )
  end

  defp post_apple(payload) do
    Plug.Test.conn(:post, "/webhooks/apple", payload)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> AccrueHostWeb.Router.call(AccrueHostWeb.Router.init([]))
  end

  defp payload, do: ~s({"opaque":"host-router-apple-notification"})

  defp valid_facts do
    %{
      notification: %{"notificationUUID" => "host-apple-notification-001"},
      transaction: %{
        "originalTransactionId" => "host-apple-lineage-001",
        "transactionId" => "host-apple-transaction-001",
        "productId" => "host-apple-product-001"
      }
    }
  end

  defp digest(payload), do: :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
