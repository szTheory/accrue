---
phase: 90-full-template-port-cleanup
verifier: claude-opus-4-7[1m]
date: 2026-04-26
result: PASS
requirements: [MG-07]
---

# Phase 90 Verification — Full Template Port & Cleanup

## Result: ✅ PASS — 6/6 must-haves verified

**Goal (from ROADMAP):** All 13 email templates use Mailglass HEEx components; `mjml_eex` and `phoenix_swoosh` are removed from `accrue/mix.exs`; legacy `mix accrue.mail.preview` is retired.

**Requirement:** MG-07 — Port the remaining 11 MJML templates to `Mailglass.Mailable` and completely remove the MJML compiler dependency.

---

## Must-haves

### 1. ✅ All 13 email templates render through Mailglass HEEx components

**Templates ported in Phase 90:**

| Template | Plan | Module |
|----------|------|--------|
| `trial_ending` | 90-01 | `accrue/lib/accrue/emails/trial_ending.ex` |
| `trial_ended` | 90-01 | `accrue/lib/accrue/emails/trial_ended.ex` |
| `subscription_canceled` | 90-01 | `accrue/lib/accrue/emails/subscription_canceled.ex` |
| `subscription_paused` | 90-01 | `accrue/lib/accrue/emails/subscription_paused.ex` |
| `subscription_resumed` | 90-01 | `accrue/lib/accrue/emails/subscription_resumed.ex` |
| `card_expiring_soon` | 90-01 | `accrue/lib/accrue/emails/card_expiring_soon.ex` |
| `invoice_finalized` | 90-02 | `accrue/lib/accrue/emails/invoice_finalized.ex` |
| `invoice_paid` | 90-02 | `accrue/lib/accrue/emails/invoice_paid.ex` |
| `invoice_payment_failed` | 90-02 | `accrue/lib/accrue/emails/invoice_payment_failed.ex` |
| `refund_issued` | 90-02 | `accrue/lib/accrue/emails/refund_issued.ex` |
| `coupon_applied` | 90-02 | `accrue/lib/accrue/emails/coupon_applied.ex` |
| `payment_succeeded` | 90-03 | `accrue/lib/accrue/emails/payment_succeeded.ex` |

Combined with Phase 89's `receipt` and `payment_failed`, all 13 transactional templates are Mailglass-backed (the 11 listed in MG-07 plus the 2 POC templates from MG-06).

### 2. ✅ `mjml_eex` and `phoenix_swoosh` removed from `accrue/mix.exs`

```
$ grep -nE "mjml_eex|phoenix_swoosh" accrue/mix.exs
(no matches)
```

### 3. ✅ Legacy `mix accrue.mail.preview` retired

```
$ ls accrue/lib/mix/tasks/accrue.mail.preview.ex
ls: ... No such file or directory
```

### 4. ✅ Legacy MJML template assets deleted

```
$ ls accrue/priv/accrue/templates/emails/
(empty)
```

26 legacy assets removed (13 `.mjml.eex` + 13 `.text.eex`).

### 5. ✅ `Accrue.Emails.HtmlBridge` and preview-only helpers removed

- `accrue/lib/accrue/emails/html_bridge.ex` — deleted
- `Accrue.Workers.Mailer.template_for/1` — removed (per `mailglass_cleanup_test`)

### 6. ✅ Email guide rewritten around supported preview surface

`accrue/guides/email.md` — `mix accrue.mail.preview` reference removed; `/dev/email-preview` LiveView is the documented preview path. Asserted by `mailglass_cleanup_test`.

---

## Test evidence

```
$ cd accrue && mix test test/accrue/emails/
Running ExUnit with seed: 83076, max_cases: 16
Excluding tags: [:live_stripe, :slow, :compile_matrix]
................................................................................................................................
Finished in 0.2 seconds (0.2s async, 0.00s sync)
128 tests, 0 failures
```

Includes `mailglass_cleanup_test` (5 regression guards) covering:
- `Accrue.Workers.Mailer.template_for/1` no longer exported
- `mix.exs` does not declare `mjml_eex` or `phoenix_swoosh`
- `html_bridge.ex`, `accrue.mail.preview.ex`, and `payment_succeeded` MJML/text assets deleted
- No `*.mjml.eex` or `*.text.eex` files remain in `priv/accrue/templates/emails/`
- Email guide retires the CLI and documents `/dev/email-preview`

---

## MG-07 status

**MG-07: COMPLETE.** Mailglass is the only mail render path in `accrue`; the MJML compiler dependency is gone.
