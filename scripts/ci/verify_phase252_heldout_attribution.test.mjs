import assert from "node:assert/strict";
import test from "node:test";
import { assertHeldoutAttribution, collectLabSubject, loadLabSubject } from "./verify_phase252_transparency.mjs";

test("held-out attribution identifies synthetic stress evidence", () => {
  assert.equal(assertHeldoutAttribution(loadLabSubject()), true);
});

test("held-out attribution rejects representative and real-adopter claims beside disclaimers", () => {
  const original = collectLabSubject();
  const claims = [
    "The held-out stress input represents typical customer behavior.",
    "The held-out stress input is real adopter usage evidence.",
  ];
  for (const claim of claims) {
    const subject = structuredClone(original);
    subject.guide.text += `\n\n${claim}`;
    assert.throws(() => assertHeldoutAttribution(subject), /contradictory public claim/, claim);
  }
});

test("held-out attribution refuses missing disclaimers and relabelled source evidence", () => {
  const original = collectLabSubject();
  const missingDisclaimer = structuredClone(original);
  missingDisclaimer.guide.text = missingDisclaimer.guide.text.replace(
    "not representative customer behavior or real adopter usage evidence",
    "synthetic stress input",
  );
  assert.throws(() => assertHeldoutAttribution(missingDisclaimer), /does not distinguish synthetic ordinary and held-out evidence/);

  const emptyLabel = structuredClone(original);
  emptyLabel.browser_evidence.label = " ";
  assert.throws(() => assertHeldoutAttribution(emptyLabel), /browser evidence label is missing or empty/);

  const ordinaryRelabel = structuredClone(original);
  ordinaryRelabel.ordinary.lane = "held_out";
  assert.throws(() => assertHeldoutAttribution(ordinaryRelabel), /ordinary adapter no longer accepts only its ordinary lane/);

  const heldOutRelabel = structuredClone(original);
  heldOutRelabel.held_out.lane = "ordinary";
  assert.throws(() => assertHeldoutAttribution(heldOutRelabel), /source facts are not separately attributed/);

  const missingFixtureLabel = structuredClone(original);
  missingFixtureLabel.browser_evidence.label = "held-out long text";
  assert.throws(() => assertHeldoutAttribution(missingFixtureLabel), /browser stress clone is not labelled separately/);
});
