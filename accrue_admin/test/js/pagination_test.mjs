import assert from "node:assert/strict";
import test from "node:test";
import { Pagination } from "../../assets/js/hooks/pagination.js";

function observerFixture(t) {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "IntersectionObserver");
  const state = { observations: [], disconnects: 0 };
  Object.defineProperty(globalThis, "IntersectionObserver", { configurable: true, value: class {
    constructor(callback, options) { state.notify = callback; state.options = options; }
    observe(element) { state.observations.push(element); }
    disconnect() { state.disconnects++; }
  }});
  t.after(() => {
    if (previous) Object.defineProperty(globalThis, "IntersectionObserver", previous);
    else delete globalThis.IntersectionObserver;
  });
  const boundary = {};
  const button = { disabled: false };
  const attributes = {};
  const calls = [];
  const hook = {
    el: {
      dataset: { paginationTarget: "7", paginationCursor: "first", paginationError: "false" },
      querySelector: (selector) => selector.includes("load-more") ? button : hook.boundary,
      setAttribute(name, value) { attributes[name] = value; },
      removeAttribute(name) { delete attributes[name]; }
    },
    boundary,
    pushEventTo(target, event, payload, callback) { calls.push({ target, event, payload, callback }); }
  };
  Pagination.mounted.call(hook);
  return { hook, state, attributes, calls, button };
}

test("automatic paging exposes progress, serializes requests, and re-arms short pages", (t) => {
  const { hook, state, attributes, calls, button } = observerFixture(t);
  assert.equal(hook.el.dataset.paginationAuto, "true");
  assert.equal(state.observations[0], hook.boundary);
  assert.equal(state.options.rootMargin, "0px 0px 160px 0px");
  state.notify([{ isIntersecting: false }]);
  assert.equal(calls.length, 0);
  state.notify([{ isIntersecting: true }]);
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 1);
  assert.equal(calls[0].target, 7);
  assert.equal(calls[0].event, "load-more");
  assert.deepEqual(calls[0].payload, {});
  assert.equal(hook.el.dataset.paginationLoading, "true");
  assert.equal(attributes["aria-busy"], "true");
  assert.equal(button.disabled, true);

  // LiveView applies the page before acknowledging the request.
  hook.el.dataset.paginationCursor = "second";
  Pagination.updated.call(hook);
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 1);
  calls[0].callback();
  assert.equal(hook.el.dataset.paginationLoading, "false");
  assert.equal(attributes["aria-busy"], undefined);
  assert.equal(button.disabled, false);
  assert.equal(state.observations.length, 2);
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 2);
  calls[1].callback();
  const observations = state.observations.length;
  delete hook.el.dataset.paginationAuto; // server patches do not own this flag
  Pagination.updated.call(hook); // unchanged polling patch
  assert.equal(hook.el.dataset.paginationAuto, "true");
  assert.equal(state.observations.length, observations);

  Pagination.destroyed.call(hook);
  const disconnects = state.disconnects;
  calls[1].callback(); // a late acknowledgement cannot revive a removed list
  assert.equal(state.disconnects, disconnects);
});

test("errors pause observation and explicit recovery resumes at the same cursor", (t) => {
  const { hook, state, calls } = observerFixture(t);
  state.notify([{ isIntersecting: true }]);
  hook.el.dataset.paginationError = "true";
  hook.boundary = null;
  Pagination.updated.call(hook);
  calls[0].callback();
  const observed = state.observations.length;
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 1);
  assert.equal(state.observations.length, observed);

  hook.el.dataset.paginationError = "false";
  hook.boundary = {};
  Pagination.updated.call(hook);
  assert.equal(state.observations.length, observed + 1);
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 2);
});

test("the final page and disconnected views cannot keep fetching", (t) => {
  const { hook, state, calls, attributes } = observerFixture(t);
  state.notify([{ isIntersecting: true }]);
  Pagination.disconnected.call(hook);
  assert.equal(hook.el.dataset.paginationLoading, "false");
  assert.equal(attributes["aria-busy"], undefined);
  const observations = state.observations.length;
  Pagination.reconnected.call(hook);
  assert.equal(state.observations.length, observations + 1);
  calls[0].callback();
  hook.el.dataset.paginationCursor = "";
  hook.boundary = null;
  Pagination.updated.call(hook);
  state.notify([{ isIntersecting: true }]);
  assert.equal(calls.length, 1);
});

test("browsers without observation retain the visible manual path without throwing", (t) => {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "IntersectionObserver");
  Object.defineProperty(globalThis, "IntersectionObserver", { configurable: true, value: undefined });
  t.after(() => {
    if (previous) Object.defineProperty(globalThis, "IntersectionObserver", previous);
    else delete globalThis.IntersectionObserver;
  });
  const hook = { el: { dataset: { paginationTarget: "7" } } };
  assert.doesNotThrow(() => Pagination.mounted.call(hook));
  assert.equal(hook.el.dataset.paginationAuto, undefined);
  assert.doesNotThrow(() => Pagination.updated.call(hook));
  assert.doesNotThrow(() => Pagination.destroyed.call(hook));
});
