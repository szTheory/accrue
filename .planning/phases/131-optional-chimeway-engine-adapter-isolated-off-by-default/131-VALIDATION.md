---
phase: 131
slug: optional-chimeway-engine-adapter-isolated-off-by-default
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 131 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `accrue/test/test_helper.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/dunning/ test/accrue/integrations/chimeway_test.exs --seed 0` |
| **Full suite command** | `cd accrue && mix test --seed 0` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/dunning/ test/accrue/integrations/ --seed 0`
- **After every plan wave:** Run `cd accrue && mix test --seed 0`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0 | DUN-03 SC#1 | — | N/A | unit | `mix test test/accrue/dunning/engine_test.exs` | ❌ Wave 0 | ⬜ pending |
| TBD | TBD | 0 | DUN-03 SC#1 | — | N/A | integration | `mix test test/accrue/webhook/default_handler_test.exs -k "dunning engine"` | ❌ Wave 0 | ⬜ pending |
| TBD | TBD | 0 | DUN-03 SC#2 | — | N/A | unit | `mix test test/accrue/integrations/chimeway_test.exs` | ❌ Wave 0 | ⬜ pending |
| TBD | TBD | 1 | DUN-03 SC#3 | — | N/A | integration | `mix test test/accrue/webhook/default_handler_test.exs -k "dunning"` | ✅ (Phase 130) | ⬜ pending |
| TBD | TBD | 1 | DUN-03 SC#4 | — | N/A | manual | Docs review | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/dunning/engine_test.exs` — covers DUN-03 SC#1 (behaviour contract + Engine.Oban impl)
- [ ] `accrue/test/accrue/integrations/chimeway_test.exs` — covers DUN-03 SC#2 (conditional compile; clone of sigra_test.exs)
- [ ] `accrue/test/accrue/dunning/engine/oban_test.exs` — covers Engine.Oban start_campaign/cancel_campaign with Mox stubs for DunningStep/Oban

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `iso_anchor` is always a binary produced by `DateTime.to_iso8601/1` (Accrue-owned); `tenant_id` / `actor_id` are binaries validated by Chimeway's trigger before use |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Duplicate Chimeway trigger from concurrent webhooks | Spoofing | `idempotency_key: "accrue.dunning:" <> sub.id <> ":" <> iso_anchor` — stable, unique per campaign |
| Stale `Signal.track` cancelling a fresh re-lapse campaign | Tampering | iso_anchor is campaign-specific; recovered + re-lapsed sub has a NEW anchor |
| Signal routing cross-tenant | Tampering | `Signal.track(tenant_id=sub.customer_id, ...)` scoped to the customer's tenant |
| Sensitive fields logged via Chimeway telemetry | Information Disclosure | The params map contains no secrets (`subscription_id`, `customer_id`, `anchor` only) |
