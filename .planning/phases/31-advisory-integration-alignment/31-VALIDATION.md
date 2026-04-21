---
phase: 31
slug: advisory-integration-alignment
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-21
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract + Playwright (host + admin) + `mix compile` + ExUnit (host contract anchor) |
| **Config file** | `examples/accrue_host/playwright.config.js` (reference only) |
| **Quick run command** | `bash scripts/ci/verify_verify01_readme_contract.sh` |
| **Full suite command** | `cd examples/accrue_host && mix verify.full` (human spine); `cd accrue_admin && npm run e2e` for package lane |
| **Estimated runtime** | Contract ~1s; admin e2e ~2–5m; host full verify ~10m+ |

---

## Traceability — ExUnit (core package)

| File | Validates VALIDATION rows |
|------|---------------------------|
| `accrue/test/accrue/phase_31_nyquist_validation_test.exs` | 31-01-01, 31-01-02 |

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
| 31-01-01 | 01 | 1 | INV-03, MOB-03, A11Y-03 | T-31-01-01 | No secrets in bash anchors | bash + exunit | `bash scripts/ci/verify_verify01_readme_contract.sh` · `mix test test/accrue/phase_31_nyquist_validation_test.exs` | ✅ | ✅ COVERED |
| 31-01-02 | 01 | 1 | MOB-03 | T-31-01-01 | N/A | node + exunit | `node -e 'const p=require("./examples/accrue_host/package.json"); if (p.scripts["e2e:mobile"]!=="env -u NO_COLOR playwright test e2e/verify01-admin-mobile.spec.js") process.exit(1)'` · `mix test test/accrue/phase_31_nyquist_validation_test.exs` | ✅ | ✅ COVERED |
| 31-02-01 | 02 | 2 | COPY-02, COPY-03 | T-31-02-01 | No PII in copy constants | mix | `cd accrue_admin && mix compile --warnings-as-errors` | ✅ | ✅ COVERED |
| 31-03-01 | 03 | 2 | COPY-03, INV-01 | T-31-03-01 | Fixture-only browser | playwright | `cd accrue_admin && npm run e2e` | ✅ | ✅ COVERED |

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: contract script after README/script edits
- [x] Wave 0 covers all MISSING references (N/A — waived)
- [x] No watch-mode flags in plans
- [x] `nyquist_compliant: true` set in frontmatter when phase execution completes

**Approval:** complete (Nyquist audit 2026-04-21)

---

## Validation Audit 2026-04-21

| Metric | Count |
|--------|-------|
| Gaps found | 4 (documentation-only: rows were `pending` while verification was green) |
| Resolved | 4 |
| Escalated | 0 |

Actions: re-ran all mapped automated commands (green); added `accrue/test/accrue/phase_31_nyquist_validation_test.exs` for ExUnit-traceable host contract + `e2e:mobile` script parity; updated per-task statuses and frontmatter.
