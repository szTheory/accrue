---
phase: 185-voice-microcopy-marketing-copy
plan: "02"
subsystem: brandbook
tags:
  - copy
  - brand
  - marketing
dependency_graph:
  requires:
    - 185-01 (brandbook/voice.md — voice constraint doc authored in Wave 1 sibling)
    - 180-brand-audit-dna-lock (BRAND-DNA.md — ratified voice adjectives, positioning)
  provides:
    - brandbook/copy.md (complete set of ready-to-paste copy blocks for every adopter-facing surface)
  affects:
    - brandbook/ (new copy.md file added)
tech_stack:
  added: []
  patterns:
    - surface-dispatch-rule (D-07: tagline leads on-page; descriptor leads search-indexed/out-of-context)
    - proof-led-claims (mechanism or named artifact; no adjective-led claims per D-10)
    - comparison-gracious-credit (Pay/Cashier in prose, not table rows per D-01)
    - comparison-table-factual-only (stripity_stripe + Raw Stripe API; no Bling per D-02/D-03)
    - microcopy-register (Precise=5 / Formal=3 for error/empty/success states per D-09)
key_files:
  created:
    - brandbook/copy.md
  modified: []
decisions:
  - "D-05 exact GitHub repo description string used verbatim: 'Billing state, modeled clearly — the Elixir billing library for Phoenix apps'"
  - "Hex.pm description leads with indexed category noun + feature noun series (≤ 300 chars)"
  - "Comparison table: stripity_stripe + Raw Stripe API only; no Bling row (D-02/D-03)"
  - "Pay and Laravel Cashier credited in comparison prose, not table rows (D-01)"
  - "Landing page tone: Casual=2 / Precise=3 per D-09 surface-dispatch table"
  - "Microcopy tone: Precise=5 / Formal=3 per D-09; no apologetic softening"
metrics:
  duration: "119s"
  completed: "2026-06-14"
  tasks_completed: 1
  files_changed: 1
requirements_closed:
  - COPY-02
---

# Phase 185 Plan 02: Copy Blocks Summary

One-liner: Complete set of ready-to-paste copy blocks for all adopter-facing surfaces — GitHub, Hex.pm, HexDocs, README, landing page, release notes, and microcopy — all mechanism-led and D-01..D-11 compliant.

## What Was Built

`brandbook/copy.md` — 250-line standalone markdown file organized by surface. Contains all 7 required sections with copy blocks that are D-01..D-11 compliant and voice.md constraint-satisfying. Phase 186 will inline this file into the HTML brand book.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write brandbook/copy.md — all copy blocks | 5e1a1185 | brandbook/copy.md |

## Verification Results

All 14 automated assertions passed:

- File exists: `brandbook/copy.md`
- All 7 required H2 sections present: GitHub, Hex.pm, HexDocs, README Hero, Landing Page, Release Notes, Microcopy
- Exact D-05 locked GitHub repo description string present verbatim
- stripity_stripe row present in comparison table (D-02)
- Raw Stripe API row present in comparison table (D-02)
- No Bling table row (D-03)
- Pay and Laravel Cashier credited in prose (D-01)
- No banned adjectives from D-10: production-grade, batteries-included, bank-grade, modern alternative
- No banned CTAs from D-11: Start free, Try it now, Get billing in minutes, demo
- Approved primary CTA present: "Get started"
- Sub-CTA spec string present: "MIT · Elixir 1.17+ · Phoenix 1.8+"
- Microcopy sections present: error states (6 examples), empty states (4), success states (4)
- Release note template present with Added/Fixed/Changed structure
- Line count: 250 (≤ 350 limit)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All 7 sections contain complete copy blocks; no placeholders or stubs exist.

## Threat Flags

None. This plan produces only static markdown prose in `brandbook/`. No executable code, network surface, user input, or data handling introduced.

## Self-Check: PASSED

- `brandbook/copy.md` exists: FOUND
- Commit 5e1a1185 exists: FOUND
- All 7 required H2 sections: FOUND
- Exact D-05 GitHub description string: FOUND
- stripity_stripe + Raw Stripe API rows: FOUND
- No Bling table row: CONFIRMED
- Pay/Cashier credited in prose: FOUND
- No banned adjectives (D-10): CONFIRMED
- No banned CTAs (D-11): CONFIRMED
- Sub-CTA spec string: FOUND
- Microcopy error/empty/success states: FOUND
- Release note template: FOUND
- Line count 250 ≤ 350: PASSED
