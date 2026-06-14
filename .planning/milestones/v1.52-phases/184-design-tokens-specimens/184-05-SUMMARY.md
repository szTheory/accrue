---
phase: 184-design-tokens-specimens
plan: "05"
subsystem: .github/workflows
tags: [ci, design-tokens, determinism, parity-check, brandbook, shift-left]
dependency_graph:
  requires:
    - Plan 02: brandbook/tokens/tokens.css (generated CSS — determinism gate target)
    - Plan 02: brandbook/tokens/harness/generate-tokens-css.mjs (npm run generate)
    - Plan 03: brandbook/tokens/harness/parity-check.mjs (npm run parity / parity-test)
    - Plan 04: brandbook/tokens/harness/generate-specimens.mjs (npm run specimens)
    - Plan 04: brandbook/examples/{palette,typography,spacing}.svg (determinism gate targets)
    - brandbook/tokens/harness/package-lock.json (committed lockfile — D-17)
  provides:
    - CI determinism gate (D-17): regenerate tokens.css + specimens → git diff --exit-code
    - CI correctness gate (SC#2): parity-check.mjs live run + --test injected-drift fixture
  affects:
    - Plan 186: brandbook assembly will pass CI without additional gate wiring
tech_stack:
  added: []
  patterns:
    - setup-node@v6 + node-version 22 + cache-dependency-path (mirrors host-integration lane)
    - npm ci from committed package-lock.json (D-17 determinism convention)
    - git diff --exit-code as the reproducibility gate (mirrors admin-drift-docs lane)
    - Two distinct gates: diff = reproducibility; parity + parity-test = correctness
key_files:
  created: []
  modified:
    - .github/workflows/ci.yml (6 new steps in docs-contracts-shift-left job)
decisions:
  - "Steps added to docs-contracts-shift-left job (runs-on ubuntu-24.04, no native deps, merge-blocking) — the recommended CI home per PATTERNS.md."
  - "Two distinct gates kept separate per plan spec: git diff --exit-code proves reproducibility (D-17); npm run parity + npm run parity-test prove correctness (SC#2 both directions)."
  - "setup-node@v6 step placed after existing bash/doc steps — node is only needed for the brandbook harness; installing it at the end of the job minimizes unnecessary Node setup for the earlier bash-only steps."
  - "npm ci with cache-dependency-path: brandbook/tokens/harness/package-lock.json — consumes the committed lockfile (T-184-SC mitigated; no npm install in CI)."
metrics:
  duration: ~3 minutes
  completed: "2026-06-14"
  tasks_completed: 1
  files_created: 0
  files_modified: 1
---

# Phase 184 Plan 05: Brandbook CI Gates (D-17 / SC#2) — Summary

Wires the brandbook token toolchain into the `docs-contracts-shift-left` CI job as two distinct gates: a determinism gate (`npm ci` → regenerate tokens.css + specimens → `git diff --exit-code`) and a correctness gate (`parity-check.mjs` live run + `--test` injected-drift fixture). Closes the Wave 0 CI requirement from 184-VALIDATION.md. Zero admin code changes.

## What Was Built

**Task 1 (cb908813): 6 new steps in `.github/workflows/ci.yml` `docs-contracts-shift-left` job**

Steps added in order after the existing bash/doc contract steps:

1. **Set up Node (tokens harness)** — `actions/setup-node@v6`, node-version 22, `cache: npm`, `cache-dependency-path: brandbook/tokens/harness/package-lock.json`. Mirrors the `host-integration` job's node-setup pattern (ci.yml:457-462). Cache key is locked to the committed harness lockfile.

2. **Install tokens harness** — `cd brandbook/tokens/harness && npm ci`. Consumes the human-verified committed `package-lock.json` (D-17). Never runs `npm install` in CI (T-184-SC mitigated).

3. **Regenerate tokens + specimens** — `cd brandbook/tokens/harness && npm run generate && npm run specimens`. Runs `generate-tokens-css.mjs` (produces `tokens.css`) and `generate-specimens.mjs` (produces `palette.svg`, `typography.svg`, `spacing.svg`) against the committed `tokens.json` SSOT.

4. **Tokens/specimens are reproducible (determinism gate, D-17)** — `git diff --exit-code -- brandbook/tokens/tokens.css brandbook/examples/palette.svg brandbook/examples/typography.svg brandbook/examples/spacing.svg`. Fails CI if any committed artifact is stale relative to its generator. Mirrors the `admin-drift-docs` diff gate (ci.yml:392-396).

5. **Brand↔admin token parity (SC#2)** — `cd brandbook/tokens/harness && npm run parity`. Runs `parity-check.mjs` live: reads `accrue_admin/assets/css/theme.css` and `tokens.json`, checks all ax-mapped tokens match in light + dark scopes (Plan 03). Exits 0 only on `PARITY_CLEAN_OK`.

6. **Parity drift detection proof (SC#2 both directions)** — `cd brandbook/tokens/harness && npm run parity-test`. Runs `parity-check.mjs --test`: exercises four injected-drift fixtures (a=positive, b=injected drift detected, c=documented divergence tolerated, d=unrelated prop ignored). Exits 0 only when all four cases pass `PARITY_TEST_OK`.

**Verification passes:**

```
CI_YAML_OK         # python3 YAML parse + gate assertion
ADMIN_CLEAN        # git diff --exit-code -- accrue_admin/ (no admin files touched)
```

## Deviations from Plan

None — plan executed exactly as written. The six steps match the spec in PATTERNS.md lines 313-326 and the plan's action description exactly.

## Known Stubs

None. Both CI gates are wired to real scripts that have been verified to exit 0 in Plans 02-04. No placeholder steps or deferred wiring.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: dependency-integrity | .github/workflows/ci.yml | npm ci consumes the committed package-lock.json (T-184-SC mitigated); integrity hashes in the lockfile enforce supply-chain trust for culori, postcss, postcss-value-parser, svgo |

T-184-14 (stale-artifact drift): mitigated by the determinism gate (step 4).
T-184-15 (CI inadvertently editing theme.css): step 5 is read-only; ADMIN_CLEAN verified above.

## Self-Check: PASSED

Files modified:
- FOUND: .github/workflows/ci.yml (modified — 22 insertions)

Commits:
- FOUND: cb908813 (Task 1 — 6 CI steps)

Verification gates:
- CI_YAML_OK: python3 YAML parse + all four assertions (parity, parity-test, git diff --exit-code, package-lock.json path)
- ADMIN_CLEAN: git diff --exit-code -- accrue_admin/ clean
