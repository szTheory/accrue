const SHELL_SELECTOR = "#accrue-admin-shell";
const SCROLL_LOCK_SELECTOR = "[data-scroll-lock]";
const SCROLLBAR_COMPENSATION_VAR = "--ax-scrollbar-comp";
const SCROLL_LOCK_PRESENTATIONS = new Set(["modal", "drawer"]);

let lockCount = 0;
let savedScrollY = 0;
let previousState = null;
let reconcileObserver = null;
let reconcileTimer = null;

function browserDocument() {
  return typeof document === "undefined" ? null : document;
}

function browserWindow() {
  return typeof window === "undefined" ? null : window;
}

function snapshotStyle(style, properties) {
  if (!style) return {};

  return properties.reduce((snapshot, property) => {
    snapshot[property] = style[property] || "";
    return snapshot;
  }, {});
}

function restoreStyle(style, snapshot) {
  if (!style || !snapshot) return;

  Object.entries(snapshot).forEach(([property, value]) => {
    style[property] = value;
  });
}

function scrollbarCompensation(win, root) {
  if (!win || !root) return 0;
  return Math.max(0, (win.innerWidth || 0) - (root.clientWidth || 0));
}

function shellInertState(shell) {
  if (!shell) return null;

  return {
    shell,
    hadAttribute: Boolean(shell.hasAttribute?.("inert")),
    propertyValue: Boolean(shell.inert)
  };
}

function setShellInert(shell) {
  if (!shell) return;

  if ("inert" in shell) {
    shell.inert = true;
  }

  shell.setAttribute?.("inert", "");
}

function ensureCurrentShellInert(doc) {
  const shell = doc?.querySelector?.(SHELL_SELECTOR);
  if (!shell) return;

  if (previousState && previousState.shellInert?.shell !== shell) {
    previousState.shellInert = shellInertState(shell);
  }

  setShellInert(shell);
}

function restoreShellInert(state) {
  if (!state?.shell) return;

  if (state.hadAttribute) {
    state.shell.setAttribute?.("inert", "");
  } else {
    state.shell.removeAttribute?.("inert");
  }

  if ("inert" in state.shell) {
    state.shell.inert = state.propertyValue;
  }
}

function captureState(doc, win) {
  const root = doc?.documentElement;
  const body = doc?.body;

  return {
    root,
    body,
    rootStyle: snapshotStyle(root?.style, ["position", "top", "left", "right", "width", "overflow"]),
    bodyStyle: snapshotStyle(body?.style, ["overflow", "paddingRight"]),
    scrollbarCompensation: root?.style?.getPropertyValue?.(SCROLLBAR_COMPENSATION_VAR) || "",
    shellInert: shellInertState(doc?.querySelector?.(SHELL_SELECTOR)),
    scrollY: Number(win?.scrollY || win?.pageYOffset || 0)
  };
}

function applyLock(state, win) {
  const { root, body, scrollY } = state;
  const compensation = scrollbarCompensation(win, root);

  savedScrollY = scrollY;

  if (root?.style) {
    root.style.position = "fixed";
    root.style.top = `-${scrollY}px`;
    root.style.left = "0";
    root.style.right = "0";
    root.style.width = "100%";
    root.style.overflow = "hidden";
    root.style.setProperty?.(SCROLLBAR_COMPENSATION_VAR, `${compensation}px`);
  }

  if (body?.style) {
    body.style.overflow = "hidden";
    body.style.paddingRight = compensation > 0 ? `var(${SCROLLBAR_COMPENSATION_VAR})` : "";
  }

  setShellInert(state.shellInert?.shell);
}

function restoreLock(state, win) {
  restoreStyle(state.root?.style, state.rootStyle);
  restoreStyle(state.body?.style, state.bodyStyle);

  if (state.scrollbarCompensation) {
    state.root?.style?.setProperty?.(SCROLLBAR_COMPENSATION_VAR, state.scrollbarCompensation);
  } else {
    state.root?.style?.removeProperty?.(SCROLLBAR_COMPENSATION_VAR);
  }

  restoreShellInert(state.shellInert);
  win?.scrollTo?.(0, savedScrollY);
}

function scrollLockElementEnabled(element) {
  const presentation = element?.dataset?.presentation || "modal";
  const attr = element?.dataset?.scrollLock;

  if (!SCROLL_LOCK_PRESENTATIONS.has(presentation)) return false;
  if (attr === "false") return false;

  return attr === "true" || attr === "" || attr === undefined;
}

function activeScrollLockCount(doc) {
  const elements = doc?.querySelectorAll?.(SCROLL_LOCK_SELECTOR) || [];

  return Array.from(elements).filter(scrollLockElementEnabled).length;
}

function applyFirstLock(doc, win) {
  if (!doc?.documentElement || !doc?.body) return false;

  previousState = captureState(doc, win);
  applyLock(previousState, win);

  return true;
}

function scheduleActiveLockReconcile() {
  const win = browserWindow();

  if (win?.setTimeout) {
    if (reconcileTimer && win.clearTimeout) {
      win.clearTimeout(reconcileTimer);
    }

    reconcileTimer = win.setTimeout(() => {
      reconcileTimer = null;
      ScrollLock.reconcileActiveLocks();
    }, 0);

    return;
  }

  ScrollLock.reconcileActiveLocks();
}

export const ScrollLock = {
  lock() {
    lockCount += 1;

    const doc = browserDocument();
    const win = browserWindow();

    if (lockCount > 1) {
      ensureCurrentShellInert(doc);
      return lockCount;
    }

    applyFirstLock(doc, win);

    return lockCount;
  },

  unlock() {
    if (lockCount === 0) return 0;

    const doc = browserDocument();
    const win = browserWindow();

    lockCount -= 1;
    if (lockCount > 0) {
      ensureCurrentShellInert(doc);
      return lockCount;
    }

    const activeCount = activeScrollLockCount(doc);

    if (activeCount > 0) {
      if (!previousState && !applyFirstLock(doc, win)) return lockCount;

      ensureCurrentShellInert(doc);
      lockCount = activeCount;
      return lockCount;
    }

    const state = previousState;
    previousState = null;

    if (state) {
      restoreLock(state, win);
    }

    return lockCount;
  },

  reconcileActiveLocks() {
    const doc = browserDocument();
    const win = browserWindow();
    const activeCount = activeScrollLockCount(doc);

    if (activeCount > 0) {
      if (lockCount === 0 || !previousState) {
        if (!applyFirstLock(doc, win)) return lockCount;
      }

      ensureCurrentShellInert(doc);
      lockCount = activeCount;
      return lockCount;
    }

    if (lockCount > 0 && previousState) {
      restoreLock(previousState, win);
    }

    lockCount = 0;
    previousState = null;

    return lockCount;
  },

  initReconciler() {
    const doc = browserDocument();
    const win = browserWindow();
    const Observer = win?.MutationObserver || globalThis.MutationObserver;

    if (!doc?.body || reconcileObserver || !Observer) {
      this.reconcileActiveLocks();
      return;
    }

    reconcileObserver = new Observer(() => scheduleActiveLockReconcile());
    reconcileObserver.observe(doc.body, {
      attributes: true,
      attributeFilter: ["data-scroll-lock", "data-presentation"],
      childList: true,
      subtree: true
    });

    scheduleActiveLockReconcile();
  }
};

export function resetScrollLockForTests() {
  reconcileObserver?.disconnect?.();
  reconcileObserver = null;

  if (reconcileTimer && browserWindow()?.clearTimeout) {
    browserWindow().clearTimeout(reconcileTimer);
  }

  reconcileTimer = null;
  lockCount = 0;
  savedScrollY = 0;
  previousState = null;
}

export function initScrollLockReconciler() {
  ScrollLock.initReconciler();
}
