---
phase: 222-close-gap-off-05-schedule-offline-reconnect-recovery
reviewed: 2026-08-05T19:57:29Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/test/accrue_host/recovery_wiring_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 222: Code Review Report

**Reviewed:** 2026-08-05T19:57:29Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The Cron entry is additive and correctly uses the existing entitlement queue. The focused formatter and recovery test pass. However, the new recovery proof leaves the normal immediate wakeup job live, so it can pass without demonstrating recovery after that immediate work was lost or unavailable.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Recovery test does not suppress the immediate wakeup job

**File:** `examples/accrue_host/test/accrue_host/recovery_wiring_test.exs:254-260`

**Issue:** Admission always persists a `ReconnectWakeup` *and* inserts a `ReconnectWakeupWorker` job (`Reconnect.schedule_attempt/5`). This test asserts only that no `ReconnectWorker` exists, then invokes `ReconnectSweeper` while the normal wakeup worker remains queued. Therefore it does not establish the required “stranded/lost immediate work” condition: the live wakeup worker could drain the same wakeup and enqueue the normal worker, allowing the test to pass without proving the scheduled recovery path is necessary. It also leaves a duplicate-work race unrepresented.

**Fix:** After asserting the durable `ReconnectWakeup` exists, query and delete (or otherwise mark unavailable) the `ReconnectWakeupWorker` Oban job before invoking `ReconnectSweeper`, while retaining the durable wakeup record. Assert that job is absent, then assert the sweeper alone inserts the `ReconnectWorker` for the attempt.

---

_Reviewed: 2026-08-05T19:57:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
