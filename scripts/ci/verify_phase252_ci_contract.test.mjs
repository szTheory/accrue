#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { executeCommandSequence, manifestFreshnessCode, REQUIRED_COMMAND_IDS } from "./verify_phase252_stories.mjs";
import { PHASE252_REPORTER_SPECS, requiredAssertionIds } from "./phase252_reporters.mjs";
import {
  assertCiContract,
  assertOwnerMap,
  classifyPath,
  CONSUMED_ROOTS,
  REQUIRED_OWNER,
} from "./phase252_paths.mjs";
import * as phase253Runner from "./verify_phase253_compositions.mjs";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(new URL(import.meta.url).pathname), "../.."));
const workflow = fs.readFileSync(path.join(root, ".github/workflows/ci.yml"), "utf8");
const ownerRunner = fs.readFileSync(path.join(root, "scripts/ci/verify_phase200_admin_guardrails.sh"), "utf8");
const manifest = JSON.parse(fs.readFileSync(path.join(root, "storybook/phase252-manifest.json"), "utf8"));

const positivePaths = [
  "storybook/components/subscription_detail.story.exs",
  "storybook/phase252-manifest.json",
  "dev_support/ui_scenarios/cadence_subscriptions.exs",
  "accrue_admin/storybook/_support/subscription_scenarios.ex",
  "accrue_admin/lib/accrue_admin/components/detail.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/copy.ex",
  "accrue_admin/lib/accrue_admin/copy/subscription.ex",
  "accrue_admin/lib/accrue_admin/scoped_path.ex",
  "accrue_admin/lib/accrue_admin/dev/component_registry.ex",
  "accrue_admin/assets/css/theme.css",
  "accrue_admin/assets/css/app.css",
  "accrue_admin/priv/static/accrue_admin.css",
  "accrue_admin/priv/static/storybook.css",
  "brandbook/tokens/tokens.css",
  "accrue_admin/e2e/subscription-stories-phase252.spec.js",
  "accrue_admin/playwright.phase252.config.js",
  ".github/workflows/accrue_admin_browser.yml",
  "accrue_admin/test/accrue_admin/dev/component_registry_test.exs",
  "accrue_admin/test/accrue_admin/live/subscription_live_test.exs",
  "scripts/dev/phase252_lab.mjs",
  "scripts/dev/phase252_isolation.test.mjs",
  "scripts/ci/generate_phase252_acceptance.mjs",
  "scripts/ci/verify_phase252_production_boundary.mjs",
  "scripts/ci/verify_phase252_stories.mjs",
  "scripts/ci/verify_phase200_guardrail_contract.sh",
];

test("every consumed source root maps to the named required CI owner", () => {
  assertOwnerMap(CONSUMED_ROOTS, manifest);
  for (const rule of CONSUMED_ROOTS) {
    const representative = rule.mode === "prefix" && rule.path.endsWith("/")
      ? `${rule.path}representative`
      : rule.path;
    assert.equal(classifyPath(representative, { manifest }), REQUIRED_OWNER, rule.id);
  }
  for (const sourcePath of positivePaths) {
    assert.equal(classifyPath(sourcePath, { manifest }), REQUIRED_OWNER, sourcePath);
  }
  for (const sourcePath of Object.keys(manifest.source_digests)) {
    assert.equal(classifyPath(sourcePath, { manifest }), REQUIRED_OWNER, sourcePath);
  }
});

test("unrelated docs are not focused while unconditional required CI still admits them", () => {
  assert.equal(classifyPath("docs/architecture/unrelated.md", { manifest }), null);
  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner, manifest }));
});

test("pull_request admission rejects path filters and exclusions", () => {
  const filtered = workflow.replace(
    "  pull_request:\n    branches: [main]",
    "  pull_request:\n    branches: [main]\n    paths-ignore:\n      - 'docs/**'",
  );
  assert.throws(() => assertCiContract({ workflow: filtered, ownerRunner, manifest }), /path/i);

  const pathLimited = workflow.replace(
    "  pull_request:\n    branches: [main]",
    "  pull_request:\n    branches: [main]\n    paths:\n      - 'accrue_admin/**'",
  );
  assert.throws(() => assertCiContract({ workflow: pathLimited, ownerRunner, manifest }), /path/i);
});

test("the named required job cannot be skipped or made optional", () => {
  const skipped = workflow.replace(
    "  admin-phase200-guardrails:\n    name: Admin Phase 200 deterministic guardrails\n    if: github.event_name != 'schedule'",
    "  admin-phase200-guardrails:\n    name: Admin Phase 200 deterministic guardrails\n    if: false",
  );
  assert.throws(() => assertCiContract({ workflow: skipped, ownerRunner, manifest }), /skip|if/i);

  const optional = workflow.replace(
    "  admin-phase200-guardrails:\n    name: Admin Phase 200 deterministic guardrails\n    if: github.event_name != 'schedule'",
    "  admin-phase200-guardrails:\n    name: Admin Phase 200 deterministic guardrails\n    if: github.event_name != 'schedule'\n    continue-on-error: true",
  );
  assert.throws(() => assertCiContract({ workflow: optional, ownerRunner, manifest }), /optional|continue-on-error/i);
});

test("the workflow and runner chain must retain the named owner invocation", () => {
  const missingOwner = workflow.replace("bash scripts/ci/verify_phase200_admin_guardrails.sh", "bash scripts/ci/other-check.sh");
  assert.throws(() => assertCiContract({ workflow: missingOwner, ownerRunner, manifest }), /owner|runner|verify_phase200_admin_guardrails/i);
});

test("a phase252 invocation fixture is required when the focused leaf is enabled", () => {
  const runnerFixture = `${ownerRunner}\nrun_step "Phase 252" npm --prefix accrue_admin run phase252:check\n`;
  const missingRunner = ownerRunner.replace(/^run_step "Phase 252 complete subscription story acceptance".*\n/m, "");
  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner: runnerFixture, manifest, requirePhase252: true }));
  assert.throws(() => assertCiContract({ workflow, ownerRunner: missingRunner, manifest, requirePhase252: true }), /phase252:check/i);
});

test("the real required owner invokes the complete phase252 leaf", () => {
  assert.equal(ownerRunner.includes("npm --prefix accrue_admin run phase252:check"), true);
  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner, manifest, requirePhase252: true }));
  const packageJson = JSON.parse(fs.readFileSync(path.join(root, "accrue_admin/package.json"), "utf8"));
  assert.equal(packageJson.scripts["phase252:check"], "node ../scripts/ci/verify_phase252_stories.mjs");
});

test("every newly consumed Phase 253 source class maps to the named required CI owner", () => {
  const phase253Roots = [
    ["phase253-collection-renderer", "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex"],
    ["phase253-focused-runner", "scripts/ci/verify_phase253_compositions.mjs"],
    ["phase253-focused-runner-tests", "scripts/ci/verify_phase253_compositions.test.mjs"],
    ["phase253-acceptance-generator", "scripts/ci/generate_phase253_acceptance.mjs"],
    ["phase253-transparency-fixtures", "scripts/ci/fixtures/phase253-transparency/presentation-violation.json"],
    ["phase253-prohibition-plan", ".planning/phases/253-real-groups-and-a-whole-subscription-job/253-05-PLAN.md"],
    ["phase253-validation", ".planning/phases/253-real-groups-and-a-whole-subscription-job/253-VALIDATION.md"],
    ["phase253-collection-story", "storybook/groups/subscriptions_collection.story.exs"],
    ["phase253-whole-page-story", "storybook/pages/subscription.story.exs"],
    ["phase253-admin-adapters", "accrue_admin/storybook/_support/subscription_collection.ex"],
    ["phase253-admin-tests", "accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs"],
    ["phase253-browser-spec", "accrue_admin/e2e/subscription-compositions-phase253.spec.js"],
    ["phase253-browser-helper", "accrue_admin/e2e/phase253-composition-helpers.js"],
    ["phase253-presentation-controls", "scripts/ci/verify_phase253_presentation.test.mjs"],
  ];
  assertOwnerMap(CONSUMED_ROOTS, manifest);
  for (const [id, sourcePath] of phase253Roots) {
    assert.equal(CONSUMED_ROOTS.some((row) => row.id === id), true, `${id} must be required`);
    assert.equal(classifyPath(sourcePath, { manifest }), REQUIRED_OWNER, `${sourcePath} must be admitted`);
  }
  for (const [id, sourcePath] of phase253Roots.slice(0, 7)) {
    const withoutRule = CONSUMED_ROOTS.filter((row) => row.id !== id);
    assert.throws(() => assertOwnerMap(withoutRule, manifest), new RegExp(id), `${id} removal must fail the owner contract`);
    assert.equal(classifyPath(sourcePath, { roots: withoutRule, manifest }), null, `${sourcePath} must become unowned when ${id} is removed`);
  }
  assert.equal(classifyPath("docs/architecture/unrelated-phase253.md", { manifest }), null);
});

test("the named required owner invokes both Phase 252 and Phase 253 checks", () => {
  const missingPhase253 = ownerRunner.replace(/^run_step "Phase 253 focused composition acceptance".*\n/m, "");
  assert.throws(
    () => assertCiContract({ workflow, ownerRunner: missingPhase253, manifest, requirePhase252: true, requirePhase253: true }),
    /phase253|composition acceptance/i,
  );

  const phase253BeforePhase252 = ownerRunner.replace(
    /^run_step "Phase 252 complete subscription story acceptance".*\n/m,
    "",
  ).replace(
    "run_step \"Phase 253 focused composition acceptance\" node scripts/ci/verify_phase253_compositions.mjs\n",
    "",
  ) + "run_step \"Phase 253 focused composition acceptance\" node scripts/ci/verify_phase253_compositions.mjs\nrun_step \"Phase 252 complete subscription story acceptance\" npm --prefix accrue_admin run phase252:check\n";
  assert.throws(
    () => assertCiContract({ workflow, ownerRunner: phase253BeforePhase252, manifest, requirePhase252: true, requirePhase253: true }),
    /phase252|phase253|order/i,
  );

  const gatedPhase253 = ownerRunner.replace(
    'run_step "Phase 253 focused composition acceptance" node scripts/ci/verify_phase253_compositions.mjs',
    'if [ "${RUN_PHASE253:-false}" = true ]; then run_step "Phase 253 focused composition acceptance" node scripts/ci/verify_phase253_compositions.mjs; fi',
  );
  assert.throws(
    () => assertCiContract({ workflow, ownerRunner: gatedPhase253, manifest, requirePhase252: true, requirePhase253: true }),
    /phase253|composition acceptance/i,
  );

  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner, manifest, requirePhase252: true, requirePhase253: true }));
});

test("the Phase 253 CI reporter requires every owner, path and unrelated-path assertion", () => {
  const command = phase253Runner.buildCommandPlan({
    id: "b".repeat(32),
    adminBuildPath: "/tmp/phase253-ci-contract/admin",
    outputDirectory: "/tmp/phase253-ci-contract/output",
  }).find(({ id }) => id === "phase253-ci-contract");
  assert.deepEqual(Object.keys(command.assertion_bindings).sort(), [
    "new_root_admission",
    "required_owner_execution",
    "unrelated_path_negative_control",
  ]);

  const missingAssertion = phase253Runner.buildCommandPlan({
    id: "b".repeat(32),
    adminBuildPath: "/tmp/phase253-ci-contract/admin",
    outputDirectory: "/tmp/phase253-ci-contract/output",
  }).map((row) => row.id === "phase253-ci-contract"
    ? { ...row, assertion_bindings: Object.fromEntries(Object.entries(row.assertion_bindings).filter(([id]) => id !== "new_root_admission")) }
    : row);
  assert.throws(() => phase253Runner.assertRequiredCommandPlan(missingAssertion), /assertion|binding/i);
});

test("manifest freshness compares JSON content without serializer key-order noise", () => {
  const code = manifestFreshnessCode();
  assert.match(code, /Jason\.decode!\(generated\) != Jason\.decode!\(checked_in\)/);
});

test("a failed phase command stops the gate and cannot produce passing evidence", async () => {
  const calls = [];
  const savedStatuses = [];
  const result = await executeCommandSequence(
    [{ id: "failing-lane" }, { id: "must-not-run" }],
    async (command) => {
      calls.push(command.id);
      return { exitCode: command.id === "failing-lane" ? 1 : 0 };
    },
    async (bundle) => savedStatuses.push(bundle.status),
  );
  assert.deepEqual(calls, ["failing-lane"]);
  assert.equal(result.status, "failed");
  assert.equal(savedStatuses.includes("passed"), false);
});

test("a missing owner root fails closed instead of becoming unrelated", () => {
  const omitted = CONSUMED_ROOTS.filter((entry) => entry.id !== "brandbook-tokens");
  assert.throws(
    () => assertOwnerMap(omitted, manifest),
    /brandbook-tokens|missing|consumed/i,
  );
  assert.equal(classifyPath("brandbook/tokens/tokens.css", { roots: omitted, manifest }), null);
});

const expectedCommandIds = [
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
];

const runner = await import("./verify_phase252_stories.mjs");

test("required phase owner admits both transparency checks and their controls before final acceptance", () => {
  assert.deepEqual(REQUIRED_COMMAND_IDS, expectedCommandIds);
  assert.equal(typeof runner.buildCommandPlan, "function");
  assert.equal(typeof runner.assertRequiredCommandPlan, "function");

  const plan = runner.buildCommandPlan({
    id: "25210-contract-test",
    adminBuildPath: "/tmp/phase252-contract/admin",
    hostBuildPath: "/tmp/phase252-contract/host",
    outputDirectory: "/tmp/phase252-contract/output",
  });
  assert.deepEqual(plan.map(({ id }) => id), expectedCommandIds);
  assert.deepEqual(plan.find(({ id }) => id === "lab-presentation").args.slice(-1), ["scripts/ci/verify_phase252_lab_presentation.test.mjs"]);
  assert.deepEqual(plan.find(({ id }) => id === "heldout-attribution").args.slice(-1), ["scripts/ci/verify_phase252_heldout_attribution.test.mjs"]);
  assert.deepEqual(plan.find(({ id }) => id === "transparency-controls").args, ["scripts/ci/verify_phase252_transparency.mjs", "--self-test"]);
  assert.doesNotThrow(() => runner.assertRequiredCommandPlan(plan));

  for (const id of ["lab-presentation", "heldout-attribution", "transparency-controls"]) {
    assert.throws(() => runner.assertRequiredCommandPlan(plan.filter((row) => row.id !== id)), /required command|lane/i, `removing ${id} must fail closed`);
  }
});

test("new reporter lanes bind named target assertions and six independent control markers", () => {
  assert.deepEqual(PHASE252_REPORTER_SPECS["lab-presentation"], {
    kind: "node-tap",
    testFiles: ["scripts/ci/verify_phase252_lab_presentation.test.mjs"],
  });
  assert.deepEqual(PHASE252_REPORTER_SPECS["heldout-attribution"], {
    kind: "node-tap",
    testFiles: ["scripts/ci/verify_phase252_heldout_attribution.test.mjs"],
  });
  assert.deepEqual(requiredAssertionIds("lab-presentation"), ["lab_static_limits", "lab_contradiction_controls"]);
  assert.deepEqual(requiredAssertionIds("heldout-attribution"), ["heldout_synthetic_attribution", "heldout_contradiction_controls"]);
  assert.deepEqual(requiredAssertionIds("transparency-controls"), [
    "lab_static_current_green",
    "lab_static_clean_green",
    "lab_static_violation_red",
    "heldout_synthetic_current_green",
    "heldout_synthetic_clean_green",
    "heldout_synthetic_violation_red",
  ]);

  const result = spawnSync(process.execPath, ["scripts/ci/verify_phase252_transparency.mjs", "--self-test"], {
    cwd: root,
    encoding: "utf8",
    timeout: 20_000,
  });
  assert.equal(result.status, 0, result.stderr);
  for (const marker of requiredAssertionIds("transparency-controls")) {
    assert.ok(result.stdout.split(/\r?\n/).includes(`PHASE252_ASSERTION=${marker}`), `missing executed control marker ${marker}`);
  }
});

test("all transparency and original descriptor inputs are fresh, owner-classified sources", () => {
  const sourcePaths = [
    "scripts/ci/verify_phase252_transparency.mjs",
    "scripts/ci/phase_evidence_path.mjs",
    "scripts/ci/verify_phase252_lab_presentation.test.mjs",
    "scripts/ci/verify_phase252_heldout_attribution.test.mjs",
    "scripts/ci/fixtures/phase252-transparency/lab-clean.json",
    "scripts/ci/fixtures/phase252-transparency/lab-violation.json",
    "scripts/ci/fixtures/phase252-transparency/heldout-clean.json",
    "scripts/ci/fixtures/phase252-transparency/heldout-violation.json",
    "guides/ui-story-lab.md",
    "storybook/components/subscription_detail.story.exs",
    "storybook/phase252-manifest.json",
    "dev_support/ui_scenarios/cadence_subscriptions.exs",
    "accrue_admin/storybook/_support/subscription_scenarios.ex",
    "accrue_admin/e2e/phase252-story-helpers.js",
    ".planning/phases/252-production-backed-subscription-stories/252-01-PLAN.md",
    ".planning/phases/252-production-backed-subscription-stories/252-04-PLAN.md",
    ...Array.from({ length: 10 }, (_, index) => `.planning/phases/252-production-backed-subscription-stories/252-${String(index + 1).padStart(2, "0")}-PLAN.md`),
    ".planning/phases/252-production-backed-subscription-stories/252-VALIDATION.md",
  ];
  assert.equal(typeof runner.buildCommandPlan, "function");
  assert.equal(typeof runner.sourceSnapshot, "function");
  const plan = runner.buildCommandPlan({
    id: "25210-source-contract",
    adminBuildPath: "/tmp/phase252-contract/admin",
    hostBuildPath: "/tmp/phase252-contract/host",
    outputDirectory: "/tmp/phase252-contract/output",
  });
  const laneSources = new Set(plan.flatMap(({ sources }) => sources));
  const snapshot = runner.sourceSnapshot(root, manifest, [...laneSources]);
  for (const source of sourcePaths) {
    assert.ok(laneSources.has(source), `command plan must declare ${source}`);
    assert.ok(snapshot.paths.includes(source), `snapshot must fingerprint ${source}`);
    assert.equal(typeof snapshot.digests[source], "string", `source digest is missing for ${source}`);
    assert.equal(classifyPath(source, { manifest }), REQUIRED_OWNER, `source is not assigned to ${REQUIRED_OWNER}`);
  }
});

test("new consumed roots have positive paths and fail when their admission rule is removed", () => {
  const newRoots = [
    ...[2, 3, 5, 6, 7, 8, 9, 10].map((number) => [`phase252-acceptance-plan-${number}`, `.planning/phases/252-production-backed-subscription-stories/252-${String(number).padStart(2, "0")}-PLAN.md`]),
    ["phase252-validation-accounting", ".planning/phases/252-production-backed-subscription-stories/252-VALIDATION.md"],
    ["phase252-transparency-fixtures", "scripts/ci/fixtures/phase252-transparency/lab-clean.json"],
    ["phase252-transparency-guide", "guides/ui-story-lab.md"],
    ["phase252-transparency-reporters", "scripts/ci/phase252_reporters.mjs"],
    ["phase252-evidence-resolver", "scripts/ci/phase_evidence_path.mjs"],
    ["phase252-lab-prohibition-plan", ".planning/phases/252-production-backed-subscription-stories/252-01-PLAN.md"],
    ["phase252-heldout-prohibition-plan", ".planning/phases/252-production-backed-subscription-stories/252-04-PLAN.md"],
  ];
  assertOwnerMap(CONSUMED_ROOTS, manifest);
  for (const [id, representative] of newRoots) {
    assert.equal(CONSUMED_ROOTS.some((row) => row.id === id), true, `${id} must be required`);
    assert.equal(classifyPath(representative, { manifest }), REQUIRED_OWNER, `${representative} must be admitted`);
    const withoutRule = CONSUMED_ROOTS.filter((row) => row.id !== id);
    assert.throws(() => assertOwnerMap(withoutRule, manifest), new RegExp(id), `${id} removal must fail the owner contract`);
    assert.equal(classifyPath(representative, { roots: withoutRule, manifest }), null, `${representative} must become unowned when ${id} is removed`);
  }
});

test("an omitted or failed transparency child cannot produce a passing sequence", async () => {
  assert.equal(typeof runner.assertRequiredCommandPlan, "function");
  const plan = expectedCommandIds.map((id) => ({ id }));
  assert.throws(() => runner.assertRequiredCommandPlan(plan.filter(({ id }) => id !== "heldout-attribution")), /required command|lane/i);

  const calls = [];
  const statuses = [];
  const result = await executeCommandSequence(
    plan,
    async ({ id }) => {
      calls.push(id);
      return { exitCode: id === "heldout-attribution" ? 1 : 0 };
    },
    async ({ status }) => statuses.push(status),
  );
  assert.equal(result.status, "failed");
  assert.equal(statuses.includes("passed"), false);
  assert.equal(calls.at(-1), "heldout-attribution");
  assert.equal(calls.includes("transparency-controls"), false);
});

test("Phase 252 CI reporter includes imported module-boundary tests", () => {
  assert.deepEqual(PHASE252_REPORTER_SPECS["phase252-ci-contract"].testFiles, [
    "scripts/ci/verify_phase252_ci_contract.test.mjs",
    "scripts/ci/main_module.mjs",
  ]);
  const plan = runner.buildCommandPlan({
    id: "25210-reporter-source-test",
    adminBuildPath: "/tmp/phase252-reporter/admin",
    hostBuildPath: "/tmp/phase252-reporter/host",
    outputDirectory: "/tmp/phase252-reporter/output",
  });
  assert.ok(plan.find(({ id }) => id === "phase252-ci-contract").sources.includes("scripts/ci/phase252_reporters.mjs"));
});
