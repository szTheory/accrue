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

function slug(value) {
  return String(value || "unknown")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function evidenceRefFromStatusPath(value) {
  if (!value) return null;
  const normalized = String(value).split(path.sep).join("/");
  if (normalized.startsWith("accrue_admin/test-results/")) return normalized;
  if (normalized.startsWith("test-results/")) return `accrue_admin/${normalized}`;
  return normalized;
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
    .filter((absPath) => path.basename(absPath) !== ".DS_Store")
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

function projectNameForEvidence(evidenceRef) {
  const match = evidenceRef.match(/admin-(?:baseline|interactions)\/([^/]+)/);
  return match ? match[1] : "chromium-desktop";
}

function isInteractionRow(row) {
  return Boolean(row && row.interaction_class && row.rubric_dimension);
}

function validState(value) {
  const state = String(value || "interactive-open");
  return [
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
  ].includes(state)
    ? state
    : "interactive-open";
}

function interactionEvidenceRefs(row, evidenceRef) {
  return Array.from(new Set([...(row.evidence_refs || []), evidenceRef].filter(Boolean)));
}

function interactionCellFromRow(row, evidenceRef) {
  const project = projectForMode(projectNameForEvidence(evidenceRef));
  const dimension = dimensionFor(row.rubric_dimension) || dimensionFor("interaction-integrity");
  const state = validState(row.state);
  const coverage = ["covered", "gap", "n/a"].includes(row.coverage_status)
    ? row.coverage_status
    : "covered";
  const probeId = row.probe_id || slug(row.interaction_class);

  return {
    cell_id: `p187__ixn__${slug(row.surface || row.interaction_class)}__${project.name}__${slug(state)}__d${String(dimension.id).padStart(2, "0")}__${slug(probeId)}`,
    surface: row.surface || row.interaction_class,
    surface_type: ["component", "component-group", "page-flow"].includes(row.surface_type)
      ? row.surface_type
      : "page-flow",
    mode: project.mode,
    viewport_width: project.viewport_width,
    theme: "light",
    state,
    dimension: dimension.id,
    dimension_name: dimension.name,
    score: null,
    coverage_status: coverage,
    evidence_refs: interactionEvidenceRefs(row, evidenceRef),
    notes: row.notes || row.failure_kind || row.actual || "Imported from live interaction observation.",
  };
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

function baselineCellContract(cell) {
  const contracted = {
    cell_id: cell.cell_id,
    surface: cell.surface,
    surface_type: cell.surface_type,
    mode: cell.mode,
    viewport_width: Number(cell.viewport_width),
    theme: cell.theme,
    state: cell.state,
    dimension: Number(cell.dimension),
    dimension_name: cell.dimension_name,
    score: cell.score ?? null,
    coverage_status: cell.coverage_status,
    evidence_refs: Array.from(new Set(cell.evidence_refs || [])),
    notes: cell.notes || cell.reason || "",
  };

  if (cell.mode === "targeted") {
    contracted.targeted_label = cell.targeted_label;
    contracted.breakpoint = Number(cell.breakpoint);
  } else {
    contracted.targeted_label = cell.targeted_label ?? null;
    contracted.breakpoint = cell.breakpoint ?? null;
  }

  return contracted;
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
      if (isInteractionRow(row)) {
        const interactionCell = interactionCellFromRow(row, evidence_ref);
        byId.set(interactionCell.cell_id, interactionCell);
        continue;
      }

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
        notes:
          normalized.notes ||
          normalized.reason ||
          normalized.failure_kind ||
          normalized.defect_candidate ||
          "Imported from raw Phase 187 baseline evidence.",
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

  return Array.from(byId.values())
    .map(baselineCellContract)
    .sort((a, b) => a.cell_id.localeCompare(b.cell_id));
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

function severityForGap(cell) {
  const text = [
    cell.reason,
    cell.notes,
    cell.defect_candidate,
    cell.failure_kind,
    cell.dimension_name,
    cell.state,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (/intercepted|focus-escaped|escape-not-dismissed|missing-dismissal|permission|disconnected/.test(text)) {
    return "high";
  }
  if (/missing-selector|fixture-gap|state-fixture-gap|not forced|unreachable|loading|error/.test(text)) {
    return "medium";
  }
  return "low";
}

function normalizeDimensionName(value) {
  const dimension = dimensionFor(value);
  return dimension ? dimension.name : "state-coverage";
}

function defectFromFinding(finding, evidenceRef) {
  const surface = surfaceForName(finding.screen || finding.surface);
  const project = projectForMode(finding.viewport || finding.mode || "chromium-desktop");
  const dimension = dimensionFor(finding.dimension ?? finding.dimension_name);
  if (!surface || !project || !dimension || typeof finding.score !== "number" || finding.score >= 2) {
    return null;
  }

  const theme = finding.theme || "light";
  return {
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

function defectFromGapCell(cell) {
  if (cell.coverage_status !== "gap") return null;

  const surface = surfaceForName(cell.surface);
  if (!surface) return null;

  const reason = cell.reason || cell.notes || cell.failure_kind || "Baseline gap was recorded by Phase 187 evidence.";
  const dimensionName = normalizeDimensionName(cell.dimension ?? cell.dimension_name);
  return {
    severity: severityForGap({ ...cell, dimension_name: dimensionName }),
    surface: surface.surface,
    surface_type: surface.surface_type,
    persona_job: surface.persona_job,
    reproduction: `Inspect ${cell.evidence_refs?.[0] || "the Phase 187 baseline evidence"} for ${surface.surface} (${cell.mode}/${cell.theme}/${cell.state}).`,
    expected: `${surface.surface} has covered evidence or an explicit remediation path for ${dimensionName} in ${cell.state}.`,
    actual: reason,
    rubric_dimension: dimensionName,
    overlay_tags: Array.from(new Set([...(cell.overlay_tags || []), ...overlayTagsForFinding(cell)])),
    cell_id: cell.cell_id,
    evidence_refs: Array.from(new Set(cell.evidence_refs?.length ? cell.evidence_refs : ["accrue_admin/test-results/phase187-command-status.json"])),
    owner_phase: String(cell.owner_phase || surface.owner_phase),
    status: "gap",
    notes: cell.defect_candidate || cell.failure_kind || "",
  };
}

function severityForInteraction(row) {
  const text = [
    row.failure_kind,
    row.actual,
    row.expected,
    row.interaction_class,
    ...(row.overlay_tags || []),
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (/intercepted|focus-escaped|escape-not-dismissed|missing-dismissal|permission|disconnected|actionability|layer/.test(text)) {
    return "high";
  }
  if (/missing-selector|fixture-gap|loading|error|empty|scroll|overflow/.test(text)) {
    return "medium";
  }
  return "low";
}

function defectFromInteractionRow(row, evidenceRef) {
  const coverage = ["covered", "gap", "n/a"].includes(row.coverage_status)
    ? row.coverage_status
    : "covered";
  const hasFailure = Boolean(row.failure_kind);
  const hasGap = coverage === "gap";
  if (!hasFailure && !hasGap) return null;

  const cell = interactionCellFromRow(row, evidenceRef);
  const dimension = dimensionFor(row.rubric_dimension) || dimensionFor("interaction-integrity");
  return {
    severity: severityForInteraction(row),
    surface: row.surface || row.interaction_class,
    surface_type: cell.surface_type,
    persona_job: "Verify live admin interaction behavior under real browser actionability, focus, scroll, and state conditions.",
    reproduction: `Run npm run e2e -- e2e/admin-interactions.spec.js and inspect ${evidenceRef} row ${row.probe_id || row.interaction_class}.`,
    expected: row.expected || `${row.interaction_class} satisfies the Phase 187 live interaction contract.`,
    actual: row.actual || row.failure_kind || "Live interaction probe recorded a gap.",
    rubric_dimension: dimension.name,
    overlay_tags: Array.from(new Set(row.overlay_tags || [])),
    cell_id: cell.cell_id,
    evidence_refs: interactionEvidenceRefs(row, evidenceRef),
    owner_phase: "191",
    status: "gap",
    notes: [row.failure_kind, row.notes].filter(Boolean).join(" "),
  };
}

function defectsFromInteractions(rawRows) {
  return rawRows
    .filter(({ row }) => isInteractionRow(row))
    .map(({ row, evidence_ref }) => defectFromInteractionRow(row, evidence_ref));
}

function representativeDefectsFromCells(cells) {
  const byKey = new Map();

  for (const cell of cells) {
    const defect = defectFromGapCell(cell);
    if (!defect) continue;

    const key = [
      defect.surface_type,
      defect.rubric_dimension,
      cell.state,
      cell.mode,
      defect.actual,
      defect.owner_phase,
    ].join("|");

    const existing = byKey.get(key);
    if (!existing) {
      byKey.set(key, { defect, count: 1 });
      continue;
    }

    existing.count += 1;
    existing.defect.evidence_refs = Array.from(
      new Set([...existing.defect.evidence_refs, ...defect.evidence_refs])
    ).slice(0, 8);
    if (!existing.defect.notes.includes("Representative surface:")) {
      existing.defect.notes = [existing.defect.notes, `Representative surface: ${existing.defect.surface}.`]
        .filter(Boolean)
        .join(" ");
    }
  }

  return Array.from(byKey.values()).map(({ defect, count }) => ({
    ...defect,
    notes: [defect.notes, count > 1 ? `Represents ${count} baseline cells with the same surface/dimension/state gap.` : ""]
      .filter(Boolean)
      .join(" "),
  }));
}

function evidenceRefsForCommand(status, name) {
  const refs = [];
  const roots = Array.isArray(status.evidence_roots) ? status.evidence_roots : [];
  for (const root of roots) {
    const absRoot = path.join(adminRoot, root.replace(/^accrue_admin\//, ""));
    if (fs.existsSync(absRoot)) {
      for (const file of listFiles(absRoot)) refs.push(assertEvidencePath(file));
    }
  }

  const logPath = status.log_path || status.stderr_log_path || status.stdout_log_path;
  if (logPath) {
    const absLog = path.join(adminRoot, logPath.replace(/^accrue_admin\//, ""));
    if (fs.existsSync(absLog)) refs.push(assertEvidencePath(absLog));
  }

  for (const file of listFiles(testResultsRoot)) {
    const rel = assertEvidencePath(file);
    if (rel.includes(`/${name}`) || rel.includes(`${name}-`)) refs.push(rel);
  }

  return Array.from(new Set(refs)).sort();
}

function defectFromCommandStatus(status, evidenceRefs) {
  const name = status.name || status.command || "unknown producer";
  const dimension = name.includes("a11y") ? "focus-semantics" : "state-coverage";
  return {
    severity: name.includes("a11y") ? "high" : "medium",
    surface: `${name} producer`,
    surface_type: "page-flow",
    persona_job: "Produce Phase 187 audit evidence without hiding collection failures.",
    reproduction: `Run producer command "${name}" from the Phase 187 non-aborting audit wrapper.`,
    expected: "Producer either exits cleanly or records parseable evidence that the baseline generator can route.",
    actual: status.error || status.message || `Producer exited ${Number(status.exit_code ?? status.exitCode ?? status.status ?? 0)} with trace/log evidence.`,
    rubric_dimension: dimension,
    overlay_tags: name.includes("a11y") ? ["focus-trap", "actionability"] : [],
    cell_id: `phase187__${name}__producer-status`,
    evidence_refs: evidenceRefs.length ? evidenceRefs.slice(0, 8) : ["accrue_admin/test-results/phase187-command-status.json"],
    owner_phase: "191",
    status: "gap",
    notes: "Producer failure preserved as audit evidence; it does not block artifact generation because trace/log evidence exists.",
  };
}

function visionScoringUnavailableDefect() {
  const evidenceRefs = [
    "accrue_admin/test-results/phase187-command-status.json",
    "accrue_admin/test-results/phase187-logs/score-visuals.log",
    "accrue_admin/test-results/admin-visuals/findings.ndjson",
  ];

  return {
    severity: "high",
    surface: "score-visuals producer",
    surface_type: "page-flow",
    persona_job: "Produce Phase 187 visual rubric evidence for only-forward comparison.",
    reproduction: "Run `ANTHROPIC_API_KEY=... npm run score-visuals` before `npm run baseline:artifacts`.",
    expected: "Every captured visual screenshot has 12 scored rubric dimensions, or the missing scorer is routed as an explicit baseline defect.",
    actual: "Vision scoring was unavailable, so screenshots are present but rubric score findings are absent.",
    rubric_dimension: "state-coverage",
    overlay_tags: [],
    cell_id: "phase187__score-visuals__producer-status",
    evidence_refs: evidenceRefs,
    owner_phase: "191",
    status: "gap",
    notes: "No ANTHROPIC_API_KEY path is non-blocking by plan, but remains a routeable baseline gap.",
  };
}

function sortAndNumberDefects(defects) {
  const rank = { critical: 0, high: 1, medium: 2, low: 3 };
  return defects
    .filter(Boolean)
    .sort((a, b) => {
      const bySeverity = (rank[a.severity] ?? 99) - (rank[b.severity] ?? 99);
      if (bySeverity !== 0) return bySeverity;
      const byOwner = String(a.owner_phase).localeCompare(String(b.owner_phase));
      if (byOwner !== 0) return byOwner;
      return String(a.surface).localeCompare(String(b.surface));
    })
    .map((defect, index) => ({
      ...defect,
      id: `AX187-${String(index + 1).padStart(3, "0")}`,
      overlay_tags: Array.from(new Set(defect.overlay_tags || [])),
      evidence_refs: Array.from(new Set(defect.evidence_refs || [])),
      owner_phase: String(defect.owner_phase),
    }));
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

function classifyCommandStatus(rawRows, findings, harnessFailures, observations, commandDefects) {
  if (!fs.existsSync(INPUTS.commandStatus)) {
    harnessFailures.push({
      kind: "harness-error",
      evidence_ref: "accrue_admin/test-results/phase187-command-status.json",
      message: "Command status file is missing; run the Phase 187 non-aborting audit wrapper.",
    });
    return;
  }

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

    const evidenceRefs = evidenceRefsForCommand(status, name);
    const parseableEvidence = rawRows.length > 0 || findings.length > 0 || evidenceRefs.length > 0;
    if (parseableEvidence && !status.crashed && !status.parser_error) {
      observations.push({
        kind: "defects-found",
        producer: name,
        exit_code: exitCode,
        evidence_ref: evidenceRef,
        evidence_refs: evidenceRefs,
      });
      commandDefects.push(defectFromCommandStatus(status, evidenceRefs));
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

function readCommandStatuses() {
  if (!fs.existsSync(INPUTS.commandStatus)) return [];

  const parsed = readJsonFile(INPUTS.commandStatus);
  if (!parsed.ok) return [];

  const statuses = Array.isArray(parsed.value) ? parsed.value : parsed.value.commands || [parsed.value];
  return statuses.map((status) => {
    const command = status.name || status.command || "unknown producer";
    const exitCode = Number(status.exit_code ?? status.exitCode ?? status.status ?? 0);
    const evidenceRefs = evidenceRefsForCommand(status, command);
    return {
      command,
      exit_code: exitCode,
      status: exitCode === 0 ? "passed" : "failed",
      started_at: status.started_at || status.startedAt || null,
      finished_at: status.finished_at || status.finishedAt || null,
      log_ref: evidenceRefFromStatusPath(status.log_path || status.stderr_log_path || status.stdout_log_path),
      evidence_refs: evidenceRefs,
    };
  });
}

function writeJson(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, `${JSON.stringify(value, null, 2)}\n`);
}

function writeText(absPath, value) {
  fs.mkdirSync(path.dirname(absPath), { recursive: true });
  fs.writeFileSync(absPath, value);
}

function countBy(items, keyFn) {
  const counts = new Map();
  for (const item of items) {
    const key = keyFn(item) ?? "unknown";
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  return Array.from(counts.entries()).sort((a, b) => String(a[0]).localeCompare(String(b[0])));
}

function markdownTable(rows, headers) {
  if (rows.length === 0) return "_None._\n";
  return [
    `| ${headers.join(" | ")} |`,
    `| ${headers.map(() => "---").join(" | ")} |`,
    ...rows.map((row) => `| ${row.join(" | ")} |`),
  ].join("\n") + "\n";
}

function markdownSummary(cells, defects, artifactManifest) {
  const covered = cells.filter((cell) => cell.coverage_status === "covered").length;
  const gaps = cells.filter((cell) => cell.coverage_status === "gap").length;
  const notApplicable = cells.filter((cell) => cell.coverage_status === "n/a").length;
  const coverageRows = countBy(cells, (cell) => cell.coverage_status);
  const surfaceRows = countBy(cells, (cell) => cell.surface_type);
  const modeRows = countBy(cells, (cell) =>
    cell.mode === "targeted" ? `${cell.mode}/${cell.targeted_label}` : cell.mode
  );
  const themeRows = countBy(cells, (cell) => cell.theme);
  const stateRows = countBy(cells, (cell) => cell.state);
  const ownerRows = countBy(defects, (defect) => defect.owner_phase);
  const severityRows = countBy(defects, (defect) => defect.severity);
  const topDefects = defects.slice(0, 40).map((defect) => [
    defect.id,
    defect.severity,
    defect.owner_phase,
    defect.surface,
    defect.rubric_dimension,
    defect.actual.replace(/\|/g, "/").slice(0, 120),
  ]);

  return `# Phase 187 Baseline

Only-forward baseline for v1.53 Admin UI Design-System Hardening.

Structured artifacts are canonical for Phase 187 and Phase 192 comparison:
baseline.cells.json and defects.ndjson are canonical. If this markdown disagrees
with those files, regenerate the markdown from the structured artifacts.

## Artifact Counts

- Baseline cells: ${cells.length}
- Covered cells: ${covered}
- Gap cells: ${gaps}
- N/A cells: ${notApplicable}
- Defects: ${defects.length}
- Evidence files referenced: ${artifactManifest.evidence.length}
- Harness failures: ${artifactManifest.harness_failures.length}

## Coverage Summary

### By Coverage Status

${markdownTable(coverageRows.map(([key, count]) => [key, count]), ["Status", "Cells"])}
### By Surface Type

${markdownTable(surfaceRows.map(([key, count]) => [key, count]), ["Surface type", "Cells"])}
### By Mode / Targeted Label

${markdownTable(modeRows.map(([key, count]) => [key, count]), ["Mode", "Cells"])}
### By Theme

${markdownTable(themeRows.map(([key, count]) => [key, count]), ["Theme", "Cells"])}
### By State

${markdownTable(stateRows.map(([key, count]) => [key, count]), ["State", "Cells"])}
## Severity-Ranked Defect Ledger

### By Severity

${markdownTable(severityRows.map(([key, count]) => [key, count]), ["Severity", "Defects"])}
### By Owner Phase

${markdownTable(ownerRows.map(([key, count]) => [key, count]), ["Owner phase", "Defects"])}
### Top Defects

${markdownTable(topDefects, ["ID", "Severity", "Owner", "Surface", "Dimension", "Actual"])}
## Outputs

- \`baseline.cells.json\` - schema-shaped baseline matrix cells
- \`defects.ndjson\` - severity-ranked defect ledger rows
- \`artifacts.manifest.json\` - evidence references, checksums, observations, and harness failures

## Phase 192 Rerun Commands

\`\`\`bash
cd accrue_admin
npm run e2e -- e2e/admin-baseline.spec.js
npm run e2e -- e2e/admin-interactions.spec.js
npm run e2e:a11y
npm run score-visuals
npm run baseline:artifacts
npm run baseline:parse
\`\`\`

Generated by \`npm run baseline:artifacts\`.
`;
}

export function main() {
  const harnessFailures = [];
  const observations = [];
  const commandDefects = [];
  const inventory = evidenceInventory();
  const { rawRows, findings } = collectRawEvidence(harnessFailures);
  classifyCommandStatus(rawRows, findings, harnessFailures, observations, commandDefects);

  if (!fs.existsSync(INPUTS.findings)) {
    observations.push({
      kind: "vision-scoring-unavailable",
      evidence_ref: "accrue_admin/test-results/admin-visuals/findings.ndjson",
      message: "Vision findings are unavailable; score-visuals skipped or produced no findings. This is a baseline gap unless credentials are available.",
    });
    commandDefects.push(visionScoringUnavailableDefect());
  }

  const cells = buildBaselineCells(inventory, rawRows, harnessFailures);
  const defects = sortAndNumberDefects([
    ...findings.map(({ row, evidence_ref }) => defectFromFinding(row, evidence_ref)),
    ...defectsFromInteractions(rawRows),
    ...representativeDefectsFromCells(cells),
    ...commandDefects,
  ]);
  const commandStatuses = readCommandStatuses();

  const artifactManifest = {
    generated_at: new Date().toISOString(),
    phase: "187-audit-baseline",
    outputs: Object.fromEntries(
      Object.entries(OUTPUTS).map(([key, absPath]) => [key, relativeFromRepo(absPath)])
    ),
    evidence: inventory,
    command_statuses: commandStatuses,
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
          command_statuses: commandStatuses.length,
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
