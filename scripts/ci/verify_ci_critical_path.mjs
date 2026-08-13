#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";

export function verifyFixtures() {
  const fixtures = JSON.parse(fs.readFileSync(".planning/phases/227-measured-critical-path-improvement/fixtures/ci-critical-path-cases.json", "utf8"));
  assert.equal(fixtures.intended_graph.host_needs.join(","), "docs-contracts-shift-left");
  throw new Error("RED: critical-path contract verifier is not implemented");
}

if (process.argv.includes("--fixtures")) verifyFixtures();
