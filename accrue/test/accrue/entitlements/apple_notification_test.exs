defmodule Accrue.Entitlements.AppleNotificationTest do
  use Accrue.RepoCase, async: false

  import Plug.Test

  alias Accrue.Entitlements.Apple.{Intake, NotificationPlug, ReconciliationWakeup}

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

  test "acknowledges verified notifications only after durable intake" do
    conn = request("verified") |> NotificationPlug.call(base_opts())

    assert conn.status == 200
    assert count(Intake) == 1
    assert count(ReconciliationWakeup) == 1
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
