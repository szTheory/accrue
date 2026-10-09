# Phase 240 current Admin coverage and provenance ledger

**Ledger revision:** 240-06 execution, source SHA is recorded in the 240-06 summary.  
**Route authority:** [`239-COVERAGE.md`](../../milestones/v1.63-phases/239-integrated-quality-handoff/239-COVERAGE.md), package `/admin` production LiveView route rows, cross-checked against compiled `AccrueAdmin.Router` helpers by existing host integration acceptance. This ledger has no independent route allowlist.  
**Scope:** 21 production LiveView routes in six operator families. Static asset endpoints and two legacy redirects remain owned by the Phase 239 route ledger; they are not counted as production pages here.  
**Registry authority:** existing `ComponentRegistry` and `component_registry_test.exs`: 30 component families, 42 variants, 8 groups. Separately, `accrue_admin/lib/accrue_admin/components/` contains 43 source component modules. Neither count is a route count or a second registry.  
**Evidence labels:** `exercised` means the named command/test was run and its result is recorded below; `source-only` means a source contract or owner exists but was not exercised in this plan; `historical` means prior-phase evidence and is not a current run.

## Route and owner inventory

| Route identity | Family | State / interaction applicability | Owning acceptance file and command | Evidence status |
|---|---|---|---|---|
| `/admin` | Overview | populated, empty, loading, error, theme, shell navigation | `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs` | exercised: host mounted billing exemplar; other states source-only |
| `/admin/analytics/recovery` | Recovery | populated, empty, filter, unavailable | `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs`; `mix test test/accrue_admin/live/analytics/recovery_live_test.exs` | source-only |
| `/admin/analytics/recovery/subscriptions/:id` | Recovery | populated, partial, owner-scoped detail | `accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs`; host integration gate | source-only |
| `/admin/connect` | Provider and offers | populated, empty, unavailable, owner scope | `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs`; host integration gate | source-only |
| `/admin/connect/:id` | Provider and offers | populated, partial provider facts, unavailable | `accrue_admin/test/accrue_admin/live/connect_account_live_test.exs`; host integration gate | source-only |
| `/admin/coupons` | Provider and offers | populated, empty, unavailable, search/filter | `accrue_admin/test/accrue_admin/live/coupons_live_test.exs`; host integration gate | source-only |
| `/admin/coupons/:id` | Provider and offers | populated, partial, related redemptions | `accrue_admin/test/accrue_admin/live/coupon_live_test.exs`; host integration gate | source-only |
| `/admin/customers` | Customer records | populated, empty, search/filter, owner scope | `accrue_admin/test/accrue_admin/live/customers_live_test.exs`; host integration gate | source-only |
| `/admin/customers/:id` | Customer records | populated, partial related records, owner scope | `accrue_admin/test/accrue_admin/live/customer_live_test.exs`; host integration gate | source-only |
| `/admin/events` | Events and delivery | populated, empty, search/filter, owner scope | `accrue_admin/test/accrue_admin/live/events_live_test.exs` | historical; route unit owner source-only |
| `/admin/events/:id` | Events and delivery | populated, partial payload, owner scope | `accrue_admin/test/accrue_admin/live/event_live_test.exs`; host integration gate | source-only |
| `/admin/invoices` | Billing records | populated, empty, no-match, unavailable, filter, exact money | `accrue_admin/test/accrue_admin/live/invoices_live_test.exs`; full Admin ExUnit | exercised: Phase 240 full Admin ExUnit |
| `/admin/invoices/:id` | Billing records | detail, action review, denied, pending, failed/unknown, exact target/money | `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`; host integration | exercised: Phase 237 mounted review; ExUnit full Admin |
| `/admin/payments` | Billing records | populated, empty, filter, unavailable | `accrue_admin/test/accrue_admin/live/charges_live_test.exs`; host integration gate | source-only |
| `/admin/payments/:id` | Billing records | populated, partial, refund review/result | `accrue_admin/test/accrue_admin/live/charge_live_test.exs`; host integration gate | source-only |
| `/admin/promotion-codes` | Provider and offers | populated, empty, unavailable, restrictions | `accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs`; host integration gate | source-only |
| `/admin/promotion-codes/:id` | Provider and offers | populated, partial, coupon relationship | `accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs`; host integration gate | source-only |
| `/admin/subscriptions` | Billing records | populated, empty, filters, lifecycle action states | `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs`; full Admin ExUnit | exercised: Phase 240 full Admin ExUnit and Phase 191 owner |
| `/admin/subscriptions/:id` | Billing records | detail, exact plan money/period, action review/result | `accrue_admin/test/accrue_admin/live/subscription_live_test.exs`; full Admin ExUnit | exercised: Phase 240 full Admin ExUnit |
| `/admin/webhooks` | Events and delivery | populated, empty, filtered queue, replay review/result | `accrue_admin/test/accrue_admin/live/webhooks_live_test.exs` | historical; route unit owner source-only |
| `/admin/webhooks/:id` | Events and delivery | populated, partial payload, delivery outcome | `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`; host integration gate | source-only |

### State applicability

`populated`, `empty`, `loading`, `error`, `partial`, `overflow`, `zero/one/many`, `long-text`, `denied`, `pending`, `failed`, and `unknown` are evaluated at their existing route owners; they do not all apply to every endpoint. Static-only asset and redirect routes have no record-state matrix because they do not render a record collection: their byte/hash and destination contracts are in `239-COVERAGE.md`. Review/result and pending are N/A for read-only route rows because those endpoints expose no mutation; detail and owner scope remain covered by their route-specific LiveView suites. This is a scope rationale, not evidence that a state was exercised.

## Requirement to recurring owner map

| Requirement | Current Phase 240 owner / evidence command | N/A / evidence boundary |
|---|---|---|
| DSN-01 | Invoice and subscription LiveView suites; host Phase 237 mounted invoice list/detail/review | N/A states follow route applicability above |
| DSN-02 | `accrue_admin` Playwright Phase 196 and Phase 198 owners; `mix verify.full` host integration | Actual 400% browser zoom unavailable on this headless host; CSS scaling/pinch evidence is not zoom proof |
| DSN-03 | Theme picker/theme ExUnit owners and Phase 199/238 mounted owners | OS preference simulation is not a physical OS test |
| DSN-04 | Invoice/subscription ExUnit plus Phase 191 lifecycle owner; authoritative disposable-fixture dispatch/audit assertions | HTTP non-GET request observation alone is not mutation proof |
| DSN-05 | FocusTrap Node owner and Phase 199 overlay browser owner | Axe is supplementary; no screen-reader speech claim |
| UXC-02 | Invoice list/detail and subscription LiveView owners | Unsupported provider operation has no success/action transition; remains explicit N/A |
| EVR-01 | Phase 237 mounted asset and resource evidence; asset tests and `mix accrue_admin.assets.build` | First-fresh measurements are diagnostics, not an SLA |
| EVR-02 | Existing ExUnit, Node, Playwright, axe, asset/drift and Linux pixel owners | Linux pixel run is remote CI owned and locally unrun on macOS; final reviewed goldens belong to Phase 243 |

## Mounted Phase 237 exemplar record

| Evidence item | Result / status |
|---|---|
| Route and fixture | host `/admin` is Admin; disposable `HOST-BROWSER-VERIFY01` invoice fixture; exercised list → invoice detail → action review and dense subscription view. host `/billing` is Portal; package fixture `/billing` is Admin. |
| Source revision and fingerprint | Recorded in the Phase 237 Playwright attachment and execution summary; repository SHA is pinned in the 240-06 summary. Per-file SHA-256 inputs: CSS, theme, invoice/subscription LiveViews, at-risk component, seed and owner spec. |
| Package build → host compilation → served resources | Package built with `mix accrue_admin.assets.build`; mounted owner compares built package CSS and JS and font response bytes to compiled host asset bytes. SHA-256 response fingerprints and content sizes are asserted. Stored and served identities are distinct evidence fields. |
| Render and state | `host /admin/invoices?org=<fixture-owner>`; fresh invoice list; exact fixture invoice detail; `Pay invoice` action review includes the target invoice and customer. No production or preview database is used. |
| Theme / viewport / input / zoom | Stored and effective theme recorded separately; 1280×900 desktop and 320×800 narrow CSS viewport; fine pointer in browser project. Browser zoom is not asserted; actual 400% zoom unavailable. |
| Browser / OS / runner / lockfile | Playwright Chromium desktop project, macOS runner; package lock revision recorded with the run. Browser version and exact CLI are in the summary evidence record. |
| Interaction evidence | Mounted navigation and server-backed invoice review exercised. Mutation count comes from the disposable fixture's authoritative dispatch/audit record, not from HTTP method collection. Preview Fake DB is never selected. |
| Resource/timing diagnostics | Initial fresh page resource count, raw encoded/decoded/transfer bytes, cold task-ready and LiveView-ready, filter/detail interaction durations, layout shift and long-task availability captured when supported. These are comparative diagnostics only; no invented SLA. |
| Stale asset negative | An isolated response fixture is deliberately given a stale digest; mounted asset comparison must reject it. Fixture is restored before the passing run. |

The commands and result transcript, including any privacy-redacted copy label and raw report retention boundary, are recorded in `240-06-SUMMARY.md`. A historical screenshot, source inspection, fake preview/source inspection, injected DOM content, or provider outcome does not substitute for the mounted assertion.

## Current changed-owner acceptance results

| Owner | Command / result |
|---|---|
| Admin | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` — 617 tests, 0 failures (Wave 3 record) |
| Phase 191 lifecycle | Existing full owner — 26 tests, 0 failures (Wave 3 record) |
| Phase 237 mounted exemplar and assets | Task 2 command/result added by this plan before completion |
| Ledger completeness | `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` then normal CLI — task 1 result added by this plan |

Historical Phase 199 results and previously resolved deferred fixes are in `240-WAVE-GATES.md`; they are not marked as re-run by this plan. The first Phase 240 RED-timing deviation remains disclosed in the 240-03 summary: later retrospective evidence does not recreate original pre-GREEN timing. No point-in-time ledger check is proposed as a recurring CI gate; existing behavior owners remain the recurring checks.
