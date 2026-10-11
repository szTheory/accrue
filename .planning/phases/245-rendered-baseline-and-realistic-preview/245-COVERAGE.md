---
phase: 245
plan: 03
status: evidence-ledger
---

# Phase 245 route and state coverage

The host imports `AccrueAdmin.Router` and mounts it at `/admin`. The package currently exposes **21 production LiveView templates**, matching the Phase 240/239 historical 21-route inventory: 19 main routes plus two analytics routes. No production route was added, removed, or renamed. Five conditional `/admin/dev/*` LiveViews are declared by the package but are not activated by this host mount (`allow_live_reload: false`); direct requests returned 404 and are listed separately from the production inventory. Redirects (`/charges`, `/charges/:id`) and hashed assets/fonts are mounted support endpoints, not operator LiveViews.

Coverage records are deterministically sorted by route then state ID. `inspected` means a current authenticated browser visit and, for screenshots, a retained manifest reference. State rows that the current ordinary stack cannot support are explicit gaps; source tests are not rendered inspection. Recovery readiness is measured from the rendered at-risk table and supporting-funnel state markers after a bounded 15-second wait.

## Machine-readable route/state inventory

<!-- coverage-json:start -->
{
  "prior_route_count": 21,
  "route_reconciliation": {
    "unchanged": 21,
    "added": 0,
    "removed": 0,
    "renamed": 0
  },
  "routes": [
    {
      "route": "/admin",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/customers",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/customers/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/subscriptions",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/subscriptions/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/invoices",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/invoices/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/payments",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/payments/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/coupons",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/coupons/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/promotion-codes",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/promotion-codes/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/connect",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/connect/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/events",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/events/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/webhooks",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/webhooks/:id",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/analytics/recovery",
      "kind": "production-liveview"
    },
    {
      "route": "/admin/analytics/recovery/subscriptions/:id",
      "kind": "production-liveview"
    }
  ],
  "supplemental_routes": [
    {
      "route": "/admin/dev/clock",
      "kind": "conditional-development-liveview",
      "activation": "allow_live_reload: false in the ordinary host; direct request is recorded in route rows"
    },
    {
      "route": "/admin/dev/email-preview",
      "kind": "conditional-development-liveview",
      "activation": "allow_live_reload: false in the ordinary host; direct request is recorded in route rows"
    },
    {
      "route": "/admin/dev/webhook-fixtures",
      "kind": "conditional-development-liveview",
      "activation": "allow_live_reload: false in the ordinary host; direct request is recorded in route rows"
    },
    {
      "route": "/admin/dev/components",
      "kind": "conditional-development-liveview",
      "activation": "allow_live_reload: false in the ordinary host; direct request is recorded in route rows"
    },
    {
      "route": "/admin/dev/fake-inspect",
      "kind": "conditional-development-liveview",
      "activation": "allow_live_reload: false in the ordinary host; direct request is recorded in route rows"
    },
    {
      "route": "/charges",
      "kind": "redirect-support",
      "reason": "legacy billing redirect, not a LiveView"
    },
    {
      "route": "/charges/:id",
      "kind": "redirect-support",
      "reason": "legacy billing detail redirect, not a LiveView"
    },
    {
      "route": "/admin/assets/*",
      "kind": "static-asset-support",
      "reason": "hashed CSS/JS/font assets are verified through served asset identity, not operator routes"
    }
  ],
  "rows": [
    {
      "id": "R01-populated",
      "route": "/admin",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin",
      "visual_anchor": "Admin shell plus dashboard metric and recent activity composition",
      "status": "inspected",
      "evidence": "manifest capture C01; PNG SHA-256 f3e27ea438ff9fb6eaf0366cdc3743f6d5520da84a418849d816d367cf8edfa1"
    },
    {
      "id": "R20-populated",
      "route": "/admin/analytics/recovery",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/analytics/recovery",
      "visual_anchor": "Admin shell plus analytics metric/work queue composition",
      "status": "inspected",
      "evidence": "manifest capture C18; PNG SHA-256 d751100ba151067c7221576e1382a843752d57763f5c831054511881938da5a1"
    },
    {
      "id": "R21-populated",
      "route": "/admin/analytics/recovery/subscriptions/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/analytics/recovery/subscriptions/00e4fb01-4a12-4910-ba50-de7e03d3e248",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C19; PNG SHA-256 bb5ec177a107208c7cdf9efbdbef3869781e4ee972ec62e3bde9380922b0e236"
    },
    {
      "id": "R14-populated",
      "route": "/admin/connect",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/connect",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C14; PNG SHA-256 d85bce5413fa06deb86988c6f313415b2c5c2e22ff3d5faf4dee237d6e3d0a49"
    },
    {
      "id": "R15-populated",
      "route": "/admin/connect/:id",
      "state": "populated",
      "url": null,
      "visual_anchor": "Admin shell and route-owned content",
      "status": "unavailable",
      "reason": "No ordinary Fake connect accounts row exists, so a detail URL cannot be formed; the collection route was still visited."
    },
    {
      "id": "R10-populated",
      "route": "/admin/coupons",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/coupons",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C10; PNG SHA-256 0d97cc627691f2c0e84c995b89e418717607b0f2167433ac14af09668c8f9f07"
    },
    {
      "id": "R11-populated",
      "route": "/admin/coupons/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/coupons/907119e2-4a62-4b2f-a9c4-7586d3c889d5",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C11; PNG SHA-256 f4ba4fb7b8de53b2133b5dfe4153fd74c71c95f0e913061fba68ea94e36f8914"
    },
    {
      "id": "R02-populated",
      "route": "/admin/customers",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C02; PNG SHA-256 1e41180a6354690f198e8b0515a67358fc36c165535fa78afe911760f4708dc9"
    },
    {
      "id": "R03-populated",
      "route": "/admin/customers/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers/028e6898-ca99-47c0-a011-f67f60a655c2",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C03; PNG SHA-256 73d0997d644e1da8f28ceaddabdd5a6d55fbed892a184ed3605a51081439651b"
    },
    {
      "id": "DEV-01-not-mounted",
      "route": "/admin/dev/clock",
      "state": "not-mounted",
      "url": "/admin/dev/clock",
      "visual_anchor": "Development route activation under the host mount",
      "status": "not-applicable",
      "reason": "Direct navigation returned HTTP 404; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance."
    },
    {
      "id": "DEV-04-not-mounted",
      "route": "/admin/dev/components",
      "state": "not-mounted",
      "url": "/admin/dev/components",
      "visual_anchor": "Development route activation under the host mount",
      "status": "not-applicable",
      "reason": "Direct navigation returned HTTP 404; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance."
    },
    {
      "id": "DEV-02-not-mounted",
      "route": "/admin/dev/email-preview",
      "state": "not-mounted",
      "url": "/admin/dev/email-preview",
      "visual_anchor": "Development route activation under the host mount",
      "status": "not-applicable",
      "reason": "Direct navigation returned HTTP 404; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance."
    },
    {
      "id": "DEV-05-not-mounted",
      "route": "/admin/dev/fake-inspect",
      "state": "not-mounted",
      "url": "/admin/dev/fake-inspect",
      "visual_anchor": "Development route activation under the host mount",
      "status": "not-applicable",
      "reason": "Direct navigation returned HTTP 404; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance."
    },
    {
      "id": "DEV-03-not-mounted",
      "route": "/admin/dev/webhook-fixtures",
      "state": "not-mounted",
      "url": "/admin/dev/webhook-fixtures",
      "visual_anchor": "Development route activation under the host mount",
      "status": "not-applicable",
      "reason": "Direct navigation returned HTTP 404; the host mount has allow_live_reload: false, so this package development route is not active in the ordinary instance."
    },
    {
      "id": "R16-populated",
      "route": "/admin/events",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/events",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C15; PNG SHA-256 f2e15913e7a0fe175a1dc26d73ef61676ba1f71f6a8d65a7384e2b5385cc6f07"
    },
    {
      "id": "R17-populated",
      "route": "/admin/events/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/events/1",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C16; PNG SHA-256 2cf65173adeb3092590525a890572397fc47d03e592aff5d0c40b50b1b0edf76"
    },
    {
      "id": "R06-populated",
      "route": "/admin/invoices",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/invoices?view=all",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C06; PNG SHA-256 17276a8bbb74cae9c191b4878389d9630ade50b56536c11ba813711b23dacd84"
    },
    {
      "id": "R07-populated",
      "route": "/admin/invoices/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/invoices/05f639e3-4b31-4ee7-a226-b249e2122a66",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C07; PNG SHA-256 6463c3956d72c8d7723001ad6b81fbde85fef5a7f8922e4b985f3e3faa80f681"
    },
    {
      "id": "R08-populated",
      "route": "/admin/payments",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/payments",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C08; PNG SHA-256 8952eed301c404f02f7cbd54639ab8d0b6e2ecc79bdcba3b2c584f8d2e05d5d5"
    },
    {
      "id": "R09-populated",
      "route": "/admin/payments/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/payments/07fce207-1342-479e-a64b-946f1d937854",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C09; PNG SHA-256 456d5238ebef9c245797e47c02c26c34af286c20a7c082b707fe458bb21648d6"
    },
    {
      "id": "R12-populated",
      "route": "/admin/promotion-codes",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/promotion-codes",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C12; PNG SHA-256 f9b9a67a7ee217fbe8ad4d3ac4be38e901e903adf741ec557b9ae0f11b130fea"
    },
    {
      "id": "R13-populated",
      "route": "/admin/promotion-codes/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/promotion-codes/3bb400f1-b8a6-4182-9890-37fcfdd60a4f",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C13; PNG SHA-256 fd62640a884615e5513edeb9db16f0580222a895d3def093b0b4ebac7c8b7f57"
    },
    {
      "id": "R04-populated",
      "route": "/admin/subscriptions",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/subscriptions",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C04; PNG SHA-256 9dda7a107e54bf82159af7d7b0274e03a2ecc5697e5849a7920a810f9b093b46"
    },
    {
      "id": "R05-populated",
      "route": "/admin/subscriptions/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/subscriptions/00e4fb01-4a12-4910-ba50-de7e03d3e248",
      "visual_anchor": "Admin shell plus record detail and history",
      "status": "inspected",
      "evidence": "manifest capture C05; PNG SHA-256 5abb4516f47788cc2b5e44326bef1c3be894c452829aa745d737faa556a3b12d"
    },
    {
      "id": "R18-populated",
      "route": "/admin/webhooks",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/webhooks",
      "visual_anchor": "Admin shell plus route-owned collection table",
      "status": "inspected",
      "evidence": "manifest capture C17; PNG SHA-256 7e51a06ebc306eeb994ba59c137333ac65d94a382760d86f8680007e1fff9c43"
    },
    {
      "id": "R19-populated",
      "route": "/admin/webhooks/:id",
      "state": "populated",
      "url": null,
      "visual_anchor": "Admin shell and route-owned content",
      "status": "unavailable",
      "reason": "No ordinary Fake webhook events row exists, so a detail URL cannot be formed; the collection route was still visited."
    }
  ],
  "state_matrix": [
    {
      "id": "LST-EMPTY",
      "applies_to": "all collection routes",
      "state": "truly-empty",
      "status": "unavailable",
      "reason": "The ordinary fixture is intentionally populated; emptying protected data is outside the read-only capture scope."
    },
    {
      "id": "LST-FILTER-ZERO",
      "applies_to": "all collection routes with filters",
      "state": "filtered-to-zero",
      "status": "unavailable",
      "reason": "A stable guaranteed-zero filter was not available across every collection; no route is marked empty based on source or guesswork."
    },
    {
      "id": "LST-PARTIAL",
      "applies_to": "billing lists and details",
      "state": "partial-or-unknown",
      "status": "inspected",
      "reason": "Ordinary Fake records preserve absent provider history and nil relationships; the exact evidence and route captures are listed per route."
    },
    {
      "id": "LST-ONE-MANY",
      "applies_to": "collection and detail related-record sections",
      "state": "one-and-many",
      "status": "unavailable",
      "reason": "Counts are recorded only where visibly rendered; no extra records were seeded to force cardinality variants."
    },
    {
      "id": "LST-OVERFLOW",
      "applies_to": "tables and long-text detail fields",
      "state": "overflow-long-text",
      "status": "unavailable",
      "reason": "No ordinary fixture was added for adversarial text; Phase 191 edge_states owns this scenario."
    },
    {
      "id": "ASYNC-LOADING-ERROR",
      "applies_to": "recovery analytics",
      "state": "loading-or-error",
      "status": "inspected",
      "reason": "Recovery loading state is checked against source-backed ready indicators with a bounded 15-second wait and recorded in R20."
    },
    {
      "id": "INTERACTION-KEYBOARD",
      "applies_to": "navigation, filters, disclosures, tabs",
      "state": "keyboard-focus-selection",
      "status": "unavailable",
      "reason": "This batch captures rendered states; it does not infer keyboard/focus behavior from PNGs."
    },
    {
      "id": "INTERACTION-POINTER-TOUCH",
      "applies_to": "hover and touch targets",
      "state": "hover-pointer-touch",
      "status": "unavailable",
      "reason": "No pointer-hover or physical touch outcome was exercised; viewport emulation is not touch evidence."
    },
    {
      "id": "INTERACTION-URL",
      "applies_to": "query filters, tabs, and selected rows",
      "state": "URL-result-alignment",
      "status": "unavailable",
      "reason": "The test preserves the explicit invoices view=all route but does not claim systematic URL/result alignment for every control."
    },
    {
      "id": "DETAIL-DISCLOSURE",
      "applies_to": "record details",
      "state": "disclosure-tabs-and-history",
      "status": "unavailable",
      "reason": "Collapsed disclosure/tab variants were not expanded across every detail route in this bounded visual inventory."
    }
  ],
  "omitted_combinations": [
    "All-theme x all-viewport x all-route combinations; four representative theme/viewport cells were captured across distinct compositions instead of a Cartesian matrix.",
    "Empty, filtered-to-zero, overflow and adversarial long-text states, because no safe ordinary scenario supported them without reseeding or protected-data mutation.",
    "Full role/scope permutations; the exact authenticated ordinary operator session was retained and no authorization boundary was bypassed.",
    "Systematic keyboard, focus, hover, pointer, touch, selected URL/query and action-result behavior; screenshots do not prove interaction outcomes.",
    "Connect and webhook details in the ordinary instance: their collection routes were visited, but no ordinary rows yielded IDs; separate Phase243 read-only observations are recorded in findings, not represented as ordinary PNG captures."
  ]
}
<!-- coverage-json:end -->

## State coverage notes

The mounted template row is not a claim that every applicable UI state was exercised. The bounded state matrix records a populated row for each reachable production route and the following shared gaps:

| State family | Status | Evidence / reason |
|---|---|---|
| Filtered-to-zero | unavailable | No stable filter scenario was identified that is guaranteed to return zero without changing the ordinary fixture; not inferred from empty source tests. |
| Truly empty | unavailable | Existing ordinary preview tables are populated; destructive data changes are outside this plan. |
| Partial / unknown billing facts | inspected where visible | Existing ordinary invoice/payment rows retain missing provider events and nil relationships as recorded in `245-ORDINARY-STORIES.md`; screenshot-specific findings name the exact route. |
| Loading / application error | partially inspected | Recovery was observed after its 15-second bounded readiness wait; the final PNG and manifest note show `no-pagination` and funnel `ready`. A stable error fixture was not available. |
| Zero / one / many | partial | The current populated ordinary collections and recovery at-risk table are inspected as rendered; alternate forced cardinalities are not claimed without matching fixture evidence. Connect is actually empty in this ordinary instance; its screenshot is not confused with filtered-to-zero. |
| Overflow / adversarial long text | unavailable | Long-name and Unicode stress records remain owned by Phase 191 / `edge_states`; they are excluded from ordinary preview captures. |
| Hover / keyboard / touch | partial | Only behavior specifically listed in a capture observation is claimed; no screenshot is treated as behavioral proof. |

The supplemental `state_matrix` records empty, filtered-zero, partial/unknown, cardinality, overflow, asynchronous, disclosure, URL-result and input-method coverage in machine-readable form. Missing overlay, tab, role/scope and interaction states remain explicit rather than inferred from the default page capture.

## Evidence boundaries

The owner screenshots in `2026-10-11-admin-owner-feedback.md` are defect references only. Generated PNGs below are the current ordinary Fake instance. Fixture-local statuses without matching processor history remain local seed facts; no attempt or settlement outcome is inferred. Missing record identifiers are unavailable evidence, not a pass. No production UI changes are made in this plan.
