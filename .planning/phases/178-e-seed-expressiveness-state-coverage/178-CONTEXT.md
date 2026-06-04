# Phase 178: E — Seed Expressiveness & State Coverage - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every admin screen's state and edge case reachable from seeded data on a single click-through — so no screen looks good only with hand-picked IDs, and so Phase 179's visual-QA loop can photograph every state. Extend the existing E2E seed fixtures (`accrue_admin/test/support/e2e_fixtures.ex`, served at `/__e2e__/seed/<fixture>` via `e2e_plug.ex`) + the host `examples/accrue_host/priv/repo/seeds.exs` (and the `scripts/ci/accrue_host_seed_e2e.exs` runner) so that empty / populated / overflow-pagination / error / loading states + edge states (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) each have a seeded instance reachable via normal navigation. Produce a screen×state STATE-MATRIX.md as the QA-loop contract. **No new screens/components, no UI redesign, no motion — this is data/fixtures engineering feeding Phase 179.** Satisfies SEED-01, SEED-02.

</domain>

<decisions>
## Implementation Decisions

Three areas proposed as a synthesized package grounded in the locked design source (`v1.51-admin-ui-depth-design.md` §4 Phase E) + a codebase scout, accepted as-is by the user (calibration: `minimal_decisive`). Scout findings: the E2E seed endpoint is `accrue_admin/test/support/e2e_plug.ex` with named fixtures in `e2e_fixtures.ex` (current: "operator-flows", consumed by `admin-visuals.spec.js` via `POST /__e2e__/seed/<name>`); `scripts/ci/accrue_host_seed_e2e.exs` (AccrueHostSeedE2E, ~20KB) is the host seed runner with an idempotent `cleanup_fixture_footprint!` keyed on a `@fixture_*` processor_id contract; host `seeds.exs` is 93 lines.

### State-coverage matrix & fixture scope (SEED-01)
- **State taxonomy:** empty / populated / overflow(pagination) / error / loading, plus the edge set: dunning-at-risk / multi-currency / long-strings / dark-only-contrast-traps. Captured in a **screen×state STATE-MATRIX.md** in the phase dir; audit which cells are currently unreached and seed those.
- **Fixture location:** extend `accrue_admin/test/support/e2e_fixtures.ex` (served via `/__e2e__/seed/<name>`) for the automated QA-loop reachability, AND the host `seeds.exs` for the dev-time click-through. Keep the existing "operator-flows" fixture working.
- **Granularity:** a small set of **named scenario fixtures** (keep operator-flows; add e.g. edge-states / overflow / dunning-at-risk / multi-currency) where each makes a cluster of related states reachable — NOT one-per-state (too many) and NOT one mega-fixture (states would collide/mask each other).
- **Single-click-through:** every state must be reachable from a seeded entity via normal navigation (no hand-picked IDs); the STATE-MATRIX documents the click-path per state cell.

### Edge-state seeding specifics (SEED-02)
- **Dunning/at-risk:** seed past_due + canceling subscriptions + a dead-letter webhook so the Recovery/Developer attention badges (Phase 175) light up and the work-queue defaults (invoices open+uncollectible, subs past_due+canceling, payments failed) are non-empty.
- **Multi-currency:** seed at least one zero-decimal currency (JPY) + a standard currency (USD/EUR) so the money-formatting path (the `format_money/3` path corrected in Phase 176) is genuinely exercised.
- **Long strings / overflow:** seed an entity with very long names/emails/metadata + enough rows to trigger pagination/overflow on list screens (and the data_table card view at mobile width).
- **Loading & error:** loading = the existing skeleton (data_table poll/loading — reachable via a paused/slow fixture or a documented test-only toggle); error = an error-empty fixture (e.g. a dead-lettered webhook / deliberately broken record). These two may require a test-only toggle since genuine async loading / runtime errors are hard to seed statically — document the mechanism in the matrix.

### Idempotency, contrast traps & QA handoff
- **Idempotency:** reuse the existing `cleanup_fixture_footprint!` processor_id-contract pattern; extend the `@fixture_*` id allowlists for any new fixtures so reseeding is idempotent (no duplicate rows). (Known v1.50 gotcha: seed idempotency.)
- **Dark-only contrast traps:** seed instances that specifically exercise tinted status backgrounds / `-readable` variants so Phase 179's dark-theme axe pass has concrete targets; record which screen+state in the matrix.
- **QA-handoff artifact:** the **STATE-MATRIX.md** (screen × state → fixture + click-path per cell) committed in the phase dir is the contract Phase 179's screenshot sweep iterates over.
- **seeds.exs vs E2E split + known dunning bug:** the E2E fixtures (test endpoint) are the authoritative reachability for the automated QA loop; the host `seeds.exs` is a rich dev-time click-through mirroring the key states — and the **known host-seed dunning bug** (flagged in the v1.50 handoff) should be fixed here so the dunning/at-risk state seeds correctly.

### Claude's Discretion
- Exact fixture names and how states are clustered into them; the exact set of seeded entities per fixture.
- The precise mechanism for the loading/error states (paused fixture vs query param toggle) — provided each is reachable on a single click-through and documented in the matrix.
- Pagination threshold row counts; the exact long-string lengths.
- Whether the multi-currency/JPY data goes in a dedicated fixture or rides an existing one.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`accrue_admin/test/support/e2e_fixtures.ex`** — the named-fixture registry; **`e2e_plug.ex`** serves `POST /__e2e__/seed/<name>`; **`live_case.ex`** wires it for tests. Extend the registry with new scenario fixtures.
- **`scripts/ci/accrue_host_seed_e2e.exs`** (`AccrueHostSeedE2E.run!/1`) — host seed runner; idempotent via `cleanup_fixture_footprint!` keyed on `@fixture_org_customer_emails` / `@fixture_*_processor_ids` / `@fixture_discount_codes` allowlists. Extend these allowlists for new fixture footprints.
- **`examples/accrue_host/priv/repo/seeds.exs`** (93 lines) — host dev seed; mirror key states here, fix the known dunning bug.
- **`accrue_admin/e2e/admin-visuals.spec.js`** — consumes `/__e2e__/seed/operator-flows`; Phase 179 extends it to sweep every fixture/state.
- **Phase 175 badges + work-queue defaults** and **Phase 176 money-formatting / 21-screen baseline** are the consumers whose states must be populated.

### Established Patterns
- Idempotent fixture seeding via the processor_id contract (do not break it — the `seed_e2e_cleanup_test.exs` asserts rerun deletes only fixture-owned rows and preserves unrelated rows).
- Custom `ax-*` CSS (no Tailwind) — but this phase ships little/no CSS; it's data.
- 254 admin tests green — do not regress; `seed_e2e_cleanup_test.exs` must stay green.

### Integration Points
- `e2e_fixtures.ex` ← consumed by `/__e2e__/seed/<name>` (admin) and by Phase 179's Playwright sweep.
- `accrue_host_seed_e2e.exs` ← the host-side fixture footprint (CI E2E).
- STATE-MATRIX.md (new) ← consumed by Phase 179.

</code_context>

<specifics>
## Specific Ideas

- **Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md` — §4 Phase E scope (lines 109–112), §6 rubric dim ④ (state coverage), §7 guardrails (the demo/host app UI is not a design target — it is the seed/runtime substrate). Downstream agents MUST read it.
- **Anti-churn justification token** per change: each new fixture/state cites the screen × rubric-dim-④ cell it makes reachable (the STATE-MATRIX cell is the justification).
- **Verification:** `cd accrue_admin && mix test --seed 0` (+ `seed_e2e_cleanup_test.exs` for host); `POST /__e2e__/seed/<name>` returns 200 and the target state is reachable; STATE-MATRIX cells all filled. Full screenshot proof is Phase 179.

</specifics>

<deferred>
## Deferred Ideas

- **Screenshot-driven visual QA sweep + LLM scoring + sign-off** across every state → Phase 179 (F). This phase only makes the states REACHABLE + documents the matrix.
- Any new screens / UI redesign — out of scope (the screens are fixed; only their seeded data changes).
- Motion states beyond what the skeleton/badge transitions (Phase 177) already provide.

*Discussion stayed within phase scope — data/fixtures only, feeding Phase 179.*

</deferred>

---

*Phase: 178-e-seed-expressiveness-state-coverage*
*Context gathered: 2026-06-04*
