#!/usr/bin/env node
//
// Phase 254 (CIQ-04, D-22/D-23) recurring-check budget.
//
// Three verbs over accrue_admin/storybook/phase254-budget.json:
//
//   check             read-only, runs in the required owner (admin-phase200-guardrails):
//                     identity, universe, skip/retry/flaky, manifest digest, fingerprint and
//                     step-summary rules FAIL; timing above warn_at only WARNS; timing above
//                     the ceiling FAILS (a hang guard). CI never rewrites the budget.
//   freeze            maintainer-only (refuses when CI is set): turns three first-attempt
//                     ubuntu samples on one commit into the frozen budget, the target
//                     evaluations and the visual/a11y allowances.
//   restamp-manifest  maintainer-only: the only way manifest_sha256 follows a regenerated
//                     manifest, and it appends a resolved manifest-restamp deviation.
//
// Everything below the CLI is a pure function over parsed JSON so the self-test can prove
// each rule with a positive and a negative control (D-02).

import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { FINGERPRINT_KEYS, machineFingerprint, summarizeSamples } from "./phase254_measure.mjs";

const require = createRequire(import.meta.url);
const { assertSelectionInvariants } = require("../../accrue_admin/e2e/phase254-selection-invariants.js");

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const BUDGET_PATH = "accrue_admin/storybook/phase254-budget.json";
const MANIFEST_PATH = "storybook/phase252-manifest.json";
const LEDGER_PATH = "accrue_admin/storybook/subscription-curation.json";
const FINGERPRINT_PATH = "accrue_admin/tmp/phase254/fingerprint-guardrails.json";
const LOCAL_SUMMARY_PATH = "accrue_admin/tmp/phase254/summary.md";
const SUMMARY_MARKER = "Phase 254 recurring budget check";

const fail = (message) => { throw new Error(`Phase 254 budget: ${message}`); };

export const TARGET_KEYS = Object.freeze(["warm_preview_s", "focused_check_s", "additional_warm_browser_s", "incremental_ci_critical_path_s"]);
export const OWNER_JOB = "admin-phase200-guardrails";
export const VISUAL_JOB = "browser-uat";
export const COMPOSITION_LANE = "phase253-compositions-browser";
export const RENDER_LANE = "subscription-render-browser";
export const GUARDRAIL_STEP = "Run Phase 200 deterministic guardrails";
export const MULTIPLIERS = Object.freeze({ warn_at: 1.25, ceiling: 2.5 });
export const ALLOWANCE_MAX_ADDED_S = 180;
export const FROZEN_METRIC = "owner_job_added_s";
export const FULL_MODE_BASIS_DEVIATION = "DEV-254-10";
export const VISUAL_BASIS_DEVIATION = "DEV-254-09";

const round3 = (value) => Math.round(value * 1000) / 1000;
const sha256Hex = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const isObject = (value) => Boolean(value) && typeof value === "object" && !Array.isArray(value);
const isNumber = (value) => typeof value === "number" && Number.isFinite(value);
const byCodeUnit = (left, right) => (left < right ? -1 : left > right ? 1 : 0);

function median(values) {
  const ordered = [...values].sort((left, right) => left - right);
  const middle = Math.floor(ordered.length / 2);
  return ordered.length % 2 === 1 ? ordered[middle] : (ordered[middle - 1] + ordered[middle]) / 2;
}

// -- escaping (T-254-19, S4) ----------------------------------------------------------

// A `::warning` workflow command is parsed line by line; the message and the property
// values need `%`, CR and LF encoded, and a property value also needs `:` and `,`. All five
// are encoded so an attacker-influenced title can neither end the command nor open another.
export function escapeWorkflowCommand(value) {
  return String(value ?? "")
    .replace(/%/g, "%25")
    .replace(/\r/g, "%0D")
    .replace(/\n/g, "%0A")
    .replace(/:/g, "%3A")
    .replace(/,/g, "%2C");
}

// A step-summary table cell: no pipe can end the cell, no angle bracket can open HTML, and no
// newline can end the row.
export function escapeMarkdownCell(value) {
  return String(value ?? "")
    .replace(/\\/g, "\\\\")
    .replace(/\|/g, "\\|")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/`/g, "'")
    .replace(/\r?\n|\r/g, " ");
}

// -- target evaluations (D-21, D-24) ----------------------------------------------------

function uniqueIds(budget) {
  return new Set((budget?.deviations ?? []).map((entry) => entry.id));
}

// Problems with a budget's target_evaluations; an empty list is a valid record.
export function targetEvaluationProblems(budget) {
  const evaluations = budget?.target_evaluations;
  if (!Array.isArray(evaluations)) return ["target_evaluations is not an array"];
  if (evaluations.length === 0) return [];
  const problems = [];
  const keys = evaluations.map((entry) => entry?.target);
  if (JSON.stringify([...keys].sort(byCodeUnit)) !== JSON.stringify([...TARGET_KEYS].sort(byCodeUnit))) {
    problems.push(`target_evaluations must hold exactly the four targets once each (found ${JSON.stringify(keys)})`);
  }
  const deviations = uniqueIds(budget);
  for (const entry of evaluations) {
    if (!isObject(entry)) { problems.push("a target evaluation is not an object"); continue; }
    if (!isNumber(entry.target_s) || !isNumber(entry.measured_s)) problems.push(`${entry.target}: target_s and measured_s must be numbers`);
    if (typeof entry.source !== "string" || entry.source === "") problems.push(`${entry.target}: source is missing`);
    if (typeof entry.met !== "boolean") problems.push(`${entry.target}: met must be a boolean`);
    else if (isNumber(entry.target_s) && isNumber(entry.measured_s) && entry.met !== (entry.measured_s <= entry.target_s)) problems.push(`${entry.target}: met disagrees with the measurement`);
    if (entry.met === false && !deviations.has(entry.deviation_id)) problems.push(`${entry.target}: unmet target names no appended deviation (${JSON.stringify(entry.deviation_id)})`);
    if (entry.source?.startsWith("ci-full-mode:")) {
      if (!isNumber(entry.cells) || entry.cells <= 0) problems.push(`${entry.target}: a full-mode CI target needs a positive cell count`);
      if (entry.basis_deviation_id !== FULL_MODE_BASIS_DEVIATION) problems.push(`${entry.target}: a full-mode CI target needs basis_deviation_id ${FULL_MODE_BASIS_DEVIATION}`);
    }
  }
  return problems;
}

function laneMs(sample, laneId) {
  const lane = (sample.lanes ?? []).find((entry) => entry.lane === laneId || String(entry.lane).endsWith(`:${laneId}`));
  return lane && isNumber(lane.duration_ms) ? lane.duration_ms : null;
}

function browserLane(sample, laneId) {
  return (sample.browser_lanes ?? []).find((entry) => entry.id === laneId || entry.lane === laneId || String(entry.lane).endsWith(`:${laneId}`)) ?? null;
}

function cellDurationsMs(lane) {
  return (lane?.durations ?? []).filter((entry) => !/^reconciles /.test(entry.identity)).map((entry) => entry.duration_ms);
}

// The four CIQ-04 provisional targets, each with its source, its cell count and (when a CI
// full-mode lane stands in for a selected-mode observation) the basis deviation (owner
// decision 2026-10-28). `deviationIds` maps an unmet target to the deviation that resolves it.
export function evaluateTargets({ budget, samples, local, deviationIds = {}, criticalPathDeltas = null }) {
  const targets = budget?.provisional_targets;
  if (!isObject(targets)) fail("the budget has no provisional_targets");
  const owner = (samples ?? []).filter((sample) => sample.job === OWNER_JOB);
  if (owner.length === 0) fail("evaluateTargets needs owner-job CI samples");
  const warm = (local ?? budget.metrics?.local ?? []).find((sample) => sample.mode === "warm");
  if (!warm || !isNumber(warm.p90_ms)) fail("evaluateTargets needs a local warm-preview sample");

  const compositionMs = owner.map((sample) => laneMs(sample, COMPOSITION_LANE));
  if (compositionMs.some((value) => value === null)) fail(`a sample has no ${COMPOSITION_LANE} lane duration`);
  const compositionLanes = owner.map((sample) => browserLane(sample, COMPOSITION_LANE));
  const renderLanes = owner.map((sample) => browserLane(sample, RENDER_LANE));
  if (compositionLanes.some((lane) => !lane) || renderLanes.some((lane) => !lane)) fail("a sample lacks the Playwright browser-lane evidence (stats duration and cells) for the two browser lanes");
  const statsS = owner.map((_, index) => (compositionLanes[index].stats_duration_ms + renderLanes[index].stats_duration_ms) / 1000);
  for (const lane of [...compositionLanes, ...renderLanes]) {
    if (!isNumber(lane.stats_duration_ms) || !isNumber(lane.cells)) fail(`the ${lane.id} browser-lane evidence lacks a numeric stats_duration_ms or cell count`);
  }
  const cellCount = (lanes) => lanes[0].cells;
  const deltas = criticalPathDeltas ?? owner.map((sample) => sample.critical_path_delta_s);
  if (deltas.some((value) => !isNumber(value))) fail("every owner sample needs a numeric critical_path_delta_s");

  const entry = (target, measured, source, cells, extra = {}) => {
    const met = measured <= targets[target];
    return {
      target,
      target_s: targets[target],
      measured_s: round3(measured),
      source,
      cells,
      met,
      deviation_id: met ? null : (deviationIds[target] ?? null),
      basis_deviation_id: extra.basis_deviation_id ?? null,
      ...(extra.values_s ? { values_s: extra.values_s } : {}),
    };
  };
  const evaluations = [
    entry("warm_preview_s", warm.p90_ms / 1000, "local-informs-only", warm.cells ?? null),
    entry("focused_check_s", median(compositionMs) / 1000, `ci-full-mode:${COMPOSITION_LANE}`, cellCount(compositionLanes), {
      basis_deviation_id: FULL_MODE_BASIS_DEVIATION, values_s: compositionMs.map((value) => round3(value / 1000)),
    }),
    entry("additional_warm_browser_s", median(statsS), `ci-full-mode:${RENDER_LANE}+${COMPOSITION_LANE}`, cellCount(compositionLanes) + cellCount(renderLanes), {
      basis_deviation_id: FULL_MODE_BASIS_DEVIATION, values_s: statsS.map(round3),
    }),
    entry("incremental_ci_critical_path_s", median(deltas), "ci-owner-job-vs-main", null, { values_s: deltas.map(round3) }),
  ];
  return evaluations;
}

// -- check (D-23) -------------------------------------------------------------------------

function ledgerRecordIds(ledger) {
  return new Set((ledger?.records ?? []).filter((record) => ["retire", "merge"].includes(record.disposition)).map((record) => record.id));
}

// results: { executed_ids[], phase252_cases, commands[{id, exitCode, skipped, failed, retried, flaky}],
//            bundles[{plan, status}], visual_added_s?, a11y_added_s? }
// durationS: the owner-job added-time estimate, or null when none was supplied.
export function checkBudget({ budget, selection, results, fingerprint, manifestBytes, summaryPath, ledger, durationS = null }) {
  const failures = [];
  const warnings = [];
  const rows = [];
  const row = (metric, value, status, detail = "") => rows.push({ metric, value: String(value), status, detail });
  const problem = (metric, value, detail) => { failures.push(`${metric}: ${detail}`); row(metric, value, "fail", detail); };

  if (!isObject(budget)) fail("check needs the budget record");

  // Identity: the executed composition cells are exactly the reported selection.
  let selectedIds = null;
  if (!isObject(selection)) {
    problem("selection report", "missing", "no selection report was supplied (PHASE254_SELECTION)");
  } else {
    try {
      assertSelectionInvariants(selection);
      selectedIds = selection.selected.map((item) => item.id).sort(byCodeUnit);
    } catch (error) {
      problem("selection report", "invalid", error.message);
    }
  }
  const executed = [...(results?.executed_ids ?? [])].sort(byCodeUnit);
  if (selectedIds) {
    const same = executed.length === selectedIds.length && executed.every((id, index) => id === selectedIds[index]);
    if (same) row("executed identities", `${executed.length} of ${selectedIds.length} selected`, "pass");
    else {
      const extra = executed.filter((id) => !selectedIds.includes(id));
      const missing = selectedIds.filter((id) => !executed.includes(id));
      problem("executed identities", `${executed.length} executed, ${selectedIds.length} selected`, `executed ids differ from the selected ids (${extra.length} unselected executed, ${missing.length} selected not executed)`);
    }
  }

  // Universe: it may grow, but it may not shrink without a CURATE-01 record.
  if (selection?.counts) {
    const universe = selection.counts.total + (results?.phase252_cases ?? 0);
    const frozenTotal = budget.selection?.total;
    if (isNumber(frozenTotal) && universe < frozenTotal) {
      const named = budget.selection?.curation_record_ids ?? [];
      const known = ledgerRecordIds(ledger);
      if (named.length > 0 && named.every((id) => known.has(id))) row("case universe", `${universe} (frozen ${frozenTotal}, curated by ${named.join(", ")})`, "pass");
      else problem("case universe", `${universe} < frozen ${frozenTotal}`, "the universe is below the frozen total without a CURATE-01 retire/merge record id");
    } else row("case universe", `${universe} (frozen ${frozenTotal ?? "unset"})`, "pass");
  }

  // Skips, retries, flaky tests and failed lanes.
  const badCommands = [];
  for (const command of results?.commands ?? []) {
    if (command.exitCode !== 0 || command.skipped > 0 || command.failed > 0 || command.retried > 0 || command.flaky > 0) badCommands.push(command.id);
  }
  const badBundles = (results?.bundles ?? []).filter((bundle) => bundle.status !== "passed").map((bundle) => bundle.plan);
  if (!results || (results.commands ?? []).length === 0) problem("skip/retry/flaky", "no lanes", "the results bundles hold no lane commands");
  else if (badCommands.length > 0 || badBundles.length > 0) problem("skip/retry/flaky", `${badCommands.length} lane(s)`, `a lane is failed, skipped, retried or flaky: ${[...badCommands, ...badBundles].join(", ")}`);
  else row("skip/retry/flaky", `${results.commands.length} lanes clean`, "pass");

  // Manifest digest.
  if (!manifestBytes) problem("manifest digest", "missing", "the committed manifest bytes were not supplied");
  else {
    const actual = sha256Hex(manifestBytes);
    if (actual !== budget.manifest_sha256) problem("manifest digest", actual.slice(0, 12), `budget manifest_sha256 ${String(budget.manifest_sha256).slice(0, 12)} differs from the committed manifest ${actual.slice(0, 12)}; run restamp-manifest after the owner regenerated it`);
    else row("manifest digest", `${actual.slice(0, 12)} matches`, "pass");
  }

  // Fingerprint.
  const missingKeys = isObject(fingerprint) ? FINGERPRINT_KEYS.filter((key) => !(key in fingerprint)) : [...FINGERPRINT_KEYS];
  if (!isObject(fingerprint)) problem("machine fingerprint", "missing", "no machine fingerprint was supplied");
  else if (missingKeys.length > 0) problem("machine fingerprint", "incomplete", `fingerprint lacks ${missingKeys.join(", ")}`);
  else if (fingerprint.manifest_sha256 !== budget.manifest_sha256) problem("machine fingerprint", "stale", "the fingerprint's manifest_sha256 differs from the budget");
  else row("machine fingerprint", `${fingerprint.image_os ?? fingerprint.os} ${fingerprint.cores} cores`, "pass");

  // Step summary destination.
  if (typeof summaryPath !== "string" || summaryPath === "") problem("step summary", "missing", "no step-summary destination was supplied");
  else row("step summary", "destination set", "pass");

  // Timing: provisional budgets enforce nothing; a frozen one warns above warn_at and fails above the ceiling.
  if (budget.frozen === null || budget.frozen === undefined) {
    row("owner job added time", durationS === null ? "n/a" : `${round3(durationS)} s`, "info", "provisional budget (frozen null): timing is not enforced");
  } else if (durationS === null || durationS === undefined) {
    row("owner job added time", "n/a", "info", "no elapsed time was supplied; timing not evaluated");
  } else if (durationS > budget.ceiling) {
    problem("owner job added time", `${round3(durationS)} s`, `above the ceiling ${budget.ceiling} s`);
  } else if (durationS > budget.warn_at) {
    const message = `owner job added time ${round3(durationS)} s is above warn_at ${budget.warn_at} s (ceiling ${budget.ceiling} s)`;
    warnings.push(message);
    row("owner job added time", `${round3(durationS)} s`, "warn", `warn_at ${budget.warn_at} s, ceiling ${budget.ceiling} s`);
  } else {
    row("owner job added time", `${round3(durationS)} s`, "pass", `warn_at ${budget.warn_at} s, ceiling ${budget.ceiling} s`);
  }

  // Visual and accessibility cells are budgeted from their own measured cost (D-22).
  for (const [key, label] of [["visual", "visual cells"], ["a11y", "accessibility cells"]]) {
    const added = results?.[`${key}_added_s`];
    const allowance = budget.allowances?.[key];
    if (isNumber(added) && allowance) {
      if (added > allowance.max_added_s) {
        warnings.push(`${label} added ${round3(added)} s, above the ${allowance.max_added_s} s allowance`);
        row(label, `${round3(added)} s`, "warn", `allowance ${allowance.max_added_s} s`);
      } else row(label, `${round3(added)} s`, "pass", `allowance ${allowance.max_added_s} s`);
    }
  }

  // Target evaluations, when recorded, must be a complete record.
  const evaluationProblems = targetEvaluationProblems(budget);
  if (evaluationProblems.length > 0) problem("target evaluations", `${evaluationProblems.length} problem(s)`, evaluationProblems.join("; "));

  return { ok: failures.length === 0, failures, warnings, rows };
}

export function renderBudgetSummary(result) {
  const lines = [
    `### ${SUMMARY_MARKER}`,
    "",
    "| Metric | Value | Status | Detail |",
    "| --- | --- | --- | --- |",
    ...result.rows.map((entry) => `| ${escapeMarkdownCell(entry.metric)} | ${escapeMarkdownCell(entry.value)} | ${escapeMarkdownCell(entry.status)} | ${escapeMarkdownCell(entry.detail)} |`),
    "",
  ];
  return lines.join("\n");
}

export function workflowWarnings(result) {
  return result.warnings.map((message) => `::warning title=${escapeWorkflowCommand("Phase 254 budget")}::${escapeWorkflowCommand(message)}`);
}

// -- freeze (D-21, D-22) --------------------------------------------------------------------

export function ciSampleBlockers(sample, budget) {
  const blockers = [];
  if (!isObject(sample)) return ["the sample is not an object"];
  if (sample.attempt !== 1) blockers.push(`attempt ${sample.attempt} (only first-attempt runs are measured)`);
  if (sample.conclusion !== "success") blockers.push(`conclusion ${sample.conclusion} (only success samples freeze)`);
  if (sample.smoke === true) blockers.push("a smoke sample");
  const fingerprint = sample.fingerprint;
  if (!isObject(fingerprint)) blockers.push("fingerprint is missing");
  else {
    for (const key of FINGERPRINT_KEYS) {
      if (fingerprint[key] === null || fingerprint[key] === undefined || fingerprint[key] === "") blockers.push(`fingerprint.${key} is missing`);
    }
    if (typeof fingerprint.image_os === "string" && !/^ubuntu/.test(fingerprint.image_os)) blockers.push(`image_os ${fingerprint.image_os} is not an ubuntu runner image`);
    if (fingerprint.dirty !== false) blockers.push("the checkout was dirty");
    if (budget && fingerprint.manifest_sha256 !== budget.manifest_sha256) blockers.push("fingerprint manifest_sha256 differs from the budget (restamp-manifest first)");
  }
  if (!isObject(sample.cache) || !isNumber(sample.cache.hits) || !isNumber(sample.cache.misses)) blockers.push("the cache outcome (hits, misses) is not recorded");
  if (!isNumber(sample.duration_s)) blockers.push("duration_s is not numeric");
  return blockers;
}

function nextDeviationId(budget, { from, to }) {
  const used = uniqueIds(budget);
  for (let number = from; number <= to; number += 1) {
    const id = `DEV-254-${String(number).padStart(2, "0")}`;
    if (!used.has(id)) return id;
  }
  return null;
}

function parseBlock(block) {
  const match = /^(\d+)-(\d+)$/.exec(String(block ?? ""));
  if (!match) fail(`--block must look like <first>-<last> (received ${JSON.stringify(block)})`);
  const [from, to] = [Number(match[1]), Number(match[2])];
  if (from > to) fail("--block range is empty");
  return { from, to };
}

const clone = (value) => JSON.parse(JSON.stringify(value));

function refuseInCi(env, verb) {
  if (env?.CI) fail(`${verb} refuses to run when CI is set; the budget is changed only by a maintainer through an appended deviation`);
}

// Re-stamps manifest_sha256 to the committed manifest bytes and records why (B-1, T-254-41).
export function restampManifest({ budget, manifestBytes, cause, block, env = process.env }) {
  refuseInCi(env, "restamp-manifest");
  if (!Buffer.isBuffer(manifestBytes) && typeof manifestBytes !== "string") fail("restampManifest needs the committed manifest bytes");
  if (typeof cause !== "string" || cause === "") fail("restampManifest needs a --cause task id");
  const to = sha256Hex(manifestBytes);
  const from = budget.manifest_sha256;
  if (from === to) return { budget, changed: false, deviation: null };
  const { from: first, to: last } = parseBlock(block);
  const id = nextDeviationId(budget, { from: first, to: last });
  if (id === null) fail(`the deviation id block ${block} is exhausted`);
  const next = clone(budget);
  const cells = next.selection?.total ?? null;
  const deviation = {
    id,
    kind: "manifest-restamp",
    target: { name: "manifest_sha256", source: "B-1: the budget digest follows a regenerated manifest only through restamp-manifest" },
    measurement: { manifest_path: MANIFEST_PATH },
    from,
    to,
    cause,
    decision: "re-stamped to the committed manifest bytes after its owner regenerated them",
    status: "resolved",
    before: { cells, owners: 2 },
    after: { cells, owners: 2 },
  };
  next.manifest_sha256 = to;
  next.deviations = [...next.deviations, deviation];
  return { budget: next, changed: true, deviation };
}

export function restampCheck({ budget, manifestBytes }) {
  const actual = sha256Hex(manifestBytes);
  return { ok: actual === budget.manifest_sha256, expected: budget.manifest_sha256, actual };
}

// mainReference: { run_id, owner_job_s, workflow_wall_s } (queue excluded).
export function freezeBudget({ budget, samples, mainReference, selection = null, phase252Cases = null, curationRecordIds = null, deviationIds = {}, env = process.env }) {
  refuseInCi(env, "freeze");
  if (!isObject(budget)) fail("freeze needs the budget record");
  if (!Array.isArray(samples)) fail("freeze needs the CI samples");
  if (!isObject(mainReference) || !isNumber(mainReference.owner_job_s) || !isNumber(mainReference.workflow_wall_s)) {
    fail("freeze needs a main reference with numeric owner_job_s and workflow_wall_s");
  }
  const owner = samples.filter((sample) => sample.job === OWNER_JOB);
  const visual = samples.filter((sample) => sample.job === VISUAL_JOB);
  if (owner.length < 3) fail(`freeze needs three owner-job samples (found ${owner.length})`);
  if (owner.length > 3) fail(`freeze takes exactly three owner-job samples (found ${owner.length})`);
  if (new Set(owner.map((sample) => sample.run_id)).size !== 3) fail("the three owner-job samples must be three distinct runs");
  if (new Set(owner.map((sample) => sample.head_sha)).size !== 1) fail("the owner-job samples span more than one head sha");
  for (const sample of [...owner, ...visual]) {
    const blockers = ciSampleBlockers(sample, budget);
    if (blockers.length > 0) fail(`run ${sample.run_id} (${sample.job}) cannot freeze a budget: ${blockers.join("; ")}`);
  }
  if (visual.length === 0) fail("freeze needs at least one browser-uat sample for allowances.visual; a guessed visual baseline is never written");

  const compositionLanes = owner.map((sample) => browserLane(sample, COMPOSITION_LANE));
  for (const [index, lane] of compositionLanes.entries()) {
    const durations = cellDurationsMs(lane);
    if (!lane || durations.length === 0 || durations.some((value) => !isNumber(value))) {
      fail(`run ${owner[index].run_id} has no per-test durations for ${COMPOSITION_LANE}; frozen.composition_cell needs them`);
    }
  }
  const cellCounts = compositionLanes.map((lane) => cellDurationsMs(lane).length);
  if (new Set(cellCounts).size !== 1) fail(`the freeze runs executed different composition cell counts (${cellCounts.join(", ")})`);
  for (const sample of owner) {
    if (!(Number.isFinite(Date.parse(sample.run_started_at)) && Number.isFinite(Date.parse(sample.completed_at)))) fail(`run ${sample.run_id} lacks run_started_at; the critical-path delta cannot be computed`);
  }

  const added = owner.map((sample) => round3(sample.duration_s - mainReference.owner_job_s));
  const criticalPath = owner.map((sample) => {
    const wall = (Date.parse(sample.completed_at) - Date.parse(sample.run_started_at)) / 1000;
    return round3(Math.max(0, wall - mainReference.workflow_wall_s));
  });
  const setup = owner.map((sample) => {
    const step = (sample.steps ?? []).find((entry) => entry.name === GUARDRAIL_STEP);
    if (!step || !isNumber(step.duration_s)) fail(`run ${sample.run_id} has no ${GUARDRAIL_STEP} step duration`);
    return sample.duration_s - step.duration_s;
  });
  const summary = summarizeSamples(added);
  const machine = (({ image_os, image_version, runner_os, cpu_model, cores, ram_bytes, arch, os }) => ({ image_os, image_version, runner_os, cpu_model, cores, ram_bytes, arch, os }))(owner[0].fingerprint);
  const pooled = compositionLanes.flatMap((lane) => cellDurationsMs(lane));
  const perCell = summarizeSamples(pooled);

  const annotated = owner.map((sample, index) => ({ ...sample, critical_path_delta_s: criticalPath[index] }));
  const evaluations = evaluateTargets({ budget, samples: annotated, deviationIds });
  const evaluationBudget = { ...clone(budget), target_evaluations: evaluations };
  const evaluationProblems = targetEvaluationProblems(evaluationBudget);
  if (evaluationProblems.length > 0) fail(`the target evaluations are incomplete: ${evaluationProblems.join("; ")}`);

  const visualP90 = summarizeSamples(visual.map((sample) => sample.duration_s)).p90;
  const frozen = {
    metric: FROZEN_METRIC,
    value: round3(summary.median),
    unit: "s",
    critical_path_delta_s: round3(median(criticalPath)),
    setup_s: round3(median(setup)),
    main_reference: { run_id: mainReference.run_id ?? null, owner_job_s: mainReference.owner_job_s, workflow_wall_s: mainReference.workflow_wall_s },
    basis: {
      head_sha: owner[0].head_sha,
      runs: owner.map((sample) => ({
        run_id: sample.run_id, head_sha: sample.head_sha, attempt: sample.attempt, job: sample.job, conclusion: sample.conclusion,
        fingerprint: sample.fingerprint, cache: sample.cache,
      })),
    },
    multipliers: { ...MULTIPLIERS },
    composition_cell: {
      lane: COMPOSITION_LANE,
      mode: "full",
      cells: cellCounts[0],
      per_cell_median_s: round3(perCell.median / 1000),
      per_cell_p90_s: round3(perCell.p90 / 1000),
      run_ids: owner.map((sample) => sample.run_id),
    },
  };
  const allowances = {
    visual: {
      job: VISUAL_JOB,
      baseline_p90_s: round3(visualP90),
      n: visual.length,
      max_added_s: ALLOWANCE_MAX_ADDED_S,
      basis: visual.map((sample) => sample.run_id),
    },
    a11y: {
      job: OWNER_JOB,
      baseline_p90_s: round3(summary.p90),
      max_added_s: ALLOWANCE_MAX_ADDED_S,
      basis: owner.map((sample) => sample.run_id),
    },
  };
  const selectionRecord = selection
    ? (() => {
        assertSelectionInvariants(selection);
        if (!Number.isInteger(phase252Cases)) fail("freeze with a selection report needs phase252Cases");
        return {
          ...budget.selection,
          total: selection.counts.total + phase252Cases,
          selected: selection.counts.selected + phase252Cases,
          sentinels: selection.sentinels.length,
          exclusions: selection.counts.excluded,
          broad_fallback: selection.mode === "full",
          mode: selection.mode,
          phase252_cases: phase252Cases,
          phase253_cases: selection.counts.total,
          curation_record_ids: curationRecordIds ?? budget.selection?.curation_record_ids ?? [],
        };
      })()
    : budget.selection;

  const next = clone(budget);
  const known = new Set(next.metrics.ci.map((sample) => `${sample.run_id}:${sample.job}`));
  for (const sample of samples) if (!known.has(`${sample.run_id}:${sample.job}`)) next.metrics.ci.push(sample);

  if (budget.frozen !== null && budget.frozen !== undefined) {
    const id = nextDeviationId(budget, { from: 20, to: 29 });
    if (id === null) fail("no free deviation id (DEV-254-20..29) for the refreeze proposal");
    next.deviations.push({
      id, kind: "refreeze-proposal",
      target: { name: "frozen", source: "D-23: re-freeze only by an appended deviation" },
      measurement: { proposed: { value: frozen.value, warn_at: round3(summary.p90 * MULTIPLIERS.warn_at), ceiling: round3(frozen.value * MULTIPLIERS.ceiling), run_ids: frozen.basis.runs.map((run) => run.run_id) }, current: { value: budget.frozen.value } },
      decision: "proposed only; the frozen value is unchanged until a maintainer resolves this record",
      status: "open",
      before: { cells: next.selection?.total ?? null, owners: 2 },
      after: { cells: next.selection?.total ?? null, owners: 2 },
    });
    return { budget: next, written: false };
  }

  next.selection = selectionRecord;
  next.metrics.freeze = { metric: FROZEN_METRIC, samples: added, ...summary, warmup: 0, machine };
  next.frozen = frozen;
  next.warn_at = round3(next.metrics.freeze.p90 * MULTIPLIERS.warn_at);
  next.ceiling = round3(frozen.value * MULTIPLIERS.ceiling);
  next.target_evaluations = evaluations;
  next.allowances = allowances;
  return { budget: next, written: true };
}

// The queue-excluded owner-job and workflow durations of a main-branch run (`gh run view --json jobs`).
export function mainReferenceFromRun(runJson, ownerJobName = "Admin Phase 200 deterministic guardrails") {
  if (!isObject(runJson) || !Array.isArray(runJson.jobs)) fail("main reference needs a run JSON with jobs");
  const owner = runJson.jobs.find((job) => job.name === ownerJobName);
  if (!owner || !owner.startedAt || !owner.completedAt) fail(`the main run has no completed ${ownerJobName} job`);
  const timed = runJson.jobs.filter((job) => job.startedAt && job.completedAt && job.conclusion !== "skipped");
  const starts = timed.map((job) => Date.parse(job.startedAt));
  const ends = timed.map((job) => Date.parse(job.completedAt));
  return {
    run_id: runJson.databaseId ?? null,
    owner_job: ownerJobName,
    owner_job_s: round3((Date.parse(owner.completedAt) - Date.parse(owner.startedAt)) / 1000),
    workflow_wall_s: round3((Math.max(...ends) - Math.min(...starts)) / 1000),
    basis: "queue excluded: earliest job startedAt to latest job completedAt, skipped jobs omitted",
  };
}

// -- result loading ----------------------------------------------------------------------------

function readJson(file) { return JSON.parse(fs.readFileSync(file, "utf8")); }

function newestPassedBundle(files) {
  const candidates = files.map((file) => ({ file, bundle: readJson(file) })).filter((entry) => entry.bundle.status === "passed" && typeof entry.bundle.run_completed_at === "string");
  if (candidates.length === 0) fail("no passed results bundle was found");
  candidates.sort((left, right) => Date.parse(right.bundle.run_completed_at) - Date.parse(left.bundle.run_completed_at));
  return candidates[0];
}

function findFiles(directory, predicate) {
  if (!fs.existsSync(directory)) return [];
  const found = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) found.push(...findFiles(full, predicate));
    else if (predicate(entry.name, full)) found.push(full);
  }
  return found.sort();
}

function normalizeResults({ phase252, phase253, renderedCases252 }) {
  const commands = [];
  for (const bundle of [phase252, phase253]) {
    for (const command of bundle.commands ?? []) {
      const evidence = command.execution_evidence ?? {};
      commands.push({
        id: `${bundle.plan ?? "?"}:${command.id}`,
        exitCode: command.exitCode,
        skipped: evidence.skipped ?? 0,
        failed: evidence.failed ?? 0,
        retried: evidence.retried ?? 0,
        flaky: evidence.flaky ?? 0,
      });
    }
  }
  const cells = phase253.commands?.find((command) => command.id === COMPOSITION_LANE)?.execution_evidence?.browser_cells;
  if (!Array.isArray(cells) || cells.length === 0) fail(`the Phase 253 bundle has no ${COMPOSITION_LANE} browser cells`);
  return {
    executed_ids: cells.map((cell) => cell.key),
    phase252_cases: renderedCases252,
    commands,
    bundles: [{ plan: phase252.plan ?? "252", status: phase252.status }, { plan: phase253.plan ?? "253", status: phase253.status }],
  };
}

export function loadResultsFromRoot(root) {
  const choose = (phase) => newestPassedBundle(findFiles(path.join(root, "accrue_admin", "tmp", phase, "ci-results"), (name) => name === "results.json"));
  const phase252 = choose("phase252");
  const phase253 = choose("phase253");
  const rendered = readJson(path.join(root, phase252.bundle.browser_result_path));
  return normalizeResults({ phase252: phase252.bundle, phase253: phase253.bundle, renderedCases252: rendered.cases.length });
}

// Resolves the newest downloaded run directory under `directory` (a `gh run download` layout:
// <run>/<artifact>/...) and reads its evidence.
export function loadEvidenceFromDirectory(directory) {
  const runs = fs.readdirSync(directory, { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && /^\d+$/.test(entry.name))
    .map((entry) => ({ name: entry.name, full: path.join(directory, entry.name), mtime: fs.statSync(path.join(directory, entry.name)).mtimeMs }))
    .filter((entry) => findFiles(path.join(entry.full, "phase253-machine-evidence"), (name) => name === "results.json").length > 0 &&
      fs.existsSync(path.join(entry.full, "phase254-machine-evidence-guardrails")))
    .sort((left, right) => right.mtime - left.mtime || Number(right.name) - Number(left.name));
  if (runs.length === 0) fail(`no downloaded run evidence (phase252/phase253/phase254 machine evidence) under ${directory}`);
  const run = runs[0];
  const phase252 = newestPassedBundle(findFiles(path.join(run.full, "phase252-machine-evidence"), (name, full) => name === "results.json" && full.includes("ci-results")));
  const phase253 = newestPassedBundle(findFiles(path.join(run.full, "phase253-machine-evidence"), (name, full) => name === "results.json" && full.includes("ci-results")));
  const browserName = path.basename(phase252.bundle.browser_result_path);
  const browserFile = findFiles(path.join(run.full, "phase252-machine-evidence"), (name) => name === browserName)[0];
  if (!browserFile) fail(`the downloaded Phase 252 evidence lacks ${browserName}`);
  const guardrail = path.join(run.full, "phase254-machine-evidence-guardrails");
  const selectionFile = findFiles(guardrail, (name) => /^selection-.*\.json$/.test(name))[0];
  const fingerprintFile = path.join(guardrail, "fingerprint-guardrails.json");
  if (!selectionFile) fail(`the downloaded guardrail evidence in run ${run.name} lacks a selection report`);
  if (!fs.existsSync(fingerprintFile)) fail(`the downloaded guardrail evidence in run ${run.name} lacks fingerprint-guardrails.json`);
  return {
    run_id: run.name,
    results: normalizeResults({ phase252: phase252.bundle, phase253: phase253.bundle, renderedCases252: readJson(browserFile).cases.length }),
    selection: readJson(selectionFile),
    fingerprint: readJson(fingerprintFile),
  };
}

// -- self-test fixtures ----------------------------------------------------------------------------

const FIXTURE_MANIFEST = Buffer.from('{"fixture":"manifest"}\n');
const FIXTURE_DIGEST = sha256Hex(FIXTURE_MANIFEST);

function fixtureFingerprint(overrides = {}) {
  return {
    os: "linux 7.0.0", arch: "x64", cpu_model: "AMD EPYC", cores: 4, ram_bytes: 16760344576, image_os: "ubuntu24", image_version: "20261026.354.1",
    runner_os: "Linux", otp: "28", elixir: "1.19.5", node: "22.23.4", playwright: "1.59.1", workers: 1,
    revision: "a".repeat(40), manifest_sha256: FIXTURE_DIGEST, dirty: false, ...overrides,
  };
}

function fixtureSelection({ ids = ["a::1", "b::2", "c::3"], selected = ids, sentinels = ["a::1"] } = {}) {
  const total = [...ids].sort(byCodeUnit);
  const chosen = [...new Set([...selected, ...sentinels])].sort(byCodeUnit);
  const sentinelList = [...sentinels].sort(byCodeUnit);
  return {
    schema_version: 1, kind: "phase254-selection", human_judgment: false,
    mode: chosen.length === total.length ? "full" : "affected",
    mode_reasons: ["fixture"],
    counts: { total: total.length, selected: chosen.length, excluded: total.length - chosen.length },
    total_ids: total,
    selected: chosen.map((id) => ({ id, reasons: ["fixture"] })),
    excluded: total.filter((id) => !chosen.includes(id)).map((id) => ({ id, reason: "fixture" })),
    sentinels: sentinelList,
    sentinels_sha256: sha256Hex(JSON.stringify(sentinelList)),
  };
}

function fixtureResults(overrides = {}) {
  return {
    executed_ids: ["a::1", "b::2", "c::3"],
    phase252_cases: 2,
    commands: [{ id: "252-08:one", exitCode: 0, skipped: 0, failed: 0, retried: 0, flaky: 0 }, { id: "253-06:two", exitCode: 0, skipped: 0, failed: 0, retried: 0, flaky: 0 }],
    bundles: [{ plan: "252-08", status: "passed" }, { plan: "253-06", status: "passed" }],
    ...overrides,
  };
}

function fixtureBudget(overrides = {}) {
  return {
    schema_version: 1,
    manifest_sha256: FIXTURE_DIGEST,
    selection: { total: 5, selected: 5 },
    metrics: { local: [{ mode: "warm", lane: "warm-preview", p90_ms: 36.363, cells: 3 }], ci: [] },
    provisional_targets: { warm_preview_s: 10, focused_check_s: 60, additional_warm_browser_s: 180, incremental_ci_critical_path_s: 300 },
    target_evaluations: [],
    frozen: null,
    allowances: null,
    warn_at: null,
    ceiling: null,
    known_reds: [],
    deviations: [{ id: "DEV-254-01", kind: "d24-local-attribution", status: "open", before: { cells: 5, owners: 2 }, after: { cells: 5, owners: 2 } }],
    ...overrides,
  };
}

function frozenBudget(overrides = {}) {
  return fixtureBudget({
    frozen: { metric: FROZEN_METRIC, value: 100, unit: "s", multipliers: { ...MULTIPLIERS } },
    warn_at: 130,
    ceiling: 250,
    ...overrides,
  });
}

const DURATIONS = (count, base) => Array.from({ length: count }, (_, index) => ({ identity: `cell ${index}`, duration_ms: base + index })).concat([{ identity: "reconciles every cell", duration_ms: 5 }]);

function fixtureCiSample(index, overrides = {}) {
  const runId = 9000 + index;
  return {
    schema_version: 1, workflow: "CI", run_id: runId, head_sha: "b".repeat(40), event: "workflow_dispatch", attempt: 1,
    job: OWNER_JOB, job_name: "Admin Phase 200 deterministic guardrails", conclusion: "success",
    started_at: "2026-10-29T10:00:00Z", completed_at: "2026-10-29T10:20:00Z", duration_s: 1200 + index * 10,
    run_started_at: "2026-10-29T09:59:00Z",
    steps: [{ name: GUARDRAIL_STEP, conclusion: "success", duration_s: 1100 + index * 10 }],
    lanes: [{ lane: "253-06:phase253-compositions-browser", duration_ms: 90_000 + index * 1000 }, { lane: "252-08:subscription-render-browser", duration_ms: 30_000 }],
    browser_lanes: [
      { id: COMPOSITION_LANE, lane: `253-06:${COMPOSITION_LANE}`, cells: 3, stats_duration_ms: 80_000, durations: DURATIONS(3, 400 + index * 100) },
      { id: RENDER_LANE, lane: `252-08:${RENDER_LANE}`, cells: 2, stats_duration_ms: 25_000, durations: DURATIONS(2, 900) },
    ],
    cache: { steps: [], hits: 2, partial: 0, misses: 0 },
    fingerprint: fixtureFingerprint(),
    informs_only: true,
    ...overrides,
  };
}

function fixtureVisualSample(overrides = {}) {
  return fixtureCiSample(50, { job: VISUAL_JOB, job_name: "Browser UAT", workflow: "AccrueAdmin Browser UAT", event: "pull_request", duration_s: 1000, browser_lanes: [], lanes: [], steps: [], ...overrides });
}

const FIXTURE_MAIN = { run_id: 1, owner_job_s: 500, workflow_wall_s: 1100 };

function freezeFixture(overrides = {}) {
  const samples = [fixtureCiSample(1), fixtureCiSample(2), fixtureCiSample(3), fixtureVisualSample()];
  return { budget: withDeviations(fixtureBudget(), ["DEV-254-05"]), samples, mainReference: FIXTURE_MAIN, deviationIds: { focused_check_s: "DEV-254-05" }, env: {}, ...overrides };
}

function withDeviations(budget, ids) {
  return { ...budget, deviations: [...budget.deviations, ...ids.map((id) => ({ id, kind: "fixture", status: "accepted", before: { cells: 5, owners: 2 }, after: { cells: 5, owners: 2 } }))] };
}

function run(overrides = {}) {
  return checkBudget({
    budget: fixtureBudget(), selection: fixtureSelection(), results: fixtureResults(), fingerprint: fixtureFingerprint(),
    manifestBytes: FIXTURE_MANIFEST, summaryPath: "summary.md", ledger: { records: [] }, durationS: null, ...overrides,
  });
}

function mustFail(result, pattern) {
  assert.equal(result.ok, false, "the check must fail");
  assert.match(result.failures.join("\n"), pattern);
}

export const SCENARIOS = [
  ["check passes a clean run (control for every failure scenario)", () => {
    const result = run();
    assert.equal(result.ok, true, result.failures.join("; "));
    assert.equal(result.warnings.length, 0);
  }],
  ["check fails when the executed identities differ from the selected ids (extra and missing)", () => {
    mustFail(run({ results: fixtureResults({ executed_ids: ["a::1", "b::2"] }) }), /executed ids differ/);
    mustFail(run({ results: fixtureResults({ executed_ids: ["a::1", "b::2", "c::3", "z::9"] }) }), /executed ids differ/);
  }],
  ["check fails when the universe is below the frozen total without a CURATE-01 record id, and passes with one", () => {
    const shrunk = { selection: fixtureSelection({ ids: ["a::1", "b::2"] }), results: fixtureResults({ executed_ids: ["a::1", "b::2"], phase252_cases: 2 }) };
    mustFail(run({ ...shrunk, budget: fixtureBudget({ selection: { total: 5, selected: 5 } }) }), /below the frozen total without a CURATE-01/);
    const curated = fixtureBudget({ selection: { total: 5, selected: 5, curation_record_ids: ["CUR-1"] } });
    assert.equal(run({ ...shrunk, budget: curated, ledger: { records: [{ id: "CUR-1", disposition: "retire" }] } }).ok, true);
    mustFail(run({ ...shrunk, budget: curated, ledger: { records: [{ id: "CUR-1", disposition: "retain" }] } }), /below the frozen total/);
    mustFail(run({ ...shrunk, budget: curated, ledger: { records: [] } }), /below the frozen total/);
  }],
  ["check fails on a skipped, retried, flaky or failed lane and on a bundle that is not passed", () => {
    for (const bad of [{ skipped: 1 }, { retried: 1 }, { flaky: 1 }, { failed: 1 }, { exitCode: 1 }]) {
      mustFail(run({ results: fixtureResults({ commands: [{ ...fixtureResults().commands[0], ...bad }] }) }), /failed, skipped, retried or flaky/);
    }
    mustFail(run({ results: fixtureResults({ bundles: [{ plan: "252-08", status: "failed" }] }) }), /failed, skipped, retried or flaky/);
    mustFail(run({ results: fixtureResults({ commands: [] }) }), /no lane commands/);
  }],
  ["digest rule, both sides: equal manifest bytes pass and a different manifest fails", () => {
    assert.equal(run().ok, true);
    mustFail(run({ manifestBytes: Buffer.from("regenerated\n") }), /manifest_sha256 .* differs from the committed manifest/);
    mustFail(run({ manifestBytes: null }), /manifest bytes were not supplied/);
  }],
  ["check fails on a missing, incomplete or stale fingerprint", () => {
    mustFail(run({ fingerprint: null }), /no machine fingerprint/);
    const { cores, ...partial } = fixtureFingerprint();
    mustFail(run({ fingerprint: partial }), /lacks cores/);
    mustFail(run({ fingerprint: fixtureFingerprint({ manifest_sha256: "0".repeat(64) }) }), /differs from the budget/);
  }],
  ["check fails without a step-summary destination", () => {
    mustFail(run({ summaryPath: "" }), /step-summary destination/);
    mustFail(run({ summaryPath: undefined }), /step-summary destination/);
  }],
  ["check fails when the selection report is missing or breaks an invariant", () => {
    mustFail(run({ selection: null }), /no selection report/);
    const broken = fixtureSelection();
    broken.selected = broken.selected.slice(1);
    mustFail(run({ selection: broken }), /selection report/);
  }],
  ["provisional budget (frozen null) enforces identity and integrity but no timing", () => {
    const result = run({ durationS: 1e9 });
    assert.equal(result.ok, true);
    assert.equal(result.warnings.length, 0);
    mustFail(run({ durationS: 1e9, manifestBytes: Buffer.from("x") }), /manifest/);
  }],
  ["warn_at boundary on both sides: one millisecond below and exactly warn_at stay silent, one millisecond above warns once", () => {
    const budget = frozenBudget();
    assert.equal(run({ budget, durationS: 129.999 }).warnings.length, 0);
    assert.equal(run({ budget, durationS: 130 }).warnings.length, 0);
    const above = run({ budget, durationS: 130.001 });
    assert.equal(above.ok, true);
    assert.equal(above.warnings.length, 1);
    assert.equal(workflowWarnings(above).length, 1);
    assert.match(workflowWarnings(above)[0], /^::warning /);
  }],
  ["ceiling: exactly the ceiling passes with a warning and one millisecond above fails", () => {
    const budget = frozenBudget();
    const at = run({ budget, durationS: 250 });
    assert.equal(at.ok, true);
    assert.equal(at.warnings.length, 1);
    mustFail(run({ budget, durationS: 250.001 }), /above the ceiling 250 s/);
  }],
  ["a frozen budget without an elapsed time reports timing as not evaluated rather than passing it", () => {
    const result = run({ budget: frozenBudget(), durationS: null });
    assert.equal(result.ok, true);
    assert.ok(result.rows.some((entry) => entry.metric === "owner job added time" && entry.status === "info" && /not evaluated/.test(entry.detail)));
  }],
  ["allowances compare measured visual and a11y cost and warn (never fail) above them", () => {
    const budget = frozenBudget({ allowances: { visual: { job: VISUAL_JOB, baseline_p90_s: 1000, n: 1, max_added_s: 180, basis: [1] }, a11y: { job: OWNER_JOB, baseline_p90_s: 100, max_added_s: 180, basis: [1] } } });
    const over = run({ budget, durationS: 100, results: fixtureResults({ visual_added_s: 181, a11y_added_s: 10 }) });
    assert.equal(over.ok, true);
    assert.equal(over.warnings.length, 1);
    assert.equal(run({ budget, durationS: 100, results: fixtureResults({ visual_added_s: 180, a11y_added_s: 180 }) }).warnings.length, 0);
  }],
  ["escapeWorkflowCommand and the summary renderer neutralize the hostile-title fixture", () => {
    const hostile = "100% bad\r\n::error::injected,title: |<script>\n| forged | row |";
    const escaped = escapeWorkflowCommand(hostile);
    assert.ok(!/[\r\n]/.test(escaped));
    for (const forbidden of [":", ","]) assert.ok(!escaped.includes(forbidden), `escaped output still holds ${forbidden}`);
    assert.match(escaped, /^100%25 bad%0D%0A%3A%3Aerror%3A%3Ainjected%2Ctitle%3A /);
    const rendered = renderBudgetSummary({ rows: [{ metric: hostile, value: "v|w", status: "pass", detail: "<b>x</b>" }] });
    const dataRow = rendered.split("\n").find((line) => line.includes("injected"));
    assert.ok(dataRow.startsWith("| "));
    assert.ok(!rendered.includes("<script>") && !rendered.includes("<b>"));
    assert.equal(dataRow.split(/(?<!\\)\|/).length, 6, "an unescaped pipe added a table column");
    const warning = workflowWarnings({ warnings: [hostile] })[0];
    assert.equal(warning.split("\n").length, 1);
    assert.ok(warning.startsWith("::warning title=Phase 254 budget::"));
  }],
  ["freeze writes the named metric, basis, multipliers, composition_cell, allowances and evaluations from three clean samples", () => {
    const { budget, written } = freezeBudget(freezeFixture());
    assert.equal(written, true);
    assert.equal(budget.frozen.metric, "owner_job_added_s");
    assert.equal(budget.frozen.value, 720);
    assert.equal(budget.metrics.freeze.n, 3);
    assert.equal(budget.metrics.freeze.warmup, 0);
    assert.equal(budget.warn_at, round3(730 * 1.25));
    assert.equal(budget.ceiling, round3(720 * 2.5));
    assert.deepEqual(budget.frozen.multipliers, { warn_at: 1.25, ceiling: 2.5 });
    assert.equal(budget.frozen.basis.runs.length, 3);
    assert.deepEqual(Object.keys(budget.frozen.basis.runs[0]), ["run_id", "head_sha", "attempt", "job", "conclusion", "fingerprint", "cache"]);
    assert.equal(budget.frozen.composition_cell.lane, "phase253-compositions-browser");
    assert.equal(budget.frozen.composition_cell.cells, 3);
    assert.equal(typeof budget.frozen.composition_cell.per_cell_p90_s, "number");
    assert.equal(budget.frozen.composition_cell.run_ids.length, 3);
    assert.equal(budget.allowances.visual.n, 1);
    assert.equal(budget.allowances.visual.max_added_s, 180);
    assert.equal(budget.allowances.a11y.baseline_p90_s, budget.metrics.freeze.p90);
    assert.deepEqual(budget.target_evaluations.map((entry) => entry.target).sort(), [...TARGET_KEYS].sort());
    assert.equal(targetEvaluationProblems(budget).length, 0);
  }],
  ["freeze rejects fewer than three samples, two shas, attempt 2, a failed run, macOS, dirty, smoke, a missing cache object and CI", () => {
    const base = freezeFixture();
    const owners = base.samples.filter((sample) => sample.job === OWNER_JOB);
    const visual = base.samples.filter((sample) => sample.job === VISUAL_JOB);
    const bad = (mutate, pattern) => assert.throws(() => freezeBudget({ ...base, samples: [...mutate(owners.map((sample) => ({ ...sample }))), ...visual] }), pattern);
    bad((list) => list.slice(0, 2), /needs three owner-job samples/);
    bad((list) => { list[2].head_sha = "c".repeat(40); return list; }, /more than one head sha/);
    bad((list) => { list[0].attempt = 2; return list; }, /attempt 2/);
    bad((list) => { list[0].conclusion = "failure"; return list; }, /conclusion failure/);
    bad((list) => { list[0].fingerprint = fixtureFingerprint({ image_os: null, os: "darwin 25.6.0" }); return list; }, /fingerprint\.image_os is missing/);
    bad((list) => { list[0].fingerprint = fixtureFingerprint({ image_os: "macos14" }); return list; }, /not an ubuntu runner image/);
    bad((list) => { list[0].fingerprint = fixtureFingerprint({ dirty: true }); return list; }, /dirty/);
    bad((list) => { list[0].smoke = true; return list; }, /smoke/);
    bad((list) => { delete list[0].cache; return list; }, /cache outcome/);
    bad((list) => { list[1].run_id = list[0].run_id; return list; }, /three distinct runs/);
    assert.throws(() => freezeBudget({ ...base, env: { CI: "true" } }), /refuses to run when CI is set/);
  }],
  ["freeze fails without browser-uat samples rather than guessing a visual baseline, and accepts several", () => {
    const base = freezeFixture();
    assert.throws(() => freezeBudget({ ...base, samples: base.samples.filter((sample) => sample.job !== VISUAL_JOB) }), /never written/);
    const two = freezeBudget({ ...base, samples: [...base.samples, fixtureVisualSample({ run_id: 777, duration_s: 1100 })] });
    assert.equal(two.budget.allowances.visual.n, 2);
    assert.equal(two.budget.allowances.visual.baseline_p90_s, 1100);
  }],
  ["freeze fails without per-test composition durations (W-3)", () => {
    const base = freezeFixture();
    const stripped = base.samples.map((sample) => (sample.job === OWNER_JOB ? { ...sample, browser_lanes: sample.browser_lanes.map((lane) => (lane.id === COMPOSITION_LANE ? { ...lane, durations: [] } : lane)) } : sample));
    assert.throws(() => freezeBudget({ ...base, samples: stripped }), /no per-test durations/);
  }],
  ["freeze appends a refreeze-proposal deviation and leaves an existing frozen value untouched", () => {
    const once = freezeBudget(freezeFixture()).budget;
    const again = freezeBudget(freezeFixture({ budget: once }));
    assert.equal(again.written, false);
    assert.deepEqual(again.budget.frozen, once.frozen);
    assert.equal(again.budget.warn_at, once.warn_at);
    assert.equal(again.budget.deviations.at(-1).kind, "refreeze-proposal");
    assert.equal(again.budget.deviations.at(-1).status, "open");
  }],
  ["evaluateTargets returns exactly the four targets, sources, cells and the full-mode basis; an unmet one without a deviation fails validation", () => {
    const samples = freezeFixture().samples.filter((sample) => sample.job === OWNER_JOB).map((sample) => ({ ...sample, critical_path_delta_s: 50 }));
    const evaluations = evaluateTargets({ budget: fixtureBudget(), samples });
    assert.deepEqual(evaluations.map((entry) => entry.target), [...TARGET_KEYS]);
    const focused = evaluations.find((entry) => entry.target === "focused_check_s");
    assert.equal(focused.source, "ci-full-mode:phase253-compositions-browser");
    assert.equal(focused.cells, 3);
    assert.equal(focused.basis_deviation_id, "DEV-254-10");
    assert.equal(focused.met, false);
    assert.equal(focused.deviation_id, null);
    const additional = evaluations.find((entry) => entry.target === "additional_warm_browser_s");
    assert.equal(additional.source, "ci-full-mode:subscription-render-browser+phase253-compositions-browser");
    assert.equal(additional.cells, 5);
    assert.equal(additional.measured_s, 105);
    assert.equal(additional.met, true);
    assert.match(targetEvaluationProblems({ ...fixtureBudget(), target_evaluations: evaluations }).join(";"), /unmet target names no appended deviation/);
    const resolved = evaluateTargets({ budget: fixtureBudget(), samples, deviationIds: { focused_check_s: "DEV-254-05" } });
    assert.deepEqual(targetEvaluationProblems(withDeviations({ ...fixtureBudget(), target_evaluations: resolved }, ["DEV-254-05"])), []);
    assert.match(targetEvaluationProblems({ ...fixtureBudget(), target_evaluations: resolved.slice(0, 3) }).join(";"), /exactly the four targets/);
  }],
  ["restampManifest sets the digest and appends exactly one resolved manifest-restamp deviation; a match changes nothing", () => {
    const stale = fixtureBudget({ manifest_sha256: "0".repeat(64) });
    const result = restampManifest({ budget: stale, manifestBytes: FIXTURE_MANIFEST, cause: "254-09-02", block: "11-19", env: {} });
    assert.equal(result.changed, true);
    assert.equal(result.budget.manifest_sha256, FIXTURE_DIGEST);
    const added = result.budget.deviations.filter((entry) => entry.kind === "manifest-restamp");
    assert.equal(added.length, 1);
    assert.equal(added[0].id, "DEV-254-11");
    assert.equal(added[0].from, "0".repeat(64));
    assert.equal(added[0].to, FIXTURE_DIGEST);
    assert.equal(added[0].cause, "254-09-02");
    assert.equal(added[0].status, "resolved");
    assert.deepEqual(added[0].before, added[0].after);
    const second = restampManifest({ budget: { ...result.budget, manifest_sha256: "1".repeat(64) }, manifestBytes: FIXTURE_MANIFEST, cause: "254-09-03", block: "11-19", env: {} });
    assert.equal(second.deviation.id, "DEV-254-12");
    const same = restampManifest({ budget: fixtureBudget(), manifestBytes: FIXTURE_MANIFEST, cause: "254-09-02", block: "11-19", env: {} });
    assert.equal(same.changed, false);
    assert.equal(same.budget.deviations.length, 1);
  }],
  ["restampManifest refuses an exhausted id block and any run with CI set; restampCheck is red on mismatch and green on match", () => {
    const stale = fixtureBudget({ manifest_sha256: "0".repeat(64) });
    assert.throws(() => restampManifest({ budget: stale, manifestBytes: FIXTURE_MANIFEST, cause: "x", block: "1-1", env: {} }), /exhausted/);
    assert.throws(() => restampManifest({ budget: stale, manifestBytes: FIXTURE_MANIFEST, cause: "x", block: "11-19", env: { CI: "1" } }), /refuses to run when CI is set/);
    assert.throws(() => restampManifest({ budget: stale, manifestBytes: FIXTURE_MANIFEST, cause: "x", block: "bad", env: {} }), /--block/);
    assert.equal(restampCheck({ budget: stale, manifestBytes: FIXTURE_MANIFEST }).ok, false);
    assert.equal(restampCheck({ budget: fixtureBudget(), manifestBytes: FIXTURE_MANIFEST }).ok, true);
  }],
  ["mainReferenceFromRun measures queue-excluded owner and workflow durations and rejects a run without the owner job", () => {
    const runJson = { databaseId: 5, jobs: [
      { name: "Admin Phase 200 deterministic guardrails", startedAt: "2026-10-26T19:32:08Z", completedAt: "2026-10-26T19:41:24Z", conclusion: "success" },
      { name: "other", startedAt: "2026-10-26T19:31:00Z", completedAt: "2026-10-26T19:50:00Z", conclusion: "success" },
      { name: "skipped", startedAt: "2026-10-26T18:00:00Z", completedAt: "2026-10-26T20:00:00Z", conclusion: "skipped" },
    ] };
    const reference = mainReferenceFromRun(runJson);
    assert.equal(reference.owner_job_s, 556);
    assert.equal(reference.workflow_wall_s, 1140);
    assert.throws(() => mainReferenceFromRun({ jobs: [] }), /no completed/);
  }],
];

export function verifyFixtures() {
  for (const [name, scenario] of SCENARIOS) {
    scenario();
    process.stdout.write(`  ok - ${name}\n`);
  }
  return SCENARIOS.length;
}

// -- CLI ------------------------------------------------------------------------------------------------

const VALUE_OPTIONS = new Set(["budget", "manifest", "selection", "fingerprint", "summary", "evidence-latest", "elapsed-s", "samples", "main-reference", "cause", "block", "out", "run", "repo", "deviation-ids", "curation-ids", "phase252-cases", "ledger"]);
const BOOLEAN_OPTIONS = new Set(["self-test", "write", "check"]);

function parseArgs(argv) {
  const positional = [];
  const flags = new Set();
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) { positional.push(token); continue; }
    const key = token.slice(2);
    if (BOOLEAN_OPTIONS.has(key)) { flags.add(key); continue; }
    if (!VALUE_OPTIONS.has(key)) fail(`unknown option --${key}`);
    if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) fail(`--${key} requires a value`);
    values[key] = argv[++index];
    if (key === "samples") {
      const list = [values[key]];
      while (index + 1 < argv.length && !argv[index + 1].startsWith("--")) list.push(argv[++index]);
      values[key] = list;
    }
  }
  return { positional, flags, values };
}

const absolute = (file) => path.resolve(ROOT, file);

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`);
}

function parseDeviationIds(text) {
  const map = {};
  for (const pair of String(text ?? "").split(",").filter(Boolean)) {
    const [key, id] = pair.split("=");
    if (!TARGET_KEYS.includes(key) || !/^DEV-254-\d\d$/.test(id ?? "")) fail(`--deviation-ids entries look like <target>=DEV-254-NN (received ${JSON.stringify(pair)})`);
    map[key] = id;
  }
  return map;
}

const verbs = {
  async check({ values, env }) {
    const budget = readJson(absolute(values.budget ?? BUDGET_PATH));
    const manifestBytes = fs.readFileSync(absolute(values.manifest ?? MANIFEST_PATH));
    const ledger = readJson(absolute(values.ledger ?? LEDGER_PATH));
    let results; let selection; let fingerprint;
    if (values["evidence-latest"]) {
      const evidence = loadEvidenceFromDirectory(absolute(values["evidence-latest"]));
      ({ results, selection, fingerprint } = evidence);
      process.stdout.write(`Phase 254 budget: evidence from downloaded run ${evidence.run_id}\n`);
    } else {
      results = loadResultsFromRoot(ROOT);
      let selectionPath = values.selection ?? env.PHASE254_SELECTION;
      if (!selectionPath && !env.CI) {
        // Locally the Phase 253 lane ran with no selection file, which is mode full by rule; the
        // selector reports exactly that for a non-pull-request event (FC-3).
        selectionPath = "accrue_admin/tmp/phase254/selection-local-full.json";
        const head = spawnSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
        const made = spawnSync(process.execPath, [absolute("scripts/ci/phase254_selection.mjs"), "select", "--event", "push", "--head", head, "--out", absolute(selectionPath)], { encoding: "utf8", cwd: ROOT });
        if (made.status !== 0) fail(`the local full-mode selection report could not be produced: ${(made.stderr || made.stdout).trim().slice(0, 200)}`);
      }
      selection = selectionPath ? readJson(absolute(selectionPath)) : null;
      const fingerprintFile = absolute(values.fingerprint ?? FINGERPRINT_PATH);
      if (fs.existsSync(fingerprintFile)) fingerprint = readJson(fingerprintFile);
      else if (!env.CI) { fingerprint = machineFingerprint(); } // local: the CI workflow step writes it on a runner
      else fingerprint = null;
    }
    const summaryPath = values.summary ?? env.GITHUB_STEP_SUMMARY ?? LOCAL_SUMMARY_PATH;
    let durationS = null;
    const supplied = values["elapsed-s"] ?? env.PHASE254_RUNNER_ELAPSED_S;
    if (supplied !== undefined && supplied !== "") {
      const elapsed = Number(supplied);
      if (!Number.isFinite(elapsed) || elapsed < 0) fail("--elapsed-s must be a non-negative number");
      durationS = budget.frozen ? round3(elapsed + budget.frozen.setup_s - budget.frozen.main_reference.owner_job_s) : elapsed;
    } else if (!values["evidence-latest"] && env.PHASE254_RUNNER_STARTED_AT) {
      const started = Number(env.PHASE254_RUNNER_STARTED_AT);
      if (!Number.isFinite(started)) fail("PHASE254_RUNNER_STARTED_AT must be epoch seconds");
      const elapsed = Math.max(0, Date.now() / 1000 - started);
      durationS = budget.frozen ? round3(elapsed + budget.frozen.setup_s - budget.frozen.main_reference.owner_job_s) : round3(elapsed);
    }
    const result = checkBudget({ budget, selection, results, fingerprint, manifestBytes, summaryPath: absolute(summaryPath), ledger, durationS });
    const markdown = renderBudgetSummary(result);
    fs.mkdirSync(path.dirname(absolute(summaryPath)), { recursive: true });
    fs.appendFileSync(absolute(summaryPath), `${markdown}\n`);
    if (!fs.readFileSync(absolute(summaryPath), "utf8").includes(`### ${SUMMARY_MARKER}`)) fail("the step-summary row was not written");
    for (const line of workflowWarnings(result)) process.stdout.write(`${line}\n`);
    for (const entry of result.rows) process.stdout.write(`  ${entry.status.padEnd(4)} ${entry.metric}: ${entry.value}${entry.detail ? ` (${entry.detail})` : ""}\n`);
    if (!result.ok) {
      process.stderr.write(`Phase 254 budget: FAIL: ${result.failures.join(" | ")}\n`);
      process.exitCode = 1;
      return;
    }
    process.stdout.write(`Phase 254 budget: PASS (${result.warnings.length} warning(s))\n`);
  },
  async freeze({ values, flags, env }) {
    refuseInCi(env, "freeze");
    if (!values.samples) fail("freeze requires --samples <file...>");
    if (!values["main-reference"]) fail("freeze requires --main-reference <file>");
    const budgetFile = absolute(values.budget ?? BUDGET_PATH);
    const budget = readJson(budgetFile);
    const samples = values.samples.flatMap((file) => { const parsed = readJson(absolute(file)); return Array.isArray(parsed) ? parsed : [parsed]; });
    const selection = values.selection ? readJson(absolute(values.selection)) : null;
    const result = freezeBudget({
      budget, samples, mainReference: readJson(absolute(values["main-reference"])), selection,
      phase252Cases: values["phase252-cases"] === undefined ? null : Number(values["phase252-cases"]),
      curationRecordIds: values["curation-ids"] ? values["curation-ids"].split(",") : null,
      deviationIds: parseDeviationIds(values["deviation-ids"]), env,
    });
    if (!flags.has("write")) {
      process.stdout.write(`${JSON.stringify({ frozen: result.budget.frozen, warn_at: result.budget.warn_at, ceiling: result.budget.ceiling, target_evaluations: result.budget.target_evaluations, allowances: result.budget.allowances }, null, 2)}\n`);
      process.stdout.write("Phase 254 budget: dry run (pass --write to record it)\n");
      return;
    }
    writeJson(budgetFile, result.budget);
    process.stdout.write(result.written ? `Phase 254 budget: frozen ${result.budget.frozen.metric} = ${result.budget.frozen.value} s, warn_at ${result.budget.warn_at} s, ceiling ${result.budget.ceiling} s\n` : "Phase 254 budget: a frozen value already exists; a refreeze-proposal deviation was appended instead\n");
  },
  async "restamp-manifest"({ values, flags, env }) {
    const budgetFile = absolute(values.budget ?? BUDGET_PATH);
    const budget = readJson(budgetFile);
    const manifestBytes = fs.readFileSync(absolute(values.manifest ?? MANIFEST_PATH));
    if (flags.has("check")) {
      const outcome = restampCheck({ budget, manifestBytes });
      if (!outcome.ok) {
        process.stderr.write(`Phase 254 budget: FAIL: budget manifest_sha256 ${outcome.expected} differs from the committed manifest ${outcome.actual}\n`);
        process.exitCode = 1;
        return;
      }
      process.stdout.write(`Phase 254 budget: manifest_sha256 matches the committed manifest (${outcome.actual.slice(0, 12)})\n`);
      return;
    }
    if (!flags.has("write")) fail("restamp-manifest needs --check or --write");
    const outcome = restampManifest({ budget, manifestBytes, cause: values.cause, block: values.block, env });
    if (!outcome.changed) { process.stdout.write("Phase 254 budget: manifest_sha256 already matches; nothing appended\n"); return; }
    writeJson(budgetFile, outcome.budget);
    process.stdout.write(`Phase 254 budget: re-stamped manifest_sha256 ${outcome.deviation.from.slice(0, 12)} -> ${outcome.deviation.to.slice(0, 12)} (${outcome.deviation.id}, cause ${outcome.deviation.cause})\n`);
  },
  async "main-reference"({ values }) {
    if (!values.run || !/^\d+$/.test(values.run)) fail("main-reference requires a numeric --run");
    const repo = values.repo ?? "szTheory/accrue";
    if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) fail("--repo must be owner/name");
    const result = spawnSync("gh", ["run", "view", values.run, "--repo", repo, "--json", "jobs,databaseId"], { encoding: "utf8", shell: false, timeout: 120_000, maxBuffer: 64 * 1024 * 1024 });
    if (result.error || result.status !== 0) fail(`gh run view failed: ${(result.stderr || result.error?.message || "").trim().slice(0, 200)}`);
    const reference = mainReferenceFromRun(JSON.parse(result.stdout));
    if (values.out) writeJson(absolute(values.out), reference);
    process.stdout.write(`${JSON.stringify(reference, null, 2)}\n`);
  },
};

async function main(argv) {
  const { positional, flags, values } = parseArgs(argv);
  if (flags.has("self-test")) {
    const count = verifyFixtures();
    process.stdout.write(`phase254 budget: PASS (self-test: ${count} scenarios)\n`);
    return;
  }
  const [verb] = positional;
  if (!verb || !Object.prototype.hasOwnProperty.call(verbs, verb)) fail(`usage: phase254_budget.mjs <${Object.keys(verbs).join("|")}> [options] | --self-test`);
  await verbs[verb]({ positional, flags, values, env: process.env });
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error.message.startsWith("Phase 254 budget:") ? error.message : `Phase 254 budget: FAIL: ${error.message}`);
    process.exitCode = 1;
  });
}
