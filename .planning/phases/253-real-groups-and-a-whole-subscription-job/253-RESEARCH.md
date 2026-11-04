# Phase 253: Real Groups and a Whole Subscription Job — Research

**Researched:** 2026-10-27
**Domain:** Phoenix LiveView composition and subscription journey
**Confidence:** HIGH for repository source seams; MEDIUM for docs; no runtime proof

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Cover exactly SBK-04, SBK-05, SBK-06, UXQ-01 and UXQ-03: production-shared subscription collection and whole detail-page compositions, mounted list/detail/review/result/return behavior, responsive essential content, and existing copy ownership. Preserve the phase's five roadmap success criteria.
- **D-02:** Keep the production DataTable state, lifecycle and event targeting; share useful presentation through ordinary Phoenix attrs/slots and existing owners. Preserve routed LiveView authority and navigation. Do not introduce a universal page schema or a separate story implementation of production behavior.
- **D-03:** Use Phase 252's deterministic launch/new-account and growing-team situations, disposable lab, compiled discovery and independent kitchen. Stories prove settled presentation only; persistence, dispatch, current scope, refreshed authority, exact target, applicable step-up, dismissal and truthful outcomes require mounted automated evidence.
- **D-04:** Preserve host ownership and provider/authority semantics. Reuse supported action policy, Copy/voice/domain owners, scoped links and legal/replay language. Never invent a provider capability or represent a requested/pending operation as upstream completion.
- **D-05:** Preserve brandbook/ and current Admin semantic-token ownership over older prompts. Essential identities, exact money, state and available actions remain usable at 320 CSS px, meaningful wider/container widths and relevant breakpoint edges in light and dark themes.
- **D-06:** Prefer a small, flat dependency tree. Reuse existing libraries and local patterns; a small local implementation is preferable to adding a dependency for a narrow need. Any proposed dependency needs concrete value beyond existing tools. No dependency or framework change is presumed necessary.
- **D-07:** Use automated acceptance for machine-verifiable behavior, existing merge-blocking owners and evidence with explicit source/runtime limits. Plans must not require confirmation-only manual UAT or treat static screenshots/metadata as proof of persisted effects, authority, provider completion or aesthetic excellence.
- **D-08:** Keep Phase 254's recurring selection/budget freeze, broad accessibility/design assessment, baseline curation and next-job selection in Phase 254. Retain all existing gates and Phase 252 isolation/package boundaries. The known event timestamp correctness candidate remains separate.

### Agent's Discretion

Choose the smallest production-owned component seams, representative supported action journey, state/width/theme matrix, test division and plan sequence after source-grounded research. Prefer coherent recommendations over presenting unresolved menus. Enumerate applicability and tradeoffs; stop additional fan-out when it no longer changes a recommendation, scope, sequence or acceptance. Record remaining assumptions explicitly and distinguish source findings from verified runtime behavior.

### Deferred Ideas (OUT OF SCOPE)

The context has no separate deferred-ideas section. D-08 records its exact deferrals: “Keep Phase 254's recurring selection/budget freeze, broad accessibility/design assessment, baseline curation and next-job selection in Phase 254” and “The known event timestamp correctness candidate remains separate.”
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Required outcome | Research support |
|---|---|---|
| SBK-04 | Real collection toolbar/result/table/pagination for new-host empty, filtered-empty, one/multiple rows and page boundary; source-supported loading/error; intact DataTable lifecycle/events. | Current production composition and mounted/component evidence support a shared list group and retained LiveComponent. [VERIFIED: .planning/REQUIREMENTS.md:16; subscriptions_live.ex:114-220] |
| SBK-05 | Production-shared whole detail page with real areas, supported review/action and incomplete evidence; no copied page or universal schema. | Reuse subscription_area/1 and share only the remaining page body. [VERIFIED: .planning/REQUIREMENTS.md:17; subscription_live.ex:252-333,333-625] |
| SBK-06 | Mounted authorized list → detail → action review/result → context return; current scope/authority/target, applicable step-up, dismissal/no dispatch and truthful outcome. | Add one composed mounted route journey; existing source revalidates actor, scope, record and review fingerprint. [VERIFIED: .planning/REQUIREMENTS.md:18; subscription_live.ex:163-249,1649-1683] |
| UXQ-01 | Essential identity, exact amounts, state and actions at 320 CSS px, wider/container and affected breakpoints in both themes without page overflow or hidden essentials. | Reuse Phase 252 viewport/theme controls; cover the current table/card transition. [VERIFIED: .planning/REQUIREMENTS.md:41; phase252-story-helpers.js:18-20; app.css:3547-3551,4085-4101] |
| UXQ-03 | Existing Copy/voice/domain owners for labels, destinations, consequences and recovery; exact IDs/evidence and locked legal/replay meaning retained. | Reuse Copy.Subscription, ScopedPath and domain result semantics. [VERIFIED: .planning/REQUIREMENTS.md:43; copy/subscription.ex:6-35,81-98; scoped_path.ex:69-128] |
</phase_requirements>

## Summary

SubscriptionsLive.render/1 owns the production collection, while DataTable owns stateful reads and paging. SubscriptionLive owns scoped detail and action confirmation. Recommend small attrs/slots presentation seams, real DataTable preservation, Storybook settled states, and one complete mounted ExUnit journey. [VERIFIED: subscriptions_live.ex:114-220; data_table.ex:6,27-35; subscription_live.ex:252-333,163-249]

## Validation Architecture

Nyquist validation is enabled. [VERIFIED: .planning/config.json:15-20]

| Requirement | Test owner |
|---|---|
| SBK-04 | ExUnit list/DataTable tests plus browser story states. |
| SBK-05 | Production-shared detail story plus content assertions. |
| SBK-06 | One routed LiveViewTest journey using TestRepo and Processor.Fake. |
| UXQ-01 | Playwright exact viewport/theme and overflow/content assertions. |
| UXQ-03 | Existing copy/path owners asserted in ExUnit and browser. |

## Sources

- Official [Phoenix.Component](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.Component.html)
- Official [Phoenix.LiveViewTest](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveViewTest.html)
- Official [Playwright options](https://playwright.dev/docs/test-use-options)
- Official [W3C Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html)

## Planner Decisions and Tradeoffs

| Decision | Recommended choice | Alternative / cost |
|---|---|---|
| Collection composition | Keep SubscriptionsLive as route/filter/scope/query owner; share its actual group with a normal attrs/slots function component only if Storybook needs a callable seam. Keep DataTable a LiveComponent. [VERIFIED: subscriptions_live.ex:58-73,114-220; data_table.ex:6,27-35] | A copied/static table is simpler to story but drops actual lifecycle, cursor behavior and child event targeting. A larger extraction adds risk without reuse value. |
| Detail composition | Reuse subscription_area/1; share only the remaining subscription page body. Keep AppShell, route, current scope and action handlers with SubscriptionLive. [VERIFIED: subscription_live.ex:42-106,252-333,333-625] | A parallel Storybook page drifts on copy, scoped links, eligibility and result state; a universal page schema is expressly out of scope. |
| Evidence split | Storybook/Playwright proves settled composition and responsive content. Mounted ExUnit proves query/scope, freshness, exact target, step-up, dismissal, dispatch and Repo/audit outcomes. [VERIFIED: CONTEXT D-03; CLAUDE.md:201-208] | Driving every action through browser is slower and still needs Repo/Fake assertions. Static stories cannot prove persisted or provider effects. |
| List data | Reuse Phase 252 launch/team facts for detail; use a narrow collection adapter or disposable Repo rows for multi/page-boundary list stories. [VERIFIED: cadence_subscriptions.exs:42-83] | Existing launch/team facts each represent one subscription, so treating them as a multi-row collection is unsupported. Avoid a shared fixture framework. |
| Responsive checks | Extend explicit 320/1280 light/dark evidence; add 767/768 around current CSS switch and a meaningful container width if its rules differ. [VERIFIED: phase252-story-helpers.js:18-20; app.css:3547-3551,4085-4101] | A device preset alone does not prove exact 320 CSS px; testing all states at every extra edge multiplies cost without new responsive behavior. |

## File and Symbol Seams

| File / symbol | Current owner responsibility | Planning consequence |
|---|---|---|
| accrue_admin/lib/accrue_admin/live/subscriptions_live.ex — render/1, handle_event/3, handle_params/3 | Filter patching, route params, current scope and actual collection composition. [VERIFIED: lines 58-110,114-220] | Keep URL and filter authority here. Extract only the collection visual group if Storybook needs it. |
| accrue_admin/lib/accrue_admin/components/data_table.ex — update/2, handle_event/3, render/1 | Stateful query reads, empty/loading/error state, row/card rendering, cursor paging and @myself event targets. [VERIFIED: lines 6,27-35,115-156,202-273,490-594] | Do not substitute stateless markup. Its exact state values are “unavailable”, “loading-skeleton”, “populated”, “filtered-empty”, “first-run-empty”; reasons are “first-run” and “filter”. |
| accrue_admin/lib/accrue_admin/live/subscription_live.ex — subscription_area/1, render/1, confirm_staged_action/1, validate_review/2 | Shared summary area, full detail body, review, scope/freshness checks, step-up and truthful results. [VERIFIED: lines 163-249,252-333,333-625,1649-1683] | Keep action behavior in routed LiveView. One detail-body presentation seam is the maximum justified extraction. |
| accrue_admin/lib/accrue_admin/queries/subscriptions.ex — list/1, detail/2 | Scoped list projection/cursor and scoped exact detail lookup. [VERIFIED: lines 20-72,90-105] | Mounted flow must use these production queries, not a story adapter. |
| accrue_admin/lib/accrue_admin/scoped_path.ex — return_destination/5 | Validates local return origin and reapplies current owner scope. [VERIFIED: lines 69-128] | Preserve this path owner; assert normalized return context. |
| accrue_admin/lib/accrue_admin/copy/subscription.ex | Existing labels, empty/loading copy and action text. [VERIFIED: lines 6-35,81-98] | Stories reuse it; no story-local formatting or eligibility copy. |

Phoenix attrs/slots are the standard explicit function-component contract. Generic example from official docs:

    attr :heading, :string, required: true
    def section(assigns), do: ~H"<section><h2>{@heading}</h2></section>"

[CITED: Phoenix.Component 1.1.31](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.Component.html)

## Strongest Mounted Journey to Add

Existing tests cover the pieces in separate cases: list link context, detail return validation, step-up, dismissal with zero Fake cancellation calls/no event, and changed actor/owner/lifecycle rejection. [VERIFIED: accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs:149-243,369-437,508-598,1084-1100,1397-1475]

Add one routed mounted sequence:

1. Create a uniquely scoped subscription in the disposable TestRepo and mount the real filtered subscription list.
2. Follow the actual subscription row link. Assert detail remains under the owner scope and carries the filtered return origin.
3. Stage existing supported destructive action “cancel_now”; source declares @destructive_actions as “cancel_now comp_subscription remove_item”. [VERIFIED: subscription_live.ex:33-40]
4. Dismiss review/step-up. Assert no Fake dispatch, cancellation event, Repo state change, or stale pending continuation.
5. Restage and pass the existing test step-up adapter. Assert current actor/scope, exact subscription target, one Fake dispatch, audit/result and Repo state.
6. Return through ScopedPath and assert current scope and original filter remain.

Rationale: source stages subscription ID/actor/scope/fingerprint; confirmation reloads current scope and exact detail and checks eligibility/input/fingerprint; destructive work uses StepUp.require_fresh; dismissal clears pending action; result branches distinguish confirmed, pending and error. [VERIFIED: subscription_live.ex:186-210,213-249,146-153,1557-1575,1577-1668]

This is the strongest mounted gap because all authority/side-effect assertions compose in a single route flow. It costs fixture setup but uses TestRepo and Processor.Fake only; no real provider is needed. Existing component tests remain the home for generic pagination/retry edges. [VERIFIED: data_table_test.ex:393-435,472-519,904-947; CONTEXT D-03]

## Phase 252 Assumption Audit

Phase 252 explicitly keeps these four unclassified predicates unresolved as metadata; do not relabel them as satisfied. [VERIFIED: .planning/phases/252-production-backed-subscription-stories/252-VERIFICATION.md:448-477]

| Unclassified assumption | Phase 253 relevance | Disposition |
|---|---|---|
| EDGE-SBK-03-unclassified: parity and 12 rendered cells. [VERIFIED: 252-VERIFICATION.md:454] | Precedent only; phase 252’s summary/facts/action area does not cover collection/full-page composition. [VERIFIED: 252-UI-SPEC.md:28-44] | Preserve shared renderer rule; add phase 253 assertions; keep metadata unresolved. |
| EDGE-SCEN-01-unclassified: scenario facts, adapters, persistence/package boundaries. [VERIFIED: 252-VERIFICATION.md:455] | Directly relevant to reuse launch/team facts and separation of static adapters from Repo fixtures. | Keep separate adapters; add only narrow collection data for many/page-boundary. |
| EDGE-LAB-02-unclassified: package contents, isolated compile and dev/prod routes. [VERIFIED: 252-VERIFICATION.md:456] | Relevant because existing disposable lab is reused. | Preserve Phase 252 lab isolation and package/route boundaries; no package expansion. |
| EDGE-CIQ-01-unclassified: workflow admission and path controls. [VERIFIED: 252-VERIFICATION.md:457] | Boundary reminder for consumed story/component roots. | Keep existing required owners and path controls; no new gate architecture or Phase 254 CI scope. |

## Validation Architecture

Nyquist validation is enabled in .planning/config.json:15-20. [VERIFIED]

| Requirement | Automated evidence |
|---|---|
| SBK-04 | Existing list LiveView test for empty/filtered/one/multiple/loading; DataTable tests for cursor, initial/partial failure, retry and 125-row boundary; add collection story cases. [VERIFIED: subscriptions_live_test.ex:214-322; data_table_test.ex:393-435,472-519,904-947] |
| SBK-05 | Production-shared detail body story and required-content assertions; existing area remains the production base. [VERIFIED: subscription_live.ex:252-333,333-625] |
| SBK-06 | One mounted routed journey above using TestRepo and Fake; keep all actor/scope/dispatch assertions in ExUnit. [CITED: Phoenix.LiveViewTest 1.1.31](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveViewTest.html) |
| UXQ-01 | Existing Playwright story owner with explicit viewport/color scheme, page overflow and essential-content assertions. [CITED: Playwright use options](https://playwright.dev/docs/test-use-options) |
| UXQ-03 | Copy/path/result assertions in ExUnit and visible label/destination assertions in browser; exact IDs remain test evidence. |

Use existing Phase 252 command patterns, extending the owned spec selection to Phase 253:

    cd accrue_admin && mix test test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/components/data_table_test.exs
    cd accrue_admin && mix test
    cd accrue_admin && npm run phase252:check
    cd accrue_admin && npm run phase252:browser

The package scripts exist at accrue_admin/package.json:49-52; the Phase 252 Playwright config is serial, uses one worker and refuses server reuse at accrue_admin/playwright.phase252.config.js:26-48. Add the Phase 253 spec to this owner/config or its same-owner selector before claiming the commands cover Phase 253. [VERIFIED]

No framework/dependency Wave 0 is needed. The command recommendations above were not executed in research; no app/test was booted. CLAUDE.md requires automated acceptance, no confirmation-only UAT, and positive controls for absence claims. [VERIFIED: CLAUDE.md:201-208,233-245]

## UX, Security and Evidence Limits

- Preserve Admin semantic token ownership; tokens.json is source of truth and tokens.css is generated. Reuse voice and Copy.Subscription for exact, measured labels/recovery. [VERIFIED: brandbook/tokens/README.md:9-16,28-46; brandbook/voice.md:7-33; copy/subscription.ex:6-35,81-98]
- Use explicit 320/1280 light/dark widths and targeted 767/768 CSS edge. W3C WCAG 2.2 Reflow identifies 320 CSS px; local two-dimensional scrolling does not justify page-wide overflow or hidden essentials. [VERIFIED: phase252-story-helpers.js:18-20; app.css:3547-3551,4085-4101] [CITED: W3C Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html)
- Relevant OWASP ASVS 5.0.0 chapters: V2 validation/business logic, V6 authentication, V7 session management, V8 authorization, and V1 encoding/sanitization. Preserve scoped queries, fresh review authority, validated return paths and truthful pending results. No new crypto work is proposed. [CITED: ASVS 5.0](https://asvs.owasp.org/); [CITED: ASVS v5 chapter index](https://github.com/OWASP/ASVS/tree/master/5.0/en); [VERIFIED: queries/subscriptions.ex:20-72,90-105; subscription_live.ex:1577-1683; scoped_path.ex:69-128]
- Environment probes: Elixir/Mix 1.19.5, Node 22.14.0, npm 11.1.0, Playwright CLI 1.59.1; pg_isready responded on /tmp:5432. Chromium binary and disposable-lab ownership were not verified; no app/database was connected. [VERIFIED: read-only probes 2026-10-27]
- Storybook docs fetched here resolve to v1.3.0 while repository lock is 1.2.0. Treat local lock/source as authoritative and make story compilation an early implementation check. [VERIFIED: accrue_admin/mix.lock:70] [CITED: PhoenixStorybook Story](https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Story.html)
- A1 [ASSUMED]: PhoenixStorybook 1.2.0 can render these seams with a narrow deterministic query adapter; if it cannot, resolve within current story owner. A2 [ASSUMED]: phase252 validator/config accepts a phase253 spec; if frozen, add same-owner selection, not new gate architecture.

## Numbered Sources

1. [Phoenix.Component 1.1.31](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.Component.html) — attrs/slots and function components.
2. [Phoenix.LiveViewTest 1.1.31](https://phoenix-live-view.hexdocs.pm/1.1.31/Phoenix.LiveViewTest.html) — connected/disconnected mount and rendered event testing.
3. [PhoenixStorybook Story](https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Story.html) — story kinds/example guidance; observed docs version 1.3.0, repo lock 1.2.0.
4. [Playwright Test use options](https://playwright.dev/docs/test-use-options) — explicit viewport and color scheme.
5. [W3C WCAG 2.2 Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) — 320 CSS-px reflow and local two-dimensional content.
6. [OWASP ASVS 5.0.0](https://asvs.owasp.org/) and [v5 chapter index](https://github.com/OWASP/ASVS/tree/master/5.0/en) — current security chapter names.

Evidence limits: Context7 was unavailable, so official docs were browsed directly. Local source/lock inspection and read-only version/readiness probes were performed. No Phase 253 code, test, visual render, app boot, fixture mutation or provider operation was performed. Research confidence is HIGH for source seams, MEDIUM for external guidance, and no runtime claim is made.
