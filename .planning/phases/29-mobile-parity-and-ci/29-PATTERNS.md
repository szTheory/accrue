# Phase 29 — Pattern Map

## Analog: horizontal overflow

| Role | File | Excerpt / convention |
|------|------|------------------------|
| Assertion | `examples/accrue_host/e2e/phase13-canonical-demo.spec.js` | `expectNoHorizontalOverflow` compares `documentElement.scrollWidth` to `window.innerWidth + 1` |
| Target | New `examples/accrue_host/e2e/support/overflow.js` | Export same function; keep tolerance **+1** px |

## Analog: project-gated specs

| Role | File | Pattern |
|------|------|---------|
| Desktop-only | `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` | `test.skip(testInfo.project.name === "chromium-mobile" \|\| ..., "reason")` |
| Mobile-only (this phase) | New MOB spec | `test.skip(testInfo.project.name !== "chromium-mobile", "…")` on `test.describe` or each test |

## Analog: VERIFY-01 spine

| Role | File | Pattern |
|------|------|---------|
| Login + billing | `examples/accrue_host/e2e/verify01-admin-mounted.spec.js` | `readFixture`, optional `reseedFixture`, `login`, `Go to billing`, `waitForLiveView`, org switcher, `?org=` URL |

## Analog: shell chrome

| Role | File | Pattern |
|------|------|---------|
| Menu control | `accrue_admin/lib/accrue_admin/components/topbar.ex` | `button[data-sidebar-toggle="true"]` + `getByRole("button", { name: "Menu" })` |
| Nav links | `accrue_admin/lib/accrue_admin/components/sidebar.ex` | `aside.ax-sidebar` / `a.ax-sidebar-link` with visible `Dashboard`, `Customers`, … labels |
| Responsive grid | `accrue_admin/assets/css/app.css` | `@media (min-width: 1024px)` shows sidebar; below that `.ax-sidebar { display: none }` until open-state class added |

## Gap (executor must close)

- **No current JS** listens for `[data-sidebar-toggle]` — mobile nav is non-functional until `accrue_admin` client bundle adds toggle + Escape + CSS overlay (Phase 29 MOB-02).
