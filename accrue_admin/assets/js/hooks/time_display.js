export function formatTimestamp(iso, { locale, timeZone } = {}) {
  if (typeof iso !== "string" || !iso || /^\d{4}-\d\d-\d\d$/.test(iso)) return null;

  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return null;

  try {
    const zone = timeZone || Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
    const text = new Intl.DateTimeFormat(locale, {
      year: "numeric", month: "short", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
      timeZone: zone, timeZoneName: "short"
    }).format(date);
    return { text, timeZone: zone };
  } catch {
    return null;
  }
}

export const TimeDisplay = {
  mounted() {
    this.renderTimestamp();
    this.onCopied = () => this.setStatus("Timestamp copied.");
    this.onCopyFailed = () => this.setStatus("Copy unavailable. Select the timestamp to copy it manually.");
    this.el.addEventListener("clipboard:copied", this.onCopied);
    this.el.addEventListener("clipboard:failed", this.onCopyFailed);
  },

  updated() {
    this.renderTimestamp();
  },

  destroyed() {
    this.el.removeEventListener("clipboard:copied", this.onCopied);
    this.el.removeEventListener("clipboard:failed", this.onCopyFailed);
  },

  renderTimestamp() {
    const time = this.el.querySelector("time");
    const result = formatTimestamp(this.el.dataset.iso);
    if (!time || !result) return;
    time.textContent = result.text;
    this.el.querySelector("[data-time-zone]").textContent = result.timeZone;
  },

  setStatus(message) {
    const status = this.el.querySelector("[data-time-copy-status]");
    if (status) status.textContent = message;
  }
};
