---
quick_id: 261008-cb9
status: complete
date: 2026-10-08
files_modified:
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
commit: 795114d9
---

# Quick Task 261008-cb9: Repair Admin CI Warnings

Moved `prepare_staged_action/2` unchanged below the final contiguous `handle_event/3` clause and renamed the unused LiveView test binding to `_view`.

## Evidence

- `cd accrue_admin && mix test --warnings-as-errors` — passed; 551 tests, 0 failures.
- `git diff --check` — passed.
- Commit `795114d9` contains only the two authorized source files and only the helper relocation and binding rename.
- Existing working-tree changes to `.planning/config.json` and `.planning/milestone.lock` were left untouched. Phase 235 and checkout source were not modified.

## Deviations

None.
