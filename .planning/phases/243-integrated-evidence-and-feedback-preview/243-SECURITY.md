---
phase: "243"
slug: "integrated-evidence-and-feedback-preview"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-10"
---

# Phase 243 — Security

The plan-authored register is verified at configured ASVS level 1. No risk acceptance substitutes for a missing mitigation.

## Trust Boundaries

| Boundary | Data crossing |
|----------|---------------|
| Rendered fixture to visual reviewer | Financial, identity, state and action facts |
| Ubuntu artifact to committed baseline | Snapshot bytes and runner/source provenance |
| Verifier to database, listener and build output | Mutable fixture setup and runtime ownership |
| Operator browser to preview | Authenticated Fake Admin inspection and recovery |
| Package build to mounted response | CSS/JS bytes |
| Evidence ledger to maintainer | Revision-specific acceptance claims |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-243-01 | Tampering | Visual masks | high | mitigate | Timestamp-only wrappers assert positive rendered targets, unchanged text and protected-fact exclusions in the Phase211 owner; accepted Ubuntu run 38083267168 | closed |
| T-243-02 | Repudiation | Linux provenance | medium | mitigate | 243-01-SUMMARY records source, runner, lock/spec/fixture hashes, artifact IDs and reviewed PNG commit; normal comparison passed at 0197f4ba | closed |
| T-243-03 | Tampering | Verifier custody | high | mitigate | Shared preflight precedes wrapper/config/setup mutation; distinct dev proof DB and per-run outputs; exact PID ownership; generic preview routing rejected. Thirteen controls pass; proof IDs are bounded, direct derived paths are contained, and production preflight rejects caller fixture injection; full verifier exit 0 and focused post-repair proof preserve authoritative preview state | closed |
| T-243-04 | Spoofing | Preview proof | medium | mitigate | Preservation spec uses actual operator sign-in and asserts Fake configuration, invoice/Events routes and warm recovery; dedicated runner passed 1/1 | closed |
| T-243-05 | Information Disclosure | Evidence and README | medium | mitigate | Handoff refers to existing README credentials; new proof receives password via environment and does not attach its value. Custody controls reject credential-bearing diagnostics | closed |
| T-243-06 | Tampering | Mounted CSS | medium | mitigate | Phase238 independently hashes package, compiled, HTTP and browser bodies; deliberately altered CSS fails and restored CSS succeeds, 2/2 focused tests | closed |
| T-243-07 | Repudiation | Coverage handoff | medium | mitigate | Additive 240-COVERAGE and 243-HANDOFF retain actual revisions, failed attempts and local/remote/provider limits; 21-route and missing-route controls pass | closed |
| T-243-SC | Tampering | Dependency resolution | high | mitigate | Existing lockfiles and workflow identities retained; no phase lockfile change or dependency upgrade. Lock identity recorded with Linux evidence | closed |

The repeated supply-chain row in the three plans is one shared threat, counted once. The generic preview URL routing defect and its failed attempt remain documented; f425645f closed it with exclusive-runner routing controls and current preservation proof.

## Accepted Risks Log

No accepted risks.

## Sign-Off

- [x] All eight threats have implemented mitigations and source/evidence references.
- [x] No open high or critical threats remain.
- [x] `threats_open: 0` and `status: verified`.

L1 verification checks mitigation presence; the independent code review and phase verifier follow this report.

## Security Audit 2026-10-10

| Metric | Count |
|---|---|
| Threats found | 8 |
| Closed | 8 |
| Open | 0 |

## Code review correction verification

The independent review identified CR-01 (proof-ID path escape) and CR-02 (synthetic custody identity bypass). Commits `388483ce` and `12649d27` close both: the proof-path control passed 1/1 and live-custody boundary controls passed 13/13 on 2026-10-10. The finding ledger records both fixed and zero open. This refresh retains the eight authored threats and the original review history.
