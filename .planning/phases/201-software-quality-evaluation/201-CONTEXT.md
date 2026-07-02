# Phase 201: software-quality-evaluation - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 201 produces `201-SOFTWARE-QUALITY-AUDIT.md`: an evidence-backed quality evaluation of Accrue as a real OSS billing project across adoption, production readiness, maintainability, supportability, UI, release, upgrade, data, security, architecture, OSS trust, and any Accrue-specific quality dimensions that materially affect adopter confidence.

This phase is audit-only. It must not change product behavior, public APIs, DB defaults, CI required-check topology, package release automation, or UI/runtime implementation. It may refine the audit artifact, cite repo evidence, and identify follow-up hardening work for Phase 204.

</domain>

<decisions>
## Implementation Decisions

### Audit Stance And Bluntness
- **D-01:** Use a **balanced release-readiness report with a blunt scored core**. Preserve rankings, 1-5 scores, confidence, top-five weakness deep dives, and blunt maintainer-facing language, but frame scores as release-readiness triage rather than a public report card.
- **D-02:** The audit voice must follow Accrue's committed brand voice: measured, exact, Phoenix-native, durable, mechanism-led, and proof-checkable. Avoid hype, generic adjectives, and public shaming. Statements like "production-ready but audit-heavy" are acceptable when backed by evidence and concrete consequences.
- **D-03:** The audit must mark strong and not-applicable dimensions honestly. Do not manufacture concerns to fill a matrix. If a dimension is strong, say why and move on.

### Evidence Boundary
- **D-04:** Static repo evidence is the primary evidence source. Every low score, concern, and recommendation must cite concrete local paths or explicitly label itself as an assumption.
- **D-05:** Limited cheap command verification is allowed when it improves confidence without turning Phase 201 into a verification milestone. Good examples: `rg`, `find`, `wc`, package metadata inspection, docs/link checks, or narrowly scoped deterministic Mix commands if already cheap and relevant.
- **D-06:** Full `mix verify.full`, Docker boot proof, live Stripe, GitHub run-history analysis, flake-rate metrics, and external scorecards are not required for Phase 201. When relevant, record them as "metrics needed" or follow-up inputs for Phase 202 / Phase 204.
- **D-07:** Dynamic claims need clear labeling. The audit can say static inspection suggests CI duplication or provider-lane ambiguity, but measured p50/p95 runtime, cache hit rates, and flake rates belong to Phase 202 unless live data is explicitly collected there.

### Scope Split With Phases 202 And 203
- **D-08:** Use an **integrated summary with explicit handoff** for CI/CD and DB schema. Phase 201 should rank CI/CD signal fidelity and schema-prefix safety as quality risks, explain why they matter to adoption/production/support trust, and cite the local evidence.
- **D-09:** Do not duplicate Phase 202's CI topology, critical-path, cache, flakiness, and target-pipeline analysis inside Phase 201. Link and summarize. Phase 202 owns implementation-grade CI/CD recommendations and measurements.
- **D-10:** Do not duplicate Phase 203's DB schema ADR inside Phase 201. Phase 201 should state that schema-prefix drift is a data/upgrade safety risk; Phase 203 owns the accepted `billing` default, explicit `public` posture, Ecto prefix reasoning, and future hardening checks.
- **D-11:** Phase 204 should consume Phase 201 as the cross-quality ranking input and consume Phases 202/203 for specialist evidence. Avoid double-counting the same CI or DB risk as multiple unrelated roadmap items.

### Folded Todos
- **D-12:** Fold `White-label billing portal design system` as supporting evidence for the portal parity/customer portal UX weakness. It is not Phase 201 implementation scope. Phase 204 may rank a future `accrue_portal` readiness/design-system/white-label pass if the audit confirms adopter-risk value.
- **D-13:** Treat `Shared page_header component for accrue_admin list pages` as resolved/positive design-system evidence, not a current weakness. PageHeader shipped in v1.54 and should only be mentioned as proof that stale todos need hygiene if still pending.
- **D-14:** Treat `Use the Accrue favicon in the brandbook HTML` as valid deferred polish. It can improve public-trust polish, but it does not reduce enough adoption, production, support, or maintenance risk to become a Phase 201 weakness by itself.

### Cross-Cutting Product And DX Lens
- **D-15:** Recommendations must be coherent with Accrue's stable-core vision: a Phoenix developer can install Accrue plus the companion admin/portal packages and launch a real SaaS billing loop with clear state, strong proof paths, and low surprise.
- **D-16:** The primary personas for the audit are: first-time Phoenix SaaS evaluator, production adopter, maintainer/reviewer, support/debugging maintainer, operator using `accrue_admin`, and customer using `accrue_portal`.
- **D-17:** For API and docs findings, evaluate from the consumer's perspective, not the provider's internal elegance. Host apps should see clear facades, exact ownership boundaries, and least-surprise setup. Do not expose backend guts unless they are fundamental to safe integration.
- **D-18:** For UI/UX findings, apply JTBD, accessibility, performance, responsive behavior, dark/light/system theming, focus/hover affordances, microcopy, and brand consistency. `accrue_admin` is recently strong; `accrue_portal` needs proportionate parity because it is customer-facing.
- **D-19:** Use lessons from Pay, Laravel Cashier, Stripe, Phoenix/Ecto/Plug, Oban, and successful OSS projects: framework-native vocabulary, small clear public facades, strong examples, test doubles/proof paths, precise provider-boundary docs, and honest operational guidance. Avoid footguns: overclaiming provider parity, hiding lifecycle semantics, stale public version truth, raw provider detail leakage, and scorecards with false precision.

### Claude's Discretion
- The planner/researcher may choose the exact table layout, score labels, and appendix structure as long as D-01 through D-19 hold.
- The planner/researcher may select cheap supporting commands, but must keep them bounded and label command outputs as supporting evidence rather than full release proof.
- The planner/researcher may tune wording to match the brandbook voice, but must not soften real risks into vague prose.

### Folded Todos
- **White-label billing portal design system** (`.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md`) — Folded as evidence for portal parity and customer-portal UX/design-system risk. The todo's implementation remains future scope.
- **Shared page_header component for accrue_admin list pages** (`.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md`) — Folded as reviewed/resolved evidence. Do not treat as an active weakness.
- **Use the Accrue favicon in the brandbook HTML** (`.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md`) — Folded as reviewed deferred polish. Mention only if the audit has a low-priority public-trust polish section.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements
- `.planning/PROJECT.md` — Stable-core posture, v1.55 goal, current milestone rationale, prior UI/brand/admin decisions.
- `.planning/ROADMAP.md` — Phase 201 boundary, success criteria, dependency shape, and audit-only non-goals.
- `.planning/REQUIREMENTS.md` — QLT-01..QLT-05 requirements and traceability.
- `.planning/STATE.md` — Current v1.55 state, deferred items, known CI issue, and standing intake rules.

### Phase Artifacts
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` — Draft audit baseline to refine.
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` — Specialist CI/CD audit; summarize and hand off, do not duplicate.
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` — Specialist DB schema ADR; summarize and hand off, do not duplicate.
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` — Downstream integration target for ranked follow-up hardening work.

### Project Vision, Brand, And Prompt Research
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — Adopter-first "done enough" rubric, subagent research preference, idiomatic Elixir/DX/UX lens.
- `prompts/accrue-brand-book.md` — Historical brand seed; use only where not superseded by committed brandbook artifacts.
- `brandbook/README.md` — Current logo, palette, and brand asset contract.
- `brandbook/voice.md` — Authoritative voice system: measured, exact, native, durable, mechanism-led.
- `brandbook/copy.md` — Approved copy blocks and public-surface wording.
- `brandbook/tokens/README.md` — Brand/admin token relationship and design-system constraints.

### Front-Door Docs, CI, And Package Surfaces
- `README.md` — Root proof path, package overview, validation modes, stable-core posture.
- `accrue/README.md` — Core package front door, install, public facade, support matrix narrative.
- `accrue_admin/README.md` — Admin package front door and operator UI surface.
- `accrue_portal/README.md` — Portal package front door; thinner surface and portal parity evidence.
- `CONTRIBUTING.md` — Contributor setup, local gates, toolchain truth drift evidence.
- `scripts/ci/README.md` — CI/docs-contract map and maintainer triage surface.
- `.github/workflows/ci.yml` — CI workflow topology and static evidence for signal/cost findings.

### Folded Todos
- `.planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md` — Portal parity and customer-facing white-label evidence.
- `.planning/todos/pending/2026-06-21-shared-page-header-component-for-accrue-admin.md` — Resolved PageHeader/design-system evidence and stale-todo hygiene signal.
- `.planning/todos/pending/2026-06-19-brandbook-use-accrue-favicon.md` — Deferred brandbook polish evidence.

### Code And Implementation Evidence To Sample
- `accrue/lib/accrue/schema.ex` — Ecto schema-prefix posture.
- `accrue/lib/accrue/migration.ex` — Migration prefix helper posture.
- `accrue/lib/accrue/config.ex` — `:billing_schema` default and validation.
- `accrue/guides/configuration.md` — Config and schema-prefix public docs.
- `accrue/guides/upgrade.md` — Upgrade/posture implications.
- `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` — Portal UI evidence cited by folded todo.
- `accrue_portal/priv/static/accrue_portal.css` — Portal style/design-system evidence.
- `accrue_admin/lib/accrue_admin/components/page_header.ex` — Resolved PageHeader pattern.
- `storybook/components/page_header.story.exs` — PageHeader Storybook proof surface.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `201-SOFTWARE-QUALITY-AUDIT.md`: seeded audit baseline with dimension table, top-five weaknesses, JTBD/adoption/SRE/maintainer sections, and top-10 hardening candidates.
- `202-CI-CD-PERFORMANCE-AUDIT.md` and `203-DB-SCHEMA-CONTRACT-ADR.md`: specialist artifacts that Phase 201 should cite, not duplicate.
- `scripts/ci/README.md`: maintainer-facing map from quality gates to owners; useful evidence for both CI strength and proof-sprawl risk.
- `brandbook/voice.md` and `brandbook/copy.md`: authoritative guardrails for audit wording.
- `PageHeader` component/story: resolved admin design-system evidence; treat as proof of pattern maturity.

### Established Patterns
- Accrue favors proof-led claims: public docs should name mechanisms (`Fake processor`, `merge-blocking CI`, `append-only ledger`, `Ecto-native schemas`) instead of adjective-led marketing.
- Elixir/Phoenix idioms matter: Mix tasks, ExUnit, HexDocs, Ecto schemas/migrations, Plug boundaries, Phoenix components, Oban, telemetry, and host-owned Repo/auth/routes should be named precisely.
- UI/design-system work has a strong recent precedent in v1.53/v1.54: page-flow gates, Storybook, component registry, theme tokens, axe, focus/hover/overlay correctness. Do not churn `accrue_admin` without evidence.
- Portal parity is a different surface: `accrue_portal` is customer-facing and should be evaluated through customer JTBD, host white-labeling, accessibility, theming, and least-surprise self-serve flows.

### Integration Points
- Phase 201 output feeds Phase 204 ranking. Keep recommendations sliced and traceable so Phase 204 can group future implementation milestones coherently.
- Phase 202 owns CI/CD measurement, topology, determinism, caching, and provider-lane truth.
- Phase 203 owns DB schema default/`public` posture and future prefix hardening checks.
- Pending todos should inform risk assessment, not silently expand Phase 201 into implementation.

</code_context>

<specifics>
## Specific Ideas

- External ecosystem lessons to consider: Laravel Cashier and Pay succeed by being framework-native, practical, and focused on common billing jobs; Stripe docs are strong because they separate testing, go-live, and customer portal configuration; Phoenix/Ecto/Plug projects tend to earn trust through exact installation, migration, testing, and production-readiness guidance.
- Footguns to avoid: public scorecards that imply false precision, "mandatory" CI/provider lanes that can silently skip, stale supported-version claims, provider-parity overclaims, UI that exposes backend implementation detail, and overbuilt governance that slows maintainers without reducing adopter risk.
- Design pillars to apply where UI is relevant: accessibility, responsive layout, focus/hover integrity, dark/light/system theme correctness, performance, microcopy, information hierarchy, brand coherence, and customer/operator JTBD clarity.
- API/docs design should be consumer-first. Prefer public facades and ownership boundaries that make sense to a Phoenix app developer over internal/provider-centric elegance.

</specifics>

<deferred>
## Deferred Ideas

- Future `accrue_portal` readiness/design-system/white-label milestone or hardening slice, if Phase 204 ranks it high enough from audit evidence.
- Brandbook favicon HTML polish.
- Todo hygiene to close or archive the resolved PageHeader pending todo.
- Phase 202 live GitHub run-history metrics, CI duration/cache/flake baseline, and provider proved-vs-skipped counts.
- Future implementation milestone for schema-prefix guards and raw SQL qualification checks.
- Any actual CI topology changes, DB defaults, UI styling changes, package metadata changes, or release automation changes.

</deferred>

---

*Phase: 201-software-quality-evaluation*
*Context gathered: 2026-07-02*
