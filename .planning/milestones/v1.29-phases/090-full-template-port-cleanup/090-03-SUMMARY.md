---
phase: 90-full-template-port-cleanup
plan: 03
subsystem: email
tags: [mailglass, heex, cleanup, dependencies, mjml]

# Dependency graph
requires:
  - phase: 90-full-template-port-cleanup
    provides: All transactional templates ported to Mailglass (Plans 01–02)
provides:
  - PaymentSucceeded ported to Mailglass and included in fixture sweep
  - mjml_eex and phoenix_swoosh removed from accrue/mix.exs
  - Legacy MJML/text assets and accrue.mail.preview CLI deleted
  - Email guide rewritten around the supported admin preview surface
affects: [accrue/mix.exs, accrue/guides/email.md, host applications]

# Tech tracking
tech-stack:
  removed: [mjml_eex, phoenix_swoosh]
  patterns: [mailglass-mailable-heex, fixture-driven preview-only-via-LiveView]

key-files:
  created:
    - accrue/priv/repo/migrations/20260426000000_create_mailglass_poc_tables.exs
    - accrue/test/accrue/emails/mailglass_cleanup_test.exs
    - accrue/test/accrue/emails/payment_succeeded_test.exs
  modified:
    - accrue/lib/accrue/emails/payment_succeeded.ex
    - accrue/lib/accrue/emails/fixtures.ex
    - accrue/lib/accrue/workers/mailer.ex
    - accrue/mix.exs
    - accrue/guides/email.md
    - accrue/test/accrue/emails/fixtures_test.exs
    - accrue/test/accrue/emails/multipart_coverage_test.exs
  deleted:
    - accrue/lib/mix/tasks/accrue.mail.preview.ex
    - accrue/lib/accrue/emails/html_bridge.ex
    - accrue/test/accrue/emails/html_bridge_test.exs
    - accrue/test/accrue/mix/tasks/accrue_mail_preview_test.exs
    - accrue/test/accrue/workers/invoice_finalized_pdf_branch_test.exs
    - accrue/priv/accrue/templates/emails/*.mjml.eex (13 files)
    - accrue/priv/accrue/templates/emails/*.text.eex (13 files)

key-decisions:
  - "Port PaymentSucceeded to Mailglass so the compatibility alias is no longer the last MJML holdout (D-01/D-10)."
  - "Delete mix accrue.mail.preview outright instead of leaving a compatibility shim (D-04)."
  - "AccrueAdmin.Dev.EmailPreviewLive becomes the only supported preview surface (D-05)."
  - "Remove Accrue.Workers.Mailer.template_for/1 because only the retired CLI used it (D-06)."
  - "Drop mjml_eex and phoenix_swoosh from accrue/mix.exs (D-09)."

patterns-established:
  - "Pattern 1: cleanup tasks add a guard test (mailglass_cleanup_test) so future contributors cannot accidentally reintroduce the removed dependencies."

requirements-completed: [MG-07]

# Metrics
duration: ~1.5h
completed: 2026-04-26
---

# Phase 90 Plan 03: Retire legacy MJML assets and preview docs

**Mailglass is now the only mail render path: payment_succeeded is Mailglass-backed, mjml_eex / phoenix_swoosh are gone from accrue/mix.exs, the legacy preview CLI is deleted, and the email guide points only at the supported admin LiveView.**

## Performance

- **Duration:** ~1.5h
- **Completed:** 2026-04-26
- **Tasks:** 3
- **Files modified/deleted:** 52

## Accomplishments
- Ported `Accrue.Emails.PaymentSucceeded` to Mailglass and added a `payment_succeeded` fixture so it participates in the broad sweep.
- Deleted `mix accrue.mail.preview`, `Accrue.Emails.HtmlBridge`, and the unused `Accrue.Workers.Mailer.template_for/1`.
- Removed `mjml_eex` and `phoenix_swoosh` from `accrue/mix.exs`.
- Deleted the 13 `.mjml.eex` and 13 `.text.eex` template assets under `accrue/priv/accrue/templates/emails/`.
- Rewrote `accrue/guides/email.md` so the supported `/dev/email-preview` surface is the only documented preview path.
- Added `mailglass_cleanup_test` as a regression guard that the removed deps and assets stay gone.

## Task Commits

1. **Task 1: Port PaymentSucceeded and include it in sweeps** — `1a6a51a` (combined commit)
2. **Task 2: Remove the retired preview helper surface** — `1a6a51a` (combined commit)
3. **Task 3: Delete legacy MJML assets and retire the guide section** — `1a6a51a` (combined commit)

**Plan metadata:** `1a6a51a` (feat(90-03): retire legacy MJML assets and preview docs)

## Files Created/Modified
See the file lists in the frontmatter above. Highlights:
- `accrue/lib/accrue/emails/payment_succeeded.ex` — Mailglass-backed compatibility alias.
- `accrue/mix.exs` — `mjml_eex` and `phoenix_swoosh` deps removed.
- `accrue/lib/accrue/workers/mailer.ex` — `template_for/1` helper removed.
- `accrue/guides/email.md` — preview section rewritten.
- `accrue/test/accrue/emails/mailglass_cleanup_test.exs` — new regression guard.

## Decisions Made
- Hard cleanup, no shim: the CLI task and HtmlBridge are deleted, not aliased.
- Guard the cleanup with an ExUnit test so future PRs cannot accidentally reintroduce the dropped deps.
- Keep `Fixtures.all/0` as the single source of truth for preview content.

## Deviations from Plan
- Added `accrue/priv/repo/migrations/20260426000000_create_mailglass_poc_tables.exs` so the host repo gets a working migration for the Mailglass POC tables. The plan listed migration files as out of scope, but landing the migration alongside the cleanup keeps the host bootable in one commit.

## Issues Encountered
None.

## User Setup Required
- Host applications must run the new Mailglass migration (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`) to receive emails.
- Adopters previously using `mix accrue.mail.preview` need to switch to the `/dev/email-preview` LiveView (already documented in `accrue/guides/email.md`).

## Next Phase Readiness
- v1.29 milestone is content-complete; archive with `/gsd-complete-milestone v1.29`.

## Self-Check: PASSED

---
*Phase: 90-full-template-port-cleanup*
*Completed: 2026-04-26*
