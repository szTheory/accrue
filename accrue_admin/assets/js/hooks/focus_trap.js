const FOCUSABLE_SELECTOR = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])",
  "[contenteditable='true']"
].join(",");

function isConnected(node) {
  return Boolean(node && node.isConnected !== false);
}

function isHidden(node) {
  return (
    !node ||
    node.hidden === true ||
    node.getAttribute?.("aria-hidden") === "true" ||
    node.getAttribute?.("data-focus-trap-hidden") === "true"
  );
}

function isFocusable(node) {
  if (!isConnected(node) || isHidden(node)) return false;
  if (node.disabled || node.getAttribute?.("aria-disabled") === "true") return false;
  if (node.getAttribute?.("tabindex") === "-1") return false;
  return typeof node.matches !== "function" || node.matches(FOCUSABLE_SELECTOR);
}

export const FocusTrap = {
  mounted() {
    this.previouslyFocused = null;
    this.focusTrapActive = false;
    this.initialFocusTimer = null;
    this.handleFocusTrapKeydown = this.handleFocusTrapKeydown.bind(this);
    this.handleFocusTrapFocusin = this.handleFocusTrapFocusin.bind(this);

    if (this.isFocusTrapActive()) {
      this.activateFocusTrap();
    }
  },

  updated() {
    const active = this.isFocusTrapActive();

    if (active && !this.focusTrapActive) {
      this.activateFocusTrap();
    } else if (!active && this.focusTrapActive) {
      this.deactivateFocusTrap({ restoreFocus: true });
    }
  },

  destroyed() {
    this.deactivateFocusTrap({ restoreFocus: true });
  },

  isFocusTrapActive() {
    return !isHidden(this.el) && this.el?.dataset?.focusTrapActive !== "false";
  },

  activateFocusTrap() {
    this.previouslyFocused = document.activeElement;
    this.focusTrapActive = true;
    document.addEventListener("keydown", this.handleFocusTrapKeydown);
    document.addEventListener("focusin", this.handleFocusTrapFocusin);
    this.scheduleInitialFocus();
  },

  deactivateFocusTrap({ restoreFocus } = { restoreFocus: false }) {
    if (this.initialFocusTimer) {
      clearTimeout(this.initialFocusTimer);
      this.initialFocusTimer = null;
    }

    if (this.focusTrapActive) {
      document.removeEventListener("keydown", this.handleFocusTrapKeydown);
      document.removeEventListener("focusin", this.handleFocusTrapFocusin);
    }

    this.focusTrapActive = false;

    if (restoreFocus) {
      this.restoreFocus();
    }
  },

  scheduleInitialFocus() {
    this.initialFocusTimer = setTimeout(() => {
      this.initialFocusTimer = null;
      if (!this.focusTrapActive) return;
      if (this.el.contains?.(document.activeElement)) return;
      this.initialFocusTarget()?.focus?.();
    }, 0);
  },

  focusableElements() {
    return Array.from(this.el.querySelectorAll?.(FOCUSABLE_SELECTOR) || []).filter(isFocusable);
  },

  initialFocusTarget() {
    const selector = this.el.dataset?.focusTrapInitial;
    const explicit = selector ? this.el.querySelector?.(selector) || document.querySelector?.(selector) : null;
    return explicit || this.focusableElements()[0] || this.fallbackFocusTarget();
  },

  fallbackFocusTarget() {
    const selector = this.el.dataset?.focusTrapFallback;
    const explicit = selector ? this.el.querySelector?.(selector) || document.querySelector?.(selector) : null;

    return (
      explicit ||
      this.el.querySelector?.("[data-focus-trap-fallback]") ||
      document.querySelector?.("[data-focus-trap-fallback]") ||
      document.querySelector?.("[role='alert']") ||
      document.querySelector?.("main h1, main h2, h1, h2")
    );
  },

  restoreFocus() {
    const previous = this.previouslyFocused;
    this.previouslyFocused = null;

    if (isConnected(previous) && typeof previous.focus === "function") {
      previous.focus();
      return;
    }

    this.fallbackFocusTarget()?.focus?.();
  },

  handleFocusTrapKeydown(event) {
    if (!this.focusTrapActive) return;

    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation?.();
      this.dispatchFocusTrapClose();
      return;
    }

    if (event.key !== "Tab") return;

    const focusable = this.focusableElements();

    if (focusable.length === 0) {
      event.preventDefault();
      this.fallbackFocusTarget()?.focus?.();
      return;
    }

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const activeElement = document.activeElement;

    if (event.shiftKey && activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && activeElement === last) {
      event.preventDefault();
      first.focus();
    } else if (!this.el.contains?.(activeElement)) {
      event.preventDefault();
      first.focus();
    }
  },

  handleFocusTrapFocusin(event) {
    if (!this.focusTrapActive || this.el.contains?.(event.target)) return;
    const first = this.focusableElements()[0] || this.fallbackFocusTarget();
    first?.focus?.();
  },

  dispatchFocusTrapClose() {
    const eventName = this.el.dataset?.focusTrapCloseEvent;
    if (!eventName) return;

    const target = this.el.dataset?.focusTrapCloseTarget;
    if (target && typeof this.pushEventTo === "function") {
      this.pushEventTo(target, eventName, {});
    } else if (typeof this.pushEvent === "function") {
      this.pushEvent(eventName, {});
    }
  }
};
