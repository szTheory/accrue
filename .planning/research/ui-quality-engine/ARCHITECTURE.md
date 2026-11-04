# UI quality engine: composition and runtime boundaries

**Date:** 2026-10-26. **Status:** research for a reviewed proposal; no implementation or milestone activation.

## Evidence and applicability

Accrue publishes two real UI packages, so the methodology applies beyond the example application. `PRODUCT.md` identifies engineers and support/billing operators as equal primary Admin users, customers as Portal users, and host applications as owners of authentication, membership policy, sessions, Repo, supervision and secrets. Stories must preserve those distinctions.

This report inspects checked-in source, installed PhoenixStorybook source and official documentation. It does **not** claim that any screen was mounted, any screenshot inspected or any browser/ExUnit suite passed during this research. The registry count below was executed independently of the application or database.

### Measured composition inventory

| Surface | Current evidence | Meaning and gap |
|---|---|---|
| Admin pages | **21** `.ex` files under `accrue_admin/lib/accrue_admin/live/` | Dashboard; nine entity list/detail pairs (customers, subscriptions, invoices, payments/charges, coupons, promotion codes, Connect, events, webhooks); Recovery and Campaign analytics. All are mounted production owners. |
| Portal pages | **8** `.ex` files under `accrue_portal/lib/accrue_portal/live/` | Home, subscriptions, subscription, invoices, payment methods, add-payment-method, checkout, blocked. No Portal story files were found in the configured tree. |
| Admin components | **46** `.ex` files under `accrue_admin/lib/accrue_admin/components/` | Includes stateless functions and real stateful components; a file count is not a claim of one public component per file. |
| Story content roots | **1** configured root: repo `storybook/` | `accrue_admin/lib/accrue_admin/dev/storybook.ex:15` resolves `../../../../storybook` to the repo root. `accrue_admin/storybook/_support/` is compiled helper code, not another content root. |
| Actual stories | **8** `.story.exs` files | `button`, `detail`, `page_header`, `action_menu`, `overlay`, `subscription_detail`, and two aggregate index pages. |
| Registry | **30 families, 42 entries, 75 specimens, 8 group contracts** | Runtime evaluation of `ComponentRegistry.entries/0` and `group_contracts/0`. Counts describe metadata/specimens, not 75 independently reachable production compositions. |
| Small groups | `storybook/groups/component_groups.story.exs:36` | Its render builds metadata cards: component names, required-state strings, hierarchy, selectors and proof-marker attributes. It does **not** render the described toolbar/table/modal/etc. groups. A marker alone is not composition coverage. |
| Section/screen exemplar | `storybook/components/subscription_detail.story.exs:40` | A story-owned reconstruction with fixed July 2026 dates and copied action/copy helpers. Production `SubscriptionLive.render/1:253` uses different current presentation, scoped destinations, eligibility, staged actions and outcomes. Useful historical example; insufficient current screen parity. |
| Other stories | Five direct component/wrapper story files | Button uses `RegistryStory.variations_for("button")`. Detail, PageHeader, action menu and overlay have curated examples. Aggregate `component_registry.story.exs` lists coverage data; it does not render all 75 specimens. |

Count method: recursive `.ex`/`.story.exs` file enumeration; registry loaded using `elixir -e 'Mix.start(); Mix.env(:dev); Code.require_file("accrue_admin/lib/accrue_admin/dev/component_registry.ex"); ...'`. Initial attempt without `Mix.start()` failed on Mix's ETS state; the reported numbers come from the corrected successful command. This was a pure metadata execution, not UI verification.

### Page ownership and proposed story tier

| Actual owner(s) | Job | Suitable next seam |
|---|---|---|
| `dashboard_live.ex` | Locate a customer or decide what needs attention | Production PageHeader/stat/attention area; full screen only after area reuse is proved. |
| `customers_live.ex`, `subscriptions_live.ex`, `invoices_live.ex`, `charges_live.ex`, `coupons_live.ex`, `promotion_codes_live.ex`, `connect_accounts_live.ex`, `events_live.ex`, `webhooks_live.ex` | Find/filter a bounded queue, interpret status, open the right object | Shared header + filter toolbar + list-status + real DataTable composition; entity-specific slots remain supplied by their real owners. |
| `customer_live.ex`, `subscription_live.ex`, `invoice_live.ex`, `charge_live.ex`, `coupon_live.ex`, `promotion_code_live.ex`, `connect_account_live.ex`, `event_live.ex`, `webhook_live.ex` | Understand one object and take a supported action | Real summary/facts/action/related-resource areas, then screen composition. Preserve evidence and action differences instead of creating one universal detail schema. |
| `analytics/recovery_live.ex`, `analytics/campaign_live.ex` | Understand exposure and a recovery history | Currency-qualified metrics + status/timeline composition, sourced from realistic lifecycle scenarios. |
| Portal `home_live.ex`, `subscriptions_live.ex`, `subscription_live.ex`, `invoices_live.ex`, `payment_methods_live.ex`, `add_payment_method_live.ex`, `checkout_live.ex`, `blocked_live.ex` | View/act for an authorized billed account | Customer-language, host-branded presentation stories; host-context selection, permission freshness and provider-return routes remain mounted tests. |

This table inventories owners and candidate seams, not a freshly verified component call graph for every page. First execution should generate that mapping from actual HEEx calls and mark each reachable scenario, unsupported state and owning test explicitly.

## Adopt, extend or introduce

| Capability | Disposition | Existing owner / proposed change |
|---|---|---|
| Component and group vocabulary | **ADOPT-EXISTING** | `ComponentRegistry`, `RegistryStory`, current components and production PageHeader/Detail compositions. |
| Useful rendered coverage | **EXTEND** | Render actual specimens and real grouped UI; stop equating index rows or `data-component-group` attributes with exercised compositions. |
| Product-shaped navigation | **EXTEND** | Installed `PhoenixStorybook.Entries` supports recursive folders and `.index.exs` labels. Organize by job/section with primitive links; no extra navigation framework. |
| DB-free scenarios | **EXTEND** | Curate existing ordinary/hero/held-out scenarios; share pure scenario definitions with renderer and seed adapters, keeping persistence separate. |
| Production presentation seams | **EXTEND selectively** | Shared function components for useful visual areas; retain stateful components where they own real interaction state. No universal page renderer. |
| Machine-readable story/scenario join | **NEW small adapter** | Derive from installed backend `content_tree/0`, `leaves/0`, `load_story/1`, story type and nested variations. Add scenario IDs, caller/source path, tier, job, theme/viewport applicability and explicit test ownership. |
| Mounted interaction proof | **ADOPT-EXISTING** | LiveView tests, existing Admin endpoint, host acceptance and browser tests. Stories supplement rather than replace these owners. |
| Review host | **ADOPT now; EXTEND later** | Immediate Admin lab uses existing `AccrueAdmin.TestEndpoint`; combined Portal lab needs explicit dev/test wiring. Do not flip canonical host dev flags. |
| Existing kitchen | **ADOPT-EXISTING** | Keep deterministic `/dev/components` renderer and its contracts. Consolidate human discovery around Storybook without destroying the other renderer's proof role. |
| Judge/ratchet machinery | **ADOPT selectively** | Existing parked ratchet and archived judgments are references/calibration material. No new judge service, CI API key or automatic revival. |

## Recommended first vertical slice

Start with **understand a subscription and identify the available next action**, then prove **find that subscription in a bounded queue**. This gives a real component → small group → section → screen ladder, with useful production work at every step.

1. Curate a handful of existing lifecycle scenarios: ordinary active, genuinely past due, scheduled cancellation, missing projection, supported Braintree differences, empty filtered queue, page boundary and a realistic long multilingual identity. Add each only where the actual owner can render it. Do not construct every persona × provider × state combination.
2. Extract the **Subscription summary/facts/action-band area** into one package-owned presentation function used by `SubscriptionLive` and its stories. Move presentation-only helpers with it. Keep production eligibility and scoped-link computation authoritative; pass their computed results explicitly or call the same pure production helper. The story must not invent its own `action_groups/1` or provider-pruning rules.
3. Replace the copied Phase195 exemplar with that shared composition. Include one full production-shaped screen composition once the area contract is sound; clearly separate a visual action state from an executed action.
4. Render a real **PageHeader + toolbar + result-status + DataTable** group using one representative production list. `CustomersLive.render/1:89` already separates PageHeader's toolbar slot from DataTable's own toolbar and passes current owner scope, query module, params, columns and responsive card renderers. Preserve that relationship; do not create a story-only reimplementation.
5. Use the actual DataTable LiveComponent in a small deterministic story harness for stateful examples. Its existing query seam can use a tiny scenario-backed implementation of the documented calls if this remains small and faithful; if it requires a broad fake database, keep the scenario in mounted integration tests. Extracting a pure table body is justified only if production also consumes it and lifecycle behavior remains intact.
6. Join each story to the actual production owner and retain mounted proof for open/close, filters, pagination, retry, confirmation and dispatch. Demonstrate with a negative control that changing a real presentation breaks the corresponding story assertion/screenshot, and that a bogus metadata marker alone cannot satisfy coverage.

Success is fewer independent render implementations and faster inspection of a real job, not a larger number of stories.

## Boundary rules

### Pure render data and real state

Function components are appropriate for data-to-markup composition with declared attributes/slots. Keep explicit assigns so LiveView change tracking remains meaningful; avoid a giant opaque `page` map, indiscriminate `{assigns}` forwarding, hidden global reads, or a new presentation DSL. Use small view data only when it makes an actual area clearer. Preserve the vocabulary in `Copy`, `BillingPresentation`, `ScopedPath` and the processor support matrix.

DataTable is a real LiveComponent (`components/data_table.ex:6`), with `update/2`, paging, retry, selection, polling and `@myself`-targeted events. Its lifecycle is not a defect to refactor away for Storybook. Likewise, overlay hooks, step-up, reconnect and event-driven focus need a browser/runtime owner. A presentational story may show their settled state, but cannot prove those behaviors.

The installed PhoenixStorybook 1.2 source supports `:component`, `:live_component`, `:page` and `:example` stories. Examples run as child LiveViews and cannot implement routed `handle_params/3`. Its iframe route is type-sensitive; `:page` content is not automatically a component variation. Generate URLs through the installed behavior and validate them instead of appending one universal iframe query to every metadata row. Prefer eager test compilation for manifest generation: dev compilation is lazy by default, whereas non-dev mode is eager (`deps/phoenix_storybook/lib/phoenix_storybook.ex:199`).

Official component, lifecycle and testing guidance supports these boundaries: [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html), [Phoenix.LiveComponent](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html), [Phoenix.LiveViewTest](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html). The current web docs redirected to LiveView 1.2.13 during research, so use them for the established conceptual boundary only; the installed locked version is implementation authority, and this proposal does not upgrade dependencies. For Storybook, inspect the installed `accrue_admin/deps/phoenix_storybook/lib/phoenix_storybook/stories/story.ex`, `entries.ex`, `router.ex` and `live/story/component_iframe_live.ex`; [the official story source documentation](https://preview.hex.pm/preview/phoenix_storybook/show/lib/phoenix_storybook/stories/story.ex) explains the child-LiveView/example limitation. [Official sandboxing guidance](https://hexdocs.pm/phoenix_storybook/sandboxing.html) explains shared JS/style context and iframe tradeoffs; the unversioned web page is older, so do not copy its installation recipe.

### Evidence that must remain mounted

| Concern | Story can establish | Required actual-runtime owner |
|---|---|---|
| Summary/status/empty/error hierarchy | Shared production markup under a valid scenario | Component rendering + rendered browser checks. |
| Query and tenant/account scope | Presentation of the computed scope | Repo-backed LiveView/host tests; foreign-object and stale-context negative controls. |
| Filters/cursors/live patch navigation | Settled controls/results, responsive composition | Actual params parsing, query seam, page boundaries, selection and focus after patches. |
| Confirmation/step-up/dispatch | Consequence wording and settled form state | Fresh authorization/eligibility, signed context, exact target, dispatch count and truthful outcome. |
| Hosted checkout/Portal management | Capability-aware CTA and return state | Exact provider scope, return token validation and host policy. No live processor calls in stories. |
| Reconnect/poll/retry/async search | Valid initial/partial/unavailable visual states | Real lifecycle, races, stale completion handling and keyboard/focus behavior. |
| Mobile/dark/focus/hook behavior | Actual shipped CSS/JS on shared composition | Browser at real content widths, themes and motion settings; browser/chrome/iframe geometry must be explicit. |

### Host and package safety

`accrue_admin/mix.exs:31` compiles `storybook/_support` only in dev/test; `:phoenix_storybook` is `only: [:dev, :test]` at line 46. The package file list includes `lib`, config/guides, static assets and metadata, **not** repo `storybook/`, helper roots or tests. Existing `lib/accrue_admin/dev/*.ex` source is packaged but conditionally defines modules outside prod; that does not make it a suitable home for realistic fixture data that must stay out of tarballs.

The Admin test router enables dev routes at `/billing` (`test/support/live_case.ex:8`). The canonical example host explicitly uses `allow_live_reload: false` for both ordinary and SQL-sandbox mounts (`examples/accrue_host/lib/accrue_host_web/router.ex:162,184`) and declares no top-level PhoenixStorybook dependency. The package dev-only dependency is not a guarantee that a downstream application's dependency compilation will include its dev/test tooling. `storybook_asset_test.exs:49` deliberately asserts that the canonical host router contains neither `live_storybook` nor `/dev/storybook`.

**Immediate choice:** keep the existing test-endpoint lab as the one review surface for the first Admin slice. Bind local tooling to loopback and use entirely synthetic data. Its separate Storybook live_session uses `PhoenixStorybook.Mount`, not Admin's normal auth hooks; a shared browser pipeline does not imply inherited Admin authorization. Do not expose this lab as an operator surface or publicly accessible preview by assumption.

**Later combined Admin/Portal choice:** if the curated jobs require a shared host, add an explicitly opted-in dev/test-only review router/backend under host support paths, leaving the canonical router's mounted product contract intact. Declare the already-used PhoenixStorybook package as a direct dev/test edge of that harness, with a written reason; do not add a second Storybook implementation or runtime transitive dependency. Ensure the harness loads current package components and assets, explicit synthetic context and scoped links. If a separate process/endpoint is clearer than conditional routes, prefer that bounded harness. Test prod compilation/route absence, absent-dependency compilation, package contents and asset identity before adopting it.

Keep one pure scenario source outside all published `files` lists. Existing story support, tests and host seed adapters consume it; persistence stays in adapters. Resolve its compilation/loading owner once. Do **not** append the same shared module directory to every Mix project's `elixirc_paths`: dependency and host compilation can redefine modules, and deployed packages cannot rely on a monorepo-relative source file. A data-first scenario file with thin existing dev/test adapters is a valid small solution; the fixture research should select the exact form. Prove no import/reference survives into prod modules and no fixture/secrets appear in package contents. No runtime dependency on test support.

## Recorded conflicts and recommended reconciliation

1. Methodology: **“Any second inventory (a gallery page, a component catalogue) gets ported, then retired.”** Locked 193-CONTEXT D-15: **“Registry stays SSOT; the kitchen stays.”** Locked 200-CONTEXT D-10: **“Do not move Phase-189/190 drift tests to Storybook. Storybook is the human-facing design lab; `/dev/components` is the deterministic second renderer.”** Keep the kitchen now, consolidate human discovery and shared renderers, and make later retirement conditional on an explicit decision plus equivalent migrated proof. Do not delete a useful independent integration renderer merely for inventory purity.
2. Methodology: **“Move each LiveView's render body into a presentational function component that takes assigns.”** Actual architecture includes stateful DataTable, lazy evidence, routed params, scope freshness and step-up. Interpret the request as selective useful composition first. A mechanical extraction of all 29 pages increases churn and can lose event/identity boundaries without providing reuse.
3. Methodology: screen stories have **“no DB, session or router.”** Treat this as the default for pure presentation. Do not claim DB-free stories prove account selection, authorization or router semantics; record required mounted complements rather than mocking the missing contract.
4. User's broad UI ambition is an explicit strategic direction; `PROJECT.md` still says stable-core/demand-driven and closes broad feature expansion by default. This proposal improves existing surfaces and proof; it does not introduce diagnosis rooms, new billing capabilities, provider parity, rebranding, or restart the parked paid AI ratchet.

## Ordered implementation horizons

| Horizon | Deliverable | Exit condition / stop rule |
|---|---|---|
| Immediate proposal | Reconcile inventory, curate scenarios/JTBD, define first two real production compositions and proof split | One reviewed scope with explicit exclusions and no code changes. |
| Immediate milestone candidate | Shared Subscription area + real list group + useful scenario manifest + focused mobile/theme checks | Both stories call production render owners; representative valid states and mounted actions checked; negative controls prove non-vacuous coverage; measured local/CI runtime. |
| Near term | Expand recurring list/detail/recovery groups by risk; add Portal host-context examples through an explicit dev/test harness | Every added story has a caller/job and independent test ownership; no mock platform, new runtime dep or duplicated UI. |
| Mid term | Complete prioritized whole-job screens and journeys; migrate remaining duplicated renderers/helpers only where value is proved | Coverage ledger joins actual pages, scenarios and mounted tests; obsolete states pruned with reasons. |
| Long term | Routine pruning, provider/support evolution, calibrated bounded design review | Repeatable quality budget and evidence remain useful; no story-count targets, open-ended critic loops or all-permutation sweeps. |

## Adversarial pass

| Objection | Risk | Recommendation / boundary |
|---|---|---|
| “Storybook will become the second app.” | Copied screens, fake eligibility, dead routes and stale hardcoded examples. | Every story must call a production renderer and name its caller; pair it with a small mounted proof. The Phase195 copied screen is the concrete warning. |
| “A component extraction will hide a security regression.” | Context disappears into a view model or a story helper becomes authority. | Compute permission and exact scope in existing owners; actions revalidate when handled. Pass only presentation decisions, never grant authority from fixtures. |
| “A single pure page abstraction is more elegant.” | Giant bags of assigns, generic DSL, diff-tracking loss and one-off branches. | Extract cohesive areas with explicit attrs/slots. Keep entity semantics and true state machines in their current owner. |
| “The metadata registry already proves coverage.” | Markers and counts can pass while only prose is rendered. | Distinguish declared, rendered and exercised coverage. Assert representative real component identity and behavior. |
| “Every group should be stateless.” | DataTable lifecycle/polling/selection and event targeting are rewritten only to please the lab. | Keep real LiveComponents; use the library's supported story type or small harness. Leave difficult integration in mounted tests. |
| “We can mount Storybook in the demo with one flag.” | Breaks deliberate absent-dependency/prod contracts and may expose unauthenticated dev code. | Existing Admin endpoint first; separate explicitly dev/test combined harness later. |
| “More realistic personas mean more fixture combinations.” | Decorative industries with identical rendering, enormous test matrices. | Add a scenario only for a distinct reachable presentation or behavior class; prune duplicates and impossible states. |
| “Single review surface means every other renderer must go.” | Removes independent integration evidence and violates locked decisions. | Single human entry point, shared canonical data/render owners, multiple purposeful test transports. Retire only proven redundancy. |

No genuinely irreversible design choice is required for the first slice. Brand identity, adopter-visible route removal and resurrection of parked paid evaluation remain excluded rather than silently decided.
