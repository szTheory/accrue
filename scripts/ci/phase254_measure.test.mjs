import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import * as measure from "./phase254_measure.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const MEASURE = path.join(HERE, "phase254_measure.mjs");

const LOCAL_SAMPLE_KEYS = [
  "schema_version", "mode", "lane", "protocol", "n", "warmup", "values_ms", "median_ms", "p90_ms", "min_ms",
  "max_ms", "cells", "per_cell", "overhead_ms", "durations", "phases", "fingerprint", "source_revision",
  "manifest_sha256", "informs_only", "smoke",
];

const TOOLCHAIN = { otp: "28", elixir: "1.19.5", node: "22.14.0", playwright: "1.59.1", workers: 1 };

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-measure-test-"));
  try {
    const run = (...args) => {
      const result = spawnSync("git", ["-C", dir, "-c", "core.hooksPath=/dev/null", "-c", "user.email=fixture@example.test", "-c", "user.name=fixture", ...args], { encoding: "utf8" });
      assert.equal(result.status, 0, result.stderr);
    };
    run("init", "-q");
    fs.mkdirSync(path.join(dir, "storybook"), { recursive: true });
    fs.writeFileSync(path.join(dir, "storybook", "phase252-manifest.json"), '{"entries":[]}\n');
    run("add", "storybook/phase252-manifest.json");
    run("commit", "-q", "-m", "seed");
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function fingerprintFixture(overrides = {}) {
  return {
    os: "linux 6.8.0", arch: "x64", cpu_model: "fixture cpu", cores: 4, ram_bytes: 16_000_000_000,
    image_os: "ubuntu24", image_version: "20260101.1", runner_os: "Linux", otp: "28", elixir: "1.19.5",
    node: "22.14.0", playwright: "1.59.1", workers: 1, revision: "a".repeat(40), manifest_sha256: "b".repeat(64),
    dirty: false, ...overrides,
  };
}

function sampleFixture(overrides = {}) {
  const base = {
    schema_version: 1, mode: "focused", lane: "phase252-render", protocol: { runs: 5, warmup: 1 }, n: 5, warmup: 1,
    values_ms: [1, 2, 3, 4, 5], median_ms: 3, p90_ms: 5, min_ms: 1, max_ms: 5, cells: 15,
    per_cell: { median_ms: 1, p90_ms: 2 }, overhead_ms: 3, durations: [], phases: null,
    fingerprint: fingerprintFixture(), source_revision: "a".repeat(40), manifest_sha256: "b".repeat(64),
    informs_only: false, smoke: false,
  };
  return { ...base, ...overrides };
}

function playwrightReport(durations) {
  return JSON.stringify({
    suites: [{ title: "x.spec.js", specs: durations.map((duration, index) => ({
      title: `case ${index + 1}`,
      ok: true,
      tests: [{ title: `case ${index + 1}`, expectedStatus: "passed", results: [{ status: "passed", duration }] }],
    })) }],
    stats: { expected: durations.length, unexpected: 0, skipped: 0, flaky: 0, duration: durations.reduce((sum, value) => sum + value, 0) + 250 },
    errors: [],
  });
}

test("machineFingerprint returns exactly the pinned FINGERPRINT_KEYS and maps ImageOS to image_os", () => {
  withScratchRepo((root) => {
    const fingerprint = measure.machineFingerprint({ env: { ImageOS: "ubuntu24", ImageVersion: "20260101.1", RUNNER_OS: "Linux" }, root, toolchain: TOOLCHAIN });
    assert.deepEqual(Object.keys(fingerprint ?? {}), [...(measure.FINGERPRINT_KEYS ?? [])]);
    assert.equal(measure.FINGERPRINT_KEYS?.length, 16);
    assert.equal(fingerprint?.image_os, "ubuntu24");
    assert.equal(fingerprint?.image_version, "20260101.1");
    assert.equal(fingerprint?.runner_os, "Linux");
  });
});

test("machineFingerprint secret-key negative control: a secret-looking environment variable never appears in the output", () => {
  withScratchRepo((root) => {
    const env = { ImageOS: "ubuntu24", GITHUB_TOKEN: "ghs_SECRETVALUE123", AWS_SECRET_ACCESS_KEY: "SECRETACCESSKEY456", PGPASSWORD: "hunter2hunter2" };
    const serialized = JSON.stringify(measure.machineFingerprint({ env, root, toolchain: TOOLCHAIN }));
    assert.match(serialized, /ubuntu24/, "positive control: an allow-listed variable is read");
    for (const forbidden of ["SECRETVALUE123", "SECRETACCESSKEY456", "hunter2hunter2", "GITHUB_TOKEN", "AWS_SECRET_ACCESS_KEY", "PGPASSWORD"]) {
      assert.ok(!serialized.includes(forbidden), `fingerprint leaked ${forbidden}`);
    }
  });
});

test("machineFingerprint derives the dirty flag from git status in a scratch repository, never the live tree", () => {
  withScratchRepo((root) => {
    const clean = measure.machineFingerprint({ env: {}, root, toolchain: TOOLCHAIN });
    assert.equal(clean?.dirty, false);
    fs.writeFileSync(path.join(root, "untracked.txt"), "dirty\n");
    const dirty = measure.machineFingerprint({ env: {}, root, toolchain: TOOLCHAIN });
    assert.equal(dirty?.dirty, true);
    assert.match(dirty?.revision ?? "", /^[0-9a-f]{40}$/);
    assert.match(dirty?.manifest_sha256 ?? "", /^[0-9a-f]{64}$/);
  });
});

test("isFreezeEligible rejects a fingerprint that is missing a key", () => {
  const fingerprint = fingerprintFixture();
  delete fingerprint.cpu_model;
  assert.equal(measure.isFreezeEligible?.(sampleFixture()), true, "positive control: a complete ubuntu sample is eligible");
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ fingerprint })), false);
});

test("summarizeSamples reports median, nearest-rank p90, min and max, and refuses empty input", () => {
  const summary = measure.summarizeSamples?.([5, 1, 3, 2, 4]);
  assert.deepEqual(summary, { n: 5, median: 3, p90: 5, min: 1, max: 5 });
  assert.equal(measure.summarizeSamples?.([10, 20]).median, 15);
  assert.throws(() => measure.summarizeSamples([]), /at least one/);
  assert.throws(() => measure.summarizeSamples([1, Number.NaN]), /finite/);
});

test("PROTOCOLS pins the D-21 cold, warm and focused sample counts", () => {
  assert.deepEqual(measure.PROTOCOLS, { cold: { runs: 3, warmup: 0 }, warm: { runs: 10, warmup: 1 }, focused: { runs: 5, warmup: 1 } });
});

test("isProtocolComplete protocol-completeness control: a one-run focused sample is rejected and a 5+1 sample is accepted", () => {
  assert.equal(measure.isProtocolComplete?.(sampleFixture({ n: 1, warmup: 0, values_ms: [1] })), false);
  assert.equal(measure.isProtocolComplete?.(sampleFixture()), true);
  assert.equal(measure.isProtocolComplete?.(sampleFixture({ mode: "bogus" })), false);
});

test("focused --report on an inline Playwright JSON fixture builds a sample with exactly the pinned local schema and marks it smoke", () => {
  const sample = measure.focusedSampleFromReport?.({
    reportText: playwrightReport([100, 200, 300]),
    lane: "phase252-render",
    fingerprint: fingerprintFixture(),
  });
  assert.deepEqual(Object.keys(sample ?? {}), LOCAL_SAMPLE_KEYS);
  assert.equal(sample?.smoke, true, "one run is below the focused protocol");
  assert.equal(sample?.informs_only, true);
  assert.equal(sample?.cells, 3);
  assert.deepEqual(sample?.durations, [
    { identity: "case 1", duration_ms: 100 }, { identity: "case 2", duration_ms: 200 }, { identity: "case 3", duration_ms: 300 },
  ]);
  assert.equal(sample?.overhead_ms, 250);
  assert.deepEqual(sample?.per_cell, { median_ms: 200, p90_ms: 300 });
});

test("the focused CLI marks a below-protocol run smoke true and writes a fingerprinted sample from --report", () => {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-cli-test-"));
  try {
    const report = path.join(dir, "report.json");
    const out = path.join(dir, "sample.json");
    fs.writeFileSync(report, playwrightReport([100, 200]));
    const env = { ...process.env };
    delete env.NODE_TEST_CONTEXT;
    const result = spawnSync(process.execPath, [MEASURE, "focused", "--lane", "phase252-render", "--report", report, "--out", out], { encoding: "utf8", env });
    assert.equal(result.status, 0, result.stderr);
    const sample = JSON.parse(fs.readFileSync(out, "utf8"));
    assert.deepEqual(Object.keys(sample), LOCAL_SAMPLE_KEYS);
    assert.equal(sample.smoke, true);
    assert.deepEqual(Object.keys(sample.fingerprint), [...measure.FINGERPRINT_KEYS]);
    assert.ok(sample.durations.length > 0);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("an unknown lane name fails and the registry names the four existing lanes", () => {
  assert.deepEqual(Object.keys(measure.LANES ?? {}).sort(), ["phase252-aggregate", "phase252-render", "phase253-aggregate", "phase253-manifest"]);
  assert.throws(() => measure.resolveLane?.("not-a-lane"), /unknown lane/);
});

// -- Task 254-01-02: freeze eligibility, warm lane identity, attribution, provisional budget ----

test("freeze eligibility: a macOS fingerprint is rejected, an ubuntu clean fingerprint is accepted, and a smoke sample is rejected", () => {
  const mac = fingerprintFixture({ os: "darwin 25.6.0", image_os: null, image_version: null, runner_os: null, cpu_model: "Apple M5 Pro" });
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ fingerprint: mac })), false);
  assert.ok(measure.freezeBlockers?.(sampleFixture({ fingerprint: mac })).some((reason) => /image_os/.test(reason)));
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ fingerprint: fingerprintFixture({ image_os: "ubuntu24", dirty: false }) })), true);
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ smoke: true })), false);
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ fingerprint: fingerprintFixture({ image_os: "macos14" }) })), false);
  assert.equal(measure.isFreezeEligible?.(sampleFixture({ fingerprint: fingerprintFixture({ dirty: true }) })), false);
});

test("warm mode refuses to report when the health identity lane is not admin-review", () => {
  const launch = { lane: "admin-review", port: 4100, partition: "1234567890", database: "accrue_admin_test1234567890" };
  const health = { ok: true, ready: true, port: 4100, partition: "1234567890", database: "accrue_admin_test1234567890" };
  assert.deepEqual(measure.assertWarmHealthIdentity(health, launch), { lane: "admin-review" }, "positive control: a matching identity is accepted");
  assert.throws(() => measure.assertWarmHealthIdentity({ ...health, lane: "admin-test" }, launch), /admin-review/);
  assert.throws(() => measure.assertWarmHealthIdentity(health, { ...launch, lane: "admin-test" }), /admin-review/);
  assert.throws(() => measure.assertWarmHealthIdentity({ ...health, ready: false }, launch), /not ready/);
  assert.throws(() => measure.assertWarmHealthIdentity({ ...health, partition: "999" }, launch), /partition/);
  assert.throws(() => measure.assertWarmHealthIdentity({ ...health, port: 1 }, launch), /port/);
});

test("attributeLaneCost groups Phase 252/253 lane durations into compile, database, boot and per-cell buckets", () => {
  const bundles = [
    { plan: "252-08", commands: [
      { id: "manifest-current", lane: "db-free", duration_ms: 64_000 },
      { id: "production-packages", lane: "isolated-build", duration_ms: 132_000 },
      { id: "scenario-repo", lane: "admin-test", duration_ms: 2_500 },
      { id: "subscription-render-browser", lane: "admin-review-browser", duration_ms: 10_000, execution_evidence: { test_count: 16 } },
      { id: "lab-presentation", lane: "read-only", duration_ms: 60 },
    ] },
    { plan: "253-06", commands: [
      { id: "phase253-compositions-browser", lane: "admin-review-browser", duration_ms: 40_000, execution_evidence: { test_count: 152 } },
    ] },
  ];
  const result = measure.attributeLaneCost?.(bundles, { boot_ms: 5_000 });
  assert.equal(result?.total_ms, 64_000 + 132_000 + 2_500 + 10_000 + 60 + 40_000);
  assert.deepEqual(result?.buckets, { compile_ms: 196_000, database_ms: 2_500, boot_ms: 10_000, cell_ms: 40_000, other_ms: 60 });
  assert.equal(result?.cells, 168);
  assert.equal(result?.lanes[0].id, "production-packages", "lanes are ordered by cost");
  assert.ok(result?.lanes.every((lane) => Number.isFinite(lane.duration_ms)));
  assert.throws(() => measure.attributeLaneCost([{ commands: [{ id: "x", lane: "db-free" }] }]), /numeric duration_ms/);
});

function seedBundles(root) {
  for (const [phase, plan, cases] of [["phase252", "252-08", 15], ["phase253", "253-06", 151]]) {
    const runId = `${phase}-run`;
    const renderPath = `accrue_admin/tmp/${phase}/render-results-${runId}.json`;
    const bundlePath = path.join(root, "accrue_admin", "tmp", phase, "ci-results", runId, "results.json");
    fs.mkdirSync(path.dirname(bundlePath), { recursive: true });
    fs.writeFileSync(path.join(root, renderPath), JSON.stringify({ cases: Array.from({ length: cases }, (_unused, index) => ({ key: index })) }), { flag: "w" });
    fs.writeFileSync(bundlePath, JSON.stringify({
      plan, run_id: runId, status: "passed", run_completed_at: "2026-10-27T23:00:00.000Z", source_revision: "c".repeat(40),
      browser_result_path: renderPath,
      commands: [
        { id: "manifest-current", lane: "db-free", duration_ms: 1000 },
        { id: `${phase}-browser`, lane: "admin-review-browser", duration_ms: 2000, execution_evidence: { test_count: cases + 1 } },
      ],
    }));
  }
}

function localSample(mode, overrides = {}) {
  const protocol = measure.PROTOCOLS?.[mode] ?? { runs: 1, warmup: 0 };
  return sampleFixture({
    mode, lane: `${mode}-lane`, protocol, n: protocol.runs, warmup: protocol.warmup,
    values_ms: Array.from({ length: protocol.runs }, (_unused, index) => index + 1),
    phases: mode === "cold" ? { compile_ms: 10, database_ms: 2, boot_ms: 3 } : null,
    informs_only: true, smoke: false, fingerprint: fingerprintFixture({ image_os: null, dirty: true }), ...overrides,
  });
}

test("buildProvisionalBudget writes the pinned top-level keys, a single open DEV-254-01 and no frozen value", () => {
  withScratchRepo((root) => {
    fs.mkdirSync(path.join(root, "accrue_admin", "tmp", "phase252"), { recursive: true });
    fs.mkdirSync(path.join(root, "accrue_admin", "tmp", "phase253"), { recursive: true });
    seedBundles(root);
    const samples = ["cold", "warm", "focused"].map((mode) => localSample(mode));
    const budget = measure.buildProvisionalBudget?.({ samples, root });
    assert.deepEqual(Object.keys(budget ?? {}), [
      "schema_version", "source_revision", "manifest_sha256", "selection", "metrics", "provisional_targets", "target_evaluations",
      "frozen", "allowances", "warn_at", "ceiling", "known_reds", "deviations", "widening_rule",
    ]);
    assert.equal(budget?.selection.total, 15 + 151);
    assert.equal(budget?.selection.selected, budget?.selection.total);
    assert.equal(budget?.frozen, null);
    assert.equal(budget?.deviations.length, 1);
    assert.equal(budget?.deviations[0].id, "DEV-254-01");
    assert.equal(budget?.deviations[0].status, "open");
    assert.deepEqual(budget?.deviations[0].before, { cells: 166, owners: 2 });
    assert.ok(budget?.deviations[0].measurement.attribution.lanes.every((lane) => Number.isFinite(lane.duration_ms)));
    assert.deepEqual(Object.keys(budget?.metrics ?? {}), ["local", "ci", "ci_reference", "freeze", "visual", "a11y", "final"]);
    assert.deepEqual(budget?.provisional_targets, { warm_preview_s: 10, focused_check_s: 60, additional_warm_browser_s: 180, incremental_ci_critical_path_s: 300 });
  });
});

test("buildProvisionalBudget refuses a smoke sample, a missing mode and a non-informs_only local sample", () => {
  withScratchRepo((root) => {
    fs.mkdirSync(path.join(root, "accrue_admin", "tmp", "phase252"), { recursive: true });
    fs.mkdirSync(path.join(root, "accrue_admin", "tmp", "phase253"), { recursive: true });
    seedBundles(root);
    const complete = ["cold", "warm", "focused"].map((mode) => localSample(mode));
    assert.doesNotThrow(() => measure.buildProvisionalBudget({ samples: complete, root }), "positive control: the complete set is accepted");
    assert.throws(() => measure.buildProvisionalBudget({ samples: [complete[0], complete[1], { ...complete[2], smoke: true }], root }), /smoke/);
    assert.throws(() => measure.buildProvisionalBudget({ samples: complete.slice(0, 2), root }), /needs a focused sample/);
    assert.throws(() => measure.buildProvisionalBudget({ samples: [complete[0], complete[1], { ...complete[2], informs_only: false }], root }), /informs_only/);
  });
});
