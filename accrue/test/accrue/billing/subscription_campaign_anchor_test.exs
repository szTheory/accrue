defmodule Accrue.Billing.SubscriptionCampaignAnchorTest do
  @moduledoc """
  Phase 128 (128-02, D-08) — the dunning-campaign anchor on Subscription:
  the `dunning_campaign_active?/1` predicate (dual-shape + catch-all) and
  the recovery-CLEAR cast path through `force_status_changeset/2`.

  Pure-unit (no DB, no Stripe) — `async: true`.
  """
  use ExUnit.Case, async: true

  alias Accrue.Billing.Subscription

  describe "dunning_campaign_active?/1" do
    test "true for a %Subscription{} with a non-nil DateTime anchor" do
      sub = %Subscription{dunning_campaign_started_at: DateTime.utc_now()}
      assert Subscription.dunning_campaign_active?(sub)
    end

    test "true for a bare map with a non-nil DateTime anchor" do
      assert Subscription.dunning_campaign_active?(%{
               dunning_campaign_started_at: DateTime.utc_now()
             })
    end

    test "false for a %Subscription{} with a nil anchor" do
      refute Subscription.dunning_campaign_active?(%Subscription{
               dunning_campaign_started_at: nil
             })
    end

    test "false for a bare map with a nil anchor" do
      refute Subscription.dunning_campaign_active?(%{dunning_campaign_started_at: nil})
    end

    test "false for any other shape (catch-all)" do
      refute Subscription.dunning_campaign_active?(nil)
      refute Subscription.dunning_campaign_active?(%{})
      refute Subscription.dunning_campaign_active?(:not_a_subscription)
      refute Subscription.dunning_campaign_active?(%Subscription{})
    end
  end

  describe "force_status_changeset/2 anchor cast (D-12 recovery-clear)" do
    test "casts the anchor to nil through the clear path" do
      anchored = %Subscription{dunning_campaign_started_at: DateTime.utc_now()}

      changeset =
        Subscription.force_status_changeset(anchored, %{dunning_campaign_started_at: nil})

      assert Map.has_key?(changeset.changes, :dunning_campaign_started_at)
      assert changeset.changes.dunning_campaign_started_at == nil
    end

    test "casts a non-nil anchor through force_status_changeset/2" do
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      changeset =
        Subscription.force_status_changeset(%Subscription{}, %{
          dunning_campaign_started_at: now
        })

      assert changeset.changes.dunning_campaign_started_at == now
    end
  end
end
