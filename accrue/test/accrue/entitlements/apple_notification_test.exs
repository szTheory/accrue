defmodule Accrue.Entitlements.AppleNotificationTest do
  use Accrue.RepoCase, async: false

  Code.require_file("../../fixtures/apple/server_evidence.exs", __DIR__)

  import Plug.Test

  alias Accrue.Entitlements.{Grant, Observation}
  alias Accrue.Entitlements.Apple.{Intake, NotificationPlug, ReconciliationWakeup, Verifier}
  alias Accrue.Entitlements.Apple.Verifier.Production
  alias Accrue.Test.AppleServerEvidence, as: Evidence

  @production_config %Verifier.Config{
    roots: [Evidence.production_root()],
    bundle_id: "com.accrue.test",
    environment: :production,
    app_apple_id: 42,
    verifier_version: "apple-v1",
    config_version: "test-v1"
  }

  defmodule FakeVerifier do
    def verify_notification("verified", _config) do
      {:ok,
       %{
         notification: %{"notificationUUID" => "notification-1"},
         transaction: %{
           "originalTransactionId" => "original-1",
           "transactionId" => "transaction-1",
           "productId" => "product_pro"
         },
         renewal: %{}
       }}
    end

    def verify_notification("sensitive-jws-token", config),
      do: verify_notification("verified", config)

    def verify_notification("quarantine", _config), do: {:error, :wrong_bundle}
    def verify_notification("malformed", _config), do: {:error, :invalid_payload}
    def verify_notification("retry", _config), do: {:error, :provider_unavailable}
  end

  defmodule CaptureVerifier do
    def verify_notification(_body, _config) do
      send(self(), :verifier_called)
      {:error, :wrong_bundle}
    end
  end

  test "acknowledges verified notifications only after durable intake" do
    conn = request("verified") |> NotificationPlug.call(base_opts())

    assert conn.status == 200
    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
  end

  test "retries a non-empty delivery whose exact raw capture is absent or unusable" do
    for capture <- [:missing, "", [], ["payload", :not_a_binary], %{body: "payload"}] do
      conn = conn(:post, "/apple/notifications", "payload")

      conn =
        if capture == :missing,
          do: conn,
          else: Plug.Conn.assign(conn, :raw_body, capture)

      assert conn
             |> NotificationPlug.call(
               base_opts(
                 verifier: CaptureVerifier,
                 intake: fn _evidence -> send(self(), :intake_called) end
               )
             )
             |> Map.fetch!(:status) == 503

      refute_received :verifier_called
      refute_received :intake_called
    end

    assert count(Intake) == 0
    assert count(ReconciliationWakeup) == 0
    assert count(Observation) == 0
    assert count(Grant) == 0
  end

  test "accepts binary and reverse-captured binary chunks byte-exactly" do
    for capture <- ["verified", ["ified", "ver"]] do
      assert conn(:post, "/apple/notifications", "verified")
             |> Plug.Conn.assign(:raw_body, capture)
             |> NotificationPlug.call(base_opts())
             |> Map.fetch!(:status) == 200
    end

    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
  end

  test "a signed production V2 envelope reaches one wakeup without account projection" do
    notification = Evidence.production_notification()

    assert {:ok, facts} = Production.verify_notification(notification, @production_config)
    assert facts.notification == %{"notificationUUID" => "notification-production-1"}
    assert facts.transaction["originalTransactionId"] == "opaque-lineage"

    production_opts =
      base_opts(
        verifier: Production,
        verifier_config: @production_config
      )

    assert request(notification) |> NotificationPlug.call(production_opts) |> Map.fetch!(:status) ==
             200

    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
    assert count(Observation) == 0
    assert count(Grant) == 0
  end

  test "production V2 delivery replays and converges concurrently on one durable wakeup" do
    notification = Evidence.production_notification()
    opts = production_opts()

    assert request(notification) |> NotificationPlug.call(opts) |> Map.fetch!(:status) == 200
    assert request(notification) |> NotificationPlug.call(opts) |> Map.fetch!(:status) == 200

    results =
      1..4
      |> Task.async_stream(
        fn _ -> request(notification) |> NotificationPlug.call(opts) |> Map.fetch!(:status) end,
        max_concurrency: 4,
        timeout: 5_000
      )
      |> Enum.to_list()

    assert Enum.all?(results, &match?({:ok, 200}, &1))
    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
  end

  test "production V2 persistence rollback remains retryable and leaves no wakeup" do
    notification = Evidence.production_notification()

    opts =
      production_opts(
        intake: fn evidence ->
          Intake.observe_notification(evidence,
            repo: Accrue.TestRepo,
            after_write: fn -> raise "injected_failure" end
          )
        end
      )

    assert request(notification) |> NotificationPlug.call(opts) |> Map.fetch!(:status) == 503
    assert count(Intake) == 0
    assert count(ReconciliationWakeup) == 0
  end

  test "production V2 rejects authenticated wrong application data without a wakeup" do
    for {key, value, reason} <- [
          {"bundleId", "com.example.wrong", :wrong_bundle},
          {"environment", "Sandbox", :wrong_environment},
          {"appAppleId", 7, :wrong_app}
        ] do
      notification = Evidence.production_notification(data: %{key => value})
      assert {:error, ^reason} = Production.verify_notification(notification, @production_config)

      assert request(notification)
             |> NotificationPlug.call(production_opts())
             |> Map.fetch!(:status) ==
               200
    end

    assert count(ReconciliationWakeup) == 0
  end

  test "production V2 independently closes outer and nested signature tampering" do
    outer = Evidence.tamper_signature(Evidence.production_notification())
    transaction = Evidence.tamper_signature(Evidence.production_transaction())
    renewal = Evidence.tamper_signature(Evidence.production_transaction())

    for notification <- [
          outer,
          Evidence.production_notification(transaction: transaction),
          Evidence.production_notification(renewal: renewal)
        ] do
      assert {:error, :invalid_signature} =
               Production.verify_notification(notification, @production_config)

      assert request(notification)
             |> NotificationPlug.call(production_opts())
             |> Map.fetch!(:status) ==
               200
    end

    assert count(ReconciliationWakeup) == 0
  end

  test "coalesces duplicate notifications into one durable wakeup" do
    assert request("verified") |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) == 200
    assert request("verified") |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) == 200

    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
  end

  test "acknowledges only a committed terminal quarantine and retries persistence failures" do
    assert request("quarantine") |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) ==
             200

    assert count(Intake) == 1

    failing_opts =
      base_opts(
        intake: fn evidence ->
          Intake.observe_notification(evidence,
            repo: Accrue.TestRepo,
            after_write: fn -> raise "injected_failure" end
          )
        end
      )

    assert request("verified") |> NotificationPlug.call(failing_opts) |> Map.fetch!(:status) ==
             503

    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 0
  end

  test "rejects retryable, malformed, oversized, and rate-limited traffic without storing it" do
    assert request("retry") |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) == 503

    assert request("malformed") |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) ==
             400

    assert request(String.duplicate("x", 5))
           |> NotificationPlug.call(base_opts(max_body_bytes: 4))
           |> Map.fetch!(:status) == 413

    assert request("verified")
           |> NotificationPlug.call(base_opts(rate_limiter: fn _conn -> {:deny, 60} end))
           |> Map.fetch!(:status) == 429

    assert count(Intake) == 0
    assert count(ReconciliationWakeup) == 0
  end

  test "qualifies identical notification identities by environment and never retains raw evidence" do
    raw = "sensitive-jws-token"

    assert request(raw) |> NotificationPlug.call(base_opts()) |> Map.fetch!(:status) == 200

    # Use the verifier facts directly to prove environment-qualified durable identity.
    {:ok, facts} = FakeVerifier.verify_notification("verified", %{})
    production = verified_evidence(facts, raw, :production)
    sandbox = %{production | environment: :sandbox}

    assert {:ok, %{disposition: :noop}} =
             Intake.observe_notification(production, repo: Accrue.TestRepo)

    assert {:ok, %{disposition: :verified}} =
             Intake.observe_notification(sandbox, repo: Accrue.TestRepo)

    rows = Accrue.TestRepo.all(Intake)
    assert Enum.map(rows, & &1.environment) |> Enum.sort() == [:production, :sandbox]
    refute inspect(rows) =~ raw
    refute Enum.any?(rows, &(inspect(&1) =~ "token@example.test"))
  end

  defp request(body),
    do: conn(:post, "/apple/notifications", body) |> Plug.Conn.assign(:raw_body, [body])

  defp base_opts(overrides \\ []) do
    NotificationPlug.init(
      Keyword.merge(
        [
          verifier: FakeVerifier,
          verifier_config: %{
            environment: :production,
            verifier_version: "fake-v1",
            config_version: "test-v1"
          },
          repo: Accrue.TestRepo,
          rate_limiter: fn _conn -> :allow end
        ],
        overrides
      )
    )
  end

  defp production_opts(overrides \\ []),
    do:
      base_opts(
        Keyword.merge([verifier: Production, verifier_config: @production_config], overrides)
      )

  defp verified_evidence(facts, raw, environment) do
    transaction = facts.transaction

    %Intake.VerifiedEvidence{
      environment: environment,
      original_transaction_id: transaction["originalTransactionId"],
      provider_event_id: facts.notification["notificationUUID"],
      provider_transaction_id: transaction["transactionId"],
      product_id: transaction["productId"],
      lifecycle: :grant,
      effective_at: ~U[2026-08-03 12:00:00.000000Z],
      signed_at: ~U[2026-08-03 12:00:00.000000Z],
      evidence_digest: :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower),
      verifier_version: "fake-v1",
      config_version: "test-v1"
    }
  end

  defp count(schema), do: Accrue.TestRepo.aggregate(schema, :count, :id)
end
