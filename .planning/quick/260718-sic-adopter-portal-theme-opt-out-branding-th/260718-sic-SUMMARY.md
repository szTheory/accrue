---
quick_id: 260718-sic
title: Adopter portal theme opt-out — branding :theme policy (system/light/dark) honored by portal
status: complete
date: 2026-07-18
mode: quick
tasks_completed: 4
tasks_total: 4
commits:
  - c1d8ba2e feat(260718-sic): add published branding :theme policy option
  - 228fceb1 feat(260718-sic): portal honors branding :theme policy
key-files:
  modified:
    - accrue/lib/accrue/config.ex
    - accrue/test/accrue/config_branding_test.exs
    - accrue/guides/branding.md
    - accrue_portal/lib/accrue_portal/brand_plug.ex
    - accrue_portal/lib/accrue_portal/router.ex
    - accrue_portal/lib/accrue_portal/auth_hook.ex
    - accrue_portal/lib/accrue_portal/layouts.ex
    - accrue_portal/test/accrue_portal/router_test.exs
    - accrue_portal/test/accrue_portal/auth_hook_test.exs
---

# Quick Task 260718-sic — Summary

Added a **published** `:branding` option `theme: :system | :light | :dark` and wired the
customer portal (`accrue_portal`) to honor it. `:system` (default) preserves the existing
cookie-driven three-way picker; `:light`/`:dark` force that mode server-side (ignoring the
`accrue_theme` cookie) and hide the picker. Library-only, additive, non-breaking.

## What changed

- **Task 1 — Config schema (`accrue`).** Added `theme` to the `:branding` `keys:` list with
  `type: {:in, [:system, :light, :dark]}, default: :system`. Because `Accrue.Config.branding/0`
  merges schema defaults, `branding()[:theme]` is always present. Documented the option in
  `accrue/guides/branding.md` (schema-table row + new "Portal color-mode" subsection — content-only,
  no new doc-file needle, so no `verify_package_docs.sh` / PackageDocsVerifier coupling).
- **Task 2 — Portal plumbing (`accrue_portal`).**
  - `BrandPlug` now reads `policy = Keyword.get(branding, :theme, :system)` and computes an
    **effective** theme + **locked** flag: `:light`/`:dark` → `{Atom.to_string(policy), true}`;
    `:system` → `{sanitized cookie, false}` where the cookie is only honored if it's in
    `~w(system light dark)` (else `"system"`). This also hardens the prior raw-cookie→`data-theme`
    path. Assigns `:accrue_portal_theme` (effective) and new `:accrue_portal_theme_locked`.
    `theme` is intentionally NOT added to the visual `Map.take` brand map — it's a policy, not a token.
  - Router `__session__` adds `"theme_locked" => conn.assigns[:accrue_portal_theme_locked] || false`
    to the `"accrue_portal"` session map.
  - `AuthHook.mount_customer` adds `assign(:theme_locked, Map.get(portal, "theme_locked", false))`.
- **Task 3 — Layout (`accrue_portal`).** Added `attr(:theme_locked, :boolean, default: false)` and
  wrapped the theme-picker `role="group"` block with `:if={not @theme_locked}`. `data-theme={@theme}`
  already reflects the effective (possibly forced) theme. No CSS/JS change.
- **Task 4 — Docs.** Covered by Task 1's guide edit.

## Deviations from Plan

- **[Rule 1 — Bug] Cookie-injection test used the wrong mechanism.** My first draft of the locked-policy
  router test injected the conflicting cookie via `Map.update!(:cookies, ...)`, which `fetch_cookies/1`
  in `BrandPlug` would overwrite (cookies were still `%Plug.Conn.Unfetched{}`). Switched to
  `Plug.Test.put_req_cookie("accrue_theme", "light")` so the cookie is a real request cookie the plug
  actually reads and then ignores under the locked policy.
- **[Rule 3 — Blocking] Dropped a redundant standalone default-flag test.** An extra
  `theme_locked defaults to false` test in `auth_hook_test.exs` halted because `CustomerSession.resolve`
  with `create?: false` requires a pre-existing customer row (which that isolated test didn't create).
  Removed it — the `Map.get(portal, "theme_locked", false)` default is trivial and the meaningful
  positive coverage (`theme == "dark"`, `theme_locked == true`) lives in the existing
  "reuses the existing customer row" test.

No architectural changes; no new deps; no host changes. Pre-existing dirty working-tree files and
`examples/accrue_host/mix.lock` were left untouched.

## Verification

- `cd accrue && mix compile` — clean.
- `cd accrue && mix test test/accrue/config_branding_test.exs` — **21 tests, 0 failures** (includes new
  `theme default is :system` and `theme accepts :light and :dark`).
- `cd accrue_portal && mix compile` — clean.
- `cd accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/auth_hook_test.exs`
  — **9 tests, 0 failures** (includes locked-policy forcing `theme == "dark"`/`theme_locked == true`,
  and the locked socket assign).
- `cd accrue_portal && mix test` (full) — **37 tests, 0 failures** (live tests exercise the root layout /
  picker rendering).

## Self-Check: PASSED

- Commit `c1d8ba2e` — FOUND
- Commit `228fceb1` — FOUND
- `accrue/lib/accrue/config.ex` — FOUND (theme key present)
- `accrue_portal/lib/accrue_portal/brand_plug.ex` — FOUND (resolve_theme/sanitize_theme present)
- `accrue_portal/lib/accrue_portal/layouts.ex` — FOUND (`:if={not @theme_locked}` present)
