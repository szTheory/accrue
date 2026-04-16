# Phase 3 Deferred Items

Out-of-scope issues encountered during plan execution. Track here, fix later.

## From 03-02 (schema foundation)

### Pre-existing test warnings in `test/accrue/webhook/dispatch_worker_test.exs`

Discovered while running `MIX_ENV=test mix test --warnings-as-errors` to verify
03-02 Task 2. These are pre-existing from Phase 2 commit `b86239d`
(`feat(02-04): handler dispatch chain, DefaultHandler, DispatchWorker, Pruner`)
and unrelated to 03-02 schema work.

1. `test/accrue/webhook/dispatch_worker_test.exs:181:5` — unused variable
   `processed_at`; fix by prefixing with `_processed_at` or removing the
   assignment.
2. `test/accrue/webhook/dispatch_worker_test.exs:6:3` — unused alias `Event`
   in the `alias Accrue.Webhook.{DispatchWorker, WebhookEvent, Event, Pruner}`
   line; remove `Event` from the multi-alias.

Both block `MIX_ENV=test mix test --warnings-as-errors` clean exit. The
`mix test` run itself passes (221 tests, 0 failures) — the warnings are
emitted after successful execution.

**Recommended fix:** one-line cleanup task, pick up alongside any Phase 3
webhook-touching plan (03-03 or later).
