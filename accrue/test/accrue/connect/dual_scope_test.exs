defmodule Accrue.Connect.DualScopeTest do
  @moduledoc """
  Phase 5 Plan 07 — CONN-11 cross-scope integration coverage.

  Covers VALIDATION.md row 28: the same `Accrue.Billing.*` call must
  work both platform-scoped (no `with_account/2` wrapper) and
  connected-account-scoped (inside `Accrue.Connect.with_account/2`)
  with correct Fake-processor keyspace isolation between the two.

  The Fake processor tags every `create_customer` / `create_charge`
  write with a scope key read from `Process.get(:accrue_connected_account_id)`
  via `thread_scope/1`. `with_account/2` is the writer side of that
  same pdict key, so nested billing calls automatically land in the
  connected-account keyspace.

  Keyspace isolation proof:

    * A platform-scoped customer must be visible via
      `Fake.customers_on(:platform)` and NOT via
      `Fake.customers_on(acct.stripe_account_id)`.
    * A connected-account-scoped customer must be visible via
      `Fake.customers_on(acct.stripe_account_id)` and NOT via
      `Fake.customers_on(:platform)`.
  """
  use Accrue.ConnectCase, async: false

  alias Accrue.Billing
  alias Accrue.Connect

  # Minimal billable schema for the dual-scope integration test. The
  # test_users table is not migrated — Billing.create_customer/1 only
  # reads `mod.__accrue__(:billable_type)` + `id`, and the Customer
  # row it inserts references `accrue_customers`, not `test_users`.
  defmodule DualScopeUser do
    @moduledoc false
    use Ecto.Schema
    use Accrue.Billable

    @primary_key {:id, :binary_id, autogenerate: true}
    schema "test_users" do
    end
  end

  defp new_user, do: %DualScopeUser{id: Ecto.UUID.generate()}

  setup do
    {:ok, acct} =
      Connect.create_account(%{
        type: :standard,
        country: "US",
        email: "dual-scope@example.com"
      })

    %{account: acct}
  end

  describe "Accrue.Billing.create_customer/1 (CONN-11)" do
    test "creates in Fake :platform keyspace when called without scope" do
      assert {:ok, _customer} = Billing.create_customer(new_user())

      platform = Fake.customers_on(:platform)
      assert length(platform) >= 1
    end

    test "creates in Fake connected-account keyspace inside with_account/2",
         %{account: acct} do
      {:ok, _customer} =
        Connect.with_account(acct.stripe_account_id, fn ->
          Billing.create_customer(new_user())
        end)

      scoped = Fake.customers_on(acct.stripe_account_id)
      assert length(scoped) == 1

      # And the scoped customer MUST NOT appear under :platform.
      platform = Fake.customers_on(:platform)
      refute Enum.any?(platform, &(&1[:id] == List.first(scoped)[:id]))
    end

    test "coexistent platform + connected-account customers are isolated",
         %{account: acct} do
      # Interleave the two scopes in a single test to exercise the
      # pdict save/restore path and prove neither bleeds into the other.
      {:ok, platform_customer} = Billing.create_customer(new_user())

      {:ok, scoped_customer} =
        Connect.with_account(acct.stripe_account_id, fn ->
          Billing.create_customer(new_user())
        end)

      # After the block exits, pdict scope must be cleared.
      refute Connect.current_account_id()

      # A second platform call lands in :platform.
      {:ok, platform_customer_2} = Billing.create_customer(new_user())

      platform = Fake.customers_on(:platform)
      scoped = Fake.customers_on(acct.stripe_account_id)

      platform_ids = Enum.map(platform, & &1[:id])
      scoped_ids = Enum.map(scoped, & &1[:id])

      assert platform_customer.processor_id in platform_ids
      assert platform_customer_2.processor_id in platform_ids
      refute scoped_customer.processor_id in platform_ids

      assert scoped_customer.processor_id in scoped_ids
      refute platform_customer.processor_id in scoped_ids
      refute platform_customer_2.processor_id in scoped_ids
    end
  end

  describe "Accrue.Billing.subscribe/3 under dual scope (CONN-11 smoke)" do
    test "subscribe succeeds both platform-scoped and account-scoped",
         %{account: acct} do
      # Platform-scoped: create customer + subscribe.
      {:ok, platform_customer} = Billing.create_customer(new_user())

      assert {:ok, _sub} =
               Billing.subscribe(platform_customer, "price_dual_scope_platform")

      # Account-scoped: identical call shape works inside with_account/2.
      Connect.with_account(acct.stripe_account_id, fn ->
        {:ok, scoped_customer} = Billing.create_customer(new_user())

        assert {:ok, _sub} =
                 Billing.subscribe(scoped_customer, "price_dual_scope_scoped")
      end)

      # Customer keyspace isolation still holds after subscribe round-trip.
      platform_ids = Fake.customers_on(:platform) |> Enum.map(& &1[:id])
      scoped_ids = Fake.customers_on(acct.stripe_account_id) |> Enum.map(& &1[:id])

      assert platform_customer.processor_id in platform_ids
      refute Enum.empty?(scoped_ids)
      assert Enum.all?(scoped_ids, &(&1 not in platform_ids))
    end
  end
end
