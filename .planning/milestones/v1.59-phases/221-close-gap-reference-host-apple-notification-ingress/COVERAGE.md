# API Coverage — Apple App Store Server Notifications V2 / App Store Server API

> Full coverage by default. Opt-outs are explicit, reasoned decisions. This matrix covers the external Apple surface touched by Phase 221; existing Accrue capabilities are integrated through the reference host rather than reimplemented.

| capability | decision | reason |
|---|---|---|
| Notifications V2 HTTPS ingress at `/webhooks/apple` | INTEGRATE | |
| Exact raw-body capture and 262,144-byte admission boundary | INTEGRATE | |
| Production JWS trust-chain, bundle, environment, and app-identity verification | INTEGRATE | |
| Durable verified intake, duplicate convergence, and bounded terminal quarantine | INTEGRATE | |
| Reconciliation wakeup plus subscription-status and transaction-history repair | INTEGRATE | |
| Host-owned App Store Server API production client configuration | INTEGRATE | |
| App Store `Request a Test Notification` and status lookup | OPT-OUT | Advisory deployed-endpoint evidence only; deterministic Fake-backed router proof remains the merge authority per D-12. |
| Notifications V1 compatibility | OPT-OUT | Apple deprecates V1 and the locked phase boundary is V2-only. |
| Mixed production/sandbox notification endpoint | OPT-OUT | D-05 requires an environment-specific production endpoint; a sandbox endpoint requires independent configuration and proof. |
| Notification-history API polling | OPT-OUT | Existing repair uses subscription status and ascending transaction history; adding another provider history path is outside this ingress gap. |
| Set App Account Token API mutation | OPT-OUT | Ownership binding remains verified and host-directed; Phase 221 does not add provider mutation or ownership reassignment. |
| Consumption/refund/renewal-extension mutations | OPT-OUT | Finance and Apple lifecycle mutations are explicitly outside this ingress/repair phase. |
| Offer-code and promotional-offer authoring | OPT-OUT | Offer authoring is outside the locked v1.59 Apple contract. |
| Family Sharing management | OPT-OUT | Family Sharing remains deferred by the existing Apple capability contract. |
