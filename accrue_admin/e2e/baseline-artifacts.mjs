import fs from "fs";
import path from "path";
import { createHash } from "crypto";
import { fileURLToPath } from "url";

import manifest from "./baseline-manifest.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const testResultsRoot = path.join(adminRoot, "test-results");
const PHASE_ARTIFACT_DIR = ".planning/phases/187-audit-baseline";
const TARGETED_LABELS = ["targeted-320", "targeted-375", "targeted-768", "targeted-1024", "targeted-1440"];
const phaseDir = path.join(repoRoot, PHASE_ARTIFACT_DIR);
const dryRun = process.argv.includes("--dry-run");

const {
  DIMENSIONS,
  PROJECTS,
  SURFACES,
  cellId,
  cellsForSurface,
} = manifest;

const OUTPUTS = {
  cells: path.join(phaseDir, "baseline.cells.json"),
  defects: path.join(phaseDir, "defects.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  markdown: path.join(phaseDir, "187-BASELINE.md"),
};

const INPUTS = {
  baseline: path.join(testResultsRoot, "admin-baseline"),
  interactions: path.join(testResultsRoot, "admin-interactions"),
  findings: path.join(testResultsRoot, "admin-visuals/findings.ndjson"),
  commandStatus: path.join(testResultsRoot, "phase187-command-status.json"),
};

function relativeFromRepo(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function assertEvidencePath(absPath) {
  const rel = relativeFromRepo(absPath);
  if (!rel.startsWith("accrue_admin/test-results/")) {
    throw new Error(`Refusing to reference evidence outside accrue_admin/test-results/: ${rel}`);
  }
  return rel;
}

function sha256(absPath) {
  return createHash("sha256").update(fs.readFileSync(absPath)).digest("hex");
}

function listFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  return entries.flatMap((entry) => {
    const absPath = path.join(dir, entry.name);
    return entry.isDirectory() ? listFiles(absPath) : [absPath];
  });
}

function readJsonFile(absPath) {
  try {
    return { ok: true, value: JSON.parse(fs.readFileSync(absPath, "utf8")) };
  } catch (error) {
    return { ok: false, error };
  }
}

function readNdjsonFile(absPath) {
  const rows = [];
  const failures = [];
  const body = fs.readFileSync(absPath, "utf8");
  body.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try {
      rows.push(JSON.parse(line));
    } catch (error) {
      failures.push({
        kind: "harness-error",
        evidence_ref: assertEvidencePath(absPath),
        message: `Invalid NDJSON at line ${index + 1}: ${error.message}`,
      });
    }
  });
  return { rows, failures };
}

function parseEvidenceFile(absPath) {
  const rel = assertEvidencePath(absPath);
  if (absPath.endsWith(".json")) {
    const parsed = readJsonFile(absPath);
    return parsed.ok
      ? { rows: Array.isArray(parsed.value) ? parsed.value : [parsed.value], failures: [] }
      : {
          rows: [],
          failures: [{ kind: "harness-error", evidence_ref: rel, message: parsed.error.message }],
        };
  }
  if (absPath.endsWith(".ndjson") || absPath.endsWith(".jsonl")) {
    return readNdjsonFile(absPath);
  }
  return { rows: [], failures: [] };
}

function evidenceInventory() {
  return listFiles(testResultsRoot)
    .filter((absPath) => fs.statSync(absPath).isFile())
    .map((absPath) => ({
      path: assertEvidencePath(absPath),
      sha256: sha256(absPath),
      bytes: fs.statSync(absPath).size,
    }))
    .sort((a, b) => a.path.localeCompare(b.path));
}

function projectForMode(mode) {
  return PROJECTS.find((project) => project.name === mode || project.mode === mode);
}

function dimensionFor(value) {
  return DIMENSIONS.find((dimension) => dimension.id === value || dimension.name === value);
}

function surfaceForName(name) {
  return SURFACES.find((surface) => surface.surface === name);
}

function normalizeRawBaselineRow(row, evidenceRef) {
  const mode = String(row.mode || row.project || row.viewport || "");
  if (/^targeted-\d+$/.test(mode)) {
    throw new Error(
      `Legacy targeted mode "${mode}" is invalid; use mode "targeted", numeric viewport_width, numeric breakpoint, and targeted_label.`
    );
  }

  if (mode === "targeted") {
    const breakpoint = Number(row.breakpoint ?? row.viewport_width ?? row.width);
    if (!Number.isFinite(breakpoint)) {
      throw new Error("Targeted baseline row is missing numeric breakpoint/viewport_width.");
    }
    const targetedLabel = String(row.targeted_label || `targeted-${breakpoint}`);
    if (!TARGETED_LABELS.includes(targetedLabel)) {
      throw new Error(`Targeted baseline row has unsupported targeted_label: ${targetedLabel}`);
    }
    return {
      ...row,
      mode: "targeted",
      viewport_width: Number(row.viewport_width ?? breakpoint),
      breakpoint,
      targeted_label: targetedLabel,
      evidence_refs: Array.from(new Set([...(row.evidence_refs || []), evidenceRef].filter(Boolean))),
    };
  }

  const project = projectForMode(mode);
  if (!project) return null;
  return {
    ...row,
    mode: project.mode,
    viewport_width: Number(row.viewport_width ?? project.viewport_width),
    breakpoint: row.breakpoint ?? null,
    targeted_label: row.targeted_label ?? null,
    evidence_refs: Array.from(new Set([...(row.evidence_refs || []), evidenceRef].filter(Boolean))),
  };
}

function screenshotEvidenceByCell(inventory) {
  const refs = new Map();
  for (const item of inventory) {
    const match = item.path.match(
      /^accrue_admin\/test-results\/admin-visuals\/([^/]+)\/(.+?)(-dark)?\.png$/
    );
    if (!match) continue;

    const [, projectName, screen, darkSuffix] = match;
    const surface = surfaceForName(screen);
    const project = projectForMode(projectName);
    if (!surface || !project) continue;

    const theme = darkSuffix ? "dark" : "light";
    for (const dimension of DIMENSIONS) {
      const id = cellId(surface.surface, project.name, theme, "default-populated", dimension.id);
      refs.set(id, [...(refs.get(id) || []), item.path]);
    }
  }
  return refs;
}

function buildBaselineCells(inventory, rawRows, harnessFailures) {
  const evidenceByCell = screenshotEvidenceByCell(inventory);
  const cells = SURFACES.flatMap((surface) => cellsForSurface(surface));
  const byId = new Map(cells.map((cell) => [cell.cell_id, cell]));

  for (const cell of cells) {
    const evidence = evidenceByCell.get(cell.cell_id) || [];
    if (evidence.length > 0) {
      cell.coverage_status = "covered";
      cell.evidence_refs = evidence;
      cell.notes = "Covered by admin visual screenshot evidence.";
    }
  }

  for (const { row, evidence_ref } of rawRows) {
    try {
      const normalized = normalizeRawBaselineRow(row, evidence_ref);
      if (!normalized) continue;

      const surface = surfaceForName(normalized.surface);
      const dimension = dimensionFor(normalized.dimension ?? normalized.dimension_name);
      if (!surface || !dimension) continue;

      const id =
        normalized.cell_id ||
        cellId(
          surface.surface,
          normalized.mode,
          normalized.theme || "light",
          normalized.state || "default-populated",
          dimension.id
        );

      byId.set(id, {
        cell_id: id,
        surface: surface.surface,
        surface_type: surface.surface_type,
        mode: normalized.mode,
        viewport_width: normalized.viewport_width,
        theme: normalized.theme || "light",
        state: normalized.state || "default-populated",
        dimension: dimension.id,
        dimension_name: dimension.name,
        score: normalized.score ?? null,
        coverage_status: normalized.coverage_status || "covered",
        evidence_refs: normalized.evidence_refs || [evidence_ref],
        notes: normalized.notes || "Imported from raw Phase 187 baseline evidence.",
        ...(normalized.mode === "targeted"
          ? {
              targeted_label: normalized.targeted_label,
              breakpoint: normalized.breakpoint,
            }
          : {}),
      });
    } catch (error) {
      harnessFailures.push({
        kind: "harness-error",
        evidence_ref,
        message: error.message,
      });
    }
  }

  return Array.from(byId.values()).sort((a, b) => a.cell_id.localeCompare(b.cell_id));
}

function overlayTagsForFinding(finding) {
  const text = [
    finding.defect,
    finding.suggested_fix,
    finding.actual,
    finding.message,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  const tags = [];
  if (/z-index|layer|scrim|modal|drawer|popover|dropdown/.test(text)) tags.push("layer-z-index");
  if (/focus trap|trapped focus/.test(text)) tags.push("focus-trap");
  if (/scroll|overflow|clipped/.test(text)) tags.push("scroll-reachability");
  if (/recover|retry|next action/.test(text)) tags.push("copy-recovery");
  if (/motion|animation|transition/.test(text)) tags.push("reduced-motion");
  return tags;
}

function severityForScore(score) {
  if (score === 0) return "high";
  if (score === 1) return "medium";
  return "low";
}

function defectFromFinding(finding, evidenceRef, index) {
  const surface = surfaceForName(finding.screen || finding.surface);
  const project = projectForMode(finding.viewport || finding.mode || "chromium-desktop");
  const dimension = dimensionFor(finding.dimension ?? finding.dimension_name);
  if (!surface || !project || !dimension || typeof finding.score !== "number" || finding.score >= 2) {
    return null;
  }

  const theme = finding.theme || "light";
  return {
    id: `AX187-${String(index).padStart(3, "0")}`,
    severity: severityForScore(finding.score),
    surface: surface.surface,
    surface_type: surface.surface_type,
    persona_job: surface.persona_job,
    reproduction: `Review ${evidenceRef} for ${surface.surface} in ${project.mode}/${theme}.`,
    expected: `${dimension.name} scores at least 2 under the Phase 187 rubric.`,
    actual: finding.defect || `${dimension.name} scored ${finding.score}.`,
    rubric_dimension: dimension.name,
    overlay_tags: overlayTagsForFinding(finding),
    cell_id: cellId(surface.surface, project.name, theme, "default-populated", dimension.id),
    evidence_refs: [evidenceRef],
    owner_phase: surface.owner_phase,
    status: "open",
    notes: finding.suggested_fix || "",
  };
}

function collectRawEvidence(harnessFailures) {
  const rawRows = [];
  const findings = [];
  for (const sourceDir of [INPUTS.baseline, INPUTS.interactions]) {
    for (const absPath of listFiles(sourceDir)) {
      if (!/\.(json|ndjson|jsonl)$/.test(absPath)) continue;
      const evidenceRef = assertEvidencePath(absPath);
      const parsed = parseEvidenceFile(absPath);
      harnessFailures.push(...parsed.failures);
      rawRows.push(...parsed.rows.map((row) => ({ row, evidence_ref: evidenceRef })));
    }
  }

  if (fs.existsSync(INPUTS.findings)) {
    const parsed = readNdjsonFile(INPUTS.findings);
    harnessFailures.push(...parsed.failures);
    findings.push(...parsed.rows.map((row) => ({ row, evidence_ref: assertEvidencePath(INPUTS.findings) })));
  }

  return { rawRows, findings };
}

function classifyCommandStatus(rawRows, findings, harnessFailures, observations) {
  if (!fs.existsSync(INPUTS.commandStatus)) return;

  const evidenceRef = assertEvidencePath(INPUTS.commandStatus);
  const parsed = readJsonFile(INPUTS.commandStatus);
  if (!parsed.ok) {
    harnessFailures.push({ kind: "harness-error", evidence_ref: evidenceRef, message: parsed.error.message });
    return;
  }

  const statuses = Array.isArray(parsed.value) ? parsed.value : parsed.value.commands || [parsed.value];
  for (const status of statuses) {
    const exitCode = Number(status.exit_code ?? status.exitCode ?? status.status ?? 0);
    const name = status.name || status.command || "unknown producer";
    if (exitCode === 0) continue;

    const parseableEvidence = rawRows.length > 0 || findings.length > 0;
    if (parseableEvidence && !status.crashed && !status.parser_error) {
      observations.push({
        kind: "defects-found",
        producer: name,
        exit_code: exitCode,
        evidence_ref: evidenceRef,
      });
    } else {
      harnessFailures.push({
        kind: "harness-error",
        producer: name,
        exit_code: exitCode,
        evidence_ref: evidenceRef,
        message: status.error || status.message || "Producer exited nonzero without parseable raw evidence.",
      });
    }
  }
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}

function markdownSummary(cells, defects, artifactManifest) {
  const covered = cells.filter((cell) => cell.coverage_status === "covered").length;
  return `# Phase 187 Baseline

Structured artifacts are canonical for Phase 187 and Phase 192 comparison.

## Artifact Counts

- Baseline cells: ${cells.length}
- Covered cells: ${covered}
- Defects: ${defects.length}
- Evidence files referenced: ${artifactManifest.evidence.length}
- Harness failures: ${artifactManifest.harness_failures.length}

## Outputs

- \`baseline.cells.json\` - schema-shaped baseline matrix cells
- \`defects.ndjson\` - severity-ranked defect ledger rows
- \`artifacts.manifest.json\` - evidence references, checksums, observations, and harness failures

Generated by \`npm run baseline:artifacts\`.
`;
}

export function main() {
  const harnessFailures = [];
  const observations = [];
  const inventory = evidenceInventory();
  const { rawRows, findings } = collectRawEvidence(harnessFailures);
  classifyCommandStatus(rawRows, findings, harnessFailures, observations);

  if (!fs.existsSync(INPUTS.findings)) {
    harnessFailures.push({
      kind: "harness-error",
      evidence_ref: "accrue_admin/test-results/admin-visuals/findings.ndjson",
      message: "Required vision findings evidence is missing; run score-visuals when credentials are available.",
    });
  }

  const cells = buildBaselineCells(inventory, rawRows, harnessFailures);
  let defectIndex = 1;
  const defects = findings
    .map(({ row, evidence_ref }) => defectFromFinding(row, evidence_ref, defectIndex++))
    .filter(Boolean);

  const artifactManifest = {
    generated_at: new Date().toISOString(),
    phase: "187-audit-baseline",
    outputs: Object.fromEntries(
      Object.entries(OUTPUTS).map(([key, absPath]) => [key, relativeFromRepo(absPath)])
    ),
    evidence: inventory,
    observations,
    harness_failures: harnessFailures,
  };

  if (dryRun) {
    console.log(
      JSON.stringify(
        {
          dry_run: true,
          cells: cells.length,
          defects: defects.length,
          evidence: inventory.length,
          harness_failures: harnessFailures.length,
        },
        null,
        2
      )
    );
    return { cells, defects, artifactManifest };
  }

  writeJson(OUTPUTS.cells, cells);
  writeText(OUTPUTS.defects, defects.map((defect) => JSON.stringify(defect)).join("\n") + (defects.length ? "\n" : ""));
  writeJson(OUTPUTS.manifest, artifactManifest);
  writeText(OUTPUTS.markdown, markdownSummary(cells, defects, artifactManifest));

  console.log(`[baseline-artifacts] Wrote ${relativeFromRepo(OUTPUTS.cells)} (${cells.length} rows)`);
  console.log(`[baseline-artifacts] Wrote ${relativeFromRepo(OUTPUTS.defects)} (${defects.length} rows)`);
  console.log(`[baseline-artifacts] Wrote ${relativeFromRepo(OUTPUTS.manifest)}`);
  console.log(`[baseline-artifacts] Wrote ${relativeFromRepo(OUTPUTS.markdown)}`);

  return { cells, defects, artifactManifest };
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  try {
    main();
  } catch (error) {
    console.error(`[baseline-artifacts] ${error.stack || error.message}`);
    process.exit(1);
  }
}
