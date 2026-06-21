// Registered LiveView hook for click-to-copy controls. Unlike initClipboardControls()
// (a one-shot binder run at first paint), each element with phx-hook="Clipboard" gets
// its own hook instance — so the binding survives DataTable row re-render on filter
// push_patch and rows appended on infinite-scroll load-more. LiveView re-mounts the
// hook on freshly-rendered elements.
export const Clipboard = {
  mounted() {
    this.el.addEventListener("click", async () => {
      const text = this.el.dataset.clipboardText || "";

      if (!navigator.clipboard?.writeText) {
        return;
      }

      await navigator.clipboard.writeText(text);
      this.el.dataset.copied = "true";
    });
  }
};

export function initClipboardControls() {
  document.querySelectorAll("[data-clipboard-text]").forEach((button) => {
    if (button.dataset.clipboardBound === "true") {
      return;
    }

    button.dataset.clipboardBound = "true";

    button.addEventListener("click", async () => {
      const text = button.dataset.clipboardText || "";

      if (!navigator.clipboard?.writeText) {
        return;
      }

      await navigator.clipboard.writeText(text);
      button.dataset.copied = "true";
    });
  });
}
