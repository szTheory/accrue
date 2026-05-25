---
phase: 130-provider-honesty-fake-lane-proof-example-host-wiring
plan: "02"
subsystem: dunning-docs
tags: [dunning, provider-honesty, drift-gate, docs, guide]
dependency_graph:
  requires: [130-01]
  provides: [dunning-guide, guide-drift-pins]
  affects:
    - accrue/guides/dunning.md
    - scripts/ci/verify_processor_support_matrix.sh
tech_stack:
  added: []
  patterns: [require_substring_in_guide-drift-pin, missing-file-guard, cross-reference-guide-pattern]
key_files:
  created:
    - accrue/guides/dunning.md
  modified:
    - scripts/ci/verify_processor_support_matrix.sh
decisions:
  - dunning.md opens with a lifecycle_semantics.md cross-reference (clones entitlements.md framing) — no past_due/unpaid/grace truth re-derived in this guide
  - Four verbatim label pins in the guide match the locked vocabulary from Plan 01: local-identical, native (Smart Retries), unsupported (clock-driven only), zero processor calls
  - require_substring_in_guide clones the existing require_substring helper (same pattern, different target file) — no duplication of the helper definition
  - guide variable + missing-file guard added alongside the matrix guard at the top of the script, mirroring the existing guard pattern exactly
  - Guide-side pins placed after the existing dunning matrix pins from Plan 01, before the negative divergence guards — consistent with the script's section ordering
metrics:
  duration: 3min
  completed_date: "2026-05-25"
  tasks: 2
  files: 2
---

# Phase 130 Plan 02: Provider-Honest Dunning Guide + Guide-Side Drift Pins Summary

Provider-honest dunning guide (`accrue/guides/dunning.md`) written with per-provider story (campaign is local-identical/zero-processor-calls; Stripe has native Smart Retries; Braintree is unsupported/clock-driven-only/not-retry-aligned; Fake is the deterministic CI proof lane), over-email warning blockquote, Stripe Test Clocks advisory note, and lifecycle cross-reference; drift gate extended with four guide-side pins and a missing-file guard.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write accrue/guides/dunning.md (provider-honest, cross-referenced) | 7201fe87 | accrue/guides/dunning.md |
| 2 | Add guide-side drift pins to verify_processor_support_matrix.sh | 9f0a7879 | scripts/ci/verify_processor_support_matrix.sh |

## Key Decisions

**1. Guide opens with lifecycle cross-reference (clone of entitlements.md framing):**
The guide's first paragraph points to `lifecycle_semantics.md#past_due` for lifecycle truth (past_due/unpaid/grace) and declares "use this guide for per-provider behavior and configuration." No lifecycle truth is re-derived here.

**2. Campaign section states convergence claim first, then diverges per-provider:**
The overview section establishes the `local-identical` / `zero processor calls` / `all first-party` convergence claim before the per-provider section. The per-provider section then documents where things diverge: Stripe's Smart Retries run beneath the campaign; Braintree has no retry overlay and is `not retry-aligned`; Fake is the deterministic CI lane. This ordering matches the locked label vocabulary from Plan 01 exactly.

**3. `require_substring_in_guide` helper is a clone of `require_substring`, not a refactor:**
The two helpers have different targets (`$guide` vs `$matrix`). Sharing a target-parameterized helper would require restructuring the whole script; cloning is the minimal-change approach that mirrors the existing pattern.

**4. Guide-side pins are load-bearing per-provider claims only (D-08 minimal-pin principle):**
Four pins: `local-identical`, `native (Smart Retries)`, `unsupported (clock-driven only)`, `zero processor calls`. Not every sentence in the guide is pinned — only the labels that code and the published guide both claim.

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Documentation and drift-gate additions only. T-130-02 (guide drift) mitigated by guide-side pins + missing-file guard as planned.

## Known Stubs

None.

## Self-Check: PASSED

- `accrue/guides/dunning.md` — exists, 193 lines (> 60), contains all four pinned substrings, lifecycle_semantics.md cross-reference, Warning blockquote, Stripe Test Clocks note, [0, 5, 12] default, not-retry-aligned for Braintree
- `scripts/ci/verify_processor_support_matrix.sh` — exits 0; defines `require_substring_in_guide` (5 occurrences: 1 definition + 4 call sites); `guide` variable and missing-file guard present
- Mutation check 1 (remove label from guide): exits 1 with "guide missing dunning guide Braintree not-retry-aligned label"
- Mutation check 2 (remove guide file): exits 1 with "missing guide .../accrue/guides/dunning.md"
- Task 1 commit 7201fe87 — verified in git log
- Task 2 commit 9f0a7879 — verified in git log
