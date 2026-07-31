---
id: SEED-005
status: consumed
planted: 2026-07-28
triggered: 2026-07-29
planted_during: v1.57 Admin Operator Control Plane — Phase 211 (grep-gated CSS retirement)
trigger_when: TRIGGER FIRED 2026-07-29 — lattice_stripe 2.0.0 published to Hex.pm (was: when the entitlements-bearing version ships)
target_version: "2.0.0"
scope: medium
consumed_by: v1.58 Phases 212-214
---

# SEED-005: Bump `lattice_stripe` dep to 2.0.0 (entitlements support) — CONSUMED BY v1.58

## Status: CONSUMED (v1.58)

**`lattice_stripe 2.0.0` is now published on Hex.pm** (released 2026-07-29T14:50Z,
confirmed via hex.pm API — it is `latest_stable`). This seed is no longer dormant; it is
**actionable now**. It remains earmarked (not yet executed) so it isn't lost across GSD
milestones — promote it into a milestone/phase when ready, or run the bump as a quick task.

## Why This Matters

`lattice_stripe 2.0.0` adds capabilities Accrue needs — most notably **entitlements
support**, plus other additions ("some other stuff that might unblock us"). These new
entitlements primitives tie directly into Accrue's existing entitlements work (see
`guides/jobs_to_be_done.md` entitlements JTBD; Phase 126 flipped entitlements ⛔→✅
"6 of 6 shipped", and Phase 127's **optional Stripe-native entitlements sync was deferred**
— 2.0.0 is what unblocks that deferral). It is also a **major version bump** (1.x → 2.0),
so expect breaking API deltas to reconcile against Accrue's lattice_stripe call sites.

## When to Surface

**Trigger:** ✅ FIRED 2026-07-29 — `lattice_stripe 2.0.0` is on Hex.pm. Surface at the next
`/gsd-new-milestone` scan, or sooner if a milestone touches entitlements / Stripe sync.
No longer gated on publication.

## Scope Estimate

**Medium** — a phase or two (now a **major** bump 1.x → 2.0, so budget for breaking-change reconciliation):
1. Bump the `lattice_stripe` pin in `accrue/mix.exs` (currently `~> 1.1`) to `~> 2.0`
   (+ `accrue_admin` if it pins it), run `mix deps.get`, resolve API deltas from the 2.0 majors.
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

Captured 2026-07-28 during Phase 211 execution at the maintainer's request; **trigger fired
2026-07-29** when the maintainer published `lattice_stripe 2.0.0` to Hex.pm. The maintainer
(user) owns `lattice_stripe` (sibling lib), so the release was within their control — this
seed is the reminder to close the loop on the Accrue side. Left **earmarked (status: ready),
not auto-executed**, per the user's explicit ask to "not lose track" without derailing
current GSD milestone work (Phase 211 in flight). Promote via `/gsd-new-milestone` scan or
run as a standalone bump when the user chooses.
