---
id: SEED-001
status: resolved
planted: 2026-05-06
planted_during: v1.36 planning
trigger_when: after v1.36 (Phases 112-114) ships and the deterministic release gate is green
scope: Small
resolved: 2026-05-07
resolved_by: milestone-close triage
---

# SEED-001: Cut the next linked Hex release after v1.36 closeout

## Why This Matters

The last published Hex tag visible in this checkout is `accrue-v0.3.1`, while the branch has
already accumulated multiple shipped milestones beyond that line:

- v1.32 — Braintree production parity
- v1.33 — Braintree full maturity
- v1.34 — Rendro native invoice PDF default
- v1.35 — Dual-provider supportability closure

The package versions in `accrue`, `accrue_admin`, and `accrue_portal` are already `1.0.0`,
and the package changelogs describe the `1.0.0` stability commitment. That is enough shipped
progress to justify another release. However, the repo is currently in `v1.36` planning, and
that milestone is explicitly the closure pass for the remaining staged rows in the dual-provider
core contract. Releasing after v1.36 provides a cleaner story than releasing mid-closure.

## When to Surface

**Trigger:** after v1.36 (Phases 112-114) ships and the deterministic release gate is green

This seed should be presented during `$gsd-new-milestone` or release-readiness review when:
- Phase 112 promotes `Accrue.Billing.update_customer/2` to explicit first-party support
- Phase 113 closes cancellation semantics drift
- Phase 114 closes processor-support/doc/verifier drift
- `host-integration` / Fake-backed deterministic release checks are green
- `main` is no longer carrying only planning artifacts for v1.36

## Scope Estimate

**Small** — release-operational follow-through, not a new feature milestone:
- verify green release lanes
- review the combined Release Please PR
- confirm changelog / version alignment
- publish the linked `accrue` then `accrue_admin` release per `RELEASING.md`

## Breadcrumbs

Related code and decisions found in the current codebase:

- `.planning/STATE.md` — active milestone `v1.36` is still planning-only; not a clean cut point yet
- `.planning/ROADMAP.md` — v1.36 exists specifically to close remaining staged contract rows before drift-gate closeout
- `.planning/phases/112-customer-update-contract-closure/112-CONTEXT.md` — recommendation set for the first of those remaining staged rows
- `RELEASING.md` — linked Release Please + Hex publish process and required deterministic release gate
- `README.md` — `1.0.x` stability boundary and release-lane framing
- `accrue/mix.exs` — package version is already `1.0.0`
- `accrue_admin/mix.exs` — package version is already `1.0.0`
- `accrue_portal/mix.exs` — package version is already `1.0.0`
- `accrue/CHANGELOG.md` — `## Unreleased` already frames the `1.0.0` stable contract
- `accrue_admin/CHANGELOG.md` — mirrors the lockstep `1.0.0` stability posture
- git tags — latest milestone tags are `v1.33`, `v1.34`, `v1.35`; latest visible Hex-style package tag is `accrue-v0.3.1`

## Notes

Recommendation at seed time:

- **Is progress significant enough to warrant a release?** Yes, absolutely.
- **Is right now the best moment to cut it?** No. The natural, coherent release checkpoint is immediately after v1.36 ships, because that is when the dual-provider core contract becomes fully first-party, docs/verifiers align, and the release story is materially cleaner.

## Resolution

Resolved on 2026-05-07 during milestone-close triage. The release follow-up is
now an explicit next-step decision for post-archive work rather than an open
seed artifact blocking milestone closure:

- run the deterministic release-readiness pass after `v1.36` archival
- review the linked Release Please PR and version/changelog alignment
- publish the next linked Hex release per `RELEASING.md`
