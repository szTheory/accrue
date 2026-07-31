# Phase 212 Plan 01: lattice_stripe 1.7.13 → 2.1.0 Upgrade Evidence

**Bump commit:** `82f659fd` — `chore(212-01): bump lattice_stripe ~> 1.1 to ~> 2.0 across accrue, accrue_admin, accrue_portal, examples/accrue_host (BUMP-01)`
**Resolved version:** `2.1.0` (pin remains `{:lattice_stripe, "~> 2.0"}` in `accrue/mix.exs` — D-01/D-02)
**Date:** 2026-07-30

This artifact satisfies D-10: (1) a sibling-repo `lib/` diff-surface summary across the adopted tag range, (2) the fixture-decoupling statement, (3) the full per-package Three Zeros gate output.

---

## 1. Sibling-repo diff-surface summary (`../lattice_stripe`, `v1.7.13..v2.1.0`, restricted to `lib/`)

Command run from repo root: `git -C ../lattice_stripe diff --stat v1.7.13..v2.1.0 -- lib/`

The cumulative delta across both adopted releases (2.0.0 + 2.1.0, since `~> 2.0` resolves to 2.1.0 today) touches 47 files, +3155/-40 lines. Categorized:

**New, purely additive modules (cannot break any existing call site):**
- `lib/lattice_stripe/entitlements/{active_entitlement,active_entitlement_summary,feature}.ex` — the new `LatticeStripe.Entitlements.*` surface (adopted next phase, 213).
- `lib/lattice_stripe/testing.ex` + `lib/lattice_stripe/testing/fixtures/{customer,invoice,meter_error_report,meter_event,meter_event_summary,payment_intent,subscription,entitlements}.ex` — the new public fixture-builder namespace (`LatticeStripe.Testing.Fixtures.*`), promoted from the sibling's own previously-private `test/support/fixtures/*.ex`.
- `lib/lattice_stripe/billing/{meter_error_report.ex,meter_error_report/*,meter_event_summary.ex}.ex` — usage-based billing/meter additions (not in scope for Phase 212/213).
- `lib/lattice_stripe/api_surface.ex`, `lib/mix/tasks/lattice_stripe.api_surface.ex`, `lib/lattice_stripe/version_prose.ex`, `lib/mix/tasks/lattice_stripe.version_prose.ex`, `lib/lattice_stripe/application.ex`, `lib/lattice_stripe/billing/guards.ex` — new internal/dev-tooling modules (release-process/doc-generation machinery, `Application` module for auto-started default Finch), no bearing on Accrue's call sites.

**Modified, backward-compatible (the Finch-optional change, confirmed via direct file diff):**
- `lib/lattice_stripe/client.ex` (+15/-… lines): `@enforce_keys [:api_key, :finch]` → `@enforce_keys [:api_key]`; `:finch` becomes optional, defaulting to the new auto-started `LatticeStripe.Finch` pool (opt-out via `config :lattice_stripe, start_default_finch: false`).
- `lib/lattice_stripe/config.ex` (+19/-… lines): the NimbleOptions `:finch` schema entry moves from `required: true` to `type: :atom, default: LatticeStripe.Finch`.
- Both changes are purely additive/relaxing (a previously-required key becomes optional-with-default) — no existing caller that explicitly passes `:finch` is affected. **Accrue itself does not declare or reference `:finch` anywhere** in `accrue/mix.exs` or `accrue/lib` (confirmed via repo-wide grep this session), so this change is a pure win, not a reconciliation burden.

**Modified, doc-prose-only (confirmed via full diff read, zero functional change):**
- `lib/lattice_stripe/{webhook.ex, webhook/plug.ex, builders/billing_portal.ex, testing.ex (partial), object_types.ex}` and the `tax/*`, `tax_id/*`, `list.ex`, `file.ex`, `quote.ex`, `drift.ex` files, plus `lib/mix/tasks/lattice_stripe.check_drift.ex`: all diffs in this bucket are `@doc`/`@moduledoc` wording changes (e.g. de-linking internal cross-references, minor typo fixes) with zero code/API surface change. Verified by reading every non-trivial diff hunk directly (not inferred from commit messages).

**The sole breaking (`!`) commit in the whole `v1.7.13..v2.0.0` range** (confirmed via `git log --oneline --grep='!' v1.7.13..v2.0.0`, cross-checked against the CHANGELOG's single `BREAKING CHANGES` bullet):
- `cd1f896 feat(65)!: ...` — includes the `git mv`-based promotion of the fixture-builder functions (`<object>_json` naming, e.g. `LatticeStripe.Testing.Fixtures.Subscription.subscription_json/1`) from the sibling's own internal `test/support/fixtures/*.ex` into the now-public `lib/lattice_stripe/testing/fixtures/*.ex`. Because these functions were **never published to Hex under any prior version** (`v1.8`/`v1.9` tags exist in the sibling's git history but were never released — `mix hex.info lattice_stripe` shows the Hex release list jumps directly from `1.7.13` to `2.0.0`), no adopter, including Accrue, could ever have called the pre-rename names. The "breaking" label applies only in principle to the sibling repo's own internal test suite, not to any external consumer.

**`v2.0.0..v2.1.0` isolated (confirms 2.1.0 adds no new functional surface beyond 2.0.0):** `git -C ../lattice_stripe diff --stat v2.0.0..v2.1.0 -- lib/` shows 7 files touched — the new `version_prose.ex` + `lattice_stripe.version_prose.ex` release-tooling mix task, and 5 files with pure `@doc`/`@moduledoc` prose rewording (`builders/billing_portal.ex`, `testing.ex`, `webhook.ex`, `webhook/plug.ex`, `check_drift.ex`). Each of these 5 diffs was read in full — every hunk is a docstring cross-reference rewording, zero functional/code change.

**Net conclusion:** the entire `v1.7.13 → 2.1.0` `lib/` surface is exactly: (a) additive new modules Accrue does not yet call, (b) the backward-compatible Finch-optional relaxation Accrue is unaffected by (doesn't declare `:finch`), and (c) a fixture-builder rename that never had a Hex-published predecessor and that Accrue's own hand-rolled fixtures never called. No reconciliation code change was required or made.

---

## 2. Fixture-decoupling statement (D-09 breaking vector)

`accrue/test/support/stripe_fixtures.ex` hand-rolls raw Stripe API response payload maps (string keys, `"object"` discriminator) and does not call any function from `LatticeStripe.Testing` or `LatticeStripe.Testing.Fixtures.*`.

Re-confirmed at bump time (post-lock-regen, per Task 2's acceptance criteria):

```
$ grep -c 'LatticeStripe\.Testing' accrue/test/support/stripe_fixtures.ex
0
```

Zero matches, both at research time (2026-07-30 session) and re-verified independently during this execution. The fixture-rename breaking vector is confirmed a no-op for Accrue.

---

## 3. Per-package Three Zeros gate output (Task 2)

Each package's gate ran exactly its actually-configured subset per the asymmetric matrix (Pitfall 1 / RESEARCH.md "Validation Architecture"):

### `accrue` (compile x2, test, credo, dialyzer, coveralls, hex.audit)

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors` | PASS (exit 0) |
| `mix compile --warnings-as-errors --no-optional-deps` | PASS (exit 0) — confirms Finch is genuinely optional now |
| `mix test --warnings-as-errors` | PASS — 58 properties, 1685 tests, 0 failures (11 excluded) |
| `mix credo --strict` | PASS — 452 files, 3851 mods/funs, 0 issues |
| `mix dialyzer --format github` | PASS — PLT auto-rebuilt (mix.lock hash changed), 0 errors after rebuild |
| `MIX_ENV=test mix coveralls` | PASS — 76.3% total (excoveralls is a real dep here) |
| `mix hex.audit` | Non-lattice_stripe advisories present (see note below) |

### `accrue_admin` (compile x2, test, credo, dialyzer, coverage, hex.audit)

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors --no-optional-deps` | PASS (exit 0) |
| `mix test --warnings-as-errors` | PASS — 514 tests, 0 failures |
| `mix credo --strict` | PASS — 190 files, 3820 mods/funs, 0 issues |
| `mix dialyzer --format github` | PASS — PLT auto-rebuilt, 0 errors |
| `mix test --cover` | PASS — 80.25% total (≥ 80% threshold; **no `excoveralls` dep here** — `accrue_admin/mix.exs` uses the built-in `test_coverage: [summary: [threshold: 80]]`, not excoveralls, so `mix test --cover` is the correct equivalent to "run the coveralls task," substituted per Rule 3) |
| `mix hex.audit` | Non-lattice_stripe advisories present (see note below) |

### `accrue_portal` (compile x2, test, credo, coverage, hex.audit — no dialyzer per the asymmetric matrix)

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors --no-optional-deps` | PASS (exit 0) |
| `mix test --warnings-as-errors` | PASS — 37 tests, 0 failures |
| `mix credo --strict` | PASS — 42 files, 415 mods/funs, 0 issues |
| `mix test --cover` | PASS — 77.76% total (≥ 75% threshold; same built-in-coverage substitution as accrue_admin — no `excoveralls` dep) |
| `mix hex.audit` | 1 non-lattice_stripe advisory present (postgrex — see note below) |

### `examples/accrue_host` (compile x2 + bounded test script only — no credo/dialyzer/coverage configured)

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors` | PASS (exit 0) |
| `mix compile --warnings-as-errors --no-optional-deps` | PASS (exit 0) |
| `bash scripts/ci/accrue_host_verify_test_bounded.sh` | PASS — 37 tests, 0 failures (covers the 2 files with direct `LatticeStripe.*` call sites) |

### D-09 fixture-vector re-confirmation

```
$ grep -c 'LatticeStripe\.Testing' accrue/test/support/stripe_fixtures.ex
0
```

### No reconciliation edits

```
$ git status --porcelain -- '*.exs' '*.ex'
 M accrue/mix.exs
```

Zero `.ex` files changed by this bump — only the single `mix.exs` deps-line pin edit. This confirms the D-11 "expected outcome" (no reconciliation needed): every command exits 0 with zero lattice_stripe-attributable warnings, and no new `@tag :skip` / `ExUnit.configure(exclude: ...)` / `# credo:disable-for-` marker was introduced anywhere.

### Note: `mix hex.audit` non-lattice_stripe advisories (pre-existing, out of scope)

`mix hex.audit` queries a live, externally-updated vulnerability database and flags several packages with security advisories in all four packages (`postgrex`, `swoosh`, `decimal`, `phoenix`, `req`, `hackney`, depending on package). **None of these advisories concern `lattice_stripe` itself** — `lattice_stripe 2.1.0` is not flagged as retired or vulnerable in any package's audit output, which is the load-bearing check D-08 assigns to `hex.audit` here (a supply-chain sanity check specifically on the new `lattice_stripe` release).

Confirmed pre-existing and unrelated to this bump: `git show HEAD~1:accrue/mix.lock` (the commit immediately before the bump) already pinned `postgrex 0.22.2`, `swoosh 1.25.3`, `decimal 2.4.1`, `phoenix 1.8.7`, `req 0.5.18`, `hackney 1.25.0` — the exact same versions the audit flags, byte-for-byte unchanged by this phase's `accrue`-package diff. Per the executor's scope-boundary rule (only auto-fix issues directly caused by the current task's changes), these pre-existing unrelated CVE advisories were left untouched — bumping them is a separate maintenance concern outside BUMP-01/02/03's scope fence (no new required deps, no unrelated dep bumps).

### Note: host-package extra dependency churn (informational)

`mix deps.update lattice_stripe` in `examples/accrue_host` triggered wider transitive churn (e.g. `hackney 1.25.0 → 4.6.0`, `braintree 0.16.0 → 0.17.0`, `req 0.5.18 → 0.7.1`, `phoenix 1.8.8 → 1.8.9`) beyond lattice_stripe's own subtree. This reflects that the host's pre-bump lock had drifted out of sync with the rest of the monorepo's path-mode graph (confirmed: the same stale hex-mode `:accrue`/`:accrue_admin`/`:accrue_portal` entries described in D-05 were present, meaning the host's lock had not been fully reconciled to path-mode resolution in some time). Removing the stale hex entries via `mix deps.unlock accrue accrue_admin accrue_portal` (D-05) and re-running `mix deps.get` produced a self-consistent, fully path-mode-resolved lock with `lattice_stripe` at the identical `2.1.0`/checksum shared by the other three packages. All four `mix compile --warnings-as-errors [--no-optional-deps]` checks pass clean against the resulting graph.

### Note: `mix hex.audit` "retired" check specifically

No package in any of the four `mix hex.audit` runs was reported as retired (`grep -i retired` over all four logs returns zero matches). This is the specific supply-chain check D-08 calls for.

### Note: pre-existing Finch DoS threat disposition (T-212-02)

Accrue does not declare or reference `:finch` anywhere in `accrue/mix.exs` or `accrue/lib` (confirmed via repo-wide grep this session) — this phase introduces no new auto-started Finch pool into Accrue's own process tree. Host applications that don't already pass `:finch` explicitly to `LatticeStripe.Client.new!/1` will get exactly one new default-started `LatticeStripe.Finch` pool as of 2.0.0; this is a host-app-awareness note, not an Accrue-side action item.

---

## Summary

BUMP-01: pin is `{:lattice_stripe, "~> 2.0"}` in `accrue/mix.exs`; all four locks resolve to identical `2.1.0` + checksum; the host's stale hex-mode `:accrue`/`:accrue_admin`/`:accrue_portal` entries are gone; committed together as one atomic 5-file change (`82f659fd`).

BUMP-02: every `LatticeStripe.*` call site compiles clean against 2.1.0 with zero deprecation warnings, including under `--no-optional-deps`; both pre-verified 2.0.0 breaking vectors (fixture rename, Finch pool) are reconfirmed needing zero Accrue-side code change.

BUMP-03: each package's actually-configured Three Zeros gate subset is green; zero new skips/exclusions introduced; dialyzer PLT churn absorbed automatically via the mix.lock-hash-keyed cache.
