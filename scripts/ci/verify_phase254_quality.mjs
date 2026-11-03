#!/usr/bin/env node

// Serial required-owner checks for the Phase 254 quality records. Keep each command named so a
// failure identifies the stale record without hiding it behind a generic aggregate result.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

export const QUALITY_CHECKS = Object.freeze([
  Object.freeze({ name: "selection projection freshness", args: ["scripts/ci/phase254_selection.mjs", "project", "--check"] }),
  Object.freeze({ name: "curation ledger", args: ["scripts/ci/verify_phase254_curation.mjs"] }),
  Object.freeze({ name: "a11y dispositions against latest results", args: ["scripts/ci/verify_a11y_dispositions.mjs", "--results-latest"] }),
  Object.freeze({ name: "confirmed design review", args: ["scripts/ci/verify_phase254_design_review.mjs", "--check", "--stage", "confirmed"] }),
  Object.freeze({ name: "Storybook CSS recomposition", args: ["scripts/ci/recompose_storybook_css.mjs", "--check"] }),
]);

/** Run each Phase 254 record check in order and fail at the first named command. */
export function runQualityChecks({
  checks = QUALITY_CHECKS,
  runCommand = (check) => spawnSync(process.execPath, check.args, { cwd: ROOT, encoding: "utf8" }),
  onStep = () => {},
} = {}) {
  const completed = [];
  for (const check of checks) {
    onStep(check);
    const result = runCommand(check);
    if (result?.status !== 0) {
      const detail = [result?.stdout, result?.stderr, result?.error?.message]
        .filter((value) => typeof value === "string" && value.trim() !== "")
        .join("\n")
        .trim();
      throw new Error(`Phase 254 quality: ${check.name} failed (exit ${result?.status ?? "unknown"})${detail ? `\n${detail}` : ""}`);
    }
    completed.push(check.name);
  }
  return completed;
}

test("the required Phase 254 quality checks run serially in their declared order", () => {
  const calls = [];
  const completed = runQualityChecks({ runCommand: (check) => { calls.push(check.name); return { status: 0 }; } });
  assert.deepEqual(calls, QUALITY_CHECKS.map(({ name }) => name));
  assert.deepEqual(completed, calls);
});

test("a failing quality check names the command and prevents later checks", () => {
  const calls = [];
  assert.throws(() => runQualityChecks({
    runCommand: (check) => {
      calls.push(check.name);
      return check === QUALITY_CHECKS[2] ? { status: 1, stderr: "fixture failure" } : { status: 0 };
    },
  }), /a11y dispositions against latest results failed[\s\S]*fixture failure/);
  assert.deepEqual(calls, QUALITY_CHECKS.slice(0, 3).map(({ name }) => name));
});

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  // node --test imports this module, registers the non-vacuous tests above, and does not run CI.
} else if (invokedAsEntrypoint) {
  try {
    const completed = runQualityChecks({ onStep: ({ name }) => process.stdout.write(`==> ${name}\n`) });
    process.stdout.write(`Phase 254 quality: PASS (${completed.length} records checked serially)\n`);
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exitCode = 1;
  }
}
