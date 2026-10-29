import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import * as transparency from "./verify_phase252_transparency.mjs";

const CLEAN = "scripts/ci/fixtures/phase253-transparency/clean.json";
const PAGE_RENDERER_SOURCE = "accrue_admin/lib/accrue_admin/live/subscription_live.ex";

test("truthful Phase253 composition attribution remains presentation-only", () => {
  assert.equal(typeof transparency.loadPhase253Subject, "function");
  assert.equal(typeof transparency.assertPhase253Presentation, "function");
  assert.equal(transparency.assertPhase253Presentation(transparency.loadPhase253Subject()), true);
});

test("Phase253 current source and manifest identity is exact", () => {
  const subject = transparency.collectPhase253Subject();
  assert.equal(transparency.assertPhase253Presentation(subject), true);
  const manifestPath = "accrue_admin/tmp/phase253/manifest.json";
  const manifestBytes = fs.readFileSync(manifestPath);
  const digest = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
  assert.equal(subject.source_identity.manifest_sha256, digest(manifestBytes));
  assert.equal(subject.source_identity.files[manifestPath], digest(manifestBytes));
  for (const [relative, expected] of Object.entries(subject.source_identity.files)) {
    assert.match(expected, /^[a-f0-9]{64}$/);
    assert.equal(digest(fs.readFileSync(relative)), expected, `${relative} current source digest`);
  }

  const manifest = JSON.parse(manifestBytes.toString("utf8"));
  assert.ok(Object.hasOwn(manifest.source_digests, PAGE_RENDERER_SOURCE), "compiled manifest hashes the production whole-page renderer");
  assert.ok(Object.hasOwn(subject.source_identity.files, PAGE_RENDERER_SOURCE), "transparency evidence hashes the production whole-page renderer");
  assert.equal(manifest.collection_variations.length, 10);
  assert.equal(manifest.page_entries.length, 9);
  assert.deepEqual(subject.manifest.collection_variations.map((entry) => entry.variation_id).sort(),
    manifest.collection_variations.map((entry) => entry.variation_id).sort());
  assert.deepEqual(subject.manifest.page_entries.map((entry) => entry.variation_id).sort(),
    manifest.page_entries.map((entry) => entry.variation_id).sort());
});

test("Phase253 subject and enumerated sources fail closed when malformed, missing, or empty", () => {
  assert.throws(() => transparency.parseSubjectJson("{", "Phase253 test subject"), /malformed JSON/);
  assert.throws(() => transparency.loadPhase253Subject({ GSD_PROHIB_SUBJECT: "  " }), /GSD_PROHIB_SUBJECT is missing or empty/);

  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase253-transparency-"));
  try {
    assert.throws(() => transparency.collectPhase253Subject(tempRoot), /required source is missing/);
    const guidePath = path.join(tempRoot, "guides/ui-story-lab.md");
    fs.mkdirSync(path.dirname(guidePath), { recursive: true });
    fs.writeFileSync(guidePath, " \n", "utf8");
    assert.throws(() => transparency.collectPhase253Subject(tempRoot), /required source is empty/);

    const missingInjected = transparency.loadPhase253Subject(
      { GSD_PROHIB_SUBJECT: "absent.json" }, tempRoot, tempRoot,
    );
    assert.fail(`missing injected file unexpectedly loaded: ${JSON.stringify(missingInjected)}`);
  } catch (error) {
    if (!/injected subject file is missing or unreadable/.test(error.message)) throw error;
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }

  const emptyRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase253-empty-source-"));
  try {
    const guidePath = path.join(emptyRoot, "guides/ui-story-lab.md");
    fs.mkdirSync(path.dirname(guidePath), { recursive: true });
    fs.writeFileSync(guidePath, "", "utf8");
    assert.throws(() => transparency.collectPhase253Subject(emptyRoot), /required source is empty/);
  } finally {
    fs.rmSync(emptyRoot, { recursive: true, force: true });
  }

  assert.ok(fs.existsSync(CLEAN));
});
