---
phase: quick-260621-h72
verified: 2026-06-21T16:50:00Z
status: human_needed
score: 6/6 must-haves verified (code-level); 3 truths carry human-only visual confirmation
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Load /admin/webhooks?status=dead in dark mode; do NOT click anything. Observe the main content region on mount and after nav."
    expected: "No bright blue UA focus box paints on .ax-shell-content. Then press Tab from the top — the keyboard skip-link still lands focus on main (visible ring on genuine keyboard focus)."
    why_human: "Browser-only UA :focus vs :focus-visible rendering; cannot be observed headlessly. The CSS rule and untouched ensurePageFocus() JS are confirmed in code + built bundle."
  - test: "On /admin/webhooks?status=dead inspect the 'Blocked' KPI card footer in both light and dark themes (secondary stat e.g. '12 dead-lettered')."
    expected: "The delta pill never wraps mid-word (white-space: nowrap) and the muted meta caption sits on its own full-width line below the pill (.ax-kpi-meta)."
    why_human: "Visual layout/wrapping at real widths; cannot be measured headlessly. CSS (.ax-kpi-delta nowrap, .ax-kpi-meta) and kpi_card.ex <p class=ax-kpi-meta> wrap confirmed in code + built bundle."
  - test: "On /admin/webhooks?status=dead exercise the three filters: focus the Type field, the Status select, and the Live mode control."
    expected: "Type field offers a native autocomplete dropdown of real distinct event types; Status options read 'Dead (N)' with zero-count statuses disabled (active value never disabled); Live mode renders as an All/Live/Test segmented toggle."
    why_human: "Native datalist dropdown appearance and segmented-control styling are browser-render-only. The :datalist/:segmented/:select-with-counts clauses, the disabled-but-not-active logic, and the .ax-segmented CSS (source + built bundle) are all confirmed in code."
---

# Quick 260621-h72: Webhooks DLQ — Design-System Tightening + Selection-Driven Retry Verification Report

**Phase Goal:** Webhooks DLQ admin page (/admin/webhooks?status=dead) — design-system tightening + selection-driven retry, delivered as 6 atomic commits across shared admin primitives.
**Verified:** 2026-06-21
**Status:** human_needed (all code-level checks pass; 3 truths additionally require a visual/browser confirmation that cannot be done headlessly)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | No blue UA focus box on .ax-shell-content load in dark mode; keyboard skip-link still works | ⚠️ PRESENT (visual confirm pending) | `app.css` + built bundle contain `.ax-shell-content:focus:not(:focus-visible) { outline: none }` (built-bundle grep count 1); `ensurePageFocus()` JS untouched. Final render is browser-only → human_verification #1. |
| 2 | KPI secondary stat never wraps mid-word; muted meta caption on its own full-width line | ⚠️ PRESENT (visual confirm pending) | `.ax-kpi-delta` has `white-space: nowrap`; `.ax-kpi-meta` selector present in source + built bundle (grep count 1); `kpi_card.ex` wraps meta slot in `<p class="ax-kpi-meta">`. Layout render is browser-only → human_verification #2. |
| 3 | Operator checks rows, clicks primary 'Retry selected', plain confirm, retries exactly those ids, records audit event of selected count | ✓ VERIFIED | `data_table.ex:113` `handle_event("bulk-action")` sends `{:data_table_bulk_action, event, MapSet.to_list(selected_ids)}` to parent without mutating selection; `webhooks_live.ex:51` `handle_info({:data_table_bulk_action, "retry_selected", ids})`; `confirm_retry_selected` scopes ids via `scope_selected_ids` (per-row `Webhooks.detail/2` owner check), retries via `replay_scoped_rows`, refreshes summary, `record_bulk_replay` emits `admin.webhook.bulk_replay.completed` with count+ids. Behavioral tests in `webhooks_live_test.exs` and `webhook_replay_test.exs` assert exactly-selected-ids retried + one audit event; full suite green. |
| 4 | The 8 non-webhooks list pages no longer render selection checkboxes or a selection bar | ✓ VERIFIED | `data_table.ex:37` `assign_new(:selectable, fn -> false end)`; selection bar + Select column gated on `@selectable`; only `webhooks_live.ex:197` passes `selectable={true}`. Other pages inherit the new false default. |
| 5 | DataTable footer reads 'Showing N events'/'Showing N results' (plural-aware), not 'N rows loaded' | ✓ VERIFIED | `data_table.ex:310` uses `Copy.data_table_row_count(length(@rows), @row_label)`; `copy.ex:475` returns `"Showing N <singular|plural>"` (plural-aware on count==1). No `"rows loaded"` literal remains. |
| 6 | Type filter autocompletes real distinct types; Status shows counts with zero-count disabled; Live mode is All/Live/Test segmented | ⚠️ PRESENT (visual confirm pending) | `webhooks_live.ex` filter_fields wire `type: :datalist` (options `Webhooks.distinct_types/1`), `status_filter_options` builds `"Dead (N)"` maps with `disabled: count == 0`, and `type: :segmented` All/Live/Test. `data_table.ex` has `:datalist`, `:segmented`, and `:select` (disabled-but-not-active) clauses. Native dropdown/segmented rendering is browser-only → human_verification #3. |

**Score:** 6/6 truths satisfied at code level. Truths 1, 2, 6 are present + fully wired but assert visual/browser rendering that cannot be confirmed headlessly → routed to human verification (not counted as failures).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `data_table.ex` | selection emit + plural footer + selectable default false + :datalist/:segmented | ✓ VERIFIED | `data_table_bulk_action` send (no mutation), `assign_new(:selectable, fn -> false end)`, `Copy.data_table_row_count`, `:datalist`/`:segmented`/extended `:select` clauses all present and wired. |
| `webhooks_live.ex` | selection-driven retry handle_info + inline confirm + plain copy; DLQ bulk-replay card removed | ✓ VERIFIED | handle_info + confirm_retry_selected + cancel_bulk_replay present; `prepare_bulk_replay`/`confirm_bulk_replay`/`"DLQ bulk replay"` card all GONE (grep empty); `selectable={true}` passed. |
| `queries/webhooks.ex` | distinct_types/1 + status_counts/1 owner-scoped via scope_rows | ✓ VERIFIED | Both defined, both pipe through `scope_rows(owner_scope)`; admin-only — NO matching defs in core `accrue/lib`. |
| `theme.css` | --ax-accent-contrast in light + dark | ✓ VERIFIED | Defined in 4 token blocks (light, dark, descendant-dark, system@dark) — `#ffffff`. |
| `priv/static/accrue_admin.css` | rebuilt bundle with .ax-segmented + .ax-kpi-meta | ✓ VERIFIED | Built bundle grep: `ax-segmented` (1), `ax-kpi-meta` (1), focus rule (1). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `data_table.ex` | `webhooks_live.ex` | bulk-action button → `send(self(), {:data_table_bulk_action, event, ids})` → parent handle_info | ✓ WIRED | Emit at data_table.ex:116; primary button (data_table.ex:227, gated on `bulk_action_event` + non-empty selection); consumed at webhooks_live.ex:51. |
| `webhooks_live.ex` | `queries/webhooks.ex` | filter options populated by distinct_types/status_counts | ✓ WIRED | `Webhooks.distinct_types(@current_owner_scope)` for Type datalist; `Webhooks.status_counts(owner_scope)` feeds `status_filter_options`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Full admin suite green | `mix test` | 329 tests, 0 failures | ✓ PASS |
| Warnings-as-errors compile | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Bulk-action emits to parent | data_table_test.exs:429-446 `assert_receive {:bulk_action_received, "retry_selected", ids}` | passes in suite | ✓ PASS |
| Selection-driven retry records exactly one audit event | webhook_replay_test.exs / webhooks_live_test.exs | passes in suite | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `webhooks_live.ex` | 147 | KPI delta literal `" dead-lettered"` (user-facing) | ℹ️ Info | Pre-existing before this task (confirmed via `git show f16444d2^`); outside the retry-microcopy prohibition scope (which targeted the retry flow strings). Not introduced or modified here. |
| `webhooks_live.ex` | 159 | KPI meta caption "shared DLQ primitives" (user-facing) | ℹ️ Info | Pre-existing before this task; same as above. New retry/confirm/helper/warning/success copy is all jargon-free and plain. |

No blocker anti-patterns. No debt markers (TBD/FIXME/XXX) introduced. No stubs — all artifacts substantive and wired.

### Guardrail Verification

| Guardrail | Status | Evidence |
| --------- | ------ | -------- |
| No core `accrue` API change | ✓ | No `distinct_types`/`status_counts` in `accrue/lib`. |
| StatusBadge unmodified | ✓ | `git log` over commit range touches no `status_badge.ex`. |
| No CSP weakening | ✓ | No CSP/unsafe-inline/unsafe-eval changes in lib diff. |
| examples/accrue_host/mix.lock untouched | ✓ | Not in commit-range diff. |
| .planning/research/.cache/ untouched | ✓ | Not in commit-range diff. |
| ROADMAP.md not changed | ✓ | Not in commit-range diff. |
| 6 atomic commits in order | ✓ | f16444d2, 4be02414, fee57d38, e11e3536, 1cdbbbc7, 745462ec present in git log. |

### Gaps Summary

No gaps. All six must-have truths are satisfied at the code level: the selection-driven retry flow (truths 3-5) is fully VERIFIED with passing behavioral tests, owner-scoping, and audit-event recording. Truths 1, 2, and 6 are fully implemented and wired in code and present in the committed built bundle, but assert visual/browser-only rendering (UA focus-ring suppression, KPI footer wrap/layout, native datalist + segmented control appearance) that cannot be confirmed headlessly — these are routed to human verification per the task's explicit guidance, not counted as failures.

The two `DLQ`/`dead-lettered` jargon strings in the KPI cards pre-date this task and fall outside the retry-microcopy prohibition; noted as informational only.

---

_Verified: 2026-06-21T16:50:00Z_
_Verifier: Claude (gsd-verifier)_
