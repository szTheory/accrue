defmodule AccrueHost.RecoveryWiringTest do
  @moduledoc """
  Phase 158 Plan 01 — PROOF-06: host-level recovery wiring config proof.
  """

  use AccrueHost.AccrueCase, async: false

  alias Accrue.Jobs.DunningSweeper
  alias Accrue.Jobs.DetectExpiringCards
  alias Accrue.Jobs.MeteredRenewalReconciler
  alias Accrue.Jobs.MeterEventsReconciler
  alias Accrue.Entitlements.Apple.ReconciliationSweeper
  alias Accrue.Entitlements.{Account, Device, Observation, Projector}
  alias Accrue.Entitlements.Offline

  alias Accrue.Entitlements.Offline.{
    Issuance,
    Reconnect,
    ReconnectAttempt,
    ReconnectSweeper,
    ReconnectWakeup,
    ReconnectWakeupWorker,
    ReconnectWorker,
    SourceCoordinator
  }

  @now ~U[2026-08-04 12:00:00.000000Z]

  defmodule SigningProvider do
    @behaviour Accrue.Entitlements.Offline.KeyProvider

    @impl true
    def sign(payload, opts) do
      key = Keyword.fetch!(opts, :signing_key)
      header = %{"alg" => "ES256", "typ" => "accrue-entitlement-proof+jwt", "kid" => key["kid"]}

      {:ok,
       key
       |> JOSE.JWK.from()
       |> JOSE.JWS.sign(Jason.encode!(payload), header)
       |> JOSE.JWS.compact()
       |> elem(1)}
    end

    @impl true
    def public_keys(opts), do: {:ok, [Keyword.fetch!(opts, :public_key)]}
  end

  defmodule InstrumentedDueSourceCoordinator do
    @behaviour SourceCoordinator

    @impl true
    def due_sources(account, now, opts) do
      fixture = Keyword.fetch!(opts, :provider_fixture)

      send(
        Keyword.fetch!(opts, :test_pid),
        {:due_sources_called, account.id, now, fixture, authority_keys(opts)}
      )

      {:ok, [fixture]}
    end

    @impl true
    def refresh(account, status, now, opts) do
      fixture = Keyword.fetch!(opts, :provider_fixture)

      send(
        Keyword.fetch!(opts, :test_pid),
        {:refresh_called, account.id, status, now, fixture, authority_keys(opts)}
      )

      {:ok, %{status | state: :resolved, retry_after: nil, next_action: :none}}
    end

    @impl true
    def enqueue_repair(_, _, _, opts) do
      send(Keyword.fetch!(opts, :test_pid), :repair_enqueued)
      :ok
    end

    defp authority_keys(opts),
      do:
        opts
        |> Keyword.keys()
        |> Enum.filter(&(&1 in [:provider_fixture, :proof, :client_proof]))
        |> Enum.sort()
  end

  setup do
    originals =
      for key <- [:offline_reconnect, :entitlements, :rails, :default_rail],
          into: %{},
          do: {key, Application.get_env(:accrue, key)}

    Application.put_env(:accrue, :entitlements,
      plans: [pro: [features: [:offline_study], products: [stripe: [production: ["price_pro"]]]]]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production]
    )

    Application.put_env(:accrue, :default_rail, :stripe)

    signing_key = test_key()

    public_key =
      signing_key
      |> Map.take(["kty", "crv", "kid", "x", "y"])
      |> Map.merge(%{"alg" => "ES256", "use" => "sig"})

    fixture = %SourceCoordinator.SourceStatus{
      source: :stripe,
      environment: :production,
      due: true,
      state: :pending,
      retry_after: nil,
      next_action: :reconnect_required
    }

    Application.put_env(:accrue, :offline_reconnect,
      source_coordinator: InstrumentedDueSourceCoordinator,
      key_provider: SigningProvider,
      provider_fixture: fixture,
      test_pid: self(),
      signing_key: signing_key,
      public_key: public_key,
      issuer: "accrue.host.offline",
      audience: "accrue-host-offline-client"
    )

    on_exit(fn ->
      Enum.each(originals, fn {key, original} ->
        if original,
          do: Application.put_env(:accrue, key, original),
          else: Application.delete_env(:accrue, key)

        assert Application.get_env(:accrue, key) == original
      end)
    end)

    %{signing_key: signing_key, public_key: public_key, provider_fixture: fixture}
  end

  describe "base config wiring proof" do
    test "base Oban config validates and preserves every recovery cron worker" do
      oban_config = base_oban_config()

      assert :ok = Oban.Config.validate(oban_config)

      crontab = cron_entries(oban_config)
      workers = Enum.map(crontab, &elem(&1, 1))

      assert DunningSweeper in workers
      assert DetectExpiringCards in workers
      assert MeterEventsReconciler in workers
      assert MeteredRenewalReconciler in workers
      assert ReconciliationSweeper in workers
      assert ReconnectSweeper in workers

      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconciliationSweeper})) == 1
      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconnectSweeper})) == 1
    end

    test "base Oban config preserves host queues and adds the Apple repair queue" do
      queues = Keyword.fetch!(base_oban_config(), :queues)
      names = Keyword.keys(queues)

      assert :accrue_webhooks in names
      assert :accrue_mailers in names
      assert :accrue_pdf in names
      assert :accrue_dunning in names
      assert :accrue_meters in names
      assert :accrue_scheduled in names
      assert :accrue_entitlements in names
      assert Keyword.fetch!(queues, :accrue_entitlements) == 10
    end

    test "reconciliation keeps PostgreSQL ownership while Oban only coalesces work" do
      reconciliation = apple_source("reconciliation.ex")

      assert reconciliation =~ "PostgreSQL row locking, rather than Oban uniqueness"
      assert reconciliation =~ "The row lock, not Oban uniqueness"
      assert reconciliation =~ "Oban uniqueness"
    end

    test "reconcile worker reads the shared production client and admission configuration" do
      runtime = File.read!(Path.expand("../../config/runtime.exs", __DIR__))
      worker = apple_source("reconcile_worker.ex")

      assert worker =~ "Application.get_env(:accrue, :apple_reconciliation)"
      assert runtime =~ "config :accrue, :apple_reconciliation"
      assert runtime =~ "client:"
      assert runtime =~ "admission: ["
      assert runtime =~ "verifier_config: verifier_config"
      assert runtime =~ "verifier_version: \"apple-production-v1\""
      assert runtime =~ "config_version: System.fetch_env!(\"APPLE_VERIFIER_CONFIG_VERSION\")"
    end

    test "durable ingress wakeups drain through the scheduled existing recovery workers" do
      ingress_test =
        File.read!(Path.expand("../accrue_host_web/apple_notification_ingest_test.exs", __DIR__))

      sweeper = apple_source("reconciliation_sweeper.ex")
      worker = apple_source("reconcile_worker.ex")
      crontab = cron_entries(base_oban_config())

      assert ingress_test =~ "preserves exact bytes before durable intake and wakeup"
      assert ingress_test =~ "Repo.one!(ReconciliationWakeup)"
      assert sweeper =~ "queue: :accrue_entitlements"
      assert worker =~ "queue: :accrue_entitlements"
      assert Enum.count(crontab, &(&1 == {"*/15 * * * *", ReconciliationSweeper})) == 1
    end
  end

  describe "runtime test safety config" do
    test "test env keeps Oban queues/plugins disabled and manual testing mode" do
      runtime_oban_config = Application.fetch_env!(:accrue_host, Oban)

      assert false == Keyword.get(runtime_oban_config, :plugins)
      assert false == Keyword.get(runtime_oban_config, :queues)
      assert :manual == Keyword.get(runtime_oban_config, :testing)
    end
  end

  describe "durable stranded reconnect recovery" do
    test "sweeps an authenticated durable attempt through one signed replacement", ctx do
      account = account!("host-recovery")
      {device, device_key} = device!(account, "host-recovery-installation")
      project_grant!(account)

      opts = [
        repo: Repo,
        now: @now,
        authorize: fn _, _ -> true end,
        key_provider: SigningProvider,
        signing_key: ctx.signing_key,
        public_key: ctx.public_key,
        issuer: "accrue.host.offline",
        audience: "accrue-host-offline-client"
      ]

      request = reconnect_request!(account, device, device_key, opts, "host-stranded-reconnect")

      assert {:error, :admission_interrupted} =
               Offline.reconnect(
                 account,
                 request,
                 Keyword.put(opts, :after_admission, fn -> :interrupted end)
               )

      attempt = Repo.one!(ReconnectAttempt)
      assert attempt.state == :admitted
      assert 1 == Repo.aggregate(ReconnectWakeup, :count)
      reconnect_worker = Oban.Worker.to_string(ReconnectWorker)
      reconnect_wakeup_worker = Oban.Worker.to_string(ReconnectWakeupWorker)

      assert [] ==
               Repo.all(from(job in Oban.Job, where: job.worker == ^reconnect_worker))

      assert {1, _} =
               Repo.delete_all(
                 from(job in Oban.Job, where: job.worker == ^reconnect_wakeup_worker)
               )

      assert [] ==
               Repo.all(from(job in Oban.Job, where: job.worker == ^reconnect_wakeup_worker))

      assert :ok = ReconnectSweeper.perform(%Oban.Job{})
      [job] = Repo.all(from(job in Oban.Job, where: job.worker == ^reconnect_worker))
      assert %{"attempt_id" => attempt_id} = job.args
      assert attempt_id == attempt.id
      assert :ok = ReconnectWorker.perform(job)

      assert_receive {:due_sources_called, account_id, worker_now, fixture, [:provider_fixture]}
      assert account_id == account.id
      assert fixture == ctx.provider_fixture

      assert_receive {:refresh_called, ^account_id, ^fixture, ^worker_now, ^fixture,
                      [:provider_fixture]}

      refute_received :repair_enqueued

      assert %{state: :completed, attempt_count: 1, due_source_count: 1} =
               Repo.get!(ReconnectAttempt, attempt.id)

      assert 1 == Repo.aggregate(Issuance, :count)

      challenge = Repo.get!(Accrue.Entitlements.Offline.Challenge, request.challenge_id)
      proof = get_in(challenge.reconnect_outcome, ["proof"])
      assert is_binary(proof)

      assert {:ok, %{state: :fresh}} =
               Offline.verify(proof, %{
                 issuer: "accrue.host.offline",
                 audience: "accrue-host-offline-client",
                 account_subject: account.id,
                 installation_id: device.installation_id,
                 device_thumbprint: device.key_thumbprint,
                 now: DateTime.to_unix(DateTime.utc_now()),
                 public_keys: [ctx.public_key]
               })
    end
  end

  defp base_oban_config do
    config_path = Path.expand("../../config/config.exs", __DIR__)

    config_path
    |> Config.Reader.read!(env: :dev)
    |> get_in([:accrue_host, Oban])
  end

  defp cron_entries(oban_config) do
    oban_config
    |> Keyword.fetch!(:plugins)
    |> Enum.find_value(fn
      {Oban.Plugins.Cron, cron_opts} -> Keyword.get(cron_opts, :crontab, [])
      _ -> nil
    end)
    |> case do
      nil -> []
      crontab -> crontab
    end
  end

  defp apple_source(filename),
    do:
      File.read!(
        Path.expand("../../../../accrue/lib/accrue/entitlements/apple/#{filename}", __DIR__)
      )

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(Repo, "test", "host-#{suffix}")
    account
  end

  defp device!(account, installation_id) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    public_jwk = key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

    {:ok, device} =
      Repo.insert(
        Device.changeset(%Device{}, %{
          account_id: account.id,
          installation_id: installation_id,
          public_jwk: public_jwk,
          key_thumbprint: Device.thumbprint(public_jwk),
          state: :active,
          registered_at: @now,
          last_accepted_revision: 0
        })
      )

    {device, key}
  end

  defp project_grant!(account) do
    {:ok, observation} =
      Observation.insert_idempotently(Repo, %{
        account_id: account.id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "evt-host-recovery",
        provider_transaction_id: "txn-host-recovery",
        kind: "grant",
        provider_lineage_id: "lineage-host-recovery",
        provider_product_id: "price_pro",
        provider_order: 1,
        observed_at: DateTime.add(@now, -7200, :second),
        state: :qualified,
        retry_count: 0,
        metadata: %{},
        evidence_digest: String.duplicate("a", 64)
      })

    assert {:ok, _} = Projector.project(observation, logical_plan: :pro)
  end

  defp reconnect_request!(account, device, device_key, opts, idempotency_key) do
    assert {:ok, challenge} = Offline.reconnect_challenge(account, device.installation_id, opts)

    input =
      [
        "v1.59",
        "reconnect",
        account.id,
        device.installation_id,
        challenge.id,
        challenge.nonce,
        digest(idempotency_key)
      ]
      |> Enum.map_join(fn value ->
        <<byte_size(value)::unsigned-big-integer-size(32), value::binary>>
      end)

    {_, private_key} = JOSE.JWK.to_key(device_key)

    %Reconnect.Request{
      installation_id: device.installation_id,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature: :public_key.sign(input, :sha256, private_key),
      idempotency_key: idempotency_key
    }
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp test_key do
    __DIR__
    |> Path.join("../../../../accrue/priv/entitlements/v1.59-offline-test-key.jwk.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
