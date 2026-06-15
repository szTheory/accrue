# Phase 187 Baseline

Only-forward baseline for v1.53 Admin UI Design-System Hardening.

Structured artifacts are canonical for Phase 187 and Phase 192 comparison:
baseline.cells.json and defects.ndjson are canonical. If this markdown disagrees
with those files, regenerate the markdown from the structured artifacts.

## Artifact Counts

- Baseline cells: 21076
- Covered cells: 2118
- Gap cells: 18958
- N/A cells: 0
- Defects: 743
- Evidence files referenced: 4250
- Harness failures: 0

## Coverage Summary

### By Coverage Status

| Status | Cells |
| --- | --- |
| covered | 2118 |
| gap | 18958 |

### By Surface Type

| Surface type | Cells |
| --- | --- |
| component | 8119 |
| component-group | 3880 |
| page-flow | 9077 |

### By Mode / Targeted Label

| Mode | Cells |
| --- | --- |
| chromium-desktop | 10488 |
| chromium-mobile | 10488 |
| targeted/targeted-1024 | 20 |
| targeted/targeted-1440 | 20 |
| targeted/targeted-320 | 20 |
| targeted/targeted-375 | 20 |
| targeted/targeted-768 | 20 |

### By Theme

| Theme | Cells |
| --- | --- |
| dark | 10488 |
| light | 10588 |

### By State

| State | Cells |
| --- | --- |
| default-populated | 2500 |
| disabled-readonly | 1392 |
| disconnected-reconnecting | 1392 |
| empty | 2400 |
| error | 2400 |
| interactive-open | 2400 |
| loading | 2400 |
| long-content | 2400 |
| overflow | 2400 |
| permission-denied | 1392 |

## Severity-Ranked Defect Ledger

### By Severity

| Severity | Defects |
| --- | --- |
| high | 96 |
| low | 413 |
| medium | 234 |

### By Owner Phase

| Owner phase | Defects |
| --- | --- |
| 189 | 282 |
| 190 | 280 |
| 191 | 181 |

### Top Defects

| ID | Severity | Owner | Surface | Dimension | Actual |
| --- | --- | --- | --- | --- | --- |
| AX187-001 | high | 190 | detail-header/metadata/actions | token-compliance | Surface was not visible in the DOM during static capture. |
| AX187-002 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Surface was not visible in the DOM during static capture. |
| AX187-003 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Surface was not visible in the DOM during static capture. |
| AX187-004 | high | 190 | detail-header/metadata/actions | state-coverage | Surface was not visible in the DOM during static capture. |
| AX187-005 | high | 190 | detail-header/metadata/actions | responsive-mobile-first | Surface was not visible in the DOM during static capture. |
| AX187-006 | high | 190 | detail-header/metadata/actions | contrast | Surface was not visible in the DOM during static capture. |
| AX187-007 | high | 190 | detail-header/metadata/actions | focus-semantics | Surface was not visible in the DOM during static capture. |
| AX187-008 | high | 190 | detail-header/metadata/actions | brand-expression | Surface was not visible in the DOM during static capture. |
| AX187-009 | high | 190 | detail-header/metadata/actions | motion | Surface was not visible in the DOM during static capture. |
| AX187-010 | high | 190 | detail-header/metadata/actions | reuse-dry | Surface was not visible in the DOM during static capture. |
| AX187-011 | high | 190 | detail-header/metadata/actions | interaction-integrity | Surface was not visible in the DOM during static capture. |
| AX187-012 | high | 190 | detail-header/metadata/actions | microcopy | Surface was not visible in the DOM during static capture. |
| AX187-013 | high | 190 | detail-header/metadata/actions | token-compliance | Surface was not visible in the DOM during static capture. |
| AX187-014 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Surface was not visible in the DOM during static capture. |
| AX187-015 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Surface was not visible in the DOM during static capture. |
| AX187-016 | high | 190 | detail-header/metadata/actions | state-coverage | Surface was not visible in the DOM during static capture. |
| AX187-017 | high | 190 | detail-header/metadata/actions | responsive-mobile-first | Surface was not visible in the DOM during static capture. |
| AX187-018 | high | 190 | detail-header/metadata/actions | contrast | Surface was not visible in the DOM during static capture. |
| AX187-019 | high | 190 | detail-header/metadata/actions | focus-semantics | Surface was not visible in the DOM during static capture. |
| AX187-020 | high | 190 | detail-header/metadata/actions | brand-expression | Surface was not visible in the DOM during static capture. |
| AX187-021 | high | 190 | detail-header/metadata/actions | motion | Surface was not visible in the DOM during static capture. |
| AX187-022 | high | 190 | detail-header/metadata/actions | reuse-dry | Surface was not visible in the DOM during static capture. |
| AX187-023 | high | 190 | detail-header/metadata/actions | interaction-integrity | Surface was not visible in the DOM during static capture. |
| AX187-024 | high | 190 | detail-header/metadata/actions | microcopy | Surface was not visible in the DOM during static capture. |
| AX187-025 | high | 190 | detail-header/metadata/actions | token-compliance | Awaiting Phase 187 evidence capture. |
| AX187-026 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Awaiting Phase 187 evidence capture. |
| AX187-027 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Awaiting Phase 187 evidence capture. |
| AX187-028 | high | 190 | detail-header/metadata/actions | state-coverage | Awaiting Phase 187 evidence capture. |
| AX187-029 | high | 190 | detail-header/metadata/actions | responsive-mobile-first | Awaiting Phase 187 evidence capture. |
| AX187-030 | high | 190 | detail-header/metadata/actions | contrast | Awaiting Phase 187 evidence capture. |
| AX187-031 | high | 190 | detail-header/metadata/actions | focus-semantics | Awaiting Phase 187 evidence capture. |
| AX187-032 | high | 190 | detail-header/metadata/actions | brand-expression | Awaiting Phase 187 evidence capture. |
| AX187-033 | high | 190 | detail-header/metadata/actions | motion | Awaiting Phase 187 evidence capture. |
| AX187-034 | high | 190 | detail-header/metadata/actions | reuse-dry | Awaiting Phase 187 evidence capture. |
| AX187-035 | high | 190 | detail-header/metadata/actions | interaction-integrity | Awaiting Phase 187 evidence capture. |
| AX187-036 | high | 190 | detail-header/metadata/actions | microcopy | Awaiting Phase 187 evidence capture. |
| AX187-037 | high | 190 | detail-header/metadata/actions | token-compliance | Awaiting Phase 187 evidence capture. |
| AX187-038 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Awaiting Phase 187 evidence capture. |
| AX187-039 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Awaiting Phase 187 evidence capture. |
| AX187-040 | high | 190 | detail-header/metadata/actions | state-coverage | Awaiting Phase 187 evidence capture. |

## Outputs

- `baseline.cells.json` - schema-shaped baseline matrix cells
- `defects.ndjson` - severity-ranked defect ledger rows
- `artifacts.manifest.json` - evidence references, checksums, observations, and harness failures

## Phase 192 Rerun Commands

```bash
cd accrue_admin
npm run e2e -- e2e/admin-baseline.spec.js
npm run e2e -- e2e/admin-interactions.spec.js
npm run e2e:a11y
npm run score-visuals
npm run baseline:artifacts
npm run baseline:parse
```

Generated by `npm run baseline:artifacts`.
