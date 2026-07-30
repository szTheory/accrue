defmodule Accrue.Entitlements.StripeSyncRefreshTest do
  @moduledoc """
  Phase 213 Plan 01 — Fake-backed advisory refresh contract.
  """

  use Accrue.BillingCase, async: false

  alias Accrue.Billing.EntitlementSummary
  alias Accrue.Entitlements.StripeSync
  alias Accrue.Events.Event
  alias Accrue.Webhook.DefaultHandler

  setup do
    {:ok, customer} =
      %Customer{}
      |> Customer.changeset(%{
        owner_type: "User",
        owner_id: Ecto.UUID.generate(),
        processor: "stripe",
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

    test "stale pull cannot clobber a strictly newer webhook snapshot", %{customer: customer} do
      Fake.put_entitlements(customer.processor_id, [entitlement("pull_old", "pull-old")])

      webhook_ts = DateTime.add(Accrue.Clock.utc_now(), 60, :second)

      webhook =
        StripeFixtures.entitlement_summary_event(
          [
            customer: customer.processor_id,
            entitlements: [entitlement("webhook_new", "webhook-new")]
          ],
          %{"id" => "evt_newer_webhook", "created" => DateTime.to_unix(webhook_ts)}
        )

      assert {:ok, %EntitlementSummary{}} = DefaultHandler.handle(webhook)
      assert {:ok, :stale} = StripeSync.refresh(customer)

      row = Repo.get_by(EntitlementSummary, customer_id: customer.id)
      assert row.last_stripe_event_id == "evt_newer_webhook"
      assert DateTime.compare(row.last_stripe_event_ts, webhook_ts) == :eq
      assert [%{"lookup_key" => "webhook-new"}] = row.data["entitlements"]["data"]
    end

    test "newer pull can refresh advisory data without erasing webhook watermark", %{
      customer: customer
    } do
      webhook_ts = DateTime.truncate(Accrue.Clock.utc_now(), :second)

      webhook =
        StripeFixtures.entitlement_summary_event(
          [
            customer: customer.processor_id,
            entitlements: [entitlement("webhook_first", "webhook-first")]
          ],
          %{"id" => "evt_existing_webhook", "created" => DateTime.to_unix(webhook_ts)}
        )

      assert {:ok, %EntitlementSummary{}} = DefaultHandler.handle(webhook)

      assert {:ok, _effects} =
               Accrue.Test.Clock.advance_clock([seconds: 90], processor: Accrue.Processor.Fake)

      Fake.put_entitlements(customer.processor_id, [entitlement("pull_later", "pull-later")])

      assert {:ok, %EntitlementSummary{} = summary} = StripeSync.refresh(customer)

      assert DateTime.compare(summary.synced_at, webhook_ts) == :gt
      assert summary.last_stripe_event_id == "evt_existing_webhook"
      assert DateTime.compare(summary.last_stripe_event_ts, webhook_ts) == :eq
      assert [%{"lookup_key" => "pull-later"}] = summary.data["entitlements"]["data"]
      assert summary.data["_accrue"]["source"] == "pull"
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

  defp entitlement(feature, lookup_key) do
    %{
      "id" => "ent_#{lookup_key}",
      "object" => "entitlements.active_entitlement",
      "feature" => "feat_#{feature}",
      "lookup_key" => lookup_key,
      "livemode" => false
    }
  end
end
