# Phase 144 — Deferred Items

Out-of-scope discoveries encountered during execution. Logged per SCOPE BOUNDARY rule (do not auto-fix unrelated files).

## test(accrue_admin/test/accrue_admin/dev/email_preview_live_test.exs): pre-existing form-selector ambiguity

- **Discovered during:** Phase 144 Plan 04 full-admin-suite verification
- **Symptom:** `mix test test/accrue_admin/dev/email_preview_live_test.exs` fails with `expected selector "form" to return a single element, but got 2` — the generic `"form"` selector now matches both the fixture-picker form and the global command-palette search form that ships in the admin layout.
- **Root cause:** Command palette was added in a later phase than the email-preview test; the test's selector was never updated to be specific.
- **Last touched (test):** Phase 90 (`d410da49`)
- **Out of scope:** Unrelated to Phase 144's recovery-dashboard wiring; no code I changed touches `email_preview_live*`.
- **Fix sketch:** Tighten the form selector to e.g. `form[phx-change=select_fixture]` in the test. Trivial; not done here to respect SCOPE BOUNDARY.
- **Recommended owner:** First future phase that touches `email_preview_live*` OR a dedicated `chore(test)` fix.
