---
phase: 122
verified: 2026-05-08T14:15:25Z
status: passed
score: 5/5 must-haves verified
gaps: []
---

# Phase 122 Verification Ledger

PR_NUMBER: 23
TARGET_VERSION: 1.1.1
RUN_ID: 25554198977

## INV-08 path decision

Path `(b)` is the default and remains correct for `INV-08`. The failed `1.1.0` portal publish and the superseding `1.1.1` recovery are already proven in `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; they did not leave a new user-facing falsehood, new non-diagnostic verifier hole, or repeated downstream trust story strong enough to justify a new friction row.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Live planning mirrors share the exact shipped trio sentence and no longer imply pre-closeout release ambiguity | ✓ VERIFIED | `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` all carry the same shipped `1.1.1` trio line or point directly to that final truth. |
| 2 | `v1.38` now reads as shipped/archive rather than "ready to begin Phase 121" or other stale active-state residue | ✓ VERIFIED | `.planning/ROADMAP.md` retired the active milestone, `.planning/STATE.md` now reports `status: shipped`, and `.planning/MILESTONES.md` contains the shipped `v1.38` block. |
| 3 | `INV-08` remains a dated path-`(b)` maintainer certification with the friction inventory as the only normative voice | ✓ VERIFIED | `.planning/research/v1.17-FRICTION-INVENTORY.md` contains `### v1.38 INV-08 maintainer pass (2026-05-08)` and points back to this verification artifact. |
| 4 | Phase 122 reuses Phase 121 as the canonical public release proof for PR `23`, target version `1.1.1`, and run `25554198977` | ✓ VERIFIED | This ledger retains `PR_NUMBER: 23`, `TARGET_VERSION: 1.1.1`, `RUN_ID: 25554198977`, and explicitly locks `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md` as the upstream proof source. |
| 5 | `HYG-03` and `INV-08` close only after the mirror cleanup and inventory evidence are on disk | ✓ VERIFIED | `.planning/REQUIREMENTS.md` now marks only the two Phase 122 requirements complete, and those rows point at the completed mirror and verification outputs. |

## Public proof reused from Phase 121

`.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md` is the canonical public linked-release proof for this closeout. Phase 122 reuses its recorded identifiers and release facts rather than cloning Hex, tag, GitHub release, or workflow transcripts:

- `PR_NUMBER: 23`
- `TARGET_VERSION: 1.1.1`
- `RUN_ID: 25554198977`
- shipped tags `accrue-v1.1.1`, `accrue_admin-v1.1.1`, and `accrue_portal-v1.1.1`
- public Hex `latest_version` `1.1.1` for `accrue`, `accrue_admin`, and `accrue_portal`

## Fresh command transcript

```text
$ bash scripts/ci/verify_v1_17_friction_research_contract.sh
verify_v1_17_friction_research_contract: OK
```

## HYG-03 mirror review

- `.planning/PROJECT.md` now states the exact shipped trio sentence and clarifies that the post-publish closeout already completed.
- `.planning/MILESTONES.md` now has `## v1.38 Linked Release Truth (Shipped: 2026-05-08)` with the canonical public proof and closeout artifacts called out explicitly.
- `.planning/ROADMAP.md` no longer presents `v1.38` as an active milestone and now summarizes the shipped trio truth plus the retired active roadmap state.
- `.planning/STATE.md` no longer says "ready to begin Phase 121 publish proof" and now records the shipped/archive posture with final milestone progress.

## Final milestone closeout

`v1.38` is now closed in the live planning mirrors. The canonical public release proof remains Phase 121-owned, while this artifact records only the fresh Phase 122 evidence: shipped mirror alignment, the dated `INV-08` path-`(b)` decision, and the final requirements closure.

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| HYG-03 | ✓ SATISFIED | `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` now carry the final shipped `1.1.1` trio truth with no stale Phase 121/120 residue. |
| INV-08 | ✓ SATISFIED | `.planning/research/v1.17-FRICTION-INVENTORY.md` records `### v1.38 INV-08 maintainer pass (2026-05-08)` and points to this ledger for the supporting transcript and closeout context. |
