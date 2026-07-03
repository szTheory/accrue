# Phase 201: Software Quality Evaluation - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 1
**Analogs found:** 1 / 1 primary, plus 4 supporting cross-artifact analogs

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | documentation / audit artifact | batch transform | `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` | exact-self baseline |

## Pattern Assignments

### `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md` (documentation / audit artifact, batch transform)

**Primary analog:** `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`

**Supporting analogs:**

- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` for CI specialist handoff and dynamic-metric boundaries.
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` for DB schema handoff, future hardening, and non-goals.
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` for Phase 204-ready recommendation rows and milestone slicing.
- `brandbook/voice.md` for measured, exact, Phoenix-native, proof-checkable audit wording.
- `.planning/REQUIREMENTS.md` for QLT-01 through QLT-05 acceptance shape.

**Artifact header pattern** (lines 1-5):

```markdown
# Software Quality Audit: Accrue v1.55

**Date:** 2026-07-01  
**Status:** Phase 201 draft baseline  
**Scope:** `accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`, public docs, planning mirrors, CI/release posture.
```

**Executive summary pattern** (lines 7-19):

```markdown
## Executive Summary

**Weakest dimension:** CI/CD efficiency, signal fidelity, and release-lane truth  
**Score:** 3/5  
**Why weakest:** CI is serious and high-signal, but static inspection shows duplicated setup, repeated package gates across matrix cells, phase-specific browser guardrails that overlap, a long critical path, live-Stripe semantics that can appear green while skipping, and compatibility labels that may not prove what they claim.  
**If ignored:** Maintainers lose time, contributors wait longer for feedback, required checks become harder to trust, and release confidence degrades because "green" stops meaning one clear thing.
```

Copy this shape for the final summary: name the weakest dimension, score it, explain the repo-backed reason, and state the consequence in maintainer/adopter terms.

**Ranked scoring table pattern** (lines 21-30):

```markdown
## Dimension Ranking Table

| Rank | Dimension | Score | Confidence | Evidence | Practical consequence | Highest-leverage fix | Priority |
|---:|---|---:|---|---|---|---|---|
| 1 | CI/CD and automation | 3 | High | `.github/workflows/ci.yml`; `scripts/ci/README.md`; `examples/accrue_host/mix.exs` | Slow or opaque required checks weaken trust and maintainer flow | Measure timings, split duplicated gates, clarify live/provider semantics | should fix before broad public push |
```

Keep the ranked table as the core QLT-01 surface. Every low score must cite local paths in the `Evidence` column or be labeled as an assumption elsewhere.

**Top-five deep dive pattern** (lines 64-78):

```markdown
### 1. CI/CD Efficiency and Signal Fidelity

**What I observed:** CI is comprehensive but likely over-coupled. Static dependency shape makes the critical path `release-gate -> admin-drift-docs -> host-integration -> playwright-e2e -> annotation-sweep`. `release-gate` repeats package work across four matrix cells. Host and Playwright lanes duplicate dependency/browser setup.

**Why it matters:** Required gates must be fast enough to respect maintainer time and precise enough that "green" means the promised risk was actually tested.

**Evidence from repo:** `.github/workflows/ci.yml`; `scripts/ci/accrue_host_uat.sh`; `scripts/ci/accrue_host_verify_browser.sh`; `examples/accrue_host/mix.exs`.

**User pain:** Contributors wait on expensive gates without knowing which failure matters.

**Maintainer pain:** Debugging CI drift becomes a release job, not a quick fix.

**Fix first:** Add timing/summary instrumentation and split compatibility-proof work from repeated lint/docs/audit work. Do not delete gates until measured.

**Do not over-fix:** Do not replace the pipeline with clever reusable workflow indirection before measuring.
```

Use this repeated block for each top weakness: observation, consequence, evidence paths, user/maintainer pain where relevant, first fix, and explicit restraint.

**Journey audit matrix pattern** (lines 128-143):

```markdown
## Adoption Friction Audit

| Step | Friction | Likely confusion | Highest-leverage fix |
|---|---|---|---|
| Landing on README | Moderate | Proof-path detail appears before simplest mental model | Keep proof, add "30-second evaluator path" |
| Understanding problem | Low | Broad "everything SaaS billing" surface | Add "use / do not use" box |
| Deciding fit | Medium | Stripe/Braintree/Fake boundaries are long | Short provider truth matrix |
```

Copy this for adopter, production/SRE, maintainer, and other journey sections: user step, friction or current state, confusion/risk, and one highest-leverage fix.

**UI/design-system evidence pattern** (lines 160-171):

```markdown
## UI/UX and Design-System Audit

Accrue has UI: `accrue_admin` and `accrue_portal`.

`accrue_admin` looks useful enough to ship and unusually coherent after v1.53/v1.54: design specs, Storybook, component lab, page-flow gates, and accessibility checks exist. The top UI risk is no longer obvious visual inconsistency; it is regression-gate cost and whether portal parity keeps up with admin polish.
```

Preserve the split between strong admin evidence and portal parity risk. Do not turn the folded PageHeader todo into a current weakness.

**GSD sanity / non-overbuild pattern** (lines 188-200):

```markdown
## GSD Sanity Check

**Probably overkill now:** broad runtime performance benchmarking, full enterprise governance, i18n, pixel-diff visual regression, schema rename to `accrue`.

**Not optional:** CI signal truth, public version/toolchain truth, schema-prefix contract clarity, release recovery guardrails, first evaluator path.
```

Use this section to separate hardening that matters before public push from work that should stay deferred or specialist-owned.

**Phase 204 recommendation pattern** (lines 212-225):

```markdown
## Top 10 Concrete Changes

| Rank | Area | Dimension improved | Why it matters | Impact | Effort | Risk reduction | Timing | Done looks like |
|---:|---|---|---|---|---|---|---|---|
| 1 | CI workflow | CI/CD | Shortens and clarifies required gates | High | Medium | High | before showing to strangers | timing baseline + target topology |
```

Planner should require final recommendations to stay rankable by Phase 204: area, quality dimension, impact, effort, risk reduction, timing, and done criteria.

## Shared Patterns

### Requirements Coverage

**Source:** `.planning/REQUIREMENTS.md`
**Apply to:** Entire audit artifact

Lines 8-14 define the acceptance shape:

```markdown
### Software Quality Evaluation

- [ ] **QLT-01**: Maintainer can read one evidence-backed audit that ranks Accrue's weakest adoption, production, maintenance, support, architecture, data, UI, security, release, upgrade, and OSS trust dimensions without treating every category as equally important.
- [ ] **QLT-02**: The audit identifies the top five weakness deep dives with repo evidence, practical consequences, highest-leverage fixes, and what not to over-fix.
- [ ] **QLT-03**: The audit separately covers adopter journey, production/SRE journey, maintainer journey, GSD sanity, and missing project-specific dimensions.
- [ ] **QLT-04**: The audit marks strong or not-applicable dimensions honestly instead of manufacturing fake concerns.
- [ ] **QLT-05**: The audit separates direct repo facts from assumptions and cites evidence paths for low scores.
```

### Evidence and Dynamic-Metric Boundary

**Source:** `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`
**Apply to:** CI/CD findings, test/QA findings, any runtime-duration claim

Lines 34-45 show how to record needed dynamic metrics without pretending static inspection measured them:

```markdown
## Baseline Metrics Needed

Static inspection is not enough to tune this safely. Collect:

- p50/p95 wall time by workflow and job for last 20-50 runs.
- Step timings for `release-gate`, `host-integration`, `playwright-e2e`, Docker smoke.
- Cache hit/miss rates and cache sizes for BEAM deps, PLTs, npm, Playwright browsers.
- Top 20 slowest ExUnit tests per package via `mix test --slowest 20`.
```

Lines 218-222 show the assumption pattern:

```markdown
## Assumptions

- Branch protection required-check list was inferred from workflow comments, not GitHub settings.
- Runtime durations require GitHub run history; this document does not claim measured p95 values yet.
```

### Specialist Handoff for DB Schema

**Source:** `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
**Apply to:** Schema-prefix safety and data/upgrade findings

Lines 77-88 show future hardening that Phase 201 should summarize, not implement:

```markdown
## Future Hardening Work

Add an implementation milestone for:

1. Centralize the default billing schema constant so `Config`, `Schema`, installer options/templates, docs tests, and example host cannot drift.
2. Add tests that representative Accrue schemas expose `__schema__(:prefix) == "billing"` under default config.
3. Add explicit test lanes for default `billing`, explicit `public`, and explicit `billing` compatibility.
```

Lines 89-95 define non-goals to preserve:

```markdown
## Non-Goals

- Do not rename tables.
- Do not move existing data automatically.
- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not put host-owned users, organizations, Oban jobs, or app tables under Accrue's schema.
```

### Phase 204-Ready Roadmap Rows

**Source:** `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`
**Apply to:** Final recommendations and hardening candidates

Lines 7-20 show the downstream table contract:

```markdown
## Ranked Top 10 Changes

| Rank | Change | Area | Improves | Impact | Effort | Risk Reduction | Timing | Done Looks Like |
|---:|---|---|---|---|---|---|---|---|
| 1 | Add CI timing/cache baseline summaries | `.github/workflows`, `scripts/ci` | CI/CD | High | Low | High | before showing to strangers | CI logs show versions, cache hits, key step timings, and slowest tests where cheap |
```

Lines 114-119 define the roadmap acceptance criteria:

```markdown
## Done Criteria for This Roadmap

- Each follow-up item traces to a concrete v1.55 audit finding.
- Each follow-up milestone can be implemented independently.
- No item is included because it is generally "best practice" without Accrue-specific risk.
- High-signal gates stay protected until measurement proves a safer shape.
```

### Brand Voice and Proof-Checkable Claims

**Source:** `brandbook/voice.md`
**Apply to:** All audit prose, summaries, score explanations, and recommendations

Lines 11-17 define the core voice:

```markdown
**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does — no superlatives, no adjective-led marketing copy. A measured sentence names a mechanism. "Every webhook is signature-verified before it touches your database" says more than "secure."

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths. Vague words ("it," "stuff," "various things") never appear in place of the actual noun. When a concept has a canonical name in the Elixir ecosystem, use it.

**Native.** Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts. It doesn't borrow Rails vocabulary, fintech marketing language, or generic SaaS prose.
```

Lines 123-136 define the claim posture:

```markdown
## Claims Posture

State capability as a mechanism or named artifact, not an adjective.

Substantiate strong claims with a verifiable mechanism the reader can inspect (VERIFY-01 proof path, merge-blocking CI, named schema field).
```

## No Analog Found

No classified implementation file is missing an analog. Phase 201 is audit-only and has an exact existing baseline artifact.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| none | n/a | n/a | n/a |

## Files Explicitly Out of Modification Scope

The following files are evidence inputs or specialist handoffs, not Phase 201 implementation targets:

| File | Use |
|------|-----|
| `.github/workflows/ci.yml` | CI evidence only; Phase 202 owns implementation recommendations. |
| `scripts/ci/README.md` | CI/support evidence only. |
| `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md` | Specialist handoff; cite and summarize, do not duplicate. |
| `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md` | Specialist handoff; cite and summarize, do not rewrite. |
| `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | Downstream target; keep recommendations consumable by it. |
| `accrue/lib/accrue/schema.ex`, `accrue/lib/accrue/migration.ex`, `accrue/lib/accrue/config.ex` | DB evidence only; no runtime/code changes in Phase 201. |
| `accrue_admin/*`, `accrue_portal/*` | UI evidence only; no UI/runtime implementation changes in Phase 201. |

## Metadata

**Analog search scope:** `.planning/phases`, `brandbook`, `.planning/REQUIREMENTS.md`  
**Files scanned:** 10 (`201` phase context/research/artifacts, Phase 202 audit, Phase 203 ADR, Phase 204 roadmap, brand voice, requirements, phase directory inventory)  
**Pattern extraction date:** 2026-07-02
