const SHELL_SELECTOR = "#accrue-admin-shell";
const SCROLLBAR_COMPENSATION_VAR = "--ax-scrollbar-comp";

let lockCount = 0;
let savedScrollY = 0;
let previousState = null;

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

export const ScrollLock = {
  lock() {
    lockCount += 1;
    if (lockCount > 1) return lockCount;

    const doc = browserDocument();
    const win = browserWindow();

    if (!doc?.documentElement || !doc?.body) return lockCount;

    previousState = captureState(doc, win);
    applyLock(previousState, win);

    return lockCount;
  },

  unlock() {
    if (lockCount === 0) return 0;

    lockCount -= 1;
    if (lockCount > 0) return lockCount;

    const state = previousState;
    previousState = null;

    if (state) {
      restoreLock(state, browserWindow());
    }

    return lockCount;
  }
};

export function resetScrollLockForTests() {
  lockCount = 0;
  savedScrollY = 0;
  previousState = null;
}
