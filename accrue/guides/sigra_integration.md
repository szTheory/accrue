# Sigra Integration

Sigra is the first-party auth adapter path for Accrue. When the host app
already uses Sigra, keep Sigra as the source of truth for signed-in users,
admin checks, and audit actor ids, then point Accrue at the adapter module.

This guide stays at the documented adapter boundary. It does not require
private Sigra internals, and it does not promise behavior outside the
published `Accrue.Auth` callbacks.

### Not using Sigra?

This walkthrough assumes **Sigra is already chosen** and you are wiring Accrue to the published adapter. If you are on the **community auth** path instead, read [Auth adapters](auth_adapters.md) first for the `Accrue.Auth` contract and supported patterns. For **organization-shaped billing** without Sigra, use [Organization billing (session → billable)](organization_billing.md) as the mainline from session to billable row. Do not reference `Accrue.Integrations.Sigra` in host code or config unless the `:sigra` dependency is present and compiled.

## Add the dependency

Add Sigra to the host app the same way you would for any normal Phoenix
installation, then compile Accrue in the same project so the conditional
adapter can be defined when `Code.ensure_loaded?(Sigra)` succeeds.

Your dependency line belongs in the host application:

```elixir
defp deps do
  [
    {:sigra, "~> 0.1"},
    {:accrue, "~> 1.0"}
  ]
end
```

Accrue does not vendor Sigra or start it for you. The host app owns Sigra
installation, routing, and any user or session schema choices.

## Configure Accrue

Point Accrue at the first-party adapter in config:

```elixir
config :accrue, :auth_adapter, Accrue.Integrations.Sigra
```

That setting keeps Accrue Admin and billing audit rows on the same auth
boundary as the rest of the host app. If Sigra is absent, leave the adapter
on your fallback module and do not reference `Accrue.Integrations.Sigra`.

For the broader adapter contract and community-auth patterns, see the
`Accrue.Auth` guide in `guides/auth_adapters.md`.

## What the adapter handles

`Accrue.Integrations.Sigra` implements `Accrue.Auth`, so Accrue asks it for:

- the current signed-in user
- the admin route boundary
- the audit sink
- the canonical actor id used in event rows

Keep authorization policy in the host app. Accrue consumes the adapter; it
does not replace Sigra's session, authorization, or account lifecycle.

## Verify audit flow

After wiring the adapter, verify the billing path with the normal host-facing
surface:

1. Start the host app with Sigra enabled.
2. Sign in as an admin user through the normal Sigra flow.
3. Perform an Accrue admin action that records an audit trail, such as a
   cancellation, pause, or replay action.
4. Confirm the resulting event or audit row contains the actor id from the
   Sigra-backed user.

For automated checks, keep the Fake Processor as the primary test surface and
exercise the host billing flow with `Accrue.Test`. That keeps auth integration
tests local while avoiding real processor calls or copied secrets.
