#!/usr/bin/env node
// Test-only fixture entry point. Production wrappers call the custody script directly.
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";

const thisFile = fileURLToPath(import.meta.url);

function main() {
  const require = createRequire(import.meta.url);
  const custodyPath = path.join(path.dirname(thisFile), "accrue_host_preview_custody.sh");
  const fixturePath = process.argv[2];
  const mode = process.argv[3];
  if (!fixturePath || !["browser", "dev"].includes(mode)) {
    console.error("usage: accrue_host_preview_custody_test_entry.mjs <fixture.json> <browser|dev>");
    process.exit(2);
  }
  fs.accessSync(fixturePath, fs.constants.R_OK);
  process.argv = [process.argv[0], custodyPath, "preflight", mode];
  require(custodyPath).run({ fixturePath });
}

let entry = false;
try {
  entry = isMainModule(import.meta.url);
} catch {
  entry = false;
}
// Custody tests spawn this shim with arguments from inside a node --test run (NODE_TEST_CONTEXT inherited);
// only an argument-less invocation under node --test is the self-test.
if (entry && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  test("custody test entry rejects a missing fixture argument with usage text", () => {
    // Clear NODE_TEST_CONTEXT so the child takes the CLI path instead of re-registering this test.
    const env = { ...process.env };
    delete env.NODE_TEST_CONTEXT;
    const result = spawnSync(process.execPath, [thisFile], { encoding: "utf8", shell: false, env });
    assert.equal(result.status, 2);
    assert.match(result.stderr, /usage: accrue_host_preview_custody_test_entry\.mjs/);
  });
} else if (entry) {
  main();
}
