# Deferred Items

- `cd accrue && mix test` has 13 failures outside Plan 218-06. They arise from pre-existing, unstaged decision-case ordering and entitlement-plan `:quotas` configuration changes, not Apple ordering/lifecycle code. Targeted Apple, projector, and projection-property suites pass.
