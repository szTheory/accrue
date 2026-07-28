---
id: SEED-005
status: dormant
planted: 2026-07-28
planted_during: v1.57 Admin Operator Control Plane — Phase 211 (grep-gated CSS retirement)
trigger_when: when the new lattice_stripe version (with entitlements support) is published to Hex.pm
scope: medium
---

# SEED-005: Bump `lattice_stripe` dep once the entitlements-bearing version ships

## Why This Matters

The maintainer is actively working on a **new `lattice_stripe` version** that adds
capabilities Accrue needs — most notably **entitlements support**, plus other additions.
It is **not done yet** (in progress as of 2026-07-28). When it lands on Hex.pm, Accrue
should adopt it: the new entitlements primitives tie directly into Accrue's existing
entitlements work (see `guides/jobs_to_be_done.md` entitlements JTBD; Phase 126 flipped
entitlements ⛔→✅ "6 of 6 shipped", and Phase 127's **optional Stripe-native entitlements
sync was deferred** — the new lattice_stripe version is what unblocks that deferral).

Bumping early (before publish) is wrong — pin against a real Hex release only.

## When to Surface

**Trigger:** the new `lattice_stripe` version (the one adding entitlements support) is
published to Hex.pm. Surface at the next `/gsd-new-milestone` scan after that, or sooner
if a milestone touches entitlements / Stripe sync.

Do **not** bump the dep before the version is published.

## Scope Estimate

**Medium** — a phase or two:
1. Bump the `lattice_stripe` pin in `accrue/mix.exs` (currently `~> 1.1`) to the new version
   (+ `accrue_admin` if it pins it), run `mix deps.get`, resolve any API deltas.
2. Review/adopt the new **entitlements support** — wire it into Accrue's entitlements
   context; revisit the Phase 127 deferred "optional Stripe-native entitlements sync."
3. Update `CLAUDE.md` / tech-stack `:lattice_stripe` row + Version Compatibility Matrix
   notes, and the JTBD entitlements doc if the deferral status changes.

## Breadcrumbs

- `accrue/mix.exs` — `:lattice_stripe` dep pin (currently `~> 1.1`)
- `CLAUDE.md` — Technology Stack table `:lattice_stripe` row + Version Compatibility Matrix
- `guides/jobs_to_be_done.md` + `.planning/research/JTBD-FRONTIER.md` — entitlements JTBD
  (Phase 126 "6 of 6 shipped"; Phase 127 optional Stripe-native sync deferred)
- Related: [[SEED-002]] ecosystem-integrations

## Notes

Captured 2026-07-28 during Phase 211 execution at the maintainer's request. The maintainer
(user) owns `lattice_stripe` (sibling lib) and is building the version in question, so the
trigger is entirely within their control — this seed is the reminder to close the loop on
the Accrue side once they publish.
