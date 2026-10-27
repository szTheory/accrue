import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";
import { expectedNodeTestIdentities } from "./phase252_reporters.mjs";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."));
const runnerPath = path.join(root, "scripts/ci/verify_phase253_compositions.mjs");
const testSource = "scripts/ci/verify_phase253_compositions.test.mjs";
const runId = "b".repeat(32);
const manifestDigest = "c".repeat(64);

async function loadRunner() {
  let runner;
  try {
    runner = await import(pathToFileURL(runnerPath));
  } catch {
    assert.fail("focused Phase 253 composition runner must exist and load");
  }
  return runner;
}

function tapReport(identities, options = {}) {
  const rows = identities.map((identity, index) => {
    const skipped = options.skippedIndex === index;
    const failed = options.failedIndex === index;
    const status = failed ? "not ok " : "ok ";
    const suffix = skipped ? " # SKIP required assertion was not executed" : "";
    return status + (index + 1) + " - " + identity + suffix;
  });
  const failed = options.failedIndex == null ? 0 : 1;
  const skipped = options.skippedIndex == null ? 0 : 1;
  const pass = identities.length - failed - skipped;
  return [
    "TAP version 13",
    ...rows,
    "1.." + identities.length,
    "# tests " + identities.length,
    "# pass " + pass,
    "# fail " + failed,
    "# cancelled 0",
    "# skipped " + skipped,
    "# todo 0",
    "",
  ].join("\n");
}

function tapSpec(runner, overrides = {}) {
  const identities = expectedNodeTestIdentities(root, [testSource]);
  return {
    id: "contract-fixture",
    sources: [testSource],
    reporter: { kind: "node-tap", testFiles: [testSource] },
    assertion_bindings: {
      runner_contract: ["focused Phase 253 composition runner exposes its bounded serial acceptance plan"],
    },
    ...overrides,
    identities,
  };
}

function tapExecution(runner, spec, overrides = {}) {
  const identities = spec.identities || expectedNodeTestIdentities(root, spec.reporter.testFiles);
  return {
    run_id: runId,
    exitCode: 0,
    stdout: tapReport(identities),
    manifest_sha256: manifestDigest,
    source_digests: Object.fromEntries(spec.sources.map((source) => [source, runner.fileDigest(root, source)])),
    ...overrides,
  };
}

test("focused Phase 253 composition runner exposes its bounded serial acceptance plan", async () => {
  const runner = await loadRunner();
  assert.equal(typeof runner.buildCommandPlan, "function");
  assert.equal(typeof runner.validateLaneEvidence, "function");
  assert.equal(typeof runner.executeCommandSequence, "function");
});

test("the runner has a finite serial lane inventory with unique disposable resources", async () => {
  const runner = await loadRunner();
  const plan = runner.buildCommandPlan({
    id: runId,
    adminBuildPath: "/tmp/phase253-contract/mix-build",
    outputDirectory: "/tmp/phase253-contract/output",
  });
  assert.deepEqual(plan.map(({ id }) => id), runner.REQUIRED_COMMAND_IDS);
  assert.doesNotThrow(() => runner.assertRequiredCommandPlan(plan));

  const mutable = plan.filter(({ lane }) => lane === "admin-test" || lane === "admin-review-browser");
  assert.equal(new Set(mutable.map(({ partition }) => partition)).size, mutable.length);
  assert.ok(mutable.every(({ partition }) => /^\d{8,16}$/.test(partition)));
  for (const lane of plan.filter(({ lane }) => lane === "admin-test")) {
    assert.ok(lane.args.includes("scripts/dev/phase252_lab.mjs"));
    assert.ok(lane.args.includes("--lane"));
    assert.equal(lane.args[lane.args.indexOf("--lane") + 1], "admin-test");
    assert.ok(lane.args.at(-1).includes("cd accrue_admin &&"));
    assert.equal(lane.env.PHASE252_TAP_REPORT, "1");
  }
  assert.equal(plan.find(({ id }) => id === "phase253-compositions-browser").args.at(-1), "e2e/subscription-compositions-phase253.spec.js");
  assert.ok(plan.find(({ id }) => id === "phase253-acceptance-contract").reporter.testFiles.includes("scripts/ci/generate_phase253_acceptance.test.mjs"));
  assert.throws(() => runner.assertRequiredCommandPlan(plan.slice(1)), /finite Phase 253 lane inventory/);
});

test("the lane sequence is awaited in order and stops after the first failed command", async () => {
  const runner = await loadRunner();
  const commands = [{ id: "one" }, { id: "two" }, { id: "three" }];
  const calls = [];
  const snapshots = [];
  const result = await runner.executeCommandSequence(
    commands,
    async ({ id }) => {
      calls.push(id);
      return { exitCode: id === "two" ? 1 : 0 };
    },
    async ({ status }) => snapshots.push(status),
  );
  assert.deepEqual(calls, ["one", "two"]);
  assert.deepEqual(snapshots, ["running", "failed"]);
  assert.equal(result.status, "failed");
  assert.equal(snapshots.includes("passed"), false);
});

test("TAP evidence binds exact executed test identities and rejects missing, failed, skipped, or forged records", async () => {
  const runner = await loadRunner();
  const spec = tapSpec(runner);
  const accepted = runner.validateLaneEvidence(spec, tapExecution(runner, spec), {
    root,
    expectedRunId: runId,
    expectedSourceDigests: { [testSource]: runner.fileDigest(root, testSource) },
    expectedManifestDigest: manifestDigest,
  });
  assert.equal(accepted.test_count, spec.identities.length);
  assert.equal(accepted.skipped, 0);
  assert.deepEqual(accepted.assertion_refs, ["runner_contract"]);
  assert.ok(accepted.assertion_bindings.runner_contract.length > 0);

  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, { stdout: "" }), {
    root, expectedRunId: runId, expectedManifestDigest: manifestDigest,
  }), /missing or empty/);
  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, {
    exitCode: 1,
  }), { root, expectedRunId: runId }), /command failed with exit/);
  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, {
    stdout: tapReport(spec.identities, { skippedIndex: 0 }),
  }), { root, expectedRunId: runId }), /skipped|TODO/);

  const fakeAssertionSpec = {
    ...spec,
    assertion_bindings: { fabricated_assertion: ["not an executed test identity"] },
  };
  assert.throws(() => runner.validateLaneEvidence(fakeAssertionSpec, tapExecution(runner, fakeAssertionSpec), {
    root, expectedRunId: runId,
  }), /no matching executed reporter identity/);
  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, {
    assertion_refs: ["fabricated_assertion"],
  }), { root, expectedRunId: runId }), /assertion references/);
});

test("TAP evidence rejects wrong-run and stale-source results", async () => {
  const runner = await loadRunner();
  const spec = tapSpec(runner);
  const expectedSourceDigests = { [testSource]: runner.fileDigest(root, testSource) };
  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, {
    run_id: "d".repeat(32),
  }), { root, expectedRunId: runId, expectedSourceDigests }), /different run/);
  assert.throws(() => runner.validateLaneEvidence(spec, tapExecution(runner, spec, {
    source_digests: { [testSource]: "e".repeat(64) },
  }), { root, expectedRunId: runId, expectedSourceDigests }), /source digest is missing or stale/);
});

function playwrightReport(identities) {
  return {
    status: "passed",
    stats: { expected: identities.length, unexpected: 0, skipped: 0, flaky: 0 },
    errors: [],
    suites: [{
      specs: identities.map((title) => ({
        title,
        ok: true,
        tests: [{ title, expectedStatus: "passed", results: [{ status: "passed" }] }],
      })),
    }],
  };
}

function browserFixture(runner, resultPath) {
  const css = "accrue_admin/priv/static/storybook.css";
  const js = "accrue_admin/priv/static/storybook.js";
  const digests = {
    [testSource]: runner.fileDigest(root, testSource),
    [css]: runner.fileDigest(root, css),
    [js]: runner.fileDigest(root, js),
  };
  const keys = [
    { key: "state::viewport::320::light", case_kind: "viewport" },
    { key: "state::viewport::1280::dark", case_kind: "viewport" },
    { key: "geometry::negative-controls::320::light", case_kind: "geometry_negative_controls" },
  ];
  const cases = keys.map(({ key, case_kind }) => {
    const testTitle = "rendered " + key;
    return {
      key,
      case_kind,
      run_id: runId,
      manifest_sha256: manifestDigest,
      executed_test: testTitle,
      completed_at: "2026-10-27T20:00:00.000Z",
      status: "passed",
      assertion_ids: case_kind === "geometry_negative_controls" ? ["geometry_detected"] : ["cell_rendered"],
      source_identity: { story_path: "/groups/subscriptions_collection", renderer: "Production.Renderer/1", proof_lane: "presentation-only" },
      served_assets: { css_sha256: digests[css], js_sha256: digests[js], verified: true },
      negative_controls: case_kind === "geometry_negative_controls"
        ? { hidden_essential_detected: true, page_overflow_detected: true }
        : undefined,
      viewport: { width: 320, container_width: null },
      theme: "light",
    };
  });
  const reconciliation = "reconciles the fixture browser cells";
  const spec = {
    id: "browser-fixture",
    sources: Object.keys(digests),
    reporter: { kind: "playwright-json" },
    assertion_bindings: {
      rendered_cells: ["viewport"],
      geometry_negative_controls: ["geometry_negative_controls"],
      manifest_reconciliation: ["__reconciliation__"],
    },
    browser_contract: {
      expected_cell_definitions: () => keys,
      reconciliation_title: reconciliation,
      asset_paths: [css, js],
      assertion_ids: { viewport: ["cell_rendered"], geometry_negative_controls: ["geometry_detected"] },
      result_path: resultPath,
    },
  };
  const result = {
    schema_version: 1,
    run_id: runId,
    manifest_sha256: manifestDigest,
    human_judgment: false,
    proof_lane: "actual direct browser presentation; no mounted-effect claims",
    expected_case_keys: keys.map(({ key }) => key),
    source_and_asset_sha256: { [css]: digests[css], [js]: digests[js] },
    cases,
  };
  const report = playwrightReport([...cases.map(({ executed_test }) => executed_test), reconciliation]);
  return { spec, result, report, digests, keys, cases, reconciliation };
}

test("browser evidence accepts the complete cell control and rejects duplicates, pooled runs, and stale assets", async () => {
  const runner = await loadRunner();
  const resultPath = "accrue_admin/tmp/phase253/ci-results/contract-browser-result.json";
  const fixture = browserFixture(runner, resultPath);
  const absoluteResultPath = path.join(root, resultPath);
  fs.mkdirSync(path.dirname(absoluteResultPath), { recursive: true });
  fs.writeFileSync(absoluteResultPath, JSON.stringify(fixture.result), { mode: 0o600 });
  try {
    const execution = {
      run_id: runId,
      exitCode: 0,
      stdout: JSON.stringify(fixture.report),
      manifest_sha256: manifestDigest,
      source_digests: fixture.digests,
    };
    const accepted = runner.validateLaneEvidence(fixture.spec, execution, {
      root,
      expectedRunId: runId,
      expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest,
      browserResult: fixture.result,
      expectedBrowserCells: fixture.keys,
    });
    assert.equal(accepted.test_count, 4);
    assert.equal(accepted.browser_cells.length, 3);
    assert.deepEqual(accepted.assertion_refs, ["geometry_negative_controls", "manifest_reconciliation", "rendered_cells"]);

    const duplicate = structuredClone(fixture.result);
    duplicate.cases[1].key = duplicate.cases[0].key;
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, execution, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: duplicate, expectedBrowserCells: fixture.keys,
    }), /mismatch|duplicate|pooled/i);

    const pooled = structuredClone(fixture.result);
    pooled.cases.pop();
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, execution, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: pooled, expectedBrowserCells: fixture.keys,
    }), /incomplete, pooled, or contains extra cells/);

    const wrongRun = structuredClone(fixture.result);
    wrongRun.cases[0].run_id = "d".repeat(32);
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, execution, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: wrongRun, expectedBrowserCells: fixture.keys,
    }), /different run|failed, stale, or pooled/);

    const staleAsset = structuredClone(fixture.result);
    staleAsset.cases[0].served_assets.css_sha256 = "f".repeat(64);
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, execution, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: staleAsset, expectedBrowserCells: fixture.keys,
    }), /differs from the current compiled asset bytes/);
  } finally {
    fs.rmSync(absoluteResultPath, { force: true });
  }
});
