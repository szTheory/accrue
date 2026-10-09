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
| Source revision and fingerprint | Captured `source_head` is `e24e10826c1d3303a640eff1af3d546e47f308c7`; `source_sha` over the manifest's per-file fingerprints is `d57776e686dd7d5083dbb64b941c0ba21bfd308dc974ec7e38157b7a7d6602e0` (the exact Phase 237 owner spec SHA-256 is `d7eebbc936477f9958c2d5243837483517c66157a307ca0eec63ad45a8cb0f87`, 32,512 B). `source_sha` fingerprints the complete owner worktree bytes exercised before its GREEN commit. CSS/theme, JS entry, bundles, fonts, invoice/subscription LiveViews, tests, recovery component, seed and browser spec are fingerprinted. |
| Package build → host compilation → served resources | Rebuilt package then recompiled host. All source-package, host-compiled, and mounted response SHA-256s match: CSS `68977564e2fd5b35b4c8588880689536e8b4cb6012d23523036b8985bc8c8f83` (130,314 B), JS `c852628a1ab87ba56d8e72153c972d8ce85e6421066b0aef6f3368e6a8186d0a` (159,939 B), Geist Sans `28258d0621216948416a859d32487ab6ad1c9effa0d08795698e70be3c917630` (56,800 B), Geist Mono `5bc6413e82be410dc057feccee55160495b999d0fe212b7b6c6499b29b8b1e4a` (58,048 B). Exact URLs/four-way digest records are in [`manifest.json`](captures/phase237-exemplar/manifest.json). |
| Render and state | Fixture: disposable host Ecto Sandbox, Admin Alpha (`accrue-e2e-alpha`); list `/admin/invoices?org=accrue-e2e-alpha&status=open%2Cuncollectible`, detail/review `/admin/invoices/2bf9bd72-f8e0-488c-a191-cf4bfad38236?org=accrue-e2e-alpha`, and dense subscription detail. The `Pay invoice` review names the exact invoice and customer. No production or preview database was selected. |
| Theme / viewport / input / zoom | Stored preference before inspection: `system` in localStorage and rendered root, no theme cookie, OS preference emulated light. Effective light/dark computed colors and reduced motion recorded after explicit Playwright media + `data-theme` overrides; this does not mutate stored preference. Captures include 320×800 and 1280×900 CSS viewports; 320/768/1280 checks run for both fine and Pixel 5 coarse pointer. Actual browser zoom is not asserted; headless 400% zoom was unavailable. |
| Browser / OS / runner / lockfile | Playwright Chromium `147.0.7727.15`, macOS `darwin 25.6.0`, Node `v22.14.0`, `CI=1`; host package-lock SHA-256 `b70a34de9865925c1d5d38b7dc564d43a9781aa91044b36878ac611c0e67df90`. Commands are recorded in the linked manifest and summary. |
| Interaction evidence | Mounted list, navigation, exact detail, recovery navigation and invoice action review exercised. No confirmation or billing dispatch was attempted; the manifest records `action_confirmed_or_dispatched: false`. This is the test's known action path, not a no-mutation inference from HTTP method collection. |
| Resource/timing diagnostics | At 2026-10-09T22:54:25.216Z the cold invoice page recorded 5 resources; raw encoded/decoded body `409,837 B`, transfer `411,337 B`; cold task-ready `234.05 ms`, LiveView-ready `184.70 ms`; warm task-ready `48.30 ms`, LiveView-ready `37.57 ms`; drawer `115.58 ms`, review `123.60 ms`. Layout-shift API supported (0 entries/value); long-task API supported (0 entries/0 ms). CSS/JS and font resource bytes/durations are in the manifest. These are single-run diagnostics, not an SLA. |
| Stale asset negative | Browser route interception XORed the first byte of the served JS. The mounted digest assertion rejected the changed bytes with `served response differs from package build`; the interception was removed and the restored response SHA matched the package SHA. The unmodified Playwright JUnit is preserved in `/private/tmp/24006-red-asset.xml`; the committed classifier record is explicitly a privacy-safe redacted report copy, not the unchanged raw report. |

Four current screenshots plus the exact render/resource manifest are captured in [`captures/phase237-exemplar/`](captures/phase237-exemplar/). The commands and result transcript, including any privacy-redacted copy label and raw report retention boundary, are recorded in `240-06-SUMMARY.md`. A historical screenshot, source inspection, fake preview/source inspection, injected DOM content, or provider outcome does not substitute for the mounted assertion.

The first-fresh resource measurements have no invented SLA. Preview Fake DB is never selected by this proof.

## Current changed-owner acceptance results

| Owner | Command / result |
|---|---|
| Admin | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` — 617 tests, 0 failures (Wave 3 record) |
| Phase 191 lifecycle | Existing full owner — 26 tests, 0 failures (Wave 3 record) |
| Phase 237 mounted exemplar and assets | `CI=1 npx playwright test e2e/phase237-admin-billing.spec.js --project=chromium-desktop` — 1 test passed; four asset byte identities matched; stale JS negative detected and restored |
| Ledger completeness | `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` then normal CLI — task 1 result added by this plan |
| Host integration full gate | `HEX_HOME=/private/tmp/accrue240-hex MIX_ENV=test mix verify.full` started with unchanged locked deps, then stopped in existing `AccrueHostWeb.TrustSmokeTest` because its webhook ingest timing was 222ms against the pre-existing 100ms budget; this is unrelated to the Phase 240 assets/browser evidence, was not retuned or rerun |

Historical Phase 199 results and previously resolved deferred fixes are in `240-WAVE-GATES.md`; they are not marked as re-run by this plan. The first Phase 240 RED-timing deviation remains disclosed in the 240-03 summary: later retrospective evidence does not recreate original pre-GREEN timing. No point-in-time ledger check is proposed as a recurring CI gate; existing behavior owners remain the recurring checks.
