---
phase: 122
verified: pending
status: draft
score: pending
gaps: []
---

# Phase 122 Verification Ledger

PR_NUMBER: 23
TARGET_VERSION: 1.1.1
RUN_ID: 25554198977

## INV-08 path decision

Path `(b)` is the default and remains correct for `INV-08`. The failed `1.1.0` portal publish and the superseding `1.1.1` recovery are already proven in `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; they did not leave a new user-facing falsehood, new non-diagnostic verifier hole, or repeated downstream trust story strong enough to justify a new friction row.

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

Pending Plan 03.

## Final milestone closeout

Pending Plan 03.
