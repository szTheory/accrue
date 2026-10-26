// Progressive enhancement: retain a native keyboard/manual control, while
// automatically loading one page near the boundary without moving the reader.
export const Pagination = {
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
        const button = this.el.querySelector('[data-role="load-more"]');
        if (button) button.disabled = false;
        Pagination.syncObserver.call(this);
      });
    }, { rootMargin: "0px 0px 160px 0px" });
    Pagination.syncObserver.call(this);
  },

  updated() {
    // Polls must not retrigger an unchanged boundary. A new cursor re-arms the
    // observer, including short pages that still leave the boundary in view.
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
    const boundary = this.el.dataset.paginationError === "true"
      ? null : this.el.querySelector('[data-role="viewport-sentinel"]');
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
