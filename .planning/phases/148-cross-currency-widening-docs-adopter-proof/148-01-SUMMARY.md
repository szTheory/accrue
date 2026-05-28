# Plan 01 Summary

**Objective**: Widen `recovered_vs_lost_mrr/1` and implement `recovery_rate/1`.

**Execution Details**:
- Modified `recovered_vs_lost_mrr/1` in `Accrue.Analytics.Dunning` to group events by `?->>'currency'` alongside `type`.
- Changed the return structure from a flat map `%{recovered_cents: N, lost_cents: N}` to lists of maps per currency: `%{recovered: [%{currency: "usd", cents: N}, ...], lost: [%{currency: "usd", cents: N}, ...]}`.
- Handled backwards compatibility by defaulting missing currency to `"usd"`.
- Implemented `recovery_rate/1` which leverages `funnel/1` to calculate the mathematical recovery rate (`recovered / (recovered + exhausted)`). Handles zero divisor gracefully by returning `nil`.
- Updated test cases in `accrue/test/accrue/analytics/dunning_test.exs` to assert against the new multi-currency shape.
- Added tests for `recovery_rate/1` arithmetic logic.

**Verification**:
- `mix test test/accrue/analytics/dunning_test.exs` completed with `20 tests, 0 failures`.

**Next Steps**: Proceed to Plan 02 to update the admin UI to consume this widened shape.