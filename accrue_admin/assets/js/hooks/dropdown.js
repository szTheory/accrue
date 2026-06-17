// Native <details class="ax-dropdown"> menus only toggle when their <summary> is
// clicked, so they stay open when the user clicks elsewhere — surprising for a menu.
// These document-level listeners dismiss any open dropdown on outside-click or Escape,
// matching the least-surprise behavior expected of a menu component.
export function initDropdowns() {
  document.addEventListener("click", (event) => {
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      if (!details.contains(event.target)) {
        details.removeAttribute("open");
      }
    });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      details.removeAttribute("open");
      const summary = details.querySelector("summary");
      if (summary) summary.focus();
    });
  });
}
