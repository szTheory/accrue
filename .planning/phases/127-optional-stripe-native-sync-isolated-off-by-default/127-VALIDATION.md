---
phase: 127
slug: optional-stripe-native-sync-isolated-off-by-default
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 127 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `127-RESEARCH.md` § Validation Architecture. Task IDs are filled by the planner.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `stream_data` (property) + `Processor.Fake.synthesize_event` (in-process webhook synth) |
| **Config file** | `accrue/test/test_helper.exs` (`live_stripe` tag excluded by default) |
| **Quick run command** | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs -x` |
| **Full suite command** | `cd accrue && mix test.all` (format-check + credo --strict + warnings-as-errors + test) |
| **Estimated runtime** | quick ~seconds · full suite ~2–4 min |

---

## Sampling Rate

- **After every task commit:** Run the focused new test file(s) with `-x` (e.g. `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs -x`)
- **After every plan wave:** `cd accrue && mix test --seed 0` (dodge known-flaky `PdfTest`, per project memory) **plus** the new/extended CI scripts (`scripts/ci/verify_entitlement_sync_isolation.sh`, `scripts/ci/verify_processor_support_matrix.sh`, `scripts/ci/verify_package_docs.sh`)
- **Before `/gsd:verify-work`:** `cd accrue && mix test.all` green + `accrue_admin` suite green + all new/extended CI scripts exit 0
- **Max feedback latency:** ~30 seconds (focused file run)

---

## Per-Task Verification Map

> Task IDs assigned by the planner. Each behavior below maps to ENT-10 and MUST be covered by a task's `<automated>` verify (or a Wave 0 dependency).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD (planner) | — | — | ENT-10 | T-replay/T-order | Enabled: summary webhook → cache write (customer, ≤10 entitlements, `has_more`) | integration | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-order | Out-of-order / replayed summary cannot regress cache (monotonic) | property | `cd accrue && mix test test/property/entitlement_summary_monotonic_property_test.exs` | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-order | Tie (`:eq` ts) processes; strict `:lt` skips with `:stale_event` telemetry | unit | (in integration file) | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-EoP | Disabled (default): zero cache read on gate path; surface == Phase 126 | isolation/integration | `cd accrue && mix test test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-EoP | Disabled: static check — no cache reference reachable from default gate path | static grep gate | `scripts/ci/verify_entitlement_sync_isolation.sh` | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-poison | Customer-not-found → `:deferred` + orphan telemetry, no raise | unit | (in integration file) | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-poison | Malformed payload (no `customer` / non-list `entitlements`) → `:ignored`, no garbage write | unit | (in integration file) | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | — | Truncated summary (`has_more: true`) flagged partial; never denies a gate | unit | (in integration file) | ❌ W0 | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | — | Capability matrix: NEW `entitlements.stripe_native_sync` row; convergence row untouched | drift gate | `scripts/ci/verify_processor_support_matrix.sh` | ✅ extend | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | T-EoP | Fail-closed contract still holds with overlay present | property (existing) | `cd accrue && mix test test/property/entitlements_fail_closed_property_test.exs` | ✅ stays green | ⬜ pending |
| TBD (planner) | — | — | ENT-10 | — | Docs: eventual-consistency window + 10-cap + deferred 1.2 read documented | doc verifier | `scripts/ci/verify_package_docs.sh` (extend needles) | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` — webhook→cache integration (clone `default_handler_phase3_test.exs` + `_out_of_order_test.exs`); covers ENT-10 enabled/stale/tie/orphan/malformed/truncated
- [ ] `accrue/test/property/entitlement_summary_monotonic_property_test.exs` — shuffle-order invariant (clone `entitlements_fail_closed_property_test.exs` structure + `stream_data` generators)
- [ ] `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` — off-by-default: assert no cache table read (Ecto `[:accrue, :repo, :query]` telemetry) + surface parity with Phase 126
- [ ] `scripts/ci/verify_entitlement_sync_isolation.sh` — static grep gate (clone `verify_core_liveview_runtime_free.sh`); wire merge-blocking in `docs-contracts-shift-left`
- [ ] `StripeFixtures.entitlement_summary_event/2` test helper (clone `StripeFixtures.webhook_event/3` + `subscription_created/1` shape)
- [ ] Migration coverage via `Accrue.BillingCase` (table exists, columns present)

*Framework already installed — no install command needed. All gaps are new test/fixture files + one new CI script, plus extensions to two existing scripts.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host enables the `entitlements.active_entitlement_summary.updated` event on their Stripe Dashboard webhook endpoint | ENT-10 | Host-owned Stripe Dashboard config, not an Accrue artifact | Documented in `guides/entitlements.md` enable steps; verified by doc-needle gate, not an automated runtime test |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
