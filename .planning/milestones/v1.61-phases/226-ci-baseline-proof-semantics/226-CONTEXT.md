# Phase 226: CI Baseline & Proof Semantics - Context

**Gathered:** 2026-08-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish a durable, privacy-safe account of comparable CI runs that lets maintainers distinguish the measured critical path, setup ownership, and provider proof state. This phase adds evidence, semantics, diagnostics, and ownership clarity; it does not optimize CI topology, remove duplicated setup, reshape the release matrix, change branch protection, rewrite caches, demote gates, or delete/retry tests.

</domain>

<decisions>
## Implementation Decisions

### Comparable-Run Baseline
- **D-01:** Make a checked-in, versioned Phase 226 evidence pack canonical: concise Markdown for maintainers plus sanitized machine-readable JSON or NDJSON for validation and later before/after comparison. GitHub `$GITHUB_STEP_SUMMARY` output may mirror run-local facts for convenience, but it is not the durable cross-run source of truth. Raw logs, traces, screenshots, reports, payloads, and provider data remain linked GitHub Actions artifacts and are not checked into the repository.
- **D-02:** Define a comparable cohort by immutable workflow/config fingerprint, event class, normalized branch class, runner image, required-job-set and matrix fingerprint, and provider configuration class. Keep pull request, push, full `workflow_dispatch`, and scheduled provider-only runs separate. Do not mix schedule-only `live-stripe` executions into full-CI timing cohorts.
- **D-03:** Use the latest 20 successful, first-attempt, full-CI runs in a rolling 90-day window for green-path duration statistics and preserve the Phase 226 snapshot as the frozen before-state. If fewer than 20 comparable observations exist, report the exact count and `insufficient sample`; do not manufacture percentiles or mix unlike runs to fill the cohort.
- **D-04:** Exclude failed, cancelled, skipped, and rerun attempts from green-path duration percentiles, but retain them in a companion reliability table. Group attempts by original run identity and SHA so a rerun is never a second sample. Normalize one root-failure signature across repeated matrix cells rather than inflating one cause into multiple incidents.
- **D-05:** Record workflow wall time, true runner queue time, dependency/DAG wait, job and step duration, rerun count, cache hit/miss plus restore/save duration and size where available, named Docker/browser/Node/npm/Phoenix/fixture/Playwright setup costs, provider proof state, and normalized root-failure signature. Derive root-job runner queue as job start minus run creation; derive a dependent job's DAG wait from the latest prerequisite completion. Never label dependency wait as runner queueing.
- **D-06:** Keep baseline rows privacy-safe: run ID and immutable URL, truncated SHA, timestamps, event/cohort fingerprints, job/step identity, calculated durations, cache observations, provider state, conclusions, and normalized signature are allowed. Actor, raw branch name, logs, secrets or secret-presence details, provider payloads, artifact contents, and user data are excluded.
- **D-07:** Validate schema version, cohort fingerprint and exclusions, stable job and matrix identities, provider-state exhaustiveness, duration arithmetic, rerun grouping, and root-signature normalization. Include deterministic fixtures covering a successful first attempt, failure, cancellation, rerun, provider non-run/misconfiguration, and one signature repeated across matrix cells.

### Provider Proof Semantics
- **D-08:** Represent lane enforcement policy and capability evidence as independent fields. `policy` is `required` or `advisory`; `proof_state` is `proved`, `failed`, `misconfigured`, `blocked`, `skipped`, or `non_run`. `stale` is a derived freshness condition on the latest proved record, never a substitute proof state. A GitHub job conclusion remains a separate raw fact and cannot itself assert provider proof.
- **D-09:** Use `proved` only when the provider suite actually executed with all required configuration and fixtures, selected at least one required test, passed its assertions, and emitted its privacy-safe evidence manifest. A green Fake-backed suite or a GitHub `success`/`skipped` conclusion is not live-provider proof.
- **D-10:** On triggers where a provider lane is not selected, record `non_run` with explicit copy that there is no provider proof for that SHA. On scheduled/manual provider runs, absent credentials, missing fixtures, or zero selected tests is `misconfigured` and must fail the periodic lane. Executed assertion failures are `failed`; runner cancellation or upstream inability is `blocked`; an explicitly selected but intentionally bypassed execution is `skipped` with a recorded reason.
- **D-11:** Derive `stale` from the documented provider cadence plus an explicit grace window. Surface both the latest proved SHA/time and its freshness; never imply that fresh proof covers a different current SHA.
- **D-12:** Emit a redacted machine-readable proof record and an `if: always()` human summary containing trigger, SHA, policy, proof state and reason, raw job conclusion, selected/passed/skipped counts, freshness, evidence links, and one exact next action. Never emit secret values or provider payloads. Use literal state words and accessible structure rather than color alone.
- **D-13:** Preserve the existing truth boundaries: deterministic Fake-backed behavior remains the contributor-facing merge proof; Floor, Primary, and Primary plus OpenTelemetry remain required release evidence; Sigra remains explicitly advisory; Stripe parity is proved only by an actually executed successful live test-mode suite.

### Setup Ownership And Diagnostics
- **D-14:** The example host owns the declared Node and Playwright versions, `package-lock.json`, Playwright configuration, fixtures, database/seed and server lifecycle, test semantics, and canonical host proof command. CI owns runner selection, pinned Node provisioning, Linux browser/OS dependency provisioning, cache transport and observation, step timing, and retained failure artifacts. Both local and CI paths invoke the same host-owned Playwright proof contract.
- **D-15:** Local host verification preflights required tooling and returns exact installation guidance rather than hiding a missing prerequisite inside an ambiguous browser-test failure. CI provisions its environment explicitly before calling the same proof contract. Phase 226 documents and measures today's duplicate provisioning; it does not remove that work before Phase 227 selects an evidence-backed optimization.
- **D-16:** Classify setup failures with stable codes at minimum for `node_missing_or_version`, `npm_lock_or_registry`, `playwright_binary_or_revision`, `linux_browser_dependency`, `browser_launch`, `port_or_server_readiness`, and `fixture_or_database`. A diagnostic leads with what failed, the owning boundary (`host` or `CI`), one narrow next command, and the artifact/log location.
- **D-17:** Record a compact privacy-safe setup fact with owner, command identity, Node/Playwright/lockfile identity, browser revision or non-sensitive path class, cache state, duration, and classified result. Redact URLs, tokens, environment values, payloads, and application data.
- **D-18:** Preserve existing single-worker and zero-retry browser semantics where they are part of required proof, along with failure-only traces/reports/server logs and accessibility evidence. Do not add Playwright browser caching by default: measure install and restore costs first, then let Phase 227 decide with a negative control and rollback.

### Maintainer Experience And Information Design
- **D-19:** Optimize the evidence interface for the maintainer job: “When CI changes state, tell me what was and was not proved, where time went, who owns the failure, and the exact next action.” Lead every baseline/proof/setup summary with fact, state, owner, next command, then linked forensic detail.
- **D-20:** Use the current brandbook's measured, exact, proof-checkable voice. Keep Markdown scannable, literal, accessible, non-color-dependent, and consistent with the Phase 225 incident-index grammar. Hide collection mechanics and backend detail unless required to explain a fundamental evidence boundary.
- **D-21:** Treat clarity, truthfulness, privacy/security, accessibility, performance, resilience, consistency, observability, and maintainability as the design pillars. Prefer stable conventional Markdown tables and versioned records over a bespoke dashboard or product UI in this phase.

### the agent's Discretion
- The researcher and planner may choose exact filenames, JSON versus NDJSON, schema field names, signature hashing/normalization mechanics, Markdown table layout, and the provider freshness grace window, provided D-01 through D-21 remain true.
- The planner may select the exact deterministic fixture mechanism and narrow verification entrypoints. No selection may change CI topology, remove setup work, or weaken proof in Phase 226.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Locked Project Posture
- `.planning/PROJECT.md` — Stable-core posture, v1.61 goal, privacy/proof constraints, and current milestone boundary.
- `.planning/ROADMAP.md` — Phase 226 goal, dependencies, success criteria, Phase 227 boundary, and fixed CI guardrails.
- `.planning/REQUIREMENTS.md` — BASE-01, BASE-02, and OWN-01; PATH/SAFE requirements remain Phase 227 work.
- `.planning/STATE.md` — Current project state and active workflow constraints.
- `.planning/phases/225-required-lane-signal-repair/225-CONTEXT.md` — Locked incident, artifact, required/advisory, and no-masking decisions inherited by Phase 226.
- `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` — Existing privacy-safe, action-first evidence grammar and immutable repair-run examples.
- `.planning/phases/225-required-lane-signal-repair/225-03-SUMMARY.md` — Fresh SHA-bound Actions proof that establishes the immediate baseline boundary.

### Prior CI Research And Current Runtime Surfaces
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` — Measure-first decisions and provider-proof honesty constraints.
- `.planning/milestones/v1.55-phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` — Existing topology map, partial snapshot, missing metrics, cache risks, and critical-path hypothesis.
- `.github/workflows/ci.yml` — Stable job identities, matrix policy, trigger topology, provider lane, caches, setup steps, and artifact behavior.
- `scripts/ci/README.md` — Canonical maintainer gate map, narrow reproduction commands, and established triage language.
- `guides/testing-live-stripe.md` — Live Stripe setup, invocation, and provider-parity contract.
- `scripts/ci/accrue_host_uat.sh` — Host verification orchestration and phase boundaries.
- `scripts/ci/accrue_host_verify_browser.sh` — Current host-owned browser setup, fixture, server, and Playwright proof path.
- `examples/accrue_host/README.md` — Host maintainer proof and setup documentation surface.
- `examples/accrue_host/playwright.config.js` — Host browser configuration, artifact, worker, and retry semantics.
- `accrue_admin/playwright.config.js` — Admin browser configuration and retained evidence conventions.

### Architecture, Engineering, And Voice Lenses
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — Adopter-first, repository-truth-first, DX, and evidence judgment lenses.
- `prompts/accrue-best-practices-deep-research-independent.md` — Project-specific software architecture, quality, and ecosystem research lenses.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — Boundary, failure, durable-evidence, and reader mental-model guidance.
- `brandbook/voice.md` — Current authoritative calm, exact, measured voice; supersedes stale prompt-level voice references.
- `brandbook/copy.md` — Current plain-language microcopy and action-oriented documentation conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/phases/225-required-lane-signal-repair/225-CI-INCIDENTS.md` already supplies the preferred privacy-safe causal-index grammar: fact, classification, next command, immutable evidence, negative control, and residual owner.
- `.github/workflows/ci.yml` already exposes stable job IDs, required/advisory matrix metadata, named setup/cache steps, provider trigger selection, and artifact uploads that the baseline can observe without changing topology.
- `scripts/ci/README.md` already maps failures to canonical narrow commands; extend its ownership and proof-state vocabulary instead of creating a competing maintainer interface.
- Existing host and Admin Playwright reports, test-results, traces, screenshots, generated evidence, and server logs remain the raw forensic layer linked by the sanitized baseline.

### Established Patterns
- Accrue uses deterministic Fake-backed checks for contributor-facing merge proof and separately classified provider/browser evidence for claims that require those environments.
- Required-check identity and matrix support labels are public contracts. Advisory success cannot satisfy required proof, and skipped/non-run provider work cannot be described as proved.
- Host applications own runtime setup and application-domain behavior; `accrue` owns reusable billing contracts. The setup model must preserve that boundary rather than moving host tooling into the library.
- Evidence is executable, privacy-safe, action-first, and mechanism-led. Raw forensic material stays in bounded artifacts rather than planning documents.

### Integration Points
- Baseline collection and summaries attach to `.github/workflows/ci.yml` and read GitHub run/job/step metadata without changing the required job graph.
- Schema validation and deterministic negative controls belong under `scripts/ci/`, with canonical commands documented in `scripts/ci/README.md`.
- Provider proof classification connects to the `live-stripe` workflow path and `guides/testing-live-stripe.md`; release-matrix policy continues to come from `.github/workflows/ci.yml`.
- Setup ownership and diagnostics connect to `scripts/ci/accrue_host_uat.sh`, `scripts/ci/accrue_host_verify_browser.sh`, `examples/accrue_host/README.md`, and the host/Admin Playwright configuration and artifact surfaces.
- Phase-local Markdown and machine-readable baseline artifacts live under `.planning/phases/226-ci-baseline-proof-semantics/`; Phase 227 consumes the frozen snapshot when selecting one optimization.

</code_context>

<specifics>
## Specific Ideas

- Preserve Phase 225 run `31322443304` and repair SHA `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997` as the immediate fresh-run boundary, while still requiring a fingerprinted multi-run cohort for duration claims.
- The expected green critical path is roughly 33–36 minutes through staged release gate, host integration, and Playwright work rather than runner queueing; Phase 226 must either confirm this with DAG-aware measurements or record the contrary result plainly.
- Preferred summary grammar: what happened, literal proof state, owner, one exact next action, then linked evidence. No dashboard, color-only status, raw-log dump, or infrastructure jargon should be necessary for the primary maintainer flow.

</specifics>

<deferred>
## Deferred Ideas

- Remove or consolidate a measured duplicate Node/npm/browser/setup cost in Phase 227 after Phase 226 establishes before-state evidence, negative controls, and rollback expectations.
- Add Playwright browser caching only if measured restore behavior beats installation and preserves Linux dependency correctness; this is a Phase 227 decision.
- Adopt an external CI-observability vendor only if a future authorized multi-repository monitoring/alerting need justifies credentials, retention, access control, and operational ownership.
- Release-matrix reshaping, branch-protection changes, required-gate demotion, cache rewrites, test deletion/retry masking, StoreKit/iPhone/Crosswake work, and Admin UI ratchet work remain outside Phase 226.

</deferred>

---

*Phase: 226-CI-Baseline-Proof-Semantics*
*Context gathered: 2026-08-11*
