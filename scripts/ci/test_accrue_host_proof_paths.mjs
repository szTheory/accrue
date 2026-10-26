import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";

let entry = false;
try {
  entry = isMainModule(import.meta.url);
} catch {
  entry = false;
}
// Register tests only when this file is the invoked entrypoint, so a bare import is side-effect free.
const registerTest = entry ? test : () => {};

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const configPath = path.join(repoRoot, "examples/accrue_host/playwright.config.js");

registerTest("Playwright rejects unsafe proof run IDs and derived paths before custody or setup", () => {
  for (const proofRunId of ["../escape", "safe/id", "x".repeat(81)]) {
    const result = spawnSync("node", ["-e", `require(${JSON.stringify(configPath)})`], {
      cwd: repoRoot,
      env: { ...process.env, ACCRUE_HOST_PROOF_RUN_ID: proofRunId },
      encoding: "utf8"
    });
    assert.notEqual(result.status, 0, `accepted unsafe run ID ${JSON.stringify(proofRunId)}`);
    assert.match(`${result.stdout}\n${result.stderr}`, /ACCRUE_HOST_PROOF_RUN_ID/);
  }

  for (const [key, value] of [
    ["MIX_BUILD_PATH", path.join(os.tmpdir(), "outside-build")],
    ["ACCRUE_HOST_PLAYWRIGHT_OUTPUT_DIR", path.join(os.tmpdir(), "outside-results")],
    ["ACCRUE_HOST_PLAYWRIGHT_REPORT_DIR", path.join(os.tmpdir(), "outside-report")],
    ["ACCRUE_ADMIN_MIX_BUILD_PATH", path.join(os.tmpdir(), "outside-admin-build")]
  ]) {
    const result = spawnSync("node", ["-e", `require(${JSON.stringify(configPath)})`], {
      cwd: repoRoot,
      env: { ...process.env, ACCRUE_HOST_PROOF_RUN_ID: "safe_run-243", [key]: value },
      encoding: "utf8"
    });
    assert.notEqual(result.status, 0, `accepted unsafe ${key}`);
    assert.match(`${result.stdout}\n${result.stderr}`, new RegExp(`${key}|proof-run directory`));
  }
});
