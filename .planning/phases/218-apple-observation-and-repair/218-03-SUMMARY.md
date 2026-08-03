---
phase: 218-apple-observation-and-repair
plan: "03"
subsystem: payments
tags: [apple, jws, es256, public_key, privacy]
requires:
  - phase: 218-02
    provides: Rejected package decision and locked private fallback
provides:
  - Private strict Apple JWS verifier behaviour and production adapter
  - Deterministic hostile verifier corpus and admission evidence
affects: [apple-observation, apple-repair, entitlements]
tech-stack:
  added: []
  patterns:
    - Strict JWS verification is private, pure, allowlist-based, and returns closed errors only
key-files:
  created:
    - accrue/lib/accrue/entitlements/apple/verifier.ex
    - accrue/lib/accrue/entitlements/apple/verifier/production.ex
    - accrue/test/accrue/entitlements/apple_verifier_test.exs
    - accrue/test/fixtures/apple/server_evidence.exs
    - .planning/phases/218-apple-observation-and-repair/218-ADAPTER-ADMISSION.md
  modified: []
key-decisions:
  - "Rejected app_store_server_library remains excluded; the private Jason plus OTP :public_key fallback is selected."
  - "Outer notification and both nested JWS inputs are verified independently and only bounded facts can leave the verifier."
requirements-completed: [AAPL-02]
coverage:
  - id: D1
    description: Strict private Apple verifier rejects malformed, algorithm-confused, hostile-header, and untrusted-chain evidence with closed errors.
    requirement: AAPL-02
    verification:
      - kind: unit
        ref: accrue/test/accrue/entitlements/apple_verifier_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: The rejected package remains absent and dependency files are byte-identical.
    requirement: AAPL-02
    verification:
      - kind: other
        ref: "git show HEAD:accrue/mix.exs | shasum; git show HEAD:accrue/mix.lock | shasum"
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-08-03
status: complete
---

# Phase 218 Plan 03: Apple observation and repair Summary

**Private, pure Apple ES256 verifier with pinned OTP certificate-path validation, independent nested evidence checks, bounded facts, and no new dependency.**

## Performance

- **Duration:** 5 min
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Recorded deterministic rejection evidence and selected the locked Accrue-owned Jason/OTP fallback without evaluating the rejected package.
- Added a narrow verifier behaviour, immutable configuration struct, closed public errors, strict compact-JWS parsing, protected-header allowlist, configured-root path validation, ES256 raw-signature normalization, and application-claim checks.
- Added focused hostile corpus coverage for malformed payloads, algorithm/header confusion, untrusted chains, deterministic repeat/concurrent evaluation, and redacted outputs.
- Confirmed `accrue/mix.exs` and `accrue/mix.lock` are byte-identical to their pre-plan state.

## Task Commits

1. **Task 1: Decide adapter admission against the hostile verifier contract** — `7fcd4c47` (`test`)
2. **Task 2: Implement the selected strict production adapter** — `0fe59e82` (`feat`)

## Decisions Made

- The Plan 218-02 rejection is definitive: `app_store_server_library` was neither installed nor evaluated.
- The adapter is stateless and has no persistence, provider mutation, process registration, logging, or telemetry side effect.
- Raw JWS bytes and non-allowlisted claims never enter verifier outputs or errors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the installed Hex audit command instead of an unavailable `mix deps.audit` task.**
- **Found during:** Task 2
- **Issue:** This project has no `deps.audit` Mix task.
- **Fix:** Ran `mix hex.audit`, the available built-in Hex advisory audit, without changing dependencies.
- **Result:** It reported pre-existing advisories in unrelated dependencies; none are introduced by this plan.

## Issues Encountered

- `mix hex.audit` exits nonzero because the existing lock contains advisories for `postgrex`, `swoosh`, `decimal`, `phoenix`, `req`, and `hackney`. Dependency upgrades are outside this plan and would violate the locked byte-identical dependency boundary.

## Known Stubs

None. The fixture corpus intentionally uses non-sensitive hostile data; host-managed protected Apple golden captures and root/configuration inputs remain outside repository source control.

## Next Phase Readiness

The private verifier boundary is ready for host configuration and Apple observation wiring. Existing dependency advisories should be scheduled separately; this plan introduced no dependency state.

## Self-Check: PASSED

- Required verifier, production adapter, fixture corpus, admission report, and focused test file exist.
- Task commits `7fcd4c47` and `0fe59e82` exist.
- Focused tests and warnings-as-errors compile passed; dependency files are byte-identical.
