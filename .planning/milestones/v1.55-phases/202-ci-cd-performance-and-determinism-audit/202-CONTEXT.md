# Phase 202: ci-cd-performance-and-determinism-audit - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 202 produces `202-CI-CD-PERFORMANCE-AUDIT.md`: an evidence-backed audit of Accrue's GitHub Actions workflow topology, static critical path, measurement needs, bottlenecks, flaky/determinism risks, cache risks, provider-lane truth, release-lane risks, and target pipeline recommendations.

This phase is audit-only. It must not change CI workflow topology, branch protection, package release automation, runtime behavior, public APIs, DB defaults, UI implementation, or required-check semantics. It may inspect local CI configuration, cite repo evidence, optionally collect read-only GitHub Actions run-history data when available, and identify follow-up hardening work for Phase 204.

</domain>

<decisions>
## Implementation Decisions

### Research And Recommendation Method
- **D-01:** Discuss all four phase-gray areas as one coherent decision set: measurement boundary, recommendation stance, provider/determinism truth, and Phase 204 handoff shape.
- **D-02:** Use specialist research and local repo evidence to make one-shot recommendations. The user explicitly prefers not to review every tradeoff manually; downstream agents should treat the captured recommendations as locked unless new repo evidence contradicts them.
- **D-03:** Use Accrue's committed voice: measured, exact, Phoenix-native, durable, mechanism-led, and proof-checkable. Call out real CI risk plainly, but avoid hype, generic "best practice" claims, and public shaming.

### Measurement Boundary
- **D-04:** Phase 202 is **static-first and audit-only**. Static workflow/config/script inspection is sufficient to complete the phase when live run-history data is unavailable.
- **D-05:** The audit may include an **opportunistic read-only GitHub Actions run-history snapshot** when `gh` access is available. If collected, label it with collection date, branch/filter, run count, and whether it is partial. Do not treat a small snapshot as exhaustive p50/p95 truth.
- **D-06:** Missing or incomplete live metrics do **not** block Phase 202. Uncollected p50/p95 job duration, step timings, cache-hit state, flake/rerun rate, slowest tests, compile profile, Docker cold/warm duration, and provider proved-vs-skipped counts must stay in `Baseline Metrics Needed`.
- **D-07:** Dynamic claims need explicit labels. The audit can say static inspection suggests duplication, cache risk, or likely critical-path drag; it must not claim measured runtime savings, cache hit rates, or flake rates without collected evidence.

### Audit Stance And Target Pipeline Shape
- **D-08:** Be **blunt but measure-first**. Name duplicated CI work, skip-capable "mandatory" lanes, and release recovery order dependence as release-confidence debt, not just runtime cost.
- **D-09:** Do **not** recommend deleting, demoting, or making required gates optional from static inspection alone. First collect job duration, step timing, cache-hit state, flake/rerun rate, and proved-vs-skipped provider counts.
- **D-10:** Target pipeline recommendations should preserve high-value gates: docs/contracts, release manifest checks, core/admin/portal package gates, host deterministic proof, provider-parity truth, and release proof.
- **D-11:** The target pipeline shape should be: docs/contracts and release manifest stay PR-blocking; package lint/docs/audit/dialyzer run once on the primary cell; compatibility matrix cells run compile/test only where they prove supported Elixir/OTP/provider promises; host integration stays PR-blocking with one browser setup owner; Playwright keeps one PR browser proof and moves duplicate full-suite coverage to the sharded lane or main/schedule based on metrics; Docker smoke becomes path-aware or main-only if run data confirms a long tail; annotation sweep remains release-facing but must justify its critical-path cost.
- **D-12:** Release recovery should replace human package-order prose with machine preflight checks before downstream package publish. Phase 202 should recommend this as follow-up only; implementation belongs to a later hardening slice if Phase 204 ranks it.

### Provider And Determinism Truth
- **D-13:** Provider parity truth is binary: classify live provider lanes as **proved** only when CI actually runs against Stripe test mode with required secrets/fixtures. Missing secrets/fixtures must be classified as **skipped/not proved**, not green parity.
- **D-14:** Future CI work should either fail scheduled `live-stripe` early when required secrets/fixtures are absent, or rename it as advisory/skip-capable. The audit should present both paths and recommend choosing based on whether maintainers can guarantee Stripe test-mode credentials and fixtures.
- **D-15:** Fake-backed deterministic tests remain the merge-blocking default. Live Stripe belongs as a periodic/manual provider canary for API drift and provider-specific behavior, not as the primary contributor loop.
- **D-16:** Required matrix cells must materially change dependency, compile, or test behavior. Sigra remains advisory until resolvable; OpenTelemetry is required only if with/without cells prove distinct code paths. Label-only matrix cells should be renamed or redesigned.
- **D-17:** Cache, flake, and runtime claims must stay separated as static risk versus measured baseline. Cache recommendations should consider GitHub cache behavior and Playwright's guidance that browser-binary caching is often not worth it on Linux unless measured.

### Phase 204 Handoff Shape
- **D-18:** Optimize for both maintainer readability and Phase 204 consumption. Keep the CI/CD audit as a readable evidence-backed report, then end with a structured `Phase 204 Handoff` table.
- **D-19:** Each Phase 204 handoff row must include: area, evidence path, current risk, priority local to Phase 202, expected impact, tradeoff, implementation approach, verification, rollback, metric-needed status, and suggested milestone-slice fit.
- **D-20:** Phase 202 priorities are local CI/CD audit priorities, not final cross-audit roadmap ranking. Phase 204 decides final ordering after consuming Phases 201, 202, and 203.
- **D-21:** Avoid issue-ready implementation cards in Phase 202. The audit may outline patch strategy, but should not create implementation commitments before Phase 204 ranks cross-quality work.

### Developer Experience And JTBD Lens
- **D-22:** Treat UI/UX here as developer experience. The CI audit should serve the maintainer/reviewer/contributor jobs: "what failed?", "what does this gate prove?", "what should I run locally?", "is this provider parity actually proved?", and "what is safe to optimize later?"
- **D-23:** Prefer a small number of named, proof-checkable gates whose failures map to clear owners over many repeated matrix failures that all say the same thing. Hide CI internals from casual contributors where possible; expose exact mechanisms to maintainers.
- **D-24:** Keep the audit coherent with Accrue's stable-core posture: optimize proof honesty, release confidence, maintainer speed, and adopter trust. Do not use CI cleanup as a pretext for broad product behavior, UI, API, or schema work.

### Claude's Discretion
- The planner/researcher may choose the exact table layout and section ordering as long as D-01 through D-24 hold.
- The planner/researcher may collect a bounded read-only `gh` snapshot if credentials are already available; if not, continue with static evidence and keep the metric gaps explicit.
- The planner/researcher may tune wording to match `brandbook/voice.md`, but must not soften concrete risks into vague language.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/PROJECT.md` - Stable-core posture, v1.55 audit-only milestone rationale, and current project vision.
- `.planning/ROADMAP.md` - Phase 202 boundary, success criteria, dependency shape, and audit-only non-goals.
- `.planning/REQUIREMENTS.md` - CI-01..CI-05 and RD-01..RD-04 requirements and traceability.
- `.planning/STATE.md` - Current v1.55 state, known CI issue, deferred items, and standing intake rules.
- `.planning/phases/201-software-quality-evaluation/201-CONTEXT.md` - Phase 201 decisions, especially evidence boundaries and CI/DB handoff split.
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` - Cross-quality audit that identifies CI/CD as the weakest dimension and feeds Phase 204.

### Phase Artifacts
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` - Draft audit baseline to refine into final Phase 202 output.
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` - Downstream integration target for ranked hardening work.

### CI And Release Topology
- `.github/workflows/ci.yml` - Primary CI topology, job IDs, required-check comments, release-gate matrix, host integration, Playwright shards, Docker smoke, annotation sweep, and live-Stripe lane.
- `.github/workflows/accrue_admin_browser.yml` - Standalone admin browser UAT workflow.
- `.github/workflows/accrue_host_uat.yml` - Manual host UAT workflow and older setup patterns.
- `.github/workflows/accrue_admin_assets.yml` - Manual admin asset freshness workflow.
- `.github/workflows/release-please.yml` - Primary ordered release and linked release proof workflow.
- `.github/workflows/publish-hex.yml` - Manual recovery publish workflow with current human package-order prose.
- `.github/workflows/release-pr-automation.yml` - Release PR automation surface.

### CI Scripts And Local Gates
- `scripts/ci/README.md` - Maintainer-facing script/gate map and triage surface.
- `scripts/ci/watch_ci.sh` - Existing GitHub Actions watch helper.
- `scripts/ci/accrue_host_uat.sh` - Host-integration entrypoint delegating to `mix verify.full`.
- `scripts/ci/accrue_host_verify_browser.sh` - Host browser verification and browser install behavior.
- `scripts/ci/accrue_host_seed_e2e.exs` - Deterministic host E2E seed fixture.
- `scripts/ci/annotation_sweep.sh` - Release-facing annotation sweep.
- `scripts/ci/compile_matrix.sh` - Sigra compile-matrix intent and current advisory semantics.
- `scripts/ci/verify_release_contract.sh` - Linked release contract check.
- `scripts/ci/verify_release_manifest_alignment.sh` - Release manifest/package version alignment check.
- `scripts/ci/capture_linked_release_proof.sh` - Linked release proof capture.
- `scripts/ci/accrue_host_hex_smoke.sh` - Host Hex smoke proof.

### Elixir, Provider, And Test Surfaces
- `accrue/mix.exs` - Core package aliases, optional deps, `test.live`, package metadata, and docs configuration.
- `accrue/config/runtime.exs` - Live-Stripe test-mode runtime switch.
- `accrue/test/live_stripe/` - Live Stripe provider parity tests and skip behavior.
- `accrue/test/accrue/telemetry/otel_test.exs` - OpenTelemetry matrix behavior evidence.
- `examples/accrue_host/mix.exs` - Host `verify` and `verify.full` aliases.
- `examples/accrue_host/package.json` - Host Playwright install/test scripts.
- `accrue_admin/package.json` - Admin Playwright install/test scripts.

### Project Vision, Brand, And Prompt Research
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - Adopter-first quality lens, subagent research preference, idiomatic Elixir/Phoenix/DX tradeoff framing.
- `prompts/accrue-brand-book.md` - Historical brand/positioning research; superseded by committed brandbook where they differ.
- `brandbook/voice.md` - Authoritative voice system: measured, exact, native, durable, proof-checkable.
- `brandbook/README.md` - Current brand asset contract and determinism gate posture.

### Reviewed Todos
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` - Reviewed as UI/admin cleanup, not folded into Phase 202.
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` - Reviewed as future portal/UI work, not folded into Phase 202.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `202-CI-CD-PERFORMANCE-AUDIT.md`: seeded audit baseline already contains current pipeline map, baseline metrics needed, findings by category, prioritized recommendations, target pipeline, patch strategy, validation plan, and assumptions.
- `.github/workflows/ci.yml`: authoritative static source for workflow/job topology, matrix shape, required-check comments, cache patterns, service usage, critical-path dependencies, provider lane semantics, and browser/Docker setup repetition.
- `scripts/ci/README.md`: existing maintainer triage map; use it to keep recommendations grounded in how maintainers already navigate failures.
- `scripts/ci/watch_ci.sh` plus GitHub Actions REST/CLI access: candidate read-only mechanism for opportunistic run-history snapshot, if authenticated.
- Mix aliases in `accrue/mix.exs` and `examples/accrue_host/mix.exs`: existing idiomatic local proof entrypoints that should remain clear in any target pipeline recommendation.

### Established Patterns
- Accrue favors proof-led claims. CI recommendations should name the mechanism: `Fake processor`, `merge-blocking CI`, `host-integration`, `live-stripe`, `release-gate`, `docs-contracts-shift-left`, and `linked release proof`.
- Current CI already distinguishes required versus advisory matrix cells via `continue-on-error` and display-name labeling; the audit should tighten whether those labels correspond to proved behavior.
- The project accepts long-running proof where it reduces adopter/release risk, but v1.55's purpose is to identify weakest quality dimensions and rank follow-up hardening, not optimize prematurely.
- Elixir/Phoenix library CI idiom favors explicit OTP/Elixir compatibility cells, primary/latest lanes for lint/docs/static work, deterministic ExUnit/Fake-backed proof as the contributor loop, and live provider canaries outside the default unit loop.

### Integration Points
- Phase 202 output feeds Phase 204. Recommendations must be sortable and traceable without forcing Phase 204 to re-mine prose.
- Any future CI implementation will likely touch `.github/workflows/ci.yml`, `scripts/ci/*`, branch protection settings, and possibly docs describing proof paths. Phase 202 should recommend but not implement.
- Release recovery hardening will likely touch `.github/workflows/publish-hex.yml` and Hex/version preflight scripts. Phase 202 should classify risk and rollback approach, not change publish behavior.
- Provider-truth hardening will likely touch `live-stripe`, docs, and perhaps test summary output. Phase 202 should preserve the Fake-backed local default while clarifying live provider proved/skipped state.

</code_context>

<specifics>
## Specific Ideas

- The strongest recommendation set is coherent across all areas: static-first audit; opportunistic read-only run-history snapshot; blunt, measure-first target pipeline; binary provider proof language; readable audit plus Phase 204 handoff table.
- Lessons from successful framework billing libraries: Laravel Cashier and Pay work because they feel native to their host framework and keep common billing jobs behind clear framework idioms. Accrue should keep its CI/DX story similarly Phoenix-native: Mix tasks, ExUnit, HexDocs, Ecto/Postgres, Plug/Phoenix host boundaries, and the Fake processor as the fast deterministic proof path.
- Lessons from provider docs: Stripe test mode/sandboxes are useful for provider-specific proof, but live-provider tests require explicit secrets/fixtures and should not silently become "green parity" when skipped.
- Lessons from Playwright: browser setup/caching should be measured. Playwright's CI docs caution that browser-binary cache restore can be comparable to download time on Linux, so recommend Playwright caching only after run data supports it.
- Lessons from GitHub Actions: job summaries and REST workflow/job APIs are appropriate for read-only measurement; cache hit/miss state is explicit; skipped checks can confuse branch-protection truth if not surfaced clearly.
- Lessons from ExUnit/Mix: async and partitioning can improve speed only when tests do not mutate global state or depend on shared resources. Accrue has many tests that mutate application env/provider state, so the audit should recommend classification before async/parallelization changes.
- External references consulted during discussion:
  - `https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching`
  - `https://docs.github.com/rest/actions/workflow-runs`
  - `https://docs.github.com/rest/actions/workflow-jobs`
  - `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands`
  - `https://playwright.dev/docs/ci`
  - `https://hexdocs.pm/ex_unit/ExUnit.Case.html`
  - `https://hexdocs.pm/mix/Mix.Tasks.Test.html`
  - `https://hexdocs.pm/mix/Mix.Tasks.Xref.html`
  - `https://hex.pm/docs/publish`
  - `https://docs.stripe.com/testing`
  - `https://docs.stripe.com/billing/testing`
  - `https://docs.stripe.com/sandboxes`
  - `https://docs.stripe.com/webhooks`
  - `https://laravel.com/docs/13.x/billing`
  - `https://github.com/pay-rails/pay`

</specifics>

<deferred>
## Deferred Ideas

- Any actual CI topology changes, branch protection changes, required-check changes, job finalizer work, reusable workflow extraction, cache changes, Docker layer-cache work, Playwright setup changes, or workflow path filters.
- Any live-Stripe behavior change: fail-on-missing-secrets, rename to advisory, summary emission, provider proved/skipped counter, or fixture/secrets management.
- Any Sigra/OpenTelemetry matrix redesign or optional-dependency compile/test implementation.
- Any release recovery preflight implementation in `publish-hex.yml`.
- Any public docs rewrite beyond what the Phase 202 audit recommends for follow-up hardening.
- Any UI/admin/portal design-system work.

### Reviewed Todos (not folded)
- `Shared page_header component for accrue_admin list pages` - UI/admin todo, likely resolved by v1.54 PageHeader work; not related to CI/CD audit scope.
- `White-label billing portal design system` - future portal/UI hardening candidate; not related to CI/CD audit scope.

</deferred>

---

*Phase: 202-ci-cd-performance-and-determinism-audit*
*Context gathered: 2026-07-02*
