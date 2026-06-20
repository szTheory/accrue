import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const PHASE192_DIR = ".planning/phases/192-idempotent-verification-sign-off";
const DEFAULT_SIGNOFF_PATH = path.join(REPO_ROOT, PHASE192_DIR, "192-SIGN-OFF.md");

const REQUIRED_ARTIFACTS = [
  "final.cells.json",
  "scorecard.delta.json",
  "regressions.ndjson",
  "artifacts.manifest.json",
];

const REQUIRED_GUARDRAILS = [
  { name: "baseline:parse", markers: ["baseline:parse"] },
  { name: "verify_phase191_ax187_coverage", markers: ["verify_phase191_ax187_coverage"] },
  { name: "e2e:group-contracts", markers: ["e2e:group-contracts"] },
  { name: "e2e:phase191", markers: ["e2e:phase191"] },
  { name: "e2e:a11y", markers: ["e2e:a11y"] },
  { name: "reduced-motion", markers: ["reduced-motion"] },
  { name: "component-lab coverage", markers: ["component-lab", "component lab"] },
];

const GALLERY_FIELDS = [
  { name: "who", aliases: ["who", "persona", "reviewer"] },
  { name: "job", aliases: ["job", "jtbd", "job to be done"] },
  { name: "route or surface", aliases: ["route", "surface", "route/surface"] },
  { name: "state", aliases: ["state"] },
  { name: "theme", aliases: ["theme"] },
  { name: "viewport", aliases: ["viewport", "width"] },
  { name: "evidence ref", aliases: ["evidence", "evidence ref", "screenshot", "artifact"] },
  { name: "why it matters", aliases: ["why", "why it matters", "matters"] },
  { name: "accept/block status", aliases: ["status", "outcome", "accept/block"] },
];

const TRACE_CATEGORIES = [
  { name: "focus trap", markers: ["focus trap", "focus-trap"] },
  { name: "focus restore", markers: ["focus restore", "focus-restore"] },
  { name: "Escape", markers: ["escape"] },
  { name: "outside click", markers: ["outside click", "click outside", "outside-click", "click-outside"] },
  { name: "scroll reachability", markers: ["scroll reachability", "scroll-reachability"] },
  { name: "LiveView patch focus", markers: ["liveview patch focus", "liveview-patch-focus", "live focus"] },
  { name: "actionability", markers: ["actionability"] },
];

const CHECKLIST_CATEGORIES = [
  { name: "JTBD clarity", markers: ["jtbd clarity", "job clarity"] },
  { name: "domain vocabulary", markers: ["domain vocabulary"] },
  { name: "microcopy recovery", markers: ["microcopy recovery"] },
  { name: "brand fit", markers: ["brand fit"] },
  { name: "accessible focus/contrast", markers: ["accessible focus/contrast", "focus/contrast", "focus and contrast"] },
  { name: "mobile usability", markers: ["mobile usability"] },
  { name: "dark-mode role clarity", markers: ["dark-mode role clarity", "dark mode role clarity"] },
  { name: "absence of backend-guts presentation", markers: ["absence of backend-guts", "backend-guts", "backend guts"] },
  { name: "responsive layout", markers: ["responsive layout"] },
  { name: "light/dark or system-theme behavior", markers: ["light/dark", "system-theme", "system theme"] },
  { name: "interaction integrity", markers: ["interaction integrity"] },
  { name: "focus/hover/disabled affordance", markers: ["focus/hover/disabled", "hover/disabled", "disabled affordance"] },
  { name: "information hierarchy", markers: ["information hierarchy"] },
  { name: "developer/operator DX", markers: ["developer/operator dx", "operator dx", "developer dx"] },
];

const REQUIRED_GALLERY_CATEGORIES = [
  "dashboard health scan",
  "customer inspection",
  "subscription triage",
  "invoice/payment review",
  "webhook/event debugging",
  "recovery campaign",
  "component lab",
  "modal",
  "drawer",
  "dropdown",
  "empty",
  "error",
  "permission",
  "disconnected",
];

const ALLOWED_EVIDENCE_ROOTS = [
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

function normalize(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/`/g, "")
    .replace(/[_/]+/g, " ")
    .replace(/[^a-z0-9:. -]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function hasAny(source, markers) {
  const normalized = normalize(source);
  return markers.some((marker) => normalized.includes(normalize(marker)));
}

function sectionSource(markdown, headingMatcher) {
  const lines = markdown.split(/\r?\n/);
  const start = lines.findIndex((line) => /^#{1,4}\s+/.test(line) && headingMatcher.test(line));
  if (start === -1) return "";
  const out = [];
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^#{1,4}\s+/.test(lines[index])) break;
    out.push(lines[index]);
  }
  return out.join("\n");
}

function parseMarkdownTables(markdown) {
  const lines = markdown.split(/\r?\n/);
  const tables = [];
  for (let index = 0; index < lines.length; index += 1) {
    if (!/^\s*\|.+\|\s*$/.test(lines[index])) continue;
    if (!/^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$/.test(lines[index + 1] || "")) continue;

    const headers = splitTableRow(lines[index]).map(normalize);
    const rows = [];
    index += 2;
    while (index < lines.length && /^\s*\|.+\|\s*$/.test(lines[index])) {
      const cells = splitTableRow(lines[index]);
      const row = {};
      headers.forEach((header, headerIndex) => {
        row[header] = cells[headerIndex] || "";
      });
      rows.push(row);
      index += 1;
    }
    tables.push({ headers, rows });
    index -= 1;
  }
  return tables;
}

function splitTableRow(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((cell) => cell.trim());
}

function headerForField(headers, field) {
  return headers.find((header) => field.aliases.some((alias) => header.includes(normalize(alias))));
}

function statusIsExplicit(value) {
  return /\b(accept|accepted|approve|approved|pass|passed|block|blocked|fail|failed)\b/i.test(String(value || ""));
}

function evidenceRefs(source) {
  return Array.from(
    new Set(
      String(source)
        .match(/(?:accrue_admin\/test-results\/|accrue_admin\/playwright-report\/|\.planning\/phases\/192-idempotent-verification-sign-off\/)[^\s),\]|]+/g) ||
        []
    )
  );
}

function validEvidenceRef(ref) {
  if (!ref || path.isAbsolute(ref) || ref.includes("\\") || ref.split("/").includes("..")) return false;
  return ALLOWED_EVIDENCE_ROOTS.some((root) => ref.startsWith(root));
}

function validateArtifactLinks(markdown, failures) {
  for (const artifact of REQUIRED_ARTIFACTS) {
    if (!markdown.includes(artifact)) {
      failures.artifacts.push(`192-SIGN-OFF.md must link or literally reference ${artifact}.`);
    }
  }
}

function validateExecutiveSections(markdown, failures) {
  const normalized = normalize(markdown);
  const required = [
    { name: "executive status", markers: ["executive status"] },
    { name: "baseline comparison summary", markers: ["baseline comparison", "final score >= phase 187 baseline"] },
    { name: "CI guardrail status", markers: ["ci guardrail"] },
    { name: "curated gallery", markers: ["curated gallery"] },
    { name: "maintainer checklist", markers: ["maintainer checklist"] },
  ];

  for (const section of required) {
    if (!hasAny(normalized, section.markers)) {
      failures.structure.push(`Missing ${section.name} section/content required by D-30.`);
    }
  }

  const executive = sectionSource(markdown, /executive status/i) || markdown.slice(0, 1000);
  if (!/\b(pass|passed|fail|failed|blocked|approved|pending)\b/i.test(executive)) {
    failures.structure.push("Executive status must state explicit pass/fail/blocked/approved/pending outcome.");
  }
}

function validateGuardrails(markdown, failures) {
  const guardrailSource = sectionSource(markdown, /ci guardrail/i) || markdown;
  for (const guardrail of REQUIRED_GUARDRAILS) {
    if (!hasAny(guardrailSource, guardrail.markers)) {
      failures.guardrails.push(`Missing CI guardrail status for ${guardrail.name}.`);
    }
  }
  if (!/\b(pass|passed|fail|failed|required guardrail passed|required guardrail failed)\b/i.test(guardrailSource)) {
    failures.guardrails.push("CI guardrail status rows must include explicit pass/fail state.");
  }
}

function validateGallery(markdown, failures) {
  const gallerySource = sectionSource(markdown, /curated gallery/i);
  if (!gallerySource.trim()) {
    failures.gallery.push("Missing curated gallery section.");
    return;
  }

  const tables = parseMarkdownTables(gallerySource);
  const galleryTable = tables.find((table) =>
    GALLERY_FIELDS.every((field) => Boolean(headerForField(table.headers, field)))
  );

  if (!galleryTable) {
    failures.gallery.push(
      `Curated gallery must include rows with fields: ${GALLERY_FIELDS.map((field) => field.name).join(", ")}.`
    );
  } else if (galleryTable.rows.length === 0) {
    failures.gallery.push("Curated gallery table must contain at least one evidence-linked row.");
  } else {
    galleryTable.rows.forEach((row, index) => {
      for (const field of GALLERY_FIELDS) {
        const header = headerForField(galleryTable.headers, field);
        if (!String(row[header] || "").trim()) {
          failures.gallery.push(`Curated gallery row ${index + 1} missing ${field.name}.`);
        }
      }

      const evidenceHeader = headerForField(galleryTable.headers, GALLERY_FIELDS.find((field) => field.name === "evidence ref"));
      const statusHeader = headerForField(
        galleryTable.headers,
        GALLERY_FIELDS.find((field) => field.name === "accept/block status")
      );
      if (evidenceRefs(row[evidenceHeader]).length === 0) {
        failures.gallery.push(`Curated gallery row ${index + 1} must include a concrete evidence ref.`);
      }
      if (!statusIsExplicit(row[statusHeader])) {
        failures.gallery.push(`Curated gallery row ${index + 1} must include accept/block status.`);
      }
    });
  }

  for (const category of REQUIRED_GALLERY_CATEGORIES) {
    if (!normalize(gallerySource).includes(normalize(category))) {
      failures.gallery.push(`Curated gallery missing required JTBD/risk category: ${category}.`);
    }
  }
}

function validateTraceRefs(markdown, failures) {
  const traceSource = `${sectionSource(markdown, /trace/i)}\n${sectionSource(markdown, /curated gallery/i)}`;
  for (const category of TRACE_CATEGORIES) {
    if (!hasAny(traceSource, category.markers)) {
      failures.traces.push(`Missing trace ref category for ${category.name}.`);
      continue;
    }
    const line = traceSource
      .split(/\r?\n/)
      .find((candidate) => hasAny(candidate, category.markers));
    if (!line || evidenceRefs(line).length === 0) {
      failures.traces.push(`${category.name} must cite a deterministic trace/evidence ref.`);
    }
  }
}

function validateChecklist(markdown, failures) {
  const checklistSource = sectionSource(markdown, /maintainer checklist/i);
  if (!checklistSource.trim()) {
    failures.checklist.push("Missing maintainer checklist section.");
    return;
  }

  for (const category of CHECKLIST_CATEGORIES) {
    const line = checklistSource
      .split(/\r?\n/)
      .find((candidate) => hasAny(candidate, category.markers));
    if (!line) {
      failures.checklist.push(`Maintainer checklist missing required review category: ${category.name}.`);
      continue;
    }
    if (!/^\s*[-*]\s+\[[xX]\]/.test(line)) {
      failures.checklist.push(`Maintainer checklist category is not checked: ${category.name}.`);
    }
  }

  if (!/\b(final )?(maintainer )?(outcome|decision)\b/i.test(checklistSource)) {
    failures.checklist.push("Maintainer checklist must include an explicit maintainer outcome/decision.");
  }
  if (!statusIsExplicit(checklistSource)) {
    failures.checklist.push("Maintainer checklist outcome must be explicit accept/block/pass/fail.");
  }
  if (evidenceRefs(checklistSource).length === 0) {
    failures.checklist.push("Maintainer checklist must cite evidence refs.");
  }
}

function validateEvidenceRefs(markdown, failures) {
  const refs = evidenceRefs(markdown);
  if (refs.length === 0) {
    failures.evidence.push("192-SIGN-OFF.md must include concrete repo-relative evidence refs.");
  }
  for (const ref of refs) {
    if (!validEvidenceRef(ref)) {
      failures.evidence.push(`Invalid evidence ref: ${ref}`);
    }
  }
}

function failureCount(failures) {
  return Object.values(failures).reduce((sum, items) => sum + items.length, 0);
}

function reportFailures(failures) {
  console.error("Phase 192 sign-off verification failed.");
  for (const [section, items] of Object.entries(failures)) {
    if (items.length === 0) continue;
    console.error(`\n${section}:`);
    for (const item of items.slice(0, 40)) console.error(`- ${item}`);
    if (items.length > 40) console.error(`- ...and ${items.length - 40} more`);
  }
}

export function verifyPhase192Signoff(options = {}) {
  const signoffPath = options.signoffPath || DEFAULT_SIGNOFF_PATH;
  const markdown = options.markdown ?? readFile(signoffPath);
  const failures = {
    structure: [],
    artifacts: [],
    guardrails: [],
    gallery: [],
    traces: [],
    checklist: [],
    evidence: [],
  };

  validateExecutiveSections(markdown, failures);
  validateArtifactLinks(markdown, failures);
  validateGuardrails(markdown, failures);
  validateGallery(markdown, failures);
  validateTraceRefs(markdown, failures);
  validateChecklist(markdown, failures);
  validateEvidenceRefs(markdown, failures);

  return {
    ok: failureCount(failures) === 0,
    summary: {
      signoff_path: signoffPath,
      artifact_refs: REQUIRED_ARTIFACTS.filter((artifact) => markdown.includes(artifact)).length,
      evidence_refs: evidenceRefs(markdown).length,
    },
    failures,
  };
}

function positiveMarkdown() {
  const trace = (name) => `.planning/phases/192-idempotent-verification-sign-off/traces/${name}.zip`;
  const screenshot = ".planning/phases/192-idempotent-verification-sign-off/gallery/dashboard-health-light.png";
  const manifest = ".planning/phases/192-idempotent-verification-sign-off/artifacts.manifest.json";

  return `# Phase 192 Maintainer Sign-Off

## Executive Status

PASS - final scorecard package is ready for maintainer approval.

## Baseline Comparison Summary

Final score >= Phase 187 baseline for every comparable cell. Structured artifacts:
- .planning/phases/192-idempotent-verification-sign-off/final.cells.json
- .planning/phases/192-idempotent-verification-sign-off/scorecard.delta.json
- .planning/phases/192-idempotent-verification-sign-off/regressions.ndjson
- ${manifest}

## CI Guardrail Status

| Guardrail | Status | Evidence |
|---|---|---|
| baseline:parse | Required guardrail passed | accrue_admin/test-results/phase192/baseline-parse.log |
| verify_phase191_ax187_coverage | Required guardrail passed | accrue_admin/test-results/phase192/phase191-coverage.log |
| e2e:group-contracts | Required guardrail passed | accrue_admin/test-results/phase192/group-contracts.log |
| e2e:phase191 | Required guardrail passed | accrue_admin/test-results/phase192/phase191.log |
| e2e:a11y | Required guardrail passed | accrue_admin/test-results/phase192/a11y.log |
| reduced-motion | Required guardrail passed | accrue_admin/test-results/phase192/reduced-motion.log |
| component-lab coverage | Required guardrail passed | accrue_admin/test-results/phase192/component-lab.log |

## Curated Gallery

Categories covered: dashboard health scan; customer inspection; subscription triage/detail; invoice/payment review; webhook/event debugging; recovery campaign; component lab; modal open state; drawer open state; dropdown open state; empty state; error state; permission-denied state; disconnected/reconnecting state.

| who | job | route/surface | state | theme | viewport | evidence ref | why it matters | status |
|---|---|---|---|---|---|---|---|---|
| maintainer | dashboard health scan, customer inspection, subscription triage/detail, invoice/payment review, webhook/event debugging, recovery campaign, component lab, modal open state, drawer open state, dropdown open state, empty state, error state, permission-denied state, disconnected/reconnecting state | /billing and /billing/dev/components | default-populated, empty, error, permission-denied, disconnected-reconnecting, interactive-open | light and dark | desktop and mobile | ${screenshot} | proves the representative JTBD and historical-risk control gallery | accept |

## Trace Refs

- focus trap: ${trace("focus-trap")}
- focus restore: ${trace("focus-restore")}
- Escape: ${trace("escape")}
- outside click: ${trace("outside-click")}
- scroll reachability: ${trace("scroll-reachability")}
- LiveView patch focus: ${trace("liveview-patch-focus")}
- actionability: ${trace("actionability")}

## Maintainer Checklist

- [x] JTBD clarity - ${screenshot}
- [x] domain vocabulary - ${screenshot}
- [x] microcopy recovery - ${screenshot}
- [x] brand fit - ${screenshot}
- [x] accessible focus/contrast - ${trace("focus-trap")}
- [x] mobile usability - ${screenshot}
- [x] dark-mode role clarity - ${screenshot}
- [x] absence of backend-guts presentation - ${screenshot}
- [x] responsive layout - ${screenshot}
- [x] light/dark or system-theme behavior - ${screenshot}
- [x] interaction integrity - ${trace("actionability")}
- [x] focus/hover/disabled affordance - ${trace("focus-restore")}
- [x] information hierarchy - ${screenshot}
- [x] developer/operator DX - ${screenshot}

Final maintainer outcome: approved / accept, based on ${manifest}.
`;
}

function assertSelfTest(name, condition, details = "") {
  if (!condition) throw new Error(`Self-test failed: ${name}${details ? ` (${details})` : ""}`);
  console.log(`self-test pass: ${name}`);
}

function runSelfTest() {
  const positive = positiveMarkdown();
  const pass = verifyPhase192Signoff({ markdown: positive, signoffPath: "temp/192-SIGN-OFF.md" });
  assertSelfTest("positive sign-off exits 0", pass.ok, JSON.stringify(pass.failures));

  const missingArtifacts = verifyPhase192Signoff({
    markdown: positive.replace(/final\.cells\.json|scorecard\.delta\.json|regressions\.ndjson|artifacts\.manifest\.json/g, ""),
  });
  assertSelfTest("missing structured artifact links exits non-zero", !missingArtifacts.ok);
  assertSelfTest("artifact section reports failures", missingArtifacts.failures.artifacts.length >= 4);

  const missingGalleryField = verifyPhase192Signoff({
    markdown: positive.replace("| who | job | route/surface | state | theme | viewport | evidence ref | why it matters | status |", "| who | job | state | theme | viewport | evidence ref | status |"),
  });
  assertSelfTest("gallery missing required fields exits non-zero", !missingGalleryField.ok);
  assertSelfTest("gallery section reports field failures", missingGalleryField.failures.gallery.length > 0);

  const uncheckedChecklist = verifyPhase192Signoff({
    markdown: positive.replace("- [x] JTBD clarity", "- [ ] JTBD clarity").replace("Final maintainer outcome: approved / accept", "Final maintainer outcome:"),
  });
  assertSelfTest("unchecked or outcome-free checklist exits non-zero", !uncheckedChecklist.ok);
  assertSelfTest("checklist section reports failures", uncheckedChecklist.failures.checklist.length > 0);

  const missingTraces = verifyPhase192Signoff({
    markdown: positive.replace(/## Trace Refs[\s\S]*?## Maintainer Checklist/, "## Trace Refs\n\nScreenshot approval only.\n\n## Maintainer Checklist"),
  });
  assertSelfTest("screenshot-only approval without trace refs exits non-zero", !missingTraces.ok);
  assertSelfTest("trace section reports failures", missingTraces.failures.traces.length > 0);

  console.log("Phase 192 sign-off self-test passed.");
}

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--self-test") options.selfTest = true;
    else if (arg === "--signoff") options.signoffPath = path.resolve(argv[++index]);
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

  const result = verifyPhase192Signoff(options);
  console.log(
    `Phase 192 sign-off verifier: artifacts=${result.summary.artifact_refs}/${REQUIRED_ARTIFACTS.length}, evidence_refs=${result.summary.evidence_refs}`
  );

  if (!result.ok) {
    reportFailures(result.failures);
    process.exitCode = 1;
  } else {
    console.log("Phase 192 sign-off verification passed.");
  }

  return result;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main();
  } catch (error) {
    console.error(`Phase 192 sign-off verifier crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
