# Phase 212: lattice_stripe 2.x bump & green reconciliation - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Bump `:lattice_stripe` from `~> 1.1` → `~> 2.0` (major 1.x→2.x) across every package that resolves the dep (`accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`), reconcile the 2.0.0 breaking-change surface, and bring the Three Zeros gate (`mix test` / `mix dialyzer` / `mix credo --strict` / coverage) green across every package with **zero new skips**. Requirements: **BUMP-01, BUMP-02, BUMP-03**.

This is a mechanical dependency-currency phase, tightly fenced by the roadmap. **Out of scope this phase:** the entitlements sync adoption (Phase 213 / SYNC-*), any docs/CLAUDE.md/JTBD reconciliation (Phase 214 / DOCS-*), pinning `~> 2.1` or chasing 2.1-only features, new required deps, any admin/portal work.

</domain>

<decisions>
## Implementation Decisions

These four decisions were researched by parallel advisors (one per gray area) against the ecosystem best-practices docs in `../lattice_stripe/prompts/` and the live repo state. They form one coherent package. The user asked for a decisive one-shot recommendation rather than adjudicating each fork; these are locked defaults for the planner unless the maintainer overrides.

### Version pin precision (BUMP-01)
- **D-01:** The literal pin in `accrue/mix.exs` is `{:lattice_stripe, "~> 2.0"}` — nothing tighter (not `~> 2.0.0`) and nothing with a raised floor (not `~> 2.1`). Hex `~> 2.0` admits `>= 2.0.0 and < 3.0.0`, so a future 2.1.0 still resolves; the roadmap fence "not `~> 2.1`" is about not raising the **floor** to chase 2.1-only additions, not about forbidding 2.1 from resolving. — **Reversibility:** costly — the pin string ships in the published `accrue` package requirement and reaches every adopter's dependency tree; loosening/tightening it later is a published-contract change, not a local edit.
- **D-02:** Lock to the **latest available 2.x** at bump time — do **not** hand-freeze the lockfile to 2.0.0. Rationale: a library's `mix.lock` never reaches adopters (only the `mix.exs` requirement resolves transitively into their tree), so the committed lock exists solely for Accrue's own CI reproducibility; locking to the newest 2.x makes CI validate the exact version the published requirement will hand adopters ("exercise the range you claim to support"). **Research fact:** `~> 2.0` currently resolves to **2.1.0** (lattice_stripe 2.1.0 is an internal release-tooling-only release with no API delta), so the lock target is 2.1.0 today — not 2.0.0.

### Lockfile regeneration + host coordination (BUMP-01)
- **D-03:** Regenerate all four lockfiles in **dev/path mode only**, committed together as one atomic 5-file change (`accrue/mix.exs` pin + the four `mix.lock` files). **CI verified as unambiguously path-mode** — no `ACCRUE_*_HEX_RELEASE` var is set in any CI workflow (`ci.yml`, `accrue_host_uat.yml`, `accrue_admin_browser.yml`, `accrue_admin_assets.yml`); those vars are set only in `publish-hex.yml` / `release-please.yml`. So the single edit to `accrue/mix.exs`'s pin flows into all four locks on regen (siblings resolve `accrue` via path deps in dev). — **Reversibility:** reversible — lockfiles regenerate deterministically from the pin.
- **D-04:** Regenerate surgically with `mix deps.update lattice_stripe` per package (bumps only that dep + its subtree) rather than a blanket `mix deps.get`, so unrelated deps don't churn. Order: `accrue`, `accrue_admin`, `accrue_portal`, `examples/accrue_host`.
- **D-05:** The host-example's stale hex-mode lock is fixed **incidentally** by this regen. `examples/accrue_host/mix.lock` currently carries a stale `{:hex, :accrue, "1.4.0", ...}` entry (which pins `lattice_stripe ~> 1.1`) — a Docker-boot leftover never exercised because host CI is path-mode. Regenerating it in path mode drops that hex `accrue` line and resolves `accrue` via path. **Verify after regen:** the host lock no longer contains a `{:hex, :accrue, ...}` line, and all four locks show the same `2.x.y` version + matching checksum.
- **D-06:** Published-hex / external-adopter resolution of `:lattice_stripe` 2.x is a **release-time event, not a Phase-212 gap.** It arrives when Release Please next publishes an `accrue` carrying the `~> 2.0` pin. CI never runs hex mode, so nothing Phase 212 gates on is left red. Do **not** republish `accrue`, bump `@version`, or add an `override:`/independent host pin inside this phase (all would violate the scope fence and/or mask the real adopter-resolution truth). Only `accrue/mix.exs` pins `:lattice_stripe`; no sibling independently pins it, so BUMP-01's "lockstep" clause is a no-op here.
- **D-07 (caveat to record, not fix):** CI uses plain `cd <pkg> && mix deps.get` with **no `--check-locked`** and no `deps.unlock`, so committed-lock *contents* are never gated — green CI proves the resolution is *satisfiable*, not that the *committed* lock is the resolved one. This is a pre-existing latent condition (out of scope to fix here). Consequence for this phase: the maintainer must regenerate locally and **eyeball all four locks before commit** rather than trust CI to catch a stale lock.

### Breaking-change surface verification (BUMP-02)
- **D-08:** Adopt the **hybrid / mechanical-gate** approach: trust the two pre-verified vectors + the maintainer's ownership of the dep, but let the four-package Three Zeros gate be the real authority — specifically including `mix compile --warnings-as-errors --no-optional-deps` (the `--no-optional-deps` flag is **load-bearing** because 2.0.0 makes Finch optional, so this exercises the now-optional Finch path). Do **not** hand-audit all 147 `LatticeStripe.*` call sites — that is disproportionate when the CHANGELOG + tag diff already bound the surface.
- **D-09:** The 2.0.0 breaking surface confirmed by the sibling `../lattice_stripe/CHANGELOG.md` is: exactly **one** `BREAKING CHANGES` entry — the test fixture-builder `<object>_json` rename (test-only) — plus two **additive/backward-compatible** items: the default Finch pool (opt-out via `start_default_finch: false`) and the additive entitlements surface (new modules — cannot break existing sites). The fixture rename provably **misses Accrue**: `accrue/test/support/stripe_fixtures.ex` hand-rolls raw payload maps and never calls `LatticeStripe.Testing.Fixtures.*`.
- **D-10:** Produce a small **auditable evidence artifact** in the phase (e.g. an `UPGRADE-NOTES` / phase-verification note) pinning: (1) a `git diff v1.7.13..<resolved 2.x tag> -- lib/` summary showing the surface is exactly the documented items; (2) the explicit statement that Accrue's fixtures are decoupled from lattice_stripe's fixture builders; (3) the four-package Three Zeros gate output including the `--warnings-as-errors --no-optional-deps` compile. This makes the surface reviewable without re-walking call sites. Also absorb any dialyzer PLT churn from the major bump (PLTs rebuild clean in CI).

### Contingency if a "no-change" vector turns out wrong (BUMP-02)
- **D-11:** Contingency policy = **absorb inline iff the fix is INTERNAL AND BEHAVIOR-PRESERVING; otherwise STOP-AND-FLAG.** Crisp predicate for the planner/executor:
  - **Absorb inline** (same green commit, log it in the phase SUMMARY) only if the fix touches **solely Accrue-internal glue** (call sites, fixtures, adapter plumbing) **AND** all of: no change to a public `Accrue.*` function signature or return shape; no observable behavior/error-semantics change; no support-matrix / dependency-requirement change; no new design choice required.
  - **Stop-and-flag** (halt before editing, surface the specific delta + options to the maintainer, do **not** begin reconciling) the moment a fix would touch a public `Accrue.*` signature/return, alter observable behavior or error shape, change the support matrix, or require a design decision — because reconciling that means moving behavior+docs+examples+release-notes together (the stable-core rule) and that is a re-plan, not a bump.
  - Never let a reconciliation silently expand the scope fence (no new required deps; entitlements sync stays out of this phase). Default to **inline** for a one-line internal rename (do not stop-and-flag trivia); default to **flag** at the public-API boundary. — **Reversibility:** one-way (for the stop-and-flag boundary) — a public `Accrue.*` API/behavior change ships to adopters who pin against it; undoing a shipped public-surface change is a breaking change requiring a semver bump and adopter migration, which is exactly why it must be flagged, not absorbed.

### Claude's Discretion
- Exact filename/location and format of the evidence artifact (D-10) — planner's choice, so long as the three contents are captured and it's committed with the phase.
- Whether the `--no-optional-deps` compile is added as a new CI step or run as a local verification gate — planner/executor's call, provided BUMP-02/BUMP-03 success criteria are demonstrably met.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & requirements (binding)
- `.planning/ROADMAP.md` — v1.58 posture + Phase 212 goal/success-criteria + the binding scope fence (`~> 2.0` not `~> 2.1`; no new required deps; no admin/portal work; no docs reconciliation this phase).
- `.planning/REQUIREMENTS.md` — BUMP-01 / BUMP-02 / BUMP-03 full text + "Out of Scope" exclusions.
- `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md` — origin of the bump, breadcrumbs, scope estimate.

### Dependency & version truth
- `accrue/mix.exs` §deps (line ~64) — the single `:lattice_stripe` pin to bump (`~> 1.1` → `~> 2.0`).
- `accrue/mix.lock`, `accrue_admin/mix.lock`, `accrue_portal/mix.lock`, `examples/accrue_host/mix.lock` — the four lockfiles to regenerate to the same 2.x; currently all at `1.7.13`; host lock also carries a stale `{:hex, :accrue, "1.4.0"}` entry to drop.
- `examples/accrue_host/mix.exs` (helpers `accrue_dep/0` etc., ~lines 78-125), `accrue_admin/mix.exs` (~lines 115-121), `accrue_portal/mix.exs` (~lines 77-83) — the hex-vs-path env-switch that makes CI path-mode.
- `../lattice_stripe/CHANGELOG.md` + `../lattice_stripe/.release-please-manifest.json` — authoritative 2.0.0 breaking/additive delta and the fact that `~> 2.0` resolves to 2.1.0 (release-tooling-only).

### Verification surface
- `accrue/test/support/stripe_fixtures.ex` — proves the fixture-rename breaking vector misses Accrue (hand-rolled maps, no `LatticeStripe.Testing.Fixtures.*`).
- `.github/workflows/ci.yml` (path-mode `mix deps.get`), `.github/workflows/accrue_host_uat.yml`, `.github/workflows/accrue_admin_browser.yml`, `.github/workflows/accrue_admin_assets.yml` — confirm CI is path-mode and locks are not `--check-locked`-enforced.
- `.github/workflows/publish-hex.yml`, `.github/workflows/release-please.yml` — where the `*_HEX_RELEASE` vars ARE set (release-time hex resolution; D-06's deferral target).
- `CLAUDE.md` §Technology Stack (`:lattice_stripe` row) + §Version Compatibility Matrix — **do not edit this phase** (Phase 214 / DOCS-01), but note the stale `~> 0.2` matrix cell + `1.1.0` claim so the planner doesn't get confused by the mismatch between docs and the actual resolved `1.7.13`.

### Ecosystem best-practices (advisor sources — informative)
- `../lattice_stripe/prompts/elixir-opensource-libs-best-practices-deep-research.md` §11 (lines ~417-437) — a library's mix.lock never ships to adopters; compatibility-minded (looser) constraints.
- `../lattice_stripe/prompts/elixir-best-practices-deep-research.md`, `../lattice_stripe/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — the mechanical-gate stack (compile `--warnings-as-errors --no-optional-deps`, tests-as-warnings, dialyzer, credo `--strict`) as the correctness backstop; Conventional-Commits→SemVer discipline for the inline-vs-flag boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The four-package Three Zeros gate already exists in CI (`ci.yml`) — the bump reuses it as the correctness backstop rather than adding new verification machinery.
- `mix deps.update lattice_stripe` (surgical single-dep update) is the tool for lockfile regen — no custom tooling needed.

### Established Patterns
- **Hex-vs-path dep duality:** every sibling switches between published (hex) and monorepo (path) deps via env-guarded helpers in its `mix.exs`. Dev + CI = path mode; publish/release = hex mode. The bump edits one pin (`accrue/mix.exs`) and lets path resolution propagate.
- **Atomic phase commit:** BUMP-01 requires the pin + all four locks committed together in one change.
- **Stable-core rule:** any processor-surface/support-matrix/public-API implication moves behavior+docs+examples+release-notes together — this is the exact boundary D-11's stop-and-flag predicate enforces.

### Integration Points
- `accrue/mix.exs` pin is the single lever; all four lockfiles are the propagation surface; the sibling `../lattice_stripe` repo is the source of truth for the 2.x delta.
- ~147 `LatticeStripe.*` call sites in `accrue` core, 4 in `examples/accrue_host`, 0 in admin/portal — the compile+test gate covers them; no manual audit planned (D-08).

</code_context>

<specifics>
## Specific Ideas

- The user (maintainer) **owns and publishes `lattice_stripe`** — asymmetric ground-truth knowledge of the 2.0.0 delta. Treated as strong signal but not a substitute for the mechanical green (D-08); the author-blind-spot risk is covered by the compile+test+tag-diff backstop.
- `~> 2.0` resolving to **2.1.0** (not 2.0.0) is expected and fine — 2.1.0 is release-tooling-only with no API delta. Don't be surprised by a `2.1.0` in the regenerated locks.

</specifics>

<deferred>
## Deferred Ideas

- **Stripe-native advisory entitlements sync** — Phase 213 (SYNC-01..05). The 2.x `LatticeStripe.Entitlements.*` modules land with this bump but are adopted next phase.
- **Docs/truth reconciliation** — Phase 214 (DOCS-01..03): flip CLAUDE.md `:lattice_stripe` row + fix the stale `~> 0.2` matrix cell + `1.1.0` claim, flip the JTBD "sync deferred" status, changelog/release-notes + `@since`. Explicitly not this phase.
- **Enforce committed locks in CI** (`--check-locked`) — surfaced by D-07 as a pre-existing latent gap. Out of scope here; candidate for a future CI-hardening item (revisit trigger: a stale-lock regression actually bites, or a CI-determinism milestone reopens).

</deferred>

---

*Phase: 212-lattice-stripe-2-x-bump-green-reconciliation*
*Context gathered: 2026-07-30*
