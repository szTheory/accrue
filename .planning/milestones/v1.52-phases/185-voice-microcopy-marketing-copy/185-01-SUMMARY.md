---
phase: 185-voice-microcopy-marketing-copy
plan: "01"
subsystem: brandbook
tags:
  - voice
  - copy
  - brand
dependency_graph:
  requires:
    - 180-brand-audit-dna-lock (BRAND-DNA.md — ratified voice adjectives, Do/Don't, positioning)
  provides:
    - brandbook/voice.md (voice system constraint doc consumed by Plan 02 copy blocks and Phase 186 assembly)
  affects:
    - brandbook/ (new voice.md file added)
tech_stack:
  added: []
  patterns:
    - voice-as-constraint-document (voice.md is the constraint; copy.md copy blocks must satisfy it)
    - proof-led-claims (mechanism or named artifact, never adjective-led)
    - surface-dispatch-rule (tagline leads on-page; descriptor leads out-of-context/search-indexed)
key_files:
  created:
    - brandbook/voice.md
  modified: []
decisions:
  - "Tone slider anchors: Formal↔Casual=3, Precise↔Evocative=4 (per D-08)"
  - "Surface dispatch rule D-07 encoded as named IF/THEN rule in voice.md"
  - "Claims posture YES/NO table derives directly from D-10 exemplars"
  - "CTA canon per D-11: approved primaries Get started/Install; banned list includes Start free/Try it now/Get billing in minutes/exclamation marks/demo"
  - "Vocabulary avoid list names all four D-10 banned adjectives: production-grade, batteries-included, bank-grade, modern alternative"
metrics:
  duration: "94s"
  completed: "2026-06-14"
  tasks_completed: 1
  files_changed: 1
requirements_closed:
  - COPY-01
---

# Phase 185 Plan 01: Voice System Summary

One-liner: Voice system document encoding Brand DNA adjectives, tone sliders with per-surface deltas, surface dispatch rule, proof-led claims posture, and CTA canon into a single constraint file.

## What Was Built

`brandbook/voice.md` — a standalone writing constraint document (164 lines) that any writer or AI agent can open and apply without consulting other files. Contains all 7 required sections per the plan spec.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write brandbook/voice.md — Accrue voice system | c8eda550 | brandbook/voice.md |

## Verification Results

All 15 automated assertions passed:

- File exists: `brandbook/voice.md`
- All 7 required H2 sections present: Voice Principles, Do / Don't, Tone Sliders, Surface Dispatch Rule, Vocabulary, Claims Posture, CTAs
- Tone slider anchors present (Formal↔Casual=3, Precise↔Evocative=4)
- All 5 per-surface delta table rows present (HexDocs, README, Landing/marketing, Release notes, Error/empty-state)
- Surface dispatch rule present (search-indexed / out of context)
- All 4 D-10 banned adjectives named in Vocabulary/Avoid: production-grade, batteries-included, bank-grade, modern alternative
- Banned CTAs present: Start free, Try it now, Get billing in minutes
- Approved primary CTAs present: Get started, Install
- Line count: 164 (≤ 250 limit)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. This plan produces a complete constraint document; no placeholders or stubs exist.

## Threat Flags

None. This plan produces only static markdown prose in `brandbook/`. No executable code, network surface, user input, or data handling introduced.

## Self-Check: PASSED

- `brandbook/voice.md` exists: FOUND
- Commit c8eda550 exists: FOUND
- All 7 required H2 sections: FOUND
- Tone slider anchors (3, 4): FOUND
- Per-surface delta table (5 rows): FOUND
- Surface dispatch rule: FOUND
- Banned adjectives (4): FOUND
- Banned CTAs: FOUND
- Approved CTAs: FOUND
- Line count 164 ≤ 250: PASSED
