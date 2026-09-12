import assert from "node:assert/strict";
import fs from "node:fs";
import { spawnSync } from "node:child_process";
import test from "node:test";
import { verifyComparisonEvidence, verifyFinalDecision, verifyPreflightEvidence } from "./verify_ci_critical_path.mjs";

const phase = ".planning/phases/227-measured-critical-path-improvement";
const contract = JSON.parse(fs.readFileSync(`${phase}/227-ci-contract.json`, "utf8"));
const fixtures = JSON.parse(fs.readFileSync(`${phase}/fixtures/ci-critical-path-cases.json`, "utf8"));

test("rejects forged duplicate push cohort through public verification", () => {
  assert.throws(
    () => verifyComparisonEvidence(fixtures.forged_keep_evidence, contract, fixtures.context),
    /workflow_dispatch|unique|required job|schema fields/,
  );
});

test("rejects a CLI invocation with no declared action", () => {
  const result = spawnSync(process.execPath, ["scripts/ci/verify_ci_critical_path.mjs"], { encoding: "utf8" });
  assert.notEqual(result.status, 0, "a no-action verifier invocation must fail closed");
});

test("requires a kept v2 terminal decision when requested", () => {
  const result = spawnSync(process.execPath, [
    "scripts/ci/verify_ci_critical_path.mjs",
    "--verify-evidence",
    "--evidence", `${phase}/227-CI-CRITICAL-PATH.ndjson`,
    "--contract", `${phase}/227-ci-contract.json`,
    "--expected-repository", "szTheory/accrue",
    "--require-kept",
  ], { encoding: "utf8" });
  assert.notEqual(result.status, 0, "the recorded rollback terminal must not satisfy a kept-only request");
  assert.match(result.stderr, /v2 terminal decision is not kept/, "the verifier must reject rollback as non-kept, not reject the modifier itself");
});

test("keeps v3 authority unspent until a matching preflight activation", () => {
  const history = fs.readFileSync(`${phase}/227-CI-CRITICAL-PATH.ndjson`, "utf8").trim().split("\n").map(JSON.parse).filter((record) => record.kind !== "gap_budget_authorization_v3");
  const budget = { kind: "gap_budget_authorization_v3", budget_id: "phase-227-gap-dispatch-false-v3", authorized_at: "2026-09-12T00:00:00Z", owner: "maintainer", repository: "szTheory/accrue", event_class: "workflow_dispatch", candidate_run_live_stripe: false, candidate_run_attempt: 1, candidate_fingerprint: "phase-227-gap-dispatch-false-v3", candidate_provider_state: "non_run", candidate_ceiling: 3, conditional_restoration_ceiling: 1, no_reruns: true, no_replacements: true, no_concurrency: true, remote_effects: "disabled", stop_on_first_nonqualifying: true, closed_predecessors: ["phase-227-dispatch-false-v1", "phase-227-gap-dispatch-false-v2"], existing_negative_control_run_id: 31660617339, phase228_provider_evidence: "../228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md", phase228_provider_outcome: "failed/selected_assertions_failed", thresholds: contract.thresholds };
  assert.deepEqual(verifyFinalDecision([...history, budget], contract), { state: "authorized_pending_candidate", admitted_observations: 0, reserved: 0, consumed: 0 });
  assert.throws(() => verifyFinalDecision([...history, budget, { kind: "gap_v3_reservation", reservation_id: "r1", purpose: "candidate", candidate_sha: "a".repeat(40), status: "open" }], contract), /cannot reserve before activation/);
  const preflight = { kind: "phase227_preflight", status: "passed", candidate_sha: "a".repeat(40), candidate_tree: "b".repeat(40), parent_sha: "d".repeat(40), parent_tree: "e".repeat(40), changed_files: [".github/workflows/ci.yml"], expected_state: "candidate", wrapper_sha256: `sha256:${"c".repeat(64)}`, remote_effects: "none", check_results: { node_syntax: "passed", node_tests: "passed", fixtures: "passed", workflow: "passed", accrue_format: "passed", accrue_test: "passed", prohibited_invocations: 0 } };
  assert.equal(verifyPreflightEvidence(preflight, "a".repeat(40), "candidate").remote_effects, "none");
  assert.throws(() => verifyFinalDecision([...history, budget, { kind: "gap_v3_activation", candidate_sha: "a".repeat(40), candidate_tree: "b".repeat(40), remote_effects: "enabled", preflight_evidence: { ...preflight, candidate_sha: "d".repeat(40) } }], contract), /candidate SHA differs/);
});

test("preflight wrapper has no remote-effect executable path", () => {
  const wrapper = fs.readFileSync("scripts/ci/preflight_phase227_candidate.sh", "utf8");
  assert.doesNotMatch(wrapper, /\b(?:gh|curl|wget|ssh|scp)\b|git\s+(?:push|fetch|pull|remote|ls-remote|update-ref)|workflow\s+(?:run|rerun)/, "wrapper must not contain a remote-capable command");
  assert.match(wrapper, /worktree add --detach/, "wrapper must use a detached worktree");
  assert.match(wrapper, /\^\[0-9a-f\]\{40\}\$/, "wrapper must require a full SHA");
});

test("preflight runtime sandbox records no prohibited invocation", () => {
  if (process.env.PHASE227_PREFLIGHT_NESTED === "1") return;
  const cache = process.env.PHASE227_MIX_CACHE;
  assert.ok(cache, "runtime sandbox requires the disposable PHASE227_MIX_CACHE");
  const sandbox = fs.mkdtempSync("/tmp/phase227-runtime-sandbox-");
  const bin = `${sandbox}/bin`; const log = `${sandbox}/prohibited.log`; const evidence = `${sandbox}/evidence.json`;
  fs.mkdirSync(bin);
  for (const command of ["gh", "curl", "wget", "ssh", "scp"]) fs.writeFileSync(`${bin}/${command}`, `#!/usr/bin/env bash\necho ${command}:\"$*\" >> \"$PHASE227_PROHIBITED_LOG\"\nexit 97\n`, { mode: 0o755 });
  fs.writeFileSync(`${bin}/git`, `#!/usr/bin/env bash\ncase \"$1\" in push|fetch|pull|remote|ls-remote|update-ref) echo git:\"$*\" >> \"$PHASE227_PROHIBITED_LOG\"; exit 97;; esac\nexec /usr/bin/git \"$@\"\n`, { mode: 0o755 });
  const sha = spawnSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const result = spawnSync("bash", ["scripts/ci/preflight_phase227_candidate.sh", "--commit", sha, "--expected-state", "inverse_rollback", "--evidence-out", evidence], { encoding: "utf8", env: { ...process.env, PATH: `${bin}:${process.env.PATH}`, PHASE227_MIX_CACHE: cache, PHASE227_PROHIBITED_LOG: log } });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(fs.existsSync(log) ? fs.readFileSync(log, "utf8") : "", "", "sandbox observed a prohibited invocation");
  assert.equal(JSON.parse(fs.readFileSync(evidence, "utf8")).remote_effects, "none");
});
