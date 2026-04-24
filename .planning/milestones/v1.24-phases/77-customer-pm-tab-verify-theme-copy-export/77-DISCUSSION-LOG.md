# Phase 77: Customer PM tab — VERIFY + theme + copy export - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`77-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 77 — Customer PM tab — VERIFY + theme + copy export  
**Areas discussed:** VERIFY-01 / Playwright placement (ADM-15); Axe policy (ADM-15); `theme-exceptions.md` posture (ADM-16); `export_copy_strings` / CI (ADM-16)  
**Mode:** User selected **all** areas and requested parallel subagent research + one-shot unified recommendations (captured as locked decisions in CONTEXT).

---

## VERIFY-01 / Playwright placement (ADM-15)

| Option | Description | Selected |
|--------|-------------|----------|
| Host `verify01-admin-a11y.spec.js` | Merge-blocking `ci.yml` e2e; same fixtures/copy_strings pattern | ✓ |
| New host spec file | Clearer ownership; needs doc wiring | |
| `accrue_admin/e2e/phase7-uat.spec.js` only | Fast package UAT; not VERIFY-01 contract | |

**User's choice:** Research synthesis + user mandate — **host `verify01-admin-a11y.spec.js`**, customer detail **`?tab=payment_methods`**, update **`verify01-v112-admin-paths.md`**.

**Notes:** Rails-engine / Nova-style lesson: **reference host** carries integration truth; duplicate merge-blocking stacks create drift.

---

## Axe policy (ADM-15)

| Option | Description | Selected |
|--------|-------------|----------|
| Match existing `scanAxe` (critical + serious) | Consistent with customers index test | ✓ |
| Full WCAG strict + moderate | Higher bar; churn without milestone policy | |
| Route-scoped `include()` only | Faster; misses shell coupling for first PM test | |

**User's choice:** **critical + serious**, **full document**, **light + dark desktop**, **one analyze per journey end state**.

**Notes:** Billing libs (Pay, Cashier) rarely define packaged axe CI — Accrue leads with a **lean** high-signal gate.

---

## `theme-exceptions.md` (ADM-16)

| Option | Description | Selected |
|--------|-------------|----------|
| Hybrid (register + phase notes) | Rows = durable bypasses; notes = clean audit | ✓ |
| Register-only | Noisy for “no new exceptions” phases | |
| Notes-only | Under-documents real bypasses | |

**User's choice:** **Hybrid**, Phase 55/53 precedent.

---

## `export_copy_strings` / CI (ADM-16)

| Option | Description | Selected |
|--------|-------------|----------|
| Mix SSOT + checked-in JSON + CI diff | Merge-blocking honesty; optional local pre-commit | ✓ |
| Editor regenerate-only | Skipped in CI-only PRs | |
| Parallel snapshot tests | Duplicate SSOT | |

**User's choice:** **`@allowlist` + `mix accrue_admin.export_copy_strings --out …/copy_strings.json`**; resolve JSON conflicts by **re-run Mix**; follow **`scripts/ci/README.md`** for authoritative browser gate.

---

## Claude's Discretion

- Playwright test naming / micro sequencing within the agreed file and route (**77-CONTEXT.md**).

## Deferred Ideas

- Global `withTags` on all axe builders — deferred unless a dedicated consistency phase is opened.
