# Phase 225: Required-Lane Signal Repair - Context

**Gathered:** 2026-08-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore trustworthy required release and Admin CI signal by classifying every active failure from trace-backed evidence, repairing its actual cause, and leaving meaningful assertions, stable check identities, and diagnostic artifacts intact. This phase is an operational maintainer interface, not a product-UI redesign or CI-topology optimization.

</domain>

<decisions>
## Implementation Decisions

### Incident Record And Maintainer Experience
- **D-01:** Create one checked-in, human-readable phase-local incident record, `225-CI-INCIDENTS.md`, with one section per normalized failure signature—not per failed matrix cell. Each section must name an incident ID/status; normalized signature; classification and confidence; first/last run and SHA; affected required/advisory cells; canonical owner and repair surface; credential-free narrow repro; evidence/artifact links; ruled-out hypotheses; root cause; corrective change; negative-control proof; fresh repair-run evidence; and residual owner/status.
- **D-02:** Treat the incident record as the concise, durable causal index. Keep raw Playwright HTML reports, traces/test-results, screenshots, and relevant server logs as GitHub artifacts rather than checking log dumps into the repository. Keep records privacy-safe and link to immutable run/job/artifact evidence without copying secrets or user data.
- **D-03:** Preserve operational UX: lead each record and maintainer-facing entry with what failed, its precise classification, the one next command, and the evidence link. Use calm, exact, mechanism-led language; never label a failure merely "flaky" without evidence. No end-user/Admin visual work belongs in this phase.

### Shared Release-Matrix Incident
- **D-04:** Treat the identical `Accrue.Webhook.IngestTest` failures in every release-matrix cell as one **test-isolation / over-broad-observation** incident, not four compatibility incidents. The record must list every affected cell while retaining required/advisory support labels.
- **D-05:** Repair webhook tests by asserting facts owned by the event under test: `processor` + `processor_event_id` for `WebhookEvent`, the worker + `args["webhook_event_id"] == event.id` for Oban work, and the relevant ledger `type` + `subject_id`. Preserve idempotency and atomicity assertions, and add a deterministic negative control proving a duplicate for the same identity is rejected. Do not rely on global-table cardinality assumptions.
- **D-06:** Preserve release-gate job/check identity, all required cells, `fail-fast: false`, and explicitly advisory Sigra semantics. Do not resolve the incident by retries, global serialization, test deletion, matrix collapse, required-gate demotion, branch-protection edits, or cache/topology changes.
- **D-07:** Audit the test whose title claims rollback on Oban insertion failure: its current path exercises success only. Either rename it to a truthful successful-ingest co-presence/atomicity contract or add a deterministic failure seam and a real rollback test; planners must not claim rollback proof already exists.

### Admin Playwright Timeout
- **D-08:** Classify the Phase 192 Admin page-flow timeout as a trace-backed **capacity/topology versus whole-test-budget** failure, not an intermittent external/lifecycle failure. The current test performs 5 viewports × 2 themes × 21 flows (210 full login/navigate/check cycles) under one 60-second test budget; the trace reaches ordinary successful Dunning Timeline checks around 64 seconds rather than showing a stuck selector or network call.
- **D-09:** Retain all page-flow coverage but split the Cartesian traversal into bounded, independently reported Playwright tests, either per viewport or deterministic flow group. Keep CI single-worker execution, existing assertions, themes, viewports, screenshots, reports, and trace behavior. Set per-case budgets from observed timings; increase a timeout only when one coherent scenario needs it.
- **D-10:** Keep retries at zero for this required lane. A retry may help later diagnosis only when it records a flaky outcome and retains first-failure evidence; it must never make a required lane appear repaired. Prefer deterministic readiness/fixture/lifecycle boundaries and semantic user-facing locators over sleeps or global timeout inflation.
- **D-11:** Preserve useful Admin artifacts. Existing Phase 192 `if: always()` Playwright report and test-results uploads are a required trace-first affordance. Repair or explicitly replace the currently missing Phase 192 generated-evidence upload path before describing that generated evidence as available.

### Proof And Completion Bar
- **D-12:** Completion requires each active red signature to map to exactly one classified incident record; a targeted reproduction and relevant negative control; full local suite evidence; and a fresh repair-commit Actions run—not merely a rerun—where every required release cell and the required Admin job pass while their assertions, check identity, matrix topology, and artifacts remain available.
- **D-13:** Required and advisory evidence must remain visibly distinct in the incident record and CI proof. The three required release cells prove repair; Sigra remains `[advisory]` and cannot be represented as required release proof.

### the agent's Discretion
- The researcher and planner may choose the record's exact Markdown layout, stable incident IDs, artifact retention duration, and deterministic test partitioning, provided every D-01 through D-13 constraint holds.
- The planner may choose whether the misleading rollback test is truthfully renamed or backed by a new deterministic failure seam after code inspection; either path must state the actual proven behavior.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Project Guardrails
- `.planning/PROJECT.md` — Stable-core posture, v1.61 goal, live-history context, and non-goals.
- `.planning/ROADMAP.md` — Phase 225 goal, REL-01..03 success criteria, and fixed CI guardrails.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, and REL-03 requirements and out-of-scope constraints.
- `.planning/STATE.md` — Current phase state and binding no-mask/no-topology-change rules.
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` — Locked prior CI/DX decisions, especially measure-first and proof-honesty stance.
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` — Existing CI topology/audit findings and deferred optimization boundary.

### Current Failure Evidence And CI Surfaces
- `.github/workflows/ci.yml` — Stable job identities, release matrix support semantics, Admin Phase 192 artifacts, and required downstream gates.
- `accrue/test/accrue/webhook/ingest_test.exs` — Shared release-matrix failure assertions requiring identity-scoped repair.
- `accrue/test/support/repo_case.ex` — Ecto SQL-sandbox isolation boundary.
- `accrue/lib/accrue/webhook/ingest.ex` — Webhook ingestion behavior whose idempotency/atomicity must remain tested.
- `accrue_admin/playwright.config.js` — Existing CI browser stability, timeout, trace, and project configuration.
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` — Timed page-flow traversal that must be partitioned without coverage loss.
- `accrue_admin/e2e/phase191-page-flow-helpers.js` — Viewport/flow topology feeding the page-flow test.
- `scripts/ci/verify_phase192_admin_guardrails.sh` — Canonical Admin Phase 192 CI entrypoint.
- `scripts/ci/README.md` — Maintainer triage language and reproducible gate-command map.

### Prompt, Architecture, And Voice Guidance
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — Adopter-first, repo-truth-first, subagent research, and DX judgment lenses.
- `prompts/accrue-best-practices-deep-research-independent.md` — Project-specific engineering and quality research input.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — Clear boundary, failure, durable-evidence, and reader-mental-model guidance.
- `prompts/accrue_admin_operator_ui_journey_blueprint.md` — Applicable operator-diagnostic clarity principles; no Admin redesign is authorized.
- `brandbook/voice.md` — Authoritative measured, exact, native, durable, proof-checkable voice.
- `brandbook/copy.md` — Plain-language microcopy conventions for maintainer-facing documentation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml` already keeps stable release-gate identity, a visible required/advisory matrix, `fail-fast: false`, Phase 192 always-uploaded evidence, and failure-artifact patterns that Phase 225 must preserve.
- `scripts/ci/README.md` already provides canonical narrow commands and a "fix the named canonical surface first" triage model; extend rather than invent a competing interface.
- `Accrue.RepoCase` provides SQL-sandbox isolation; affected tests must make assertions specific to their own event instead of assuming all tables are globally empty.
- Current Admin Playwright report/test-results artifacts provide the trace-first evidence basis; the implementation should retain and link them rather than replace them with retry behavior.

### Established Patterns
- Accrue distinguishes required proof from advisory capability explicitly; changes must preserve that honest support vocabulary.
- The project favors deterministic Fake-backed and credential-free proof as the contributor-facing path, with explicit evidence for anything provider/browser-specific.
- Phase 192 already uses `if: always()` for selected browser evidence; host browser jobs use failure-only reports/traces/server logs. Artifact choice must remain targeted and explainable.

### Integration Points
- The implementation will connect test assertions under `accrue/test/accrue/webhook/`, Playwright page-flow tests under `accrue_admin/e2e/`, CI artifact wiring in `.github/workflows/ci.yml`, maintainer triage documentation in `scripts/ci/README.md`, and the new phase-local incident record.
- Phase 226 owns comparable-run baselines, provider-proof semantics expansion, and setup ownership; Phase 227 owns measured critical-path optimization. Phase 225 may not pull those changes forward.

</code_context>

<specifics>
## Specific Ideas

- Current run evidence: `31289155535` shows the same three webhook global-count failures in all four release cells, including three required cells and advisory Sigra. Earlier runs `31287555136` and `31288699712` document already-narrowed stale-contract failures and the recurring signature.
- Admin Phase 192 trace evidence from the same run shows 13 passed / 1 failed after roughly 2.4 minutes, with the timed traversal continuing normally through about 64 seconds; the relevant failure is the single-test budget against 210 serial journey checks, not a proved browser/network stall.
- Maintain an incident-response UX for on-call maintainers, reviewers, and contributors: concise diagnostic first, one exact next action, then linked forensic detail. Markdown must remain scannable and use literal links/statuses rather than color-only meaning.

</specifics>

<deferred>
## Deferred Ideas

- Comparable-run duration/cache/rerun baseline, provider proved/skipped/advisory reporting expansion, and host/browser setup ownership documentation belong to Phase 226.
- Matrix reshaping, required-check or branch-protection changes, cache rewrites, and critical-path optimization belong to Phase 227 after baseline and negative-control evidence.
- Admin UI ratchet recovery or redesign, StoreKit/iPhone/Crosswake work, and any end-user visual change remain out of scope.

</deferred>

---

*Phase: 225-Required-Lane Signal Repair*
*Context gathered: 2026-08-08*
