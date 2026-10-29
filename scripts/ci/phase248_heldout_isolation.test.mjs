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
      assert.equal(command, "mix");
      const script = args.join(" ");
      assert.ok([
        "run priv/repo/seeds/edge_states.exs",
        "run priv/repo/seeds/phase248_cleanup_edge.exs"
      ].includes(script));
      operations.push(script.includes("cleanup") ? "edge-cleanup" : "seed");
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
  assert.deepEqual(operations, ["sandbox-setup", "seed", "edge-cleanup", "teardown"]);
});

test("held-out setup cleans a partially written edge fixture when seeding fails", async () => {
  const operations = [];
  const setup = load("examples/accrue_host/e2e/phase248-heldout-setup.js", {
    PHASE248_PROOF_LANE: "heldout", ACCRUE_HOST_BROWSER_PORT: "4102"
  }, {
    "node:path": path,
    "node:child_process": { execFileSync: (_command, args) => {
      if (args[1] === "priv/repo/seeds/edge_states.exs") {
        operations.push("seed-failed");
        throw new Error("seed failed");
      }
      operations.push("edge-cleanup");
    } },
    "./global-setup.js": async () => {
      operations.push("sandbox-setup");
      return async () => operations.push("teardown");
    }
  });
  await assert.rejects(setup(), /seed failed/);
  assert.deepEqual(operations, ["sandbox-setup", "seed-failed", "edge-cleanup", "teardown"]);
});

test("held-out cleanup locks its customer before validating children and deleting rows", () => {
  const source = fs.readFileSync(
    path.join(repo, "examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs"),
    "utf8"
  );
  const lock = source.indexOf('lock: "FOR UPDATE"');
  const childGuard = source.indexOf("Phase 248 edge cleanup found an unrelated customer child");
  const firstDelete = source.indexOf("Repo.delete!(row)");

  assert.notEqual(lock, -1, "customer row must be locked against new FK children");
  assert.ok(lock < childGuard, "the lock must precede the child-set guard");
  assert.ok(childGuard < firstDelete, "all child checks must precede deletion");
});

test("held-out cleanup binds the exact customer ID to its expected synthetic owner", () => {
  const source = fs.readFileSync(
    path.join(repo, "examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs"),
    "utf8"
  );
  const ownerGuard = source.indexOf('customer.owner_id != "314e6b2c-fd88-45b9-85b4-2623f3dc35aa"');
  const firstDelete = source.indexOf("Repo.delete!(row)");

  assert.notEqual(ownerGuard, -1, "cleanup must verify the fixture's exact owner identity");
  assert.ok(ownerGuard < firstDelete, "owner validation must happen before deletion");
});
