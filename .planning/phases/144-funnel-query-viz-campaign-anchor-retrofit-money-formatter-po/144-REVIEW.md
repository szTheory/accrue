---
phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - accrue/lib/accrue/analytics/dunning.ex
  - accrue/lib/accrue/webhook/default_handler.ex
  - accrue/test/accrue/analytics/dunning_test.exs
  - accrue/test/accrue/webhook/dunning_campaign_keying_test.exs
  - accrue/test/accrue/webhook/dunning_exhaustion_test.exs
  - accrue/test/property/dunning_funnel_property_test.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/lib/accrue_admin/components/funnel_chart.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/test/accrue_admin/components/funnel_chart_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Phase 144 ships the DAN-01 / DAN-02 / DAN-08 / DAN-09 / DAN-13 deliverables: a three-stage dunning funnel query, JSONB safe-cast on the MRR aggregation, campaign-anchor retrofit on dunning lifecycle events, and a CLDR-backed money formatter for the recovery KPI cards. The implementation is largely correct and the test coverage is thorough across unit, property, and LiveView render layers.

The single CRITICAL finding is a multi-currency aggregation bug: `Accrue.Analytics.Dunning.recovered_vs_lost_mrr/1` sums `mrr_value_cents` across every event regardless of the per-event `currency`, and `RecoveryLive` then formats the (currency-blind) integer using the tenant's `default_currency`. For any host that has ever emitted mixed-currency `dunning.recovered`/`dunning.exhausted` events, the displayed totals are arithmetically wrong (apples plus oranges, displayed as apples). Tests only ever exercise single-currency fixtures so the defect is invisible at CI but observable in production.

Warnings cover: a stale comment in `funnel/1` claiming a strict inequality that actually holds with equality (the three predicates partition the tuple space, so the property test's `<=` invariant is structurally always `==`), missing tests for the `__legacy__` sentinel mixing with non-legacy events for the same subject, no error handling around `Dunning.funnel/0` and `recovered_vs_lost_mrr/0` in `RecoveryLive.mount/3`, two `@since "1.4.0"` docstring tags that look like ExDoc metadata but are actually plain text inside `@doc` heredocs (won't surface in generated docs), static SVG element IDs (`funnel-title`/`funnel-desc`) that collide if a future page renders two funnel components, and an unused `_ = sub_id` line in the stale-recovery-isolation test that suggests the test stops short of asserting the cancel path was attempted.

Info items: minor doc inaccuracy on the funnel invariant ("strictly less" claim is incorrect — see WR-01); `iteration_tag` interpolation in the property test makes the dataset effectively per-iteration but at the cost of inflating cardinality (acceptable trade-off but worth noting); the JPY regression test only asserts presence of the symbol, not the rendered cent count; the funnel chart has no test for very-large values where rounding could distort proportional bars.

## Critical Issues

### CR-01: Multi-currency recovered/lost MRR aggregation sums denominations together

**File:** `accrue/lib/accrue/analytics/dunning.ex:43-66`, `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:12-22`

**Issue:** `recovered_vs_lost_mrr/1` aggregates `mrr_value_cents` across ALL matching events with no `WHERE` clause on `e.data->>'currency'`. The `dunning.exhausted` and `dunning.recovered` event payloads written by `Accrue.Webhook.DefaultHandler` carry a per-event `currency` field (e.g. `"usd"` or `"jpy"`, see `default_handler.ex:827` and `:914`), and Stripe customers in different currencies WILL produce events in different denominations. `RecoveryLive.mount/3` then formats the currency-blind integer cents total using `Accrue.Config.get!(:default_currency)`.

Concrete failure: a tenant whose default currency is `:usd` has one USD recovered campaign at `mrr_value_cents: 5000` ($50.00) and one JPY recovered campaign at `mrr_value_cents: 5000` (¥5,000 ≈ $33). The dashboard displays "Recovered MRR: $100.00" — formed by `5000 + 5000 = 10_000` cents under the USD formatter. The "$100" claim is wrong by every interpretation: it is neither $33+$50=$83 (correctly converted) nor an honest "mixed-currency" rendering. A merchant making revenue decisions on this number is being lied to.

Phase 144 RESEARCH.md Pitfall #4 anticipates the runtime-vs-compile-time read for `default_currency` (handled correctly by `Config.get!/1` over `compile_env`) but does NOT anticipate the multi-currency-rollup question. This was not stress-tested because every existing test fixture is single-currency.

**Fix:** Either (a) parametrize the analytics by currency and have the LiveView pick one per-call (preferred — matches the per-event currency tag), or (b) add a defensive guard that emits operator telemetry when the aggregation crosses currencies and refuses to mix. Minimal patch for option (a):

```elixir
# in Accrue.Analytics.Dunning
@spec recovered_vs_lost_mrr(keyword()) :: %{recovered_cents: non_neg_integer(), lost_cents: non_neg_integer(), currency: String.t()}
def recovered_vs_lost_mrr(opts \\ []) when is_list(opts) do
  currency = Keyword.get(opts, :currency) || Atom.to_string(Accrue.Config.get!(:default_currency))

  query =
    from(e in Event,
      where: e.type in [@recovered_type, @exhausted_type],
      where: fragment("(?->>'currency') = ?", e.data, ^currency),
      group_by: e.type,
      select: {e.type, sum(fragment("CASE WHEN jsonb_typeof((?->'mrr_value_cents')) = 'number' THEN (?->>'mrr_value_cents')::integer ELSE 0 END", e.data, e.data))}
    )
    |> apply_window(opts)

  results = Repo.all(query) |> Map.new()

  %{
    recovered_cents: Map.get(results, @recovered_type) || 0,
    lost_cents: Map.get(results, @exhausted_type) || 0,
    currency: currency
  }
end
```

Then have `RecoveryLive.mount/3` pass `currency:` explicitly and use the returned `currency` for the formatter. Mirror in `funnel/1` if mixed-currency cohorts should be reported separately (less critical because the funnel reports counts, not money).

## Warnings

### WR-01: Funnel docstring claims "strictly less" when invariant is structurally an equality

**File:** `accrue/lib/accrue/analytics/dunning.ex:77-81`

**Issue:** The doc reads "guarantees the invariant `recovered + exhausted + active <= entered`. (Strictly less when a tuple flags BOTH recovered AND exhausted — physically impossible by construction but defensively handled.)" In fact the three filter predicates `has_recovered` / `has_exhausted AND NOT has_recovered` / `NOT has_recovered AND NOT has_exhausted` PARTITION the boolean space, so EVERY tuple contributes exactly 1 to exactly one of the three counts and 1 to `entered`. The sum is always `== entered`, never `< entered`. The "strictly less" case described in the doc cannot occur — a both-flags tuple contributes 1 to `recovered`, 0 to `exhausted`, 0 to `active`, summing to 1 = `entered`.

This isn't a runtime bug (the property test `<=` invariant still holds), but the documentation misleads a future reader trying to reason about how the bounded inequality could become strict.

**Fix:** Rewrite the invariant claim:

```elixir
@doc """
...
The three filter predicates are mutually exclusive AND exhaustive (they
partition the {has_recovered, has_exhausted} boolean space), so the
identity `recovered + exhausted + active == entered` holds for every
window. A tuple that flags BOTH recovered AND exhausted (physically
impossible by construction) would still satisfy the identity — it
would contribute 1 to `recovered` only.
"""
```

Then strengthen the property test to assert equality, not `<=`.

### WR-02: `RecoveryLive.mount/3` has no error handling around analytics queries

**File:** `accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex:10-31`

**Issue:** `mount/3` calls `Dunning.recovered_vs_lost_mrr()` and `Dunning.funnel()` directly. If either raises (DB connection blip, malformed legacy event row, Postgrex error during the JSONB cast), the LiveView mount crashes and the user sees the generic 500 page. There is no `try`/`rescue`, no `:telemetry` for analytics-degraded state, and no fallback empty render.

The DAN-08 safe-cast does protect against the most common JSONB-cast crash (string `mrr_value_cents` values), but a malformed `accrue_events.data` payload (e.g. data is JSON `null` instead of `{}`) would still crash `(?->'mrr_value_cents')` due to NULL dereference. A single bad row breaks the entire recovery dashboard.

**Fix:** Wrap the queries and provide a zero fallback with telemetry:

```elixir
stats =
  try do
    Dunning.recovered_vs_lost_mrr()
  rescue
    e ->
      :telemetry.execute([:accrue, :analytics, :recovery_query_failed], %{count: 1}, %{error: inspect(e), op: :recovered_vs_lost_mrr})
      %{recovered_cents: 0, lost_cents: 0}
  end

funnel =
  try do
    Dunning.funnel()
  rescue
    e ->
      :telemetry.execute([:accrue, :analytics, :recovery_query_failed], %{count: 1}, %{error: inspect(e), op: :funnel})
      %{entered: 0, recovered: 0, exhausted: 0, active: 0}
  end
```

### WR-03: Static SVG element IDs in FunnelChart collide if rendered twice on the same page

**File:** `accrue_admin/lib/accrue_admin/components/funnel_chart.ex:54,58-59`

**Issue:** The SVG declares `aria-labelledby="funnel-title funnel-desc"` and embeds `<title id="funnel-title">` and `<desc id="funnel-desc">` with HARDCODED IDs. If a future page (a comparative view, a small-multiples dashboard, a print/export composite, etc.) renders two `<FunnelChart.funnel_chart>` components, the page will have two DOM elements with `id="funnel-title"`. This is a hard violation of HTML5's unique-ID-per-document rule and breaks `aria-labelledby` resolution — screen readers may announce only one chart's label for both, or behave unpredictably.

Current LiveView renders only one funnel, so this is dormant — but the component is reusable by design and the bug will lurk until activated.

**Fix:** Generate a stable per-render id (or accept an `:id` attr) and prefix the element IDs:

```elixir
attr(:id, :string, default: nil)
...
def funnel_chart(assigns) do
  assigns =
    assigns
    |> assign_new(:id, fn -> "funnel-#{System.unique_integer([:positive])}" end)
    |> assign(:recovered_pct, pct(assigns.recovered, assigns.entered))
    |> assign(:exhausted_pct, pct(assigns.exhausted, assigns.entered))

  ~H"""
  ...
  <svg ... aria-labelledby={"#{@id}-title #{@id}-desc"} ...>
    <title id={"#{@id}-title"}>Dunning recovery funnel</title>
    <desc id={"#{@id}-desc"}>...</desc>
  </svg>
  ...
  """
end
```

### WR-04: `@since "1.4.0"` is plain docstring text, not ExDoc metadata

**File:** `accrue/lib/accrue/analytics/dunning.ex:109`, `accrue_admin/lib/accrue_admin/components/funnel_chart.ex:27`

**Issue:** Both files contain `@since "1.4.0"` INSIDE the `@doc` heredoc string, not as a sibling module attribute. ExDoc's "since" pill is sourced from `@doc since: "..."` (a keyword on the doc itself) or `@since` set BEFORE `@doc`. Inside the heredoc, `@since "1.4.0"` renders as literal markdown text in the generated HTML — it does NOT produce the version-introduced indicator that the rest of the codebase uses for backward-compat tracking.

This matters because Accrue's public-API surface tracks "@since" markers in ExDoc — both `Accrue.Analytics.Dunning.funnel/1` and `AccrueAdmin.Components.FunnelChart.funnel_chart/1` are public-API additions in v1.44 and need correct ExDoc since-markers for the release notes pipeline.

**Fix:** Move the marker out of the heredoc and use the proper ExDoc form:

```elixir
@doc since: "1.4.0"
@doc """
Three-stage dunning funnel computed from the `accrue_events` ledger.
...
"""
@spec funnel(keyword()) :: ...
def funnel(opts \\ []) when is_list(opts) do
  ...
```

### WR-05: No test for `__legacy__` sentinel mixing with anchored events for the SAME subject

**File:** `accrue/test/accrue/analytics/dunning_test.exs:198-222`

**Issue:** The "legacy events without campaign_anchor collapse under '__legacy__'" test exercises ONLY legacy events. It does not exercise the realistic post-deploy scenario: a subject has a pre-Phase-144 `dunning.recovered` (no `campaign_anchor`) AND a post-Phase-144 `dunning.exhausted` (with `campaign_anchor`). The COALESCE behavior is well-defined (they end up in two separate tuples: `(subject, '__legacy__')` and `(subject, '2026-...')`), but the implementation may surprise operators reading the numbers — a single subject that cycled both before AND after the cutoff contributes 2 to `entered`.

The current test suite does not document or assert this "double-counting across the cutoff" behavior. A regression here could silently inflate or deflate `entered` without breaking any existing test.

**Fix:** Add a regression test:

```elixir
test "legacy and anchored events for the same subject form two distinct tuples" do
  subject_id = Ecto.UUID.generate()

  # Legacy: no campaign_anchor (pre-Phase-144 event)
  Accrue.Repo.insert!(%Accrue.Events.Event{
    type: "dunning.recovered",
    subject_type: "Subscription",
    subject_id: subject_id,
    actor_type: "system",
    schema_version: 1,
    data: %{}
  })

  # Post-Phase-144: anchored
  Accrue.Repo.insert!(%Accrue.Events.Event{
    type: "dunning.exhausted",
    subject_type: "Subscription",
    subject_id: subject_id,
    actor_type: "system",
    schema_version: 1,
    data: %{"campaign_anchor" => "2026-06-01T00:00:00Z"}
  })

  # Two tuples: (subject, '__legacy__') and (subject, '2026-06-01...')
  assert %{entered: 2, recovered: 1, exhausted: 1, active: 0} = Dunning.funnel()
end
```

### WR-06: Stale-recovery-isolation test never exercises the actual webhook path it claims to protect

**File:** `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs:281-319`

**Issue:** The test "a stale recovery keyed to an OLD campaign does not cancel a FRESH campaign's steps" sets up two anchors (A=old, B=fresh) and seeds Oban jobs against B. It then directly invokes `Oban.cancel_all_jobs` with a fragment matching `iso_a` (the old anchor) and asserts B's steps survive. The test never invokes `DefaultHandler.handle/1` for the stale recovery scenario, and the line `_ = sub_id` (line 317) admits this — the bound variable is never used.

What the test actually proves: `Oban.cancel_all_jobs` matched by a non-existent key cancels nothing. That's a tautology about Oban's query semantics, not a guarantee about Accrue's webhook reducer behavior. The real failure mode the test claims to guard against — "an out-of-order recovery webhook for an old campaign reaches `run_post_commit_dunning_cancel` and cancels the fresh campaign's steps" — is not exercised.

To prove the guarantee, the test needs to (a) fire a recovery webhook whose stashed anchor is `iso_a`, (b) confirm B's steps remain live after `DefaultHandler.handle/1` returns. Currently the cancel-keying invariant in production code depends on `Process.put(:accrue_dunning_cancel, {updated, iso_anchor})` capturing the anchor at the right moment — that capture is not directly tested.

**Fix:** Rewrite the test to drive through `DefaultHandler.handle/1` with a stale-anchor scenario, or rename the test to "cancel keyed by a non-existent anchor is a no-op" and acknowledge the narrower claim.

## Info

### IN-01: Property test inflates cardinality with `iteration_tag` interpolation

**File:** `accrue/test/property/dunning_funnel_property_test.exs:54-65`

**Issue:** To work around the append-only `accrue_events` table within a single sandbox transaction, the test interpolates `iteration_tag = System.unique_integer([:positive])` into BOTH `subject_id` and `campaign_anchor`. This works, but it means the generator's intended cardinality (3 subjects × small anchor pool) explodes per iteration into a fresh universe — the property doesn't actually exercise the "many iterations share subjects" cohort behavior the generator suggests.

For the strict mutual-exclusion invariant this is OK (the predicates are per-tuple), but the test name and generator structure imply cohort interactions that aren't really exercised.

**Fix:** Document the trade-off in the moduledoc, or move to a `setup_all`-cleanup pattern that DELETEs `accrue_events` rows between iterations (requires bypassing the immutability trigger — not recommended for a property test).

### IN-02: Funnel invariant in property test could be tightened from `<=` to `==`

**File:** `accrue/test/property/dunning_funnel_property_test.exs:69`

**Issue:** Per the WR-01 analysis, the structural invariant is actually `recovered + exhausted + active == entered`. The property test asserts the weaker `<=` bound, which always holds and provides less protection. Tightening to `==` would catch a class of refactor regressions (e.g., a future change to the filter predicates that introduces a gap or overlap).

**Fix:** Change `<=` to `==` in the property assertion. If you keep `<=`, document why in the moduledoc.

### IN-03: JPY regression test asserts symbol presence but not formatted-cents output

**File:** `accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs:152-167`

**Issue:** The JPY test asserts that the page contains `¥` / `￥` / `"JPY"` and refutes `"$50.00"`/`"$20.00"`. It does NOT assert the formatted cents value (5000 JPY should render as `¥5,000` since JPY is a zero-decimal currency — no decimal point). A bug that incorrectly treats JPY as a 2-decimal currency would yield `¥50` or `¥50.00` and still satisfy the current assertions.

**Fix:** Add explicit value assertions: `assert html =~ "5,000"` or `assert html =~ "5000"` (matching the rendered value), and refute `"50.00"` to lock the zero-decimal behavior.

### IN-04: FunnelChart has no test for proportional-bar rounding at large counts

**File:** `accrue_admin/test/accrue_admin/components/funnel_chart_test.exs`

**Issue:** `pct/2` uses `round(n * 100 / total)`. For `entered=1, recovered=1`, this yields 100 — clean. For `entered=3, recovered=1`, this yields 33 — visually fine. But for `entered=99, recovered=33, exhausted=33, active=33`, the three percentages are all `33`, summing to `99` — not `100`. The bars won't visually fill, but no test catches the rounding floor.

This is a UX nit, not a correctness bug, but a `pct(33, 99)` test that locks in the rounding behavior would be useful for future refactors that might switch to `Float.round/2` or `trunc/1`.

**Fix:** Add a test for `entered=99, recovered=33, exhausted=33, active=33` that asserts the rendered percentages.

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
