---
phase: 69
slug: doc-planning-mirrors
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for doc + planning mirror work (**DOC-01**, **DOC-02**, **HYG-01**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`accrue` app) + bash CI script |
| **Config file** | `accrue/config/config.exs` (host test); none required for doc-only tasks |
| **Quick run command** | `bash scripts/ci/verify_package_docs.sh` (repo root) |
| **Full suite command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |
| **Estimated runtime** | ~30–90 seconds |

---

## Sampling Rate

- **After every edit** to a path enforced by **`verify_package_docs.sh`:** Run **`bash scripts/ci/verify_package_docs.sh`**
- **After any change** to **`verify_package_docs.sh`:** Run the **full** ExUnit file above
- **Before `/gsd-verify-work`:** Both commands exit **0**
- **Max feedback latency:** Under **120s** on a warm `mix` build

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 69-01-01 | 01 | 1 | DOC-01 | T-69-01 | N/A (public pins only) | bash | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| 69-01-02 | 01 | 1 | DOC-02 | T-69-02 | N/A | integration | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ | ⬜ pending |
| 69-01-03 | 01 | 1 | DOC-01, DOC-02 | T-69-01 | N/A | grep | `rg '\[x\] \*\*DOC-0[12]\*\*' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |
| 69-02-01 | 02 | 1 | HYG-01 | T-69-03 | N/A | manual+grep | Review **PROJECT** / **MILESTONES** / **STATE** Hex lines vs `mix.exs` | ✅ | ⬜ pending |
| 69-02-02 | 02 | 1 | HYG-01 | T-69-03 | N/A | grep | `rg '\[x\] \*\*HYG-01\*\*' .planning/REQUIREMENTS.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements: **no new** Wave 0 stubs.

- [x] **`scripts/ci/verify_package_docs.sh`** — SSOT for integrator doc needles
- [x] **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** — harness + fixtures

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| Maintainer reads **PROJECT** narrative for tone | HYG-01 | Subjective | Skim **Current State** / milestone blurbs for factual (not voice) mistakes only |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or documented manual row above
- [ ] Sampling continuity: doc edits always paired with **`verify_package_docs`**
- [ ] No watch-mode flags
- [ ] Feedback latency under **120s** for quick loop
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
