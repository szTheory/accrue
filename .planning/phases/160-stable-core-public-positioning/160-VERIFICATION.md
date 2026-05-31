---
phase: 160-stable-core-public-positioning
verified: 2026-05-31T21:47:52Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 160: Stable-Core Public Positioning Verification Report

**Phase Goal:** Stable-Core Public Positioning. Public docs, mirrors, release notes, support matrix, and CI contracts consistently communicate Accrue's stable-core / demand-driven expansion posture and verify drift for POS-01, POS-02, and POS-03.
**Verified:** 2026-05-31T21:47:52Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public package docs and READMEs explain stable-core / demand-driven posture (roadmap SC1, POS-01). | ✓ VERIFIED | `README.md` and `accrue/README.md` contain explicit stable-core language; `bash scripts/ci/verify_stable_core_posture.sh` passed. |
| 2 | Public posture language avoids abandoned-product framing (`feature freeze`, `maintenance only`, `no new features ever`). | ✓ VERIFIED | `verify_stable_core_posture.sh` `require_absent_regex` checks all anchor/mirror files; script passed. |
| 3 | Adopter-facing docs expose complete supported billing loop and maturity boundary without `.planning/*` dependency (roadmap SC2, POS-02). | ✓ VERIFIED | `accrue/guides/jobs_to_be_done.md` has `## Scope and maturity`; `first_hour.md` and package READMEs link canonical guides; `verify_package_docs.sh` passed. |
| 4 | Package/example mirrors stay thin and point authority back to canonical public guides with package-vs-host ownership boundaries. | ✓ VERIFIED | `accrue_admin/README.md`, `accrue_portal/README.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md` include guide handoffs and ownership boundaries; `verify_adoption_proof_matrix.sh` passed. |
| 5 | Release notes, package docs, support matrix, adoption proof docs, and planning mirrors align on the same stable-core posture (roadmap SC3, POS-03). | ✓ VERIFIED | `accrue/guides/release-notes.md`, `.planning/processor-support-matrix.md`, `.planning/REQUIREMENTS.md`, and adoption-proof matrix contain aligned posture framing; `verify_release_notes_contract.sh` and `verify_stable_core_posture.sh` passed. |
| 6 | Dedicated stable-core drift verifier exists and checks required positive/negative posture anchors. | ✓ VERIFIED | `scripts/ci/verify_stable_core_posture.sh` exists, includes `require_fixed`, `require_regex`, `require_absent_regex`, and passed at runtime. |
| 7 | CI runs stable-core posture verification as a merge-blocking docs-contract step, with POS gate ownership documented. | ✓ VERIFIED | `.github/workflows/ci.yml` includes `Stable-core posture contract` under `docs-contracts-shift-left`; `scripts/ci/README.md` has POS-01/POS-02/POS-03 gate rows and triage section. |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `README.md` | Root stable-core posture + package map | ✓ VERIFIED | `verify.artifacts` pass; posture anchors present. |
| `accrue/README.md` | Core boundary + reopen triggers | ✓ VERIFIED | `verify.artifacts` pass; required trigger phrases present. |
| `accrue/guides/first_hour.md` | Setup spine + maturity pointer | ✓ VERIFIED | `verify.artifacts` pass; maturity link present. |
| `accrue/guides/jobs_to_be_done.md` | Billing-loop scope + maturity section | ✓ VERIFIED | `verify.artifacts` pass; `## Scope and maturity` present. |
| `accrue/guides/maturity-and-maintenance.md` | Long-form stable-core doctrine | ✓ VERIFIED | `verify.artifacts` pass. |
| `accrue_admin/README.md` | Thin mirror with guide pointers | ✓ VERIFIED | `verify.artifacts` pass. |
| `accrue_portal/README.md` | Thin mirror with ownership boundaries | ✓ VERIFIED | `verify.artifacts` pass. |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | Proof mirror with canonical handoff | ✓ VERIFIED | `verify.artifacts` pass. |
| `accrue/guides/release-notes.md` | Stable-core posture mirror | ✓ VERIFIED | `verify.artifacts` pass; release-notes contract passed. |
| `.planning/processor-support-matrix.md` | Maintainer-facing capability SSOT framing | ✓ VERIFIED | `verify.artifacts` pass; processor contract passed. |
| `scripts/ci/verify_stable_core_posture.sh` | Dedicated posture drift gate | ✓ VERIFIED | Exists + runtime pass (`verify_stable_core_posture: OK`). |
| `scripts/ci/verify_release_notes_contract.sh` | Release-note posture pointer checks | ✓ VERIFIED | Exists + runtime pass (`verify_release_notes_contract: OK (1.3.0)`). |
| `scripts/ci/README.md` | POS gate registry + triage | ✓ VERIFIED | POS table and `verify_stable_core_posture` triage present. |
| `.github/workflows/ci.yml` | CI wiring for posture gate | ✓ VERIFIED | `Stable-core posture contract` step under `docs-contracts-shift-left`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `README.md` | `accrue/README.md` | package map/start-here links | ✓ WIRED | `verify.key-links` passed. |
| `accrue/README.md` | `accrue/guides/first_hour.md` | guide index | ✓ WIRED | `verify.key-links` passed. |
| `accrue/guides/first_hour.md` | `accrue/guides/maturity-and-maintenance.md` | maturity pointer | ✓ WIRED | `verify.key-links` passed. |
| `accrue/guides/jobs_to_be_done.md` | `accrue/guides/maturity-and-maintenance.md` | scope+maturity cross-link | ✓ WIRED | Link exists (`jobs_to_be_done.md` references `maturity-and-maintenance.md` and has `## Scope and maturity`); `verify.key-links` miss was literal-pattern wording sensitivity. |
| `accrue/guides/release-notes.md` | `accrue/guides/maturity-and-maintenance.md` | stable-core posture section | ✓ WIRED | Release notes contain stable-core posture line and guide pointers; `verify_release_notes_contract.sh` enforces this with regex. |
| `.github/workflows/ci.yml` | `scripts/ci/verify_stable_core_posture.sh` | docs-contracts-shift-left step | ✓ WIRED | `verify.key-links` passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `scripts/ci/verify_stable_core_posture.sh` | N/A (static contract checks) | grep checks over repo files | N/A | ✓ VERIFIED (not a runtime data-render artifact) |
| `scripts/ci/verify_release_notes_contract.sh` | `accrue_version` | parsed from `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Stable-core posture contract passes | `bash scripts/ci/verify_stable_core_posture.sh` | `verify_stable_core_posture: OK` | ✓ PASS |
| Release-notes posture/version contract passes | `bash scripts/ci/verify_release_notes_contract.sh` | `verify_release_notes_contract: OK (1.3.0)` | ✓ PASS |
| Package docs contract passes | `bash scripts/ci/verify_package_docs.sh` | Passed with fixed invariants | ✓ PASS |
| Support matrix and adoption-proof contracts pass | `bash scripts/ci/verify_processor_support_matrix.sh` and `bash scripts/ci/verify_adoption_proof_matrix.sh` | Both OK | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Step 7c probe scripts | `find scripts -path '*/tests/probe-*.sh'` + PLAN/SUMMARY probe grep | No phase-declared or conventional probes found | ? SKIP (no probes present for this phase) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| POS-01 | 160-01 | Public docs/READMEs communicate stable-core demand-driven posture | ✓ SATISFIED | `README.md`, `accrue/README.md`, `maturity-and-maintenance.md`, `jobs_to_be_done.md`; posture verifier passes. |
| POS-02 | 160-01, 160-02 | Adopter can see supported billing loop + support/ownership boundaries without planning internals | ✓ SATISFIED | `first_hour.md`, `jobs_to_be_done.md`, `accrue_admin/README.md`, `accrue_portal/README.md`, host README and adoption-proof matrix handoffs. |
| POS-03 | 160-02, 160-03 | Maintainer can verify posture consistency across release notes/docs/support matrix/planning mirrors | ✓ SATISFIED | `verify_stable_core_posture.sh`, `verify_release_notes_contract.sh`, CI step wiring, POS registry in `scripts/ci/README.md`. |

Orphaned requirements for Phase 160 in `.planning/REQUIREMENTS.md`: none (POS-01, POS-02, POS-03 all present in plan frontmatter).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue_admin/README.md` | 56 | `placeholder` term | ℹ️ Info | Phrase is policy text (“placeholder copy”) in a dev-only boundary bullet, not an implementation stub. |

### Human Verification Required

None.

### Gaps Summary

No blocker gaps found. All roadmap success criteria and POS requirements for Phase 160 are backed by concrete artifacts, wiring, and passing drift contracts.

---

_Verified: 2026-05-31T21:47:52Z_  
_Verifier: the agent (gsd-verifier)_
