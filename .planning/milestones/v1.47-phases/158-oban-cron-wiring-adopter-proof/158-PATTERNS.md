# Phase 158: Oban Cron Wiring Adopter Proof - Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs` | ExUnit host proof | static config -> assertions | same file + `dunning_wiring_test.exs` | high |
| `examples/accrue_host/config/config.exs` | host config | copyable adopter config | same file | exact |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | docs matrix | proof inventory | same file | exact |

## Pattern Assignments

### `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs`

**Current setup pattern:**

- `use AccrueHost.AccrueCase, async: false`
- `use Oban.Testing, repo: AccrueHost.Repo`
- Aliases the recovery cron worker modules
- Reads runtime config with `Application.fetch_env!(:accrue_host, Oban)`
- Accepts test safety values (`plugins: false`, `queues: false`) as a pass path

**Phase 158 target pattern:**

- Keep the test in this file; do not create a parallel proof surface.
- Add `alias Accrue.Jobs.DunningSweeper`.
- Read `examples/accrue_host/config/config.exs` with `Config.Reader.read!/2`.
- Extract `[:accrue_host, Oban]` from the read config and validate it with `Oban.Config.validate/1`.
- Assert `Application.fetch_env!(:accrue_host, Oban)` still has `plugins: false`, `queues: false`, and `testing: :manual` as a separate test-safety assertion.
- Assert base config queues include:
  - `:accrue_webhooks`
  - `:accrue_mailers`
  - `:accrue_dunning`
  - `:accrue_meters`
  - `:accrue_scheduled`
- Assert base config cron workers include:
  - `Accrue.Jobs.DunningSweeper`
  - `Accrue.Jobs.DetectExpiringCards`
  - `Accrue.Jobs.MeterEventsReconciler`
  - `Accrue.Jobs.MeteredRenewalReconciler`

**Closest analogs:**

- Same file for module shape and host proof naming.
- `examples/accrue_host/test/accrue_host/dunning_wiring_test.exs` for the principle that example-host tests prove a thin host seam while deeper behavior stays in core tests.
- Oban docs for `Config.Reader.read!/2` + `Oban.Config.validate/1` config testing.

### `examples/accrue_host/config/config.exs`

**Current config shape:**

- `config :accrue_host, Oban` contains `repo`, `queues`, and `plugins`.
- `plugins` contains `{Oban.Plugins.Cron, crontab: [...]}`.
- All target queues and cron workers are already declared.

**Phase 158 target pattern:**

- Add only a short comment immediately above `crontab:`.
- Teach append-merge for adopters with an existing crontab.
- Include the concrete shape `crontab: existing_cron_jobs() ++ [ ...Accrue entries... ]`.
- Do not refactor config into helper functions.

### `examples/accrue_host/docs/adoption-proof-matrix.md`

**Current matrix row:**

- Recovery wiring row mentions `accrue_meters`, `accrue_scheduled`, `DetectExpiringCards`, and `MeterEventsReconciler`.
- It omits `DunningSweeper`, `MeteredRenewalReconciler`, `accrue_webhooks`, `accrue_mailers`, and `accrue_dunning`.

**Phase 158 target pattern:**

- Update the existing Recovery wiring row in place.
- List all four cron worker modules.
- List the host queue set including `accrue_dunning`.
- Point to `config/config.exs` for the append-merge comment.
- Do not add a second long section or duplicate the config snippet.

## Related Source Truth

### `examples/accrue_host/config/test.exs`

Runtime test config intentionally disables Oban queues/plugins and sets `testing: :manual`. The recovery wiring test should preserve this as a safety assertion but not treat it as the adopter wiring proof.

### Worker queue declarations

- `accrue/lib/accrue/jobs/dunning_sweeper.ex` uses `queue: :accrue_dunning`.
- `accrue/lib/accrue/jobs/detect_expiring_cards.ex` uses `queue: :accrue_scheduled`.
- `accrue/lib/accrue/jobs/meter_events_reconciler.ex` uses `queue: :accrue_meters`.
- `accrue/lib/accrue/jobs/metered_renewal_reconciler.ex` uses `queue: :accrue_meters`.
- `accrue/lib/accrue/webhook/dispatch_worker.ex` uses `queue: :accrue_webhooks`.
- `accrue/lib/accrue/workers/mailer.ex` uses `queue: :accrue_mailers`.

### Core behavior tests

The executor should avoid re-creating behavior-heavy job coverage in `recovery_wiring_test.exs`; richer dunning behavior is already covered by `dunning_wiring_test.exs` and core package tests, while Phase 158's target is static host wiring proof.
