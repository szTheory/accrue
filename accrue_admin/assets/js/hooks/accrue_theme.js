export const THEME_COOKIE = "accrue_theme";
export const ALLOWED_THEMES = new Set(["light", "dark", "system"]);

export function sanitizeTheme(theme) {
  return ALLOWED_THEMES.has(theme) ? theme : "system";
}

export function setThemePreference(theme) {
  const value = sanitizeTheme(theme);
  document.documentElement.dataset.theme = value;
  window.localStorage.setItem(THEME_COOKIE, value);
  document.cookie = `${THEME_COOKIE}=${encodeURIComponent(value)}; path=/; max-age=31536000; samesite=lax`;
  return value;
}

// Reflect the active theme onto the segmented control: active class, aria-checked,
// and roving tabindex (active = 0, others = -1) so the radiogroup has a single tab stop.
function syncThemeButtonActiveState(activeTheme) {
  document.querySelectorAll("[data-theme-target]").forEach((candidate) => {
    const isActive = candidate.dataset.themeTarget === activeTheme;
    candidate.classList.toggle("ax-theme-picker-option-active", isActive);
    candidate.setAttribute("aria-checked", String(isActive));
    candidate.setAttribute("tabindex", isActive ? "0" : "-1");
  });
}

/**
 * Delegated click handler so theme controls keep working after LiveView
 * replaces the topbar markup (per-button listeners would be lost).
 */
function onThemeTargetClick(event) {
  const button = event.target.closest("[data-theme-target]");
  if (!button) return;

  const raw = button.dataset.themeTarget;
  const activeTheme = setThemePreference(raw);
  syncThemeButtonActiveState(activeTheme);
}

const NEXT_KEYS = new Set(["ArrowRight", "ArrowDown"]);
const PREV_KEYS = new Set(["ArrowLeft", "ArrowUp"]);

/**
 * Roving-tabindex keyboard support for the radiogroup: arrow keys move to and
 * activate the adjacent segment; Home/End jump to the first/last. Delegated so it
 * survives LiveView re-renders.
 */
function onThemeTargetKeydown(event) {
  const current = event.target.closest("[data-theme-target]");
  if (!current) return;

  const group = current.closest('[role="radiogroup"]');
  if (!group) return;

  const options = Array.from(group.querySelectorAll("[data-theme-target]"));
  const index = options.indexOf(current);
  if (index === -1) return;

  let nextIndex = null;
  if (NEXT_KEYS.has(event.key)) nextIndex = (index + 1) % options.length;
  else if (PREV_KEYS.has(event.key)) nextIndex = (index - 1 + options.length) % options.length;
  else if (event.key === "Home") nextIndex = 0;
  else if (event.key === "End") nextIndex = options.length - 1;
  else return;

  event.preventDefault();
  const target = options[nextIndex];
  const activeTheme = setThemePreference(target.dataset.themeTarget);
  syncThemeButtonActiveState(activeTheme);
  target.focus();
}

export function initThemeControls() {
  document.addEventListener("click", onThemeTargetClick, true);
  document.addEventListener("keydown", onThemeTargetKeydown, true);
  const initial = document.documentElement.dataset.theme;
  if (initial) syncThemeButtonActiveState(sanitizeTheme(initial));
}
