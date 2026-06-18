import assert from "node:assert/strict";
import test from "node:test";

import { CommandPalette } from "../../assets/js/hooks/command_palette.js";

function withWindow(windowLike, callback) {
  const priorWindow = globalThis.window;
  globalThis.window = windowLike;

  try {
    callback();
  } finally {
    if (priorWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = priorWindow;
    }
  }
}

function item(dataset) {
  return {
    dataset,
    classList: { add() {}, remove() {} },
    scrollIntoView() {}
  };
}

test("Enter patches to the active command path with LiveSocket's argument order", () => {
  const patches = [];
  const pushedEvents = [];
  const activeItem = item({ path: "/billing/customers" });
  let prevented = false;

  const hook = {
    ...CommandPalette,
    activeIndex: 0,
    items: [activeItem],
    el: { dataset: { target: "#global-search" } },
    pushEventTo(...args) {
      pushedEvents.push(args);
    }
  };

  const event = {
    key: "Enter",
    preventDefault() {
      prevented = true;
    }
  };

  withWindow(
    {
      liveSocket: {
        pushHistoryPatch(...args) {
          patches.push(args);
        }
      }
    },
    () => hook.handleInputKeydown(event)
  );

  assert.equal(prevented, true);
  assert.deepEqual(pushedEvents, [["#global-search", "close", {}]]);
  assert.equal(patches.length, 1);
  assert.equal(patches[0][0], event);
  assert.equal(patches[0][1], "/billing/customers");
  assert.equal(patches[0][2], "push");
  assert.equal(patches[0][3], activeItem);
});
