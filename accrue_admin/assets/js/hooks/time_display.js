export const TIME_DISPLAY_KEY = "accrue_admin_time_display";
let activePreference = null;
let initializedDocument = null;

export function formatTimestamp(iso, { locale, timeZone, mode } = {}) {
  if (typeof iso !== "string") return null;
  const parts = iso.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(Z|[+-]\d{2}:\d{2})$/);
  if (!parts) return null;

  const [, year, month, day, hour, minute, second, offset] = parts;
  const daysInMonth = [31, Number(year) % 4 === 0 && (Number(year) % 100 !== 0 || Number(year) % 400 === 0) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][Number(month) - 1];
  if (!daysInMonth || Number(day) < 1 || Number(day) > daysInMonth) return null;
  if (Number(hour) > 23 || Number(minute) > 59 || Number(second) > 59) return null;
  if (offset !== "Z" && (Number(offset.slice(1, 3)) > 23 || Number(offset.slice(4, 6)) > 59)) return null;

  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return null;

  try {
    const zone = timeZone || (mode === "utc" ? "UTC" : null) || Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
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

function selectedMode() {
  return activePreference || "local";
}

function renderAllTimestamps(documentRef) {
  documentRef.querySelectorAll("[data-time-display]").forEach((element) => renderTimestampElement(element));
}

function renderTimestampElement(element) {
  const time = element.querySelector("time");
  const result = formatTimestamp(element.dataset.iso, { mode: selectedMode() });
  if (!time || !result) return;
  time.textContent = result.text;
  const zone = element.querySelector("[data-time-zone]");
  if (zone) zone.textContent = result.timeZone;
}

function syncPreferenceControls(documentRef) {
  documentRef.querySelectorAll("[data-time-preference]").forEach((control) => {
    control.value = selectedMode();
  });
}

export function initTimeDisplayPreference(documentRef = document, windowRef = window) {
  if (initializedDocument !== documentRef) {
    try {
      const stored = windowRef.localStorage.getItem(TIME_DISPLAY_KEY);
      activePreference = stored === "local" || stored === "utc" ? stored : "local";
    } catch {
      activePreference = "utc";
    }

    documentRef.addEventListener("change", (event) => {
      if (event.target?.matches?.("[data-time-preference]")) {
        setTimeDisplayPreference(event.target.value, documentRef, windowRef);
      }
    });

    if (typeof MutationObserver !== "undefined" && documentRef.documentElement) {
      const observer = new MutationObserver(() => syncPreferenceControls(documentRef));
      observer.observe(documentRef.documentElement, { childList: true, subtree: true });
    }
    initializedDocument = documentRef;
  }

  syncPreferenceControls(documentRef);
  renderAllTimestamps(documentRef);
  return selectedMode();
}

export function setTimeDisplayPreference(mode, documentRef = document, windowRef = window) {
  activePreference = mode === "utc" ? "utc" : "local";
  try {
    windowRef.localStorage.setItem(TIME_DISPLAY_KEY, activePreference);
  } catch {
    // Keep the in-memory choice available for the current page session.
  }
  syncPreferenceControls(documentRef);
  renderAllTimestamps(documentRef);
  return activePreference;
}

export const TimeDisplay = {
  mounted() {
    this.renderTimestamp();
    this.onCopied = () => {
      this.setStatus("Timestamp copied.");
      this.setCopyFallback("");
    };
    this.onCopyFailed = (event) => {
      const text = event.detail?.text;
      this.setStatus("Clipboard unavailable. Select and copy the UTC timestamp below.");
      this.setCopyFallback(text || "Timestamp unavailable for manual copy.");
    };
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
    renderTimestampElement(this.el);
  },

  setStatus(message) {
    const status = this.el.querySelector("[data-time-copy-status]");
    if (status) status.textContent = message;
  },

  setCopyFallback(text) {
    const fallback = this.el.querySelector("[data-time-copy-fallback]");
    if (!fallback) return;
    fallback.textContent = text;
    fallback.hidden = text.length === 0;
  }
};
