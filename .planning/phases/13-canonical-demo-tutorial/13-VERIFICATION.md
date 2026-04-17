---
phase: 13-canonical-demo-tutorial
verified: 2026-04-17T02:06:22Z
status: human_needed
score: 10/10 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Follow the README on a fresh local machine"
    expected: "Starting from the documented prerequisites, a developer can complete First run, create one Fake-backed subscription, post one signed webhook, inspect /billing, and finish with mix verify without guessing missing steps."
    why_human: "Documentation usability and end-to-end onboarding clarity need a human walkthrough."
  - test: "Inspect the mounted admin flow during the tutorial"
    expected: "The mounted /billing pages, webhook replay surface, and seeded-history/admin states are understandable and match the docs language."
    why_human: "Visual clarity, navigation, and admin-flow comprehension are UI qualities not fully provable with static checks."
---

# Phase 13: Canonical Demo + Tutorial Verification Report

**Phase Goal:** Make `examples/accrue_host` the canonical local evaluation path for Accrue and document it as a tutorial from clone through first subscription and admin inspection.
**Verified:** 2026-04-17T02:06:22Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A new user can run the local host demo from documented prerequisites and commands without live Stripe credentials. | ✓ VERIFIED | `examples/accrue_host/README.md` documents PostgreSQL, `mix setup`, `mix phx.server`, Fake-backed defaults, and explicitly says live Stripe credentials are not required. `accrue/guides/first_hour.md` mirrors the same Fake-backed path. |
| 2 | The canonical tutorial teaches a first Fake-backed subscription through host-owned boundaries. | ✓ VERIFIED | `examples/accrue_host/README.md` teaches `Start subscription` through `AccrueHost.Billing`; `accrue/guides/first_hour.md` teaches `MyApp.Billing.subscribe`; `examples/accrue_host/test/accrue_host/billing_facade_test.exs` proves `Billing.subscribe/3` creates a fake-backed subscription. |
| 3 | The demo proves signed webhook ingest, mounted admin inspection, replay visibility, and focused host tests. | ✓ VERIFIED | `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` covers signed `/webhooks/stripe` ingest and idempotency; `admin_mount_test.exs` covers `/billing` admin gating; `admin_webhook_replay_test.exs` covers admin inspection and replay; `mix verify` wires those proofs into the tutorial contract. |
| 4 | A maintainer can run `cd examples/accrue_host && mix verify` for the focused tutorial proof suite. | ✓ VERIFIED | `examples/accrue_host/mix.exs` defines `verify` with the six locked proof files; orchestrator gate `cd accrue && mix test ...` passed and `bash scripts/ci/accrue_host_uat.sh` also passed through the delegated full contract. |
| 5 | A maintainer can run `cd examples/accrue_host && mix verify.full` as the CI-equivalent local gate. | ✓ VERIFIED | `examples/accrue_host/mix.exs` defines `verify.full` as `verify.install`, `verify`, compile warnings, assets build, regression, dev boot, and browser smoke. User-provided gate `bash scripts/ci/accrue_host_uat.sh` passed, including Phoenix boot smoke and Playwright e2e, which exercises `mix verify.full`. |
| 6 | The repo-root wrapper delegates to the same full contract instead of maintaining a second command graph. | ✓ VERIFIED | `scripts/ci/accrue_host_uat.sh` now exports env passthrough and ends with `cd "$host_dir"` plus `mix verify.full`. `examples/accrue_host/test/repo_wrapper_contract_test.exs` asserts delegation and absence of embedded proof-file lists. |
| 7 | Maintainers can detect drift between the canonical demo contract and the tutorial docs before release. | ✓ VERIFIED | `accrue/test/accrue/docs/canonical_demo_contract_test.exs` reads the manifest and checks README/guide/wrapper parity; `scripts/ci/verify_package_docs.sh` checks fixed invariants; orchestrator gate for the docs tests passed with 81 tests, 0 failures. |
| 8 | The docs contract forbids private setup surfaces in the public `First run` story. | ✓ VERIFIED | `accrue/test/accrue/docs/first_hour_guide_test.exs` asserts required public surfaces, rejects internal modules like `Accrue.Billing.Customer`, and rejects singular `webhook_signing_secret`; `accrue/guides/first_hour.md` uses only public host-facing surfaces. |
| 9 | Mode labels and command order stay in parity across docs, tests, and shell verification. | ✓ VERIFIED | `examples/accrue_host/demo/command_manifest.exs` stores `First run`, `Seeded history`, `mix verify`, `mix verify.full`, and wrapper labels; `canonical_demo_contract_test.exs` and `first_hour_guide_test.exs` consume that manifest; `verify_package_docs.sh` checks the fixed labels. |
| 10 | The docs clearly separate `First run`, `Seeded history`, `mix verify`, `mix verify.full`, Hex smoke, and production setup. | ✓ VERIFIED | `examples/accrue_host/README.md` has `First run`, `Seeded history`, and `Verification modes`; `accrue/guides/first_hour.md` has matching numbered sections and explains focused/full/wrapper/Hex/production modes distinctly. |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/accrue_host/demo/command_manifest.exs` | Shared ordered command and mode metadata | ✓ VERIFIED | Exists, substantive, and consumed by docs tests. |
| `examples/accrue_host/mix.exs` | Host-local Mix aliases for setup, verify, and verify.full | ✓ VERIFIED | Defines `verify`, `verify.full`, and the focused/full command graphs. |
| `scripts/ci/accrue_host_uat.sh` | Thin repo-root wrapper around the host-local full contract | ✓ VERIFIED | Delegates to `mix verify.full`; review fix for `PGPORT` and `PGDATABASE` is present. |
| `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | Manifest-backed README/guide/wrapper parity coverage | ✓ VERIFIED | Exists and reads the manifest directly. |
| `accrue/test/accrue/docs/first_hour_guide_test.exs` | Public-boundary and forbidden-surface contract checks | ✓ VERIFIED | Exists and asserts public/forbidden surfaces plus label order. |
| `scripts/ci/verify_package_docs.sh` | Fixed-invariant package-doc verification | ✓ VERIFIED | Exists and checks labels, anchors, links, and version invariants. |
| `examples/accrue_host/README.md` | Canonical clone-to-running tutorial for the checked-in host app | ✓ VERIFIED | Contains the canonical first-run, seeded-history, and verification split. |
| `accrue/guides/first_hour.md` | Package-facing tutorial mirror of the canonical host demo path | ✓ VERIFIED | Mirrors the host story with public-boundary package guidance. |
| `accrue/README.md` | Compact package README orientation toward the canonical tutorial | ✓ VERIFIED | Links into First Hour and the checked-in demo without duplicating the tutorial. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scripts/ci/accrue_host_uat.sh` | `examples/accrue_host/mix.exs` | repo-root wrapper calls host-local verify.full | ✓ WIRED | `gsd-tools verify key-links` found the `mix verify.full` delegation pattern. |
| `accrue/test/accrue/docs/canonical_demo_contract_test.exs` | `examples/accrue_host/demo/command_manifest.exs` | reads manifest to assert labels and command order | ✓ WIRED | `command_manifest()` loads the host manifest module and uses its labels. |
| `scripts/ci/verify_package_docs.sh` | `accrue/test/accrue/docs/package_docs_verifier_test.exs` | shell verifier is exercised by ExUnit | ✓ WIRED | The ExUnit wrapper runs the shell verifier in both green-path and drift-path modes. |
| `examples/accrue_host/README.md` | `accrue/guides/first_hour.md` | same ordered story and command labels | ✓ WIRED | Both surfaces carry `First run`, `Seeded history`, `mix verify`, and `mix verify.full`. |
| `accrue/README.md` | `accrue/guides/first_hour.md` | orientation link into the package-facing tutorial | ✓ WIRED | `accrue/README.md` links to `guides/first_hour.md` and references the canonical verification labels. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/accrue_host/demo/command_manifest.exs` | command labels and story artifacts | Static Elixir manifest consumed by tests/docs | Yes - concrete command strings and labels | ✓ FLOWING |
| `examples/accrue_host/mix.exs` | `verify` / `verify.full` alias graph | Mix aliases invoking focused proofs, dev boot, and browser smoke | Yes - exercised by the passed host UAT gate | ✓ FLOWING |
| `scripts/ci/accrue_host_uat.sh` | repo-root execution path | Environment passthrough plus `mix verify.full` delegation | Yes - passed in orchestrator gate | ✓ FLOWING |
| `examples/accrue_host/README.md` | tutorial commands and surfaces | Human-written doc constrained by manifest-backed docs tests | Yes - labels and commands are contract-checked | ✓ FLOWING |
| `accrue/guides/first_hour.md` | package tutorial steps | Human-written guide constrained by manifest-backed docs tests | Yes - ordered steps and boundaries are contract-checked | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs contracts stay green | `cd accrue && mix test --warnings-as-errors test/accrue/docs/troubleshooting_guide_test.exs test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/package_docs_verifier_test.exs` | Passed: 81 tests, 0 failures | ✓ PASS |
| Canonical full demo gate runs through the delegated wrapper | `bash scripts/ci/accrue_host_uat.sh` | Passed, including host tests, Phoenix boot smoke, and Playwright e2e | ✓ PASS |
| Generated host/install surface stays in sync | Schema drift check | `drift_detected=false` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DEMO-01 | 13-03 | User can clone the repository and run `examples/accrue_host` as the canonical local demo with documented prerequisites and commands. | ✓ SATISFIED | Host README documents prerequisites and the exact clone-to-run sequence; First Hour guide points to the checked-in host demo as canonical. |
| DEMO-02 | 13-03 | User can seed or create a Fake-backed subscription in the demo without live Stripe credentials. | ✓ SATISFIED | README and First Hour guide explicitly teach Fake-backed flow; `billing_facade_test.exs` proves fake-backed subscription creation. |
| DEMO-03 | 13-03 | User can inspect billing state and replay a webhook/admin action through the mounted admin UI in the demo. | ✓ SATISFIED | README and guide teach `/billing`; `admin_mount_test.exs` and `admin_webhook_replay_test.exs` verify mount, inspection, and replay. |
| DEMO-04 | 13-01, 13-03 | User can run a single CI-equivalent local command that verifies the demo setup and focused host proofs. | ✓ SATISFIED | `mix verify.full` is the CI-equivalent gate; repo-root wrapper delegates to it; wrapper gate passed. |
| DEMO-05 | 13-01, 13-02, 13-03 | User can understand which demo commands are for local evaluation, CI validation, Hex-style smoke validation, and production setup. | ✓ SATISFIED | Manifest, host README, guide, and package README all distinguish `mix verify`, `mix verify.full`, wrapper, Hex smoke, and production setup. |
| DEMO-06 | 13-01, 13-02 | Maintainer can detect drift between the demo path and documented tutorial commands before release. | ✓ SATISFIED | Manifest-backed docs tests and `verify_package_docs.sh` enforce parity and fixed invariants. |
| ADOPT-02 | 13-03 | User can follow a tutorial from install through first subscription, signed webhook ingest, admin inspection/replay, and focused host tests. | ✓ SATISFIED | `accrue/guides/first_hour.md` covers install, runtime config, first subscription, signed webhook ingest, mounted admin inspection/replay, and `mix verify`. |

No orphaned Phase 13 requirements were found in `.planning/REQUIREMENTS.md`; all requirement IDs claimed by the phase plans are accounted for.

### Anti-Patterns Found

No blocking or warning anti-patterns were found in the phase-modified files. The review findings in `13-REVIEW.md` were confirmed fixed in code:

- `scripts/ci/accrue_host_uat.sh` now forwards `PGPORT` and optional `PGDATABASE` in the `pg_isready` probe.
- `accrue/test/accrue/docs/canonical_demo_contract_test.exs` and `accrue/test/accrue/docs/first_hour_guide_test.exs` now fail with explicit assertion messages instead of crashing on missing first labels.

### Human Verification Required

### 1. Fresh Clone Walkthrough

**Test:** On a fresh local environment with PostgreSQL running, follow `examples/accrue_host/README.md` exactly through `First run`.
**Expected:** The evaluator reaches one Fake-backed subscription, one signed webhook proof, `/billing` inspection, and a successful `mix verify` without undocumented setup.
**Why human:** This checks tutorial clarity, pacing, and whether the docs feel complete to a new evaluator.

### 2. Admin Flow Readability

**Test:** Walk the `/billing` admin pages during both `First run` and `Seeded history`, including webhook replay visibility.
**Expected:** The UI labels, admin states, and replay surface are understandable and line up with the docs wording.
**Why human:** Visual comprehension and admin UX quality are not fully captured by static assertions or backend/browser-smoke checks.

---

_Verified: 2026-04-17T02:06:22Z_
_Verifier: Claude (gsd-verifier)_
