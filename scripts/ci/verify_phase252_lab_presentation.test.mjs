import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";

test("lab presentation states disposable static limits", () => {
  const guide = fs.readFileSync(new URL("../../guides/ui-story-lab.md", import.meta.url), "utf8");
  assert.ok(/disposable.{0,4}non-production review lab/i.test(guide), "guide must identify a disposable non-production review lab");
});
