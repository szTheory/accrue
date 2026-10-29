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

    # CURATE-01 (D-37..D-40). The frozen baseline is computed once, at the HEAD before the first
    # curation edit, and pinned here as literal data. frozen_baseline/0 never reads the current tree,
    # so later retirements cannot change it; verify_phase254_curation.mjs re-derives it from
    # `git show @frozen_source_commit:<path>` and fails on any drift.
    @frozen_source_commit "986f68b71bae643ce24f0906c39d072fe5ea117b"
    @frozen_subject_sources [
      "storybook/components/action_menu.story.exs",
      "storybook/components/detail.story.exs",
      "storybook/components/overlay.story.exs",
      "storybook/components/page_header.story.exs",
      "storybook/phase252-manifest.json"
    ]
    # {source path, story path, %Variation{} ids}. Manifest entries come from the tracked manifest,
    # every other source from the %Variation{ id: ... } struct literals of the story file.
    @frozen_subject_groups [
      {"storybook/components/action_menu.story.exs", "/components/action_menu",
       ~w(danger default focus open provider_pruned)},
      {"storybook/components/detail.story.exs", "/components/detail",
       ~w(change_actions long_labels read_only view_actions)},
      {"storybook/components/overlay.story.exs", "/components/overlay",
       ~w(drawer_desktop drawer_mobile modal_shell popover_shell reduced_motion)},
      {"storybook/components/page_header.story.exs", "/components/page_header",
       ~w(actions combined_controls default filter_toolbar long_content stat_strip)},
      {"storybook/phase252-manifest.json", "/components/subscription_detail",
       ~w(active braintree_pruned dunning_active incomplete_evidence populated scheduled_cancellation)}
    ]
    @frozen_subjects_sha256 "1082c32dfd875980f87ca450f77bbe70c26c039d6c61c429a60aaa6ac2a80905"
    @frozen_manifest_sha256 "e321f5210f3d2e1604eb4f14e52a67dc52362d35f400309ea5247ee61164adbf"
    @frozen_kitchen_test_digests %{
      "accrue_admin/e2e/kitchen-banner.spec.js" =>
        "571441982d7a944b40624923189fdcb6a04664adf2d4c3d91c7937f5b1502b64",
      "accrue_admin/test/accrue_admin/dev/component_group_registry_test.exs" =>
        "cc8902bf54c3c86f1988bf83d477778ca8e948da6c5a146b9aab09c2e552bd0a",
      "accrue_admin/test/accrue_admin/dev/component_kitchen_live_test.exs" =>
        "dc838913beebdb0c3f5752d69f803b7ea0d07336368581a0ca667544045206af",
      "accrue_admin/test/accrue_admin/dev/component_registry_test.exs" =>
        "ece76a9f5cb66ae79eaa1ca0bdc0b5f0471e725a1c39f24149e1cac64b630797"
    }
    @frozen_compatibility_ids ["braintree_pruned", "dunning_active", "populated"]

    # Phase 253 compiled composition keys (`<story path>||<variation>`) the corrected gap rows cite;
    # subscription_manifest_test asserts every key exists in the compiled Phase 253 manifest.
    @phase253_page_keys Enum.map(
                          ~w(active awaiting_step_up dispatching incomplete_evidence result_confirmed result_failed result_pending review_cancel_now scheduled_cancellation),
                          &"/pages/subscription||#{&1}"
                        )
    @phase253_journey_page_keys Enum.map(
                                  ~w(awaiting_step_up dispatching result_confirmed result_failed result_pending review_cancel_now),
                                  &"/pages/subscription||#{&1}"
                                )
    @phase253_collection_keys Enum.map(
                                ~w(filtered_empty incomplete_projection loading multiple_rows new_host_empty one_row page_boundary partial_cursor_error queue_empty unavailable),
                                &"/groups/subscriptions_collection||#{&1}"
                              )
    @sbk06_journey_test "accrue_admin/test/accrue_admin/live/subscription_journey_test.exs"
    @frozen_registry %{family_count: 30, entry_count: 42, specimen_count: 75}
    @frozen_entry_count 6
    @duplicate_fact_fields [
      :actor,
      :job,
      :input_source,
      :production_renderer,
      :proof_lane,
      :composition_tier
    ]
    @curation_dispositions ["retire", "merge", "retain", "reclassify"]
    @curation_reason_classes ["stale", "impossible", "duplicate"]
    @curation_reachability_states ["reachable", "historic_supported", "unreachable"]
    @curation_survivor_kinds ["manifest_entry", "story"]
    @curation_guide_path "accrue_admin/storybook/subscription-curation.json"

    @doc "Discovers retained subscription variations from the compiled PhoenixStorybook backend."
    @spec entries() :: [map()]
    def entries do
      selected = Enum.filter(Storybook.leaves(), &(&1.path == @subscription_story_path))

      case selected do
        [%StoryEntry{path: path}] ->
          case Storybook.load_story(String.trim_leading(path, "/")) do
            {:ok, story} ->
              entries_for([{path, story}], @storybook_root)

            reason ->
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

    @doc "The frozen curation baseline: pinned literal data, never recomputed from the current tree."
    @spec frozen_baseline() :: map()
    def frozen_baseline do
      subjects =
        for {source, story_path, ids} <- @frozen_subject_groups, id <- ids do
          %{story_path: story_path, variation_id: id, source_path: source}
        end
        |> Enum.sort_by(&{&1.story_path, &1.variation_id})

      %{
        source_commit: @frozen_source_commit,
        entries: @frozen_entry_count,
        compatibility_ids: @frozen_compatibility_ids,
        registry: @frozen_registry,
        manifest_sha256: @frozen_manifest_sha256,
        kitchen_test_digests: @frozen_kitchen_test_digests,
        subject_sources: @frozen_subject_sources,
        subjects: subjects,
        subjects_sha256: @frozen_subjects_sha256
      }
    end

    @doc """
    Digest over the sorted subjects as a list-of-lists JSON form, so it cannot depend on map key order
    (BEAM map key order is not alphabetical) and matches the Node verifier byte for byte.
    """
    @spec subjects_digest([map()]) :: String.t()
    def subjects_digest(subjects) when is_list(subjects) do
      subjects
      |> Enum.map(&[&1.story_path, &1.variation_id, &1.source_path])
      |> Jason.encode!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
    end

    @doc "Builds the fact and expected blocks that decide whether two entries are an exact duplicate."
    @spec duplicate_evidence(map(), map()) :: map()
    def duplicate_evidence(subject_entry, survivor_entry)
        when is_map(subject_entry) and is_map(survivor_entry) do
      %{subject: duplicate_blocks(subject_entry), survivor: duplicate_blocks(survivor_entry)}
    end

    defp duplicate_blocks(entry) do
      %{fact: Map.take(entry, @duplicate_fact_fields), expected: Map.fetch!(entry, :expected)}
    end

    @doc "Returns the compiled curation ledger: frozen baseline, current counts, records, and amendments."
    @spec curation_ledger() :: map()
    def curation_ledger do
      %{
        schema_version: 1,
        frozen_baseline: frozen_baseline(),
        current: current_counts(),
        records: curation_records(),
        amendments: curation_amendments(),
        source_digests: source_digests()
      }
    end

    @doc "Counts observed in the current tree, checked against the frozen baseline by the verifier."
    @spec current_counts() :: map()
    def current_counts do
      current_entries = entries()
      registry = ComponentRegistry.entries()

      %{
        entries: length(current_entries),
        compatibility_ids:
          current_entries
          |> Enum.map(& &1.variation_id)
          |> Enum.filter(&(&1 in @frozen_compatibility_ids))
          |> Enum.sort(),
        registry: %{
          family_count: registry |> Enum.map(& &1.family) |> Enum.uniq() |> length(),
          entry_count: length(registry),
          specimen_count: registry |> Enum.map(&length(Map.get(&1, :specimens) || [])) |> Enum.sum()
        },
        kitchen_test_digests: kitchen_test_digests()
      }
    end

    defp kitchen_test_digests do
      root = repository_root()

      @frozen_kitchen_test_digests
      |> Map.keys()
      |> Map.new(fn relative_path ->
        path = Path.join(root, relative_path)

        unless File.regular?(path) do
          raise ArgumentError, "kitchen test file is missing: #{relative_path}"
        end

        {relative_path, :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)}
      end)
    end

    @doc "Amendments to earlier decisions recorded with the owner acknowledgement."
    @spec curation_amendments() :: [map()]
    def curation_amendments do
      [
        %{
          id: "AMD-254-01",
          decisions: ["D-06", "D-14", "D-39", "D-40"],
          original:
            "D-06/D-14 pin the full-mode browser counts as the literals 15 Phase 252 cells (12 canonical, 3 compatibility) and 151 Phase 253 cells.",
          amended:
            "15 stays alive as the frozen_baseline fixture positive control; the live Phase 252 count is derived from the ledger (frozen baseline minus retired). After the D-40 retirement of subscription_detail||populated full mode is 14 Phase 252 cells and 151 Phase 253 cells.",
          rationale:
            "D-39 locks that the pinned literals are derived from the ledger as an explicit amendment; keeping 15 as a literal would make the D-40 duplicate retirement impossible without weakening a gate, while deriving the count keeps every skip, retry and flaky rejection and the 12 canonical cells intact.",
          evidence: [
            %{
              path: "scripts/ci/verify_phase252_stories.mjs",
              marker: "function validateRenderResults"
            },
            %{
              path: "scripts/ci/generate_phase252_acceptance.mjs",
              marker: "function validateBrowser"
            },
            %{path: "scripts/ci/phase252_reporters.mjs", marker: "function browserBindings"},
            %{
              path: "scripts/ci/generate_phase252_acceptance.test.mjs",
              marker: "pooled cells and incomplete UI or edge predicates are rejected"
            },
            %{
              path: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
              marker: "generated guide preserves Phase 253 compiled routes"
            }
          ],
          record_ids: ["CUR-254-06"],
          owner_ack: %{date: "2026-10-28", status: "owner-accepted at plan time"}
        }
      ]
    end

    @doc "Returns the validated curation records, sorted by id."
    @spec curation_records() :: [map()]
    def curation_records do
      curation_records_for(raw_curation_records())
    end

    @doc "Normalizes and validates curation records against the frozen baseline."
    @spec curation_records_for([map()]) :: [map()]
    def curation_records_for(records) when is_list(records) do
      baseline = frozen_baseline()
      normalized = Enum.map(records, &normalize_curation_record!(&1, baseline))

      duplicate =
        normalized
        |> Enum.group_by(& &1.id)
        |> Enum.find(fn {_id, same} -> length(same) > 1 end)

      if duplicate do
        {id, _same} = duplicate
        raise ArgumentError, "duplicate curation record id: #{id}"
      end

      Enum.sort_by(normalized, & &1.id)
    end

    def curation_records_for(_records),
      do: raise(ArgumentError, "curation records must be a list")

    defp raw_curation_records do
      [
        primitive_retain_record(
          "CUR-254-01",
          "/components/detail",
          %{
            owner: "AccrueAdmin.Components.Detail.summary_list/1",
            evidence: [
              %{
                path: "accrue_admin/lib/accrue_admin/components/detail.ex",
                marker: "def summary_list(assigns) do"
              },
              %{path: "storybook/components/detail.story.exs", marker: "summary_list_story"}
            ]
          },
          "Only Storybook coverage of the Detail.summary_list/1 primitive API (read-only, change/view action and long-label rows). The subscription story renders it only through the whole subscription area.",
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/overlay_components_test.exs#renders a semantic summary-list dl with read-only and long value rows",
            protects:
              "Detail.summary_list/1 keeps its semantic description-list rows for read-only and long values"
          }
        ),
        primitive_retain_record(
          "CUR-254-02",
          "/components/overlay",
          %{
            owner: "AccrueAdmin.Components.Overlay.overlay/1",
            evidence: [
              %{
                path: "accrue_admin/lib/accrue_admin/components/overlay.ex",
                marker: "def overlay(assigns) do"
              },
              %{path: "storybook/components/overlay.story.exs", marker: "overlay_story"}
            ]
          },
          "Only Storybook coverage of the Overlay primitive API (desktop and mobile drawer, modal and popover shells, reduced motion). The subscription action drawer exercises one presentation of it.",
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/overlay_components_test.exs#renders drawer presentation through the body-level overlay root",
            protects:
              "Overlay renders every presentation through the body-level overlay root with its focus contract"
          }
        ),
        primitive_retain_record(
          "CUR-254-03",
          "/components/page_header",
          %{
            owner: "AccrueAdmin.Components.PageHeader.page_header/1",
            evidence: [
              %{
                path: "accrue_admin/lib/accrue_admin/components/page_header.ex",
                marker: "def page_header(assigns) do"
              },
              %{path: "storybook/components/page_header.story.exs", marker: "page_header_story"}
            ]
          },
          "Only Storybook coverage of the PageHeader slot contract (actions, stat strip, filter toolbar, long content, combined controls) outside the subscription collection page.",
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/page_header_test.exs#renders breadcrumbs, required title, semantic markers, and exactly one h1",
            protects:
              "PageHeader keeps its breadcrumb, title, semantic marker and single h1 slot contract"
          }
        ),
        braintree_pruned_record(),
        dunning_active_record(),
        populated_retire_record(),
        provider_pruned_merge_record()
      ]
    end

    # D-40: the compatibility id `populated` was a pure alias. The fact source delegated
    # `fetch!(:populated)` to `fetch!(:active)` and the generated expected block is identical, so
    # the two story variations render the same thing. The blocks below are pinned literals taken
    # from the manifest at the origin commit (never recomputed, the entry no longer exists);
    # verify_phase254_curation.mjs re-derives both blocks and the alias from `git show` at
    # provenance.origin_commit and fails on any difference.
    @populated_origin_commit "9b40acc8e53ca4d2eeb9a984dbc744097f92bc98"
    @active_blocks %{
      fact: %{
        actor: "vendor billing support operator",
        job: "understand subscription state and choose a supported next action",
        input_source: "deterministic Cadence scenario facts",
        production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
        proof_lane: "static render",
        composition_tier: "component"
      },
      expected: %{
        identity: %{
          actor: "vendor billing support operator",
          owner_slug: "cadence-demo",
          customer_id: "3a632d30-37d1-4c08-a5bf-2b14f2862520",
          customer_processor_id: "cus_cadence_active",
          customer_name: "Acme Research",
          subscription_id: "ea26f232-b276-42bb-b862-d5c1b7d9d457",
          subscription_processor_id: "sub_cadence_active"
        },
        facts: %{
          currency: "usd",
          amount_minor: 12_500,
          price_ids: ["pro_monthly_2026"],
          quantities: [12]
        },
        lifecycle: %{
          status: "active",
          cancel_at_period_end: false,
          current_period_start: "2026-10-24T12:00:00Z",
          current_period_end: "2026-11-24T12:00:00Z"
        },
        actions: %{
          owner: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          proof: "rendered by production eligibility; no action dispatch claim"
        }
      }
    }

    defp populated_retire_record do
      %{
        id: "CUR-254-06",
        subject: %{
          story_path: @subscription_story_path,
          variation_id: "populated",
          scenario_id: "populated"
        },
        disposition: "retire",
        reason_class: "duplicate",
        reachability: %{
          state: "historic_supported",
          owner: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          evidence: [
            %{
              path: "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
              marker: "def subscription_area(assigns) do"
            },
            %{
              path: "accrue_admin/storybook/_support/subscription_manifest.ex",
              marker: "@frozen_compatibility_ids [\"braintree_pruned\", \"dunning_active\", \"populated\"]"
            }
          ]
        },
        reason:
          "A pure alias: the fact source delegated fetch!(:populated) to fetch!(:active) and the generated expected block equals the active block, so the variation renders exactly what active renders. The survivors are the subscription_detail active variation and the page-tier active story.",
        reason_evidence: %{kind: "fact_expected_equality"},
        duplicate_evidence: %{subject: @active_blocks, survivor: @active_blocks},
        alias_evidence: %{
          facts_path: "dev_support/ui_scenarios/cadence_subscriptions.exs",
          subject_scenario: "populated",
          survivor_scenario: "active"
        },
        survivor: %{kind: "manifest_entry", key: "#{@subscription_story_path}||active"},
        additional_survivors: [
          %{kind: "story", key: "/pages/subscription", variation_id: "active"}
        ],
        preserved_regressions: [
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#the declared active variation renders the production area from real facts without Repo",
            protects:
              "the active subscription_detail variation renders the production area from the same facts the alias used"
          },
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs#canonical lifecycle variation IDs sit beside preserved compatibility IDs",
            protects:
              "the remaining compatibility ids stay story variations and the retired id stays absent"
          },
          %{
            test_ref:
              "accrue_admin/e2e/subscription-stories-phase252.spec.js#reconciles every declared direct render against the generated manifest",
            protects:
              "every remaining compatibility render case (braintree_pruned, dunning_active) still renders in the browser lane"
          }
        ],
        reference_scan: %{
          # The frozen baseline legitimately names the retired id, and the manifest test asserts it
          # as a positive control. A context pattern keeps unrelated "populated" list-state markers
          # (data-ax-state, test titles) from counting as references to this variation.
          allowed_paths: [
            "accrue_admin/storybook/_support/subscription_manifest.ex",
            "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs"
          ],
          contexts: [
            ":populated\\b",
            "\\|\\|populated\\b",
            "variation_id=populated\\b",
            "\\bvariation_id\\b.*[\"']populated[\"']",
            "\\b(scenario_id|route_variation_id)[\"']?\\s*[:=]+\\s*[\"']populated[\"']"
          ]
        },
        kitchen_impact: "none",
        provenance: %{origin_commit: @populated_origin_commit, decided_in: "254-06-02"}
      }
    end

    # D-40: retained and reclassified; the provider-pruned action menu is a provider-boundary
    # negative, not a canonical lifecycle state.
    defp braintree_pruned_record do
      %{
        id: "CUR-254-04",
        subject: %{
          story_path: @subscription_story_path,
          variation_id: "braintree_pruned",
          scenario_id: "braintree_pruned"
        },
        disposition: "reclassify",
        classification: "provider-boundary negative",
        reason_class: nil,
        reachability: %{
          state: "reachable",
          owner: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          evidence: [
            %{
              path: "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
              marker: "braintree_processor?(@subscription)"
            },
            %{
              path: "dev_support/ui_scenarios/cadence_subscriptions.exs",
              marker: "def fetch!(:braintree_pruned)"
            }
          ]
        },
        reason:
          "A Braintree-backed subscription prunes unsupported provider actions and shows Braintree guidance instead. The variation is the only subscription_detail story that proves the provider boundary, so it is retained and reclassified as a provider-boundary negative rather than a lifecycle state.",
        reason_evidence: %{kind: "provider_boundary_negative"},
        survivor: %{kind: "manifest_entry", key: "#{@subscription_story_path}||braintree_pruned"},
        preserved_regressions: [
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#provider-pruned empty action groups are omitted for a valid Braintree subscription",
            protects:
              "a Braintree subscription renders only its supported danger-zone action group and omits empty provider-pruned groups"
          }
        ],
        kitchen_impact: "none",
        provenance: %{origin_commit: @frozen_source_commit, decided_in: "254-04-03"}
      }
    end

    # D-40: the Phase 195 spec promised a default-open recovery drill for this subscription; the
    # compatibility story now renders the production area's Dunning row only.
    defp dunning_active_record do
      %{
        id: "CUR-254-05",
        subject: %{
          story_path: @subscription_story_path,
          variation_id: "dunning_active",
          scenario_id: "dunning_active"
        },
        disposition: "reclassify",
        classification: "recovery-claim drift",
        reason_class: nil,
        reachability: %{
          state: "reachable",
          owner: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          evidence: [
            %{
              path:
                ".planning/milestones/v1.54-phases/195-exemplar-b-subscription-detail/195-UI-SPEC.md",
              marker: "dunning-active default-open recovery drill"
            },
            %{
              path: "accrue_admin/test/accrue_admin/components/subscription_area_test.exs",
              marker: "summary_row(dunning, \"Dunning\") != nil"
            }
          ]
        },
        reason:
          "Claim drift: Phase 195 described this variation as a dunning-active default-open recovery drill (recovery drill open), but the story now renders the production subscription area, whose recovery evidence is a Dunning row only. The variation is retained for the optional Dunning row. The page-tier past-due and recovery state is uncovered and stays gated on retry/campaign-history integrity.",
        reason_evidence: %{kind: "claim_drift"},
        gap: %{
          state: "page-tier past-due and dunning recovery",
          entry_trigger: "retry/campaign-history integrity"
        },
        survivor: %{kind: "manifest_entry", key: "#{@subscription_story_path}||dunning_active"},
        preserved_regressions: [
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#optional seats and dunning rows follow real item and lifecycle evidence",
            protects:
              "the Dunning row appears only for a subscription with a started dunning campaign"
          }
        ],
        kitchen_impact: "none",
        provenance: %{origin_commit: @frozen_source_commit, decided_in: "254-04-03"}
      }
    end

    # D-40: action_menu/provider_pruned is merged into two survivors. Its menu shape duplicates the
    # `danger` variation (one open Danger zone group of danger items); its provider claim was a
    # story-local rule, so the real provider-boundary claim lives in subscription_detail
    # braintree_pruned. The shape blocks are pinned literals taken from the story source at the
    # origin commit; verify_phase254_curation.mjs re-parses both variations there and fails on any
    # difference, and re-parses the surviving `danger` variation in the current tree.
    @provider_pruned_origin_commit "fdcd6c4ebf57543b9ba7df5a40e5b8271fb79bf1"
    @danger_zone_shape %{
      fact: %{story_state: "open"},
      expected: %{group_shape: [%{label: "Danger zone", item_kinds: ["danger"]}]}
    }

    defp provider_pruned_merge_record do
      %{
        id: "CUR-254-07",
        subject: %{
          story_path: "/components/action_menu",
          variation_id: "provider_pruned",
          scenario_id: nil
        },
        disposition: "merge",
        reason_class: "duplicate",
        reachability: %{
          state: "reachable",
          owner: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          evidence: [
            %{
              path: "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
              marker: "braintree_processor?(@subscription)"
            },
            %{
              path: "accrue_admin/lib/accrue_admin/components/dropdown_menu.ex",
              marker: "def action_menu(assigns) do"
            }
          ]
        },
        reason:
          "Duplicate menu shape plus a stale story-local provider rule. provider_pruned renders one open Danger zone group of danger items, the same shape the danger variation renders (story state, group label sequence and item kinds; item count and description text are not part of the shape). Its provider claim was a hand-written Stripe-only description on one item that production eligibility never used; the real Braintree pruning is rendered by SubscriptionLive.subscription_area/1 through the braintree_pruned subscription_detail variation and pinned by the provider-pruned regression.",
        reason_evidence: %{kind: "fact_expected_equality"},
        duplicate_evidence: %{subject: @danger_zone_shape, survivor: @danger_zone_shape},
        shape_evidence: %{
          path: "storybook/components/action_menu.story.exs",
          subject: %{variation_id: "provider_pruned", groups: "provider_pruned_groups"},
          survivor: %{variation_id: "danger", groups: "danger_groups"}
        },
        survivor: %{kind: "story", key: "/components/action_menu", variation_id: "danger"},
        additional_survivors: [
          %{kind: "manifest_entry", key: "#{@subscription_story_path}||braintree_pruned"}
        ],
        preserved_regressions: [
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/overlay_components_test.exs#renders a non-modal disclosure menu with button menuitems",
            protects:
              "the action menu keeps its Danger zone group last with danger-styled menu items (the shape danger and provider_pruned shared)"
          },
          %{
            test_ref:
              "accrue_admin/test/accrue_admin/components/subscription_area_test.exs#provider-pruned empty action groups are omitted for a valid Braintree subscription",
            protects:
              "a Braintree subscription renders only its supported Danger zone group through the production owner (the real provider claim)"
          }
        ],
        reference_scan: %{
          allowed_paths: [
            "accrue_admin/storybook/_support/subscription_manifest.ex",
            "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs"
          ]
        },
        kitchen_impact: "none",
        provenance: %{origin_commit: @provider_pruned_origin_commit, decided_in: "254-06-03"}
      }
    end

    defp reclassification_for(story_path, variation_id) do
      Enum.find_value(curation_records(), {nil, nil}, fn record ->
        if record.disposition == "reclassify" and record.subject.story_path == story_path and
             record.subject.variation_id == variation_id do
          {record.id, record.classification}
        end
      end)
    end

    defp primitive_retain_record(id, story_path, reachability, reason, regression) do
      %{
        id: id,
        subject: %{story_path: story_path, variation_id: nil, scenario_id: nil},
        disposition: "retain",
        reason_class: nil,
        reachability: Map.put(reachability, :state, "reachable"),
        reason: reason,
        reason_evidence: %{kind: "retained_primitive_regression"},
        survivor: %{kind: "story", key: story_path},
        preserved_regressions: [regression],
        kitchen_impact: "none",
        provenance: %{origin_commit: @frozen_source_commit, decided_in: "254-04-01"}
      }
    end

    defp normalize_curation_record!(record, baseline) when is_map(record) do
      for field <- [:id, :disposition, :reason] do
        unless non_empty_string?(Map.get(record, field)) do
          raise ArgumentError, "curation record is missing #{field}"
        end
      end

      unless record.disposition in @curation_dispositions do
        raise ArgumentError,
              "curation record #{record.id} has unsupported disposition: #{inspect(record.disposition)}"
      end

      unless Regex.match?(~r/\ACUR-254-\d{2,}\z/, record.id) do
        raise ArgumentError, "curation record id must look like CUR-254-NN: #{record.id}"
      end

      reason_class = Map.get(record, :reason_class)

      if record.disposition in ["retire", "merge"] and reason_class not in @curation_reason_classes do
        raise ArgumentError,
              "curation record #{record.id} (#{record.disposition}) needs a reason class: #{inspect(reason_class)}"
      end

      if reason_class != nil and reason_class not in @curation_reason_classes do
        raise ArgumentError,
              "curation record #{record.id} has unsupported reason class: #{inspect(reason_class)}"
      end

      subject = Map.get(record, :subject, %{})

      unless non_empty_string?(Map.get(subject, :story_path)) do
        raise ArgumentError, "curation record #{record.id} is missing subject.story_path"
      end

      unless Enum.any?(baseline.subjects, fn frozen ->
               frozen.story_path == subject.story_path and
                 (subject.variation_id == nil or frozen.variation_id == subject.variation_id)
             end) do
        raise ArgumentError,
              "curation record #{record.id} subject #{inspect(subject)} is absent from the frozen baseline"
      end

      reachability = Map.get(record, :reachability, %{})

      unless Map.get(reachability, :state) in @curation_reachability_states and
               non_empty_string?(Map.get(reachability, :owner)) and
               Map.get(reachability, :evidence, []) != [] do
        raise ArgumentError,
              "curation record #{record.id} needs reachability state, owner, and evidence"
      end

      unless Map.get(record.survivor, :kind) in @curation_survivor_kinds and
               non_empty_string?(Map.get(record.survivor, :key)) do
        raise ArgumentError, "curation record #{record.id} needs a survivor kind and key"
      end

      for extra <- Map.get(record, :additional_survivors, []) do
        unless Map.get(extra, :kind) in @curation_survivor_kinds and
                 non_empty_string?(Map.get(extra, :key)) do
          raise ArgumentError, "curation record #{record.id} has an invalid additional survivor"
        end
      end

      if record.disposition in ["retire", "merge"] and reason_class == "duplicate" do
        evidence = Map.get(record, :duplicate_evidence)

        unless is_map(evidence) and is_map(Map.get(evidence, :subject)) and
                 Map.get(evidence, :subject) == Map.get(evidence, :survivor) do
          raise ArgumentError,
                "curation record #{record.id} is a duplicate and needs equal subject and survivor evidence blocks"
        end
      end

      unless Map.get(record, :preserved_regressions, []) != [] do
        raise ArgumentError, "curation record #{record.id} needs a preserved regression"
      end

      unless Map.get(record, :kitchen_impact) == "none" do
        raise ArgumentError, "curation record #{record.id} must have kitchen_impact none"
      end

      if record.disposition == "reclassify" and not non_empty_string?(Map.get(record, :classification)) do
        raise ArgumentError, "curation record #{record.id} (reclassify) needs a classification"
      end

      record
    end

    defp normalize_curation_record!(_record, _baseline),
      do: raise(ArgumentError, "curation record must be a map")

    @doc "Writes the curation ledger as deterministic JSON through a temp file and an atomic rename."
    @spec write_curation!(Path.t(), keyword()) :: :ok
    def write_curation!(path, opts \\ []) when is_binary(path) do
      writer = Keyword.get(opts, :writer, &File.write!/2)

      json =
        curation_ledger()
        |> ordered_json()
        |> Jason.encode!(pretty: true)
        |> Kernel.<>("\n")

      path |> Path.dirname() |> File.mkdir_p!()
      temp = "#{path}.tmp-#{System.unique_integer([:positive])}"

      try do
        writer.(temp, json)
        File.rename!(temp, path)
        :ok
      after
        File.rm(temp)
      end
    end

    @doc "Rejects a committed curation ledger that differs from the one compiled from current source."
    @spec verify_curation!(Path.t()) :: :ok
    def verify_curation!(path) when is_binary(path) do
      committed = path |> File.read!() |> Jason.decode!()
      current = curation_ledger() |> Jason.encode!() |> Jason.decode!()

      unless committed == current do
        raise ArgumentError,
              "curation ledger is stale; regenerate it with node scripts/ci/verify_phase254_curation.mjs --write"
      end

      :ok
    end

    # BEAM map key order is not alphabetical, so every map is rewritten as an ordered object to keep
    # the generated bytes stable across builds.
    defp ordered_json(%{} = map) when not is_struct(map) do
      map
      |> Enum.map(fn {key, value} -> {to_string(key), ordered_json(value)} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Jason.OrderedObject.new()
    end

    defp ordered_json(list) when is_list(list), do: Enum.map(list, &ordered_json/1)
    defp ordered_json(other), do: other

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
            entry.variation_id in @frozen_compatibility_ids

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
          "reachable",
          reason:
            "The legacy detail Storybook route renders subscription_area/1 only. It does not prove the whole-page shell, breadcrumb, related resources, drill sections, or full-page route; the whole page is covered by the Phase 253 page stories listed here (presentation only).",
          manifest_keys: @phase253_page_keys,
          story_path: "/pages/subscription",
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
          "reachable",
          reason:
            "Covered by the Phase 253 collection stories listed here (presentation only: the actual toolbar, result, table and pagination composition for each declared state); mounted list behavior is proven by the mounted tests.",
          manifest_keys: @phase253_collection_keys,
          story_path: "/groups/subscriptions_collection",
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
          "reachable",
          reason:
            "Covered by SBK-06: the mounted journey test accrue_admin/test/accrue_admin/live/subscription_journey_test.exs follows list, detail, action review, step-up, result and context-preserving return, and the Phase 253 page stories listed here show the review and result states as presentation only. Static stories alone still do not exercise mount authorization, step-up, preview, confirmation, provider results, or persistence.",
          manifest_keys: @phase253_journey_page_keys,
          story_path: "/pages/subscription",
          extra: %{covering_requirement: "SBK-06", covering_test: @sbk06_journey_test},
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
        curation_section(),
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

    defp curation_section do
      baseline = frozen_baseline()

      record_rows =
        Enum.map(curation_records(), fn record ->
          subject =
            case record.subject.variation_id do
              nil -> "`#{guide_cell(record.subject.story_path)}` (story)"
              id -> "`#{guide_cell(record.subject.story_path)}||#{guide_cell(id)}`"
            end

          regressions =
            record.preserved_regressions
            |> Enum.map(&"`#{guide_cell(&1.test_ref)}`")
            |> Enum.join("<br>")

          survivors =
            [record.survivor | Map.get(record, :additional_survivors, [])]
            |> Enum.map(fn survivor ->
              key =
                case Map.get(survivor, :variation_id) do
                  nil -> survivor.key
                  id -> "#{survivor.key}||#{id}"
                end

              "`#{guide_cell(key)}`"
            end)
            |> Enum.join("<br>")

          "| #{record.id} | #{subject} | #{record.disposition} | #{guide_cell(Map.get(record, :reason_class) || Map.get(record, :classification))} | #{record.reachability.state} (#{guide_cell(record.reachability.owner)}) | #{survivors} | #{regressions} | #{guide_cell(record.reason)} |"
        end)

      amendment_rows =
        Enum.map(curation_amendments(), fn amendment ->
          "- **#{amendment.id}** (#{Enum.join(amendment.decisions, ", ")}): #{amendment.amended} Owner acknowledgement: #{amendment.owner_ack.status}, #{amendment.owner_ack.date}."
        end)

      [
        "## Curation ledger",
        "",
        "Generated from `SubscriptionManifest.curation_ledger/0` into `#{@curation_guide_path}` and verified by `scripts/ci/verify_phase254_curation.mjs`. A story is retired or merged only with mechanical evidence (fact and expected-block equality, a replacing owner, or a failing fixture invariant), a surviving subject that still renders, and a preserved regression that runs in a required lane. Grep absence and screenshot similarity are never evidence.",
        "",
        "Frozen baseline at `#{baseline.source_commit}`: #{baseline.entries} canonical and compatibility entries (compatibility ids #{Enum.map_join(baseline.compatibility_ids, ", ", &"`#{&1}`")}), #{length(baseline.subjects)} enumerated subjects, #{baseline.registry.family_count} registry families, #{baseline.registry.entry_count} registry entries and #{baseline.registry.specimen_count} specimens. The kitchen at `/dev/components` is untouched (`kitchen_impact: none`).",
        "",
        "| Record | Subject | Disposition | Reason class or classification | Reachability | Survivor | Preserved regressions | Reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
        record_rows,
        "",
        "### Amendments",
        "",
        amendment_rows,
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
      {curation_record, curation_classification} = reclassification_for(path, to_string(variation_id))

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
        curation_record: curation_record,
        curation_classification: curation_classification,
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
