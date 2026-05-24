---
phase: 128-campaign-engine-foundation-idempotency-must-fix
verified: 2026-05-24T18:47:32Z
status: passed
score: 4/4 ROADMAP success criteria verified (21/21 plan must-have truths)
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
gaps: []
deferred: []
---

# Phase 128: Campaign Engine Foundation + Idempotency Must-Fix — Verification Report

**Phase Goal:** Failed-payment recovery runs as a first-party, durable, config-driven multi-step Oban campaign that emails on a host-defined cadence from local `past_due_since` state, never double-sends, and stops the instant payment recovers — replacing today's single un-deduped email.

**Verified:** 2026-05-24T18:47:32Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria — the contract)

| #   | Truth (ROADMAP SC) | Status | Evidence |
| --- | ------------------ | ------ | -------- |
| SC1 | Host can declare a multi-step `NimbleOptions`-validated dunning cadence under `:dunning`, default journey ON by default; invalid cadence (incl. `last_step.after_days > grace_days`) fails loudly at boot | ✓ VERIFIED | `config.ex`: `@step_schema` (:7), `@default_dunning_steps` `[0,5,12]` with correct keys/templates (:18-22), `{:custom, __MODULE__, :validate_dunning_campaign, []}` schema entry (:274), default `[enabled: true, steps: ...]` (:266), `validate_dunning_campaign_grace!/1` cross-field boot raise (:1110-1137) wired into `maybe_validate_boot_setup!/1` (:1058). `config_dunning_campaign_test.exs` green. |
| SC2 | On `past_due`, a durable `Accrue.Dunning.Campaign` schedules each step via `Accrue.Workers.DunningStep` from local state, emailing through Mailglass — independent of processor webhook re-fires | ✓ VERIFIED | Pure `Accrue.Dunning.Campaign.next_step/3` (`campaign.ex`, no side effects); `Accrue.Workers.DunningStep` durable Oban worker (`queue: :accrue_dunning, max_attempts: 3`, :57) calls resolver (:201) + `Mailer.deliver` (:169) + chains next; day-0 enqueued on the REAL webhook path via the atomic elector (`default_handler.ex` :1138-1155). `dunning_step_test.exs` + `dunning_campaign_start_test.exs` green. |
| SC3 | Duplicate processor retries never produce duplicate emails: `:invoice_payment_failed` now idempotent (closing the un-deduped gap) + each campaign step uniquely keyed | ✓ VERIFIED | `mailer/default.ex` Oban `unique` at enqueue keyed `[:type, :invoice_id]` with `invoice_id` promoted top-level + `period: :infinity` + `:completed` state (:53-88); backstop `idempotency_key(:invoice_payment_failed,...)` (`mailer.ex` :352-358). Steps 2/3 deduped via campaign-identity `idempotency_key` (`mailer.ex` :369-379, CR-01 fix). DunningStep D-16 `unique` keys `[:subscription_id, :step_key, :campaign_started_at]` (:138-139). `mailer_idempotency_test.exs` proves same-invoice dedup + per-invoice granularity + completed-state survival. |
| SC4 | The moment a sub leaves `past_due`, the in-flight campaign cancels (no further steps); keyed to the FIRST nil→past_due transition so later failures can't restart/orphan/duplicate | ✓ VERIFIED | D-09 atomic `update_all WHERE is_nil(dunning_campaign_started_at)` elector (count==1 wins / count==0 no-op) (`default_handler.ex` :1144-1151); cancel-on-recovery `maybe_finalize_dunning_campaign/2` clears anchor in-transaction + post-commit `Oban.cancel_all_jobs` keyed on `campaign_started_at` (:806-891); per-step cancel-guard `campaign_active?/1` uses `dunning_sweepable?/1` (`:past_due` only, CR-02 fix, dunning_step.ex :152-153). `dunning_campaign_keying_test.exs` proves race-elector, already-running no-op, cancel-on-recovery, stale-recovery isolation, anchor-clear durability. |

**Score:** 4/4 ROADMAP success criteria verified.

### Plan Must-Have Truths (detail, all VERIFIED)

| Plan | Must-Have Truth | Status | Evidence |
| ---- | --------------- | ------ | -------- |
| 01 | Multi-step cadence declarable under `:dunning` | ✓ | schema entry + `@step_schema` |
| 01 | Default journey `[0,5,12]` ships ON (opt-out) | ✓ | `@default_dunning_steps`, default in schema |
| 01 | Invalid cadence fails loudly at boot (intra-list + cross-field grace) | ✓ | `validate_dunning_campaign/1` + `validate_dunning_campaign_grace!/1` |
| 01 | `campaign: false` → `[enabled: false, steps: []]`; enabled+empty = loud error | ✓ | `validate_dunning_campaign(false)` (:1229) + empty-when-enabled error (:1242) |
| 02 | Nullable `dunning_campaign_started_at` column (add, not new table) | ✓ | migration `add ..., :utc_datetime_usec, null: true` |
| 02 | Anchor castable via `force_status_changeset/2` (`@cast_fields`) | ✓ | field :66, `@cast_fields` :93 |
| 02 | `dunning_campaign_active?/1` true iff non-nil DateTime | ✓ | dual-clause + catch-all :270-272 |
| 02 | Migration forward-only, nullable, no backfill | ✓ | `change/0`, applies cleanly |
| 03 | Pure resolver `(steps, started_at, now) → next step + delay`, no DB/Oban/clock | ✓ | `campaign.ex`; grep: 0 Repo/Oban/Clock |
| 03 | Day-0 returns step-1 immediately; past-last returns terminal | ✓ | `>=` boundary semantics + `:done` |
| 03 | `schedule_in = max(0, after_days_sec − elapsed)`, never negative | ✓ | `max(0, ...)` clamp :92 |
| 03 | Property-tested (zero/boundary/single/past-last/empty) | ✓ | property test green |
| 04 | Duplicate same-invoice `:invoice_payment_failed` never double-sends (week-2 redelivery) | ✓ | `unique` period :infinity + :completed |
| 04 | Per-invoice granularity REAL (top-level `invoice_id`, not global suppression) | ✓ | `dedup_args` promotes `invoice_id`; test asserts in_A/in_B distinct jobs |
| 04 | Dedup is PRIMARY via Oban `unique` at enqueue, only `:invoice_payment_failed` | ✓ | `dedup_unique` :78-88, others `false` |
| 04 | Backstop `idempotency_key` keyed on `invoice_id`, routed to Mailglass lane | ✓ | mailer.ex :352, routing :82 |
| 04 | Two new step email modules with portal CTA, registered in `default_template/1` | ✓ | `DunningActionRequired`/`DunningFinalNotice`, `default_template` :399-400 |
| 05 | Durable Oban worker delivers a step + chains next, shared `campaign_started_at` | ✓ | `dunning_step.ex` :87-89, :201 |
| 05 | Each step uniquely keyed, can never send twice | ✓ | D-16 unique :138-139 |
| 05 | Cancel-guard FIRST: not-past_due OR nil anchor → `{:cancel, :recovered}` | ✓ | :87-99, `campaign_active?/1` |
| 05 | ISO8601 string anchor, parsed via `DateTime.from_iso8601`, clock via `Accrue.Clock` | ✓ | grep: 0 String.to_atom, 0 DateTime.utc_now, 1 Accrue.Clock.utc_now |
| 06 | First nil→past_due transition: atomic `update_all WHERE is_nil` exactly-one-winner | ✓ | :1144-1151 |
| 06 | Later in-window failure does not restart/orphan (count==0 no-op) | ✓ | `case count` :1148-1151 |
| 06 | Cancel-on-recovery: anchor nilled in-transaction + post-commit cancel keyed on anchor | ✓ | :806-891, post-commit run :237 |
| 06 | Anchor-clear durable independent of bulk-cancel (cancel error doesn't undo) | ✓ | rescue in `cancel_dunning_steps` :883-891 |
| 06 | D-15 REPLACE: campaign enabled → standalone email skipped; disabled → fires (deduped) | ✓ | :1657-1666 |
| 06 | Campaign fires on REAL webhook entry (DefaultHandler), not just a unit helper | ✓ | `dunning_campaign_start_test.exs` drives DefaultHandler |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/lib/accrue/config.ex` | Campaign schema + validators + accessors (DUN-01) | ✓ VERIFIED | All grep gates met; boot wiring present |
| `accrue/lib/accrue/billing/subscription.ex` | Anchor field + cast + predicate (DUN-05 foundation) | ✓ VERIFIED | field, @cast_fields, `dunning_campaign_active?/1`, `dunning_sweepable?/1` |
| `accrue/priv/repo/migrations/20260525120000_*.exs` | Nullable forward-only anchor column | ✓ VERIFIED | `add ..., null: true`, no index; migrates clean |
| `accrue/lib/accrue/dunning/campaign.ex` | Pure step resolver (DUN-02) | ✓ VERIFIED | Substantive; 0 side-effecting calls. (gsd "Missing pattern" is a false positive — moduledoc says "No side effects, no DB" capital N; verified by Read.) |
| `accrue/lib/accrue/mailer/default.ex` | dedup_unique + per-type args (DUN-04) | ✓ VERIFIED | top-level invoice_id, period :infinity |
| `accrue/lib/accrue/workers/mailer.ex` | idempotency_key clauses + routing + template reg | ✓ VERIFIED | invoice_payment_failed + campaign-identity keys; Mailglass routing; default_template |
| `accrue/lib/accrue/emails/dunning_action_required.ex` | Step-2 email w/ portal CTA | ✓ VERIFIED | put_function + update_pm_url + quartet |
| `accrue/lib/accrue/emails/dunning_final_notice.ex` | Step-3 email w/ portal CTA | ✓ VERIFIED | put_function + update_pm_url + quartet |
| `accrue/lib/accrue/workers/dunning_step.ex` | Cancel-guarded, Oban-unique chained worker (DUN-02/05) | ✓ VERIFIED | All grep gates met; CR-02 fix present |
| `accrue/lib/accrue/webhook/default_handler.ex` | Elector + finalize + D-15 gate (DUN-02/05) | ✓ VERIFIED | All grep gates met; CR-02 terminal extension present |
| Test files (8) | DUN-01/02/04/05 proofs | ✓ VERIFIED | All exist; 6 properties + 75 tests green |

### Key Link Verification

(gsd-sdk `verify.key-links` reported "Source file not found" for all links — a tooling path-resolution artifact from the `accrue/`-prefixed `from:` paths in frontmatter resolving against the wrong CWD. Every link was verified manually by grep/Read.)

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `maybe_validate_boot_setup!/1` | `validate_dunning_campaign_grace!/1` | boot validator call | ✓ WIRED | config.ex:1058 |
| `campaign:` schema | `validate_dunning_campaign/1` | `{:custom, __MODULE__, ...}` | ✓ WIRED | config.ex:274 |
| Subscription schema | `dunning_campaign_started_at` column | `field(...)` | ✓ WIRED | subscription.ex:66 |
| `force_status_changeset/2` | anchor | `@cast_fields` entry | ✓ WIRED | subscription.ex:93 |
| resolver | step keyword shape | consumes Plan-01 contract, `now` arg | ✓ WIRED | campaign.ex:84,91 |
| `deliver/2` | `Mailer.new(unique: dedup_unique(...))` | derived unique | ✓ WIRED | default.ex:37 |
| `deliver/2` args | top-level `invoice_id` | per-type arg builder | ✓ WIRED | default.ex:56 |
| `default_template/1` | DunningActionRequired/FinalNotice | new clauses | ✓ WIRED | mailer.ex:399-400 |
| DunningStep `perform/1` | `Campaign.next_step/3` | resolver call | ✓ WIRED | dunning_step.ex:201 |
| DunningStep `perform/1` | `Mailer.deliver/2` | step delivery | ✓ WIRED | dunning_step.ex:169 |
| DunningStep | `dunning_campaign_active?/1` | cancel-guard reload | ✓ WIRED | dunning_step.ex:153 (gsd confirmed this one) |
| `maybe_bump_past_due_since/2` | DunningStep enqueue | count==1 day-0 enqueue | ✓ WIRED | default_handler.ex:1093,1168 |
| `maybe_finalize_dunning_campaign/2` | `Oban.cancel_all_jobs` | post-commit cancel keyed on anchor | ✓ WIRED | default_handler.ex:237,880 |
| `maybe_dispatch_invoice_email("payment_failed")` | `dunning_campaign_enabled?/0` | D-15 gate | ✓ WIRED | default_handler.ex:1661 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Day-0 enqueue | `dunning_campaign_started_at` anchor | `update_all set: [...now_usec]` after `is_nil` win | Real DB write (count-checked) | ✓ FLOWING |
| DunningStep chain | next step + delay | `Campaign.next_step(Config.dunning_campaign_steps(), anchor, now)` | Real config + clock-injected now | ✓ FLOWING |
| Cancel-on-recovery | `iso_anchor` | `row.dunning_campaign_started_at` captured before clear | Real row value | ✓ FLOWING |
| Step email | assigns (sub_id, anchor, invoice_id) | threaded from worker args → Mailer.deliver | Real scalar refs | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Library compiles clean | `mix compile --warnings-as-errors` | exit 0, no output | ✓ PASS |
| Phase test files green | `mix test <8 phase files> --seed 0` | 6 properties, 75 tests, 0 failures | ✓ PASS |
| Full suite (phase gate, no regression) | `mix test --seed 0` | 56 properties, 1555 tests, 0 failures (11 excluded) | ✓ PASS |
| CR-01/CR-02 fix commits exist | `git cat-file -t e3407184 67652386 ...` | all 8 fix commits exist | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| ----------- | -------------- | ----------- | ------ | -------- |
| DUN-01 | 01, 04 | Multi-step `NimbleOptions` cadence under `:dunning`, default ON | ✓ SATISFIED | config schema/validators/accessors + 2 step templates |
| DUN-02 | 03, 05, 06 | First-party durable Oban campaign scheduling from local state | ✓ SATISFIED | pure resolver + DunningStep worker + real-webhook elector |
| DUN-04 | 04 | Failed-payment/dunning-step emails idempotent (closes mailer.ex:292,314 gap) | ✓ SATISFIED | enqueue-unique + delivery idempotency_key for invoice + steps 2/3 (CR-01) |
| DUN-05 | 02, 05, 06 | Cancel-on-recovery + first-transition keying; no restart/duplicate | ✓ SATISFIED | atomic elector + finalize hook + cancel-guard (CR-02 terminal-state) |

All 4 declared requirement IDs cross-referenced against REQUIREMENTS.md — each maps to Phase 128 and is marked Complete (REQUIREMENTS.md :74-77). No orphaned requirements: REQUIREMENTS.md maps exactly DUN-01/02/04/05 to Phase 128, all claimed by plans. (DUN-03 and DUN-06..10 are mapped to later phases 129-132, not this phase — correctly out of scope.)

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER in any phase-modified source file | — | Completion is auditable |
| (none) | — | No stub phrases (coming soon / not implemented / placeholder) | — | No hollow implementations |

The 4 REVIEW Info findings (IN-01 duplicated email scaffolding, IN-02 hardcoded `"Acme Billing"` brand fallback, IN-03 non-total `email_type/1`, IN-04 deferred migration index) were intentionally left open as out-of-scope for the critical_warning fix pass. Per phase guidance these are acceptable and do not fail verification. IN-02 (hardcoded brand fallbacks in production email modules) and IN-03 (non-total `email_type/1` crashes worker on a custom step key) are the most consequential and are recommended for a follow-up phase, but neither blocks this phase's goal: IN-03 is unreachable on the shipped default journey (which uses only `:reminder`/`:action_required`/`:final_notice`), and IN-02 only surfaces if a host's branding resolution returns nil at delivery.

### Human Verification Required

None. All observable truths are provable programmatically (config validation, Oban dedup/unique semantics, atomic elector race, cancel-on-recovery, anchor-clear durability) and are covered by passing automated tests. No visual/UX/real-time/external-service surface in this phase. (The two REVIEW-FIX items flagged "requires human verification" — CR-02 guard logic change and WR-05 exit-reraise control flow — are both now covered by passing automated tests: CR-02 by the terminal-`:unpaid` cancel-guard + parameterized terminal-exhaustion tests; WR-05's narrowed catch is exercised by the full webhook suite with no regression.)

### Gaps Summary

No gaps. The phase goal is achieved and observably true in the codebase:

1. **Config-driven cadence (DUN-01):** the `:dunning.campaign` schema, default `[0,5,12]` journey shipped ON, two-layer validation (intra-list `{:custom}` + cross-field boot raise) all present and tested.
2. **Durable Oban campaign (DUN-02):** pure resolver + cancel-guarded chained `DunningStep` worker, started from the REAL webhook path via the atomic elector, independent of webhook re-fires.
3. **Idempotency must-fix (DUN-04):** the un-deduped `:invoice_payment_failed` gap is closed (per-invoice top-level dedup, not global suppression), AND the CR-01 follow-up gave steps 2/3 delivery-level idempotency keyed on campaign identity — closing the no-double-sends gap for the full journey, not just step 1.
4. **Cancel-on-recovery + keying (DUN-05):** atomic first-transition election (exactly-one-winner), durable in-transaction anchor-clear, post-commit anchor-keyed bulk cancel, stale-recovery isolation, and the CR-02 fix that stops dunning a terminated (`:unpaid`/`:canceled`) subscription.

Both REVIEW BLOCKERs (CR-01, CR-02) and all 6 Warnings were confirmed fixed in the codebase (not just claimed): the `dunning_sweepable?/1` cancel-guard, the campaign-identity `idempotency_key`, the `finalizing_transition?/1` terminal extension, the single-source `@default_grace_days`/`@default_dunning_campaign`, the `:unknown_step` cadence-drift guard, the `Accrue.Clock` determinism fix, schema-valid test fixtures, the narrowed `safe_deliver/2` catch, and the corrected resolver boundary doc. Full suite at the expected baseline (56 properties, 1555 tests, 0 failures).

---

_Verified: 2026-05-24T18:47:32Z_
_Verifier: Claude (gsd-verifier)_
