---
quick_id: 260621-mr6
slug: webhooks-datatable-polish
verified: 2026-06-21T16:40:00Z
status: passed
verdict: PASS
score: 4/4 goal fixes verified
full_suite: "348 tests, 0 failures (accrue_admin)"
targeted_suite: "28 tests, 0 failures"
commits_inspected: [9aa35ced, 63b3a394, 231b3316, bf83caf5]
---

# Verification — Quick Task 260621-mr6: Webhooks DataTable polish

**Verdict: PASS.** All four goal fixes are present, wired, and tested. Every pinned
contract survives. Opt-out pages remain byte-identical. Full `accrue_admin` suite is
green (348/0). The one un-run host test is an acceptable gap (justified in G).

Verifier did NOT trust the executor: every claim below is backed by `git show`/`grep`
on the committed diffs and by re-running the suites myself.

---

## Goal Fixes

| # | Fix | Status | Evidence |
|---|-----|--------|----------|
| 1 | Truthful filtered-empty state, opt-in + non-breaking | VERIFIED | A, F |
| 2 | Vertical gap between toolbar and results/empty card | VERIFIED | D |
| 3 | Mobile-first responsive filter grid | VERIFIED | D |
| 4 | Select buttons → native checkboxes, contracts preserved | VERIFIED | B, C |

---

## A. NON-BREAKING claim (most important regression risk) — PASS

`git show 9aa35ced` (data_table.ex):
- `update/2` adds `|> assign_new(:filtered_empty_title, fn -> nil end)` and
  `|> assign_new(:filtered_empty_copy, fn -> nil end)` after `:empty_copy`. ✓
- New `resolve_empty_state/1` derives:
  - `filtered? = any_filter_active?(socket.assigns[:filter_params] || %{})`
  - `resolved_empty_title = if filtered? and socket.assigns.filtered_empty_title, do: <filtered>, else: socket.assigns.empty_title`
  - `resolved_empty_copy` analogous. ✓
- HEEx empty block now renders `@resolved_empty_title`/`@resolved_empty_copy`. ✓

**Byte-identical proof:** when `filtered_empty_title == nil` (the opt-out default), the
`if filtered? and nil` short-circuits to `else: empty_title`, so `resolved_empty_title ==
empty_title` for ALL filter states. Opt-out pages render exactly as before.

**Spot-check of opt-out pages:** `grep -rn "filtered_empty_" lib/.../live/` returns ONLY
`webhooks_live.ex:246,247`. `invoices_live.ex` and `subscriptions_live.ex` pass only
`empty_title`/`empty_copy` (via their own untouched `queue_empty_title/copy` helpers) and
do NOT pass `filtered_empty_*`. Confirmed non-breaking.

## B. SINGLE toggle-all invariant — PASS

- `grep -c 'data-role="toggle-all"' data_table.ex` = **1** (rendered once, shared by
  grid + cards). ✓
- It is now an `<input type="checkbox" class="ax-checkbox">` wrapped in a `<label>`,
  keeping `data-role="toggle-all"`, `data-phase191-focus="toggle-all"`,
  `aria-label={toggle_all_label(assigns)}`, `checked={all_visible_selected?(assigns)}`. ✓
- Per-row controls (grid + card): 2× `data-role="toggle-row"`, both
  `<input type="checkbox" class="ax-checkbox">` with `data-row-id`,
  `data-phase191-focus="toggle-row"`, `aria-label={selection_label(...)}`,
  `checked={selected?(...)}`. The stale `aria-pressed` and the `"Selected"/"Select"`
  text node were dropped. ✓
- `<th>` is now `<th ...><span class="ax-visually-hidden">Select</span></th>` —
  **NOT** `ax-sr-only`. ✓ `ax-visually-hidden` exists in app.css and the committed bundle. ✓

(4 total `type="checkbox"` in the file = toggle-all + 2 toggle-row + 1 pre-existing
filter-input checkbox at line 430, which this task did not touch.)

## C. CONTRACTS preserved — PASS

- No test asserts visible "Select"/"Selected"/"Select visible"/"Clear visible" as a node.
  The only related assertions are `aria-label="Select visible fixture rows"` and
  `aria-label="Clear visible fixture rows"` (from `toggle_all_label`, unchanged). ✓
- `data-role="selected-count">2 selected<` and `>1 selected<` still asserted in tests AND
  still rendered (data_table.ex line 247). ✓
- Bulk-action button (`data-role="bulk-action"`, "Retry selected") unchanged. ✓
- `empty-state`, `clear-filters` data-roles still present. ✓

## D. CSS — PASS

`git show 231b3316` (app.css):
- New base rule `.ax-data-table{display:flex;flex-direction:column;gap:var(--ax-space-lg)}`. ✓
- `.ax-data-table-filters` converted to `display:grid; gap:var(--ax-space-md);
  grid-template-columns:1fr` with `@media (min-width:768px){ ...
  repeat(auto-fit,minmax(12rem,1fr)) auto; align-items:end }`. ✓
- Spacing tokens only — **no new color tokens**. ✓
- Select-all label reuses existing `.ax-field-inline` (231b3316 swapped it away from a new
  `ax-data-table-toggle-all` class) → **no new registered class**. ✓

**component_registry.ex UNCHANGED** — absent from all four `--stat` outputs (appears only
inside a commit-message string). ✓

**Committed bundle (priv/static/accrue_admin.css):**
- `.ax-data-table{display:flex;flex-direction:column;gap:var(--ax-space-lg)}` present. ✓
- `.ax-data-table-filters{display:grid;gap:var(--ax-space-md);grid-template-columns:1fr}`
  and `repeat(auto-fit,minmax(12rem,1fr)) auto` at the 768px breakpoint present. ✓

**JS untouched:** `bf83caf5 --stat` shows **only** `priv/static/accrue_admin.css`
changed — `accrue_admin.js` is byte-identical (not in the commit). No `assets/js/*` source
edited across any of the four commits. ✓ (This is stronger than the plan's allowance —
the deterministic rebuild did not even perturb the JS md5.)

## E. RE-RAN THE TESTS MYSELF — PASS

Targeted (`data_table_test.exs webhooks_live_test.exs webhook_replay_test.exs assets_test.exs`):
> **28 tests, 0 failures**

Full `mix test` (accrue_admin):
> **348 tests, 0 failures**

`mix compile --warnings-as-errors` → exit 0. No BLOCKERS.

## F. SPEC-GAP proof — PASS (non-trivial tests)

- `data_table_test.exs` "distinguishes true-empty from filtered-empty": the filtered case
  (`params %{"status" => "closed"}`) now `refute html =~ "Nothing in this list yet"` AND
  `assert html =~ "No fixtures match these filters"`; the true-empty case adds
  `refute html =~ "No fixtures match these filters"`. Fixture passes literal
  `filtered_empty_title="No fixtures match these filters"`. These would FAIL on the
  pre-change HEEx (old code rendered `@empty_title` = "Nothing in this list yet" in both
  cases). ✓ Genuinely closes the gap.
- `webhooks_live_test.exs` new test: mounts `/billing/webhooks?type=does-not-exist-zzz`
  (org genuinely has `evt_dead`+`evt_ok`), `assert "No webhook deliveries match these
  filters"` AND `refute "No webhook deliveries for this organization yet"`. The refuted
  string exactly matches `copy.ex:670 webhooks_index_empty_title`. Non-trivial. ✓

## G. HOST TEST caveat — ACCEPTABLE GAP

- **Zero host modifications:** `examples/accrue_host/` does not appear in any of the four
  commits' `--stat`. `mix.lock` untouched. ✓
- **Could this UI-only change affect the host test?** No. The current
  `admin_webhook_replay_test.exs` (repaired in the prior 260621-lzc task to a
  selection-driven contract) does **not** click `[data-role='toggle-all']` or any checkbox.
  It exercises:
  1. Org-scoped list scoping — asserts outsider/ambiguous rows absent, relies on
     `AccrueAdmin.Copy.webhooks_index_empty_title()` (unchanged) and absence of
     `data-role="bulk-action"` (unchanged).
  2. Handler defense-in-depth — `send(view.pid, {:data_table_bulk_action, "retry_selected",
     ids})` then `render_click(element(view, "[data-role='confirm-retry-selected']"))`.
     None of these markers (`bulk-action`, `confirm-retry-selected`, the
     `{:data_table_bulk_action,...}` notification, the security/scope path) were touched by
     this task.
  - The single-`toggle-all` invariant the old host test relied on is independently
    confirmed green in the accrue_admin suite (B above).
  - **Conclusion:** the un-run host test is an **acceptable gap, not a real risk** — every
    contract it depends on is unchanged and is additionally covered by the passing
    accrue_admin `webhooks_live_test`/`webhook_replay_test`.

---

## Residual Risks

- **None blocking.** The host integration test was not executed (would require
  `mix deps.get` against the off-limits stale `mix.lock`), but its contracts are unchanged
  and independently covered (G). If a host CI run is ever desired, it should pass unchanged.
- Visual sanity of the new `.ax-data-table` base gap (no double-stacking with child margins)
  was not pixel-inspected here; it is a low-risk additive flex gap on a container that
  previously had none, and no test regressed.

---

_Verified by re-reading committed diffs and re-running both suites. Verifier: Claude (gsd-verifier)._
