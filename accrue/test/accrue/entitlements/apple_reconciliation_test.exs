defmodule Accrue.Entitlements.AppleReconciliationTest do
  use Accrue.RepoCase, async: false
  use Oban.Testing, repo: Accrue.TestRepo

  alias Accrue.Entitlements.{Account, Grant, Observation, Projector}
  alias Accrue.Entitlements.Apple.{
    Client,
    Lineage,
    Reconciliation,
    ReconciliationSweeper,
    ReconcileWorker
  }
  alias Accrue.Entitlements.Apple.Client.Production
  alias Accrue.Entitlements.Apple.Reconciliation.Checkpoint
  alias Accrue.Entitlements.Apple.ReconciliationWakeupWorker

  defmodule ConfiguredClient do
    @behaviour Client
    defstruct []

    def subscription_statuses(_, lineage, environment),
      do: {:ok, [%{lineage: lineage, environment: environment}]}

    def transaction_history(_, _, _, _, _), do: {:ok, %{signed_transactions: [], has_more: false}}
    def notification_history(_, _, _), do: {:ok, %{notifications: []}}
    def set_app_account_token(_, _, _, _), do: :ok
  end

  defmodule ReconciliationVerifier do
    @behaviour Accrue.Entitlements.Apple.Verifier
    def verify_notification(_, _), do: {:error, :invalid_payload}
    def verify_renewal(_, _), do: {:error, :invalid_payload}
    def verify_transaction("invalid", _), do: {:error, :invalid_signature}

    def verify_transaction(transaction, %{account_id: account_id, original_id: original_id}),
      do:
        {:ok,
         %{
           "originalTransactionId" => original_id,
           "transactionId" => transaction,
           "productId" => "product_pro",
           "appAccountToken" => account_id,
           "signedDate" => 1_754_000_000_000,
           "expiresDate" => 1_800_000_000_000
         }}
  end

  defmodule ResumeClient do
    @behaviour Client
    defstruct [:test_pid]

    def subscription_statuses(_, _, _), do: {:ok, []}

    def transaction_history(%__MODULE__{test_pid: test_pid}, _, _, revision, _) do
      send(test_pid, {:resumed_from, revision})
      {:ok, %{signed_transactions: [], revision: "complete", has_more: false}}
    end

    def notification_history(_, _, _), do: {:ok, %{notifications: []}}
    def set_app_account_token(_, _, _, _), do: :ok
  end

  @tag :status
  test "the deterministic client preserves status authority and ascending history scripts" do
    fake =
      Client.Fake.new(
        statuses: [{:ok, [%{transaction: "status-1"}]}],
        history: [
          {:ok, %{signed_transactions: [], revision: "r1", has_more: true}},
          {:ok, %{signed_transactions: [], revision: "r2", has_more: false}}
        ]
      )

    assert {:ok, [%{transaction: "status-1"}]} =
             Client.subscription_statuses(fake, "lineage", :production)

    assert {:ok, %{revision: "r1", has_more: true}} =
             Client.transaction_history(fake, "lineage", %{sort: :ascending}, nil, :production)

    assert {:ok, %{revision: "r2", has_more: false}} =
             Client.transaction_history(fake, "lineage", %{sort: :ascending}, "r1", :production)
  end

  test "a configured non-Fake client dispatches through the client behaviour" do
    assert {:ok, [%{lineage: "configured", environment: :sandbox}]} =
             Client.subscription_statuses(%ConfiguredClient{}, "configured", :sandbox)
  end

  test "production adapter uses the environment-specific Apple endpoint for each request" do
    test_pid = self()

    client =
      Production.new(
        authorization: "test-token",
        transport: fn :get, {url, _headers}, _options, _body_format ->
          send(test_pid, {:apple_url, to_string(url)})
          {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, [], ~s({"data":[]})}}
        end
      )

    assert {:ok, []} = Client.subscription_statuses(client, "sandbox lineage", :sandbox)

    assert_receive {:apple_url,
                    "https://api.storekit-sandbox.itunes.apple.com/inApps/v1/subscriptions/sandbox%20lineage"}

    assert {:ok, %{signed_transactions: [], has_more: false}} =
             Client.transaction_history(
               client,
               "sandbox lineage",
               %{sort: :ascending},
               nil,
               :sandbox
             )

    assert_receive {:apple_url,
                    "https://api.storekit-sandbox.itunes.apple.com/inApps/v2/history/sandbox%20lineage?sort=ascending"}
  end

  test "production adapter safely bounds numeric and malformed Retry-After headers" do
    for {header, expected} <- [
          {"999999", 21_600},
          {"Wed, 21 Oct 2015 07:28:00 GMT", 60},
          {"invalid", 60}
        ] do
      client =
        Production.new(
          authorization: "test-token",
          transport: fn :get, _request, _options, _body_format ->
            {:ok, {{~c"HTTP/1.1", 429, ~c"Too Many Requests"}, [{~c"retry-after", header}], ""}}
          end
        )

      assert {:error, {:rate_limited, ^expected}} =
               Client.subscription_statuses(client, "lineage", :production)
    end
  end

  @tag :status
  test "cadence is bounded and preserves a known provider bound during an outage" do
    now = ~U[2026-08-03 12:00:00Z]

    assert Reconciliation.due(%{next_due_at: nil}, now)
    refute Reconciliation.due(%{next_due_at: DateTime.add(now, 1, :second)}, now)

    assert Reconciliation.retry_after({:error, {:rate_limited, 120}}, 1, now) ==
             DateTime.add(now, 120, :second)

    assert Reconciliation.retry_after({:error, :provider_unavailable}, 20, now) ==
             DateTime.add(now, 21_600, :second)
  end

  @tag :status
  test "filter fingerprints are stable and reject drift" do
    filters = %{product_types: ["AUTO_RENEWABLE"], sort: :ascending}

    assert Reconciliation.query_fingerprint(filters) ==
             Reconciliation.query_fingerprint(%{
               sort: :ascending,
               product_types: ["AUTO_RENEWABLE"]
             })

    refute Reconciliation.query_fingerprint(filters) ==
             Reconciliation.query_fingerprint(%{
               sort: :descending,
               product_types: ["AUTO_RENEWABLE"]
             })
  end

  test "history advances the completed revision only after the final ascending page" do
    fake =
      Client.Fake.new(
        statuses: [{:ok, []}],
        history: [
          {:ok, %{signed_transactions: [], revision: "r1", has_more: true}},
          {:ok, %{signed_transactions: [], revision: "r2", has_more: false}}
        ]
      )

    lineage_id = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-history").id
    now = ~U[2026-08-03 12:00:00Z]
    args = %{lineage_id: lineage_id, environment: :production}

    assert {:ok, %Checkpoint{pending_revision: "r1", completed_revision: nil, page_count: 1}} =
             Reconciliation.run(args,
               repo: Accrue.TestRepo,
               client: fake,
               now: now,
               admission: [],
               continue: fn _ -> {:ok, :continued} end
             )

    assert {:ok, %Checkpoint{pending_revision: nil, completed_revision: "r2", page_count: 0}} =
             Reconciliation.run(args,
               repo: Accrue.TestRepo,
               client: fake,
               now: now,
               admission: []
             )
  end

  test "a durable wakeup drains through configured admission across every history page" do
    account = account!("apple-reconciliation-worker")
    lineage = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-worker")
    {:claimed, lineage} = Lineage.claim(Accrue.TestRepo, lineage, account.id, account.id)

    fake =
      Client.Fake.new(
        statuses: [{:ok, []}],
        history: [
          {:ok, %{signed_transactions: ["page-1"], revision: "r1", has_more: true}},
          {:ok, %{signed_transactions: ["page-2"], revision: "r2", has_more: false}}
        ]
      )

    previous = Application.get_env(:accrue, :apple_reconciliation)

    Application.put_env(:accrue, :apple_reconciliation,
      client: fake,
      admission: admission(account, lineage)
    )

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:accrue, :apple_reconciliation),
        else: Application.put_env(:accrue, :apple_reconciliation, previous)
    end)

    assert {:ok, _} =
             Reconciliation.enqueue(lineage.id, :production, :host_requested,
               repo: Accrue.TestRepo
             )

    assert :ok = perform_job(ReconciliationWakeupWorker, %{})

    args = %{
      "lineage_id" => lineage.id,
      "environment" => "production",
      "reason" => "host_requested"
    }

    assert :ok = perform_job(ReconcileWorker, args)

    assert :ok = perform_job(ReconcileWorker, args)
    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 2
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 2

    assert %Checkpoint{
             pending_revision: nil,
             completed_revision: "r2",
             page_count: 0,
             run_state: :idle
           } =
             Accrue.TestRepo.get_by!(Checkpoint, lineage_id: lineage.id, environment: :production)
  end

  test "a due checkpoint repairs Apple state after a missed notification" do
    account = account!("apple-scheduled-repair")
    lineage = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-scheduled-repair")
    {:claimed, lineage} = Lineage.claim(Accrue.TestRepo, lineage, account.id, account.id)
    now = ~U[2026-08-03 12:00:00Z]

    Accrue.TestRepo.insert!(
      Checkpoint.changeset(%Checkpoint{}, %{
        lineage_id: lineage.id,
        environment: :production,
        run_state: :idle,
        page_count: 0,
        page_budget: 25,
        attempts: 0,
        next_due_at: DateTime.add(now, -1, :second)
      })
    )

    previous = Application.get_env(:accrue, :apple_reconciliation)

    Application.put_env(:accrue, :apple_reconciliation,
      client:
        Client.Fake.new(
          statuses: [{:ok, []}],
          history: [{:ok, %{signed_transactions: ["scheduled-repair"], has_more: false}}]
        ),
      admission: admission(account, lineage)
    )

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:accrue, :apple_reconciliation),
        else: Application.put_env(:accrue, :apple_reconciliation, previous)
    end)

    assert {:ok, 1} = ReconciliationSweeper.sweep(Accrue.TestRepo, now: now)

    [job] =
      Accrue.TestRepo.all(
        from(job in Oban.Job,
          where:
            job.worker == ^worker_name(ReconcileWorker) and job.args["reason"] == "scheduled_due"
        )
      )

    assert job.args == %{
             "environment" => "production",
             "lineage_id" => lineage.id,
             "reason" => "scheduled_due"
           }

    assert %Checkpoint{run_state: :running, next_due_at: nil} =
             Accrue.TestRepo.get_by!(Checkpoint, lineage_id: lineage.id, environment: :production)

    assert :ok = perform_job(ReconcileWorker, job.args)
    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1

    assert %Checkpoint{run_state: :idle, next_due_at: %DateTime{}} =
             Accrue.TestRepo.get_by!(Checkpoint, lineage_id: lineage.id, environment: :production)
  end

  test "invalid signed history is rejected before it writes an observation or grant" do
    account = account!("invalid-apple-history")
    lineage = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-invalid-history")
    {:claimed, lineage} = Lineage.claim(Accrue.TestRepo, lineage, account.id, account.id)

    client =
      Client.Fake.new(
        statuses: [{:ok, []}],
        history: [{:ok, %{signed_transactions: ["invalid"], has_more: false}}]
      )

    assert {:ok, %Checkpoint{run_state: :retrying}} =
             Reconciliation.run(%{lineage_id: lineage.id, environment: :production},
               repo: Accrue.TestRepo,
               client: client,
               admission: admission(account, lineage)
             )

    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 0
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 0
  end

  test "a failed reconciliation persists and dispatches a scheduled retry that resumes its cursor" do
    lineage = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-retry")
    now = ~U[2026-08-03 12:00:00Z]

    assert {:ok, %Checkpoint{run_state: :retrying, retry_after_at: retry_at}} =
             Reconciliation.run(%{lineage_id: lineage.id, environment: :production},
               repo: Accrue.TestRepo,
               client: Client.Fake.new(statuses: [{:error, :provider_unavailable}]),
               now: now,
               admission: []
             )

    [retry_job] =
      Accrue.TestRepo.all(
        from(job in Oban.Job,
          where: job.worker == ^worker_name(ReconcileWorker) and job.args["reason"] == "retry"
        )
      )

    assert retry_job.scheduled_at == retry_at

    checkpoint =
      Accrue.TestRepo.get_by!(Checkpoint, lineage_id: lineage.id, environment: :production)
      |> Ecto.Changeset.change(pending_revision: "resume-cursor")
      |> Accrue.TestRepo.update!()

    previous = Application.get_env(:accrue, :apple_reconciliation)

    Application.put_env(:accrue, :apple_reconciliation,
      client: %ResumeClient{test_pid: self()},
      admission: []
    )

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:accrue, :apple_reconciliation),
        else: Application.put_env(:accrue, :apple_reconciliation, previous)
    end)

    assert :ok = perform_job(ReconcileWorker, retry_job.args)
    assert_receive {:resumed_from, "resume-cursor"}

    checkpoint_id = checkpoint.id

    assert %Checkpoint{id: ^checkpoint_id, run_state: :idle, pending_revision: nil} =
             Accrue.TestRepo.get!(Checkpoint, checkpoint.id)
  end

  test "current status is admitted when transaction history is empty" do
    account = account!("apple-status-authority")
    lineage = Lineage.lock_or_insert(Accrue.TestRepo, :production, "orig-status-authority")
    {:claimed, lineage} = Lineage.claim(Accrue.TestRepo, lineage, account.id, account.id)

    client =
      Client.Fake.new(
        statuses: [{:ok, [%{"signedTransactionInfo" => "status-only"}]}],
        history: [{:ok, %{signed_transactions: [], has_more: false}}]
      )

    assert {:ok, %Checkpoint{run_state: :idle}} =
             Reconciliation.run(%{lineage_id: lineage.id, environment: :production},
               repo: Accrue.TestRepo,
               client: client,
               admission: admission(account, lineage)
             )

    assert Accrue.TestRepo.aggregate(Observation, :count, :id) == 1
    assert Accrue.TestRepo.aggregate(Grant, :count, :id) == 1
  end

  test "complete Apple order keeps delayed positive evidence behind terminal evidence" do
    account = account!("apple-order-terminal")
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]

    active =
      apple_observation!(account,
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("a", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(active)

    refund =
      apple_observation!(account,
        lifecycle: :refunded,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("b", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(refund)

    delayed_active =
      apple_observation!(account,
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("a", 64)
      )

    assert {:noop, :stale} = Projector.project(delayed_active)
    assert [] == current_grants(account.id)
  end

  test "Apple ordering is deterministic per scope while Stripe retains numeric ordering" do
    account = account!("apple-order-scopes")
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]

    production =
      apple_observation!(account,
        environment: :production,
        lineage: "lineage-production",
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("c", 64)
      )

    sandbox =
      apple_observation!(account,
        environment: :sandbox,
        lineage: "lineage-sandbox",
        lifecycle: :active,
        signed_at: signed_at,
        effective_at: effective_at,
        digest: String.duplicate("d", 64)
      )

    assert {:noop, :no_material_change} = Projector.project(production)
    assert {:noop, :no_material_change} = Projector.project(sandbox)

    stripe_low = stripe_observation!(account, 1)
    stripe_high = stripe_observation!(account, 2)
    assert {:noop, :no_material_change} = Projector.project(stripe_low)
    assert {:noop, :no_material_change} = Projector.project(stripe_high)
    assert {:noop, :stale} = Projector.project(stripe_low)
  end

  test "lifecycle normalization preserves only verified provider bounds" do
    signed_at = ~U[2026-08-03 12:00:00.000000Z]
    effective_at = ~U[2026-08-03 13:00:00.000000Z]
    expiry = DateTime.add(effective_at, 30, :day)
    grace_expiry = DateTime.add(expiry, 3, :day)

    assert %{kind: "active", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :active,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "renewal_disabled", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :renewal_disabled,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "grace", expires_at: ^grace_expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :grace,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               grace_expires_at: grace_expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "grace", expires_at: nil} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :grace,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    assert %{kind: "billing_retry", expires_at: ^expiry} =
             Reconciliation.normalize_lifecycle(%{
               lifecycle: :billing_retry,
               signed_at: signed_at,
               effective_at: effective_at,
               expires_at: grace_expiry,
               last_verified_expires_at: expiry,
               evidence_digest: String.duplicate("f", 64)
             })

    for lifecycle <- [:expired, :refunded, :revoked] do
      assert %{kind: kind, expires_at: nil} =
               Reconciliation.normalize_lifecycle(%{
                 lifecycle: lifecycle,
                 signed_at: signed_at,
                 effective_at: effective_at,
                 expires_at: expiry,
                 evidence_digest: String.duplicate("f", 64)
               })

      assert kind == Atom.to_string(lifecycle)
    end
  end

  defp admission(account, lineage) do
    [
      verifier: ReconciliationVerifier,
      verifier_config: %{account_id: account.id, original_id: lineage.original_transaction_id},
      product_map: %{"product_pro" => :pro},
      verifier_version: "test-v1",
      config_version: "test-v1"
    ]
  end

  defp account!(owner_id) do
    {:ok, account} = Account.fetch_or_create(Accrue.TestRepo, "test", owner_id)
    account
  end

  defp apple_observation!(account, opts) do
    lifecycle = Keyword.fetch!(opts, :lifecycle)
    environment = Keyword.get(opts, :environment, :production)
    lineage = Keyword.get(opts, :lineage, "lineage-apple")
    signed_at = Keyword.fetch!(opts, :signed_at)
    effective_at = Keyword.fetch!(opts, :effective_at)
    digest = Keyword.fetch!(opts, :digest)

    normalized =
      Reconciliation.normalize_lifecycle(%{
        lifecycle: lifecycle,
        signed_at: signed_at,
        effective_at: effective_at,
        expires_at: DateTime.add(effective_at, 30, :day),
        evidence_digest: digest
      })

    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: :apple,
        environment: environment,
        provider_event_id: "apple-#{environment}-#{lineage}-#{lifecycle}-#{digest}",
        provider_transaction_id: "transaction-#{digest}",
        kind: normalized.kind,
        provider_lineage_id: lineage,
        provider_product_id: "product_pro",
        provider_order: 1,
        provider_order_key: normalized.provider_order_key,
        observed_at: effective_at,
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "apple_server"},
        evidence_digest: digest
      })

    observation
  end

  defp stripe_observation!(account, order) do
    {:ok, observation} =
      Observation.insert_idempotently(Accrue.TestRepo, %{
        account_id: account.id,
        rail: :stripe,
        environment: :production,
        provider_event_id: "stripe-#{order}",
        provider_transaction_id: "stripe-transaction-#{order}",
        kind: "grant",
        provider_lineage_id: "stripe-lineage",
        provider_product_id: "price_pro",
        provider_order: order,
        observed_at: ~U[2026-08-03 12:00:00.000000Z],
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "fake_observer"},
        evidence_digest: String.duplicate("e", 64)
      })

    observation
  end

  defp current_grants(account_id) do
    Accrue.TestRepo.all(
      from(grant in Grant, where: grant.account_id == ^account_id and is_nil(grant.superseded_at))
    )
  end

  defp worker_name(worker), do: worker |> Atom.to_string() |> String.trim_leading("Elixir.")
end
