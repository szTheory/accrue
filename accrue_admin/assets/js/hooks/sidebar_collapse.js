/**
 * SidebarCollapse — Phoenix LiveView hook for collapsible sidebar nav groups.
 *
 * Persists expand/collapse state per group per mount_path in localStorage.
 * On mount, overrides server-rendered aria-expanded if a stored value exists.
 * Does not fire any server events — collapse is pure client state.
 *
 * Expected element attributes (on hook element = the <section> or collapsible wrapper):
 *   data-group       — group slug (e.g. "recovery", "developer")
 *   data-controls    — id of the <div> containing the link list to show/hide
 *   aria-expanded    — server-rendered initial state (overridden by localStorage)
 *
 * Reads mount_path from closest [data-mount-path] ancestor (set on ax-shell div).
 * localStorage key format: "ax-sidebar-{mountPath}-{group}"
 */
export const SidebarCollapse = {
  mounted() {
    const key = this.storageKey();
    const stored = localStorage.getItem(key);
    if (stored !== null) {
      this.setExpanded(stored === "true");
    }

    this.handleClick = this.handleClick.bind(this);
    this.el.addEventListener("click", this.handleClick);
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleClick);
  },

  handleClick(e) {
    if (e.target.closest("[data-collapse-toggle]")) {
      e.preventDefault();
      const expanded = this.el.getAttribute("aria-expanded") === "true";
      this.setExpanded(!expanded);
      localStorage.setItem(this.storageKey(), String(!expanded));
    }
  },

  setExpanded(expanded) {
    this.el.setAttribute("aria-expanded", String(expanded));
    const list = document.getElementById(this.el.dataset.controls);
    if (list) {
      list.hidden = !expanded;
    }
  },

  storageKey() {
    // Prefix with mount_path to avoid key collision across multiple admin mounts
    const mountEl = this.el.closest("[data-mount-path]");
    const mountPath = mountEl ? mountEl.dataset.mountPath : "/billing";
    return "ax-sidebar-" + mountPath + "-" + this.el.dataset.group;
  }
};
