import assert from "node:assert/strict";
import test from "node:test";
import { PreserveDisclosure } from "../../assets/js/hooks/preserve_disclosure.js";

function fixture(dismissible) {
  const listeners = new Map();
  const doc = new Map();
  const state = { focused: false };
  const summary = { focus() { state.focused = true; } };
  const el = { open: true, hasAttribute: () => dismissible, contains: target => target === summary,
    querySelector: () => summary,
    addEventListener: (name, fn) => listeners.set(name, fn),
    removeEventListener: name => listeners.delete(name),
    ownerDocument: { addEventListener: (name, fn) => doc.set(name, fn), removeEventListener: name => doc.delete(name) }
  };
  summary.parentElement = el;
  const hook = { ...PreserveDisclosure, el };
  hook.mounted();
  return { hook, el, listeners, doc, summary, state };
}

test("status picker preserves selection-time disclosure and dismisses outside or with Escape", () => {
  const { hook, el, listeners, doc, summary, state } = fixture(true);
  hook.beforeUpdate();
  el.open = false; // server patch returns a closed native details
  hook.updated();
  assert.equal(el.open, true);
  doc.get("pointerdown")({ type: "pointerdown", target: summary });
  assert.equal(el.open, true);
  doc.get("pointerdown")({ type: "pointerdown", target: {} });
  hook.updated();
  assert.equal(el.open, false);
  assert.equal(state.focused, false); // outside interaction keeps its focus destination
  el.open = true;
  let prevented = false;
  listeners.get("keydown")({ type: "keydown", key: "Escape", preventDefault() { prevented = true; }, stopPropagation() {} });
  assert.equal(el.open, false);
  assert.equal(state.focused, true);
  assert.equal(prevented, true);
  hook.destroyed();
  assert.equal(doc.size, 0);
  assert.equal(listeners.size, 0);
});

test("ordinary detail disclosures retain their existing behavior without global dismissal", () => {
  const { hook, doc, listeners } = fixture(false);
  assert.equal(doc.size, 0);
  assert.equal(listeners.has("keydown"), false);
  hook.destroyed();
  assert.equal(listeners.size, 0);
});
