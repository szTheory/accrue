# Phase 50 — Technical Research

**Question:** What do we need to know to **plan** Copy enforcement, theme exception registry, and VERIFY-01 extensions well?

**Status:** Ready for planning  
**Date:** 2026-04-22

---

## 1. Enforcement surface (ADM-04)

- **Primary glob:** `accrue_admin/lib/accrue_admin/live/**/*.ex` and `accrue_admin/lib/accrue_admin/components/**/*.ex` per **50-CONTEXT D-01**.
- **Heuristic:** Grep for HEEx attributes containing English sentence fragments (`>…<`, `label: "`, `placeholder: "`) and compare against `AccrueAdmin.Copy` / `Copy.` calls — literals not backed by `Copy` are candidates.
- **Git diff:** Useful as **CI advisory** or PR comment, not merge-blocking definition — noise from docs and non-UI paths (**D-02**).
- **Module split:** `defdelegate` from `AccrueAdmin.Copy` to `AccrueAdmin.Copy.Dashboard`, `.Subscription`, etc. keeps call sites `alias AccrueAdmin.Copy` stable (**D-07**).

---

## 2. Anti-drift Copy ↔ Playwright (D-23)

| Approach | Pros | Cons |
|----------|------|------|
| **Mix task** writes `examples/accrue_host/e2e/generated/copy-strings.json` from runtime string values | Single source; JS imports JSON; CI runs `mix` before e2e in workflow or pre-step | Requires task + gitignore or committed artifact policy |
| **ExUnit contract** compares spec file substrings to `Copy` | No Node step | Fragile for regex-heavy specs; duplicates path logic |

**Recommendation:** **`mix accrue_admin.export_copy_strings`** (name negotiable) under `accrue_admin` **:dev** or invoked from **`scripts/ci`** — enumerates selected `Copy` functions (explicit allowlist in task module to avoid exporting secrets). Host e2e **`require()`**s generated JSON. Document regeneration in **`examples/accrue_host/README.md`**.

---

## 3. Theme exception register (ADM-05)

- **Path:** `accrue_admin/guides/theme-exceptions.md` — lives **outside** `.planning/` for OSS discoverability (**D-10**).
- **Row shape:** slug, location (file or route), deviation, rationale, future token, status, phase ref (**50-CONTEXT**).
- **PR hygiene:** Add bullet to root **`CONTRIBUTING.md`** (no dedicated `pull_request_template` in repo today).

---

## 4. VERIFY-01 extension (ADM-06)

- **Existing spine:** `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — customers index + light/dark axe (**serious/critical** filter).
- **Fixture:** `e2e/support/fixture.js` — `login`, `waitForLiveView`, `reseedFixture` — reuse for new flows.
- **Inventory:** Single markdown or JSON list under **`examples/accrue_host/docs/`** (executor picks exact filename; **50-VERIFICATION.md** links it) — paths must match **mounted** router (`/billing/...`).

**v1.12 union (initial inventory seeds — confirm against shipped 48/49):**

- Dashboard home (`/` billing entry → dashboard).
- Customers index (already covered — extend if copy changes).
- Subscriptions index + **subscription detail** (Phase 49).
- Any Phase 48 KPI deep-link targets touched by operator strings in this phase.

---

## 5. LiveViewTest vs Playwright split (D-16)

- **Library:** `Phoenix.LiveViewTest` for HTML structure, forms, and Copy call correctness.
- **Host:** Playwright for **session + mount + static pipeline + axe** on inventory paths only.

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Anti-drift task exports too much / wrong functions | Explicit allowlist keyed by function name atoms |
| Axe flakes on timing | Shared `waitForLiveView` + role-based readiness before axe (**D-20**) |
| Copy refactor breaks Hex API | No new **public** modules beyond delegated functions on **`AccrueAdmin.Copy`** (**D-05**) |

---

## Validation Architecture

> Nyquist / Dimension 8 — maps phase risks to **automated** vs **manual** verification and sampling expectations.

### Dimensions covered

| Dimension | Strategy |
|-----------|----------|
| **1 — Correctness** | `mix test` in `accrue_admin` for LiveViews touched; `mix test` in `accrue` if shared contexts change (unlikely). |
| **2 — Regression** | Existing suites green; new tests only additive where inventory grows. |
| **3 — Security** | No new logging of Stripe secrets; step-up / destructive flows unchanged; threat models in PLAN.md. |
| **4 — Performance** | No unbounded loops in Mix export; Playwright per-flow (not 40-URL sweep) for blocking job. |
| **5 — DX** | Document `mix … export` + `npm run e2e` in host README; CONTRIBUTING checklist. |
| **6 — Observability** | N/A — no new telemetry requirement. |
| **7 — Compatibility** | Elixir 1.17+ / Phoenix 1.8+ only; VERIFY-01 job matrix unchanged. |
| **8 — Validation continuity** | After each plan wave: `cd accrue_admin && mix compile --warnings-as-errors && mix test`; after e2e plan: `npm run e2e` (or scoped script) in `examples/accrue_host` per **50-VALIDATION.md**. |

### Wave 0

**None required** — Mix + ExUnit + Playwright already exist. VALIDATION.md marks Wave 0 as satisfied by existing infrastructure.

### Manual-only

- Visual review of **theme exception** rows with design intent (optional screenshot in PR description if major deviation).

---

## RESEARCH COMPLETE

Proceed to **`50-*-PLAN.md`** authoring with **50-CONTEXT.md**, **50-UI-SPEC.md**, and this file as inputs.
