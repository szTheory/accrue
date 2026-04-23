# Phase 55: Core admin VERIFY + theme + copy CI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`55-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 55 — core admin VERIFY + theme + copy CI  
**Areas discussed:** Named VERIFY flow ids + parity matrix; PDF / new tab / download CI; `export_copy_strings` + allowlists; Theme-exceptions + contributor SSOT  

**Mode:** User selected **all** gray areas; maintainer requested **parallel subagent research** + one-shot synthesized recommendations (no interactive per-question turns).

---

## 1 — Named VERIFY flow ids + parity matrix

| Option | Description | Selected |
|--------|-------------|----------|
| A | Kebab slug duplicated verbatim in `test.describe` | |
| B | Lane + short slug composed (`VERIFY-01` + `invoice-create`) | |
| C | Human title + bracketed machine id + lint | |
| D | Central registry JSON/codegen driving matrix + tests | |
| **E (chosen)** | **Lock to `55-UI-SPEC` examples** `core-admin-invoices-index` / `core-admin-invoices-detail` + pattern `core-admin-<surface>-<role>` + tags / top-level describe binding + matrix flip same PR | ✓ |

**User's choice:** Delegate synthesis — **canonical ids per UI-SPEC** with Playwright tag/`describe` binding, matrix **`merge-blocking`** flip same change-set, CI matrix→tests guard (**D-01–D-06**).

**Notes:** Research favored generic `verify-{lane}-{slug}`; **cohesion** with approved **55-UI-SPEC** examples overrode for zero doc churn on naming examples.

---

## 2 — PDF / new tab / download in merge-blocking CI

| Option | Description | Selected |
|--------|-------------|----------|
| A | Full strict popup/download/%PDF always on `main` | |
| B | Navigate + shell smoke only | |
| C | Advisory / nightly for heavy PDF | |
| **D (chosen)** | **Tiered:** merge-blocking = **record UI + a11y + control wiring** (D-07); **strict** popup/download/%PDF when deterministic (D-08); **documented advisory** only after bounded honest attempt — **never** silent downgrade (D-09) | ✓ |

**User's choice:** Research-default **B+C** enriched with **55-UI-SPEC** “fix first” ethos — **D-07–D-11**.

**Notes:** Emphasized `waitForEvent` **before** click, avoid `networkidle` religion, **axe** stays on HTML surfaces not PDF structure.

---

## 3 — `export_copy_strings` + allowlists + JSON

| Option | Description | Selected |
|--------|-------------|----------|
| A | CI regenerates; commit advisory | |
| B | Strict `git diff --exit-code` only | |
| C | Hybrid CI prelude + commit when closure changes | ✓ |
| D | Split JSON shards | (defer **D-16** only if pain) |

**User's choice:** **Hybrid (C)** + deterministic export (**D-12–D-14**); optional **B** hardening as **D-15** discretionary; sharding deferred (**D-16**).

**Notes:** Aligns gettext/i18n lesson — **deterministic** generated artifacts + **narrow allowlist** keyed to VERIFY consumers.

---

## 4 — Theme-exceptions + contributor docs

| Option | Description | Selected |
|--------|-------------|----------|
| A | Package guide SSOT only | ✓ (part of **D-17**) |
| B | Planning SSOT | |
| C | Two registers | |
| **D (chosen)** | **New rows** only for warranted deviations (**D-18**) **plus** **same-phase link hygiene** for stale `admin_ui.md` paths (**D-19**) | ✓ |

**User's choice:** Single **`accrue_admin/guides/theme-exceptions.md`** SSOT; fix **`admin_ui.md`** dead `.planning/26-...` link in Phase 55 as hygiene.

---

## Claude's discretion

- CI guard implementation details (**D-05**), whether **D-15** ships in 55 vs follow-up, timeout tuning for strict PDF layer.

## Deferred ideas

- See **`55-CONTEXT.md`** `<deferred>` — bidirectional CI, JSON sharding, post-export diff gate, nightly PDF fidelity suite.
