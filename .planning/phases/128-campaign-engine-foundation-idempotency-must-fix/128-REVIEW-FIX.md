---
phase: 128-campaign-engine-foundation-idempotency-must-fix
fixed_at: 2026-05-24T18:35:00Z
review_path: .planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 128: Code Review Fix Report

**Fixed at:** 2026-05-24T18:35:00Z
**Source review:** .planning/phases/128-campaign-engine-foundation-idempotency-must-fix/128-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (2 Critical + 6 Warning; the 4 Info findings are out of scope for `critical_warning`)
- Fixed: 8
- Skipped: 0

**Verification:** `cd accrue && mix compile --warnings-as-errors` exits 0. All affected suites
pass with `--seed 0`: the full `test/accrue/webhook/` directory (117 tests, 0 failures) plus the
worker/email/config/property suites (combined 6 properties, 95 tests, 0 failures). A pre-existing,
unrelated test-only warning (`@summary_type` in `default_handler_entitlement_summary_test.exs`, a
file not touched by this fix) remains; it does not affect the library compile.

## Fixed Issues

### CR-01: Step-2 / step-3 dunning emails can be sent twice on a worker retry (no idempotency)

**Files modified:** `accrue/lib/accrue/workers/mailer.ex`, `accrue/test/accrue/workers/mailer_idempotency_test.exs`
**Commit:** e3407184
**Applied fix:** Took the reviewer's approach 1. Routed `:dunning_action_required` and
`:dunning_final_notice` through the Mailglass lane in `deliver_email/4` (and skip the lane PDF
render for them, mirroring `:invoice_payment_failed`), and added an `idempotency_key/2` clause for
both types keyed on the campaign identity (`subscription_id` + `campaign_started_at` anchor) plus
the type: `accrue:v1:<type>:<sub>:<anchor>`. The anchor is the immutable campaign anchor threaded
unchanged through every `DunningStep` retry, so the key is stable across retries — a re-executed
worker re-derives the same key and the second delivery is deduped (a missing identity cancels with
`:missing_campaign_identity`). Added a parameterized test proving the stamped key for both types and
the missing-identity cancel path. This closes the no-double-sends gap that was previously open for
steps 2 and 3 while step 1 was protected.

### CR-02: Campaign anchor is never cleared on terminal (`:unpaid`) transition

**Files modified:** `accrue/lib/accrue/workers/dunning_step.ex`, `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/test/accrue/workers/dunning_step_test.exs`, `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs`
**Commit:** 67652386
**Status note:** fixed: requires human verification (logic/condition change to the live-campaign guard).
**Applied fix:** Changed the `DunningStep` cancel-guard `campaign_active?/1` from `past_due?/1`
(which matches both `:past_due` AND `:unpaid`) to `dunning_sweepable?/1` (`:past_due` only), and
corrected the misleading "(or unpaid)" comment. A terminated `:unpaid` sub with a still-set anchor
is now treated as NOT live and is never dunned further. Additionally extended
`maybe_finalize_dunning_campaign/2` to finalize the campaign (clear the anchor + stash the
post-commit bulk cancel) on EITHER edge out of `:past_due` — recovery (`active?`) OR terminal
exhaustion (`dunning_exhausted_status/1` non-nil) — via a new `finalizing_transition?/1` helper, so
scheduled steps are proactively cancelled on `:unpaid`/`:canceled` rather than relying solely on the
per-step guard. Added coverage: a terminal `:unpaid` cancel-guard backstop test, and a
parameterized cancel-on-terminal-exhaustion test (`:unpaid` and `:canceled`) proving the anchor is
nilled and scheduled steps are cancelled.

### WR-01: `dunning_campaign_grace!` hardcodes the `grace_days` default instead of reading the schema

**Files modified:** `accrue/lib/accrue/config.ex`
**Commit:** 5512ae87
**Applied fix:** Extracted `@default_grace_days 14` and
`@default_dunning_campaign [enabled: true, steps: @default_dunning_steps]` module attributes, and
referenced them from the `@schema` defaults, the `dunning_campaign/0` accessor, and the
`validate_dunning_campaign_grace!/1` boot guard. The boot guard can no longer validate against a
stale default that drifted from the schema (the `14` and default journey were previously inlined as
literals in three places).

### WR-02: `chain_next/4` re-resolves against LIVE config, not the campaign's enrolled cadence

**Files modified:** `accrue/lib/accrue/workers/dunning_step.ex`, `accrue/test/accrue/workers/dunning_step_test.exs`
**Commit:** 75f8502a
**Applied fix:** Took the reviewer's second option (lower-risk, no Oban-args schema change). Made
`advance_past_current/3` return `:unknown_step` when the just-delivered step key is absent from the
live cadence (instead of falling back to the wall clock), and had `chain_next/4` treat that as
journey-exhausted (enqueue nothing). This removes the double-send vector where a mid-flight cadence
edit could re-resolve to a different step whose boundary is still pending. Added a test that edits
the live cadence to drop a step, delivers that (now-unknown) step, and asserts nothing is enqueued.

### WR-03: `dunning_source/2` reads `DateTime.utc_now/0` directly instead of `Accrue.Clock`

**Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`, `accrue/test/accrue/webhook/dunning_exhaustion_test.exs`
**Commit:** 54d34289
**Applied fix:** Replaced `DateTime.utc_now()` with `Accrue.Clock.utc_now()` in `dunning_source/1`
for Fake-lane determinism, consistent with every other clock read in the phase. Updated the
exhaustion test's seeded `dunning_sweep_attempted_at` timestamps to anchor to `Accrue.Clock` (the
Fake clock under test) instead of the wall clock — the prior wall-clock seeds were now inconsistent
with the deterministic comparison and the "older than 5 minutes -> :stripe_native" case failed
before the test was corrected. All 7 exhaustion tests pass after the update.

### WR-04: Tests configure `:dunning` with schema-INVALID values that would fail boot validation

**Files modified:** `accrue/test/accrue/webhook/dunning_campaign_start_test.exs`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs`
**Commit:** 0eb7c395
**Applied fix:** Changed the two test fixtures from `mode: :stripe_native` / `terminal_action:
:cancel` (both rejected by the `@schema` `{:in, ...}` constraints) to the schema-valid `mode:
:stripe_smart_retries` / `terminal_action: :canceled`. Added `assert Accrue.Config.validate_at_boot!()
== :ok` to `disable_campaign!/0` so future config drift is caught (the fixture now passes boot
validation as a faithful host config would).

### WR-05: `safe_deliver/2` swallows ALL throws/exits, including sandbox/`DBConnection` ownership errors

**Files modified:** `accrue/lib/accrue/webhook/default_handler.ex`
**Commit:** 6743dab9
**Status note:** fixed: requires human verification (error-handling/control-flow change with no
automated test for the new exit-reraise path).
**Applied fix:** Narrowed the `catch` in `safe_deliver/2` from `catch kind, reason` (unconditional)
to `catch :throw, reason` only, so abnormal `exit`s (e.g. `DBConnection.OwnershipError`,
`exit(:shutdown)`) propagate (fail loud) rather than being masked as a silent `:ok` behind a
successful reconciliation. Note `safe_deliver/2` runs at the post-commit dispatch site, so a
propagated exit does not roll back committed state. Enriched the existing
`[:accrue, :mailer, :dispatch_failed]` telemetry with `subscription_id` and `invoice_id` from
assigns (via a new `emit_dispatch_failed/3` helper) so a dropped dunning email is reconstructable.
This adds metadata to an EXISTING telemetry event — no new event family was introduced (respects the
Phase 129/131 telemetry scope fence).

### WR-06: Resolver moduledoc and property-test doc contradict the implementation's boundary semantics

**Files modified:** `accrue/test/property/dunning_campaign_property_test.exs`
**Commit:** 494c4774
**Applied fix:** Corrected the property-test moduledoc from "strictly greater than" to "greater than
or equal to" so it matches both the resolver implementation (`>=` in `pending_step?/2`) and the
test's own `expected_next/2` oracle (also `>=`). Documentation-only change; the 4 properties / 4
tests still pass.

## Skipped Issues

None — all in-scope findings were fixed. The 4 Info findings (IN-01 duplicated email-template
module, IN-02 hardcoded brand fallbacks, IN-03 non-total `email_type/1`, IN-04 deferred migration
index) are out of scope for `fix_scope: critical_warning` and were not attempted.

---

_Fixed: 2026-05-24T18:35:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
