# Phase 29: Mobile parity and CI - Context

**Gathered:** 2026-04-20  
**Status:** Ready for planning

**Source:** `/gsd-discuss-phase 29` with `--all` (user selected every gray area) and parallel research synthesis (Playwright projects, Phase 21 CI contract, OSS engine patterns).

<domain>
## Phase Boundary

Phase 29 closes **MOB-01..MOB-03** for v1.6: **no horizontal overflow** on representative **mounted admin** flows at a **real mobile viewport**, **primary navigation reachable** on narrow width (documented contract + minimal automated proof), and **CI** that keeps **Playwright green on `chromium-mobile`** for the **in-scope admin-heavy** journey—not the placeholder `mobile-tag-holder.spec.js` alone.

It **does not** add billing domain features, new UI kits, a second browser matrix inside `accrue_admin` package CI, or a full-router mobile regression grid (that would be scope creep and a Pay/Cashier-style kitchen-sink footgun).

**Depends on:** Phase 28 layout/focus/table work where it affects mobile; inherit **no** false expectation that Phase 28’s desktop-only axe journey runs on mobile projects.

Exit is **REQUIREMENTS.md** MOB checkboxes plus **green** `chromium-mobile` for the obligations below.

</domain>

<decisions>
## Implementation Decisions

### D-01 — MOB-01: Overflow — which flows and how to assert

- **Representative spine:** **`/billing/customers?org=…` index + exactly one deterministic customer detail** (fixture-backed URL or stable row→navigation). This matches **data-dense** admin surfaces (hybrid table/card) where horizontal overflow actually bites, without a route matrix.
- **Assertion:** Reuse the **`expectNoHorizontalOverflow`** pattern from `phase13-canonical-demo.spec.js` (`documentElement.scrollWidth` vs `window.innerWidth` tolerance +1px) after **`waitForLiveView`** stabilizes following each navigation that changes layout.
- **Viewport fidelity:** Run these overflow assertions **only** on the Playwright project **`chromium-mobile`** (Pixel 5 profile in `playwright.config.js`). **Do not** treat **`chromium-mobile-tagged`** (Desktop Chrome @ 1280×900 + `grep: /@mobile/`) as satisfying MOB-01—it is a **speed/tag-discovery** lane, not responsive layout proof.
- **Package vs host:** Keep assertions in **`examples/accrue_host` Playwright**; use **LiveViewTest** inside `accrue_admin` only for semantics that do not need real CSS/font metrics.

**Rationale:** Engine-style admins (Nova, dense Rails consoles) fail on **detail** and **index** differently; **customers-only** is too thin. A **maximal per-route matrix** duplicates the “Cypress runs 40 minutes” failure mode. Two-screen spine is the **bounded** sweet spot for Phase 21 **desktop-first** + Phase 29 **mobile credibility**.

### D-02 — MOB-02: Primary nav “reachable” — definition, docs, and test

- **Definition of “reachable” (normative for this phase):** At the **mobile project viewport** (Pixel 5), an operator can open **primary billing destinations** (same top-level destinations the mounted shell already exposes on desktop—dashboard/money indexes as routed today) **without horizontal page scroll**, **without hover-only affordances**, and with a **visible control** (e.g. menu / drawer trigger) to expose links that the narrow shell hides. **`?org=`** remains coherent: after opening nav, org context must not strand the user (links still carry or preserve active org as today’s shell does).
- **Documentation:** Add a short **“Mounted admin — mobile shell”** subsection to **`examples/accrue_host/README.md`** (VERIFY-01 / mounted-admin area): single scroll owner, drawer/hamburger pattern, touch-target expectations, `?org=` note, and **z-index / host layout** cautions (Filament/ActiveAdmin lesson: double chrome and `overflow:hidden` hiding the menu).
- **Automation:** **One** Playwright path in the same **MOB-focused spec file** as D-01/D-03 (or tightly coupled sibling) running on **`chromium-mobile` only**: open the shell menu, assert **N** primary `getByRole("link", …)` targets are visible inside the panel, then **Escape** (or close control) returns to a sane state—aligned with Phase 28 Escape semantics where applicable.

**Rationale:** Doc-only regresses silently; test-only frustrates library consumers who embed Accrue in novel hosts. **Both** maximize **least surprise** and maintainer DX.

### D-03 — MOB-03: Admin-heavy mobile journey — which flow and which project

- **Golden journey:** **Customers index → open one seeded customer detail** using the same **fixture spine** as `verify01-admin-mounted.spec.js` / `verify01-org-switching.spec.js`: `readFixture`, `login`, **“Go to billing”**, `waitForLiveView`, **organization switcher** to the fixture org, then customers URL with `?org=`. Add **scroll-into-view** on a row or key cell before navigation as needed for mobile hit targets.
- **Tagging:** Tag the substantive spec or `test.describe` with **`@mobile`** for discoverability and alignment with `chromium-mobile-tagged`, but **gate** layout/MOB assertions with **`test.skip(testInfo.project.name !== "chromium-mobile", …)`** so the **tagged desktop-viewport project does not claim mobile parity**.
- **Placeholder:** Keep `mobile-tag-holder.spec.js` only if still needed as a **grep anchor**; MOB-03 **exit** is satisfied by the **new** admin-heavy journey on **real** `chromium-mobile`, not the placeholder alone.
- **Seeding:** Prefer **no `reseedFixture()`** in the new MOB spec when running under the **CI fixture handoff** (`ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1` + pre-seeded DB from `accrue_host_verify_browser.sh`) to avoid extra Mix churn on the slowest project; if flakes appear, document a **narrow** reseed exception (same pattern as other VERIFY specs that mutate state).

**Rationale:** Webhooks path is higher **async** surface for v1.6 ROI; subscriptions index is a **longer** LV chain. Customers is already the **VERIFY-01 / A11Y-04** narrative center; extending it to **detail** proves **admin-heavy** without inventing a parallel spine.

### D-04 — CI posture (Phase 21 D-01 cohesive)

- **Keep the canonical entrypoint:** Continue **`npm run e2e`** from `accrue_host_verify_browser.sh` / `mix verify.full` so **Chromium desktop** remains the **wide** merge gate (Phase 21 **desktop-first** unchanged).
- **Do not** move MOB obligations to **scheduled-only** PR checks—nightly green does not protect the PR that introduced a regression (bisect cost shifts to maintainers).
- **Bounded mobile cost:** New MOB tests **skip** on `chromium-desktop` and `chromium-mobile-tagged`, and run **only** on `chromium-mobile`. That adds roughly **one mobile pass** of a **small file** instead of doubling the entire suite on Pixel 5.
- **Optional later tightening:** A **`workflow_dispatch`** (or scheduled) job that runs **`--project=chromium-mobile`** without skips is a **nice-to-have trend signal**, not required to close v1.6 MOB.

**Rationale:** Full **(A) all specs × all projects** violates Phase 21’s explicit **smaller mobile subset** and repeats the “always-on Cypress matrix” footgun. **(C) scheduled-only mobile** violates MOB’s **PR-evident** intent. **(D)+(B)** hybrid—desktop full + **one real-mobile slice**—honors D-01 while making MOB **merge-blocking** where it matters.

### D-05 — Cross-cutting DX and ecosystem lessons (locked principles)

- **Hex packages stay fast:** Do not add a default Playwright matrix to **`accrue_admin`**’s `mix test`; prove mounted behavior through **`examples/accrue_host`** (Phase 21 D-05).
- **Stable selectors:** Prefer **`getByRole` / test ids on shell only**—avoid chaining long CSS paths that churn with `ax-*` tweaks.
- **Artifacts:** Rely on existing **`trace: "retain-on-failure"`** / screenshot settings—no new reporter machinery for this phase.
- **Learn from Pay / Cashier / Nova / Filament:** **Right:** one **reference host**, idempotent seeds, **golden path per concern**. **Wrong:** per-test full DB reseed armies, **viewport-fake** “mobile” suites, and **kitchen-sink** route loops that ossify layout churn into CI noise.

### Claude's Discretion

- Exact **filename** for the MOB spec (`verify01-admin-mobile-*.spec.js` vs extending `verify01-admin-mounted.spec.js`)—planner picks whichever minimizes duplication with `reseedFixture` usage and keeps **failure attribution** clear in CI logs.
- Whether to add a **second** overflow checkpoint on **webhooks index** in the same phase if implementation time allows—**optional** stretch, not required for MOB-01 exit if customers+detail is green.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — MOB-01..MOB-03 checkboxes and traceability table.
- `.planning/ROADMAP.md` — Phase 29 goal, success criteria, canonical ref list.

### Locked prior decisions (do not contradict)

- `.planning/phases/21-admin-and-host-ux-proof/21-CONTEXT.md` — **D-01** desktop-first + mobile subset; split specs + fixture spine; where Playwright lives.
- `.planning/phases/26-hierarchy-and-pattern-alignment/26-CONTEXT.md` — extend host Playwright when not expressible in LiveViewTest; Phase 29 owns `@mobile` expansion.
- `.planning/phases/28-accessibility-hardening/28-CONTEXT.md` — desktop-only axe / theme constraints; Phase 29 owns true mobile layout coverage.

### UI contracts

- `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — interaction / Playwright matrix intent (desktop vs mobile coverage notes).

### Host browser implementation (expected edit surface)

- `examples/accrue_host/playwright.config.js` — `chromium-desktop`, `chromium-mobile`, `chromium-mobile-tagged` definitions.
- `examples/accrue_host/e2e/global-setup.js` — seed / fixture contract with `ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED`.
- `examples/accrue_host/e2e/support/fixture.js` — `login`, `waitForLiveView`, `readFixture`, `reseedFixture`.
- `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` — `expectNoHorizontalOverflow` / responsive helpers.
- `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` — mounted customers index spine with `?org=`.
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — **example of `test.skip` per project** (inverse pattern: desktop-only there; mobile-only here).
- `examples/accrue_host/e2e/mobile-tag-holder.spec.js` — current `@mobile` placeholder.
- `scripts/ci/accrue_host_verify_browser.sh` — single-seed + `ACCRUE_HOST_SKIP_PLAYWRIGHT_GLOBAL_SEED=1` Playwright invocation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`expectNoHorizontalOverflow` / `assertResponsiveState`** in `e2e/phase13-canonical-demo.spec.js` — extract to `e2e/support/` if reused to avoid drift.
- **VERIFY-01 fixture spine** — `verify01-admin-mounted.spec.js`, `verify01-org-switching.spec.js`, `support/fixture.js`.

### Established Patterns

- **Project-specific skips** — `verify01-admin-a11y.spec.js` skips mobile projects; MOB specs invert the condition.
- **Three Playwright projects** — substantive mobile layout must use **`chromium-mobile`**, not **`chromium-mobile-tagged`** (desktop viewport + `@mobile` grep).

### Integration Points

- **`mix verify.full` / `accrue_host_verify_browser.sh`** — canonical CI browser gate; MOB work must keep **`npm run e2e`** green without large runtime regression.
- **`examples/accrue_host/README.md`** — VERIFY-01 documentation home for the new mobile-shell checklist.

</code_context>

<specifics>
## Specific Ideas

- Treat **`chromium-mobile-tagged`** exactly as documented in `playwright.config.js` comments: a **non-device** grep lane—never the sole proof for MOB-01/MOB-02 layout.
- Align nav test assertions with **existing** `getByTestId("organization-switcher")` and role-based link labels already used in VERIFY-01 specs.

</specifics>

<deferred>
## Deferred Ideas

- **Full mobile matrix** (every `AccrueAdmin.Router` live path × Pixel 5) — future phase if maintainers want exhaustive coverage; conflicts with Phase 21 bounded-mobile philosophy.
- **Webhooks list as primary MOB-03 journey** — optional stretch if customers+detail is insufficient in practice.
- **Dedicated scheduled `workflow_dispatch` mobile sweep** — optional operational hardening, not v1.6 MOB exit criteria.

### Reviewed Todos (not folded)

- None — `gsd-sdk query todo.match-phase "29"` returned no matches.

</deferred>

---

*Phase: 29-mobile-parity-and-ci*  
*Context gathered: 2026-04-20*
