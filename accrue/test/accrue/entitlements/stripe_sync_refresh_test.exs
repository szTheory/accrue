defmodule Accrue.Entitlements.StripeSyncRefreshTest do
  @moduledoc """
  Phase 213 Plan 01 — Fake-backed advisory refresh contract.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.StripeSync
  alias Accrue.Events.Event

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "fake",
        processor_id: "cus_fake_sync",
        email: "stripe-sync@example.test"
      })
      |> Repo.insert()

    %{customer: customer}
  end

  describe "refresh/2" do
    setup do
      previous = Application.get_env(:accrue, :entitlements)

      Application.put_env(
        :accrue,
        :entitlements,
        Keyword.put(previous || [], :stripe_native_sync, :advisory)
      )

      on_exit(fn ->
        if previous do
          Application.put_env(:accrue, :entitlements, previous)
        else
          Application.delete_env(:accrue, :entitlements)
        end
      end)

      :ok
    end

    test "writes a complete Fake entitlement list as one advisory summary", %{customer: customer} do
      Fake.put_entitlements(customer.processor_id, [
        %{
          "id" => "ent_fake_alpha",
          "object" => "entitlements.active_entitlement",
          "feature" => "feat_alpha",
          "lookup_key" => "alpha",
          "livemode" => false
        }
      ])

      assert {:ok, %EntitlementSummary{} = summary} = StripeSync.refresh(customer)

      assert summary.customer_id == customer.id
      assert summary.stripe_customer_id == customer.processor_id
      assert summary.entitlement_count == 1
      assert summary.truncated == false
      assert summary.last_stripe_event_ts == nil
      assert summary.last_stripe_event_id == nil
      assert summary.data["object"] == "entitlements.active_entitlement_summary"
      assert summary.data["customer"] == customer.processor_id
      assert summary.data["entitlements"]["has_more"] == false
      assert summary.data["entitlements"]["url"] == "/v1/entitlements/active_entitlements"
      assert summary.data["_accrue"]["source"] == "pull"
      assert [%{"lookup_key" => "alpha"}] = summary.data["entitlements"]["data"]

      assert Fake.call_count(:list_active_entitlements) == 1
      assert Repo.aggregate(EntitlementSummary, :count) == 1
    end

    test "identical refresh is unchanged and does not duplicate the ledger", %{customer: customer} do
      Fake.put_entitlements(customer.processor_id, [
        %{
          "id" => "ent_fake_alpha",
          "object" => "entitlements.active_entitlement",
          "feature" => "feat_alpha",
          "lookup_key" => "alpha",
          "livemode" => false
        }
      ])

      assert {:ok, %EntitlementSummary{}} = StripeSync.refresh(customer)
      ledger_count = Repo.aggregate(Event, :count)

      assert {:ok, :unchanged} = StripeSync.refresh(customer)
      assert Repo.aggregate(Event, :count) == ledger_count
      assert Repo.aggregate(EntitlementSummary, :count) == 1
    end
  end

  test "disabled refresh returns before Processor or Repo I/O", %{customer: customer} do
    previous = Application.get_env(:accrue, :entitlements)

    Application.put_env(
      :accrue,
      :entitlements,
      Keyword.put(previous || [], :stripe_native_sync, :disabled)
    )

    on_exit(fn ->
      if previous do
        Application.put_env(:accrue, :entitlements, previous)
      else
        Application.delete_env(:accrue, :entitlements)
      end
    end)

    assert {:ok, :disabled} = StripeSync.refresh(customer)
    assert Fake.call_count(:list_active_entitlements) == 0
    assert Repo.aggregate(EntitlementSummary, :count) == 0
  end
end
