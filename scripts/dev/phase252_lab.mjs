import { randomBytes, randomInt, createHash } from "node:crypto";
import { spawn, execFileSync } from "node:child_process";
import { open, mkdir, readFile, writeFile, unlink, chmod } from "node:fs/promises";
import { createServer, isIPv4 } from "node:net";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const SCRIPT_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const ADMIN_ROOT = path.join(SCRIPT_ROOT, "accrue_admin");
const LEGACY_ADMIN_PORT = 4017;
const HELDOUT_HOST_PORT = 4102;
const LANES = new Set(["admin-test", "admin-review", "host-heldout"]);

function fail(message) {
  throw new Error(message);
}

function loopbackHost(host) {
  return host === "localhost" || host === "::1" || (isIPv4(host) && Number(host.split(".")[0]) === 127);
}

function loopbackAddress(address) {
  if (typeof address !== "string") return false;
  const [host, mask, ...extra] = address.split("/");
  if (extra.length > 0) return false;
  if (mask != null) {
    const expectedMask = host === "::1" ? "128" : isIPv4(host) ? "32" : null;
    if (mask !== expectedMask) return false;
  }
  return host === "::1" || (isIPv4(host) && Number(host.split(".")[0]) === 127);
}

function normalizedLoopbackAddress(address) {
  if (!loopbackAddress(address)) return null;
  return address.split("/", 1)[0];
}

// A hosted CI runner reaches its PostgreSQL service container through a published port, and
// the server then reports the container's bridge address (RFC 1918) from inet_server_addr()
// instead of a loopback one. Only GITHUB_ACTIONS=true widens the accepted server address,
// and only to the three RFC 1918 IPv4 blocks: public addresses are rejected there too, and
// a developer machine keeps the strict loopback requirement. The database, role and
// fresh-partition checks are unchanged in both modes.
function privateRangeAddress(address) {
  if (typeof address !== "string") return false;
  const [host, mask, ...extra] = address.split("/");
  if (extra.length > 0 || (mask != null && mask !== "32") || !isIPv4(host)) return false;
  const [first, second] = host.split(".").map(Number);
  return first === 10 || (first === 172 && second >= 16 && second <= 31) || (first === 192 && second === 168);
}

export function acceptedServerAddress(address, env = process.env) {
  const loopback = normalizedLoopbackAddress(address);
  if (loopback) return loopback;
  if (env.GITHUB_ACTIONS === "true" && privateRangeAddress(address)) return address.split("/", 1)[0];
  return null;
}

export function buildLaunchConfig(options = {}) {
  const lane = String(options.lane || "");
  if (!LANES.has(lane)) fail("lane must be admin-test, admin-review, or host-heldout");

  const partition = String(options.partition ?? "");
  if (!/^\d{8,16}$/.test(partition)) {
    fail("an explicit numeric MIX_TEST_PARTITION with at least 8 digits is required");
  }

  const port = Number(options.port);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    fail("an explicit available loopback port is required");
  }
  if (lane === "host-heldout" && port !== HELDOUT_HOST_PORT) {
    fail(`host-heldout retains its existing port guard at ${HELDOUT_HOST_PORT}`);
  }
  if (lane !== "host-heldout" && port === LEGACY_ADMIN_PORT) {
    fail(`the legacy admin E2E port ${LEGACY_ADMIN_PORT} is not accepted for a disposable lab`);
  }

  const host = String(options.pgHost || "127.0.0.1");
  if (!loopbackHost(host)) fail("PGHOST must be a loopback PostgreSQL host");
  const role = String(options.pgRole || "postgres");
  if (role !== "postgres") fail("the disposable test lanes require the existing postgres test role");

  const prefix = lane === "host-heldout" ? "accrue_host_test" : "accrue_admin_test";
  const database = `${prefix}${partition}`;
  if (options.database != null && String(options.database) !== database) {
    fail(`database must equal the derived disposable database ${database}`);
  }
  const controlDatabase = String(options.controlDatabase || "postgres");
  if (!/^[a-z][a-z0-9_]{0,62}$/.test(controlDatabase) || controlDatabase === database) {
    fail("control database must be a safe non-target database name");
  }

  return {
    lane,
    partition,
    database,
    role,
    host,
    port,
    controlDatabase,
  };
}

export async function prepareLaunch(config, adapters, env = process.env) {
  const server = await adapters.readServerIdentity();
  const serverAddress = acceptedServerAddress(server.address, env);
  if (
    server.database !== config.controlDatabase ||
    server.role !== config.role ||
    serverAddress == null
  ) {
    fail("PostgreSQL server, role, or control database identity does not match the requested local lane");
  }
  if (await adapters.databaseExists(config.database)) {
    fail(`refusing existing database ${config.database}; use a fresh partition`);
  }
  if (!(await adapters.portAvailable(config.port))) {
    fail(`refusing occupied loopback port ${config.port}`);
  }

  await adapters.beforeCreate?.();
  await adapters.createDatabase(config.database);
  return { database: config.database, serverAddress, created: true };
}

export function ownsProcess(manifest, observed) {
  if (!manifest || !observed) return false;
  for (const key of ["pid", "startIdentity", "command", "database", "port", "nonce"]) {
    if (manifest[key] == null || observed[key] !== manifest[key]) return false;
  }
  if (manifest.parentPid != null && observed.parentPid !== manifest.parentPid) return false;
  if (manifest.parentStartIdentity != null && observed.parentStartIdentity !== manifest.parentStartIdentity) return false;
  if (manifest.parentCommandHash != null && observed.parentCommandHash !== manifest.parentCommandHash) return false;
  if (manifest.processGroupId != null && observed.processGroupId !== manifest.processGroupId) return false;
  if (manifest.commandHash != null && observed.commandHash !== manifest.commandHash) return false;
  return true;
}

export function matchesHealthIdentity(config, identity, health, pid) {
  return Boolean(
    health &&
    health.ok === true &&
    health.ready === true &&
    health.nonce === identity.nonce &&
    health.database === config.database &&
    health.role === config.role &&
    health.address === identity.address &&
    Number(health.port) === config.port &&
    String(health.partition) === config.partition &&
    Number(health.pid) === Number(pid),
  );
}

export function matchesStartingHealthIdentity(config, identity, health, pid) {
  return Boolean(
    health &&
    health.ok === true &&
    health.ready === false &&
    health.nonce === identity.nonce &&
    health.database === config.database &&
    health.role === config.role &&
    health.address === identity.address &&
    Number(health.port) === config.port &&
    String(health.partition) === config.partition &&
    Number(health.pid) === Number(pid),
  );
}

async function terminateOwnedProcessGroup(manifest) {
  if (!manifest) return false;
  // Require the full command identity for the first observation. Once that
  // proves ownership, allow the leader's command title to change as it handles
  // termination; PID, start time, PGID, and parent identity remain mandatory.
  let ownerValidated = false;
  const snapshot = () => ownedProcessGroupSnapshot(manifest, ownerValidated);
  const waitForGroupExit = async (milliseconds) => {
    const deadline = Date.now() + milliseconds;
    while (Date.now() < deadline) {
      const current = snapshot();
      if (!current.safe) return false;
      if (current.members.length === 0) return true;
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    const current = snapshot();
    return current.safe && current.members.length === 0;
  };
  const signalGroup = (signal) => {
    const current = snapshot();
    if (!current.safe) return false;
    if (current.members.length === 0) return true;
    try {
      process.kill(-manifest.processGroupId, signal);
      return true;
    } catch (error) {
      if (error?.code === "ESRCH") {
        const after = snapshot();
        return after.safe && after.members.length === 0;
      }
      return false;
    }
  };

  const initial = snapshot();
  if (!initial.safe) return false;
  ownerValidated = true;
  if (initial.members.length === 0) return true;
  if (!signalGroup("SIGTERM")) return false;
  if (await waitForGroupExit(5_000)) return true;
  if (!signalGroup("SIGKILL")) return false;
  return waitForGroupExit(5_000);
}

function nonce() {
  return randomBytes(18).toString("hex");
}

function freshPartition() {
  return String(randomInt(1_000_000_000, 9_999_999_999));
}

async function chooseFreePort() {
  const server = createServer();
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  const { port } = server.address();
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
  return port;
}

async function portAvailable(port) {
  const server = createServer();
  try {
    await new Promise((resolve, reject) => {
      server.once("error", reject);
      server.listen(port, "127.0.0.1", resolve);
    });
    return true;
  } catch (error) {
    if (error?.code === "EADDRINUSE" || error?.code === "EACCES") return false;
    throw error;
  } finally {
    if (server.listening) {
      await new Promise((resolve) => server.close(resolve));
    }
  }
}

function privateRoot() {
  const uid = typeof process.getuid === "function" ? process.getuid() : "local";
  return path.join(os.tmpdir(), `accrue-phase252-${uid}`);
}

async function ensurePrivateRoot() {
  const root = privateRoot();
  await mkdir(root, { recursive: true, mode: 0o700 });
  await chmod(root, 0o700);
  await mkdir(path.join(root, "sessions"), { recursive: true, mode: 0o700 });
  await chmod(path.join(root, "sessions"), 0o700);
  return root;
}

function lockName(namespace) {
  return createHash("sha256").update(namespace).digest("hex");
}

export async function acquireNamespaceLock(directory, namespace) {
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const lockPath = path.join(directory, `${lockName(namespace)}.lock`);
  const token = nonce();
  const record = {
    namespace,
    token,
    pid: process.pid,
    createdAt: new Date().toISOString(),
  };
  let handle;
  try {
    handle = await open(lockPath, "wx", 0o600);
    await handle.writeFile(`${JSON.stringify(record)}\n`);
  } catch (error) {
    await handle?.close();
    if (error?.code === "EEXIST") {
      fail(`namespace or port is already locked; refusing stale or concurrent ownership metadata at ${lockPath}`);
    }
    throw error;
  }
  await handle.close();

  return {
    path: lockPath,
    token,
    async release() {
      let current;
      try {
        current = JSON.parse(await readFile(lockPath, "utf8"));
      } catch (error) {
        if (error?.code === "ENOENT") return false;
        throw error;
      }
      if (current.token !== token || current.pid !== process.pid || current.namespace !== namespace) {
        return false;
      }
      await unlink(lockPath);
      return true;
    },
  };
}

function psqlArgs(config, sql) {
  return [
    "-X", "-A", "-t", "-F", "\t", "-v", "ON_ERROR_STOP=1",
    "-U", config.role, "-h", config.host, "-p", String(process.env.PGPORT || "5432"),
    "-d", config.controlDatabase, "-c", sql,
  ];
}

function psql(config, sql) {
  const env = {
    ...process.env,
    PGHOST: config.host,
    PGUSER: config.role,
    PGDATABASE: config.controlDatabase,
    PGPORT: process.env.PGPORT || "5432",
  };
  try {
    return execFileSync("psql", psqlArgs(config, sql), {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      env,
    }).trim();
  } catch (error) {
    const detail = String(error.stderr || error.message || "").split("\n")[0];
    fail(`local PostgreSQL preflight failed${detail ? `: ${detail}` : ""}`);
  }
}

async function readServerIdentity(config) {
  const [database, role, address] = psql(
    config,
    "SELECT current_database(), current_user, COALESCE(host(inet_server_addr()), 'local-socket');",
  ).split("\t");
  return { database, role, address };
}

async function databaseExists(config, database) {
  const result = psql(config, `SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${database}');`);
  return result === "t";
}

async function createDatabase(config, database) {
  psql(config, `CREATE DATABASE "${database}";`);
}

async function dropDatabase(config) {
  const exists = await databaseExists(config, config.database);
  if (!exists) return;
  psql(
    config,
    `SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${config.database}' AND pid <> pg_backend_pid();`,
  );
  psql(config, `DROP DATABASE "${config.database}";`);
}

function processInfo(pid) {
  let output;
  try {
    output = execFileSync("ps", ["-p", String(pid), "-o", "pid=", "-o", "ppid=", "-o", "pgid=", "-o", "lstart=", "-o", "stat=", "-o", "command="], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch (error) {
    if (error.status === 1 && !String(error.stderr || "").trim()) return null;
    throw error;
  }
  const match = output.match(/^(\d+)\s+(\d+)\s+(\d+)\s+(.{24})\s+(\S+)\s+([\s\S]+)$/);
  if (!match) return null;
  const command = match[6].trim();
  return {
    pid: Number(match[1]),
    parentPid: Number(match[2]),
    processGroupId: Number(match[3]),
    startIdentity: match[4].trim().replace(/\s+/g, " "),
    state: match[5],
    command,
    commandHash: createHash("sha256").update(command).digest("hex"),
  };
}

function processGroupMembers(processGroupId) {
  const output = execFileSync("ps", ["-axo", "pid=", "-o", "ppid=", "-o", "pgid=", "-o", "stat="], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  });
  const members = output.split("\n").flatMap((line) => {
    const match = line.match(/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s*$/);
    if (!match || Number(match[3]) !== processGroupId) return [];
    return [{
      pid: Number(match[1]),
      parentPid: Number(match[2]),
      processGroupId: Number(match[3]),
      state: match[4],
    }];
  });
  return members;
}

function isRunningProcess(info) {
  return !info.state.startsWith("Z") && !info.state.startsWith("X");
}

function ownedProcessGroupSnapshot(manifest, allowLeaderShutdownTransition = false) {
  if (
    !manifest ||
    !Number.isInteger(manifest.processGroupId) ||
    manifest.processGroupId !== manifest.pid
  ) {
    return { safe: false, members: [] };
  }

  const members = processGroupMembers(manifest.processGroupId);
  let runningMembers = members.filter(isRunningProcess);
  const leader = runningMembers.find((member) => member.pid === manifest.processGroupId);
  if (leader) {
    const current = processInfo(manifest.processGroupId);
    // `ps` and `processInfo` are separate snapshots. The leader can exit
    // between them, changing its command to `<defunct>` while its PID, start
    // time, and process-group ID still prove it is the recorded process.
    // A zombie cannot execute or be reused, so exclude it and keep tracking
    // any live descendants that still hold the group open.
    if (
      current &&
      current.pid === manifest.pid &&
      current.processGroupId === manifest.processGroupId &&
      current.startIdentity === manifest.startIdentity &&
      current.state.startsWith("Z")
    ) {
      runningMembers = runningMembers.filter((member) => member.pid !== manifest.pid);
    } else {
      const parent = processInfo(manifest.parentPid);
      if (
        !current ||
        !parent ||
        current.pid !== manifest.pid ||
        current.processGroupId !== manifest.processGroupId ||
        current.startIdentity !== manifest.startIdentity ||
        current.parentPid !== manifest.parentPid ||
        parent.startIdentity !== manifest.parentStartIdentity ||
        parent.commandHash !== manifest.parentCommandHash ||
        (!allowLeaderShutdownTransition && current.commandHash !== manifest.commandHash)
      ) {
        return { safe: false, members: runningMembers };
      }
    }
  }
  // A live member keeps its process-group ID allocated after the original
  // leader exits. When no member remains, never signal that numeric ID: it may
  // later be reused by an unrelated process group.
  return { safe: true, members: runningMembers };
}

async function refreshOwnedProcessIdentity(manifest) {
  if (!manifest) return false;
  const current = processInfo(manifest.pid);
  if (!current) return true;

  const parent = processInfo(manifest.parentPid);
  if (
    !parent ||
    current.pid !== manifest.pid ||
    current.startIdentity !== manifest.startIdentity ||
    current.parentPid !== manifest.parentPid ||
    current.processGroupId !== manifest.processGroupId ||
    parent.startIdentity !== manifest.parentStartIdentity ||
    parent.commandHash !== manifest.parentCommandHash
  ) {
    return false;
  }

  // Script shims such as asdf's `mix` exec into the real runtime under the same
  // PID. Refresh the exact command only after the PID/start/parent proof holds.
  manifest.observedCommand = current.command;
  manifest.commandHash = current.commandHash;
  return true;
}

function displayedCommand(command, args) {
  const parts = [command];
  let redactNext = false;
  for (const raw of args) {
    const value = String(raw);
    if (redactNext) {
      parts.push("<redacted>");
      redactNext = false;
    } else if (/^--?(?:password|secret|token|api[-_]?key)$/i.test(value)) {
      parts.push(value);
      redactNext = true;
    } else if (/^--?(?:password|secret|token|api[-_]?key)=/i.test(value)) {
      parts.push(`${value.split("=", 1)[0]}=<redacted>`);
    } else {
      parts.push(value);
    }
  }
  return parts.join(" ");
}

async function readHealth(port) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 900);
  try {
    const response = await fetch(`http://127.0.0.1:${port}/__e2e__/health`, { signal: controller.signal });
    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function waitForHealth(config, child, identity, timeoutMs = 120_000, interrupted = () => false) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (interrupted()) fail("owned E2E startup interrupted before health identity was established");
    if (child.exitCode != null || child.signalCode != null) {
      fail(`owned E2E server exited during startup (code ${child.exitCode ?? "signal"})`);
    }
    const health = await readHealth(config.port);
    if (health) {
      const valid = matchesHealthIdentity(config, identity, health, child.pid);
      if (valid) return health;
      if (!matchesStartingHealthIdentity(config, identity, health, child.pid)) {
        fail("health identity mismatch on the owned loopback endpoint; refusing browser attachment");
      }
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  fail(`owned E2E server did not report its expected health identity on port ${config.port}`);
}

function runtimeEnv(config, identity) {
  const env = {
    ...process.env,
    MIX_ENV: "test",
    MIX_TEST_PARTITION: config.partition,
    PGHOST: config.host,
    PGUSER: config.role,
    ACCRUE_ADMIN_E2E_PORT: String(config.port),
    PHASE252_E2E_NONCE: identity.nonce,
    PHASE252_E2E_DATABASE: config.database,
    PHASE252_E2E_ROLE: config.role,
    PHASE252_E2E_ADDRESS: identity.address,
    PHASE252_E2E_PGHOST: config.host,
    PHASE252_E2E_PORT: String(config.port),
    PHASE252_E2E_PARTITION: config.partition,
    PHASE252_E2E_LANE: config.lane,
    PHASE252_E2E_PARENT_PID: String(process.pid),
  };
  if (config.lane === "host-heldout") {
    env.PHASE248_PROOF_LANE = "heldout";
    env.ACCRUE_HOST_BROWSER_PORT = String(HELDOUT_HOST_PORT);
    delete env.ACCRUE_HOST_E2E_DISABLE_SQL_SANDBOX;
  }
  return env;
}

export async function openOwnedSession(options) {
  const partition = options.partition ?? process.env.MIX_TEST_PARTITION ?? freshPartition();
  const port = options.port ?? (options.lane === "host-heldout" ? HELDOUT_HOST_PORT : await chooseFreePort());
  const config = buildLaunchConfig({
    lane: options.lane,
    partition,
    port,
    pgHost: options.pgHost || "127.0.0.1",
    pgRole: options.pgRole || process.env.PGUSER || "postgres",
    controlDatabase: options.controlDatabase || "postgres",
    database: options.database,
  });
  const sessionNonce = options.nonce || process.env.PHASE252_E2E_NONCE || nonce();
  const identity = { nonce: sessionNonce };
  const root = await ensurePrivateRoot();
  const parentObserved = processInfo(process.pid);
  if (!parentObserved) fail("could not record launcher parent identity; refusing resource mutation");
  const locks = [];
  let created = false;
  let creationAttempted = false;
  let child;
  let manifestPath;
  let manifest;
  let childExit;
  let cleanupPromise;
  let startupSignal = null;
  const startupSignals = ["SIGINT", "SIGTERM"];
  const startupSignalHandlers = new Map(
    startupSignals.map((signal) => {
      const handler = () => { startupSignal = signal; };
      process.on(signal, handler);
      return [signal, handler];
    }),
  );
  const assertStartupNotInterrupted = () => {
    if (startupSignal) fail(`owned session startup interrupted by ${startupSignal}`);
  };

  try {
    locks.push(await acquireNamespaceLock(path.join(root, "locks"), `db:${config.database}`));
    locks.push(await acquireNamespaceLock(path.join(root, "locks"), `port:${config.port}`));
    const adapters = {
      readServerIdentity: () => readServerIdentity(config),
      databaseExists: (database) => databaseExists(config, database),
      portAvailable: (portToCheck) => portAvailable(portToCheck),
      createDatabase: (database) => createDatabase(config, database),
      beforeCreate: () => {
        assertStartupNotInterrupted();
        creationAttempted = true;
      },
    };
    const prepared = await prepareLaunch(config, adapters);
    created = true;
    identity.address = prepared.serverAddress;
    assertStartupNotInterrupted();

    const command = options.command;
    const args = options.args || [];
    if (!command) fail("owned session requires an executable command");
    child = spawn(command, args, {
      cwd: options.cwd || SCRIPT_ROOT,
      env: runtimeEnv(config, identity),
      shell: false,
      detached: true,
      stdio: "inherit",
    });
    childExit = new Promise((resolve) => {
      child.once("exit", (code, signal) => resolve({ code, signal }));
    });
    await new Promise((resolve, reject) => {
      child.once("spawn", resolve);
      child.once("error", reject);
    });

    const observed = processInfo(child.pid);
    if (!observed) fail("could not record started child identity; refusing to continue");
    if (observed.processGroupId !== observed.pid) {
      fail("started child is not the leader of its own process group; refusing to continue");
    }
    manifest = {
      version: 1,
      lane: config.lane,
      database: config.database,
      role: config.role,
      address: identity.address,
      port: config.port,
      partition: config.partition,
      nonce: identity.nonce,
      parentPid: process.pid,
      parentStartIdentity: parentObserved.startIdentity,
      parentCommand: displayedCommand(process.execPath, process.argv.slice(1)),
      parentCommandHash: parentObserved.commandHash,
      pid: observed.pid,
      processGroupId: observed.processGroupId,
      startIdentity: observed.startIdentity,
      command: displayedCommand(command, args),
      observedCommand: observed.command,
      commandHash: observed.commandHash,
      createdDatabase: true,
      startedAt: new Date().toISOString(),
      lockTokens: locks.map((lock) => lock.token),
    };
    manifestPath = path.join(root, "sessions", `${identity.nonce}.json`);
    await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, { mode: 0o600, flag: "wx" });
    assertStartupNotInterrupted();

    let health = null;
    if (options.waitForHealth) {
      health = await waitForHealth(config, child, identity, options.healthTimeoutMs, () => Boolean(startupSignal));
    }

    process.stdout.write(
      `Phase 252 ${config.lane}: db=${config.database} role=${config.role} address=${config.host} port=${config.port} pid=${observed.pid} started=${observed.startIdentity}\n`,
    );

    async function stop() {
      if (cleanupPromise) return cleanupPromise;
      cleanupPromise = (async () => {
      let safeToDrop = !child;
      if (child) {
        const refreshed = await refreshOwnedProcessIdentity(manifest);
        if (refreshed) safeToDrop = await terminateOwnedProcessGroup(manifest);
        if (!safeToDrop) fail("owned process group no longer matches its recorded leader identity; preserving resources");
      }

      if (created && safeToDrop && manifest?.createdDatabase) {
        const server = await readServerIdentity(config);
        if (server.database !== config.controlDatabase || server.role !== config.role || !acceptedServerAddress(server.address)) {
          fail("PostgreSQL identity changed before owned database cleanup; preserving database");
        }
        await dropDatabase(config);
        created = false;
      }
      if (manifestPath) {
        try {
          const currentManifest = JSON.parse(await readFile(manifestPath, "utf8"));
          if (currentManifest.nonce === identity.nonce && currentManifest.pid === manifest.pid) {
            await unlink(manifestPath);
          }
        } catch (error) {
          if (error?.code !== "ENOENT") throw error;
        }
      }
      for (const lock of locks.reverse()) await lock.release();
      return { config, identity, health };
      })();
      return cleanupPromise;
    }

    return {
      config,
      identity,
      health,
      child,
      manifest,
      wait: () => childExit,
      stop,
    };
  } catch (error) {
    let safeToDrop = !child;
    if (child && manifest) {
      const refreshed = await refreshOwnedProcessIdentity(manifest);
      if (refreshed) safeToDrop = await terminateOwnedProcessGroup(manifest);
    } else if (child && !safeToDrop) {
      safeToDrop = false;
    }
    if (!safeToDrop) {
      locks.length = 0;
      process.stderr.write(`Phase 252 resources preserved for manual identity review: db=${config.database} port=${config.port}\n`);
      throw error;
    }
    if (creationAttempted && !created) {
      locks.length = 0;
      process.stderr.write(`Phase 252 creation outcome is uncertain; preserving namespace lock for db=${config.database}\n`);
      throw error;
    }
    if (created) {
      try {
        const server = await readServerIdentity(config);
        if (server.database === config.controlDatabase && server.role === config.role && acceptedServerAddress(server.address)) {
          await dropDatabase(config);
        }
      } catch {
        // Preserve the database and lock when identity cannot be re-established.
        locks.length = 0;
        throw error;
      }
    }
    for (const lock of locks.reverse()) await lock.release();
    if (manifestPath) await unlink(manifestPath).catch(() => {});
    throw error;
  } finally {
    for (const [signal, handler] of startupSignalHandlers) process.removeListener(signal, handler);
  }
}

function parseOptions(args) {
  const options = {};
  const commandIndex = args.indexOf("--");
  const optionArgs = commandIndex < 0 ? args : args.slice(0, commandIndex);
  const command = commandIndex < 0 ? [] : args.slice(commandIndex + 1);
  for (let index = 0; index < optionArgs.length; index += 1) {
    const key = optionArgs[index];
    if (!key.startsWith("--")) fail(`unexpected argument ${key}`);
    const name = key.slice(2).replace(/-([a-z])/g, (_match, letter) => letter.toUpperCase());
    const value = optionArgs[index + 1];
    if (!value || value.startsWith("--")) fail(`${key} requires a value`);
    options[name] = value;
    index += 1;
  }
  return { options, command };
}

async function runOwned(options, command, args, cwd, waitForHealth = false) {
  const config = {
    lane: options.lane || "admin-review",
    partition: options.partition || process.env.MIX_TEST_PARTITION || freshPartition(),
    port: Number(options.port || process.env.ACCRUE_ADMIN_E2E_PORT || (options.lane === "host-heldout" ? HELDOUT_HOST_PORT : await chooseFreePort())),
    pgHost: process.env.PGHOST || "127.0.0.1",
    pgRole: process.env.PGUSER || "postgres",
    controlDatabase: options.controlDatabase || "postgres",
  };
  const handle = await openOwnedSession({
    ...config,
    command,
    args,
    cwd,
    waitForHealth,
    detached: options.detached === true,
  });
  let interrupted = false;
  const onSignal = async () => {
    interrupted = true;
    try {
      await handle.stop();
    } catch (error) {
      process.stderr.write(`Phase 252 cleanup refused: ${error.message}\n`);
    }
    process.exitCode = 128;
  };
  process.once("SIGINT", onSignal);
  process.once("SIGTERM", onSignal);
  const exit = await handle.wait();
  process.removeListener("SIGINT", onSignal);
  process.removeListener("SIGTERM", onSignal);
  await handle.stop();
  if (interrupted || exit.signal) process.exitCode = 1;
  else process.exitCode = exit.code ?? 1;
}

async function browser(options, args) {
  const partition = options.partition || process.env.MIX_TEST_PARTITION || freshPartition();
  const port = Number(options.port || await chooseFreePort());
  const identityNonce = process.env.PHASE252_E2E_NONCE || nonce();
  const config = buildLaunchConfig({
    lane: "admin-review",
    partition,
    port,
    pgHost: process.env.PGHOST || "127.0.0.1",
    pgRole: process.env.PGUSER || "postgres",
  });
  const env = {
    ...process.env,
    MIX_ENV: "test",
    MIX_TEST_PARTITION: config.partition,
    ACCRUE_ADMIN_E2E_PORT: String(config.port),
    PHASE252_E2E_NONCE: identityNonce,
    PHASE252_E2E_DATABASE: config.database,
    PHASE252_E2E_ROLE: config.role,
    PHASE252_E2E_ADDRESS: config.host,
    PHASE252_E2E_PGHOST: config.host,
    PHASE252_E2E_PORT: String(config.port),
    PHASE252_E2E_PARTITION: config.partition,
    PHASE252_E2E_LANE: config.lane,
  };
  const playwright = path.join(ADMIN_ROOT, "node_modules", "@playwright", "test", "cli.js");
  const child = spawn(process.execPath, [playwright, "test", "--config", "playwright.phase252.config.js", ...args], {
    cwd: ADMIN_ROOT,
    env,
    shell: false,
    stdio: "inherit",
  });
  const code = await new Promise((resolve, reject) => {
    child.once("error", reject);
    child.once("exit", (exitCode, signal) => resolve(signal ? 1 : exitCode ?? 1));
  });
  process.exitCode = code;
}

async function main(argv) {
  const [verb, ...rest] = argv;
  if (verb === "--help" || verb === "help" || !verb) {
    process.stdout.write(
      "Usage: phase252_lab.mjs exec --lane admin-test|admin-review|host-heldout [--partition N] [--port N] -- command [args...]\n" +
      "       phase252_lab.mjs serve --lane admin-review [--partition N] [--port N]\n" +
      "       phase252_lab.mjs browser [--partition N] [--port N] [playwright args...]\n" +
      "       phase252_lab.mjs isolation\n",
    );
    return;
  }
  const { options, command } = parseOptions(rest);
  if (verb === "exec") {
    if (!command.length) fail("exec requires a command after --");
    return runOwned(options, command[0], command.slice(1), SCRIPT_ROOT, false);
  }
  if (verb === "serve") {
    const config = buildLaunchConfig({
      lane: options.lane || "admin-review",
      partition: options.partition || process.env.MIX_TEST_PARTITION || freshPartition(),
      port: Number(options.port || process.env.ACCRUE_ADMIN_E2E_PORT || await chooseFreePort()),
      pgHost: process.env.PGHOST || "127.0.0.1",
      pgRole: process.env.PGUSER || "postgres",
    });
    return runOwned(
      { ...options, ...config, detached: true },
      "mix",
      ["accrue_admin.e2e.server"],
      ADMIN_ROOT,
      true,
    );
  }
  if (verb === "browser") return browser(options, command);
  if (verb === "isolation") {
    const child = spawn(process.execPath, ["--test", "scripts/dev/phase252_isolation.test.mjs"], {
      cwd: SCRIPT_ROOT,
      env: process.env,
      shell: false,
      stdio: "inherit",
    });
    const code = await new Promise((resolve, reject) => {
      child.once("error", reject);
      child.once("exit", (exitCode, signal) => resolve(signal ? 1 : exitCode ?? 1));
    });
    process.exitCode = code;
    return;
  }
  fail(`unknown phase252 lab command ${verb}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  main(process.argv.slice(2)).catch((error) => {
    process.stderr.write(`phase252_lab: ${error.message}\n`);
    process.exitCode = 2;
  });
}
