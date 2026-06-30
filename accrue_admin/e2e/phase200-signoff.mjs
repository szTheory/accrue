import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { REQUIRED_PHASE200_ARTIFACTS, verifyPhase200Signoff } from "../../scripts/ci/verify_phase200_signoff.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");

const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE200_DIR);
const DEFAULT_OUTPUT = path.join(phaseDir, "200-SIGN-OFF.md");
const BLOCKING_SEVERITIES = new Set(["BLOCKER", "REPAIR-IN-PHASE"]);
const COVERAGE_RANK = new Map([
  ["pending", -1],
  ["missing", -1],
  ["unreachable", -1],
  ["gap", 0],
  ["n/a", 1],
  ["covered", 2],
]);

function phaseRef(fileName) {
  return `${PHASE200_DIR}/${fileName}`.replace(/\/+/g, "/");
}

function artifactPaths(root) {
  return {
    "baseline.union.cells.json": path.join(root, "baseline.union.cells.json"),
    "final.cells.json": path.join(root, "final.cells.json"),
    "scorecard.delta.json": path.join(root, "scorecard.delta.json"),
    "regressions.ndjson": path.join(root, "regressions.ndjson"),
    "artifacts.manifest.json": path.join(root, "artifacts.manifest.json"),
    "200-SCORECARD.md": path.join(root, "200-SCORECARD.md"),
    "200-STORYBOOK-COVERAGE.md": path.join(root, "200-STORYBOOK-COVERAGE.md"),
    "200-VERIFICATION.md": path.join(root, "200-VERIFICATION.md"),
    "judge.findings.json": path.join(root, "judge.findings.json"),
  };
}

function readFile(absPath) {
  return fs.readFileSync(absPath, "utf8");
}

function readJson(absPath) {
  return JSON.parse(readFile(absPath));
}

function readNdjson(absPath) {
  return readFile(absPath)
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line) => JSON.parse(line));
}

function rowsFrom(value) {
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.rows)) return value.rows;
  if (value && Array.isArray(value.cells)) return value.cells;
  if (value && Array.isArray(value.findings)) return value.findings;
  return [];
}

function parseScore(value) {
  if (value === null || value === undefined || value === "") return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function coverageRank(value) {
  return COVERAGE_RANK.get(String(value || "")) ?? -99;
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}

function writeJson(absPath, value) {
  writeText(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function loadJsonIfPresent(absPath) {
  if (!fs.existsSync(absPath)) return null;
  try {
    return readJson(absPath);
  } catch (error) {
    return { malformed: true, error: error.message };
  }
}

function loadNdjsonIfPresent(absPath) {
  if (!fs.existsSync(absPath)) return null;
  try {
    return readNdjson(absPath);
  } catch (error) {
    return { malformed: true, error: error.message };
  }
}

function unresolvedJudgeBlockers(judge) {
  return rowsFrom(judge).filter((finding) => {
    if (!BLOCKING_SEVERITIES.has(finding.severity)) return false;
    return !/^(resolved|closed)$/i.test(String(finding.status || ""));
  });
}

function downgradeRows(delta) {
  const score = [];
  const coverage = [];
  for (const row of rowsFrom(delta)) {
    const baseline = parseScore(row.baseline_score);
    const final = parseScore(row.final_score);
    if (baseline !== null && (final === null || final < baseline)) score.push(row);
    const match = String(row.coverage_change || "").match(/^([^->]+)->(.+)$/);
    if (match && coverageRank(match[2]) < coverageRank(match[1])) coverage.push(row);
  }
  return { score, coverage };
}

function stalePageFlowRows(finalCells) {
  return rowsFrom(finalCells).filter((row) => {
    if (!String(row.cell_id || "").startsWith("p193__")) return false;
    return row.coverage_status !== "covered" || parseScore(row.score) === null || parseScore(row.score) < 2 || !Array.isArray(row.evidence_refs) || row.evidence_refs.length === 0;
  });
}

function commandStatusValue(value) {
  if (typeof value === "string") return value;
  if (value && typeof value === "object") return value.status || value.result || value.outcome;
  return "";
}

function failedGuardrails(manifest) {
  const statuses = manifest && typeof manifest === "object" ? manifest.command_statuses || manifest.guardrails || {} : {};
  return Object.entries(statuses).filter(([, value]) => !/^(pass|passed|ok|green)$/i.test(String(commandStatusValue(value))));
}

function collectEvidence(options = {}) {
  const root = path.resolve(options.phaseDir || phaseDir);
  const artifacts = artifactPaths(root);
  const artifactRows = REQUIRED_PHASE200_ARTIFACTS.map((artifact) => ({
    artifact,
    ref: phaseRef(artifact),
    path: artifacts[artifact],
    status: fs.existsSync(artifacts[artifact]) ? "present" : "missing",
  }));

  const judge = loadJsonIfPresent(artifacts["judge.findings.json"]);
  const finalCells = loadJsonIfPresent(artifacts["final.cells.json"]);
  const delta = loadJsonIfPresent(artifacts["scorecard.delta.json"]);
  const regressions = loadNdjsonIfPresent(artifacts["regressions.ndjson"]);
  const manifest = loadJsonIfPresent(artifacts["artifacts.manifest.json"]);

  const missingArtifacts = artifactRows.filter((row) => row.status === "missing");
  const malformed = [
    ["judge.findings.json", judge],
    ["final.cells.json", finalCells],
    ["scorecard.delta.json", delta],
    ["regressions.ndjson", regressions],
    ["artifacts.manifest.json", manifest],
  ].filter(([, value]) => value?.malformed);

  const judgeBlockers = judge && !judge.malformed ? unresolvedJudgeBlockers(judge) : [];
  const regressionRows = Array.isArray(regressions) ? regressions : [];
  const downgrades = delta && !delta.malformed ? downgradeRows(delta) : { score: [], coverage: [] };
  const staleRows = finalCells && !finalCells.malformed ? stalePageFlowRows(finalCells) : [];
  const guardrailFailures = manifest && !manifest.malformed ? failedGuardrails(manifest) : [];
  const judgeCoveredArtifacts = new Set(judgeBlockers.map((finding) => finding.affected).filter(Boolean));

  const repairItems = [
    ...judgeBlockers.map((finding) => ({
      id: finding.id || "P200-JUDGE-UNKNOWN",
      lens: finding.lens || "correctness",
      severity: finding.severity,
      title: finding.title || "Unresolved judge blocker",
      locked_reference: finding.locked_reference || "VER-03",
      affected: finding.affected || "Phase 200 sign-off",
      evidence_refs: finding.evidence_refs || [phaseRef("judge.findings.json")],
      repair: finding.repair || "Repair the blocker, regenerate judge findings, and rerun sign-off.",
    })),
    ...missingArtifacts
      .filter((row) => (row.artifact !== "judge.findings.json" || judge === null) && !judgeCoveredArtifacts.has(row.artifact))
      .map((row) => ({
        id: `missing artifact: ${row.artifact}`,
        lens: row.artifact === "200-STORYBOOK-COVERAGE.md" ? "accessibility" : "correctness",
        severity: "BLOCKER",
        title: `Missing ${row.artifact}`,
        locked_reference: row.artifact === "200-STORYBOOK-COVERAGE.md" ? "STY-03" : "VER-03",
        affected: row.artifact,
        evidence_refs: [row.ref],
        repair: `Generate ${row.artifact} and rerun verify_phase200_signoff.`,
      })),
    ...malformed.map(([artifact, value]) => ({
      id: `malformed artifact: ${artifact}`,
      lens: "correctness",
      severity: "BLOCKER",
      title: `Malformed ${artifact}`,
      locked_reference: "VER-03",
      affected: artifact,
      evidence_refs: [phaseRef(artifact)],
      repair: `Regenerate ${artifact}: ${value.error}`,
    })),
    ...regressionRows.map((row, index) => ({
      id: row.id || row.cell_id || `regression row ${index + 1}`,
      lens: "correctness",
      severity: "BLOCKER",
      title: "Regression row remains",
      locked_reference: "VER-01",
      affected: row.cell_id || "regressions.ndjson",
      evidence_refs: row.evidence_refs || [phaseRef("regressions.ndjson")],
      repair: "Repair the regression, regenerate scorecard artifacts, and rerun sign-off.",
    })),
    ...downgrades.score.slice(0, 20).map((row) => ({
      id: row.cell_id || "score downgrade",
      lens: "correctness",
      severity: "BLOCKER",
      title: "Score downgrade row remains",
      locked_reference: "VER-01",
      affected: row.cell_id || "scorecard.delta.json",
      evidence_refs: row.evidence_refs || [phaseRef("scorecard.delta.json")],
      repair: "Repair the score downgrade and regenerate scorecard.delta.json.",
    })),
    ...downgrades.coverage.slice(0, 20).map((row) => ({
      id: row.cell_id || "coverage downgrade",
      lens: "correctness",
      severity: "BLOCKER",
      title: "Coverage downgrade row remains",
      locked_reference: "VER-01",
      affected: row.cell_id || "scorecard.delta.json",
      evidence_refs: row.evidence_refs || [phaseRef("scorecard.delta.json")],
      repair: "Repair the coverage downgrade and regenerate scorecard.delta.json.",
    })),
    ...staleRows.slice(0, 20).map((row) => ({
      id: row.cell_id || "stale page-flow row",
      lens: "interaction",
      severity: "BLOCKER",
      title: "Page-flow row is not closed",
      locked_reference: "VER-01",
      affected: row.cell_id || "final.cells.json",
      evidence_refs: row.evidence_refs || [phaseRef("final.cells.json")],
      repair: "Regenerate page-flow evidence so every p193 row is covered with score >= 2.",
    })),
    ...guardrailFailures.map(([name, value]) => ({
      id: `guardrail: ${name}`,
      lens: /storybook/i.test(name) ? "accessibility" : "correctness",
      severity: "BLOCKER",
      title: `Guardrail ${name} is not passed`,
      locked_reference: /storybook/i.test(name) ? "STY-03" : "VER-02",
      affected: name,
      evidence_refs: [value?.evidence_ref || phaseRef("artifacts.manifest.json")],
      repair: `Rerun and repair ${name}, then regenerate artifacts.manifest.json.`,
    })),
  ];

  const decision = repairItems.length === 0 ? "ACCEPT" : "REJECT";
  return {
    root,
    artifacts,
    artifactRows,
    judge,
    finalCells,
    delta,
    regressions: regressionRows,
    manifest,
    regressionsPresent: Array.isArray(regressions),
    repairItems,
    decision,
  };
}

function artifactStatusTable(rows) {
  return rows.map((row) => `| \`${row.artifact}\` | ${row.status.toUpperCase()} | \`${row.ref}\` |`).join("\n");
}

function judgeTable(items) {
  if (items.length === 0) {
    return `| none | correctness | ADVISORY | resolved | VER-03 | Phase 200 sign-off | \`${phaseRef("judge.findings.json")}\` |`;
  }

  return items
    .map(
      (item) =>
        `| ${item.id} | ${item.lens || "correctness"} | ${item.severity} | open | ${item.locked_reference} | ${String(item.affected || "").replace(/\|/g, "/")} | \`${(
          item.evidence_refs || [phaseRef("judge.findings.json")]
        ).join(", ")}\` |`
    )
    .join("\n");
}

function repairList(items) {
  if (items.length === 0) return "- None. Structured artifacts have no unresolved blocking rows.";
  return items
    .map(
      (item) =>
        `- ${item.id}: ${item.title}. Locked reference: ${item.locked_reference}. Affected: ${item.affected}. Evidence: \`${(
          item.evidence_refs || []
        ).join(", ")}\`. Repair: ${item.repair}`
    )
    .join("\n");
}

function scorecardSummary(evidence) {
  const finalCount = evidence.finalCells && !evidence.finalCells.malformed ? rowsFrom(evidence.finalCells).length : "missing";
  const deltaCount = evidence.delta && !evidence.delta.malformed ? rowsFrom(evidence.delta).length : "missing";
  const regressionCount = evidence.regressionsPresent ? evidence.regressions.length : "missing";
  return [
    `- Final cells: ${finalCount}`,
    `- Scorecard delta rows: ${deltaCount}`,
    `- Regression rows: ${regressionCount}`,
    `- Blocking repair rows: ${evidence.repairItems.length}`,
  ].join("\n");
}

function approvalDateFromEvidence(value) {
  const match = String(value || "").match(/\b(20\d{2}-\d{2}-\d{2})\b/);
  return match ? match[1] : null;
}

function readExistingApprovalCheckpoint(outputPath) {
  if (!fs.existsSync(outputPath)) return null;
  const body = readFile(outputPath);
  const checkpoint = body.match(/^\| Human checkpoint response \| ACCEPT \| (.+?) \|$/m);
  const finalLine = body.match(/^Final maintainer decision: ACCEPT \(maintainer approved (20\d{2}-\d{2}-\d{2})\)\./m);
  if (!checkpoint && !finalLine) return null;

  const evidence = checkpoint?.[1] || `User response \`approved\`, ${finalLine[1]}`;
  return {
    date: finalLine?.[1] || approvalDateFromEvidence(evidence),
    evidence,
  };
}

function renderMarkdown(evidence, { approvalCheckpoint = null } = {}) {
  const decisionSentence =
    evidence.decision === "ACCEPT" && approvalCheckpoint?.date
      ? `ACCEPT - maintainer approval was received on ${approvalCheckpoint.date}, and deterministic Phase 200 artifacts satisfy the all-or-nothing gate.`
      : evidence.decision === "ACCEPT"
      ? "ACCEPT - deterministic Phase 200 artifacts satisfy the all-or-nothing gate."
      : "REJECT - deterministic Phase 200 artifacts require the named repairs below before ACCEPT.";

  const finalLine =
    evidence.decision === "ACCEPT" && approvalCheckpoint?.date
      ? `Final maintainer decision: ACCEPT (maintainer approved ${approvalCheckpoint.date}). Evidence source: ${phaseRef("artifacts.manifest.json")} and ${phaseRef("judge.findings.json")}.`
      : evidence.decision === "ACCEPT"
      ? `Final maintainer decision: ACCEPT. Evidence source: ${phaseRef("artifacts.manifest.json")} and ${phaseRef("judge.findings.json")}.`
      : `Final maintainer decision: REJECT. Required repairs: ${
          evidence.repairItems
            .slice(0, 8)
            .map((item) => item.id)
            .join(", ") || "missing artifact package"
        }. Evidence source: ${phaseRef("judge.findings.json")}.`;
  const approvalRow =
    evidence.decision === "ACCEPT" && approvalCheckpoint?.evidence
      ? `| Human checkpoint response | ACCEPT | ${approvalCheckpoint.evidence} |`
      : "";

  return `# Phase 200 Maintainer Sign-Off

## Executive Status

${decisionSentence}

This file is the sole Phase 200 maintainer decision surface. Structured artifacts remain canonical; markdown summarizes the evidence and repair path.

## Deterministic Artifact Summary

| Artifact | Status | Reference |
| --- | --- | --- |
${artifactStatusTable(evidence.artifactRows)}

## Scorecard Gate Summary

${scorecardSummary(evidence)}

Guardrail evidence named for final ACCEPT: \`verify_phase200_scorecard\`, \`verify_phase200_signoff\`, Storybook, Phase 199 interaction regression, \`reduced-motion\`, and host leak checks.

## Four-Lens Judge Findings

| Finding | Lens | Severity | Status | Locked reference | Affected | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
${judgeTable(evidence.repairItems)}

## Required Repairs

${repairList(evidence.repairItems)}

## Maintainer Checkpoint

| Check | Status | Evidence |
| --- | --- | --- |
| Exact final decision line | ${evidence.decision} | \`${phaseRef("200-SIGN-OFF.md")}\` |
| verify_phase200_scorecard | ${evidence.decision} | \`${phaseRef("200-SCORECARD.md")}\` |
| verify_phase200_signoff | ${evidence.decision} | \`${phaseRef("200-SIGN-OFF.md")}\` |
| Storybook coverage report | ${evidence.decision} | \`${phaseRef("200-STORYBOOK-COVERAGE.md")}\` |
| Verification report | ${evidence.decision} | \`${phaseRef("200-VERIFICATION.md")}\` |
| Judge findings | ${evidence.decision} | \`${phaseRef("judge.findings.json")}\` |
| phase199 interaction regression | ${evidence.decision} | \`${phaseRef("artifacts.manifest.json")}\` |
| reduced-motion guardrail | ${evidence.decision} | \`${phaseRef("artifacts.manifest.json")}\` |
| host leak guardrail | ${evidence.decision} | \`${phaseRef("artifacts.manifest.json")}\` |
${approvalRow}

${finalLine}
`;
}

export function generatePhase200Signoff(options = {}) {
  const root = path.resolve(options.phaseDir || phaseDir);
  const outputPath = path.resolve(options.outputPath || DEFAULT_OUTPUT);
  const evidence = collectEvidence({ phaseDir: root });
  const markdown = renderMarkdown(evidence, { approvalCheckpoint: readExistingApprovalCheckpoint(outputPath) });
  const verification = verifyPhase200Signoff({ markdown, signoffPath: outputPath, phaseDir: root });
  if (!verification.ok) {
    throw new Error(`Generated Phase 200 sign-off failed verifier: ${JSON.stringify(verification.failures)}`);
  }

  if (options.write !== false && !options.dryRun) writeText(outputPath, markdown);
  return {
    decision: evidence.decision,
    markdown,
    summary: {
      decision: evidence.decision,
      repair_items: evidence.repairItems.length,
      artifacts: evidence.artifactRows.length,
      output_path: outputPath,
      dry_run: Boolean(options.dryRun),
    },
  };
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

function writeAcceptFixture(root) {
  fs.mkdirSync(root, { recursive: true });
  const artifacts = artifactPaths(root);
  writeJson(artifacts["baseline.union.cells.json"], [fixtureFinalCell()]);
  writeJson(artifacts["final.cells.json"], [fixtureFinalCell()]);
  writeJson(artifacts["scorecard.delta.json"], [
    { cell_id: fixtureFinalCell().cell_id, baseline_score: 2, final_score: 2, coverage_change: "covered->covered" },
  ]);
  writeText(artifacts["regressions.ndjson"], "");
  writeJson(artifacts["artifacts.manifest.json"], {
    command_statuses: {
      verify_phase200_scorecard: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/scorecard.log" },
      verify_phase200_signoff: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/signoff.log" },
      storybook: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/storybook-a11y.json" },
      phase199: { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/phase199.log" },
      "reduced-motion": { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/reduced-motion.log" },
      "host leak": { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/host-leak.log" },
    },
  });
  writeText(artifacts["200-SCORECARD.md"], "# Phase 200 Scorecard\n\nStatus: pass\n");
  writeText(artifacts["200-STORYBOOK-COVERAGE.md"], "# Phase 200 Storybook Coverage\n\nStatus: pass\n");
  writeText(artifacts["200-VERIFICATION.md"], "# Phase 200 Verification\n\nStatus: pass\n");
  writeJson(artifacts["judge.findings.json"], { findings: [], summary: { blocking_findings: 0 } });
}

function writeRejectFixture(root) {
  fs.mkdirSync(root, { recursive: true });
  const artifacts = artifactPaths(root);
  writeJson(artifacts["baseline.union.cells.json"], [fixtureFinalCell()]);
  writeJson(artifacts["judge.findings.json"], {
    findings: [
      {
        id: "P200-JUDGE-001",
        severity: "BLOCKER",
        status: "open",
        title: "Missing final cell artifact",
        locked_reference: "VER-01",
        affected: "final.cells.json",
        evidence_refs: [phaseRef("final.cells.json")],
        repair: "Generate final.cells.json and rerun verify_phase200_signoff.",
      },
    ],
  });
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-signoff-"));
  try {
    const rejectRoot = path.join(root, "reject");
    writeRejectFixture(rejectRoot);
    const reject = generatePhase200Signoff({
      phaseDir: rejectRoot,
      outputPath: path.join(rejectRoot, "200-SIGN-OFF.md"),
      dryRun: true,
      write: false,
    });
    assertSelfTest("generator writes verifier-clean REJECT when final evidence is absent", reject.decision === "REJECT");
    assertSelfTest("REJECT draft names blocking repair IDs", reject.markdown.includes("P200-JUDGE-001"));
    assertSelfTest("REJECT draft references every locked Phase 200 artifact", REQUIRED_PHASE200_ARTIFACTS.every((artifact) => reject.markdown.includes(artifact)));

    const acceptRoot = path.join(root, "accept");
    writeAcceptFixture(acceptRoot);
    const accept = generatePhase200Signoff({
      phaseDir: acceptRoot,
      outputPath: path.join(acceptRoot, "200-SIGN-OFF.md"),
      dryRun: true,
      write: false,
    });
    assertSelfTest("generator can produce verifier-clean ACCEPT for passing fixture", accept.decision === "ACCEPT");

    const outputRoot = path.join(root, "write");
    writeRejectFixture(outputRoot);
    const outputPath = path.join(outputRoot, "200-SIGN-OFF.md");
    generatePhase200Signoff({ phaseDir: outputRoot, outputPath });
    assertSelfTest("normal generation writes 200-SIGN-OFF.md", fs.existsSync(outputPath));

    console.log("Phase 200 sign-off generator self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--dry-run") options.dryRun = true;
    else if (arg === "--phase-dir") options.phaseDir = path.resolve(argv[++index]);
    else if (arg === "--output") options.outputPath = path.resolve(argv[++index]);
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

  const result = generatePhase200Signoff(options);
  console.log(
    `Phase 200 sign-off ${options.dryRun ? "dry-run" : "generated"}: decision=${result.summary.decision}, repairs=${
      result.summary.repair_items
    }, artifacts=${result.summary.artifacts}`
  );
  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 sign-off generator failed: ${error.message}`);
    process.exitCode = 1;
  }
}
