#!/usr/bin/env node
// Phase 254 CIQ-02: contract tests for the shared cell universe, the tracked selection projection,
// the D-12 sentinel set and the D-14 control set. Each D-14 control and each FC rule is its own
// named test. Diff fixtures use scratch repositories under the OS temp directory, never the live tree.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { CONSUMED_ROOTS, classifyPath } from "./phase252_paths.mjs";
import * as selection from "./phase254_selection.mjs";
import { expectedPhase252Cells, readCurationLedger } from "./verify_phase254_curation.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "../..");
const universe = createRequire(import.meta.url)("../../accrue_admin/e2e/phase253-cell-universe.js");

// Pinned: sha256 of the sorted JSON array of the 151 keys that the pre-extraction helpers produced
// for the compiled Phase 253 manifest (computed from the HEAD helpers before the extraction).
const PINNED_CELL_KEYS_SHA256 = "5f108b264b77a014dcceae480291c384a0f9739afbc855d39b9afad229440027";
// Pinned: changing any sentinel id (a reviewed edit) must change this digest and fail the test.
const PINNED_SENTINELS_SHA256 = "30d80bffd87e109e01e2853e1a8fbe92270634a3a2a4f3403e8eccf721f6b862";

const SHARED = [
  "accrue_admin/lib/accrue_admin/dev/storybook.ex",
  "accrue_admin/lib/accrue_admin/queries/subscriptions.ex",
  "accrue_admin/lib/accrue_admin/router.ex",
  "accrue_admin/storybook/_support/subscription_compositions_manifest.ex",
  "dev_support/ui_scenarios/cadence_subscriptions.exs",
];
const COLLECTION_ONLY = [
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/storybook/_support/subscription_collection.ex",
  "storybook/groups/subscriptions_collection.story.exs",
];
const PAGE_ONLY = [
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/storybook/_support/subscription_page_scenarios.ex",
  "storybook/pages/subscription.story.exs",
];

function digestMap(paths) {
  return Object.fromEntries(paths.map((entry) => [entry, "0".repeat(64)]));
}

function fixtureManifest() {
  const collectionDeps = [...SHARED, ...COLLECTION_ONLY].sort();
  const pageDeps = [...SHARED, ...PAGE_ONLY].sort();
  return {
    source_digests: digestMap([...SHARED, ...COLLECTION_ONLY, ...PAGE_ONLY]),
    collection_variations: universe.COLLECTION_STATES.map((id) => ({
      story_path: "/groups/subscriptions_collection",
      variation_id: id,
      collection_state: id,
      scenario_id: "launch",
      iframe_path: `/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=${id}`,
      production_renderer: "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1",
      fact_source: "CadenceSubscriptionFacts.fetch!(:launch)",
      proof_lane: "presentation-only",
      expected: {},
      depends_on: collectionDeps,
    })),
    page_entries: universe.PAGE_VARIATIONS.map((id) => ({
      story_path: "/pages/subscription",
      variation_id: id,
      direct_path: `/billing/dev/storybook/pages/subscription?tab=${id}`,
      presentation_snapshot: "canonical",
      production_renderer: "AccrueAdmin.Live.SubscriptionLive.subscription_page/1",
      fact_source: "CadenceSubscriptionFacts.fetch!(:active)",
      proof_lane: "presentation-only",
      expected: { scenario: "active", snapshot: "canonical" },
      depends_on: pageDeps,
    })),
  };
}

const committed = () => selection.readProjection(ROOT).projection;
const ledger = () => readCurationLedger(ROOT);
const phase252Manifest = () => JSON.parse(fs.readFileSync(path.join(ROOT, selection.PHASE252_MANIFEST_PATH), "utf8"));

function select(projection, paths, overrides = {}) {
  return selection.selectCases({
    projection,
    run: { event: selection.LOCAL_FIXTURE_EVENT },
    changedPaths: paths.map((entry) => (typeof entry === "string" ? { status: "M", path: entry } : entry)),
    ...overrides,
  });
}

function gitEnv() {
  const env = { ...process.env };
  for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_PREFIX"]) delete env[name];
  return env;
}

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-test-"));
  const run = (...args) => {
    const result = spawnSync("git", ["-C", dir, "-c", "core.hooksPath=/dev/null", "-c", "user.email=fixture@example.test", "-c", "user.name=fixture", "-c", "commit.gpgsign=false", ...args], { encoding: "utf8", env: gitEnv() });
    assert.equal(result.status, 0, result.stderr);
    return result.stdout.trim();
  };
  const write = (relative, content) => {
    const file = path.join(dir, relative);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, content);
  };
  try {
    run("init", "-q");
    return fn({ dir, run, write });
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

// Two commits in a scratch repo; the diff base..head is the supplied change set.
function scratchDiff(changes) {
  return withScratchRepo(({ dir, run, write }) => {
    write("README.md", "base\n");
    for (const [relative] of changes.filter(([, kind]) => kind !== "add")) write(relative, "base\n");
    run("add", "-A");
    run("commit", "-q", "-m", "base");
    const base = run("rev-parse", "HEAD");
    for (const [relative, kind, target] of changes) {
      if (kind === "add" || kind === "modify") write(relative, "changed\n");
      if (kind === "delete") fs.rmSync(path.join(dir, relative));
      if (kind === "move") {
        fs.mkdirSync(path.dirname(path.join(dir, target)), { recursive: true });
        fs.renameSync(path.join(dir, relative), path.join(dir, target));
      }
    }
    run("add", "-A");
    run("commit", "-q", "-m", "head");
    const head = run("rev-parse", "HEAD");
    return selection.readChangedPaths({ base, head, event: "pull_request", root: dir });
  });
}

// --- 254-07-02: shared cell universe and projection ---------------------------------------------

test("the shared cell universe imports with no side effects and the helpers consume it", () => {
  const probe = spawnSync(process.execPath, ["-e", [
    `const before = Object.keys(require.cache).length;`,
    `require(${JSON.stringify(path.join(ROOT, "accrue_admin/e2e/phase253-cell-universe.js"))});`,
    `const loaded = Object.keys(require.cache).filter((file) => /playwright|node_modules/.test(file));`,
    `process.exit(loaded.length === 0 && Object.keys(require.cache).length === before + 1 ? 0 : 1);`,
  ].join("\n")], { encoding: "utf8", env: { ...process.env, PHASE252_E2E_NONCE: "" } });
  assert.equal(probe.status, 0, probe.stderr);

  const helpers = fs.readFileSync(path.join(ROOT, "accrue_admin/e2e/phase253-composition-helpers.js"), "utf8");
  assert.match(helpers, /require\("\.\/phase253-cell-universe\.js"\)/);
  for (const moved of ["function createCollectionCases", "function createPageCases", "function createPageStressCases", "function createExpectedBrowserCellDefinitions"]) {
    assert.equal(helpers.includes(moved), false, `${moved} must live only in the shared module`);
  }
  // positive control: the moved builders are really defined in the shared module
  const shared = fs.readFileSync(path.join(ROOT, "accrue_admin/e2e/phase253-cell-universe.js"), "utf8");
  for (const moved of ["function createCollectionCases", "function createExpectedBrowserCellDefinitions", "function cellKey"]) assert.ok(shared.includes(moved), moved);
});

test("the shared universe produces the identical 151 keys as before the extraction", () => {
  const keys = universe.createExpectedBrowserCellDefinitions(fixtureManifest()).map((definition) => definition.key);
  assert.equal(keys.length, 151);
  assert.equal(new Set(keys).size, 151);
  assert.equal(selection.sha256(JSON.stringify([...keys].sort())), PINNED_CELL_KEYS_SHA256);
  assert.equal(universe.cellKey({ story_path: "/pages/subscription", variation_id: "active" }, 320, "dark"), "page::active::viewport::320::dark");
  assert.equal(universe.cellKey({ story_path: "/groups/subscriptions_collection", variation_id: "one_row" }, 320, "dark"), "one_row::viewport::320::dark");
});

test("the committed projection equals the shared cell universe and the ledger-derived Phase 252 total (derived, no literal)", () => {
  const projection = committed();
  const keys = universe.createExpectedBrowserCellDefinitions(fixtureManifest()).map((definition) => definition.key).sort();
  assert.deepEqual(projection.cases.map((item) => item.id), keys);
  assert.equal(projection.cases.length, projection.expected_case_count);
  assert.equal(projection.always_run.length, expectedPhase252Cells(ledger()).total);
  assert.equal(new Set(projection.cases.map((item) => item.id)).size, projection.cases.length);
  assert.equal(selection.assertProjectionShape(projection), true);
  for (const item of projection.cases) {
    assert.equal(item.fixture_class, "pure-story");
    assert.equal(item.schedule, "pr-selectable");
    assert.ok(item.depends_on.length > 0 && item.depends_on.every((source) => source in projection.source_digests), item.id);
  }
});

test("buildProjection from a fixture manifest regenerates the same ids and rejects a depends_on outside source_digests", () => {
  const built = selection.buildProjection({ manifest: fixtureManifest(), phase252Manifest: phase252Manifest(), ledger: ledger() });
  assert.deepEqual(built.cases.map((item) => item.id), committed().cases.map((item) => item.id));
  assert.equal(built.always_run.length, expectedPhase252Cells(ledger()).total);

  const outside = fixtureManifest();
  outside.page_entries[0].depends_on = [...outside.page_entries[0].depends_on, "accrue/lib/accrue.ex"].sort();
  assert.throws(() => selection.buildProjection({ manifest: outside, phase252Manifest: phase252Manifest(), ledger: ledger() }), /outside source_digests/);
  const empty = fixtureManifest();
  empty.collection_variations[0].depends_on = [];
  assert.throws(() => selection.buildProjection({ manifest: empty, phase252Manifest: phase252Manifest(), ledger: ledger() }), /no depends_on/);
});

test("project --check semantics: a projection with a removed case is reported stale and the unchanged one passes", () => {
  const projection = committed();
  const regenerated = selection.buildProjection({ manifest: fixtureManifest(), phase252Manifest: phase252Manifest(), ledger: ledger() });
  // the fixture manifest is a different digest source, so compare the case universe only
  assert.doesNotThrow(() => selection.assertProjectionCurrent({ cases: projection.cases }, { cases: regenerated.cases }));
  const removed = { cases: projection.cases.slice(1) };
  assert.throws(() => selection.assertProjectionCurrent(removed, { cases: regenerated.cases }), /is stale; regenerate it with node scripts\/ci\/phase254_selection\.mjs project --write/);
});

function sentinelCoverageGaps(sentinels) {
  const gaps = [];
  const has = (predicate) => sentinels.some(predicate);
  if (sentinels.length < 6 || sentinels.length > 10) gaps.push("about eight sentinels");
  for (const theme of ["light", "dark"]) if (!has((item) => item.theme === theme)) gaps.push(`theme ${theme}`);
  for (const width of [320, 1280]) if (!has((item) => item.width === width)) gaps.push(`width ${width}`);
  for (const tier of ["collection", "page"]) if (!has((item) => item.tier === tier)) gaps.push(`tier ${tier}`);
  if (!has((item) => item.page_role === "overlay_result")) gaps.push("overlay page");
  if (!has((item) => item.id.includes("::breakpoint::767::"))) gaps.push("767 edge");
  if (!has((item) => item.id.includes("::breakpoint::768::"))) gaps.push("768 edge");
  if (!has((item) => item.case_kind === "synthetic_text_stress")) gaps.push("synthetic-text stress");
  if (!has((item) => item.case_kind === "geometry_negative_controls")) gaps.push("geometry negative control");
  return gaps;
}

test("sentinel set satisfies every D-12 coverage criterion and the checker finds a seeded gap", () => {
  const projection = committed();
  const byId = new Map(projection.cases.map((item) => [item.id, item]));
  const sentinels = projection.sentinels.map((id) => byId.get(id));
  assert.ok(sentinels.every(Boolean), "every sentinel is a case id");
  assert.deepEqual(sentinelCoverageGaps(sentinels), []);
  // positive controls: dropping the geometry control, the overlay page or one theme is detected
  assert.deepEqual(sentinelCoverageGaps(sentinels.filter((item) => item.case_kind !== "geometry_negative_controls")), ["geometry negative control"]);
  assert.ok(sentinelCoverageGaps(sentinels.filter((item) => item.page_role !== "overlay_result")).includes("overlay page"));
  assert.ok(sentinelCoverageGaps(sentinels.filter((item) => item.theme !== "dark")).includes("theme dark"));
});

test("the sentinel digest is pinned: changing one id changes it", () => {
  const projection = committed();
  assert.equal(projection.sentinels_sha256, PINNED_SENTINELS_SHA256);
  assert.equal(selection.sentinelsDigest(selection.SENTINEL_IDS), PINNED_SENTINELS_SHA256);
  const mutated = [...selection.SENTINEL_IDS];
  mutated[0] = "geometry::negative-controls::320::dark";
  assert.notEqual(selection.sentinelsDigest(mutated), PINNED_SENTINELS_SHA256);
  const tampered = structuredClone(projection);
  tampered.sentinels = [...mutated].sort();
  assert.throws(() => selection.assertProjectionShape(tampered), /sentinel/);
});

test("global roots and the irrelevant allowlist are explicit, and no allowlist entry contains a consumed root", () => {
  const projection = committed();
  const globalIds = projection.global_roots.map((rule) => rule.id);
  for (const required of ["admin-css-source", "admin-built-static", "brandbook-tokens", "storybook-backend", "admin-router", "copy-owner", "ui-scenarios", "playwright-config", "playwright-lab-config", "browser-specs-and-helpers", "selector", "required-ci-workflow", "lab-runner", "mix-lockfile", "npm-lockfile"]) {
    assert.ok(globalIds.includes(required), required);
  }
  assert.deepEqual(projection.irrelevant_allowlist.map((rule) => rule.path), ["docs/", "prompts/", ".planning/research/"]);
  for (const rule of projection.irrelevant_allowlist) {
    assert.equal(classifyPath(`${rule.path}representative.md`), null, `${rule.id} must not be a consumed root`);
    assert.equal(CONSUMED_ROOTS.some((consumed) => consumed.path.startsWith(rule.path)), false, rule.id);
  }
  // positive control: the classifier does find a consumed root, so the zero above is evidence
  assert.notEqual(classifyPath("storybook/components/subscription_detail.story.exs"), null);
});

// --- 254-07-03: select verb, report and the D-14 control set --------------------------------------

test("D-14 control: a collection-only change selects affected cases with a non-empty exclusion list", () => {
  const projection = committed();
  const report = select(projection, ["storybook/groups/subscriptions_collection.story.exs"]);
  assert.equal(report.mode, "affected");
  assert.ok(report.excluded.length > 0);
  const collection = projection.cases.filter((item) => item.tier === "collection").map((item) => item.id);
  for (const id of collection) assert.ok(report.selected.some((item) => item.id === id && item.reasons.includes("changed:depends_on")), id);
  assert.ok(projection.cases.filter((item) => item.tier === "page" && !projection.sentinels.includes(item.id)).every((item) => report.excluded.some((entry) => entry.id === item.id)));
  assert.equal(report.counts.selected + report.counts.excluded, report.counts.total);
});

test("D-14 control: a page-only change excludes collection cells (both tiers narrow)", () => {
  const projection = committed();
  const report = select(projection, ["accrue_admin/lib/accrue_admin/live/subscription_live.ex"]);
  assert.equal(report.mode, "affected");
  const collection = projection.cases.filter((item) => item.tier === "collection" && !projection.sentinels.includes(item.id));
  assert.ok(collection.every((item) => report.excluded.some((entry) => entry.id === item.id)));
});

test("D-14 control: docs/x.md selects exactly the sentinels", () => {
  const projection = committed();
  const report = select(projection, ["docs/x.md"]);
  assert.equal(report.mode, "affected");
  assert.deepEqual(report.selected.map((item) => item.id), [...projection.sentinels].sort());
  assert.ok(report.selected.every((item) => item.reasons.length === 1 && item.reasons[0] === "sentinel"));
});

for (const [name, changed] of [
  ["accrue/lib/accrue/x.ex", "accrue/lib/accrue/x.ex"],
  ["mix.lock", "mix.lock"],
  ["accrue_admin/assets/css/app.css", "accrue_admin/assets/css/app.css"],
]) {
  test(`D-14 control: ${name} selects full`, () => {
    const projection = committed();
    const report = select(projection, [changed]);
    assert.equal(report.mode, "full");
    assert.equal(report.counts.selected, projection.expected_case_count);
    assert.equal(report.excluded.length, 0);
  });
}

test("D-14 control: full mode selects every cell of the projection, equal to the shared universe count", () => {
  const projection = committed();
  const report = select(projection, ["mix.lock"]);
  assert.equal(report.counts.selected, universe.createExpectedBrowserCellDefinitions(fixtureManifest()).length);
  assert.equal(report.selected.length, projection.expected_case_count);
});

test("FC-1: an unmapped non-allowlisted path and an unsafe path are full, never irrelevant", () => {
  const projection = committed();
  for (const changed of ["scripts/ci/unrelated_new_tool.mjs", "../outside.txt", "/etc/passwd", "docs/../accrue/lib/x.ex", ""]) {
    const report = select(projection, [changed]);
    assert.equal(report.mode, "full", JSON.stringify(changed));
    assert.ok(report.mode_reasons.some((reason) => reason.startsWith("FC-1:")), JSON.stringify(changed));
  }
  // positive control: an allowlisted path stays affected
  assert.equal(select(projection, ["prompts/x.md"]).mode, "affected");
});

test("FC-1: an owner-mapped path without case scope is full", () => {
  const report = select(committed(), ["accrue_admin/lib/accrue_admin/components/detail.ex"]);
  assert.equal(report.mode, "full");
  assert.ok(report.mode_reasons.some((reason) => reason.startsWith("FC-1:owner-mapped-no-case-scope:")));
});

test("FC-2: every global root forces full", () => {
  const projection = committed();
  for (const rule of projection.global_roots) {
    const representative = rule.mode === "prefix" ? `${rule.path}representative.txt` : rule.mode === "basename" ? `nested/dir/${rule.path}` : rule.path;
    const report = select(projection, [representative]);
    assert.equal(report.mode, "full", rule.id);
    assert.ok(report.mode_reasons.some((reason) => reason.startsWith("FC-2:")), rule.id);
  }
});

test("FC-3: missing, zero, invalid and unreachable bases, shallow clones, diff errors and non-PR events are full with a named reason", () => {
  const cases = [
    [{ base: "", head: "abc1234", event: "pull_request" }, "FC-3:missing-base"],
    [{ base: undefined, head: "abc1234", event: "pull_request" }, "FC-3:missing-base"],
    [{ base: "0".repeat(40), head: "abc1234", event: "pull_request" }, "FC-3:zero-base"],
    [{ base: "not a sha", head: "abc1234", event: "pull_request" }, "FC-3:invalid-base"],
    [{ base: "abc1234", head: "def5678", event: "push" }, "FC-3:non-pr-event:push"],
    [{ base: "abc1234", head: "def5678", event: "workflow_dispatch" }, "FC-3:non-pr-event:workflow_dispatch"],
    [{ base: "abc1234", head: "def5678", event: undefined }, "FC-3:non-pr-event:none"],
  ];
  const projection = committed();
  for (const [input, reason] of cases) {
    const read = selection.readChangedPaths({ ...input, root: ROOT });
    assert.deepEqual(read.fullReasons, [reason]);
    const report = selection.selectCases({ projection, run: read.run, changedPaths: read.changedPaths, fullReasons: read.fullReasons });
    assert.equal(report.mode, "full");
    assert.ok(report.mode_reasons.includes(reason));
    assert.equal(report.excluded.length, 0);
  }
  withScratchRepo(({ dir, run, write }) => {
    write("a.txt", "a\n");
    run("add", "-A");
    run("commit", "-q", "-m", "one");
    const base = run("rev-parse", "HEAD");
    write("docs/b.txt", "b\n");
    run("add", "-A");
    run("commit", "-q", "-m", "two");
    const head = run("rev-parse", "HEAD");
    assert.deepEqual(selection.readChangedPaths({ base: "1".repeat(40), head, event: "pull_request", root: dir }).fullReasons, ["FC-3:unreachable-base"]);
    assert.deepEqual(selection.readChangedPaths({ base, head: "2".repeat(40), event: "pull_request", root: dir }).fullReasons, ["FC-3:unreachable-head"]);
    const clone = `${dir}-shallow`;
    try {
      const cloned = spawnSync("git", ["clone", "-q", "--depth", "1", `file://${dir}`, clone], { encoding: "utf8", env: gitEnv() });
      assert.equal(cloned.status, 0, cloned.stderr);
      assert.deepEqual(selection.readChangedPaths({ base, head, event: "pull_request", root: clone }).fullReasons, ["FC-3:shallow-clone"]);
    } finally {
      fs.rmSync(clone, { recursive: true, force: true });
    }
    // positive control: the same repository with a reachable base and a full history gives a real diff
    const ok = selection.readChangedPaths({ base, head, event: "pull_request", root: dir });
    assert.equal(ok.run.diff_status, "ok");
    assert.deepEqual(ok.changedPaths, [{ status: "A", path: "docs/b.txt" }]);
  });
  const notARepo = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-norepo-"));
  try {
    const failed = selection.readChangedPaths({ base: "abc1234", head: "def5678", event: "pull_request", root: notARepo });
    assert.deepEqual(failed.fullReasons, ["FC-3:diff-error"]);
    assert.equal(failed.run.diff_status, "failed");
  } finally {
    fs.rmSync(notARepo, { recursive: true, force: true });
  }
});

test("FC-3: a real scratch diff with a modified collection story is affected, and a rename to docs/ maps the old path", () => {
  const projection = committed();
  const modified = scratchDiff([["storybook/groups/subscriptions_collection.story.exs", "modify"]]);
  const modifiedReport = selection.selectCases({ projection, run: modified.run, changedPaths: modified.changedPaths, fullReasons: modified.fullReasons });
  assert.equal(modifiedReport.mode, "affected");
  assert.ok(modifiedReport.excluded.length > 0);

  const moved = scratchDiff([["storybook/groups/subscriptions_collection.story.exs", "move", "docs/moved.md"]]);
  assert.deepEqual(moved.changedPaths.map((item) => `${item.status}:${item.path}`).sort(), ["A:docs/moved.md", "D:storybook/groups/subscriptions_collection.story.exs"]);
  const movedReport = selection.selectCases({ projection, run: moved.run, changedPaths: moved.changedPaths, fullReasons: moved.fullReasons });
  assert.equal(movedReport.mode, "affected");
  assert.ok(movedReport.changed_paths.some((item) => item.status === "D" && item.class === "case-scoped"), "old path maps");
  assert.ok(movedReport.counts.selected > projection.sentinels.length);

  const docsOnly = scratchDiff([["docs/x.md", "add"]]);
  const docsReport = selection.selectCases({ projection, run: docsOnly.run, changedPaths: docsOnly.changedPaths, fullReasons: docsOnly.fullReasons });
  assert.deepEqual(docsReport.selected.map((item) => item.id), [...projection.sentinels].sort());
});

test("FC-4: a case without depends_on is always selected as broaden:no-metadata", () => {
  const projection = structuredClone(committed());
  const target = projection.cases.find((item) => !projection.sentinels.includes(item.id));
  delete target.depends_on;
  const report = select(projection, ["docs/x.md"]);
  assert.equal(report.mode, "affected");
  assert.deepEqual(report.selected.find((item) => item.id === target.id).reasons, ["broaden:no-metadata"]);
  const emptied = structuredClone(committed());
  emptied.cases.find((item) => item.id === target.id).depends_on = [];
  assert.deepEqual(select(emptied, ["docs/x.md"]).selected.find((item) => item.id === target.id).reasons, ["broaden:no-metadata"]);
});

test("FC-4: a path that matches two conflicting classes gives full", () => {
  const projection = structuredClone(committed());
  projection.source_digests["docs/x.md"] = "0".repeat(64);
  projection.cases.find((item) => !projection.sentinels.includes(item.id)).depends_on = ["docs/x.md"];
  const report = select(projection, ["docs/x.md"]);
  assert.equal(report.mode, "full");
  assert.ok(report.mode_reasons.some((reason) => reason.startsWith("FC-4:conflict:docs/x.md")));
});

test("FC-5: invariant breaches hard-fail (overlap, union, missing sentinel, stale sentinel)", () => {
  const projection = committed();
  const report = select(projection, ["docs/x.md"]);
  assert.equal(selection.assertSelectionInvariants(report), true);
  const overlap = structuredClone(report);
  overlap.excluded.push({ id: overlap.selected[0].id, reason: "x" });
  assert.throws(() => selection.assertSelectionInvariants(overlap), /overlap/);
  const incomplete = structuredClone(report);
  incomplete.excluded.pop();
  assert.throws(() => selection.assertSelectionInvariants(incomplete), /selected plus excluded versus total_ids/);
  const noSentinel = structuredClone(report);
  const sentinel = noSentinel.sentinels[0];
  noSentinel.selected = noSentinel.selected.filter((item) => item.id !== sentinel);
  noSentinel.excluded.push({ id: sentinel, reason: "x" });
  assert.throws(() => selection.assertSelectionInvariants(noSentinel), /omits sentinels/);
  const stale = structuredClone(report);
  stale.sentinels = [...stale.sentinels.slice(1), "ghost::viewport::1::light"];
  stale.sentinels_sha256 = selection.sentinelsDigest(stale.sentinels);
  assert.throws(() => selection.assertSelectionInvariants(stale), /stale sentinel/);
  const fullWithExcluded = structuredClone(select(projection, ["mix.lock"]));
  fullWithExcluded.excluded.push({ id: fullWithExcluded.selected.pop().id, reason: "x" });
  assert.throws(() => selection.assertSelectionInvariants(fullWithExcluded), /full mode/);
});

test("FC-5: a stale or forged projection hard-fails before any narrowing", () => {
  const projection = committed();
  assert.equal(selection.verifyProjectionFresh(projection, { root: ROOT }), true);
  const [first] = Object.keys(projection.source_digests);
  const stale = structuredClone(projection);
  stale.source_digests[first] = "f".repeat(64);
  assert.throws(() => selection.verifyProjectionFresh(stale, { root: ROOT }), /the projection is stale/);
  const forged = structuredClone(projection);
  forged.cases[0].depends_on = [...forged.cases[0].depends_on, "accrue/lib/accrue.ex"].sort();
  assert.throws(() => selection.assertProjectionShape(forged), /outside source_digests/);
  const ledgerDrift = structuredClone(projection);
  ledgerDrift.curation_ledger_sha256 = "0".repeat(64);
  assert.throws(() => selection.verifyProjectionFresh(ledgerDrift, { root: ROOT }), /the projection is stale/);
});

test("the report records run context, digests, classified paths, per-case metadata, reasons and always-run lists", () => {
  const projection = committed();
  const read = selection.readChangedPathsFile("scripts/ci/fixtures/phase254-selection/collection-only.txt", { root: ROOT });
  const report = selection.selectCases({ projection, run: { ...read.run, workflow: "ci", job: "guardrails", run_id: "1" }, changedPaths: read.changedPaths, fullReasons: read.fullReasons, projectionSha256: "a".repeat(64), selectorSha256: "b".repeat(64), fixtureSource: read.fixtureSource });
  for (const key of ["run", "manifest_sha256", "projection_sha256", "selector_sha256", "changed_paths", "mode", "mode_reasons", "total_ids", "selected", "excluded", "sentinels", "sentinels_sha256", "cases", "always_run"]) {
    assert.ok(key in report, key);
  }
  assert.equal(report.run.event, "local-fixture");
  assert.equal(report.run.diff_status, "fixture");
  assert.ok(report.mode_reasons.some((reason) => reason.startsWith("fixture:scripts/ci/fixtures/phase254-selection/collection-only.txt")));
  assert.deepEqual(report.total_ids, [...report.total_ids].sort());
  assert.equal(report.cases.length, report.total_ids.length);
  assert.ok(report.cases.every((item) => item.fixture_class === "pure-story" && item.schedule === "pr-selectable"));
  assert.equal(report.always_run.length, projection.always_run.length);
  assert.equal(report.mode, "affected");
  assert.ok(report.changed_paths[0].case_ids.length > 0 && report.changed_paths[0].class === "case-scoped");
});

test("renderSelectionSummary states mode, counts and excluded ids and escapes hostile path names", () => {
  const projection = committed();
  const hostile = ["docs/a|b`c$(whoami)::error::x\nnext.md", "docs/<script>alert(1)</script>.md"];
  const report = select(projection, hostile);
  const markdown = selection.renderSelectionSummary(report);
  assert.match(markdown, /Mode: \*\*affected\*\*/);
  assert.match(markdown, new RegExp(`Selected: ${report.counts.selected} of ${report.counts.total} cases; excluded: ${report.counts.excluded}`));
  assert.match(markdown, /not the full sweep/);
  for (const excluded of report.excluded.slice(0, 3)) assert.ok(markdown.includes(selection.escapeMarkdown(excluded.id)));
  assert.doesNotMatch(markdown, /::error::/);
  assert.doesNotMatch(markdown, /\$\(/);
  assert.doesNotMatch(markdown, /<script>/);
  assert.doesNotMatch(markdown, /`/);
  const rows = markdown.split("\n").filter((line) => line.startsWith("| ") && !line.startsWith("| ---") && !line.startsWith("| Status"));
  assert.equal(rows.length, hostile.length);
  // positive control: the unescaped value really does contain those characters
  assert.match(hostile[0], /\||`|\$\(|::error::|\n/);
});

test("select CLI writes the report from the collection-only fixture and the summary names the excluded ids", () => {
  const out = path.join(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-cli-")), "selection.json");
  try {
    const result = spawnSync(process.execPath, [path.join(HERE, "phase254_selection.mjs"), "select", "--event", "pull_request", "--changed-paths-file", "scripts/ci/fixtures/phase254-selection/collection-only.txt", "--out", out, "--summary"], { cwd: ROOT, encoding: "utf8", env: { ...process.env, NODE_TEST_CONTEXT: "", GITHUB_STEP_SUMMARY: "" } });
    assert.equal(result.status, 0, result.stderr);
    const report = JSON.parse(fs.readFileSync(out, "utf8"));
    assert.equal(report.mode, "affected");
    assert.equal(report.run.event, "local-fixture");
    assert.ok(report.excluded.length > 0);
    assert.equal(selection.assertSelectionInvariants(report), true);
    assert.match(result.stdout, /Excluded case ids/);
    assert.match(result.stdout, new RegExp(`${report.counts.selected} of ${report.counts.total}`));
    assert.equal(report.projection_sha256, selection.readProjection(ROOT).projectionSha256);
    assert.equal(report.selector_sha256, selection.sha256(fs.readFileSync(path.join(HERE, "phase254_selection.mjs"))));
  } finally {
    fs.rmSync(path.dirname(out), { recursive: true, force: true });
  }
});

test("--self-test passes and names the hostile-path fixture", () => {
  const result = spawnSync(process.execPath, [path.join(HERE, "phase254_selection.mjs"), "--self-test"], { cwd: ROOT, encoding: "utf8", env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /hostile-path fixture/);
  assert.match(result.stdout, /Phase 254 selection self-test: PASS/);
});

test("the selector and the Playwright lane apply one shared set of report invariants", () => {
  const shared = createRequire(import.meta.url)("../../accrue_admin/e2e/phase254-selection-invariants.js");
  const helpers = createRequire(import.meta.url)("../../accrue_admin/e2e/phase253-composition-helpers.js");
  assert.equal(selection.assertSelectionInvariants, shared.assertSelectionInvariants, "the selector re-exports the shared function, not a copy");
  assert.equal(typeof helpers.resolveSelection, "function");
  const { projection, projectionSha256 } = selection.readProjection(ROOT);
  const report = selection.selectCases({ projection, run: { event: "local-fixture" }, changedPaths: [{ status: "M", path: "docs/x.md" }], projectionSha256 });
  assert.equal(shared.assertSelectionInvariants(report), true, "positive control: a real report passes");
  const forged = structuredClone(report);
  forged.selected = forged.selected.filter((item) => item.id !== forged.sentinels[0]);
  assert.throws(() => shared.assertSelectionInvariants(forged), (error) => error.code === "SELECTION_INVARIANT" && /Phase 254 selection:/.test(error.message));
  assert.throws(() => selection.assertSelectionInvariants(forged), (error) => error.code === "SELECTION_INVARIANT");
});
