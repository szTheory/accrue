if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.SubscriptionManifest do
    @moduledoc false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Storybook.SubscriptionScenarios
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}
    alias PhoenixStorybook.Stories.{Variation, VariationGroup}

    @storybook_root "/dev/storybook"
    @subscription_story_path "/components/subscription_detail"
    @source_paths [
      "accrue_admin/lib/accrue_admin/dev/storybook.ex",
      "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
      "accrue_admin/storybook/_support/subscription_manifest.ex",
      "accrue_admin/storybook/_support/subscription_scenarios.ex",
      "dev_support/ui_scenarios/cadence_subscriptions.exs",
      "storybook/components/subscription_detail.story.exs"
    ]

    @doc "Discovers retained subscription variations from the compiled PhoenixStorybook backend."
    @spec entries() :: [map()]
    def entries do
      selected = Enum.filter(Storybook.leaves(), &(&1.path == @subscription_story_path))

      case selected do
        [%StoryEntry{path: path}] ->
          case Storybook.load_story(String.trim_leading(path, "/")) do
            {:ok, story} ->
              entries_for([{path, story}], @storybook_root)

            {:error, reason} ->
              raise ArgumentError, "subscription story could not be loaded: #{inspect(reason)}"
          end

        [] ->
          raise ArgumentError,
                "compiled PhoenixStorybook tree is missing #{@subscription_story_path}"

        _ ->
          raise ArgumentError,
                "compiled PhoenixStorybook tree contains duplicate #{@subscription_story_path} leaves"
      end
    end

    @doc "Builds stable entries from compiled story modules; useful for validating fixture trees."
    @spec entries_for([{String.t(), module()}], String.t()) :: [map()]
    def entries_for(stories, root_path) when is_list(stories) and is_binary(root_path) do
      entries =
        stories
        |> Enum.flat_map(fn
          {path, story} when is_binary(path) and is_atom(story) ->
            validate_story_path!(path)
            validate_story_module!(story)

            story
            |> apply(:variations, [])
            |> flatten_variations!(path)
            |> Enum.map(fn {group_id, variation} ->
              entry!(path, group_id, variation, root_path)
            end)

          other ->
            raise ArgumentError, "invalid compiled subscription story source: #{inspect(other)}"
        end)

      if entries == [] do
        raise ArgumentError, "compiled subscription story tree contains zero variations"
      end

      duplicate =
        entries
        |> Enum.group_by(& &1.key)
        |> Enum.find(fn {_key, same_key} -> length(same_key) > 1 end)

      if duplicate do
        {key, _entries} = duplicate
        raise ArgumentError, "duplicate subscription story path/group/variation key: #{key}"
      end

      Enum.sort_by(entries, &{&1.story_path, &1.group_id || "", &1.variation_id})
    end

    def entries_for(_stories, _root_path),
      do: raise(ArgumentError, "subscription stories and Storybook root must be provided")

    @doc "Hashes the real source files consumed by this generated manifest."
    @spec source_digests() :: %{String.t() => String.t()}
    def source_digests do
      root = repository_root()

      @source_paths
      |> Enum.sort()
      |> Map.new(fn relative_path ->
        path = Path.join(root, relative_path)

        unless File.regular?(path) do
          raise ArgumentError, "manifest source file is missing: #{relative_path}"
        end

        digest = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
        {relative_path, digest}
      end)
    end

    @doc "Writes the deterministic generated manifest to the requested path."
    @spec write!(Path.t()) :: :ok
    def write!(path) when is_binary(path) do
      contents = %{
        schema_version: 1,
        source_digests: source_digests(),
        entries: entries()
      }

      json = Jason.encode!(contents, pretty: true) <> "\n"
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, json)
    end

    @doc "Rejects a generated manifest whose source digests, declarations, or direct routes drifted."
    @spec verify!(Path.t()) :: :ok
    def verify!(path) when is_binary(path) do
      manifest = path |> File.read!() |> Jason.decode!()

      unless manifest["schema_version"] == 1 do
        raise ArgumentError, "subscription manifest has an unsupported schema version"
      end

      unless manifest["source_digests"] == source_digests() do
        raise ArgumentError, "subscription manifest source digest is stale"
      end

      current_entries = entries() |> Jason.encode!() |> Jason.decode!()

      unless manifest["entries"] == current_entries do
        raise ArgumentError, "subscription manifest entries or direct routes are stale"
      end

      unless Enum.all?(manifest["entries"], &route_matches?(&1, Map.get(&1, "url"))) do
        raise ArgumentError, "subscription manifest contains an invalid direct route"
      end

      :ok
    end

    @doc "Checks that a direct URL still names the entry's compiled story and variation route."
    @spec route_matches?(map(), String.t()) :: boolean()
    def route_matches?(entry, url) when is_map(entry) and is_binary(url) do
      expected_url = Map.get(entry, :url, Map.get(entry, "url"))
      variation_id = Map.get(entry, :route_variation_id, Map.get(entry, "route_variation_id"))

      if is_binary(expected_url) and is_binary(variation_id) do
        expected = URI.parse(expected_url)
        actual = URI.parse(url)
        query = URI.decode_query(actual.query || "")

        actual.scheme == expected.scheme and actual.host == expected.host and
          actual.path == expected.path and query["variation_id"] == variation_id
      else
        false
      end
    rescue
      ArgumentError -> false
    end

    def route_matches?(_entry, _url), do: false

    defp flatten_variations!(variations, path) when is_list(variations) do
      flattened =
        Enum.flat_map(variations, fn
          %Variation{id: id} = variation ->
            validate_id!(id, "variation", path)
            [{nil, variation}]

          %VariationGroup{id: group_id, variations: grouped} ->
            validate_id!(group_id, "variation group", path)

            if not is_list(grouped) or grouped == [] do
              raise ArgumentError, "variation group #{group_id} in #{path} contains no variations"
            end

            Enum.map(grouped, fn
              %Variation{id: id} = variation ->
                validate_id!(id, "grouped variation", path)
                {group_id, variation}

              other ->
                raise ArgumentError,
                      "variation group #{group_id} in #{path} contains a non-Variation: #{inspect(other)}"
            end)

          other ->
            raise ArgumentError,
                  "subscription story #{path} contains an unsupported declaration: #{inspect(other)}"
        end)

      if flattened == [] do
        raise ArgumentError, "subscription story #{path} contains zero variations"
      end

      flattened
    end

    defp flatten_variations!(_variations, path),
      do: raise(ArgumentError, "subscription story #{path} variations must be a list")

    defp entry!(path, group_id, %Variation{id: variation_id, attributes: attributes}, root_path) do
      validate_id!(variation_id, "variation", path)
      if group_id, do: validate_id!(group_id, "variation group", path)

      unless is_map(attributes) do
        raise ArgumentError,
              "subscription variation #{inspect(variation_id)} in #{path} is missing attribution"
      end

      scenario = Map.get(attributes, :scenario)

      unless is_atom(scenario) and not is_nil(scenario) do
        raise ArgumentError,
              "subscription variation #{inspect(variation_id)} in #{path} is missing a scenario ID"
      end

      metadata = SubscriptionScenarios.attributes(scenario)

      unless attributes == metadata do
        raise ArgumentError,
              "subscription variation #{inspect(variation_id)} in #{path} has missing or unknown attribution"
      end

      facts = SubscriptionScenarios.validate!(attributes)
      route_variation_id = group_id || variation_id
      key = key(path, group_id, variation_id)

      %{
        key: key,
        story_path: path,
        group_id: if(group_id, do: to_string(group_id)),
        variation_id: to_string(variation_id),
        route_variation_id: to_string(route_variation_id),
        url:
          NavigationHelpers.path_to_story(root_path, path, %{variation_id: route_variation_id}),
        actor: Map.fetch!(metadata, :actor),
        job: Map.fetch!(metadata, :job),
        input_source: Map.fetch!(metadata, :input_source),
        production_renderer: Map.fetch!(metadata, :production_renderer),
        composition_tier: "component",
        proof_lane: Map.fetch!(metadata, :proof_lane),
        scenario_id: Atom.to_string(scenario),
        expected: expected_facts(facts, metadata)
      }
    end

    defp expected_facts(facts, metadata) do
      %{
        identity: %{
          actor: metadata.actor,
          owner_slug: facts.owner.slug,
          customer_id: facts.customer.id,
          customer_processor_id: facts.customer.processor_id,
          customer_name: facts.customer.name,
          subscription_id: facts.subscription.id,
          subscription_processor_id: facts.subscription.processor_id
        },
        lifecycle: %{
          status: Atom.to_string(facts.subscription.status),
          cancel_at_period_end: facts.subscription.cancel_at_period_end,
          current_period_start: datetime(facts.subscription.current_period_start),
          current_period_end: datetime(facts.subscription.current_period_end)
        },
        facts: %{
          amount_minor: facts.billing.amount_minor,
          currency: Atom.to_string(facts.billing.currency),
          price_ids: Enum.map(facts.subscription.items, & &1.price_id),
          quantities: Enum.map(facts.subscription.items, & &1.quantity)
        },
        actions: %{
          owner: metadata.production_renderer,
          proof: "rendered by production eligibility; no action dispatch claim"
        }
      }
    end

    defp datetime(nil), do: nil
    defp datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)

    defp key(path, group_id, variation_id) do
      Enum.join([path, group_id || "", variation_id], "|")
    end

    defp validate_id!(id, kind, path) do
      if is_atom(id) and not is_nil(id) and Atom.to_string(id) != "" do
        id
      else
        raise ArgumentError,
              "#{kind} ID must be a non-empty atom in #{path}, got: #{inspect(id)}"
      end
    end

    defp validate_story_path!(path) do
      if not String.starts_with?(path, "/") or path == "/" do
        raise ArgumentError,
              "subscription story path must be an absolute Storybook path, got: #{inspect(path)}"
      end
    end

    defp validate_story_module!(story) do
      unless Code.ensure_loaded?(story) and function_exported?(story, :variations, 0) do
        raise ArgumentError,
              "compiled subscription story does not export variations/0: #{inspect(story)}"
      end
    end

    defp repository_root do
      Path.expand("../../../", __DIR__)
    end
  end
end
