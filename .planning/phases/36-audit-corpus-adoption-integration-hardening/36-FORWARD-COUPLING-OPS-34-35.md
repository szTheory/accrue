# Forward coupling — OPS-03, OPS-04, OPS-05 (Phases 34–35)

Phase **36** does not implement new operator UI; it records **contracts to preserve** from Phases **34–35** so later edits do not fork copy, navigation truth, or Playwright SSOT.

## OPS-03 (route matrix / nav order)

- **`AccrueAdmin.Nav`** (`accrue_admin/lib/accrue_admin/nav.ex`) is the canonical owner of operator-facing navigation labels and order.
- **`accrue_admin/test/accrue_admin/nav_test.exs`** and **`accrue_admin/test/accrue_admin/components/navigation_components_test.exs`** encode expected ordering and shell wiring; changes to sidebar entries should update these tests in the same change set.
- **`accrue_admin/README.md`** section **Admin routes** must stay aligned with **`AccrueAdmin.Router.accrue_admin/2`** and the shipped `live/3` route list (monotonic router order as documented there).
- Avoid introducing a second “shadow” route matrix in prose or ad-hoc docs without updating the README inventory and tests above.

## OPS-04 (summary / KPI surfaces)

New summary or KPI rows must follow **UX-04** token discipline from Phase **35** planning artifacts (see `.planning/phases/35-summary-surfaces-test-literal-hygiene/35-CONTEXT.md` and that phase’s plans): theme tokens (`--ax-*`, `ax-*`) and documented exceptions only—no new KPI patterns here.

## OPS-05 (Copy + Playwright literals)

Operator-visible strings belong in **`AccrueAdmin.Copy`** (and existing locked/legal gates where applicable). **Playwright** specs under **`examples/accrue_host/e2e/`** must not accumulate literals that diverge from LiveView/Copy SSOT. Phase **35** remains the verification owner for literal hygiene in the v1.7 operator scope.

### Related documentation

- Dual README / script maintenance expectations for contributors: **`accrue/guides/testing.md`** — section **Adoption documentation contracts (dual README gates)**.
