# Phase 204: Ranked Hardening Roadmap - Research

**Researched:** 2026-07-02  
**Domain:** Audit-to-roadmap synthesis for an Elixir/Phoenix OSS billing library  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
[VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

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

### the agent's Discretion
[VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

- The planner/researcher may adjust the exact wording and section order of `204-HARDENING-ROADMAP.md`, but D-07 through D-26 are locked.
- The planner/researcher may slightly reorder top-10 ranks if it cites stronger evidence from the final Phase 201-203 artifacts, but must preserve the ranking rule: trust/safety before runtime speed, measurement before CI topology cleanup, and low effort only as a tie-breaker.
- The planner/researcher may split or combine follow-up milestones when planning, but must keep slices independently implementable and must not turn DB, CI, portal, and docs into one broad cleanup phase.

### Deferred Ideas (OUT OF SCOPE)
[VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

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
</user_constraints>

## Project Constraints (from CLAUDE.md)

- Accrue is an Elixir/Phoenix payments and billing library with core packages `accrue`, `accrue_admin`, and `accrue_portal`. [VERIFIED: CLAUDE.md]
- The locked project stack floor in project instructions is Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, and PostgreSQL 14+, while current package manifests and CI evidence show a later active toolchain that Phase 204 must treat as public-truth drift rather than silently normalizing. [VERIFIED: CLAUDE.md; VERIFIED: CONTRIBUTING.md; VERIFIED: accrue/mix.exs; VERIFIED: .github/workflows/ci.yml]
- Webhook signature verification is mandatory and non-bypassable; sensitive Stripe fields must not be logged; payment method details are stored as Stripe references rather than PII. [VERIFIED: CLAUDE.md]
- Public entry points are expected to emit `:telemetry` start/stop/exception events and OTel span helpers are available for Billing context functions. [VERIFIED: CLAUDE.md]
- The repo is a monorepo with sibling package projects, shared workflows, shared guides, and package-specific `mix.exs` and `CHANGELOG.md` files. [VERIFIED: CLAUDE.md]
- Project skills are absent in the local project skill directories, so Phase 204 research has no project-local skill rules to apply beyond CLAUDE.md and the GSD references. [VERIFIED: CLAUDE.md; VERIFIED: `find .codex/skills .agents/skills .claude/skills -maxdepth 2 -name SKILL.md`]
- GSD workflow rules say file-changing work should happen through GSD workflow entry points; this research artifact is part of the active GSD phase flow. [VERIFIED: CLAUDE.md; VERIFIED: `gsd-tools query init.phase-op 204`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RD-01 | Maintainer gets a ranked top-10 hardening list with area, quality dimension improved, impact, effort, risk reduction, timing, and done criteria. | Use locked D-07 through D-11 ranking rules, D-21/D-22 table shape, and Phase 201-203 evidence rows. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| RD-02 | Follow-up work is grouped into milestone-sized slices rather than one giant cleanup grab bag. | Use the five locked follow-up slices and preserve dependency order where measurement precedes CI topology cleanup. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| RD-03 | The roadmap ties every recommended implementation slice back to concrete risk found in the audits. | Every card should cite Phase 201, 202, or 203 source evidence plus local path anchors when available. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md] |
| RD-04 | The roadmap explicitly defers polish-only or overbuilt work that does not reduce adoption, production, support, or maintenance risk. | Use D-16 through D-20 and the Phase 201 GSD sanity/deferred findings to keep polish out unless tied to risk. [VERIFIED: .planning/REQUIREMENTS.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md; VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md] |
</phase_requirements>

## Summary

Phase 204 should turn the completed Phase 201 software-quality audit, Phase 202 CI/CD audit, and Phase 203 DB schema ADR into one ranked implementation roadmap without changing source code, CI topology, DB defaults, package metadata, runtime behavior, public docs, or UI. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

The strongest planning guidance is already locked: trust and safety outrank cheapness; public truth, evaluator clarity, provider proof semantics, release recovery order, and schema-prefix safety are risk-reduction work; CI cleanup must be measure-first; portal work is narrow readiness, not broad redesign. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

The existing `204-HARDENING-ROADMAP.md` is a usable draft baseline, but it must be reshaped to the locked two-layer artifact: a compact top-10 table first, then implementation cards with source evidence, JTBD, scope, non-goals, approach, verification, rollback, and metrics/evidence fields. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

**Primary recommendation:** Plan one documentation-only edit that upgrades the draft roadmap into the required two-layer, source-cited, boundary-preserving artifact. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Phase 204 roadmap artifact | Planning / documentation | GSD phase artifacts | The current phase produces only `204-HARDENING-ROADMAP.md`; implementation belongs to later milestones. [VERIFIED: .planning/ROADMAP.md] |
| Public toolchain/version truth | Public docs / package metadata | CI / release docs | Drift is visible between `CONTRIBUTING.md`, package manifests, and workflow setup, so the future owner spans public docs and verifier needles. [VERIFIED: CONTRIBUTING.md; VERIFIED: accrue/mix.exs; VERIFIED: .github/workflows/ci.yml] |
| Evaluator proof path | Public docs / example host | CI host proof | The evaluator path must point to the checked-in host proof rather than inventing a new product flow. [VERIFIED: README.md; VERIFIED: examples/accrue_host/README.md; VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md] |
| Provider proof semantics | CI/CD | Testing docs | `live-stripe` is schedule/manual and skip-capable, while Fake remains merge-blocking; the roadmap must preserve that distinction. [VERIFIED: .github/workflows/ci.yml; VERIFIED: guides/testing-live-stripe.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |
| Release recovery order | Release automation | Package publication docs | Primary Release Please encodes ordered publish dependencies, while manual recovery currently carries package order in prose. [VERIFIED: .github/workflows/release-please.yml; VERIFIED: .github/workflows/publish-hex.yml] |
| CI baseline and cleanup | CI/CD | Maintainer docs | Baseline summaries and cache/timing evidence must precede release-gate splitting, browser setup consolidation, Docker policy, and cache changes. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://playwright.dev/docs/ci] |
| Schema-prefix hardening | Core library / database contract | Installer, docs, tests | The accepted DB contract spans `Accrue.Config`, `Accrue.Schema`, `Accrue.Migration`, installer output, docs, and example-host mirrors. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md; VERIFIED: accrue/lib/accrue/config.ex; VERIFIED: accrue/lib/accrue/schema.ex; VERIFIED: accrue/lib/accrue/migration.ex] |
| Portal parity readiness | `accrue_portal` package | Example host / docs | Portal parity is ranked only as narrow readiness because package docs and the folded todo show a direct customer self-serve story gap. [VERIFIED: accrue_portal/README.md; VERIFIED: .planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Markdown phase artifacts | Existing repo format | Produce `204-HARDENING-ROADMAP.md` and `204-RESEARCH.md`. | Phase 204 is documentation-only and GSD consumes Markdown phase artifacts. [VERIFIED: .planning/ROADMAP.md; VERIFIED: `gsd-tools query init.phase-op 204`] |
| Phase 201 audit | Final Phase 201 artifact | Source ranked quality weaknesses and handoff rows. | The context says Phase 201 is authoritative over generic best practices. [VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Phase 202 audit | Final Phase 202 artifact | Source CI/CD topology, measurement gaps, local CI priorities, and rollback shapes. | The context requires measure-first CI decisions and Phase 202 owns specialist CI detail. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Phase 203 ADR | Accepted Phase 203 artifact | Source DB schema contract and future prefix-hardening rows. | The context locks the `billing` default and explicit `public` handling through the ADR. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| `rg` / `git` | `rg 15.1.0`, `git 2.41.0` | Verify local evidence paths and avoid unsourced roadmap rows. | Repo-local truth is the primary evidence rule. [VERIFIED: environment availability probe; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| GitHub Actions docs | Current official docs as fetched 2026-07-02 | Confirm `GITHUB_STEP_SUMMARY` and cache-hit behavior. | Use only to sharpen CI baseline/card details, not to override Phase 202. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] |
| Playwright CI docs | Current official docs as fetched 2026-07-02 | Confirm browser caching caution. | Use to justify measurement before browser-binary caching. [CITED: https://playwright.dev/docs/ci] |
| Ecto docs | Ecto v3.14 docs as fetched 2026-07-02 | Confirm `@schema_prefix` and `__schema__(:prefix)` testability. | Use to sharpen schema-prefix hardening cards. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html] |
| Hex docs | Hex publish docs and Hex v2.5.0 task docs as fetched 2026-07-02 | Confirm publish metadata, dry-run, docs publish, and recovery behavior. | Use to sharpen package metadata and recovery-preflight cards. [CITED: https://hex.pm/docs/publish; CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html] |
| Stripe docs | Official webhook/testing docs as fetched 2026-07-02 | Confirm webhook signature/test-mode proof boundaries. | Use to keep provider-proof claims exact. [CITED: https://docs.stripe.com/webhooks; CITED: https://docs.stripe.com/billing/subscriptions/webhooks; CITED: https://docs.stripe.com/billing/testing] |
| Phoenix docs | Phoenix v1.8.8 docs as fetched 2026-07-02 | Confirm contexts and Plug vocabulary. | Use to keep roadmap language Phoenix-native. [CITED: https://phoenix.hexdocs.pm/contexts.html; CITED: https://phoenix.hexdocs.pm/plug.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phase 201-203 artifacts as primary evidence | Generic OSS hardening checklists | Generic checklists would violate D-03 and risk ranking unsourced preferences. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Compact table plus detailed cards | One giant Markdown table | A wide table would be harder to scan and contradict D-21 through D-26. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Measurement-first CI cleanup | Immediate release-gate split/cache changes | Phase 202 records metrics-needed gaps and warns against topology changes before baseline data. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |
| Narrow portal readiness | Broad portal redesign | D-18 limits portal parity to readiness unless concrete adoption, support, accessibility, or strategy evidence appears. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |

**Installation:**

No package installation is required for Phase 204. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

**Version verification:**

No new package versions need registry verification because Phase 204 installs no packages and changes no dependency manifests. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Package Legitimacy Audit

No external packages are recommended or installed in this phase. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | n/a | n/a | n/a | n/a | n/a | No install |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package recommendations in this research]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package recommendations in this research]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 201 audit ─┐
                 ├─> Evidence normalization ─> Ranked top-10 table ─┐
Phase 202 audit ─┤                                                   ├─> 204-HARDENING-ROADMAP.md
                 ├─> Risk/dependency ordering ─> Implementation cards ┤
Phase 203 ADR  ──┘                                                   │
                                                                     ├─> Suggested follow-up milestones
204-CONTEXT locked decisions ─> Ranking rules / artifact shape ──────┘

Decision points:
- If work reduces adoption, release, data, support, or maintenance risk -> ranked or carded.
- If work is polish-only or overbuilt without concrete risk -> explicit deferral.
- If CI topology/cache/gate changes are proposed before baseline metrics -> move behind measurement card.
- If roadmap prose implies Phase 204 implemented work -> rewrite as future follow-up only.
```

This diagram reflects the locked Phase 204 dependency shape and audit-only boundary. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Recommended Project Structure

```text
.planning/phases/204-ranked-hardening-roadmap/
├── 204-CONTEXT.md              # Locked decisions and scope from discuss phase.
├── 204-RESEARCH.md             # This planner-facing research artifact.
├── 204-HARDENING-ROADMAP.md    # Target roadmap artifact to refine.
└── 204-01-PLAN.md              # Planner output for the one implementation plan.
```

This structure matches the initialized Phase 204 directory and expected single-plan shape. [VERIFIED: `gsd-tools query init.phase-op 204`; VERIFIED: .planning/ROADMAP.md]

### Pattern 1: Evidence-First Ranking

**What:** Every ranked item should cite Phase 201-203 evidence and identify the risk class it reduces. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**When to use:** Use this for the top-10 table and every implementation card. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Example:**

```markdown
### Rank 3 - Clarify provider proved/skipped/advisory semantics

- Source evidence: Phase 201 provider-parity clarity score 3; Phase 202 live-stripe handoff row; `.github/workflows/ci.yml` schedule/manual `live-stripe`; `guides/testing-live-stripe.md`.
- Reader/JTBD served: Maintainer and Phoenix evaluator need to know what green proves.
- Scope: Future docs/workflow-summary changes only.
- Non-goals: No live provider behavior change in Phase 204.
- Verification: Roadmap row cites Phase 201/202 and says skipped means not proved.
```

The fields above are required by D-23. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Pattern 2: Measure-Before-Optimize CI Cards

**What:** CI cleanup cards must state the measurement prerequisite before proposing topology, caching, branch-protection, or schedule changes. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**When to use:** Use this for CI baseline, host browser setup, release-gate split, Docker smoke, Playwright cache, and test-value classification cards. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**Example:**

```yaml
metrics/evidence needed:
  - p50/p95 job duration
  - cache-hit state
  - slowest tests
  - provider proved/skipped counts
rollback:
  - remove summary-only instrumentation or restore previous workflow/script split
```

GitHub job summaries and cache-hit outputs are official Actions mechanisms for surfacing this run evidence. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]

### Pattern 3: Boundary Language for Audit-Only Work

**What:** Roadmap prose must use future-tense implementation language and explicitly say Phase 204 does not implement behavior. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**When to use:** Use this in the introduction, implementation cards, suggested milestones, and phase handoff. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Example:**

```markdown
This roadmap ranks future implementation slices. It does not change product behavior,
public APIs, DB defaults, CI topology, release automation, runtime UI, package metadata,
or public docs in v1.55.
```

This wording is directly grounded in the Phase 204 boundary. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Anti-Patterns to Avoid

- **Ranking by cheapness:** D-08 says cheap work must not outrank public-truth, provider-proof, release-order, or schema-prefix confusion. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- **Treating CI cleanup as already measured:** Phase 202 has a partial GitHub snapshot but still labels p50/p95, cache health, slowest tests, flake rate, Docker cold/warm, and provider counts as metrics-needed. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]
- **Overclaiming provider proof:** The CI workflow labels `live-stripe` as schedule/manual, and the docs state Fake remains merge-blocking while live Stripe stays advisory. [VERIFIED: .github/workflows/ci.yml; VERIFIED: guides/testing-live-stripe.md]
- **Letting Phase 204 imply implementation:** The milestone is audit-only and roadmap-only. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- **Broad docs or portal redesign:** D-18 through D-20 defer broad redesign/rewrite unless tied to concrete adoption, production, support, or maintenance risk. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ranking model | New scoring algorithm or generic risk matrix | Locked D-07 ranking blend plus Phase 201-203 evidence | User decisions already define the ranking policy. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Roadmap artifact shape | Bespoke issue tracker format | Two-layer Markdown: top-10 table plus implementation cards | D-21 through D-26 define required columns, cards, and sections. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| CI evidence display | Ad hoc log scraping as the only proof | `$GITHUB_STEP_SUMMARY` and cache outputs for future CI baseline work | GitHub documents job summaries and cache-hit outputs. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] |
| Playwright browser optimization | Blind browser-binary cache | Measure install vs restore time first | Playwright official docs do not recommend browser binary caching by default, especially on Linux. [CITED: https://playwright.dev/docs/ci] |
| Schema prefix safety | `search_path` as the primary contract | `@schema_prefix`, migration prefixes, `qualified_table/1`, and agreement tests | Ecto documents schema prefixes and reflection, and Phase 203 rejects `search_path` as the primary contract. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md] |
| Release recovery order | Human memory in manual workflow prose | Future Hex/package preflight checks before downstream publish | `publish-hex.yml` currently relies on prose; Hex docs support dry-run/local checks. [VERIFIED: .github/workflows/publish-hex.yml; CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html] |

**Key insight:** The risky work in this phase is not code complexity; it is preserving evidence provenance, rank discipline, and the audit-only boundary while making future implementation cards actionable. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Reordering Back to the Draft Baseline

**What goes wrong:** The draft currently ranks CI timing summaries first, while locked D-11 ranks public toolchain/version truth first. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Why it happens:** The draft was created before the discuss-phase ranking decision set was locked. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**How to avoid:** Treat D-07 through D-11 as authoritative unless final audit evidence justifies a cited adjustment. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Warning signs:** The final top-10 starts with runtime speed or cheap work instead of public trust, evaluator clarity, provider truth, or release safety. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Pitfall 2: Turning Roadmap Cards Into Implementation Tasks

**What goes wrong:** The roadmap says "add", "fix", or "change" in ways that imply Phase 204 already changed files outside the roadmap artifact. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Why it happens:** Most top-10 items are concrete implementation candidates, so prose can drift into execution language. [VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md]  
**How to avoid:** Use "future slice", "follow-up implementation", and explicit non-goals/rollback fields. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Warning signs:** The final artifact claims CI summaries, schema guards, metadata, or portal docs now exist when only roadmap text changed. [VERIFIED: .planning/ROADMAP.md]

### Pitfall 3: Hiding Metrics-Needed Boundaries

**What goes wrong:** The roadmap recommends gate deletion, cache changes, branch-protection changes, or schedule-only moves without the Phase 202 baseline. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**Why it happens:** Static inspection already shows duplicated setup and repeated matrix gates, but Phase 202 says static evidence is insufficient for topology deletion. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**How to avoid:** Put CI baseline summaries before host setup consolidation, release-gate splitting, Docker policy, Playwright caching, and test classification. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Warning signs:** A CI card lacks a `Metrics/evidence needed` field or has rollback that cannot restore the old gate. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Pitfall 4: Overclaiming Provider Parity

**What goes wrong:** Fake, Stripe test-mode, Braintree local proof, and skipped live-provider lanes are presented as equivalent proof. [VERIFIED: guides/testing-live-stripe.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**Why it happens:** The workflow display name says mandatory periodic, but the lane is manual/scheduled and test modules can skip under missing secrets/fixtures. [VERIFIED: .github/workflows/ci.yml; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
**How to avoid:** Use proved, skipped/not proved, failed, advisory, and merge-blocking exactly. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Warning signs:** The roadmap says live Stripe "proves" parity without requiring a non-skipped run. [VERIFIED: guides/testing-live-stripe.md]

### Pitfall 5: Widening Portal Readiness Into UI Churn

**What goes wrong:** A narrow portal readiness row becomes a broad design-system/white-label redesign milestone. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Why it happens:** The folded todo documents real portal UI issues, including an unstyled `View details` link, but the phase only authorizes ranking future readiness work. [VERIFIED: .planning/todos/pending/2026-06-19-white-label-billing-portal-design-system.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**How to avoid:** Scope portal parity to setup, troubleshooting, theming boundary, proof path, and customer-facing readiness. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
**Warning signs:** The roadmap proposes new portal features or broad component work without concrete adoption/support/accessibility evidence. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Code Examples

Verified patterns from official and local sources:

### GitHub Actions Summary Pattern for Future CI Baseline Work

```yaml
- name: Append CI baseline summary
  run: |
    {
      echo "### CI baseline"
      echo ""
      echo "- cache hit: ${{ steps.cache-deps.outputs.cache-hit }}"
      echo "- Elixir: ${{ matrix.elixir }}"
      echo "- OTP: ${{ matrix.otp }}"
    } >> "$GITHUB_STEP_SUMMARY"
```

GitHub documents appending Markdown to `$GITHUB_STEP_SUMMARY`, and cache docs expose `cache-hit`. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]

### Schema Prefix Assertion Pattern for Future DB Hardening

```elixir
assert Accrue.Customer.__schema__(:prefix) == "billing"
```

Ecto documents `@schema_prefix` and `__schema__(:prefix)`, and Phase 203 specifically recommends representative prefix-agreement checks. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md]

### Implementation Card Skeleton

```markdown
### [Rank] [Change]

**Source evidence:** ...
**Reader/JTBD served:** ...
**Scope:** ...
**Non-goals:** ...
**Implementation approach:** ...
**Verification:** ...
**Rollback:** ...
**Metrics/evidence needed:** ...
```

These fields are locked by D-23 and should be present for every ranked implementation card. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Draft roadmap ranked CI timing summaries first. | Locked discussion ranks public toolchain/version truth first, then evaluator path, provider semantics, release recovery, CI baseline, schema guards, package metadata, host browser setup, release-gate split, and portal readiness. | Phase 204 discuss context gathered 2026-07-02. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] | Planner must update the draft top-10 order or cite stronger Phase 201-203 evidence for any deviation. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Single compact draft table and milestone notes. | Required two-layer artifact with top-10 table plus implementation cards. | Phase 204 discuss context gathered 2026-07-02. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] | Future planners/executors should not have to re-mine the audits. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Static CI optimization recommendations. | Measure-first baseline summaries before topology/cache/gate changes. | Phase 202 final audit 2026-07-02 and Phase 204 D-09. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] | Reduces risk of deleting proof rather than improving signal. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |
| Schema rename to `accrue` as a tempting polish fix. | Accepted contract keeps `billing`, preserves explicit `public`, and hardens prefix agreement instead. | Phase 203 accepted ADR 2026-07-02. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md] | Avoids upgrade risk and keeps the schema name domain-oriented. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md] |

**Deprecated/outdated:**

- Ranking CI runtime speed above public trust is outdated for Phase 204 because D-07 through D-11 lock adopter-proof release readiness as the ranking blend. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- Treating skipped `live-stripe` as proof is invalid because Phase 202 requires proved-vs-skipped separation. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]
- Default schema rename to `accrue` is explicitly out of scope and rejected by Phase 203. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md]

## Assumptions Log

All substantive claims in this research are tagged as verified from local artifacts or cited from official documentation. [VERIFIED: this RESEARCH.md source tags]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | No unverified assumptions are intentionally used. | n/a | n/a |

## Open Questions (RESOLVED)

1. **What exact CI metrics will future implementation collect?**  
   - What we know: Phase 202 lists p50/p95 runtime, step timings, cache-hit state, slowest tests, compile profile, flake/rerun rate, live-Stripe proved-vs-skipped counts, and Docker cold/warm duration. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md]  
   - RESOLVED: Phase 204 will not design the exact future scripts or workflow summary patches. The roadmap must name the Phase 202 metric families above as `Metrics/evidence needed` for CI-related cards and keep topology, cache, gate, branch-protection, Docker, and Playwright changes behind that baseline evidence. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-01-PLAN.md]
   - Roadmap consequence: CI cleanup recommendations stay as follow-up implementation cards, not Phase 204 implementation work. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

2. **Should any top-10 rank move from locked D-11?**  
   - What we know: D-11 permits slight reordering only with stronger evidence from the final Phase 201-203 artifacts. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]  
   - RESOLVED: No stronger contradictory evidence appeared during this research. The Phase 204 plan preserves the D-11 rank order: public toolchain/version truth, evaluator proof path, provider proved/skipped/advisory semantics, release recovery preflight, CI baseline summaries, schema-prefix hardening guards, package metadata/listing trust, host browser setup ownership after measurement, release-gate repetition split after baseline data, and narrow portal parity readiness. [VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-01-PLAN.md]
   - Roadmap consequence: future execution should implement the locked D-11 order unless a later phase records new source evidence and explicitly supersedes this resolution. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `git` | Evidence review and optional commit | yes | 2.41.0 | none needed [VERIFIED: environment probe] |
| `rg` | Fast local evidence checks | yes | 15.1.0 | `grep` if unavailable [VERIFIED: environment probe] |
| `node` | GSD tooling and docs commit helper | yes | v22.14.0 | none needed [VERIFIED: environment probe] |
| `npm` | Existing repo/browser evidence only | yes | 11.1.0 | not needed for Phase 204 [VERIFIED: environment probe] |
| `mix` / Elixir | Existing test framework context | yes | OTP 28 / Elixir runtime output present | not needed for Phase 204 content-only validation [VERIFIED: environment probe] |
| `gh` | Optional future CI run-history checks | yes | 2.95.0 | static audit evidence if not authenticated [VERIFIED: environment probe; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |

**Missing dependencies with no fallback:** none for Phase 204. [VERIFIED: environment probe]  
**Missing dependencies with fallback:** none for Phase 204. [VERIFIED: environment probe]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Markdown/content contract checks for Phase 204; existing repo uses ExUnit/Mix for implementation phases, but this phase should not run product tests as its primary gate. [VERIFIED: .planning/ROADMAP.md; VERIFIED: `rg --hidden --files -g '*_test.exs'`] |
| Config file | No Phase 204 test config; use `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` as the target artifact. [VERIFIED: `gsd-tools query init.phase-op 204`] |
| Quick run command | `test -f .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md && rg -n "Ranking method|Ranked Top 10|Implementation Cards|Suggested Follow-Up Milestones|Explicit Deferrals|Requirement Coverage|Phase Handoff and Boundary" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Full suite command | `rg -n "Source evidence|Reader/JTBD served|Non-goals|Verification|Rollback|Metrics/evidence needed|Phase 201|Phase 202|Phase 203" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| RD-01 | Ranked top-10 has required columns and done criteria. | content contract | `rg -n "Ranked Top 10|Area / quality dimension|Impact|Effort|Risk reduction|Timing / slice|Done criteria" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | yes, draft exists [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md] |
| RD-02 | Follow-up work is grouped into milestone-sized slices. | content contract | `rg -n "Suggested Follow-Up Milestones|Public Truth|Evaluator|CI Critical Path|Schema Prefix|Portal" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | yes, draft exists [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md] |
| RD-03 | Each implementation slice ties back to Phase 201-203 risks. | content contract | `rg -n "Source evidence|Phase 201|Phase 202|Phase 203|201-SOFTWARE|202-CI-CD|203-DB" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | yes, draft exists [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md] |
| RD-04 | Polish-only and overbuilt work is explicitly deferred. | content contract | `rg -n "Explicit Deferrals|polish|overbuilt|pixel-diff|schema rename|runtime performance|i18n|enterprise" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | yes, draft exists [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md] |

### Sampling Rate

- **Per task commit:** Run the quick content-contract command after editing the roadmap. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- **Per wave merge:** Run the full content-contract command and inspect the roadmap for audit-only boundary language. [VERIFIED: .planning/ROADMAP.md]
- **Phase gate:** Confirm `204-HARDENING-ROADMAP.md` contains required sections, top-10 columns, card fields, explicit deferrals, requirement coverage, and phase boundary text before `$gsd-verify-work`. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]

### Wave 0 Gaps

- [ ] Upgrade the draft `204-HARDENING-ROADMAP.md` from a compact baseline to the required two-layer artifact with implementation cards. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- [ ] Add a content-contract verification step to the plan because the target artifact is Markdown rather than executable code. [VERIFIED: .planning/ROADMAP.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 204 does not implement auth behavior. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| V3 Session Management | no | Phase 204 does not implement sessions or portal routes. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| V4 Access Control | no | Phase 204 does not implement authorization logic. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| V5 Input Validation | yes | Validate roadmap claims against Phase 201-203 evidence and local paths; do not accept unsourced recommendations. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md; VERIFIED: .planning/REQUIREMENTS.md] |
| V6 Cryptography | no direct implementation | Future provider-proof wording must preserve Stripe signature/replay semantics without changing webhook crypto in Phase 204. [VERIFIED: CLAUDE.md; CITED: https://docs.stripe.com/webhooks] |

### Known Threat Patterns for Phase 204

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Roadmap implies implementation happened in v1.55. | Spoofing / Repudiation | Add Phase Handoff and Boundary text saying the phase is roadmap-only. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md] |
| Provider proof overclaiming. | Spoofing | Use proved/skipped/not-proved/advisory/merge-blocking labels and cite `live-stripe` evidence. [VERIFIED: .github/workflows/ci.yml; VERIFIED: guides/testing-live-stripe.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |
| Release recovery order is treated as a checklist instead of a machine guard. | Tampering / Supply chain | Rank future recovery preflight checks before downstream publish. [VERIFIED: .github/workflows/publish-hex.yml; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |
| Schema-prefix drift is minimized as docs polish. | Tampering | Rank schema-prefix guards as data safety work and keep `billing` default. [VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md] |
| CI deletion is rationalized as performance work before measurement. | Denial of Service / Repudiation | Require baseline summaries and rollback before topology/cache changes. [VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md` - locked Phase 204 decisions, ranking rules, artifact shape, deferrals, and phase boundary. [VERIFIED: local read]
- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` - cross-quality weakness ranking, top-five deep dives, evidence appendix, and Phase 204 handoff. [VERIFIED: local read]
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` - CI/CD topology, metrics-needed boundaries, prioritized recommendations, and Phase 204 handoff rows. [VERIFIED: local read]
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` - accepted DB schema contract and future hardening rows. [VERIFIED: local read]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` - Phase 204 requirements, milestone posture, current state, and audit-only boundary. [VERIFIED: local read]
- `CLAUDE.md` - project constraints and GSD workflow instructions. [VERIFIED: local read]
- `brandbook/voice.md` and `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - voice system and adopter-first assessment lens. [VERIFIED: local read]

### Secondary (MEDIUM confidence)

- GitHub Actions workflow commands - job summaries through `GITHUB_STEP_SUMMARY`. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands]
- GitHub Actions dependency caching - `cache-hit` output and cache hit/miss behavior. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]
- Playwright CI docs - browser binary caching caution. [CITED: https://playwright.dev/docs/ci]
- Ecto Schema docs - `@schema_prefix` and `__schema__(:prefix)`. [CITED: https://ecto.hexdocs.pm/Ecto.Schema.html]
- Ecto query-prefix guide - search-path context for prefix behavior. [CITED: https://github.com/elixir-ecto/ecto/blob/master/guides/howtos/Multi%20tenancy%20with%20query%20prefixes.md]
- Hex publish docs and `mix hex.publish` docs - package metadata, publish, dry-run, docs publish, and revert/republish behavior. [CITED: https://hex.pm/docs/publish; CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html]
- Stripe webhook and billing testing docs - signature/replay, subscription webhook, and test-clock/testing boundaries. [CITED: https://docs.stripe.com/webhooks; CITED: https://docs.stripe.com/billing/subscriptions/webhooks; CITED: https://docs.stripe.com/billing/testing]
- Phoenix contexts and Plug docs - Phoenix-native vocabulary for roadmap cards. [CITED: https://phoenix.hexdocs.pm/contexts.html; CITED: https://phoenix.hexdocs.pm/plug.html]

### Tertiary (LOW confidence)

- None used for recommendations. [VERIFIED: this research source list]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - No new package stack; local Markdown artifacts and repo tools are verified. [VERIFIED: `gsd-tools query init.phase-op 204`; VERIFIED: environment probe]
- Architecture: HIGH - Phase boundary, target artifact, and upstream audit dependencies are locked in roadmap/context. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
- Pitfalls: HIGH - Pitfalls are direct synthesis from locked decisions and Phase 201-203 audit findings. [VERIFIED: .planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md; VERIFIED: .planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md; VERIFIED: .planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md]

**Research date:** 2026-07-02  
**Valid until:** 2026-08-01 for Phase 204 planning, unless Phase 201-203 artifacts or locked context decisions change. [VERIFIED: .planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md]
