export const JsonViewerTabs = {
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
