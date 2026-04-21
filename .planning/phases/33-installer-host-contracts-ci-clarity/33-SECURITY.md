---
phase: 33
slug: installer-host-contracts-ci-clarity
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-21
---

# Phase 33 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.  
> Scope: documentation + CI clarity only (no billing logic, secrets, or webhook paths changed).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Package & root guides | Host developers follow install/proof instructions | Non-secret integration guidance |
| GitHub Actions workflow | Contributors infer merge-blocking vs advisory lanes from job ids and docs | CI metadata only (no credentials in edits) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-doc-01 | Tampering (misleading docs) | `accrue/guides/first_hour.md` | mitigate | §4 links to `upgrade.md#installer-rerun-behavior`; semantics match `upgrade.md` installer rerun bullets | closed |
| T-doc-02 | Tampering (doc rot) | First Hour guide + tests | mitigate | `first_hour_guide_test.exs` asserts anchor substring; `verify_package_docs.sh` `require_fixed` on `upgrade.md#installer-rerun-behavior` | closed |
| T-doc-03 | Tampering (lost install hook) | `accrue/guides/troubleshooting.md` | mitigate | `require_fixed` on `mix accrue.install --check` in `verify_package_docs.sh` | closed |
| T-ci-01 | Tampering (broken automation contracts) | `.github/workflows/ci.yml` | mitigate | Top-of-file comment lists stable job ids; YAML `jobs:` keys unchanged (comments + `name:` / prose only) | closed |
| T-ci-02 | Tampering (misread merge policy) | CI + `README.md` + `guides/testing-live-stripe.md` | mitigate | Explicit `host-integration` (PR-blocking) vs advisory `live-stripe` (manual/cron) in README, guide, and workflow comments | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-21 | 5 | 5 | 0 | Cursor agent (inline `/gsd-secure-phase 33`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-21
