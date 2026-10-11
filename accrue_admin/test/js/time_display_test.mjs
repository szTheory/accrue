import assert from "node:assert/strict";
import test from "node:test";

import { formatTimestamp, TimeDisplay } from "../../assets/js/hooks/time_display.js";
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
  assert.equal(formatTimestamp("2026-10-11"), null);
  assert.equal(formatTimestamp(null), null);
});

test("hook formats a mounted timestamp and removes status listeners on destroy", () => {
  const listeners = new Map();
  const time = { textContent: "UTC initial" };
  const zone = { textContent: "UTC" };
  const status = { textContent: "" };
  const el = {
    dataset: { iso: "2026-10-11T15:04:05.123456Z" },
    querySelector(selector) {
      if (selector === "time") return time;
      if (selector === "[data-time-zone]") return zone;
      if (selector === "[data-time-copy-status]") return status;
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
  assert.equal(status.textContent, `Clipboard unavailable. Select and copy: ${el.dataset.iso}`);
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
