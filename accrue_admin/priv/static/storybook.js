/* committed Storybook hooks bundle plus PhoenixStorybook 1.2 runtime. */
(() => {
  // accrue_admin/assets/js/hooks/focus_trap.js
  var FOCUSABLE_SELECTOR = [
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
  function focusWithoutScroll(node) {
    if (!node || typeof node.focus !== "function") return false;
    try {
      node.focus({ preventScroll: true });
    } catch (_error) {
      node.focus();
    }
    return true;
  }
  function restoreFocusAfterPatch(node, { requireFocusable = false } = {}) {
    if (!node || typeof node.focus !== "function") return false;
    const restore = () => {
      if (!isConnected(node) || !isVisibleForFocus(node)) return;
      if (requireFocusable && !isFocusable(node)) return;
      focusWithoutScroll(node);
    };
    window.requestAnimationFrame(() => window.requestAnimationFrame(restore));
    return true;
  }
  function isHidden(node) {
    return !node || node.hidden === true || node.getAttribute?.("aria-hidden") === "true" || node.getAttribute?.("data-focus-trap-hidden") === "true";
  }
  function isFocusable(node) {
    if (!isConnected(node) || isHidden(node)) return false;
    if (node.disabled || node.getAttribute?.("aria-disabled") === "true") return false;
    if (node.getAttribute?.("tabindex") === "-1") return false;
    return typeof node.matches !== "function" || node.matches(FOCUSABLE_SELECTOR);
  }
  function isVisibleForFocus(node) {
    if (!node) return false;
    if (typeof window === "undefined") return true;
    const style = window.getComputedStyle?.(node);
    const rect = typeof node.getBoundingClientRect === "function" ? node.getBoundingClientRect() : null;
    return (!style || style.display !== "none" && style.visibility !== "hidden") && (!rect || rect.width > 0 && rect.height > 0);
  }
  var focusTrapStack = [];
  function removeFocusTrap(hook) {
    const index = focusTrapStack.indexOf(hook);
    if (index >= 0) focusTrapStack.splice(index, 1);
  }
  function pruneFocusTrapStack() {
    for (let index = focusTrapStack.length - 1; index >= 0; index -= 1) {
      const hook = focusTrapStack[index];
      if (!hook?.focusTrapActive || !isConnected(hook.el) || isHidden(hook.el)) {
        focusTrapStack.splice(index, 1);
      }
    }
  }
  function topFocusTrap() {
    pruneFocusTrapStack();
    return focusTrapStack[focusTrapStack.length - 1] || null;
  }
  function isTopFocusTrap(hook) {
    return topFocusTrap() === hook;
  }
  var FocusTrap = {
    mounted() {
      this.previouslyFocused = document.activeElement;
      this.focusTrapActive = false;
      this.initialFocusTimer = null;
      this.handleFocusTrapKeydown = this.handleFocusTrapKeydown.bind(this);
      this.handleFocusTrapFocusin = this.handleFocusTrapFocusin.bind(this);
      if (this.isFocusTrapActive()) {
        this.activateFocusTrap();
      } else if (this.el?.dataset?.focusTrapInitial) {
        this.scheduleInitialFocus({ requireActive: false });
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
      removeFocusTrap(this);
      focusTrapStack.push(this);
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
      removeFocusTrap(this);
      if (restoreFocus) {
        this.restoreFocus();
      }
    },
    scheduleInitialFocus({ requireActive = true } = {}) {
      this.initialFocusTimer = setTimeout(() => {
        this.initialFocusTimer = null;
        if (requireActive && !this.focusTrapActive) return;
        if (this.focusTrapActive && !isTopFocusTrap(this)) return;
        if (!this.focusTrapActive && this.isFocusTrapActive()) return;
        if (this.el.contains?.(document.activeElement)) return;
        focusWithoutScroll(this.initialFocusTarget());
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
      return explicit || this.el.querySelector?.("[data-focus-trap-fallback]") || document.querySelector?.("[data-focus-trap-fallback]") || document.querySelector?.("[role='alert']") || document.querySelector?.("main h1, main h2, h1, h2");
    },
    restoreFocus() {
      const previous = this.previouslyFocused;
      this.previouslyFocused = null;
      const returnSelector = this.el?.dataset?.focusTrapReturnTo;
      const returnTarget = returnSelector ? document.querySelector(returnSelector) : null;
      if (isFocusable(returnTarget) && isVisibleForFocus(returnTarget) && typeof returnTarget.focus === "function") {
        restoreFocusAfterPatch(returnTarget, { requireFocusable: true });
        return;
      }
      if (isFocusable(previous) && isVisibleForFocus(previous) && typeof previous.focus === "function") {
        restoreFocusAfterPatch(previous, { requireFocusable: true });
        return;
      }
      const fallback = this.fallbackFocusTarget();
      if (fallback && !this.el.contains?.(fallback) && restoreFocusAfterPatch(fallback)) return;
      const pageFallback = document.querySelector?.("#main-content, main");
      if (restoreFocusAfterPatch(pageFallback)) return;
      restoreFocusAfterPatch(fallback);
    },
    handleFocusTrapKeydown(event) {
      if (!this.focusTrapActive) return;
      if (!isTopFocusTrap(this)) return;
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
      if (!isTopFocusTrap(this)) return;
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

  // accrue_admin/assets/js/hooks/command_palette.js
  var CommandPalette = {
    mounted() {
      this.activeIndex = -1;
      this.previousFocus = null;
      this.wasOpen = this.isOpen();
      this.handleGlobalKeydown = this.handleGlobalKeydown.bind(this);
      this.handleInputKeydown = this.handleInputKeydown.bind(this);
      this.handlePointerMove = this.handlePointerMove.bind(this);
      this.handleDocumentClick = this.handleDocumentClick.bind(this);
      this.focusTrap = {
        ...FocusTrap,
        el: this.el,
        pushEventTo: (...args) => this.pushEventTo(...args),
        pushEvent: (...args) => this.pushEvent(...args),
        isFocusTrapActive: () => Boolean(this.isOpen())
      };
      window.addEventListener("keydown", this.handleGlobalKeydown);
      document.addEventListener("click", this.handleDocumentClick);
      this.el.addEventListener("keydown", this.handleInputKeydown);
      this.el.addEventListener("pointermove", this.handlePointerMove);
      this.setupItems();
      FocusTrap.mounted.call(this.focusTrap);
      if (this.wasOpen) {
        this.previousFocus = document.activeElement;
        this.focusPaletteInput();
      }
    },
    updated() {
      this.setupItems();
      if (this.focusTrap) {
        this.focusTrap.el = this.el;
        FocusTrap.updated.call(this.focusTrap);
      }
      const isOpen = this.isOpen();
      if (isOpen && !this.wasOpen) {
        this.previousFocus = document.activeElement;
        this.focusPaletteInput();
      } else if (!isOpen && this.wasOpen) {
        this.restoreFocus();
        this.previousFocus = null;
      }
      this.wasOpen = isOpen;
    },
    destroyed() {
      if (this.focusTrap) {
        FocusTrap.destroyed.call(this.focusTrap);
        this.focusTrap = null;
      }
      if (this.wasOpen) {
        this.restoreFocus();
        this.previousFocus = null;
      }
      window.removeEventListener("keydown", this.handleGlobalKeydown);
      document.removeEventListener("click", this.handleDocumentClick);
      this.el.removeEventListener("keydown", this.handleInputKeydown);
      this.el.removeEventListener("pointermove", this.handlePointerMove);
    },
    handleGlobalKeydown(e) {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        this.pushEventTo(this.el.dataset.target, "toggle", {});
      }
      if (e.key === "Escape" && this.isOpen()) {
        e.preventDefault();
        this.pushEventTo(this.el.dataset.target, "close", {});
      }
    },
    handleInputKeydown(e) {
      if (e.key === "ArrowDown") {
        e.preventDefault();
        this.moveActive(1);
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        this.moveActive(-1);
      } else if (e.key === "Enter") {
        e.preventDefault();
        this.selectActive(e);
      }
    },
    handlePointerMove(e) {
      const item = e.target.closest?.(".ax-command-palette-item[data-path], .ax-command-palette-item[data-action]");
      const index = item ? this.items?.indexOf(item) : -1;
      if (index >= 0 && index !== this.activeIndex) {
        this.activeIndex = index;
        this.updateActiveItem();
      }
    },
    handleDocumentClick(e) {
      const trigger = e.target.closest?.("[data-command-palette-trigger]");
      if (trigger) {
        e.preventDefault();
        this.pushEventTo(this.el.dataset.target, "open", {});
        return;
      }
      const backdrop = e.target.closest?.(".ax-command-palette-backdrop");
      if (!backdrop || !this.isOpen()) return;
      e.preventDefault();
      e.stopPropagation?.();
      this.pushEventTo(this.el.dataset.target, "close", {});
    },
    setupItems() {
      const previousItem = this.items?.[this.activeIndex];
      const previousIdentity = previousItem ? this.itemIdentity(previousItem) : null;
      const previousContext = this.selectionContext;
      this.items = Array.from(
        this.el.querySelectorAll(".ax-command-palette-item[data-path], .ax-command-palette-item[data-action]")
      );
      const input = this.el.querySelector?.("input");
      this.selectionContext = this.contextFor(input?.value || "", this.items);
      const preservedIndex = previousContext === this.selectionContext && previousIdentity ? this.items.findIndex((item) => this.itemIdentity(item) === previousIdentity) : -1;
      this.activeIndex = preservedIndex >= 0 ? preservedIndex : this.items.length ? 0 : -1;
      this.updateActiveItem();
    },
    itemIdentity(item) {
      return item.dataset.path ? `path:${item.dataset.path}` : `action:${item.dataset.action}`;
    },
    contextFor(query, items) {
      const path = items[0]?.dataset.path;
      if (!path) return query;
      try {
        const url = new URL(path, "http://localhost");
        const base = url.pathname.replace(/\/(customers|invoices|subscriptions)(\/.*)?$/, "");
        const owner = url.searchParams.get("org") || "";
        return `${query}\0${base}\0${owner}`;
      } catch {
        return query;
      }
    },
    isOpen() {
      const wrapper = this.el.closest(".ax-command-palette-wrapper");
      return wrapper && wrapper.dataset.open === "true";
    },
    focusPaletteInput() {
      const input = this.el.querySelector?.("input");
      if (input && document.activeElement !== input) {
        setTimeout(() => input.focus(), 0);
      }
    },
    restoreFocus() {
      const preferred = this.previousFocus && this.previousFocus.isConnected ? this.previousFocus : document.querySelector("[data-command-palette-trigger], #main-content, main");
      if (preferred && typeof preferred.focus === "function") {
        const needsTemporaryTabIndex = preferred.tabIndex < 0 && !preferred.hasAttribute("tabindex");
        if (needsTemporaryTabIndex) {
          preferred.setAttribute("tabindex", "-1");
        }
        setTimeout(() => preferred.focus({ preventScroll: true }), 0);
      }
    },
    moveActive(step) {
      if (!this.items || this.items.length === 0) return;
      const current = this.activeIndex < 0 ? step > 0 ? -1 : 0 : this.activeIndex;
      this.activeIndex = (current + step + this.items.length) % this.items.length;
      this.updateActiveItem();
    },
    updateActiveItem() {
      if (!this.items) return;
      this.items.forEach((item) => {
        item.classList.remove("ax-active");
        item.setAttribute?.("aria-selected", "false");
      });
      const activeItem = this.items[this.activeIndex];
      if (activeItem) {
        activeItem.classList.add("ax-active");
        activeItem.setAttribute?.("aria-selected", "true");
        activeItem.scrollIntoView({ block: "nearest" });
      }
      const input = this.el.querySelector?.("input");
      const listbox = activeItem?.closest?.('[role="listbox"]');
      if (input) {
        if (activeItem?.id && listbox?.id) {
          input.setAttribute?.("aria-activedescendant", activeItem.id);
          input.setAttribute?.("aria-controls", listbox.id);
        } else {
          input.removeAttribute?.("aria-activedescendant");
          input.removeAttribute?.("aria-controls");
        }
      }
      const status = this.el.querySelector?.("[data-active-result-status]");
      if (status) status.textContent = activeItem ? (activeItem.textContent || "").trim() : "";
    },
    selectActive(e) {
      if (!this.items || this.items.length === 0) return;
      const activeItem = this.items[this.activeIndex];
      if (activeItem) {
        if (activeItem.dataset.path) {
          this.pushEventTo(this.el.dataset.target, "close", {});
          window.liveSocket.pushHistoryPatch(e, activeItem.dataset.path, "push", activeItem);
        } else if (activeItem.dataset.action) {
          this.pushEventTo(this.el.dataset.target, activeItem.dataset.action, {});
        }
      }
    }
  };

  // accrue_admin/assets/js/hooks/connection_state.js
  var DEFAULT_STALE_SELECTOR = [
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
  function focusWithoutScroll2(element) {
    if (element && typeof element.focus === "function") {
      element.focus({ preventScroll: true });
    }
  }
  var ConnectionState = {
    mounted() {
      this.status = this.el.querySelector("[data-connection-status]");
      this.message = this.el.querySelector("[data-connection-state-message]");
      this.staleSelector = this.el.dataset.staleDisableSelector || DEFAULT_STALE_SELECTOR;
      this.disabledControls = /* @__PURE__ */ new Map();
      this.busyControls = /* @__PURE__ */ new Map();
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
        disabled: "disabled" in control ? control.disabled : void 0,
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
        if (prior.disabled !== void 0) {
          control.disabled = prior.disabled;
        } else {
          restoreAttribute(control, "tabindex", prior.tabindex);
        }
      }
      this.disabledControls.clear();
    },
    syncBusyControl(control) {
      if (!control.matches("[data-role='step-up-submit'], [data-role='confirm-action']")) return;
      const loading = control.classList.contains("phx-click-loading") || control.classList.contains("phx-submit-loading") || control.hasAttribute("data-phx-ref-loading");
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
          focusWithoutScroll2(replacement);
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
      return Array.from(document.querySelectorAll(this.staleSelector)).find(
        (control) => control.tagName === descriptor.tagName && control.getAttribute("phx-click") === descriptor.click && control.getAttribute("phx-submit") === descriptor.submit && control.getAttribute("data-role") === descriptor.role && control.getAttribute("aria-label") === descriptor.ariaLabel
      ) || null;
    },
    ensurePageFocus() {
      window.requestAnimationFrame(() => {
        if (document.activeElement && document.activeElement !== document.body) return;
        const target = this.el.querySelector("#main-content, main");
        focusWithoutScroll2(target);
      });
    }
  };

  // accrue_admin/assets/js/hooks/scroll_lock.js
  var SHELL_SELECTOR = "#accrue-admin-shell";
  var SCROLL_LOCK_SELECTOR = "[data-scroll-lock]";
  var SCROLLBAR_COMPENSATION_VAR = "--ax-scrollbar-comp";
  var SCROLL_LOCK_PRESENTATIONS = /* @__PURE__ */ new Set(["modal", "drawer"]);
  var lockCount = 0;
  var savedScrollY = 0;
  var previousState = null;
  var reconcileObserver = null;
  var reconcileTimer = null;
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
    return attr === "true" || attr === "" || attr === void 0;
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
  var ScrollLock = {
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

  // accrue_admin/assets/js/hooks/overlay.js
  var SCROLL_LOCK_PRESENTATIONS2 = /* @__PURE__ */ new Set(["modal", "drawer"]);
  function presentationFor(element) {
    return element?.dataset?.presentation || "modal";
  }
  function scrollLockEnabled(element) {
    const presentation = presentationFor(element);
    const attr = element?.dataset?.scrollLock;
    if (!SCROLL_LOCK_PRESENTATIONS2.has(presentation)) return false;
    if (attr === "false") return false;
    return attr === "true" || attr === "" || attr === void 0;
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
  var Overlay = {
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

  // accrue_admin/assets/js/toast.js
  var toastTimeout;
  function showToast(message, { duration = 2500 } = {}) {
    if (typeof document === "undefined" || !document.body) return;
    let toast = document.querySelector("[data-ax-toast]");
    if (!toast) {
      toast = document.createElement("div");
      toast.dataset.axToast = "true";
      toast.className = "ax-toast";
      toast.setAttribute("role", "status");
      document.body.append(toast);
    }
    clearTimeout(toastTimeout);
    toast.textContent = message;
    toast.hidden = false;
    toastTimeout = setTimeout(() => {
      toast.hidden = true;
    }, duration);
  }

  // accrue_admin/assets/js/hooks/clipboard.js
  function announce(button, message) {
    const parent = button.parentElement;
    if (!parent || typeof document === "undefined") return;
    let status = parent.querySelector("[data-clipboard-feedback]");
    if (!status) {
      status = document.createElement("span");
      status.dataset.clipboardFeedback = "true";
      status.className = "ax-visually-hidden";
      status.setAttribute("role", "status");
      status.setAttribute("aria-live", "polite");
      parent.append(status);
    }
    status.textContent = message;
  }
  function dispatch(button, type, text) {
    if (type === "clipboard:copied") {
      const label = button.dataset.clipboardLabel || "text";
      const message = `Copied ${label} to clipboard`;
      button.dataset.copied = "true";
      announce(button, message);
      showToast(message);
      button.dispatchEvent(new CustomEvent(type, { bubbles: true }));
      return;
    }
    delete button.dataset.copied;
    showToast("Could not copy. Select the text to copy it manually.");
    announce(button, `Clipboard unavailable. Select and copy the text manually: ${text}`);
    button.dispatchEvent(new CustomEvent(type, { bubbles: true, detail: { text } }));
  }
  var Clipboard = {
    mounted() {
      if (this.clipboardClickHandler) return;
      this.clipboardClickHandler = async () => {
        const text = this.el.dataset.clipboardText || "";
        if (!navigator.clipboard?.writeText) {
          dispatch(this.el, "clipboard:failed", text);
          return;
        }
        try {
          await navigator.clipboard.writeText(text);
          dispatch(this.el, "clipboard:copied", text);
        } catch {
          dispatch(this.el, "clipboard:failed", text);
        }
      };
      this.el.addEventListener("click", this.clipboardClickHandler);
    },
    destroyed() {
      if (this.clipboardClickHandler) {
        this.el.removeEventListener("click", this.clipboardClickHandler);
        this.clipboardClickHandler = null;
      }
    }
  };

  // accrue_admin/assets/js/hooks/preserve_disclosure.js
  var PreserveDisclosure = {
    mounted() {
      this.disclosureDesiredOpen = this.el.open;
      this.captureDisclosureIntent = (event) => {
        const summary = event.target.closest?.("summary");
        if (summary?.parentElement === this.el) {
          this.disclosureDesiredOpen = !this.el.open;
        }
      };
      this.el.addEventListener("click", this.captureDisclosureIntent, true);
      if (this.el.hasAttribute("data-disclosure-dismiss")) {
        this.dismissDisclosure = (event) => {
          if (!this.el.open) return;
          const escape = event.type === "keydown" && event.key === "Escape";
          const outside = event.type === "pointerdown" && !this.el.contains(event.target);
          if (!escape && !outside) return;
          this.disclosureDesiredOpen = false;
          this.el.open = false;
          if (escape) {
            event.preventDefault();
            event.stopPropagation();
            this.el.querySelector("summary")?.focus();
          }
        };
        this.el.addEventListener("keydown", this.dismissDisclosure);
        this.el.ownerDocument.addEventListener("pointerdown", this.dismissDisclosure);
      }
    },
    beforeUpdate() {
      if (typeof this.disclosureDesiredOpen !== "boolean") {
        this.disclosureDesiredOpen = this.el.open;
      }
    },
    updated() {
      this.el.open = this.disclosureDesiredOpen;
    },
    destroyed() {
      this.el.removeEventListener("click", this.captureDisclosureIntent, true);
      if (this.dismissDisclosure) {
        this.el.removeEventListener("keydown", this.dismissDisclosure);
        this.el.ownerDocument.removeEventListener("pointerdown", this.dismissDisclosure);
      }
    }
  };

  // accrue_admin/assets/js/hooks/time_display.js
  var activePreference = null;
  function formatTimestamp(iso, { locale, timeZone, mode, dateOnly = false } = {}) {
    if (typeof iso !== "string") return null;
    const parts = iso.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})$/);
    if (!parts) return null;
    const [, year, month, day, hour, minute, second, offset] = parts;
    const daysInMonth = [31, Number(year) % 4 === 0 && (Number(year) % 100 !== 0 || Number(year) % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][Number(month) - 1];
    if (!daysInMonth || Number(day) < 1 || Number(day) > daysInMonth) return null;
    if (Number(hour) > 23 || Number(minute) > 59 || Number(second) > 59) return null;
    if (offset !== "Z" && (Number(offset.slice(1, 3)) > 23 || Number(offset.slice(4, 6)) > 59)) return null;
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return null;
    try {
      const zone = timeZone || (mode === "utc" ? "UTC" : null) || Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
      const text = new Intl.DateTimeFormat(locale, {
        year: "numeric",
        month: "short",
        day: "2-digit",
        ...dateOnly ? {} : { hour: "2-digit", minute: "2-digit", second: "2-digit", timeZoneName: "short" },
        timeZone: zone
      }).format(date);
      return { text, timeZone: zone };
    } catch {
      return null;
    }
  }
  function selectedMode() {
    return activePreference || "local";
  }
  function renderTimestampElement(element) {
    const time = element.querySelector("time");
    const result = formatTimestamp(element.dataset.iso, { mode: selectedMode(), dateOnly: element.dataset.timeFormat === "date" });
    if (!time || !result) return;
    time.textContent = result.text;
    const zone = element.querySelector("[data-time-zone]");
    if (zone) {
      zone.textContent = result.timeZone;
      zone.classList?.add("ax-visually-hidden");
    }
    const button = element.querySelector("button[data-clipboard-text]");
    if (button?.setAttribute) button.setAttribute("title", `${result.timeZone}. Click to copy the exact UTC timestamp.`);
  }
  var TimeDisplay = {
    mounted() {
      this.renderTimestamp();
      this.onCopied = () => {
        this.setStatus("Timestamp copied.");
        this.setCopyFallback("");
      };
      this.onCopyFailed = (event) => {
        const text = event.detail?.text;
        this.setStatus("Clipboard unavailable. Select and copy the UTC timestamp below.");
        this.setCopyFallback(text || "Timestamp unavailable for manual copy.");
      };
      this.el.addEventListener("clipboard:copied", this.onCopied);
      this.el.addEventListener("clipboard:failed", this.onCopyFailed);
    },
    updated() {
      this.renderTimestamp();
    },
    destroyed() {
      this.el.removeEventListener("clipboard:copied", this.onCopied);
      this.el.removeEventListener("clipboard:failed", this.onCopyFailed);
    },
    renderTimestamp() {
      renderTimestampElement(this.el);
    },
    setStatus(message) {
      const status = this.el.querySelector("[data-time-copy-status]");
      if (status) status.textContent = message;
    },
    setCopyFallback(text) {
      const fallback = this.el.querySelector("[data-time-copy-fallback]");
      if (!fallback) return;
      fallback.textContent = text;
      fallback.hidden = text.length === 0;
    }
  };

  // accrue_admin/assets/js/hooks/json_viewer_tabs.js
  var JsonViewerTabs = {
    mounted() {
      this.activateTab = (tab, focus = false) => {
        if (!tab || !this.el.contains(tab)) return;
        const tabs = [...this.el.querySelectorAll("[data-json-tab]")];
        const selected = tab.dataset.jsonTab;
        tabs.forEach((candidate) => {
          const active = candidate === tab;
          candidate.setAttribute("aria-selected", String(active));
          candidate.setAttribute("tabindex", active ? "0" : "-1");
          candidate.classList.toggle("ax-tab-active", active);
          const panel = document.getElementById(candidate.getAttribute("aria-controls"));
          if (panel && this.el.contains(panel)) panel.hidden = candidate !== tab;
        });
        this.el.dataset.activeJsonTab = selected;
        if (focus) tab.focus();
      };
      this.onClick = (event) => {
        const tab = event.target.closest?.("[data-json-tab]");
        if (tab) this.activateTab(tab);
      };
      this.onKeyDown = (event) => {
        const current = event.target.closest?.("[data-json-tab]");
        if (!current) return;
        const tabs = [...this.el.querySelectorAll("[data-json-tab]")];
        const index = tabs.indexOf(current);
        let nextIndex;
        if (event.key === "ArrowRight") nextIndex = (index + 1) % tabs.length;
        else if (event.key === "ArrowLeft") nextIndex = (index - 1 + tabs.length) % tabs.length;
        else if (event.key === "Home") nextIndex = 0;
        else if (event.key === "End") nextIndex = tabs.length - 1;
        else return;
        event.preventDefault();
        this.activateTab(tabs[nextIndex], true);
      };
      this.el.addEventListener("click", this.onClick);
      this.el.addEventListener("keydown", this.onKeyDown);
    },
    destroyed() {
      this.el.removeEventListener("click", this.onClick);
      this.el.removeEventListener("keydown", this.onKeyDown);
    }
  };

  // accrue_admin/assets/js/hooks/pagination.js
  var Pagination = {
    mounted() {
      if (typeof IntersectionObserver === "undefined") return;
      const target = Number(this.el.dataset.paginationTarget);
      if (!Number.isInteger(target) || target <= 0) return;
      this.paginationLoading = false;
      this.paginationDestroyed = false;
      this.el.dataset.paginationAuto = "true";
      this.paginationObserver = new IntersectionObserver((entries) => {
        if (!entries.some((entry) => entry.isIntersecting) || this.paginationLoading) return;
        if (this.el.dataset.paginationError === "true" || !this.el.dataset.paginationCursor) return;
        this.paginationLoading = true;
        this.el.dataset.paginationLoading = "true";
        this.el.setAttribute("aria-busy", "true");
        const button = this.el.querySelector('[data-role="load-more"]');
        if (button) button.disabled = true;
        this.pushEventTo(target, "load-more", {}, () => {
          if (this.paginationDestroyed) return;
          this.paginationLoading = false;
          this.el.dataset.paginationLoading = "false";
          this.el.removeAttribute("aria-busy");
          const button2 = this.el.querySelector('[data-role="load-more"]');
          if (button2) button2.disabled = false;
          Pagination.syncObserver.call(this);
        });
      }, { rootMargin: "0px 0px 160px 0px" });
      Pagination.syncObserver.call(this);
    },
    updated() {
      if (this.paginationObserver) this.el.dataset.paginationAuto = "true";
      if (this.paginationLoading) {
        this.el.dataset.paginationLoading = "true";
        this.el.setAttribute("aria-busy", "true");
        const button = this.el.querySelector('[data-role="load-more"]');
        if (button) button.disabled = true;
      }
      Pagination.syncObserver.call(this);
    },
    syncObserver() {
      if (!this.paginationObserver || this.paginationLoading) return;
      const boundary = this.el.dataset.paginationError === "true" ? null : this.el.querySelector('[data-role="viewport-sentinel"]');
      const cursor = this.el.dataset.paginationCursor;
      if (boundary === this.paginationBoundary && cursor === this.paginationCursor) return;
      this.paginationObserver.disconnect();
      this.paginationBoundary = boundary;
      this.paginationCursor = cursor;
      if (boundary && cursor) this.paginationObserver.observe(boundary);
    },
    disconnected() {
      this.paginationObserver?.disconnect();
      this.paginationBoundary = null;
      this.paginationLoading = false;
      this.el.dataset.paginationLoading = "false";
      this.el.removeAttribute("aria-busy");
      const button = this.el.querySelector('[data-role="load-more"]');
      if (button) button.disabled = false;
    },
    reconnected() {
      Pagination.syncObserver.call(this);
    },
    destroyed() {
      this.paginationDestroyed = true;
      this.paginationObserver?.disconnect();
    }
  };

  // accrue_admin/assets/js/storybook_hooks.js
  window.storybook = window.storybook || {};
  window.storybook.Hooks = {
    ...window.storybook.Hooks,
    CommandPalette,
    ConnectionState,
    FocusTrap,
    Overlay,
    Clipboard,
    PreserveDisclosure,
    TimeDisplay,
    JsonViewerTabs,
    Pagination
  };
})();

(()=>{var h,d={mounted(){h=this,window.addEventListener("psb:set-color-mode",this.onSetColorMode),window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change",()=>{let e=this.selectedColorMode(),o=this.actualColorMode(e);this.pushEvent("psb:set-color-mode",{selected_mode:e,mode:o}),this.toggleColorModeClass(o)})},destroyed(){window.removeEventListener("psb:set-color-mode",this.onSetColorMode)},selectedColorMode(){return localStorage.getItem("psb_selected_color_mode")||"system"},actualColorMode(e){return e==="system"&&window.matchMedia("(prefers-color-scheme: dark)").matches||e==="dark"?"dark":"light"},toggleColorModeClass:e=>{"psbColorMode"in document.documentElement.dataset&&(e==="dark"?document.documentElement.classList.add("psb:dark"):document.documentElement.classList.remove("psb:dark"))},onSetColorMode:e=>{let o=e.detail.mode||"system";localStorage.setItem("psb_selected_color_mode",o);let t=h.actualColorMode(o);h.pushEvent("psb:set-color-mode",{selected_mode:o,mode:t}),h.toggleColorModeClass(t)}},v=d.selectedColorMode(),S=d.actualColorMode(v);d.toggleColorModeClass(S);var p={execJS:(e,o)=>{e&&liveSocket.execJS(e,e.getAttribute(o))},mounted(){let e=document.querySelector("#psb-search-container"),o=document.querySelector("#psb-search-modal"),t=document.querySelector("#psb-search-list"),c=document.querySelector("#psb-search-input"),l=t.children,r=t.firstElementChild,i=t.lastElementChild,s=r;new MutationObserver(n=>{l=t.children,r=t.firstElementChild,i=t.lastElementChild,l.length>0&&(this.execJS(s,"phx-baseline"),s=r,this.execJS(s,"phx-highlight"))}).observe(t,{childList:!0}),window.addEventListener("psb:open-search",()=>{this.execJS(e,"phx-show"),this.execJS(o,"phx-show"),setTimeout(()=>c.focus(),50),this.execJS(s,"phx-highlight")}),window.addEventListener("psb:close-search",()=>{this.execJS(o,"phx-hide"),this.execJS(e,"phx-hide")}),window.addEventListener("keydown",n=>{n.metaKey&&(n.key==="k"||n.key==="K")&&(n.preventDefault(),this.dispatchOpenSearch())});for(let n of l)n.addEventListener("mouseover",a=>{a.movementX!==0&&a.movementY!==0&&a.target===n&&(this.execJS(s,"phx-baseline"),s=a.target,this.execJS(s,"phx-highlight"))});e.addEventListener("keydown",n=>{n.key==="Enter"&&(n.preventDefault(),s.querySelector("a")?.click()),n.key==="Escape"&&this.dispatchCloseSearch(),n.key==="Tab"&&n.preventDefault(),n.key==="ArrowUp"&&(this.execJS(s,"phx-baseline"),s===r?s=i:s=s.previousElementSibling,this.execJS(s,"phx-highlight"),s?.scrollIntoView({block:"nearest",inline:"nearest"})),n.key==="ArrowDown"&&(this.execJS(s,"phx-baseline"),s===i?s=r:s=s.nextElementSibling,this.execJS(s,"phx-highlight"),s?.scrollIntoView({block:"nearest",inline:"nearest"}))}),t.addEventListener("click",n=>{n.target.closest("a")&&(this.resetInput(c),this.dispatchCloseSearch())})},resetInput(e){e.value="",this.pushEventTo("#psb-search-container","search",{search:{input:""}})},dispatchOpenSearch(){let e=new Event("psb:open-search");window.dispatchEvent(e)},dispatchCloseSearch(){let e=new Event("psb:close-search");window.dispatchEvent(e)}};var m={mounted(){let e=document.querySelector("#psb-sidebar-container"),o=document.querySelector("#psb-sidebar-overlay"),t=()=>{e.classList.remove("psb:hidden"),o.classList.remove("psb:hidden")},c=()=>{e.classList.add("psb:hidden"),o.classList.add("psb:hidden")};this.handleEvent("psb:open-sidebar",t),this.handleEvent("psb:close-sidebar",c),window.addEventListener("psb:open-sidebar",t),window.addEventListener("psb:close-sidebar",c)}};var b={mounted(){if(window.location.hash){let e=document.querySelector(window.location.hash);if(e){let o=document.querySelector("#psb-live-container");setTimeout(()=>{o.scrollTop=e.offsetTop-115},100)}}this.bindAnchorLinks(),this.bindCopyCodeLinks()},updated(){this.bindAnchorLinks()},bindAnchorLinks(){for(let e of document.querySelectorAll(".psb-variation-anchor-link"))e.addEventListener("click",o=>{o.preventDefault(),window.history.replaceState({},"",e.hash)})},bindCopyCodeLinks(){let e=["psb:text-slate-500","psb:hover:text-slate-100"],o=["psb:text-green-400","psb:hover:text-green-400"],t="fa-copy",c="fa-check";window.addEventListener("psb:copy-code",l=>{let r=l.target;this.copyToClipboard(r.nextElementSibling.textContent);let i=r.querySelector(".fa-copy");i&&(r.classList.add(...o),r.classList.remove(...e),i.classList.add(c),i.classList.remove(t),setTimeout(()=>{i.classList.add(t),i.classList.remove(c),r.classList.add(...e),r.classList.remove(...o)},1e3))})},copyToClipboard(e){let o=document.createElement("textarea");o.textContent=e,o.style.position="fixed",document.body.appendChild(o),o.select();try{return document.execCommand("copy")}catch(t){return console.warn("Copy to clipboard failed.",t),prompt("Copy to clipboard: Ctrl+C, Enter",e)}finally{document.body.removeChild(o)}}};function u(e,o){for(let t of Object.keys(o??{}))e.includes(t)&&console.warn(`[phoenix_storybook] Hook "${t}" is reserved by PhoenixStorybook and will be overridden.`)}window.storybook===void 0&&(console.warn("No storybook configuration detected."),console.warn("If you need to use custom hooks or uploaders, please define them in JS file and declare this     file in your Elixir backend module options (:js_path key)."),window.storybook={});var f=window.storybook?.LiveView||window.LiveView,x=window.storybook?.Phoenix||window.Phoenix,C=document.querySelector("html").getAttribute("phx-socket")||"/live",L=document.querySelector("meta[name='csrf-token']")?.getAttribute("content"),k=d.selectedColorMode(),g=d.actualColorMode(k),w={"PhoenixStorybook.StoryHook":b,"PhoenixStorybook.SearchHook":p,"PhoenixStorybook.SidebarHook":m,"PhoenixStorybook.ColorModeHook":d};u(Object.keys(w),window.storybook.Hooks);var y=new f.LiveSocket(C,x.Socket,{hooks:{...window.storybook.Hooks,...w},uploaders:window.storybook.Uploaders,params:e=>({_csrf_token:L,extra:window.storybook.Params,selected_color_mode:k,color_mode:g}),...window.storybook.LiveSocketOptions});y.connect();window.liveSocket=y;})();
