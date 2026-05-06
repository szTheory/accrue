---
phase: 107
slug: rendro-release-optional-chromic-path
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-06
verified_at: 2026-05-06T17:30:03Z
---

# Phase 107 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source-of-truth detail in `107-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto sandbox / integration support in `accrue` |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs` |
| **Full suite command** | `cd accrue && mix test.all && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` |
| **Estimated runtime** | ~90 seconds quick run, ~4 minutes full suite |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/billing/pdf_test.exs test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
- **After every plan wave:** Run `cd accrue && mix test.all`
- **Before `$gsd-verify-work`:** Run `cd accrue && mix test.all && cd ../accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs && bash scripts/ci/verify_rendro_hex_resolution.sh`
- **Max feedback latency:** ~90 seconds for the focused quick run

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 107-01-01 | 01 | 1 | PDF-06 | T-107-01 | Explicit Chromic misconfiguration returns `%Accrue.Error.InvoiceRendererUnavailable{}` instead of a bare atom, while `%Accrue.Error.PdfDisabled{}` remains unchanged for intentional disablement | unit | `cd accrue && mix test test/accrue/billing/pdf_test.exs --trace` | ✅ | ✅ passed 2026-05-06 |
| 107-01-02 | 01 | 1 | PDF-06 | T-107-02/T-107-03/T-107-04 | Boot warnings use `:invoice_pdf_adapter` correctly, legacy `:pdf_adapter`-only hosts get a migration warning, and mailer degradation treats the typed unavailable error as terminal with low-cardinality ops telemetry | integration | `cd accrue && mix test test/accrue/application_boot_guards_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs --trace` | ✅ | ✅ passed 2026-05-06 |
| 107-01-03 | 01 | 1 | PDF-06 | T-107-03/T-107-04 | Narrow host docs match the explicit adapter split and typed unavailable contract without implying automatic fallback | static | `rg -n "explicit compatibility path|InvoiceRendererUnavailable|invoice_pdf_adapter|pdf_adapter|pdf_adapter_unavailable" accrue/guides/pdf.md accrue/guides/configuration.md accrue/guides/telemetry.md accrue/guides/production-readiness.md` | ✅ | ✅ passed 2026-05-06 |
| 107-02-01 | 02 | 2 | PDF-07 | T-107-05 | `accrue` resolves Rendro from Hex at `~> 0.1.0` and no longer references `../../rendro` | integration | `cd accrue && mix deps.get && mix deps.tree | rg "rendro"` | ✅ | ✅ passed 2026-05-06 |
| 107-02-02 | 02 | 2 | PDF-07 | T-107-06/T-107-07 | Clean-checkout proof script exists, is executable, rejects local-path truth, and is wired into `RELEASING.md` publish-order guidance | integration | `bash scripts/ci/verify_rendro_hex_resolution.sh` | ✅ | ✅ passed 2026-05-06 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `accrue/test/accrue/application_boot_guards_test.exs` already exists and only needs Phase 107 key/warning updates.
- [x] `accrue/test/accrue/billing/pdf_test.exs` already exists and only needs the typed unavailable assertion update.
- [x] `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs` already exists and only needs degradation-branch assertion updates.
- [x] `scripts/ci/verify_rendro_hex_resolution.sh` exists and passed its clean-checkout proof on 2026-05-06.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional live Chromic smoke with a host-supervised `ChromicPDF` pool | PDF-06 | Deterministic CI should not depend on a browser process or host-supervised pool startup | In a host app configured with `config :accrue, :invoice_pdf_adapter, Accrue.InvoiceRenderer.ChromicPDF` and `{ChromicPDF, on_demand: true}` in the supervisor, render a known invoice and confirm PDF bytes are returned without any `InvoiceRendererUnavailable` error |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or a declared Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the only missing verification artifact (`scripts/ci/verify_rendro_hex_resolution.sh`)
- [x] No watch-mode flags
- [x] Feedback latency < 120 seconds for the quick lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-06
