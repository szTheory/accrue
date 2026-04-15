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

export function initThemeControls() {
  document.querySelectorAll("[data-theme-target]").forEach((button) => {
    button.addEventListener("click", () => {
      const activeTheme = setThemePreference(button.dataset.themeTarget);

      document.querySelectorAll("[data-theme-target]").forEach((candidate) => {
        candidate.classList.toggle("ax-theme-button-active", candidate.dataset.themeTarget === activeTheme);
      });
    });
  });
}
