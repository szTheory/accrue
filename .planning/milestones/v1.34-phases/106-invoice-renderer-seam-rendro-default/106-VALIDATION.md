---
phase: 106
slug: invoice-renderer-seam-rendro-default
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 106 — Validation Strategy

> Per-phase validation contract for invoice renderer seam work and Rendro-default parity proof.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit in `accrue/` and `accrue_admin/` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs -x` |
| **Admin proof command** | `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs -x` |
| **Focused config/docs command** | `cd accrue && mix test test/accrue/config_test.exs test/mix/tasks/accrue_install_uat_test.exs -x` |
| **Estimated runtime** | 1-3 minutes depending on DB boot and app compilation |

## Sampling Rate

- **After every task commit:** run the plan-local command in that task's `<automated>` block.
- **After every wave:** run the core PDF contract tests plus the admin LiveView proof lane.
- **Before phase verification:** run all automated commands listed in the per-task map.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threat Ref | Test Type | Automated Command | Status |
|---------|------|------|--------------|------------|-----------|-------------------|--------|
| 106-01-01 | 01 | 1 | PDF-01, PDF-02, PDF-05 | T-106-01, T-106-03 | ExUnit seam-proof | `cd accrue && mix test test/accrue/webhook/default_handler_mailer_dispatch_test.exs test/accrue/billing/pdf_test.exs -x` | ⬜ pending |
| 106-01-02 | 01 | 1 | PDF-01, PDF-02 | T-106-02 | docs/config regression | `cd accrue && mix test test/accrue/config_test.exs test/mix/tasks/accrue_install_uat_test.exs -x` | ⬜ pending |
| 106-02-01 | 02 | 2 | PDF-04, PDF-05 | T-106-03 | adapter parity proof | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/invoice_renderer/rendro_test.exs -x` | ⬜ pending |
| 106-02-02 | 02 | 2 | PDF-03, PDF-05 | T-106-01, T-106-03 | end-to-end lane proof | `cd accrue && mix test test/accrue/webhook/default_handler_mailer_dispatch_test.exs -x && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs -x` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the invoice-renderer docs now distinguish `:invoice_pdf_adapter` from `:pdf_adapter` without over-documenting migration | PDF-01, PDF-02 | Wording quality and scope discipline are judgment calls | Read `guides/configuration.md` and ensure it points invoice rendering to the invoice seam while leaving broader migration docs to later phases |
| Confirm Rendro parity work preserves invoice intent rather than chasing byte-for-byte equivalence with ChromicPDF | PDF-05 | Layout intent is semantic, not literal-binary | Review the final tests/refactors and confirm they assert invoice semantics such as branding, totals, line items, dates, and footer, not engine-specific bytes |

## Validation Sign-Off

- [x] All planned tasks have automated verification
- [x] No watch-mode commands are required
- [x] Cross-package proof lanes are explicitly named
- [x] `nyquist_compliant: true` set in frontmatter
- [ ] Automated commands executed and green

**Approval:** pending
