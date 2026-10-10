import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const custody = path.join(repoRoot, "scripts/ci/accrue_host_preview_custody.sh");
const browserWrapper = path.join(repoRoot, "scripts/ci/accrue_host_verify_browser.sh");
const devWrapper = path.join(repoRoot, "scripts/ci/accrue_host_verify_dev_boot.sh");

function fixture(overrides = {}) {
  return {
    preview: {
      databaseHost: "db",
      database: "accrue_host_dev",
      connection: "postgres://preview/db/accrue_host_dev",
      databaseInstance: "docker-volume:accrue-host_pgdata",
      composeProject: "accrue-host",
      volume: "accrue-host_pgdata",
      port: 4000,
      process: "container:preview-web",
      databaseProcess: "container:preview-db",
      buildPath: "/workspace/examples/accrue_host/_build"
    },
    target: {
      databaseHost: "localhost",
      database: "accrue_host_test",
      connection: "postgres://localhost/accrue_host_test",
      databaseInstance: "postgres-system:proof-71",
      composeProject: "accrue-host-proof-71",
      volume: "accrue-host-proof-71_pgdata",
      port: 47101,
      process: "unoccupied",
      databaseProcess: "pid:5432-proof",
      buildPath: "/private/tmp/accrue-host-proof-71/_build"
    },
    ...overrides
  };
}

function run(mode, data, extraEnv = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-custody-test-"));
  const fixturePath = path.join(dir, "targets.json");
  fs.writeFileSync(fixturePath, JSON.stringify(data));
  const result = spawnSync("node", [custody, "preflight", mode], {
    cwd: repoRoot,
    encoding: "utf8",
    env: {
      ...process.env,
      ACCRUE_HOST_CUSTODY_TEST_FIXTURE: fixturePath,
      ACCRUE_HOST_CUSTODY_TEST_MODE: "1",
      ...extraEnv
    }
  });
  fs.rmSync(dir, { recursive: true, force: true });
  return result;
}

test("accepts a fully identified disposable browser target", () => {
  const result = run("browser", fixture());
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /database=accrue_host_test/);
});

test("accepts the dedicated dev-boot database and rejects the historical preview DB", () => {
  assert.equal(run("dev", fixture()).status, 0);
  const collision = fixture();
  collision.target.database = "accrue_host_dev";
  assert.notEqual(run("dev", collision).status, 0);
});

test("rejects every preview identity alias, including the connection and build path", () => {
  const preview = fixture().preview;
  for (const key of Object.keys(preview)) {
    const result = run("browser", fixture({ target: { ...fixture().target, [key]: preview[key] } }));
    assert.notEqual(result.status, 0, `accepted aliased ${key}`);
  }
});

test("rejects unknown target identity and occupied listener before mutation", () => {
  const unknown = fixture();
  delete unknown.target.connection;
  assert.notEqual(run("browser", unknown).status, 0);

  const occupied = fixture();
  occupied.target.process = "pid:4321";
  assert.notEqual(run("browser", occupied).status, 0);
});

test("rejects loopback host aliases and does not report DATABASE_URL credentials", () => {
  const data = fixture();
  data.preview.databaseHost = "localhost";
  data.preview.connection = "loopback:5432/accrue_host_dev";
  data.target.databaseHost = "127.0.0.1";
  const result = run("browser", data, { DATABASE_URL: "postgres://private-user:private-password@example.invalid/other" });
  assert.notEqual(result.status, 0);
  assert.doesNotMatch(`${result.stdout}\n${result.stderr}`, /private-user|private-password|example\.invalid/);
});

test("both wrappers invoke custody before database mutation and dev uses its isolated database", () => {
  for (const wrapper of [browserWrapper, devWrapper]) {
    const source = fs.readFileSync(wrapper, "utf8");
    const guard = source.indexOf("accrue_host_preview_custody.sh");
    const mutation = source.search(/mix ecto\.(drop|create|migrate)/);
    assert.ok(guard >= 0 && guard < mutation, `${wrapper} does not guard before DB mutation`);
  }
  const dev = fs.readFileSync(path.join(repoRoot, "examples/accrue_host/config/dev.exs"), "utf8");
  assert.match(dev, /ACCRUE_HOST_DEV_BOOT_DATABASE/);
});

test("both verifier wrappers snapshot the preview before work and assert preservation during cleanup", () => {
  for (const wrapper of [browserWrapper, devWrapper]) {
    const source = fs.readFileSync(wrapper, "utf8");
    const preflight = source.indexOf('node "$custody_tool" preflight');
    const snapshot = source.indexOf('node "$custody_tool" snapshot');
    const cleanup = source.indexOf("cleanup() {");
    const assertion = source.indexOf("assert-preserved");
    assert.ok(preflight >= 0 && snapshot > preflight, `${wrapper} does not capture preview state after preflight`);
    assert.ok(cleanup >= 0 && assertion > cleanup, `${wrapper} does not compare preview state during cleanup`);
  }
  const custodySource = fs.readFileSync(custody, "utf8");
  assert.match(custodySource, /seeded invoice sentinel is missing/);
  assert.match(custodySource, /showcase audit event is missing/);
  assert.match(custodySource, /assert-preserved/);
});

test("direct Playwright config and setup both preflight before server or fixture work", () => {
  const config = fs.readFileSync(path.join(repoRoot, "examples/accrue_host/playwright.config.js"), "utf8");
  const setup = fs.readFileSync(path.join(repoRoot, "examples/accrue_host/e2e/global-setup.js"), "utf8");
  assert.match(config, /accrue_host_preview_custody\.sh/);
  assert.match(setup, /accrue_host_preview_custody\.sh/);
  assert.ok(config.indexOf("accrue_host_preview_custody.sh") < config.indexOf("webServer:"));
  assert.ok(setup.indexOf("accrue_host_preview_custody.sh") < setup.indexOf("fs.mkdirSync"));
});

test("direct Playwright config and setup execute the same failing collision preflight", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-custody-direct-"));
  const fixturePath = path.join(dir, "collision.json");
  const collision = fixture();
  collision.target.database = collision.preview.database;
  fs.writeFileSync(fixturePath, JSON.stringify(collision));
  const env = {
    ...process.env,
    ACCRUE_HOST_CUSTODY_TEST_MODE: "1",
    ACCRUE_HOST_CUSTODY_TEST_FIXTURE: fixturePath,
    ACCRUE_HOST_REUSE_SERVER: "0",
    ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED: "1",
    ACCRUE_HOST_E2E_FIXTURE: path.join(dir, "must-not-be-created", "fixture.json")
  };
  for (const entry of [
    "require('./examples/accrue_host/playwright.config.js')",
    "require('./examples/accrue_host/e2e/global-setup.js')()"
  ]) {
    const result = spawnSync("node", ["-e", entry], { cwd: repoRoot, env, encoding: "utf8" });
    assert.notEqual(result.status, 0, `${entry} accepted the preview DB alias`);
    assert.match(`${result.stdout}\n${result.stderr}`, /aliases preview database name/);
  }
  assert.equal(fs.existsSync(path.join(dir, "must-not-be-created")), false);
  fs.rmSync(dir, { recursive: true, force: true });
});

test("both wrappers reject a collision before invoking any Mix mutation", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-custody-wrapper-"));
  const fixturePath = path.join(dir, "collision.json");
  const markerPath = path.join(dir, "mix-was-invoked");
  const binDir = path.join(dir, "bin");
  fs.mkdirSync(binDir);
  fs.writeFileSync(path.join(binDir, "mix"), `#!/bin/sh\necho invoked >> '${markerPath}'\nexit 92\n`);
  fs.chmodSync(path.join(binDir, "mix"), 0o755);
  const collision = fixture();
  collision.target.database = collision.preview.database;
  fs.writeFileSync(fixturePath, JSON.stringify(collision));
  const env = {
    ...process.env,
    PATH: `${binDir}:${process.env.PATH}`,
    ACCRUE_HOST_CUSTODY_TEST_MODE: "1",
    ACCRUE_HOST_CUSTODY_TEST_FIXTURE: fixturePath
  };
  for (const wrapper of [browserWrapper, devWrapper]) {
    const result = spawnSync("bash", [wrapper], { cwd: repoRoot, env, encoding: "utf8" });
    assert.notEqual(result.status, 0, `${path.basename(wrapper)} accepted the preview DB alias`);
  }
  assert.equal(fs.existsSync(markerPath), false, "Mix was invoked before collision refusal");
  fs.rmSync(dir, { recursive: true, force: true });
});
