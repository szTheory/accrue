#!/usr/bin/env node
/* Read-only custody gate for the host verifier and direct Playwright entry. */
const { execFileSync, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "../..");
const hostRoot = path.join(repoRoot, "examples/accrue_host");

function fail(message) {
  console.error(`[preview-custody] REFUSED: ${message}`);
  process.exit(2);
}

function requireIdentity(identity, label) {
  for (const field of ["databaseHost", "database", "connection", "databaseInstance", "composeProject", "volume", "port", "process", "databaseProcess", "buildPath"]) {
    if (identity[field] === undefined || identity[field] === null || String(identity[field]).trim() === "") {
      fail(`${label} identity is unavailable (${field})`);
    }
  }
}

function fixtureTargets() {
  if (process.env.ACCRUE_HOST_CUSTODY_TEST_MODE !== "1") return null;
  const fixturePath = process.env.ACCRUE_HOST_CUSTODY_TEST_FIXTURE;
  if (!fixturePath) fail("test fixture path is unavailable");
  return JSON.parse(fs.readFileSync(fixturePath, "utf8"));
}

function previewIdentity() {
  const project = process.env.ACCRUE_HOST_PREVIEW_INSTANCE || "accrue-host";
  const databaseHost = process.env.ACCRUE_HOST_PREVIEW_DATABASE_HOST || "db";
  const database = process.env.ACCRUE_HOST_PREVIEW_DATABASE || "accrue_host_dev";
  const volumes = execFileSync("docker", ["volume", "ls", "--filter", `label=com.docker.compose.project=${project}`, "--format", "{{.Name}}"], { encoding: "utf8" })
    .trim().split(/\s+/).filter(Boolean);
  const databaseVolume = process.env.ACCRUE_HOST_PREVIEW_VOLUME || `${project}_pgdata`;
  if (!volumes.includes(databaseVolume)) fail(`preview database volume ${databaseVolume} is unavailable for Compose instance ${project}`);
  const containers = execFileSync("docker", ["ps", "-q", "--filter", `label=com.docker.compose.project=${project}`, "--filter", "label=com.docker.compose.service=web"], { encoding: "utf8" })
    .trim().split(/\s+/).filter(Boolean);
  const databaseContainers = execFileSync("docker", ["ps", "-q", "--filter", `label=com.docker.compose.project=${project}`, "--filter", "label=com.docker.compose.service=db"], { encoding: "utf8" })
    .trim().split(/\s+/).filter(Boolean);
  let port = process.env.ACCRUE_HOST_PREVIEW_PORT || "container:4000 (proxy :80)";
  let buildPath = process.env.ACCRUE_HOST_PREVIEW_BUILD_PATH;
  if (containers[0]) {
    const published = execFileSync("docker", ["port", containers[0], "4000/tcp"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
    if (published) port = published.split("\n").map((line) => line.split(":").at(-1)).join(",");
  }
  if (!buildPath) {
    const composeConfig = JSON.parse(execFileSync("docker", ["compose", "-p", project, "-f", path.join(hostRoot, "docker-compose.yml"), "config", "--format", "json"], {
      cwd: hostRoot,
      encoding: "utf8",
      env: { ...process.env, COMPOSE_PROJECT_NAME: project }
    }));
    const mounts = composeConfig.services.web.volumes
      .filter((mount) => mount.target.includes("/_build"))
      .map((mount) => `${mount.target}[${project}_${mount.source}]`);
    buildPath = mounts.join(";") || "unavailable";
  }
  return {
    databaseHost,
    database,
    connection: `${databaseHost}:${process.env.ACCRUE_HOST_PREVIEW_DATABASE_PORT || "5432"}/${database}`,
    databaseInstance: `docker-volume:${databaseVolume}`,
    composeProject: project,
    volume: databaseVolume,
    port,
    process: process.env.ACCRUE_HOST_PREVIEW_PROCESS || (containers.length ? `container:${containers[0]}` : "stopped"),
    databaseProcess: process.env.ACCRUE_HOST_PREVIEW_DATABASE_PROCESS || (databaseContainers.length ? `container:${databaseContainers[0]}` : "stopped"),
    buildPath
  };
}

function portOwner(port) {
  const result = spawnSync("lsof", ["-nP", "-t", `-iTCP:${port}`, "-sTCP:LISTEN"], { encoding: "utf8" });
  if (result.error || result.status > 1) return "unavailable";
  const pids = result.stdout.trim().split(/\s+/).filter(Boolean);
  if (process.env.ACCRUE_HOST_REUSE_SERVER === "1" && process.env.ACCRUE_HOST_PROOF_SERVER_PID && pids.includes(process.env.ACCRUE_HOST_PROOF_SERVER_PID)) {
    return `proof-server:${process.env.ACCRUE_HOST_PROOF_SERVER_PID}`;
  }
  return pids.join(",") || "unoccupied";
}

function targetIdentity(mode) {
  const testMode = mode === "browser";
  const port = String(process.env[testMode ? "ACCRUE_HOST_BROWSER_PORT" : "ACCRUE_HOST_PORT"] || (testMode ? "4101" : "4100"));
  const host = process.env.PGHOST || "localhost";
  const database = testMode
    ? `accrue_host_test${process.env.MIX_TEST_PARTITION || ""}`
    : process.env.ACCRUE_HOST_DEV_BOOT_DATABASE || "accrue_host_dev";
  const connectionPort = process.env.PGPORT || "5432";
  const pgIdentity = spawnSync("psql", ["-h", host, "-p", connectionPort, "-U", process.env.PGUSER || "postgres", "-d", "postgres", "-v", "ON_ERROR_STOP=1", "-Atc", "SELECT current_setting('data_directory') || '|' || (pg_control_system()).system_identifier"], {
    encoding: "utf8",
    env: { ...process.env, PGPASSWORD: process.env.PGPASSWORD || "postgres" }
  });
  if (pgIdentity.error || pgIdentity.status !== 0) fail(`${mode} proof database instance could not be identified by a read-only PostgreSQL query`);
  const [dataDirectory, systemIdentifier] = pgIdentity.stdout.trim().split("|");
  if (!dataDirectory || !systemIdentifier) fail(`${mode} proof database instance identity is incomplete`);
  return {
    databaseHost: host,
    database,
    connection: `${normalizeHost(host)}:${connectionPort}/${database}`,
    databaseInstance: `postgres-system:${systemIdentifier}`,
    composeProject: process.env.COMPOSE_PROJECT_NAME || "none (native PostgreSQL)",
    volume: `pgdata:${dataDirectory}`,
    port,
    process: portOwner(port),
    databaseProcess: portOwner(connectionPort),
    buildPath: path.resolve(process.env.MIX_BUILD_PATH || path.join(hostRoot, "_build"))
  };
}

function assertDistinct(preview, target, mode) {
  requireIdentity(preview, "preview");
  requireIdentity(target, `${mode} proof`);
  const pairs = [
    ["database host", normalizeHost(preview.databaseHost), normalizeHost(target.databaseHost)],
    ["database name", preview.database, target.database],
    ["database connection", preview.connection, target.connection],
    ["database instance", preview.databaseInstance, target.databaseInstance],
    ["Compose instance", preview.composeProject, target.composeProject],
    ["database volume", preview.volume, target.volume],
    ["port", preview.port, target.port],
    ["listener process", preview.process, target.process],
    ["database process", preview.databaseProcess, target.databaseProcess],
    ["build path", preview.buildPath, target.buildPath]
  ];
  for (const [name, left, right] of pairs) {
    if (String(left).toLowerCase() === String(right).toLowerCase()) fail(`${mode} proof aliases preview ${name}`);
  }
  console.log(`[preview-custody] preview databaseHost=${preview.databaseHost} database=${preview.database} connection=${preview.connection} databaseInstance=${preview.databaseInstance} compose=${preview.composeProject} volume=${preview.volume} port=${preview.port} process=${preview.process} databaseProcess=${preview.databaseProcess} buildPath=${preview.buildPath}`);
  if (target.process !== "unoccupied" && !target.process.startsWith("proof-server:")) {
    fail(`${mode} proof listener port is occupied by process ${target.process}`);
  }
  if (target.process === "unavailable") fail(`${mode} proof listener ownership could not be inspected`);
  console.log(`[preview-custody] mode=${mode} target databaseHost=${target.databaseHost} database=${target.database} connection=${target.connection} databaseInstance=${target.databaseInstance} compose=${target.composeProject} volume=${target.volume} port=${target.port} process=${target.process} databaseProcess=${target.databaseProcess} buildPath=${target.buildPath}`);
}

function normalizeHost(host) {
  const value = String(host).toLowerCase().replace(/^\[|\]$/g, "");
  return ["localhost", "127.0.0.1", "::1"].includes(value) ? "loopback" : value;
}

function run() {
  const [command, mode] = process.argv.slice(2);
  if (command !== "preflight" || !["browser", "dev"].includes(mode)) fail("usage: accrue_host_preview_custody.sh preflight <browser|dev>");
  const fixtures = fixtureTargets();
  const preview = fixtures ? fixtures.preview : previewIdentity();
  const target = fixtures ? fixtures.target : targetIdentity(mode);
  assertDistinct(preview, target, mode);
}

run();
