import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");

const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE200_DIR);

export const ALLOWED_LENSES = ["correctness", "accessibility", "brand", "interaction"];
export const ALLOWED_SEVERITIES = ["BLOCKER", "REPAIR-IN-PHASE", "ADVISORY", "DEFERRED"];

const BLOCKING_SEVERITIES = new Set(["BLOCKER", "REPAIR-IN-PHASE"]);
const DIRECT_PHASE200_REQUIREMENTS = new Set(["VER-01", "VER-02", "VER-03", "STY-02", "STY-03"]);

const COVERAGE_RANK = new Map([
  ["pending", -1],
  ["missing", -1],
  ["unreachable", -1],
  ["gap", 0],
  ["n/a", 1],
  ["covered", 2],
]);

const REQUIRED_ARTIFACTS = [
  {
    key: "baselineUnion",
    file: "baseline.union.cells.json",
    lens: "correctness",
    lockedReference: "VER-01",
    title: "Missing union baseline artifact",
  },
  {
    key: "finalCells",
    file: "final.cells.json",
    lens: "correctness",
    lockedReference: "VER-01",
    title: "Missing final cell artifact",
  },
  {
    key: "delta",
    file: "scorecard.delta.json",
    lens: "correctness",
    lockedReference: "VER-01",
    title: "Missing scorecard delta artifact",
  },
  {
    key: "regressions",
    file: "regressions.ndjson",
    lens: "correctness",
    lockedReference: "VER-01",
    title: "Missing regression ledger",
  },
  {
    key: "manifest",
    file: "artifacts.manifest.json",
    lens: "correctness",
    lockedReference: "VER-03",
    title: "Missing artifact manifest",
  },
  {
    key: "scorecardMarkdown",
    file: "200-SCORECARD.md",
    lens: "correctness",
    lockedReference: "VER-01",
    title: "Missing scorecard markdown summary",
  },
  {
    key: "storybookCoverageMarkdown",
    file: "200-STORYBOOK-COVERAGE.md",
    lens: "accessibility",
    lockedReference: "STY-03",
    title: "Missing Storybook coverage report",
  },
  {
    key: "verificationMarkdown",
    file: "200-VERIFICATION.md",
    lens: "correctness",
    lockedReference: "VER-02",
    title: "Missing verification report",
  },
];

const OPTIONAL_STRUCTURED_INPUTS = [
  {
    key: "storybookA11y",
    defaultPath: path.join(adminRoot, "test-results/phase200/storybook-a11y.json"),
    ref: "accrue_admin/test-results/phase200/storybook-a11y.json",
    lens: "accessibility",
    lockedReference: "VER-02",
  },
  {
    key: "pageFlowEvidence",
    defaultPath: path.join(adminRoot, "test-results/phase200/page-flow-evidence.json"),
    ref: "accrue_admin/test-results/phase200/page-flow-evidence.json",
    lens: "interaction",
    lockedReference: "VER-02",
  },
  {
    key: "hostLeakEvidence",
    defaultPath: path.join(adminRoot, "test-results/phase200/host-leak.json"),
    ref: "accrue_admin/test-results/phase200/host-leak.json",
    lens: "correctness",
    lockedReference: "VER-03",
  },
];

const REVIEWED_SCOPE_NOTES = [
  ["accrue_admin/e2e/README.md", "Browser debugging selector recipe for /reports."],
  ["accrue_admin/assets/js/theme_test.js", "Future DOM/theme unit tests for accrueTheme.setTheme and system mode."],
  ["packages/testing/test-utils/src/setup.ts", "Future non-browser DOM test helper."],
  ["accrue_admin/lib/accrue_admin/router.ex", "Future API-key bootstrap auth at /api/bootstrap, listed for Phase 202."],
  ["accrue_admin/test/accrue_admin/bootstrap_manual_flow_test.exs", "OAuth-before-bootstrap note."],
  ["accrue_admin/test/support/bootstrap_manual_flow.ex", "OAuth-before-bootstrap note."],
  ["accrue_admin/test/support/bootstrap_orchestrator.ex", "OAuth-before-bootstrap note."],
  ["accrue_admin/test/support/ui_case.ex", "Lazy dashboard bootstrap helper note."],
  ["crates/core/src/**/*.rs", "Future high-value finance engine modules."],
  ["packages/accrue-dsl/src/index.ts", "Placeholder DSL parser."],
];

function repoRelative(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function phaseRef(fileName) {
  return `${PHASE200_DIR}/${fileName}`.replace(/\/+/g, "/");
}

function evidenceRefFor(absPath, fallbackFile) {
  const rel = repoRelative(path.resolve(absPath));
  if (rel && !rel.startsWith("..") && rel !== "") return rel;
  return phaseRef(fallbackFile || path.basename(absPath));
}

function validEvidenceRef(ref) {
  const value = String(ref || "");
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return (
    value.startsWith("accrue_admin/test-results/") ||
    value.startsWith("accrue_admin/playwright-report/") ||
    value.startsWith(`${PHASE200_DIR}/`)
  );
}

function validLockedReference(ref) {
  const value = String(ref || "");
  return (
    DIRECT_PHASE200_REQUIREMENTS.has(value) ||
    /^rubric:d(0[1-9]|1[0-2])$/.test(value) ||
    /^brandbook\/(voice|copy)\.md$/.test(value) ||
    /^(component|group|page-flow)-contract:[a-z0-9._/-]+$/i.test(value) ||
    /^phase199-contract:[a-z0-9._/-]+$/i.test(value)
  );
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
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${absPath}:${index + 1}: ${error.message}`);
      }
    });
}

function rowsFrom(value) {
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.rows)) return value.rows;
  if (value && Array.isArray(value.cells)) return value.cells;
  if (value && Array.isArray(value.findings)) return value.findings;
  if (value && Array.isArray(value.evidence)) return value.evidence;
  return [];
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function parseScore(value) {
  if (value === null || value === undefined || value === "") return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function coverageRank(value) {
  return COVERAGE_RANK.get(String(value || "")) ?? -99;
}

function firstValidEvidence(refs, fallback) {
  const list = Array.isArray(refs) ? refs : [refs].filter(Boolean);
  return list.find((ref) => validEvidenceRef(ref)) || fallback;
}

function makeFinding({
  id,
  lens,
  severity,
  title,
  summary,
  lockedReference,
  supportingReferences = [],
  affected,
  evidenceRefs,
  repair,
  source,
  sourceKind,
}) {
  return {
    id,
    lens,
    severity,
    status: BLOCKING_SEVERITIES.has(severity) ? "open" : "recorded",
    title,
    summary,
    locked_reference: lockedReference,
    supporting_references: supportingReferences,
    affected,
    evidence_refs: Array.from(new Set([...(Array.isArray(evidenceRefs) ? evidenceRefs : [evidenceRefs])].filter(Boolean))),
    repair,
    source,
    source_kind: sourceKind,
  };
}

function scopeNotes() {
  return REVIEWED_SCOPE_NOTES.map(([ref, note], index) => ({
    id: `P200-SCOPE-${String(index + 1).padStart(2, "0")}`,
    ref,
    note,
    disposition: "non-blocking-scope-note",
    can_block: false,
    blocker_rule: "May escalate only with a direct VER-01, VER-02, VER-03, STY-02, or STY-03 deterministic gate failure.",
  }));
}

function buildPaths(options = {}) {
  const resolvedPhaseDir = path.resolve(options.phaseDir || phaseDir);
  const inputs = {
    baselineUnion: path.join(resolvedPhaseDir, "baseline.union.cells.json"),
    finalCells: path.join(resolvedPhaseDir, "final.cells.json"),
    delta: path.join(resolvedPhaseDir, "scorecard.delta.json"),
    regressions: path.join(resolvedPhaseDir, "regressions.ndjson"),
    manifest: path.join(resolvedPhaseDir, "artifacts.manifest.json"),
    scorecardMarkdown: path.join(resolvedPhaseDir, "200-SCORECARD.md"),
    storybookCoverageMarkdown: path.join(resolvedPhaseDir, "200-STORYBOOK-COVERAGE.md"),
    verificationMarkdown: path.join(resolvedPhaseDir, "200-VERIFICATION.md"),
  };

  for (const input of OPTIONAL_STRUCTURED_INPUTS) {
    inputs[input.key] = input.defaultPath;
  }

  return {
    phaseDir: resolvedPhaseDir,
    outputPath: path.resolve(options.outputPath || path.join(resolvedPhaseDir, "judge.findings.json")),
    inputs: { ...inputs, ...(options.inputs || {}) },
  };
}

function readStructuredInput(absPath, label, fallbackRef, findings, nextId, lens, lockedReference) {
  if (!fs.existsSync(absPath)) return { ok: false, missing: true, data: null, nextId };

  try {
    const data = absPath.endsWith(".ndjson") ? readNdjson(absPath) : readJson(absPath);
    return { ok: true, missing: false, data, nextId };
  } catch (error) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens,
        severity: "BLOCKER",
        title: `Malformed ${label}`,
        summary: `${label} could not be parsed: ${error.message}`,
        lockedReference,
        supportingReferences: ["D-25"],
        affected: label,
        evidenceRefs: fallbackRef,
        repair: `Regenerate ${label} and rerun the Phase 200 verifier before ACCEPT.`,
        source: "artifact-parse",
      })
    );
    return { ok: false, missing: false, data: null, nextId: nextId + 1 };
  }
}

function analyzeDelta(rows, deltaRef, findings, nextId) {
  const scoreDowngrades = [];
  const coverageDowngrades = [];

  for (const row of rowsFrom(rows)) {
    const baselineScore = parseScore(row.baseline_score);
    const finalScore = parseScore(row.final_score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) scoreDowngrades.push(row);

    const match = String(row.coverage_change || "").match(/^([^->]+)->(.+)$/);
    if (match && coverageRank(match[2]) < coverageRank(match[1])) coverageDowngrades.push(row);
    if (String(row.blocker_classification || "").includes("coverage-downgrade")) coverageDowngrades.push(row);
  }

  if (scoreDowngrades.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "correctness",
        severity: "BLOCKER",
        title: "Score downgrade rows remain in scorecard delta",
        summary: `${scoreDowngrades.length} scorecard delta row(s) have final score below the union baseline.`,
        lockedReference: "VER-01",
        supportingReferences: ["D-17", "D-28"],
        affected: scoreDowngrades.slice(0, 5).map((row) => row.cell_id || "(missing cell_id)").join(", "),
        evidenceRefs: firstValidEvidence(scoreDowngrades.flatMap((row) => row.evidence_refs || []), deltaRef),
        repair: "Repair the downgraded cells, regenerate final.cells.json and scorecard.delta.json, then rerun sign-off.",
        source: "scorecard.delta.json",
      })
    );
    nextId += 1;
  }

  if (coverageDowngrades.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "correctness",
        severity: "BLOCKER",
        title: "Coverage downgrade rows remain in scorecard delta",
        summary: `${coverageDowngrades.length} scorecard delta row(s) downgrade coverage against the union baseline.`,
        lockedReference: "VER-01",
        supportingReferences: ["D-17", "D-28"],
        affected: coverageDowngrades.slice(0, 5).map((row) => row.cell_id || "(missing cell_id)").join(", "),
        evidenceRefs: firstValidEvidence(coverageDowngrades.flatMap((row) => row.evidence_refs || []), deltaRef),
        repair: "Restore coverage to the union baseline or document a baseline correction, then regenerate artifacts.",
        source: "scorecard.delta.json",
      })
    );
    nextId += 1;
  }

  return nextId;
}

function analyzeRegressions(rows, regressionsRef, findings, nextId) {
  const regressions = rowsFrom(rows);
  if (regressions.length === 0) return nextId;

  findings.push(
    makeFinding({
      id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
      lens: "correctness",
      severity: "BLOCKER",
      title: "Regression ledger is not empty",
      summary: `${regressions.length} regression row(s) remain. ACCEPT requires an empty regressions.ndjson.`,
      lockedReference: "VER-01",
      supportingReferences: ["D-17", "D-28"],
      affected: regressions.slice(0, 5).map((row) => row.id || row.cell_id || row.kind || "(regression)").join(", "),
      evidenceRefs: firstValidEvidence(regressions.flatMap((row) => row.evidence_refs || []), regressionsRef),
      repair: "Repair the regression rows, regenerate scorecard artifacts, and rerun the Phase 200 verifier.",
      source: "regressions.ndjson",
    })
  );
  return nextId + 1;
}

function analyzeFinalCells(rows, finalCellsRef, findings, nextId) {
  const staleP193 = rowsFrom(rows).filter((row) => {
    const cellId = String(row.cell_id || "");
    if (!cellId.startsWith("p193__")) return false;
    return row.coverage_status !== "covered" || parseScore(row.score) === null || parseScore(row.score) < 2 || !Array.isArray(row.evidence_refs) || row.evidence_refs.length === 0;
  });

  if (staleP193.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "interaction",
        severity: "BLOCKER",
        title: "Pending page-flow cells are not closed",
        summary: `${staleP193.length} p193 page-flow row(s) are not covered with score >= 2 and deterministic evidence.`,
        lockedReference: "VER-01",
        supportingReferences: ["D-15", "D-28", "page-flow-contract:phase193"],
        affected: staleP193.slice(0, 5).map((row) => row.cell_id || "(missing cell_id)").join(", "),
        evidenceRefs: firstValidEvidence(staleP193.flatMap((row) => row.evidence_refs || []), finalCellsRef),
        repair: "Regenerate page-flow evidence and final.cells.json so every p193 row is covered with score >= 2.",
        source: "final.cells.json",
      })
    );
    return nextId + 1;
  }

  return nextId;
}

function commandStatusValue(value) {
  if (typeof value === "string") return value;
  if (value && typeof value === "object") return value.status || value.result || value.outcome;
  return "";
}

function commandEvidenceRef(name, value, fallback) {
  if (value && typeof value === "object") return value.evidence_ref || value.evidenceRef || value.ref || fallback;
  return fallback;
}

function analyzeManifest(manifest, manifestRef, findings, nextId) {
  const statuses = manifest && typeof manifest === "object" ? manifest.command_statuses || manifest.guardrails || {} : {};
  const failed = Object.entries(statuses).filter(([, value]) => !/^(pass|passed|ok|green)$/i.test(String(commandStatusValue(value))));
  const hostLeaks = failed.filter(([name]) => /host|adopter|leak/i.test(name));

  if (hostLeaks.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "correctness",
        severity: "BLOCKER",
        title: "Host or adopter leak evidence is unresolved",
        summary: `${hostLeaks.length} host/adopter leak guardrail status row(s) are not passed.`,
        lockedReference: "VER-03",
        supportingReferences: ["D-12", "D-28"],
        affected: hostLeaks.map(([name]) => name).join(", "),
        evidenceRefs: firstValidEvidence(hostLeaks.map(([name, value]) => commandEvidenceRef(name, value, manifestRef)), manifestRef),
        repair: "Fix the host/adopter leak boundary, regenerate artifacts.manifest.json, and rerun the sign-off verifier.",
        source: "artifacts.manifest.json",
      })
    );
    nextId += 1;
  }

  const nonHostFailures = failed.filter(([name]) => !/host|adopter|leak/i.test(name));
  if (nonHostFailures.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "correctness",
        severity: "BLOCKER",
        title: "Deterministic guardrail status is not green",
        summary: `${nonHostFailures.length} manifest guardrail status row(s) are not passed.`,
        lockedReference: "VER-02",
        supportingReferences: ["D-18", "D-28"],
        affected: nonHostFailures.map(([name]) => name).join(", "),
        evidenceRefs: firstValidEvidence(nonHostFailures.map(([name, value]) => commandEvidenceRef(name, value, manifestRef)), manifestRef),
        repair: "Rerun and repair the failed guardrail before ACCEPT.",
        source: "artifacts.manifest.json",
      })
    );
    nextId += 1;
  }

  return nextId;
}

function analyzeStorybookA11y(value, evidenceRef, findings, nextId) {
  const failing = rowsFrom(value).filter((row) => {
    const violations = Array.isArray(row.violations) ? row.violations : [];
    const serious = violations.some((violation) => /^(critical|serious)$/i.test(String(violation.impact || violation.severity || "")));
    return row.status !== "passed" || serious;
  });

  if (failing.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "accessibility",
        severity: "BLOCKER",
        title: "Storybook accessibility evidence has failures",
        summary: `${failing.length} rendered Storybook scan row(s) are failed or include critical/serious violations.`,
        lockedReference: "VER-02",
        supportingReferences: ["STY-03", "D-21"],
        affected: failing.slice(0, 5).map((row) => row.story_url || row.story || "(storybook row)").join(", "),
        evidenceRefs: evidenceRef,
        repair: "Repair the Storybook accessibility failure and rerun the Phase 200 Storybook scan.",
        source: "storybook-a11y.json",
      })
    );
    return nextId + 1;
  }

  return nextId;
}

function analyzePageFlowEvidence(value, evidenceRef, findings, nextId) {
  const stale = rowsFrom(value).filter((row) => {
    const cellId = String(row.cell_id || "");
    return cellId.startsWith("p193__") && (row.coverage_status !== "covered" || parseScore(row.score) === null || parseScore(row.score) < 2);
  });

  if (stale.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "interaction",
        severity: "BLOCKER",
        title: "Page-flow evidence leaves stale pending rows",
        summary: `${stale.length} page-flow evidence row(s) fail the covered/score >= 2 closure rule.`,
        lockedReference: "VER-02",
        supportingReferences: ["D-15", "D-28", "page-flow-contract:phase193"],
        affected: stale.slice(0, 5).map((row) => row.cell_id || "(missing cell_id)").join(", "),
        evidenceRefs: evidenceRef,
        repair: "Regenerate page-flow evidence with covered rows and score >= 2 before final sign-off.",
        source: "page-flow-evidence.json",
      })
    );
    return nextId + 1;
  }

  return nextId;
}

function analyzeHostLeakEvidence(value, evidenceRef, findings, nextId) {
  const rows = rowsFrom(value);
  const leaks = rows.filter((row) => {
    if (row.leak === true || row.host_leak === true || row.adopter_leak === true) return true;
    if (Array.isArray(row.leaks) && row.leaks.length > 0) return true;
    if (/fail|failed|blocked/i.test(String(row.status || row.outcome || ""))) return true;
    return /host|adopter|leak/i.test(String(row.kind || row.id || "")) && !/pass|passed/i.test(String(row.status || ""));
  });

  if (leaks.length > 0) {
    findings.push(
      makeFinding({
        id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
        lens: "correctness",
        severity: "BLOCKER",
        title: "Host leak evidence is unresolved",
        summary: `${leaks.length} host/adopter leak row(s) remain in structured evidence.`,
        lockedReference: "VER-03",
        supportingReferences: ["D-12", "D-28"],
        affected: leaks.slice(0, 5).map((row) => row.id || row.path || row.kind || "(host leak row)").join(", "),
        evidenceRefs: evidenceRef,
        repair: "Remove the host/adopter leak, regenerate evidence, and rerun final sign-off.",
        source: "host-leak.json",
      })
    );
    return nextId + 1;
  }

  return nextId;
}

function validateFindings(findings) {
  const failures = [];
  for (const finding of findings) {
    if (!ALLOWED_LENSES.includes(finding.lens)) failures.push(`${finding.id || "(finding)"} has invalid lens ${finding.lens}.`);
    if (!ALLOWED_SEVERITIES.includes(finding.severity)) {
      failures.push(`${finding.id || "(finding)"} has invalid severity ${finding.severity}.`);
    }

    if (finding.source_kind === "reviewed_todo" && BLOCKING_SEVERITIES.has(finding.severity)) {
      if (!DIRECT_PHASE200_REQUIREMENTS.has(finding.locked_reference)) {
        failures.push(`${finding.id || "(finding)"} reviewed todo cannot block without a direct Phase 200 requirement reference.`);
      }
    }

    if (BLOCKING_SEVERITIES.has(finding.severity)) {
      if (!validLockedReference(finding.locked_reference)) {
        failures.push(`${finding.id || "(finding)"} blocking finding is missing an allowed locked reference.`);
      }
      if (!String(finding.affected || "").trim()) failures.push(`${finding.id || "(finding)"} blocking finding is missing affected scope.`);
      if (!Array.isArray(finding.evidence_refs) || finding.evidence_refs.length === 0) {
        failures.push(`${finding.id || "(finding)"} blocking finding is missing evidence refs.`);
      } else {
        for (const ref of finding.evidence_refs) {
          if (!validEvidenceRef(ref)) failures.push(`${finding.id || "(finding)"} has invalid evidence ref ${ref}.`);
        }
      }
    }
  }

  if (failures.length > 0) throw new Error(failures.join("\n"));
}

function summaryFor(findings, notes) {
  const counts = Object.fromEntries(ALLOWED_SEVERITIES.map((severity) => [severity, 0]));
  for (const finding of findings) counts[finding.severity] = (counts[finding.severity] || 0) + 1;
  const blocking = findings.filter((finding) => BLOCKING_SEVERITIES.has(finding.severity));
  return {
    status: blocking.length === 0 ? "clear" : "blocked",
    findings: findings.length,
    blocking_findings: blocking.length,
    counts_by_severity: counts,
    scope_notes: notes.length,
  };
}

export function generatePhase200JudgeFindings(options = {}) {
  const paths = buildPaths(options);
  const findings = [];
  let nextId = 1;

  for (const artifact of REQUIRED_ARTIFACTS) {
    const absPath = paths.inputs[artifact.key];
    const ref = evidenceRefFor(absPath, artifact.file);
    if (!fs.existsSync(absPath)) {
      findings.push(
        makeFinding({
          id: `P200-JUDGE-${String(nextId).padStart(3, "0")}`,
          lens: artifact.lens,
          severity: "BLOCKER",
          title: artifact.title,
          summary: `${artifact.file} is required before Phase 200 can record ACCEPT.`,
          lockedReference: artifact.lockedReference,
          supportingReferences: ["D-24", "D-25", "D-28"],
          affected: artifact.file,
          evidenceRefs: ref,
          repair: `Generate ${artifact.file}, rerun the relevant verifier, and regenerate judge.findings.json.`,
          source: "required-artifact",
        })
      );
      nextId += 1;
    }
  }

  const deltaRef = evidenceRefFor(paths.inputs.delta, "scorecard.delta.json");
  const delta = readStructuredInput(paths.inputs.delta, "scorecard.delta.json", deltaRef, findings, nextId, "correctness", "VER-01");
  nextId = delta.nextId;
  if (delta.ok) nextId = analyzeDelta(delta.data, deltaRef, findings, nextId);

  const regressionsRef = evidenceRefFor(paths.inputs.regressions, "regressions.ndjson");
  const regressions = readStructuredInput(
    paths.inputs.regressions,
    "regressions.ndjson",
    regressionsRef,
    findings,
    nextId,
    "correctness",
    "VER-01"
  );
  nextId = regressions.nextId;
  if (regressions.ok) nextId = analyzeRegressions(regressions.data, regressionsRef, findings, nextId);

  const finalCellsRef = evidenceRefFor(paths.inputs.finalCells, "final.cells.json");
  const finalCells = readStructuredInput(paths.inputs.finalCells, "final.cells.json", finalCellsRef, findings, nextId, "correctness", "VER-01");
  nextId = finalCells.nextId;
  if (finalCells.ok) nextId = analyzeFinalCells(finalCells.data, finalCellsRef, findings, nextId);

  const manifestRef = evidenceRefFor(paths.inputs.manifest, "artifacts.manifest.json");
  const manifest = readStructuredInput(paths.inputs.manifest, "artifacts.manifest.json", manifestRef, findings, nextId, "correctness", "VER-03");
  nextId = manifest.nextId;
  if (manifest.ok) nextId = analyzeManifest(manifest.data, manifestRef, findings, nextId);

  for (const input of OPTIONAL_STRUCTURED_INPUTS) {
    const absPath = paths.inputs[input.key];
    if (!fs.existsSync(absPath)) continue;
    const parsed = readStructuredInput(absPath, input.key, input.ref, findings, nextId, input.lens, input.lockedReference);
    nextId = parsed.nextId;
    if (!parsed.ok) continue;
    if (input.key === "storybookA11y") nextId = analyzeStorybookA11y(parsed.data, input.ref, findings, nextId);
    if (input.key === "pageFlowEvidence") nextId = analyzePageFlowEvidence(parsed.data, input.ref, findings, nextId);
    if (input.key === "hostLeakEvidence") nextId = analyzeHostLeakEvidence(parsed.data, input.ref, findings, nextId);
  }

  const extraFindings = (options.extraFindings || []).map((finding, index) => ({
    id: finding.id || `P200-JUDGE-EXTRA-${String(index + 1).padStart(2, "0")}`,
    status: BLOCKING_SEVERITIES.has(finding.severity) ? "open" : "recorded",
    supporting_references: [],
    evidence_refs: [],
    ...finding,
  }));

  const allFindings = [...findings, ...extraFindings];
  validateFindings(allFindings);

  const notes = scopeNotes();
  const result = {
    generated_at: new Date().toISOString(),
    phase: "200-idempotent-verification-sign-off",
    allowed_lenses: ALLOWED_LENSES,
    allowed_severities: ALLOWED_SEVERITIES,
    summary: summaryFor(allFindings, notes),
    findings: allFindings,
    scope_notes: notes,
  };

  if (options.write !== false && !options.dryRun) writeJson(paths.outputPath, result);
  return result;
}

function fixtureCell(overrides = {}) {
  return {
    cell_id: "p193__fixture-flow__chromium-desktop__light__default-populated__d11",
    baseline_score: 2,
    final_score: 2,
    coverage_change: "covered->covered",
    evidence_refs: ["accrue_admin/test-results/phase200/page-flow-evidence.json"],
    ...overrides,
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

function fixturePackage(root, overrides = {}) {
  fs.mkdirSync(root, { recursive: true });
  const files = {
    baselineUnion: path.join(root, "baseline.union.cells.json"),
    finalCells: path.join(root, "final.cells.json"),
    delta: path.join(root, "scorecard.delta.json"),
    regressions: path.join(root, "regressions.ndjson"),
    manifest: path.join(root, "artifacts.manifest.json"),
    scorecardMarkdown: path.join(root, "200-SCORECARD.md"),
    storybookCoverageMarkdown: path.join(root, "200-STORYBOOK-COVERAGE.md"),
    verificationMarkdown: path.join(root, "200-VERIFICATION.md"),
    storybookA11y: path.join(root, "storybook-a11y.json"),
    pageFlowEvidence: path.join(root, "page-flow-evidence.json"),
    hostLeakEvidence: path.join(root, "host-leak.json"),
  };

  const omit = new Set(overrides.omit || []);
  const writeIfIncluded = (key, body) => {
    if (omit.has(key)) return;
    fs.writeFileSync(files[key], body);
  };

  writeIfIncluded("baselineUnion", `${JSON.stringify([fixtureFinalCell()])}\n`);
  writeIfIncluded("finalCells", `${JSON.stringify(overrides.finalCells || [fixtureFinalCell()])}\n`);
  writeIfIncluded("delta", `${JSON.stringify(overrides.delta || [fixtureCell()])}\n`);
  writeIfIncluded("regressions", overrides.regressions || "");
  writeIfIncluded(
    "manifest",
    `${JSON.stringify(
      overrides.manifest || {
        command_statuses: {
          "phase200 host/adopter leak": { status: "passed", evidence_ref: "accrue_admin/test-results/phase200/host-leak.json" },
        },
        evidence: [{ path: "accrue_admin/test-results/phase200/page-flow-evidence.json" }],
      }
    )}\n`
  );
  writeIfIncluded("scorecardMarkdown", "# Phase 200 Scorecard\n\nStatus: pass\n");
  writeIfIncluded("storybookCoverageMarkdown", "# Phase 200 Storybook Coverage\n\nStatus: pass\n");
  writeIfIncluded("verificationMarkdown", "# Phase 200 Verification\n\nStatus: pass\n");
  writeIfIncluded(
    "storybookA11y",
    `${JSON.stringify(overrides.storybookA11y || { rows: [{ story_url: "/billing/dev/storybook/components/button", status: "passed", violations: [] }] })}\n`
  );
  writeIfIncluded(
    "pageFlowEvidence",
    `${JSON.stringify(overrides.pageFlowEvidence || { rows: [fixtureFinalCell()] })}\n`
  );
  writeIfIncluded("hostLeakEvidence", `${JSON.stringify(overrides.hostLeakEvidence || { rows: [] })}\n`);

  return files;
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  assertSelfTest("allowed lens enum is exactly bounded", ALLOWED_LENSES.join(",") === "correctness,accessibility,brand,interaction");
  assertSelfTest(
    "allowed severity enum is exactly bounded",
    ALLOWED_SEVERITIES.join(",") === "BLOCKER,REPAIR-IN-PHASE,ADVISORY,DEFERRED"
  );

  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-judge-"));
  try {
    const positiveInputs = fixturePackage(path.join(root, "positive"));
    const positive = generatePhase200JudgeFindings({
      phaseDir: path.join(root, "positive"),
      inputs: positiveInputs,
      dryRun: true,
      write: false,
    });
    assertSelfTest("positive fixture produces zero blocking findings", positive.summary.blocking_findings === 0);

    const missingInputs = fixturePackage(path.join(root, "missing"), { omit: ["finalCells"] });
    const missing = generatePhase200JudgeFindings({
      phaseDir: path.join(root, "missing"),
      inputs: missingInputs,
      dryRun: true,
      write: false,
    });
    assertSelfTest(
      "missing artifacts produce BLOCKER findings",
      missing.findings.some((finding) => finding.severity === "BLOCKER" && /final cell/i.test(finding.title))
    );

    const regressionInputs = fixturePackage(path.join(root, "regression"), {
      regressions: `${JSON.stringify({ id: "P200-REG-001", evidence_refs: ["accrue_admin/test-results/phase200/page-flow-evidence.json"] })}\n`,
    });
    const regression = generatePhase200JudgeFindings({
      phaseDir: path.join(root, "regression"),
      inputs: regressionInputs,
      dryRun: true,
      write: false,
    });
    assertSelfTest("non-empty regressions produce BLOCKER findings", regression.findings.some((finding) => /Regression ledger/i.test(finding.title)));

    const downgradeInputs = fixturePackage(path.join(root, "downgrade"), {
      delta: [fixtureCell({ coverage_change: "covered->gap" })],
    });
    const downgrade = generatePhase200JudgeFindings({
      phaseDir: path.join(root, "downgrade"),
      inputs: downgradeInputs,
      dryRun: true,
      write: false,
    });
    assertSelfTest("coverage downgrade produces BLOCKER findings", downgrade.findings.some((finding) => /Coverage downgrade/i.test(finding.title)));

    const hostLeakInputs = fixturePackage(path.join(root, "host-leak"), {
      hostLeakEvidence: { rows: [{ id: "host-leak-001", status: "failed", leak: true }] },
    });
    const hostLeak = generatePhase200JudgeFindings({
      phaseDir: path.join(root, "host-leak"),
      inputs: hostLeakInputs,
      dryRun: true,
      write: false,
    });
    assertSelfTest("host leak evidence produces BLOCKER findings", hostLeak.findings.some((finding) => /Host leak/i.test(finding.title)));

    let invalidLensFailed = false;
    try {
      generatePhase200JudgeFindings({
        phaseDir: path.join(root, "positive"),
        inputs: positiveInputs,
        dryRun: true,
        write: false,
        extraFindings: [{ lens: "visual", severity: "ADVISORY", title: "Bad lens", summary: "Nope." }],
      });
    } catch (error) {
      invalidLensFailed = /invalid lens/i.test(error.message);
    }
    assertSelfTest("invalid lens is rejected", invalidLensFailed);

    let missingRefFailed = false;
    try {
      generatePhase200JudgeFindings({
        phaseDir: path.join(root, "positive"),
        inputs: positiveInputs,
        dryRun: true,
        write: false,
        extraFindings: [{ lens: "correctness", severity: "BLOCKER", title: "No locked ref", summary: "Nope." }],
      });
    } catch (error) {
      missingRefFailed = /locked reference|evidence refs/i.test(error.message);
    }
    assertSelfTest("blocking findings without locked refs are rejected", missingRefFailed);

    assertSelfTest("reviewed todos are present as scope notes", positive.scope_notes.length === REVIEWED_SCOPE_NOTES.length);
    let todoBlockFailed = false;
    try {
      generatePhase200JudgeFindings({
        phaseDir: path.join(root, "positive"),
        inputs: positiveInputs,
        dryRun: true,
        write: false,
        extraFindings: [
          {
            lens: "brand",
            severity: "BLOCKER",
            title: "Todo tried to block",
            summary: "A reviewed todo cannot block without a direct Phase 200 requirement.",
            locked_reference: "brandbook/voice.md",
            affected: "accrue_admin/e2e/README.md",
            evidence_refs: ["accrue_admin/test-results/phase200/host-leak.json"],
            source_kind: "reviewed_todo",
          },
        ],
      });
    } catch (error) {
      todoBlockFailed = /reviewed todo cannot block/i.test(error.message);
    }
    assertSelfTest("reviewed todos cannot block without direct Phase 200 requirement reference", todoBlockFailed);

    console.log("Phase 200 judge generator self-test passed.");
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

  const result = generatePhase200JudgeFindings(options);
  console.log(
    `Phase 200 judge findings ${options.dryRun ? "dry-run" : "generated"}: findings=${result.summary.findings}, blocking=${
      result.summary.blocking_findings
    }, scope_notes=${result.summary.scope_notes}`
  );
  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 judge generator failed: ${error.message}`);
    process.exitCode = 1;
  }
}
