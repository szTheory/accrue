import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  BRAND_MARKER,
  BUNDLE_MARKER,
  SHIM_MARKER,
  checkStorybookCss,
  composeStorybookCss,
  extractShimTail,
  scenarioNames,
  verifyFixtures
} from "./recompose_storybook_css.mjs";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const SCRIPT = path.join(ROOT, "scripts/ci/recompose_storybook_css.mjs");

const HEADER = "/* decision line */\n/* served via AccrueAdmin.Assets */\n/* Composition: PSB + admin + shim */\n";
const TAIL = `${SHIM_MARKER}\n/* shim body */\n.psb-sandbox{--ax-x:1}\n`;
const PSB = ".psb{color:red}";
const BRAND = ":root{--accrue-ink:#111}\n";
const ADMIN = ".ax-a{color:blue}\n.ax-b{color:green}\n";
const PREVIOUS = `${HEADER}${PSB}\nstale-brand\nstale-admin\n${TAIL}`;

function compose(overrides = {}) {
  return composeStorybookCss({ psbCss: PSB, brandCss: BRAND, adminCss: ADMIN, previous: PREVIOUS, ...overrides });
}

function fixtureRoot(storybook, admin = ADMIN) {
  const root = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "recompose-storybook-"));
  const files = {
    "accrue_admin/priv/static/storybook.css": storybook,
    "accrue_admin/priv/static/accrue_admin.css": admin,
    "accrue_admin/deps/phoenix_storybook/priv/static/css/phoenix_storybook.css": PSB,
    "accrue/priv/static/brand.css": BRAND
  };
  for (const [relative, contents] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(root, relative)), { recursive: true });
    fs.writeFileSync(path.join(root, relative), contents);
  }
  return root;
}

test("composition orders header, PSB css, brand css, the literal bundle marker, admin css and the preserved shim tail", () => {
  const out = compose();
  const order = [HEADER, PSB, BRAND_MARKER, BRAND.trim(), BUNDLE_MARKER, ADMIN.trim().split("\n")[0], TAIL];
  let cursor = -1;
  for (const part of order) {
    const at = out.indexOf(part, cursor + 1);
    assert.ok(at > cursor, `missing or out of order: ${part.slice(0, 40)}`);
    cursor = at;
  }
  assert.equal(BUNDLE_MARKER, "/* === accrue_admin.css bundle === */");
  assert.ok(out.startsWith(HEADER));
  assert.ok(out.endsWith(TAIL), "the shim tail is last and byte-identical");
  assert.equal(extractShimTail(out), TAIL);
  assert.equal(compose({ previous: out }), out, "composing from its own output is a fixed point");
});

test("a previous file without the shim marker fails closed, and a duplicated marker is ambiguous", () => {
  assert.throws(() => compose({ previous: `${HEADER}${PSB}\n` }), /shim marker/);
  assert.throws(() => compose({ previous: `${PREVIOUS}${TAIL}` }), /more than once|ambiguous/);
  assert.throws(() => compose({ previous: "no header\n" + TAIL }), /header/);
  assert.equal(extractShimTail(PREVIOUS), TAIL, "positive control: the same input with one marker yields the tail");
});

test("check fails when the embedded admin section differs from the admin file by one byte", () => {
  const good = compose();
  const stale = good.replace(".ax-b{color:green}", ".ax-b{color:greeN}");
  assert.notEqual(stale, good, "the mutation must change the file");
  const staleRoot = fixtureRoot(stale);
  const goodRoot = fixtureRoot(good);
  try {
    assert.throws(() => checkStorybookCss({ root: staleRoot }), /embedded accrue_admin\.css section sha256 [0-9a-f]{64} does not equal/);
    assert.equal(checkStorybookCss({ root: goodRoot }).ok, true);
  } finally {
    fs.rmSync(staleRoot, { recursive: true, force: true });
    fs.rmSync(goodRoot, { recursive: true, force: true });
  }
});

test("check passes on an exact composition and reports equal section and bundle sha256 values", () => {
  const root = fixtureRoot(compose());
  try {
    const result = checkStorybookCss({ root });
    assert.equal(result.ok, true);
    assert.match(result.embedded_sha256, /^[0-9a-f]{64}$/);
    assert.equal(result.embedded_sha256, result.bundle_sha256);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("an admin bundle without a trailing newline (the minified real shape) composes, checks and is a fixed point", () => {
  const minified = ".ax-a{color:blue}.ax-b{color:green}";
  const out = compose({ adminCss: minified });
  assert.ok(out.includes(`${BUNDLE_MARKER}\n${minified}\n\n${SHIM_MARKER}`));
  assert.equal(compose({ adminCss: minified, previous: out }), out);
  const root = fixtureRoot(out, minified);
  try {
    assert.equal(checkStorybookCss({ root }).embedded_sha256, checkStorybookCss({ root }).bundle_sha256);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("check also rejects a drifted PSB section, a drifted brand section and a missing shim tail", () => {
  const good = compose();
  const roots = [
    fixtureRoot(good.replace(PSB, ".psb{color:RED}")),
    fixtureRoot(good.replace(":root{--accrue-ink:#111}", ":root{--accrue-ink:#222}")),
    fixtureRoot(good.slice(0, good.indexOf(SHIM_MARKER)))
  ];
  try {
    for (const root of roots) assert.throws(() => checkStorybookCss({ root }), /storybook\.css|shim marker/);
  } finally {
    for (const root of roots) fs.rmSync(root, { recursive: true, force: true });
  }
});

test("the real tree is idempotent: --check exits 0 with matching section and bundle sha256", () => {
  const result = spawnSync(process.execPath, [SCRIPT, "--check"], { encoding: "utf8", cwd: ROOT, env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.equal(result.status, 0, result.stderr + result.stdout);
  assert.match(result.stdout, /embedded accrue_admin\.css section sha256 ([0-9a-f]{64}) equals the bundle sha256 \1/);
});

test("--self-test names every scenario and exits 0; an unknown flag fails closed", () => {
  assert.equal(verifyFixtures(), scenarioNames().length);
  const run = spawnSync(process.execPath, [SCRIPT, "--self-test"], { encoding: "utf8", cwd: ROOT, env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.equal(run.status, 0, run.stderr);
  for (const name of scenarioNames()) assert.ok(run.stdout.includes(`ok - ${name}`), `self-test did not name: ${name}`);
  const bad = spawnSync(process.execPath, [SCRIPT, "--nope"], { encoding: "utf8", cwd: ROOT, env: { ...process.env, NODE_TEST_CONTEXT: "" } });
  assert.notEqual(bad.status, 0);
  assert.match(bad.stderr, /unknown option/);
});
