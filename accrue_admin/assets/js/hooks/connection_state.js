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
    this.busyControls = new Map();
    this.isDisconnected = false;
    this.preStaleFocus = null;
    this.preStaleFocusDescriptor = null;

    this.handleClick = (event) => {
      const staleControl = event.target.closest("[data-stale-disabled='true']");
      if (!staleControl) return;

      event.preventDefault();
      event.stopPropagation();
    };

    this.handleOffline = () => this.markDisconnected();
    this.handleOnline = () => this.markNetworkOnline();

    this.controlObserver = new MutationObserver((records) => {
      for (const record of records) {
        if (record.type === "attributes" && record.target instanceof Element) {
          this.syncBusyControl(record.target);
        }

        for (const node of record.addedNodes || []) {
          if (!(node instanceof Element)) continue;
          this.syncBusyControl(node);
          if (this.isDisconnected && node.matches(this.staleSelector)) this.disableControl(node);
          for (const control of node.querySelectorAll(this.staleSelector)) {
            if (this.isDisconnected) this.disableControl(control);
          }
        }

        for (const node of record.removedNodes || []) {
          if (node instanceof Element) this.forgetRemovedBusyControls(node);
        }
      }
    });

    // Overlay.portal mounts into #ax-overlay-root beside the shell. Observe the
    // document so pending and replacement controls there receive the guard.
    this.controlObserver.observe(document.body, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["class", "data-phx-ref-loading"]
    });

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
    this.controlObserver.disconnect();
    this.restoreBusyControls();
    this.isDisconnected = false;
  },

  markDisconnected() {
    if (!this.isDisconnected) {
      this.preStaleFocus = document.activeElement;
      this.preStaleFocusDescriptor = this.focusDescriptor(this.preStaleFocus);
    }
    this.isDisconnected = true;
    this.setState("disconnected");
    this.disableStaleControls();
  },

  markNetworkOnline() {
    if (!this.isDisconnected) return;

    // Browser connectivity does not establish a joined LiveView or refresh
    // action authorization. Keep every stale control locked until reconnected.
    this.setState("reconnecting");
    this.disableStaleControls();
  },

  markRestored() {
    this.isDisconnected = false;
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
    } else if (state === "reconnecting") {
      this.message.textContent = this.message.dataset.reconnectingCopy || this.message.dataset.disconnectedCopy;
    } else {
      this.message.textContent = "";
    }
  },

  disableStaleControls() {
    for (const control of document.querySelectorAll(this.staleSelector)) {
      this.disableControl(control);
    }
  },

  disableControl(control) {
    if (this.disabledControls.has(control)) return;

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

  syncBusyControl(control) {
    if (!control.matches("[data-role='step-up-submit'], [data-role='confirm-action']")) return;

    const loading = control.classList.contains("phx-click-loading") ||
      control.classList.contains("phx-submit-loading") ||
      control.hasAttribute("data-phx-ref-loading");

    if (loading) {
      if (!this.busyControls.has(control)) {
        this.busyControls.set(control, control.getAttribute("aria-busy"));
      }
      control.setAttribute("aria-busy", "true");

      if (!control.querySelector(":scope > .ax-button-spinner")) {
        const spinner = document.createElement("span");
        spinner.className = "ax-button-spinner";
        spinner.setAttribute("aria-hidden", "true");
        control.prepend(spinner);
      }
    } else {
      this.restoreBusyControl(control);
    }
  },

  restoreBusyControl(control) {
    if (!this.busyControls.has(control)) return;

    const priorAriaBusy = this.busyControls.get(control);
    if (priorAriaBusy === null) {
      control.removeAttribute("aria-busy");
    } else {
      control.setAttribute("aria-busy", priorAriaBusy);
    }

    control.querySelector(":scope > .ax-button-spinner")?.remove();
    this.busyControls.delete(control);
  },

  forgetRemovedBusyControls(node) {
    if (this.busyControls.has(node)) this.busyControls.delete(node);
    for (const control of node.querySelectorAll("[data-role='step-up-submit'], [data-role='confirm-action']")) {
      if (this.busyControls.has(control)) this.busyControls.delete(control);
    }
  },

  restoreBusyControls() {
    for (const control of this.busyControls.keys()) {
      if (control.isConnected) this.restoreBusyControl(control);
    }
    this.busyControls.clear();
  },

  restoreFocusIfNeeded() {
    const active = document.activeElement;
    const focusWasLost = !active || active === document.body;
    const target = this.preStaleFocus;

    if (focusWasLost) {
      const replacement = target && target.isConnected ? target : this.findFocusReplacement();
      const canFocus = replacement && !replacement.disabled && replacement.getAttribute("aria-disabled") !== "true";

      if (canFocus) {
        focusWithoutScroll(replacement);
      } else {
        this.ensurePageFocus();
      }
    }

    this.preStaleFocus = null;
    this.preStaleFocusDescriptor = null;
  },

  focusDescriptor(target) {
    if (!(target instanceof Element)) return null;

    return {
      tagName: target.tagName,
      click: target.getAttribute("phx-click"),
      submit: target.getAttribute("phx-submit"),
      role: target.getAttribute("data-role"),
      ariaLabel: target.getAttribute("aria-label")
    };
  },

  findFocusReplacement() {
    const descriptor = this.preStaleFocusDescriptor;
    if (!descriptor) return null;

    return Array.from(document.querySelectorAll(this.staleSelector)).find((control) =>
      control.tagName === descriptor.tagName &&
      control.getAttribute("phx-click") === descriptor.click &&
      control.getAttribute("phx-submit") === descriptor.submit &&
      control.getAttribute("data-role") === descriptor.role &&
      control.getAttribute("aria-label") === descriptor.ariaLabel
    ) || null;
  },

  ensurePageFocus() {
    window.requestAnimationFrame(() => {
      if (document.activeElement && document.activeElement !== document.body) return;

      const target = this.el.querySelector("#main-content, main");
      focusWithoutScroll(target);
    });
  }
};
