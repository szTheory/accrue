---
phase: 178
slug: e-seed-expressiveness-state-coverage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 178 — Validation Strategy

> Per-phase validation contract for seed expressiveness & state coverage. From RESEARCH.md `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) — accrue_admin (fixtures) + accrue_host (seed runner) |
| **Quick run command** | `cd accrue_admin && mix test test/<touched>_test.exs --seed 0` |
| **Full admin suite** | `cd accrue_admin && mix test --seed 0` |
| **Host seed idempotency** | `cd examples/accrue_host && mix test test/accrue_host/seed_e2e_cleanup_test.exs` |
| **Estimated runtime** | ~30–60s |

---

## Sampling Rate

- **After every task commit:** focused `mix test` for the touched fixture/seed
- **After every wave:** full admin suite + seed_e2e_cleanup_test (idempotency must stay green)
- **Before sign-off:** STATE-MATRIX.md all cells filled; each new fixture POST returns 200 with target entity present; reseed idempotent
- **Max feedback latency:** ~60s

---

## Per-Task Verification Map

| Area | Requirement | Test Type | What it proves | Automated Command |
|------|-------------|-----------|----------------|-------------------|
| New named fixtures reachable | SEED-01 | LiveCase/plug test | `POST /__e2e__/seed/<name>` returns 200; the seeded entities exist | `mix test test/.../e2e_fixtures_test.exs` (or live_case) |
| State reachable on single click-through (no hand-picked IDs) | SEED-01 | LiveView test | navigating from the seeded entity surfaces the target state | `mix test test/.../<screen>_live_test.exs` |
| Dunning/at-risk seeded → badges + work-queues non-empty | SEED-02 | query/LiveView | at_risk_subscriptions/1 returns rows; dead-letter webhook present | `mix test` + dunning bug regression test |
| Multi-currency (JPY) invoice/charge seeded | SEED-02 | render/format test | JPY formats correctly (zero-decimal), no crash | `mix test` |
| Long-strings / overflow (≥26 rows, threshold 25) | SEED-02 | LiveView test | pagination/overflow active on the list | `mix test test/.../<list>_live_test.exs` |
| Idempotency: reseed = no dupes | SEED-01 | host test | cleanup_fixture_footprint! deletes only fixture-owned rows | `cd examples/accrue_host && mix test test/.../seed_e2e_cleanup_test.exs` |
| Host dunning bug fixed (real subscription ids, not phantom UUIDs) | SEED-02 | host test/query | dunning events' subject_id matches a real subscription | `mix test` + regression assertion |
| Regression | all | full suite | 254 admin tests stay green | `cd accrue_admin && mix test --seed 0` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Confirm the exact e2e_fixtures.ex "add a named fixture" recipe + the e2e_plug.ex per-fixture route clause (RESEARCH: no dynamic dispatch — each fixture needs its own `post "/seed/<name>"`).
- [ ] Confirm DataTable `@default_limit = 25` (overflow fixtures need ≥26 rows per entity).
- [ ] Confirm the dunning-bug root cause site (`hero_accounts.exs` phantom `Ecto.UUID.generate()` for dunning event subject_id) before fixing.
- [ ] Confirm idempotency allowlist extension points in `cleanup_fixture_footprint!` (@fixture_* processor_id/email/discount allowlists).

*Existing ExUnit infrastructure covers the phase — no framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Loading/poll-banner state visual | SEED-01 | needs 5s wait / double-seed timing in a live browser | Phase 179 sweep (or a documented test-only trigger) |
| Dark-only contrast traps actually trip axe | SEED-02 | requires the dark-theme axe run on seeded data | Phase 179 axe pass (this phase only seeds the targets) |
| Every state visually photographed | SEED-01 | the whole point feeds Phase 179 | Phase 179 screenshot sweep over STATE-MATRIX |

*Reachability + entity existence are automated; the photographic confirmation is Phase 179's job.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] seed_e2e_cleanup_test.exs stays green (idempotency)
- [ ] STATE-MATRIX.md all cells filled (fixture + click-path per cell)
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
