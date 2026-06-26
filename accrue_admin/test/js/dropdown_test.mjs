import assert from "node:assert/strict";
import test from "node:test";

import { initDropdowns } from "../../assets/js/hooks/dropdown.js";

function detailsElement() {
  const summary = {
    focusCalls: [],
    focus(options) {
      this.focusCalls.push(options);
    }
  };

  return {
    open: true,
    insideTarget: {},
    removeCalls: 0,
    contains(target) {
      return target === this.insideTarget;
    },
    querySelector(selector) {
      return selector === "summary" ? summary : null;
    },
    removeAttribute(attribute) {
      assert.equal(attribute, "open");
      this.open = false;
      this.removeCalls += 1;
    },
    summary
  };
}

function fakeDocument(dropdowns) {
  const listeners = { click: new Set(), keydown: new Set() };

  return {
    listeners,
    addEventListener(type, handler) {
      if (!listeners[type]) listeners[type] = new Set();
      listeners[type].add(handler);
    },
    querySelectorAll(selector) {
      assert.equal(selector, "details.ax-dropdown[open]");
      return dropdowns.filter((dropdown) => dropdown.open);
    },
    dispatch(type, event) {
      for (const handler of Array.from(listeners[type] || [])) {
        handler(event);
      }
    }
  };
}

function withDocument(documentLike, callback) {
  const priorDocument = globalThis.document;
  globalThis.document = documentLike;

  try {
    callback();
  } finally {
    if (priorDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = priorDocument;
    }
  }
}

test("Escape closes an open dropdown and restores focus to the summary trigger", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("keydown", { key: "Escape" });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.removeCalls, 1);
  assert.deepEqual(dropdown.summary.focusCalls, [{ preventScroll: true }]);
});

test("outside click closes an open dropdown and restores focus", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("click", { target: {} });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.removeCalls, 1);
  assert.deepEqual(dropdown.summary.focusCalls, [{ preventScroll: true }]);
});

test("inside click leaves an open dropdown alone", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("click", { target: dropdown.insideTarget });
  });

  assert.equal(dropdown.open, true);
  assert.equal(dropdown.removeCalls, 0);
  assert.deepEqual(dropdown.summary.focusCalls, []);
});

test("repeated close attempts are safe after the dropdown is already closed", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("keydown", { key: "Escape" });
    documentLike.dispatch("keydown", { key: "Escape" });
    documentLike.dispatch("click", { target: {} });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.removeCalls, 1);
  assert.deepEqual(dropdown.summary.focusCalls, [{ preventScroll: true }]);
});
