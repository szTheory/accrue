# Phase 158: Oban Cron Wiring Adopter Proof - Research

**Researched:** 2026-05-31
**Status:** Complete
**Phase:** 158 - Oban Cron Wiring Adopter Proof

## Research Question

What does the planner need to know to make `examples/accrue_host` prove that Accrue's required Oban cron workers and queues are wired in the host config, without adding new runtime behavior or duplicating core job tests?

## Findings

### Oban config testing

Oban's current documentation supports exactly the proof shape this phase needs:

- Use `Config.Reader.read!/2` to read a config file from disk in a test.
- Extract the host's `[:accrue_host, Oban]` config from the read result.
- Use `Oban.Config.validate/1` to validate top-level options, queues, and plugin options.
- Cron configuration can also be validated through plugin validation, but top-level `Oban.Config.validate/1` is sufficient when the test is proving the full host Oban config.

Primary docs:

- `https://oban.hexdocs.pm/testing_config.html` - demonstrates `Config.Reader.read!(env: :prod) |> get_in([:my_app, Oban])` followed by `Oban.Config.validate(config)`.
- `https://oban.hexdocs.pm/Oban.Config.html` - documents `validate/1` as public config verification and notes that it helps when test config differs from production config.

### Current host config state

`examples/accrue_host/config/config.exs` already declares:

- Queues: `accrue_webhooks`, `accrue_mailers`, `accrue_pdf`, `accrue_dunning`, `accrue_meters`, `accrue_scheduled`.
- Cron workers:
  - `Accrue.Jobs.DunningSweeper`
  - `Accrue.Jobs.DetectExpiringCards`
  - `Accrue.Jobs.MeterEventsReconciler`
  - `Accrue.Jobs.MeteredRenewalReconciler`

`examples/accrue_host/config/test.exs` deliberately overrides the runtime Oban config with:

- `queues: false`
- `plugins: false`
- `testing: :manual`

That test runtime posture is correct for Ecto sandbox safety, but it cannot be accepted as proof that the base host config is wired for adopters.

### Current recovery wiring test gap

`examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` currently:

- Reads `Application.fetch_env!(:accrue_host, Oban)`, so under `MIX_ENV=test` it sees the disabled runtime config.
- Treats `plugins == false` and `queues == false` as acceptable pass paths.
- Checks only three cron workers and omits `Accrue.Jobs.DunningSweeper`.
- Checks only `accrue_meters` and `accrue_scheduled` when queues are enabled.
- Includes smoke tests for job functions, which are secondary at best and overlap with deeper core job tests.

The upgraded proof should read base `config.exs` directly, validate it, and assert exact queue/cron membership.

### Queue truth

The roadmap and PRF-03 text say "all four required Oban queues" and list `accrue_webhooks`, `accrue_mailers`, `accrue_meters`, and `accrue_scheduled`. The worker truth shows this list is incomplete for the cron proof because `DunningSweeper` runs on `:accrue_dunning`.

Relevant worker bindings:

- `Accrue.Jobs.DunningSweeper` -> `:accrue_dunning`
- `Accrue.Jobs.DetectExpiringCards` -> `:accrue_scheduled`
- `Accrue.Jobs.MeterEventsReconciler` -> `:accrue_meters`
- `Accrue.Jobs.MeteredRenewalReconciler` -> `:accrue_meters`
- `Accrue.Webhook.DispatchWorker` -> `:accrue_webhooks`
- `Accrue.Workers.Mailer` -> `:accrue_mailers`

Planning should preserve PRF-03's required runtime queues while also asserting `:accrue_dunning`, because omitting it would let the DunningSweeper cron pass while its queue is not configured.

### Existing pattern to preserve

Phase 157 established a narrow adopter-proof pattern:

- Use the existing example-host proof surface rather than creating a parallel suite.
- Prove the host integration seam directly.
- Avoid broad behavior duplication when core `accrue` tests already cover job internals.
- Keep copyable teaching next to the exact callsite/config surface where adopters need it.

Phase 158 should follow the same pattern.

## Recommended Plan Shape

Create one focused plan covering three files:

1. Upgrade `recovery_wiring_test.exs` into a config-contract proof.
   - Import or reference `Config.Reader`.
   - Read `config/config.exs` relative to `examples/accrue_host`.
   - Extract `[:accrue_host, Oban]`.
   - Assert `Oban.Config.validate(base_oban_config) == :ok`.
   - Assert runtime test config still has `queues: false`, `plugins: false`, and `testing: :manual` so safety stays explicit.
   - Assert the base queues include `:accrue_webhooks`, `:accrue_mailers`, `:accrue_dunning`, `:accrue_meters`, and `:accrue_scheduled`.
   - Assert `Oban.Plugins.Cron` includes all four cron worker modules.
   - Remove or demote behavior-heavy smoke tests unless they are trivially stable and secondary.

2. Add adopter teaching in `config.exs`.
   - Put a concise append-merge comment immediately above the `crontab:` key.
   - The comment should tell adopters with an existing crontab to append Accrue entries instead of replacing their own entries.
   - Include a small shape such as `crontab: existing_cron_jobs() ++ [ ...Accrue entries... ]`.

3. Update the adoption-proof matrix.
   - Update the Recovery wiring row to mention all four cron workers.
   - Mention the required queues including `accrue_dunning`.
   - Point to `config/config.exs` for the append-merge comment rather than duplicating the full snippet.

## Validation Architecture

The execution plan should verify:

- `cd examples/accrue_host && mix test test/accrue_host/recovery_wiring_test.exs --seed 0`
- `rg "DunningSweeper|DetectExpiringCards|MeterEventsReconciler|MeteredRenewalReconciler" examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`
- `rg "accrue_webhooks|accrue_mailers|accrue_dunning|accrue_meters|accrue_scheduled" examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`
- `rg "existing_cron_jobs\\(\\).*\\+\\+" examples/accrue_host/config/config.exs`
- `rg "append|replacing|config/config.exs|DunningSweeper|accrue_dunning" examples/accrue_host/docs/adoption-proof-matrix.md`

## Risks and Pitfalls

- Do not use `Application.fetch_env!/2` as the primary proof. It reads the test override and can pass while base `config.exs` is missing workers or queues.
- Do not assert only the four queues named in the stale PRF-03 text. `:accrue_dunning` is required for the DunningSweeper cron worker.
- Do not add a production helper module for config fragments. The phase is an adopter-proof closeout, not a new API surface.
- Do not duplicate the full append-merge snippet in README and matrix. Keep the canonical teaching in `config.exs`.
- Do not expand into broad worker behavior tests; existing core tests and `dunning_wiring_test.exs` cover deeper behavior.

## RESEARCH COMPLETE
