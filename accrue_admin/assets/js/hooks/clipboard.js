let toastTimeout;

function showToast(message) {
  if (typeof document === "undefined" || !document.body) return;
  let toast = document.querySelector("[data-clipboard-toast]");
  if (!toast) {
    toast = document.createElement("div");
    toast.dataset.clipboardToast = "true";
    toast.className = "ax-clipboard-toast";
    toast.setAttribute("role", "status");
    document.body.append(toast);
  }
  clearTimeout(toastTimeout);
  toast.textContent = message;
  toast.hidden = false;
  toastTimeout = setTimeout(() => { toast.hidden = true; }, 2500);
}

// Registered LiveView hook for click-to-copy controls. Each mounted node owns
// one handler, so controls added by LiveView patches keep their behavior.
function announce(button, message) {
  const parent = button.parentElement;
  if (!parent || typeof document === "undefined") return;
  let status = parent.querySelector("[data-clipboard-feedback]");
  if (!status) {
    status = document.createElement("span");
    status.dataset.clipboardFeedback = "true";
    status.className = "ax-visually-hidden";
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    parent.append(status);
  }
  status.textContent = message;
}

function dispatch(button, type, text) {
  if (type === "clipboard:copied") {
    button.dataset.copied = "true";
    announce(button, "Copied to clipboard.");
    showToast("Copied to clipboard");
    button.dispatchEvent(new CustomEvent(type, { bubbles: true }));
    return;
  }

  delete button.dataset.copied;
  showToast("Could not copy. Select the text to copy it manually.");
  announce(button, `Clipboard unavailable. Select and copy the text manually: ${text}`);
  button.dispatchEvent(new CustomEvent(type, { bubbles: true, detail: { text } }));
}

export const Clipboard = {
  mounted() {
    if (this.clipboardClickHandler) return;
    this.clipboardClickHandler = async () => {
      const text = this.el.dataset.clipboardText || "";
      if (!navigator.clipboard?.writeText) {
        dispatch(this.el, "clipboard:failed", text);
        return;
      }
      try {
        await navigator.clipboard.writeText(text);
        dispatch(this.el, "clipboard:copied", text);
      } catch {
        dispatch(this.el, "clipboard:failed", text);
      }
    };
    this.el.addEventListener("click", this.clipboardClickHandler);
  },

  destroyed() {
    if (this.clipboardClickHandler) {
      this.el.removeEventListener("click", this.clipboardClickHandler);
      this.clipboardClickHandler = null;
    }
  }
};

export function initClipboardControls() {
  document.querySelectorAll('[data-clipboard-text]:not([phx-hook="Clipboard"])').forEach((button) => {
    if (button.dataset.clipboardBound === "true") return;
    button.dataset.clipboardBound = "true";

    button.addEventListener("click", async () => {
      const text = button.dataset.clipboardText || "";
      if (!navigator.clipboard?.writeText) {
        dispatch(button, "clipboard:failed", text);
        return;
      }
      try {
        await navigator.clipboard.writeText(text);
        dispatch(button, "clipboard:copied", text);
      } catch {
        dispatch(button, "clipboard:failed", text);
      }
    });
  });
}
