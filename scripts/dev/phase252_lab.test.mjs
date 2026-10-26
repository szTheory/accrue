import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import {
  acquireNamespaceLock,
  buildLaunchConfig,
  ownsProcess,
  prepareLaunch,
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
    () => buildLaunchConfig({ lane: "admin-review", partition: "925210032", database: "accrue_admin_dev" }),
    /derived disposable database/i,
  );
  assert.throws(
    () => buildLaunchConfig({ lane: "admin-review", partition: "925210033", pgHost: "db.example.test" }),
    /loopback PostgreSQL host/i,
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
    { server: { ...server, role: "root" }, databaseExists: false, portAvailable: true },
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
      }),
    );
    assert.equal(created, false, "preflight failure must precede database creation");
  }

  let createdDatabase;
  await prepareLaunch(config, {
    readServerIdentity: async () => server,
    databaseExists: async () => false,
    portAvailable: async () => true,
    createDatabase: async (database) => { createdDatabase = database; },
  });
  assert.equal(createdDatabase, config.database);
});

test("accepts cleanup only when pid, start identity, command, DB, port and nonce all match", () => {
  const manifest = {
    pid: 1500,
    startIdentity: "2026-10-26T23:00:00Z",
    command: "mix accrue_admin.e2e.server",
    database: "accrue_admin_test925210035",
    port: 4315,
    nonce: "phase252-nonce",
  };

  assert.equal(ownsProcess(manifest, { ...manifest }), true);
  assert.equal(ownsProcess(manifest, { ...manifest, pid: 1501 }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, startIdentity: "reused-pid" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, command: "unrelated-server" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, database: "accrue_admin_test_other" }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, port: 4017 }), false);
  assert.equal(ownsProcess(manifest, { ...manifest, nonce: "stale-nonce" }), false);
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
