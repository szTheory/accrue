# Phase 204: ranked-hardening-roadmap - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 204 produces `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`: a ranked, evidence-backed roadmap that turns the completed Phase 201 software-quality audit, Phase 202 CI/CD audit, and Phase 203 DB schema ADR into implementation-sized follow-up hardening work.

This phase is roadmap-only. It must not change product behavior, public APIs, DB defaults, CI topology, release automation, runtime UI, CSS, routes, package metadata, source code, scripts, examples, or public docs outside the Phase 204 roadmap artifact. It may refine the roadmap artifact, rank hardening candidates, group future implementation slices, define done criteria, and explicitly defer polish-only or overbuilt work.

</domain>

<decisions>
## Implementation Decisions

### Research Method And Lens
- **D-01:** Discuss and resolve all four gray areas as one coherent decision set: ranking rules, milestone slicing, ranked-versus-deferred boundary, and roadmap row/artifact shape.
- **D-02:** Use parallel subagent research plus local repo evidence to make one-shot recommendations. The user explicitly prefers a researched recommendation set over step-by-step manual tradeoff review.
- **D-03:** Apply repo-local truth first. Phase 201, 202, and 203 artifacts are authoritative over generic best practices. External ecosystem references are used only to sharpen tradeoffs and identify footguns.
- **D-04:** Apply `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` as the strategic lens: practical adopter-facing "done enough" judgment, Phoenix SaaS evaluator perspective, least-surprise DX, and no overbuilding.
- **D-05:** Apply the committed brandbook, especially `brandbook/voice.md`, over older prompt-era brand language. Roadmap prose should be measured, exact, Phoenix-native, durable, mechanism-led, and proof-checkable.
- **D-06:** Use UI/UX, graphic-design, JTBD, and user-psychology lenses where applicable, especially for evaluator-path, package/front-door docs, support-routing docs, and `accrue_portal` parity. Do not turn Phase 204 into UI implementation.

### Ranking Rules
- **D-07:** Use an **adopter-proof release-readiness blend**. Rank by: (1) adopter or release trust breakage, (2) data/release safety, (3) measurement prerequisites, (4) maintainer runtime and CI efficiency, and (5) low effort only as a tie-breaker inside the same risk class.
- **D-08:** Do not let "cheap" outrank "prevents public-truth, provider-proof, release-order, or schema-prefix confusion." Low effort is a useful tie-breaker, not the primary sort key.
- **D-09:** CI/CD is the weakest quality dimension, but CI topology cleanup must stay measure-first. Add timing/cache/provider-proof summaries before splitting gates, changing branch-protection semantics, demoting checks, adding caches, or moving work to schedules.
- **D-10:** Treat public truth, evaluator clarity, provider proof semantics, release recovery order, and schema-prefix safety as trust/safety work, not polish.
- **D-11:** Recommended ranked top 10 for the roadmap:
  1. Fix public toolchain/version truth.
  2. Create one evaluator proof path.
  3. Clarify provider proved/skipped/advisory semantics.
  4. Add release recovery preflight for linked package order.
  5. Add CI timing/cache/provider baseline summaries.
  6. Add schema-prefix hardening guards.
  7. Polish package metadata and public listing trust signals.
  8. Consolidate host browser setup ownership after measurement.
  9. Split release-gate repetition after baseline data.
  10. Add a narrow portal parity readiness pass.

### Milestone Slicing
- **D-12:** The roadmap should group follow-up work into milestone-sized slices, not one giant cleanup grab bag.
- **D-13:** Recommended implementation sequence:
  1. **Public Truth And Proof-State Baseline** - toolchain/version truth, provider proved/skipped language, CI timing/cache/provider summaries, and package metadata exactness.
  2. **Evaluator Path And Release Safety** - one 30-minute clone-to-confidence path, linked release recovery preflight, and public docs that explain what the gates prove.
  3. **CI Critical Path Cleanup** - host browser setup ownership, release-gate split, matrix-fidelity cleanup, Docker/Playwright policy only after baseline evidence.
  4. **Schema Prefix Contract Hardening** - central default, prefix agreement tests, raw SQL qualification guard, installer/docs/test mirror checks.
  5. **Portal Parity Readiness** - narrow customer-facing portal setup, troubleshooting, theming/white-label readiness, and proof-path parity.
- **D-14:** It is acceptable for roadmap rank and implementation sequence to differ slightly. Rank expresses cross-audit risk priority; milestone sequence must respect dependencies, especially "measure before CI cleanup."
- **D-15:** Release recovery preflight can live with public/release-truth work rather than becoming a standalone milestone, unless future planning finds a same-day release recovery risk large enough to justify a dedicated release slice.

### Ranked Versus Deferred Boundary
- **D-16:** Include public truth, evaluator path, provider proof semantics, release recovery preflight, schema hardening, CI baseline, package metadata, host browser setup, release-gate split, and narrow portal readiness in the ranked set.
- **D-17:** Defer test value classification until CI summaries produce slowest-test, cache, runtime, and failure-history evidence. Without that baseline, classification risks rationalizing proof deletion instead of improving signal.
- **D-18:** Include portal parity only as a **narrow readiness** item. Broad portal white-label/design-system/UI polish remains deferred unless tied to a concrete portal adoption failure, support issue, accessibility defect, or strategy change.
- **D-19:** Defer a support triage index unless future evidence shows repeated support-routing pain or public-support scale. It is a good candidate, but weaker than portal parity for the current top 10 because portal parity is a direct package-story gap with existing todo evidence.
- **D-20:** Defer pixel-diff visual regression tooling, default schema rename to `accrue`, broad runtime performance benchmarking, enterprise governance artifacts, i18n/localization program, and any docs rewrite not tied to adoption, production, support, or maintenance risk.

### Roadmap Artifact Shape
- **D-21:** Use a **two-layer roadmap artifact**: a compact ranked top-10 table first, followed by detailed implementation cards grouped into follow-up milestones.
- **D-22:** Required top-10 table columns: `Rank`, `Change`, `Area / quality dimension`, `Impact`, `Effort`, `Risk reduction`, `Timing / slice`, and `Done criteria`.
- **D-23:** Required implementation-card fields: `Source evidence`, `Reader/JTBD served`, `Scope`, `Non-goals`, `Implementation approach`, `Verification`, `Rollback`, and `Metrics/evidence needed`.
- **D-24:** Required document sections: `How to read this roadmap`, `Ranking method`, `Ranked Top 10`, `Implementation Cards`, `Suggested Follow-Up Milestones`, `Explicit Deferrals`, `Requirement Coverage`, and `Phase Handoff and Boundary`.
- **D-25:** Keep the maintainer scan path short. Do not bury the rank inside long cards. Use detailed cards so future planner/executor agents do not have to re-mine Phase 201-203 prose.
- **D-26:** Avoid wide, overloaded Markdown tables where the content becomes hard to scan. Prefer the compact ranking table plus per-item cards for accessibility and reviewer ergonomics.

### JTBD, DX, UI/UX, And Ecosystem Lessons
- **D-27:** Roadmap readers and jobs to serve:
  - Maintainer/reviewer: "What should we fix first, and why?"
  - Future planner/executor: "What files, evidence, verification, and rollback shape does this work need?"
  - Phoenix evaluator: "What does Accrue prove in the first 30 minutes?"
  - Support maintainer: "Which risk does this reduce and what should not be over-fixed?"
  - Release maintainer: "What must be true before a linked Hex recovery?"
  - Portal adopter/customer-flow reviewer: "Does `accrue_portal` feel first-class enough for the official story?"
- **D-28:** For docs/API/DX decisions, optimize for the consumer's mental model, not provider-internal elegance. Use Phoenix nouns (`context`, `facade`, `plug`, `Ecto schema`, `migration`, `mix task`, `ExUnit`, `Oban`, `telemetry`) and hide backend guts unless a real Ecto/Postgres/provider constraint requires naming them.
- **D-29:** For UI/UX-adjacent portal work, apply accessibility, responsive layout, dark/light/system theming, focus/hover integrity, performance, microcopy, brand coherence, white-label boundaries, and customer JTBD. Phase 204 should rank this work, not design or implement it.
- **D-30:** Lessons from successful billing libraries: Laravel Cashier and Pay win by giving framework-native setup paths, clear subscription/provider/webhook docs, explicit upgrade and processor boundary notes, and practical examples. Accrue should learn that clarity and native vocabulary matter more than broad claims.
- **D-31:** Footguns to avoid from billing ecosystems: overclaiming provider parity, hiding webhook ordering/provider-test requirements, letting fake/test lanes look equivalent to live-provider proof, publishing linked packages out of order, and making docs look simpler than the real setup.
- **D-32:** Elixir/Phoenix idiom favors explicit mechanisms: Phoenix context/facade boundaries, Plug composability, Ecto prefix contracts, Mix tasks, ExUnit/Playwright proof paths, Oban-owned migration/version patterns, and Hex metadata/release discipline. The roadmap should name these mechanisms directly.

### Folded Todos
- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) - Fold as evidence for the narrow portal parity readiness item. The todo does not authorize broad portal UI redesign in Phase 204.

### Claude's Discretion
- The planner/researcher may adjust the exact wording and section order of `204-HARDENING-ROADMAP.md`, but D-07 through D-26 are locked.
- The planner/researcher may slightly reorder top-10 ranks if it cites stronger evidence from the final Phase 201-203 artifacts, but must preserve the ranking rule: trust/safety before runtime speed, measurement before CI topology cleanup, and low effort only as a tie-breaker.
- The planner/researcher may split or combine follow-up milestones when planning, but must keep slices independently implementable and must not turn DB, CI, portal, and docs into one broad cleanup phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/PROJECT.md` - Stable-core posture, v1.55 audit-only rationale, post-v1.48 pause rule, and current milestone goal.
- `.planning/ROADMAP.md` - Phase 204 boundary, success criteria, dependency shape, canonical refs, and no-code-change posture.
- `.planning/REQUIREMENTS.md` - RD-01 through RD-04 requirements and traceability.
- `.planning/STATE.md` - Current v1.55 state and Phase 204 starting position.

### Phase 204 Target
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` - Target artifact to refine from draft baseline into final ranked roadmap.

### Inputs From Prior v1.55 Phases
- `.planning/phases/201-software-quality-evaluation/201-CONTEXT.md` - Phase 201 decisions, audit stance, evidence boundary, and Phase 204 handoff split.
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` - Cross-quality ranking, top-five weakness deep dives, evidence appendix, folded todo classification, and Phase 204 top-10 handoff.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CONTEXT.md` - Phase 202 decisions around static-first CI audit, provider proof semantics, target pipeline, and handoff row shape.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` - Specialist CI/CD evidence and local-priority Phase 204 handoff rows.
- `.planning/phases/203-database-schema-contract-adr/203-CONTEXT.md` - Phase 203 decisions around `billing`, explicit `public`, authoritative surfaces, compatibility, and handoff shape.
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` - Accepted DB schema contract ADR and structured schema-prefix hardening handoff rows.

### Project Vision, Brand, And Prompt Lens
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - Adopter-first "done enough" rubric, subagent research preference, idiomatic Elixir/Phoenix/DX lens, and anti-overbuilding guidance.
- `brandbook/voice.md` - Current authoritative voice system: measured, exact, Phoenix-native, durable, mechanism-led, proof-checkable.
- `brandbook/copy.md` - Approved public-surface copy patterns and mechanism-led claim posture.
- `brandbook/README.md` - Current brand asset contract and first-impression surface constraints.

### CI, Release, And Package Evidence
- `.github/workflows/ci.yml` - CI topology, matrix, host/browser lanes, release gate, annotation sweep, Docker smoke, and live-Stripe lane.
- `.github/workflows/release-please.yml` - Primary ordered linked release path.
- `.github/workflows/publish-hex.yml` - Manual recovery publish workflow that needs preflight if ranked.
- `scripts/ci/README.md` - Maintainer-facing CI/script map and gate ownership evidence.
- `scripts/ci/watch_ci.sh` - Existing GitHub Actions watch helper.
- `scripts/ci/verify_release_contract.sh` - Existing release contract check.
- `scripts/ci/verify_release_manifest_alignment.sh` - Existing release/package alignment check.
- `scripts/ci/capture_linked_release_proof.sh` - Linked release proof capture.
- `scripts/ci/accrue_host_uat.sh` - Host integration proof entrypoint.
- `scripts/ci/accrue_host_verify_browser.sh` - Host browser verification and setup behavior.
- `scripts/ci/annotation_sweep.sh` - Release-facing annotation sweep.
- `scripts/ci/compile_matrix.sh` - Optional-dependency compile-matrix/advisory semantics.
- `accrue/mix.exs` - Core package version, metadata, deps, aliases, docs config, and support truth.
- `accrue_admin/mix.exs` - Admin package version, metadata, docs/package surface.
- `accrue_portal/mix.exs` - Portal package version, metadata, docs/package surface.
- `CONTRIBUTING.md` - Public toolchain/setup truth drift evidence.
- `RELEASING.md` - Linked release and support contract evidence.

### Public Docs, Evaluator Path, And Provider Proof
- `README.md` - Root front door, proof path, public positioning, and first evaluator route.
- `accrue/README.md` - Core package front door and public facade narrative.
- `accrue_admin/README.md` - Admin package front door and operator UI surface.
- `accrue_portal/README.md` - Portal package front door and package parity evidence.
- `examples/accrue_host/README.md` - Host Start Here/proof path candidate.
- `examples/accrue_host/docs/adoption-proof-matrix.md` - Existing proof matrix and evaluator evidence.
- `accrue/guides/first_hour.md` - First-hour guide and evaluator-path input.
- `accrue/guides/testing.md` - Local testing/proof semantics.
- `guides/testing-live-stripe.md` - Live Stripe provider-proof and skip/proved semantics.
- `accrue/guides/release-notes.md` - Release/public narrative evidence.

### DB Schema Contract Evidence
- `accrue/lib/accrue/config.ex` - `:billing_schema` default, validation, and config docs.
- `accrue/lib/accrue/schema.ex` - Compile-time Ecto schema prefix mechanism.
- `accrue/lib/accrue/migration.ex` - Migration prefix helpers and raw SQL qualification helpers.
- `accrue/lib/accrue/install/options.ex` - Installer `--billing-schema` option behavior.
- `accrue/lib/accrue/install/patches.ex` - Generated host config snippets.
- `accrue/lib/accrue/install/templates.ex` - Installer-generated defaults.
- `accrue/lib/mix/tasks/accrue.install.ex` - Installer CLI docs and wiring.
- `accrue/test/mix/tasks/accrue_install_test.exs` - Installer tests for default `billing` and explicit `public`.
- `accrue/test/mix/tasks/accrue_install_uat_test.exs` - Installer UAT coverage.
- `examples/accrue_host/config/config.exs` - Example host explicit `billing` config mirror.
- `examples/accrue_host/test/install_boundary_test.exs` - Example-host install boundary checks.
- `accrue/guides/configuration.md` - Compile-time schema config docs.
- `accrue/guides/upgrade.md` - Upgrade and host-owned schema move boundary.

### Portal And Todo Evidence
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` - Folded evidence for narrow portal parity readiness.
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` - Reviewed/resolved PageHeader/stale-todo evidence; not active Phase 204 scope.
- `.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md` - Reviewed deferred brandbook polish; not active Phase 204 scope.
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` - Portal UI/JTBD evidence.
- `accrue_portal/priv/static/accrue_portal.css` - Portal style/design-system evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `204-HARDENING-ROADMAP.md`: draft baseline with a top-10 table, five follow-up milestone slices, explicit deferrals, and done criteria.
- `201-SOFTWARE-QUALITY-AUDIT.md`: cross-quality input with ranked dimensions, top-five weakness deep dives, evidence appendix, folded todo classification, and initial Phase 204 top-10 handoff.
- `202-CI-CD-PERFORMANCE-AUDIT.md`: specialist CI input with baseline-metrics-needed, local priority handoff rows, provider proved/skipped language, target pipeline, verification, rollback, and metric-needed fields.
- `203-DB-SCHEMA-CONTRACT-ADR.md`: accepted schema-prefix contract plus structured future hardening rows for default constants, prefix agreement, compatibility lanes, raw SQL guards, docs mirrors, and host-owned data migration boundary.
- `brandbook/voice.md`: prose guardrail for the roadmap's tone and claim discipline.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md`: user preference source for subagent research, adopter-first ranking, idiomatic Elixir/Phoenix/DX lens, and "done enough" judgment.

### Established Patterns
- Accrue favors proof-led claims over adjective-led claims. The roadmap should name mechanisms such as `Fake processor`, `merge-blocking CI`, `live-stripe`, `@schema_prefix`, `Accrue.Migration.qualified_table/1`, and linked release proof.
- Phase 201-203 artifacts use readable reports followed by structured handoff rows. Phase 204 should keep that pattern and make the handoff executable by future planners.
- Recent UI/admin milestones show heavy design-system investment is allowed only when tied to explicit strategy or firsthand defects. Portal parity should be narrow and evidence-led, not broad UI churn.
- CI work must distinguish static risk, measured baseline, and implementation. Measurement belongs before topology changes, cache changes, or gate demotion.
- DB schema work must distinguish normative current contract from advisory future hardening. The default remains `billing`; explicit `public` remains supported.

### Integration Points
- Phase 204 output feeds future roadmap/milestone creation. Its rows must be rankable and independently sliceable.
- Future CI hardening will likely touch `.github/workflows/ci.yml`, workflow summaries, `scripts/ci/*`, docs describing proof paths, and possibly branch-protection settings.
- Future release hardening will likely touch `.github/workflows/publish-hex.yml` and release verifier scripts.
- Future DB hardening will likely touch `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, installer code, docs, tests, and static checks.
- Future portal readiness may touch `accrue_portal` docs, CSS/components, host proof paths, troubleshooting docs, and portal release-note coverage.

</code_context>

<specifics>
## Specific Ideas

- Parallel subagent research was run for all four gray areas:
  - Ranking rules.
  - Follow-up milestone slicing.
  - Ranked-versus-deferred boundary.
  - Roadmap row/artifact shape.
- All researchers converged on the same core posture: trust and proof truth before speed, measurement before CI cleanup, schema hardening as safety work, portal parity as narrow readiness, and a two-layer artifact for both scanning and execution.
- External ecosystem references consulted during discussion:
  - `https://phoenix.hexdocs.pm/contexts.html` - Phoenix context/facade idiom.
  - `https://phoenix.hexdocs.pm/plug.html` - Plug composability and request boundary idiom.
  - `https://ecto.hexdocs.pm/Ecto.Schema.html` - `@schema_prefix` behavior.
  - `https://github.com/elixir-ecto/ecto/blob/master/guides/howtos/Multi%20tenancy%20with%20query%20prefixes.md` - Ecto query/schema prefix behavior and search-path pitfalls.
  - `https://oban.hexdocs.pm/Oban.Migration.html` - Oban migration/prefix/versioning precedent.
  - `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands` - GitHub Actions job summaries for surfacing important run information.
  - `https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching` - Cache-hit output and cache behavior.
  - `https://playwright.dev/docs/ci` - Playwright browser cache caution; measure before caching.
  - `https://hex.pm/docs/publish` and `https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html` - Hex package metadata, publish, docs, and recovery behavior.
  - `https://docs.stripe.com/webhooks`, `https://docs.stripe.com/billing/subscriptions/webhooks`, and `https://docs.stripe.com/billing/testing` - provider/webhook proof semantics and testing limits.
  - `https://laravel.com/docs/13.x/billing` - Laravel Cashier's framework-native billing docs and provider/webhook setup lessons.
  - `https://github.com/pay-rails/pay/` and `https://github.com/pay-rails/pay/blob/main/docs/6_subscriptions.md` - Pay Rails provider-boundary, fake processor, and subscription docs lessons.
- Roadmap tone should avoid "production-grade", "easy", "seamless", "robust", and other brandbook-banned words unless quoted from external sources. Use exact mechanisms instead.
- The final `204-HARDENING-ROADMAP.md` should be blunt about what is still not proved: no hidden p50/p95 CI data, no pretending live provider lanes prove parity when skipped, and no claiming schema guards exist before they are implemented.

</specifics>

<deferred>
## Deferred Ideas

- Test value classification until CI baseline summaries provide slowest-test, runtime, cache, flake/rerun, and failure-history evidence.
- Broad portal white-label/design-system redesign beyond narrow readiness unless future evidence shows a concrete adoption, accessibility, support, or strategy-triggered need.
- Support triage index unless support-routing pain or public support scale becomes a clearer risk.
- Pixel-diff visual regression tooling unless current page-flow scoring misses real regressions.
- Default schema rename from `billing` to `accrue`.
- Automatic production data movement between schemas or a casual public-to-billing relocation recipe.
- CI gate deletion, demotion, branch-protection changes, Docker/Playwright cache changes, or schedule-only moves before baseline measurement.
- Broad docs rewrite, enterprise governance program, i18n/localization program, and runtime performance benchmarking without concrete adopter/support/production risk.
- Brandbook favicon HTML polish.

### Reviewed Todos (not folded)
- `Shared page_header component for accrue_admin list pages` - reviewed as resolved/stale admin UI evidence; PageHeader shipped in v1.54 and should not drive Phase 204 scope.
- `Use the Accrue favicon in the brandbook HTML` - reviewed as valid brandbook polish, but not enough adoption, production, support, or maintenance risk to rank now.

</deferred>

---

*Phase: 204-ranked-hardening-roadmap*
*Context gathered: 2026-07-02*
