---
status: resolved
trigger: "Phase 245 authenticated browser sweep stalls after /admin and before /admin/customers completion; latest interrupted stack points to page.setViewportSize."
created: 2026-10-11T14:30:00Z
updated: 2026-10-12T12:50:18.077962+00:00
---

## Current Focus

hypothesis: The capture wrapper waits for a nonexistent dashboard data table before screenshotting, consuming the test time budget and making a later interrupted viewport call appear responsible.
test: Dashboard table count is zero; the exact first-two capture visits pass after using an immediate optional DOM read.
expecting: A table count above zero or continued first-two stall after the change would refute the hypothesis; neither occurred.
next_action: Hand the passing guard, clean capture evidence, custody check, and full verifier result to the milestone owner for independent security re-audit; archive only after human confirmation.
bug_class: Bohrbug (deterministic missing optional selector wait)
reasoning_checkpoint:
  hypothesis: "Locator.getAttribute on an absent optional dashboard data table waits for Playwright's timeout; repeated optional waits consume the capture budget, and the interrupted setViewportSize stack is downstream."
  confirming_evidence:
    - "Authenticated dashboard has zero [data-role=data-table] elements in the live DOM."
    - "Exact first-two visit wrapper delayed after /admin navigation before screenshot under old lookup; with immediate DOM read, both routes and screenshots completed in 15.4 seconds."
  falsification_test: "Restore the waiting lookup or observe a nonzero dashboard table count; the first should reintroduce delay and the second would remove the missing-selector mechanism."
  fix_rationale: "Read optional state immediately from the DOM so absence returns null without waiting; preserve the existing unavailable or state semantics."
  blind_spots: "Full mounted sweep and recovery route remain unverified after the targeted change."
  candidate_causes:
    - "code: optional locator getter waits for absent selector even though rejection is caught"
    - "environment: Chromium sandbox process launch permission can fail before tests execute"
  and_gate: "No for the capture stall: the locator wait reproduces on the authorized ordinary browser; sandbox launch denial is a separate test-environment issue."

## Symptoms

expected: Authenticated capture completes mounted Admin sweep and writes fresh manifest with clean source provenance.
actual: Recent run completed route identity and invoice tests; sweep printed visit start for /admin and /admin/customers without completion.
errors: Interruption stack showed page.setViewportSize on the next route; no timeout cause yet.
reproduction: Run Phase245 Playwright config with isolated ordinary Fake host at http://accrue-host-phase245-ordinary.localhost/ and operator credential from local source.
started: During clean recapture after prior 19-PNG run whose manifest has source_dirty=true.

## Eliminated

- hypothesis: `page.setViewportSize` deterministically blocks when moving from dashboard to customers.
  evidence: The bounded diagnostic signed in, captured /admin, set the same viewport, and navigated to /admin/customers in 5.1 seconds.
  timestamp: 2026-10-11T15:00:00Z
- hypothesis: The first customers full-page screenshot deterministically stalls after dashboard capture.
  evidence: Extended bounded diagnostic captured both dashboard and customers full-page screenshots in 5.2 seconds.
  timestamp: 2026-10-11T15:03:00Z

## Evidence

- timestamp: 2026-10-11T14:30:00Z
  checked: Existing manifest and source
  found: Prior manifest has 19 captures at revision dd89ff7 with source_dirty=true; latest source has per-visit start logs and 15-second navigation / 20-second screenshot bounds, but setViewportSize has no bound.
  implication: Prior PNGs cannot establish current run progress; a specific unbounded await needs testing.
- timestamp: 2026-10-11T14:58:00Z
  checked: First bounded diagnostic attempt
  found: Chromium exited before test execution with MachPortRendezvousServer bootstrap_check_in Permission denied (1100).
  implication: This sandbox launch failure gives no evidence about the capture stall; retry needs browser process permission.
- timestamp: 2026-10-11T15:00:00Z
  checked: Escalated first-two-route diagnostic
  found: Authentication, dashboard DOM, dashboard full-page screenshot, setViewportSize at 1280x900, and customers DOM completed in 5.1 seconds.
  implication: The viewport operation and navigation are viable in isolation; next discriminate customers screenshot from full sweep cumulative effects.
- timestamp: 2026-10-11T15:03:00Z
  checked: Bounded two-screenshot diagnostic
  found: Both full-page screenshots, viewport set and customers navigation completed in 5.2 seconds.
  implication: Neither screenshot is a repeatable direct cause; test setup or later cumulative work remains.
- timestamp: 2026-10-11T15:01:00Z
  checked: Exact capture test limited to first two visits
  found: /admin navigation completed, then screenshot start appeared only much later; no screenshot completion appeared, and after moving to /admin/customers an interrupt stack landed in setViewportSize. Bare two-route diagnostic had completed in five seconds.
  implication: The current source line in the interrupt stack is a downstream symptom. Optional locator wait and screenshot timeout in the visit wrapper require separate tests.
- timestamp: 2026-10-11T15:02:00Z
  checked: Direct dashboard DOM count and exact first-two visit after nonwaiting lookup
  found: Dashboard data-table count was zero; exact capture wrapper completed dashboard and customers screenshots in 15.4 seconds.
  implication: The missing optional selector wait is confirmed as a preventable delay; the full sweep still needs verification.
- timestamp: 2026-10-11T15:07:00Z
  checked: Full committed capture from 8979f897 and Playwright error snapshot
  found: All 21 mounted route visits and dev probes completed in 50 seconds. Filtered-zero URL rendered zero customers and the exact copy "No customers match these filters." as a paragraph; the test requested a heading role and failed.
  implication: Main stall is resolved. The supplemental assertion uses the wrong semantic role; source assertion needs correction before complete evidence can be written.
- timestamp: 2026-10-11T15:10:00Z
  checked: Second complete sweep and CommandPalette hook source
  found: Filtered-zero passed. Control+K did not open global search immediately after page.goto; the handler is installed in CommandPalette.mounted(), while page.goto defaults to load completion and does not guarantee LiveView hook mounting. Existing e2e fixture waits for [data-phx-main].phx-connected before LiveView interactions.
  implication: Capture must wait for LiveView client readiness before exercising the keyboard shortcut; Control+K itself is supported by the handler.
- timestamp: 2026-10-11T15:11:00Z
  checked: Focused supplemental diagnostic and full capture to manifest write
  found: All supplemental interactions passed in 12.5 seconds; subsequent full run passed all browser work but assertNoSecrets rejected source_digests file path page_header.ex because its key regex matches "header" in a source filename.
  implication: Security validation must distinguish source file path keys from manifest field names; manifest has not yet been written.
- timestamp: 2026-10-11T15:11:45Z
  checked: Final authenticated Playwright run, manifest files, PNG hashes, protected preview custody and baseline verifier
  found: Four tests passed in 49.1 seconds; manifest has 24 captures, source_dirty=false, source_revision=e90e1436, and every PNG hash/byte count matches. Phase243 assert-preserved passed. Baseline verifier reports only stale F02/F05 references to R14-populated; current C14 has R14-filtered-to-zero with the same PNG hash.
  implication: Browser capture and provenance are complete. Findings/coverage owner must update the two route-state references before whole-phase verifier passes.
- timestamp: 2026-10-11T15:22:27Z
  checked: Independent bulk-capture Fake processor guard and fresh capture from source revision a8d39ea4
  found: Mock guard test accepted Accrue.Processor.Fake and rejected Accrue.Processor.Stripe without database access. The standalone bulk test now invokes the same live dockerEval processor guard before creating output or taking any screenshot. All five authenticated Playwright tests passed in 49.6 seconds; manifest has 24 clean-source captures and all PNG hashes match; full route/manifest/findings verifier and protected Phase243 custody assertion passed.
  implication: Running only the bulk capture test is now subject to the Fake-processor custody check, and fresh evidence is bound to guarded source.

## Resolution

root_cause: Optional locator attribute reads wait for nonexistent dashboard data-table until Playwright timeout; catches mask the wait and consume sweep budget.
fix: Commits 8979f897, 84d14422, 9b07efc2, c7bd7f1e and e90e1436 remove optional locator waits, align supplemental assertions with observed DOM, wait for LiveView hooks, and validate source digest paths separately from secret metadata fields. Commit a8d39ea4 adds an independent live Fake-processor guard to the bulk capture test.
verification:
  target_test: {result: pass, detail: "five authenticated Phase245 Playwright tests passed in 49.6 seconds, including the focused positive/negative processor guard"}
  mutation_check: {result: skipped, reason: "Stryker is not configured for this CommonJS Playwright capture harness"}
  no_op_deletion: {result: pass, detail: "capture visits, state assertions, secret-field validation and evidence writing remain active"}
  adjacent_tests: {result: pass, suites_run: ["full Phase245 Playwright suite", "PNG digest and byte-count audit", "full route/manifest/findings verifier", "Phase243 preview assert-preserved"]}
  revert_and_reconfirm: {result: not_run, reason: "the original source was observed failing before the fix and the same first-two wrapper passed in 15.4 seconds after, but no literal post-fix revert was run"}
  manifest_verifier: {result: pass, detail: "PASS: route inventory, capture manifest and findings"}
  guardrail_verdict: pending_literal_revert_check_and_human_verify
files_changed: [examples/accrue_host/e2e/phase245-admin-baseline.spec.js]

## Milestone Closeout Resolution — 2026-10-12

The repaired optional-selector read completed the recorded authenticated sweep 5/5 and retained 24 provenance-bound baseline captures; independent 2026-10-12 verification preserves their historical source a8d39ea4 and passes 14/14.
