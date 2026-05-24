---
phase: 128-campaign-engine-foundation-idempotency-must-fix
plan: 04
subsystem: dunning / mailer
tags: [dunning, idempotency, oban-unique, email-templates, DUN-04, DUN-01]
requires:
  - "Accrue.Mailer.Default.deliver/2 (existing enqueue boundary)"
  - "Accrue.Workers.Mailer (existing Oban worker + Mailglass lane)"
  - "Accrue.Emails.CardExpiringSoon (clone target for the new step templates)"
provides:
  - "Per-invoice idempotent :invoice_payment_failed enqueue (Oban unique, top-level invoice_id discriminator)"
  - "Accrue.Emails.DunningActionRequired (atom :dunning_action_required)"
  - "Accrue.Emails.DunningFinalNotice (atom :dunning_final_notice)"
  - "idempotency_key(:invoice_payment_failed) backstop key accrue:v1:invoice_payment_failed:<id>"
affects:
  - "Accrue.Mailer.Default.deliver/2 (now derives a per-type Oban unique)"
  - "Accrue.Workers.Mailer (new Mailglass-lane routing + template clauses for :invoice_payment_failed)"
tech-stack:
  added: []
  patterns:
    - "Oban unique-at-enqueue with TOP-LEVEL arg discriminator (keys narrow to top-level args only — no recursion)"
    - "per-type Oban arg builder + nil/empty guard fallback to unique:false"
key-files:
  created:
    - accrue/lib/accrue/emails/dunning_action_required.ex
    - accrue/lib/accrue/emails/dunning_final_notice.ex
    - accrue/test/accrue/workers/mailer_idempotency_test.exs
    - accrue/test/accrue/emails/dunning_step_emails_test.exs
    - accrue/test/accrue/workers/mailer_dunning_wiring_test.exs
  modified:
    - accrue/lib/accrue/mailer/default.ex
    - accrue/lib/accrue/workers/mailer.ex
decisions:
  - "Promote invoice_id to a TOP-LEVEL Oban arg ONLY for the deduped :invoice_payment_failed path; every other type keeps the bare %{type:, assigns:} shape (no scope creep, no regression)."
  - "Route :invoice_payment_failed through the Mailglass lane so the D-14 backstop key fires; the PRIMARY dedup remains the D-13 enqueue-unique (lane-independent)."
  - "Skip PDF attachment for :invoice_payment_failed in the Mailglass lane — these dunning-step emails carry no PDF (Rule 1 fix for a bug the routing change would otherwise introduce)."
metrics:
  duration: "~6 min"
  tasks: 3
  files: 7
  completed: "2026-05-24"
---

# Phase 128 Plan 04: Idempotency Must-Fix + Dunning Step Templates Summary

Closed the latent duplicate-send bug on `:invoice_payment_failed` with a per-invoice Oban `unique`-at-enqueue dedup (top-level `invoice_id` discriminator) plus a Mailglass-lane `idempotency_key/2` backstop, and shipped the two new dunning step email templates (`DunningActionRequired`, `DunningFinalNotice`) the default journey resolves via `default_template/1`.

## What Was Built

**DUN-04 (idempotency must-fix):**
- `Accrue.Mailer.Default.deliver/2` now derives a per-type Oban `unique` via `dedup_unique/2`. ONLY `:invoice_payment_failed` (with a usable `invoice_id`) gets a unique — `keys: [:type, :invoice_id]`, `period: :infinity`, `states` including `:completed` (excluding `:cancelled`/`:discarded`). Every other type returns `false` (a no-op — no regression).
- A new `dedup_args/3` PROMOTES `invoice_id` to a TOP-LEVEL Oban arg for the deduped `:invoice_payment_failed` enqueue (verified against `deps/oban/lib/oban/engines/basic.ex:514-525`: `Map.take` over the unique `keys` operates on TOP-LEVEL stringified arg keys with no recursion). A nested-only `invoice_id` would have collapsed every invoice to one signature → global suppression (a worse bug); the promotion makes the signature per-invoice. A nil/empty `invoice_id` falls back to the non-promoted shape + `unique: false`.
- `Accrue.Workers.Mailer.idempotency_key(:invoice_payment_failed, assigns)` backstop keyed on `invoice_id` → `accrue:v1:invoice_payment_failed:<invoice_id>`; nil/empty → `{:error, :missing_invoice_id}`.
- `:invoice_payment_failed` is now routed to the Mailglass lane in `deliver_email/4` so the backstop key actually takes effect.

**DUN-01 (the two new step templates):**
- `Accrue.Emails.DunningActionRequired` (atom `:dunning_action_required`) — firmer step-2 copy, portal update-payment CTA.
- `Accrue.Emails.DunningFinalNotice` (atom `:dunning_final_notice`) — urgent/last-chance step-3 copy, portal CTA.
- Both clone the `CardExpiringSoon` Mailglass + `Phoenix.Component` convention, export the full quartet (`subject/1`, `message/1`, `render/1`, `render_text/1`), and resolve via two new `default_template/1` clauses (plus `@compile {:no_warn_undefined}` entries).

## Tasks

| Task | Name | Commits | Key files |
| ---- | ---- | ------- | --------- |
| 1 | Two new dunning step email templates (D-01, D-02) | `9a669bf` (test), `38b2775` (feat) | `dunning_action_required.ex`, `dunning_final_notice.ex`, `dunning_step_emails_test.exs` |
| 2 | Primary enqueue-dedup + Mailglass backstop + template registration (D-13, D-14, D-02) | `a0b894d` (test), `f021497` (feat) | `mailer/default.ex`, `workers/mailer.ex`, `mailer_dunning_wiring_test.exs` |
| 3 | Wave-0 idempotency integration test (DUN-04) | `eda66a5` (test + Rule 1 fix) | `mailer_idempotency_test.exs`, `workers/mailer.ex` |

All three tasks followed RED → GREEN (no REFACTOR needed — the email modules are verbatim clones and the mailer changes are surgical).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Skip PDF attachment for `:invoice_payment_failed` in the Mailglass lane**
- **Found during:** Task 3 (running the backstop delivery test through `perform_job`).
- **Issue:** Routing `:invoice_payment_failed` to the Mailglass lane (a Task 2 requirement) exposed it to `deliver_mailglass/4`'s unconditional `maybe_attach_pdf/3` call. The Mailglass lane attempts an invoice PDF render whenever an `invoice_id` is present (the receipt behavior), so a failed-payment email with `invoice_id: "in_KEY"` raised `Accrue.PDF.RenderFailed` (CastError on a non-UUID id). The Swoosh lane had gated PDF via `needs_pdf?/1`, which excludes `:invoice_payment_failed`; the plan explicitly states these step-style emails carry no PDF.
- **Fix:** Introduced `maybe_attach_pdf_for_lane/3` with a dedicated `:invoice_payment_failed -> msg` (skip) clause; all other Mailglass types fall through to the existing `maybe_attach_pdf/3`. Preserves the receipt/payment_failed PDF behavior.
- **Files modified:** `accrue/lib/accrue/workers/mailer.ex`
- **Commit:** `eda66a5`

## Verification

- `cd accrue && mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` → 9 tests, 0 failures (the plan gate).
- `cd accrue && mix test test/accrue/emails --seed 0` → 142 tests, 0 failures.
- `cd accrue && mix compile --warnings-as-errors` → exits 0.
- Regression sweep `cd accrue && mix test test/accrue/workers test/accrue/emails test/accrue/mailer_test.exs test/accrue/webhook/default_handler_mailer_dispatch_test.exs --seed 0` → 212 tests, 0 failures (the existing Mailglass-lane dispatch test still green after the routing + PDF-skip change).

## Threat Mitigations Confirmed

- **T-128-07 / T-128-19** (notification spam / global-suppression regression): per-invoice granularity proven — two distinct invoices each enqueue a separate job (`conflict?: false`), and a duplicate for the SAME invoice returns `conflict?: true` (one job), surviving a `:completed` week-2 redelivery. The top-level `invoice_id` arg is asserted directly.
- **T-128-08** (info disclosure): the promoted top-level `invoice_id` is the same scalar id already validated by `only_scalars!/1`; no new PII surface.
- **T-128-09** (dedup key collision): `keys: [:type, :invoice_id]` includes `:type`; keyed on `invoice_id` (always present), not nullable `invoice_number`.

## Notes / Scope Fence Honored

- No telemetry / ledger / engine code (Phase 129/131 boundary respected).
- No dedup/promotion for any non-`:invoice_payment_failed` type.
- Pre-existing modified file `accrue/guides/maturity-and-maintenance.md` was left untouched (out of scope, present before this plan).

## Self-Check: PASSED

All created files exist on disk and all 5 per-task commits are present in git history.
