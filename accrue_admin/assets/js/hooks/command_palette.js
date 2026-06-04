export const CommandPalette = {
  mounted() {
    this.activeIndex = 0;
    // Track previous focus to restore on close (WCAG 2.4.3 Focus Order)
    this.previousFocus = null;
    this.wasOpen = this.el.parentElement.dataset.open === "true";
    this.handleGlobalKeydown = this.handleGlobalKeydown.bind(this);
    this.handleInputKeydown = this.handleInputKeydown.bind(this);

    window.addEventListener("keydown", this.handleGlobalKeydown);

    this.el.addEventListener("keydown", this.handleInputKeydown);

    // Initial setup if already open
    this.setupItems();
  },

  updated() {
    this.activeIndex = 0;
    this.setupItems();

    const isOpen = this.el.parentElement.dataset.open === "true";

    if (isOpen && !this.wasOpen) {
      // Palette just opened: save focus before moving it to the input
      this.previousFocus = document.activeElement;
      const input = this.el.querySelector("input");
      if (input && document.activeElement !== input) {
        // setTimeout to ensure it's visible after LiveView patch
        setTimeout(() => input.focus(), 0);
      }
    } else if (!isOpen && this.wasOpen) {
      // Palette just closed: restore focus to the trigger element
      if (this.previousFocus && typeof this.previousFocus.focus === "function") {
        // Defer past the CSS exit transition so the focus ring appears after the palette is gone
        setTimeout(() => this.previousFocus.focus(), 0);
      }
      this.previousFocus = null;
    }

    this.wasOpen = isOpen;
  },

  destroyed() {
    window.removeEventListener("keydown", this.handleGlobalKeydown);
    this.el.removeEventListener("keydown", this.handleInputKeydown);
  },

  handleGlobalKeydown(e) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      this.pushEventTo(this.el.dataset.target, "toggle", {});
    }
    
    if (e.key === "Escape" && this.el.parentElement.dataset.open === "true") {
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
      this.selectActive();
    }
  },

  setupItems() {
    this.items = Array.from(this.el.querySelectorAll("li[data-path], li[data-action]"));
    this.updateActiveItem();
  },

  moveActive(step) {
    if (!this.items || this.items.length === 0) return;
    this.activeIndex = (this.activeIndex + step + this.items.length) % this.items.length;
    this.updateActiveItem();
  },

  updateActiveItem() {
    if (!this.items || this.items.length === 0) return;
    
    this.items.forEach(item => item.classList.remove("ax-active"));
    
    const activeItem = this.items[this.activeIndex];
    if (activeItem) {
      activeItem.classList.add("ax-active");
      activeItem.scrollIntoView({ block: "nearest" });
    }
  },

  selectActive() {
    if (!this.items || this.items.length === 0) return;
    
    const activeItem = this.items[this.activeIndex];
    if (activeItem) {
      if (activeItem.dataset.path) {
        this.pushEventTo(this.el.dataset.target, "close", {});
        window.liveSocket.pushHistoryPatch(activeItem.dataset.path, "push", this.el);
      } else if (activeItem.dataset.action) {
        this.pushEventTo(this.el.dataset.target, activeItem.dataset.action, {});
      }
    }
  }
};
