function focusSummary(details) {
  const summary = details.querySelector("summary");
  if (summary && typeof summary.focus === "function") {
    summary.focus({ preventScroll: true });
  }
}

function closeDropdown(details, { restoreFocus = false } = {}) {
  details.removeAttribute("open");

  if (restoreFocus) {
    focusSummary(details);
  }
}

// Native <details class="ax-dropdown"> menus only toggle when their <summary> is
// clicked, so they stay open when the user clicks elsewhere. These document-level
// listeners dismiss any open dropdown on outside-click or Escape and restore focus
// to the disclosure trigger, matching the expected menu control loop.
export function initDropdowns() {
  document.addEventListener("click", (event) => {
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      if (!details.contains(event.target)) {
        closeDropdown(details, { restoreFocus: true });
      }
    });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    document.querySelectorAll("details.ax-dropdown[open]").forEach((details) => {
      closeDropdown(details, { restoreFocus: true });
    });
  });
}
