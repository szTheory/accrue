/**
 * Mobile shell: Menu toggle opens/closes sidebar overlay via `ax-shell-nav-open` on
 * `document.documentElement`, matching `accrue_admin` CSS below the lg breakpoint.
 */

let lastToggle = null;

function closest(target, selector) {
  if (!target || typeof target.closest !== "function") return null;
  return target.closest(selector);
}

function navOpen() {
  return document.documentElement.classList.contains("ax-shell-nav-open");
}

function focusLastToggle() {
  if (lastToggle && lastToggle.isConnected && typeof lastToggle.focus === "function") {
    lastToggle.focus({ preventScroll: true });
  }
}

function closeNav({ restoreFocus = false } = {}) {
  document.documentElement.classList.remove("ax-shell-nav-open");

  if (restoreFocus) {
    focusLastToggle();
  }
}

function openNav(toggle) {
  lastToggle = toggle;
  document.documentElement.classList.add("ax-shell-nav-open");
}

function onDocumentClick(event) {
  const toggle = closest(event.target, "[data-sidebar-toggle='true']");
  if (toggle) {
    event.preventDefault();
    if (navOpen()) {
      closeNav({ restoreFocus: true });
    } else {
      openNav(toggle);
    }
    return;
  }

  if (!navOpen()) return;

  const navLink = closest(event.target, ".ax-sidebar a.ax-sidebar-link");
  if (navLink) {
    closeNav();
    return;
  }

  const sidebar = closest(event.target, ".ax-sidebar");
  if (!sidebar) {
    closeNav({ restoreFocus: true });
  }
}

function onKeyDown(event) {
  if (event.key === "Escape" && navOpen()) {
    event.preventDefault();
    closeNav({ restoreFocus: true });
  }
}

export function initShellNav() {
  document.addEventListener("click", onDocumentClick, true);
  document.addEventListener("keydown", onKeyDown);
}
