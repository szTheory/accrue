---
phase: 252-production-backed-subscription-stories
plan: "08"
subsystem: ci-and-acceptance
tags: [ci, subscriptions, storybook, browser-evidence, automated-uat]
requires:
  - phase: 252-04
    provides: Persisted scenario facts, cleanup ownership, and held-out database lane
  - phase: 252-06
    provides: Twelve canonical browser cells, twenty UI predicates, and served asset evidence
  - phase: 252-07
    provides: Fresh production compiles and unpacked package boundary checks
provides:
  - Consumed-root classifier and unconditional required CI owner contract
  - Serial Phase 252 owner with isolated builds, guarded numeric database partitions, and current browser evidence
  - Acceptance generator mapping ten requirements, three tasks, thirteen classified edges, and twenty UI predicates to fresh evidence
  - Automated UAT output sourced from all eight completed plan summaries
affects: [252-phase-verification, ci-required-checks, subscription-story-coverage]
tech-stack:
  added: []
  patterns: [serial digest-pinned acceptance owner, exact browser cell reconciliation, archive-aware phase evidence reads]
key-files:
  created:
    - scripts/ci/phase252_paths.mjs
    - scripts/ci/verify_phase252_ci_contract.test.mjs
    - scripts/ci/verify_phase252_stories.mjs
    - scripts/ci/generate_phase252_acceptance.mjs
    - scripts/ci/generate_phase252_acceptance.test.mjs
    - .planning/phases/252-production-backed-subscription-stories/252-08-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-08-02-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-08-02-sequence-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-08-03-red-evidence.json
  modified:
    - .github/workflows/ci.yml
    - .gitignore
    - .planning/phases/252-production-backed-subscription-stories/252-05-SUMMARY.md
    - accrue_admin/package.json
    - accrue_admin/e2e/phase252-story-helpers.js
    - accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
    - scripts/ci/verify_phase200_admin_guardrails.sh
    - scripts/ci/verify_phase200_guardrail_contract.sh
key-decisions:
  - "Run the full owner serially with unique numeric partitions and isolated Mix build outputs so every mutable lane belongs to this run."
  - "Treat static browser cells, mounted authorization, persisted state, and reset isolation as separate evidence claims."
  - "Keep four unclassified assumptions and two descriptor-less prohibitions visibly unresolved while reporting their concrete behavior coverage separately."
  - "Upload structured result bundles and per-run browser JSON; keep raw command logs out of CI artifacts."
actuals:
  tokens: 36667
  tasks: 3
  commits: 7
commits: 7
plan_head_before: 928f8533b7a8e2ac98d2c5403f16ac887d189b29
plan_head_after: 2e27f4cb02252c2f864a1acdfef522e731834d7f
metrics:
  duration: 82min
  started: 2026-10-26T23:15:06-04:00
  completed: 2026-10-27
  tasks: 3
  files: 18
status: complete
human_judgment: false
requirements-completed: [CIQ-01, SBK-01, SBK-02, SBK-03, SCEN-01, SCEN-02, SCEN-03, SCEN-04, LAB-01, LAB-02]
coverage:
  - id: CIQ-01
    description: "Every consumed Phase 252 root reaches the named required guardrail owner through unconditional pull request workflow admission."
    requirement: CIQ-01
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:consumed_root_owner_map"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:workflow_admission"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:named_required_owner_execution"
        status: pass
    human_judgment: false
  - id: SBK-01
    description: "The compiled caller map preserves caller identity adjacency, rejects empty caller sources, and remains deterministically ordered."
    requirement: SBK-01
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:current_caller_map"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:caller_identity_adjacency"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:empty_caller_source_refusal"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:stable_caller_ordering"
        status: pass
    human_judgment: false
  - id: SBK-02
    description: "Compiled story variations retain direct routes and deterministic manifest ordering, with twelve independent render cells."
    requirement: SBK-02
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:compiled_variation_routes"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:story_variation_identity_adjacency"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:zero_variation_and_missing_attribution_refusal"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:deterministic_manifest_ordering"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:exact_twelve_canonical_width_theme_cells"
        status: pass
    human_judgment: false
  - id: SBK-03
    description: "The story uses the production subscription renderer and passes all twenty independent UI predicates."
    requirement: SBK-03
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:story-slice:shared_renderer_and_active_variation"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:exact_twelve_canonical_width_theme_cells"
        status: pass
    human_judgment: false
  - id: SCEN-01
    description: "Deterministic launch and team facts pass domain validation, persisted reload, and held-out identity separation."
    requirement: SCEN-01
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-domain:deterministic_fact_source"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:persisted_launch_and_team_facts"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:heldout_identity_separation"
        status: pass
    human_judgment: false
  - id: SCEN-02
    description: "Cancellation boundaries use the fixed clock and money values preserve exact minor unit precision."
    requirement: SCEN-02
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-domain:canceling_boundary_exact_clock"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-domain:exact_minor_unit_money_precision"
        status: pass
    human_judgment: false
  - id: SCEN-03
    description: "Persisted scenario graphs satisfy constraints, reject conflicting replay, roll back interruptions, and serialize concurrent inserts."
    requirement: SCEN-03
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:persisted_launch_and_team_facts"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:replay_identity_conflict_refusal"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:transaction_rollback"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:concurrent_insert_serialization"
        status: pass
    human_judgment: false
  - id: SCEN-04
    description: "Guarded cleanup is idempotent, ownership-scoped, and preserves unrelated children under concurrency."
    requirement: SCEN-04
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:exact_cleanup_authority"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:cleanup_idempotency_absence_mismatch"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:serialized_unrelated_child_concurrency"
        status: pass
    human_judgment: false
  - id: LAB-01
    description: "The lab enforces resource identity and process ownership, while reset isolation preserves the separate review database."
    requirement: LAB-01
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-lab-contract:namespace_lock_one_owner"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-lab-contract:exact_process_identity_cleanup"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:isolation-reset:distinct_review_process_and_database"
        status: pass
    human_judgment: false
  - id: LAB-02
    description: "Fresh production compiles and unpacked package inspections preserve development routes and keep fixtures outside production packages."
    requirement: LAB-02
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:production-packages:fresh_production_compiles"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:production-packages:actual_unpacked_hex_archives"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:production-boundary-controls:development_positive_production_route_exclusion"
        status: pass
    human_judgment: false
  - id: 252-08-01
    description: "Consumed roots, unconditional workflow admission, and required owner invocation mutations are checked."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:consumed_root_owner_map"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:workflow_admission"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-ci-contract:required_owner_invocation_mutations"
        status: pass
    human_judgment: false
  - id: 252-08-02
    description: "The fresh serial required owner completed every source, package, database, isolation, and browser command."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#bundle:all_required_commands_passed"
        status: pass
    human_judgment: false
  - id: 252-08-03
    description: "Acceptance fixtures reject missing, failed, stale, pooled, incomplete, unsafe-path, and mutated-guide evidence."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:missing_command_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:failed_command_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:stale_source_and_asset_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:pooled_cell_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:missing_predicate_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:unsafe_evidence_path_rejection"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-acceptance-contract:guide_contract_mutation_rejection"
        status: pass
    human_judgment: false
  - id: EDGE-LAB-01-concurrency
    description: "Concurrent lab starts, stale lock owners, and exact process cleanup all preserve resource ownership."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-lab-contract:namespace_lock_one_owner"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-lab-contract:stale_lock_owner_refusal"
        status: pass
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:phase252-lab-contract:exact_process_identity_cleanup"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-01-adjacency
    description: "Caller identity facts remain adjacent to their resolved compiled caller record."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:caller_identity_adjacency"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-01-empty
    description: "An empty caller source is refused rather than represented as complete coverage."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:empty_caller_source_refusal"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-01-ordering
    description: "Caller entries preserve deterministic order."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:stable_caller_ordering"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-02-adjacency
    description: "Story variation identity remains adjacent to its generated route."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:story_variation_identity_adjacency"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-02-empty
    description: "Missing attribution and zero-variation declarations are rejected."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:zero_variation_and_missing_attribution_refusal"
        status: pass
    human_judgment: false
  - id: EDGE-SBK-02-ordering
    description: "Generated manifest output is deterministic."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:manifest-contract:deterministic_manifest_ordering"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-02-boundary
    description: "Cancellation state follows the exact fixed-clock boundary."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-domain:canceling_boundary_exact_clock"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-02-precision
    description: "Money values retain exact integer minor-unit precision."
    verification:
      - kind: unit
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-domain:exact_minor_unit_money_precision"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-03-concurrency
    description: "Transactions roll back partial scenario graphs and serialize concurrent inserts."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:transaction_rollback"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:concurrent_insert_serialization"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-03-idempotency
    description: "Same-identity scenario replay is checked against persisted launch and team facts."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:persisted_launch_and_team_facts"
        status: pass
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:scenario-repo:replay_identity_conflict_refusal"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-04-concurrency
    description: "Cleanup serializes ownership checks and deletes while unrelated child inserts remain protected."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:serialized_unrelated_child_concurrency"
        status: pass
    human_judgment: false
  - id: EDGE-SCEN-04-idempotency
    description: "Repeated cleanup handles absent rows safely and refuses mismatched ownership."
    verification:
      - kind: integration
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:heldout-cleanup:cleanup_idempotency_absence_mismatch"
        status: pass
    human_judgment: false
  - id: UI-E1-loading
    description: "E1 loading and settled content behavior passes on each mapped canonical cell."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E1-loading"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E1-error
    description: "E1 error state controls reject invalid route, missing variation, metadata-only content, and authority regression."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E1-error"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E1-overflow
    description: "E1 content geometry and keyboard focus remain valid at narrow and desktop widths."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E1-overflow"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E1-long-text
    description: "E1 ordinary and held-out long text wraps and the full identifier copy control remains available."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E1-long-text"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-empty
    description: "E2 requires core facts while omitting optional rows for empty input."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-empty"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-loading
    description: "E2 loading artifacts clear before settled content is asserted in every canonical cell."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-loading"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-error
    description: "E2 error state rejects bad routes, missing variations, metadata-only output, and authority regression."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-error"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-populated
    description: "E2 populated state reconciles render attribution with actual facts and eligible actions."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-populated"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-partial
    description: "E2 incomplete evidence exposes unavailable values and ordered caveats only on incomplete cells."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-partial"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-overflow
    description: "E2 facts and action content remain inside the document with visible keyboard focus."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-overflow"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-zero-one-many
    description: "E2 optional rows and action groups track the declared zero-one-many inputs."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-zero-one-many"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E2-long-text
    description: "E2 ordinary and held-out long text wraps and the complete identifier copies on long-text cells."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E2-long-text"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-empty
    description: "E3 requires core facts, omits optional empty rows, and preserves scoped not-found behavior."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-empty"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-loading
    description: "E3 loading artifacts clear before settled content is asserted in every canonical cell."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-loading"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-error
    description: "E3 error state rejects invalid route, missing variation, metadata-only output, and authority regression."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-error"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-populated
    description: "E3 populated state reconciles render attribution with actual facts and eligible actions."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-populated"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-partial
    description: "E3 incomplete evidence reports unavailable values and ordered caveats on incomplete cells."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-partial"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-overflow
    description: "E3 content geometry contains required facts and actions with visible keyboard focus."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-overflow"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-zero-one-many
    description: "E3 optional rows and action groups track the declared zero-one-many inputs."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-zero-one-many"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
  - id: UI-E3-long-text
    description: "E3 ordinary and held-out long text wraps and the complete identifier copies on long-text cells."
    verification:
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/render-results-25208-1793075457515-88834-5ee13886b28a.json#ui:UI-E3-long-text"
        status: pass
      - kind: automated_ui
        ref: "accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json#commands:subscription-render-browser:twenty_ui_predicates"
        status: pass
    human_judgment: false
---

# Phase 252 Plan 08: Required CI Owner and Automated Acceptance Summary

**A serial CI owner now proves Phase 252 with fresh command logs, source and served-asset digests, production builds, isolated database lanes, and independently reconciled browser cells.**

## Performance

- **Duration:** 82 minutes
- **Started:** 2026-10-26T23:15:06-04:00
- **Completed:** 2026-10-27
- **Tasks:** 3
- **Files changed by this plan:** 18
- **Measured diff estimate:** 145,907 characters / 4 = 36,477 tokens

## Accomplishments

- Added the consumed-root classifier and mutation-tested workflow contract. The required `admin-phase200-guardrails` job remains admitted unconditionally on pull requests, while positive Phase 252 roots route to the owner and unrelated paths do not enter its focused classification.
- Extended the complete serial `phase252:check` owner to capture unique command records, isolated builds, numeric disposable database partitions, fresh source snapshots, current manifest identity, costs, and actual per-run browser output. The owner stops at the first failed command and cannot write a passing bundle after failed acceptance validation.
- Added complete acceptance mapping for ten requirements, three plan tasks, thirteen classified edge predicates, and twenty UI predicates. The validator rejects missing or failed commands, stale digests, reused partitions, incomplete manifest attribution, pooled render cells, missing predicate assertions, unsafe paths, and guide contract drift.
- Preserved the four unclassified assumptions and two descriptor-less prohibitions as unresolved metadata, with concrete behavior coverage listed separately from any probe verdict.
- Added a CI artifact upload for result bundles and per-run browser JSON. Raw command logs are not published.
- The fresh required owner completed 18 commands, including three fresh production packages, isolated persisted and cleanup lanes, reset-isolation proof, twelve canonical browser cells, three compatibility cases, and the acceptance fixture suite. The acceptance bundle is `accrue_admin/tmp/phase252/ci-results/25208-1793075457515-88834-5ee13886b28a/results.json`.

## Verification

- `node --test scripts/ci/generate_phase252_acceptance.test.mjs scripts/ci/verify_phase252_ci_contract.test.mjs` — 22 tests passed.
- `npm --prefix accrue_admin run phase252:check` — passed, 18/18 serial commands. Production packages: 132,092 ms; cold manifest compile: 66,642 ms; cold database startup: 2,609 ms; warm database lane: 3,138 ms; browser lane: 9,606 ms.
- `gsd_run check tdd-red-evidence .planning/phases/252-production-backed-subscription-stories/252-08-03-red-evidence.json --raw` — `RED_EVIDENCE_OK`; the designated acceptance test failed against the unimplemented validator before implementation.

## TDD Gate Compliance

- **RED:** `252-08-03-red-evidence.json` records the target evidence-validation test failing at the intentional stub.
- **GREEN:** the complete acceptance and CI contract suite passed, then the real aggregate owner passed all 18 commands and validated the fresh bundle.

## Unresolved Probe Metadata

The acceptance bundle retains `EDGE-CIQ-01-unclassified`, `EDGE-LAB-02-unclassified`, `EDGE-SBK-03-unclassified`, and `EDGE-SCEN-01-unclassified` with `status: unresolved`. Their concrete CI, package, story, UI, domain, persisted, and held-out behavior refs are included in the acceptance object in the owner result bundle. The plan 01 and plan 04 prohibitions remain `status: unresolved` with their original `flagged-unverified` reasons. None is reported as a resolved probe verdict.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Matched the runner's deterministic source digest ordering**
- **Found during:** Task 3 aggregate owner validation
- **Issue:** The validator used locale collation while the owner fingerprints keys using JavaScript's default lexical order, so valid fresh evidence was rejected.
- **Fix:** Use the same default lexical ordering when recomputing the digest fingerprint.
- **Files modified:** `scripts/ci/generate_phase252_acceptance.mjs`

**2. [Rule 1 - Bug] Scoped held-out long-text evidence to its actual cells**
- **Found during:** Task 3 aggregate owner validation
- **Issue:** The validator required the held-out long-text assertion in every canonical cell, although the browser contract exercises it only for active 320px cells.
- **Fix:** Keep the assertion on the explicitly mapped long-text cells and require other render predicates on all canonical rows.
- **Files modified:** `scripts/ci/generate_phase252_acceptance.mjs`

**3. [Rule 1 - Bug] Parsed the validation ledger and nested prohibition metadata as written**
- **Found during:** Task 3 aggregate owner validation
- **Issue:** The validation ledger says “17 surfaced items” and the two prohibition records are indented under `must_haves` in plan frontmatter.
- **Fix:** Accept the documented wording and parse prohibition records at their actual YAML indentation while preserving unresolved status.
- **Files modified:** `scripts/ci/generate_phase252_acceptance.mjs`

**4. [Rule 2 - Missing critical metadata] Promoted Plan 05 completion status for archive-aware UAT**
- **Found during:** Task 3 UAT generation
- **Issue:** Plan 05 recorded completion only under `metrics.status`, so the shared UAT reader did not recognize the summary as complete.
- **Fix:** Added the existing completion status to summary frontmatter without changing its coverage or verification evidence.
- **Files modified:** `.planning/phases/252-production-backed-subscription-stories/252-05-SUMMARY.md`
- **Commit:** `2e27f4cb`

## Known Stubs

None found in the files created or modified by this plan.

## Self-Check: PASSED

- All 18 source files changed by the plan are accounted for in the key-file list.
- Task commits through `69c592a5dd4a2713b7e3960ecd4127d541371fe5` and the Plan 05 metadata correction commit `2e27f4cb02252c2f864a1acdfef522e731834d7f` exist on the assigned phase branch.
- The fresh owner result and browser result exist and carry matching run identity `25208-1793075457515-88834-5ee13886b28a`.
