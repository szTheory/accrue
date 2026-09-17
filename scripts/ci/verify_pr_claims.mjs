#!/usr/bin/env node
//
// SL-A (quick task 260917-l7v), verifier half. Pairs with
// render_pr_claims.mjs -- see that file's header for WHY THIS IS A PAIR AND
// NOT A TRIAD.
//
// THE RULE THAT DEFINES THIS DESIGN:
//   no string from any committed file ever becomes a program name, a flag, or
//   a shell word.
// Program name and flags come from the frozen EVALUATORS table below and from
// nowhere else. Committed values are typed scalars, schema-validated by
// render_pr_claims.mjs's pure VALIDATORS before any argv is constructed, and
// every ref-shaped value is first resolved to a self-produced 40-hex SHA
// (through `rev-parse --verify --end-of-options`) so the only strings that
// reach a range expression are ones this file generated. That sentence is the
// invariant a future reviewer checks this file against.
//
// An earlier revision of this design proposed executing commands parsed out
// of the markdown inside a hardened sandbox. It was overturned and must not
// be reintroduced. The prefix allowlist it relied on was not sound: git
// accepts unambiguous long-option abbreviations (the mechanism behind
// GHSA-2f96-g7mh-g2hx), and a PR tree can ship .gitattributes/.gitmodules
// wiring diff.external or a textconv filter and obtain execution with no
// argument injection at all.
//
// NO KIND MAY PERFORM NETWORK I/O. A claim about a CI run conclusion must be
// a LINK in the body, not an assertion. That boundary is what keeps the
// evaluator table auditable at a glance; do not add a kind that fetches.
//
// FAIL-CLOSED SET. Unknown kind, schema violation, argument-validation
// failure, evaluator error, evaluator timeout, output exceeding the bounded
// buffer, measured-vs-expected mismatch, re-render mismatch, a body claim-id
// marker with no backing claim, a claim id absent from the body, or a sidecar
// below the --min-executed floor => FAIL. Never skip, never warn. A skip path
// is how the gate this replaces went vacuous.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { spawnSync } from "node:child_process";
import { isMainModule } from "./main_module.mjs";
import { CLAIM_KINDS, CLAIM_ID_MARKER, VALIDATORS, renderBody, renderExpected } from "./render_pr_claims.mjs";

const fail = (message) => { throw new Error(`pr claims: FAIL: ${message}`); };

const DEFAULT_TIMEOUT_MS = 10_000;
const MAX_TIMEOUT_MS = 60_000;
const MAX_BUFFER_BYTES = 1_000_000;
const LOCK_PATTERN = /index\.lock|Unable to create .*\.lock/i;

// Forced on EVERY invocation. The first two close the in-tree
// .gitattributes / hooks vector that a scrubbed HOME alone does not: a PR
// worktree is untrusted content, and `core.attributesFile`/`core.hooksPath`
// are read from the tree, not from HOME.
const GIT_HARDENING = Object.freeze([
  "--no-optional-locks",
  "-c", "core.attributesFile=/dev/null",
  "-c", "core.hooksPath=/dev/null",
  "-c", "protocol.ext.allow=never"
]);

// Replaced, never inherited.
function hardenedEnv() {
  return {
    PATH: process.env.PATH || "/usr/bin:/bin",
    LANG: "C",
    LC_ALL: "C",
    GIT_CONFIG_GLOBAL: "/dev/null",
    GIT_CONFIG_SYSTEM: "/dev/null",
    GIT_TERMINAL_PROMPT: "0",
    GIT_ASKPASS: "",
    GIT_ALLOW_PROTOCOL: ""
  };
}

// Exported so the timeout and bounded-buffer failure paths are unit-testable
// against synthetic spawnSync-shaped results. Neither is ever truncated into
// a pass: both raise.
export function classifyRunResult(result, args) {
  const shown = args.join(" ");
  if (result.error) {
    const code = result.error.code;
    if (code === "ETIMEDOUT") fail(`evaluator timed out running \`git ${shown}\` -- a timeout is a FAILURE, never a truncated comparison`);
    if (code === "ENOBUFS") fail(`evaluator output exceeded the ${MAX_BUFFER_BYTES}-byte bounded buffer running \`git ${shown}\` -- refusing to compare truncated output`);
    return { retryable: false, error: `git ${shown} failed: ${String(result.error.message || code).slice(0, 400)}` };
  }
  if (result.signal) fail(`evaluator was killed by ${result.signal} running \`git ${shown}\` -- treated as a timeout, never as a pass`);
  if (result.status !== 0) {
    const stderr = (result.stderr || "").trim();
    return { retryable: LOCK_PATTERN.test(stderr), error: `git ${shown} exited ${result.status}: ${stderr.slice(0, 400)}` };
  }
  return { retryable: false, stdout: result.stdout };
}

// Retries ONLY on classified lock contention. A blanket retry would convert a
// real failure into a slow real failure.
function runGit(repo, args, timeoutMs) {
  let last = "";
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const result = spawnSync("git", [...GIT_HARDENING, "-C", repo, ...args], {
      shell: false,
      encoding: "utf8",
      timeout: timeoutMs,
      maxBuffer: MAX_BUFFER_BYTES,
      env: hardenedEnv()
    });
    const classified = classifyRunResult(result, args);
    if (classified.stdout !== undefined) return classified.stdout;
    last = classified.error;
    if (!classified.retryable) fail(last);
    spawnSync(process.execPath, ["-e", "setTimeout(()=>{},150)"], { timeout: 2000 });
  }
  fail(`${last} (retried 3 times on classified lock contention)`);
  return "";
}

// Resolves a validated ref-shaped value to a 40-hex commit SHA. From here on
// the only strings reaching a range expression are ones this file produced.
// `--end-of-options` is the correct literal separator for a REVISION operand
// (a bare `--` would make git read the value as a PATH).
function resolveCommit(repo, value, timeoutMs, where) {
  VALIDATORS.ref(value, where);
  const out = runGit(repo, ["rev-parse", "--verify", "--end-of-options", `${value}^{commit}`], timeoutMs).trim();
  if (!/^[0-9a-f]{40}$/.test(out)) fail(`${where}: "${value}" did not resolve to a commit SHA`);
  return out;
}

function readRepoFile(repo, relative, where) {
  VALIDATORS.path(relative, where);
  return path.join(repo, relative);
}

// -- the frozen evaluator table -------------------------------------------
//
// Keyed identically to render_pr_claims.mjs's CLAIM_KINDS (a key-set
// mismatch is its own negative control). `path_exists`, `file_sha256`, and
// `fixed_string_count` deliberately use Node built-ins rather than shelling
// out at all -- the smallest blast radius available for those three.
export const EVALUATORS = Object.freeze({
  merge_count(repo, claim, timeoutMs) {
    const base = resolveCommit(repo, claim.base, timeoutMs, `${claim.id}.base`);
    const head = resolveCommit(repo, claim.head, timeoutMs, `${claim.id}.head`);
    return Number(runGit(repo, ["rev-list", "--count", "--merges", head, "--not", base], timeoutMs).trim());
  },
  commit_reachable(repo, claim, timeoutMs) {
    const ancestor = resolveCommit(repo, claim.ancestor, timeoutMs, `${claim.id}.ancestor`);
    const descendant = resolveCommit(repo, claim.descendant, timeoutMs, `${claim.id}.descendant`);
    return Number(runGit(repo, ["rev-list", "--count", ancestor, "--not", descendant], timeoutMs).trim()) === 0;
  },
  path_exists(repo, claim) {
    return fs.existsSync(readRepoFile(repo, claim.path, `${claim.id}.path`));
  },
  file_sha256(repo, claim) {
    const target = readRepoFile(repo, claim.path, `${claim.id}.path`);
    if (!fs.existsSync(target)) fail(`${claim.id}: file_sha256 target does not exist: ${claim.path}`);
    return crypto.createHash("sha256").update(fs.readFileSync(target)).digest("hex");
  },
  fixed_string_count(repo, claim) {
    const target = readRepoFile(repo, claim.path, `${claim.id}.path`);
    if (!fs.existsSync(target)) fail(`${claim.id}: fixed_string_count target does not exist: ${claim.path}`);
    const text = fs.readFileSync(target, "utf8");
    return text.split("\n").filter((line) => line.includes(claim.needle)).length;
  },
  tracked_path_count(repo, claim, timeoutMs) {
    VALIDATORS.path(claim.pathspec, `${claim.id}.pathspec`);
    const out = runGit(repo, ["ls-files", "-z", "--", claim.pathspec], timeoutMs);
    return out.split("\0").filter(Boolean).length;
  },
  // Not a measurement. Expiry, owner, and the hard caps are enforced by
  // assertAttestedLimits before this ever runs.
  attested(repo, claim) {
    return claim.expected;
  }
});

function assertTablesAgree() {
  const kinds = Object.keys(CLAIM_KINDS).sort().join(",");
  const evaluators = Object.keys(EVALUATORS).sort().join(",");
  if (kinds !== evaluators) fail(`the render table and the evaluator table disagree: render declares [${kinds}] but evaluators declare [${evaluators}]`);
}

// -- schema ---------------------------------------------------------------

export function assertSchema(sidecar) {
  assertTablesAgree();
  if (!sidecar || typeof sidecar !== "object") fail("sidecar is not a JSON object");
  if (sidecar.schema !== 1) fail(`unsupported sidecar schema ${JSON.stringify(sidecar.schema)} (expected 1)`);
  if (!Array.isArray(sidecar.claims)) fail("sidecar.claims must be an array");
  const seen = new Set();
  for (const claim of sidecar.claims) {
    if (!claim || typeof claim !== "object") fail("a claim entry is not an object");
    VALIDATORS.string(claim.id, "claim.id");
    if (seen.has(claim.id)) fail(`duplicate claim id "${claim.id}"`);
    seen.add(claim.id);
    VALIDATORS.string(claim.text, `${claim.id}.text`);
    const kind = CLAIM_KINDS[claim.kind];
    if (!kind) {
      fail(`claim ${claim.id}: unknown kind "${claim.kind}"; the frozen table declares: ${Object.keys(CLAIM_KINDS).join(", ")}. An unknown kind is never skipped.`);
    }
    for (const [field, validator] of Object.entries(kind.args)) {
      if (!(field in claim)) fail(`claim ${claim.id} (kind ${claim.kind}) is missing required argument "${field}"`);
      VALIDATORS[validator](claim[field], `${claim.id}.${field}`);
    }
    if (!("expected" in claim)) fail(`claim ${claim.id} is missing "expected"`);
    VALIDATORS[kind.expected](claim.expected, `${claim.id}.expected`);
    for (const note of claim.notes || []) VALIDATORS.string(note, `${claim.id}.notes[]`);
  }
  return sidecar.claims.length;
}

export function assertExpectedRepository(sidecar, expectedRepository) {
  if (!expectedRepository) return;
  if (sidecar.repository !== expectedRepository) {
    fail(`sidecar declares repository "${sidecar.repository}" which does not match --expected-repository ${expectedRepository}`);
  }
}

// -- attested caps ---------------------------------------------------------

export function assertAttestedLimits(claims, today = new Date()) {
  const attested = claims.filter((claim) => claim.kind === "attested");
  for (const claim of attested) {
    const expiry = new Date(`${claim.expires_on}T23:59:59Z`);
    if (Number.isNaN(expiry.getTime())) fail(`attested claim ${claim.id}: expires_on "${claim.expires_on}" is not a date`);
    if (today > expiry) fail(`attested claim ${claim.id} expired on ${claim.expires_on} (owner: ${claim.owner}) -- re-measure it or renew it explicitly`);
  }
  if (attested.length > 2) fail(`${attested.length} attested claims exceed the hard cap of 2`);
  if (claims.length > 0 && attested.length / claims.length > 0.2) {
    fail(`attested claims are ${attested.length}/${claims.length} (${Math.round((attested.length / claims.length) * 100)}%) of all claims, above the 20% cap`);
  }
}

// -- workflow trigger interlock -------------------------------------------
//
// Retained DELIBERATELY even though it is no longer load-bearing for safety
// under the typed design. It is an interlock: it goes red BEFORE the blast
// radius changes rather than after. Do not delete it as redundant.
export function assertNoPullRequestTarget(repo) {
  const dir = path.join(repo, ".github", "workflows");
  if (!fs.existsSync(dir)) fail(`no .github/workflows directory found under ${repo} -- refusing to report a trigger-surface pass over zero inspected files`);
  const files = fs.readdirSync(dir).filter((name) => name.endsWith(".yml") || name.endsWith(".yaml"));
  if (files.length === 0) fail("zero workflow files inspected -- refusing to report a trigger-surface pass");
  for (const name of files) {
    const text = fs.readFileSync(path.join(dir, name), "utf8");
    for (const [index, line] of text.split("\n").entries()) {
      if (/^\s*pull_request_target\s*:/.test(line.replace(/#.*$/, ""))) {
        fail(`.github/workflows/${name} line ${index + 1} declares a pull_request_target trigger; the evaluator's blast radius must not widen silently`);
      }
    }
  }
  return files.length;
}

// -- SL-B: ref fields must name explicit remote refs ----------------------
//
// ROOT CAUSE this encodes: a claim computed against local `main` is read by a
// reviewer against `origin/main`. During phase 232 that produced a merge count
// asserted as 3, "corrected" to 9, where 9 was right only against a
// 4-commit-stale local `main` -- a fresh clone yields 4. An `origin/`-explicit
// claim is reproducible by the reviewer; a bare one is not, and the reviewer
// has no way to tell which one they are looking at. (Measured again while this
// guard was written: in this very repository `main..origin/integration/…`
// reports 12 merges while `origin/main..origin/integration/…` reports 8.)
//
// Under the typed design this is a VALIDATION RULE ON A SCHEMA FIELD, not text
// analysis: it inspects only values whose declared argument type in
// CLAIM_KINDS[kind].args is "ref", so a path, a prose mention, or a SHA can
// never trip it. Ref hygiene and claim truth are separate properties -- a bare
// ref fails here even when its `expected` value is currently correct, and
// there is a named scenario proving that separation.
export const WELL_KNOWN_LOCAL_REF = /^(main|master|develop|trunk|release)$/;

export function assertRemoteRefsExplicit(claims) {
  if (!Array.isArray(claims)) fail("remote-ref check was handed something that is not a claims array");
  let inspected = 0;
  for (const claim of claims) {
    const kind = CLAIM_KINDS[claim.kind];
    if (!kind) fail(`claim ${claim.id}: unknown kind "${claim.kind}"`);
    for (const [field, validator] of Object.entries(kind.args)) {
      if (validator !== "ref") continue;
      const value = claim[field];
      inspected += 1;
      // A 7-40 hex SHA is unambiguous in every clone and needs no remote
      // qualification.
      if (/^[0-9a-f]{7,40}$/.test(value)) continue;
      if (value.startsWith("origin/") || value.startsWith("refs/remotes/")) continue;
      if (WELL_KNOWN_LOCAL_REF.test(value)) {
        fail(`claim ${claim.id}: ${field} names the bare local branch "${value}", which resolves differently in every clone; write "origin/${value}". A well-known branch name never qualifies for the local_ref_reason escape.`);
      }
      const reason = claim.local_ref_reason;
      if (typeof reason !== "string" || !reason.trim()) {
        fail(`claim ${claim.id}: ${field} names "${value}", which is neither a SHA nor an origin/-qualified ref; write "origin/${value}", or record why it is local-only in a non-empty "local_ref_reason" on the same claim.`);
      }
    }
  }
  // Deliberately NOT a zero-inspected hard failure: ref-typed arguments are
  // optional per claim kind, and a sidecar built entirely from
  // content-addressed claims legitimately declares none. The count is printed
  // instead, and the rule's own non-vacuity is carried by the --fixtures
  // scenarios, which the same merge-blocking CI step runs with this flag set.
  return inspected;
}

// -- the mutual render join -----------------------------------------------

export function assertRenderJoin(sidecar, bodyText) {
  const rendered = renderBody(sidecar);
  if (rendered !== bodyText) {
    const a = rendered.split("\n"); const b = bodyText.split("\n");
    let line = 0;
    while (line < Math.max(a.length, b.length) && a[line] === b[line]) line += 1;
    fail(`the committed body is not byte-exactly re-derivable from the sidecar; first difference at line ${line + 1}\n  rendered: ${JSON.stringify(a[line])}\n  committed: ${JSON.stringify(b[line])}`);
  }
}

export function assertClaimIdJoin(sidecar, bodyText) {
  const declared = new Set(sidecar.claims.map((claim) => claim.id));
  const inBody = new Set([...bodyText.matchAll(CLAIM_ID_MARKER)].map((match) => match[1]));
  for (const id of inBody) {
    if (!declared.has(id)) fail(`the body carries claim id marker [claim:${id}] which is absent from the sidecar's claims`);
  }
  for (const id of declared) {
    if (!inBody.has(id)) fail(`sidecar claim "${id}" never appears in the body -- an unpublished claim is not a claim`);
  }
}

// -- evaluation ------------------------------------------------------------

export function evaluateClaims(repo, sidecar, { timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > MAX_TIMEOUT_MS) {
    fail(`--timeout-ms must be a positive integer no greater than ${MAX_TIMEOUT_MS}`);
  }
  let executed = 0;
  for (const claim of sidecar.claims) {
    const measured = EVALUATORS[claim.kind](repo, claim, timeoutMs);
    if (measured !== claim.expected) {
      fail(`claim ${claim.id} (${claim.kind}) asserts ${JSON.stringify(claim.expected)} but the measured value is ${JSON.stringify(measured)}\n  reproduce: ${CLAIM_KINDS[claim.kind].renderCommand(claim)}`);
    }
    executed += 1;
  }
  return executed;
}

export function verifyClaims(repo, sidecar, bodyText, options = {}) {
  const {
    requireClaims = false,
    requireRenderJoin = false,
    requireRemoteRefs = false,
    requireNoPullRequestTarget = false,
    expectedRepository,
    minExecuted,
    timeoutMs = DEFAULT_TIMEOUT_MS
  } = options;

  const declared = assertSchema(sidecar);
  assertExpectedRepository(sidecar, expectedRepository);
  assertAttestedLimits(sidecar.claims);
  let refFields = 0;
  if (requireRemoteRefs) refFields = assertRemoteRefsExplicit(sidecar.claims);
  if (requireNoPullRequestTarget) assertNoPullRequestTarget(repo);
  if (requireRenderJoin) {
    if (typeof bodyText !== "string") fail("--require-render-join needs --body");
    assertRenderJoin(sidecar, bodyText);
    assertClaimIdJoin(sidecar, bodyText);
  }
  let executed = 0;
  if (requireClaims) executed = evaluateClaims(repo, sidecar, { timeoutMs });
  if (minExecuted !== undefined) {
    if (executed < minExecuted) fail(`only ${executed} claims were evaluated, below the --min-executed floor of ${minExecuted}`);
  }
  return { declared, executed, refFields };
}

// -- fixtures --------------------------------------------------------------

function withScratch(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-pr-claims-"));
  try { return fn(dir); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
}

function fixtureGit(dir, args) {
  const result = spawnSync("git", [...GIT_HARDENING, "-C", dir, ...args], {
    shell: false, encoding: "utf8", timeout: 20_000,
    env: { ...hardenedEnv(), GIT_AUTHOR_NAME: "f", GIT_AUTHOR_EMAIL: "f@invalid", GIT_COMMITTER_NAME: "f", GIT_COMMITTER_EMAIL: "f@invalid" }
  });
  if (result.status !== 0) throw new Error(`fixture git ${args.join(" ")} failed: ${result.stderr}`);
  return result.stdout;
}

// Builds a repository whose real merge count on main..topic is 4 -- so a
// claim asserting 3 reproduces the phase-232 error exactly.
function seedFixtureRepo(dir) {
  fixtureGit(dir, ["init", "-q", "-b", "main"]);
  fs.writeFileSync(path.join(dir, "seed.txt"), "seed\n");
  fixtureGit(dir, ["add", "seed.txt"]);
  fixtureGit(dir, ["commit", "-q", "-m", "seed"]);
  const base = fixtureGit(dir, ["rev-parse", "HEAD"]).trim();
  fixtureGit(dir, ["checkout", "-q", "-b", "topic"]);
  for (let index = 1; index <= 4; index += 1) {
    fixtureGit(dir, ["checkout", "-q", "-b", `feature-${index}`, base]);
    fs.writeFileSync(path.join(dir, `f${index}.txt`), `${index}\n`);
    fixtureGit(dir, ["add", `f${index}.txt`]);
    fixtureGit(dir, ["commit", "-q", "-m", `feature ${index}`]);
    fixtureGit(dir, ["checkout", "-q", "topic"]);
    fixtureGit(dir, ["merge", "-q", "--no-ff", "--no-edit", `feature-${index}`]);
  }
  // Remote-tracking refs are created directly rather than fetched: the
  // hardened env sets GIT_ALLOW_PROTOCOL="", which correctly refuses the
  // `file` transport (a good sign -- that refusal is the hardening working).
  // This writes only inside the disposable mkdtemp fixture repository.
  for (const branch of ["main", "topic"]) {
    fixtureGit(dir, ["update-ref", `refs/remotes/origin/${branch}`, fixtureGit(dir, ["rev-parse", branch]).trim()]);
  }
  return base;
}

function sidecarWith(claims, body) {
  return {
    schema: 1,
    repository: "szTheory/accrue",
    claims,
    body: body || [
      { kind: "markdown", lines: ["## What a reviewer would reject this for", ""] },
      ...claims.map((claim) => ({ kind: "claim", id: claim.id })),
      { kind: "markdown", lines: [""] }
    ]
  };
}

function scenarioUnknownKindIsNeverSkipped() {
  const sidecar = sidecarWith([{ id: "C1", kind: "exec_shell", text: "x", expected: 0 }]);
  assert.throws(
    () => assertSchema(sidecar),
    /unknown kind "exec_shell"; the frozen table declares: merge_count, commit_reachable, path_exists, file_sha256, fixed_string_count, tracked_path_count, attested\. An unknown kind is never skipped\./
  );
}

function scenarioSchemaViolationFailsBeforeAnyEvaluator() {
  const sidecar = sidecarWith([{ id: "C1", kind: "merge_count", base: "origin/main", text: "x", expected: 4 }]);
  assert.throws(() => assertSchema(sidecar), /missing required argument "head"/);
}

function scenarioFlagLikeValueRejectedBeforeArgvIsBuilt() {
  const sidecar = sidecarWith([{ id: "C1", kind: "merge_count", base: "--upload-pack=touch /tmp/gsd-pr-claims-pwn", head: "HEAD", text: "x", expected: 0 }]);
  assert.throws(() => assertSchema(sidecar), /C1\.base: value "--upload-pack=touch \/tmp\/gsd-pr-claims-pwn" begins with "-" and is rejected outright/);
  assert.equal(fs.existsSync("/tmp/gsd-pr-claims-pwn"), false, "nothing may be executed from a committed value");
}

function scenarioRangeAndReflogRefsRejected() {
  assert.throws(() => assertSchema(sidecarWith([{ id: "C1", kind: "merge_count", base: "origin/main..HEAD", head: "HEAD", text: "x", expected: 0 }])), /contains "\.\."/);
  assert.throws(() => assertSchema(sidecarWith([{ id: "C1", kind: "merge_count", base: "main@{1}", head: "HEAD", text: "x", expected: 0 }])), /C1\.base/);
  assert.throws(() => assertSchema(sidecarWith([{ id: "C1", kind: "merge_count", base: "origin/ main", head: "HEAD", text: "x", expected: 0 }])), /outside \[A-Za-z0-9/);
}

function scenarioBadShaRejected() {
  const claim = { id: "C1", kind: "attested", text: "x", expected: true, reason: "r", owner: "o", expires_on: "2099-01-01", approving_sha: "nothex!" };
  assert.throws(() => assertSchema(sidecarWith([claim])), /C1\.approving_sha: "nothex!" is not a 7-40 character lowercase hex SHA/);
}

function scenarioFalseExpectedValueFailsPrintingBoth() {
  withScratch((dir) => {
    seedFixtureRepo(dir);
    const sidecar = sidecarWith([{ id: "C1", kind: "merge_count", base: "main", head: "topic", expected: 3, text: "The branch carries three internal merges." }]);
    assertSchema(sidecar);
    assert.throws(
      () => evaluateClaims(dir, sidecar),
      /claim C1 \(merge_count\) asserts 3 but the measured value is 4/
    );
  });
}

function scenarioTrueExpectedValuePasses() {
  withScratch((dir) => {
    const base = seedFixtureRepo(dir);
    const sidecar = sidecarWith([
      { id: "C1", kind: "merge_count", base: "main", head: "topic", expected: 4, text: "The branch carries four internal merges." },
      { id: "C2", kind: "commit_reachable", ancestor: base.slice(0, 12), descendant: "topic", expected: true, text: "The seed commit is an ancestor of the topic head." },
      { id: "C3", kind: "path_exists", path: "seed.txt", expected: true, text: "The seed file exists." },
      { id: "C4", kind: "tracked_path_count", pathspec: "seed.txt", expected: 1, text: "One tracked seed file." },
      { id: "C5", kind: "fixed_string_count", path: "seed.txt", needle: "seed", expected: 1, text: "One seed line." }
    ]);
    assertSchema(sidecar);
    assert.equal(evaluateClaims(dir, sidecar), 5);
  });
}

function scenarioEvaluatorErrorFailsClosed() {
  withScratch((dir) => {
    seedFixtureRepo(dir);
    const sidecar = sidecarWith([{ id: "C1", kind: "merge_count", base: "no-such-ref-anywhere", head: "topic", expected: 0, text: "x" }]);
    assertSchema(sidecar);
    assert.throws(() => evaluateClaims(dir, sidecar), /pr claims: FAIL/);
  });
}

function scenarioTimeoutAndBufferAreFailuresNotTruncatedPasses() {
  assert.throws(
    () => classifyRunResult({ error: Object.assign(new Error("timed out"), { code: "ETIMEDOUT" }) }, ["rev-list", "--count"]),
    /timed out running `git rev-list --count` -- a timeout is a FAILURE, never a truncated comparison/
  );
  assert.throws(
    () => classifyRunResult({ error: Object.assign(new Error("too big"), { code: "ENOBUFS" }) }, ["ls-files"]),
    /exceeded the 1000000-byte bounded buffer .* refusing to compare truncated output/s
  );
  assert.throws(
    () => classifyRunResult({ signal: "SIGTERM" }, ["rev-list"]),
    /killed by SIGTERM .* never as a pass/s
  );
  assert.throws(() => evaluateClaims(".", sidecarWith([]), { timeoutMs: 120_000 }), /--timeout-ms must be a positive integer no greater than 60000/);
}

function scenarioRenderJoinByteExact() {
  const claims = [{ id: "C1", kind: "path_exists", path: "seed.txt", expected: true, text: "The seed file exists." }];
  const sidecar = sidecarWith(claims);
  const body = renderBody(sidecar);
  assert.doesNotThrow(() => assertRenderJoin(sidecar, body));
  const tampered = body.replace("The seed file exists.", "The seed file exists!");
  assert.throws(() => assertRenderJoin(sidecar, tampered), /not byte-exactly re-derivable from the sidecar; first difference at line 3/);
}

function scenarioBodyMarkerWithNoBackingClaim() {
  const sidecar = sidecarWith([{ id: "C1", kind: "path_exists", path: "seed.txt", expected: true, text: "x" }]);
  const body = renderBody(sidecar) + "- an unbacked assertion [claim:C9]\n";
  assert.throws(() => assertClaimIdJoin(sidecar, body), /\[claim:C9\] which is absent from the sidecar's claims/);
}

function scenarioClaimAbsentFromBody() {
  const sidecar = sidecarWith([{ id: "C1", kind: "path_exists", path: "seed.txt", expected: true, text: "x" }]);
  const body = renderBody(sidecar).replace("[claim:C1]", "");
  assert.throws(() => assertClaimIdJoin(sidecar, body), /sidecar claim "C1" never appears in the body/);
}

function scenarioMinExecutedFloor() {
  const sidecar = sidecarWith([]);
  sidecar.body = [{ kind: "markdown", lines: ["## Nothing", ""] }];
  assert.throws(
    () => verifyClaims(".", sidecar, renderBody(sidecar), { requireClaims: true, minExecuted: 1 }),
    /only 0 claims were evaluated, below the --min-executed floor of 1/
  );
}

function scenarioAttestedExpiry() {
  const claims = [
    { id: "C1", kind: "attested", text: "x", expected: true, reason: "r", owner: "maintainer", expires_on: "2020-01-01", approving_sha: "9b50ce6a" },
    { id: "C2", kind: "path_exists", path: "a", expected: true, text: "y" },
    { id: "C3", kind: "path_exists", path: "b", expected: true, text: "z" },
    { id: "C4", kind: "path_exists", path: "c", expected: true, text: "w" },
    { id: "C5", kind: "path_exists", path: "d", expected: true, text: "v" }
  ];
  assert.throws(() => assertAttestedLimits(claims), /attested claim C1 expired on 2020-01-01 \(owner: maintainer\)/);
}

function scenarioAttestedHardCapOfTwo() {
  const attested = (id) => ({ id, kind: "attested", text: "x", expected: true, reason: "r", owner: "o", expires_on: "2099-01-01", approving_sha: "9b50ce6a" });
  const claims = [attested("C1"), attested("C2"), attested("C3")];
  for (let index = 4; index <= 20; index += 1) claims.push({ id: `C${index}`, kind: "path_exists", path: "a", expected: true, text: "x" });
  assert.throws(() => assertAttestedLimits(claims), /3 attested claims exceed the hard cap of 2/);
}

function scenarioAttestedPercentageCap() {
  const attested = (id) => ({ id, kind: "attested", text: "x", expected: true, reason: "r", owner: "o", expires_on: "2099-01-01", approving_sha: "9b50ce6a" });
  const claims = [attested("C1"), attested("C2"), { id: "C3", kind: "path_exists", path: "a", expected: true, text: "x" }];
  assert.throws(() => assertAttestedLimits(claims), /attested claims are 2\/3 \(67%\) of all claims, above the 20% cap/);
}

function scenarioPullRequestTargetInterlock() {
  withScratch((dir) => {
    const workflows = path.join(dir, ".github", "workflows");
    fs.mkdirSync(workflows, { recursive: true });
    fs.writeFileSync(path.join(workflows, "ci.yml"), "on:\n  pull_request:\n    branches: [main]\n");
    assert.equal(assertNoPullRequestTarget(dir), 1);
    fs.writeFileSync(path.join(workflows, "evil.yml"), "on:\n  pull_request_target:\n    branches: [main]\n");
    assert.throws(() => assertNoPullRequestTarget(dir), /evil\.yml line 2 declares a pull_request_target trigger/);
  });
}

function scenarioZeroWorkflowsInspectedFails() {
  withScratch((dir) => {
    fs.mkdirSync(path.join(dir, ".github", "workflows"), { recursive: true });
    assert.throws(() => assertNoPullRequestTarget(dir), /zero workflow files inspected/);
  });
}

function scenarioExpectedRepositoryMismatch() {
  const sidecar = sidecarWith([{ id: "C1", kind: "path_exists", path: "a", expected: true, text: "x" }]);
  assert.throws(() => assertExpectedRepository(sidecar, "other/repo"), /does not match --expected-repository other\/repo/);
}

function scenarioTablesAgree() {
  assert.doesNotThrow(() => assertTablesAgree());
  assert.deepEqual(Object.keys(EVALUATORS).sort(), Object.keys(CLAIM_KINDS).sort());
}

function scenarioConformingPositiveControl() {
  withScratch((dir) => {
    const base = seedFixtureRepo(dir);
    const workflows = path.join(dir, ".github", "workflows");
    fs.mkdirSync(workflows, { recursive: true });
    fs.writeFileSync(path.join(workflows, "ci.yml"), "on:\n  pull_request:\n    branches: [main]\n");
    const claims = [
      { id: "C1", kind: "merge_count", base: "origin/main", head: "origin/topic", expected: 4, text: "The branch carries four internal merges." },
      { id: "C2", kind: "commit_reachable", ancestor: base, descendant: "origin/topic", expected: true, text: "The seed commit is an ancestor of the topic head." },
      { id: "C3", kind: "file_sha256", path: "seed.txt", expected: crypto.createHash("sha256").update("seed\n").digest("hex"), text: "The seed file hashes as recorded." },
      { id: "C4", kind: "tracked_path_count", pathspec: "seed.txt", expected: 1, text: "Exactly one tracked seed path." },
      { id: "C5", kind: "attested", text: "A maintainer-owned fact with an expiry.", expected: true, reason: "not machine-measurable", owner: "maintainer", expires_on: "2099-01-01", approving_sha: base.slice(0, 12) }
    ];
    const sidecar = sidecarWith(claims);
    const body = renderBody(sidecar);
    const result = verifyClaims(dir, sidecar, body, {
      requireClaims: true,
      requireRenderJoin: true,
      requireRemoteRefs: true,
      requireNoPullRequestTarget: true,
      expectedRepository: "szTheory/accrue",
      minExecuted: 1
    });
    assert.deepEqual(result, { declared: 5, executed: 5, refFields: 4 });
  });
}

function refClaim(value, extra = {}) {
  return { id: "C1", kind: "merge_count", base: value, head: "origin/topic", expected: 0, text: "x", ...extra };
}

function scenarioBareMainRefFails() {
  assert.throws(() => assertRemoteRefsExplicit([refClaim("main")]), /names the bare local branch "main".*write "origin\/main"/s);
}

function scenarioOtherWellKnownBareRefsFail() {
  for (const name of ["master", "develop", "trunk", "release"]) {
    assert.throws(
      () => assertRemoteRefsExplicit([{ id: "C1", kind: "merge_count", base: "origin/main", head: name, expected: 0, text: "x" }]),
      new RegExp(`head names the bare local branch "${name}"`)
    );
  }
}

// Ref hygiene and claim truth are SEPARATE properties. This proves the
// separation: the claim's expected value is measured correct against a real
// fixture repository, and the ref check still fails it.
function scenarioBareRefFailsEvenWhenExpectedValueIsCorrect() {
  withScratch((dir) => {
    seedFixtureRepo(dir);
    const claim = { id: "C1", kind: "merge_count", base: "main", head: "topic", expected: 4, text: "x" };
    const sidecar = sidecarWith([claim]);
    assertSchema(sidecar);
    assert.equal(evaluateClaims(dir, sidecar), 1, "the asserted value really is correct");
    assert.throws(() => assertRemoteRefsExplicit([claim]), /names the bare local branch "main"/);
  });
}

function scenarioExplicitRemoteAndShaRefsPass() {
  assert.equal(assertRemoteRefsExplicit([refClaim("origin/main")]), 2);
  assert.equal(assertRemoteRefsExplicit([refClaim("refs/remotes/origin/main")]), 2);
  assert.equal(assertRemoteRefsExplicit([refClaim("9b50ce6a080b684263de6c53d54e0726df077fa2")]), 2);
  assert.equal(assertRemoteRefsExplicit([refClaim("9b50ce6a")]), 2);
}

function scenarioLocalTopicRefNeedsARecordedReason() {
  assert.throws(() => assertRemoteRefsExplicit([refClaim("review/v1.62-candidate-code-only")]), /record why it is local-only in a non-empty "local_ref_reason"/);
  assert.throws(() => assertRemoteRefsExplicit([refClaim("review/v1.62-candidate-code-only", { local_ref_reason: "   " })]), /non-empty "local_ref_reason"/);
  assert.doesNotThrow(() => assertRemoteRefsExplicit([refClaim("review/v1.62-candidate-code-only", { local_ref_reason: "never leaves the machine by design" })]));
  // A bare well-known branch name never qualifies for the escape.
  assert.throws(() => assertRemoteRefsExplicit([refClaim("main", { local_ref_reason: "I would rather not" })]), /never qualifies for the local_ref_reason escape/);
}

function scenarioNonRefFieldsAreNeverInspected() {
  const claims = [
    { id: "C1", kind: "path_exists", path: "main", expected: true, text: "a path literally named main" },
    { id: "C2", kind: "fixed_string_count", path: "a", needle: "main", expected: 1, text: "prose mentioning main" },
    { id: "C3", kind: "tracked_path_count", pathspec: "main", expected: 1, text: "a pathspec named main" }
  ];
  assert.equal(assertRemoteRefsExplicit(claims), 0);
}

const SCENARIOS = [
  ["an unknown claim kind fails, naming the kind and the frozen table's keys, and is never skipped", scenarioUnknownKindIsNeverSkipped],
  ["a claim violating its kind's argument schema fails before any evaluator runs", scenarioSchemaViolationFailsBeforeAnyEvaluator],
  ["an argument value matching /^-/ fails at validation, before any argv is built, and nothing is executed", scenarioFlagLikeValueRejectedBeforeArgvIsBuilt],
  ["a ref value containing .. or @{ or a space fails validation", scenarioRangeAndReflogRefsRejected],
  ["a SHA value that is not 7-40 lowercase hex fails validation", scenarioBadShaRejected],
  ["a claim whose measured value differs from expected fails, printing both (asserted 3 against a repo that really yields 4)", scenarioFalseExpectedValueFailsPrintingBoth],
  ["a conforming set of five kinds measures true against a real fixture repository", scenarioTrueExpectedValuePasses],
  ["an evaluator error fails closed rather than being skipped", scenarioEvaluatorErrorFailsClosed],
  ["an evaluator timeout, a bounded-buffer overflow, a kill signal, and an out-of-range --timeout-ms are all failures, never truncated passes", scenarioTimeoutAndBufferAreFailuresNotTruncatedPasses],
  ["a committed body differing by one byte from the renderer's output fails, naming the first differing line", scenarioRenderJoinByteExact],
  ["a body claim-id marker with no backing claim in the sidecar fails", scenarioBodyMarkerWithNoBackingClaim],
  ["a sidecar claim id that never appears in the body fails", scenarioClaimAbsentFromBody],
  ["a sidecar with zero claims fails the --min-executed floor, naming the floor", scenarioMinExecutedFloor],
  ["an attested claim past its expires_on fails, naming the expiry date and owner", scenarioAttestedExpiry],
  ["a third attested claim fails the hard cap of 2", scenarioAttestedHardCapOfTwo],
  ["attested claims above 20% of total claims fail", scenarioAttestedPercentageCap],
  ["a repository declaring a pull_request_target workflow fails the trigger-surface interlock", scenarioPullRequestTargetInterlock],
  ["a workflows directory with zero inspected files fails rather than passing vacuously", scenarioZeroWorkflowsInspectedFails],
  ["a sidecar whose repository does not match --expected-repository fails", scenarioExpectedRepositoryMismatch],
  ["the render table and the evaluator table declare exactly the same frozen kinds", scenarioTablesAgree],
  ["a conforming sidecar passes every strict flag at once and reports the evaluated claim count", scenarioConformingPositiveControl],
  ["SL-B: a claim whose base is the bare local branch main fails, naming the field and instructing origin/main", scenarioBareMainRefFails],
  ["SL-B: a claim whose head is a bare master, develop, trunk, or release fails", scenarioOtherWellKnownBareRefsFail],
  ["SL-B: a bare local ref fails EVEN WHEN its expected value is measured correct -- ref hygiene and claim truth are separable", scenarioBareRefFailsEvenWhenExpectedValueIsCorrect],
  ["SL-B: origin/main, refs/remotes/origin/main, and a hex SHA all pass", scenarioExplicitRemoteAndShaRefsPass],
  ["SL-B: a local-only topic ref passes only with a non-empty local_ref_reason, and a well-known branch name never qualifies for that escape", scenarioLocalTopicRefNeedsARecordedReason],
  ["SL-B: path, pathspec, and prose fields are never inspected by the ref rule", scenarioNonRefFieldsAreNeverInspected]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

const BOOLEAN_FLAGS = new Set(["fixtures", "require-claims", "require-render-join", "require-remote-refs", "require-no-pull-request-target"]);
const VALUE_OPTIONS = new Set(["repo", "claims", "body", "expected-repository", "min-executed", "timeout-ms"]);

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
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();

  // --fixtures returns before --claims / --body are ever read.
  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    const suffix = requestedStrictFlags.length
      ? ` (fixtures: ${requestedStrictFlags.join(", ")}; ${count} scenarios)`
      : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    console.log(`pr claims: PASS${suffix}`);
    return;
  }

  const repo = parsed.values.repo || process.cwd();
  if (!parsed.values.claims) fail("--claims is required");
  if (!fs.existsSync(parsed.values.claims)) fail(`claims sidecar does not exist: ${parsed.values.claims}`);
  const sidecar = JSON.parse(fs.readFileSync(parsed.values.claims, "utf8"));
  const bodyText = parsed.values.body ? fs.readFileSync(parsed.values.body, "utf8") : undefined;

  const result = verifyClaims(repo, sidecar, bodyText, {
    requireClaims: parsed.flags.has("require-claims"),
    requireRenderJoin: parsed.flags.has("require-render-join"),
    requireRemoteRefs: parsed.flags.has("require-remote-refs"),
    requireNoPullRequestTarget: parsed.flags.has("require-no-pull-request-target"),
    expectedRepository: parsed.values["expected-repository"],
    minExecuted: parsed.values["min-executed"] === undefined ? undefined : Number(parsed.values["min-executed"]),
    timeoutMs: parsed.values["timeout-ms"] === undefined ? DEFAULT_TIMEOUT_MS : Number(parsed.values["timeout-ms"])
  });

  const counts = `${result.declared} declared, ${result.executed} evaluated, ${result.refFields} ref fields inspected`;
  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")}; ${counts})`
    : ` (schema-only: no strict flags supplied; ${counts})`;
  console.log(`pr claims: PASS${suffix}`);
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
    console.error(error.message.startsWith("pr claims:") ? error.message : `pr claims: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
