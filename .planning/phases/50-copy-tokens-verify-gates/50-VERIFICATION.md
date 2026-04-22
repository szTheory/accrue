# Phase 50 — Verification gate

**Status:** Active — inventory + export pipeline landed in plans **`50-01`..`50-03`**; extend Playwright row-by-row as VERIFY-01 coverage grows.

Mounted-path inventory for VERIFY-01 expansion lives at **`examples/accrue_host/docs/verify01-v112-admin-paths.md`** (seeded in plan **`50-01`**).

## Canonical artifacts

| Artifact | Purpose |
|----------|---------|
| `accrue_admin/guides/theme-exceptions.md` | **ADM-05** exception register (**D-10**) |
| `examples/accrue_host/docs/verify01-v112-admin-paths.md` | **ADM-06** mounted-path inventory (**D-15**) |

## Merge-blocking checklist (executor)

- [ ] Every row in **`verify01-v112-admin-paths.md`** has a **Playwright** flow (merge-blocking job) **or** explicit waiver with reason in this file.
- [ ] **`theme-exceptions.md`** documents every **intentional** non-token exception introduced in v1.12 churn (**D-11**).
- [ ] **`npm run e2e`** (VERIFY-01) green for **chromium** desktop project used in CI.

*Linked from **50-CONTEXT.md** **D-11**.*

## Anti-drift (ADM-04 + ADM-06)

**D-23:** `mix accrue_admin.export_copy_strings` is merge-blocking via
`scripts/ci/accrue_host_verify_browser.sh` (runs before `npm run e2e` and writes
`examples/accrue_host/e2e/generated/copy_strings.json`). VERIFY-01 Playwright
specs must load that JSON (`require` / `readFileSync` from `e2e/generated/`) for
at least one assertion so operator strings cannot drift silently away from
`AccrueAdmin.Copy`.
