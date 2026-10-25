#!/usr/bin/env node
// Exact-SHA CI verdict helper (plan 250-03, LAND-02).
//
// Decides mechanically whether a 40-hex head SHA meets the Phase 250 CI bar
// (decision D1): every job with a pull_request run path concluded `success` in the
// LATEST attempt of the newest run of each judged workflow, where the run's head_sha
// equals the SHA asked about. Nothing is judged from a branch name, a PR check rollup
// or a run that merely looks recent.
//
// Exit codes: 0 green, 1 red (each offending job and its first failed step is named),
// 2 something is still queued/in progress (or --wait-minutes expired).
//
// Usage:
//   node 250-ci-head-status.mjs --repo OWNER/REPO --sha <40hex> --event pull_request|push
//        [--visual-pending-ok] [--baseline-run <id>] [--wait-minutes <n>] [--json]
//   node 250-ci-head-status.mjs --self-test

import { spawnSync } from "node:child_process";

const CI_PATH = ".github/workflows/ci.yml";
const BROWSER_PATH = ".github/workflows/accrue_admin_browser.yml";
const BROWSER_PUSH_PATHS = ["accrue/", "accrue_admin/", BROWSER_PATH];
const VISUAL_STEP = "Phase 211 visual regression gate";

// Job names pinned from runs 40204835226 (ci.yml) and 40204835309 (browser) at 23bee494,
// minus the D1 exclusions. Playwright's matrix name is expanded here. A rename seen in a
// real run may update this pin; the pin may never shrink.
const PRIMARY = "Primary dev target; elixir=1.19.5 otp=28.0";
export const CI_REQUIRED = [
  "Docs and bash contracts (shift-left)",
  "iOS offline client package compatibility",
  "Release manifest SSOT (REL-02)",
  "Release gate (Floor; elixir=1.19.0 otp=28.0 sigra=off opentelemetry=off)",
  `Release gate (${PRIMARY} sigra=off opentelemetry=off)`,
  `Release gate (${PRIMARY} sigra=off opentelemetry=on)`,
  `Release gate (${PRIMARY} sigra=on opentelemetry=off) [advisory]`,
  "Phase 18 Stripe Tax gate",
  "Admin drift and docs",
  "Admin group contracts (Phase 190)",
  "Admin hardening guardrails (Phase 192)",
  "Admin Phase 200 deterministic guardrails",
  "Admin UI ratchet self-tests",
  "Host integration (required deterministic gate)",
  "Playwright E2E shard 1/3",
  "Playwright E2E shard 2/3",
  "Playwright E2E shard 3/3",
  "Host Docker boot smoke",
  "Annotation sweep"
];
export const CI_PARKED = ["Admin UI ratchet guardrails [parked]"];
export const CI_PR_MUST_SKIP = [
  "Stripe provider-proof trigger classifier",
  "Stripe provider-proof incident reconciliation",
  "Stripe test-mode parity (mandatory periodic)"
];
export const BROWSER_REQUIRED = ["Browser UAT"];
export const BROWSER_PR_MUST_SKIP = ["Mint visual baselines"];

// ---------------------------------------------------------------- gh access

function ghApi(apiPath) {
  const result = spawnSync("gh", ["api", apiPath], { encoding: "utf8", maxBuffer: 100_000_000 });
  if (result.status !== 0) throw new Error(`gh api ${apiPath} failed: ${result.stderr.trim()}`);
  return JSON.parse(result.stdout);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------- collection

// Reads the newest run of one workflow path for (sha, event) and the jobs of its LATEST
// attempt only. Runs whose head_sha differs from the requested one are never judged;
// they are returned in `mismatched` so the verdict can name them.
export function collectWorkflow({ repo, sha, event, workflowPath, gh }) {
  const listing = gh(`repos/${repo}/actions/runs?head_sha=${sha}&per_page=100`);
  const all = (listing.workflow_runs || []).filter((run) => String(run.path || "").startsWith(workflowPath));
  const mismatched = all.filter((run) => run.head_sha !== sha);
  const matching = all
    .filter((run) => run.head_sha === sha && run.event === event)
    .sort((a, b) => String(b.created_at).localeCompare(String(a.created_at)) || b.id - a.id);
  const run = matching[0] || null;
  if (!run) return { workflowPath, run: null, jobs: [], mismatched };
  const attempt = run.run_attempt || 1;
  const jobsPage = gh(`repos/${repo}/actions/runs/${run.id}/attempts/${attempt}/jobs?per_page=100`);
  return {
    workflowPath,
    run: { id: run.id, status: run.status, conclusion: run.conclusion, attempt, head_sha: run.head_sha },
    jobs: (jobsPage.jobs || []).map(normalizeJob),
    mismatched
  };
}

function normalizeJob(job) {
  return {
    id: job.id,
    name: job.name,
    status: job.status,
    conclusion: job.conclusion,
    url: job.html_url,
    steps: (job.steps || []).map((step) => ({ name: step.name, status: step.status, conclusion: step.conclusion }))
  };
}

function firstFailedStep(job) {
  const step = job.steps.find((s) => s.conclusion === "failure");
  return step ? step.name : null;
}

function failedSteps(job) {
  return job.steps.filter((s) => s.conclusion === "failure").map((s) => s.name);
}

function describe(job) {
  const status = job.status === "completed" ? job.conclusion : job.status;
  const step = firstFailedStep(job);
  const ref = job.id ? ` (job ${job.id})` : "";
  return `${job.name}: ${status}${step ? `; first failed step: ${step}` : ""}${ref}`;
}

function isPending(job) {
  return job.status !== "completed";
}

// ---------------------------------------------------------------- judging

export function pathsTriggerBrowser(paths) {
  return paths.filter((p) => BROWSER_PUSH_PATHS.some((prefix) => (prefix.endsWith("/") ? p.startsWith(prefix) : p === prefix)));
}

// Pure verdict over collected data. `collected` = { ci, browser } from collectWorkflow,
// `baseline` = { jobs } (push mode), `changedPaths` = paths changed by the pushed commit.
export function judge({ sha, event, collected, baseline = null, changedPaths = [], visualPendingOk = false, absentIsPending = false }) {
  const red = [];
  const pending = [];
  const notes = [];
  const passed = [];
  let visualPending = false;

  const considerRun = (label, data, { requireRun, required, mustSkip, parked }) => {
    for (const run of data.mismatched) {
      red.push(`${label}: run ${run.id} has head_sha ${run.head_sha}, not ${sha}; it is not judged`);
    }
    if (!data.run) {
      if (!requireRun) {
        notes.push(`${label}: not triggered (paths)`);
        return;
      }
      (absentIsPending ? pending : red).push(`${label}: no ${event} run exists at ${sha}`);
      return;
    }
    notes.push(`${label}: run ${data.run.id} attempt ${data.run.attempt} head_sha ${data.run.head_sha}`);
    const byName = new Map();
    for (const job of data.jobs) byName.set(job.name, job);
    const known = new Set([...required, ...mustSkip, ...parked]);
    for (const job of data.jobs) {
      if (!known.has(job.name)) red.push(`${label}: unpinned job name: ${describe(job)}`);
    }
    for (const name of parked) {
      const job = byName.get(name);
      if (job) notes.push(`${label}: parked lane, any conclusion allowed: ${describe(job)}`);
    }
    for (const name of mustSkip) {
      const job = byName.get(name);
      if (!job) continue;
      if (isPending(job)) pending.push(`${label}: ${describe(job)}`);
      else if (job.conclusion !== "skipped") red.push(`${label}: dispatch-only job ran on ${event}: ${describe(job)}`);
    }
    for (const name of required) {
      const job = byName.get(name);
      if (!job) {
        red.push(`${label}: missing required job: ${name}`);
      } else if (isPending(job)) {
        pending.push(`${label}: ${describe(job)}`);
      } else if (job.conclusion === "success") {
        passed.push(name);
      } else if (visualPendingOk && name === "Browser UAT" && job.conclusion === "failure"
        && failedSteps(job).length === 1 && failedSteps(job)[0] === VISUAL_STEP) {
        visualPending = true;
        notes.push(`${label}: visual-pending, handed to the baseline mint: ${describe(job)}`);
      } else {
        red.push(`${label}: ${describe(job)}`);
      }
    }
  };

  if (event === "pull_request") {
    considerRun("ci.yml", collected.ci, { requireRun: true, required: CI_REQUIRED, mustSkip: CI_PR_MUST_SKIP, parked: CI_PARKED });
    considerRun("accrue_admin_browser.yml", collected.browser, { requireRun: true, required: BROWSER_REQUIRED, mustSkip: BROWSER_PR_MUST_SKIP, parked: [] });
  } else if (event === "push") {
    if (!baseline) throw new Error("--event push requires --baseline-run <id>");
    const baselineOk = new Set(baseline.jobs.filter((j) => j.conclusion === "success").map((j) => j.name));
    const baselineNot = baseline.jobs.filter((j) => j.conclusion !== "success");
    for (const job of baselineNot) notes.push(`ci.yml: recorded, not claimed (baseline ${job.conclusion || job.status}): ${job.name}`);
    const data = collected.ci;
    for (const run of data.mismatched) red.push(`ci.yml: run ${run.id} has head_sha ${run.head_sha}, not ${sha}; it is not judged`);
    if (!data.run) {
      (absentIsPending ? pending : red).push(`ci.yml: no push run exists at ${sha}`);
    } else {
      notes.push(`ci.yml: run ${data.run.id} attempt ${data.run.attempt} head_sha ${data.run.head_sha}`);
      const byName = new Map(data.jobs.map((j) => [j.name, j]));
      for (const name of baselineOk) {
        const job = byName.get(name);
        if (!job) red.push(`ci.yml: baseline success job absent at ${sha}: ${name}`);
        else if (isPending(job)) pending.push(`ci.yml: ${describe(job)}`);
        else if (job.conclusion === "success") passed.push(name);
        else red.push(`ci.yml: baseline success job regressed: ${describe(job)}`);
      }
      for (const job of data.jobs) {
        if (baselineOk.has(job.name) || baselineNot.some((b) => b.name === job.name)) continue;
        if (isPending(job)) pending.push(`ci.yml: ${describe(job)}`);
        else if (job.conclusion === "failure" || job.conclusion === "cancelled") red.push(`ci.yml: job not in baseline failed: ${describe(job)}`);
        else notes.push(`ci.yml: job not in baseline: ${describe(job)}`);
      }
    }
    const matched = pathsTriggerBrowser(changedPaths);
    const b = collected.browser;
    for (const run of b.mismatched) red.push(`accrue_admin_browser.yml: run ${run.id} has head_sha ${run.head_sha}, not ${sha}; it is not judged`);
    if (matched.length === 0) {
      if (!b.run) notes.push("accrue_admin_browser.yml: not triggered (paths)");
    } else if (!b.run) {
      (absentIsPending ? pending : red).push(`accrue_admin_browser.yml: no push run at ${sha} although ${matched.length} changed path(s) match its push paths (${matched[0]})`);
    } else {
      notes.push(`accrue_admin_browser.yml: run ${b.run.id} attempt ${b.run.attempt} head_sha ${b.run.head_sha}`);
      const byName = new Map(b.jobs.map((j) => [j.name, j]));
      const uat = byName.get("Browser UAT");
      if (!uat) red.push("accrue_admin_browser.yml: missing required job: Browser UAT");
      else if (isPending(uat)) pending.push(`accrue_admin_browser.yml: ${describe(uat)}`);
      else if (uat.conclusion === "success") passed.push("Browser UAT");
      else red.push(`accrue_admin_browser.yml: ${describe(uat)}`);
      const mint = byName.get("Mint visual baselines");
      if (mint) {
        if (isPending(mint)) pending.push(`accrue_admin_browser.yml: ${describe(mint)}`);
        else if (mint.conclusion !== "skipped") red.push(`accrue_admin_browser.yml: dispatch-only job ran on push: ${describe(mint)}`);
      }
    }
  } else {
    throw new Error(`unsupported --event ${event}`);
  }

  let code;
  let verdict;
  if (pending.length > 0) {
    code = 2;
    verdict = "PENDING";
  } else if (red.length > 0) {
    code = 1;
    verdict = "RED";
  } else {
    code = 0;
    verdict = visualPending ? "GREEN (visual-pending)" : "GREEN";
  }
  return { code, verdict, sha, event, red, pending, notes, passed, visualPending };
}

function render(result) {
  const out = [`250-ci-head-status: ${result.verdict} at ${result.sha} (event ${result.event})`];
  for (const line of result.notes) out.push(`  note: ${line}`);
  for (const line of result.red) out.push(`  RED: ${line}`);
  for (const line of result.pending) out.push(`  PENDING: ${line}`);
  out.push(`  success jobs: ${result.passed.length}`);
  return out.join("\n");
}

// ---------------------------------------------------------------- self-test

function selfTest() {
  const SHA = "a".repeat(40);
  const OTHER = "b".repeat(40);
  const repo = "o/r";
  let failures = 0;
  let checks = 0;

  const job = (name, conclusion = "success", extra = {}) => ({
    id: Math.floor(Math.random() * 1e9),
    name,
    status: extra.status || "completed",
    conclusion: extra.status && extra.status !== "completed" ? null : conclusion,
    html_url: "https://example.test/job",
    steps: extra.steps || []
  });
  const baseCi = () => [
    ...CI_REQUIRED.map((n) => job(n)),
    job(CI_PARKED[0], "failure", { steps: [{ name: "Verify frozen ratchet evidence", conclusion: "failure" }] }),
    ...CI_PR_MUST_SKIP.map((n) => job(n, "skipped")),
  ];
  const baseBrowser = () => [job("Browser UAT"), job("Mint visual baselines", "skipped")];

  // Fake `gh api`: honours only what the real API does, so attempt selection and the
  // head_sha filter are exercised by the real collection code.
  const makeGh = ({ ci = baseCi(), browser = baseBrowser(), ciAttempts = null, browserRun = true, ciRunSha = SHA, browserRunSha = SHA, event = "pull_request", baselineJobs = null, ciAttempt = 1 }) => (apiPath) => {
    if (apiPath.includes("/actions/runs?head_sha=")) {
      const runs = [
        { id: 100, path: CI_PATH, head_sha: ciRunSha, event, status: "completed", conclusion: "success", run_attempt: ciAttempt, created_at: "2026-01-01T00:00:00Z" }
      ];
      if (browserRun) runs.push({ id: 200, path: BROWSER_PATH, head_sha: browserRunSha, event, status: "completed", conclusion: "success", run_attempt: 1, created_at: "2026-01-01T00:00:00Z" });
      return { workflow_runs: runs };
    }
    let m = apiPath.match(/actions\/runs\/(\d+)\/attempts\/(\d+)\/jobs/);
    if (m) {
      if (m[1] === "100") return { jobs: ciAttempts ? ciAttempts[Number(m[2])] : ci };
      if (m[1] === "200") return { jobs: browser };
      if (m[1] === "900") return { jobs: baselineJobs };
    }
    m = apiPath.match(/actions\/runs\/(\d+)$/);
    if (m && m[1] === "900") return { id: 900, run_attempt: 1 };
    throw new Error(`fake gh: unexpected ${apiPath}`);
  };

  const run = (opts, judgeOpts = {}) => {
    const gh = makeGh(opts);
    const event = judgeOpts.event || "pull_request";
    const collected = {
      ci: collectWorkflow({ repo, sha: SHA, event, workflowPath: CI_PATH, gh }),
      browser: collectWorkflow({ repo, sha: SHA, event, workflowPath: BROWSER_PATH, gh })
    };
    return judge({ sha: SHA, event, collected, ...judgeOpts });
  };

  const expect = (label, result, code, ...needles) => {
    checks += 1;
    const text = render(result);
    const missing = needles.filter((n) => !text.includes(n));
    if (result.code !== code || missing.length > 0) {
      failures += 1;
      console.error(`SELF-TEST FAIL: ${label}: rc ${result.code} (want ${code}); missing in output: ${JSON.stringify(missing)}\n${text}`);
    } else {
      console.log(`ok - ${label} (rc ${code})`);
    }
  };
  const swap = (list, name, replacement) => list.map((j) => (j.name === name ? replacement : j));
  const without = (list, name) => list.filter((j) => j.name !== name);
  const REL = CI_REQUIRED[3];

  expect("all-success fixture; only the parked lane is non-success", run({}), 0);
  expect("parked lane may be success too", run({ ci: swap(baseCi(), CI_PARKED[0], job(CI_PARKED[0])) }), 0);
  expect("required job failure", run({ ci: swap(baseCi(), REL, job(REL, "failure", { steps: [{ name: "Accrue admin test", conclusion: "failure" }] })) }), 1, REL, "Accrue admin test");
  expect("required job skipped", run({ ci: swap(baseCi(), "Host Docker boot smoke", job("Host Docker boot smoke", "skipped")) }), 1, "Host Docker boot smoke", "skipped");
  expect("required job cancelled", run({ ci: swap(baseCi(), "Annotation sweep", job("Annotation sweep", "cancelled")) }), 1, "Annotation sweep");
  expect("missing Playwright shard 2/3", run({ ci: without(baseCi(), "Playwright E2E shard 2/3") }), 1, "Playwright E2E shard 2/3");
  expect("whole browser workflow run absent", run({ browserRun: false }), 1, "accrue_admin_browser.yml", "no pull_request run");
  expect("ci run head_sha differs from --sha", run({ ciRunSha: OTHER }), 1, "run 100", OTHER);
  expect("unpinned job name", run({ ci: [...baseCi(), job("Surprise job")] }), 1, "unpinned job name", "Surprise job");
  expect("unexpanded Playwright matrix placeholder is unpinned", run({ ci: [...without(baseCi(), "Playwright E2E shard 1/3"), job("Playwright E2E shard ${{ matrix.shard }}/${{ strategy.job-total }}", "skipped")] }), 1, "unpinned job name", "Playwright E2E shard 1/3");
  expect("dispatch-only Mint job ran on pull_request", run({ browser: swap(baseBrowser(), "Mint visual baselines", job("Mint visual baselines")) }), 1, "dispatch-only job ran", "Mint visual baselines");
  expect("Stripe trio job ran on pull_request", run({ ci: swap(baseCi(), CI_PR_MUST_SKIP[2], job(CI_PR_MUST_SKIP[2])) }), 1, "dispatch-only job ran", CI_PR_MUST_SKIP[2]);
  const attempt1 = baseCi();
  const attempt2 = swap(baseCi(), "Admin drift and docs", job("Admin drift and docs", "failure", { steps: [{ name: "Ensure committed bundle is fresh", conclusion: "failure" }] }));
  expect("stale attempt: attempt 1 all-success, latest attempt 2 failed", run({ ciAttempts: { 1: attempt1, 2: attempt2 }, ciAttempt: 2 }), 1, "Admin drift and docs", "Ensure committed bundle is fresh");
  expect("latest attempt green is judged, not an older red", run({ ciAttempts: { 1: attempt2, 2: attempt1 }, ciAttempt: 2 }), 0);
  expect("in-progress job exits 2", run({ ci: swap(baseCi(), "Host integration (required deterministic gate)", job("Host integration (required deterministic gate)", null, { status: "in_progress" })) }), 2, "Host integration (required deterministic gate)");
  expect("queued job exits 2", run({ ci: swap(baseCi(), "Annotation sweep", job("Annotation sweep", null, { status: "queued" })) }), 2, "Annotation sweep");
  expect("pending takes precedence over an already-red job", run({ ci: swap(swap(baseCi(), "Annotation sweep", job("Annotation sweep", null, { status: "queued" })), REL, job(REL, "failure")) }), 2);
  expect("absent run during wait grace is pending, not red", run({ browserRun: false }, { absentIsPending: true }), 2, "no pull_request run");

  const visualFail = (steps) => swap(baseBrowser(), "Browser UAT", job("Browser UAT", "failure", { steps }));
  const gate = { name: VISUAL_STEP, conclusion: "failure" };
  expect("Browser UAT red only at the visual gate, flag absent", run({ browser: visualFail([gate]) }), 1, "Browser UAT", VISUAL_STEP);
  expect("visual gate only, --visual-pending-ok", run({ browser: visualFail([gate]) }, { visualPendingOk: true }), 0, "visual-pending");
  expect("visual gate plus another failed step, --visual-pending-ok", run({ browser: visualFail([{ name: "Test Admin hooks", conclusion: "failure" }, gate]) }, { visualPendingOk: true }), 1, "Test Admin hooks");
  expect("--visual-pending-ok never excuses another job", run({ browser: visualFail([gate]), ci: swap(baseCi(), REL, job(REL, "failure")) }, { visualPendingOk: true }), 1, REL);

  // push mode
  const pushBase = () => [...CI_REQUIRED.map((n) => job(n)), ...CI_PR_MUST_SKIP.map((n) => job(n)), job(CI_PARKED[0], "failure")];
  const baseline = (jobs) => ({ jobs });
  const pushRun = (ci, browserOpts, changedPaths, baselineJobs = pushBase().map((j) => (j.name === CI_PARKED[0] ? j : j))) =>
    run({ ci, event: "push", ...browserOpts }, { event: "push", baseline: baseline(baselineJobs), changedPaths });
  expect("push: identical to baseline, browser paths not touched", pushRun(pushBase(), { browserRun: false }, ["README.md"]), 0, "not triggered (paths)", "recorded, not claimed");
  expect("push: baseline success job now failure", pushRun(swap(pushBase(), REL, job(REL, "failure")), { browserRun: false }, ["README.md"]), 1, REL, "regressed");
  expect("push: baseline success job now skipped", pushRun(swap(pushBase(), REL, job(REL, "skipped")), { browserRun: false }, ["README.md"]), 1, REL);
  expect("push: baseline success job now cancelled", pushRun(swap(pushBase(), REL, job(REL, "cancelled")), { browserRun: false }, ["README.md"]), 1, REL);
  expect("push: baseline success job absent", pushRun(without(pushBase(), REL), { browserRun: false }, ["README.md"]), 1, "baseline success job absent", REL);
  expect("push: baseline non-success job is recorded, not claimed", run({ ci: swap(pushBase(), "Host Docker boot smoke", job("Host Docker boot smoke", "skipped")), event: "push", browserRun: false }, { event: "push", baseline: baseline(swap(pushBase(), "Host Docker boot smoke", job("Host Docker boot smoke", "skipped"))), changedPaths: ["README.md"] }), 0, "recorded, not claimed (baseline skipped): Host Docker boot smoke");
  expect("push: browser paths touched, run absent", pushRun(pushBase(), { browserRun: false }, ["accrue_admin/lib/x.ex"]), 1, "accrue_admin_browser.yml", "no push run");
  expect("push: browser paths touched, Browser UAT success, Mint skipped", pushRun(pushBase(), {}, ["accrue/lib/x.ex"]), 0);
  expect("push: browser paths touched, Browser UAT failure", pushRun(pushBase(), { browser: visualFail([gate]) }, [BROWSER_PATH]), 1, "Browser UAT");
  expect("push: Mint ran on push", pushRun(pushBase(), { browser: swap(baseBrowser(), "Mint visual baselines", job("Mint visual baselines")) }, ["accrue/mix.exs"]), 1, "dispatch-only job ran on push");

  checks += 1;
  const sorted = pathsTriggerBrowser(["accrue_admin/a", "accrue/b", ".github/workflows/accrue_admin_browser.yml", "accrue_host/c", "README.md", "accrue-docs/d"]);
  if (sorted.length !== 3) { failures += 1; console.error(`SELF-TEST FAIL: pathsTriggerBrowser matched ${JSON.stringify(sorted)}`); } else console.log("ok - pathsTriggerBrowser prefix boundaries");

  if (failures > 0) {
    console.error(`250-ci-head-status self-test: FAIL (${failures} of ${checks})`);
    return 1;
  }
  console.log(`250-ci-head-status self-test: PASS (${checks} checks)`);
  return 0;
}

// ---------------------------------------------------------------- main

function parseArgs(argv) {
  const opts = { event: "pull_request", wait: 0, visualPendingOk: false, json: false, selfTest: false };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = () => {
      i += 1;
      if (i >= argv.length) throw new Error(`${arg} needs a value`);
      return argv[i];
    };
    if (arg === "--repo") opts.repo = next();
    else if (arg === "--sha") opts.sha = next();
    else if (arg === "--event") opts.event = next();
    else if (arg === "--baseline-run") opts.baselineRun = next();
    else if (arg === "--wait-minutes") opts.wait = Number(next());
    else if (arg === "--visual-pending-ok") opts.visualPendingOk = true;
    else if (arg === "--json") opts.json = true;
    else if (arg === "--self-test") opts.selfTest = true;
    else throw new Error(`unknown argument ${arg}`);
  }
  return opts;
}

function changedPathsFor(sha) {
  const result = spawnSync("git", ["diff", "--name-only", `${sha}^1`, sha], { encoding: "utf8", maxBuffer: 100_000_000 });
  if (result.status !== 0) throw new Error(`git diff ${sha}^1 ${sha} failed (is the commit fetched?): ${result.stderr.trim()}`);
  return result.stdout.split("\n").filter(Boolean);
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.selfTest) return selfTest();
  if (!opts.repo || !/^[0-9a-f]{40}$/.test(opts.sha || "")) throw new Error("--repo OWNER/REPO and a 40-hex --sha are required");
  if (!["pull_request", "push"].includes(opts.event)) throw new Error("--event must be pull_request or push");
  if (opts.event === "push" && !opts.baselineRun) throw new Error("--event push requires --baseline-run <id>");

  let baseline = null;
  if (opts.event === "push") {
    const baseRun = ghApi(`repos/${opts.repo}/actions/runs/${opts.baselineRun}`);
    const attempt = baseRun.run_attempt || 1;
    baseline = { jobs: ghApi(`repos/${opts.repo}/actions/runs/${opts.baselineRun}/attempts/${attempt}/jobs?per_page=100`).jobs.map(normalizeJob) };
  }
  const changedPaths = opts.event === "push" ? changedPathsFor(opts.sha) : [];
  const deadline = Date.now() + opts.wait * 60_000;
  const graceEnd = Date.now() + Math.min(opts.wait, 5) * 60_000;

  for (;;) {
    const collected = {
      ci: collectWorkflow({ repo: opts.repo, sha: opts.sha, event: opts.event, workflowPath: CI_PATH, gh: ghApi }),
      browser: collectWorkflow({ repo: opts.repo, sha: opts.sha, event: opts.event, workflowPath: BROWSER_PATH, gh: ghApi })
    };
    const result = judge({
      sha: opts.sha, event: opts.event, collected, baseline, changedPaths,
      visualPendingOk: opts.visualPendingOk, absentIsPending: opts.wait > 0 && Date.now() < graceEnd
    });
    if (result.code !== 2 || Date.now() >= deadline) {
      if (result.code === 2 && opts.wait > 0) result.pending.push(`--wait-minutes ${opts.wait} expired`);
      console.log(opts.json ? JSON.stringify(result, null, 2) : render(result));
      return result.code;
    }
    await sleep(60_000);
  }
}

main().then((code) => process.exit(code), (error) => {
  console.error(`250-ci-head-status: ${error.message}`);
  process.exit(3);
});
