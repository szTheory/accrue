#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

function runSelfTest() {
  assert.fail("ci_monitor implementation is not present yet");
}

test("ci monitor self-test validates a read-only exact-SHA monitor", () => {
  runSelfTest();
});

if (require.main === module && process.argv.includes("--self-test")) {
  try {
    runSelfTest();
    process.stdout.write("ci monitor self-test: PASS\n");
  } catch (error) {
    process.stderr.write(`ci monitor self-test: FAIL: ${error.message}\n`);
    process.exitCode = 1;
  }
}

module.exports = { runSelfTest };
