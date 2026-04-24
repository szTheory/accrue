---
phase: 77-customer-pm-tab-verify-theme-copy-export
verified: ""
status: pending
---

# Phase 77 — Customer PM tab VERIFY + theme + copy export

Phase closure record for **v1.24** requirements **ADM-15** (merge-blocking VERIFY / axe on the customer **`payment_methods`** tab) and **ADM-16** (documented theme posture + **`export_copy_strings`** alignment). This file references paths and Copy keys only — no live credentials or processor identifiers.

## ADM-15 (VERIFY-01 / axe)

- **Playwright:** `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — `test.describe("VERIFY-01 admin customer detail payment_methods tab (v1.24 ADM-15)", …)` exercises `/billing/customers/:id?tab=payment_methods&org=<slug>` with light then dark theme toggles.
- **VERIFY matrix:** `examples/accrue_host/docs/verify01-v112-admin-paths.md` — subsection **`## Phase 77 — v1.24 ADM-15 (customer payment_methods tab)`** maps the exact `test.describe` title to the mounted path template and **ADM-15**.
- **Axe severity:** `scanAxe` in that spec filters violations to **`critical`** and **`serious`** impacts only (same helper as other VERIFY-01 admin journeys).

## ADM-16 (theme + copy export)

- **Theme register / reviewer note:** `accrue_admin/guides/theme-exceptions.md` — **`## Phase 77 reviewer note (customer payment_methods tab)`** records the **`CustomerLive`** **`payment_methods`** audit outcome for **ADM-14** / **ADM-15** surfaces.
- **Mix export (SSOT):** `cd accrue_admin && mix accrue_admin.export_copy_strings --out ../examples/accrue_host/e2e/generated/copy_strings.json`
- **Derived artifact:** `examples/accrue_host/e2e/generated/copy_strings.json` — regenerated **2026-04-24**; working tree showed **no diff** after export (artifact already matched Mix output).

## Closure checklist

- [ ] **ADM-15** satisfied — VERIFY-01 spec + matrix doc in place; axe helper unchanged in intent.
- [ ] **ADM-16** satisfied — Phase 77 theme reviewer note present; copy export command run with no drift.
- [ ] Merge-blocking CI intent unchanged — `scripts/ci/accrue_host_verify_browser.sh` still orchestrates export + Playwright VERIFY paths as before this phase (no script edit required for Phase 77 scope).

## Traceability

- **Roadmap:** `.planning/ROADMAP.md` — Phase **77** row under **v1.24** (customer PM tab VERIFY + theme + copy export).
- **Requirements:** `.planning/REQUIREMENTS.md` — **ADM-15**, **ADM-16** (operator surfaces + hygiene).
- **Playwright projects:** desktop projects run the new describe; mobile projects `test.skip` where the theme toggle is unavailable below the `md` breakpoint.
