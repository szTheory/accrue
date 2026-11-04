import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import * as generator from "./generate_phase254_acceptance.mjs";
import { renderAutomatedUat } from "./verify_executable_uat_contract.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const phaseDir = path.join(root, ".planning", "phases", generator.PHASE_SLUG);
const readJson = (relative) => JSON.parse(fs.readFileSync(path.join(root, relative), "utf8"));
const sha = (relative) => requireHash(fs.readFileSync(path.join(root, relative)));
function requireHash(bytes) {
  return createHash(bytes);
}
function createHash(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}
function hashText(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}
function fixtureEvidence() {
  const metadata = generator.inspectPhase254Metadata({ root });
  const ledger = readJson("accrue_admin/storybook/subscription-curation.json");
  const visualCases = readJson("accrue_admin/storybook/phase254-visual-cases.json");
  const visualManifest = readJson("accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json");
  const manifestEntries = visualManifest.entries ?? visualManifest;
  const designReview = readJson(`.planning/phases/${generator.PHASE_SLUG}/254-DESIGN-REVIEW.json`);
  const digestRows = (assets) => assets.map(({ path: assetPath, sha256: expected_sha256, key }) => ({ key, path: assetPath, expected_sha256, actual_sha256: expected_sha256 }));
  const sourceAssets = Object.entries(designReview.assets).flatMap(([key, value]) => value.path ? [{ key, path: value.path, sha256: value.sha256 }] : []);
  const visualAssets = Object.entries(manifestEntries).map(([key, value]) => ({ key, expected_sha256: value.sha256, actual_sha256: value.sha256 }));
  const curationSources = Object.entries(ledger.source_digests ?? {}).map(([sourcePath, expected_sha256]) => ({ path: sourcePath, expected_sha256, actual_sha256: expected_sha256 }));
  const checkpointAnswers = {
    "254-03-01": "push-approved",
    "254-03-03": "fix-in-phase; accept-known-red for KR-254-06",
    "254-15-02": "fix-in-phase; accept-attributable",
    "254-18-02": "not required",
  };
  const amendments = [
    ...(ledger.amendments ?? []).map((row) => ({ ...row, source: "accrue_admin/storybook/subscription-curation.json" })),
    ...(visualCases.amendments ?? []).map((row) => ({ ...row, source: "accrue_admin/storybook/phase254-visual-cases.json" })),
    ...(designReview.amendments ?? []).map((row) => ({ ...row, source: `.planning/phases/${generator.PHASE_SLUG}/254-DESIGN-REVIEW.json` })),
  ];
  const taskResults = Object.fromEntries(metadata.tasks.map((task) => [task.id, {
    task_id: task.id,
    command_sha256: hashText(task.automated ?? `checkpoint:${task.id}`),
    status: "pass",
    skipped: 0,
    retries: 0,
    evidence_refs: [`254-VALIDATION.md#task-${task.id}`],
    supporting_refs: [task.id === "254-05-01" ? "live isolation test: 403 in review lane, test lane 200" :
      task.id === "254-05-02" ? "interleaved race control, reconciliation and dependent project identity pass" :
        task.id === "254-02-03" ? "pure-story classifier and ownership contract pass" :
          task.automated ? `${task.plan}-SUMMARY.md#${task.id}` : ({
      "254-03-01": "254-03-CHECKPOINT-LOG.md",
      "254-03-03": "254-03-SUMMARY.md",
      "254-15-02": "254-15-CHECKPOINT-LOG.md",
      "254-18-02": "254-18-SUMMARY.md",
    })[task.id]],
    ...(task.checkpoint ? { checkpoint_answer: checkpointAnswers[task.id] } : {}),
  }]));
  const taskEvidence = Object.fromEntries(metadata.tasks.map((task) => [task.id, {
    plan: task.plan,
    task_id: task.id,
    requirements: [...task.requirements],
    evidence_refs: taskResults[task.id].evidence_refs,
    supporting_refs: taskResults[task.id].supporting_refs,
    command_sha256: taskResults[task.id].command_sha256,
    status: "pass",
    skipped: 0,
    retries: 0,
    automated_command: task.automated ?? `checkpoint:decision (recorded answer for ${task.id})`,
    threat_refs: [...task.threat_refs],
  }]));
  const head = "a".repeat(40);
  const budget = {
    manifest_sha256: sha("storybook/phase252-manifest.json"),
    metrics: {
      final: { head_sha: head, runs: [] },
      visual: { run_id: 11, added_s: 0, per_cell: { p90_ms: 1 } },
      a11y: { run_id: 12, added_s: 0, per_cell: { p90_ms: 1 } },
    },
    deviations: [
      { id: "DEV-254-05", kind: "ciq02-fanout-enabled", status: "resolved" },
      { id: "DEV-254-50", kind: "a11y-cell-budget-freeze", status: "accepted" },
    ],
    known_reds: [],
  };
  const summaries = metadata.plans.map((plan) => ({
    name: plan.name.replace("-PLAN.md", "-SUMMARY.md"),
    status: "complete",
    coverage: metadata.tasks.filter((task) => task.plan === plan.name.replace("-PLAN.md", "")).map((task) => ({
      human_judgment: false,
      verification: taskResults[task.id].supporting_refs.map((ref) => ({ ref, status: "pass" })),
    })),
  }));
  const mintRunIds = [...new Set(Object.values(manifestEntries).filter((entry) => entry.provenance !== "phase211-committed" && entry.mint_run_id != null).map((entry) => String(entry.mint_run_id)))].sort();
  return {
    metadata,
    summaries,
    tasks: taskEvidence,
    task_results: taskResults,
    edge_evidence: Object.fromEntries(generator.EDGE_IDS.map((id) => {
      const binding = generator.EDGE_BINDINGS[id];
      return [id, {
        status: "pass",
        task_id: binding.task_id,
        summary_name: `${binding.task_id.slice(0, 6)}-SUMMARY.md`,
        source_path: binding.source_path,
        source_sha256: sha(binding.source_path),
        test_identities: [...binding.test_identities],
        source_assertions: [...(binding.source_assertions ?? [])],
        refs: [`executed evidence: ${binding.execution_ref}`],
      }];
    })),
    prohibitions: metadata.prohibition_statements.map((statement) => ({ statement, status: "green", fail_first: true })),
    amendments,
    manifest: { keys: Object.keys(manifestEntries), mint_run_ids: mintRunIds, entries: manifestEntries },
    visual_cases: visualCases,
    design_review: designReview,
    ledger,
    identities: {
      source_assets: digestRows(sourceAssets),
      visual_assets: visualAssets,
      curation_sources: curationSources,
      current_manifest_sha256: budget.manifest_sha256,
      budget_manifest_sha256: budget.manifest_sha256,
      measured_head: head,
      git_head: head,
      measured_head_is_ancestor: true,
      source_drift_after_measurement: [],
    },
    budget,
    checkpoints: checkpointAnswers,
    escalation_count: 0,
    final_runs: [
      { job: "admin-phase200-guardrails", run_id: 11, head_sha: head, attempt: 1, conclusion: "success", phase_owned_ok: true },
      { job: "browser-uat", run_id: 12, head_sha: head, attempt: 1, conclusion: "success", phase_owned_ok: true },
    ],
  };
}
function rejects(mutator, pattern) {
  const evidence = structuredClone(fixtureEvidence());
  mutator(evidence);
  assert.throws(() => generator.validatePhase254Evidence(evidence), pattern);
}

test("metadata is parsed from all eighteen plans and binds seven requirements and every task", () => {
  const metadata = generator.inspectPhase254Metadata({ root });
  assert.equal(metadata.plans.length, 18);
  assert.deepEqual(metadata.requirements, [...generator.REQUIREMENT_IDS].sort());
  assert.ok(metadata.tasks.some(({ id }) => id === "254-18-03"));
  assert.deepEqual(metadata.unclassified, [...generator.UNRESOLVED_ASSUMPTION_IDS]);
});

test("repository-relative directory paths may end with a slash without weakening traversal checks", () => {
  assert.equal(generator.normalizeRepositoryRelativePath("accrue_admin/e2e/__screenshots__/visual-desktop/"), "accrue_admin/e2e/__screenshots__/visual-desktop");
  assert.throws(() => generator.normalizeRepositoryRelativePath("scripts//ci/file.mjs"), /unsafe path/);
  assert.throws(() => generator.normalizeRepositoryRelativePath("../outside/file.mjs"), /unsafe path/);
});

test("a complete evidence fixture validates all requirements, tasks, edges, amendments and current identities", () => {
  assert.equal(generator.validatePhase254Evidence(fixtureEvidence()).status, "passed");
});

test("every explicit edge is bound to its named test identities, source file and executed summary ref", () => {
  for (const id of generator.EDGE_IDS) {
    const binding = generator.EDGE_BINDINGS[id];
    const source = fs.readFileSync(path.join(root, binding.source_path), "utf8");
    assert.ok(binding.test_identities.every((identity) => source.includes(identity)), `${id} source identity`);
    assert.ok(binding.task_id, `${id} task identity`);
  }
  rejects((e) => { e.edge_evidence[generator.EDGE_IDS[0]].test_identities = []; }, /test identities mismatch/);
  rejects((e) => { e.edge_evidence[generator.EDGE_IDS[1]].source_sha256 = "stale"; }, /source identity is stale/);
  rejects((e) => { e.edge_evidence[generator.EDGE_IDS[2]].refs = ["unrelated test run"]; }, /bound test run/);
});

test("a missing requirement is rejected", () => rejects((e) => e.metadata.requirements.pop(), /requirement IDs mismatch/));
test("a task without executed evidence is rejected", () => rejects((e) => { delete e.tasks["254-14-02"]; }, /task evidence IDs mismatch/));
test("task evidence is bound to the task ID, exact planned command and task-specific validation result", () => {
  rejects((e) => { delete e.task_results["254-14-02"]; }, /per-task result IDs mismatch/);
  rejects((e) => { e.task_results["254-14-02"].command_sha256 = "0".repeat(64); }, /command identity mismatch/);
  rejects((e) => { e.task_results["254-14-02"].task_id = "254-14-01"; }, /task evidence command identity mismatch/);
  rejects((e) => { e.task_results["254-14-02"].evidence_refs = ["254-14-SUMMARY.md#plan-level-green"]; }, /no matching task-specific green result/);
  rejects((e) => { e.task_results["254-14-02"].supporting_refs = ["254-13-SUMMARY.md#254-13-02"]; }, /no matching task-specific green result/);
  rejects((e) => { e.task_results["254-14-02"].status = "failed"; }, /has no executed green evidence/);
  rejects((e) => { e.task_results["254-14-02"].skipped = 1; }, /skipped tests/);
});
test("generic plan-level and sibling-task refs cannot stand in for the task-specific result", () => {
  const task = generator.inspectPhase254Metadata({ root }).tasks.find(({ id }) => id === "254-01-01");
  const summaryRefs = ["254-01-SUMMARY.md#plan-level-green"];
  assert.equal(generator.taskResultIsGreen(task, null, summaryRefs, {}), false);
  const result = {
    task_id: task.id,
    command_sha256: hashText(task.automated),
    status: "pass",
    skipped: 0,
    retries: 0,
    evidence_refs: [`254-VALIDATION.md#task-${task.id}`],
    supporting_refs: ["254-01-SUMMARY.md#plan-level-green"],
  };
  assert.equal(generator.taskResultIsGreen(task, result, summaryRefs, {}), true);
  assert.equal(generator.taskResultIsGreen(task, { ...result, evidence_refs: ["254-01-SUMMARY.md#plan-level-green"] }, summaryRefs, {}), false);
  assert.equal(generator.taskResultIsGreen(task, { ...result, evidence_refs: ["254-VALIDATION.md#task-254-01-02"] }, summaryRefs, {}), false);
  assert.equal(generator.taskResultIsGreen(task, { ...result, command_sha256: "0".repeat(64) }, summaryRefs, {}), false);
});
test("skipped or retried test evidence is rejected", () => {
  rejects((e) => { e.tasks["254-14-02"].skipped = 1; }, /skipped tests/);
  rejects((e) => { e.tasks["254-14-02"].retries = 1; }, /retried tests/);
});
test("stale source, asset, manifest and run identities are rejected", () => {
  rejects((e) => { e.identities.source_assets[0].actual_sha256 = "0".repeat(64); }, /source asset is stale/);
  rejects((e) => { e.identities.visual_assets[0].actual_sha256 = "0".repeat(64); }, /visual baseline asset is stale/);
  rejects((e) => { e.identities.current_manifest_sha256 = "0".repeat(64); }, /budget manifest digest is stale/);
  rejects((e) => { e.final_runs[0].head_sha = "b".repeat(40); }, /different source head/);
  rejects((e) => { e.identities.source_drift_after_measurement = ["accrue_admin/lib/source.ex"]; }, /source files changed after its observed head/);
});
test("final owner jobs require green phase-owned attempt-1 runs and all deviations must close", () => {
  rejects((e) => { e.final_runs = e.final_runs.filter((run) => run.job !== "admin-phase200-guardrails"); }, /admin-phase200-guardrails has no successful attempt-1 phase-owned run/);
  rejects((e) => { e.final_runs[1].phase_owned_ok = false; }, /browser-uat has no successful attempt-1 phase-owned run/);
  rejects((e) => { e.budget.deviations[0].status = "open"; }, /open budget deviation remains/);
});
test("unmatched final reds and owner-job reds are rejected", () => {
  rejects((e) => {
    e.final_runs.push({ job: "Docs and bash contracts (shift-left)", run_id: 13, head_sha: "a".repeat(40), attempt: 1, conclusion: "failure", phase_owned_ok: false });
  }, /red run 13 has no triage disposition/);
  rejects((e) => {
    e.final_runs.push({ job: "Docs and bash contracts (shift-left)", run_id: 13, head_sha: "a".repeat(40), attempt: 1, conclusion: "failure", phase_owned_ok: false });
    e.budget.deviations.push({ id: "DEV-254-51", kind: "final-triage", status: "accepted", entries: [{ job: "Docs and bash contracts (shift-left)", step: "SL-G", run_id: 13, classification: "environmental" }] });
  }, /unmatched environmental red requires the 254-18-02 owner decision/);
  rejects((e) => {
    e.budget.deviations.push({ id: "DEV-254-51", kind: "final-triage", status: "accepted", entries: [{ job: "admin-phase200-guardrails", step: "owner step", run_id: 11, classification: "in-scope", fixed_in_sha: "b".repeat(40), followup_run_id: 14, owner_job_out_of_scope: true }] });
  }, /out-of-scope red remains inside a required owner job/);
});
test("unclassified assumptions cannot be relabelled resolved", () => rejects((e) => { e.metadata.unresolved_assumptions[0].status = "resolved"; }, /must remain unresolved/));
test("each promoted prohibition needs its native fail-first proof", () => rejects((e) => { e.prohibitions[1].fail_first = false; }, /native green and fail-first proof/));
test("every unconditional amendment is required", () => {
  for (const id of generator.AMENDMENT_IDS) rejects((e) => { e.amendments = e.amendments.filter((row) => row.id !== id); }, /unconditional and conditional amendments/);
});
test("amendments require the plan-time owner acknowledgment", () => rejects((e) => { e.amendments.find((row) => row.id === "AMD-254-04").owner_ack = undefined; }, /plan-time owner acknowledgment/));
test("AMD-254-06 is required for multiple mint identities and must name the exact runs", () => {
  rejects((e) => { e.manifest.mint_run_ids = ["run-a", "run-b"]; e.amendments = e.amendments.filter((row) => row.id !== "AMD-254-06"); }, /AMD-254-06 is required/);
  rejects((e) => { e.manifest.mint_run_ids = ["run-a", "run-b"]; e.amendments.find((row) => row.id === "AMD-254-06").amended = ["run-a"]; }, /mint run identities mismatch/);
});
test("CIQ-02 needs the isolation identities, pure-story classifier and fan-out decision", () => {
  rejects((e) => {
    e.tasks["254-05-01"].supporting_refs = ["review lane works"];
    e.task_results["254-05-01"].supporting_refs = ["review lane works"];
    e.summaries.find(({ name }) => name === "254-05-SUMMARY.md").coverage.find((entry) => entry.verification.some(({ ref }) => ref === "live isolation test: 403 in review lane, test lane 200")).verification[0].ref = "review lane works";
  }, /CIQ-02 isolation evidence/);
  rejects((e) => { e.budget.deviations = e.budget.deviations.filter((row) => row.kind !== "ciq02-fanout-enabled"); }, /CIQ-02 isolation evidence/);
});
test("the confirmed design review must cover every rubric dimension", () => rejects((e) => { e.design_review.rubric_verdicts.pop(); }, /rubric dimensions mismatch/));
test("checkpoint tasks require recorded answers", () => rejects((e) => { delete e.checkpoints["254-15-02"]; }, /checkpoint answer IDs mismatch/));
test("the recorded 254-03-03 disposition is grounded in its summary, and 254-18-02 waits for a recorded outcome", () => {
  const summaries = [
    { name: "254-03-SUMMARY.md", source: fs.readFileSync(path.join(phaseDir, "254-03-SUMMARY.md"), "utf8") },
    { name: "254-15-SUMMARY.md", source: fs.readFileSync(path.join(phaseDir, "254-15-SUMMARY.md"), "utf8") },
  ];
  const noEscalation = { metrics: { final: { runs: [] } }, deviations: [], known_reds: [] };
  const beforeSummary = generator.checkpointAnswers(root, noEscalation, summaries);
  assert.equal(beforeSummary["254-03-03"], "fix-in-phase; accept-known-red for KR-254-06");
  assert.equal(beforeSummary["254-18-02"], "");

  const triageRecorded = {
    metrics: { final: {
      escalation_required: false,
      escalation_count: 0,
      runs: [
        { job: "admin-phase200-guardrails", attempt: 1, conclusion: "success", phase_owned_ok: true },
        { job: "browser-uat", attempt: 1, conclusion: "success", phase_owned_ok: true },
      ],
    } },
    deviations: [], known_reds: [],
  };
  assert.equal(generator.checkpointAnswers(root, triageRecorded, summaries)["254-18-02"], "not required");
  assert.equal(generator.checkpointAnswers(root, {
    ...triageRecorded,
    metrics: { final: { ...triageRecorded.metrics.final, runs: [] } },
  }, summaries)["254-18-02"], "");

  const recordedSummary = { ...summaries[0], name: "254-18-SUMMARY.md", source: "254-18-02 escalation not required (0 unmatched reds)" };
  assert.equal(generator.checkpointAnswers(root, noEscalation, [...summaries, recordedSummary])["254-18-02"], "not required");

  const unresolved = {
    ...triageRecorded,
    deviations: [{ kind: "final-triage", entries: [{ job: "other", step: "step", run_id: 5, classification: "environmental" }] }],
  };
  const needsOwner = generator.checkpointAnswers(root, unresolved, summaries);
  assert.equal(needsOwner["254-18-02"], "");
  const ownerDecision = { ...recordedSummary, source: "254-18-02 entry x: fix-in-phase" };
  assert.equal(generator.checkpointAnswers(root, unresolved, [...summaries, ownerDecision])["254-18-02"], "fix-in-phase");
});
test("summary acceptance requires human_judgment false and green evidence", () => {
  rejects((e) => { e.summaries[0].coverage[0].human_judgment = true; }, /SUMMARY has missing or human-judgment-only/);
  rejects((e) => { delete e.summaries[0].coverage[0].human_judgment; }, /SUMMARY has missing or human-judgment-only/);
});
test("pendingInputs reports only the current plan summary and refuses early UAT writes", () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "phase254-pending-"));
  const fixturePhase = path.join(temp, ".planning", "phases", generator.PHASE_SLUG);
  fs.mkdirSync(fixturePhase, { recursive: true });
  try {
    for (const name of generator.SUMMARY_NAMES ?? Array.from({ length: 17 }, (_, index) => `254-${String(index + 1).padStart(2, "0")}-SUMMARY.md`)) {
      if (name === "254-18-SUMMARY.md") continue;
      fs.writeFileSync(path.join(fixturePhase, name), "placeholder\n");
    }
    assert.deepEqual(generator.pendingInputs({ root: temp }), ["254-18-SUMMARY.md"]);
    assert.throws(() => generator.generatePhase254Acceptance({ root: temp, latest: true, writeUat: true }), /refusing to generate 254-UAT\.md/);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test("--expect-pending succeeds only when the final summary is the sole missing input", () => {
  const temp = fs.mkdtempSync(path.join(root, "accrue_admin", "tmp", "phase254-pending-cli-"));
  const tempPhase = path.join(temp, ".planning", "phases", generator.PHASE_SLUG);
  const tempScripts = path.join(temp, "scripts", "ci");
  const tempBudget = path.join(temp, "accrue_admin", "storybook", "phase254-budget.json");
  fs.mkdirSync(tempPhase, { recursive: true });
  fs.mkdirSync(tempScripts, { recursive: true });
  try {
    fs.cpSync(phaseDir, tempPhase, { recursive: true, filter: (source) => path.basename(source) !== "254-18-SUMMARY.md" });
    for (const name of ["generate_phase254_acceptance.mjs", "phase_evidence_path.mjs", "main_module.mjs", "verify_executable_uat_contract.mjs"]) {
      fs.copyFileSync(path.join(root, "scripts", "ci", name), path.join(tempScripts, name));
    }
    const budget = readJson("accrue_admin/storybook/phase254-budget.json");
    const head = spawnSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" });
    assert.equal(head.status, 0, head.stderr);
    budget.metrics.final.head_sha = head.stdout.trim();
    for (const run of budget.metrics.final.runs ?? []) if (run.head_sha) run.head_sha = head.stdout.trim();
    const copyRepoFile = (relative) => {
      const destination = path.join(temp, relative);
      fs.mkdirSync(path.dirname(destination), { recursive: true });
      fs.copyFileSync(path.join(root, relative), destination);
    };
    const ledger = readJson("accrue_admin/storybook/subscription-curation.json");
    const visualCases = readJson("accrue_admin/storybook/phase254-visual-cases.json");
    const review = readJson(`.planning/phases/${generator.PHASE_SLUG}/254-DESIGN-REVIEW.json`);
    const manifest = readJson("accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json");
    const files = new Set([
      "accrue_admin/storybook/subscription-curation.json",
      "accrue_admin/storybook/phase254-visual-cases.json",
      "accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json",
      "storybook/phase252-manifest.json",
      "accrue_admin/lib/accrue_admin/live/subscriptions_live.ex",
      "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
      "accrue_admin/assets/css/app.css",
      "accrue_admin/assets/css/theme.css",
      "accrue_admin/priv/static/accrue_admin.css",
      "accrue_admin/priv/static/storybook.css",
      ...Object.keys(review.assets).map((key) => review.assets[key].path).filter(Boolean),
      ...Object.keys(ledger.source_digests ?? {}),
      ...generator.EDGE_IDS.map((id) => generator.EDGE_BINDINGS[id].source_path),
      ...Object.values(manifest.entries ?? manifest).map((entry) => `accrue_admin/e2e/__screenshots__/visual-desktop/${entry.file}`),
    ]);
    for (const relative of files) copyRepoFile(relative);
    fs.mkdirSync(path.dirname(tempBudget), { recursive: true });
    fs.writeFileSync(tempBudget, `${JSON.stringify(budget, null, 2)}\n`);
    const script = path.join(tempScripts, "generate_phase254_acceptance.mjs");
    const childEnv = { ...process.env };
    delete childEnv.NODE_TEST_CONTEXT;
    const expectedPending = spawnSync(process.execPath, [script, "--latest", "--expect-pending", "254-18"], { cwd: temp, encoding: "utf8", env: childEnv });
    assert.equal(expectedPending.status, 0, expectedPending.stderr);
    const result = JSON.parse(expectedPending.stdout);
    assert.equal(result.status, "pending");
    assert.equal(result.completed_summary_count, 17);
    assert.equal(result.tasks.length, 51);
    assert.equal(result.final_runs.length, 4);
    assert.deepEqual(result.pending_inputs, ["254-18-SUMMARY.md"]);
    assert.equal(result.uat_written, false);

    const validationPath = path.join(tempPhase, "254-VALIDATION.md");
    const validation = fs.readFileSync(validationPath, "utf8");
    fs.unlinkSync(validationPath);
    const missingValidation = spawnSync(process.execPath, [script, "--latest", "--expect-pending", "254-18"], { cwd: temp, encoding: "utf8", env: childEnv });
    assert.notEqual(missingValidation.status, 0);
    fs.writeFileSync(validationPath, validation);

    const budgetBytes = fs.readFileSync(tempBudget);
    fs.unlinkSync(tempBudget);
    const missingBudget = spawnSync(process.execPath, [script, "--latest", "--expect-pending", "254-18"], { cwd: temp, encoding: "utf8", env: childEnv });
    assert.notEqual(missingBudget.status, 0);
    fs.writeFileSync(tempBudget, budgetBytes);

    const unexpectedPending = spawnSync(process.execPath, [script, "--latest", "--expect-pending", "254-17"], { cwd: temp, encoding: "utf8", env: childEnv });
    assert.notEqual(unexpectedPending.status, 0);
    fs.unlinkSync(path.join(tempPhase, "254-17-SUMMARY.md"));
    const extraMissing = spawnSync(process.execPath, [script, "--latest", "--expect-pending", "254-18"], { cwd: temp, encoding: "utf8", env: childEnv });
    assert.notEqual(extraMissing.status, 0);
  } finally {
    fs.rmSync(temp, { recursive: true, force: true });
  }
});

test("generated UAT equals the project renderer after complete summaries and verification exist", () => {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), "phase254-uat-render-"));
  const tempPhase = path.join(tempRoot, ".planning", "phases", generator.PHASE_SLUG);
  fs.mkdirSync(tempPhase, { recursive: true });
  try {
    for (const name of generator.SUMMARY_NAMES.slice(0, 17)) fs.copyFileSync(path.join(phaseDir, name), path.join(tempPhase, name));
    fs.writeFileSync(path.join(tempPhase, "254-18-SUMMARY.md"), `---\nstatus: complete\ncompleted: 2026-11-03\ncoverage:\n  - id: T1\n    description: "Phase 254 final automated contract"\n    requirement: CIQ-04\n    verification:\n      - kind: command\n        ref: "node scripts/ci/generate_phase254_acceptance.test.mjs"\n        status: pass\n    human_judgment: false\n---\n`);
    fs.writeFileSync(path.join(tempPhase, "254-VERIFICATION.md"), "---\nstatus: passed\nbehavior_unverified: 0\n---\n");
    const summaries = generator.validateCompletedSummaries({ root: tempRoot });
    assert.equal(generator.renderUat(summaries), renderAutomatedUat(tempPhase));
  } finally {
    fs.rmSync(tempRoot, { recursive: true, force: true });
  }
});
