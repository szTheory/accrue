import { Socket } from "../../deps/phoenix/priv/static/phoenix.mjs";
import { LiveSocket } from "../../deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js";
import { initClipboardControls, Clipboard } from "./hooks/clipboard";
import { initThemeControls } from "./hooks/accrue_theme";
import { initShellNav } from "./hooks/accrue_shell_nav";
import { initDropdowns } from "./hooks/dropdown";
import { CommandPalette } from "./hooks/command_palette";
import { ConnectionState } from "./hooks/connection_state";
import { FocusTrap } from "./hooks/focus_trap";
import { SidebarCollapse } from "./hooks/sidebar_collapse";
import topbar from "../vendor/topbar.js";

// Navigation loading bar. Runs at deferred-load time, after the runtime brand
// <style> has applied --ax-accent, so the accent read below is white-label live.
const accent =
  getComputedStyle(document.documentElement)
    .getPropertyValue("--ax-accent")
    .trim() || "#5D79F6";
topbar.config({
  barColors: { 0: accent },
  shadowColor: "rgba(0,0,0,.15)",
  barThickness: 2
});
const reduce = window.matchMedia("(prefers-reduced-motion: reduce)");
window.addEventListener("phx:page-loading-start", () =>
  topbar.show(reduce.matches ? 0 : 120)
);
window.addEventListener("phx:page-loading-stop", () => topbar.hide());

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
  initShellNav();
  initDropdowns();
});

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: csrfToken ? { _csrf_token: csrfToken } : {},
  hooks: { CommandPalette, ConnectionState, FocusTrap, SidebarCollapse, Clipboard }
});

liveSocket.connect();
window.liveSocket = liveSocket;
