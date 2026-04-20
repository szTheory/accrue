---
status: passed
phase: 28-accessibility-hardening
updated: 2026-04-20
---

# Phase 28 — Verification

## Merge gate (CI — no human checklist required)

Pull requests run **`.github/workflows/ci.yml`** → job **`host-integration`** → **`scripts/ci/accrue_host_uat.sh`** → **`cd examples/accrue_host && mix verify.full`**. The browser step (**`scripts/ci/accrue_host_verify_browser.sh`**) builds `accrue_admin` assets, runs **`mix deps.compile accrue_admin --force`**, boots the test server, then **`npm run e2e`** — the **full** Playwright suite, which includes **`e2e/verify01-admin-a11y.spec.js`** (axe serious + critical, light + dark on desktop).

Local equivalent (maintainer / pre-push):

```bash
bash scripts/ci/accrue_host_uat.sh
# or from examples/accrue_host:
mix verify.full
```

## Coverage (requirements)

| ID       | Evidence in this phase |
| -------- | ----------------------- |
| **A11Y-01** | Step-up: `Phoenix.LiveView.JS` `push_focus` / `focus_first` / `pop_focus` on the dialog; Escape + `StepUp.dismiss_challenge` on mounted money pages (see `step_up_auth_modal.ex`, `step_up.ex`, LiveView handlers). |
| **A11Y-02** | `DataTable` optional `table_caption` + visually hidden `<caption>`; **customers** and **webhooks** pass `Copy.*_table_caption/0` (see `data_table.ex`, `copy.ex`, live views). |
| **A11Y-03** | Host Playwright forces **light** then **dark** via `data-theme-target` and runs axe (serious + critical), including `color-contrast` when reported at those severities. |
| **A11Y-04** | `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — VERIFY-01-style journey (login → billing → org → **customers index**). |

## Automated (focused local iteration)

Same **`mix deps.compile accrue_admin --force`** requirement as CI when admin CSS changes (see `AccrueAdmin.Assets` compile-time embed in `accrue_admin/lib/accrue_admin/assets.ex`).

From `examples/accrue_host` after a normal e2e seed + server (or rely on **`mix verify.full`** for the full story):

```bash
cd ../../accrue_admin && mix accrue_admin.assets.build
cd ../examples/accrue_host && mix deps.compile accrue_admin --force
npm run e2e:a11y
```

Equivalent without the npm script:

```bash
npm run e2e -- e2e/verify01-admin-a11y.spec.js
```

The spec is **desktop-only** (theme toggles are hidden below the `md` breakpoint); mobile Playwright projects **skip** this file by design.

## Exploratory only (not merge-blocking)

28-CONTEXT **D-04** items are **not** asserted in CI; use when changing tokens, host `accent_hex`, or Phase 26 theme-exception paths — optional design review, not a release checklist:

- **Gradients / background-images** — layered surfaces; axe samples flattened RGB.
- **Layered overlays** — drawer / modal backdrops; focus order on blurred content.
- **Hover / focus / active / disabled** — states the axe journey does not exhaust.
- **Phase 26 theme-exception literals** — paths in `26-theme-exceptions.md` touched by new UI.
- **Host `accent_hex` / branding** — `--ax-accent` from `AccrueAdmin.Layouts` vs light/dark shells.

## Focus mechanism (A11Y-01)

- **Open:** `JS.push_focus()` then `JS.focus_first(to: "#accrue-admin-step-up-dialog")` on `phx-mounted` of the step-up dialog.
- **Close / success:** `JS.pop_focus()` on dismiss paths that complete the flow.
- **Escape / cancel:** `phx-window-keydown` + `StepUp.dismiss_challenge/1` on mounted pages when a step-up is pending.

## Table captions (A11Y-02)

- LiveComponent assign: `:table_caption` (optional; default `nil`).
- Desktop `<table>` renders `<caption class="ax-visually-hidden">` when assign is set; caption strings live in `AccrueAdmin.Copy` next to page headings.

## Layout note (data table)

Below `1024px` width, **card rows** are shown and the desktop `<table>` shell is `display: none`; from `1024px` up, the shell is shown and cards are hidden so only one representation is in the layout at a time (avoids duplicate contrast targets in axe).
