// Phase 254 (D-13 / D-14): static spec-ownership contract for the accrue_admin Playwright
// configs, plus the pure-story vs mounted classifier.
//
// Two independent properties are enforced here, each with seeded positive controls so a
// green result is evidence and not an absence of findings:
//
//   1. Every e2e spec file is owned by exactly one owner group across both configs.
//      Owner groups: default-browser (chromium-desktop + chromium-mobile, which run the
//      same specs at two viewports on purpose), visual (visual-desktop) and lab (every
//      project of playwright.phase252.config.js). A spec matched by no project, or by
//      projects of two different groups, is rejected. At the time this contract was
//      written the two launcher-owned lab specs were also loaded by the default
//      projects, which crashed the whole default listing (PATTERNS P8).
//   2. A spec that resets or seeds state, or imports the visual helpers (which do), is
//      "mounted"; it must never be owned by the pure-story lab group, whose servers
//      refuse reset/seed in the review lane.

import assert from "node:assert/strict";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ADMIN_ROOT = path.join(ROOT, "accrue_admin");
const E2E_ROOT = path.join(ADMIN_ROOT, "e2e");
const require = createRequire(import.meta.url);

export const OWNER_GROUPS = Object.freeze({
  "default-browser": Object.freeze(["chromium-desktop", "chromium-mobile"]),
  visual: Object.freeze(["visual-desktop"]),
  // Every project of playwright.phase252.config.js; resolved from that config, not listed.
  lab: Object.freeze([]),
});

// Playwright's default testMatch is **/*.@(spec|test).?(c|m)[jt]s?(x); a regex is tested
// against the absolute file path.
const DEFAULT_TEST_MATCH = /\.(?:spec|test)\.[cm]?[jt]sx?$/;

const MOUNTED_MARKERS = Object.freeze([
  { id: "reset-route", pattern: /\/__e2e__\/reset\b/ },
  { id: "seed-route", pattern: /\/__e2e__\/seed\b/ },
]);
const VISUAL_HELPERS_IMPORT = /(?:require\(\s*|from\s+)["'](?:\.\/)?(?:support\/)?admin-visual-helpers(?:\.js)?["']/;
const RELATIVE_IMPORT = /(?:require\(\s*|from\s+)["'](\.{1,2}\/[^"']+)["']/g;

function patternList(value, label) {
  if (value === undefined || value === null) return null;
  const list = Array.isArray(value) ? value : [value];
  for (const entry of list) {
    if (!(entry instanceof RegExp)) {
      throw new Error(`${label} uses a non-RegExp pattern; this contract only evaluates RegExp patterns`);
    }
  }
  return list;
}

function regexMatches(pattern, value) {
  pattern.lastIndex = 0;
  return pattern.test(value);
}

export function projectMatches(project, absolutePath) {
  const matchList = patternList(project.testMatch, `${project.name} testMatch`) ?? [DEFAULT_TEST_MATCH];
  const ignoreList = patternList(project.testIgnore, `${project.name} testIgnore`) ?? [];
  const normalized = absolutePath.split(path.sep).join("/");
  if (!matchList.some((pattern) => regexMatches(pattern, normalized))) return false;
  return !ignoreList.some((pattern) => regexMatches(pattern, normalized));
}

/** The owner groups (a Set) that load `specPath` under the given resolved projects. */
export function ownerGroupsForSpec(specPath, projects) {
  const groups = new Set();
  for (const project of projects) {
    if (projectMatches(project, specPath)) groups.add(project.group);
  }
  return groups;
}

/** Throws for any spec owned by zero groups or by more than one group; returns spec -> group. */
export function assertSpecOwnership(specPaths, projects) {
  const ownership = new Map();
  const problems = [];
  for (const specPath of specPaths) {
    const groups = [...ownerGroupsForSpec(specPath, projects)].sort();
    const label = path.basename(specPath);
    if (groups.length === 0) problems.push(`${label} is not owned by any project`);
    else if (groups.length > 1) problems.push(`${label} is owned by multiple groups: ${groups.join(", ")}`);
    else ownership.set(specPath, groups[0]);
  }
  if (problems.length > 0) throw new Error(`spec ownership violated: ${problems.join("; ")}`);
  return ownership;
}

function resolveImportedPath(fromFile, specifier) {
  const base = path.resolve(path.dirname(fromFile), specifier);
  for (const candidate of [base, `${base}.js`, `${base}.cjs`, `${base}.mjs`]) {
    try {
      if (fs.statSync(candidate).isFile()) return candidate;
    } catch {
      // try the next extension
    }
  }
  return null;
}

/** Sources of the spec's local relative imports, one level deep. */
export function readLocalImports(specPath, source = fs.readFileSync(specPath, "utf8")) {
  const imported = [];
  for (const match of source.matchAll(RELATIVE_IMPORT)) {
    const resolved = resolveImportedPath(specPath, match[1]);
    if (resolved) imported.push(fs.readFileSync(resolved, "utf8"));
  }
  return imported;
}

/** "mounted" when the spec (or a one-level local import) resets, seeds or uses the visual helpers. */
export function classifySpecSource(source, imports = []) {
  if (VISUAL_HELPERS_IMPORT.test(source)) return "mounted";
  for (const text of [source, ...imports]) {
    if (MOUNTED_MARKERS.some(({ pattern }) => pattern.test(text))) return "mounted";
  }
  return "pure-story";
}

/** Rejects any spec owned by the pure-story lab group that classifies as mounted. */
export function assertLabSpecsArePure(ownership, readSource) {
  const mounted = [];
  for (const [specPath, group] of ownership) {
    if (group !== "lab") continue;
    const { source, imports } = readSource(specPath);
    if (classifySpecSource(source, imports) === "mounted") mounted.push(path.basename(specPath));
  }
  if (mounted.length > 0) {
    throw new Error(`mounted spec in pure-story project (D-14): ${mounted.join(", ")}`);
  }
}

function withEnv(values, fn) {
  const saved = new Map();
  for (const key of Object.keys(values)) saved.set(key, process.env[key]);
  Object.assign(process.env, values);
  try {
    return fn();
  } finally {
    for (const [key, previous] of saved) {
      if (previous === undefined) delete process.env[key];
      else process.env[key] = previous;
    }
  }
}

function loadConfig(configPath, env = {}) {
  const resolved = require.resolve(configPath);
  delete require.cache[resolved];
  try {
    return withEnv(env, () => require(resolved));
  } finally {
    delete require.cache[resolved];
  }
}

const DEFAULT_PROJECT_GROUPS = Object.freeze({
  "chromium-desktop": "default-browser",
  "chromium-mobile": "default-browser",
  "visual-desktop": "visual",
});

const LAB_CONFIG_ENV = Object.freeze({
  PHASE252_E2E_NONCE: "0".repeat(24),
  PHASE252_E2E_DATABASE: "accrue_admin_ownership_contract",
  PHASE252_E2E_ROLE: "accrue_admin_ownership_contract",
  PHASE252_E2E_ADDRESS: "127.0.0.1",
  PHASE252_E2E_PORT: "45123",
  PHASE252_E2E_PARTITION: "12345678",
});

function resolveProjects(config, groupFor) {
  return (config.projects || []).map((project) => ({
    name: project.name,
    group: groupFor(project.name),
    testMatch: project.testMatch ?? config.testMatch,
    testIgnore: project.testIgnore ?? config.testIgnore,
  }));
}

/** Projects of both real configs, each assigned to an owner group; unknown names fail closed. */
export function loadRealProjects() {
  const defaults = loadConfig(path.join(ADMIN_ROOT, "playwright.config.js"));
  const lab = loadConfig(path.join(ADMIN_ROOT, "playwright.phase252.config.js"), LAB_CONFIG_ENV);
  const defaultProjects = resolveProjects(defaults, (name) => {
    const group = DEFAULT_PROJECT_GROUPS[name];
    if (!group) throw new Error(`default config project ${name} has no owner group; assign one in OWNER_GROUPS`);
    return group;
  });
  const labProjects = resolveProjects(lab, () => "lab");
  for (const [group, names] of Object.entries(OWNER_GROUPS)) {
    if (group === "lab") continue;
    for (const name of names) {
      assert.ok(defaultProjects.some((project) => project.name === name && project.group === group), `${name} is missing from the default config`);
    }
  }
  return [...defaultProjects, ...labProjects];
}

export function listSpecFiles(directory = E2E_ROOT) {
  const found = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name === "__screenshots__") continue;
    const absolute = path.join(directory, entry.name);
    if (entry.isDirectory()) found.push(...listSpecFiles(absolute));
    else if (/\.(?:spec|test)\.[cm]?[jt]sx?$/.test(entry.name)) found.push(absolute);
  }
  return found.sort();
}

function readRealSource(specPath) {
  const source = fs.readFileSync(specPath, "utf8");
  return { source, imports: readLocalImports(specPath, source) };
}

// -- fixtures -------------------------------------------------------------------------

const FIXTURE_PROJECTS = Object.freeze([
  { name: "chromium-desktop", group: "default-browser", testIgnore: [/lab\.spec\.js$/, /visual\.spec\.js$/] },
  { name: "chromium-mobile", group: "default-browser", testIgnore: [/lab\.spec\.js$/, /visual\.spec\.js$/] },
  { name: "visual-desktop", group: "visual", testMatch: /visual\.spec\.js$/ },
  { name: "lab-project", group: "lab", testMatch: /lab\.spec\.js$/ },
]);
const fixturePath = (name) => path.join(E2E_ROOT, name);

// -- tests ----------------------------------------------------------------------------

test("a fixture spec matched by chromium-desktop and chromium-mobile counts once and passes", () => {
  const spec = fixturePath("plain.spec.js");
  assert.deepEqual([...ownerGroupsForSpec(spec, FIXTURE_PROJECTS)], ["default-browser"]);
  const ownership = assertSpecOwnership([spec], FIXTURE_PROJECTS);
  assert.equal(ownership.get(spec), "default-browser");
});

test("a fixture spec unmatched by every project is rejected as unowned", () => {
  const projects = FIXTURE_PROJECTS.map((project) => ({ ...project, testIgnore: [/orphan\.spec\.js$/] }));
  assert.throws(() => assertSpecOwnership([fixturePath("orphan.spec.js")], projects), /orphan\.spec\.js is not owned by any project/);
});

test("a fixture spec matched by default-browser and visual groups is rejected as double-owned", () => {
  const projects = [
    { name: "chromium-desktop", group: "default-browser" },
    { name: "visual-desktop", group: "visual", testMatch: /shared\.spec\.js$/ },
  ];
  assert.throws(
    () => assertSpecOwnership([fixturePath("shared.spec.js")], projects),
    /shared\.spec\.js is owned by multiple groups: default-browser, visual/,
  );
});

test("a fixture spec matched by default-browser and lab groups is rejected as double-owned", () => {
  const projects = [
    { name: "chromium-desktop", group: "default-browser" },
    { name: "lab-project", group: "lab", testMatch: /lab\.spec\.js$/ },
  ];
  assert.throws(
    () => assertSpecOwnership([fixturePath("lab.spec.js")], projects),
    /lab\.spec\.js is owned by multiple groups: default-browser, lab/,
  );
});

test("a non-RegExp pattern fails closed instead of being silently ignored", () => {
  assert.throws(
    () => projectMatches({ name: "p", testMatch: "**/*.spec.js" }, fixturePath("x.spec.js")),
    /non-RegExp pattern/,
  );
});

test("classifySpecSource marks a POST to /__e2e__/reset as mounted", () => {
  const source = 'async function reset(request) { await request.post("/__e2e__/reset"); }';
  assert.equal(classifySpecSource(source), "mounted");
});

test("classifySpecSource marks a /__e2e__/seed/ template path as mounted", () => {
  const source = "async function seed(request, name) { await request.post(`/__e2e__/seed/${name}`); }";
  assert.equal(classifySpecSource(source), "mounted");
});

test("classifySpecSource marks an admin-visual-helpers import as mounted", () => {
  const source = 'const { reset, seed } = require("./support/admin-visual-helpers");';
  assert.equal(classifySpecSource(source), "mounted");
});

test("classifySpecSource marks a spec mounted when its one-level local import resets state", () => {
  const source = 'const { go } = require("./helper.js");';
  const imported = 'exports.go = (request) => request.post("/__e2e__/reset");';
  assert.equal(classifySpecSource(source, [imported]), "mounted");
});

test("classifySpecSource does not treat a 'Reset filters' link text as a reset call", () => {
  const source = 'await page.getByRole("link", { name: "Reset filters" }).click();';
  assert.equal(classifySpecSource(source), "pure-story");
});

test("a mounted spec owned by the pure-story lab project is rejected", () => {
  const spec = fixturePath("lab.spec.js");
  const ownership = assertSpecOwnership([spec], FIXTURE_PROJECTS.filter((project) => project.group === "lab"));
  assert.throws(
    () => assertLabSpecsArePure(ownership, () => ({ source: 'request.post("/__e2e__/reset")', imports: [] })),
    /mounted spec in pure-story project \(D-14\): lab\.spec\.js/,
  );
  assert.doesNotThrow(() => assertLabSpecsArePure(ownership, () => ({ source: 'await page.goto("/billing/dev/storybook")', imports: [] })));
});

test("a mounted spec owned by a non-lab group is not a pure-story violation", () => {
  const ownership = new Map([[fixturePath("admin-a11y.spec.js"), "default-browser"]]);
  assert.doesNotThrow(() => assertLabSpecsArePure(ownership, () => ({ source: 'request.post("/__e2e__/reset")', imports: [] })));
});

test("every real e2e spec is owned by exactly one owner group across both Playwright configs", () => {
  const specs = listSpecFiles();
  assert.ok(specs.length >= 20, `expected the real e2e directory listing, saw ${specs.length} specs`);
  const projects = loadRealProjects();
  const ownership = assertSpecOwnership(specs, projects);
  const groups = new Set(ownership.values());
  assert.deepEqual([...groups].sort(), ["default-browser", "lab", "visual"]);
  const byName = (name) => ownership.get(path.join(E2E_ROOT, name));
  assert.equal(byName("subscription-compositions-phase253.spec.js"), "lab");
  assert.equal(byName("subscription-compositions-reconcile-phase254.spec.js"), "lab");
  assert.equal(byName("phase252-review.spec.js"), "lab");
  assert.equal(byName("subscription-stories-phase252.spec.js"), "lab");
  assert.equal(byName("admin-visual-regression-phase211.spec.js"), "visual");
  assert.equal(byName("subscription-visual-phase254.spec.js"), "visual", "CIQ-03 extends the one visual owner (D-15), never a second baseline owner");
  assert.equal(byName("admin-a11y.spec.js"), "default-browser");
});

test("real lab specs and their local imports are pure-story, and real mounted specs classify as mounted", () => {
  const ownership = assertSpecOwnership(listSpecFiles(), loadRealProjects());
  assert.doesNotThrow(() => assertLabSpecsArePure(ownership, readRealSource));
  const classifyReal = (name) => {
    const { source, imports } = readRealSource(path.join(E2E_ROOT, name));
    return classifySpecSource(source, imports);
  };
  // Positive controls: the classifier must find a known mounted spec of each shape.
  assert.equal(classifyReal("admin-a11y.spec.js"), "mounted");
  assert.equal(classifyReal("admin-interactions.spec.js"), "mounted");
  assert.equal(classifyReal("admin-visual-regression-phase211.spec.js"), "mounted");
  for (const name of ["subscription-compositions-phase253.spec.js", "subscription-compositions-reconcile-phase254.spec.js", "subscription-stories-phase252.spec.js", "phase252-review.spec.js"]) {
    assert.equal(classifyReal(name), "pure-story", name);
  }
});
