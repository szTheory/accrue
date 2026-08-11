---
phase: 226-ci-baseline-proof-semantics
plan: "01"
subsystem: ci-evidence
tags: [node, github-actions, ndjson, privacy, deterministic-fixtures]
requires: []
provides: [schema-v1-ci-baseline-collector, deterministic-cohort-semantics]
affects: [226-02, 227-critical-path]
tech_stack:
  added: []
  patterns: [dependency-free-esm, strict-record-allowlists, raw-and-derived-facts]
key_files:
  created:
    - scripts/ci/collect_ci_baseline.mjs
    - scripts/ci/render_ci_baseline.mjs
    - scripts/ci/verify_ci_baseline.mjs
    - .planning/phases/226-ci-baseline-proof-semantics/schema-v1.json
    - .planning/phases/226-ci-baseline-proof-semantics/fixtures/ci-baseline-cases.json
  modified: []
decisions:
  - "Use a strict schema-v1 allowlist and branch classes so persisted records cannot contain raw Actions metadata."
  - "Use first-attempt full-CI successes only for cohort percentiles; retain failed, cancelled, skipped, and rerun facts in reliability evidence."
metrics:
  duration: "~16 minutes"
  completed: "2026-08-11"
  tasks_completed: 2
  files_created: 5
status: complete
coverage:
  - id: BASE-01-tracer
    description: "Sanitized Actions metadata is transformed into validated NDJSON and deterministic Markdown."
    human_judgment: false
    ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
    status: pass
  - id: BASE-01-cohort-semantics
    description: "Fixtures prove cohort isolation, sample thresholds, rerun deduplication, and failure grouping."
    human_judgment: false
    ref: "node scripts/ci/verify_ci_baseline.mjs --fixtures"
    status: pass
---

# Phase 226 Plan 01: CI Baseline Proof Semantics Summary

Dependency-free CI evidence engine that converts allowlisted Actions facts into privacy-safe NDJSON and deterministic maintainer Markdown, with proven cohort and reliability semantics.

## Completed Tasks

1. Built the successful-run tracer with strict schema-v1 validation, immutable evidence URLs, SHA truncation, branch classification, and separate root queue versus DAG wait facts.
2. Added deterministic cohort, reliability, provider-state, cache/setup, and normalized-failure-signature controls.

## Verification

- `node --check scripts/ci/collect_ci_baseline.mjs` — PASS
- `node --check scripts/ci/render_ci_baseline.mjs` — PASS
- `node --check scripts/ci/verify_ci_baseline.mjs` — PASS
- `node scripts/ci/verify_ci_baseline.mjs --fixtures` — PASS

## Decisions Made

- Persist only schema-v1 allowlisted facts. Raw branch names, actors, logs, secrets, provider payloads, artifact content, and user data fail closed.
- Keep raw timestamps/conclusions as observations and calculate queue, DAG wait, durations, percentiles, and reliability claims separately.
- Require 20 successful first-attempt full-CI observations in 90 days for percentiles; otherwise report the exact count as `insufficient_sample`.

## Unresolved Assumption

BASE-01 has no SPEC edge classification. Its descriptor-less privacy prohibition remains explicit here; the committed fixture matrix covers missing timestamps, non-comparable cohorts, fewer-than-20 samples, reruns, cancellation, unknown fields, and repeated matrix signatures.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All five planned artifacts exist.
- Task commits `2a27c61b`, `85267218`, `c8c2903e`, and `ebb4b8a2` exist.
