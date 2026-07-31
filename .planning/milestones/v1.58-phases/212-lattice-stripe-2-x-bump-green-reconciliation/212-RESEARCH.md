# Phase 212: lattice_stripe 2.x bump & green reconciliation - Research

**Researched:** 2026-07-30
**Domain:** Elixir dependency-version bump (major 1.x→2.x) across a 4-package monorepo, mechanical reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

These four decisions were researched by parallel advisors (one per gray area) against the ecosystem best-practices docs in `../lattice_stripe/prompts/` and the live repo state. They form one coherent package. The user asked for a decisive one-shot recommendation rather than adjudicating each fork; these are locked defaults for the planner unless the maintainer overrides.

**Version pin precision (BUMP-01)**
- **D-01:** The literal pin in `accrue/mix.exs` is `{:lattice_stripe, "~> 2.0"}` — nothing tighter (not `~> 2.0.0`) and nothing with a raised floor (not `~> 2.1`). Hex `~> 2.0` admits `>= 2.0.0 and < 3.0.0`, so a future 2.1.0 still resolves; the roadmap fence "not `~> 2.1`" is about not raising the **floor** to chase 2.1-only additions, not about forbidding 2.1 from resolving. — **Reversibility:** costly — the pin string ships in the published `accrue` package requirement and reaches every adopter's dependency tree; loosening/tightening it later is a published-contract change, not a local edit.
- **D-02:** Lock to the **latest available 2.x** at bump time — do **not** hand-freeze the lockfile to 2.0.0. Rationale: a library's `mix.lock` never reaches adopters (only the `mix.exs` requirement resolves transitively into their tree), so the committed lock exists solely for Accrue's own CI reproducibility; locking to the newest 2.x makes CI validate the exact version the published requirement will hand adopters ("exercise the range you claim to support"). **Research fact:** `~> 2.0` currently resolves to **2.1.0** (lattice_stripe 2.1.0 is an internal release-tooling-only release with no API delta), so the lock target is 2.1.0 today — not 2.0.0.

**Lockfile regeneration + host coordination (BUMP-01)**
- **D-03:** Regenerate all four lockfiles in **dev/path mode only**, committed together as one atomic 5-file change (`accrue/mix.exs` pin + the four `mix.lock` files). **CI verified as unambiguously path-mode** — no `ACCRUE_*_HEX_RELEASE` var is set in any CI workflow (`ci.yml`, `accrue_host_uat.yml`, `accrue_admin_browser.yml`, `accrue_admin_assets.yml`); those vars are set only in `publish-hex.yml` / `release-please.yml`. So the single edit to `accrue/mix.exs`'s pin flows into all four locks on regen (siblings resolve `accrue` via path deps in dev). — **Reversibility:** reversible — lockfiles regenerate deterministically from the pin.
- **D-04:** Regenerate surgically with `mix deps.update lattice_stripe` per package (bumps only that dep + its subtree) rather than a blanket `mix deps.get`, so unrelated deps don't churn. Order: `accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`.
- **D-05:** The host-example's stale hex-mode lock is fixed **incidentally** by this regen. `examples/accrue_host/mix.lock` currently carries a stale `{:hex, :accrue, "1.4.0", ...}` entry (which pins `lattice_stripe ~> 1.1`) — a Docker-boot leftover never exercised because host CI is path-mode. Regenerating it in path mode drops that hex `accrue` line and resolves `accrue` via path. **Verify after regen:** the host lock no longer contains a `{:hex, :accrue, ...}` line, and all four locks show the same `2.x.y` version + matching checksum.
- **D-06:** Published-hex / external-adopter resolution of `:lattice_stripe` 2.x is a **release-time event, not a Phase-212 gap.** It arrives when Release Please next publishes an `accrue` carrying the `~> 2.0` pin. CI never runs hex mode, so nothing Phase 212 gates on is left red. Do **not** republish `accrue`, bump `@version`, or add an `override:`/independent host pin inside this phase (all would violate the scope fence and/or mask the real adopter-resolution truth). Only `accrue/mix.exs` pins `:lattice_stripe`; no sibling independently pins it, so BUMP-01's "lockstep" clause is a no-op here.
- **D-07 (caveat to record, not fix):** CI uses plain `cd <pkg> && mix deps.get` with **no `--check-locked`** and no `deps.unlock`, so committed-lock *contents* are never gated — green CI proves the resolution is *satisfiable*, not that the *committed* lock is the resolved one. This is a pre-existing latent condition (out of scope to fix here). Consequence for this phase: the maintainer must regenerate locally and **eyeball all four locks before commit** rather than trust CI to catch a stale lock.

**Breaking-change surface verification (BUMP-02)**
- **D-08:** Adopt the **hybrid / mechanical-gate** approach: trust the two pre-verified vectors + the maintainer's ownership of the dep, but let the four-package Three Zeros gate be the real authority — specifically including `mix compile --warnings-as-errors --no-optional-deps` (the `--no-optional-deps` flag is **load-bearing** because 2.0.0 makes Finch optional, so this exercises the now-optional Finch path). Do **not** hand-audit all 147 `LatticeStripe.*` call sites — that is disproportionate when the CHANGELOG + tag diff already bound the surface.
- **D-09:** The 2.0.0 breaking surface confirmed by the sibling `../lattice_stripe/CHANGELOG.md` is: exactly **one** `BREAKING CHANGES` entry — the test fixture-builder `<object>_json` rename (test-only) — plus two **additive/backward-compatible** items: the default Finch pool (opt-out via `start_default_finch: false`) and the additive entitlements surface (new modules — cannot break existing sites). The fixture rename provably **misses Accrue**: `accrue/test/support/stripe_fixtures.ex` hand-rolls raw payload maps and never calls `LatticeStripe.Testing.Fixtures.*`.
- **D-10:** Produce a small **auditable evidence artifact** in the phase (e.g. an `UPGRADE-NOTES` / phase-verification note) pinning: (1) a `git diff v1.7.13..<resolved 2.x tag> -- lib/` summary showing the surface is exactly the documented items; (2) the explicit statement that Accrue's fixtures are decoupled from lattice_stripe's fixture builders; (3) the four-package Three Zeros gate output including the `--warnings-as-errors --no-optional-deps` compile. This makes the surface reviewable without re-walking call sites. Also absorb any dialyzer PLT churn from the major bump (PLTs rebuild clean in CI).

**Contingency if a "no-change" vector turns out wrong (BUMP-02)**
- **D-11:** Contingency policy = **absorb inline iff the fix is INTERNAL AND BEHAVIOR-PRESERVING; otherwise STOP-AND-FLAG.** Crisp predicate for the planner/executor:
  - **Absorb inline** (same green commit, log it in the phase SUMMARY) only if the fix touches **solely Accrue-internal glue** (call sites, fixtures, adapter plumbing) **AND** all of: no change to a public `Accrue.*` function signature or return shape; no observable behavior/error-semantics change; no support-matrix / dependency-requirement change; no new design choice required.
  - **Stop-and-flag** (halt before editing, surface the specific delta + options to the maintainer, do **not** begin reconciling) the moment a fix would touch a public `Accrue.*` signature/return, alter observable behavior or error shape, change the support matrix, or require a design decision — because reconciling that means moving behavior+docs+examples+release-notes together (the stable-core rule) and that is a re-plan, not a bump.
  - Never let a reconciliation silently expand the scope fence (no new required deps; entitlements sync stays out of this phase). Default to **inline** for a one-line internal rename (do not stop-and-flag trivia); default to **flag** at the public-API boundary. — **Reversibility:** one-way (for the stop-and-flag boundary) — a public `Accrue.*` API/behavior change ships to adopters who pin against it; undoing a shipped public-surface change is a breaking change requiring a semver bump and adopter migration, which is exactly why it must be flagged, not absorbed.

### Claude's Discretion
- Exact filename/location and format of the evidence artifact (D-10) — planner's choice, so long as the three contents are captured and it's committed with the phase.
- Whether the `--no-optional-deps` compile is added as a new CI step or run as a local verification gate — planner/executor's call, provided BUMP-02/BUMP-03 success criteria are demonstrably met.

### Deferred Ideas (OUT OF SCOPE)
- **Stripe-native advisory entitlements sync** — Phase 213 (SYNC-01..05). The 2.x `LatticeStripe.Entitlements.*` modules land with this bump but are adopted next phase.
- **Docs/truth reconciliation** — Phase 214 (DOCS-01..03): flip CLAUDE.md `:lattice_stripe` row + fix the stale `~> 0.2` matrix cell + `1.1.0` claim, flip the JTBD "sync deferred" status, changelog/release-notes + `@since`. Explicitly not this phase.
- **Enforce committed locks in CI** (`--check-locked`) — surfaced by D-07 as a pre-existing latent gap. Out of scope here; candidate for a future CI-hardening item (revisit trigger: a stale-lock regression actually bites, or a CI-determinism milestone reopens).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|---------------------|
| BUMP-01 | The `:lattice_stripe` pin in `accrue/mix.exs` is bumped `{:lattice_stripe, "~> 1.1"}` → `~> 2.0`, and `mix.lock` is refreshed to a resolved 2.x version across every project that resolves the dep (`accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`), all lockfiles committed; any sibling independently pinning is bumped in lockstep. | Confirmed fact #1 (current pin/lock state), #2 (live Hex-verified `~> 2.0` → `2.1.0` resolution), #8 (only `accrue/mix.exs` pins the dep — lockstep clause is a no-op), plus the D-05 stale host-lock finding. See "Standard Stack" and "Code Examples → atomic 5-file commit shape". |
| BUMP-02 | Every `LatticeStripe.*` call site compiles clean against 2.x with no deprecated-call warnings; the two verified 2.0.0 breaking vectors (fixture rename, Finch pool) are confirmed to need no change, or reconciled if false. | Confirmed fact #3 (breaking surface = exactly 1 test-only rename + 2 additive items, independently re-derived via full tag-range `git diff`, not just CHANGELOG prose), #4 (fixture decoupling proof), #5 (Finch-optional path + Accrue's non-use of Finch), #7 (call-site counts). See "Common Pitfalls" #3/#4 and "Code Examples". |
| BUMP-03 | The Three Zeros gate (`mix test`, `mix dialyzer`, `mix credo --strict`, coverage) is green across all packages, zero new skips, dialyzer PLT churn absorbed. | Confirmed fact #6 (CI path-mode, no `--check-locked`) plus the newly-discovered per-package gate-composition asymmetry (Pitfall 1) and PLT-cache-key-on-mix.lock-hash finding (auto-absorbs churn). See "Validation Architecture" for the full per-package command matrix. |
</phase_requirements>

## Summary

This phase is a verification-first mechanical bump, and every load-bearing claim in CONTEXT.md's 11 locked decisions (D-01..D-11) was independently re-derived against the live repo and the live sibling `lattice_stripe` repo this session — including one live `mix hex.info lattice_stripe` call against the real Hex.pm registry (network-verified, not just git-tag inference). **All eight facts-to-verify are CONFIRMED, with zero contradictions.** One fact (#7, call-site counts) needed a methodology correction (initial greps over-counted by including `deps/`/`_build/` vendored copies in `accrue_admin`/`accrue_portal`; corrected counts match CONTEXT's claim exactly).

Beyond confirming CONTEXT's claims, this research surfaced three findings that **strengthen** the "no Accrue-side code change" thesis and one nuance the planner needs for accurately scoping BUMP-03's Three Zeros gate:

1. **The fixture-rename breaking change is a non-event even in principle**, not just in practice: git tags `v1.8` and `v1.9` exist in the sibling repo's history but were **never published to Hex** (`mix hex.info lattice_stripe` shows Hex's release list jumps directly from `1.7.13` → `2.0.0`, confirmed by `CHANGELOG.md`'s `[2.0.0](.../compare/v1.7.13...v2.0.0)` header). The renamed fixture-builder functions (`LatticeStripe.Testing.Fixtures.Subscription.subscription_json/1` etc.) were promoted from `lattice_stripe`'s own **internal** `test/support/fixtures/*.ex` directly into the public `lib/` tree in the same 2.0.0 commit (`cd1f896`, via `git mv` + rename) — they never existed as public API in *any* Hex-published version. No adopter, including Accrue, could ever have called the pre-rename names.
2. **`~> 2.0` resolving to `2.1.0` is confirmed live against the Hex.pm registry** (not just inferred from the manifest file), and `2.1.0`'s CHANGELOG entry (`feat(release): sync published version prose automatically`) is confirmed release-tooling-only by a full `git diff v2.0.0..v2.1.0` restricted to non-doc/non-release files — it touches only `README.md`/guides prose, a new `version_prose.ex` mix task module, and CI/release workflow files. Zero `lib/lattice_stripe/{client,config,billing,entitlements}` changes.
3. **Accrue does not declare or reference `:finch` anywhere** in `accrue/mix.exs` or `accrue/lib` — confirming the `--no-optional-deps` compile flag genuinely exercises the now-optional Finch path end-to-end, with nothing in Accrue's own dependency graph masking a hidden Finch requirement.
4. **Nuance for the planner:** the "Three Zeros gate" (test/dialyzer/credo/coverage) does **not** apply uniformly across all four packages today. Only `accrue` and `accrue_admin` run `mix dialyzer` in CI; `accrue_portal` has credo + a coverage threshold but no dialyzer dep; `examples/accrue_host` has none of dialyzer/credo/coverage configured — its CI gate is `mix compile --warnings-as-errors` + `mix test`/`mix test.live` only. BUMP-03's per-package success bar must be read against each package's *actual* configured gate, not a blanket four-package assumption.

**Primary recommendation:** Proceed exactly per CONTEXT.md's locked decisions (D-01..D-11). No new information surfaced that should change the plan's shape. The planner's job is to sequence: (1) edit the one pin in `accrue/mix.exs`, (2) run `mix deps.update lattice_stripe` in each of the four packages in the documented order, (3) run `mix compile --warnings-as-errors --no-optional-deps` per package as the Finch-optional proof, (4) run each package's actually-configured Three Zeros subset, (5) produce the D-10 evidence artifact, (6) commit the 5-file atomic change.

## Architectural Responsibility Map

This phase has no browser/frontend/API-tier surface — it is a pure build-tooling / dependency-graph change. The "tiers" here are monorepo packages, not runtime architectural layers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `:lattice_stripe` version pin | `accrue` package (`mix.exs`) | — | Sole pin location (confirmed fact #8); all other packages inherit transitively via path-mode resolution of `:accrue`. |
| Lockfile regeneration | Each of the 4 packages' own `mix.lock` | `accrue` (source of the pin) | Locks are per-package build artifacts; each must be regenerated in its own working directory even though only one source pin changes. |
| Breaking-surface reconciliation | `accrue` core `lib/` + `test/support/` | `examples/accrue_host` (4 call sites) | `accrue_admin`/`accrue_portal` have zero direct `LatticeStripe.*` call sites (confirmed) — they only inherit the dep transitively through `:accrue`, so reconciliation work concentrates entirely in `accrue` + the host example. |
| Three Zeros gate execution | Per-package CI workflow (`ci.yml`) | — | Gate composition differs per package (see Pitfall below) — not a single uniform command across all four. |
| Evidence artifact (D-10) | Phase-level doc, not code | — | Documentation/verification tier, not runtime. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|---------------|
| `:lattice_stripe` | `~> 2.0` (resolves to **2.1.0** today) | Stripe API wrapper — sibling package, same author | Already the sole Stripe SDK across all four packages; this phase moves the existing pin, it does not introduce a new dependency. `[VERIFIED: hex.pm registry — live `mix hex.info lattice_stripe` run this session]` |

**Version verification (live, this session):**
```
$ mix hex.info lattice_stripe
Config: {:lattice_stripe, "~> 2.1"}
Locked version: 1.7.13
Recent releases:
  2.1.0 (2026-07-29)
  2.0.0 (2026-07-29)
  1.7.13 (2026-05-29)
  ...
```
This is a direct network call against the live Hex.pm registry — `[VERIFIED: hex.pm registry]`, not `[ASSUMED]` or inferred from local git state alone. It independently corroborates the sibling repo's `.release-please-manifest.json` (`{".": "2.1.0"}`) and `mix.exs` `@version "2.1.0"`.

**No new packages are introduced.** The Package Legitimacy Gate protocol (designed for detecting hallucinated/slopsquatted *new* installs) does not apply in its full form here — `lattice_stripe` is an existing, already-integrated, maintainer-owned dependency undergoing a version bump, not a new install. The live `mix hex.info` call above (2,870 all-time downloads, MIT license, GitHub link `github.com/szTheory/lattice_stripe`, changelog link resolving) stands in as the equivalent legitimacy evidence.

### Supporting

None — no new supporting libraries are introduced by this phase (explicit scope fence: "no new required deps").

### Alternatives Considered

Not applicable — this is a same-package major-version bump, not a library selection decision. CONTEXT.md's D-01..D-11 already closed every open fork (pin precision, lock strategy, verification method, contingency policy).

**Installation (per-package, in the locked order):**
```bash
cd accrue && mix deps.update lattice_stripe
cd ../accrue_admin && mix deps.update lattice_stripe
cd ../accrue_portal && mix deps.update lattice_stripe
cd ../examples/accrue_host && mix deps.update lattice_stripe
```
(After first editing the pin string in `accrue/mix.exs` line 64 from `"~> 1.1"` to `"~> 2.0"`.)

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|--------------|---------|-------------|
| `lattice_stripe` | Hex.pm | First published pre-2026 (1.1.0 era); 2.0.0/2.1.0 both cut 2026-07-29 | 2,870 all-time / 826 last-7-days / 395 yesterday (`mix hex.info`, live) | `github.com/szTheory/lattice_stripe` (resolves) | OK | Approved — pre-existing dependency, version bump only |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

No packages were discovered via WebSearch or training data for this phase — the single package involved (`lattice_stripe`) was verified directly against the live Hex.pm registry via `mix hex.info` and cross-checked against the sibling repo's own git tags/CHANGELOG/`.release-please-manifest.json`, all three of which agree.

## Architecture Patterns

### System Architecture Diagram

```
                      ┌─────────────────────────────┐
                      │   accrue/mix.exs (line 64)   │
                      │  {:lattice_stripe, "~>1.1"}  │  ◄── SINGLE EDIT POINT
                      │         ↓ becomes            │      (D-01: pin precision)
                      │  {:lattice_stripe, "~>2.0"}  │
                      └───────────────┬──────────────┘
                                      │ resolved via plain Hex dep
                                      │ (NOT path — lattice_stripe has
                                      │  no hex-vs-path env switch in
                                      │  accrue/mix.exs; only :accrue
                                      │  itself gets that treatment
                                      │  in the *downstream* siblings)
                                      ▼
                         ┌────────────────────────┐
                         │  accrue/mix.lock        │  regenerated via
                         │  → lattice_stripe 2.1.0 │  `mix deps.update
                         └────────────┬────────────┘   lattice_stripe`
                                      │
              ┌───────────────────────┼───────────────────────┐
              │ path-mode :accrue dep │ path-mode :accrue dep  │ path-mode :accrue dep
              ▼                       ▼                        ▼
   ┌──────────────────┐   ┌──────────────────┐    ┌─────────────────────────┐
   │  accrue_admin     │   │  accrue_portal    │    │  examples/accrue_host    │
   │  mix.lock          │   │  mix.lock          │    │  mix.lock                 │
   │  → lattice_stripe   │   │  → lattice_stripe   │    │  → lattice_stripe          │
   │    2.1.0 (inherited)│   │    2.1.0 (inherited)│    │    2.1.0 (inherited)       │
   │  0 direct call sites│   │  0 direct call sites│    │  drops stale hex :accrue   │
   │                     │   │                     │    │  "1.4.0" line (D-05)      │
   │                     │   │                     │    │  4 direct call sites       │
   └──────────────────┘   └──────────────────┘    └─────────────────────────┘

   Each downstream sibling resolves `:accrue` via `{:accrue, path: "../accrue"}`
   in dev/CI (env-guarded: ACCRUE_ADMIN_HEX_RELEASE / ACCRUE_HOST_HEX_RELEASE
   flip it to hex mode only at publish time — those vars are set ONLY in
   publish-hex.yml / release-please.yml, never in ci.yml or any browser/
   asset/UAT workflow). Path mode means Mix re-resolves accrue's OWN deps
   (including lattice_stripe) fresh from accrue/mix.exs at every `deps.get`/
   `deps.update` — so the one edited pin propagates without any second edit.
```

### Recommended Project Structure

No new files/folders. This phase touches exactly 5 existing files:
```
accrue/mix.exs          # 1 line changed: the pin
accrue/mix.lock          # regenerated
accrue_admin/mix.lock    # regenerated
accrue_portal/mix.lock   # regenerated
examples/accrue_host/mix.lock  # regenerated (also drops stale hex :accrue entry)
```
Plus one new evidence-artifact file (D-10 — Claude's Discretion on name/location; e.g. `.planning/phases/212-.../UPGRADE-NOTES.md` or folded into the phase SUMMARY).

### Pattern 1: Hex-vs-path dependency duality (pre-existing, reused not created)
**What:** Every sibling package (`accrue_admin`, `accrue_portal`, `examples/accrue_host`) resolves its `:accrue` dependency through an env-guarded helper function that returns either a path dep (dev/CI default) or a hex dep (`ACCRUE_*_HEX_RELEASE=1`, publish-time only).
**When to use:** Already in place; this phase relies on it rather than modifying it.
**Example (confirmed live in repo):**
```elixir
# accrue_admin/mix.exs
defp accrue_dep do
  if System.get_env("ACCRUE_ADMIN_HEX_RELEASE") == "1" do
    {:accrue, "~> #{@version}"}
  else
    {:accrue, path: "../accrue"}
  end
end
```
```elixir
# examples/accrue_host/mix.exs
defp accrue_dep do
  if hex_release?() do
    {:accrue, "~> #{accrue_version()}"}
  else
    {:accrue, path: "../../accrue"}
  end
end
defp hex_release?, do: System.get_env("ACCRUE_HOST_HEX_RELEASE") == "1"
```
Note the asymmetry: `:lattice_stripe` itself has **no** such helper anywhere — `accrue/mix.exs` line 64 is a plain `{:lattice_stripe, "~> 1.1"}`. Only the `:accrue` dep (in downstream siblings) gets the hex/path treatment. This is why editing one line in `accrue/mix.exs` and running `deps.update` downstream is sufficient — it is not itself a hex/path toggle.

### Anti-Patterns to Avoid

- **Hand-freezing the lockfile to `2.0.0`:** D-02 explicitly rejects this — lock to whatever `~> 2.0` resolves to at bump time (currently `2.1.0`), since the committed lock exists for CI reproducibility, not adopter contract (a library's lock never ships to adopters).
- **Blanket `mix deps.get` instead of surgical `mix deps.update lattice_stripe`:** would churn unrelated dep versions and make the diff noisy/hard to review (D-04).
- **Auditing all ~134-147 call sites by hand:** disproportionate given the CHANGELOG + tag diff already bound the breaking surface to exactly one test-only rename that provably misses Accrue (D-08). Trust the compile+test gate as the authority instead.
- **Republishing `accrue` or bumping its `@version` as part of this phase:** D-06 — external/Hex-mode adopter resolution is a release-time event, not this phase's concern. CI never runs hex mode.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Verifying the Finch-optional path actually works | A custom "does Finch load lazily" test harness | `mix compile --warnings-as-errors --no-optional-deps` (D-08) | This flag is the mechanism Mix itself provides for excluding optional deps from the build graph — it is the correct, minimal-effort way to prove `:finch` is truly optional now. |
| Detecting whether the committed lock matches the resolved graph | A custom lock-diff script | Manual eyeball per D-07 (documented pre-existing gap, out of scope to automate this phase) | CI intentionally doesn't `--check-locked`; building automation for this would silently expand scope beyond BUMP-01..03. |
| Confirming the breaking-change surface | Re-implementing a changelog parser or walking every call site | `git diff <old-tag>..<new-tag> -- lib/` against the sibling repo + reading `CHANGELOG.md` directly (both done this session, see Sources) | The sibling repo is source-controlled and its CHANGELOG is release-please-generated from Conventional Commits — it is already the authoritative, structured record. |

**Key insight:** Every "don't hand-roll" here is really "don't build new verification tooling for a bump that's already backstopped by the existing four-package CI gate." The phase should add exactly one new command (`--no-optional-deps` compile) to the existing gate, not new machinery.

## Common Pitfalls

### Pitfall 1: Assuming the Three Zeros gate is uniform across all four packages
**What goes wrong:** Planner writes a single "run test/dialyzer/credo/coverage on all 4 packages" verification step, then it fails or is meaningless for `accrue_portal` (no dialyzer dep) and `examples/accrue_host` (no dialyzer, no credo config file, no excoveralls dep).
**Why it happens:** BUMP-03's requirement text says "Three Zeros gate... across every package" in the abstract, but the actual CI-configured gate composition differs per package.
**How to avoid:** Confirmed via `ci.yml` + each package's `mix.exs`/`.credo.exs` presence:
  - `accrue`: compile --warnings-as-errors, test --warnings-as-errors, credo --strict, dialyzer (PLT cached at `accrue/_build/test/*.plt*`, keyed on `hashFiles('accrue/mix.lock')`)
  - `accrue_admin`: same four, dialyzer PLT cached at `accrue_admin/priv/plts`, keyed on `hashFiles('accrue_admin/mix.lock', 'accrue/mix.lock', 'accrue/mix.exs', ...)`
  - `accrue_portal`: compile --warnings-as-errors, test --warnings-as-errors, credo --strict (has `.credo.exs` + `test_coverage: [summary: [threshold: 75]]`) — **no dialyzer dep in `mix.exs`, no PLT step in `ci.yml`**
  - `examples/accrue_host`: compile --warnings-as-errors, `mix test.live` — **no credo config file, no dialyxir/excoveralls dep at all**
**Warning signs:** A plan task that says "run the Three Zeros gate on accrue_host" without qualification will produce a false "gap" or a wasted verification step chasing a gate that was never configured for that package.

### Pitfall 2: Missing the stale `examples/accrue_host/mix.lock` hex `:accrue` entry
**What goes wrong:** Regenerating only the `lattice_stripe` sub-dependency without noticing the pre-existing stale `{:hex, :accrue, "1.4.0", ...}` line, which itself transitively pins `lattice_stripe ~> 1.1` and could mask a false-green if any tooling ever runs host in hex mode.
**Why it happens:** It's a Docker-boot leftover (per D-05) — host CI is path-mode so this line is silently unexercised, easy to miss in a routine `git diff` review since it doesn't error.
**How to avoid:** After regenerating, explicitly grep `examples/accrue_host/mix.lock` for `{:hex, :accrue,` — confirmed present before this phase (`"accrue": {:hex, :accrue, "1.4.0", ...}` at line 2), should be **absent** after a path-mode `deps.update`/`deps.get` regen. This is a concrete, checkable assertion for the D-10 evidence artifact.
**Warning signs:** `git diff examples/accrue_host/mix.lock` shows the `lattice_stripe` line changed but the stale `:accrue` hex line is untouched.

### Pitfall 3: Confusing "resolves to 2.1.0" with "2.1.0 pin" (violates the roadmap fence)
**What goes wrong:** Someone tightens the `mix.exs` pin itself to `~> 2.1` because that's what the lock resolves to, believing it's "more accurate."
**Why it happens:** The roadmap fence language ("not `~> 2.1`") is about the **published requirement string**, not the resolved lock version — these are two different things and easy to conflate.
**How to avoid:** D-01 is explicit: `~> 2.0` in `mix.exs` (admits `>= 2.0.0, < 3.0.0`), while `mix.lock` legitimately resolves to whatever the latest matching version is (`2.1.0` today). Never edit the `mix.exs` pin string to match the lock's resolved version.
**Warning signs:** A diff on `accrue/mix.exs` showing `"~> 2.1"` instead of `"~> 2.0"`.

### Pitfall 4: Treating the "Unreleased" CHANGELOG block as pending/unreleased work
**What goes wrong:** The sibling `CHANGELOG.md` has a stale `## [Unreleased]` section (lines 34-38) appearing *after* the `[2.0.0]` entry but *before* `[1.7.13]` — an artifact of release-please's changelog ordering — describing the default-Finch-pool feature in more detail than the terse `2.0.0` bullet. A careless read could conclude there's an unreleased Finch change still pending beyond `2.1.0`.
**Why it happens:** This is the same Finch feature already shipped in `2.0.0` (commit `f7fc710`, `feat(61-01)`), just left with a duplicate/stale "Unreleased" block that release-please didn't clean up. Confirmed via `git log v1.7.13..v2.0.0` — the `61-01` Finch commits are all *before* the `f95bd21 chore(main): release 2.0.0` tag commit.
**How to avoid:** Trust the tag boundaries (`git diff v2.0.0..v2.1.0`) over raw CHANGELOG section ordering when determining what's actually released. The `2.0.0`→`2.1.0` diff (confirmed this session) touches zero `lib/lattice_stripe/{client,config}.ex` files, proving nothing Finch-related changed between those two tags.
**Warning signs:** Treating this phase's scope as needing to "catch up to" content described only in the stale Unreleased block.

## Code Examples

### The actual Finch-optional change (2.0.0), confirmed via sibling repo diff

```elixir
# Source: git diff v1.7.13..v2.0.0 -- lib/lattice_stripe/client.ex (../lattice_stripe, this session)
# BEFORE (1.7.13):
@enforce_keys [:api_key, :finch]
# ...
# - `:finch` - Name atom of a running Finch pool (e.g., `MyApp.Finch`)   [REQUIRED]

# AFTER (2.0.0):
@enforce_keys [:api_key]
# ...
# - `:finch` - Name atom of a running Finch pool (e.g., `MyApp.Finch`). Defaults
#   to `LatticeStripe.Finch`, started automatically at application boot.  [OPTIONAL]
```

```elixir
# Source: git diff v1.7.13..v2.0.0 -- lib/lattice_stripe/config.ex
# The NimbleOptions schema entry for :finch changes from `required: true` to:
finch: [
  type: :atom,
  default: LatticeStripe.Finch,
  doc: "... Defaults to LatticeStripe.Finch, started automatically at application " <>
       "boot unless disabled via `config :lattice_stripe, start_default_finch: false`. ..."
]
```

### Confirmed: Accrue's fixtures never touch the renamed surface

```elixir
# Source: accrue/test/support/stripe_fixtures.ex (this repo)
defmodule Accrue.Test.StripeFixtures do
  @moduledoc """
  Canned Stripe API response payloads for Accrue tests.
  ...not part of the published Hex package...
  """

  @spec subscription_created(map()) :: map()
  def subscription_created(overrides \\ %{}) do
    # hand-rolled raw map, string keys, "object" discriminator —
    # zero calls to LatticeStripe.Testing or LatticeStripe.Testing.Fixtures.*
    ...
```
`grep -n "LatticeStripe.Testing" accrue/test/support/stripe_fixtures.ex` returns **zero matches**, confirmed this session.

### The atomic 5-file commit shape (D-03)

```bash
# 1. Edit the single pin
#    accrue/mix.exs: {:lattice_stripe, "~> 1.1"} → {:lattice_stripe, "~> 2.0"}

# 2. Regenerate surgically, in order (D-04):
cd accrue && mix deps.update lattice_stripe
cd ../accrue_admin && mix deps.update lattice_stripe
cd ../accrue_portal && mix deps.update lattice_stripe
cd ../examples/accrue_host && mix deps.update lattice_stripe

# 3. Verify all four locks agree + host's stale hex :accrue line is gone:
grep '"lattice_stripe"' accrue/mix.lock accrue_admin/mix.lock \
  accrue_portal/mix.lock examples/accrue_host/mix.lock
grep '"accrue":' examples/accrue_host/mix.lock   # expect: no match (or path-based, not hex)

# 4. One commit: accrue/mix.exs + all four mix.lock files together.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| `:finch` required, caller must supervise their own pool | `:finch` optional, defaults to auto-started `LatticeStripe.Finch` (opt-out via `start_default_finch: false`) | `lattice_stripe` 2.0.0 (2026-07-29) | Backwards-compatible additive change — existing callers passing `:finch` explicitly are unaffected. Accrue does not currently pass `:finch` explicitly and does not declare `:finch` itself, so this is a pure win (fewer things the host app must wire), not a reconciliation burden. |
| Public test-fixture builders lived only in `lattice_stripe`'s internal `test/support/fixtures/*.ex` (private, unreleased) | Promoted to public `lib/lattice_stripe/testing/fixtures/*.ex` with the `<object>_json` naming convention | `lattice_stripe` 2.0.0 (2026-07-29) | New capability for adopters (typed fixture builders for `customer`, `invoice`, `subscription`, `payment_intent`, `entitlements`, `meter_event*`), not a removal — the "breaking" label applies only to unreleased `v1.8`/`v1.9` internal tags, never to any Hex-published version. |
| No entitlements primitives in `lattice_stripe` | `LatticeStripe.Entitlements.{ActiveEntitlement, ActiveEntitlementSummary, Feature}` | `lattice_stripe` 2.0.0 (2026-07-29) | Out of scope for Phase 212 (adopted in Phase 213) — these modules will simply exist and compile after this bump; nothing calls them yet. |

**Deprecated/outdated:** None relevant to this phase — no Accrue-side API is deprecated by this bump.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|-----------------|
| — | (none) | — | Every claim in this research was either `[VERIFIED]` via a live command this session (grep, `git diff`, `mix hex.info`) or `[CITED]` from the sibling repo's own `CHANGELOG.md`/`.release-please-manifest.json`. No `[ASSUMED]` claims were needed — this phase's entire premise is independently checkable against two local repos, and both were checked directly. |

**This table is empty:** all claims in this research were verified or cited — no user confirmation needed.

## Open Questions

None blocking. Two minor items for the planner's awareness (not gaps in research, just discretion points already flagged in CONTEXT.md):

1. **Where does `--no-optional-deps` live?**
   - What we know: it is not currently run anywhere in `ci.yml`.
   - What's unclear: whether the plan adds it as a permanent new CI step (all four `compile --warnings-as-errors` lines could gain a `--no-optional-deps` sibling) or as a one-time local verification the executor runs and records in the D-10 evidence artifact.
   - Recommendation: CONTEXT.md already marks this "Claude's Discretion" — the planner should pick based on whether the phase wants durable regression protection (new CI step, touches `ci.yml`, larger diff) vs. minimal footprint (local-only, evidence-artifact-only, smaller diff, matches "mechanical phase" framing better). Given the scope fence explicitly favors minimal footprint, local-only + evidence artifact is the lower-risk default.

2. **Coverage command isn't directly invoked in `ci.yml` today.**
   - What we know: `excoveralls` is a `mix.exs` dep in `accrue`/`accrue_admin`/`accrue_portal` (with explicit thresholds of 80%/75% for admin/portal respectively), but no `mix coveralls` command appears anywhere in `.github/workflows/ci.yml`.
   - What's unclear: whether "coverage" as a Three Zeros pillar is currently enforced anywhere at all (a Makefile? a local pre-commit hook?) or whether it's aspirational/local-only tooling not wired into CI.
   - Recommendation: the planner should have the executor run `mix coveralls` (or `mix test --cover`) locally per package as part of BUMP-03's verification and record the result in the evidence artifact, since CI does not appear to gate on it. This isn't a phase-212 gap to fix (out of scope — CI hardening is not this phase's job) but the plan's verification steps should not assume CI already proves coverage is green.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Elixir | all mix commands | ✓ | 1.19.5 | — |
| Erlang/OTP | Elixir runtime | ✓ | 28 (erts-16.3) | — |
| `lattice_stripe` sibling repo (`../lattice_stripe`) | source-of-truth for breaking-surface verification | ✓ | tags up to v2.1.0 present locally | — |
| Hex.pm network access | `mix deps.update`, `mix hex.info` | ✓ | confirmed via live `mix hex.info lattice_stripe` call this session | — |
| Dialyzer (`dialyxir`) | `accrue`, `accrue_admin` only | ✓ (already a dep) | — | N/A — not configured for `accrue_portal`/`examples/accrue_host`, this is expected, not missing |
| Credo | `accrue`, `accrue_admin`, `accrue_portal` (not host) | ✓ (already a dep where configured) | — | N/A — `examples/accrue_host` has no `.credo.exs`, expected |

**Missing dependencies with no fallback:** none — this phase requires no new tooling.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (all four packages), ExCoveralls for coverage (`accrue`, `accrue_admin`, `accrue_portal`) |
| Config file | Per-package `mix.exs` (`test_coverage:` key); `accrue/.credo.exs`, `accrue_admin/.credo.exs`, `accrue_portal/.credo.exs`; `accrue/.dialyzer_ignore.exs` |
| Quick run command | `cd <pkg> && mix test` (per package) |
| Full suite / gate command | See per-package table below — composition differs by package, confirmed this session |

### Phase Requirements → Verification Map

This phase has no user-facing "behavior" to test in the ExUnit sense — BUMP-01/02/03 are proven by **compile/resolve/gate-green**, not by new test assertions. The verification matrix is therefore commands-per-package, not test-cases-per-requirement:

| Req ID | What must be TRUE | Verification Command(s) | Package(s) |
|--------|---------------------|---------------------------|------------|
| BUMP-01 | Pin is `~> 2.0`; all 4 locks resolve to the same 2.x; committed atomically | `grep '"lattice_stripe"' */mix.lock examples/accrue_host/mix.lock` — all 4 show identical version+checksum; `git diff --stat` shows exactly the 5 files | `accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host` |
| BUMP-01 | Host's stale hex `:accrue` entry is gone | `grep '"accrue":' examples/accrue_host/mix.lock` after regen — expect no `{:hex, :accrue, ...}` line | `examples/accrue_host` |
| BUMP-02 | Zero deprecation/compile warnings against 2.x, including the Finch-optional path | `mix compile --warnings-as-errors` (existing) **+** `mix compile --warnings-as-errors --no-optional-deps` (new, load-bearing per D-08) | `accrue` (primary — 98 lib + 36 test call sites), `examples/accrue_host` (4 call sites) |
| BUMP-02 | Fixture-rename vector confirmed no-op | `grep -rn "LatticeStripe.Testing" accrue/test/support/stripe_fixtures.ex` → zero matches (already confirmed this session, re-verify at bump time in case of drift) | `accrue` |
| BUMP-03 | `mix test` green, zero new skips | `mix test --warnings-as-errors` | `accrue`, `accrue_admin`, `accrue_portal`; `mix test.live` for `examples/accrue_host` (skips cleanly without live secrets — pre-existing, unrelated to this bump) |
| BUMP-03 | `mix dialyzer` green, PLT churn absorbed | `mix dialyzer --format github` — PLT cache key includes `hashFiles(mix.lock)`, so a lattice_stripe version bump automatically invalidates and rebuilds the cache (no manual PLT-clear step needed) | `accrue`, `accrue_admin` **only** — no dialyzer configured for `accrue_portal`/`examples/accrue_host` |
| BUMP-03 | `mix credo --strict` green | `mix credo --strict` | `accrue`, `accrue_admin`, `accrue_portal` — no `.credo.exs` for `examples/accrue_host` |
| BUMP-03 | Coverage green (no CI gate currently enforces this — see Open Questions #2) | `mix coveralls` (threshold 80% admin / 75% portal / tool-configured-no-threshold-found for accrue) | `accrue`, `accrue_admin`, `accrue_portal` |
| Roadmap Success Criterion 5 | Fresh clean-checkout `mix deps.get && mix compile --warnings-as-errors` succeeds | Run from a fresh `git clone` or `git clean -fdx` state per package (not just incremental) | all 4 packages |

### Sampling Rate

- **Per task commit:** `mix compile --warnings-as-errors --no-optional-deps` (fast, catches the Finch-optional regression immediately) per touched package.
- **Per wave / before final commit:** the full per-package matrix above.
- **Phase gate:** all rows green before the phase's evidence artifact is finalized and `/gsd-verify-work` runs.

### Wave 0 Gaps

None — existing test/dialyzer/credo/coverage infrastructure (where configured per package) fully covers this phase's verification needs. No new test files, fixtures, or framework installs are required. The only net-new verification surface is the `--no-optional-deps` compile invocation, which uses Mix's built-in flag (no new tooling to install).

## Security Domain

### Applicable ASVS Categories

This phase makes no code changes to authentication, session management, access control, or input validation surfaces — it is a dependency-version bump with a confirmed zero-diff breaking surface for Accrue. ASVS categories are assessed for completeness but most are not applicable to this phase's actual change surface.

| ASVS Category | Applies | Standard Control |
|----------------|---------|--------------------|
| V2 Authentication | no | Not touched — Stripe API key handling (`Client.new!/1`) is unchanged in shape; only the `:finch` requiredness changed. |
| V3 Session Management | no | Not touched by this phase. |
| V4 Access Control | no | Not touched by this phase. |
| V5 Input Validation | no | `LatticeStripe.Config` schema validation (`NimbleOptions`) is unchanged in required/optional semantics for `:api_key`; only `:finch` moved from required to optional-with-default. No new user-input surface. |
| V6 Cryptography | no | Not touched — webhook signature verification (`plug_crypto`) is untouched by this bump; `lattice_stripe`'s webhook signing logic is outside this diff's scope (confirmed via `git diff v1.7.13..v2.0.0 -- lib/lattice_stripe/webhook.ex` showing only doc/prose-adjacent changes, not signing logic). |
| V14 Configuration | yes | `lattice_stripe` 2.0.0's new `start_default_finch: false` opt-out is a new config surface (host-owned, not Accrue-owned) — document but no Accrue-side action required this phase. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|------------------------|
| Supply-chain: dependency bump introduces a compromised/malicious release | Tampering | `lattice_stripe` is maintainer-owned (same author as Accrue), version-controlled in a sibling repo with visible git history and Conventional-Commits-driven release-please automation; the 2.0.0/2.1.0 releases were verified this session against both the live Hex.pm registry and the local git tags/CHANGELOG — no anomaly found. Standard mitigation for future bumps: always diff the actual tag range, don't trust the CHANGELOG prose alone (this session found the stale "Unreleased" block pitfall by doing exactly this). |
| Silent auto-started Finch pool duplicating a host-managed pool | Denial of Service (resource exhaustion, minor) | Host apps that already run their own Finch pool and pass `:finch` explicitly are unaffected (backwards-compatible per the confirmed diff); apps that don't pass `:finch` get exactly one new default pool. Not a risk for Accrue itself (Accrue doesn't declare/start Finch), but worth a one-line note in the D-10 evidence artifact for downstream host-app awareness — out of scope to mitigate in code this phase. |

## Sources

### Primary (HIGH confidence — live-verified this session)

- `mix hex.info lattice_stripe` — live Hex.pm registry query, run from `accrue/` this session. Confirms `~> 2.1` config resolution, release list (`2.1.0` 2026-07-29, `2.0.0` 2026-07-29, `1.7.13` 2026-05-29, no `1.8`/`1.9` — those never published), download counts, license, source links.
- `git diff v2.0.0..v2.1.0` (full, and restricted to non-doc/release files) in `../lattice_stripe` — confirms 2.1.0 is release-tooling-only (`version_prose.ex` mix task + CHANGELOG/README prose + CI workflow files; zero `lib/lattice_stripe/{client,config,billing,entitlements}` changes).
- `git diff v1.7.13..v2.0.0 -- lib/` in `../lattice_stripe` — confirms the actual 2.0.0 `lib/` delta: `client.ex`/`config.ex` Finch-optional change, new `entitlements/*` + `testing/fixtures/*` modules (all additive/new files), no removed public functions from any previously-Hex-published version.
- `git show cd1f896` (the sole `!`-marked breaking commit) — confirms the fixture rename is a `git mv` promotion from `lattice_stripe`'s own private `test/support/fixtures/*.ex` into the public `lib/` tree, never previously public.
- `git log v1.7.13..v2.0.0 --oneline` — confirms exactly one breaking (`!`) commit in the whole range.
- `grep -rn "LatticeStripe\." accrue/lib accrue/test examples/accrue_host accrue_admin/lib accrue_admin/test accrue_portal/lib accrue_portal/test` (deps/_build-excluded) — confirms call-site counts: `accrue` lib=98/test=36 (134 total, ~matches CONTEXT's ~147), `examples/accrue_host`=4, `accrue_admin`=0, `accrue_portal`=0.
- `accrue/test/support/stripe_fixtures.ex` (full read) + targeted grep — confirms zero `LatticeStripe.Testing` references.
- `.github/workflows/ci.yml` (grep for `_HEX_RELEASE`, `check-locked`, `plt`, `dialyzer`, `credo`, `coverage`, `warnings-as-errors`) + `accrue_host_uat.yml`/`accrue_admin_browser.yml`/`accrue_admin_assets.yml` (grep) — confirms path-mode-only CI, no `--check-locked`, PLT cache keyed on `mix.lock` hash, and the per-package gate-composition asymmetry documented in Pitfall 1.
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs`, `examples/accrue_host/mix.exs` (read/grep) — confirms the hex-vs-path helper pattern and its scope (applies to `:accrue`, not `:lattice_stripe`).
- All four `mix.lock` files (grep) — confirms current `1.7.13` resolution across the board and the stale `{:hex, :accrue, "1.4.0", ...}` line in `examples/accrue_host/mix.lock`.

### Secondary (MEDIUM confidence)

- `../lattice_stripe/CHANGELOG.md` (full read of the 2.1.0/2.0.0/1.7.13 entries) — official, release-please-generated, cross-checked against the live Hex data above (fully consistent).
- `../lattice_stripe/.release-please-manifest.json` — `{".": "2.1.0"}`, consistent with `mix.exs @version` and live Hex data.

### Tertiary (LOW confidence)

- None — every claim in this research traces to a primary source checked this session.

## Metadata

**Confidence breakdown:**
- Standard stack (version target): HIGH — live Hex.pm registry query, not inference.
- Architecture (hex-vs-path duality, call-site distribution): HIGH — every file read directly, every count regrepped after an initial methodology error was caught and corrected.
- Pitfalls (gate-composition asymmetry, stale lock line, changelog ordering trap): HIGH — all four discovered via direct repo inspection this session, not carried over from CONTEXT.md.
- Breaking-surface completeness: HIGH — full `git diff` across the entire `v1.7.13..v2.0.0` range for `lib/`, not just the CHANGELOG prose, plus the commit-level `git show` for the one flagged breaking commit.

**Research date:** 2026-07-30
**Valid until:** Effectively permanent for the historical claims (tag diffs don't change); the "resolves to 2.1.0" claim is valid until `lattice_stripe` publishes a new 2.x release — re-run `mix hex.info lattice_stripe` immediately before executing the bump if more than a few days have passed, since a new patch/minor could land in the interim.
