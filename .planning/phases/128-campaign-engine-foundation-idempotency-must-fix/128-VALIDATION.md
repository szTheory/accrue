---
phase: 128
slug: campaign-engine-foundation-idempotency-must-fix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
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

> Planner populates Task IDs + Plan + Wave during planning. Requirement→behavior→command mapping below is locked from RESEARCH.md and MUST be preserved.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DUN-01 | — | Config validator: strictly-increasing + unique `after_days`; unique `key`; `campaign: false` → `[enabled: false, steps: []]`; empty-steps-while-enabled = loud error; `last_step.after_days <= grace_days` raises at boot | property + unit | `mix test test/accrue/config_dunning_campaign_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-01 | — | Default journey shipped on by default (`[0,5,12]`, correct templates/keys) | unit | `mix test test/accrue/config_dunning_campaign_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-02 | — | Pure `Accrue.Dunning.Campaign` resolver `(steps, started_at, now) → next step + delay`; ordering/zero-elapsed/boundary edge cases; deterministic | property (stream_data) | `mix test test/property/dunning_campaign_property_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-02 | — | Real webhook path: `invoice.payment_failed` fixture through `DefaultHandler` enqueues day-0 `DunningStep` (real entry point, not unit helper) | integration (Oban.Testing) | `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-02 | — | Step chain: `perform/1` delivers + enqueues next step with SAME `campaign_started_at`; final step enqueues nothing | integration (`perform_job`) | `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-04 | — | `:invoice_payment_failed` once-per-invoice: duplicate enqueue → `{:ok, %Job{conflict?: true}}`, no second job; survives simulated week-2 redelivery (`period: :infinity` + `:completed`) | integration (Oban unique) | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-04 | — | `idempotency_key/2` clause keys on `invoice_id`; `{:error, :missing_invoice_id}` on nil/empty | unit | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-04 | — | `dedup_unique/2` returns `false` for every non-`:invoice_payment_failed` type (no regression) | unit | `mix test test/accrue/workers/mailer_idempotency_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-05 | — | Race-safe first-transition guard: under N concurrent `update_all where is_nil(anchor)`, exactly ONE count==1 (winner), rest count==0 (no-op) | integration (concurrent Ecto + Sandbox) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-05 | — | Later failure webhook in same window does NOT restart/duplicate (anchor already set → count==0) | integration | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-05 | — | Cancel-on-recovery: leaving `past_due` → anchor nilled + `cancel_all_jobs` removes scheduled steps; keyed on `campaign_started_at` so a fresh re-lapse campaign survives a stale recovery | integration (Oban + webhook) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-05 | — | Step cancel-guard: `perform/1` on recovered sub (not past_due OR nil anchor) → `{:cancel, :recovered}`, sends nothing | integration (`perform_job`) | `mix test test/accrue/webhook/dunning_campaign_keying_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DUN-05 | — | D-15 REPLACE: campaign enabled ⇒ standalone `:invoice_payment_failed` NOT dispatched (one day-0 email); disabled ⇒ standalone fires (deduped) | integration | `mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/accrue/config_dunning_campaign_test.exs` — DUN-01 validation (intra-list + boot grace cross-field)
- [ ] `test/property/dunning_campaign_property_test.exs` — DUN-02 pure resolver properties (clone `test/property/connect_platform_fee_property_test.exs` structure)
- [ ] `test/accrue/webhook/dunning_campaign_start_test.exs` — DUN-02 real webhook path + D-15 REPLACE gate
- [ ] `test/accrue/webhook/dunning_campaign_keying_test.exs` — DUN-05 race-safe keying + cancel-on-recovery + cancel-guard
- [ ] `test/accrue/workers/mailer_idempotency_test.exs` — DUN-04 immediate dedup (Oban unique + `idempotency_key/2` clause + no-regression)
- [ ] Migration present in `priv/repo/migrations/` before integration tests run (test_helper boots all migrations)
- [ ] Framework install: none — full infra already in `test_helper.exs`

> Concurrency note (DUN-05 race test): use multiple sandbox-checked-out connections OR `Ecto.Adapters.SQL.Sandbox` shared mode + `Task.async_stream` to simulate concurrent `update_all`.

---

## Manual-Only Verifications

All phase behaviors have automated verification. (Email visual rendering for the two new templates is covered by the existing mailer render conventions; no net-new manual gate for this backend phase.)

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (single-file seconds)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
