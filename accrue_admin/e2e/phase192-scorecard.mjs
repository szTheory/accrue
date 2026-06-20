import fs from "fs";
import os from "os";
import path from "path";
import { createHash } from "crypto";
import { fileURLToPath } from "url";

import manifest from "./baseline-manifest.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const testResultsRoot = path.join(adminRoot, "test-results");
const PHASE187_DIR = ".planning/phases/187-audit-baseline";
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE192_DIR);

const { DIMENSIONS, PROJECTS, STATE_TAXONOMY } = manifest;

const DEFAULT_INPUTS = {
  baselinePath: path.join(repoRoot, PHASE187_DIR, "baseline.cells.json"),
  evidenceRoot: testResultsRoot,
};

const OUTPUTS = {
  finalCells: path.join(phaseDir, "final.cells.json"),
  delta: path.join(phaseDir, "scorecard.delta.json"),
  regressions: path.join(phaseDir, "regressions.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  markdown: path.join(phaseDir, "192-SCORECARD.md"),
};

const COVERAGE_RANK = new Map([
  ["missing", -1],
  ["unreachable", -1],
  ["gap", 0],
  ["n/a", 1],
  ["covered", 2],
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

const VISUAL_ONLY_LENSES = new Set(["visual-brand-microcopy", "maintainer-review"]);
const DETERMINISTIC_DIMENSIONS = new Set([
  "contrast",
  "focus-semantics",
  "motion",
  "state-coverage",
  "responsive-mobile-first",
  "interaction-integrity",
]);

const DETERMINISTIC_CLAIM_WORDS = [
  "accessibility",
  "a11y",
  "axe",
  "focus",
  "scroll",
  "overlay",
  "actionability",
  "interaction",
  "escape",
  "outside click",
  "ci pass",
  "guardrail",
];

const GENERATED_ROOTS = [
  "accrue_admin/test-results/",
  "accrue_admin/playwright-report/",
  `${PHASE192_DIR}/`,
];

function relativeFromRepo(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function normalizeRef(value, baseDir = repoRoot) {
  if (!value) return null;
  const raw = String(value).split(path.sep).join("/");
  if (raw.startsWith("playwright-trace:")) return raw;
  if (GENERATED_ROOTS.some((root) => raw.startsWith(root))) return raw;
  if (raw.startsWith("test-results/")) return `accrue_admin/${raw}`;
  if (path.isAbsolute(raw)) return relativeFromRepo(raw);
  return path.relative(repoRoot, path.resolve(baseDir, raw)).split(path.sep).join("/");
}

function isGeneratedRef(ref) {
  const value = String(ref || "");
  if (value.startsWith("playwright-trace:")) return true;
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) {
    return false;
  }
  return GENERATED_ROOTS.some((root) => value.startsWith(root));
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

function readJson(absPath) {
  try {
    return JSON.parse(fs.readFileSync(absPath, "utf8"));
  } catch (error) {
    throw new Error(`Unable to parse JSON at ${absPath}: ${error.message}`);
  }
}

function readNdjson(absPath) {
  const rows = [];
  const body = fs.readFileSync(absPath, "utf8");
  body.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try {
      rows.push(JSON.parse(line));
    } catch (error) {
      throw new Error(`Unable to parse NDJSON at ${absPath}:${index + 1}: ${error.message}`);
    }
  });
  return rows;
}

function readRows(absPath) {
  if (absPath.endsWith(".ndjson") || absPath.endsWith(".jsonl")) return readNdjson(absPath);
  if (!absPath.endsWith(".json")) return [];
  const parsed = readJson(absPath);
  if (Array.isArray(parsed)) return parsed;
  if (Array.isArray(parsed.cells)) return parsed.cells;
  if (Array.isArray(parsed.rows)) return parsed.rows;
  if (Array.isArray(parsed.findings)) return parsed.findings;
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

function dimensionInfo(value) {
  return DIMENSIONS.find((dimension) => dimension.id === Number(value) || dimension.name === value);
}

function projectInfo(value) {
  return PROJECTS.find((project) => project.name === value || project.mode === value);
}

function scoreValue(value) {
  if (value === null || value === undefined) return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number < 0 || number > 3) {
    throw new Error(`Invalid score "${value}"; expected 0, 1, 2, 3, or null.`);
  }
  return number;
}

function evidenceRefs(row, sourceRef, sourceDir = repoRoot) {
  const sourceEvidenceRef = normalizeRef(sourceRef, sourceDir);
  return Array.from(
    new Set(
      [
        ...(Array.isArray(row?.evidence_refs) ? row.evidence_refs : []),
        ...(Array.isArray(row?.evidenceRefs) ? row.evidenceRefs : []),
        row?.evidence_ref,
        row?.evidenceRef,
        isGeneratedRef(sourceEvidenceRef) ? sourceEvidenceRef : null,
      ]
        .map((ref) => normalizeRef(ref, sourceDir))
        .filter(Boolean)
    )
  );
}

function rowLenses(row, sourceRef) {
  const explicit = [
    ...(Array.isArray(row?.evidence_lenses) ? row.evidence_lenses : []),
    ...(Array.isArray(row?.lens_results) ? row.lens_results.map((lens) => lens.lens || lens.name) : []),
    ...(Array.isArray(row?.lenses) ? row.lenses : []),
    row?.lens,
    row?.validation_lens,
  ]
    .filter(Boolean)
    .map((lens) => String(lens).trim().toLowerCase().replace(/_/g, "-"));

  if (explicit.length > 0) return Array.from(new Set(explicit));

  const source = `${sourceRef || ""} ${row?.source || ""} ${row?.kind || ""}`.toLowerCase();
  if (source.includes("axe") || source.includes("wcag")) return ["axe"];
  if (source.includes("reduced-motion")) return ["reduced-motion"];
  if (source.includes("group-contract")) return ["component-group"];
  if (source.includes("phase191") || source.includes("interaction") || source.includes("trace")) {
    return ["interaction-trace"];
  }
  if (source.includes("visual") || source.includes("screenshot") || source.includes("score-visuals")) {
    return ["visual-brand-microcopy"];
  }
  if (source.includes("component")) return ["component-lab"];
  if (source.includes("baseline")) return ["correctness"];
  return ["correctness"];
}

function idDimension(cellId) {
  const match = String(cellId || "").match(/__d([0-9]{2})(?:__|$)/);
  return match ? Number(match[1]) : null;
}

function validP187Id(cellId) {
  return /^p187__.+__d(0[1-9]|1[0-2])(?:__.+)?$/.test(String(cellId || ""));
}

function contractedCell(row, sourceRef = null, sourceDir = repoRoot) {
  const dimension = dimensionInfo(row.dimension ?? row.rubric_dimension);
  if (!dimension) throw new Error(`Unable to normalize row without a Phase 187 dimension: ${JSON.stringify(row)}`);

  const cellId = row.cell_id || row.final_cell_id;
  if (!cellId || !validP187Id(cellId)) {
    throw new Error(`Unable to normalize row without frozen p187__...__dXX cell_id: ${cellId || "(missing)"}`);
  }
  if (idDimension(cellId) !== dimension.id) {
    throw new Error(`Cell ${cellId} changes the Phase 187 dimension suffix.`);
  }

  const project = projectInfo(row.mode || row.project || row.viewport);
  const refs = evidenceRefs(row, sourceRef, sourceDir);
  const lenses = rowLenses(row, sourceRef);

  for (const lens of lenses) {
    if (!ALLOWED_LENSES.has(lens)) throw new Error(`Unsupported evidence lens "${lens}" for ${cellId}.`);
  }

  return {
    cell_id: cellId,
    surface: row.surface || "unknown",
    surface_type: row.surface_type || "page-flow",
    mode: row.mode || project?.mode || "chromium-desktop",
    viewport_width: Number(row.viewport_width ?? project?.viewport_width ?? 1440),
    theme: row.theme || "light",
    state: STATE_TAXONOMY.includes(row.state) ? row.state : "default-populated",
    dimension: dimension.id,
    dimension_name: dimension.name,
    score: scoreValue(row.score ?? row.final_score),
    coverage_status: normalizeCoverage(row.coverage_status),
    evidence_refs: refs,
    evidence_lenses: lenses,
    lens_results: normalizeLensResults(row, lenses, refs),
    notes: row.notes || row.reason || row.defect || row.actual || "Normalized Phase 192 evidence row.",
    targeted_label: row.targeted_label ?? null,
    breakpoint: row.breakpoint ?? null,
  };
}

function normalizeCoverage(value) {
  const coverage = String(value || "covered");
  if (coverage === "missing" || coverage === "unreachable") return coverage;
  if (COVERAGE_RANK.has(coverage)) return coverage;
  return "covered";
}

function normalizeLensResults(row, lenses, refs) {
  if (Array.isArray(row.lens_results)) return row.lens_results;
  return lenses.map((lens) => ({
    lens,
    status: row.status || row.outcome || "observed",
    evidence_refs: refs,
  }));
}

function supportIsVisualOnly(cell) {
  const lenses = rowLenses(cell);
  if (lenses.length > 0) return lenses.every((lens) => VISUAL_ONLY_LENSES.has(lens));
  return false;
}

function requiresDeterministicSupport(cell) {
  const notes = String(cell.notes || "").toLowerCase();
  return (
    DETERMINISTIC_DIMENSIONS.has(cell.dimension_name) ||
    DETERMINISTIC_CLAIM_WORDS.some((word) => notes.includes(word))
  );
}

function regressionRow(kind, baseline, finalCell, message) {
  const refs = Array.from(new Set([...(finalCell?.evidence_refs || []), ...(baseline?.evidence_refs || [])]));
  return {
    id: `P192-${kind.toUpperCase()}-${String(baseline?.cell_id || finalCell?.cell_id || "unknown")
      .replace(/[^a-zA-Z0-9]+/g, "-")
      .slice(0, 80)}`,
    kind,
    cell_id: finalCell?.cell_id || baseline?.cell_id || null,
    surface: finalCell?.surface || baseline?.surface || null,
    state: finalCell?.state || baseline?.state || null,
    dimension: finalCell?.dimension || baseline?.dimension || null,
    dimension_name: finalCell?.dimension_name || baseline?.dimension_name || null,
    baseline_score: baseline?.score ?? null,
    final_score: finalCell?.score ?? null,
    baseline_coverage_status: baseline?.coverage_status ?? null,
    final_coverage_status: finalCell?.coverage_status ?? null,
    evidence_refs: refs,
    evidence_lenses: finalCell?.evidence_lenses || [],
    message,
    required_repair: "Repair the evidence, harness normalization, or true UI regression before final sign-off.",
  };
}

function compareCells(baselineRows, finalRows, deltaRows) {
  const baselineById = new Map(baselineRows.map((cell) => [cell.cell_id, cell]));
  const finalById = new Map(finalRows.map((cell) => [cell.cell_id, cell]));
  const regressions = [];
  const comparableIds = new Set([...finalById.keys()]);

  for (const finalCell of finalRows) {
    const baseline = baselineById.get(finalCell.cell_id);
    const correction = deltaRows.find((row) => isBaselineCorrection(row, finalCell.cell_id, baselineById));

    if (!baseline && !correction) {
      regressions.push(
        regressionRow(
          "baseline-correction-required",
          null,
          finalCell,
          "Final cell is not present in the frozen Phase 187 baseline and has no structured correction."
        )
      );
      continue;
    }

    if (finalCell.evidence_refs.length === 0) {
      regressions.push(regressionRow("missing-evidence", baseline, finalCell, "Comparable final cell has no evidence refs."));
    }

    for (const ref of finalCell.evidence_refs) {
      if (!isGeneratedRef(ref)) {
        regressions.push(regressionRow("missing-evidence", baseline, finalCell, `Invalid evidence ref: ${ref}`));
      }
    }

    if (requiresDeterministicSupport(finalCell) && supportIsVisualOnly(finalCell)) {
      regressions.push(
        regressionRow(
          "new-regression",
          baseline,
          finalCell,
          "D-17/D-18 deterministic claim is supported only by visual/model/maintainer evidence."
        )
      );
    }

    if (!baseline) continue;

    const baselineScore = scoreValue(baseline.score);
    const finalScore = scoreValue(finalCell.score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) {
      regressions.push(
        regressionRow(
          "score-downgrade",
          baseline,
          finalCell,
          `Final score ${finalScore} is below Phase 187 baseline score ${baselineScore}.`
        )
      );
    }

    if (
      baseline.coverage_status === "covered" &&
      ["gap", "missing", "unreachable"].includes(finalCell.coverage_status) &&
      !correction
    ) {
      regressions.push(
        regressionRow(
          "coverage-downgrade",
          baseline,
          finalCell,
          `Coverage downgraded from covered to ${finalCell.coverage_status}.`
        )
      );
    }
  }

  const finalDelta = [];
  for (const cellId of comparableIds) {
    const baseline = baselineById.get(cellId);
    const finalCell = finalById.get(cellId);
    if (!finalCell) continue;
    finalDelta.push({
      cell_id: cellId,
      baseline_score: baseline?.score ?? null,
      final_score: finalCell.score,
      baseline_coverage_status: baseline?.coverage_status ?? null,
      final_coverage_status: finalCell.coverage_status,
      score_delta:
        baseline?.score === null || baseline?.score === undefined || finalCell.score === null
          ? null
          : Number(finalCell.score) - Number(baseline.score),
      coverage_change: `${baseline?.coverage_status ?? "new"}->${finalCell.coverage_status}`,
      blocker_classification: regressions.find((row) => row.cell_id === cellId)?.kind || null,
      evidence_refs: finalCell.evidence_refs,
      evidence_lenses: finalCell.evidence_lenses,
    });
  }

  return { deltaRows: finalDelta, regressions };
}

function isBaselineCorrection(row, cellId, baselineById) {
  const type = String(row?.type || row?.kind || row?.reason || row?.status || "").toLowerCase();
  const correction = row?.baseline_correction || row?.correction || type.includes("baseline-correction");
  if (!correction) return false;
  const target = row.invalid_baseline_cell_id || row.baseline_cell_id || row.corrected_cell_id || row.cell_id;
  return Boolean(target && (target === cellId || baselineById.has(target) || String(target).startsWith("p187__")));
}

function evidenceInventory(files, generatedOutputs = OUTPUTS) {
  const entries = files
    .filter((absPath) => fs.existsSync(absPath) && fs.statSync(absPath).isFile())
    .map((absPath) => ({
      path: normalizeRef(absPath),
      sha256: sha256(absPath),
      bytes: fs.statSync(absPath).size,
    }))
    .filter((entry) => isGeneratedRef(entry.path))
    .sort((a, b) => a.path.localeCompare(b.path));

  const outputs = Object.fromEntries(
    Object.entries(generatedOutputs).map(([key, absPath]) => [key, relativeFromRepo(absPath)])
  );

  for (const ref of Object.values(outputs)) {
    entries.push({ path: ref, generated: true });
  }

  return {
    generated_at: new Date().toISOString(),
    phase: "192-idempotent-verification-sign-off",
    outputs,
    lens_inputs: files.map((absPath) => normalizeRef(absPath)).filter(Boolean).filter(isGeneratedRef),
    command_statuses: [],
    evidence: entries,
  };
}

function discoverLensFiles(evidenceRoot, explicitInputs = []) {
  const roots = [evidenceRoot, ...explicitInputs].filter(Boolean);
  const files = [];
  for (const entry of roots) {
    const absPath = path.resolve(entry);
    if (!fs.existsSync(absPath)) continue;
    if (fs.statSync(absPath).isDirectory()) {
      files.push(...listFiles(absPath).filter((file) => /\.(json|ndjson|jsonl)$/.test(file)));
    } else if (/\.(json|ndjson|jsonl)$/.test(absPath)) {
      files.push(absPath);
    }
  }
  return Array.from(new Set(files)).sort();
}

function normalizeEvidence(files, baselineById) {
  const cellsById = new Map();
  const corrections = [];
  const failures = [];

  for (const file of files) {
    const sourceRef = normalizeRef(file);
    let rows;
    try {
      rows = readRows(file);
    } catch (error) {
      failures.push({
        kind: "new-regression",
        cell_id: null,
        evidence_refs: [sourceRef],
        evidence_lenses: ["correctness"],
        message: error.message,
      });
      continue;
    }

    for (const row of rows) {
      if (!row || typeof row !== "object") continue;
      if (row.baseline_correction || String(row.kind || "").includes("baseline-correction")) {
        corrections.push({ ...row, evidence_refs: evidenceRefs(row, sourceRef, path.dirname(file)) });
        continue;
      }
      if (!row.cell_id && !row.final_cell_id) continue;

      try {
        const cell = contractedCell(row, sourceRef, path.dirname(file));
        if (!baselineById.has(cell.cell_id)) {
          failures.push(
            regressionRow(
              "baseline-correction-required",
              null,
              cell,
              "Evidence row uses a cell ID outside the frozen Phase 187 baseline."
            )
          );
        }
        const previous = cellsById.get(cell.cell_id);
        cellsById.set(cell.cell_id, mergeCell(previous, cell));
      } catch (error) {
        failures.push({
          kind: "new-regression",
          cell_id: row.cell_id || row.final_cell_id || null,
          evidence_refs: [sourceRef],
          evidence_lenses: rowLenses(row, sourceRef),
          message: error.message,
        });
      }
    }
  }

  return { cells: Array.from(cellsById.values()), corrections, failures };
}

function mergeCell(previous, next) {
  if (!previous) return next;
  const previousScore = previous.score ?? -1;
  const nextScore = next.score ?? -1;
  const winner = nextScore >= previousScore ? next : previous;
  return {
    ...winner,
    evidence_refs: Array.from(new Set([...previous.evidence_refs, ...next.evidence_refs])),
    evidence_lenses: Array.from(new Set([...previous.evidence_lenses, ...next.evidence_lenses])),
    lens_results: [...(previous.lens_results || []), ...(next.lens_results || [])],
    notes: `${previous.notes}\n${next.notes}`,
  };
}

function fallbackCellsFromBaseline(baselineRows) {
  return baselineRows
    .filter((cell) => Array.isArray(cell.evidence_refs) && cell.evidence_refs.length > 0)
    .map((cell) => ({
      ...cell,
      evidence_refs: Array.from(new Set(cell.evidence_refs.map((ref) => normalizeRef(ref)).filter(isGeneratedRef))),
      evidence_lenses: ["correctness"],
      lens_results: [
        {
          lens: "correctness",
          status: "read-only-baseline-preview",
          evidence_refs: cell.evidence_refs || [],
        },
      ],
      notes: `${cell.notes || ""} Phase 192 dry-run preview reused existing generated evidence references; Plan 192-06 owns final evidence generation.`,
    }))
    .filter((cell) => cell.evidence_refs.length > 0);
}

function renderMarkdown({ finalCells, deltaRows, regressions, manifestContent, dryRun }) {
  const covered = finalCells.filter((cell) => cell.coverage_status === "covered").length;
  const coverageDowngrades = regressions.filter((row) => row.kind === "coverage-downgrade").length;
  const scoreDowngrades = regressions.filter((row) => row.kind === "score-downgrade").length;
  const missingEvidence = regressions.filter((row) => row.kind === "missing-evidence").length;
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

  return `# Phase 192 Scorecard

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
- Manifest evidence entries: ${manifestContent.evidence.length}
- CI guardrail status: ${dryRun ? "not evaluated in non-final dry-run" : "see artifacts.manifest.json"}
- Maintainer sign-off state: pending 192-SIGN-OFF.md

## Canonical Artifacts

- final.cells.json
- scorecard.delta.json
- regressions.ndjson
- artifacts.manifest.json

This markdown is derived from structured reducer output. Structured JSON and NDJSON artifacts remain canonical.
`;
}

export function generatePhase192Scorecard(options = {}) {
  const baselinePath = path.resolve(options.baselinePath || DEFAULT_INPUTS.baselinePath);
  const evidenceRoot = path.resolve(options.evidenceRoot || DEFAULT_INPUTS.evidenceRoot);
  const outputPaths = { ...OUTPUTS, ...(options.outputs || {}) };
  const dryRun = Boolean(options.dryRun);

  const baselineRows = readJson(baselinePath);
  if (!Array.isArray(baselineRows)) throw new Error("baseline.cells.json must be an array.");
  const baselineById = new Map(baselineRows.map((cell) => [cell.cell_id, cell]));
  const lensFiles = discoverLensFiles(evidenceRoot, options.lensInputs || []);
  const normalized = normalizeEvidence(lensFiles, baselineById);
  const finalCells = normalized.cells.length > 0 ? normalized.cells : fallbackCellsFromBaseline(baselineRows);
  const initialDelta = normalized.corrections;
  const comparison = compareCells(baselineRows, finalCells, initialDelta);
  const regressions = [...normalized.failures, ...comparison.regressions];
  const deltaRows = [...comparison.deltaRows, ...initialDelta];
  const manifestContent = evidenceInventory(lensFiles, outputPaths);
  const markdownContent = renderMarkdown({ finalCells, deltaRows, regressions, manifestContent, dryRun });

  const packageResult = {
    finalCells,
    deltaRows,
    regressions,
    manifest: manifestContent,
    markdown: markdownContent,
    summary: {
      baseline_cells: baselineRows.length,
      final_cells: finalCells.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      lens_inputs: lensFiles.length,
      dry_run: dryRun,
    },
    outputPaths,
  };

  if (!dryRun && options.write !== false) {
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
    surface_type: "page-flow",
    mode: "chromium-desktop",
    viewport_width: 1440,
    theme: "light",
    state: "default-populated",
    dimension: 11,
    dimension_name: "interaction-integrity",
    score: 2,
    coverage_status: "covered",
    evidence_refs: ["accrue_admin/test-results/phase192-fixture/interaction.json"],
    evidence_lenses: ["interaction-trace", "correctness"],
    notes: "Fixture deterministic interaction row.",
    targeted_label: null,
    breakpoint: null,
    ...overrides,
  };
}

function writeFixture(root, rows) {
  fs.mkdirSync(root, { recursive: true });
  writeJson(path.join(root, "lens.json"), rows);
  return path.join(root, "lens.json");
}

function runFixture(root, baseline, rows) {
  const baselinePath = path.join(root, "baseline.cells.json");
  const evidenceRoot = path.join(root, "evidence");
  writeJson(baselinePath, baseline);
  writeFixture(evidenceRoot, rows);
  return generatePhase192Scorecard({
    baselinePath,
    evidenceRoot,
    dryRun: true,
    write: false,
    outputs: {
      finalCells: path.join(root, "out/final.cells.json"),
      delta: path.join(root, "out/scorecard.delta.json"),
      regressions: path.join(root, "out/regressions.ndjson"),
      manifest: path.join(root, "out/artifacts.manifest.json"),
      markdown: path.join(root, "out/192-SCORECARD.md"),
    },
  });
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase192-scorecard-"));
  try {
    const baseline = [fixtureCell()];

    const positive = runFixture(path.join(root, "positive"), baseline, [fixtureCell({ score: 3 })]);
    assertSelfTest("positive fixture produces one final cell", positive.finalCells.length === 1);
    assertSelfTest("positive fixture produces one passing delta", positive.deltaRows.length === 1);
    assertSelfTest("positive fixture has zero regressions", positive.regressions.length === 0);
    assertSelfTest("positive fixture preserves manifest evidence refs", positive.manifest.evidence.length > 0);

    const scoreDowngrade = runFixture(path.join(root, "score-downgrade"), baseline, [fixtureCell({ score: 1 })]);
    assertSelfTest(
      "score downgrade produces score-downgrade row",
      scoreDowngrade.regressions.some((row) => row.kind === "score-downgrade")
    );

    for (const coverage_status of ["gap", "missing", "unreachable"]) {
      const result = runFixture(path.join(root, `coverage-${coverage_status}`), baseline, [
        fixtureCell({ coverage_status }),
      ]);
      assertSelfTest(
        `coverage ${coverage_status} produces coverage-downgrade row`,
        result.regressions.some((row) => row.kind === "coverage-downgrade")
      );
    }

    const missingEvidence = runFixture(path.join(root, "missing-evidence"), baseline, [
      fixtureCell({ evidence_refs: [], evidence_lenses: ["interaction-trace"] }),
    ]);
    assertSelfTest(
      "missing evidence produces missing-evidence row",
      missingEvidence.regressions.some((row) => row.kind === "missing-evidence")
    );

    const invalidId = runFixture(path.join(root, "invalid-id"), baseline, [
      fixtureCell({ cell_id: "phase192__fixture__d11" }),
    ]);
    assertSelfTest(
      "non-Phase-187 cell ID is rejected",
      invalidId.regressions.some((row) => row.kind === "new-regression")
    );

    const changedDimension = runFixture(path.join(root, "changed-dimension"), baseline, [
      fixtureCell({
        cell_id: "p187__fixture-surface__chromium-desktop__light__default-populated__d12",
        dimension: 11,
      }),
    ]);
    assertSelfTest(
      "changed dimension suffix is rejected",
      changedDimension.regressions.some((row) => row.kind === "new-regression")
    );

    const baselineCorrection = runFixture(path.join(root, "baseline-correction"), baseline, [
      {
        ...fixtureCell({ cell_id: "p187__new-surface__chromium-desktop__light__default-populated__d11" }),
        baseline_correction: true,
        kind: "baseline-correction-required",
        invalid_baseline_cell_id: baseline[0].cell_id,
        reason: "Phase 187 row was invalid and stale.",
      },
    ]);
    assertSelfTest("baseline correction fixture is represented structurally", baselineCorrection.deltaRows.length >= 1);

    const visualOnly = runFixture(path.join(root, "visual-only"), baseline, [
      fixtureCell({
        evidence_refs: ["accrue_admin/test-results/phase192-fixture/screenshot.png"],
        evidence_lenses: ["visual-brand-microcopy"],
      }),
    ]);
    assertSelfTest(
      "visual-only deterministic claim is rejected",
      visualOnly.regressions.some((row) => row.kind === "new-regression")
    );

    const packageShape = positive;
    assertSelfTest("final.cells.json shape has Phase 187 fields", "dimension_name" in packageShape.finalCells[0]);
    assertSelfTest("scorecard.delta.json shape records score comparison", "score_delta" in packageShape.deltaRows[0]);
    assertSelfTest("regressions.ndjson shape is NDJSON-ready", scoreDowngrade.regressions.every((row) => row.kind));
    assertSelfTest("192-SCORECARD.md derives from structured counts", packageShape.markdown.includes("Final cells: 1"));

    console.log("Phase 192 scorecard reducer self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = { lensInputs: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--dry-run") options.dryRun = true;
    else if (arg === "--baseline") options.baselinePath = argv[++index];
    else if (arg === "--evidence-root") options.evidenceRoot = argv[++index];
    else if (arg === "--lens") options.lensInputs.push(argv[++index]);
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

  const result = generatePhase192Scorecard(options);
  console.log(
    `Phase 192 scorecard ${options.dryRun ? "dry-run" : "generation"}: baseline=${
      result.summary.baseline_cells
    }, final=${result.summary.final_cells}, delta=${result.summary.delta_rows}, regressions=${
      result.summary.regression_rows
    }, lens_inputs=${result.summary.lens_inputs}`
  );

  if (options.dryRun) {
    console.log("Dry-run did not write canonical Phase 192 scorecard artifacts.");
    return result;
  }

  if (result.regressions.length > 0) {
    console.error("Phase 192 scorecard has blocking regressions; see regressions.ndjson.");
    process.exitCode = 1;
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 192 scorecard reducer failed: ${error.message}`);
    process.exitCode = 1;
  }
}
