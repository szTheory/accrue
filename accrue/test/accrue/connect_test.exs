defmodule Accrue.ConnectTest do
  use Accrue.ConnectCase, async: false

  alias Accrue.Connect
  alias Accrue.Connect.Account
  alias Accrue.Processor.Fake

  describe "with_account/2 + current_account_id/0" do
    test "scopes pdict for the duration of the block, then restores prior" do
      refute Connect.current_account_id()

      result =
        Connect.with_account("acct_test_outer", fn ->
          assert Connect.current_account_id() == "acct_test_outer"

          Connect.with_account("acct_test_inner", fn ->
            assert Connect.current_account_id() == "acct_test_inner"
            :inner_ok
          end)

          # Prior scope restored after inner block
          assert Connect.current_account_id() == "acct_test_outer"
          :outer_ok
        end)

      assert result == :outer_ok
      # Pdict cleared back to nil on outer exit
      refute Connect.current_account_id()
    end

    test "accepts a %Account{} struct OR a binary id" do
      row = %Account{stripe_account_id: "acct_struct_scope"}

      Connect.with_account(row, fn ->
        assert Connect.current_account_id() == "acct_struct_scope"
      end)

      refute Connect.current_account_id()
    end

    test "restores prior scope even if fun raises" do
      :ok = Connect.put_account_id("acct_prior")

      assert_raise RuntimeError, "boom", fn ->
        Connect.with_account("acct_temp", fn -> raise "boom" end)
      end

      assert Connect.current_account_id() == "acct_prior"
    after
      Connect.delete_account_id()
    end

    test "with nil clears scope for the block, then restores" do
      :ok = Connect.put_account_id("acct_outer")

      Connect.with_account(nil, fn ->
        refute Connect.current_account_id()
      end)

      assert Connect.current_account_id() == "acct_outer"
    after
      Connect.delete_account_id()
    end
  end

  describe "resolve_account_id/1" do
    test "handles struct + binary + nil" do
      assert Connect.resolve_account_id(%Account{stripe_account_id: "acct_a"}) == "acct_a"
      assert Connect.resolve_account_id("acct_b") == "acct_b"
      assert Connect.resolve_account_id(nil) == nil
    end
  end

  describe "create_account/2" do
    test "rejects missing :type with an Accrue.ConfigError" do
      assert {:error, %Accrue.ConfigError{}} = Connect.create_account(%{country: "US"})
    end

    test "accepts :type in both atom and string form" do
      for type <- [:standard, "standard", :express, "express", :custom, "custom"] do
        assert {:ok, %Account{} = acct} = Connect.create_account(%{type: type})
        assert acct.type == (if is_atom(type), do: Atom.to_string(type), else: type)
        assert is_binary(acct.stripe_account_id)
        assert String.starts_with?(acct.stripe_account_id, "acct_fake_")
      end
    end

    test "persists a local row" do
      {:ok, acct} = Connect.create_account(%{type: :standard, country: "US"})
      assert %Account{} = loaded = Repo.get_by(Account, stripe_account_id: acct.stripe_account_id)
      assert loaded.country == "US"
      assert loaded.type == "standard"
    end

    test "records a connect.account.created event row" do
      initial_count =
        Repo.aggregate(
          from(e in Accrue.Events.Event, where: e.type == "connect.account.created"),
          :count,
          :id
        )

      {:ok, _acct} = Connect.create_account(%{type: :standard})

      final_count =
        Repo.aggregate(
          from(e in Accrue.Events.Event, where: e.type == "connect.account.created"),
          :count,
          :id
        )

      assert final_count == initial_count + 1
    end
  end

  describe "retrieve_account/2" do
    test "upserts local row on miss" do
      {:ok, created} = Connect.create_account(%{type: :express})

      # Simulate a fresh retrieve (round-trips through the Fake).
      assert {:ok, fetched} = Connect.retrieve_account(created.stripe_account_id)
      assert fetched.stripe_account_id == created.stripe_account_id
      assert fetched.type == "express"
    end
  end

  describe "update_account/3" do
    test "round-trips a payout schedule nested map (CONN-08)" do
      {:ok, acct} = Connect.create_account(%{type: :custom})

      patch = %{settings: %{payouts: %{schedule: %{interval: "daily"}}}}
      assert {:ok, updated} = Connect.update_account(acct.stripe_account_id, patch)

      # Verify the Fake stored the nested map intact.
      stripe = Enum.find(Fake.accounts(), fn a -> a[:id] == acct.stripe_account_id end)
      assert get_in(stripe, [:settings, :payouts, :schedule, :interval]) == "daily"
      assert %Account{} = updated
    end

    test "round-trips a capabilities nested map (CONN-09)" do
      {:ok, acct} = Connect.create_account(%{type: :custom})

      patch = %{capabilities: %{card_payments: %{requested: true}}}
      assert {:ok, _updated} = Connect.update_account(acct.stripe_account_id, patch)

      stripe = Enum.find(Fake.accounts(), fn a -> a[:id] == acct.stripe_account_id end)
      assert get_in(stripe, [:capabilities, :card_payments, :requested]) == true
    end
  end

  describe "delete_account/2 (tombstone path)" do
    test "marks deauthorized_at without removing the local row" do
      {:ok, acct} = Connect.create_account(%{type: :standard})

      assert {:ok, tombstoned} = Connect.delete_account(acct.stripe_account_id)
      assert %DateTime{} = tombstoned.deauthorized_at
      assert Account.deauthorized?(tombstoned)

      # Row still exists locally (audit trail).
      assert %Account{} = Repo.get_by(Account, stripe_account_id: acct.stripe_account_id)
    end
  end

  describe "CONN-11 dual-scope Fake keyspace" do
    test "same create_customer call lands in distinct scopes depending on with_account" do
      # Platform-scope call
      {:ok, _platform_cust} = Accrue.Processor.create_customer(%{name: "platform user"})

      # Connected-account-scope call
      Connect.with_account("acct_dual_test", fn ->
        {:ok, _connected_cust} = Accrue.Processor.create_customer(%{name: "connected user"})
      end)

      platform_names = Fake.customers_on(:platform) |> Enum.map(& &1[:name])
      connected_names = Fake.customers_on("acct_dual_test") |> Enum.map(& &1[:name])

      assert "platform user" in platform_names
      refute "connected user" in platform_names

      assert "connected user" in connected_names
      refute "platform user" in connected_names
    end
  end
end
