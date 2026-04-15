import { Socket } from "../../deps/phoenix/priv/static/phoenix.mjs";
import { LiveSocket } from "../../deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js";
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

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: csrfToken ? { _csrf_token: csrfToken } : {}
});

liveSocket.connect();
window.liveSocket = liveSocket;
