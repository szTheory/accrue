# CI-Green Remediation — design-system drift from never-CI-validated work

**Opened:** 2026-07-27
**Trigger:** Local `main` was 546 commits ahead of `origin/main` and had never been CI-validated
(the daily "green" scheduled runs were testing the stale origin). Syncing `main` to origin ran the
full gate for the first time and exposed accumulated drift — chiefly a large design-system
contract regression shipped (uncaught) by the Phase 209/210 "reign" work.

## Status snapshot

| Workflow | State |
|----------|-------|
| Release Please | ✅ green |
| CI | ❌ red — blocked by FND-01 (below) |
| AccrueAdmin Browser UAT | ❌ red — not yet triaged |

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
- **Unknown remainder** — the `accrue` suite's 25 failures were ALL verifier+brand (so it should go
  green once FND-01 lands). But the **accrue_admin package test suite and full e2e were never
  enumerated** — more failures may hide behind the FND-01 block. Run `cd accrue_admin && mix test`
  and the e2e gates once FND-01 is resolved.

## Meta-finding

Phases 209/210 are recorded "shipped & verified 2026-07-19" but were verified by PNG review + local
checks, **never by CI**. The CI design-system guards (FND-01/DSY-01/RES-04/FND-05) would have
blocked them. Phase 211 (CSS retirement, planned) sits on top of this. The remediation should
likely land **before or as part of** Phase 211 execution.

## Recommended kickoff

Scope as a tracked GSD debug/hardening phase, e.g. `/gsd-debug` for the drawer-form regression +
`/gsd-plan-phase` for the FND-01/contrast design-system remediation. Do NOT bulk-annotate 208 sites
unilaterally — the annotate-vs-refactor call is a design decision for the pass.
