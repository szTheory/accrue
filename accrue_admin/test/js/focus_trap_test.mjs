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

function fakeWindow({ reducedMotion = false } = {}) {
  return {
    getComputedStyle() {
      return { display: "block", visibility: "visible" };
    },
    matchMedia(query) {
      return { matches: reducedMotion && query.includes("prefers-reduced-motion") };
    },
    requestAnimationFrame(callback) {
      callback();
      return 1;
    }
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

function withDocument(documentLike, callback, windowLike = fakeWindow()) {
  const priorDocument = globalThis.document;
  const priorWindow = globalThis.window;
  globalThis.document = documentLike;
  globalThis.window = windowLike;

  try {
    callback();
  } finally {
    if (priorDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = priorDocument;
    }
    if (priorWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = priorWindow;
    }
  }
}

async function withDocumentAsync(documentLike, callback, windowLike = fakeWindow()) {
  const priorDocument = globalThis.document;
  const priorWindow = globalThis.window;
  globalThis.document = documentLike;
  globalThis.window = windowLike;

  try {
    await callback();
  } finally {
    if (priorDocument === undefined) {
      delete globalThis.document;
    } else {
      globalThis.document = priorDocument;
    }
    if (priorWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = priorWindow;
    }
  }
}

function waitForTimers() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

// Phase 199: overlay entry must move focus into the panel before keyboard traversal.
test("initial focus moves to the configured target after activation", async () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const first = focusable("first", documentLike);
  const initial = focusable("initial", documentLike);
  initial.selector = "#drawer-primary-action";
  const root = rootElement([first, initial], {
    focusTrapInitial: "#drawer-primary-action",
    focusTrapCloseEvent: "close_drawer"
  });

  await withDocumentAsync(documentLike, async () => {
    trigger.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent() {}
    };

    hook.mounted();
    await waitForTimers();

    assert.equal(documentLike.activeElement, initial);

    hook.destroyed();
  });
});

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

// Phase 199: focus that escapes an active overlay must be brought back inside.
test("outside focus is redirected back inside the active trap", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const first = focusable("first", documentLike);
  const last = focusable("last", documentLike);
  const outside = focusable("outside", documentLike);
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

    documentLike.dispatch("focusin", { target: outside });
    assert.equal(documentLike.activeElement, first);

    hook.destroyed();
  });
});

test("nested traps only enforce focus and Escape from the topmost overlay", () => {
  const documentLike = fakeDocument();
  const drawerTrigger = focusable("drawer-trigger", documentLike);
  const drawerButton = focusable("drawer-button", documentLike);
  const modalInput = focusable("modal-input", documentLike);
  const outside = focusable("outside", documentLike);
  const drawerRoot = rootElement([drawerButton], {
    focusTrapCloseEvent: "close_drawer"
  });
  const modalRoot = rootElement([modalInput], {
    focusTrapCloseEvent: "close_modal"
  });
  const pushed = [];

  withDocument(documentLike, () => {
    drawerTrigger.focus();

    const drawerHook = {
      ...FocusTrap,
      el: drawerRoot,
      pushEvent(eventName, payload) {
        pushed.push(["drawer", eventName, payload]);
      }
    };
    const modalHook = {
      ...FocusTrap,
      el: modalRoot,
      pushEvent(eventName, payload) {
        pushed.push(["modal", eventName, payload]);
      }
    };

    drawerHook.mounted();
    drawerButton.focus();
    modalHook.mounted();

    modalInput.focus();
    documentLike.dispatch("focusin", { target: modalInput });
    assert.equal(documentLike.activeElement, modalInput);

    outside.focus();
    documentLike.dispatch("focusin", { target: outside });
    assert.equal(documentLike.activeElement, modalInput);

    const escape = keyEvent("Escape");
    documentLike.dispatch("keydown", escape);
    assert.equal(escape.defaultPrevented, true);
    assert.deepEqual(pushed, [["modal", "close_modal", {}]]);

    modalHook.destroyed();

    outside.focus();
    documentLike.dispatch("focusin", { target: outside });
    assert.equal(documentLike.activeElement, drawerButton);

    drawerHook.destroyed();
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

// Phase 199: Escape must use the same LiveView close target as the rendered backdrop.
test("Escape dispatches close events through the configured LiveView target", () => {
  const documentLike = fakeDocument();
  const cancel = focusable("cancel", documentLike);
  const root = rootElement([cancel], {
    focusTrapCloseEvent: "cancel_pending_action",
    focusTrapCloseTarget: "#invoice-drawer"
  });
  const pushed = [];

  withDocument(documentLike, () => {
    cancel.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEventTo(...args) {
        pushed.push(args);
      }
    };

    hook.mounted();

    const escape = keyEvent("Escape");
    documentLike.dispatch("keydown", escape);

    assert.equal(escape.defaultPrevented, true);
    assert.deepEqual(pushed, [["#invoice-drawer", "cancel_pending_action", {}]]);

    hook.destroyed();
  });
});

// Phase 199: closing a panel should restore the trigger when it still exists.
test("Destroy cleanup restores focus to the connected trigger", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const close = focusable("close", documentLike);
  const root = rootElement([close], {
    focusTrapCloseEvent: "close_drawer"
  });

  withDocument(documentLike, () => {
    trigger.focus();

    const hook = {
      ...FocusTrap,
      el: root,
      pushEvent() {}
    };

    hook.mounted();
    close.focus();
    hook.destroyed();

    assert.equal(documentLike.activeElement, trigger);
    assert.equal(trigger.focusCount, 2);
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

test("focus restoration prefers the surviving replacement trigger over the removed opener", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("old-trigger", documentLike);
  const replacement = focusable("replacement-trigger", documentLike);
  const close = focusable("close", documentLike);
  documentLike.registry["#invoice-action-trigger"] = replacement;
  const root = rootElement([close], {
    focusTrapCloseEvent: "close_drawer",
    focusTrapReturnTo: "#invoice-action-trigger"
  });

  withDocument(documentLike, () => {
    trigger.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    trigger.isConnected = false;

    hook.destroyed();

    assert.equal(documentLike.activeElement, replacement);
    assert.equal(replacement.focusCount, 1);
    assert.equal(documentLike.listeners.keydown.size, 0);
    assert.equal(documentLike.listeners.focusin.size, 0);
  });
});

// Phase 254 UXQ-02 (A11Y-254-29): Escape closes the action menu and the drawer together, so the
// control that opened the drawer is hidden when the drawer is torn down. Focus returns to the
// menu button (the <summary>) that owns the closed menu, not to the page.
test("focus returns to the owning menu button when the opener sat in a menu that has closed", () => {
  const documentLike = fakeDocument();
  const menuItem = focusable("menu-item", documentLike);
  const summary = focusable("more-actions", documentLike);
  summary.localName = "summary";
  summary.matches = () => false;
  summary.parentElement = { localName: "details" };
  menuItem.closest = (selector) => (selector === "details" ? { querySelector: (inner) => (inner === ":scope > summary" ? summary : null) } : null);
  const close = focusable("close", documentLike);
  const fallbackPage = focusable("main", documentLike);
  documentLike.registry["#main-content, main"] = fallbackPage;
  const root = rootElement([close], { focusTrapCloseEvent: "close_drawer" });

  withDocument(documentLike, () => {
    menuItem.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    menuItem.hidden = true; // the menu closed with Escape: the opener is not visible or focusable

    hook.destroyed();

    assert.equal(documentLike.activeElement, summary);
    assert.equal(summary.focusCount, 1);
    assert.equal(fallbackPage.focusCount, 0);
  });
});

// A closed <details> keeps boxes for its content (content-visibility), so the opener inside it looks
// visible to getBoundingClientRect even though it cannot take focus. It must be treated as hidden.
test("an opener inside a closed disclosure is skipped for the disclosure's own summary", () => {
  const documentLike = fakeDocument();
  const menuItem = focusable("menu-item", documentLike);
  const summary = focusable("more-actions", documentLike);
  summary.localName = "summary";
  summary.matches = () => false;
  summary.parentElement = { localName: "details" };
  summary.contains = (node) => node === summary;
  const closedDetails = {
    localName: "details",
    hasAttribute: () => false,
    querySelector: (inner) => (inner === ":scope > summary" ? summary : null)
  };
  menuItem.parentElement = { closest: (selector) => (selector === "details:not([open])" ? closedDetails : null) };
  menuItem.closest = (selector) => (selector === "details" ? closedDetails : null);
  const close = focusable("close", documentLike);
  const root = rootElement([close], { focusTrapCloseEvent: "close_drawer" });

  withDocument(documentLike, () => {
    menuItem.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    hook.destroyed();

    assert.equal(documentLike.activeElement, summary);
    assert.equal(menuItem.focusCount, 1, "the opener took focus once when the drawer opened and never again");
    assert.equal(summary.focusCount, 1);
  });
});

// The delayed return runs two animation frames after the overlay closes. A user who has already
// moved to another control (keyboard users tab quickly) must keep it.
test("the delayed focus return does not take a control the user has already moved to", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const elsewhere = focusable("back-link", documentLike);
  const close = focusable("close", documentLike);
  const root = rootElement([close], { focusTrapCloseEvent: "close_drawer" });
  let pending = null;
  const windowLike = { ...fakeWindow(), requestAnimationFrame(callback) { pending = callback; return 1; } };

  withDocument(documentLike, () => {
    trigger.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    hook.destroyed();
    elsewhere.focus(); // before the frames elapse
    pending?.();
    pending?.();

    assert.equal(documentLike.activeElement, elsewhere);
    assert.equal(trigger.focusCount, 1, "the opener took focus once, when the overlay opened");
  }, windowLike);
});

test("the delayed focus return still runs when focus is lost (positive control)", () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const close = focusable("close", documentLike);
  const root = rootElement([close], { focusTrapCloseEvent: "close_drawer" });
  let pending = null;
  const windowLike = { ...fakeWindow(), requestAnimationFrame(callback) { pending = callback; return 1; } };

  withDocument(documentLike, () => {
    trigger.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    hook.destroyed();
    documentLike.activeElement = null; // the overlay left the page and focus fell to nothing
    pending?.();
    pending?.();

    assert.equal(documentLike.activeElement, trigger);
  }, windowLike);
});

test("the owning menu button is not used while the opener is still focusable (positive control)", () => {
  const documentLike = fakeDocument();
  const menuItem = focusable("menu-item", documentLike);
  const summary = focusable("more-actions", documentLike);
  summary.localName = "summary";
  summary.matches = () => false;
  summary.parentElement = { localName: "details" };
  menuItem.closest = () => ({ querySelector: () => summary });
  const close = focusable("close", documentLike);
  const root = rootElement([close], { focusTrapCloseEvent: "close_drawer" });

  withDocument(documentLike, () => {
    menuItem.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    close.focus();
    hook.destroyed();

    assert.equal(documentLike.activeElement, menuItem);
    assert.equal(summary.focusCount, 0);
  });
});

test("rapid teardown with reduced motion cancels pending focus and cannot intercept later Tab", async () => {
  const documentLike = fakeDocument();
  const trigger = focusable("trigger", documentLike);
  const initial = focusable("initial", documentLike);
  const root = rootElement([initial], { focusTrapInitial: "#initial" });
  initial.selector = "#initial";
  const windowLike = fakeWindow({ reducedMotion: true });

  await withDocumentAsync(documentLike, async () => {
    trigger.focus();
    const hook = { ...FocusTrap, el: root, pushEvent() {} };
    hook.mounted();
    hook.destroyed();
    await waitForTimers();

    const tab = keyEvent("Tab");
    documentLike.dispatch("keydown", tab);

    assert.equal(windowLike.matchMedia("(prefers-reduced-motion: reduce)").matches, true);
    assert.equal(initial.focusCount, 0);
    assert.equal(tab.defaultPrevented, false);
    assert.equal(documentLike.listeners.keydown.size, 0);
    assert.equal(documentLike.listeners.focusin.size, 0);
  }, windowLike);
});
