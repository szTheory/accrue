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
| Source revision and fingerprint | Captured `source_head` is `9eaa9cc1057afd54bf45fd9b214449e3dd5a6695`; `source_sha` is `e40c3c9827f83a1f6819a72ecdcb62c9cf4750958c558c34890170319b6d1f63`. Exact owner spec SHA-256 `e0b682d3a3c364914e896b95b34276bb728a8bd68f24f9843c19607742f23580`, 33,719 B. The manifest fingerprints the source/worktree bytes actually exercised, including CSS, JS, fonts, LiveViews, fixtures and the owner spec. |
| Package build → host compilation → served resources | Rebuilt package and recompiled host; all four resources match package, compiled, served and browser-request bytes. CSS `4b971b0b94e08ee1bb62d47c4142be59ec270daf79e2bad4af73e746d9bb478f` (130,349 B). Exact CSS/JS/Geist/Geist Mono URLs and digests are authoritative in [manifest.json](captures/phase237-exemplar/manifest.json). |
| Render and state | Disposable host Ecto Sandbox, Admin Alpha; invoice collection → detail/review `/admin/invoices/9ada837c-631e-4858-8119-2f403746a742?org=accrue-e2e-alpha` and the manifest's dense subscription route. Review names the exact invoice and customer. No production or feedback-preview database selected. |
| Theme / viewport / input / zoom | Stored preference before inspection: `system` in localStorage and rendered root, no theme cookie, OS preference emulated light. Effective light/dark computed colors and reduced motion recorded after explicit Playwright media + `data-theme` overrides; this does not mutate stored preference. Captures include 320×800 and 1280×900 CSS viewports; 320/768/1280 checks run for both fine and Pixel 5 coarse pointer. Actual browser zoom is not asserted; headless 400% zoom was unavailable. |
| Browser / OS / runner / lockfile | Playwright Chromium `147.0.7727.15`, macOS `darwin 25.6.0`, Node `v22.14.0`, `CI=1`; host package-lock SHA-256 `b70a34de9865925c1d5d38b7dc564d43a9781aa91044b36878ac611c0e67df90`. Commands are recorded in the linked manifest and summary. |
| Interaction evidence | Mounted list, navigation, exact detail, recovery navigation and invoice action review exercised. No confirmation or billing dispatch was attempted; the manifest records `action_confirmed_or_dispatched: false`. This is the test's known action path, not a no-mutation inference from HTTP method collection. |
| Resource/timing diagnostics | At 2026-10-09T23:41:47.669Z: 5 resources; encoded/decoded body 409,872/409,872 B, transfer 411,372 B; cold task/LiveView-ready 215.08/175.82 ms; warm 40.33/31.7 ms; drawer/review 111.25/123.63 ms. Layout shift and long task API observations are in the manifest. These are single-run diagnostics, not an SLA. |
| Stale asset negative | Browser route interception XORed the first byte of the served JS. The mounted digest assertion rejected the changed bytes with `served response differs from package build`; the interception was removed and the restored response SHA matched the package SHA. The unmodified Playwright JUnit is preserved in `/private/tmp/24006-red-asset.xml`; the committed classifier record is explicitly a privacy-safe redacted report copy, not the unchanged raw report. |

Four current screenshots plus the exact render/resource manifest are captured in [`captures/phase237-exemplar/`](captures/phase237-exemplar/). The commands and result transcript, including any privacy-redacted copy label and raw report retention boundary, are recorded in `240-06-SUMMARY.md`. A historical screenshot, source inspection, fake preview/source inspection, injected DOM content, or provider outcome does not substitute for the mounted assertion.

The first-fresh resource measurements have no invented SLA. Preview Fake DB is never selected by this proof.

## Phase 242-07 Current Owner Acceptance

This record adds current evidence from Phase 242 Plan 07. It does not convert other
route states to exercised merely because their owners ran in the combined suite.

| Changed consumer | Current owner / observable states | Result |
|---|---|---|
| Coupon → promotion code → exact coupon parent; Connect detail → exact fee review target | `accrue_admin/e2e/admin-page-flow-phase191.spec.js` (`@phase242`) | `CI=1 npm --prefix accrue_admin run e2e:phase191`: 29 passed, 1 incumbent skip, 0 failed. |
| Shell overlays, focus, responsive widths, theme modes, atomic CSS text enlargement/spacing stress | `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` (`@phase242`) | `CI=1 npm --prefix accrue_admin run e2e:phase199`: 27 passed, 15 incumbent skips, 0 failed. Playwright viewport/pointer/theme emulation only. |
| Events filtered membership and exact source webhook; single/bulk reviewed replay target | `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js`; `accrue_admin/test/accrue_admin/live/webhook_replay_test.exs`; `webhooks_live_test.exs` | Host Phase 238 owner passed; replay ExUnit owner pair: 25 tests, 0 failures. Underlying ExUnit asserts jobs, audit and domain state for dismissal, duplicates, stale scope/eligibility and read failure. |
| Search current-result pointer → Arrow → Enter, no-match/reopen and scoped real link | `examples/accrue_host/e2e/phase234-search-completion.spec.js` | Host Phase 234 owner passed as part of the 2-test host command. |
| Combined changed-consumer regression | Admin full ExUnit + Node; host full ExUnit | Admin 679 tests, Node 44/44, host 223 tests, all 0 failures; both warnings-as-errors compiles passed. |

The route inventory above remains the route/state authority. In this plan, loading,
error, partial and zero/one/many states are only marked current where the selected
owner explicitly exercised them; the full suite run is regression coverage, not a
claim that every inventory state was mounted. See the Phase 242 execution gate for
commands, current asset hashes, inspection record and evidence limits.

## Current changed-owner acceptance results

| Owner | Command / result |
|---|---|
| Admin | Final warnings-as-errors compile and full ExUnit — 618 tests, 0 failures |
| Phase 191 lifecycle | Existing full owner — 26 tests, 0 failures (Wave 3 record) |
| Phase 237 mounted exemplar and assets | `CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — 1 test passed; four asset byte identities matched; stale JS negative detected and restored |
| Ledger completeness | Final self-test `valid=1 missing-route-rejected=1`; normal CLI passed 21 routes, 8 requirements, registry 30/42/8 and 43 source modules |
| Host integration full gate | Final `mix verify.full` exited 0: bounded 64/0, full 223/0, dev boot passed, browser 37 passed/16 incumbent skips, separate Braintree checkout 14/0. Initial 222ms TrustSmoke observation remains historical; later complete failures identified archive/path and stale fixture assertions, now repaired without changing thresholds. |

Historical Phase 199 results and previously resolved deferred fixes are in `240-WAVE-GATES.md`; they are not marked as re-run by this plan. The first Phase 240 RED-timing deviation remains disclosed in the 240-03 summary: later retrospective evidence does not recreate original pre-GREEN timing. No point-in-time ledger check is proposed as a recurring CI gate; existing behavior owners remain the recurring checks.

## Final gate record

[Current results](captures/final-gates/results.json) and explicitly labeled privacy copies of native JUnit reports preserve the automated closeout evidence. Package desktop/mobile owners: 89 passed, 19 incumbent skips, 0 failures; Node 41/41 (includes all 12 baseline-set controls); exact eight-baseline CLI and package docs/contrast guard passed. The existing owner tests and CI lanes remain authoritative; remote CI has not been observed in this execution.
