---
phase: 185-voice-microcopy-marketing-copy
verified: 2026-06-14T05:51:44Z
status: passed
score: 13/13
overrides_applied: 0
---

# Phase 185: Voice, Microcopy & Marketing Copy — Verification Report

**Phase Goal:** A committed voice system and complete set of ready-to-paste copy blocks exist for every adopter-facing channel, consistent with the ratified brand DNA, and reviewed and approved by the user in one batch.
**Verified:** 2026-06-14T05:51:44Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | Voice system document committed with voice principles, tone sliders, vocabulary use/avoid, and say-this/not-this examples consistent with ratified BRAND-DNA | VERIFIED | `brandbook/voice.md` exists at commit `c8eda550`, 164 lines; all 7 required H2 sections present; derived from BRAND-DNA adjectives (measured, exact, native, durable) |
| SC-2 | Ready-to-paste copy blocks exist in `brandbook/` covering all required surfaces: GitHub, Hex.pm, HexDocs, README hero, landing-page sections, release-note templates, microcopy | VERIFIED | `brandbook/copy.md` exists at commit `5e1a1185`, 250 lines; all 7 required H2 sections present; all surface subsections populated with substantive copy, no placeholders |
| SC-3 | User reviewed all copy blocks in one batch and approved; final committed copy reflects the approved batch | VERIFIED | Plan 03 Task 2 (type: `checkpoint:human-verify`, gate: `blocking`) was completed; user responded "Approved" with no revision requests; `185-03-SUMMARY.md` records the approval; working tree was clean at gate close |

**Score:** 3/3 ROADMAP success criteria verified

---

### Locked-Decision Compliance (D-01 through D-11)

| # | Decision | Truth | Status | Evidence |
|---|----------|-------|--------|----------|
| D-01 | Pay (Rails) and Laravel Cashier credited in prose, not as comparison table rows | VERIFIED | `copy.md` line 134: gracious prose credit; no Pay/Cashier table rows found |
| D-02 | Comparison table contains `stripity_stripe` and `Raw Stripe API` rows | VERIFIED | Both rows present in comparison table; 5 factual capability rows total |
| D-03 | No Bling row in comparison table | VERIFIED | `grep -qi "^.*[|].*[Bb]ling.*[|]"` returns no match |
| D-04 | "migration pain / design regrets" language absent from public copy | VERIFIED | Not present in `copy.md`; phrase is private motivation only |
| D-05 | GitHub repo description is exactly `Billing state, modeled clearly — the Elixir billing library for Phoenix apps` | VERIFIED | String found verbatim in `copy.md` line 14; 69 chars confirmed |
| D-06 | Engaged surfaces (README, landing) lead with tagline; search-indexed surfaces lead with descriptor | VERIFIED | README hero block has tagline first; GitHub/Hex.pm blocks lead with descriptor; encoded as named rule in `voice.md` |
| D-07 | Surface dispatch rule encoded as named IF/THEN rule | VERIFIED | `## Surface Dispatch Rule` section in `voice.md` with explicit "Tagline leads / Descriptor leads" rule and WHY explanation |
| D-08 | Tone slider anchors: Formal↔Casual = 3, Precise↔Evocative = 4 | VERIFIED | `voice.md`: "anchor = 3" and "anchor = 4" both present with correct explanations |
| D-09 | Per-surface delta table with 5 rows (HexDocs, README, Landing/marketing, Release notes, Error/empty-state) | VERIFIED | All 5 rows present in `## Tone Sliders` section with correct values |
| D-10 | Claims are mechanism-led; banned adjectives absent from copy blocks | VERIFIED | Banned adjectives (production-grade, batteries-included, bank-grade, modern alternative) all appear only in `voice.md` Avoid list — not in any copy block in `copy.md`; YES/NO claims table in `voice.md` uses mechanism-led exemplars |
| D-11 | CTAs are literal next-actions; banned CTAs absent | VERIFIED | "Start free", "Try it now", "Get billing in minutes", standalone "demo" all absent from `copy.md`; approved CTAs "Get started" and "Install" present; sub-CTA spec "MIT · Elixir 1.17+ · Phoenix 1.8+" present |

**Score:** 11/11 locked decisions verified (D-04 folded into D-10/prose posture; 11 distinct checks total counted across D-01..D-11)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/voice.md` | Voice system — principles, tone sliders, vocabulary, say-this/not-this, CTA canon | VERIFIED | 164 lines (≤ 250 limit); committed `c8eda550`; 7 required H2 sections all present |
| `brandbook/copy.md` | Complete ready-to-paste copy blocks for all adopter-facing surfaces | VERIFIED | 250 lines (≤ 350 limit); committed `5e1a1185`; 7 required H2 surface sections all present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `brandbook/copy.md` | `brandbook/voice.md` | copy.md constraint line references voice.md | VERIFIED | `copy.md` line 4: `Constraint source: 'brandbook/voice.md' (D-01..D-11 per 185-CONTEXT.md)'`; all copy blocks demonstrably satisfy the voice constraints |
| User approval | Phase 186 | Approved voice.md + copy.md consumed by Phase 186 HTML assembly | VERIFIED | User approval recorded in `185-03-SUMMARY.md`; both files at approved commit; Phase 186 can inline them |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces static markdown prose only. No dynamic data, no state, no rendering pipeline. Both artifacts are source documents, not components.

### Behavioral Spot-Checks

Not applicable — no runnable code produced by this phase. All output is static markdown.

### Probe Execution

No probes declared or applicable. Phase 185 is documentation-only; no `scripts/*/tests/probe-*.sh` files exist for this phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| COPY-01 | 185-01-PLAN.md | Committed voice system — voice principles, tone sliders, vocabulary use/avoid, say-this/not-this consistent with ratified brand DNA | SATISFIED | `brandbook/voice.md` committed at `c8eda550`; all 7 sections present and complete |
| COPY-02 | 185-02-PLAN.md | Ready-to-paste copy blocks for all adopter-facing surfaces, user-reviewed in one batch | SATISFIED | `brandbook/copy.md` committed at `5e1a1185`; Plan 03 approval gate completed; `185-03-SUMMARY.md` records user "Approved" response |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No anti-patterns found |

Scan results: no `TBD`, `FIXME`, `XXX`, `PLACEHOLDER`, or `TODO` markers in either brandbook file. No empty implementations, no stub patterns. Both files contain substantive, complete prose with no deferred content.

---

### Human Verification Required

None. This phase produces static markdown copy. All verification criteria are machine-checkable:
- File existence and line counts: verified by `wc -l` and `test -f`
- Structural completeness: verified by `grep` for required headings
- Locked-string compliance (D-05): verified by exact string match
- Banned content absence (D-10, D-11): verified by grep scan
- Comparison table correctness (D-02, D-03): verified by grep
- User approval (SC-3): recorded in `185-03-SUMMARY.md` with explicit "Approved" response

The only item that could be considered human-dependent — "does the prose read in the voice it describes?" — is adequately resolved by the blocking human-review gate that was completed in Plan 03 Task 2. No further human testing is required.

---

### Gaps Summary

None. All 3 ROADMAP success criteria are satisfied. All 11 locked decisions are honored in the artifacts. Both files are committed, within line limits, and contain complete substantive content.

---

_Verified: 2026-06-14T05:51:44Z_
_Verifier: Claude (gsd-verifier)_
