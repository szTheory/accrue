---
phase: 128
slug: campaign-engine-foundation-idempotency-must-fix
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
validated: 2026-05-25
---

# Phase 128 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Sourced from `128-RESEARCH.md` § Validation Architecture (HIGH confidence — test infra verified present).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + ExUnitProperties (stream_data ~> 1.3) + Oban.Testing + Ecto.Adapters.SQL.Sandbox + Mox |
| **Config file** | `accrue/test/test_helper.exs` (boots TestRepo, runs migrations, starts Oban `testing: :manual`, defines Mox mocks) |
| **Quick run command** | `cd accrue && mix test <single new file> --seed 0` |
| **Full suite command** | `cd accrue && mix test --seed 0` |
| **Estimated runtime** | full suite ~minutes; single file ~seconds |

> `--seed 0` dodges the known-flaky PdfTest (per project memory). Migration must exist in `priv/repo/migrations/` before integration tests — `test_helper.exs` runs all migrations at boot.

---

## Sampling Rate

- **After every task commit:** Run the single new test file for that task — `cd accrue && mix test <file> --seed 0`
- **After every plan wave:** Run the full suite — `cd accrue && mix test --seed 0`
- **Before `/gsd:verify-work`:** Full suite green + `mix credo --strict` + dialyzer
- **Max feedback latency:** single-file seconds; full-suite minutes

---

## Per-Task Verification Map

> Task IDs + Plan + Wave reconciled from SUMMARY artifacts during the 2026-05-25 validation audit. Requirement→behavior→command mapping is preserved from RESEARCH.md; statuses/file-exists reflect the executed-and-verified codebase.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01.T1+T2 | 01 | 1 | DUN-01 | T-128-01 | Config validator: strictly-increasing + unique `after_days`; unique `key`; `campaign: false` → `[enabled: false, steps: []]`; empty-steps-while-enabled = loud error; `last_step.after_days <= grace_days` raises at boot | property + unit | `mix test test/accrue/config_dunning_campaign_test.exs --seed 0` | ✅ | ✅ green |
| 01.T1+T2 | 01 | 1 | DUN-01 | — | Default journey shipped on by default (`[0,5,12]`, correct templates/keys) | unit | `mix test test/accrue/config_dunning_campaign_test.exs --seed 0` | ✅ | ✅ green |
| 03.T1+T2 | 03 | 1 | DUN-02 | T-128-05/06 | Pure `Accrue.Dunning.Campaign` resolver `(steps, started_at, now) → next step + delay`; ordering/zero-elapsed/boundary edge cases; deterministic | property (stream_data) | `mix test test/property/dunning_campaign_property_test.exs --seed 0` | ✅ | ✅ green |
| 06.T1 | 06 | 2 | DUN-02 | — | Real webhook path: `invoice.payment_failed` fixture through `DefaultHandler` enqueues day-0 `DunningStep` (real entry point, not unit helper) | integration (Oban.Testing) | `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ✅ | ✅ green |
| 05.T1 | 05 | 2 | DUN-02 | — | Step chain: `perform/1` delivers + enqueues next step with SAME `campaign_started_at`; final step enqueues nothing | integration (`perform_job`) | `mix test test/accrue/workers/dunning_step_test.exs --seed 0` | ✅ | ✅ green |
| 04.T3 | 04 | 1 | DUN-04 | T-128-07/19 | `:invoice_payment_failed` once-per-invoice: duplicate enqueue → `{:ok, %Job{conflict?: true}}`, no second job; survives simulated week-2 redelivery (`period: :infinity` + `:completed`) | integration (Oban unique) | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ✅ | ✅ green |
| 04.T2+T3 | 04 | 1 | DUN-04 | T-128-09 | `idempotency_key/2` clause keys on `invoice_id`; `{:error, :missing_invoice_id}` on nil/empty | unit | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ✅ | ✅ green |
| 04.T3 | 04 | 1 | DUN-04 | — | `dedup_unique/2` returns `false` for every non-`:invoice_payment_failed` type (no regression) | unit | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ✅ | ✅ green |
| 06.T2 | 06 | 2 | DUN-05 | T-128-03 | Race-safe first-transition guard: under N concurrent `update_all where is_nil(anchor)`, exactly ONE count==1 (winner), rest count==0 (no-op) | integration (concurrent Ecto + Sandbox) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ✅ | ✅ green |
| 06.T2 | 06 | 2 | DUN-05 | — | Later failure webhook in same window does NOT restart/duplicate (anchor already set → count==0) | integration | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ✅ | ✅ green |
| 06.T2 | 06 | 2 | DUN-05 | — | Cancel-on-recovery: leaving `past_due` → anchor nilled + `cancel_all_jobs` removes scheduled steps; keyed on `campaign_started_at` so a fresh re-lapse campaign survives a stale recovery | integration (Oban + webhook) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ✅ | ✅ green |
| 05.T1 | 05 | 2 | DUN-05 | — | Step cancel-guard: `perform/1` on recovered sub (not past_due OR nil anchor) → `{:cancel, :recovered}`, sends nothing | integration (`perform_job`) | `mix test test/accrue/workers/dunning_step_test.exs --seed 0` | ✅ | ✅ green |
| 06.T1 | 06 | 2 | DUN-05 | — | D-15 REPLACE: campaign enabled ⇒ standalone `:invoice_payment_failed` NOT dispatched (one day-0 email); disabled ⇒ standalone fires (deduped) | integration | `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Audit note (2026-05-25):** Row "Step chain" and "Step cancel-guard" were planned against `dunning_campaign_start_test.exs`/`dunning_campaign_keying_test.exs` but their `perform_job`-driven coverage actually landed in `test/accrue/workers/dunning_step_test.exs` during execution (Plan 05) — command column updated to the real file. Plan 02's anchor column/predicate (DUN-05 foundation) gained bonus coverage in `test/accrue/billing/subscription_campaign_anchor_test.exs` (7 tests), and Plan 04's templates/wiring in `dunning_step_emails_test.exs` + `mailer_dunning_wiring_test.exs` — all green, not separately rowed since they back the requirement rows above.

---

## Wave 0 Requirements

- [x] `test/accrue/config_dunning_campaign_test.exs` — DUN-01 validation (intra-list + boot grace cross-field)
- [x] `test/property/dunning_campaign_property_test.exs` — DUN-02 pure resolver properties (cloned `test/property/connect_platform_fee_property_test.exs` structure)
- [x] `test/accrue/webhook/dunning_campaign_start_test.exs` — DUN-02 real webhook path + D-15 REPLACE gate
- [x] `test/accrue/webhook/dunning_campaign_keying_test.exs` — DUN-05 race-safe keying + cancel-on-recovery
- [x] `test/accrue/workers/dunning_step_test.exs` — DUN-02 step chain + DUN-05 step cancel-guard (`perform_job`)
- [x] `test/accrue/workers/mailer_idempotency_test.exs` — DUN-04 immediate dedup (Oban unique + `idempotency_key/2` clause + no-regression)
- [x] Migration present in `priv/repo/migrations/20260525120000_add_dunning_campaign_started_at_to_subscriptions.exs` (test_helper boots all migrations)
- [x] Framework install: none — full infra already in `test_helper.exs`

> Concurrency note (DUN-05 race test): use multiple sandbox-checked-out connections OR `Ecto.Adapters.SQL.Sandbox` shared mode + `Task.async_stream` to simulate concurrent `update_all`.

---

## Manual-Only Verifications

All phase behaviors have automated verification. (Email visual rendering for the two new templates is covered by the existing mailer render conventions; no net-new manual gate for this backend phase.)

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency acceptable (single-file seconds)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-25 — all 4 requirements (DUN-01/02/04/05) automated and green

---

## Validation Audit 2026-05-25

Retroactive audit of the planner-authored draft against the executed-and-verified codebase. All planned Wave-0 test files exist on disk; the 6 phase test files re-run green at `--seed 0` (6 properties, 54 tests, 0 failures). No gaps — every requirement has automated verification.

| Metric | Count |
|--------|-------|
| Requirements audited | 4 (DUN-01, DUN-02, DUN-04, DUN-05) |
| Per-task rows | 13 |
| Gaps found | 0 |
| Resolved (auto-generated tests) | 0 (all pre-existed from execution) |
| Escalated to manual-only | 0 |
| Status reclassifications | 13 (`⬜ pending` → `✅ green`) |

> Source-of-truth cross-check: `128-VERIFICATION.md` (status: passed, 4/4 ROADMAP SC, 21/21 must-haves) and the six 128-0N-SUMMARY artifacts. No `gsd-nyquist-auditor` spawn required — there were no MISSING/PARTIAL gaps to fill.
