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

function syncThemeButtonActiveState(activeTheme) {
  document.querySelectorAll("[data-theme-target]").forEach((candidate) => {
    candidate.classList.toggle("ax-theme-button-active", candidate.dataset.themeTarget === activeTheme);
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

export function initThemeControls() {
  document.addEventListener("click", onThemeTargetClick, true);
  const initial = document.documentElement.dataset.theme;
  if (initial) syncThemeButtonActiveState(sanitizeTheme(initial));
}
