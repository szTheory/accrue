# Deferred Items — Quick Task 260414-l9q

Out-of-scope items discovered during execution. Not fixed in this task.

## Pre-existing test flake

The full `mix test` suite produces 0 failures on the stable path but
occasionally produces 1 failure on first-run. This flakiness predates
this quick task (confirmed on baseline before any changes) and does
not appear to involve the tests added by this task. Re-running always
returns green.

Repro notes:

- First `mix test` after a fresh `mix compile`: 1 failure (intermittent)
- Subsequent runs: 0 failures, stable
- Observed on branch base commit `6b4f0d1f` before any l9q changes

Not investigated. Track separately if it recurs.
