---
phase: 244
status: secured
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
threats_total: 8
threats_closed: 8
threats_open: 0
verified_source: 332426178e6c6c177efe4b0bd298511fead02256
---

# Phase 244 Security Verification

Independent security audit verified the eight unique planned threats at ASVS level 1. T-244-SC appears in all three plans and is counted once. The auditor's prose total said seven; its eight distinct rows are the authoritative register reconciled here. No additional tests were run by this audit; evidence is source and existing executed test coverage.

| Threat | Severity | Status | Mitigation evidence |
|---|---|---|---|
| T-244-01 | high | CLOSED | Home uses owner-scoped Events.list, projection excludes data; dashboard_live.ex:91–105, queries/events.ex:79–86 and 215–224; dashboard_live_test.exs:120–155. |
| T-244-02 | medium | CLOSED | Exact raw type SQL filtering and ScopedPath navigation; queries/events.ex:187–188, events_live.ex:425–449; events_live_test.exs:297–335 and 385. |
| T-244-03 | high | CLOSED | Scoped EventLive reads and validated relationships; event_live.ex:24,228,313–405; event_live_test.exs:228–245,358–440. |
| T-244-04 | medium | CLOSED | Exact key, IDs and ISO8601 timestamp; event_live.ex:233–257,445–446; controlled precision test event_live_test.exs:81–107. |
| T-244-05 | high | CLOSED | Replay requires fresh step-up and ownership recheck; webhook_live.ex:150–163,601–655; denial leaves jobs/audit unchanged, webhook_live_test.exs:330–350. |
| T-244-06 | high | CLOSED | Accepted replay and unknown reread remain distinct, recorded event/audit; webhook_live.ex:718–735,769–791; webhook_live_test.exs:353–405 and webhook_replay_test.exs:448–480. |
| T-244-07 | high | CLOSED | retry_read fetches only; webhook_live.ex:96–125; same job/event/audit assertions webhook_live_test.exs:390–405. |
| T-244-SC | high | CLOSED | No dependency manifest or lockfile changes; existing pinned asset build only. Conditional install audit was not triggered. |

Paths above are under accrue_admin/lib/accrue_admin and accrue_admin/test/accrue_admin; the event query owner is queries/events.ex. All phase commits are reachable from this branch. The executed acceptance source revision is an ancestor of current HEAD; subsequent validation additions are tests and documentation.

## Accepted Risks

None. No unregistered Summary Threat Flags were reported.

## Security Audit

| Threats found | Closed | Open |
|---|---|---|
| 8 | 8 | 0 |
