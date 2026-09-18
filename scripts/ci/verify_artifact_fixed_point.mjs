#!/usr/bin/env node
//
// SL-G (quick task 260917-l7v): no generated artifact may derive a field from
// an artifact that, in turn, checksums it.
//
// THE DEFECT THIS ENCODES. `232-UAT.md` used to derive its `started:` and
// `updated:` front-matter fields from `232-VERIFICATION.md`'s `verified:`
// field, while `232-VERIFICATION.md`'s `covered_digest` covers
// `232-UAT.md`. That is a derivation CYCLE: every verifier run bumps
// `verified:`, which rewrites the UAT, which re-stales the digest, which
// requires another verifier run -- forever. The only fixed point reachable
// under that shape was a hand-written digest, and it cost real time during
// the phase-232 close. The cycle is broken at its source as part of this
// same task: scripts/ci/verify_executable_uat_contract.mjs's
// `renderAutomatedUat()` now sources `started:`/`updated:` from the phase's
// own SUMMARY `completed:` dates instead of VERIFICATION's `verified:` --
// those dates are written once when a plan finishes and do not change on a
// later verification re-run, so regenerating the UAT artifact is a fixed
// point. This file is the guard that proves it, and that catches the shape
// again if it ever comes back.
//
// THREE CHECKS, in increasing strength:
//
// CHECK 1 -- CYCLE DETECTION (--require-acyclic). Builds a directed graph
// over phase artifacts with two kinds of edge: a DERIVES edge (artifact A's
// front matter takes a value from artifact B, declared by a machine-readable
// `derived_from: <path>[#field]` key) and a COVERS edge (B's `covered_files`
// lists A, alongside a `covered_digest`). Fails on any cycle, printing the
// full edge list that closes it -- naming the specific edges is what makes a
// cycle fixable rather than merely reported. No live artifact declares
// `derived_from:` today (the fix above removed the only derivation this
// task found); the fixtures below reproduce the exact pre-fix 232 shape as a
// negative control.
//
// CHECK 2 -- FIXED POINT (--require-fixed-point). The weaker but
// always-available property: regenerate each known generated artifact into a
// scratch file and require its bytes to be identical to the committed file.
// Any diff is a FAIL naming the first changed line. Normalizes nothing -- a
// normalization step here would hide exactly the timestamp churn this exists
// to catch. Only artifacts this file KNOWS how to regenerate are checked
// (today: `*-UAT.md` files carrying `source: executable-summary-coverage`,
// regenerated via verify_executable_uat_contract.mjs's `renderAutomatedUat`)
// -- this is a deliberately narrow, documented registry, not a claim of
// covering every renderer in this repository.
//
// CHECK 3 -- DIGEST TRUTH (--require-digest-match). Recomputes each
// `covered_digest` from its declared `covered_files` set (sorted path order,
// `sha256` over `path \0 bytes \0` per file, prefixed `v1:sha256:`) and
// requires equality with the committed value. This is what makes a
// hand-written digest fail, closing the escape hatch that was used to break
// the cycle by hand before this task. A committed `covered_digest` goes
// stale the moment ANY of its covered files changes after this guard is
// wired in -- that is the check doing its job, not a bug; the remediation is
// to recompute and commit the new value alongside the change that touched a
// covered file.
//
// SCOPE. Default (no --phase) resolves the phase from .planning/STATE.md's
// `current_phase:`, matching this repo's other current-phase-scoped tools --
// NOT every phase in the repository. Recomputing every historical phase's
// covered_digest is out of scope for this task and would touch dozens of
// unrelated, already-closed phase directories; this guard only re-verifies
// the phase actively being worked on.
//
// ANTI-VACUITY. Each of the three checks fails outright when it would
// otherwise inspect zero items (zero edges, zero regenerable artifacts, zero
// covered_digest artifacts) rather than silently reporting a pass. The PASS
// line names artifacts inspected, edges built, regenerations compared, and
// digests checked.

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { renderAutomatedUat } from "./verify_executable_uat_contract.mjs";

const fail = (message) => { throw new Error(`artifact fixed point: FAIL: ${message}`); };

// -- frontmatter parsing (self-contained; mirrors the convention already
// established in verify_executable_uat_contract.mjs) --------------------------

function frontmatter(source, file) {
  const match = source.match(/^---\n([\s\S]*?)\n---(?:\n|$)/);
  if (!match) fail(`${file}: missing YAML frontmatter`);
  return match[1];
}

function scalar(metadata, key) {
  const match = metadata.match(new RegExp(`^${key}:\\s*["']?([^\\n"']+)["']?\\s*$`, "m"));
  return match?.[1]?.trim();
}

function listField(metadata, key) {
  const lines = metadata.split("\n");
  const start = lines.findIndex((line) => line === `${key}:`);
  if (start === -1) return [];
  const items = [];
  for (const line of lines.slice(start + 1)) {
    const match = line.match(/^\s+-\s*["']?([^"'\n]+)["']?\s*$/);
    if (!match) break;
    items.push(match[1].trim());
  }
  return items;
}

// -- pure graph construction and cycle detection -------------------------------

export function scanArtifact(relativePath, source) {
  const metadata = frontmatter(source, relativePath);
  return {
    relativePath,
    derivedFrom: scalar(metadata, "derived_from"),
    coveredFiles: listField(metadata, "covered_files"),
    coveredDigest: scalar(metadata, "covered_digest")
  };
}

export function buildEdges(artifacts) {
  const edges = [];
  for (const artifact of artifacts) {
    if (artifact.derivedFrom) {
      const [target] = artifact.derivedFrom.split("#");
      edges.push({ from: artifact.relativePath, to: target.trim(), kind: "DERIVES", label: artifact.derivedFrom });
    }
    for (const covered of artifact.coveredFiles) {
      edges.push({ from: artifact.relativePath, to: covered, kind: "COVERS" });
    }
  }
  return edges;
}

// Colour-marking DFS over the directed edge list; returns the edge sequence
// closing the first cycle found, or null. A self-loop (an artifact whose own
// covered_files or derived_from names itself) is a length-1 cycle and is
// caught by the same mechanism.
export function findCycle(edges) {
  const adjacency = new Map();
  const nodes = new Set();
  for (const edge of edges) {
    if (!adjacency.has(edge.from)) adjacency.set(edge.from, []);
    adjacency.get(edge.from).push(edge);
    nodes.add(edge.from);
    nodes.add(edge.to);
  }

  const state = new Map(); // undefined = unvisited, 1 = visiting, 2 = done
  const pathStack = [];

  function dfs(node) {
    state.set(node, 1);
    for (const edge of adjacency.get(node) || []) {
      pathStack.push(edge);
      const nextState = state.get(edge.to);
      if (nextState === 1) {
        const cycleStart = pathStack.findIndex((candidate) => candidate.from === edge.to);
        return pathStack.slice(cycleStart === -1 ? 0 : cycleStart);
      }
      if (nextState !== 2) {
        const found = dfs(edge.to);
        if (found) return found;
      }
      pathStack.pop();
    }
    state.set(node, 2);
    return null;
  }

  for (const node of nodes) {
    if (state.get(node) === undefined) {
      const found = dfs(node);
      if (found) return found;
    }
  }
  return null;
}

export function assertAcyclic(edges) {
  if (!Array.isArray(edges) || edges.length === 0) {
    fail("zero artifact pairs discovered -- refusing to report a pass over zero inspected edges");
  }
  const cycle = findCycle(edges);
  if (cycle) {
    const named = cycle.map((edge) => `${edge.from} --${edge.kind}--> ${edge.to}`).join("; ");
    fail(`derivation cycle detected: ${named}`);
  }
  return edges.length;
}

// -- CHECK 2: fixed point --------------------------------------------------------

function firstDiffLine(committed, regenerated) {
  const committedLines = committed.split("\n");
  const regeneratedLines = regenerated.split("\n");
  const max = Math.max(committedLines.length, regeneratedLines.length);
  for (let index = 0; index < max; index += 1) {
    if (committedLines[index] !== regeneratedLines[index]) {
      return { line: index + 1, before: committedLines[index] ?? "<missing>", after: regeneratedLines[index] ?? "<missing>" };
    }
  }
  return null;
}

export function assertFixedPoint(pairs) {
  if (!Array.isArray(pairs) || pairs.length === 0) {
    fail("zero generated artifacts discovered -- refusing to report a pass over zero regenerations");
  }
  for (const pair of pairs) {
    if (pair.committedContent !== pair.regeneratedContent) {
      const diff = firstDiffLine(pair.committedContent, pair.regeneratedContent);
      fail(
        `${pair.relativePath}: regeneration is not a byte-level no-op -- first changed field at line ${diff.line}: ` +
        `"${diff.before}" -> "${diff.after}"`
      );
    }
  }
  return pairs.length;
}

// -- CHECK 3: digest truth -------------------------------------------------------

// The `covered_digest` field is NOT this guard's to define. It is GSD's
// covered-input fingerprint (#4155): the GSD runtime reads the same field, under
// the same `v1:sha256:` version tag, to decide whether a phase is `passed` or
// permanently `stale`. An independent formula here -- even a perfectly
// deterministic one -- makes this guard a SECOND writer to a field that already
// has an owner, and `FINGERPRINT_VERSION` cannot arbitrate between them because
// both would stamp `v1`. That is exactly what shipped in the first cut of this
// file: a rolling `path \0 bytes \0` hash that agreed with itself and with
// nothing else, which read phase 232 as matching while GSD read it as stale
// forever. The formula below is GSD's, reproduced byte-for-byte from
// gsd-core/bin/lib/verification.cjs#computeCoveredDigest:
//
//   canonicalize (posix-normalize -> de-dup -> sort)
//   per file:   parts.push(`${rel}\n${sha256(bytes)}\n`)
//   aggregate:  sha256(`v1\n` + parts.join("")) over utf-8
//
// If GSD bumps FINGERPRINT_VERSION, this function must be updated in lockstep or
// removed -- never left to stamp a stale `v1` under a new definition.
const FINGERPRINT_VERSION = 1;

function canonicalizeCoveredFiles(files) {
  return Array.from(new Set(files.map((f) => path.posix.normalize(String(f).split(path.sep).join("/"))))).sort();
}

// A covered_files entry is recorded relative to the repo at mint time. A later
// milestone close moves .planning/phases/NNN-*/ under
// .planning/milestones/<version>-phases/, so resolve the recorded path first
// and fall back to the archive rather than failing on a correct move.
function resolveCoveredPath(repo, rel) {
  const direct = path.resolve(repo, rel);
  if (fs.existsSync(direct)) return direct;
  const prefix = ".planning/phases/";
  if (!rel.startsWith(prefix)) return null;
  const remainder = rel.slice(prefix.length);
  const milestonesRoot = path.join(repo, ".planning", "milestones");
  for (const archive of archivePhaseRoots(repo)) {
    const candidate = path.join(milestonesRoot, archive, remainder);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

export function computeDigest(repo, coveredFiles) {
  if (!Array.isArray(coveredFiles) || coveredFiles.length === 0) {
    fail("covered_files is empty -- refusing to compute a digest over zero files");
  }
  const uniqueSorted = canonicalizeCoveredFiles(coveredFiles);
  if (uniqueSorted.length === 0) {
    fail("covered_files canonicalized to zero entries -- refusing to compute a digest over zero files");
  }
  const parts = [];
  for (const rel of uniqueSorted) {
    if (rel === "" || rel === ".." || rel.startsWith("../") || path.isAbsolute(rel)) {
      fail(`covered file escapes the repository root: ${rel}`);
    }
    const absolute = resolveCoveredPath(repo, rel);
    if (!absolute) fail(`covered file missing on disk: ${rel}`);
    const fileHash = crypto.createHash("sha256").update(fs.readFileSync(absolute)).digest("hex");
    // The recorded `rel` string -- never the resolved location -- feeds the
    // digest, so archiving a phase directory does not perturb a fingerprint
    // minted before the move.
    parts.push(`${rel}\n${fileHash}\n`);
  }
  const aggregate = crypto
    .createHash("sha256")
    .update(`v${FINGERPRINT_VERSION}\n${parts.join("")}`, "utf-8")
    .digest("hex");
  return `v${FINGERPRINT_VERSION}:sha256:${aggregate}`;
}

export function assertDigestMatch(repo, verificationArtifacts) {
  if (!Array.isArray(verificationArtifacts) || verificationArtifacts.length === 0) {
    fail("zero covered_digest artifacts discovered -- refusing to report a pass over zero inspected digests");
  }
  for (const artifact of verificationArtifacts) {
    const fresh = computeDigest(repo, artifact.coveredFiles);
    if (fresh !== artifact.coveredDigest) {
      fail(
        `${artifact.relativePath}: covered_digest mismatch over ${artifact.coveredFiles.length} covered files -- ` +
        `committed "${artifact.coveredDigest}", recomputed "${fresh}"`
      );
    }
  }
  return verificationArtifacts.length;
}

// -- repo-level enumeration, scoped to the current phase -----------------------

function git(repo, args) {
  const result = spawnSync("git", ["-C", repo, "--no-optional-locks", ...args], { encoding: "utf8", shell: false, timeout: 20000, maxBuffer: 5_000_000 });
  if (result.error || result.status !== 0) fail(`git ${args[0]} failed: ${(result.stderr || result.error?.message || "unknown error").trim().slice(0, 400)}`);
  return result.stdout;
}

function readStateCurrentPhase(repo) {
  const source = fs.readFileSync(path.join(repo, ".planning", "STATE.md"), "utf8");
  const metadata = frontmatter(source, ".planning/STATE.md");
  const phase = scalar(metadata, "current_phase");
  if (!phase) fail(".planning/STATE.md: current_phase is missing");
  return phase;
}

function matchPhaseDir(root, phase) {
  let entries;
  try {
    entries = fs.readdirSync(root, { withFileTypes: true }).filter((entry) => entry.isDirectory());
  } catch {
    return null;
  }
  return entries.find((entry) => entry.name === phase || entry.name.startsWith(`${phase}-`)) || null;
}

function archivePhaseRoots(repo) {
  try {
    return fs.readdirSync(path.join(repo, ".planning", "milestones"), { withFileTypes: true })
      .filter((entry) => entry.isDirectory() && entry.name.endsWith("-phases"))
      .map((entry) => entry.name)
      .sort();
  } catch {
    return [];
  }
}

// A milestone close archives .planning/phases/NNN-*/ into
// .planning/milestones/<version>-phases/NNN-*/ while STATE.md's current_phase
// still names the last phase of the milestone that just shipped. Resolving the
// active tree only would fail on that routine, correct operation, so fall back
// to the archive -- the same archive-aware fallback the phase-230 evidence-path
// sweep established for this class of regression.
function resolveActivePhaseDir(repo, phase) {
  const activeRoot = path.join(repo, ".planning", "phases");
  const active = matchPhaseDir(activeRoot, phase);
  if (active) {
    return { name: active.name, prefix: `.planning/phases/${active.name}`, absolute: path.join(activeRoot, active.name) };
  }
  const milestonesRoot = path.join(repo, ".planning", "milestones");
  for (const archive of archivePhaseRoots(repo)) {
    const archived = matchPhaseDir(path.join(milestonesRoot, archive), phase);
    if (archived) {
      return {
        name: archived.name,
        prefix: `.planning/milestones/${archive}/${archived.name}`,
        absolute: path.join(milestonesRoot, archive, archived.name)
      };
    }
  }
  fail(`phase ${phase}: no phase directory found under ${activeRoot} or any .planning/milestones/*-phases/`);
}

function liveArtifactFiles(repo, phase) {
  const { prefix } = resolveActivePhaseDir(repo, phase);
  const tracked = git(repo, ["ls-files", `${prefix}/*`]).split("\n").filter(Boolean);
  return tracked.filter((file) => /-VERIFICATION\.md$|-UAT\.md$/.test(file)).sort();
}

function loadArtifacts(repo, files) {
  return files.map((relativePath) => scanArtifact(relativePath, fs.readFileSync(path.join(repo, relativePath), "utf8")));
}

export function liveEdges(repo, phase) {
  return buildEdges(loadArtifacts(repo, liveArtifactFiles(repo, phase)));
}

export function liveVerificationArtifacts(repo, phase) {
  const files = liveArtifactFiles(repo, phase).filter((file) => /-VERIFICATION\.md$/.test(file));
  return loadArtifacts(repo, files).filter((artifact) => artifact.coveredDigest && artifact.coveredFiles.length > 0);
}

// The narrow, documented generator registry (see header CHECK 2): only
// `*-UAT.md` files carrying the executable-summary-coverage marker are known
// generated artifacts today.
export function liveGeneratedUatPairs(repo, phase) {
  const { absolute: phaseDir } = resolveActivePhaseDir(repo, phase);
  const uatFiles = liveArtifactFiles(repo, phase).filter((file) => /-UAT\.md$/.test(file));
  const generated = uatFiles.filter((relativePath) =>
    /^source:\s*executable-summary-coverage\s*$/m.test(fs.readFileSync(path.join(repo, relativePath), "utf8"))
  );
  if (generated.length === 0) return [];
  const scratch = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-artifact-fixed-point-"));
  try {
    return generated.map((relativePath) => {
      const committedContent = fs.readFileSync(path.join(repo, relativePath), "utf8");
      const regeneratedContent = renderAutomatedUat(phaseDir);
      const scratchFile = path.join(scratch, path.basename(relativePath));
      fs.writeFileSync(scratchFile, regeneratedContent);
      return { relativePath, committedContent, regeneratedContent: fs.readFileSync(scratchFile, "utf8") };
    });
  } finally {
    fs.rmSync(scratch, { recursive: true, force: true });
  }
}

// -- fixtures ------------------------------------------------------------------

function withScratch(fn) {
  const dir = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), "gsd-artifact-fixed-point-fixture-"));
  try {
    return fn(dir);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

const SCENARIOS = [
  [
    "a fixture pair where A's front matter derives from B, and B's covered_digest covers A, fails -- naming both artifacts and the two edges that close the cycle (the exact pre-fix 232-UAT.md / 232-VERIFICATION.md shape)",
    () => {
      const artifacts = [
        scanArtifact("fixtures/A-UAT.md", '---\nstatus: complete\nderived_from: "fixtures/B-VERIFICATION.md#verified"\n---\n'),
        scanArtifact("fixtures/B-VERIFICATION.md", '---\ncovered_files:\n  - "fixtures/A-UAT.md"\ncovered_digest: "v1:sha256:deadbeef"\n---\n')
      ];
      assert.throws(
        () => assertAcyclic(buildEdges(artifacts)),
        /fixtures\/A-UAT\.md --DERIVES--> fixtures\/B-VERIFICATION\.md.*fixtures\/B-VERIFICATION\.md --COVERS--> fixtures\/A-UAT\.md/s
      );
    }
  ],
  [
    "a fixture pair at a non-fixed point (regenerating A changes A's bytes) fails, naming the changed field",
    () => {
      const pairs = [{
        relativePath: "fixtures/A-UAT.md",
        committedContent: "---\nupdated: 2026-01-01\nfoo: bar\n---\n",
        regeneratedContent: "---\nupdated: 2026-01-02\nfoo: bar\n---\n"
      }];
      assert.throws(
        () => assertFixedPoint(pairs),
        /fixtures\/A-UAT\.md.*not a byte-level no-op.*updated: 2026-01-01.*updated: 2026-01-02/s
      );
    }
  ],
  [
    "a fixture whose covered_digest does not match a freshly computed digest of its covered set fails",
    () => {
      withScratch((dir) => {
        fs.writeFileSync(path.join(dir, "covered.txt"), "hello\n");
        const artifact = {
          relativePath: "fixtures/V.md",
          coveredFiles: ["covered.txt"],
          coveredDigest: "v1:sha256:0000000000000000000000000000000000000000000000000000000000000000"
        };
        assert.throws(() => assertDigestMatch(dir, [artifact]), /fixtures\/V\.md.*covered_digest mismatch/s);
      });
    }
  ],
  [
    "a run inspecting zero artifact pairs fails rather than reporting a pass (acyclic)",
    () => {
      assert.throws(() => assertAcyclic([]), /zero artifact pairs discovered/);
    }
  ],
  [
    "a run regenerating zero generated artifacts fails rather than reporting a pass (fixed-point)",
    () => {
      assert.throws(() => assertFixedPoint([]), /zero generated artifacts discovered/);
    }
  ],
  [
    "a run inspecting zero covered_digest artifacts fails rather than reporting a pass (digest-match)",
    () => {
      assert.throws(() => assertDigestMatch(process.cwd(), []), /zero covered_digest artifacts discovered/);
    }
  ],
  [
    "a pair where A's derived fields come only from sources OUTSIDE B's covered set passes",
    () => {
      const artifacts = [
        scanArtifact("fixtures/A.md", '---\nderived_from: "fixtures/C.md#value"\n---\n'),
        scanArtifact("fixtures/B.md", '---\ncovered_files:\n  - "fixtures/A.md"\ncovered_digest: "v1:sha256:xyz"\n---\n'),
        scanArtifact("fixtures/C.md", '---\nvalue: 1\n---\n')
      ];
      assert.doesNotThrow(() => assertAcyclic(buildEdges(artifacts)));
    }
  ],
  [
    "a pair at a fixed point -- regenerating A is a byte-level no-op -- passes",
    () => {
      const content = "---\nstarted: 2026-01-01\nupdated: 2026-01-02\n---\n";
      assert.doesNotThrow(() => assertFixedPoint([{ relativePath: "fixtures/A.md", committedContent: content, regeneratedContent: content }]));
    }
  ],
  [
    "computeDigest reproduces GSD's covered-input fingerprint exactly (golden vector)",
    () => {
      // NOT `computeDigest(...) === computeDigest(...)`: that is a self-referential
      // oracle -- it holds for ANY deterministic formula, including the wrong one
      // this file originally shipped. The constant below was cross-checked against
      // the GSD runtime's own computeCoveredDigest (gsd-core/bin/lib/verification.cjs)
      // for the single file "covered.txt" containing "hello\n". If a future edit to
      // computeDigest changes the formula, this fails -- which is the point: GSD
      // reads the same `covered_digest` field under the same v1 tag, and a second
      // definition of v1 makes every fingerprinted phase permanently stale.
      withScratch((dir) => {
        fs.writeFileSync(path.join(dir, "covered.txt"), "hello\n");
        assert.strictEqual(
          computeDigest(dir, ["covered.txt"]),
          "v1:sha256:7611c9ba460e3089f57dd59c63321e6c5065b0d6bf5ac037dda0224bcbed6256"
        );
      });
    }
  ],
  [
    "computeDigest canonicalizes like GSD does -- de-duplicated, posix-normalized, sorted",
    () => {
      withScratch((dir) => {
        fs.writeFileSync(path.join(dir, "covered.txt"), "hello\n");
        // Same single distinct file expressed three ways must fold to the same
        // digest as the canonical one-entry list, because GSD folds them too.
        assert.strictEqual(
          computeDigest(dir, ["./covered.txt", "covered.txt", "a/../covered.txt"]),
          "v1:sha256:7611c9ba460e3089f57dd59c63321e6c5065b0d6bf5ac037dda0224bcbed6256"
        );
      });
    }
  ],
  [
    "a covered_digest matching a freshly computed digest over real files on disk passes",
    () => {
      withScratch((dir) => {
        fs.writeFileSync(path.join(dir, "covered.txt"), "hello\n");
        const digest = computeDigest(dir, ["covered.txt"]);
        assert.doesNotThrow(() => assertDigestMatch(dir, [{ relativePath: "fixtures/V.md", coveredFiles: ["covered.txt"], coveredDigest: digest }]));
      });
    }
  ],
  [
    "a covered_digest computed under the SUPERSEDED rolling-hash formula is rejected",
    () => {
      withScratch((dir) => {
        fs.writeFileSync(path.join(dir, "covered.txt"), "hello\n");
        // The formula this file originally shipped: sha256 over `path \0 bytes \0`
        // streamed into one rolling hash, stamped -- fatally -- as the same `v1`.
        const legacy = crypto.createHash("sha256");
        legacy.update(Buffer.from("covered.txt", "utf8"));
        legacy.update(Buffer.from([0]));
        legacy.update(fs.readFileSync(path.join(dir, "covered.txt")));
        legacy.update(Buffer.from([0]));
        const stale = `v1:sha256:${legacy.digest("hex")}`;
        assert.throws(() => assertDigestMatch(dir, [{ relativePath: "fixtures/V.md", coveredFiles: ["covered.txt"], coveredDigest: stale }]));
      });
    }
  ],
  [
    "the live 232-UAT.md / 232-VERIFICATION.md pair passes all three checks after the cycle is broken at its source",
    () => {
      const repo = path.resolve(process.cwd());
      const phase = "232";
      const edges = liveEdges(repo, phase);
      assert.ok(edges.length > 0, "expected covered_files edges to be discovered for phase 232");
      assert.doesNotThrow(() => assertAcyclic(edges));
      const pairs = liveGeneratedUatPairs(repo, phase);
      assert.ok(pairs.length > 0, "expected at least one generated UAT artifact for phase 232");
      assert.doesNotThrow(() => assertFixedPoint(pairs));
      const verificationArtifacts = liveVerificationArtifacts(repo, phase);
      assert.ok(verificationArtifacts.length > 0, "expected at least one covered_digest artifact for phase 232");
      assert.doesNotThrow(() => assertDigestMatch(repo, verificationArtifacts));
    }
  ]
];

export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// -- entrypoint ------------------------------------------------------------------

const BOOLEAN_FLAGS = new Set(["fixtures", "require-acyclic", "require-fixed-point", "require-digest-match"]);
const VALUE_OPTIONS = new Set(["repo", "phase"]);

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
  const requestedStrictFlags = [...BOOLEAN_FLAGS].filter((flag) => flag !== "fixtures" && parsed.flags.has(flag)).sort();

  if (parsed.flags.has("fixtures")) {
    const count = verifyFixtures();
    const suffix = requestedStrictFlags.length
      ? ` (fixtures: ${requestedStrictFlags.join(", ")}; ${count} scenarios)`
      : ` (fixtures: no strict flags requested; ${count} scenarios)`;
    console.log(`artifact fixed point: PASS${suffix}`);
    return;
  }

  // path.resolve, not a bare fallback to process.cwd(): a relative --repo
  // (e.g. the literal "--repo ." this guard is wired with in ci.yml) breaks
  // verify_executable_uat_contract.mjs's archiveAwareVerificationRef, whose
  // archive-vs-active resolution depends on finding a leading "/.planning/"
  // in the phaseDir string it is handed -- a relative phaseDir silently
  // short-circuits that resolution and leaves a stale, unresolved ref in
  // place instead of throwing, which is exactly the kind of silent-pass this
  // guard exists to catch. Always hand renderAutomatedUat an absolute path.
  const repo = path.resolve(parsed.values.repo || process.cwd());
  const phase = parsed.values.phase || readStateCurrentPhase(repo);

  const files = liveArtifactFiles(repo, phase);
  if (files.length === 0) fail(`phase ${phase}: zero artifacts discovered -- refusing to report a pass over zero inspected artifacts`);

  let edgesBuilt = 0, regenerationsCompared = 0, digestsChecked = 0;
  if (parsed.flags.has("require-acyclic")) edgesBuilt = assertAcyclic(liveEdges(repo, phase));
  if (parsed.flags.has("require-fixed-point")) regenerationsCompared = assertFixedPoint(liveGeneratedUatPairs(repo, phase));
  if (parsed.flags.has("require-digest-match")) digestsChecked = assertDigestMatch(repo, liveVerificationArtifacts(repo, phase));

  const suffix = requestedStrictFlags.length
    ? ` (verified: ${requestedStrictFlags.join(", ")}; phase ${phase}, artifacts: ${files.length}, edges: ${edgesBuilt}, regenerations compared: ${regenerationsCompared}, digests checked: ${digestsChecked})`
    : ` (schema-only: no strict flags supplied; phase ${phase}, ${files.length} artifacts)`;
  console.log(`artifact fixed point: PASS${suffix}`);
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
    console.error(error.message.startsWith("artifact fixed point:") ? error.message : `artifact fixed point: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
