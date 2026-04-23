# Phase 16 — Expansion recommendation (checked-in artifact)

Contract file for **Accrue.Docs.ExpansionDiscoveryTest**. Captures ranked expansion bets
post–v1.2 discovery.

## Recommendation Rationale

Decisions weigh **user value**, **architecture impact**, **risk**, and **prerequisites**.
We stay **Stripe-first**, keep billing integration **host-owned**, allow a future
**custom processor** path only behind a clear boundary, and treat **Sigra** as the
reference org model while preserving **`owner_type`** / **`owner_id`** on billables.

## Ranked Recommendation

| Rank | Candidate | Disposition |
| ---- | --------- | ----------- |
| 1 | Stripe Tax support | Next milestone |
| 2 | Organization / multi-tenant billing | Backlog |
| 3 | Revenue recognition / exports | Backlog |
| 4 | Official second processor adapter | Planted seed |

## Migration Path Notes

Call out **recurring-item migration** and **customer location** work before enabling
automatic tax broadly.

## Assumptions Log

Stripe remains processor of record; hosts own export **delivery** channels.

## Open Questions

Timing for FIN-03 style **host-authorized export delivery** remains demand-driven.

## Security And Boundary Checks

Explicit milestone risks:

- **cross-tenant billing leakage**
- **wrong-audience finance exports**
- **tax rollout correctness**
- **processor-boundary downgrade** when adding adapters

Favor **separate-package** or host-owned adapter strategies for non-Stripe processors.

### Verification Runs

Point readers at CI **release-gate** and **host-integration** jobs plus local `mix verify`.

## Sign-Off

Maintainers acknowledge this ranking informed v1.3 planning; update when discovery reruns.
