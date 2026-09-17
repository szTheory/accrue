---
phase: 226-ci-baseline-proof-semantics
plan: "02"
subsystem: ci-evidence
tags: [github-actions, baseline, ndjson, deterministic-markdown]
requires: [schema-v1-ci-baseline-collector]
provides: [frozen-90-day-ci-baseline, action-first-critical-path-report]
affects: [227-critical-path]
tech_stack:
  added: []
  patterns: [paginated-actions-metadata, strict-allowlist, byte-reproducible-render]
key_files:
  created:
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson
    - .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
  modified:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/render_ci_baseline.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/schema-v1.json
    - .planning/phases/226-ci-baseline-proof-semantics/226-VALIDATION.md
decisions:
  - "Freeze exact fingerprint cohorts and label the current sample insufficient rather than mix unlike run topologies."
metrics:
  duration: "~35 minutes"
  completed: "2026-08-11"
  tasks_completed: 2
  files_changed: 6
status: complete
---

# Phase 226 Plan 02: CI Baseline Proof Summary

Frozen, privacy-safe 90-day Actions evidence with an action-first report that truthfully marks the comparable timing cohort insufficient.

## Completed Tasks

1. Collected 3,020 schema-v1 records from paginated Actions run and job metadata, retaining the Phase 225 repair boundary and reliability evidence while excluding raw forensic data.
2. Rendered and byte-verified the maintainer report with literal states, queue-versus-DAG timing, setup/cache facts, provider boundary, exclusions, immutable links, and reproduction commands.

## Verification

- `gh auth status && node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` — PASS
- `node scripts/ci/render_ci_baseline.mjs --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --out /tmp/226-CI-BASELINE-rendered.md && cmp /tmp/226-CI-BASELINE-rendered.md .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — PASS
- `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_ci_baseline.mjs --fixtures` — PASS

## Decisions Made

- Freeze exact fingerprint cohorts and label the sample `insufficient_sample` rather than broaden a timing cohort.
- Preserve run `31322443304` at SHA `ee940cf9e1f8` as the Phase 225 repair boundary, not as a replacement cohort.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical evidence completeness] Completed the live collector and renderer contracts**
- **Found during:** Task 1
- **Issue:** The Plan 01 engine did not paginate historical jobs, emit snapshot/cohort records, or provide the required action-first report detail.
- **Fix:** Added paginated read-only Actions collection, timing-safe normalization, strict snapshot schema, derived setup/cache facts, and deterministic report sections.
- **Files modified:** `scripts/ci/collect_ci_baseline.mjs`, `scripts/ci/render_ci_baseline.mjs`, `schema-v1.json`
- **Verification:** Fixture, live-record, and byte-render gates passed.
- **Commit:** c3828f1b, 011dfef7

**Total deviations:** 1 auto-fixed. **Impact:** The frozen evidence now satisfies BASE-01 without expanding CI topology or reading logs/artifact contents.

## Known Stubs

None.

## Self-Check: PASSED

- Frozen NDJSON and rendered Markdown exist.
- Task commits `c3828f1b` and `011dfef7` exist.
