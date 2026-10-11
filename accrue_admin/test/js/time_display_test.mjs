import assert from "node:assert/strict";
import test from "node:test";

import { formatTimestamp, TimeDisplay } from "../../assets/js/hooks/time_display.js";

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
  hook.destroyed();
  assert.equal(listeners.size, 0);
});

test("copy failure provides a manual-copy instruction", () => {
  const status = { textContent: "" };
  TimeDisplay.setStatus.call({ el: { querySelector: () => status } }, "Copy unavailable. Select the timestamp to copy it manually.");
  assert.match(status.textContent, /manually/);
});
