# Phase 213 — LatticeStripe Entitlements API Coverage

**Scope:** the `LatticeStripe.Entitlements` 2.x capabilities relevant to a client-backed, observational refresh of a customer's active entitlements.

| Capability | Decision | Reason |
|---|---|---|
| `ActiveEntitlement.stream!/3` | INTEGRATE | `Accrue.Processor.Stripe.list_active_entitlements/2` drains the customer-filtered stream with `limit: "100"` so pagination is complete-or-error. |
| `ActiveEntitlement.list_path/0` | INTEGRATE | `Processor.Stripe` obtains the SDK-owned path and exposes it through the separate facade-safe `Processor.active_entitlement_list_metadata/0` contract. `StripeSync` passes `metadata.list_path` into `Reconcile`, including for an empty list, so neither domain module references raw `LatticeStripe` and the D-01 list callback keeps its exact `{:ok, [map()]}` result shape. |
| `ActiveEntitlement.from_map/1` and struct fields | INTEGRATE | The Stripe adapter consumes SDK structs and projects only the string-keyed webhook-compatible fields required by Accrue. |
| `ActiveEntitlement.list/3` and `list!/3` | OPT-OUT | One-page list calls can truncate; the exhaustive `stream!/3` path is the required refresh primitive. |
| `ActiveEntitlement.retrieve/3` and `retrieve!/3` | OPT-OUT | A single-entitlement lookup cannot reconcile the complete customer snapshot and would not close SYNC-01. |
| `ActiveEntitlementSummary.from_map/1` / summary data shape | INTEGRATE | Existing webhook summaries and the pull-reconstructed payload share this shape so material-change and diagnostic reads stay unified. |
| `ActiveEntitlementSummary.stream_entitlements!/3` | OPT-OUT | It requires a webhook-provided summary and does not provide the independent client-backed customer refresh required by SYNC-01. |
| `Feature.create/retrieve/update/list/stream/from_map` surface | OPT-OUT | Feature-catalog authoring and discovery are explicitly deferred; this phase reads active customer entitlements only. |

No relevant capability is undecided. Raw calls remain confined to `accrue/lib/accrue/processor/stripe.ex`.
