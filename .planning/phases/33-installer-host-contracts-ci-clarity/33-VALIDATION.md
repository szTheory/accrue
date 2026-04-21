---
phase: 33
slug: installer-host-contracts-ci-clarity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash doc-contract scripts + ExUnit (`accrue` app) |
| **Config file** | `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh` |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh` |
| **Full suite command** | `bash scripts/ci/verify_package_docs.sh && bash scripts/ci/verify_verify01_readme_contract.sh && cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` |
| **Estimated runtime** | ~30–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_package_docs.sh` from repository root when any tracked markdown or `scripts/ci/*.sh` changes.
- **After every plan wave:** Run the **full suite command** if installer task files or host README changed; otherwise quick + VERIFY-01 script.
- **Before `/gsd-verify-work`:** Full suite command must be green when installer or doc tests were touched.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | ADOPT-04 | T-doc-01 | No misleading installer semantics | bash + exunit | `bash scripts/ci/verify_package_docs.sh && cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 33-02-01 | 02 | 2 | ADOPT-05 | T-doc-02 | Doc gates catch anchor drift | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 33-03-01 | 03 | 2 | ADOPT-06 | T-ci-01 | Job ids stable; advisory lane labeled | bash + grep | `bash scripts/ci/verify_package_docs.sh` (plus plan acceptance greps) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers requirements — no new Wave 0 framework install.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions UI clarity | ADOPT-06 | UI outside repo | Open `.github/workflows/ci.yml` in GitHub’s workflow editor; confirm `jobs.*` keys for `release-gate`, `host-integration`, `live-stripe` match docs. |
| Installer rerun on real host | ADOPT-04 | Full Phoenix app shape varies | In `examples/accrue_host`, run `mix accrue.install --yes` twice; confirm no duplicate router mounts; compare to `upgrade.md` text. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` or documented manual steps
- [ ] Sampling continuity: doc script after each doc-touching wave
- [ ] Wave 0 N/A
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution green
