---
phase: 108-docs-migration-proof-closeout
reviewed: 2026-05-06T21:15:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - accrue/README.md
  - accrue/guides/first_hour.md
  - accrue/guides/production-readiness.md
  - accrue/guides/configuration.md
  - accrue/guides/pdf.md
  - accrue/guides/upgrade.md
  - accrue/guides/custom_pdf_adapter.md
  - accrue/guides/email.md
  - accrue/guides/branding.md
  - .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md
  - .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-01-SUMMARY.md
  - .planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-02-SUMMARY.md
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 108: Code Review Report

**Reviewed:** 2026-05-06T21:15:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Reviewed the six Phase 108 docs commits and the cited Phase 108 files only. The main problems are contract mismatches between the new documentation and the actual invoice-rendering/config implementation, plus verification artifacts that marked the phase as passed without exercising the new config claims.

## Warnings

### WR-01: Branding guide documents an unsupported `logo_base64` contract

**File:** `accrue/guides/branding.md:20`
**Issue:** The new quickstart/schema/precedence guidance at `accrue/guides/branding.md:20`, `accrue/guides/branding.md:43`, and `accrue/guides/branding.md:71-89` tells users to configure `:branding[:logo_base64]` and says it takes precedence for PDF rendering. The actual branding schema does not define `:logo_base64` at all (`accrue/lib/accrue/config.ex:268-289`), and the invoice/email render paths only read `logo_url` or plain text (`accrue/lib/accrue/invoices/components.ex:42-49`, `accrue/lib/accrue/invoice_renderer/rendro.ex:19-160`). Following the new guide can fail config validation or silently fail to affect rendered invoices.
**Fix:** Remove `logo_base64` from the docs until the key is implemented end-to-end, or add real schema/renderer support for it and cover that behavior with tests.

### WR-02: Email guide overstates what `:invoice_pdf_adapter` controls

**File:** `accrue/guides/email.md:39-45`
**Issue:** The new bullets at `accrue/guides/email.md:39-45` and `accrue/guides/email.md:151-159` say `:invoice_pdf_adapter` controls whether invoice emails attach PDFs or fall back to hosted invoice URLs. That is not the full contract even in the same guide, which later says attachment behavior depends on `:attach_invoice_pdf` (`accrue/guides/email.md:285-289`). More importantly, the current mailer implementation does not consult `:attach_invoice_pdf` before attaching/falling back (`accrue/lib/accrue/workers/mailer.ex:92-97`, `accrue/lib/accrue/workers/mailer.ex:111-114`, `accrue/lib/accrue/workers/mailer.ex:161-169`). The new docs therefore hide an important toggle and describe behavior more narrowly than the codebase actually supports/claims to support.
**Fix:** Document the full attachment contract (`:attach_invoice_pdf` plus renderer outcome), then add or repair mailer tests so the toggle is either enforced or removed from the public contract.

### WR-03: Phase verification marked the docs closeout as passed without validating the new config claims

**File:** `.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-VERIFICATION.md:74-112`
**Issue:** The closeout artifacts claim `Self-Check: PASSED` (`.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-01-SUMMARY.md:102`, `.planning/milestones/v1.34-phases/108-docs-migration-proof-closeout/108-02-SUMMARY.md:106`) even though the supporting proof in `108-VERIFICATION.md:74-112` only covers doc grep/build gates and not whether the new Phase 108 config snippets or renderer-asset claims are actually valid. That gap is why the broken `logo_base64` contract shipped while the phase reported a clean closeout.
**Fix:** Add a docs/config smoke check to the verification lane, such as an ExUnit test or script that runs `Accrue.Config.validate!/1` against guide snippets and asserts the documented renderer-specific branding behavior before marking the phase passed.

---

_Reviewed: 2026-05-06T21:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
