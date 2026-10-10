# Phase 242 — Planning Probe Coverage

**Date:** 2026-10-10. Planning predicates only; no product runtime evidence.

## Edge Coverage

No phase SPEC exists. The owning spec-section helper reported edges/prohibitions supplied:false at the expected nonexistent SPEC path. Default-on spec-less fallback ran the compiled edge probe on all four canonical requirement texts. Initial prose classified three as unclassified; delegated author review enumerated the actual collection/text/stateful/IO/numeric boundaries from D01–21 and the current source. The corrected shape overrides produce **28 explicit resolved predicates; zero backstop/unresolved/unclassified**. Every row must be lifted into PLAN must_haves; no silent drops.

| Item | Status | Verification | Acceptance criterion |
|---|---|---|---|
| JRN-05/boundary | resolved | explicit | Supported return/filter limits and delivery selection zero/one/many preserve actual decoder membership; invalid/oversize/duplicate return values use the safe current-owner family fallback. |
| JRN-05/adjacency | resolved | explicit | Distinct event, source delivery and replay job IDs remain distinct; repeated selected IDs do not dispatch twice and a missing or foreign relation never links an unrelated record. |
| JRN-05/empty | resolved | explicit | Empty, no-match, unavailable detail/list and absent attempt evidence render distinct states; zero selected deliveries cannot confirm replay. |
| JRN-05/encoding | resolved | explicit | Returns round-trip supported UTF-8 search/filter values through the destination decoder; malformed percent/duplicate keys fail closed and exact processor/event IDs remain unchanged. |
| JRN-05/ordering | resolved | explicit | Captured selected delivery identities and displayed replay result counts agree through confirm; changed selection cannot silently substitute another set; existing list ordering remains unchanged. |
| JRN-05/precision | resolved | explicit | Selected/eligible/queued/skipped/denied/failed/unknown counts use exact actual per-record outcomes and sum to their reported population without interpreting accepted as processed. |
| JRN-05/idempotency | resolved | explicit | Repeated replay confirmation, dismissal, denied step-up and duplicate queue attempts preserve existing dispatch/job/audit protections; authoritative observations distinguish no action from accepted enqueue. |
| JRN-05/concurrency | resolved | explicit | Fresh owner/actor/eligibility/material state is checked at dispatch; pre-dispatch read failure differs from post-acceptance reread failure and neither invites blind duplicate replay. |
| JRN-06/boundary | resolved | explicit | Coupon validity/redemption bounds and Connect fee inputs use existing supported semantics at zero/boundaries/invalid precision; unknown restrictions or provider observations never become unrestricted/ready. |
| JRN-06/adjacency | resolved | explicit | Promotion code identity differs from its exact coupon parent; missing/foreign parent does not select another coupon; local fee policy differs from provider capability facts. |
| JRN-06/empty | resolved | explicit | Zero/no-match/unavailable catalog/Connect and absent parent/limit/snapshot/default/override have truthful distinct states with no invented provider freshness or healthy result. |
| JRN-06/encoding | resolved | explicit | Supported coupon/code/Connect filters round-trip decoder/encoder meanings with validated family labels; exact provider IDs and decimal input semantics are preserved. |
| JRN-06/ordering | resolved | explicit | Coupon→code→exact parent/source navigation preserves authorized relationship identity and supported return constraints; facts precede local action and diagnostic disclosure. |
| JRN-06/precision | resolved | explicit | Fee review proposal, domain preview and persisted policy agree exactly under incumbent money/percent/min/max validation; presentation does not implement independent rounding. |
| JRN-06/idempotency | resolved | explicit | Repeated fee confirmation or dismissal cannot duplicate/change persisted policy under existing protection; successful save is distinct from cancelled/denied/invalid action. |
| JRN-06/concurrency | resolved | explicit | Fresh account/owner/actor/current policy is checked at save and material drift invalidates review; a local override never implies a changed Stripe readiness observation. |
| JRN-07/boundary | resolved | explicit | Each of Customers/Invoices/Subscriptions remains bounded at five results; zero/end/wrap navigation stays within the current mounted item set and real scoped destinations. |
| JRN-07/adjacency | resolved | explicit | Equal visible names across groups retain distinct record IDs and destinations; pointer/Arrow/Enter agree on one active item rather than a same-named different record. |
| JRN-07/empty | resolved | explicit | Empty query shortcuts, loading, no match and partial/unavailable group are distinct; no current items means Enter dispatches no navigation/action. |
| JRN-07/encoding | resolved | explicit | Supported search query and record identity preserve current normalization; scoped real result links cannot inherit a previous owner after query/scope replacement. |
| JRN-07/ordering | resolved | explicit | Pointer movement and Arrow navigation change the same authoritative active item; result replacement preserves it only when still valid in the same context, otherwise applies the specified deterministic fallback. |
| JRN-07/precision | resolved | explicit | Result count/group limits and active index stay integer/bounded; an absent item cannot become an out-of-range Enter target. |
| JRN-07/idempotency | resolved | explicit | Repeated open/close, hook updated/destroyed and query completion leave one current listener/selection lifecycle and restore focus without duplicate navigation. |
| JRN-07/concurrency | resolved | explicit | Delayed prior query/generation/owner cannot replace current results; successful groups survive partial failure; Enter activates the current visibly/accessibly active link after LiveView replacement. |
| UXC-01/adjacency | resolved | explicit | Routine payment vs diagnostic Charge, billing event vs delivery and review dismissal vs domain cancellation remain distinct in the actual rendered contexts. |
| UXC-01/empty | resolved | explicit | Unknown/missing/zero values use the correct resource-specific Copy states without claiming unrestricted/healthy/complete; first-run differs from filtered no-match. |
| UXC-01/encoding | resolved | explicit | Exact diagnostic identifiers/raw enums/provider terms and Copy.Locked text remain verbatim; routine collection labels use incumbent human names rather than raw enum presentation. |
| UXC-01/ordering | resolved | explicit | Lists/details/filter chips/reviews use the same incumbent Copy vocabulary and resource-first hierarchy; diagnostics remain available without replacing routine task labels. |

## Authored Edge Inputs

```json
[
  {
    "id": "JRN-05",
    "text": "Operators can trace existing events and webhook deliveries through related evidence and supported replay review without hiding material failures, uncertainty or exact diagnostic detail.",
    "shapes": [
      "collection",
      "text",
      "stateful",
      "io",
      "numeric-range"
    ]
  },
  {
    "id": "JRN-06",
    "text": "Operators can inspect existing discounts, promotion-code relationships and Connect facts with supported actions and explicit stored-provider versus local-policy boundaries.",
    "shapes": [
      "collection",
      "text",
      "stateful",
      "io",
      "numeric-range"
    ]
  },
  {
    "id": "JRN-07",
    "text": "Operators can find the correct scoped record using the existing Home, navigation and search, with consistent visible selection across pointer and keyboard input.",
    "shapes": [
      "collection",
      "text",
      "stateful",
      "io",
      "numeric-range"
    ]
  },
  {
    "id": "UXC-01",
    "text": "Operators see coherent resource, collection-method and action language across lists, details, filters and reviews, while exact diagnostic terms and locked audit/legal meaning remain intact.",
    "shapes": [
      "collection",
      "text"
    ]
  }
]
```

## UI Probe Continuity

The compiled UI probe ran after independent seven-dimension approval. Six actual surfaces use explicit unioned kinds; 44 applicable items are resolved explicitly in 242-UI-SPEC.md. There are zero backstop/unresolved/unclassified items. Input below preserves author review rather than heuristic-only classification.

```json
[
  {
    "id": "E1",
    "text": "List: existing page heading/stat strip above the event table. Detail: event type in the existing summary card, followed by the event facts. | Label the append-only local billing event as an **event**. Keep actor, subject, exact type, source delivery, timestamp and material processing facts in the primary read path. Event \u2192 source delivery and subject links retain exact identity and authorized scope. Lazy Activity and Event payload disclosure remain discoverable; no absent activity or causal link is invented. Return labels name `Events` and restore only actual supported filter meanings.",
    "elements": [
      "list-collection",
      "nav",
      "interactive-control",
      "static-content"
    ]
  },
  {
    "id": "E2",
    "text": "List: existing page heading and delivery table. Detail: delivery identity/summary followed by attempt and dispatch lifecycle facts. Replay review: existing review surface headed by its exact target and consequence. | Use **webhook delivery/deliveries** for selection, row counts and review; processing attempts, resulting billing events and a queued replay are distinct observations. Keep material failure, uncertainty, eligibility and diagnostics visible without opening raw JSON. Existing inline single/bulk replay review names the exact delivery or selected delivery set, owner, current eligibility, consequence and locked audit wording. Selection or fresh scope/eligibility/material-state change cannot silently change the set. Dismissal returns without dispatch. Results say only what evidence establishes: queued/accepted, skipped/ineligible, denied, failed or unknown; acceptance is not processing success or payment. Do not invite blind retry after acceptance when reread fails.",
    "elements": [
      "list-collection",
      "form",
      "nav",
      "interactive-control",
      "static-content"
    ]
  },
  {
    "id": "E3",
    "text": "Lists: existing heading/stat strip and family-specific table. Details: existing record summary card and its exact coupon/code identity; keep the linked parent/child facts next in the read path. | Distinguish a discount definition (**coupon**) from the customer-facing **promotion code** referring to it. Show code identity, parent, validity/activity, expiry, redemption bounds and provider restrictions when known. Preserve relevant coupon \u2194 code relationships and exact parent identity. Missing/inaccessible parent is stated as unavailable and never linked to a plausible unrelated record; missing/unknown restriction is not described as unlimited. No catalog create/edit action is implied. Return labels identify the list family and retain only its validated active query/filter/parent constraint.",
    "elements": [
      "list-collection",
      "nav",
      "interactive-control",
      "static-content"
    ]
  },
  {
    "id": "E4",
    "text": "List: existing heading/stat strip and connected-account table. Detail: connected account identity in its existing summary card. Fee review: existing drawer title, account target and fee preview/policy facts. | Lead with connected account and owner identity. Readiness, capability and requirements are the last stored Stripe observation; preserve the current statement that the page does not track when Stripe last reported them. Do not imply a report timestamp, live readiness, or provider change. Keep local platform-fee policy explicitly separate. The existing review is self-contained: exact account/owner, current local policy, proposed override or default consequence, exact amount/percentage semantics, validation result and observation limits. Preserve fresh target/policy/actor checks, step-up, duplicate protection, correction, dismissal without save, associated errors and focus return.",
    "elements": [
      "list-collection",
      "form",
      "nav",
      "interactive-control",
      "static-content"
    ]
  },
  {
    "id": "E5",
    "text": "Home: existing page heading and current summary composition. Navigation: current selected owner and active destination in the existing sidebar. | Keep the current Home and familiar static navigation. Route, selected owner and visible destinations agree across Home, sidebar and breadcrumbs. Do not rebuild Home metrics or add navigation families.",
    "elements": [
      "nav",
      "static-content"
    ]
  },
  {
    "id": "E6",
    "text": "`AccrueAdmin.Components.GlobalSearch` | Existing bounded Customers, Invoices and Subscriptions groups only",
    "elements": [
      "form",
      "list-collection",
      "nav",
      "interactive-control",
      "static-content"
    ]
  }
]
```

## Prohibition Recall Handoff

The planner performed two-stage recall/precision below. The four initially retained candidates were rechecked against current locked decisions, explicit edge/UI rows and executable test owners. Each is routine, already specified behavior, so none needs an additional descriptor-less `must_haves.prohibitions` declaration. The corresponding negative assertions remain in task acceptance criteria and owning tests. Current-owner authorization and external-path injection remain with ScopedPath/domain auth and STRIDE. No bespoke intent prohibition remains without a machine-verifiable owner; no test result is claimed during planning.


## Planner Source and Probe Audit — execution pending

| Source | Covered items | Plan |
|---|---|---|
| GOAL | Existing investigation, catalog/Connect and scoped shell with coherent language | 242-01–07 |
| REQ | JRN-05, JRN-06, JRN-07, UXC-01 | 242-01–07 |
| RESEARCH | Five decoder/encoder families, relationship proof, DLQ outcome contract, Connect policy, async search, Copy and mounted evidence | 242-01–07 |
| CONTEXT | D-01–D-09 | 242-01–02 |
| CONTEXT | D-10–D-12 | 242-03–04 |
| CONTEXT | D-13–D-16 | 242-05–06 |
| CONTEXT | D-17–D-21 | 242-07 and owning tasks |

| Plan | Edge rows in must_haves.truths | UI rows in must_haves.truths |
|---|---|---|
| 242-01 | JRN-05/boundary, JRN-05/encoding | E1/empty, E1/loading, E1/error, E1/populated, E1/partial, E1/overflow, E1/zero-one-many, E1/long-text |
| 242-02 | JRN-05/adjacency, JRN-05/empty, JRN-05/ordering, JRN-05/precision, JRN-05/idempotency, JRN-05/concurrency | E2/empty, E2/loading, E2/error, E2/populated, E2/partial, E2/overflow, E2/zero-one-many, E2/long-text |
| 242-03 | JRN-06/boundary, JRN-06/adjacency, JRN-06/empty, JRN-06/encoding, JRN-06/ordering | E3/empty, E3/loading, E3/error, E3/populated, E3/partial, E3/overflow, E3/zero-one-many, E3/long-text |
| 242-04 | JRN-06/precision, JRN-06/idempotency, JRN-06/concurrency | E4/empty, E4/loading, E4/error, E4/populated, E4/partial, E4/overflow, E4/zero-one-many, E4/long-text |
| 242-05 | JRN-07/boundary, JRN-07/adjacency, JRN-07/empty, JRN-07/encoding, JRN-07/ordering, JRN-07/precision, JRN-07/idempotency, JRN-07/concurrency | E6/empty, E6/loading, E6/error, E6/populated, E6/partial, E6/overflow, E6/zero-one-many, E6/long-text |
| 242-06 | UXC-01/adjacency, UXC-01/empty, UXC-01/encoding, UXC-01/ordering | E5/loading, E5/error, E5/overflow, E5/long-text |
| 242-07 | — | — |

**No-silent-drop equality:** 28 explicit resolved edge rows = 28 plan truths + 0 flagged assumptions. 44 explicit resolved UI rows = 44 plan truths + 0 flagged assumptions. Deferred ideas and Phase 243 closure are excluded.

### Prohibition recall → precision

Adversarial recall asked of each requirement what it could silently become that the author would reject. The raw ten candidates per requirement are listed below. Precision checked each against D-01–21 and the 28 edge/44 UI predicates; all are already ordinary domain correctness, accessible interaction, Copy fidelity or authorization requirements with explicit executable owners. No extra descriptor-less prohibition is retained.

| Requirement | Ten recall candidates | Precision |
|---|---|---|
| JRN-05 | queued means processed; replay moves money; missing attempts mean healthy; failures hidden in JSON; dismiss dispatches; event counted as delivery; foreign subject link; ignored filter preserved; selected set changes; blind retry after acceptance | Drop extra descriptor: D-02/D-05 and JRN-05/precision/idempotency/concurrency already require these negatives; 242-02 T1/T2 acceptance and replay ExUnit assert them. Foreign scope stays with STRIDE/authorization. |
| JRN-06 | stored readiness called live; fee changes Stripe readiness; unknown restriction unlimited; wrong coupon parent; owner hidden; fee independently rounded; dismissal saves; invented report time; default silently changed; stale actor accepted | Drop extra descriptor: D-10/D-11/D-12 and JRN-06/boundary/precision/idempotency/concurrency explicitly govern these; 242-03/04 acceptance and LiveView/Copy tests assert them. |
| JRN-07 | previous-owner result selected; highlight differs from Enter; same-name wrong ID; extra result group; partial success lost; focus trapped; duplicate navigation; stale query promoted; long ID clipped; failed group called no-match | Drop extra descriptor: D-13/D-14/D-15 and JRN-07/adjacency/ordering/concurrency already specify exact selection and scope; 242-05 T1/T2 LiveComponent/Node and 242-07 mounted acceptance assert them. |
| UXC-01 | dismiss called domain cancellation; audit meaning obscured; raw enum as routine label; Charge diagnostic renamed; locked text rewritten; delivery called event; unknown called zero; provider meaning changed; blameful wording; money consequence hidden | Drop extra descriptor: D-16 and UXC-01/adjacency/empty/encoding/ordering govern routine labels and protected exact text; 242-06 T2 Copy/render assertions cover them. No source-backed blameful wording rule is minted. |

Canon referral: external-path injection and foreign-owner authorization remain with ScopedPath/domain auth and STRIDE. Routine engineering items remain in the 28 edge truths, 44 UI truths, locked decisions and owning test acceptance criteria. Four initially retained candidates were dropped after precision re-evaluation because they duplicate those requirements; zero bespoke projections remain, zero source behaviors were dismissed, and zero green enforcement or human confirmation is inferred. No descriptor-less resolved/test assertion remains to force a flagged-unverified/manual-proof loop.

Gate observations: api-coverage returned detected:false for this existing Admin refinement; no external API matrix. assumption-delta scan 242 returned detected:false. No ORM schema-pattern file or package install is planned. ASVS level 1/high blocking applies in every plan.
