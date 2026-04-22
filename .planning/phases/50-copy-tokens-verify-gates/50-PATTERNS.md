# Phase 50 — Pattern Map

**Phase:** 50 — Copy, tokens & VERIFY gates  
**Sources:** `50-CONTEXT.md`, `50-RESEARCH.md`, codebase scan

---

## Analog: Copy module growth

| New / target | Analog | Excerpt / rule |
|--------------|--------|----------------|
| `lib/mix/tasks/accrue_admin.*.ex` | `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` | `use Mix.Task`, `@shortdoc`, run from `accrue_admin/` root |
| `defdelegate` to `Copy.*` submodule | Future `AccrueAdmin.Copy.Dashboard` | Keep **`alias AccrueAdmin.Copy`** at call sites per **50-CONTEXT D-07** |

---

## Analog: LiveView operator strings

| File | Role | Pattern |
|------|------|---------|
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | Breadcrumb + `ScopedPath` | Copy + `customer_label/1` style |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | KPI labels | **`Copy.dashboard_*`** only in HEEx for operator text |
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Drill + actions | Mixed — **Phase 50** completes migration for remaining literals |

---

## Analog: VERIFY-01 host e2e

| File | Role |
|------|------|
| `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | Login → navigate → `waitForLiveView` → axe |
| `examples/accrue_host/e2e/support/fixture.js` | `reseedFixture`, `login`, `waitForLiveView` |

---

## Data flow: anti-drift export

```
AccrueAdmin.Copy (Elixir) --mix task--> examples/accrue_host/e2e/generated/copy_strings.json
                                                    |
                                            verify01-*.spec.js (require)
```

**Rule:** Generated JSON is **build artifact** — document in **`examples/accrue_host/README.md`** whether it is **committed** (deterministic CI) or **generated in CI** before e2e; pick one strategy in execution.

---

## PATTERN MAPPING COMPLETE
