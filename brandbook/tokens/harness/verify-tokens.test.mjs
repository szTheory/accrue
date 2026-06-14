/**
 * verify-tokens.test.mjs — RED test for verify-tokens.mjs
 *
 * Verifies:
 *   1. verify-tokens.mjs exists
 *   2. It exits 0 when run against the real tokens.css
 *   3. It exits non-zero when a required token is missing (negative check)
 *
 * Run AFTER verify-tokens.mjs has been created:
 *   node brandbook/tokens/harness/verify-tokens.test.mjs
 */

import { execSync } from "child_process";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const VERIFY_PATH = path.resolve(__dirname, "./verify-tokens.mjs");
const CSS_PATH = path.resolve(__dirname, "../tokens.css");

let failures = 0;
function check(cond, label) {
  if (!cond) {
    console.error(`[verify-test] FAIL: ${label}`);
    failures++;
  } else {
    console.log(`[verify-test] OK:   ${label}`);
  }
}

// Test 1: verify-tokens.mjs exists
check(fs.existsSync(VERIFY_PATH), "verify-tokens.mjs exists");

if (fs.existsSync(VERIFY_PATH)) {
  // Test 2: exits 0 against the real tokens.css
  try {
    execSync(`node ${VERIFY_PATH}`, { stdio: "pipe" });
    check(true, "verify-tokens.mjs exits 0 on complete tokens.css");
  } catch (err) {
    console.error("[verify-test] verify-tokens.mjs output:", err.stdout?.toString(), err.stderr?.toString());
    check(false, "verify-tokens.mjs exits 0 on complete tokens.css");
  }

  // Test 3: negative check — mutated CSS triggers non-zero exit
  if (fs.existsSync(CSS_PATH)) {
    const original = fs.readFileSync(CSS_PATH, "utf8");
    // Remove the --accrue-moss line temporarily
    const mutated = original.replace(/.*--accrue-moss:.*\n/, "");
    const tmpPath = path.resolve(__dirname, "../tokens.css.tmp-test");
    fs.writeFileSync(tmpPath, mutated, "utf8");

    try {
      execSync(`CSS_PATH_OVERRIDE="${tmpPath}" node ${VERIFY_PATH}`, { stdio: "pipe" });
      check(false, "verify-tokens exits NON-ZERO when --accrue-moss is missing (should have failed)");
    } catch (err) {
      const stderr = err.stderr?.toString() ?? "";
      const stdout = err.stdout?.toString() ?? "";
      const combinedOutput = stderr + stdout;
      check(
        combinedOutput.includes("accrue-moss"),
        "verify-tokens.mjs names the missing token in output"
      );
      check(true, "verify-tokens exits non-zero on missing --accrue-moss");
    } finally {
      fs.unlinkSync(tmpPath);
    }
  }
}

if (failures > 0) {
  console.error(`\n[verify-test] FAIL (${failures} assertion(s) failed)`);
  process.exit(1);
}
console.log("\n[verify-test] OK — all assertions passed");
process.exit(0);
