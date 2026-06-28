---
phase: 197
slug: propagate-list
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-28
verified: 2026-06-28
threats_total: 32
threats_closed: 32
accepted_risks: 1
unregistered_flags: 0
---

# Phase 197 - Security

Per-phase security contract for `197-propagate-list`. This audit verifies the declared PLAN threat register against implemented code and test evidence. Implementation files were not modified.

## Audit Inputs

| Input | Evidence |
|-------|----------|
| Threat register | `197-01-PLAN.md:200-205`, `197-02-PLAN.md:186-191`, `197-03-PLAN.md:206-210`, `197-04-PLAN.md:188-192`, `197-05-PLAN.md:158-162`, `197-06-PLAN.md:199-204`, `197-07-PLAN.md:167-171` |
| Summary threat flags | `197-01-SUMMARY.md:103-105`, `197-02-SUMMARY.md:112-114`, `197-03-SUMMARY.md:122-124`, `197-06-SUMMARY.md:97-99`, `197-07-SUMMARY.md:169-171`; `197-04` and `197-05` had no `## Threat Flags` section, so their plan threat registers were verified directly |
| Validation/review/verification | `197-VALIDATION.md:43-50`, `197-REVIEW.md:52-74`, `197-VERIFICATION.md:26-55`, `197-VERIFICATION.md:96-104`, `197-VERIFICATION.md:142-144` |
| Config | `.planning/config.json` does not declare a security `asvs_level` or `block_on`; this artifact uses the template default `asvs_level: 1` under the active verify:post secure-phase hook |

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser URL params to LiveView filters | List filters, work-queue defaults, `view=all`, cursor, loading fixture, and `org` slug enter through route/query params. | URL params and owner-scope selector |
| LiveView/DataTable to query modules | Shared `DataTable` decodes params and passes `current_owner_scope` into query modules for rows and newer-count polling. | Filter maps, cursor, owner scope |
| Scoped list rows to browser | List rows, visible counts, chip labels, empty/loading states, and mobile cards render back to the browser. | Billing/customer/connect/webhook/event metadata |
| Webhook replay UI to DLQ | Browser-selected webhook IDs are accepted only after owner-scope proof and then replayed. | Selected webhook IDs and admin audit data |
| Test/browser contracts | Phase 197 contracts and Playwright checks exercise UI markers and fixture labels. | Test-only fixtures and visible UI state, no secret-bearing browser assertions |

## Threat Register

| Threat ID | Category | Component | Disposition | Evidence | Status |
|-----------|----------|-----------|-------------|----------|--------|
| T-197-01 | Information Disclosure | List clear-all contracts | mitigate | Test manifest `all_target` rows preserve `view=all` without dropping scope intent (`test/support/list_contracts.ex:13-229`); runtime merge keeps existing `org` query params (`data_table_nav.ex:12-21`, `data_table_nav.ex:46-58`). | closed |
| T-197-02 | Denial of Service | Webhooks status decode | mitigate | Webhook status strings are filtered through `@valid_status_strings` before `String.to_existing_atom/1` (`queries/webhooks.ex:18-19`, `queries/webhooks.ex:173-180`); test rejects `Elixir.String` input (`query_modules_test.exs:310-314`). | closed |
| T-197-03 | Information Disclosure | Charges owner scope | mitigate | Charges join customers and scope by organization before filters/cursors/counts (`queries/charges.ex:24-30`, `queries/charges.ex:59-64`, `queries/charges.ex:127-135`); query test excludes denied-org charge (`query_modules_test.exs:466-519`). | closed |
| T-197-04 | Tampering | Test-only manifest | mitigate | Contract module is under `accrue_admin/test/support/list_contracts.ex:1-8`; grep for `AccrueAdmin.ListContracts|ListContracts` in `accrue_admin/lib` returned no runtime imports. | closed |
| T-197-05 | Spoofing | Browser smoke assertions | mitigate | Playwright asserts rendered PageHeader/list/chips/count/clear affordances, not source-only proof (`admin-spec-list-phase197.spec.js:171-230`, `admin-spec-list-phase197.spec.js:233-397`). | closed |
| T-197-06 | Information Disclosure | LiveView clear-all links | mitigate | All eight LiveViews call `DataTableNav.patch_with_filters`, pass `current_owner_scope`, and use scoped clear-all hrefs; grep verified lines across all target LiveViews, including `customers_live.ex:74,137,146`, `invoices_live.ex:56,136,145`, `charges_live.ex:56,136,145`, `coupons_live.ex:63,151,160`, `promotion_codes_live.ex:55,142,151`, `webhooks_live.ex:99,241,250`, `events_live.ex:86,159,168`, `connect_accounts_live.ex:55,140,149`. | closed |
| T-197-07 | Spoofing | Default lenses and queue-empty states | mitigate | Shared contracts bind default lenses/state copy for all eight pages (`list_contracts.ex:13-229`); browser verifies URL-backed default params and state markers (`admin-spec-list-phase197.spec.js:159-215`, `admin-spec-list-phase197.spec.js:380-395`). | closed |
| T-197-08 | Tampering | Payments route language | mitigate | Payments page uses `ChargesLive` with `list_id="payments"` and payment copy (`charges_live.ex:100`, `charges_live.ex:132-140`); focused verification confirms no `/charges` UI drift (`197-VERIFICATION.md:45-47`). | closed |
| T-197-09 | Elevation of Privilege | Webhooks replay | mitigate | Replay confirmation scopes selected IDs before `DLQ.requeue/1` (`webhooks_live.ex:110-155`); tests prove selected IDs/count are audited and out-of-scope rows are not retried (`webhooks_live_test.exs:253-285`, `webhooks_live_test.exs:329-370`). | closed |
| T-197-10 | Information Disclosure | Connect attention filters | mitigate | Connect list and newer counts apply `scope_query(owner_scope)` before filters/counting (`queries/connect_accounts.ex:18-29`, `queries/connect_accounts.ex:49-58`, `queries/connect_accounts.ex:91-99`); LiveView KPI summary uses scoped accounts (`connect_accounts_live.ex:432-467`). | closed |
| T-197-11 | Denial of Service | Webhooks.decode_filter/1 | mitigate | `decode_filter/1` routes status through the allowlisted decoder (`queries/webhooks.ex:54-60`, `queries/webhooks.ex:173-193`); malicious existing-atom string is ignored by test (`query_modules_test.exs:310-314`). | closed |
| T-197-12 | Information Disclosure | Charges.list/1 | mitigate | Row and count paths join `Customer` and organization-scope before filtering (`queries/charges.ex:18-30`, `queries/charges.ex:54-64`, `queries/charges.ex:130-135`); source and tests close the prior owner-scope gap (`query_modules_test.exs:466-519`). | closed |
| T-197-13 | Tampering | Connect needs_attention | mitigate | `needs_attention=true` is a named OR predicate over deauthorized/onboarding/charges/payouts readiness (`queries/connect_accounts.ex:133-144`); tests include all blocker variants and exclude a healthy account (`query_modules_test.exs:354-414`). | closed |
| T-197-14 | Repudiation | Count/copy helpers | mitigate | `DataTable` passes only visible row count into list status (`data_table.ex:282-284`); FilterChipBar renders "Showing N ..." visible-copy labels (`filter_chip_bar.ex:38-47`, `filter_chip_bar.ex:129-130`). | closed |
| T-197-15 | Information Disclosure | Customers/Coupons/Promotion clear-all | mitigate | `DataTableNav.merge_query/2` preserves existing `org` and removes blank filters (`data_table_nav.ex:46-58`); target clear-all links use it (`customers_live.ex:348-356`, `coupons_live.ex:346-353`, `promotion_codes_live.ex:362-370`). | closed |
| T-197-16 | Spoofing | Coupons valid default | mitigate | Coupon contract declares `valid=true` default and `view=all` escape hatch (`list_contracts.ex:92-119`); browser all-page contract asserts active chip/result/clear-all semantics (`admin-spec-list-phase197.spec.js:56-66`, `admin-spec-list-phase197.spec.js:192-215`). | closed |
| T-197-17 | Spoofing | Promotion active default | mitigate | Promotion-code contract declares `active=true` default and `view=all` escape hatch (`list_contracts.ex:120-148`); browser contract asserts Active codes and All promotion codes (`admin-spec-list-phase197.spec.js:68-77`, `admin-spec-list-phase197.spec.js:192-215`). | closed |
| T-197-18 | Information Disclosure | Row identity | mitigate | Runtime rows put operator-facing identifiers before raw plumbing IDs, for example customer/coupon/promotion/payment/invoice/webhook/connect card titles (`customers_live.ex:215-255`, `coupons_live.ex:230-271`, `promotion_codes_live.ex:230-281`, `charges_live.ex:264-273`, `invoices_live.ex:236-258`, `webhooks_live.ex:553`, `connect_accounts_live.ex:517`); focused tests assert column priority (`customers_live_test.exs:224-272`, `coupons_live_test.exs:180-262`, `promotion_codes_live_test.exs:186-268`, `charges_live_test.exs:220-332`, `invoices_live_test.exs:229-329`). | closed |
| T-197-19 | Information Disclosure | Invoices clear-all | mitigate | Invoices uses scoped path, `DataTableNav.patch_with_filters`, `current_owner_scope`, and clear-all merge (`invoices_live.ex:56`, `invoices_live.ex:136`, `invoices_live.ex:145`, `invoices_live.ex:473-478`). | closed |
| T-197-20 | Information Disclosure | Payments owner scope | mitigate | `ChargesLive` passes `current_owner_scope` into the DataTable (`charges_live.ex:132-140`); row, summary, and refund counts scope through customer owner fields (`queries/charges.ex:127-135`, `charges_live.ex:196-248`). | closed |
| T-197-21 | Spoofing | Status queue labels | mitigate | Invoice/payment contracts bind backend status params to operator labels (`list_contracts.ex:35-53`, `list_contracts.ex:63-90`); browser verifies default URL params and clear-all escape hatches (`admin-spec-list-phase197.spec.js:309-328`). | closed |
| T-197-22 | Repudiation | Visible counts | mitigate | Same visible-count path as T-197-14: `visible_count: length(@rows)` (`data_table.ex:282-284`) and "Showing N" copy (`filter_chip_bar.ex:129-130`); verification reports chips/count coverage for all target pages (`197-VERIFICATION.md:28`, `197-VERIFICATION.md:47`, `197-VERIFICATION.md:51`). | closed |
| T-197-23 | Elevation of Privilege | Webhooks replay | mitigate | Default replay queue is `failed,dead` (`webhooks_live.ex:22`, `webhooks_live.ex:64-67`); selected-row replay keeps only IDs passing `Webhooks.detail(id, owner_scope)` before `DLQ.requeue/1` (`webhooks_live.ex:110-155`). | closed |
| T-197-24 | Denial of Service | Webhooks status params | mitigate | Failed/dead multi-status params use the allowlisted decoder and SQL `in ^statuses` filter (`queries/webhooks.ex:159-163`, `queries/webhooks.ex:173-180`); tests prove only failed/dead deliveries are returned (`query_modules_test.exs:316-344`). | closed |
| T-197-25 | Spoofing | Events default lens | mitigate | Events contract declares All ledger as default and Admin changes as a quick lens (`list_contracts.ex:175-196`); browser verifies All ledger/Admin changes and event rendering (`admin-spec-list-phase197.spec.js:349-364`). | closed |
| T-197-26 | Tampering | Connect needs_attention | mitigate | Connect defaults to `needs_attention=true` through URL-backed defaults (`connect_accounts_live.ex:67-75`) and the query implements OR, not AND, semantics (`queries/connect_accounts.ex:133-144`); tests cover all readiness blockers (`query_modules_test.exs:348-414`). | closed |
| T-197-27 | Information Disclosure | Clear-all links | mitigate | `ScopedPath.build/4` injects `org` for organization scopes (`scoped_path.ex:13-21`), and `DataTableNav.merge_query/2` preserves it on filter changes/clear-all (`data_table_nav.ex:46-58`); grep verified all target LiveViews use these paths. | closed |
| T-197-28 | Spoofing | Browser page contract | mitigate | Playwright all-page desktop/mobile checks assert visible PageHeader, h1, list markers, chips, counts, defaults, and loading markers (`admin-spec-list-phase197.spec.js:171-230`, `admin-spec-list-phase197.spec.js:233-397`); verification shows `npm run e2e:phase197` passed (`197-VERIFICATION.md:101-102`). | closed |
| T-197-29 | Information Disclosure | Mobile clipping/overflow | mitigate | Browser checks desktop and mobile no-horizontal-clipping plus mobile card rendering (`admin-spec-list-phase197.spec.js:220-230`, `admin-spec-list-phase197.spec.js:268-291`); command passed (`197-VERIFICATION.md:101`). | closed |
| T-197-30 | Repudiation | Verification summary | mitigate | Exact command evidence and unrelated broad-suite Dashboard blocker are recorded (`197-07-SUMMARY.md:84-105`, `197-VERIFICATION.md:96-104`, `197-VERIFICATION.md:130-144`). | closed |
| T-197-31 | Tampering | Source guard drift | mitigate | Compile warnings and package-doc guards are recorded green (`197-VALIDATION.md:47-50`, `197-VERIFICATION.md:100-103`, `197-07-SUMMARY.md:93-95`); broad Dashboard failure is documented outside Phase 197 ownership (`197-VERIFICATION.md:130-144`). | closed |
| T-197-SC | Tampering | Package installs | accept | Accepted supply-chain risk is documented below. Verification found no dependency additions: `package.json` has only existing devDependencies (`package.json:23-27`), and `git show e2ac0ba6 -- accrue_admin/package.json` adds only the `e2e:phase197` script. | documented accepted risk |

## Focused Mitigation Notes

| Required behavior | Verification |
|-------------------|--------------|
| Owner-scope preservation | URL scope is preserved by `ScopedPath.build/4` and `DataTableNav.merge_query/2`; all eight LiveViews pass `current_owner_scope` into `DataTable`; owner-bearing query modules scope list/count/detail paths (`queries/customers.ex:18-57,67-86,135-143`, `queries/invoices.ex:18-70,162-170`, `queries/charges.ex:18-64,127-135`, `queries/events.ex:49-87,149-166`, `queries/connect_accounts.ex:18-58,91-99`, `queries/webhooks.ex:22-50,93-106,195-227`). |
| URL/filter allowlisting | Webhooks statuses and invoices statuses are allowlisted before atom conversion (`queries/webhooks.ex:173-180`, `queries/invoices.ex:137-159`); clear-all/filter URLs are merged and blank-dropped through one shared helper (`data_table_nav.ex:46-58`). |
| Connect needs_attention bounded predicate | `needs_attention=true` is exactly the bounded OR predicate over deauthorization, missing onboarding, charges, and payouts (`queries/connect_accounts.ex:133-144`) and is tested (`query_modules_test.exs:354-414`). |
| Webhooks replay failed/dead allowlisting and scoped selected replay | Default queue is `failed,dead`; status params are allowlisted; bulk count filters failed/dead after scoping; selected IDs are scoped before replay (`webhooks_live.ex:22`, `queries/webhooks.ex:93-99`, `webhooks_live.ex:110-155`). |
| No secret-bearing browser checks | Grep over `admin-spec-list-phase197.spec.js` and `test/support/list_contracts.ex` for secret/token/password/key/auth/raw_body/card/PAN/CVV/body text scraping found only non-secret `card-list` UI marker hits (`admin-spec-list-phase197.spec.js:222`, `admin-spec-list-phase197.spec.js:228`, `admin-spec-list-phase197.spec.js:230`, `admin-spec-list-phase197.spec.js:268`). |
| No cross-organization row/count leakage | Owner-bearing list and count paths are scoped in query modules and summary queries; Connect owner-scope blocker was fixed and review-cleaned (`197-REVIEW.md:52-74`); tests exclude denied organization rows/counts (`query_modules_test.exs:416-519`, `connect_accounts_live_test.exs:133-168`, `webhooks_live_test.exs:287-370`). |

## Unregistered Flags

None.

`197-03-SUMMARY.md:122-124` names security-relevant surfaces (Webhooks decoder, Connect attention predicate, Charges owner-scope predicate); each maps to declared threats T-197-11/T-197-24, T-197-13/T-197-26, and T-197-03/T-197-12/T-197-20. Other Summary threat-flag sections report no new endpoint, auth path, file access path, package, schema, or trust boundary. No unmapped implementation security surface was found.

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-197-SC | T-197-SC | The phase added a Playwright command but no new package dependency. Existing dependency supply-chain exposure is outside this phase's implementation scope and was explicitly accepted in the PLAN registers. | Phase 197 PLAN register; verified by secure-phase hook | 2026-06-28 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-28 | 32 | 32 | 0 | Codex secure-phase hook |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-28
