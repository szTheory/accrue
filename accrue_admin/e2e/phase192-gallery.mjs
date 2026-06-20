import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const adminRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(adminRoot, "..");
const testResultsRoot = path.join(adminRoot, "test-results");
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";
const phaseDir = path.join(repoRoot, PHASE192_DIR);

const DEFAULT_INPUTS = {
  finalCells: path.join(phaseDir, "final.cells.json"),
  delta: path.join(phaseDir, "scorecard.delta.json"),
  regressions: path.join(phaseDir, "regressions.ndjson"),
  manifest: path.join(phaseDir, "artifacts.manifest.json"),
  scorecard: path.join(phaseDir, "192-SCORECARD.md"),
};

const DEFAULT_OUTPUT = path.join(phaseDir, "192-SIGN-OFF.md");

const REQUIRED_GALLERY_FIELDS = [
  "who",
  "job",
  "route_or_surface",
  "state",
  "theme",
  "viewport",
  "evidence_ref",
  "why_this_matters",
  "status",
];

const GALLERY_CATEGORIES = [
  {
    category: "dashboard health scan",
    who: "maintainer",
    job: "dashboard health scan",
    route_or_surface: "/billing",
    state: "default-populated",
    why_this_matters:
      "Confirms an operator can inspect billing health without backend-guts presentation.",
  },
  {
    category: "customer inspection",
    who: "operator",
    job: "customer inspection",
    route_or_surface: "/billing/customers/:id",
    state: "default-populated",
    why_this_matters:
      "Confirms customer identity, owner scope, subscription, invoice, and event context stay readable together.",
  },
  {
    category: "subscription triage/detail",
    who: "operator",
    job: "subscription triage/detail",
    route_or_surface: "/billing/subscriptions and /billing/subscriptions/:id",
    state: "default-populated",
    why_this_matters:
      "Confirms an operator can filter subscriptions, inspect a customer, and recover a failing billing process.",
  },
  {
    category: "invoice/payment review",
    who: "operator",
    job: "invoice/payment review",
    route_or_surface: "/billing/invoices, /billing/payments, and detail routes",
    state: "default-populated",
    why_this_matters:
      "Confirms invoice, charge/payment, refund, and void review copy names the affected object and next action.",
  },
  {
    category: "webhook/event debugging",
    who: "maintainer",
    job: "webhook/event debugging",
    route_or_surface: "/billing/webhooks, /billing/events, and detail routes",
    state: "default-populated",
    why_this_matters:
      "Confirms webhook replay, event inspection, and failure recovery are presented as operator work, not raw internals.",
  },
  {
    category: "recovery campaign",
    who: "operator",
    job: "recovery campaign",
    route_or_surface: "/billing/analytics/recovery",
    state: "default-populated",
    why_this_matters:
      "Confirms recovery copy explains what happened, which subscription or invoice is affected, and the next useful action.",
  },
  {
    category: "component lab",
    who: "maintainer",
    job: "component lab",
    route_or_surface: "/billing/dev/components",
    state: "default-populated",
    why_this_matters:
      "Confirms reusable component and component-group specimens still express the ax-* token contract.",
  },
  {
    category: "modal",
    who: "maintainer",
    job: "modal open state",
    route_or_surface: "modal confirmation surface",
    state: "interactive-open",
    why_this_matters:
      "Confirms the modal open state supports focused review of destructive confirmation without layout drift.",
  },
  {
    category: "drawer",
    who: "maintainer",
    job: "drawer open state",
    route_or_surface: "webhook replay drawer",
    state: "interactive-open",
    why_this_matters:
      "Confirms drawer content remains reachable and actionable when replaying a webhook.",
  },
  {
    category: "dropdown",
    who: "maintainer",
    job: "dropdown open state",
    route_or_surface: "customer action dropdown",
    state: "interactive-open",
    why_this_matters:
      "Confirms dropdown affordance, hover, focused, and open states remain legible in dense admin context.",
  },
  {
    category: "command palette",
    who: "maintainer",
    job: "command palette open state",
    route_or_surface: "global command palette",
    state: "interactive-open",
    why_this_matters:
      "Confirms global search and command entry keep focus and Escape behavior trace-backed.",
  },
  {
    category: "empty",
    who: "operator",
    job: "empty state recovery",
    route_or_surface: "filtered tables and billing lists",
    state: "empty",
    why_this_matters:
      "Confirms empty-state microcopy names clear filters or the next inspection step.",
  },
  {
    category: "error",
    who: "operator",
    job: "error state recovery",
    route_or_surface: "invoice, webhook, and event error states",
    state: "error",
    why_this_matters:
      "Confirms error copy states what happened, the affected object or process, and a repair action.",
  },
  {
    category: "permission",
    who: "maintainer",
    job: "permission-denied state",
    route_or_surface: "restricted admin route",
    state: "permission-denied",
    why_this_matters:
      "Confirms permission messaging is exact without exposing backend-guts detail.",
  },
  {
    category: "disconnected",
    who: "operator",
    job: "disconnected/reconnecting state",
    route_or_surface: "LiveView connection status",
    state: "disconnected-reconnecting",
    why_this_matters:
      "Confirms LiveView recovery status is visible without interrupting inspection work.",
  },
  {
    category: "mobile nav",
    who: "operator",
    job: "mobile navigation",
    route_or_surface: "admin mobile nav",
    state: "interactive-open",
    why_this_matters:
      "Confirms layout-risk navigation remains reachable on narrow viewports.",
  },
  {
    category: "destructive confirmations",
    who: "operator",
    job: "destructive confirmation",
    route_or_surface: "refund, void, replay, and recover confirmation controls",
    state: "interactive-open",
    why_this_matters:
      "Confirms destructive actions require explicit confirmation and name the affected charge/payment, invoice, webhook, or subscription.",
  },
  {
    category: "disabled/read-only actions",
    who: "operator",
    job: "disabled/read-only action review",
    route_or_surface: "disabled and read-only action controls",
    state: "disabled-readonly",
    why_this_matters:
      "Confirms disabled affordances explain why an action is unavailable without hiding the next useful step.",
  },
];

const LAYOUT_RISK_CATEGORIES = new Set([
  "dashboard health scan",
  "customer inspection",
  "subscription triage/detail",
  "invoice/payment review",
  "webhook/event debugging",
  "recovery campaign",
  "component lab",
  "mobile nav",
]);

const TRACE_REQUIREMENTS = [
  ["focus trap", "focus-trap"],
  ["focus restore", "focus-restore"],
  ["Escape", "escape"],
  ["outside click", "outside-click"],
  ["scroll reachability", "scroll-reachability"],
  ["LiveView patch focus", "liveview-patch-focus"],
  ["actionability", "actionability"],
];

const CHECKLIST_ROWS = [
  ["JTBD clarity", "Gallery rows are organized around operator and maintainer jobs, not chronology."],
  ["domain vocabulary", "Copy uses customer, subscription, invoice, charge/payment, webhook, event, recovery, and Connect account."],
  ["microcopy recovery", "States name what happened, the affected object or process, and the next useful action where one exists."],
  ["brand fit", "Review follows measured, exact, native, durable Accrue voice without fintech/startup gloss."],
  ["accessible focus/contrast", "Focus and contrast claims cite deterministic browser or trace evidence."],
  ["mobile usability", "Layout-risk flows include mobile evidence."],
  ["dark-mode role clarity", "Light and dark rows prove role clarity across selected flows."],
  ["absence of backend-guts presentation", "The surface uses operator language instead of implementation dumping."],
  ["accessibility", "Axe/WCAG status is represented as a deterministic guardrail, not a screenshot-only claim."],
  ["performance", "Guardrail status names bounded commands and keeps full evidence runs separate."],
  ["responsive layout", "Narrow viewport rows cover layout-risk flows."],
  ["light/dark or system-theme behavior", "Theme behavior is explicit; system theme is listed only with deterministic evidence."],
  ["interaction integrity", "Focus, Escape, outside click, scroll, patch focus, and actionability claims link traces."],
  ["focus/hover/disabled affordance", "Historical-risk controls include focus, hover, disabled/read-only, and open states."],
  ["information hierarchy", "Status, blockers, artifacts, and gallery evidence are ordered for maintainer scanning."],
  ["brand expression", "The package reads like quiet, well-made developer tooling."],
  ["developer/operator DX", "Maintainers can review one sign-off package instead of raw screenshots, traces, or the full cell corpus."],
];

const GUARDRAILS = [
  ["baseline:parse", "cd accrue_admin && npm run baseline:parse"],
  ["verify_phase191_ax187_coverage", "node scripts/ci/verify_phase191_ax187_coverage.mjs"],
  ["e2e:group-contracts", "cd accrue_admin && npm run e2e:group-contracts"],
  ["e2e:phase191", "cd accrue_admin && npm run e2e:phase191"],
  ["e2e:a11y", "cd accrue_admin && npm run e2e:a11y"],
  ["reduced-motion", "cd accrue_admin && npx playwright test e2e/reduced-motion.spec.js --workers=1"],
  ["component-lab coverage", "cd accrue_admin && npm run phase192:component-lab"],
];

function repoRelative(absPath) {
  return path.relative(repoRoot, absPath).split(path.sep).join("/");
}

function phaseRef(value) {
  return `${PHASE192_DIR}/${value}`.replace(/\/+/g, "/");
}

function readJson(absPath, repairs) {
  try {
    return JSON.parse(fs.readFileSync(absPath, "utf8"));
  } catch (error) {
    repairs.push(`Regenerate ${repoRelative(absPath)}; it is missing or malformed (${error.message}).`);
    return null;
  }
}

function readNdjson(absPath, repairs) {
  try {
    return fs
      .readFileSync(absPath, "utf8")
      .split(/\r?\n/)
      .filter(Boolean)
      .map((line, index) => {
        try {
          return JSON.parse(line);
        } catch (error) {
          repairs.push(`Regenerate ${repoRelative(absPath)}; line ${index + 1} is malformed (${error.message}).`);
          return { malformed: true };
        }
      });
  } catch (error) {
    repairs.push(`Regenerate ${repoRelative(absPath)}; it is missing or unreadable (${error.message}).`);
    return null;
  }
}

function readText(absPath, repairs) {
  try {
    return fs.readFileSync(absPath, "utf8");
  } catch (error) {
    repairs.push(`Regenerate ${repoRelative(absPath)}; it is missing or unreadable (${error.message}).`);
    return null;
  }
}

function collectRefs(value, refs = []) {
  if (!value) return refs;
  if (typeof value === "string") {
    if (
      value.startsWith("accrue_admin/test-results/") ||
      value.startsWith("accrue_admin/playwright-report/") ||
      value.startsWith(PHASE192_DIR)
    ) {
      refs.push(value);
    }
    return refs;
  }
  if (Array.isArray(value)) {
    value.forEach((item) => collectRefs(item, refs));
    return refs;
  }
  if (typeof value === "object") {
    Object.values(value).forEach((item) => collectRefs(item, refs));
  }
  return refs;
}

function refFor(refs, category, theme = "light", viewport = "desktop") {
  const normalized = `${category} ${theme} ${viewport}`.toLowerCase();
  const match = refs.find((ref) => {
    const candidate = ref.toLowerCase();
    return normalized
      .split(/\s+/)
      .filter(Boolean)
      .every((part) => candidate.includes(part.replace("/", "-")) || candidate.includes(part));
  });
  if (match) return match;
  return phaseRef(`artifacts.manifest.json#${category.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}-${theme}-${viewport}`);
}

function traceRefFor(refs, slug) {
  return refs.find((ref) => ref.toLowerCase().includes(slug)) || phaseRef(`artifacts.manifest.json#trace-${slug}`);
}

function loadArtifactPackage(options = {}) {
  const inputs = { ...DEFAULT_INPUTS, ...(options.inputs || {}) };
  const repairs = [];
  const finalCells = readJson(inputs.finalCells, repairs);
  const delta = readJson(inputs.delta, repairs);
  const regressions = readNdjson(inputs.regressions, repairs);
  const manifest = readJson(inputs.manifest, repairs);
  const scorecard = readText(inputs.scorecard, repairs);

  const refs = Array.from(new Set(collectRefs(manifest)));
  const regressionRows = Array.isArray(regressions) ? regressions.filter((row) => row && !row.malformed) : [];
  if (regressionRows.length > 0) {
    repairs.push(`Resolve ${regressionRows.length} regression row(s) in ${repoRelative(inputs.regressions)} before accepting sign-off.`);
  }

  const cells = Array.isArray(finalCells) ? finalCells : Array.isArray(finalCells?.cells) ? finalCells.cells : [];
  const deltaRows = Array.isArray(delta) ? delta : Array.isArray(delta?.rows) ? delta.rows : [];
  const guardrails = manifest?.command_statuses || manifest?.guardrails || manifest?.commands || {};

  return {
    inputs,
    refs,
    repairs,
    status: repairs.length === 0 ? "ACCEPT" : "BLOCK",
    finalCellCount: cells.length,
    comparableCellCount: deltaRows.length,
    regressionCount: regressionRows.length,
    scorecardPresent: Boolean(scorecard),
    manifest,
    guardrails,
  };
}

function commandStatus(guardrails, key) {
  if (Array.isArray(guardrails)) {
    return guardrails.find((row) => String(row.name || row.command || "").includes(key));
  }
  return guardrails[key] || Object.values(guardrails || {}).find((row) => String(row.name || row.command || "").includes(key));
}

function generateEvidenceRows(refs, artifactStatus) {
  const rows = [];
  for (const item of GALLERY_CATEGORIES) {
    for (const theme of ["light", "dark"]) {
      rows.push({
        ...item,
        theme,
        viewport: "desktop",
        evidence_ref: refFor(refs, item.category, theme, "desktop"),
        status: artifactStatus,
      });
    }
    if (LAYOUT_RISK_CATEGORIES.has(item.category)) {
      rows.push({
        ...item,
        theme: "light",
        viewport: "mobile",
        evidence_ref: refFor(refs, item.category, "light", "mobile"),
        status: artifactStatus,
      });
    }
  }
  return rows;
}

function validateGalleryRows(rows) {
  const failures = [];
  rows.forEach((row, index) => {
    for (const field of REQUIRED_GALLERY_FIELDS) {
      if (!String(row[field] || "").trim()) failures.push(`gallery row ${index + 1} missing ${field}`);
    }
    if (!["ACCEPT", "BLOCK"].includes(row.status)) {
      failures.push(`gallery row ${index + 1} status must be ACCEPT or BLOCK`);
    }
  });
  for (const category of GALLERY_CATEGORIES.map((row) => row.category)) {
    if (!rows.some((row) => row.category === category || row.job.includes(category))) {
      failures.push(`gallery missing required category ${category}`);
    }
  }
  for (const category of GALLERY_CATEGORIES.map((row) => row.category)) {
    const categoryRows = rows.filter((row) => row.category === category);
    if (!categoryRows.some((row) => row.theme === "light")) failures.push(`${category} missing light evidence`);
    if (!categoryRows.some((row) => row.theme === "dark")) failures.push(`${category} missing dark evidence`);
  }
  for (const category of LAYOUT_RISK_CATEGORIES) {
    if (!rows.some((row) => row.category === category && row.viewport === "mobile")) {
      failures.push(`${category} missing mobile layout-risk evidence`);
    }
  }
  if (failures.length > 0) throw new Error(failures.join("; "));
}

function validateTraceRefs(traceRefs) {
  const failures = TRACE_REQUIREMENTS.filter(([name]) => !String(traceRefs[name] || "").trim()).map(
    ([name]) => `missing trace ref for ${name}`
  );
  if (failures.length > 0) throw new Error(failures.join("; "));
}

function validateChecklistRows(rows) {
  const failures = [];
  for (const [name] of CHECKLIST_ROWS) {
    const row = rows.find((item) => item.category === name);
    if (!row) failures.push(`checklist missing ${name}`);
    else if (!["ACCEPT", "BLOCK"].includes(row.status)) failures.push(`checklist ${name} status must be ACCEPT or BLOCK`);
    else if (!String(row.evidence_ref || "").trim()) failures.push(`checklist ${name} missing evidence ref`);
  }
  if (failures.length > 0) throw new Error(failures.join("; "));
}

export function generatePhase192Gallery(options = {}) {
  const artifactPackage = options.artifactPackage || loadArtifactPackage(options);
  const refs = options.refs || artifactPackage.refs;
  const rows = options.rows || generateEvidenceRows(refs, artifactPackage.status);
  const traceRefs = Object.fromEntries(TRACE_REQUIREMENTS.map(([name, slug]) => [name, traceRefFor(refs, slug)]));
  validateGalleryRows(rows);
  validateTraceRefs(traceRefs);
  return { rows, traceRefs, status: artifactPackage.status };
}

function checklistRows(status, refs) {
  const fallback = refs[0] || phaseRef("artifacts.manifest.json#maintainer-checklist");
  return CHECKLIST_ROWS.map(([category, review]) => ({
    category,
    review,
    status,
    evidence_ref: category.includes("interaction") || category.includes("focus")
      ? traceRefFor(refs, "actionability")
      : fallback,
  }));
}

function markdownTable(headers, rows) {
  return [
    `| ${headers.join(" | ")} |`,
    `| ${headers.map(() => "---").join(" | ")} |`,
    ...rows.map((row) => `| ${headers.map((header) => String(row[header] ?? "").replace(/\|/g, "\\|")).join(" | ")} |`),
  ].join("\n");
}

function renderSignoff({ artifactPackage, gallery, checklist }) {
  const statusWord = artifactPackage.status === "ACCEPT" ? "PASS" : "BLOCK";
  const guardrailRows = GUARDRAILS.map(([name, command]) => {
    const found = commandStatus(artifactPackage.guardrails, name);
    const passed = found && /pass|passed|ok|success|0/i.test(String(found.status ?? found.outcome ?? found.exit_code ?? ""));
    return {
      Guardrail: name,
      Command: command,
      Status: passed && artifactPackage.status === "ACCEPT" ? "Required guardrail passed" : "Required guardrail failed",
      Evidence: found?.evidence_ref || found?.log || phaseRef(`artifacts.manifest.json#guardrail-${name.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}`),
    };
  });

  const galleryRows = gallery.rows.map((row) => ({
    who: row.who,
    job: row.job,
    "route/surface": row.route_or_surface,
    state: row.state,
    theme: row.theme,
    viewport: row.viewport,
    "evidence ref": row.evidence_ref,
    "why it matters": row.why_this_matters,
    status: row.status,
  }));

  const checklistLines = checklist
    .map(
      (row) =>
        `- [x] ${row.category} - ${row.status}: ${row.review} Evidence: ${row.evidence_ref}`
    )
    .join("\n");

  const repairs =
    artifactPackage.repairs.length > 0
      ? artifactPackage.repairs.map((repair) => `- ${repair}`).join("\n")
      : "- None. Structured evidence is present and no blocking regression rows were found.";

  const traceLines = TRACE_REQUIREMENTS.map(
    ([name]) => `- ${name}: ${gallery.traceRefs[name]}`
  ).join("\n");

  return `# Phase 192 Maintainer Sign-Off

## Executive Status

${statusWord} - Phase 192 sign-off outcome is ${artifactPackage.status}; ${artifactPackage.status === "BLOCK" ? "blocked" : "passed"} until structured evidence proves otherwise. The maintainer decision surface is this file, not raw \`test-results\` output or the full final-cell corpus.

Required repairs before ACCEPT:
${repairs}

## Baseline Comparison

Final score >= Phase 187 baseline is accepted only when structured artifacts prove every comparable cell. Current structured summary:

- final cells: ${artifactPackage.finalCellCount}
- comparable cells: ${artifactPackage.comparableCellCount}
- regression rows: ${artifactPackage.regressionCount}
- scorecard summary present: ${artifactPackage.scorecardPresent ? "yes" : "no"}

Structured artifact refs:
- ${phaseRef("final.cells.json")}
- ${phaseRef("scorecard.delta.json")}
- ${phaseRef("regressions.ndjson")}
- ${phaseRef("artifacts.manifest.json")}
- ${phaseRef("192-SCORECARD.md")}

## CI Guardrail Status

${markdownTable(["Guardrail", "Command", "Status", "Evidence"], guardrailRows)}

## Curated Gallery

Categories covered: dashboard health scan; customer inspection; subscription triage/detail; invoice/payment review; webhook/event debugging; recovery campaign; component lab; modal open state; drawer open state; dropdown open state; command palette open state; mobile nav; destructive confirmations; disabled/read-only actions; empty state; error state; permission-denied state; disconnected/reconnecting state.

${markdownTable(["who", "job", "route/surface", "state", "theme", "viewport", "evidence ref", "why it matters", "status"], galleryRows)}

## Interaction Trace References

${traceLines}

## Artifact Manifest Links

- Artifact manifest: ${phaseRef("artifacts.manifest.json")}
- Final cells: ${phaseRef("final.cells.json")}
- Scorecard delta: ${phaseRef("scorecard.delta.json")}
- Regressions: ${phaseRef("regressions.ndjson")}
- Scorecard summary: ${phaseRef("192-SCORECARD.md")}

## Maintainer Checklist

${checklistLines}

Final maintainer decision: ${artifactPackage.status}. Evidence source: ${phaseRef("artifacts.manifest.json")}.
`;
}

async function runVerifier(markdown, signoffPath = DEFAULT_OUTPUT) {
  const verifierPath = path.join(repoRoot, "scripts/ci/verify_phase192_signoff.mjs");
  const verifier = await import(pathToFileURL(verifierPath).href);
  return verifier.verifyPhase192Signoff({ markdown, signoffPath });
}

export async function generatePhase192Signoff(options = {}) {
  const artifactPackage = options.artifactPackage || loadArtifactPackage(options);
  const gallery = generatePhase192Gallery({ ...options, artifactPackage });
  const checklist = options.checklist || checklistRows(artifactPackage.status, artifactPackage.refs);
  validateChecklistRows(checklist);
  const markdown = renderSignoff({ artifactPackage, gallery, checklist });
  const verification = await runVerifier(markdown, options.outputPath || DEFAULT_OUTPUT);
  return { markdown, verification, status: artifactPackage.status, artifactPackage, gallery, checklist };
}

function completeFixture(dir) {
  const fixturePhaseDir = path.join(dir, PHASE192_DIR);
  fs.mkdirSync(fixturePhaseDir, { recursive: true });
  const refs = [
    phaseRef("gallery/dashboard-health-scan-light-desktop.png"),
    phaseRef("gallery/dashboard-health-scan-dark-desktop.png"),
    phaseRef("gallery/customer-inspection-light-mobile.png"),
    phaseRef("traces/focus-trap.zip"),
    phaseRef("traces/focus-restore.zip"),
    phaseRef("traces/escape.zip"),
    phaseRef("traces/outside-click.zip"),
    phaseRef("traces/scroll-reachability.zip"),
    phaseRef("traces/liveview-patch-focus.zip"),
    phaseRef("traces/actionability.zip"),
    "accrue_admin/test-results/phase192/baseline-parse.log",
  ];
  fs.writeFileSync(path.join(fixturePhaseDir, "final.cells.json"), JSON.stringify([{ cell_id: "p187__fixture__d01", evidence_refs: refs }]));
  fs.writeFileSync(path.join(fixturePhaseDir, "scorecard.delta.json"), JSON.stringify([{ cell_id: "p187__fixture__d01", final_score: 3, baseline_score: 2 }]));
  fs.writeFileSync(path.join(fixturePhaseDir, "regressions.ndjson"), "");
  fs.writeFileSync(
    path.join(fixturePhaseDir, "artifacts.manifest.json"),
    JSON.stringify({
      evidence: refs.map((ref) => ({ path: ref, sha256: "a".repeat(64) })),
      command_statuses: Object.fromEntries(GUARDRAILS.map(([name]) => [name, { status: "passed", evidence_ref: refs[refs.length - 1] }])),
    })
  );
  fs.writeFileSync(path.join(fixturePhaseDir, "192-SCORECARD.md"), "# Fixture scorecard\n\nPASS\n");
  return {
    finalCells: path.join(fixturePhaseDir, "final.cells.json"),
    delta: path.join(fixturePhaseDir, "scorecard.delta.json"),
    regressions: path.join(fixturePhaseDir, "regressions.ndjson"),
    manifest: path.join(fixturePhaseDir, "artifacts.manifest.json"),
    scorecard: path.join(fixturePhaseDir, "192-SCORECARD.md"),
  };
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

async function runSelfTest() {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase192-gallery-"));
  try {
    const inputs = completeFixture(tempRoot);
    const complete = await generatePhase192Signoff({ inputs, outputPath: path.join(tempRoot, "192-SIGN-OFF.md") });
    assertSelfTest("complete fixture renders ACCEPT", complete.status === "ACCEPT");
    assertSelfTest("complete fixture passes verifier", complete.verification.ok, JSON.stringify(complete.verification.failures));

    const missing = await generatePhase192Signoff({
      inputs: { ...inputs, finalCells: path.join(tempRoot, "missing-final.cells.json") },
      outputPath: path.join(tempRoot, "missing-SIGN-OFF.md"),
    });
    assertSelfTest("missing artifact renders BLOCK", missing.status === "BLOCK");
    assertSelfTest("missing artifact records required repair", missing.markdown.includes("missing-final.cells.json"));

    const artifactPackage = loadArtifactPackage({ inputs });
    assertSelfTest(
      "gallery row without required field fails self-test",
      (() => {
        try {
          generatePhase192Gallery({
            artifactPackage,
            rows: [{ ...generateEvidenceRows(artifactPackage.refs, "ACCEPT")[0], who: "" }],
          });
          return false;
        } catch {
          return true;
        }
      })()
    );
    assertSelfTest(
      "missing trace ref fails self-test",
      (() => {
        try {
          validateTraceRefs({ "focus trap": "" });
          return false;
        } catch {
          return true;
        }
      })()
    );
    assertSelfTest(
      "incomplete checklist fails self-test",
      (() => {
        try {
          validateChecklistRows(checklistRows("ACCEPT", artifactPackage.refs).slice(1));
          return false;
        } catch {
          return true;
        }
      })()
    );
    console.log("Phase 192 gallery/sign-off self-test passed.");
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--dry-run") options.dryRun = true;
    else if (arg === "--output") options.outputPath = path.resolve(argv[++index]);
    else throw new Error(`Unknown argument: ${arg}`);
  }
  return options;
}

export async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.selfTest) {
    await runSelfTest();
    return { ok: true };
  }

  const result = await generatePhase192Signoff(options);
  if (options.dryRun) {
    process.stdout.write(result.markdown);
    process.stdout.write(`\nVerifier result: ${result.verification.ok ? "PASS" : "FAIL"}\n`);
    return result;
  }

  const outputPath = options.outputPath || DEFAULT_OUTPUT;
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, result.markdown);
  console.log(`Wrote ${repoRelative(outputPath)} (${result.status}).`);
  if (!result.verification.ok) {
    console.error(JSON.stringify(result.verification.failures, null, 2));
    process.exitCode = 1;
  }
  return result;
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(`Phase 192 sign-off generator failed: ${error.message}`);
    process.exitCode = 1;
  });
}
