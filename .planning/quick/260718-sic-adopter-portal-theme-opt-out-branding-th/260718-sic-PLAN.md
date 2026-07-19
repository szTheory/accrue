---
quick_id: 260718-sic
title: Adopter portal theme opt-out — branding :theme policy (system/light/dark) honored by portal
status: planned
date: 2026-07-18
mode: quick
---

# Quick Task 260718-sic — Plan

## Goal
Let an adopter declare which color modes the customer portal offers, via a new **published** `:branding`
option `theme: :system | :light | :dark` (confirmed with user):
- `:system` (default) → offer both modes + the 3-way picker; user preference via the `accrue_theme` cookie,
  defaults to OS. (Current behavior.)
- `:light` / `:dark` → **force** that mode (ignore the cookie) and **hide the picker** (the affordance = no
  picker when there's no choice). Makes single-mode opt-out trivial for adopters who don't want to theme both.
Library-only (core `accrue` config + `accrue_portal`); no host change required.

Confirmed: `Accrue.Config.branding/0` merges schema defaults, so once `theme` is in the schema it's always
present (`Keyword.fetch!`-able). BrandPlug already reads the `accrue_theme` cookie → `@theme`; it will now also
read the policy and compute an **effective** theme + a **locked?** flag threaded to the layout.

## Tasks

### Task 1 — Add `theme` to the published branding schema
- **files:** `accrue/lib/accrue/config.ex` (the `:branding` `keys:` list, ~line 348)
- **action:** Add:
  ```elixir
  theme: [
    type: {:in, [:system, :light, :dark]},
    default: :system,
    doc:
      "Customer portal color-mode policy. `:system` (default) offers light + dark with a picker " <>
        "(follows the OS, user-switchable via the `accrue_theme` cookie). `:light` or `:dark` locks " <>
        "the portal to that mode and hides the picker."
  ],
  ```
- **verify:** `cd accrue && mix compile` clean; `mix test test/accrue/config_branding_test.exs` green (update
  that test if it asserts the exact key/default set — add a positive assertion that `theme` defaults to
  `:system`).
- **done:** `Accrue.Config.branding()[:theme]` returns `:system` by default and the set value otherwise.

### Task 2 — Portal honors the policy (effective theme + locked flag)
- **files:**
  - `accrue_portal/lib/accrue_portal/brand_plug.ex` — after reading `Accrue.Config.branding()`, get
    `policy = Keyword.get(branding, :theme, :system)`. Compute:
    - if `policy in [:light, :dark]` → `effective = Atom.to_string(policy)`, `locked = true`;
    - else → `effective = sanitized cookie` (only `~w(system light dark)`, else `"system"`), `locked = false`.
    Replace the current `assign(:accrue_portal_theme, cookie || "system")` with `assign(:accrue_portal_theme,
    effective)` and add `assign(:accrue_portal_theme_locked, locked)`. (Sanitizing the cookie also hardens the
    existing raw-cookie-into-`data-theme` path.)
  - `accrue_portal/lib/accrue_portal/router.ex` — in `__session__`, add
    `"theme_locked" => conn.assigns[:accrue_portal_theme_locked] || false` to the `"accrue_portal"` session map
    (next to the existing `"theme" => …`).
  - `accrue_portal/lib/accrue_portal/auth_hook.ex` — in `mount_customer`, add
    `assign(:theme_locked, Map.get(portal, "theme_locked", false))` alongside the existing `assign(:theme, …)`.
- **verify:** `cd accrue_portal && mix compile` clean; `mix test test/accrue_portal/router_test.exs
  test/accrue_portal/auth_hook_test.exs` green (update if they assert the session/socket shape — add
  assertions for `theme_locked`).
- **done:** Locked policies force the mode server-side regardless of cookie; `:system` keeps cookie-driven
  behavior; `@theme_locked` reaches the layout.

### Task 3 — Layout hides the picker when locked
- **files:** `accrue_portal/lib/accrue_portal/layouts.ex`
- **action:** Add `attr(:theme_locked, :boolean, default: false)`. Wrap the theme-picker `role="group"` block
  with `:if={not @theme_locked}` so it renders only when the adopter offers a choice. `data-theme={@theme}`
  already reflects the effective (possibly forced) theme — no other change. (No CSS/JS change: when the picker
  is absent, the delegated `[data-portal-theme]` handler simply finds nothing.)
- **verify:** `mix compile` clean.
- **done:** `theme: :light|:dark` → no picker + forced mode; `:system` → picker as before.

### Task 4 — Document the option
- **files:** `accrue/guides/branding.md`
- **action:** Add a short subsection documenting `theme` (`:system`/`:light`/`:dark`) and its effect on the
  mounted portal (picker vs. locked). Content-only edit to an existing guide (does NOT add a new doc-file
  needle to verify_package_docs.sh, so no PackageDocsVerifier coupling).
- **verify:** n/a (prose).
- **done:** Adopters can discover the option from the branding guide.

## Guardrails
- Library-only; no host change; no new deps. Additive to the published branding schema (new optional key with
  a safe default — non-breaking). Keep existing `--accrue-*` tokens + picker behavior for `:system`.
- Leave pre-existing dirty working-tree files + `mix.lock` untouched. Do NOT build deferred items (admin
  settings surface, admin re-skin).

## Verification (end-to-end)
1. `cd accrue && mix compile` + `cd accrue_portal && mix compile` clean; targeted tests above green
   (`accrue` config_branding + `accrue_portal` router/auth_hook), plus `cd accrue_portal && mix test` full.
2. (Live, optional) With demo `branding` unset for `theme` → picker present (current). Temporarily set
   `theme: :light` in the host config → `/billing` renders `data-theme="light"` forced (even on a dark OS) and
   the picker is absent; revert. (Demo host config change is only for the manual check — do NOT commit it.)
