#!/usr/bin/env node
//
// SL-D (quick task 260917-l7v): ban the pipefail/SIGPIPE `grep -q` idiom in
// scripts/ci -- bespoke, not shellcheck.
//
// MECHANISM. Under `set -euo pipefail`, a `-q` (or `-v`) consumer exits at
// its first match and closes the pipe; the producer takes SIGPIPE and dies
// 141; pipefail promotes that to the pipeline status; an enclosing `if !`
// inverts it and SKIPS the `fail` on precisely the input that should have
// tripped it.
//
// ACCURACY REQUIREMENT, re-measured live during this task rather than
// trusting an earlier estimate: **36** pipelines into `grep -q`/`-qv` under
// scripts/ci, of which **3** have non-builtin producers. None was producing
// a false PASS at measurement time -- both producers hand-fixed this session
// emit far under the 64 KiB pipe buffer (30 lines / 1527 bytes and 1 line /
// 69 bytes). So this is a LATENT hazard, not an active one. It is still
// worth banning because the failure is silent and inverted, and because the
// same shape was hand-fixed twice in one session (`3f6791c7`, `7e9f45dc`)
// with nothing preventing a third.
//
// WHY BESPOKE AND NOT SHELLCHECK. shellcheck 0.11.0 is installed on this
// machine and reports NOTHING on the exact pre-fix shape, even with
// `--include=SC2337`. The upstream rule is merged but unreleased. Making
// this merge-blocking via shellcheck would require a digest-pinned
// master-build container -- a supply-chain dependency taken on for a
// ~15-line check, on the merge-blocking path. Keep the bespoke guard.
//
// DETECTION. Enumerate `git ls-files 'scripts/ci/*.sh'`. For each file
// containing a non-comment `set -...pipefail` line, scan for a pipeline
// whose consumer is `grep` carrying `-q` or `-v` in its short-option
// cluster. EVERY producer is an OFFENDER -- external command, shell
// function, and (since quick task 261025-vdn) the shell builtins `printf`
// and `echo` too. The one exemption: a pipeline captured inside a command
// substitution ending `|| true`, where pipefail's promoted exit status is
// absorbed by the trailing `|| true` and never propagates.
//
// WHY BUILTIN PRODUCERS ARE NO LONGER EXEMPT. This file originally exempted
// `printf`/`echo` on the theory that a single sub-pipe-buffer write cannot
// lose the race. That theory was falsified in CI: in job 121312543518 a
// 7551-byte `printf` feeding `grep -Fq` in verify_release_contract.sh lost
// the SIGPIPE race (grep matched, exited, closed the pipe while printf was
// still writing), the pipeline reported failure, and a PRESENT needle read
// as missing. Commit 5561a9a9 fixed that site by having grep read the
// variable from a here-string (`grep -Fq needle <<<"$var"`), which has no
// producer process at all. Builtin-producer offenders are told to do the
// same.
//
// ALLOWLIST. IDIOM_ALLOWLIST below follows LIBRARY_MODULE_ALLOWLIST's shape
// in verify_ci_script_contract.mjs: every entry carries a one-line committed
// reason; an empty reason FAILS. Prefer FIXING to allowlisting -- the
// original 3 external-producer offenders were converted to
// capture-then-filter (accrue_host_verify_dev_boot.sh,
// accrue_host_verify_browser.sh), and the 30 builtin-producer sites the
// narrowing exposed in six scripts were converted to here-strings (quick
// task 261025-vdn). Empty today.
//
// FOLLOW-UP SEED (not implemented here; recorded in this task's SUMMARY
// deferred list): 53 shell guards under scripts/ci are entirely unlinted,
// and full shellcheck adoption is a substantially larger win than this one
// rule. Any future adoption must include `disable=SC2143` -- shellcheck's
// own SC2143 actively recommends the exact footgun this file bans.

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";

const fail = (message) => { throw new Error(`pipefail grep idiom: FAIL: ${message}`); };

// Empty today (see ALLOWLIST above): every measured live offender was fixed,
// not allowlisted. Keyed `relativePath#line`; every reason MUST be a
// non-empty, non-whitespace string -- an entry without a committed reason is
// not an allowlist entry (assertAllowlistReasons enforces this).
export const IDIOM_ALLOWLIST = new Map([]);

const BUILTIN_PRODUCERS = new Set(["printf", "echo"]);

// -- pure scanning -----------------------------------------------------------

function hasPipefail(source) {
  return source.split("\n").some((line) => {
    const trimmed = line.trim();
    if (trimmed.startsWith("#")) return false;
    return /^set\s+-\S*\s*(?:.*\bpipefail\b)?/.test(trimmed) && /\bset\b[^#]*\bpipefail\b/.test(trimmed);
  });
}

// Finds `$( ... )` spans on a single line (naive, non-nested-aware balance,
// sufficient for this repo's single-line pipeline shapes) whose content
// contains a `| grep` pipeline AND an absorbing `|| true` -- the exemption
// proven by a dedicated positive control.
function findExemptCommandSubstitutionSpans(line) {
  const spans = [];
  let searchFrom = 0;
  while (true) {
    const start = line.indexOf("$(", searchFrom);
    if (start === -1) break;
    let depth = 1;
    let pos = start + 2;
    while (pos < line.length && depth > 0) {
      if (line[pos] === "(") depth += 1;
      else if (line[pos] === ")") depth -= 1;
      pos += 1;
    }
    const end = pos;
    const content = line.slice(start, end);
    if (/\|\s*grep\b/.test(content) && /\|\|\s*true\b/.test(content)) spans.push([start, end]);
    searchFrom = end > start + 2 ? end : start + 2;
  }
  return spans;
}

function isWithinExemptSpan(index, spans) {
  return spans.some(([start, end]) => index >= start && index < end);
}

// Extracts the short-option flag characters immediately following `grep` on
// the consumer side of a pipe (e.g. "-Fq needle" -> "Fq"; "-qv" -> "qv"). A
// long-option token ("--quiet") or the first non-dash token (the pattern
// argument) stops the scan.
function extractGrepFlagChars(rest) {
  const tokens = rest.trim().split(/\s+/).filter(Boolean);
  let flagChars = "";
  for (const token of tokens) {
    if (!token.startsWith("-") || token.startsWith("--")) break;
    flagChars += token.slice(1);
  }
  return flagChars;
}

// Finds the nearest "simple command" boundary before `beforeIndex`: `;`,
// `(` (also covers `$(`), `&&`, `||`, or a bare `|` from an earlier stage in
// the same pipeline chain. Returns the index immediately after that
// boundary, or 0 (start of line) if none is found.
function findBoundaryEnd(line, beforeIndex) {
  let best = 0;
  for (const token of [";", "("]) {
    const idx = line.lastIndexOf(token, beforeIndex - 1);
    if (idx !== -1 && idx + 1 > best) best = idx + 1;
  }
  for (const token of ["&&", "||"]) {
    const idx = line.lastIndexOf(token, beforeIndex - 1);
    if (idx !== -1 && idx + token.length > best) best = idx + token.length;
  }
  // A bare `|` (not part of `||`, already handled above) closes an earlier
  // pipeline stage -- e.g. `a | b | grep -q x` isolates producer `b`.
  const pipeIdx = line.lastIndexOf("|", beforeIndex - 1);
  if (pipeIdx !== -1 && line[pipeIdx - 1] !== "|" && line[pipeIdx + 1] !== "|" && pipeIdx + 1 > best) best = pipeIdx + 1;
  return best;
}

// Also strips a bare leading `!` (pipeline negation with no keyword):
// `! printf ... | grep -Fq x || fail` is the same race with an inverted
// status, and was invisible to the producer extraction before 261025-vdn.
const LEADING_KEYWORD_PATTERN = /^\s*(?:(?:if|elif|while|until|then|do)\s+)?!?\s*/;

// Extracts the producer's command/function name immediately preceding the
// pipe at `pipeIndex` -- the first word of the nearest preceding simple
// command, after stripping a leading shell keyword (`if`, `if !`, etc.).
export function extractProducer(line, pipeIndex) {
  const boundaryEnd = findBoundaryEnd(line, pipeIndex);
  let segment = line.slice(boundaryEnd, pipeIndex);
  segment = segment.replace(LEADING_KEYWORD_PATTERN, "").trimStart();
  const tokenMatch = /^([A-Za-z_][\w./-]*)/.exec(segment);
  return tokenMatch ? tokenMatch[1] : null;
}

const GREP_CONSUMER_PATTERN = /\|\s*grep\b([^\n]*)/g;

// Scans one file's source and returns every `producer | grep` pipeline found
// (for inspected-count reporting) plus the subset that are OFFENDERS: a
// non-exempted producer (builtin or not) feeding a `-q`/`-v` grep consumer under
// `set -...pipefail`. Files without pipefail are not scanned at all (a
// script without `set -o pipefail` passes, unconditionally).
export function scanFile(relativePath, source) {
  if (!hasPipefail(source)) return { pipelines: [], offenders: [] };
  const lines = source.split("\n");
  const pipelines = [];
  const offenders = [];
  for (let lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    const line = lines[lineIndex];
    if (line.trim().startsWith("#")) continue;
    const exemptSpans = findExemptCommandSubstitutionSpans(line);
    GREP_CONSUMER_PATTERN.lastIndex = 0;
    let match;
    while ((match = GREP_CONSUMER_PATTERN.exec(line)) !== null) {
      const pipeIndex = match.index;
      const producer = extractProducer(line, pipeIndex);
      if (!producer) continue;
      const flagChars = extractGrepFlagChars(match[1]);
      const isQOrV = flagChars.includes("q") || flagChars.includes("v");
      const pipeline = { file: relativePath, line: lineIndex + 1, producer, flagChars, isQOrV };
      pipelines.push(pipeline);
      if (!isQOrV) continue;
      if (isWithinExemptSpan(pipeIndex, exemptSpans)) continue;
      offenders.push(pipeline);
    }
  }
  return { pipelines, offenders };
}

// -- allowlist ----------------------------------------------------------------

// An allowlist entry with an empty (or whitespace-only) reason is treated as
// no entry at all -- checked unconditionally, independent of whether any
// offender currently maps to it, so a bad commit cannot smuggle in a silent
// exemption ahead of the offender that would use it.
export function assertAllowlistReasons(allowlist) {
  for (const [key, reason] of allowlist.entries()) {
    if (typeof reason !== "string" || reason.trim() === "") {
      fail(`allowlist entry "${key}" has an empty reason -- an entry without a committed reason is not an allowlist entry`);
    }
  }
}

export function applyAllowlist(offenders, allowlist) {
  assertAllowlistReasons(allowlist);
  return offenders.filter((offender) => !allowlist.has(`${offender.file}#${offender.line}`));
}

// -- repo-level enumeration ---------------------------------------------------

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, "--no-optional-locks", ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout;
}

export function liveShCohort(repo) {
  return git(repo, ["ls-files", "scripts/ci/*.sh"]).split("\n").filter(Boolean).sort();
}

// Fails when the cohort is empty -- "a run inspecting zero files fails
// rather than reporting a pass" is a named negative control.
export function assertCohortNonEmpty(cohort) {
  if (!Array.isArray(cohort) || cohort.length === 0) {
    fail("cohort is empty -- refusing to report a pass over zero inspected files");
  }
}

export function collectOffenders(repo, cohort) {
  let pipelineCount = 0;
  const offenders = [];
  for (const relativePath of cohort) {
    const source = fs.readFileSync(path.join(repo, relativePath), "utf8");
    const { pipelines, offenders: fileOffenders } = scanFile(relativePath, source);
    pipelineCount += pipelines.length;
    offenders.push(...fileOffenders);
  }
  return { pipelineCount, offenders };
}

export function verifyIdiomBan(repo) {
  const cohort = liveShCohort(repo);
  assertCohortNonEmpty(cohort);
  const { pipelineCount, offenders } = collectOffenders(repo, cohort);
  const remaining = applyAllowlist(offenders, IDIOM_ALLOWLIST);
  if (remaining.length) {
    const named = remaining
      .map((offender) => `${offender.file}:${offender.line} (producer "${offender.producer}")`)
      .join("; ");
    const hasBuiltin = remaining.some((offender) => BUILTIN_PRODUCERS.has(offender.producer));
    const hasExternal = remaining.some((offender) => !BUILTIN_PRODUCERS.has(offender.producer));
    const hints = [];
    if (hasBuiltin) hints.push("for a printf/echo producer, use a here-string so grep has no producer to race: grep -Fq needle <<<\"$var\" (commit 5561a9a9)");
    if (hasExternal) hints.push("for an external/function producer, remediate with capture-then-filter: out=$(producer); case \"$out\" in ... esac");
    fail(
      `${remaining.length} '| grep -q/-v' pipeline(s) under pipefail: ${named} -- ${hints.join("; ")}`
    );
  }
  return { files: cohort.length, pipelines: pipelineCount, offenders: offenders.length };
}

// -- fixtures ------------------------------------------------------------------

function withScratchRepo(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-pipefail-idiom-"));
  try {
    spawnSync("git", ["-C", dir, "init", "-q"], { encoding: "utf8" });
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function seedShFile(dir, name, content) {
  fs.mkdirSync(path.join(dir, "scripts", "ci"), { recursive: true });
  fs.writeFileSync(path.join(dir, "scripts", "ci", name), content);
  spawnSync("git", ["-C", dir, "add", "-A"], { encoding: "utf8" });
}

const SCENARIOS = [
  [
    "a fixture script with set -euo pipefail and an awk producer feeding grep -Fq fails, naming file, line, and the capture-then-filter remediation",
    () => {
      withScratchRepo((dir) => {
        seedShFile(dir, "bad.sh", 'set -euo pipefail\nif awk \'{print}\' "$f" | grep -Fq needle; then echo hi; fi\n');
        assert.throws(
          () => verifyIdiomBan(dir),
          /scripts\/ci\/bad\.sh:2 \(producer "awk"\).*capture-then-filter/s
        );
      });
    }
  ],
  [
    "the same shape with grep -qv as the consumer fails",
    () => {
      const source = "set -euo pipefail\nif sed -n '1p' \"$f\" | grep -qv skip; then echo hi; fi\n";
      const { offenders } = scanFile("scripts/ci/bad-qv.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "sed");
    }
  ],
  [
    "the same shape with bare grep -v as the consumer fails",
    () => {
      const source = "set -euo pipefail\nif find . -name '*.sh' | grep -v skip; then echo hi; fi\n";
      const { offenders } = scanFile("scripts/ci/bad-v.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "find");
    }
  ],
  [
    "the same shape with a git producer fails",
    () => {
      const source = "set -euo pipefail\nif git log --oneline | grep -q fix; then echo hi; fi\n";
      const { offenders } = scanFile("scripts/ci/bad-git.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "git");
    }
  ],
  [
    "the same shape with a cat producer fails",
    () => {
      const source = "set -euo pipefail\nif cat \"$f\" | grep -q needle; then echo hi; fi\n";
      const { offenders } = scanFile("scripts/ci/bad-cat.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "cat");
    }
  ],
  [
    "a shell-function producer fails",
    () => {
      const source = 'set -euo pipefail\nif describe_port_owner "$p" | grep -q .; then echo hi; fi\n';
      const { offenders } = scanFile("scripts/ci/bad-fn.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "describe_port_owner");
    }
  ],
  [
    "an allowlist entry whose recorded reason is an empty string fails",
    () => {
      const allowlist = new Map([["scripts/ci/bad.sh#2", ""]]);
      assert.throws(() => assertAllowlistReasons(allowlist), /empty reason/);
      assert.throws(() => applyAllowlist([], allowlist), /empty reason/);
    }
  ],
  [
    "a run inspecting zero files fails rather than reporting a pass",
    () => {
      assert.throws(() => assertCohortNonEmpty([]), /zero inspected files/);
    }
  ],
  [
    "a builtin printf producer feeding grep -Fq under set -euo pipefail fails, naming the here-string remediation",
    () => {
      withScratchRepo((dir) => {
        seedShFile(dir, "bad-printf.sh", 'set -euo pipefail\nif printf \'%s\\n\' "$var" | grep -Fq needle; then echo hi; fi\n');
        assert.throws(
          () => verifyIdiomBan(dir),
          /scripts\/ci\/bad-printf\.sh:2 \(producer "printf"\).*here-string.*<<<"\$var"/s
        );
      });
    }
  ],
  [
    "a builtin echo producer feeding grep -q under pipefail fails",
    () => {
      const source = 'set -euo pipefail\nif echo "$var" | grep -q needle; then echo hi; fi\n';
      const { offenders } = scanFile("scripts/ci/bad-echo.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "echo");
    }
  ],
  [
    "a bare `! printf ... | grep -Fq` negated pipeline under pipefail fails",
    () => {
      const source = 'set -euo pipefail\n    ! printf \'%s\\n\' "$out" | grep -Fq "$secret" || fail "leaked"\n';
      const { offenders } = scanFile("scripts/ci/bad-negated.sh", source);
      assert.equal(offenders.length, 1);
      assert.equal(offenders[0].producer, "printf");
    }
  ],
  [
    "grep reading the variable from a <<< here-string passes",
    () => {
      const source = 'set -euo pipefail\nif grep -Fq needle <<<"$var"; then echo hi; fi\ngrep -Eq \'a|b\' <<<"$var" || fail "missing"\n';
      const { offenders, pipelines } = scanFile("scripts/ci/ok-herestring.sh", source);
      assert.equal(offenders.length, 0);
      assert.equal(pipelines.length, 0);
    }
  ],
  [
    "a printf producer feeding grep -v inside a $( ... ) capture ending || true passes",
    () => {
      const source = 'set -euo pipefail\nrest=$(printf \'%s\\n\' "$lines" | grep -v \'^#\' || true)\n';
      const { offenders, pipelines } = scanFile("scripts/ci/ok-printf-absorbed.sh", source);
      assert.equal(pipelines.length, 1, "the pipeline must be seen (non-vacuous) and then exempted");
      assert.equal(offenders.length, 0);
    }
  ],
  [
    "a printf producer feeding grep -q in a file WITHOUT pipefail passes",
    () => {
      const source = 'set -eu\nif printf \'%s\\n\' "$var" | grep -q needle; then echo hi; fi\n';
      const { offenders } = scanFile("scripts/ci/ok-printf-no-pipefail.sh", source);
      assert.equal(offenders.length, 0);
    }
  ],
  [
    "a pipeline captured in $( ... ) ending || true passes",
    () => {
      const source = 'set -euo pipefail\nout=$(producer_cmd | grep -q needle || true)\n';
      const { offenders } = scanFile("scripts/ci/ok-absorbed.sh", source);
      assert.equal(offenders.length, 0);
    }
  ],
  [
    "a script without set -o pipefail passes",
    () => {
      const source = 'if awk \'{print}\' "$f" | grep -Fq needle; then echo hi; fi\n';
      const { offenders, pipelines } = scanFile("scripts/ci/ok-no-pipefail.sh", source);
      assert.equal(offenders.length, 0);
      assert.equal(pipelines.length, 0);
    }
  ],
  [
    "the two remediated host scripts pass",
    () => {
      withScratchRepo((dir) => {
        for (const name of ["accrue_host_verify_dev_boot.sh", "accrue_host_verify_browser.sh"]) {
          const source = fs.readFileSync(path.join(process.cwd(), "scripts", "ci", name), "utf8");
          const { offenders } = scanFile(`scripts/ci/${name}`, source);
          assert.equal(offenders.length, 0, `${name} must have zero offending pipelines after remediation`);
        }
      });
    }
  ],
  [
    "a repo-level run over the live cohort resolves zero offenders and reports non-vacuous counts",
    () => {
      const repo = path.resolve(process.cwd());
      const result = verifyIdiomBan(repo);
      assert.ok(result.files > 0);
      assert.ok(result.pipelines > 0);
      assert.equal(result.offenders, 0);
    }
  ]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// -- entrypoint ----------------------------------------------------------------

const BOOLEAN_FLAGS = new Set(["fixtures", "require-idiom-ban"]);
const VALUE_OPTIONS = new Set(["repo"]);

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

function main() {
  const parsed = options(process.argv.slice(2));
  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    const suffix = parsed.flags.has("require-idiom-ban")
      ? ` (fixtures: require-idiom-ban; ${count} scenarios)`
      : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    console.log(`pipefail grep idiom: PASS${suffix}`);
    return;
  }

  const repo = parsed.values.repo || process.cwd();
  if (!parsed.flags.has("require-idiom-ban")) {
    // Schema-only invocation: still enumerate to prove the cohort is
    // non-empty, but do not enforce the ban.
    const cohort = liveShCohort(repo);
    assertCohortNonEmpty(cohort);
    console.log(`pipefail grep idiom: PASS (schema-only: no strict flags supplied; ${cohort.length} files)`);
    return;
  }

  const result = verifyIdiomBan(repo);
  console.log(`pipefail grep idiom: PASS (verified: require-idiom-ban; ${result.files} files, ${result.pipelines} pipelines, ${result.offenders} offenders)`);
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
    console.error(error.message.startsWith("pipefail grep idiom:") ? error.message : `pipefail grep idiom: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
