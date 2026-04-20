/**
 * Mobile shell: Menu toggle opens/closes sidebar overlay via `ax-shell-nav-open` on
 * `document.documentElement`, matching `accrue_admin` CSS below the lg breakpoint.
 */

function onDocumentClick(event) {
  const toggle = event.target.closest("[data-sidebar-toggle='true']");
  if (toggle) {
    event.preventDefault();
    document.documentElement.classList.toggle("ax-shell-nav-open");
    return;
  }

  const navLink = event.target.closest(".ax-sidebar a.ax-sidebar-link");
  if (navLink && document.documentElement.classList.contains("ax-shell-nav-open")) {
    document.documentElement.classList.remove("ax-shell-nav-open");
  }
}

function onKeyDown(event) {
  if (event.key === "Escape" && document.documentElement.classList.contains("ax-shell-nav-open")) {
    document.documentElement.classList.remove("ax-shell-nav-open");
  }
}

export function initShellNav() {
  document.addEventListener("click", onDocumentClick, true);
  document.addEventListener("keydown", onKeyDown);
}
