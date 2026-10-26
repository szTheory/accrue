#!/usr/bin/env node
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import assert from "node:assert/strict";
import { isMainModule } from "./main_module.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const routeAuthority = path.join(root, ".planning/milestones/v1.63-phases/239-integrated-quality-handoff/239-COVERAGE.md");
const requiredRequirements = ["DSN-01", "DSN-02", "DSN-03", "DSN-04", "DSN-05", "UXC-02", "EVR-01", "EVR-02"];

function fail(message) {
  console.error(`Phase 240 evidence invalid: ${message}`);
  process.exitCode = 1;
  return false;
}

function expectedRoutes() {
  const source = readFileSync(routeAuthority, "utf8");
  return source.split("\n").flatMap((line) => {
    if (!line.startsWith("| package_route | /admin |")) return [];
    const cells = line.split("|").map((cell) => cell.trim());
    return cells[4] === "GET production LiveView" ? [cells[3]] : [];
  });
}

function registryCounts() {
  const expression = [
    "entries = AccrueAdmin.Dev.ComponentRegistry.entries()",
    "families = entries |> Enum.map(& &1.family) |> Enum.uniq() |> length()",
    "groups = AccrueAdmin.Dev.ComponentRegistry.group_contracts() |> length()",
    "IO.puts(\"PHASE240_COUNTS=#{families},#{length(entries)},#{groups}\")"
  ].join("; ");
  const result = spawnSync("mix", ["run", "-e", expression], { cwd: path.join(root, "accrue_admin"), encoding: "utf8", env: { ...process.env, MIX_ENV: "test" } });
  if (result.status !== 0) throw new Error(`could not read incumbent component registry: ${result.stderr || result.stdout}`);
  const match = `${result.stdout}\n${result.stderr}`.match(/PHASE240_COUNTS=(\d+),(\d+),(\d+)/);
  if (!match) throw new Error("incumbent ComponentRegistry emitted no count record");
  return match.slice(1).map(Number);
}

function validate(file) {
  let markdown;
  try { markdown = readFileSync(file, "utf8"); }
  catch (error) { return fail(`cannot read ${file}: ${error.message}`); }

  const requiredHeadings = [
    "## Route and owner inventory",
    "### State applicability",
    "## Requirement to recurring owner map",
    "## Mounted Phase 237 exemplar record",
    "## Current changed-owner acceptance results"
  ];
  for (const heading of requiredHeadings) if (!markdown.includes(heading)) return fail(`missing required field/section: ${heading}`);

  const expected = expectedRoutes();
  if (expected.length !== 21) return fail(`route authority currently yields ${expected.length} production Admin LiveViews, expected 21`);
  const section = markdown.split("## Route and owner inventory")[1]?.split("### State applicability")[0] ?? "";
  const rows = section.split("\n").filter((line) => line.startsWith("| `/admin"));
  const routeRows = rows.map((line) => {
    const cells = line.split("|").map((cell) => cell.trim());
    return { route: cells[1]?.replaceAll("`", ""), family: cells[2], states: cells[3], ownerCell: cells[4], status: cells[5] };
  });
  const routes = routeRows.map((row) => row.route);
  if (routes.length !== expected.length) {
    const missing = expected.filter((route) => !routes.includes(route));
    return fail(`expected ${expected.length} route rows; omitted required route: ${missing[0] ?? "unknown"}`);
  }
  if (new Set(routes).size !== routes.length) return fail("duplicate route identity");
  for (const route of expected) if (!routes.includes(route)) return fail(`omitted required route: ${route}`);

  const ownerRefs = [];
  for (const row of routeRows) {
    if (!row.family || !row.states || !row.ownerCell || !row.status) return fail(`route row is missing family/state/owner/evidence status: ${row.route}`);
    if (!/(exercised|source-only|historical)/.test(row.status)) return fail(`invalid evidence status for ${row.route}`);
    const refs = [...row.ownerCell.matchAll(/`([^`]+)`/g)].map((match) => match[1]);
    if (refs.length === 0) return fail(`missing owner reference for ${row.route}`);
    for (const ref of refs) {
      if (/^(mix test|host integration gate|full Admin ExUnit)/.test(ref)) continue;
      if (/^phase\d+-.+\.spec\.js$/.test(ref)) {
        if (!readableRepoPath(`examples/accrue_host/e2e/${ref}`)) return fail(`mounted owner is not present: ${ref}`);
      } else if (ref.startsWith("examples/")) {
        if (!markdown.includes(ref)) return fail(`owner reference not recorded: ${ref}`);
      } else if (!readableRepoPath(ref)) return fail(`owner reference is not present in current source: ${ref}`);
      ownerRefs.push(ref);
    }
  }
  if (new Set(ownerRefs).size !== ownerRefs.length) return fail("owner references must be unique per route row");

  for (const requirement of requiredRequirements) {
    if (!markdown.includes(`| ${requirement} |`)) return fail(`missing requirement mapping: ${requirement}`);
  }
  if (!/N\/A.{0,220}(because|no |not |remain|does not)/is.test(markdown)) return fail("missing N/A state applicability rationale");
  if (!/30 component families/.test(markdown) || !/42 variants/.test(markdown) || !/8 groups/.test(markdown)) return fail("missing incumbent registry family/variant/group counts");
  if (!/component modules/.test(markdown)) return fail("missing separately identified source component-module inventory");
  const modules = spawnSync("find", [path.join(root, "accrue_admin/lib/accrue_admin/components"), "-type", "f", "-name", "*.ex"], { encoding: "utf8" });
  if (modules.status !== 0) return fail("could not inspect current source component modules");
  const moduleCount = modules.stdout.trim() ? modules.stdout.trim().split("\n").length : 0;
  if (moduleCount !== 43 || !new RegExp(`\\b${moduleCount} source component modules\\b`).test(markdown)) return fail(`source component module count mismatch (live ${moduleCount}, ledger must state 43)`);
  const [families, variants, groups] = registryCounts();
  if (families !== 30 || variants !== 42 || groups !== 8) return fail(`incumbent registry changed: live ${families}/${variants}/${groups}, documented 30/42/8`);
  if (!markdown.includes("host `/admin` is Admin") || !markdown.includes("host `/billing` is Portal") || !markdown.includes("package fixture `/billing` is Admin")) return fail("host Admin/Portal and package Admin mount identities must be explicit");
  if (!markdown.includes("no invented SLA") || !markdown.includes("Preview Fake DB is never selected")) return fail("missing resource-SLA or disposable-preview boundary statement");
  return true;
}

function readableRepoPath(relative) {
  if (path.isAbsolute(relative) || relative.split(/[\\/]/).includes("..")) return false;
  try { readFileSync(path.join(root, relative)); return true; }
  catch { return false; }
}


function runCli(args) {
  const env = { ...process.env };
  delete env.NODE_TEST_CONTEXT;
  return spawnSync(process.execPath, [fileURLToPath(import.meta.url), ...args], { encoding: "utf8", shell: false, env });
}

function registerTests() {
  test("rejects a ledger missing required sections", () => {
    const dir = mkdtempSync(path.join(os.tmpdir(), "phase240-fixture-"));
    try {
      const ledger = path.join(dir, "ledger.md");
      writeFileSync(ledger, "# empty ledger\n");
      const result = runCli([ledger]);
      assert.notEqual(result.status, 0);
      assert.match(result.stderr, /missing required field\/section/);
    } finally { rmSync(dir, { recursive: true, force: true }); }
  });

  test("rejects a ledger that omits a required route row", () => {
    const dir = mkdtempSync(path.join(os.tmpdir(), "phase240-fixture-"));
    try {
      const routes = expectedRoutes();
      assert.equal(routes.length, 21);
      const rows = routes.slice(1).map((route) => `| \`${route}\` | family | states | \`owner\` | exercised |`);
      const ledger = path.join(dir, "ledger.md");
      writeFileSync(ledger, [
        "## Route and owner inventory", "", ...rows, "", "### State applicability",
        "## Requirement to recurring owner map", "## Mounted Phase 237 exemplar record",
        "## Current changed-owner acceptance results", ""
      ].join("\n"));
      const result = runCli([ledger]);
      assert.notEqual(result.status, 0);
      assert.ok(result.stderr.includes(`omitted required route: ${routes[0]}`), result.stderr);
    } finally { rmSync(dir, { recursive: true, force: true }); }
  });
}

function main() {
  const ledgerArg = process.argv.at(-1);
if (process.argv.includes("--self-test")) {
  const real = process.argv.at(-1);
  if (!validate(path.resolve(root, real))) process.exit(1);
  const original = readFileSync(path.resolve(root, real), "utf8");
  const omittedRoute = expectedRoutes()[0];
  const omittedRow = original.split("\n").find((line) => line.startsWith(`| \`${omittedRoute}\` |`));
  if (!omittedRow) { fail(`self-test could not locate required route ${omittedRoute}`); process.exit(1); }
  const temp = mkdtempSync(path.join(os.tmpdir(), "phase240-evidence-"));
  try {
    const copy = path.join(temp, "240-COVERAGE.md");
    writeFileSync(copy, original.replace(`${omittedRow}\n`, ""));
    const rejection = spawnSync(process.execPath, [fileURLToPath(import.meta.url), copy], { encoding: "utf8" });
    const output = `${rejection.stdout}\n${rejection.stderr}`;
    if (rejection.status === 0 || !output.includes(omittedRoute)) {
      fail(`missing-route negative was not rejected with route-specific diagnostic: ${omittedRoute}`);
      process.exit(1);
    }
  } finally { rmSync(temp, { recursive: true, force: true }); }
  console.log("self-test: valid=1 missing-route-rejected=1");
  process.exit(0);
}

if (!ledgerArg || !validate(path.resolve(root, ledgerArg))) process.exit(1);
console.log(`Phase 240 evidence valid: ${expectedRoutes().length} routes; 8 requirements; registry 30/42/8; 43 source component modules.`);
}

let entry = false;
try {
  entry = isMainModule(import.meta.url);
} catch {
  entry = false;
}

if (entry && process.env.NODE_TEST_CONTEXT) {
  registerTests();
} else if (entry) {
  main();
}
