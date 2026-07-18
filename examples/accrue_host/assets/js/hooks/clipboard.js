// Registered LiveView hook for the demo login page's click-to-copy credential
// chips. Ported from accrue_admin's Clipboard hook, with two additions: a
// transient `data-copied` flag that swaps the chip's icon (copy -> check) for a
// beat, and an ephemeral toast surfaced via #copy-toast-root. Each element with
// phx-hook="Clipboard" gets its own instance, so bindings survive re-render.
export const Clipboard = {
  mounted() {
    this.onClick = async () => {
      const text = this.el.dataset.clipboardText || "";

      if (!navigator.clipboard?.writeText) {
        return;
      }

      try {
        await navigator.clipboard.writeText(text);
      } catch {
        return;
      }

      this.el.dataset.copied = "true";
      clearTimeout(this.copiedTimer);
      this.copiedTimer = setTimeout(() => {
        delete this.el.dataset.copied;
      }, 1200);

      showCopyToast(this.el.dataset.copyLabel || "value");
    };

    this.el.addEventListener("click", this.onClick);
  },

  destroyed() {
    clearTimeout(this.copiedTimer);

    if (this.onClick) {
      this.el.removeEventListener("click", this.onClick);
    }
  }
};

// Clone the hidden #copy-toast-template, fill in the label, and drop it into the
// fixed #copy-toast-root. The root is position:fixed (daisyUI `toast`), so this
// never reflows the page. Auto-dismisses with a fade/slide after ~1.6s.
function showCopyToast(label) {
  const root = document.getElementById("copy-toast-root");
  const template = document.getElementById("copy-toast-template");

  if (!root || !template) {
    return;
  }

  const node = template.content.firstElementChild.cloneNode(true);
  const labelEl = node.querySelector("[data-copy-toast-label]");

  if (labelEl) {
    labelEl.textContent = `Copied ${label}`;
  }

  root.appendChild(node);

  setTimeout(() => {
    node.dataset.leaving = "true";
    setTimeout(() => node.remove(), 200);
  }, 1600);
}
