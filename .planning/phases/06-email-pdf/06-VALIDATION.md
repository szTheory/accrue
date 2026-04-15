---
phase: 6
slug: email-pdf
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated by the planner from 06-RESEARCH.md `## Validation Architecture`
> and finalized before execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test --only phase6` |
| **Full suite command** | `cd accrue && mix test` |
| **Estimated runtime** | ~30 seconds (test adapters avoid Chromium + real MJML NIF warm) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --only phase6`
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green including `mix credo --strict` and `mix dialyzer`
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

*Populated by the planner. Each task in every PLAN.md MUST map to a row here
covering: Task ID · Plan · Wave · Requirement(s) · Test Type · Automated Command · File Exists.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/support/mailer_test_helpers.ex` — `assert_email_sent/2`, `assert_no_email_sent/0`, refute helpers
- [ ] `accrue/test/support/pdf_test_helpers.ex` — `assert_pdf_rendered/2` capturing last ChromicPDF.Test invocation
- [ ] `accrue/test/support/email_fixtures.ex` — deterministic RenderContext builders per email type (13 types)
- [ ] `accrue/test/support/responsive_render_matrix.md` — manual-check matrix (Outlook/Gmail/Apple Mail) with MJML preview artifacts
- [ ] Property test scaffolding for money + CLDR formatting (stream_data generators)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| MJML responsive rendering in Outlook/Gmail/Apple Mail | MAIL-15 | No headless Litmus-equivalent in OSS; desktop Outlook quirks unobservable via automated check | Run `mix accrue.emails.preview` → open each of 13 types in Litmus or paste into Gmail/Outlook/Apple Mail; screenshot into `responsive_render_matrix.md` |
| Visual parity of PDF layout vs email HTML body | PDF-07 | Byte-identical check is too strict (fonts); human perceptual check required | Render same invoice via `render_invoice_pdf/2` + via email HTML → visually compare in phase sign-off |
| Dark-mode email rendering in Apple Mail / Gmail | MAIL-16 | Requires real client | Documented in render matrix |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
