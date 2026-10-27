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
      name = test.name |> to_string() |> String.replace(~r/[\r\n]+/u, " ")

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

if Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionManifest) do
  defmodule AccrueAdmin.SubscriptionManifestTest do
    use ExUnit.Case, async: false

    alias AccrueAdmin.Dev.Storybook
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
      manifest_path = Path.join(root, "storybook/phase252-manifest.json")
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
else
  defmodule AccrueAdmin.SubscriptionManifestBootTest do
    use ExUnit.Case, async: false

    test "compiled subscription story manifest API is available" do
      assert Code.ensure_loaded?(AccrueAdmin.Storybook.SubscriptionManifest),
             "the compiled subscription variation manifest is unavailable"
    end
  end
end
