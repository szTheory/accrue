---
quick_id: 260426-fb8
slug: mix-format-v1.29
status: complete
date: 2026-04-26
description: "Mix format auto-fix for v1.29 Mailglass commits (Phase 1 of post-v1.29 main-CI recovery)"
pr: 16
pr_url: "https://github.com/szTheory/accrue/pull/16"
branch: fix/mix-format-v1.29
commit: 9869c85
---

# Quick Task 260426-fb8: Mix format auto-fix — Summary

## Result

✅ **Format gate is GREEN across all 5 Release gate matrix cells on PR #16.**

The compile-dependent gates (Browser UAT, Phase 18 Stripe Tax gate, test/dialyzer/credo portions of each matrix cell) stay RED for an unrelated reason — the structural Mailglass-on-Hex blocker. That's expected and tracked as a separate milestone (Phase 2 of the recovery).

## What changed

`cd accrue && mix format` auto-fixed 20 files (156 insertions, 45 deletions). All cosmetic — multi-line tuple wrapping, `do` block formatting, blank lines after function calls, comment indentation.

## Files modified

20 files in `accrue/`:

**lib/accrue/emails/** (13 files): card_expiring_soon, coupon_applied, invoice_finalized, invoice_paid, invoice_payment_failed, payment_failed, payment_succeeded, receipt, refund_issued, subscription_canceled, subscription_paused, subscription_resumed, trial_ended, trial_ending — all the v1.29 Mailglass-ported mailers had the same `from({...})` tuple wrap.

**lib/accrue/** (4 other files):
- `application.ex` — `Logger.warning(...)` indentation
- `billing/meter_event_actions.ex` — `with :ok <-` indentation
- `billing/subscription_actions.ex` — `# Use non-bang variants` comment indent
- `workers/mailer.ex` — `{:error, reason} -> {:cancel, reason}` multi-line + a string interpolation wrap

**test/accrue/** (3 files):
- `invoices/components_test.exs` — multi-line `build_context(%{...})` wrap
- `webhook/default_handler_mailer_dispatch_test.exs` — blank lines + `do` block test header wraps

## Verification (local)

- `cd accrue && mix format --check-formatted` → exit 0 ✓
- `cd accrue_admin && mix format --check-formatted` → exit 0 ✓
- `cd accrue && mix compile --warnings-as-errors` → clean ✓
- `cd accrue && mix test test/accrue/emails/ test/accrue/invoices/components_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs` → 141 tests, 0 failures ✓

## Verification (CI on PR #16)

| Gate | Before | After |
|------|--------|-------|
| `Accrue format` (Floor) | FAIL | **PASS** |
| `Accrue format` (Primary 1.18/27 sigra=off opentelemetry=off) | FAIL | **PASS** |
| `Accrue format` (Primary 1.18/27 sigra=on opentelemetry=off) | FAIL | **PASS** |
| `Accrue format` (Primary 1.18/27 sigra=off opentelemetry=on) | FAIL | **PASS** |
| `Accrue format` (Forward-compat 1.18.4/28) | FAIL | **PASS** |
| `Docs and bash contracts (shift-left)` | FAIL | **PASS** |
| `Release manifest SSOT (REL-02)` | PASS | **PASS** |
| `Browser UAT` | FAIL (Mailglass dep) | FAIL (Mailglass dep) — unchanged |
| `Phase 18 Stripe Tax gate` | FAIL (Mailglass dep) | FAIL (Mailglass dep) — unchanged |
| `Release gate` test/credo/dialyzer steps | FAIL (Mailglass dep) | FAIL (Mailglass dep) — unchanged |
| `Host integration` | SKIPPED (gated on earlier failures) | SKIPPED — unchanged |
| `Annotation sweep` | SKIPPED | SKIPPED — unchanged |

`Docs and bash contracts (shift-left)` actually went from FAIL → PASS too — bonus. The earlier `docs-contracts-shift-left` job was apparently failing on something unrelated to Mailglass that was format-or-doc-adjacent. Now green.

## Out of scope (deferred to Phase 2)

The Mailglass path dep in `accrue/mix.exs:59` and `accrue_admin/mix.exs` cannot be resolved by CI checkouts because Mailglass lives as a sibling repo. This blocks every gate that compiles either package. Fix: publish Mailglass to Hex, then change path deps to Hex deps in this repo.

That's a separate milestone, executed in `~/projects/mailglass` first, then a small follow-up PR here.

## Status

Phase 1 of the post-v1.29 main-CI recovery — DONE. PR #16 is open and ready to merge. Awaiting user confirmation before merge.
