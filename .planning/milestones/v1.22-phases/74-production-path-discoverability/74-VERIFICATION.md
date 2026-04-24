# Phase 74 — Production path discoverability — Verification

**Status:** passed  
**Date:** 2026-04-23

## PRS-01..PRS-03

- **Root `README.md`** — includes **`accrue/guides/production-readiness.md`** under **Where to go next** with production / live-Stripe framing; **Proof path** paragraph lists **`verify_production_readiness_discoverability.sh`** in **`docs-contracts-shift-left`**.
- **`accrue/README.md`** — **Start here** links **`guides/production-readiness.md`** with ship-order framing.
- **`scripts/ci/verify_production_readiness_discoverability.sh`** — merge-blocking; asserts link needles and **`### 1.`**–**`### 10.`** + intro heading in **`accrue/guides/production-readiness.md`**.
- **`.github/workflows/ci.yml`** — **`docs-contracts-shift-left`** runs the verifier after **`verify_verify01_readme_contract.sh`**.
- **`scripts/ci/README.md`** — **PRS gates (v1.22)** table + triage subsection + co-update rule.
