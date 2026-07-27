# CI-Green Remediation — design-system drift from never-CI-validated work

**Opened:** 2026-07-27
**Trigger:** Local `main` was 546 commits ahead of `origin/main` and had never been CI-validated
(the daily "green" scheduled runs were testing the stale origin). Syncing `main` to origin ran the
full gate for the first time and exposed accumulated drift — chiefly a large design-system
contract regression shipped (uncaught) by the Phase 209/210 "reign" work.

## Status snapshot (updated 2026-07-27, end of remediation session)

- **`accrue` package suite: ✅ GREEN** (was 25 failures → 0). FND-01 annotated, FND-05 contrast
  checker fixed, DSY-01/RES-04/brand/CMP-05-anchor all fixed.
- **`accrue_admin` package suite: 1 failure left** (was 7 → 1). 6 stale tests fixed; the remaining
  one is the storybook-shim design item below.
- **Docs-and-bash-contracts job: should be ✅** (full `verify_package_docs.sh` passes locally).
- **Remaining CI red:** the 1 admin ThemeTest failure (blocks the Release gate), the admin browser
  guardrail gates (drawer-form — needs the running app), and Browser UAT (needs the running app).

### Remaining work (the real tail)

1. **ThemeTest storybook dark-shim drift** — `theme.css` dark now uses `var(--ax-accent-readable)` /
   `color-mix(in srgb, var(--ax-accent) …)` for 3 tokens (`--ax-accent-readable`, `--ax-focus-ring`,
   `--ax-focus-shadow`), but the storybook `.ax-theme-dark-shim` holds resolved hexes (`#9bb5ff`,
   `rgba(155,181,255,.24)`). The test wants verbatim mirroring, BUT `--ax-accent` is **not defined in
   the storybook sandbox** (it's runtime brand-injected via `layouts.ex`). So the correct fix is to
   add `--ax-accent` (default `#5d79f6`) + any needed `--accrue-*` to the sandbox so a verbatim-var
   shim resolves — a deliberate storybook-theming change on the composed `priv/static/storybook.css`.
   Do NOT just var-ify the shim (breaks dark rendering in the sandbox). Fold with the Phase 211
   storybook.css recomposition.
2. **Admin browser guardrails (Phase 190/192) — `drawer-form portal shell` not visible** — possible
   real UI regression; needs reproduction against the running admin app + Playwright.
3. **AccrueAdmin Browser UAT** — needs running app; untriaged.
4. **FND-01 follow-up (optional/future)** — 168 blocks are annotated as exceptions (approved). The
   deliberate type-system pass can convert intentional ones to `.ax-type-*` primitives later.

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
