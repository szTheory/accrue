---
schema_version: 1
open_count: 4
waived_count: 0
fixed_count: 0
total_count: 4
last_updated: 2026-08-03T01:52:16.732Z
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
  }
]
````
