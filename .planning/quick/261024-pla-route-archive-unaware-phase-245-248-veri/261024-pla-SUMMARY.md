---
phase: quick-261024-pla
plan: 01
subsystem: ci
tags: [archive-sweep, phase_evidence_path, verifiers]
status: complete
human_judgment: false
commits: 2
plan_head_before: 32c0d4b19a0a3489de038f67e413861a811a5179
plan_head_after: 193a8a8e
key-files:
  modified:
    - scripts/ci/verify_phase245_baseline.mjs
    - scripts/ci/verify_phase248_integrated_proof.mjs
    - scripts/ci/verify_phase248_integrated_proof.test.mjs
    - scripts/ci/verify_phase248_render_proof.test.mjs
actuals:
  tokens: 9000
  tasks: 2
  commits: 2
---

# Quick 261024-pla: Route archive-unaware phase 245/248 verifier reads

The archive sweep (`node scripts/ci/verify_phase230_archive_invariants.mjs`) now exits 0. It exited 1 with 11 findings at base 32c0d4b1. The phase 245 and 248 verifiers read the archived evidence through `resolvePhaseEvidencePath`.

## Commits
- 7dc8419c: `verify_phase245_baseline.mjs`. A new `resolveEvidenceInput` helper resolves `--coverage`, `--manifest` and `--findings`. Defaults go through the resolver. Recorded PNG paths are checked textually against the 245 captures prefix, with no `..` segment. They are resolved through the resolver and must sit inside the resolved captures directory. Resolver errors print `FAIL:` instead of a stack trace.
- 193a8a8e: the 248 integrated-proof owner source now uses `resolvePhaseEvidencePath`, and the result still passes through `resolveEvidenceFile`. Both 248 tests use the resolver for their manifest and proof paths. The three non-read literals got `archive-sweep-exempt` markers: the proof-markdown replace text and the two synthetic `245-baseline` fixture slugs.

## Verification
- Sweep: exits 0 (`scanned_files=134, literals=50`).
- Positive control: an export of 32c0d4b1 run with its own copy of the script exits 1 and reports 11 findings. They include `phase245_baseline.mjs:15` and `render_proof.test.mjs:11`.
- The sweep CLI ignores `--repo`, so the control has to run the exported copy of the script. `--repo .` runs against the live repo regardless.
- 245 verifier: `--routes-only` passes with defaults and with the recorded `.planning/phases/...` flag form. `--self-test` passes. The full run shows only `source digest is stale` lines, with no ENOENT, missing PNG or escape failures.
- 248 tests: the per-test ok/not-ok set matches baseline by name. Tests 4, 10, 11, 12 and 13 are ok; the others fail as before. No path-resolution failures remain.
- `phase_evidence_path.test.mjs`: 9 passed, 0 failed.

## Deviations
**[Rule 1 - Bug] Render-proof test child process polluted by node:test context.** The 248 validator imports `verify_phase248_integrated_proof.mjs`. That module now imports `phase_evidence_path.mjs`, which imports `main_module.mjs`. `main_module.mjs` registers node:test cases whenever `NODE_TEST_CONTEXT` is set, and the spawned child inherited it, so its stdout filled with serialized test events. That broke the render tests' output regexes. Fix: `verify_phase248_render_proof.test.mjs` now spawns the validator with `NODE_TEST_CONTEXT: ''`. `verify_phase248_render_proof.mjs` was not edited.

## Out of scope: pre-existing, not fixed
- Frozen 245/248 evidence has drifted from current main: stale source digests, served CSS digest mismatch, and `current product source differs from tested source: ...customer_live.ex`. Re-capturing the evidence is out of scope.
- `verify_artifact_fixed_point.mjs` fails on the live repo. The `--repo` form reports `phase null`. The `--fixtures` form and `node --test` test 18 report `covered file missing on disk: .planning/REQUIREMENTS.md`, which has been absent since commit 593b8588. This is unrelated to the touched files, none of which is in any `covered_files` list.

## Self-Check: PASSED
Commits 7dc8419c and 193a8a8e exist. The 4 modified files are committed. The working tree is clean apart from the untracked plan directory.
