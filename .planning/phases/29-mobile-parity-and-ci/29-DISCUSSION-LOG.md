# Phase 29: Mobile parity and CI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `29-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-04-20  
**Phase:** 29 — Mobile parity and CI  
**Areas discussed:** MOB-01 overflow representatives; MOB-02 nav reachability; MOB-03 admin-heavy mobile flow; CI posture vs Phase 21 D-01  
**Mode:** User requested **all** areas + deep one-shot synthesis (parallel research subagents + orchestrator merge).

---

## MOB-01 — Representative flows for horizontal overflow

| Option | Description | Selected |
|--------|-------------|----------|
| A — Customers index only | Single route, fastest | |
| B — Customers index + one detail | List + detail without matrix | ✓ |
| C — Minimal VERIFY-01 multi-route spine | Several shells, more timing risk | |
| D — Full route matrix | Maximum signal, kitchen-sink CI | |

**User's choice:** Delegated to research + synthesis; **locked: Option B** (see `29-CONTEXT.md` D-01).

**Notes:** Subagent emphasized Pay/Nova/Stripe-sample lessons: prove **data-dense** pages, avoid **per-route generated loops**, keep browser gates on **host** not Hex package.

---

## MOB-02 — Primary navigation reachable

| Option | Description | Selected |
|--------|-------------|----------|
| A — Documentation checklist only | Maintainer contract, no CI | |
| B — One Playwright path only | CI guard, less onboarding prose | |
| C — Both checklist + Playwright | Docs + regression signal | ✓ |

**User's choice:** **Locked: Option C** — README subsection + one minimal `chromium-mobile` proof (`29-CONTEXT.md` D-02).

**Notes:** Subagent cited Spree/ActiveAdmin double-chrome, Filament shell conventions, `100vh`/fixed positioning footguns under host layouts.

---

## MOB-03 — Admin-heavy `@mobile` / `chromium-mobile` coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Customers index → detail | VERIFY-01-aligned, moderate flake | ✓ |
| Webhooks list/detail | Different density, more async | |
| Subscriptions index | Longer chain, weaker VERIFY tie-in | |

**User's choice:** **Locked: customers index → detail** on **real `chromium-mobile`**, with **`@mobile` tag + project skip** so `chromium-mobile-tagged` does not fake device parity (`29-CONTEXT.md` D-03).

**Notes:** Subagent referenced `verify01-admin-mounted.spec.js` spine, `workers: 1`, global seed handoff from `accrue_host_verify_browser.sh`.

---

## CI posture — Phase 21 D-01 alignment

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full suite on all projects every PR | Highest cost / flake | |
| B — Desktop full + one focused mobile file | Bounded PR signal | ✓ (via per-test project skips) |
| C — Mobile scheduled only | PRs can ship regressions | |
| D — Hybrid default + optional workflow | Trend signal optional | partial (optional dispatch deferred) |

**User's choice:** **Locked:** keep **`npm run e2e`** desktop-wide; add MOB specs that **execute substantive work only on `chromium-mobile`** (`29-CONTEXT.md` D-04).

**Notes:** Subagent stressed OSS norm: **package CI light, host integration heavy**; avoid scheduled-only for merge-blocking MOB.

---

## Claude's Discretion

- Exact MOB spec **filename** and whether to extract overflow helper to `e2e/support/` — planner choice (`29-CONTEXT.md`).
- Optional second surface (webhooks) if time allows — stretch, not exit criteria.

## Deferred Ideas

- Full per-route mobile matrix; scheduled-only MOB gate; webhooks-first MOB-03 — see `29-CONTEXT.md` `<deferred>`.
