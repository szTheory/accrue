---
phase: 245-rendered-baseline-and-realistic-preview
fixed_at: 2026-10-11T14:29:07Z
review_path: .planning/phases/245-rendered-baseline-and-realistic-preview/245-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 245: Code Review Fix Report

**Fixed at:** 2026-10-11T14:29:07Z  
**Source review:** `.planning/phases/245-rendered-baseline-and-realistic-preview/245-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Environment checks do not protect the connected database

**Files modified:** `examples/accrue_host/priv/repo/seeds/ordinary.exs`, `scripts/ci/seed_phase245_ordinary.sh`, `examples/accrue_host/README.md`  
**Commit:** `a6914b3a`, `92708e0b`  
**Applied fix:** The seed entrypoint checks the live Repo database, role, and resolved Compose DB address before evaluating seed files. Test execution is constrained to the test database name family. The host wrapper verifies the running ordinary project's network, named DB volume, and live Postgres fingerprint, then snapshots and checks preservation of Phase 243 around the explicit seed command.

### WR-01: The verifier does not validate source digests or dirty-source provenance

**Files modified:** `scripts/ci/verify_phase245_baseline.mjs`  
**Commit:** `511a9999`  
**Applied fix:** Every capture digest must be a SHA-256 matching an existing repository file. The verifier rejects dirty source captures and binds each capture revision to the top-level manifest revision. The Playwright harness records dirty state only for its complete capture source set, including the capture spec and config.

### WR-02: Any production route can be marked unavailable and still pass verification

**Files modified:** `scripts/ci/verify_phase245_baseline.mjs`  
**Commit:** `511a9999`  
**Applied fix:** The verifier requires the exact mounted production route inventory, forbids `not-applicable` for mounted production routes, requires at least half of mounted routes to be inspected, and requires concrete observed evidence for unavailable routes. Generic blanket reasons fail.

### WR-03: The verifier can accept duplicate owner topics while omitting required topics

**Files modified:** `scripts/ci/verify_phase245_baseline.mjs`  
**Commit:** `511a9999`  
**Applied fix:** The owner ledger must contain each of the 13 canonical owner-brief topics exactly once, no unknown topics, and a recognized disposition for every topic.

### WR-04: The capture can claim a route was inspected after any successful redirect

**Files modified:** `examples/accrue_host/e2e/phase245-admin-baseline.spec.js`, `scripts/ci/verify_phase245_baseline.mjs`  
**Commit:** `92708e0b`, `b7d1f256`, `511a9999`  
**Applied fix:** Before screenshotting, the browser must remain at the requested origin, concrete path, query, and route template and render a visible main heading. A mismatch is recorded as unavailable with the observed destination. Captures retain the heading identity, and the verifier checks it against the route row and final URL. The capture lane also independently checks the actual ordinary Compose DB identity and rejects secret/session field names from manifest artifacts.

## Verification

Checks ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees` to `false`.

- `node scripts/ci/verify_phase245_baseline.mjs --self-test` — passed refreshed positive fixture and negative controls for stale digest, mismatched route, duplicate owner topic, and generic unavailable reason.
- `node scripts/ci/verify_phase245_baseline.mjs --coverage .planning/phases/245-rendered-baseline-and-realistic-preview/245-COVERAGE.md --routes-only` — passed.
- Focused Playwright route-identity test (`--grep='route identity rejects'`) — passed, covering exact record path, redirect, and query mismatch.
- Node syntax checks, Elixir parse, `mix format --check-formatted` for the seed, Bash syntax check, and `git diff --check` — passed.

The full authenticated browser capture and database wrapper were not run in this fixer pass. The existing capture artifacts still need a fresh run against committed sources; historical capture files were left intact for audit context.

---

_Fixed: 2026-10-11T14:29:07Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
