---
phase: 129-customer-operator-surfaces-observability
verified: 2026-05-25T09:13:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 129: Customer + Operator Surfaces + Observability Verification Report

**Phase Goal:** A customer with a failed payment is prompted to fix it, an operator can see exactly where a customer is in their dunning journey, and the whole campaign lifecycle is observable through the ledger and telemetry — including the recovered-vs-lost signal merchants care about.
**Verified:** 2026-05-25T09:13:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|-----------------------------------|--------|----------|
| 1 | A past-due customer sees a recovery prompt in `accrue_portal` deep-linking into the add/update-payment-method flow | ✓ VERIFIED | `accrue_portal/.../live/subscription_live.ex:154-167` conditional `<section data-role="subscription-recovery-banner">` gated on `recovery_prompt?/1` (:283-285, calls `Subscription.past_due?/1 or dunning_campaign_active?/1`); CTA href via provider-aware `update_pm_path/2` (:287-290): Braintree → `/payment-methods/new`, others → `/payment-methods`. 8 portal LiveView tests pass. |
| 2 | An operator sees a subscription's active dunning state (current step, started-at, next scheduled action) in `accrue_admin`, read-only, every string via `AccrueAdmin.Copy` SSOT | ✓ VERIFIED | `accrue_admin/.../live/subscription_live.ex:220-254` read-only `<article data-role="subscription-dunning-state">` — no phx-click/phx-submit/button/form inside the panel (confirmed by line-range inspection; the form/button matches at :283+ are a separate action card). Shows badge state, started-at, next action. All 11 visible strings route through `Copy.dunning_*` (:222-251); next action derived from pure `Campaign.next_step/3` (:1039). 13 admin LiveView tests pass. |
| 3 | Dunning lifecycle is observable: `accrue_events` ledger entries (campaign_started/step_sent/recovered/exhausted) + telemetry family aligned with `guides/telemetry.md` | ✓ VERIFIED | All four ledger writes + `[:accrue, :ops, :dunning_*]` telemetry present in lib/: campaign_started (`default_handler.ex:1245-1255`, wired at :1225), step_sent (`dunning_step.ex:195-206`, wired at :179), recovered (`default_handler.ex:862-883`), exhausted (`default_handler.ex:789-800`). Drift-gate triad lockstep: inventory (`telemetry_ops_inventory.ex:27-30`), metrics counters (`metrics.ex:94-97`), guide catalog (:90-93) + runbook (:451-454). 53 dunning+contract tests pass. **D-01 deviation** (`[:accrue, :ops, :dunning_*]` not literal `[:accrue, :dunning, *]`) is intentional+documented to keep events inside the enforced drift gate — accepted per phase notes. |
| 4 | A recovered-vs-lost signal is derivable as a ledger-query counter (no new table) | ✓ VERIFIED | `Accrue.Billing.Dunning.recovered_vs_lost/1` (`dunning.ex:133-139`) folds `accrue_events`: recovered = count `dunning.recovered`, lost = count `dunning.exhausted` via parameterized `count_events/2` (:146-150). Excludes request-time `terminal_action_requested` (allowlist :48-49, grep-confirmed absent). No `create table` in file. Honors `since:`/`until:` `%DateTime{}` windows. Unit + property tests pass. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/webhook/default_handler.ex` | 3 lifecycle emit sites (campaign_started, recovered, exhausted) ledger+telemetry | ✓ VERIFIED | All present, substantive, wired into real reducer/elector paths |
| `accrue/lib/accrue/workers/dunning_step.ex` | step_sent emit after delivery | ✓ VERIFIED | `emit_step_sent/2` (:189-209) called after `Mailer.deliver` (:179) |
| `accrue/lib/accrue/billing/dunning.ex` | `recovered_vs_lost/1` ledger fold | ✓ VERIFIED | Full implementation, no new table, parameterized window |
| `accrue/lib/accrue/telemetry/metrics.ex` | 4 counters | ✓ VERIFIED | recovered/exhausted source-tagged; started/step_sent untagged (cardinality guard) |
| `accrue/test/support/telemetry_ops_inventory.ex` | 4 events registered | ✓ VERIFIED | Lines 27-30 |
| `accrue/guides/telemetry.md` | catalog + runbook rows | ✓ VERIFIED | Catalog :90-93, runbook :451-454 |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | recovery banner + helpers | ✓ VERIFIED | Banner :154-167, `recovery_prompt?/1`, `update_pm_path/2` |
| `accrue_portal/lib/accrue_portal/copy.ex` | 3 recovery strings | ✓ VERIFIED | `subscription_recovery_heading/body/cta` :177-184 |
| `accrue_portal/lib/accrue_portal/path.ex` | `payment_methods_new/1` | ✓ VERIFIED | Line 7 |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | read-only panel + helpers | ✓ VERIFIED | Panel :220-254, `next_action_summary/1`, `dunning_badge_tone/1` |
| `accrue_admin/lib/accrue_admin/copy/dunning.ex` | Copy.Dunning submodule | ✓ VERIFIED | Full string set, state-aware label |
| `accrue_admin/lib/accrue_admin/copy.ex` | defdelegates | ✓ VERIFIED | 13 dunning delegates |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `default_handler.ex` | Events / Telemetry.Ops | campaign_started/recovered/exhausted emit | ✓ WIRED | All three sites emit both ledger + `[:accrue, :ops, :dunning_*]` from real code paths |
| `dunning_step.ex` | Events / Telemetry.Ops | step_sent after delivery | ✓ WIRED | `emit_step_sent/2` invoked post-`Mailer.deliver` |
| `dunning.ex` | accrue_events ledger | `Repo.aggregate` over recovered/exhausted | ✓ WIRED | Counts the two confirmed-transition types only |
| portal `subscription_live.ex` | `past_due?/1` + `dunning_campaign_active?/1` | `recovery_prompt?/1` gate | ✓ WIRED | Calls canonical predicates, not status atoms |
| portal `subscription_live.ex` | add/update-PM route | `update_pm_path/2` processor dispatch | ✓ WIRED | Braintree→/new, others→list; always a real path |
| admin `subscription_live.ex` | `Campaign.next_step/3` | `next_action_summary/1` over anchor | ✓ WIRED | Pure resolver + `Clock.utc_now/0`, decoupled from Oban |
| admin template | `AccrueAdmin.Copy` | `Copy.dunning_*` calls | ✓ WIRED | 11 calls; no hardcoded operator strings in panel |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| admin dunning panel | `@subscription.dunning_campaign_started_at` | `Subscriptions.detail/2` under `current_owner_scope`; real schema field `subscription.ex:66` | Yes | ✓ FLOWING |
| admin next action | `Campaign.next_step/3` over real anchor + `Clock.utc_now/0` | pure resolver + Config steps | Yes | ✓ FLOWING |
| portal banner | `@subscription` (predicates) | `Authorize.subscription/2` in mount | Yes | ✓ FLOWING |
| recovered_vs_lost | `count_events/2` aggregate | `accrue_events` ledger via Repo.aggregate | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Dunning lifecycle + drift-gate contract | `mix test` (5 dunning files + ops_event_contract + metrics_ops_parity) | 3 properties, 53 tests, 0 failures | ✓ PASS |
| Portal recovery banner show/hide + CTA | `mix test subscription_live_test.exs` (portal) | 8 tests, 0 failures | ✓ PASS |
| Admin read-only dunning panel | `mix test subscription_live_test.exs` (admin) | 13 tests, 0 failures | ✓ PASS |
| Full accrue suite (no regressions) | `mix test --seed 0` | 57 properties, 1569 tests, 0 failures (11 excluded) | ✓ PASS |
| Full admin suite | `mix test` | 137 tests, 0 failures | ✓ PASS |
| Full portal suite | `mix test` | 34 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DUN-06 | 129-03 | Customer recovery prompt in portal deep-linking to add/update-PM flow | ✓ SATISFIED | Truth 1 — banner + provider-aware CTA, 8 tests |
| DUN-07 | 129-04 | Operator read-only dunning state in admin, all copy via Copy SSOT | ✓ SATISFIED | Truth 2 — read-only panel, Copy.Dunning, 13 tests |
| DUN-08 | 129-01, 129-02 | Lifecycle ledger + telemetry + recovered-vs-lost counter, no new table | ✓ SATISFIED | Truths 3+4 — 4 events drift-gate triad + `recovered_vs_lost/1` |

All three Phase-129 requirement IDs (DUN-06, DUN-07, DUN-08) are declared in plan frontmatter and verified satisfied. No orphaned requirements: REQUIREMENTS.md maps exactly DUN-06/07/08 to Phase 129, all claimed by plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER in any of the 11 modified lib files | — | Clean |
| `accrue_admin/.../subscription_live.ex` | 242-251 | Empty-state branch renders `Started: Unknown` (format_datetime of nil) and duplicates the empty-state body via `next_action_summary/1` catch-all | ⚠️ Warning (WR-03, from code review) | Cosmetic operator-copy quality; panel still renders and conveys state. Does NOT block goal achievement (operator can still see "no active campaign"). |
| `accrue/.../default_handler.ex` | 851-890 | Nested `Repo.transaction(multi)` inside the reducer's outer `Repo.transact` (no savepoint, untested error path) | ⚠️ Warning (WR-01, from code review) | Happy path works (verified by passing keying tests); failure path untested. Robustness concern, not a goal blocker. |

### Human Verification Required

None. All four success criteria are programmatically verifiable through code inspection, data-flow tracing, and the comprehensive passing test suites (LiveView render tests cover show/hide, read-only contract, provider-correct CTA hrefs, and copy routing via `has_element?/2,3` without Chrome). No visual-only, real-time, or external-service behavior remains unverified.

### Gaps Summary

No goal-blocking gaps. All 4 ROADMAP success criteria are observably true in the codebase:

1. The portal recovery banner renders for past-due/active-campaign customers with a provider-aware "Update payment method" CTA into the existing PM flow.
2. The admin read-only dunning-state panel shows badge state, started-at, and resolver-derived next action with every string via the `AccrueAdmin.Copy` SSOT and zero mutating controls.
3. All four lifecycle events (campaign_started/step_sent/recovered/exhausted) emit paired ledger + `[:accrue, :ops, :dunning_*]` telemetry, registered in lockstep across the enforced drift-gate triad. The `[:accrue, :ops, :dunning_*]` namespace (vs ROADMAP SC#3's literal `[:accrue, :dunning, *]`) is the documented intentional D-01 deviation so events pass the enforced drift gate — accepted per the phase brief.
4. `recovered_vs_lost/1` answers the recovered-vs-lost question as a flat `%{recovered:, lost:}` ledger fold with no new table, structurally excluding the request-time terminal-action signal.

Two non-blocking robustness/quality warnings carry over from the code review (WR-01 nested transaction error path; WR-03 empty-state "Started: Unknown" cosmetic copy). Both are documented in 129-REVIEW.md and neither prevents the phase goal from being achieved. They are recommended for follow-up before v1.0 but do not warrant blocking phase progression.

---

_Verified: 2026-05-25T09:13:00Z_
_Verifier: Claude (gsd-verifier)_
