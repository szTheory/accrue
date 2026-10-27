ExUnit.start()
{:ok, _localize_apps} = Application.ensure_all_started(:localize)

defmodule AccrueAdmin.SubscriptionCompositionManifestFixture.Duplicate do
  alias PhoenixStorybook.Stories.Variation

  def variations do
    [
      %Variation{id: :one_row, attributes: %{scenario: :launch}},
      %Variation{id: :one_row, attributes: %{scenario: :launch}}
    ]
  end
end

defmodule AccrueAdmin.SubscriptionCompositionManifestFixture.Missing do
  alias PhoenixStorybook.Stories.Variation

  def variations, do: [%Variation{id: :other, attributes: %{scenario: :launch}}]
end

defmodule AccrueAdmin.SubscriptionCompositionsManifestBootTest do
  use ExUnit.Case, async: false

  test "compiled collection composition manifest is available" do
    assert Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionCompositionsManifest),
           "the compiled collection composition manifest is unavailable"
  end
end

if Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionCompositionsManifest) do
  defmodule AccrueAdmin.SubscriptionCompositionsManifestTest do
    use ExUnit.Case, async: false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Storybook.SubscriptionCompositionsManifest, as: Manifest
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}

    @storybook_root "/dev/storybook"
    @story_path "/groups/subscriptions_collection"
    @manifest_path Path.expand("../../../tmp/phase253/manifest.json", __DIR__)

    test "compiled one_row identity resolves to the mounted collection story and current transport" do
      assert Process.whereis(AccrueAdmin.TestRepo) == nil

      assert [%StoryEntry{path: @story_path}] =
               Enum.filter(Storybook.leaves(), &(&1.path == @story_path))

      assert [entry] = Manifest.entries()
      assert entry.story_path == @story_path
      assert entry.group_id == nil
      assert entry.variation_id == "one_row"
      assert entry.route_variation_id == "one_row"

      assert entry.url ==
               NavigationHelpers.path_to_story(
                 @storybook_root,
                 "groups/subscriptions_collection",
                 %{
                   variation_id: "one_row"
                 }
               )

      assert entry.direct_path == "/billing" <> entry.url
      assert entry.transport_kind == "live_component"

      assert entry.production_renderer ==
               "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1"

      assert entry.query_module == "AccrueAdmin.Storybook.SubscriptionCollectionQuery"
      assert entry.fact_source == "CadenceSubscriptionFacts.fetch!(:launch)"
      assert entry.proof_lane == "presentation-only"
      assert entry.expected.subscription_id == "c134aee0-b71a-44f5-a030-f6146577dba5"
      assert entry.expected.processor_id == "sub_cadence_launch"
      assert entry.expected.customer_name == "Northstar Research"
      assert entry.expected.status == "active"
      assert entry.expected.plan_price_id == "pro_monthly_2026"
      assert entry.expected.amount_state == "unavailable"
      assert Manifest.route_matches?(entry, entry.url)

      wrong_route =
        NavigationHelpers.path_to_story(@storybook_root, "groups/subscriptions_collection", %{
          variation_id: "not_declared"
        })

      refute Manifest.route_matches?(entry, wrong_route)
    end

    test "manifest write verifies current source digests and keeps task 1 transport provenance" do
      :ok = Manifest.write!(@manifest_path)
      assert :ok = Manifest.verify!(@manifest_path)

      manifest = @manifest_path |> File.read!() |> Jason.decode!()
      assert manifest["human_judgment"] == false
      assert manifest["transport"]["transport_kind"] == "live_component"

      assert Map.has_key?(
               manifest["source_digests"],
               "accrue_admin/lib/accrue_admin/queries/subscriptions.ex"
             )

      assert manifest["transport"]["direct_path"] ==
               "/billing/dev/storybook/groups/subscriptions_collection?variation_id=one_row"

      [{source_path, _digest} | _] = Enum.sort(manifest["source_digests"])

      stale_digests =
        Map.put(manifest["source_digests"], source_path, String.duplicate("0", 64))

      File.write!(
        @manifest_path,
        Jason.encode!(Map.put(manifest, "source_digests", stale_digests))
      )

      assert_raise ArgumentError, ~r/source digest/i, fn ->
        Manifest.verify!(@manifest_path)
      end

      :ok = Manifest.write!(@manifest_path)
      assert :ok = Manifest.verify!(@manifest_path)
    end

    test "duplicate identity, missing one_row, and empty declarations fail closed" do
      assert_raise ArgumentError, ~r/duplicate collection path\/group\/variation identity/i, fn ->
        Manifest.entries_for(
          [{@story_path, AccrueAdmin.SubscriptionCompositionManifestFixture.Duplicate}],
          @storybook_root
        )
      end

      assert_raise ArgumentError, ~r/missing the unique one_row/i, fn ->
        Manifest.entries_for(
          [{@story_path, AccrueAdmin.SubscriptionCompositionManifestFixture.Missing}],
          @storybook_root
        )
      end

      assert_raise ArgumentError, ~r/zero variations/i, fn ->
        Manifest.entries_for([], @storybook_root)
      end
    end
  end
end
