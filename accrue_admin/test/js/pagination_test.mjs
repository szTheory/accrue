import assert from "node:assert/strict";
import test from "node:test";
import { Pagination } from "../../assets/js/hooks/pagination.js";

test("visible boundaries request one page at a time and release their observer on removal", (t) => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "IntersectionObserver");
  let notify;
  let observed;
  let disconnected = false;
  Object.defineProperty(globalThis, "IntersectionObserver", { configurable: true, value: class {
    constructor(callback) { notify = callback; }
    observe(element) { observed = element; }
    disconnect() { disconnected = true; }
  }});
  t.after(() => {
    if (previous) Object.defineProperty(globalThis, "IntersectionObserver", previous);
    else delete globalThis.IntersectionObserver;
  });

  const calls = [];
  const hook = {
    el: { dataset: { paginationTarget: "7" } },
    pushEventTo(target, event, payload, callback) { calls.push({ target, event, payload, callback }); }
  };
  Pagination.mounted.call(hook);
  assert.equal(observed, hook.el);
  notify([{ isIntersecting: false }]);
  assert.equal(calls.length, 0);
  notify([{ isIntersecting: true }]);
  notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].target, 7);
  assert.equal(calls[0].event, "load-more");
  assert.deepEqual(calls[0].payload, {});
  calls[0].callback();
  notify([{ isIntersecting: false }]);
  notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 2);
  Pagination.destroyed.call(hook);
  assert.equal(disconnected, true);
});

test("browsers without observation retain the manual paging path without throwing", (t) => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "IntersectionObserver");
  Object.defineProperty(globalThis, "IntersectionObserver", { configurable: true, value: undefined });
  t.after(() => {
    if (previous) Object.defineProperty(globalThis, "IntersectionObserver", previous);
    else delete globalThis.IntersectionObserver;
  });
  const hook = { el: { dataset: { paginationTarget: "7" } } };
  assert.doesNotThrow(() => Pagination.mounted.call(hook));
  assert.doesNotThrow(() => Pagination.destroyed.call(hook));
});
