---
phase: 120
slug: release-contract-audit
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 120 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash verifier scripts + GitHub Actions YAML contracts |
| **Config file** | none centralized; scripts are invoked directly from `.github/workflows/ci.yml` |
| **Quick run command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh` |
| **Full suite command** | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh`
- **After every plan wave:** Run the same bundle plus `bash scripts/ci/verify_adoption_proof_matrix.sh`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-01 | 01 | 1 | REL-09, PPX-15 | T-120-01 / T-120-02 / T-120-03 / T-120-04 | Scope decision is grounded in live automation and registry evidence before any edits land | evidence capture | `rg -n "accrue_portal|accrue_release_created|accrue_admin_release_created|accrue_portal_release_created|publish-accrue-portal|workflow_dispatch|options:" RELEASING.md release-please-config.json .release-please-manifest.json .github/workflows/release-please.yml .github/workflows/publish-hex.yml && curl -fsSL https://hex.pm/api/packages/accrue_portal` | ✅ | ✅ green |
| 120-02-01 | 02 | 2 | REL-09, PPX-15 | T-120-05 / T-120-08 | Runbook/config/manifest reflect one chosen scope with no mixed wording | bash contract | `scope_cfg="$(jq -r '.plugins[] | select(.type==\"linked-versions\") | .components | join(\",\")' release-please-config.json)" && scope_manifest="$(jq -r 'keys | join(\",\")' .release-please-manifest.json)" && test "$scope_cfg" = "$scope_manifest" && rg -n "Last verified against|accrue_portal|linked \`accrue\`" RELEASING.md` | ✅ | ✅ green |
| 120-02-02 | 02 | 2 | REL-09, PPX-15 | T-120-06 / T-120-07 | Automated and manual publish workflows expose the same chosen package set and ordered chain | bash contract | `bash scripts/ci/verify_release_manifest_alignment.sh && rg -n "publish-accrue-admin:|needs: \\[release, publish-accrue\\]|publish-accrue-portal:|ACCRUE_PORTAL_HEX_RELEASE|accrue_portal_release_created|options:" .github/workflows/release-please.yml .github/workflows/publish-hex.yml` | ✅ | ✅ green |
| 120-03-01 | 03 | 3 | REL-09, PPX-15 | T-120-09 / T-120-11 / T-120-12 | Scope-aware verifier enforces release contract across docs and workflows without exposing secrets | bash contract | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh` | ✅ | ✅ green |
| 120-03-02 | 03 | 3 | REL-09, PPX-15 | T-120-10 | CI invokes the release-contract verifier from a merge-blocking path | bash contract + CI wiring | `bash scripts/ci/verify_release_manifest_alignment.sh && bash scripts/ci/verify_release_contract.sh && bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_adoption_proof_matrix.sh && rg -n "verify_release_contract\\.sh" .github/workflows/ci.yml` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers early evidence gathering and contract edits. Scope-aware verifier creation and CI wiring are deliberate Wave 3 deliverables in `120-03-PLAN.md`, not missing Wave 0 prerequisites.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Review publish ordering semantics in workflow `needs:` chains after Plan `120-02` edits | REL-09 | The release contract is partly encoded in workflow structure, not only command output | Read `.github/workflows/release-please.yml` and confirm the chosen package set and ordering are stated and enforced consistently |
| Confirm the chosen `accrue_portal` scope decision remains honest against current public registry state before Phase `121` | PPX-15 | Public registry truth is external to repo-local verifiers and may change between planning and release execution | Run `curl -fsSL https://hex.pm/api/packages/accrue_portal` and compare with the contract documented in `RELEASING.md`, manifest/config, and recovery workflow |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit manual evidence steps
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed
