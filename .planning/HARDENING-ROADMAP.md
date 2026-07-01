# Hardening Roadmap After v1.55 Audits

**Date:** 2026-07-01  
**Status:** Phase 204 draft baseline  
**Purpose:** Convert the v1.55 audit findings into implementation-sized follow-up work.

## Ranked Top 10 Changes

| Rank | Change | Area | Improves | Impact | Effort | Risk Reduction | Timing | Done Looks Like |
|---:|---|---|---|---|---|---|---|---|
| 1 | Add CI timing/cache baseline summaries | `.github/workflows`, `scripts/ci` | CI/CD | High | Low | High | before showing to strangers | CI logs show versions, cache hits, key step timings, and slowest tests where cheap |
| 2 | Fix public toolchain/version truth | `CONTRIBUTING.md`, READMEs, release docs | OSS trust | High | Low | High | before next release | One current table for Elixir/OTP/Postgres/Node/package versions |
| 3 | Clarify provider proof semantics | testing docs, CI comments, live-stripe workflow | production trust | High | Medium | High | before next release | Fake/Stripe/Braintree lanes say proved/skipped/advisory clearly |
| 4 | Consolidate host browser setup | host CI scripts/workflow | CI runtime/DX | Medium | Low | Medium | before heavy PR activity | host browser gate installs npm/Chromium once |
| 5 | Guard release recovery order | `publish-hex.yml` | release safety | Medium | Low | High | before next Hex recovery | admin/portal recovery checks upstream Hex version first |
| 6 | Split release-gate repetition | `ci.yml` | CI runtime | High | Medium | Medium | after baseline | lint/docs/audit run once; compatibility cells prove compatibility |
| 7 | Add schema-prefix hardening tests | config/schema/migration tests | DB safety | Medium | Medium | High | before 1.0 hardening | default `billing`, explicit `public`, explicit `billing` all tested |
| 8 | Create evaluator proof path | root/host README | adoption | High | Low | High | before showing to strangers | 30-minute clone-to-confidence path exists |
| 9 | Portal parity pass | `accrue_portal` docs/tests | package parity | Medium | Medium | Medium | before portal promotion | portal has first-hour/setup/troubleshooting parity |
| 10 | Package metadata polish | package `mix.exs`, README badges | OSS polish | Medium | Low | Medium | before public push | Hex links/descriptions and GitHub trust signals are complete |

## Suggested Follow-Up Milestones

### Milestone A: CI Truth and Runtime Baseline

Goal: measure before optimizing.

Scope:

- Add timing/cache summaries.
- Collect slowest tests and compile timing.
- Make live/provider skip/proved state explicit.
- Update CI docs with current critical path.

Out of scope:

- Splitting release-gate.
- Deleting tests.
- Moving checks to nightly.

### Milestone B: Public Truth and Evaluator Clarity

Goal: make Accrue easier to trust in the first 30 minutes.

Scope:

- Update supported toolchain/version truth.
- Add evaluator proof path.
- Add provider proof matrix.
- Polish package metadata and README first impression.

Out of scope:

- Broad docs rewrite.
- New product features.

### Milestone C: CI Critical Path Cleanup

Goal: reduce required-check time without reducing signal.

Scope:

- Split repeated release-gate work.
- Consolidate browser setup.
- Consider Playwright/Docker caching after baseline.
- Keep high-value host proof.

Out of scope:

- Clever workflow abstractions with unclear local reproduction.
- Removing gates solely because they are slow.

### Milestone D: Schema Prefix Contract Hardening

Goal: make the existing `billing` schema contract hard to drift.

Scope:

- Centralize default.
- Add prefix agreement tests.
- Add raw SQL qualification guard.
- Test explicit `public` and explicit old/current `billing`.
- Update upgrade docs around host-owned schema moves.

Out of scope:

- Renaming default to `accrue`.
- Automatic production data movement.

### Milestone E: Portal Parity Readiness

Goal: make `accrue_portal` feel first-class alongside core/admin.

Scope:

- Portal setup guide.
- Auth/session/CSP configuration notes.
- Braintree local checkout and billing portal proof path.
- Portal release-note coverage.
- Portal issue-template and troubleshooting polish.

Out of scope:

- New portal UI features unless audit evidence shows a concrete adoption blocker.

## Defer Explicitly

- Pixel-diff visual regression tooling unless current page-flow scoring misses real regressions.
- Default schema rename to `accrue`.
- Broad runtime performance benchmarking without sourced adopter scale risk.
- Enterprise governance artifacts beyond license, security, release, and contribution basics.
- i18n/localization program unless user-facing portal/admin adoption demands it.

## Done Criteria for This Roadmap

- Each follow-up item traces to a concrete v1.55 audit finding.
- Each follow-up milestone can be implemented independently.
- No item is included because it is generally "best practice" without Accrue-specific risk.
- High-signal gates stay protected until measurement proves a safer shape.
