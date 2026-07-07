import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import { verifyFrozenRatchetLedger } from "./verify_ratchet_ledger.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
export const PHASE208_DIR = ".planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept";
export const DEFAULT_SIGNOFF_PATH = path.join(REPO_ROOT, PHASE208_DIR, "UI-RATCHET-SIGN-OFF.md");

export const VALID_STATUS_VALUES = new Set(["PASS", "BLOCKED", "PENDING", "N/A"]);

export const REQUIRED_SECTIONS = [
  "Executive Status",
  "Representative Slice Evidence",
  "Ledger Baseline Summary",
  "Regression Files",
  "CI Gate Evidence",
  "Persona Regression Proof",
  "Existing UI Gate Status",
  "Follow-On Runbook",
  "Maintainer Checkpoint",
];

export const REQUIRED_RUNBOOK_HEADINGS = [
  "Run The Representative Slice",
  "Read The Digest",
  "Apply Fixes And Mint Guards",
  "Freeze The Baseline",
  "Run Deterministic Guardrails",
  "Graduate Another Surface",
  "Recover From A Regression",
];

const ACCEPT_PREFIX = "Final maintainer decision: ACCEPT (maintainer approved ";
const ACCEPT_LINE_RE = /^Final maintainer decision: ACCEPT \(maintainer approved \d{4}-\d{2}-\d{2}\)\. Evidence source: .+$/;

const REQUIRED_ACCEPT_COPIES = [
  {
    key: "noKey",
    label: "no-key proof",
    copy: "PASS - ANTHROPIC_API_KEY is not required for this job",
    refs: [".github/workflows/ci.yml"],
  },
  {
    key: "guardrailsClean",
    label: "deterministic ratchet guardrails",
    copy: "PASS - deterministic ratchet guardrails are clean",
    refs: ["scripts/ci/verify_ratchet_ledger.mjs"],
  },
  {
    key: "zeroFoldedOpen",
    label: "zero folded open findings",
    copy: "PASS - folded confirmed_open findings are 0",
    refs: ["scripts/ci/verify_ratchet_ledger.mjs"],
    requiresFrozenCommand: true,
  },
  {
    key: "findingRegressions",
    label: "finding regression file",
    copy: "PASS - finding-regressions.ndjson is 0 bytes",
    refs: ["accrue_admin/e2e/ratchet/finding-regressions.ndjson"],
  },
  {
    key: "independentRecompute",
    label: "independent recompute",
    copy: "PASS - independent recompute matches ledger.baseline.json",
    refs: ["scripts/ci/verify_ratchet_ledger.mjs"],
  },
  {
    key: "syntheticCount",
    label: "synthetic count increase proof",
    copy: "PASS - synthetic count increase blocks the gate",
    refs: ["scripts/ci/verify_ratchet_ledger.mjs"],
  },
  {
    key: "personaRegression",
    label: "persona regression proof",
    copy: "PASS - regressed lens count increase blocks the gate",
    refs: ["scripts/ci/verify_ratchet_ledger.mjs"],
  },
  {
    key: "existingUiGates",
    label: "existing UI gates",
    copy: "PASS - admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift are green",
    refs: ["accrue_admin/test-results/"],
  },
  {
    key: "bundleFreshness",
    label: "bundle freshness",
    copy: "PASS - accrue_admin.css is fresh",
    refs: ["accrue_admin/test-results/"],
  },
];

function repoRelative(absPath) {
  return path.relative(REPO_ROOT, absPath).split(path.sep).join("/");
}

function stripMarkdown(value) {
  return String(value || "")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/[*_`]/g, "")
    .trim();
}

function normalize(value) {
  return stripMarkdown(value)
    .toLowerCase()
    .replace(/[_/]+/g, " ")
    .replace(/[^a-z0-9:. -]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function readFile(filePath, failures) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    failures.missingArtifacts.push(`Unable to read ${repoRelative(filePath) || filePath}: ${error.message}`);
    return "";
  }
}

function tableCells(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((cell) => stripMarkdown(cell));
}

function isSeparatorRow(line) {
  return /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$/.test(line);
}

function parseMarkdownTables(markdown) {
  const lines = markdown.split(/\r?\n/);
  const rows = [];

  for (let index = 0; index < lines.length - 2; index += 1) {
    if (!lines[index].includes("|") || !isSeparatorRow(lines[index + 1])) continue;
    const headers = tableCells(lines[index]);
    const statusIndex = headers.findIndex((header) => /^status$/i.test(header));
    const evidenceIndex = headers.findIndex((header) => /^evidence$/i.test(header) || /^source$/i.test(header));
    const checkIndex = headers.findIndex((header) => /^(check|item|gate|evidence|requirement)$/i.test(header));
    const detailIndex = headers.findIndex((header) => /^(details?|result|copy|summary)$/i.test(header));

    let rowIndex = index + 2;
    while (rowIndex < lines.length && lines[rowIndex].includes("|") && !isSeparatorRow(lines[rowIndex])) {
      const cells = tableCells(lines[rowIndex]);
      rows.push({
        raw: lines[rowIndex],
        source: lines[rowIndex],
        headers,
        cells,
        status: statusIndex >= 0 ? stripMarkdown(cells[statusIndex] || "") : "",
        evidence: evidenceIndex >= 0 ? cells[evidenceIndex] || "" : "",
        check: checkIndex >= 0 ? cells[checkIndex] || "" : "",
        detail: detailIndex >= 0 ? cells[detailIndex] || "" : "",
        line: rowIndex + 1,
      });
      rowIndex += 1;
    }
    index = rowIndex - 1;
  }

  return rows;
}

function headingRows(markdown) {
  return markdown
    .split(/\r?\n/)
    .map((line, index) => {
      const match = line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);
      return match ? { level: match[1].length, title: stripMarkdown(match[2]), line: index + 1 } : null;
    })
    .filter(Boolean);
}

function headingIndex(markdown, title) {
  const wanted = normalize(title);
  return headingRows(markdown).findIndex((heading) => normalize(heading.title) === wanted);
}

function rangeSource(markdown, startTitle, endTitle = null) {
  const lines = markdown.split(/\r?\n/);
  const headings = headingRows(markdown);
  const start = headings.find((heading) => normalize(heading.title) === normalize(startTitle));
  if (!start) return "";
  const end = endTitle
    ? headings.find((heading) => heading.line > start.line && normalize(heading.title) === normalize(endTitle))
    : headings.find((heading) => heading.line > start.line && heading.level <= start.level);
  return lines.slice(start.line - 1, end ? end.line - 1 : undefined).join("\n");
}

function cleanRef(ref) {
  return String(ref || "")
    .trim()
    .replace(/^[("<'`]+/, "")
    .replace(/[).,;:'"`\]]+$/, "");
}

export function evidenceRefs(source) {
  const refs = new Set();
  const text = String(source || "");
  const patterns = [
    /(?:^|[\s([`])((?:accrue_admin|scripts|\.github|\.planning)\/[^\s),\]|`]+|\/[A-Za-z0-9._/-]+|[A-Za-z0-9_.-]+\\[^\s),\]|`]+)/g,
  ];

  for (const pattern of patterns) {
    let match = pattern.exec(text);
    while (match) {
      refs.add(cleanRef(match[1]));
      match = pattern.exec(text);
    }
  }

  return Array.from(refs).filter(Boolean);
}

export function validEvidenceRef(ref) {
  const value = cleanRef(ref);
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return (
    value === ".github/workflows/ci.yml" ||
    value.startsWith("accrue_admin/e2e/ratchet/") ||
    value.startsWith("accrue_admin/test-results/") ||
    value.startsWith("scripts/ci/") ||
    value.startsWith(`${PHASE208_DIR}/`)
  );
}

function failureTemplate() {
  return {
    decision: [],
    structure: [],
    status: [],
    runbook: [],
    evidence: [],
    frozenEvidence: [],
    missingArtifacts: [],
  };
}

function failureCount(failures) {
  return Object.values(failures).reduce((sum, rows) => sum + rows.length, 0);
}

export function parseDecisionLine(markdown, failures = failureTemplate()) {
  const lines = markdown.split(/\r?\n/).filter((line) => line.startsWith("Final maintainer decision: "));
  if (lines.length !== 1) {
    failures.decision.push(`Expected exactly one final decision line, found ${lines.length}.`);
    return { decision: null, line: lines[0] || null };
  }

  const line = lines[0].trim();
  if (!line.startsWith(ACCEPT_PREFIX) || !ACCEPT_LINE_RE.test(line)) {
    failures.decision.push(`Final decision line must match: ${ACCEPT_PREFIX}{YYYY-MM-DD}). Evidence source: ...`);
    return { decision: null, line };
  }

  return { decision: "ACCEPT", line };
}

export function validateStructure(markdown, failures = failureTemplate()) {
  let previousIndex = -1;
  for (const section of REQUIRED_SECTIONS) {
    const index = headingIndex(markdown, section);
    if (index === -1) {
      failures.structure.push(`Missing required section: ${section}.`);
      continue;
    }
    if (index < previousIndex) failures.structure.push(`Required section is out of order: ${section}.`);
    previousIndex = Math.max(previousIndex, index);
  }
}

export function validateStatusValues(markdown, failures = failureTemplate()) {
  const rows = parseMarkdownTables(markdown);
  for (const row of rows) {
    if (!row.status) continue;
    const value = row.status.toUpperCase();
    if (!VALID_STATUS_VALUES.has(value)) {
      failures.status.push(`Invalid Status value on line ${row.line}: ${JSON.stringify(row.status)}.`);
    }
  }
}

export function validateEvidenceReferences(markdown, failures = failureTemplate()) {
  const refs = evidenceRefs(markdown);
  if (refs.length === 0) {
    failures.evidence.push("UI-RATCHET-SIGN-OFF.md must include concrete repo-relative evidence refs.");
    return refs;
  }

  for (const ref of refs) {
    if (!validEvidenceRef(ref)) failures.evidence.push(`Invalid evidence ref: ${ref}`);
  }

  return refs;
}

export function validateRunbook(markdown, failures = failureTemplate()) {
  for (const heading of REQUIRED_RUNBOOK_HEADINGS) {
    if (headingIndex(markdown, heading) === -1) failures.runbook.push(`Missing runbook heading: ${heading}.`);
  }

  const runbook = rangeSource(markdown, "Follow-On Runbook", "Maintainer Checkpoint");
  if (!/\bSLICES\.foundation\b/.test(runbook)) failures.runbook.push("Runbook must name SLICES.foundation as the proven slice.");
  if (!/\bbounded\b/i.test(runbook) || !/\bsurface\/slice\b/i.test(runbook)) {
    failures.runbook.push("Runbook must describe follow-on graduation as a bounded surface/slice run.");
  }

  const forbidden = [
    /\bphase\s+208\s+(must|will|shall)\s+(run|sweep|graduate)\s+(all|every|full|entire)\b/i,
    /\b(all|every|full|entire)\s+admin\s+surfaces?\b/i,
    /\bfull[- ]admin[- ]surface\s+sweep\b/i,
    /\bfull[- ]surface\s+sweep\b/i,
    /\bsweep\s+(all|every|the full|the entire)\b/i,
    /\bperform\s+SWEEP-01\b/i,
  ];
  for (const pattern of forbidden) {
    if (pattern.test(runbook)) {
      failures.runbook.push("Runbook must tee up bounded follow-on graduation, not mandate a full-admin sweep in Phase 208.");
      break;
    }
  }
}

function rowForCopy(rows, copy) {
  const wanted = normalize(copy);
  return rows.find((row) => normalize(row.raw).includes(wanted));
}

function rowForMarkers(rows, markers) {
  return rows.find((row) => {
    const source = normalize(row.raw);
    return markers.every((marker) => source.includes(normalize(marker)));
  });
}

function rowHasRef(row, expectedRefs) {
  const refs = evidenceRefs(row.raw);
  return expectedRefs.some((expected) => refs.some((ref) => ref === expected || ref.startsWith(expected)));
}

function validateRequiredCopy(markdown, rows, requirement, failures) {
  const source = normalize(markdown);
  if (!source.includes(normalize(requirement.copy))) {
    failures.evidence.push(`ACCEPT requires ${requirement.label} copy: ${requirement.copy}`);
    return;
  }

  const row = rowForCopy(rows, requirement.copy);
  if (!row) return;
  if (row.status && row.status.toUpperCase() !== "PASS") {
    failures.evidence.push(`${requirement.label} row must use Status PASS, found ${row.status}.`);
  }
  if (requirement.refs && !rowHasRef(row, requirement.refs)) {
    failures.evidence.push(`${requirement.label} row must reference ${requirement.refs.join(" or ")}.`);
  }
  if (requirement.requiresFrozenCommand && !/scripts\/ci\/verify_ratchet_ledger\.mjs\s+--verify-frozen/.test(row.raw)) {
    failures.evidence.push("Zero folded-open evidence must be backed by scripts/ci/verify_ratchet_ledger.mjs --verify-frozen output.");
  }
}

function flattenFrozenFailures(result) {
  const out = [];
  for (const [section, items] of Object.entries(result.failures || {})) {
    for (const item of items) out.push(`${section}: ${item}`);
  }
  return out;
}

export function validateAcceptEvidence(markdown, options = {}, failures = failureTemplate()) {
  const rows = parseMarkdownTables(markdown);
  for (const requirement of REQUIRED_ACCEPT_COPIES) validateRequiredCopy(markdown, rows, requirement, failures);

  const existingGates = rowForMarkers(rows, ["admin-hardening-guardrails", "admin-phase200-guardrails", "asset-drift"]);
  if (!existingGates) {
    failures.evidence.push("ACCEPT requires existing UI gate evidence naming admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift.");
  } else if (existingGates.status.toUpperCase() !== "PASS") {
    failures.evidence.push(`ACCEPT requires existing UI gate Status PASS, found ${existingGates.status || "missing"}.`);
  }

  const bundleFreshness = rowForMarkers(rows, ["accrue_admin.css", "fresh"]);
  if (!bundleFreshness) {
    failures.evidence.push("ACCEPT requires bundle freshness evidence for accrue_admin.css.");
  } else if (bundleFreshness.status.toUpperCase() !== "PASS") {
    failures.evidence.push(`ACCEPT requires bundle freshness Status PASS, found ${bundleFreshness.status || "missing"}.`);
  }

  const frozenResult = options.frozenResult || verifyFrozenRatchetLedger(options.ratchetPaths || {});
  if (!frozenResult.ok) {
    failures.frozenEvidence.push(
      "ACCEPT requires scripts/ci/verify_ratchet_ledger.mjs --verify-frozen to pass: " + flattenFrozenFailures(frozenResult).join("; ")
    );
  }
}

export function verifyUiRatchetSignoff(options = {}) {
  const signoffPath = path.resolve(options.signoffPath || DEFAULT_SIGNOFF_PATH);
  const phaseDir = path.resolve(options.phaseDir || path.dirname(signoffPath));
  const failures = failureTemplate();
  const markdown = options.markdown ?? readFile(signoffPath, failures);

  const decision = parseDecisionLine(markdown, failures);
  validateStructure(markdown, failures);
  validateStatusValues(markdown, failures);
  validateRunbook(markdown, failures);
  validateEvidenceReferences(markdown, failures);

  if (options.requireAccept && decision.decision !== "ACCEPT") {
    failures.decision.push("CI sign-off verification requires Final maintainer decision: ACCEPT.");
  }

  if (decision.decision === "ACCEPT") validateAcceptEvidence(markdown, { ...options, phaseDir }, failures);

  return {
    ok: failureCount(failures) === 0,
    decision: decision.decision,
    summary: {
      signoff_path: signoffPath,
      phase_dir: phaseDir,
      status_rows: parseMarkdownTables(markdown).filter((row) => row.status).length,
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

function writeNdjson(filePath, rows) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, rows.map((row) => JSON.stringify(row)).join("\n") + (rows.length ? "\n" : ""));
}

function sha256(filePath) {
  return createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function emptyConfirmedOpen() {
  return Object.fromEntries(
    [
      "persona:operator-founder",
      "persona:customer-support",
      "persona:finance-billing-ops",
      "persona:recovery-growth-ops",
      "persona:developer-integration",
      "persona:compliance-audit",
      "design",
    ].map((lens) => [lens, { total: 0, minor: 0, real: 0 }])
  );
}

function foundationScoreRows(score = 2) {
  return [
    { cell_id: "fixture-dashboard", surface: "dashboard", surface_type: "page-flow", coverage_status: "covered", score },
    { cell_id: "fixture-subscription-detail", surface: "subscription-detail", surface_type: "page-flow", coverage_status: "covered", score },
    { cell_id: "fixture-subscriptions", surface: "subscriptions", surface_type: "page-flow", coverage_status: "covered", score },
    { cell_id: "fixture-button", surface: "button", surface_type: "component", coverage_status: "covered", score },
    { cell_id: "fixture-group", surface: "page-header/actions/breadcrumbs", surface_type: "component-group", coverage_status: "covered", score },
  ];
}

function writeRatchetFixture(root, overrides = {}) {
  const ledgerPath = path.join(root, "accrue_admin/e2e/ratchet/findings.ledger.ndjson");
  const baselinePath = path.join(root, "accrue_admin/e2e/ratchet/ledger.baseline.json");
  const reopenMarkersPath = path.join(root, "accrue_admin/e2e/ratchet/reopen-markers.ndjson");
  const regressionsPath = path.join(root, "accrue_admin/e2e/ratchet/finding-regressions.ndjson");
  const roundsPath = path.join(root, "accrue_admin/e2e/ratchet/rounds.ndjson");
  const phase200RegressionsPath = path.join(root, ".planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/regressions.ndjson");
  const cellsCensusPath = path.join(root, ".planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/final.cells.json");

  const ledgerRows =
    overrides.ledgerRows ||
    [
      {
        finding_id: "f-8888888888888801",
        seq: 1,
        event: "verify-close",
        status: "verified-closed",
        raised_by_lenses: ["design"],
        severity: "real",
        claim_key: "dashboard__d02__kpi-row__ov-none",
        guard_ref: "ledger-count",
      },
    ];
  writeNdjson(ledgerPath, ledgerRows);
  writeText(reopenMarkersPath, "");
  writeText(regressionsPath, overrides.regressionsText || "");
  writeText(phase200RegressionsPath, overrides.phase200RegressionsText || "");
  const baseline = overrides.baseline || {
    schema_version: "ratchet-ledger-baseline/1",
    frozen: true,
    epoch: 1,
    ledger_sha256: sha256(ledgerPath),
    confirmed_open: emptyConfirmedOpen(),
    resolved_locked: ["dashboard__d02__kpi-row__ov-none"],
  };
  writeJson(baselinePath, baseline);
  writeNdjson(
    roundsPath,
    overrides.roundRows || [
      { schema_version: "ratchet-round-seal/1", round: 4, dry: true, epoch: baseline.epoch, scope: "foundation", bundle_sha256: "a".repeat(64), seq: 1 },
      { schema_version: "ratchet-round-seal/1", round: 5, dry: true, epoch: baseline.epoch, scope: "foundation", bundle_sha256: "b".repeat(64), seq: 2 },
    ]
  );
  writeJson(cellsCensusPath, overrides.cellsCensusRows || foundationScoreRows());

  return {
    ledgerPath,
    baselinePath,
    reopenMarkersPath,
    regressionsPath,
    roundsPath,
    phase200RegressionsPath,
    cellsCensusPath,
  };
}

function validSignoffMarkdown(overrides = {}) {
  const status = {
    noKey: "PASS",
    deterministic: "PASS",
    zeroOpen: "PASS",
    regressions: "PASS",
    recompute: "PASS",
    synthetic: "PASS",
    persona: "PASS",
    existingGates: "PASS",
    bundle: "PASS",
    ...overrides.status,
  };
  const phase = PHASE208_DIR;
  const broadLine =
    overrides.broadSweepLine ||
    "Use a bounded surface/slice run for each follow-on graduation; do not convert Phase 208 into the optional full sweep.";
  const finalLine =
    overrides.finalLine === undefined
      ? `Final maintainer decision: ACCEPT (maintainer approved 2026-07-07). Evidence source: accrue_admin/e2e/ratchet/ledger.baseline.json and ${phase}/UI-RATCHET-SIGN-OFF.md.`
      : overrides.finalLine;

  return `# Phase 208 UI Ratchet Sign-Off

## Executive Status

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| deterministic ratchet guardrails | ${status.deterministic} | PASS - deterministic ratchet guardrails are clean | scripts/ci/verify_ratchet_ledger.mjs |

## Representative Slice Evidence

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| proven slice | PASS | SLICES.foundation reached CONVERGED (2 dry rounds). | accrue_admin/e2e/ratchet/rounds.ndjson |
| score floor | PASS | All foundation score-floor rows are covered at score >= 2. | .planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-VALIDATION.md |

## Ledger Baseline Summary

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| frozen baseline | PASS | ledger.baseline.json is frozen and materially non-empty. | accrue_admin/e2e/ratchet/ledger.baseline.json |
| zero folded open findings | ${status.zeroOpen} | PASS - folded confirmed_open findings are 0 from scripts/ci/verify_ratchet_ledger.mjs --verify-frozen. | scripts/ci/verify_ratchet_ledger.mjs |

## Regression Files

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| ratchet finding regressions | ${status.regressions} | PASS - finding-regressions.ndjson is 0 bytes | accrue_admin/e2e/ratchet/finding-regressions.ndjson |
| Phase 200 regressions | PASS | regressions.ndjson is 0 bytes. | .planning/phases/208-prove-convergence-on-the-representative-slice-wire-ci-accept/208-VALIDATION.md |

## CI Gate Evidence

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| no LLM key | ${status.noKey} | PASS - ANTHROPIC_API_KEY is not required for this job | .github/workflows/ci.yml |
| independent verifier | ${status.recompute} | PASS - independent recompute matches ledger.baseline.json | scripts/ci/verify_ratchet_ledger.mjs |
| synthetic count increase | ${status.synthetic} | PASS - synthetic count increase blocks the gate | scripts/ci/verify_ratchet_ledger.mjs |

## Persona Regression Proof

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| cross-persona regression | ${status.persona} | PASS - regressed lens count increase blocks the gate | scripts/ci/verify_ratchet_ledger.mjs |

## Existing UI Gate Status

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift | ${status.existingGates} | PASS - admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift are green | accrue_admin/test-results/phase208/existing-ui-gates.log |
| accrue_admin.css bundle | ${status.bundle} | PASS - accrue_admin.css is fresh | accrue_admin/test-results/phase208/bundle-freshness.log |

## Follow-On Runbook

The proven slice is SLICES.foundation. ${broadLine}

## Run The Representative Slice

Run \`mix accrue_admin.ui.round --slice foundation\` until the digest reports \`CONVERGED (2 dry rounds)\`.

## Read The Digest

Read \`accrue_admin/e2e/ratchet/rounds.ndjson\` and the generated digest before changing decisions.

## Apply Fixes And Mint Guards

Apply fixes through \`mix accrue_admin.ui.fix\` and preserve ratchet guard refs.

## Freeze The Baseline

Run \`cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --freeze\` only after deterministic evidence is green.

## Run Deterministic Guardrails

Run \`node scripts/ci/verify_ratchet_ledger.mjs --verify-frozen\` and \`node scripts/ci/verify_ui_ratchet_signoff.mjs --require-accept\`.

## Graduate Another Surface

Pick one bounded surface/slice, run the same round/fix/freeze checks, and commit the evidence before widening scope.

## Recover From A Regression

If \`finding-regressions.ndjson\` is not empty, repair the named regression and rerun the deterministic guardrails.

## Maintainer Checkpoint

| Check | Status | Result | Evidence |
| --- | --- | --- | --- |
| final ACCEPT line | PASS | This artifact carries one final decision line. | ${phase}/UI-RATCHET-SIGN-OFF.md |

${finalLine}
`;
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function verifyFixture(root, markdown, ratchetOverrides = {}, options = {}) {
  const ratchetPaths = writeRatchetFixture(root, ratchetOverrides);
  return verifyUiRatchetSignoff({
    markdown,
    signoffPath: path.join(root, PHASE208_DIR, "UI-RATCHET-SIGN-OFF.md"),
    ratchetPaths,
    requireAccept: options.requireAccept ?? true,
  });
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "ui-ratchet-signoff-verifier-"));
  try {
    {
      const result = verifyFixture(path.join(root, "valid"), validSignoffMarkdown());
      assertSelfTest("valid ACCEPT fixture passes", result.ok, JSON.stringify(result.failures));
    }

    {
      const result = verifyFixture(path.join(root, "missing-final"), validSignoffMarkdown({ finalLine: "" }));
      assertSelfTest("missing final decision line fails", !result.ok);
      assertSelfTest("missing final line reports decision failure", result.failures.decision.length > 0);
    }

    {
      const markdown = `${validSignoffMarkdown()}\nFinal maintainer decision: ACCEPT (maintainer approved 2026-07-07). Evidence source: duplicate.\n`;
      const result = verifyFixture(path.join(root, "duplicate-final"), markdown);
      assertSelfTest("duplicate final decision lines fail", !result.ok);
    }

    {
      const result = verifyFixture(path.join(root, "invalid-status"), validSignoffMarkdown({ status: { noKey: "GREEN" } }));
      assertSelfTest("invalid status token fails", !result.ok);
      assertSelfTest("invalid status reports status failure", result.failures.status.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace(/^## CI Gate Evidence\n[\s\S]*?\n## Persona Regression Proof/m, "## Persona Regression Proof");
      const result = verifyFixture(path.join(root, "missing-section"), markdown);
      assertSelfTest("missing required section fails", !result.ok);
      assertSelfTest("missing section reports structure failure", result.failures.structure.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace(/^## Recover From A Regression\n[\s\S]*?\n## Maintainer Checkpoint/m, "## Maintainer Checkpoint");
      const result = verifyFixture(path.join(root, "missing-runbook-heading"), markdown);
      assertSelfTest("missing runbook heading fails", !result.ok);
      assertSelfTest("missing runbook heading reports runbook failure", result.failures.runbook.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace("PASS - folded confirmed_open findings are 0", "folded confirmed_open findings are clean");
      const result = verifyFixture(path.join(root, "missing-zero-open-copy"), markdown);
      assertSelfTest("missing zero folded open evidence fails", !result.ok);
      assertSelfTest("missing zero folded open evidence reports evidence failure", result.failures.evidence.length > 0);
    }

    {
      const baseline = {
        schema_version: "ratchet-ledger-baseline/1",
        frozen: true,
        epoch: 1,
        ledger_sha256: "will-be-overwritten-by-mismatch",
        confirmed_open: { ...emptyConfirmedOpen(), design: { total: 1, minor: 0, real: 1 } },
        resolved_locked: ["dashboard__d02__kpi-row__ov-none"],
      };
      const result = verifyFixture(path.join(root, "nonzero-open"), validSignoffMarkdown(), { baseline });
      assertSelfTest("nonzero folded-open evidence fails", !result.ok);
      assertSelfTest("nonzero folded-open evidence reports frozen evidence failure", result.failures.frozenEvidence.length > 0);
    }

    {
      const result = verifyFixture(path.join(root, "nonempty-regression"), validSignoffMarkdown(), {
        regressionsText: `${JSON.stringify({ kind: "count-increase", lens: "design" })}\n`,
      });
      assertSelfTest("non-empty regression file evidence fails", !result.ok);
      assertSelfTest("non-empty regression file reports frozen evidence failure", result.failures.frozenEvidence.length > 0);
    }

    {
      const baseline = {
        schema_version: "ratchet-ledger-baseline/1",
        frozen: false,
        epoch: 1,
        ledger_sha256: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        confirmed_open: emptyConfirmedOpen(),
        resolved_locked: [],
      };
      const result = verifyFixture(path.join(root, "placeholder-baseline"), validSignoffMarkdown(), { ledgerRows: [], baseline });
      assertSelfTest("unfrozen/all-zero empty-file baseline evidence fails", !result.ok);
      assertSelfTest("unfrozen/all-zero baseline reports frozen evidence failure", result.failures.frozenEvidence.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace("PASS - synthetic count increase blocks the gate", "synthetic count increase was checked");
      const result = verifyFixture(path.join(root, "missing-synthetic"), markdown);
      assertSelfTest("missing synthetic failure proof row fails", !result.ok);
      assertSelfTest("missing synthetic proof reports evidence failure", result.failures.evidence.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace(
        "| admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift | PASS | PASS - admin-hardening-guardrails, admin-phase200-guardrails, and asset-drift are green | accrue_admin/test-results/phase208/existing-ui-gates.log |",
        ""
      );
      const result = verifyFixture(path.join(root, "missing-existing-gates"), markdown);
      assertSelfTest("missing existing UI gate evidence fails", !result.ok);
      assertSelfTest("missing existing UI gate evidence reports evidence failure", result.failures.evidence.length > 0);
    }

    {
      const result = verifyFixture(path.join(root, "pending-existing-gates"), validSignoffMarkdown({ status: { existingGates: "PENDING" } }));
      assertSelfTest("existing UI gate row marked PENDING under ACCEPT fails", !result.ok);
      assertSelfTest("pending existing gate reports evidence failure", result.failures.evidence.length > 0);
    }

    {
      const markdown = validSignoffMarkdown().replace("scripts/ci/verify_ratchet_ledger.mjs", "/tmp/verify_ratchet_ledger.mjs");
      const result = verifyFixture(path.join(root, "invalid-ref"), markdown);
      assertSelfTest("invalid artifact refs fail", !result.ok);
      assertSelfTest("invalid artifact refs report evidence failure", result.failures.evidence.length > 0);
      assertSelfTest("absolute evidence ref is rejected", !validEvidenceRef("/tmp/verify_ratchet_ledger.mjs"));
      assertSelfTest("backslash evidence ref is rejected", !validEvidenceRef("scripts\\ci\\verify_ratchet_ledger.mjs"));
      assertSelfTest("parent traversal evidence ref is rejected", !validEvidenceRef(`${PHASE208_DIR}/../208-VALIDATION.md`));
      assertSelfTest("outside-root evidence ref is rejected", !validEvidenceRef("accrue_admin/priv/static/accrue_admin.css"));
    }

    {
      const result = verifyFixture(
        path.join(root, "broad-sweep"),
        validSignoffMarkdown({ broadSweepLine: "Phase 208 will sweep all admin surfaces before release." })
      );
      assertSelfTest("broad sweep mandate language fails", !result.ok);
      assertSelfTest("broad sweep language reports runbook failure", result.failures.runbook.length > 0);
    }

    {
      const missingPath = path.join(root, "missing", PHASE208_DIR, "UI-RATCHET-SIGN-OFF.md");
      const result = verifyUiRatchetSignoff({ signoffPath: missingPath, requireAccept: true, ratchetPaths: writeRatchetFixture(path.join(root, "missing-fixture")) });
      assertSelfTest("--require-accept with no sign-off file fails", !result.ok);
      assertSelfTest("missing sign-off path is reported", result.failures.missingArtifacts.some((failure) => failure.includes("UI-RATCHET-SIGN-OFF.md")));
    }

    console.log("UI ratchet sign-off verifier self-test passed.");
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

  const result = verifyUiRatchetSignoff(options);
  console.log(
    `UI ratchet sign-off verifier: decision=${result.decision || "invalid"}, status_rows=${result.summary.status_rows}, evidence_refs=${result.summary.evidence_refs}, failures=${result.summary.failures}`
  );

  if (!result.ok) {
    reportFailures("UI ratchet sign-off verification failed.", result.failures);
    process.exitCode = 1;
  } else {
    console.log("UI ratchet sign-off verification passed.");
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`UI ratchet sign-off verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
