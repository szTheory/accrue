# Phase 227: Measured Critical-Path Improvement - Context

**Gathered:** 2026-08-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver one measured improvement to the confirmed release-gate → host-integration → Playwright critical path by removing one unnecessary dependency edge. The first candidate attempt produced nine visible exclusions and zero admissible timing observations because the manual trigger coupled full-CI measurement to unavailable live-Stripe proof. Restore the known graph first, then permit one final, preflighted three-run experiment whose trigger intent, proof vector, budget, and rollback states are explicit. Preserve every required release, host, browser, provider, and failure proof; stable check and artifact identities; zero-retry semantics; and the Phase 226 evidence boundary. This phase does not collapse the release matrix, edit branch protection, demote gates, cache Playwright browsers, delete or mask tests, create a second performance workflow, or broadly redesign the CI graph.

</domain>

<decisions>
## Implementation Decisions

### Optimization Target And Dependency Boundary
- **D-01:** Optimize dependency ordering first. Change `host-integration` so its only upstream required prerequisite is `docs-contracts-shift-left`; it must no longer wait indirectly for `release-gate` through `admin-drift-docs`.
- **D-02:** Keep release/admin proof and host/browser proof as independent required work that runs to completion even when another independent lane fails. `annotation-sweep` remains the final required fan-in and must continue to report the aggregate failure.
- **D-03:** Make this a one-edge optimization. Preserve the `host-integration → playwright-e2e` dependency and every other graph edge unless a later measured phase authorizes another change.

### Before/After Proof Bar
- **D-04:** Require three successful, first-attempt, same-event-class post-change runs. Compare them with the frozen compatible Phase 226 before cohort, retain every individual observation, and report the exact workflow fingerprint, sample count, range, and exclusions. Reruns are reliability evidence, not independent performance samples.
- **D-05:** Use staged critical-path duration—`release-gate` start through the latest `playwright-e2e` shard completion—as the primary success metric. Report removed `host-integration` DAG wait as causal evidence and whole-workflow wall time as supporting context.
- **D-06:** Keep the optimization only if the three-run post-change median is at least 20% faster than the Phase 226 before median of 2,083 seconds (a post-change median of at most 1,666 seconds after integer rounding). No post-change observation may exceed the Phase 226 p95 of 2,602 seconds unless the evidence pack identifies and substantiates an external anomaly.
- **D-07:** Preserve the Phase 226 baseline unchanged. Publish a separate Phase 227 evidence pack with concise maintainer-facing Markdown and sanitized machine-readable comparison records containing immutable run links, workflow/cohort fingerprints, individual measurements, exclusions, calculations, proof results, and rollback evidence.

### Negative Control, Stable Contracts, And Rollback
- **D-08:** Supply two complementary negative controls: (1) a deterministic repository verifier that asserts the intended graph and external evidence contract, and (2) a controlled failing fixture or Actions run proving `annotation-sweep` fails while independent host/browser work completes and retains its failure or success artifacts.
- **D-09:** Guard an exact contract manifest covering required job IDs and display names, release-matrix compatibility/support labels, provider policy/proof labels, artifact names, upload conditions, and retention. Explicitly additive Phase 227 evidence is allowed; removal, rename, weakening, or silent substitution is not.
- **D-10:** Trigger rollback if any required identity, artifact, proof state, or failure propagation changes; a negative control fails; a new deterministic failure appears; or the three-run median misses the 20% improvement bar.
- **D-11:** Rollback is the exact inverse dependency patch restoring the original `host-integration` edge, followed by the static/negative-control verifier and a fresh successful first-attempt CI run demonstrating that the prior graph and evidence contract are restored. Do not add a lasting feature switch for this single YAML edge.

### Candidate Trigger Contract
- **D-12:** Apply the D-11 exact inverse immediately and verify the restored graph before redesigning or launching more candidate measurements. Nine retained `workflow_dispatch` exclusions and zero admissible observations are insufficient evidence; the optimized edge must not remain active while its measurement contract is replanned.
- **D-13:** Keep the existing `CI` workflow and `workflow_dispatch` event. Add one explicit Boolean `run_live_stripe` input: it is required, defaults to `true` to preserve current manual behavior, and gates only the `live-stripe` job for manual runs. Scheduled provider proof remains unchanged. Phase 227 measurement runs explicitly pass `run_live_stripe: false` and record live-Stripe proof for that SHA as `non_run`; workflow success must never imply provider proof.
- **D-14:** Do not use pull-request close/reopen activity, no-op commits, reruns, or a second performance-only workflow to manufacture repeatable observations. The explicit dispatch input is the least-surprising maintainer contract and its value is part of the workflow/cohort fingerprint.

### Observation Admission And Proof Vector
- **D-15:** A post-change observation is admissible only when the raw GitHub workflow conclusion is `success` **and** a repository-bound proof vector is complete for the registered measurement topology. A green workflow conclusion alone is not job-presence, artifact, provider, or required-proof evidence.
- **D-16:** The vector must bind the exact candidate SHA, first attempt, `workflow_dispatch` event, `run_live_stripe: false`, workflow/cohort fingerprints, required job and matrix identities, and immutable run/job links. It must prove successful Floor, Primary, and Primary plus OpenTelemetry release cells; docs contracts; every required Admin lane; host integration; all three Playwright shards; Docker smoke; and `annotation-sweep`, plus the contractually expected artifact presence or documented conditional absence.
- **D-17:** Advisory Sigra and the parked Admin ratchet remain visibly advisory and retain their literal outcomes. Live Stripe is explicitly `non_run` for measurement dispatches, with the latest independent scheduled/manual provider proof linked separately. Any missing, skipped, renamed, weakened, or differently conditioned required proof is an exclusion and rollback trigger, never a substitute sample.

### Final Run Budget And Failure Classification
- **D-18:** Retain all nine existing failed candidate runs and the earlier inadmissible control as immutable exclusions. After rollback verification and trigger/proof-vector preflight, authorize one final cohort of exactly three independent candidate first attempts at one exact SHA, event class, and input topology. This is the remaining Phase 227 performance-run budget; do not launch replacement cohorts.
- **D-19:** Reruns are diagnosis and reliability evidence only. Cancelled, skipped, failed, incompatible, blocked, or slow observations remain visible with their original run identity and attempt number; none may be silently replaced or promoted into the timing cohort.
- **D-20:** Classify each non-qualifying run from repository-bound facts as `candidate_regression`, `deterministic_required_lane_failure`, `external_or_runner_blocked`, or `inconclusive`. Use `candidate_regression` only for a reproducible graph, identity, artifact, proof, or failure-propagation regression. Use `external_or_runner_blocked` only with observation-specific GitHub status/incident or explicit runner/infrastructure evidence. Ordinary variance, a green rerun, and unexplained failure are not external anomalies.

### Rollback State And Final Decision
- **D-21:** Any non-qualifying outcome in the final three-run cohort, fewer than three successful compatible first attempts, a missed D-06 timing predicate, or any safety/negative-control regression immediately triggers the D-11 inverse. Do not keep sampling until three green runs appear and do not leave the candidate edge active while investigating.
- **D-22:** Report rollback in three literal stages: `rollback_applied` means the inverse patch and local static, negative-control, and inherited preservation checks pass; `rollback_verified` additionally requires one fresh successful first-attempt normal CI run with immutable job and artifact evidence; `rollback_applied_unverified` means the inverse is present but external proof is blocked. Only `rollback_verified` is a completed rollback.
- **D-23:** Every maintainer-facing report begins with current fact, literal state, owner, and one exact next command. Follow with the decision threshold, immutable observations or evidence gap, required/advisory/provider proof vector, exclusions and classifications, negative-control result, and rollback evidence. Keep Markdown plus sanitized NDJSON as the interface; this phase does not warrant a dashboard or end-user UI.

### the agent's Discretion
- The researcher and planner may choose machine-readable schema details, exact preflight command composition, verifier implementation, and controlled-failure seam, provided D-01 through D-23 remain true.
- They may define a narrow, evidence-based rule for substantiating an external timing anomaly. Runner variance alone is not enough to discard a post-change observation silently; all exclusions must remain visible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Locked Project Posture
- `.planning/PROJECT.md` — Stable-core posture, v1.61 milestone goal, current critical-path ownership, and proof-preservation guardrails.
- `.planning/ROADMAP.md` — Phase 227 goal, PATH-01/PATH-02/SAFE-01/SAFE-02 success criteria, dependency on Phase 226, and fixed phase boundary.
- `.planning/REQUIREMENTS.md` — Critical-path, stable-check, negative-control, and rollback requirements plus explicit non-goals.
- `.planning/STATE.md` — Current milestone state and binding workflow constraints.
- `.planning/phases/225-required-lane-signal-repair/225-CONTEXT.md` — Required/advisory identity, zero-retry, artifact, incident, and no-masking decisions inherited by this phase.

### Frozen Before-State Evidence
- `.planning/phases/226-ci-baseline-proof-semantics/226-CONTEXT.md` — Locked comparable-run, critical-path, setup-ownership, provider-proof, and evidence-interface decisions.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — Frozen human-readable before-state: confirmed staged path, p50 2,083s, p95 2,602s, individual immutable run links, DAG waits, setup costs, cache facts, provider states, and exclusions.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` — Sanitized machine-readable before observations used for Phase 227 calculations.
- `.planning/phases/226-ci-baseline-proof-semantics/schema-v1.json` — Phase 226 evidence schema and validation boundary.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VERIFICATION.md` — Executed proof for baseline accuracy, provider semantics, setup diagnostics, and required evidence preservation.
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` — Measure-first CI optimization decisions and proof-honesty constraints.
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` — Original topology analysis, duplicated-work candidates, validation expectations, and rollback requirements.

### Executed Phase 227 Evidence And Replanning Inputs
- `.planning/phases/227-measured-critical-path-improvement/227-01-SUMMARY.md` — Implemented one-edge candidate, executable workflow contract, and inverse fixture.
- `.planning/phases/227-measured-critical-path-improvement/227-02-SUMMARY.md` — Live evidence attempt, nine excluded candidate runs, admissible negative control, and the zero-sample blocker that requires replanning.
- `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md` — Current human-readable insufficient-evidence and rollback-required state.
- `.planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson` — Immutable negative-control, exclusion, and pending-decision records that must remain visible.
- `.planning/phases/227-measured-critical-path-improvement/227-ci-contract.json` — Current graph, identity, artifact, frozen-input, inverse, and timing-threshold manifest to extend for trigger inputs and the proof vector.
- `.planning/phases/227-measured-critical-path-improvement/227-RESEARCH.md` — Existing implementation research, failure-propagation rules, evidence design, and anomaly standard.
- `.planning/phases/227-measured-critical-path-improvement/227-PATTERNS.md` — Repository-native workflow, verifier, evidence, and maintainer-documentation patterns.

### CI Graph, Evidence, And Host/Browser Surfaces
- `.github/workflows/ci.yml` — Canonical job IDs/display names, `needs` graph, release matrix policy, final annotation fan-in, and artifact upload contracts.
- `scripts/ci/collect_ci_baseline.mjs` — Existing GitHub run/job/step collection and comparison input path.
- `scripts/ci/render_ci_baseline.mjs` — Existing human-readable timing, critical-path, setup/cache, provider, and reliability rendering patterns.
- `scripts/ci/verify_ci_baseline.mjs` — Existing deterministic evidence validation and repository trust-binding patterns.
- `scripts/ci/README.md` — Canonical maintainer commands, evidence grammar, ownership diagnostics, and narrow triage flow.
- `scripts/ci/accrue_host_uat.sh` — Host proof orchestration boundary used by `host-integration`.
- `scripts/ci/accrue_host_verify_browser.sh` — Host-owned browser setup, fixture, server, Playwright, and artifact behavior that must remain intact.
- `examples/accrue_host/playwright.config.js` — Host browser worker, retry, trace, screenshot, and report semantics.
- `accrue_admin/playwright.config.js` — Admin browser evidence and zero-retry conventions.

### Project Judgment, Maintainer UX, And Voice
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — Repo-truth-first, proof-honest, DX/least-surprise, cross-ecosystem judgment lens requested for the recommendation.
- `prompts/GSD-REPO-HYGIENE.md` — Project policy that push CI and periodic/manual provider proof are verified separately and reported with exact run conclusions.
- `brandbook/voice.md` — Current authoritative measured, exact, native, durable voice and proof-checkable claims posture; supersedes older prompt wording where they conflict.
- `brandbook/copy.md` — Current literal next-action and precise maintainer-copy patterns.

### Primary External Semantics
- `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow` — Typed `workflow_dispatch` inputs and Boolean input semantics.
- `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions` — Skipped-job behavior and why a green workflow cannot replace a complete proof vector.
- `https://docs.github.com/en/actions/reference/workflows-and-actions/expressions` — `success`, `failure`, `cancelled`, and `always` status behavior.
- `https://docs.github.com/en/actions/how-tos/manage-workflow-runs` — Workflow reruns as later attempts rather than independent observations.
- `https://sre.google/workbook/canarying-releases/` — Bounded canary evaluation, declared criteria, and known rollback posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, and `verify_ci_baseline.mjs` already collect, render, and validate privacy-safe GitHub timing evidence. Phase 227 should extend or reuse these contracts rather than introduce an unrelated measurement system.
- The Phase 226 NDJSON corpus and schema already model run attempts, workflow fingerprints, job/step duration, DAG wait, queue delay, setup/cache facts, provider state, and exclusions needed for a before/after comparison.
- Existing CI verification scripts and `scripts/ci/README.md` provide the established pattern for an executable contract verifier plus one exact maintainer command.
- `scripts/ci/verify_ci_critical_path.mjs`, `227-ci-contract.json`, and the Phase 227 fixture corpus already enforce the candidate/inverse graph, immutable live evidence, timing predicates, and negative control. Extend this contract rather than introduce another measurement path.
- The current Phase 227 Markdown/NDJSON pair already retains every failed run and the admissible negative control; it should evolve from `decision_pending` to explicit rollback/candidate/keep state without rewriting history.

### Established Patterns
- Required job/check names and release-matrix labels are externally visible contracts. Advisory Sigra remains advisory; Floor, Primary, and Primary plus OpenTelemetry remain required release evidence.
- Independent required jobs finish and retain evidence; retries, cancellation, skipped jobs, or finalizer semantics may not make a failing required proof appear repaired.
- Browser proof remains single-worker and zero-retry with retained reports, traces, screenshots, generated evidence, and server logs according to the existing lane-specific upload conditions.
- Durable evidence is sanitized and checked in; raw logs and forensic artifacts remain linked Actions artifacts.
- Raw GitHub conclusion, Accrue required-proof result, provider proof state, and rollback state are separate facts. None may be inferred from another.
- Maintainer evidence follows the current brand grammar: measured, exact, native, and durable; lead with fact, state, owner, and one next command before forensic detail.

### Integration Points
- `.github/workflows/ci.yml`: change only the `host-integration.needs` relationship, preserve `playwright-e2e.needs: [host-integration]`, and keep `annotation-sweep` dependent on release, admin, host, Playwright, Docker, and the other required/advisory lanes.
- Phase 227 evidence collection consumes the Phase 226 frozen baseline and three new first-attempt runs without mutating the before snapshot.
- The new static contract verifier connects the workflow graph to an exact manifest of check, matrix/provider, and artifact identities; its command belongs in `scripts/ci/README.md` and relevant CI proof.
- Rollback restores the original dependency relationship and reuses the same verifier and CI evidence path.
- `.github/workflows/ci.yml`: add the typed `run_live_stripe` dispatch input without changing scheduled provider behavior or any stable job/check identity; measurement uses the explicit false value.
- `scripts/ci/verify_ci_critical_path.mjs`: verify input topology, the complete required/advisory/provider proof vector, the final three-run budget, failure classification, and staged rollback truth.
- `scripts/ci/README.md`: document one exact rollback/preflight/dispatch/verification sequence and explain that measurement success does not provide live-provider proof.

</code_context>

<specifics>
## Specific Ideas

- Before-state staged critical path: 20 compatible complete observations, p50 2,083 seconds, p95 2,602 seconds.
- Keep threshold: post-change median across three successful first attempts must be at most 1,666 seconds (at least 20% faster after integer rounding).
- The intended graph change is narrow: `host-integration` starts after `docs-contracts-shift-left`; `admin-drift-docs` continues after `release-gate`; release/admin and host/browser converge again at `annotation-sweep`.
- Preferred evidence grammar remains: current fact, literal state, owner, one exact next action, then immutable links and forensic detail.
- Recommended measurement launch shape: `gh workflow run ci.yml --ref <candidate-sha> -f run_live_stripe=false`; the final plan must substitute and record the exact immutable candidate ref/SHA.
- The nine existing candidate failures are a trigger-contract failure and insufficient-evidence record, not a measured speed regression. Do not claim the one-edge change caused them without reproducible evidence.

</specifics>

<deferred>
## Deferred Ideas

- Moving duplicated static work out of release-matrix cells requires its own measured, proof-preserving change after this one-edge optimization.
- Consolidating host/browser provisioning may be considered in a later measured slice; Playwright browser caching remains disfavored unless new measurements contradict current official and Phase 226 evidence.
- Further graph changes, including parallelizing Playwright independently of host integration, require separate measurement and authorization.
- A separate performance-only workflow may be considered in a future observability phase if repeated experiments justify the maintenance and drift cost; it is not warranted for this one-edge phase.
- Matrix collapse, branch-protection changes, required-gate demotion, cache rewrites, test deletion/retry masking, StoreKit/iPhone/Crosswake work, and Admin UI ratchet work remain out of scope.

</deferred>

---

*Phase: 227-Measured Critical-Path Improvement*
*Context gathered: 2026-08-13*
