#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { executeCommandSequence } from "./verify_phase252_stories.mjs";
import {
  assertCiContract,
  assertOwnerMap,
  classifyPath,
  CONSUMED_ROOTS,
  REQUIRED_OWNER,
} from "./phase252_paths.mjs";

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
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
  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner: runnerFixture, manifest, requirePhase252: true }));
  assert.throws(() => assertCiContract({ workflow, ownerRunner, manifest, requirePhase252: true }), /phase252:check/i);
});

test("the real required owner invokes the complete phase252 leaf", () => {
  assert.equal(ownerRunner.includes("npm --prefix accrue_admin run phase252:check"), true);
  assert.doesNotThrow(() => assertCiContract({ workflow, ownerRunner, manifest, requirePhase252: true }));
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
