const DROPDOWN_SELECTOR = "details.ax-dropdown";
const OPEN_DROPDOWN_SELECTOR = `${DROPDOWN_SELECTOR}[open]`;
const PANEL_SELECTOR = ".ax-dropdown-panel";
const VIEWPORT_MARGIN = 8;
const PANEL_GAP = 8;

function focusSummary(details) {
  const summary = details.querySelector("summary");
  if (summary && typeof summary.focus === "function") {
    summary.focus({ preventScroll: true });
  }
}

function cssPx(value) {
  return `${Math.round(value)}px`;
}

function resetDropdownPosition(details) {
  const panel = details.querySelector(PANEL_SELECTOR);
  if (details.dataset) delete details.dataset.floatingPlacement;

  if (!panel?.style) return;

  panel.style.removeProperty("--ax-dropdown-shift-x");
  panel.style.removeProperty("--ax-dropdown-origin-x");
  panel.style.removeProperty("--ax-dropdown-origin-y");
  panel.style.removeProperty("--ax-dropdown-max-height");
}

function dropdownViewport() {
  const fallback = globalThis.document?.documentElement;

  return {
    width: globalThis.window?.innerWidth || fallback?.clientWidth || 1024,
    height: globalThis.window?.innerHeight || fallback?.clientHeight || 768
  };
}

function positionDropdown(details) {
  if (!details?.open) {
    resetDropdownPosition(details);
    return;
  }

  const summary = details.querySelector("summary");
  const panel = details.querySelector(PANEL_SELECTOR);
  if (!summary?.getBoundingClientRect || !panel?.getBoundingClientRect || !panel.style) return;

  panel.style.removeProperty("--ax-dropdown-shift-x");

  const viewport = dropdownViewport();
  const triggerRect = summary.getBoundingClientRect();
  const naturalPanelRect = panel.getBoundingClientRect();
  const spaceBelow = viewport.height - triggerRect.bottom - VIEWPORT_MARGIN - PANEL_GAP;
  const spaceAbove = triggerRect.top - VIEWPORT_MARGIN - PANEL_GAP;
  const shouldPlaceAbove =
    triggerRect.bottom + PANEL_GAP + naturalPanelRect.height > viewport.height - VIEWPORT_MARGIN &&
    spaceAbove > spaceBelow;
  const placement = shouldPlaceAbove ? "top" : "bottom";
  const availableHeight = Math.max(96, Math.floor(placement === "top" ? spaceAbove : spaceBelow));

  if (details.dataset) details.dataset.floatingPlacement = placement;
  panel.style.setProperty("--ax-dropdown-max-height", cssPx(availableHeight));

  const placedPanelRect = panel.getBoundingClientRect();
  let shiftX = 0;

  if (placedPanelRect.left < VIEWPORT_MARGIN) {
    shiftX = VIEWPORT_MARGIN - placedPanelRect.left;
  } else if (placedPanelRect.right > viewport.width - VIEWPORT_MARGIN) {
    shiftX = viewport.width - VIEWPORT_MARGIN - placedPanelRect.right;
  }

  panel.style.setProperty("--ax-dropdown-shift-x", cssPx(shiftX));

  const finalLeft = placedPanelRect.left + shiftX;
  const triggerCenter = triggerRect.left + triggerRect.width / 2;
  const originX = Math.min(
    placedPanelRect.width,
    Math.max(0, triggerCenter - finalLeft)
  );
  const originY = placement === "top" ? "bottom" : "top";

  panel.style.setProperty("--ax-dropdown-origin-x", cssPx(originX));
  panel.style.setProperty("--ax-dropdown-origin-y", originY);
}

function positionOpenDropdowns() {
  document.querySelectorAll(OPEN_DROPDOWN_SELECTOR).forEach(positionDropdown);
}

function schedulePositionOpenDropdowns() {
  if (typeof globalThis.window?.requestAnimationFrame === "function") {
    globalThis.window.requestAnimationFrame(positionOpenDropdowns);
  } else {
    positionOpenDropdowns();
  }
}

function closeDropdown(details, { restoreFocus = false } = {}) {
  details.removeAttribute("open");
  resetDropdownPosition(details);

  if (restoreFocus) {
    focusSummary(details);
  }
}

function isDropdownDetails(element) {
  if (!element) return false;
  if (typeof element.matches === "function") return element.matches(DROPDOWN_SELECTOR);
  return Boolean(element.querySelector?.(PANEL_SELECTOR));
}

// Native <details class="ax-dropdown"> menus only toggle when their <summary> is
// clicked, so they stay open when the user clicks elsewhere. These document-level
// listeners dismiss any open dropdown on outside-click or Escape. Escape restores
// focus to the disclosure trigger; pointer outside-click lets the clicked control
// keep focus normally.
export function initDropdowns() {
  document.addEventListener(
    "click",
    (event) => {
      document.querySelectorAll(OPEN_DROPDOWN_SELECTOR).forEach((details) => {
        if (!details.contains(event.target)) {
          closeDropdown(details, { restoreFocus: false });
        }
      });
      schedulePositionOpenDropdowns();
    },
    true
  );

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    document.querySelectorAll(OPEN_DROPDOWN_SELECTOR).forEach((details) => {
      closeDropdown(details, { restoreFocus: true });
    });
  });

  document.addEventListener(
    "toggle",
    (event) => {
      if (!isDropdownDetails(event.target)) return;

      if (event.target.open) {
        schedulePositionOpenDropdowns();
      } else {
        resetDropdownPosition(event.target);
      }
    },
    true
  );

  if (typeof globalThis.window?.addEventListener === "function") {
    globalThis.window.addEventListener("resize", schedulePositionOpenDropdowns);
  }
}
