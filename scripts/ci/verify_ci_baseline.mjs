#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { collectBaseline } from "./collect_ci_baseline.mjs";
import { renderBaseline } from "./render_ci_baseline.mjs";

function fail(message) {
  throw new Error(message);
}

function fixturePath() {
  return path.resolve(".planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json");
}

export function verifyFixtures() {
  const fixture = JSON.parse(fs.readFileSync(fixturePath(), "utf8"));
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-ci-baseline-"));
  try {
    const records = collectBaseline([fixture.successful_run]);
    assert.equal(records.length, 3, "successful fixture emits run plus two jobs");
    const ndjsonPath = path.join(temp, "baseline.ndjson");
    fs.writeFileSync(ndjsonPath, `${records.map((record) => JSON.stringify(record)).join("\n")}\n`);
    const markdown = renderBaseline(records);
    assert.match(markdown, /Comparable timing/, "renderer includes timing table");
    assert.doesNotMatch(markdown, /unsafe-branch-name/, "renderer never receives raw branch name");
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

function main() {
  if (!process.argv.includes("--fixtures")) fail("usage: verify_ci_baseline.mjs --fixtures");
  verifyFixtures();
  console.log("ci baseline fixtures: PASS");
}

try {
  main();
} catch (error) {
  console.error(`ci baseline fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
