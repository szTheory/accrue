# Entitlement-Source Capability Matrix

**Runtime authority:** `Accrue.Entitlements.Source.Registry`; the ordered JSON conformance corpus is `accrue/priv/entitlements/v1.59-source-capabilities.json`.
**Separate gateway authority:** `.planning/processor-support-matrix.md` owns processor control. Do not infer source capability from `Accrue.Processor`.

## Closed vocabulary

- Capability order: `observation`, `control`, `restore`, `reconciliation`, `management`, `offline`.
- State vocabulary: `supported`, `externally_managed`, `host_owned`, `deferred`, `unavailable`, `feasibility_blocked`.

States are code vocabulary, not user-facing colors or status labels. Equal and adjacent states remain distinct.

## Verified source contract

| Source | Capability | State | Host next action |
| --- | --- | --- | --- |
| Stripe | all six ordered capabilities | supported | Review the source contract. |
| Apple | observation, restore, reconciliation | supported | Review verified Apple evidence. |
| Apple | control | unavailable | Manage in Apple; no Stripe cancellation, dunning, retry, swap, proration, invoice, or payment-method mutation is available. |
| Apple | management | externally_managed | Use **Manage subscription** at `https://apps.apple.com/account/subscriptions`. |
| Apple | offline | feasibility_blocked | Review the later Apple feasibility proof. |
| Host/Fake proof | management | host_owned | Review host configuration. |
| Host/Fake proof | remaining ordered capabilities | supported | Review the source contract. |

`deferred` remains a closed state for later rail contracts; it is not silently coalesced with `unavailable` or `feasibility_blocked`.
