// Phase 254 CIQ-03 (D-20, D-06, D-19): a mutation contract over the visual baseline owner.
//
// The real files must pass; every mutation below must fail the contract with its own message. A
// contract that only ever sees the passing files proves nothing, so each rule has a seeded violation.
// Baselines are minted by the workflow_dispatch mint job only, never locally, never from macOS.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const read = (relative) => fs.readFileSync(path.join(ROOT, relative), "utf8");

const WORKFLOW_PATH = ".github/workflows/accrue_admin_browser.yml";
const CONFIG_PATH = "accrue_admin/playwright.config.js";
const NEW_SPEC_PATH = "accrue_admin/e2e/subscription-visual-phase254.spec.js";
const LEGACY_SPEC_PATH = "accrue_admin/e2e/admin-visual-regression-phase211.spec.js";
const MINT_JOB = "visual-baselines-mint";
const GATE_JOB = "browser-uat";
const TRIGGER_PATHS = ["storybook/**", "dev_support/ui_scenarios/**", "brandbook/tokens/**", "scripts/ci/phase254_*"];

const stripComments = (text) => text.split("\n").filter((line) => !/^\s*#/.test(line)).join("\n");

// The text of one job: from its `  <name>:` key to the next two-space key (or the end).
export function jobBlock(workflow, name) {
  const lines = stripComments(workflow).split("\n");
  const start = lines.findIndex((line) => line === `  ${name}:`);
  if (start < 0) throw new Error(`workflow has no job ${name}`);
  let end = lines.length;
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^ {2}[A-Za-z0-9_-]+:\s*$/.test(lines[index])) { end = index; break; }
  }
  return lines.slice(start, end).join("\n");
}

function steps(block) {
  return block.split(/\n(?=      - )/).filter((chunk) => chunk.startsWith("      - ")).map((chunk) => chunk.trimEnd());
}

function onBlock(workflow, event) {
  const text = stripComments(workflow);
  const match = text.match(new RegExp(`^  ${event}:\\n([\\s\\S]*?)(?=^  [a-z_]+:|^[a-z]+:)`, "m"));
  if (!match) throw new Error(`workflow has no ${event} trigger`);
  return match[1];
}

export function assertVisualContract({ workflow, config, newSpec, legacySpec, allWorkflows = [] }) {
  const clean = stripComments(workflow);
  const mint = jobBlock(workflow, MINT_JOB);
  const gate = jobBlock(workflow, GATE_JOB);

  // 1. --pre-mint is a local-only flag: no workflow step may pass it.
  for (const text of [workflow, ...allWorkflows]) {
    if (/--pre-mint/.test(stripComments(text))) throw new Error("--pre-mint must not appear in any workflow step");
  }

  // 2. --update-snapshots exists only in the mint job.
  if (/--update-snapshots/.test(gate)) throw new Error("--update-snapshots must appear only in the mint job");
  const outside = clean.replace(mint, "");
  if (/--update-snapshots/.test(outside)) throw new Error("--update-snapshots must appear only in the mint job");
  const flags = [...mint.matchAll(/--update-snapshots(=[a-z]+)?/g)].map((match) => match[1] ?? "");
  if (!flags.includes("=changed")) throw new Error("the mint job must pass --update-snapshots=changed");
  if (flags.some((flag) => flag !== "=changed" && flag !== "=none")) throw new Error("every --update-snapshots in the mint job must be =changed or =none (a bare or =all flag rewrites every baseline)");

  // 3. Minted baselines are uploaded only on success.
  const uploads = steps(mint).filter((step) => /actions\/upload-artifact/.test(step));
  if (uploads.length === 0) throw new Error("the mint job must upload the minted baselines");
  for (const upload of uploads) {
    if (/if:\s*(?:always|failure|cancelled)\(\)/.test(upload)) throw new Error("the minted baselines must not upload on always()");
    if (!/^\s+if:\s*success\(\)\s*$/m.test(upload)) throw new Error("the minted baselines must upload only if: success()");
  }

  // 4. Stability proof, identity manifest build and the manifest-backed set check run in the mint job.
  if (!/subscription-visual-phase254\.spec\.js[^\n]*--repeat-each=3/.test(mint)) throw new Error("the mint job must prove stability with --repeat-each=3 on the new spec");
  if (!/phase254_visual_manifest\.mjs build/.test(mint)) throw new Error("the mint job must build the identity manifest");
  if (!/fetch-depth:\s*0/.test(mint)) throw new Error("the mint job needs fetch-depth 0");

  // 5. The gate job checks the manifest, after the set guard and before the pixel gate, with full history.
  const gateSteps = steps(gate).map((step) => step);
  const indexOf = (pattern) => gateSteps.findIndex((step) => pattern.test(step));
  const guardAt = indexOf(/visual-baseline-set\.cjs/);
  const manifestAt = indexOf(/phase254_visual_manifest\.mjs check --base/);
  const gateAt = indexOf(/npm run e2e:visual-regression/);
  if (manifestAt < 0) throw new Error("the browser-uat job must run the visual manifest check step");
  if (!(guardAt >= 0 && guardAt < manifestAt && manifestAt < gateAt)) throw new Error("the manifest check must run after the set guard and before the visual regression gate");
  if (!/fetch-depth:\s*0/.test(gate)) throw new Error("the browser-uat job needs fetch-depth 0 for the merge-base");
  if (/visual-baseline-set\.cjs[^\n]*--pre-mint/.test(gate)) throw new Error("the browser workflow guard must run without --pre-mint");

  // 6. RESEARCH F3: the browser workflow also triggers on the Phase 254 inputs, on both events.
  for (const event of ["pull_request", "push"]) {
    const block = onBlock(workflow, event);
    for (const trigger of TRIGGER_PATHS) {
      if (!block.includes(`"${trigger}"`)) throw new Error(`the ${event} trigger lacks the path ${trigger}`);
    }
  }

  // 7. D-06: thresholds are pinned in the config, with no per-call widening and no retries.
  if (!/threshold:\s*0\.2\b/.test(config)) throw new Error("the screenshot threshold must stay 0.2");
  if (!/maxDiffPixelRatio:\s*0\.01\b/.test(config)) throw new Error("maxDiffPixelRatio must stay 0.01");
  if (/\bretries\s*:/.test(config) || /--retries/.test(clean)) throw new Error("no retries are allowed for the visual gate");

  // 8. D-19: no stylePath anywhere in the visual specs or the config.
  for (const text of [config, newSpec, legacySpec]) {
    if (/\bstylePath\b/.test(text)) throw new Error("a stylePath option is not allowed");
  }

  // 9. The new spec's screenshot call is strict, with an empty mask allowlist, and nothing can switch it off.
  const calls = [...newSpec.matchAll(/toHaveScreenshot\(([^)]*)\)/g)].map((match) => match[1]);
  if (calls.length === 0) throw new Error("the new spec must call toHaveScreenshot");
  for (const call of calls) {
    if (!/maxDiffPixels:\s*0\b/.test(call)) throw new Error("the new spec's toHaveScreenshot call must pin maxDiffPixels: 0");
    if (!/mask:\s*\[\s*\]/.test(call)) throw new Error("the new spec's toHaveScreenshot call must carry an empty mask allowlist");
  }
  if (/process\.env\.[A-Z0-9_]*(?:SKIP|SCREENSHOT|UPDATE)/.test(newSpec)) throw new Error("no environment flag may disable or rewrite the screenshot assertion");
  return true;
}

const real = () => ({
  workflow: read(WORKFLOW_PATH),
  config: read(CONFIG_PATH),
  newSpec: read(NEW_SPEC_PATH),
  legacySpec: read(LEGACY_SPEC_PATH),
  allWorkflows: fs.readdirSync(path.join(ROOT, ".github/workflows")).filter((name) => /\.ya?ml$/.test(name)).map((name) => read(`.github/workflows/${name}`)),
});

function mutate(target, edit) {
  const inputs = real();
  const before = inputs[target];
  inputs[target] = edit(before);
  assert.notEqual(inputs[target], before, "the mutation must change the file (a no-op mutation proves nothing)");
  return inputs;
}

test("the real workflow, config and specs satisfy the visual contract", () => {
  assert.equal(assertVisualContract(real()), true);
});

test("the contract can find a defect: --pre-mint in a workflow step is rejected", () => {
  assert.throws(
    () => assertVisualContract(mutate("workflow", (text) => text.replace("visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop\n", "visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop --pre-mint\n"))),
    /--pre-mint must not appear/,
  );
  assert.throws(() => assertVisualContract({ ...real(), allWorkflows: ["jobs:\n  x:\n    steps:\n      - run: node a.cjs dir --pre-mint\n"] }), /--pre-mint must not appear/);
});

test("--update-snapshots outside the mint job is rejected", () => {
  assert.throws(
    () => assertVisualContract(mutate("workflow", (text) => text.replace("run: cd accrue_admin && npm run e2e:visual-regression\n", "run: cd accrue_admin && npm run e2e:visual-regression -- --update-snapshots=changed\n"))),
    /--update-snapshots must appear only in the mint job/,
  );
});

test("a mint without =changed, with a bare flag or with =all is rejected", () => {
  const changed = "npm run e2e:visual-regression -- --update-snapshots=changed";
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace(changed, "npm run e2e:visual-regression -- --update-snapshots"))), /must pass --update-snapshots=changed|bare or =all/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace(changed, "npm run e2e:visual-regression -- --update-snapshots=all"))), /must pass --update-snapshots=changed/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("--update-snapshots=none --grep", "--update-snapshots=all --grep"))), /bare or =all/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace(changed, "npm run e2e:visual-regression"))), /must pass --update-snapshots=changed/);
});

test("an upload that is always() or has no success() condition is rejected", () => {
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("        if: success()\n        uses: actions/upload-artifact@v7\n        with:\n          name: phase211-visual-baselines", "        if: always()\n        uses: actions/upload-artifact@v7\n        with:\n          name: phase211-visual-baselines"))), /must not upload on always\(\)/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("        if: success()\n        uses: actions/upload-artifact@v7\n        with:\n          name: phase211-visual-baselines", "        uses: actions/upload-artifact@v7\n        with:\n          name: phase211-visual-baselines"))), /only if: success\(\)/);
});

test("a mint job without the stability proof, the manifest build or full history is rejected", () => {
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("--repeat-each=3", "--repeat-each=1"))), /--repeat-each=3/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("phase254_visual_manifest.mjs build", "phase254_visual_manifest.mjs verify"))), /build the identity manifest/);
  const mintStart = real().workflow.indexOf(`  ${MINT_JOB}:`);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.slice(0, mintStart) + text.slice(mintStart).replace("          fetch-depth: 0\n", ""))), /mint job needs fetch-depth 0/);
});

test("removing the manifest check step, or moving it after the pixel gate, is rejected", () => {
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace(/      - name: Check visual baseline identity manifest\n        run: [^\n]*\n\n/, ""))), /must run the visual manifest check step/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => {
    const step = text.match(/      - name: Check visual baseline identity manifest\n        run: [^\n]*\n\n/)[0];
    return text.replace(step, "").replace("      - name: Upload Phase 254 machine evidence", `${step}      - name: Upload Phase 254 machine evidence`);
  })), /after the set guard and before the visual regression gate/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace("          # The identity manifest check needs the merge-base with the default branch.\n          fetch-depth: 0\n", ""))), /browser-uat job needs fetch-depth 0/);
});

test("a missing F3 trigger path on either event is rejected", () => {
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace('      - "storybook/**"\n', ""))), /lacks the path storybook\/\*\*/);
  assert.throws(() => assertVisualContract(mutate("workflow", (text) => text.replace(/(  push:[\s\S]*?)      - "scripts\/ci\/phase254_\*"\n/, "$1"))), /push trigger lacks the path scripts\/ci\/phase254_\*/);
});

test("a widened threshold or maxDiffPixelRatio, a retries key and a stylePath are rejected", () => {
  assert.throws(() => assertVisualContract(mutate("config", (text) => text.replace("threshold: 0.2,", "threshold: 0.3,"))), /threshold must stay 0\.2/);
  assert.throws(() => assertVisualContract(mutate("config", (text) => text.replace("maxDiffPixelRatio: 0.01,", "maxDiffPixelRatio: 0.05,"))), /maxDiffPixelRatio must stay 0\.01/);
  assert.throws(() => assertVisualContract(mutate("config", (text) => text.replace("  workers: 1,", "  workers: 1,\n  retries: 2,"))), /no retries/);
  assert.throws(() => assertVisualContract(mutate("config", (text) => text.replace("  outputDir\n", "  outputDir,\n  stylePath: './mask.css'\n"))), /stylePath/);
  assert.throws(() => assertVisualContract(mutate("newSpec", (text) => text.replace("{ maxDiffPixels: 0, mask: [] }", "{ maxDiffPixels: 0, mask: [], stylePath: 'x.css' }"))), /stylePath/);
  assert.throws(() => assertVisualContract(mutate("legacySpec", (text) => text.replace("maskColor: \"#FF00FF\"", "maskColor: \"#FF00FF\", stylePath: 'x.css'"))), /stylePath/);
});

test("a looser new-spec screenshot call (a ratio instead of 0 pixels, a non-empty mask, an env switch) is rejected", () => {
  assert.throws(() => assertVisualContract(mutate("newSpec", (text) => text.replace("{ maxDiffPixels: 0, mask: [] }", "{ maxDiffPixels: 50, mask: [] }"))), /maxDiffPixels: 0/);
  assert.throws(() => assertVisualContract(mutate("newSpec", (text) => text.replace("{ maxDiffPixels: 0, mask: [] }", "{ maxDiffPixels: 0, mask: [page.locator('time')] }"))), /empty mask allowlist/);
  assert.throws(() => assertVisualContract(mutate("newSpec", (text) => `${text}\nif (process.env.PHASE254_SKIP_SCREENSHOT) { /* never */ }\n`)), /no environment flag/);
});

test("jobBlock isolates exactly one job and ignores YAML comments (positive control for the scanner)", () => {
  const { workflow } = real();
  const mint = jobBlock(workflow, MINT_JOB);
  assert.match(mint, /--update-snapshots=changed/);
  assert.doesNotMatch(mint, /Run browser UAT/);
  assert.doesNotMatch(jobBlock(workflow, GATE_JOB), /--update-snapshots/);
  assert.doesNotMatch(stripComments("# --pre-mint in a comment\nrun: x\n"), /--pre-mint/);
  assert.throws(() => jobBlock(workflow, "no-such-job"), /no job/);
});
