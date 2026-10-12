import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function load(relative, env, dependencies) {
  const filename = path.join(repo, relative);
  const module = { exports: {} };
  const require = (id) => {
    assert.ok(Object.hasOwn(dependencies, id), `unexpected dependency: ${id}`);
    return dependencies[id];
  };
  require.resolve = (id) => id;
  vm.runInNewContext(fs.readFileSync(filename, "utf8"), {
    module, require, process: { env }, __dirname: path.dirname(filename)
  }, { filename });
  return module.exports;
}

test("held-out config rejects disabled sandbox before shared lifecycle loads", () => {
  assert.throws(() => load("examples/accrue_host/playwright.phase248-heldout.config.js", {
    PHASE248_PROOF_LANE: "heldout", ACCRUE_HOST_BROWSER_PORT: "4102",
    ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX: "1"
  }, { "@playwright/test": { defineConfig: (config) => config } }), /require SQL sandbox isolation/);
});

test("held-out setup rejects disabled sandbox before any fixture operation", async () => {
  let operations = 0;
  const setup = load("examples/accrue_host/e2e/phase248-heldout-setup.js", {
    PHASE248_PROOF_LANE: "heldout", ACCRUE_HOST_BROWSER_PORT: "4102",
    ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX: "1"
  }, {
    "node:path": path,
    "node:child_process": { execFileSync: () => { operations++; } },
    "./global-setup.js": async () => { operations++; }
  });
  await assert.rejects(setup(), /requires SQL sandbox isolation/);
  assert.equal(operations, 0);
});

test("held-out setup retains sandbox fixture and teardown for the supported lane", async () => {
  const operations = [];
  const setup = load("examples/accrue_host/e2e/phase248-heldout-setup.js", {
    PHASE248_PROOF_LANE: "heldout", ACCRUE_HOST_BROWSER_PORT: "4102"
  }, {
    "node:path": path,
    "node:child_process": { execFileSync: (command, args, options) => {
      operations.push("seed");
      assert.equal(command, "mix");
      assert.equal(args.join(" "), "run priv/repo/seeds/edge_states.exs");
      assert.equal(options.env.MIX_ENV, "test");
      assert.notEqual(options.env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX, "1");
    } },
    "./global-setup.js": async () => {
      operations.push("sandbox-setup");
      return async () => operations.push("teardown");
    }
  });
  const teardown = await setup();
  await teardown();
  assert.deepEqual(operations, ["sandbox-setup", "seed", "teardown"]);
});
