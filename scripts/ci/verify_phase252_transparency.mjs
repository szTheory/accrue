#!/usr/bin/env node

import fs from "node:fs";
import crypto from "node:crypto";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const LAB_TEST = "scripts/ci/verify_phase252_lab_presentation.test.mjs";
const LAB_CLEAN = "scripts/ci/fixtures/phase252-transparency/lab-clean.json";
const LAB_VIOLATION = "scripts/ci/fixtures/phase252-transparency/lab-violation.json";
const LAB_ASSERTION = "lab presentation states disposable static limits";
const HELDOUT_TEST = "scripts/ci/verify_phase252_heldout_attribution.test.mjs";
const HELDOUT_CLEAN = "scripts/ci/fixtures/phase252-transparency/heldout-clean.json";
const HELDOUT_VIOLATION = "scripts/ci/fixtures/phase252-transparency/heldout-violation.json";
const HELDOUT_ASSERTION = "held-out attribution identifies synthetic stress evidence";
const PHASE253_TEST = "scripts/ci/verify_phase253_presentation.test.mjs";
const PHASE253_CLEAN = "scripts/ci/fixtures/phase253-transparency/clean.json";
const PHASE253_PRESENTATION_VIOLATION = "scripts/ci/fixtures/phase253-transparency/presentation-violation.json";
const PHASE253_ATTRIBUTION_VIOLATION = "scripts/ci/fixtures/phase253-transparency/attribution-violation.json";
const PHASE253_ASSERTION = "truthful Phase253 composition attribution remains presentation-only";
const PHASE253_MANIFEST = "accrue_admin/tmp/phase253/manifest.json";
const PHASE253_GUIDE = "guides/ui-story-lab.md";
const PHASE253_COLLECTION_STORY = "storybook/groups/subscriptions_collection.story.exs";
const PHASE253_PAGE_STORY = "storybook/pages/subscription.story.exs";
const PHASE253_BROWSER_HELPERS = "accrue_admin/e2e/phase253-composition-helpers.js";
const PHASE253_BROWSER_SPEC = "accrue_admin/e2e/subscription-compositions-phase253.spec.js";
const PHASE253_COMPILED_SOURCES = Object.freeze([
  "accrue_admin/lib/accrue_admin/dev/storybook.ex",
  "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
  "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
  "accrue_admin/lib/accrue_admin/queries/subscriptions.ex",
  "accrue_admin/lib/accrue_admin/router.ex",
  "accrue_admin/storybook/_support/subscription_collection.ex",
  "accrue_admin/storybook/_support/subscription_compositions_manifest.ex",
  "accrue_admin/storybook/_support/subscription_page_scenarios.ex",
  "dev_support/ui_scenarios/cadence_subscriptions.exs",
  PHASE253_COLLECTION_STORY,
  PHASE253_PAGE_STORY,
]);
const PHASE253_COLLECTION_IDS = Object.freeze([
  "filtered_empty", "incomplete_projection", "loading", "multiple_rows", "new_host_empty",
  "one_row", "page_boundary", "partial_cursor_error", "queue_empty", "unavailable",
]);
const PHASE253_PAGE_IDS = Object.freeze([
  "active", "awaiting_step_up", "dispatching", "incomplete_evidence", "result_confirmed",
  "result_failed", "result_pending", "review_cancel_now", "scheduled_cancellation",
]);

function fail(message) {
  throw new Error(`Phase252 transparency: ${message}`);
}

function requireText(value, label) {
  if (typeof value !== "string" || value.trim() === "") fail(`${label} is missing or empty`);
  return value.trim();
}

export function parseSubjectJson(source, label = "subject") {
  try {
    return JSON.parse(source);
  } catch {
    fail(`${label} is malformed JSON`);
  }
}

function phase253Source(root, relative) {
  const filename = path.resolve(root, relative);
  let stat;
  try {
    stat = fs.statSync(filename);
  } catch {
    fail(`Phase253 subject collection: required source is missing (${relative})`);
  }
  if (!stat.isFile()) fail(`Phase253 subject collection: required source is not a file (${relative})`);
  const contents = fs.readFileSync(filename);
  if (contents.toString("utf8").trim() === "") fail(`Phase253 subject collection: required source is empty (${relative})`);
  return contents;
}

function phase253Text(root, relative) {
  return phase253Source(root, relative).toString("utf8");
}

function sha256(source) {
  return crypto.createHash("sha256").update(source).digest("hex");
}

function phase253Moduledoc(source, label) {
  const matches = [...source.matchAll(/@moduledoc\s+"""([\s\S]*?)"""/g)];
  if (matches.length !== 1) fail(`Phase253 subject collection: ${label} moduledoc is missing or duplicated`);
  return requireText(matches[0][1].replace(/\s+/g, " "), `${label} moduledoc`);
}

function phase253ManifestRows(rows, label) {
  if (!Array.isArray(rows) || rows.length === 0) fail(`Phase253 subject collection: ${label} are missing or empty`);
  const seen = new Set();
  return rows.map((row) => {
    if (!row || typeof row !== "object" || Array.isArray(row)) fail(`Phase253 subject collection: malformed ${label} row`);
    const variationId = requireText(row.variation_id || row.key, `${label} variation identity`);
    if (seen.has(variationId)) fail(`Phase253 subject collection: duplicate ${label} identity (${variationId})`);
    seen.add(variationId);
    return {
      variation_id: variationId,
      fact_source: requireText(row.fact_source, `${label} fact source`),
      production_renderer: requireText(row.production_renderer, `${label} production renderer`),
      proof_lane: requireText(row.proof_lane, `${label} proof lane`),
      transport_kind: requireText(row.transport_kind, `${label} transport kind`),
    };
  });
}

function phase253CurrentManifest(root, manifest, manifestBytes) {
  const collection = phase253ManifestRows(manifest.collection_variations, "collection variations");
  const pages = phase253ManifestRows(manifest.page_entries, "page entries");
  if (JSON.stringify([...collection.map(({ variation_id }) => variation_id)].sort()) !== JSON.stringify([...PHASE253_COLLECTION_IDS].sort())) {
    fail("Phase253 subject collection: compiled collection inventory differs from the bounded ten-state contract");
  }
  if (JSON.stringify([...pages.map(({ variation_id }) => variation_id)].sort()) !== JSON.stringify([...PHASE253_PAGE_IDS].sort())) {
    fail("Phase253 subject collection: compiled page inventory differs from the bounded nine-state contract");
  }

  const sourceDigests = manifest.source_digests;
  if (!sourceDigests || typeof sourceDigests !== "object" || Array.isArray(sourceDigests)) {
    fail("Phase253 subject collection: compiled manifest source digests are missing");
  }
  if (JSON.stringify(Object.keys(sourceDigests).sort()) !== JSON.stringify([...PHASE253_COMPILED_SOURCES].sort())) {
    fail("Phase253 subject collection: compiled source inventory differs from the bounded source contract");
  }

  const files = {};
  for (const relative of [...PHASE253_COMPILED_SOURCES, PHASE253_GUIDE, PHASE253_BROWSER_HELPERS, PHASE253_BROWSER_SPEC]) {
    const contents = phase253Source(root, relative);
    const currentDigest = sha256(contents);
    if (Object.hasOwn(sourceDigests, relative) && sourceDigests[relative] !== currentDigest) {
      fail(`Phase253 subject collection: compiled source digest is stale (${relative})`);
    }
    files[relative] = currentDigest;
  }
  files[PHASE253_MANIFEST] = sha256(manifestBytes);
  return { collection, pages, files };
}

/** Collect only enumerated story, guide, manifest, and browser-label surfaces. */
export function collectPhase253Subject(root = ROOT) {
  const guide = phase253Text(root, PHASE253_GUIDE);
  const manifestBytes = phase253Source(root, PHASE253_MANIFEST);
  const manifest = parseSubjectJson(manifestBytes.toString("utf8"), "Phase253 compiled manifest");
  const inventory = phase253CurrentManifest(root, manifest, manifestBytes);
  const collectionSource = phase253Text(root, PHASE253_COLLECTION_STORY);
  const pageSource = phase253Text(root, PHASE253_PAGE_STORY);
  const browserHelpers = phase253Text(root, PHASE253_BROWSER_HELPERS);
  const collectionLabel = browserHelpers.match(/stress_label\s*:\s*["']([^"']+)["']/)?.[1];
  const pageLabel = browserHelpers.match(/stress_label\s*:\s*kind\s*===\s*["']synthetic["']\s*\?\s*`([^`]+)`/)?.[1];
  const syntheticLabels = [collectionLabel, pageLabel].map((label) => requireText(label, "Phase253 browser synthetic label"));
  const entries = phase253ManifestRows(manifest.entries, "compiled manifest entries");
  return {
    schema_version: 1,
    guide: { source: PHASE253_GUIDE, text: guide },
    collection_story: { source: PHASE253_COLLECTION_STORY, moduledoc: phase253Moduledoc(collectionSource, "collection story") },
    page_story: { source: PHASE253_PAGE_STORY, moduledoc: phase253Moduledoc(pageSource, "page story") },
    manifest: {
      source: PHASE253_MANIFEST,
      entries,
      collection_variations: inventory.collection,
      page_entries: inventory.pages,
    },
    browser_evidence: {
      source: PHASE253_BROWSER_HELPERS,
      proof_lane: "actual direct browser presentation; no mounted-effect claims",
      synthetic_labels: syntheticLabels,
    },
    source_identity: {
      manifest_sha256: sha256(manifestBytes),
      files: inventory.files,
    },
  };
}

/** Read an injected subject when present; otherwise collect current bounded sources. */
export function loadPhase253Subject(env = process.env, root = ROOT, cwd = process.cwd()) {
  if (!Object.prototype.hasOwnProperty.call(env, "GSD_PROHIB_SUBJECT")) return collectPhase253Subject(root);
  const supplied = requireText(env.GSD_PROHIB_SUBJECT, "GSD_PROHIB_SUBJECT");
  let source;
  try {
    source = fs.readFileSync(path.resolve(cwd, supplied), "utf8");
  } catch {
    fail("injected subject file is missing or unreadable");
  }
  return parseSubjectJson(source, "injected subject");
}

const PHASE253_EFFECT_CLAIMS = Object.freeze([
  {
    id: "mounted-authority",
    pattern: /\b(?:the\s+)?(?:settled\s+)?(?:subscription\s+story|storybook|lab\s+rendering|rendered\s+controls|story\s+rendering)\s+(?:proves?|shows?|confirms?|demonstrates?|establish(?:es)?)\b[^.!?\n]{0,180}\bmounted\s+(?:authority|authorization)\b/i,
  },
  {
    id: "persistence",
    pattern: /\b(?:the\s+)?(?:settled\s+)?(?:subscription\s+story|storybook|lab\s+rendering|rendered\s+controls|story\s+rendering)\s+(?:proves?|shows?|confirms?|demonstrates?|establish(?:es)?)\b[^.!?\n]{0,180}\b(?:persistence|persisted\s+billing\s+state)\b/i,
  },
  {
    id: "action-dispatch",
    pattern: /\b(?:the\s+)?(?:settled\s+)?(?:subscription\s+story|storybook|lab\s+rendering|rendered\s+controls|story\s+rendering)\s+(?:proves?|shows?|confirms?|demonstrates?|establish(?:es)?)\b[^.!?\n]{0,180}\b(?:action\s+dispatch|dispatched\s+action\s+behavior|action\s+success)\b/i,
  },
  {
    id: "provider-completion",
    pattern: /\b(?:the\s+)?(?:settled\s+)?(?:subscription\s+story|storybook|lab\s+rendering|rendered\s+controls|story\s+rendering)\s+(?:proves?|shows?|confirms?|demonstrates?|establish(?:es)?)\b[^.!?\n]{0,180}\bprovider\s+completion\b/i,
  },
]);

const PHASE253_SYNTHETIC_CLAIMS = Object.freeze([
  {
    id: "representative-customer-behavior",
    pattern: /\bsynthetic\b[^.!?\n]{0,100}\b(?:collection|held-out|stress|facts|scenario|input)\b[^.!?\n]{0,50}\b(?:represents?|reflects?|models?)\b[^.!?\n]{0,50}\b(?:typical|representative)\s+(?:customer|adopter)\s+(?:behavior|usage)\b/i,
  },
  {
    id: "real-adopter-usage",
    pattern: /\bsynthetic\b[^.!?\n]{0,100}\b(?:collection|held-out|stress|facts|scenario|input)\b[^.!?\n]{0,50}\b(?:is|are)\b[^.!?\n]{0,40}\b(?:real|actual)\s+(?:customer|adopter)\s+(?:behavior|usage|evidence)\b/i,
  },
]);

function phase253SubjectText(subject, guide, collectionStory, pageStory, entries, collections, pages, labels) {
  return [
    guide,
    collectionStory,
    pageStory,
    ...entries.map((row) => Object.values(row).join("\n")),
    ...collections.map((row) => Object.values(row).join("\n")),
    ...pages.map((row) => Object.values(row).join("\n")),
    subject.browser_evidence.proof_lane,
    ...labels,
  ].join("\n");
}

export function assertPhase253Presentation(subject) {
  if (!subject || typeof subject !== "object" || Array.isArray(subject)) fail("Phase253 assertion: subject must be an object");
  if (subject.schema_version !== 1) fail("Phase253 assertion: unrecognized subject schema");
  const guide = requireText(subject.guide?.text, "Phase253 assertion: guide prose");
  const guideSource = requireText(subject.guide?.source, "Phase253 assertion: guide source");
  const collectionStory = requireText(subject.collection_story?.moduledoc, "Phase253 assertion: collection story moduledoc");
  const collectionSource = requireText(subject.collection_story?.source, "Phase253 assertion: collection story source");
  const pageStory = requireText(subject.page_story?.moduledoc, "Phase253 assertion: page story moduledoc");
  const pageSource = requireText(subject.page_story?.source, "Phase253 assertion: page story source");
  const manifestSource = requireText(subject.manifest?.source, "Phase253 assertion: manifest source");
  const entries = phase253ManifestRows(subject.manifest?.entries, "manifest entries");
  const collections = phase253ManifestRows(subject.manifest?.collection_variations, "collection variations");
  const pages = phase253ManifestRows(subject.manifest?.page_entries, "page entries");
  const browserSource = requireText(subject.browser_evidence?.source, "Phase253 assertion: browser evidence source");
  const browserLane = requireText(subject.browser_evidence?.proof_lane, "Phase253 assertion: browser proof lane");
  const labels = subject.browser_evidence?.synthetic_labels;
  if (!Array.isArray(labels) || labels.length < 2) fail("Phase253 assertion: synthetic browser stress labels are missing or empty");
  const syntheticLabels = labels.map((label) => requireText(label, "Phase253 assertion: synthetic browser stress label"));
  const manifestDigest = requireText(subject.source_identity?.manifest_sha256, "Phase253 assertion: manifest digest");
  if (!/^[a-f0-9]{64}$/.test(manifestDigest)) fail("Phase253 assertion: manifest digest is malformed");
  const sourceFiles = subject.source_identity?.files;
  if (!sourceFiles || typeof sourceFiles !== "object" || Array.isArray(sourceFiles) || Object.keys(sourceFiles).length === 0) {
    fail("Phase253 assertion: source identities are missing or empty");
  }
  for (const [relative, digest] of Object.entries(sourceFiles)) {
    requireText(relative, "Phase253 assertion: source identity path");
    if (typeof digest !== "string" || !/^[a-f0-9]{64}$/.test(digest)) fail(`Phase253 assertion: malformed source identity digest (${relative})`);
  }

  if (guideSource !== PHASE253_GUIDE || collectionSource !== PHASE253_COLLECTION_STORY || pageSource !== PHASE253_PAGE_STORY ||
      manifestSource !== PHASE253_MANIFEST || browserSource !== PHASE253_BROWSER_HELPERS) {
    fail("Phase253 assertion: enumerated source identity differs from the bounded Phase253 contract");
  }
  if (!/synthetic stress scenarios, not representative customer behavior or real adopter usage evidence/i.test(guide) ||
      !/disposable, non-production review lab/i.test(guide) ||
      !/static review surface/i.test(guide) ||
      !/rendered controls do not establish completed billing actions, mounted authorization, provider completion, or persistence/i.test(guide) ||
      !/static rendering verifies story state and visual\/semantic output\. it does not prove mounted authorization, provider completion, dispatched action behavior, or persistence\./i.test(guide)) {
    fail("Phase253 assertion: guide omits static-presentation or synthetic-stress limits");
  }
  if (!/production subscription collection with a connected DataTable LiveComponent/i.test(collectionStory) ||
      !/deterministic development adapter over validated Cadence subscription facts/i.test(collectionStory) ||
      !/routed billing page continues to use the scoped Repo query/i.test(collectionStory)) {
    fail("Phase253 assertion: collection story omits its production-renderer and development-adapter attribution");
  }
  if (!/whole subscription detail page rendered by SubscriptionLive's production component/i.test(pageStory) ||
      !/variations carry deterministic story facts only/i.test(pageStory) ||
      !/do not establish mounted authorization, persistence, action dispatch, or provider completion/i.test(pageStory)) {
    fail("Phase253 assertion: whole-page story omits its presentation-only effect limits");
  }
  if (browserLane !== "actual direct browser presentation; no mounted-effect claims" ||
      syntheticLabels.some((label) => !/synthetic/i.test(label) || !/not customer evidence/i.test(label))) {
    fail("Phase253 assertion: browser evidence does not preserve presentation-only and synthetic-stress labels");
  }

  for (const [label, rows, renderer, transport] of [
    ["manifest entries", entries, null, null],
    ["collection variations", collections, "AccrueAdmin.Live.SubscriptionsLive.subscriptions_collection/1", "live_component"],
    ["page entries", pages, "AccrueAdmin.Live.SubscriptionLive.subscription_page/1", "page_story"],
  ]) {
    for (const row of rows) {
      if (!/^CadenceSubscriptionFacts\.fetch!\(:[a-z_]+\)$/.test(row.fact_source) || row.proof_lane !== "presentation-only" ||
          (renderer && row.production_renderer !== renderer) || (transport && row.transport_kind !== transport)) {
        fail(`Phase253 assertion: ${label} lost bounded production/source/presentation attribution`);
      }
    }
  }

  const surfaces = phase253SubjectText(subject, guide, collectionStory, pageStory, entries, collections, pages, syntheticLabels);
  for (const claim of PHASE253_EFFECT_CLAIMS) {
    if (claim.pattern.test(surfaces)) fail(`Phase253 assertion: contradictory public claim phase253-static-effects (${claim.id})`);
  }
  for (const claim of PHASE253_SYNTHETIC_CLAIMS) {
    if (claim.pattern.test(surfaces)) fail(`Phase253 assertion: contradictory public claim phase253-synthetic-attribution (${claim.id})`);
  }
  return true;
}

function readRequired(root, relative) {
  const filename = path.resolve(root, relative);
  let stat;
  try {
    stat = fs.statSync(filename);
  } catch {
    fail(`lab subject collection: required source is missing (${relative})`);
  }
  if (!stat.isFile()) fail(`lab subject collection: required source is not a file (${relative})`);
  const contents = fs.readFileSync(filename, "utf8");
  if (contents.trim() === "") fail(`lab subject collection: required source is empty (${relative})`);
  return contents;
}

function moduledocFrom(source) {
  const matches = [...source.matchAll(/@moduledoc\s+"""([\s\S]*?)"""/g)];
  if (matches.length !== 1) fail("lab subject collection: SubscriptionDetail moduledoc is missing or duplicated");
  return requireText(matches[0][1], "SubscriptionDetail moduledoc");
}

function manifestEntries(value) {
  if (!value || typeof value !== "object" || !Array.isArray(value.entries) || value.entries.length === 0) {
    fail("lab subject collection: manifest entries are missing or empty");
  }
  const seen = new Set();
  return value.entries.map((entry) => {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) fail("lab subject collection: malformed manifest entry");
    const key = requireText(entry.key, "manifest entry key");
    if (seen.has(key)) fail("lab subject collection: duplicate manifest entry key");
    seen.add(key);
    return {
      key,
      actor: requireText(entry.actor, "manifest actor attribution"),
      job: requireText(entry.job, "manifest job attribution"),
      input_source: requireText(entry.input_source, "manifest input-source attribution"),
      production_renderer: requireText(entry.production_renderer, "manifest production-renderer attribution"),
      proof_lane: requireText(entry.proof_lane, "manifest proof-lane attribution"),
    };
  });
}

function heldOutAttribution(root) {
  const relative = "dev_support/ui_scenarios/cadence_subscriptions.exs";
  const source = readRequired(root, relative);
  const matches = [...source.matchAll(/(@doc\s+"([^"]+)"\s*\n\s*def held_out!\s*\(:long_text\)\s+do([\s\S]*?)\n\s*end(?=\n\s*def held_out!\(case_name\)))/g)];
  if (matches.length !== 1) fail("held-out subject collection: held_out!(:long_text) attribution block is missing or duplicated");
  const functionBlock = requireText(matches[0][1], "held_out!(:long_text) source block");
  const lane = functionBlock.match(/Map\.put\(\s*:lane\s*,\s*:(\w+)\s*\)/)?.[1];
  const caseName = functionBlock.match(/Map\.put\(\s*:held_out_case\s*,\s*:(\w+)\s*\)/)?.[1];
  return {
    source: relative,
    documentation: requireText(matches[0][2], "held-out source documentation"),
    function_block: functionBlock,
    lane: requireText(lane, "held-out source lane"),
    case: requireText(caseName, "held-out source case"),
  };
}

function ordinaryAttribution(root) {
  const relative = "accrue_admin/storybook/_support/subscription_scenarios.ex";
  const source = readRequired(root, relative);
  const clauses = [...source.matchAll(/defp validate_scenario\(%\{lane: :ordinary, scenario: scenario\}\) do([\s\S]*?)\n  end/g)];
  const refusal = [...source.matchAll(/defp validate_scenario\(_facts\),\s*do:\s*\{:error,\s*"([^"]+)"\}/g)];
  if (clauses.length !== 1 || refusal.length !== 1) fail("held-out subject collection: ordinary-lane validation or refusal clause is missing or duplicated");
  const validationBlock = requireText(clauses[0][0], "ordinary-lane validation block");
  const lane = validationBlock.match(/lane:\s*:(\w+)/)?.[1];
  return {
    source: relative,
    validation_block: `${validationBlock}\n${refusal[0][0]}`,
    lane: requireText(lane, "ordinary adapter lane"),
    refusal: requireText(refusal[0][1], "ordinary adapter refusal"),
  };
}

function browserHeldOutEvidence(root) {
  const relative = "accrue_admin/e2e/phase252-story-helpers.js";
  const source = readRequired(root, relative);
  const matches = [...source.matchAll(/async function assertHeldOutLongText\(page,\s*ordinaryStory,\s*theme\)\s*\{([\s\S]*?)\n\}/g)];
  if (matches.length !== 1) fail("held-out subject collection: assertHeldOutLongText function is missing or duplicated");
  const functionBlock = requireText(matches[0][0], "assertHeldOutLongText source block");
  const labels = [...functionBlock.matchAll(/\blabel\s*:\s*["']([^"']+)["']/g)];
  if (labels.length !== 1) fail("held-out subject collection: browser evidence label is missing or duplicated");
  return {
    source: relative,
    function_name: "assertHeldOutLongText",
    function_block: functionBlock,
    label: requireText(labels[0][1], "browser held-out evidence label"),
  };
}

/**
 * Collect only the named public surfaces: guide prose, SubscriptionDetail's moduledoc,
 * and five public attribution fields from every generated manifest entry. This lexical
 * contract is finite and intentionally does not classify arbitrary language or inspect
 * unrelated code, comments, historical plans, or fixture prose.
 */
export function collectLabSubject(root = ROOT) {
  const guidePath = "guides/ui-story-lab.md";
  const storyPath = "storybook/components/subscription_detail.story.exs";
  const manifestPath = "storybook/phase252-manifest.json";
  const guide = readRequired(root, guidePath);
  const storySource = readRequired(root, storyPath);
  const manifest = parseSubjectJson(readRequired(root, manifestPath), "Phase 252 manifest");
  return {
    schema_version: 1,
    guide: { source: guidePath, text: guide },
    story: { source: storyPath, moduledoc: moduledocFrom(storySource) },
    manifest: { source: manifestPath, entries: manifestEntries(manifest) },
    held_out: heldOutAttribution(root),
    ordinary: ordinaryAttribution(root),
    browser_evidence: browserHeldOutEvidence(root),
  };
}

/** Read injected content only; the named test calls this from inside its test callback. */
export function loadLabSubject(env = process.env, root = ROOT, cwd = process.cwd()) {
  if (Object.prototype.hasOwnProperty.call(env, "GSD_PROHIB_SUBJECT")) {
    const supplied = requireText(env.GSD_PROHIB_SUBJECT, "GSD_PROHIB_SUBJECT");
    const filename = path.resolve(cwd, supplied);
    let source;
    try {
      source = fs.readFileSync(filename, "utf8");
    } catch {
      fail("injected subject file is missing or unreadable");
    }
    return parseSubjectJson(source, "injected subject");
  }
  return collectLabSubject(root);
}

const LAB_CLAIMS = Object.freeze([
  {
    id: "lab-production-console",
    pattern: /\b(?:the\s+)?(?:review\s+)?lab\s+(?:is|acts as|serves as|functions as)\s+(?:a\s+)?production\s+(?:billing\s+)?(?:operations?\s+)?console\b/i,
  },
  {
    id: "completed-billing-actions",
    pattern: /\b(?:the\s+)?(?:lab|storybook|subscription\s+story|story|preview|rendered\s+controls)\s+(?:proves?|shows?|confirms?|demonstrates?|establishes?)\b[^.!?\n]{0,80}\b(?:completed\s+billing\s+actions?|successful\s+billing\s+actions?|action\s+success)\b/i,
  },
  {
    id: "mounted-authorization",
    pattern: /\b(?:the\s+)?(?:lab|storybook|subscription\s+story|story|preview|rendered\s+controls)\s+(?:proves?|shows?|confirms?|demonstrates?|establishes?)\b[^.!?\n]{0,80}\bmounted\s+authorization\b/i,
  },
  {
    id: "provider-completion",
    pattern: /\b(?:the\s+)?(?:lab|storybook|subscription\s+story|story|preview|rendered\s+controls)\s+(?:proves?|shows?|confirms?|demonstrates?|establishes?)\b[^.!?\n]{0,80}\bprovider\s+completion\b/i,
  },
  {
    id: "persistence",
    pattern: /\b(?:the\s+)?(?:lab|storybook|subscription\s+story|story|preview|rendered\s+controls)\s+(?:proves?|shows?|confirms?|demonstrates?|establishes?)\b[^.!?\n]{0,80}\b(?:persistence|persisted\s+billing\s+state)\b/i,
  },
]);

const HELDOUT_CLAIMS = Object.freeze([
  {
    id: "representative-customer-behavior",
    pattern: /\bheld-out\s+(?:stress\s+)?(?:input|facts|scenario|scenarios)\s+(?:represents?|reflects?|models?)\s+(?:typical|representative)\s+(?:customer|adopter)\s+(?:behavior|usage)\b/i,
  },
  {
    id: "real-adopter-usage",
    pattern: /\bheld-out\s+(?:stress\s+)?(?:input|facts|scenario|scenarios)\s+(?:is|are)\s+(?:real|actual)\s+adopter\s+(?:usage|behavior|evidence)\b/i,
  },
]);

function validateLabSubject(subject) {
  if (!subject || typeof subject !== "object" || Array.isArray(subject)) fail("lab assertion: subject must be an object");
  if (subject.schema_version !== 1) fail("lab assertion: unrecognized subject schema");
  const guide = requireText(subject.guide?.text, "lab assertion: guide prose");
  requireText(subject.guide?.source, "lab assertion: guide source");
  const story = requireText(subject.story?.moduledoc, "lab assertion: story moduledoc");
  requireText(subject.story?.source, "lab assertion: story source");
  const entries = subject.manifest?.entries;
  requireText(subject.manifest?.source, "lab assertion: manifest source");
  if (!Array.isArray(entries) || entries.length === 0) fail("lab assertion: manifest attribution entries are missing or empty");
  const seen = new Set();
  for (const entry of entries) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) fail("lab assertion: malformed manifest attribution entry");
    const key = requireText(entry.key, "lab assertion: manifest entry key");
    if (seen.has(key)) fail("lab assertion: duplicate manifest entry key");
    seen.add(key);
    for (const field of ["actor", "job", "input_source", "production_renderer", "proof_lane"]) {
      requireText(entry[field], `lab assertion: manifest ${field}`);
    }
    if (entry.proof_lane !== "static render") fail("lab assertion: manifest proof lane is not static render");
    if (!/deterministic/i.test(entry.input_source)) fail("lab assertion: manifest input source is not attributed as deterministic");
  }
  return { guide, story, entries };
}

export function assertLabPresentation(subject) {
  const { guide, story, entries } = validateLabSubject(subject);
  if (!/\bdisposable.{0,4}non-production review lab\b/i.test(guide)) {
    fail("lab assertion: missing explicit non-production review-lab attribution");
  }
  if (!/\bstatic rendering\b/i.test(guide) || !/rendered controls do not establish completed billing actions/i.test(guide)) {
    fail("lab assertion: guide does not state static presentation and action limits");
  }
  if (!/\bordinary[\s\S]*\bheld-out[\s\S]*\bsynthetic[\s\S]*\bnot representative customer behavior[\s\S]*\breal adopter usage evidence\b/i.test(guide)) {
    fail("lab assertion: guide does not distinguish synthetic ordinary and held-out evidence");
  }
  if (!/Static rendering verifies story state and visual\/semantic output\.\s+It does not prove mounted authorization, provider completion, dispatched action behavior, or persistence\./i.test(guide)) {
    fail("lab assertion: existing static-render evidence boundary is missing");
  }
  if (!/Every variation is a static render of deterministic scenario facts\.[\s\S]*does not\s+establish mounted authorization, provider completion, persistence, or action success\./i.test(story)) {
    fail("lab assertion: story moduledoc omits static-render evidence limits");
  }

  const surfaces = [
    { name: "guide", text: guide },
    { name: "SubscriptionDetail moduledoc", text: story },
    ...entries.map((entry) => ({ name: "manifest attribution", text: [entry.actor, entry.job, entry.input_source, entry.production_renderer, entry.proof_lane].join("\n") })),
  ];
  for (const surface of surfaces) {
    const claim = LAB_CLAIMS.find(({ pattern }) => pattern.test(surface.text));
    if (claim) fail(`lab assertion: contradictory public claim ${claim.id} in ${surface.name}`);
  }
  return true;
}

/** Check only the guide's held-out claims and the three extracted source-attribution contracts. */
export function assertHeldoutAttribution(subject) {
  assertLabPresentation(subject);
  const heldOut = subject.held_out;
  const ordinary = subject.ordinary;
  const browser = subject.browser_evidence;
  const heldOutSource = requireText(heldOut?.source, "held-out assertion: source path");
  const heldOutDoc = requireText(heldOut?.documentation, "held-out assertion: source documentation");
  const heldOutBlock = requireText(heldOut?.function_block, "held-out assertion: source lane block");
  const heldOutLane = requireText(heldOut?.lane, "held-out assertion: source lane");
  const heldOutCase = requireText(heldOut?.case, "held-out assertion: source case");
  const ordinarySource = requireText(ordinary?.source, "held-out assertion: ordinary source path");
  const ordinaryBlock = requireText(ordinary?.validation_block, "held-out assertion: ordinary validation block");
  const ordinaryLane = requireText(ordinary?.lane, "held-out assertion: ordinary lane");
  const ordinaryRefusal = requireText(ordinary?.refusal, "held-out assertion: ordinary refusal");
  const browserSource = requireText(browser?.source, "held-out assertion: browser source path");
  const browserFunction = requireText(browser?.function_name, "held-out assertion: browser function name");
  const browserLabel = requireText(browser?.label, "held-out assertion: browser evidence label");
  requireText(browser?.function_block, "held-out assertion: browser source block");

  if (heldOutSource !== "dev_support/ui_scenarios/cadence_subscriptions.exs" ||
      !/separately labelled held-out text stress input, never an ordinary variation/i.test(heldOutDoc) ||
      heldOutLane !== "held_out" || heldOutCase !== "long_text" ||
      !/Map\.put\(\s*:lane\s*,\s*:held_out\s*\)/.test(heldOutBlock) ||
      !/Map\.put\(\s*:held_out_case\s*,\s*:long_text\s*\)/.test(heldOutBlock)) {
    fail("held-out assertion: source facts are not separately attributed to the held_out long-text lane");
  }
  if (ordinarySource !== "accrue_admin/storybook/_support/subscription_scenarios.ex" ||
      ordinaryLane !== "ordinary" || ordinaryRefusal !== "scenario must declare the ordinary review lane" ||
      !/lane: :ordinary, scenario: scenario/.test(ordinaryBlock) ||
      !/scenario must be a declared ordinary Cadence fact/.test(ordinaryBlock)) {
    fail("held-out assertion: ordinary adapter no longer accepts only its ordinary lane");
  }
  if (browserSource !== "accrue_admin/e2e/phase252-story-helpers.js" ||
      browserFunction !== "assertHeldOutLongText" || browserLabel !== "held-out long text (not manifest fixture)") {
    fail("held-out assertion: browser stress clone is not labelled separately from manifest fixtures");
  }
  if (!/long-text browser clone is a separate synthetic stress input,[\s\S]{0,100}distinct from the manifest fixture entries[\s\S]{0,120}CadenceSubscriptionFacts\.held_out!\/1`?\s+source/i.test(subject.guide.text)) {
    fail("held-out assertion: guide conflates the browser clone with source held-out facts or manifest fixtures");
  }

  for (const { id, pattern } of HELDOUT_CLAIMS) {
    if (pattern.test(subject.guide.text)) fail(`held-out assertion: contradictory public claim ${id}`);
  }
  return true;
}

function tapSummary(output) {
  const count = (name) => {
    const match = output.match(new RegExp(`^# ${name} (\\d+)$`, "m"));
    return match ? Number(match[1]) : null;
  };
  const plan = output.match(/^1\.\.(\d+)$/m);
  const records = [...output.matchAll(/^(ok|not ok) (\d+) - (.+)$/gm)].map((match) => ({
    status: match[1], number: Number(match[2]), name: match[3],
  }));
  return { planned: plan ? Number(plan[1]) : null, records, tests: count("tests"), pass: count("pass"), fail: count("fail"), cancelled: count("cancelled"), skipped: count("skipped"), todo: count("todo") };
}

function runTestTargets(testFiles, subjectPath = null) {
  const env = { ...process.env };
  delete env.NODE_TEST_CONTEXT;
  delete env.NODE_OPTIONS;
  delete env.GSD_PROHIB_SUBJECT;
  if (subjectPath) env.GSD_PROHIB_SUBJECT = path.resolve(ROOT, subjectPath);
  const result = spawnSync(process.execPath, ["--test", "--test-reporter=tap", ...testFiles], {
    cwd: ROOT,
    env,
    encoding: "utf8",
    timeout: 10_000,
    maxBuffer: 4 * 1024 * 1024,
    windowsHide: true,
  });
  if (result.error || result.signal || result.status === null) fail("lab self-test child failed or exceeded its 10-second bound");
  return { status: result.status, output: result.stdout || "" };
}

function runLabTarget(subjectPath = null) {
  return runTestTargets([LAB_TEST], subjectPath);
}

function requireLabControl(label, subjectPath, expectedStatus, expectedExit, expectedDiagnostic = null) {
  const result = runLabTarget(subjectPath);
  const tap = tapSummary(result.output);
  if (tap.planned === null || tap.planned <= 0 || tap.records.length !== tap.planned || tap.tests !== tap.planned) {
    fail(`lab self-test ${label} has a missing or vacuous named TAP report`);
  }
  if (tap.cancelled !== 0 || tap.skipped !== 0 || tap.todo !== 0) fail(`lab self-test ${label} has skipped, TODO, or cancelled tests`);
  const target = tap.records.filter((record) => record.name === LAB_ASSERTION);
  if (target.length !== 1 || target[0].status !== expectedStatus || result.status !== expectedExit) {
    fail(`lab self-test ${label} did not produce the required named ${expectedStatus === "ok" ? "GREEN" : "RED"}`);
  }
  if (expectedExit === 0 && (tap.pass !== tap.tests || tap.fail !== 0)) fail(`lab self-test ${label} is not a clean non-vacuous pass`);
  if (expectedExit !== 0 && (tap.fail < 1 || !result.output.includes(expectedDiagnostic))) {
    fail(`lab self-test ${label} RED lacks the intended content diagnostic`);
  }
  return { label, tests: tap.tests, pass: tap.pass, fail: tap.fail };
}

export function selfTestLab() {
  const controls = [
    requireLabControl("current", null, "ok", 0),
    requireLabControl("clean", LAB_CLEAN, "ok", 0),
    requireLabControl("violation", LAB_VIOLATION, "not ok", 1, "Phase252 transparency: lab assertion: contradictory public claim lab-production-console"),
  ];
  process.stdout.write(`PASS Phase 252 lab transparency: controls=${controls.map(({ label }) => label).join(",")} target_tests=${controls.map(({ tests }) => tests).join(",")} assertion=${LAB_ASSERTION}\n`);
  for (const marker of ["lab_static_current_green", "lab_static_clean_green", "lab_static_violation_red"]) {
    process.stdout.write(`PHASE252_ASSERTION=${marker}\n`);
  }
  return controls;
}

function requireHeldoutControl(label, testFiles, subjectPath, expectedFailure = null) {
  const result = runTestTargets(testFiles, subjectPath);
  const tap = tapSummary(result.output);
  if (tap.planned === null || tap.planned <= 0 || tap.records.length !== tap.planned || tap.tests !== tap.planned) {
    fail(`held-out self-test ${label} has a missing or vacuous named TAP report`);
  }
  if (tap.cancelled !== 0 || tap.skipped !== 0 || tap.todo !== 0) fail(`held-out self-test ${label} has skipped, TODO, or cancelled tests`);
  const expectedNames = testFiles.includes(LAB_TEST) ? [LAB_ASSERTION, HELDOUT_ASSERTION] : [HELDOUT_ASSERTION];
  for (const name of expectedNames) {
    const matches = tap.records.filter((record) => record.name === name);
    const status = name === expectedFailure ? "not ok" : "ok";
    if (matches.length !== 1 || matches[0].status !== status) {
      fail(`held-out self-test ${label} did not produce the required named ${status === "ok" ? "GREEN" : "RED"}`);
    }
  }
  const failures = tap.records.filter((record) => record.status === "not ok").map((record) => record.name);
  if (expectedFailure === null) {
    if (result.status !== 0 || failures.length !== 0 || tap.pass !== tap.tests || tap.fail !== 0) {
      fail(`held-out self-test ${label} is not a clean non-vacuous pass`);
    }
  } else if (result.status !== 1 || failures.length !== 1 || failures[0] !== expectedFailure || tap.fail !== 1 ||
      !result.output.includes("Phase252 transparency: held-out assertion: contradictory public claim representative-customer-behavior")) {
    fail(`held-out self-test ${label} RED lacks the intended content diagnostic`);
  }
  return { label, tests: tap.tests, pass: tap.pass, fail: tap.fail };
}

export function selfTestHeldout(includeLabTarget = false) {
  const testFiles = includeLabTarget ? [LAB_TEST, HELDOUT_TEST] : [HELDOUT_TEST];
  const controls = [
    requireHeldoutControl("current", testFiles, null),
    requireHeldoutControl("clean", testFiles, HELDOUT_CLEAN),
    requireHeldoutControl("violation", testFiles, HELDOUT_VIOLATION, HELDOUT_ASSERTION),
  ];
  const targetNames = testFiles.includes(LAB_TEST) ? `${LAB_ASSERTION};${HELDOUT_ASSERTION}` : HELDOUT_ASSERTION;
  process.stdout.write(`PASS Phase 252 held-out transparency: controls=${controls.map(({ label }) => label).join(",")} target_tests=${controls.map(({ tests }) => tests).join(",")} assertions=${targetNames}\n`);
  for (const marker of ["heldout_synthetic_current_green", "heldout_synthetic_clean_green", "heldout_synthetic_violation_red"]) {
    process.stdout.write(`PHASE252_ASSERTION=${marker}\n`);
  }
  return controls;
}

function requirePhase253Control(label, subjectPath, expectedStatus, expectedExit, expectedDiagnostic = null) {
  const result = runTestTargets([PHASE253_TEST], subjectPath);
  const tap = tapSummary(result.output);
  if (tap.planned === null || tap.planned <= 0 || tap.records.length !== tap.planned || tap.tests !== tap.planned) {
    fail(`Phase253 self-test ${label} has a missing or vacuous named TAP report`);
  }
  if (tap.cancelled !== 0 || tap.skipped !== 0 || tap.todo !== 0) fail(`Phase253 self-test ${label} has skipped, TODO, or cancelled tests`);
  const target = tap.records.filter((record) => record.name === PHASE253_ASSERTION);
  if (target.length !== 1 || target[0].status !== expectedStatus || result.status !== expectedExit) {
    fail(`Phase253 self-test ${label} did not produce the required named ${expectedStatus === "ok" ? "GREEN" : "RED"}`);
  }
  if (expectedExit === 0 && (tap.pass !== tap.tests || tap.fail !== 0)) fail(`Phase253 self-test ${label} is not a clean non-vacuous pass`);
  if (expectedExit !== 0 && (tap.fail !== 1 || !result.output.includes(expectedDiagnostic))) {
    fail(`Phase253 self-test ${label} RED lacks the intended content diagnostic`);
  }
  return { label, tests: tap.tests, pass: tap.pass, fail: tap.fail };
}

export function selfTestCompositions() {
  const controls = [
    requirePhase253Control("current", null, "ok", 0),
    requirePhase253Control("clean", PHASE253_CLEAN, "ok", 0),
    requirePhase253Control("presentation-violation", PHASE253_PRESENTATION_VIOLATION, "not ok", 1,
      "Phase252 transparency: Phase253 assertion: contradictory public claim phase253-static-effects"),
    requirePhase253Control("attribution-violation", PHASE253_ATTRIBUTION_VIOLATION, "not ok", 1,
      "Phase252 transparency: Phase253 assertion: contradictory public claim phase253-synthetic-attribution"),
  ];
  process.stdout.write(`PASS Phase 253 presentation transparency: controls=${controls.map(({ label }) => label).join(",")} target_tests=${controls.map(({ tests }) => tests).join(",")} assertion=${PHASE253_ASSERTION}\n`);
  for (const marker of ["phase253_current_green", "phase253_clean_green", "phase253_static_violation_red", "phase253_synthetic_violation_red"]) {
    process.stdout.write(`PHASE253_ASSERTION=${marker}\n`);
  }
  return controls;
}

function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--self-test")) fail("usage: node scripts/ci/verify_phase252_transparency.mjs --self-test --only lab");
  const onlyIndex = args.indexOf("--only");
  const only = onlyIndex === -1 ? "both" : args[onlyIndex + 1];
  if (only === "lab") selfTestLab();
  else if (only === "heldout") selfTestHeldout(false);
  else if (only === "compositions") selfTestCompositions();
  else if (only === "both") {
    selfTestHeldout(true);
    selfTestLab();
  }
  else fail("expected --only lab, --only heldout, --only compositions, or the default both-target mode");
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 2;
  }
}
