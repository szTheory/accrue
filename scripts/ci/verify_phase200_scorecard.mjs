import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE200_DIR = ".planning/phases/200-idempotent-verification-sign-off";
const EXPECTED_UNION_COUNT = 30348;

const DEFAULT_INPUTS = {
  baselinePath: path.join(REPO_ROOT, PHASE200_DIR, "baseline.union.cells.json"),
  finalCellsPath: path.join(REPO_ROOT, PHASE200_DIR, "final.cells.json"),
  deltaPath: path.join(REPO_ROOT, PHASE200_DIR, "scorecard.delta.json"),
  regressionsPath: path.join(REPO_ROOT, PHASE200_DIR, "regressions.ndjson"),
  manifestPath: path.join(REPO_ROOT, PHASE200_DIR, "artifacts.manifest.json"),
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

const ALLOWED_ARTIFACT_ROOTS = [
  "accrue_admin/test-results/",
  "accrue_admin/playwright-report/",
  `${PHASE200_DIR}/`,
];

function readFile(filePath, failures, label) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    failures.missingFiles.push(`${label}: unable to read ${filePath}: ${error.message}`);
    return null;
  }
}

function readJson(filePath, failures, label) {
  const body = readFile(filePath, failures, label);
  if (body === null) return null;
  try {
    return JSON.parse(body);
  } catch (error) {
    failures.malformedJson.push(`${label}: malformed JSON in ${filePath}: ${error.message}`);
    return null;
  }
}

function readNdjson(filePath, failures, label) {
  const body = readFile(filePath, failures, label);
  if (body === null) return [];
  const rows = [];
  body.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try {
      rows.push(JSON.parse(line));
    } catch (error) {
      failures.malformedJson.push(`${label}: malformed NDJSON in ${filePath}:${index + 1}: ${error.message}`);
    }
  });
  return rows;
}

function asArray(value, label, failures) {
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.cells)) return value.cells;
  if (value && Array.isArray(value.rows)) return value.rows;
  failures.malformedRows.push(`${label} must be an array or contain an array at .cells/.rows.`);
  return [];
}

function evidenceRefs(row) {
  return Array.from(
    new Set(
      [
        ...(Array.isArray(row?.evidence_refs) ? row.evidence_refs : []),
        ...(Array.isArray(row?.evidenceRefs) ? row.evidenceRefs : []),
        row?.evidence_ref,
        row?.evidenceRef,
      ]
        .filter(Boolean)
        .map(String)
    )
  );
}

function normalizedLens(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/_/g, "-");
}

function rowLenses(row) {
  return Array.from(
    new Set(
      [
        ...(Array.isArray(row?.evidence_lenses) ? row.evidence_lenses : []),
        ...(Array.isArray(row?.validation_lenses) ? row.validation_lenses : []),
        ...(Array.isArray(row?.lenses) ? row.lenses : []),
        row?.lens,
        row?.validation_lens,
      ]
        .filter(Boolean)
        .map(normalizedLens)
    )
  );
}

function idDimension(cellId) {
  const match = String(cellId || "").match(/__d([0-9]{2})(?:__|$)/);
  return match ? Number(match[1]) : null;
}

function validCellGrammar(cell) {
  const id = String(cell?.cell_id || "");
  if (!/^p(187|193)__.+__d(0[1-9]|1[0-2])(?:__.+)?$/.test(id)) return false;
  return idDimension(id) === Number(cell?.dimension);
}

function scoreValue(value) {
  if (value === null || value === undefined) return null;
  const number = Number(value);
  return Number.isInteger(number) && number >= 0 && number <= 3 ? number : Number.NaN;
}

function formatCell(cell) {
  return `${cell?.cell_id || "(missing cell_id)"} ${cell?.dimension_name || "(missing dimension)"}`;
}

function validateCellShape(cell, failures, label) {
  const required = [
    "cell_id",
    "surface",
    "surface_type",
    "mode",
    "viewport_width",
    "theme",
    "state",
    "dimension",
    "dimension_name",
    "score",
    "coverage_status",
    "evidence_refs",
    "notes",
  ];

  for (const field of required) {
    if (!(field in cell)) failures.malformedRows.push(`${label}: ${formatCell(cell)} missing ${field}.`);
  }

  const dimension = Number(cell.dimension);
  if (!DIMENSIONS.has(dimension) || cell.dimension_name !== DIMENSIONS.get(dimension)) {
    failures.malformedRows.push(`${label}: ${formatCell(cell)} has invalid dimension mapping.`);
  }
  if (!validCellGrammar(cell)) {
    failures.malformedRows.push(`${label}: ${formatCell(cell)} violates p187/p193 cell grammar.`);
  }
  if (!COVERAGE_RANK.has(cell.coverage_status)) {
    failures.malformedRows.push(`${label}: ${formatCell(cell)} has invalid coverage_status.`);
  }
  if (Number.isNaN(scoreValue(cell.score))) {
    failures.malformedRows.push(`${label}: ${formatCell(cell)} has invalid score; expected 0, 1, 2, 3, or null.`);
  }
  if (!Array.isArray(cell.evidence_refs)) {
    failures.malformedRows.push(`${label}: ${formatCell(cell)} evidence_refs must be an array.`);
  }
}

function validateUniqueCellIds(rows, label, failures) {
  const seen = new Set();
  const duplicates = new Set();
  for (const row of rows) {
    if (!row?.cell_id) continue;
    if (seen.has(row.cell_id)) duplicates.add(row.cell_id);
    seen.add(row.cell_id);
  }
  for (const cellId of duplicates) {
    failures.duplicateCellIds.push(`${label}: duplicate cell_id ${cellId}.`);
  }
}

function validArtifactRef(ref) {
  const value = String(ref || "");
  if (value.startsWith("playwright-trace:")) return true;
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return ALLOWED_ARTIFACT_ROOTS.some((root) => value.startsWith(root));
}

function validateArtifactRef(ref, label, failures) {
  if (!validArtifactRef(ref)) {
    failures.badArtifactRefs.push(`${label}: invalid artifact ref "${ref}" (repo-relative generated roots only).`);
  }
}

function validateChecksum(row, label, failures) {
  const checksum = row.sha256 || row.checksum || row.digest;
  if (!checksum) return;
  const value = String(checksum).replace(/^sha256:/, "");
  if (!/^[a-f0-9]{64}$/i.test(value)) {
    failures.badArtifactRefs.push(`${label}: ${artifactRef(row) || row.id || "(unknown artifact)"} has invalid SHA-256 checksum.`);
  }
}

function manifestEntries(manifest) {
  if (Array.isArray(manifest)) return manifest;
  if (manifest && Array.isArray(manifest.artifacts)) return manifest.artifacts;
  if (manifest && Array.isArray(manifest.evidence)) return manifest.evidence;
  if (manifest && Array.isArray(manifest.files)) return manifest.files;
  if (manifest && typeof manifest === "object") {
    return Object.entries(manifest)
      .filter(([, value]) => value && typeof value === "object")
      .map(([key, value]) => ({ id: key, ...value }));
  }
  return [];
}

function artifactRef(row) {
  return row.path || row.ref || row.evidence_ref || row.evidenceRef || row.artifact || row.href;
}

function validateManifest(manifestPath, failures) {
  const manifest = readJson(manifestPath, failures, "artifacts.manifest.json");
  const entries = manifest ? manifestEntries(manifest) : [];
  const refs = new Set();

  if (entries.length === 0) {
    failures.manifest.push("artifacts.manifest.json must list at least one artifact/evidence entry.");
  }

  for (const entry of entries) {
    const ref = artifactRef(entry);
    if (!ref) {
      failures.manifest.push(`Manifest entry ${entry.id || "(without id)"} is missing path/ref/evidence_ref.`);
      continue;
    }
    validateArtifactRef(ref, "artifacts.manifest.json", failures);
    validateChecksum(entry, "artifacts.manifest.json", failures);
    refs.add(String(ref));
  }

  return { entries, refs };
}

function validateEvidence(row, label, failures, manifestRefs) {
  const refs = evidenceRefs(row);
  if (refs.length === 0) {
    failures.missingEvidence.push(`${label}: ${row.cell_id || row.id || "(row)"} lacks evidence refs.`);
    return;
  }

  for (const ref of refs) {
    validateArtifactRef(ref, label, failures);
    if (manifestRefs.size > 0 && !manifestRefs.has(ref)) {
      failures.unmanifestedEvidence.push(`${label}: ${row.cell_id || row.id || "(row)"} references ${ref} not present in artifacts.manifest.json.`);
    }
  }

  for (const lens of rowLenses(row)) {
    if (!ALLOWED_LENSES.has(lens)) {
      failures.malformedRows.push(`${label}: ${row.cell_id || row.id || "(row)"} uses unknown evidence lens "${lens}".`);
    }
  }
}

function compareFinalCells(baselineRows, finalRows, deltaRows, manifestRefs, failures) {
  const baselineById = new Map();
  for (const cell of baselineRows) {
    validateCellShape(cell, failures, "baseline.union.cells.json");
    if (cell.cell_id) baselineById.set(cell.cell_id, cell);
  }
  validateUniqueCellIds(baselineRows, "baseline.union.cells.json", failures);

  const finalById = new Map();
  for (const cell of finalRows) {
    validateCellShape(cell, failures, "final.cells.json");
    if (!cell.cell_id) continue;
    if (!baselineById.has(cell.cell_id)) {
      failures.invalidComparableCells.push(`${cell.cell_id} is not present in baseline.union.cells.json.`);
    }
    validateEvidence(cell, "final.cells.json", failures, manifestRefs);
    finalById.set(cell.cell_id, cell);
  }
  validateUniqueCellIds(finalRows, "final.cells.json", failures);

  for (const baseline of baselineRows) {
    const finalCell = finalById.get(baseline.cell_id);
    if (!finalCell) {
      failures.missingComparableCells.push(`${baseline.cell_id} missing from final.cells.json.`);
      continue;
    }

    const baselineScore = scoreValue(baseline.score);
    const finalScore = scoreValue(finalCell.score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) {
      failures.scoreDowngrades.push(`${baseline.cell_id}: final_score ${finalScore} below baseline_score ${baselineScore}.`);
    }

    const baselineCoverageRank = COVERAGE_RANK.get(baseline.coverage_status) ?? -99;
    const finalCoverageRank = COVERAGE_RANK.get(finalCell.coverage_status) ?? -99;
    if (finalCoverageRank < baselineCoverageRank) {
      failures.coverageDowngrades.push(
        `${baseline.cell_id}: coverage downgraded ${baseline.coverage_status} -> ${finalCell.coverage_status}.`
      );
    }

    if (String(baseline.cell_id).startsWith("p193__")) {
      if (finalCell.coverage_status !== "covered") {
        failures.p193Closure.push(`${baseline.cell_id}: p193 page-flow row must close as covered.`);
      }
      if (finalScore === null || finalScore < 2) {
        failures.p193Closure.push(`${baseline.cell_id}: p193 page-flow row must close with score >= 2.`);
      }
      if (evidenceRefs(finalCell).length === 0) {
        failures.p193Closure.push(`${baseline.cell_id}: p193 page-flow row must have deterministic evidence refs.`);
      }
    }
  }

  for (const row of deltaRows) {
    const kind = String(row.kind || row.type || row.reason || "").toLowerCase();
    if (/downgrade|regression|correction/.test(kind) || row.baseline_correction || row.regression) {
      validateEvidence(row, "scorecard.delta.json", failures, manifestRefs);
    }
  }
}

function failureTemplate() {
  return {
    missingFiles: [],
    malformedJson: [],
    malformedRows: [],
    duplicateCellIds: [],
    manifest: [],
    badArtifactRefs: [],
    unmanifestedEvidence: [],
    missingComparableCells: [],
    invalidComparableCells: [],
    scoreDowngrades: [],
    coverageDowngrades: [],
    missingEvidence: [],
    p193Closure: [],
    regressions: [],
  };
}

function failureCount(failures) {
  return Object.values(failures).reduce((sum, items) => sum + items.length, 0);
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

export function verifyPhase200Scorecard(options = {}) {
  const paths = { ...DEFAULT_INPUTS, ...options };
  const failures = failureTemplate();
  const expectedBaselineCount = options.expectedBaselineCount ?? EXPECTED_UNION_COUNT;

  const baselineRows = asArray(readJson(paths.baselinePath, failures, "baseline.union.cells.json"), "baseline.union.cells.json", failures);
  for (const cell of baselineRows) validateCellShape(cell, failures, "baseline.union.cells.json");
  validateUniqueCellIds(baselineRows, "baseline.union.cells.json", failures);

  if (expectedBaselineCount !== null && baselineRows.length !== expectedBaselineCount) {
    failures.malformedRows.push(`baseline.union.cells.json expected ${expectedBaselineCount} rows, found ${baselineRows.length}.`);
  }

  if (options.baselineOnly) {
    return {
      ok: failureCount(failures) === 0,
      summary: { baseline_cells: baselineRows.length, baseline_only: true },
      failures,
    };
  }

  const manifestResult = validateManifest(paths.manifestPath, failures);
  const manifestRefs = manifestResult.refs;
  const finalRows = asArray(readJson(paths.finalCellsPath, failures, "final.cells.json"), "final.cells.json", failures);
  const deltaRows = asArray(readJson(paths.deltaPath, failures, "scorecard.delta.json"), "scorecard.delta.json", failures);
  const regressions = readNdjson(paths.regressionsPath, failures, "regressions.ndjson");

  if (regressions.length > 0) {
    for (const row of regressions) {
      failures.regressions.push(`${row.id || row.cell_id || "(regression row)"} blocks sign-off; regressions.ndjson must be empty.`);
      validateEvidence(row, "regressions.ndjson", failures, manifestRefs);
    }
  }

  compareFinalCells(baselineRows, finalRows, deltaRows, manifestRefs, failures);

  return {
    ok: failureCount(failures) === 0,
    summary: {
      baseline_cells: baselineRows.length,
      final_cells: finalRows.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      manifest_entries: manifestResult.entries.length,
      baseline_only: false,
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
    notes: "Fixture row proves deterministic interaction evidence.",
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

function fixturePackage(root, overrides = {}) {
  const componentRef = "accrue_admin/test-results/phase200/fixture-component.json";
  const pageFlowRef = "accrue_admin/test-results/phase200/page-flow-evidence.json";
  const baseline = overrides.baseline || [fixtureCell(), fixtureP193()];
  const final =
    overrides.final ||
    [
      fixtureCell({ score: 3 }),
      fixtureP193({
        score: 2,
        coverage_status: "covered",
        evidence_refs: [pageFlowRef],
        evidence_lenses: ["page-flow", "interaction-trace"],
      }),
    ];
  const delta =
    overrides.delta ||
    final.map((cell) => ({
      cell_id: cell.cell_id,
      baseline_score: baseline.find((row) => row.cell_id === cell.cell_id)?.score ?? null,
      final_score: cell.score,
      kind: "passing-delta",
      evidence_refs: cell.evidence_refs,
      evidence_lenses: cell.evidence_lenses,
    }));
  const regressions = overrides.regressions || "";
  const manifest = overrides.manifest || {
    evidence: [
      { path: componentRef, sha256: "a".repeat(64), bytes: 42 },
      { path: pageFlowRef, sha256: "b".repeat(64), bytes: 42 },
      { path: `${PHASE200_DIR}/baseline.union.cells.json`, generated: true },
      { path: `${PHASE200_DIR}/final.cells.json`, generated: true },
      { path: `${PHASE200_DIR}/scorecard.delta.json`, generated: true },
      { path: `${PHASE200_DIR}/regressions.ndjson`, generated: true },
      { path: `${PHASE200_DIR}/artifacts.manifest.json`, generated: true },
    ],
  };

  writeJson(path.join(root, "baseline.union.cells.json"), baseline);
  writeJson(path.join(root, "final.cells.json"), final);
  writeJson(path.join(root, "scorecard.delta.json"), delta);
  writeText(path.join(root, "regressions.ndjson"), regressions);
  writeJson(path.join(root, "artifacts.manifest.json"), manifest);

  return {
    baselinePath: path.join(root, "baseline.union.cells.json"),
    finalCellsPath: path.join(root, "final.cells.json"),
    deltaPath: path.join(root, "scorecard.delta.json"),
    regressionsPath: path.join(root, "regressions.ndjson"),
    manifestPath: path.join(root, "artifacts.manifest.json"),
    expectedBaselineCount: baseline.length,
  };
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase200-scorecard-verifier-"));
  try {
    const positive = verifyPhase200Scorecard(fixturePackage(path.join(root, "positive")));
    assertSelfTest("valid passing artifacts exit zero", positive.ok, JSON.stringify(positive.failures));

    const baselineOnly = verifyPhase200Scorecard({
      ...fixturePackage(path.join(root, "baseline-only")),
      baselineOnly: true,
    });
    assertSelfTest("--baseline-only validates union baseline shape and count", baselineOnly.ok);

    const nonEmptyRegression = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "regression"), {
        regressions: `${JSON.stringify({
          id: "P200-REG-001",
          cell_id: fixtureCell().cell_id,
          kind: "score-downgrade",
          evidence_refs: ["accrue_admin/test-results/phase200/fixture-component.json"],
          evidence_lenses: ["correctness"],
        })}\n`,
      })
    );
    assertSelfTest("non-empty regressions.ndjson exits non-zero", !nonEmptyRegression.ok);
    assertSelfTest("regressions section is reported", nonEmptyRegression.failures.regressions.length > 0);

    const missingEvidence = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "missing-evidence"), {
        final: [fixtureCell({ evidence_refs: [] }), fixtureP193({ score: 2, coverage_status: "covered", evidence_refs: [] })],
      })
    );
    assertSelfTest("missing evidence exits non-zero", !missingEvidence.ok);
    assertSelfTest("missing evidence section is reported", missingEvidence.failures.missingEvidence.length > 0);

    const badManifest = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "bad-manifest"), {
        manifest: {
          evidence: [
            { path: "../secret.json", sha256: "not-a-sha" },
            { path: "accrue_admin/test-results/phase200/fixture-component.json", sha256: "a".repeat(64) },
          ],
        },
      })
    );
    assertSelfTest("bad manifest refs exit non-zero", !badManifest.ok);
    assertSelfTest("bad artifact refs are reported", badManifest.failures.badArtifactRefs.length > 0);

    const unmanifested = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "unmanifested"), {
        manifest: { evidence: [{ path: "accrue_admin/test-results/phase200/fixture-component.json", sha256: "a".repeat(64) }] },
      })
    );
    assertSelfTest("unmanifested evidence refs exit non-zero", !unmanifested.ok);
    assertSelfTest("unmanifested evidence section is reported", unmanifested.failures.unmanifestedEvidence.length > 0);

    const staleP193 = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "stale-p193"), {
        final: [fixtureCell({ score: 3 }), fixtureP193()],
      })
    );
    assertSelfTest("stale pending p193 rows exit non-zero", !staleP193.ok);
    assertSelfTest("p193 closure section is reported", staleP193.failures.p193Closure.length > 0);

    const malformedPaths = fixturePackage(path.join(root, "malformed-json"));
    writeText(malformedPaths.finalCellsPath, "{not-json");
    const malformed = verifyPhase200Scorecard(malformedPaths);
    assertSelfTest("malformed JSON exits non-zero", !malformed.ok);
    assertSelfTest("malformed JSON section is reported", malformed.failures.malformedJson.length > 0);

    const duplicate = verifyPhase200Scorecard(
      fixturePackage(path.join(root, "duplicate"), {
        baseline: [fixtureCell(), fixtureCell()],
        final: [fixtureCell({ score: 3 }), fixtureCell({ score: 3 })],
      })
    );
    assertSelfTest("duplicate cell IDs exit non-zero", !duplicate.ok);
    assertSelfTest("duplicate cell ID section is reported", duplicate.failures.duplicateCellIds.length > 0);

    console.log("Phase 200 scorecard verifier self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--baseline-only") options.baselineOnly = true;
    else if (arg === "--baseline" || arg === "--baseline-union") options.baselinePath = path.resolve(argv[++index]);
    else if (arg === "--final-cells") options.finalCellsPath = path.resolve(argv[++index]);
    else if (arg === "--delta") options.deltaPath = path.resolve(argv[++index]);
    else if (arg === "--regressions") options.regressionsPath = path.resolve(argv[++index]);
    else if (arg === "--manifest-path") options.manifestPath = path.resolve(argv[++index]);
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

  const result = verifyPhase200Scorecard(options);
  console.log(
    `Phase 200 scorecard verifier: baseline=${result.summary.baseline_cells || 0}, final=${
      result.summary.final_cells || 0
    }, delta=${result.summary.delta_rows || 0}, regressions=${result.summary.regression_rows || 0}, manifest=${
      result.summary.manifest_entries || 0
    }${options.baselineOnly ? " (baseline-only)" : ""}`
  );

  if (!result.ok) {
    reportFailures("Phase 200 scorecard verification failed.", result.failures);
    process.exitCode = 1;
  } else {
    console.log("Phase 200 scorecard verification passed.");
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 200 scorecard verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
