if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.SubscriptionCompositionsManifest do
    @moduledoc false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Storybook.SubscriptionScenarios
    alias AccrueAdmin.Storybook.SubscriptionPageScenarios
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}
    alias PhoenixStorybook.Stories.{Variation, VariationGroup}

    @storybook_root "/dev/storybook"
    @mounted_storybook_root "/billing/dev/storybook"
    @story_path "/groups/subscriptions_collection"
    @page_story_path "/pages/subscription"
    @required_variation "one_row"
    @required_variation_id :one_row
    @collection_states ~w(new_host_empty filtered_empty queue_empty one_row multiple_rows page_boundary loading unavailable partial_cursor_error incomplete_projection)
    @required_page_variations ~w(active scheduled_cancellation incomplete_evidence review_cancel_now awaiting_step_up dispatching result_confirmed result_pending result_failed)
    @renderer "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1"
    @query_module "AccrueAdmin.Storybook.SubscriptionCollectionQuery"
    @source_paths [
      "accrue_admin/lib/accrue_admin/dev/storybook.ex",
      "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
      "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
      "accrue_admin/lib/accrue_admin/queries/subscriptions.ex",
      "accrue_admin/lib/accrue_admin/router.ex",
      "accrue_admin/storybook/_support/subscription_collection.ex",
      "accrue_admin/storybook/_support/subscription_compositions_manifest.ex",
      "accrue_admin/storybook/_support/subscription_page_scenarios.ex",
      "dev_support/ui_scenarios/cadence_subscriptions.exs",
      "storybook/groups/subscriptions_collection.story.exs",
      "storybook/pages/subscription.story.exs"
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

            reason ->
              raise ArgumentError,
                    "compiled collection story could not be loaded: #{inspect(reason)}"
          end

        [] ->
          raise ArgumentError, "compiled Storybook tree is missing #{@story_path}"

        _duplicates ->
          raise ArgumentError, "compiled Storybook tree contains duplicate #{@story_path} leaves"
      end
    end

    @doc "Discovers every direct collection variation from the compiled PhoenixStorybook tree."
    @spec collection_variation_entries() :: [map()]
    def collection_variation_entries do
      case Enum.filter(Storybook.leaves(), &(&1.path == @story_path)) do
        [%StoryEntry{path: path}] ->
          case Storybook.load_story(String.trim_leading(path, "/")) do
            {:ok, story} ->
              collection_variation_entries_for([{path, story}], @storybook_root)

            reason ->
              raise ArgumentError,
                    "compiled collection story could not be loaded: #{inspect(reason)}"
          end

        [] ->
          raise ArgumentError, "compiled Storybook tree is missing #{@story_path}"

        _duplicates ->
          raise ArgumentError, "compiled Storybook tree contains duplicate #{@story_path} leaves"
      end
    end

    @doc "Builds source-bound direct routes for all variations in the compiled collection story."
    @spec collection_variation_entries_for([{String.t(), module()}], String.t()) :: [map()]
    def collection_variation_entries_for(stories, root_path)
        when is_list(stories) and is_binary(root_path) do
      unless Enum.any?(stories, fn
               {@story_path, _story} -> true
               _other -> false
             end) do
        raise ArgumentError, "compiled collection story is missing #{@story_path}"
      end

      entries =
        Enum.flat_map(stories, fn
          {@story_path = path, story} when is_atom(story) ->
            validate_story!(story)

            story
            |> apply(:variations, [])
            |> flatten_variations!(path)
            |> Enum.map(fn {group_id, variation} ->
              collection_variation_entry!(path, group_id, variation, root_path)
            end)

          {path, _story} ->
            raise ArgumentError, "unexpected subscription collection path: #{inspect(path)}"

          other ->
            raise ArgumentError, "invalid compiled collection source: #{inspect(other)}"
        end)

      if entries == [] do
        raise ArgumentError, "compiled collection story contains zero variations"
      end

      duplicate =
        entries
        |> Enum.group_by(& &1.variation_id)
        |> Enum.find(fn {_id, same_id} -> length(same_id) > 1 end)

      if duplicate do
        {id, _entries} = duplicate
        raise ArgumentError, "duplicate compiled collection variation ID: #{id}"
      end

      Enum.sort_by(entries, &{&1.story_path, &1.variation_id})
    end

    def collection_variation_entries_for(_stories, _root_path),
      do: raise(ArgumentError, "compiled collection stories and Storybook root must be provided")

    @doc "Discovers the approved whole-page variations from the compiled PhoenixStorybook tree."
    @spec page_entries() :: [map()]
    def page_entries do
      case Enum.filter(Storybook.leaves(), &(&1.path == @page_story_path)) do
        [%StoryEntry{path: path}] ->
          case Storybook.load_story(String.trim_leading(path, "/")) do
            {:ok, story} ->
              page_entries_for([{path, story}], @storybook_root)

            reason ->
              raise ArgumentError,
                    "compiled whole-page story could not be loaded: #{inspect(reason)}"
          end

        [] ->
          raise ArgumentError, "compiled Storybook tree is missing #{@page_story_path}"

        _duplicates ->
          raise ArgumentError,
                "compiled Storybook tree contains duplicate #{@page_story_path} leaves"
      end
    end

    @doc "Builds fail-closed manifest entries for the compiled whole-page story."
    @spec page_entries_for([{String.t(), module()}], String.t()) :: [map()]
    def page_entries_for(stories, root_path) when is_list(stories) and is_binary(root_path) do
      unless Enum.any?(stories, fn
               {@page_story_path, _story} -> true
               _other -> false
             end) do
        raise ArgumentError, "compiled page Storybook tree is missing #{@page_story_path}"
      end

      entries =
        Enum.flat_map(stories, fn
          {@page_story_path = path, story} when is_atom(story) ->
            validate_page_story!(story)

            story
            |> apply(:variations, [])
            |> flatten_page_variations!(path)
            |> Enum.map(&page_entry!(path, &1, root_path))

          {path, _story} ->
            raise ArgumentError, "unexpected whole-page story path: #{inspect(path)}"

          other ->
            raise ArgumentError, "invalid compiled whole-page story source: #{inspect(other)}"
        end)

      if entries == [] do
        raise ArgumentError, "compiled whole-page story contains zero variations"
      end

      duplicate =
        entries
        |> Enum.group_by(& &1.variation_id)
        |> Enum.find(fn {_id, same_id} -> length(same_id) > 1 end)

      if duplicate do
        {id, _entries} = duplicate
        raise ArgumentError, "duplicate whole-page path/variation identity: #{id}"
      end

      actual_ids = Enum.map(entries, & &1.variation_id)

      page_tabs =
        stories
        |> Enum.find_value(fn
          {@page_story_path, story} -> apply(story, :navigation, [])
          _other -> nil
        end)
        |> List.wrap()
        |> Enum.map(&(elem(&1, 0) |> to_string()))

      unless Enum.sort(page_tabs) == Enum.sort(actual_ids) do
        raise ArgumentError,
              "whole-page navigation tabs must map one-to-one to the compiled page variations"
      end

      missing = @required_page_variations -- actual_ids
      extra = actual_ids -- @required_page_variations

      unless missing == [] and extra == [] do
        raise ArgumentError,
              "whole-page variation set is incomplete or unsupported (missing: #{inspect(missing)}, extra: #{inspect(extra)})"
      end

      Enum.sort_by(entries, &{&1.story_path, &1.variation_id})
    end

    def page_entries_for(_stories, _root_path),
      do: raise(ArgumentError, "whole-page stories and Storybook root must be provided")

    @doc "Builds a stable, narrow projection from compiled collection stories."
    @spec entries_for([{String.t(), module()}], String.t()) :: [map()]
    def entries_for(stories, root_path) when is_list(stories) and is_binary(root_path) do
      declarations =
        stories
        |> Enum.flat_map(fn
          {@story_path = path, story} when is_atom(story) ->
            validate_story!(story)

            story
            |> apply(:variations, [])
            |> flatten_variations!(path)

          {path, _story} ->
            raise ArgumentError,
                  "unexpected subscription composition story path: #{inspect(path)}"

          other ->
            raise ArgumentError, "invalid compiled collection story source: #{inspect(other)}"
        end)

      if declarations == [] do
        raise ArgumentError, "compiled collection story contains zero variations"
      end

      # This manifest preserves the task 1 one-row transport proof. Additional
      # settled collection states are exercised by the collection slice tests;
      # they do not carry the launch/team source attribution required here.
      entries =
        declarations
        |> Enum.filter(fn {_group_id, %Variation{id: variation_id}} ->
          variation_id == @required_variation_id
        end)
        |> Enum.map(fn {group_id, variation} ->
          entry!(@story_path, group_id, variation, root_path)
        end)

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
        entries: current_entries,
        collection_variations: collection_variation_entries(),
        page_entries: page_entries()
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

      current_page_entries = page_entries() |> Jason.encode!() |> Jason.decode!()

      unless manifest["page_entries"] == current_page_entries do
        raise ArgumentError, "whole-page manifest entries or direct routes are stale"
      end

      current_collection_variations =
        collection_variation_entries() |> Jason.encode!() |> Jason.decode!()

      unless manifest["collection_variations"] == current_collection_variations do
        raise ArgumentError, "compiled collection variation inventory or direct routes are stale"
      end

      current_transport = transport!(entries())

      unless manifest["transport"] == current_transport do
        raise ArgumentError, "collection manifest transport evidence is stale"
      end

      unless Enum.all?(manifest["entries"], &route_matches?(&1, Map.get(&1, "url"))) do
        raise ArgumentError, "collection manifest contains an invalid direct route"
      end

      unless Enum.all?(manifest["page_entries"], &route_matches?(&1, Map.get(&1, "url"))) do
        raise ArgumentError, "whole-page manifest contains an invalid navigation-tab route"
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

        route_parameter =
          Map.get(entry, :route_parameter, Map.get(entry, "route_parameter", "variation_id"))

        actual.scheme == expected.scheme and actual.host == expected.host and
          actual.path == expected.path and query == %{route_parameter => variation_id}
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
      expected_attributes = %{scenario: scenario}
      canonical_attributes = %{scenario: scenario, collection_state: :one_row}

      unless is_map(attributes) and attributes in [expected_attributes, canonical_attributes] and
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

    defp collection_variation_entry!(
           path,
           group_id,
           %Variation{id: variation_id, attributes: attributes},
           root_path
         ) do
      validate_id!(variation_id, "collection variation", path)
      if group_id, do: validate_id!(group_id, "variation group", path)

      scenario = if is_map(attributes), do: Map.get(attributes, :scenario, :launch)

      collection_state =
        if is_map(attributes), do: Map.get(attributes, :collection_state, :one_row)

      allowed_attributes =
        is_map(attributes) and Map.keys(attributes) -- [:scenario, :collection_state] == []

      unless allowed_attributes and scenario in [:launch, :growing_team] and
               collection_state in Enum.map(@collection_states, &String.to_atom/1) and
               variation_id == collection_state do
        raise ArgumentError,
              "collection variation #{inspect(variation_id)} in #{path} has unsupported scenario or state attribution"
      end

      facts = scenario |> CadenceSubscriptionFacts.fetch!() |> SubscriptionScenarios.validate!()

      route_variation_id = group_id || variation_id
      route_id = to_string(route_variation_id)

      url =
        NavigationHelpers.path_to_story(root_path, String.trim_leading(path, "/"), %{
          variation_id: route_id
        })

      iframe_url =
        NavigationHelpers.path_to_story(
          "#{@storybook_root}/iframe",
          String.trim_leading(path, "/"),
          %{variation_id: route_id}
        )

      %{
        story_path: path,
        group_id: if(group_id, do: to_string(group_id)),
        variation_id: to_string(variation_id),
        route_variation_id: route_id,
        collection_state: Atom.to_string(collection_state),
        scenario_id: Atom.to_string(scenario),
        url: url,
        direct_path:
          @mounted_storybook_root <>
            String.replace_prefix(url, @storybook_root, ""),
        iframe_path:
          @mounted_storybook_root <>
            String.replace_prefix(iframe_url, @storybook_root, ""),
        transport_kind: "live_component",
        production_renderer: @renderer,
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

    defp flatten_page_variations!(variations, path) when is_list(variations) do
      Enum.map(variations, fn
        %Variation{} = variation ->
          variation

        other ->
          raise ArgumentError,
                "unsupported whole-page variation declaration in #{path}: #{inspect(other)}"
      end)
    end

    defp flatten_page_variations!(_variations, path),
      do: raise(ArgumentError, "whole-page story #{path} variations must be a list")

    defp page_entry!(path, %Variation{id: variation_id, attributes: attributes}, root_path) do
      validate_id!(variation_id, "whole-page variation", path)

      unless is_map(attributes) do
        raise ArgumentError,
              "whole-page variation #{inspect(variation_id)} in #{path} needs an attribution map"
      end

      scenario = Map.get(attributes, :scenario)
      snapshot = Map.get(attributes, :snapshot)

      expected_attributes =
        try do
          SubscriptionPageScenarios.attributes(scenario, snapshot)
        rescue
          ArgumentError -> nil
        end

      unless is_map(expected_attributes) and attributes == expected_attributes do
        raise ArgumentError,
              "whole-page variation #{inspect(variation_id)} in #{path} has malformed or incomplete attribution"
      end

      facts = scenario |> CadenceSubscriptionFacts.fetch!() |> SubscriptionScenarios.validate!()
      route_id = Atom.to_string(variation_id)

      url =
        NavigationHelpers.path_to_story(root_path, String.trim_leading(path, "/"), %{
          tab: route_id
        })

      %{
        key: key(path, nil, variation_id),
        story_path: path,
        group_id: nil,
        variation_id: route_id,
        route_variation_id: route_id,
        route_parameter: "tab",
        url: url,
        direct_path: @mounted_storybook_root <> String.replace_prefix(url, @storybook_root, ""),
        transport_kind: "page_story",
        production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_page/1",
        fact_source: "CadenceSubscriptionFacts.fetch!(:#{scenario})",
        presentation_snapshot: Atom.to_string(snapshot),
        proof_lane: "presentation-only",
        expected: %{
          scenario: Atom.to_string(scenario),
          snapshot: Atom.to_string(snapshot),
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
      [_one_row] = Enum.filter(entries, &(&1.variation_id == @required_variation))

      component_url =
        NavigationHelpers.path_to_story(
          "#{@storybook_root}/iframe",
          "groups/subscriptions_collection",
          %{variation_id: @required_variation}
        )

      component_direct_path =
        @mounted_storybook_root <> String.replace_prefix(component_url, @storybook_root, "")

      expected = %{
        "direct_path" => component_direct_path,
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

    defp validate_page_story!(story) do
      unless Code.ensure_loaded?(story) and function_exported?(story, :variations, 0) and
               function_exported?(story, :render, 1) and function_exported?(story, :navigation, 0) do
        raise ArgumentError,
              "compiled whole-page story must export variations/0, navigation/0, and render/1: #{inspect(story)}"
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
