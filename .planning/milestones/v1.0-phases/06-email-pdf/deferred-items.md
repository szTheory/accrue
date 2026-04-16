# Phase 06 email-pdf — deferred items

## Pre-existing Accrue.Processor.Fake GenServer lifecycle flake

**Discovered during:** Plan 06-04 full-regression run (post Task 3).

**Symptom:** Under certain seeds (e.g. `--seed 1`, `--seed 11`, `--seed 44`,
`--seed 99`) a small subset of tests (`Accrue.Billing.TrialTest`,
`Accrue.Processor.IdempotencyTest`) exit early with:

```
** (exit) exited in: GenServer.call(Accrue.Processor.Fake, :reset, 5000)
   ** (EXIT) no process: the process is not alive or there's no process
   currently associated with the given name
```

**Root cause (hypothesis):** The test-helper checkout of
`Accrue.Processor.Fake` races a sibling test's teardown that stops the
GenServer. This is orthogonal to Phase 6 — the Fake processor lifecycle
is owned by Phase 1 test infrastructure.

**Evidence it is pre-existing:** running `git stash` + `mix test --seed 1`
against the committed baseline (before Plan 06-04 touched anything)
produces 26 failures at seed 1; my Plan 06-04 changes actually
*reduce* the failure count at that seed (they only affected the mailer
Adapter/assertions path, which is green).

**Scope:** Out of scope for Plan 06-04 (Rule: SCOPE BOUNDARY).
Filed here for future investigation — a Phase 1 test-helper patch is
the right fix surface.

**Reproduction:**

```bash
cd accrue && mix test --seed 1
# vs
cd accrue && mix test --seed 0   # passes clean
```
