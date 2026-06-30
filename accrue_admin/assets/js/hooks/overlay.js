import { FocusTrap } from "./focus_trap";
import { ScrollLock } from "./scroll_lock";

const SCROLL_LOCK_PRESENTATIONS = new Set(["modal", "drawer"]);

function presentationFor(element) {
  return element?.dataset?.presentation || "modal";
}

function scrollLockEnabled(element) {
  const presentation = presentationFor(element);
  const attr = element?.dataset?.scrollLock;

  if (!SCROLL_LOCK_PRESENTATIONS.has(presentation)) return false;
  if (attr === "false") return false;

  return attr === "true" || attr === "" || attr === undefined;
}

function scheduleScrollLockReconcile() {
  if (typeof window === "undefined") {
    ScrollLock.reconcileActiveLocks();
    return;
  }

  window.setTimeout(() => ScrollLock.reconcileActiveLocks(), 0);
}

function schedulePageFocusFallback() {
  if (typeof window === "undefined") return;

  window.setTimeout(() => {
    if (document.querySelector("#ax-overlay-root [data-ax-overlay-shell]")) return;
    if (document.activeElement && document.activeElement !== document.body) return;

    const fallback = document.querySelector("#main-content, main");
    if (fallback && typeof fallback.focus === "function") {
      fallback.focus({ preventScroll: true });
    }
  }, 0);
}

export const Overlay = {
  ...FocusTrap,

  mounted() {
    this.overlayScrollLocked = false;
    FocusTrap.mounted.call(this);
    this.syncOverlayScrollLock();
    scheduleScrollLockReconcile();
  },

  updated() {
    FocusTrap.updated.call(this);
    this.syncOverlayScrollLock();
    scheduleScrollLockReconcile();
  },

  destroyed() {
    this.releaseOverlayScrollLock();
    FocusTrap.destroyed.call(this);
    scheduleScrollLockReconcile();
    schedulePageFocusFallback();
  },

  syncOverlayScrollLock() {
    const shouldLock = scrollLockEnabled(this.el);

    if (shouldLock && !this.overlayScrollLocked) {
      ScrollLock.lock();
      this.overlayScrollLocked = true;
    } else if (!shouldLock && this.overlayScrollLocked) {
      ScrollLock.unlock();
      this.overlayScrollLocked = false;
    }
  },

  releaseOverlayScrollLock() {
    if (!this.overlayScrollLocked) return;

    ScrollLock.unlock();
    this.overlayScrollLocked = false;
  }
};
