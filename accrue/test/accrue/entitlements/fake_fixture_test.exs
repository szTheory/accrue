defmodule Accrue.Entitlements.FakeFixtureTest do
  use Accrue.RepoCase, async: false

  alias Accrue.Config
  alias Accrue.Entitlements.{Account, Device, Grant, Observation}
  alias Accrue.Test.EntitlementFixtures
  alias Accrue.TestRepo

  test "legacy and concurrent rail configs are deterministic and boot-valid" do
    assert EntitlementFixtures.legacy_config() == EntitlementFixtures.legacy_config()
    assert EntitlementFixtures.multi_rail_config() == EntitlementFixtures.multi_rail_config()

    assert Config.validate!(EntitlementFixtures.legacy_config())
    assert Config.validate!(EntitlementFixtures.multi_rail_config())

    rails = Keyword.fetch!(EntitlementFixtures.multi_rail_config(), :rails)
    assert Keyword.fetch!(rails, :stripe)[:source] == :stripe
    assert Keyword.fetch!(rails, :apple)[:source] == :apple
    assert Keyword.fetch!(EntitlementFixtures.multi_rail_config(), :default_rail) == :stripe
  end

  test "record fixtures cover every supported rail and environment with bounded fake evidence" do
    account = EntitlementFixtures.account_attrs("fixture-owner")
    pairs = for rail <- [:stripe, :apple], environment <- [:production, :sandbox], do: {rail, environment}

    assert Enum.map(pairs, fn pair ->
             observation = EntitlementFixtures.observation_attrs(account.id, pair)
             grant = EntitlementFixtures.grant_attrs(account.id, pair)
             device = EntitlementFixtures.device_attrs(account.id, pair)
             {{observation.rail, observation.environment}, {grant.rail, grant.environment}, device.state}
           end) ==
             Enum.map(pairs, fn {rail, environment} -> {{rail, environment}, {rail, environment}, :active} end)

    observation = EntitlementFixtures.observation_attrs(account.id, {:apple, :sandbox})
    assert observation.metadata == %{"source" => "fake_observer"}
    assert observation.evidence_digest =~ ~r/\A[a-f0-9]{64}\z/
    assert observation.observed_at == ~U[2026-08-02 15:00:00.000000Z]
    refute inspect(observation) =~ "receipt"
    refute inspect(observation) =~ "jws"
  end

  test "named scenarios are sorted, unique, and exercise real persistence constraints" do
    names = EntitlementFixtures.scenario(:all) |> Enum.map(& &1.name)
    assert names == Enum.sort(names)
    assert length(names) == length(Enum.uniq(names))

    account_attrs = EntitlementFixtures.account_attrs("scenario-owner")
    assert {:ok, account} = Account.fetch_or_create(TestRepo, account_attrs.owner_type, account_attrs.owner_id)

    duplicate = EntitlementFixtures.observation_attrs(account.id, {:apple, :production})
    assert {:ok, first} = Observation.insert_idempotently(TestRepo, duplicate)
    assert {:ok, second} = Observation.insert_idempotently(TestRepo, duplicate)
    assert first.id == second.id

    grant_attrs = EntitlementFixtures.grant_attrs(account.id, {:stripe, :production})
    assert {:ok, first_grant} = TestRepo.insert(Grant.changeset(%Grant{}, grant_attrs))
    assert {:error, _} = TestRepo.insert(Grant.changeset(%Grant{}, grant_attrs))
    assert {:ok, _} = TestRepo.update(Grant.changeset(first_grant, %{superseded_at: ~U[2026-08-02 16:00:00.000000Z]}))
    assert {:ok, _} = TestRepo.insert(Grant.changeset(%Grant{}, grant_attrs))

    device_attrs = EntitlementFixtures.device_attrs(account.id, {:apple, :sandbox})
    assert {:ok, device} = TestRepo.insert(Device.changeset(%Device{}, device_attrs))
    assert {:ok, _} = TestRepo.update(Device.changeset(device, %{state: :revoked, revoked_at: ~U[2026-08-02 16:00:00.000000Z]}))
    assert {:ok, _} = TestRepo.insert(Device.changeset(%Device{}, device_attrs))
  end

  test "fixture calls and scenario values remain stable without provider dependencies" do
    assert EntitlementFixtures.scenario(:all) == EntitlementFixtures.scenario(:all)
    assert EntitlementFixtures.account_attrs("stable") == EntitlementFixtures.account_attrs("stable")
    assert EntitlementFixtures.observation_attrs("account-id", {:stripe, :production}) ==
             EntitlementFixtures.observation_attrs("account-id", {:stripe, :production})

    fixture_source = File.read!("test/support/entitlements/fixtures.ex")
    refute fixture_source =~ "Stripe."
    refute fixture_source =~ "Apple."
    refute fixture_source =~ "System.fetch_env!"
  end
end
