---
phase: 244-operator-language-and-evidence
fixed_at: 2026-10-11T02:53:36Z
review_path: .planning/phases/244-operator-language-and-evidence/244-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 244: Code Review Fix Report

**Fixed at:** 2026-10-11T02:53:36Z  
**Source review:** `.planning/phases/244-operator-language-and-evidence/244-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Lazy evidence disclosures lose their open state during loading patches

**Files modified:** `accrue_admin/lib/accrue_admin/live/event_live.ex`, `accrue_admin/lib/accrue_admin/live/webhook_live.ex`, `accrue_admin/test/accrue_admin/live/event_live_test.exs`, `accrue_admin/test/accrue_admin/live/webhook_live_test.exs`, `examples/accrue_host/e2e/phase244-operator-evidence.spec.js`  
**Commit:** `4c0ce625`  
**Applied fix:** Added the existing `PreserveDisclosure` hook and stable IDs to Event Activity, Event Raw payload, and Webhook Raw payload. Added owner assertions and desktop keyboard/mobile touch browser steps that open on the first activation, retain focus for keyboard activation, and preserve a deliberate close across a later disclosure loading patch. Added a disposable marker payload to the browser event fixture so its Raw payload section is rendered.

### WR-01: The mobile timestamp layout assertion measures the first field

**Files modified:** `examples/accrue_host/e2e/phase244-operator-evidence.spec.js`  
**Commit:** `4c0ce625`  
**Applied fix:** Read the width and overflow measurements from the already selected `recordedField`, so the 320px assertion measures the exact Recorded timestamp field.

## Verification

- **LiveView owners:** `cd accrue_admin && mix test test/accrue_admin/live/event_live_test.exs test/accrue_admin/live/webhook_live_test.exs` — 36 tests, 0 failures. Run against source commit `4c0ce625` before the fixture-only follow-up commit.
- **JavaScript syntax:** `node --check examples/accrue_host/e2e/phase244-operator-evidence.spec.js` — passed.
- **Diff whitespace:** `git diff --check` — passed.
- **Formatting check:** `mix format --check-formatted` reported pre-existing formatting differences elsewhere in `webhook_live_test.exs`; it did not identify the added assertions or disclosures. No unrelated formatting changes were made.
- **Desktop browser:** `ACCRUE_HOST_PROOF_RUN_ID=26284-1791685212995 npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project=chromium-desktop --grep=@phase244-desktop --workers=1` — Event detail keyboard proof passed. The first combined run's Webhook test timed out after its Open event request returned 302 to `/`; the exact Webhook tagged case was rerun and passed without a code change. The passing run proved the scoped Event route, retained disclosure state, selected evidence, and unchanged replay status/job/audit facts.
- **Touch browser:** `ACCRUE_HOST_PROOF_RUN_ID=26284-1791685212995 npm --prefix examples/accrue_host run e2e -- e2e/phase244-operator-evidence.spec.js --project=chromium-desktop --grep=@phase244-mobile --workers=1` — 2 passed. Event timestamp dimensions: viewport 320px, document 320px, selected Recorded field 280px, content 280px. Event and Webhook touch disclosure interactions passed.
- **Revision and assets:** Browser proof ran at `65f5726b4126cc7d1600159f06e62b63787e135f`; spec SHA-256 `b14903ae7bc426b445b905426490dafa6e25e3f649e039a8655ec3133fe213b4`. CSS SHA-256 `b40ac1dc7bb6a09ac7bccedb10ac1856ea9cbad212d69ce11db054a22807b952`; JS SHA-256 `e228bac9b978a658b37e96b9aa833fe6e8a87358447d00d93e616f55f5667c26`. Served, package, and compiled bytes matched in the browser checks; no asset rebuild was needed.
- **Test environment:** The proof used native PostgreSQL `accrue_host_test`, warm proof build `26284-1791685212995`, and port 4101. The separately named phase-243 feedback web/database containers were observed already running and were left untouched. Browser verification ran in the isolated proof server, not in the feedback preview.

---

_Fixed: 2026-10-11T02:53:36Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
