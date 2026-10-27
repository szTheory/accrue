#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const LAB_TEST = "scripts/ci/verify_phase252_lab_presentation.test.mjs";
const LAB_CLEAN = "scripts/ci/fixtures/phase252-transparency/lab-clean.json";
const LAB_VIOLATION = "scripts/ci/fixtures/phase252-transparency/lab-violation.json";
const LAB_ASSERTION = "lab presentation states disposable static limits";

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

function runLabTarget(subjectPath = null) {
  const env = { ...process.env };
  delete env.NODE_TEST_CONTEXT;
  delete env.NODE_OPTIONS;
  delete env.GSD_PROHIB_SUBJECT;
  if (subjectPath) env.GSD_PROHIB_SUBJECT = path.resolve(ROOT, subjectPath);
  const result = spawnSync(process.execPath, ["--test", "--test-reporter=tap", LAB_TEST], {
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
  return controls;
}

function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--self-test")) fail("usage: node scripts/ci/verify_phase252_transparency.mjs --self-test --only lab");
  const onlyIndex = args.indexOf("--only");
  const only = onlyIndex === -1 ? "lab" : args[onlyIndex + 1];
  if (only !== "lab" || (onlyIndex !== -1 && !only)) fail("task 09-01 supports --only lab");
  selfTestLab();
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    main();
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 2;
  }
}
