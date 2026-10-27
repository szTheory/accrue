if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.SubscriptionCompositionsManifest do
    @moduledoc false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Storybook.SubscriptionScenarios
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}
    alias PhoenixStorybook.Stories.{Variation, VariationGroup}

    @storybook_root "/dev/storybook"
    @mounted_storybook_root "/billing/dev/storybook"
    @story_path "/groups/subscriptions_collection"
    @required_variation "one_row"
    @renderer "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1"
    @query_module "AccrueAdmin.Storybook.SubscriptionCollectionQuery"
    @source_paths [
      "accrue_admin/lib/accrue_admin/dev/storybook.ex",
      "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
      "accrue_admin/lib/accrue_admin/queries/subscriptions.ex",
      "accrue_admin/lib/accrue_admin/router.ex",
      "accrue_admin/storybook/_support/subscription_collection.ex",
      "accrue_admin/storybook/_support/subscription_compositions_manifest.ex",
      "dev_support/ui_scenarios/cadence_subscriptions.exs",
      "storybook/groups/subscriptions_collection.story.exs"
    ]

    @doc "Discovers the collection composition from the compiled PhoenixStorybook tree."
    @spec entries() :: [map()]
    def entries do
      case Enum.filter(Storybook.leaves(), &(&1.path == @story_path)) do
        [%StoryEntry{path: path}] ->
          case Storybook.load_story(String.trim_leading(path, "/")) do
            {:ok, story} ->
              unless to_string(story.storybook_type()) == "live_component" do
                raise ArgumentError,
                      "compiled collection story must use the mounted LiveComponent transport"
              end

              entries_for([{path, story}], @storybook_root)

            {:error, reason} ->
              raise ArgumentError,
                    "compiled collection story could not be loaded: #{inspect(reason)}"
          end

        [] ->
          raise ArgumentError, "compiled Storybook tree is missing #{@story_path}"

        _duplicates ->
          raise ArgumentError, "compiled Storybook tree contains duplicate #{@story_path} leaves"
      end
    end

    @doc "Builds a stable, narrow projection from compiled collection stories."
    @spec entries_for([{String.t(), module()}], String.t()) :: [map()]
    def entries_for(stories, root_path) when is_list(stories) and is_binary(root_path) do
      entries =
        stories
        |> Enum.flat_map(fn
          {@story_path = path, story} when is_atom(story) ->
            validate_story!(story)

            story
            |> apply(:variations, [])
            |> flatten_variations!(path)
            |> Enum.map(fn {group_id, variation} ->
              entry!(path, group_id, variation, root_path)
            end)

          {path, _story} ->
            raise ArgumentError,
                  "unexpected subscription composition story path: #{inspect(path)}"

          other ->
            raise ArgumentError, "invalid compiled collection story source: #{inspect(other)}"
        end)

      if entries == [] do
        raise ArgumentError, "compiled collection story contains zero variations"
      end

      duplicate =
        entries
        |> Enum.group_by(& &1.key)
        |> Enum.find(fn {_key, same_key} -> length(same_key) > 1 end)

      if duplicate do
        {key, _entries} = duplicate
        raise ArgumentError, "duplicate collection path/group/variation identity: #{key}"
      end

      unless Enum.count(entries, &(&1.variation_id == @required_variation)) == 1 do
        raise ArgumentError, "compiled collection story is missing the unique one_row variation"
      end

      Enum.sort_by(entries, &{&1.story_path, &1.group_id || "", &1.variation_id})
    end

    def entries_for(_stories, _root_path),
      do: raise(ArgumentError, "collection stories and Storybook root must be provided")

    @doc "Hashes the source files that determine the direct collection preview."
    @spec source_digests() :: %{String.t() => String.t()}
    def source_digests do
      root = repository_root()

      @source_paths
      |> Enum.sort()
      |> Map.new(fn relative_path ->
        path = Path.join(root, relative_path)

        unless File.regular?(path) do
          raise ArgumentError, "collection manifest source is missing: #{relative_path}"
        end

        digest = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
        {relative_path, digest}
      end)
    end

    @doc "Writes the current compiled collection and transport to the requested JSON path."
    @spec write!(Path.t()) :: :ok
    def write!(path) when is_binary(path) do
      current_entries = entries()

      contents = %{
        schema_version: 1,
        human_judgment: false,
        source_digests: source_digests(),
        transport: transport!(current_entries),
        entries: current_entries
      }

      json = Jason.encode!(contents, pretty: true) <> "\n"
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, json)
    end

    @doc "Rejects stale compiled routes, source digests, or the task 1 transport proof."
    @spec verify!(Path.t()) :: :ok
    def verify!(path) when is_binary(path) do
      manifest = path |> File.read!() |> Jason.decode!()

      unless manifest["schema_version"] == 1 and manifest["human_judgment"] == false do
        raise ArgumentError, "collection manifest has an unsupported schema or judgment mode"
      end

      unless manifest["source_digests"] == source_digests() do
        raise ArgumentError, "collection manifest source digest is stale"
      end

      current_entries = entries() |> Jason.encode!() |> Jason.decode!()

      unless manifest["entries"] == current_entries do
        raise ArgumentError, "collection manifest entries or direct routes are stale"
      end

      current_transport = transport!(entries())

      unless manifest["transport"] == current_transport do
        raise ArgumentError, "collection manifest transport evidence is stale"
      end

      unless Enum.all?(manifest["entries"], &route_matches?(&1, Map.get(&1, "url"))) do
        raise ArgumentError, "collection manifest contains an invalid direct route"
      end

      :ok
    end

    @doc "Checks that a URL resolves to the compiled path and selected variation."
    @spec route_matches?(map(), String.t()) :: boolean()
    def route_matches?(entry, url) when is_map(entry) and is_binary(url) do
      expected_url = Map.get(entry, :url, Map.get(entry, "url"))
      variation_id = Map.get(entry, :route_variation_id, Map.get(entry, "route_variation_id"))

      if is_binary(expected_url) and is_binary(variation_id) do
        expected = URI.parse(expected_url)
        actual = URI.parse(url)
        query = URI.decode_query(actual.query || "")

        actual.scheme == expected.scheme and actual.host == expected.host and
          actual.path == expected.path and query == %{"variation_id" => variation_id}
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
          %VariationGroup{id: group_id, variations: group_variations}
          when is_list(group_variations) ->
            validate_id!(group_id, "variation group", path)

            Enum.map(group_variations, fn
              %Variation{} = variation -> {group_id, variation}
              other -> raise ArgumentError, "invalid variation in #{path}: #{inspect(other)}"
            end)

          %Variation{} = variation ->
            [{nil, variation}]

          other ->
            raise ArgumentError, "unsupported collection variation declaration: #{inspect(other)}"
        end)

      if flattened == [] do
        raise ArgumentError, "compiled collection story #{path} contains zero variations"
      end

      flattened
    end

    defp flatten_variations!(_variations, path),
      do: raise(ArgumentError, "collection story #{path} variations must be a list")

    defp entry!(path, group_id, %Variation{id: variation_id, attributes: attributes}, root_path) do
      validate_id!(variation_id, "variation", path)
      if group_id, do: validate_id!(group_id, "variation group", path)

      scenario = if is_map(attributes), do: Map.get(attributes, :scenario)

      unless is_map(attributes) and attributes == %{scenario: scenario} and
               scenario in [:launch, :growing_team] do
        raise ArgumentError,
              "collection variation #{inspect(variation_id)} in #{path} needs only a launch or growing_team fact"
      end

      facts = scenario |> CadenceSubscriptionFacts.fetch!() |> SubscriptionScenarios.validate!()
      route_variation_id = group_id || variation_id
      route_id = to_string(route_variation_id)

      url =
        NavigationHelpers.path_to_story(root_path, String.trim_leading(path, "/"), %{
          variation_id: route_id
        })

      %{
        key: key(path, group_id, variation_id),
        story_path: path,
        group_id: if(group_id, do: to_string(group_id)),
        variation_id: to_string(variation_id),
        route_variation_id: route_id,
        url: url,
        direct_path: @mounted_storybook_root <> String.replace_prefix(url, @storybook_root, ""),
        transport_kind: "live_component",
        production_renderer: @renderer,
        query_module: @query_module,
        fact_source: "CadenceSubscriptionFacts.fetch!(:#{scenario})",
        proof_lane: "presentation-only",
        expected: %{
          subscription_id: facts.subscription.id,
          processor_id: facts.subscription.processor_id,
          customer_name: facts.customer.name,
          customer_email: facts.customer.email,
          owner_slug: facts.owner.slug,
          status: Atom.to_string(facts.subscription.status),
          plan_price_id: hd(facts.subscription.items).price_id,
          plan_quantity: hd(facts.subscription.items).quantity,
          amount_state: "unavailable"
        }
      }
    end

    defp transport!(entries) do
      root = repository_root()
      path = Path.join(root, "accrue_admin/tmp/phase253/transport.json")

      unless File.regular?(path) do
        raise ArgumentError, "current-run task 1 transport.json is missing"
      end

      transport = path |> File.read!() |> Jason.decode!()
      [one_row] = Enum.filter(entries, &(&1.variation_id == @required_variation))

      expected = %{
        "direct_path" => one_row.direct_path,
        "fact_sources" => [
          "CadenceSubscriptionFacts.fetch!(:launch)",
          "CadenceSubscriptionFacts.fetch!(:growing_team)"
        ],
        "mounted_event" => "load-more targeted to the DataTable LiveComponent",
        "query_module" => @query_module,
        "renderer" => @renderer,
        "schema_version" => 1,
        "story_module" => "AccrueAdmin.Storybook.Groups.SubscriptionsCollection",
        "story_path" => @story_path,
        "transport_kind" => "live_component"
      }

      unless Map.take(transport, Map.keys(expected)) == expected do
        raise ArgumentError,
              "task 1 transport evidence does not match the compiled collection route"
      end

      expected
    rescue
      MatchError ->
        raise ArgumentError, "transport evidence must include the one_row collection variation"
    end

    defp validate_story!(story) do
      unless Code.ensure_loaded?(story) and function_exported?(story, :variations, 0) do
        raise ArgumentError,
              "compiled collection story does not export variations/0: #{inspect(story)}"
      end
    end

    defp validate_id!(id, kind, path) do
      if is_atom(id) and not is_nil(id) and Atom.to_string(id) != "" do
        id
      else
        raise ArgumentError, "#{kind} ID must be a non-empty atom in #{path}, got: #{inspect(id)}"
      end
    end

    defp key(path, group_id, variation_id),
      do: Enum.join([path, group_id || "", variation_id], "|")

    defp repository_root, do: Path.expand("../../../", __DIR__)
  end
end
