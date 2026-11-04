import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import { mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const {
  EXPECTED_BASELINES,
  checkBaselineSet,
  expectedBaselines,
  snapshotFileName,
  validateEntry,
} = require("../../e2e/visual-baseline-set.cjs");
const validator = path.resolve("e2e/visual-baseline-set.cjs");
const REAL_DIRECTORY = path.resolve("e2e/__screenshots__/visual-desktop");
const CASE_KEYS = Object.freeze(["phase254-page-active-w1280-light", "phase254-page-scheduled_cancellation-w320-dark"]);

const sha256 = (value) => crypto.createHash("sha256").update(value).digest("hex");

function withBaselineDirectory(run) {
  const directory = mkdtempSync(path.join(tmpdir(), "accrue-visual-baselines-"));
  try {
    run(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
}

function legacyEntry(key, bytes) {
  return {
    case_key: key, file: `${key}.png`, sha256: sha256(bytes), provenance: "phase211-committed", last_commit: "b".repeat(40),
    mint_run_id: null, mint_sha: null, kind: null, served: null, scenario_file_sha256: null, playwright_version: null, browser_version: null,
    reason: "legacy", finding_id: null,
  };
}

function mintedEntry(key, bytes) {
  return {
    case_key: key, file: snapshotFileName(key), sha256: sha256(bytes), provenance: "phase254-mint", kind: "story",
    mint_run_id: "9001", mint_sha: "a".repeat(40),
    served: { css_sha256: "1".repeat(64), js_sha256: "2".repeat(64), geist_sans_sha256: "3".repeat(64), geist_mono_sha256: "4".repeat(64) },
    scenario_file_sha256: "5".repeat(64), playwright_version: "1.0.0", browser_version: "1.0.0.0", reason: "first mint", finding_id: "CIQ-03",
  };
}

// A complete fixture set: the twelve legacy names and the fixture case keys, each with its manifest entry.
function createCompleteSet(directory, { cases = true } = {}) {
  const entries = {};
  for (const name of EXPECTED_BASELINES) {
    writeFileSync(path.join(directory, name), `png ${name}`);
    const key = name.replace(/\.png$/, "");
    entries[key] = legacyEntry(key, `png ${name}`);
  }
  if (cases) {
    for (const key of CASE_KEYS) {
      writeFileSync(path.join(directory, snapshotFileName(key)), `png ${key}`);
      entries[key] = mintedEntry(key, `png ${key}`);
    }
  }
  writeManifest(directory, entries);
  return entries;
}

function writeManifest(directory, entries) {
  writeFileSync(path.join(directory, "manifest.json"), JSON.stringify({ schema_version: 1, entries }, null, 2));
}

function readEntries(directory) {
  return JSON.parse(readFileSync(path.join(directory, "manifest.json"), "utf8")).entries;
}

const check = (directory, options = {}) => checkBaselineSet(directory, { caseKeys: CASE_KEYS, ...options });

function runCli(directory, ...flags) {
  return spawnSync(process.execPath, [validator, directory, ...flags], { encoding: "utf8" });
}

test("expected legacy set names exactly the twelve selected light/dark captures", () => {
  assert.deepEqual(EXPECTED_BASELINES, [
    "dashboard.png", "dashboard-dark.png",
    "subscriptions.png", "subscriptions-dark.png",
    "subscription-detail.png", "subscription-detail-dark.png",
    "component-kitchen.png", "component-kitchen-dark.png",
    "invoices.png", "invoices-dark.png",
    "invoice-detail.png", "invoice-detail-dark.png"
  ]);
});

test("the snapshot file name is Playwright's sanitized case key (underscores become hyphens)", () => {
  assert.equal(snapshotFileName("phase254-page-scheduled_cancellation-w320-light"), "phase254-page-scheduled-cancellation-w320-light.png");
  assert.equal(snapshotFileName("phase254-page-active-w1280-dark"), "phase254-page-active-w1280-dark.png");
  const rows = expectedBaselines(CASE_KEYS);
  assert.equal(rows.length, 14);
  assert.deepEqual(rows.filter((row) => !row.legacy).map((row) => row.key), [...CASE_KEYS]);
});

test("complete set passes the pure check and CLI", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory);
    const result = check(directory);
    assert.deepEqual(result.problems, []);
    assert.equal(result.ok, true);
    assert.deepEqual(result.missing, []);
  });
});

test("the CLI reads the tracked case list and accepts a directory holding the legacy set with --pre-mint only", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory, { cases: false });
    const strict = runCli(directory);
    assert.notEqual(strict.status, 0, "without --pre-mint the unminted case baselines fail");
    assert.match(strict.stderr, /missing PNGs/);
    const pre = runCli(directory, "--pre-mint");
    assert.equal(pre.status, 0, pre.stderr);
    assert.match(pre.stdout, /Found all 12 required visual baselines/);
    assert.match(pre.stdout, /case baselines are not minted yet \(--pre-mint\)/);
  });
});

test("missing directory fails and names all twelve expected legacy files", () => {
  withBaselineDirectory((parent) => {
    const directory = path.join(parent, "absent");
    const result = runCli(directory);
    assert.notEqual(result.status, 0);
    for (const name of EXPECTED_BASELINES) assert.match(result.stderr, new RegExp(name));
  });
});

test("empty directory fails and names all twelve expected legacy files", () => {
  withBaselineDirectory((directory) => {
    const result = runCli(directory);
    assert.notEqual(result.status, 0);
    for (const name of EXPECTED_BASELINES) assert.match(result.stderr, new RegExp(name));
    assert.match(result.stderr, /manifest\.json is missing/);
  });
});

test("a one-image directory remains incomplete and reports every omitted legacy file", () => {
  withBaselineDirectory((directory) => {
    writeFileSync(path.join(directory, EXPECTED_BASELINES[0]), "png fixture");
    const result = runCli(directory);
    assert.notEqual(result.status, 0);
    assert.deepEqual(check(directory).missing.slice(0, 11), EXPECTED_BASELINES.slice(1));
    for (const name of EXPECTED_BASELINES.slice(1)) assert.match(result.stderr, new RegExp(name));
  });
});

for (const omitted of EXPECTED_BASELINES) {
  test(`partial set fails when ${omitted} is absent`, () => {
    withBaselineDirectory((directory) => {
      createCompleteSet(directory);
      rmSync(path.join(directory, omitted));
      const result = runCli(directory);
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, new RegExp(omitted));
      assert.equal(check(directory).missing[0], omitted);
    });
  });
}

test("an extra PNG that no expected key names fails (symmetric to a missing PNG)", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory);
    assert.equal(check(directory).ok, true, "positive control: the complete set passes");
    writeFileSync(path.join(directory, "stray-capture.png"), "stray");
    const result = check(directory);
    assert.equal(result.ok, false);
    assert.deepEqual(result.extra, ["stray-capture.png"]);
    assert.match(runCli(directory).stderr, /PNGs outside the expected set \(1\): stray-capture\.png/);
  });
});

test("an extra PNG listed in the manifest but absent from the expected set fails as a manifest extra", () => {
  withBaselineDirectory((directory) => {
    const entries = createCompleteSet(directory);
    writeFileSync(path.join(directory, "stray-capture.png"), "stray");
    entries["stray-capture"] = legacyEntry("stray-capture", "stray");
    writeManifest(directory, entries);
    const result = check(directory);
    assert.equal(result.ok, false);
    assert.deepEqual(result.extra, ["stray-capture.png"]);
    assert.deepEqual(result.manifestExtra, ["stray-capture"], "the manifest never defines the expected set");
  });
});

test("a PNG whose byte content differs from its manifest sha256 fails (byte mismatch)", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory);
    assert.deepEqual(check(directory).mismatched, [], "positive control: untouched bytes match");
    writeFileSync(path.join(directory, "dashboard.png"), "a different image");
    writeFileSync(path.join(directory, snapshotFileName(CASE_KEYS[0])), "a different minted image");
    const result = check(directory);
    assert.equal(result.ok, false);
    assert.deepEqual(result.mismatched.sort(), ["dashboard.png", snapshotFileName(CASE_KEYS[0])].sort());
    assert.match(runCli(directory).stderr, /PNG bytes differ from the manifest sha256/);
  });
});

test("a manifest entry missing a required field fails and names the field", () => {
  withBaselineDirectory((directory) => {
    const entries = createCompleteSet(directory);
    for (const [mutate, pattern] of [
      [(entry) => { delete entry.sha256; }, /dashboard: sha256 is missing/],
      [(entry) => { entry.provenance = "unknown"; }, /dashboard: provenance must be/],
      [(entry) => { entry.reason = ""; }, /dashboard: reason is missing/],
      [(entry) => { delete entry.finding_id; }, /dashboard: finding_id is missing/],
    ]) {
      const mutated = structuredClone(entries);
      mutate(mutated.dashboard);
      writeManifest(directory, mutated);
      assert.match(check(directory).fieldErrors.join("\n"), pattern);
      assert.equal(check(directory).ok, false);
    }
    const minted = structuredClone(entries);
    delete minted[CASE_KEYS[0]].mint_run_id;
    minted[CASE_KEYS[1]].served.css_sha256 = "short";
    writeManifest(directory, minted);
    const errors = check(directory).fieldErrors.join("\n");
    assert.match(errors, /mint_run_id is missing/);
    assert.match(errors, /served\.css_sha256 is missing/);
    writeManifest(directory, entries);
    assert.equal(check(directory).ok, true, "restoring the manifest passes again");
  });
});

test("a legacy PNG removed together with its manifest entry still fails (the independent expected set names it)", () => {
  withBaselineDirectory((directory) => {
    const entries = createCompleteSet(directory);
    rmSync(path.join(directory, "invoices.png"));
    delete entries.invoices;
    writeManifest(directory, entries);
    const result = check(directory);
    assert.equal(result.ok, false);
    assert.deepEqual(result.missing, ["invoices.png"]);
    assert.deepEqual(result.manifestMissing, ["invoices"]);
    assert.equal(check(directory, { preMint: true }).ok, false, "--pre-mint never tolerates a legacy baseline");
  });
});

test("a case PNG removed together with its manifest entry fails strictly; --pre-mint tolerates only that absence of both", () => {
  withBaselineDirectory((directory) => {
    const entries = createCompleteSet(directory);
    const key = CASE_KEYS[1];
    rmSync(path.join(directory, snapshotFileName(key)));
    delete entries[key];
    writeManifest(directory, entries);
    assert.equal(check(directory).ok, false);
    assert.deepEqual(check(directory).missing, [snapshotFileName(key)]);
    const tolerated = check(directory, { preMint: true });
    assert.equal(tolerated.ok, true);
    assert.deepEqual(tolerated.preMintTolerated, [snapshotFileName(key)]);
  });
});

test("--pre-mint does not tolerate a case PNG that has an entry, nor a PNG that has no entry", () => {
  withBaselineDirectory((directory) => {
    const entries = createCompleteSet(directory);
    const key = CASE_KEYS[0];
    rmSync(path.join(directory, snapshotFileName(key)));
    assert.equal(check(directory, { preMint: true }).ok, false, "an entry whose PNG vanished fails");
    writeFileSync(path.join(directory, snapshotFileName(key)), `png ${key}`);
    delete entries[key];
    writeManifest(directory, entries);
    const result = check(directory, { preMint: true });
    assert.equal(result.ok, false, "a PNG without its entry fails");
    assert.deepEqual(result.manifestMissing, [key]);
  });
});

test("an unexpected non-PNG file in the baseline directory fails", () => {
  withBaselineDirectory((directory) => {
    createCompleteSet(directory);
    writeFileSync(path.join(directory, "notes.txt"), "scratch");
    const result = check(directory);
    assert.equal(result.ok, false);
    assert.deepEqual(result.otherFiles, ["notes.txt"]);
  });
});

test("validateEntry accepts a legacy and a minted entry and rejects a minted entry with a legacy provenance shape", () => {
  assert.deepEqual(validateEntry("dashboard", legacyEntry("dashboard", "x")), []);
  assert.deepEqual(validateEntry(CASE_KEYS[0], mintedEntry(CASE_KEYS[0], "x")), []);
  const hybrid = { ...legacyEntry("dashboard", "x"), mint_run_id: "1" };
  assert.match(validateEntry("dashboard", hybrid).join("\n"), /a legacy entry has no mint run id/);
});

test("real directory: every legacy PNG's bytes equal its manifest sha256 and the byte check can fail (positive control)", () => {
  const entries = readEntries(REAL_DIRECTORY);
  for (const name of EXPECTED_BASELINES) {
    const key = name.replace(/\.png$/, "");
    assert.equal(sha256(readFileSync(path.join(REAL_DIRECTORY, name))), entries[key].sha256, `${name} bytes equal the manifest`);
    // An untouched key keeps its Phase 211 entry; a rebaselined key is a minted entry with a run id.
    if (entries[key].provenance === "phase211-committed") assert.equal(entries[key].mint_run_id, null, `${key}: a legacy entry has no mint run id`);
    else {
      assert.equal(entries[key].provenance, "phase254-mint", `${key}: provenance`);
      assert.match(String(entries[key].mint_run_id), /^\d+$/, `${key}: a minted entry has a mint run id`);
    }
  }
  const pre = checkBaselineSet(REAL_DIRECTORY, { preMint: true });
  assert.deepEqual(pre.problems, []);
  assert.deepEqual(pre.mismatched, []);
  // Positive control on a copy: flipping one byte of a legacy PNG must be reported.
  withBaselineDirectory((directory) => {
    for (const name of readdirSync(REAL_DIRECTORY)) writeFileSync(path.join(directory, name), readFileSync(path.join(REAL_DIRECTORY, name)));
    const bytes = readFileSync(path.join(directory, "dashboard.png"));
    bytes[bytes.length - 1] ^= 0xff;
    writeFileSync(path.join(directory, "dashboard.png"), bytes);
    assert.deepEqual(checkBaselineSet(directory, { preMint: true }).mismatched, ["dashboard.png"]);
  });
});

test("real directory: the strict check fails exactly while a case baseline is not minted", () => {
  const pre = checkBaselineSet(REAL_DIRECTORY, { preMint: true });
  const strict = checkBaselineSet(REAL_DIRECTORY);
  assert.equal(strict.ok, pre.preMintTolerated.length === 0 && pre.ok);
  assert.ok(strict.expected.length >= 44, "the expected set derives from the tracked case list");
});
