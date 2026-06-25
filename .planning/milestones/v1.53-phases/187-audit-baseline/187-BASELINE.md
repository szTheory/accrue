# Phase 187 Baseline

Only-forward baseline for v1.53 Admin UI Design-System Hardening.

Structured artifacts are canonical for Phase 187 and Phase 192 comparison:
baseline.cells.json and defects.ndjson are canonical. If this markdown disagrees
with those files, regenerate the markdown from the structured artifacts.

## Artifact Counts

- Baseline cells: 21276
- Covered cells: 4303
- Gap cells: 16967
- N/A cells: 6
- Defects: 800
- Evidence files referenced: 4248
- Harness failures: 0

## Coverage Summary

### By Coverage Status

| Status | Cells |
| --- | --- |
| covered | 4303 |
| gap | 16967 |
| n/a | 6 |

### By Surface Type

| Surface type | Cells |
| --- | --- |
| component | 8174 |
| component-group | 3920 |
| page-flow | 9182 |

### By Mode / Targeted Label

| Mode | Cells |
| --- | --- |
| chromium-desktop | 10538 |
| chromium-mobile | 10538 |
| targeted/targeted-1024 | 40 |
| targeted/targeted-1440 | 40 |
| targeted/targeted-320 | 40 |
| targeted/targeted-375 | 40 |
| targeted/targeted-768 | 40 |

### By Theme

| Theme | Cells |
| --- | --- |
| dark | 10488 |
| light | 10788 |

### By State

| State | Cells |
| --- | --- |
| default-populated | 2612 |
| disabled-readonly | 1398 |
| disconnected-reconnecting | 1394 |
| empty | 2402 |
| error | 2402 |
| interactive-open | 2460 |
| loading | 2402 |
| long-content | 2402 |
| overflow | 2410 |
| permission-denied | 1394 |

## Severity-Ranked Defect Ledger

### By Severity

| Severity | Defects |
| --- | --- |
| high | 118 |
| low | 353 |
| medium | 329 |

### By Owner Phase

| Owner phase | Defects |
| --- | --- |
| 189 | 342 |
| 190 | 280 |
| 191 | 178 |

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
| AX187-025 | high | 190 | detail-header/metadata/actions | token-compliance | Surface was not visible in the DOM during static capture. |
| AX187-026 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Surface was not visible in the DOM during static capture. |
| AX187-027 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Surface was not visible in the DOM during static capture. |
| AX187-028 | high | 190 | detail-header/metadata/actions | state-coverage | Surface was not visible in the DOM during static capture. |
| AX187-029 | high | 190 | detail-header/metadata/actions | responsive-mobile-first | Surface was not visible in the DOM during static capture. |
| AX187-030 | high | 190 | detail-header/metadata/actions | contrast | Surface was not visible in the DOM during static capture. |
| AX187-031 | high | 190 | detail-header/metadata/actions | focus-semantics | Surface was not visible in the DOM during static capture. |
| AX187-032 | high | 190 | detail-header/metadata/actions | brand-expression | Surface was not visible in the DOM during static capture. |
| AX187-033 | high | 190 | detail-header/metadata/actions | motion | Surface was not visible in the DOM during static capture. |
| AX187-034 | high | 190 | detail-header/metadata/actions | reuse-dry | Surface was not visible in the DOM during static capture. |
| AX187-035 | high | 190 | detail-header/metadata/actions | interaction-integrity | Surface was not visible in the DOM during static capture. |
| AX187-036 | high | 190 | detail-header/metadata/actions | microcopy | Surface was not visible in the DOM during static capture. |
| AX187-037 | high | 190 | detail-header/metadata/actions | token-compliance | Surface was not visible in the DOM during static capture. |
| AX187-038 | high | 190 | detail-header/metadata/actions | visual-hierarchy | Surface was not visible in the DOM during static capture. |
| AX187-039 | high | 190 | detail-header/metadata/actions | spacing-rhythm | Surface was not visible in the DOM during static capture. |
| AX187-040 | high | 190 | detail-header/metadata/actions | state-coverage | Surface was not visible in the DOM during static capture. |

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
