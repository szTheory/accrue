import assert from "node:assert/strict";
import { randomInt, randomUUID } from "node:crypto";
import { execFileSync, spawn } from "node:child_process";
import { createServer } from "node:net";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { openOwnedSession } from "./phase252_lab.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ADMIN_ROOT = path.join(ROOT, "accrue_admin");
const PARTITION_MIN = 1_000_000_000;
const PARTITION_MAX = 9_999_999_999;

function freshPartition() {
  return String(randomInt(PARTITION_MIN, PARTITION_MAX));
}

async function freePort() {
  const listener = createServer();
  await new Promise((resolve, reject) => {
    listener.once("error", reject);
    listener.listen(0, "127.0.0.1", resolve);
  });
  const port = listener.address().port;
  await new Promise((resolve, reject) => listener.close((error) => error ? reject(error) : resolve()));
  return port;
}

function psql(database, sql) {
  const host = process.env.PGHOST || "127.0.0.1";
  const role = process.env.PGUSER || "postgres";
  const port = process.env.PGPORT || "5432";
  return execFileSync("psql", [
    "-X", "-A", "-t", "-F", "\t", "-w", "-v", "ON_ERROR_STOP=1",
    "-U", role, "-h", host, "-p", port, "-d", database, "-c", sql,
  ], {
    encoding: "utf8",
    env: { ...process.env, PGHOST: host, PGUSER: role, PGPORT: port, PGDATABASE: database },
    stdio: ["ignore", "pipe", "pipe"],
  }).trim();
}

function databaseExists(database) {
  return psql("postgres", `SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${database}')`) === "t";
}

function processIdentity(pid) {
  try {
    const output = execFileSync("ps", ["-p", String(pid), "-o", "pid=", "-o", "lstart=", "-o", "stat=", "-o", "command="], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const match = output.match(/^(\d+)\s+(.{24})\s+(\S+)\s+([\s\S]+)$/);
    if (!match) return null;
    return {
      pid: Number(match[1]),
      startIdentity: match[2].trim().replace(/\s+/g, " "),
      state: match[3],
      command: match[4].trim(),
    };
  } catch {
    return null;
  }
}

function sameProcess(identity) {
  const current = processIdentity(identity.pid);
  return Boolean(
    current && current.startIdentity === identity.startIdentity && current.command === identity.command &&
    !current.state.startsWith("Z") && !current.state.startsWith("X"),
  );
}

async function waitUntil(predicate, timeoutMs = 10_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await predicate()) return true;
    await new Promise((resolve) => setTimeout(resolve, 25));
  }
  return Boolean(await predicate());
}

async function stopExactProcess(identity) {
  if (!sameProcess(identity)) return;
  try {
    process.kill(identity.pid, "SIGTERM");
  } catch (error) {
    if (error?.code === "ESRCH") return;
    throw error;
  }
  if (await waitUntil(() => !sameProcess(identity), 2_000)) return;
  if (sameProcess(identity)) process.kill(identity.pid, "SIGKILL");
}

function insertMarker(database, marker) {
  psql(database, `
    INSERT INTO billing.accrue_customers (owner_type, owner_id, processor, processor_id, name, metadata, inserted_at, updated_at)
    VALUES ('phase252-isolation', '${marker}', 'stripe', 'cus_${marker}', 'Phase 252 ${marker}', '{"phase252":"${marker}"}', now(), now());
    INSERT INTO billing.accrue_subscriptions (customer_id, processor, processor_id, status, metadata, inserted_at, updated_at)
    SELECT id, 'stripe', 'sub_${marker}', 'active', '{"phase252":"${marker}"}', now(), now()
    FROM billing.accrue_customers WHERE owner_type = 'phase252-isolation' AND owner_id = '${marker}';
    INSERT INTO billing.accrue_subscription_items (subscription_id, processor, processor_id, price_id, quantity, metadata, inserted_at, updated_at)
    SELECT id, 'stripe', 'si_${marker}', 'price_${marker}', 3, '{"phase252":"${marker}"}', now(), now()
    FROM billing.accrue_subscriptions WHERE processor_id = 'sub_${marker}';
  `);
}

function markerSnapshot(database, marker) {
  return psql(database, `
    SELECT COALESCE(
      jsonb_agg(jsonb_build_object(
        'customer_id', c.id::text,
        'owner_type', c.owner_type,
        'owner_id', c.owner_id,
        'customer_processor_id', c.processor_id,
        'customer_name', c.name,
        'customer_metadata', c.metadata,
        'subscription_id', s.id::text,
        'subscription_customer_id', s.customer_id::text,
        'subscription_processor_id', s.processor_id,
        'subscription_status', s.status,
        'subscription_metadata', s.metadata,
        'item_id', i.id::text,
        'item_subscription_id', i.subscription_id::text,
        'item_processor_id', i.processor_id,
        'item_price_id', i.price_id,
        'item_quantity', i.quantity,
        'item_metadata', i.metadata
      ) ORDER BY c.id, s.id, i.id), '[]'::jsonb
    )::text
    FROM billing.accrue_customers c
    JOIN billing.accrue_subscriptions s ON s.customer_id = c.id
    JOIN billing.accrue_subscription_items i ON i.subscription_id = s.id
    WHERE c.owner_type = 'phase252-isolation' AND c.owner_id = '${marker}';
  `);
}

async function withSessions(callback) {
  const sessions = [];
  try {
    const review = await openOwnedSession({
      lane: "admin-review",
      partition: freshPartition(),
      port: await freePort(),
      command: "mix",
      args: ["accrue_admin.e2e.server"],
      cwd: ADMIN_ROOT,
      waitForHealth: true,
      healthTimeoutMs: 120_000,
    });
    sessions.push(review);

    const normal = await openOwnedSession({
      lane: "admin-test",
      partition: freshPartition(),
      port: await freePort(),
      command: "mix",
      args: ["accrue_admin.e2e.server"],
      cwd: ADMIN_ROOT,
      waitForHealth: true,
      healthTimeoutMs: 120_000,
    });
    sessions.push(normal);

    await callback({ review, normal });
  } finally {
    let cleanupError;
    for (const session of sessions.reverse()) {
      try {
        await session.stop();
      } catch (error) {
        cleanupError ||= error;
      }
    }
    if (cleanupError) throw cleanupError;
  }
}

test("ordinary reset deletes its marker and preserves review relationships byte-for-byte", async () => {
  await withSessions(async ({ review, normal }) => {
    assert.notEqual(review.config.database, normal.config.database);
    assert.notEqual(review.config.partition, normal.config.partition);
    assert.notEqual(review.config.port, normal.config.port);
    assert.notEqual(review.manifest.pid, normal.manifest.pid);
    assert.equal(review.health.ready, true);
    assert.equal(normal.health.ready, true);

    const reviewMarker = `review_${randomUUID().replaceAll("-", "")}`;
    const normalMarker = `normal_${randomUUID().replaceAll("-", "")}`;
    insertMarker(review.config.database, reviewMarker);
    insertMarker(normal.config.database, normalMarker);

    const reviewBefore = markerSnapshot(review.config.database, reviewMarker);
    const normalBefore = markerSnapshot(normal.config.database, normalMarker);
    assert.equal(JSON.parse(reviewBefore).length, 1, "review marker and joined child rows should exist before reset");
    assert.equal(JSON.parse(normalBefore).length, 1, "normal marker and joined child rows should exist before reset");

    const reset = await fetch(`http://127.0.0.1:${normal.config.port}/__e2e__/reset`, { method: "POST" });
    assert.equal(reset.status, 200, "the ordinary test server should accept its real reset route");
    assert.deepEqual(await reset.json(), { ok: true });

    assert.equal(JSON.parse(markerSnapshot(normal.config.database, normalMarker)).length, 0,
      "positive control: reset must remove the ordinary customer and cascading child relationships");
    const reviewAfter = markerSnapshot(review.config.database, reviewMarker);
    assert.equal(reviewAfter, reviewBefore,
      "negative control: the review customer and joined subscription/item data must reload byte-for-byte unchanged");
  });
});

test("occupied listeners, wrong health identity, failed bootstrap and duplicate namespaces fail closed", async () => {
  const occupied = createServer((_request, response) => response.end("unrelated listener"));
  await new Promise((resolve, reject) => {
    occupied.once("error", reject);
    occupied.listen(0, "127.0.0.1", resolve);
  });
  const occupiedPort = occupied.address().port;
  const occupiedDb = `accrue_admin_test${freshPartition()}`;
  try {
    await assert.rejects(openOwnedSession({
      lane: "admin-review",
      partition: occupiedDb.slice("accrue_admin_test".length),
      port: occupiedPort,
      command: process.execPath,
      args: ["-e", "setTimeout(() => {}, 60000)"],
      waitForHealth: true,
    }), /occupied loopback port/);
    assert.equal(occupied.listening, true, "preflight must preserve the unrelated listener");
    assert.equal(databaseExists(occupiedDb), false, "occupied-port refusal must happen before database creation");
  } finally {
    await new Promise((resolve) => occupied.close(resolve));
  }

  const mismatchPartition = freshPartition();
  const mismatchDb = `accrue_admin_test${mismatchPartition}`;
  const wrongHealthProgram = [
    "const http = require('node:http');",
    "http.createServer((_req, res) => { res.setHeader('content-type', 'application/json'); res.end(JSON.stringify({ok:true,ready:true,nonce:'wrong',database:process.env.PHASE252_E2E_DATABASE,role:'postgres',address:process.env.PHASE252_E2E_ADDRESS,port:Number(process.env.PHASE252_E2E_PORT),partition:process.env.PHASE252_E2E_PARTITION,pid:process.pid})); }).listen(Number(process.env.PHASE252_E2E_PORT), '127.0.0.1');",
  ].join(" ");
  await assert.rejects(openOwnedSession({
    lane: "admin-review",
    partition: mismatchPartition,
    port: await freePort(),
    command: process.execPath,
    args: ["-e", wrongHealthProgram],
    waitForHealth: true,
    healthTimeoutMs: 5_000,
  }), /health identity mismatch/);
  assert.equal(databaseExists(mismatchDb), false, "mismatched server bootstrap must clean its launcher-created database");

  const failedPartition = freshPartition();
  const failedDb = `accrue_admin_test${failedPartition}`;
  await assert.rejects(openOwnedSession({
    lane: "admin-review",
    partition: failedPartition,
    port: await freePort(),
    command: process.execPath,
    args: ["-e", "process.exit(23)"],
    waitForHealth: true,
    healthTimeoutMs: 5_000,
  }), /exited during startup|could not record started child identity/);
  assert.equal(databaseExists(failedDb), false, "failed bootstrap must clean its launcher-created database");

  await withSessions(async ({ review }) => {
    const sameDatabase = review.config.database;
    const stillOwnedPid = review.manifest.pid;
    await assert.rejects(openOwnedSession({
      lane: "admin-review",
      partition: review.config.partition,
      port: await freePort(),
      command: process.execPath,
      args: ["-e", "setTimeout(() => {}, 60000)"],
      waitForHealth: true,
    }), /already locked/);
    assert.equal(databaseExists(sameDatabase), true, "duplicate namespace must preserve the first owned database");
    assert.equal(review.child.exitCode, null, "duplicate namespace must not terminate the first session process");
    assert.equal(review.manifest.pid, stillOwnedPid);
  });
});

test("interrupted launcher stops descendants before database teardown and preserves unrelated processes", async () => {
  const partition = freshPartition();
  const database = `accrue_admin_test${partition}`;
  const port = await freePort();
  const directory = await mkdtemp(path.join(os.tmpdir(), "phase252-process-group-"));
  const statePath = path.join(directory, "child-state.json");
  const grandchildReadyPath = path.join(directory, "grandchild-ready.json");
  const sentinelSignalPath = path.join(directory, "sentinel-signal.txt");
  const childToken = randomUUID();
  const sentinel = spawn(process.execPath, ["-e", [
    "const fs = require('node:fs');",
    `const marker = ${JSON.stringify(sentinelSignalPath)};`,
    "process.on('SIGTERM', () => { fs.writeFileSync(marker, 'SIGTERM'); process.exit(0); });",
    "setInterval(() => {}, 1000);",
  ].join(" ")], { stdio: "ignore" });
  const sentinelSpawned = new Promise((resolve, reject) => {
    sentinel.once("spawn", resolve);
    sentinel.once("error", reject);
  });
  await sentinelSpawned;
  const sentinelIdentity = await new Promise((resolve, reject) => {
    const check = async () => {
      const identity = processIdentity(sentinel.pid);
      if (identity) return resolve(identity);
      if (sentinel.exitCode != null || sentinel.signalCode != null) return reject(new Error("sentinel exited during startup"));
      setTimeout(check, 10);
    };
    check();
  });

  const grandchildProgram = [
    "const fs = require('node:fs');",
    `const ready = ${JSON.stringify(grandchildReadyPath)};`,
    `const token = ${JSON.stringify(childToken)};`,
    "process.on('SIGTERM', () => { fs.appendFileSync(ready, '\\nSIGTERM\\n'); setTimeout(() => { fs.appendFileSync(ready, 'DONE\\n'); process.exit(0); }, 350); });",
    "fs.writeFileSync(ready, JSON.stringify({ pid: process.pid, token }));",
    "setInterval(() => {}, 1000);",
  ].join(" ");
  const targetProgram = [
    "const fs = require('node:fs');",
    "const { spawn } = require('node:child_process');",
    `const state = ${JSON.stringify(statePath)};`,
    `const ready = ${JSON.stringify(grandchildReadyPath)};`,
    `const grandchildProgram = ${JSON.stringify(grandchildProgram)};`,
    "const grandchild = spawn(process.execPath, ['-e', grandchildProgram], { stdio: 'ignore' });",
    "process.on('SIGTERM', () => { fs.appendFileSync(state, '\\nPARENT_SIGTERM\\n'); setTimeout(() => process.exit(0), 40); });",
    "const deadline = Date.now() + 5000;",
    "const publishReady = () => { if (fs.existsSync(ready)) { fs.writeFileSync(state, JSON.stringify({ parentPid: process.pid, grandchildPid: grandchild.pid }) + '\\n'); return; } if (Date.now() > deadline) process.exit(31); setTimeout(publishReady, 10); };",
    "publishReady();",
    "setInterval(() => {}, 1000);",
  ].join(" ");

  const launcher = spawn(process.execPath, [
    path.join(ROOT, "scripts/dev/phase252_lab.mjs"), "exec",
    "--lane", "admin-test", "--partition", partition, "--port", String(port),
    "--", process.execPath, "-e", targetProgram,
  ], { cwd: ROOT, stdio: "ignore" });
  const launcherExited = new Promise((resolve, reject) => {
    launcher.once("exit", (code, signal) => resolve({ code, signal }));
    launcher.once("error", reject);
  });

  let observerRunning = false;
  let droppedWhileGrandchildAlive = false;
  let observer;
  let grandchildIdentity;
  try {
    const ready = await waitUntil(async () => {
      try {
        const rawState = await readFile(statePath, "utf8");
        const state = JSON.parse(rawState.split("\n", 1)[0]);
        const readyRecord = JSON.parse((await readFile(grandchildReadyPath, "utf8")).split("\n", 1)[0]);
        if (readyRecord.token !== childToken || readyRecord.pid !== state.grandchildPid) return false;
        grandchildIdentity = processIdentity(state.grandchildPid);
        return Boolean(grandchildIdentity && databaseExists(database));
      } catch {
        return false;
      }
    }, 20_000);
    assert.equal(ready, true, "the guarded launcher should create its owned database and child/grandchild pair");

    observerRunning = true;
    observer = (async () => {
      while (observerRunning) {
        if (!databaseExists(database) && grandchildIdentity && sameProcess(grandchildIdentity)) {
          droppedWhileGrandchildAlive = true;
        }
        await new Promise((resolve) => setTimeout(resolve, 20));
      }
    })();
    launcher.kill("SIGTERM");
    const exit = await Promise.race([
      launcherExited,
      new Promise((_, reject) => setTimeout(() => reject(new Error("guarded launcher did not finish SIGTERM cleanup")), 15_000)),
    ]);
    assert.equal(exit.code, 1, "an interrupted owned command should return the documented failure exit status");
    assert.equal(await waitUntil(() => !databaseExists(database)), true, "the launcher should remove its exact disposable database after process cleanup");
    assert.equal(droppedWhileGrandchildAlive, false, "database teardown must wait until the owned grandchild is no longer running");
    const grandchildState = await readFile(grandchildReadyPath, "utf8");
    assert.match(grandchildState, /SIGTERM/, "the grandchild should receive termination through owned cleanup");
    assert.match(grandchildState, /DONE/, "cleanup should wait until the grandchild finishes its graceful shutdown");
    assert.equal(sameProcess(sentinelIdentity), true, "an unrelated process outside the owned session must remain alive");
    await assert.rejects(readFile(sentinelSignalPath, "utf8"), { code: "ENOENT" }, "cleanup must not signal the unrelated sentinel");
  } finally {
    observerRunning = false;
    await observer;
    if (launcher.exitCode == null && launcher.signalCode == null) {
      launcher.kill("SIGKILL");
      await launcherExited.catch(() => {});
    }
    if (grandchildIdentity) await stopExactProcess(grandchildIdentity);
    if (sameProcess(sentinelIdentity)) sentinel.kill("SIGTERM");
    if (sentinel.exitCode == null && sentinel.signalCode == null) {
      await new Promise((resolve) => sentinel.once("exit", resolve));
    }
    await rm(directory, { recursive: true, force: true });
  }
});
