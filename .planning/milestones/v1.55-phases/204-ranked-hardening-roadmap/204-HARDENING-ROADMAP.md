# Phase 204 Ranked Hardening Roadmap

**Date:** 2026-07-03
**Status:** Complete Phase 204 roadmap
**Purpose:** Rank future hardening work after the Phase 201 software-quality audit, Phase 202 CI/CD audit, and Phase 203 schema-contract ADR.
**Boundary:** This artifact is roadmap-only. It orders future work; it does not implement product, CI, release, package, database, documentation, or UI changes.

## How to read this roadmap

Read the top table first. It gives the future hardening order, the quality dimension each item improves, and the evidence needed before implementation. The order is locked by Phase 204 context: trust and safety issues rank before convenience work, release and data safety outrank polish, and CI changes stay measurement-led.

The roadmap is written for four readers:

- Maintainers deciding which hardening PR to start next.
- Reviewers checking whether a future PR matches the evidence from Phases 201-203.
- Phoenix evaluators trying to understand the package proof path.
- Release and support maintainers avoiding proof, provider, and database contract footguns.

Each ranked item names a narrow slice. Items that need baseline data say so directly, especially CI timing, cache, provider, release-gate, and branch-protection changes.

## Ranking method

Ranking used the Phase 204 decision stack:

- **Trust and safety first:** public version truth, evaluator proof, provider-state clarity, release recovery, and schema-prefix guarantees reduce adopter and maintainer risk early.
- **Measurement before optimization:** CI timing, cache, provider, release-gate, topology, and branch-protection changes wait for baseline summaries from Phase 202 evidence.
- **Current contract before new contract:** Phase 203 keeps `billing` as the default prefix, keeps explicit `public` references, rejects `search_path` as the primary contract, and treats data movement as host-owned work.
- **Narrow readiness before broad redesign:** portal work is limited to parity readiness and documented host ownership until a later design-system or white-label phase.
- **Low-effort tie-breakers only after risk:** package listing cleanup and public truth checks are attractive because they are visible and bounded, not because polish outranks proof or release safety.

## Ranked Top 10

| Rank | Change | Area / quality dimension | Impact | Effort | Risk reduction | Timing / slice | Done criteria |
|---|---|---|---|---|---|---|---|
| 1 | Fix public toolchain/version truth | Public docs and OSS trust. Phase 201 found public drift between `CONTRIBUTING.md` and executable package/CI truth. | High: removes first-contact doubt for Phoenix adopters and maintainers. | Low | High: prevents evaluators from choosing the wrong Elixir, OTP, PostgreSQL, or Node floor. | Public Truth And Proof-State Baseline | Repo-local authority table cites package manifests and CI; public docs match it; a docs-contract check proves no stale floor survives. |
| 2 | Publish an evaluator proof path | Adoption proof and first-hour evaluation. Phase 201 found the proof path scattered across README, first-hour guide, host README, and testing docs. | High: lets a Phoenix evaluator run the right Fake processor proof without guessing. | Medium | High: reduces abandonment caused by unclear setup, proof tiers, or portal expectations. | Public Truth And Proof-State Baseline | One evaluator path names the merge-blocking Fake processor lane, host proof command, optional provider lanes, and expected evidence. |
| 3 | Clarify provider proved/skipped/advisory semantics | Provider parity and test confidence. Phase 201 and Phase 202 both found that `live-stripe` and provider lanes can look stronger than their actual evidence. | High: stops skipped advisory provider checks from being read as proof. | Medium | High: protects release and adoption decisions from false confidence. | Evaluator Path And Release Safety | Fake processor remains merge-blocking CI; provider runs report proved, skipped, or advisory with required secrets and fixtures named. |
| 4 | Add release recovery preflight for linked package order | Release safety. Phase 202 found release-gate duration and Phase 201 found linked package/version truth risk across Hex packages. | High: reduces risk when publishing linked packages and recovering a partial release. | Medium | High: prevents wrong-order publication and unclear recovery steps. | Evaluator Path And Release Safety | Preflight verifies linked package order, changelog/version consistency, and recovery commands before release automation changes. |
| 5 | Add CI timing/cache/provider baseline summaries | CI/CD performance and determinism. Phase 202 could inspect partial runs but requires richer baseline data before topology, cache, gate, or branch-protection changes. | Medium-high: gives maintainers data to choose the next CI cleanup without weakening signal. | Medium | Medium-high: avoids optimizing the wrong bottleneck or hiding skipped provider proof. | CI Critical Path Cleanup | Baseline before topology/cache/gate/branch-protection changes records p50/p95 job times, step timing, cache hit/miss data, provider states, and reruns. |
| 6 | Add schema-prefix hardening guards | Database contract safety. Phase 203 records `billing` as the default prefix, explicit `public` references, `@schema_prefix`, and `Accrue.Migration.qualified_table/1`. | Medium-high: protects host installs and upgrades from prefix drift. | Medium | High: prevents default-prefix, public-table, and raw-SQL qualification regressions. | Schema Prefix Contract Hardening | Tests and static checks preserve `billing`, explicit `public`, and qualified migration helpers without schema rename or data movement. |
| 7 | Align package metadata and public listing trust | OSS packaging and public evaluation. Phase 201 found package truth and public listing confidence tied to README, package metadata, and Hex surfaces. | Medium: improves evaluator confidence before install. | Low-medium | Medium: reduces mismatch between Hex/package pages and repo-local truth. | Public Truth And Proof-State Baseline | Package metadata, README package sections, and Hex listing copy mirror the same proof tiers, version floors, and package boundaries. |
| 8 | Assign host browser setup ownership after measurement | Host evaluation and browser proof. Phase 201 and Phase 202 found browser setup ownership split across docs and CI, with Playwright/cache decisions needing measurement first. | Medium: reduces friction in host proof runs without changing runtime UI. | Medium | Medium: prevents ambiguous Node, browser, and host-e2e setup failures. | CI Critical Path Cleanup | Baseline before cache/topology changes identifies browser install ownership, host command ownership, and measured failure modes. |
| 9 | Split release-gate repetition after baseline data | Release CI cost and determinism. Phase 202 saw long release-gate cells but requires baseline summaries before gate reshaping or branch-protection changes. | Medium: can reduce duplicate release checks once evidence identifies overlap. | Medium | Medium: keeps release confidence while removing measured repetition. | CI Critical Path Cleanup | Baseline before gate/topology/branch-protection changes proves which release-gate steps are duplicate, required, or advisory. |
| 10 | Prepare narrow portal parity readiness | Portal package readiness. Phase 201 and the pending white-label note found portal parity questions, but Phase 204 keeps broad redesign out of scope. | Medium: clarifies what the portal package proves and what hosts own. | Medium | Medium: prevents overpromising portal behavior before a later design-system phase. | Portal Parity Readiness | Portal readiness matrix names supported setup, provider expectations, host-owned styling, and follow-up design-system work. |

## Implementation Cards

### Rank 1 - Fix public toolchain/version truth

**Source evidence:** Phase 201 flagged public drift between `CONTRIBUTING.md`, package manifests, and CI floors; Phase 204 D-11 ranks this first because it is the first public trust check.
**Reader/JTBD served:** Phoenix evaluator and maintainer checking whether the repo can be trusted before local setup.
**Scope:** Future public truth update across the root contributor guide, package-facing docs, release notes pointers, and any docs-contract needles tied to Elixir, OTP, PostgreSQL, Node, and package versions.
**Non-goals:** No language/runtime upgrade, package metadata change, release automation change, or CI topology change is implied by this roadmap item.
**Implementation approach:** Treat executable files and CI as the source of truth, then mirror the same floor table into public docs with a verification check that fails on stale version claims.
**Verification:** Grep docs for version-floor claims, compare them to package/CI truth, and run the docs-contract check added by the future implementation.
**Rollback:** Revert the docs-contract needle and edited public truth table if it blocks a valid release; the executable package and CI files remain authoritative.
**Metrics/evidence needed:** Before/after grep output for every version floor, plus links to package manifest and workflow lines used as authority.

### Rank 2 - Publish an evaluator proof path

**Source evidence:** Phase 201 found evaluator proof split across README, `accrue/guides/first_hour.md`, `examples/accrue_host/README.md`, and testing guides.
**Reader/JTBD served:** Phoenix evaluator trying to prove the package locally in the first hour without reading every guide.
**Scope:** Future proof-path spine that names the Fake processor lane, host command, portal expectation, optional provider lanes, and expected proof artifacts.
**Non-goals:** No new example app, runtime route, provider behavior, or portal UI change.
**Implementation approach:** Add one evaluator sequence that points to existing commands and package boundaries, then update adjacent links so docs converge on that sequence.
**Verification:** Run the named Fake processor proof command in the host example, confirm link targets resolve, and verify the proof path distinguishes blocking and advisory lanes.
**Rollback:** Revert the proof-path doc addition if it creates link churn or conflicts with package docs; existing host and package guides remain available.
**Metrics/evidence needed:** Command output from the host Fake proof lane and link-check evidence for every referenced guide.

### Rank 3 - Clarify provider proved/skipped/advisory semantics

**Source evidence:** Phase 201 and Phase 202 both found `live-stripe` and provider lanes can be skipped or advisory while looking like proof in casual reading.
**Reader/JTBD served:** Maintainer, reviewer, and evaluator deciding whether provider coverage is proved, skipped, advisory, or outside the merge-blocking CI lane.
**Scope:** Future provider-state labels for Fake processor proof, Stripe test-mode runs, Braintree checkout coverage, advisory scheduled lanes, and missing-secret skips.
**Non-goals:** No new provider integration, no Stripe credential handling change, no requirement that advisory provider lanes become merge-blocking CI.
**Implementation approach:** Standardize provider result language as proved, skipped, or advisory; attach required secrets, fixtures, and command names to each state.
**Verification:** Run Fake processor checks, inspect `live-stripe` skip behavior without secrets, and run a provider lane only when required test-mode credentials exist.
**Rollback:** Revert label changes if they confuse release output; preserve Fake processor as the blocking proof lane while restoring prior text.
**Metrics/evidence needed:** Provider command transcript showing Fake proved, `live-stripe` skipped without secrets, and any future provider proved run with secret names redacted.

### Rank 4 - Add release recovery preflight for linked package order

**Source evidence:** Phase 202 highlighted release-gate duration and recovery risk; Phase 201 highlighted linked package/version trust across package surfaces and Hex.
**Reader/JTBD served:** Release maintainer publishing linked packages and needing preflight confidence before any publish step.
**Scope:** Future preflight for linked package order, package version alignment, changelog consistency, local package build checks, and recovery instructions for partial publish.
**Non-goals:** No release automation replacement, no publish credential change, no package splitting, and no CI gate reshaping before measurement.
**Implementation approach:** Add a preflight checklist or script that reads existing release metadata, confirms package order, and prints recovery guidance before publish.
**Verification:** Run the preflight in dry mode, compare output with release docs, and confirm package order matches dependency order.
**Rollback:** Remove the preflight script or checklist and fall back to existing release docs if it blocks a legitimate release.
**Metrics/evidence needed:** Dry-run transcript, package order proof, and release-gate timing from Phase 202 baseline work.

### Rank 5 - Add CI timing/cache/provider baseline summaries

**Source evidence:** Phase 202 measured partial workflow evidence but did not have durable p50/p95 timing, cache hit/miss, provider-state, or rerun summaries.
**Reader/JTBD served:** Maintainer deciding which CI cleanup to implement without weakening test signal.
**Scope:** Future baseline summaries for workflow wall time, job time, step time, cache behavior, provider state, reruns, Docker cold/warm timing, and release-gate cost.
**Non-goals:** No cache policy change, matrix split, gate removal, topology change, or branch-protection change before baseline data exists.
**Implementation approach:** Collect and publish a short CI baseline artifact first, then use it to rank follow-up cleanup PRs.
**Verification:** Compare multiple workflow runs, record p50/p95 where available, and verify skipped provider lanes are labeled separately from proved lanes.
**Rollback:** Remove the baseline artifact if it proves noisy or misleading; do not roll back CI gates because this item does not change them.
**Metrics/evidence needed:** Run IDs, job timings, step timings, cache hit/miss data, rerun counts, provider proved/skipped/advisory states, and release-gate timing.

### Rank 6 - Add schema-prefix hardening guards

**Source evidence:** Phase 203 records the current contract: default `billing`, explicit `public` references, compile-time `@schema_prefix`, and `Accrue.Migration.qualified_table/1` for qualified migration SQL.
**Reader/JTBD served:** Maintainer protecting host installs from prefix drift, raw SQL qualification errors, and accidental public-table regressions.
**Scope:** Future tests and static checks that enforce default `billing`, preserve explicit `public`, reject `search_path` as the primary contract, and keep migration helpers qualified.
**Non-goals:** No schema rename, no data movement, no default prefix change, no host migration rewrite, and no new DB table.
**Implementation approach:** Add targeted assertions around default prefix constants, explicit public schema usage, raw SQL qualification, and migration helper output.
**Verification:** Run schema-prefix tests, inspect generated SQL for qualification, and prove `@schema_prefix` remains aligned with the ADR.
**Rollback:** Revert the added guards if they reject valid host-owned custom-prefix setups; retain Phase 203 documented contract while adjusting the test scope.
**Metrics/evidence needed:** Failing/passing guard output, affected SQL snippets, and host custom-prefix fixture coverage if the future PR adds it.

### Rank 7 - Align package metadata and public listing trust

**Source evidence:** Phase 201 found public package trust tied to README/package truth, package metadata, docs links, and Hex listing expectations.
**Reader/JTBD served:** Evaluator deciding from Hex or package docs whether the package set is coherent and current.
**Scope:** Future package listing copy, package descriptions, README package table, docs links, and release metadata checks that mirror the same truth.
**Non-goals:** No package rename, ownership transfer, release cadence change, or package metadata rewrite beyond truth alignment.
**Implementation approach:** Use a single package truth map, update listing-facing copy from it, and add verification needles for package names, versions, docs URLs, and proof-state language.
**Verification:** Compare package metadata to README package sections and generated Hex-facing copy, then run the future metadata verifier.
**Rollback:** Revert metadata and listing text changes if Hex publishing requirements conflict; keep internal package manifests unchanged.
**Metrics/evidence needed:** Before/after package metadata diff, Hex preview output where available, and docs-link check output.

### Rank 8 - Assign host browser setup ownership after measurement

**Source evidence:** Phase 201 and Phase 202 found browser setup ownership split across contributor docs, host docs, Playwright shards, and CI cache assumptions.
**Reader/JTBD served:** Evaluator or contributor running host browser proof and needing to know who owns Node, browser install, and host setup failures.
**Scope:** Future ownership notes and measured cleanup for host browser setup, Playwright install behavior, host e2e command boundaries, and cache decisions.
**Non-goals:** No runtime UI, CSS, route, portal styling, or Playwright cache/topology change before baseline data.
**Implementation approach:** Use Phase 202 CI baseline data to name current browser setup cost and then document ownership for host runs and CI runs separately.
**Verification:** Run the host browser proof command, record setup timing, and confirm docs identify setup ownership without changing UI code.
**Rollback:** Revert ownership docs or cache notes if they misclassify failures; leave host proof commands unchanged.
**Metrics/evidence needed:** Host browser setup timing, Playwright install timing, cache hit/miss data, and failure-mode examples from measured runs.

### Rank 9 - Split release-gate repetition after baseline data

**Source evidence:** Phase 202 observed long release-gate cells and suspected repetition, while also requiring baseline summaries before gate, topology, or branch-protection edits.
**Reader/JTBD served:** Release maintainer and CI maintainer choosing a lower-cost release gate without losing release confidence.
**Scope:** Future split or dedupe only after baseline data proves which release-gate steps are duplicate, required, advisory, or provider-specific.
**Non-goals:** No branch-protection edit, gate removal, cache rewrite, matrix collapse, or release automation change before baseline data.
**Implementation approach:** Start from the CI baseline summary, group release-gate steps by evidence value, then propose the smallest verified split.
**Verification:** Compare old and proposed release-gate evidence, prove blocking checks still cover release-critical paths, and record wall-time change.
**Rollback:** Restore the prior release-gate shape if the split hides a required proof signal or increases flake rate.
**Metrics/evidence needed:** Old/new release-gate timing, duplicate-step proof, flake/rerun counts, and mapping of each step to release evidence.

### Rank 10 - Prepare narrow portal parity readiness

**Source evidence:** Phase 201 and the pending white-label portal note found portal parity and styling questions, while Phase 204 explicitly defers broad portal redesign.
**Reader/JTBD served:** Portal reviewer, host maintainer, and evaluator checking what `accrue_portal` proves and what the host owns.
**Scope:** Future readiness matrix for portal package setup, provider expectations, route/mount assumptions, styling ownership, Braintree checkout branch notes, and follow-up design-system work.
**Non-goals:** No broad portal white-label redesign, no new runtime UI, no CSS overhaul, no route change, no portal feature expansion.
**Implementation approach:** Create a narrow portal readiness matrix that names current supported behavior and gaps without implementing the design-system phase.
**Verification:** Run existing portal package checks, verify links to portal docs, and confirm the matrix does not claim broader parity than evidence supports.
**Rollback:** Revert the readiness matrix if it overstates support; leave portal runtime code and host styling untouched.
**Metrics/evidence needed:** Portal docs link check, existing portal test output, and a future|follow-up issue reference for later white-label/design-system work.

## Suggested Follow-Up Milestones

### Public Truth And Proof-State Baseline

Purpose: close the public trust gap before deeper hardening work. This slice includes Rank 1, Rank 2, Rank 3 setup language, and Rank 7 listing truth where the same source map can serve all public surfaces.

Source evidence: Phase 201 found public toolchain/version drift, a scattered evaluator proof path, provider-proof ambiguity, and package/listing trust gaps; Phase 202 adds the merge-blocking CI versus provider-lane proof boundary.

Expected outputs:

- Repo-local version and package truth table.
- Evaluator proof path grounded in Fake processor and merge-blocking CI.
- Provider-state labels for proved, skipped, and advisory runs.
- Package metadata and Hex listing alignment checks.

### Evaluator Path And Release Safety

Purpose: make proof and release decisions safer once public truth is aligned. This slice carries Rank 3 provider semantics and Rank 4 release recovery preflight.

Source evidence: Phase 201 links provider-state clarity to evaluator trust and linked package/version truth; Phase 202 identifies `live-stripe` proved/skipped ambiguity, release-gate duration, and linked release-order recovery risk.

Expected outputs:

- Provider-state command examples with secret requirements named but not exposed.
- Linked package publish order preflight.
- Partial-release recovery guidance that matches release docs.
- Release-gate baseline dependency noted before automation changes.

### CI Critical Path Cleanup

Purpose: create measured CI evidence before changing gates, cache policy, topology, or branch-protection rules. This slice includes Rank 5, Rank 8, and Rank 9.

Source evidence: Phase 202 requires p50/p95 timing, step timing, cache hit/miss, provider-state, rerun, Docker, host browser, and release-gate baseline data before topology, cache, gate, or branch-protection changes; Phase 201 ties host browser setup ownership to first-hour proof friction.

Expected outputs:

- CI timing/cache/provider baseline summary.
- Host browser setup ownership record based on measured runs.
- Release-gate repetition proposal only after baseline data.
- Explicit proof that provider skips and advisory runs stay visible.

### Schema Prefix Contract Hardening

Purpose: turn the Phase 203 ADR into targeted guardrails while preserving host compatibility. This slice maps to Rank 6.

Source evidence: Phase 203 accepts the default `billing` prefix, explicit `public`, compile-time `@schema_prefix`, and `Accrue.Migration.qualified_table/1` contract while deferring schema rename and data movement.

Expected outputs:

- Tests for default `billing`, explicit `public`, and compile-time `@schema_prefix`.
- Static checks or focused tests for `Accrue.Migration.qualified_table/1`.
- Documentation mirror that keeps schema rename and data movement out of scope.
- Rollback notes for host custom-prefix compatibility.

### Portal Parity Readiness

Purpose: document narrow portal readiness before any broad design-system or white-label work. This slice maps to Rank 10.

Source evidence: Phase 201 and the pending portal design-system note identify portal parity and ownership questions; Phase 204 limits the slice to readiness proof instead of broad UI, CSS, route, or white-label redesign work.

Expected outputs:

- Portal readiness matrix.
- Host-owned styling and route ownership notes.
- Existing portal proof commands and provider expectations.
- Follow-up pointer for later design-system work.

## Explicit Deferrals

- **test-value classification:** Deferred until CI baseline summaries identify slow, duplicate, flaky, or low-signal tests with evidence.
- **portal white-label/design-system redesign:** Deferred to a later portal phase; Phase 204 only ranks narrow readiness work.
- **support triage index:** Deferred because Phase 204 ranks hardening work, not support workflow indexing.
- **pixel-diff coverage:** Deferred until portal readiness and design-system scope are chosen.
- **schema rename:** Deferred and not recommended by Phase 203; current default remains `billing`.
- **data movement:** Deferred and host-owned; Phase 203 treats movement between schemas as host migration work.
- **CI gate/topology/cache/branch-protection before baseline data:** Deferred until timing, cache, provider-state, rerun, and release-gate summaries exist.
- **broad docs rewrite:** Deferred; near-term docs work is limited to truth alignment, evaluator proof, and package listing trust.
- **enterprise governance:** Deferred because current evidence points to public trust, proof, release, CI, schema, and portal readiness first.
- **i18n/localization:** Deferred; no Phase 201-203 evidence makes localization a current hardening blocker.
- **broad runtime performance benchmarking:** Deferred until proof, CI measurement, release, and schema contract risks are lower.
- **brandbook favicon polish:** Deferred as polish after ranked trust, release, CI, schema, and portal readiness work.

## Requirement Coverage

| Requirement | Covered by | Coverage proof |
|---|---|---|
| RD-01 | How to read this roadmap, Ranking method, Ranked Top 10 | The roadmap gives a fast scan path, states the ranking method, and orders exactly ten future hardening candidates from public truth through portal readiness. |
| RD-02 | Ranked Top 10, Implementation Cards, Suggested Follow-Up Milestones | Each ranked row names impact, effort, risk reduction, timing, and done criteria; each card adds source evidence, scope, verification, rollback, and metrics. |
| RD-03 | Ranked Top 10, Implementation Cards, Suggested Follow-Up Milestones | Every ranked row, card, and follow-up slice cites Phase 201, Phase 202, or Phase 203 evidence so future implementation work traces back to concrete audit or ADR risk. |
| RD-04 | Explicit Deferrals, Phase Handoff and Boundary | Explicit Deferrals names polish-only or overbuilt work and its reopen threshold; the boundary section confirms Phase 204 stayed roadmap-only instead of promoting deferred work into implementation. |

## Phase Handoff and Boundary

Phase 204 is roadmap-only and does not change product behavior, public APIs, DB defaults, CI topology, release automation, runtime UI, CSS, routes, package metadata, examples, scripts, or public docs. The only intended implementation artifact is `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`, plus the executor summary and required GSD tracking files.

Handoff rules for future phases:

- Treat the rank order as the planning input, not proof that any hardening work has already landed.
- Start with Public Truth And Proof-State Baseline unless a later planning pass records stronger evidence.
- Keep CI topology, cache policy, release-gate shape, and branch-protection proposals behind the Phase 202 baseline requirement.
- Keep the Phase 203 database contract: default `billing`, explicit `public`, no default `accrue`, and no `search_path` primary contract.
- Keep portal work narrow until a later portal phase accepts white-label/design-system scope.
- Preserve provider-state language so Fake processor proof, `live-stripe`, skipped lanes, and advisory lanes cannot be confused.

This handoff did not change release commands, package manifests, workflow files, database migrations, source code, example app code, portal code, or public-facing guides.
