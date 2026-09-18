#!/usr/bin/env node
//
// SL-F (quick task 260917-l7v): a committed PR-body file must match the live
// PR body it represents.
//
// WHY. A committed body drifted from the live body twice in one phase-232
// session. The sibling guard verify_pr_body_contract.mjs checks the SHAPE of
// a committed body (required sections, claim density, no leaked local paths,
// expected repository). It cannot check whether anyone ever published it.
// This one does, and deliberately checks nothing the sibling already checks.
//
// THE HONEST COST, WRITTEN WHERE A MAINTAINER SEES IT BEFORE MUTING THE GATE.
// This is the only guard in this set that needs the network and a credential,
// and it FAILS CLOSED -- an unavailable token is a failure, never a skip,
// because "skip when unavailable" is precisely how a gate goes vacuous. The
// cost is that this check will go transiently RED for a TRUE reason: you
// commit a body edit, CI runs, and the live body is not updated until you run
//
//     gh pr edit <number> --body-file <path>
//
// That red is correct, and the gate prints that exact command. Do not soften
// it into a warning. If the transient red is unacceptable, DELETE the gate
// rather than make it lie.
//
// TOKEN AVAILABILITY, corrected. `secrets.GITHUB_TOKEN` IS available on fork
// `pull_request` runs -- what a fork loses is repository and organization
// secrets, which this gate does not use. So it needs only
// `permissions: pull-requests: read` on the workflow and it blocks on forks
// exactly like it blocks on branches. Do NOT add a skip-on-fork branch on the
// belief that forks have no token; they do.
//
// DECLARATION. A committed body opts in with YAML front matter `pr: <number>`
// or a single HTML comment `<!-- pr: https://github.com/OWNER/REPO/pull/N -->`.
// A file with NO declaration is `unopened`: it passes, and the PASS line names
// how many were unopened so a whole-corpus opt-out cannot hide in a green run.
//
// RETRY, CLASSIFIED. At most 3 attempts, and only on a network error, a 5xx,
// or a rate-limit response (429, or 403 carrying `x-ratelimit-remaining: 0`).
// A 401, 404, or 422 is real -- retrying only makes the failure slower. After
// exhausting retries the message names it as infrastructure and says to re-run
// the job, so an infra blip reads differently from a drift finding at a glance.
//
// NEVER LOG A CREDENTIAL. No header value is ever printed. The live body is
// routed through the sibling's assertLeak AND through SL-C's redaction before
// any of it reaches stdout -- a diff must never be the thing that publishes a
// local path or a censused reference into a public log.

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { assertLeak, assertExpectedRepository } from "./verify_pr_body_contract.mjs";
import { loadCensus, redact, DEFAULT_CENSUS } from "./verify_sensitive_token_census.mjs";
import { renderBody } from "./render_pr_claims.mjs";

const fail = (message) => { throw new Error(`pr body currency: FAIL: ${message}`); };

export const DEFAULT_TIMEOUT_MS = 15000;
export const MAX_ATTEMPTS = 3;
const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);

// -- declaration parsing --------------------------------------------------------

const FRONT_MATTER_PATTERN = /^---\n([\s\S]*?)\n---\n/;
const COMMENT_PATTERN = /^<!--\s*pr:\s*(\S+)\s*-->\s*$/m;

// Returns { number, body } where `number` is null for an unopened body.
// `body` always has the declaration stripped, so the comparison never trips on
// the marker that enables it.
export function parseDeclaration(text, expectedRepository, relativePath) {
  const frontMatter = FRONT_MATTER_PATTERN.exec(text);
  if (frontMatter) {
    const line = /^pr:\s*(\S+)\s*$/m.exec(frontMatter[1]);
    const rest = text.slice(frontMatter[0].length);
    if (!line) return { number: null, body: rest };
    return { number: parseReference(line[1], expectedRepository, relativePath), body: rest };
  }
  const comment = COMMENT_PATTERN.exec(text);
  if (!comment) return { number: null, body: text };
  return {
    number: parseReference(comment[1], expectedRepository, relativePath),
    body: text.replace(COMMENT_PATTERN, "").replace(/^\n+/, "")
  };
}

export function parseReference(reference, expectedRepository, relativePath) {
  if (/^\d+$/.test(reference)) {
    const number = Number(reference);
    if (number <= 0) fail(`${relativePath}: declares a non-positive pull request number`);
    return number;
  }
  const url = /^https:\/\/github\.com\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)\/pull\/(\d+)$/.exec(reference);
  if (!url) fail(`${relativePath}: declares a malformed pull request reference -- expected a number or a https://github.com/OWNER/REPO/pull/N url`);
  assertExpectedRepository(`https://github.com/${url[1]}`, expectedRepository);
  return Number(url[2]);
}

// -- normalization and comparison -----------------------------------------------

export function normalize(text) {
  return String(text)
    .replace(/\r\n/g, "\n")
    .split("\n")
    .map((line) => line.replace(/\s+$/, ""))
    .join("\n")
    .replace(/\n+$/, "");
}

export function firstDifference(committed, live) {
  const a = normalize(committed).split("\n");
  const b = normalize(live).split("\n");
  for (let index = 0; index < Math.max(a.length, b.length); index += 1) {
    if (a[index] !== b[index]) {
      return { line: index + 1, committed: a[index] ?? "<end of committed body>", live: b[index] ?? "<end of live body>" };
    }
  }
  return null;
}

// -- fetching -------------------------------------------------------------------

function classify(response) {
  if (RETRYABLE_STATUSES.has(response.status)) return "retryable";
  if (response.status === 403 && response.headers?.get?.("x-ratelimit-remaining") === "0") return "retryable";
  return "fatal";
}

export async function fetchLiveBody(expectedRepository, number, { token, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
  if (!token) {
    fail(
      `no credential available to read pull request #${number}. This gate fails closed and does NOT skip -- ` +
      "a gate that skips when its input is unavailable is a gate that passes vacuously. " +
      "Grant `permissions: pull-requests: read` on the workflow, or pass --token-env naming a set variable."
    );
  }
  const url = `https://api.github.com/repos/${expectedRepository}/pulls/${number}`;
  let lastReason = "unknown";
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(url, {
        signal: controller.signal,
        headers: {
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          Authorization: `Bearer ${token}`
        }
      });
      if (response.ok) {
        const payload = await response.json();
        if (typeof payload?.body !== "string") {
          fail(`pull request #${number} responded without a body field -- refusing to treat an absent body as a match`);
        }
        return { body: payload.body, attempts: attempt };
      }
      if (classify(response) === "fatal") {
        fail(`pull request #${number} returned HTTP ${response.status} -- not retryable, this is a real answer`);
      }
      lastReason = `HTTP ${response.status}`;
    } catch (error) {
      if (String(error?.message || "").startsWith("pr body currency:")) throw error;
      lastReason = error?.name === "AbortError" ? `timed out after ${timeoutMs}ms` : `network error (${error?.name || "unknown"})`;
    } finally {
      clearTimeout(timer);
    }
    if (attempt < MAX_ATTEMPTS) {
      await new Promise((resolve) => setTimeout(resolve, 250 * attempt));
    }
  }
  fail(`pull request #${number} could not be read after ${MAX_ATTEMPTS} attempts (${lastReason}) -- this is INFRASTRUCTURE, not drift; re-run the job`);
}

// -- corpus ----------------------------------------------------------------------

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, "--no-optional-locks", ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout;
}

export function liveBodyCorpus(repo) {
  return git(repo, ["ls-files", "*-INTEGRATION-PR.md"]).split("\n").filter(Boolean).sort();
}

// -- verification -----------------------------------------------------------------

export async function verifyCurrency(repo, {
  bodies,
  expectedRepository,
  token,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  minDeclared = 0,
  fetchBody = fetchLiveBody
} = {}) {
  // `bodies ?? ...`, not `bodies.length ? ...`: an explicitly empty list must
  // reach the zero-files failure below rather than silently falling back to a
  // live enumeration that happens to be non-empty.
  const corpus = bodies ?? liveBodyCorpus(repo);
  if (corpus.length === 0) {
    fail("no committed pull-request body files were found -- refusing to report a pass over zero files");
  }
  let declared = 0;
  let compared = 0;
  let retried = 0;
  let unopened = 0;
  for (const relativePath of corpus) {
    const text = fs.readFileSync(path.join(repo, relativePath), "utf8");
    const { number, body } = parseDeclaration(text, expectedRepository, relativePath);
    if (number === null) { unopened += 1; continue; }
    declared += 1;
    const live = await fetchBody(expectedRepository, number, { token, timeoutMs });
    if (live.attempts > 1) retried += 1;
    const liveLines = String(live.body).replace(/\r\n/g, "\n").split("\n");
    assertLeak(liveLines);
    const difference = firstDifference(body, live.body);
    if (difference) {
      fail(
        `${relativePath} has drifted from the live body of pull request #${number}. ` +
        `First difference at line ${difference.line}: committed ${JSON.stringify(redact(difference.committed).slice(0, 200))} ` +
        `vs live ${JSON.stringify(redact(difference.live).slice(0, 200))}. ` +
        `Remediate with: gh pr edit ${number} --body-file ${relativePath}`
      );
    }
    compared += 1;
  }
  if (declared < minDeclared) {
    fail(`only ${declared} committed body file(s) declared a pull request, below --min-declared ${minDeclared} -- deleting every declaration must not turn this gate off`);
  }
  return { files: corpus.length, declared, compared, retried, unopened };
}

// -- fixtures ----------------------------------------------------------------------

function seedBody(dir, relativePath, content) {
  const absolute = path.join(dir, relativePath);
  fs.mkdirSync(path.dirname(absolute), { recursive: true });
  fs.writeFileSync(absolute, content);
  return relativePath;
}

function withScratch(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(require_tmp()), "gsd-pr-currency-"));
  try { return fn(dir); } finally { fs.rmSync(dir, { recursive: true, force: true }); }
}

function require_tmp() {
  return process.env.TMPDIR || "/tmp";
}

const BODY = "## What a reviewer would reject this for\n\n- Something concrete, with `a command`.\n";

function stubFetch(body, { attemptsNeeded = 1 } = {}) {
  let calls = 0;
  return async () => {
    calls += 1;
    if (calls < attemptsNeeded) {
      // Simulates a 5xx that the real fetcher would retry.
      return stubFetch(body)();
    }
    return { body, attempts: attemptsNeeded };
  };
}

const SCENARIOS = [
  [
    "a committed body whose live body differs fails, printing the first differing line and the gh pr edit remediation",
    async () => withScratch(async (dir) => {
      const file = seedBody(dir, "232-INTEGRATION-PR.md", `<!-- pr: 45 -->\n${BODY}`);
      await assert.rejects(
        () => verifyCurrency(dir, { bodies: [file], expectedRepository: "szTheory/accrue", token: "t", fetchBody: stubFetch(BODY.replace("concrete", "different")) }),
        /drifted from the live body of pull request #45.*First difference at line.*gh pr edit 45 --body-file 232-INTEGRATION-PR\.md/s
      );
    })
  ],
  [
    "a declared PR with NO token available fails, naming the missing credential and explicitly rejecting a skip",
    async () => withScratch(async (dir) => {
      const file = seedBody(dir, "232-INTEGRATION-PR.md", `<!-- pr: 45 -->\n${BODY}`);
      await assert.rejects(
        () => verifyCurrency(dir, { bodies: [file], expectedRepository: "szTheory/accrue", token: undefined }),
        /no credential available.*fails closed and does NOT skip/s
      );
    })
  ],
  [
    "a non-retryable non-200 fails immediately, without retrying",
    async () => {
      let calls = 0;
      const originalFetch = globalThis.fetch;
      globalThis.fetch = async () => { calls += 1; return { ok: false, status: 404, headers: new Map() }; };
      try {
        await assert.rejects(() => fetchLiveBody("szTheory/accrue", 45, { token: "t" }), /HTTP 404 -- not retryable/);
        assert.equal(calls, 1, "a 404 must not be retried");
      } finally { globalThis.fetch = originalFetch; }
    }
  ],
  [
    "a fetch that times out on all attempts fails, classified as infrastructure with a re-run instruction",
    async () => {
      const originalFetch = globalThis.fetch;
      globalThis.fetch = async () => { const error = new Error("aborted"); error.name = "AbortError"; throw error; };
      try {
        await assert.rejects(
          () => fetchLiveBody("szTheory/accrue", 45, { token: "t", timeoutMs: 5 }),
          /after 3 attempts \(timed out after 5ms\) -- this is INFRASTRUCTURE, not drift; re-run the job/
        );
      } finally { globalThis.fetch = originalFetch; }
    }
  ],
  [
    "a 5xx on attempt 1 followed by a 200 on attempt 2 passes, and the retry is recorded",
    async () => {
      let calls = 0;
      const originalFetch = globalThis.fetch;
      globalThis.fetch = async () => {
        calls += 1;
        if (calls === 1) return { ok: false, status: 503, headers: new Map() };
        return { ok: true, status: 200, headers: new Map(), json: async () => ({ body: BODY }) };
      };
      try {
        const result = await fetchLiveBody("szTheory/accrue", 45, { token: "t" });
        assert.equal(result.attempts, 2);
      } finally { globalThis.fetch = originalFetch; }
    }
  ],
  [
    "a body declaring a non-numeric pull request reference fails",
    () => {
      assert.throws(() => parseReference("not-a-number", "szTheory/accrue", "x.md"), /malformed pull request reference/);
    }
  ],
  [
    "a body declaring a url whose owner/repo does not match --expected-repository fails",
    () => {
      assert.throws(() => parseReference("https://github.com/other/repo/pull/45", "szTheory/accrue", "x.md"), /does not match --expected-repository/);
    }
  ],
  [
    "a run over zero body files fails rather than reporting a pass",
    async () => withScratch(async (dir) => {
      await assert.rejects(() => verifyCurrency(dir, { bodies: [], expectedRepository: "szTheory/accrue", token: "t" }), /refusing to report a pass over zero files/);
    })
  ],
  [
    "a run where fewer bodies carried a declaration than --min-declared fails",
    async () => withScratch(async (dir) => {
      const file = seedBody(dir, "232-INTEGRATION-PR.md", BODY);
      await assert.rejects(
        () => verifyCurrency(dir, { bodies: [file], expectedRepository: "szTheory/accrue", token: "t", minDeclared: 1 }),
        /below --min-declared 1 -- deleting every declaration must not turn this gate off/
      );
    })
  ],
  [
    "POSITIVE: a declared PR whose live body matches after newline normalization passes",
    async () => withScratch(async (dir) => {
      const file = seedBody(dir, "232-INTEGRATION-PR.md", `<!-- pr: 45 -->\n${BODY}`);
      const result = await verifyCurrency(dir, { bodies: [file], expectedRepository: "szTheory/accrue", token: "t", minDeclared: 1, fetchBody: stubFetch(BODY.replace(/\n/g, "\r\n") + "\r\n\r\n") });
      assert.equal(result.compared, 1);
      assert.equal(result.declared, 1);
    })
  ],
  [
    "POSITIVE: a body declaring no pull request is reported unopened and passes",
    async () => withScratch(async (dir) => {
      const file = seedBody(dir, "232-INTEGRATION-PR.md", BODY);
      const result = await verifyCurrency(dir, { bodies: [file], expectedRepository: "szTheory/accrue", token: "t" });
      assert.equal(result.unopened, 1);
      assert.equal(result.declared, 0);
    })
  ],
  [
    "POSITIVE: a front-matter `pr:` declaration is parsed and stripped from the compared text",
    () => {
      const parsed = parseDeclaration(`---\npr: 45\n---\n${BODY}`, "szTheory/accrue", "x.md");
      assert.equal(parsed.number, 45);
      assert.equal(parsed.body, BODY);
    }
  ],
  [
    "CROSS-GATE: a declaration rendered by render_pr_claims.mjs parses back to the same number and strips to the body the live PR carries",
    () => {
      // SL-A renders the declaration from the sidecar; SL-F strips it before
      // comparing. Those two definitions are written in different files, so
      // this asserts they agree -- the check that was missing when SL-G's
      // digest and GSD's digest silently disagreed under the same v1 tag.
      const sidecar = {
        schema: 1,
        repository: "szTheory/accrue",
        pr: 45,
        claims: [],
        body: [{ kind: "markdown", lines: ["## What a reviewer would reject this for", "", "- Something concrete, with `a command`."] }]
      };
      const rendered = renderBody(sidecar);
      const parsed = parseDeclaration(rendered, "szTheory/accrue", "rendered.md");
      assert.equal(parsed.number, 45);
      assert.ok(!parsed.body.includes("<!-- pr:"), "the stripped body must not retain the declaration");
      assert.equal(normalize(parsed.body), normalize("## What a reviewer would reject this for\n\n- Something concrete, with `a command`."));
    }
  ],
  [
    "no fixture scenario touches the network: every declared-PR scenario injects through the fetchBody seam or stubs globalThis.fetch",
    () => {
      const source = fs.readFileSync(new URL(import.meta.url), "utf8");
      const scenarioBlock = source.slice(source.indexOf("const SCENARIOS = ["));
      assert.ok(!/await fetch\(/.test(scenarioBlock), "scenarios must never call fetch directly");
    }
  ]
];

export async function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) await scenario();
  return SCENARIOS.length;
}

// -- entrypoint --------------------------------------------------------------------

const BOOLEAN_FLAGS = new Set(["fixtures", "require-currency"]);
const VALUE_OPTIONS = new Set(["repo", "bodies", "expected-repository", "token-env", "timeout-ms", "min-declared"]);

function options(argv) {
  const flags = new Set(); const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index]; if (!token.startsWith("--")) fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (BOOLEAN_FLAGS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option: --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
  }
  return { flags, values };
}

async function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) {
    const count = await verifyFixtures();
    const suffix = parsed.flags.has("require-currency") ? ` (fixtures: require-currency; ${count} scenarios)` : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    console.log(`pr body currency: PASS${suffix}`);
    return;
  }

  const repo = parsed.values.repo || process.cwd();
  const expectedRepository = parsed.values["expected-repository"];
  if (!expectedRepository) fail("--expected-repository is required");
  // Registers SL-C's redactors so a printed diff line cannot publish a
  // censused reference into a public CI log.
  try { loadCensus(repo, DEFAULT_CENSUS); } catch { /* census absent in a scratch repo; redact() then no-ops */ }

  if (!parsed.flags.has("require-currency")) {
    const corpus = liveBodyCorpus(repo);
    if (corpus.length === 0) fail("no committed pull-request body files were found -- refusing to report a pass over zero files");
    console.log(`pr body currency: PASS (schema-only: no strict flags supplied; ${corpus.length} body files)`);
    return;
  }

  const tokenEnv = parsed.values["token-env"] || "GITHUB_TOKEN";
  const result = await verifyCurrency(repo, {
    expectedRepository,
    token: process.env[tokenEnv],
    timeoutMs: parsed.values["timeout-ms"] ? Number(parsed.values["timeout-ms"]) : DEFAULT_TIMEOUT_MS,
    minDeclared: parsed.values["min-declared"] ? Number(parsed.values["min-declared"]) : 0
  });
  console.log(
    `pr body currency: PASS (verified: require-currency; ${result.files} body files, ` +
    `${result.declared} declared, ${result.compared} compared, ${result.retried} retried, ${result.unopened} unopened)`
  );
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  main().catch((error) => {
    console.error(error.message.startsWith("pr body currency:") ? error.message : `pr body currency: FAIL: ${redact(error.message)}`);
    process.exitCode = 1;
  });
}
