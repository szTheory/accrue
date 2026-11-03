#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import assert from "node:assert/strict";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import { renderAutomatedUat } from "./verify_executable_uat_contract.mjs";

export const PHASE_SLUG = "254-recurring-quality-reviewed-fixes-and-curation";
export const REQUIREMENT_IDS = Object.freeze(["CIQ-02", "CIQ-03", "CIQ-04", "UXQ-02", "UXQ-04", "CURATE-01", "CURATE-02"]);
export const EDGE_IDS = Object.freeze([
  "EDGE-UXQ-02-empty", "EDGE-UXQ-02-encoding", "EDGE-UXQ-04-boundary", "EDGE-UXQ-04-precision",
  "EDGE-CURATE-01-adjacency", "EDGE-CURATE-01-empty", "EDGE-CURATE-01-ordering", "EDGE-CURATE-01-concurrency",
]);
export const EDGE_BINDINGS = Object.freeze({
  "EDGE-UXQ-02-empty": {
    task_id: "254-11-02",
    source_path: "scripts/ci/verify_a11y_dispositions.test.mjs",
    test_identities: [
      "empty register: passes when every cell that ran evaluated at least one rule",
      "empty register: fails when one cell reports zero rules evaluated",
      "empty register: fails when no cell ran at all",
      "empty register: an absent register file fails closed",
      "empty register: an unparsable register file fails closed",
    ],
    execution_ref: "node --test scripts/ci/verify_a11y_dispositions.test.mjs",
  },
  "EDGE-UXQ-02-encoding": {
    task_id: "254-11-02",
    source_path: "scripts/ci/verify_a11y_dispositions.test.mjs",
    test_identities: [
      "encoding: names that differ only in ASCII whitespace normalize equal",
      "encoding: NFC and NFD forms of the same text stay distinct under code point comparison",
      "encoding: long synthetic Unicode identities differing only in the last code point are distinct",
    ],
    execution_ref: "verify_a11y_dispositions.test.mjs",
  },
  "EDGE-UXQ-04-boundary": {
    task_id: "254-12-01",
    source_path: "accrue_admin/e2e/subscription-design-phase254.spec.js",
    test_identities: ["DR-254-02:computed collection heading"],
    source_assertions: ["for (const width of [767, 768])", "window.innerWidth", ".toBe(width)"],
    execution_ref: "subscription-design-phase254.spec.js: 13 passed",
  },
  "EDGE-UXQ-04-precision": {
    task_id: "254-12-01",
    source_path: "accrue_admin/e2e/subscription-design-phase254.spec.js",
    test_identities: ["DR-254-02:computed collection heading"],
    source_assertions: ["getComputedStyle(probe)", ".toBe(expected[\"font-size\"])"],
    execution_ref: "subscription-design-phase254.spec.js: 13 passed",
  },
  "EDGE-CURATE-01-adjacency": {
    task_id: "254-04-01",
    source_path: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
    test_identities: ["duplicate evidence is exact block equality and any differing field keeps both subjects"],
    execution_ref: "subscription_manifest_test.exs via mix run --no-start",
  },
  "EDGE-CURATE-01-empty": {
    task_id: "254-04-01",
    source_path: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
    test_identities: ["curation records are sorted, shaped, grounded in the frozen baseline and refuse invalid input"],
    execution_ref: "subscription_manifest_test.exs via mix run --no-start",
  },
  "EDGE-CURATE-01-ordering": {
    task_id: "254-04-01",
    source_path: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
    test_identities: ["curation records are sorted, shaped, grounded in the frozen baseline and refuse invalid input"],
    execution_ref: "subscription_manifest_test.exs via mix run --no-start",
  },
  "EDGE-CURATE-01-concurrency": {
    task_id: "254-04-01",
    source_path: "accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs",
    test_identities: ["curation ledger regenerates byte-identically and an interrupted regeneration leaves the committed ledger intact"],
    execution_ref: "subscription_manifest_test.exs via mix run --no-start",
  },
});
export const AMENDMENT_IDS = Object.freeze(["AMD-254-01", "AMD-254-02", "AMD-254-03", "AMD-254-04", "AMD-254-05"]);
export const CHECKPOINT_TASK_IDS = Object.freeze(["254-03-01", "254-03-03", "254-15-02", "254-18-02"]);
export const UNRESOLVED_ASSUMPTION_IDS = Object.freeze([
  "EDGE-CIQ-02-unclassified", "EDGE-CIQ-03-unclassified", "EDGE-CIQ-04-unclassified", "EDGE-CURATE-02-unclassified",
]);
export const EDGE_DECISIONS = Object.freeze({
  "EDGE-CIQ-02-unclassified": "EDGE-CIQ-02 kept flagged: the probe assigned no edge category, so the D-10/D-14 fail-closed selector controls tested in 254-07 are cited as related coverage, not as its resolution.",
  "EDGE-CIQ-03-unclassified": "EDGE-CIQ-03 kept flagged: no probe category, while determinism, identity and mask-geometry edges are tested in 254-14 as related coverage.",
  "EDGE-CIQ-04-unclassified": "EDGE-CIQ-04 kept flagged: no probe category, while the warn_at/ceiling boundary sides and freeze rejections are tested in 254-09 as related coverage.",
  "EDGE-CURATE-02-unclassified": "EDGE-CURATE-02 kept flagged: no probe category, while gated-filter, tie-break, determinism and story-count-invariance are tested in 254-16 as related coverage.",
});

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const PLAN_DIR = `.planning/phases/${PHASE_SLUG}`;
const BUDGET_PATH = "accrue_admin/storybook/phase254-budget.json";
const VISUAL_CASES_PATH = "accrue_admin/storybook/phase254-visual-cases.json";
const VISUAL_MANIFEST_PATH = "accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json";
const DESIGN_REVIEW_PATH = `${PLAN_DIR}/254-DESIGN-REVIEW.json`;
const CURATION_PATH = "accrue_admin/storybook/subscription-curation.json";
const VALIDATION_PATH = `${PLAN_DIR}/254-VALIDATION.md`;
export const SUMMARY_NAMES = Object.freeze(Array.from({ length: 18 }, (_, index) => `254-${String(index + 1).padStart(2, "0")}-SUMMARY.md`));
const EXPECTED_RUBRIC = Object.freeze(["typography", "color", "hierarchy", "redundancy", "affordances", "microcopy", "journey"]);
const EVIDENCE_ONLY_AFTER_MEASUREMENT = new Set([
  BUDGET_PATH,
  ".planning/STATE.md",
  VALIDATION_PATH,
  `${PLAN_DIR}/254-18-SUMMARY.md`,
  `${PLAN_DIR}/254-UAT.md`,
  `${PLAN_DIR}/254-VERIFICATION.md`,
]);

function fail(message) { throw new Error(`Phase 254 acceptance: ${message}`); }
function sha256(value) { return crypto.createHash("sha256").update(value).digest("hex"); }
function exactSet(actual, expected, label) {
  if (!Array.isArray(actual)) fail(`${label} is not an array`);
  const left = [...actual].sort();
  const right = [...expected].sort();
  if (left.length !== actual.length || right.length !== expected.length || JSON.stringify(left) !== JSON.stringify(right)) {
    fail(`${label} mismatch (expected ${right.join(", ")}; found ${left.join(", ")})`);
  }
}
function object(value, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) fail(`${label} must be an object`);
  return value;
}
function safePath(root, relative, label = "evidence path") {
  if (typeof relative !== "string" || relative.length === 0 || path.isAbsolute(relative)) fail(`${label} must be repository-relative`);
  const normalized = relative.replaceAll("\\", "/");
  if (normalized.split("/").some((part) => !part || part === "." || part === "..")) fail(`${label} contains an unsafe path`);
  const absolute = path.resolve(root, normalized);
  const rel = path.relative(root, absolute);
  if (rel === ".." || rel.startsWith(`..${path.sep}`) || path.isAbsolute(rel)) fail(`${label} escapes the repository`);
  if (fs.existsSync(absolute)) {
    const real = path.relative(root, fs.realpathSync(absolute));
    if (real === ".." || real.startsWith(`..${path.sep}`) || path.isAbsolute(real)) fail(`${label} resolves outside the repository`);
  }
  return absolute;
}
function readJson(root, relative, label) {
  const file = safePath(root, relative, label);
  if (!fs.existsSync(file)) fail(`${label} is missing: ${relative}`);
  try { return JSON.parse(fs.readFileSync(file, "utf8")); }
  catch { fail(`${label} is malformed JSON: ${relative}`); }
}
function phaseFile(root, name) {
  const absolute = resolvePhaseEvidencePath(PHASE_SLUG, name, { root });
  return { absolute, source: fs.readFileSync(absolute, "utf8") };
}
function frontmatter(source, file) {
  const match = source.match(/^---\s*\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) fail(`${file} is missing YAML frontmatter`);
  return match[1];
}
function unquote(value) {
  const text = String(value ?? "").trim();
  return text.length >= 2 && ((text.startsWith('"') && text.endsWith('"')) || (text.startsWith("'") && text.endsWith("'"))) ? text.slice(1, -1) : text;
}
function scalar(source, key) {
  const match = source.match(new RegExp(`^${key}:\\s*(.*?)\\s*$`, "m"));
  return match ? unquote(match[1]) : undefined;
}
function listField(source, key, file) {
  const match = source.match(new RegExp(`^${key}:\\s*\\[([^\\]]*)\\]\\s*$`, "m"));
  if (!match) fail(`${file} has no finite ${key} list`);
  return match[1].split(",").map(unquote).filter(Boolean);
}

function parseTaskBlocks(source, planName, requirements, threatRefs, wave) {
  return [...source.matchAll(/<task\b[\s\S]*?<\/task>/g)].map((match) => {
    const block = match[0];
    const name = block.match(/<name>\s*(254-\d{2}-\d{2}):\s*([^<]+)<\/name>/);
    if (!name) fail(`${planName} contains a task without a Phase 254 ID`);
    const type = block.match(/<task\b[^>]*type="([^"]+)"/)?.[1] ?? "auto";
    const automated = block.match(/<automated>([\s\S]*?)<\/automated>/)?.[1]?.trim() ?? null;
    const files = block.match(/<files>([\s\S]*?)<\/files>/)?.[1]?.split(",").map((item) => item.trim()).filter(Boolean) ?? [];
    return {
      id: name[1],
      name: name[2].trim(),
      plan: planName.replace("-PLAN.md", ""),
      requirements: [...requirements],
      threat_refs: [...threatRefs],
      wave,
      type,
      files,
      automated,
      checkpoint: /<task\b[^>]*type="checkpoint:/.test(block),
    };
  });
}
function threatRefs(source) {
  return [...new Set([...source.matchAll(/\|\s*(T-254-[A-Z0-9-]+)\s*\|/g)].map((match) => match[1]))];
}
function unresolvedPlanAssumption(planSources, id) {
  return planSources.some(({ source }) => {
    const lines = source.split(/\r?\n/);
    const index = lines.findIndex((line) => line.trim() === `- id: ${id}`);
    if (index < 0) return false;
    const fields = [];
    for (const line of lines.slice(index + 1)) {
      if (/^\s+- id:/.test(line) || /^\S/.test(line)) break;
      fields.push(line);
    }
    return /^\s+status:\s*unresolved\s*$/m.test(fields.join("\n"));
  });
}

export function inspectPhase254Metadata({ root = ROOT } = {}) {
  const planFiles = fs.readdirSync(path.join(root, PLAN_DIR)).filter((name) => /^254-\d{2}-PLAN\.md$/.test(name)).sort();
  exactSet(planFiles, Array.from({ length: 18 }, (_, index) => `254-${String(index + 1).padStart(2, "0")}-PLAN.md`), "Phase 254 plans");
  const plans = planFiles.map((name) => {
    const { source } = phaseFile(root, name);
    const fm = frontmatter(source, name);
    if (scalar(fm, "phase") !== PHASE_SLUG) fail(`${name} belongs to another phase`);
    const requirements = listField(fm, "requirements", name);
    return { name, source, frontmatter: fm, requirements, tasks: parseTaskBlocks(source, name, requirements, threatRefs(source), scalar(fm, "wave")) };
  });
  const requirements = [...new Set(plans.flatMap((plan) => plan.requirements))].sort();
  exactSet(requirements, REQUIREMENT_IDS, "Phase 254 requirements");
  const tasks = plans.flatMap(({ tasks: planTasks }) => planTasks);
  exactSet(tasks.map(({ id }) => id), [...new Set(tasks.map(({ id }) => id))], "unique Phase 254 task IDs");
  for (const checkpointId of CHECKPOINT_TASK_IDS) {
    if (!tasks.some(({ id }) => id === checkpointId && tasks.find((task) => task.id === id).checkpoint)) fail(`checkpoint task is missing: ${checkpointId}`);
  }

  const probe = readJson(root, `${PLAN_DIR}/254-EDGE-PROBE.json`, "Phase 254 edge probe");
  if (!Array.isArray(probe.items)) fail("Phase 254 edge probe has no item inventory");
  const edgeName = ({ requirement_id: requirement, category }) => `EDGE-${requirement}-${category}`;
  const explicit = probe.items.filter((item) => item.status === "unresolved" && item.category !== "unclassified")
    .map(edgeName);
  exactSet(explicit, EDGE_IDS, "eight explicit Phase 254 edge truths");
  const unclassified = probe.items.filter((item) => item.status === "unresolved" && item.category === "unclassified").map(edgeName);
  exactSet(unclassified, UNRESOLVED_ASSUMPTION_IDS, "four unclassified Phase 254 assumptions");
  for (const id of UNRESOLVED_ASSUMPTION_IDS) if (!unresolvedPlanAssumption(plans, id)) fail(`${id} must remain unresolved in its plan`);

  const prohibitionStatements = [...new Set(plans.flatMap(({ frontmatter: fm }) =>
    [...fm.matchAll(/^\s+- statement:\s*["']?(MUST NOT[^\n"']+)["']?\s*$/gm)].map(([, statement]) => statement.trim())) )];
  const native = readJson(root, `${PLAN_DIR}/254-NATIVE-PROHIBITION-PROOF.json`, "native prohibition proof");
  if (!Array.isArray(native.checks)) fail("native prohibition proof has no checks");
  exactSet(prohibitionStatements, native.checks.map(({ projection }) => projection?.statement), "promoted prohibitions and native proof statements");
  return {
    requirements,
    tasks,
    edges: explicit,
    unclassified,
    unresolved_assumptions: UNRESOLVED_ASSUMPTION_IDS.map((id) => ({ id, status: "unresolved", decision: EDGE_DECISIONS[id] })),
    prohibition_statements: prohibitionStatements,
    plans,
  };
}

function extractCoverageBlock(fm, file) {
  const lines = fm.split(/\r?\n/);
  const start = lines.findIndex((line) => line === "coverage:");
  if (start < 0) fail(`${file} is missing executable coverage`);
  const blocks = [];
  let current = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[A-Za-z0-9_-]+:/.test(line)) break;
    if (/^  - id:/.test(line)) {
      if (current.length) blocks.push(current.join("\n"));
      current = [line];
    } else if (current.length) current.push(line);
  }
  if (current.length) blocks.push(current.join("\n"));
  return blocks;
}
function parseCoverage(block, file) {
  const id = block.match(/^\s+- id:\s*["']?([^\s"']+)/m)?.[1];
  const description = unquote(block.match(/^\s+description:\s*(.*?)\s*$/m)?.[1] ?? "");
  const requirement = block.match(/^\s+requirement:\s*([^\s#]+)/m)?.[1];
  const judgment = block.match(/^\s+human_judgment:\s*(true|false)\s*$/m)?.[1];
  const verification = [];
  const lines = block.split(/\r?\n/);
  let current = null;
  for (const line of lines) {
    const kind = line.match(/^\s+- kind:\s*(.*?)\s*$/);
    if (kind) {
      if (current) verification.push(current);
      current = { kind: unquote(kind[1]), ref: "", status: "" };
      continue;
    }
    const ref = line.match(/^\s+ref:\s*(.*?)\s*$/);
    if (ref && current) current.ref = unquote(ref[1]);
    const status = line.match(/^\s+status:\s*(.*?)\s*$/);
    if (status && current) current.status = unquote(status[1]);
  }
  if (current) verification.push(current);
  if (!id || !description || !requirement || judgment !== "false") fail(`${file} coverage must name a requirement and human_judgment: false`);
  if (verification.length === 0 || verification.some((item) => !item.ref || item.status !== "pass")) fail(`${file} coverage ${id} is missing executed green evidence`);
  return { id, description, requirement, human_judgment: false, verification };
}
function summaryPath(root, name) { return path.join(root, PLAN_DIR, name); }
export function pendingInputs({ root = ROOT } = {}) {
  return SUMMARY_NAMES.filter((name) => !fs.existsSync(summaryPath(root, name)));
}
function loadSummary(root, name) {
  const { absolute, source } = phaseFile(root, name);
  const fm = frontmatter(source, name);
  if (scalar(fm, "status") !== "complete") fail(`${name} must have status: complete`);
  const topJudgment = scalar(fm, "human_judgment");
  if (topJudgment !== undefined && topJudgment !== "false") fail(`${name} has human_judgment true`);
  const coverage = extractCoverageBlock(fm, name).map((block) => parseCoverage(block, name));
  if (coverage.length === 0) fail(`${name} has no executable coverage`);
  const completed = scalar(fm, "completed") ?? scalar(fm, "completed_date");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(completed ?? "")) fail(`${name} needs a deterministic completed date`);
  return { name, absolute, source, frontmatter: fm, status: "complete", human_judgment: scalar(fm, "human_judgment") ?? null, coverage, completed };
}
function currentValidationRows(root) {
  const source = fs.readFileSync(safePath(root, VALIDATION_PATH, "Phase 254 validation map"), "utf8");
  const rows = new Map();
  for (const line of source.split(/\r?\n/)) {
    if (!line.startsWith("| 254-")) continue;
    const cells = line.split("|").slice(1, -1).map((cell) => cell.trim());
    if (cells.length < 10 || !/^254-\d{2}-\d{2}$/.test(cells[0])) continue;
    rows.set(cells[0], { command: cells[7], status: cells[9], requirement: cells[3], threat_ref: cells[4] });
  }
  return rows;
}
function markdownCell(value) {
  return String(value ?? "—").replaceAll("|", "&#124;").replaceAll("\n", "<br>").trim() || "—";
}
export function writeValidationMap({ root = ROOT, greenTaskIds = [] } = {}) {
  const repository = fs.realpathSync(root);
  const metadata = inspectPhase254Metadata({ root: repository });
  const summaries = SUMMARY_NAMES.filter((name) => fs.existsSync(summaryPath(repository, name))).map((name) => loadSummary(repository, name));
  const summaryByPlan = new Map(summaries.map((summary) => [summary.name.replace("-SUMMARY.md", ""), summary]));
  const explicitGreen = new Set(greenTaskIds);
  const budgetFile = safePath(repository, BUDGET_PATH, "Phase 254 budget");
  const budget = fs.existsSync(budgetFile) ? JSON.parse(fs.readFileSync(budgetFile, "utf8")) : {};
  const cp = budget.metrics?.final ? checkpointAnswers(repository, budget, summaries) : {};
  const rows = metadata.tasks.map((task) => {
    const summary = summaryByPlan.get(task.plan);
    let green = summary?.coverage.length > 0 && summary.coverage.every((entry) => entry.human_judgment === false && entry.verification.every(({ status }) => status === "pass"));
    if (task.plan === "254-18") {
      if (task.id === "254-18-01") green = Array.isArray(budget.metrics?.final?.runs) && ["admin-phase200-guardrails", "browser-uat"].every((job) => budget.metrics.final.runs.some((run) => run.job === job && run.attempt === 1 && run.conclusion === "success" && run.phase_owned_ok === true));
      else if (task.id === "254-18-02") green = !!cp[task.id];
      else green = explicitGreen.has(task.id);
    }
    const command = task.automated ?? "node scripts/ci/generate_phase254_acceptance.mjs --latest --expect-pending 254-18";
    const exists = task.files.length === 0 ? "n/a" : task.files.every((relative) => fs.existsSync(safePath(repository, relative, `${task.id} owned file`))) ? "yes" : "no";
    if (exists === "no") green = false;
    return {
      task,
      cells: [task.id, task.plan, task.wave ?? "—", task.requirements.join(", "), task.threat_refs.join(", ") || "—", task.name, task.type, command, exists, green ? "✅ green" : "⬜ pending"],
      green,
    };
  });
  const source = fs.readFileSync(safePath(repository, VALIDATION_PATH, "Phase 254 validation map"), "utf8");
  const tableStart = source.indexOf("| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |");
  if (tableStart < 0) fail("Phase 254 validation map has no task table header");
  const tableEnd = source.indexOf("\n*Status:", tableStart);
  if (tableEnd < 0) fail("Phase 254 validation map has no status legend after its task table");
  const header = source.slice(tableStart, source.indexOf("\n", tableStart));
  const separator = source.slice(source.indexOf("\n", tableStart) + 1, source.indexOf("\n", source.indexOf("\n", tableStart) + 1));
  const body = rows.map(({ cells }) => `| ${cells.map(markdownCell).join(" | ")} |`).join("\n");
  const updatedTable = `${header}\n${separator}\n${body}`;
  let updated = `${source.slice(0, tableStart)}${updatedTable}${source.slice(tableEnd)}`;
  const allGreen = rows.every(({ green }) => green);
  updated = updated.replace(/^nyquist_compliant:\s*(?:true|false)\s*$/m, `nyquist_compliant: ${allGreen}`)
    .replace(/^wave_0_complete:\s*(?:true|false)\s*$/m, `wave_0_complete: ${allGreen}`);
  fs.writeFileSync(safePath(repository, VALIDATION_PATH, "Phase 254 validation map"), updated);
  return { task_count: rows.length, green_count: rows.filter(({ green }) => green).length, pending: rows.filter(({ green }) => !green).map(({ task }) => task.id), nyquist_compliant: allGreen, wave_0_complete: allGreen };
}
function taskEvidence(metadata, summaries, validationRows) {
  const result = {};
  for (const task of metadata.tasks) {
    const summary = summaries.find(({ name }) => name === `${task.plan}-SUMMARY.md`);
    const refs = summary?.coverage.flatMap((entry) => entry.verification.map(({ ref }) => ref)) ?? [];
    const row = validationRows.get(task.id);
    const validationCurrent = task.plan === "254-18" && row?.status === "✅ green" && row.command;
    const executed = refs.length > 0 || validationCurrent;
    const referenceText = refs.join("\n");
    const skipped = Number(referenceText.match(/\b(\d+)\s+skipped\b/i)?.[1] ?? 0);
    const retries = Number(referenceText.match(/\b(\d+)\s+(?:retries|retried)\b/i)?.[1] ?? 0);
    result[task.id] = {
      plan: task.plan,
      requirements: task.requirements,
      evidence_refs: refs.length > 0 ? refs : validationCurrent ? [row.command] : [],
      status: executed ? "pass" : "missing",
      skipped,
      retries,
      automated_command: task.automated ?? row?.command ?? "Checkpoint disposition checked by the Phase 254 acceptance verifier",
      threat_refs: task.threat_refs,
    };
  }
  return result;
}
function amendmentRows(root) {
  const ledger = readJson(root, CURATION_PATH, "subscription curation ledger");
  const cases = readJson(root, VISUAL_CASES_PATH, "visual cases");
  const design = readJson(root, DESIGN_REVIEW_PATH, "design review record");
  const found = [
    ...(ledger.amendments ?? []).map((amendment) => ({ ...amendment, source: CURATION_PATH })),
    ...(cases.amendments ?? []).map((amendment) => ({ ...amendment, source: VISUAL_CASES_PATH })),
    ...(design.amendments ?? []).map((amendment) => ({ ...amendment, source: DESIGN_REVIEW_PATH })),
  ];
  return { found, ledger, cases, design };
}
function manifestMintRuns(root) {
  const manifest = readJson(root, VISUAL_MANIFEST_PATH, "visual identity manifest");
  const entries = manifest.entries ?? manifest;
  return {
    manifest,
    keys: Object.keys(entries).sort(),
    mint_run_ids: [...new Set(Object.values(entries)
      .filter((entry) => entry && entry.provenance !== "phase211-committed" && entry.mint_run_id != null)
      .map((entry) => String(entry.mint_run_id)))].sort(),
  };
}
function commandText(root, command, args) {
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8", shell: false, timeout: 30_000 });
  if (result.status !== 0) fail(`${command} ${args.join(" ")} failed while checking current source identity`);
  return result.stdout.trim();
}
function testIdentityIsDeclared(source, sourcePath, identity) {
  if (sourcePath.endsWith(".exs")) return source.includes('test "' + identity + '" do');
  return source.includes('test("' + identity + '"') || source.includes("test(`" + identity);
}
export function checkpointAnswers(root, budget, summaries) {
  const prior = summaries.find(({ name }) => name === "254-03-SUMMARY.md")?.source ?? "";
  const checkpoint15 = phaseFile(root, "254-15-CHECKPOINT-LOG.md").source;
  const checkpoint03 = phaseFile(root, "254-03-CHECKPOINT-LOG.md").source;
  const latestEntries = (budget.deviations ?? []).filter(({ kind }) => kind === "final-triage").flatMap(({ entries }) => entries ?? []);
  const acceptedKnownReds = budget.known_reds?.filter((entry) => entry.decision === "accept-known-red") ?? [];
  const alreadyAccepted = (entry) => acceptedKnownReds.some((known) =>
    (entry.known_red_id && known.id === entry.known_red_id) ||
    (known.job === entry.job && known.step === entry.step && known.main_run_id === entry.main_run_id));
  const unresolvedEscalations = latestEntries.filter((entry) =>
    (["out-of-scope-branch-only", "environmental"].includes(entry.classification) || entry.owner_job_out_of_scope === true) && !alreadyAccepted(entry));
  const needsEscalation = unresolvedEscalations.length > 0;
  const summary18 = summaries.find(({ name }) => name === "254-18-SUMMARY.md")?.source ?? "";
  const answer18 = needsEscalation
    ? (summary18.match(/254-18-02[\s\S]{0,500}?\b(fix-in-phase|accept-known-red|halt)\b/)?.[1] ?? "")
    : (summary18 && /escalation not required/i.test(summary18) ? "not required" : "");
  return {
    "254-03-01": /push-approved/.test(prior) && /push-approved/.test(checkpoint03) ? "push-approved" : "",
    "254-03-03": /254-03-03 round 2/.test(prior) && /A[^\n]*fix-in-phase[^\n]*KR-254-05/.test(prior) && /B[^\n]*accept-known-red[^\n]*KR-254-06/.test(prior) ? "fix-in-phase; accept-known-red for KR-254-06" : "",
    "254-15-02": /fix-in-phase/.test(checkpoint15) && /accept-attributable/.test(checkpoint15) ? "fix-in-phase; accept-attributable" : "",
    "254-18-02": answer18,
    escalation_count: unresolvedEscalations.length,
  };
}

function collectEvidence(root) {
  const repository = fs.realpathSync(root);
  const metadata = inspectPhase254Metadata({ root: repository });
  const summaries = SUMMARY_NAMES.filter((name) => fs.existsSync(summaryPath(repository, name))).map((name) => loadSummary(repository, name));
  const validationRows = currentValidationRows(repository);
  const budget = readJson(repository, BUDGET_PATH, "Phase 254 budget");
  const { found: amendments, ledger, cases, design } = amendmentRows(repository);
  const { manifest, keys: manifest_keys, mint_run_ids } = manifestMintRuns(repository);
  const proof = readJson(repository, `${PLAN_DIR}/254-NATIVE-PROHIBITION-PROOF.json`, "native prohibition proof");
  const edgeEvidence = Object.fromEntries(EDGE_IDS.map((id) => {
    const binding = EDGE_BINDINGS[id];
    const summary = summaries.find(({ name }) => name === `${binding.task_id.slice(0, 6)}-SUMMARY.md`);
    const refs = summary?.coverage.flatMap((entry) => entry.verification.map(({ ref }) => ref)) ?? [];
    const matchingRefs = refs.filter((ref) => ref.includes(binding.execution_ref));
    const sourceFile = safePath(repository, binding.source_path, `${id} test source`);
    const source = fs.existsSync(sourceFile) ? fs.readFileSync(sourceFile, "utf8") : "";
    const identitiesPresent = binding.test_identities.every((identity) => testIdentityIsDeclared(source, binding.source_path, identity));
    const assertionsPresent = (binding.source_assertions ?? []).every((assertion) => source.includes(assertion));
    const executed = matchingRefs.length > 0 && identitiesPresent && assertionsPresent;
    return [id, {
      status: executed ? "pass" : "missing",
      task_id: binding.task_id,
      summary_name: `${binding.task_id.slice(0, 6)}-SUMMARY.md`,
      source_path: binding.source_path,
      source_sha256: source ? sha256(source) : null,
      test_identities: binding.test_identities,
      source_assertions: binding.source_assertions ?? [],
      refs: matchingRefs,
    }];
  }));
  const finalRuns = budget.metrics?.final?.runs ?? [];
  const liveSources = [
    "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
    "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
    "accrue_admin/assets/css/app.css",
    "accrue_admin/assets/css/theme.css",
    "accrue_admin/priv/static/accrue_admin.css",
    "accrue_admin/priv/static/storybook.css",
  ];
  const currentDigests = Object.fromEntries(liveSources.map((relative) => [relative, fs.existsSync(safePath(repository, relative)) ? sha256(fs.readFileSync(safePath(repository, relative))) : null]));
  const checkpointRecord = checkpointAnswers(repository, budget, summaries);
  const sourceAssetIdentities = Object.entries(design.assets ?? {}).flatMap(([key, asset]) => {
    if (!asset || typeof asset.path !== "string" || typeof asset.sha256 !== "string") return [];
    const file = safePath(repository, asset.path, `design asset ${key}`);
    return [{ key, path: asset.path, expected_sha256: asset.sha256, actual_sha256: fs.existsSync(file) ? sha256(fs.readFileSync(file)) : null }];
  });
  const visualAssetIdentities = Object.entries(manifest.entries ?? manifest).map(([key, entry]) => {
    const relative = `accrue_admin/e2e/__screenshots__/visual-desktop/${entry.file}`;
    const file = safePath(repository, relative, `visual baseline ${key}`);
    return { key, expected_sha256: entry.sha256, actual_sha256: fs.existsSync(file) ? sha256(fs.readFileSync(file)) : null };
  });
  const curationSourceIdentities = Object.entries(ledger.source_digests ?? {}).map(([relative, expected]) => {
    const file = safePath(repository, relative, "curation source digest");
    return { path: relative, expected_sha256: expected, actual_sha256: fs.existsSync(file) ? sha256(fs.readFileSync(file)) : null };
  });
  const trackedManifestPath = safePath(repository, "storybook/phase252-manifest.json", "tracked Phase 252 manifest");
  const currentManifestSha = fs.existsSync(trackedManifestPath) ? sha256(fs.readFileSync(trackedManifestPath)) : null;
  const measuredHead = budget.metrics?.final?.head_sha ?? null;
  const gitHead = commandText(repository, "git", ["rev-parse", "HEAD"]);
  const changedAfterMeasurement = measuredHead && /^[a-f0-9]{40}$/i.test(measuredHead)
    ? commandText(repository, "git", ["diff", "--name-only", `${measuredHead}..HEAD`]).split(/\r?\n/).filter(Boolean)
    : [];
  const measuredHeadIsAncestor = measuredHead && /^[a-f0-9]{40}$/i.test(measuredHead)
    ? spawnSync("git", ["merge-base", "--is-ancestor", measuredHead, "HEAD"], { cwd: repository, encoding: "utf8", shell: false }).status === 0
    : false;
  return {
    root: repository,
    metadata,
    summaries,
    tasks: taskEvidence(metadata, summaries, validationRows),
    edge_evidence: edgeEvidence,
    prohibitions: metadata.prohibition_statements.map((statement) => {
      const check = proof.checks.find(({ projection }) => projection?.statement === statement);
      const evidence = check?.result?.evidence ?? [];
      return { statement, status: check?.result?.status, fail_first: evidence.some((item) => item.failFirst && item.passed && item.failFirstProof === "violation-fixture"), proof: evidence };
    }),
    amendments,
    manifest: { keys: manifest_keys, mint_run_ids, entries: manifest.entries ?? manifest },
    visual_cases: cases,
    design_review: design,
    ledger,
    current_digests: currentDigests,
    identities: {
      source_assets: sourceAssetIdentities,
      visual_assets: visualAssetIdentities,
      curation_sources: curationSourceIdentities,
      current_manifest_sha256: currentManifestSha,
      budget_manifest_sha256: budget.manifest_sha256,
      measured_head: measuredHead,
      git_head: gitHead,
      measured_head_is_ancestor: measuredHeadIsAncestor,
      source_drift_after_measurement: changedAfterMeasurement.filter((relative) => !EVIDENCE_ONLY_AFTER_MEASUREMENT.has(relative)),
    },
    budget,
    checkpoints: Object.fromEntries(CHECKPOINT_TASK_IDS.map((id) => [id, checkpointRecord[id]])),
    escalation_count: checkpointRecord.escalation_count,
    final_runs: finalRuns,
  };
}
export const collectPhase254Evidence = collectEvidence;

export function validatePhase254Evidence(evidence) {
  object(evidence, "acceptance evidence");
  const metadata = object(evidence.metadata, "phase metadata");
  exactSet(metadata.requirements, REQUIREMENT_IDS, "requirement IDs");
  const taskIds = metadata.tasks.map((task) => task.id);
  if (!Array.isArray(evidence.summaries) || evidence.summaries.some((summary) => summary.status !== "complete" || summary.coverage.some((row) => row.human_judgment !== false || row.verification.some((verification) => verification.status !== "pass")))) {
    fail("a SUMMARY has missing or human-judgment-only acceptance evidence");
  }
  exactSet(Object.keys(evidence.tasks ?? {}), taskIds, "task evidence IDs");
  for (const task of metadata.tasks) {
    const row = object(evidence.tasks[task.id], `task evidence ${task.id}`);
    if (row.status !== "pass" || !Array.isArray(row.evidence_refs) || row.evidence_refs.length === 0) fail(`${task.id} has no executed green evidence`);
    if ((row.skipped ?? 0) !== 0) fail(`${task.id} evidence contains skipped tests`);
    if ((row.retries ?? 0) !== 0) fail(`${task.id} evidence contains retried tests`);
    exactSet(row.requirements, task.requirements, `${task.id} requirement bindings`);
    if (!row.automated_command) fail(`${task.id} has no executable verification command`);
  }
  exactSet(Object.keys(evidence.edge_evidence ?? {}), [...EDGE_IDS], "explicit edge evidence IDs");
  for (const id of EDGE_IDS) {
    const edge = evidence.edge_evidence[id];
    const binding = EDGE_BINDINGS[id];
    if (edge.status !== "pass" || edge.task_id !== binding.task_id || edge.summary_name !== `${binding.task_id.slice(0, 6)}-SUMMARY.md` || edge.source_path !== binding.source_path) fail(`${id} has no executed evidence from its bound task and source`);
    exactSet(edge.test_identities, binding.test_identities, `${id} test identities`);
    exactSet(edge.source_assertions ?? [], binding.source_assertions ?? [], `${id} source assertions`);
    if (!/^[a-f0-9]{64}$/i.test(edge.source_sha256 ?? "")) fail(`${id} test source identity is stale or missing`);
    const edgeSourcePath = safePath(evidence.root ?? ROOT, edge.source_path, `${id} test source`);
    if (!fs.existsSync(edgeSourcePath)) fail(`${id} test source is missing`);
    const edgeSource = fs.readFileSync(edgeSourcePath, "utf8");
    if (sha256(edgeSource) !== edge.source_sha256 || !binding.test_identities.every((identity) => testIdentityIsDeclared(edgeSource, binding.source_path, identity)) || !(binding.source_assertions ?? []).every((assertion) => edgeSource.includes(assertion))) fail(`${id} test source identity is stale`);
    if (!Array.isArray(edge.refs) || edge.refs.length === 0 || edge.refs.some((ref) => !ref.includes(binding.execution_ref))) fail(`${id} has no executed evidence from its bound test run`);
  }
  exactSet(evidence.metadata.unclassified, UNRESOLVED_ASSUMPTION_IDS, "unclassified assumptions");
  exactSet(evidence.metadata.unresolved_assumptions.map(({ id }) => id), UNRESOLVED_ASSUMPTION_IDS, "unresolved assumption output");
  for (const row of evidence.metadata.unresolved_assumptions) {
    if (row.status !== "unresolved" || row.decision !== EDGE_DECISIONS[row.id]) fail(`${row.id} must remain unresolved with its one-line decision`);
  }
  if (evidence.prohibitions.length !== 3 || evidence.prohibitions.some(({ status, fail_first }) => status !== "green" || fail_first !== true)) fail("all three prohibitions need native green and fail-first proof");

  const amendmentIds = evidence.amendments.map(({ id }) => id);
  const expectedAmendments = [...AMENDMENT_IDS];
  const mintRuns = evidence.manifest.mint_run_ids.map(String).sort();
  const amd06 = evidence.amendments.find(({ id }) => id === "AMD-254-06");
  if (mintRuns.length > 1 && !amd06) fail("AMD-254-06 is required when Phase 254 entries have multiple mint run IDs");
  if (amd06) expectedAmendments.push("AMD-254-06");
  exactSet(amendmentIds, expectedAmendments, "unconditional and conditional amendments");
  for (const id of expectedAmendments) {
    const amendment = evidence.amendments.find((item) => item.id === id);
    if (!amendment?.owner_ack || amendment.owner_ack.date !== "2026-10-28" || amendment.owner_ack.status !== "owner-accepted at plan time") fail(`${id} is missing the plan-time owner acknowledgment`);
  }
  if (amd06) exactSet((amd06.amended ?? []).map(String), mintRuns, "AMD-254-06 mint run identities");
  if (mintRuns.length > 1 && !amd06?.owner_decision) fail("AMD-254-06 needs its owner decision when multiple mint runs are present");

  const rubric = evidence.design_review?.rubric_verdicts?.map(({ dimension }) => dimension) ?? [];
  exactSet(rubric, EXPECTED_RUBRIC, "confirmed design review rubric dimensions");
  if (evidence.design_review.stage !== "confirmed") fail("design review record is not confirmed");
  for (const item of evidence.identities.source_assets) {
    if (!item.actual_sha256 || item.actual_sha256 !== item.expected_sha256) fail(`design review source asset is stale: ${item.path}`);
  }
  for (const item of evidence.identities.visual_assets) {
    if (!item.actual_sha256 || item.actual_sha256 !== item.expected_sha256) fail(`visual baseline asset is stale: ${item.key}`);
  }
  for (const item of evidence.identities.curation_sources) {
    if (!item.actual_sha256 || item.actual_sha256 !== item.expected_sha256) fail(`curation source identity is stale: ${item.path}`);
  }
  if (evidence.identities.current_manifest_sha256 !== evidence.identities.budget_manifest_sha256) fail("budget manifest digest is stale");
  if (!evidence.identities.measured_head_is_ancestor || evidence.identities.source_drift_after_measurement.length > 0) fail("final measurement is stale or source files changed after its observed head");
  const expectedVisualKeys = evidence.visual_cases?.cases?.map(({ key }) => key) ?? [];
  if (expectedVisualKeys.length === 0 || evidence.manifest.keys.length !== expectedVisualKeys.length + 12) fail("visual manifest key count differs from the 12 retained Phase 211 keys plus Phase 254 cases");
  for (const key of expectedVisualKeys) if (!evidence.manifest.keys.includes(key)) fail(`visual case is missing from the identity manifest: ${key}`);
  for (const capture of evidence.design_review.captures ?? []) {
    const entry = evidence.manifest.entries[capture.key];
    if (!entry || entry.sha256 !== capture.png_sha256) fail(`design review capture is stale or missing from the manifest: ${capture.key}`);
  }
  const isolation = evidence.tasks["254-05-01"]?.evidence_refs?.join("\n") ?? "";
  const fanout = (evidence.budget.deviations ?? []).some((item) => item.kind === "ciq02-fanout-enabled" || item.kind === "ciq02-fanout-deferred");
  if (!/403/.test(isolation) || !/isolation/.test(isolation) || !/interleav|race|reconcil|dependent/i.test(evidence.tasks["254-05-02"]?.evidence_refs?.join("\n") ?? "") || !/pure-story|classifier|ownership/i.test(evidence.tasks["254-02-03"]?.evidence_refs?.join("\n") ?? "") || !fanout) {
    fail("CIQ-02 isolation evidence or the Phase 254 fan-out record is missing");
  }
  exactSet(Object.keys(evidence.checkpoints), CHECKPOINT_TASK_IDS, "checkpoint answer IDs");
  for (const id of CHECKPOINT_TASK_IDS) if (!evidence.checkpoints[id]) fail(`${id} has no recorded answer`);
  if (evidence.checkpoints["254-18-02"] === "not required" && evidence.escalation_count !== 0) fail("254-18-02 cannot be marked not required while an escalation is present");

  const budget = object(evidence.budget, "budget record");
  const final = object(budget.metrics?.final, "final CI measurement");
  const runs = evidence.final_runs;
  if (!Array.isArray(runs) || runs.length === 0) fail("final attempt-1 runs are missing");
  const ownerIds = ["admin-phase200-guardrails", "browser-uat"];
  for (const owner of ownerIds) {
    if (!runs.some((run) => run.job === owner && run.attempt === 1 && run.conclusion === "success" && run.phase_owned_ok === true)) fail(`${owner} has no successful attempt-1 phase-owned run`);
  }
  if (runs.some((run) => run.attempt !== 1 || run.head_sha !== final.head_sha)) fail("final run is retried or belongs to a different source head");
  if (budget.deviations?.some((deviation) => !["resolved", "accepted"].includes(deviation.status))) fail("an open budget deviation remains");
  for (const metric of [budget.metrics.visual, budget.metrics.a11y]) {
    if (!metric || typeof metric.added_s !== "number" || typeof metric.per_cell?.p90_ms !== "number") fail("final visual or a11y cost metric is incomplete");
  }
  const runIds = new Set(runs.map(({ run_id }) => String(run_id)));
  if (!runIds.has(String(budget.metrics.visual.run_id)) || !runIds.has(String(budget.metrics.a11y.run_id))) fail("visual or a11y metric refers to a stale final run");
  if (!budget.deviations.some((item) => item.kind === "a11y-cell-budget-freeze")) fail("a11y cell budget freeze deviation is missing");
  const finalTriage = budget.deviations.filter((item) => item.kind === "final-triage").flatMap((item) => item.entries ?? []);
  const acceptedRed = (entry) => (budget.known_reds ?? []).some((known) =>
    known.decision === "accept-known-red" && ((entry.known_red_id && known.id === entry.known_red_id) ||
      (known.job === entry.job && known.step === entry.step && known.main_run_id === entry.main_run_id)));
  for (const entry of finalTriage) {
    if (!["in-scope", "pre-existing-on-main", "out-of-scope-branch-only", "environmental"].includes(entry.classification)) fail("final triage has an unknown red classification");
    if (entry.classification === "pre-existing-on-main" && !entry.main_run_id) fail("pre-existing red has no main run identity");
    if (entry.classification === "in-scope" && (!entry.fixed_in_sha || !entry.followup_run_id)) fail("in-scope red has no fix and follow-up attempt-1 identity");
    if (["out-of-scope-branch-only", "environmental"].includes(entry.classification) && !entry.decision && !acceptedRed(entry)) fail(`unmatched ${entry.classification} red requires the 254-18-02 owner decision`);
    if (entry.owner_job_out_of_scope === true) fail("an out-of-scope red remains inside a required owner job");
  }
  for (const run of runs.filter((row) => row.conclusion !== "success")) {
    if (!finalTriage.some((entry) => entry.run_id === run.run_id && (entry.decision || entry.main_run_id || entry.known_red_id || acceptedRed(entry)))) fail(`red run ${run.run_id} has no triage disposition`);
  }
  return {
    status: "passed",
    phase: "254",
    human_judgment: false,
    requirements: [...REQUIREMENT_IDS],
    tasks: taskIds,
    task_evidence: evidence.tasks,
    explicit_edges: [...EDGE_IDS].map((id) => ({
      id,
      task_id: evidence.edge_evidence[id].task_id,
      summary_name: evidence.edge_evidence[id].summary_name,
      source_path: evidence.edge_evidence[id].source_path,
      source_sha256: evidence.edge_evidence[id].source_sha256,
      test_identities: evidence.edge_evidence[id].test_identities,
      source_assertions: evidence.edge_evidence[id].source_assertions,
      evidence_refs: evidence.edge_evidence[id].refs,
    })),
    unresolved_assumptions: evidence.metadata.unresolved_assumptions,
    prohibitions: evidence.prohibitions,
    amendments: expectedAmendments.map((id) => ({ id, source: evidence.amendments.find((row) => row.id === id).source })),
    checkpoints: Object.fromEntries(CHECKPOINT_TASK_IDS.map((id) => [id, evidence.checkpoints[id]])),
    final_source_head: final.head_sha,
    final_runs: runs,
    manifest_keys: evidence.manifest.keys,
    manifest_mint_run_ids: mintRuns,
    rubric_dimensions: rubric,
  };
}

export function validateCompletedSummaries({ root = ROOT } = {}) {
  const missing = pendingInputs({ root });
  if (missing.length > 0) fail(`completed summaries are missing: ${missing.join(", ")}`);
  const summaries = SUMMARY_NAMES.map((name) => loadSummary(root, name));
  return { phaseDir: path.join(root, PLAN_DIR), summaries, coverage: summaries.flatMap(({ name, coverage }) => coverage.map((entry) => ({ file: name, ...entry }))), started: summaries.map(({ completed }) => completed).sort()[0], updated: summaries.map(({ completed }) => completed).sort().at(-1) };
}
export function renderUat(summarySet) {
  const generated = renderAutomatedUat(summarySet.phaseDir);
  return generated;
}
export function generatePhase254Acceptance({ root = ROOT, latest = false, writeUat = false } = {}) {
  if (!latest) fail("usage: node generate_phase254_acceptance.mjs --latest [--write-uat] [--expect-pending 254-18]");
  const missing = pendingInputs({ root });
  if (writeUat && missing.length > 0) fail(`refusing to generate 254-UAT.md while summaries are pending: ${missing.join(", ")}`);
  const evidence = validatePhase254Evidence(collectEvidence(root));
  if (writeUat) {
    const summarySet = validateCompletedSummaries({ root });
    const output = renderUat(summarySet);
    const destination = path.join(summarySet.phaseDir, "254-UAT.md");
    fs.writeFileSync(destination, output, { mode: 0o600 });
    return { evidence, pending: [], uat_written: true, uat_path: path.relative(root, destination).split(path.sep).join("/") };
  }
  return { evidence, pending: missing, uat_written: false, uat_path: null };
}

function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--latest")) fail("--latest is required");
  const writeUat = args.includes("--write-uat");
  const pendingIndex = args.indexOf("--expect-pending");
  const expectedPending = pendingIndex < 0 ? undefined : args[pendingIndex + 1];
  if (pendingIndex >= 0 && !expectedPending) fail("--expect-pending requires a plan id");
  const result = generatePhase254Acceptance({ root: ROOT, latest: true, writeUat });
  if (expectedPending) exactSet(result.pending, [`254-${expectedPending.slice(-2)}-SUMMARY.md`], "expected pending summary inputs");
  if (!expectedPending && result.pending.length > 0 && !writeUat) fail(`pending summaries: ${result.pending.join(", ")}`);
  process.stdout.write(`${JSON.stringify({ ...result.evidence, pending_inputs: result.pending, uat_written: result.uat_written, uat_path: result.uat_path }, null, 2)}\n`);
}

let invokedAsEntrypoint = false;
try { invokedAsEntrypoint = isMainModule(import.meta.url); } catch { invokedAsEntrypoint = false; }
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  test("Phase 254 identities are unique and include all seven requirements", () => {
    const metadata = inspectPhase254Metadata({ root: ROOT });
    assert.equal(metadata.requirements.length, 7);
    assert.equal(new Set(metadata.tasks.map(({ id }) => id)).size, metadata.tasks.length);
    assert.deepEqual(metadata.unclassified, [...UNRESOLVED_ASSUMPTION_IDS]);
  });
} else if (invokedAsEntrypoint) {
  try { main(); } catch (error) {
    process.stderr.write(`generate_phase254_acceptance: ${error.message}\n`);
    process.exitCode = 2;
  }
}
