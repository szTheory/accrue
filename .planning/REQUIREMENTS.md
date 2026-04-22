# Requirements: Accrue v1.9

**Defined:** 2026-04-21  
**Core value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through at least the first major version.

## v1.9 Requirements — Observability & operator runbooks

### Telemetry catalog & truth

- [x] **OBS-01**: Developer can use `guides/telemetry.md` as an authoritative **catalog** of every `[:accrue, :ops, :*]` event emitted by `accrue`, including Connect, PDF-mailer fallback, and ledger upcast failures, with measurements and metadata columns aligned to code.
- [x] **OBS-03**: Developer can read a concise description of the **firehose** namespace (`Accrue.Telemetry.span/3`, `[:accrue, :billing, …]`, ancillary webhook/mail events) and when to subscribe for diagnostics vs paging.
- [x] **OBS-04**: Maintainer can reconcile `guides/telemetry.md` with `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md` such that **no ops event** listed in the audit’s §1 remains undocumented (or is explicitly marked removed with PR reference).

### Host wiring & metrics

- [x] **OBS-02**: Developer can copy a **cross-domain** example from Accrue docs (e.g. host `Telemetry` handler or snippet) showing how a non-billing Phoenix context attaches to **ops** or **billing** telemetry without importing private modules.
- [x] **TEL-01**: Developer using `Accrue.Telemetry.Metrics.defaults/0` gets counters (or documented intentional omissions) for **every** ops event in **OBS-01**, per gap closure in the v1.9 audit §2 — or the guide states why a given ops signal is host-only metric with a pattern to add locally.

### Operator runbooks

- [ ] **RUN-01**: Operator can follow an Accrue-maintained **runbook** section (in `guides/telemetry.md` or a linked guide) that maps high-signal ops events (DLQ dead-letter, meter reporting failure, dunning exhaustion, revenue loss, charge failed, incomplete expired, Connect deauth / payout failed) to **first actions** (replay, check Oban, verify Stripe dashboard, customer comms) without duplicating Stripe’s accounting UI.

## v2 / later (not in v1.9 roadmap)

- **Metered billing milestone (v1.10+)** — see `.planning/research/v1.10-METERING-SPIKE.md` for API/Fake parity acceptance outline.

## Out of scope

| Item | Reason |
|------|--------|
| **PROC-08** — Official second processor adapter | Explicit non-goal until a milestone reprioritizes with narrow adapter scope; avoids false parity. |
| **FIN-03** — App-owned finance exports | Wrong-audience export risk; requires host governance design before any implementation. |
| Pixel parity with Stripe Dashboard reporting | Stripe-native surfaces remain source of truth for finance ops. |
| New billing domain primitives (subscriptions, tax, org rows) | v1.9 is observability + runbooks only. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OBS-01 | Phase 40 | Complete |
| OBS-03 | Phase 40 | Complete |
| OBS-04 | Phase 40 | Complete |
| OBS-02 | Phase 41 | Complete |
| TEL-01 | Phase 41 | Complete |
| RUN-01 | Phase 42 | Pending |

**Coverage:** v1.9 requirements: **6** total · Mapped: **6** · Unmapped: **0**

---
*Requirements defined: 2026-04-21 after post–v1.8 prioritization plan*
