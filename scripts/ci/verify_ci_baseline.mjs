#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { collectBaseline, cohortFingerprint, liveRuns, summarizeCohorts, unresolvedPrerequisites, workflowRunnerImage } from "./collect_ci_baseline.mjs";
import { deriveStagedPathPercentiles, renderBaseline } from "./render_ci_baseline.mjs";

function fail(message) {
  throw new Error(message);
}

function verifyCriticalPath(records, rendered) {
  const staged = deriveStagedPathPercentiles(records);
  assert.equal(staged.sample_count, 20, "critical path requires exactly 20 complete staged observations");
  assert.notEqual(staged.p50_ms, null, "critical path p50 must be present");
  assert.notEqual(staged.p95_ms, null, "critical path p95 must be present");
  assert.match(rendered, /Fingerprint strata/, "rendered Markdown discloses fingerprint strata");
  assert.match(rendered, /Sensitivity/, "rendered Markdown discloses per-stratum sensitivity");
  assert.match(rendered, new RegExp(`Latest compatible complete paths: ${staged.sample_count}`), "rendered Markdown names the staged sample count");
  assert.match(rendered, new RegExp(`staged-path p50: ${Math.round(staged.p50_ms / 1000)}s`), "rendered Markdown reports staged p50");
  assert.match(rendered, new RegExp(`staged-path p95: ${Math.round(staged.p95_ms / 1000)}s`), "rendered Markdown reports staged p95");
  assert.match(rendered, new RegExp(`\\*\\*${staged.conclusion}\\*\\*`), "rendered Markdown states the explicit conclusion");
  assert.equal(staged.fingerprint_distribution.reduce((total, stratum) => total + stratum.sample_count, 0), 20, "fingerprint distribution accounts for every selected observation");
  return staged;
}

function fixturePath() {
  return path.resolve(".planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json");
}

function rejectsForbiddenFields(fixture) {
  for (const field of ["actor", "logs", "secret_metadata", "provider_payload", "artifact_content", "user_data"]) {
    assert.throws(
      () => collectBaseline([{ ...fixture.successful_run, [field]: "forbidden" }]),
      new RegExp(`forbidden field: ${field}`),
      `${field} is rejected`
    );
  }
  assert.throws(
    () => collectBaseline([{ ...fixture.successful_run, head_branch: undefined, raw_branch: "forbidden" }]),
    /forbidden field: raw_branch/,
    "raw branch fields are rejected"
  );
}

function datedRun(base, id, offset, overrides = {}) {
  const stamp = (seconds) => new Date(Date.parse(base.created_at) + (offset * 86_400_000) + (seconds * 1_000)).toISOString();
  return {
    ...base, id, html_url: `https://github.com/acme/accrue/actions/runs/${id}`, head_sha: `${id.toString(16).padStart(12, "0")}${"a".repeat(28)}`,
    created_at: stamp(0), run_started_at: stamp(5), updated_at: stamp(305),
    jobs: base.jobs.map((job, index) => ({ ...job, id: (id * 10) + index, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + index}`, started_at: stamp(index ? 200 : 10), completed_at: stamp(index ? 300 : 190) })),
    ...overrides
  };
}

function cohortControls(fixture) {
  for (const event of ["push", "pull_request"]) {
    const omittedProviderState = { ...fixture.successful_run, event };
    delete omittedProviderState.provider_state;
    assert.equal(
      collectBaseline([omittedProviderState])[0].provider_state,
      "non_run",
      `successful ${event} input without provider evidence remains non_run`
    );
  }
  for (const providerState of ["proved", "failed", "misconfigured", "blocked", "skipped", "non_run"]) {
    assert.equal(
      collectBaseline([{ ...fixture.successful_run, provider_state: providerState }])[0].provider_state,
      providerState,
      `explicit ${providerState} provider state is preserved`
    );
  }

  const unresolvedPrerequisite = structuredClone(fixture.successful_run);
  unresolvedPrerequisite.jobs[1].needs = ["required-release-gate"];
  assert.throws(
    () => collectBaseline([unresolvedPrerequisite]),
    /test.*required-release-gate|required-release-gate.*test/,
    "an absent prerequisite fails with both dependent and prerequisite identities"
  );

  const nineteen = Array.from({ length: 19 }, (_, index) => datedRun(fixture.successful_run, 200 + index, index));
  const twenty = [...nineteen, datedRun(fixture.successful_run, 220, 20)];
  const insufficient = summarizeCohorts(nineteen);
  assert.equal(insufficient[0].sample_count, 19);
  assert.equal(insufficient[0].sample_status, "insufficient_sample");
  assert.equal(insufficient[0].p50_ms, null);
  const ready = summarizeCohorts(twenty);
  assert.equal(ready[0].sample_count, 20);
  assert.equal(ready[0].sample_status, "ready");
  assert.equal(ready[0].p50_ms, 300000);
  assert.equal(ready[0].p95_ms, 300000);

  const nonRunPopulation = (event, startId) => Array.from(
    { length: 20 },
    (_, index) => datedRun(fixture.successful_run, startId + index, index, { event, provider_state: "non_run" })
  );
  const nonRunPush = nonRunPopulation("push", 230);
  const nonRunPullRequest = nonRunPopulation("pull_request", 260);
  const nonRunCohorts = summarizeCohorts([...nonRunPush, ...nonRunPullRequest]);
  assert.equal(nonRunCohorts.length, 2, "push and pull_request remain separate timing cohorts");
  for (const cohort of nonRunCohorts) {
    assert.equal(cohort.sample_count, 20, "non_run full-CI cohort has the locked sample count");
    assert.equal(cohort.sample_status, "ready", "non_run full-CI cohort is ready");
    assert.notEqual(cohort.p50_ms, null, "non_run full-CI cohort emits p50");
    assert.notEqual(cohort.p95_ms, null, "non_run full-CI cohort emits p95");
  }
  for (const run of [...nonRunPush, ...nonRunPullRequest]) {
    assert.equal(collectBaseline([run])[0].provider_state, "non_run", "timing eligibility does not manufacture provider proof");
  }

  const original = datedRun(fixture.successful_run, 301, 21, { original_run_id: 300, run_attempt: 1, conclusion: "failure" });
  const retry = datedRun(fixture.successful_run, 302, 22, { original_run_id: 300, run_attempt: 2, head_sha: original.head_sha });
  const rerun = summarizeCohorts([...twenty, original, retry])[0];
  assert.equal(rerun.sample_count, 20, "a later retry cannot inflate green samples");
  assert.equal(rerun.reliability.rerun_count, 1, "reliability retains rerun facts");

  const failed = datedRun(fixture.successful_run, 401, 23, { conclusion: "failure" });
  failed.jobs = failed.jobs.map((job) => ({ ...job, conclusion: "failure", failure_message: "Timeout request 1234567890abcdef" }));
  const failedRecords = collectBaseline([failed]).filter((record) => record.kind === "job");
  assert.equal(new Set(failedRecords.map((job) => job.failure_signature)).size, 1, "matrix failures collapse to one root signature");
  assert.deepEqual(summarizeCohorts([failed])[0].reliability.root_incidents[0].affected_cells.sort(), ["build", "test"]);
  const cancelled = datedRun(fixture.successful_run, 402, 23, { conclusion: "cancelled" });
  const skipped = datedRun(fixture.successful_run, 403, 23, { conclusion: "skipped" });
  const reliability = summarizeCohorts([failed, cancelled, skipped])[0].reliability;
  assert.equal(reliability.failure_count, 1);
  assert.equal(reliability.cancellation_count, 1);
  assert.equal(reliability.skipped_count, 1);

  const scheduled = datedRun(fixture.successful_run, 501, 24, { event: "schedule", provider_state: "non_run" });
  const dispatch = datedRun(fixture.successful_run, 502, 24, { event: "workflow_dispatch", provider_state: "misconfigured" });
  assert.notEqual(cohortFingerprint(scheduled), cohortFingerprint(dispatch), "provider-only schedule and full dispatch are separate cohorts");
  assert.equal(collectBaseline([scheduled])[0].provider_state, "non_run");
  assert.equal(collectBaseline([dispatch])[0].provider_state, "misconfigured");

  const instrumented = datedRun(fixture.successful_run, 550, 25);
  instrumented.jobs[0].cache = { hit: true, restore_ms: 12, save_ms: 2, size_bytes: 128 };
  instrumented.jobs[0].setup_costs = { node_ms: 5, npm_ms: 6, browser_ms: 7, playwright_ms: 8 };
  const instrumentedJob = collectBaseline([instrumented]).find((record) => record.kind === "job");
  assert.deepEqual(instrumentedJob.cache, { hit: true, restore_ms: 12, save_ms: 2, size_bytes: 128 });
  assert.deepEqual(instrumentedJob.setup_costs, { node_ms: 5, npm_ms: 6, browser_ms: 7, playwright_ms: 8 });

  assert.throws(() => collectBaseline([datedRun(fixture.successful_run, 601, 25, { updated_at: "not-a-time" })]), /updated_at/);
  const validLeapDay = datedRun({ ...fixture.successful_run, created_at: "2024-02-29T00:00:00Z" }, 602, 0);
  assert.doesNotThrow(() => collectBaseline([validLeapDay]), "real leap-day run timestamps are accepted");
  for (const invalid of ["2026-02-30T00:00:00Z", "2025-02-29T00:00:00Z"]) {
    assert.throws(
      () => collectBaseline([datedRun({ ...fixture.successful_run, created_at: "2024-02-29T00:00:00Z" }, 603, 0, { updated_at: invalid })]),
      /run.updated_at must be an ISO-8601 UTC timestamp/,
      `baseline run rejects impossible UTC calendar date: ${invalid}`
    );
    const invalidJob = datedRun({ ...fixture.successful_run, created_at: "2024-02-29T00:00:00Z" }, 604, 0);
    invalidJob.jobs[0].completed_at = invalid;
    assert.throws(
      () => collectBaseline([invalidJob]),
      /job.completed_at must be an ISO-8601 UTC timestamp/,
      `baseline job rejects impossible UTC calendar date: ${invalid}`
    );
  }
  assert.throws(() => collectBaseline([{ ...fixture.successful_run, jobs: [{ ...fixture.successful_run.jobs[0], name: "!!!" }] }]), /job.name/);
}

function stagedRun(base, id, offset, overrides = {}) {
  const stamp = (seconds) => new Date(Date.parse(base.created_at) + (offset * 86_400_000) + (seconds * 1_000)).toISOString();
  const run = datedRun(base, id, offset, {
    updated_at: stamp(2_100),
    workflow_path: ".github/workflows/ci.yml@critical-path",
    jobs: [
      { id: (id * 10) + 1, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + 1}`, name: "release-gate", started_at: stamp(10), completed_at: stamp(300), conclusion: "success", runner_image: "ubuntu-24.04", needs: [] },
      { id: (id * 10) + 2, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + 2}`, name: "host-integration", started_at: stamp(360), completed_at: stamp(900), conclusion: "success", runner_image: "ubuntu-24.04", needs: ["release-gate"] },
      { id: (id * 10) + 3, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + 3}`, name: "playwright-e2e (shard 1)", started_at: stamp(960), completed_at: stamp(1_800), conclusion: "success", runner_image: "ubuntu-24.04", needs: ["host-integration"] },
      { id: (id * 10) + 4, html_url: `https://github.com/acme/accrue/actions/runs/${id}/job/${(id * 10) + 4}`, name: "playwright-e2e (shard 2)", started_at: stamp(970), completed_at: stamp(2_050), conclusion: "success", runner_image: "ubuntu-24.04", needs: ["host-integration"] }
    ]
  });
  return { ...run, ...overrides };
}

function stagedPathControls(fixture) {
  const runs = Array.from({ length: 20 }, (_, index) => stagedRun(fixture.successful_run, 700 + index, index));
  const records = [...collectBaseline(runs), ...summarizeCohorts(runs)];
  const staged = deriveStagedPathPercentiles(records);
  assert.equal(staged.sample_count, 20, "one ready cohort contributes exactly 20 staged observations");
  assert.equal(staged.p50_ms, 2_040_000, "p50 measures per-run release start to latest Playwright completion");
  assert.equal(staged.p95_ms, 2_040_000, "p95 uses the same per-run span population");
  assert.equal(staged.conclusion, "confirmed", "33–36 minute staged path is confirmed");
  assert.match(renderBaseline(records), /confirmed/, "renderer reports the cohort conclusion");

  const contraryRuns = runs.map((run) => ({ ...run, jobs: run.jobs.map((job) => job.name.includes("shard 2") ? { ...job, completed_at: new Date(Date.parse(job.completed_at) + 300_000).toISOString() } : job) }));
  const contrary = deriveStagedPathPercentiles([...collectBaseline(contraryRuns), ...summarizeCohorts(contraryRuns)]);
  assert.equal(contrary.conclusion, "contrary_measured_result", "out-of-range staged path reports a measured contrary result");

  const missingHost = runs.map((run) => ({ ...run, jobs: run.jobs.filter((job) => job.name !== "host-integration") }));
  assert.throws(() => deriveStagedPathPercentiles([...collectBaseline(missingHost), ...summarizeCohorts(missingHost)]), /unresolved prerequisite host-integration|missing host-integration stage/, "missing host stage is rejected before staged-path arithmetic");
  const badOrderRecords = records.map((record) => record.kind === "job" && record.stable_identity === "playwright-e2e" ? { ...record, started_at: new Date(Date.parse(record.started_at) - 200_000).toISOString() } : record);
  assert.throws(() => deriveStagedPathPercentiles(badOrderRecords), /Playwright stage must start after host-integration/, "stage ordering is rejected at the staged-path boundary");
  const rerun = [...runs.slice(0, 19), stagedRun(fixture.successful_run, 720, 20, { original_run_id: 700, run_attempt: 2, head_sha: runs[0].head_sha })];
  assert.throws(() => deriveStagedPathPercentiles([...collectBaseline(rerun), ...summarizeCohorts(rerun)]), /20 compatible complete paths/, "rerun inflation cannot satisfy the stage cohort");
  assert.throws(() => deriveStagedPathPercentiles([...collectBaseline(runs.slice(0, 19)), ...summarizeCohorts(runs.slice(0, 19))]), /20 compatible complete paths/, "nineteen observations cannot satisfy the stage cohort");

  const multiFingerprintRuns = runs.map((run, index) => ({
    ...run,
    workflow_revision: `critical-path-${index % 4}`
  }));
  const multiFingerprintRecords = [...collectBaseline(multiFingerprintRuns), ...summarizeCohorts(multiFingerprintRuns)];
  const compatible = deriveStagedPathPercentiles(multiFingerprintRecords);
  assert.equal(compatible.sample_count, 20, "latest compatible complete paths span fingerprints without weakening the sample size");
  assert.equal(compatible.fingerprint_distribution.length, 4, "fingerprint distribution retains every observed topology stratum");
  assert.deepEqual(compatible.fingerprint_distribution.map((stratum) => stratum.sample_count), [5, 5, 5, 5], "fingerprint sensitivity is deterministic");
  assert.equal(compatible.fingerprint_distribution.reduce((total, stratum) => total + stratum.sample_count, 0), 20, "strata sum to the selected population");
  const compatibleMarkdown = renderBaseline(multiFingerprintRecords);
  assert.match(compatibleMarkdown, /Fingerprint strata/, "compatible-path report labels fingerprint distribution");
  assert.match(compatibleMarkdown, /Sensitivity/, "compatible-path report labels per-stratum sensitivity");

  const duplicateIdentity = multiFingerprintRuns.map((run, index) => index === 19 ? { ...run, original_run_id: multiFingerprintRuns[0].id, head_sha: multiFingerprintRuns[0].head_sha } : run);
  assert.throws(() => deriveStagedPathPercentiles([...collectBaseline(duplicateIdentity), ...summarizeCohorts(duplicateIdentity)]), /20 unique successful first-attempt/, "duplicate original-run/SHA identity cannot fill the compatible population");
  const scheduledCompatible = multiFingerprintRuns.map((run, index) => index === 19 ? { ...run, event: "schedule" } : run);
  assert.throws(() => deriveStagedPathPercentiles([...collectBaseline(scheduledCompatible), ...summarizeCohorts(scheduledCompatible)]), /20 compatible complete paths/, "schedule/provider-only runs cannot fill the compatible population");
}

function historicalRevisionAndIdentityControls() {
  const base = {
    id: 1_700,
    html_url: "https://github.com/szTheory/accrue/actions/runs/1700",
    head_sha: "b".repeat(40),
    created_at: "2026-08-11T06:00:00Z",
    run_started_at: "2026-08-11T06:00:10Z",
    updated_at: "2026-08-11T06:02:00Z",
    event: "push",
    head_branch: "main",
    conclusion: "success",
    run_attempt: 1,
    workflow_revision: "sha256:f6b1d06c0897168bdff1b692a63d1704db24b96a48620504888b1fe2f30c47fa"
  };
  const job = (name, id = 17_000) => ({
    id,
    html_url: `https://github.com/szTheory/accrue/actions/runs/1700/job/${id}`,
    name,
    started_at: "2026-08-11T06:00:20Z",
    completed_at: "2026-08-11T06:01:00Z",
    conclusion: "success"
  });
  const historicalHost = { ...base, jobs: [job("Host integration (required deterministic gate)")] };
  assert.deepEqual(unresolvedPrerequisites([historicalHost]), [], "an audited historical revision admits its exact documented missing prerequisite");
  for (const [label, run, expected] of [
    ["unknown historical revision", { ...historicalHost, workflow_revision: "sha256:" + "0".repeat(64) }, /admin-drift-and-docs|docs-and-bash-contracts-shift-left/],
    ["unknown historical topology", { ...base, jobs: [job("Host integration unknown topology")] }, /unresolved workflow job identity/],
    ["malicious host suffix", { ...base, jobs: [job("Host integration attacker")] }, /unresolved workflow job identity/],
    ["release suffix", { ...base, jobs: [job("Release gate attacker")] }, /unresolved workflow job identity/],
    ["out-of-range Playwright shard", { ...base, jobs: [job("Playwright E2E shard 4/3")] }, /unresolved workflow job identity/]
  ]) {
    assert.throws(() => collectBaseline([run]), expected, `${label} fails before durable record emission`);
  }
  for (const name of [
    "Playwright E2E shard 1/3",
    "Playwright E2E shard 2/3",
    "Playwright E2E shard 3/3",
    "playwright-e2e-shard-matrix.shard-/-strategy.job-total",
    "Release gate (Floor; elixir=1.19.0 otp=28.0 sigra=off opentelemetry=off)",
    "Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=off)",
    "Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=on opentelemetry=off) [advisory]",
    "Release gate (Primary dev target; elixir=1.19.5 otp=28.0 sigra=off opentelemetry=on)"
  ]) {
    assert.doesNotThrow(() => workflowRunnerImage(name), `declared matrix identity resolves: ${name}`);
  }
  for (const name of [
    "playwright-e2e-shard-matrix.shard-/-strategy.job-total-attacker",
    "playwright-e2e-shard-matrix.shard-1-strategy.job-total-3"
  ]) {
    assert.throws(() => workflowRunnerImage(name), /unresolved workflow runner contract/, `non-enumerated matrix identity remains rejected: ${name}`);
  }
}

async function liveDisplayIdentityControls() {
  const workflow = fs.readFileSync(path.resolve(".github/workflows/ci.yml"), "utf8");
  const docsDisplayName = "Docs and bash contracts (shift-left)";
  assert.match(
    workflow,
    /^  docs-contracts-shift-left:\n    name: Docs and bash contracts \(shift-left\)$/m,
    "the live fixture remains coupled to the docs-contracts-shift-left workflow display name"
  );
  const run = { id: 980, html_url: "https://github.com/acme/accrue/actions/runs/980", head_sha: "a".repeat(40), created_at: "2026-08-11T06:00:00Z", run_started_at: "2026-08-11T06:00:10Z", updated_at: "2026-08-11T06:04:00Z", event: "push", head_branch: "main", conclusion: "success", run_attempt: 2 };
  const jobs = [
    [9800, "Release gate (Primary dev target)", "2026-08-11T06:00:15Z", "2026-08-11T06:00:19Z"],
    [9801, "Admin drift and docs", "2026-08-11T06:00:20Z", "2026-08-11T06:01:00Z"],
    [9802, docsDisplayName, "2026-08-11T06:00:25Z", "2026-08-11T06:01:10Z"],
    [9803, "Host integration (required deterministic gate)", "2026-08-11T06:01:20Z", "2026-08-11T06:03:00Z"],
  ].map(([id, name, started_at, completed_at]) => ({ id, html_url: `https://github.com/acme/accrue/actions/runs/980/job/${id}`, name, started_at, completed_at, conclusion: "success", run_attempt: 2, runner_name: "self-hosted-looking-name", steps: [] }));
  const skippedOnlyRun = { ...run, id: 979, event: "schedule", run_attempt: 1 };
  const skippedOnlyJob = { ...jobs[0], id: 9790, name: "Release gate (${{ matrix.compatibility }}; elixir=${{ matrix.elixir }} otp=${{ matrix.otp }} sigra=${{ matrix.sigra }} opentelemetry=${{ matrix.opentelemetry }})", conclusion: "skipped", run_attempt: 1 };
  const skippedOnly = await liveRuns("acme/accrue", "ci.yml", 90, {
    fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: [skippedOnlyJob] }] : [{ workflow_runs: [skippedOnlyRun] }],
    now: () => Date.parse("2026-08-11T06:04:00Z")
  });
  assert.deepEqual(skippedOnly[0].jobs, [], "skipped workflow nodes cannot enter timing or DAG admission");
  const annotationPrerequisites = [
    "Release manifest SSOT (REL-02)", docsDisplayName, "Release gate (Primary dev target)", "Phase 18 Stripe Tax gate",
    "Admin drift and docs", "Admin group contracts (Phase 190)", "Admin hardening guardrails (Phase 192)",
    "Admin Phase 200 deterministic guardrails", "Admin UI ratchet guardrails", "Host integration (required deterministic gate)",
    "Playwright E2E shard 1/3", "Host Docker boot smoke"
  ].map((name, index) => ({
    id: 97_000 + index, html_url: `https://github.com/acme/accrue/actions/runs/977/job/${97_000 + index}`, name,
    started_at: `2026-08-11T06:${String(index).padStart(2, "0")}:00Z`, completed_at: `2026-08-11T06:${String(index).padStart(2, "0")}:30Z`,
    conclusion: "success", run_attempt: 1, steps: []
  }));
  const annotation = { id: 97_099, html_url: "https://github.com/acme/accrue/actions/runs/977/job/97099", name: "Annotation sweep", started_at: "2026-08-11T06:20:00Z", completed_at: "2026-08-11T06:21:00Z", conclusion: "success", run_attempt: 1, steps: [] };
  const annotationRun = { ...run, id: 977, run_attempt: 1 };
  const annotationFetch = (jobsForRun) => async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: jobsForRun }] : [{ workflow_runs: [annotationRun] }];
  const incompleteAnnotation = await liveRuns("acme/accrue", "ci.yml", 90, {
    fetchPages: annotationFetch([...annotationPrerequisites.filter((job) => job.name !== "Host Docker boot smoke"), annotation]), now: () => Date.parse("2026-08-11T06:22:00Z")
  });
  assert.ok(!incompleteAnnotation[0].jobs.some((job) => job.name === "Annotation sweep"), "annotation sweep with an absent declared prerequisite is excluded from timing evidence");
  const completeAnnotation = await liveRuns("acme/accrue", "ci.yml", 90, {
    fetchPages: annotationFetch([...annotationPrerequisites, annotation]), now: () => Date.parse("2026-08-11T06:22:00Z")
  });
  assert.ok(completeAnnotation[0].jobs.some((job) => job.name === "Annotation sweep"), "annotation sweep with every declared successful prerequisite remains eligible");
  const stale = { ...jobs[0], id: 9799, run_attempt: 1, conclusion: "failure", started_at: "2026-08-11T06:00:11Z", completed_at: "2026-08-11T06:03:59Z" };
  const endpoints = [];
  const fetchPages = async (endpoint) => {
    endpoints.push(endpoint);
    if (endpoint.includes("/jobs?filter=all")) return [{ jobs: [stale, ...jobs] }];
    if (endpoint.includes("/attempts/2/jobs?")) return [{ jobs }];
    return [{ workflow_runs: [run] }];
  };
  const records = collectBaseline(await liveRuns("acme/accrue", "ci.yml", 90, { fetchPages, now: () => Date.parse("2026-08-11T06:04:00Z") }));
  assert.ok(endpoints.some((endpoint) => endpoint.includes("/attempts/2/jobs?")), "live collector requests only the exact run-attempt jobs endpoint");
  assert.ok(endpoints.every((endpoint) => !endpoint.includes("/jobs?filter=all")), "live collector never requests all-attempt jobs");
  assert.deepEqual(records.filter((record) => record.kind === "job").map((record) => record.job_id), jobs.map((job) => job.id), "only current-attempt jobs reach normalized records");
  const host = records.find((record) => record.kind === "job" && record.stable_identity === "host-integration");
  assert.equal(host.dag_wait_ms, 10_000, "host resolves current display-name prerequisites in the live collector");
  const historicalScheduledRun = { ...run, id: 981, event: "schedule", workflow_revision: "sha256:2535a639493f2b5549d3bb0e1baf12bc12ede268b55cd710e41da3afb22f2e42" };
  const historicalScheduledJobs = jobs.filter((job) => job.name !== "Release gate (Primary dev target)");
  const historicalScheduledFetch = async (endpoint) => endpoint.includes("/jobs?")
    ? [{ jobs: historicalScheduledJobs }]
    : [{ workflow_runs: [historicalScheduledRun] }];
  const historicalScheduledRecords = collectBaseline(await liveRuns("szTheory/accrue", "ci.yml", 90, {
    fetchPages: historicalScheduledFetch,
    now: () => Date.parse("2026-08-11T06:04:00Z")
  }));
  assert.equal(
    historicalScheduledRecords.find((record) => record.kind === "job" && record.stable_identity === "admin-drift-and-docs").dag_wait_ms,
    null,
    "historical scheduled admin drift job retains its explicit no-prerequisite topology"
  );
  const historicalNonScheduledFetch = async (endpoint) => endpoint.includes("/jobs?")
    ? [{ jobs: historicalScheduledJobs }]
    : [{ workflow_runs: [{ ...historicalScheduledRun, event: "push" }] }];
  const historicalNonScheduledRuns = await liveRuns("szTheory/accrue", "ci.yml", 90, {
    fetchPages: historicalNonScheduledFetch,
    now: () => Date.parse("2026-08-11T06:04:00Z")
  });
  assert.throws(
    () => collectBaseline(historicalNonScheduledRuns),
    /job admin-drift-and-docs has unresolved prerequisite release-gate/,
    "the scheduled compatibility mapping cannot hide a missing non-scheduled release gate"
  );
  for (const [name, mutate, pattern] of [
    ["absent", (items) => items.filter((job) => job.name !== docsDisplayName), /unresolved prerequisite docs-and-bash-contracts-shift-left/],
    ["spelling drift", (items) => items.map((job) => job.name === docsDisplayName ? { ...job, name: "Docs and bash contract (shift-left)" } : job), /unresolved prerequisite docs-and-bash-contracts-shift-left/],
    ["temporal", (items) => items.map((job) => job.name === docsDisplayName ? { ...job, completed_at: "2026-08-11T06:01:30Z" } : job), /starts before prerequisite docs-and-bash-contracts-shift-left completes/],
  ]) {
    const brokenFetch = async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: mutate(jobs) }] : [{ workflow_runs: [run] }];
    if (name === "spelling drift") {
      await assert.rejects(() => liveRuns("acme/accrue", "ci.yml", 90, { fetchPages: brokenFetch, now: () => Date.parse("2026-08-11T06:04:00Z") }), /unresolved workflow runner contract/, `${name} cannot fabricate a runner contract`);
      continue;
    }
    const broken = await liveRuns("acme/accrue", "ci.yml", 90, { fetchPages: brokenFetch, now: () => Date.parse("2026-08-11T06:04:00Z") });
    assert.throws(() => collectBaseline(broken), pattern, `${name} live prerequisite fails closed`);
  }

  const mismatchedFetch = async (endpoint) => endpoint.includes("/attempts/2/jobs?") ? [{ jobs: [{ ...jobs[0], run_attempt: 1 }] }] : [{ workflow_runs: [run] }];
  await assert.rejects(() => liveRuns("acme/accrue", "ci.yml", 90, { fetchPages: mismatchedFetch, now: () => Date.parse("2026-08-11T06:04:00Z") }), /job.run_attempt must match run.run_attempt/, "mismatched attempt is rejected before normalization");

  assert.equal(workflowRunnerImage("Docs and bash contracts (shift-left)"), "github-hosted/ubuntu-24.04", "docs runner class comes from the trusted workflow contract");
  assert.equal(workflowRunnerImage("iOS offline client package compatibility"), "github-hosted/macos-15", "iOS runner class comes from the trusted workflow contract");
  assert.equal(workflowRunnerImage("controlled self-hosted job", [{ identity: "controlled-self-hosted-job", runsOn: "[self-hosted, linux, x64]" }]), "self-hosted/declared", "self-hosted classification omits raw labels");
  assert.throws(() => workflowRunnerImage("unknown external job"), /unresolved workflow runner contract/, "unknown runner identity fails closed");
  assert.throws(() => workflowRunnerImage("Release gate", [{ identity: "release-gate", runsOn: "ubuntu-24.04" }, { identity: "release-gate", runsOn: "macos-15" }]), /ambiguous workflow runner contract/, "ambiguous runner identity fails closed");
  assert.notEqual(cohortFingerprint({ ...run, jobs: [{ ...jobs[0], runner_image: "github-hosted/ubuntu-24.04" }] }), cohortFingerprint({ ...run, jobs: [{ ...jobs[0], runner_image: "github-hosted/macos-15" }] }), "different workflow-declared runner images produce distinct fingerprints");
  assert.notEqual(cohortFingerprint({ ...run, jobs: [{ ...jobs[0], runner_image: "github-hosted/ubuntu-24.04" }] }), cohortFingerprint({ ...run, jobs: [{ ...jobs[0], runner_image: "self-hosted/declared" }] }), "self-hosted work cannot share a hosted cohort");

  const historicalRatchetRun = {
    ...run,
    id: 982,
    workflow_revision: "sha256:89a5a0cb25d05eb88f40cffed7f1ba2549676b440d0a018d218eaa69e253cae8",
    created_at: "2026-08-11T06:00:00Z",
    event: "workflow_dispatch",
    jobs: [
      { ...jobs[0], id: 9819, name: "Admin hardening guardrails (Phase 192)", started_at: "2026-08-11T06:00:15Z", completed_at: "2026-08-11T06:00:19Z" },
      { ...jobs[0], id: 9820, name: "Admin UI ratchet guardrails", started_at: "2026-08-11T06:00:20Z", completed_at: "2026-08-11T06:01:00Z" }
    ]
  };
  const historicalRatchet = await liveRuns("szTheory/accrue", "ci.yml", 90, {
    fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: historicalRatchetRun.jobs }] : [{ workflow_runs: [historicalRatchetRun] }],
    now: () => Date.parse("2026-08-11T06:04:00Z")
  });
  assert.deepEqual(
    unresolvedPrerequisites(historicalRatchet),
    [],
    "the audited historical ratchet compatibility rule resolves its absent Phase 200 prerequisite"
  );
  const futureRatchet = await liveRuns("szTheory/accrue", "ci.yml", 90, {
    fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: historicalRatchetRun.jobs }] : [{ workflow_runs: [{ ...historicalRatchetRun, created_at: "2026-08-13T06:00:00Z" }] }],
    now: () => Date.parse("2026-08-13T06:04:00Z")
  });
  assert.deepEqual(
    unresolvedPrerequisites(futureRatchet),
    ["job admin-ui-ratchet-guardrails has unresolved prerequisite admin-phase-200-deterministic-guardrails"],
    "future ratchet runs cannot inherit the historical compatibility rule"
  );

  const compatibilityCases = [
    { event: "schedule", name: "Admin drift and docs", expected: "release-gate", revision: "sha256:2535a639493f2b5549d3bb0e1baf12bc12ede268b55cd710e41da3afb22f2e42" },
    { event: "push", name: "Host Docker boot smoke", expected: "docs-and-bash-contracts-shift-left", revision: "sha256:abe82c1752c18b85daccb8a33255b78adee988866a6f1df64c68186d4f90fd43" },
    { event: "push", name: "Host integration (required deterministic gate)", expected: "admin-drift-and-docs", revision: "sha256:f6b1d06c0897168bdff1b692a63d1704db24b96a48620504888b1fe2f30c47fa" },
    { event: "push", name: "Playwright E2E shard 1/3", expected: "host-integration", revision: "sha256:fbef942d3a3f18c88689962c5d658a0a6dde16a95cfeb8e06b99b68d58e3ce99" }
  ];
  for (const [index, compatibility] of compatibilityCases.entries()) {
    const historicalRun = { ...run, id: 990 + index, event: compatibility.event, created_at: "2026-08-11T06:00:00Z", workflow_revision: compatibility.revision, jobs: [{ ...jobs[0], id: 9900 + index, name: compatibility.name, started_at: "2026-08-11T06:00:20Z", completed_at: "2026-08-11T06:01:00Z" }] };
    const fetch = async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: historicalRun.jobs }] : [{ workflow_runs: [historicalRun] }];
    const historical = await liveRuns("szTheory/accrue", "ci.yml", 90, { fetchPages: fetch, now: () => Date.parse("2026-08-11T06:04:00Z") });
    assert.deepEqual(unresolvedPrerequisites(historical), [], `historical compatibility accepts ${compatibility.name} only in its audited era`);
    const future = await liveRuns("szTheory/accrue", "ci.yml", 90, { fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: historicalRun.jobs }] : [{ workflow_runs: [{ ...historicalRun, created_at: "2026-08-13T06:00:00Z" }] }], now: () => Date.parse("2026-08-13T06:04:00Z") });
    assert.ok(unresolvedPrerequisites(future).some((message) => message.endsWith(` ${compatibility.expected}`)), `future ${compatibility.name} remains fail-closed for ${compatibility.expected}`);
  }
  const scheduledRatchetOnly = { ...run, id: 998, event: "schedule", created_at: "2026-08-11T06:00:00Z", workflow_revision: "sha256:943d650205233f1c5c017bc605c90077600ba8c33240ea6268326887c0960ec0", jobs: [{ ...jobs[0], id: 9980, name: "Admin UI ratchet guardrails", started_at: "2026-08-11T06:00:20Z", completed_at: "2026-08-11T06:01:00Z" }] };
  const scheduledRatchet = await liveRuns("szTheory/accrue", "ci.yml", 90, { fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: scheduledRatchetOnly.jobs }] : [{ workflow_runs: [scheduledRatchetOnly] }], now: () => Date.parse("2026-08-11T06:04:00Z") });
  assert.deepEqual(unresolvedPrerequisites(scheduledRatchet), [], "scheduled ratchet compatibility includes its historical hardening prerequisite absence");
  const futureScheduledRatchet = await liveRuns("szTheory/accrue", "ci.yml", 90, { fetchPages: async (endpoint) => endpoint.includes("/jobs?") ? [{ jobs: scheduledRatchetOnly.jobs }] : [{ workflow_runs: [{ ...scheduledRatchetOnly, created_at: "2026-08-13T06:00:00Z" }] }], now: () => Date.parse("2026-08-13T06:04:00Z") });
  assert.ok(unresolvedPrerequisites(futureScheduledRatchet).some((message) => message.endsWith(" admin-hardening-guardrails")), "future scheduled ratchet runs remain fail-closed for the historical hardening prerequisite");
}

export async function verifyFixtures() {
  const fixture = JSON.parse(fs.readFileSync(fixturePath(), "utf8"));
  for (const scenario of ["successful_first_attempt", "failure", "cancellation", "rerun", "provider_non_run", "provider_misconfigured", "repeated_matrix_signature", "privacy_rejection", "arithmetic", "insufficient_sample"]) {
    assert.ok(fixture.scenarios.includes(scenario), `fixture inventory includes ${scenario}`);
  }
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "accrue-ci-baseline-"));
  try {
    const records = collectBaseline([fixture.successful_run]);
    assert.equal(records.length, 3, "successful fixture emits run plus two jobs");
    const ndjsonPath = path.join(temp, "baseline.ndjson");
    fs.writeFileSync(ndjsonPath, `${records.map((record) => JSON.stringify(record)).join("\n")}\n`);
    const markdown = renderBaseline(records);
    assert.match(markdown, /Comparable timing/, "renderer includes timing table");
    assert.doesNotMatch(markdown, /unsafe-branch-name/, "renderer never receives raw branch name");
    const jobs = records.filter((record) => record.kind === "job");
    assert.equal(jobs[0].runner_queue_ms, 10_000, "root queue is measured from workflow creation");
    assert.equal(jobs[0].dag_wait_ms, null, "root jobs have no DAG wait");
    assert.equal(jobs[1].runner_queue_ms, null, "dependent jobs do not masquerade DAG wait as queue");
    assert.equal(jobs[1].dag_wait_ms, 10_000, "dependent wait uses latest prerequisite completion");
    rejectsForbiddenFields(fixture);
    cohortControls(fixture);
    stagedPathControls(fixture);
    historicalRevisionAndIdentityControls();
    await liveDisplayIdentityControls();
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
}

async function main() {
  const args = process.argv.slice(2);
  const recordsIndex = args.indexOf("--records");
  const renderedIndex = args.indexOf("--rendered");
  const requireCriticalPath = args.includes("--require-critical-path");
  if (args.includes("--fixtures")) await verifyFixtures();
  if (recordsIndex !== -1) {
    const source = args[recordsIndex + 1];
    if (!source) fail("--records requires an NDJSON path");
    const records = fs.readFileSync(source, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
    const expected = renderBaseline(records);
    if (renderedIndex !== -1) {
      const rendered = args[renderedIndex + 1];
      if (!rendered) fail("--rendered requires a Markdown path");
      assert.equal(fs.readFileSync(rendered, "utf8"), expected, "rendered Markdown must be byte-reproducible");
    }
    if (requireCriticalPath) verifyCriticalPath(records, expected);
  }
  if (requireCriticalPath && recordsIndex === -1) fail("--require-critical-path requires --records");
  if (!args.includes("--fixtures") && recordsIndex === -1) fail("usage: verify_ci_baseline.mjs --fixtures | --records records.ndjson [--rendered baseline.md] [--require-critical-path]");
  console.log("ci baseline fixtures: PASS");
}

try {
  await main();
} catch (error) {
  console.error(`ci baseline fixtures: FAIL: ${error.message}`);
  process.exitCode = 1;
}
