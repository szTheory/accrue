#!/usr/bin/env node

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { REQUIRED_COMMAND_IDS } from "./verify_phase252_stories.mjs";
import { LEDGER_PATH, SUBSCRIPTION_STORY_PATH, expectedPhase252Cells } from "./verify_phase254_curation.mjs";
import { deriveExecutionEvidence, expectedExUnitIdentities, expectedNodeTestIdentities, parseTap13Report, PHASE252_REPORTER_SPECS, requiredAssertionIds } from "./phase252_reporters.mjs";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import {
  assertEvidenceRowCounts,
  generatePhase252Acceptance,
  validateCurrentPhase252Metadata,
  validateGuideContract,
  validatePhase252Evidence,
} from "./generate_phase252_acceptance.mjs";

const PHASE_SLUG = "252-production-backed-subscription-stories";
const REQUIREMENTS = ["CIQ-01", "SBK-01", "SBK-02", "SBK-03", "SCEN-01", "SCEN-02", "SCEN-03", "SCEN-04", "LAB-01", "LAB-02"];
const TASK_IDS = ["252-08-01", "252-08-02", "252-08-03", "252-09-01", "252-09-02", "252-10-01", "252-10-02", "252-10-03"];
const PROHIBITION_IDS = ["PROH-LAB-PRESENTATION", "PROH-HELDOUT-ATTRIBUTION"];
const TRANSPARENCY_SOURCE_PATHS = [
  "scripts/ci/phase_evidence_path.mjs", "scripts/ci/main_module.mjs", "scripts/ci/verify_phase252_transparency.mjs",
  "scripts/ci/verify_phase252_lab_presentation.test.mjs", "scripts/ci/verify_phase252_heldout_attribution.test.mjs",
  "scripts/ci/fixtures/phase252-transparency/lab-clean.json", "scripts/ci/fixtures/phase252-transparency/lab-violation.json",
  "scripts/ci/fixtures/phase252-transparency/heldout-clean.json", "scripts/ci/fixtures/phase252-transparency/heldout-violation.json",
  "guides/ui-story-lab.md", "storybook/components/subscription_detail.story.exs", "storybook/phase252-manifest.json",
  "dev_support/ui_scenarios/cadence_subscriptions.exs", "accrue_admin/storybook/_support/subscription_scenarios.ex",
  "accrue_admin/e2e/phase252-story-helpers.js",
  ...Array.from({ length: 10 }, (_, index) => `.planning/phases/${PHASE_SLUG}/252-${String(index + 1).padStart(2, "0")}-PLAN.md`),
  `.planning/phases/${PHASE_SLUG}/252-VALIDATION.md`,
];
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
const repositoryRoot = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");

function nodeTapReport(identities) {
  return [
    "TAP version 13",
    ...identities.map((identity, index) => `ok ${index + 1} - ${identity}`),
    `1..${identities.length}`,
    `# tests ${identities.length}`,
    `# pass ${identities.length}`,
    "# fail 0",
    "# cancelled 0",
    "# skipped 0",
    "# todo 0",
    "",
  ].join("\n");
}

function exUnitTapReport(identities) {
  return ["TAP version 13", ...identities.map((identity, index) => `ok ${index + 1} - ${identity}`), `1..${identities.length}`, ""].join("\n");
}

function fixtureReporterOutput(root, commandId, rows) {
  const spec = PHASE252_REPORTER_SPECS[commandId];
  if (spec.kind === "node-tap") return nodeTapReport(expectedNodeTestIdentities(root, spec.testFiles));
  if (spec.kind === "exunit-tap") return exUnitTapReport(expectedExUnitIdentities(root, spec.testFiles));
  if (spec.kind === "playwright-json") {
    const identities = [...rows.map((row) => row.test_id), "reconciles every declared direct render against the generated manifest"];
    return JSON.stringify({
      errors: [],
      stats: { expected: identities.length, unexpected: 0, skipped: 0, flaky: 0 },
      suites: [{ specs: identities.map((title) => ({ title, tests: [{ title, expectedStatus: "passed", results: [{ status: "passed" }] }] })) }],
    });
  }
  const markers = requiredAssertionIds(commandId).map((assertion) => `PHASE252_ASSERTION=${assertion}`);
  if (commandId === "production-packages") {
    return [
      ...["accrue", "accrue_admin", "accrue_portal"].map((name) => `PASS ${name}: isolated production compile, actual Hex package contents, and runtime boundary (42 files).`),
      "Phase 252 production package boundary verified for all three packages.",
      ...markers,
      "",
    ].join("\n");
  }
  return [...markers, ""].join("\n");
}

function rewriteFixtureCommandOutput(fixture, commandId, transform) {
  const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
  const command = bundle.commands.find((row) => row.id === commandId);
  const outputPath = path.join(fixture.root, command.stdout_path);
  const nextOutput = transform(fs.readFileSync(outputPath, "utf8"));
  fs.writeFileSync(outputPath, nextOutput);
  command.stdout_sha256 = digest(nextOutput);
  command.execution_evidence.stdout_sha256 = digest(nextOutput);
  fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
  return bundle;
}

function refreshSourceDigest(fixture, relative) {
  const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
  const prefix = `.planning/phases/${PHASE_SLUG}/`;
  const absolute = relative.startsWith(prefix)
    ? resolvePhaseEvidencePath(PHASE_SLUG, relative.slice(prefix.length), { root: fixture.root })
    : path.join(fixture.root, relative);
  bundle.source_digests[relative] = digest(fs.readFileSync(absolute));
  const sorted = Object.fromEntries(Object.entries(bundle.source_digests).sort(([left], [right]) => left < right ? -1 : left > right ? 1 : 0));
  bundle.source_fingerprint = digest(JSON.stringify(sorted));
  fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
}

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
  "LAB-01": [["phase252-lab-contract", "namespace_lock_one_owner"], ["phase252-lab-contract", "exact_process_identity_cleanup"], ["phase252-lab-contract", "owned_process_group_identity"], ["isolation-reset", "distinct_review_process_and_database"], ["isolation-reset", "interrupted_descendant_cleanup_before_database_drop"], ["isolation-reset", "owned_descendants_cleanup_after_leader_exit"], ["isolation-reset", "unrelated_process_survives_group_cleanup"]],
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
  const refs = requiredAssertionIds(id);
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
      ? `\nprohibitions:\n  - statement: "The review lab must not be presented as a production operations console or evidence of completed billing actions."\n    category: transparency\n    status: resolved\n    verification: test\n    resolution: "Bounded by scripts/ci/verify_phase252_lab_presentation.test.mjs with fresh clean and violation controls."\n    check_kind: node-test\n    check_target: scripts/ci/verify_phase252_lab_presentation.test.mjs\n    check_violation_fixture: scripts/ci/fixtures/phase252-transparency/lab-violation.json\n    check_clean_fixture: scripts/ci/fixtures/phase252-transparency/lab-clean.json\n`
      : plan === 4
        ? `\nprohibitions:\n  - statement: "Held-out adversarial scenarios must not be presented as representative customer behavior or evidence of real adopter usage."\n    category: transparency\n    status: resolved\n    verification: test\n    resolution: "Bounded by scripts/ci/verify_phase252_heldout_attribution.test.mjs with fresh clean and violation controls."\n    check_kind: node-test\n    check_target: scripts/ci/verify_phase252_heldout_attribution.test.mjs\n    check_violation_fixture: scripts/ci/fixtures/phase252-transparency/heldout-violation.json\n    check_clean_fixture: scripts/ci/fixtures/phase252-transparency/heldout-clean.json\n`
        : "";
    const ui = plan === 6 ? `\nmust_haves:\n  truths:\n${UI_IDS.map((id) => `    - "${id}: explicit UI truth"`).join("\n")}\n` : "";
    write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/${name}`, `---\n${truths ? `must_haves:\n  truths:\n${truths}\n` : ""}${ui}${prohibitions}---\n`);
    write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-${String(plan).padStart(2, "0")}-SUMMARY.md`, `---\nstatus: complete\ncompleted: 2026-10-${String(20 + plan).padStart(2, "0")}\ncoverage:\n  - id: P${plan}\n    description: Previous phase plan evidence\n    verification:\n      - kind: integration\n        ref: "scripts/ci/verify_phase252_stories.mjs#previous-plan-${plan}"\n        status: pass\n    human_judgment: false\n---\n`);
  }
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-08-PLAN.md`, `---\n${planRequirements}\n---\n<task><name>252-08-01: Prove required-owner admission</name></task><task><name>252-08-02: Run focused checks</name></task><task><name>252-08-03: Generate acceptance</name></task>\nEDGE-CIQ-01-unclassified remains explicitly unresolved.\n`);
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-09-PLAN.md`, `---\nphase: 252-production-backed-subscription-stories\nplan: "09"\n---\n<task><name>252-09-01: Prove lab presentation transparency</name></task><task><name>252-09-02: Prove held-out attribution</name></task>\n`);
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-10-PLAN.md`, `---\nphase: 252-production-backed-subscription-stories\nplan: "10"\n---\n<task><name>252-10-01: Admit transparency owner lanes</name></task><task><name>252-10-02: Migrate fresh acceptance</name></task><task><name>252-10-03: Prove and refresh descriptors</name></task>\n`);
  for (const plan of [9, 10]) {
    write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-${String(plan).padStart(2, "0")}-SUMMARY.md`, `---\nstatus: complete\ncompleted: 2026-10-${String(20 + plan).padStart(2, "0")}\nhuman_judgment: false\ncoverage:\n  - id: P${plan}\n    description: Historical plan evidence\n    verification:\n      - kind: integration\n        ref: "scripts/ci/verify_phase252_stories.mjs#historical-${plan}"\n        status: pass\n    human_judgment: false\n---\n`);
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
  write(root, "scripts/ci/phase252_reporters.mjs", fs.readFileSync(path.join(repositoryRoot, "scripts/ci/phase252_reporters.mjs")));
  // Phase 254 CURATE-01: the browser row counts derive from the curation ledger, so the fixture carries a copy.
  // The fixture renders the frozen 12 canonical + 3 compatibility rows, so it carries the committed
  // ledger with its records cleared: the frozen-baseline positive control (15 rows). Tests that need
  // a retirement add one explicitly (retireCompatibilityId).
  write(root, LEDGER_PATH, JSON.stringify({ ...JSON.parse(fs.readFileSync(path.join(repositoryRoot, LEDGER_PATH), "utf8")), records: [] }, null, 2));
  for (const relativePath of TRANSPARENCY_SOURCE_PATHS.filter((relative) => !relative.startsWith(".planning/") && relative !== "storybook/phase252-manifest.json")) {
    write(root, relativePath, fs.readFileSync(path.join(repositoryRoot, relativePath)));
  }
  write(root, "scripts/ci/phase_evidence_path.mjs", fs.readFileSync(path.join(repositoryRoot, "scripts/ci/phase_evidence_path.mjs")));
  write(root, "dev_support/phase252_tap_formatter.ex", fs.readFileSync(path.join(repositoryRoot, "dev_support/phase252_tap_formatter.ex")));
  write(root, "accrue_admin/test/test_helper.exs", fs.readFileSync(path.join(repositoryRoot, "accrue_admin/test/test_helper.exs")));
  write(root, "examples/accrue_host/test/test_helper.exs", fs.readFileSync(path.join(repositoryRoot, "examples/accrue_host/test/test_helper.exs")));
  write(root, "storybook/components/subscription_detail.story.exs", fs.readFileSync(path.join(repositoryRoot, "storybook/components/subscription_detail.story.exs")));
  for (const relativePath of Object.values(PHASE252_REPORTER_SPECS).flatMap((spec) => spec.testFiles || [])) {
    write(root, relativePath, fs.readFileSync(path.join(repositoryRoot, relativePath)));
  }
  write(root, "dev_support/ui_scenarios/cadence_subscriptions.exs", "fixture scenario source");
  const manifest = {
    schema_version: 1,
    source_digests: { "dev_support/ui_scenarios/cadence_subscriptions.exs": digest(fs.readFileSync(path.join(root, "dev_support/ui_scenarios/cadence_subscriptions.exs"))) },
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
      test_id: `${id} | compatibility | 1280px | light`,
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
  const runId = "25208-1793072424185-64706-61aa2ca2b88c";
  const screenshotDirectory = `accrue_admin/tmp/phase252/ci-results/${runId}/screenshots`;
  const fixturePng = Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), Buffer.alloc(112, 42)]);
  for (const row of rows.filter((candidate) => candidate.case_kind === "canonical")) {
    const name = `${row.scenario_id}-${row.width}-${row.theme}.png`;
    const screenshotPath = `${screenshotDirectory}/${name}`;
    write(root, screenshotPath, fixturePng);
    row.screenshot = {
      path: screenshotPath,
      sha256: digest(fixturePng),
      state: row.scenario_id,
      width: row.width,
      theme: row.theme,
    };
  }
  const renderResults = {
    schema_version: 1,
    run_id: runId,
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
  const renderPath = write(root, `accrue_admin/tmp/phase252/render-results-${runId.toLowerCase()}.json`, JSON.stringify(renderResults, null, 2) + "\n");
  const sourcePaths = [...new Set([
    "storybook/phase252-manifest.json", "dev_support/ui_scenarios/cadence_subscriptions.exs",
    assetCssPath, assetJsPath, fontSans, fontMono, "accrue_admin/e2e/phase252-story-helpers.js",
    "scripts/ci/verify_phase252_stories.mjs",
    "scripts/ci/phase252_reporters.mjs",
    "scripts/ci/generate_phase252_acceptance.mjs",
    "scripts/ci/generate_phase252_acceptance.test.mjs",
    "dev_support/phase252_tap_formatter.ex",
    "accrue_admin/test/test_helper.exs",
    "examples/accrue_host/test/test_helper.exs",
    "storybook/components/subscription_detail.story.exs",
    ...Object.values(PHASE252_REPORTER_SPECS).flatMap((spec) => spec.testFiles || []),
    "guides/ui-story-lab.md",
    ".github/workflows/ci.yml",
    ...TRANSPARENCY_SOURCE_PATHS,
  ])].sort();
  const sourceDigests = Object.fromEntries(sourcePaths.map((relative) => [relative, digest(fs.readFileSync(relative.startsWith(`.planning/phases/${PHASE_SLUG}/`)
    ? resolvePhaseEvidencePath(PHASE_SLUG, relative.slice(`.planning/phases/${PHASE_SLUG}/`.length), { root })
    : path.join(root, relative)))]));
  const fingerprint = digest(JSON.stringify(sourceDigests));
  const resultDirectory = `accrue_admin/tmp/phase252/ci-results/${runId}`;
  const commandRecords = REQUIRED_COMMAND_IDS.map((id, index) => {
    const reporter = PHASE252_REPORTER_SPECS[id];
    const stdout = fixtureReporterOutput(root, id, rows);
    const stderr = "";
    const outPath = `${resultDirectory}/logs/${id}.stdout.log`;
    const errPath = `${resultDirectory}/logs/${id}.stderr.log`;
    write(root, outPath, stdout);
    write(root, errPath, stderr);
    const started = Date.parse("2026-10-27T00:00:00.000Z") + (index * 10);
    const executionEvidence = deriveExecutionEvidence({
      root,
      commandId: id,
      stdout,
      expectedAssertions: requiredAssertionIds(id),
      browserResult: id === "subscription-render-browser" ? renderResults : null,
    });
    return {
      id,
      command: ["node", "fixture"],
      cwd: ".",
      lane: "read-only",
      warmth: "warm",
      partition: null,
      sources: ["lab-presentation", "heldout-attribution", "transparency-controls"].includes(id) ? TRANSPARENCY_SOURCE_PATHS : reporter.testFiles || [],
      assertion_refs: executionEvidence.assertion_refs,
      execution_evidence: executionEvidence.execution_evidence,
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
  const resultsPath = write(root, `${resultDirectory}/results.json`, "{}");
  const resultBundle = {
    schema_version: 1,
    plan: "252-08",
    run_id: runId,
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
    run_completed_at: "2026-10-27T00:00:00.205Z",
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
  const currentSummaryCoverage = [...REQUIREMENTS, ...TASK_IDS, ...EDGE_IDS, ...UI_IDS, ...PROHIBITION_IDS].map((id) => `  - id: ${id}\n    description: "Current fixture evidence for ${id}"\n    verification:\n${refs.map((ref) => `      - kind: integration\n        ref: "${ref}"\n        status: pass\n`).join("")}    human_judgment: false`).join("\n");
  write(root, `.planning/milestones/fixture-phases/${PHASE_SLUG}/252-10-SUMMARY.md`, `---\nstatus: complete\ncompleted: 2026-10-27\nhuman_judgment: false\ncoverage:\n${currentSummaryCoverage}\n---\n`);

  return { root, phaseDir, resultsPath, renderPath, manifestDigest, rows };
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
    assert.deepEqual(evidence.unresolved_prohibitions, []);
    assert.equal(evidence.prohibition_evidence.length, 2);
    assert.ok(evidence.prohibition_evidence.every((item) => item.status === "green" && item.flagged === false && item.evidence_refs.length === 5));
    assert.equal(evidence.human_judgment, false);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("resolved transparency descriptors require live target assertions and fresh controls", () => {
  const fixture = createFixture();
  try {
    const descriptors = [
      ["252-01-PLAN.md", "The review lab must not be presented as a production operations console or evidence of completed billing actions.", "scripts/ci/verify_phase252_lab_presentation.test.mjs", "scripts/ci/fixtures/phase252-transparency/lab-violation.json", "scripts/ci/fixtures/phase252-transparency/lab-clean.json"],
      ["252-04-PLAN.md", "Held-out adversarial scenarios must not be presented as representative customer behavior or evidence of real adopter usage.", "scripts/ci/verify_phase252_heldout_attribution.test.mjs", "scripts/ci/fixtures/phase252-transparency/heldout-violation.json", "scripts/ci/fixtures/phase252-transparency/heldout-clean.json"],
    ];
    for (const [filename, statement, target, violation, clean] of descriptors) {
      const absolute = path.join(fixture.phaseDir, filename);
      const source = fs.readFileSync(absolute, "utf8");
      const resolved = `prohibitions:\n  - statement: "${statement}"\n    category: transparency\n    status: resolved\n    verification: test\n    resolution: "Bounded by ${target} with fresh clean and violation controls."\n    check_kind: node-test\n    check_target: ${target}\n    check_violation_fixture: ${violation}\n    check_clean_fixture: ${clean}\n`;
      fs.writeFileSync(absolute, source.replace(/prohibitions:\n[\s\S]*?(?=---\n)/, resolved));
    }
    const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
    fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    const evidence = validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath });
    assert.equal(evidence.prohibition_evidence.length, 2);
    assert.equal(evidence.unresolved_prohibitions.length, 0);
    assert.ok(evidence.prohibition_evidence.every((item) => item.status === "green" && item.flagged === false));
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("prohibition descriptors reject unresolved, partial, nested, changed, and swapped metadata", () => {
  const mutations = [
    (source) => source.replace(/(?=---\n$)/, "  - status: unresolved\n"),
    (source) => source.replace("status: resolved", "status: unresolved"),
    (source) => source.replace("category: transparency", "category: marketing"),
    (source) => source.replace("verification: test", "verification: manual"),
    (source) => source.replace(/    check_clean_fixture:.*\n/, ""),
    (source) => source.replace("    check_kind: node-test", "    check:\n      kind: node-test"),
    (source) => source.replace("review lab must not be presented", "review lab may be presented"),
    (source) => source.replace("check_target: scripts/ci/verify_phase252_lab_presentation.test.mjs", "check_target: scripts/ci/verify_phase252_heldout_attribution.test.mjs"),
    (source) => source.replace("check_violation_fixture: scripts/ci/fixtures/phase252-transparency/lab-violation.json", "check_violation_fixture: scripts/ci/fixtures/phase252-transparency/lab-clean.json"),
    (source) => source.replace(/prohibitions:\n[\s\S]*?(?=---\n)/, ""),
  ];
  for (const mutate of mutations) {
    const fixture = createFixture();
    try {
      const path01 = path.join(fixture.phaseDir, "252-01-PLAN.md");
      const original = fs.readFileSync(path01, "utf8");
      fs.writeFileSync(path01, mutate(original));
      refreshSourceDigest(fixture, `.planning/phases/${PHASE_SLUG}/252-01-PLAN.md`);
      assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /prohibition/i);
    } finally {
      fs.rmSync(fixture.root, { recursive: true, force: true });
    }
  }
});

test("fresh descriptor digests do not bless poisoned fixtures or absent transparency controls", () => {
  const poisoned = createFixture();
  try {
    const relative = "scripts/ci/fixtures/phase252-transparency/lab-violation.json";
    const absolute = path.join(poisoned.root, relative);
    const subject = JSON.parse(fs.readFileSync(absolute, "utf8"));
    subject.guide.text = subject.guide.text.replace("The review lab is a production operations console.", "The review lab is a static review surface.");
    fs.writeFileSync(absolute, JSON.stringify(subject, null, 2) + "\n");
    refreshSourceDigest(poisoned, relative);
    assert.throws(() => validatePhase252Evidence({ root: poisoned.root, resultsPath: poisoned.resultsPath }), /intended contradictory claim/i);
  } finally {
    fs.rmSync(poisoned.root, { recursive: true, force: true });
  }

  const disclaimer = createFixture();
  try {
    const relative = "scripts/ci/fixtures/phase252-transparency/lab-violation.json";
    const absolute = path.join(disclaimer.root, relative);
    const subject = JSON.parse(fs.readFileSync(absolute, "utf8"));
    subject.guide.text = subject.guide.text.replace("Rendered controls do not establish completed billing actions.", "");
    fs.writeFileSync(absolute, JSON.stringify(subject, null, 2) + "\n");
    refreshSourceDigest(disclaimer, relative);
    assert.throws(() => validatePhase252Evidence({ root: disclaimer.root, resultsPath: disclaimer.resultsPath }), /beside the original limiting disclaimer/i);
  } finally {
    fs.rmSync(disclaimer.root, { recursive: true, force: true });
  }

  for (const relative of [`.planning/phases/${PHASE_SLUG}/252-01-PLAN.md`, `.planning/phases/${PHASE_SLUG}/252-09-PLAN.md`, `.planning/phases/${PHASE_SLUG}/252-10-PLAN.md`, `.planning/phases/${PHASE_SLUG}/252-VALIDATION.md`, "guides/ui-story-lab.md"]) {
    const stale = createFixture();
    try {
      const absolute = relative.startsWith(".planning/")
        ? path.join(stale.phaseDir, path.basename(relative))
        : path.join(stale.root, relative);
      fs.appendFileSync(absolute, "stale digest fixture mutation\n");
      assert.throws(() => validatePhase252Evidence({ root: stale.root, resultsPath: stale.resultsPath }), /stale or invalid|source digest/i);
    } finally {
      fs.rmSync(stale.root, { recursive: true, force: true });
    }
  }

  const missingClean = createFixture();
  try {
    fs.unlinkSync(path.join(missingClean.root, "scripts/ci/fixtures/phase252-transparency/lab-clean.json"));
    assert.throws(() => validatePhase252Evidence({ root: missingClean.root, resultsPath: missingClean.resultsPath }), /does not exist|missing/i);
  } finally {
    fs.rmSync(missingClean.root, { recursive: true, force: true });
  }

  const missingMarker = createFixture();
  try {
    rewriteFixtureCommandOutput(missingMarker, "transparency-controls", (output) => output.replace("PHASE252_ASSERTION=lab_static_clean_green\n", ""));
    assert.throws(() => validatePhase252Evidence({ root: missingMarker.root, resultsPath: missingMarker.resultsPath }), /assertion definitions mismatch|missing.*marker|reporter evidence/i);
  } finally {
    fs.rmSync(missingMarker.root, { recursive: true, force: true });
  }

  const skippedTarget = createFixture();
  try {
    rewriteFixtureCommandOutput(skippedTarget, "lab-presentation", (output) => output.replace(/^ok (\d+) - lab presentation states disposable static limits$/m, "ok $1 - lab presentation states disposable static limits # SKIP skipped target"));
    assert.throws(() => validatePhase252Evidence({ root: skippedTarget.root, resultsPath: skippedTarget.resultsPath }), /skipped or marked TODO/i);
  } finally {
    fs.rmSync(skippedTarget.root, { recursive: true, force: true });
  }

  const excludedTarget = createFixture();
  try {
    rewriteFixtureCommandOutput(excludedTarget, "heldout-attribution", (output) => {
      let lines = output.split("\n");
      const removed = lines.findIndex((line) => line.includes("held-out attribution identifies synthetic stress evidence"));
      lines.splice(removed, 1);
      const count = Number(lines.find((line) => /^1\.\.\d+$/.test(line)).slice(3)) - 1;
      return lines.map((line) => line.replace(/^1\.\.\d+$/, `1..${count}`).replace(/^# tests \d+$/, `# tests ${count}`).replace(/^# pass \d+$/, `# pass ${count}`)).join("\n");
    });
    assert.throws(() => validatePhase252Evidence({ root: excludedTarget.root, resultsPath: excludedTarget.resultsPath }), /executed test identities mismatch|excluded|assertion definitions mismatch|TAP test numbering/i);
  } finally {
    fs.rmSync(excludedTarget.root, { recursive: true, force: true });
  }

  const missingLane = createFixture();
  try {
    const bundle = JSON.parse(fs.readFileSync(missingLane.resultsPath, "utf8"));
    bundle.commands = bundle.commands.filter((row) => row.id !== "transparency-controls");
    fs.writeFileSync(missingLane.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    assert.throws(() => validatePhase252Evidence({ root: missingLane.root, resultsPath: missingLane.resultsPath }), /required command IDs mismatch/i);
  } finally {
    fs.rmSync(missingLane.root, { recursive: true, force: true });
  }
});

test("behavior validation works without the final summary and current UAT owns active evidence", () => {
  const fixture = createFixture();
  try {
    const summary10 = path.join(fixture.phaseDir, "252-10-SUMMARY.md");
    const summarySource = fs.readFileSync(summary10, "utf8");
    fs.unlinkSync(summary10);
    assert.equal(validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }).status, "passed");
    assert.throws(() => generatePhase252Acceptance({ root: fixture.root, resultsPath: fixture.resultsPath, writeUat: true }), /252-10-SUMMARY|does not exist|not found/i);
    fs.writeFileSync(summary10, summarySource);

    const activeDirectory = path.join(fixture.root, ".planning", "phases", PHASE_SLUG);
    fs.mkdirSync(activeDirectory, { recursive: true });
    for (let number = 1; number <= 10; number += 1) {
      const suffixes = ["PLAN.md", "SUMMARY.md"];
      for (const suffix of suffixes) {
        const filename = `252-${String(number).padStart(2, "0")}-${suffix}`;
        fs.copyFileSync(path.join(fixture.phaseDir, filename), path.join(activeDirectory, filename));
      }
    }
    fs.copyFileSync(path.join(fixture.phaseDir, "252-VALIDATION.md"), path.join(activeDirectory, "252-VALIDATION.md"));
    fs.appendFileSync(path.join(fixture.phaseDir, "252-01-PLAN.md"), "\narchive-only mutation is shadowed by the active artifact\n");
    assert.equal(validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }).status, "passed");
    const result = generatePhase252Acceptance({ root: fixture.root, resultsPath: fixture.resultsPath, writeUat: true });
    assert.equal(result.uat_written, true);
    assert.ok(result.uat_path.endsWith("/252-UAT.md"));
    assert.match(fs.readFileSync(path.join(activeDirectory, "252-UAT.md"), "utf8"), /PROH-LAB-PRESENTATION/);
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
    const renderPath = assetFixture.renderPath;
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
    const renderPath = fixture.renderPath;
    const render = JSON.parse(fs.readFileSync(renderPath, "utf8"));
    render.cases = render.cases.filter((row) => row.key !== "/components/subscription_detail||active::320::light");
    fs.writeFileSync(renderPath, JSON.stringify(render, null, 2) + "\n");
    const bundle = JSON.parse(fs.readFileSync(fixture.resultsPath, "utf8"));
    bundle.browser_results_sha256 = digest(fs.readFileSync(renderPath));
    fs.writeFileSync(fixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    // The expectation derives from the ledger (frozen 15 minus retired); 15 stays the frozen-baseline positive control.
    const derivedTotal = expectedPhase252Cells(JSON.parse(fs.readFileSync(path.join(fixture.root, LEDGER_PATH), "utf8"))).total;
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), new RegExp(`exactly ${derivedTotal}|omitted canonical cell|all ${derivedTotal} rendered result rows`, "i"));
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }

  for (const mutate of [
    (render) => { delete render.ui_predicate_coverage["UI-E1-error"]; },
    (_render, bundle) => { bundle.commands.find((row) => row.id === "manifest-contract").assertion_refs = []; },
  ]) {
    const missing = createFixture();
    try {
      const renderPath = missing.renderPath;
      const render = JSON.parse(fs.readFileSync(renderPath, "utf8"));
      const bundle = JSON.parse(fs.readFileSync(missing.resultsPath, "utf8"));
      mutate(render, bundle);
      fs.writeFileSync(renderPath, JSON.stringify(render, null, 2) + "\n");
      bundle.browser_results_sha256 = digest(fs.readFileSync(renderPath));
      fs.writeFileSync(missing.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
      assert.throws(() => validatePhase252Evidence({ root: missing.root, resultsPath: missing.resultsPath }), /UI predicate|missing assertion evidence|EDGE-SBK-01|no assertion references|no executed assertion references/);
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

test("TAP reporter accepts complete executed records and ignores unrelated compile wording", () => {
  const testFiles = ["scripts/dev/phase252_lab.test.mjs"];
  const identities = expectedNodeTestIdentities(repositoryRoot, testFiles);
  const output = `compile note: optional fixture skip behavior is documented\n${nodeTapReport(identities)}`;
  const evidence = deriveExecutionEvidence({
    root: repositoryRoot,
    commandId: "phase252-lab-contract",
    stdout: output,
    expectedAssertions: ["owned_resource_identity", "unsafe_input_refusal", "cleanup_identity_guard", "namespace_lock_one_owner", "stale_lock_owner_refusal", "exact_process_identity_cleanup", "owned_process_group_identity"],
  });
  assert.equal(evidence.execution_evidence.test_count, identities.length);
  assert.equal(evidence.execution_evidence.skipped, 0);
  assert.equal(evidence.assertion_refs.length, 7);
});

test("TAP reporter rejects skipped required records", () => {
  assert.throws(() => parseTap13Report([
    "TAP version 13",
    "ok 1 - required identity # SKIP unavailable",
    "1..1",
    "# tests 1",
    "# pass 1",
    "# fail 0",
    "# cancelled 0",
    "# skipped 1",
    "# todo 0",
  ].join("\n"), { format: "node-tap" }), /skipped or marked TODO/i);
});

test("TAP reporter rejects missing, empty, and truncated reports", () => {
  for (const output of ["", "compile succeeded with no test process output", "TAP version 13\n1..0\n"]) {
    assert.throws(() => parseTap13Report(output, { format: "exunit-tap" }), /missing|empty|zero executed/i);
  }
  assert.throws(() => parseTap13Report("TAP version 13\nok 1 - first\n", { format: "exunit-tap" }), /plan is missing/i);
  assert.throws(() => parseTap13Report("TAP version 13\nok 1 - first\n1..2\n", { format: "exunit-tap" }), /declared 2 tests but reported 1/i);
});

test("TAP reporter rejects excluded or mismatched required identities", () => {
  const testFiles = ["scripts/dev/phase252_lab.test.mjs"];
  const identities = expectedNodeTestIdentities(repositoryRoot, testFiles);
  const assertions = ["owned_resource_identity", "unsafe_input_refusal", "cleanup_identity_guard", "namespace_lock_one_owner", "stale_lock_owner_refusal", "exact_process_identity_cleanup", "owned_process_group_identity"];
  assert.throws(() => deriveExecutionEvidence({
    root: repositoryRoot,
    commandId: "phase252-lab-contract",
    stdout: nodeTapReport(identities.slice(0, -1)),
    expectedAssertions: assertions,
  }), /executed test identities mismatch|executed count differs/i);
  const renamed = [...identities];
  renamed[0] = "fabricated test identity";
  assert.throws(() => deriveExecutionEvidence({
    root: repositoryRoot,
    commandId: "phase252-lab-contract",
    stdout: nodeTapReport(renamed),
    expectedAssertions: assertions,
  }), /executed test identities mismatch/i);
});

test("ExUnit source identities retain enclosing describe labels", () => {
  const fixtureRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase252-exunit-describe-"));
  try {
    const testFile = path.join(fixtureRoot, "test", "described_test.exs");
    fs.mkdirSync(path.dirname(testFile), { recursive: true });
    fs.writeFileSync(testFile, [
      "defmodule Example.DescribedTest do",
      "  use ExUnit.Case",
      "",
      "  describe \"outer context\" do",
      "    test \"outer case\" do",
      "      :ok",
      "    end",
      "",
      "    describe \"nested context\" do",
      "      test \"nested case\" do",
      "        :ok",
      "      end",
      "    end",
      "  end",
      "end",
      "",
    ].join("\n"));
    assert.deepEqual(expectedExUnitIdentities(fixtureRoot, ["test/described_test.exs"]), [
      "Example.DescribedTest::test outer context outer case",
      "Example.DescribedTest::test outer context nested context nested case",
    ]);
  } finally {
    fs.rmSync(fixtureRoot, { recursive: true, force: true });
  }
});

test("assertEvidenceRowCounts mutation fixtures: 15 rows fail a one-retirement ledger and 14 rows fail a frozen-only ledger", () => {
  const baseline = { entries: 6, compatibility_ids: ["braintree_pruned", "dunning_active", "populated"] };
  const frozenOnly = { frozen_baseline: baseline, records: [] };
  const oneRetired = { frozen_baseline: baseline, records: [{ disposition: "retire", subject: { story_path: SUBSCRIPTION_STORY_PATH, variation_id: "populated" } }] };
  const rows = (compatibility) => [
    ...Array.from({ length: 12 }, () => ({ case_kind: "canonical" })),
    ...Array.from({ length: compatibility }, () => ({ case_kind: "compatibility" })),
  ];
  assert.deepEqual(assertEvidenceRowCounts(rows(3), frozenOnly), { canonical: 12, compatibility: 3, total: 15 });
  assert.throws(() => assertEvidenceRowCounts(rows(2), frozenOnly), /exactly 15 rows: 12 canonical and 3 compatibility/);
  assert.deepEqual(assertEvidenceRowCounts(rows(2), oneRetired), { canonical: 12, compatibility: 2, total: 14 });
  assert.throws(() => assertEvidenceRowCounts(rows(3), oneRetired), /exactly 14 rows: 12 canonical and 2 compatibility/);
  assert.throws(() => assertEvidenceRowCounts([...rows(1), { case_kind: "canonical" }], oneRetired), /pooled or omits/);
  assert.throws(() => assertEvidenceRowCounts(rows(3), null), /cannot derive Phase 252 cell counts/);
});

function retireCompatibilityId(root, id) {
  const ledgerPath = path.join(root, LEDGER_PATH);
  const ledger = JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
  ledger.records.push({ id: "CUR-254-99", disposition: "retire", subject: { story_path: SUBSCRIPTION_STORY_PATH, variation_id: id, scenario_id: id } });
  fs.writeFileSync(ledgerPath, JSON.stringify(ledger, null, 2));
  return ledgerPath;
}

test("Phase 252 browser row counts derive from the curation ledger at the evidence validator", () => {
  const fixture = createFixture();
  try {
    // Frozen-only ledger: today's gate still demands exactly 15 rows (12 canonical + 3 compatibility).
    assert.equal(validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }).guide_contract, "passed");
    // One retired compatibility id makes the old 15 rows a mismatch.
    const ledgerPath = retireCompatibilityId(fixture.root, "populated");
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /all 14 rendered result rows|exactly 14 rows: 12 canonical and 2 compatibility/);
    // A missing ledger never defaults to a smaller number.
    fs.rmSync(ledgerPath);
    assert.throws(() => validatePhase252Evidence({ root: fixture.root, resultsPath: fixture.resultsPath }), /curation ledger is missing or unreadable/);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("the browser reporter binds assertions against ledger-derived row counts and fails closed without a ledger", () => {
  const fixture = createFixture();
  try {
    const browserResult = JSON.parse(fs.readFileSync(fixture.renderPath, "utf8"));
    const stdout = fixtureReporterOutput(fixture.root, "subscription-render-browser", browserResult.cases);
    const derive = () => deriveExecutionEvidence({
      root: fixture.root,
      commandId: "subscription-render-browser",
      stdout,
      expectedAssertions: requiredAssertionIds("subscription-render-browser"),
      browserResult,
    });
    assert.equal(derive().execution_evidence.test_count, 16, "frozen-only ledger: 15 rows plus the reconciliation test");
    const ledgerPath = retireCompatibilityId(fixture.root, "populated");
    assert.throws(derive, /all 14 rendered result rows/);
    fs.rmSync(ledgerPath);
    assert.throws(derive, /curation ledger is missing or unreadable/);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("Playwright JSON reporter requires current summary counts and every passing result", () => {
  const fixture = createFixture();
  try {
    const browserResult = JSON.parse(fs.readFileSync(fixture.renderPath, "utf8"));
    const base = JSON.parse(fixtureReporterOutput(fixture.root, "subscription-render-browser", browserResult.cases));
    const evidenceFor = (report) => deriveExecutionEvidence({
      root: fixture.root,
      commandId: "subscription-render-browser",
      stdout: JSON.stringify(report),
      expectedAssertions: requiredAssertionIds("subscription-render-browser"),
      browserResult,
    });
    const positive = evidenceFor(base);
    assert.equal(positive.execution_evidence.test_count, 16);

    const skip = structuredClone(base);
    skip.stats.skipped = 1;
    skip.suites[0].specs[0].tests[0].results[0].status = "skipped";
    assert.throws(() => evidenceFor(skip), /skipped|failed|flaky/i);

    const excluded = structuredClone(base);
    excluded.suites[0].specs.pop();
    assert.throws(() => evidenceFor(excluded), /expected 16 tests but reported 15/i);

    const missingSummary = structuredClone(base);
    delete missingSummary.stats;
    assert.throws(() => evidenceFor(missingSummary), /summary stats are missing/i);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("report assertion references bind to executed test identities", () => {
  const testFiles = ["scripts/dev/phase252_lab.test.mjs"];
  const identities = expectedNodeTestIdentities(repositoryRoot, testFiles);
  assert.throws(() => deriveExecutionEvidence({
    root: repositoryRoot,
    commandId: "phase252-lab-contract",
    stdout: nodeTapReport(identities),
    expectedAssertions: ["fake_asserted_behavior"],
  }), /assertion definitions mismatch/i);
  const legitimate = deriveExecutionEvidence({
    root: repositoryRoot,
    commandId: "phase252-lab-contract",
    stdout: nodeTapReport(identities),
    expectedAssertions: ["owned_resource_identity", "unsafe_input_refusal", "cleanup_identity_guard", "namespace_lock_one_owner", "stale_lock_owner_refusal", "exact_process_identity_cleanup", "owned_process_group_identity"],
  });
  assert.ok(Object.values(legitimate.execution_evidence.assertion_bindings).every((ids) => ids.length > 0));
});

test("acceptance generator re-parses reporter logs after their digests are updated", () => {
  const skipFixture = createFixture();
  try {
    rewriteFixtureCommandOutput(skipFixture, "phase252-lab-contract", (output) =>
      output.replace(/^ok 1 - (.+)$/m, "ok 1 - $1 # SKIP excluded by mutation"));
    assert.throws(() => validatePhase252Evidence({ root: skipFixture.root, resultsPath: skipFixture.resultsPath }), /was skipped or marked TODO/i);
  } finally {
    fs.rmSync(skipFixture.root, { recursive: true, force: true });
  }

  const excludedFixture = createFixture();
  try {
    rewriteFixtureCommandOutput(excludedFixture, "phase252-lab-contract", (output) => {
      let lines = output.split("\n");
      const records = lines.map((line, index) => ({ line, index })).filter(({ line }) => /^ok \d+ - /.test(line));
      const removed = records.at(-1);
      lines.splice(removed.index, 1);
      const remaining = records.length - 1;
      lines = lines.map((line) => line.replace(/^1\.\.\d+$/, `1..${remaining}`).replace(/^# tests \d+$/, `# tests ${remaining}`).replace(/^# pass \d+$/, `# pass ${remaining}`));
      return lines.join("\n");
    });
    assert.throws(() => validatePhase252Evidence({ root: excludedFixture.root, resultsPath: excludedFixture.resultsPath }), /executed test identities mismatch|executed count differs/i);
  } finally {
    fs.rmSync(excludedFixture.root, { recursive: true, force: true });
  }

  const emptyFixture = createFixture();
  try {
    rewriteFixtureCommandOutput(emptyFixture, "scenario-domain", () => "");
    assert.throws(() => validatePhase252Evidence({ root: emptyFixture.root, resultsPath: emptyFixture.resultsPath }), /missing or empty/i);
  } finally {
    fs.rmSync(emptyFixture.root, { recursive: true, force: true });
  }

  const fakeRefFixture = createFixture();
  try {
    const bundle = JSON.parse(fs.readFileSync(fakeRefFixture.resultsPath, "utf8"));
    bundle.commands.find((row) => row.id === "scenario-domain").assertion_refs = ["fake_asserted_behavior"];
    fs.writeFileSync(fakeRefFixture.resultsPath, JSON.stringify(bundle, null, 2) + "\n");
    assert.throws(() => validatePhase252Evidence({ root: fakeRefFixture.root, resultsPath: fakeRefFixture.resultsPath }), /assertion references or reporter records differ/i);
  } finally {
    fs.rmSync(fakeRefFixture.root, { recursive: true, force: true });
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
    assert.deepEqual(result.evidence.unresolved_prohibitions, []);
    assert.equal(result.evidence.prohibition_evidence.length, 2);
  } finally {
    fs.rmSync(fixture.root, { recursive: true, force: true });
  }
});

test("current source metadata validates before the full aggregate runs", () => {
  const metadata = validateCurrentPhase252Metadata({ root: repositoryRoot });
  assert.equal(metadata.status, "metadata_passed");
  assert.deepEqual({
    requirements: metadata.requirements,
    tasks: metadata.tasks,
    classified_edges: metadata.classified_edges,
    unclassified_assumptions: metadata.unclassified_assumptions,
    ui_predicates: metadata.ui_predicates,
  }, {
    requirements: 10,
    tasks: 8,
    classified_edges: 13,
    unclassified_assumptions: 4,
    ui_predicates: 20,
  });
  assert.deepEqual(metadata.prohibitions.map(({ id, target }) => [id, target]), [
    ["PROH-LAB-PRESENTATION", "scripts/ci/verify_phase252_lab_presentation.test.mjs"],
    ["PROH-HELDOUT-ATTRIBUTION", "scripts/ci/verify_phase252_heldout_attribution.test.mjs"],
  ]);
  for (const prohibition of metadata.prohibitions) {
    assert.ok(prohibition.resolution.includes(prohibition.target));
  }
});
