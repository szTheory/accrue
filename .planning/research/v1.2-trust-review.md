# Phase 15 — Trust review (checked-in artifact)

This file satisfies the **Accrue.Docs.TrustReviewTest** contract and summarizes trust
boundaries for the v1.2 trust-hardening milestone. Keep it updated when release gates
or evidence paths change.

## Trust Boundaries

- **webhook request -> raw-body verification** — Stripe signatures verified before parsers.
- **host auth/session -> /billing mount** — Only signed-in scopes reach mounted admin.
- **admin operator -> replay action** — Replay is host-authorized and audit-visible.
- **generated installer output -> host-owned code** — `mix accrue.install` stamps host boundaries.
- **retained browser artifacts -> repo/CI storage** — Playwright traces/screenshots policy.
- **public docs/issues -> maintainer intake** — Templates route sensitive reports privately.
- **public errors/logs -> diagnostic readers** — No secrets in surfaced errors (TRUST-05).

## Evidence (concrete repo paths)

- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs`
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs`
- `.github/ISSUE_TEMPLATE/bug.yml`
- `.github/ISSUE_TEMPLATE/integration-problem.yml`
- `scripts/ci/accrue_host_uat.sh`
- `.github/workflows/ci.yml`
- `accrue/test/accrue/webhook/plug_test.exs`
- `accrue/test/accrue/errors_test.exs`
- `accrue/test/accrue/telemetry/otel_test.exs`

**host-owned** assumptions: the host app owns auth, billing facade, and webhook route wiring.

**advisory** jobs (for example live Stripe) stay non-blocking versus required release gates.

**environment-specific** secrets never ship in docs or fixtures.

Requirement tags referenced here: **TRUST-01**, **TRUST-05**, **TRUST-06**.

### Threat Verification

Each item records **severity**, maps to **ASVS** categories where applicable, and states
whether it is release-blocking. **high-severity findings are release-blocking** and
**cannot be accepted in Phase 15** without remediation. **low or medium** findings may
ship only with **concrete rationale** and a tracked follow-up.
