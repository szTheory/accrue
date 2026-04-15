---
phase: 06-email-pdf
fixed_at: 2026-04-15T12:35:00Z
review_path: .planning/phases/06-email-pdf/06-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 6
skipped: 1
status: partial
---

# Phase 6: Code Review Fix Report

**Fixed at:** 2026-04-15T12:35:00Z
**Source review:** `.planning/phases/06-email-pdf/06-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope (Critical + Warning): 7
- Fixed: 6
- Skipped: 1
- Full `mix test` suite: 1013 tests, 46 properties, 0 failures

## Fixed Issues

### CR-01: Mailer worker ignores `:branding` config for `From:` header

**Files modified:** `accrue/lib/accrue/workers/mailer.ex`
**Commit:** `1a3872c`
**Applied fix:** Replaced the deprecated flat-key reads (`Application.get_env(:accrue, :from_name, ...)`) with `Accrue.Config.branding(:from_name)` / `Accrue.Config.branding(:from_email)`, so D6-02 nested branding config is honored and the deprecation shim in `Accrue.Config.branding/0` actually takes effect.

### WR-01: `Config.branding/0` `cond` has no fallthrough clause

**Files modified:** `accrue/lib/accrue/config.ex`
**Commit:** `0463f48`
**Applied fix:** Added a `true ->` clause that raises `Accrue.ConfigError` with a descriptive message when `:branding` is neither an empty list nor a populated keyword list, replacing the latent `CondClauseError` with a clear actionable error.

### WR-02: Unescaped URL interpolation into HTML body

**Files modified:** `accrue/lib/accrue/workers/mailer.ex`
**Commit:** `005b40c`
**Applied fix:** `append_hosted_url_note/3` now runs the URL through `Phoenix.HTML.html_escape/1` + `safe_to_string/1` before interpolating into the `href` attribute. Defense-in-depth for stray quotes and unexpected upstream sources.

### WR-03: `Swoosh.Email.to/2` called with `nil` when recipient is missing

**Files modified:** `accrue/lib/accrue/workers/mailer.ex`
**Commit:** `0cdbaad`
**Applied fix:**
1. `enrich/2` now resolves `:to` from `assigns[:to]`, `assigns["to"]`, or the hydrated `customer.email` and writes it back into the enriched assigns map.
2. `perform/1` short-circuits before `deliver_email/4` and returns `{:cancel, :missing_recipient}` (Oban terminal, non-retriable) when no recipient resolves — previously this crashed inside Swoosh and thrashed the queue. Refactored the mail-building pipeline into a private `deliver_email/4` helper for clarity.

**Requires human verification:** The `{:cancel, ...}` return relies on Oban 2.21's cancel-tuple semantics; verify in smoke tests that a missing-recipient job lands in `cancelled` state (not `discarded`) in your host deployment.

### WR-04: `:reply_to_email` branding key is never applied to outgoing mail

**Files modified:** `accrue/lib/accrue/workers/mailer.ex`
**Commit:** `9997618`
**Applied fix:** Added a `maybe_reply_to/2` private helper (no-op on `nil` or empty string) and wired it into the email-build pipeline immediately after `from/2`, reading from `Accrue.Config.branding(:reply_to_email)`.

### WR-05: Stripe charge ID exposed in email subject line

**Files modified:** `accrue/lib/accrue/emails/refund_issued.ex`
**Commit:** `da81d15`
**Applied fix:** Replaced the `"Refund issued for charge #{id}"` subject clause with `"Refund issued: #{formatted_amount}"` when `context.refund.formatted_amount` is present. The `context.branding` fallback and generic `"Refund issued"` fallback remain. Charge IDs stay in the email body where they belong.

## Skipped Issues

### WR-06: `EEx.eval_file/2` re-reads text templates on every email

**File:** `accrue/lib/accrue/emails/*.ex` (all 13 email modules)
**Reason:** skipped: cross-cutting refactor exceeds safe per-finding scope
**Details:** The suggested fix (`EEx.function_from_file/5`) requires identical edits across 13 email modules plus coordination with IN-01 (the duplicated `to_keyword/1` / `text_template_path/0` helpers that would become dead code). The reviewer's own fix note calls out that this is a "bonus: eliminates the 13-module `to_keyword/1` duplication" — i.e., it's entangled with IN-01, which is out of scope for this fix pass.

Additionally, `EEx.function_from_file/5` evaluates the path argument at compile time but the current pattern relies on `:code.priv_dir(:accrue)`. That works during `:accrue` compilation but is worth validating against a release build (the whole point of the fix), and we cannot run a release smoke test from inside the fixer workflow.

**Recommendation:** Handle WR-06 + IN-01 together as a single refactor PR that:
1. Extracts `use Accrue.Emails.Template` (or similar) injecting `render_text/1` from a compile-time `EEx.function_from_file/5`.
2. Verifies the `:code.priv_dir/1` path resolves correctly in a `mix release` build.
3. Deletes 13 copies of `to_keyword/1` + `text_template_path/0`.

The underlying correctness concern (disk I/O on hot path; runtime template parsing) is real but has never fired in practice, and the current tests exercise these paths green.

## Verification

- All 6 applied fixes passed `mix compile` cleanly (no warnings introduced, no existing warnings regressed).
- Full `mix test` after all commits: **1013 tests, 46 properties, 0 failures** (10 excluded tags for `:live_stripe`/`:slow`).
- Worker-specific suite `mix test test/accrue/workers/`: **46 tests, 0 failures**.
- Note: during the first full-suite run a single test (`Accrue.Processor.FakePhase3Test` "create_invoice_preview returns a non-persistent preview") flaked; a rerun with `mix test --failed` and a full rerun with `--seed 0` both pass cleanly. The flake is unrelated to any fix in this pass — none of the committed changes touch invoice preview, Phase 3 processor code, or the billing fake.

## Out-of-scope findings (Info tier, not addressed)

IN-01, IN-02, IN-03, IN-04, IN-05 remain open in REVIEW.md. IN-01 is closely tied to WR-06 and should be handled in the same follow-up refactor (see WR-06 skip recommendation above).

---

_Fixed: 2026-04-15T12:35:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
