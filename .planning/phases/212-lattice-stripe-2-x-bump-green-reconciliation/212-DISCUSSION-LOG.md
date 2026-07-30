# Phase 212: lattice_stripe 2.x bump & green reconciliation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-30
**Phase:** 212-lattice-stripe-2-x-bump-green-reconciliation
**Areas discussed:** Breaking-surface completeness, Lockfile regen + host coordination, Version pin precision, Contingency if 'no-change' is wrong

---

The user selected all four gray areas and asked for parallel-advisor research per area (pros/cons/tradeoffs + idiomatic Elixir/ecosystem + lessons from other libs + DX), then a decisive, mutually-coherent one-shot recommendation so they would not have to adjudicate each fork. Four `gsd-advisor-researcher` agents ran in parallel against the ecosystem best-practices docs in `../lattice_stripe/prompts/` and the live repo. Their recommendations converged with no contradictions and are recorded as D-01..D-11 in CONTEXT.md.

---

## Version pin precision

| Option | Description | Selected |
|--------|-------------|----------|
| A. `~> 2.0`, lock to latest 2.x | Hex-idiomatic library floor; admits all 2.x; lock target = newest 2.x (a library's mix.lock never ships to adopters) | ✓ |
| B. `~> 2.0` but hand-freeze lock to 2.0.0 | Same requirement string, but CI tests a stale version — strictly worse posture | |
| C. `~> 2.0.0` (patch-only) | Over-tight; causes diamond conflicts for adopters; rejected by fence intent | |

**User's choice:** A (via decisive-recommendation delegation).
**Notes:** Literal pin = `{:lattice_stripe, "~> 2.0"}`. Hex `~> 2.0` = `>= 2.0.0 and < 3.0.0`; the fence "not `~> 2.1`" is about the floor, not forbidding a 2.1 from resolving. Research fact: `~> 2.0` resolves to 2.1.0 today (release-tooling-only, no API delta). → D-01, D-02.

---

## Lockfile regen + host coordination

| Option | Description | Selected |
|--------|-------------|----------|
| A. Path-mode regen of all four locks; hex catches up at release | Matches the mode CI actually runs; atomic; fixes the stale host lock incidentally; honors scope fence | ✓ |
| B. Also republish `accrue` so host resolves 2.x in hex mode now | Couples a lib bump to a release; violates ship-complete cadence; chicken-and-egg | |
| C. `override:` / explicit host pin to force 2.x | Adds a forbidden pin; masks real adopter resolution truth | |

**User's choice:** A.
**Notes:** CI verified path-mode (no `*_HEX_RELEASE` var in any CI workflow). Single `accrue/mix.exs` pin edit propagates via path deps. Regen surgically with `mix deps.update lattice_stripe` per package. Host lock's stale `{:hex, :accrue, "1.4.0"}` line drops incidentally. Published-hex resolution is a release-time event, not a Phase-212 gap. Caveat recorded: CI uses plain `mix deps.get` with no `--check-locked` → eyeball all four locks before commit. → D-03..D-07.

---

## Breaking-surface completeness

| Option | Description | Selected |
|--------|-------------|----------|
| A. Trust roadmap 2 vectors + maintainer knowledge; document & move on | Fastest but no reproducible artifact; author blind-spot risk | |
| B. Full independent diff of all 147 call sites as a gate | Max confidence but disproportionate; CHANGELOG + tag diff already bound the surface | |
| C. Hybrid — trust the 2 vectors, make the four-package mechanical green the real backstop | Idiomatic Elixir; deterministic; `--no-optional-deps` exercises the now-optional Finch path | ✓ |

**User's choice:** C.
**Notes:** 2.0.0 CHANGELOG = one test-only breaking change (fixture `<object>_json` rename) + two additive items (default Finch pool w/ `start_default_finch: false` opt-out; entitlements surface). Accrue's `stripe_fixtures.ex` hand-rolls maps → breaking vector misses Accrue. Produce an auditable evidence note (tag-diff summary + fixture-decoupling statement + gate output). → D-08, D-09, D-10.

---

## Contingency if 'no-change' is wrong

| Option | Description | Selected |
|--------|-------------|----------|
| A. Absorb inline unconditionally | Never stalls but scope fence stops being binding; worst for a published lib | |
| B. Absorb inline iff internal AND behavior-preserving; else stop-and-flag | Keeps bump atomic in common case; halts exactly at the public-API boundary | ✓ |
| C. Always stop-and-flag any unforeseen delta | Blocks on trivia; escalation fatigue devalues real flags | |

**User's choice:** B.
**Notes:** Crisp predicate — absorb inline only if the fix touches solely Accrue-internal glue AND changes no public `Accrue.*` signature/return, no observable behavior/error shape, no support matrix, no design choice; otherwise halt, surface delta+options, don't begin reconciling. Log every inline fix in SUMMARY. → D-11.

---

## Claude's Discretion

- Exact filename/location/format of the breaking-surface evidence artifact (D-10).
- Whether the `--no-optional-deps` compile is a new CI step or a local verification gate.

## Deferred Ideas

- Stripe-native advisory entitlements sync → Phase 213 (SYNC-01..05).
- Docs/truth reconciliation (CLAUDE.md pin + stale `~> 0.2` cell + JTBD status flip + changelog/`@since`) → Phase 214 (DOCS-01..03).
- Enforce committed locks in CI (`--check-locked`) — pre-existing latent gap surfaced by D-07; future CI-hardening candidate.
