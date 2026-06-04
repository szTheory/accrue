---
phase: 177-d-motion-micro-interaction-design
fixed_at: 2026-06-04T19:29:30Z
review_path: .planning/phases/177-d-motion-micro-interaction-design/177-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 177: Code Review Fix Report

**Fixed at:** 2026-06-04T19:29:30Z
**Source review:** `.planning/phases/177-d-motion-micro-interaction-design/177-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (3 Critical + 4 Warning; Info excluded per fix_scope=critical_warning)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: sidebar_collapse.js — transitionend never fires under prefers-reduced-motion

**Files modified:** `accrue_admin/assets/js/hooks/sidebar_collapse.js`
**Commit:** 6d2f8585
**Applied fix:** After adding `.ax-collapsed`, reads back `getComputedStyle(list).transition-duration`. If the parsed float is `<= 0.001` (the `0ms` set by `--ax-dur-exit` under `prefers-reduced-motion: reduce`), applies `list.hidden = true` and removes `.ax-collapsed` synchronously without waiting for `transitionend`. The `{ once: true }` transitionend listener is retained on the normal-motion path.

---

### CR-02: detail_drawer.ex — close button has no click handler

**Files modified:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`
**Commit:** 8f7e83cb
**Applied fix:** Moved `{@rest}` from the outer `<section>` onto the close `<button :if={!@close_href}>`. The `attr(:rest, :global, include: ~w(phx-click phx-target))` declaration already expressed the intent; the forwarding target was wrong. `{@rest}` was removed from the `<section>` — section-level event listeners are not appropriate here.

---

### CR-03: customer_live.ex — Repo.delete/1 bare match crashes LiveView on DB failure

**Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`
**Commit:** f03b1bd1
**Applied fix:** Wrapped `Repo.delete(persisted_payment_method)` in a `case` expression. On `{:ok, _deleted}`, the existing best-effort `Repo.update()` for the default payment method runs as before. On `{:error, _changeset}` (constraint, concurrent deletion, DB error), logs and returns `:ok` so the LiveView process does not crash. Consistent with the "best effort" comment already present on `Repo.update/1` two lines below.

---

### WR-01: customer_live.ex — :replacement_required guard logic inverted

**Files modified:** `accrue_admin/lib/accrue_admin/live/customer_live.ex`
**Commit:** f03b1bd1 (same commit as CR-03)
**Applied fix:** Added `not` to `has_other_payment_methods?(customer, payment_method)` in the `:replacement_required` cond branch. Previously the guard fired when a replacement WAS available (blocking deletion incorrectly) and passed through when NO replacement existed (allowing potentially orphaned customers). Now correctly: `:replacement_required` fires only when the payment method is the default AND no other payment method exists.
**Note:** This is a logic correctness fix — requires human verification that the intended semantic (block deletion of last default payment method) is correct.

---

### WR-02: sidebar_collapse.js — aria-expanded written before null guard

**Files modified:** `accrue_admin/assets/js/hooks/sidebar_collapse.js`
**Commit:** 6d2f8585 (same commit as CR-01)
**Applied fix:** Moved `document.getElementById(this.el.dataset.controls)` and the `if (!list) return` guard to the top of `setExpanded`, before `this.el.setAttribute("aria-expanded", ...)`. If the controlled list is missing (e.g. during a LiveView reconnect where `data-controls` id has not yet stabilised), the function now returns without mutating any ARIA state.

---

### WR-03: global_search.ex — mount_path initialised to hardcoded "/billing"

**Files modified:** `accrue_admin/lib/accrue_admin/components/global_search.ex`
**Commit:** 929c5174
**Applied fix:** Changed the `mount/1` default from `mount_path: "/billing"` to `mount_path: nil` with an explanatory comment. The correct value always arrives via `update/2` from `app_shell`. Using `nil` prevents silently building broken navigation links in cases where `update/2` is not called before render.

---

### WR-04: detail_drawer.ex — aria-labelledby uses hardcoded static ID

**Files modified:** `accrue_admin/lib/accrue_admin/components/detail_drawer.ex`
**Commit:** 8f7e83cb (same commit as CR-02)
**Applied fix:** Added `attr(:id, :string, default: "detail-drawer")`. The `<section>` now renders `id={@id}` and `aria-labelledby={"#{@id}-title"}`. The `<h2>` now renders `id={"#{@id}-title"}`. Existing callers that omit the `id` attr get the `"detail-drawer"` default, preserving backward compatibility. Callers that render multiple drawers can pass distinct `id` attrs to avoid HTML uniqueness violations.

---

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-06-04T19:29:30Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
