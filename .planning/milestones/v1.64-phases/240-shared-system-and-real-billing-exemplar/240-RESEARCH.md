# Phase 240: Shared System and Real Billing Exemplar — Research

**Researched:** 2026-10-09  
**Domain:** Phoenix LiveView Admin UI, shared design system, billing operator workflows, and recurring browser evidence  
**Confidence:** HIGH for existing source and test ownership; MEDIUM for mounted visual behavior, which requires execution-time inspection

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Incumbent system and useful hierarchy
- **D-01:** Use Impeccable Operate mode with the current Cobalt/quiet-confidence identity, Geist/Geist Mono and package-owned `--ax-*` roles. Reuse initialized code-first setup; do not repeat init, audience, brand or build-path questions.
- **D-02:** Serve engineers and support/billing operators equally. Organize identity/scope → current facts → supported next action → related evidence using appropriate existing tables, details and disclosures. Routine filters, scope, blockers, uncertainty and material consequences stay discoverable; no fixed-column or universal card/table mandate.
- **D-03:** Confirm suspected compression/control defects in current mounted output before editing. Fix the owning shared selector/component; retain deliberate 2px dense and 1px structural exceptions. Use existing task/section spacing and hierarchy instead of per-page specificity patches or a blanket scale migration.

### Responsive, state and interaction acceptance
- **D-04:** Exemplar acceptance includes long/missing data, narrow and intermediate widths, coarse-pointer contexts, text enlargement, text-spacing overrides and explicit zoom methods/limits. Keep essential identity, money, state and actions usable. Distinguish 24px AA target minimum/exceptions from the incumbent larger frequent-touch target direction.
- **D-05:** Preserve Light/Dark/System stored preference and correct effective styles, including OS changes while System remains selected, patch/reload persistence and host-forced theme precedence.
- **D-06:** Exercise actual idle → busy → idle labels/icons/disabled state, repeated LiveView updates and reconnect with replaced controls. Network online alone must not unlock staged actions; original disabled controls remain disabled and no mutation is replayed.
- **D-07:** Keyboard flows require visible focus, associated errors/status, Tab/Shift-Tab overlay containment, validation → correction → submission and logical focus return when a trigger is replaced or removed. Check rapid dismissal and reduced-motion teardown if the existing removal timer affects actual focus/hit targets. Frequent keyboard work stays immediate; no new motion dependency or routine money/count/navigation animation.
- **D-08:** Empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown exemplar states remain distinct with only a supported next step. Missing evidence, zero counts and accepted requests cannot imply health, settlement or completion. Preserve locked legal/audit text and exact diagnostic terms; improve surrounding routine copy and hierarchy.
- **D-09:** Preserve v1.63 fresh owner/target/material-state revalidation, authorization/step-up, duplicate protection, exact currency/minor units, provider eligibility and accepted versus completed/pending/unknown outcomes. No backend/provider capability expansion or blind retry.

### Automated evidence, assets and bounded iteration
- **D-10:** Reuse existing ExUnit, registry/Storybook/kitchen, package browser, mounted host, axe, asset/drift and Linux pixel owners. Each owning change includes faithful recurring acceptance and focused negative controls for new guards. No confirmation-only human UAT, paid AI judge, new full-matrix workflow, softened tolerances or new sleeps/retries to hide failures.
- **D-11:** Strengthen the existing complete expected Linux snapshot-set guard before propagation; prove missing-all and missing-partial failures. Retain current pixel thresholds. Final baseline review remains Phase 243. Volatile-value masks cannot hide identity, money, state, actions or errors.
- **D-12:** Inventory current 21 production Admin routes, component/state coverage and existing acceptance owners without duplicating the incumbent 30-family/42-variant/8-group registry. Record source, fixture, built/compiled/served CSS/JS/font provenance and exercised behavior separately from historical/source-only evidence. Collect lightweight comparable resource diagnostics at the first fresh mounted exemplar without inventing a timing SLA/platform.
- **D-13:** Source lives in `accrue_admin/`; build package assets with `mix accrue_admin.assets.build` and prove current compiled/served bytes. Host `/admin` is Admin; host `/billing` is Portal; package fixture `/billing` is Admin. Normal host absence of dev component/Storybook routes is intentional. Proof/reset/mutation work uses disposable fixtures, separate from the Fake feedback preview database. HTTP request observation alone cannot prove absence of LiveView mutation; use accurately limited claims or authoritative state/dispatch/audit evidence.
- **D-14:** One complete build/check and batched desktop/narrow/effective-theme inspection, one corrective batch, at most one confirming inspection per agreed delivery batch. Preserve the budget across renamed polish work. Reopen only for a named defect, safety/behavior failure, changed task requirement or explicit owner feedback. Zero required human UAT is the target; subjective feedback after delivery is optional.

### Agent discretion
Exact task decomposition, reuse of existing shared roles, truthful routine wording and smallest faithful fixture/assertion mechanisms are delegated within these approved constraints. Close a source candidate as unobserved/already adequate when current mounted evidence supports that disposition. Targeted source/command research and the required UI contract are preparatory work, not another broad design or sibling-project review.

### Deferred Ideas (OUT OF SCOPE)
Truthful subscription-to-invoice destinations, bounded billing return links and Recovery direct-entry/window corrections belong to Phase 241. Events/webhooks/catalog/Connect, navigation/search selection and cross-route terminology propagation belong to Phase 242. Final reviewed Linux baselines and feedback-preview handoff belong to Phase 243. Portal/checkout restyling, new diagnosis/causality/rooms, billing/provider capabilities, rebrand/font/framework migration, paid evaluators, global CI redesign, release publication and historical UAT/ship-window debt remain outside this milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DSN-01 | Operators can scan identity, current facts and next actions through consistent shared typography, spacing and hierarchy in existing list, detail and action-review compositions. | Shared `Detail`, invoice LiveViews/copy, `theme.css` token roles, existing detail/list ExUnit owners. |
| DSN-02 | Operators can read essential facts and activate controls with long or missing data at narrow, desktop and tablet/coarse-pointer layouts, including text enlargement and zoom without lost task access. | Existing detail/list/browser contracts; extend mounted representative viewport/zoom/focus acceptance; distinguish real browser zoom from CSS simulation. |
| DSN-03 | Operators can select and retain Light, Dark or System, with one selected preference, correct effective styles and existing host-forced theme behavior. | `accrue_theme.js`, `ThemePickerTest`, `ThemeTest`, effective CSS selectors; add OS-change and patch/reload browser coverage. |
| DSN-04 | Operators retain correct labels, icons, disabled state and task context through actual busy completion, repeated LiveView updates and reconnect, without premature enabling or replay of a staged action. | `connection_state.js`, invoice/subscription action ExUnit owners, mounted browser interaction owner; add controlled busy/reconnect/update cases. |
| DSN-05 | Keyboard users can complete touched navigation and review flows with visible focus, associated validation/status semantics, overlay containment and logical focus return after dismissal, correction or replacement. | `FocusTrap`, `DetailDrawer`/`Overlay`, JS focus-trap tests and existing overlay browser lane. |
| UXC-02 | Operators can distinguish empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown states and choose the supported next step without inferred health or completion claims. | `AccrueAdmin.Copy.Invoice`, invoice detail state branches and list ExUnit suites; extend assertions for state-specific next action and truthful result wording. |
| EVR-01 | Maintainers can inspect current route, interaction, component and state coverage with source, fixture and served-asset provenance, keeping historical, rendered and exercised evidence distinct. | Existing Phase 239 coverage/component parity and capture format; phase artifact should map current exemplar routes/owners and record current source/fixture/served asset/interaction provenance distinctly. |
| EVR-02 | Maintainers receive faithful recurring regression proof with each delivery slice in existing acceptance owners, including focused failure controls for new guards and no confirmation-only human UAT dependency. | ExUnit, JS hook, mounted Playwright, axe, asset, and Linux visual owners already exist; extend them by behavior and demonstrate new guards with focused missing-all/missing-partial controls. |
</phase_requirements>

## Summary

Use the incumbent Admin system and put the first representative work through the real invoice list → detail → action review, with a dense subscription view as the shared pattern cross-check. Existing source owners are `accrue_admin/assets/css/theme.css`, `assets/css/app.css`, `Components.Detail`, `Live.InvoicesLive`, `Live.InvoiceLive`, and the invoice copy module. Do not turn observed source candidates into defects without the current mounted confirmation required by D-03. [VERIFIED: `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md`; `accrue_admin/assets/css/theme.css:12-33`; `accrue_admin/lib/accrue_admin/components/detail.ex:27-55`; `accrue_admin/lib/accrue_admin/live/invoices_live.ex:84-110`; `accrue_admin/lib/accrue_admin/live/invoice_live.ex:34-70`; `accrue_admin/lib/accrue_admin/copy/invoice.ex:30-55`]

The highest-value implementation shape is one owning shared style/component adjustment paired with focused tests at existing owners. The source shows detail-section spacing/title overrides and a narrower action-band button rule; inspect their actual computed and clickable geometry under built/served CSS before changing them. Theme persistence, stale-control locking, overlay focus, and visual baselines also have named owners. No new library/provider is needed or authorized. [VERIFIED: `.planning/research/v1.64/VISUAL-SYSTEM.md`; `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; `accrue_admin/assets/css/app.css:6143-6221`; `accrue_admin/assets/js/hooks/connection_state.js:1-82`; `accrue_admin/assets/js/hooks/accrue_theme.js:1-81`; `accrue_admin/test/js/focus_trap_test.mjs`]

**Primary recommendation:** Plan a vertical tracer through the invoice list, invoice detail, action review, and one dense subscription composition; attach focused ExUnit/browser/theme/focus/reconnect checks to the existing semantic owners, rebuild and identify the served package bundle, and strengthen the current Linux snapshot expected-set guard early. Treat Phase 243 as reviewed baseline closure, not the first time these checks appear. [VERIFIED: `.planning/ROADMAP.md` Phase 240; `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` D-10–D-14; `.github/workflows/accrue_admin_browser.yml:65-102`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Invoice list/detail/review and subscription facts | API / Backend | Frontend Server (SSR) | LiveViews load scoped billing facts and authorize actions; rendered HEEx and copy compose the operator-facing result. The browser must not own billing truth or mutation policy. [VERIFIED: `accrue_admin/lib/accrue_admin/live/invoices_live.ex:1-25`; `accrue_admin/lib/accrue_admin/live/invoice_live.ex:1-32`] |
| Shared typography, spacing, theme and component hierarchy | Frontend Server (SSR) | Browser / Client | Package components emit structure and `--ax-*` classes; package CSS defines roles and theme-specific computed presentation. [VERIFIED: `accrue_admin/lib/accrue_admin/components/detail.ex:27-55`; `accrue_admin/assets/css/theme.css:12-33,82-100`; `accrue_admin/assets/css/app.css:6143-6221`] |
| Busy/reconnect and focus/overlay interaction | Browser / Client | Frontend Server (SSR) | JS hooks preserve client interaction state around LiveView lifecycle callbacks and DOM replacement; server remains authoritative for action outcome. [VERIFIED: `accrue_admin/assets/js/hooks/connection_state.js:24-82`; `accrue_admin/assets/js/hooks/focus_trap.js`; `accrue_admin/lib/accrue_admin/components/detail_drawer.ex:24-55`] |
| Package assets and current served-byte proof | CDN / Static | Frontend Server (SSR) | Admin package builds committed CSS/JS/fonts and embeds static asset identity; mounted host compiled package has to serve the rebuilt bytes. [VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`; `accrue_admin/lib/accrue_admin/assets.ex`; `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`] |
| Exemplar fixture/state coverage and disposable mutation proof | Database / Storage | API / Backend | ExUnit/Playwright fixtures use isolated test data; mutation evidence belongs to authoritative DB/dispatch/audit assertions rather than only page HTTP observation. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` D-13] |

## Standard Stack

### Core

| Library / system | Version | Purpose | Why standard |
|------------------|---------|---------|--------------|
| Phoenix LiveView | Repo constraint `~> 1.1` | Server-rendered and patched Admin routes | Existing package dependency and lifecycle model; preserve it for route/action behavior. [VERIFIED: `accrue_admin/mix.exs:1-50`] |
| Phoenix Component | Phoenix `~> 1.8` | Shared HEEx component composition | Existing `Detail`, drawers, tables, buttons, overlays, and copy consumers own reusable presentation. [VERIFIED: `accrue_admin/mix.exs:35-50`; `accrue_admin/lib/accrue_admin/components/detail.ex:11-55`] |
| Accrue Admin design tokens | Package-owned; no package version change | Cobalt/Geist/Geist Mono styles and semantic `--ax-*` roles | `theme.css` is the token authority; use existing composed type/spacing/color/focus/motion roles and deliberate dense/structural exceptions. [VERIFIED: `accrue_admin/assets/css/theme.css:12-100`; `accrue_admin/guides/admin_ui.md:1-30`] |
| ExUnit / Phoenix LiveViewTest | Existing repo versions | Billing truth, owner scope, action eligibility, lifecycle, copy/state tests | Existing invoice/subscription LiveView tests already establish isolated setup and exact money/owner behavior. [VERIFIED: `accrue_admin/test/accrue_admin/live/invoices_live_test.exs:1-75`; `invoice_live_test.exs:1-120`; `subscription_live_test.exs:1-95`] |
| Playwright Test | `1.59.1` in package declaration | Mounted browser behavior, responsive/theme/focus and Linux screenshot checks | Existing package lanes already run the Admin browser acceptance. [VERIFIED: `accrue_admin/package.json:1-18,50-56`] |

### Supporting

| Tool / owner | Purpose | When to use |
|--------------|---------|-------------|
| `AccrueAdmin.Copy.Invoice` | Routine invoice labels, statuses and empty/no-match content | Keep user-facing wording in existing copy owner and preserve locked legal/audit/diagnostic strings. [VERIFIED: `accrue_admin/lib/accrue_admin/copy/invoice.ex:1-55`] |
| `accrue_admin.assets.build` Mix task | Regenerate package-owned committed CSS/JS/fonts | After asset changes; then confirm host compiled and served identity. [VERIFIED: `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`; `accrue_admin/guides/admin_ui.md:9-10,108`] |
| Component registry / Storybook / kitchen | Existing component variant and state specimen ownership | Update only touched components/contracts; do not create a second inventory. [CITED: `.planning/research/v1.64/VISUAL-SYSTEM.md`; `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs`] |
| axe Playwright integration | Supplementary semantic/accessibility scan | Reuse `e2e:a11y` for changed mounted routes; do not present axe as universal accessibility certification. [VERIFIED: `accrue_admin/package.json:12-13`; CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`] |

**Installation:** none. Do not add a package, provider, backend capability, framework, font, or motion dependency for this phase. [VERIFIED: `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` D-10, D-13 and Deferred Ideas; `.planning/REQUIREMENTS.md` Out of scope]

## Architecture Patterns

### Recommended Project Structure

```text
accrue_admin/
├── assets/css/theme.css                 # token authority
├── assets/css/app.css                   # shared selectors and layout composition
├── assets/js/hooks/                     # theme, focus, overlay, connection state
├── lib/accrue_admin/components/          # shared Detail, Overlay, Drawer, table and controls
├── lib/accrue_admin/live/                # invoice/subscription route behavior and rendering
├── lib/accrue_admin/copy/                # routine domain language and state copy
├── test/accrue_admin/live/               # scoped billing truth/action/state contracts
├── test/js/                              # hook behavior unit tests
└── e2e/                                  # mounted host/package and pixel acceptance
```

Every listed path was opened or enumerated in source this session. [VERIFIED: `accrue_admin/assets/css/theme.css`; `accrue_admin/assets/css/app.css`; `accrue_admin/assets/js/hooks/`; `accrue_admin/lib/accrue_admin/components/detail.ex`; `accrue_admin/lib/accrue_admin/live/invoices_live.ex`; `accrue_admin/lib/accrue_admin/copy/invoice.ex`; `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`; `accrue_admin/test/js/focus_trap_test.mjs`; `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`]

### Pattern 1: Tracer invoice journey with one shared hierarchy

**What:** Preserve the existing invoice collection → scoped invoice detail → self-contained action review path. Align each view on identity/scope, current facts, supported action, and related evidence. Render money from canonical minor-unit/currency facts, retain owner scope and exact action eligibility, and use the established `Detail`, `DetailDrawer`, `MoneyFormatter`, status, and copy owners instead of parallel wrappers. [VERIFIED: `accrue_admin/lib/accrue_admin/live/invoices_live.ex:84-110`; `accrue_admin/lib/accrue_admin/live/invoice_live.ex:34-100`; `accrue_admin/lib/accrue_admin/components/detail.ex:27-55`; `accrue_admin/lib/accrue_admin/components/detail_drawer.ex:24-55`; `accrue_admin/test/accrue_admin/live/invoice_live_test.exs:1-120`]

**When to use:** The Phase 240 invoice exemplar and touched shared list/detail/review primitives. Cross-check hierarchy/density on `SubscriptionsLive` and `SubscriptionLive`; do not propagate to other route families as proof before their Phase 241–242 owner checks. [CITED: `.planning/ROADMAP.md` Phase 240 propagation obligation; `.planning/research/v1.64/OPERATOR-EXPERIENCE.md`]

**Current route owners:** the existing ExUnit entry points exercise `"/billing/invoices?status=open"`, `"/billing/invoices/#{invoice.id}"`, `"/billing/subscriptions?status=canceling"`, and `"/billing/subscriptions/#{subscription.id}"`. The host mount is `/admin`; do not confuse the package test mount `/billing` with host `/billing` (Portal). [VERIFIED: `accrue_admin/test/accrue_admin/live/invoices_live_test.exs:50-66`; `accrue_admin/test/accrue_admin/live/invoice_live_test.exs:90-112`; `accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs:39-55`; `accrue_admin/test/accrue_admin/live/subscription_live_test.exs:50-85`; CITED: `240-CONTEXT.md` D-13]

**Example (verified source value):**

`export const ALLOWED_THEMES = new Set(["light", "dark", "system"]);` [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-2`]

The source line is reproduced verbatim; preserve these supported preference values when extending theme tests. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-5`]

### Pattern 2: Test state transitions at the owning seam

Keep unit hook assertions for local hook behavior, LiveView tests for authorized state/action and source state, and mounted browser checks for actual CSS cascade, focus, input mode, OS theme changes, LiveView patches, and reconnect. Exercise idle → actual busy → idle with a controlled test fixture hold/error, then force a LiveView update/replacement and ensure stale controls remain locked until LiveView readiness. Never infer busy coverage from a “Saving…” specimen. [VERIFIED: `accrue_admin/assets/js/hooks/connection_state.js:24-82`; `accrue_admin/test/js/focus_trap_test.mjs`; `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`; CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

### Pattern 3: Theme preference is distinct from effective theme

Retain one stored preference in the existing hook, assert selection/persistence separately from the computed effective palette, and cover OS theme changes while preference remains `system`. Retain host-forced precedence and disabled/locked picker behavior. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-81`; `accrue_admin/test/accrue_admin/components/theme_picker_test.exs:1-80`; `accrue_admin/test/accrue_admin/theme_test.exs:1-60`]

### Pattern 4: Evidence chain separates source, fixture, build and served output

For the fresh mounted exemplar, record route/query, application identity, fixture namespace/state, source revision/fingerprints, build output, served CSS/JS/font URL and digest, effective theme, viewport/zoom/input method, browser/OS and result. A source token or rebuilt disk asset alone does not prove current mounted bytes. Scope a page request observer to observed page HTTP requests; wider “no mutation” claims require fixture database/dispatch/audit evidence. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; `accrue_admin/lib/accrue_admin/assets.ex`; `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`]

### Early pixel guard pattern

Extend the existing expected baseline set at `.github/workflows/accrue_admin_browser.yml` and `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`. Fail when every expected Linux image is absent and when only a subset exists; test each via focused negative control at this owner. Preserve pixel thresholds and keep masks limited to volatile timestamp values; money, identity, state, actions and error meaning remain visible. Phase 240 establishes the fail-closed guard; Phase 243 owns reviewed final baseline updates. [VERIFIED: `.github/workflows/accrue_admin_browser.yml:85-102`; `accrue_admin/e2e/admin-visual-regression-phase211.spec.js:1-150`; CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

### Anti-Patterns to Avoid

- Page-specific spacing/control patches before inspecting current mounted output; correct the shared source only after geometry/hierarchy confirmation. [CITED: `240-CONTEXT.md` D-03; `VISUAL-SYSTEM.md`]
- New scale, framework, typeface, provider, motion dependency, or package; the current token/components/lanes already serve the scoped need. [CITED: `240-CONTEXT.md` D-01, D-10, D-13; `REQUIREMENTS.md` Out of scope]
- Promoting host `/billing` as Admin or treating the package fixture `/billing` as the host route; host `/billing` is Portal and package fixture `/billing` is Admin. Keep tests in their actual mount. [CITED: `240-CONTEXT.md` D-13; `AUTOMATION-AND-SEAMS.md`]
- Treating the browser `online` event as LiveView readiness, restoring replaced controls without re-scanning them, or replaying a staged mutation after reconnect. These are source risks to test, not asserted mounted bugs. [VERIFIED: `accrue_admin/assets/js/hooks/connection_state.js:24-82`; CITED: `AUTOMATION-AND-SEAMS.md`]
- Calling CSS zoom simulation actual browser zoom; using axe or ARIA tree evidence to claim screen-reader speech; using synthetic touch to claim physical-device verification. [CITED: `AUTOMATION-AND-SEAMS.md`; official W3C references below]
- Adding a second component/route matrix, full workflow, retries, fixed sleeps, broad masks, increased pixel tolerance, or confirmation-only human UAT. [CITED: `240-CONTEXT.md` D-10–D-14; `REQUIREMENTS.md` Acceptance constraints]
- Claiming an HTTP-only non-GET collector proves no LiveView mutation; it only supports an HTTP-scoped observation. Use authoritative disposable-fixture evidence for a broader claim. [CITED: `AUTOMATION-AND-SEAMS.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Design-token/type/spacing system | New global scale, route-only token map, or component CSS framework | Package `--ax-*` roles and `ax-*` classes | Existing system owns Cobalt/Geist themes and documented dense/structural exceptions. [VERIFIED: `theme.css:12-100`; `guides/admin_ui.md:9-30`] |
| Invoice detail/review composition | New page-local summary/detail/drawer component | `Detail`, existing action-review/step-up and `DetailDrawer`/`Overlay` | Existing components own composition and focus contracts. [VERIFIED: `detail.ex:27-103`; `detail_drawer.ex:24-55`; `invoice_live.ex:11-32`] |
| Billing action correctness | Client-only eligibility, retry/replay, or duplicate guard | Existing server action path plus authorization/step-up/stale-target/duplicate tests | Billing facts and mutations remain server-authoritative; v1.63 safety contracts are locked. [CITED: `240-CONTEXT.md` D-09; `REQUIREMENTS.md` Acceptance constraints; VERIFIED: `invoice_live_test.exs:1-120`] |
| Theme preference/picker | Per-button listeners or alternative storage/theme system | Delegated existing `accrue_theme.js` and `ThemePicker` | Delegation survives LiveView replacement; stored preference and host override already have owners. [VERIFIED: `accrue_theme.js:1-81`; `theme_picker_test.exs:1-80`; `theme_test.exs:1-60`] |
| Focus containment/return | New drawer focus trap or global tab-order script | Existing `FocusTrap` hook and `Overlay`/`DetailDrawer` | Shared stack and restore behavior already exist with JS tests; add only missing scenario coverage. [VERIFIED: `assets/js/hooks/focus_trap.js`; `components/detail_drawer.ex:24-55`; `test/js/focus_trap_test.mjs`] |
| Visual regression platform | New screenshot workflow or paid judge | Existing Linux phase-211 Playwright/pixel job | It already owns stable screenshots; fix its all-images-missing gap without changing thresholds. [VERIFIED: `package.json:8-14`; `e2e/admin-visual-regression-phase211.spec.js:1-150`; `.github/workflows/accrue_admin_browser.yml:85-102`] |

## Common Pitfalls

### Pitfall 1: Token declarations look correct but are overridden or stale in the host

**What goes wrong:** A source token change is accepted although selector specificity or host compiled assets still show incorrect mounted geometry/color.  
**Why:** A narrower selector can defeat the generic responsive rule; source, built package assets, host-compiled assets and current served bytes are separate evidence. [VERIFIED: `accrue_admin/assets/css/app.css:6218-6221,6745-6753`; CITED: `AUTOMATION-AND-SEAMS.md`]  
**How to avoid:** Inspect computed styles/click target geometry in the current mounted exemplar, build package assets, compare served identity/digests, then test the owner route.  
**Warning signs:** An apparent 44px generic button still renders shorter in detail action band, or host `/admin` serves old CSS/JS/font.

### Pitfall 2: Disconnect restoration enables stale or replaced controls too early

**What goes wrong:** Browser online restores controls before the LiveView socket is ready; controls inserted while disconnected were not captured in the original disabled-state map.  
**Why:** `connection_state.js` currently attaches browser online and LiveView reconnected restoration handlers and contains no `updated()` callback. Treat this as a hypothesis requiring a faithful test. [VERIFIED: `accrue_admin/assets/js/hooks/connection_state.js:24-82`]  
**How to avoid:** Use a controlled held request / disconnect scenario in the existing disposable fixture, patch in replacement action controls, prove browser online alone does not unlock them, then reconnect and assert prior disabled state and no replay.  
**Warning signs:** A staged action becomes clickable between `online` and actual LiveView `reconnected`; a replacement control is enabled when original state was disabled.

### Pitfall 3: Theme preference is confused with rendered theme

**What goes wrong:** The picker says System while assertions only force `data-theme` to light/dark; OS appearance change or host force changes actual computed styles unexpectedly.  
**Why:** Stored preference and effective theme are distinct, and host-forced theme is a separate precedence path. [VERIFIED: `accrue_admin/assets/js/hooks/accrue_theme.js:1-81`; `accrue_admin/test/accrue_admin/theme_test.exs:30-60`]  
**How to avoid:** Browser test stored `system`, emulate OS light→dark, assert one selected preference plus changed computed roles; patch/reload; separately assert host-forced mode locks the picker.

### Pitfall 4: Snapshot gate silently disappears when the whole image set is deleted

**What goes wrong:** CI skips visual regression rather than failing if every expected PNG is missing.  
**Why:** Current workflow has an any-PNG presence check before invoking the visual project. [VERIFIED: `.github/workflows/accrue_admin_browser.yml:85-102`; `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]  
**How to avoid:** Make expected membership explicit from the spec's surface/theme cases, fail on all-missing and partial-missing, and add focused negative controls. Retain existing thresholds. Final goldens are Phase 243.  
**Warning signs:** Pixel job condition only asks whether a glob matched at least one file.

### Pitfall 5: Visual or HTTP evidence overstates what it proves

**What goes wrong:** CSS zoom/narrow view is reported as browser zoom; a request collector is reported as proof of no billing writes; historical captures are called current; accessibility scan is treated as certification.  
**How to avoid:** Record actual method and scope. Broader mutation claims need authoritative DB/dispatch/audit assertions in disposable fixtures; use a current mounted render for geometry, separate from source and archived images. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; [W3C Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html); [Playwright accessibility testing](https://playwright.dev/docs/accessibility-testing)]

## Environment Availability

Read-only version and health probes only; no service started, fixture reset, package installation or app startup. [VERIFIED: this session's shell probes; no application startup was performed]

| Dependency | Required By | Available | Version / observation | Fallback |
|------------|------------|-----------|-----------------------|----------|
| Elixir / Mix | Package ExUnit and asset build | ✓ | Elixir 1.19.5, Mix 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | OTP 28 | — |
| Node.js / npm | JS tests and Playwright scripts | ✓ | Node v22.14.0, npm 11.1.0 | — |
| Playwright CLI/browser | Mounted browser scenarios and Linux goldens | CLI ✓ / effective browser availability unconfirmed | Local CLI reports Playwright 1.59.1; the probed `<home>/.cache/ms-playwright` path is absent, which does not establish absence from macOS's effective cache or an override | Resolve Playwright's actual executable/cache during execution; provision existing pinned Chromium if needed |
| PostgreSQL | Disposable package/host test fixtures | ✓ responding | `pg_isready`: `/tmp:5432 - accepting connections` | Use existing test DB setup; do not touch feedback preview DB |
| Docker | Host compose environment, if used for mounted host | Unconfirmed | `docker info` emitted no server information | Use existing mounted preview if already running; no startup in research |

Probe results describe availability only; they do not assert a current app or browser render. [VERIFIED: this session's read-only probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix.LiveViewTest; Node `node:test`; Playwright Test 1.59.1 |
| Config file | `accrue_admin/playwright.config.js`; package tests in `accrue_admin/test/` |
| Quick run command | Focused ExUnit module, e.g. `cd accrue_admin && mix test test/accrue_admin/live/invoice_live_test.exs` (setup/runtime cost varies; no sub-30-second claim) |
| Full suite command | `cd examples/accrue_host && mix verify.full` (host DB-reset/build/browser composite; do not run it against preview; not a quick check) |

Commands and owners below were confirmed in package scripts or source tests; commands are recommendations, not execution results. [VERIFIED: `accrue_admin/package.json:1-50`; `accrue_admin/test/accrue_admin/live/invoice_live_test.exs`; `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command / Owner | File Exists? |
|--------|----------|-----------|---------------------------|-------------|
| DSN-01 | Identity/facts/action hierarchy through invoice list/detail/review and dense subscription | unit + mounted browser | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs`; extend `npm run e2e:phase198` only for touched mounted detail contract | ✓ |
| DSN-02 | Long/missing values, narrow/intermediate/coarse-pointer, enlarged text, actual zoom and intact actions | mounted browser | Extend the closest list/detail Playwright owner, currently `npm run e2e:phase196` / `npm run e2e:phase198`; run `npm run e2e:a11y` for supplementary tree/axe checks. Existing direct-width/layout checks do not establish actual browser zoom; add the scoped test at the owner. | ✓ owners; actual-zoom/coarse-pointer scenario is Wave 0 gap |
| DSN-03 | Stored Light/Dark/System, effective styles across OS change, patch/reload and host force | unit + mounted browser | `cd accrue_admin && mix test test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs`; extend mounted theme owner (`npm run e2e:phase199` or `npm run e2e:a11y` as best owner) for system OS change and persistence | ✓ unit; browser system case is Wave 0 gap |
| DSN-04 | Real busy completion, repeated patches/reconnect/replaced controls, no premature enable or replay | ExUnit + mounted browser | Extend `mix test test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscription_live_test.exs` and the existing mounted interaction owner (`npm run e2e:phase199`); extend JS hook test if hook logic changes | ✓ partial; real busy/reconnect replacement case is Wave 0 gap |
| DSN-05 | Focus-visible, associated errors/status, Tab/Shift-Tab containment, dismiss/correction/replaced trigger return | JS + mounted browser + axe | `cd accrue_admin && node --test test/js/focus_trap_test.mjs`; extend `npm run e2e:phase199` for real overlay flow and `npm run e2e:a11y` for semantics | ✓ unit/overlay owners; full correction/replacement browser flow is Wave 0 gap |
| UXC-02 | Distinct empty/no-match/unavailable/partial/unsupported/denied/pending/failed/unknown messages and supported next actions | ExUnit + mounted browser | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs`; add state-specific assertions at these owners; use mounted assertion for review outcome state | ✓ partial; matrix of states is Wave 0 gap |
| EVR-01 | Current route/component/state inventory and provenance separates source, fixture, built/compiled/served and exercised evidence | deterministic script/doc validation + mounted artifact | Extend existing package capture/evidence owner, `cd accrue_admin && npm run e2e:visual-regression` for current pixels; asset build command is `mix accrue_admin.assets.build`; record manifest/provenance with exemplar. No current source-only pass can substitute for fresh mounted output. | ✓ infrastructure; exemplar coverage/provenance record is Wave 0 artifact gap |
| EVR-02 | Each change has recurring owner acceptance and focused failures; no mandatory human UAT | targeted ExUnit/JS/browser/CI negative tests | `cd accrue_admin && mix test ...` (focused changed owner); `node --test ...` as applicable; `npm run e2e:visual-regression` (Linux CI required for approved baselines); assert all-missing and partial-missing expected-set guard at `.github/workflows/accrue_admin_browser.yml` / phase-211 spec | ✓ lanes; negative-control guard cases are Wave 0 gap |

Playwright mounted/browser and complete visual runs have fixture/browser startup costs; do not put a “<30s” budget on them. Keep existing workflow duplication in view and do not run `mix verify.full` and shards redundantly for every small edit. The `mix verify.full` command resets its disposable test DB and rebuilds assets, per the approved evidence research; it must never run against the feedback preview. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

### Sampling Rate

- **Per task:** one focused owner test for the changed behavior, with setup cost reported separately from assertion runtime.
- **Per delivery batch:** full changed-owner checks plus the existing package/mounted check appropriate to that layer; batch desktop/narrow and effective theme inspection together.
- **Phase gate:** required CI owner lanes green, expected-set negatives demonstrated/restored, built and served assets identified, and current exemplar evidence recorded. Final reviewed golden update remains Phase 243.

Use locator/state readiness rather than adding fixed waits or retries. If a focused check cannot prove behavior at its layer, label the limit and add the smallest test at the correct semantic owner. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` D-10–D-14]

### Wave 0 Gaps

- [ ] Extend `.github/workflows/accrue_admin_browser.yml` expected-set guard and/or phase-211 owner with independent missing-all and missing-partial negative controls; keep pixel job blocking and thresholds intact.
- [ ] Add a disposable-fixture controlled busy hold and reconnect/replaced-control test at the existing invoice/subscription and mounted interaction owners; assert `online` alone does not unlock and no action is replayed.
- [ ] Add one mounted System preference scenario for stored selection vs effective OS theme, persistence through LiveView patch/reload, and host-forced precedence.
- [ ] Complete overlay correction/validation/dismissal and removed/replaced trigger focus-return path at the existing Playwright overlay owner; preserve `node:test` hook coverage.
- [ ] Add representative long/missing data + narrow/intermediate/coarse-pointer + text-spacing and explicitly labeled actual browser zoom observation to changed list/detail owner. CSS zoom simulation remains supplemental.
- [ ] Create the current exemplar evidence record: source revision/fingerprints, fixture, route/state, current app identity, rebuilt package bytes, compiled/served CSS/JS/font identity, effective theme, viewport/zoom/input, interaction result, and diagnostic resource measurements.
- [ ] Extend invoice state tests to cover the required state distinctions only where the exemplar has a real branch; do not manufacture unsupported states or imply new backend capability.

Existing test frameworks, dependencies, fixtures, package-browser, host, axe, build/drift, and Linux pixel owners exist; there is no Wave 0 install/config gap. Gaps listed here are focused scenario/record extensions; mounted behavior and their evidence are outstanding, not already verified. [VERIFIED: existing package/test files named above; CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

**Disposable environment prerequisite:** all reset, reseed, mutation, controlled hold/error, and proof runs use the package E2E/test database or host `MIX_ENV=test` isolated database/partition. Keep the Fake feedback-preview DB separate and read-only. Do not use package `/billing` fixture routes as the canonical host’s Admin route. `mix verify.full` is destructive to its configured test DB by design, so reserve it for the disposable test environment. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`; `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` D-13]

**Execution costs and limits:** ExUnit can be run by changed module; browser tests incur fixture reset, app/browser startup, and assertions; Linux visual snapshots must run on Linux-compatible fonts/browser to compare committed goldens. No execution timing or current render was measured during this research. No arbitrary SLA or new timing threshold is justified. At the first fresh mounted exemplar, collect comparable raw/encoded resources, cold/warm task-ready and LiveView-ready times, representative filter/drawer response, available long-task/layout-shift diagnostics, fixture scale, runner/browser/cache and elapsed focused-check setup/assertion. Set any regression budget from observed variance, not an invented number. [CITED: `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md`]

## Security Domain

The phase changes presentation/interactions around existing billing actions, so preserve the security invariants already tested by the server-side LiveView owners. The current invoice suite configures a test auth adapter and step-up verifier; the phase must not move authorization or eligibility decisions into client code. [VERIFIED: `accrue_admin/test/accrue_admin/live/invoice_live_test.exs:1-45`; `accrue_admin/lib/accrue_admin/live/invoice_live.ex:32-70`; CITED: `240-CONTEXT.md` D-09]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | Yes, existing action identity/step-up | Existing `Accrue.Auth` and StepUp server path; do not expand or weaken. [VERIFIED: `invoice_live_test.exs:8-44`; `invoice_live.ex:6-10`] |
| V3 Session Management | Yes, only as existing host/session context | Preserve existing authenticated LiveView/session context; no new session mechanism. [CITED: `240-CONTEXT.md` D-09] |
| V4 Access Control | Yes | Owner scope, fresh target/material-state revalidation, authorization and duplicate protection remain server-side and covered by disposable ExUnit fixtures. [VERIFIED: `invoice_live.ex:34-70`; `invoices_live_test.exs:70-120`; CITED: `240-CONTEXT.md` D-09] |
| V5 Input Validation | Yes | Reuse existing LiveView validations and associated accessible errors; do not trust client labels, route params, amounts or stale action controls. [VERIFIED: `invoice_live.ex:74-100`; CITED: `240-CONTEXT.md` D-07, D-09] |
| V6 Cryptography | No phase-owned changes | No new cryptographic handling or secrets surface in the approved scope. [CITED: `240-CONTEXT.md` Phase Boundary/Deferred Ideas] |

### Known Threat Patterns for Phoenix LiveView billing UI

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Stale/foreign invoice or changed eligibility after staged review | Tampering / Elevation | Revalidate owner, target, material state, eligibility and authorization on server immediately before dispatch; preserve duplicate protection and tests. [CITED: `240-CONTEXT.md` D-09; `REQUIREMENTS.md` Acceptance constraints] |
| Reconnect or rapid repeated action dispatch | Tampering / Denial | Stale controls remain locked until LiveView reconnection; no automatic replay; retain server duplicate guard. [VERIFIED: `connection_state.js:24-82`; CITED: `240-CONTEXT.md` D-06, D-09] |
| Wrong amount/currency shown or rounded | Tampering | Render exact canonical minor units/currency and assert amount/target through review; never use formatted display text as authority for action. [CITED: `240-CONTEXT.md` D-09; `invoice_live_test.exs:60-120`] |
| Unknown/accepted outcome presented as settled | Spoofing / Tampering | Keep pending/failed/unknown distinct; only authoritative completion evidence may say completed/settled. [CITED: `240-CONTEXT.md` D-08, D-09; `REQUIREMENTS.md` UXC-02] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md` — locked phase decisions, boundaries and downstream deferrals, read directly.
- `.planning/REQUIREMENTS.md` — exact eight requirement statements and acceptance constraints, read directly.
- `.planning/ROADMAP.md` Phase 240 — goal, success criteria, propagation obligation, early guard and Phase 243 baseline ownership, read directly.
- `.planning/STATE.md` — planning status and active phase, read directly.
- `accrue_admin/assets/css/theme.css`, `assets/css/app.css`, `assets/js/hooks/connection_state.js`, `assets/js/hooks/accrue_theme.js`, `assets/js/hooks/focus_trap.js` — token/cascade and actual hook implementations, opened this session.
- `accrue_admin/lib/accrue_admin/components/detail.ex`, `components/detail_drawer.ex`, `live/invoices_live.ex`, `live/invoice_live.ex`, `copy/invoice.ex` — existing layout/list/detail/review and copy ownership, opened this session.
- `accrue_admin/test/accrue_admin/live/{invoices_live,invoice_live,subscriptions_live,subscription_live}_test.exs`, `test/accrue_admin/{components/theme_picker_test,theme_test}.exs`, `test/js/focus_trap_test.mjs` — existing semantic test ownership, opened this session.
- `accrue_admin/package.json`, `mix.exs`, `playwright.config.js`, `e2e/admin-visual-regression-phase211.spec.js`, `.github/workflows/accrue_admin_browser.yml` — actual check/build declarations and snapshot guard owner, opened this session.

### Secondary (MEDIUM confidence)

- `.planning/research/v1.64/SUMMARY.md` — completed broad review and settled scope/decisions.
- `.planning/research/v1.64/VISUAL-SYSTEM.md` — source candidates and acceptance lenses; visual candidates explicitly require current mounted confirmation.
- `.planning/research/v1.64/OPERATOR-EXPERIENCE.md` — audience/jobs and operator scan order.
- `.planning/research/v1.64/AUTOMATION-AND-SEAMS.md` — existing owners, fixture custody, provenance/evidence limits and bounded performance approach.

### Official primary technical references carried by approved due diligence

- [W3C WCAG 2.2 Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) — 320 CSS-pixel reflow acceptance and scope around tabular two-dimensional content.
- [W3C WCAG 2.2 Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html) — 200% text enlargement acceptance; CSS zoom simulation is not browser zoom.
- [W3C WCAG 2.2 Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) and [Target Size Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html) — 24px AA criterion/exceptions versus larger enhanced target direction.
- [W3C ARIA APG Modal Dialog Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — dialog focus containment/keyboard behavior.
- [Playwright Accessibility Testing](https://playwright.dev/docs/accessibility-testing) — automated checks do not detect every accessibility issue.
- [Playwright Visual Comparisons](https://playwright.dev/docs/test-snapshots) — environment-dependent visual snapshot generation/comparison.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A real mounted host or package browser environment can be reached during execution for the required current render and served-asset observations. [ASSUMED] | Environment / validation | Source-only work cannot confirm geometry or served output; execution must report unavailable honestly and cannot claim current render proof. |
| A2 | The installed Playwright executable and effective macOS browser cache/override have not yet been resolved. The absent probed `<home>/.cache/ms-playwright` path does not establish that Chromium is absent. [ASSUMED] | Environment Availability | At execution, resolve the installed Playwright Chromium executable and effective cache/override; if the pinned browser is missing, provision it as routine authorized task setup without changing project dependencies. Record the actual local mounted result and use the existing Linux owner for pixel comparisons. A failed or unavailable local inspection remains unverified, never a claimed pass. |
| A3 | The phase can express real busy/reconnect behavior using a small controlled hold/error in the existing disposable fixture seam. [ASSUMED] | Validation Architecture | If the seam cannot faithfully hold a server action, choose the smallest existing fixture seam or explicitly report the untested transition; do not add production delays. |

## Open Questions — RESOLVED Planning Dispositions

No unresolved planning decision remains. Current mounted appearance, browser availability and additional snapshot need are execution-time observations; none is claimed verified by this research.

1. **RESOLVED — Source candidates (D-03; owners: Plans 01 and 03).** Inspect the actual current served invoice list/detail/review and dense subscription exemplar before editing. For each action-band sizing, detail spacing, filter hierarchy and review-copy candidate, record confirmed, already adequate or unobserved from mounted evidence. Repair confirmed defects at the owning shared selector/component under the agreed inspection budget; an unobserved candidate is not a confirmed defect or a reason to invent a cosmetic change. [CITED: `240-CONTEXT.md` D-03/D-14; `.planning/research/v1.64/VISUAL-SYSTEM.md`; `.planning/research/v1.64/OPERATOR-EXPERIENCE.md`]
2. **RESOLVED — Local Playwright setup (execution owner: mounted browser tasks in Plans 01/03/06).** Resolve the installed Playwright Chromium executable path and effective macOS cache/override first. The read-only probe established Playwright CLI 1.59.1 and absence only at the probed `<home>/.cache/ms-playwright` path; it did not establish that the effective browser cache is absent. If Chromium is missing at the resolved path, install the existing pinned browser as routine authorized task setup, with no new project dependency or product decision. Record the environment and mounted result honestly; run pixel comparisons through the existing Linux owner. Do not treat an unavailable local browser or a Linux pixel result as proof of a local mounted behavior inspection. [VERIFIED: session probe limited to named path; `accrue_admin/package.json:50-56`; CITED: `240-PATTERNS.md` browser availability guidance]
3. **RESOLVED — Linux goldens (D-11; owners: Plan 02 and Phase 243).** Phase 240 guards the complete existing eight-image Linux set and proves complete, missing-all and missing-partial controls early in Plan 02. Bounded mounted inspection determines whether the exemplar justifies additional goldens; any changed UI still faces the blocking existing pixel comparison with unchanged thresholds and masks. Phase 243 owns final reviewed baseline selection/updates. A failing or absent comparison is not automatically blessed, bypassed or deferred. [CITED: `240-CONTEXT.md` D-10/D-11/D-14; `.planning/ROADMAP.md` Phases 240/243; `240-02-PLAN.md`]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read from package/mix declarations and source owners.
- Architecture: HIGH for responsibility and current implementation boundaries; MEDIUM for the appearance of current mounted output.
- Pitfalls: HIGH for cited source/guard behavior; MEDIUM for reconnect, CSS geometry, and review-composition candidates until mounted execution.

**Research date:** 2026-10-09  
**Valid until:** 2026-11-08 for stable code ownership; recheck installed browser/tool versions at execution.
