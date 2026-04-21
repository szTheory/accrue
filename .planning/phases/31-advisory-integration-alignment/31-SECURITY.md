---
phase: 31
slug: advisory-integration-alignment
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-21
updated: 2026-04-21
---

# Phase 31 — Security

Per-phase security contract for VERIFY-01 README/CI alignment, host npm shortcuts, `AccrueAdmin.Copy` step-up chrome, and fixture Playwright / documentation posture vs merge-blocking host VERIFY-01.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI / local bash → `verify_verify01_readme_contract.sh` | Contract script reads repo files only; no network. | README paths and substring anchors |
| Maintainer README → evaluators | VERIFY-01 prose and listed spec paths. | Proof pointers; no credentials |
| Admin UI `Copy` → step-up modal | Static operator strings; no user input echoed into new accessors. | Fixed English chrome only |
| Fixture Playwright → `__e2e__` | Package UAT runs against test endpoints only. | Fixture-scoped HTTP |
| Workflow / README comments | Non-executable documentation of CI truth. | Maintainer intent only |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-31-01-01 | T | README VERIFY-01 drift vs CI | mitigate | `require_substring` anchors (including mobile spec + mobile shell heading) plus `grep -oE` file-exists loop over `e2e/verify01-*.spec.js`; `sk_live` negation block unchanged. Evidence: `scripts/ci/verify_verify01_readme_contract.sh`. | closed |
| T-31-01-02 | — | `examples/accrue_host/package.json` npm scripts | accept | No secrets in script strings; `e2e:mobile` mirrors `e2e:a11y` (`env -u NO_COLOR playwright test …`). Evidence: `examples/accrue_host/package.json`. | closed |
| T-31-02-01 | — | `AccrueAdmin.Copy` step-up strings | accept | Public functions return static literals only; no new logging of challenge maps. Evidence: `accrue_admin/lib/accrue_admin/copy.ex`, `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex`. | closed |
| T-31-03-01 | — | `accrue_admin` fixture Playwright assertions | accept | Structural / regex assertions reduce drift; merge-blocking literal contracts remain on host VERIFY-01. Evidence: `accrue_admin/e2e/phase7-uat.spec.js`, `.github/workflows/accrue_admin_browser.yml` header comment, `accrue_admin/README.md` §Browser UAT. | closed |

---

## Accepted Risks Log

No accepted risks beyond the **accept** dispositions already recorded in the threat register and sourced from the phase `31-*-PLAN.md` threat models.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-21 | 4 | 4 | 0 | gsd-secure-phase (inline) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented (none additional beyond register)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-21
