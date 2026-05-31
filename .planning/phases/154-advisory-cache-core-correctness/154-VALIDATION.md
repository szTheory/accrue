---
phase: 154
slug: advisory-cache-core-correctness
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-30
validated: 2026-05-31
---

# Phase 154 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs --seed 0` |
| **Full suite command** | `mix test` (from `accrue/` directory) |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs --seed 0`
- **After every plan wave:** Run `mix test` from `accrue/` directory
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| ADV-01 OCC removal | 01 | 1 | ADV-01 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`; code in `accrue/lib/accrue/billing/entitlement_summary.ex` | ✅ green |
| ADV-02 nil-ts | 01 | 0 | ADV-02 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ green |
| ADV-03 stale | 01 | 0 | ADV-03 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ green |
| ADV-04 concurrent | 01 | 0 | ADV-04 | — | N/A | integration | `mix test test/accrue/webhook/wr05_concurrency_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/wr05_concurrency_test.exs` uses `Sandbox.allow/3` | ✅ green |
| POL-01 processor | 01 | 0 | POL-01 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ green |
| POL-02 livemode | 01 | 0 | POL-02 | — | N/A | unit | `mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs --seed 0` | ✅ `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — ADV-02: nil `last_stripe_event_ts` event updates the row, not a silent no-op
- [x] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — ADV-03: DB-level stale skip returns `{:ok, :stale}`, emits `result: :unchanged`, and writes no second ledger event
- [x] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — POL-01: event processor writes the correct `:processor` field, not the global config default
- [x] `test/accrue/webhook/default_handler_entitlement_summary_test.exs` — POL-02: follow-up event with absent `livemode` carries forward prior row's livemode
- [x] `test/accrue/webhook/wr05_concurrency_test.exs` — ADV-04 concurrent test uses `Ecto.Adapters.SQL.Sandbox.allow/3` in both `Task.async` workers

*Wave 0 must complete before Wave 1 implementation tasks can be verified.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Audit 2026-05-31

| Metric | Count |
|--------|-------|
| Requirements audited | 6 |
| Covered | 6 |
| Partial | 0 |
| Missing | 0 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

### Evidence

- `ADV-01` — `EntitlementSummary.force_changeset/2` no longer calls `optimistic_lock/1`, and `lock_version` is absent from `@cast_fields`.
- `ADV-02` — `ADV-02: nil last_stripe_event_ts event updates the row` covers nil incoming watermarks.
- `ADV-03` — `ADV-03: DB-level stale skip emits result: :unchanged, no ledger event` covers DB-level stale return, telemetry, and no duplicate ledger write.
- `ADV-04` — `WR05ConcurrencyTest` runs two concurrent workers with explicit `Ecto.Adapters.SQL.Sandbox.allow/3` and asserts the newer timestamp wins.
- `POL-01` — `POL-01: processor field reflects event processor, not global config` asserts `"stripe"` is persisted from the event path.
- `POL-02` — `POL-02: follow-up event with absent livemode key carries forward prior row livemode` asserts prior `livemode: true` is preserved.

### Verification Commands

- `cd accrue && mix compile --warnings-as-errors` — passed
- `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs test/accrue/webhook/wr05_concurrency_test.exs --seed 0` — 17 tests, 0 failures

No additional generated test files were needed; all Phase 154 requirements already had targeted automated coverage.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-31
