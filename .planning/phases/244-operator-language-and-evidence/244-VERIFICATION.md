---
phase: 244-operator-language-and-evidence
verified: 2026-10-11T02:57:55Z
status: gaps_found
score: 4/9 must-haves verified
covered_files:
  - .planning/phases/244-operator-language-and-evidence/244-01-PLAN.md
  - .planning/phases/244-operator-language-and-evidence/244-01-SUMMARY.md
  - .planning/phases/244-operator-language-and-evidence/244-02-PLAN.md
  - .planning/phases/244-operator-language-and-evidence/244-02-SUMMARY.md
  - .planning/phases/244-operator-language-and-evidence/244-03-PLAN.md
  - .planning/phases/244-operator-language-and-evidence/244-03-SUMMARY.md
  - .planning/phases/244-operator-language-and-evidence/244-CONTEXT.md
  - .planning/phases/244-operator-language-and-evidence/244-INVENTORY.md
  - .planning/phases/244-operator-language-and-evidence/244-RESEARCH.md
  - .planning/phases/244-operator-language-and-evidence/244-REVIEW-DISPOSITION.md
  - .planning/phases/244-operator-language-and-evidence/244-REVIEW-FIX.md
  - .planning/phases/244-operator-language-and-evidence/244-REVIEW.md
  - .planning/phases/244-operator-language-and-evidence/244-SECURITY.md
  - .planning/phases/244-operator-language-and-evidence/244-UI-REVIEW.md
  - .planning/phases/244-operator-language-and-evidence/244-UI-SPEC.md
  - .planning/phases/244-operator-language-and-evidence/244-VALIDATION.md
  - accrue_admin/assets/js/hooks/preserve_disclosure.js
  - accrue_admin/lib/accrue_admin/components/timeline.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/billing_event.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
  - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
  - examples/accrue_host/e2e/phase244-operator-evidence.spec.js
covered_digest: "v3:sha256:ba85806f9bfcdf7bcf9cec46dea7db1435f261b172c7a5b2673ad7ccba0ca5ab"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 15
  total: 15
  not_honored: []
gaps:
  - truth: "For targeted unknown outcomes, operators can tell which supported next step is available."
    status: failed
    reason: "The in-scope bulk replay path reports an aggregate unknown count for an unclassifiable enqueue exception, but it does not identify which selected delivery had the unknown result or state the next action. The refreshed table has delivery links, but the aggregate outcome is not attached to a row; opening every selected record is an inference rather than an action the result supports or names."
    artifacts:
      - path: "accrue_admin/lib/accrue_admin/copy.ex"
        issue: "webhooks_retry_result/1 returns only aggregate counts for unknown outcomes and no next-step guidance."
      - path: "accrue_admin/lib/accrue_admin/live/webhooks_live.ex"
        issue: "The result is emitted as a flash after refreshing the list; there is no per-delivery result association."
      - path: "accrue_admin/test/accrue_admin/live/webhook_replay_test.exs"
        issue: "The unclassifiable enqueue test asserts the unknown count and absence of a success claim, but does not assert a supported recovery action or identify the affected delivery in rendered output."
    missing:
      - "Associate each unknown outcome with its exact delivery and provide a supported read/investigation next step, or explicitly establish that no safe next action is available."
deferred: []
prohibition_reviews:
  - statement: "MUST NOT imply a replay was processed or completed when evidence proves only request or queue acceptance."
    original_status: unresolved
    original_verification: null
    disposition: supported-by-source-and-tests
    evidence: "The confirm copy says queue acceptance does not mean processing is complete; accepted-reread tests assert request accepted/current status unknown and refute 'processed successfully'."
  - statement: "MUST NOT invite another billing mutation as a generic retry when observation after an accepted mutation is uncertain."
    original_status: unresolved
    original_verification: null
    disposition: supported-by-source-and-tests
    evidence: "The uncertain state offers Retry read. Its handler only reloads detail; the named test asserts the accepted job and replay/audit event set remain unchanged after the read retry."
  - statement: "MUST NOT expose raw payload or sensitive fields on Home while making exact authorized evidence discoverable."
    original_status: unresolved
    original_verification: null
    disposition: supported-by-source-review
    evidence: "DashboardLive builds its timeline from label, timestamp, subject summary, actor type, metadata, and scoped detail href; it never reads event.data. The owner-scoped query projection also excludes payload data, while EventLive exposes exact evidence at the authorized detail route."
human_verification:
  - test: "Exercise the backstop encoding cases in a rendered browser at narrow width: a Unicode/unbroken event key, long or Unicode identifiers, and long/Unicode destination labels."
    expected: "Displayed evidence remains selectable and byte-for-byte exact, wraps without hiding controls or overflowing, and links retain the exact scoped destination."
    why_human: "The present browser run covers ordinary IDs and exact timestamps at 320px; unit coverage checks a Unicode unknown key's neutral label but no held-out browser case checks unusual raw keys, long IDs, or encoded link destinations."
  - test: "Exercise repeated same-label/same-value activity rows and nearby event/webhook actions in the mounted narrow layout."
    expected: "Each action remains attached to its own record in stable order, and adjacent event and delivery actions remain distinguishable."
    why_human: "The current owner/browser assertions cover separate event and webhook examples, but not the plan's duplicate-value ordering and adjacency backstops."
---

# Phase 244: Operator Language and Evidence Verification Report

**Phase Goal:** Operators can understand the activity, state, outcome, and supported next action on targeted existing Admin screens without losing exact investigation evidence.
**Verified:** 2026-10-11T02:57:55Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Targeted Admin activity and state labels use source-backed operator language and remain consistent across confirmed consumers. | ✓ VERIFIED | `BillingEvent` maps only confirmed event keys; Home, Events, detail, and related webhook consumers call the shared label owner. Focused Copy and LiveView assertions plus the revision-bound browser checks confirm rendered labels. |
| 2 | For targeted completed, failed, blocked, and unknown outcomes, operators can tell the confirmed effect and supported next step. | ✗ FAILED | Single-delivery accepted/read-unknown handling names “Retry read” and proves it does not redispatch. However, bulk unclassifiable enqueue exceptions show only an aggregate “1 unknown” count; the refreshed result is not tied to a delivery and gives no next step. See the gap above. |
| 3 | Exact event keys, related record IDs, and full available timestamps remain available at the scoped investigation destination. | ✓ VERIFIED | EventLive renders ISO8601 precision; its named LiveView test checks seconds, fractional precision, and UTC offset. Desktop and 320×800 browser tests verify the scoped event route, exact stored key, subject ID, and timestamp. Webhook activity tests preserve event/delivery distinction and scoped links. |
| 4 | Repeated headings and action names accurately describe their destinations or effects. | ✓ VERIFIED | Home’s “View events” points to the scoped Events list; “Open event” targets the exact event. “Retry read” invokes the read handler; “Replay webhook” enters confirmation and step-up. Existing browser tests check hrefs and durable state/job/audit facts. |
| 5 | Unknown or malformed keys and absent evidence receive neutral/unavailable wording without fabricated values. | ✓ VERIFIED | Copy tests cover Unicode unknown, empty, nil, and malformed keys. Event detail tests cover missing payload and unavailable time behavior; Home uses only a scoped event link and record summary. |
| 6 | Unusual raw event-key bytes remain selectable and exact in rendered evidence. | ? UNCERTAIN | The unit test checks neutral labeling for a Unicode key, but no browser/held-out test renders and selects that key in EventLive. This plan item is tagged `verification: backstop`. |
| 7 | Long/Unicode record identifiers remain exact and usable in the native evidence surface at narrow width. | ? UNCERTAIN | Browser evidence verifies an ordinary identifier and timestamp at 320px. No test uses a long or Unicode identifier. This plan item is tagged `verification: backstop`. |
| 8 | Adjacent event and webhook actions remain distinguishable at narrow width, and repeated matching values keep stable row/action association. | ? UNCERTAIN | UI-SPEC/VALIDATION audit documents 35 state considerations and mounted tests cover narrow disclosures, but the specific adjacent-action and duplicate-value ordering backstops are not directly exercised. |
| 9 | Long/Unicode link labels and identifiers preserve exact scoped destinations and remain operable. | ? UNCERTAIN | Scoped ordinary links are asserted on desktop/mobile; no held-out test covers long or Unicode href labels/identifiers. This plan item is tagged `verification: backstop`. |

**Score:** 4/9 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/copy/billing_event.ex` | Shared source-backed event labels and neutral fallback | ✓ VERIFIED | Substantive mapping; delegated through `copy.ex` and used by DashboardLive, EventsLive, EventLive, and webhook activity. Copy tests cover known, Unicode unknown, and malformed keys. |
| `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` | Home activity language, scoped links, exact evidence route | ✓ VERIFIED | Renders values from the owner-scoped event query; does not read `event.data`; owner tests cover empty/multiple rows and scoped destinations. |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` and `event_live.ex` | Consistent list/detail labels with exact key, identity, and timestamp | ✓ VERIFIED | Real query results flow to rendered list/detail fields; the exact time test uses a controlled fractional timestamp. |
| `accrue_admin/lib/accrue_admin/live/webhook_live.ex` and `webhooks_live.ex` | Distinct delivery/event state and replay/read actions | ✓ VERIFIED | Handlers branch on current status/ownership and read actual detail/jobs/events; focused tests assert output and durable facts. Bulk unknown guidance is incomplete as described in the gap. |
| `accrue_admin/lib/accrue_admin/components/timeline.ex` and `accrue_admin/assets/js/hooks/preserve_disclosure.js` | Native exact-evidence disclosure retained through patches | ✓ VERIFIED | Used by event/webhook details; REVIEW-FIX and current browser spec cover keyboard/touch open/close through patch behavior. |
| Requirement-linked ExUnit tests and `examples/accrue_host/e2e/phase244-operator-evidence.spec.js` | Behavioral evidence for UI, links, state transitions, and narrow layout | ✓ VERIFIED | Three named state tests passed in this verification; phase validation records 688 Admin tests, focused owner reruns, and post-commit desktop/touch browser runs. |

`verify.artifacts` and `verify.key-links` returned `total: 0` for each plan because those plan frontmatter entries are scalar strings rather than the query's object schema. Those empty tool results are not counted as verification; artifacts and links above were traced manually.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Producer event keys | `BillingEvent` Copy | Confirmed producer mapping | WIRED | `customer.updated`, local-only update, receipt, and replay-request labels are tied to producer behavior; unknown keys remain neutral. |
| `BillingEvent` Copy | Home, Events, detail, related activity | Shared label delegate | WIRED | Each confirmed event consumer calls the shared mapping; filters and exact evidence retain raw key values. |
| Owner-scoped event query | Home timeline | Projection to title/time/subject/actor/href | FLOWING | `DashboardLive.recent_events/2` maps real query results; Home does not read raw event payload. |
| Owner-scoped event query | Event detail | `Events.detail/2` to rendered summary/evidence | FLOWING | Source key, IDs, and inserted timestamp render from the scoped record. |
| Replay action | Dispatch/job/audit result | Existing DLQ/step-up path to result copy | WIRED | Named tests assert accepted/failed/unknown statuses against jobs and audit events. Bulk unknown output lacks row/action attribution. |
| Read retry | Detail refresh | `retry_read` handler | WIRED | Named test proves a read retry restores current details without adding another job or replay event. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Home `DashboardLive` | recent event rows | Owner-scoped `Events.list/2` | Yes; fields are mapped from returned event records | ✓ FLOWING |
| EventLive | event and related evidence | Owner-scoped `Events.detail/2` | Yes; key, identities, timestamp, and relationships are record fields | ✓ FLOWING |
| WebhookLive | delivery, jobs, derived events | Scoped `Webhooks.detail/2`, Oban query, event query | Yes; state and action outcomes derive from persisted rows | ✓ FLOWING |
| WebhooksLive | bulk replay summary | DLQ result and refreshed scoped list | Yes; aggregate counts are real, but unknown outcomes are not associated with individual records | ⚠️ PARTIAL |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| An unclassifiable enqueue exception remains unknown and is not reported as failure | `cd accrue_admin && mix test test/accrue_admin/live/webhook_replay_test.exs:429` (run with other named cases) | 3 selected tests, 0 failures; 33 excluded | ✓ PASS |
| Accepted replay/read-unknown remains queued; retrying read does not redispatch | `cd accrue_admin && mix test test/accrue_admin/live/webhook_live_test.exs:425` (run with other named cases) | Same named command: 3 selected tests, 0 failures; 33 excluded | ✓ PASS |
| Full Admin regression and browser rendering | Existing evidence only; no suite/server rerun | Validation records 688 tests, desktop 2/2, touch 2/2; the last full suite predates validation-only test additions | ✓ PASS (recorded, revision-bound) |

### Probe Execution

No phase-declared executable probe script was found. The ambiguous STATE-01 edge resolves to the named unclassifiable-enqueue test above; it proves neutral unknown classification and absence of a false success claim, while exposing the missing next-step guidance.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| LANG-01 | 244-01, 244-02, 244-03 | Faithful operator-facing activity/state labels without decoding keys | ✓ SATISFIED | Shared Copy mappings, consumer tests, and desktop/touch rendered evidence. |
| STATE-01 | 244-03 | State/outcome, action effect, and supported next step without invented cause | ✗ BLOCKED | Accepted/read-unknown and blocked states have evidence-backed copy; unclassifiable bulk enqueue result lacks per-record outcome association and next-step guidance. |
| EVID-01 | 244-01, 244-02, 244-03 | Exact investigation keys, identifiers, and timestamps remain discoverable | ✓ SATISFIED | Event detail tests and browser evidence check key, record IDs, timestamp precision, and scoped destinations. Backstop encoding cases remain human-review items. |
| CONS-01 | 244-01, 244-02, 244-03 | Consistent headings/actions accurately describe destinations/effects | ✓ SATISFIED | Scoped href/handler tests and browser navigation; read retry and replay are distinct. Backstop narrow adjacency/encoded destination cases remain human-review items. |

Orphaned requirements: none. `ROADMAP.md` maps exactly LANG-01, STATE-01, EVID-01, and CONS-01 to Phase 244, and all four appear across the plans.

### Decision Coverage

The decision-coverage gate found all 15 trackable CONTEXT.md decisions honored by shipped artifacts; it is advisory and does not alter the status.

### Security, Review, and Test Quality

The phase SECURITY report records all eight unique planned threats closed at ASVS level 1 (`threats_open: 0`). The current code review reports zero findings; CR-01 and WR-01 are recorded as fixed, and review disposition has zero open items. The linked test files have no disabled tests; no circular expected-value generator was found in the browser spec. The earlier Webhook browser timeout/HTTP 302 was followed by a passing exact tagged rerun without a source change; its cause remains unconfirmed and is not treated as a reproduced defect.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| None | — | No debt markers, placeholder implementations, or empty user-facing paths in the reviewed phase source | — | No blocker anti-pattern found |

### Human Verification Required

The two `verification: backstop` truth groups above lack direct held-out evidence for the unusual encoding and duplicate/adjacent layout cases. The existing UI-SPEC/VALIDATION audit resolves its 35 broader considerations, and the browser run verifies normal values at narrow width; it does not exercise these exact backstop inputs. These do not replace the concrete STATE-01 gap.

### Prohibition Review

The three plan prohibitions were originally written with `status: unresolved` and `verification: null`. This report preserves that provenance and resolves them through direct source/test evidence instead of treating their missing descriptors as automatic passes: completion claims are explicitly negated, uncertain recovery is read-only, and Home's render projection excludes raw payload. The three findings are reviewed individually in `prohibition_reviews` frontmatter.

### Gaps Summary

Three roadmap truths are supported by source and behavioral evidence. The unknown bulk replay edge is accurately labeled unknown, but an operator cannot identify which delivery produced the aggregate result or see a supported next action from that result. The phase therefore has one blocking STATE-01 gap. Additional held-out browser evidence is still needed for unusual identifiers/keys and duplicate/adjacent narrow-layout backstops. No browser outage or mutation was fabricated during verification.

---

_Verified: 2026-10-11T02:57:55Z_  
_Verifier: the agent (gsd-verifier)_
