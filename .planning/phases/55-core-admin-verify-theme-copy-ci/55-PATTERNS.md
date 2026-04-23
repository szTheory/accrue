# Phase 55 — Pattern map

Analogs for files this phase creates or modifies. Downstream executors: read these **before** editing.

| Planned touchpoint | Role | Closest analog | Notes |
|--------------------|------|----------------|-------|
| `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | VERIFY-01 + axe + `copyStrings` | Same file (customers / subscriptions / Connect blocks) | Reuse `login`, `waitForLiveView`, `scanAxe`, mobile skips, **`domcontentloaded`**. |
| `scripts/ci/accrue_host_seed_e2e.exs` | Deterministic fixture ids | `connect_account_id` emission + `insert_fixture_connect_account!` | Add **`invoice_id`** + cleanup mirroring **processor_id** fixture prefixes. |
| `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` | Allowlist | **53-02** plan + current `@allowlist` | Only add **0-arity** `AccrueAdmin.Copy` names used in specs. |
| `examples/accrue_host/e2e/generated/copy_strings.json` | Generated artifact | Current JSON (sorted keys) | Regenerate via Mix task; **no hand edits** of string values. |
| `accrue_admin/guides/core-admin-parity.md` | VERIFY matrix | Invoice rows + Connect/subscription precedent | Flip **`Named VERIFY flow id`** + **`VERIFY-01 lane`** in **same** change-set as specs. |
| `examples/accrue_host/docs/verify01-v112-admin-paths.md` | Spec ↔ path mapping | **Phase 53** auxiliary section | Add **Phase 55** invoice rows + `test.describe` titles. |
| `accrue_admin/guides/admin_ui.md` | Contributor link | `core-admin-parity.md` link style | Replace **`.planning/...26-theme-exceptions.md`** → **`theme-exceptions.md`**. |
| `accrue_admin/guides/theme-exceptions.md` | Exception register | Phase **53** reviewer note | Add slugged row **or** short audit note if zero deviations. |

## Excerpt — mobile skip + axe filter

From `examples/accrue_host/e2e/verify01-admin-a11y.spec.js`:

```javascript
test.skip(
  testInfo.project.name === "chromium-mobile" || testInfo.project.name === "chromium-mobile-tagged",
  "theme toggle is hidden below the md breakpoint; A11Y gate runs on desktop only"
);
// …
const results = await new AxeBuilder({ page }).analyze();
return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");
```

## PATTERN MAPPING COMPLETE
