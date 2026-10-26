# Phase 240: Shared System and Real Billing Exemplar — Pattern Map

**Mapped:** 2026-10-09  
**Files analyzed:** 13 source/test/acceptance owners, plus one evidence artifact  
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest tracked analog | Match quality |
|---|---|---|---|---|
| `accrue_admin/assets/css/app.css` | config/style | transform | same file, owning shared selectors | exact |
| `accrue_admin/lib/accrue_admin/components/detail.ex` | component | transform | same component; `detail_drawer.ex` for review composition | exact |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | controller/LiveView | request-response, CRUD-read | same file and `invoice_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | controller/LiveView | request-response, event-driven | same file | exact |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | controller/LiveView | request-response, CRUD-read | same file and `subscription_live.ex` | exact |
| `accrue_admin/lib/accrue_admin/copy/invoice.ex` | utility/copy | transform | same module | exact |
| `accrue_admin/assets/js/hooks/connection_state.js` | hook | event-driven | same hook; mounted phase-191 page-flow spec | exact |
| `accrue_admin/assets/js/hooks/accrue_theme.js` | hook | event-driven | same hook; phase-199 theme spec and phase-238 mounted theme checks | exact |
| `accrue_admin/assets/js/hooks/focus_trap.js` | hook | event-driven | same hook and `test/js/focus_trap_test.mjs` | exact |
| `accrue_admin/test/accrue_admin/live/{invoices_live,invoice_live,subscriptions_live,subscription_live}_test.exs` | test | request-response, event-driven | corresponding LiveView tests | exact |
| `accrue_admin/test/accrue_admin/components/theme_picker_test.exs`, `theme_test.exs` | test | transform | same tests | exact |
| `accrue_admin/test/js/focus_trap_test.mjs` | test | event-driven | same hook test | exact |
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` | test | event-driven, request-response | same package overlay spec | exact |
| `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | test | event-driven, request-response | same package lifecycle spec | exact |
| `accrue_admin/e2e/admin-visual-regression-phase211.spec.js` and `.github/workflows/accrue_admin_browser.yml` | test/CI config | file-I/O, batch | same spec/workflow | exact |
| `examples/accrue_host/e2e/phase237-admin-billing.spec.js` | test/evidence capture | request-response, file-I/O | same mounted-host spec | exact |
| `.planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` (evidence record) | documentation | transform | phase-237 mounted billing evidence/capture manifest | role-match |

`accrue_admin/test/accrue_admin/dev/component_registry_test.exs` and Storybook coverage/spec owners may be updated only for touched specimens. Their inventory remains the incumbent 30 families / 42 variants / 8 groups. The separate 43-module component inventory is a different count and must not be reconciled into or substituted for the registry. Avoid adding another registry or route allowlist.

## Pattern Assignments

### Shared invoice/list/detail and CSS composition

**Analogs:** `accrue_admin/lib/accrue_admin/live/invoices_live.ex:84-110`, `invoice_live.ex:34-100`, `components/detail.ex:27-55`, `components/detail_drawer.ex:24-55`, `assets/css/theme.css:12-100`, `assets/css/app.css:6143-6221`.

Reuse the existing `Detail`, `DetailDrawer`, `MoneyFormatter`, status and copy owners. The LiveView owns scoped facts and action eligibility; CSS/components own hierarchy and responsive presentation. Keep exact minor-unit/currency facts and current owner scope. Inspect mounted computed/clickable geometry before changing candidate compression; correct the shared selector/component, retain intentional 2px dense and 1px structural exceptions, and avoid page-specific specificity patches or a scale migration. Source token presence is not mounted evidence.

### Invoice/subscription behavior and tests

**Analogs:** `accrue_admin/test/accrue_admin/live/invoice_live_test.exs:1-120`, `invoices_live_test.exs:1-75`, `subscription_live_test.exs:1-95`, `subscriptions_live_test.exs:1-75`.

Keep facts, state and authorization checks in the existing owner suites. Preserve fresh owner/target/material-state checks, step-up, duplicate protection, exact currency/minor-unit cases, and accepted versus completed/pending/unknown outcome distinctions. Add assertions where the state/copy changes; do not create a browser-owned billing rule or broaden provider/backend capability. Keep routine strings in `AccrueAdmin.Copy.Invoice`; preserve legal/audit text and exact diagnostic wording.

**Focused command:** `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs`

### Theme preference, mounted behavior, and exact browser owners

The correct overlay owner is package **Phase 199**: `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`, invoked by `cd accrue_admin && npm run e2e:phase199`. It owns overlay containment/geometry/dismissal and the existing theme persistence/reload flows (spec lines 791-810). Extend it for the touched invoice review overlay: Tab/Shift-Tab containment, correction/submit, dismissal, and focus return to a surviving target when the original trigger is replaced/removed. Keep `focus_trap.js` local behavior in `cd accrue_admin && node --test test/js/focus_trap_test.mjs`.

The closest real offline/reconnect package owner is **Phase 191**, `accrue_admin/e2e/admin-page-flow-phase191.spec.js`, invoked by `cd accrue_admin && npm run e2e:phase191`. Its existing reconnect case (lines 304-332) goes offline, observes disabled stale action and reconnection copy, then online/restored copy. Extend this specific owner with a held real action and replaced controls; browser `online` alone must not enable them, and reconnect must not replay a mutation. Add complementary unit coverage at `test/accrue_admin/live/invoice_live_test.exs` / `subscription_live_test.exs` and `test/js` only for behavior their layer can observe. `connection_state.js:31-82` is the implementation source, not evidence that mounted behavior is already correct.

For actual host-mounted invoice/layout/served-CSS evidence, follow the tracked Phase 237 and 238 mounted owners: `examples/accrue_host/e2e/phase237-admin-billing.spec.js` (lines 1-21 source fingerprint list; 74-83 served stylesheet digest; viewport/theme/overflow helpers lines 40-71) and `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` (lines 31-59 scoped authenticated route, state and axe flow; lines 65-100 keyboard/action behavior). Phase 237 is the semantic mounted billing owner; Phase 238 is the better host theme/reconnect/interaction precedent where those cases are present. Do not substitute package `/billing` fixture routes for host `/admin` or host `/billing` (Portal).

Theme source is `accrue_admin/assets/js/hooks/accrue_theme.js:1-24,27-77`: supported stored values are `light`, `dark`, `system`; delegated event listeners survive LiveView replacement and update the single selected roving-tab stop. Keep selected preference separate from effective computed colors. Extend phase 199 for persistence/patch/reload and phase 238's host forced-dark theme path for precedence; add System OS light→dark→light computed-consumer assertions without changing the preference.

### Pixel completeness guard and recurring CI

The closest implementation is the existing `accrue_admin/e2e/admin-visual-regression-phase211.spec.js:9-23,25-85,88-141` plus `.github/workflows/accrue_admin_browser.yml:80-92`. Preserve its eight Linux goldens, current thresholds, reduced-motion setup, and narrow timestamp-only masks. Fix the expected-set guard so *all missing* and *partial missing* both fail, and give the guard focused negative controls at this owner. The workflow's current lines 82-91 test only whether any PNG exists and skip the visual gate otherwise; the corrected blocking gate remains the existing recurring `Admin browser UAT` job invoking `cd accrue_admin && npm run e2e:visual-regression`, not a new workflow. Keep final reviewed baseline refresh with Phase 243.

### Assets, coverage provenance, and evidence

Use the phase-237 capture pattern: record route/query, host/package identity, fixture and state, source revision/fingerprints, built and compiled bytes, served CSS/JS/font URL and digest, effective theme, viewport/zoom/input, browser/OS, result and measured diagnostic values. Record source/fixture/asset provenance separately from exercised behavior and historical evidence. HTTP page-request observation is only an HTTP observation; it cannot alone prove no LiveView mutation. Use authoritative disposable-fixture state/dispatch/audit evidence for broader no-mutation claims. Never use the Fake feedback preview database for proof/reset/mutation work.

Build source package assets using the existing command, from repository root: `mix accrue_admin.assets.build`. Existing build/asset tests and `admin-drift-docs` CI remain the recurring source/build owner; mounted host proof must compare served CSS **and JS** and loaded font provenance with current built package bytes. Existing package browser and mounted `host-integration` / `playwright-e2e` lanes already recur through `.github/workflows/ci.yml` and `.github/workflows/accrue_admin_browser.yml`; extend their named owner rather than creating a new matrix/workflow. `phase237-admin-billing.spec.js` imports the mounted fixture/test support and computes SHA-256 from served CSS vs `priv/static/accrue_admin.css`; copy that evidence shape for the current exemplar.

For browser availability, the earlier `~/.cache/ms-playwright` path probe is not proof that the effective macOS Playwright cache is missing. Resolve the installed executable cheaply at execution with `cd accrue_admin && node -p "require('playwright').chromium.executablePath()"` (or the installed Playwright API); report that returned path/cache state accurately. No browser execution is implied by this pattern map.

## Shared Patterns

### Truthful state and authorization
**Sources:** `invoice_live.ex`, `invoice_live_test.exs`, `copy/invoice.ex`. Server remains authoritative. Empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown are separate states with only an existing supported next step. Missing evidence/zero counts/request acceptance do not imply health, settlement or completion; do not offer blind mutation retry.

### Stored versus effective theme
**Sources:** `accrue_theme.js:1-24,27-77`, `theme_picker_test.exs`, `theme_test.exs`, package Phase 199 and host Phase 238. Verify selected preference separately from computed consumer styles; test OS changes under System, LiveView replacement/patch and persistence. Host-forced theme wins and suppresses normal choices.

### LiveView reconnect and focus lifecycle
**Sources:** `connection_state.js:31-82`, `focus_trap.js`, `admin-page-flow-phase191.spec.js:304-332`, `admin-interaction-overlay-phase199.spec.js`. Keep staged actions locked until actual LiveView readiness and fresh current state; preserve original disabled state across replacement and never replay a mutation. Overlay focus containment and restoration need mounted assertions for replacement/removal cases.

### Commands and scope

| Purpose | Existing command/owner |
|---|---|
| Invoice/subscription state | `cd accrue_admin && mix test test/accrue_admin/live/invoices_live_test.exs test/accrue_admin/live/invoice_live_test.exs test/accrue_admin/live/subscriptions_live_test.exs test/accrue_admin/live/subscription_live_test.exs` |
| Theme | `cd accrue_admin && mix test test/accrue_admin/components/theme_picker_test.exs test/accrue_admin/theme_test.exs` |
| Focus hook | `cd accrue_admin && node --test test/js/focus_trap_test.mjs` |
| Overlay mounted | `cd accrue_admin && npm run e2e:phase199` |
| Offline/reconnect mounted | `cd accrue_admin && npm run e2e:phase191` |
| Host billing evidence | existing `host-integration` / `playwright-e2e` lanes; `examples/accrue_host/e2e/phase237-admin-billing.spec.js` |
| Assets | repository root: `mix accrue_admin.assets.build` |
| Linux snapshots | workflow `Admin browser UAT` → `cd accrue_admin && npm run e2e:visual-regression` |

No human UAT gate, paid judge, dependency, full new workflow/matrix, extra waits/retries, broad masks, or softened pixel thresholds. Target zero required human UAT. Keep zoom simulation distinct from actual browser zoom and keep 24px AA minimum/exceptions distinct from the incumbent 44px frequent-action target direction.

## No Analog Found

None. A dedicated current Phase 240 coverage/provenance artifact is new as a deliverable, but the tracked Phase 237 capture manifest/spec is the closest role match.

## Metadata

**Analog search scope:** `accrue_admin/assets`, `lib/accrue_admin/{components,live,copy}`, `test/accrue_admin`, `test/js`, `e2e`, mounted host `examples/accrue_host/e2e`, CI workflows, and Phase 237/238 planning artifacts.  
**Files scanned:** 18 primary tracked analogs; secondary owners were located via the focused path and line searches above.  
**Tracked-source gate:** named source analogs were checked with `git ls-files`; no ignored `.gsd` runtime mirrors are referenced.  
**Project guidance:** no root `AGENTS.md` or `.codex/skills` / `.agents/skills` index was found.
