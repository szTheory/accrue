import assert from "node:assert/strict";
import test from "node:test";

import { formatTimestamp, initTimeDisplayPreference, setTimeDisplayPreference, TimeDisplay } from "../../assets/js/hooks/time_display.js";
import { Clipboard } from "../../assets/js/hooks/clipboard.js";

test("formats instants in an explicit browser timezone without altering the source ISO", () => {
  const iso = "2026-10-11T15:04:05.123456Z";
  const formatted = formatTimestamp(iso, { locale: "en-US", timeZone: "America/Los_Angeles" });
  assert.equal(formatted.timeZone, "America/Los_Angeles");
  assert.match(formatted.text, /08:04:05/);
  assert.equal(iso, "2026-10-11T15:04:05.123456Z");
});

test("invalid values and date-only strings are excluded", () => {
  assert.equal(formatTimestamp("not a date"), null);
  assert.equal(formatTimestamp("2026-02-30T12:00:00Z"), null);
  assert.equal(formatTimestamp("2026-10-11T25:04:05Z"), null);
  assert.equal(formatTimestamp("2026-10-11"), null);
  assert.equal(formatTimestamp(null), null);
});

test("shared preference persists Local and UTC and renders the active mode", () => {
  const values = new Map();
  const control = { value: "local" };
  const time = { textContent: "UTC initial" };
  const zone = { textContent: "UTC" };
  const node = { dataset: { iso: "2026-10-11T15:04:05Z" }, querySelector: (selector) => selector === "time" ? time : zone };
  const doc = {
    querySelectorAll: (selector) => selector === "[data-time-preference]" ? [control] : [node],
    addEventListener() {}
  };
  const win = { localStorage: { getItem: (key) => values.get(key) ?? null, setItem: (key, value) => values.set(key, value) } };

  assert.equal(initTimeDisplayPreference(doc, win), "local");
  assert.equal(setTimeDisplayPreference("utc", doc, win), "utc");
  assert.equal(values.get("accrue_admin_time_display"), "utc");
  assert.equal(control.value, "utc");
  assert.equal(zone.textContent, "UTC");
});

test("storage failures keep a session choice and default unreadable preference to UTC", () => {
  const control = { value: "local" };
  const time = { textContent: "UTC initial" };
  const zone = { textContent: "UTC" };
  const node = { dataset: { iso: "2026-10-11T15:04:05Z" }, querySelector: (selector) => selector === "time" ? time : zone };
  const doc = { querySelectorAll: (selector) => selector === "[data-time-preference]" ? [control] : [node], addEventListener() {} };
  const win = { localStorage: { getItem() { throw new Error("blocked"); }, setItem() { throw new Error("blocked"); } } };

  assert.equal(initTimeDisplayPreference(doc, win), "utc");
  assert.equal(setTimeDisplayPreference("local", doc, win), "local");
  assert.equal(control.value, "local");
  assert.notEqual(time.textContent, "UTC initial");
});

test("hook formats a mounted timestamp and removes status listeners on destroy", () => {
  const listeners = new Map();
  const time = { textContent: "UTC initial" };
  const zone = { textContent: "UTC" };
  const status = { textContent: "" };
  const fallback = { textContent: "", hidden: true };
  const el = {
    dataset: { iso: "2026-10-11T15:04:05.123456Z" },
    querySelector(selector) {
      if (selector === "time") return time;
      if (selector === "[data-time-zone]") return zone;
      if (selector === "[data-time-copy-status]") return status;
      if (selector === "[data-time-copy-fallback]") return fallback;
      return null;
    },
    addEventListener(type, listener) { listeners.set(type, listener); },
    removeEventListener(type) { listeners.delete(type); }
  };
  const hook = { ...TimeDisplay, el };

  hook.mounted();
  assert.notEqual(time.textContent, "UTC initial");
  assert.notEqual(zone.textContent, "UTC");
  listeners.get("clipboard:copied")();
  assert.equal(status.textContent, "Timestamp copied.");
  listeners.get("clipboard:failed")({ detail: { text: el.dataset.iso } });
  assert.equal(status.textContent, "Clipboard unavailable. Select and copy the UTC timestamp below.");
  assert.equal(fallback.textContent, el.dataset.iso);
  assert.equal(fallback.hidden, false);
  listeners.get("clipboard:copied")();
  assert.equal(fallback.hidden, true);
  hook.destroyed();
  assert.equal(listeners.size, 0);
});

test("copy failure provides the exact original value for manual copy", () => {
  const status = { textContent: "" };
  TimeDisplay.setStatus.call({ el: { querySelector: () => status } }, "Clipboard unavailable. Select and copy: 2026-10-11T15:04:05.123456Z");
  assert.equal(status.textContent, "Clipboard unavailable. Select and copy: 2026-10-11T15:04:05.123456Z");
});

test("Clipboard failure event carries the untouched ISO value", async () => {
  const priorNavigator = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  const listeners = new Map();
  const events = [];
  const iso = "2026-10-11T15:04:05.123456Z";
  const el = {
    dataset: { clipboardText: iso },
    addEventListener(type, listener) { listeners.set(type, listener); },
    dispatchEvent(event) { events.push(event); }
  };
  Object.defineProperty(globalThis, "navigator", {
    configurable: true,
    value: { clipboard: { writeText: async () => { throw new Error("denied"); } } }
  });

  try {
    Clipboard.mounted.call({ el });
    await listeners.get("click")();
    assert.equal(events.at(-1).type, "clipboard:failed");
    assert.equal(events.at(-1).detail.text, iso);
    assert.equal(el.dataset.copied, undefined);
  } finally {
    if (priorNavigator) Object.defineProperty(globalThis, "navigator", priorNavigator);
    else delete globalThis.navigator;
  }
});
