---
phase: 214-docs-truth-reconciliation
verified: 2026-07-31T04:35:00Z
status: gaps_found
score: 8/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Core, admin, and portal changelogs have correctly scoped Unreleased entries, while numbered releases and package versions remain Release Please-owned."
    status: failed
    reason: "The release-notes contract hard-pins all package versions to 1.4.0, so it rejects the aligned 1.5.0 Release Please state that it is required to validate. The script is merge-blocking CI and is also invoked by the Release Please workflow."
    artifacts:
      - path: "scripts/ci/verify_release_notes_contract.sh"
        issue: "Lines 33-35 require each @version to equal 1.4.0 instead of checking the lockstep version and its matching release-note sections."
      - path: "accrue/test/accrue/docs/release_notes_contract_test.exs"
        issue: "Fixtures cover only the current 1.4.0 state; no generated 1.5.0 Release Please candidate is accepted."
    missing:
      - "Replace fixed 1.4.0 assertions with a Release Please-safe invariant and add a 1.5.0 linked release-candidate fixture that passes."
---

# Phase 214: Docs & truth reconciliation Verification Report

**Phase Goal:** Every public and planning doc surface that mentions `lattice_stripe`'s version or the entitlements sync status tells the same, currently-true story — closing the stale `~> 0.2` matrix cell and flipping the Phase 127 deferral note to shipped/observational.

**Verified:** 2026-07-31T04:35:00Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Current stack surfaces declare `lattice_stripe ~> 2.0`, with 2.x entitlements support. | ✓ VERIFIED | `CLAUDE.md:39` and `:90` both declare `~> 2.0`; the current lock resolution is correctly distinguished as 2.1.0. |
| 2 | JTBD and entitlement guidance say the optional sync shipped as default-off observational diagnostics and never as a grant authority. | ✓ VERIFIED | `jobs_to_be_done.md:386-408`, `JTBD-FRONTIER.md:21,85`, and `entitlements.md:239-375` preserve local plan→feature grants and prohibit gate influence. |
| 3 | Support, adoption, planning, changelog, release-note, and public metadata surfaces describe the same stable-core advisory capability. | ✓ VERIFIED | Support matrix states the native advisory divergence lane (`:62,73`); adoption proof wires package-doc and isolation checks (`:20-22,42`); core/companion Unreleased entries, the 1.5.0 release story, and exactly four `since: "1.5.0"` surfaces are guarded by passing focused tests. |
| 4 | A scoped current-surface scan finds no stale `~> 0.2` or current deferred/authoritative-sync claim. | ✓ VERIFIED | Scoped grep found only explicitly historical roadmap/seed/status references; `verify_package_docs.sh` passes and has positive/negative checks for the relevant current surfaces. |
| 5 | The package-doc verifier rejects current version/status/authority regressions with non-vacuous fixtures. | ✓ VERIFIED | `package_docs_verifier_test.exs` is ROOT_DIR-backed and the focused suite passed 49 tests with the release contract suite; direct package-doc verifier passed. |
| 6 | Numbered releases and versions remain Release Please-owned without the new contract blocking the Release Please candidate. | ✗ FAILED | `verify_release_notes_contract.sh:33-35` pins 1.4.0. A temporary repository with only all three `@version` values changed to 1.5.0 exits 1: `accrue @version must remain 1.4.0 until Release Please`. CI runs it on PRs (`.github/workflows/ci.yml:88-89`) and Release Please invokes it (`release-please.yml:369-378`). |
| 7 | The plain-language 1.5.0 story links all three changelogs and distinguishes core capability from companion compatibility. | ✓ VERIFIED | `release-notes.md:5-7,22-24`; the direct contract and focused release tests pass. |
| 8 | Exactly the supported four Phase 213 public contract locations carry `@doc since: "1.5.0"`; internals stay unbadged. | ✓ VERIFIED | `verify_package_docs.sh:238-260` checks the four immediate-predecessor positions and exclusions; focused tests pass. |
| 9 | Release/package-doc verifier families reject the claimed documentation drift cases. | ✓ VERIFIED | The 49 focused ExUnit tests passed; negative fixtures cover absent/misplaced Unreleased sections, ownership inversions, manual numbered sections, portal discovery, next-release wording, and `since` drift. |

**Score:** 8/9 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `CLAUDE.md` | Current stack and matrix truth | ✓ VERIFIED | Both required current references are substantive and checked by the docs contract. |
| JTBD, entitlement, support, adoption, and planning mirrors | Shipped advisory/local-authority story | ✓ VERIFIED | Present, substantive, and referenced by `verify_package_docs.sh` and isolation/support proof. |
| Per-package CHANGELOGs and `release-notes.md` | Owned Unreleased and linked next-release story | ✓ VERIFIED | Present, substantive, linked by release notes, and guarded by the release contract. |
| `scripts/ci/verify_package_docs.sh` plus focused test | Executable current-truth contract | ✓ VERIFIED | Live invocation and ROOT_DIR fixture suite pass. |
| `scripts/ci/verify_release_notes_contract.sh` plus focused test | Release ownership/discoverability contract | ⚠️ PARTIAL | Exists, substantive, CI-wired, and tests current drift; its fixed-version branch rejects the Release Please candidate state. |
| Public API metadata files | Exact supported `since` metadata | ✓ VERIFIED | Four intended annotations and internal exclusions are enforced by the docs contract. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `verify_package_docs.sh` | Current stack/JTBD/support/adoption surfaces | scoped assertions | ✓ WIRED | Root-relative assertions cover `CLAUDE.md`, JTBD mirrors, support matrix, adoption proof, metadata, and negative patterns. |
| package-doc ExUnit test | `verify_package_docs.sh` | live run + ROOT_DIR fixtures | ✓ WIRED | Test invokes the script and copies/mutates its actual input paths. |
| support/adoption mirrors | isolation gate | documented proof location | ✓ WIRED | Adoption proof explicitly names `verify_entitlement_sync_isolation.sh`; direct gate passed. |
| `release-notes.md` | three package changelogs | explicit links | ✓ WIRED | All three GitHub changelog links are present at lines 5-7. |
| release contract | release notes and release workflows | assertions + CI invocation | ✗ NOT_WIRED SAFELY | The script is invoked by merge-blocking CI and Release Please, but hard-pins 1.4.0 and fails the intended generated 1.5.0 state. |
| package-doc verifier | four public metadata surfaces | exact adjacent annotations/exclusions | ✓ WIRED | Lines 238-260 make the expected locations and internal exclusions executable. |

### Data-Flow Trace (Level 4)

Not applicable: this phase delivers static documentation and deterministic repository contracts, not dynamic rendered data. The relevant flow is document → verifier → CI; all such links above were manually traced.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Current public/planning documentation contract | `bash scripts/ci/verify_package_docs.sh` | exited 0 | ✓ PASS |
| Support matrix and advisory isolation contract | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_entitlement_sync_isolation.sh` | both exited 0 | ✓ PASS |
| Current release-note contract | `bash scripts/ci/verify_release_notes_contract.sh` | `OK (1.4.0)` | ✓ PASS (current state only) |
| Focused phase regression suites | `cd accrue && mix test test/accrue/docs/release_notes_contract_test.exs test/accrue/docs/package_docs_verifier_test.exs` | 49 tests, 0 failures | ✓ PASS |
| Release Please 1.5.0 candidate | temporary ROOT_DIR fixture with all three `@version` values set to 1.5.0 | exited 1: `accrue @version must remain 1.4.0 until Release Please` | ✗ FAIL |

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts found; not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DOCS-01 | 214-01 | Correct both `CLAUDE.md` version surfaces to `~> 2.0`. | ✓ SATISFIED | Both named locations verified and package-doc contract passes. |
| DOCS-02 | 214-01 | Flip both JTBD surfaces to shipped/observational while remaining advisory. | ✓ SATISFIED | Both mirrors and current entitlement guidance preserve the local-only grant boundary. |
| DOCS-03 | 214-01, 214-02 | Consistent changelogs/release notes, public metadata, support/adoption/planning mirrors. | ✗ BLOCKED | Content and current checks pass, but the newly added release contract blocks the intended Release Please 1.5.0 state, so the release-note portion is not actually usable through the project’s merge/release wiring. |

All plan-declared requirements (`DOCS-01`, `DOCS-02`, `DOCS-03`) are accounted for. No Phase 214 orphan requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_release_notes_contract.sh` | 33-35 | Fixed current-version constants in a Release Please gate | 🛑 Blocker | Prevents the next linked release from passing CI/release proof. |

No unresolved `TBD`, `FIXME`, or `XXX` marker was found in Phase 214 implementation files. The pre-existing dirty Phase 213 review file was not modified.

### Gaps Summary

The visible documentation corrections are real and the current 1.4.0 repository passes their deterministic guards. However, the phase also introduced a release truth contract intended to protect a next linked `1.5.0` release while keeping numbered releases and versions Release Please-owned. That contract is wired into both merge-blocking CI and the Release Please workflow, yet it rejects an aligned 1.5.0 candidate before it can validate the matching generated changelog/release-note state. No later milestone phase exists to defer this specific release-pipeline failure to.

_Verified: 2026-07-31T04:35:00Z_  
_Verifier: the agent (gsd-verifier)_
