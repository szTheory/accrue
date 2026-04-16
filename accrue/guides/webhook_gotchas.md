# Webhook Gotchas

Webhook bugs usually come from wiring mistakes, not from the reducer itself.
This guide covers the failure modes most likely to break verification,
idempotency, or replay safety in a production Phoenix app.

Keep examples on placeholders only. Real webhook secrets are never committed,
and copied snippets should be reviewed before they are promoted to a live
environment.

## Raw body ordering

Raw-body capture must run before `Plug.Parsers`. Signature verification depends
on the exact bytes Stripe signed, so any earlier JSON parsing or body mutation
will break verification.

The webhook pipeline needs the caching body reader on the webhook scope:

```elixir
pipeline :accrue_webhooks do
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Phoenix.json_library(),
    body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}
end
```

Do not install that body reader globally. Keep it on webhook routes only so the
rest of the application keeps its normal request parsing behavior.

## Signature verification

Signature verification is mandatory. A webhook endpoint that skips verification
is not a valid production integration, even if the route is obscured or limited
by network controls.

Accrue expects the raw request body and the signature header together. If either
is missing, treat the request as invalid and return a failure response rather
than trying to reduce the payload anyway.

## Secret rotation

Rotate secrets by configuration, not by pasting values into code or docs. Real
webhook secrets are never committed, and examples should use placeholders such
as `"WEBHOOK_SECRET_CURRENT"` and `"WEBHOOK_SECRET_PREVIOUS"`.

During rotation, keep the old and new secret available long enough for in-flight
events to clear, then remove the old value once verification logs and delivery
history show the new secret is handling traffic.

## Re-fetch current objects

Treat webhook payloads as signals, not as your source of truth. When a handler
needs current subscription, invoice, or charge state, re-fetch the current
object through the processor path before you persist local state changes.

That avoids stale-snapshot bugs and keeps out-of-order deliveries from forcing
the local model backward.

## Replay and DLQ hygiene

Replays must use the same reducer path as first delivery. Do not build a
separate "replay-only" code path that bypasses the normal ingest, verification,
or reconciliation flow.

For dead-letter handling:

- keep replay operations idempotent
- preserve enough metadata to explain why the original delivery failed
- use the same reducer path for manual replay, CLI replay, and queue-driven retry
- review DLQ rows before bulk requeue so one bad payload does not churn forever

The goal is simple: the event that succeeds on replay should look like a normal
delivery with better timing, not like a different subsystem.
