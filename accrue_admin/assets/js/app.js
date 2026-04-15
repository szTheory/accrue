import { initClipboardControls } from "./hooks/clipboard";
import { initThemeControls } from "./hooks/accrue_theme";

function ready(callback) {
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", callback, { once: true });
  } else {
    callback();
  }
}

ready(() => {
  initClipboardControls();
  initThemeControls();
});
