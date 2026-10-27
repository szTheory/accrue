#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import { deriveExecutionEvidence, PHASE252_REPORTER_SPECS, requiredAssertionIds } from "./phase252_reporters.mjs";
import { REQUIRED_COMMAND_IDS } from "./verify_phase252_stories.mjs";

export const PHASE_SLUG = "252-production-backed-subscription-stories";
export const REQUIREMENT_IDS = Object.freeze(["CIQ-01", "SBK-01", "SBK-02", "SBK-03", "SCEN-01", "SCEN-02", "SCEN-03", "SCEN-04", "LAB-01", "LAB-02"]);
export const TASK_IDS = Object.freeze(["252-08-01", "252-08-02", "252-08-03", "252-09-01", "252-09-02", "252-10-01", "252-10-02", "252-10-03"]);
export const PROHIBITION_IDS = Object.freeze(["PROH-LAB-PRESENTATION", "PROH-HELDOUT-ATTRIBUTION"]);
const ORIGINAL_PROHIBITION_DESCRIPTORS = Object.freeze([
  {
    id: "PROH-LAB-PRESENTATION",
    plan: "252-01-PLAN.md",
    statement: "The review lab must not be presented as a production operations console or evidence of completed billing actions.",
    target: "scripts/ci/verify_phase252_lab_presentation.test.mjs",
    violationFixture: "scripts/ci/fixtures/phase252-transparency/lab-violation.json",
    cleanFixture: "scripts/ci/fixtures/phase252-transparency/lab-clean.json",
    targetCommand: "lab-presentation",
    targetAssertions: ["lab_static_limits", "lab_contradiction_controls"],
    controlAssertions: ["lab_static_current_green", "lab_static_clean_green", "lab_static_violation_red"],
  },
  {
    id: "PROH-HELDOUT-ATTRIBUTION",
    plan: "252-04-PLAN.md",
    statement: "Held-out adversarial scenarios must not be presented as representative customer behavior or evidence of real adopter usage.",
    target: "scripts/ci/verify_phase252_heldout_attribution.test.mjs",
    violationFixture: "scripts/ci/fixtures/phase252-transparency/heldout-violation.json",
    cleanFixture: "scripts/ci/fixtures/phase252-transparency/heldout-clean.json",
    targetCommand: "heldout-attribution",
    targetAssertions: ["heldout_synthetic_attribution", "heldout_contradiction_controls"],
    controlAssertions: ["heldout_synthetic_current_green", "heldout_synthetic_clean_green", "heldout_synthetic_violation_red"],
  },
]);
export const EDGE_IDS = Object.freeze([
  "EDGE-LAB-01-concurrency",
  "EDGE-SBK-01-adjacency", "EDGE-SBK-01-empty", "EDGE-SBK-01-ordering",
  "EDGE-SBK-02-adjacency", "EDGE-SBK-02-empty", "EDGE-SBK-02-ordering",
  "EDGE-SCEN-02-boundary", "EDGE-SCEN-02-precision",
  "EDGE-SCEN-03-concurrency", "EDGE-SCEN-03-idempotency",
  "EDGE-SCEN-04-concurrency", "EDGE-SCEN-04-idempotency",
]);
export const UNCLASSIFIED_EDGE_IDS = Object.freeze([
  "EDGE-CIQ-01-unclassified", "EDGE-LAB-02-unclassified",
  "EDGE-SBK-03-unclassified", "EDGE-SCEN-01-unclassified",
]);
export const UI_IDS = Object.freeze([
  "UI-E1-loading", "UI-E1-error", "UI-E1-overflow", "UI-E1-long-text",
  "UI-E2-empty", "UI-E2-loading", "UI-E2-error", "UI-E2-populated", "UI-E2-partial", "UI-E2-overflow", "UI-E2-zero-one-many", "UI-E2-long-text",
  "UI-E3-empty", "UI-E3-loading", "UI-E3-error", "UI-E3-populated", "UI-E3-partial", "UI-E3-overflow", "UI-E3-zero-one-many", "UI-E3-long-text",
]);

export const UI_ASSERTIONS = Object.freeze({
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
});

const EDGE_EVIDENCE = Object.freeze({
  "EDGE-LAB-01-concurrency": [["phase252-lab-contract", "namespace_lock_one_owner"], ["phase252-lab-contract", "stale_lock_owner_refusal"], ["phase252-lab-contract", "exact_process_identity_cleanup"], ["phase252-lab-contract", "owned_process_group_identity"], ["isolation-reset", "interrupted_descendant_cleanup_before_database_drop"], ["isolation-reset", "owned_descendants_cleanup_after_leader_exit"], ["isolation-reset", "unrelated_process_survives_group_cleanup"]],
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
});

const REQUIREMENT_EVIDENCE = Object.freeze({
  "CIQ-01": [["phase252-ci-contract", "consumed_root_owner_map"], ["phase252-ci-contract", "workflow_admission"], ["phase252-ci-contract", "named_required_owner_execution"]],
  "SBK-01": [["manifest-contract", "current_caller_map"], ["manifest-contract", "caller_identity_adjacency"], ["manifest-contract", "empty_caller_source_refusal"], ["manifest-contract", "stable_caller_ordering"]],
  "SBK-02": [["manifest-contract", "compiled_variation_routes"], ["manifest-contract", "story_variation_identity_adjacency"], ["manifest-contract", "zero_variation_and_missing_attribution_refusal"], ["manifest-contract", "deterministic_manifest_ordering"], ["subscription-render-browser", "exact_twelve_canonical_width_theme_cells"]],
  "SBK-03": [["story-slice", "shared_renderer_and_active_variation"], ["subscription-render-browser", "exact_twelve_canonical_width_theme_cells"]],
  "SCEN-01": [["scenario-domain", "deterministic_fact_source"], ["scenario-repo", "persisted_launch_and_team_facts"], ["heldout-cleanup", "heldout_identity_separation"]],
  "SCEN-02": [["scenario-domain", "canceling_boundary_exact_clock"], ["scenario-domain", "exact_minor_unit_money_precision"]],
  "SCEN-03": [["scenario-repo", "persisted_launch_and_team_facts"], ["scenario-repo", "replay_identity_conflict_refusal"], ["scenario-repo", "transaction_rollback"], ["scenario-repo", "concurrent_insert_serialization"]],
  "SCEN-04": [["heldout-cleanup", "exact_cleanup_authority"], ["heldout-cleanup", "cleanup_idempotency_absence_mismatch"], ["heldout-cleanup", "serialized_unrelated_child_concurrency"]],
  "LAB-01": [["phase252-lab-contract", "namespace_lock_one_owner"], ["phase252-lab-contract", "exact_process_identity_cleanup"], ["phase252-lab-contract", "owned_process_group_identity"], ["isolation-reset", "distinct_review_process_and_database"], ["isolation-reset", "interrupted_descendant_cleanup_before_database_drop"], ["isolation-reset", "owned_descendants_cleanup_after_leader_exit"], ["isolation-reset", "unrelated_process_survives_group_cleanup"]],
  "LAB-02": [["production-packages", "fresh_production_compiles"], ["production-packages", "actual_unpacked_hex_archives"], ["production-boundary-controls", "development_positive_production_route_exclusion"]],
});

const TASK_EVIDENCE = Object.freeze({
  "252-08-01": [["phase252-ci-contract", "consumed_root_owner_map"], ["phase252-ci-contract", "workflow_admission"], ["phase252-ci-contract", "required_owner_invocation_mutations"]],
  "252-08-02": [["bundle", "all_required_commands_passed"]],
  "252-08-03": [["phase252-acceptance-contract", "missing_command_rejection"], ["phase252-acceptance-contract", "failed_command_rejection"], ["phase252-acceptance-contract", "stale_source_and_asset_rejection"], ["phase252-acceptance-contract", "pooled_cell_rejection"], ["phase252-acceptance-contract", "missing_predicate_rejection"], ["phase252-acceptance-contract", "unsafe_evidence_path_rejection"], ["phase252-acceptance-contract", "guide_contract_mutation_rejection"]],
  "252-09-01": [["lab-presentation", "lab_static_limits"], ["lab-presentation", "lab_contradiction_controls"], ["transparency-controls", "lab_static_current_green"], ["transparency-controls", "lab_static_clean_green"], ["transparency-controls", "lab_static_violation_red"]],
  "252-09-02": [["heldout-attribution", "heldout_synthetic_attribution"], ["heldout-attribution", "heldout_contradiction_controls"], ["transparency-controls", "heldout_synthetic_current_green"], ["transparency-controls", "heldout_synthetic_clean_green"], ["transparency-controls", "heldout_synthetic_violation_red"]],
  "252-10-01": [["phase252-ci-contract", "required_transparency_lane_inventory"], ["phase252-ci-contract", "transparency_reporter_bindings"], ["phase252-ci-contract", "transparency_source_freshness"], ["phase252-ci-contract", "transparency_consumed_root_admission"], ["phase252-ci-contract", "transparency_non_vacuity"]],
  "252-10-02": [["phase252-acceptance-contract", "missing_command_rejection"], ["phase252-acceptance-contract", "stale_source_and_asset_rejection"], ["phase252-acceptance-contract", "guide_contract_mutation_rejection"]],
  "252-10-03": [["bundle", "all_required_commands_passed"], ["transparency-controls", "lab_static_violation_red"], ["transparency-controls", "heldout_synthetic_violation_red"]],
});

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const MANIFEST_PATH = "storybook/phase252-manifest.json";
const TRANSPARENCY_SOURCE_PATHS = Object.freeze([
  "scripts/ci/phase_evidence_path.mjs",
  "scripts/ci/verify_phase252_transparency.mjs",
  "scripts/ci/verify_phase252_lab_presentation.test.mjs",
  "scripts/ci/verify_phase252_heldout_attribution.test.mjs",
  "scripts/ci/fixtures/phase252-transparency/lab-clean.json",
  "scripts/ci/fixtures/phase252-transparency/lab-violation.json",
  "scripts/ci/fixtures/phase252-transparency/heldout-clean.json",
  "scripts/ci/fixtures/phase252-transparency/heldout-violation.json",
  "guides/ui-story-lab.md",
  "storybook/components/subscription_detail.story.exs",
  MANIFEST_PATH,
  "dev_support/ui_scenarios/cadence_subscriptions.exs",
  "accrue_admin/storybook/_support/subscription_scenarios.ex",
  "accrue_admin/e2e/phase252-story-helpers.js",
  ".planning/phases/252-production-backed-subscription-stories/252-01-PLAN.md",
  ".planning/phases/252-production-backed-subscription-stories/252-04-PLAN.md",
]);
const STATES = ["active", "scheduled_cancellation", "incomplete_evidence"];
const WIDTHS = [320, 1280];
const THEMES = ["light", "dark"];
const REQUIRED_RENDER_ASSERTIONS = [
  "direct_route", "actual_content", "identity", "facts", "actions", "theme", "served_assets", "fonts_loaded",
  "settled_content_visible", "loading_artifacts_absent", "document_and_required_content_geometry", "keyboard_focus_visible",
  "full_id_copy", "optional_rows_and_action_groups_follow_inputs", "unavailable_values_and_ordered_caveats",
  "canonical_render_attribution", "ordinary_content_complete",
];

function fail(message) {
  throw new Error(`Phase 252 acceptance: ${message}`);
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function exactSet(actual, expected, label) {
  const left = [...actual].sort();
  const right = [...expected].sort();
  if (JSON.stringify(left) !== JSON.stringify(right)) fail(`${label} mismatch (expected ${right.join(", ")}; found ${left.join(", ")})`);
}

function realRoot(root) {
  try { return fs.realpathSync(root); } catch { fail(`repository root is missing: ${root}`); }
}

function resolveRelative(root, relative) {
  if (typeof relative !== "string" || !relative || path.isAbsolute(relative)) fail(`evidence path must be repository-relative: ${String(relative)}`);
  if (relative.split(/[\\/]/).some((part) => ["", ".", ".."].includes(part))) fail(`evidence path has an unsafe segment: ${relative}`);
  const rootPath = realRoot(root);
  const joined = path.resolve(rootPath, relative);
  if (!joined.startsWith(rootPath + path.sep)) fail(`evidence path escapes repository root: ${relative}`);
  let resolved;
  try { resolved = fs.realpathSync(joined); } catch { fail(`evidence path does not exist: ${relative}`); }
  if (!resolved.startsWith(rootPath + path.sep) || !fs.statSync(resolved).isFile()) fail(`evidence path does not resolve to a repository file: ${relative}`);
  return resolved;
}

function resolveResultsPath(root, supplied) {
  if (typeof supplied !== "string" || !supplied) fail("runner result path is required");
  if (!path.isAbsolute(supplied)) return resolveRelative(root, supplied);
  const rootPath = realRoot(root);
  let absolute;
  try { absolute = fs.realpathSync(path.resolve(supplied)); } catch { fail("runner result path does not exist"); }
  if (!absolute.startsWith(rootPath + path.sep)) fail("runner result path must stay inside the repository");
  return resolveRelative(root, path.relative(rootPath, absolute));
}

function readJson(file, label) {
  try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch (error) { fail(`${label} is not valid JSON (${error.message})`); }
}

function resolveSnapshotPath(root, relative) {
  const prefix = `.planning/phases/${PHASE_SLUG}/`;
  if (!relative.startsWith(prefix)) return resolveRelative(root, relative);
  let absolute;
  try { absolute = fs.realpathSync(resolvePhaseEvidencePath(PHASE_SLUG, relative.slice(prefix.length), { root })); } catch { fail(`phase source does not exist in active or archived evidence: ${relative}`); }
  const rootPath = realRoot(root);
  if (!absolute.startsWith(rootPath + path.sep) || !fs.statSync(absolute).isFile()) fail(`phase source does not resolve to a repository file: ${relative}`);
  return absolute;
}

function verifyDigest(root, relative, expected, label) {
  const actual = sha256(fs.readFileSync(resolveSnapshotPath(root, relative)));
  if (!/^[0-9a-f]{64}$/.test(expected || "") || actual !== expected) fail(`${label} digest is stale or invalid: ${relative}`);
  return actual;
}

function validateCommands(root, bundle, bundlePath) {
  if (bundle.status !== "passed") fail(`runner status is ${String(bundle.status)}, expected passed`);
  if (bundle.plan !== "252-08" || bundle.human_judgment !== false) fail("runner plan identity or human_judgment is invalid");
  if (typeof bundle.run_id !== "string" || !/^25208-\d{13}-\d+-[0-9a-f]{12}$/.test(bundle.run_id)) fail("runner has no current run identity");
  if (!/^[0-9a-f]{40}$/.test(bundle.source_revision || "")) fail("runner source revision is missing or invalid");
  if (bundle.results_path && resolveResultsPath(root, bundle.results_path) !== bundlePath) fail("runner results_path does not identify the supplied bundle");
  if (!bundle.results_path || !bundle.results_path.startsWith("accrue_admin/tmp/phase252/ci-results/")) fail("runner result bundle is outside the Phase 252 result namespace");
  if (!bundle.browser_result_path?.startsWith("accrue_admin/tmp/phase252/render-results-")) fail("browser result is outside the Phase 252 result namespace");
  if (!Number.isFinite(Date.parse(bundle.run_started_at)) || !Number.isFinite(Date.parse(bundle.run_completed_at))) fail("runner has invalid run timestamps");
  if (Date.parse(bundle.run_completed_at) < Date.parse(bundle.run_started_at)) fail("runner completed before its start timestamp");
  if (!Array.isArray(bundle.commands)) fail("runner bundle has no command results");
  const ids = bundle.commands.map((row) => row?.id);
  exactSet(ids, REQUIRED_COMMAND_IDS, "required command IDs");
  if (ids.length !== REQUIRED_COMMAND_IDS.length || ids.some((id, index) => id !== REQUIRED_COMMAND_IDS[index])) fail("commands are duplicated or out of required serial order");

  const commands = new Map();
  let previousCompletion = Date.parse(bundle.run_started_at);
  for (const row of bundle.commands) {
    commands.set(row.id, row);
    if (row.exitCode !== 0 || row.signal || row.error || row.validation_error) fail(`failed command ${row.id} cannot produce passing evidence`);
    if (!Number.isInteger(row.duration_ms) || row.duration_ms < 0) fail(`command ${row.id} has no measured duration`);
    const started = Date.parse(row.started_at);
    const completed = Date.parse(row.completed_at);
    if (!Number.isFinite(started) || !Number.isFinite(completed) || completed < started) fail(`command ${row.id} has invalid start/end timestamps`);
    if (started < previousCompletion || completed > Date.parse(bundle.run_completed_at)) fail(`command ${row.id} is not part of a fresh serial owner run`);
    previousCompletion = completed;
    if (!Array.isArray(row.assertion_refs) || row.assertion_refs.length === 0) fail(`command ${row.id} has no executed assertion references`);
    if (new Set(row.assertion_refs).size !== row.assertion_refs.length) fail(`command ${row.id} repeats executed assertion references`);
    if (!Array.isArray(row.sources) || row.sources.some((source) => !bundle.source_digests?.[source])) fail(`command ${row.id} source is outside the fresh digest snapshot`);
    if (["lab-presentation", "heldout-attribution", "transparency-controls"].includes(row.id)) {
      exactSet(row.sources, TRANSPARENCY_SOURCE_PATHS, `${row.id} transparency source set`);
    }
    for (const kind of ["stdout", "stderr"]) verifyDigest(root, row[`${kind}_path`], row[`${kind}_sha256`], `${row.id} ${kind}`);
    const reporter = PHASE252_REPORTER_SPECS[row.id];
    if (!reporter || row.execution_evidence?.kind !== reporter.kind) fail(`command ${row.id} has no matching executed reporter evidence`);
    const stdout = fs.readFileSync(resolveRelative(root, row.stdout_path), "utf8");
    if (row.execution_evidence.stdout_sha256 !== row.stdout_sha256) fail(`command ${row.id} reporter digest is not bound to its stdout log`);
    const browserResult = row.id === "subscription-render-browser"
      ? readJson(resolveRelative(root, bundle.browser_result_path), "browser result for reporter binding")
      : null;
    let recomputed;
    try {
      recomputed = deriveExecutionEvidence({ root, commandId: row.id, stdout, expectedAssertions: requiredAssertionIds(row.id), browserResult });
    } catch (error) {
      fail(`command ${row.id} reporter evidence is invalid: ${error.message}`);
    }
    if (JSON.stringify(row.assertion_refs) !== JSON.stringify(recomputed.assertion_refs) ||
        JSON.stringify(row.execution_evidence) !== JSON.stringify(recomputed.execution_evidence)) {
      fail(`command ${row.id} assertion references or reporter records differ from its executed stdout`);
    }
    for (const testFile of reporter.testFiles || []) {
      if (!bundle.source_digests?.[testFile]) fail(`command ${row.id} reporter test source is outside the fresh digest snapshot: ${testFile}`);
    }
    if (["admin-test", "host-heldout", "admin-review-browser"].includes(row.lane) && !/^\d{8,16}$/.test(String(row.partition || ""))) {
      fail(`mutable command ${row.id} lacks a disposable numeric partition`);
    }
  }
  const partitions = bundle.commands.filter((row) => ["admin-test", "host-heldout", "admin-review-browser"].includes(row.lane)).map((row) => row.partition);
  if (new Set(partitions).size !== partitions.length) fail("mutable lanes reuse a disposable partition");
  return commands;
}

function validateSourceSnapshot(root, bundle) {
  if (!bundle.source_digests || typeof bundle.source_digests !== "object" || Array.isArray(bundle.source_digests)) fail("runner has no source digest snapshot");
  const sorted = Object.entries(bundle.source_digests).sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0);
  if (sorted.length === 0) fail("runner source digest snapshot is empty");
  for (const [relative, expected] of sorted) verifyDigest(root, relative, expected, "source");
  for (const required of ["scripts/ci/verify_phase252_stories.mjs", "scripts/ci/generate_phase252_acceptance.mjs", "scripts/ci/generate_phase252_acceptance.test.mjs", "scripts/ci/phase252_reporters.mjs", "dev_support/phase252_tap_formatter.ex", "accrue_admin/test/test_helper.exs", "examples/accrue_host/test/test_helper.exs", ".github/workflows/ci.yml", ...TRANSPARENCY_SOURCE_PATHS]) {
    if (!bundle.source_digests[required]) fail(`source snapshot does not pin required acceptance source: ${required}`);
  }
  const digestMap = Object.fromEntries(sorted);
  if (sha256(JSON.stringify(digestMap)) !== bundle.source_fingerprint) fail("runner source fingerprint does not match its digest list");
  return digestMap;
}

function validateManifest(root, bundle, sourceDigests) {
  if (bundle.manifest_path !== MANIFEST_PATH) fail("runner does not use the tracked Phase 252 manifest");
  const bytes = fs.readFileSync(resolveRelative(root, MANIFEST_PATH));
  const actualDigest = sha256(bytes);
  if (actualDigest !== bundle.manifest_sha256 || sourceDigests[MANIFEST_PATH] !== actualDigest) fail("tracked manifest digest is stale");
  const manifest = readJson(resolveRelative(root, MANIFEST_PATH), "tracked manifest");
  if (manifest.schema_version !== 1 || !Array.isArray(manifest.entries) || manifest.entries.length === 0 || !manifest.source_digests) fail("tracked manifest is incomplete");
  for (const [relative, expected] of Object.entries(manifest.source_digests)) {
    if (!sourceDigests[relative] || sourceDigests[relative] !== expected) fail(`manifest source digest is missing or stale: ${relative}`);
  }
  return { manifest, manifestDigest: actualDigest };
}

function expectedCells(id, canonicalRows) {
  if (id.endsWith("-partial")) return canonicalRows.filter((row) => row.state === "incomplete_evidence").map((row) => row.key).sort();
  if (id.endsWith("-long-text")) return canonicalRows.filter((row) => row.state === "active" && row.width === 320).map((row) => row.key).sort();
  return canonicalRows.map((row) => row.key).sort();
}

function validateUiAssertion(assertion, cells, rowsByKey, browser, commands) {
  if (assertion.startsWith("negative_controls.")) {
    const control = assertion.slice("negative_controls.".length);
    if (browser.negative_controls?.[control]?.rejected !== true) fail(`UI assertion ${assertion} is missing its negative control`);
    return;
  }
  if (["authority_regression", "scoped_not_found_regression"].includes(assertion)) {
    if (!commands.get("mounted-subscription-regressions")?.assertion_refs.includes(assertion)) fail(`UI assertion ${assertion} lacks mounted regression evidence`);
    return;
  }
  for (const key of cells) {
    const row = rowsByKey.get(key);
    if (!row) fail(`UI predicate points to a missing render cell: ${key}`);
    const required = assertion === "required_facts_present" ? ["facts", "__actual_content"]
      : assertion === "actual_facts_and_actions" ? ["facts", "actions", "__actual_content"]
        : assertion === "optional_rows_omitted" ? ["optional_rows_and_action_groups_follow_inputs"]
          : [assertion];
    if (required.some((name) => name === "__actual_content" ? !row.actual_content?.text_sha256 : row.assertions?.[name] !== true)) {
      fail(`UI assertion ${assertion} lacks case evidence at ${key}`);
    }
  }
}

function mountedStoryPath(entry) {
  const generated = new URL(entry.url, "http://phase252.local");
  const pathname = generated.pathname.startsWith("/dev/storybook/") ? `/billing${generated.pathname}` : generated.pathname;
  return `${pathname}${generated.search}`;
}

function validateBrowser(root, bundle, sourceDigests, manifest, manifestDigest, commands) {
  const browserPath = resolveRelative(root, bundle.browser_result_path);
  verifyDigest(root, bundle.browser_result_path, bundle.browser_results_sha256, "browser result");
  const browser = readJson(browserPath, "browser result");
  if (browser.run_id !== bundle.run_id) fail("browser result run ID does not match its required owner run");
  if (browser.human_judgment !== false || browser.manifest_sha256 !== manifestDigest) fail("browser result has unverified or stale manifest evidence");
  if (!Array.isArray(browser.cases) || browser.cases.length !== 15) fail("browser evidence must contain exactly 15 rows: 12 canonical and 3 compatibility cases");
  const canonical = browser.cases.filter((row) => row.case_kind === "canonical");
  const compatibility = browser.cases.filter((row) => row.case_kind === "compatibility");
  if (canonical.length !== 12 || compatibility.length !== 3) fail("browser evidence is pooled or omits canonical/compatibility rows");
  const expectedCanonical = STATES.flatMap((state) => WIDTHS.flatMap((width) => THEMES.map((theme) => `${state}::${width}::${theme}`)));
  exactSet(new Set(canonical.map((row) => `${row.state}::${row.width}::${row.theme}`)), expectedCanonical, "canonical state/width/theme cells");
  if (new Set(canonical.map((row) => row.key)).size !== 12 || new Set(compatibility.map((row) => row.key)).size !== 3) fail("browser row identity is duplicated");
  if (browser.cases.some((row) => row.status !== "passed" || row.manifest_sha256 !== manifestDigest || !/^[0-9a-f]{64}$/.test(row.actual_content?.text_sha256 || ""))) fail("browser row failed, is stale, or lacks actual DOM content evidence");
  const rowsByKey = new Map(browser.cases.map((row) => [row.key, row]));
  if (rowsByKey.size !== 15) fail("browser result contains duplicate case keys");
  const screenshotDirectory = `${path.posix.dirname(bundle.results_path)}/screenshots`;
  const screenshotPaths = new Set();

  for (const row of browser.cases) {
    const entry = manifest.entries.find((candidate) => candidate.key === row.variation_key);
    if (!entry) fail(`browser case has no generated-manifest entry: ${row.key}`);
    const expectedKey = row.case_kind === "canonical"
      ? `${entry.key}::${row.width}::${row.theme}`
      : `${entry.key}::compatibility::${row.width}::${row.theme}`;
    if (row.key !== expectedKey || row.scenario_id !== entry.scenario_id || row.state !== entry.scenario_id ||
        row.source !== entry.input_source || row.renderer !== entry.production_renderer || row.lane !== entry.proof_lane ||
        row.route_variation_id !== entry.route_variation_id || row.url !== mountedStoryPath(entry)) {
      fail(`browser case attribution or direct route differs from its manifest entry: ${row.key}`);
    }
    if (row.viewport?.width !== row.width || row.applied_theme?.dataTheme !== row.theme) fail(`browser viewport or theme differs from its declared cell: ${row.key}`);
    if (row.case_kind === "canonical") {
      const expectedName = `${row.scenario_id}-${row.width}-${row.theme}.png`;
      const expectedPath = `${screenshotDirectory}/${expectedName}`;
      if (row.screenshot?.path !== expectedPath || !/^[0-9a-f]{64}$/.test(row.screenshot?.sha256 || "") || screenshotPaths.has(row.screenshot.path)) {
        fail(`canonical screenshot path or digest is missing, duplicated, or outside the unique run: ${row.key}`);
      }
      if (row.screenshot.state !== row.scenario_id || row.screenshot.width !== row.width || row.screenshot.theme !== row.theme) {
        fail(`canonical screenshot identity differs from its direct route cell: ${row.key}`);
      }
      const image = fs.readFileSync(resolveRelative(root, row.screenshot.path));
      if (image.length < 100 || !image.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) || sha256(image) !== row.screenshot.sha256) {
        fail(`canonical screenshot bytes are not a current PNG for the rendered route: ${row.key}`);
      }
      screenshotPaths.add(row.screenshot.path);
    }
    exactSet(row.ui_predicate_ids || [], UI_IDS, `${row.key} UI assertion IDs`);
    if (typeof row.actual_content?.text_length !== "number" || row.actual_content.text_length <= 0) fail(`actual DOM content length is missing: ${row.key}`);
    if (!row.served_assets?.cssHref?.includes("/dev/storybook/assets/storybook-css-") ||
        !row.served_assets?.jsHref?.includes("/dev/storybook/assets/storybook-js-")) fail(`served CSS/JS evidence is missing or not a Storybook asset route: ${row.key}`);
    if (row.fonts?.status !== "loaded" || row.fonts?.sans !== true || row.fonts?.mono !== true) fail(`font evidence is incomplete: ${row.key}`);
    if (row.asset_identity?.storybook_css_sha256 !== sourceDigests["accrue_admin/priv/static/storybook.css"] ||
        row.asset_identity?.storybook_js_sha256 !== sourceDigests["accrue_admin/priv/static/storybook.js"]) fail(`served asset digest is stale or pooled: ${row.key}`);
  }
  if (screenshotPaths.size !== 12) fail("browser evidence does not contain twelve unique canonical screenshots");
  for (const row of canonical) {
    for (const assertion of REQUIRED_RENDER_ASSERTIONS) if (row.assertions?.[assertion] !== true) fail(`canonical case lacks ${assertion}: ${row.key}`);
  }
  const negativeIds = ["invalid_route", "missing_variation", "metadata_only"];
  if (browser.negative_controls?.baseline_accepted !== true || negativeIds.some((id) => browser.negative_controls?.[id]?.rejected !== true)) fail("browser reconciliation negative controls are incomplete");
  exactSet(Object.keys(browser.ui_predicate_coverage || {}), UI_IDS, "UI predicate IDs");
  for (const id of UI_IDS) {
    const item = browser.ui_predicate_coverage[id];
    if (!Array.isArray(item.assertions) || !Array.isArray(item.cells)) fail(`UI evidence is incomplete: ${id}`);
    exactSet(item.assertions, UI_ASSERTIONS[id], `${id} assertion map`);
    exactSet(item.cells, expectedCells(id, canonical), `${id} independent case rows`);
    const expectedControls = id.endsWith("-error") ? [...negativeIds, "authority_regression"] : [];
    exactSet(item.controls || [], expectedControls, `${id} control map`);
    for (const assertion of item.assertions) validateUiAssertion(assertion, item.cells, rowsByKey, browser, commands);
  }
  return { browser, browserPath, canonical, compatibility };
}

function readPhaseArtifact(root, relative) {
  const absolute = resolvePhaseEvidencePath(PHASE_SLUG, relative, { root });
  return { absolute, source: fs.readFileSync(absolute, "utf8") };
}

function extractFrontmatter(source, file) {
  const found = source.match(/^---\n([\s\S]*?)\n---(?:\n|$)/);
  if (!found) fail(`${file} has no YAML frontmatter`);
  return found[1];
}

function collectProhibitions(metadata, file) {
  const lines = metadata.split("\n");
  const start = lines.findIndex((line) => /^\s*prohibitions:\s*$/.test(line));
  if (start === -1) return [];
  const indentation = lines[start].match(/^\s*/)[0].length;
  const section = [];
  for (const line of lines.slice(start + 1)) {
    const lineIndentation = line.match(/^\s*/)[0].length;
    if (line.trim() && lineIndentation <= indentation && /^[A-Za-z0-9_-]+:\s*$/.test(line.trim())) break;
    section.push(line);
  }
  const raw = section.join("\n");
  const descriptor = ORIGINAL_PROHIBITION_DESCRIPTORS.find((candidate) => candidate.plan === file);
  if (!descriptor) {
    if (/^\s*-\s+statement:/m.test(raw)) fail(`${file} adds an unexpected prohibition statement`);
    return [];
  }
  const itemIndent = indentation + 2;
  const statementRows = [...raw.matchAll(new RegExp(`^\\s{${itemIndent}}-\\s+statement:\\s*(.+)$`, "gm"))];
  if (statementRows.length !== 1) fail(`${file} must retain exactly one original prohibition statement`);
  const statement = statementRows[0][1].trim().replace(/^['"]|['"]$/g, "");
  if (statement !== descriptor.statement) fail(`${file} prohibition statement changed or was relabelled`);
  const entryStart = statementRows[0].index;
  const nextItem = raw.slice(entryStart + statementRows[0][0].length).search(new RegExp(`^\\s{${itemIndent}}-\\s+`, "m"));
  const chunk = raw.slice(entryStart + statementRows[0][0].length, nextItem === -1 ? raw.length : entryStart + statementRows[0][0].length + nextItem);
  const fields = new Map();
  const propertyIndent = itemIndent + 2;
  for (const line of chunk.split("\n")) {
    if (!line.trim()) continue;
    const match = line.match(new RegExp(`^\\s{${propertyIndent}}([a-z_]+):\\s*(.*?)\\s*$`));
    if (!match) fail(`${file} prohibition descriptor must use flat scalar fields`);
    const [, key, rawValue] = match;
    if (fields.has(key)) fail(`${file} prohibition descriptor repeats ${key}`);
    if (!rawValue || /^[>|[{]/.test(rawValue)) fail(`${file} prohibition descriptor ${key} must be a nonempty scalar`);
    fields.set(key, rawValue.replace(/^['"]|['"]$/g, ""));
  }
  const expectedKeys = ["category", "status", "verification", "resolution", "check_kind", "check_target", "check_violation_fixture", "check_clean_fixture"];
  exactSet([...fields.keys()], expectedKeys, `${file} prohibition descriptor fields`);
  if (fields.get("category") !== "transparency" || fields.get("status") !== "resolved" || fields.get("verification") !== "test") {
    fail(`${file} prohibition must be resolved, test-tier transparency metadata`);
  }
  if (fields.get("check_kind") !== "node-test" || fields.get("check_target") !== descriptor.target ||
      fields.get("check_violation_fixture") !== descriptor.violationFixture || fields.get("check_clean_fixture") !== descriptor.cleanFixture) {
    fail(`${file} prohibition target or control descriptor is incomplete, changed, or swapped`);
  }
  if (!fields.get("resolution").includes(descriptor.target)) fail(`${file} prohibition resolution does not name its bounded target`);
  return [{ ...descriptor, plan: file, statement, status: fields.get("status"), resolution: fields.get("resolution") }];
}

function inspectPlanSources(root) {
  const sources = [];
  for (let number = 1; number <= 10; number += 1) {
    const name = `252-${String(number).padStart(2, "0")}-PLAN.md`;
    const { source } = readPhaseArtifact(root, name);
    sources.push({ name, source, metadata: extractFrontmatter(source, name) });
  }
  const plan08 = sources.find(({ name }) => name === "252-08-PLAN.md");
  const requirementRow = plan08.metadata.match(/^requirements:\s*\[([^\]]*)\]/m);
  if (!requirementRow) fail("plan 252-08 has no requirements list");
  const requirements = [...requirementRow[1].matchAll(/["']([^"']+)["']/g)].map((match) => match[1]);
  exactSet(requirements, REQUIREMENT_IDS, "plan requirement IDs");
  const tasks = sources.filter(({ name }) => ["252-08-PLAN.md", "252-09-PLAN.md", "252-10-PLAN.md"].includes(name))
    .flatMap(({ source }) => [...source.matchAll(/<name>\s*(252-\d{2}-\d{2}):/g)].map((match) => match[1]));
  exactSet(tasks, TASK_IDS, "plan task IDs");

  const edgeIds = [...new Set(sources.flatMap(({ source }) => source.match(/EDGE-[A-Z]+-\d+-[a-z0-9-]+/g) || []))];
  exactSet(edgeIds.filter((id) => !id.endsWith("-unclassified")), EDGE_IDS, "classified edge predicates");
  exactSet(edgeIds.filter((id) => id.endsWith("-unclassified")), UNCLASSIFIED_EDGE_IDS, "unclassified assumptions");
  const plan06 = sources.find(({ name }) => name === "252-06-PLAN.md");
  const uiIds = [...new Set(plan06.source.match(/UI-E[1-3]-[a-z0-9-]+/g) || [])];
  exactSet(uiIds, UI_IDS, "UI-SPEC predicate IDs");

  const { source: validation } = readPhaseArtifact(root, "252-VALIDATION.md");
  if (!/17 surfaced(?: items)?\s*=\s*13 classified explicit acceptance truths plus four unclassified unresolved flagged assumptions/i.test(validation)) {
    fail("validation accounting must retain 13 classified truths and four unresolved assumptions");
  }
  const prohibitions = sources.flatMap(({ metadata, name }) => collectProhibitions(metadata, name));
  exactSet(prohibitions.map(({ plan }) => plan), ORIGINAL_PROHIBITION_DESCRIPTORS.map(({ plan }) => plan), "original transparency prohibition plans");
  exactSet(prohibitions.map(({ statement }) => statement), ORIGINAL_PROHIBITION_DESCRIPTORS.map(({ statement }) => statement), "original transparency prohibition statements");
  return { requirements, tasks, edges: EDGE_IDS, unclassified: UNCLASSIFIED_EDGE_IDS, uiIds, prohibitions };
}

export function validateGuideContract(guide) {
  if (typeof guide !== "string") fail("guide text is required");
  if (!/The final repository-root gate is:[\s\S]{0,120}npm --prefix accrue_admin run phase252:check/.test(guide)) fail("guide must name the final phase252:check owner command");
  if (!/available after plan 252-08 adds (?:its )?runner and package script/i.test(guide)) fail("guide must state when the phase gate becomes available");
  if (!/Static rendering[\s\S]{0,180}does not prove mounted authorization, provider completion, dispatched action behavior, or persistence/i.test(guide)) fail("guide must state the static-render evidence limits");
  if (!/Automated UAT requires fresh assertion evidence[\s\S]{0,180}not persisted\/isolation evidence/i.test(guide)) fail("guide must distinguish static and persisted/isolation evidence");
  if (!/first bootstrap compiles and migrates an empty disposable database[\s\S]*startup time should be recorded separately from warm browser renders/i.test(guide)) fail("guide must separate cold database startup and warm render cost");
  if (!/budgets are provisional; Phase 254 owns frozen recurring selection and budgets/i.test(guide)) fail("guide must leave cost budgets provisional for Phase 254");
  return "passed";
}

function hasAssertion(commands, commandId, assertion) {
  if (commandId === "bundle") return assertion === "all_required_commands_passed";
  if (commandId === "browser") return assertion === "twenty_ui_predicates";
  return commands.get(commandId)?.assertion_refs.includes(assertion) === true;
}

function refsFor(bundle, references) {
  const commands = new Map(bundle.commands.map((row) => [row.id, row]));
  return references.map(([commandId, assertion]) => {
    if (!hasAssertion(commands, commandId, assertion)) fail(`missing assertion evidence ${commandId}:${assertion}`);
    if (commandId === "bundle") return `${bundle.results_path}#bundle:${assertion}`;
    if (commandId === "browser") return `${bundle.results_path}#browser:${assertion}`;
    return `${bundle.results_path}#commands:${commandId}:${assertion}`;
  });
}

function validateAssertionMaps(commands, bundle, browserData) {
  for (const [id, refs] of Object.entries(REQUIREMENT_EVIDENCE)) {
    if (!refs.every(([command, assertion]) => hasAssertion(commands, command, assertion))) fail(`requirement ${id} lacks current owner assertion evidence`);
  }
  for (const [id, refs] of Object.entries(EDGE_EVIDENCE)) {
    if (!refs.every(([command, assertion]) => hasAssertion(commands, command, assertion))) fail(`${id} lacks current owner assertion evidence`);
  }
  for (const [id, refs] of Object.entries(TASK_EVIDENCE)) {
    if (!refs.every(([command, assertion]) => hasAssertion(commands, command, assertion))) fail(`task ${id} lacks current owner assertion evidence`);
  }
  return {
    requirements: Object.fromEntries(Object.entries(REQUIREMENT_EVIDENCE).map(([id, refs]) => [id, refsFor(bundle, refs)])),
    tasks: Object.fromEntries(Object.entries(TASK_EVIDENCE).map(([id, refs]) => [id, refsFor(bundle, refs)])),
    edges: Object.fromEntries(Object.entries(EDGE_EVIDENCE).map(([id, refs]) => [id, refsFor(bundle, refs)])),
    ui: Object.fromEntries(UI_IDS.map((id) => [id, [`${bundle.browser_result_path}#ui:${id}`, `${bundle.results_path}#commands:subscription-render-browser:twenty_ui_predicates`]])),
    uiData: Object.fromEntries(UI_IDS.map((id) => [id, browserData.browser.ui_predicate_coverage[id]])),
  };
}

function mapProhibitionEvidence(root, plan, commands, bundle) {
  validateTransparencyFixtures(root);
  return plan.prohibitions.map((descriptor) => {
    const configured = ORIGINAL_PROHIBITION_DESCRIPTORS.find(({ id }) => id === descriptor.id);
    if (!configured || descriptor.target !== configured.target || descriptor.violationFixture !== configured.violationFixture || descriptor.cleanFixture !== configured.cleanFixture) {
      fail(`${descriptor.plan} descriptor does not match the bounded current prohibition target`);
    }
    const target = refsFor(bundle, configured.targetAssertions.map((assertion) => [configured.targetCommand, assertion]));
    const controls = refsFor(bundle, configured.controlAssertions.map((assertion) => ["transparency-controls", assertion]));
    const sourceRefs = [descriptor.plan.startsWith("252-01")
      ? `.planning/phases/${PHASE_SLUG}/252-01-PLAN.md`
      : `.planning/phases/${PHASE_SLUG}/252-04-PLAN.md`,
    configured.target, configured.violationFixture, configured.cleanFixture,
    "scripts/ci/verify_phase252_transparency.mjs", "guides/ui-story-lab.md"];
    const sourceDigests = Object.fromEntries(sourceRefs.map((source) => {
      const value = bundle.source_digests?.[source];
      if (!value) fail(`${descriptor.id} is missing a fresh descriptor, target, fixture, checker, or guide digest: ${source}`);
      return [source, value];
    }));
    return {
      id: configured.id,
      plan: configured.plan,
      statement: configured.statement,
      status: "green",
      flagged: false,
      check: { kind: "node-test", target: configured.target, violation_fixture: configured.violationFixture, clean_fixture: configured.cleanFixture },
      evidence_refs: [...target, ...controls],
      source_digests: sourceDigests,
    };
  });
}

function validateTransparencyFixtures(root) {
  const claims = {
    "PROH-LAB-PRESENTATION": /the review lab is a production operations console/i,
    "PROH-HELDOUT-ATTRIBUTION": /the held-out stress input represents typical customer behavior/i,
  };
  for (const descriptor of ORIGINAL_PROHIBITION_DESCRIPTORS) {
    const violation = readJson(resolveRelative(root, descriptor.violationFixture), `${descriptor.id} violation fixture`);
    const clean = readJson(resolveRelative(root, descriptor.cleanFixture), `${descriptor.id} clean fixture`);
    const violationGuide = typeof violation.guide === "string" ? violation.guide : violation.guide?.text;
    const cleanGuide = typeof clean.guide === "string" ? clean.guide : clean.guide?.text;
    const claim = claims[descriptor.id];
    if (typeof violationGuide !== "string" || !claim.test(violationGuide)) fail(`${descriptor.id} violation fixture no longer carries its intended contradictory claim`);
    if (!/rendered controls do not establish completed billing actions/i.test(violationGuide) ||
        !/not representative customer behavior or real adopter usage evidence/i.test(violationGuide)) {
      fail(`${descriptor.id} violation fixture must keep the contradiction beside the original limiting disclaimer`);
    }
    if (typeof cleanGuide !== "string" || claim.test(cleanGuide) || !/not representative customer behavior or real adopter usage evidence/i.test(cleanGuide)) {
      fail(`${descriptor.id} clean fixture is missing its bounded non-contradictory attribution`);
    }
  }
}

function unresolvedMetadata(plan, mapped) {
  const concreteCoverage = {
    "EDGE-CIQ-01-unclassified": ["CIQ-01"],
    "EDGE-LAB-02-unclassified": ["LAB-02"],
    "EDGE-SBK-03-unclassified": ["SBK-03", "UI-E2-populated", "UI-E3-populated"],
    "EDGE-SCEN-01-unclassified": ["SCEN-01"],
  };
  const assumptions = plan.unclassified.map((id) => ({
    id,
    status: "unresolved",
    concrete_behavior_coverage: concreteCoverage[id].flatMap((coverageId) => mapped.requirements[coverageId] || mapped.ui[coverageId] || []),
  }));
  return {
    assumptions,
  };
}

function parseCoverage(source, file) {
  const metadata = extractFrontmatter(source, file);
  const status = metadata.match(/^status:\s*["']?([^\s"']+)/m)?.[1];
  if (status !== "complete") fail(`${file} must have status: complete`);
  const completed = metadata.match(/^\s*completed:\s*["']?([^\n"']+)/m)?.[1]?.trim();
  if (!completed) fail(`${file} has no completed date for deterministic UAT generation`);
  const lines = metadata.split("\n");
  const start = lines.findIndex((line) => line === "coverage:");
  if (start === -1) fail(`${file} has no executable coverage`);
  const sectionLines = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[A-Za-z0-9_-]+:/.test(line)) break;
    sectionLines.push(line);
  }
  const section = sectionLines.join("\n");
  const entries = section.split(/\n(?=  - id:)/).filter((part) => /^  - id:/m.test(part));
  if (entries.length === 0) fail(`${file} has no coverage entries`);
  for (const entry of entries) {
    if (!/^\s+human_judgment:\s*false\s*$/m.test(entry)) fail(`${file} coverage is missing human_judgment: false`);
    const statuses = [...entry.matchAll(/^\s+status:\s*([^\s#]+)/gm)].map((match) => match[1]);
    const refs = [...entry.matchAll(/^\s+ref:\s*["']?([^\n"']+)/gm)];
    if (statuses.length === 0 || statuses.some((value) => value !== "pass") || refs.length === 0) fail(`${file} coverage contains an unproved or unreferenced item`);
  }
  return { metadata, completed, entries };
}

function phaseSummaries(root) {
  const summaries = [];
  for (let number = 1; number <= 10; number += 1) {
    const name = `252-${String(number).padStart(2, "0")}-SUMMARY.md`;
    const artifact = readPhaseArtifact(root, name);
    const parsed = parseCoverage(artifact.source, name);
    if ([8, 10].includes(number) && parsed.metadata.match(/^human_judgment:\s*(true|false)\s*$/m)?.[1] !== "false") fail(`${name} must declare human_judgment: false`);
    summaries.push({ name, absolute: artifact.absolute, source: artifact.source, ...parsed });
  }
  return summaries;
}

function validateCurrentSummary(summaries, bundle, mapped, prohibitionEvidence) {
  const summary = summaries.find(({ name }) => name === "252-10-SUMMARY.md");
  if (!summary) fail("current acceptance requires the completed 252-10-SUMMARY.md");
  const coverageById = new Map(summary.entries.map((entry) => {
    const id = entry.match(/^  - id:\s*["']?([^\s"']+)/m)?.[1];
    return [id, entry];
  }));
  const expectedIds = [...REQUIREMENT_IDS, ...TASK_IDS, ...EDGE_IDS, ...UI_IDS, ...PROHIBITION_IDS];
  exactSet([...coverageById.keys()], expectedIds, "plan 252-10 summary coverage IDs");
  for (const id of REQUIREMENT_IDS) {
    const entry = coverageById.get(id);
    for (const ref of mapped.requirements[id]) if (!entry.includes(ref)) fail(`summary coverage ${id} omits current evidence reference ${ref}`);
  }
  for (const id of TASK_IDS) {
    const entry = coverageById.get(id);
    for (const ref of mapped.tasks[id]) if (!entry.includes(ref)) fail(`summary coverage ${id} omits current evidence reference ${ref}`);
  }
  for (const id of EDGE_IDS) {
    const entry = coverageById.get(id);
    for (const ref of mapped.edges[id]) if (!entry.includes(ref)) fail(`summary coverage ${id} omits current evidence reference ${ref}`);
  }
  for (const id of UI_IDS) {
    const entry = coverageById.get(id);
    for (const ref of mapped.ui[id]) if (!entry.includes(ref)) fail(`summary coverage ${id} omits current evidence reference ${ref}`);
  }
  for (const item of prohibitionEvidence) {
    const entry = coverageById.get(item.id);
    for (const ref of item.evidence_refs) if (!entry.includes(ref)) fail(`summary coverage ${item.id} omits current evidence reference ${ref}`);
  }
  if (!summary.absolute.endsWith(path.join(PHASE_SLUG, "252-10-SUMMARY.md"))) fail("summary resolver returned a different current phase artifact");
  if (!bundle.results_path) fail("current runner result path is missing for summary cross-check");
  return coverageById;
}

function renderUat(summaries) {
  const entries = summaries.flatMap(({ name, entries }) => entries.map((entry) => ({ name, entry })));
  const dates = summaries.map(({ completed }) => completed).sort();
  const tests = entries.map(({ name, entry }, index) => {
    const id = entry.match(/^\s+- id:\s*["']?([^\s"']+)/m)?.[1] || `coverage-${index + 1}`;
    const description = entry.match(/^\s+description:\s*["']?([^\n"']+)/m)?.[1]?.trim() || `${name} ${id}`;
    const refs = [...entry.matchAll(/^\s+ref:\s*["']?([^\n"']+)/gm)].map((match) => match[1].trim());
    const statuses = [...entry.matchAll(/^\s+status:\s*([^\s#]+)/gm)].map((match) => match[1]);
    const result = statuses.length > 0 && statuses.every((status) => status === "pass") ? "pass" : "issue";
    return `### ${index + 1}. ${description}\nsource: automated\nverification: ${refs.join(" | ")}\nresult: [${result}]`;
  });
  const phase = "252";
  return `---\nstatus: complete\nphase: ${phase}\nsource: executable-summary-coverage\nstarted: ${dates[0]}\nupdated: ${dates.at(-1)}\n---\n\n# Phase ${phase} Automated UAT\n\nEvery acceptance item below is produced from committed executable coverage. No post-hoc human verification is required.\n\n## Tests\n\n${tests.join("\n\n")}\n\n## Summary\n\ntotal: ${tests.length}\npassed: ${tests.filter((item) => item.includes("result: [pass]")).length}\nissues: ${tests.filter((item) => item.includes("result: [issue]")).length}\npending: 0\nskipped: 0\nblocked: 0\n`;
}

export function validatePhase252Evidence({ root = ROOT, resultsPath }) {
  const repository = realRoot(root);
  const bundlePath = resolveResultsPath(repository, resultsPath);
  const bundle = readJson(bundlePath, "runner result bundle");
  const commands = validateCommands(repository, bundle, bundlePath);
  const sourceDigests = validateSourceSnapshot(repository, bundle);
  const { manifest, manifestDigest } = validateManifest(repository, bundle, sourceDigests);
  const browserData = validateBrowser(repository, bundle, sourceDigests, manifest, manifestDigest, commands);
  if (bundle.browser_results_sha256 !== sha256(fs.readFileSync(browserData.browserPath))) fail("browser result digest does not match the runner bundle");
  if (!Array.isArray(bundle.requirements)) fail("runner result has no requirement list");
  exactSet(bundle.requirements, REQUIREMENT_IDS, "runner requirement IDs");
  const plan = inspectPlanSources(repository);
  const guidePath = resolveRelative(repository, "guides/ui-story-lab.md");
  const guideContract = validateGuideContract(fs.readFileSync(guidePath, "utf8"));
  const mapped = validateAssertionMaps(commands, bundle, browserData);
  const prohibitions = mapProhibitionEvidence(repository, plan, commands, bundle);
  const unresolved = unresolvedMetadata(plan, mapped);
  return {
    status: "passed",
    plan: "252-08",
    run_id: bundle.run_id,
    human_judgment: false,
    command_count: bundle.commands.length,
    requirements: plan.requirements,
    tasks: plan.tasks,
    classified_edges: plan.edges,
    ui_predicates: plan.uiIds,
    unresolved_assumptions: unresolved.assumptions,
    unresolved_prohibitions: [],
    prohibition_evidence: prohibitions,
    guide_contract: guideContract,
    results_path: bundle.results_path,
    browser_result_path: bundle.browser_result_path,
    evidence_refs: { requirements: mapped.requirements, tasks: mapped.tasks, edges: mapped.edges, ui: mapped.ui, prohibitions: Object.fromEntries(prohibitions.map(({ id, evidence_refs }) => [id, evidence_refs])) },
  };
}

export function generatePhase252Acceptance({ root = ROOT, resultsPath, writeUat = false }) {
  const evidence = validatePhase252Evidence({ root, resultsPath });
  if (!writeUat) return { evidence, uat_written: false, uat_path: null };
  const summaries = phaseSummaries(realRoot(root));
  const bundlePath = resolveResultsPath(root, resultsPath);
  const bundle = readJson(bundlePath, "runner result bundle");
  const { manifest } = validateManifest(root, bundle, validateSourceSnapshot(root, bundle));
  const browserData = validateBrowser(root, bundle, bundle.source_digests, manifest, bundle.manifest_sha256, new Map(bundle.commands.map((row) => [row.id, row])));
  const mapped = validateAssertionMaps(new Map(bundle.commands.map((row) => [row.id, row])), bundle, browserData);
  validateCurrentSummary(summaries, bundle, mapped, evidence.prohibition_evidence);
  const destination = path.join(path.dirname(summaries.find(({ name }) => name === "252-10-SUMMARY.md").absolute), "252-UAT.md");
  fs.writeFileSync(destination, renderUat(summaries), { mode: 0o600 });
  return { evidence, uat_written: true, uat_path: path.relative(realRoot(root), destination).split(path.sep).join("/") };
}

function main() {
  const args = process.argv.slice(2);
  const resultsIndex = args.indexOf("--results");
  if (resultsIndex === -1 || !args[resultsIndex + 1]) fail("usage: node generate_phase252_acceptance.mjs --results <repository-relative-results.json> [--write]");
  const result = generatePhase252Acceptance({ root: ROOT, resultsPath: args[resultsIndex + 1], writeUat: args.includes("--write") });
  process.stdout.write(JSON.stringify({ ...result.evidence, uat_written: result.uat_written, uat_path: result.uat_path }, null, 2) + "\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try { main(); } catch (error) {
    process.stderr.write(`generate_phase252_acceptance: ${error.message}\n`);
    process.exitCode = 2;
  }
}
