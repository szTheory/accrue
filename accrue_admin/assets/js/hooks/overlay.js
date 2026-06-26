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

export const Overlay = {
  ...FocusTrap,

  mounted() {
    this.overlayScrollLocked = false;
    FocusTrap.mounted.call(this);
    this.syncOverlayScrollLock();
  },

  updated() {
    FocusTrap.updated.call(this);
    this.syncOverlayScrollLock();
  },

  destroyed() {
    this.releaseOverlayScrollLock();
    FocusTrap.destroyed.call(this);
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
