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
const previewRunner = path.join(repoRoot, "examples/accrue_host/e2e/preview-runner.js");
const { validatePreviewSelection } = await import(path.join(repoRoot, "examples/accrue_host/e2e/preview-routing.js"));

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

test("direct Playwright preflight permits only its exact listener PID and rejects foreign owners", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-custody-direct-owner-"));
  const binDir = path.join(dir, "bin");
  const fixturePath = path.join(dir, "targets.json");
  const fixtureFile = path.join(dir, "existing-fixture.json");
  fs.mkdirSync(binDir);
  fs.writeFileSync(fixtureFile, "{}");
  fs.writeFileSync(path.join(binDir, "lsof"), "#!/bin/sh\nprintf '4242\\n'\n");
  fs.chmodSync(path.join(binDir, "lsof"), 0o755);
  const targets = fixture();
  targets.target.process = "inspect-listener";
  fs.writeFileSync(fixturePath, JSON.stringify(targets));
  const env = {
    ...process.env,
    PATH: `${binDir}:${process.env.PATH}`,
    ACCRUE_HOST_CUSTODY_TEST_MODE: "1",
    ACCRUE_HOST_CUSTODY_TEST_FIXTURE: fixturePath,
    ACCRUE_HOST_DIRECT_PROOF_PID: "4242"
  };
  const accepted = spawnSync("node", [custody, "preflight", "browser"], { cwd: repoRoot, env, encoding: "utf8" });
  assert.equal(accepted.status, 0, accepted.stderr || accepted.stdout);
  assert.match(accepted.stdout, /process=proof-server:4242/);

  const pidFile = path.join(dir, "webserver.pid");
  fs.writeFileSync(pidFile, "4242\n", { mode: 0o600 });
  const setupEnv = {
    ...env,
    ACCRUE_HOST_DIRECT_PROOF_PID_FILE: pidFile,
    ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED: "1",
    ACCRUE_HOST_E2E_FIXTURE: fixtureFile
  };
  delete setupEnv.ACCRUE_HOST_DIRECT_PROOF_PID;
  const globalSetup = path.join(repoRoot, "examples/accrue_host/e2e/global-setup.js");
  const setupAccepted = spawnSync("node", ["-e", `require(${JSON.stringify(globalSetup)})().then(teardown => teardown && teardown())`], {
    cwd: repoRoot,
    env: setupEnv,
    encoding: "utf8"
  });
  assert.equal(setupAccepted.status, 0, setupAccepted.stderr || setupAccepted.stdout);
  assert.equal(fs.existsSync(pidFile), false, "global setup retained the one-run PID file");

  const foreign = spawnSync("node", [custody, "preflight", "browser"], {
    cwd: repoRoot,
    env: { ...env, ACCRUE_HOST_DIRECT_PROOF_PID: "9999" },
    encoding: "utf8"
  });
  assert.notEqual(foreign.status, 0, "foreign listener was accepted");
  assert.match(foreign.stderr, /occupied by process 4242/);

  fs.writeFileSync(pidFile, "9999\n", { mode: 0o600 });
  const setupRejected = spawnSync("node", ["-e", `require(${JSON.stringify(globalSetup)})()`], {
    cwd: repoRoot,
    env: { ...setupEnv, ACCRUE_HOST_E2E_FIXTURE: path.join(dir, "must-not-be-created", "fixture.json") },
    encoding: "utf8"
  });
  assert.notEqual(setupRejected.status, 0, "global setup accepted a foreign listener");
  assert.equal(fs.existsSync(path.join(dir, "must-not-be-created")), false, "global setup created fixtures before rejecting a foreign listener");
  fs.writeFileSync(path.join(binDir, "lsof"), "#!/bin/sh\nprintf '4242\\n4343\\n'\n");
  const mixed = spawnSync("node", [custody, "preflight", "browser"], { cwd: repoRoot, env, encoding: "utf8" });
  assert.notEqual(mixed.status, 0, "multiple listener owners were accepted with one matching token");
  fs.rmSync(dir, { recursive: true, force: true });
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

test("preview URL fails closed unless the exclusive preservation spec is explicitly selected", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-preview-routing-"));
  const markerPath = path.join(dir, "mutable-setup-ran");
  const configPath = path.join(repoRoot, "examples/accrue_host/playwright.config.js");
  const setupPath = path.join(repoRoot, "examples/accrue_host/e2e/global-setup.js");
  const baseEnv = {
    ...process.env,
    ACCRUE_HOST_PREVIEW_BASE_URL: "http://accrue-host-phase243-preview.localhost",
    ACCRUE_HOST_PREVIEW_INSTANCE: "accrue-host-phase243-preview",
    ACCRUE_HOST_E2E_FIXTURE: markerPath
  };
  const runConfig = (args, extraEnv = {}) => spawnSync("node", ["-e", `process.argv = ["node", "playwright", ...${JSON.stringify(args)}]; const config = require(${JSON.stringify(configPath)}); if (config.webServer || config.globalSetup) process.exit(9); console.log(JSON.stringify(config.testMatch));`], {
    cwd: repoRoot,
    env: { ...baseEnv, ...extraEnv },
    encoding: "utf8"
  });
  const runSetup = (args, extraEnv = {}) => spawnSync("node", ["-e", `process.argv = ["node", "playwright", ...${JSON.stringify(args)}]; require(${JSON.stringify(setupPath)})().then((teardown) => teardown && teardown());`], {
    cwd: repoRoot,
    env: { ...baseEnv, ...extraEnv },
    encoding: "utf8"
  });
  const previewSpec = "examples/accrue_host/e2e/phase243-preview-preservation.spec.js";
  const genericSpec = "examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js";
  const previewEnv = {
    ACCRUE_HOST_PREVIEW_MODE: "preservation",
    ACCRUE_HOST_PREVIEW_SELECTION: "phase243-preview-preservation",
    npm_lifecycle_event: "e2e:preview"
  };

  for (const [label, args, env] of [
    ["URL without explicit mode", [genericSpec], {}],
    ["REUSE_SERVER generic route", [genericSpec], { ...previewEnv, ACCRUE_HOST_REUSE_SERVER: "1" }]
  ]) {
    const result = runConfig(args, env);
    assert.notEqual(result.status, 0, `accepted ${label}`);
    assert.match(`${result.stdout}\n${result.stderr}`, /preview|preservation/i);
    assert.equal(fs.existsSync(markerPath), false, `${label} reached mutable setup`);
  }

  for (const args of [[], [genericSpec], [previewSpec, genericSpec], [previewSpec, "--grep=all"]]) {
    assert.throws(() => validatePreviewSelection(args), /select exactly|unsupported preview runner argument/);
    const result = spawnSync("node", [previewRunner, ...args], { cwd: path.dirname(previewRunner), env: baseEnv, encoding: "utf8" });
    assert.notEqual(result.status, 0, `preview runner accepted ${args.join(" ") || "all-spec selection"}`);
    assert.equal(fs.existsSync(markerPath), false, "rejected preview selection reached mutable setup");
  }
  assert.doesNotThrow(() => validatePreviewSelection(["e2e/phase243-preview-preservation.spec.js", "--project=chromium-desktop", "--workers=1"]));

  const accepted = runConfig([previewSpec, "--project=chromium-desktop", "--workers=1"], previewEnv);
  assert.equal(accepted.status, 0, accepted.stderr || accepted.stdout);
  assert.match(accepted.stdout, /e2e\/phase243-preview-preservation\.spec\.js/);
  const setupAccepted = runSetup([previewSpec], previewEnv);
  assert.equal(setupAccepted.status, 0, setupAccepted.stderr || setupAccepted.stdout);
  assert.equal(fs.existsSync(markerPath), false, "preview global setup created a fixture or mutation marker");
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
