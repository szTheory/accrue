---
phase: 31
slug: advisory-integration-alignment
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract + Playwright (host + admin) + `mix compile` |
| **Config file** | `examples/accrue_host/playwright.config.js` (reference only) |
| **Quick run command** | `bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` (human spine); `cd accrue_admin && npm run e2e` for package lane |
| **Estimated runtime** | Contract ~1s; admin e2e ~2–5m; host full verify ~10m+ |

---

## Sampling Rate

- **After every task commit touching README or `verify_verify01_readme_contract.sh`:** `bash scripts/ci/verify_verify01_readme_contract.sh`
- **After plan wave 1:** `cd examples/accrue_host && npm run e2e:mobile` (post-`31-01` script addition)
- **After plan wave 2:** `cd accrue_admin && npm run e2e`
- **Before `/gsd-verify-work`:** Contract script + admin `npm run e2e` green; host `mix verify.full` per phase verification doc

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | INV-03, MOB-03, A11Y-03 | T-31-01-01 | No secrets in bash anchors | bash | `bash scripts/ci/verify_verify01_readme_contract.sh` | ✅ | ⬜ pending |
| 31-01-02 | 01 | 1 | MOB-03 | T-31-01-01 | N/A | node | `node -e "JSON.parse(require('fs').readFileSync('examples/accrue_host/package.json')).scripts['e2e:mobile']"` | ✅ | ⬜ pending |
| 31-02-01 | 02 | 2 | COPY-02, COPY-03 | T-31-02-01 | No PII in copy constants | mix | `cd accrue_admin && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 31-03-01 | 03 | 2 | COPY-03, INV-01 | T-31-03-01 | Fixture-only browser | playwright | `cd accrue_admin && npm run e2e` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — **no Wave 0 stubs**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full host orchestration | INV-03 | Long runtime / DB seed | From repo root: `cd examples/accrue_host && mix verify.full` after wave 1 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: contract script after README/script edits
- [ ] Wave 0 covers all MISSING references (N/A — waived)
- [ ] No watch-mode flags in plans
- [ ] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** pending
