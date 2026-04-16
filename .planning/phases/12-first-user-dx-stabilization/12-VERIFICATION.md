---
phase: 12-first-user-dx-stabilization
verified: 2026-04-16T22:31:21Z
status: gaps_found
score: 3/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Common setup failures for config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable messages."
    status: failed
    reason: "Two Phase 12 diagnostic paths are still wrong in live code: installer `--check` can flag a valid router as `ACCRUE-DX-WEBHOOK-PIPELINE`, and boot validation swallows migration lookup failures instead of surfacing a shared diagnostic."
    artifacts:
      - path: "accrue/lib/mix/tasks/accrue.install.ex"
        issue: "`webhook_pipeline_misused?/1` matches unrelated browser/auth pipeline strings anywhere in the router file."
      - path: "accrue/lib/accrue/config.ex"
        issue: "`ensure_migrations_current!/1` rescues all exceptions from `Ecto.Migrator.migrations/0` and returns `:ok`."
    missing:
      - "Make webhook pipeline preflight scope-aware so valid routers do not get false DX failures."
      - "Convert migration lookup failures into `Accrue.ConfigError` with `ACCRUE-DX-MIGRATIONS-PENDING` or another explicit setup diagnostic instead of suppressing them."
  - truth: "Quickstart and troubleshooting docs follow the host-app path without skipped setup steps."
    status: failed
    reason: "The published First Hour guide and troubleshooting matrix tell users to configure `webhook_signing_secret`, but runtime code only reads `:webhook_signing_secrets`."
    artifacts:
      - path: "accrue/guides/first_hour.md"
        issue: "Runtime config example uses the singular key `webhook_signing_secret`."
      - path: "accrue/guides/troubleshooting.md"
        issue: "The `ACCRUE-DX-WEBHOOK-SECRET-MISSING` fix text repeats the singular key."
    missing:
      - "Update both guides to document `config :accrue, :webhook_signing_secrets, %{stripe: ...}`."
      - "Extend package/docs verification so this config-key drift is caught automatically."
---

# Phase 12: First-User DX Stabilization Verification Report

**Phase Goal:** The first-hour experience for a Phoenix developer is tightened using failures and friction discovered by the host app: installer behavior, setup errors, docs, diagnostics, and public API clarity.
**Verified:** 2026-04-16T22:31:21Z
**Status:** gaps_found
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Re-running the installer against the host app is idempotent and does not clobber user-owned files. | ✓ VERIFIED | `Accrue.Install.Fingerprints.write/3` preserves stamped user-edited files and writes `.accrue/conflicts` artifacts; installer unit/UAT tests passed; `bash scripts/ci/accrue_host_hex_smoke.sh` passed. |
| 2 | Common setup failures for config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable messages. | ✗ FAILED | Shared diagnostics exist, but `accrue/lib/mix/tasks/accrue.install.ex` still misclassifies valid routers, and `accrue/lib/accrue/config.ex` still swallows migration lookup exceptions. |
| 3 | Quickstart and troubleshooting docs follow the host-app path without skipped setup steps. | ✗ FAILED | Host-first docs and contracts exist, but `accrue/guides/first_hour.md` and `accrue/guides/troubleshooting.md` still document the wrong webhook secret key. |
| 4 | The host app validates both path-dependency development and Hex-style dependency modes. | ✓ VERIFIED | `examples/accrue_host/mix.exs` switches on `ACCRUE_HOST_HEX_RELEASE`; `scripts/ci/accrue_host_hex_smoke.sh` passed; `.github/workflows/ci.yml` runs the smoke step. |
| 5 | Package docs retain correct version snippets, source links, and internal HexDocs guide links. | ✓ VERIFIED | `scripts/ci/verify_package_docs.sh` passed and `accrue/test/accrue/docs/package_docs_verifier_test.exs` passed against current `mix.exs` and README metadata. |

**Score:** 3/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue/lib/accrue/install/fingerprints.ex` | No-clobber stamped writes and conflict artifacts | ✓ VERIFIED | Writes pristine updates, skips edited generated files, and emits `.accrue/conflicts` paths. |
| `accrue/lib/accrue/install/patches.ex` | Manual patch conflict artifacts | ✓ VERIFIED | Emits patch snippets and conflict artifacts for manual follow-up. |
| `accrue/lib/mix/tasks/accrue.install.ex` | Summary output and shared diagnostic preflight | ⚠️ HOLLOW | Summary and check flow exist, but webhook pipeline detection is over-broad. |
| `accrue/lib/accrue/setup_diagnostic.ex` | Stable code/summary/fix/docs formatting with redaction | ✓ VERIFIED | Ten DX codes, docs anchors, redaction, and formatter present. |
| `accrue/lib/accrue/config.ex` | Boot-time repo/migration/Oban/webhook diagnostics | ⚠️ HOLLOW | Webhook/Oban diagnostics exist, but migration lookup failures can escape as success. |
| `accrue/lib/accrue/webhook/plug.ex` | Generic HTTP failures with actionable redacted logs | ✓ VERIFIED | Uses shared diagnostics for raw-body setup errors and returns generic 500/400 bodies. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | Host-facing billing read helper | ✓ VERIFIED | `billing_state_for/1` returns current customer/subscription via Repo queries. |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | UI reads through host facade | ✓ VERIFIED | Calls `Billing.billing_state_for/1` in `load_state/1`. |
| `accrue/guides/first_hour.md` | Canonical host-first setup guide | ✗ FAILED | Structure is correct, but runtime config example uses the wrong webhook key. |
| `accrue/guides/troubleshooting.md` | Troubleshooting matrix with stable anchors | ✗ FAILED | Matrix and anchors exist, but webhook secret fix text uses the wrong key. |
| `scripts/ci/verify_package_docs.sh` | Strict package-doc verifier | ✓ VERIFIED | Parses versions, checks source refs, README snippets, and HexDocs links. |
| `scripts/ci/accrue_host_hex_smoke.sh` | Hex-mode validation entrypoint | ✓ VERIFIED | Re-runs deps, installer, compile, migrations, and focused host proofs. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `accrue/test/accrue/docs/first_hour_guide_test.exs` | `accrue/guides/first_hour.md` | `@guide` + `File.read!` | ✓ WIRED | Contract test reads the guide directly and passed. |
| `accrue/test/accrue/docs/troubleshooting_guide_test.exs` | `accrue/guides/troubleshooting.md` | `@guide` + `File.read!` | ✓ WIRED | Contract test reads the guide directly and passed. |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | `scripts/ci/verify_package_docs.sh` | `System.cmd/3` | ✓ WIRED | Test shells into the repo verifier and passed. |
| `accrue/lib/accrue/install/fingerprints.ex` | `accrue/lib/mix/tasks/accrue.install.ex` | write-result tuples and summary labels | ✓ WIRED | Installer consumes changed/skipped/conflict tuples for user-visible summaries. |
| `accrue/lib/accrue/install/patches.ex` | `accrue/lib/mix/tasks/accrue.install.ex` | manual patch conflict reporting | ✓ WIRED | Manual patch results become installer output and conflict artifact counts. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | `Billing.billing_state_for/1` | ✓ WIRED | LiveView calls the facade in `load_state/1`. |
| `examples/accrue_host/mix.exs` | `scripts/ci/accrue_host_hex_smoke.sh` | `ACCRUE_HOST_HEX_RELEASE=1` | ✓ WIRED | Script exports the env switch consumed by `hex_release?/0`. |
| `.github/workflows/ci.yml` | `scripts/ci/accrue_host_hex_smoke.sh` | dedicated CI step | ✓ WIRED | Workflow runs `bash scripts/ci/accrue_host_hex_smoke.sh`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | `customer`, `subscription` | `AccrueHost.Billing.billing_state_for/1` -> `Repo.one()` queries over `Accrue.Billing.Customer` and `Accrue.Billing.Subscription` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Package-doc verifier succeeds on current metadata | `bash scripts/ci/verify_package_docs.sh` | Printed `package docs verified for accrue 0.1.2 and accrue_admin 0.1.2` | ✓ PASS |
| Package-doc ExUnit wrapper exercises the verifier | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | 1 test, 0 failures | ✓ PASS |
| Installer no-clobber and conflict taxonomy hold | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs --seed 0` | 12 tests, 0 failures | ✓ PASS |
| Installer UAT contracts hold | `cd accrue && mix test test/mix/tasks/accrue_install_uat_test.exs --seed 0` | 5 tests, 0 failures | ✓ PASS |
| Host facade/path-mode proof files hold | `cd examples/accrue_host && MIX_ENV=test mix test test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs --seed 0` | 11 tests, 0 failures | ✓ PASS |
| Hex-mode smoke path works end to end | `bash scripts/ci/accrue_host_hex_smoke.sh` | Installer + compile + migrations + focused host proofs passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DX-01 | 12-02, 12-03 | Installer output and generated files stay idempotent on rerun. | ✓ SATISFIED | Fingerprint/no-clobber code exists; installer tests and UAT passed; Hex smoke reran installer successfully. |
| DX-02 | 12-05 | Setup failures produce actionable errors. | ✗ BLOCKED | Shared diagnostics exist, but valid routers can fail `--check` and migration lookup failures can be silently ignored. |
| DX-03 | 12-01, 12-06 | Quickstart docs follow the host-app path without skipped steps. | ✗ BLOCKED | First Hour guide is host-first, but the runtime config example documents an unread config key. |
| DX-04 | 12-01, 12-06 | Troubleshooting docs cover likely first-hour failures. | ✗ BLOCKED | Troubleshooting matrix exists with stable anchors, but the webhook-secret fix points users at the wrong key. |
| DX-05 | 12-01, 12-04, 12-06 | Public APIs are documented without private module knowledge. | ✓ SATISFIED | README/guide emphasize `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`; host UI reads through `AccrueHost.Billing`. |
| DX-06 | 12-01, 12-07 | Package version snippets, source links, and HexDocs guide links remain correct. | ✓ SATISFIED | Strict package-doc verifier and wrapper passed against current package metadata. |
| DX-07 | 12-02, 12-08 | Host app supports both path and Hex dependency validation. | ✓ SATISFIED | `hex_release?/0` switch exists, CI invokes Hex smoke, and the Hex smoke script passed locally. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `accrue/guides/first_hour.md` | 45 | Wrong config key (`webhook_signing_secret`) | 🛑 Blocker | First-hour docs direct users into a guaranteed webhook-secret failure. |
| `accrue/guides/troubleshooting.md` | 13 | Wrong remediation key (`webhook_signing_secret`) | 🛑 Blocker | Troubleshooting sends users to the same broken config path instead of the real runtime setting. |
| `accrue/lib/mix/tasks/accrue.install.ex` | 362 | Router-wide string match for webhook pipeline misuse | 🛑 Blocker | Valid Phoenix routers can fail installer preflight despite correct webhook scoping. |
| `accrue/lib/accrue/config.ex` | 491 | Rescue-all migration lookup swallow | 🛑 Blocker | Boot validation can report success when migration state cannot be inspected. |

### Human Verification Required

None. The blocking issues are code/docs correctness failures, not visual or subjective checks.

### Gaps Summary

Phase 12 clearly delivered most of the intended surface: installer rerun safety is real, the host app exposes a thin public billing facade, the package-doc verifier is live, and both path-mode and Hex-mode host validation passed. The phase still misses the goal because the first-hour docs and troubleshooting guidance are wrong on a critical webhook config key, and two setup-diagnostic paths still fail the "actionable and trustworthy" bar. A new user can still be pointed into a broken config path, and a valid router or broken migration lookup can be misreported.

---

_Verified: 2026-04-16T22:31:21Z_
_Verifier: Claude (gsd-verifier)_
