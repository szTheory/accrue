---
phase: 14-adoption-front-door
verified: 2026-04-17T08:19:10Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 14: Adoption Front Door Verification Report

**Phase Goal:** Make the public repository, package docs, and support surfaces explain what Accrue is, where to start, what is stable, and how to ask for help.
**Verified:** 2026-04-17T08:19:10Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The repository root has a clear front door for Accrue, `accrue_admin`, the local demo, docs, and production hardening. | ✓ VERIFIED | `README.md` contains the front-door headline, package map, local demo link, guide links, `SECURITY.md`, and `RELEASING.md`; `root_readme_test.exs` asserts those invariants. |
| 2 | Package docs and README paths align around the host-first tutorial and public integration boundaries. | ✓ VERIFIED | `accrue/README.md` routes readers to First Hour, troubleshooting, webhooks, testing, upgrade, and the canonical demo; `accrue_admin/README.md` explicitly stays downstream of core setup and links to the admin guide plus First Hour. |
| 3 | Issue templates cover bug reports, integration problems, documentation gaps, and feature requests. | ✓ VERIFIED | `.github/ISSUE_TEMPLATE/config.yml` disables blank issues and exposes exactly four forms; `issue_templates_test.exs` enforces chooser taxonomy and titles. |
| 4 | Release guidance clearly explains Fake, Stripe test mode, live Stripe, and required vs advisory checks. | ✓ VERIFIED | `RELEASING.md` separates `Canonical local demo: Fake`, `Provider parity: Stripe test mode`, and `Advisory/manual: live Stripe`; `release_guidance_test.exs` and `verify_package_docs.sh` guard the wording. |
| 5 | A repository visitor can tell what Accrue is, which package to start with, and where the canonical local demo lives. | ✓ VERIFIED | `README.md` explains what Accrue is, names `accrue` and `accrue_admin`, and points to `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`. |
| 6 | A first-time integrator sees the supported public setup surfaces before internals. | ✓ VERIFIED | `README.md` and `accrue/README.md` list `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `AccrueAdmin.Router.accrue_admin/2`, `Accrue.Auth`, and `Accrue.ConfigError`, while `root_readme_test.exs` forbids private-module guidance. |
| 7 | Public issue intake warns users not to paste secrets, production payloads, customer data, or PII and routes security reports privately. | ✓ VERIFIED | All four issue forms contain the required no-secrets warning; chooser config links to `SECURITY.md` and `CONTRIBUTING.md`; `issue_templates_test.exs` enforces both. |
| 8 | Public docs keep Fake, Stripe test mode, and live Stripe in distinct lanes. | ✓ VERIFIED | `README.md`, `RELEASING.md`, `guides/testing-live-stripe.md`, and `CONTRIBUTING.md` consistently separate deterministic, provider-parity, and advisory lanes. |
| 9 | Drift guards fail if the front-door route map or mode labels regress. | ✓ VERIFIED | `scripts/ci/verify_package_docs.sh`, `root_readme_test.exs`, `release_guidance_test.exs`, and `package_docs_verifier_test.exs` all execute successfully against the current repo state. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `README.md` | Repository front door | ✓ VERIFIED | Contains identity, package map, stable surfaces, Fake/test/live labels, and next-step links. |
| `accrue/README.md` | Compact core package landing page | ✓ VERIFIED | Routes to First Hour and reference guides while restating supported public setup surfaces. |
| `accrue_admin/README.md` | Admin package landing page downstream of core setup | ✓ VERIFIED | Positions admin after core billing/webhook setup and links to HexDocs guides. |
| `.github/ISSUE_TEMPLATE/config.yml` | Support chooser with private/security routing | ✓ VERIFIED | `blank_issues_enabled: false`; links to `SECURITY.md` and `CONTRIBUTING.md`. |
| `.github/ISSUE_TEMPLATE/bug.yml` | Structured bug intake | ✓ VERIFIED | Uses `[Bug]: ` title, no-secrets warning, and public-surface prompts. |
| `.github/ISSUE_TEMPLATE/integration-problem.yml` | Structured integration intake | ✓ VERIFIED | Routes users through First Hour/Troubleshooting and supported surfaces. |
| `.github/ISSUE_TEMPLATE/documentation-gap.yml` | Structured docs-gap intake | ✓ VERIFIED | Asks for missing/wrong doc path and affected public surface. |
| `.github/ISSUE_TEMPLATE/feature-request.yml` | Structured feature intake | ✓ VERIFIED | Anchors requests to user problem, workaround, and public API surface. |
| `RELEASING.md` | Required vs advisory release guidance | ✓ VERIFIED | Separates Fake, Stripe test mode, and live Stripe lanes with explicit release semantics. |
| `guides/testing-live-stripe.md` | Provider-parity detail guide | ✓ VERIFIED | Keeps Stripe test mode in an optional provider-parity lane. |
| `scripts/ci/verify_package_docs.sh` | Fixed-string drift guard | ✓ VERIFIED | Checks README, RELEASING, package versions, demo route map, and release-lane wording. |
| `accrue/test/accrue/docs/root_readme_test.exs` | Root README contract | ✓ VERIFIED | Enforces headline, route map, supported surfaces, and negative private-module assertions. |
| `accrue/test/accrue/docs/issue_templates_test.exs` | Issue-template contract | ✓ VERIFIED | Enforces taxonomy, warnings, and support/security routing. |
| `accrue/test/accrue/docs/release_guidance_test.exs` | Release-guidance contract | ✓ VERIFIED | Enforces required/advisory lane language across release docs. |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | Shell-verifier contract | ✓ VERIFIED | Proves `verify_package_docs.sh` fails on drift in root README and release guidance. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `README.md` | `examples/accrue_host/README.md` | canonical local demo path | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `README.md` | `accrue/guides/first_hour.md` | package-facing tutorial route | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `accrue/README.md` | `accrue/guides/first_hour.md` | compact landing page start path | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `.github/ISSUE_TEMPLATE/config.yml` | `SECURITY.md` | contact links | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `.github/ISSUE_TEMPLATE/integration-problem.yml` | `accrue/guides/first_hour.md` | issue guidance | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `.github/ISSUE_TEMPLATE/bug.yml` | Accrue public surfaces | sanitized reproduction fields | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `RELEASING.md` | `guides/testing-live-stripe.md` | provider-parity detail link | ✓ VERIFIED | `gsd-tools verify key-links` passed. |
| `scripts/ci/verify_package_docs.sh` | `README.md` | front-door fixed invariants | ✓ VERIFIED | Script requires root README lane labels and route map strings. |
| `scripts/ci/verify_package_docs.sh` | `RELEASING.md` | required versus advisory wording checks | ✓ VERIFIED | Script requires release-lane wording strings. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `accrue/test/accrue/docs/root_readme_test.exs` | `readme` | `README.md` on disk | Yes | ✓ FLOWING |
| `accrue/test/accrue/docs/issue_templates_test.exs` | form/config contents | `.github/ISSUE_TEMPLATE/*.yml` on disk | Yes | ✓ FLOWING |
| `accrue/test/accrue/docs/release_guidance_test.exs` | `releasing`, `guide`, `contributing` | `RELEASING.md`, `guides/testing-live-stripe.md`, `CONTRIBUTING.md` on disk | Yes | ✓ FLOWING |
| `scripts/ci/verify_package_docs.sh` | extracted versions + fixed-string checks | `mix.exs`, README files, RELEASING, host demo README | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Docs drift guard passes on current repo state | `bash scripts/ci/verify_package_docs.sh` | `package docs verified for accrue 0.1.2 and accrue_admin 0.1.2` | ✓ PASS |
| Docs contracts pass | `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/issue_templates_test.exs test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/release_guidance_test.exs` | `11 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `ADOPT-01` | 14-01, 14-03 | Root README explains Accrue, packages, local demo, docs, and production-hardening path. | ✓ SATISFIED | `README.md` front door plus `RELEASING.md` production-hardening lane guidance. |
| `ADOPT-02` | 14-01 | User can follow a tutorial through first subscription, signed webhook ingest, admin inspection/replay, and focused tests. | ✓ SATISFIED | Phase 14 routes readers into the Phase 13 canonical tutorial via `README.md`, `accrue/README.md`, and `accrue_admin/README.md` links to `examples/accrue_host/README.md` and `accrue/guides/first_hour.md`. |
| `ADOPT-03` | 14-03 | User can choose between Fake, Stripe test mode, and live Stripe flows. | ✓ SATISFIED | `README.md`, `RELEASING.md`, and `guides/testing-live-stripe.md` all preserve the three-lane model. |
| `ADOPT-04` | 14-02 | User can find issue templates for bug, integration, docs-gap, and feature requests. | ✓ SATISFIED | Chooser config and four YAML forms exist; contract test enforces exact taxonomy. |
| `ADOPT-05` | 14-01, 14-02, 14-03 | User can identify supported public APIs and host-owned boundaries without private modules. | ✓ SATISFIED | Root/core READMEs list stable setup surfaces; issue forms and tests keep support anchored to public boundaries. |
| `ADOPT-06` | 14-01, 14-03 | User-facing docs preserve brand voice and avoid unproven claims. | ✓ SATISFIED | Front door uses established tagline and host-backed claims only; release/provider-parity docs avoid overstating live Stripe requirements. |

### Anti-Patterns Found

No blocker, warning, or informational anti-patterns found in the phase-owned files. The placeholder grep matched YAML `placeholder:` form fields only, not stub implementations.

### Human Verification Required

None.

### Gaps Summary

No gaps found. Phase 14 delivers the repository front door, package doc routing, support intake, and release-lane guidance described in the roadmap and phase plans, and the implemented drift guards are passing against the current codebase.

---

_Verified: 2026-04-17T08:19:10Z_
_Verifier: Claude (gsd-verifier)_
