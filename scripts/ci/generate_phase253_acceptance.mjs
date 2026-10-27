#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";
import { UNCLASSIFIED_EDGE_IDS as PHASE252_UNCLASSIFIED_EDGE_IDS } from "./generate_phase252_acceptance.mjs";
import {
  buildCommandPlan,
  expectedBrowserCellKeys,
  REQUIRED_COMMAND_IDS,
  validateLaneEvidence,
} from "./verify_phase253_compositions.mjs";

export const PHASE_SLUG = "253-real-groups-and-a-whole-subscription-job";
export const REQUIREMENT_IDS = Object.freeze(["SBK-04", "SBK-05", "SBK-06", "UXQ-01", "UXQ-03"]);
export const TASK_IDS = Object.freeze([
  "253-01-01", "253-01-02", "253-02-01", "253-02-02", "253-03-01", "253-03-02",
  "253-04-01", "253-04-02", "253-05-01", "253-05-02", "253-05-03",
  "253-06-01", "253-06-02", "253-06-03",
]);
export const EDGE_IDS = Object.freeze([
  "EDGE-SBK-04-adjacency", "EDGE-SBK-04-boundary", "EDGE-SBK-04-empty", "EDGE-SBK-04-ordering", "EDGE-SBK-04-precision",
  "EDGE-SBK-06-adjacency", "EDGE-SBK-06-empty", "EDGE-SBK-06-ordering",
  "EDGE-UXQ-03-empty", "EDGE-UXQ-03-encoding",
]);
export const CURRENT_UNCLASSIFIED_IDS = Object.freeze(["EDGE-SBK-05-unclassified", "EDGE-UXQ-01-unclassified"]);
export const HISTORICAL_UNCLASSIFIED_IDS = Object.freeze([...PHASE252_UNCLASSIFIED_EDGE_IDS]);
export const UI_IDS = Object.freeze([
  "UI-E1-empty", "UI-E1-error", "UI-E1-loading", "UI-E1-long-text", "UI-E1-overflow", "UI-E1-partial", "UI-E1-populated", "UI-E1-zero-one-many",
  "UI-E2-empty", "UI-E2-error", "UI-E2-loading", "UI-E2-long-text", "UI-E2-overflow", "UI-E2-partial", "UI-E2-populated", "UI-E2-zero-one-many",
  "UI-E3-empty", "UI-E3-error", "UI-E3-loading", "UI-E3-long-text", "UI-E3-overflow", "UI-E3-partial",
  "UI-E4-error", "UI-E4-loading", "UI-E4-long-text", "UI-E4-overflow",
]);
export const PROHIBITION_STATEMENTS = Object.freeze([
  "MUST NOT present settled subscription story or lab rendering as proof of mounted authority, persistence, action dispatch or provider completion.",
  "MUST NOT describe synthetic collection and held-out stress facts as representative customer behavior or real adopter usage evidence.",
]);

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const RESULT_ROOT = "accrue_admin/tmp/phase253/ci-results";
const MANIFEST_PATH = "accrue_admin/tmp/phase253/manifest.json";
const BROWSER_RESULT_ROOT = "accrue_admin/tmp/phase253";
const TRACKED_PHASE252_MANIFEST = "storybook/phase252-manifest.json";
const HISTORICAL_SUMMARY = "252-08-SUMMARY.md";
const PHASE_PLAN_FILES = Object.freeze(Array.from({ length: 6 }, (_, index) => `253-0${index + 1}-PLAN.md`));
const SUMMARY_FILES = Object.freeze(Array.from({ length: 6 }, (_, index) => `253-0${index + 1}-SUMMARY.md`));
const EXPECTED_PROHIBITIONS = Object.freeze([
  {
    statement: PROHIBITION_STATEMENTS[0],
    check_kind: "node-test",
    check_target: "scripts/ci/verify_phase253_presentation.test.mjs",
    check_violation_fixture: "scripts/ci/fixtures/phase253-transparency/presentation-violation.json",
    check_clean_fixture: "scripts/ci/fixtures/phase253-transparency/clean.json",
  },
  {
    statement: PROHIBITION_STATEMENTS[1],
    check_kind: "node-test",
    check_target: "scripts/ci/verify_phase253_presentation.test.mjs",
    check_violation_fixture: "scripts/ci/fixtures/phase253-transparency/attribution-violation.json",
    check_clean_fixture: "scripts/ci/fixtures/phase253-transparency/clean.json",
  },
]);

export function expectedAssertionReferences(spec) {
  const bindings = spec?.assertion_bindings;
  if (bindings && typeof bindings === "object" && !Array.isArray(bindings) && Object.keys(bindings).length > 0) {
    return Object.keys(bindings);
  }
  return Array.isArray(spec?.process_markers) ? spec.process_markers : [];
}

const REQUIREMENT_BINDINGS = Object.freeze({
  "SBK-04": [
    ["phase253-manifest-contract", "collection_manifest_identity"],
    ["phase253-manifest-contract", "ten_collection_variations"],
    ["phase253-collection-live", "collection_transport"],
    ["phase253-collection-live", "cursor_and_owner_boundary"],
    ["phase253-collection-live", "datatable_recovery_and_accessibility"],
    ["phase253-collection-live", "collection_state_projection"],
    ["phase253-compositions-browser", "collection_render_cells"],
    ["phase253-compositions-browser", "collection_synthetic_stress"],
    ["phase253-compositions-browser", "geometry_negative_controls"],
  ],
  "SBK-05": [
    ["phase253-manifest-contract", "nine_page_variations"],
    ["phase253-page-slice", "shared_production_page_renderer"],
    ["phase253-page-slice", "full_page_states"],
    ["phase253-page-slice", "related_resource_omission"],
    ["phase253-story-slice", "active_production_story"],
    ["phase253-story-slice", "story_input_validation"],
    ["phase253-compositions-browser", "page_composition_cells"],
    ["phase253-compositions-browser", "page_synthetic_stress"],
  ],
  "SBK-06": [
    ["phase253-mounted-job-live", "end_to_end_job_and_inert_dismissals"],
    ["phase253-mounted-job-live", "mounted_authority_and_freshness"],
    ["phase253-mounted-job-live", "action_effect_and_safe_return"],
    ["phase253-compositions-browser", "page_composition_cells"],
  ],
  "UXQ-01": [
    ["phase253-compositions-browser", "collection_render_cells"],
    ["phase253-compositions-browser", "collection_synthetic_stress"],
    ["phase253-compositions-browser", "page_composition_cells"],
    ["phase253-compositions-browser", "page_synthetic_stress"],
    ["phase253-compositions-browser", "geometry_negative_controls"],
  ],
  "UXQ-03": [
    ["phase253-manifest-contract", "source_digest_and_negative_controls"],
    ["phase253-page-slice", "full_page_states"],
    ["phase253-story-slice", "story_input_validation"],
    ["phase253-collection-live", "collection_state_projection"],
    ["phase253-mounted-job-live", "mounted_authority_and_freshness"],
    ["phase253-mounted-job-live", "action_effect_and_safe_return"],
    ["phase253-presentation-contract", "malformed_and_missing_subject_rejection"],
    ["phase253-compositions-browser", "collection_synthetic_stress"],
    ["phase253-compositions-browser", "page_synthetic_stress"],
  ],
});

const TASK_BINDINGS = Object.freeze({
  "253-01-01": [["phase253-collection-live", "collection_transport"], ["phase253-collection-live", "cursor_and_owner_boundary"], ["phase253-story-slice", "active_production_story"]],
  "253-01-02": [["phase253-manifest-contract", "collection_manifest_identity"], ["phase253-manifest-contract", "source_digest_and_negative_controls"], ["phase253-compositions-browser", "collection_render_cells"], ["phase253-compositions-browser", "manifest_reconciliation"]],
  "253-02-01": [["phase253-collection-live", "collection_state_projection"], ["phase253-collection-live", "datatable_recovery_and_accessibility"]],
  "253-02-02": [["phase253-collection-live", "cursor_and_owner_boundary"], ["phase253-collection-live", "collection_transport"]],
  "253-03-01": [["phase253-page-slice", "shared_production_page_renderer"], ["phase253-page-slice", "full_page_states"]],
  "253-03-02": [["phase253-page-slice", "related_resource_omission"], ["phase253-story-slice", "story_input_validation"], ["phase253-compositions-browser", "page_composition_cells"]],
  "253-04-01": [["phase253-mounted-job-live", "end_to_end_job_and_inert_dismissals"], ["phase253-mounted-job-live", "action_effect_and_safe_return"]],
  "253-04-02": [["phase253-mounted-job-live", "mounted_authority_and_freshness"], ["phase253-mounted-job-live", "action_effect_and_safe_return"]],
  "253-05-01": [["phase253-compositions-browser", "collection_render_cells"], ["phase253-compositions-browser", "geometry_negative_controls"], ["phase253-compositions-browser", "collection_synthetic_stress"]],
  "253-05-02": [["phase253-compositions-browser", "page_composition_cells"], ["phase253-compositions-browser", "page_synthetic_stress"], ["phase253-mounted-job-live", "action_effect_and_safe_return"]],
  "253-05-03": [["phase253-presentation-contract", "current_and_clean_source_identity"], ["phase253-presentation-contract", "malformed_and_missing_subject_rejection"], ["phase253-transparency-controls", "phase253_current_green"], ["phase253-transparency-controls", "phase253_clean_green"], ["phase253-transparency-controls", "phase253_static_violation_red"], ["phase253-transparency-controls", "phase253_synthetic_violation_red"]],
  "253-06-01": [["bundle", "all_required_commands_passed"], ["phase253-compositions-browser", "manifest_reconciliation"]],
  "253-06-02": [["phase253-ci-contract", "new_root_admission"], ["phase253-ci-contract", "required_owner_execution"], ["phase253-ci-contract", "unrelated_path_negative_control"]],
  "253-06-03": [["phase253-acceptance-contract", "complete_phase_mapping"], ["phase253-acceptance-contract", "unresolved_assumptions_preserved"], ["phase253-acceptance-contract", "native_prohibition_projection"], ["phase253-acceptance-contract", "premature_uat_rejected"]],
});

const EDGE_BINDINGS = Object.freeze({
  "EDGE-SBK-04-adjacency": [["phase253-collection-live", "cursor_and_owner_boundary"]],
  "EDGE-SBK-04-boundary": [["phase253-collection-live", "cursor_and_owner_boundary"]],
  "EDGE-SBK-04-empty": [["phase253-collection-live", "collection_state_projection"]],
  "EDGE-SBK-04-ordering": [["phase253-collection-live", "collection_transport"], ["phase253-collection-live", "datatable_recovery_and_accessibility"]],
  "EDGE-SBK-04-precision": [["phase253-collection-live", "collection_state_projection"]],
  "EDGE-SBK-06-adjacency": [["phase253-mounted-job-live", "mounted_authority_and_freshness"]],
  "EDGE-SBK-06-empty": [["phase253-mounted-job-live", "end_to_end_job_and_inert_dismissals"]],
  "EDGE-SBK-06-ordering": [["phase253-mounted-job-live", "action_effect_and_safe_return"]],
  "EDGE-UXQ-03-empty": [["phase253-collection-live", "collection_state_projection"], ["phase253-page-slice", "full_page_states"]],
  "EDGE-UXQ-03-encoding": [["phase253-mounted-job-live", "action_effect_and_safe_return"], ["phase253-compositions-browser", "collection_synthetic_stress"]],
});

function uiBindings(id) {
  const match = id.match(/^UI-(E[1-4])-(.+)$/);
  if (!match) fail(`unsupported UI criterion ID: ${id}`);
  const [, surface, category] = match;
  const refs = [];
  if (surface === "E1") {
    refs.push(["phase253-compositions-browser", category === "long-text" ? "collection_synthetic_stress" : "collection_render_cells"]);
    if (category === "overflow") refs.push(["phase253-compositions-browser", "geometry_negative_controls"]);
    if (category !== "long-text" && category !== "overflow") refs.push(["phase253-collection-live", category === "error" || category === "loading" ? "datatable_recovery_and_accessibility" : "collection_state_projection"]);
  } else if (surface === "E2") {
    refs.push(["phase253-compositions-browser", category === "long-text" ? "page_synthetic_stress" : "page_composition_cells"]);
    if (category === "empty" || category === "zero-one-many") refs.push(["phase253-page-slice", "related_resource_omission"]);
    if (category === "error") refs.push(["phase253-mounted-job-live", "mounted_authority_and_freshness"]);
    if (category === "loading" || category === "partial" || category === "populated") refs.push(["phase253-page-slice", "full_page_states"]);
  } else if (surface === "E3") {
    refs.push(["phase253-compositions-browser", category === "long-text" ? "page_synthetic_stress" : "page_composition_cells"]);
    if (category === "empty") refs.push(["phase253-mounted-job-live", "end_to_end_job_and_inert_dismissals"]);
    if (category === "error") refs.push(["phase253-mounted-job-live", "mounted_authority_and_freshness"]);
    if (category === "loading" || category === "partial") refs.push(["phase253-mounted-job-live", "action_effect_and_safe_return"]);
  } else {
    refs.push(["phase253-compositions-browser", category === "long-text" ? "page_synthetic_stress" : "page_composition_cells"]);
    refs.push(["phase253-mounted-job-live", "action_effect_and_safe_return"]);
  }
  return refs;
}

function fail(message) {
  throw new Error(`Phase 253 acceptance: ${message}`);
}

function sha256(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

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

function safeRepoPath(root, relativePath, label = "evidence path") {
  if (typeof relativePath !== "string" || relativePath.length === 0 || path.isAbsolute(relativePath)) {
    fail(`${label} must be a repository-relative path`);
  }
  const normalized = relativePath.replaceAll("\\", "/");
  if (normalized.split("/").some((part) => !part || part === "." || part === "..")) fail(`${label} contains an unsafe path segment`);
  const rootPath = fs.realpathSync(root);
  const absolute = path.resolve(rootPath, normalized);
  const relative = path.relative(rootPath, absolute);
  if (relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) fail(`${label} escapes the repository`);
  if (fs.existsSync(absolute)) {
    const actual = fs.realpathSync(absolute);
    const actualRelative = path.relative(rootPath, actual);
    if (actualRelative === ".." || actualRelative.startsWith(`..${path.sep}`) || path.isAbsolute(actualRelative)) fail(`${label} resolves outside the repository`);
  }
  return absolute;
}

function readJson(root, relativePath, label) {
  const absolute = safeRepoPath(root, relativePath, label);
  if (!fs.existsSync(absolute)) fail(`${label} is missing: ${relativePath}`);
  try { return JSON.parse(fs.readFileSync(absolute, "utf8")); }
  catch { fail(`${label} is malformed JSON: ${relativePath}`); }
}

function readPhaseArtifact(root, artifactPath) {
  const absolute = resolvePhaseEvidencePath(PHASE_SLUG, artifactPath, { root });
  return { absolute, source: fs.readFileSync(absolute, "utf8") };
}

function extractFrontmatter(source, file) {
  const match = source.match(/^---\s*\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) fail(`${file} is missing YAML frontmatter`);
  return match[1];
}

function unquote(value) {
  const text = value.trim();
  return text.length >= 2 && ((text.startsWith('"') && text.endsWith('"')) || (text.startsWith("'") && text.endsWith("'")))
    ? text.slice(1, -1)
    : text;
}

function scalar(frontmatter, key) {
  const match = frontmatter.match(new RegExp(`^${key}:\\s*(.*?)\\s*$`, "m"));
  return match ? unquote(match[1]) : undefined;
}

export function completedSummaryDate(frontmatter) {
  const topLevel = scalar(frontmatter, "completed") || scalar(frontmatter, "completed_date");
  if (topLevel) return topLevel;
  const nested = frontmatter.match(/^[ \t]+completed_date:\s*(.*?)\s*$/m);
  return nested ? unquote(nested[1]) : undefined;
}

function listField(frontmatter, key, file) {
  const match = frontmatter.match(new RegExp(`^${key}:\\s*\\[([^\\]]*)\\]\\s*$`, "m"));
  if (!match) fail(`${file} has no finite ${key} list`);
  return match[1].split(",").map((item) => unquote(item)).filter(Boolean);
}

function parsePlanTaskBlocks(source, planName, requirementIds) {
  const tasks = [];
  for (const block of source.matchAll(/<task\b[\s\S]*?<\/task>/g)) {
    const name = block[0].match(/<name>\s*(253-\d{2}-\d{2}):\s*([^<]+)<\/name>/);
    if (!name) fail(`${planName} has a task without a Phase 253 identity`);
    tasks.push({ id: name[1], name: name[2].trim(), plan: planName, requirements: [...requirementIds] });
  }
  return tasks;
}

function assertUnresolvedAssumption(planSources, id) {
  const entry = planSources.some(({ source }) => {
    const lines = source.split(/\r?\n/);
    const index = lines.findIndex((line) => line.trim() === "- id: " + id);
    if (index < 0) return false;
    const fields = [];
    for (const line of lines.slice(index + 1)) {
      if (/^\s+- id:/.test(line) || /^\S/.test(line)) break;
      fields.push(line);
    }
    return /^\s+status:\s*unresolved\s*$/m.test(fields.join("\n"));
  });
  if (!entry) fail(id + " must remain an explicitly unresolved assumption in the phase plan");
}

function assertUnresolvedAssumptionLegacy(planSources, id) {
  const entry = planSources.some(({ source }) => {
    const match = source.match(new RegExp(`^\\s+- id:\\s*${id}\\s*$([\\s\\S]{0,500}?)(?=^\\s+- id:|^[A-Za-z0-9_-]+:|\\Z)`, "m"));
    return match && /^\s+status:\s*unresolved\s*$/m.test(match[1]);
  });
  if (!entry) fail(`${id} must remain an explicitly unresolved assumption in the phase plan`);
}

function parsePlanProhibitions(frontmatter) {
  const lines = frontmatter.split(/\r?\n/);
  const start = lines.findIndex((line) => /^  prohibitions:\s*$/.test(line));
  if (start < 0) fail("253-05-PLAN.md has no prohibition metadata block");
  const entries = [];
  let current = null;
  for (const line of lines.slice(start + 1)) {
    if (/^\S/.test(line) || /^  [A-Za-z0-9_-]+:/.test(line)) break;
    if (!line.trim()) continue;
    const statement = line.match(/^    - statement:\s*(.*?)\s*$/);
    if (statement) {
      if (current) entries.push(current);
      current = { statement: unquote(statement[1]) };
      continue;
    }
    if (!current) fail("253-05-PLAN.md prohibition metadata is malformed");
    const field = line.match(/^      ([a-z_]+):\s*(.*?)\s*$/);
    if (!field) fail("253-05-PLAN.md prohibition descriptors must use flat scalar fields");
    if (Object.hasOwn(current, field[1])) fail(`253-05-PLAN.md prohibition repeats ${field[1]}`);
    if (/^[>|[{]/.test(field[2]) || !field[2]) fail(`253-05-PLAN.md prohibition ${field[1]} must be a nonempty scalar`);
    current[field[1]] = unquote(field[2]);
  }
  if (current) entries.push(current);
  return entries;
}

function validateProhibitions(entries) {
  exactSet(entries.map(({ statement }) => statement), PROHIBITION_STATEMENTS, "project prohibition statements");
  return EXPECTED_PROHIBITIONS.map((expected) => {
    const entry = entries.find(({ statement }) => statement === expected.statement);
    const requiredFields = ["category", "status", "verification", "resolution", "check_kind", "check_target", "check_violation_fixture", "check_clean_fixture"];
    exactSet(Object.keys(entry || {}), ["statement", ...requiredFields], `prohibition descriptor fields for ${expected.statement}`);
    if (entry.category !== "transparency" || entry.status !== "resolved" || entry.verification !== "test") {
      fail("both Phase 253 prohibitions must be resolved test-tier transparency metadata");
    }
    for (const key of ["check_kind", "check_target", "check_violation_fixture", "check_clean_fixture"]) {
      if (entry[key] !== expected[key]) fail(`prohibition ${key} is missing, changed, or swapped`);
    }
    if (!entry.resolution.includes(expected.check_target) || !/current|clean|violation/i.test(entry.resolution)) {
      fail("prohibition resolution must name its bounded target and proof controls");
    }
    return { ...entry, id: expected.statement === PROHIBITION_STATEMENTS[0] ? "PROH-BOUNDED-STATIC-EFFECTS" : "PROH-SYNTHETIC-ATTRIBUTION" };
  });
}

export function inspectPhase253Metadata({ root = ROOT } = {}) {
  const planSources = PHASE_PLAN_FILES.map((name) => {
    const { source } = readPhaseArtifact(root, name);
    const frontmatter = extractFrontmatter(source, name);
    if (scalar(frontmatter, "phase") !== PHASE_SLUG) fail(`${name} belongs to a different phase`);
    return { name, source, frontmatter };
  });

  const planRequirements = new Set();
  const tasks = [];
  for (const { name, source, frontmatter } of planSources) {
    const requirements = listField(frontmatter, "requirements", name);
    requirements.forEach((id) => planRequirements.add(id));
    tasks.push(...parsePlanTaskBlocks(source, name, requirements));
  }
  exactSet([...planRequirements], REQUIREMENT_IDS, "Phase 253 requirement IDs");
  exactSet(tasks.map(({ id }) => id), TASK_IDS, "Phase 253 task IDs");
  exactSet(Object.keys(TASK_BINDINGS), TASK_IDS, "task-to-evidence mapping IDs");

  const edgeProbe = readJson(root, `.planning/phases/${PHASE_SLUG}/253-EDGE-PROBE.json`, "Phase 253 edge probe");
  if (!Array.isArray(edgeProbe.items)) fail("Phase 253 edge probe has no item inventory");
  const edgeId = ({ requirement_id: requirement, category }) => `EDGE-${requirement}-${category}`;
  const resolvedEdges = edgeProbe.items.filter((item) => item.status === "resolved" && item.verification === "explicit").map(edgeId);
  const currentUnclassified = edgeProbe.items.filter((item) => item.status === "unresolved" && item.category === "unclassified").map(edgeId);
  exactSet(resolvedEdges, EDGE_IDS, "ten explicit Phase 253 edge IDs");
  exactSet(currentUnclassified, CURRENT_UNCLASSIFIED_IDS, "current unresolved Phase 253 assumptions");
  exactSet(Object.keys(EDGE_BINDINGS), EDGE_IDS, "edge-to-evidence mapping IDs");
  for (const id of CURRENT_UNCLASSIFIED_IDS) assertUnresolvedAssumption(planSources, id);

  const uiProbe = readJson(root, `.planning/phases/${PHASE_SLUG}/253-UI-PROBE.json`, "Phase 253 UI probe");
  if (!Array.isArray(uiProbe.items)) fail("Phase 253 UI probe has no item inventory");
  const probedUi = uiProbe.items.filter((item) => item.status === "resolved" && item.verification === "explicit")
    .map(({ requirement_id: requirement, category }) => `UI-${requirement}-${category}`);
  exactSet(probedUi, UI_IDS, "twenty-six Phase 253 UI IDs");
  const plannedUi = [...new Set(planSources.flatMap(({ source }) => [...source.matchAll(/\bUI-E[1-4]-[a-z0-9-]+\b/g)].map((match) => match[0])))];
  exactSet(plannedUi, UI_IDS, "UI IDs represented in executable plans");

  const plan05 = planSources.find(({ name }) => name === "253-05-PLAN.md");
  const prohibitions = parsePlanProhibitions(plan05.frontmatter);
  const historical = readPhaseEvidenceForHistoricalAssumptions(root);

  return {
    requirements: [...REQUIREMENT_IDS],
    tasks: tasks.map(({ id }) => id),
    task_requirements: Object.fromEntries(tasks.map(({ id, requirements }) => [id, requirements])),
    edges: [...EDGE_IDS],
    ui: [...UI_IDS],
    current_unclassified: [...CURRENT_UNCLASSIFIED_IDS],
    historical_unclassified: historical.ids,
    unresolved_assumptions: [
      ...CURRENT_UNCLASSIFIED_IDS.map((id) => ({ id, status: "unresolved", source: "253-EDGE-PROBE.json" })),
      ...historical.ids.map((id) => ({ id, status: "unresolved", source: historical.path })),
    ],
    prohibitions,
    plan_sources: planSources,
  };
}

function readPhaseEvidenceForHistoricalAssumptions(root) {
  const { absolute, source } = resolveHistoricalSummary(root);
  const section = source.match(/^## Unresolved Probe Metadata\s*\n([\s\S]*?)(?=^## |\Z)/m)?.[1] || "";
  if (!section.includes("status: unresolved") || /\bstatus:\s*resolved\b/i.test(section)) {
    fail("Phase 252 historical probe assumptions must remain unresolved");
  }
  for (const id of HISTORICAL_UNCLASSIFIED_IDS) {
    if (!section.includes(id)) fail(`historical unclassified assumption is missing: ${id}`);
  }
  return { ids: [...HISTORICAL_UNCLASSIFIED_IDS], path: path.relative(root, absolute).split(path.sep).join("/") };
}

function resolveHistoricalSummary(root) {
  const absolute = resolvePhaseEvidencePath("252-production-backed-subscription-stories", HISTORICAL_SUMMARY, { root });
  return { absolute, source: fs.readFileSync(absolute, "utf8") };
}

function resultsRelativePath(resultsPath) {
  if (typeof resultsPath !== "string" || !resultsPath) fail("a current Phase 253 results path is required");
  const normalized = resultsPath.replaceAll("\\", "/");
  const match = normalized.match(/^accrue_admin\/tmp\/phase253\/ci-results\/([a-f0-9]{24,64})\/results\.json$/i);
  if (!match) fail("result path must name a repository-relative Phase 253 run bundle");
  return { relative: normalized, runId: match[1] };
}

function latestResultsPath(root) {
  const directory = safeRepoPath(root, RESULT_ROOT, "Phase 253 results directory");
  if (!fs.existsSync(directory)) fail("no Phase 253 focused results are available");
  const candidates = fs.readdirSync(directory, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && /^[a-f0-9]{24,64}$/i.test(entry.name))
    .map((entry) => path.join(directory, entry.name, "results.json"))
    .filter((absolute) => fs.existsSync(absolute))
    .map((absolute) => ({ absolute, mtime: fs.statSync(absolute).mtimeMs }))
    .sort((left, right) => right.mtime - left.mtime || left.absolute.localeCompare(right.absolute));
  if (candidates.length === 0) fail("no Phase 253 focused result bundles were found");
  return path.relative(fs.realpathSync(root), candidates[0].absolute).split(path.sep).join("/");
}

function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]));
  }
  return value;
}

function assertEqualJson(actual, expected, label) {
  if (JSON.stringify(canonical(actual)) !== JSON.stringify(canonical(expected))) fail(`${label} differs from revalidated current evidence`);
}

function digestMap(bundle, root) {
  const digests = object(bundle.source_digests, "runner source digest map");
  const keys = Object.keys(digests).sort();
  if (keys.length === 0) fail("runner source digest map is empty");
  for (const source of keys) {
    if (!/^[a-f0-9]{64}$/i.test(String(digests[source]))) fail(`invalid digest for source ${source}`);
    const absolute = safeRepoPath(root, source, "source digest path");
    if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) fail(`source digest target is missing: ${source}`);
    if (sha256(fs.readFileSync(absolute)) !== digests[source]) fail(`source digest is stale: ${source}`);
  }
  const sorted = Object.fromEntries(keys.map((key) => [key, digests[key]]));
  if (sha256(JSON.stringify(sorted)) !== bundle.source_fingerprint) fail("source fingerprint does not match the current source map");
  return sorted;
}

function currentManifest(root, bundle, sourceDigests) {
  if (bundle.manifest_path !== MANIFEST_PATH) fail("runner manifest path changed or is unexpected");
  const manifestPath = safeRepoPath(root, MANIFEST_PATH, "compiled Phase 253 manifest");
  if (!fs.existsSync(manifestPath)) fail("compiled Phase 253 manifest is missing");
  const bytes = fs.readFileSync(manifestPath);
  if (sha256(bytes) !== bundle.manifest_sha256) fail("compiled Phase 253 manifest digest is stale");
  const manifest = JSON.parse(bytes.toString("utf8"));
  if (manifest.schema_version !== 1 || manifest.human_judgment !== false) fail("compiled Phase 253 manifest schema or judgment mode is invalid");
  object(manifest.source_digests, "compiled manifest source digest map");
  for (const [source, digest] of Object.entries(manifest.source_digests)) {
    if (sourceDigests[source] !== digest) fail(`compiled manifest source digest is missing or stale: ${source}`);
  }
  return manifest;
}

function validateLog(root, resultDir, command, stream) {
  const pathField = `${stream}_path`;
  const digestField = `${stream}_sha256`;
  const relativePath = command[pathField];
  const absolute = safeRepoPath(root, relativePath, `${stream} log path`);
  const rel = path.relative(resultDir, absolute);
  if (rel.startsWith("..") || path.isAbsolute(rel)) fail(`${stream} log escaped its run directory`);
  if (!fs.existsSync(absolute) || !fs.statSync(absolute).isFile()) fail(`${stream} log is missing`);
  const bytes = fs.readFileSync(absolute);
  if (sha256(bytes) !== command[digestField]) fail(`${stream} log digest is stale`);
  return bytes.toString("utf8");
}

function validateCommandEvidence(root, bundle, resultsPath, manifest, sourceDigests) {
  const resultDir = path.dirname(safeRepoPath(root, resultsPath, "result bundle path"));
  const outputDirectory = path.join(fs.realpathSync(root), path.dirname(resultsPath));
  const plan = buildCommandPlan({
    id: bundle.run_id,
    adminBuildPath: path.join(os.tmpdir(), `phase253-acceptance-${bundle.run_id}`),
    outputDirectory,
  });
  exactSet(plan.map(({ id }) => id), REQUIRED_COMMAND_IDS, "focused lane inventory");
  if (!Array.isArray(bundle.commands)) fail("runner bundle has no executed command records");
  exactSet(bundle.commands.map(({ id }) => id), REQUIRED_COMMAND_IDS, "executed Phase 253 command identities");
  const commandMap = new Map(bundle.commands.map((command) => [command.id, command]));
  const checked = new Map();
  const usedPartitions = [];

  for (const spec of plan) {
    const command = commandMap.get(spec.id);
    if (command.exitCode !== 0 || command.signal || command.error || command.validation_error) fail(`${spec.id} did not finish with a clean zero exit`);
    if (command.run_id !== bundle.run_id || command.manifest_sha256 !== bundle.manifest_sha256) fail(`${spec.id} belongs to a different run or compiled manifest`);
    exactSet(command.sources, spec.sources, `${spec.id} source inventory`);
    const commandDigests = object(command.source_digests, `${spec.id} source digest map`);
    exactSet(Object.keys(commandDigests), spec.sources, `${spec.id} source digest keys`);
    for (const source of spec.sources) {
      if (commandDigests[source] !== sourceDigests[source]) fail(`${spec.id} source digest is missing or stale: ${source}`);
    }
    if (spec.partition) {
      if (!/^\d{8,16}$/.test(String(command.partition)) || command.partition !== spec.partition && spec.id !== "phase253-compositions-browser") {
        // Partition values are freshly generated when the plan is reconstructed; only syntax and uniqueness are stable.
        if (!/^\d{8,16}$/.test(String(command.partition))) fail(`${spec.id} has no fresh numeric disposable partition`);
      }
      usedPartitions.push(command.partition);
    }
    if (command.duration_ms < 0 || !Number.isFinite(command.duration_ms)) fail(`${spec.id} has an invalid duration`);
    const started = Date.parse(command.started_at);
    const completed = Date.parse(command.completed_at);
    if (!Number.isFinite(started) || !Number.isFinite(completed) || completed < started) fail(`${spec.id} execution timestamps are invalid`);
    const stdout = validateLog(root, resultDir, command, "stdout");
    validateLog(root, resultDir, command, "stderr");

    let browserResult = null;
    let expectedBrowserCells = undefined;
    if (spec.reporter.kind === "playwright-json") {
      const browserPath = safeRepoPath(root, bundle.browser_result_path, "Phase 253 browser result path");
      if (bundle.browser_result_path !== spec.browser_contract.result_path || !fs.existsSync(browserPath)) fail("browser result path is missing or belongs to a different run");
      try { browserResult = JSON.parse(fs.readFileSync(browserPath, "utf8")); }
      catch { fail("browser result is malformed JSON"); }
      expectedBrowserCells = spec.browser_contract.expected_cell_definitions(manifest);
      exactSet(expectedBrowserCells.map(({ key }) => key), expectedBrowserCellKeys(manifest), "expected browser cell inventory");
    }

    const execution = {
      exitCode: command.exitCode,
      run_id: command.run_id,
      expected_run_id: bundle.run_id,
      manifest_sha256: command.manifest_sha256,
      source_digests: commandDigests,
      assertion_refs: command.assertion_refs,
      stdout,
    };
    const evidence = validateLaneEvidence(spec, execution, {
      root,
      expectedRunId: bundle.run_id,
      expectedSourceDigests: sourceDigests,
      expectedManifestDigest: bundle.manifest_sha256,
      browserResult,
      expectedBrowserCells,
    });
    if (!evidence || evidence.skipped !== 0 || (evidence.test_count !== null && evidence.test_count <= 0)) fail(`${spec.id} reporter is skipped or vacuous`);
    exactSet(command.assertion_refs, expectedAssertionReferences(spec), `${spec.id} assertion reference inventory`);
    assertEqualJson(command.execution_evidence, evidence, `${spec.id} reporter evidence`);
    checked.set(spec.id, { command, spec, evidence });
  }

  if (usedPartitions.length !== new Set(usedPartitions).size) fail("mutable Phase 253 lanes share a disposable partition");
  const browser = checked.get("phase253-compositions-browser");
  const browserResultPath = safeRepoPath(root, bundle.browser_result_path, "Phase 253 browser result path");
  if (sha256(fs.readFileSync(browserResultPath)) !== bundle.browser_result_sha256) fail("browser result digest does not match the runner bundle");
  for (const cell of browser.evidence.browser_cells) {
    if (cell.run_id !== bundle.run_id || cell.manifest_sha256 !== bundle.manifest_sha256 || cell.status !== "passed") fail("browser cell has a stale, pooled, or failed run identity");
  }
  return checked;
}

function assertionReference(bundle, commands, commandId, assertionId) {
  if (commandId === "bundle") {
    if (assertionId !== "all_required_commands_passed" || bundle.status !== "passed" || bundle.commands.length !== REQUIRED_COMMAND_IDS.length) {
      fail("bundle-level reference does not prove all required Phase 253 commands passed");
    }
    return `${bundle.results_path}#bundle:${assertionId}`;
  }
  const row = commands.get(commandId);
  if (!row) fail(`evidence reference names an unexecuted lane: ${commandId}`);
  const { evidence } = row;
  if (!evidence.assertion_refs.includes(assertionId)) fail(`evidence reference names an absent assertion: ${commandId}#${assertionId}`);
  const identities = evidence.assertion_bindings?.[assertionId];
  if (!Array.isArray(identities) || identities.length === 0) fail(`assertion ${commandId}#${assertionId} has no executed identity binding`);
  if (evidence.test_identities.length > 0 && identities.some((identity) => !evidence.test_identities.includes(identity))) {
    fail(`assertion ${commandId}#${assertionId} references a test identity outside its report`);
  }
  if (row.spec.reporter.kind === "playwright-json") {
    const cells = evidence.browser_cells || [];
    if (cells.length === 0 || cells.some((cell) => cell.status !== "passed" || cell.run_id !== bundle.run_id || cell.manifest_sha256 !== bundle.manifest_sha256)) {
      fail(`browser assertion ${assertionId} lacks current per-cell source and run evidence`);
    }
  }
  return `${bundle.results_path}#commands:${commandId}:${assertionId}`;
}

function refsFor(bundle, commands, pairs) {
  if (!Array.isArray(pairs) || pairs.length === 0) fail("coverage item has no assertion references");
  return pairs.map(([commandId, assertionId]) => assertionReference(bundle, commands, commandId, assertionId));
}

function uiAssertionMap() {
  return Object.fromEntries(UI_IDS.map((id) => [id, uiBindings(id)]));
}

export function validatePhase253Evidence({ root = ROOT, resultsPath } = {}) {
  const repository = fs.realpathSync(root);
  const identity = resultsRelativePath(resultsPath);
  const bundle = readJson(repository, identity.relative, "Phase 253 runner result bundle");
  const expectedBundlePath = `${RESULT_ROOT}/${identity.runId}/results.json`;
  if (identity.relative !== expectedBundlePath || bundle.results_path !== expectedBundlePath || bundle.run_id !== identity.runId) {
    fail("result path, directory nonce, and runner identity do not match");
  }
  if (bundle.schema_version !== 1 || bundle.plan !== "253-06" || bundle.status !== "passed" || bundle.human_judgment !== false) {
    fail("runner bundle must be a passed current Phase 253 execution with human_judgment: false");
  }
  if (!/^[a-f0-9]{24,64}$/i.test(bundle.run_id)) fail("runner bundle has no fresh run identity");
  if (!bundle.run_started_at || !bundle.run_completed_at || Date.parse(bundle.run_completed_at) < Date.parse(bundle.run_started_at)) {
    fail("runner bundle timestamps are invalid");
  }
  if (bundle.source_revision !== bundle.source_revision_after || !/^[a-f0-9]{40}$/i.test(bundle.source_revision || "")) {
    fail("runner source revision changed during the execution");
  }
  const sourceDigests = digestMap(bundle, repository);
  const manifest = currentManifest(repository, bundle, sourceDigests);
  const trackedManifest = safeRepoPath(repository, TRACKED_PHASE252_MANIFEST, "tracked Phase 252 manifest");
  const trackedManifestDigest = sha256(fs.readFileSync(trackedManifest));
  if (bundle.tracked_phase252_manifest_sha256_before !== trackedManifestDigest ||
      bundle.tracked_phase252_manifest_sha256_after !== trackedManifestDigest) {
    fail("tracked Phase 252 manifest changed during the Phase 253 run");
  }

  const metadata = inspectPhase253Metadata({ root: repository });
  const validatedProhibitions = validateProhibitions(metadata.prohibitions);
  const commands = validateCommandEvidence(repository, bundle, identity.relative, manifest, sourceDigests);
  const requirementRefs = Object.fromEntries(REQUIREMENT_IDS.map((id) => [id, refsFor(bundle, commands, REQUIREMENT_BINDINGS[id])]));
  const taskRefs = Object.fromEntries(TASK_IDS.map((id) => [id, refsFor(bundle, commands, TASK_BINDINGS[id])]));
  const edgeRefs = Object.fromEntries(EDGE_IDS.map((id) => [id, refsFor(bundle, commands, EDGE_BINDINGS[id])]));
  const uiMap = uiAssertionMap();
  exactSet(Object.keys(uiMap), UI_IDS, "UI evidence mapping IDs");
  const uiRefs = Object.fromEntries(UI_IDS.map((id) => [id, refsFor(bundle, commands, uiMap[id])]));
  const prohibitionRefs = validatedProhibitions.map((prohibition, index) => ({
    id: prohibition.id,
    statement: prohibition.statement,
    evidence_refs: refsFor(bundle, commands, index === 0
      ? [["phase253-transparency-controls", "phase253_current_green"], ["phase253-transparency-controls", "phase253_clean_green"], ["phase253-transparency-controls", "phase253_static_violation_red"], ["phase253-presentation-contract", "current_and_clean_source_identity"]]
      : [["phase253-transparency-controls", "phase253_current_green"], ["phase253-transparency-controls", "phase253_clean_green"], ["phase253-transparency-controls", "phase253_synthetic_violation_red"], ["phase253-presentation-contract", "current_and_clean_source_identity"]]),
  }));

  return {
    status: "passed",
    plan: "253-06",
    run_id: bundle.run_id,
    human_judgment: false,
    command_count: bundle.commands.length,
    requirements: metadata.requirements,
    tasks: metadata.tasks,
    classified_edges: metadata.edges,
    ui_predicates: metadata.ui,
    unresolved_assumptions: metadata.unresolved_assumptions,
    unresolved_prohibitions: [],
    prohibition_evidence: prohibitionRefs,
    results_path: bundle.results_path,
    browser_result_path: bundle.browser_result_path,
    manifest_path: bundle.manifest_path,
    manifest_sha256: bundle.manifest_sha256,
    source_fingerprint: bundle.source_fingerprint,
    browser_cells: commands.get("phase253-compositions-browser").evidence.browser_cells,
    evidence_refs: {
      requirements: requirementRefs,
      tasks: taskRefs,
      edges: edgeRefs,
      ui: uiRefs,
      prohibitions: Object.fromEntries(prohibitionRefs.map(({ id, evidence_refs }) => [id, evidence_refs])),
    },
  };
}

function coverageBlock(frontmatter, file) {
  const lines = frontmatter.split(/\r?\n/);
  const start = lines.findIndex((line) => line === "coverage:");
  if (start < 0) fail(`${file} is missing executable coverage`);
  const entries = [];
  let current = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[A-Za-z0-9_-]+:/.test(line)) break;
    if (/^  - id:/.test(line)) {
      if (current.length) entries.push(current.join("\n"));
      current = [line];
    } else if (current.length) {
      current.push(line);
    }
  }
  if (current.length) entries.push(current.join("\n"));
  if (entries.length === 0) fail(`${file} has no executable coverage entries`);
  return entries;
}

function summaryCoverageEntry(entry, file) {
  const id = entry.match(/^\s+- id:\s*["']?([^\s"']+)/m)?.[1];
  const description = entry.match(/^\s+description:\s*(.*?)\s*$/m)?.[1];
  const refs = [...entry.matchAll(/^\s+ref:\s*(.*?)\s*$/gm)].map((match) => unquote(match[1]));
  const statuses = [...entry.matchAll(/^\s+status:\s*([^\s#]+)/gm)].map((match) => match[1]);
  if (!id || !/^\s+human_judgment:\s*false\s*$/m.test(entry)) fail(`${file} coverage must have an ID and human_judgment: false`);
  if (refs.length === 0 || refs.some((ref) => !ref)) fail(`${file} coverage ${id} has no executable evidence reference`);
  if (statuses.length === 0 || statuses.some((status) => status !== "pass")) fail(`${file} coverage ${id} is not fully passed`);
  return { id, description: description ? unquote(description) : `${file} ${id}`, refs };
}

export function validateCompletedSummaries({ root = ROOT } = {}) {
  const summaries = SUMMARY_FILES.map((name) => {
    const { absolute, source } = readPhaseArtifact(root, name);
    const metadata = extractFrontmatter(source, name);
    if (scalar(metadata, "status") !== "complete") fail(`${name} must have status: complete before UAT generation`);
    const entries = coverageBlock(metadata, name).map((entry) => summaryCoverageEntry(entry, name));
    const completed = completedSummaryDate(metadata);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(completed || "")) fail(`${name} needs a deterministic completed date`);
    return { name, absolute, directory: path.dirname(absolute), source, completed, entries };
  });
  exactSet([...new Set(summaries.map(({ directory }) => directory))], [summaries[0].directory], "SUMMARY phase directory");
  if (summaries.length !== SUMMARY_FILES.length) fail("all six complete plan summaries are required before UAT generation");
  const dates = summaries.map(({ completed }) => completed).sort();
  const coverage = summaries.flatMap(({ name, entries }) => entries.map((entry) => ({ file: name, ...entry })));
  return { phaseDir: summaries[0].directory, summaries, coverage, started: dates[0], updated: dates.at(-1) };
}

function renderUat(summarySet) {
  const tests = summarySet.coverage.map(({ file, id, description, refs }, index) =>
    `### ${index + 1}. ${description}\nsource: automated\nverification: ${refs.join(" | ")}\nresult: [pass]`);
  return `---\nstatus: complete\nphase: 253\nsource: executable-summary-coverage\nstarted: ${summarySet.started}\nupdated: ${summarySet.updated}\n---\n\n# Phase 253 Automated UAT\n\nEvery acceptance item below is produced from committed executable coverage. No post-hoc human verification is required.\n\n## Tests\n\n${tests.join("\n\n")}\n\n## Summary\n\ntotal: ${tests.length}\npassed: ${tests.length}\nissues: 0\npending: 0\nskipped: 0\nblocked: 0\n`;
}

export function generatePhase253Acceptance({ root = ROOT, resultsPath, latest = false, writeUat = false } = {}) {
  const repository = fs.realpathSync(root);
  const selectedPath = latest ? latestResultsPath(repository) : resultsPath;
  if (!selectedPath) fail("usage: node generate_phase253_acceptance.mjs --latest [--write-uat] or --results <repository-relative-results.json>");
  const evidence = validatePhase253Evidence({ root: repository, resultsPath: selectedPath });
  if (!writeUat) return { evidence, uat_written: false, uat_path: null };
  const summarySet = validateCompletedSummaries({ root: repository });
  const destination = path.join(summarySet.phaseDir, "253-UAT.md");
  fs.writeFileSync(destination, renderUat(summarySet), { mode: 0o600 });
  return {
    evidence,
    uat_written: true,
    uat_path: path.relative(repository, destination).split(path.sep).join("/"),
    uat_test_count: summarySet.coverage.length,
  };
}

function main() {
  const args = process.argv.slice(2);
  const latest = args.includes("--latest");
  const resultIndex = args.indexOf("--results");
  const resultsPath = resultIndex === -1 ? undefined : args[resultIndex + 1];
  if (resultIndex !== -1 && !resultsPath) fail("--results requires a repository-relative results path");
  if (latest === Boolean(resultsPath)) fail("choose exactly one of --latest or --results <path>");
  const result = generatePhase253Acceptance({ root: ROOT, resultsPath, latest, writeUat: args.includes("--write-uat") });
  process.stdout.write(JSON.stringify({ ...result.evidence, uat_written: result.uat_written, uat_path: result.uat_path, ...(result.uat_test_count ? { uat_test_count: result.uat_test_count } : {}) }, null, 2) + "\n");
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try { main(); } catch (error) {
    process.stderr.write(`generate_phase253_acceptance: ${error.message}\n`);
    process.exitCode = 2;
  }
}

