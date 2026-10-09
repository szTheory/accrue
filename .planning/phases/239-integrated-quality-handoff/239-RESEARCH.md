# Phase 239: Integrated Quality & Handoff — Research

**Researched:** 2026-10-09  
**Domain:** Cross-surface verification, rendered UI evidence, package asset/docs parity, local preview and handoff  
**Confidence:** HIGH for in-repo test/CI patterns; MEDIUM for coverage completeness until the current source inventory is reconciled

## User Constraints

- Durable Phase 235 decision, copied verbatim from `.planning/STATE.md`: “Default to shift-left verification: automate stable acceptance with focused tests, integration/E2E/smoke/seam checks, and CI when recurring value exists; target zero human UAT and hand off only irreducible human judgment or external/live-provider evidence, with the reason recorded. Do not reopen a verified closure absent new evidence.” [VERIFIED: `.planning/STATE.md:267`]
- User confirmed in this session to continue the next GSD workflow autonomously. There is no Phase 239 `CONTEXT.md` (`init.phase-op 239`: `has_context: false`). The roadmap and durable decisions therefore define scope.
- No `AGENTS.md`, `.codex/skills/`, or `.agents/skills/` project instructions were present at the project root during discovery.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INT-01 | Keyboard users can complete navigation and action flows with Tab, Shift+Tab, and Escape, including focus containment/restoration through patches, nested overlays, removed triggers, and reconnects. | Reuse the Phase 234–238 focused interaction specs and shared hook tests; add only integrated transitions absent from slice evidence. |
| INT-02 | People using narrow viewports, zoom, or coarse pointers can access essential content and actions at 320 CSS pixels without page-wide overflow or unusable controls. | Reuse the 320 CSS-pixel browser patterns and existing mobile/overflow helpers; cover representative cross-surface journeys and reconcile inventory gaps. |
| INT-03 | Admin and Portal support light, dark, system, host-forced themes, representative accent and host-to-Portal theme handoff; repeated keyboard actions remain immediate and reduced motion removes nonessential motion. | Existing theme and host-forced Phase 238 lane plus reduced-motion and Portal/host specs are the starting evidence; check pairwise combinations only where a slice did not already prove them. |
| INT-04 | Empty, no-match, unavailable, unsupported, denied, pending, error, and long-content states are covered deliberately at the least costly credible verification layer. | Existing ExUnit/LiveView fixtures cover detailed branches; use browser checks only where actual rendered and announced behavior matters. |
| SHIP-01 | Generated Admin and Portal assets, fonts, mounts, CSP/SRI, copy exports, and host integration documentation match the source actually served by each package. | Reconcile asset builders, package response/hash tests, Braintree SRI tests, CSP tests, generated copy export, mount paths, and published guides. |
| SHIP-02 | Every owned route and unique interaction has a coverage disposition supported by current required gates and inspected representative renders. | Refresh the dated Phase 233 source inventory against current routers; maintain a route/interaction-to-test/evidence disposition ledger and inspect current mounted renders. |
| SHIP-03 | Component examples and adopter docs match production; task-owned debris is removed; a useful feedback preview remains separate from mutation/reset proof. | Reuse component-registry/Storybook parity tests and current stable local demo; keep `mix verify.full` and test DB reset out of the feedback-preview path. |
</phase_requirements>

## Summary

Phase 239 closes evidence across already-refined surfaces. Phases 234–238 have focused ExUnit/LiveView and browser journeys, so the work should begin with a fresh inventory/coverage reconciliation and current served inspection, then add only missing integration assertions. The Phase 233 inventory is explicitly source-only, dated 2026-10-07, and pinned to an older SHA; it is useful as a route-family seed, not current render proof. [VERIFIED: `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md:1-7, 61-65`]

The current stack already has the right layers: ExUnit and LiveView for detailed state/authorization cases, Playwright in the canonical host for real mounted browser behavior, CI asset rebuilds and existing documentation/component contracts. The required `playwright-e2e` job is a 3-shard Playwright gate and includes a Phase 238 forced-dark contract on shard 1. [VERIFIED: `.github/workflows/ci.yml:1488-1492, 1509-1523, 1576-1592`] The most efficient plan is to retain these seams, map each owned route and unique interaction to existing evidence, mark existing evidence complete when still valid, and spend new tests only on uncovered combinations or source-to-served drift.

The feedback preview should be a stable, read-only evaluation path based on the existing seeded Fake-backed example and mounted Admin/Portal. Keep it separate from `mix verify.full`: `verify.full` includes installation, regression, boot and browser proofs, and its browser script drops and reseeds the test database. [VERIFIED: `examples/accrue_host/mix.exs:157-165`; `scripts/ci/accrue_host_verify_browser.sh` reads reset and seed steps] Any remaining owner feedback should ask for subjective judgment (for example visual preference) or live-provider fidelity that deterministic fixtures cannot establish, and record the exact limit; no routine human UAT for stable acceptance.

**Primary recommendation:** Plan a finite integrated closure: refresh the route/interaction evidence ledger; reuse existing lower-cost tests; add a small representative mounted smoke/current-render set only for uncovered seams; verify generated/served assets, mounts, fonts, CSP/SRI, copy and component/doc parity; and document a stable read-only preview separate from mutation/reset proofs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Business-state, authorization and interaction variants | API / Backend | Frontend Server (SSR) | LiveView/ExUnit fixtures can explore branches cheaply; keep existing owner-scope and action seams authoritative. |
| Keyboard, focus, viewport, zoom, theme and motion behavior | Browser / Client | Frontend Server (SSR) | Focus and computed/rendered layout are DOM behaviors; run browser assertions only for representative integrated paths. |
| Route reachability, package mounting, served CSS/JS/fonts, headers | Frontend Server (SSR) | CDN / Static | Host mounts package routers and assets; response/body/header checks prove what a consumer actually receives. |
| Coverage disposition and handoff evidence | CI / Delivery | Browser / Client | CI records repeatable checks; saved current screenshots/render evidence supports human review without substituting for tests. |
| Stable evaluation preview | Frontend Server (SSR) | Database / Storage | Canonical example provides mounted package experiences and seeded demo state; preview should be read-only and isolated from test-reset tasks. |

## Standard Stack

### Core

| Tool / library | Version or constraint | Purpose | Why standard |
|---|---|---|---|
| ExUnit + Phoenix LiveView | Existing project lockfiles; Phoenix `~> 1.8`, LiveView `~> 1.1` | Focused unit, component, mounted LiveView and contract tests | All three packages already use this stack; keep detailed deterministic branch assertions at this layer. [VERIFIED: `accrue_admin/mix.exs:39-45`] |
| Playwright Test | Host lockfile; `@playwright/test` `^1.57.0` and Node `22.x` in host `package.json` | Browser interaction, served assets, responsive and current-render smoke | Existing required CI shard, seeded host fixtures and failure trace/report infrastructure. [VERIFIED: `examples/accrue_host/package.json` lines 1-18; `.github/workflows/ci.yml:1538-1545`] |
| Existing Mix asset tasks | Repo-owned Mix tasks | Rebuild and compare Admin/host artifacts; Portal package assets are served through its package Plug | Current project sources and drift tests already encode these ownership boundaries. [VERIFIED: `examples/accrue_host/mix.exs:166-172`; `accrue_portal/lib/accrue_portal/assets.ex:8-27`] |

### Supporting

| Tool | Purpose | When to use |
|---|---|---|
| `@axe-core/playwright` | Automated accessibility rule checks | Keep for representative mounted state checks; it does not replace keyboard/focus assertions. Existing host package declares it. [VERIFIED: `examples/accrue_host/package.json` lines 15-18] |
| Existing component registry and Storybook coverage | Production component/example parity | Run current registry/render parity; expand only for a specifically identified gap. [VERIFIED: `accrue_admin/test/accrue_admin/dev/component_registry_test.exs:48-118`; `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs:1-66`] |
| Existing static asset and CSP contract tests | Content hash/body, CSP nonce and SRI parity | Use before adding new build or browser assertions. [VERIFIED: `accrue_admin/test/accrue_admin/assets_test.exs:6-43`; `accrue_portal/test/accrue_portal/csp_plug_test.exs:4-19`; `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` SRI contract] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Full browser coverage of every data permutation | ExUnit/LiveView permutations plus a small set of mounted browser journeys | Browser permutations cost more and duplicate branch evidence; reserve browser for behavior dependent on actual DOM, navigation, focus or served resources. |
| Static historical screenshots as acceptance | Current served DOM/computed style plus fresh representative captures | Historical captures are not evidence for current code/render; capture after build from the mounted host and link the exact source SHA. |
| A new visual testing dependency or CI rearchitecture | Existing Playwright, CI shards and established visual tools | Requirements explicitly defer paid visual evaluation, endless ratchet, and wholesale CI redesign. [VERIFIED: `.planning/REQUIREMENTS.md` out-of-scope section, lines 70-86] |

No external package installation is indicated by the current requirements or inspected test seams. Do not add a dependency absent a concrete uncovered requirement.

## Architecture Patterns

### Coverage disposition, then targeted proof

Refresh the Phase 233 route inventory using current package routers and host router, then create one Phase 239 matrix with each production route, unique interaction/transport and relevant state family. Each row should point to an existing focused test or browser spec, its layer and freshness, and disposition (`covered`, `integrated smoke needed`, `not applicable` with reason, or `human-only` with reason). Reconcile old source claims to present code; do not count redirect/dev-only routes as production UI. The old inventory distinguishes production routes from compatibility redirects and dev routes and explicitly disclaims served proof. [VERIFIED: `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md:11-16, 30-48`]

Use a tier rule:

1. ExUnit for data, authorization, outcome and error permutations.
2. LiveView tests for mount, event, patch, flash and rendered server HTML contracts.
3. Playwright for browser-only properties: keyboard/focus across patches/reconnects, overflow at 320 CSS px, actual zoom strategy, host theme handoff, reduced motion, mounted routes, network responses, and representative visual inspection.
4. CI only for stable checks with recurring regression value. Reuse current jobs and add a new recurring gate only when the evidence is not already merge-blocking.

### Reuse the seeded host as the consumer seam

The canonical host is already the integrated package consumer. Its Playwright config owns `e2e/`, uses local base URL, retains failure traces, and separates default, mobile and opt-in walkthrough projects. The required CI lane seeds each shard fixture once, disables redundant global seed, runs the shard, and runs the Phase 238 forced-dark lane. [VERIFIED: `examples/accrue_host/playwright.config.js`; `.github/workflows/ci.yml:1514-1523, 1569-1592`] Add or extend integration smoke in this setup instead of booting a parallel test app.

### Compare generated and actually served surfaces

- Rebuild Admin assets with `cd accrue_admin && mix accrue_admin.assets.build`; current `admin-drift-docs` already rebuilds and compares committed CSS/JS. [VERIFIED: `.github/workflows/ci.yml:817-826`]
- Host `mix assets.build` builds the consuming app. The host browser script runs Admin copy export into `examples/accrue_host/e2e/generated/copy_strings.json`; for parity proof, generate to a temporary output and compare with the committed export so verification does not overwrite authored/tracked data. [VERIFIED: `scripts/ci/accrue_host_verify_browser.sh` contains the export invocation; read this file before implementation.] 
- Portal asset Plug embeds package static assets at compile time, fingerprints response URLs from content, and emits an ETag. Existing tests in `accrue_portal/test` and `accrue_admin/test` should be checked for asset response equality before duplicating them. [VERIFIED: `accrue_portal/lib/accrue_portal/assets.ex:8-27, 29-52`; `accrue_admin/test/accrue_admin/assets_test.exs:6-43`]
- Inspect font network responses from a real Admin mount: font source is referenced by generated CSS and font files are package static resources. Assert served success/content type or computed loaded font for one representative route; do not rely on the CSS text alone. [VERIFIED: `accrue_admin/assets/css/app.css:1-18`]
- CSP and SRI are distinct checks. Portal CSP nonce/provider allowlist has an ExUnit contract, and checkout markup/tests pin Braintree external scripts with `sha384` integrity values; preserve both contracts and check the actual mounted response/markup only where its integration is not covered. [VERIFIED: `accrue_portal/test/accrue_portal/csp_plug_test.exs:4-19`; `accrue_portal/lib/accrue_portal/live/checkout_live.ex:21-23, 337-340`; `accrue_portal/test/accrue_portal/live/checkout_live_test.exs:132-163`]

### Keep preview and mutation/reset proof separate

The checked-in Cadence demo offers a stable `http://accrue.localhost` preview, a loopback fallback, seeded demo identities, and Fake-backed billing. [VERIFIED: `examples/accrue_host/README.md:12-60`; `accrue_admin/guides/local_demo.md:1-28`] Recommend the named stable URL or the current startup banner as the feedback handoff, with credentials/role instructions from the README and a concise change summary. Make preview read-only for Phase 239: avoid replay, refunds, changes, resets or seeding as part of feedback. Use a separate disposable/test database for proof. `mix verify.full` must be labeled as proof and not as a preview command: its host browser script explicitly drops the `MIX_ENV=test` database before create/migrate/seed. [VERIFIED: `scripts/ci/accrue_host_verify_browser.sh` lines containing `MIX_ENV=test mix ecto.drop --quiet`; `examples/accrue_host/mix.exs:157-165`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Detailed interaction/data state permutations | Huge end-to-end matrix | Existing ExUnit/LiveView suites, with narrow added cases for proven gaps | Cheap deterministic seams already cover behavior. |
| Keyboard/focus/viewport semantics | String-only HTML checks | Browser DOM assertions and existing accessibility helpers | Patches, actual focus and layout require a browser. |
| Admin component catalog parity | A second hand-maintained variant inventory | `AccrueAdmin.Dev.ComponentRegistry` + `storybook_coverage_test.exs` | Existing tests derive stories/coverage from production registry. |
| Current render evidence | Historical screenshots as current proof | Browser against current mounted app, linked to source SHA | Inventory explicitly marks older captures as non-current. |
| Local review environment | A new preview site or a verification command that resets shared state | Existing stable seeded `accrue_host` demo; keep proof in isolated test DB | Existing demo and verification paths are already distinct; test scripts can drop DB. |

**Key insight:** the requirement is evidence completeness across boundaries, not multiplying browser checks. Maintain one inventory-to-evidence ledger and let each existing low-cost seam prove what it can.

## Common Pitfalls

### Pitfall 1: Treating the Phase 233 inventory as current evidence
**What goes wrong:** Route totals, paths or output no longer match the current code; captures appear to prove behavior they never inspected.  
**How to avoid:** Re-read all package/host router sources; pin refreshed inventory and captures to the same current SHA. Keep source inventory and served render proof distinct.

### Pitfall 2: Promoting a test to CI without recurring value
**What goes wrong:** CI grows longer and noisy while overlapping tests merely repeat slice checks.  
**How to avoid:** Use the existing required shard and jobs. Add only an uncovered, deterministic, recurrent regression check; keep subjective or environment-specific review outside blocking automation.

### Pitfall 3: Running proof against the preview database
**What goes wrong:** `verify.full` or a browser proof resets/seeds its test DB, while manual evaluation may contain valuable feedback state.  
**How to avoid:** Keep the stable preview process and DB separate from the test-proof process; never use the preview database in `MIX_ENV=test` reset scripts.

### Pitfall 4: Assuming hashed paths prove all asset integrity properties
**What goes wrong:** Package content hashes/ETags, CSP nonces, external SRI, font requests and copy-export parity are different contracts.  
**How to avoid:** Reuse/extend each focused source-to-served contract independently; specifically include font fetch, mount-prefixed URLs, CSP header, external SRI markup and generated copy diff only where not already covered.

### Pitfall 5: Re-testing provider outcomes with live credentials
**What goes wrong:** A deterministic UI task can incur external effects and still fail to prove all stable local behavior.  
**How to avoid:** Use Fake/Mox fixtures for required gates. Record live-provider fidelity as human/external-only only if an acceptance claim truly requires an external provider.

## Code Examples

Existing focused and full validation entry points (commands quoted verbatim from project Mix config and CI):

```bash
cd accrue_admin && mix test --warnings-as-errors
cd accrue_portal && mix test --warnings-as-errors
cd examples/accrue_host && mix verify
cd examples/accrue_host && mix verify.full
cd accrue_admin && mix accrue_admin.assets.build
```

`mix verify` runs the bounded host test script. `mix verify.full` additionally installs, compiles, rebuilds assets, runs the host regression test script, dev boot smoke, and browser proof. The host `test` alias and verifier scripts include database lifecycle operations; keep them off the preview database. [VERIFIED: `examples/accrue_host/mix.exs:148-165`; `scripts/ci/accrue_host_verify_test_bounded.sh`; `scripts/ci/accrue_host_verify_test_full.sh`; `scripts/ci/accrue_host_verify_browser.sh`]

For one focused mounted check, preserve project convention:

```bash
cd examples/accrue_host && npx playwright test e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop
```

This proves the already-covered Phase 238 slice, not every Phase 239 route; use it as a known passing comparison while mapping all phase specs. [VERIFIED: `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-VALIDATION.md` contains the exact command and reports the existing focused evidence.]

## State of the Art

This is an in-repo integration phase and adds no new framework/package. The current direction is already encoded by existing project practice: high-volume state permutations at ExUnit/LiveView, real browser integration where rendering matters, and browser shards in required CI. Avoid importing a generic testing framework or a visual CI service without a demonstrated gap.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | The current stable seeded Fake-backed example is a suitable read-only preview after checking its current mutation posture during planning. | Preview | Feedback could alter seeded rows; planner should ensure the review path is read-only or disposable and state this in handoff. |
| A2 | The copy export can be regenerated to a temp path using the checked-in task and compared without requiring generated file replacement. | Served surfaces | If task cannot write to arbitrary output, use temp worktree/copy for comparison. |
| A3 | A representative set of cross-surface render checks is sufficient when every route/interaction has an explicit disposition and per-slice proof remains current. | Coverage disposition | A row without appropriate evidence must be added to the minimal browser or LiveView set; do not infer completeness from representative pages alone. |

## Open Questions

1. **(RESOLVED)** Use the existing `admin@example.com` operator for `/admin` and `healthy@example.com` customer for `/billing`; those roles and credentials already appear in the host README. Do not copy credentials into a new phase artifact. This keeps the optional preview on the established operator/customer paths. [VERIFIED: `examples/accrue_host/README.md:54-60`]
2. **(RESOLVED)** The default `/billing` mount already has an integrated Portal theme contract: Phase 236's mounted browser test covers system/light/dark selection, host-branded accents, keyboard focus, reduced motion, and long content; the required browser workflow also runs forced-light and forced-dark Portal checks. No separate theme-handoff path needs a duplicate render check. Keep `/shared-billing` as a distinct route/context disposition; add a theme assertion only if route reconciliation finds a real gap. [VERIFIED: `examples/accrue_host/e2e/phase236-portal-self-service.spec.js:579-649`; `.github/workflows/ci.yml:1650-1678`]
3. **(RESOLVED)** The recurring Admin `mix test --warnings-as-errors` job includes `copy_test.exs`; that test checks selected generated values against the fixture, while the browser proof regenerates `copy_strings.json` in place. Neither compares the full regenerated export to the checked-in fixture. Add an exact full-export comparison using temporary output to `copy_test.exs`, so the existing required Admin test job catches recurring drift without a new CI job or overwriting generated output. [VERIFIED: `accrue_admin/test/accrue_admin/copy_test.exs:516-535`; `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex:147-155`; `.github/workflows/ci.yml:682-683`; `scripts/ci/accrue_host_verify_browser.sh:124`]
4. **(RESOLVED)** Treat package-owned routes mounted at `/admin`, `/billing`, and `/shared-billing` as the core ledger. Include host-owned entry/context seams only where they are part of this billing journey: `/`, `/app/billing`, the login prerequisite, and the redirects/actions that establish the mounted Portal or Admin session. Classify those as host-owned. Exclude unrelated Cadence product routes such as pricing, reports, settings, mailbox, and inbound webhook paths with an explicit reason; do not claim ownership of those surfaces. [VERIFIED: `accrue_admin/lib/accrue_admin/router.ex:72-102`; `accrue_portal/lib/accrue_portal/router.ex:128-143`; `examples/accrue_host/lib/accrue_host_web/router.ex:30-35,53-105,138-157`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---|---|
| Elixir / OTP / Mix | ExUnit, Phoenix build and serve | ✓ | Elixir 1.19.5, OTP 28 | Use CI's pinned toolchain. |
| Node | Playwright and asset tasks | ✓ | 22.14.0 | Use CI's Node 22 setup. |
| PostgreSQL | Host ExUnit/E2E | ✓ | `pg_isready` reports local server accepting at `:5432` | CI supplies Postgres 15 service. |
| Chromium | Local Playwright | No working executable observed: `/opt/homebrew/bin/chromium` wrapper points to a missing app binary | — | Existing `npm run e2e:install` installs Playwright Chromium; required CI does this. Do not install during research. |
| New external packages/services | None indicated | N/A | — | Keep current stack. |

## Validation Architecture

Workflow setting `workflow.nyquist_validation` is enabled. Existing infrastructure is sufficient; Phase 239 should not create a new test framework.

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Phoenix LiveView across `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host`; Playwright Test in `examples/accrue_host`. |
| Config | Each package's existing `mix.exs` test config; host `examples/accrue_host/playwright.config.js`. |
| Quick commands | Existing per-task test files; focused browser specs from `examples/accrue_host/e2e/phase234-*`, `phase236-*`, `phase237-*`, `phase238-*`. |
| Full phase/regression commands | `cd accrue && mix test`; `cd accrue_admin && mix test --warnings-as-errors`; `cd accrue_portal && mix test --warnings-as-errors`; `cd examples/accrue_host && mix verify.full`. |
| Required recurring host browser gate | `.github/workflows/ci.yml` `playwright-e2e`; host Playwright shards run after `host-integration`. |

### Phase Requirements → Test Map

| Requirement | Existing seam / likely file family | Recommended new verification only if ledger shows gap |
|---|---|---|
| INT-01 | Admin hook JS tests in `accrue_admin/test/js`, Admin Playwright specs and Phase 234–238 host journeys; Portal LiveView and mounted browser specs | One cross-patch, nested-overlay or reconnect browser assertion per distinct shared focus mechanism; detailed per-action results stay in ExUnit. |
| INT-02 | `examples/accrue_host/e2e/support/overflow.js`, phase mobile/layout specs and 320 CSS-pixel patterns | Check 320 CSS-pixel overflow and usable primary action on any route absent from existing route journey; do not screenshot every page at every size. |
| INT-03 | `accrue_admin/test/accrue_admin/theme_test.exs`, host theme specs, `reduced-motion.spec.js`, Phase 238 forced-dark CI | Add only missing pairwise host-to-Portal handoff/forced theme or keyboard-repeat assertion. |
| INT-04 | Existing per-route ExUnit/LiveView suites in `accrue_admin/test/accrue_admin/live` and `accrue_portal/test/accrue_portal/live` | Fill states at the cheapest layer; require mounted browser only for state-dependent visual/accessibility behavior. |
| SHIP-01 | Admin assets tests/build gate; Portal `assets.ex`, `csp_plug_test.exs`, checkout SRI markup tests; host mount/router and generated copy export | Targeted served test for any unchecked Portal asset/mount/font; temp output parity compare for copy export if not already in required CI. |
| SHIP-02 | Phase 233 inventory (stale source snapshot) + Phase 234–238 validation/coverage artifacts + current workflow jobs | Produce refreshed all-route and unique-interaction disposition matrix tied to current tests and representative inspected renders. |
| SHIP-03 | Component registry/Storybook coverage tests; `accrue_admin/guides/*`, package READMEs and host README/local-demo | Add parity assertions for only demonstrated component/doc drift; record read-only preview URL/access and separate test proof/reset command. |

### Wave 0 Gaps

- No test framework install is needed.
- Create/refresh the route-to-evidence disposition ledger before adding tests.
- Refresh the source inventory: Phase 233 inventory has a dated SHA and expressly is not render proof.
- Identify current required CI job names and assertions from `ci.yml`; do not claim they were run remotely merely because their definitions exist.
- Decide preview safety model using the existing stable demo and ensure no verification task uses its DB.

### Sampling Rate

- Per implementation task: focused adjacent ExUnit/LiveView test or one focused Playwright spec for DOM-only behavior.
- Per integration wave: only changed package full suite(s), then the consolidated existing host verification path.
- Phase gate: current required local suites and CI discovery/contract checks green; no remote CI or protected-branch status implied.

## Security Domain

Security enforcement is enabled by default. No authorization/API surface change is scoped; cross-surface proof must preserve its current owner/customer boundaries.

| ASVS Category | Applies | Existing control to retain |
|---|---|---|
| V2 Authentication | Yes | Host auth and package auth hooks; do not publish preview credentials beyond the existing fictional local demo instructions. |
| V3 Session Management | Yes | LiveView reconnect/session tests and seeded host browser session setup. |
| V4 Access Control | Yes | Existing owner/customer-denial ExUnit/LiveView tests; no broad permissive route smoke. |
| V5 Input Validation | Yes | Existing POST/LiveView validation and forged-input fixtures. |
| V6 Cryptography | Yes | Existing CSP nonce and Braintree SRI contracts; never replace with test-only relaxed headers in preview. |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation in Phase 239 verification |
|---|---|---|
| A broad smoke route accidentally mounts without auth/owner scope | Elevation of privilege / Information disclosure | Reuse authenticated fixtures and denial tests; route inventory must note auth and mount boundary. |
| Shared or reset preview/test DB | Tampering / Denial of service | Distinct preview and test DBs; test scripts run only in test env; do not reset preview state. |
| External script/asset drift or permissive CSP | Tampering | Preserve SRI hashes, CSP nonce/allowlist tests, and actual package-served asset checks. |
| Preview presented as live-provider proof | Spoofing | Clearly label Fake-backed preview; reserve live provider claim for its separate credentialed lane. |

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md:224-237` — Phase goal, dependencies, five acceptance criteria.
- `.planning/REQUIREMENTS.md:47-63` — exact INT-01..04 and SHIP-01..03 requirement statements.
- `.planning/STATE.md:248-270` — existing verification decisions, 320 CSS px technique, shift-left/no-human-UAT policy.
- `.planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md` — source inventory and evidence boundary.
- `.planning/phases/234-admin-customers-subscriptions/234-VALIDATION.md`, `.planning/phases/235-customer-plan-selection-checkout/235-VALIDATION.md`, `.planning/phases/236-portal-billing-self-service/236-VALIDATION.md`, `.planning/phases/237-admin-invoices-payments-recovery/237-VALIDATION.md`, `.planning/phases/238-admin-events-webhooks-remaining-billing-surfaces/238-VALIDATION.md` — slice verification commands/evidence. (Read latest relevant validation artifacts while planning; this research read the Phase 238 strategy and selected prior inventories/tests.)
- `.github/workflows/ci.yml` — current CI job definitions and host Playwright shard contract.
- `examples/accrue_host/mix.exs`, `scripts/ci/accrue_host_verify_*.sh`, `examples/accrue_host/playwright.config.js` — local full proof and browser behavior.
- `accrue_admin/test/accrue_admin/assets_test.exs`, `accrue_portal/test/accrue_portal/csp_plug_test.exs`, `accrue_portal/test/accrue_portal/live/checkout_live_test.exs` — existing served asset/security contracts.
- `examples/accrue_host/README.md`, `accrue_admin/guides/local_demo.md` — stable local review path and Fake-backed scope.

## Metadata

**Confidence breakdown:**
- Existing stack and commands: HIGH — verified in current Mix/npm configuration and CI.
- CI/browser/asset contracts: HIGH — current source and test files inspected.
- Complete route and interaction coverage: MEDIUM — Phase 233 route inventory is stale by SHA and must be freshly reconciled during planning/execution.
- Preview safety posture: MEDIUM — stable seeded demo is documented, but Phase 239 must separate its running data from proof mutations/reset and state precisely what reviewer actions are safe.

**Research date:** 2026-10-09  
**Valid until:** 2026-11-08 for in-repo architecture; rerun route/CI inspection if routers or workflow change before execution.
