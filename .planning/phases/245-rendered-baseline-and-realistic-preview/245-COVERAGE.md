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
      "visual_anchor": "Visible route heading: Billing operations",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C01; PNG SHA-256 f3e27ea438ff9fb6eaf0366cdc3743f6d5520da84a418849d816d367cf8edfa1"
    },
    {
      "id": "R01-search-open",
      "route": "/admin",
      "state": "global-search-open",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin",
      "visual_anchor": "Global search dialog with scoped list suggestions; visible page heading: Billing operations",
      "status": "inspected",
      "evidence": "manifest capture C21; PNG SHA-256 279965ae1108628914e93388bfa1e74b34b5a5505e2a4287bdd4b05b5127d502; Control+K opened the modal dialog, exposed the scoped-list suggestions, and moved focus to its search input."
    },
    {
      "id": "R01-search-pointer-active",
      "route": "/admin",
      "state": "global-search-keyboard-and-pointer-active",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin",
      "visual_anchor": "Search result list with recorded keyboard and pointer selection indicators; visible page heading: Billing operations",
      "status": "inspected",
      "evidence": "manifest capture C22; PNG SHA-256 a4dc6a1cd6aac10770622be5a609007c7a05583850543c6725169aad7b7b5cb7; ArrowDown keyboard-active path=/admin/subscriptions/2dda99ea-cc04-4266-a61d-31808a8f5c75; after pointer hover target=/admin/customers/83df248a-b961-4f77-9b26-166b4bd03deb, hovered path=/admin/customers/83df248a-b961-4f77-9b26-166b4bd03deb, hovered has ax-active=true, active paths=[\"/admin/customers/83df248a-b961-4f77-9b26-166b4bd03deb\"], hover background=rgb(229, 235, 255). This records observed behavior without asserting the expected selection state."
    },
    {
      "id": "R20-populated",
      "route": "/admin/analytics/recovery",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/analytics/recovery",
      "visual_anchor": "Visible route heading: Revenue Recovery",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C18; PNG SHA-256 e06757a3afeda6c47e32234a665b0b0b54308a2bab0031578cd90aee81eea30b"
    },
    {
      "id": "R21-populated",
      "route": "/admin/analytics/recovery/subscriptions/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/analytics/recovery/subscriptions/00e4fb01-4a12-4910-ba50-de7e03d3e248",
      "visual_anchor": "Visible route heading: Dunning Timeline",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C19; PNG SHA-256 bb5ec177a107208c7cdf9efbdbef3869781e4ee972ec62e3bde9380922b0e236"
    },
    {
      "id": "R14-filtered-to-zero",
      "route": "/admin/connect",
      "state": "filtered-to-zero",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/connect",
      "visual_anchor": "Visible route heading: Finish account readiness",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C14; PNG SHA-256 d85bce5413fa06deb86988c6f313415b2c5c2e22ff3d5faf4dee237d6e3d0a49"
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
      "visual_anchor": "Visible route heading: Review usable discounts",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C10; PNG SHA-256 f87e2f0c3152e8b28d4e69b132ece521ef1e711f07a87f2c50eeb30d48a0d033"
    },
    {
      "id": "R11-populated",
      "route": "/admin/coupons/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/coupons/907119e2-4a62-4b2f-a9c4-7586d3c889d5",
      "visual_anchor": "Visible route heading: $10 Welcome Credit",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C11; PNG SHA-256 f5f5b1a1528a9239e2a2fdda95bfc8096341e179d1e3e16a9efdde7190763211"
    },
    {
      "id": "R02-filtered-zero",
      "route": "/admin/customers",
      "state": "filtered-to-zero",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers?q=phase245-no-results-7c92e34a",
      "visual_anchor": "Customer collection filtered-zero state and matching query; visible page heading: Find a customer",
      "status": "inspected",
      "evidence": "manifest capture C20; PNG SHA-256 565f516a7052e87b565427378452337524c63632ae5bc7ae23a6144e11e9c3be; A safe impossible q parameter remained in the final URL and rendered the explicit filtered-empty state with zero table rows."
    },
    {
      "id": "R02-populated",
      "route": "/admin/customers",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers",
      "visual_anchor": "Visible route heading: Find a customer",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C02; PNG SHA-256 2a9f842816fde330cbeceba788c117c506f93975da51b0a875c9e5b17376834d"
    },
    {
      "id": "R03-activity-disclosure-open",
      "route": "/admin/customers/:id",
      "state": "activity-disclosure-expanded",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers/83df248a-b961-4f77-9b26-166b4bd03deb?return_to=%2Fadmin%2Fcustomers&tab=invoices",
      "visual_anchor": "Customer detail with expanded Activity disclosure; visible page heading: Atelier Café",
      "status": "inspected",
      "evidence": "manifest capture C24; PNG SHA-256 ff578a12599f942f77cd6ffd2c419d776f1e72402e71812ea2cd8ea18d904cf2; Opening the Activity disclosure rendered its available timeline/empty evidence without a record mutation."
    },
    {
      "id": "R03-invoices-tab",
      "route": "/admin/customers/:id",
      "state": "peer-record-invoices-tab-selected",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers/83df248a-b961-4f77-9b26-166b4bd03deb?return_to=%2Fadmin%2Fcustomers&tab=invoices",
      "visual_anchor": "Customer detail with invoice peer-record tab selected; visible page heading: Atelier Café",
      "status": "inspected",
      "evidence": "manifest capture C23; PNG SHA-256 60b06eaab0e6bc7e61d26dd7e8711aee54595d3304ded2c17d4e6ed44966cfb9; Clicking the Invoices peer tab updated the URL to tab=invoices and set aria-current=page; the rendered peer-record panel reflects the selected tab."
    },
    {
      "id": "R03-populated",
      "route": "/admin/customers/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/customers/028e6898-ca99-47c0-a011-f67f60a655c2",
      "visual_anchor": "Visible route heading: Mohr-Donnelly",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C03; PNG SHA-256 73d0997d644e1da8f28ceaddabdd5a6d55fbed892a184ed3605a51081439651b"
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
      "visual_anchor": "Visible route heading: Trace billing activity",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C15; PNG SHA-256 f2e15913e7a0fe175a1dc26d73ef61676ba1f71f6a8d65a7384e2b5385cc6f07"
    },
    {
      "id": "R17-populated",
      "route": "/admin/events/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/events/1",
      "visual_anchor": "Visible route heading: Billing event",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C16; PNG SHA-256 2cf65173adeb3092590525a890572397fc47d03e592aff5d0c40b50b1b0edf76"
    },
    {
      "id": "R06-populated",
      "route": "/admin/invoices",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/invoices?view=all",
      "visual_anchor": "Visible route heading: Clear open receivables",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C06; PNG SHA-256 17276a8bbb74cae9c191b4878389d9630ade50b56536c11ba813711b23dacd84"
    },
    {
      "id": "R07-populated",
      "route": "/admin/invoices/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/invoices/05f639e3-4b31-4ee7-a226-b249e2122a66",
      "visual_anchor": "Visible route heading: DEMO-UNCOLL-0006",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C07; PNG SHA-256 6463c3956d72c8d7723001ad6b81fbde85fef5a7f8922e4b985f3e3faa80f681"
    },
    {
      "id": "R08-populated",
      "route": "/admin/payments",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/payments",
      "visual_anchor": "Visible route heading: Recover failed payments",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C08; PNG SHA-256 8952eed301c404f02f7cbd54639ab8d0b6e2ecc79bdcba3b2c584f8d2e05d5d5"
    },
    {
      "id": "R09-populated",
      "route": "/admin/payments/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/payments/07fce207-1342-479e-a64b-946f1d937854",
      "visual_anchor": "Visible route heading: ch_showcase_refunded",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C09; PNG SHA-256 456d5238ebef9c245797e47c02c26c34af286c20a7c082b707fe458bb21648d6"
    },
    {
      "id": "R12-populated",
      "route": "/admin/promotion-codes",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/promotion-codes",
      "visual_anchor": "Visible route heading: Find active codes",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C12; PNG SHA-256 f9b9a67a7ee217fbe8ad4d3ac4be38e901e903adf741ec557b9ae0f11b130fea"
    },
    {
      "id": "R13-populated",
      "route": "/admin/promotion-codes/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/promotion-codes/3bb400f1-b8a6-4182-9890-37fcfdd60a4f",
      "visual_anchor": "Visible route heading: WELCOME10",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C13; PNG SHA-256 fd62640a884615e5513edeb9db16f0580222a895d3def093b0b4ebac7c8b7f57"
    },
    {
      "id": "R04-populated",
      "route": "/admin/subscriptions",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/subscriptions",
      "visual_anchor": "Visible route heading: Subscriptions",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C04; PNG SHA-256 9dda7a107e54bf82159af7d7b0274e03a2ecc5697e5849a7920a810f9b093b46"
    },
    {
      "id": "R05-populated",
      "route": "/admin/subscriptions/:id",
      "state": "populated",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/subscriptions/00e4fb01-4a12-4910-ba50-de7e03d3e248",
      "visual_anchor": "Visible route heading: Flatley-McDermott",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C05; PNG SHA-256 5abb4516f47788cc2b5e44326bef1c3be894c452829aa745d737faa556a3b12d"
    },
    {
      "id": "R18-filtered-to-zero",
      "route": "/admin/webhooks",
      "state": "filtered-to-zero",
      "url": "http://accrue-host-phase245-ordinary.localhost/admin/webhooks",
      "visual_anchor": "Visible route heading: Replay failed deliveries",
      "status": "inspected",
      "evidence": "final URL matched requested template; main h1 rendered; manifest capture C17; PNG SHA-256 7e51a06ebc306eeb994ba59c137333ac65d94a382760d86f8680007e1fff9c43"
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
      "id": "LST-CONNECT-FILTERED-ZERO",
      "applies_to": "/admin/connect (default Needs attention view)",
      "state": "filtered-to-zero",
      "status": "inspected",
      "reason": "C14/R14-filtered-to-zero shows the selected Needs attention view, Accounts 0, and its no-matching-results copy. The All accounts alternative was not selected, so this does not prove a separately rendered unfiltered-empty state."
    },
    {
      "id": "LST-WEBHOOK-NEEDS-REPLAY-ZERO",
      "applies_to": "/admin/webhooks (default Needs replay view)",
      "state": "filtered-to-zero",
      "status": "inspected",
      "reason": "C17/R18-filtered-to-zero shows Received 0, Blocked 0, Replayed 0 and a Needs replay filtered-empty message. All deliveries was not selected; this is not evidence that delivery history globally does not exist."
    },
    {
      "id": "LST-CUSTOMERS-FILTER-ZERO",
      "applies_to": "/admin/customers?q=phase245-no-results-7c92e34a",
      "state": "filtered-to-zero",
      "status": "inspected",
      "reason": "C20/R02-filtered-zero retains the safe impossible q parameter and shows zero rows plus “No customers match these filters.”; other customer filters were not changed."
    },
    {
      "id": "LST-UNFILTERED-TRULY-EMPTY",
      "applies_to": "Connect and Webhooks All/unfiltered alternatives",
      "state": "truly-empty",
      "status": "unavailable",
      "reason": "The current Connect and Webhooks screenshots retain their Needs attention/Needs replay views. Although their visible totals are zero, the All accounts/All deliveries alternatives were not activated, so no unfiltered empty-state PNG is claimed."
    },
    {
      "id": "LST-PARTIAL",
      "applies_to": "/admin/invoices, /admin/invoices/:id, /admin/payments, /admin/payments/:id and linked detail evidence",
      "state": "partial-or-unknown",
      "status": "inspected",
      "reason": "Current ordinary captures preserve absent provider history and nil relationships in their displayed contexts; exact evidence is route-specific. No missing provider event is converted into a processor outcome."
    },
    {
      "id": "LST-ONE-MANY",
      "applies_to": "related-record sections on customer, subscription, invoice, payment and recovery detail routes",
      "state": "one-and-many",
      "status": "unavailable",
      "reason": "Visible current counts are retained in the route screenshots, but no safe fixture forces alternate one/many cardinalities for the same relationship; those variants remain uninspected."
    },
    {
      "id": "LST-OVERFLOW",
      "applies_to": "tables and long-text detail fields across production routes",
      "state": "overflow-long-text",
      "status": "unavailable",
      "reason": "No ordinary capture uses adversarial unbroken/oversized text. Phase 191 edge_states owns that stress fixture; ordinary story data was not polluted to force it."
    },
    {
      "id": "ASYNC-RECOVERY-READY",
      "applies_to": "/admin/analytics/recovery",
      "state": "ready-after-loading",
      "status": "inspected",
      "reason": "C18/R20 used source-backed readiness markers with a 15,000ms bounded wait; the captured table state is no-pagination and supporting funnel state is ready. A stable application-error state was not available."
    },
    {
      "id": "OVERLAY-GLOBAL-SEARCH",
      "applies_to": "/admin global search dialog",
      "state": "dialog-open-and-results",
      "status": "inspected",
      "reason": "C21/R01-search-open opened with Control+K, moved focus to #global-search-input, and shows the scoped Customers/Invoices/Subscriptions choices."
    },
    {
      "id": "INTERACTION-KEYBOARD",
      "applies_to": "global search shortcut and result navigation",
      "state": "keyboard-focus-selection",
      "status": "inspected",
      "reason": "C21 confirms Control+K focus in the dialog input; C22 records ArrowDown selecting a subscription result before pointer hover. Enter/activation and focus restoration after close were not tested."
    },
    {
      "id": "INTERACTION-POINTER",
      "applies_to": "global search result hover/selection",
      "state": "pointer-hover-selection",
      "status": "inspected",
      "reason": "C22 records pointer hover moving ax-active to the customer result, with one active path and a visible customer-row highlight in the PNG. The previously keyboard-selected subscription path was different; simultaneous highlighted rows were not seen in this captured after-state, and keyboard activation parity remains open."
    },
    {
      "id": "INTERACTION-TOUCH",
      "applies_to": "physical touch targets",
      "state": "touch-outcome",
      "status": "unavailable",
      "reason": "No physical touch device or touch interaction was used; viewport emulation is not touch evidence."
    },
    {
      "id": "INTERACTION-URL-CUSTOMER-TAB",
      "applies_to": "customer peer-record tabs",
      "state": "URL-result-alignment",
      "status": "inspected",
      "reason": "C23/R03-invoices-tab records clicking Invoices, URL tab=invoices, aria-current=page and the rendered zero-invoice content. Other customer tabs and filters were not audited."
    },
    {
      "id": "INTERACTION-URL-CUSTOMER-FILTER",
      "applies_to": "customer search query",
      "state": "URL-result-alignment",
      "status": "inspected",
      "reason": "C20/R02-filtered-zero retains q=phase245-no-results-7c92e34a and shows zero rows. Clear/reset and query preservation across other collections remain untested."
    },
    {
      "id": "INTERACTION-URL-OTHER-FILTERS",
      "applies_to": "non-customer collection filters and search",
      "state": "URL-result-alignment",
      "status": "unavailable",
      "reason": "Only the customer impossible-query transition was exercised; selection/query/count/row alignment and clear/remove scope on other collections remain unverified."
    },
    {
      "id": "DETAIL-CUSTOMER-ACTIVITY",
      "applies_to": "/admin/customers/:id Activity disclosure",
      "state": "disclosure-expanded-lazy-prompt",
      "status": "inspected",
      "reason": "C24/R03-activity-disclosure-open records clicking the disclosure and its open state. The PNG still shows “Open this section to load customer activity”; loaded timeline/empty history was not observed."
    },
    {
      "id": "DETAIL-OTHER-DISCLOSURES",
      "applies_to": "other record detail disclosure and tab states",
      "state": "disclosure-tabs-and-history",
      "status": "unavailable",
      "reason": "Only the customer Invoices tab and Activity disclosure were opened. Other record histories, raw payload controls, replay sections and disclosure/tab variants remain uninspected in Phase245 ordinary captures."
    }
  ],
  "omitted_combinations": [
    "All-theme x all-viewport x all-route combinations; four representative theme/viewport cells were captured across distinct compositions instead of a Cartesian matrix.",
    "Unfiltered truly-empty Connect and Webhooks views; their current screenshots show selected Needs attention/Needs replay filtered-zero states and the All alternatives were not activated.",
    "Full role/owner-scope permutations; the exact authenticated ordinary operator session was retained and no authorization boundary was bypassed.",
    "Systematic filter transitions/count/query alignment, keyboard activation, focus restoration, touch, clipboard outcomes, action results, and alternate detail disclosures; only the exact representative interactions listed in the state matrix were exercised.",
    "Connect and webhook details in the ordinary instance: their collection routes were visited, but no ordinary rows yielded IDs; separate Phase243 read-only observations are recorded in findings, not represented as ordinary PNG captures."
  ]
}
<!-- coverage-json:end -->

## State coverage notes

The mounted route inventory contains 21 production templates; the clean manifest contains 24 PNGs: one representative route image for each reachable route plus customer filtered-zero, global-search-open, keyboard/pointer-selection, customer Invoices-tab, and Activity-disclosure states. The matrix distinguishes selected filtered-zero screens from unfiltered empty collections. Connect and Webhooks show zero total counts while their Needs attention/Needs replay views are selected; their All alternatives were not activated, so no unfiltered-empty state is claimed. Customers has a separate impossible-query filtered-zero capture.

| State family | Status | Evidence / reason |
|---|---|---|
| Filtered-to-zero | inspected in three selected views | Customer impossible query (C20), Connect Needs attention (C14), and Webhooks Needs replay (C17). Only the customer query was explicitly made impossible; the Connect/Webhooks views are the selected defaults with visible zero counts. |
| Truly empty, unfiltered | unavailable | All accounts and All deliveries were not selected. A zero count on the selected filtered view does not by itself establish what the unfiltered state renders. |
| Partial / unknown billing facts | inspected where visible | Ordinary invoice/payment rows preserve absent provider events and nil relationships; missing local history is not a processor outcome. |
| Loading / ready / application error | partially inspected | Recovery reached source-backed `no-pagination` and funnel `ready` after a 15-second wait (C18). A stable application-error state was not available. |
| Zero / one / many | partial | Visible counts are recorded on current list/detail routes; alternate forced relationship cardinalities were not seeded or claimed. |
| Overflow / adversarial long text | unavailable | Phase 191 `edge_states` owns those stress fixtures; they are excluded from ordinary preview. |
| Search / keyboard / pointer | representative interaction inspected | C21/C22 capture Ctrl+K, focus, ArrowDown selection and pointer hover. Hover moved the active marker from the earlier subscription path to the customer path; only the customer appeared highlighted in the after-state. Keyboard activation remains untested. |
| Tabs / disclosures | representative interaction inspected | C23 selected the customer Invoices tab (zero invoice rows). C24 opened Activity, but the image still shows the lazy-load prompt, so no loaded history is claimed. Other details remain uninspected. |
| Touch / role scope / other filter transitions | unavailable | No physical touch or alternate role/scope was exercised; non-customer filter/query/count and clear/remove behavior remains unverified. |

All detailed entries, exact route-state IDs, reasons, and PNG hashes are in the machine-readable `state_matrix` and route rows above. Screenshots do not prove unrecorded interactions, accessibility conformance, or action outcomes.

## Evidence boundaries

The owner screenshots in `2026-10-11-admin-owner-feedback.md` are defect references only. Generated PNGs below are the current ordinary Fake instance. Fixture-local statuses without matching processor history remain local seed facts; no attempt or settlement outcome is inferred. Missing record identifiers are unavailable evidence, not a pass. No production UI changes are made in this plan.
