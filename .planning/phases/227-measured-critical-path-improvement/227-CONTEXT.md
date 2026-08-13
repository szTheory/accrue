# Phase 227: Measured Critical-Path Improvement - Context

**Gathered:** 2026-08-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver one measured improvement to the confirmed release-gate → host-integration → Playwright critical path by removing one unnecessary dependency edge. Preserve every required release, host, browser, provider, and failure proof; stable check and artifact identities; zero-retry semantics; and the Phase 226 evidence boundary. This phase does not collapse the release matrix, edit branch protection, demote gates, cache Playwright browsers, delete or mask tests, or broadly redesign the CI graph.

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

### the agent's Discretion
- The researcher and planner may choose the Phase 227 evidence filenames, machine-readable schema details, verifier implementation, and controlled-failure seam, provided D-01 through D-11 remain true.
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

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, and `verify_ci_baseline.mjs` already collect, render, and validate privacy-safe GitHub timing evidence. Phase 227 should extend or reuse these contracts rather than introduce an unrelated measurement system.
- The Phase 226 NDJSON corpus and schema already model run attempts, workflow fingerprints, job/step duration, DAG wait, queue delay, setup/cache facts, provider state, and exclusions needed for a before/after comparison.
- Existing CI verification scripts and `scripts/ci/README.md` provide the established pattern for an executable contract verifier plus one exact maintainer command.

### Established Patterns
- Required job/check names and release-matrix labels are externally visible contracts. Advisory Sigra remains advisory; Floor, Primary, and Primary plus OpenTelemetry remain required release evidence.
- Independent required jobs finish and retain evidence; retries, cancellation, skipped jobs, or finalizer semantics may not make a failing required proof appear repaired.
- Browser proof remains single-worker and zero-retry with retained reports, traces, screenshots, generated evidence, and server logs according to the existing lane-specific upload conditions.
- Durable evidence is sanitized and checked in; raw logs and forensic artifacts remain linked Actions artifacts.

### Integration Points
- `.github/workflows/ci.yml`: change only the `host-integration.needs` relationship, preserve `playwright-e2e.needs: [host-integration]`, and keep `annotation-sweep` dependent on release, admin, host, Playwright, Docker, and the other required/advisory lanes.
- Phase 227 evidence collection consumes the Phase 226 frozen baseline and three new first-attempt runs without mutating the before snapshot.
- The new static contract verifier connects the workflow graph to an exact manifest of check, matrix/provider, and artifact identities; its command belongs in `scripts/ci/README.md` and relevant CI proof.
- Rollback restores the original dependency relationship and reuses the same verifier and CI evidence path.

</code_context>

<specifics>
## Specific Ideas

- Before-state staged critical path: 20 compatible complete observations, p50 2,083 seconds, p95 2,602 seconds.
- Keep threshold: post-change median across three successful first attempts must be at most 1,666 seconds (at least 20% faster after integer rounding).
- The intended graph change is narrow: `host-integration` starts after `docs-contracts-shift-left`; `admin-drift-docs` continues after `release-gate`; release/admin and host/browser converge again at `annotation-sweep`.
- Preferred evidence grammar remains: current fact, literal state, owner, one exact next action, then immutable links and forensic detail.

</specifics>

<deferred>
## Deferred Ideas

- Moving duplicated static work out of release-matrix cells requires its own measured, proof-preserving change after this one-edge optimization.
- Consolidating host/browser provisioning may be considered in a later measured slice; Playwright browser caching remains disfavored unless new measurements contradict current official and Phase 226 evidence.
- Further graph changes, including parallelizing Playwright independently of host integration, require separate measurement and authorization.
- Matrix collapse, branch-protection changes, required-gate demotion, cache rewrites, test deletion/retry masking, StoreKit/iPhone/Crosswake work, and Admin UI ratchet work remain out of scope.

</deferred>

---

*Phase: 227-Measured Critical-Path Improvement*
*Context gathered: 2026-08-12*
