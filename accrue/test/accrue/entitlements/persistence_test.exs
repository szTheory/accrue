defmodule Accrue.Entitlements.PersistenceTest do
  use Accrue.RepoCase

  alias Accrue.Entitlements.Account
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
end
