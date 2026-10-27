import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import test from "node:test";
import { fileURLToPath, pathToFileURL } from "node:url";
import { expectedNodeTestIdentities } from "./phase252_reporters.mjs";

const root = path.resolve(process.env.PHASE253_REPO_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../.."));
const runnerPath = path.join(root, "scripts/ci/verify_phase253_compositions.mjs");
const testSource = "scripts/ci/verify_phase253_compositions.test.mjs";
const require = createRequire(import.meta.url);
const browserHelpers = require("../../accrue_admin/e2e/phase253-composition-helpers.js");
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
        tests: [{ expectedStatus: "passed", results: [{ status: "passed", retry: 0 }] }],
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
  const collectionIdentity = (scenarioId, suffix) => ({
    story_path: "/groups/subscriptions_collection",
    renderer: "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1",
    fact_source: `CadenceSubscriptionFacts.fetch!(:${scenarioId})`,
    proof_lane: "presentation-only",
    expected_facts: {
      subscription_id: `subscription-${suffix}`,
      customer_name: `Customer ${suffix}`,
      amount_state: "unavailable",
    },
  });
  const keys = [
    {
      key: "one_row::breakpoint::767::light", case_kind: "breakpoint",
      executed_test: "one_row | breakpoint edge | 767px | light", variation_id: "one_row", scenario_id: "launch",
      width: 767, viewport: { width: 767, container_width: null }, theme: "light",
      url: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row",
      source_identity: collectionIdentity("launch", "one-row"),
    },
    {
      key: "filtered_empty::breakpoint::768::dark", case_kind: "breakpoint",
      executed_test: "filtered_empty | breakpoint edge | 768px | dark", variation_id: "filtered_empty", scenario_id: "growing_team",
      width: 768, viewport: { width: 768, container_width: null }, theme: "dark",
      url: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=filtered_empty",
      source_identity: collectionIdentity("growing_team", "filtered-empty"),
    },
    {
      key: "one_row::viewport::320::light", case_kind: "viewport",
      executed_test: "one_row | viewport | 320px | light", variation_id: "one_row", scenario_id: "launch",
      width: 320, viewport: { width: 320, container_width: null }, theme: "light",
      url: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row",
      source_identity: collectionIdentity("launch", "one-row"),
    },
    {
      key: "one_row::viewport::1280::dark", case_kind: "viewport",
      executed_test: "one_row | viewport | 1280px | dark", variation_id: "one_row", scenario_id: "launch",
      width: 1280, viewport: { width: 1280, container_width: null }, theme: "dark",
      url: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row",
      source_identity: collectionIdentity("launch", "one-row"),
    },
    {
      key: "geometry::negative-controls::320::light", case_kind: "geometry_negative_controls",
      executed_test: "geometry controls detect hidden essential content and page overflow",
      variation_id: "one_row", scenario_id: "launch", width: 320,
      viewport: { width: 320, container_width: null }, theme: "light",
      url: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=one_row",
      source_identity: collectionIdentity("launch", "one-row"),
    },
  ];
  const cases = keys.map((definition) => {
    const { key, case_kind, variation_id } = definition;
    const assertionIds = case_kind === "geometry_negative_controls"
      ? ["geometry_detected"]
      : case_kind === "breakpoint"
        ? [variation_id === "one_row" ? "actual_transition" : "filtered_empty_layout"]
        : ["cell_rendered"];
    return {
      ...definition,
      key,
      case_kind,
      run_id: runId,
      manifest_sha256: manifestDigest,
      completed_at: "2026-10-27T20:00:00.000Z",
      status: "passed",
      assertion_ids: assertionIds,
      served_assets: { css_sha256: digests[css], js_sha256: digests[js], verified: true },
      negative_controls: case_kind === "geometry_negative_controls"
        ? { hidden_essential_detected: true, page_overflow_detected: true }
        : undefined,
    };
  });
  const reconciliation = "reconciles the fixture browser cells";
  const spec = {
    id: "browser-fixture",
    sources: Object.keys(digests),
    reporter: { kind: "playwright-json" },
    assertion_bindings: {
      rendered_cells: ["viewport"],
      breakpoint_controls: ["breakpoint"],
      geometry_negative_controls: ["geometry_negative_controls"],
      manifest_reconciliation: ["__reconciliation__"],
    },
    browser_contract: {
      expected_cell_definitions: () => keys,
      reconciliation_title: reconciliation,
      asset_paths: [css, js],
      assertion_ids: {
        viewport: ["cell_rendered"],
        breakpoint: {
          one_row: ["actual_transition"],
          filtered_empty: ["filtered_empty_layout"],
        },
        geometry_negative_controls: ["geometry_detected"],
      },
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
    assert.equal(accepted.test_count, 6);
    assert.equal(accepted.browser_cells.length, 5);
    assert.deepEqual(accepted.assertion_refs, ["breakpoint_controls", "geometry_negative_controls", "manifest_reconciliation", "rendered_cells"]);

    const validateBrowser = (browserResult, stdout = execution.stdout) => runner.validateLaneEvidence(fixture.spec, {
      ...execution,
      stdout,
    }, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult, expectedBrowserCells: fixture.keys,
    });
    const titleSwap = structuredClone(fixture.result);
    [titleSwap.cases[0].executed_test, titleSwap.cases[1].executed_test] =
      [titleSwap.cases[1].executed_test, titleSwap.cases[0].executed_test];
    assert.deepEqual(
      titleSwap.cases.map(({ executed_test }) => executed_test).sort(),
      fixture.result.cases.map(({ executed_test }) => executed_test).sort(),
      "swapping titles preserves the unordered Playwright identity set",
    );
    assert.throws(() => validateBrowser(titleSwap), /exact definition/);

    const attributionMutations = [
      ["case kind", (row) => { row.case_kind = "container"; }],
      ["scenario", (row) => { row.scenario_id = "launch"; }],
      ["variation", (row) => { row.variation_id = "one_row"; }],
      ["route", (row) => { row.url = "/billing/dev/storybook/iframe/wrong"; }],
      ["renderer", (row) => { row.source_identity.renderer = "Wrong.Renderer/1"; }],
      ["fact source", (row) => { row.source_identity.fact_source = "CadenceSubscriptionFacts.fetch!(:wrong)"; }],
      ["proof lane", (row) => { row.source_identity.proof_lane = "provider-completion"; }],
      ["expected facts", (row) => { row.source_identity.expected_facts.customer_name = "Invented Customer"; }],
    ];
    for (const [label, mutate] of attributionMutations) {
      const changed = structuredClone(fixture.result);
      mutate(changed.cases[1]);
      assert.equal(browserHelpers.matchesExpectedBrowserCell(changed.cases[1], fixture.keys[1]), false, `${label} mutation changes the exact cell binding`);
      assert.throws(() => validateBrowser(changed), /kind|exact definition/, `${label} mutation must fail closed`);
    }

    const missingIdentity = structuredClone(fixture.report);
    delete missingIdentity.suites[0].specs[0].title;
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, {
      ...execution,
      stdout: JSON.stringify(missingIdentity),
    }, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: fixture.result, expectedBrowserCells: fixture.keys,
    }), /spec identity/);

    const retried = structuredClone(fixture.report);
    retried.suites[0].specs[0].tests[0].results[0].retry = 1;
    assert.throws(() => runner.validateLaneEvidence(fixture.spec, {
      ...execution,
      stdout: JSON.stringify(retried),
    }, {
      root, expectedRunId: runId, expectedSourceDigests: fixture.digests,
      expectedManifestDigest: manifestDigest, browserResult: fixture.result, expectedBrowserCells: fixture.keys,
    }), /retried/);

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

test("browser helper binds all 151 full cell keys to their exact test and source attribution", () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(root, "accrue_admin/tmp/phase253/manifest.json"), "utf8"));
  const definitions = browserHelpers.createExpectedBrowserCellDefinitions(manifest);
  const results = {
    run_id: runId,
    expected_case_keys: definitions.map(({ key }) => key),
    cases: definitions.map((definition) => ({
      ...definition,
      run_id: runId,
      manifest_sha256: manifestDigest,
      status: "passed",
      assertion_ids: ["contract-cell"],
      served_assets: { verified: true },
    })),
  };
  assert.deepEqual(browserHelpers.reconcileResults(results, manifest, manifestDigest), []);

  const swappedTitles = structuredClone(results);
  [swappedTitles.cases[0].executed_test, swappedTitles.cases[1].executed_test] =
    [swappedTitles.cases[1].executed_test, swappedTitles.cases[0].executed_test];
  assert.deepEqual(
    swappedTitles.cases.map(({ executed_test }) => executed_test).sort(),
    results.cases.map(({ executed_test }) => executed_test).sort(),
    "title swapping leaves the aggregate executed-title set intact",
  );
  assert.ok(browserHelpers.reconcileResults(swappedTitles, manifest, manifestDigest).some((error) => /exact definition/.test(error)));

  const wrongCollectionFacts = structuredClone(results);
  wrongCollectionFacts.cases[0].source_identity.expected_facts.customer_name = "Wrong Customer";
  assert.ok(browserHelpers.reconcileResults(wrongCollectionFacts, manifest, manifestDigest).some((error) => /exact definition/.test(error)));
});

test("browser assertion inventories include breakpoint and page stress controls", async () => {
  const runner = await loadRunner();
  const browser = runner.buildCommandPlan({
    id: runId,
    adminBuildPath: "/tmp/phase253-contract/admin",
    outputDirectory: "/tmp/phase253-contract/output",
  }).find(({ id }) => id === "phase253-compositions-browser");
  const manifestSourcePaths = [
    "accrue_admin/lib/accrue_admin/dev/storybook.ex",
    "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
    "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
    "accrue_admin/lib/accrue_admin/queries/subscriptions.ex",
    "accrue_admin/lib/accrue_admin/router.ex",
    "accrue_admin/storybook/_support/subscription_collection.ex",
    "accrue_admin/storybook/_support/subscription_compositions_manifest.ex",
    "accrue_admin/storybook/_support/subscription_page_scenarios.ex",
    "dev_support/ui_scenarios/cadence_subscriptions.exs",
    "storybook/groups/subscriptions_collection.story.exs",
    "storybook/pages/subscription.story.exs",
  ];
  assert.ok(manifestSourcePaths.every((source) => browser.sources.includes(source)));
  assert.ok(runner.sourceInventory([browser]).includes("accrue_admin/lib/accrue_admin/live/subscription_live.ex"),
    "common aggregate source inventory includes the production whole-page renderer");
  for (const source of [
    "accrue_admin/storybook/_support/subscription_manifest.ex",
    "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
    "guides/subscription-story-coverage.md",
  ]) {
    assert.ok(runner.sourceInventory([browser]).includes(source), `aggregate source identity includes generated guide dependency ${source}`);
  }
  const manifest = JSON.parse(fs.readFileSync(path.join(root, "accrue_admin/tmp/phase253/manifest.json"), "utf8"));
  const definitions = browser.browser_contract.expected_cell_definitions(manifest);
  assert.equal(definitions.length, 151, "finite browser inventory retains every one of the 151 cells");
  assert.equal(new Set(definitions.map(({ key }) => key)).size, 151);
  assert.equal(new Set(definitions.map(({ executed_test }) => executed_test)).size, 151);
  assert.ok(definitions.every((definition) => definition.executed_test && definition.variation_id && definition.scenario_id &&
    definition.url && definition.source_identity?.renderer && definition.source_identity?.fact_source &&
    definition.source_identity?.proof_lane && definition.source_identity?.expected_facts),
  "every browser cell has an explicit title, route, and manifest-derived attribution");
  assert.equal(definitions.filter(({ case_kind }) => case_kind === "synthetic_text_stress").length, 2);
  assert.equal(definitions.filter(({ case_kind }) => case_kind === "page_synthetic_text_stress").length, 6);
  const oneRowIdentity = definitions.find(({ key }) => key === "one_row::viewport::320::light").source_identity;
  assert.deepEqual(definitions.find(({ case_kind }) => case_kind === "geometry_negative_controls").source_identity, oneRowIdentity,
    "geometry control borrows explicit one_row identity without inventing a manifest variation");
  assert.deepEqual(Object.keys(browser.browser_contract.assertion_ids.breakpoint).sort(), ["filtered_empty", "one_row"]);
  assert.deepEqual([...browser.browser_contract.assertion_ids.breakpoint.one_row].sort(), [
    "actual_767_768_card_table_transition",
    "compiled_direct_route",
    "no_hidden_essential_or_page_overflow",
    "ordered_collection_content",
    "source_facts_and_state_controls",
    "table_local_scroll_is_separate",
    "theme_and_served_asset_identity",
  ].sort());
  assert.deepEqual([...browser.browser_contract.assertion_ids.breakpoint.filtered_empty].sort(), [
    "compiled_direct_route",
    "filtered_empty_is_visible_without_inventing_empty_table_or_cards",
    "no_hidden_essential_or_page_overflow",
    "ordered_collection_content",
    "source_facts_and_state_controls",
    "theme_and_served_asset_identity",
  ].sort());
  assert.deepEqual([...browser.browser_contract.assertion_ids.page_synthetic_text_stress].sort(), [
    "compiled_direct_whole_page_route",
    "exact_ids_amount_caveats_state_and_destinations",
    "long_source_preserving_synthetic_stress_is_visible_and_unclipped",
    "native_disclosures_activity_and_related_links",
    "no_hidden_essential_content_or_page_overflow",
    "production_source_identity_and_fact_content",
    "theme_and_served_asset_identity",
  ].sort());
});

test("CI and acceptance contracts include imported main-module test identities", async () => {
  const runner = await loadRunner();
  const ciContract = runner.buildCommandPlan({
    id: runId,
    adminBuildPath: "/tmp/phase253-contract/admin",
    outputDirectory: "/tmp/phase253-contract/output",
  }).find(({ id }) => id === "phase253-ci-contract");
  assert.deepEqual(ciContract.reporter.testFiles, [
    "scripts/ci/verify_phase252_ci_contract.test.mjs",
    "scripts/ci/main_module.mjs",
  ]);
  assert.ok(ciContract.sources.includes("scripts/ci/main_module.mjs"));

  const acceptanceContract = runner.buildCommandPlan({
    id: runId,
    adminBuildPath: "/tmp/phase253-contract/admin",
    outputDirectory: "/tmp/phase253-contract/output",
  }).find(({ id }) => id === "phase253-acceptance-contract");
  assert.deepEqual(acceptanceContract.reporter.testFiles, [
    "scripts/ci/generate_phase253_acceptance.test.mjs",
    "scripts/ci/main_module.mjs",
  ]);
  assert.ok(acceptanceContract.sources.includes("scripts/ci/main_module.mjs"));
});
