# Phase 50 — Verification gate

**Status:** Draft — fill inventory URLs after **`50-01`** / **`50-03`** land.

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
