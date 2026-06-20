import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";

const DEFAULT_INPUTS = {
  baselinePath: path.join(REPO_ROOT, ".planning/phases/187-audit-baseline/baseline.cells.json"),
  finalCellsPath: path.join(REPO_ROOT, PHASE192_DIR, "final.cells.json"),
  deltaPath: path.join(REPO_ROOT, PHASE192_DIR, "scorecard.delta.json"),
  regressionsPath: path.join(REPO_ROOT, PHASE192_DIR, "regressions.ndjson"),
  manifestPath: path.join(REPO_ROOT, PHASE192_DIR, "artifacts.manifest.json"),
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

const VISUAL_ONLY_MARKERS = [
  "visual",
  "brand",
  "microcopy",
  "maintainer",
  "screenshot",
  "score-visuals",
  "model",
  "gallery",
];

const NON_VISUAL_MARKERS = [
  "axe",
  "a11y",
  "wcag",
  "trace",
  "interaction",
  "focus",
  "keyboard",
  "playwright",
  "group-contracts",
  "phase191",
  "reduced-motion",
  "component-lab",
  "baseline",
  "ci",
  "test-results",
];

const SENSITIVE_DIMENSIONS = new Set([
  "contrast",
  "focus-semantics",
  "motion",
  "interaction-integrity",
  "responsive-mobile-first",
  "state-coverage",
]);

const SENSITIVE_WORDS = [
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

const ALLOWED_ARTIFACT_ROOTS = [
  "accrue_admin/test-results/",
  "accrue_admin/playwright-report/",
  `${PHASE192_DIR}/`,
];

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch (error) {
    throw new Error(`Unable to read ${filePath}: ${error.message}`);
  }
}

function readJson(filePath) {
  try {
    return JSON.parse(readFile(filePath));
  } catch (error) {
    throw new Error(`Malformed JSON in ${filePath}: ${error.message}`);
  }
}

function readNdjson(filePath) {
  return readFile(filePath)
    .split(/\r?\n/)
    .filter((line) => line.trim().length > 0)
    .map((line, index) => {
      try {
        return JSON.parse(line);
      } catch (error) {
        throw new Error(`${filePath}:${index + 1}: ${error.message}`);
      }
    });
}

function asArray(value, label, failures) {
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.cells)) return value.cells;
  if (value && Array.isArray(value.rows)) return value.rows;
  failures.push(`${label} must be an array or contain an array at .cells/.rows.`);
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
  if (!/^p187__.+__d(0[1-9]|1[0-2])(?:__.+)?$/.test(id)) return false;
  return idDimension(id) === Number(cell?.dimension);
}

function formatCell(cell) {
  return `${cell?.cell_id || "(missing cell_id)"} ${cell?.dimension_name || "(missing dimension)"}`;
}

function scoreValue(value) {
  if (value === null || value === undefined) return null;
  const number = Number(value);
  return Number.isInteger(number) && number >= 0 && number <= 3 ? number : Number.NaN;
}

function validateBaselineCellShape(cell, failures, label = "final.cells.json") {
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
    if (!(field in cell)) failures.push(`${label}: ${formatCell(cell)} missing ${field}.`);
  }

  const dimension = Number(cell.dimension);
  if (!DIMENSIONS.has(dimension) || cell.dimension_name !== DIMENSIONS.get(dimension)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid D-09/D-12 dimension mapping.`);
  }
  if (!validCellGrammar(cell)) {
    failures.push(`${label}: ${formatCell(cell)} violates frozen p187__...__dXX grammar.`);
  }
  if (!COVERAGE_RANK.has(cell.coverage_status)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid coverage_status.`);
  }
  const score = scoreValue(cell.score);
  if (Number.isNaN(score)) {
    failures.push(`${label}: ${formatCell(cell)} has invalid score; expected 0, 1, 2, 3, or null.`);
  }
  if (!Array.isArray(cell.evidence_refs)) {
    failures.push(`${label}: ${formatCell(cell)} evidence_refs must be an array.`);
  }
}

function isBaselineCorrection(row, baselineById) {
  if (!row || typeof row !== "object") return false;
  const type = String(row.type || row.kind || row.reason || row.status || "").toLowerCase();
  const correction = Boolean(row.baseline_correction || row.correction || type.includes("baseline-correction"));
  if (!correction) return false;
  const namedInvalidRow =
    row.invalid_baseline_cell_id || row.baseline_cell_id || row.corrected_cell_id || row.cell_id;
  return Boolean(namedInvalidRow && (baselineById.has(namedInvalidRow) || String(namedInvalidRow).startsWith("p187__")));
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

function validArtifactRef(ref) {
  const value = String(ref || "");
  if (!value || path.isAbsolute(value) || value.includes("\\") || value.split("/").includes("..")) return false;
  return ALLOWED_ARTIFACT_ROOTS.some((root) => value.startsWith(root));
}

function validateArtifactRef(ref, label, failures) {
  if (!validArtifactRef(ref)) {
    failures.push(`${label}: invalid artifact ref "${ref}" (D-16/T-192-03 repo-relative generated roots only).`);
  }
}

function validateChecksum(row, label, failures) {
  const checksum = row.sha256 || row.checksum || row.digest;
  if (!checksum) return;
  const value = String(checksum).replace(/^sha256:/, "");
  if (!/^[a-f0-9]{64}$/i.test(value)) {
    failures.push(`${label}: ${artifactRef(row) || row.id || "(unknown artifact)"} has non-SHA-256-looking checksum.`);
  }
}

function validateManifest(manifestPath) {
  const failures = {
    manifest: [],
  };
  const manifest = readJson(manifestPath);
  const entries = manifestEntries(manifest);

  if (entries.length === 0) {
    failures.manifest.push("artifacts.manifest.json must list at least one artifact/evidence entry.");
  }

  const refs = new Set();
  for (const entry of entries) {
    const ref = artifactRef(entry);
    if (!ref) {
      failures.manifest.push(`Manifest entry ${entry.id || "(without id)"} is missing path/ref/evidence_ref.`);
      continue;
    }
    validateArtifactRef(ref, "artifacts.manifest.json", failures.manifest);
    validateChecksum(entry, "artifacts.manifest.json", failures.manifest);
    refs.add(String(ref));
  }

  return { entries, refs, failures };
}

function allArtifactRefs(manifestResult) {
  return manifestResult.refs;
}

function supportIsVisualOnly(row) {
  const refs = evidenceRefs(row).map((ref) => ref.toLowerCase());
  const lenses = rowLenses(row);
  const source = `${refs.join(" ")} ${lenses.join(" ")} ${String(row.notes || row.reason || "").toLowerCase()}`;
  const hasVisual = VISUAL_ONLY_MARKERS.some((marker) => source.includes(marker));
  const hasNonVisual = NON_VISUAL_MARKERS.some((marker) => source.includes(marker));
  if (lenses.length > 0) {
    return lenses.every((lens) => lens === "visual-brand-microcopy" || lens === "maintainer-review");
  }
  return hasVisual && !hasNonVisual;
}

function requiresDeterministicSupport(row) {
  const dimensionName = row.dimension_name || row.rubric_dimension || "";
  const notes = String(row.notes || row.reason || row.actual || row.expected || "").toLowerCase();
  return SENSITIVE_DIMENSIONS.has(dimensionName) || SENSITIVE_WORDS.some((word) => notes.includes(word));
}

function validateEvidence(row, label, failures, manifestRefs) {
  const refs = evidenceRefs(row);
  if (refs.length === 0) {
    failures.push(`${label}: ${row.cell_id || row.id || "(row)"} lacks D-16 evidence refs.`);
    return;
  }
  for (const ref of refs) {
    validateArtifactRef(ref, label, failures);
    if (manifestRefs.size > 0 && !manifestRefs.has(ref)) {
      failures.push(`${label}: ${row.cell_id || row.id || "(row)"} references ${ref} not present in artifacts.manifest.json.`);
    }
  }
  const lenses = rowLenses(row);
  for (const lens of lenses) {
    if (!ALLOWED_LENSES.has(lens)) {
      failures.push(`${label}: ${row.cell_id || row.id || "(row)"} uses unknown evidence lens "${lens}".`);
    }
  }
  if (requiresDeterministicSupport(row) && supportIsVisualOnly(row)) {
    failures.push(
      `${label}: ${row.cell_id || row.id || "(row)"} relies only on visual/model/maintainer evidence for a D-17/D-18 deterministic claim.`
    );
  }
}

function compareFinalCells(baselineRows, finalRows, deltaRows, manifestRefs) {
  const failures = {
    malformedRows: [],
    missingComparableCells: [],
    invalidComparableCells: [],
    scoreDowngrades: [],
    coverageDowngrades: [],
    missingEvidence: [],
    baselineCorrections: [],
  };

  const baselineById = new Map();
  for (const cell of baselineRows) {
    validateBaselineCellShape(cell, failures.malformedRows, "baseline.cells.json");
    if (cell.cell_id) baselineById.set(cell.cell_id, cell);
  }

  const correctionRows = deltaRows.filter((row) => isBaselineCorrection(row, baselineById));
  for (const row of correctionRows) {
    validateEvidence(row, "scorecard.delta.json baseline correction", failures.baselineCorrections, manifestRefs);
    const note = `${row.invalid_baseline_cell_id || row.baseline_cell_id || row.cell_id || "(unknown cell)"} ${row.reason || row.notes || ""}`;
    if (!/invalid|stale|impossible|correction/i.test(note)) {
      failures.baselineCorrections.push(
        `scorecard.delta.json baseline correction for ${row.cell_id || "(unknown cell)"} must name the invalid Phase 187 row and why.`
      );
    }
  }

  const finalById = new Map();
  for (const cell of finalRows) {
    validateBaselineCellShape(cell, failures.malformedRows, "final.cells.json");
    if (!cell.cell_id) continue;

    const baseline = baselineById.get(cell.cell_id);
    const correction = correctionRows.find((row) => row.cell_id === cell.cell_id || row.final_cell_id === cell.cell_id);
    if (!baseline && !correction) {
      failures.invalidComparableCells.push(
        `${cell.cell_id} is not a comparable Phase 187 row and has no structured baseline correction.`
      );
    }
    if (baseline && idDimension(cell.cell_id) !== idDimension(baseline.cell_id)) {
      failures.invalidComparableCells.push(`${cell.cell_id} changes the Phase 187 dimension suffix.`);
    }
    validateEvidence(cell, "final.cells.json", failures.missingEvidence, manifestRefs);
    finalById.set(cell.cell_id, cell);
  }

  for (const baseline of baselineRows) {
    const finalCell = finalById.get(baseline.cell_id);
    const correction = correctionRows.find(
      (row) => row.invalid_baseline_cell_id === baseline.cell_id || row.baseline_cell_id === baseline.cell_id
    );
    if (!finalCell && !correction) {
      failures.missingComparableCells.push(`${baseline.cell_id} missing from final.cells.json.`);
      continue;
    }
    if (!finalCell) continue;

    const baselineScore = scoreValue(baseline.score);
    const finalScore = scoreValue(finalCell.score);
    if (baselineScore !== null && (finalScore === null || finalScore < baselineScore)) {
      failures.scoreDowngrades.push(
        `${baseline.cell_id}: final_score ${finalScore} below baseline_score ${baselineScore} (D-10 score-downgrade).`
      );
    }

    if (
      baseline.coverage_status === "covered" &&
      finalCell.coverage_status !== "covered" &&
      !correction
    ) {
      failures.coverageDowngrades.push(
        `${baseline.cell_id}: coverage downgraded covered -> ${finalCell.coverage_status} (D-11 coverage-downgrade).`
      );
    }
    if ((finalCell.coverage_status === "gap" || finalCell.coverage_status === "n/a") && !correction) {
      failures.coverageDowngrades.push(
        `${baseline.cell_id}: final cell is newly unreachable/gap without baseline correction.`
      );
    }
  }

  for (const row of deltaRows) {
    const kind = String(row.kind || row.type || row.reason || "").toLowerCase();
    if (/downgrade|regression|correction/.test(kind) || row.baseline_correction || row.regression) {
      validateEvidence(row, "scorecard.delta.json", failures.missingEvidence, manifestRefs);
    }
  }

  return failures;
}

function mergeFailureMaps(...maps) {
  const merged = {};
  for (const map of maps) {
    for (const [key, items] of Object.entries(map)) {
      merged[key] ||= [];
      merged[key].push(...items);
    }
  }
  return merged;
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

export function verifyPhase192Scorecard(options = {}) {
  const paths = { ...DEFAULT_INPUTS, ...options };
  const manifestResult = validateManifest(paths.manifestPath);
  const manifestRefs = allArtifactRefs(manifestResult);

  if (options.manifestOnly) {
    const failures = manifestResult.failures;
    return {
      ok: failureCount(failures) === 0,
      summary: { manifest_entries: manifestResult.entries.length },
      failures,
    };
  }

  const shapeFailures = { malformedRows: [] };
  const baselineRows = asArray(readJson(paths.baselinePath), "baseline.cells.json", shapeFailures.malformedRows);
  const finalRows = asArray(readJson(paths.finalCellsPath), "final.cells.json", shapeFailures.malformedRows);
  const deltaRows = asArray(readJson(paths.deltaPath), "scorecard.delta.json", shapeFailures.malformedRows);
  const regressions = readNdjson(paths.regressionsPath);
  const regressionFailures = { regressions: [], missingEvidence: [] };

  if (regressions.length > 0) {
    for (const row of regressions) {
      regressionFailures.regressions.push(
        `${row.id || row.cell_id || "(regression row)"} blocks sign-off; regressions.ndjson must be empty.`
      );
      validateEvidence(row, "regressions.ndjson", regressionFailures.missingEvidence, manifestRefs);
    }
  }

  const comparisonFailures = compareFinalCells(baselineRows, finalRows, deltaRows, manifestRefs);
  const failures = mergeFailureMaps(manifestResult.failures, shapeFailures, comparisonFailures, regressionFailures);

  return {
    ok: failureCount(failures) === 0,
    summary: {
      baseline_cells: baselineRows.length,
      final_cells: finalRows.length,
      delta_rows: deltaRows.length,
      regression_rows: regressions.length,
      manifest_entries: manifestResult.entries.length,
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
    surface_type: "page-flow",
    mode: "chromium-desktop",
    viewport_width: 1440,
    theme: "light",
    state: "default-populated",
    dimension: 11,
    dimension_name: "interaction-integrity",
    score: 2,
    coverage_status: "covered",
    evidence_refs: ["accrue_admin/test-results/phase192/interaction-trace.json"],
    evidence_lenses: ["interaction-trace", "correctness"],
    notes: "Fixture row proves deterministic interaction integrity evidence.",
    targeted_label: null,
    breakpoint: null,
    ...overrides,
  };
}

function fixturePackage(root, overrides = {}) {
  const baseline = [fixtureCell()];
  const final = overrides.final || [fixtureCell({ score: 3 })];
  const delta = overrides.delta || [
    {
      cell_id: baseline[0].cell_id,
      baseline_score: 2,
      final_score: 3,
      coverage_change: "covered->covered",
      kind: "passing-delta",
      evidence_refs: ["accrue_admin/test-results/phase192/interaction-trace.json"],
      evidence_lenses: ["interaction-trace"],
    },
  ];
  const regressions = overrides.regressions || "";
  const manifest = overrides.manifest || {
    artifacts: [
      {
        path: "accrue_admin/test-results/phase192/interaction-trace.json",
        sha256: "a".repeat(64),
        bytes: 42,
      },
    ],
  };

  writeJson(path.join(root, "baseline.cells.json"), baseline);
  writeJson(path.join(root, "final.cells.json"), final);
  writeJson(path.join(root, "scorecard.delta.json"), delta);
  writeText(path.join(root, "regressions.ndjson"), regressions);
  writeJson(path.join(root, "artifacts.manifest.json"), manifest);

  return {
    baselinePath: path.join(root, "baseline.cells.json"),
    finalCellsPath: path.join(root, "final.cells.json"),
    deltaPath: path.join(root, "scorecard.delta.json"),
    regressionsPath: path.join(root, "regressions.ndjson"),
    manifestPath: path.join(root, "artifacts.manifest.json"),
  };
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "phase192-scorecard-"));
  try {
    const positive = verifyPhase192Scorecard(fixturePackage(path.join(root, "positive")));
    assertSelfTest("positive structured package exits 0", positive.ok, JSON.stringify(positive.failures));

    const downgrade = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "downgrade"), { final: [fixtureCell({ score: 1 })] })
    );
    assertSelfTest("score downgrade exits non-zero", !downgrade.ok);
    assertSelfTest("score downgrade reports score-downgrade section", downgrade.failures.scoreDowngrades.length > 0);

    const coverageGap = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "coverage-gap"), { final: [fixtureCell({ coverage_status: "gap" })] })
    );
    assertSelfTest("coverage downgrade exits non-zero", !coverageGap.ok);
    assertSelfTest("coverage downgrade reports coverage section", coverageGap.failures.coverageDowngrades.length > 0);

    const missingEvidence = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "missing-evidence"), {
        final: [fixtureCell({ evidence_refs: [], evidence_lenses: [] })],
      })
    );
    assertSelfTest("missing evidence exits non-zero", !missingEvidence.ok);
    assertSelfTest("missing evidence reports evidence section", missingEvidence.failures.missingEvidence.length > 0);

    const nonEmptyRegression = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "regression"), {
        regressions: `${JSON.stringify({
          id: "P192-REG-001",
          cell_id: fixtureCell().cell_id,
          kind: "score-downgrade",
          evidence_refs: ["accrue_admin/test-results/phase192/interaction-trace.json"],
          evidence_lenses: ["interaction-trace"],
        })}\n`,
      })
    );
    assertSelfTest("non-empty regressions.ndjson exits non-zero", !nonEmptyRegression.ok);
    assertSelfTest("regressions section is reported", nonEmptyRegression.failures.regressions.length > 0);

    const invalidCell = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "invalid-cell"), {
        final: [fixtureCell({ cell_id: "phase192__fixture__d11" })],
      })
    );
    assertSelfTest("non-p187 cell ID exits non-zero", !invalidCell.ok);
    assertSelfTest("invalid comparable cell section is reported", invalidCell.failures.invalidComparableCells.length > 0);

    const visualOnly = verifyPhase192Scorecard(
      fixturePackage(path.join(root, "visual-only"), {
        final: [
          fixtureCell({
            evidence_refs: ["accrue_admin/test-results/phase192/gallery-screenshot.png"],
            evidence_lenses: ["visual-brand-microcopy"],
          }),
        ],
        manifest: {
          artifacts: [
            {
              path: "accrue_admin/test-results/phase192/gallery-screenshot.png",
              sha256: "b".repeat(64),
            },
          ],
        },
      })
    );
    assertSelfTest("visual-only deterministic support exits non-zero", !visualOnly.ok);

    const manifestOnly = verifyPhase192Scorecard({
      ...fixturePackage(path.join(root, "manifest-only")),
      manifestOnly: true,
    });
    assertSelfTest("--manifest validates manifest independently", manifestOnly.ok);

    const badManifest = verifyPhase192Scorecard({
      ...fixturePackage(path.join(root, "bad-manifest"), {
        manifest: { artifacts: [{ path: "../secret.json", sha256: "not-a-sha" }] },
      }),
      manifestOnly: true,
    });
    assertSelfTest("--manifest fails invalid refs/checksums", !badManifest.ok);

    console.log("Phase 192 scorecard self-test passed.");
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--manifest") options.manifestOnly = true;
    else if (arg === "--baseline") options.baselinePath = path.resolve(argv[++index]);
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

  const result = verifyPhase192Scorecard(options);
  console.log(
    `Phase 192 scorecard verifier: baseline=${result.summary.baseline_cells || 0}, final=${
      result.summary.final_cells || 0
    }, delta=${result.summary.delta_rows || 0}, regressions=${result.summary.regression_rows || 0}, manifest=${
      result.summary.manifest_entries || 0
    }`
  );

  if (!result.ok) {
    reportFailures("Phase 192 scorecard verification failed.", result.failures);
    process.exitCode = 1;
  } else {
    console.log("Phase 192 scorecard verification passed.");
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 192 scorecard verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
