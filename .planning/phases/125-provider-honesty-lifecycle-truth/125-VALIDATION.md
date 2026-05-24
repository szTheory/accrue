---
phase: 125
slug: provider-honesty-lifecycle-truth
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 125 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + `stream_data` (property tests for the lifecycle truth table) |
| **Config file** | `accrue/test/test_helper.exs`, `accrue/mix.exs` (existing — no install needed) |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements/provider_honesty_test.exs` (per-file during a task) |
| **Full suite command** | `cd accrue && mix test` (the merge-blocking `release-gate`) |
| **Drift-gate command** | `bash scripts/ci/verify_processor_support_matrix.sh` (the merge-blocking `docs-contracts-shift-left` job) |
| **Estimated runtime** | quick ~2–5s · full suite ~tens of seconds · drift gate <1s |

---

## Sampling Rate

- **After every task commit:** Run the relevant per-file `mix test <file>` (quick) + `bash scripts/ci/verify_processor_support_matrix.sh` when a capabilities/matrix file changed.
- **After every plan wave:** Run `cd accrue && mix test` (full suite).
- **Before `/gsd:verify-work`:** Full suite green AND `verify_processor_support_matrix.sh` exits 0.
- **Max feedback latency:** ~5s for per-file runs.

---

## Per-Task Verification Map

> Filled once PLAN.md files exist (one row per task). Columns below are the contract;
> the gsd-planner emits matching `<automated>` verify commands and the executor checks them off.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 125-AA-NN | AA | W | ENT-08 / ENT-09 | — / T-125-* | {expected behavior} | unit / property / gate | `{command}` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

New test/proof artifacts this phase introduces (created by their owning tasks, not a separate Wave 0 install — ExUnit already exists):

- [ ] `accrue/test/accrue/entitlements/provider_honesty_test.exs` — Fake-lane deterministic proof: `LocalMap.resolve/2` byte-identical across Fake/Stripe/Braintree with zero processor calls; `Capabilities` `:entitlements` labels equal the doc literals (D-05, SC#1).
- [ ] Lifecycle truth-table pin test (all 8 `@statuses` × modifiers → expected ✅/✗) — table-driven or `stream_data`, merge-blocking via `release-gate` (D-12/D-14, SC#3).
- [ ] `scripts/ci/verify_processor_support_matrix.sh` extension — `require_substring` + stale-row + NEGATIVE divergence guard for the entitlements rows (D-06/D-08, SC#2).
- [ ] Past-due grace behavioral coverage — `within_grace?/2` window math (clock-driven via `Accrue.Clock`), `:none` default fail-closed, `:dunning`/N-day grant, telemetry `:past_due_grace` / `:past_due_expired` reasons (D-15..D-20, SC#3/#4).

*Existing infrastructure (ExUnit + stream_data) covers all phase requirements — no framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification (unit, property, and bash drift gate).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
