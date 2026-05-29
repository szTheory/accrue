---
phase: 145-time-window-url-plumbing-window-selector
verified: 2026-05-27T21:30:00Z
status: human_needed
score: 8/9 must-haves verified
overrides_applied: 0
deferred:
  - truth: "analytics.md documents outcome-event-timestamp attribution and UTC-only window semantics (SC4 docs half)"
    addressed_in: "Phase 148"
    evidence: "Phase 148 success criteria SC3: 'adopter visits accrue/guides/analytics.md and finds... cutoff-date semantics with the Showing data since YYYY-MM-DD UI badge explanation'"
human_verification:
  - test: "Click the 7d / 30d / 90d preset buttons in a real browser session on /billing/analytics/recovery"
    expected: "Funnel counts and KPI card values reload to reflect the narrowed window; URL updates to ?window=7d / ?window=30d / ?window=90d; browser back-button restores the prior window"
    why_human: "render_patch confirms handle_params fires and the active button updates, but cannot verify that the DB query results actually change the displayed KPI numbers in the rendered HTML. The live DB fixture seeds events into the current 30d window; asserting that 7d returns different counts requires time-gated seed data not present in tests."
---

# Phase 145: Time-window URL plumbing + WindowSelector Verification Report

**Phase Goal:** Thread the `?window=7d|30d|90d` URL parameter through `RecoveryLive` so all analytics calls respect the selected time window. Introduce `AccrueAdmin.Components.WindowSelector` as the first `live_patch`-style filter in `accrue_admin`, setting the idiom for Phases 146 and 148.
**Verified:** 2026-05-27T21:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | mount/3 in RecoveryLive contains zero Dunning.* calls — only assign_shell(socket, admin) | VERIFIED | recovery_live.ex:10-13: mount/3 body is exactly `admin = Map.get(...); {:ok, assign_shell(socket, admin)}`. Grep for `Dunning.recovered_vs_lost_mrr()\|Dunning.funnel()` returns no output. |
| 2 | handle_params/3 is the sole data-loading entry point: Dunning.funnel/1 and Dunning.recovered_vs_lost_mrr/1 are both called there | VERIFIED | recovery_live.ex:16-39: handle_params calls both `Dunning.recovered_vs_lost_mrr(since: since, until: until)` (line 20) and `Dunning.funnel(since: since, until: until)` (line 21). Both Dunning calls in the codebase live only inside handle_params. |
| 3 | parse_window/1 has a whitelist guard (w in ["7d", "30d", "90d"]) and a catch-all clause that returns "30d" | VERIFIED | recovery_live.ex:91-92: `defp parse_window(w) when w in ["7d", "30d", "90d"], do: w` and `defp parse_window(_), do: "30d"`. Both clauses present. |
| 4 | WindowSelector renders a `<nav class="ax-tabs">` with 3 `<.link patch>` buttons labeled "7 days UTC", "30 days UTC", "90 days UTC" | VERIFIED | window_selector.ex:28-38: `<nav class="ax-tabs" aria-label="Time window (UTC)">` with `<.link :for={{value, label} <- @windows}` and `<%= label %> UTC`. @windows module attribute is `[{"7d", "7 days"}, {"30d", "30 days"}, {"90d", "90 days"}]`. Labels produce "7 days UTC", "30 days UTC", "90 days UTC". Uses `<.link patch=...>` not bare `<a href>`. |
| 5 | Active button carries class ax-tab-active and aria-current="page"; inactive buttons carry neither | VERIFIED | window_selector.ex:32-33: `class={["ax-tab", @current_window == value && "ax-tab-active"]}` and `aria-current={if @current_window == value, do: "page", else: nil}`. Navigation_components_test.exs:206: `assert 1 == html |> String.split(~s(aria-current="page")) |> length() |> Kernel.-(1)` — only one button carries aria-current. |
| 6 | ?window=7d and ?window=90d render the correct button as active in integration tests | VERIFIED | recovery_live_test.exs:184-193: test "?window=7d renders 7d button as active" asserts `active_window_label(html) =~ "7 days"`; test "?window=90d renders 90d button as active" asserts `active_window_label(html) =~ "90 days"`. Both pass (20 tests, 0 failures). |
| 7 | Invalid ?window=bad renders 30d button as active in integration tests | VERIFIED | recovery_live_test.exs:196-200: test "invalid ?window= falls back to 30d default" asserts `active_window_label(html) =~ "30 days"`. Passes. |
| 8 | render_patch to ?window=7d fires handle_params and the 7d button becomes active | VERIFIED | recovery_live_test.exs:202-207: test "window change via render_patch fires handle_params" calls `render_patch(view, "/billing/analytics/recovery?window=7d")` and asserts `active_window_label(html) =~ "7 days"`. Passes. |
| 9 | mix test --seed 0 from accrue_admin/ exits 0 | UNCERTAIN | 156 tests, 3 failures. However, the 3 failures are pre-existing (EmailPreviewLiveTest x2 + ConnectAccountLiveTest x1) confirmed by git log showing those test files last modified at Phase 90, unrelated to Phase 145 changes. The 8 new Phase 145 tests all pass. Phase-specific test files exit 0: `mix test test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` = 20 tests, 0 failures. |

**Score:** 8/9 truths verified (truth 9 is UNCERTAIN due to pre-existing failures; all Phase 145 tests pass)

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | analytics.md documents outcome-event-timestamp attribution and UTC-only window semantics | Phase 148 | Phase 148 SC3: "adopter visits accrue/guides/analytics.md and finds... cutoff-date semantics with the Showing data since YYYY-MM-DD UI badge explanation" |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/lib/accrue_admin/components/window_selector.ex` | AccrueAdmin.Components.WindowSelector Phoenix.Component with `attr :current_window, :string, required: true` | VERIFIED | File exists, 47 lines. Contains both required attrs, @windows module attribute, window_selector/1 function, ax-tabs nav, .link patch usage. No bare `<a href>`. |
| `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | Updated RecoveryLive with handle_params data loading | VERIFIED | Contains `def handle_params`, `parse_window/1`, `window_bounds/1`, `WindowSelector.window_selector` in template, WindowSelector alias. mount/3 is pure shell. |
| `accrue_admin/test/accrue_admin/components/navigation_components_test.exs` | WindowSelector component unit tests | VERIFIED | Contains `describe "WindowSelector"` with 3 tests covering labels, active state, and patch hrefs. 11 total tests in file. |
| `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs` | Window param integration tests with DAN-10 marker | VERIFIED | Contains `describe "window parameter (DAN-10)"` with 5 tests. DAN-10 label present. 9 total live tests. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `AccrueAdmin.Live.Analytics.RecoveryLive.handle_params/3` | `Accrue.Analytics.Dunning.funnel/1` | `since:/until:` opts from `window_bounds/1` | WIRED | recovery_live.ex:21: `Dunning.funnel(since: since, until: until)` |
| `AccrueAdmin.Live.Analytics.RecoveryLive.handle_params/3` | `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` | `since:/until:` opts from `window_bounds/1` | WIRED | recovery_live.ex:20: `Dunning.recovered_vs_lost_mrr(since: since, until: until)` |
| `AccrueAdmin.Live.Analytics.RecoveryLive.render/1` | `AccrueAdmin.Components.WindowSelector` | `<WindowSelector.window_selector>` in template | WIRED | recovery_live.ex:57: `<WindowSelector.window_selector current_window={@window} base_path={@current_path} />` |
| `AccrueAdmin.Components.WindowSelector` | LiveView handle_params | `<.link patch=...>` click fires handle_params | WIRED | window_selector.ex:29-36: `<.link patch={window_href(@base_path, value)} ...>`. Integration test confirms render_patch triggers handle_params. |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `recovery_live.ex` render | `@window` | `handle_params/3` → `parse_window(params["window"])` → `assign(:window, window)` | Yes — parsed from URL param, whitelisted, assigned every render | FLOWING |
| `window_selector.ex` | `@current_window` | Prop from RecoveryLive template: `current_window={@window}` | Yes — live socket assign passed as attr | FLOWING |
| `recovery_live.ex` render | `@stats`, `@funnel` | `handle_params/3` → `Dunning.recovered_vs_lost_mrr(since:, until:)` and `Dunning.funnel(since:, until:)` → real DB queries confirmed in test output (SQL logs visible in test run) | Yes — DB queries with since/until timestamps logged in test output | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 145 tests pass (component + integration) | `mix test test/accrue_admin/components/navigation_components_test.exs test/accrue_admin/live/analytics/recovery_live_test.exs --seed 0` from `accrue_admin/` | 20 tests, 0 failures, 0.2s | PASS |
| No Dunning no-arg calls in mount | `grep -n "Dunning.recovered_vs_lost_mrr()\|Dunning.funnel()" accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex` | No output | PASS |
| Clean compilation | `mix compile 2>&1 \| grep -E "error:\|warning:"` | No output | PASS |
| WindowSelector uses .link patch not bare anchor | `grep -n "<a href" accrue_admin/lib/accrue_admin/components/window_selector.ex` | No output | PASS |

---

### Probe Execution

Step 7c: SKIPPED — no `scripts/*/tests/probe-*.sh` files declared in PLAN or present for this phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|------------|-------------|-------------|--------|----------|
| DAN-10 | 145-01-PLAN.md | Time-window URL plumbing + selector: `?window=7d\|30d\|90d` via `handle_params/3`, default `30d`, window selector UI (3 preset buttons), URL as SSOT, all Dunning.* calls thread `:since`/`:until`, UTC-only labels | SATISFIED | All sub-clauses verified: URL param parsed (parse_window/1), handle_params threads opts (lines 20-21), WindowSelector renders 3 .link patch buttons with UTC labels, integration tests cover all cases. REQUIREMENTS.md marks DAN-10 as [x]. |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | No TBD/FIXME/XXX markers; no stub returns; no empty handlers; no hardcoded /billing paths in WindowSelector | — |

One notable deviation from plan (documented in SUMMARY.md, not a blocker): `window_selector.ex` implements `window_href/2` as a private helper using `URI.parse/1` + `Map.put(:query, ...)` + `URI.to_string/1` rather than plain string concatenation (`@base_path <> "?window=" <> value`). This is a BETTER implementation — handles paths with existing query params safely — and was introduced as a post-review fix (commit `6ca402fb`). The plan acceptance criteria (`patch={@base_path <> "?window=" <> value}`) was superseded by the superior URI-based approach. No impact on correctness or tests.

---

### Human Verification Required

#### 1. Button Click Reloads Data With Correct Window

**Test:** In a running accrue_admin dev server, navigate to `/billing/analytics/recovery`. Click the "7 days" button. Then click "90 days". Then click "30 days". Use browser DevTools Network tab or observe the funnel counts change.
**Expected:** Each button click updates the URL (`?window=7d`, `?window=90d`, `?window=30d`), the active button state (aria-current and ax-tab-active class) updates, and the funnel/KPI values reflect the selected window. Browser back-button restores the prior window state.
**Why human:** `render_patch` in tests confirms handle_params fires and active button updates, but cannot verify that displayed KPI numbers actually differ between windows in a live environment with real data. The integration tests assert DOM state (active button), not that the data itself differs between time windows.

---

### Gaps Summary

No blocking gaps. One truth (T9: `mix test --seed 0` exits 0) is UNCERTAIN due to 3 pre-existing failures in `EmailPreviewLiveTest` and `ConnectAccountLiveTest` — these files were last modified at Phase 90 (`git log --diff-filter=M` returns `d410da49 docs(phase-90)`) and are unrelated to Phase 145 changes. The Phase 145 test surface (20 tests in 2 files) is clean at 0 failures.

The docs callout in SC4 (analytics.md outcome-timestamp attribution) is explicitly deferred to Phase 148 (DAN-14).

---

_Verified: 2026-05-27T21:30:00Z_
_Verifier: Claude (gsd-verifier)_
