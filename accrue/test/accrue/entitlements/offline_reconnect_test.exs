defmodule Accrue.Entitlements.OfflineReconnectTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Entitlements.{Account, Device, Observation, Projector}
  alias Accrue.Entitlements.Offline

  alias Accrue.Entitlements.Offline.{
    Issuance,
    Issuer,
    Reconnect,
    ReconnectAttempt,
    ReconnectWakeup,
    SourceCoordinator
  }

  alias Accrue.TestRepo

  @now ~U[2026-08-04 01:00:00.000000Z]

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

  defmodule NoDueSources do
    @behaviour SourceCoordinator
    @impl true
    def due_sources(_, _, _), do: {:ok, []}
    @impl true
    def refresh(_, status, _, _), do: {:ok, status}
    @impl true
    def enqueue_repair(_, _, _, _), do: :ok
  end

  defmodule PendingRepairSource do
    @behaviour SourceCoordinator

    @impl true
    def due_sources(_, _, _) do
      {:ok,
       [
         %SourceCoordinator.SourceStatus{
           source: :stripe,
           environment: :production,
           due: true,
           state: :pending,
           retry_after: 60,
           next_action: :reconnect_required
         }
       ]}
    end

    @impl true
    def refresh(_, status, _, _), do: {:ok, status}

    @impl true
    def enqueue_repair(_, status, _, opts) do
      send(Keyword.fetch!(opts, :test_pid), {:repair_enqueued, status.source})
      Keyword.get(opts, :enqueue_result, :ok)
    end
  end

  defmodule UnavailableSource do
    @behaviour SourceCoordinator
    def due_sources(_, _, _), do: {:error, :provider_timeout}
    def refresh(_, status, _, _), do: {:ok, status}
    def enqueue_repair(_, _, _, _), do: :ok
  end

  setup do
    original = Application.get_env(:accrue, :entitlements)
    original_rails = Application.get_env(:accrue, :rails)
    original_default_rail = Application.get_env(:accrue, :default_rail)

    Application.put_env(:accrue, :entitlements,
      plans: [
        pro: [
          features: [:offline_study],
          quotas: [downloads: 3],
          products: [stripe: [production: ["price_pro"]]]
        ]
      ]
    )

    Application.put_env(:accrue, :rails,
      stripe: [environments: [:production], default_environment: :production]
    )

    Application.put_env(:accrue, :default_rail, :stripe)

    on_exit(fn ->
      if original,
        do: Application.put_env(:accrue, :entitlements, original),
        else: Application.delete_env(:accrue, :entitlements)

      if original_rails,
        do: Application.put_env(:accrue, :rails, original_rails),
        else: Application.delete_env(:accrue, :rails)

      if original_default_rail,
        do: Application.put_env(:accrue, :default_rail, original_default_rail),
        else: Application.delete_env(:accrue, :default_rail)
    end)

    signing_key = test_key()

    public_key =
      signing_key
      |> Map.take(["kty", "crv", "kid", "x", "y"])
      |> Map.merge(%{"alg" => "ES256", "use" => "sig"})

    account = account!("issuer")
    {device, device_key} = device!(account, "install-219-issuer")

    %{
      account: account,
      device: device,
      device_key: device_key,
      signing_key: signing_key,
      public_key: public_key
    }
  end

  @tag :issuance
  test "legacy issuer entry points reject caller assertions without an admission", ctx do
    project_grant!(ctx.account)

    request = %Issuer.Request{account_id: ctx.account.id, device_id: ctx.device.id, now: @now}

    assert {:error, :unauthorized} = Issuer.issue(ctx.account, request, issuer_opts(ctx))

    assert {:error, :unauthorized} =
             Issuer.issue_after_admission(ctx.account, request, issuer_opts(ctx))

    assert {:error, :unauthorized} =
             Issuer.issue_in_transaction(TestRepo, request, issuer_opts(ctx))

    assert [] == TestRepo.all(Issuance)
  end

  test "issuer re-locks a consumed PoP admission and rejects forged, cross-bound, and replayed use",
       ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "issuer-admission-capability")

    assert {:error, :admission_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_admission, fn -> :interrupted end)
             )

    challenge = TestRepo.get!(Accrue.Entitlements.Offline.Challenge, request.challenge_id)
    admission = Issuer.Admission.from_reconnect_challenge(challenge, ctx.device)

    issuer_request = %Issuer.Request{
      account_id: ctx.account.id,
      device_id: ctx.device.id,
      now: @now
    }

    forged = %{admission | idempotency_digest: digest("forged-idempotency")}

    assert {:error, :admission_invalid} =
             Issuer.issue_after_admission(ctx.account, issuer_request, forged, opts)

    {other_device, _} = device!(ctx.account, "install-219-cross-device")
    cross_device_request = %{issuer_request | device_id: other_device.id}

    assert {:error, :admission_invalid} =
             Issuer.issue_after_admission(ctx.account, cross_device_request, admission, opts)

    other_account = account!("issuer-cross-account")
    {other_account_device, _} = device!(other_account, "install-219-cross-account")

    cross_account_request = %{
      issuer_request
      | account_id: other_account.id,
        device_id: other_account_device.id
    }

    assert {:error, :admission_invalid} =
             Issuer.issue_after_admission(other_account, cross_account_request, admission, opts)

    assert {:ok, %{compact: compact, disposition: :allow}} =
             Issuer.issue_after_admission(ctx.account, issuer_request, admission, opts)

    assert is_binary(compact)

    assert {:error, :admission_invalid} =
             Issuer.issue_after_admission(ctx.account, issuer_request, admission, opts)

    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "a public reconnect challenge completes authenticated reconnect issuance", ctx do
    project_grant!(ctx.account)

    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]

    assert {:ok, %{purpose: :reconnect} = challenge} =
             Offline.reconnect_challenge(ctx.account, ctx.device.installation_id, opts)

    signature =
      reconnect_signing_input(
        ctx.account.id,
        ctx.device.installation_id,
        challenge.id,
        challenge.nonce,
        "reconnect-idempotency"
      )
      |> then(fn input ->
        {_, private_key} = JOSE.JWK.to_key(ctx.device_key)
        :public_key.sign(input, :sha256, private_key)
      end)

    request = %Reconnect.Request{
      installation_id: ctx.device.installation_id,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature: signature,
      idempotency_key: "reconnect-idempotency"
    }

    assert {:ok, %{disposition: :issued, proof: proof, due_source_count: 0}} =
             Offline.reconnect(ctx.account, request, opts)

    assert is_binary(proof)

    # A lost response is retried with exactly the authenticated request binding;
    # replay returns the durable result rather than consuming another challenge or
    # issuing a second proof.
    assert {:ok, %{disposition: :issued, proof: ^proof, due_source_count: 0}} =
             Offline.reconnect(ctx.account, request, opts)

    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "an admitted reconnect resumes after an interruption before source scheduling", ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-crash-after-admission")

    assert {:error, :admission_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_admission, fn -> :interrupted end)
             )

    challenge = TestRepo.get!(Accrue.Entitlements.Offline.Challenge, request.challenge_id)

    assert %{"state" => "admitted", "repair_outbox" => %{"state" => "scheduled"}} =
             challenge.reconnect_outcome

    assert {:ok, %{disposition: :issued, proof: proof}} =
             Offline.reconnect(ctx.account, request, opts)

    assert is_binary(proof)
    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "a host worker advances an admitted attempt without a client replay", ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-worker-after-crash")

    assert {:error, :admission_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_admission, fn -> :interrupted end)
             )

    attempt = TestRepo.one!(ReconnectAttempt)
    assert attempt.state == :admitted
    assert 1 == TestRepo.aggregate(ReconnectWakeup, :count)

    assert :ok =
             Reconnect.execute_attempt(attempt.id,
               offline_reconnect: opts,
               repo: TestRepo,
               now: @now
             )

    assert %{state: :completed} = TestRepo.get!(ReconnectAttempt, attempt.id)
    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "a committed issuance is replayable after response delivery is interrupted", ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-after-issuance-commit")

    assert {:error, :issuance_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_issuance_commit, fn -> :interrupted end)
             )

    assert 1 == TestRepo.aggregate(Issuance, :count)

    assert {:ok, %{disposition: :issued, proof: proof}} =
             Offline.reconnect(ctx.account, request, opts)

    assert is_binary(proof)
    assert 1 == TestRepo.aggregate(Issuance, :count)
    assert %{state: :completed} = TestRepo.one!(ReconnectAttempt)
  end

  test "a late worker cannot replace an inline issued replay outcome", ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-inline-worker-owner")

    assert {:ok, %{disposition: :issued, proof: proof}} =
             Offline.reconnect(ctx.account, request, opts)

    attempt = TestRepo.one!(ReconnectAttempt)

    assert {:error, :attempt_unavailable} =
             Reconnect.execute_attempt(attempt.id,
               offline_reconnect: opts,
               repo: TestRepo,
               now: @now
             )

    assert {:ok, %{disposition: :issued, proof: ^proof}} =
             Offline.reconnect(ctx.account, request, opts)

    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "the sweeper requeues an expired running lease and converges once", ctx do
    project_grant!(ctx.account)
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-expired-lease")

    assert {:error, :admission_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_admission, fn -> :interrupted end)
             )

    attempt = TestRepo.one!(ReconnectAttempt)

    {:ok, _} =
      TestRepo.update(
        ReconnectAttempt.changeset(attempt, %{
          state: :running,
          started_at: DateTime.add(@now, -301, :second)
        })
      )

    assert {:ok, 1} =
             Reconnect.enqueue_due(TestRepo,
               now: @now,
               lease_seconds: 300,
               insert_job: fn job ->
                 send(
                   self(),
                   {:requeued_attempt, Ecto.Changeset.get_change(job, :args)["attempt_id"]}
                 )

                 {:ok, job}
               end
             )

    assert_receive {:requeued_attempt, attempt_id}
    assert attempt_id == attempt.id

    assert :ok =
             Reconnect.execute_attempt(attempt.id,
               offline_reconnect: opts,
               repo: TestRepo,
               now: @now
             )

    assert %{state: :completed, attempt_count: 1} = TestRepo.get!(ReconnectAttempt, attempt.id)
    assert 1 == TestRepo.aggregate(Issuance, :count)
  end

  test "a failed wakeup job insertion rolls back wakeup draining", ctx do
    opts = issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]
    request = reconnect_request!(ctx, opts, "reconnect-wakeup-rollback")

    assert {:error, :admission_interrupted} =
             Offline.reconnect(
               ctx.account,
               request,
               Keyword.put(opts, :after_admission, fn -> :interrupted end)
             )

    assert {:error, {:job_insert_failed, :unavailable}} =
             Reconnect.drain_wakeups(TestRepo, insert_job: fn _ -> {:error, :unavailable} end)

    assert 1 == TestRepo.aggregate(ReconnectWakeup, :count)
  end

  test "wakeup insertion failure rolls back PoP consumption and durable rows", ctx do
    opts =
      issuer_opts(ctx) ++
        [
          source_coordinator: NoDueSources,
          authorize: fn _, _ -> true end,
          insert_wakeup_job: fn _ -> {:error, :unavailable} end
        ]

    request = reconnect_request!(ctx, opts, "reconnect-admission-enqueue-rollback")
    assert {:error, :unavailable} = Offline.reconnect(ctx.account, request, opts)

    assert %{consumed_at: nil} =
             TestRepo.get!(Accrue.Entitlements.Offline.Challenge, request.challenge_id)

    assert 0 == TestRepo.aggregate(ReconnectAttempt, :count)
    assert 0 == TestRepo.aggregate(ReconnectWakeup, :count)
  end

  test "a failed durable repair enqueue becomes an explicit terminal escalation", ctx do
    opts =
      issuer_opts(ctx) ++
        [
          source_coordinator: PendingRepairSource,
          authorize: fn _, _ -> true end,
          test_pid: self(),
          enqueue_result: {:error, :oban_unavailable}
        ]

    request = reconnect_request!(ctx, opts, "reconnect-enqueue-failure")

    assert {:ok, %{disposition: :needs_repair, reason: :repair_enqueue_failed, proof: nil}} =
             Offline.reconnect(ctx.account, request, opts)

    assert_receive {:repair_enqueued, :stripe}

    challenge = TestRepo.get!(Accrue.Entitlements.Offline.Challenge, request.challenge_id)

    assert %{
             "state" => "final",
             "repair_outbox" => %{
               "state" => "repair_escalated",
               "reason" => "repair_enqueue_failed"
             }
           } = challenge.reconnect_outcome

    assert {:ok, %{disposition: :needs_repair}} = Offline.reconnect(ctx.account, request, opts)
    refute_receive {:repair_enqueued, :stripe}
  end

  test "reconnect telemetry is bounded and excludes request or proof material", ctx do
    handler_id = "offline-reconnect-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        [:accrue, :entitlements, :offline, :reconnect],
        fn _, _, metadata, pid ->
          send(pid, {:reconnect_telemetry, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    project_grant!(ctx.account)

    issued_opts =
      issuer_opts(ctx) ++ [source_coordinator: NoDueSources, authorize: fn _, _ -> true end]

    issued_request = reconnect_request!(ctx, issued_opts, "telemetry-issued")

    assert {:ok, %{disposition: :issued}} =
             Offline.reconnect(ctx.account, issued_request, issued_opts)

    pending_opts =
      issuer_opts(ctx) ++
        [
          source_coordinator: PendingRepairSource,
          authorize: fn _, _ -> true end,
          test_pid: self()
        ]

    pending_request = reconnect_request!(ctx, pending_opts, "telemetry-pending")

    assert {:ok, %{disposition: :pending}} =
             Offline.reconnect(ctx.account, pending_request, pending_opts)

    assert_receive {:repair_enqueued, :stripe}

    repair_opts = Keyword.put(pending_opts, :enqueue_result, {:error, :unavailable})
    repair_request = reconnect_request!(ctx, repair_opts, "telemetry-repair")

    assert {:ok, %{disposition: :needs_repair}} =
             Offline.reconnect(ctx.account, repair_request, repair_opts)

    assert_receive {:repair_enqueued, :stripe}

    invalid_request = %{issued_request | nonce_signature: <<>>}

    assert {:error, :invalid_request} =
             Offline.reconnect(ctx.account, invalid_request, issued_opts)

    for expected <- [:issued, :pending, :needs_repair, :rejected] do
      assert_receive {:reconnect_telemetry,
                      %{
                        action: :reconnect,
                        disposition: ^expected,
                        correlation_hash: correlation_hash
                      }}

      assert is_binary(correlation_hash) or is_nil(correlation_hash)
    end

    refute_receive {:reconnect_telemetry, %{proof: _}}
  end

  test "telemetry uses monotonic latency, persisted queue age, and exact failure reasons", ctx do
    handler_id = "offline-reconnect-clock-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach(
        handler_id,
        [:accrue, :entitlements, :offline, :reconnect],
        fn _, measures, metadata, pid -> send(pid, {:clock_telemetry, measures, metadata}) end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    opts =
      issuer_opts(ctx) ++ [source_coordinator: UnavailableSource, authorize: fn _, _ -> true end]

    request = reconnect_request!(ctx, opts, "telemetry-source-unavailable")

    assert {:ok, %{disposition: :needs_repair, reason: :source_unavailable}} =
             Offline.reconnect(ctx.account, request, opts)

    assert_receive {:clock_telemetry, %{latency_ms: latency, queue_age_ms: 0}, metadata}
    assert is_integer(latency) and latency >= 0 and latency < 1_000
    assert metadata.reason == :source_unavailable
    refute contains_secret?(metadata)
  end

  test "an empty due schedule is a resolved source set" do
    assert :ok = SourceCoordinator.validate([])
  end

  @tag :issuance
  test "issued-proof retirement validation is explicit and preserves required keys", ctx do
    old_key = ctx.public_key
    next_key = Map.put(old_key, "kid", "accrue-v1.59-offline-next")
    expires_at = DateTime.add(@now, 60, :second)

    {:ok, _issuance} =
      TestRepo.insert(
        Issuance.changeset(%Issuance{}, %{
          account_id: ctx.account.id,
          device_id: ctx.device.id,
          token_id_hash: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false),
          kid: old_key["kid"],
          revision: 1,
          disposition: :allow,
          issued_at: @now,
          fresh_until: @now,
          expires_at: expires_at
        })
      )

    assert {:error, :config_invalid} =
             Offline.verification_keys_with_issued_retention(
               keys: [next_key],
               repo: TestRepo,
               now: @now
             )

    assert {:ok, %{"keys" => keys}} =
             Offline.verification_keys_with_issued_retention(
               keys: [old_key, next_key],
               repo: TestRepo,
               now: @now
             )

    assert Enum.map(keys, & &1["kid"]) == Enum.sort([old_key["kid"], next_key["kid"]])

    assert {:ok, %{"keys" => [^next_key]}} =
             Offline.verification_keys_with_issued_retention(
               keys: [next_key],
               repo: TestRepo,
               now: DateTime.add(expires_at, 86_400, :second)
             )
  end

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(TestRepo, "test", "owner-219-#{suffix}")
    account
  end

  defp device!(account, installation_id) do
    key = JOSE.JWK.generate_key({:ec, "P-256"})
    public_jwk = key |> JOSE.JWK.to_public_map() |> elem(1) |> Map.take(["kty", "crv", "x", "y"])

    {:ok, device} =
      TestRepo.insert(
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

  defp issuer_opts(ctx) do
    [
      repo: TestRepo,
      key_provider: SigningProvider,
      signing_key: ctx.signing_key,
      public_key: ctx.public_key,
      issuer: "accrue.test.offline",
      audience: "accrue-offline-client",
      now: @now
    ]
  end

  defp reconnect_request!(ctx, opts, idempotency_key) do
    assert {:ok, %{purpose: :reconnect} = challenge} =
             Offline.reconnect_challenge(ctx.account, ctx.device.installation_id, opts)

    signature =
      reconnect_signing_input(
        ctx.account.id,
        ctx.device.installation_id,
        challenge.id,
        challenge.nonce,
        idempotency_key
      )
      |> then(fn input ->
        {_, private_key} = JOSE.JWK.to_key(ctx.device_key)
        :public_key.sign(input, :sha256, private_key)
      end)

    %Reconnect.Request{
      installation_id: ctx.device.installation_id,
      challenge_id: challenge.id,
      nonce: challenge.nonce,
      nonce_signature: signature,
      idempotency_key: idempotency_key
    }
  end

  defp reconnect_signing_input(account, installation, challenge, nonce, key) do
    ["v1.59", "reconnect", account, installation, challenge, nonce, digest(key)]
    |> Enum.map_join(fn value ->
      <<byte_size(value)::unsigned-big-integer-size(32), value::binary>>
    end)
  end

  defp digest(value), do: :crypto.hash(:sha256, value) |> Base.url_encode64(padding: false)

  defp contains_secret?(value) when is_map(value),
    do:
      Enum.any?(value, fn {k, v} ->
        to_string(k) in [
          "proof",
          "account_id",
          "device_id",
          "nonce",
          "nonce_signature",
          "public_jwk",
          "evidence"
        ] or contains_secret?(v)
      end)

  defp contains_secret?(value) when is_list(value), do: Enum.any?(value, &contains_secret?/1)
  defp contains_secret?(_), do: false

  defp project_grant!(account) do
    {:ok, observation} =
      Observation.insert_idempotently(TestRepo, %{
        account_id: account.id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "evt-219-issuer",
        provider_transaction_id: "txn-219-issuer",
        kind: "grant",
        provider_lineage_id: "lineage-219-issuer",
        provider_product_id: "price_pro",
        provider_order: 1,
        # Projection evaluates the committed snapshot at the database/test clock;
        # keep the fixture effective before that clock while issuing at @now.
        observed_at: DateTime.add(@now, -2 * 60 * 60, :second),
        state: :qualified,
        retry_count: 0,
        metadata: %{},
        evidence_digest: String.duplicate("a", 64)
      })

    assert {:ok, _} = Projector.project(observation, logical_plan: :pro)
  end

  defp test_key do
    __DIR__
    |> Path.join("../../../priv/entitlements/v1.59-offline-test-key.jwk.json")
    |> File.read!()
    |> Jason.decode!()
  end
end
