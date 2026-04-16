# Phase 10: Host App Dogfood Harness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 10-Host App Dogfood Harness
**Areas discussed:** Harness location and shape, host auth boundary, Fake-backed billing flow, webhook proof, admin audited action, local verification

---

## Harness Location and Shape

| Option | Description | Selected |
|--------|-------------|----------|
| `examples/accrue_host` | Visible example-style Phoenix app that can become the canonical dogfood path and later feed adoption assets. | ✓ |
| Root `host_app/` | Very prominent in repo root, but less conventional for OSS example/demo paths. | |
| Test-only fixture under `accrue/test` | Fast and contained, but too synthetic to prove first-user DX. | |

**User's choice:** Workflow fallback selected the recommended default: `examples/accrue_host`.
**Notes:** This keeps the phase realistic without turning it into the Phase 13 tutorial/demo polish effort.

---

## Host Auth Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Phoenix-auth-shaped host session | Host-owned `Accounts.User`, session cookie, admin check, and public Accrue auth adapter path. | ✓ |
| Sigra-backed auth | Realistic and supported, but relies on another Jon-owned library and would not stress generic first-user integration. | |
| Test bypass only | Simple, but fails the phase requirement for a realistic auth/session boundary. | |

**User's choice:** Workflow fallback selected the recommended default: Phoenix-auth-shaped host session.
**Notes:** The admin mount may have explicit test helpers, but the normal path must be session-protected.

---

## Fake-Backed Billing Flow

| Option | Description | Selected |
|--------|-------------|----------|
| SaaS-style subscribe/update flow | User views plans, subscribes via generated facade, sees persisted billing state, and performs one update action. | ✓ |
| Minimal create-subscription button only | Easier, but weaker proof of realistic lifecycle behavior. | |
| Direct DB seed plus admin inspection | Useful for fixtures, but bypasses the public APIs this phase exists to validate. | |

**User's choice:** Workflow fallback selected the recommended default: SaaS-style subscribe/update flow.
**Notes:** Deterministic Fake price IDs are acceptable. No live Stripe network access in the required path.

---

## Webhook Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Signed POST through host webhook route | Exercises raw-body handling, signature verification, ingest, dispatch, idempotency, and ledger state. | ✓ |
| `Accrue.Test.Webhooks.trigger_event/2` only | Good helper reference, but bypasses the mounted Plug route. | |
| Direct reducer invocation | Too private and too narrow for dogfooding. | |

**User's choice:** Workflow fallback selected the recommended default: signed POST through the host route.
**Notes:** `Accrue.Test.Webhooks` remains useful, but the phase must prove the public Plug integration.

---

## Admin Audited Action

| Option | Description | Selected |
|--------|-------------|----------|
| Webhook replay/requeue | Existing admin capability, low product-policy burden, and naturally tied to webhook/event history. | ✓ |
| Refund or cancellation | Realistic but requires more product policy and payment semantics than the dogfood harness needs. | |
| View-only admin proof | Insufficient because the roadmap requires one audited admin action. | |

**User's choice:** Workflow fallback selected the recommended default: webhook replay/requeue.
**Notes:** The proof must assert persisted audit/event output, not only UI success text.

---

## Local Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Local setup/test/browser-equivalent commands | Covers clean checkout setup and dogfood behavior now; Phase 11 promotes the checks to CI. | ✓ |
| Full GitHub Actions gate now | Valuable but explicitly Phase 11 scope. | |
| Manual smoke instructions only | Too weak for a canonical harness. | |

**User's choice:** Workflow fallback selected the recommended default: local verification commands.
**Notes:** Playwright is acceptable if it follows existing repo patterns; Phoenix-level tests can cover the browser-equivalent proof if that is lower-risk for Phase 10.

---

## the agent's Discretion

- Exact Phoenix generator command and committed generated file details.
- Exact route names and UI copy inside the dogfood host app.
- Exact local UAT technology, provided Phase 11 can promote it to CI.
- Exact existing `accrue_admin` audited action selected, provided persisted audit/event output is verified.

## Deferred Ideas

- Mandatory GitHub Actions host-app gate — Phase 11.
- Hex-style dependency validation and first-hour troubleshooting polish — Phase 12 unless trivial.
- Public tutorial/demo packaging and screenshots — Phase 13.
- Quality hardening checks — Phase 14.
- Hosted public demo — future `HOST-09`.
