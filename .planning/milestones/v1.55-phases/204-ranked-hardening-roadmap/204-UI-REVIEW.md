# Phase 204 - UI Review

**Audited:** 2026-07-03
**Baseline:** `204-UI-SPEC.md` Markdown information-design contract
**Screenshots:** not captured (Phase 204 is a Markdown planning artifact; no 200 dev server at ports 3000 or 5173, and port 8080 returned non-200/301)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Required labels and measured voice are present, but several deferrals lack explicit reopen thresholds. |
| 2. Visuals | 2/4 | The scan path exists, but the first decision table is too wide to scan comfortably. |
| 3. Color / Information Signaling | 3/4 | No color misuse, but evidence cues are plain text instead of navigable Markdown links. |
| 4. Typography | 4/4 | Semantic Markdown heading hierarchy and label treatment match the contract. |
| 5. Spacing / Markdown Readability | 2/4 | Cards and table rows are mechanically structured but visually dense in rendered Markdown. |
| 6. Experience Design | 3/4 | Boundary communication is strong, but deferral visibility is uneven. |

**Overall: 17/24**

---

## Top 3 Priority Fixes

1. **Compress the Ranked Top 10 table** - the maintainer's first scan surface requires horizontal scanning and overloaded cells - shorten each table cell to a phrase, keep evidence/detail in cards, and target sub-300-character row lines while preserving the exact required columns.
2. **Make deferral reopen thresholds explicit** - future planners cannot consistently tell when deferred work should come back - rewrite each deferral as `Deferred until/unless {specific evidence threshold}`.
3. **Improve evidence navigation** - Phase evidence is cited but not linkable - convert Phase 201/202/203 evidence mentions in ranked rows and card source lines into local Markdown links or concise footnote references.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

PASS: The required section labels from `204-UI-SPEC.md:124-133` are present in the roadmap at `204-HARDENING-ROADMAP.md:8`, `:21`, `:31`, `:46`, `:158`, `:225`, `:240`, and `:249`.

PASS: Roadmap prose follows the requested measured, mechanism-led voice. The broad-claim scan found no prohibited claim terms in `204-HARDENING-ROADMAP.md`; the only matches appeared in `204-UI-SPEC.md:139`, where they are listed as terms to avoid.

WARNING: Deferral copy only partially satisfies `204-UI-SPEC.md:55`, which requires the risk threshold that would reopen deferred work. `204-HARDENING-ROADMAP.md:228`, `:231`, `:232`, `:234`, `:236`, and `:238` state a deferral but do not give a concrete reopen condition such as adoption failure, support volume, accessibility defect, production incident, or measured maintenance cost.

### Pillar 2: Visuals (2/4)

PASS: The scan path follows `204-UI-SPEC.md:50`: `How to read this roadmap`, `Ranking method`, and `Ranked Top 10` appear before `Implementation Cards` at `204-HARDENING-ROADMAP.md:8`, `:21`, `:31`, and `:46`.

WARNING: The Ranked Top 10 table violates the compact first-decision-surface intent in `204-UI-SPEC.md:51`. Measured row lengths for `204-HARDENING-ROADMAP.md:35-44` are 508-595 characters, with max cell lengths of 128-173 characters. This makes the table mechanically correct but hard to read in common Markdown renderers.

WARNING: The implementation-card hierarchy exists, but the visual rhythm inside each card is dense. For example, `204-HARDENING-ROADMAP.md:50-57` is eight consecutive label/value lines with no bullets or vertical grouping; the same pattern repeats across all ten cards.

### Pillar 3: Color / Information Signaling (3/4)

PASS: The roadmap does not add raw HTML, inline styles, hardcoded colors, RGB values, or CSS-like color declarations, matching `204-UI-SPEC.md:99-110`.

WARNING: The information-signaling equivalent of accent color is underused. `204-UI-SPEC.md:107-110` reserves accent treatment for evidence links, local path links, requirement IDs, and anchors, but the roadmap has 38 Phase 201/202/203 text mentions and 0 Markdown links. Evidence is present, but it is not visually or interactively navigable.

### Pillar 4: Typography (4/4)

PASS: The artifact uses semantic Markdown only: one document title at `204-HARDENING-ROADMAP.md:1`, `##` sections for the required roadmap blocks, and `###` headings for ranks and follow-up milestones.

PASS: Card labels use bold label text such as `**Source evidence:**`, matching the label role in `204-UI-SPEC.md:90-95`. No raw HTML, inline font styling, custom font stack, or decorative typographic treatment was found.

### Pillar 5: Spacing / Markdown Readability (2/4)

PASS: The artifact uses semantic Markdown spacing and avoids custom layout/CSS, which matches the no-custom-CSS constraint in `204-UI-SPEC.md:75` and the typography guidance at `204-UI-SPEC.md:81`.

WARNING: The table and cards are too dense for the declared scan path. The first table rows at `204-HARDENING-ROADMAP.md:35-44` are all over 500 characters, and the ten cards use consecutive field lines rather than bullets or blank-line groupings. This undermines the `204-UI-SPEC.md:51-52` requirement that the table stay compact and cards stay readable.

WARNING: Follow-up milestone sections are more readable than the rank cards because they use short paragraphs and bullets at `204-HARDENING-ROADMAP.md:160-223`. The card section should adopt a similarly scannable structure while preserving the required field order.

### Pillar 6: Experience Design (3/4)

PASS: Boundary communication is strong. The roadmap states the artifact is roadmap-only at `204-HARDENING-ROADMAP.md:6`, repeats no-change surfaces at `:251`, and closes with explicit handoff/no-change language at `:253-262`.

PASS: Verification artifacts align with the user-facing boundary: `204-VERIFICATION.md:31-42` verifies the ranked evidence, structure, and no-implementation boundary; `204-VALIDATION.md:23-27` explains why runtime UI tests are not applicable.

WARNING: Deferral visibility is not consistently action-guiding. `204-HARDENING-ROADMAP.md:227-238` lists the required deferral categories, but several rows stop at "deferred" without a specific future signal. This degrades future planning because a later phase may reopen polish work based on preference rather than evidence.

---

## Files Audited

- `.planning/phases/204-ranked-hardening-roadmap/204-01-PLAN.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-01-SUMMARY.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-VERIFICATION.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-VALIDATION.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-SECURITY.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-UI-SPEC.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-CONTEXT.md`
- `.planning/phases/204-ranked-hardening-roadmap/204-HARDENING-ROADMAP.md`
- `CLAUDE.md`

