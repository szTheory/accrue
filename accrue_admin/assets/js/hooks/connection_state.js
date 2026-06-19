const DEFAULT_STALE_SELECTOR = [
  "[data-stale-disable]",
  "button[phx-click]",
  "button[phx-submit]",
  "button[form]",
  "form[phx-submit] button[type='submit']",
  "form[phx-submit] button:not([type])",
  "input[type='submit'][phx-click]",
  "input[type='submit'][phx-submit]",
  "[data-role='confirm-action']",
  "[data-role='confirm-refund']",
  "[data-role='confirm-replay']",
  "[data-role='confirm-bulk-replay']",
  "[data-role='step-up-submit']"
].join(", ");

function restoreAttribute(element, name, value) {
  if (value === null) {
    element.removeAttribute(name);
  } else {
    element.setAttribute(name, value);
  }
}

function focusWithoutScroll(element) {
  if (element && typeof element.focus === "function") {
    element.focus({ preventScroll: true });
  }
}

export const ConnectionState = {
  mounted() {
    this.status = this.el.querySelector("[data-connection-status]");
    this.message = this.el.querySelector("[data-connection-state-message]");
    this.staleSelector = this.el.dataset.staleDisableSelector || DEFAULT_STALE_SELECTOR;
    this.disabledControls = new Map();
    this.preStaleFocus = null;

    this.handleClick = (event) => {
      const staleControl = event.target.closest("[data-stale-disabled='true']");
      if (!staleControl) return;

      event.preventDefault();
      event.stopPropagation();
    };

    this.handleOffline = () => this.markDisconnected();
    this.handleOnline = () => this.markRestored();

    document.addEventListener("click", this.handleClick, true);
    window.addEventListener("offline", this.handleOffline);
    window.addEventListener("online", this.handleOnline);

    this.setState("connected", { hidden: true });
    this.ensurePageFocus();
  },

  disconnected() {
    this.markDisconnected();
  },

  reconnected() {
    this.markRestored();
  },

  destroyed() {
    this.restoreStaleControls();
    document.removeEventListener("click", this.handleClick, true);
    window.removeEventListener("offline", this.handleOffline);
    window.removeEventListener("online", this.handleOnline);
  },

  markDisconnected() {
    this.preStaleFocus = document.activeElement;
    this.setState("disconnected");
    this.disableStaleControls();
  },

  markRestored() {
    this.restoreStaleControls();
    this.setState("restored");
    this.restoreFocusIfNeeded();
  },

  setState(state, options = {}) {
    const hidden = options.hidden || false;
    this.el.dataset.connectionState = state;

    if (!this.status || !this.message) return;

    this.status.dataset.connectionState = state;
    this.status.hidden = hidden;

    if (state === "disconnected") {
      this.message.textContent = this.message.dataset.disconnectedCopy;
    } else if (state === "restored") {
      this.message.textContent = this.message.dataset.restoredCopy;
    } else {
      this.message.textContent = "";
    }
  },

  disableStaleControls() {
    for (const control of this.el.querySelectorAll(this.staleSelector)) {
      if (this.disabledControls.has(control)) continue;

      this.disabledControls.set(control, {
        disabled: "disabled" in control ? control.disabled : undefined,
        ariaDisabled: control.getAttribute("aria-disabled"),
        tabindex: control.getAttribute("tabindex")
      });

      control.dataset.staleDisabled = "true";
      control.setAttribute("aria-disabled", "true");

      if ("disabled" in control) {
        control.disabled = true;
      } else {
        control.setAttribute("tabindex", "-1");
      }
    }
  },

  restoreStaleControls() {
    for (const [control, prior] of this.disabledControls.entries()) {
      if (!control.isConnected) continue;

      delete control.dataset.staleDisabled;
      restoreAttribute(control, "aria-disabled", prior.ariaDisabled);

      if (prior.disabled !== undefined) {
        control.disabled = prior.disabled;
      } else {
        restoreAttribute(control, "tabindex", prior.tabindex);
      }
    }

    this.disabledControls.clear();
  },

  restoreFocusIfNeeded() {
    const active = document.activeElement;
    const focusWasLost = !active || active === document.body;
    const target = this.preStaleFocus;

    if (focusWasLost && target && target.isConnected) {
      focusWithoutScroll(target);
    }

    this.preStaleFocus = null;
  },

  ensurePageFocus() {
    window.requestAnimationFrame(() => {
      if (document.activeElement && document.activeElement !== document.body) return;

      const target = this.el.querySelector("#main-content, main");
      focusWithoutScroll(target);
    });
  }
};
