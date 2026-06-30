import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");

const PHASE187_ARCHIVE_DIR = ".planning/milestones/v1.53-phases/187-audit-baseline";
const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE200_DIR);
const EXPECTED_UNION_COUNT = 30348;

const DEFAULT_INPUTS = {
  componentBaselinePath: path.join(repoRoot, PHASE187_ARCHIVE_DIR, "baseline.cells.json"),
  pageFlowBaselinePath: path.join(repoRoot, PHASE187_ARCHIVE_DIR, "baseline.page-flow.cells.json"),
  evidenceRoot: path.join(phaseDir, "evidence"),
};

const OUTPUTS = {
  baselineUnion: path.join(phaseDir, "baseline.union.cells.json"),
  finalCells: path.join(phaseDir, "final.cells.json"),
  delta: path.join(phaseDir, "scorecard.delta.json"),
  regressions: path.join(phaseDir, "regressions.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  markdown: path.join(phaseDir, "200-SCORECARD.md"),
};

const DIMENSIONS = new Map([
  [1, "token-compliance"],
  [2, "visual-hierarchy"],
  [3, "spacing-rhythm"],
  [4, "state-coverage"],
  [5, "responsive-mobile-first"],
  [6, "contrast"],
  [7, "focus-semantics"],
  [8, "brand-expression"],
  [9, "motion"],
  [10, "reuse-dry"],
  [11, "interaction-integrity"],
  [12, "microcopy"],
]);

const COVERAGE_RANK = new Map([
  ["pending", -1],
  ["missing", -1],
  ["unreachable", -1],
  ["gap", 0],
  ["n/a", 1],
  ["covered", 2],
]);

const STATE_TAXONOMY = new Set([
  "default-populated",
  "empty",
  "loading",
  "error",
  "permission-denied",
  "disconnected-reconnecting",
  "overflow",
  "long-content",
  "disabled-readonly",
  "interactive-open",
]);

const ALLOWED_LENSES = new Set([
  "correctness",
  "browser-behavior",
  "axe",
  "wcag",
  "reduced-motion",
  "component-lab",
  "component-group",
  "page-flow",
  "interaction-trace",
  "visual-brand-microcopy",
  "maintainer-review",
  "ci-guardrail",
]);

const GENERATED_ROOTS = [
  "accrue_admin/test-results/",
  "accrue_admin/playwright-report/",
  `${PHASE200_DIR}/`,
];

const ARCHIVE_OUTPUT_MARKERS = [
  ".planning/milestones/",
  ".planning/phases/187-audit-baseline/",
  ".planning/phases/192-idempotent-verification-sign-off/",
];

function relativeFromRepo(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function isAllowedArtifactRef(ref) {
  const value = String(ref || "");
  if (value.startsWith("playwright-trace:")) return true;
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return GENERATED_ROOTS.some((root) => value.startsWith(root));
}

function normalizeArtifactRef(value, baseDir = repoRoot) {
  if (!value) return null;
  const raw = String(value).split(path.sep).join("/");
  if (raw.startsWith("playwright-trace:")) return raw;
  if (raw.startsWith("test-results/")) return `accrue_admin/${raw}`;
  if (path.isAbsolute(raw)) return relativeFromRepo(raw);
  if (GENERATED_ROOTS.some((root) => raw.startsWith(root))) return raw;

  const resolved = path.resolve(baseDir, raw);
  return relativeFromRepo(resolved);
}

function allowedEvidenceRefs(row, sourceRef, sourceDir = repoRoot) {
  const refs = [
    ...(Array.isArray(row?.evidence_refs) ? row.evidence_refs : []),
    ...(Array.isArray(row?.evidenceRefs) ? row.evidenceRefs : []),
    row?.evidence_ref,
    row?.evidenceRef,
    sourceRef,
  ];

  return Array.from(
    new Set(
      refs
        .map((ref) => normalizeArtifactRef(ref, sourceDir))
        .filter((ref) => ref && isAllowedArtifactRef(ref))
    )
  );
}

function rowLenses(row, sourceRef = "") {
  const explicit = [
    ...(Array.isArray(row?.evidence_lenses) ? row.evidence_lenses : []),
    ...(Array.isArray(row?.validation_lenses) ? row.validation_lenses : []),
    ...(Array.isArray(row?.lenses) ? row.lenses : []),
    ...(Array.isArray(row?.lens_results) ? row.lens_results.map((lens) => lens.lens || lens.name) : []),
    row?.lens,
    row?.validation_lens,
  ]
    .filter(Boolean)
    .map((lens) => String(lens).trim().toLowerCase().replace(/_/g, "-"));

  if (explicit.length > 0) return Array.from(new Set(explicit));

  const source = `${sourceRef} ${row?.source || ""} ${row?.kind || ""}`.toLowerCase();
  if (source.includes("axe") || source.includes("wcag")) return ["axe"];
  if (source.includes("reduced-motion")) return ["reduced-motion"];
  if (source.includes("page-flow")) return ["page-flow", "interaction-trace"];
  if (source.includes("interaction") || source.includes("trace")) return ["interaction-trace"];
  if (source.includes("storybook")) return ["component-lab", "axe"];
  if (source.includes("component")) return ["component-lab"];
  return ["correctness"];
}

function scoreValue(value) {
  if (value === null || value === undefined) return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number < 0 || number > 3) {
    throw new Error(`Invalid score "${value}"; expected 0, 1, 2, 3, or null.`);
  }
  return number;
}

function normalizeCoverage(value) {
  const coverage = String(value || "covered");
  if (COVERAGE_RANK.has(coverage)) return coverage;
  return "covered";
}

function idDimension(cellId) {
  const match = String(cellId || "").match(/__d([0-9]{2})(?:__|$)/);
  return match ? Number(match[1]) : null;
}

function validUnionCellId(cellId) {
  return /^p(187|193)__.+__d(0[1-9]|1[0-2])(?:__.+)?$/.test(String(cellId || ""));
}

function readFile(absPath) {
  try {
    return fs.readFileSync(absPath, "utf8");
  } catch (error) {
    throw new Error(`Unable to read ${absPath}: ${error.message}`);
  }
}

function readJson(absPath) {
  try {
    return JSON.parse(readFile(absPath));
  } catch (error) {
    throw new Error(`Unable to parse JSON at ${absPath}: ${error.message}`);
  }
}

function readNdjson(absPath) {
  return readFile(absPath)
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`Unable to parse NDJSON at ${absPath}:${index + 1}: ${error.message}`);
      }
    });
}

function readRows(absPath) {
  if (absPath.endsWith(".ndjson") || absPath.endsWith(".jsonl")) return readNdjson(absPath);
  if (!absPath.endsWith(".json")) return [];
  const parsed = readJson(absPath);
  if (Array.isArray(parsed)) return parsed;
  if (Array.isArray(parsed.cells)) return parsed.cells;
  if (Array.isArray(parsed.rows)) return parsed.rows;
  if (Array.isArray(parsed.findings)) return parsed.findings;
  if (Array.isArray(parsed.evidence)) return parsed.evidence;
  if (parsed && typeof parsed === "object") return [parsed];
  return [];
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}

function sha256(absPath) {
  return createHash("sha256").update(fs.readFileSync(absPath)).digest("hex");
}

function listFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const absPath = path.join(dir, entry.name);
    return entry.isDirectory() ? listFiles(absPath) : [absPath];
  });
}

function assertArrayRows(rows, label) {
  if (!Array.isArray(rows)) throw new Error(`${label} must be an array.`);
}

function assertOutputPathsSafe(outputPaths) {
  for (const [name, absPath] of Object.entries(outputPaths)) {
    const repoRelative = relativeFromRepo(path.resolve(absPath));
    if (ARCHIVE_OUTPUT_MARKERS.some((marker) => repoRelative.startsWith(marker))) {
      throw new Error(`${name} output path points into an archived or prior-phase directory: ${repoRelative}`);
    }
  }
}

function buildUnionBaseline(componentRows, pageFlowRows, expectedCount = EXPECTED_UNION_COUNT) {
  assertArrayRows(componentRows, "baseline.cells.json");
  assertArrayRows(pageFlowRows, "baseline.page-flow.cells.json");

  const rows = [...componentRows, ...pageFlowRows].map((cell) => ({ ...cell }));
  const ids = new Map();
  const duplicates = [];

  for (const cell of rows) {
    if (!cell || typeof cell !== "object") throw new Error("Union baseline contains a non-object row.");
    if (!cell.cell_id) throw new Error("Union baseline contains a row without cell_id.");
    if (ids.has(cell.cell_id)) duplicates.push(cell.cell_id);
    ids.set(cell.cell_id, true);
  }

  if (duplicates.length > 0) {
    const proof = duplicates.map((cell_id) => ({ cell_id, duplicate_count: rows.filter((row) => row.cell_id === cell_id).length }));
    throw new Error(`Duplicate union cell IDs require structured duplicate proof: ${JSON.stringify(proof)}`);
  }

  if (expectedCount !== null && rows.length !== expectedCount) {
    throw new Error(`Union baseline expected ${expectedCount} rows, found ${rows.length}.`);
  }

  return rows;
}

function validateCellContract(cell, label) {
  const dimension = Number(cell.dimension);
  if (!DIMENSIONS.has(dimension) || cell.dimension_name !== DIMENSIONS.get(dimension)) {
    throw new Error(`${label}: ${cell.cell_id || "(missing cell_id)"} has invalid dimension mapping.`);
  }
  if (!validUnionCellId(cell.cell_id)) {
    throw new Error(`${label}: ${cell.cell_id || "(missing cell_id)"} violates p187/p193 cell grammar.`);
  }
  if (idDimension(cell.cell_id) !== dimension) {
    throw new Error(`${label}: ${cell.cell_id} changes the dimension suffix.`);
  }
  if (!COVERAGE_RANK.has(String(cell.coverage_status || ""))) {
    throw new Error(`${label}: ${cell.cell_id} has invalid coverage_status.`);
  }
  scoreValue(cell.score);
  if (!Array.isArray(cell.evidence_refs)) {
    throw new Error(`${label}: ${cell.cell_id} evidence_refs must be an array.`);
  }
}

function contractedCell(row, sourceRef = null, sourceDir = repoRoot) {
  const cellId = row.cell_id || row.final_cell_id;
  const dimension = Number(row.dimension ?? row.rubric_dimension);
  const dimensionName = row.dimension_name || DIMENSIONS.get(dimension);

  const cell = {
    cell_id: cellId,
    surface: row.surface || "unknown",
    surface_type: row.surface_type || (String(cellId || "").startsWith("p193__") ? "page-flow" : "component"),
    route: row.route || undefined,
    mode: row.mode || row.project || "chromium-desktop",
    viewport_width: Number(row.viewport_width ?? 1440),
    theme: row.theme || "light",
    state: STATE_TAXONOMY.has(row.state) ? row.state : "default-populated",
    dimension,
    dimension_name: dimensionName,
    score: scoreValue(row.score ?? row.final_score),
    coverage_status: normalizeCoverage(row.coverage_status),
    evidence_refs: allowedEvidenceRefs(row, sourceRef, sourceDir),
    evidence_lenses: rowLenses(row, sourceRef).filter((lens) => ALLOWED_LENSES.has(lens)),
    lens_results: Array.isArray(row.lens_results) ? row.lens_results : [],
    notes: row.notes || row.reason || row.defect || row.actual || "Normalized Phase 200 evidence row.",
    targeted_label: row.targeted_label ?? null,
    breakpoint: row.breakpoint ?? null,
    source_status: row.source_status ?? null,
    source_notes: row.source_notes ?? null,
  };

  validateCellContract(cell, "evidence");
  return cell;
}

function mergeCell(previous, next) {
  if (!previous) return next;
  const previousScore = previous.score ?? -1;
  const nextScore = next.score ?? -1;
  const winner = nextScore >= previousScore ? next : previous;
  return {
    ...winner,
    evidence_refs: Array.from(new Set([...(previous.evidence_refs || []), ...(next.evidence_refs || [])])),
    evidence_lenses: Array.from(new Set([...(previous.evidence_lenses || []), ...(next.evidence_lenses || [])])),
    lens_results: [...(previous.lens_results || []), ...(next.lens_results || [])],
    notes: [previous.notes, next.notes].filter(Boolean).join("\n"),
  };
}

function discoverLensFiles(evidenceRoot, explicitInputs = []) {
  const roots = [evidenceRoot, ...explicitInputs].filter(Boolean);
  const files = [];
  for (const entry of roots) {
    const absPath = path.resolve(entry);
    if (!fs.existsSync(absPath)) continue;
    if (fs.statSync(absPath).isDirectory()) {
      files.push(...listFiles(absPath).filter((file) => /\.(json|ndjson|jsonl)$/i.test(file)));
    } else if (/\.(json|ndjson|jsonl)$/i.test(absPath)) {
      files.push(absPath);
    }
  }
  return Array.from(new Set(files)).sort();
}

function discoverArtifactFiles(evidenceRoot, explicitInputs = []) {
  const roots = [evidenceRoot, ...explicitInputs].filter(Boolean);
  const files = [];
  for (const entry of roots) {
    const absPath = path.resolve(entry);
    if (!fs.existsSync(absPath)) continue;
    if (fs.statSync(absPath).isDirectory()) {
      files.push(...listFiles(absPath).filter((file) => /\.(json|ndjson|jsonl|png|zip|html)$/i.test(file)));
    } else if (/\.(json|ndjson|jsonl|png|zip|html)$/i.test(absPath)) {
      files.push(absPath);
    }
  }
  return Array.from(new Set(files)).sort();
}

function regressionRow(kind, baseline, finalCell, message) {
  return {
    id: `P200-${kind.toUpperCase()}-${String(baseline?.cell_id || finalCell?.cell_id || "unknown")
      .replace(/[^a-zA-Z0-9]+/g, "-")
      .slice(0, 80)}`,
    kind,
    cell_id: finalCell?.cell_id || baseline?.cell_id || null,
    surface: finalCell?.surface || baseline?.surface || null,
    surface_type: finalCell?.surface_type || baseline?.surface_type || null,
    state: finalCell?.state || baseline?.state || null,
    dimension: finalCell?.dimension || baseline?.dimension || null,
    dimension_name: finalCell?.dimension_name || baseline?.dimension_name || null,
    baseline_score: baseline?.score ?? null,
    final_score: finalCell?.score ?? null,
    baseline_coverage_status: baseline?.coverage_status ?? null,
    final_coverage_status: finalCell?.coverage_status ?? null,
    evidence_refs: Array.from(new Set([...(finalCell?.evidence_refs || []), ...(baseline?.evidence_refs || [])])),
    evidence_lenses: finalCell?.evidence_lenses || [],
    message,
    required_repair: "Repair the evidence, harness normalization, or true admin UI regression before Phase 200 sign-off.",
  };
}

function normalizeEvidence(files, unionBaselineById) {
  const cellsById = new Map();
  const corrections = [];
  const failures = [];

  for (const file of files) {
    const sourceRef = normalizeArtifactRef(file);
    let rows;
    try {
      rows = readRows(file);
    } catch (error) {
      failures.push({
        kind: "new-regression",
        cell_id: null,
        evidence_refs: allowedEvidenceRefs({}, sourceRef, path.dirname(file)),
        evidence_lenses: ["correctness"],
        message: error.message,
      });
      continue;
    }

    for (const row of rows) {
      if (!row || typeof row !== "object") continue;
      if (row.baseline_correction || String(row.kind || "").includes("baseline-correction")) {
        corrections.push({ ...row, evidence_refs: allowedEvidenceRefs(row, sourceRef, path.dirname(file)) });
        continue;
      }
      if (!row.cell_id && !row.final_cell_id) continue;

      try {
        const cell = contractedCell(row, sourceRef, path.dirname(file));
        if (!unionBaselineById.has(cell.cell_id)) {
          failures.push(
            regressionRow(
              "baseline-correction-required",
              null,
              cell,
              "Evidence row uses a cell ID outside the Phase 200 union baseline."
            )
          );
        }
        cellsById.set(cell.cell_id, mergeCell(cellsById.get(cell.cell_id), cell));
      } catch (error) {
        failures.push({
          kind: "new-regression",
          cell_id: row.cell_id || row.final_cell_id || null,
          evidence_refs: allowedEvidenceRefs(row, sourceRef, path.dirname(file)),
          evidence_lenses: rowLenses(row, sourceRef),
          message: error.message,
        });
      }
    }
  }

  return { cellsById, corrections, failures };
}

function fallbackCellFromBaseline(cell) {
  return {
    ...cell,
    evidence_refs: allowedEvidenceRefs(cell, null),
    evidence_lenses: Array.isArray(cell.evidence_lenses) && cell.evidence_lenses.length > 0 ? cell.evidence_lenses : ["correctness"],
    lens_results: Array.isArray(cell.lens_results)
      ? cell.lens_results
      : [
          {
            lens: "correctness",
            status: "read-only-union-baseline",
            evidence_refs: cell.evidence_refs || [],
          },
        ],
    notes: `${cell.notes || ""} Phase 200 fallback preserved archived union-baseline row until stronger evidence is supplied.`,
  };
}

function finalCellsFromUnion(unionRows, evidenceById) {
  return unionRows.map((baseline) => evidenceById.get(baseline.cell_id) || fallbackCellFromBaseline(baseline));
}

function compareCells(unionRows, finalRows, deltaRows) {
  const baselineById = new Map(unionRows.map((cell) => [cell.cell_id, cell]));
  const finalById = new Map();
  const regressions = [];

  for (const baseline of unionRows) {
    try {
      validateCellContract(baseline, "baseline.union.cells.json");
    } catch (error) {
      regressions.push(regressionRow("malformed-baseline", baseline, null, error.message));
    }
  }

  for (const finalCell of finalRows) {
    const baseline = baselineById.get(finalCell.cell_id);
    finalById.set(finalCell.cell_id, finalCell);

    try {
      validateCellContract(finalCell, "final.cells.json");
    } catch (error) {
      regressions.push(regressionRow("malformed-final", baseline, finalCell, error.message));
      continue;
    }

    if (!baseline) {
      regressions.push(
        regressionRow("baseline-correction-required", null, finalCell, "Final cell is not present in the union baseline.")
      );
      continue;
    }

    if (finalCell.evidence_refs.length === 0) {
      regressions.push(regressionRow("missing-evidence", baseline, finalCell, "Comparable final cell has no evidence refs."));
    }

    const baselineScore = scoreValue(baseline.score);
    const finalScore = scoreValue(finalCell.score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) {
      regressions.push(
        regressionRow("score-downgrade", baseline, finalCell, `Final score ${finalScore} is below union baseline score ${baselineScore}.`)
      );
    }

    const baselineCoverage = String(baseline.coverage_status || "");
    const finalCoverage = String(finalCell.coverage_status || "");
    if ((COVERAGE_RANK.get(finalCoverage) ?? -99) < (COVERAGE_RANK.get(baselineCoverage) ?? -99)) {
      regressions.push(
        regressionRow("coverage-downgrade", baseline, finalCell, `Coverage downgraded from ${baselineCoverage} to ${finalCoverage}.`)
      );
    }

    if (String(baseline.cell_id).startsWith("p193__")) {
      if (finalCoverage !== "covered") {
        regressions.push(
          regressionRow("p193-pending-closure", baseline, finalCell, "p193 page-flow baseline row must close as covered.")
        );
      }
      if (finalScore === null || finalScore < 2) {
        regressions.push(
          regressionRow("p193-score-floor", baseline, finalCell, "p193 page-flow baseline row must close with score >= 2.")
        );
      }
      if (finalCell.evidence_refs.length === 0) {
        regressions.push(
          regressionRow("p193-missing-evidence", baseline, finalCell, "p193 page-flow baseline row must close with deterministic evidence refs.")
        );
      }
    }
  }

  for (const baseline of unionRows) {
    if (!finalById.has(baseline.cell_id)) {
      regressions.push(regressionRow("missing-comparable-cell", baseline, null, "Union baseline row missing from final.cells.json."));
    }
  }

  const comparisonDelta = unionRows.map((baseline) => {
    const finalCell = finalById.get(baseline.cell_id);
    return {
      cell_id: baseline.cell_id,
      surface: baseline.surface,
      surface_type: baseline.surface_type,
      baseline_score: baseline.score ?? null,
      final_score: finalCell?.score ?? null,
      baseline_coverage_status: baseline.coverage_status ?? null,
      final_coverage_status: finalCell?.coverage_status ?? null,
      score_delta:
        baseline.score === null || baseline.score === undefined || finalCell?.score === null || finalCell?.score === undefined
          ? null
          : Number(finalCell.score) - Number(baseline.score),
      coverage_change: `${baseline.coverage_status ?? "unknown"}->${finalCell?.coverage_status ?? "missing"}`,
      blocker_classification: regressions.find((row) => row.cell_id === baseline.cell_id)?.kind || null,
      evidence_refs: finalCell?.evidence_refs || [],
      evidence_lenses: finalCell?.evidence_lenses || [],
    };
  });

  return { deltaRows: [...comparisonDelta, ...deltaRows], regressions };
}

function evidenceInventory(files, outputPaths, referencedRefs = []) {
  const entries = files
    .filter((absPath) => fs.existsSync(absPath) && fs.statSync(absPath).isFile())
    .map((absPath) => ({
      path: normalizeArtifactRef(absPath),
      sha256: sha256(absPath),
      bytes: fs.statSync(absPath).size,
    }))
    .filter((entry) => isAllowedArtifactRef(entry.path))
    .sort((a, b) => a.path.localeCompare(b.path));

  const seen = new Set(entries.map((entry) => entry.path));
  for (const ref of referencedRefs.map((value) => normalizeArtifactRef(value)).filter(isAllowedArtifactRef)) {
    if (seen.has(ref)) continue;
    seen.add(ref);
    entries.push({ path: ref, status: "referenced-evidence" });
  }

  const outputs = Object.fromEntries(
    Object.entries(outputPaths).map(([key, absPath]) => [key, relativeFromRepo(path.resolve(absPath))])
  );

  for (const ref of Object.values(outputs)) {
    if (seen.has(ref)) continue;
    seen.add(ref);
    entries.push({ path: ref, generated: true });
  }

  return {
    generated_at: new Date().toISOString(),
    phase: "200-idempotent-verification-sign-off",
    outputs,
    evidence: entries,
  };
}

function renderMarkdown({ finalCells, deltaRows, regressions, manifestContent, dryRun }) {
  const covered = finalCells.filter((cell) => cell.coverage_status === "covered").length;
  const p193Open = regressions.filter((row) => String(row.kind || "").startsWith("p193-")).length;
  const scoreDowngrades = regressions.filter((row) => row.kind === "score-downgrade").length;
  const coverageDowngrades = regressions.filter((row) => row.kind === "coverage-downgrade").length;
  const missingEvidence = regressions.filter((row) => row.kind === "missing-evidence" || row.kind === "p193-missing-evidence").length;
  const status = regressions.length === 0 ? "pass" : "fail";

  const blockerLines =
    regressions.length === 0
      ? ["No blocking regressions recorded."]
      : regressions.map(
          (row) =>
            `- ${row.kind}: ${row.cell_id || "(no cell)"} ${row.dimension_name || ""} - ${row.message} Evidence: ${
              row.evidence_refs?.join(", ") || "none"
            }`
        );

  return `# Phase 200 Scorecard

**Status:** ${status}${dryRun ? " (dry-run preview)" : ""}

## Blocking Regressions

${blockerLines.join("\n")}

## Structured Summary

- Final cells: ${finalCells.length}
- Covered final cells: ${covered}
- Delta rows: ${deltaRows.length}
- Regression rows: ${regressions.length}
- Score downgrades: ${scoreDowngrades}
- Coverage downgrades: ${coverageDowngrades}
- Missing evidence rows: ${missingEvidence}
- Open p193 closure rows: ${p193Open}
- Manifest evidence entries: ${manifestContent.evidence.length}
- Maintainer sign-off state: pending 200-SIGN-OFF.md

## Canonical Artifacts

- baseline.union.cells.json
- final.cells.json
- scorecard.delta.json
- regressions.ndjson
- artifacts.manifest.json

This markdown is derived from structured reducer output. Structured JSON and NDJSON artifacts remain canonical.
`;
}

export function generatePhase200Scorecard(options = {}) {
  const componentBaselinePath = path.resolve(options.componentBaselinePath || DEFAULT_INPUTS.componentBaselinePath);
  const pageFlowBaselinePath = path.resolve(options.pageFlowBaselinePath || DEFAULT_INPUTS.pageFlowBaselinePath);
  const evidenceRoot = path.resolve(options.evidenceRoot || DEFAULT_INPUTS.evidenceRoot);
  const outputPaths = { ...OUTPUTS, ...(options.outputs || {}) };
  const dryRun = Boolean(options.dryRun);
  const baselineOnly = Boolean(options.baselineOnly);
  const write = options.write !== false && !dryRun;

  assertOutputPathsSafe(outputPaths);

  const componentRows = readJson(componentBaselinePath);
  const pageFlowRows = readJson(pageFlowBaselinePath);
  const unionRows = buildUnionBaseline(componentRows, pageFlowRows, options.expectedUnionCount ?? EXPECTED_UNION_COUNT);
  const unionBaselineById = new Map(unionRows.map((cell) => [cell.cell_id, cell]));

  if (write) writeJson(outputPaths.baselineUnion, unionRows);

  if (baselineOnly) {
    return {
      baselineUnion: unionRows,
      summary: {
        union_cells: unionRows.length,
        component_cells: componentRows.length,
        page_flow_cells: pageFlowRows.length,
        baseline_only: true,
        dry_run: dryRun,
      },
      outputPaths,
    };
  }

  const lensFiles = discoverLensFiles(evidenceRoot, options.lensInputs || []);
  const artifactFiles = discoverArtifactFiles(evidenceRoot, options.lensInputs || []);
  const normalized = normalizeEvidence(lensFiles, unionBaselineById);
  const finalCells = finalCellsFromUnion(unionRows, normalized.cellsById);
  const comparison = compareCells(unionRows, finalCells, normalized.corrections);
  const regressions = [...normalized.failures, ...comparison.regressions];
  const deltaRows = comparison.deltaRows;
  const referencedRefs = [
    ...finalCells.flatMap((cell) => cell.evidence_refs || []),
    ...deltaRows.flatMap((row) => row.evidence_refs || []),
    ...regressions.flatMap((row) => row.evidence_refs || []),
  ];
  const manifestContent = evidenceInventory(artifactFiles.length > 0 ? artifactFiles : lensFiles, outputPaths, referencedRefs);
  const markdownContent = renderMarkdown({ finalCells, deltaRows, regressions, manifestContent, dryRun });

  const packageResult = {
    baselineUnion: unionRows,
    finalCells,
    deltaRows,
    regressions,
    manifest: manifestContent,
    markdown: markdownContent,
    summary: {
      union_cells: unionRows.length,
      final_cells: finalCells.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      lens_inputs: lensFiles.length,
      dry_run: dryRun,
      baseline_only: false,
    },
    outputPaths,
  };

  if (write) {
    writeJson(outputPaths.finalCells, finalCells);
    writeJson(outputPaths.delta, deltaRows);
    writeText(outputPaths.regressions, regressions.map((row) => JSON.stringify(row)).join("\n") + (regressions.length ? "\n" : ""));
    writeJson(outputPaths.manifest, manifestContent);
    writeText(outputPaths.markdown, markdownContent);
  }

  return packageResult;
}

function fixtureCell(overrides = {}) {
  return {
    cell_id: "p187__fixture-surface__chromium-desktop__light__default-populated__d11",
    surface: "fixture-surface",
    surface_type: "component",
    mode: "chromium-desktop",
    viewport_width: 1440,
    theme: "light",
    state: "default-populated",
    dimension: 11,
    dimension_name: "interaction-integrity",
    score: 2,
    coverage_status: "covered",
    evidence_refs: ["accrue_admin/test-results/phase200/fixture-component.json"],
    evidence_lenses: ["correctness"],
    notes: "Fixture deterministic interaction row.",
    targeted_label: null,
    breakpoint: null,
    ...overrides,
  };
}

function fixtureP193(overrides = {}) {
  return {
    cell_id: "p193__fixture-flow__chromium-desktop__light__default-populated__d11",
    surface: "fixture-flow",
    surface_type: "page-flow",
    mode: "chromium-desktop",
    viewport_width: 1440,
    theme: "light",
    state: "default-populated",
    dimension: 11,
    dimension_name: "interaction-integrity",
    score: null,
    coverage_status: "pending",
    evidence_refs: [],
    evidence_lenses: [],
    notes: "Awaiting Phase 193 page-flow baseline capture.",
    targeted_label: "fixture flow d11",
    breakpoint: "desktop",
    ...overrides,
  };
}

function writeFixture(root, name, rows) {
  const evidenceRoot = path.join(root, "evidence");
  fs.mkdirSync(evidenceRoot, { recursive: true });
  const filePath = path.join(evidenceRoot, name);
  writeJson(filePath, { rows });
  return evidenceRoot;
}

function runFixture(root, componentRows, pageFlowRows, evidenceRows = []) {
  const componentBaselinePath = path.join(root, "baseline.cells.json");
  const pageFlowBaselinePath = path.join(root, "baseline.page-flow.cells.json");
  const evidenceRoot = writeFixture(root, "phase200-evidence.json", evidenceRows);

  writeJson(componentBaselinePath, componentRows);
  writeJson(pageFlowBaselinePath, pageFlowRows);

  return generatePhase200Scorecard({
    componentBaselinePath,
    pageFlowBaselinePath,
    evidenceRoot,
    dryRun: true,
    write: false,
    expectedUnionCount: componentRows.length + pageFlowRows.length,
    outputs: {
      baselineUnion: path.join(root, "out/baseline.union.cells.json"),
      finalCells: path.join(root, "out/final.cells.json"),
      delta: path.join(root, "out/scorecard.delta.json"),
      regressions: path.join(root, "out/regressions.ndjson"),
      manifest: path.join(root, "out/artifacts.manifest.json"),
      markdown: path.join(root, "out/200-SCORECARD.md"),
    },
  });
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-scorecard-"));
  try {
    const baseline = [fixtureCell()];
    const p193 = [fixtureP193()];
    const p193Evidence = [
      fixtureP193({
        score: 2,
        coverage_status: "covered",
        evidence_refs: ["accrue_admin/test-results/phase200/page-flow-evidence.json"],
        evidence_lenses: ["page-flow", "interaction-trace"],
        notes: "Phase 200 fixture evidence closes p193.",
      }),
    ];

    const positive = runFixture(path.join(root, "positive"), baseline, p193, p193Evidence);
    assertSelfTest("positive fixture produces union baseline", positive.baselineUnion.length === 2);
    assertSelfTest("positive fixture has zero regressions", positive.regressions.length === 0, JSON.stringify(positive.regressions));
    assertSelfTest("positive fixture renders markdown from structured counts", positive.markdown.includes("Final cells: 2"));

    let duplicateFailed = false;
    try {
      runFixture(path.join(root, "duplicate"), baseline, [fixtureP193({ cell_id: baseline[0].cell_id })], []);
    } catch (error) {
      duplicateFailed = /Duplicate union cell IDs/.test(error.message);
    }
    assertSelfTest("duplicate union ID fails generation", duplicateFailed);

    const scoreDowngrade = runFixture(path.join(root, "score-downgrade"), baseline, p193, [
      fixtureCell({ score: 1, evidence_refs: ["accrue_admin/test-results/phase200/fixture-component.json"] }),
      ...p193Evidence,
    ]);
    assertSelfTest(
      "score downgrade produces score-downgrade row",
      scoreDowngrade.regressions.some((row) => row.kind === "score-downgrade")
    );

    const coverageDowngrade = runFixture(path.join(root, "coverage-downgrade"), baseline, p193, [
      fixtureCell({ coverage_status: "gap", evidence_refs: ["accrue_admin/test-results/phase200/fixture-component.json"] }),
      ...p193Evidence,
    ]);
    assertSelfTest(
      "coverage downgrade produces coverage-downgrade row",
      coverageDowngrade.regressions.some((row) => row.kind === "coverage-downgrade")
    );

    const missingEvidence = runFixture(path.join(root, "missing-evidence"), baseline, p193, [
      fixtureCell({ evidence_refs: [] }),
      ...p193Evidence,
    ]);
    assertSelfTest(
      "missing evidence produces missing-evidence row",
      missingEvidence.regressions.some((row) => row.kind === "missing-evidence")
    );

    const pendingP193 = runFixture(path.join(root, "pending-p193"), baseline, p193, []);
    assertSelfTest(
      "p193 pending closure failure is produced",
      pendingP193.regressions.some((row) => row.kind === "p193-pending-closure")
    );
    assertSelfTest(
      "p193 score floor failure is produced",
      pendingP193.regressions.some((row) => row.kind === "p193-score-floor")
    );
    assertSelfTest(
      "p193 deterministic evidence failure is produced",
      pendingP193.regressions.some((row) => row.kind === "p193-missing-evidence")
    );

    const baselineOnly = generatePhase200Scorecard({
      componentBaselinePath: path.join(root, "positive/baseline.cells.json"),
      pageFlowBaselinePath: path.join(root, "positive/baseline.page-flow.cells.json"),
      baselineOnly: true,
      dryRun: true,
      write: false,
      expectedUnionCount: 2,
      outputs: {
        baselineUnion: path.join(root, "out/baseline.union.cells.json"),
        finalCells: path.join(root, "out/final.cells.json"),
        delta: path.join(root, "out/scorecard.delta.json"),
        regressions: path.join(root, "out/regressions.ndjson"),
        manifest: path.join(root, "out/artifacts.manifest.json"),
        markdown: path.join(root, "out/200-SCORECARD.md"),
      },
    });
    assertSelfTest("baseline-only mode builds union without final artifacts", baselineOnly.summary.baseline_only);

    console.log("Phase 200 scorecard reducer self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = { lensInputs: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--baseline-only") options.baselineOnly = true;
    else if (arg === "--dry-run") options.dryRun = true;
    else if (arg === "--component-baseline") options.componentBaselinePath = path.resolve(argv[++index]);
    else if (arg === "--page-flow-baseline") options.pageFlowBaselinePath = path.resolve(argv[++index]);
    else if (arg === "--evidence-root") options.evidenceRoot = path.resolve(argv[++index]);
    else if (arg === "--lens") options.lensInputs.push(path.resolve(argv[++index]));
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

  const result = generatePhase200Scorecard(options);
  if (options.baselineOnly) {
    console.log(
      `Phase 200 union baseline ${options.dryRun ? "dry-run" : "generation"}: union=${
        result.summary.union_cells
      }, component=${result.summary.component_cells}, page_flow=${result.summary.page_flow_cells}`
    );
    return result;
  }

  console.log(
    `Phase 200 scorecard ${options.dryRun ? "dry-run" : "generation"}: union=${
      result.summary.union_cells
    }, final=${result.summary.final_cells}, delta=${result.summary.delta_rows}, regressions=${
      result.summary.regression_rows
    }, lens_inputs=${result.summary.lens_inputs}`
  );

  if (!options.dryRun && result.regressions.length > 0) {
    console.error("Phase 200 scorecard has blocking regressions; see regressions.ndjson.");
    process.exitCode = 1;
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 scorecard reducer failed: ${error.message}`);
    process.exitCode = 1;
  }
}
