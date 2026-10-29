#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createHash, randomBytes, randomInt } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { sharedAdminBuildPath } from "./phase252_paths.mjs";
import { deriveExecutionEvidence, PHASE252_REPORTER_SPECS } from "./phase252_reporters.mjs";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import { expectedPhase252Cells, readCurationLedger } from "./verify_phase254_curation.mjs";

export const REQUIRED_COMMAND_IDS = Object.freeze([
  "manifest-current",
  "phase252-lab-contract",
  "scenario-domain",
  "subscription-area",
  "story-slice",
  "manifest-contract",
  "production-boundary-db-free",
  "phase248-heldout-contract",
  "phase252-ci-contract",
  "production-boundary-controls",
  "production-packages",
  "scenario-repo",
  "registry-kitchen-mount-scoped-path",
  "mounted-subscription-regressions",
  "heldout-cleanup",
  "isolation-reset",
  "subscription-render-browser",
  "lab-presentation",
  "heldout-attribution",
  "transparency-controls",
  "phase252-acceptance-contract",
]);

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const RESULT_ROOT_RELATIVE = "accrue_admin/tmp/phase252/ci-results";
const HISTORICAL_RENDER_RESULT = "accrue_admin/tmp/phase252/render-results.json";
const MANIFEST_PATH = "storybook/phase252-manifest.json";
const GENERATED_RENDER_RESULT_DIR = "accrue_admin/tmp/phase252";
const REQUIREMENT_IDS = ["CIQ-01", "SBK-01", "SBK-02", "SBK-03", "SCEN-01", "SCEN-02", "SCEN-03", "SCEN-04", "LAB-01", "LAB-02"];
const PHASE_SLUG = "252-production-backed-subscription-stories";
const PHASE_ARTIFACT_PREFIX = `.planning/phases/${PHASE_SLUG}/`;
const ACCEPTANCE_METADATA_PATHS = Object.freeze([
  ...Array.from({ length: 10 }, (_, index) => `${PHASE_ARTIFACT_PREFIX}252-${String(index + 1).padStart(2, "0")}-PLAN.md`),
  `${PHASE_ARTIFACT_PREFIX}252-VALIDATION.md`,
]);
const TRANSPARENCY_SOURCE_PATHS = Object.freeze([
  "scripts/ci/phase_evidence_path.mjs",
  "scripts/ci/main_module.mjs",
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
  ...ACCEPTANCE_METADATA_PATHS,
]);

const SOURCE_AND_ASSET_PATHS = Object.freeze([
  ".github/workflows/ci.yml",
  ".github/workflows/accrue_admin_browser.yml",
  "accrue_admin/package.json",
  "accrue_admin/playwright.phase252.config.js",
  "accrue_admin/e2e/phase252-review.spec.js",
  "accrue_admin/e2e/phase252-story-helpers.js",
  "accrue_admin/e2e/subscription-stories-phase252.spec.js",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/js/storybook_hooks.js",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/storybook.css",
  "accrue_admin/priv/static/storybook.js",
  "accrue_admin/priv/static/fonts/geist-sans-vf.woff2",
  "accrue_admin/priv/static/fonts/geist-mono-vf.woff2",
  "brandbook/tokens/tokens.css",
  "scripts/ci/phase252_paths.mjs",
  "scripts/ci/phase252_reporters.mjs",
  "scripts/ci/phase_evidence_path.mjs",
  "scripts/ci/verify_phase252_ci_contract.test.mjs",
  "scripts/ci/verify_phase252_production_boundary.mjs",
  "scripts/ci/verify_phase252_production_boundary.test.mjs",
  "scripts/ci/verify_phase252_stories.mjs",
  "scripts/ci/verify_phase252_transparency.mjs",
  "scripts/ci/verify_phase252_lab_presentation.test.mjs",
  "scripts/ci/verify_phase252_heldout_attribution.test.mjs",
  "scripts/ci/fixtures/phase252-transparency/lab-clean.json",
  "scripts/ci/fixtures/phase252-transparency/lab-violation.json",
  "scripts/ci/fixtures/phase252-transparency/heldout-clean.json",
  "scripts/ci/fixtures/phase252-transparency/heldout-violation.json",
  ...ACCEPTANCE_METADATA_PATHS,
  "scripts/ci/generate_phase252_acceptance.mjs",
  "scripts/ci/generate_phase252_acceptance.test.mjs",
  "guides/ui-story-lab.md",
  "scripts/ci/verify_phase200_admin_guardrails.sh",
  "scripts/ci/verify_phase200_guardrail_contract.sh",
  "scripts/dev/phase252_lab.mjs",
  "scripts/dev/phase252_lab.test.mjs",
  "scripts/dev/phase252_isolation.test.mjs",
  "scripts/ci/phase248_heldout_isolation.test.mjs",
  "accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs",
  "accrue_admin/test/test_helper.exs",
  "examples/accrue_host/test/test_helper.exs",
  "dev_support/phase252_tap_formatter.ex",
  "accrue_admin/test/accrue_admin/dev/subscription_story_slice_test.exs",
  "storybook/components/subscription_detail.story.exs",
]);

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function sourceFilePath(root, relativePath) {
  if (relativePath.startsWith(PHASE_ARTIFACT_PREFIX)) {
    return resolvePhaseEvidencePath(PHASE_SLUG, relativePath.slice(PHASE_ARTIFACT_PREFIX.length), { root });
  }
  return path.join(root, relativePath);
}

export function fileDigest(root, relativePath) {
  const absolutePath = sourceFilePath(root, relativePath);
  if (!fs.existsSync(absolutePath) || !fs.statSync(absolutePath).isFile()) {
    throw new Error("Phase 252 source or asset is missing: " + relativePath);
  }
  return sha256(fs.readFileSync(absolutePath));
}

export function sourceSnapshot(root, manifest, extraPaths = []) {
  const paths = [...new Set([
    ...SOURCE_AND_ASSET_PATHS,
    ...Object.keys(manifest?.source_digests || {}),
    ...extraPaths,
    MANIFEST_PATH,
  ])].sort();
  const digests = Object.fromEntries(paths.map((relativePath) => [relativePath, fileDigest(root, relativePath)]));
  return { paths, digests, fingerprint: sha256(JSON.stringify(digests)) };
}

function makeRunId() {
  return "25208-" + Date.now() + "-" + process.pid + "-" + randomBytes(6).toString("hex");
}

function freshPartition(used) {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    const partition = String(randomInt(1_000_000_000, 10_000_000_000));
    if (!used.has(partition)) {
      used.add(partition);
      return partition;
    }
  }
  throw new Error("could not allocate a unique Phase 252 numeric partition");
}

function canonicalTempRoot() {
  return fs.realpathSync(os.tmpdir());
}

function mixBuildPath(id, project) {
  const userId = typeof process.getuid === "function" ? process.getuid() : "local";
  if (project === "accrue-admin") {
    const shared = sharedAdminBuildPath({ tempRoot: canonicalTempRoot(), userId: String(userId) });
    if (shared) return shared;
  }
  return path.join(canonicalTempRoot(), "accrue-phase252-" + userId, id, "mix-build", project);
}

export function manifestFreshnessCode() {
  return [
    '{:ok, _started} = Application.ensure_all_started(:localize)',
    "alias AccrueAdmin.Storybook.SubscriptionManifest",
    'temp = Path.join(System.tmp_dir!(), "phase252-manifest-current-#{System.unique_integer([:positive])}.json")',
    "try do",
    "  :ok = SubscriptionManifest.write!(temp)",
    "  generated = File.read!(temp)",
    '  checked_in = File.read!(Path.expand("../storybook/phase252-manifest.json", File.cwd!()))',
    '  if Jason.decode!(generated) != Jason.decode!(checked_in), do: raise("checked-in phase252 manifest is stale; regenerate it from compiled source before browser review")',
    '  IO.puts("Phase 252 manifest: generated compiled-source bytes match the tracked manifest")',
    '  IO.puts("PHASE252_ASSERTION=compiled_variation_discovery")',
    '  IO.puts("PHASE252_ASSERTION=source_digest_freshness")',
    '  IO.puts("PHASE252_ASSERTION=tracked_manifest_content_identity")',
    "after",
    "  File.rm(temp)",
    "end",
  ].join("\n");
}

function command(id, display, executable, args, options = {}) {
  return {
    id,
    display,
    executable,
    args,
    cwd: options.cwd || ".",
    lane: options.lane || "read-only",
    warmth: options.warmth || "warm",
    partition: options.partition || null,
    sources: [...new Set([...(options.sources || []), ...(PHASE252_REPORTER_SPECS[id]?.testFiles || [])])],
    assertions: options.assertions || [],
    reporter: PHASE252_REPORTER_SPECS[id],
    env: options.env || {},
  };
}

export function buildCommandPlan({ id, adminBuildPath, hostBuildPath, outputDirectory }) {
  const usedPartitions = new Set();
  const tap = (file) => ["--test", "--test-reporter=tap", file];
  const phase252LabExec = (testId, files, assertions = [], lane = "admin-test") => {
    const partition = freshPartition(usedPartitions);
    const shell = "cd accrue_admin && MIX_ENV=test mix test " + files.join(" ");
    return command(
      testId,
      "node ../scripts/dev/phase252_lab.mjs exec",
      process.execPath,
      ["scripts/dev/phase252_lab.mjs", "exec", "--lane", lane, "--partition", partition, "--", "sh", "-c", shell],
      { lane, partition, warmth: lane === "admin-test" && testId === "scenario-repo" ? "cold-database-startup" : "warm", env: { MIX_ENV: "test", MIX_BUILD_PATH: lane === "host-heldout" ? hostBuildPath : adminBuildPath, PHASE252_TAP_REPORT: "1" }, sources: files.map((file) => lane === "host-heldout" ? "examples/accrue_host/" + file : "accrue_admin/" + file), assertions },
    );
  };
  const dbFree = (testId, file, assertions = []) => command(
    testId,
    "MIX_ENV=test mix run --no-start",
    "mix",
    ["run", "--no-start", file],
    { cwd: "accrue_admin", lane: "db-free", warmth: testId === "scenario-domain" ? "cold-build" : "warm", env: { MIX_ENV: "test", MIX_BUILD_PATH: adminBuildPath }, sources: ["accrue_admin/" + file], assertions },
  );

  const plan = [
    command(
      "manifest-current",
      "MIX_ENV=test mix run --no-start -e <generate-and-compare-manifest>",
      "mix",
      ["run", "--no-start", "-e", manifestFreshnessCode()],
      { cwd: "accrue_admin", lane: "db-free", warmth: "cold-build", env: { MIX_ENV: "test", MIX_BUILD_PATH: adminBuildPath }, sources: [MANIFEST_PATH, "accrue_admin/storybook/_support/subscription_manifest.ex"], assertions: ["compiled_variation_discovery", "source_digest_freshness", "tracked_manifest_content_identity"] },
    ),
    command("phase252-lab-contract", "node --test Phase 252 lab lifecycle contract", process.execPath, tap("scripts/dev/phase252_lab.test.mjs"), { lane: "read-only", sources: ["scripts/dev/phase252_lab.test.mjs", "scripts/dev/phase252_lab.mjs"], assertions: ["owned_resource_identity", "unsafe_input_refusal", "cleanup_identity_guard", "namespace_lock_one_owner", "stale_lock_owner_refusal", "exact_process_identity_cleanup", "owned_process_group_identity"] }),
    dbFree("scenario-domain", "test/accrue_admin/dev/subscription_scenarios_test.exs", ["validated_deterministic_scenarios", "fixed_clock_and_identity", "deterministic_fact_source", "canceling_boundary_exact_clock", "exact_minor_unit_money_precision"]),
    dbFree("subscription-area", "test/accrue_admin/components/subscription_area_test.exs", ["production_area_content", "copy_and_scoped_action_semantics"]),
    dbFree("story-slice", "test/accrue_admin/dev/subscription_story_slice_test.exs", ["shared_renderer_and_active_variation", "no_repo_bootstrap", "subscription_story_uses_full_width_layout"]),
    dbFree("manifest-contract", "test/accrue_admin/dev/subscription_manifest_test.exs", ["compiled_variation_routes", "stable_group_and_same_id_keys", "current_caller_map", "stale_manifest_rejection", "story_variation_identity_adjacency", "zero_variation_and_missing_attribution_refusal", "deterministic_manifest_ordering", "caller_identity_adjacency", "empty_caller_source_refusal", "stable_caller_ordering"]),
    dbFree("production-boundary-db-free", "test/accrue_admin/dev/subscription_production_boundary_test.exs", ["production_route_and_compile_boundary"]),
    command("phase248-heldout-contract", "node --test Phase 248 held-out isolation contract", process.execPath, tap("scripts/ci/phase248_heldout_isolation.test.mjs"), { lane: "read-only", sources: ["scripts/ci/phase248_heldout_isolation.test.mjs"], assertions: ["held_out_partition_and_owner"] }),
    command("phase252-ci-contract", "node --test Phase 252 CI admission contract", process.execPath, tap("scripts/ci/verify_phase252_ci_contract.test.mjs"), { lane: "read-only", sources: ["scripts/ci/verify_phase252_ci_contract.test.mjs", "scripts/ci/phase252_reporters.mjs", ".github/workflows/ci.yml", "scripts/ci/verify_phase200_admin_guardrails.sh"], assertions: ["consumed_root_owner_map", "workflow_admission", "named_required_owner_execution", "required_owner_invocation_mutations", "required_transparency_lane_inventory", "transparency_reporter_bindings", "transparency_source_freshness", "transparency_consumed_root_admission", "transparency_non_vacuity"] }),
    command("production-boundary-controls", "node scripts/ci/verify_phase252_production_boundary.mjs --self-test", process.execPath, ["scripts/ci/verify_phase252_production_boundary.mjs", "--self-test"], { lane: "isolated-build", sources: ["scripts/ci/verify_phase252_production_boundary.mjs"], assertions: ["production_package_leak_negative_controls", "development_positive_production_route_exclusion"] }),
    command("production-packages", "node scripts/ci/verify_phase252_production_boundary.mjs", process.execPath, ["scripts/ci/verify_phase252_production_boundary.mjs"], { lane: "isolated-build", warmth: "cold", sources: ["scripts/ci/verify_phase252_production_boundary.mjs", "accrue/mix.exs", "accrue_admin/mix.exs", "accrue_portal/mix.exs"], assertions: ["fresh_production_compiles", "actual_unpacked_hex_archives"] }),
    phase252LabExec("scenario-repo", ["test/accrue_admin/dev/subscription_scenario_repo_test.exs"], ["persisted_launch_and_team_facts", "database_constraints", "replay_identity_conflict_refusal", "transaction_rollback", "concurrent_insert_serialization"]),
    phase252LabExec("registry-kitchen-mount-scoped-path", [
      "test/accrue_admin/dev/component_registry_test.exs",
      "test/accrue_admin/dev/component_group_registry_test.exs",
      "test/accrue_admin/dev/storybook_coverage_test.exs",
      "test/accrue_admin/dev/storybook_asset_test.exs",
      "test/accrue_admin/dev/subscription_production_boundary_test.exs",
      "test/accrue_admin/scoped_path_test.exs",
    ], ["registry_variant_and_token_reconciliation", "group_contract_and_mounted_kitchen", "production_caller_map_reconciliation", "served_storybook_assets", "development_and_production_route_boundaries", "scoped_return_path_safety"]),
    phase252LabExec("mounted-subscription-regressions", ["test/accrue_admin/live/subscription_live_test.exs"], ["mounted_subscription_structure", "organization_scope_enforcement", "lifecycle_distinctions", "action_review_and_confirmation", "provider_action_boundaries", "authority_regression", "scoped_not_found_regression"]),
    (() => {
      const partition = freshPartition(usedPartitions);
      return command(
        "heldout-cleanup",
        "node ../scripts/dev/phase252_lab.mjs exec",
        process.execPath,
        ["scripts/dev/phase252_lab.mjs", "exec", "--lane", "host-heldout", "--partition", partition, "--", "sh", "-c", "cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/phase252_scenario_cleanup_test.exs"],
        { lane: "host-heldout", partition, warmth: "cold-database-startup", env: { MIX_ENV: "test", MIX_BUILD_PATH: hostBuildPath, PHASE252_TAP_REPORT: "1" }, sources: ["examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs", "examples/accrue_host/mix.exs", "scripts/dev/phase252_lab.mjs"], assertions: ["exact_cleanup_authority", "unrelated_child_preserved", "heldout_identity_separation", "cleanup_idempotency_absence_mismatch", "serialized_unrelated_child_concurrency"] },
      );
    })(),
    command("isolation-reset", "node --test Phase 252 isolated normal/review reset proof", process.execPath, tap("scripts/dev/phase252_isolation.test.mjs"), { lane: "self-owned-disposable-review-and-admin-test", warmth: "cold-database-startup", env: { MIX_BUILD_PATH: adminBuildPath }, sources: ["scripts/dev/phase252_isolation.test.mjs", "scripts/dev/phase252_lab.mjs"], assertions: ["normal_reset_positive_control", "review_data_unchanged_negative_control", "distinct_review_process_and_database", "interrupted_descendant_cleanup_before_database_drop", "owned_descendants_cleanup_after_leader_exit", "unrelated_process_survives_group_cleanup"] }),
  ];

  const partition = freshPartition(usedPartitions);
  const resultId = id.toLowerCase();
  const outputDir = path.join(outputDirectory, "playwright-output");
  plan.push(command(
    "subscription-render-browser",
    "node scripts/dev/phase252_lab.mjs browser -- --reporter=json e2e/subscription-stories-phase252.spec.js",
    process.execPath,
    ["scripts/dev/phase252_lab.mjs", "browser", "--", "--reporter=json", "e2e/subscription-stories-phase252.spec.js"],
    {
      lane: "admin-review-browser",
      partition,
      warmth: "warm-render-after-cold-owned-database-startup",
      sources: ["accrue_admin/e2e/subscription-stories-phase252.spec.js", "accrue_admin/e2e/phase252-story-helpers.js", MANIFEST_PATH, "accrue_admin/priv/static/storybook.css", "accrue_admin/priv/static/storybook.js", "accrue_admin/priv/static/fonts/geist-sans-vf.woff2", "accrue_admin/priv/static/fonts/geist-mono-vf.woff2"],
      assertions: ["exact_twelve_canonical_width_theme_cells", "three_compatibility_render_cases", "manifest_reconciliation_negative_controls", "twenty_ui_predicates", "served_assets_and_fonts"],
      env: {
        MIX_ENV: "test",
        MIX_BUILD_PATH: adminBuildPath,
        MIX_TEST_PARTITION: partition,
        PHASE252_E2E_NONCE: id,
        PHASE252_RESULT_ID: resultId,
        PLAYWRIGHT_OUTPUT_DIR: outputDir,
        PHASE252_SCREENSHOT_DIR: path.join(outputDirectory, "screenshots"),
      },
    },
  ));
  plan.push(command(
    "lab-presentation",
    "node --test Phase 252 lab presentation assertion",
    process.execPath,
    tap("scripts/ci/verify_phase252_lab_presentation.test.mjs"),
    { lane: "read-only", sources: TRANSPARENCY_SOURCE_PATHS, assertions: ["lab_static_limits", "lab_contradiction_controls"] },
  ));
  plan.push(command(
    "heldout-attribution",
    "node --test Phase 252 held-out attribution assertion",
    process.execPath,
    tap("scripts/ci/verify_phase252_heldout_attribution.test.mjs"),
    { lane: "read-only", sources: TRANSPARENCY_SOURCE_PATHS, assertions: ["heldout_synthetic_attribution", "heldout_contradiction_controls"] },
  ));
  plan.push(command(
    "transparency-controls",
    "node scripts/ci/verify_phase252_transparency.mjs --self-test",
    process.execPath,
    ["scripts/ci/verify_phase252_transparency.mjs", "--self-test"],
    {
      lane: "read-only",
      sources: TRANSPARENCY_SOURCE_PATHS,
      assertions: [
        "lab_static_current_green",
        "lab_static_clean_green",
        "lab_static_violation_red",
        "heldout_synthetic_current_green",
        "heldout_synthetic_clean_green",
        "heldout_synthetic_violation_red",
      ],
    },
  ));
  plan.push(command(
    "phase252-acceptance-contract",
    "node --test Phase 252 acceptance evidence contract",
    process.execPath,
    tap("scripts/ci/generate_phase252_acceptance.test.mjs"),
    {
      lane: "read-only",
      sources: ["scripts/ci/generate_phase252_acceptance.mjs", "scripts/ci/generate_phase252_acceptance.test.mjs", "scripts/ci/verify_phase252_stories.mjs", "guides/ui-story-lab.md", ".github/workflows/ci.yml"],
      assertions: ["missing_command_rejection", "failed_command_rejection", "stale_source_and_asset_rejection", "pooled_cell_rejection", "missing_predicate_rejection", "unsafe_evidence_path_rejection", "guide_contract_mutation_rejection", "executed_tap_positive_control", "skipped_required_test_rejection", "missing_and_empty_report_rejection", "excluded_required_test_rejection", "fake_assertion_ref_rejection"],
    },
  ));
  return plan;
}

export function assertRequiredCommandPlan(commands) {
  if (!Array.isArray(commands)) throw new TypeError("Phase 252 required command plan must be an array");
  const ids = commands.map((row) => row?.id);
  if (JSON.stringify(ids) !== JSON.stringify(REQUIRED_COMMAND_IDS)) {
    throw new Error("Phase 252 required command plan does not exactly match the named required lane inventory");
  }
  for (const id of REQUIRED_COMMAND_IDS) {
    if (!PHASE252_REPORTER_SPECS[id]) throw new Error("Phase 252 required command has no reporter specification: " + id);
  }
  return true;
}

export async function executeCommandSequence(commands, execute, persist) {
  if (!Array.isArray(commands) || typeof execute !== "function" || typeof persist !== "function") {
    throw new TypeError("executeCommandSequence requires commands, execute, and persist");
  }
  const results = [];
  for (const commandSpec of commands) {
    let result;
    try {
      result = await execute(commandSpec);
    } catch (error) {
      result = { exitCode: 1, error: String(error?.message || error) };
    }
    if (!Number.isInteger(result?.exitCode)) {
      result = { ...result, exitCode: 1, error: result?.error || "command did not report an integer exit code" };
    }
    results.push({ ...result, id: commandSpec.id, assertion_refs: result.assertion_refs || [] });
    const failed = result.exitCode !== 0;
    const snapshot = { status: failed ? "failed" : "running", commands: [...results] };
    await persist(snapshot);
    if (failed) return snapshot;
  }
  const completed = { status: "passed", commands: results };
  await persist(completed);
  return completed;
}

function spawnCaptured(spec, root, logDirectory) {
  return new Promise((resolve) => {
    const startedAt = new Date().toISOString();
    const started = Date.now();
    const stdoutChunks = [];
    const stderrChunks = [];
    const env = { ...process.env, ...spec.env };
    const child = spawn(spec.executable, spec.args, {
      cwd: path.resolve(root, spec.cwd),
      env,
      shell: false,
      stdio: ["ignore", "pipe", "pipe"],
    });
    child.stdout.on("data", (chunk) => stdoutChunks.push(Buffer.from(chunk)));
    child.stderr.on("data", (chunk) => stderrChunks.push(Buffer.from(chunk)));
    let settled = false;

    async function finish(exitCode, signal, error = null) {
      if (settled) return;
      settled = true;
      const stdout = Buffer.concat(stdoutChunks);
      const stderr = Buffer.concat(stderrChunks);
      const name = spec.id.replace(/[^a-z0-9-]/gi, "-");
      const stdoutPath = path.join(logDirectory, name + ".stdout.log");
      const stderrPath = path.join(logDirectory, name + ".stderr.log");
      fs.writeFileSync(stdoutPath, stdout, { mode: 0o600 });
      fs.writeFileSync(stderrPath, error ? Buffer.concat([stderr, Buffer.from(error.message + "\n")]) : stderr, { mode: 0o600 });
      resolve({
        id: spec.id,
        command: [spec.display, ...spec.args],
        cwd: spec.cwd,
        lane: spec.lane,
        warmth: spec.warmth,
        partition: spec.partition,
        sources: spec.sources,
        started_at: startedAt,
        completed_at: new Date().toISOString(),
        duration_ms: Date.now() - started,
        exitCode,
        signal,
        stdout_path: path.relative(root, stdoutPath).split(path.sep).join("/"),
        stdout_sha256: sha256(stdout),
        stderr_path: path.relative(root, stderrPath).split(path.sep).join("/"),
        stderr_sha256: sha256(fs.readFileSync(stderrPath)),
        error: exitCode === 0 ? null : (error?.message || stderr.toString("utf8").trim().split("\n").slice(-8).join("\n")),
      });
    }
    child.once("error", (error) => finish(127, null, error));
    child.once("exit", (code, signal) => finish(code ?? 1, signal));
  });
}

// Phase 254 CURATE-01 (AMD-254-01): the expected row counts derive from the curation ledger
// (frozen baseline minus retired). 15 rows (12 canonical + 3 compatibility) stays the frozen-baseline
// fixture positive control; a missing or unreadable ledger throws and never defaults to a smaller count.
export function assertRenderRowCounts(rows, ledger) {
  const expected = expectedPhase252Cells(ledger);
  if (!Array.isArray(rows) || rows.length !== expected.total) {
    throw new Error(`browser result must contain exactly ${expected.total} current rows: ${expected.canonical} canonical cells and ${expected.compatibility} compatibility cases`);
  }
  const canonical = rows.filter((row) => row.case_kind === "canonical");
  const compatibility = rows.filter((row) => row.case_kind === "compatibility");
  if (canonical.length !== expected.canonical || compatibility.length !== expected.compatibility) {
    throw new Error("browser result is pooled or omits a canonical/compatibility cell");
  }
  return expected;
}

function validateRenderResults(resultPath, { id, manifestDigest }) {
  if (!fs.existsSync(resultPath)) throw new Error("browser result file is missing");
  const results = JSON.parse(fs.readFileSync(resultPath, "utf8"));
  if (results.run_id !== id) throw new Error("browser result run identity does not match the current launcher");
  if (results.human_judgment !== false) throw new Error("browser result does not declare human_judgment: false");
  if (results.manifest_sha256 !== manifestDigest) throw new Error("browser result manifest digest is stale");
  const expectedCells = assertRenderRowCounts(results.cases, readCurationLedger(ROOT));
  const canonical = results.cases.filter((row) => row.case_kind === "canonical");
  const canonicalKeys = new Set(canonical.map((row) => row.scenario_id + "::" + row.width + "::" + row.theme));
  for (const state of ["active", "scheduled_cancellation", "incomplete_evidence"]) {
    for (const width of [320, 1280]) {
      for (const theme of ["light", "dark"]) {
        if (!canonicalKeys.has(state + "::" + width + "::" + theme)) throw new Error("browser result omitted canonical cell " + state + "/" + width + "/" + theme);
      }
    }
  }
  if (results.cases.some((row) => row.status !== "passed" || row.manifest_sha256 !== manifestDigest)) {
    throw new Error("browser result contains a failed or stale render row");
  }
  const screenshotRoot = path.join(ROOT, RESULT_ROOT_RELATIVE, id, "screenshots");
  const screenshotPaths = new Set();
  for (const row of canonical) {
    const expectedName = `${row.scenario_id}-${row.width}-${row.theme}.png`;
    const expectedPath = path.relative(ROOT, path.join(screenshotRoot, expectedName)).split(path.sep).join("/");
    if (row.screenshot?.path !== expectedPath || !/^[0-9a-f]{64}$/.test(row.screenshot?.sha256 || "") || screenshotPaths.has(row.screenshot.path)) {
      throw new Error("browser result screenshot path is pooled, missing, duplicated, or outside the current run");
    }
    screenshotPaths.add(row.screenshot.path);
    const bytes = fs.readFileSync(path.resolve(ROOT, row.screenshot.path));
    if (bytes.length < 100 || sha256(bytes) !== row.screenshot.sha256) {
      throw new Error("browser result screenshot bytes are missing, empty, or stale: " + row.screenshot.path);
    }
  }
  if (screenshotPaths.size !== expectedCells.canonical) throw new Error(`browser result must capture all ${expectedCells.canonical} canonical state/width/theme screenshots`);
  if (results.negative_controls?.baseline_accepted !== true || ["invalid_route", "missing_variation", "metadata_only"].some((key) => results.negative_controls?.[key]?.rejected !== true)) {
    throw new Error("browser reconciliation negative controls are incomplete");
  }
  const expectedUi = ["UI-E1-loading", "UI-E1-error", "UI-E1-overflow", "UI-E1-long-text", "UI-E2-empty", "UI-E2-loading", "UI-E2-error", "UI-E2-populated", "UI-E2-partial", "UI-E2-overflow", "UI-E2-zero-one-many", "UI-E2-long-text", "UI-E3-empty", "UI-E3-loading", "UI-E3-error", "UI-E3-populated", "UI-E3-partial", "UI-E3-overflow", "UI-E3-zero-one-many", "UI-E3-long-text"].sort();
  if (!results.ui_predicate_coverage || JSON.stringify(Object.keys(results.ui_predicate_coverage).sort()) !== JSON.stringify(expectedUi)) {
    throw new Error("browser result does not cover the complete twenty-predicate UI contract");
  }
  return results;
}

async function gitValue(root, args) {
  const child = spawn("git", args, { cwd: root, stdio: ["ignore", "pipe", "pipe"] });
  return new Promise((resolve, reject) => {
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8").on("data", (chunk) => stdout += chunk);
    child.stderr.setEncoding("utf8").on("data", (chunk) => stderr += chunk);
    child.once("error", reject);
    child.once("exit", (code) => code === 0 ? resolve(stdout.trim()) : reject(new Error(stderr.trim() || "git command failed")));
  });
}

async function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true, mode: 0o700 });
  fs.writeFileSync(filePath, JSON.stringify(value, null, 2) + "\n", { mode: 0o600 });
}

async function main() {
  const id = makeRunId();
  const resultDirectory = path.join(ROOT, RESULT_ROOT_RELATIVE, id);
  const resultPath = path.join(resultDirectory, "results.json");
  const logDirectory = path.join(resultDirectory, "logs");
  fs.mkdirSync(logDirectory, { recursive: true, mode: 0o700 });
  const manifestBytes = fs.readFileSync(path.join(ROOT, MANIFEST_PATH));
  const parsedManifest = JSON.parse(manifestBytes.toString("utf8"));
  const manifestDigest = sha256(manifestBytes);
  const adminBuildPath = mixBuildPath(id, "accrue-admin");
  const hostBuildPath = mixBuildPath(id, "accrue-host");
  const commandPlan = buildCommandPlan({
    id,
    adminBuildPath,
    hostBuildPath,
    outputDirectory: resultDirectory,
  });
  assertRequiredCommandPlan(commandPlan);
  const runSourcePaths = commandPlan.flatMap((commandSpec) => [
    ...(commandSpec.sources || []),
    ...(commandSpec.reporter?.testFiles || []),
  ]);
  const before = sourceSnapshot(ROOT, parsedManifest, runSourcePaths);
  const sourceRevision = await gitValue(ROOT, ["rev-parse", "HEAD"]);
  const originalRenderPath = path.join(ROOT, HISTORICAL_RENDER_RESULT);
  const originalRenderDigest = fs.existsSync(originalRenderPath) ? sha256(fs.readFileSync(originalRenderPath)) : null;
  const browserResultPath = path.join(ROOT, GENERATED_RENDER_RESULT_DIR, "render-results-" + id.toLowerCase() + ".json");
  const bundle = {
    schema_version: 1,
    plan: "252-08",
    run_id: id,
    status: "running",
    human_judgment: false,
    source_revision: sourceRevision,
    source_fingerprint: before.fingerprint,
    source_digests: before.digests,
    manifest_path: MANIFEST_PATH,
    manifest_sha256: manifestDigest,
    requirements: REQUIREMENT_IDS,
    browser_result_path: path.relative(ROOT, browserResultPath).split(path.sep).join("/"),
    historical_render_result_preserved: originalRenderDigest === null ? "not-present-before-run" : "digest-pinned",
    historical_render_result_sha256_before: originalRenderDigest,
    build_paths: {
      admin: path.relative(canonicalTempRoot(), adminBuildPath).split(path.sep).join("/"),
      host: path.relative(canonicalTempRoot(), hostBuildPath).split(path.sep).join("/"),
    },
    run_started_at: new Date().toISOString(),
    run_completed_at: null,
    results_path: path.relative(ROOT, resultPath).split(path.sep).join("/"),
    commands: [],
    costs: { cold_build: null, cold_database_startup: null, warm_database_lane: null, production_build: null, browser_lane: null },
  };
  await writeJson(resultPath, bundle);
  process.stdout.write("Phase 252 focused gate: run_id=" + id + " commands=" + commandPlan.length + " result=" + bundle.browser_result_path + "\n");

  const sequence = await executeCommandSequence(
    commandPlan,
    async (spec) => {
      process.stdout.write("==> " + spec.id + " [" + spec.lane + "/" + spec.warmth + "]\n");
      const result = await spawnCaptured(spec, ROOT, logDirectory);
      if (result.exitCode === 0 && spec.id === "subscription-render-browser") {
        try {
          validateRenderResults(browserResultPath, { id, manifestDigest });
          result.browser_result_path = bundle.browser_result_path;
        } catch (error) {
          result.exitCode = 1;
          result.validation_error = error.message;
          const stderrPath = path.join(ROOT, result.stderr_path);
          fs.appendFileSync(stderrPath, "\n" + error.message + "\n");
          result.stderr_sha256 = sha256(fs.readFileSync(stderrPath));
        }
      }
      if (result.exitCode === 0 && spec.reporter) {
        try {
          const stdout = fs.readFileSync(path.resolve(ROOT, result.stdout_path), "utf8");
          const browserResult = spec.id === "subscription-render-browser"
            ? JSON.parse(fs.readFileSync(browserResultPath, "utf8"))
            : null;
          Object.assign(result, deriveExecutionEvidence({
            root: ROOT,
            commandId: spec.id,
            stdout,
            expectedAssertions: spec.assertions || [],
            browserResult,
          }));
        } catch (error) {
          result.exitCode = 1;
          result.validation_error = "executed reporter evidence validation failed: " + error.message;
          const stderrPath = path.resolve(ROOT, result.stderr_path);
          fs.appendFileSync(stderrPath, "\n" + result.validation_error + "\n");
          result.stderr_sha256 = sha256(fs.readFileSync(stderrPath));
        }
      }
      process.stdout.write("    " + (result.exitCode === 0 ? "PASS " : "FAIL ") + spec.id + " " + result.duration_ms + "ms\n");
      return result;
    },
    async (snapshot) => {
      bundle.status = snapshot.status;
      bundle.commands = snapshot.commands;
      bundle.run_updated_at = new Date().toISOString();
      await writeJson(resultPath, bundle);
    },
  );

  if (sequence.status !== "passed") {
    bundle.status = "failed";
    bundle.run_completed_at = new Date().toISOString();
    await writeJson(resultPath, bundle);
    process.stderr.write("Phase 252 focused gate failed at " + (sequence.commands.at(-1)?.id || "unknown") + "; no passing bundle was produced.\n");
    process.exitCode = 1;
    return;
  }

  const current = sourceSnapshot(ROOT, parsedManifest, runSourcePaths);
  if (current.fingerprint !== before.fingerprint) {
    bundle.status = "failed";
    bundle.validation_error = "source or asset bytes changed during the focused run";
    bundle.run_completed_at = new Date().toISOString();
    await writeJson(resultPath, bundle);
    process.stderr.write("Phase 252 focused gate failed: source or asset bytes changed during the run.\n");
    process.exitCode = 1;
    return;
  }
  const afterRenderDigest = fs.existsSync(originalRenderPath) ? sha256(fs.readFileSync(originalRenderPath)) : null;
  if (afterRenderDigest !== originalRenderDigest) {
    bundle.status = "failed";
    bundle.validation_error = "historical fixed-path render evidence changed during the run";
    bundle.run_completed_at = new Date().toISOString();
    await writeJson(resultPath, bundle);
    process.stderr.write("Phase 252 focused gate failed: the historical fixed-path render result changed.\n");
    process.exitCode = 1;
    return;
  }

  const coldBuild = bundle.commands.find((row) => row.id === "manifest-current");
  const coldDatabase = bundle.commands.find((row) => row.id === "scenario-repo");
  const warmDatabase = bundle.commands.find((row) => row.id === "registry-kitchen-mount-scoped-path");
  const productionBuild = bundle.commands.find((row) => row.id === "production-packages");
  const browser = bundle.commands.find((row) => row.id === "subscription-render-browser");
  bundle.costs = {
    cold_build: coldBuild ? { command_id: coldBuild.id, duration_ms: coldBuild.duration_ms, lane: coldBuild.lane } : null,
    cold_database_startup: coldDatabase ? { command_id: coldDatabase.id, duration_ms: coldDatabase.duration_ms, lane: coldDatabase.lane } : null,
    warm_database_lane: warmDatabase ? { command_id: warmDatabase.id, duration_ms: warmDatabase.duration_ms, lane: warmDatabase.lane } : null,
    production_build: productionBuild ? { command_id: productionBuild.id, duration_ms: productionBuild.duration_ms, lane: productionBuild.lane } : null,
    browser_lane: browser ? { command_id: browser.id, duration_ms: browser.duration_ms, lane: browser.lane } : null,
    budget_status: "measured-only; no Phase 254 budget is frozen here",
  };
  bundle.status = "passed";
  bundle.run_completed_at = new Date().toISOString();
  bundle.browser_results_sha256 = sha256(fs.readFileSync(browserResultPath));
  await writeJson(resultPath, bundle);
  try {
    const { validatePhase252Evidence } = await import("./generate_phase252_acceptance.mjs");
    bundle.acceptance = validatePhase252Evidence({ root: ROOT, resultsPath: path.relative(ROOT, resultPath).split(path.sep).join("/") });
  } catch (error) {
    bundle.status = "failed";
    bundle.validation_error = "acceptance evidence validation failed: " + error.message;
    await writeJson(resultPath, bundle);
    process.stderr.write("Phase 252 focused gate failed: " + bundle.validation_error + "\n");
    process.exitCode = 1;
    return;
  }
  await writeJson(resultPath, bundle);
  process.stdout.write("Phase 252 focused gate passed: " + bundle.commands.length + " commands; cold compile=" + (bundle.costs.cold_build?.duration_ms ?? 0) + "ms; cold DB=" + (bundle.costs.cold_database_startup?.duration_ms ?? 0) + "ms; warm DB=" + (bundle.costs.warm_database_lane?.duration_ms ?? 0) + "ms; browser lane=" + (bundle.costs.browser_lane?.duration_ms ?? 0) + "ms.\n");
  process.stdout.write("Result bundle: " + path.relative(ROOT, resultPath).split(path.sep).join("/") + "\n");
}

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
  // Fixture tests only: they call the pure exports and never start the
  // multi-command aggregate (which would compile and boot the lab).
  test("assertRequiredCommandPlan accepts exactly the required lane inventory and rejects a dropped lane", () => {
    const inventory = REQUIRED_COMMAND_IDS.map((id) => ({ id }));
    assert.equal(assertRequiredCommandPlan(inventory), true);
    assert.throws(() => assertRequiredCommandPlan(inventory.slice(1)), /does not exactly match/);
    assert.throws(() => assertRequiredCommandPlan("not-an-array"), TypeError);
  });

  test("executeCommandSequence stops at the first failing command and persists the failed snapshot", async () => {
    const persisted = [];
    const calls = [];
    const outcome = await executeCommandSequence(
      [{ id: "one" }, { id: "two" }, { id: "three" }],
      async (spec) => {
        calls.push(spec.id);
        return { exitCode: spec.id === "two" ? 1 : 0 };
      },
      async (snapshot) => { persisted.push(snapshot.status); },
    );
    assert.equal(outcome.status, "failed");
    assert.deepEqual(calls, ["one", "two"]);
    assert.equal(persisted.at(-1), "failed");
  });

  test("executeCommandSequence reports passed only when every command exits zero", async () => {
    const outcome = await executeCommandSequence(
      [{ id: "one" }, { id: "two" }],
      async () => ({ exitCode: 0 }),
      async () => {},
    );
    assert.equal(outcome.status, "passed");
    assert.equal(outcome.commands.length, 2);
  });

  test("manifestFreshnessCode compares the checked-in phase252 manifest", () => {
    assert.match(manifestFreshnessCode(), /storybook\/phase252-manifest\.json/);
  });
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    process.stderr.write("verify_phase252_stories: " + error.message + "\n");
    process.exitCode = 2;
  });
}
