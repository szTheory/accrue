# Phase 31: Advisory integration alignment - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `31-CONTEXT.md` — this log preserves rationale and research synthesis.

**Date:** 2026-04-21  
**Phase:** 31-advisory-integration-alignment  
**Areas discussed:** README ↔ CI contract; npm script surface; `AccrueAdmin.Copy` scope; dual Playwright alignment  
**Mode:** User selected **all** gray areas and requested **parallel subagent research** + one-shot cohesive recommendations (synthesized into `31-CONTEXT.md`).

---

## README ↔ CI contract (`verify_verify01_readme_contract.sh`)

| Approach | Description | Role in Phase 31 |
|----------|-------------|------------------|
| Substring anchors (current) | Fast, readable CI failures; stable markers | **Extend** for MOB parity (Tier A) |
| Filesystem “mentioned spec exists” | Catches renames vs prose | **Optional** Tier B if cheap |
| Generated README / manifest SSOT | DRY for volatile lists | **Deferred** — process overhead |
| Mix task doc contract | Idiomatic Elixir consumer | **Deferred** unless bash hits limits |

**User's choice:** **Tier A + optional Tier B** — symmetric anchors for mobile + a11y; optional mechanical file-existence loop; avoid manifest/codegen in this phase.

**Notes (research synthesis):** Library repos fail when README, CI, and bash allowlists form **triple SSOT**; keep narrative README, cap substring list, prefer **filesystem checks** over English-only coupling for spec renames. Billing-adjacent **high-severity** prose rules stay **narrow** (e.g. `sk_live` negation).

---

## npm script surface (`examples/accrue_host/package.json`)

| Option | Description | Selected |
|--------|-------------|----------|
| `e2e:mobile` beside `e2e:a11y` | Parallel focused lanes, same env hygiene | ✓ |
| `test:*` namespace | Competes with `mix test` mental model | ✗ |
| Flags-only (`npm run e2e -- --project=…`) | Fewer scripts, worse discoverability | Partial — document flags **after** shortcuts exist |

**User's choice:** Add **`e2e:mobile`** mirroring **`e2e:a11y`**; keep **`e2e`** wide; README + contract assert advertised shortcuts.

**Notes:** Ecosystem pattern for library monorepos — **Mix owns orchestration**, npm owns **Playwright runner**; avoid script explosion beyond a small **`e2e:*`** family; note POSIX `env -u` for Windows contributors if not already documented.

---

## `AccrueAdmin.Copy` SSOT sweep scope

| Option | Description | Selected |
|--------|-------------|----------|
| Strict all-LiveViews | Maximum consistency | ✗ — churn / non-normative noise |
| Tiered (VERIFY-01 + money + step-up) | Risk-aligned | ✓ |
| Docs-only exceptions | Cheap | ✗ — drifts |
| Generated registry / gettext | Inventory / i18n | **Deferred** |

**User's choice:** **Tiered governance** — finish audit-called surfaces; expand **`Copy.Locked`** only for verbatim-contract strings; Playwright uses literals **selectively**.

**Notes:** Filament/Nova/ActiveAdmin teach that integrators treat **APIs and behaviors** as stable before paragraph prose; Elixir **named functions** beat gettext-for-a-library before a real i18n milestone.

---

## Dual Playwright (`accrue_host` vs `accrue_admin`)

| Option | Description | Selected |
|--------|-------------|----------|
| Host-only canonical | Single truth for VERIFY-01 | **Principle** — host is law |
| Admin smoke / advisory / dedup literals | Package speed + boundary | ✓ — **narrow** admin suite assertions |
| Shared support via symlink | DRY | ✗ — boundary + Windows |
| npm workspace shared package | DRY | **Deferred** |

**User's choice:** **Host canonical** for merge-blocking truth; **admin** job/specs **stop duplicating host literals** (roles/testids or smoke posture); **no** admin→host symlinks.

**Notes:** Cypress/component-lib pattern is **consumer-app E2E** for release truth; matches Phase **21/28/29** pyramid; dual seeds/configs are the **drift vector** — reduce literal duplication, not necessarily delete all admin browser runs in one shot.

---

## Claude's Discretion

Implementation details for Tier B contract mechanics, exact `accrue_admin_browser.yml` posture (smoke vs advisory vs assertion-only), and final substring wording once filenames stabilize — captured in `31-CONTEXT.md` **Claude's Discretion** section.

## Deferred Ideas

See `<deferred>` in `31-CONTEXT.md` (manifest/codegen, npm workspaces, gettext, route-matrix expansion).
