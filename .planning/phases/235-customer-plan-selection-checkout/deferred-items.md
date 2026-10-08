# Deferred Items — Phase 235 Plan 01

- `accrue_admin/lib/accrue_admin/live/subscription_live.ex:172` emits an existing compiler warning because `handle_event/3` clauses are not grouped. This is unrelated to the mounted checkout hook and browser spec.
- The host test application emits an existing `ex_money` warning about automatically starting the exchange rate service. This is unrelated to the mounted checkout hook and browser spec.
