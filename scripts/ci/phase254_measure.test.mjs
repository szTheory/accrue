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

// -- Task 254-01-03: ci-collect and cache outcome parsing -------------------------------------

const CI_SAMPLE_KEYS = [
  "schema_version", "workflow", "run_id", "head_sha", "event", "attempt", "job", "conclusion", "started_at", "completed_at",
  "duration_s", "steps", "lanes", "cache", "fingerprint", "informs_only",
];

function logLine(step, text, job = "Job") {
  return `${job}\t${step}\t2026-10-28T12:00:00.0000000Z ${text}`;
}

function cacheStepLines(step, { action = "actions/cache@v5", key = null, outcome = null } = {}) {
  return [
    logLine(step, `Run ${action}`),
    ...(key === null ? [] : [logLine(step, "with:"), logLine(step, `  key: ${key}`)]),
    ...(outcome === null ? [] : [logLine(step, outcome)]),
  ];
}

test("parseCacheOutcomes records a hit and a miss (positive control: one of each yields hits 1 and misses 1)", () => {
  const log = [
    ...cacheStepLines("Restore deps cache", { key: "Linux-deps-abc", outcome: "Cache restored from key: Linux-deps-abc" }),
    ...cacheStepLines("Restore build cache", { action: "actions/cache/restore@v5", key: "Linux-build-def", outcome: "Cache not found for input keys: Linux-build-def, Linux-build-" }),
    logLine("Compile admin package", "Run cd accrue_admin && mix compile"),
  ].join("\n");
  const result = measure.parseCacheOutcomes?.(log);
  assert.equal(result?.hits, 1);
  assert.equal(result?.misses, 1);
  assert.equal(result?.partial, 0);
  assert.deepEqual(result?.steps, [
    { name: "Restore deps cache", outcome: "hit", key: "Linux-deps-abc" },
    { name: "Restore build cache", outcome: "miss", key: "Linux-build-def" },
  ]);
});

test("parseCacheOutcomes records partial when the restored key differs from the primary key", () => {
  const log = cacheStepLines("Restore deps cache", { key: "Linux-deps-new", outcome: "Cache restored from key: Linux-deps-" }).join("\n");
  const result = measure.parseCacheOutcomes?.(log);
  assert.equal(result?.partial, 1);
  assert.equal(result?.hits, 0);
  assert.deepEqual(result?.steps, [{ name: "Restore deps cache", outcome: "partial", key: "Linux-deps-" }]);
});

test("parseCacheOutcomes reads setup-node cache hits and misses and ignores save and post steps", () => {
  const log = [
    logLine("Set up Node", "Run actions/setup-node@v6"), logLine("Set up Node", "with:"), logLine("Set up Node", "  cache: npm"),
    logLine("Set up Node", "npm cache is not found"),
    logLine("Set up Node 2", "Run actions/setup-node@v6"), logLine("Set up Node 2", "  cache: npm"),
    logLine("Set up Node 2", "Cache restored from key: node-cache-Linux-x64-npm-abc"),
    ...cacheStepLines("Save build cache", { action: "actions/cache/save@v5", key: "k" }),
    ...cacheStepLines("Post Restore deps cache", { key: "k" }),
    logLine("Set up Node 3", "Run actions/setup-node@v6"), logLine("Set up Node 3", "  node-version: 22"),
  ].join("\n");
  const result = measure.parseCacheOutcomes?.(log);
  assert.equal(result?.misses, 1);
  assert.equal(result?.hits, 1);
  assert.deepEqual(result?.steps.map((step) => step.name), ["Set up Node", "Set up Node 2"]);
});

test("parseCacheOutcomes rejects a cache step with no recognised outcome line as unparsed instead of counting a miss", () => {
  const log = cacheStepLines("Restore deps cache", { key: "Linux-deps-abc", outcome: "Something unexpected happened" }).join("\n");
  assert.throws(() => measure.parseCacheOutcomes(log), /unparsed/);
});

function ciRunFixture(overrides = {}) {
  return {
    databaseId: 12345, workflowName: "CI", event: "pull_request", attempt: 1, headSha: "d".repeat(40),
    jobs: [
      {
        databaseId: 101, name: "Admin Phase 200 deterministic guardrails", conclusion: "success",
        startedAt: "2026-10-28T12:00:00Z", completedAt: "2026-10-28T12:10:30Z",
        steps: [
          { name: "Set up job", conclusion: "success", startedAt: "2026-10-28T12:00:00Z", completedAt: "2026-10-28T12:00:02Z" },
          { name: "Run Phase 200 deterministic guardrails", conclusion: "success", startedAt: "2026-10-28T12:01:00Z", completedAt: "2026-10-28T12:09:00Z" },
        ],
      },
      { databaseId: 102, name: "Browser UAT", conclusion: "success", startedAt: "2026-10-28T12:00:00Z", completedAt: "2026-10-28T12:20:00Z", steps: [] },
      { databaseId: 103, name: "Some unrelated job", conclusion: "success", startedAt: "2026-10-28T12:00:00Z", completedAt: "2026-10-28T12:01:00Z", steps: [] },
    ],
    ...overrides,
  };
}

function withArtifacts(fn, { guardrails = fingerprintFixture(), browser = fingerprintFixture({ image_os: "ubuntu24" }), skipGuardrails = false } = {}) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-ci-artifacts-"));
  try {
    const put = (relative, value) => {
      const file = path.join(dir, relative);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, JSON.stringify(value));
    };
    if (!skipGuardrails) put("phase254-machine-evidence-guardrails/fingerprint-guardrails.json", guardrails);
    put("phase254-machine-evidence-browser-uat/fingerprint-browser-uat.json", browser);
    put("phase252-machine-evidence/ci-results/run-a/results.json", { plan: "252-08", commands: [{ id: "scenario-repo", duration_ms: 2500 }, { id: "bad", duration_ms: "x" }] });
    put("phase253-machine-evidence/ci-results/run-b/results.json", { plan: "253-06", commands: [{ id: "phase253-compositions-browser", duration_ms: 43000 }] });
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const CI_LOGS = {
  101: cacheStepLines("Restore accrue_admin deps cache", { key: "Linux-deps-1", outcome: "Cache restored from key: Linux-deps-1" }).join("\n"),
  102: cacheStepLines("Set up Node", { action: "actions/setup-node@v6", outcome: "npm cache is not found" }).concat(logLine("Set up Node", "  cache: npm")).join("\n"),
};

test("collectCiSample turns one attempt-1 run into one pinned-schema CI sample per owner job, with lanes and cache hits", () => {
  withArtifacts((dir) => {
    const samples = measure.collectCiSample?.(ciRunFixture(), dir, CI_LOGS);
    assert.equal(samples?.length, 2, "the unrelated job is not an owner and yields no sample");
    const [guardrails, browser] = samples ?? [];
    assert.deepEqual(Object.keys(guardrails ?? {}), CI_SAMPLE_KEYS);
    assert.equal(guardrails?.job, "Admin Phase 200 deterministic guardrails");
    assert.equal(guardrails?.attempt, 1);
    assert.equal(guardrails?.conclusion, "success");
    assert.equal(guardrails?.fingerprint.image_os, "ubuntu24");
    assert.equal(guardrails?.duration_s, 630);
    assert.deepEqual(guardrails?.steps.map((step) => step.duration_s), [2, 480]);
    assert.deepEqual(guardrails?.lanes, [{ lane: "252-08:scenario-repo", duration_ms: 2500 }, { lane: "253-06:phase253-compositions-browser", duration_ms: 43000 }]);
    assert.equal(guardrails?.cache.hits, 1);
    assert.equal(guardrails?.informs_only, true);
    assert.equal(browser?.job, "Browser UAT");
    assert.deepEqual(browser?.lanes, []);
    assert.equal(browser?.cache.misses, 1);
  });
});

test("collectCiSample rejects an attempt-2 run", () => {
  withArtifacts((dir) => {
    assert.throws(() => measure.collectCiSample(ciRunFixture({ attempt: 2 }), dir, CI_LOGS), /attempt 2/);
  });
});

test("collectCiSample rejects a missing fingerprint file and a fingerprint without image_os", () => {
  withArtifacts((dir) => {
    assert.throws(() => measure.collectCiSample(ciRunFixture(), dir, CI_LOGS), /missing fingerprint file/);
  }, { skipGuardrails: true });
  const noImage = fingerprintFixture();
  delete noImage.image_os;
  withArtifacts((dir) => {
    assert.throws(() => measure.collectCiSample(ciRunFixture(), dir, CI_LOGS), /lacks image_os/);
  }, { guardrails: noImage });
  withArtifacts((dir) => {
    assert.throws(() => measure.collectCiSample(ciRunFixture(), dir, CI_LOGS), /lacks image_os/);
  }, { guardrails: fingerprintFixture({ image_os: null }) });
});

test("collectCiSample rejects a run with no owner job and an owner job without a log", () => {
  withArtifacts((dir) => {
    const noOwner = ciRunFixture({ jobs: [{ databaseId: 103, name: "Some unrelated job", conclusion: "success", steps: [] }] });
    assert.throws(() => measure.collectCiSample(noOwner, dir, CI_LOGS), /none of the owner jobs/);
    assert.throws(() => measure.collectCiSample(ciRunFixture(), dir, { 101: CI_LOGS[101] }), /no job log/);
  });
});

// -- 254-03 red triage (mechanical in-scope test) -------------------------------------------

const OWNED_FIXTURE = new Set([
  "scripts/ci/phase254_measure.mjs",
  "accrue_admin/e2e/subscription-compositions-phase253.spec.js",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "storybook/components/",
  ".github/workflows/ci.yml",
]);

function failure(overrides = {}) {
  return {
    workflow_file: "ci.yml",
    job: "Browser UAT",
    step: "Run Playwright",
    log: "  1) [chromium-desktop] > e2e/subscription-compositions-phase253.spec.js:20:5 > composition renders\n    Error: expected visible",
    ...overrides,
  };
}

test("classifyRed: a failing Playwright path inside the owned set is in-scope", () => {
  const result = measure.classifyRed?.(failure(), { owned: OWNED_FIXTURE, mainFailures: [] });
  assert.equal(result?.classification, "in-scope");
  assert.equal(result?.path, "accrue_admin/e2e/subscription-compositions-phase253.spec.js");
});

test("classifyRed: a failing step named in PHASE254_STEP_NAMES is in-scope even without a path", () => {
  assert.ok(measure.PHASE254_STEP_NAMES?.includes("Phase 254 machine fingerprint"));
  const result = measure.classifyRed?.(failure({ step: "Phase 254 machine fingerprint", log: "boom" }), { owned: OWNED_FIXTURE, mainFailures: [] });
  assert.equal(result?.classification, "in-scope");
});

test("classifyRed: a path outside the owned set whose job and step also failed on main is pre-existing-on-main", () => {
  const log = "  1) [chromium-desktop] > e2e/unowned-thing.spec.js:9:1 > something\n    Error: nope";
  const main = [{ workflow_file: "ci.yml", job: "Browser UAT", step: "Run Playwright" }];
  assert.equal(measure.classifyRed?.(failure({ log }), { owned: OWNED_FIXTURE, mainFailures: main })?.classification, "pre-existing-on-main");
  assert.equal(measure.classifyRed?.(failure({ log }), { owned: OWNED_FIXTURE, mainFailures: [] })?.classification, "out-of-scope-branch-only");
});

test("classifyRed: a log with no extractable path is environmental", () => {
  const result = measure.classifyRed?.(failure({ log: "The runner has received a shutdown signal." }), { owned: OWNED_FIXTURE, mainFailures: [] });
  assert.equal(result?.classification, "environmental");
  assert.equal(result?.path, null);
});

test("classifyRed: a failing accrue_admin/e2e spec absent from every 252-254 files_modified list is NOT in-scope (consumed root alone is insufficient)", () => {
  const log = "  1) [chromium-desktop] > e2e/some-other-phase.spec.js:3:1 > x\n    Error: y";
  assert.equal(measure.classifyRed?.(failure({ log }), { owned: OWNED_FIXTURE, mainFailures: [] })?.classification, "out-of-scope-branch-only");
  const real = measure.ownedPaths?.({ root: path.resolve(HERE, "../..") });
  assert.ok(real instanceof Set);
  assert.equal(real.has("accrue_admin/e2e/some-other-phase.spec.js"), false);
});

test("classifyRed: a directory entry in the owned set acts as a prefix", () => {
  const log = "Error at storybook/components/subscription_detail.story.exs:12";
  assert.equal(measure.classifyRed?.(failure({ log }), { owned: OWNED_FIXTURE, mainFailures: [] })?.classification, "in-scope");
});

test("ownedPaths reads 252-254 plan frontmatter and contains scripts/ci/phase254_measure.mjs (positive control)", () => {
  const owned = measure.ownedPaths?.({ root: path.resolve(HERE, "../..") });
  assert.ok(owned instanceof Set && owned.size > 0, "owned set is non-empty");
  assert.ok(owned.has("scripts/ci/phase254_measure.mjs"));
  assert.ok(owned.has("accrue_admin/storybook/phase254-budget.json"));
});

test("ownedPaths on a root with no 252-254 plans returns an empty set (negative control)", () => {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-owned-"));
  try {
    fs.mkdirSync(path.join(dir, ".planning", "phases"), { recursive: true });
    assert.equal(measure.ownedPaths?.({ root: dir }).size, 0);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

test("extractFailingPaths normalises runner prefixes, file URLs and drops node_modules and node internals", () => {
  const log = [
    "Error: failed at file:///home/runner/work/accrue/accrue/scripts/ci/verify_x.mjs:10:3",
    "    at /home/runner/work/accrue/accrue/node_modules/playwright/lib/x.js:1:1",
    "    at node:internal/modules/run_main:1:1",
    "  1) [chromium-desktop] > e2e/a.spec.js:3:1 > t",
    "  test/accrue_admin/live/foo_test.exs:44",
  ].join("\n");
  assert.deepEqual(measure.extractFailingPaths?.(log), ["scripts/ci/verify_x.mjs", "e2e/a.spec.js", "test/accrue_admin/live/foo_test.exs"]);
  assert.deepEqual(measure.extractFailingPaths?.("nothing here"), []);
});

function jobFixture(name, steps) {
  return { name, conclusion: steps.some((s) => s.conclusion === "failure") ? "failure" : "success", steps };
}

test("triageRuns keys the main reference per workflow: the same step failing only in the other workflow's main run is not pre-existing", () => {
  const log = "  1) [chromium-desktop] > e2e/unowned.spec.js:1:1 > x\n    Error: z";
  const runs = [
    { workflow_file: "accrue_admin_browser.yml", workflow: "AccrueAdmin Browser UAT", run_id: 11, jobs: [{ ...jobFixture("Browser UAT", [{ name: "Run Playwright", conclusion: "failure" }]), failed_logs: { "Run Playwright": log } }] },
  ];
  const onB = { "accrue_admin_browser.yml": { run_id: 22, failures: [{ job: "Browser UAT", step: "Run Playwright" }] } };
  const onlyA = { "accrue_admin_browser.yml": { run_id: 22, failures: [] }, "ci.yml": { run_id: 21, failures: [{ job: "Browser UAT", step: "Run Playwright" }] } };
  const [pre] = measure.triageRuns?.({ runs, mainRuns: onB, owned: OWNED_FIXTURE }) ?? [];
  assert.equal(pre?.classification, "pre-existing-on-main");
  assert.equal(pre?.main_run_id, 22);
  const [notPre] = measure.triageRuns?.({ runs, mainRuns: onlyA, owned: OWNED_FIXTURE }) ?? [];
  assert.equal(notPre?.classification, "out-of-scope-branch-only");
  assert.deepEqual(Object.keys(notPre ?? {}).sort(), ["classification", "first_error_line", "job", "main_run_id", "path", "run_id", "step", "test_ref", "workflow"]);
});

test("triageRuns rejects a failing run whose workflow has no main-run key with a named error, and a fully green run yields no entries", () => {
  const failing = [{ workflow_file: "ci.yml", workflow: "CI", run_id: 1, jobs: [jobFixture("X", [{ name: "s", conclusion: "failure" }])] }];
  assert.throws(() => measure.triageRuns?.({ runs: failing, mainRuns: { "accrue_admin_browser.yml": { run_id: 2, failures: [] } }, owned: OWNED_FIXTURE }), /no --main-run for workflow ci\.yml/);
  const green = [{ workflow_file: "ci.yml", workflow: "CI", run_id: 1, jobs: [jobFixture("X", [{ name: "s", conclusion: "success" }])] }];
  assert.deepEqual(measure.triageRuns?.({ runs: green, mainRuns: {}, owned: OWNED_FIXTURE }), []);
});

test("parseMainRunOptions parses repeatable workflow=run pairs and rejects malformed pairs", () => {
  assert.deepEqual(measure.parseMainRunOptions?.(["ci.yml=5", "accrue_admin_browser.yml=7"]), { "ci.yml": 5, "accrue_admin_browser.yml": 7 });
  assert.throws(() => measure.parseMainRunOptions?.(["ci.yml"]), /workflow=run_id/);
  assert.throws(() => measure.parseMainRunOptions?.(["ci.yml=abc"]), /workflow=run_id/);
});
