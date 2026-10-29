#!/usr/bin/env node
// Phase 254 CIQ-02 selector core (D-09..D-14).
//
//   project --write|--check
//       Generate the tracked case-universe projection accrue_admin/storybook/phase254-selection.json
//       from the compiled manifests (through mix) and the shared cell universe
//       (accrue_admin/e2e/phase253-cell-universe.js), or regenerate it in memory and fail when the
//       committed copy is stale.
//   select --event E --base B --head H --out PATH [--summary] [--changed-paths-file F]
//       Map a diff to a transparent, fail-closed selection report. Every ambiguity broadens to
//       mode "full"; the selector never silently skips a case.
//   --self-test
//       Run every rejection scenario, each paired with a passing control.
//
// A selection (affected or sentinel-only) is never equivalent to the full sweep. The report and
// the step summary always state the mode, selected/total counts and the excluded case ids.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";
import { CONSUMED_ROOTS, REQUIRED_OWNER, classifyPath, matchesRule, normalizeRepoPath } from "./phase252_paths.mjs";
import { LEDGER_PATH, expectedPhase252Cells, readCurationLedger } from "./verify_phase254_curation.mjs";

const SELF_PATH = fileURLToPath(import.meta.url);
const ROOT = path.resolve(path.dirname(SELF_PATH), "../..");
const universe = createRequire(import.meta.url)("../../accrue_admin/e2e/phase253-cell-universe.js");

export const PROJECTION_PATH = "accrue_admin/storybook/phase254-selection.json";
export const PHASE252_MANIFEST_PATH = "storybook/phase252-manifest.json";
export const SCHEMA_VERSION = 1;
export const REPORT_KIND = "phase254-selection";
export const MODES = Object.freeze(["full", "affected"]);
export const LOCAL_FIXTURE_EVENT = "local-fixture";
export const SELECTOR_SOURCE = "scripts/ci/phase254_selection.mjs";

// D-12: a frozen, reviewed set. The contract test pins its digest, so changing one id is a
// deliberate edit in two places. Coverage: both themes, 320 and 1280, collection and page tiers,
// one overlay page, the 767 and 768 edge, synthetic-text stress and the geometry negative control.
export const SENTINEL_IDS = Object.freeze([
  "geometry::negative-controls::320::light",
  "one_row::breakpoint::767::light",
  "one_row::synthetic-text::320::dark",
  "one_row::viewport::1280::light",
  "page::active::breakpoint::768::dark",
  "page::active::viewport::1280::light",
  "page::review_cancel_now::viewport::320::dark",
  "partial_cursor_error::viewport::320::dark",
]);

// D-10 FC-2: a change here can alter every case, so it always broadens to full.
export const GLOBAL_ROOTS = Object.freeze([
  { id: "admin-css-source", path: "accrue_admin/assets/css/", mode: "prefix" },
  { id: "admin-built-static", path: "accrue_admin/priv/static/", mode: "prefix" },
  { id: "brandbook-tokens", path: "brandbook/tokens/", mode: "prefix" },
  { id: "storybook-backend", path: "accrue_admin/lib/accrue_admin/dev/storybook.ex", mode: "exact" },
  { id: "admin-router", path: "accrue_admin/lib/accrue_admin/router.ex", mode: "exact" },
  { id: "portal-router", path: "accrue_portal/lib/accrue_portal/router.ex", mode: "exact" },
  { id: "copy-owner", path: "accrue_admin/lib/accrue_admin/copy.ex", mode: "exact" },
  { id: "copy-owner-submodules", path: "accrue_admin/lib/accrue_admin/copy/", mode: "prefix" },
  { id: "ui-scenarios", path: "dev_support/ui_scenarios/", mode: "prefix" },
  { id: "playwright-config", path: "accrue_admin/playwright.config.js", mode: "exact" },
  { id: "playwright-lab-config", path: "accrue_admin/playwright.phase252.config.js", mode: "exact" },
  { id: "browser-specs-and-helpers", path: "accrue_admin/e2e/", mode: "prefix" },
  { id: "selector", path: SELECTOR_SOURCE, mode: "exact" },
  { id: "selection-projection", path: PROJECTION_PATH, mode: "exact" },
  { id: "required-ci-workflow", path: ".github/workflows/ci.yml", mode: "exact" },
  { id: "browser-workflow", path: ".github/workflows/accrue_admin_browser.yml", mode: "exact" },
  { id: "lab-runner", path: "scripts/dev/phase252_lab.mjs", mode: "exact" },
  { id: "mix-lockfile", path: "mix.lock", mode: "basename" },
  { id: "npm-lockfile", path: "package-lock.json", mode: "basename" },
  { id: "yarn-lockfile", path: "yarn.lock", mode: "basename" },
  { id: "pnpm-lockfile", path: "pnpm-lock.yaml", mode: "basename" },
]);

// D-10 FC-1: only these may be skipped. None of them may contain a consumed root or a global root;
// a path that matches both an allowlist entry and anything else is a conflict and broadens.
export const IRRELEVANT_ALLOWLIST = Object.freeze([
  { id: "docs", path: "docs/", mode: "prefix" },
  { id: "prompts", path: "prompts/", mode: "prefix" },
  { id: "planning-research", path: ".planning/research/", mode: "prefix" },
]);

class SelectionError extends Error {}

function fail(message, code = "SELECTION_FAILED") {
  const error = new SelectionError(`Phase 254 selection: ${message}`);
  error.code = code;
  throw error;
}

// --- small utilities ------------------------------------------------------------------------

export function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

export function stableStringify(value) {
  if (Array.isArray(value)) return `[${value.map((item) => stableStringify(item)).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

function isObject(value) {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

const byCodeUnit = (left, right) => (left < right ? -1 : left > right ? 1 : 0);

function sortedUnique(values) {
  return [...new Set(values)].sort(byCodeUnit);
}

function exactSet(actual, expected, label) {
  const left = [...actual].sort(byCodeUnit);
  const right = [...expected].sort(byCodeUnit);
  if (left.length !== new Set(left).size || right.length !== new Set(right).size || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(`${label} mismatch; expected ${new Set(right).size} unique ids and received ${left.length}`, "SELECTION_INVARIANT");
  }
}

export function sentinelsDigest(sentinels) {
  return sha256(JSON.stringify([...sentinels].sort(byCodeUnit)));
}

// --- projection -------------------------------------------------------------------------------

function entryForDefinition(definition, manifest) {
  const pageKinds = new Set(["page_composition", "page_synthetic_text_stress"]);
  const pool = pageKinds.has(definition.case_kind) ? manifest.page_entries : manifest.collection_variations;
  const entry = pool.find((candidate) => candidate.variation_id === definition.variation_id);
  if (!entry) fail(`case ${definition.key} has no compiled manifest entry`, "PROJECTION_INVALID");
  return { entry, tier: pageKinds.has(definition.case_kind) ? "page" : "collection" };
}

function assertDependsOn(owner, dependsOn, digests) {
  if (!Array.isArray(dependsOn) || dependsOn.length === 0) fail(`${owner} has no depends_on`, "PROJECTION_INVALID");
  if (JSON.stringify(dependsOn) !== JSON.stringify(sortedUnique(dependsOn))) fail(`${owner} depends_on must be sorted and unique`, "PROJECTION_INVALID");
  const outside = dependsOn.filter((source) => !Object.prototype.hasOwnProperty.call(digests, source));
  if (outside.length > 0) fail(`${owner} depends_on names a path outside source_digests: ${outside.join(", ")}`, "PROJECTION_INVALID");
}

export function buildProjection({ manifest, phase252Manifest, ledger }) {
  if (!isObject(manifest) || !isObject(manifest.source_digests) || !Array.isArray(manifest.collection_variations) || !Array.isArray(manifest.page_entries)) {
    fail("the Phase 253 manifest lacks source_digests, collection_variations or page_entries", "PROJECTION_INVALID");
  }
  if (!isObject(phase252Manifest) || !Array.isArray(phase252Manifest.entries) || !isObject(phase252Manifest.source_digests)) {
    fail("the Phase 252 manifest lacks entries or source_digests", "PROJECTION_INVALID");
  }
  const definitions = universe.createExpectedBrowserCellDefinitions(manifest);
  const cases = definitions
    .map((definition) => {
      const { entry, tier } = entryForDefinition(definition, manifest);
      assertDependsOn(`case ${definition.key}`, entry.depends_on, manifest.source_digests);
      return {
        id: definition.key,
        tier,
        fixture_class: "pure-story",
        schedule: "pr-selectable",
        case_kind: definition.case_kind,
        variation_id: definition.variation_id,
        page_role: tier === "page" ? (universe.PAGE_DETAIL_VARIATIONS.includes(definition.variation_id) ? "detail" : "overlay_result") : null,
        width: definition.width,
        theme: definition.theme,
        depends_on: [...entry.depends_on],
      };
    })
    .sort((left, right) => byCodeUnit(left.id, right.id));
  const ids = cases.map((item) => item.id);
  if (new Set(ids).size !== ids.length) fail("the shared cell universe produced duplicate case ids", "PROJECTION_INVALID");
  if (cases.length !== definitions.length) fail("the projection dropped a cell definition", "PROJECTION_INVALID");

  const compatibility = new Set(ledger?.frozen_baseline?.compatibility_ids ?? []);
  const alwaysRun = [];
  for (const entry of phase252Manifest.entries) {
    assertDependsOn(`Phase 252 entry ${entry.key}`, entry.depends_on, phase252Manifest.source_digests);
    if (compatibility.has(entry.variation_id)) {
      alwaysRun.push({ id: `${entry.key}::compatibility::1280::light`, owner: "phase252:check", tier: "detail", kind: "compatibility", depends_on: [...entry.depends_on] });
    } else {
      for (const width of [320, 1280]) {
        for (const theme of ["light", "dark"]) {
          alwaysRun.push({ id: `${entry.key}::${width}::${theme}`, owner: "phase252:check", tier: "detail", kind: "canonical", depends_on: [...entry.depends_on] });
        }
      }
    }
  }
  alwaysRun.sort((left, right) => byCodeUnit(left.id, right.id));
  const derived = expectedPhase252Cells(ledger);
  if (alwaysRun.length !== derived.total) {
    fail(`always_run lists ${alwaysRun.length} Phase 252 cases but the curation ledger derives ${derived.total}`, "PROJECTION_INVALID");
  }

  const sentinels = [...SENTINEL_IDS].sort(byCodeUnit);
  const known = new Set(ids);
  const stale = sentinels.filter((id) => !known.has(id));
  if (stale.length > 0) fail(`stale sentinel ids are not in the case universe: ${stale.join(", ")}`, "PROJECTION_INVALID");

  return {
    schema_version: SCHEMA_VERSION,
    manifest_sha256: sha256(stableStringify({
      source_digests: manifest.source_digests,
      collection_variations: manifest.collection_variations,
      page_entries: manifest.page_entries,
    })),
    source_digests: manifest.source_digests,
    phase252_manifest_sha256: sha256(stableStringify(phase252Manifest)),
    phase252_source_digests: phase252Manifest.source_digests,
    curation_ledger_sha256: sha256(stableStringify(ledger)),
    expected_case_count: definitions.length,
    cases,
    always_run: alwaysRun,
    sentinels,
    sentinels_sha256: sentinelsDigest(sentinels),
    global_roots: GLOBAL_ROOTS.map((rule) => ({ ...rule })),
    irrelevant_allowlist: IRRELEVANT_ALLOWLIST.map((rule) => ({ ...rule })),
  };
}

export function serializeProjection(projection) {
  return `${JSON.stringify(projection, null, 2)}\n`;
}

export function assertProjectionCurrent(committed, regenerated) {
  if (stableStringify(committed) !== stableStringify(regenerated)) {
    fail(`${PROJECTION_PATH} is stale; regenerate it with node scripts/ci/phase254_selection.mjs project --write`, "PROJECTION_STALE");
  }
}

function mixCompositionsCode(target) {
  if (/["\\#\n]/.test(target)) fail(`refusing a manifest target with unsafe characters: ${target}`);
  // SubscriptionCompositionsManifest.write!/1 also demands the gitignored run-time transport proof
  // (accrue_admin/tmp/phase253/transport.json), which a fresh checkout does not have. The cell
  // universe needs only the three compiled sections below, so they are read from the module's own
  // public discovery functions instead.
  return [
    "{:ok, _started} = Application.ensure_all_started(:localize)",
    "alias AccrueAdmin.Storybook.SubscriptionCompositionsManifest, as: Compositions",
    "contents = %{source_digests: Compositions.source_digests(), collection_variations: Compositions.collection_variation_entries(), page_entries: Compositions.page_entries()}",
    `File.write!("${target}", Jason.encode!(contents))`,
  ].join("\n");
}

export function generateCompositionsManifest(root = ROOT) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-"));
  const target = path.join(dir, "compositions.json");
  try {
    const result = spawnSync("mix", ["run", "--no-start", "-e", mixCompositionsCode(target)], {
      cwd: path.join(root, "accrue_admin"),
      env: { ...process.env, MIX_ENV: "test" },
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
      timeout: 20 * 60 * 1000,
    });
    if (result.status !== 0) {
      const tail = `${result.stdout || ""}${result.stderr || ""}`.trim().split("\n").slice(-12).join("\n");
      fail(`mix could not generate the compiled compositions manifest (exit ${result.status}):\n${tail}`, "PROJECTION_REGENERATION_FAILED");
    }
    return JSON.parse(fs.readFileSync(target, "utf8"));
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

export function regenerateProjection(root = ROOT) {
  return buildProjection({
    manifest: generateCompositionsManifest(root),
    phase252Manifest: JSON.parse(fs.readFileSync(path.join(root, PHASE252_MANIFEST_PATH), "utf8")),
    ledger: readCurationLedger(root),
  });
}

export function readProjection(root = ROOT) {
  const file = path.join(root, PROJECTION_PATH);
  let bytes;
  try {
    bytes = fs.readFileSync(file);
  } catch (error) {
    fail(`${PROJECTION_PATH} is missing or unreadable (${error.code || error.message}); run project --write`, "PROJECTION_MISSING");
  }
  let projection;
  try {
    projection = JSON.parse(bytes.toString("utf8"));
  } catch (error) {
    fail(`${PROJECTION_PATH} is not valid JSON: ${error.message}`, "PROJECTION_INVALID");
  }
  return { projection, projectionSha256: sha256(bytes) };
}

// Structural rules every consumer applies before trusting a projection (FC-5).
export function assertProjectionShape(projection) {
  if (!isObject(projection) || projection.schema_version !== SCHEMA_VERSION) fail("the projection has an unsupported schema", "PROJECTION_INVALID");
  for (const key of ["cases", "always_run", "sentinels", "global_roots", "irrelevant_allowlist"]) {
    if (!Array.isArray(projection[key])) fail(`the projection lacks ${key}`, "PROJECTION_INVALID");
  }
  if (!isObject(projection.source_digests)) fail("the projection lacks source_digests", "PROJECTION_INVALID");
  const ids = projection.cases.map((item) => item.id);
  if (new Set(ids).size !== ids.length || ids.length === 0) fail("the projection has duplicate or no case ids", "PROJECTION_INVALID");
  if (projection.cases.length !== projection.expected_case_count) {
    fail(`the projection lists ${projection.cases.length} cases but expected_case_count is ${projection.expected_case_count}`, "PROJECTION_INVALID");
  }
  for (const item of projection.cases) {
    if (!Array.isArray(item.depends_on)) continue; // an absent depends_on is broadened, never trusted
    const outside = item.depends_on.filter((source) => !Object.prototype.hasOwnProperty.call(projection.source_digests, source));
    if (outside.length > 0) fail(`case ${item.id} depends_on names a path outside source_digests: ${outside.join(", ")}`, "PROJECTION_INVALID");
  }
  const known = new Set(ids);
  const stale = projection.sentinels.filter((id) => !known.has(id));
  if (stale.length > 0) fail(`stale sentinel ids are not in the case universe: ${stale.join(", ")}`, "SELECTION_INVARIANT");
  if (projection.sentinels_sha256 !== sentinelsDigest(projection.sentinels)) fail("sentinels_sha256 does not match the sentinel set", "SELECTION_INVARIANT");
  const allowlist = projection.irrelevant_allowlist;
  for (const rule of allowlist) {
    if (normalizeRepoPath(rule.path.replace(/\/$/, "")) === null) fail(`irrelevant allowlist entry ${rule.id} has an unsafe path`, "PROJECTION_INVALID");
    const overlapsConsumed = CONSUMED_ROOTS.some((consumed) => matchesRule(rule.path.replace(/\/$/, ""), consumed) || matchesRule(consumed.path.replace(/\/$/, ""), rule));
    const overlapsGlobal = projection.global_roots.some((global) => rootMatches(rule.path.replace(/\/$/, ""), global) || rootMatches(global.path.replace(/\/$/, ""), rule));
    if (overlapsConsumed || overlapsGlobal) fail(`irrelevant allowlist entry ${rule.id} contains a consumed or global root`, "PROJECTION_INVALID");
  }
  return true;
}

// Digest-bind the projection to the files it was derived from (FC-5, T-254-14): a stale or forged
// projection hard-fails instead of narrowing a run.
export function verifyProjectionFresh(projection, { root = ROOT } = {}) {
  assertProjectionShape(projection);
  for (const [group, digests] of [["source_digests", projection.source_digests], ["phase252_source_digests", projection.phase252_source_digests ?? {}]]) {
    for (const [relative, expected] of Object.entries(digests)) {
      const file = path.join(root, relative);
      if (!fs.existsSync(file) || sha256(fs.readFileSync(file)) !== expected) {
        fail(`the projection is stale: ${relative} (${group}) changed; regenerate with project --write`, "PROJECTION_STALE");
      }
    }
  }
  const phase252 = JSON.parse(fs.readFileSync(path.join(root, PHASE252_MANIFEST_PATH), "utf8"));
  if (sha256(stableStringify(phase252)) !== projection.phase252_manifest_sha256) {
    fail(`the projection is stale: ${PHASE252_MANIFEST_PATH} changed; regenerate with project --write`, "PROJECTION_STALE");
  }
  const ledger = readCurationLedger(root);
  if (sha256(stableStringify(ledger)) !== projection.curation_ledger_sha256) {
    fail(`the projection is stale: ${LEDGER_PATH} changed; regenerate with project --write`, "PROJECTION_STALE");
  }
  if (projection.always_run.length !== expectedPhase252Cells(ledger).total) {
    fail("the projection always_run count differs from the ledger-derived Phase 252 total", "PROJECTION_STALE");
  }
  return true;
}

// --- path classification ------------------------------------------------------------------------

function rootMatches(repoPath, rule) {
  if (rule.mode === "basename") return repoPath.split("/").pop() === rule.path;
  return matchesRule(repoPath, rule);
}

function consumedRule(repoPath) {
  if (classifyPath(repoPath) !== REQUIRED_OWNER) return null;
  return CONSUMED_ROOTS.find((rule) => rule.owner === REQUIRED_OWNER && matchesRule(repoPath, rule))?.id ?? "manifest-source";
}

export function classifyChange(change, projection) {
  const repoPath = normalizeRepoPath(change.path);
  if (repoPath === null) {
    // CIQ-01's null means "not focused", never "safe to skip": an unsafe or unparsable name is unmapped.
    return { path: change.path, status: change.status, class: "unmapped", rule: "invalid-path", case_ids: [] };
  }
  const globalRule = projection.global_roots.find((rule) => rootMatches(repoPath, rule));
  const caseIds = projection.cases
    .filter((item) => Array.isArray(item.depends_on) && item.depends_on.length > 0 && item.depends_on.includes(repoPath))
    .map((item) => item.id);
  const consumed = consumedRule(repoPath);
  const irrelevant = projection.irrelevant_allowlist.find((rule) => rootMatches(repoPath, rule));
  const base = { path: repoPath, status: change.status };
  if (irrelevant && (globalRule || caseIds.length > 0 || consumed)) return { ...base, class: "conflict", rule: `irrelevant:${irrelevant.id}`, case_ids: [] };
  if (globalRule) return { ...base, class: "global", rule: `global:${globalRule.id}`, case_ids: [] };
  if (caseIds.length > 0) return { ...base, class: "case-scoped", rule: "depends_on", case_ids: caseIds };
  if (consumed) return { ...base, class: "owner-mapped", rule: `consumed:${consumed}`, case_ids: [] };
  if (irrelevant) return { ...base, class: "irrelevant", rule: `irrelevant:${irrelevant.id}`, case_ids: [] };
  return { ...base, class: "unmapped", rule: "unmapped", case_ids: [] };
}

// --- changed paths ---------------------------------------------------------------------------------

function gitEnv() {
  const env = { ...process.env };
  for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_PREFIX", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES"]) delete env[name];
  return env;
}

function git(root, args) {
  return spawnSync("git", ["-C", root, ...args], { encoding: "utf8", env: gitEnv(), maxBuffer: 256 * 1024 * 1024 });
}

const SHA_PATTERN = /^[0-9a-f]{7,64}$/i;

export function parseNameStatusZ(output) {
  const tokens = output.split("\0");
  if (tokens.at(-1) === "") tokens.pop();
  const changes = [];
  for (let index = 0; index < tokens.length; index += 2) {
    const status = tokens[index];
    const file = tokens[index + 1];
    if (!/^[A-Z][0-9]*$/.test(status ?? "") || file === undefined || file === "") {
      fail("git diff output could not be parsed", "DIFF_PARSE_FAILED");
    }
    changes.push({ status, path: file });
  }
  return changes;
}

// Returns the changed paths or the named reason the diff is unusable. Every unusable case becomes
// FC-3 full in selectCases; this function never throws for a git failure.
export function readChangedPaths({ base, head, event, root = ROOT }) {
  const run = { event: event ?? "", head_sha: head ?? "", base_sha: base ?? "", base_source: "git-diff", diff_status: "not-run" };
  const broaden = (reason, diffStatus = "not-run") => ({ run: { ...run, diff_status: diffStatus }, changedPaths: null, fullReasons: [reason] });
  if (event !== "pull_request") return broaden(`FC-3:non-pr-event:${String(event || "none").slice(0, 40)}`);
  if (!base) return broaden("FC-3:missing-base");
  if (/^0+$/.test(base)) return broaden("FC-3:zero-base");
  if (!SHA_PATTERN.test(base)) return broaden("FC-3:invalid-base");
  if (!head || !SHA_PATTERN.test(head)) return broaden("FC-3:invalid-head");
  const inside = git(root, ["rev-parse", "--is-inside-work-tree"]);
  if (inside.status !== 0) return broaden("FC-3:diff-error", "failed");
  const shallow = git(root, ["rev-parse", "--is-shallow-repository"]);
  if (shallow.status !== 0 || shallow.stdout.trim() !== "false") return broaden("FC-3:shallow-clone");
  if (git(root, ["cat-file", "-e", `${base}^{commit}`]).status !== 0) return broaden("FC-3:unreachable-base");
  if (git(root, ["cat-file", "-e", `${head}^{commit}`]).status !== 0) return broaden("FC-3:unreachable-head");
  const diff = git(root, ["diff", "--name-status", "-z", "--no-renames", base, head]);
  if (diff.status !== 0) return broaden("FC-3:diff-error", "failed");
  let changes;
  try {
    changes = parseNameStatusZ(diff.stdout);
  } catch {
    return broaden("FC-3:diff-error", "failed");
  }
  return { run: { ...run, diff_status: "ok" }, changedPaths: changes, fullReasons: [] };
}

export function readChangedPathsFile(file, { root = ROOT } = {}) {
  const absolute = path.resolve(root, file);
  let text;
  try {
    text = fs.readFileSync(absolute, "utf8");
  } catch (error) {
    fail(`changed-paths file is unreadable (${error.code || error.message})`, "FIXTURE_UNREADABLE");
  }
  const changes = [];
  for (const line of text.split("\n")) {
    if (line.trim() === "") continue;
    const [status, ...paths] = line.split("\t");
    if (!/^[A-Z][0-9]*$/.test(status) || paths.length === 0 || paths.some((entry) => entry === "")) {
      fail(`changed-paths file line is not "STATUS<TAB>path": ${JSON.stringify(line.slice(0, 80))}`, "FIXTURE_INVALID");
    }
    for (const entry of paths) changes.push({ status, path: entry });
  }
  return {
    run: { event: LOCAL_FIXTURE_EVENT, head_sha: "", base_sha: "", base_source: "changed-paths-file", diff_status: "fixture" },
    changedPaths: changes,
    fullReasons: [],
    fixtureSource: path.relative(root, absolute).split(path.sep).join("/"),
  };
}

// --- selection --------------------------------------------------------------------------------------

export function selectCases({ projection, run = {}, changedPaths, fullReasons = [], projectionSha256 = null, selectorSha256 = null, fixtureSource = null }) {
  assertProjectionShape(projection);
  const totalIds = projection.cases.map((item) => item.id).sort(byCodeUnit);
  const reasons = [...fullReasons];
  const classified = (changedPaths ?? []).map((change) => classifyChange(change, projection));
  classified.sort((left, right) => byCodeUnit(left.path, right.path) || byCodeUnit(left.status, right.status));
  if (changedPaths !== null && changedPaths.length === 0 && reasons.length === 0) reasons.push("empty-diff");
  for (const item of classified) {
    if (item.class === "global") reasons.push(`FC-2:${item.rule}:${item.path}`);
    else if (item.class === "unmapped") reasons.push(`FC-1:${item.rule}:${item.path}`);
    else if (item.class === "owner-mapped") reasons.push(`FC-1:owner-mapped-no-case-scope:${item.path}`);
    else if (item.class === "conflict") reasons.push(`FC-4:conflict:${item.path}`);
  }
  const mode = reasons.length > 0 ? "full" : "affected";
  if (fixtureSource) reasons.push(`fixture:${fixtureSource}`);

  const selected = new Map(totalIds.map((id) => [id, new Set()]));
  for (const id of projection.sentinels) selected.get(id)?.add("sentinel");
  for (const item of projection.cases) {
    if (!Array.isArray(item.depends_on) || item.depends_on.length === 0) selected.get(item.id).add("broaden:no-metadata");
  }
  for (const item of classified) {
    if (item.class === "case-scoped") for (const id of item.case_ids) selected.get(id).add("changed:depends_on");
  }
  let selectedIds;
  if (mode === "full") {
    for (const set of selected.values()) set.add("broaden:full");
    selectedIds = totalIds;
  } else {
    selectedIds = totalIds.filter((id) => selected.get(id).size > 0);
  }
  const selectedSet = new Set(selectedIds);

  const report = {
    schema_version: SCHEMA_VERSION,
    kind: REPORT_KIND,
    human_judgment: false,
    run: {
      event: run.event ?? "",
      workflow: run.workflow ?? "",
      job: run.job ?? "",
      run_id: run.run_id ?? "",
      head_sha: run.head_sha ?? "",
      base_sha: run.base_sha ?? "",
      base_source: run.base_source ?? "",
      diff_status: run.diff_status ?? "not-run",
    },
    manifest_sha256: projection.manifest_sha256 ?? null,
    projection_sha256: projectionSha256,
    selector_sha256: selectorSha256,
    changed_paths: classified.map((item) => ({ path: item.path, status: item.status, class: item.class, rule: item.rule, case_ids: item.case_ids })),
    mode,
    mode_reasons: mode === "full" ? sortedUnique(reasons) : sortedUnique(["no-full-trigger", ...reasons]),
    counts: { total: totalIds.length, selected: selectedIds.length, excluded: totalIds.length - selectedIds.length },
    total_ids: totalIds,
    selected: selectedIds.map((id) => ({ id, reasons: [...selected.get(id)].sort(byCodeUnit) })),
    excluded: totalIds.filter((id) => !selectedSet.has(id)).map((id) => ({ id, reason: "unaffected:no-changed-dependency" })),
    sentinels: [...projection.sentinels].sort(byCodeUnit),
    sentinels_sha256: projection.sentinels_sha256,
    cases: projection.cases.map((item) => ({ id: item.id, tier: item.tier, fixture_class: item.fixture_class, schedule: item.schedule })),
    always_run: projection.always_run.map((item) => ({ id: item.id, owner: item.owner })),
  };
  assertSelectionInvariants(report);
  return report;
}

export function assertSelectionInvariants(report) {
  if (!isObject(report) || report.kind !== REPORT_KIND) fail("not a selection report", "SELECTION_INVARIANT");
  if (!MODES.includes(report.mode)) fail(`unsupported selection mode ${JSON.stringify(report.mode)}`, "SELECTION_INVARIANT");
  for (const key of ["total_ids", "selected", "excluded", "sentinels", "mode_reasons"]) {
    if (!Array.isArray(report[key])) fail(`report lacks ${key}`, "SELECTION_INVARIANT");
  }
  const total = report.total_ids;
  if (JSON.stringify(total) !== JSON.stringify(sortedUnique(total)) || total.length === 0) fail("total_ids must be a non-empty sorted unique list", "SELECTION_INVARIANT");
  const selectedIds = report.selected.map((item) => item.id);
  const excludedIds = report.excluded.map((item) => item.id);
  if (new Set(selectedIds).size !== selectedIds.length) fail("selected contains a duplicate id", "SELECTION_INVARIANT");
  if (new Set(excludedIds).size !== excludedIds.length) fail("excluded contains a duplicate id", "SELECTION_INVARIANT");
  const overlap = selectedIds.filter((id) => excludedIds.includes(id));
  if (overlap.length > 0) fail(`selected and excluded overlap: ${overlap.slice(0, 5).join(", ")}`, "SELECTION_INVARIANT");
  exactSet([...selectedIds, ...excludedIds], total, "selected plus excluded versus total_ids");
  const stale = report.sentinels.filter((id) => !total.includes(id));
  if (stale.length > 0) fail(`stale sentinel ids are not in total_ids: ${stale.join(", ")}`, "SELECTION_INVARIANT");
  const missing = report.sentinels.filter((id) => !selectedIds.includes(id));
  if (missing.length > 0) fail(`selected omits sentinels: ${missing.join(", ")}`, "SELECTION_INVARIANT");
  if (report.sentinels_sha256 !== sentinelsDigest(report.sentinels)) fail("sentinels_sha256 does not match the sentinel set", "SELECTION_INVARIANT");
  if (report.selected.some((item) => !Array.isArray(item.reasons) || item.reasons.length === 0)) fail("a selected case has no reason", "SELECTION_INVARIANT");
  if (report.excluded.some((item) => typeof item.reason !== "string" || item.reason === "")) fail("an excluded case has no reason", "SELECTION_INVARIANT");
  if (report.mode === "full" && (report.excluded.length > 0 || report.mode_reasons.length === 0)) fail("full mode must select every case and name its reason", "SELECTION_INVARIANT");
  if (report.counts && (report.counts.total !== total.length || report.counts.selected !== selectedIds.length || report.counts.excluded !== excludedIds.length)) {
    fail("report counts disagree with the id lists", "SELECTION_INVARIANT");
  }
  return true;
}

// --- rendering ----------------------------------------------------------------------------------------

// Copied from render_provider_summary.mjs escapeMarkdown, plus `$`, so a hostile changed-path name
// cannot inject markdown, HTML, a workflow command or a shell expansion into the step summary.
export function escapeMarkdown(value) {
  return String(value ?? "not recorded")
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/`/g, "&#96;")
    .replace(/[\\*_#[\]|$()]/g, (character) => `&#${character.codePointAt(0)};`)
    .replace(/:/g, "&#58;").replace(/[\r\n]/g, " ").replace(/[\u0000-\u001F\u007F]/g, "");
}

export function renderSelectionSummary(report) {
  assertSelectionInvariants(report);
  const lines = [];
  lines.push("## Phase 254 browser case selection", "");
  lines.push(`- Mode: **${escapeMarkdown(report.mode)}**`);
  lines.push(`- Selected: ${report.counts.selected} of ${report.counts.total} cases; excluded: ${report.counts.excluded}`);
  lines.push(`- Event: ${escapeMarkdown(report.run.event)}; diff status: ${escapeMarkdown(report.run.diff_status)}; base source: ${escapeMarkdown(report.run.base_source)}`);
  lines.push(`- Sentinels (${report.sentinels.length}, always selected): ${report.sentinels.map(escapeMarkdown).join(", ")}`);
  if (report.mode === "affected") {
    lines.push("", "> This is an affected selection, not the full sweep. The excluded cases below were not run by this selection; the push to main runs the full sweep.");
  }
  lines.push("", "### Mode reasons", "");
  for (const reason of report.mode_reasons) lines.push(`- ${escapeMarkdown(reason)}`);
  lines.push("", "### Changed paths", "");
  if (report.changed_paths.length === 0) {
    lines.push("No changed paths were read.");
  } else {
    lines.push("| Status | Path | Class | Rule | Cases |", "| --- | --- | --- | --- | --- |");
    for (const item of report.changed_paths) {
      lines.push(`| ${escapeMarkdown(item.status)} | ${escapeMarkdown(item.path)} | ${escapeMarkdown(item.class)} | ${escapeMarkdown(item.rule)} | ${item.case_ids.length} |`);
    }
  }
  lines.push("", "### Excluded case ids", "");
  if (report.excluded.length === 0) {
    lines.push("None excluded.");
  } else {
    lines.push(report.excluded.map((item) => escapeMarkdown(item.id)).join(", "));
  }
  lines.push("", `Phase 252 cases that always run in phase252:check: ${report.always_run.length}.`, "");
  return `${lines.join("\n")}\n`;
}

// --- CLI -----------------------------------------------------------------------------------------------

const BOOLEAN_OPTIONS = new Set(["write", "check", "summary", "self-test"]);
const VALUE_OPTIONS = new Set(["event", "base", "head", "out", "changed-paths-file", "run-id", "workflow", "job"]);

function parseArgs(argv) {
  const positional = [];
  const flags = new Set();
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) { positional.push(token); continue; }
    const key = token.slice(2);
    if (BOOLEAN_OPTIONS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option --${key}`, "USAGE");
    const next = argv[index + 1];
    if (next === undefined || (next.startsWith("--") && next !== "")) {
      // an empty base is legitimate (non-PR events); a value that looks like the next flag is not
      fail(`--${key} requires a value`, "USAGE");
    }
    values[key] = argv[++index];
  }
  return { positional, flags, values };
}

function runProject(flags) {
  if (flags.has("write") === flags.has("check")) fail("project needs exactly one of --write or --check", "USAGE");
  const regenerated = regenerateProjection(ROOT);
  if (flags.has("write")) {
    fs.writeFileSync(path.join(ROOT, PROJECTION_PATH), serializeProjection(regenerated));
    process.stdout.write(`Phase 254 selection: wrote ${PROJECTION_PATH} (${regenerated.cases.length} cases, ${regenerated.always_run.length} always-run Phase 252 cases, ${regenerated.sentinels.length} sentinels)\n`);
    return;
  }
  const { projection } = readProjection(ROOT);
  assertProjectionCurrent(projection, regenerated);
  const defined = regenerated.expected_case_count;
  if (projection.cases.length !== defined) fail("the committed projection's case count differs from the shared cell universe", "PROJECTION_STALE");
  process.stdout.write(`Phase 254 selection: project --check PASS (${projection.cases.length} cases equal the shared cell universe; ${projection.always_run.length} Phase 252 cases; ${projection.sentinels.length} sentinels; ${PROJECTION_PATH} is current)\n`);
}

function runSelect(flags, values) {
  const { projection, projectionSha256 } = readProjection(ROOT);
  verifyProjectionFresh(projection, { root: ROOT });
  const selectorSha256 = sha256(fs.readFileSync(SELF_PATH));
  const context = {
    workflow: values.workflow ?? process.env.GITHUB_WORKFLOW ?? "",
    job: values.job ?? process.env.GITHUB_JOB ?? "",
    run_id: values["run-id"] ?? process.env.GITHUB_RUN_ID ?? "local",
  };
  const read = values["changed-paths-file"]
    ? readChangedPathsFile(values["changed-paths-file"], { root: ROOT })
    : readChangedPaths({ base: values.base, head: values.head ?? process.env.GITHUB_SHA ?? "", event: values.event, root: ROOT });
  const report = selectCases({
    projection,
    run: { ...read.run, ...context },
    changedPaths: read.changedPaths,
    fullReasons: read.fullReasons,
    projectionSha256,
    selectorSha256,
    fixtureSource: read.fixtureSource ?? null,
  });
  if (!values.out) fail("select requires --out", "USAGE");
  const out = path.resolve(ROOT, values.out);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, `${JSON.stringify(report, null, 2)}\n`);
  if (flags.has("summary")) {
    const markdown = renderSelectionSummary(report);
    if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdown);
    else process.stdout.write(markdown);
  }
  process.stdout.write(`Phase 254 selection: mode ${report.mode}, ${report.counts.selected} of ${report.counts.total} cases selected, ${report.counts.excluded} excluded -> ${path.relative(ROOT, out)}\n`);
}

// --- self-test scenarios -------------------------------------------------------------------------------------

function committedProjection() {
  return readProjection(ROOT).projection;
}

function select(projection, paths, overrides = {}) {
  return selectCases({
    projection,
    run: { event: LOCAL_FIXTURE_EVENT },
    changedPaths: paths.map((entry) => (typeof entry === "string" ? { status: "M", path: entry } : entry)),
    ...overrides,
  });
}

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-scratch-"));
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

export const HOSTILE_PATHS = Object.freeze(["docs/a|b`c$(whoami)::error::x\nnext.md", "docs/<img src=x>.md", "docs/[link](javascript:alert(1)).md"]);

export const SCENARIOS = [
  [
    "hostile-path fixture: pipe, backtick, $(...), ::error:: and newline are escaped in the rendered step summary",
    () => {
      const projection = committedProjection();
      const report = select(projection, HOSTILE_PATHS);
      const markdown = renderSelectionSummary(report);
      assert.doesNotMatch(markdown, /::error::/);
      assert.doesNotMatch(markdown, /\$\(/);
      assert.doesNotMatch(markdown, /`/);
      const rows = markdown.split("\n").filter((line) => line.startsWith("| ") && !line.startsWith("| ---") && !line.startsWith("| Status"));
      assert.equal(rows.length, HOSTILE_PATHS.length, "a newline in a path must not add a table row");
      for (const row of rows) assert.equal((row.match(/ \| /g) ?? []).length, 4, "a pipe in a path must not add a column");
      assert.match(markdown, /Excluded case ids/);
      assert.equal(escapeMarkdown("a|b\nc"), "a&#124;b c");
    },
  ],
  [
    "docs-only change selects exactly the sentinels; the control (a collection story) selects more",
    () => {
      const projection = committedProjection();
      const docs = select(projection, ["docs/x.md"]);
      assert.equal(docs.mode, "affected");
      assert.deepEqual(docs.selected.map((item) => item.id), [...projection.sentinels].sort(byCodeUnit));
      assert.ok(docs.excluded.length > 0);
      const collection = select(projection, ["storybook/groups/subscriptions_collection.story.exs"]);
      assert.equal(collection.mode, "affected");
      assert.ok(collection.counts.selected > docs.counts.selected && collection.excluded.length > 0);
    },
  ],
  [
    "global roots and unmapped paths broaden to full: accrue/lib, mix.lock and app.css",
    () => {
      const projection = committedProjection();
      for (const changed of ["accrue/lib/accrue/x.ex", "mix.lock", "accrue_admin/mix.lock", "accrue_admin/assets/css/app.css", "../escape.txt"]) {
        const report = select(projection, [changed]);
        assert.equal(report.mode, "full", changed);
        assert.equal(report.counts.selected, projection.expected_case_count, changed);
        assert.equal(report.excluded.length, 0, changed);
      }
    },
  ],
  [
    "a case without depends_on is always selected as broaden:no-metadata and a conflicting class gives full",
    () => {
      const projection = structuredClone(committedProjection());
      const target = projection.cases.find((item) => !projection.sentinels.includes(item.id));
      target.depends_on = [];
      const report = select(projection, ["docs/x.md"]);
      assert.equal(report.mode, "affected");
      assert.deepEqual(report.selected.find((item) => item.id === target.id).reasons, ["broaden:no-metadata"]);
      const conflicted = structuredClone(committedProjection());
      conflicted.source_digests["docs/x.md"] = "0".repeat(64);
      conflicted.cases.find((item) => !conflicted.sentinels.includes(item.id)).depends_on = ["docs/x.md"];
      const conflict = select(conflicted, ["docs/x.md"]);
      assert.equal(conflict.mode, "full");
      assert.ok(conflict.mode_reasons.some((reason) => reason.startsWith("FC-4:conflict:docs/x.md")));
      const overlapping = structuredClone(committedProjection());
      overlapping.irrelevant_allowlist.push({ id: "overlap", path: "storybook/groups/", mode: "prefix" });
      assert.throws(() => select(overlapping, ["docs/x.md"]), /contains a consumed or global root/);
      const direct = select(committedProjection(), []);
      assert.equal(direct.mode, "full", "an empty diff is ambiguous and broadens");
    },
  ],
  [
    "invariants throw for overlap, a union that is not total, a missing sentinel and a stale sentinel",
    () => {
      const projection = committedProjection();
      const report = select(projection, ["docs/x.md"]);
      assert.equal(assertSelectionInvariants(report), true);
      const overlap = structuredClone(report);
      overlap.excluded.push({ id: overlap.selected[0].id, reason: "x" });
      assert.throws(() => assertSelectionInvariants(overlap), /overlap/);
      const missing = structuredClone(report);
      missing.excluded.pop();
      assert.throws(() => assertSelectionInvariants(missing), /selected plus excluded versus total_ids mismatch/);
      const noSentinel = structuredClone(report);
      noSentinel.selected = noSentinel.selected.filter((item) => item.id !== noSentinel.sentinels[0]);
      noSentinel.excluded.push({ id: noSentinel.sentinels[0], reason: "x" });
      assert.throws(() => assertSelectionInvariants(noSentinel), /omits sentinels/);
      const stale = structuredClone(report);
      stale.sentinels = [...stale.sentinels.slice(1), "not-a-case::viewport::1::light"];
      stale.sentinels_sha256 = sentinelsDigest(stale.sentinels);
      assert.throws(() => assertSelectionInvariants(stale), /stale sentinel/);
    },
  ],
  [
    "FC-3 base handling: missing, zero, unreachable, shallow, diff failure and non-PR events give full with a named reason",
    () => {
      const expected = [
        [{ base: "", head: "abc1234", event: "pull_request" }, "FC-3:missing-base"],
        [{ base: "0000000000000000000000000000000000000000", head: "abc1234", event: "pull_request" }, "FC-3:zero-base"],
        [{ base: "abc1234", head: "def5678", event: "push" }, "FC-3:non-pr-event:push"],
        [{ base: "abc1234", head: "def5678", event: "workflow_dispatch" }, "FC-3:non-pr-event:workflow_dispatch"],
        [{ base: "--output=x", head: "def5678", event: "pull_request" }, "FC-3:invalid-base"],
      ];
      for (const [input, reason] of expected) {
        const read = readChangedPaths({ ...input, root: ROOT });
        assert.deepEqual(read.fullReasons, [reason]);
        assert.equal(read.changedPaths, null);
      }
      withScratchRepo(({ dir, run, write }) => {
        write("README.md", "one\n");
        run("add", "-A");
        run("commit", "-q", "-m", "base");
        const base = run("rev-parse", "HEAD");
        write("docs/x.md", "two\n");
        run("add", "-A");
        run("commit", "-q", "-m", "head");
        const head = run("rev-parse", "HEAD");
        const ok = readChangedPaths({ base, head, event: "pull_request", root: dir });
        assert.equal(ok.run.diff_status, "ok");
        assert.deepEqual(ok.changedPaths, [{ status: "A", path: "docs/x.md" }]);
        const unreachable = readChangedPaths({ base: "1".repeat(40), head, event: "pull_request", root: dir });
        assert.deepEqual(unreachable.fullReasons, ["FC-3:unreachable-base"]);
        const clone = path.join(fs.realpathSync(os.tmpdir()), `phase254-selection-shallow-${process.pid}-${Date.now()}`);
        try {
          const cloned = spawnSync("git", ["clone", "-q", "--depth", "1", `file://${dir}`, clone], { encoding: "utf8", env: gitEnv() });
          assert.equal(cloned.status, 0, cloned.stderr);
          const shallow = readChangedPaths({ base, head, event: "pull_request", root: clone });
          assert.deepEqual(shallow.fullReasons, ["FC-3:shallow-clone"]);
        } finally {
          fs.rmSync(clone, { recursive: true, force: true });
        }
        const notRepo = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "phase254-selection-norepo-"));
        try {
          const failed = readChangedPaths({ base, head, event: "pull_request", root: notRepo });
          assert.deepEqual(failed.fullReasons, ["FC-3:diff-error"]);
          assert.equal(failed.run.diff_status, "failed");
        } finally {
          fs.rmSync(notRepo, { recursive: true, force: true });
        }
      });
    },
  ],
  [
    "a rename maps its old path (--name-status --no-renames) and a newline path is read intact with -z",
    () => {
      const projection = committedProjection();
      withScratchRepo(({ dir, run, write }) => {
        write("storybook/groups/subscriptions_collection.story.exs", "story\n");
        write("docs/keep.md", "keep\n");
        run("add", "-A");
        run("commit", "-q", "-m", "base");
        const base = run("rev-parse", "HEAD");
        run("mv", "storybook/groups/subscriptions_collection.story.exs", "docs/moved.md");
        write("docs/new\nline.md", "x\n");
        run("add", "-A");
        run("commit", "-q", "-m", "head");
        const head = run("rev-parse", "HEAD");
        const read = readChangedPaths({ base, head, event: "pull_request", root: dir });
        const paths = read.changedPaths.map((item) => `${item.status}:${item.path}`).sort();
        assert.deepEqual(paths, ["A:docs/moved.md", "A:docs/new\nline.md", "D:storybook/groups/subscriptions_collection.story.exs"]);
        const report = selectCases({ projection, run: read.run, changedPaths: read.changedPaths, fullReasons: read.fullReasons });
        assert.equal(report.mode, "affected");
        assert.ok(report.changed_paths.some((item) => item.status === "D" && item.class === "case-scoped"));
        assert.ok(report.counts.selected > projection.sentinels.length);
      });
    },
  ],
  [
    "the projection digest guard rejects a stale source digest and a sentinel edit; the committed projection passes",
    () => {
      const projection = committedProjection();
      assert.equal(verifyProjectionFresh(projection, { root: ROOT }), true);
      const stale = structuredClone(projection);
      const [first] = Object.keys(stale.source_digests);
      stale.source_digests[first] = "0".repeat(64);
      assert.throws(() => verifyProjectionFresh(stale, { root: ROOT }), /the projection is stale/);
      const edited = structuredClone(projection);
      edited.sentinels = [...edited.sentinels.slice(1), edited.cases.find((item) => !edited.sentinels.includes(item.id)).id];
      assert.throws(() => assertProjectionShape(edited), /sentinels_sha256/);
      const removed = structuredClone(projection);
      removed.cases = removed.cases.slice(1);
      assert.throws(() => assertProjectionShape(removed), /expected_case_count|stale sentinel/);
      assert.throws(() => assertProjectionCurrent(removed, projection), /is stale/);
      assert.doesNotThrow(() => assertProjectionCurrent(projection, structuredClone(projection)));
    },
  ],
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

function main(argv) {
  const { positional, flags, values } = parseArgs(argv);
  if (flags.has("self-test")) {
    const count = verifyFixtures();
    for (const [name] of SCENARIOS) process.stdout.write(`ok - ${name}\n`);
    process.stdout.write(`Phase 254 selection self-test: PASS (${count} scenarios, each with a positive control; hostile-path fixture escaped)\n`);
    return;
  }
  const [verb] = positional;
  if (verb === "project") return runProject(flags);
  if (verb === "select") return runSelect(flags, values);
  fail("usage: phase254_selection.mjs project --write|--check | select --event E --base B --head H --out PATH [--summary] [--changed-paths-file F] | --self-test", "USAGE");
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
// A spawn with arguments is a real CLI run even when NODE_TEST_CONTEXT is inherited.
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof SelectionError ? error.message : `Phase 254 selection: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
