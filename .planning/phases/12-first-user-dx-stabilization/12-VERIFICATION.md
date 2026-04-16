---
phase: 12-first-user-dx-stabilization
verified: 2026-04-16T22:55:21Z
status: gaps_found
score: 3/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "Installer `--check` no longer flags valid host-style routers as `ACCRUE-DX-WEBHOOK-PIPELINE`, and runtime auth adapters from `config/runtime.exs` are honored."
    - "Migration lookup failures now raise `Accrue.ConfigError` with `ACCRUE-DX-MIGRATIONS-PENDING` instead of being swallowed."
    - "Published docs and verifier checks now use `:webhook_signing_secrets` and reject singular `webhook_signing_secret` drift."
  gaps_remaining:
    - "Troubleshooting deep links are incomplete: five `Accrue.SetupDiagnostic` docs anchors point at fragments that do not exist in `guides/troubleshooting.md`."
  regressions:
    - "The troubleshooting guide contract test still checks only four anchors, so the missing deep-link sections ship without failing automation."
gaps:
  - truth: "Common setup failures for config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable messages."
    status: partial
    reason: "The diagnostic taxonomy is wired and the prior router/migration defects are fixed, but five shipped `docs_path` anchors still resolve to nowhere, so affected messages are not fully actionable from the emitted docs link."
    artifacts:
      - path: "accrue/lib/accrue/setup_diagnostic.ex"
        issue: "Publishes docs fragments for `accrue-dx-oban-not-supervised`, `accrue-dx-webhook-route-missing`, `accrue-dx-webhook-pipeline`, `accrue-dx-auth-adapter`, and `accrue-dx-admin-mount-missing`."
      - path: "accrue/guides/troubleshooting.md"
        issue: "Defines detailed sections only through `ACCRUE-DX-WEBHOOK-RAW-BODY`; the five later anchor targets do not exist."
    missing:
      - "Add full troubleshooting sections for the five emitted diagnostic anchors so every `docs_path` fragment resolves."
  - truth: "Quickstart and troubleshooting docs follow the host-app path without skipped setup steps."
    status: partial
    reason: "The host-first guide and webhook secret config are now correct, but troubleshooting still stops before five shipped diagnostic sections, leaving the remediation path incomplete."
    artifacts:
      - path: "accrue/guides/troubleshooting.md"
        issue: "Matrix rows exist for all ten diagnostics, but detailed remediation sections exist for only five."
      - path: "accrue/test/accrue/docs/troubleshooting_guide_test.exs"
        issue: "Anchor coverage only asserts four fragments, so the missing sections are not protected by tests."
    missing:
      - "Extend the troubleshooting guide with detailed sections for all emitted diagnostics."
      - "Expand the guide contract test to assert all required anchors, ideally from one authoritative list."
---

# Phase 12: First-User DX Stabilization Verification Report

**Phase Goal:** The first-hour experience for a Phoenix developer is tightened using failures and friction discovered by the host app: installer behavior, setup errors, docs, diagnostics, and public API clarity.
**Verified:** 2026-04-16T22:55:21Z
**Status:** gaps_found
**Re-verification:** Yes - after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Re-running the installer against the host app is idempotent and does not clobber user-owned files. | ✓ VERIFIED | Installer regression suites and Hex smoke passed; rerun output still preserves user-edited files and conflict artifacts. |
| 2 | Common setup failures for config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable messages. | ✗ FAILED | Router false positives and migration swallowing are fixed, but five `Accrue.SetupDiagnostic` docs links point at anchors missing from the troubleshooting guide. |
| 3 | Quickstart and troubleshooting docs follow the host-app path without skipped setup steps. | ✗ FAILED | `first_hour.md` now teaches `:webhook_signing_secrets`, but `troubleshooting.md` stops after `ACCRUE-DX-WEBHOOK-RAW-BODY` and omits five detailed remediation sections. |
| 4 | The host app validates both path-dependency development and Hex-style dependency modes. | ✓ VERIFIED | `scripts/ci/accrue_host_hex_smoke.sh` passed end to end. |
| 5 | Package docs retain correct version snippets, source links, and internal HexDocs guide links. | ✓ VERIFIED | `scripts/ci/verify_package_docs.sh` and its ExUnit wrapper passed on current metadata and guides. |

**Score:** 3/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/mix/tasks/accrue.install.ex` | Scope-aware webhook preflight and host-auth-aware installer check | ✓ VERIFIED | `webhook_route_contexts/1` scopes the check to mounted webhook context, and auth-adapter detection inspects runtime config too. |
| `accrue/lib/accrue/config.ex` | Migration inspection failures mapped to shared setup diagnostics | ✓ VERIFIED | `ensure_migrations_current!/1` raises `Accrue.ConfigError` for expected lookup failures and reraises unexpected exceptions. |
| `accrue/guides/first_hour.md` | Canonical host-first setup guide with correct runtime webhook config | ✓ VERIFIED | Uses `config :accrue, :webhook_signing_secrets, %{...}` and passed its contract test. |
| `accrue/guides/troubleshooting.md` | Troubleshooting guide with stable anchors for shipped diagnostics | ⚠️ PARTIAL | Matrix rows cover all codes, but detailed anchored sections exist only for repo, migrations, Oban-not-configured, webhook-secret-missing, and webhook-raw-body. |
| `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | Contract coverage for troubleshooting anchors | ⚠️ PARTIAL | Checks all codes but only four anchors, so missing deep-link sections do not fail tests. |
| `scripts/ci/verify_package_docs.sh` | Strict package/docs drift verifier including webhook config key guard | ✓ VERIFIED | Enforces plural webhook secret config and rejects singular drift in both published guides. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `accrue/lib/mix/tasks/accrue.install.ex` | `accrue/test/mix/tasks/accrue_install_test.exs` | `ACCRUE-DX-WEBHOOK-PIPELINE` regression cases | ✓ WIRED | Tests cover both mis-scoped and valid host-style routers. |
| `accrue/lib/accrue/config.ex` | `accrue/lib/accrue/setup_diagnostic.ex` | `ACCRUE-DX-MIGRATIONS-PENDING` | ✓ WIRED | Boot validation reuses the shared diagnostic constructor. |
| `accrue/guides/first_hour.md` | `accrue/test/accrue/docs/first_hour_guide_test.exs` | Host-first guide contract | ✓ WIRED | Contract asserts ordered steps and the plural webhook config key. |
| `scripts/ci/verify_package_docs.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | Shell verifier wrapper | ✓ WIRED | Wrapper proves verifier success and singular-key failure mode via temp fixture. |
| `accrue/lib/accrue/setup_diagnostic.ex` | `accrue/guides/troubleshooting.md` | `docs_path` fragments | ✗ NOT_WIRED | Anchors for `oban-not-supervised`, `webhook-route-missing`, `webhook-pipeline`, `auth-adapter`, and `admin-mount-missing` are emitted but not defined in the guide. |
| `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | `accrue/guides/troubleshooting.md` | Anchor assertions | ⚠️ PARTIAL | The test asserts only four anchors, not the full diagnostic surface. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | `customer`, `subscription` | `AccrueHost.Billing.billing_state_for/1` -> Repo queries | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Migration diagnostics contract | `cd accrue && mix test test/accrue/config_test.exs` | 33 tests, 0 failures | ✓ PASS |
| Installer rerun and preflight regressions | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | 20 tests, 0 failures | ✓ PASS |
| Guide and package-doc contracts | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Package-doc shell verifier | `bash scripts/ci/verify_package_docs.sh` | `package docs verified for accrue 0.1.2 and accrue_admin 0.1.2` | ✓ PASS |
| Hex dependency smoke | `bash scripts/ci/accrue_host_hex_smoke.sh` | deps, installer rerun, compile, migrate, and focused host tests all passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DX-01 | 12-02, 12-03 | Installer output and generated files remain idempotent on rerun. | ✓ SATISFIED | Installer regression suites and Hex smoke passed. |
| DX-02 | 12-05, 12-09 | Setup failures produce actionable errors. | ✗ BLOCKED | Diagnostics exist and prior code defects are fixed, but five emitted troubleshooting deep links resolve to missing anchors. |
| DX-03 | 12-01, 12-06, 12-10 | Quickstart docs follow the host-app path without skipped setup steps. | ✓ SATISFIED | `first_hour.md` teaches the host-first sequence and correct webhook runtime config. |
| DX-04 | 12-01, 12-06, 12-10 | Troubleshooting docs cover likely first-hour failures. | ✗ BLOCKED | The guide matrix names all ten diagnostics, but detailed sections are missing for five shipped anchors. |
| DX-05 | 12-01, 12-04, 12-06 | Public APIs are documented without private module knowledge. | ✓ SATISFIED | First Hour guide contract still guards public-vs-private boundary and host facade usage. |
| DX-06 | 12-01, 12-07, 12-10 | Package docs metadata and links remain correct. | ✓ SATISFIED | Shell verifier and ExUnit wrapper passed; webhook config drift guard is active. |
| DX-07 | 12-02, 12-08 | Host app supports both path and Hex dependency validation. | ✓ SATISFIED | Hex smoke passed on the canonical host app. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/guides/troubleshooting.md` | 111 | Detailed troubleshooting sections stop at `ACCRUE-DX-WEBHOOK-RAW-BODY`. | 🛑 Blocker | Five shipped diagnostic docs links land on non-existent fragments. |
| `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | 17 | Anchor contract asserts only four anchors. | 🛑 Blocker | Automation misses broken troubleshooting deep links for half the diagnostic surface. |

### Human Verification Required

None. The remaining failures are objective docs and test-contract gaps.

### Gaps Summary

Re-verification closed the two explicit blockers from the prior report. The installer preflight now behaves correctly on valid host routers, migration lookup failures no longer silently return `:ok`, and the docs/verifier drift around `:webhook_signing_secrets` is fixed and guarded.

Phase 12 still does not meet its goal because the troubleshooting deep-link surface is incomplete. `Accrue.SetupDiagnostic` emits ten stable docs fragments, but [accrue/guides/troubleshooting.md](/Users/jon/projects/accrue/accrue/guides/troubleshooting.md#L111) only defines detailed sections through `ACCRUE-DX-WEBHOOK-RAW-BODY`, and [accrue/test/accrue/docs/troubleshooting_guide_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/troubleshooting_guide_test.exs#L17) only checks four anchors. A first user hitting `ACCRUE-DX-OBAN-NOT-SUPERVISED`, `ACCRUE-DX-WEBHOOK-ROUTE-MISSING`, `ACCRUE-DX-WEBHOOK-PIPELINE`, `ACCRUE-DX-AUTH-ADAPTER`, or `ACCRUE-DX-ADMIN-MOUNT-MISSING` still gets a broken remediation link.

---

_Verified: 2026-04-16T22:55:21Z_  
_Verifier: Claude (gsd-verifier)_
