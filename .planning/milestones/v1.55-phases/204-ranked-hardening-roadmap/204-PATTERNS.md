# Phase 204: Ranked Hardening Roadmap - Pattern Map

**Mapped:** 2026-07-03  
**Files analyzed:** 1  
**Analogs found:** 1 / 1

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` | documentation artifact | transform | `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` plus Phase 201-203 audit artifacts | exact/self + supporting analogs |

## Pattern Assignments

### `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` (documentation artifact, transform)

**Primary analog:** `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`

**Supporting analogs:**

- `.planning/phases/201-software-quality-evaluation/201-SOFTWARE-QUALITY-AUDIT.md`
- `.planning/phases/202-ci-cd-performance-and-determinism-audit/202-CI-CD-PERFORMANCE-AUDIT.md`
- `.planning/phases/203-database-schema-contract-adr/203-DB-SCHEMA-CONTRACT-ADR.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-UI-SPEC.md`
- `brandbook/voice.md`

**Import/auth pattern:** Not applicable. This is a Markdown planning artifact. Do not add runtime imports, source code, CI workflows, package metadata, routes, CSS, public docs, or product behavior changes.

**Current draft pattern to preserve selectively** (lines 1-20):

```markdown
# Hardening Roadmap After v1.55 Audits

**Date:** 2026-07-01  
**Status:** Phase 204 draft baseline  
**Purpose:** Convert the v1.55 audit findings into implementation-sized follow-up work.

## Ranked Top 10 Changes

| Rank | Change | Area | Improves | Impact | Effort | Risk Reduction | Timing | Done Looks Like |
|---:|---|---|---|---|---|---|---|---|
```

Use the draft's compact table-first scan path, but update the status, rank order, section names, and table columns to the locked Phase 204 contract.

**Required document interaction pattern** (204-UI-SPEC lines 46-58):

```markdown
| First scan | Put `How to read this roadmap`, `Ranking method`, and `Ranked Top 10` before implementation cards. The top-10 table is the maintainer's first decision surface. |
| Ranked table | Use exactly these columns: `Rank`, `Change`, `Area / quality dimension`, `Impact`, `Effort`, `Risk reduction`, `Timing / slice`, `Done criteria`. Keep each table cell to one compact sentence or phrase. Move detail into cards. |
| Cards | Use one card per ranked item with heading format `### Rank N - {Change}`. Field order is fixed: `Source evidence`, `Reader/JTBD served`, `Scope`, `Non-goals`, `Implementation approach`, `Verification`, `Rollback`, `Metrics/evidence needed`. |
| Evidence links | Every ranked row and card must cite Phase 201, Phase 202, or Phase 203 evidence. Use local path references where available. Do not introduce unsourced preferences. |
| Boundary language | Use future-tense implementation language. The roadmap must say Phase 204 ranks future work and did not implement behavior. |
| Deferrals | Place `Explicit Deferrals` after follow-up milestones. Deferrals must explain the risk threshold that would reopen the work. |
```

Copy this section order into the final roadmap:

```markdown
## How to read this roadmap
## Ranking method
## Ranked Top 10
## Implementation Cards
## Suggested Follow-Up Milestones
## Explicit Deferrals
## Requirement Coverage
## Phase Handoff and Boundary
```

**Core transform pattern: evidence ranking table** (201-SOFTWARE-QUALITY-AUDIT lines 21-34):

```markdown
## Dimension Ranking Table

| Rank | Dimension | Score | Confidence | Evidence | Practical consequence | Highest-leverage fix | Priority |
|---:|---|---:|---|---|---|---|---|
| 1 | CI/CD and automation | 3 | High | `.github/workflows/ci.yml`; `scripts/ci/README.md`; `examples/accrue_host/mix.exs` | Slow or opaque required checks weaken trust and maintainer flow | Measure timings, split duplicated gates, clarify live/provider semantics | should fix before broad public push |
| 2 | Adoption ease | 3 | High | `README.md`; `accrue/README.md`; `examples/accrue_host/README.md`; adoption matrix | New evaluator may not know which path proves value fastest | One evaluator path with 3-5 commands and pass/fail criteria | should fix before broad public push |
| 4 | Release quality / version truth | 3 | High | `CONTRIBUTING.md` says Elixir 1.17+/OTP 27+; packages use `~> 1.19`; CI uses OTP 28 | Public version truth drift damages trust | Public truth audit and same-source toolchain/version table | must fix before next release-readiness pass |
```

Use this style for ranking: concrete evidence path, practical consequence, fix, and timing. Do not rank by generic best practices.

**Implementation card evidence pattern** (201-SOFTWARE-QUALITY-AUDIT lines 64-78):

```markdown
### 1. CI/CD Efficiency and Signal Fidelity

**What I observed:** CI is comprehensive but likely over-coupled. Static dependency shape makes the critical path `release-gate -> admin-drift-docs -> host-integration -> playwright-e2e -> annotation-sweep`. `release-gate` repeats package work across four matrix cells. Host and Playwright lanes duplicate dependency/browser setup.

**Why it matters:** Required gates must be fast enough to respect maintainer time and precise enough that "green" means the promised risk was actually tested.

**Evidence from repo:** `.github/workflows/ci.yml`; `scripts/ci/accrue_host_uat.sh`; `scripts/ci/accrue_host_verify_browser.sh`; `examples/accrue_host/mix.exs`.

**Fix first:** Add timing/summary instrumentation and split compatibility-proof work from repeated lint/docs/audit work. Do not delete gates until measured.

**Do not over-fix:** Do not replace the pipeline with clever reusable workflow indirection before measuring.
```

Translate this into the Phase 204 card fields: `Source evidence`, `Reader/JTBD served`, `Scope`, `Non-goals`, `Implementation approach`, `Verification`, `Rollback`, and `Metrics/evidence needed`.

**Required card skeleton** (204-RESEARCH lines 371-386):

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

Use heading format from the UI spec: `### Rank N - {Change}`.

**CI metrics-needed pattern** (202-CI-CD-PERFORMANCE-AUDIT lines 38-52):

```markdown
## Baseline Metrics Needed

Static inspection is not enough to tune this safely. The collected 10-run snapshot is partial and cannot replace a baseline. It does show that recent successful push runs are roughly 34 minutes end to end, but it is not enough to declare p95, flake rate, cache health, or safe gate removals.

Collect these before changing topology:

- **metrics-needed:** p50/p95 wall time by workflow and job for at least the last 20-50 comparable non-release and release-adjacent runs.
- **metrics-needed:** step timings for `release-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`, admin guardrails, and `annotation-sweep`.
- **metrics-needed:** cache-hit state, cache miss state, restore time, save time, and cache sizes for BEAM deps, PLTs, npm, and any future Playwright browser cache.
- **metrics-needed:** top 20 slowest ExUnit tests per package via `mix test --slowest 20` and slowest modules where useful.
- **metrics-needed:** scheduled `live-stripe` proved-vs-skipped count, with proved requiring Stripe test mode execution against required secrets and fixtures.
```

Apply this to ranks about CI baseline, host browser setup, release-gate split, Docker/Playwright policy, and test value classification. Any CI cleanup card must keep topology/cache/gate changes behind baseline evidence.

**Handoff row pattern for implementation-grade cards** (202-CI-CD-PERFORMANCE-AUDIT lines 296-311):

```markdown
## Phase 204 Handoff

These rows are local CI/CD priorities for Phase 202. They are rankable inputs for Phase 204, not final cross-audit ordering and not issue-ready implementation cards.

| Area | Evidence path | Current risk | Priority local to Phase 202 | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric-needed status | Suggested milestone-slice fit |
|---|---|---|---|---|---|---|---|---|---|---|
| CI baseline summaries | `.github/workflows/ci.yml`, `Baseline Metrics Needed`, partial run `28538686414` | Maintainer cannot see timings, cache-hit state, slowest tests, or provider proved-vs-skipped state in one run summary | P0 | Turns optimization from static inference into measured evidence | Adds small summary maintenance surface | Add `$GITHUB_STEP_SUMMARY` blocks for versions, cache-hit state, key step timings, slowest tests where cheap, and provider status | Two comparable CI runs show summary fields; no gate removed | Remove summary steps | Required before topology cleanup | Small measurement-first hardening slice |
| Release recovery preflight | `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `scripts/ci/verify_release_contract.sh` | Manual recovery can publish admin/portal before upstream package availability because order is prose | P1 | Reduces same-day release recovery risk | Adds Hex/API checks to a manual recovery path | Add preflight checks for upstream package version/tag/public Hex state before downstream publish | Out-of-order recovery attempt fails before publish; valid order still dry-runs | Remove preflight step | Needs current Hex/package state during implementation | Release confidence slice |
```

Use this as the source for CI and release roadmap cards. Convert row columns into card fields rather than leaving all details in a wide table.

**DB hardening handoff pattern** (203-DB-SCHEMA-CONTRACT-ADR lines 118-130):

```markdown
## Phase 204 Handoff

Phase 204 should rank these rows against the Phase 201 software-quality audit and the Phase 202 CI/CD audit. These are local DB-schema-contract inputs only, not final cross-audit ordering and not issue-ready implementation cards. Phase 203 does not implement the checks below.

| Area | Evidence path | Current risk | Expected impact | Tradeoff | Implementation approach | Verification | Rollback | Metric/evidence-needed status | Non-goals |
|---|---|---|---|---|---|---|---|---|---|
| Centralize default `billing` schema constant | `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/schema.ex`, `accrue/lib/accrue/install/options.ex`, `examples/accrue_host/config/config.exs` | The default appears as repeated `"billing"` literals across executable and mirror surfaces. Drift could make generated config, compiled schemas, and examples disagree. | One named default reduces support-contract drift and makes future changes deliberate. | Adds a shared constant surface that must avoid compile-time dependency cycles. | Centralize the default in the lowest safe module or generated constant pattern, then route config/schema/installer/example checks through it. | Focused tests prove default generated config, `Accrue.Config`, and representative `Accrue.Schema` prefix all agree. | Revert to literals if the constant introduces compile-order friction. | Evidence exists; Phase 204 needs final ranking and implementation design. | No default rename and no runtime behavior change. |
| Add raw SQL qualification guard | `accrue/lib/accrue/migration.ex`, `accrue/lib/accrue/analytics/dunning.ex`, `scripts/ci/accrue_host_seed_e2e.exs` | Unqualified raw SQL references to Accrue-owned `accrue_*` tables could bypass configured schema placement through `search_path`. | Prevents accidental schema-unsafe SQL from entering Accrue-owned code. | A static check needs an allowlist for generated migrations, docs snippets, and approved helper definitions. | Add a grep/Credo-style guard that flags raw SQL `accrue_*` table names outside `Accrue.Migration.qualified_table/1` and approved helper code. | A negative fixture fails when an unqualified table is introduced; existing qualified callsites pass. | Remove the guard or narrow its allowlist if it blocks legitimate helper code. | Needs candidate command and false-positive sample before final rollout. | No SQL rewrite in Phase 203 and no `search_path` contract. |
```

Use this as the source for the schema-prefix hardening card. Keep `billing`, preserve explicit `public`, and do not suggest a default rename.

**Boundary and non-goal pattern** (203-DB-SCHEMA-CONTRACT-ADR lines 132-162):

```markdown
## Non-Goals

- Do not change the default schema from `billing` to `accrue`.
- Do not use Postgres `search_path` as the primary Accrue contract.
- Do not implement schema-prefix hardening in Phase 203.
- Do not change current defaults, database schemas, migrations, installer behavior, source code, runtime behavior, public docs defaults, CI topology, package metadata, or product surface.

## Verification

Future implementation should prove that schema prefix, migration prefix, docs, installer output, and example host all agree.

Phase 203 verification is markdown/content verification because schema-relevant files are evidence only. If any implementation, public docs mirror, CI, package metadata, example-host, or script file changes while executing this phase, that violates the boundary and requires stopping or rerouting to an implementation milestone.
```

Copy this boundary style for Phase 204, adapted to roadmap-only work.

**Phase handoff boundary pattern** (202-CI-CD-PERFORMANCE-AUDIT lines 323-335):

```markdown
## Phase Handoff and Boundary

Phase 202 is an **audit-only** gate. It produced the specialist CI/CD evidence that Phase 204 will rank alongside Phase 201 software-quality findings and Phase 203 database schema-contract findings. Phase 202 priorities are local CI/CD priorities; Phase 204 owns final cross-audit ordering and implementation slicing.

The Phase 202 gate did **not** change CI workflow topology, branch protection, package release automation, runtime behavior, public APIs, DB defaults, UI implementation, required-check semantics, source trees, workflow files, release workflows, script behavior, public docs, or package metadata. Static recommendations in this file are not implementation changes.
```

Phase 204 should use the same plain boundary language: the roadmap ranks future work and does not implement the hardening items.

**Requirement coverage pattern** (REQUIREMENTS lines 31-36 and 55-76):

```markdown
### Hardening Roadmap

- [ ] **RD-01**: Maintainer gets a ranked top-10 hardening list with area, quality dimension improved, impact, effort, risk reduction, timing, and done criteria.
- [ ] **RD-02**: Follow-up work is grouped into milestone-sized slices rather than one giant cleanup grab bag.
- [ ] **RD-03**: The roadmap ties every recommended implementation slice back to concrete risk found in the audits.
- [ ] **RD-04**: The roadmap explicitly defers polish-only or overbuilt work that does not reduce adoption, production, support, or maintenance risk.

| RD-01 | Phase 204 | Pending |
| RD-02 | Phase 204 | Pending |
| RD-03 | Phase 204 | Pending |
| RD-04 | Phase 204 | Pending |
```

Add a `Requirement Coverage` table mapping RD-01 through RD-04 to final roadmap sections.

**Validation pattern** (204-RESEARCH lines 437-461):

```markdown
| Quick run command | `test -f .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md && rg -n "Ranking method|Ranked Top 10|Implementation Cards|Suggested Follow-Up Milestones|Explicit Deferrals|Requirement Coverage|Phase Handoff and Boundary" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` |
| Full suite command | `rg -n "Source evidence|Reader/JTBD served|Non-goals|Verification|Rollback|Metrics/evidence needed|Phase 201|Phase 202|Phase 203" .planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md` |
```

Use these as the plan's content-contract verification commands.

**Voice pattern** (brandbook/voice.md lines 11-18, 21-33):

```markdown
**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does — no superlatives, no adjective-led marketing copy.

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths.

**Native.** Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts.

| State the mechanism | Name the benefit without naming the mechanism |
| Use plain present tense: "Accrue owns the billing engine" | Hedge with "helps you," "makes it easy to," "lets you" |
| Write proof-checkable sentences | Write any sentence that can't be verified by reading the source |
```

Use mechanism-led prose. Avoid the banned broad claims below.

**Avoid-language pattern** (brandbook/voice.md lines 100-119):

```markdown
| production-grade | Banned adjective (D-10) — name the mechanism instead |
| seamless | Meaningless filler; every library claims it |
| robust | Adjective-led; says nothing checkable |
| easy | Condescending and false — integration has real setup steps |
| effortless | Same as easy; patronizing |
| simple | Same register problem; prefer naming the actual effort |
```

## Shared Patterns

### Audit-Only Boundary

**Source:** `.planning/ROADMAP.md` lines 121-132  
**Apply to:** `204-HARDENING-ROADMAP.md`

```markdown
**Goal:** Produce `204-HARDENING-ROADMAP.md`, grouping follow-up implementation work by priority, milestone shape, impact, effort, risk reduction, and done criteria.
**Depends on:** Phases 201, 202, and 203
**Requirements:** RD-01, RD-02, RD-03, RD-04

1. Follow-up implementation work is ranked from the Phase 201-203 audit evidence, not from unsourced preferences.
2. Each proposed hardening slice includes priority, milestone shape, impact, effort, risk reduction, and done criteria.
3. Polish-only work is deferred unless it reduces adoption, production, support, or maintenance risk.
4. The roadmap preserves the v1.55 audit-only boundary and does not imply implementation happened in this milestone.
```

### Rank Order

**Source:** `.planning/phases/204-ranked-hardening-roadmap/204-RESEARCH.md` lines 388-401  
**Apply to:** `Ranked Top 10` and card order

```markdown
| Draft roadmap ranked CI timing summaries first. | Locked discussion ranks public toolchain/version truth first, then evaluator path, provider semantics, release recovery, CI baseline, schema guards, package metadata, host browser setup, release-gate split, and portal readiness. |

- Ranking CI runtime speed above public trust is outdated for Phase 204 because D-07 through D-11 lock adopter-proof release readiness as the ranking blend.
- Treating skipped `live-stripe` as proof is invalid because Phase 202 requires proved-vs-skipped separation.
- Default schema rename to `accrue` is explicitly out of scope and rejected by Phase 203.
```

### Evidence-First Claims

**Source:** `201-SOFTWARE-QUALITY-AUDIT.md` lines 228-256  
**Apply to:** all ranked rows and implementation cards

```markdown
This appendix is the QLT-05 evidence map. Static repository evidence is the primary source. Bounded command output supports confidence; it is not a full release proof. When a claim needs live CI history, a live provider account, branch-protection settings, external scorecards, or production traffic data, it is labeled **metrics-needed** or **Assumption**.

| Release quality / version truth | `CONTRIBUTING.md`; `accrue/mix.exs`; `accrue_admin/mix.exs`; `accrue_portal/mix.exs`; `.github/workflows/ci.yml`; `RELEASING.md` | Public setup says Elixir 1.17+/OTP 27+ while package manifests and CI are on Elixir 1.19/OTP 28 | Direct repo fact |
```

### Provider Proof Semantics

**Source:** `201-SOFTWARE-QUALITY-AUDIT.md` lines 265-268 and `204-RESEARCH.md` lines 329-334  
**Apply to:** provider-proof roadmap row/card

```markdown
`guides/testing-live-stripe.md` and `accrue/test/live_stripe` are advisory Stripe test-mode/provider-parity proof. They are useful evidence that Accrue watches real Stripe API drift for 3DS, Connect, and proration shapes. They are **not** a required Phase 201 gate, not the canonical local demo, and not the merge-blocking Fake-backed proof lane.

**How to avoid:** Use proved, skipped/not proved, failed, advisory, and merge-blocking exactly.
```

### Measure-Before-CI-Cleanup

**Source:** `202-CI-CD-PERFORMANCE-AUDIT.md` lines 147-160 and 287-294  
**Apply to:** CI baseline, host browser setup, release-gate split, Docker/Playwright policy, test classification

```markdown
| P0 | CI baseline summaries | Measurement | No timing/cache summary artifact | Add summaries for versions, cache-hit state, key step timings, and slowest tests where cheap | High | Low | Compare two comparable runs and check summary fields | Remove summaries |
| P1 | Split release-gate check classes | Runtime | Matrix repeats package gates | After p50/p95 and step timing baseline, run lint/docs/audit once and keep compatibility tests in matrix | High | Medium | Same failures caught; p95 PR runtime improves | Restore old job |

- **metrics-needed:** Runtime p50/p95, step timings, cache-hit state, slowest tests, compile profile, Docker cold/warm duration, failure/rerun rate, and live-Stripe proved-vs-skipped counts need a larger GitHub Actions and local diagnostic baseline.
- **metrics-needed:** Any branch-protection or required-check finalizer recommendation requires live branch-protection data and reviewer workflow impact before changing required-check semantics.
```

### Schema-Prefix Contract

**Source:** `203-DB-SCHEMA-CONTRACT-ADR.md` lines 21-50 and 73-92  
**Apply to:** schema-prefix hardening roadmap row/card

```markdown
Accrue's current contract is intentionally small:

- Accrue MUST keep `billing` as the default Accrue-owned Postgres schema for v1.55 and v1.x.
- Accrue MAY support explicit `public` when a host opts in because it intentionally wants Accrue tables in the default schema.
- Accrue MUST NOT rename the default schema to `accrue` in this milestone.
- Accrue MUST NOT rely on PostgreSQL `search_path` as its primary schema contract.

| `Accrue.Config` | Defines the `:billing_schema` default, option docs, and identifier validation. | `accrue/lib/accrue/config.ex` |
| `Accrue.Schema` | Applies the compile-time Ecto `@schema_prefix` used by Accrue-owned schemas. | `accrue/lib/accrue/schema.ex` |
| `Accrue.Migration` | Creates the configured schema and centralizes migration prefix helpers plus raw SQL table qualification. | `accrue/lib/accrue/migration.ex` |
```

### Portal Readiness Boundary

**Source:** `201-SOFTWARE-QUALITY-AUDIT.md` lines 112-126 and `204-RESEARCH.md` lines 336-341  
**Apply to:** portal parity roadmap row/card

```markdown
**What I observed:** `accrue_portal` exists as a sibling package and has tests, but its docs and public narrative are thinner than core/admin.

**Fix first:** Portal readiness pass: install, auth/session, CSP, theming/customization, Braintree flow, troubleshooting, release notes.

**Do not over-fix:** Do not build new portal features until the existing contract is easier to adopt.

**How to avoid:** Scope portal parity to setup, troubleshooting, theming boundary, proof path, and customer-facing readiness.
```

### Required Section Labels and Voice

**Source:** `204-UI-SPEC.md` lines 124-140  
**Apply to:** all roadmap headings and provider-proof wording

```markdown
- `How to read this roadmap`
- `Ranking method`
- `Ranked Top 10`
- `Implementation Cards`
- `Suggested Follow-Up Milestones`
- `Explicit Deferrals`
- `Requirement Coverage`
- `Phase Handoff and Boundary`

- Use measured, exact, Phoenix-native, mechanism-led, proof-checkable prose from `brandbook/voice.md`.
- Prefer terms such as `Fake processor`, `merge-blocking CI`, `live-stripe`, `@schema_prefix`, `Accrue.Migration.qualified_table/1`, `mix task`, `ExUnit`, `Playwright`, and `Hex` when they are the actual mechanism.
- Avoid broad claims such as "easy", "seamless", "robust", and "production-grade" unless quoting source text.
- Use "proved", "skipped/not proved", "advisory", and "merge-blocking" exactly when describing provider proof semantics.
```

## No Analog Found

No target file lacks an analog. There are no runtime controller, service, model, migration, middleware, component, route, hook, provider, or store files in Phase 204 scope. Source-code analogs are intentionally not applicable because the phase is roadmap-only.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | n/a | n/a | The only target file is a Markdown roadmap artifact with direct phase-artifact analogs. |

## Metadata

**Analog search scope:** `.planning/phases`, `.planning`, `brandbook`, `prompts`  
**Files scanned:** Markdown phase artifacts and support docs via `rg --files` / `rg -n`; primary analogs read: 204 draft roadmap, 201 audit, 202 audit, 203 ADR, 204 UI spec, roadmap, requirements, voice, and milestone prompt.  
**Project instructions:** No `AGENTS.md` file was present in the project root; no project-local `.codex/skills` or `.agents/skills` directories were present.  
**Pattern extraction date:** 2026-07-03
