import assert from "node:assert/strict";
import test from "node:test";

import { CommandPalette } from "../../assets/js/hooks/command_palette.js";

function focusable(name, documentLike, { tabIndex = 0 } = {}) {
  return {
    name,
    isConnected: true,
    hidden: false,
    disabled: false,
    tabIndex,
    attributes: {},
    focusCalls: [],
    getAttribute(attribute) {
      return this.attributes[attribute] || null;
    },
    focus(options) {
      this.focusCalls.push(options);
      documentLike.activeElement = this;
    },
    hasAttribute(attribute) {
      return Object.prototype.hasOwnProperty.call(this.attributes, attribute);
    },
    setAttribute(attribute, value) {
      this.attributes[attribute] = String(value);
    }
  };
}

function fakeDocument() {
  return {
    activeElement: null,
    listeners: { click: new Set() },
    registry: {},
    addEventListener(type, handler) {
      if (!this.listeners[type]) this.listeners[type] = new Set();
      this.listeners[type].add(handler);
    },
    removeEventListener(type, handler) {
      this.listeners[type]?.delete(handler);
    },
    querySelector(selector) {
      return this.registry[selector] || null;
    },
    dispatch(type, event) {
      for (const handler of Array.from(this.listeners[type] || [])) {
        handler(event);
      }
    }
  };
}

function fakeWindow() {
  return {
    listeners: { keydown: new Set() },
    addEventListener(type, handler) {
      if (!this.listeners[type]) this.listeners[type] = new Set();
      this.listeners[type].add(handler);
    },
    removeEventListener(type, handler) {
      this.listeners[type]?.delete(handler);
    },
    dispatch(type, event) {
      for (const handler of Array.from(this.listeners[type] || [])) {
        handler(event);
      }
    }
  };
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

function withBrowser(documentLike, windowLike, callback) {
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

async function withBrowserAsync(documentLike, windowLike, callback) {
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

function item(dataset) {
  return {
    dataset,
    classList: { add() {}, remove() {} },
    scrollIntoView() {}
  };
}

test("Enter patches to the active command path with LiveSocket's argument order", () => {
  const patches = [];
  const pushedEvents = [];
  const activeItem = item({ path: "/billing/customers" });
  let prevented = false;

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    items: [activeItem],
    el: { dataset: { target: "#global-search" } },
    pushEventTo(...args) {
      pushedEvents.push(args);
    }
  };

  const event = {
    key: "Enter",
    preventDefault() {
      prevented = true;
    }
  };

  withWindow(
    {
      liveSocket: {
        pushHistoryPatch(...args) {
          patches.push(args);
        }
      }
    },
    () => hook.handleInputKeydown(event)
  );

  assert.equal(prevented, true);
  assert.deepEqual(pushedEvents, [["#global-search", "close", {}]]);
  assert.equal(patches.length, 1);
  assert.equal(patches[0][0], event);
  assert.equal(patches[0][1], "/billing/customers");
  assert.equal(patches[0][2], "push");
  assert.equal(patches[0][3], activeItem);
});

// Phase 199: command palette keyboard lifecycle uses a single configured LiveView target.
test("Cmd+K opens the palette and Escape closes it through the configured target", () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const pushedEvents = [];
  let open = false;

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    el: {
      dataset: { target: "#global-search" },
      addEventListener() {},
      removeEventListener() {},
      querySelectorAll() {
        return [];
      },
      closest() {
        return open ? { dataset: { open: "true" } } : { dataset: { open: "false" } };
      }
    },
    pushEventTo(...args) {
      pushedEvents.push(args);
    }
  };

  withBrowser(documentLike, windowLike, () => {
    hook.mounted();

    const openEvent = {
      key: "k",
      metaKey: true,
      defaultPrevented: false,
      preventDefault() {
        this.defaultPrevented = true;
      }
    };
    windowLike.dispatch("keydown", openEvent);

    open = true;
    const escapeEvent = {
      key: "Escape",
      defaultPrevented: false,
      preventDefault() {
        this.defaultPrevented = true;
      }
    };
    windowLike.dispatch("keydown", escapeEvent);

    hook.destroyed();

    assert.equal(openEvent.defaultPrevented, true);
    assert.equal(escapeEvent.defaultPrevented, true);
    assert.deepEqual(pushedEvents, [
      ["#global-search", "toggle", {}],
      ["#global-search", "close", {}]
    ]);
  });
});

test("trigger clicks open the command palette without navigating", () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const pushedEvents = [];
  const trigger = {
    closest(selector) {
      return selector === "[data-command-palette-trigger]" ? this : null;
    }
  };
  const click = {
    target: trigger,
    defaultPrevented: false,
    preventDefault() {
      this.defaultPrevented = true;
    }
  };

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    el: {
      dataset: { target: "#global-search" },
      addEventListener() {},
      removeEventListener() {},
      querySelectorAll() {
        return [];
      },
      closest() {
        return { dataset: { open: "false" } };
      }
    },
    pushEventTo(...args) {
      pushedEvents.push(args);
    }
  };

  withBrowser(documentLike, windowLike, () => {
    hook.mounted();
    documentLike.dispatch("click", click);
    hook.destroyed();
  });

  assert.equal(click.defaultPrevented, true);
  assert.deepEqual(pushedEvents, [["#global-search", "open", {}]]);
});

// Phase 199: closing the palette should restore the invoking trigger, never body.
test("open and close updates move focus to input then restore the trigger without body fallback", async () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const wrapper = { dataset: { open: "false" } };
  const trigger = focusable("trigger", documentLike);
  const input = focusable("search input", documentLike);
  const body = focusable("body", documentLike);

  documentLike.registry["[data-command-palette-trigger], #main-content, main"] = body;
  trigger.focus();

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    wasOpen: false,
    previousFocus: null,
    items: [],
    el: {
      dataset: { target: "#global-search" },
      querySelector(selector) {
        return selector === "input" ? input : null;
      },
      querySelectorAll() {
        return [];
      },
      closest() {
        return wrapper;
      }
    }
  };

  await withBrowserAsync(documentLike, windowLike, async () => {
    wrapper.dataset.open = "true";
    hook.updated();
    await waitForTimers();

    assert.equal(documentLike.activeElement, input);

    wrapper.dataset.open = "false";
    hook.updated();
    await waitForTimers();

    assert.equal(documentLike.activeElement, trigger);
    assert.equal(body.focusCalls.length, 0);
  });
});

// Phase 199 RED: backdrop clicks should close through the same hook lifecycle as Escape.
test("backdrop clicks close the command palette through the hook lifecycle", () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const pushedEvents = [];
  const backdrop = {
    closest(selector) {
      if (selector === ".ax-command-palette-backdrop") return this;
      return null;
    }
  };
  const click = {
    target: backdrop,
    defaultPrevented: false,
    preventDefault() {
      this.defaultPrevented = true;
    }
  };

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    el: {
      dataset: { target: "#global-search" },
      addEventListener() {},
      removeEventListener() {},
      querySelectorAll() {
        return [];
      },
      closest() {
        return { dataset: { open: "true" } };
      }
    },
    pushEventTo(...args) {
      pushedEvents.push(args);
    }
  };

  withBrowser(documentLike, windowLike, () => {
    hook.mounted();
    documentLike.dispatch("click", click);
    hook.destroyed();
  });

  assert.deepEqual(pushedEvents, [["#global-search", "close", {}]]);
  assert.equal(click.defaultPrevented, true);
});

// Phase 199 RED: route close/destruction should restore the invoking trigger.
test("destroying an open command palette restores focus to the trigger", async () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const wrapper = { dataset: { open: "true" } };
  const trigger = focusable("trigger", documentLike);
  const input = focusable("search input", documentLike);

  trigger.focus();

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    wasOpen: false,
    previousFocus: null,
    el: {
      dataset: { target: "#global-search" },
      addEventListener() {},
      removeEventListener() {},
      querySelector(selector) {
        return selector === "input" ? input : null;
      },
      querySelectorAll() {
        return [];
      },
      closest() {
        return wrapper;
      }
    },
    pushEventTo() {}
  };

  await withBrowserAsync(documentLike, windowLike, async () => {
    hook.mounted();
    hook.updated();
    await waitForTimers();

    assert.equal(documentLike.activeElement, input);

    hook.destroyed();
    await waitForTimers();

    assert.equal(documentLike.activeElement, trigger);
  });
});

test("Tab stays contained inside an open command palette dialog", () => {
  const documentLike = fakeDocument();
  const windowLike = fakeWindow();
  const wrapper = { dataset: { open: "true" } };
  const input = focusable("search input", documentLike);
  const result = focusable("result link", documentLike);
  const outside = focusable("outside", documentLike);

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    wasOpen: true,
    previousFocus: outside,
    el: {
      dataset: { target: "#global-search" },
      addEventListener() {},
      removeEventListener() {},
      querySelector(selector) {
        return selector === "input" ? input : null;
      },
      querySelectorAll(selector) {
        if (selector.includes("a[href]")) return [input, result];
        return [];
      },
      contains(node) {
        return node === input || node === result;
      },
      closest() {
        return wrapper;
      }
    },
    pushEventTo() {}
  };

  withBrowser(documentLike, windowLike, () => {
    hook.mounted();

    result.focus();
    const forward = {
      key: "Tab",
      shiftKey: false,
      defaultPrevented: false,
      stopped: false,
      preventDefault() {
        this.defaultPrevented = true;
      },
      stopPropagation() {
        this.stopped = true;
      }
    };
    documentLike.dispatch("keydown", forward);

    assert.equal(forward.defaultPrevented, true);
    assert.equal(documentLike.activeElement, input);

    input.focus();
    const reverse = {
      key: "Tab",
      shiftKey: true,
      defaultPrevented: false,
      stopped: false,
      preventDefault() {
        this.defaultPrevented = true;
      },
      stopPropagation() {
        this.stopped = true;
      }
    };
    documentLike.dispatch("keydown", reverse);

    assert.equal(reverse.defaultPrevented, true);
    assert.equal(documentLike.activeElement, result);

    hook.destroyed();
  });
});
