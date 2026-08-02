defmodule Accrue.Entitlements.PersistenceTest do
  use Accrue.RepoCase

  alias Accrue.Entitlements.Account
  alias Accrue.Entitlements.Device
  alias Accrue.Entitlements.Grant
  alias Accrue.Entitlements.Observation
  alias Accrue.TestRepo

  test "fetch_or_create persists one opaque UUID account per owner at revision zero" do
    attrs = %{owner_type: "user", owner_id: "owner-216-tracer"}

    assert {:ok, first} = Account.fetch_or_create(TestRepo, attrs.owner_type, attrs.owner_id)
    assert {:ok, second} = Account.fetch_or_create(TestRepo, attrs.owner_type, attrs.owner_id)

    assert first.id == second.id
    assert Ecto.UUID.cast(first.id) == {:ok, first.id}
    assert first.revision == 0
    assert TestRepo.aggregate(Account, :count, :id) == 1

    reloaded = TestRepo.get!(Account, first.id)
    assert reloaded.owner_type == attrs.owner_type
    assert reloaded.owner_id == attrs.owner_id
    assert reloaded.revision == 0
    assert %DateTime{} = reloaded.inserted_at
    assert %DateTime{} = reloaded.updated_at
  end

  @tag :observation
  test "event observations are idempotent and keep only bounded provenance" do
    account = account!("observation-event")
    attrs = observation_attrs(account.id, %{provider_event_id: "evt-216-observation"})

    assert {:ok, first} = Observation.insert_idempotently(TestRepo, attrs)
    assert {:ok, second} = Observation.insert_idempotently(TestRepo, attrs)

    assert first.id == second.id
    assert TestRepo.aggregate(Observation, :count, :id) == 1
    assert first.metadata == %{"source" => "apple_server"}
    assert first.evidence_digest == String.duplicate("a", 64)
  end

  @tag :observation
  test "observations scope identities by rail and environment and enforce paired evidence fields" do
    account = account!("observation-scope")
    attrs = observation_attrs(account.id, %{provider_event_id: "shared-event"})

    assert {:ok, _} = Observation.insert_idempotently(TestRepo, attrs)

    assert {:ok, _} =
             Observation.insert_idempotently(
               TestRepo,
               Map.merge(attrs, %{rail: :stripe, environment: :sandbox})
             )

    assert TestRepo.aggregate(Observation, :count, :id) == 2

    refute Observation.ingest_changeset(
             Map.drop(attrs, [:provider_event_id, :provider_transaction_id])
           ).valid?

    refute Observation.ingest_changeset(Map.put(attrs, :evidence_ref, "opaque://evidence/1")).valid?

    refute Observation.ingest_changeset(
             Map.put(attrs, :evidence_expires_at, ~U[2026-08-03 00:00:00.000000Z])
           ).valid?

    assert Observation.ingest_changeset(
             Map.merge(attrs, %{
               evidence_ref: "opaque://evidence/1",
               evidence_expires_at: ~U[2026-08-03 00:00:00.000000Z]
             })
           ).valid?
  end

  @tag :observation
  test "observation ingestion rejects raw evidence, PII, nested metadata, and invalid ordering" do
    account = account!("observation-invalid")
    attrs = observation_attrs(account.id)

    for invalid <- [
          %{metadata: %{"receipt" => "base64-payload"}},
          %{metadata: %{"source" => %{"nested" => "payload"}}},
          %{metadata: %{"source" => "eyJhbGciOiJIUzI1NiJ9.payload.signature"}},
          %{rail: :unknown},
          %{environment: :offline},
          %{state: :unknown},
          %{retry_count: -1},
          %{provider_order: -1},
          %{evidence_digest: "short"}
        ] do
      refute Observation.ingest_changeset(Map.merge(attrs, invalid)).valid?
    end
  end

  @tag :observation
  test "blank identities normalize before idempotent fallback selection" do
    account = account!("observation-blank-identity")

    attrs =
      observation_attrs(account.id, %{
        provider_event_id: "   ",
        provider_transaction_id: "transaction-blank-fallback"
      })

    assert {:ok, first} = Observation.insert_idempotently(TestRepo, attrs)
    assert {:ok, second} = Observation.insert_idempotently(TestRepo, attrs)
    assert first.id == second.id
    assert is_nil(first.provider_event_id)
    assert first.provider_transaction_id == "transaction-blank-fallback"

    event_attrs =
      observation_attrs(account.id, %{
        provider_event_id: "event-blank-fallback",
        provider_transaction_id: " \t "
      })

    assert {:ok, event_observation} = Observation.insert_idempotently(TestRepo, event_attrs)
    assert event_observation.provider_event_id == "event-blank-fallback"
    assert is_nil(event_observation.provider_transaction_id)

    refute Observation.ingest_changeset(
             observation_attrs(account.id, %{provider_event_id: " ", provider_transaction_id: "\n"})
           ).valid?
  end

  @tag :observation
  test "observations accept only bounded opaque evidence locators" do
    account = account!("observation-evidence-locator")
    expiry = ~U[2026-08-03 00:00:00.000000Z]

    assert Observation.ingest_changeset(
             observation_attrs(account.id, %{
               evidence_ref: "opaque://evidence/1",
               evidence_expires_at: expiry
             })
           ).valid?

    for reference <- [
          "opaque://",
          "https://provider.example/receipt",
          "{\"receipt\":\"raw\"}",
          "<receipt>raw</receipt>",
          "eyJhbGciOiJIUzI1NiJ9.payload.signature",
          String.duplicate("a", 256)
        ] do
      refute Observation.ingest_changeset(
               observation_attrs(account.id, %{evidence_ref: reference, evidence_expires_at: expiry})
             ).valid?
    end
  end

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(TestRepo, "user", "owner-#{suffix}")
    account
  end

  @tag :device
  test "device registrations are account-scoped and retain revoked history" do
    account = account!("device-one")
    other_account = account!("device-two")
    attrs = device_attrs(account.id)

    assert {:ok, first} = TestRepo.insert(Device.changeset(%Device{}, attrs))
    assert {:error, _} = TestRepo.insert(Device.changeset(%Device{}, attrs))

    assert {:ok, _} =
             TestRepo.insert(Device.changeset(%Device{}, %{attrs | account_id: other_account.id}))

    assert {:ok, revoked} =
             first
             |> Device.changeset(%{state: :revoked, revoked_at: ~U[2026-08-02 16:00:00.000000Z]})
             |> TestRepo.update()

    assert {:ok, replacement} = TestRepo.insert(Device.changeset(%Device{}, attrs))
    assert revoked.id != replacement.id
  end

  @tag :device
  test "device registrations reject empty identity and invalid revision or lifecycle" do
    account = account!("device-invalid")
    attrs = device_attrs(account.id)

    for invalid <- [
          %{installation_id: ""},
          %{key_thumbprint: nil},
          %{state: :unknown},
          %{last_accepted_revision: -1},
          %{revoked_at: ~U[2026-08-02 16:00:00.000000Z]}
        ] do
      refute Device.changeset(%Device{}, Map.merge(attrs, invalid)).valid?
    end
  end

  @tag :grant
  test "current grants preserve complete qualified source-item history" do
    account = account!("grant-history")
    attrs = grant_attrs(account.id)

    assert {:ok, first} = TestRepo.insert(Grant.changeset(%Grant{}, attrs))
    assert {:error, duplicate} = TestRepo.insert(Grant.changeset(%Grant{}, attrs))
    assert %{provider_lineage_id: ["has already been taken"]} = errors_on(duplicate)

    assert {:ok, different_source} =
             TestRepo.insert(Grant.changeset(%Grant{}, %{attrs | source_item_id: "item-2"}))

    assert {:ok, superseded} =
             first
             |> Grant.changeset(%{superseded_at: ~U[2026-08-02 16:00:00.000000Z]})
             |> TestRepo.update()

    assert {:ok, replacement} = TestRepo.insert(Grant.changeset(%Grant{}, attrs))
    assert superseded.id != replacement.id
    assert different_source.account_revision == 0
    assert TestRepo.aggregate(Grant, :count, :id) == 3
  end

  @tag :grant
  test "grants reject incomplete identity and non-positive quantities" do
    account = account!("grant-invalid")
    attrs = grant_attrs(account.id)

    for invalid <- [
          %{source_item_id: nil},
          %{provider_lineage_id: ""},
          %{quantity: 0},
          %{provider_order: -1}
        ] do
      refute Grant.changeset(%Grant{}, Map.merge(attrs, invalid)).valid?
    end
  end

  @tag :grant
  test "source observations must have the same account rail and environment" do
    account = account!("grant-provenance")
    other_account = account!("grant-provenance-other")

    assert {:ok, observation} =
             Observation.insert_idempotently(
               TestRepo,
               observation_attrs(account.id, %{provider_event_id: "event-provenance"})
             )

    attrs = Map.put(grant_attrs(account.id), :source_observation_id, observation.id)
    assert {:ok, _grant} = TestRepo.insert(Grant.changeset(%Grant{}, attrs))
    assert {:ok, _grant} =
             TestRepo.insert(
               Grant.changeset(%Grant{}, %{grant_attrs(account.id) | source_item_id: "nil-source"})
             )

    for invalid <- [
          %{attrs | account_id: other_account.id, source_item_id: "account-mismatch"},
          %{attrs | rail: :stripe, source_item_id: "rail-mismatch"},
          %{attrs | environment: :sandbox, source_item_id: "environment-mismatch"}
        ] do
      assert {:error, changeset} = TestRepo.insert(Grant.changeset(%Grant{}, invalid))
      assert %{source_observation_id: [_]} = errors_on(changeset)
    end
  end

  defp observation_attrs(account_id, overrides \\ %{}) do
    Map.merge(
      %{
        account_id: account_id,
        rail: :apple,
        environment: :production,
        provider_event_id: nil,
        provider_transaction_id: "transaction-216",
        kind: "renewal",
        provider_lineage_id: "lineage-216",
        provider_product_id: "product-216",
        provider_order: 7,
        observed_at: ~U[2026-08-02 15:00:00.000000Z],
        state: :qualified,
        retry_count: 0,
        metadata: %{"source" => "apple_server"},
        evidence_digest: String.duplicate("a", 64)
      },
      overrides
    )
  end

  defp grant_attrs(account_id) do
    %{
      account_id: account_id,
      rail: :apple,
      environment: :production,
      provider_lineage_id: "lineage-grant-216",
      provider_product_id: "product-grant-216",
      logical_plan: "pro",
      source_item_id: "item-1",
      quantity: 1,
      provider_order: 0,
      account_revision: 0,
      effective_at: ~U[2026-08-02 15:00:00.000000Z]
    }
  end

  defp device_attrs(account_id) do
    %{
      account_id: account_id,
      installation_id: "install-216",
      key_thumbprint: "thumbprint-216",
      state: :active,
      registered_at: ~U[2026-08-02 15:00:00.000000Z],
      last_seen_at: ~U[2026-08-02 15:01:00.000000Z],
      last_accepted_revision: 0
    }
  end

  defp errors_on(changeset),
    do: Ecto.Changeset.traverse_errors(changeset, fn {message, _} -> message end)
end
