(() => {
  const THEME_COOKIE = "accrue_theme";
  const ALLOWED_THEMES = new Set(["light", "dark", "system"]);

  const sanitizeTheme = (theme) => ALLOWED_THEMES.has(theme) ? theme : "system";

  const setThemePreference = (theme) => {
    const value = sanitizeTheme(theme);
    document.documentElement.dataset.theme = value;
    window.localStorage.setItem(THEME_COOKIE, value);
    document.cookie = `${THEME_COOKIE}=${encodeURIComponent(value)}; path=/; max-age=31536000; samesite=lax`;
    return value;
  };

  const initThemeControls = () => {
    document.querySelectorAll("[data-theme-target]").forEach((button) => {
      button.addEventListener("click", () => {
        const activeTheme = setThemePreference(button.dataset.themeTarget);

        document.querySelectorAll("[data-theme-target]").forEach((candidate) => {
          candidate.classList.toggle("ax-theme-button-active", candidate.dataset.themeTarget === activeTheme);
        });
      });
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initThemeControls, { once: true });
  } else {
    initThemeControls();
  }
})();
