#!/usr/bin/env node
// Phase 254 CIQ-03 (D-18): the identity manifest of the committed visual baselines.
//
//   build        --artifact-dir D --identity-dir D --run-id ID --sha SHA [--reasons FILE]
//                [--reason TEXT --finding-id ID] [--previous FILE] [--out FILE]
//       Build manifest.json for a freshly minted baseline directory. A PNG whose bytes differ from the
//       previous entry (or that has none) is a changed key and must carry a reason and a finding id.
//   check        [--dir D] [--base SHA]
//       Gate: the Chromium and Playwright versions recorded in every minted entry equal the running
//       ones, and every PNG changed since the merge-base is a minted entry whose served asset digests,
//       font digests and scenario digest equal the committed files. The set, byte and field rules are
//       the baseline set guard's (accrue_admin/e2e/visual-baseline-set.cjs), which runs beside it.
//   seed-legacy  [--dir D] [--out FILE]
//       Write the manifest of the unchanged Phase 211 PNGs (provenance phase211-committed).
//   --self-test  Run every rejection scenario, each paired with a passing control.
//
// Baselines are minted on the Linux CI runner only; nothing here ever produces a PNG.

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

const SELF_PATH = fileURLToPath(import.meta.url);
const ROOT = path.resolve(path.dirname(SELF_PATH), "../..");
const guard = createRequire(import.meta.url)("../../accrue_admin/e2e/visual-baseline-set.cjs");

export const BASELINE_DIR = "accrue_admin/e2e/__screenshots__/visual-desktop";
export const IDENTITY_DIR = "accrue_admin/tmp/phase254/visual-identity";
export const CASES_PATH = "accrue_admin/storybook/phase254-visual-cases.json";
export const SCENARIO_FILE = "dev_support/ui_scenarios/cadence_subscriptions.exs";
const { EXPECTED_BASELINES, MANIFEST_FILE, PROVENANCE_LEGACY, PROVENANCE_MINT, snapshotFileName, validateEntry } = guard;

export class ManifestError extends Error {}

function fail(message) {
  throw new ManifestError(`Phase 254 visual manifest: ${message}`);
}

export function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

const byCodeUnit = (left, right) => (left < right ? -1 : left > right ? 1 : 0);

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    fail(`${file} is missing or invalid JSON (${error.code || error.message})`);
  }
}

// The files a minted entry's served digests must equal, by kind: a story route serves the Storybook
// bundle, a mounted page the admin bundle; both serve the committed Geist faces.
export function currentAssetDigests(kind, root = ROOT) {
  const file = (relative) => sha256(fs.readFileSync(path.join(root, relative)));
  const bundle = kind === "story" ? ["accrue_admin/priv/static/storybook.css", "accrue_admin/priv/static/storybook.js"]
    : ["accrue_admin/priv/static/accrue_admin.css", "accrue_admin/priv/static/accrue_admin.js"];
  return {
    served: {
      css_sha256: file(bundle[0]),
      js_sha256: file(bundle[1]),
      geist_sans_sha256: file("accrue_admin/priv/static/fonts/geist-sans-vf.woff2"),
      geist_mono_sha256: file("accrue_admin/priv/static/fonts/geist-mono-vf.woff2"),
    },
    scenario_file_sha256: file(SCENARIO_FILE),
  };
}

// The versions this checkout would run with, read without launching a browser: the installed
// @playwright/test package and the Chromium build its playwright-core pins.
export function runningVersions(root = ROOT) {
  const adminModules = path.join(root, "accrue_admin", "node_modules");
  const playwright = readJson(path.join(adminModules, "@playwright", "test", "package.json")).version;
  const browsers = readJson(path.join(adminModules, "playwright-core", "browsers.json")).browsers;
  const chromium = browsers.find((entry) => entry.name === "chromium");
  if (!chromium?.browserVersion) fail("playwright-core/browsers.json has no chromium browserVersion");
  return { playwright_version: playwright, browser_version: chromium.browserVersion };
}

function caseKeyOfFile(fileName, caseKeys) {
  const legacy = EXPECTED_BASELINES.find((name) => name === fileName);
  if (legacy) return legacy.replace(/\.png$/, "");
  const key = caseKeys.find((candidate) => snapshotFileName(candidate) === fileName);
  if (!key) fail(`${fileName} is neither a legacy baseline nor a case key of ${CASES_PATH}`);
  return key;
}

function readCaseKeys(root) {
  return guard.readCaseKeys(path.join(root, CASES_PATH));
}

function commonVersions(identities) {
  const versions = new Set(identities.map((identity) => `${identity.playwright_version}|${identity.browser_version}`));
  if (versions.size !== 1) fail(`the identity files disagree about the Playwright and browser versions (${[...versions].join("; ")})`);
  const [playwright_version, browser_version] = [...versions][0].split("|");
  return { playwright_version, browser_version };
}

// buildManifest: sorted entries for every PNG in artifactDir. reasons maps a key to {reason, finding_id};
// the "*" key is the default for every changed key.
export function buildManifest({ artifactDir, identityDir, reasons = {}, mint, previous = null, root = ROOT, caseKeys = null }) {
  if (!mint?.run_id || !/^[0-9a-f]{40}$/.test(mint.sha ?? "")) fail("build needs the mint run id and a 40-character commit sha");
  const keys = caseKeys ?? readCaseKeys(root);
  const files = fs.readdirSync(artifactDir).filter((name) => name.endsWith(".png")).sort();
  if (files.length === 0) fail(`${artifactDir} holds no PNG`);
  const identities = new Map();
  for (const name of fs.existsSync(identityDir) ? fs.readdirSync(identityDir).filter((entry) => entry.endsWith(".json")) : []) {
    const identity = readJson(path.join(identityDir, name));
    identities.set(identity.key, identity);
  }
  const versions = identities.size > 0 ? commonVersions([...identities.values()]) : null;
  const entries = {};
  for (const file of files) {
    const key = caseKeyOfFile(file, keys);
    const bytes = sha256(fs.readFileSync(path.join(artifactDir, file)));
    const prior = previous?.entries?.[key];
    if (prior && prior.sha256 === bytes) {
      entries[key] = prior;
      continue;
    }
    const why = reasons[key] ?? reasons["*"];
    if (!why || typeof why.reason !== "string" || why.reason.trim() === "" || typeof why.finding_id !== "string" || why.finding_id === "") {
      fail(`${key}: a changed baseline needs a reason and a finding id`);
    }
    const identity = identities.get(key);
    const legacyKey = EXPECTED_BASELINES.includes(file);
    if (!identity && !legacyKey) fail(`${key}: no identity file in ${identityDir}`);
    if (identity && identity.snapshot !== file) fail(`${key}: the identity file names ${identity.snapshot}, not ${file}`);
    if (!identity && !versions) fail(`${key}: a rebaselined legacy key needs identity files from the same run for the browser version`);
    const kind = identity?.kind === "story" ? "story" : "mounted";
    const current = currentAssetDigests(kind, root);
    entries[key] = {
      case_key: key,
      file,
      sha256: bytes,
      provenance: PROVENANCE_MINT,
      kind,
      mint_run_id: String(mint.run_id),
      mint_sha: mint.sha,
      served: identity ? identity.served : current.served,
      scenario_file_sha256: identity ? identity.scenario_file_sha256 : current.scenario_file_sha256,
      playwright_version: identity ? identity.playwright_version : versions.playwright_version,
      browser_version: identity ? identity.browser_version : versions.browser_version,
      reason: why.reason,
      finding_id: why.finding_id,
    };
  }
  const sorted = Object.fromEntries(Object.keys(entries).sort(byCodeUnit).map((key) => [key, entries[key]]));
  return { schema_version: 1, entries: sorted };
}

function gitEnv() {
  const env = { ...process.env };
  for (const name of ["GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_PREFIX", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES"]) delete env[name];
  return env;
}

function git(root, args) {
  return spawnSync("git", ["-C", root, ...args], { encoding: "utf8", env: gitEnv(), maxBuffer: 64 * 1024 * 1024 });
}

// The PNG file names under dir whose bytes differ between base and the working tree (added, modified or
// deleted); an unreachable base is a failure, never "nothing changed".
export function changedPngsSince(base, dir, { root = ROOT } = {}) {
  if (!/^[0-9a-f]{7,64}$/i.test(base ?? "")) fail(`base must be a commit sha, saw ${JSON.stringify(base)}`);
  if (git(root, ["cat-file", "-e", `${base}^{commit}`]).status !== 0) fail(`base ${base} is not reachable; fetch the full history`);
  const relative = path.relative(root, path.resolve(root, dir)).split(path.sep).join("/");
  const diff = git(root, ["diff", "--name-only", "-z", "--no-renames", base, "--", relative]);
  if (diff.status !== 0) fail(`git diff against ${base} failed: ${diff.stderr.trim()}`);
  const untracked = git(root, ["ls-files", "--others", "--exclude-standard", "-z", "--", relative]);
  if (untracked.status !== 0) fail(`git ls-files failed: ${untracked.stderr.trim()}`);
  return [...new Set([...diff.stdout.split("\0"), ...untracked.stdout.split("\0")].filter(Boolean))]
    .filter((name) => name.endsWith(".png"))
    .map((name) => path.posix.basename(name))
    .sort();
}

// checkManifest returns the list of problems (empty when the gate passes).
export function checkManifest({ dir, manifest = null, base = null, root = ROOT, versions = null, changedPngs = null, caseKeys = null }) {
  const problems = [];
  const read = manifest ? { manifest, error: null } : (() => {
    try {
      const parsed = readJson(path.join(dir, MANIFEST_FILE));
      return { manifest: parsed, error: null };
    } catch (error) {
      return { manifest: null, error: error.message };
    }
  })();
  if (!read.manifest || read.manifest.schema_version !== 1 || typeof read.manifest.entries !== "object") {
    return [read.error ?? `${MANIFEST_FILE} must be {schema_version: 1, entries: {...}}`];
  }
  const entries = read.manifest.entries;
  const running = versions ?? runningVersions(root);
  const keys = caseKeys ?? readCaseKeys(root);
  for (const [key, entry] of Object.entries(entries)) {
    problems.push(...validateEntry(key, entry));
    if (entry?.provenance !== PROVENANCE_MINT) continue;
    if (entry.browser_version !== running.browser_version) problems.push(`${key}: Chromium version mismatch (manifest ${entry.browser_version}, running ${running.browser_version})`);
    if (entry.playwright_version !== running.playwright_version) problems.push(`${key}: Playwright version mismatch (manifest ${entry.playwright_version}, running ${running.playwright_version})`);
  }
  const changed = changedPngs ?? (base ? changedPngsSince(base, dir, { root }) : []);
  for (const file of changed) {
    if (!fs.existsSync(path.join(dir, file))) continue; // a deleted PNG is the set guard's failure
    let key;
    try {
      key = caseKeyOfFile(file, keys);
    } catch (error) {
      problems.push(error.message);
      continue;
    }
    const entry = entries[key];
    if (!entry) {
      problems.push(`${key}: changed since the merge-base but has no manifest entry`);
      continue;
    }
    if (entry.provenance !== PROVENANCE_MINT || !entry.mint_run_id || !entry.mint_sha) {
      problems.push(`${key}: changed since the merge-base without a current mint run id and asset digests`);
      continue;
    }
    if (entry.sha256 !== sha256(fs.readFileSync(path.join(dir, file)))) problems.push(`${key}: the PNG bytes differ from the manifest sha256`);
    const current = currentAssetDigests(entry.kind, root);
    for (const field of Object.keys(current.served)) {
      if (entry.served?.[field] !== current.served[field]) problems.push(`${key}: served ${field} differs from the committed asset`);
    }
    if (entry.scenario_file_sha256 !== current.scenario_file_sha256) problems.push(`${key}: scenario_file_sha256 differs from the committed scenario file`);
  }
  return problems;
}

function lastCommitOf(file, root) {
  const result = git(root, ["log", "-1", "--format=%H", "--", path.relative(root, file).split(path.sep).join("/")]);
  const sha = result.stdout.trim();
  if (result.status !== 0 || !/^[0-9a-f]{40}$/.test(sha)) fail(`could not read the last commit of ${file}`);
  return sha;
}

export function buildLegacyManifest({ dir, root = ROOT }) {
  const entries = {};
  for (const file of EXPECTED_BASELINES) {
    const key = file.replace(/\.png$/, "");
    const absolute = path.join(dir, file);
    entries[key] = {
      case_key: key,
      file,
      sha256: sha256(fs.readFileSync(absolute)),
      provenance: PROVENANCE_LEGACY,
      last_commit: lastCommitOf(absolute, root),
      mint_run_id: null,
      mint_sha: null,
      kind: null,
      served: null,
      scenario_file_sha256: null,
      playwright_version: null,
      browser_version: null,
      reason: "Phase 211 committed baseline, unchanged by Phase 254",
      finding_id: null,
    };
  }
  return { schema_version: 1, entries };
}

// --- self-test scenarios -----------------------------------------------------------------------------------

function tmpDir(prefix) {
  return fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), prefix));
}

const HEX = (character) => character.repeat(64);
export const FIXTURE_VERSIONS = Object.freeze({ playwright_version: "9.9.9", browser_version: "999.0.0.1" });

// A scratch repository root carrying the five committed asset files, so currentAssetDigests has bytes.
export function fixtureRoot() {
  const root = tmpDir("phase254-visual-root-");
  for (const relative of [
    "accrue_admin/priv/static/storybook.css", "accrue_admin/priv/static/storybook.js",
    "accrue_admin/priv/static/accrue_admin.css", "accrue_admin/priv/static/accrue_admin.js",
    "accrue_admin/priv/static/fonts/geist-sans-vf.woff2", "accrue_admin/priv/static/fonts/geist-mono-vf.woff2", SCENARIO_FILE,
  ]) {
    fs.mkdirSync(path.dirname(path.join(root, relative)), { recursive: true });
    fs.writeFileSync(path.join(root, relative), `${relative}\n`);
  }
  return root;
}

export function mintedEntry(key, bytes, root, overrides = {}) {
  const current = currentAssetDigests("story", root);
  return {
    case_key: key,
    file: snapshotFileName(key),
    sha256: sha256(bytes),
    provenance: PROVENANCE_MINT,
    kind: "story",
    mint_run_id: "12345",
    mint_sha: "a".repeat(40),
    served: current.served,
    scenario_file_sha256: current.scenario_file_sha256,
    ...FIXTURE_VERSIONS,
    reason: "first mint",
    finding_id: "CIQ-03",
    ...overrides,
  };
}

export const SCENARIOS = [
  [
    "a minted entry with current digests and the running versions passes; a stale served css digest fails",
    () => {
      const root = fixtureRoot();
      const dir = tmpDir("phase254-visual-dir-");
      try {
        const key = "phase254-page-active-w1280-light";
        const bytes = "png bytes";
        fs.writeFileSync(path.join(dir, snapshotFileName(key)), bytes);
        const entries = { [key]: mintedEntry(key, bytes, root) };
        const run = (override) => checkManifest({ dir, manifest: { schema_version: 1, entries: override ?? entries }, versions: FIXTURE_VERSIONS, changedPngs: [snapshotFileName(key)], root, caseKeys: [key] });
        assert.deepEqual(run(), []);
        const stale = { [key]: mintedEntry(key, bytes, root, { served: { ...entries[key].served, css_sha256: HEX("0") } }) };
        assert.match(run(stale).join("\n"), /served css_sha256 differs from the committed asset/);
      } finally {
        fs.rmSync(root, { recursive: true, force: true });
        fs.rmSync(dir, { recursive: true, force: true });
      }
    },
  ],
  [
    "a changed PNG without a mint run id fails; the legacy entry of an unchanged PNG passes",
    () => {
      const root = fixtureRoot();
      const dir = tmpDir("phase254-visual-dir-");
      try {
        fs.writeFileSync(path.join(dir, "dashboard.png"), "legacy bytes");
        const legacy = {
          dashboard: {
            case_key: "dashboard", file: "dashboard.png", sha256: sha256("legacy bytes"), provenance: PROVENANCE_LEGACY, last_commit: "b".repeat(40),
            mint_run_id: null, mint_sha: null, kind: null, served: null, scenario_file_sha256: null, playwright_version: null, browser_version: null,
            reason: "legacy", finding_id: null,
          },
        };
        const run = (changed) => checkManifest({ dir, manifest: { schema_version: 1, entries: legacy }, versions: FIXTURE_VERSIONS, changedPngs: changed, root, caseKeys: [] });
        assert.deepEqual(run([]), [], "positive control: an unchanged legacy PNG passes");
        assert.match(run(["dashboard.png"]).join("\n"), /dashboard: changed since the merge-base without a current mint run id and asset digests/);
      } finally {
        fs.rmSync(root, { recursive: true, force: true });
        fs.rmSync(dir, { recursive: true, force: true });
      }
    },
  ],
  [
    "a recorded Chromium or Playwright version that differs from the running one fails",
    () => {
      const root = fixtureRoot();
      const dir = tmpDir("phase254-visual-dir-");
      try {
        const key = "phase254-page-active-w1280-light";
        fs.writeFileSync(path.join(dir, snapshotFileName(key)), "x");
        const entries = { [key]: mintedEntry(key, "x", root) };
        const run = (versions) => checkManifest({ dir, manifest: { schema_version: 1, entries }, versions, changedPngs: [], root, caseKeys: [key] });
        assert.deepEqual(run(FIXTURE_VERSIONS), []);
        assert.match(run({ ...FIXTURE_VERSIONS, browser_version: "1000.0.0.0" }).join("\n"), /Chromium version mismatch/);
        assert.match(run({ ...FIXTURE_VERSIONS, playwright_version: "9.9.10" }).join("\n"), /Playwright version mismatch/);
      } finally {
        fs.rmSync(root, { recursive: true, force: true });
        fs.rmSync(dir, { recursive: true, force: true });
      }
    },
  ],
  [
    "buildManifest sorts entries, keeps an unchanged previous entry and rejects a changed key with no reason",
    () => {
      const root = fixtureRoot();
      const artifact = tmpDir("phase254-visual-art-");
      const identities = tmpDir("phase254-visual-id-");
      try {
        const keys = ["phase254-page-scheduled_cancellation-w320-light", "phase254-page-active-w320-light"];
        for (const key of keys) {
          fs.writeFileSync(path.join(artifact, snapshotFileName(key)), `bytes ${key}`);
          const current = currentAssetDigests("story", root);
          fs.writeFileSync(path.join(identities, `${key}.json`), JSON.stringify({ key, kind: "story", snapshot: snapshotFileName(key), served: current.served, scenario_file_sha256: current.scenario_file_sha256, ...FIXTURE_VERSIONS }));
        }
        const mint = { run_id: "777", sha: "c".repeat(40) };
        assert.throws(() => buildManifest({ artifactDir: artifact, identityDir: identities, reasons: {}, mint, root, caseKeys: keys }), /a changed baseline needs a reason and a finding id/);
        const built = buildManifest({ artifactDir: artifact, identityDir: identities, reasons: { "*": { reason: "first mint", finding_id: "CIQ-03" } }, mint, root, caseKeys: keys });
        assert.deepEqual(Object.keys(built.entries), [...keys].sort(byCodeUnit));
        for (const [key, entry] of Object.entries(built.entries)) assert.deepEqual(validateEntry(key, entry), [], key);
        const rebuilt = buildManifest({ artifactDir: artifact, identityDir: identities, reasons: {}, mint, previous: built, root, caseKeys: keys });
        assert.deepEqual(rebuilt, built, "unchanged keys keep their entries and need no reason");
        fs.writeFileSync(path.join(artifact, snapshotFileName(keys[1])), "different bytes");
        assert.throws(() => buildManifest({ artifactDir: artifact, identityDir: identities, reasons: {}, mint, previous: built, root, caseKeys: keys }), /a changed baseline needs a reason/);
      } finally {
        for (const directory of [root, artifact, identities]) fs.rmSync(directory, { recursive: true, force: true });
      }
    },
  ],
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// --- CLI -----------------------------------------------------------------------------------------------------

const VALUE_OPTIONS = new Set(["dir", "base", "artifact-dir", "identity-dir", "run-id", "sha", "reasons", "reason", "finding-id", "previous", "out"]);

function parseArgs(argv) {
  const positional = [];
  const values = {};
  const flags = new Set();
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) { positional.push(token); continue; }
    const key = token.slice(2);
    if (key === "self-test") { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option --${key}`);
    const next = argv[index + 1];
    if (next === undefined || next.startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
  }
  return { positional, values, flags };
}

function main(argv) {
  const { positional, values, flags } = parseArgs(argv);
  if (flags.has("self-test")) {
    const count = verifyFixtures();
    for (const [name] of SCENARIOS) process.stdout.write(`ok - ${name}\n`);
    process.stdout.write(`Phase 254 visual manifest self-test: PASS (${count} scenarios, each with a passing control)\n`);
    return;
  }
  const [verb] = positional;
  const dir = path.resolve(ROOT, values.dir ?? BASELINE_DIR);
  if (verb === "check") {
    const problems = checkManifest({ dir, base: values.base ?? null });
    if (problems.length > 0) fail(`check FAIL:\n${problems.map((line) => `- ${line}`).join("\n")}`);
    process.stdout.write(`Phase 254 visual manifest: check PASS (${values.base ? `PNGs changed since ${values.base.slice(0, 12)} verified` : "no base given, version rules only"})\n`);
    return;
  }
  if (verb === "build") {
    for (const required of ["run-id", "sha"]) if (!values[required]) fail(`build needs --${required}`);
    const artifactDir = path.resolve(ROOT, values["artifact-dir"] ?? BASELINE_DIR);
    const identityDir = path.resolve(ROOT, values["identity-dir"] ?? IDENTITY_DIR);
    const reasons = values.reasons ? readJson(path.resolve(ROOT, values.reasons)) : {};
    if (values.reason !== undefined || values["finding-id"] !== undefined) reasons["*"] = { reason: values.reason, finding_id: values["finding-id"] };
    const previousFile = path.resolve(ROOT, values.previous ?? path.join(path.relative(ROOT, artifactDir), MANIFEST_FILE));
    const previous = fs.existsSync(previousFile) ? readJson(previousFile) : null;
    const manifest = buildManifest({ artifactDir, identityDir, reasons, mint: { run_id: values["run-id"], sha: values.sha }, previous });
    const out = path.resolve(ROOT, values.out ?? path.join(path.relative(ROOT, artifactDir), MANIFEST_FILE));
    fs.writeFileSync(out, `${JSON.stringify(manifest, null, 2)}\n`);
    process.stdout.write(`Phase 254 visual manifest: wrote ${path.relative(ROOT, out)} (${Object.keys(manifest.entries).length} entries)\n`);
    return;
  }
  if (verb === "seed-legacy") {
    const manifest = buildLegacyManifest({ dir });
    const out = path.resolve(ROOT, values.out ?? path.join(path.relative(ROOT, dir), MANIFEST_FILE));
    fs.writeFileSync(out, `${JSON.stringify(manifest, null, 2)}\n`);
    process.stdout.write(`Phase 254 visual manifest: wrote ${path.relative(ROOT, out)} (${Object.keys(manifest.entries).length} legacy entries)\n`);
    return;
  }
  fail("usage: phase254_visual_manifest.mjs build|check|seed-legacy [options] | --self-test");
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof ManifestError ? error.message : `Phase 254 visual manifest: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
