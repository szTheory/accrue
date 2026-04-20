---
status: clean
phase: 27-microcopy-and-operator-strings
depth: quick
---

# Code review — Phase 27

**Scope:** `AccrueAdmin.Copy`, `AccrueAdmin.Copy.Locked`, money + webhook LiveViews touched in plans 27-01–27-03.

**Checks:** Confirmed copy moves are literal-only (no new `raw/1` on user data), webhook replay branches still gate on existing `Webhooks` / `DLQ` outcomes, and `payment_processor_action_warning/1` preserves `inspect/1` parity.

**Findings:** None.
