import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  LEDGER_PATH,
  MANIFEST_PATH,
  SUBSCRIPTION_STORY_PATH,
  expectedPhase252Cells,
  extractVariationIds,
  frozenManifestAt,
  frozenSubjectsAt,
  readCurationLedger,
  scenarioNames,
  scenarios,
  subjectsSha256,
  verifyFixtures,
  verifyLedger,
} from "./verify_phase254_curation.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const SCRIPT = path.join(ROOT, "scripts/ci/verify_phase254_curation.mjs");

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(ROOT, relativePath), "utf8"));
}

for (const [name, scenario] of scenarios()) test(`fixture: ${name}`, scenario);

test("every rejection scenario passes together (verifyFixtures)", () => {
  assert.equal(verifyFixtures(), scenarioNames().length);
  assert.ok(scenarioNames().length >= 17);
});

test("--self-test exits 0, names each scenario and reports the seeded positive control", () => {
  const result = spawnSync(process.execPath, [SCRIPT, "--self-test"], { encoding: "utf8", cwd: ROOT });
  assert.equal(result.status, 0, result.stderr);
  for (const name of scenarioNames()) assert.ok(result.stdout.includes(`ok - ${name}`), `self-test did not name: ${name}`);
  assert.match(result.stdout, /seeded populated reference-scan positive found/);
});

test("an unknown flag and a missing --results value fail closed", () => {
  const unknown = spawnSync(process.execPath, [SCRIPT, "--nope"], { encoding: "utf8", cwd: ROOT });
  assert.notEqual(unknown.status, 0);
  assert.match(unknown.stderr, /unknown option/);
  const missing = spawnSync(process.execPath, [SCRIPT, "--results"], { encoding: "utf8", cwd: ROOT });
  assert.notEqual(missing.status, 0);
  assert.match(missing.stderr, /--results requires a path/);
});

test("the committed ledger satisfies every rule against the tree and the frozen history", () => {
  const ledger = readCurationLedger(ROOT);
  const baseline = ledger.frozen_baseline;
  const summary = verifyLedger(ledger, {
    root: ROOT,
    manifest: readJson(MANIFEST_PATH),
    frozenSubjects: frozenSubjectsAt(baseline.source_commit, baseline.subject_sources, { root: ROOT }),
    frozenManifest: frozenManifestAt(baseline.source_commit, { root: ROOT }),
  });
  assert.ok(summary.records >= 3);
});

test("the committed ledger counts equal the tracked manifest and subject coverage holds", () => {
  const ledger = readCurationLedger(ROOT);
  const manifest = readJson(MANIFEST_PATH);
  assert.equal(ledger.frozen_baseline.entries - ledger.records.filter((record) => ["retire", "merge"].includes(record.disposition) && record.subject.story_path === SUBSCRIPTION_STORY_PATH && record.subject.variation_id !== null).length, manifest.entries.length);
  assert.equal(ledger.current.entries, manifest.entries.length);
  assert.equal(ledger.frozen_baseline.subjects_sha256, subjectsSha256(ledger.frozen_baseline.subjects));
  const subjects = ledger.frozen_baseline.subjects;
  assert.ok(subjects.some((subject) => subject.story_path === SUBSCRIPTION_STORY_PATH && subject.variation_id === "populated"));
  assert.ok(subjects.some((subject) => subject.story_path === "/components/action_menu" && subject.variation_id === "provider_pruned"));
  for (const record of ledger.records) {
    assert.ok(
      subjects.some((subject) => subject.story_path === record.subject.story_path && (record.subject.variation_id === null || subject.variation_id === record.subject.variation_id)),
      `${record.id} is grounded in the frozen baseline`,
    );
  }
});

test("per-file frozen subject counts equal the %Variation{ occurrences in the real story files", () => {
  const ledger = readCurationLedger(ROOT);
  const baseline = ledger.frozen_baseline;
  for (const source of baseline.subject_sources.filter((sourcePath) => sourcePath.endsWith(".story.exs"))) {
    const atCommit = spawnSync("git", ["-C", ROOT, "show", `${baseline.source_commit}:${source}`], { encoding: "utf8" });
    assert.equal(atCommit.status, 0, `git show ${source}`);
    const occurrences = (atCommit.stdout.match(/%Variation\{/g) || []).length;
    const subjects = baseline.subjects.filter((subject) => subject.source_path === source);
    assert.equal(subjects.length, occurrences, `${source} subject count`);
    assert.deepEqual(subjects.map((subject) => subject.variation_id).sort(), extractVariationIds(atCommit.stdout).sort());
  }
  assert.equal(baseline.subjects.filter((subject) => subject.story_path === "/components/page_header").length, 6);
});

test("expectedPhase252Cells on the committed ledger is the frozen 12/3/15 until a record retires a compatibility id", () => {
  const ledger = readCurationLedger(ROOT);
  const cells = expectedPhase252Cells(ledger);
  const retired = ledger.records.filter((record) => ["retire", "merge"].includes(record.disposition) && record.subject.story_path === SUBSCRIPTION_STORY_PATH).length;
  assert.equal(cells.canonical, 12);
  assert.equal(cells.compatibility, 3 - retired);
  assert.equal(cells.total, 15 - retired);
  assert.equal(expectedPhase252Cells({ frozen_baseline: ledger.frozen_baseline, records: [] }).total, 15, "frozen-only ledger stays the positive control");
});

test("LEDGER_PATH names the tracked package path (D-04)", () => {
  assert.equal(LEDGER_PATH, "accrue_admin/storybook/subscription-curation.json");
  assert.ok(fs.existsSync(path.join(ROOT, LEDGER_PATH)));
});
