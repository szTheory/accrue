# Deferred items — Phase 210

Out-of-scope discoveries logged during 210-03 execution (not fixed — outside the plan's scope).

## Pre-existing unit test failure (unrelated to the reign)

- **Test:** `AccrueAdmin.DisplayComponentsTest` — "Timeline related resources keep item rhythm without turning each link into a nested card" (`accrue_admin/test/accrue_admin/components/display_components_test.exs:390`).
- **Symptom:** `assert html =~ ~s(class="ax-card ax-related")` fails because the Related component renders `class="ax-card ax-related ax-related-resources"` (trailing modifier class breaks the exact-substring match).
- **Why deferred:** The Related component/test was last modified 4 weeks ago (commit `0959926d`), long before Phase 210. It is not in the 210-03 diff (which touches only `stat_strip.ex` + `app.css` + rebuilt bundle) and is unrelated to the Home reign. SCOPE BOUNDARY: only auto-fix issues directly caused by the current task's changes.
- **Suggested fix (follow-up):** loosen the assertion to a class-token check or update it to `class="ax-card ax-related ax-related-resources"`.
