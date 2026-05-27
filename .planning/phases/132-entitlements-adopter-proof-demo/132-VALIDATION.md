# Phase 132: Entitlements Adopter-Proof Demo Validation

This file ensures nyquist_compliance by establishing automated verification testing commands.

## Automated Verification Tests

### 1. Entitlement Logic Integrity
**Command:** `cd examples/accrue_host && mix test test/accrue_host_web/live/entitlements_guard_test.exs`
**Purpose:** Ensures the gating rules properly allow and deny access to the dummy route based on the organizational entitlements.

### 2. Adopter-Proof Matrix Validation
**Command:** `bash scripts/ci/verify_adoption_proof_matrix.sh`
**Purpose:** Validates the CI contract ensuring that the `adoption-proof-matrix.md` contains the correct row for Entitlements gating.

### 3. Route Registration Checks
**Command:** `cd examples/accrue_host && mix phx.routes | grep "/app/reports/advanced"`
**Purpose:** Confirms the new guarded LiveView route is successfully compiled into the router pipeline.

### 4. Code Format and Compilation
**Command:** `cd examples/accrue_host && mix compile && mix format --check-formatted`
**Purpose:** General nyquist validation ensuring the injected configuration and route definitions compile cleanly without formatting regressions.
