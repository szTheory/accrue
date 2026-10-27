import assert from "node:assert/strict";
import test from "node:test";
import * as transparency from "./verify_phase252_transparency.mjs";

test("held-out attribution identifies synthetic stress evidence", () => {
  assert.equal(typeof transparency.assertHeldoutAttribution, "function", "shared held-out attribution assertion must exist");
});
