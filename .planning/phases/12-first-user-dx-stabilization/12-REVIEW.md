---
phase: 12-first-user-dx-stabilization
reviewed: 2026-04-16T22:52:36Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - accrue/lib/mix/tasks/accrue.install.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/setup_diagnostic.ex
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/mix/tasks/accrue_install_uat_test.exs
  - accrue/test/accrue/config_test.exs
  - accrue/guides/first_hour.md
  - accrue/guides/troubleshooting.md
  - accrue/test/accrue/docs/first_hour_guide_test.exs
  - accrue/test/accrue/docs/troubleshooting_guide_test.exs
  - scripts/ci/verify_package_docs.sh
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---
# Phase 12: Code Review Report

**Reviewed:** 2026-04-16T22:52:36Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

I reviewed the scoped Phase 12 DX changes at standard depth, with focused validation against the three warnings from the prior review. Two of those are now closed: the docs and verifier consistently use `:webhook_signing_secrets`, and migration lookup failures now raise the shared diagnostic path instead of being swallowed. Installer `--check` also has UAT coverage for the router-shape false positive that was previously reported.

One user-facing docs defect remains: several `Accrue.SetupDiagnostic` links point at anchors that do not exist in `guides/troubleshooting.md`. The current test coverage also misses that contract, which is why the broken deep links still ship.

## Warnings

### WR-01: Troubleshooting guide is missing sections for five shipped diagnostic anchors

**File:** `accrue/guides/troubleshooting.md:111-130`
**Issue:** `Accrue.SetupDiagnostic` publishes docs links for `accrue-dx-oban-not-supervised`, `accrue-dx-webhook-route-missing`, `accrue-dx-webhook-pipeline`, `accrue-dx-auth-adapter`, and `accrue-dx-admin-mount-missing` ([`accrue/lib/accrue/setup_diagnostic.ex:18`](/Users/jon/projects/accrue/accrue/lib/accrue/setup_diagnostic.ex:18), [`accrue/lib/accrue/setup_diagnostic.ex:22`](/Users/jon/projects/accrue/accrue/lib/accrue/setup_diagnostic.ex:22), [`accrue/lib/accrue/setup_diagnostic.ex:24`](/Users/jon/projects/accrue/accrue/lib/accrue/setup_diagnostic.ex:24), [`accrue/lib/accrue/setup_diagnostic.ex:25`](/Users/jon/projects/accrue/accrue/lib/accrue/setup_diagnostic.ex:25), [`accrue/lib/accrue/setup_diagnostic.ex:26`](/Users/jon/projects/accrue/accrue/lib/accrue/setup_diagnostic.ex:26)), but the troubleshooting guide ends after the raw-body section and never defines those anchors. Users clicking those docs links will land on a non-existent fragment instead of the promised exact fix.
**Fix:**
```markdown
## `ACCRUE-DX-OBAN-NOT-SUPERVISED` {#accrue-dx-oban-not-supervised}
...
## `ACCRUE-DX-WEBHOOK-ROUTE-MISSING` {#accrue-dx-webhook-route-missing}
...
## `ACCRUE-DX-WEBHOOK-PIPELINE` {#accrue-dx-webhook-pipeline}
...
## `ACCRUE-DX-AUTH-ADAPTER` {#accrue-dx-auth-adapter}
...
## `ACCRUE-DX-ADMIN-MOUNT-MISSING` {#accrue-dx-admin-mount-missing}
...
```
Add a full section for each code already listed in the matrix so every `docs_path` emitted by `Accrue.SetupDiagnostic` resolves to a real anchor.

### WR-02: Troubleshooting guide test only checks a subset of required anchors

**File:** `accrue/test/accrue/docs/troubleshooting_guide_test.exs:17-22`
**Issue:** The regression test asserts only four anchors, even though the guide and diagnostic module expose ten diagnostic codes. That incomplete check let the five missing troubleshooting sections ship unnoticed. This affects test reliability for a user-facing contract, so the current test does not actually protect the documented setup-diagnostic surface.
**Fix:**
```elixir
@anchors [
  "accrue-dx-repo-config",
  "accrue-dx-migrations-pending",
  "accrue-dx-oban-not-configured",
  "accrue-dx-oban-not-supervised",
  "accrue-dx-webhook-secret-missing",
  "accrue-dx-webhook-route-missing",
  "accrue-dx-webhook-raw-body",
  "accrue-dx-webhook-pipeline",
  "accrue-dx-auth-adapter",
  "accrue-dx-admin-mount-missing"
]
```
Better still, derive the expected anchors from `Accrue.SetupDiagnostic` or keep a single authoritative list shared between the guide contract and the tests.

---

_Reviewed: 2026-04-16T22:52:36Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
