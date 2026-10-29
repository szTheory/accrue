#!/usr/bin/env node
// Phase 254 UXQ-04 / D-07: deterministic composer for accrue_admin/priv/static/storybook.css.
//
//   --write       Recompose storybook.css from its inputs and write it in place.
//   --check       Recompose in memory and fail unless the committed file is byte-equal; report the
//                 embedded accrue_admin.css section sha256 against the bundle sha256.
//   --self-test   Run the in-memory fixture scenarios (no filesystem).
//
// storybook.css is the served Storybook sandbox bundle. It has no mix build task, so it was
// recomposed by hand (RESEARCH F2) and silently went stale against priv/static/accrue_admin.css.
// Layout, in order:
//   1. the three verbatim header comment lines of the previous file, then a blank line
//   2. the full PhoenixStorybook sandbox CSS
//   3. the BRAND_MARKER line and accrue/priv/static/brand.css (the --accrue-* tokens the shim and
//      the admin bundle read; the previous hand composition already carried them)
//   4. the BUNDLE_MARKER line and the full priv/static/accrue_admin.css
//   5. a blank line and the dark-mode shim tail, preserved byte-for-byte from the previous file
//      (it starts at SHIM_MARKER and runs to end of file)
// Because the tail is read from the previous file, a deliberate hand edit to the tail survives
// --write; the check pins its position (last, one marker) rather than its bytes.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { isMainModule } from "./main_module.mjs";

export const BRAND_MARKER = "/* === brand.css === */";
export const BUNDLE_MARKER = "/* === accrue_admin.css bundle === */";
export const SHIM_MARKER = "/* === D-17 Spike B: dark-mode class-to-attribute shim === */";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
export const STORYBOOK_CSS = "accrue_admin/priv/static/storybook.css";
export const ADMIN_CSS = "accrue_admin/priv/static/accrue_admin.css";
export const PSB_CSS = "accrue_admin/deps/phoenix_storybook/priv/static/css/phoenix_storybook.css";
export const BRAND_CSS = "accrue/priv/static/brand.css";

function fail(message) {
  return new Error(`Phase 254 storybook.css recompose: ${message}`);
}

const sha256 = (text) => crypto.createHash("sha256").update(text).digest("hex");
const withNewline = (text) => (text.endsWith("\n") ? text : `${text}\n`);

function markerLineStarts(css, marker) {
  const starts = [];
  let from = 0;
  for (;;) {
    const at = css.indexOf(marker, from);
    if (at === -1) return starts;
    if (at === 0 || css[at - 1] === "\n") starts.push(at);
    from = at + marker.length;
  }
}

// The shim tail: the byte range from the SHIM_MARKER line to end of file.
export function extractShimTail(css) {
  const starts = markerLineStarts(css, SHIM_MARKER);
  if (starts.length === 0) throw fail("the previous storybook.css has no dark-mode shim marker line");
  if (starts.length > 1) throw fail("the dark-mode shim marker appears more than once; the tail is ambiguous");
  return css.slice(starts[0]);
}

// The header: the three leading comment lines of the previous file, verbatim.
export function extractHeader(css) {
  const lines = css.split("\n");
  const header = lines.slice(0, 3);
  if (header.length < 3 || !header.every((line) => line.startsWith("/*") && line.endsWith("*/"))) {
    throw fail("the previous storybook.css does not start with the three header comment lines");
  }
  return `${header.join("\n")}\n`;
}

// The admin bundle is minified and may lack a final newline: the separator ends its last line and
// leaves one blank line before the shim tail.
const adminSeparator = (adminCss) => (adminCss.endsWith("\n") ? "\n" : "\n\n");

export function composeStorybookCss({ psbCss, adminCss, brandCss, previous }) {
  for (const [name, value] of Object.entries({ psbCss, adminCss, previous })) {
    if (typeof value !== "string" || value.length === 0) throw fail(`${name} is required`);
  }
  const header = extractHeader(previous);
  const tail = extractShimTail(previous);
  const brand = typeof brandCss === "string" && brandCss.length > 0 ? `${BRAND_MARKER}\n${withNewline(brandCss)}\n` : "";
  return `${header}\n${withNewline(psbCss)}\n${brand}${BUNDLE_MARKER}\n${adminCss}${adminSeparator(adminCss)}${tail}`;
}

function readInputs(root) {
  const read = (relative) => {
    const absolute = path.join(root, relative);
    if (!fs.existsSync(absolute)) {
      throw fail(`input ${relative} is missing${relative === PSB_CSS ? " (run mix deps.get in accrue_admin)" : ""}`);
    }
    return fs.readFileSync(absolute, "utf8");
  };
  return {
    previous: read(STORYBOOK_CSS),
    adminCss: read(ADMIN_CSS),
    psbCss: read(PSB_CSS),
    brandCss: read(BRAND_CSS)
  };
}

// Recompose in memory and compare to the committed file. The embedded accrue_admin.css section is
// located by its literal marker so a stale embed is reported with both digests.
export function checkStorybookCss({ root = ROOT } = {}) {
  const inputs = readInputs(root);
  const tail = extractShimTail(inputs.previous);
  const bundleStarts = markerLineStarts(inputs.previous, BUNDLE_MARKER);
  if (bundleStarts.length !== 1) throw fail(`storybook.css must contain the bundle marker exactly once (found ${bundleStarts.length}); run --write`);
  const sectionStart = bundleStarts[0] + BUNDLE_MARKER.length + 1;
  const tailStart = inputs.previous.length - tail.length;
  const separator = adminSeparator(inputs.adminCss);
  const embedded = inputs.previous.slice(sectionStart, Math.max(sectionStart, tailStart - separator.length));
  const embeddedSha = sha256(embedded);
  const bundleSha = sha256(inputs.adminCss);
  if (embeddedSha !== bundleSha) {
    throw fail(
      `the embedded accrue_admin.css section sha256 ${embeddedSha} does not equal the priv/static/accrue_admin.css sha256 ${bundleSha}; run: node scripts/ci/recompose_storybook_css.mjs --write`
    );
  }
  const expected = composeStorybookCss(inputs);
  if (expected !== inputs.previous) {
    throw fail(
      `storybook.css is not the deterministic composition of its inputs (the PhoenixStorybook, brand.css or layout section drifted); run: node scripts/ci/recompose_storybook_css.mjs --write`
    );
  }
  return { ok: true, embedded_sha256: embeddedSha, bundle_sha256: bundleSha, bytes: Buffer.byteLength(inputs.previous), tail_bytes: Buffer.byteLength(tail) };
}

export function writeStorybookCss({ root = ROOT } = {}) {
  const inputs = readInputs(root);
  const next = composeStorybookCss(inputs);
  const changed = next !== inputs.previous;
  if (changed) fs.writeFileSync(path.join(root, STORYBOOK_CSS), next);
  return { changed, bytes_before: Buffer.byteLength(inputs.previous), bytes_after: Buffer.byteLength(next) };
}

const HEADER = "/* decision line */\n/* served via AccrueAdmin.Assets */\n/* Composition: PSB + admin + shim */\n";
const TAIL = `${SHIM_MARKER}\n/* shim body */\n.psb-sandbox{--ax-x:1}\n`;
const PREVIOUS = `${HEADER}.psb{}\nstale\n${TAIL}`;
const FIXTURE = { psbCss: ".psb{}", brandCss: ":root{--a:1}\n", adminCss: ".ax{}\n", previous: PREVIOUS };

function withFixtureRoot(storybook, fn) {
  const root = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "recompose-self-test-"));
  try {
    const files = {
      [STORYBOOK_CSS]: storybook,
      [ADMIN_CSS]: FIXTURE.adminCss,
      [PSB_CSS]: FIXTURE.psbCss,
      [BRAND_CSS]: FIXTURE.brandCss
    };
    for (const [relative, contents] of Object.entries(files)) {
      fs.mkdirSync(path.dirname(path.join(root, relative)), { recursive: true });
      fs.writeFileSync(path.join(root, relative), contents);
    }
    return fn(root);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

const SCENARIOS = [
  [
    "composition places header, PSB, brand, the literal bundle marker, admin css and the preserved tail in order",
    () => {
      const out = composeStorybookCss(FIXTURE);
      assert.ok(out.startsWith(HEADER));
      assert.ok(out.endsWith(TAIL));
      assert.ok(out.indexOf(".psb{}") < out.indexOf(BRAND_MARKER));
      assert.ok(out.indexOf(BRAND_MARKER) < out.indexOf(BUNDLE_MARKER));
      assert.ok(out.indexOf(BUNDLE_MARKER) < out.indexOf(SHIM_MARKER));
      assert.equal(composeStorybookCss({ ...FIXTURE, previous: out }), out);
    }
  ],
  [
    "a previous file without the shim marker fails (positive control: with the marker it composes)",
    () => {
      assert.throws(() => composeStorybookCss({ ...FIXTURE, previous: `${HEADER}.psb{}\n` }), /shim marker/);
      assert.ok(composeStorybookCss(FIXTURE).length > 0);
    }
  ],
  [
    "check fails when the embedded admin section differs by one byte",
    () => {
      const good = composeStorybookCss(FIXTURE);
      const stale = good.replace(".ax{}", ".aX{}");
      assert.notEqual(stale, good);
      withFixtureRoot(stale, (root) => assert.throws(() => checkStorybookCss({ root }), /does not equal/));
    }
  ],
  [
    "an admin bundle without a trailing newline composes to a fixed point and checks",
    () => {
      const minified = ".ax{}";
      const out = composeStorybookCss({ ...FIXTURE, adminCss: minified });
      assert.ok(out.includes(`${BUNDLE_MARKER}\n${minified}\n\n${SHIM_MARKER}`));
      assert.equal(composeStorybookCss({ ...FIXTURE, adminCss: minified, previous: out }), out);
    }
  ],
  [
    "check passes on an exact composition",
    () => {
      withFixtureRoot(composeStorybookCss(FIXTURE), (root) => {
        const result = checkStorybookCss({ root });
        assert.equal(result.embedded_sha256, result.bundle_sha256);
      });
    }
  ]
];

export const scenarioNames = () => SCENARIOS.map(([name]) => name);
export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

function main(argv = process.argv.slice(2)) {
  const known = new Set(["--write", "--check", "--self-test"]);
  for (const token of argv) if (!known.has(token)) throw fail(`unknown option: ${token}`);
  if (argv.length !== 1) throw fail("exactly one of --write, --check, --self-test is required");
  if (argv[0] === "--self-test") {
    for (const [name, scenario] of SCENARIOS) {
      scenario();
      console.log(`ok - ${name}`);
    }
    console.log(`Phase 254 storybook.css recompose self-test: PASS (${SCENARIOS.length} scenarios)`);
    return;
  }
  if (argv[0] === "--write") {
    const result = writeStorybookCss();
    console.log(
      result.changed
        ? `Phase 254 storybook.css recompose: wrote ${STORYBOOK_CSS} (${result.bytes_before} -> ${result.bytes_after} bytes)`
        : `Phase 254 storybook.css recompose: ${STORYBOOK_CSS} already current`
    );
    return;
  }
  const result = checkStorybookCss();
  console.log(
    `Phase 254 storybook.css recompose: PASS (embedded accrue_admin.css section sha256 ${result.embedded_sha256} equals the bundle sha256 ${result.bundle_sha256}; ${STORYBOOK_CSS} is the deterministic composition, ${result.tail_bytes}-byte shim tail last)`
  );
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("Phase 254") ? error.message : `Phase 254 storybook.css recompose: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
