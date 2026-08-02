defmodule Accrue.Entitlements.PersistenceTest do
  use Accrue.RepoCase

  alias Accrue.Entitlements.Account
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

  defp account!(suffix) do
    {:ok, account} = Account.fetch_or_create(TestRepo, "user", "owner-#{suffix}")
    account
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
end
