import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { assertLabPresentation, collectLabSubject, loadLabSubject, parseSubjectJson } from "./verify_phase252_transparency.mjs";

test("lab presentation states disposable static limits", () => {
  assert.equal(assertLabPresentation(loadLabSubject()), true);
});

test("lab presentation rejects affirmative production and completion claims beside disclaimers", () => {
  const original = collectLabSubject();
  const mutations = [
    { surface: "guide", claim: "The review lab is a production operations console." },
    { surface: "guide", claim: "The review lab proves completed billing actions." },
    { surface: "story", claim: "The subscription story proves completed billing actions." },
    { surface: "story", claim: "The subscription story establishes mounted authorization." },
    { surface: "story", claim: "The subscription story demonstrates provider completion." },
    { surface: "story", claim: "The subscription story proves persistence." },
  ];
  for (const { surface, claim } of mutations) {
    const subject = structuredClone(original);
    if (surface === "guide") subject.guide.text += `\n\n${claim}`;
    else subject.story.moduledoc += `\n\n${claim}`;
    assert.throws(() => assertLabPresentation(subject), /contradictory public claim/, claim);
  }
});

test("lab subject rejects missing, empty, malformed, duplicate, and unknown data", () => {
  const subject = collectLabSubject();
  assert.throws(() => assertLabPresentation({ ...subject, schema_version: 2 }), /unrecognized subject schema/);
  assert.throws(() => assertLabPresentation({ ...subject, guide: { ...subject.guide, text: "  " } }), /guide prose is missing or empty/);
  const duplicate = structuredClone(subject);
  duplicate.manifest.entries[1].key = duplicate.manifest.entries[0].key;
  assert.throws(() => assertLabPresentation(duplicate), /duplicate manifest entry key/);
  assert.throws(() => parseSubjectJson("{", "test subject"), /malformed JSON/);

  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase252-lab-subject-"));
  try {
    assert.throws(() => collectLabSubject(tempRoot), /required source is missing/);
    const invalidPath = path.join(tempRoot, "malformed.json");
    fs.writeFileSync(invalidPath, "{", "utf8");
    assert.throws(() => loadLabSubject({ GSD_PROHIB_SUBJECT: "malformed.json" }, tempRoot, tempRoot), /malformed JSON/);
    assert.throws(() => loadLabSubject({ GSD_PROHIB_SUBJECT: "missing.json" }, tempRoot, tempRoot), /injected subject file is missing or unreadable/);
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
});
