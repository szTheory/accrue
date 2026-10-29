#!/usr/bin/env node
// Phase 254 UXQ-04 / D-31..D-36: verifier and Markdown renderer for the one bounded design review record.
//
//   --render                   Regenerate the Markdown view from the typed JSON record.
//   --check [--stage S]        Verify the record (S is assessment | corrected | confirmed and must equal
//                              the record's stage) and that the Markdown view equals the renderer output.
//   --self-test                Run every rejection scenario, each paired with a passing control.
//
// The JSON record is the single source (254-DESIGN-REVIEW.json); the Markdown view is generated and
// diff-checked. No gsd-ui-review scoring is re-run and no aesthetic score may appear in the record
// (D-03, D-31): any score-like key and any tmp-path evidence is rejected. Source evidence is bound by
// sha256 to the file at source_commit, so a cited line range cannot silently drift.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { isMainModule } from "./main_module.mjs";
import { repositoryRoot, resolvePhaseEvidencePath } from "./phase_evidence_path.mjs";

export const PHASE_SLUG = "254-recurring-quality-reviewed-fixes-and-curation";
export const RECORD_ARTIFACT = "254-DESIGN-REVIEW.json";
export const VIEW_ARTIFACT = "254-DESIGN-REVIEW.md";

export const STAGES = ["assessment", "corrected", "confirmed"];
export const RUBRIC = ["typography", "color", "hierarchy", "redundancy", "affordances", "microcopy", "journey"];
export const TIERS = ["token", "component", "group", "page", "copy", "contract"];
export const DISPOSITIONS = ["fixed", "contract-amended", "deferred", "rejected"];
export const CAPTURE_STATES = ["settled", "focus-visible", "disclosure-open", "review-open"];
export const CAPTURE_WIDTHS = [320, 1280];
export const CAPTURE_THEMES = ["light", "dark"];
export const VERDICTS = ["finding", "assessed-no-finding"];

export const ASSET_PATHS = {
  app_css: "accrue_admin/assets/css/app.css",
  theme_css: "accrue_admin/assets/css/theme.css",
  accrue_admin_css: "accrue_admin/priv/static/accrue_admin.css",
  storybook_css: "accrue_admin/priv/static/storybook.css"
};

// D-33: the four capture cells, each at 320/1280 x light/dark = 16 captures. A story route is used only
// for settled states; review-open and the focused-disclosure cell need the mounted LiveView (AMD-254-03
// records that the collection "populated" cell is the Phase 253 multiple_rows story).
export const CAPTURE_CELLS = [
  { label: "collection populated", prefix: "phase254-collection-multiple_rows", sourcing: "story", state: "settled", route: "/billing/dev/storybook/iframe/groups/subscriptions_collection?variation_id=multiple_rows" },
  { label: "detail active", prefix: "phase254-page-active", sourcing: "story", state: "settled", route: "/billing/dev/storybook/iframe/pages/subscription?tab=active" },
  { label: "detail review-open", prefix: "phase254-mounted-review-open", sourcing: "mounted", state: "review-open", route: "/billing/subscriptions/:id" },
  { label: "detail disclosure open, summary focused", prefix: "phase254-mounted-disclosure-focus", sourcing: "mounted", state: "focus-visible", route: "/billing/subscriptions/:id" }
];

export function captureCells() {
  const cells = [];
  for (const cell of CAPTURE_CELLS) {
    for (const width of CAPTURE_WIDTHS) {
      for (const theme of CAPTURE_THEMES) {
        const number = String(cells.length + 1).padStart(2, "0");
        cells.push({
          id: `CAP-254-${number}`,
          key: `${cell.prefix}-w${width}-${theme}`,
          sourcing: cell.sourcing,
          route: cell.route,
          width,
          theme,
          state: cell.state,
          png_sha256: null,
          pass: null
        });
      }
    }
  }
  return cells;
}

function fail(message) {
  return new Error(`Phase 254 design review: ${message}`);
}

const sha256 = (data) => crypto.createHash("sha256").update(data).digest("hex");
const md5 = (data) => crypto.createHash("md5").update(data).digest("hex");
const HEX40 = /^[0-9a-f]{40}$/;
const HEX64 = /^[0-9a-f]{64}$/;
const isObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value);
const nonEmptyString = (value) => typeof value === "string" && value.trim().length > 0;
const toText = (data) => (Buffer.isBuffer(data) ? data.toString("utf8") : String(data));

// ---------------------------------------------------------------------------------------------
// Readers (injectable so the rejection scenarios stay pure; the defaults use git and the tree).
// ---------------------------------------------------------------------------------------------

export function gitReader(root = repositoryRoot) {
  return (commit, relativePath) => {
    const result = spawnSync("git", ["-C", root, "show", `${commit}:${relativePath}`], { encoding: "buffer", maxBuffer: 256 * 1024 * 1024 });
    return result.status === 0 ? result.stdout : null;
  };
}

function phaseArtifactParts(contractPath) {
  const segments = String(contractPath).split("/");
  if (segments.length < 4 || segments[0] !== ".planning" || segments[1] !== "phases") return null;
  return { slug: segments[2], artifact: segments.slice(3).join("/") };
}

// Planning-resident files resolve through the archive-safe helper (D-04) so milestone archival cannot
// break the contract-text check.
export function contractReader(root = repositoryRoot) {
  return (contractPath) => {
    const parts = phaseArtifactParts(contractPath);
    if (!parts) return null;
    try {
      return fs.readFileSync(resolvePhaseEvidencePath(parts.slug, parts.artifact, { root }), "utf8");
    } catch {
      return null;
    }
  };
}

export function evidenceExistsReader(root = repositoryRoot) {
  return (artifact) => {
    try {
      return fs.existsSync(resolvePhaseEvidencePath(PHASE_SLUG, artifact, { root }));
    } catch {
      return false;
    }
  };
}

// ---------------------------------------------------------------------------------------------
// Subscription detail spacing scan (D-34 spacing, D-35 scoped CSS guard).
// ---------------------------------------------------------------------------------------------

const SPACE_SCALE_REMS = new Set(["0.125rem", "0.25rem", "0.5rem", "1rem", "1.5rem", "2rem", "3rem", "4rem"]);
const GAP_PROPERTIES = new Set(["gap", "row-gap", "column-gap"]);

function gapComponentIsOnScale(component) {
  return /^var\(--ax-space-[a-z0-9]+\)$/.test(component) || SPACE_SCALE_REMS.has(component);
}

// Finds page-tier gap declarations on `.ax-subscription-detail-page` rules that are not made only of
// --ax-space-* tokens or non-zero on-scale rem rungs: the 1px / 3px / 0 overrides and a raw `0 0.25rem`.
export function scanSubscriptionDetailSpacing(css) {
  if (typeof css !== "string") throw fail("scanSubscriptionDetailSpacing requires CSS text");
  const stripped = css.replace(/\/\*[\s\S]*?\*\//g, (comment) => comment.replace(/[^\n]/g, " "));
  const rulePattern = /([^{}]+)\{([^{}]*)\}/g;
  const findings = [];
  let match;
  while ((match = rulePattern.exec(stripped))) {
    const selector = match[1].trim().replace(/\s+/g, " ");
    if (!selector.includes(".ax-subscription-detail-page")) continue;
    const braceOffset = match.index + match[0].indexOf("{");
    const line = stripped.slice(0, braceOffset).split("\n").length;
    for (const declaration of match[2].split(";")) {
      const colon = declaration.indexOf(":");
      if (colon < 0) continue;
      const property = declaration.slice(0, colon).trim().toLowerCase();
      if (!GAP_PROPERTIES.has(property)) continue;
      const value = declaration.slice(colon + 1).trim().replace(/\s+/g, " ");
      const components = value.split(" ");
      if (!components.every(gapComponentIsOnScale)) findings.push({ selector, property, value, line });
    }
  }
  return findings;
}

// ---------------------------------------------------------------------------------------------
// Record verification.
// ---------------------------------------------------------------------------------------------

function walk(value, visitor, where = "$") {
  if (Array.isArray(value)) {
    value.forEach((item, index) => walk(item, visitor, `${where}[${index}]`));
  } else if (isObject(value)) {
    for (const [key, child] of Object.entries(value)) {
      visitor.key?.(key, `${where}.${key}`);
      walk(child, visitor, `${where}.${key}`);
    }
  } else if (typeof value === "string") {
    visitor.string?.(value, where);
  }
}

function assertNoScoreOrTmpEvidence(record) {
  walk(record, {
    key(key, where) {
      if (/score/i.test(key) || /^(rating|grade)s?$/i.test(key)) {
        throw fail(`score-like key "${key}" at ${where}: the record carries no aesthetic score (D-03, D-31)`);
      }
    },
    string(value, where) {
      if (/(^|[\\/])tmp[\\/]/.test(value)) {
        throw fail(`evidence at ${where} points under a tmp directory ("${value}"); record committed, source-bound evidence only`);
      }
    }
  });
}

function checkRelativePath(value, label) {
  if (!nonEmptyString(value) || path.isAbsolute(value) || value.split("/").some((segment) => segment === ".." || segment === "")) {
    throw fail(`${label}: "${value}" is not a repository-relative path`);
  }
}

function readAtCommit(ctx, commit, relativePath, label) {
  const data = ctx.read(commit, relativePath);
  if (data === null || data === undefined) throw fail(`${label}: cannot read ${relativePath} at commit ${commit}`);
  return data;
}

function checkSourceRef(ref, ctx, label) {
  if (!isObject(ref)) throw fail(`${label}: source_ref must be an object {path, lines, sha, needle}`);
  checkRelativePath(ref.path, `${label} source_ref path`);
  if (!HEX64.test(ref.sha ?? "")) throw fail(`${label}: source_ref ${ref.path} has no sha256`);
  const data = readAtCommit(ctx, ctx.record.source_commit, ref.path, label);
  const actual = sha256(data);
  if (actual !== ref.sha) {
    throw fail(`${label}: source_ref sha for ${ref.path} is stale (record ${ref.sha}, file at source_commit ${actual})`);
  }
  const range = /^(\d+)(?:-(\d+))?$/.exec(ref.lines ?? "");
  if (!range) throw fail(`${label}: source_ref lines "${ref.lines}" for ${ref.path} must be N or N-M`);
  const start = Number(range[1]);
  const end = Number(range[2] ?? range[1]);
  const lines = toText(data).split("\n");
  if (start < 1 || end < start || end > lines.length) {
    throw fail(`${label}: source_ref lines ${ref.lines} are outside ${ref.path} (${lines.length} lines)`);
  }
  if (!nonEmptyString(ref.needle)) throw fail(`${label}: source_ref ${ref.path}:${ref.lines} has no needle`);
  if (!lines.slice(start - 1, end).join("\n").includes(ref.needle)) {
    throw fail(`${label}: source_ref ${ref.path}:${ref.lines} does not contain "${ref.needle}" (the cited lines drifted)`);
  }
}

function checkStage(record) {
  if (!STAGES.includes(record.stage)) throw fail(`stage "${record.stage}" is not one of ${STAGES.join(", ")}`);
  if (!HEX40.test(record.source_commit ?? "")) throw fail("source_commit must be a 40-hex commit sha");
  if (record.stage === "assessment") {
    if (record.fix_commit !== null) throw fail("fix_commit must be null at stage assessment");
  } else if (!HEX40.test(record.fix_commit ?? "")) {
    throw fail(`fix_commit must be a 40-hex commit sha at stage ${record.stage}`);
  }
}

function checkAssets(record, ctx) {
  const assets = record.assets;
  if (!isObject(assets)) throw fail("assets is required");
  const commit = record.stage === "assessment" ? record.source_commit : record.fix_commit;
  const bodies = {};
  for (const [name, expectedPath] of Object.entries(ASSET_PATHS)) {
    const entry = assets[name];
    if (!isObject(entry) || entry.path !== expectedPath || !HEX64.test(entry.sha256 ?? "")) {
      throw fail(`assets.${name} must be {path: ${expectedPath}, sha256}`);
    }
    const data = readAtCommit(ctx, commit, expectedPath, `assets.${name}`);
    bodies[name] = data;
    if (sha256(data) !== entry.sha256) {
      throw fail(`assets.${name} sha256 is stale (record ${entry.sha256}, ${expectedPath} at ${commit} is ${sha256(data)})`);
    }
  }
  const route = `css-${md5(bodies.accrue_admin_css)}`;
  if (assets.served_css_route !== route) {
    throw fail(`assets.served_css_route ${assets.served_css_route} does not equal ${route} (md5 of priv/static/accrue_admin.css)`);
  }
  if (!toText(bodies.storybook_css).includes(toText(bodies.accrue_admin_css))) {
    throw fail("storybook.css does not contain the accrue_admin.css bytes; run node scripts/ci/recompose_storybook_css.mjs --write before capturing (D-33)");
  }
}

function checkRubric(record) {
  if (!Array.isArray(record.rubric) || record.rubric.length !== RUBRIC.length || RUBRIC.some((name, index) => record.rubric[index] !== name)) {
    throw fail(`rubric must be exactly ${RUBRIC.join(", ")}`);
  }
}

function findingDimensions(finding) {
  return [finding.dimension, ...(Array.isArray(finding.also_dimensions) ? finding.also_dimensions : [])];
}

function checkCaptures(record) {
  if (!Array.isArray(record.captures) || record.captures.length !== 16) {
    throw fail(`captures must hold exactly 16 cells (D-33), found ${Array.isArray(record.captures) ? record.captures.length : "none"}`);
  }
  const ids = new Set();
  const keys = new Set();
  const expected = new Map(captureCells().map((cell) => [cell.key, cell]));
  for (const capture of record.captures) {
    if (!isObject(capture)) throw fail("capture must be an object");
    if (!/^CAP-254-\d{2}$/.test(capture.id ?? "")) throw fail(`capture id "${capture.id}" must look like CAP-254-NN`);
    if (ids.has(capture.id)) throw fail(`duplicate capture id ${capture.id}`);
    ids.add(capture.id);
    if (!CAPTURE_STATES.includes(capture.state)) throw fail(`${capture.id}: state "${capture.state}" is not one of ${CAPTURE_STATES.join(", ")}`);
    if (!["story", "mounted"].includes(capture.sourcing)) throw fail(`${capture.id}: sourcing must be story or mounted`);
    const cell = expected.get(capture.key);
    if (!cell) throw fail(`${capture.id}: key "${capture.key}" is not one of the four D-33 key patterns at 320/1280 x light/dark`);
    if (keys.has(capture.key)) throw fail(`duplicate capture key ${capture.key}`);
    keys.add(capture.key);
    if (capture.sourcing !== cell.sourcing || capture.state !== cell.state) {
      throw fail(`${capture.id}: key ${capture.key} requires ${cell.sourcing} sourcing and state ${cell.state}, found ${capture.sourcing} / ${capture.state}`);
    }
    if (["review-open", "focus-visible", "disclosure-open"].includes(capture.state) && capture.sourcing === "story") {
      throw fail(`${capture.id}: state ${capture.state} cannot be sourced from a story route; it needs the mounted LiveView`);
    }
    if (capture.width !== cell.width || capture.theme !== cell.theme) {
      throw fail(`${capture.id}: width/theme must be ${cell.width}/${cell.theme} for key ${capture.key}`);
    }
    if (!nonEmptyString(capture.route)) throw fail(`${capture.id}: route is required`);
    if (record.stage === "assessment") {
      if (capture.png_sha256 !== null || capture.pass !== null) {
        throw fail(`${capture.id}: png_sha256 and pass must be null at stage assessment (no capture exists yet)`);
      }
    } else if (record.stage === "confirmed") {
      if (!HEX64.test(capture.png_sha256 ?? "")) throw fail(`${capture.id}: a confirmed record needs png_sha256 for every capture`);
      if (typeof capture.pass !== "boolean") throw fail(`${capture.id}: a confirmed record needs a boolean pass`);
    } else if (capture.png_sha256 !== null && !HEX64.test(capture.png_sha256)) {
      throw fail(`${capture.id}: png_sha256 must be null or a sha256`);
    }
  }
  return ids;
}

function checkFindings(record, ctx, captureIds) {
  if (!Array.isArray(record.findings) || record.findings.length === 0) throw fail("findings must be a non-empty list");
  const ids = new Set();
  for (const finding of record.findings) {
    const label = finding?.id ?? "finding";
    if (!isObject(finding) || !/^DR-254-\d{2}$/.test(finding.id ?? "")) throw fail(`finding id "${finding?.id}" must look like DR-254-NN`);
    if (ids.has(finding.id)) throw fail(`duplicate finding id ${finding.id}`);
    ids.add(finding.id);
    if (!/^(253#[1-9]\d*|assessment)$/.test(finding.origin ?? "")) throw fail(`${label}: origin "${finding.origin}" must be 253#n or assessment`);
    if (!RUBRIC.includes(finding.dimension)) throw fail(`${label}: dimension "${finding.dimension}" is not a rubric dimension`);
    for (const extra of finding.also_dimensions ?? []) {
      if (!RUBRIC.includes(extra)) throw fail(`${label}: also_dimensions entry "${extra}" is not a rubric dimension`);
    }
    if (!nonEmptyString(finding.claim)) throw fail(`${label}: claim is required`);
    if (!Array.isArray(finding.source_refs) || finding.source_refs.length === 0) throw fail(`${label}: source_refs must be non-empty`);
    finding.source_refs.forEach((ref) => checkSourceRef(ref, ctx, label));
    if (!TIERS.includes(finding.owning_tier)) throw fail(`${label}: owning_tier "${finding.owning_tier}" is not one of ${TIERS.join(", ")}`);
    if (!DISPOSITIONS.includes(finding.disposition)) throw fail(`${label}: disposition "${finding.disposition}" is not one of ${DISPOSITIONS.join(", ")}`);
    if (!nonEmptyString(finding.rationale)) throw fail(`${label}: rationale is required`);
    for (const list of ["evidence_captures", "confirmation_captures"]) {
      for (const id of finding[list] ?? []) {
        if (!captureIds.has(id)) throw fail(`${label}: ${list} names unknown capture ${id}`);
      }
    }
    if (!Array.isArray(finding.tests)) throw fail(`${label}: tests must be a list`);
    for (const test of finding.tests) {
      checkRelativePath(test?.path, `${label} test path`);
      if (!nonEmptyString(test.kind) || !nonEmptyString(test.status)) throw fail(`${label}: every test needs a kind and a status`);
    }
    checkFindingForStage(finding, record, ctx);
  }
  return ids;
}

function checkFindingForStage(finding, record, ctx) {
  const label = finding.id;
  if (finding.disposition === "fixed") {
    if (finding.tests.length === 0) throw fail(`${label}: a fixed finding must list its tests`);
    if (record.stage === "assessment") {
      if (finding.tests.some((test) => test.status !== "pending")) throw fail(`${label}: tests are planned (status pending) at stage assessment`);
    } else {
      if (finding.tests.some((test) => test.status === "pending")) throw fail(`${label}: a fixed finding at stage ${record.stage} has a pending test`);
      const red = finding.red_evidence;
      if (!Array.isArray(red) || red.length === 0) throw fail(`${label}: a fixed finding at stage ${record.stage} needs a red-evidence reference`);
      for (const artifact of red) {
        if (!nonEmptyString(artifact) || !ctx.evidenceExists(artifact)) throw fail(`${label}: red evidence ${artifact} does not exist in the phase directory`);
      }
    }
  }
  if (finding.disposition === "contract-amended") checkContract(finding, record, ctx);
  if (finding.disposition === "rejected" && !nonEmptyString(finding.rationale)) throw fail(`${label}: a rejected finding needs a rationale`);
  if (record.stage === "assessment") {
    if (finding.verdict !== null || (finding.confirmation_captures ?? []).length > 0) {
      throw fail(`${label}: verdict must be null and confirmation_captures empty at stage assessment`);
    }
  } else if (record.stage === "confirmed" && !["confirmed", "not-confirmed"].includes(finding.verdict)) {
    throw fail(`${label}: a confirmed record needs verdict confirmed or not-confirmed`);
  }
  if (finding.mechanical_check) checkMechanicalCheck(finding, record, ctx);
}

function checkContract(finding, record, ctx) {
  const label = finding.id;
  const contract = finding.contract;
  if (!isObject(contract) || !nonEmptyString(contract.path) || !nonEmptyString(contract.row) || !nonEmptyString(contract.section) || !nonEmptyString(contract.amended_text)) {
    throw fail(`${label}: a contract-amended finding needs contract.path, contract.section, contract.row and contract.amended_text`);
  }
  if (!["amend-row", "add-row"].includes(contract.action)) throw fail(`${label}: contract.action must be amend-row or add-row`);
  const text = ctx.readContract(contract.path);
  if (text === null || text === undefined) throw fail(`${label}: contract file ${contract.path} could not be read`);
  const rowPattern = new RegExp(`^\\|\\s*${contract.row.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\s*\\|`, "m");
  if (record.stage === "assessment") {
    const exists = rowPattern.test(text);
    if (contract.action === "amend-row" && !exists) throw fail(`${label}: row "${contract.row}" to amend is absent from ${contract.path}`);
    if (contract.action === "add-row" && exists) throw fail(`${label}: row "${contract.row}" to add already exists in ${contract.path}`);
  } else if (!text.includes(contract.amended_text)) {
    throw fail(`${label}: amended_text for row "${contract.row}" was not found in ${contract.path}`);
  }
}

function checkMechanicalCheck(finding, record, ctx) {
  const check = finding.mechanical_check;
  if (check?.id !== "subscription-detail-spacing") throw fail(`${finding.id}: unknown mechanical_check ${check?.id}`);
  const commit = record.stage === "assessment" ? record.source_commit : record.fix_commit;
  const css = toText(readAtCommit(ctx, commit, check.path, `${finding.id} mechanical_check`));
  const found = scanSubscriptionDetailSpacing(css).length;
  if (record.stage === "assessment" && found === 0) {
    throw fail(`${finding.id}: the spacing scan finds no page-tier gap override at source_commit, so the finding has no mechanical basis`);
  }
  if (record.stage !== "assessment" && finding.disposition === "fixed" && found > 0) {
    throw fail(`${finding.id}: the spacing scan still finds ${found} page-tier gap override(s) at fix_commit`);
  }
}

function checkRubricVerdicts(record, ctx, captureIds, findingIds) {
  if (!Array.isArray(record.rubric_verdicts)) throw fail("rubric_verdicts must be a list");
  const seen = new Set();
  const byId = new Map(record.findings.map((finding) => [finding.id, finding]));
  for (const verdict of record.rubric_verdicts) {
    if (!isObject(verdict) || !RUBRIC.includes(verdict.dimension)) throw fail(`rubric verdict dimension "${verdict?.dimension}" is not a rubric dimension`);
    if (seen.has(verdict.dimension)) throw fail(`duplicate rubric verdict for ${verdict.dimension}`);
    seen.add(verdict.dimension);
    if (!VERDICTS.includes(verdict.verdict)) throw fail(`${verdict.dimension}: verdict "${verdict.verdict}" must be finding or assessed-no-finding`);
    if (verdict.verdict === "finding") {
      if (!Array.isArray(verdict.finding_ids) || verdict.finding_ids.length === 0) throw fail(`${verdict.dimension}: a finding verdict needs finding_ids`);
      for (const id of verdict.finding_ids) {
        if (!findingIds.has(id)) throw fail(`${verdict.dimension}: finding verdict names unknown finding ${id}`);
        if (!findingDimensions(byId.get(id)).includes(verdict.dimension)) {
          throw fail(`${verdict.dimension}: finding ${id} carries dimension ${byId.get(id).dimension}, not ${verdict.dimension}`);
        }
      }
    } else {
      if (!Array.isArray(verdict.capture_ids) || verdict.capture_ids.length === 0) throw fail(`${verdict.dimension}: an assessed-no-finding verdict needs capture_ids`);
      for (const id of verdict.capture_ids) if (!captureIds.has(id)) throw fail(`${verdict.dimension}: unknown capture ${id}`);
      if (!Array.isArray(verdict.source_refs) || verdict.source_refs.length === 0) throw fail(`${verdict.dimension}: an assessed-no-finding verdict needs source_refs`);
      verdict.source_refs.forEach((ref) => checkSourceRef(ref, ctx, `${verdict.dimension} verdict`));
      if (!nonEmptyString(verdict.rationale)) throw fail(`${verdict.dimension}: an assessed-no-finding verdict needs a rationale`);
      const contradicting = record.findings.find((finding) => findingDimensions(finding).includes(verdict.dimension));
      if (contradicting) throw fail(`${verdict.dimension}: assessed-no-finding contradicts finding ${contradicting.id}, which carries that dimension`);
    }
  }
  for (const dimension of RUBRIC) if (!seen.has(dimension)) throw fail(`rubric dimension ${dimension} has no verdict`);
}

function checkAmendments(record) {
  if (!Array.isArray(record.amendments)) throw fail("amendments must be a list");
  const ids = new Set();
  for (const amendment of record.amendments) {
    if (!isObject(amendment) || !/^AMD-254-\d{2}$/.test(amendment.id ?? "")) throw fail(`amendment id "${amendment?.id}" must look like AMD-254-NN`);
    if (ids.has(amendment.id)) throw fail(`duplicate amendment ${amendment.id}`);
    ids.add(amendment.id);
    if (!Array.isArray(amendment.decisions) || amendment.decisions.length === 0) throw fail(`${amendment.id}: decisions is required`);
    for (const field of ["original", "amended", "rationale"]) if (!nonEmptyString(amendment[field])) throw fail(`${amendment.id}: ${field} is required`);
    if (!Array.isArray(amendment.evidence) || amendment.evidence.length === 0) throw fail(`${amendment.id}: evidence is required`);
    const ack = amendment.owner_ack;
    if (!isObject(ack) || !/^\d{4}-\d{2}-\d{2}$/.test(ack.date ?? "") || !nonEmptyString(ack.status)) {
      throw fail(`${amendment.id}: owner_ack {date, status} is required`);
    }
  }
}

function checkBaselines(record, findingIds) {
  if (!Array.isArray(record.baselines_changed)) throw fail("baselines_changed must be a list");
  for (const entry of record.baselines_changed) {
    if (!isObject(entry) || !nonEmptyString(entry.key)) throw fail("every changed baseline needs a key");
    if (!findingIds.has(entry.finding_id)) throw fail(`changed baseline ${entry.key} maps to no finding (finding_id "${entry.finding_id}")`);
  }
}

function checkDeferred(record, findingIds) {
  if (!Array.isArray(record.deferred)) throw fail("deferred must be a list");
  const ids = new Set();
  const referenced = new Set();
  for (const entry of record.deferred) {
    if (!isObject(entry) || !/^DEF-254-\d{2}$/.test(entry.id ?? "")) throw fail(`deferred id "${entry?.id}" must look like DEF-254-NN`);
    if (ids.has(entry.id)) throw fail(`duplicate deferred entry ${entry.id}`);
    ids.add(entry.id);
    if (!nonEmptyString(entry.subject)) throw fail(`${entry.id}: subject is required`);
    if (!TIERS.includes(entry.tier)) throw fail(`${entry.id}: tier "${entry.tier}" is not one of ${TIERS.join(", ")}`);
    if (!nonEmptyString(entry.trigger)) throw fail(`${entry.id}: a deferral needs a trigger`);
    if (entry.finding_id !== undefined && entry.finding_id !== null) {
      if (!findingIds.has(entry.finding_id)) throw fail(`${entry.id}: unknown finding ${entry.finding_id}`);
      referenced.add(entry.finding_id);
    }
  }
  for (const finding of record.findings) {
    if (finding.disposition === "deferred" && !referenced.has(finding.id)) {
      throw fail(`${finding.id}: a deferred finding needs a deferred[] entry (tier and trigger)`);
    }
  }
}

export function verifyDesignReview(record, { root = repositoryRoot, stage, read, readContract, evidenceExists } = {}) {
  if (!isObject(record)) throw fail("the record must be an object");
  assertNoScoreOrTmpEvidence(record);
  checkStage(record);
  if (stage !== undefined && record.stage !== stage) throw fail(`the record is at stage ${record.stage}, not ${stage}`);
  const ctx = {
    record,
    read: read ?? gitReader(root),
    readContract: readContract ?? contractReader(root),
    evidenceExists: evidenceExists ?? evidenceExistsReader(root)
  };
  checkAssets(record, ctx);
  checkRubric(record);
  const captureIds = checkCaptures(record);
  const findingIds = checkFindings(record, ctx, captureIds);
  checkRubricVerdicts(record, ctx, captureIds, findingIds);
  checkAmendments(record);
  checkBaselines(record, findingIds);
  checkDeferred(record, findingIds);
  return {
    stage: record.stage,
    findings: record.findings.length,
    captures: record.captures.length,
    verdicts: record.rubric_verdicts.length,
    deferred: record.deferred.length
  };
}

// ---------------------------------------------------------------------------------------------
// Markdown view (S4: untrusted strings are escaped before they reach a table or a heading).
// ---------------------------------------------------------------------------------------------

function escapeCell(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/\|/g, "&#124;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\r?\n/g, " ");
}

const code = (value) => `\`${escapeCell(value).replace(/`/g, "'")}\``;

export function renderDesignReview(record) {
  const lines = [];
  const push = (line = "") => lines.push(line);
  push("# Phase 254 design review");
  push();
  push("<!-- Generated from 254-DESIGN-REVIEW.json by scripts/ci/verify_phase254_design_review.mjs --render. Do not edit by hand. -->");
  push();
  push(`**Stage:** ${escapeCell(record.stage)}`);
  push(`**Source commit:** ${code(record.source_commit)}`);
  push(`**Fix commit:** ${record.fix_commit ? code(record.fix_commit) : "none yet"}`);
  push("**Scoring:** none. No aesthetic score is recorded (D-03, D-31); every cell is a source-bound claim or a mechanical result.");
  push();
  push("## Assets");
  push();
  push("| Asset | Path | sha256 |");
  push("|-------|------|--------|");
  for (const name of Object.keys(ASSET_PATHS)) {
    const entry = record.assets?.[name] ?? {};
    push(`| ${escapeCell(name)} | ${code(entry.path)} | ${code(entry.sha256)} |`);
  }
  push(`| served_css_route | ${code(record.assets?.served_css_route)} | md5 of accrue_admin.css |`);
  push();
  push("## Rubric verdicts");
  push();
  push("| Dimension | Verdict | Findings or evidence |");
  push("|-----------|---------|----------------------|");
  for (const verdict of record.rubric_verdicts ?? []) {
    const detail = verdict.verdict === "finding"
      ? (verdict.finding_ids ?? []).join(", ")
      : `captures ${(verdict.capture_ids ?? []).join(", ")}; ${(verdict.source_refs ?? []).map((ref) => `${ref.path}:${ref.lines}`).join(", ")}; ${verdict.rationale ?? ""}`;
    push(`| ${escapeCell(verdict.dimension)} | ${escapeCell(verdict.verdict)} | ${escapeCell(detail)} |`);
  }
  push();
  push("## Captures");
  push();
  push("| Id | Key | Sourcing | State | Width | Theme | Route | png sha256 | Pass |");
  push("|----|-----|----------|-------|-------|-------|-------|------------|------|");
  for (const capture of record.captures ?? []) {
    push(`| ${escapeCell(capture.id)} | ${code(capture.key)} | ${escapeCell(capture.sourcing)} | ${escapeCell(capture.state)} | ${escapeCell(capture.width)} | ${escapeCell(capture.theme)} | ${code(capture.route)} | ${capture.png_sha256 ? code(capture.png_sha256) : "pending"} | ${capture.pass === null ? "pending" : escapeCell(capture.pass)} |`);
  }
  push();
  push("## Findings");
  for (const finding of record.findings ?? []) {
    push();
    push(`### ${escapeCell(finding.id)} ${escapeCell(finding.dimension)}${(finding.also_dimensions ?? []).length ? ` (+ ${escapeCell(finding.also_dimensions.join(", "))})` : ""}`);
    push();
    push(`- **Origin:** ${escapeCell(finding.origin)}`);
    push(`- **Owning tier:** ${escapeCell(finding.owning_tier)}`);
    push(`- **Disposition:** ${escapeCell(finding.disposition)}`);
    push(`- **Verdict:** ${finding.verdict ? escapeCell(finding.verdict) : "pending"}`);
    push(`- **Claim:** ${escapeCell(finding.claim)}`);
    push(`- **Rationale:** ${escapeCell(finding.rationale)}`);
    push(`- **Evidence:** ${(finding.source_refs ?? []).map((ref) => code(`${ref.path}:${ref.lines}`)).join(", ")}`);
    if ((finding.tests ?? []).length) {
      push(`- **Tests:** ${finding.tests.map((entry) => `${code(entry.path)} (${escapeCell(entry.kind)}, ${escapeCell(entry.status)}${entry.id ? `, ${escapeCell(entry.id)}` : ""})`).join("; ")}`);
    }
    if ((finding.red_evidence ?? []).length) push(`- **Red evidence:** ${finding.red_evidence.map((entry) => code(entry)).join(", ")}`);
    if (finding.contract) {
      push(`- **Contract:** ${code(finding.contract.path)}, section ${escapeCell(finding.contract.section)}, ${escapeCell(finding.contract.action)} row ${code(finding.contract.row)}`);
      push(`- **Amended text:** ${code(finding.contract.amended_text)}`);
    }
  }
  push();
  push("## Amendments");
  push();
  if ((record.amendments ?? []).length === 0) push("None.");
  for (const amendment of record.amendments ?? []) {
    push(`- **${escapeCell(amendment.id)}** (${escapeCell((amendment.decisions ?? []).join(", "))}): ${escapeCell(amendment.original)} -> ${escapeCell(amendment.amended)}. ${escapeCell(amendment.rationale)} Owner acknowledgement: ${escapeCell(amendment.owner_ack?.date)} ${escapeCell(amendment.owner_ack?.status)}.`);
  }
  push();
  push("## Changed baselines");
  push();
  if ((record.baselines_changed ?? []).length === 0) push("None.");
  for (const entry of record.baselines_changed ?? []) push(`- ${code(entry.key)} -> ${escapeCell(entry.finding_id)}`);
  push();
  push("## Deferred");
  push();
  push("| Id | Subject | Tier | Trigger | Finding |");
  push("|----|---------|------|---------|---------|");
  for (const entry of record.deferred ?? []) {
    push(`| ${escapeCell(entry.id)} | ${escapeCell(entry.subject)} | ${escapeCell(entry.tier)} | ${escapeCell(entry.trigger)} | ${escapeCell(entry.finding_id ?? "")} |`);
  }
  return `${lines.join("\n")}\n`;
}

// ---------------------------------------------------------------------------------------------
// Self-test fixtures: a small valid record over an in-memory file set (no git, no tree).
// ---------------------------------------------------------------------------------------------

const FIXTURE_COMMIT = "a".repeat(40);
const FIXTURE_FIX_COMMIT = "b".repeat(40);
const FIXTURE_CONTRACT_PATH = path.posix.join(".planning", "phases", "253-fixture", "253-UI-SPEC.md");
const FIXTURE_CONTRACT = "## Typography\n\n| Role | Size |\n|------|------|\n| Page heading | 28px |\n";
const FIXTURE_FILES = {
  [ASSET_PATHS.app_css]: ".a{color:red}\n.ax-subscription-detail-page{gap:0.0625rem}\n.b{margin:0}\n",
  [ASSET_PATHS.theme_css]: ":root{--ax-space-xs:0.25rem}\n",
  [ASSET_PATHS.accrue_admin_css]: ".ax-admin{display:block}\n",
  [ASSET_PATHS.storybook_css]: "/* header */\n.ax-admin{display:block}\n\n/* shim */\n",
  "src/page.css": "line one\nline two with .ax-subscription-detail-page marker\nline three\n"
};

function fixtureRef(file, lines, needle, files = FIXTURE_FILES) {
  return { path: file, lines, sha: sha256(files[file]), needle };
}

export function fixtureHarness(overrides = {}) {
  const files = { ...FIXTURE_FILES, ...(overrides.files ?? {}) };
  const readMap = (commit, relativePath) => {
    if (commit !== FIXTURE_COMMIT && commit !== FIXTURE_FIX_COMMIT) return null;
    return Object.hasOwn(files, relativePath) ? Buffer.from(files[relativePath]) : null;
  };
  const record = {
    schema_version: 1,
    stage: "assessment",
    source_commit: FIXTURE_COMMIT,
    fix_commit: null,
    assets: {
      app_css: { path: ASSET_PATHS.app_css, sha256: sha256(files[ASSET_PATHS.app_css]) },
      theme_css: { path: ASSET_PATHS.theme_css, sha256: sha256(files[ASSET_PATHS.theme_css]) },
      accrue_admin_css: { path: ASSET_PATHS.accrue_admin_css, sha256: sha256(files[ASSET_PATHS.accrue_admin_css]) },
      storybook_css: { path: ASSET_PATHS.storybook_css, sha256: sha256(files[ASSET_PATHS.storybook_css]) },
      served_css_route: `css-${md5(files[ASSET_PATHS.accrue_admin_css])}`
    },
    rubric: [...RUBRIC],
    rubric_verdicts: [
      { dimension: "typography", verdict: "finding", finding_ids: ["DR-254-02"] },
      { dimension: "color", verdict: "assessed-no-finding", capture_ids: ["CAP-254-01"], source_refs: [fixtureRef("src/page.css", "1-2", "line one", files)], rationale: "No color defect in the examined rules." },
      { dimension: "hierarchy", verdict: "finding", finding_ids: ["DR-254-01"] },
      { dimension: "redundancy", verdict: "assessed-no-finding", capture_ids: ["CAP-254-05"], source_refs: [fixtureRef("src/page.css", "2-3", "line three", files)], rationale: "No redundant selectors in the examined rules." },
      { dimension: "affordances", verdict: "assessed-no-finding", capture_ids: ["CAP-254-13"], source_refs: [fixtureRef("src/page.css", "1-3", "line two", files)], rationale: "Native summary controls examined." },
      { dimension: "microcopy", verdict: "finding", finding_ids: ["DR-254-03"] },
      { dimension: "journey", verdict: "assessed-no-finding", capture_ids: ["CAP-254-01", "CAP-254-05", "CAP-254-09", "CAP-254-13"], source_refs: [fixtureRef("src/page.css", "1-3", "line two", files)], rationale: "List to detail to action to result examined." }
    ],
    captures: captureCells(),
    findings: [
      {
        id: "DR-254-01",
        origin: "253#1",
        dimension: "hierarchy",
        claim: "Page-tier gap overrides compress the detail groups.",
        source_refs: [fixtureRef(ASSET_PATHS.app_css, "2", ".ax-subscription-detail-page", files)],
        evidence_captures: ["CAP-254-05"],
        owning_tier: "page",
        disposition: "fixed",
        rationale: "Remove the overrides so the component tokens apply.",
        tests: [{ path: "accrue_admin/e2e/fixture.spec.js", kind: "computed", status: "pending" }],
        mechanical_check: { id: "subscription-detail-spacing", path: ASSET_PATHS.app_css },
        confirmation_captures: [],
        verdict: null
      },
      {
        id: "DR-254-02",
        origin: "253#2",
        dimension: "typography",
        claim: "The heading contract names one size for a responsive heading.",
        source_refs: [fixtureRef("src/page.css", "2", "line two", files)],
        evidence_captures: ["CAP-254-01"],
        owning_tier: "contract",
        disposition: "contract-amended",
        rationale: "Amend the contract row.",
        tests: [],
        contract: {
          path: FIXTURE_CONTRACT_PATH,
          section: "Typography",
          action: "amend-row",
          row: "Page heading",
          amended_text: "| Page heading | 24px below 768px, 28px from 768px |"
        },
        confirmation_captures: [],
        verdict: null
      },
      {
        id: "DR-254-03",
        origin: "assessment",
        dimension: "microcopy",
        claim: "A dev-sounding label.",
        source_refs: [fixtureRef("src/page.css", "3", "line three", files)],
        evidence_captures: ["CAP-254-13"],
        owning_tier: "copy",
        disposition: "deferred",
        rationale: "Wording needs a product decision.",
        tests: [],
        confirmation_captures: [],
        verdict: null
      }
    ],
    amendments: [
      {
        id: "AMD-254-03",
        decisions: ["D-33"],
        original: "collection populated",
        amended: "Phase 253 multiple_rows",
        rationale: "No populated collection state exists.",
        evidence: ["accrue_admin/storybook/_support/subscription_compositions_manifest.ex"],
        owner_ack: { date: "2026-10-28", status: "owner-accepted at plan time" }
      }
    ],
    baselines_changed: [],
    deferred: [
      { id: "DEF-254-01", subject: "A dev-sounding label", tier: "copy", trigger: "The next audit strip copy pass.", finding_id: "DR-254-03" }
    ]
  };
  const harness = {
    record,
    files,
    options: {
      read: readMap,
      readContract: (contractPath) => (contractPath === FIXTURE_CONTRACT_PATH ? (overrides.contract ?? FIXTURE_CONTRACT) : null),
      evidenceExists: (artifact) => (overrides.evidence ?? ["fixture-red-evidence.json"]).includes(artifact)
    }
  };
  return harness;
}

const clone = (value) => JSON.parse(JSON.stringify(value));

function rejects(mutate, pattern, { stage, files, contract } = {}) {
  const harness = fixtureHarness({ files, contract });
  const record = clone(harness.record);
  mutate(record, harness);
  assert.throws(() => verifyDesignReview(record, { ...harness.options, stage }), pattern);
}

function toCorrected(record) {
  record.stage = "corrected";
  record.fix_commit = FIXTURE_FIX_COMMIT;
  const fixed = record.findings[0];
  fixed.tests = [{ path: "accrue_admin/e2e/fixture.spec.js", kind: "computed", status: "red-then-green" }];
  fixed.red_evidence = ["fixture-red-evidence.json"];
  record.findings[0].mechanical_check = { id: "subscription-detail-spacing", path: ASSET_PATHS.app_css };
}

const FIXED_APP_CSS = ".a{color:red}\n.ax-subscription-detail-page{gap:var(--ax-space-xs)}\n.b{margin:0}\n";
const CORRECTED_CONTRACT = `${FIXTURE_CONTRACT}| Page heading | 24px below 768px, 28px from 768px |\n`;

export const SCENARIOS = [
  [
    "a valid record at stage assessment passes (control for every rejection below)",
    () => {
      const { record, options } = fixtureHarness();
      const summary = verifyDesignReview(record, { ...options, stage: "assessment" });
      assert.equal(summary.captures, 16);
      assert.equal(summary.verdicts, 7);
    }
  ],
  [
    "score-like keys are rejected anywhere, and a record with no such key passes",
    () => {
      for (const key of ["score", "rating", "grade", "total_score", "aestheticScore"]) {
        rejects((record) => { record.findings[0][key] = 3; }, /score-like key/);
      }
      rejects((record) => { record.captures[0].meta = { nested: [{ Score: 1 }] }; }, /score-like key/);
    }
  ],
  [
    "evidence paths under tmp directories are rejected",
    () => {
      rejects((record) => { record.findings[0].tests[0].path = "accrue_admin/tmp/phase254/spec.js"; }, /tmp directory/);
      rejects((record) => { record.amendments[0].evidence = ["tmp/phase254/result.json"]; }, /tmp directory/);
    }
  ],
  [
    "a source_ref whose sha differs from the file at source_commit is rejected",
    () => {
      rejects((record) => { record.findings[0].source_refs[0].sha = "0".repeat(64); }, /stale/);
      rejects((record) => { record.findings[0].source_refs[0].needle = "absent needle"; }, /drifted/);
      rejects((record) => { record.findings[0].source_refs[0].lines = "99"; }, /outside/);
      rejects((record) => { record.findings[0].source_refs[0].path = "../escape.css"; }, /repository-relative/);
    }
  ],
  [
    "asset sha, served route and the storybook embed are checked",
    () => {
      rejects((record) => { record.assets.app_css.sha256 = "1".repeat(64); }, /assets\.app_css sha256 is stale/);
      rejects((record) => { record.assets.served_css_route = "css-deadbeef"; }, /served_css_route/);
      rejects(() => {}, /does not contain the accrue_admin\.css bytes/, {
        files: { [ASSET_PATHS.storybook_css]: "/* stale */\n.old{}\n" }
      });
    }
  ],
  [
    "out-of-enum owning_tier, disposition, dimension and origin are rejected",
    () => {
      rejects((record) => { record.findings[0].owning_tier = "page-ish"; }, /owning_tier/);
      rejects((record) => { record.findings[0].disposition = "wontfix"; }, /disposition/);
      rejects((record) => { record.findings[0].dimension = "polish"; }, /dimension/);
      rejects((record) => { record.findings[0].origin = "253#0"; }, /origin/);
    }
  ],
  [
    "a stage confirmed record with a capture lacking png_sha256 is rejected",
    () => {
      const confirm = (record) => {
        toCorrected(record);
        record.stage = "confirmed";
        record.captures.forEach((capture, index) => { capture.png_sha256 = sha256(`png ${index}`); capture.pass = true; });
        record.findings.forEach((finding) => { finding.verdict = "confirmed"; });
      };
      const harness = fixtureHarness({ files: { [ASSET_PATHS.app_css]: FIXED_APP_CSS }, contract: CORRECTED_CONTRACT });
      const record = clone(harness.record);
      confirm(record);
      assert.doesNotThrow(() => verifyDesignReview(record, { ...harness.options, stage: "confirmed" }));
      record.captures[4].png_sha256 = null;
      assert.throws(() => verifyDesignReview(record, { ...harness.options, stage: "confirmed" }), /png_sha256/);
    }
  ],
  [
    "assessment-stage captures must still be pending, and the stage flag must match the record",
    () => {
      rejects((record) => { record.captures[0].png_sha256 = "2".repeat(64); }, /png_sha256 and pass must be null/);
      rejects(() => {}, /not corrected/, { stage: "corrected" });
    }
  ],
  [
    "a baselines_changed entry without a finding id is rejected, with a control that maps",
    () => {
      rejects((record) => { record.baselines_changed = [{ key: "subscription-detail", finding_id: null }]; }, /maps to no finding/);
      rejects((record) => { record.baselines_changed = [{ key: "subscription-detail", finding_id: "DR-254-99" }]; }, /maps to no finding/);
      const { record, options } = fixtureHarness();
      record.baselines_changed = [{ key: "subscription-detail", finding_id: "DR-254-01" }];
      assert.doesNotThrow(() => verifyDesignReview(record, options));
    }
  ],
  [
    "a Markdown view that is not the renderer output is rejected, and a hostile cell is escaped",
    () => {
      const { record } = fixtureHarness();
      const view = renderDesignReview(record);
      assert.doesNotThrow(() => assertViewMatches(record, view));
      assert.throws(() => assertViewMatches(record, `${view}\nedited by hand`), /stale|not the renderer/);
      const hostile = clone(record);
      hostile.findings[0].claim = "x | y <script>alert(1)</script>\nsecond line";
      const rendered = renderDesignReview(hostile);
      assert.ok(!rendered.includes("<script>"));
      assert.ok(rendered.includes("&lt;script&gt;"));
      assert.ok(rendered.includes("x &#124; y"));
    }
  ],
  [
    "the spacing scan finds the 1px, 3px, zero and raw 0 0.25rem page-tier gaps and passes token-only CSS",
    () => {
      const defective = [
        ".ax-subscription-detail-page { gap: 0.0625rem; }",
        ".ax-subscription-detail-page .ax-stack-md { gap: 0.1875rem; }",
        ".ax-subscription-detail-page .ax-field-list, .ax-subscription-detail-page .ax-field-list-compact { gap: 0; }",
        ".ax-subscription-detail-page .ax-field { gap: 0 0.25rem; }",
        "@media (min-width: 768px) { .ax-subscription-detail-page .ax-x { row-gap: 3px; } }"
      ].join("\n");
      assert.equal(scanSubscriptionDetailSpacing(defective).length, 5);
      const tokenOnly = [
        ".ax-subscription-detail-page { gap: var(--ax-space-md); }",
        ".ax-subscription-detail-page .ax-field { gap: var(--ax-space-2xs) var(--ax-space-xs); }",
        ".ax-subscription-detail-page .ax-breadcrumbs-list { gap: 0.125rem; }",
        "/* .ax-subscription-detail-page { gap: 0 } */",
        ".ax-other { gap: 0; }"
      ].join("\n");
      assert.deepEqual(scanSubscriptionDetailSpacing(tokenOnly), []);
    }
  ],
  [
    "rubric_verdicts reject a missing redundancy, a missing journey, a duplicate, a cross-dimension finding and an empty no-finding verdict",
    () => {
      rejects((record) => { record.rubric_verdicts = record.rubric_verdicts.filter((entry) => entry.dimension !== "redundancy"); }, /redundancy has no verdict/);
      rejects((record) => { record.rubric_verdicts = record.rubric_verdicts.filter((entry) => entry.dimension !== "journey"); }, /journey has no verdict/);
      rejects((record) => { record.rubric_verdicts.push({ ...record.rubric_verdicts[0] }); }, /duplicate rubric verdict/);
      rejects((record) => { record.rubric_verdicts[0].finding_ids = ["DR-254-01"]; }, /carries dimension hierarchy, not typography/);
      rejects((record) => { record.rubric_verdicts[3].capture_ids = []; }, /needs capture_ids/);
      rejects((record) => { record.rubric_verdicts[3].source_refs = []; }, /needs source_refs/);
      rejects((record) => { record.rubric_verdicts[1].verdict = "maybe"; }, /finding or assessed-no-finding/);
      rejects((record) => { record.rubric_verdicts[1] = { dimension: "color", verdict: "finding", finding_ids: ["DR-254-77"] }; }, /unknown finding/);
    }
  ],
  [
    "an assessed-no-finding verdict is contradicted by a finding that carries its dimension",
    () => {
      rejects((record) => { record.findings[0].also_dimensions = ["color"]; }, /contradicts finding DR-254-01/);
    }
  ],
  [
    "capture cells: state and sourcing must follow D-33, keys must follow the four patterns, and there must be 16",
    () => {
      rejects((record) => { record.captures[8].sourcing = "story"; }, /review-open|requires mounted/);
      rejects((record) => { record.captures[12].sourcing = "story"; }, /requires mounted|cannot be sourced from a story/);
      rejects((record) => { record.captures[0].key = "phase254-collection-populated-w320-light"; }, /four D-33 key patterns/);
      rejects((record) => { record.captures.pop(); }, /exactly 16/);
      rejects((record) => { record.captures.push({ ...record.captures[0], id: "CAP-254-17", key: "phase254-page-active-w320-light" }); }, /exactly 16/);
      rejects((record) => { record.captures[1].key = record.captures[0].key; }, /requires|duplicate capture key/);
      rejects((record) => { record.captures[9].state = "settled"; }, /requires mounted sourcing and state review-open|requires/);
      assert.equal(captureCells().length, 16);
      assert.equal(captureCells().filter((cell) => cell.sourcing === "mounted").length, 8);
    }
  ],
  [
    "a contract-amended finding needs contract.path and contract.row, names an existing row to amend and a new row to add",
    () => {
      rejects((record) => { delete record.findings[1].contract.path; }, /needs contract\.path/);
      rejects((record) => { delete record.findings[1].contract.row; }, /needs contract\.path/);
      rejects((record) => { record.findings[1].contract.row = "Section title"; }, /row "Section title" to amend is absent/);
      rejects((record) => { record.findings[1].contract.action = "add-row"; }, /already exists/);
      rejects((record) => { record.findings[1].contract.action = "rewrite"; }, /amend-row or add-row/);
      rejects((record) => { record.findings[1].contract.path = path.posix.join(".planning", "phases", "253-fixture", "missing.md"); }, /could not be read/);
    }
  ],
  [
    "stage corrected: a fixed finding needs tests and red evidence, and amended_text must be found in the contract file",
    () => {
      const corrected = (mutate, pattern, overrides = {}) => {
        const harness = fixtureHarness({ files: { [ASSET_PATHS.app_css]: FIXED_APP_CSS }, contract: CORRECTED_CONTRACT, ...overrides });
        const record = clone(harness.record);
        toCorrected(record);
        mutate(record);
        if (pattern) assert.throws(() => verifyDesignReview(record, { ...harness.options, stage: "corrected" }), pattern);
        else assert.doesNotThrow(() => verifyDesignReview(record, { ...harness.options, stage: "corrected" }));
      };
      corrected(() => {}, null);
      corrected((record) => { record.findings[0].tests = []; }, /must list its tests/);
      corrected((record) => { delete record.findings[0].red_evidence; }, /red-evidence reference/);
      corrected((record) => { record.findings[0].red_evidence = ["missing.json"]; }, /does not exist/);
      corrected((record) => { record.findings[0].tests[0].status = "pending"; }, /pending test/);
      corrected((record) => { record.fix_commit = null; }, /fix_commit/);
      corrected(() => {}, /amended_text/, { contract: FIXTURE_CONTRACT });
      corrected(() => {}, /still finds 1 page-tier gap override/, { files: {} });
    }
  ],
  [
    "the spacing finding has a mechanical basis at assessment: a fixture without an override is rejected",
    () => {
      const clean = ".a{color:red}\n.ax-subscription-detail-page{gap:var(--ax-space-xs)}\n.b{margin:0}\n";
      rejects(() => {}, /no mechanical basis/, { files: { [ASSET_PATHS.app_css]: clean } });
    }
  ],
  [
    "amendments need decisions, evidence and an owner acknowledgement; deferred findings need a tier and a trigger",
    () => {
      rejects((record) => { delete record.amendments[0].owner_ack; }, /owner_ack/);
      rejects((record) => { record.amendments[0].evidence = []; }, /evidence is required/);
      rejects((record) => { record.amendments[0].id = "AMD-3"; }, /AMD-254-NN/);
      rejects((record) => { record.deferred = []; }, /needs a deferred\[\] entry/);
      rejects((record) => { record.deferred[0].trigger = ""; }, /needs a trigger/);
      rejects((record) => { record.deferred[0].tier = "elsewhere"; }, /tier/);
      rejects((record) => { record.deferred[0].finding_id = "DR-254-88"; }, /unknown finding/);
    }
  ]
];

export const scenarioNames = () => SCENARIOS.map(([name]) => name);
export function verifyFixtures() {
  for (const [, scenario] of SCENARIOS) scenario();
  return SCENARIOS.length;
}

// ---------------------------------------------------------------------------------------------
// View check and CLI.
// ---------------------------------------------------------------------------------------------

export function assertViewMatches(record, viewText) {
  const expected = renderDesignReview(record);
  if (viewText !== expected) {
    throw fail(`${VIEW_ARTIFACT} is stale or not the renderer output; run: node scripts/ci/verify_phase254_design_review.mjs --render`);
  }
}

function recordPaths(root) {
  const recordPath = resolvePhaseEvidencePath(PHASE_SLUG, RECORD_ARTIFACT, { root });
  return { recordPath, viewPath: path.join(path.dirname(recordPath), VIEW_ARTIFACT) };
}

function parseArgs(argv) {
  const flags = new Set();
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) throw fail(`unexpected argument: ${token}`);
    const key = token.slice(2);
    if (["render", "check", "self-test"].includes(key)) flags.add(key);
    else if (key === "stage") {
      if (index + 1 >= argv.length || argv[index + 1].startsWith("--")) throw fail("--stage requires a value");
      values.stage = argv[++index];
      if (!STAGES.includes(values.stage)) throw fail(`--stage must be one of ${STAGES.join(", ")}`);
    } else throw fail(`unknown option: --${key}`);
  }
  return { flags, values };
}

function main(argv = process.argv.slice(2), root = repositoryRoot) {
  const { flags, values } = parseArgs(argv);
  if (flags.size !== 1) throw fail("exactly one of --render, --check, --self-test is required");
  if (flags.has("self-test")) {
    for (const [name, scenario] of SCENARIOS) {
      scenario();
      console.log(`ok - ${name}`);
    }
    console.log(`Phase 254 design review self-test: PASS (${SCENARIOS.length} scenarios, each with a passing control)`);
    return;
  }
  const { recordPath, viewPath } = recordPaths(root);
  const record = JSON.parse(fs.readFileSync(recordPath, "utf8"));
  if (flags.has("render")) {
    fs.writeFileSync(viewPath, renderDesignReview(record));
    console.log(`Phase 254 design review: rendered ${path.relative(root, viewPath).split(path.sep).join("/")}`);
    return;
  }
  const summary = verifyDesignReview(record, { root, stage: values.stage });
  assertViewMatches(record, fs.readFileSync(viewPath, "utf8"));
  console.log(
    `Phase 254 design review: PASS (stage ${summary.stage}; ${summary.findings} findings, ${summary.captures} captures, ${summary.verdicts} rubric verdicts, ${summary.deferred} deferrals; source shas match; Markdown view is current)`
  );
}

let invokedAsEntrypoint = false;
try {
  invokedAsEntrypoint = isMainModule(import.meta.url);
} catch {
  invokedAsEntrypoint = false;
}
// A spawn with arguments is a real CLI run even when NODE_TEST_CONTEXT is inherited.
if (invokedAsEntrypoint && process.env.NODE_TEST_CONTEXT && process.argv.length <= 2) {
  for (const [name, scenario] of SCENARIOS) test(name, scenario);
} else if (invokedAsEntrypoint) {
  try {
    main();
  } catch (error) {
    console.error(error.message.startsWith("Phase 254") ? error.message : `Phase 254 design review: FAIL: ${error.message}`);
    process.exitCode = 1;
  }
}
