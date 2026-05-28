# Plan 01 Summary

**Objective**: Provide the core state-checking helper `Accrue.Dunning.requires_attention?/1` for host apps to query if a customer is in an active dunning campaign.

**Execution Details**:
- Created `Accrue.Dunning` module in `accrue/lib/accrue/dunning.ex`.
- Implemented `requires_attention?/1` that accepts a `billable` or `customer` struct/id and delegates to `Accrue.Billing.Query.in_active_dunning_campaign/1`.
- Created `accrue/test/accrue/dunning_test.exs` to verify both true/false behaviors of `requires_attention?/1` using mock factory setups.

**Verification**:
- `mix test accrue/test/accrue/dunning_test.exs` passed successfully.
