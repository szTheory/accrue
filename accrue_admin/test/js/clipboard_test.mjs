import assert from "node:assert/strict";
import test from "node:test";

import { Clipboard, initClipboardControls } from "../../assets/js/hooks/clipboard.js";

function withBrowser(t, { clipboard, button }) {
  const originals = {
    document: Object.getOwnPropertyDescriptor(globalThis, "document"),
    navigator: Object.getOwnPropertyDescriptor(globalThis, "navigator"),
    CustomEvent: Object.getOwnPropertyDescriptor(globalThis, "CustomEvent")
  };
  Object.defineProperty(globalThis, "document", { configurable: true, value: { querySelectorAll: () => [button] } });
  Object.defineProperty(globalThis, "navigator", { configurable: true, value: { clipboard } });
  Object.defineProperty(globalThis, "CustomEvent", {
    configurable: true,
    value: class CustomEvent {
      constructor(type, options = {}) { this.type = type; this.detail = options.detail; }
    }
  });
  t.after(() => {
    for (const [name, descriptor] of Object.entries(originals)) {
      if (descriptor) Object.defineProperty(globalThis, name, descriptor);
      else delete globalThis[name];
    }
  });
}

function button(text) {
  const listeners = new Map();
  const events = [];
  return {
    dataset: { clipboardText: text },
    listeners,
    events,
    addEventListener(type, listener) { listeners.set(type, listener); },
    removeEventListener(type) { listeners.delete(type); },
    dispatchEvent(event) { events.push(event); }
  };
}

test("visible toast waits for the real write and reports rejection without success", async (t) => {
  const target = button("record-123");
  target.dataset.clipboardLabel = "customer ID";
  let finishWrite;
  const clipboard = { writeText: () => new Promise((resolve) => { finishWrite = resolve; }) };
  withBrowser(t, { clipboard, button: target });
  let toast;
  let creations = 0;
  document.body = { append(node) { toast = node; creations++; } };
  document.querySelector = () => toast;
  document.createElement = () => ({ dataset: {}, setAttribute() {} });
  const timeout = globalThis.setTimeout;
  let hideToast;
  globalThis.setTimeout = (callback, duration) => {
    assert.equal(duration, 2500);
    hideToast = callback;
    return 0;
  };
  t.after(() => { globalThis.setTimeout = timeout; });

  const hook = { el: target };
  Clipboard.mounted.call(hook);
  const pending = target.listeners.get("click")();
  assert.equal(toast, undefined);
  finishWrite();
  await pending;
  assert.equal(toast.textContent, "Copied customer ID to clipboard");
  assert.equal(toast.hidden, false);
  assert.equal(toast.className, "ax-toast");
  assert.equal(toast.dataset.axToast, "true");

  clipboard.writeText = async () => { throw new Error("denied"); };
  await target.listeners.get("click")();
  assert.match(toast.textContent, /Could not copy/);
  assert.equal(creations, 1);
  hideToast();
  assert.equal(toast.hidden, true);
  assert.equal(target.dataset.copied, undefined);
  Clipboard.destroyed.call(hook);
});

test("shared hook and first-paint controls name the copied value without including its contents", async (t) => {
  const target = button("2026-10-11T15:04:05.123456Z");
  const written = [];
  withBrowser(t, { clipboard: { writeText: async (text) => written.push(text) }, button: target });
  let toast;
  let status;
  document.body = { append(node) { toast = node; } };
  document.querySelector = () => toast;
  document.createElement = () => ({ dataset: {}, setAttribute() {} });
  target.parentElement = { querySelector: () => status, append(node) { status = node; } };
  const timeout = globalThis.setTimeout;
  globalThis.setTimeout = () => 0;
  t.after(() => { globalThis.setTimeout = timeout; });

  const hook = { el: target };
  Clipboard.mounted.call(hook);
  for (const label of ["timestamp", "subscription ID", "event payload"]) {
    target.dataset.clipboardLabel = label;
    await target.listeners.get("click")();
    assert.equal(toast.textContent, `Copied ${label} to clipboard`);
    assert.equal(status.textContent, toast.textContent);
    assert.equal(written.at(-1), target.dataset.clipboardText);
  }
  Clipboard.destroyed.call(hook);

  initClipboardControls();
  target.dataset.clipboardLabel = "invoice ID";
  await target.listeners.get("click")();
  assert.equal(toast.textContent, "Copied invoice ID to clipboard");
  delete target.dataset.clipboardLabel;
  await target.listeners.get("click")();
  assert.equal(toast.textContent, "Copied text to clipboard");
});

test("first-paint controls report success only after a clipboard write resolves", async (t) => {
  const target = button("cus_123");
  withBrowser(t, { clipboard: { writeText: async () => {} }, button: target });
  initClipboardControls();

  await target.listeners.get("click")();
  assert.equal(target.events.at(-1).type, "clipboard:copied");
  assert.equal(target.dataset.copied, "true");
});

test("first-paint controls expose exact manual-copy text when clipboard is absent or rejects", async (t) => {
  const target = button("2026-10-11T15:04:05.123456Z");
  withBrowser(t, { clipboard: undefined, button: target });
  initClipboardControls();
  await target.listeners.get("click")();

  assert.equal(target.events.at(-1).type, "clipboard:failed");
  assert.equal(target.events.at(-1).detail.text, target.dataset.clipboardText);
  assert.equal(target.dataset.copied, undefined);

  const rejected = button("{\"id\":\"evt_123\"}");
  Object.defineProperty(globalThis, "document", { configurable: true, value: { querySelectorAll: () => [rejected] } });
  Object.defineProperty(globalThis, "navigator", { configurable: true, value: { clipboard: { writeText: async () => { throw new Error("denied"); } } } });
  initClipboardControls();
  await rejected.listeners.get("click")();
  assert.equal(rejected.events.at(-1).type, "clipboard:failed");
  assert.equal(rejected.events.at(-1).detail.text, rejected.dataset.clipboardText);
  assert.equal(rejected.dataset.copied, undefined);
});

test("mounted Clipboard hook reports a missing API and binds only one listener per mount", async (t) => {
  const target = button("cus_123");
  withBrowser(t, { clipboard: undefined, button: target });
  const hook = { el: target };

  Clipboard.mounted.call(hook);
  Clipboard.mounted.call(hook);
  assert.equal(target.listeners.size, 1);
  await target.listeners.get("click")();
  assert.equal(target.events.at(-1).type, "clipboard:failed");
  assert.equal(target.events.at(-1).detail.text, "cus_123");
});
