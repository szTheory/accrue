---
quick_id: 260501-lfk
slug: repair-active-roadmap-md-for-v1-33-archi
date: 2026-05-01
status: complete
mode: quick
commit: 445c742
---

# Quick Task 260501-lfk: Summary

## What changed

`.planning/ROADMAP.md` repaired for the active v1.33 milestone:

**Removed (12 stale `### Phase NN` detail blocks for already-shipped phases — their authoritative detail now lives under per-milestone archives in `.planning/milestones/v1.X-phases/`):**

- Phase 24 (v1.5)
- Phases 59, 60, 61 (v1.16)
- Phases 62, 63, 64, 65 (v1.17)
- Phase 66 (v1.18)
- Phases 88, 89, 90 (v1.29)

The summary `<details>` collapses, milestone success criteria, and `## Progress` tables for each shipped milestone are untouched.

**Added** `## Phase Details` section under the active v1.33 milestone block, with `### Phase 101`–`### Phase 104` detail blocks copied verbatim from `.planning/milestones/v1.33-ROADMAP.md` (lines 11–47).

## Verification

```text
$ grep -nE '^### Phase (24|59|60|61|62|63|64|65|66|88|89|90):' .planning/ROADMAP.md
(no matches — good)

$ grep -nE '^### Phase 10[1-4]:' .planning/ROADMAP.md
67:### Phase 101: Accrue Portal Foundation & Checkout
78:### Phase 102: Coupon/Discount Mapping
87:### Phase 103: Metering Engine
96:### Phase 104: Connect Spike / Decision

$ grep -cE '^<details>$' .planning/ROADMAP.md
26
$ grep -cE '^</details>$' .planning/ROADMAP.md
26

# Progress tables unchanged
$ grep -cE '^\| 24\. Adoption proof hardening' .planning/ROADMAP.md
1
$ grep -cE '^\| 88\. Mailglass Foundation' .planning/ROADMAP.md
1
$ grep -cE '^\| 66\. Deferred UAT' .planning/ROADMAP.md
1
```

File size went from 1091 to 962 lines (net -129).

## Commits

- `445c742` — `docs(260501-lfk): repair active ROADMAP.md for v1.33` — the ROADMAP.md change.

## Status

complete
