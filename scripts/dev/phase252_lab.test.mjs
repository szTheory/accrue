import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import {
  acquireNamespaceLock,
  buildLaunchConfig,
  matchesHealthIdentity,
  matchesStartingHealthIdentity,
  ownsProcess,
  prepareLaunch,
  acceptedServerAddress,
} from "./phase252_lab.mjs";

test("requires a fresh explicit numeric test partition", () => {
  assert.throws(
    () => buildLaunchConfig({ lane: "admin-review", partition: "", port: 4312 }),
    /explicit numeric MIX_TEST_PARTITION/i,
  );
});

test("derives an isolated package database and local endpoint from explicit input", () => {
  const config = buildLaunchConfig({
    lane: "admin-review",
    partition: "925210031",
    port: 4312,
    pgHost: "127.0.0.1",
    pgDatabase: "postgres",
    pgRole: "postgres",
  });

  assert.equal(config.database, "accrue_admin_test925210031");
  assert.equal(config.partition, "925210031");
  assert.equal(config.host, "127.0.0.1");
  assert.equal(config.port, 4312);
});

test("rejects non-disposable database names and nonlocal PostgreSQL hosts", () => {
  assert.throws(
    () => buildLaunchConfig({ lane: "admin-review", partition: "925210032", port: 4313, database: "accrue_admin_dev" }),
    /derived disposable database/i,
  );
  assert.throws(
    () => buildLaunchConfig({ lane: "admin-review", partition: "925210033", port: 4314, pgHost: "db.example.test" }),
    /loopback PostgreSQL host/i,
  );
});

test("keeps the host-heldout numeric database and fixed port contract", () => {
  const config = buildLaunchConfig({ lane: "host-heldout", partition: "925210039", port: 4102 });
  assert.equal(config.database, "accrue_host_test925210039");
  assert.throws(
    () => buildLaunchConfig({ lane: "host-heldout", partition: "925210040", port: 4317 }),
    /retains its existing port guard/i,
  );
});

test("checks server, database and port before creating the owned target", async () => {
  const config = buildLaunchConfig({
    lane: "admin-review",
    partition: "925210034",
    port: 4314,
    pgHost: "127.0.0.1",
    pgDatabase: "postgres",
    pgRole: "postgres",
  });
  const server = { database: "postgres", role: "postgres", address: "127.0.0.1" };

  for (const observation of [
    { server: { ...server, database: "accrue_admin_dev" }, databaseExists: false, portAvailable: true },
    { server: { ...server, role: "root" }, databaseExists: false, portAvailable: true },
    { server: { ...server, address: "10.0.0.7" }, databaseExists: false, portAvailable: true },
    { server, databaseExists: true, portAvailable: true },
    { server, databaseExists: false, portAvailable: false },
  ]) {
    let created = false;
    await assert.rejects(
      prepareLaunch(config, {
        readServerIdentity: async () => observation.server,
        databaseExists: async () => observation.databaseExists,
        portAvailable: async () => observation.portAvailable,
        createDatabase: async () => { created = true; },
      }, {}),
    );
    assert.equal(created, false, "preflight failure must precede database creation");
  }

  let createdDatabase;
  const order = [];
  await prepareLaunch(config, {
    readServerIdentity: async () => { order.push("identity"); return server; },
    databaseExists: async () => { order.push("database"); return false; },
    portAvailable: async () => { order.push("port"); return true; },
    createDatabase: async (database) => { order.push("create"); createdDatabase = database; },
  });
  assert.equal(createdDatabase, config.database);
  assert.deepEqual(order, ["identity", "database", "port", "create"]);
});

test("accepts loopback PostgreSQL inet addresses with a host mask", async () => {
  const config = buildLaunchConfig({
    lane: "admin-review",
    partition: "925210042",
    port: 4318,
  });
  let createdDatabase;

  let result;
  await assert.doesNotReject(async () => {
    result = await prepareLaunch(config, {
      readServerIdentity: async () => ({
        database: "postgres",
        role: "postgres",
        address: "127.0.0.1/32",
      }),
      databaseExists: async () => false,
      portAvailable: async () => true,
      createDatabase: async (database) => { createdDatabase = database; },
    });
  });

  assert.equal(createdDatabase, config.database);
  assert.equal(result.serverAddress, "127.0.0.1");
});

test("accepts cleanup only when PID, process group, start identity, command, DB, port and nonce match", () => {
  const manifest = {
    pid: 1500,
    processGroupId: 1500,
    startIdentity: "2026-10-26T23:00:00Z",
    command: "mix accrue_admin.e2e.server",
    parentPid: 1400,
    parentStartIdentity: "2026-10-26T22:59:00Z",
    parentCommandHash: "parent-command-digest",
    database: "accrue_admin_test925210035",
    port: 4315,
    nonce: "phase252-nonce",
  };

  assert.equal(ownsProcess(manifest, { ...manifest }), true);
  assert.equal(ownsProcess(manifest, { ...manifest, pid: 1501 }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, processGroupId: 1501 }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, parentStartIdentity: "reused-parent" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, startIdentity: "reused-pid" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, command: "unrelated-server" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, database: "accrue_admin_test_other" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, port: 4017 }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, nonce: "stale-nonce" }), false);
});

test("health identity must match the owned database, loopback endpoint, partition, nonce and PID", () => {
  const config = {
    database: "accrue_admin_test925210037",
    role: "postgres",
    host: "127.0.0.1",
    port: 4316,
    partition: "925210037",
  };
  const identity = { nonce: "phase252-nonce", address: config.host };
  const health = {
    ok: true,
    ready: true,
    nonce: "phase252-nonce",
    database: config.database,
    role: config.role,
    address: config.host,
    port: config.port,
    partition: config.partition,
    pid: 1520,
  };

  assert.equal(matchesHealthIdentity(config, identity, health, 1520), true);
  assert.equal(
    matchesStartingHealthIdentity(config, identity, { ...health, ready: false }, 1520),
    true,
  );
  for (const mismatch of [
    { ready: false },
    { nonce: "other" },
    { database: "accrue_admin_test925210038" },
    { role: "other" },
    { address: "0.0.0.0" },
    { port: 4017 },
    { partition: "1" },
    { pid: 1521 },
  ]) {
    assert.equal(matchesHealthIdentity(config, identity, { ...health, ...mismatch }, 1520), false);
  }
});

test("namespace locks admit one owner and can be acquired again after exact release", async () => {
  const directory = await mkdtemp(join(tmpdir(), "phase252-lock-test-"));

  try {
    const first = await acquireNamespaceLock(directory, "accrue_admin_test925210036");
    await assert.rejects(
      acquireNamespaceLock(directory, "accrue_admin_test925210036"),
      /already locked/i,
    );
    await first.release();
    const second = await acquireNamespaceLock(directory, "accrue_admin_test925210036");
    await second.release();
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("a stale lock owner cannot remove replacement namespace metadata", async () => {
  const directory = await mkdtemp(join(tmpdir(), "phase252-lock-owner-"));

  try {
    const lock = await acquireNamespaceLock(directory, "accrue_admin_test925210041");
    const current = JSON.parse(await readFile(lock.path, "utf8"));
    await writeFile(lock.path, JSON.stringify({ ...current, token: "replacement-owner" }));
    assert.equal(await lock.release(), false);
    assert.equal(JSON.parse(await readFile(lock.path, "utf8")).token, "replacement-owner");
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test("a hosted CI runner accepts only an RFC 1918 server address; a developer machine and public addresses stay rejected", async () => {
  const ci = { GITHUB_ACTIONS: "true" };
  for (const address of ["10.1.2.3", "172.16.0.2", "172.18.0.2", "172.31.255.254", "192.168.1.9", "172.18.0.2/32"]) {
    assert.equal(acceptedServerAddress(address, ci), address.split("/")[0], `${address} accepted in CI`);
    assert.equal(acceptedServerAddress(address, {}), null, `${address} rejected outside CI`);
    assert.equal(acceptedServerAddress(address, { GITHUB_ACTIONS: "false" }), null, `${address} rejected when GITHUB_ACTIONS is not true`);
  }
  for (const address of ["8.8.8.8", "172.15.0.1", "172.32.0.1", "192.169.0.1", "11.0.0.1", "0.0.0.0", "fd00::2", "10.0.0.1/24", "not-an-address", null, undefined]) {
    assert.equal(acceptedServerAddress(address, ci), null, `${String(address)} rejected even in CI`);
  }
  for (const address of ["127.0.0.1", "127.0.0.1/32", "::1"]) {
    assert.ok(acceptedServerAddress(address, {}), `${address} still accepted outside CI`);
    assert.ok(acceptedServerAddress(address, ci), `${address} still accepted in CI`);
  }

  const config = buildLaunchConfig({ lane: "admin-review", partition: "925210051", port: 4325 });
  const adapters = (server) => {
    const state = { created: false };
    return {
      state,
      readServerIdentity: async () => server,
      databaseExists: async () => false,
      portAvailable: async () => true,
      createDatabase: async () => { state.created = true; },
    };
  };
  const bridge = { database: "postgres", role: "postgres", address: "172.18.0.2" };

  const accepted = adapters(bridge);
  const result = await prepareLaunch(config, accepted, ci);
  assert.equal(result.serverAddress, "172.18.0.2");
  assert.equal(accepted.state.created, true);

  const strict = adapters(bridge);
  await assert.rejects(prepareLaunch(config, strict, {}), /identity does not match/);
  assert.equal(strict.state.created, false);

  const publicServer = adapters({ ...bridge, address: "8.8.8.8" });
  await assert.rejects(prepareLaunch(config, publicServer, ci), /identity does not match/);
  assert.equal(publicServer.state.created, false);

  // The database and role checks are unchanged in CI mode.
  for (const server of [{ ...bridge, database: "accrue_admin_dev" }, { ...bridge, role: "root" }]) {
    const wrong = adapters(server);
    await assert.rejects(prepareLaunch(config, wrong, ci), /identity does not match/);
    assert.equal(wrong.state.created, false);
  }
});
