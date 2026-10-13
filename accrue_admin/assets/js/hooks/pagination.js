// Observe the paging boundary without scrolling the operator to appended rows.
// The explicit Load more button remains usable when observation is unavailable.
export const Pagination = {
  mounted() {
    if (typeof IntersectionObserver === "undefined") return;
    const target = Number(this.el.dataset.paginationTarget);
    if (!Number.isInteger(target) || target <= 0) return;
    this.paginationLoading = false;
    this.paginationObserver = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting) || this.paginationLoading) return;
      this.paginationLoading = true;
      this.pushEventTo(target, "load-more", {}, () => { this.paginationLoading = false; });
    });
    this.paginationObserver.observe(this.el);
  },

  destroyed() {
    this.paginationObserver?.disconnect();
  }
};
