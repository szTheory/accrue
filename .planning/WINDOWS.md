---
schema_version: 1
open_count: 10
waived_count: 0
fixed_count: 0
total_count: 10
last_updated: 2026-08-13T03:58:20.522Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 214.2 | unrun-verify | examples/accrue_host/e2e/verify01-admin-mobile.spec.js |  | Host mobile entitlement contract is skipped because the checked-in Playwright config has no chromium-mobile project. | open |  | 2026-07-31T19:21:33.589Z |  |
| 2 | 215 | deviation | examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift |  | Corrected stale capability case name in the tracer test. | open |  | 2026-08-01T01:55:48.046Z |  |
| 3 | 215 | deviation | examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift |  | Reducer now requires every declared evidence lane before reporting proven. | open |  | 2026-08-01T01:55:48.106Z |  |
| 4 | 217 | unrun-verify | accrue/test/accrue/docs/package_docs_verifier_test.exs |  | mix test.all could not start because unrelated shared dirty file is not formatted | open |  | 2026-08-03T01:52:16.732Z |  |
| 5 | 220 | unrun-verify | examples/accrue_host/test/accrue_host/billing_facade_test.exs | 160 | Full mix verify could not complete because the pre-existing fake subscription uniqueness test failed. | open |  | 2026-08-04T15:43:48.620Z |  |
| 6 | 220 | deviation | accrue/lib/accrue/entitlements/snapshot.ex |  | Forwarded snapshot :now option to repository folding for frozen expiry-boundary proof. | open |  | 2026-08-05T02:02:05.577Z |  |
| 7 | 221 | unrun-verify | examples/accrue_host |  | mix verify blocked by unrelated tracked formatting violations before its test suite | open |  | 2026-08-05T17:28:54.045Z |  |
| 8 | 221 | unrun-verify | examples/accrue_host/lib/accrue_host_web/components/layouts.ex |  | Full mix format --check-formatted is blocked by unrelated tracked formatting violations in layouts and existing migrations. | open |  | 2026-08-05T17:40:05.349Z |  |
| 9 | 225 | deviation | accrue_admin/mix.lock | 41 | Locked already-declared jose dependency so the Admin Playwright web server starts in a clean checkout. | open |  | 2026-08-09T03:32:55.284Z |  |
| 10 | 227 | unrun-verify | .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson |  | Live three-success critical-path comparison could not run: final bounded cohort had no qualifying successful workflow_dispatch observations. | open |  | 2026-08-13T03:58:20.522Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "214.2",
    "file": "examples/accrue_host/e2e/verify01-admin-mobile.spec.js",
    "line": null,
    "description": "Host mobile entitlement contract is skipped because the checked-in Playwright config has no chromium-mobile project.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T19:21:33.589Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "215",
    "file": "examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift",
    "line": null,
    "description": "Corrected stale capability case name in the tracer test.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-01T01:55:48.046Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "215",
    "file": "examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift",
    "line": null,
    "description": "Reducer now requires every declared evidence lane before reporting proven.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-01T01:55:48.106Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "217",
    "file": "accrue/test/accrue/docs/package_docs_verifier_test.exs",
    "line": null,
    "description": "mix test.all could not start because unrelated shared dirty file is not formatted",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T01:52:16.732Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "220",
    "file": "examples/accrue_host/test/accrue_host/billing_facade_test.exs",
    "line": 160,
    "description": "Full mix verify could not complete because the pre-existing fake subscription uniqueness test failed.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-04T15:43:48.620Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "220",
    "file": "accrue/lib/accrue/entitlements/snapshot.ex",
    "line": null,
    "description": "Forwarded snapshot :now option to repository folding for frozen expiry-boundary proof.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T02:02:05.577Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "221",
    "file": "examples/accrue_host",
    "line": null,
    "description": "mix verify blocked by unrelated tracked formatting violations before its test suite",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T17:28:54.045Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "221",
    "file": "examples/accrue_host/lib/accrue_host_web/components/layouts.ex",
    "line": null,
    "description": "Full mix format --check-formatted is blocked by unrelated tracked formatting violations in layouts and existing migrations.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T17:40:05.349Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "225",
    "file": "accrue_admin/mix.lock",
    "line": 41,
    "description": "Locked already-declared jose dependency so the Admin Playwright web server starts in a clean checkout.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-09T03:32:55.284Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "unrun-verify",
    "phase": "227",
    "file": ".planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson",
    "line": null,
    "description": "Live three-success critical-path comparison could not run: final bounded cohort had no qualifying successful workflow_dispatch observations.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-13T03:58:20.522Z",
    "resolved_at": null
  }
]
````
