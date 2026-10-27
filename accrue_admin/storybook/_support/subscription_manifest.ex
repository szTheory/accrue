if Mix.env() != :prod do
  defmodule AccrueAdmin.Storybook.SubscriptionManifest do
    @moduledoc false

    alias AccrueAdmin.Dev.Storybook
    alias AccrueAdmin.Dev.ComponentRegistry
    alias AccrueAdmin.Storybook.SubscriptionScenarios
    alias AccrueAdmin.Storybook.SubscriptionCompositionsManifest
    alias PhoenixStorybook.{NavigationHelpers, StoryEntry}
    alias PhoenixStorybook.Stories.{Variation, VariationGroup}

    @storybook_root "/dev/storybook"
    @subscription_story_path "/components/subscription_detail"
    @caller_source_paths [
      "accrue_admin/lib/accrue_admin/dev/component_registry.ex",
      "accrue_admin/lib/accrue_admin/router.ex",
      "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
      "accrue_portal/lib/accrue_portal/router.ex",
      "accrue_portal/lib/accrue_portal/live/subscriptions_live.ex",
      "accrue_portal/lib/accrue_portal/live/subscription_live.ex"
    ]
    @manifest_source_paths [
      "accrue_admin/lib/accrue_admin/dev/storybook.ex",
      "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
      "accrue_admin/storybook/_support/subscription_manifest.ex",
      "accrue_admin/storybook/_support/subscription_scenarios.ex",
      "dev_support/ui_scenarios/cadence_subscriptions.exs",
      "storybook/components/subscription_detail.story.exs"
    ]
    @source_paths @manifest_source_paths ++ @caller_source_paths
    @phase253_guide_source_paths [
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

    @doc "Returns stable production call-site rows linked to compiled story declarations and registry contracts."
    @spec caller_map() :: [map()]
    def caller_map do
      root = repository_root()
      entries = entries()
      manifest_keys = Enum.map(entries, & &1.key) |> Enum.sort()

      component_rows =
        [
          {"Detail.summary_card/1", nil, "Detail.summary_card title="},
          {"Detail.summary_list/1", nil, "Detail.summary_list"},
          {"StatusBadge.status_badge/1", "status", "StatusBadge.status_badge"},
          {"IdBadge.id_badge/1", "id-badge", "IdBadge.id_badge"},
          {"DropdownMenu.action_menu/1", nil, "DropdownMenu.action_menu"},
          {"Action band buttons", "button", "class=\"ax-button ax-button-primary\""}
        ]
        |> Enum.map(fn {label, family, marker} ->
          extra =
            if family do
              variants = ComponentRegistry.variants_for(family)

              unless variants != [] do
                raise ArgumentError,
                      "subscription caller has no component registry family: #{family}"
              end

              %{registry_family: family, registry_variants: Enum.map(variants, & &1.variant)}
            else
              %{}
            end

          caller_row!(
            root,
            label,
            "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
            "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
            marker,
            "component",
            "reachable",
            manifest_keys: manifest_keys,
            story_path: @subscription_story_path,
            extra: extra
          )
        end)

      story_rows =
        Enum.map(entries, fn entry ->
          compatibility? =
            entry.variation_id in ["populated", "braintree_pruned", "dunning_active"]

          caller_row!(
            root,
            "#{entry.variation_id} story variation",
            "AccrueAdmin.Storybook.Components.SubscriptionDetail.variations/0",
            "storybook/components/subscription_detail.story.exs",
            ":#{entry.variation_id},",
            "component",
            "reachable",
            manifest_keys: [entry.key],
            story_path: entry.story_path,
            manifest_urls: [entry.url],
            contract: entry.scenario_id,
            classification:
              if(compatibility?,
                do: "source-supported compatibility declaration",
                else: "selected subscription state"
              )
          )
        end)

      group_contract =
        ComponentRegistry.group_contract_by_slug("detail-header-metadata-actions") ||
          raise ArgumentError,
                "subscription detail group contract is missing from ComponentRegistry"

      group_row =
        caller_row!(
          root,
          group_contract.name,
          "AccrueAdmin.Dev.ComponentRegistry.group_contracts/0",
          "accrue_admin/lib/accrue_admin/dev/component_registry.ex",
          group_contract.proof_id,
          "group",
          "uncovered",
          reason:
            "The selected subscription story reaches the shared area and action band, but does not render the full registered detail-header group contract.",
          contract: group_contract.slug,
          registry_proof_id: group_contract.proof_id,
          registry_components: group_contract.primary_components
        )

      area_row =
        caller_row!(
          root,
          "Subscription summary, facts, and eligible actions",
          "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
          "def subscription_area(assigns) do",
          "area",
          "reachable",
          manifest_keys: manifest_keys,
          story_path: @subscription_story_path
        )

      section_row =
        caller_row!(
          root,
          "Subscription actions section",
          "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
          "data-ax-action-band",
          "section",
          "reachable",
          manifest_keys: manifest_keys,
          story_path: @subscription_story_path
        )

      admin_rows = [
        caller_row!(
          root,
          "Admin subscription detail page",
          "AccrueAdmin.Live.SubscriptionLive.render/1",
          "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
          "<.subscription_area",
          "page",
          "uncovered",
          reason:
            "The legacy detail Storybook route renders subscription_area/1 only. It does not prove the whole-page shell, breadcrumb, related resources, drill sections, or full-page route.",
          route_path: "/subscriptions/:id",
          route_evidence:
            source_evidence!(
              root,
              "accrue_admin/lib/accrue_admin/router.ex",
              "live(\"/subscriptions/:id\", AccrueAdmin.Live.SubscriptionLive"
            )
        ),
        caller_row!(
          root,
          "Admin subscription list",
          "AccrueAdmin.Live.SubscriptionsLive.render/1",
          "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
          "def render(assigns) do",
          "job",
          "uncovered",
          reason: "The subscription list has no selected subscription Storybook composition.",
          route_path: "/subscriptions",
          route_evidence:
            source_evidence!(
              root,
              "accrue_admin/lib/accrue_admin/router.ex",
              "live(\"/subscriptions\", AccrueAdmin.Live.SubscriptionsLive"
            )
        ),
        caller_row!(
          root,
          "Admin mounted subscription action journey",
          "AccrueAdmin.Live.SubscriptionLive.handle_event/3",
          "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
          "def handle_event(\"open_action_drawer\"",
          "job",
          "uncovered",
          reason:
            "Static stories do not exercise mount authorization, step-up, preview, confirmation, provider results, or persistence; Phase 253 owns the mounted Admin journey.",
          route_path: "/subscriptions/:id",
          route_evidence:
            source_evidence!(
              root,
              "accrue_admin/lib/accrue_admin/router.ex",
              "live(\"/subscriptions/:id\", AccrueAdmin.Live.SubscriptionLive"
            )
        )
      ]

      portal_rows = [
        caller_row!(
          root,
          "Portal subscription list",
          "AccruePortal.Live.SubscriptionsLive.render/1",
          "accrue_portal/lib/accrue_portal/live/subscriptions_live.ex",
          "def render(assigns) do",
          "job",
          "uncovered",
          reason:
            "The customer-facing subscription list and its cancellation controls have no selected Portal Storybook composition.",
          route_path: "/subscriptions",
          route_evidence:
            source_evidence!(
              root,
              "accrue_portal/lib/accrue_portal/router.ex",
              "live(\"/subscriptions\", AccruePortal.Live.SubscriptionsLive"
            )
        ),
        caller_row!(
          root,
          "Portal subscription detail page",
          "AccruePortal.Live.SubscriptionLive.render/1",
          "accrue_portal/lib/accrue_portal/live/subscription_live.ex",
          "def render(assigns) do",
          "job",
          "uncovered",
          reason:
            "Portal subscription detail, recovery messaging, and plan-change preview have no selected Storybook composition.",
          route_path: "/subscriptions/:id",
          route_evidence:
            source_evidence!(
              root,
              "accrue_portal/lib/accrue_portal/router.ex",
              "live(\"/subscriptions/:id\", AccruePortal.Live.SubscriptionLive"
            )
        ),
        caller_row!(
          root,
          "Portal mounted cancellation and plan-change journey",
          "AccruePortal.Live.SubscriptionLive.handle_event/3",
          "accrue_portal/lib/accrue_portal/live/subscription_live.ex",
          "\"confirm_plan_change\"",
          "job",
          "uncovered",
          reason:
            "Static stories do not exercise Portal authorization, plan-change preview/commit, cancellation, provider results, or persisted effects.",
          route_path: "/subscriptions/:id",
          route_evidence:
            source_evidence!(
              root,
              "accrue_portal/lib/accrue_portal/router.ex",
              "live(\"/subscriptions/:id\", AccruePortal.Live.SubscriptionLive"
            )
        ),
        caller_row!(
          root,
          "Mounted authority, provider completion, and persistence",
          "AccrueAdmin.Storybook.Components.SubscriptionDetail.subscription_detail_story/1",
          "storybook/components/subscription_detail.story.exs",
          "Every variation is a static render",
          "proof-lane",
          "not_applicable",
          reason:
            "These effects are not observable in the static render proof lane; the story delegates presentation and does not execute mounted or provider workflows.",
          story_path: @subscription_story_path
        )
      ]

      ([group_row, area_row, section_row] ++
         component_rows ++ story_rows ++ admin_rows ++ portal_rows)
      |> caller_map_for()
    end

    @doc "Normalizes and validates caller coverage rows, refusing empty or duplicate identities."
    @spec caller_map_for([map()]) :: [map()]
    def caller_map_for(rows) when is_list(rows) do
      if rows == [] do
        raise ArgumentError, "production caller source contains zero rows"
      end

      normalized = Enum.map(rows, &normalize_caller_row!/1)

      duplicate =
        normalized
        |> Enum.group_by(& &1.key)
        |> Enum.find(fn {_key, matching_rows} -> length(matching_rows) > 1 end)

      if duplicate do
        {key, _matching_rows} = duplicate
        raise ArgumentError, "duplicate production caller identity: #{key}"
      end

      Enum.sort_by(normalized, &{&1.owner, &1.path, &1.tier, &1.state, &1.label, &1.key})
    end

    def caller_map_for(_rows),
      do: raise(ArgumentError, "production caller source must be a non-empty list")

    @doc "Writes a deterministic guide from the current production caller map."
    @spec write_coverage_guide!(Path.t()) :: :ok
    def write_coverage_guide!(path) when is_binary(path) do
      contents = coverage_guide()
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, contents)
    end

    @doc "Renders the deterministic current caller and composition guide."
    @spec coverage_guide() :: String.t()
    def coverage_guide do
      rows = caller_map()

      sections = [
        {"Reachable", "reachable"},
        {"Uncovered", "uncovered"},
        {"Not applicable", "not_applicable"}
      ]

      state_tables =
        Enum.map(sections, fn {title, state} ->
          state_rows = Enum.filter(rows, &(&1.state == state))

          [
            "## #{title}",
            "",
            "| Tier | Caller | Production owner | Source evidence | Route / story links | Contract or reason |",
            "| --- | --- | --- | --- | --- | --- |",
            Enum.map(state_rows, &guide_row/1),
            ""
          ]
        end)

      compatibility =
        rows
        |> Enum.filter(&(&1.classification == "source-supported compatibility declaration"))
        |> Enum.map(&"`#{&1.label}` (`#{&1.contract}`)")
        |> Enum.join(", ")

      digests =
        source_digests()
        |> Map.merge(phase253_guide_source_digests())
        |> Enum.sort()
        |> Enum.map(fn {source, digest} -> "- `#{source}` — `#{digest}`" end)

      [
        "# Production caller and composition coverage",
        "",
        "Generated from compiled subscription Storybook declarations, production source call sites, current router routes, and ComponentRegistry contracts. `Reachable` means the named source is linked to a selected static-render manifest entry; browser DOM verification is supplied separately by Phase 252-06.",
        "",
        "The composition trace is component → group → area → section → page. The current story calls the same `SubscriptionLive.subscription_area/1` owner used by the Admin detail page, and includes its action band. The legacy detail Storybook route `/dev/storybook/components/subscription_detail` does not prove a whole page.",
        "",
        "Selected story IDs are discovered from the compiled tree. Source-supported compatibility declarations retained with their scenario contracts: #{compatibility}.",
        "",
        "Phase 253's compiled composition supplement below documents the Admin whole-page and collection stories. Mounted route and action-journey behavior is verified separately. Portal subscription list/detail and mounted cancellation/plan-change jobs remain visible below for later coverage planning; this guide does not implement those jobs.",
        "",
        state_tables,
        phase253_composition_section(),
        "## Source digests",
        "",
        digests,
        ""
      ]
      |> List.flatten()
      |> Enum.join("\n")
    end

    defp phase253_composition_section do
      collection_entries = SubscriptionCompositionsManifest.collection_variation_entries()
      page_entries = SubscriptionCompositionsManifest.page_entries()

      collection_rows =
        Enum.map(collection_entries, fn entry ->
          "| `#{guide_cell(entry.variation_id)}` | `#{guide_cell(entry.scenario_id)}` | #{guide_route(entry.direct_path)} | #{guide_route(entry.iframe_path)} | `#{guide_cell(entry.production_renderer)}` | `#{guide_cell(entry.fact_source)}` | `#{guide_cell(entry.proof_lane)}` |"
        end)

      page_rows =
        Enum.map(page_entries, fn entry ->
          "| `#{guide_cell(entry.variation_id)}` | `#{guide_cell(entry.expected.scenario)}` | `#{guide_cell(entry.presentation_snapshot)}` | #{guide_route(entry.direct_path)} | `#{guide_cell(entry.production_renderer)}` | `#{guide_cell(entry.fact_source)}` | `#{guide_cell(entry.proof_lane)}` |"
        end)

      [
        "## Phase 253 compiled composition supplement",
        "",
        "This additive section is generated from `SubscriptionCompositionsManifest.collection_variation_entries/0` and `page_entries/0`. Phase 252's six canonical component entries and coverage assertions remain unchanged.",
        "",
        "Review the direct routes and their compiled renderers below. The collection also lists its iframe route because the browser evidence visits that compiled route.",
        "",
        "### Collection compositions",
        "",
        "| Variation | Scenario | Direct route | Story iframe route | Production renderer | Source facts | Proof lane |",
        "| --- | --- | --- | --- | --- | --- | --- |",
        collection_rows,
        "",
        "### Whole subscription pages",
        "",
        "| Variation | Scenario | Snapshot | Direct route | Production renderer | Source facts | Proof lane |",
        "| --- | --- | --- | --- | --- | --- | --- |",
        page_rows,
        "",
        "Presentation-only evidence covers settled appearance; it does not establish mounted authority, persistence, dispatch, or provider completion. Use the mounted route and action-journey tests for those claims. The collection preview is backed by validated development/test facts; it does not claim provider price lookup or a persisted action.",
        ""
      ]
    end

    defp phase253_guide_source_digests do
      root = repository_root()

      @phase253_guide_source_paths
      |> Enum.sort()
      |> Map.new(fn relative_path ->
        path = Path.join(root, relative_path)

        unless File.regular?(path) do
          raise ArgumentError, "Phase 253 coverage guide source file is missing: #{relative_path}"
        end

        digest = :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)
        {relative_path, digest}
      end)
    end

    defp guide_route(route), do: "[`#{guide_cell(route)}`](#{route})"

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

    defp caller_row!(root, label, owner, path, marker, tier, state, opts) do
      evidence = source_evidence!(root, path, marker)
      options = Map.new(opts)

      route_evidence = Map.get(options, :route_evidence)

      row = %{
        label: label,
        owner: owner,
        path: path,
        tier: tier,
        state: state,
        evidence: evidence,
        reason: Map.get(options, :reason),
        contract: Map.get(options, :contract),
        registry_proof_id: Map.get(options, :registry_proof_id),
        registry_components: Map.get(options, :registry_components),
        story_path: Map.get(options, :story_path),
        manifest_keys: Map.get(options, :manifest_keys, []),
        manifest_urls: Map.get(options, :manifest_urls, []),
        route_path: Map.get(options, :route_path),
        route_evidence: route_evidence,
        classification: Map.get(options, :classification)
      }

      Map.merge(row, Map.get(options, :extra, %{}))
    end

    defp source_evidence!(root, relative_path, marker) do
      source_path = Path.join(root, relative_path)

      unless File.regular?(source_path) do
        raise ArgumentError, "production caller source is missing: #{relative_path}"
      end

      source_path
      |> File.read!()
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.find_value(fn {line, line_number} ->
        if String.contains?(line, marker) do
          "#{relative_path}:#{line_number}: #{String.trim(line)}"
        end
      end)
      |> case do
        nil ->
          raise ArgumentError,
                "production caller evidence is missing from #{relative_path}: #{marker}"

        evidence ->
          evidence
      end
    end

    defp normalize_caller_row!(row) when is_map(row) do
      fields = [:label, :owner, :path, :tier, :state, :evidence]

      Enum.each(fields, fn field ->
        value = Map.get(row, field)

        unless is_binary(value) and String.trim(value) != "" do
          raise ArgumentError, "production caller row is missing #{field}"
        end
      end)

      unless row.state in ["reachable", "uncovered", "not_applicable"] do
        raise ArgumentError, "production caller row has unsupported state: #{inspect(row.state)}"
      end

      if row.state != "reachable" and not non_empty_string?(Map.get(row, :reason)) do
        raise ArgumentError, "#{row.state} production caller row is missing a reason"
      end

      manifest_keys = Map.get(row, :manifest_keys, [])

      unless is_list(manifest_keys) and Enum.all?(manifest_keys, &non_empty_string?/1) do
        raise ArgumentError, "production caller row has invalid manifest keys"
      end

      identity = [row.owner, row.path, row.tier, row.state, row.label]
      key = Enum.map_join(identity, "|", &URI.encode/1)

      row
      |> Map.put(:key, key)
      |> Map.put(:manifest_keys, Enum.sort(Enum.uniq(manifest_keys)))
    end

    defp normalize_caller_row!(_row),
      do: raise(ArgumentError, "production caller row must be a map")

    defp non_empty_string?(value), do: is_binary(value) and String.trim(value) != ""

    defp guide_row(row) do
      links =
        (Map.get(row, :manifest_urls, []) ++
           Enum.map(Map.get(row, :manifest_keys, []), &"manifest key `#{&1}`") ++
           List.wrap(Map.get(row, :route_path)))
        |> Enum.reject(&is_nil/1)
        |> Enum.join("<br>")

      source_evidence =
        [Map.get(row, :evidence), Map.get(row, :route_evidence)]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("<br>")

      contract_or_reason =
        Map.get(row, :reason) || Map.get(row, :contract) || Map.get(row, :classification) || "—"

      "| #{guide_cell(row.tier)} | #{guide_cell(row.label)} | #{guide_cell(row.owner)} | `#{guide_cell(source_evidence)}` | #{guide_cell(links)} | #{guide_cell(contract_or_reason)} |"
    end

    defp guide_cell(nil), do: "—"
    defp guide_cell(value), do: value |> to_string() |> String.replace("|", "\\|")
  end
end
