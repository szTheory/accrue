# Phase 247 Initial Verification Gap Closure

Closure evidence for the actionable gaps recorded by initial verification at `94e4937d`. The original `247-VERIFICATION.md` and initial 16-capture review remain unchanged. This note does not mark Phase 247 complete or requirements complete.

## Recovery overlap

`accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` now starts the real LiveView, holds its initial 30-day async query, changes the selected window to 7 days, resolves the newer query first, then releases the older query. The assertions require the current 7-day value and loading state to survive the out-of-order completion. The small `:recovery_query_fun` application seam in `RecoveryLive` receives the existing owner scope and selected bounds; production reads still use the owner-scoped Dunning queries. Focused test passed with seed 0.

## Populated held-out webhook proof

The Playwright test at `examples/accrue_host/e2e/phase247-current-proof.spec.js` populates only the second webhook fixture in the isolated `accrue_host_test` database. Its raw JSON identifiers match that webhook, owner customer, and fixture subscription. It adds a linked `customer.updated` event and a discarded `Oban.Job` with attempt 3/max 25. The UI is opened via the real LiveView route; the test expands Activity, keyboard-selects Raw with arrow/enter, checks deep values, and compares native clipboard text byte-for-byte with the rendered JSON.

The current manifest has 20 full-page images across the five scenarios at 1280×900 and 320×820, light/dark. The expanded evidence scenario is explicitly marked `webhook-populated-evidence`; original empty-history captures and manifest were copied intact to `captures/phase247-initial-verification/`. All 20 current images were visually inspected. The initial inspection found horizontal clipping of long raw JSON values at 320px. `.ax-json-raw` now wraps long values; checked-in CSS was rebuilt offline from the existing npm cache and the final proof was captured from a fresh isolated 4102 build path. The updated narrow captures show the whole payload with no document-width overflow. Existing disclosure checks report a 45px actual target and visible open/closed chevron cues.

## Negative prohibition evidence

- `webhook_replay_test.exs`: accepted queue replay remains `:received`; success/completion copy is absent.
- `charge_live_test.exs`: missing fee evidence renders unavailable rather than inferred zero.
- `recovery_live_test.exs`: actual zero and unsupported currency states reject “money saved” and “confirmed churn” claims.
- `connect_accounts_live_test.exs` and the existing webhook activity test keep missing snapshot/history states unavailable or empty without inferring setup faults, pending work, or success.

These are explicit named outcomes and negative copy assertions tied to the corresponding states. The existing plan's prohibition tier is untouched; the parent reviewer can assess whether the tests provide sufficient enforcement before changing any plan-level judgment.

## Verification

- `mix test test/accrue_admin/live/analytics/recovery_live_test.exs test/accrue_admin/live/webhook_replay_test.exs --seed 0`: 49 tests, 0 failures.
- `mix test test/accrue_admin/live/charge_live_test.exs --seed 0`: 22 tests, 0 failures.
- Final `mix test --warnings-as-errors --seed 0` in `accrue_admin`: 730 tests, 0 failures.
- Ordinary Phase 247 browser lane: 1 passed, with `ACCRUE_HOST_SKIP_SEEDS=1` and the existing Phase 245 host.
- Isolated held-out Phase 247 browser lane on 4102: 1 passed. The first fixture helper attempt exposed unsupported `Repo.exists?/1`; replaced with a scoped `Repo.one/1` lookup before the passing run.
- `node scripts/ci/verify_phase247_render_proof.mjs --manifest .planning/phases/247-evidence-true-details-and-analytics/captures/phase247-current-proof/manifest.json`: 20 images validated at source `48a8d7fdde48`; captured source digests and served CSS/JS match.

The Phase 243 protected preview and port 4101 were not used or changed. The ordinary lane always skipped seeds. No production webhook, ordinary seed, new dependency, or remote service was touched. Current mounted evidence now exists; the initial verification itself remains historical and pending its ordinary review process.
