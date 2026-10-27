import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const ADMIN = "accrue_admin/test/accrue_admin/";

export const PHASE252_REPORTER_SPECS = Object.freeze({
  "manifest-current": { kind: "process-markers" },
  "phase252-lab-contract": { kind: "node-tap", testFiles: ["scripts/dev/phase252_lab.test.mjs"] },
  "scenario-domain": { kind: "exunit-tap", testFiles: [`${ADMIN}dev/subscription_scenarios_test.exs`] },
  "subscription-area": { kind: "exunit-tap", testFiles: [`${ADMIN}components/subscription_area_test.exs`] },
  "story-slice": { kind: "exunit-tap", testFiles: [`${ADMIN}dev/subscription_story_slice_test.exs`] },
  "manifest-contract": { kind: "exunit-tap", testFiles: [`${ADMIN}dev/subscription_manifest_test.exs`, `${ADMIN}dev/storybook_coverage_test.exs`] },
  "production-boundary-db-free": { kind: "exunit-tap", testFiles: [`${ADMIN}dev/subscription_production_boundary_test.exs`] },
  "phase248-heldout-contract": { kind: "node-tap", testFiles: ["scripts/ci/phase248_heldout_isolation.test.mjs"] },
  "phase252-ci-contract": { kind: "node-tap", testFiles: ["scripts/ci/verify_phase252_ci_contract.test.mjs"] },
  "production-boundary-controls": { kind: "process-markers" },
  "production-packages": { kind: "process-markers" },
  "scenario-repo": { kind: "exunit-tap", testFiles: [`${ADMIN}dev/subscription_scenario_repo_test.exs`] },
  "registry-kitchen-mount-scoped-path": { kind: "exunit-tap", testFiles: [
    `${ADMIN}dev/component_registry_test.exs`,
    `${ADMIN}dev/component_group_registry_test.exs`,
    `${ADMIN}dev/storybook_coverage_test.exs`,
    `${ADMIN}dev/storybook_asset_test.exs`,
    `${ADMIN}dev/subscription_production_boundary_test.exs`,
    `${ADMIN}scoped_path_test.exs`,
  ] },
  "mounted-subscription-regressions": { kind: "exunit-tap", testFiles: [`${ADMIN}live/subscription_live_test.exs`] },
  "heldout-cleanup": { kind: "exunit-tap", testFiles: ["examples/accrue_host/test/accrue_host/phase252_scenario_cleanup_test.exs"] },
  "isolation-reset": { kind: "node-tap", testFiles: ["scripts/dev/phase252_isolation.test.mjs"] },
  "subscription-render-browser": { kind: "playwright-json" },
  "phase252-acceptance-contract": { kind: "node-tap", testFiles: ["scripts/ci/generate_phase252_acceptance.test.mjs"] },
});

const PROCESS_MARKERS = Object.freeze({
  "manifest-current": {
    compiled_variation_discovery: "PHASE252_ASSERTION=compiled_variation_discovery",
    source_digest_freshness: "PHASE252_ASSERTION=source_digest_freshness",
    tracked_manifest_content_identity: "PHASE252_ASSERTION=tracked_manifest_content_identity",
  },
  "production-boundary-controls": {
    production_package_leak_negative_controls: "PHASE252_ASSERTION=production_package_leak_negative_controls",
    development_positive_production_route_exclusion: "PHASE252_ASSERTION=development_positive_production_route_exclusion",
  },
  "production-packages": {
    fresh_production_compiles: "PHASE252_ASSERTION=fresh_production_compiles",
    actual_unpacked_hex_archives: "PHASE252_ASSERTION=actual_unpacked_hex_archives",
  },
});

const TEST_ASSERTION_BINDINGS = Object.freeze({
  "phase252-lab-contract": {
    owned_resource_identity: ["health identity must match"],
    unsafe_input_refusal: ["requires a fresh explicit numeric test partition"],
    cleanup_identity_guard: ["accepts cleanup only when PID"],
    namespace_lock_one_owner: ["namespace locks admit one owner"],
    stale_lock_owner_refusal: ["stale lock owner cannot remove"],
    exact_process_identity_cleanup: ["accepts cleanup only when PID"],
    owned_process_group_identity: ["health identity must match"],
  },
  "scenario-domain": {
    validated_deterministic_scenarios: ["all canonical lifecycle facts validate"],
    fixed_clock_and_identity: ["repeated fact fetches retain stable IDs"],
    deterministic_fact_source: ["launch and growing-team facts share"],
    canceling_boundary_exact_clock: ["canceling boundary follows the canonical predicate"],
    exact_minor_unit_money_precision: ["money controls accept exact zero and large minor units"],
  },
  "subscription-area": {
    production_area_content: ["production area retains the semantic hierarchy and full copied ID"],
    copy_and_scoped_action_semantics: ["summary action links and buttons expose the complete context exactly once", "generic summary action without context keeps its visible accessible name"],
  },
  "story-slice": {
    shared_renderer_and_active_variation: ["all canonical lifecycle variations delegate to the shared production area"],
    no_repo_bootstrap: ["declared active variation renders the production area from real facts without Repo"],
    subscription_story_uses_full_width_layout: ["subscription story declares the one-column layout for its preview"],
  },
  "manifest-contract": {
    compiled_variation_routes: ["compiled subscription story discovers each real retained variation"],
    stable_group_and_same_id_keys: ["grouped and same-ID declarations keep path and group identity"],
    current_caller_map: ["current caller map reconciles production sources"],
    stale_manifest_rejection: ["generated manifest verification rejects stale source digests"],
    story_variation_identity_adjacency: ["compiled subscription story discovers each real retained variation"],
    zero_variation_and_missing_attribution_refusal: ["zero, duplicate, missing-ID, and missing-attribution declarations fail closed"],
    deterministic_manifest_ordering: ["current caller map reconciles production sources"],
    caller_identity_adjacency: ["current caller map reconciles production sources"],
    empty_caller_source_refusal: ["caller map rejects empty and duplicate identities"],
    stable_caller_ordering: ["caller map rejects empty and duplicate identities"],
  },
  "production-boundary-db-free": {
    production_route_and_compile_boundary: ["prod-like route table omits Storybook, test, and lab routes"],
  },
  "phase248-heldout-contract": {
    held_out_partition_and_owner: ["held-out config rejects disabled sandbox before shared lifecycle loads", "held-out cleanup locks its customer before validating children"],
  },
  "phase252-ci-contract": {
    consumed_root_owner_map: ["every consumed source root maps to the named required CI owner"],
    workflow_admission: ["pull_request admission rejects path filters and exclusions"],
    named_required_owner_execution: ["the real required owner invokes the complete phase252 leaf"],
    required_owner_invocation_mutations: ["workflow and runner chain must retain the named owner invocation", "the named required job cannot be skipped or made optional"],
  },
  "scenario-repo": {
    persisted_launch_and_team_facts: ["persists launch and growing-team source facts"],
    database_constraints: ["migrated Postgres rejects invalid foreign keys"],
    replay_identity_conflict_refusal: ["replay is stable and conflicting source or processor identities are refused"],
    transaction_rollback: ["rolls back a failed middle insert"],
    concurrent_insert_serialization: ["rolls back a failed middle insert and serializes competing inserts"],
  },
  "registry-kitchen-mount-scoped-path": {
    registry_variant_and_token_reconciliation: ["every registry variant appears in the /dev/components page render", "all tokens listed in ComponentRegistry.entries() are defined"],
    group_contract_and_mounted_kitchen: ["mounted kitchen renders exactly one proof root for each group contract", "mounted group specimens expose deterministic operator-stress states"],
    production_caller_map_reconciliation: ["subscription composition coverage reconciles registry families"],
    served_storybook_assets: ["serves committed storybook css and js bundles"],
    development_and_production_route_boundaries: ["prod-like route table omits Storybook, test, and lab routes"],
    scoped_return_path_safety: ["absolute, foreign-scope, and secret-bearing return input cannot redirect", "return path keeps destination filters"],
  },
  "mounted-subscription-regressions": {
    mounted_subscription_structure: ["renders the six-band detail structure with one related resources strip"],
    organization_scope_enforcement: ["subscription loader denies rows outside the active organization"],
    lifecycle_distinctions: ["lifecycle states stay distinct from scheduled cancellation"],
    action_review_and_confirmation: ["each eligible subscription action review identifies its target", "repeated confirmation and delayed step-up submission dispatch one cancellation"],
    provider_action_boundaries: ["crafted Braintree action events are rejected server-side", "definitive provider rejection is distinct from an ambiguous timeout"],
    authority_regression: ["out-of-scope subscription route redirects with denial flash"],
    scoped_not_found_regression: ["subscription loader denies rows outside the active organization"],
  },
  "heldout-cleanup": {
    exact_cleanup_authority: ["exact cleanup succeeds, tolerates absence, and refuses mismatched same-ID ownership"],
    unrelated_child_preserved: ["an unrelated child makes exact held-out cleanup refuse"],
    heldout_identity_separation: ["ordinary launch and team seeds persist shared facts"],
    cleanup_idempotency_absence_mismatch: ["exact cleanup succeeds, tolerates absence"],
    serialized_unrelated_child_concurrency: ["concurrent child insertion serializes before the cleanup child-set guard"],
  },
  "isolation-reset": {
    normal_reset_positive_control: ["ordinary reset deletes its marker"],
    review_data_unchanged_negative_control: ["ordinary reset deletes its marker and preserves review relationships byte-for-byte"],
    distinct_review_process_and_database: ["occupied listeners, wrong health identity, failed bootstrap and duplicate namespaces fail closed"],
    interrupted_descendant_cleanup_before_database_drop: ["interrupted launcher stops descendants before database teardown"],
    owned_descendants_cleanup_after_leader_exit: ["owned process-group cleanup handles live descendants after its leader exits"],
    unrelated_process_survives_group_cleanup: ["interrupted launcher stops descendants before database teardown"],
  },
  "phase252-acceptance-contract": {
    missing_command_rejection: ["missing and failed commands cannot become passing UAT evidence"],
    failed_command_rejection: ["missing and failed commands cannot become passing UAT evidence"],
    stale_source_and_asset_rejection: ["changed source and stale served asset bytes reject the bundle"],
    pooled_cell_rejection: ["pooled cells and incomplete UI or edge predicates are rejected"],
    missing_predicate_rejection: ["pooled cells and incomplete UI or edge predicates are rejected"],
    unsafe_evidence_path_rejection: ["unsafe result and log paths fail closed"],
    guide_contract_mutation_rejection: ["guide contract pins the actual owner command"],
    executed_tap_positive_control: ["TAP reporter accepts complete executed records"],
    skipped_required_test_rejection: ["TAP reporter rejects skipped required records"],
    missing_and_empty_report_rejection: ["TAP reporter rejects missing, empty, and truncated reports"],
    excluded_required_test_rejection: ["TAP reporter rejects excluded or mismatched required identities"],
    fake_assertion_ref_rejection: ["report assertion references bind to executed test identities"],
  },
});

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");
const uniqueSorted = (values) => [...new Set(values)].sort();

function fail(message) {
  throw new Error(`Phase 252 executed-test evidence: ${message}`);
}

function exactSet(actual, expected, label) {
  const left = uniqueSorted(actual);
  const right = uniqueSorted(expected);
  if (left.length !== actual.length || right.length !== expected.length || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(`${label} mismatch; expected ${right.length} identities and received ${left.length}`);
  }
}

function elixirString(value) {
  return value.replace(/\\n/g, " ").replace(/\\r/g, " ").replace(/\\"/g, '"').replace(/\\\\/g, "\\").replace(/[\r\n]+/g, " ");
}

export function expectedExUnitIdentities(root, testFiles) {
  const identities = [];
  for (const relativePath of testFiles) {
    const source = fs.readFileSync(path.join(root, relativePath), "utf8");
    let currentModule = null;
    let caseModule = null;
    for (const line of source.split(/\r?\n/)) {
      const moduleMatch = line.match(/^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)/);
      if (moduleMatch) currentModule = moduleMatch[1];
      if (/\buse\s+[\w.]*Case\b/.test(line)) {
        if (!currentModule) fail(`cannot identify test case module in ${relativePath}`);
        caseModule = currentModule;
      }
      for (const match of line.matchAll(/\btest\s+"((?:\\.|[^"\\])*)"/g)) {
        if (!caseModule) fail(`test has no source ExUnit.Case identity in ${relativePath}`);
        identities.push(`${caseModule}::test ${elixirString(match[1])}`);
      }
    }
  }
  if (identities.length === 0) fail(`required ExUnit test files declared no named tests: ${testFiles.join(", ")}`);
  if (new Set(identities).size !== identities.length) fail("source ExUnit identities are duplicated across required files");
  return identities;
}

export function expectedNodeTestIdentities(root, testFiles) {
  const identities = [];
  for (const relativePath of testFiles) {
    const source = fs.readFileSync(path.join(root, relativePath), "utf8");
    for (const match of source.matchAll(/\btest\s*\(\s*(["'`])((?:\\.|(?!\1)[^\\])*)\1/g)) {
      identities.push(match[2].replace(/\\(["'`\\])/g, "$1"));
    }
  }
  if (identities.length === 0) fail(`required Node test files declared no named tests: ${testFiles.join(", ")}`);
  if (new Set(identities).size !== identities.length) fail("source Node test titles are duplicated across required files");
  return identities;
}

export function parseTap13Report(output, { format }) {
  if (typeof output !== "string" || output.trim() === "") fail("required TAP reporter output is missing or empty");
  const lines = output.split(/\r?\n/);
  const start = lines.findIndex((line) => line.trim() === "TAP version 13");
  if (start < 0) fail("required TAP version 13 header is missing");
  const plans = [];
  const records = [];
  let planIndex = -1;
  for (let index = start + 1; index < lines.length; index += 1) {
    const line = lines[index].trim();
    const plan = line.match(/^1\.\.(\d+)$/);
    if (plan) {
      plans.push(Number(plan[1]));
      planIndex = index;
      break;
    }
    const record = line.match(/^(ok|not ok)\s+(\d+)(?:\s+-\s+(.+))?$/);
    if (!record) continue;
    const title = record[3] || "";
    if (record[1] !== "ok") fail(`required test failed: ${title || record[2]}`);
    if (/\s#\s*(?:SKIP|TODO)\b/i.test(title)) fail(`required test was skipped or marked TODO: ${title}`);
    if (!title) fail(`TAP record ${record[2]} has no named test identity`);
    records.push({ number: Number(record[2]), identity: title });
  }
  if (plans.length !== 1 || planIndex < 0) fail("required TAP plan is missing or ambiguous");
  if (plans[0] <= 0) fail("required TAP report contains zero executed tests");
  if (records.length !== plans[0]) fail(`TAP plan declared ${plans[0]} tests but reported ${records.length}`);
  for (let index = 0; index < records.length; index += 1) {
    if (records[index].number !== index + 1) fail("TAP test numbering is missing, repeated, or out of order");
  }
  const identities = records.map(({ identity }) => identity);
  if (new Set(identities).size !== identities.length) fail("TAP report repeats a test identity");
  if (format === "node-tap") {
    const summary = Object.fromEntries([...lines.slice(planIndex + 1).join("\n").matchAll(/^# (tests|pass|fail|cancelled|skipped|todo) (\d+)$/gm)].map((match) => [match[1], Number(match[2])]));
    if (summary.tests !== records.length || summary.pass !== records.length || summary.fail !== 0 || summary.cancelled !== 0 || summary.skipped !== 0 || summary.todo !== 0) {
      fail("Node TAP summary is missing, incomplete, or reports failed, cancelled, skipped, or TODO tests");
    }
  }
  return { identities, count: records.length, skipped: 0, failed: 0 };
}

function parsePlaywrightJson(output) {
  let report;
  try {
    report = JSON.parse(output);
  } catch {
    fail("Playwright JSON reporter output is not a single valid JSON report");
  }
  if (!report || report.status !== "passed" || !Array.isArray(report.suites)) fail("Playwright report status or suites are missing");
  const tests = [];
  const visit = (suite) => {
    for (const spec of suite.specs || []) {
      for (const test of spec.tests || []) {
        if (test.expectedStatus !== "passed" || !Array.isArray(test.results) || test.results.length !== 1 || test.results[0]?.status !== "passed") {
          fail(`browser test is failed, skipped, retried, or missing a result: ${test.title || spec.title || "<unnamed>"}`);
        }
        tests.push({ identity: test.title, status: test.results[0].status });
      }
    }
    for (const nested of suite.suites || []) visit(nested);
  };
  for (const suite of report.suites) visit(suite);
  const identities = tests.map(({ identity }) => identity);
  if (identities.length === 0 || identities.some((identity) => !identity) || new Set(identities).size !== identities.length) {
    fail("Playwright report is empty or contains unnamed/duplicate test identities");
  }
  return { identities, count: tests.length, skipped: 0, failed: 0 };
}

function bindAssertionIds(commandId, assertionIds, identities) {
  const commandBindings = TEST_ASSERTION_BINDINGS[commandId];
  if (!commandBindings) fail(`no named behavior binding is registered for ${commandId}`);
  exactSet(assertionIds, Object.keys(commandBindings), `${commandId} assertion definitions`);
  const bindings = {};
  for (const assertionId of assertionIds) {
    const matchers = commandBindings[assertionId];
    if (!Array.isArray(matchers) || matchers.length === 0) fail(`${commandId} assertion ${assertionId} has no reporter identity binding`);
    const matched = uniqueSorted(identities.filter((identity) => matchers.some((fragment) => identity.includes(fragment))));
    if (matched.length === 0) fail(`${commandId} assertion ${assertionId} has no matching executed reporter record`);
    bindings[assertionId] = matched;
  }
  return bindings;
}

function browserBindings(assertionIds, browserResult, identities) {
  const rows = browserResult?.cases;
  if (!Array.isArray(rows) || rows.length !== 15) fail("browser reporter cannot bind assertions without all 15 rendered result rows");
  const expectedIdentities = [...rows.map((row) => row.test_id), "reconciles every declared direct render against the generated manifest"];
  exactSet(identities, expectedIdentities, "Playwright and result-ledger test identities");
  const byAssertion = {
    exact_twelve_canonical_width_theme_cells: rows.filter((row) => row.case_kind === "canonical").map((row) => row.test_id),
    three_compatibility_render_cases: rows.filter((row) => row.case_kind === "compatibility").map((row) => row.test_id),
    manifest_reconciliation_negative_controls: ["reconciles every declared direct render against the generated manifest"],
    twenty_ui_predicates: rows.filter((row) => row.case_kind === "canonical").map((row) => row.test_id),
    served_assets_and_fonts: rows.map((row) => row.test_id),
  };
  exactSet(assertionIds, Object.keys(byAssertion), "browser assertion definitions");
  return Object.fromEntries(assertionIds.map((id) => {
    const selected = uniqueSorted(byAssertion[id]);
    if (selected.length === 0 || selected.some((identity) => !identities.includes(identity))) fail(`browser assertion ${id} has no executed test identity`);
    return [id, selected];
  }));
}

function processAssertions(commandId, output) {
  const markers = PROCESS_MARKERS[commandId];
  if (!markers) fail(`process lane ${commandId} has no marker contract`);
  const lines = new Set(output.split(/\r?\n/).map((line) => line.trim()));
  const assertions = Object.entries(markers).filter(([, marker]) => lines.has(marker)).map(([assertion]) => assertion);
  exactSet(assertions, Object.keys(markers), `${commandId} process markers`);
  if (commandId === "production-packages") {
    const packagePasses = [...output.matchAll(/^PASS (accrue|accrue_admin|accrue_portal): isolated production compile, actual Hex package contents, and runtime boundary \((\d+) files\)\.$/gm)];
    exactSet(packagePasses.map((match) => match[1]), ["accrue", "accrue_admin", "accrue_portal"], "production package process output");
    if (packagePasses.some((match) => Number(match[2]) <= 0) || !lines.has("Phase 252 production package boundary verified for all three packages.")) {
      fail("production package output lacks fresh compile and unpacked archive completion evidence");
    }
  }
  return assertions;
}

export function deriveExecutionEvidence({ root, commandId, stdout, expectedAssertions, browserResult = null }) {
  const spec = PHASE252_REPORTER_SPECS[commandId];
  if (!spec) fail(`required command ${commandId} has no reporter specification`);
  let actualAssertions;
  let assertionBindings = {};
  let parsed;
  if (spec.kind === "node-tap" || spec.kind === "exunit-tap") {
    parsed = parseTap13Report(stdout, { format: spec.kind });
    const expected = spec.kind === "node-tap"
      ? expectedNodeTestIdentities(root, spec.testFiles)
      : expectedExUnitIdentities(root, spec.testFiles);
    exactSet(parsed.identities, expected, `${commandId} executed test identities`);
    if (parsed.count !== expected.length) fail(`${commandId} executed count differs from its required source test count`);
    assertionBindings = bindAssertionIds(commandId, expectedAssertions, parsed.identities);
    actualAssertions = expectedAssertions;
  } else if (spec.kind === "playwright-json") {
    parsed = parsePlaywrightJson(stdout);
    assertionBindings = browserBindings(expectedAssertions, browserResult, parsed.identities);
    actualAssertions = expectedAssertions;
  } else {
    actualAssertions = processAssertions(commandId, stdout);
    exactSet(actualAssertions, expectedAssertions, `${commandId} expected assertion refs`);
  }
  return {
    assertion_refs: actualAssertions,
    execution_evidence: {
      kind: spec.kind,
      stdout_sha256: sha256(stdout),
      test_count: parsed?.count ?? null,
      skipped: parsed?.skipped ?? 0,
      failed: parsed?.failed ?? 0,
      test_identities: parsed?.identities ?? [],
      assertion_bindings: assertionBindings,
    },
  };
}

export function requiredAssertionIds(commandId) {
  const spec = PHASE252_REPORTER_SPECS[commandId];
  if (!spec) fail(`required command ${commandId} has no reporter specification`);
  const ids = spec.kind === "process-markers"
    ? Object.keys(PROCESS_MARKERS[commandId] || {})
    : spec.kind === "playwright-json"
      ? ["exact_twelve_canonical_width_theme_cells", "three_compatibility_render_cases", "manifest_reconciliation_negative_controls", "twenty_ui_predicates", "served_assets_and_fonts"]
      : Object.keys(TEST_ASSERTION_BINDINGS[commandId] || {});
  if (ids.length === 0) fail(`required command ${commandId} has no named assertion contract`);
  return ids;
}
