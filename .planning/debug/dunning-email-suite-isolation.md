---
status: investigating
trigger: "5 test failures appear ONLY in full suite (mix test --seed 0), PASS in isolation. Cross-suite test-isolation / shared-state bug from phase 128 dunning work. All 5 are 'email expected but not delivered' (mailbox empty)."
created: 2026-05-24T00:00:00Z
updated: 2026-05-24T00:00:00Z
---

## Current Focus

hypothesis: Shared dedup/idempotency state for a colliding invoice_id (`in_step_test`) persists across the Ecto sandbox boundary in the full suite, suppressing `:invoice_payment_failed` email deliveries.
test: Locate the exact persisting state (mailglass_deliveries table vs ETS/persistent_term/Agent cache vs Test mailer adapter dedup vs Oban unique).
expecting: Find a global/non-sandboxed store keyed by invoice_id that outlives a test.
next_action: Read lib/accrue/workers/dunning_step.ex, lib/accrue/workers/mailer.ex, lib/accrue/mailer/default.ex to map the delivery + dedup path.

## Symptoms

expected: When dunning step / webhook fires, `:invoice_payment_failed` email is delivered and `{:accrue_email_delivered, :invoice_payment_failed, _}` arrives in the test process mailbox.
actual: In full suite (--seed 0), the mailbox is EMPTY for 5 tests; deliveries suppressed.
errors: assert_received {:accrue_email_delivered, :invoice_payment_failed, _} fails (no matching message).
reproduction: `mix test --seed 0` from accrue/ → 5 failures. `mix test test/accrue/workers/dunning_step_test.exs --seed 0` and `mix test test/accrue/webhook --seed 0` → 0 failures.
started: After phase 128 dunning campaign work.

## Eliminated

## Evidence

- timestamp: investigation-1
  checked: lib/accrue/mailer/test.ex (Accrue.Mailer.Test adapter) + lib/accrue/mailer.ex facade
  found: In test env `config :accrue, :mailer, Accrue.Mailer.Test`. The Test adapter does NO dedup — it just `send(self(), {:accrue_email_delivered, type, assigns})`. So the strong hypothesis (persisting mailglass_deliveries / idempotency state suppressing deliveries) is WRONG for the default test path: there IS no dedup store on the test path.
  implication: Mailbox-empty must come from the global Application env being mutated by another test and not restored, OR an async race against a test that temporarily swaps the global :mailer / :emails env. `Accrue.Mailer.deliver/2` reads `impl()` = `Application.get_env(:accrue, :mailer)` and `enabled?(type)` = `Application.get_env(:accrue, :emails)` — both GLOBAL mutable state.

- timestamp: investigation-2
  checked: grep for tests mutating :mailer / :emails env
  found: Many async:false tests (mailer_test.exs, default_handler_mailer_dispatch_test.exs) swap :mailer to Accrue.Mailer.Default with on_exit restore. If a test swaps global :mailer/:emails and an async:true test runs concurrently (or restore is incomplete), the dunning email goes to Oban (not the test pid) → empty mailbox.
  implication: Need to find the polluting test under --seed 0 and whether failing tests are async:true (vulnerable to concurrent global-env swap) or whether a non-restoring mutation leaks forward.

## Current-Focus reasoning_checkpoint

reasoning_checkpoint:
  hypothesis: "test/accrue/config_test.exs `describe \"get!/1 defaults\"` block (esp. the 'adapter defaults resolve to module atoms' test) calls Application.delete_env(:accrue, :mailer) with NO on_exit restore. This permanently removes the test-env `config :accrue, :mailer, Accrue.Mailer.Test`, so Accrue.Mailer.impl/0 falls back to its hardcoded default Accrue.Mailer.Default for every test that runs afterward in the same suite. Default enqueues an Oban job instead of send(self(), {:accrue_email_delivered,...}), so the test pid mailbox is empty → 5 dunning/webhook email assertions fail."
  confirming_evidence:
    - "DIAG at the failing happy-path test under full suite: impl=Accrue.Mailer.Default enabled?=true emails=[] — :mailer is NOT Accrue.Mailer.Test."
    - "config_test.exs:82-83 deletes :mailer and :mailer_adapter; the describe block has no on_exit and no setup restore."
    - "Minimal repro: `mix test test/accrue/config_test.exs test/accrue/workers/dunning_step_test.exs --seed 0` reproduces 4 failures + DIAG impl=Accrue.Mailer.Default. Running dunning_step_test alone = 0 failures."
    - "Accrue.Mailer.impl/0 = Application.get_env(:accrue, :mailer, Accrue.Mailer.Default) — deleting the key yields the Default fallback."
    - "Accrue.Mailer.Test.deliver does send(self(),...) with NO dedup, so the original strong hypothesis (persisting mailglass/idempotency dedup state) is ruled out for the default test path."
  falsification_test: "If restoring :mailer (and the other deleted keys) in config_test with on_exit does NOT make `mix test --seed 0` go green, the hypothesis is wrong."
  fix_rationale: "Restores the leaked global Application env so each test module sees the test-env default mailer (Accrue.Mailer.Test). Addresses the root cause (unrestored global mutation), not the symptom. No assertions weakened, no production code touched."
  blind_spots: "Other tests in the same describe block delete other keys (:emails, :pdf_adapter, :auth_adapter, :invoice_pdf_adapter, :business_name, etc.) without restore — benign today but same anti-pattern; fixing the whole block's restore is the robust hermetic fix."

## Eliminated

- hypothesis: "Persisting mailglass_deliveries / idempotency-key dedup state suppresses :invoice_payment_failed deliveries across the Ecto sandbox boundary (the strong hypothesis)."
  evidence: "In test env the configured adapter is Accrue.Mailer.Test, which just does send(self(), {:accrue_email_delivered,...}) with ZERO dedup and never reaches Oban/Mailglass/idempotency keys. The mailbox-empty symptom is caused by impl() resolving to Accrue.Mailer.Default (global :mailer env deleted), not by any dedup store."
  timestamp: investigation-final

- hypothesis: "A leaked :emails kill switch ([invoice_payment_failed: false]) suppresses delivery."
  evidence: "DIAG shows enabled?=true at the failing test; emails=[] / nil both yield enabled?=true. Kill switch not the cause."
  timestamp: investigation-final

## Resolution

root_cause: "test/accrue/config_test.exs `describe \"get!/1 defaults\"` block mutates global Application env via Application.delete_env(:accrue, :mailer) (and other keys) with no on_exit restore. The 'adapter defaults resolve to module atoms' test (line 78) deletes :mailer, permanently dropping the test-env `config :accrue, :mailer, Accrue.Mailer.Test`. Every subsequent test in the run then sees Accrue.Mailer.impl/0 fall back to its hardcoded Accrue.Mailer.Default, which enqueues an Oban job instead of sending {:accrue_email_delivered,...} to the test pid → empty mailbox → 5 dunning/webhook email-delivery assertions fail. Under --seed 0, config_test (async:false) runs before the dunning/webhook email tests, so the leak surfaces only in the full suite, not in isolation. Phase 128 added the new dunning email tests that depend on the test-env mailer being Accrue.Mailer.Test, exposing the pre-existing config_test leak."
fix: "Added a `setup` block to the `describe \"get!/1 defaults\"` block in test/accrue/config_test.exs that snapshots every :accrue env key those tests delete (including :mailer / :mailer_adapter / :emails) and restores them via on_exit (delete if previously unset, else put_env the prior value). The block is now hermetic — the test-env `config :accrue, :mailer, Accrue.Mailer.Test` survives the suite, so downstream email tests still resolve the capture adapter. No production code changed, no assertions weakened."
verification: "mix compile --warnings-as-errors exits 0. Full suite `mix test --seed 0`: 56 properties, 1555 tests, 0 failures (11 excluded). Minimal repro `config_test.exs + dunning_step_test.exs --seed 0`: 44 tests, 0 failures (was 4 failures). Isolated re-runs: config_test 36/0, dunning_step 8/0, webhook 117/0."
files_changed: [test/accrue/config_test.exs]
