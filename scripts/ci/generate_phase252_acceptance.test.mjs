#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { REQUIRED_COMMAND_IDS } from "./verify_phase252_stories.mjs";
import {
  generatePhase252Acceptance,
  validateGuideContract,
  validatePhase252Evidence,
} from "./generate_phase252_acceptance.mjs";

const PHASE_SLUG = "252-production-backed-subscription-stories";
const REQUIREMENTS = ["CIQ-01", "SBK-01", "SBK-02", "SBK-03", "SCEN-01", "SCEN-02", "SCEN-03", "SCEN-04", "LAB-01", "LAB-02"];
const TASK_IDS = ["252-08-01", "252-08-02", "252-08-03"];
const EDGE_IDS = [
  "EDGE-LAB-01-concurrency",
  "EDGE-SBK-01-adjacency", "EDGE-SBK-01-empty", "EDGE-SBK-01-ordering",
  "EDGE-SBK-02-adjacency", "EDGE-SBK-02-empty", "EDGE-SBK-02-ordering",
  "EDGE-SCEN-02-boundary", "EDGE-SCEN-02-precision",
  "EDGE-SCEN-03-concurrency", "EDGE-SCEN-03-idempotency",
  "EDGE-SCEN-04-concurrency", "EDGE-SCEN-04-idempotency",
];
const UNCLASSIFIED = [
  "EDGE-CIQ-01-unclassified", "EDGE-LAB-02-unclassified",
  "EDGE-SBK-03-unclassified", "EDGE-SCEN-01-unclassified",
];
const UI_IDS = [
  "UI-E1-loading", "UI-E1-error", "UI-E1-overflow", "UI-E1-long-text",
  "UI-E2-empty", "UI-E2-loading", "UI-E2-error", "UI-E2-populated", "UI-E2-partial", "UI-E2-overflow", "UI-E2-zero-one-many", "UI-E2-long-text",
  "UI-E3-empty", "UI-E3-loading", "UI-E3-error", "UI-E3-populated", "UI-E3-partial", "UI-E3-overflow", "UI-E3-zero-one-many", "UI-E3-long-text",
];

const ASSERTIONS = {
  "manifest-current": ["compiled_variation_discovery", "source_digest_freshness", "tracked_manifest_content_identity"],
  "phase252-lab-contract": ["owned_resource_identity", "unsafe_input_refusal", "cleanup_identity_guard", "namespace_lock_one_owner", "stale_lock_owner_refusal", "exact_process_identity_cleanup"],
  "scenario-domain": ["validated_deterministic_scenarios", "fixed_clock_and_identity", "deterministic_fact_source", "canceling_boundary_exact_clock", "exact_minor_unit_money_precision"],
  "subscription-area": ["production_area_content", "copy_and_scoped_action_semantics"],
  "story-slice": ["shared_renderer_and_active_variation", "no_repo_bootstrap"],
  "manifest-contract": ["compiled_variation_routes", "stable_group_and_same_id_keys", "current_caller_map", "stale_manifest_rejection", "story_variation_identity_adjacency", "zero_variation_and_missing_attribution_refusal", "deterministic_manifest_ordering", "caller_identity_adjacency", "empty_caller_source_refusal", "stable_caller_ordering"],
  "production-boundary-db-free": ["production_route_and_compile_boundary"],
  "phase248-heldout-contract": ["held_out_partition_and_owner"],
  "phase252-ci-contract": ["consumed_root_owner_map", "workflow_admission", "named_required_owner_execution", "required_owner_invocation_mutations"],
  "production-boundary-controls": ["production_package_leak_negative_controls", "development_positive_production_route_exclusion"],
  "production-packages": ["fresh_production_compiles", "actual_unpacked_hex_archives"],
  "scenario-repo": ["persisted_launch_and_team_facts", "database_constraints", "replay_identity_conflict_refusal", "transaction_rollback", "concurrent_insert_serialization"],
  "registry-kitchen-mount-scoped-path": ["registry_variant_and_token_reconciliation", "group_contract_and_mounted_kitchen", "production_caller_map_reconciliation", "served_storybook_assets", "development_and_production_route_boundaries", "scoped_return_path_safety"],
  "mounted-subscription-regressions": ["mounted_subscription_structure", "organization_scope_enforcement", "lifecycle_distinctions", "action_review_and_confirmation", "provider_action_boundaries", "authority_regression", "scoped_not_found_regression"],
  "heldout-cleanup": ["exact_cleanup_authority", "unrelated_child_preserved", "heldout_identity_separation", "cleanup_idempotency_absence_mismatch", "serialized_unrelated_child_concurrency"],
  "isolation-reset": ["normal_reset_positive_control", "review_data_unchanged_negative_control", "distinct_review_process_and_database"],
  "subscription-render-browser": ["exact_twelve_canonical_width_theme_cells", "three_compatibility_render_cases", "manifest_reconciliation_negative_controls", "twenty_ui_predicates", "served_assets_and_fonts"],
  "phase252-acceptance-contract": ["missing_command_rejection", "failed_command_rejection", "stale_source_and_asset_rejection", "pooled_cell_rejection", "missing_predicate_rejection", "unsafe_evidence_path_rejection", "guide_contract_mutation_rejection"],
};

const UI_ASSERTIONS = {
  "UI-E1-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E1-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E1-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E1-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
  "UI-E2-empty": ["required_facts_present", "optional_rows_omitted", "scoped_not_found_regression"],
  "UI-E2-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E2-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E2-populated": ["canonical_render_attribution", "actual_facts_and_actions"],
  "UI-E2-partial": ["unavailable_values_and_ordered_caveats"],
  "UI-E2-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E2-zero-one-many": ["optional_rows_and_action_groups_follow_inputs"],
  "UI-E2-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
  "UI-E3-empty": ["required_facts_present", "optional_rows_omitted", "scoped_not_found_regression"],
  "UI-E3-loading": ["settled_content_visible", "loading_artifacts_absent"],
  "UI-E3-error": ["negative_controls.invalid_route", "negative_controls.missing_variation", "negative_controls.metadata_only", "authority_regression"],
  "UI-E3-populated": ["canonical_render_attribution", "actual_facts_and_actions"],
  "UI-E3-partial": ["unavailable_values_and_ordered_caveats"],
  "UI-E3-overflow": ["document_and_required_content_geometry", "keyboard_focus_visible"],
  "UI-E3-zero-one-many": ["optional_rows_and_action_groups_follow_inputs"],
  "UI-E3-long-text": ["ordinary_content_complete", "held_out_long_text_complete", "full_id_copy"],
};

const EDGE_EVIDENCE = {
  "EDGE-LAB-01-concurrency": [["phase252-lab-contract", "namespace_lock_one_owner"], ["phase252-lab-contract", "stale_lock_owner_refusal"], ["phase252-lab-contract", "exact_process_identity_cleanup"]],
  "EDGE-SBK-01-adjacency": [["manifest-contract", "caller_identity_adjacency"]],
  "EDGE-SBK-01-empty": [["manifest-contract", "empty_caller_source_refusal"]],
  "EDGE-SBK-01-ordering": [["manifest-contract", "stable_caller_ordering"]],
  "EDGE-SBK-02-adjacency": [["manifest-contract", "story_variation_identity_adjacency"]],
  "EDGE-SBK-02-empty": [["manifest-contract", "zero_variation_and_missing_attribution_refusal"]],
  "EDGE-SBK-02-ordering": [["manifest-contract", "deterministic_manifest_ordering"]],
  "EDGE-SCEN-02-boundary": [["scenario-domain", "canceling_boundary_exact_clock"]],
  "EDGE-SCEN-02-precision": [["scenario-domain", "exact_minor_unit_money_precision"]],
  "EDGE-SCEN-03-concurrency": [["scenario-repo", "transaction_rollback"], ["scenario-repo", "concurrent_insert_serialization"]],
  "EDGE-SCEN-03-idempotency": [["scenario-repo", "persisted_launch_and_team_facts"], ["scenario-repo", "replay_identity_conflict_refusal"]],
  "EDGE-SCEN-04-concurrency": [["heldout-cleanup", "serialized_unrelated_child_concurrency"]],
  "EDGE-SCEN-04-idempotency": [["heldout-cleanup", "cleanup_idempotency_absence_mismatch"]],
};

const REQUIREMENT_EVIDENCE = {
  "CIQ-01": [["phase252-ci-contract", "consumed_root_owner_map"], ["phase252-ci-contract", "workflow_admission"], ["phase252-ci-contract", "named_required_owner_execution"]],
  "SBK-01": [["manifest-contract", "current_caller_map"], ["manifest-contract", "caller_identity_adjacency"], ["manifest-contract", "empty_caller_source_refusal"], ["manifest-contract", "stable_caller_ordering"]],
  "SBK-02": [["manifest-contract", "compiled_variation_routes"], ["manifest-contract", "story_variation_identity_adjacency"], ["manifest-contract", "zero_variation_and_missing_attribution_refusal"], ["manifest-contract", "deterministic_manifest_ordering"], ["subscription-render-browser", "exact_twelve_canonical_width_theme_cells"]],
  "SBK-03": [["story-slice", "shared_renderer_and_active_variation"], ["subscription-render-browser", "exact_twelve_canonical_width_theme_cells"]],
  "SCEN-01": [["scenario-domain", "deterministic_fact_source"], ["scenario-repo", "persisted_launch_and_team_facts"], ["heldout-cleanup", "heldout_identity_separation"]],
  "SCEN-02": [["scenario-domain", "canceling_boundary_exact_clock"], ["scenario-domain", "exact_minor_unit_money_precision"]],
  "SCEN-03": [["scenario-repo", "persisted_launch_and_team_facts"], ["scenario-repo", "replay_identity_conflict_refusal"], ["scenario-repo", "transaction_rollback"], ["scenario-repo", "concurrent_insert_serialization"]],
  "SCEN-04": [["heldout-cleanup", "exact_cleanup_authority"], ["heldout-cleanup", "cleanup_idempotency_absence_mismatch"], ["heldout-cleanup", "serialized_unrelated_child_concurrency"]],
  "LAB-01": [["phase252-lab-contract", "namespace_lock_one_owner"], ["phase252-lab-contract", "exact_process_identity_cleanup"], ["isolation-reset", "distinct_review_process_and_database"]],
  "LAB-02": [["production-packages", "fresh_production_compiles"], ["production-packages", "actual_unpacked_hex_archives"], ["production-boundary-controls", "development_positive_production_route_exclusion"]],
};

const TASK_EVIDENCE = {
  "252-08-01": [["phase252-ci-contract", "consumed_root_owner_map"], ["phase252-ci-contract", "workflow_admission"], ["phase252-ci-contract", "required_owner_invocation_mutations"]],
  "252-08-02": [["bundle", "all_required_commands_passed"]],
  "252-08-03": [["phase252-acceptance-contract", "missing_command_rejection"], ["phase252-acceptance-contract", "failed_command_rejection"], ["phase252-acceptance-contract", "stale_source_and_asset_rejection"], ["phase252-acceptance-contract", "pooled_cell_rejection"], ["phase252-acceptance-contract", "missing_predicate_rejection"], ["phase252-acceptance-contract", "unsafe_evidence_path_rejection"], ["phase252-acceptance-contract", "guide_contract_mutation_rejection"]],
};

const digest = (value) => crypto.createHash("sha256").update(value).digest("hex");
const write = (root, relative, content) => {
  const destination = path.join(root, relative);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, content);
  return destination;
};

function commandRefs(id) {
  const refs = ASSERTIONS[id] || [];
  return refs.map((ref) => `${id}#${ref}`);
}

function fixtureUiCoverage(rows) {
  const allCells = rows.filter((row) => row.case_kind === "canonical").map((row) => row.key);
  const partialCells = rows.filter((row) => row.case_kind === "canonical" && row.state === "incomplete_evidence").map((row) => row.key);
  const longCells = rows.filter((row) => row.case_kind === "canonical" && row.state === "active" && row.width === 320).map((row) => row.key);
  return Object.fromEntries(UI_IDS.map((id) => [id, {
    assertions: UI_ASSERTIONS[id],
    cells: id.endsWith("-partial") ? partialCells : id.endsWith("-long-text") ? longCells : allCells,
    controls: id.endsWith("-error") ? ["invalid_route", "missing_variation", "metadata_only", "authority_regression"] : [],
  }]));
}

function createFixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase252-acceptance-fixture-"));
  const phaseDir = path.join(root, ".planning", "milestones", "fixture-phases", PHASE_SLUG);
  fs.mkdirSync(phaseDir, { recursive: true });
  const planRequirements = `requirements: [${REQUIREMENTS.map((id) => `"${id}"`).join(", ")}]`;
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-08-PLAN.md`, `---\n${planRequirements}\n---\n<task><name>252-08-01: Prove required-owner admission</name></task><task><name>252-08-02: Run focused checks</name></task><task><name>252-08-03: Generate acceptance</name></task>\nEDGE-CIQ-01-unclassified remains explicitly unresolved.\n`);
  const edgePlans = {
    "252-01-PLAN.md": ["EDGE-SBK-03-unclassified"],
    "252-02-PLAN.md": ["EDGE-SCEN-01-unclassified", "EDGE-SCEN-02-boundary", "EDGE-SCEN-02-precision"],
    "252-03-PLAN.md": ["EDGE-LAB-01-concurrency"],
    "252-04-PLAN.md": ["EDGE-SCEN-03-idempotency", "EDGE-SCEN-03-concurrency", "EDGE-SCEN-04-idempotency", "EDGE-SCEN-04-concurrency"],
    "252-05-PLAN.md": ["EDGE-SBK-01-adjacency", "EDGE-SBK-01-empty", "EDGE-SBK-01-ordering", "EDGE-SBK-02-adjacency", "EDGE-SBK-02-empty", "EDGE-SBK-02-ordering"],
    "252-06-PLAN.md": [],
    "252-07-PLAN.md": ["EDGE-LAB-02-unclassified"],
  };
  for (let plan = 1; plan <= 7; plan += 1) {
    const name = `252-${String(plan).padStart(2, "0")}-PLAN.md`;
    const ids = edgePlans[name] || [];
    const truths = ids.map((id) => `    - "${id}: explicit fixture truth"`).join("\n");
    const prohibitions = plan === 1
      ? `\nprohibitions:\n  - statement: "The lab is not a production operations console or evidence of completed actions."\n    status: "unresolved"\n    reason: "flagged-unverified specless fallback; no wired-check descriptor"\n`
      : plan === 4
        ? `\nprohibitions:\n  - statement: "Held-out scenarios do not represent customer behavior or adopter usage."\n    status: "unresolved"\n    reason: "flagged-unverified specless fallback; no wired-check descriptor"\n`
        : "";
    const ui = plan === 6 ? `\nmust_haves:\n  truths:\n${UI_IDS.map((id) => `    - "${id}: explicit UI truth"`).join("\n")}\n` : "";
    write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/${name}`, `---\n${truths ? `must_haves:\n  truths:\n${truths}\n` : ""}${ui}${prohibitions}---\n`);
    write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-${String(plan).padStart(2, "0")}-SUMMARY.md`, `---\nstatus: complete\ncompleted: 2026-10-${String(20 + plan).padStart(2, "0")}\ncoverage:\n  - id: P${plan}\n    description: Previous phase plan evidence\n    verification:\n      - kind: integration\n        ref: "scripts/ci/verify_phase252_stories.mjs#previous-plan-${plan}"\n        status: pass\n    human_judgment: false\n---\n`);
  }
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-VALIDATION.md`, "17 surfaced = 13 classified explicit acceptance truths plus four unclassified unresolved flagged assumptions.\n");
  write(root, "guides/ui-story-lab.md", "The first bootstrap compiles and migrates an empty disposable database. Startup time should be recorded separately from warm browser renders. Budgets are provisional; Phase 254 owns frozen recurring selection and budgets.\n\nStatic rendering verifies story state. It does not prove mounted authorization, provider completion, dispatched action behavior, or persistence. Automated UAT requires fresh assertion evidence for the claim being made; a previous static render or a browser screenshot alone is not persisted/isolation evidence.\n\nThe final repository-root gate is:\n\n```sh\nnpm --prefix accrue_admin run phase252:check\n```\n\nThat command becomes available after plan 252-08 adds its runner and package script.\n");

  const assetCssPath = "accrue_admin/priv/static/storybook.css";
  const assetJsPath = "accrue_admin/priv/static/storybook.js";
  const fontSans = "accrue_admin/priv/static/fonts/geist-sans-vf.woff2";
  const fontMono = "accrue_admin/priv/static/fonts/geist-mono-vf.woff2";
  write(root, assetCssPath, "fixture css");
  write(root, assetJsPath, "fixture js");
  write(root, fontSans, "fixture sans");
  write(root, fontMono, "fixture mono");
  write(root, "accrue_admin/e2e/phase252-story-helpers.js", "fixture helper");
  write(root, "scripts/ci/verify_phase252_stories.mjs", "fixture owner source");
  write(root, "scripts/ci/generate_phase252_acceptance.mjs", "fixture acceptance source");
  write(root, "scripts/ci/generate_phase252_acceptance.test.mjs", "fixture acceptance tests");
  write(root, ".github/workflows/ci.yml", "fixture workflow");
  write(root, "dev_support/ui_scenarios/cadence_subscriptions.exs", "fixture scenario source");
  const manifest = {
    schema_version: 1,
    source_digests: { "dev_support/ui_scenarios/cadence_subscriptions.exs": digest("fixture scenario source") },
    entries: ["active", "scheduled_cancellation", "incomplete_evidence", "compat_one", "compat_two", "compat_three"].map((id) => ({
      key: `/components/subscription_detail||${id}`,
      url: `/dev/storybook/components/subscription_detail?variation_id=${id}`,
      route_variation_id: id,
      variation_id: id,
      scenario_id: id,
      input_source: "fixture facts",
      production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
      proof_lane: "static render",
    })),
  };
  const manifestPath = write(root, "storybook/phase252-manifest.json", JSON.stringify(manifest, null, 2) + "\n");
  const manifestBytes = fs.readFileSync(manifestPath);
  const manifestDigest = digest(manifestBytes);

  const rows = [];
  for (const state of ["active", "scheduled_cancellation", "incomplete_evidence"]) {
    for (const width of [320, 1280]) {
      for (const theme of ["light", "dark"]) {
        const key = `/components/subscription_detail||${state}::${width}::${theme}`;
        rows.push({
          key,
          test_id: `${state} | ${width}px | ${theme}`,
          variation_key: `/components/subscription_detail||${state}`,
          scenario_id: state,
          state,
          width,
          theme,
          case_kind: "canonical",
          url: `/billing/dev/storybook/components/subscription_detail?variation_id=${state}`,
          generated_url: `/dev/storybook/components/subscription_detail?variation_id=${state}`,
          source: "fixture facts",
          renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
          lane: "static render",
          route_variation_id: state,
          status: "passed",
          manifest_sha256: manifestDigest,
          viewport: { width },
          applied_theme: { dataTheme: theme },
          ui_predicate_ids: UI_IDS,
          actual_content: { text_sha256: digest(key), text_length: 100 },
          served_assets: { cssHref: "/dev/storybook/assets/storybook-css-fixture", jsHref: "/dev/storybook/assets/storybook-js-fixture" },
          fonts: { status: "loaded", sans: true, mono: true },
          asset_identity: { storybook_css_sha256: digest("fixture css"), storybook_js_sha256: digest("fixture js") },
          assertions: {
            direct_route: true, actual_content: true, identity: true, facts: true, actions: true, theme: true,
            served_assets: true, fonts_loaded: true, settled_content_visible: true, loading_artifacts_absent: true,
            document_and_required_content_geometry: true, keyboard_focus_visible: true, full_id_copy: true,
            optional_rows_and_action_groups_follow_inputs: true, unavailable_values_and_ordered_caveats: true,
            canonical_render_attribution: true, ordinary_content_complete: true, held_out_long_text_complete: true,
          },
        });
      }
    }
  }
  for (const id of ["compat_one", "compat_two", "compat_three"]) {
    rows.push({
      key: `/components/subscription_detail||${id}::compatibility::1280::light`,
      variation_key: `/components/subscription_detail||${id}`,
      scenario_id: id,
      state: id,
      width: 1280,
      theme: "light",
      case_kind: "compatibility",
      url: `/billing/dev/storybook/components/subscription_detail?variation_id=${id}`,
      generated_url: `/dev/storybook/components/subscription_detail?variation_id=${id}`,
      source: "fixture facts",
      renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_area/1",
      lane: "static render",
      route_variation_id: id,
      status: "passed",
      manifest_sha256: manifestDigest,
      viewport: { width: 1280 },
      applied_theme: { dataTheme: "light" },
      ui_predicate_ids: UI_IDS,
      actual_content: { text_sha256: digest(id), text_length: 100 },
      served_assets: { cssHref: "/dev/storybook/assets/storybook-css-fixture", jsHref: "/dev/storybook/assets/storybook-js-fixture" },
      fonts: { status: "loaded", sans: true, mono: true },
      asset_identity: { storybook_css_sha256: digest("fixture css"), storybook_js_sha256: digest("fixture js") },
      assertions: { direct_route: true, actual_content: true, served_assets: true, fonts_loaded: true },
    });
  }
  const renderResults = {
    schema_version: 1,
    run_id: "25208-1793072424185-64706-61aa2ca2b88c",
    manifest_sha256: manifestDigest,
    human_judgment: false,
    cases: rows,
    negative_controls: {
      baseline_accepted: true,
      invalid_route: { rejected: true },
      missing_variation: { rejected: true },
      metadata_only: { rejected: true },
    },
    ui_predicate_coverage: fixtureUiCoverage(rows),
  };
  const renderPath = write(root, "accrue_admin/tmp/phase252/render-results-fixture.json", JSON.stringify(renderResults, null, 2) + "\n");
  const sourcePaths = [
    "storybook/phase252-manifest.json", "dev_support/ui_scenarios/cadence_subscriptions.exs",
    assetCssPath, assetJsPath, fontSans, fontMono, "accrue_admin/e2e/phase252-story-helpers.js",
    "scripts/ci/verify_phase252_stories.mjs",
    "scripts/ci/generate_phase252_acceptance.mjs",
    "scripts/ci/generate_phase252_acceptance.test.mjs",
    "guides/ui-story-lab.md",
    ".github/workflows/ci.yml",
  ].sort();
  const sourceDigests = Object.fromEntries(sourcePaths.map((relative) => [relative, digest(fs.readFileSync(path.join(root, relative)))]));
  const fingerprint = digest(JSON.stringify(sourceDigests));
  const commandRecords = REQUIRED_COMMAND_IDS.map((id, index) => {
    const stdout = `output ${id}\n`;
    const stderr = "";
    const outPath = `accrue_admin/tmp/phase252/ci-results/fixture/logs/${id}.stdout.log`;
    const errPath = `accrue_admin/tmp/phase252/ci-results/fixture/logs/${id}.stderr.log`;
    write(root, outPath, stdout);
    write(root, errPath, stderr);
    const started = Date.parse("2026-10-27T00:00:00.000Z") + (index * 10);
    return {
      id,
      command: ["node", "fixture"],
      cwd: ".",
      lane: "read-only",
      warmth: "warm",
      partition: null,
      sources: [],
      assertion_refs: ASSERTIONS[id] || [],
      started_at: new Date(started).toISOString(),
      completed_at: new Date(started + 5).toISOString(),
      duration_ms: 5,
      exitCode: 0,
      signal: null,
      stdout_path: outPath,
      stdout_sha256: digest(stdout),
      stderr_path: errPath,
      stderr_sha256: digest(stderr),
      error: null,
    };
  });
  const resultsPath = write(root, "accrue_admin/tmp/phase252/ci-results/fixture/results.json", "{}");
  const resultBundle = {
    schema_version: 1,
    plan: "252-08",
    run_id: "25208-1793072424185-64706-61aa2ca2b88c",
    status: "passed",
    human_judgment: false,
    source_revision: "0".repeat(40),
    source_fingerprint: fingerprint,
    source_digests: sourceDigests,
    manifest_path: "storybook/phase252-manifest.json",
    manifest_sha256: manifestDigest,
    requirements: REQUIREMENTS,
    browser_result_path: path.relative(root, renderPath).split(path.sep).join("/"),
    browser_results_sha256: digest(fs.readFileSync(renderPath)),
    results_path: path.relative(root, resultsPath).split(path.sep).join("/"),
    historical_render_result_preserved: "digest-pinned",
    commands: commandRecords,
    costs: { cold_build: { duration_ms: 5 }, cold_database_startup: { duration_ms: 5 }, warm_database_lane: { duration_ms: 5 }, production_build: { duration_ms: 5 }, browser_lane: { duration_ms: 5 } },
    run_started_at: "2026-10-27T00:00:00.000Z",
    run_completed_at: "2026-10-27T00:00:00.185Z",
  };
  fs.writeFileSync(resultsPath, JSON.stringify(resultBundle, null, 2) + "\n");

  const refs = [
    `${resultBundle.results_path}#bundle:all_required_commands_passed`,
    ...commandRecords.flatMap((row) => row.assertion_refs.map((id) => `${resultBundle.results_path}#commands:${row.id}:${id}`)),
    `${resultBundle.results_path}#commands:subscription-render-browser:twenty_ui_predicates`,
    ...UI_IDS.map((id) => `${resultBundle.browser_result_path}#ui:${id}`),
  ];
  const summaryCoverage = [...REQUIREMENTS, ...TASK_IDS, ...EDGE_IDS, ...UI_IDS].map((id) => `  - id: ${id}\n    description: "Fixture evidence for ${id}"\n    verification:\n      - kind: integration\n        ref: "${refs[0]}"\n        status: pass\n${refs.slice(1).map((ref) => `      - kind: integration\n        ref: "${ref}"\n        status: pass\n`).join("")}    human_judgment: false`).join("\n");
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-08-SUMMARY.md`, `---\nstatus: complete\ncompleted: 2026-10-27\nhuman_judgment: false\ncoverage:\n${summaryCoverage}\n---\n`);

  return { root, phaseDir, resultsPath, manifestDigest, rows };
}

test("fresh actual runner, manifest and browser evidence produce complete coverage", () => {
  const fixture = createFixture();
  try {
    const evidence = validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath });
    assert.equal(evidence.status, "passed");
    assert.deepEqual(evidence.requirements, REQUIREMENTS);
    assert.deepEqual(evidence.tasks, TASK_IDS);
    assert.deepEqual(evidence.classified_edges, EDGE_IDS);
    assert.deepEqual(evidence.ui_predicates, UI_IDS);
    assert.deepEqual(evidence.unresolved_assumptions.map((item) => item.id), UNCLASSIFIED);
    assert.equal(evidence.unresolved_prohibitions.length, 2);
    assert.equal(evidence.human_judgment, false);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("missing and failed commands cannot become passing UAT evidence", () => {
  for (const mutate of [
    (bundle) => { bundle.commands = bundle.commands.filter((row) => row.id !== "scenario-domain"); },
    (bundle) => { bundle.commands.find((row) => row.id === "scenario-domain").exitCode = 1; },
  ]) {
    const fixture = createFixture();
    try {
      const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
      mutate(bundle);
      fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
      assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /required command IDs mismatch|failed command/);
    } finally {
      fs.rmSync(fixture.root, { recursive: true, force: true });
    }
  }
});

test("changed source and stale served asset bytes reject the bundle", () => {
  const fixture = createFixture();
  try {
    fs.appendFileSync(path.join(fixture.root, "accrue_admin/priv/static/storybook.css"), "changed");
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /stale source|source digest/i);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }

  const assetFixture = createFixture();
  try {
    const renderPath = path.join(assetFixture.root, "accrue_admin/tmp/phase252/render-results-fixture.json");
    const render = JSON.parse(fs.readFileSync(renderPath, "utf8"));
    render.cases[0].asset_identity.storybook_css_sha256 = "0".repeat(64);
    fs.writeFileSync(renderPath, JSON.stringify(render, null, 2) + "\n");
    const bundle = JSON.parse(fs.readFileSync(assetFixture.resultsPath, "utf8"));
    bundle.browser_results_sha256 = digest(fs.readFileSync(renderPath));
    fs.writeFileSync(assetFixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    assert.throws(() => validatePhase252Evidence({ root: assetFixture.root, resultsPath: assetFixture.resultsPath }), /served asset|asset.*digest/i);
  } finally {
    fs.rmSync(assetFixture.root, { recursive: true, force: true });
  }
});

test("pooled cells and incomplete UI or edge predicates are rejected", () => {
  const fixture = createFixture();
  try {
    const renderPath = path.join(fixture.root, "accrue_admin/tmp/phase252/render-results-fixture.json");
    const render = JSON.parse(fs.readFileSync(renderPath, "utf8"));
    render.cases = render.cases.filter((row) => row.key !== "/components/subscription_detail||active::320::light");
    fs.writeFileSync(renderPath, JSON.stringify(render, null, 2) + "\n");
    const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
    bundle.browser_results_sha256 = digest(fs.readFileSync(renderPath));
    fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /exactly 15|omitted canonical cell/i);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }

  for (const mutate of [
    (render) => { delete render.ui_predicate_coverage["UI-E1-error"]; },
    (_render, bundle) => { bundle.commands.find((row) => row.id === "manifest-contract").assertion_refs = []; },
  ]) {
    const missing = createFixture();
    try {
      const renderPath = path.join(missing.root, "accrue_admin/tmp/phase252/render-results-fixture.json");
      const render = JSON.parse(fs.readFileSync(renderPath, "utf8"));
      const bundle = JSON.parse(fs.readFileSync(missing.resultsPath, "utf8"));
      mutate(render, bundle);
      fs.writeFileSync(renderPath, JSON.stringify(render, null, 2) + "\n");
      bundle.browser_results_sha256 = digest(fs.readFileSync(renderPath));
      fs.writeFileSync(missing.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
      assert.throws(() => validatePhase252Evidence({ root: missing.root, resultsPath: missing.resultsPath }), /UI predicate|missing assertion evidence|EDGE-SBK-01|no assertion references/);
    } finally {
      fs.rmSync(missing.root, { recursive: true, force: true });
    }
  }
});

test("unsafe result and log paths fail closed", () => {
  const fixture = createFixture();
  try {
    const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
    bundle.commands[0].stdout_path = "../../outside.log";
    fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /evidence path|repository-relative/i);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("guide contract pins the actual owner command, evidence limits, and provisional budgets", () => {
  const guide = fs.readFileSync(new URL("../../guides/ui-story-lab.md", import.meta.url), "utf8");
  const fixture = createFixture();
  try {
    const evidence = validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath });
    assert.equal(evidence.guide_contract, "passed");
    const badCommand = guide.replace("npm --prefix accrue_admin run phase252:check", "npm --prefix accrue_admin run other");
    const badBudget = guide.replace("Phase 254 owns frozen recurring selection and budgets", "budget is final now");
    assert.throws(() => validateGuideContract(badCommand), /phase252:check/i);
    assert.throws(() => validateGuideContract(badBudget), /Phase 254|provisional/i);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("acceptance UAT is archive-aware and follows the project automated UAT shape", () => {
  const fixture = createFixture();
  try {
    const result = generatePhase252Acceptance({ root: fixture.root, resultsPath: fixture.resultsPath, writeUat: true });
    assert.equal(result.uat_written, true);
    const uatPath = path.join(fixture.phaseDir, "252-UAT.md");
    const generated = fs.readFileSync(uatPath, "utf8");
    assert.match(generated, /# Phase 252 Automated UAT/);
    assert.match(generated, /## Tests/);
    assert.match(generated, /## Summary/);
    assert.match(generated, /source: automated/);
    assert.doesNotMatch(generated, /\[(pending|issue|blocked|skipped)\]/i);
    assert.equal(result.evidence.unresolved_assumptions.length, 4);
    assert.equal(result.evidence.unresolved_prohibitions.length, 2);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});
