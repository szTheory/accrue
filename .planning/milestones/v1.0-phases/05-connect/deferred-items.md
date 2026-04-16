# Phase 05 Deferred Items

Out-of-scope discoveries noted during execution but not fixed in the
current plan (GSD Rule: scope boundary — only auto-fix issues directly
caused by current task changes).

## Pre-existing compiler warnings (not caused by Phase 05)

1. **`test/accrue/checkout_test.exs:178`** — `_suppress_unused_alias_warning/0`
   is unused. Added by Phase 4 plan 04-07 (commit 8a2a70e) as a workaround
   for an earlier alias warning; current codebase makes the alias
   `Accrue.Processor.Fake` unused. Trips `--warnings-as-errors`.

2. **`test/accrue/webhook/checkout_session_completed_test.exs:44`** —
   `refute match?({:error, _}, {:ok, result})` triggers an Elixir 1.17+
   type-checker "clause will never match" warning because the RHS is
   statically known to be `{:ok, _}`. Test is correct; warning is new
   with the 1.17 type-inference pass. Trips `--warnings-as-errors`.

Both predate Phase 5 (verified via git blame to commit 8a2a70e,
Phase 04 P07). Fix should land in a follow-up quick task, not
as a Phase 5 deviation.

## Pre-existing dialyzer failures (not caused by Phase 05)

3. **`lib/mix/tasks/accrue.webhooks.replay.ex:84,101,110,112`** —
   `unknown_function Mix.raise/1` and `Mix.shell/0`. Verified
   pre-existing via `git stash && mix dialyzer` baseline comparison
   on 2026-04-14 during Plan 07 execution.

4. **`lib/accrue/connect.ex:71,125,146,...`** — 20+ `unknown_type`
   warnings on existing `@spec` declarations. Not introduced by
   Plan 07; Plan 07 did not modify `lib/accrue/connect.ex`. These
   are from Plans 02-05 and should be addressed as a Phase 5
   cleanup quick task referencing the `lattice_stripe` struct types.

Both confirmed pre-existing by stashing Plan 07 changes and re-running
`mix dialyzer` — the same warnings appear with identical line numbers.
