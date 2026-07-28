# CI-Green Remediation — design-system drift from never-CI-validated work

**Opened:** 2026-07-27
**Trigger:** Local `main` was 546 commits ahead of `origin/main` and had never been CI-validated
(the daily "green" scheduled runs were testing the stale origin). Syncing `main` to origin ran the
full gate for the first time and exposed accumulated drift — chiefly a large design-system
contract regression shipped (uncaught) by the Phase 209/210 "reign" work.

## Status snapshot (updated 2026-07-27, SESSION 2 — the tail is closed)

- **`accrue` package suite: ✅ GREEN** — 1685 tests, 0 failures, `--warnings-as-errors` clean
  (`--seed 0`). FND-01 annotated, FND-05 contrast checker fixed, DSY-01/RES-04/brand/CMP-05-anchor.
- **`accrue_admin` package suite: ✅ GREEN** — 514 tests, 0 failures, `--warnings-as-errors` clean.
  The last unit failure (ThemeTest storybook dark-shim, item 1 below) is FIXED, and a hidden
  `--warnings-as-errors` aborter (unused `alias AccrueAdmin.Copy` in `auth_hook_test.exs`, left by
  the earlier stale-test fix) is removed.
- **Docs-and-bash-contracts job: ✅** — `verify_package_docs.sh` + `verify_stable_core_posture.sh`
  both green locally; FND-05 semantic contrast math passes.
- **Admin browser guardrails (Phase 190/192): ✅** — `admin-group-contracts` (16/16), phase191
  "avoid clipping at required widths" (2/2) and "overlays trap focus" (2/2) all pass against the
  running e2e server.
- **Only unverified surface left:** the top-level **AccrueAdmin Browser UAT** workflow (item 3) —
  not yet run locally; everything the Phase 192 script covers is green.

### The tail — RESOLVED this session (commits `74a4c0be`, `b79e89e4`)

1. **ThemeTest storybook dark-shim drift** — ✅ FIXED (`74a4c0be`). Made the `.ax-theme-dark-shim`
   block verbatim-mirror theme.css for the 3 accent/focus tokens AND added `--ax-accent: #5d79f6`
   (the `layouts.ex` brand default) + `--accrue-paper: #0f1318` (dark base) inside the shim so the
   var/color-mix values still resolve in the runtime-brand-free storybook sandbox — exactly the
   recipe this doc prescribed. `priv/static/storybook.css` edited directly (hand-composed, no build
   task). Clears Admin Phase 200 + all Release gates.
2. **Admin browser guardrails (Phase 190/192) — `drawer-form portal shell` not visible** — ✅ FIXED
   (`b79e89e4`). REAL regression: the 209/210 reign replaced the dev-kitchen
   `<DetailDrawer.detail_drawer id="grp190-drawer-form-shell">` (a portaled Overlay supplying the id,
   `data-component-group="drawer-form"`, `-title`, focus-trap fallback) with a plain inline preview
   card. Re-wrapped the reign's richer content in DetailDrawer (Cancel/Save → `:footer`).
   ALSO surfaced a latent phase191 clip (subscription-detail @ phone-320, ~12px horizontal overflow;
   the phase192 script had been aborting at group-contracts before ever reaching it): three
   content-box elements with explicit `width` + padding/border and no box-sizing reset
   (`.ax-detail-priority-actions-compact`, `.ax-detail-open-invoice-queue`, mobile full-width
   `.ax-dropdown-trigger`/`.ax-dropdown-panel`) — added `box-sizing: border-box` to each, rebuilt the
   committed `accrue_admin.css` bundle.
3. **AccrueAdmin Browser UAT** — ✅ ALL 11 red specs fixed & verified against the running e2e
   server (commits `74a4c0be`, `b79e89e4`, `1dce1262`, `d30cbacc`, `97e67f79`, `515283e4`). Full
   inventory + resolutions:
   - `admin-a11y:38` (axe) — dark contrast fixes (`1dce1262`).
   - `admin-group-contracts:618` (operator-stress) — drawer portal shell (`b79e89e4`).
   - `phase191:219` (clipping) + `phase191:245` (focus-trap) — box-sizing clip + drawer shell.
   - `phase200:71` (final evidence) — cleared by the a11y + overlay fixes.
   - `phase196:73` (Subscriptions LIST) — column rename "Customer / subscription"→"Customer details".
   - `dropdown-dismiss:8` — kitchen label "More actions"→"More billing actions".
   - `foundation-tokens:64` (contrast) — parseColor accepts Chrome `color(srgb …)`.
   - `foundation-tokens:190` (auto-guard) — retarget `.ax-kpi-row`→`.ax-kpi-card`.
   - `phase7-uat:29` — Home h1 regression (source) + StatStrip/IA copy reconciliation + `.first()`.
   - `phase199:999` (auto-guard) — retarget `.ax-primary-nav`→`.ax-topbar` (both-viewport nav chrome).
   All pushed to origin/main; CI + Browser UAT re-validating.
4. **FND-01 follow-up (optional/future)** — 168 blocks annotated as exceptions (approved). The
   deliberate type-system pass can convert intentional ones to `.ax-type-*` primitives later.

## SESSION 2 outcome (2026-07-27 → 2026-07-28)

The tail is closed. Real regressions found & fixed at source (all shipped uncaught by the 209/210
reign because it was PNG-verified, never CI-validated): dark-shim drift, drawer-form portal shell
loss, subscription-detail 320px horizontal clip (3 box-sizing sites), two dark-mode AA contrast
failures, and the Home h1 (210-02 wired PageHeader `title=` to the wrong Copy fn, orphaning
`home_intro_headline/0`). The rest were legitimate stale-test drift from intentional reign copy
(column/label renames, StatStrip duplication → `.first()`, color-mix serialization, kitchen dropdown
label) and two parked-ratchet-guard retargets. Core CI (Release ×4, Phase 200, Phase 192,
Docs/posture) green locally; assets gate clean (bundle == source build); ratchet ledger self-test +
verify-frozen pass.

## Already fixed + pushed (mechanical, contract-defined — banked)

- `mix format` — 3 unformatted committed files (`fake_test.exs`, `accrue_admin.ui.round/fix.ex`). Commit `8823aaa3`.
- DSY-01 — 7 bare px-breakpoint `@media` rules annotated with `--ax-bp-*` comments. Commit `3d82e406`.
- RES-04 — sr-only `margin: -1px` annotated; `min-width:0` added to `.ax-search-trigger-text` truncation block (+ bundle rebuilt). Commit `3d82e406`.
- `brand.css` test (`application_test.exs:73`) — was `== 7`, brand.css legitimately grew to 21 single-word tokens (theming: surface/border/radius/shadow across light/dark/system). Now asserts `>= 7`; the 7-core-palette `for` loop still enforces the real contract. Commit `3d82e406`.
- FND-05 contrast checker (`verify_foundation_contrast.mjs`) — the `dark` scope regex couldn't match the refactored comma-grouped selector (`html.accrue-admin[data-theme="dark"], html.accrue-admin [data-theme="dark"], .accrue-admin [data-theme="dark"] {`). Regex now tolerates the group so the check can actually run. Commit `3d82e406`. NOTE: this makes the check *run* — the contrast **math** has not been validated yet (FND-01 exits the script first).

## The real blocker — FND-01 (208 sites) — THE pass

`accrue_admin/assets/css/app.css` has **208 raw type declarations** (`font-size`/`font-weight`/
`line-height`/`letter-spacing`) sitting directly in component CSS instead of going through the
`.ax-type-*` primitives. Old `main` (e2a24382) had **0**; the reign work added ~268 type
declarations and only annotated 78 → 208 unannotated. The `verify_package_docs.sh` FND-01 check
exits on the first hit, which cascades into **all 24 `Accrue.Docs.PackageDocsVerifierTest`
failures** (the "verifier succeeds" test runs the whole script; every negative "rejects X" test
sees the FND-01 message instead of its injected violation). So the entire `accrue` suite stays red
until FND-01 is resolved.

**Decision to make (per-site or bulk):**
- **(A) Annotate** each block with `/* ax-type-exception: <reason> */` — fast, mechanical, but 208
  annotations dilute the guard's intent (the guard exists to push type through primitives).
- **(B) Refactor** — route type through the `.ax-type-*` primitive classes in the HEEx/CSS so raw
  declarations disappear. Correct per design-system intent, but touches templates + many rules.
- Likely a **hybrid**: refactor where a primitive class cleanly applies; annotate genuinely
  bespoke cases (dev-kitchen specimens, weight-only emphasis) with honest reasons.
- Enumerate all 208 with: `awk '/@font-face/{f=1} f&&/}/{f=0;next} /ax-type-exception:/{e=1;next} /(font-size|font-weight|line-height|letter-spacing|font-family)[[:space:]]*:/{if(!f&&!e&&$0!~/font-family:[[:space:]]*var\(--ax-font-sans\)/)print FNR": "$0} e&&/}/{e=0}' accrue_admin/assets/css/app.css`

## Still to fix (after FND-01 unblocks the script)

- **FND-05 contrast math** — run `ROOT_DIR=$(pwd) node scripts/ci/verify_foundation_contrast.mjs`
  after FND-01 clears; the regex fix lets it run, but the actual light/dark/system contrast ratios
  are unvalidated. May pass, may reveal real contrast failures from the de-saturation passes.
- **Admin browser guardrails — Phases 190 & 192** — Playwright `drawer-form portal shell` element
  `toBeVisible` fails "across themes and breakpoints." **Possible real UI regression** from the
  reign work (or a stale spec). Needs reproduction against the running admin app.
- **AccrueAdmin Browser UAT** workflow — red, not yet triaged.
- **accrue_admin package suite — ENUMERATED (was 7 failures, now 2).** Commit `cc0d0e35` fixed 5
  stale tests (RelatedResources `ax-related-resources` class ×4 + `ax-related-item ` space;
  auth_hook headline→`<title>Dashboard</title>`; theme_test dark-selector regex). **2 remain, both
  real (not stale) — deferred to this pass:**
  - `AccrueAdmin.ThemeTest` "Storybook dark shim mirrors every dark ax token" — `storybook.css`
    dark shim hardcodes `#9bb5ff` where `theme.css` dark now uses `var(--ax-accent-readable)`.
    Real drift; `storybook.css` has no rebuild task (hand-composed, Phase 193) — recompose per the
    Phase 211 research recipe (`.planning/phases/211-.../211-RESEARCH.md` § Bundle Rebuild).
  - `AccrueAdmin.Queries.QueryModulesTest` "subscription queries use status-safe list filters" —
    `Subscriptions.list(status: active)` row set doesn't match the expected fixture. **Possibly a
    real status-filter regression** (data correctness) — investigate before assuming stale fixture.
- **accrue suite** — 25 failures were ALL verifier+brand; goes green once FND-01 lands (verified the
  brand fix already; the other 24 cascade off FND-01).
- **e2e / Browser UAT** — still not enumerated (need running admin app + Playwright).

## Meta-finding

Phases 209/210 are recorded "shipped & verified 2026-07-19" but were verified by PNG review + local
checks, **never by CI**. The CI design-system guards (FND-01/DSY-01/RES-04/FND-05) would have
blocked them. Phase 211 (CSS retirement, planned) sits on top of this. The remediation should
likely land **before or as part of** Phase 211 execution.

## Recommended kickoff

Scope as a tracked GSD debug/hardening phase, e.g. `/gsd-debug` for the drawer-form regression +
`/gsd-plan-phase` for the FND-01/contrast design-system remediation. Do NOT bulk-annotate 208 sites
unilaterally — the annotate-vs-refactor call is a design decision for the pass.
