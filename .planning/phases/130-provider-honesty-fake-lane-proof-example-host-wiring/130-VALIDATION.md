---
phase: 130
slug: provider-honesty-fake-lane-proof-example-host-wiring
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `accrue/test/test_helper.exs` (Oban `testing: :manual`, exclusion tags) |
| **Quick run command** | `cd accrue && mix test test/accrue/dunning/ test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` |
| **Full suite command** | `cd accrue && mix test --seed 0` |
| **Estimated runtime** | ~15-30 seconds (no live network calls) |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/dunning/ --seed 0`
- **After every plan wave:** Run `cd accrue && mix test --seed 0` + `bash scripts/ci/verify_processor_support_matrix.sh`
- **Before `/gsd:verify-work`:** Full suite must be green + drift gate must pass
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 130-01-01 | 01 | 1 | DUN-09 | — | N/A | bash | `bash scripts/ci/verify_processor_support_matrix.sh` | ✅ | ⬜ pending |
| 130-01-02 | 01 | 1 | DUN-09 | — | N/A | doc | `grep -q "dunning.campaign" .planning/processor-support-matrix.md` | ✅ | ⬜ pending |
| 130-01-03 | 01 | 1 | DUN-09 | — | N/A | unit | `cd accrue && mix test --only compile_matrix --seed 0` | ✅ | ⬜ pending |
| 130-02-01 | 02 | 1 | DUN-09 | — | N/A | doc | `test -f accrue/guides/dunning.md` | ❌ W0 | ⬜ pending |
| 130-02-02 | 02 | 2 | DUN-09 | — | N/A | bash | `bash scripts/ci/verify_processor_support_matrix.sh` | ✅ | ⬜ pending |
| 130-03-01 | 03 | 2 | DUN-10 | — | N/A | unit | `cd accrue && mix test test/accrue/dunning/dunning_full_journey_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 130-03-02 | 03 | 2 | DUN-10 | — | N/A | unit | `cd accrue && mix test test/accrue/webhook/dunning_campaign_start_test.exs --seed 0` | ✅ | ⬜ pending |
| 130-04-01 | 04 | 2 | DUN-10 | — | N/A | unit | `cd examples/accrue_host && mix test test/accrue_host/billing/dunning_host_proof_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| 130-04-02 | 04 | 2 | DUN-10 | — | N/A | bash | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/guides/dunning.md` — new guide created (SC#1, D-01..D-04) before drift-gate pins can verify
- [ ] `accrue/test/accrue/dunning/dunning_full_journey_test.exs` — new full-journey test file (SC#3, D-10..D-12)
- [ ] `examples/accrue_host/test/accrue_host/billing/dunning_host_proof_test.exs` — host wiring/journey proof (SC#4, D-16)

*Note: Existing test infrastructure (`Accrue.BillingCase`, `Oban.drain_queue/2`, `Accrue.Test.Clock.advance/2`) ships — no new test framework setup required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `accrue/guides/dunning.md` renders correctly in ExDoc | DUN-09 | ExDoc HTML generation not run in CI quick test | `cd accrue && mix docs && open doc/guides/dunning.html` |

---

## Validation Architecture Notes (from RESEARCH.md)

1. **Drift gate is `bash`, not ExUnit** — `scripts/ci/verify_processor_support_matrix.sh` runs as the `docs-contracts-shift-left` CI job; the ExUnit code-side mirror (D-09) doubles as a compile-time assertion in the journey test.
2. **Oban drain semantics** — `Oban.drain_queue(queue: :accrue_dunning)` in `:manual` mode executes all enqueued (including scheduled) jobs regardless of `scheduled_at`; clock advance is needed only to make `DunningSweeper`'s query predicates select the right subscriptions. Confirm in Wave 1 task 03-01.
3. **`DetectExpiringCards` queue** — uses `:accrue_scheduled`, NOT `:accrue_dunning`; host config must add `accrue_scheduled: 5` if this cron is wired (D-14 discretion item).
4. **No `:release_gate` or `:slow` tag** — the full-journey test is merge-blocking by default (untagged in `test_helper.exs:70` exclusion list).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
