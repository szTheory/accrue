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
