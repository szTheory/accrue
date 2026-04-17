---
phase: 14
slug: adoption-front-door
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| 14-01-01 | 01 | 1 | ADOPT-01, ADOPT-05, ADOPT-06 | T-14-01 / T-14-03 | Root README routes users without asking for secrets or teaching private APIs | docs contract | `cd accrue && mix test test/accrue/docs/root_readme_test.exs` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 1 | ADOPT-02, ADOPT-05 | T-14-03 | Package/docs links preserve the host-first tutorial and public facade boundaries | docs contract | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/first_hour_guide_test.exs` | ✅ | ⬜ pending |
| 14-02-01 | 02 | 1 | ADOPT-04 | T-14-01 | Issue forms warn against secrets, production payloads, customer data, and PII | file-shape test | `cd accrue && mix test test/accrue/docs/issue_templates_test.exs` | ❌ W0 | ⬜ pending |
| 14-03-01 | 03 | 2 | ADOPT-03, ADOPT-06 | T-14-02 / T-14-04 | Release docs distinguish required Fake gates from provider-parity and advisory/manual Stripe checks | docs contract | `cd accrue && mix test test/accrue/docs/release_guidance_test.exs` | ❌ W0 | ⬜ pending |
| 14-03-02 | 03 | 2 | ADOPT-01, ADOPT-03, ADOPT-05 | T-14-03 / T-14-04 | Shell verifier guards front-door links, mode labels, and public-boundary copy | shell verifier | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/docs/root_readme_test.exs` - stubs for ADOPT-01, ADOPT-03, ADOPT-05, ADOPT-06
- [ ] `accrue/test/accrue/docs/issue_templates_test.exs` - stubs for ADOPT-04 and no-secrets intake rules
- [ ] `accrue/test/accrue/docs/release_guidance_test.exs` - stubs for ADOPT-03 and required/advisory wording
- [ ] `scripts/ci/verify_package_docs.sh` - root README and release-guidance invariants

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s for focused docs checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
