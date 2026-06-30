import assert from "node:assert/strict";
import test from "node:test";

import { initDropdowns } from "../../assets/js/hooks/dropdown.js";

function rect({ left, top, width, height }) {
  return {
    left,
    top,
    width,
    height,
    right: left + width,
    bottom: top + height
  };
}

function styleMap() {
  const values = new Map();

  return {
    setProperty(name, value) {
      values.set(name, String(value));
    },
    removeProperty(name) {
      values.delete(name);
    },
    getPropertyValue(name) {
      return values.get(name) || "";
    }
  };
}

function detailsElement(options = {}) {
  const summaryRect = options.summaryRect || rect({ left: 16, top: 16, width: 96, height: 40 });
  const panelRect = options.panelRect || rect({ left: 16, top: 64, width: 240, height: 160 });
  const summary = {
    focusCalls: [],
    getBoundingClientRect() {
      return summaryRect;
    },
    focus(options) {
      this.focusCalls.push(options);
    }
  };
  const attributes = new Map();
  const panelStyle = styleMap();
  const panel = {
    style: panelStyle,
    getBoundingClientRect() {
      const shiftX = Number.parseFloat(panelStyle.getPropertyValue("--ax-dropdown-shift-x")) || 0;
      const placement = details.dataset.floatingPlacement || "bottom";
      const gap = 8;
      const top = placement === "top" ? summaryRect.top - panelRect.height - gap : summaryRect.bottom + gap;

      return rect({
        left: panelRect.left + shiftX,
        top,
        width: panelRect.width,
        height: panelRect.height
      });
    }
  };

  return {
    open: true,
    insideTarget: {},
    dataset: {},
    removeCalls: 0,
    getBoundingClientRect() {
      return summaryRect;
    },
    setAttribute(attribute, value = "") {
      attributes.set(attribute, String(value));
    },
    getAttribute(attribute) {
      return attributes.get(attribute) || null;
    },
    hasAttribute(attribute) {
      return attributes.has(attribute);
    },
    contains(target) {
      return target === this.insideTarget;
    },
    querySelector(selector) {
      if (selector === "summary") return summary;
      if (selector === ".ax-dropdown-panel") return panel;
      return null;
    },
    removeAttribute(attribute) {
      assert.equal(attribute, "open");
      this.open = false;
      this.removeCalls += 1;
    },
    summary,
    panel
  };
}

function fakeDocument(dropdowns) {
  const listeners = { click: new Set(), keydown: new Set() };
  const bodyStyle = { overflow: "", paddingRight: "" };
  const rootStyle = {
    position: "",
    top: "",
    overflow: "",
    getPropertyValue() {
      return "";
    }
  };

  return {
    listeners,
    body: { style: bodyStyle },
    documentElement: { style: rootStyle },
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

function withWindow(windowLike, callback) {
  const priorWindow = globalThis.window;
  globalThis.window = windowLike;

  try {
    callback();
  } finally {
    if (priorWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = priorWindow;
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

// Phase 199: dropdowns are non-modal floating surfaces, not scroll-locking overlays.
test("dropdown dismissal does not apply modal scroll lock or aria-modal state", () => {
  const dropdown = detailsElement();
  const documentLike = fakeDocument([dropdown]);

  withDocument(documentLike, () => {
    initDropdowns();
    documentLike.dispatch("keydown", { key: "Escape" });
  });

  assert.equal(dropdown.open, false);
  assert.equal(dropdown.hasAttribute("inert"), false);
  assert.equal(dropdown.hasAttribute("aria-modal"), false);
  assert.equal(documentLike.documentElement.style.position, "");
  assert.equal(documentLike.documentElement.style.top, "");
  assert.equal(documentLike.documentElement.style.overflow, "");
  assert.equal(documentLike.body.style.overflow, "");
  assert.equal(documentLike.body.style.paddingRight, "");
});

test("open dropdown flips above a bottom-edge trigger and keeps transform origin near the trigger", () => {
  const dropdown = detailsElement({
    summaryRect: rect({ left: 256, top: 196, width: 56, height: 36 }),
    panelRect: rect({ left: 72, top: 240, width: 240, height: 152 })
  });
  const documentLike = fakeDocument([dropdown]);
  const windowLike = {
    innerWidth: 320,
    innerHeight: 240,
    addEventListener() {},
    requestAnimationFrame(callback) {
      callback();
    }
  };

  withWindow(windowLike, () => {
    withDocument(documentLike, () => {
      initDropdowns();
      documentLike.dispatch("toggle", { target: dropdown });
    });
  });

  assert.equal(dropdown.dataset.floatingPlacement, "top");
  assert.match(dropdown.panel.style.getPropertyValue("--ax-dropdown-shift-x"), /^-?\d+px$/);
  assert.match(dropdown.panel.style.getPropertyValue("--ax-dropdown-origin-x"), /^\d+px$/);
  assert.equal(dropdown.panel.style.getPropertyValue("--ax-dropdown-origin-y"), "bottom");

  const finalRect = dropdown.panel.getBoundingClientRect();
  assert.ok(finalRect.left >= 0, "panel should not clip past the left viewport edge");
  assert.ok(finalRect.right <= windowLike.innerWidth, "panel should not clip past the right viewport edge");
  assert.ok(finalRect.bottom <= dropdown.summary.getBoundingClientRect().top, "panel should sit above the trigger");
});
