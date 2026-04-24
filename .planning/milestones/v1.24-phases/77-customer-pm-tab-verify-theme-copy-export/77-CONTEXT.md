# Phase 77: Customer PM tab — VERIFY + theme + copy export - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **ADM-15** (extend merge-blocking **VERIFY-01** with **Playwright + `@axe-core/playwright`** for **≥1** materially changed **customer** mounted route group tied to **ADM-14** work on the **`payment_methods`** tab) and **ADM-16** (record intentional **theme / layout** posture in **`accrue_admin/guides/theme-exceptions.md`**; keep **`mix accrue_admin.export_copy_strings`**, **`examples/accrue_host/e2e/generated/copy_strings.json`**, and **CI** allowlists aligned when **Copy** changes). Evidence: **`77-VERIFICATION.md`** + verifier contracts stay green per **`.planning/REQUIREMENTS.md`**.

**Out of scope:** **BIL-04** / **BIL-05** (Phase 78); new product features beyond VERIFY/theme/copy hygiene; gettext / host-overridable operator copy (Tier B).

</domain>

<decisions>
## Implementation Decisions

### ADM-15 — Where VERIFY / Playwright lives (host contract)

- **D-01 (primary):** Add the new **customer payment methods** merge-blocking flow in **`examples/accrue_host/e2e/verify01-admin-a11y.spec.js`**, alongside existing **customers index** axe tests. **Rationale:** Host **`npm run e2e`** under **`ci.yml`** is the evaluator-facing VERIFY-01 spine; billing libraries in other ecosystems (Rails engines, Laravel packages) anchor “real integration” in a **reference host** or dummy app — **`accrue_host`** is that contract. Package-local **`accrue_admin/e2e/phase7-uat.spec.js`** remains **supplementary** for maintainer UAT; it **does not** satisfy ADM-15 on its own because it is not the same merge-blocking gate adopters and README contracts describe.

- **D-02 (route):** The **minimum** “materially changed **customer** route **group**” is **`/billing/customers/:id?tab=payment_methods&org=<slug>`** (after login + org selection + **`waitForLiveView`**) — **not** customers **index** alone (already axe-covered). This matches **ADM-14**’s edit surface (**`AccrueAdmin.Live.CustomerLive`** `payment_methods` branch).

- **D-03 (documentation):** Extend **`examples/accrue_host/docs/verify01-v112-admin-paths.md`** with a row mapping **test title ↔ URL template ↔ ADM-15** so the VERIFY matrix stays the SSOT for “what merge-blocking admin paths mean,” following Phase 53/55/invoice precedent.

- **D-04 (split file):** **Defer** extracting a new `verify01-admin-*.spec.js` until **`verify01-admin-a11y.spec.js`** becomes hard to review; if split, mirror naming under **`examples/accrue_host/e2e/`** and register the file in the same paths doc.

- **D-05 (assertions):** Prefer **stable hooks** (`getByRole`, accessible names, existing **`ax-*`** where they double as selectors) and **`copy_strings.json`** keys for **Copy-backed** visible text — **never** a second independent English source in JS. Matches Phase 50/53 anti-drift design.

### ADM-15 — Axe policy (coherent with existing helper)

- **D-06:** Reuse the same **impact filter** as **`scanAxe` in `verify01-admin-a11y.spec.js` today:** **`critical` + `serious` only** after `AxeBuilder({ page }).analyze()`. Do **not** broaden to moderate/minor in this phase without a milestone-level policy change (principle of least surprise for maintainers).

- **D-07 (scope):** **Full-document** axe after the PM tab is stable (same pattern as customers index test). **Rationale:** Admin regressions often come from **shell + main** interaction (landmarks, nav, content); route-scoped `include()` is reserved for **future** secondary pages only if the team already has a **shell** axe elsewhere in the milestone — not required for the first PM-tab addition.

- **D-08 (themes):** Run **light then dark** for this customer-detail flow **on desktop projects only**, using the same **skip mobile projects** rationale as existing **`verify01-admin-a11y.spec.js`** tests (theme toggle hidden below `md`).

- **D-09 (flakes):** **One** `analyze()` at the **end state** of the journey (post-`waitForLiveView`, post tab-visible assertions) — not after every click. Optional: short `waitForFunction` / token settle pattern **only** where dark theme already needed it for sidebar contrast (mirror existing test). Attach violation JSON on failure for triage; avoid snapshotting raw violation HTML.

- **D-10 (suppressions):** **No** silent `disableRules` / broad `exclude`. Any exception needs **issue link + rationale** in **`theme-exceptions.md`** or test comment; prefer fixing tokens over papering over.

### ADM-16 — `theme-exceptions.md` (hybrid, Phase 55 precedent)

- **D-11:** Keep the **hybrid** model already in the guide: **Register table** = **durable intentional** token/layout bypasses (hex, inline `style`, non-`ax-*` hacks). **Phase reviewer notes** = **scoped audits** where the outcome is “**reviewed; no new bypasses**” (Phase 53/55 style).

- **D-12:** For **ADM-14** / **ADM-15** touches on the **payment_methods** tab: if the audit finds **no** new bypasses, add a **short Phase 77 reviewer note** only — **do not** add placeholder register rows.

- **D-13:** If a **durable** bypass ships, add **≥1 register row** (`slug`, `location`, `deviation`, `rationale`, `future_token`, `status`, `phase_ref`) — phase notes **must not** substitute for rows when code contains real debt.

### ADM-16 — `export_copy_strings` / `copy_strings.json` / CI

- **D-14 (SSOT):** **`AccrueAdmin.Copy` / submodules + `@allowlist`** in **`accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex`** remain the **single source of truth**; **`examples/accrue_host/e2e/generated/copy_strings.json`** is a **derived artifact** for Playwright — not hand-edited.

- **D-15 (command):** Canonical regenerate:  
  **`cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`**

- **D-16 (CI honesty):** Keep **merge-blocking** behavior where CI regenerates or verifies the artifact matches the task output (existing **`scripts/ci/accrue_host_verify_browser.sh`** / workflow integration — follow whatever **`scripts/ci/README.md`** documents as authoritative for this repo). Contributors may push a fix commit after CI red; **`main` must not lie**.

- **D-17 (merge conflicts):** Resolve **`copy_strings.json`** conflicts by **re-running the Mix task** on the merged branch, not by hand-merging JSON hunks.

- **D-18 (DX):** Document the one-liner in **contributor-facing** doc if not already (e.g. **`CONTRIBUTING.md`** or **`accrue_admin/guides/`** pointer); optional pre-commit is **nice-to-have**, not assumed — **CI is the backstop** (good OSS DX for drive-by PRs).

### Cross-tab stragglers (from **76-VERIFICATION.md**)

- **D-19:** **ADM-15** merge-blocking **Playwright + axe** targets the **payment_methods** tab journey (**D-02**). **Subscriptions KPI** / **charges empty** literals remain **second-class** in this phase unless explicitly migrated: if this phase **also** routes them through **Copy** for **ADM-16**, update **`@allowlist` + JSON** and prefer **ExUnit** (`customer_live_test.exs`) for those strings; **do not** multiply separate VERIFY browser journeys per straggler unless a future requirement ties them to a new materially changed route group.

### Claude's Discretion

- Exact **Playwright** test title string and minor step ordering inside **`verify01-admin-a11y.spec.js`** as long as **D-01–D-10** hold.
- Whether to add **`withTags([...])`** to `AxeBuilder` globally — **out of scope** unless changing all existing scans in a dedicated follow-up; stay consistent with **D-06**.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **ADM-15**, **ADM-16** (v1.24)
- `.planning/ROADMAP.md` — **### Phase 77** … **### Phase 78**
- `.planning/PROJECT.md` — v1.24 goals; VERIFY / Copy posture
- `.planning/phases/76-customer-pm-tab-inventory-copy-burn-down/76-CONTEXT.md` — Phase 76 locked decisions (**D-11–D-13** VERIFY ownership)
- `.planning/phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md` — ADM-13 inventory; cross-tab stragglers (**D-19**)

### VERIFY-01 host spine

- `examples/accrue_host/README.md` — VERIFY-01 / proof section
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — existing **`scanAxe`**, customers index pattern
- `examples/accrue_host/e2e/support/fixture.js` — `login`, `waitForLiveView`, `readFixture`, `reseedFixture`
- `examples/accrue_host/e2e/generated/copy_strings.json` — Playwright Copy SSOT
- `examples/accrue_host/docs/verify01-v112-admin-paths.md` — VERIFY path matrix (**extend for ADM-15**)
- `scripts/ci/accrue_host_verify_browser.sh` — browser / copy_strings gate (verify name in **`scripts/ci/README.md`**)

### Admin implementation

- `accrue_admin/lib/accrue_admin/live/customer_live.ex` — customer LiveView; **`payment_methods`** tab
- `accrue_admin/lib/accrue_admin/copy.ex` — **`defdelegate`** facade
- `accrue_admin/lib/accrue_admin/copy/customer_payment_methods.ex` — tab copy submodule
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — **`@allowlist`** + export task
- `accrue_admin/guides/theme-exceptions.md` — register + phase notes (**ADM-16**)
- `accrue_admin/test/accrue_admin/live/customer_live_test.exs` — ExUnit tab coverage

### Supplementary (non-merge-blocking for ADM-15 unless policy changes)

- `accrue_admin/e2e/phase7-uat.spec.js` — package UAT
- `.github/workflows/` — distinguish **`ci.yml`** host e2e vs **`accrue_admin_browser.yml`**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`verify01-admin-a11y.spec.js`**: `scanAxe`, `copyStrings` import pattern, theme toggle sequence, mobile **skip** pattern.
- **`fixture.js`**: org-scoped navigation primitives proven on other VERIFY flows.
- **`export_copy_strings`** + **`customer_payment_methods_*`** allowlist entries from Phase 76.

### Established Patterns

- **Merge-blocking VERIFY-01** lives under **`examples/accrue_host/e2e/`**, not **`accrue_admin/e2e/`**.
- **Theme exceptions**: table for real debt; narrative notes when audit is clean (Phase 55).

### Integration Points

- **`ci.yml`** `npm run e2e` path consumes host Playwright specs.
- **Playwright** reads **`e2e/generated/copy_strings.json`** — regenerate via Mix when **Copy** surface changes.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** gray areas be researched via subagents and resolved in one coherent pass emphasizing **DX**, **least surprise**, **OSS contributor clarity**, and alignment with **Accrue**’s “billing state, modeled clearly” + **VERIFY-01 as host contract** vision. Subagent synthesis converged on: **host `verify01-admin-a11y.spec.js` + customer detail PM deep link**, **critical/serious full-page axe light+dark**, **hybrid theme-exceptions**, **Mix-generated `copy_strings.json` + CI diff honesty**.

</specifics>

<deferred>
## Deferred Ideas

- **Splitting** `verify01-admin-a11y.spec.js` into multiple files — only if file size/review friction demands (**D-04**).
- **Global AxeBuilder `withTags` migration** for all VERIFY tests — separate policy phase if desired (**Claude's Discretion**).
- **gettext / Tier B host-overridable copy** — explicit non-goal for v1.24.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 77-customer-pm-tab-verify-theme-copy-export*  
*Context gathered: 2026-04-24*
