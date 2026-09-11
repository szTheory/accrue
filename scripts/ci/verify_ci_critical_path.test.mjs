import assert from "node:assert/strict";
import fs from "node:fs";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { verifyComparisonEvidence } from "./verify_ci_critical_path.mjs";

const phase = ".planning/phases/227-measured-critical-path-improvement";
const contract = JSON.parse(fs.readFileSync(`${phase}/227-ci-contract.json`, "utf8"));
const fixtures = JSON.parse(fs.readFileSync(`${phase}/fixtures/ci-critical-path-cases.json`, "utf8"));

test("rejects forged duplicate push cohort through public verification", () => {
  assert.throws(
    () => verifyComparisonEvidence(fixtures.forged_keep_evidence, contract, fixtures.context),
    /workflow_dispatch|unique|required job|schema fields/,
  );
});

test("rejects a CLI invocation with no declared action", () => {
  const result = spawnSync(process.execPath, ["scripts/ci/verify_ci_critical_path.mjs"], { encoding: "utf8" });
  assert.notEqual(result.status, 0, "a no-action verifier invocation must fail closed");
});
