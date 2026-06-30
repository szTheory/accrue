import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const DEFAULT_SIGNOFF_PATH = path.join(REPO_ROOT, PHASE200_DIR, "200-SIGN-OFF.md");

export const REQUIRED_PHASE200_ARTIFACTS = [
  "baseline.union.cells.json",
  "final.cells.json",
  "scorecard.delta.json",
  "regressions.ndjson",
  "artifacts.manifest.json",
  "200-SCORECARD.md",
  "200-STORYBOOK-COVERAGE.md",
  "200-VERIFICATION.md",
  "judge.findings.json",
];

const BLOCKING_SEVERITIES = new Set(["BLOCKER", "REPAIR-IN-PHASE"]);
const COVERAGE_RANK = new Map([
  ["pending", -1],
  ["missing", -1],
  ["unreachable", -1],
  ["gap", 0],
  ["n/a", 1],
  ["covered", 2],
]);

const REQUIRED_SECTIONS = [
  { name: "Executive Status", pattern: /executive status/i },
  { name: "Deterministic Artifact Summary", pattern: /deterministic artifact summary/i },
  { name: "Four-Lens Judge Findings", pattern: /four-lens judge findings/i },
  { name: "Required Repairs", pattern: /required repairs/i },
  { name: "Maintainer Checkpoint", pattern: /maintainer checkpoint/i },
];

const ACCEPT_GUARDRAIL_MARKERS = [
  "verify_phase200_scorecard",
  "verify_phase200_signoff",
  "storybook",
  "phase199",
  "reduced-motion",
  "host",
];

function repoRelative(absPath) {
  return path.relative(REPO_ROOT, absPath).split(path.sep).join("/");
}

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Unable to read ${filePath}: ${error.message}`);
  }
}

function readJson(filePath, failures, label) {
  try {
    return JSON.parse(readFile(filePath));
  } catch (error) {
    failures.malformedArtifacts.push(`${label}: ${error.message}`);
    return null;
  }
}

function readNdjson(filePath, failures, label) {
  try {
    return readFile(filePath)
      .split(/\r?\n/)
      .filter((line) => line.trim().length > 0)
      .map((line, index) => {
        try {
          return JSON.parse(line);
        } catch (error) {
          failures.malformedArtifacts.push(`${label}:${index + 1}: ${error.message}`);
          return null;
        }
      })
      .filter(Boolean);
  } catch (error) {
    failures.missingArtifacts.push(`${label}: ${error.message}`);
    return [];
  }
}

function rowsFrom(value) {
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.rows)) return value.rows;
  if (value && Array.isArray(value.cells)) return value.cells;
  if (value && Array.isArray(value.findings)) return value.findings;
  return [];
}

function normalize(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/`/g, "")
    .replace(/[_/]+/g, " ")
    .replace(/[^a-z0-9:. -]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasAny(source, markers) {
  const normalized = normalize(source);
  return markers.some((marker) => normalized.includes(normalize(marker)));
}

function sectionSource(markdown, headingMatcher) {
  const lines = markdown.split(/\r?\n/);
  const start = lines.findIndex((line) => /^#{1,4}\s+/.test(line) && headingMatcher.test(line));
  if (start === -1) return "";
  const out = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^#{1,4}\s+/.test(lines[index])) break;
    out.push(lines[index]);
  }
  return out.join("\n");
}

function evidenceRefs(source) {
  return Array.from(
    new Set(
      String(source)
        .match(/(?:accrue_admin\/test-results\/|accrue_admin\/playwright-report\/|\.planning\/phases\/200-idempotent-verification-sign-off\/)[^\s),\]|]+/g) ||
        []
    )
  );
}

function validEvidenceRef(ref) {
  if (!ref || path.isAbsolute(ref) || ref.includes("\\") || ref.split("/").includes("..")) return false;
  return (
    ref.startsWith("accrue_admin/test-results/") ||
    ref.startsWith("accrue_admin/playwright-report/") ||
    ref.startsWith(`${PHASE200_DIR}/`)
  );
}

function artifactPaths(phaseDir, overrides = {}) {
  return {
    baselineUnion: path.join(phaseDir, "baseline.union.cells.json"),
    finalCells: path.join(phaseDir, "final.cells.json"),
    delta: path.join(phaseDir, "scorecard.delta.json"),
    regressions: path.join(phaseDir, "regressions.ndjson"),
    manifest: path.join(phaseDir, "artifacts.manifest.json"),
    scorecardMarkdown: path.join(phaseDir, "200-SCORECARD.md"),
    storybookCoverageMarkdown: path.join(phaseDir, "200-STORYBOOK-COVERAGE.md"),
    verificationMarkdown: path.join(phaseDir, "200-VERIFICATION.md"),
    judgeFindings: path.join(phaseDir, "judge.findings.json"),
    ...overrides,
  };
}

function failureTemplate() {
  return {
    decision: [],
    structure: [],
    artifacts: [],
    evidence: [],
    missingArtifacts: [],
    malformedArtifacts: [],
    regressions: [],
    judgeFindings: [],
    staleState: [],
    scorecard: [],
    guardrails: [],
    rejectRepairs: [],
  };
}

function failureCount(failures) {
  return Object.values(failures).reduce((sum, rows) => sum + rows.length, 0);
}

function parseDecisionLine(markdown, failures) {
  const lines = markdown.split(/\r?\n/).filter((line) => line.startsWith("Final maintainer decision: "));
  if (lines.length !== 1) {
    failures.decision.push(`Expected exactly one final decision line, found ${lines.length}.`);
    return { decision: null, line: lines[0] || null };
  }

  const match = lines[0].match(/^Final maintainer decision: (ACCEPT|REJECT)\b/);
  if (!match) {
    failures.decision.push("Final decision line must start with Final maintainer decision: ACCEPT or Final maintainer decision: REJECT.");
    return { decision: null, line: lines[0] };
  }

  return { decision: match[1], line: lines[0] };
}

function validateStructure(markdown, failures) {
  for (const section of REQUIRED_SECTIONS) {
    if (!sectionSource(markdown, section.pattern).trim()) failures.structure.push(`Missing ${section.name} section.`);
  }

  for (const artifact of REQUIRED_PHASE200_ARTIFACTS) {
    if (!markdown.includes(artifact)) failures.artifacts.push(`200-SIGN-OFF.md must reference ${artifact}.`);
  }

  const refs = evidenceRefs(markdown);
  if (refs.length === 0) failures.evidence.push("200-SIGN-OFF.md must include concrete repo-relative evidence refs.");
  for (const ref of refs) {
    if (!validEvidenceRef(ref)) failures.evidence.push(`Invalid evidence ref: ${ref}`);
  }
}

function parseScore(value) {
  if (value === null || value === undefined || value === "") return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function coverageRank(value) {
  return COVERAGE_RANK.get(String(value || "")) ?? -99;
}

function unresolvedJudgeBlockers(judge) {
  return rowsFrom(judge).filter((finding) => {
    if (!BLOCKING_SEVERITIES.has(finding.severity)) return false;
    return !/^(resolved|closed)$/i.test(String(finding.status || ""));
  });
}

function commandStatusValue(value) {
  if (typeof value === "string") return value;
  if (value && typeof value === "object") return value.status || value.result || value.outcome;
  return "";
}

function markdownStatusPass(filePath, label, failures) {
  if (!fs.existsSync(filePath)) return;
  const body = readFile(filePath);
  if (!/^\*\*Status:\*\*\s*pass\b/im.test(body) && !/^Status:\s*pass\b/im.test(body)) {
    failures.guardrails.push(`ACCEPT requires ${label} to report pass status.`);
  }
}

function validateAcceptArtifacts(paths, failures) {
  for (const artifact of REQUIRED_PHASE200_ARTIFACTS) {
    const key = {
      "baseline.union.cells.json": "baselineUnion",
      "final.cells.json": "finalCells",
      "scorecard.delta.json": "delta",
      "regressions.ndjson": "regressions",
      "artifacts.manifest.json": "manifest",
      "200-SCORECARD.md": "scorecardMarkdown",
      "200-STORYBOOK-COVERAGE.md": "storybookCoverageMarkdown",
      "200-VERIFICATION.md": "verificationMarkdown",
      "judge.findings.json": "judgeFindings",
    }[artifact];
    if (!fs.existsSync(paths[key])) failures.missingArtifacts.push(`ACCEPT requires ${artifact}.`);
  }
  markdownStatusPass(paths.scorecardMarkdown, "200-SCORECARD.md", failures);
  markdownStatusPass(paths.storybookCoverageMarkdown, "200-STORYBOOK-COVERAGE.md", failures);
  markdownStatusPass(paths.verificationMarkdown, "200-VERIFICATION.md", failures);
}

function validateAcceptScorecard(paths, failures) {
  if (!fs.existsSync(paths.regressions)) return;
  const regressions = readNdjson(paths.regressions, failures, "regressions.ndjson");
  if (regressions.length > 0) {
    failures.regressions.push(`ACCEPT requires empty regressions.ndjson, found ${regressions.length} row(s).`);
  }

  if (fs.existsSync(paths.delta)) {
    const delta = rowsFrom(readJson(paths.delta, failures, "scorecard.delta.json"));
    const scoreDowngrades = delta.filter((row) => {
      const baseline = parseScore(row.baseline_score);
      const final = parseScore(row.final_score);
      return baseline !== null && (final === null || final < baseline);
    });
    const coverageDowngrades = delta.filter((row) => {
      const match = String(row.coverage_change || "").match(/^([^->]+)->(.+)$/);
      return match && coverageRank(match[2]) < coverageRank(match[1]);
    });
    if (scoreDowngrades.length > 0) failures.scorecard.push(`ACCEPT rejects ${scoreDowngrades.length} score downgrade row(s).`);
    if (coverageDowngrades.length > 0) failures.scorecard.push(`ACCEPT rejects ${coverageDowngrades.length} coverage downgrade row(s).`);
  }

  if (fs.existsSync(paths.finalCells)) {
    const finalCells = rowsFrom(readJson(paths.finalCells, failures, "final.cells.json"));
    const staleP193 = finalCells.filter((row) => {
      if (!String(row.cell_id || "").startsWith("p193__")) return false;
      return row.coverage_status !== "covered" || parseScore(row.score) === null || parseScore(row.score) < 2 || !Array.isArray(row.evidence_refs) || row.evidence_refs.length === 0;
    });
    if (staleP193.length > 0) {
      failures.staleState.push(`ACCEPT rejects ${staleP193.length} stale p193 row(s) without covered score >= 2 and evidence refs.`);
    }
  }
}

function validateAcceptJudge(paths, failures) {
  if (!fs.existsSync(paths.judgeFindings)) return;
  const judge = readJson(paths.judgeFindings, failures, "judge.findings.json");
  const blockers = unresolvedJudgeBlockers(judge);
  if (blockers.length > 0) {
    failures.judgeFindings.push(
      `ACCEPT rejects unresolved judge blockers: ${blockers.map((finding) => finding.id || finding.title || finding.severity).join(", ")}.`
    );
  }
}

function validateAcceptManifest(paths, markdown, failures) {
  if (fs.existsSync(paths.manifest)) {
    const manifest = readJson(paths.manifest, failures, "artifacts.manifest.json");
    const statuses = manifest && typeof manifest === "object" ? manifest.command_statuses || manifest.guardrails || {} : {};
    const failed = Object.entries(statuses).filter(([, value]) => !/^(pass|passed|ok|green)$/i.test(String(commandStatusValue(value))));
    if (failed.length > 0) failures.guardrails.push(`ACCEPT rejects failed guardrails in artifacts.manifest.json: ${failed.map(([name]) => name).join(", ")}.`);
  }

  const guardrailSource = `${sectionSource(markdown, /maintainer checkpoint/i)}\n${sectionSource(markdown, /deterministic artifact summary/i)}`;
  for (const marker of ACCEPT_GUARDRAIL_MARKERS) {
    if (!hasAny(guardrailSource, [marker])) failures.guardrails.push(`ACCEPT sign-off must mention ${marker} guardrail evidence.`);
  }
}

function validateReject(markdown, paths, failures) {
  const repairs = sectionSource(markdown, /required repairs/i);
  if (!/\b(P200-JUDGE-[0-9]+|missing artifact|regressions\.ndjson|final\.cells\.json|scorecard\.delta\.json)\b/i.test(repairs)) {
    failures.rejectRepairs.push("REJECT must name blocking finding IDs or exact missing repair artifacts.");
  }

  if (fs.existsSync(paths.judgeFindings)) {
    const judge = readJson(paths.judgeFindings, failures, "judge.findings.json");
    for (const blocker of unresolvedJudgeBlockers(judge)) {
      if (blocker.id && !markdown.includes(blocker.id)) {
        failures.rejectRepairs.push(`REJECT must name unresolved blocking finding ${blocker.id}.`);
      }
    }
  }
}

export function verifyPhase200Signoff(options = {}) {
  const signoffPath = path.resolve(options.signoffPath || DEFAULT_SIGNOFF_PATH);
  const phaseDir = path.resolve(options.phaseDir || path.dirname(signoffPath));
  const paths = artifactPaths(phaseDir, options.artifactPaths || {});
  const markdown = options.markdown ?? readFile(signoffPath);
  const failures = failureTemplate();

  const decision = parseDecisionLine(markdown, failures);
  validateStructure(markdown, failures);
  if (options.requireAccept && decision.decision !== "ACCEPT") {
    failures.decision.push("CI sign-off verification requires Final maintainer decision: ACCEPT.");
  }

  if (decision.decision === "ACCEPT") {
    validateAcceptArtifacts(paths, failures);
    validateAcceptScorecard(paths, failures);
    validateAcceptJudge(paths, failures);
    validateAcceptManifest(paths, markdown, failures);
    if (/\bhuman_needed\b/i.test(markdown)) failures.staleState.push("ACCEPT sign-off must not leave human_needed state.");
  }

  if (decision.decision === "REJECT") validateReject(markdown, paths, failures);

  return {
    ok: failureCount(failures) === 0,
    decision: decision.decision,
    summary: {
      signoff_path: signoffPath,
      artifact_refs: REQUIRED_PHASE200_ARTIFACTS.filter((artifact) => markdown.includes(artifact)).length,
      evidence_refs: evidenceRefs(markdown).length,
      failures: failureCount(failures),
    },
    failures,
  };
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, value);
}

function fixtureFinalCell(overrides = {}) {
  return {
    cell_id: "p193__fixture-flow__chromium-desktop__light__default-populated__d11",
    score: 2,
    coverage_status: "covered",
    evidence_refs: ["accrue_admin/test-results/phase200/page-flow-evidence.json"],
    ...overrides,
  };
}

function fixturePackage(root, overrides = {}) {
  fs.mkdirSync(root, { recursive: true });
  const paths = artifactPaths(root);
  const omit = new Set(overrides.omit || []);
  const writeUnlessOmitted = (key, writer) => {
    if (!omit.has(key)) writer();
  };

  writeUnlessOmitted("baselineUnion", () => writeJson(paths.baselineUnion, [fixtureFinalCell()]));
  writeUnlessOmitted("finalCells", () => writeJson(paths.finalCells, overrides.finalCells || [fixtureFinalCell()]));
  writeUnlessOmitted(
    "delta",
    () =>
      writeJson(paths.delta, overrides.delta || [{ cell_id: fixtureFinalCell().cell_id, baseline_score: 2, final_score: 2, coverage_change: "covered->covered" }])
  );
  writeUnlessOmitted("regressions", () => writeText(paths.regressions, overrides.regressions || ""));
  writeUnlessOmitted(
    "manifest",
    () =>
      writeJson(
        paths.manifest,
        overrides.manifest || {
          command_statuses: {
            verify_phase200_scorecard: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/scorecard.log" },
            verify_phase200_signoff: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/signoff.log" },
            storybook: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/storybook-a11y.json" },
            phase199: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/phase199.log" },
            "reduced-motion": { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/reduced-motion.log" },
            "host leak": { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/host-leak.log" },
          },
        }
      )
  );
  writeUnlessOmitted("scorecardMarkdown", () => writeText(paths.scorecardMarkdown, overrides.scorecardMarkdown || "# Phase 200 Scorecard\n\nStatus: pass\n"));
  writeUnlessOmitted(
    "storybookCoverageMarkdown",
    () => writeText(paths.storybookCoverageMarkdown, overrides.storybookCoverageMarkdown || "# Phase 200 Storybook Coverage\n\nStatus: pass\n")
  );
  writeUnlessOmitted("verificationMarkdown", () => writeText(paths.verificationMarkdown, overrides.verificationMarkdown || "# Phase 200 Verification\n\nStatus: pass\n"));
  writeUnlessOmitted(
    "judgeFindings",
    () =>
      writeJson(
        paths.judgeFindings,
        overrides.judge || {
          findings: [],
          summary: { blocking_findings: 0 },
        }
      )
  );

  return paths;
}

function signoffMarkdown(decision = "ACCEPT", repairIds = []) {
  const phase = PHASE200_DIR;
  const artifactList = REQUIRED_PHASE200_ARTIFACTS.map((artifact) => `- ${phase}/${artifact}`).join("\n");
  const repairList =
    repairIds.length > 0
      ? repairIds.map((id) => `- ${id}: repair the blocking evidence, regenerate artifacts, and rerun verify_phase200_scorecard plus verify_phase200_signoff.`).join("\n")
      : "- None. Structured artifacts have no unresolved blocking rows.";

  return `# Phase 200 Maintainer Sign-Off

## Executive Status

${decision} - Phase 200 sign-off is ${decision === "ACCEPT" ? "accepted by structured evidence" : "rejected until named repairs are complete"}.

## Deterministic Artifact Summary

${artifactList}

Guardrail evidence: verify_phase200_scorecard, verify_phase200_signoff, Storybook, phase199, reduced-motion, and host leak checks.

## Four-Lens Judge Findings

| Finding | Lens | Severity | Status | Evidence |
| --- | --- | --- | --- | --- |
${repairIds.length > 0 ? repairIds.map((id) => `| ${id} | correctness | BLOCKER | open | ${phase}/judge.findings.json |`).join("\n") : `| none | correctness | ADVISORY | resolved | ${phase}/judge.findings.json |`}

## Required Repairs

${repairList}

## Maintainer Checkpoint

| Check | Status | Evidence |
| --- | --- | --- |
| exact final decision line | ${decision} | ${phase}/200-SIGN-OFF.md |
| deterministic artifact package | ${decision} | ${phase}/artifacts.manifest.json |
| Storybook coverage report | ${decision} | ${phase}/200-STORYBOOK-COVERAGE.md |
| scorecard verifier | ${decision} | ${phase}/200-SCORECARD.md |

Final maintainer decision: ${decision}. Evidence source: ${phase}/artifacts.manifest.json and ${phase}/judge.findings.json.
`;
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  assertSelfTest(
    "required artifact list is locked",
    REQUIRED_PHASE200_ARTIFACTS.join(",") ===
      "baseline.union.cells.json,final.cells.json,scorecard.delta.json,regressions.ndjson,artifacts.manifest.json,200-SCORECARD.md,200-STORYBOOK-COVERAGE.md,200-VERIFICATION.md,judge.findings.json"
  );

  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-signoff-verifier-"));
  try {
    fixturePackage(path.join(root, "accept"));
    const accept = verifyPhase200Signoff({
      markdown: signoffMarkdown("ACCEPT"),
      signoffPath: path.join(root, "accept/200-SIGN-OFF.md"),
    });
    assertSelfTest("valid ACCEPT fixture passes", accept.ok, JSON.stringify(accept.failures));

    const rejectRoot = path.join(root, "reject");
    fixturePackage(rejectRoot, {
      judge: { findings: [{ id: "P200-JUDGE-001", severity: "BLOCKER", status: "open" }] },
    });
    const reject = verifyPhase200Signoff({
      markdown: signoffMarkdown("REJECT", ["P200-JUDGE-001"]),
      signoffPath: path.join(rejectRoot, "200-SIGN-OFF.md"),
    });
    assertSelfTest("verifier-clean REJECT fixture passes with named blocker", reject.ok, JSON.stringify(reject.failures));
    const rejectRequiredAccept = verifyPhase200Signoff({
      markdown: signoffMarkdown("REJECT", ["P200-JUDGE-001"]),
      signoffPath: path.join(rejectRoot, "200-SIGN-OFF.md"),
      requireAccept: true,
    });
    assertSelfTest("REJECT fails when requireAccept is enabled", !rejectRequiredAccept.ok);
    assertSelfTest("requireAccept reports decision failure", rejectRequiredAccept.failures.decision.length > 0);

    const noFinalLine = verifyPhase200Signoff({ markdown: signoffMarkdown("ACCEPT").replace(/^Final maintainer decision:.*$/m, ""), phaseDir: path.join(root, "accept") });
    assertSelfTest("missing final decision line fails", !noFinalLine.ok);
    assertSelfTest("decision section reports missing final line", noFinalLine.failures.decision.length > 0);

    const doubleFinalLine = verifyPhase200Signoff({
      markdown: `${signoffMarkdown("ACCEPT")}\nFinal maintainer decision: ACCEPT duplicate.\n`,
      phaseDir: path.join(root, "accept"),
    });
    assertSelfTest("multiple final decision lines fail", !doubleFinalLine.ok);

    fixturePackage(path.join(root, "regression"), {
      regressions: `${JSON.stringify({ id: "P200-REG-001", evidence_refs: ["accrue_admin/test-results/phase200/page-flow-evidence.json"] })}\n`,
    });
    const acceptRegression = verifyPhase200Signoff({ markdown: signoffMarkdown("ACCEPT"), signoffPath: path.join(root, "regression/200-SIGN-OFF.md") });
    assertSelfTest("ACCEPT with regressions fails", !acceptRegression.ok);
    assertSelfTest("regressions section reports failure", acceptRegression.failures.regressions.length > 0);

    fixturePackage(path.join(root, "blocker"), {
      judge: { findings: [{ id: "P200-JUDGE-002", severity: "REPAIR-IN-PHASE", status: "open" }] },
    });
    const acceptBlocker = verifyPhase200Signoff({ markdown: signoffMarkdown("ACCEPT"), signoffPath: path.join(root, "blocker/200-SIGN-OFF.md") });
    assertSelfTest("ACCEPT with unresolved blocking findings fails", !acceptBlocker.ok);
    assertSelfTest("judge findings section reports failure", acceptBlocker.failures.judgeFindings.length > 0);

    fixturePackage(path.join(root, "missing-storybook"), { omit: ["storybookCoverageMarkdown"] });
    const acceptMissing = verifyPhase200Signoff({
      markdown: signoffMarkdown("ACCEPT"),
      signoffPath: path.join(root, "missing-storybook/200-SIGN-OFF.md"),
    });
    assertSelfTest("ACCEPT with missing Storybook coverage report fails", !acceptMissing.ok);
    assertSelfTest("missing artifacts section reports Storybook coverage", acceptMissing.failures.missingArtifacts.some((failure) => /200-STORYBOOK-COVERAGE/.test(failure)));

    fixturePackage(path.join(root, "failed-storybook"), {
      storybookCoverageMarkdown: "# Phase 200 Storybook Coverage\n\n**Status:** fail\n",
    });
    const acceptFailedStorybook = verifyPhase200Signoff({
      markdown: signoffMarkdown("ACCEPT"),
      signoffPath: path.join(root, "failed-storybook/200-SIGN-OFF.md"),
    });
    assertSelfTest("ACCEPT with failed Storybook coverage report fails", !acceptFailedStorybook.ok);
    assertSelfTest("failed Storybook report is treated as guardrail failure", acceptFailedStorybook.failures.guardrails.length > 0);

    fixturePackage(path.join(root, "stale"), {
      finalCells: [fixtureFinalCell({ score: null, coverage_status: "pending", evidence_refs: [] })],
    });
    const acceptStale = verifyPhase200Signoff({ markdown: signoffMarkdown("ACCEPT"), signoffPath: path.join(root, "stale/200-SIGN-OFF.md") });
    assertSelfTest("ACCEPT with stale pending state fails", !acceptStale.ok);
    assertSelfTest("stale state section reports failure", acceptStale.failures.staleState.length > 0);

    console.log("Phase 200 sign-off verifier self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function reportFailures(title, failures) {
  console.error(title);
  for (const [section, items] of Object.entries(failures)) {
    if (items.length === 0) continue;
    console.error(`\n${section}:`);
    for (const item of items.slice(0, 40)) console.error(`- ${item}`);
    if (items.length > 40) console.error(`- ...and ${items.length - 40} more`);
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--signoff") options.signoffPath = path.resolve(argv[++index]);
    else if (arg === "--phase-dir") options.phaseDir = path.resolve(argv[++index]);
    else if (arg === "--require-accept") options.requireAccept = true;
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return options;
}

export function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.selfTest) {
    runSelfTest();
    return { ok: true };
  }

  const result = verifyPhase200Signoff(options);
  console.log(
    `Phase 200 sign-off verifier: decision=${result.decision || "invalid"}, artifact_refs=${result.summary.artifact_refs}, evidence_refs=${
      result.summary.evidence_refs
    }, failures=${result.summary.failures}`
  );

  if (!result.ok) {
    reportFailures("Phase 200 sign-off verification failed.", result.failures);
    process.exitCode = 1;
  } else {
    console.log("Phase 200 sign-off verification passed.");
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 sign-off verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
