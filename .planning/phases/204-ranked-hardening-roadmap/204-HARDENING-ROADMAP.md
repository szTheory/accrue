# Phase 204 Ranked Hardening Roadmap

**Date:** 2026-07-03
**Status:** Phase 204 roadmap assembly
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

Implementation cards are completed in the next task using the fixed field order from the Phase 204 UI contract.
