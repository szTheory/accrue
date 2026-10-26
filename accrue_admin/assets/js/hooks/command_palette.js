import { FocusTrap } from "./focus_trap.js";

export const CommandPalette = {
  mounted() {
    this.activeIndex = -1;
    // Track previous focus to restore on close (WCAG 2.4.3 Focus Order)
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

    // Initial setup if already open
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
      // Palette just opened: save focus before moving it to the input
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
    const preservedIndex = previousContext === this.selectionContext && previousIdentity
      ? this.items.findIndex(item => this.itemIdentity(item) === previousIdentity)
      : -1;
    this.activeIndex = preservedIndex >= 0 ? preservedIndex : (this.items.length ? 0 : -1);
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
      return `${query}\u0000${base}\u0000${owner}`;
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
      // setTimeout to ensure it's visible after LiveView patch
      setTimeout(() => input.focus(), 0);
    }
  },

  restoreFocus() {
    const preferred = this.previousFocus && this.previousFocus.isConnected
      ? this.previousFocus
      : document.querySelector("[data-command-palette-trigger], #main-content, main");

    if (preferred && typeof preferred.focus === "function") {
      const needsTemporaryTabIndex =
        preferred.tabIndex < 0 && !preferred.hasAttribute("tabindex");

      if (needsTemporaryTabIndex) {
        preferred.setAttribute("tabindex", "-1");
      }

      // Defer past the CSS exit transition so the focus ring appears after the palette is gone.
      setTimeout(() => preferred.focus({ preventScroll: true }), 0);
    }
  },

  moveActive(step) {
    if (!this.items || this.items.length === 0) return;
    const current = this.activeIndex < 0 ? (step > 0 ? -1 : 0) : this.activeIndex;
    this.activeIndex = (current + step + this.items.length) % this.items.length;
    this.updateActiveItem();
  },

  updateActiveItem() {
    if (!this.items) return;
    
    this.items.forEach(item => {
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
