defmodule AccrueHostWeb.AppleNotificationIngestTest do
  use AccrueHost.HostFlowProofCase, async: false

  alias Accrue.Entitlements.Apple.{Intake, ReconciliationWakeup}
  alias AccrueHost.Repo

  defmodule FakeVerifier do
    def verify_notification(body, %{test_pid: test_pid}) do
      send(test_pid, {:apple_notification_bytes, body})

      {:ok,
       %{
         notification: %{"notificationUUID" => "host-apple-notification-001"},
         transaction: %{
           "originalTransactionId" => "host-apple-lineage-001",
           "transactionId" => "host-apple-transaction-001",
           "productId" => "host-apple-product-001"
         }
       }}
    end

    def verify_transaction(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
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

  defp digest(payload), do: :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
