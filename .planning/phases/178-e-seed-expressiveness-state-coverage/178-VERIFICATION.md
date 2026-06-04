---
phase: 178-e-seed-expressiveness-state-coverage
verified: 2026-06-04T21:27:43Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Loading/poll-banner state visual — double-seed + 5s browser wait"
    expected: "newer_count banner ('N new rows — click to load') appears at top of DataTable after seeding twice without reset and waiting 5s for poll_interval to fire"
    why_human: "Requires live browser timing; cannot verify with grep or synchronous test run; Phase 179 owns the screenshot and timing"
  - test: "Dark-only contrast traps exercise axe in dark theme"
    expected: "Tinted ax-badge-danger chips (past_due subscription, dead webhook, open invoice) pass axe contrast audit in dark theme"
    why_human: "Requires dark-theme axe pass against seeded data in a running browser — Phase 179's axe sweep is the verifier"
  - test: "Every STATE-MATRIX non-N/A cell reachable via single click-through in a running dev environment"
    expected: "Developer can run mix ecto.reset in examples/accrue_host, navigate to each screen, and land in every seeded state (populated, dunning, JPY, long-name, overflow) without using hand-picked IDs"
    why_human: "End-to-end dev-environment navigation cannot be verified programmatically; seeding evidence exists but human must confirm click-path correctness matches matrix descriptions"
---

# Phase 178: E — Seed Expressiveness & State Coverage Verification Report

**Phase Goal:** Make every admin screen's state and edge case reachable from seeded data on a single click-through (E2E seed fixtures at `/__e2e__/seed/<fixture>` + host `seeds.exs`), so no screen looks good only with hand-picked IDs and Phase 179's visual-QA loop can photograph every state.
**Verified:** 2026-06-04T21:27:43Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | STATE-MATRIX.md enumerates all 21 screens × state dimensions, every cell filled | ✓ VERIFIED | File exists; 41 pipe-delimited rows (header + legend + 21 data rows); `seed_overflow` appears exactly 9 times in data; 0 blank/TBD cells; 52 `seed_edge_states` occurrences |
| 2 | POST `/__e2e__/seed/edge-states` and `/__e2e__/seed/overflow` return 200 | ✓ VERIFIED | Both routes present in `e2e_plug.ex` lines 41-55 (dual path form: stripped + full); 8/8 tests green including two HTTP POST assertions (262 tests, 0 failures) |
| 3 | seed_edge_states!/0 inserts :past_due at-risk subscription with dunning_campaign_started_at set | ✓ VERIFIED | `%Subscription{} |> Subscription.force_status_changeset(...)` pipe form confirmed in `e2e_fixtures.ex` line 149; test "seed_edge_states!/0 inserts at-risk subscription with :past_due status" passes |
| 4 | seed_edge_states!/0 inserts canceling subscription (active + cancel_at_period_end: true) and JPY invoice/charge | ✓ VERIFIED | `e2e_fixtures.ex` lines 163-188 confirmed; tests for canceling sub and JPY invoice both pass green |
| 5 | seed_overflow!/0 inserts ≥26 customers and ≥26 subscriptions (DataTable Load-more reachable) | ✓ VERIFIED | `Enum.map(1..26, ...)` in `e2e_fixtures.ex` lines 221-234; test "seed_overflow!/0 inserts at least 26 customers/subscriptions" passes |
| 6 | Dunning bug fixed: hero_accounts.exs dunning events reference real subscription IDs | ✓ VERIFIED | Lines 101, 138, 164 now use `past_due_subscription.id` / `canceled_subscription.id`; zero `Ecto.UUID.generate()` calls at those sites; regression test ("dunning campaign_started events have subject_ids that match real subscriptions") passes — 3 tests, 0 failures in host suite |
| 7 | Host dev seed: edge_states.exs wired into seeds.exs, idempotent, seeds long-name customer / canceling sub / JPY charge+invoice / at-risk sub | ✓ VERIFIED | `edge_states.exs` exists with all 5 entity types; `cancel_at_period_end: true` confirmed line 106; `currency: "jpy"` confirmed lines 122, 144; `Code.eval_file("seeds/edge_states.exs", __DIR__)` in `seeds.exs` line 94; @fixture allowlists in `accrue_host_seed_e2e.exs` extended with 4 sub IDs + 1 customer ID; seed_e2e_cleanup_test passes |

**Score:** 7/7 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Photographic confirmation that every STATE-MATRIX cell produces a valid screenshot | Phase 179 | Phase 179 goal: "sweep the full screen inventory across all four matrix cells, score each screenshot against the 10 dimensions" |
| 2 | Loading/poll-banner state actually photographed via double-seed + 5s wait | Phase 179 | Phase 179 success criteria: "Playwright screenshot harness sweeps the full screen inventory" — this phase only documents the mechanism |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.planning/phases/178-e-seed-expressiveness-state-coverage/STATE-MATRIX.md` | 21-screen × state QA contract | ✓ VERIFIED | 21 data rows, 9 state columns, 9 seed_overflow cells, 52 seed_edge_states cells, 0 blank cells |
| `accrue_admin/test/accrue_admin/e2e_fixtures_test.exs` | 8-test RED scaffold (now GREEN) | ✓ VERIFIED | 8 tests, 0 failures; tests assert seed_edge_states!/0 and seed_overflow!/0 contracts |
| `accrue_admin/test/support/e2e_fixtures.ex` | seed_edge_states!/0 + seed_overflow!/0 + helpers | ✓ VERIFIED | Both functions present and substantive (137-237 lines); insert_coupon/1, insert_promo_code/2, insert_connect_account/2 private helpers added |
| `accrue_admin/test/support/e2e_plug.ex` | POST /seed/edge-states and /seed/overflow routes | ✓ VERIFIED | Dual routes for each (stripped + full path) at lines 41-55 |
| `examples/accrue_host/priv/repo/seeds/hero_accounts.exs` | Dunning bug fix — real subscription IDs | ✓ VERIFIED | 3 phantom UUIDs replaced; lines 101, 138, 164 confirmed |
| `examples/accrue_host/test/accrue_host/hero_accounts_test.exs` | Regression test for dunning event subject_id | ✓ VERIFIED | 2 tests present including regression; both pass |
| `scripts/ci/accrue_host_seed_e2e.exs` | Extended @fixture_* allowlists | ✓ VERIFIED | sub_e2e_dunning_at_risk, sub_e2e_canceling, sub_e2e_edge_at_risk, sub_e2e_edge_canceling, cus_e2e_edge_1 confirmed |
| `examples/accrue_host/priv/repo/seeds/edge_states.exs` | Host dev seed — 5 edge-state entities | ✓ VERIFIED | File exists; all 5 entities present; idempotent upsert pattern used |
| `examples/accrue_host/priv/repo/seeds.exs` | eval_file chain includes edge_states.exs | ✓ VERIFIED | `Code.eval_file("seeds/edge_states.exs", __DIR__)` at line 94 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `e2e_plug.ex` | `Fixtures.seed_edge_states!/0` | `json(conn, 200, Fixtures.seed_edge_states!())` | ✓ WIRED | Routes at lines 42-43 and 46-47 (dual path) |
| `e2e_plug.ex` | `Fixtures.seed_overflow!/0` | `json(conn, 200, Fixtures.seed_overflow!())` | ✓ WIRED | Routes at lines 50-51 and 53-54 (dual path) |
| `seed_edge_states!/0` | `Subscription.force_status_changeset/2` | `%Subscription{} \|> Subscription.force_status_changeset(attrs_map) \|> TestRepo.insert!()` | ✓ WIRED | Confirmed in `e2e_fixtures.ex` lines 148-161 (2-arity pipe form) |
| `seeds.exs` → `edge_states.exs` upsert | `Repo.get_by(schema, processor: "fake", processor_id: ...)` | idempotent get-or-insert | ✓ WIRED | Upsert helper lines 37-49 of edge_states.exs; canceling sub, JPY charge, JPY invoice confirmed |
| `hero_accounts.exs (sub_7d/sub_90d)` | `Dunning.at_risk_subscriptions/1` | `past_due_subscription.id` as subject_id in dunning events | ✓ WIRED | Lines 101, 164 use real ID; regression test confirms JOIN resolves |

### Data-Flow Trace (Level 4)

This phase produces seed data, not rendering components. Data-flow verification is at the entity-existence level — the data flows from fixture functions into the TestRepo/Repo and is therefore queryable by admin LiveViews.

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `seed_edge_states!/0` | at_risk_sub, jpy_invoice, canceling_sub | TestRepo.insert! via force_status_changeset / changeset | Yes — DB rows confirmed by test assertions | ✓ FLOWING |
| `seed_overflow!/0` | 26 customers, 26 subscriptions | TestRepo.insert! via Enum.map(1..26) | Yes — count assertion ≥26 passes | ✓ FLOWING |
| `edge_states.exs` | long_name_customer, at_risk_sub, canceling_sub, jpy_charge, jpy_invoice | Repo.insert! via upsert helper | Yes — file runs clean; idempotent second run produces no duplicates | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 8 e2e_fixtures_test.exs tests pass | `cd accrue_admin && mix test test/accrue_admin/e2e_fixtures_test.exs --seed 0` | 8 tests, 0 failures | ✓ PASS |
| Full admin suite 262 tests green | `cd accrue_admin && mix test --seed 0` | 262 tests, 0 failures | ✓ PASS |
| Host dunning + cleanup tests green | `cd examples/accrue_host && mix test test/accrue_host/hero_accounts_test.exs test/accrue_host/seed_e2e_cleanup_test.exs --seed 0` | 3 tests, 0 failures | ✓ PASS |
| STATE-MATRIX has 21 rows, 9 seed_overflow, 0 blank | `grep -c "^|" STATE-MATRIX.md` + overflow count + blank check | ROW_COUNT=41, OVERFLOW_COUNT=9, BLANK_COUNT=0 | ✓ PASS |
| hero_accounts dunning bug fixed | `grep "Ecto.UUID.generate" hero_accounts.exs` | 0 matches at former bug lines | ✓ PASS |

### Probe Execution

No probes declared for this phase. No conventional `scripts/*/tests/probe-*.sh` files reference Phase 178 fixtures.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SEED-01 | 178-01, 178-02, 178-04 | Every admin screen's empty, populated, overflow/pagination, error, and loading states reachable from seeded data on single click-through | ✓ SATISFIED | STATE-MATRIX covers all 21 screens × 9 state dimensions; E2E fixtures serve via `/__e2e__/seed/<fixture>`; host seeds.exs includes edge_states.exs; 262 tests green |
| SEED-02 | 178-02, 178-03, 178-04 | Edge states (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) each have a seeded instance | ✓ SATISFIED | at_risk_sub (:past_due + dunning_campaign_started_at), canceling_sub (cancel_at_period_end: true), JPY invoice/charge (55_000 jpy), long_name_customer (111-char name), coupon, connect_account all seeded in both E2E fixtures and host seeds |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TBD/FIXME/XXX markers found in any phase-modified file | — | — |

No debt markers found in any of the 7 phase-modified files. No stub implementations — all fixture functions insert real rows via real changesets.

### Human Verification Required

#### 1. Loading / Poll-Banner State

**Test:** Seed with `POST /__e2e__/seed/operator-flows`, navigate to `/billing/customers` in a browser. Without calling reset, POST to the same endpoint again. Wait 5 seconds for `DataTable.poll_interval_ms` (default 5000ms) to fire.
**Expected:** A "N new rows — click to load" banner appears at the top of the data table.
**Why human:** Requires live browser + wall-clock timing. Cannot be verified with ExUnit or grep; Phase 179 owns the screenshot and timing logic.

#### 2. Dark-Only Contrast Traps Exercised by axe

**Test:** Run Phase 179's axe sweep in dark theme against a browser seeded with `seed_edge_states!`. Target screens: SubscriptionLive (past_due badge), WebhookLive (dead status), DashboardLive (Recovery badge), InvoiceLive (open badge).
**Expected:** `ax-badge-danger` tinted chips pass WCAG contrast in dark mode (no axe violations on those elements).
**Why human:** Requires dark-theme browser context + axe runner. Phase 179 is the designated executor for this check.

#### 3. Single Click-Through Reachability of All STATE-MATRIX Cells

**Test:** After `mix ecto.reset` in `examples/accrue_host`, open the admin UI at `/`. Navigate to each screen listed in STATE-MATRIX.md and verify the state documented in each populated/dunning/multi-currency/long-strings cell is actually visible without using any hand-picked IDs.
**Expected:** Every cell's described state is visible via normal navigation (e.g., RecoveryLive at-risk table is non-empty, SubscriptionLive shows `:past_due` badge for at_risk_sub, InvoiceLive shows ¥55,000 for jpy_invoice, CustomerLive shows truncated 110-char name).
**Why human:** End-to-end click-through across 21 screens in a running Phoenix dev server cannot be verified programmatically. The automated tests confirm entity existence; only a human can confirm the UI renders each state as documented.

---

## Gaps Summary

No blocking gaps. All 7 observable truths are VERIFIED with direct codebase evidence:

- STATE-MATRIX.md exists with 21 rows, 9 state columns, zero blank cells, exactly 9 `seed_overflow` entries and 52 `seed_edge_states` entries.
- Both new E2E fixture functions (`seed_edge_states!/0`, `seed_overflow!/0`) exist, are substantive, and are wired to plug routes. 8/8 contract tests pass.
- The dunning bug in `hero_accounts.exs` is fixed with a regression test. 3/3 host tests pass.
- `edge_states.exs` host seed exists, is wired into `seeds.exs`, is idempotent, and seeds all 5 edge-state entity types.
- 262 admin tests, 3 host tests — 0 failures across all.

The 3 human verification items are deferred to Phase 179 by design (photographic + axe confirmation is that phase's entire purpose). Status is `human_needed` because the click-through reachability confirmation requires a human with a running dev environment.

---

_Verified: 2026-06-04T21:27:43Z_
_Verifier: Claude (gsd-verifier)_
