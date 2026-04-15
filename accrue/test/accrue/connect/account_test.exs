defmodule Accrue.Connect.AccountTest.FakeStripeAccount do
  @moduledoc false
  defstruct [:id, :type, :charges_enabled, :payouts_enabled, :details_submitted]
end

defmodule Accrue.Connect.AccountTest do
  use Accrue.ConnectCase, async: true

  alias Accrue.Connect.{Account, Projection}

  import Ecto.Changeset, only: [get_change: 2]

  describe "changeset/2" do
    test "requires stripe_account_id and type" do
      cs = Account.changeset(%Account{}, %{})
      refute cs.valid?
      assert %{stripe_account_id: ["can't be blank"], type: ["can't be blank"]} = errors_on(cs)
    end

    test "rejects unknown type" do
      attrs = %{stripe_account_id: "acct_test_001", type: "bogus"}
      cs = Account.changeset(%Account{}, attrs)
      refute cs.valid?
      assert %{type: ["is invalid"]} = errors_on(cs)
    end

    test "accepts each of standard/express/custom" do
      for t <- ["standard", "express", "custom"] do
        cs = Account.changeset(%Account{}, %{stripe_account_id: "acct_" <> t, type: t})
        assert cs.valid?, "expected #{t} to be valid"
      end
    end

    test "enforces unique stripe_account_id constraint" do
      attrs = %{stripe_account_id: "acct_dupe", type: "standard"}
      assert {:ok, _row} = Repo.insert(Account.changeset(%Account{}, attrs))

      assert {:error, cs} = Repo.insert(Account.changeset(%Account{}, attrs))
      refute cs.valid?
      assert %{stripe_account_id: ["has already been taken"]} = errors_on(cs)
    end
  end

  describe "force_status_changeset/2" do
    test "accepts a state-fields-only patch without requiring stripe_account_id" do
      row = %Account{stripe_account_id: "acct_test_007", type: "express", lock_version: 1}
      cs = Account.force_status_changeset(row, %{charges_enabled: true, payouts_enabled: true})
      assert cs.valid?
      assert get_change(cs, :charges_enabled) == true
      assert get_change(cs, :payouts_enabled) == true
    end

    test "does not cast :type (state-fields allowlist only)" do
      row = %Account{stripe_account_id: "acct_test_008", type: "standard", lock_version: 1}
      cs = Account.force_status_changeset(row, %{type: "express"})
      assert cs.valid?
      refute Map.has_key?(cs.changes, :type)
    end
  end

  describe "predicates" do
    test "charges_enabled?/1 works on struct, bare map, and unknown" do
      assert Account.charges_enabled?(%Account{charges_enabled: true})
      assert Account.charges_enabled?(%{charges_enabled: true})
      refute Account.charges_enabled?(%Account{charges_enabled: false})
      refute Account.charges_enabled?(%{})
      refute Account.charges_enabled?(nil)
    end

    test "payouts_enabled?/1 works on struct, bare map, and unknown" do
      assert Account.payouts_enabled?(%Account{payouts_enabled: true})
      assert Account.payouts_enabled?(%{payouts_enabled: true})
      refute Account.payouts_enabled?(%Account{payouts_enabled: false})
      refute Account.payouts_enabled?(nil)
    end

    test "details_submitted?/1 works on struct, bare map, and unknown" do
      assert Account.details_submitted?(%Account{details_submitted: true})
      assert Account.details_submitted?(%{details_submitted: true})
      refute Account.details_submitted?(%{})
    end

    test "fully_onboarded?/1 requires all three state flags" do
      ready = %Account{
        charges_enabled: true,
        payouts_enabled: true,
        details_submitted: true
      }

      assert Account.fully_onboarded?(ready)

      partial = %Account{
        charges_enabled: true,
        payouts_enabled: false,
        details_submitted: true
      }

      refute Account.fully_onboarded?(partial)
      refute Account.fully_onboarded?(%{})
    end

    test "deauthorized?/1 reflects the deauthorized_at tombstone" do
      now = DateTime.utc_now()
      assert Account.deauthorized?(%Account{deauthorized_at: now})
      assert Account.deauthorized?(%{deauthorized_at: now})
      refute Account.deauthorized?(%Account{deauthorized_at: nil})
      refute Account.deauthorized?(%{})
    end
  end

  describe "Projection.decompose/1" do
    test "extracts columns from atom-keyed Fake-shape input" do
      fixture =
        connect_account_fixture(:standard_fully_onboarded)
        |> Map.put(:id, "acct_test_alpha")

      assert {:ok, attrs} = Projection.decompose(fixture)
      assert attrs.stripe_account_id == "acct_test_alpha"
      assert attrs.type == "standard"
      assert attrs.charges_enabled == true
      assert attrs.payouts_enabled == true
      assert attrs.details_submitted == true
      assert is_map(attrs.capabilities)
      assert is_map(attrs.requirements)
      # data is jsonb-normalized (string keys)
      assert attrs.data["id"] == "acct_test_alpha"
    end

    test "extracts columns from string-keyed Stripe-shape input" do
      fixture = %{
        "id" => "acct_str_001",
        "object" => "account",
        "type" => "express",
        "country" => "US",
        "email" => "owner@example.com",
        "charges_enabled" => true,
        "details_submitted" => true,
        "payouts_enabled" => true,
        "capabilities" => %{"card_payments" => %{"status" => "active"}},
        "requirements" => %{"currently_due" => []},
        "metadata" => %{}
      }

      assert {:ok, attrs} = Projection.decompose(fixture)
      assert attrs.stripe_account_id == "acct_str_001"
      assert attrs.type == "express"
      assert attrs.country == "US"
      assert attrs.charges_enabled == true
      assert attrs.capabilities["card_payments"]["status"] == "active"
    end

    test "decomposes a (non-schema) struct input via Map.from_struct/1" do
      stripe_like = %Accrue.Connect.AccountTest.FakeStripeAccount{
        id: "acct_struct",
        type: "custom",
        charges_enabled: false,
        payouts_enabled: false,
        details_submitted: false
      }

      assert {:ok, attrs} = Projection.decompose(stripe_like)
      assert attrs.stripe_account_id == "acct_struct"
      assert attrs.type == "custom"
    end
  end

  # Mirror of Accrue.DataCase.errors_on/1 — kept local so this file
  # doesn't need to reach into the Phoenix-shaped DataCase template.
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
