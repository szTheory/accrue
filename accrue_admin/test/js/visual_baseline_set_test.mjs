import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { EXPECTED_BASELINES, checkBaselineSet } = require("../../e2e/visual-baseline-set.cjs");
const validator = path.resolve("e2e/visual-baseline-set.cjs");

function withBaselineDirectory(run) {
  const directory = mkdtempSync(path.join(tmpdir(), "accrue-visual-baselines-"));
  try {
    run(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function createCompleteSet(directory) {
  for (const name of EXPECTED_BASELINES) writeFileSync(path.join(directory, name), "png fixture");
}

test("expected set names exactly the twelve selected light/dark captures", () => {
  assert.deepEqual(EXPECTED_BASELINES, [
    "dashboard.png", "dashboard-dark.png",
    "subscriptions.png", "subscriptions-dark.png",
    "subscription-detail.png", "subscription-detail-dark.png",
    "component-kitchen.png", "component-kitchen-dark.png",
    "invoices.png", "invoices-dark.png",
    "invoice-detail.png", "invoice-detail-dark.png"
  ]);
});

test("complete set passes the pure check and CLI", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory);
    assert.deepEqual(checkBaselineSet(directory).missing, []);
    const result = spawnSync(process.execPath, [validator, directory], { encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /all 12 required visual baselines/);
  });
});

test("missing directory fails and names all twelve expected files", () => {
  withBaselineDirectory((parent) => {
    const directory = path.join(parent, "absent");
    const result = spawnSync(process.execPath, [validator, directory], { encoding: "utf8" });
    assert.notEqual(result.status, 0);
    for (const name of EXPECTED_BASELINES) assert.match(result.stderr, new RegExp(name));
  });
});

test("empty directory fails and names all twelve expected files", () => {
  withBaselineDirectory((directory) => {
    const result = spawnSync(process.execPath, [validator, directory], { encoding: "utf8" });
    assert.notEqual(result.status, 0);
    for (const name of EXPECTED_BASELINES) assert.match(result.stderr, new RegExp(name));
  });
});

test("a one-image directory remains incomplete and reports every omitted file", () => {
  withBaselineDirectory((directory) => {
    writeFileSync(path.join(directory, EXPECTED_BASELINES[0]), "png fixture");
    const result = spawnSync(process.execPath, [validator, directory], { encoding: "utf8" });
    assert.notEqual(result.status, 0);
    assert.deepEqual(checkBaselineSet(directory).missing, EXPECTED_BASELINES.slice(1));
    for (const name of EXPECTED_BASELINES.slice(1)) assert.match(result.stderr, new RegExp(name));
  });
});

for (const omitted of EXPECTED_BASELINES) {
  test(`partial set fails when ${omitted} is absent`, () => {
    withBaselineDirectory((directory) => {
      createCompleteSet(directory);
      rmSync(path.join(directory, omitted));
      const result = spawnSync(process.execPath, [validator, directory], { encoding: "utf8" });
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, new RegExp(omitted));
      assert.equal(checkBaselineSet(directory).missing[0], omitted);
    });
  });
}
