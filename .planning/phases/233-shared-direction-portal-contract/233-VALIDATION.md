---
phase: "233"
slug: "shared-direction-portal-contract"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-07"
---

# Phase 233 — Validation Strategy

> Execution validation contract. Planning has not run application tests, built assets, or inspected current served rendering. Final task IDs and focused commands are synchronized with the plans before plan checking.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing ExUnit, Phoenix.LiveViewTest, and canonical host Playwright |
| Config file | `accrue_portal/mix.exs`; canonical host Playwright configuration |
| Quick run command | `cd accrue_portal && mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/router_test.exs` |
| Full suite command | `cd accrue_portal && mix test --warnings-as-errors` |
| Estimated runtime | Unmeasured; record actual focused and full-suite runtime during execution |

## Sampling Rate

- After each behavior change, run its focused test files before committing.
- After each wave, run the Portal suite and the browser scenarios applicable to that wave.
- Before phase verification, require the full Portal suite, canonical example integration checks, docs contracts, and current served visual evidence.
- Target focused feedback under 60 seconds; measure rather than claim this target has passed.

## Per-Task Verification Map

The planner will replace these provisional slice IDs with the concrete task IDs, threat references, and commands in the PLAN files.

| Slice | Requirement | Secure Behavior | Test Type | Automated Command / Evidence | Status |
|-------|-------------|-----------------|-----------|------------------------------|--------|
| Current baseline | BASE-01 | Current source and served assets trace to recorded provenance | Browser/artifact | Bounded canonical-host capture with source SHA, asset hashes, route/state/theme/viewport and assertion results | pending |
| Semantic roles | SYS-01, SYS-02 | Host text/accents remain presentation; token ownership preserved | Source/browser | Existing asset contracts plus rendered focus, status cues, contrast and reflow assertions | pending |
| Optional context tracer | POR-08, SAFE-02 | Resolve and authorize before provisioning; exact owner type/ID/processor | ExUnit integration | Focused auth/router suite plus new adapter and identity assertions | pending |
| Protected actions | POR-08, SAFE-02, SAFE-03 | Reauthorize same server-loaded target through all four POSTs and LiveView paths | ExUnit integration | New denied/revoked/stale-pin cases and zero-provider-call assertions | pending |
| Form invalidation | SAFE-03 | No cross-account retarget or replay; clear secure state; preserve human actor | ExUnit/browser | Account switch/reconnect/denial and audit attribution scenarios | pending |
| Canonical adoption | SHIP-04 | Personal default and authorized mixed/custom host contract | Host integration/docs | Canonical host scenarios and documented mounting/selection/action examples | pending |

## Wave 0 Requirements

- Existing frameworks suffice; no new framework or dependency is required.
- Create meaningful adapter/identity/policy fixtures in the owning tracer task before the expanded scenarios use them.
- Add denied, missing, deleted, explicit-invalid and unavailable selection cases; prove zero provisioning/provider writes.
- Cover all four POST routes, LiveView connected/disconnected mounts, reconnect, protected navigation/events, stale form and checkout identity.
- Create bounded canonical-host browser proof for current served assets, billed identity, secure-field clearing and accessible recovery.
- A source-only assertion or historical screenshot cannot substitute for current served behavior.

## Manual-Only Verifications

| Behavior | Requirement | Why Direct Inspection | Instructions |
|----------|-------------|-----------------------|--------------|
| Audience identity and visual hierarchy | BASE-01, SYS-01, SYS-02 | Browser assertions cannot fully judge composition | Executor inspects current representative Admin/Portal renders; records observations and provenance alongside machine assertions. No recurring user UAT checkpoint is needed for automatable behavior. |

## Validation Sign-Off

- [ ] Concrete plan task IDs, threat references and commands are synchronized.
- [ ] Every task has an automated check or explicit prerequisite that supplies it.
- [ ] No three consecutive tasks lack automated verification.
- [ ] Every new verification target is created before it is invoked.
- [ ] No watch-mode command is used.
- [ ] Focused feedback timing is measured.
- [ ] Execution results support `nyquist_compliant: true` and `wave_0_complete: true` before those flags change.

**Approval:** Pending execution evidence.
