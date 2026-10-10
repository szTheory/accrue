---
phase: "241"
slug: "billing-operator-journeys"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 241 — Security

Authored register verified by the independent security auditor at ASVS L1, with `block_on: high`. All 17 mitigations are closed; one explicitly documented low-severity dependency risk is accepted.

## Trust Boundaries

| Boundary | Description | Data crossing |
|---|---|---|
| Browser/routes → Admin LiveView | Untrusted URLs, events and reconnect state meet current actor/owner records | Local return routes, filters, target IDs, staged intent |
| Reviewed action → provider | Fresh authorization and record checks precede dispatch | Exact amount/action and selected customer/record |
| Disposable host → test observability | Authenticated SQL-sandbox-only counter endpoint | Fake callback counts; no secrets or provider payloads |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / evidence | Status |
|---|---|---|---|---|---|---|
| T-241-01 | Tampering | Subscription invoice links | high | mitigate | `subscription_live.ex:2490`; exact customer and excluded-owner membership in `query_modules_test.exs:223` | closed |
| T-241-02 | Information Disclosure | Related invoice group | medium | mitigate | Current owner scope in subscription links and invoice queries; excluded-owner assertions | closed |
| T-241-03 | Spoofing | ScopedPath return destination | high | mitigate | Local route/mount validation and fresh-owner rebuilding in `scoped_path.ex:91`; hostile URL controls | closed |
| T-241-04 | Elevation of Privilege | Customer detail return | high | mitigate | Loaded customer ID comparison in `scoped_path.ex:92`; wrong-customer/cross-mount rejection | closed |
| T-241-05 | Tampering | Decoder parity | medium | mitigate | Consumed-filter allowlists in `scoped_path.ex:7`; retained filters and dropped unsupported sort tests | closed |
| T-241-06 | Elevation of Privilege | Payment/subscription return callers | high | mitigate | Validated destination pairs in charge/customer/subscription callers; current owner and customer controls | closed |
| T-241-07 | Repudiation | Repeated detail navigation | medium | mitigate | Staged navigation, reopen/dismiss and stale confirm remain at zero Fake dispatch in `subscription_live_test.exs:589` | closed |
| T-241-08 | Spoofing | Campaign return | high | mitigate | Recovery-only return validation in `campaign_live.ex:49`; direct and hostile origin cases | closed |
| T-241-09 | Information Disclosure | Recovery window/owner links | medium | mitigate | Current owner plus supported selected window in `at_risk_table.ex:201`; window decoder and round-trip tests | closed |
| T-241-10 | Tampering | Subscription staged action | high | mitigate | Fresh actor, owner, target, eligibility, input, step-up and fingerprint at confirmation; stale controls | closed |
| T-241-11 | Repudiation | Subscription repeat/reconnect | high | mitigate | Submitted/uncertain states plus Fake counts, repeated confirmation and reconnect controls | closed |
| T-241-12 | Tampering | Refund intent | high | mitigate | Integer amount parsing and current charge, currency, remaining balance, actor/owner checks; boundary tests | closed |
| T-241-13 | Elevation of Privilege | Payment-method action | high | mitigate | Fresh customer/method reload and reviewed-state comparison; foreign/stale targets denied | closed |
| T-241-14 | Repudiation | Action result/reconnect | high | mitigate | Direct Fake callback counts for refund/method actions, timeout and APIError HTTP500 guidance, no repeat/reconnect dispatch; `charge_live_test.exs:645`, `customer_live_test.exs:454` | closed |
| T-241-15 | Tampering | Mounted billing journey | high | mitigate | Scoped exclusion and authenticated sandbox-only Fake counter; mounted Escape dismissal measured `invoice_action` 0→0 | closed |
| T-241-16 | Information Disclosure | Served evidence/fixtures | medium | mitigate | Test-only fixture seam; bounded provenance/hash/counter manifest without secrets/provider payloads | closed |
| T-241-17 | Tampering | Admin package CSS spacing | low | mitigate | Approved 4px token is used in both action gaps; package assets test verifies served CSS bytes equal the compiled package asset. Plan 08 records source/built/compiled/package-served identity; host-served identity remains unobserved. | closed |
| T-241-SC | Tampering | Package supply chain | low | accept | Existing package supply-chain exposure is unchanged by Plan 08; package source and compiled CSS bytes are verified, but this does not establish external provenance or remote CI. Accepted as a bounded dependency risk under Plan 08. | accepted |

Implementation paths above are relative to `accrue_admin/lib/accrue_admin/` and owning tests to `accrue_admin/test/accrue_admin/`. Host counter guards are in `examples/accrue_host/lib/accrue_host_web/router.ex:54` and `controllers/organization_scope_controller.ex:98`. Mounted assertions are in `examples/accrue_host/e2e/phase237-admin-billing.spec.js:306`.

## Accepted Risks Log

| Threat ID | Risk | Severity | Acceptance | Boundary |
|---|---|---|---|---|
| T-241-SC | Package supply-chain provenance beyond locally verified package source/build/compiled bytes | low | Accepted in 241-08-PLAN.md | No claim of external provenance, remote CI, or host-served identity for Plan 08. |

## Security Audit Trail

| Date | Total | Closed | Blocking open | Result |
|---|---|---|---|---|
| 2026-10-10 | 16 | 13 | 2 | Independent audit found T-241-07/14/15 acceptance gaps; repaired without accepting risk |
| 2026-10-10 | 16 | 15 | 1 | Recheck found APIError message path bypassing uncertainty guidance |
| 2026-10-10 | 16 | 16 | 0 | APIError negative regression reproduced then fixed; independent recheck SECURED |
| 2026-10-10 | 18 | 17 | 0 | Plan 08 audit: T-241-17 mitigated by tokenized package CSS and asset-byte controls; T-241-SC explicitly accepted as low risk. |

## Executed Evidence and Limits

- Focused charge/customer/subscription owners: 80 tests, 0 failures before the additional HTTP500 control.
- Final Admin warnings-as-errors compile passed; complete Admin suite: 646 tests, 0 failures.
- HTTP500 test failed before the product correction, then passed in the full suite. Unknown APIError uses reconciliation guidance; the two recognized blocked-action codes retain domain copy.
- Mounted Chromium host proof: 1 passed; observed Fake count 0→0. Fresh screenshots and count-bearing manifest are in `evidence/phase237-exemplar/`.
- The host proof covers staged invoice review and Escape dismissal, with disposable Fake fixtures. It does not claim live-provider or physical-device observations.
- `241-SECURITY-FIX.md` records exact repairs and commits. The summary's `test_only_observability` flag maps to T-241-15; no unregistered flag remains.

## Sign-Off

- [x] Every authored threat has an implemented mitigation and evidence.
- [x] No accepted-risk bypass.
- [x] `threats_open: 0`.
- [x] Independent security auditor returned SECURED on 2026-10-10.
