#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { isDeepStrictEqual } from "node:util";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { sharedAdminBuildPath } from "./phase252_paths.mjs";
import {
  expectedExUnitIdentities,
  expectedNodeTestIdentities,
  parseTap13Report,
} from "./phase252_reporters.mjs";

const require = createRequire(import.meta.url);
const browserHelpers = require("../../accrue_admin/e2e/phase253-composition-helpers.js");
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const RESULT_ROOT = "accrue_admin/tmp/phase253/ci-results";
const MANIFEST_PATH = "accrue_admin/tmp/phase253/manifest.json";
const TRACKED_PHASE252_MANIFEST = "storybook/phase252-manifest.json";
const BROWSER_RESULT_ROOT = "accrue_admin/tmp/phase253";
const PHASE_SLUG = "253-real-groups-and-a-whole-subscription-job";
const ADMIN = "accrue_admin/test/accrue_admin/";
const PHASE_METADATA = Object.freeze([
  ...Array.from({ length: 6 }, (_, index) => ".planning/phases/" + PHASE_SLUG + "/253-" + String(index + 1).padStart(2, "0") + "-PLAN.md"),
  ...Array.from({ length: 5 }, (_, index) => ".planning/phases/" + PHASE_SLUG + "/253-" + String(index + 1).padStart(2, "0") + "-SUMMARY.md"),
  ".planning/phases/" + PHASE_SLUG + "/253-CONTEXT.md",
  ".planning/phases/" + PHASE_SLUG + "/253-RESEARCH.md",
  ".planning/phases/" + PHASE_SLUG + "/253-PATTERNS.md",
  ".planning/phases/" + PHASE_SLUG + "/253-UI-SPEC.md",
  ".planning/phases/" + PHASE_SLUG + "/253-VALIDATION.md",
  ".planning/REQUIREMENTS.md",
]);
const COMMON_SOURCES = Object.freeze([
  ".github/workflows/ci.yml",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/storybook/_support/subscription_manifest.ex",
  "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
  "guides/subscription-story-coverage.md",
  "scripts/ci/verify_phase253_compositions.mjs",
  "scripts/ci/verify_phase253_compositions.test.mjs",
  "scripts/ci/phase252_reporters.mjs",
  "scripts/ci/phase252_paths.mjs",
  "scripts/ci/phase_evidence_path.mjs",
  "scripts/ci/verify_phase252_stories.mjs",
  "scripts/ci/verify_phase252_ci_contract.test.mjs",
  "scripts/ci/verify_phase252_transparency.mjs",
  "scripts/ci/verify_phase253_presentation.test.mjs",
  "scripts/ci/generate_phase253_acceptance.mjs",
  "scripts/ci/generate_phase253_acceptance.test.mjs",
  ".planning/phases/252-production-backed-subscription-stories/252-08-SUMMARY.md",
  "scripts/ci/verify_phase200_admin_guardrails.sh",
  "scripts/ci/verify_phase200_guardrail_contract.sh",
  "scripts/dev/phase252_lab.mjs",
  "storybook/phase252-manifest.json",
  "accrue_admin/playwright.phase252.config.js",
  "accrue_admin/e2e/phase253-composition-helpers.js",
  "accrue_admin/e2e/phase254-result-ledger.js",
  "accrue_admin/e2e/phase253-cell-universe.js",
  "accrue_admin/e2e/phase254-selection-invariants.js",
  "accrue_admin/e2e/subscription-compositions-phase253.spec.js",
  "accrue_admin/e2e/subscription-compositions-reconcile-phase254.spec.js",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/storybook.css",
  "accrue_admin/priv/static/storybook.js",
]);

const COLLECTION_ASSERTIONS = Object.freeze([
  "compiled_direct_route",
  "ordered_collection_content",
  "source_facts_and_state_controls",
  "theme_and_served_asset_identity",
  "no_hidden_essential_or_page_overflow",
]);
const COLLECTION_BREAKPOINT_ASSERTIONS = Object.freeze([
  ...COLLECTION_ASSERTIONS,
  "actual_767_768_card_table_transition",
  "table_local_scroll_is_separate",
]);
const COLLECTION_FILTERED_EMPTY_BREAKPOINT_ASSERTIONS = Object.freeze([
  ...COLLECTION_ASSERTIONS,
  "filtered_empty_is_visible_without_inventing_empty_table_or_cards",
]);
const COLLECTION_STRESS_ASSERTIONS = Object.freeze([
  "synthetic_name_and_id_wrap",
  "filter_value_remains_text_without_page_overflow",
  "essential_actions_remain_available",
]);
const GEOMETRY_ASSERTIONS = Object.freeze([
  "hidden_essential_control_is_detected",
  "page_overflow_control_is_detected",
  "restored_actual_layout_passes",
]);
const PAGE_ASSERTIONS = Object.freeze([
  "compiled_direct_whole_page_route",
  "production_source_identity_and_fact_content",
  "exact_ids_amount_caveats_state_and_destinations",
  "native_disclosures_activity_and_related_links",
  "theme_and_served_asset_identity",
  "no_hidden_essential_content_or_page_overflow",
]);
const PAGE_STRESS_ASSERTIONS = Object.freeze([
  ...PAGE_ASSERTIONS,
  "long_source_preserving_synthetic_stress_is_visible_and_unclipped",
]);
const RECONCILIATION_TITLE = browserHelpers.BROWSER_RECONCILIATION_TITLE;
const EXPECTED_ASSET_PATHS = Object.freeze([
  "accrue_admin/priv/static/storybook.css",
  "accrue_admin/priv/static/storybook.js",
]);

const ASSERTION_BINDINGS = Object.freeze({
  "phase253-manifest-contract": Object.freeze({
    collection_manifest_identity: ["compiled one_row identity resolves to the mounted collection story and current transport"],
    ten_collection_variations: ["compiled collection inventory exposes every direct variation for responsive evidence"],
    nine_page_variations: ["compiled whole-page story declares every direct production-rendered variation"],
    source_digest_and_negative_controls: ["manifest write verifies current source digests and keeps task 1 transport provenance", "duplicate identity, missing one_row, and empty declarations fail closed"],
  }),
  "phase253-page-slice": Object.freeze({
    shared_production_page_renderer: ["production owner exposes the shared whole subscription page renderer"],
    full_page_states: ["canonical whole-page variations retain the active cancellation and incomplete facts", "review, step-up, dispatch and results retain production copy and safe status semantics"],
    related_resource_omission: ["lazy disclosures and zero, one, and many related/item groups follow production omission rules"],
  }),
  "phase253-story-slice": Object.freeze({
    active_production_story: ["declared active variation renders the production area from real facts without Repo"],
    story_input_validation: ["absent, malformed, or unrecognized story input is rejected", "all canonical lifecycle variations delegate to the shared production area"],
  }),
  "phase253-collection-live": Object.freeze({
    collection_transport: ["page-boundary Storybook route renders one row and the real continuation control", "production route uses the scoped Subscriptions query despite query-module input"],
    cursor_and_owner_boundary: ["EDGE-SBK-04-boundary and adjacency preserve scoped equal-sort pages at 24, 25, and 26 rows"],
    datatable_recovery_and_accessibility: ["loads additional rows via opaque cursor pagination", "load-more failure keeps loaded rows and retry loads the failed page"],
    collection_state_projection: ["distinguishes populated, first-run-empty, filtered-empty, queue-empty, and loading states"],
  }),
  "phase253-mounted-job-live": Object.freeze({
    end_to_end_job_and_inert_dismissals: ["scoped list to reviewed cancellation returns with filters after two inert dismissals"],
    mounted_authority_and_freshness: ["subscription loader denies rows outside the active organization", "confirmation rejects a changed actor and owner after review"],
    action_effect_and_safe_return: ["drawer-hosted destructive action preserves step-up and records admin audit linkage", "untrusted return origins preserve only allowed filters inside current organization scope"],
  }),
  "phase253-presentation-contract": Object.freeze({
    current_and_clean_source_identity: ["Phase253 current source and manifest identity is exact"],
    malformed_and_missing_subject_rejection: ["Phase253 subject and enumerated sources fail closed when malformed, missing, or empty"],
  }),
  "phase253-ci-contract": Object.freeze({
    new_root_admission: ["every newly consumed Phase 253 source class maps to the named required CI owner"],
    required_owner_execution: ["the named required owner invokes both Phase 252 and Phase 253 checks"],
    unrelated_path_negative_control: ["unrelated docs are not focused while unconditional required CI still admits them"],
  }),
  // Phase 254 UXQ-04 (D-35): the reviewed correction batch runs in this required owner. The copy
  // lane is the DR-254-05 owner test (db-free); the design lane is the computed/source design spec.
  "phase254-action-copy": Object.freeze({
    result_link_label_owner: ["DR-254-05 label owner"],
    result_link_href_owner: ["DR-254-05 href owner"],
    result_link_rendered_from_owners: ["DR-254-05 rendered result"],
    production_and_story_call_owners: ["DR-254-05 production callers"],
    label_literal_has_one_owner: ["DR-254-05 literal guard"],
  }),
  "phase254-design-browser": Object.freeze({
    detail_spacing_uses_component_tokens: ["DR-254-01:computed"],
    heading_contract_declared_literals: ["DR-254-02:source"],
    heading_responsive_at_767_and_768: ["DR-254-02:computed"],
    detail_field_labels_equal_summary_keys: ["DR-254-03:computed"],
  }),
  "phase253-acceptance-contract": Object.freeze({
    complete_phase_mapping: ["acceptance requires all five requirements, fourteen tasks, ten edges, and twenty-six UI criteria"],
    unresolved_assumptions_preserved: ["current and historical unclassified assumptions remain unresolved"],
    native_prohibition_projection: ["both project prohibitions require native clean and independent violation descriptors"],
    premature_uat_rejected: ["acceptance UAT generation requires every completed summary"],
  }),
});

const REQUIRED_ASSERTION_IDS = Object.freeze({
  "phase253-ci-contract": Object.freeze([
    "new_root_admission",
    "required_owner_execution",
    "unrelated_path_negative_control",
  ]),
});

const PROCESS_MARKERS = Object.freeze({
  "phase253-transparency-controls": Object.freeze([
    "phase253_current_green",
    "phase253_clean_green",
    "phase253_static_violation_red",
    "phase253_synthetic_violation_red",
  ]),
});

const REQUIRED_COMMAND_IDS = Object.freeze([
  "phase253-manifest-contract",
  "phase253-page-slice",
  "phase253-story-slice",
  "phase253-collection-live",
  "phase253-mounted-job-live",
  "phase253-compositions-browser",
  "phase253-presentation-contract",
  "phase253-transparency-controls",
  "phase253-ci-contract",
  "phase253-acceptance-contract",
  "phase254-action-copy",
  "phase254-design-browser",
]);

// Phase 254 UXQ-04: exact per-key test counts of the design spec (4 widths/themes per computed key,
// one served-stylesheet source test). A key losing or gaining a test is a source-bound change.
export const DESIGN_SPEC_TEST_COUNTS = Object.freeze({
  "DR-254-01:computed": 4,
  "DR-254-02:computed": 4,
  "DR-254-02:source": 1,
  "DR-254-03:computed": 4,
});
export const DESIGN_PROJECT = "phase254-design";

function fail(message) {
  throw new Error("Phase 253 composition evidence: " + message);
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function uniqueSorted(values) {
  return [...new Set(values)].sort();
}

function exactSet(actual, expected, label) {
  const left = uniqueSorted(actual);
  const right = uniqueSorted(expected);
  if (left.length !== actual.length || right.length !== expected.length || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(label + " mismatch; expected " + right.length + " unique values and received " + left.length);
  }
}

function safeRepoPath(root, relativePath) {
  if (typeof relativePath !== "string" || relativePath.length === 0 || path.isAbsolute(relativePath)) {
    fail("source path must be a nonempty repository-relative path");
  }
  const absolute = path.resolve(root, relativePath);
  const relative = path.relative(root, absolute);
  if (relative === ".." || relative.startsWith(".." + path.sep) || path.isAbsolute(relative)) {
    fail("source path escaped the repository: " + relativePath);
  }
  return absolute;
}

export function fileDigest(root, relativePath) {
  const absolute = safeRepoPath(root, relativePath);
  if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) {
    fail("required source is missing: " + relativePath);
  }
  return sha256(fs.readFileSync(absolute));
}

export function sourceSnapshot(root, sources) {
  if (!Array.isArray(sources) || sources.length === 0) fail("source snapshot requires a finite path inventory");
  const paths = uniqueSorted(sources);
  if (paths.length !== sources.length) fail("source snapshot inventory contains duplicate paths");
  const digests = Object.fromEntries(paths.map((relativePath) => [relativePath, fileDigest(root, relativePath)]));
  return { paths, digests, fingerprint: sha256(JSON.stringify(digests)) };
}

function freshPartition(used) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const value = String(crypto.randomInt(100_000_000, 999_999_999));
    if (!used.has(value)) {
      used.add(value);
      return value;
    }
  }
  fail("could not allocate unique disposable Phase 253 database partitions");
}

function mixBuildPath(runId) {
  const userId = typeof process.getuid === "function" ? process.getuid() : "local";
  const shared = sharedAdminBuildPath({ tempRoot: fs.realpathSync(os.tmpdir()), userId: String(userId) });
  if (shared) return shared;
  return path.join(fs.realpathSync(os.tmpdir()), "accrue-phase253-" + userId, runId, "mix-build", "accrue-admin");
}

function testSourcePaths(testFiles) {
  return testFiles.map((file) => file.startsWith("accrue_admin/") ? file : "accrue_admin/" + file);
}

function command(id, display, executable, args, options = {}) {
  return {
    id,
    display,
    executable,
    args,
    cwd: options.cwd || ".",
    lane: options.lane || "read-only",
    partition: options.partition || null,
    sources: uniqueSorted(options.sources || []),
    reporter: options.reporter,
    assertion_bindings: options.assertion_bindings || {},
    process_markers: options.process_markers || [],
    browser_contract: options.browser_contract || null,
    env: options.env || {},
  };
}

// Phase 254 CIQ-02 (D-13, D-24 step 3): the composition cells are pure-story (the review lane
// refuses reset and seed with 403 and every cell writes its own result file), so they may run on
// bounded Playwright workers against the one lab server. 1 is the unchanged serial run; the
// guardrail runner sets PHASE254_COMPOSITION_WORKERS. Reconciliation stays a dependent project.
export const MAX_COMPOSITION_WORKERS = 4;

export function resolveCompositionWorkers(env = process.env) {
  const raw = env.PHASE254_COMPOSITION_WORKERS;
  if (raw === undefined || raw === "") return 1;
  if (!/^[1-9]\d*$/.test(raw) || Number(raw) > MAX_COMPOSITION_WORKERS) {
    fail("PHASE254_COMPOSITION_WORKERS must be an integer from 1 to " + MAX_COMPOSITION_WORKERS);
  }
  return Number(raw);
}

export function buildCommandPlan({ id, adminBuildPath, outputDirectory, browserWorkers = 1 }) {
  if (!Number.isInteger(browserWorkers) || browserWorkers < 1 || browserWorkers > MAX_COMPOSITION_WORKERS) {
    fail("browser workers must be an integer from 1 to " + MAX_COMPOSITION_WORKERS);
  }
  if (typeof id !== "string" || !/^[a-f0-9]{24,64}$/i.test(id)) fail("runner ID must be a fresh 24-64 character hexadecimal nonce");
  if (!adminBuildPath || !outputDirectory) fail("command plan requires run-specific build and output paths");
  const usedPartitions = new Set();
  const tapArgs = (testFile) => ["--test", "--test-reporter=tap", testFile];
  const exunitNoStart = (testId, testFile, cwdFile, assertions, extraSources = []) => command(
    testId,
    "MIX_ENV=test mix run --no-start",
    "mix",
    ["run", "--no-start", cwdFile],
    {
      cwd: "accrue_admin",
      lane: "db-free",
      sources: [testFile, "accrue_admin/test/test_helper.exs", "dev_support/phase252_tap_formatter.ex", ...extraSources],
      reporter: { kind: "exunit-tap", testFiles: [testFile] },
      assertion_bindings: assertions,
      env: { MIX_ENV: "test", MIX_BUILD_PATH: adminBuildPath, PHASE252_TAP_REPORT: "1" },
    },
  );
  const adminTest = (testId, testFiles, assertions) => {
    const partition = freshPartition(usedPartitions);
    const mixFiles = testFiles.map((file) => file.replace(/^accrue_admin\//, ""));
    const shell = "cd accrue_admin && MIX_ENV=test mix test " + mixFiles.join(" ");
    return command(
      testId,
      "node scripts/dev/phase252_lab.mjs exec --lane admin-test",
      process.execPath,
      ["scripts/dev/phase252_lab.mjs", "exec", "--lane", "admin-test", "--partition", partition, "--", "sh", "-c", shell],
      {
        lane: "admin-test",
        partition,
        sources: [...testFiles, "scripts/dev/phase252_lab.mjs", "accrue_admin/test/test_helper.exs", "dev_support/phase252_tap_formatter.ex"],
        reporter: { kind: "exunit-tap", testFiles },
        assertion_bindings: assertions,
        env: { MIX_ENV: "test", MIX_BUILD_PATH: adminBuildPath, PHASE252_TAP_REPORT: "1" },
      },
    );
  };

  const browserPartition = freshPartition(usedPartitions);
  const designPartition = freshPartition(usedPartitions);
  const browserResultPath = path.join(BROWSER_RESULT_ROOT, "render-results-" + id.toLowerCase() + ".json").split(path.sep).join("/");
  const browserSources = [
    "accrue_admin/e2e/subscription-compositions-phase253.spec.js",
    "accrue_admin/e2e/subscription-compositions-reconcile-phase254.spec.js",
    "accrue_admin/e2e/phase253-composition-helpers.js",
    "accrue_admin/e2e/phase254-result-ledger.js",
    "accrue_admin/e2e/phase253-cell-universe.js",
    "accrue_admin/e2e/phase254-selection-invariants.js",
    "accrue_admin/playwright.phase252.config.js",
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
    "storybook/pages/subscription.story.exs",
    "accrue_admin/assets/css/app.css",
    "accrue_admin/priv/static/accrue_admin.css",
    "accrue_admin/priv/static/storybook.css",
    "accrue_admin/priv/static/storybook.js",
  ];
  const nodeTap = (testId, file, assertions, sources = [], testFiles = [file]) => command(
    testId,
    "node --test --test-reporter=tap",
    process.execPath,
    tapArgs(file),
    {
      lane: "read-only",
      sources: [file, ...sources],
      reporter: { kind: "node-tap", testFiles },
      assertion_bindings: assertions,
    },
  );

  const plan = [
    exunitNoStart(
      "phase253-manifest-contract",
      ADMIN + "dev/subscription_compositions_manifest_test.exs",
      "test/accrue_admin/dev/subscription_compositions_manifest_test.exs",
      ASSERTION_BINDINGS["phase253-manifest-contract"],
    ),
    exunitNoStart(
      "phase253-page-slice",
      ADMIN + "dev/subscription_page_slice_test.exs",
      "test/accrue_admin/dev/subscription_page_slice_test.exs",
      ASSERTION_BINDINGS["phase253-page-slice"],
    ),
    exunitNoStart(
      "phase253-story-slice",
      ADMIN + "dev/subscription_story_slice_test.exs",
      "test/accrue_admin/dev/subscription_story_slice_test.exs",
      ASSERTION_BINDINGS["phase253-story-slice"],
    ),
    adminTest(
      "phase253-collection-live",
      [
        ADMIN + "dev/subscription_collection_transport_test.exs",
        ADMIN + "components/data_table_test.exs",
        ADMIN + "live/subscriptions_live_test.exs",
      ],
      ASSERTION_BINDINGS["phase253-collection-live"],
    ),
    adminTest(
      "phase253-mounted-job-live",
      [
        ADMIN + "live/subscription_journey_test.exs",
        ADMIN + "live/subscription_live_test.exs",
      ],
      ASSERTION_BINDINGS["phase253-mounted-job-live"],
    ),
    command(
      "phase253-compositions-browser",
      "node scripts/dev/phase252_lab.mjs browser -- --reporter=json" + (browserWorkers > 1 ? " --workers=" + browserWorkers : "") + " e2e/subscription-compositions-phase253.spec.js e2e/subscription-compositions-reconcile-phase254.spec.js",
      process.execPath,
      [
        "scripts/dev/phase252_lab.mjs",
        "browser",
        "--partition",
        browserPartition,
        "--",
        "--reporter=json",
        ...(browserWorkers > 1 ? ["--workers=" + browserWorkers] : []),
        "e2e/subscription-compositions-phase253.spec.js",
        // Phase 254 D-13: the dependent phase254-reconcile project merges the per-case files.
        "e2e/subscription-compositions-reconcile-phase254.spec.js",
      ],
      {
        lane: "admin-review-browser",
        partition: browserPartition,
        sources: [...browserSources, "scripts/dev/phase252_lab.mjs"],
        reporter: { kind: "playwright-json" },
        assertion_bindings: {
          collection_render_cells: ["viewport", "breakpoint", "container"],
          collection_synthetic_stress: ["synthetic_text_stress"],
          geometry_negative_controls: ["geometry_negative_controls"],
          page_composition_cells: ["page_composition"],
          page_synthetic_stress: ["page_synthetic_text_stress"],
          manifest_reconciliation: ["__reconciliation__"],
        },
        browser_contract: {
          expected_cell_definitions: expectedBrowserCellDefinitionsFromHelpers,
          reconciliation_title: RECONCILIATION_TITLE,
          asset_paths: EXPECTED_ASSET_PATHS,
          assertion_ids: {
            viewport: COLLECTION_ASSERTIONS,
            breakpoint: {
              one_row: COLLECTION_BREAKPOINT_ASSERTIONS,
              filtered_empty: COLLECTION_FILTERED_EMPTY_BREAKPOINT_ASSERTIONS,
            },
            container: COLLECTION_ASSERTIONS,
            synthetic_text_stress: COLLECTION_STRESS_ASSERTIONS,
            geometry_negative_controls: GEOMETRY_ASSERTIONS,
            page_composition: PAGE_ASSERTIONS,
          page_synthetic_text_stress: PAGE_STRESS_ASSERTIONS,
          },
          result_path: browserResultPath,
        },
        env: {
          MIX_ENV: "test",
          MIX_BUILD_PATH: adminBuildPath,
          MIX_TEST_PARTITION: browserPartition,
          PHASE252_E2E_NONCE: id.toLowerCase(),
        },
      },
    ),
    nodeTap(
      "phase253-presentation-contract",
      "scripts/ci/verify_phase253_presentation.test.mjs",
      ASSERTION_BINDINGS["phase253-presentation-contract"],
      ["scripts/ci/verify_phase252_transparency.mjs", "scripts/ci/phase_evidence_path.mjs", "scripts/ci/main_module.mjs"],
      // verify_phase252_transparency.mjs now imports the shared module-boundary guard, and
      // main_module.mjs registers its own node:test cases in every importing process, so its
      // identities are part of this lane's exact inventory (same shape as phase253-ci-contract).
      ["scripts/ci/verify_phase253_presentation.test.mjs", "scripts/ci/main_module.mjs"],
    ),
    command(
      "phase253-transparency-controls",
      "node scripts/ci/verify_phase252_transparency.mjs --self-test --only compositions",
      process.execPath,
      ["scripts/ci/verify_phase252_transparency.mjs", "--self-test", "--only", "compositions"],
      {
        lane: "read-only",
        reporter: { kind: "process-markers" },
        sources: [
          "scripts/ci/verify_phase252_transparency.mjs",
          "scripts/ci/verify_phase253_presentation.test.mjs",
          "scripts/ci/fixtures/phase253-transparency/clean.json",
          "scripts/ci/fixtures/phase253-transparency/presentation-violation.json",
          "scripts/ci/fixtures/phase253-transparency/attribution-violation.json",
          "scripts/ci/phase_evidence_path.mjs",
          "scripts/ci/generate_phase253_acceptance.mjs",
          "guides/ui-story-lab.md",
          "storybook/phase252-manifest.json",
          "storybook/groups/subscriptions_collection.story.exs",
          "storybook/pages/subscription.story.exs",
          "accrue_admin/e2e/phase253-composition-helpers.js",
          "accrue_admin/e2e/subscription-compositions-phase253.spec.js",
        ],
        process_markers: PROCESS_MARKERS["phase253-transparency-controls"],
      },
    ),
    nodeTap(
      "phase253-ci-contract",
      "scripts/ci/verify_phase252_ci_contract.test.mjs",
      ASSERTION_BINDINGS["phase253-ci-contract"],
      [
        "scripts/ci/main_module.mjs",
        "scripts/ci/phase252_paths.mjs",
        "scripts/ci/verify_phase252_stories.mjs",
        "scripts/ci/phase252_reporters.mjs",
        "scripts/ci/verify_phase200_admin_guardrails.sh",
        "scripts/ci/verify_phase200_guardrail_contract.sh",
        ".github/workflows/ci.yml",
      ],
      ["scripts/ci/verify_phase252_ci_contract.test.mjs", "scripts/ci/main_module.mjs"],
    ),
    nodeTap(
      "phase253-acceptance-contract",
      "scripts/ci/generate_phase253_acceptance.test.mjs",
      ASSERTION_BINDINGS["phase253-acceptance-contract"],
      [
        "scripts/ci/generate_phase253_acceptance.mjs",
        "scripts/ci/verify_executable_uat_contract.mjs",
        "scripts/ci/phase_evidence_path.mjs",
        "scripts/ci/main_module.mjs",
      ],
      ["scripts/ci/generate_phase253_acceptance.test.mjs", "scripts/ci/main_module.mjs"],
    ),
    exunitNoStart(
      "phase254-action-copy",
      ADMIN + "dev/subscription_action_copy_test.exs",
      "test/accrue_admin/dev/subscription_action_copy_test.exs",
      ASSERTION_BINDINGS["phase254-action-copy"],
      [
        "accrue_admin/lib/accrue_admin/copy.ex",
        "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
        "accrue_admin/storybook/_support/subscription_page_scenarios.ex",
      ],
    ),
    command(
      "phase254-design-browser",
      "node scripts/dev/phase252_lab.mjs browser -- --reporter=json e2e/subscription-design-phase254.spec.js",
      process.execPath,
      [
        "scripts/dev/phase252_lab.mjs",
        "browser",
        "--partition",
        designPartition,
        "--",
        "--reporter=json",
        "e2e/subscription-design-phase254.spec.js",
      ],
      {
        lane: "admin-review-browser",
        partition: designPartition,
        sources: [
          "accrue_admin/e2e/subscription-design-phase254.spec.js",
          "accrue_admin/playwright.phase252.config.js",
          "accrue_admin/assets/css/app.css",
          "accrue_admin/assets/css/theme.css",
          "accrue_admin/priv/static/accrue_admin.css",
          "accrue_admin/priv/static/storybook.css",
          "accrue_admin/priv/static/storybook.js",
          "scripts/dev/phase252_lab.mjs",
        ],
        reporter: { kind: "playwright-titles", project: DESIGN_PROJECT, expected_counts: DESIGN_SPEC_TEST_COUNTS },
        assertion_bindings: ASSERTION_BINDINGS["phase254-design-browser"],
        env: {
          MIX_ENV: "test",
          MIX_BUILD_PATH: adminBuildPath,
          MIX_TEST_PARTITION: designPartition,
          PHASE252_E2E_NONCE: id.toLowerCase() + "-design",
        },
      },
    ),
  ];
  assertRequiredCommandPlan(plan);
  return plan;
}

function expectedBrowserCellDefinitionsFromHelpers(manifest) {
  return browserHelpers.createExpectedBrowserCellDefinitions(manifest);
}

export function expectedBrowserCellKeys(manifest) {
  return expectedBrowserCellDefinitionsFromHelpers(manifest).map(({ key }) => key);
}

export function assertRequiredCommandPlan(commands) {
  if (!Array.isArray(commands)) throw new TypeError("Phase 253 required command plan must be an array");
  const ids = commands.map((row) => row?.id);
  if (JSON.stringify(ids) !== JSON.stringify(REQUIRED_COMMAND_IDS)) {
    fail("required command plan does not exactly match the finite Phase 253 lane inventory");
  }
  const partitions = commands.filter((row) => row.lane === "admin-test" || row.lane === "admin-review-browser").map((row) => row.partition);
  if (partitions.some((value) => !/^\d{8,16}$/.test(String(value))) || new Set(partitions).size !== partitions.length) {
    fail("every mutable Phase 253 lane requires a distinct fresh numeric partition");
  }
  for (const row of commands) {
    if (!Array.isArray(row.sources) || row.sources.length === 0) fail("lane has no source inventory: " + row.id);
    if (row.reporter?.kind === "node-tap" || row.reporter?.kind === "exunit-tap") {
      if (!Array.isArray(row.reporter.testFiles) || row.reporter.testFiles.length === 0) fail("TAP lane has no exact test-file inventory: " + row.id);
      if (Object.keys(row.assertion_bindings || {}).length === 0) fail("TAP lane has no explicit assertion identity bindings: " + row.id);
    } else if (row.reporter?.kind === "playwright-json") {
      if (!row.browser_contract || !Array.isArray(row.browser_contract.asset_paths) || row.browser_contract.asset_paths.length === 0) {
        fail("browser lane has no finite cell and served-asset contract");
      }
    } else if (row.reporter?.kind === "playwright-titles") {
      if (row.reporter.project !== DESIGN_PROJECT || !isDeepStrictEqual(row.reporter.expected_counts, DESIGN_SPEC_TEST_COUNTS)) {
        fail("design browser lane has no exact project and per-key test count contract");
      }
      if (Object.keys(row.assertion_bindings || {}).length === 0) fail("design browser lane has no explicit assertion identity bindings: " + row.id);
    } else if (row.reporter?.kind !== "process-markers" || row.process_markers.length === 0) {
      fail("lane has no supported reporter contract: " + row.id);
    }
  }
  for (const [commandId, requiredAssertions] of Object.entries(REQUIRED_ASSERTION_IDS)) {
    const command = commands.find((row) => row.id === commandId);
    const actualAssertions = Object.keys(command?.assertion_bindings || {}).sort();
    if (JSON.stringify(actualAssertions) !== JSON.stringify([...requiredAssertions].sort())) {
      fail(commandId + " reporter assertion binding inventory is incomplete or unexpected");
    }
  }
  return true;
}

function matchAssertions(assertionBindings, identities, commandId) {
  if (!assertionBindings || typeof assertionBindings !== "object" || Array.isArray(assertionBindings) || Object.keys(assertionBindings).length === 0) {
    fail(commandId + " has no bounded reporter assertion bindings");
  }
  const bindings = {};
  for (const [assertionId, fragments] of Object.entries(assertionBindings)) {
    if (!Array.isArray(fragments) || fragments.length === 0 || fragments.some((fragment) => typeof fragment !== "string" || fragment.length === 0)) {
      fail(commandId + " assertion " + assertionId + " has no named reporter identity");
    }
    const matches = uniqueSorted(identities.filter((identity) => fragments.some((fragment) => identity.includes(fragment))));
    if (matches.length === 0) fail(commandId + " assertion " + assertionId + " has no matching executed reporter identity");
    bindings[assertionId] = matches;
  }
  return bindings;
}

function verifySourceIdentity(spec, execution, { expectedSourceDigests, expectedManifestDigest }) {
  if (!execution || typeof execution !== "object") fail(spec.id + " produced no command result");
  if (execution.exitCode !== 0) fail(spec.id + " command failed with exit " + String(execution.exitCode));
  if (!/^[a-f0-9]{24,64}$/i.test(String(execution.run_id || ""))) fail(spec.id + " command result has no run identity");
  if (execution.run_id !== execution.expected_run_id) fail(spec.id + " command result belongs to a different run");
  if (expectedManifestDigest && execution.manifest_sha256 !== expectedManifestDigest) {
    fail(spec.id + " command result is bound to a stale or different compiled manifest");
  }
  if (expectedSourceDigests) {
    const actual = execution.source_digests || {};
    for (const source of spec.sources) {
      if (typeof expectedSourceDigests[source] !== "string" || actual[source] !== expectedSourceDigests[source]) {
        fail(spec.id + " source digest is missing or stale: " + source);
      }
    }
  }
}

function tapReporter(spec, execution, root) {
  const format = spec.reporter.kind;
  const report = parseTap13Report(execution.stdout, { format });
  const expected = format === "node-tap"
    ? expectedNodeTestIdentities(root, spec.reporter.testFiles)
    : expectedExUnitIdentities(root, spec.reporter.testFiles);
  exactSet(report.identities, expected, spec.id + " executed test identities");
  if (report.count !== expected.length || report.skipped !== 0 || report.failed !== 0) {
    fail(spec.id + " reporter count or skip state differs from its source-bound inventory");
  }
  const assertionBindings = matchAssertions(spec.assertion_bindings, report.identities, spec.id);
  if (execution.assertion_refs != null) exactSet(execution.assertion_refs, Object.keys(assertionBindings), spec.id + " assertion references");
  return {
    kind: format,
    test_count: report.count,
    skipped: report.skipped,
    failed: report.failed,
    test_identities: report.identities,
    assertion_refs: Object.keys(assertionBindings).sort(),
    assertion_bindings: assertionBindings,
  };
}

function playrightTestIdentities(report) {
  if (!report || !Array.isArray(report.suites) || !report.stats || !Array.isArray(report.errors)) {
    fail("Playwright JSON report is missing suites, statistics, or error inventory");
  }
  if (report.status !== undefined && report.status !== "passed") fail("Playwright JSON report did not pass");
  const stats = report.stats;
  for (const field of ["expected", "unexpected", "skipped", "flaky"]) {
    if (!Number.isInteger(stats[field])) fail("Playwright report lacks integer " + field + " count");
  }
  if (stats.expected <= 0 || stats.unexpected !== 0 || stats.skipped !== 0 || stats.flaky !== 0 || report.errors.length !== 0) {
    fail("Playwright report is empty, failed, skipped, flaky, or contains global errors");
  }
  const tests = [];
  const visit = (suite) => {
    for (const item of suite.specs || []) {
      if (item.ok === false) fail("Playwright spec failed: " + String(item.title || "unnamed"));
      if (typeof item.title !== "string" || item.title.length === 0 ||
          !Array.isArray(item.tests) || item.tests.length !== 1) {
        fail("Playwright spec identity is missing or pooled across test projects");
      }
      for (const test of item.tests || []) {
        if (test.expectedStatus !== "passed" || !Array.isArray(test.results) || test.results.length !== 1 ||
            test.results[0]?.status !== "passed" || test.results[0]?.retry !== 0) {
          fail("Playwright test identity is missing, skipped, failed, or retried");
        }
        tests.push(item.title);
      }
    }
    for (const nested of suite.suites || []) visit(nested);
  };
  for (const suite of report.suites) visit(suite);
  if (tests.length !== stats.expected || tests.length === 0 || new Set(tests).size !== tests.length) {
    fail("Playwright reporter identity count is empty, duplicated, or inconsistent with summary statistics");
  }
  return tests;
}

// Phase 254 (CIQ-04): per-test durations of the passing report, kept in the lane evidence so a
// budget freeze can price one composition cell from CI evidence. Pure observation: the
// identity, pass/skip/retry/flaky gates above are unchanged.
function playwrightTestDurations(report) {
  const durations = [];
  const visit = (suite) => {
    for (const item of suite.specs || []) {
      for (const test of item.tests || []) {
        const duration = test.results?.[0]?.duration;
        durations.push({ identity: item.title, duration_ms: Number.isFinite(duration) && duration >= 0 ? duration : null });
      }
    }
    for (const nested of suite.suites || []) visit(nested);
  };
  for (const suite of report.suites) visit(suite);
  return durations;
}

// Phase 254 D-13/D-14: the reconcile test must have run as its own dependent project, and
// every cell must have run in the cells project. A reconcile title that ran anywhere else
// (or a cell that ran in the reconcile project) is not the dependent step this lane claims.
export const RECONCILE_PROJECT = "phase254-reconcile";
export const CELLS_PROJECT = "phase252-owned-review";

export function playwrightProjectsByTitle(report) {
  const byTitle = new Map();
  const visit = (suite) => {
    for (const item of suite.specs || []) {
      for (const entry of item.tests || []) byTitle.set(item.title, entry.projectName);
    }
    for (const nested of suite.suites || []) visit(nested);
  };
  for (const suite of report.suites || []) visit(suite);
  return byTitle;
}

export function assertReconcileProjectExecuted(report, reconciliationTitle) {
  const projects = playwrightProjectsByTitle(report);
  if (projects.get(reconciliationTitle) !== RECONCILE_PROJECT) {
    fail("the reconcile test did not execute in the " + RECONCILE_PROJECT + " project: " + String(projects.get(reconciliationTitle)));
  }
  for (const [title, project] of projects) {
    if (title !== reconciliationTitle && project !== CELLS_PROJECT) {
      fail("browser cell " + title + " did not execute in the " + CELLS_PROJECT + " project: " + String(project));
    }
  }
}

// Phase 254 UXQ-04: the design spec lane. The report must be a complete passing Playwright report in
// which every test ran in the phase254-design project, every title carries a DR-NNN-NN:kind key, and
// the per-key test counts equal the finite inventory. It is a source-bound count, not a cell universe.
export function validateDesignEvidence(spec, execution) {
  let report;
  try {
    report = JSON.parse(execution.stdout);
  } catch {
    fail(spec.id + " Playwright JSON reporter output is not one complete report");
  }
  const identities = playrightTestIdentities(report);
  for (const [title, project] of playwrightProjectsByTitle(report)) {
    if (project !== spec.reporter.project) fail(spec.id + " test " + title + " did not execute in the " + spec.reporter.project + " project: " + String(project));
  }
  const counts = {};
  for (const title of identities) {
    const key = /^(DR-\d{3}-\d{2}:[a-z][a-z-]*)\s/.exec(title)?.[1];
    if (!key) fail(spec.id + " test title has no DR-NNN-NN:kind key prefix: " + title);
    counts[key] = (counts[key] || 0) + 1;
  }
  if (!isDeepStrictEqual(Object.fromEntries(Object.entries(counts).sort()), Object.fromEntries(Object.entries(spec.reporter.expected_counts).sort()))) {
    fail(spec.id + " executed per-key test counts differ from the source-bound inventory: " + JSON.stringify(counts));
  }
  const assertionBindings = matchAssertions(spec.assertion_bindings, identities, spec.id);
  if (execution.assertion_refs != null) exactSet(execution.assertion_refs, Object.keys(assertionBindings), spec.id + " assertion references");
  return {
    kind: "playwright-titles",
    test_count: identities.length,
    skipped: report.stats.skipped,
    failed: report.stats.unexpected,
    test_identities: identities,
    durations: playwrightTestDurations(report),
    stats_duration_ms: Number.isFinite(report.stats.duration) ? report.stats.duration : null,
    assertion_refs: Object.keys(assertionBindings).sort(),
    assertion_bindings: assertionBindings,
  };
}

function assertExactStrings(actual, expected, label) {
  if (!Array.isArray(actual) || actual.some((item) => typeof item !== "string" || item.length === 0)) {
    fail(label + " is missing or malformed");
  }
  exactSet(actual, expected, label);
}

function validateBrowserEvidence(spec, execution, { root, expectedSourceDigests, expectedManifestDigest, browserResult, expectedBrowserCells, selection }) {
  let report;
  try {
    report = JSON.parse(execution.stdout);
  } catch {
    fail("Playwright JSON reporter output is not one complete report");
  }
  const reportIdentities = playrightTestIdentities(report);
  assertReconcileProjectExecuted(report, spec.browser_contract.reconciliation_title);
  if (!browserResult || typeof browserResult !== "object") fail("current-run browser cell bundle is missing");
  if (browserResult.run_id !== execution.run_id) fail("browser cell bundle has a different run ID");
  if (browserResult.manifest_sha256 !== expectedManifestDigest) fail("browser cell bundle has a stale manifest digest");
  if (browserResult.human_judgment !== false || browserResult.proof_lane !== "actual direct browser presentation; no mounted-effect claims") {
    fail("browser bundle has an unsupported proof or judgment classification");
  }
  const universe = expectedBrowserCells || spec.browser_contract.expected_cell_definitions(JSON.parse(fs.readFileSync(safeRepoPath(root, MANIFEST_PATH), "utf8")));
  const universeKeys = universe.map(({ key }) => key);
  if (new Set(universeKeys).size !== universeKeys.length) fail("expected browser cell inventory contains duplicate keys");
  // Phase 254 D-11/D-14: the expected set is exactly the selected set. With no selection the
  // universe is expected in full, and a result that declares an affected selection is rejected
  // (acceptance evidence is always a full sweep).
  let definitions = universe;
  if (selection) {
    const known = new Set(universeKeys);
    const unknown = selection.selected_keys.filter((key) => !known.has(key));
    if (unknown.length > 0) fail("selection names a case outside the compiled cell universe: " + unknown[0]);
    const selectedSet = new Set(selection.selected_keys);
    const excludedSet = new Set(selection.excluded_keys || []);
    const excludedRow = (browserResult.cases || []).find((row) => excludedSet.has(row?.key));
    if (excludedRow) fail("browser result has a row for an excluded case: " + String(excludedRow.key));
    if (!isDeepStrictEqual(browserResult.selection ?? null, selection.block)) {
      fail("browser result selection block differs from the selection this run was started with");
    }
    definitions = universe.filter(({ key }) => selectedSet.has(key));
  } else if (browserResult.selection && browserResult.selection.mode !== "full") {
    fail("browser result declares an affected selection; this validation requires a full sweep");
  }
  const expectedKeys = definitions.map(({ key }) => key);
  assertExactStrings(browserResult.expected_case_keys, expectedKeys, "browser declared cell inventory");
  if (!Array.isArray(browserResult.cases) || browserResult.cases.length !== expectedKeys.length) {
    fail("browser result is incomplete, pooled, or contains extra cells");
  }
  const rows = browserResult.cases;
  const rowKeys = rows.map((row) => row?.key);
  assertExactStrings(rowKeys, expectedKeys, "browser executed cell keys");
  const definitionsByKey = new Map(definitions.map((definition) => [definition.key, definition]));
  const rowTestIdentities = [];
  const rowBindings = {};
  const expectedKinds = Object.keys(spec.browser_contract.assertion_ids);
  for (const row of rows) {
    const definition = definitionsByKey.get(row.key);
    if (!definition || row.case_kind !== definition.case_kind) fail("browser cell kind does not match its finite source inventory: " + String(row.key));
    if (!browserHelpers.matchesExpectedBrowserCell(row, definition)) {
      fail("browser cell test or compiled source attribution differs from its exact definition: " + row.key);
    }
    if (row.run_id !== execution.run_id || row.manifest_sha256 !== expectedManifestDigest || row.status !== "passed") {
      fail("browser cell is failed, stale, or pooled: " + String(row.key));
    }
    if (typeof row.executed_test !== "string" || row.executed_test.length === 0 ||
        typeof row.completed_at !== "string" || row.completed_at.length === 0) {
      fail("browser cell is missing an executed test identity or completion time: " + row.key);
    }
    const assertionInventory = spec.browser_contract.assertion_ids[row.case_kind];
    const expectedAssertions = Array.isArray(assertionInventory)
      ? assertionInventory
      : assertionInventory?.[row.key.split("::")[0]];
    assertExactStrings(row.assertion_ids, expectedAssertions, "browser row assertions for " + row.key);
    if (!row.source_identity || typeof row.source_identity !== "object" || Object.values(row.source_identity).every((value) => value == null || value === "")) {
      fail("browser cell lacks compiled source identity: " + row.key);
    }
    if (!row.served_assets?.verified || !/^[a-f0-9]{64}$/.test(row.served_assets.css_sha256 || "") ||
        !/^[a-f0-9]{64}$/.test(row.served_assets.js_sha256 || "")) {
      fail("browser cell lacks verified served CSS and JavaScript identity: " + row.key);
    }
    const cssPath = "accrue_admin/priv/static/storybook.css";
    const jsPath = "accrue_admin/priv/static/storybook.js";
    if (row.served_assets.css_sha256 !== expectedSourceDigests[cssPath] ||
        row.served_assets.js_sha256 !== expectedSourceDigests[jsPath]) {
      fail("browser cell served an asset that differs from the current compiled asset bytes: " + row.key);
    }
    rowTestIdentities.push(row.executed_test);
    rowBindings[row.case_kind] ||= [];
    rowBindings[row.case_kind].push(row.executed_test);
  }
  const reconciliation = spec.browser_contract.reconciliation_title;
  exactSet(reportIdentities, [...rowTestIdentities, reconciliation], "Playwright report and executed browser cell identities");
  const assetIdentity = browserResult.source_and_asset_sha256;
  if (!assetIdentity || typeof assetIdentity !== "object" || Array.isArray(assetIdentity)) {
    fail("browser result has no source and asset digest map");
  }
  for (const asset of spec.browser_contract.asset_paths) {
    if (assetIdentity[asset] !== expectedSourceDigests[asset]) fail("browser source and served asset digest is stale: " + asset);
  }
  for (const [source, digest] of Object.entries(assetIdentity)) {
    if (expectedSourceDigests[source] !== digest) fail("browser source digest is missing, stale, or unexpected: " + source);
  }
  const geometry = rows.find((row) => row.case_kind === "geometry_negative_controls");
  if (!geometry || geometry.negative_controls?.hidden_essential_detected !== true ||
      geometry.negative_controls?.page_overflow_detected !== true) {
    fail("browser geometry negative controls were not independently detected");
  }
  const assertionBindings = {};
  const selectedKinds = new Set(definitions.map((definition) => definition.case_kind));
  for (const [assertion, kinds] of Object.entries(spec.assertion_bindings)) {
    // An affected selection may legitimately contain no cell of a kind; full mode never skips.
    if (selection?.mode === "affected" && !kinds.includes("__reconciliation__") && !kinds.some((kind) => selectedKinds.has(kind))) continue;
    const selected = kinds.includes("__reconciliation__")
      ? [reconciliation]
      : uniqueSorted(rows.filter((row) => kinds.includes(row.case_kind)).map((row) => row.executed_test));
    if (selected.length === 0 || selected.some((identity) => !reportIdentities.includes(identity))) {
      fail("browser assertion " + assertion + " has no reporter-bound cell identity");
    }
    assertionBindings[assertion] = selected;
  }
  if (execution.assertion_refs != null) exactSet(execution.assertion_refs, Object.keys(assertionBindings), "browser assertion references");
  return {
    kind: "playwright-json",
    test_count: reportIdentities.length,
    skipped: report.stats.skipped,
    failed: report.stats.unexpected,
    test_identities: reportIdentities,
    durations: playwrightTestDurations(report),
    stats_duration_ms: Number.isFinite(report.stats.duration) ? report.stats.duration : null,
    assertion_refs: Object.keys(assertionBindings).sort(),
    assertion_bindings: assertionBindings,
    browser_result_path: spec.browser_contract.result_path,
    browser_result_sha256: sha256(fs.readFileSync(safeRepoPath(root, spec.browser_contract.result_path))),
    browser_cells: rows.map((row) => ({
      key: row.key,
      case_kind: row.case_kind,
      run_id: row.run_id,
      manifest_sha256: row.manifest_sha256,
      executed_test: row.executed_test,
      status: row.status,
      completed_at: row.completed_at,
      assertion_ids: row.assertion_ids,
      source_identity: row.source_identity,
      served_assets: row.served_assets,
      viewport: row.viewport,
      theme: row.theme,
    })),
  };
}

export function validateLaneEvidence(spec, execution, options = {}) {
  const root = options.root || ROOT;
  const expectedRunId = options.expectedRunId;
  if (!spec || typeof spec.id !== "string" || !spec.reporter) fail("lane specification is missing an ID or reporter");
  if (!execution || typeof execution !== "object") fail(spec.id + " produced no command result");
  if (execution.exitCode !== 0) fail(spec.id + " command failed with exit " + String(execution.exitCode));
  if (!/^[a-f0-9]{24,64}$/i.test(String(execution.run_id || ""))) fail(spec.id + " command result has no run identity");
  if (expectedRunId && execution.run_id !== expectedRunId) fail(spec.id + " command result belongs to a different run");
  execution.expected_run_id = expectedRunId || execution.run_id;
  verifySourceIdentity(spec, execution, {
    expectedSourceDigests: options.expectedSourceDigests || null,
    expectedManifestDigest: options.expectedManifestDigest || null,
  });
  if (spec.reporter.kind === "node-tap" || spec.reporter.kind === "exunit-tap") {
    return tapReporter(spec, execution, root);
  }
  if (spec.reporter.kind === "playwright-json") {
    return validateBrowserEvidence(spec, execution, {
      root,
      expectedSourceDigests: options.expectedSourceDigests || {},
      expectedManifestDigest: options.expectedManifestDigest,
      browserResult: options.browserResult,
      expectedBrowserCells: options.expectedBrowserCells,
      selection: options.selection || null,
    });
  }
  if (spec.reporter.kind === "playwright-titles") {
    return validateDesignEvidence(spec, execution);
  }
  if (spec.reporter.kind === "process-markers") {
    const lines = new Set(String(execution.stdout || "").split(/\r?\n/).map((line) => line.trim()));
    for (const marker of spec.process_markers) {
      if (!lines.has("PHASE253_ASSERTION=" + marker)) fail(spec.id + " did not emit executed assertion marker " + marker);
    }
    const actual = spec.process_markers.map((marker) => marker);
    if (execution.assertion_refs != null) exactSet(execution.assertion_refs, actual, spec.id + " assertion references");
    return {
      kind: "process-markers",
      test_count: null,
      skipped: 0,
      failed: 0,
      test_identities: [],
      assertion_refs: actual,
      assertion_bindings: Object.fromEntries(actual.map((marker) => [marker, ["PHASE253_ASSERTION=" + marker]])),
    };
  }
  fail(spec.id + " has an unsupported reporter kind: " + String(spec.reporter.kind));
}

export async function executeCommandSequence(commands, execute, persist) {
  if (!Array.isArray(commands) || typeof execute !== "function" || typeof persist !== "function") {
    throw new TypeError("executeCommandSequence requires commands, execute, and persist");
  }
  const results = [];
  for (const spec of commands) {
    let result;
    try {
      result = await execute(spec);
    } catch (error) {
      result = { exitCode: 1, error: String(error?.message || error) };
    }
    if (!Number.isInteger(result?.exitCode)) {
      result = { ...result, exitCode: 1, error: result?.error || "command did not report an integer exit code" };
    }
    results.push({ ...result, id: spec.id });
    const status = result.exitCode === 0 ? "running" : "failed";
    await persist({ status, commands: [...results] });
    if (status === "failed") return { status, commands: results };
  }
  const completed = { status: "passed", commands: results };
  await persist(completed);
  return completed;
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true, mode: 0o700 });
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2) + "\n", { mode: 0o600 });
}

function spawnCaptured(spec, root, logDirectory) {
  return new Promise((resolve) => {
    const startedAt = new Date().toISOString();
    const start = Date.now();
    const stdoutChunks = [];
    const stderrChunks = [];
    const child = spawn(spec.executable, spec.args, {
      cwd: path.resolve(root, spec.cwd),
      env: { ...process.env, ...spec.env },
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });
    child.stdout.on("data", (chunk) => stdoutChunks.push(Buffer.from(chunk)));
    child.stderr.on("data", (chunk) => stderrChunks.push(Buffer.from(chunk)));
    let settled = false;
    const finish = (exitCode, signal, error = null) => {
      if (settled) return;
      settled = true;
      const stdout = Buffer.concat(stdoutChunks);
      const stderr = Buffer.concat(stderrChunks);
      const name = spec.id.replace(/[^a-z0-9-]/gi, "-");
      const stdoutPath = path.join(logDirectory, name + ".stdout.log");
      const stderrPath = path.join(logDirectory, name + ".stderr.log");
      fs.writeFileSync(stdoutPath, stdout, { mode: 0o600 });
      fs.writeFileSync(stderrPath, error ? Buffer.concat([stderr, Buffer.from(String(error.message || error) + "\n")]) : stderr, { mode: 0o600 });
      resolve({
        id: spec.id,
        command: [spec.display, ...spec.args],
        cwd: spec.cwd,
        lane: spec.lane,
        partition: spec.partition,
        sources: spec.sources,
        started_at: startedAt,
        completed_at: new Date().toISOString(),
        duration_ms: Date.now() - start,
        exitCode,
        signal,
        stdout: stdout.toString("utf8"),
        stderr: stderr.toString("utf8"),
        stdout_path: path.relative(root, stdoutPath).split(path.sep).join("/"),
        stdout_sha256: sha256(stdout),
        stderr_path: path.relative(root, stderrPath).split(path.sep).join("/"),
        stderr_sha256: sha256(error ? fs.readFileSync(stderrPath) : stderr),
        error: exitCode === 0 ? null : (error?.message || stderr.toString("utf8").trim().split("\n").slice(-8).join("\n")),
      });
    };
    child.once("error", (error) => finish(127, null, error));
    child.once("exit", (code, signal) => finish(code ?? 1, signal));
  });
}

export function sourceInventory(commands) {
  return uniqueSorted([
    ...COMMON_SOURCES,
    ...PHASE_METADATA,
    MANIFEST_PATH,
    ...commands.flatMap((spec) => spec.sources),
    ...commands.flatMap((spec) => spec.reporter?.testFiles || []),
  ]);
}

function manifestBytes(root) {
  const filename = safeRepoPath(root, MANIFEST_PATH);
  if (!fs.existsSync(filename)) fail("compiled Phase 253 manifest is missing after its test lane");
  return fs.readFileSync(filename);
}

function summarizeCommand(spec, captured, evidence, sourceDigests, manifestDigest) {
  const { stdout, stderr, ...metadata } = captured;
  return {
    ...metadata,
    run_id: captured.run_id,
    manifest_sha256: manifestDigest,
    source_digests: Object.fromEntries(spec.sources.map((source) => [source, sourceDigests[source]])),
    assertion_refs: evidence.assertion_refs,
    execution_evidence: evidence,
  };
}

function gitRevision(root) {
  const result = require("node:child_process").spawnSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" });
  if (result.status !== 0) fail("could not capture the current source revision");
  return result.stdout.trim();
}

async function main() {
  const runId = crypto.randomBytes(16).toString("hex");
  const outputDirectory = path.join(ROOT, RESULT_ROOT, runId);
  const logDirectory = path.join(outputDirectory, "logs");
  fs.mkdirSync(logDirectory, { recursive: true, mode: 0o700 });
  const adminBuildPath = mixBuildPath(runId);
  const browserWorkers = resolveCompositionWorkers();
  const plan = buildCommandPlan({ id: runId, adminBuildPath, outputDirectory, browserWorkers });
  assertRequiredCommandPlan(plan);

  const resultPath = path.join(outputDirectory, "results.json");
  const trackedManifestPath = safeRepoPath(ROOT, TRACKED_PHASE252_MANIFEST);
  const trackedManifestDigestBefore = sha256(fs.readFileSync(trackedManifestPath));
  const bundle = {
    schema_version: 1,
    plan: "253-06",
    run_id: runId,
    status: "running",
    human_judgment: false,
    source_revision: gitRevision(ROOT),
    run_started_at: new Date().toISOString(),
    run_completed_at: null,
    results_path: path.relative(ROOT, resultPath).split(path.sep).join("/"),
    browser_result_path: plan.find((spec) => spec.id === "phase253-compositions-browser").browser_contract.result_path,
    browser_workers: browserWorkers,
    tracked_phase252_manifest_sha256_before: trackedManifestDigestBefore,
    tracked_phase252_manifest_sha256_after: null,
    manifest_path: MANIFEST_PATH,
    manifest_sha256: null,
    source_fingerprint: null,
    source_digests: {},
    commands: [],
  };
  writeJson(resultPath, bundle);
  process.stdout.write("Phase 253 focused aggregate: run_id=" + runId + " lanes=" + plan.length + " result=" + bundle.results_path + "\n");

  // The manifest lane (first) reads accrue_admin/tmp/phase253/transport.json, the gitignored
  // current-run proof that subscription_collection_transport_test.exs (phase253-collection-live)
  // ran. That lane is also a required later lane, so it is executed once ahead of the manifest
  // lane purely to produce the proof: a clean checkout (CI) has no leftover file, and a stale one
  // from an earlier run must never satisfy the check, so it is removed first.
  const transportProof = path.join(ROOT, "accrue_admin/tmp/phase253/transport.json");
  fs.rmSync(transportProof, { force: true });
  const proofLane = plan.find((spec) => spec.id === "phase253-collection-live");
  process.stdout.write("==> " + proofLane.id + " [transport proof for the manifest lane]\n");
  const proofCaptured = await spawnCaptured(proofLane, ROOT, logDirectory);
  bundle.transport_proof = { id: proofLane.id, exitCode: proofCaptured.exitCode, duration_ms: proofCaptured.duration_ms };
  if (proofCaptured.exitCode !== 0 || !fs.existsSync(transportProof)) {
    bundle.status = "failed";
    bundle.validation_error = "the transport proof lane did not pass and write transport.json";
    bundle.run_completed_at = new Date().toISOString();
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 aggregate failed at the transport proof (" + proofLane.id + ")\n");
    process.exitCode = 1;
    return;
  }

  const first = plan[0];
  process.stdout.write("==> " + first.id + " [" + first.lane + "]\n");
  const firstCaptured = await spawnCaptured(first, ROOT, logDirectory);
  firstCaptured.run_id = runId;
  let firstEvidence;
  try {
    firstEvidence = validateLaneEvidence(first, firstCaptured, { root: ROOT, expectedRunId: runId });
  } catch (error) {
    firstCaptured.exitCode = 1;
    firstCaptured.validation_error = error.message;
    firstEvidence = { assertion_refs: [], test_identities: [], kind: first.reporter.kind };
  }
  if (firstCaptured.exitCode !== 0) {
    bundle.status = "failed";
    bundle.commands = [{ ...firstCaptured, id: first.id, assertion_refs: firstEvidence.assertion_refs, validation_error: firstCaptured.validation_error || firstCaptured.error }];
    bundle.run_completed_at = new Date().toISOString();
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 aggregate failed at " + first.id + "\n");
    process.exitCode = 1;
    return;
  }

  let compiledManifest;
  let compiledManifestDigest;
  let initialSnapshot;
  try {
    const bytes = manifestBytes(ROOT);
    compiledManifest = JSON.parse(bytes.toString("utf8"));
    compiledManifestDigest = sha256(bytes);
    if (compiledManifest.human_judgment !== false || compiledManifest.schema_version !== 1) {
      fail("compiled Phase 253 manifest has unsupported schema or judgment mode");
    }
    initialSnapshot = sourceSnapshot(ROOT, sourceInventory(plan));
    const resultDigest = sha256(fs.readFileSync(safeRepoPath(ROOT, plan[5].browser_contract.result_path.replace(/render-results-[a-f0-9]+\.json$/, "manifest.json"))));
    if (!compiledManifestDigest || !resultDigest) fail("compiled manifest source identity was not captured");
  } catch (error) {
    bundle.status = "failed";
    bundle.validation_error = error.message;
    bundle.run_completed_at = new Date().toISOString();
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 aggregate manifest validation failed: " + error.message + "\n");
    process.exitCode = 1;
    return;
  }

  // Phase 254 D-11: the selection (PHASE254_SELECTION, passed to every child unchanged through
  // the inherited environment) is resolved and validated once, before the browser lane starts.
  // Unset means the full universe. A report that fails its invariants, names another projection
  // or another universe stops the run here.
  let selection;
  try {
    selection = browserHelpers.resolveSelection(browserHelpers.createExpectedBrowserCellDefinitions(compiledManifest));
  } catch (error) {
    bundle.status = "failed";
    bundle.validation_error = error.message;
    bundle.run_completed_at = new Date().toISOString();
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 aggregate selection validation failed: " + error.message + "\n");
    process.exitCode = 1;
    return;
  }
  bundle.selection = selection.block;
  process.stdout.write("Phase 254 selection: mode " + selection.block.mode + ", " + selection.block.selected_count + " of " +
    selection.block.total_count + " browser cells (" + selection.block.reason + ")\n");

  bundle.manifest_sha256 = compiledManifestDigest;
  bundle.source_fingerprint = initialSnapshot.fingerprint;
  bundle.source_digests = initialSnapshot.digests;
  const firstRecord = summarizeCommand(first, firstCaptured, firstEvidence, initialSnapshot.digests, compiledManifestDigest);
  bundle.commands = [firstRecord];
  bundle.run_updated_at = new Date().toISOString();
  writeJson(resultPath, bundle);

  const remaining = plan.slice(1);
  const sequence = await executeCommandSequence(
    remaining,
    async (spec) => {
      process.stdout.write("==> " + spec.id + " [" + spec.lane + (spec.partition ? "/" + spec.partition : "") + "]\n");
      const captured = await spawnCaptured(spec, ROOT, logDirectory);
      captured.run_id = runId;
      captured.manifest_sha256 = compiledManifestDigest;
      captured.source_digests = Object.fromEntries(spec.sources.map((source) => [source, initialSnapshot.digests[source]]));
      let browserResult = null;
      if (spec.reporter.kind === "playwright-json") {
        const browserPath = safeRepoPath(ROOT, spec.browser_contract.result_path);
        if (fs.existsSync(browserPath)) {
          try { browserResult = JSON.parse(fs.readFileSync(browserPath, "utf8")); }
          catch { captured.validation_error = "browser result bundle is malformed JSON"; }
        }
      }
      let evidence = null;
      if (captured.exitCode === 0) {
        try {
          evidence = validateLaneEvidence(spec, captured, {
            root: ROOT,
            expectedRunId: runId,
            expectedSourceDigests: initialSnapshot.digests,
            expectedManifestDigest: compiledManifestDigest,
            browserResult,
            selection,
          });
          captured.assertion_refs = evidence.assertion_refs;
          captured.execution_evidence = evidence;
        } catch (error) {
          captured.exitCode = 1;
          captured.validation_error = error.message;
        }
      }
      process.stdout.write("    " + (captured.exitCode === 0 ? "PASS " : "FAIL ") + spec.id + " " + captured.duration_ms + "ms\n");
      const { stdout, stderr, ...metadata } = captured;
      return { ...metadata, assertion_refs: evidence?.assertion_refs || [], execution_evidence: evidence, validation_error: captured.validation_error || null };
    },
    async (snapshot) => {
      bundle.status = snapshot.status === "failed" ? "failed" : "running";
      bundle.commands = [firstRecord, ...snapshot.commands];
      bundle.run_updated_at = new Date().toISOString();
      writeJson(resultPath, bundle);
    },
  );

  if (sequence.status !== "passed") {
    bundle.status = "failed";
    bundle.run_completed_at = new Date().toISOString();
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 focused aggregate failed at " + String(sequence.commands.at(-1)?.id || "unknown") + "\n");
    process.exitCode = 1;
    return;
  }

  try {
    const currentSnapshot = sourceSnapshot(ROOT, initialSnapshot.paths);
    if (currentSnapshot.fingerprint !== initialSnapshot.fingerprint) fail("source bytes changed during the focused Phase 253 run");
    const afterManifestDigest = sha256(manifestBytes(ROOT));
    if (afterManifestDigest !== compiledManifestDigest) fail("compiled Phase 253 manifest changed during the focused run");
    const trackedManifestDigestAfter = sha256(fs.readFileSync(trackedManifestPath));
    if (trackedManifestDigestAfter !== trackedManifestDigestBefore) fail("historical tracked Phase 252 manifest changed during the focused Phase 253 run");
    const browserPath = safeRepoPath(ROOT, bundle.browser_result_path);
    bundle.browser_result_sha256 = sha256(fs.readFileSync(browserPath));
    bundle.tracked_phase252_manifest_sha256_after = trackedManifestDigestAfter;
    bundle.source_revision_after = gitRevision(ROOT);
    bundle.status = "passed";
    bundle.run_completed_at = new Date().toISOString();
    bundle.commands = [firstRecord, ...sequence.commands];
    writeJson(resultPath, bundle);
    process.stdout.write("Phase 253 focused aggregate passed: " + bundle.commands.length + " serial lanes; browser cells=" +
      String(bundle.commands.find((row) => row.id === "phase253-compositions-browser")?.execution_evidence?.browser_cells?.length || 0) + ".\n");
    process.stdout.write("Result bundle: " + bundle.results_path + "\n");
  } catch (error) {
    bundle.status = "failed";
    bundle.validation_error = error.message;
    bundle.run_completed_at = new Date().toISOString();
    bundle.commands = [firstRecord, ...sequence.commands];
    writeJson(resultPath, bundle);
    process.stderr.write("Phase 253 focused aggregate failed after execution: " + error.message + "\n");
    process.exitCode = 1;
  }
}

export { REQUIRED_COMMAND_IDS };

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
// A bare `node --test <this file>` child has no CLI arguments and registers fixture
// tests. A spawn that passes arguments (even from inside a node --test run, where
// NODE_TEST_CONTEXT is inherited) is a real CLI invocation and keeps its behavior.
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  // Fixture tests only: they never invoke the lab, compile, or the aggregate.
  test("assertRequiredCommandPlan rejects a dropped lane and a non-array plan", () => {
    const inventory = REQUIRED_COMMAND_IDS.map((id) => ({ id }));
    assert.throws(() => assertRequiredCommandPlan(inventory.slice(1)), /does not exactly match the finite Phase 253 lane inventory/);
    assert.throws(() => assertRequiredCommandPlan("not-an-array"), TypeError);
  });

  test("executeCommandSequence stops at the first failing lane and persists the failed snapshot", async () => {
    const calls = [];
    const persisted = [];
    const outcome = await executeCommandSequence(
      [{ id: "a" }, { id: "b" }, { id: "c" }],
      async (spec) => { calls.push(spec.id); return { exitCode: spec.id === "b" ? 2 : 0 }; },
      async (snapshot) => { persisted.push(snapshot.status); },
    );
    assert.equal(outcome.status, "failed");
    assert.deepEqual(calls, ["a", "b"]);
    assert.equal(persisted.at(-1), "failed");
  });

  test("executeCommandSequence turns a missing integer exit code into a failure", async () => {
    const outcome = await executeCommandSequence([{ id: "a" }], async () => ({}), async () => {});
    assert.equal(outcome.status, "failed");
    assert.match(outcome.commands[0].error, /integer exit code/);
  });

  test("executeCommandSequence passes only when every lane exits zero", async () => {
    const outcome = await executeCommandSequence([{ id: "a" }, { id: "b" }], async () => ({ exitCode: 0 }), async () => {});
    assert.equal(outcome.status, "passed");
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    process.stderr.write("verify_phase253_compositions: " + error.message + "\n");
    process.exitCode = 2;
  });
}
