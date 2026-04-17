---
phase: 17-milestone-closure-cleanup
verified: 2026-04-17T15:36:11Z
status: gaps_found
score: 4/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Phase metadata keeps this cleanup out of v1.2 product requirement scope."
    status: failed
    reason: "The plan frontmatter declares `audit-tech-debt` under `requirements`, but `REQUIREMENTS.md` does not define that ID and `ROADMAP.md` explicitly says Phase 17 has no requirements."
    artifacts:
      - path: ".planning/phases/17-milestone-closure-cleanup/17-01-PLAN.md"
        issue: "Declares `audit-tech-debt` at `requirements:`."
      - path: ".planning/REQUIREMENTS.md"
        issue: "Phase 17 traceability says this phase adds no product requirements."
      - path: ".planning/ROADMAP.md"
        issue: "Phase 17 requirements are documented as `None`."
    missing:
      - "Remove `audit-tech-debt` from the Phase 17 plan frontmatter requirements list, or add a formally defined requirement ID to `REQUIREMENTS.md` and `ROADMAP.md` so traceability is consistent."
---

# Phase 17: Milestone Closure Cleanup Verification Report

**Phase Goal:** close v1.2 audit tech debt before archival without adding product scope.
**Verified:** 2026-04-17T15:36:11Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | ROADMAP and PROJECT bookkeeping agree that Phase 13 and the canonical demo outcome are complete. | ✓ VERIFIED | `.planning/PROJECT.md:61` contains the checked canonical-demo line; `.planning/ROADMAP.md:39` still records Phase 13 complete. |
| 2 | Browser E2E fixture cleanup only removes fixture-owned webhook/payment-failed rows and preserves unrelated shared test DB history. | ✓ VERIFIED | `scripts/ci/accrue_host_seed_e2e.exs:124-126` deletes by fixture actor IDs, webhook IDs, and subscription IDs; `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs:21` exercises rerun cleanup and `:73` proves an unrelated dispatch job survives. |
| 3 | Release/provider-parity/contributor docs no longer reference stale Phase 9 gates, non-existent primary CI jobs, or the wrong browser trust lane path. | ✓ VERIFIED | `RELEASING.md:7,19`, `guides/testing-live-stripe.md:86`, and `CONTRIBUTING.md:15` use current wording; stale phrases are checked as absent by `accrue/test/accrue/docs/release_guidance_test.exs:44` and `scripts/ci/verify_package_docs.sh:126`. |
| 4 | Focused docs contracts and host trust checks prove the cleanup does not regress v1.2 audit coverage. | ✓ VERIFIED | Orchestrator-provided evidence shows `mix test` for release/doc verifier tests, `bash scripts/ci/verify_package_docs.sh`, `bash scripts/ci/accrue_host_uat.sh`, and schema-drift verification all passed. |
| 5 | Phase metadata keeps this cleanup out of v1.2 product requirement scope. | ✗ FAILED | `17-01-PLAN.md:18-19` declares `requirements: audit-tech-debt`, while `.planning/REQUIREMENTS.md:72` says Phase 17 adds no product requirements and `.planning/ROADMAP.md` says `Requirements: None`. |

**Score:** 4/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.planning/PROJECT.md` | Canonical-demo milestone checklist marked complete | ✓ VERIFIED | Artifact verifier passed; checked line present at `:61`. |
| `scripts/ci/accrue_host_seed_e2e.exs` | Fixture-owned browser seed cleanup | ✓ VERIFIED | Artifact verifier passed; delete predicate is fixture-scoped at `:124-126`. |
| `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` | Regression proof that unrelated shared DB history is preserved | ✓ VERIFIED | Artifact verifier passed; rerun/preservation test starts at `:21`. |
| `RELEASING.md` | Current required/provider-parity/advisory release wording | ✓ VERIFIED | Artifact verifier passed; release-gate and deterministic wording present at `:7-19`. |
| `guides/testing-live-stripe.md` | Provider-parity guide without stale CI job references | ✓ VERIFIED | Artifact verifier passed; `host-integration` reference present at `:86`; stale `primary test job` wording absent. |
| `CONTRIBUTING.md` | Contributor setup points browser UAT to `examples/accrue_host` | ✓ VERIFIED | Artifact verifier passed; correct Node.js line present at `:15`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scripts/ci/accrue_host_seed_e2e.exs` | `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` | fixture-owned delete predicates proven against unrelated event rows | ✓ VERIFIED | `gsd-tools verify key-links` passed; test calls `AccrueHostSeedE2E.run!/1` and asserts unrelated rows survive. |
| `RELEASING.md` | `accrue/test/accrue/docs/release_guidance_test.exs` | positive and negative docs assertions | ✓ VERIFIED | `gsd-tools verify key-links` passed; release guidance tests assert current wording and reject stale wording. |
| `guides/testing-live-stripe.md` | `.github/workflows/ci.yml` | current workflow job names and advisory status | ✓ VERIFIED | `gsd-tools verify key-links` passed; guide references `release-gate`, `host-integration`, and `live-stripe`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `scripts/ci/accrue_host_seed_e2e.exs` | `fixture_webhook_ids`, `fixture_subscription_ids` | `Repo.all(...)` queries over `WebhookEvent` and `Subscription` in `cleanup_fixture_footprint!/0` | Yes | ✓ FLOWING |
| `examples/accrue_host/test/accrue_host/seed_e2e_cleanup_test.exs` | `first_fixture`, `second_fixture`, `unrelated` | Real calls to `AccrueHostSeedE2E.run!/1`, `Events.record/1`, and `Repo.insert!` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Canonical-demo bookkeeping is checked off | `rg -n --fixed-strings -- "- [x] Phoenix developers can clone ..."` | Passed (orchestrator evidence) | ✓ PASS |
| Seed cleanup preserves unrelated rows | `cd examples/accrue_host && MIX_ENV=test mix test test/accrue_host/seed_e2e_cleanup_test.exs --trace` | Passed (orchestrator evidence) | ✓ PASS |
| Docs contracts stay green | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs --trace` | Passed, 9 tests / 0 failures (orchestrator evidence) | ✓ PASS |
| Shell docs verifier stays green | `bash scripts/ci/verify_package_docs.sh` | Passed (orchestrator evidence) | ✓ PASS |
| Host trust lane still passes | `bash scripts/ci/accrue_host_uat.sh` | Passed, including 138 host tests and 2 Playwright walkthroughs (orchestrator evidence) | ✓ PASS |
| Schema drift remains closed | `node "$HOME/.codex/get-shit-done/bin/gsd-tools.cjs" verify schema-drift "17"` | `drift_detected=false` (orchestrator evidence) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `audit-tech-debt` | `17-01-PLAN.md` | Not defined in `.planning/REQUIREMENTS.md` | ✗ BLOCKED | `17-01-PLAN.md:18-19` declares it; `.planning/REQUIREMENTS.md:72` says Phase 17 is cleanup-only with no requirement additions; `.planning/ROADMAP.md` Phase 17 says `Requirements: None`. |

Orphaned requirements for Phase 17: none in `.planning/REQUIREMENTS.md`; the traceability problem is the inverse one, an undefined plan-side requirement ID.

### Anti-Patterns Found

None. Focused scan across the phase's modified files found no TODO/FIXME markers, placeholder text, or empty implementations.

### Gaps Summary

The implemented cleanup work achieved the technical outcome: bookkeeping is aligned, fixture cleanup is scoped to owned rows, regression coverage is real, and the docs/trust checks are wired and passing.

The remaining gap is in planning traceability. Phase 17 is explicitly described in both `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` as cleanup-only with no new product requirement, but `17-01-PLAN.md` still declares `audit-tech-debt` under `requirements:`. That leaves one piece of archival tech debt open and prevents a clean pass.

---

_Verified: 2026-04-17T15:36:11Z_  
_Verifier: Claude (gsd-verifier)_
