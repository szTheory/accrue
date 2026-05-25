---
phase: 129
slug: customer-operator-surfaces-observability
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 129 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `129-RESEARCH.md` → "Validation Architecture". Task IDs are
> requirement-level until the planner assigns plan/wave IDs — refine the
> Per-Task map after PLAN.md files exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) + `Phoenix.LiveViewTest` for the portal/admin surfaces |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `accrue_portal/test/test_helper.exs`; case templates under `accrue/test/support/` (e.g. `Accrue.BillingCase`) |
| **Quick run command** | `cd accrue && mix test <file>` (e.g. `mix test test/accrue/telemetry/ops_event_contract_test.exs`) |
| **Full suite command** | `cd accrue && mix test` · `cd accrue_admin && mix test` · `cd accrue_portal && mix test` (per package touched) |
| **Estimated runtime** | ~30–90s per package quick run; full `accrue` suite a few min |

> **Known-flaky dodge (from project memory):** the `accrue` full suite has a flaky `PdfTest` — run the full suite with `--seed 0`. The 6 PackageDocsVerifier failures are RESOLVED (Phase 126). Neither is touched by this phase.

---

## Sampling Rate

- **After every task commit:** Run the touched file's quick run (e.g. `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs`)
- **After every plan wave:** Run the full per-package suite for any package touched in the wave. **Because the drift gate is set-equality, run `ops_event_contract_test` + `metrics_ops_parity_test` whenever ANY of the four contract surfaces changed** (inventory + `metrics.ex` + `guides/telemetry.md` + a `lib/` emit site).
- **Before `/gsd:verify-work`:** All three packages' full suites green (dodge flaky `PdfTest` with `--seed 0`)
- **Max feedback latency:** ~90 seconds (single-file quick run)

---

## Per-Task Verification Map

> Requirement-level until plan/wave IDs are assigned. `✅ extend` = test file
> exists, add assertions; `❌ W0` = Wave 0 must create the file/attribute first.

| Req | Behavior | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-----------------|-----------|-------------------|-------------|--------|
| DUN-08 | `dunning.campaign_started` emits ledger + `[:accrue,:ops,:dunning_campaign_started]` on first nil→past_due edge (**no `:source` tag** — metadata has none) | — | N/A | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_start_test.exs` | ✅ extend | ⬜ pending |
| DUN-08 | `dunning.step_sent` emits once per delivered step (`step_key`, `step_index`) | — | N/A | unit (worker) | `cd accrue && mix test test/accrue/workers/dunning_step_test.exs` | ❌ W0 (verify/create) | ⬜ pending |
| DUN-08 | `dunning.recovered` emits on past_due→active/paid recovery (`source`) | — | N/A | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` | ✅ extend | ⬜ pending |
| DUN-08 | `dunning.exhausted` emits on confirmed terminal transition (ALL sources), NEVER from `terminal_action_requested` | — | N/A | unit (webhook) | `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` | ✅ extend | ⬜ pending |
| DUN-08 | Drift gate green: every new event present in inventory + `metrics.ex` + guide catalog+runbook + `lib/` emit (set-equality, `lib/`-only scan) | — | N/A | contract | `cd accrue && mix test test/accrue/telemetry/ops_event_contract_test.exs test/accrue/telemetry/metrics_ops_parity_test.exs` | ✅ exists | ⬜ pending |
| DUN-08 | recovered-vs-lost fold returns `%{recovered:, lost:}`; never counts `terminal_action_requested`; honors `since:`/`until:` window | — | N/A | unit + property | `cd accrue && mix test test/accrue/billing/dunning_test.exs` | ✅ extend | ⬜ pending |
| DUN-06 | Past-due / active-campaign subscription renders recovery banner with provider-correct CTA href (Braintree → `/payment-methods/new`; others → update-PM dest) | — | CTA href must not assume Braintree for non-Braintree processors | LiveView render | `cd accrue_portal && mix test test/accrue_portal/live/subscription_live_test.exs` | ✅ extend (`data-role` = W0) | ⬜ pending |
| DUN-06 | Non-past-due subscription renders NO banner | — | N/A | LiveView render | same file | ✅ extend | ⬜ pending |
| DUN-07 | Admin renders read-only dunning `ax-card` (active?/started-at/next-action); all strings via `AccrueAdmin.Copy`; NO action controls | — | Read-only: panel emits no mutating controls | LiveView render | `cd accrue_admin && mix test test/accrue_admin/live/subscription_live_test.exs` | ✅ extend (`data-role` = W0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Verify `accrue/test/accrue/workers/dunning_step_test.exs` exists; if not, create it for the `step_sent` emit assertion (the worker may currently be exercised only via webhook integration tests).
- [ ] Add a stable `data-role` attribute to the new portal banner `<section>` (`data-role="subscription-recovery-banner"`, matching the PLAN/UI-SPEC) and the admin dunning `<article>`/`ax-card` (e.g. `data-role="subscription-dunning-state"`) so render tests can `has_element?` them deterministically (mirrors the existing `data-role` convention in admin LiveView).
- [ ] Property test (extend `dunning_campaign_property_test.exs` or `billing/dunning_test.exs`): recovered-vs-lost fold never counts `terminal_action_requested`, and respects `since:`/`until:` windows (`stream_data` already a dev/test dep).
- [ ] Confirm `metrics_ops_parity_test` + `ops_event_contract_test` are in the default `mix test` run (they are — both under `test/accrue/telemetry/`).

*No framework install needed — ExUnit, `Phoenix.LiveViewTest`, `stream_data`, and the telemetry contract tests all already exist.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual placement / styling of the portal recovery banner | DUN-06 | Pixel/visual polish not asserted by render tests | Load a past-due subscription in `accrue_portal`, confirm banner sits before the main `portal-card` and the CTA navigates to the correct provider destination |
| Visual placement of the admin dunning `ax-card` | DUN-07 | Card ordering/visual polish not asserted by render tests | Open an admin subscription detail with an active campaign, confirm the read-only card shows step/started-at/next-action |

*Render tests cover presence, CTA href correctness, read-only-ness, and conditional show/hide; the above are visual-polish-only.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`dunning_step_test.exs`, `data-role` attributes, property test)
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
