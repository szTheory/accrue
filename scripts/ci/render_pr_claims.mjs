#!/usr/bin/env node
//
// SL-A (quick task 260917-l7v), renderer half.
//
// WHY A PAIR, NOT A TRIAD -- do not "complete" this into a
// collect_ -> render_ -> verify_ triad. The six existing triads in this
// directory COLLECT facts FROM the repository into a records file. Here the
// records file is AUTHORED: the claims are what a human asserts, and the
// measurement happens inside verify_pr_claims.mjs's evaluators. There is no
// collect_ stage, and adding an empty one would be cargo-culting the shape
// without the substance.
//
// This file is the PURE half of the pair. It contains no subprocess call, no
// filesystem write, and no measurement: only the claim-kind argument schemas,
// the pure argument validators, the display-command builders, and the
// deterministic markdown projection. Every execution-bearing concern lives in
// verify_pr_claims.mjs.
//
// Restores the convention stated at scripts/ci/README.md line 29: the
// canonical JSON is the factual authority and its Markdown is a deterministic
// projection. verify_pr_body_contract.mjs was the one artifact that inverted
// that (markdown-first, no records file), and it is precisely the one that
// went vacuous -- its falsifiability check accepted any line containing
// backticks, which is a punctuation check, not a truth check, and three false
// claims shipped through it.
//
// Usage: node scripts/ci/render_pr_claims.mjs --claims <sidecar.json>
// Writes the projected markdown body to stdout. Nothing ever parses that
// output back into a command.

import assert from "node:assert/strict";
import fs from "node:fs";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`pr claims render: FAIL: ${message}`); };

// -- pure argument validators ---------------------------------------------
//
// These run BEFORE any argv is ever constructed (verify_pr_claims.mjs calls
// them at schema-validation time). A value that fails any of them never
// reaches a subprocess at all.

const SHA_PATTERN = /^[0-9a-f]{7,40}$/;
const REF_PATTERN = /^[A-Za-z0-9._/-]{1,120}$/;

export const VALIDATORS = Object.freeze({
  sha(value, where) {
    if (typeof value !== "string") fail(`${where}: expected a SHA string, got ${typeof value}`);
    if (value.startsWith("-")) fail(`${where}: value "${value}" begins with "-" and is rejected outright`);
    if (!SHA_PATTERN.test(value)) fail(`${where}: "${value}" is not a 7-40 character lowercase hex SHA`);
    return value;
  },
  ref(value, where) {
    if (typeof value !== "string") fail(`${where}: expected a ref string, got ${typeof value}`);
    if (value.startsWith("-")) fail(`${where}: value "${value}" begins with "-" and is rejected outright`);
    if (!REF_PATTERN.test(value)) fail(`${where}: ref "${value}" contains a character outside [A-Za-z0-9._/-] or exceeds 120 characters`);
    if (value.includes("..")) fail(`${where}: ref "${value}" contains ".." -- a range must be expressed as two separate typed fields, never one string`);
    if (value.includes("@{")) fail(`${where}: ref "${value}" contains "@{" -- reflog and upstream shorthands are rejected`);
    return value;
  },
  path(value, where) {
    if (typeof value !== "string") fail(`${where}: expected a path string, got ${typeof value}`);
    if (value.startsWith("-")) fail(`${where}: value "${value}" begins with "-" and is rejected outright`);
    if (!value.length) fail(`${where}: path is empty`);
    if (value.startsWith("/")) fail(`${where}: path "${value}" is absolute; paths must be repository-relative`);
    if (value.split("/").includes("..")) fail(`${where}: path "${value}" contains a ".." segment`);
    return value;
  },
  integer(value, where) {
    if (typeof value !== "number" || !Number.isSafeInteger(value) || value < 0) {
      fail(`${where}: expected a non-negative safe integer, got ${JSON.stringify(value)}`);
    }
    return value;
  },
  boolean(value, where) {
    if (typeof value !== "boolean") fail(`${where}: expected a boolean, got ${JSON.stringify(value)}`);
    return value;
  },
  string(value, where) {
    if (typeof value !== "string" || !value.trim()) fail(`${where}: expected a non-empty string`);
    return value;
  },
  date(value, where) {
    if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) fail(`${where}: expected an ISO date YYYY-MM-DD, got ${JSON.stringify(value)}`);
    return value;
  }
});

// -- the frozen claim-kind table (schemas + display strings) ---------------
//
// `args` names each typed argument's validator. `expected` names the
// validator for the asserted value. `renderCommand` builds the string a HUMAN
// pastes into a terminal.
//
// renderCommand's output is OUTPUT ONLY. Nothing anywhere parses it back into
// a command, an argv, or a shell word -- verify_pr_claims.mjs measures from
// the TYPED FIELDS, never from this string. This is the line a future
// maintainer is most likely to undo, so it is stated here, immediately above
// the function it constrains.
export const CLAIM_KINDS = Object.freeze({
  merge_count: Object.freeze({
    args: Object.freeze({ base: "ref", head: "ref" }),
    expected: "integer",
    refFields: Object.freeze(["base", "head"]),
    renderCommand: (claim) => `git rev-list --count --merges ${claim.base}..${claim.head}`
  }),
  commit_reachable: Object.freeze({
    args: Object.freeze({ ancestor: "ref", descendant: "ref" }),
    expected: "boolean",
    refFields: Object.freeze(["ancestor", "descendant"]),
    renderCommand: (claim) => `git merge-base --is-ancestor ${claim.ancestor} ${claim.descendant} && echo true || echo false`
  }),
  path_exists: Object.freeze({
    args: Object.freeze({ path: "path" }),
    expected: "boolean",
    refFields: Object.freeze([]),
    renderCommand: (claim) => `test -e ${claim.path} && echo true || echo false`
  }),
  file_sha256: Object.freeze({
    args: Object.freeze({ path: "path" }),
    expected: "string",
    refFields: Object.freeze([]),
    renderCommand: (claim) => `shasum -a 256 ${claim.path} | cut -d' ' -f1`
  }),
  fixed_string_count: Object.freeze({
    args: Object.freeze({ path: "path", needle: "string" }),
    expected: "integer",
    refFields: Object.freeze([]),
    renderCommand: (claim) => `grep -c -F -- ${JSON.stringify(claim.needle)} ${claim.path}`
  }),
  tracked_path_count: Object.freeze({
    args: Object.freeze({ pathspec: "path" }),
    expected: "integer",
    refFields: Object.freeze([]),
    renderCommand: (claim) => `git ls-files -- ${claim.pathspec} | wc -l`
  }),
  // The waiver pressure-valve, reusing this repo's expiring-waiver idiom. It
  // is NOT a measurement: it records a human attestation with an owner and a
  // hard expiry, and verify_pr_claims.mjs fails it once past expires_on. Hard
  // caps (at most 2, and at most 20% of all claims) live in the verifier.
  attested: Object.freeze({
    args: Object.freeze({ reason: "string", owner: "string", expires_on: "date", approving_sha: "sha" }),
    expected: "boolean",
    refFields: Object.freeze([]),
    renderCommand: (claim) => `# attested by ${claim.owner}, expires ${claim.expires_on}, approving sha ${claim.approving_sha}`
  })
});

export const CLAIM_ID_MARKER = /\[claim:([A-Za-z0-9_-]+)\]/g;

export function renderExpected(value) {
  return typeof value === "string" ? value : JSON.stringify(value);
}

// -- the deterministic markdown projection --------------------------------

export function renderClaimBlock(claim) {
  const kind = CLAIM_KINDS[claim.kind];
  if (!kind) fail(`claim ${claim.id}: unknown kind "${claim.kind}"; the frozen table declares: ${Object.keys(CLAIM_KINDS).join(", ")}`);
  const lines = [`- ${claim.text} [claim:${claim.id}]`];
  lines.push(`  Verify: \`${kind.renderCommand(claim)}\` -> \`${renderExpected(claim.expected)}\`.`);
  for (const note of claim.notes || []) lines.push(note);
  return lines;
}

export function renderBody(sidecar) {
  if (!sidecar || typeof sidecar !== "object") fail("sidecar is not an object");
  if (!Array.isArray(sidecar.body) || sidecar.body.length === 0) fail("sidecar.body must be a non-empty array of blocks");
  const claims = new Map((sidecar.claims || []).map((claim) => [claim.id, claim]));
  const lines = [];
  for (const block of sidecar.body) {
    if (block.kind === "markdown") {
      if (!Array.isArray(block.lines)) fail("a markdown block has no lines array");
      lines.push(...block.lines);
      continue;
    }
    if (block.kind === "claim") {
      const claim = claims.get(block.id);
      if (!claim) fail(`body references claim id "${block.id}" which is absent from sidecar.claims`);
      lines.push(...renderClaimBlock(claim));
      continue;
    }
    fail(`unknown body block kind "${block.kind}" (expected "markdown" or "claim")`);
  }
  return lines.join("\n") + "\n";
}

// -- fixtures --------------------------------------------------------------

function sampleSidecar() {
  return {
    schema: 1,
    repository: "szTheory/accrue",
    claims: [
      { id: "C1", kind: "merge_count", base: "origin/main", head: "origin/topic", expected: 4, text: "The branch carries four internal merges." },
      { id: "C2", kind: "path_exists", path: ".planning/FIXTURE.md", expected: false, text: "The shadow directory is gone.", notes: ["  Extra authored note line."] }
    ],
    body: [
      { kind: "markdown", lines: ["## What a reviewer would reject this for", ""] },
      { kind: "claim", id: "C1" },
      { kind: "claim", id: "C2" },
      { kind: "markdown", lines: [""] }
    ]
  };
}

function scenarioRendersDeterministically() {
  const first = renderBody(sampleSidecar());
  const second = renderBody(sampleSidecar());
  assert.equal(first, second, "the projection must be byte-identical across runs");
  assert.match(first, /\[claim:C1\]/);
  assert.match(first, /Verify: `git rev-list --count --merges origin\/main\.\.origin\/topic` -> `4`\./);
  assert.match(first, /Verify: `test -e \.planning\/FIXTURE\.md && echo true \|\| echo false` -> `false`\./);
  assert.match(first, /^ {2}Extra authored note line\.$/m);
  assert.ok(first.endsWith("\n"));
}

function scenarioUnknownKindInRender() {
  const sidecar = sampleSidecar();
  sidecar.claims[0].kind = "exec_shell";
  assert.throws(() => renderBody(sidecar), /unknown kind "exec_shell"; the frozen table declares/);
}

function scenarioBodyReferencesMissingClaim() {
  const sidecar = sampleSidecar();
  sidecar.claims = sidecar.claims.filter((claim) => claim.id !== "C2");
  assert.throws(() => renderBody(sidecar), /body references claim id "C2" which is absent/);
}

function scenarioUnknownBlockKind() {
  const sidecar = sampleSidecar();
  sidecar.body.push({ kind: "html", lines: ["<script>"] });
  assert.throws(() => renderBody(sidecar), /unknown body block kind "html"/);
}

function scenarioEmptyBodyFails() {
  assert.throws(() => renderBody({ schema: 1, claims: [], body: [] }), /non-empty array of blocks/);
}

function scenarioValidatorsRejectFlagLikeAndTraversal() {
  assert.throws(() => VALIDATORS.ref("--upload-pack=touch /tmp/pwn", "C1.base"), /begins with "-"/);
  assert.throws(() => VALIDATORS.ref("origin/main..HEAD", "C1.base"), /contains "\.\."/);
  assert.throws(() => VALIDATORS.ref("main@{upstream}", "C1.base"), /contains "@\{"|outside \[A-Za-z0-9/);
  assert.throws(() => VALIDATORS.ref("origin/ main", "C1.base"), /outside \[A-Za-z0-9/);
  assert.throws(() => VALIDATORS.sha("ZZZZZZZ", "C1.approving_sha"), /not a 7-40 character lowercase hex SHA/);
  assert.throws(() => VALIDATORS.path("/etc/passwd", "C1.path"), /absolute/);
  assert.throws(() => VALIDATORS.path("../../etc/passwd", "C1.path"), /contains a "\.\." segment/);
  assert.throws(() => VALIDATORS.integer(-1, "C1.expected"), /non-negative safe integer/);
  assert.throws(() => VALIDATORS.integer(1.5, "C1.expected"), /non-negative safe integer/);
  assert.doesNotThrow(() => VALIDATORS.ref("refs/remotes/origin/main", "C1.base"));
  assert.doesNotThrow(() => VALIDATORS.sha("9b50ce6a080b684263de6c53d54e0726df077fa2", "C1.approving_sha"));
}

const SCENARIOS = [
  ["the projection is deterministic and emits a pasteable command plus the claim id marker", scenarioRendersDeterministically],
  ["an unknown claim kind fails the render, naming the frozen table's keys", scenarioUnknownKindInRender],
  ["a body block referencing a claim id absent from the sidecar fails the render", scenarioBodyReferencesMissingClaim],
  ["an unknown body block kind fails the render", scenarioUnknownBlockKind],
  ["a sidecar with an empty body fails the render", scenarioEmptyBodyFails],
  ["the pure validators reject flag-like values, range syntax, traversal, and non-integer expectations", scenarioValidatorsRejectFlagLikeAndTraversal]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

const BOOLEAN_FLAGS = new Set(["fixtures"]);
const VALUE_OPTIONS = new Set(["claims"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    if (key in values) fail(`--${key} may be provided only once`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    console.log(`pr claims render: PASS (fixtures: ${count} scenarios)`);
    return;
  }
  if (!parsed.values.claims) fail("--claims is required");
  if (!fs.existsSync(parsed.values.claims)) fail(`claims sidecar does not exist: ${parsed.values.claims}`);
  const sidecar = JSON.parse(fs.readFileSync(parsed.values.claims, "utf8"));
  process.stdout.write(renderBody(sidecar));
}

// D-29: isMainModule() throws (never returns a silent false) when there is no
// invoking entrypoint; caught here and treated as "not the entrypoint" so a
// bare import stays side-effect-free (established pattern, 232-01).
let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("pr claims render:") ? error.message : `pr claims render: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
