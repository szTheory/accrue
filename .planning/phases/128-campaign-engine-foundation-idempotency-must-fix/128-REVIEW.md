---
phase: 128-campaign-engine-foundation-idempotency-must-fix
reviewed: 2026-05-24T18:17:04Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - accrue/lib/accrue/billing/subscription.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/dunning/campaign.ex
  - accrue/lib/accrue/emails/dunning_action_required.ex
  - accrue/lib/accrue/emails/dunning_final_notice.ex
  - accrue/lib/accrue/mailer/default.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/lib/accrue/workers/dunning_step.ex
  - accrue/lib/accrue/workers/mailer.ex
  - accrue/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs
  - accrue/test/accrue/billing/subscription_campaign_anchor_test.exs
  - accrue/test/accrue/config_dunning_campaign_test.exs
  - accrue/test/accrue/emails/dunning_step_emails_test.exs
  - accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs
  - accrue/test/accrue/webhook/dunning_campaign_keying_test.exs
  - accrue/test/accrue/webhook/dunning_campaign_start_test.exs
  - accrue/test/accrue/workers/dunning_step_test.exs
  - accrue/test/accrue/workers/mailer_dunning_wiring_test.exs
  - accrue/test/accrue/workers/mailer_idempotency_test.exs
  - accrue/test/property/dunning_campaign_property_test.exs
findings:
  critical: 2
  warning: 6
  info: 4
  total: 12
status: issues_found
---

# Phase 128: Code Review Report

**Reviewed:** 2026-05-24T18:17:04Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the dunning campaign engine: config cadence + cross-field boot guard, the
`dunning_campaign_started_at` anchor column, the pure step resolver, the Oban-unique
`DunningStep` worker, the `:invoice_payment_failed` enqueue dedup, and the webhook
wiring (atomic first-transition elector + post-commit cancel-on-recovery).

The single-winner elector (`update_all WHERE is_nil(...)`), the post-commit
cancel ordering, the anchor-keyed cancel isolation, and the pure resolver are all
well-built and well-tested. The standalone-vs-campaign day-0 REPLACE gate is correct.

However, the phase's central goal — **idempotency / no double-sends** — has a real gap.
The two NEW dunning-step emails (`:dunning_action_required`, `:dunning_final_notice`)
have **neither enqueue-level nor delivery-level dedup**, while the `DunningStep` worker
delivers the step email BEFORE it does retryable work (`Oban.insert` of the next step).
A `DunningStep` retry therefore re-sends those emails. The day-0 `:reminder` email is
protected (Mailer dedup keys on `invoice_id`), but steps 2 and 3 are not (CR-01).

Separately, a campaign that reaches a terminal state via Stripe-native termination or
the sweeper (`:unpaid`) never has its anchor cleared, so in-flight steps keep firing to a
terminated customer; the cancel-guard's reliance on `past_due?/1` (which *includes*
`:unpaid`) actively keeps the campaign "active" in that state (CR-02).

Test fidelity is the other recurring theme: several suites write `:dunning` config that
would be **rejected by the schema at boot** (`mode: :stripe_native`, `terminal_action:
:cancel`), passing only because the read accessors never re-validate (WR-04).

## Critical Issues

### CR-01: Step-2 / step-3 dunning emails can be sent twice on a worker retry (no idempotency)

**File:** `accrue/lib/accrue/workers/dunning_step.ex:74-101`, `accrue/lib/accrue/mailer/default.ex:78-88`, `accrue/lib/accrue/workers/mailer.ex:74-85`

**Issue:** The phase's stated focus is "idempotency (no double-sends)", but only the
day-0 `:reminder` email is actually deduped. In `perform/1`:

```elixir
deliver_step(sub, step_key_str, anchor, args)   # sends the email FIRST
chain_next(subscription_id, step_key_str, anchor, args)  # then does retryable work
{:ok, :delivered}
```

`deliver_step/4` calls `Mailer.deliver(email_type(step_key_str), assigns)`. For
`:dunning_action_required` and `:dunning_final_notice`, `Accrue.Mailer.Default.dedup_unique/2`
returns `false` (only `:invoice_payment_failed` gets a `unique` keyword), so the Mailer
enqueue is NOT deduped, and `Accrue.Workers.Mailer.deliver_email/4` routes those two types
through the **Swoosh lane, which applies no delivery-level idempotency_key** (see the
explicit comment at `mailer.ex:80-81` and `idempotency_key/2` only handling
`:receipt`/`:payment_failed`/`:payment_succeeded`/`:invoice_payment_failed`).

`chain_next/4` -> `enqueue_step/5` -> `Oban.insert/1` runs AFTER the email is delivered.
If that insert raises (transient DB/connection error), `perform/1` raises, Oban retries
the SAME `DunningStep` job (`max_attempts: 3`). On retry, `deliver_step/4` runs again and
enqueues a SECOND `:dunning_action_required` (or `:dunning_final_notice`) email. The D-16
`unique` on `DunningStep` does NOT help here — the retry re-executes the existing job
rather than enqueuing a duplicate. Net effect: the customer receives the action-required
or final-notice email twice (or up to 3x).

This is the exact class of defect ("no double-sends") the phase was created to prevent;
it is closed for step 1 and left open for steps 2 and 3.

**Fix:** Give the step emails the same delivery-level idempotency the reminder has. Two
viable approaches:

1. Route all dunning-step types through the Mailglass lane and give them an
   `idempotency_key/2` keyed on the campaign identity (stable across retries):

```elixir
# mailer.ex — deliver_email/4
defp deliver_email(type, template_mod, atomized, recipient)
     when type in [:dunning_action_required, :dunning_final_notice] do
  deliver_mailglass(type, template_mod, atomized, recipient)
end

# mailer.ex — idempotency_key/2
defp idempotency_key(type, assigns)
     when type in [:dunning_action_required, :dunning_final_notice] do
  sub = assigns[:subscription_id] || assigns["subscription_id"]
  anchor = assigns[:campaign_started_at] || assigns["campaign_started_at"]
  if is_binary(sub) and is_binary(anchor) and sub != "" and anchor != "" do
    "accrue:v1:#{type}:#{sub}:#{anchor}"
  else
    {:error, :missing_campaign_identity}
  end
end
```

2. OR give the `Mailer.Default` enqueue a `unique` for these types keyed on
   `[:type, :subscription_id, :campaign_started_at]` (requires promoting those scalars to
   top-level args, mirroring the `invoice_id` promotion at `default.ex:53-64`).

Either way, the key must be derived from the campaign anchor + step (already threaded into
`deliver_step/4`'s assigns), so it is stable across `DunningStep` retries.

### CR-02: Campaign anchor is never cleared on terminal (`:unpaid`) transition — steps keep firing to a terminated subscription

**File:** `accrue/lib/accrue/webhook/default_handler.ex:804-828`, `accrue/lib/accrue/workers/dunning_step.ex:146-148`

**Issue:** `maybe_finalize_dunning_campaign/2` only clears the anchor (and stashes the
post-commit cancel) when `Subscription.active?(updated)` is true. When the subscription
transitions OUT of `:past_due` to a terminal `:unpaid` (the default `terminal_action`) —
either via the Accrue sweeper or Stripe-native termination — the anchor is left set, and
no `Oban.cancel_all_jobs` is stashed.

The `DunningStep` cancel-guard (`campaign_active?/1`) does NOT save it:

```elixir
defp campaign_active?(%Subscription{} = sub) do
  Subscription.past_due?(sub) and Subscription.dunning_campaign_active?(sub)
end
```

`Subscription.past_due?/1` returns true for BOTH `:past_due` AND `:unpaid`
(`subscription.ex:156-158`). So an `:unpaid` subscription with a still-set anchor is
treated as an ACTIVE campaign, and any in-flight scheduled step (`:action_required`,
`:final_notice`) WILL deliver — dunning a customer whose subscription is already
terminated, and continuing to chain further steps.

The config grace-guard (`last_step.after_days <= grace_days`) only enforces ordering on
the *happy default path*. It does not hold under: clock skew, Oban backoff delaying a
step past the terminal transition, a host whose Stripe Smart Retries terminate earlier
than `grace_days`, or `terminal_action: :unpaid` arriving before the final-notice step's
scheduled time. In all of those, this fires dunning email(s) after termination.

Note the module's own doc (`subscription.ex:230-243`) draws exactly this line: `:unpaid`
"has already reached its terminal state ... and must not be swept again." The campaign
engine ignores that boundary.

**Fix:** The cancel-guard should treat ONLY `:past_due` (not `:unpaid`) as a live
campaign, mirroring `dunning_sweepable?/1`:

```elixir
defp campaign_active?(%Subscription{} = sub) do
  Subscription.dunning_sweepable?(sub) and Subscription.dunning_campaign_active?(sub)
end
```

AND `maybe_finalize_dunning_campaign/2` should also clear the anchor + schedule the
post-commit cancel on a terminal transition (e.g. when
`Subscription.dunning_exhausted_status(updated)` is non-nil), not only on recovery — so
scheduled steps are proactively cancelled rather than relying on the per-step guard.
At minimum, fix the guard (it is the backstop the design leans on).

## Warnings

### WR-01: `dunning_campaign_grace!` hardcodes the `grace_days` default instead of reading the schema

**File:** `accrue/lib/accrue/config.ex:1101-1110`

**Issue:** `validate_dunning_campaign_grace!/1` reads `grace_days = Keyword.get(dunning, :grace_days, 14)` and `raw_campaign = Keyword.get(dunning, :campaign, enabled: true, steps: @default_dunning_steps)` — duplicating the schema defaults (14, and the default journey) as inline literals. If the `:dunning` schema default for `:grace_days` ever changes, this boot guard silently validates against the stale default and could pass a config that the real default would reject (or vice-versa). The same hardcoded `14` also appears at `dunning_campaign/0:830`.

**Fix:** Derive the default from the schema, e.g. read it from `@schema[:dunning][:keys][:grace_days][:default]`, or extract a module attribute `@default_grace_days 14` referenced by both the schema and this guard so they cannot drift.

### WR-02: `chain_next/4` re-resolves against LIVE config, not the campaign's enrolled cadence

**File:** `accrue/lib/accrue/workers/dunning_step.ex:180-211`

**Issue:** `chain_next/4` calls `Config.dunning_campaign_steps()` (current app env) and `advance_past_current/3` calls `find_after_days/2` against that same live list. If a host edits the cadence (or disables the campaign) mid-flight, an in-progress campaign resolves against the NEW steps. Worse: if the just-delivered `step_key_str` is no longer present in the live config, `find_after_days/2` returns `nil` and `advance_past_current/3` falls back to wall-clock `now` (`dunning_step.ex:199-203`). With a stale anchor far in the past this usually yields `:done`, but with a recently-started campaign and a reordered cadence it can re-resolve to a step whose boundary is still pending — potentially re-enqueuing a step under a different key. Combined with CR-01's missing dedup, that is another double-send vector.

**Fix:** Thread the enrolled step list (or a cadence version/hash) through the Oban args at enqueue time so the chain resolves against the cadence the campaign started with, OR make the wall-clock fallback in `advance_past_current/3` return a sentinel that forces `:done` when the current step key is unknown (treat "step no longer configured" as journey-exhausted rather than re-resolving).

### WR-03: `dunning_source/2` reads `DateTime.utc_now/0` directly instead of `Accrue.Clock`

**File:** `accrue/lib/accrue/webhook/default_handler.ex:877-883`

**Issue:** `dunning_source/1` uses `DateTime.diff(DateTime.utc_now(), attempted_at, :second) < 300` to decide `:accrue_sweeper` vs `:stripe_native`. Everywhere else in this phase the code is careful to read the wall clock via `Accrue.Clock.utc_now/0` for Fake-lane determinism (e.g. `dunning_step.ex:200`, `default_handler.ex:1120`, `mailer.ex` paths). This direct `DateTime.utc_now/0` makes the exhaustion-telemetry `source` tag non-deterministic under the Fake clock and could flap right at the 300s boundary in tests.

**Fix:** Replace `DateTime.utc_now()` with `Accrue.Clock.utc_now()` for consistency with the phase's determinism contract.

### WR-04: Tests configure `:dunning` with schema-INVALID values that would fail boot validation

**File:** `accrue/test/accrue/webhook/dunning_campaign_start_test.exs:101-108`, `accrue/test/accrue/webhook/default_handler_mailer_dispatch_test.exs:382-387`

**Issue:** `disable_campaign!/0` and the mailer-dispatch test set:

```elixir
Application.put_env(:accrue, :dunning,
  mode: :stripe_native,        # schema requires :stripe_smart_retries | :disabled
  terminal_action: :cancel,    # schema requires :unpaid | :canceled
  ...)
```

Both `:stripe_native` and `:cancel` are rejected by the `@schema` `{:in, ...}` constraints
(`config.ex:260,262`). These tests only pass because they write directly to app env and the
read accessors (`dunning_campaign_enabled?/0` -> `get!(:dunning)`) never re-validate. The
test config is not a faithful representation of a bootable host config — it masks the fact
that a host copying these values would crash at `validate_at_boot!/0`.

**Fix:** Use schema-valid values in the test fixtures: `mode: :stripe_smart_retries` (or
`:disabled`) and `terminal_action: :canceled`. Optionally assert `Config.validate_at_boot!() == :ok`
on the test fixture so config drift is caught.

### WR-05: `safe_deliver/2` swallows ALL throws/exits, including sandbox/`DBConnection` ownership errors

**File:** `accrue/lib/accrue/webhook/default_handler.ex:1727-1747`

**Issue:** `safe_deliver/2` wraps dispatch in `rescue e ->` AND `catch kind, reason ->`,
converting every failure (including `DBConnection.OwnershipError`, `exit`s, and
programmer errors like a bad template) into telemetry + `:ok`. While the intent (don't
roll back reconciled state on a mailer failure) is sound, catching `catch kind, reason`
unconditionally also suppresses `exit(:shutdown)` / `exit(:normal)` propagation and can
hide genuine bugs (e.g. a malformed assigns map) as silent telemetry. This is a
robustness/observability hazard for a payments library where a silently-dropped dunning
email is a revenue event.

**Fix:** Narrow the rescue to expected error classes, or re-raise on `exit`:
`catch :exit, reason -> reraise` for abnormal exits, and let `catch :throw, _` be handled.
At minimum, include enough detail in the telemetry to reconstruct which dunning email was
dropped (currently only `type` + `inspect(e)`; add `subscription_id`/`invoice_id` from
assigns).

### WR-06: Resolver moduledoc and property-test doc contradict the implementation's boundary semantics

**File:** `accrue/lib/accrue/dunning/campaign.ex:32-42`, `accrue/test/property/dunning_campaign_property_test.exs:23-25`

**Issue:** The implementation uses `>=` (`pending_step?/2` at `campaign.ex:102`:
`after_days * 86_400 >= elapsed`) — an at-boundary step stays pending. The resolver
moduledoc correctly describes `>=`, but the property test's moduledoc states the opposite:
"the FIRST step whose absolute `after_days * 86_400` is **strictly greater than** `elapsed`"
(`property_test.exs:24`). The oracle in that same file (`expected_next/2`, line 102) uses
`>=`, matching the implementation, so the test still passes — but the documentation is
internally contradictory and will mislead the next reader about the day-0 / at-boundary
contract.

**Fix:** Correct the property-test moduledoc to say "greater than or equal to" to match
both the implementation and its own oracle.

## Info

### IN-01: Duplicated email-template module (~135 lines) between the two dunning emails

**File:** `accrue/lib/accrue/emails/dunning_action_required.ex`, `accrue/lib/accrue/emails/dunning_final_notice.ex`

**Issue:** `DunningActionRequired` and `DunningFinalNotice` are near-identical: the
`message/1`, `render/1`, `render_text/1`, `template_assigns/1`, `context/1`, `branding/1`,
`map_get/2`, and `normalize_map/1` helpers are byte-for-byte the same; only `subject/1` and
the `~H` body differ. This is copy-paste duplication that will drift (a bug fix in one
helper must be applied twice).

**Fix:** Extract the shared scaffolding into a `use Accrue.Emails.DunningStep` macro or a
shared helper module, leaving each template to define only `subject/1` and the `~H` body.

### IN-02: Hardcoded brand fallbacks `"Acme Billing"` / `"billing@example.test"` in production email modules

**File:** `accrue/lib/accrue/emails/dunning_action_required.ex:37-38`, `accrue/lib/accrue/emails/dunning_final_notice.ex:37-38`

**Issue:** Both `message/1` fall back to `"Acme Billing"` and `"billing@example.test"` when
branding is absent. These placeholder values would ship as the visible From: identity if a
host's branding resolution returns nil at delivery time. For a billing library these are
surprising defaults to leak into a real customer's inbox.

**Fix:** Fall back to `Accrue.Config.branding(:from_name)` / `Accrue.Config.branding(:from_email)`
(which themselves carry the documented schema defaults) rather than literal "Acme"/example
strings.

### IN-03: `email_type/1` is non-total — an unmapped step key crashes the worker

**File:** `accrue/lib/accrue/workers/dunning_step.ex:229-231`

**Issue:** `email_type/1` has clauses only for `"reminder"`, `"action_required"`, and
`"final_notice"`. A campaign whose host config uses a custom step `key` (the validator
permits ANY atom key, `config.ex:9`) reaches `deliver_step/4 -> email_type(step_key_str)`
with no matching clause and raises `FunctionClauseError`, failing the job. The cadence
validator does not constrain `key` to the three built-ins, so this is reachable with a
valid config.

**Fix:** Either add a catch-all `defp email_type(_), do: :invoice_payment_failed` (or derive
the type from the step's `:template`), or document/validate that custom step keys require a
matching email-type mapping.

### IN-04: Migration has no down/rollback story and no index, by explicit deferral

**File:** `accrue/priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs:22-26`

**Issue:** Uses `change/0` (auto-reversible add column — fine) but the moduledoc defers the
optional partial index to Phase 129. The cancel-on-recovery bulk cancel
(`default_handler.ex:854-862`) and the elector both filter on
`dunning_campaign_started_at`; on large `accrue_subscriptions` tables the
`WHERE is_nil(dunning_campaign_started_at)` elector update is a full-row predicate (acceptable
since it is also keyed by `s.id`, the PK). No correctness issue — noting the deferral so the
Phase 129 index is not forgotten. (Performance out of v1 scope; flagged as Info only.)

**Fix:** None required this phase; ensure the deferred partial index lands in Phase 129 as
documented.

---

_Reviewed: 2026-05-24T18:17:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
