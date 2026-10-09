# Phase 239 component and state evidence reconciliation

**Inspected source:** local `1cd7a3de34473a5d285bc5fa14a6ca10b6522560` before Plan 239-03 edits. This is a local-source inventory, not a remote CI observation.

## Registry-derived component and example disposition

Source of truth is `AccrueAdmin.Dev.ComponentRegistry.entries/0`; counts and order below were read from the live registry with `MIX_ENV=test mix run`. The two derived contracts were run locally. The tables are a dated disposition of that source, not a second allowlist.

| Family | Registry variants in source order | Example / disposition |
|---|---|---|
| button | primary, secondary, ghost, danger | Each variant has a specimen in the registry; `/dev/components` render and component Storybook variation derive from those entries. |
| input | text | Registry specimen; derived component variation. |
| textarea | default | Registry specimen; derived component variation. |
| checkbox | default | Registry specimen; derived component variation. |
| radio | default | Registry specimen; derived component variation. |
| toggle | default | Registry specimen; derived component variation. |
| theme-picker | segmented | Registry specimen; derived component variation. |
| segmented | filter | Registry specimen; derived component variation. |
| stat-strip | inline | Registry specimen; derived component variation. |
| timeline | threaded | Registry specimen; derived component variation. |
| select | default | Registry specimen; derived component variation. |
| form-field | wrapper | Registry specimen; derived component variation. |
| status | moss, cobalt, amber, slate, ink | Each variant has a specimen; derived component variations. |
| icon | md | Registry specimen; derived component variation. |
| money | display | Registry specimen; derived component variation. |
| json-viewer | tree | Registry specimen; derived component variation. |
| spinner | sm | Registry specimen; derived component variation. |
| tooltip | above | Registry specimen; derived component variation. |
| inline-id | short | Registry specimen; derived component variation. |
| id-badge | default | Registry specimen; derived component variation. |
| empty-state | no-data | Registry specimen; derived component variation. |
| card | base, moss, cobalt, amber, slate, ink | No per-entry `specimens` field (6/6). These are class/token registrations; their rendered contexts are represented by group contracts such as `kpi-chart-table`, and every registry variant still receives a derived coverage row. No empty example file or fake specimen is implied. |
| foundation-type | roles | No specimen: typography role/token metadata, represented in derived registry coverage. |
| foundation-measure | prose | No specimen: measure token metadata, represented in derived registry coverage. |
| foundation-layer | stack | No specimen: layer token metadata, represented in derived registry coverage. |
| foundation-focus | control | No specimen: focus token metadata, represented in derived registry coverage. |
| foundation-disabled-readonly | states | No specimen: semantic token metadata, represented in derived registry coverage. |
| foundation-interactive | states | No specimen: semantic token metadata, represented in derived registry coverage. |
| foundation-scrollbar | root | No specimen: scrollbar token metadata, represented in derived registry coverage. |
| foundation-status | roles | No specimen: status token metadata, represented in derived registry coverage. |

The registry contains 30 families / 42 family-variant entries and 8 ordered group contracts. `storybook/components/component_registry.story.exs` derives its rows, variants, applicable and N/A states, and variation IDs from the registry. `storybook/groups/component_groups.story.exs` derives group proofs from `group_contracts/0`. `component_registry_test.exs` checks rendered variant classes, component outputs, token definitions/rendering, state metadata and specimen/state structure; `storybook_coverage_test.exs` checks family/variant/order, state sets, variation IDs, group examples and avoids hardcoded totals. The empty specimen fields above are intentional for class/token metadata and are not missing family or variation rows.

## Adopter document reconciliation

| Document | Current claim and source relationship | Disposition |
|---|---|---|
| `accrue_admin/README.md` | Names package ownership and `/dev/components` as a dev-only route; it does not publish a duplicate exhaustive family/variant list. It points adopters to the package UI guide and host example. | No mismatch: route/ownership statements agree with the registry source boundary. No static inventory to maintain. |
| `accrue_admin/guides/admin_ui.md` | Describes package mount, authored token/class conventions, explicit empty/loading/error list states, browser regression path, and dev-only surfaces. It does not claim every state applies to each primitive. | No mismatch: guidance is a usage contract and remains compatible with registry `applicable_states` / explicit `na_states`. |
| `accrue_admin/guides/spec-list.md` | Specifies list-archetype populated, first-run empty, filtered-empty and loading states plus filter and pagination behavior, with its own verification-source descriptions. | No mismatch: scoped list-page contract; it does not replace component-level state metadata or claim that all components support all four states. |

`bash scripts/ci/verify_package_docs.sh` passed, including its existing source/documentation guards. No adopter-facing component or supported-state claim requires correction.

## INT-04 state evidence owners

Evidence layer describes what the check actually observes: ExUnit is deterministic server/component behavior; LiveView tests assert rendered server HTML/events; Playwright observes a real browser render/interaction. A row in the route ledger or historical report is not represented as a newly run test here.

| State family | Current evidence owner | Evidence layer and scope |
|---|---|---|
| empty | `accrue_admin/test/accrue_admin/live/customers_live_test.exs`, `examples/accrue_host/test/accrue_host_web/portal_cold_start_test.exs`, Portal `home_live_test.exs`; linked route owners in `239-COVERAGE.md` | LiveView/server-rendered empty behavior; Phase 239 smoke covers only its named settled representative render. |
| no-match | `accrue_admin/test/accrue_admin/live/events_live_test.exs`; `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` | ExUnit list/search outcome plus Playwright rendered event-search empty result. |
| unavailable | Admin `coupons_live_test.exs`, Portal `invoices_live_test.exs` and named route suites in `239-COVERAGE.md` | ExUnit/LiveView unavailable-vs-empty branches; no assertion infers availability from the representative screenshot. |
| unsupported | Admin `connect_account_live_test.exs` and `connect_accounts_live_test.exs`; Phase 238 currency/provider cases summarized in `238-REVIEW-FIX.md` | ExUnit/LiveView partial-known-facts and unsupported-value behavior; browser screenshot is not used as the detailed owner. |
| denied | `accrue_portal/test/accrue_portal/live/blocked_live_test.exs`; Admin route authorization tests | ExUnit/LiveView boundary result and denial copy, distinct from empty/unavailable. |
| pending | Portal `add_payment_method_live_test.exs` and `checkout_live_test.exs`; Phase 236/238 host browser flows listed in `239-COVERAGE.md` | ExUnit for deterministic pending/action transitions; Playwright for visible pending feedback, duplicate-submit prevention and focus/interaction behavior. |
| error | Route-owning Admin and Portal `*_live_test.exs` rows in `239-COVERAGE.md`, including event, invoice, and payment-method suites | ExUnit/LiveView safe error/recovery and read-failure distinction; Phase 238 browser spec covers named recovery interactions, not every error branch. |
| long-content | `examples/accrue_host/e2e/phase236-portal-self-service.spec.js`, `phase237-admin-billing.spec.js`, and `phase238-admin-events-webhooks.spec.js` | Playwright rendered layout, discoverability and action containment for actual long identifiers/labels; route tests retain server data assertions. |

The family mapping above preserves existing Phase 234–238 owners and the per-route evidence ledger. Browser proof is assigned only to layout, focus, and actual interaction outcomes that require a browser. Live-provider fidelity remains outside fake-backed local evidence; remote CI remains unobserved.

## Gap findings for conditional closure

| Status | Gap class | Finding |
|---|---|---|
| NO-GAP | registry/example | Derived contracts cover all 30 families, 42 variants, and 8 ordered group contracts. Empty specimens are explicitly classified above; no family/variant row is missing. |
| NO-GAP | adopter-document | README and guides make no competing static component inventory or unsupported universal-state claim; package-doc verifier passes. |
| NO-GAP | state-family | All eight INT-04 families have a named current evidence owner and appropriate evidence layer above and in `239-COVERAGE.md`. |

## Task 2 disposition

No additional assertion or documentation correction required. No demonstrated gap remains open; Task 2 therefore requires only the report completeness check and does not repeat Task 1 suites.

