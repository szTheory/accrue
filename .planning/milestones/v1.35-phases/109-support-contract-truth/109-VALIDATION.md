---
phase: 109
slug: support-contract-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for support-truth and docs-drift closure. Source-of-truth detail lives in `109-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash docs verifiers plus targeted `rg` contract checks |
| **Config file** | `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`, `scripts/ci/verify_processor_support_matrix.sh` |
| **Quick run command** | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh` |
| **Full suite command** | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Estimated runtime** | under 1 minute |

---

## Sampling Rate

- **After every task commit:** run the task-local `rg` command from that task.
- **After every plan wave:** run `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh`.
- **Before `$gsd-verify-work`:** run the full suite command.
- **Max feedback latency:** under 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-01-01 | 01 | 1 | SUP-01 | T-109-01 | support matrix and front-door docs all describe checkout and billing portal with the same provider-honest semantics | static | `rg -n "Stripe returns upstream hosted URLs|Braintree returns mounted first-party local|provider-honest|same facade" .planning/processor-support-matrix.md README.md accrue/README.md` | ✅ | ⬜ pending |
| 109-01-02 | 01 | 1 | SUP-01 | T-109-01 | planning mirrors match the same support contract and do not reintroduce Stripe-only wording | static | `rg -n "provider-honest|gateway subscription core|Stripe returns upstream hosted URLs|Braintree returns mounted first-party local" .planning/ROADMAP.md .planning/PROJECT.md` | ✅ | ⬜ pending |
| 109-02-01 | 02 | 2 | SUP-02 | T-109-02 | First Hour and package/docs branch early into the mounted Braintree path with the minimum setup contract | static | `rg -n "portal_base_url|portal_mount_path|Hosted Fields|accrue_portal|Braintree|billing portal" accrue/guides/first_hour.md accrue/guides/braintree-local-portal.md accrue_portal/README.md` | ✅ | ⬜ pending |
| 109-02-02 | 02 | 2 | SUP-02 | T-109-02 | front-door operator docs surface the sharp Braintree setup failures without turning into full troubleshooting duplicates | static | `rg -n "portal_base_url|portal_mount_path|auth|session|CSP|discount preview|completion" accrue/guides/production-readiness.md accrue/guides/telemetry.md` | ✅ | ⬜ pending |
| 109-03-01 | 03 | 3 | SUP-01/SUP-02 | T-109-03 | example-host docs mirror the new support contract and example-host proof posture without claiming Stripe-only checkout/portal | static | `rg -n "Braintree|checkout|billing portal|mounted|provider-honest|gateway subscription core" examples/accrue_host/README.md examples/accrue_host/docs/adoption-proof-matrix.md` | ✅ | ⬜ pending |
| 109-03-02 | 03 | 3 | SUP-01/SUP-02 | T-109-03 | bash gates and contributor map pin the updated literals and same-PR co-update rule | integration | `bash scripts/ci/verify_processor_support_matrix.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/processor-support-matrix.md` exists and already contains the target provider-honest checkout/portal wording.
- [x] `README.md`, `accrue/README.md`, `accrue/guides/first_hour.md`, `accrue/guides/braintree-local-portal.md`, `accrue_portal/README.md`, `examples/accrue_host/README.md`, and `examples/accrue_host/docs/adoption-proof-matrix.md` all exist.
- [x] `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, `scripts/ci/verify_adoption_proof_matrix.sh`, and `scripts/ci/verify_processor_support_matrix.sh` all exist.

---

## Manual-Only Verifications

All planned phase work is grep-verifiable or bash-gate-verifiable. No manual-only gate is required for planning.

---

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane
- [x] No watch-mode flags
- [x] Feedback latency < 180 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
