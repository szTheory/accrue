---
quick_id: 260501-lfk
slug: repair-active-roadmap-md-for-v1-33-archi
date: 2026-05-01
status: pending
mode: quick
---

# Quick Task 260501-lfk: Repair active ROADMAP.md for v1.33

## Description

Repair `.planning/ROADMAP.md` to match the active v1.33 milestone:

1. **Archive stale `### Phase NN` detail blocks** that are residue from already-shipped milestones. The summary `<details>` blocks (with their tables) stay; only the per-phase `### Phase NN` heading + body sub-sections are removed, since each shipped phase's authoritative detail now lives under `.planning/milestones/v1.X-phases/`.
   - Phase 24 (under v1.5 `<details>`)
   - Phases 59–61 (under v1.16 `<details>`)
   - Phases 62–65 (under v1.17 `<details>`)
   - Phase 66 (under v1.18 `<details>`)
   - Phases 88–90 (under v1.29 `<details>`)
2. **Add Phase 101–104 detail blocks** under the active v1.33 section, copied verbatim from `.planning/milestones/v1.33-ROADMAP.md` (lines 11–47, the `## Phase Details` section). They are inserted between the milestone success criteria block (line 64) and the `## Phases` heading (line 65) that opens the archived prior-milestone collapses.

## Files

- `.planning/ROADMAP.md` (edited in place)

## Action

Use `Edit` with exact-match strings for each of the 12 removals + 1 insertion. No reordering of unrelated sections, no edits to the `## Progress` tables (which already correctly list shipped phases by milestone), no edits to phase artifacts under `.planning/milestones/`.

## Verify

```bash
# All targeted ### Phase blocks are gone from active ROADMAP.md
! grep -E '^### Phase (24|59|60|61|62|63|64|65|66|88|89|90):' .planning/ROADMAP.md

# Phase 101-104 detail blocks exist in active ROADMAP.md
grep -c '^### Phase 10[1-4]:' .planning/ROADMAP.md  # expect 4

# v1.33 anchor still intact
grep -n '^## v1.33 Braintree Full Maturity$' .planning/ROADMAP.md  # expect 1 hit

# Progress tables still mention shipped phases (untouched)
grep -c '^| 24\. Adoption proof hardening' .planning/ROADMAP.md  # expect 1
grep -c '^| 88\. Mailglass Foundation' .planning/ROADMAP.md      # expect 1
```

## Done

- All 12 stale `### Phase NN` blocks removed from active ROADMAP.md
- 4 new `### Phase 10N` detail blocks inserted under active v1.33 section, content matching `.planning/milestones/v1.33-ROADMAP.md`
- File is well-formed Markdown (no orphan `<details>` opens, no orphan blank-line runs > 2)
