---
phase: 212
slug: lattice-stripe-2-x-bump-green-reconciliation
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-30
---

# Phase 212 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 212-RESEARCH.md `## Validation Architecture` (independently verified 2026-07-30).
> This is a mechanical dependency-bump phase — BUMP-01/02/03 are proven by **compile/resolve/gate-green**, not by new test assertions. No Wave 0 test scaffolding is required.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (all four packages); ExCoveralls for coverage (`accrue`, `accrue_admin`, `accrue_portal`) |
| **Config file** | Per-package `mix.exs` (`test_coverage:`); `<pkg>/.credo.exs`; `accrue/.dialyzer_ignore.exs` |
| **Quick run command** | `cd <pkg> && mix compile --warnings-as-errors --no-optional-deps` (fast — catches the now-optional Finch regression) |
| **Full suite command** | Per-package matrix below (composition differs by package — confirmed this session) |
| **Estimated runtime** | ~single-digit minutes per package (test + dialyzer + credo) |

**Per-package gate composition (NOT uniform — Pitfall 1):**

| Package | test | dialyzer | credo --strict | coverage |
|---------|------|----------|----------------|----------|
| `accrue` | ✅ | ✅ | ✅ | ✅ |
| `accrue_admin` | ✅ | ✅ | ✅ | ✅ |
| `accrue_portal` | ✅ | — (none configured) | ✅ | ✅ |
| `examples/accrue_host` | compile + test only | — | — | — |

---

## Sampling Rate

- **After every task commit:** `mix compile --warnings-as-errors --no-optional-deps` on each touched package.
- **After every plan wave:** Full per-package gate matrix above.
- **Before `/gsd-verify-work`:** Every configured gate green across all four packages, zero new skips.
- **Max feedback latency:** compile gate < ~30s per package.

---

## Per-Requirement Verification Map

| Req ID | What must be TRUE | Automated Command | Package(s) | Status |
|--------|-------------------|-------------------|------------|--------|
| BUMP-01 | Pin `~> 2.0`; all 4 locks same 2.x version+checksum; 5-file atomic commit | `grep '"lattice_stripe"' accrue/mix.lock accrue_admin/mix.lock accrue_portal/mix.lock examples/accrue_host/mix.lock` + `git diff --stat` | all 4 | ⬜ pending |
| BUMP-01 | Host stale `{:hex, :accrue, ...}` line dropped | `grep '"accrue":' examples/accrue_host/mix.lock` → no hex line | `examples/accrue_host` | ⬜ pending |
| BUMP-02 | Zero compile warnings incl. Finch-optional path | `mix compile --warnings-as-errors` + `mix compile --warnings-as-errors --no-optional-deps` | `accrue`, `examples/accrue_host` | ⬜ pending |
| BUMP-02 | Fixture-rename vector confirmed no-op | `grep -rn "LatticeStripe.Testing" accrue/test/support/stripe_fixtures.ex` → 0 matches | `accrue` | ⬜ pending |
| BUMP-03 | `mix test` green, zero new skips | `mix test --warnings-as-errors` | `accrue`, `accrue_admin`, `accrue_portal` | ⬜ pending |
| BUMP-03 | `mix dialyzer` green, PLT churn absorbed (cache key includes `hashFiles(mix.lock)` → auto-rebuild) | `mix dialyzer --format github` | `accrue`, `accrue_admin` only | ⬜ pending |
| BUMP-03 | `mix credo --strict` green | `mix credo --strict` | `accrue`, `accrue_admin`, `accrue_portal` | ⬜ pending |
| BUMP-03 | Coverage green | `mix coveralls` | `accrue`, `accrue_admin`, `accrue_portal` | ⬜ pending |
| Success Criterion 5 | Fresh clean-checkout `mix deps.get && mix compile --warnings-as-errors` succeeds | Run from `git clean -fdx`/fresh clone state per package | all 4 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing test/dialyzer/credo/coverage infrastructure (where configured per package) fully covers this phase. No new test files, fixtures, or framework installs. The only net-new verification surface is the `--no-optional-deps` compile flag (Mix built-in — nothing to install).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Eyeball all four `mix.lock` files before commit | BUMP-01 | CI uses plain `mix deps.get` with **no `--check-locked`** (D-07) — green CI proves resolution is *satisfiable*, not that the *committed* lock is the resolved one | After regen, visually diff each `mix.lock`: same `2.x.y` version + matching checksum across all 4; host lock has no `{:hex, :accrue, ...}` line |
| Finalize the D-10 evidence artifact | BUMP-02 | Auditable record, not a test assertion | Capture: (1) `git diff v1.7.13..v2.1.0 -- lib/` surface summary from sibling repo, (2) fixture-decoupling statement, (3) four-package gate output incl. `--no-optional-deps` compile |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are covered by the compile/gate matrix above
- [ ] Sampling continuity: compile gate runs on every touched package per commit
- [ ] Wave 0 covers all MISSING references (N/A — none)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (compile gate)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
