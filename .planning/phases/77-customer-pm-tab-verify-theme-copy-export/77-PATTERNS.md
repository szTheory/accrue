# Phase 77 — Pattern map

Analogs for executor agents — **read these files before editing**.

## Playwright + axe (merge-blocking host)

| Target | Role | Closest analog | Excerpt / pattern |
|--------|------|----------------|-------------------|
| `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | New customer PM-tab test | `core-admin-invoices-index` describe + `mounted admin customers index` | `reseedFixture`, `login`, org button, `waitForLiveView`, `scanAxe`, light→dark, mobile `test.skip` |
| `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | `scanAxe` helper | self lines 15–17 | `AxeBuilder({ page }).analyze()` + filter `critical` \|\| `serious` |
| `examples/accrue_host/e2e/support/fixture.js` | Fixture + reseed | self | `readFixture`, `reseedFixture`, `ACCRUE_HOST_E2E_FIXTURE` |

## VERIFY documentation matrix

| Target | Analog | Notes |
|--------|--------|-------|
| `examples/accrue_host/docs/verify01-v112-admin-paths.md` | Phase 55 invoice rows | Pipe table: describe title \| path template \| requirement ids |

## Theme + copy

| Target | Analog | Notes |
|--------|--------|-------|
| `accrue_admin/guides/theme-exceptions.md` | Phase 53 / 55 reviewer notes | Narrative block under `## Phase … reviewer note` |
| `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` | self `@allowlist` | Regenerate JSON, never hand-edit `copy_strings.json` |

## LiveView surface under test

| File | Relevant region |
|------|------------------|
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | `@tabs`, `handle_params` tab normalization, `"payment_methods"` branch (~176–184) |

---

## PATTERN MAPPING COMPLETE
