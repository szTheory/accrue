# Phase 217 External API Coverage

External API integration is detected because Phase 217 changes the dispatch and safety contract around existing Stripe subscription commands. The phase does not add an SDK or provider; it integrates through Accrue's existing processor behaviour and Fake-first tests.

| capability | decision | reason |
|---|---|---|
| Stripe subscription creation after canonical preflight | INTEGRATE | Plan 217-03 implements the D-09/D-10 revision recheck, durable operation identity, and provider idempotency. |
| Stripe ambiguous-create reconciliation before retry | INTEGRATE | Plan 217-03 forbids blind retry and reconciles through the existing fetch/idempotency seam. |
| Stripe persisted-subscription lifecycle mutations | INTEGRATE | Plan 217-05 covers cancel, period-end cancel, resume, pause, unpause, swap, and quantity update through persisted provenance while retaining public facade signatures. |
| Stripe persisted-subscription invoice preview | INTEGRATE | Plan 217-05 routes the D-15 preview through the persisted subscription processor. |
| Stripe persisted-subscription item add, remove, and quantity update | INTEGRATE | Plan 217-05 derives the adapter from the persisted parent subscription. |
| Apple StoreKit purchase runtime | OPT-OUT | Phase 217 supplies required preflight only; StoreKit/Crosswake runtime integration is explicitly host/Phase-218 scope. |
| Apple subscription lifecycle mutation from Accrue | OPT-OUT | D-17/D-18 require successful `externally_managed` guidance and prohibit a gateway mutation adapter. |
| Apple evidence verification and transaction-history reconciliation | OPT-OUT | Explicit Phase 218 scope; Phase 217 consumes no unverified Apple evidence. |

Every detected Stripe capability is INTEGRATE. Each OPT-OUT is a locked ownership or later-phase boundary, not an omitted implementation.
