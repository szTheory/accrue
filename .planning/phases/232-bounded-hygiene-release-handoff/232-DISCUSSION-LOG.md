# Phase 232: Bounded Hygiene & Release Handoff - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-16
**Phase:** 232-bounded-hygiene-release-handoff
**Areas discussed:** Remote-ref cleanup scope, window-disposition bucketing, parked/deferred item scope

---

## Remote-ref cleanup scope (HYG-01)

Presented after measuring: 4 origin branches fully merged into `origin/main`
(`fix/chimeway-opaque-recipient-release`, `fix/getfluent-1.5.1`, `fix/release-otp-28-1`,
`release-please--branches--main`) and 4 not merged (`fix/chimeway-opaque-recipient`,
`fix/release-boot-env-resolver`, `gsd/phase-225-required-lane-signal-repair`,
`phase-226-baseline-5da8e6b88735`). 0 open PRs.

| Option | Description | Selected |
|--------|-------------|----------|
| Classify only, delete nothing | Commit the classification HYG-01 requires; maintainer runs any deletion later from the committed list. Zero irreversible public action inside the phase. | ✓ |
| Delete the 4 merged, classify the rest | Authorize `git push origin --delete` for the branches provably contained in `origin/main`. | |
| Delete merged + unmerged after archiving tags | Archive-tag each unmerged branch, then delete all eight. | |

**User's choice:** Classify only, delete nothing.
**Notes:** Recorded as D-47. Encoded structurally rather than as an intention — the hygiene
verifier constrains every `remote_branch` row to `disposition in {retained, superseded}` with
`authorization_required: false`, so the artifact **cannot express** a remote-branch deletion.

---

## Window-disposition bucketing (CR-01 follow-through)

Presented after CR-01 (`disposition: "fixed"` requires `state: "proved"`) made two of the
renderer's four buckets unreachable, collapsing waived-and-failed and waived-and-never-run
into one undifferentiated section.

| Option | Description | Selected |
|--------|-------------|----------|
| Sub-split waived by state | Group waived rows by their own state so failing-on-the-merits is visually distinct from never-run. Requires re-rendering committed phase-231 evidence. | ✓ |
| Leave as-is, document the dead branches | Keep renderer and committed evidence byte-identical; comment that the branches are defensive-only. | |
| Drop the dead branches entirely | Delete the unreachable branches so code matches the enforced invariant. | |

**User's choice:** Sub-split waived by state.
**Notes:** Recorded as D-13 through D-20. Research surfaced a third legal case the framing had
missed — `waived/proved` is legal today and is a real ledger/reality mismatch, so the split is
three-way, not two-way. Re-rendering 231's artifact was resolved in favour of regeneration
(D-20) on the reproducibility argument: the JSON is the evidence of record and the Markdown is
a projection, so freezing the Markdown while the renderer changes destroys `render(json) == md`,
which is the artifact's only source of authority.

---

## Parked and deferred item scope

| Option | Description | Selected |
|--------|-------------|----------|
| Admin UI ratchet guardrails disposition | Record an explicit disposition so the parked v1.56 gate stops polluting release-gate signal. | ✓ |
| `verify_ci_baseline.mjs` isMainModule guard | Pre-existing INFO; `node --test` runs its CLI and exits 1. | ✓ |
| release-please `commit-search-depth` pin | ~492 commits against a default of 500; silent truncation risk. | ✓ |
| Neither — keep 232 to its five requirements | HYG-01/02/03 + REL-04/05 only. | ✓ |

**User's choice:** All four selected, with a freeform instruction to research each deeply via
subagents — pros/cons/tradeoffs, what is idiomatic for Elixir/Phoenix libraries, lessons from
comparable successful projects in and outside the ecosystem, developer ergonomics, and a single
coherent recommendation set requiring no further deliberation.

**Notes:** The contradictory selection (all three items *and* "neither") was resolved by the
freeform text, which asked for research rather than a scope cut. Four parallel research agents
were run; every load-bearing claim was independently re-verified against the repository before
being recorded. Three of the four premises the questions were built on turned out to be wrong,
and the corrections are recorded as decisions:

- The candidate was **not** simply stale — it is the only line carrying the published 1.5.1
  release state (D-02). Re-cutting from the milestone tip alone would have regressed two
  published releases.
- `verify_ci_baseline.mjs` was **not** an isolated INFO finding — 16 of 42 verifier scripts
  fail the same way, and 14 guards use idioms that fail **silent-green** on a path containing
  a space (D-27, D-28).
- The changelog-noise and `commit-search-depth` premises were both wrong — filtering is already
  on by default (next release is 14 bullets, not 153) and the measured commit walk is 310/500,
  not 492/500 (D-35, D-36).

Two findings arrived that no question had anticipated: a hardcoded fabricated-PASS block in
`ci.yml` (D-24) and a degraded phase-200 shadow directory silently overriding the committed
archive on every local verifier run (D-51).

A `release-please release-pr --dry-run` was executed against the public repository during
research (read-only; exit 0; no branch, PR, tag, or release created). It produced the REL-05
evidence recorded in D-39.

---

## Claude's Discretion

- Section ordering, microcopy, and table shapes inside the rendered artifacts, provided the
  vocabulary stays `disposition` × `state` and "parked" remains a CI-lane presentation label,
  never a schema value.
- Whether the hygiene triad and the window-disposition triad share helper modules.
- Plan and wave decomposition.

## Deferred Ideas

- Commitlint with a billing-domain `scope-enum` banning numeric/phase-ID scopes, wired into the
  GSD commit contract — the real long-term changelog fix, but a new capability affecting every
  future commit.
- A curated per-minor Highlights slot above the generated changelog ledger.
- Standardizing `--fixtures` vs `--self-test`, adding `--help`, and migrating hand-rolled argv
  to `parseArgs` with `strict: true`.
- Renaming the two adopter-named refs; deleting local `main`; the remote deletions themselves.
- The orphaned `CapabilityReportTests.swift`.
- Remaining 231-REVIEW WARNING/INFO items not in scope.
- Package publication — outside v1.62 entirely.
