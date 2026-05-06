---
phase: 108
slug: docs-migration-proof-closeout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source-of-truth detail lives in `108-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit in `accrue` / `accrue_admin`, shell docs verifiers, and HexDocs build |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `scripts/ci/verify_package_docs.sh` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs && MIX_ENV=dev mix docs --warnings-as-errors && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh` |
| **Estimated runtime** | ~2 minutes quick run, ~4 minutes with docs verifier/build |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs`
- **After every plan wave:** Run `bash scripts/ci/verify_package_docs.sh`
- **Before `$gsd-verify-work`:** Run `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs && MIX_ENV=dev mix docs --warnings-as-errors && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs && cd .. && bash scripts/ci/verify_package_docs.sh`
- **Conditional release proof:** Run `bash scripts/ci/verify_rendro_hex_resolution.sh` only if dependency or release-truth files change during execution
- **Max feedback latency:** ~120 seconds for the behavioral quick lane

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 1 | PDF-08 | T-108-01 | README / First Hour / Production Readiness / Configuration all describe the Rendro-first default without implying that Chrome is required by default | static | `rg -n "Rendro|invoice_pdf_adapter|ChromicPDF|guides/pdf.md" accrue/README.md accrue/guides/first_hour.md accrue/guides/production-readiness.md accrue/guides/configuration.md` | ✅ | ⬜ pending |
| 108-01-02 | 01 | 1 | PDF-09 | T-108-01/T-108-02 | `accrue/guides/pdf.md` contains a dedicated migration section covering the three locked host states, and `upgrade.md` points at it without duplicating the full story | static | `rg -n "Migration|invoice_pdf_adapter|pdf_adapter|no action needed|ChromicPDF" accrue/guides/pdf.md accrue/guides/upgrade.md` | ✅ | ⬜ pending |
| 108-02-01 | 02 | 2 | PDF-08/PDF-09 | T-108-01/T-108-02 | Advanced guides stop implying Chromic is the default invoice path and explain renderer-specific asset / email / HTML-seam constraints honestly | static | `rg -n "advanced HTML seam|invoice_pdf_adapter|Rendro|ChromicPDF|logo_base64" accrue/guides/custom_pdf_adapter.md accrue/guides/email.md accrue/guides/branding.md` | ✅ | ⬜ pending |
| 108-02-02 | 02 | 2 | PDF-08/PDF-09 | T-108-03 | Final closeout artifact records the three primary behavior proofs, the docs verifier, and whether Rendro Hex resolution proof was rerun or inherited | integration | `test -f .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md && rg -n "pdf_test.exs|default_handler_mailer_dispatch_test.exs|invoice_live_test.exs|verify_package_docs.sh|verify_rendro_hex_resolution.sh" .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/billing/pdf_test.exs` already exists for the invoice renderer behavioral lane.
- [x] `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` already exists for the email attachment / fallback behavioral lane.
- [x] `accrue_admin/test/accrue_admin/live/invoice_live_test.exs` already exists for the admin invoice open/download lane.
- [x] `scripts/ci/verify_package_docs.sh` already exists as the supporting docs verifier.
- [ ] `.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md` must be created by Plan `108-02` Task `02`.

---

## Manual-Only Verifications

All phase behaviors have automated verification or static grep-verifiable doc conditions. No manual-only gate is required for the planned Phase 108 surface.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or a declared Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers every referenced proof lane except the deliberate closeout artifact
- [x] No watch-mode flags
- [x] Feedback latency < 180 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
