import assert from "node:assert/strict";
import test from "node:test";

import { FocusTrap } from "../../assets/js/hooks/focus_trap.js";

function fakeDocument() {
  const listeners = { keydown: new Set(), focusin: new Set() };

  return {
    activeElement: null,
    listeners,
    addEventListener(type, handler) {
      if (!listeners[type]) listeners[type] = new Set();
      listeners[type].add(handler);
    },
    removeEventListener(type, handler) {
      listeners[type]?.delete(handler);
    },
    dispatch(type, event) {
      for (const handler of Array.from(listeners[type] || [])) {
        handler(event);
      }
    },
    querySelector(selector) {
      return this.registry?.[selector] || null;
    },
    registry: {}
  };
}

function focusable(name, documentLike) {
  return {
    name,
    disabled: false,
    hidden: false,
    isConnected: true,
    attributes: {},
    focusCount: 0,
    getAttribute(attr) {
      return this.attributes[attr] || null;
    },
    hasAttribute(attr) {
      return Object.prototype.hasOwnProperty.call(this.attributes, attr);
    },
    matches() {
      return true;
    },
    focus() {
      this.focusCount += 1;
      documentLike.activeElement = this;
    }
  };
}

function rootElement(children, dataset = {}) {
  return {
    dataset,
    isConnected: true,
    hidden: false,
    getAttribute(attr) {
      if (attr === "aria-hidden") return this.ariaHidden || null;
      return null;
    },
    contains(node) {
      return children.includes(node);
    },
    querySelector(selector) {
      return children.find((child) => child.selector === selector) || null;
    },
    querySelectorAll() {
      return children;
    }
  };
}

function keyEvent(key, options = {}) {
  return {
    key,
    shiftKey: false,
    defaultPrevented: false,
    stopped: false,
    ...options,
    preventDefault() {
      this.defaultPrevented = true;
    },
    stopPropagation() {
      this.stopped = true;
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

test("Tab and Shift+Tab wrap across active overlay focus targets", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const first = focusable("first", documentLike);
  const last = focusable("last", documentLike);
  const root = rootElement([first, last], {
    focusTrapCloseEvent: "close_overlay"
  });

  withDocument(documentLike, () => {
    trigger.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent() {}
    };

    hook.mounted();

    first.focus();
    const reverse = keyEvent("Tab", { shiftKey: true });
    documentLike.dispatch("keydown", reverse);
    assert.equal(reverse.defaultPrevented, true);
    assert.equal(documentLike.activeElement, last);

    const forward = keyEvent("Tab");
    documentLike.dispatch("keydown", forward);
    assert.equal(forward.defaultPrevented, true);
    assert.equal(documentLike.activeElement, first);

    hook.destroyed();
  });
});

test("Escape invokes only the configured close event", () => {
  const documentLike = fakeDocument();
  const cancel = focusable("cancel", documentLike);
  const submit = focusable("submit", documentLike);
  submit.click = () => {
    throw new Error("Escape must not click submit controls");
  };

  const root = rootElement([cancel, submit], {
    focusTrapCloseEvent: "close_step_up"
  });
  const pushed = [];

  withDocument(documentLike, () => {
    cancel.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent(eventName, payload) {
        pushed.push([eventName, payload]);
      }
    };

    hook.mounted();

    const escape = keyEvent("Escape");
    documentLike.dispatch("keydown", escape);

    assert.equal(escape.defaultPrevented, true);
    assert.deepEqual(pushed, [["close_step_up", {}]]);

    hook.destroyed();
  });
});

test("Destroy cleanup removes listeners and restores fallback focus when trigger disconnected", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const close = focusable("close", documentLike);
  const fallback = focusable("heading", documentLike);
  fallback.selector = "#billing-heading";
  documentLike.registry["#billing-heading"] = fallback;

  const root = rootElement([close, fallback], {
    focusTrapCloseEvent: "close_drawer",
    focusTrapFallback: "#billing-heading"
  });

  withDocument(documentLike, () => {
    trigger.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent() {}
    };

    hook.mounted();
    assert.equal(documentLike.listeners.keydown.size, 1);
    assert.equal(documentLike.listeners.focusin.size, 1);

    trigger.isConnected = false;
    hook.destroyed();

    assert.equal(documentLike.listeners.keydown.size, 0);
    assert.equal(documentLike.listeners.focusin.size, 0);
    assert.equal(documentLike.activeElement, fallback);
  });
});
