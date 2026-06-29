import assert from "node:assert/strict";
import { afterEach, beforeEach, test } from "node:test";

import { ScrollLock, resetScrollLockForTests } from "../../assets/js/hooks/scroll_lock.js";

function styleDeclaration() {
  const customProperties = new Map();

  return {
    position: "",
    top: "",
    left: "",
    right: "",
    width: "",
    overflow: "",
    paddingRight: "",
    setProperty(name, value) {
      customProperties.set(name, String(value));
    },
    getPropertyValue(name) {
      return customProperties.get(name) || "";
    },
    removeProperty(name) {
      customProperties.delete(name);
    }
  };
}

function shellElement() {
  const attributes = new Map();

  return {
    inert: false,
    setAttribute(name, value = "") {
      attributes.set(name, String(value));
      if (name === "inert") this.inert = true;
    },
    removeAttribute(name) {
      attributes.delete(name);
      if (name === "inert") this.inert = false;
    },
    hasAttribute(name) {
      return attributes.has(name);
    }
  };
}

function fakeBrowser({ scrollY = 0, innerWidth = 1024, clientWidth = 1008 } = {}) {
  const shell = shellElement();
  const activeScrollLocks = [];
  const documentElement = {
    style: styleDeclaration(),
    clientWidth
  };
  const body = {
    style: styleDeclaration()
  };

  const documentLike = {
    documentElement,
    body,
    activeScrollLocks,
    querySelector(selector) {
      return selector === "#accrue-admin-shell" ? shell : null;
    },
    querySelectorAll(selector) {
      return selector === "[data-scroll-lock]" ? activeScrollLocks : [];
    }
  };

  const windowLike = {
    innerWidth,
    scrollY,
    scrollCalls: [],
    scrollTo(x, y) {
      this.scrollCalls.push([x, y]);
      this.scrollY = y;
    }
  };

  return { activeScrollLocks, documentLike, shell, windowLike };
}

function withBrowserGlobals(browser, callback) {
  const priorDocument = globalThis.document;
  const priorWindow = globalThis.window;

  globalThis.document = browser.documentLike;
  globalThis.window = browser.windowLike;

  try {
    callback(browser);
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

beforeEach(() => {
  resetScrollLockForTests();
});

afterEach(() => {
  resetScrollLockForTests();
});

test("lock is ref-counted and restores only after the final unlock", () => {
  const browser = fakeBrowser({ scrollY: 240 });

  withBrowserGlobals(browser, ({ documentLike, shell }) => {
    ScrollLock.lock();
    ScrollLock.lock();

    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.unlock();
    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.unlock();
    assert.equal(documentLike.documentElement.style.position, "");
    assert.equal(shell.hasAttribute("inert"), false);
  });
});

test("lock saves scroll position with an iOS-safe fixed top offset and restores exactly", () => {
  const browser = fakeBrowser({ scrollY: 512 });

  withBrowserGlobals(browser, ({ documentLike, windowLike }) => {
    ScrollLock.lock();

    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(documentLike.documentElement.style.top, "-512px");

    windowLike.scrollY = 0;
    ScrollLock.unlock();

    assert.deepEqual(windowLike.scrollCalls.at(-1), [0, 512]);
    assert.equal(windowLike.scrollY, 512);
    assert.equal(documentLike.documentElement.style.top, "");
  });
});

test("accrue admin shell remains inert until the final unlock", () => {
  const browser = fakeBrowser();

  withBrowserGlobals(browser, ({ shell }) => {
    assert.equal(shell.hasAttribute("inert"), false);

    ScrollLock.lock();
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.lock();
    ScrollLock.unlock();
    assert.equal(shell.hasAttribute("inert"), true);

    ScrollLock.unlock();
    assert.equal(shell.hasAttribute("inert"), false);
  });
});

test("scrollbar compensation is set while locked and cleared after unlock", () => {
  const browser = fakeBrowser({ innerWidth: 1200, clientWidth: 1183 });

  withBrowserGlobals(browser, ({ documentLike }) => {
    ScrollLock.lock();

    assert.equal(
      documentLike.documentElement.style.getPropertyValue("--ax-scrollbar-comp"),
      "17px"
    );

    ScrollLock.unlock();
    assert.equal(documentLike.documentElement.style.getPropertyValue("--ax-scrollbar-comp"), "");
  });
});

// Phase 199: rapid overlay churn must not leave body/root styles or inert state behind.
test("rapid lock and unlock cycles restore prior styles, inert state, and scroll position", () => {
  const browser = fakeBrowser({ scrollY: 73, innerWidth: 1000, clientWidth: 990 });

  withBrowserGlobals(browser, ({ documentLike, shell, windowLike }) => {
    documentLike.documentElement.style.overflow = "clip";
    documentLike.documentElement.style.setProperty("--ax-scrollbar-comp", "4px");
    documentLike.body.style.overflow = "visible";
    documentLike.body.style.paddingRight = "2px";
    shell.setAttribute("inert", "");

    ScrollLock.lock();
    ScrollLock.unlock();
    ScrollLock.unlock();
    ScrollLock.lock();
    ScrollLock.unlock();

    assert.equal(documentLike.documentElement.style.position, "");
    assert.equal(documentLike.documentElement.style.top, "");
    assert.equal(documentLike.documentElement.style.overflow, "clip");
    assert.equal(documentLike.documentElement.style.getPropertyValue("--ax-scrollbar-comp"), "4px");
    assert.equal(documentLike.body.style.overflow, "visible");
    assert.equal(documentLike.body.style.paddingRight, "2px");
    assert.equal(shell.hasAttribute("inert"), true);
    assert.deepEqual(windowLike.scrollCalls, [
      [0, 73],
      [0, 73]
    ]);
  });
});

test("reconcile keeps shell inert when a LiveView patch replaces an open drawer with step-up overlays", () => {
  const browser = fakeBrowser({ scrollY: 128 });
  const drawer = { dataset: { presentation: "drawer", scrollLock: "true" } };
  const modal = { dataset: { presentation: "modal", scrollLock: "true" } };

  withBrowserGlobals(browser, ({ activeScrollLocks, documentLike, shell }) => {
    activeScrollLocks.push(drawer);

    ScrollLock.lock();
    assert.equal(shell.hasAttribute("inert"), true);

    activeScrollLocks.push(modal);
    ScrollLock.unlock();
    assert.equal(shell.hasAttribute("inert"), false);

    ScrollLock.reconcileActiveLocks();

    assert.equal(documentLike.documentElement.style.position, "fixed");
    assert.equal(shell.hasAttribute("inert"), true);
  });
});
