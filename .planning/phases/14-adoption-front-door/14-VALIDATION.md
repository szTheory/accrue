---
phase: 14
slug: adoption-front-door
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-17
---

# Phase 14 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir / Mix |
| **Config file** | none - standard Mix/ExUnit project layout |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/canonical_demo_contract_test.exs test/accrue/docs/first_hour_guide_test.exs` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors` |
| **Estimated runtime** | ~60 seconds for focused docs checks; full suite varies by environment |

---

## Sampling Rate

- **After every task commit:** Run the relevant focused docs-contract test for touched surfaces, or the quick run command if no narrower command is available.
- **After every plan wave:** Run `cd accrue && mix test --warnings-as-errors`.
- **Before `$gsd-verify-work`:** Full suite must be green and `scripts/ci/verify_package_docs.sh` must pass.
- **Max feedback latency:** 60 seconds for focused docs checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | ADOPT-01, ADOPT-02, ADOPT-05, ADOPT-06 | T-14-01 / T-14-03 / T-14-04 | Root README and package landing pages route users into the host-first tutorial, keep public boundaries copy-paste safe, and preserve Fake/test/live labels | docs contract | `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs` | planned in same task | ⬜ pending |
| 14-02-01 | 02 | 1 | ADOPT-04, ADOPT-05 | T-14-01 / T-14-03 | Issue forms warn against secrets, production payloads, customer data, and PII while steering reporters to supported public surfaces | file-shape test | `cd accrue && mix test test/accrue/docs/issue_templates_test.exs` | planned in same task | ⬜ pending |
| 14-03-01 | 03 | 2 | ADOPT-01, ADOPT-03, ADOPT-05, ADOPT-06 | T-14-02 / T-14-03 / T-14-04 | Release docs distinguish required Fake gates from provider-parity and advisory/manual Stripe checks, and the shell verifier locks those labels in place | docs contract + shell verifier | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs && bash ../scripts/ci/verify_package_docs.sh` | planned in same task | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Task-Boundary Verification

Existing infrastructure covers the phase. Each plan now uses a same-task unit where any new docs contract or verifier update is created and then satisfied by the implementation within that task before the task verify runs:

- Plan `14-01` creates the root README/docs contracts and the aligned README surfaces in one task, then runs the full focused docs command.
- Plan `14-02` creates the issue-template contract and the chooser/forms in one task, then runs the issue-template suite.
- Plan `14-03` creates the release-guidance contract, updates release/support docs, extends the shell verifier, and then runs both the focused ExUnit command and shell verifier.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub issue chooser rendering | ADOPT-04 | GitHub UI rendering is platform-hosted and not exercised by local tests | Inspect `.github/ISSUE_TEMPLATE/config.yml` and four issue-form YAML files for valid GitHub issue-form fields before merge |

---

## Threat Model References

| Ref | Threat | Mitigation |
|-----|--------|------------|
| T-14-01 | Public issue forms solicit Stripe keys, webhook secrets, production payloads, customer data, or PII | Top-of-form warnings, required sanitized reproduction fields, no generic support form, and contact links to `SECURITY.md` |
| T-14-02 | Docs imply raw-body webhook verification or endpoint secrets are optional | Preserve links and copy around `use Accrue.Webhook.Handler`, `/webhooks/stripe`, and signed webhook guidance |
| T-14-03 | Public docs teach private modules as stable APIs | Root/package docs repeat only generated `MyApp.Billing`, public macros/helpers, `Accrue.Auth`, and `Accrue.ConfigError` |
| T-14-04 | Release docs make advisory/provider checks look required, blocking normal releases or local evaluation | Label modes as canonical local demo, provider-parity checks, and advisory/manual before shipping |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or same-task test-first dependencies
- [x] Every task verify is satisfiable at that task boundary
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Same-task units cover all previously missing contract files
- [x] No watch-mode flags
- [x] Feedback latency < 60s for focused docs checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
