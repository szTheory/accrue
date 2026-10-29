defmodule AccrueAdmin.Test.Phase252SubscriptionManifestTapFormatter do
  use GenServer

  def init(_opts), do: {:ok, []}

  def handle_cast({:test_finished, test}, results), do: {:noreply, [test | results]}

  def handle_cast({:suite_finished, _times}, results) do
    tests = Enum.reverse(results)
    IO.puts("TAP version 13")

    tests
    |> Enum.with_index(1)
    |> Enum.each(fn {test, index} ->
      name = "#{inspect(test.module)}::#{test.name}" |> String.replace(~r/[\r\n]+/u, " ")

      case test.state do
        nil ->
          IO.puts("ok #{index} - #{name}")

        {:skipped, _reason} ->
          IO.puts("ok #{index} - #{name} # SKIP")

        {:failed, failures} ->
          IO.puts("not ok #{index} - #{name}")

          Enum.each(failures, fn failure ->
            detail = failure_message(failure) |> String.replace(~r{/Users/[^/\s]+}, "<home>")
            IO.puts("# #{detail}")
          end)

        _ ->
          IO.puts("not ok #{index} - #{name}")
      end
    end)

    IO.puts("1..#{length(tests)}")
    {:noreply, []}
  end

  def handle_cast(_event, results), do: {:noreply, results}

  defp failure_message({exception, _stacktrace}) when is_exception(exception),
    do: Exception.message(exception)

  defp failure_message(exception) when is_exception(exception), do: Exception.message(exception)
  defp failure_message(%{message: message}) when is_binary(message), do: message

  defp failure_message(failure),
    do: inspect(failure, limit: 10, printable_limit: 400, pretty: false)
end

ExUnit.start(formatters: [AccrueAdmin.Test.Phase252SubscriptionManifestTapFormatter])

repo_root = Path.expand("../../../../", __DIR__)

unless Code.ensure_loaded?(CadenceSubscriptionFacts) do
  Code.require_file(Path.join(repo_root, "dev_support/ui_scenarios/cadence_subscriptions.exs"))
end

unless Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionScenarios) do
  Code.require_file(
    Path.join(repo_root, "accrue_admin/storybook/_support/subscription_scenarios.ex")
  )
end

Code.require_file(
  Path.join(repo_root, "accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs")
)

defmodule AccrueAdmin.SubscriptionManifestFixture.Grouped do
  alias AccrueAdmin.Storybook.SubscriptionScenarios
  alias PhoenixStorybook.Stories.{Variation, VariationGroup}

  def variations do
    [
      %VariationGroup{
        id: :lifecycle,
        variations: [
          %Variation{id: :shared, attributes: SubscriptionScenarios.attributes(:active)},
          %Variation{id: :later, attributes: SubscriptionScenarios.attributes(:active)}
        ]
      }
    ]
  end
end

defmodule AccrueAdmin.SubscriptionManifestFixture.Flat do
  alias AccrueAdmin.Storybook.SubscriptionScenarios
  alias PhoenixStorybook.Stories.Variation

  def variations do
    [%Variation{id: :shared, attributes: SubscriptionScenarios.attributes(:active)}]
  end
end

defmodule AccrueAdmin.SubscriptionManifestFixture.MissingAttribution do
  alias PhoenixStorybook.Stories.Variation

  def variations, do: [%Variation{id: :active, attributes: %{scenario: :active}}]
end

defmodule AccrueAdmin.SubscriptionManifestFixture.MissingId do
  alias AccrueAdmin.Storybook.SubscriptionScenarios
  alias PhoenixStorybook.Stories.Variation

  def variations do
    [%Variation{id: nil, attributes: SubscriptionScenarios.attributes(:active)}]
  end
end

defmodule AccrueAdmin.SubscriptionManifestBootTest do
  use ExUnit.Case, async: false

  test "compiled subscription story manifest API is available" do
    assert Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionManifest),
           "the compiled subscription variation manifest is unavailable"
  end
end

if Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionManifest) do
  defmodule AccrueAdmin.SubscriptionManifestTest do
    use ExUnit.Case, async: false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Storybook.SubscriptionCompositionsManifest
    alias AccrueAdmin.Storybook.SubscriptionManifest
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}
    alias PhoenixStorybook.Stories.{Variation, VariationGroup}

    @storybook_root "/dev/storybook"
    @story_path "/components/subscription_detail"

    test "compiled subscription story discovers each real retained variation with stable routes and source digests" do
      assert Process.whereis(AccrueAdmin.TestRepo) == nil

      story_entry = Enum.find(Storybook.leaves(), &(&1.path == @story_path))
      assert %StoryEntry{} = story_entry
      {:ok, story} = Storybook.load_story(String.trim_leading(story_entry.path, "/"))

      declared =
        apply(story, :variations, [])
        |> Enum.flat_map(fn
          %VariationGroup{id: group_id, variations: variations} ->
            Enum.map(variations, &{group_id, &1})

          %Variation{} = variation ->
            [{nil, variation}]
        end)

      entries = SubscriptionManifest.entries()

      expected_keys =
        declared
        |> Enum.map(fn {group_id, variation} ->
          key(@story_path, group_id, variation.id)
        end)
        |> Enum.sort()

      assert Enum.map(entries, & &1.key) == expected_keys
      assert length(entries) == length(declared)
      assert Enum.uniq(Enum.map(entries, & &1.key)) == Enum.map(entries, & &1.key)

      for {group_id, variation} <- declared do
        entry = Enum.find(entries, &(&1.key == key(@story_path, group_id, variation.id)))

        metadata =
          AccrueAdmin.Storybook.SubscriptionScenarios.attributes(variation.attributes.scenario)

        facts = AccrueAdmin.Storybook.SubscriptionScenarios.validate!(variation.attributes)
        route_id = group_id || variation.id

        assert entry.story_path == @story_path
        assert entry.group_id == if(group_id, do: to_string(group_id), else: nil)
        assert entry.variation_id == to_string(variation.id)
        assert entry.route_variation_id == to_string(route_id)

        assert entry.url ==
                 NavigationHelpers.path_to_story(@storybook_root, @story_path, %{
                   variation_id: route_id
                 })

        assert SubscriptionManifest.route_matches?(entry, entry.url)

        wrong_url =
          NavigationHelpers.path_to_story(@storybook_root, @story_path, %{
            variation_id: "wrong-#{variation.id}"
          })

        refute SubscriptionManifest.route_matches?(entry, wrong_url)
        assert entry.actor == metadata.actor
        assert entry.job == metadata.job
        assert entry.input_source == metadata.input_source
        assert entry.production_renderer == metadata.production_renderer
        assert entry.composition_tier == "component"
        assert entry.proof_lane == "static render"
        assert entry.scenario_id == Atom.to_string(variation.attributes.scenario)
        assert entry.expected.identity.customer_id == facts.customer.id
        assert entry.expected.identity.subscription_id == facts.subscription.id

        assert entry.expected.identity.subscription_processor_id ==
                 facts.subscription.processor_id

        assert entry.expected.identity.owner_slug == facts.owner.slug
        assert entry.expected.lifecycle.status == Atom.to_string(facts.subscription.status)

        assert entry.expected.lifecycle.cancel_at_period_end ==
                 facts.subscription.cancel_at_period_end

        assert entry.expected.facts.amount_minor == facts.billing.amount_minor
        assert entry.expected.facts.currency == Atom.to_string(facts.billing.currency)
        assert entry.expected.actions.owner == metadata.production_renderer

        assert entry.expected.actions.proof ==
                 "rendered by production eligibility; no action dispatch claim"
      end

      root = Path.expand("../../../../", __DIR__)

      manifest_path =
        Path.join(
          System.tmp_dir!(),
          "phase252-generated-manifest-#{System.unique_integer([:positive])}.json"
        )

      on_exit(fn -> File.rm(manifest_path) end)

      :ok = SubscriptionManifest.write!(manifest_path)
      manifest = manifest_path |> File.read!() |> Jason.decode!()

      assert manifest["entries"] |> Enum.map(& &1["key"]) == expected_keys
      assert map_size(manifest["source_digests"]) >= 5

      for {source, digest} <- manifest["source_digests"] do
        source_path = Path.join(root, source)
        assert File.regular?(source_path)
        assert byte_size(digest) == 64

        assert digest ==
                 :crypto.hash(:sha256, File.read!(source_path))
                 |> Base.encode16(case: :lower)
      end
    end

    test "grouped and same-ID declarations keep path and group identity in stable keys and routes" do
      stories = [
        {"/z/subscriptions", AccrueAdmin.SubscriptionManifestFixture.Grouped},
        {"/a/subscriptions", AccrueAdmin.SubscriptionManifestFixture.Flat}
      ]

      entries = SubscriptionManifest.entries_for(stories, @storybook_root)
      reversed = SubscriptionManifest.entries_for(Enum.reverse(stories), @storybook_root)

      assert entries == reversed

      assert Enum.map(entries, &{&1.story_path, &1.group_id, &1.variation_id}) == [
               {"/a/subscriptions", nil, "shared"},
               {"/z/subscriptions", "lifecycle", "later"},
               {"/z/subscriptions", "lifecycle", "shared"}
             ]

      assert length(Enum.uniq(Enum.map(entries, & &1.key))) == length(entries)
      assert Enum.at(entries, 0).url != Enum.at(entries, 2).url

      assert URI.decode_query(URI.parse(Enum.at(entries, 1).url).query)["variation_id"] ==
               "lifecycle"

      assert SubscriptionManifest.route_matches?(Enum.at(entries, 1), Enum.at(entries, 1).url)
    end

    test "generated manifest verification rejects stale source digests before accepting routes" do
      assert function_exported?(SubscriptionManifest, :verify!, 1),
             "the generated manifest freshness verifier is unavailable"

      manifest_path =
        Path.join(
          System.tmp_dir!(),
          "phase252-manifest-#{System.unique_integer([:positive])}.json"
        )

      on_exit(fn -> File.rm(manifest_path) end)

      :ok = SubscriptionManifest.write!(manifest_path)
      assert :ok = SubscriptionManifest.verify!(manifest_path)
      first_write = File.read!(manifest_path)
      :ok = SubscriptionManifest.write!(manifest_path)
      assert File.read!(manifest_path) == first_write

      manifest = manifest_path |> File.read!() |> Jason.decode!()
      [{source_path, _digest} | _] = Enum.sort(manifest["source_digests"])

      [first_entry | remaining_entries] = manifest["entries"]

      wrong_route =
        NavigationHelpers.path_to_story(@storybook_root, @story_path, %{variation_id: "not-real"})

      tampered_entries = [Map.put(first_entry, "url", wrong_route) | remaining_entries]
      File.write!(manifest_path, Jason.encode!(%{manifest | "entries" => tampered_entries}))

      assert_raise ArgumentError, ~r/entries|routes/i, fn ->
        SubscriptionManifest.verify!(manifest_path)
      end

      stale_digests = Map.put(manifest["source_digests"], source_path, String.duplicate("0", 64))
      File.write!(manifest_path, Jason.encode!(%{manifest | "source_digests" => stale_digests}))

      assert_raise ArgumentError, ~r/source digest/i, fn ->
        SubscriptionManifest.verify!(manifest_path)
      end

      refute SubscriptionManifest.route_matches?(hd(SubscriptionManifest.entries()), wrong_route)
    end

    test "zero, duplicate, missing-ID, and missing-attribution declarations fail closed while one reconciles" do
      assert_raise ArgumentError, fn -> SubscriptionManifest.entries_for([], @storybook_root) end

      assert_raise ArgumentError, fn ->
        SubscriptionManifest.entries_for(
          [
            {"/same/subscriptions", AccrueAdmin.SubscriptionManifestFixture.Flat}
            | [{"/same/subscriptions", AccrueAdmin.SubscriptionManifestFixture.Flat}]
          ],
          @storybook_root
        )
      end

      assert_raise ArgumentError, fn ->
        SubscriptionManifest.entries_for(
          [{"/missing-id", AccrueAdmin.SubscriptionManifestFixture.MissingId}],
          @storybook_root
        )
      end

      assert_raise ArgumentError, fn ->
        SubscriptionManifest.entries_for(
          [{"/missing-attribution", AccrueAdmin.SubscriptionManifestFixture.MissingAttribution}],
          @storybook_root
        )
      end

      assert [%{variation_id: "shared"}] =
               SubscriptionManifest.entries_for(
                 [{"/one/subscription", AccrueAdmin.SubscriptionManifestFixture.Flat}],
                 @storybook_root
               )
    end

    test "caller map rejects empty and duplicate identities, retaining distinct same-label callers in stable order" do
      assert function_exported?(SubscriptionManifest, :caller_map_for, 1),
             "the caller-map normalizer is unavailable"

      assert_raise ArgumentError, ~r/zero|empty|caller/i, fn ->
        SubscriptionManifest.caller_map_for([])
      end

      one = caller_row("Subscription detail", "Owner A", "lib/a.ex", "area", "uncovered")
      assert [single] = SubscriptionManifest.caller_map_for([one])
      assert single.label == "Subscription detail"
      assert single.state == "uncovered"
      assert single.reason == "The current story does not render this caller."

      assert_raise ArgumentError, ~r/duplicate/i, fn ->
        SubscriptionManifest.caller_map_for([one, one])
      end

      same_label = [
        caller_row("Subscription detail", "Owner B", "lib/b.ex", "page", "uncovered"),
        caller_row("Subscription detail", "Owner A", "lib/a.ex", "area", "uncovered")
      ]

      rows = SubscriptionManifest.caller_map_for(same_label)
      assert rows == SubscriptionManifest.caller_map_for(Enum.reverse(same_label))
      assert Enum.map(rows, & &1.label) == ["Subscription detail", "Subscription detail"]
      assert length(Enum.uniq(Enum.map(rows, & &1.key))) == 2

      assert Enum.map(rows, &{&1.owner, &1.path, &1.tier, &1.state}) == [
               {"Owner A", "lib/a.ex", "area", "uncovered"},
               {"Owner B", "lib/b.ex", "page", "uncovered"}
             ]
    end

    test "current caller map reconciles production sources, registry contracts, manifest links, and explicit gaps" do
      assert function_exported?(SubscriptionManifest, :caller_map, 0),
             "the production caller map is unavailable"

      rows = SubscriptionManifest.caller_map()
      entries = SubscriptionManifest.entries()
      keys = Enum.map(entries, & &1.key) |> Enum.sort()
      by_owner = Map.new(rows, &{{&1.owner, &1.tier}, &1})

      assert rows == SubscriptionManifest.caller_map_for(rows)
      assert Enum.all?(rows, &(&1.state in ["reachable", "uncovered", "not_applicable"]))
      assert Enum.all?(rows, &(&1.evidence != "" and is_binary(&1.path)))

      for row <- rows, row.state != "reachable" do
        assert is_binary(row.reason) and row.reason != ""
      end

      for owner <- [
            "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
            "AccrueAdmin.Live.SubscriptionLive.render/1",
            "AccrueAdmin.Live.SubscriptionsLive.render/1",
            "AccruePortal.Live.SubscriptionLive.render/1",
            "AccruePortal.Live.SubscriptionsLive.render/1"
          ] do
        assert Enum.any?(rows, &(&1.owner == owner)), "missing current production owner #{owner}"
      end

      area = by_owner[{"AccrueAdmin.Live.SubscriptionLive.subscription_area/1", "area"}]
      action_band = by_owner[{"AccrueAdmin.Live.SubscriptionLive.subscription_area/1", "section"}]
      page = by_owner[{"AccrueAdmin.Live.SubscriptionLive.render/1", "page"}]
      group = Enum.find(rows, &(&1.tier == "group"))

      assert area.state == "reachable"
      assert action_band.state == "reachable"
      assert area.manifest_keys == keys
      assert action_band.manifest_keys == keys
      assert page.state == "uncovered"
      assert page.reason =~ "whole-page"

      contract =
        AccrueAdmin.Dev.ComponentRegistry.group_contract_by_slug(group.contract)

      assert group.state == "uncovered"
      assert group.evidence =~ contract.proof_id
      assert group.owner == "AccrueAdmin.Dev.ComponentRegistry.group_contracts/0"

      assert Enum.any?(rows, &(&1.tier == "job" and &1.path =~ "accrue_portal"))

      na = Enum.find(rows, &(&1.state == "not_applicable"))
      assert na.tier == "proof-lane"
      assert na.reason =~ "static render"

      root = Path.expand("../../../../", __DIR__)
      guide_path = Path.join(root, "guides/subscription-story-coverage.md")
      :ok = SubscriptionManifest.write_coverage_guide!(guide_path)
      guide = File.read!(guide_path)
      assert guide =~ "Production caller and composition coverage"
      assert guide =~ "Uncovered"
      assert guide =~ "Not applicable"
      assert guide =~ "AccruePortal.Live.SubscriptionsLive.render/1"
      assert guide =~ "does not prove a whole page"
    end

    test "generated guide preserves Phase 253 compiled routes and their presentation proof limits" do
      assert Code.ensure_loaded?(SubscriptionCompositionsManifest)

      collection_entries = SubscriptionCompositionsManifest.collection_variation_entries()
      page_entries = SubscriptionCompositionsManifest.page_entries()
      entries = SubscriptionManifest.entries()

      assert length(collection_entries) == 10
      assert length(page_entries) == 9
      # AMD-254-01: the live entry count derives from the ledger (frozen baseline minus retired);
      # the frozen 6 stays alive as the baseline fixture positive control.
      ledger = SubscriptionManifest.curation_ledger()

      retired =
        Enum.count(ledger.records, fn record ->
          record.disposition in ["retire", "merge"] and
            record.subject.story_path == @story_path and record.subject.variation_id != nil
        end)

      assert ledger.frozen_baseline.entries == 6
      assert length(entries) == ledger.frozen_baseline.entries - retired

      root = Path.expand("../../../../", __DIR__)
      guide_path = Path.join(root, "guides/subscription-story-coverage.md")
      :ok = SubscriptionManifest.write_coverage_guide!(guide_path)
      guide = File.read!(guide_path)

      assert guide =~ "## Phase 253 compiled composition supplement"

      assert guide =~
               "Phase 252's six canonical component entries and coverage assertions remain unchanged."

      assert guide =~
               "Phase 253's compiled composition supplement below documents the Admin whole-page and collection stories. Mounted route and action-journey behavior is verified separately."

      refute guide =~ "Admin whole-page/list/action-journey work remains in Phase 253."

      assert guide =~
               "Presentation-only evidence covers settled appearance; it does not establish mounted authority, persistence, dispatch, or provider completion."

      for entry <- collection_entries do
        assert guide =~ entry.direct_path
        assert guide =~ entry.iframe_path
        assert guide =~ entry.production_renderer
        assert guide =~ entry.fact_source
        assert guide =~ entry.proof_lane
      end

      for entry <- page_entries do
        assert guide =~ entry.direct_path
        assert guide =~ entry.production_renderer
        assert guide =~ entry.fact_source
        assert guide =~ entry.presentation_snapshot
        assert guide =~ entry.proof_lane
      end
    end

    test "curation ledger pins a frozen baseline whose subjects, digest and counts never read the current tree" do
      baseline = SubscriptionManifest.frozen_baseline()

      assert baseline.entries == 6
      assert baseline.compatibility_ids == ["braintree_pruned", "dunning_active", "populated"]
      assert baseline.source_commit =~ ~r/\A[0-9a-f]{40}\z/
      assert baseline.manifest_sha256 =~ ~r/\A[0-9a-f]{64}\z/
      assert map_size(baseline.kitchen_test_digests) > 0

      assert Map.keys(baseline.registry) |> Enum.sort() ==
               [:entry_count, :family_count, :specimen_count]

      subjects = baseline.subjects
      keys = Enum.map(subjects, &{&1.story_path, &1.variation_id})

      assert keys == Enum.sort(keys)
      assert Enum.uniq(keys) == keys
      assert length(subjects) == 26
      assert SubscriptionManifest.subjects_digest(subjects) == baseline.subjects_sha256

      # Positive controls for the two subjects 254-06 later removes.
      assert {"/components/subscription_detail", "populated"} in keys
      assert {"/components/action_menu", "provider_pruned"} in keys

      assert subjects |> Enum.count(&(&1.story_path == "/components/page_header")) == 6

      assert subjects |> Enum.map(& &1.source_path) |> Enum.uniq() |> Enum.sort() ==
               baseline.subject_sources

      # Pinned data: two calls return the identical term and the digest of a tampered list differs.
      assert SubscriptionManifest.frozen_baseline() == baseline
      refute SubscriptionManifest.subjects_digest(tl(subjects)) == baseline.subjects_sha256
    end

    test "curation records are sorted, shaped, grounded in the frozen baseline and refuse invalid input" do
      records = SubscriptionManifest.curation_records()
      baseline = SubscriptionManifest.frozen_baseline()
      ids = Enum.map(records, & &1.id)

      assert ids == Enum.sort(ids)
      assert Enum.uniq(ids) == ids
      assert Enum.all?(ids, &(&1 =~ ~r/\ACUR-254-\d{2,}\z/))

      for record <- records do
        assert record.disposition in ["retire", "merge", "retain", "reclassify"]
        assert record.kitchen_impact == "none"
        assert record.reachability.state in ["reachable", "historic_supported", "unreachable"]
        assert record.reachability.evidence != []
        assert record.preserved_regressions != []
        assert record.provenance.origin_commit == baseline.source_commit

        assert Enum.any?(baseline.subjects, fn subject ->
                 subject.story_path == record.subject.story_path and
                   (record.subject.variation_id == nil or
                      subject.variation_id == record.subject.variation_id)
               end)
      end

      [first | _] = records
      assert SubscriptionManifest.curation_records_for(Enum.reverse(records)) == records

      assert_raise ArgumentError, ~r/absent from the frozen baseline/, fn ->
        SubscriptionManifest.curation_records_for([
          put_in(first, [:subject, :story_path], "/components/never_existed")
        ])
      end

      assert_raise ArgumentError, ~r/unsupported disposition/, fn ->
        SubscriptionManifest.curation_records_for([%{first | disposition: "delete"}])
      end

      assert_raise ArgumentError, ~r/kitchen_impact none/, fn ->
        SubscriptionManifest.curation_records_for([%{first | kitchen_impact: "minor"}])
      end

      assert_raise ArgumentError, ~r/needs a reason class/, fn ->
        SubscriptionManifest.curation_records_for([%{first | disposition: "retire"}])
      end

      assert_raise ArgumentError, ~r/duplicate curation record id/, fn ->
        SubscriptionManifest.curation_records_for([first, first])
      end
    end

    test "duplicate evidence is exact block equality and any differing field keeps both subjects" do
      by_id = Map.new(SubscriptionManifest.entries(), &{&1.variation_id, &1})

      alias_evidence = SubscriptionManifest.duplicate_evidence(by_id["populated"], by_id["active"])
      assert alias_evidence.subject == alias_evidence.survivor

      distinct =
        SubscriptionManifest.duplicate_evidence(by_id["braintree_pruned"], by_id["active"])

      refute distinct.subject == distinct.survivor

      one_field =
        SubscriptionManifest.duplicate_evidence(
          by_id["populated"],
          put_in(by_id["active"], [:expected, :facts, :amount_minor], 1)
        )

      refute one_field.subject == one_field.survivor
    end

    test "curation ledger regenerates byte-identically and an interrupted regeneration leaves the committed ledger intact" do
      path =
        Path.join(System.tmp_dir!(), "phase254-curation-#{System.unique_integer([:positive])}.json")

      on_exit(fn -> File.rm(path) end)

      :ok = SubscriptionManifest.write_curation!(path)
      first = File.read!(path)
      :ok = SubscriptionManifest.write_curation!(path)
      assert File.read!(path) == first
      assert :ok = SubscriptionManifest.verify_curation!(path)

      decoded = Jason.decode!(first)

      assert Map.keys(decoded) |> Enum.sort() ==
               ["amendments", "current", "frozen_baseline", "records", "schema_version", "source_digests"]

      assert decoded["source_digests"] == SubscriptionManifest.source_digests()
      assert decoded["records"] |> Enum.map(& &1["id"]) == decoded["records"] |> Enum.map(& &1["id"]) |> Enum.sort()
      assert Enum.any?(decoded["amendments"], &(&1["id"] == "AMD-254-01"))

      interrupted = fn temp, json ->
        File.write!(temp, json)
        raise "writer interrupted after the temp write and before the rename"
      end

      assert_raise RuntimeError, ~r/interrupted/, fn ->
        SubscriptionManifest.write_curation!(path, writer: interrupted)
      end

      assert File.read!(path) == first

      leftovers =
        path |> Path.dirname() |> File.ls!() |> Enum.filter(&String.starts_with?(&1, Path.basename(path) <> ".tmp-"))

      assert leftovers == []

      fresh_dir = Path.join(System.tmp_dir!(), "phase254-curation-new-#{System.unique_integer([:positive])}")
      on_exit(fn -> File.rm_rf(fresh_dir) end)
      target = Path.join(fresh_dir, "ledger.json")

      assert_raise RuntimeError, ~r/interrupted/, fn ->
        SubscriptionManifest.write_curation!(target, writer: interrupted)
      end

      refute File.exists?(target), "an interrupted first write must not leave a partial ledger"

      File.write!(path, Jason.encode!(Map.put(decoded, "records", [])))

      assert_raise ArgumentError, ~r/curation ledger is stale/, fn ->
        SubscriptionManifest.verify_curation!(path)
      end
    end

    test "committed curation ledger is current and the guide renders every record in a deterministic curation section" do
      root = Path.expand("../../../../", __DIR__)
      committed = Path.join(root, "accrue_admin/storybook/subscription-curation.json")
      assert :ok = SubscriptionManifest.verify_curation!(committed)

      guide = SubscriptionManifest.coverage_guide()
      assert guide == SubscriptionManifest.coverage_guide()
      assert guide =~ "## Curation ledger"
      assert guide =~ "AMD-254-01"

      for record <- SubscriptionManifest.curation_records() do
        assert guide =~ record.id
      end
    end

    test "braintree_pruned and dunning_active are retained and reclassified with the recovery claim drift recorded" do
      records = Map.new(SubscriptionManifest.curation_records(), &{&1.id, &1})

      assert records |> Map.keys() |> Enum.sort() ==
               ["CUR-254-01", "CUR-254-02", "CUR-254-03", "CUR-254-04", "CUR-254-05"]

      braintree = records["CUR-254-04"]
      assert braintree.disposition == "reclassify"
      assert braintree.classification == "provider-boundary negative"
      assert braintree.subject.variation_id == "braintree_pruned"
      assert braintree.survivor == %{kind: "manifest_entry", key: "#{@story_path}||braintree_pruned"}

      assert Enum.any?(
               braintree.preserved_regressions,
               &(&1.test_ref =~ "provider-pruned empty action groups are omitted")
             )

      dunning = records["CUR-254-05"]
      assert dunning.disposition == "reclassify"
      assert dunning.subject.variation_id == "dunning_active"
      assert dunning.reason =~ "recovery drill open"
      assert dunning.reason =~ "Dunning row"
      assert dunning.reason =~ "retry/campaign-history integrity"
      assert dunning.gap.entry_trigger == "retry/campaign-history integrity"
      assert dunning.survivor == %{kind: "manifest_entry", key: "#{@story_path}||dunning_active"}

      # No variation is removed and no id changes: all six entries are still discovered.
      by_id = Map.new(SubscriptionManifest.entries(), &{&1.variation_id, &1})
      assert map_size(by_id) == 6

      assert by_id["braintree_pruned"].curation_record == "CUR-254-04"
      assert by_id["braintree_pruned"].curation_classification == "provider-boundary negative"
      assert by_id["dunning_active"].curation_record == "CUR-254-05"

      for id <- ["active", "scheduled_cancellation", "incomplete_evidence", "populated"] do
        assert by_id[id].curation_record == nil
        assert by_id[id].curation_classification == nil
      end
    end

    test "the regenerated guide lists every curation record, keeps the whole-page limit, and is deterministic" do
      guide = SubscriptionManifest.coverage_guide()
      assert guide == SubscriptionManifest.coverage_guide()
      assert guide =~ "does not prove a whole page"

      for id <- ["CUR-254-01", "CUR-254-02", "CUR-254-03", "CUR-254-04", "CUR-254-05"] do
        assert guide =~ id
      end

      assert guide =~ "provider-boundary negative"
      assert guide =~ "retry/campaign-history integrity"

      dir = Path.join(System.tmp_dir!(), "phase254-guide-#{System.unique_integer([:positive])}")
      on_exit(fn -> File.rm_rf(dir) end)
      first = Path.join(dir, "first.md")
      second = Path.join(dir, "second.md")
      :ok = SubscriptionManifest.write_coverage_guide!(first)
      :ok = SubscriptionManifest.write_coverage_guide!(second)
      assert File.read!(first) == File.read!(second)
    end

    defp caller_row(label, owner, path, tier, state) do
      %{
        label: label,
        owner: owner,
        path: path,
        tier: tier,
        state: state,
        evidence: "#{path}:1",
        reason: if(state == "uncovered", do: "The current story does not render this caller."),
        manifest_keys: []
      }
    end

    setup_all do
      previous_accrue_env = Application.get_env(:accrue, :env, :unset)
      previous_locale = Application.get_env(:localize, :default_locale, :unset)
      Application.put_env(:accrue, :env, :test)
      Application.put_env(:localize, :default_locale, :en)
      {:ok, _started} = Application.ensure_all_started(:localize)

      on_exit(fn ->
        case previous_accrue_env do
          :unset -> Application.delete_env(:accrue, :env)
          value -> Application.put_env(:accrue, :env, value)
        end

        case previous_locale do
          :unset -> Application.delete_env(:localize, :default_locale)
          value -> Application.put_env(:localize, :default_locale, value)
        end
      end)

      :ok
    end

    defp key(path, group_id, variation_id) do
      Enum.join([path, group_id || "", variation_id], "|")
    end
  end
end
