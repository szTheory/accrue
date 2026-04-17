---
phase: 14
slug: adoption-front-door
status: verified
threats_open: 0
asvs_level: default
created: 2026-04-17
---

# Phase 14 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| public repo visitor -> repository docs | Untrusted readers may copy snippets directly from README surfaces into real apps. | Public setup guidance, links, validation-lane labels |
| repository docs -> package/public APIs | Front-door wording defines which Accrue surfaces are treated as stable by adopters. | Public API names, generated host-owned boundary guidance |
| public GitHub user -> issue forms | Untrusted public issue content crosses into permanent repository support surfaces. | Sanitized reproduction context, public-surface references |
| issue chooser -> support/security routing | Public support intake must not replace private vulnerability reporting. | Support taxonomy, vulnerability disclosure links |
| maintainer docs -> release decisions | Release wording changes which checks maintainers believe are required blockers. | Release gate labels, required/advisory check guidance |
| provider-parity guide -> contributor behavior | Readers may over-trust or under-trust Stripe-backed checks based on wording. | Credential handling guidance, provider-parity scope |

---

## Security Verification

**Phase:** 14 - adoption-front-door
**ASVS Level:** default
**Block On:** open
**Threats Open:** 0

### Threat Verification

| Threat ID | Category | Component | Disposition | Status | Evidence |
|-----------|----------|-----------|-------------|--------|----------|
| T-14-01-01 | I | README.md | accept | CLOSED | Accepted risk logged below. Plan 14-01 limits this surface to support/security routing rather than secret intake. |
| T-14-01-02 | T | README.md, accrue/README.md | mitigate | CLOSED | [README.md](/Users/jon/projects/accrue/README.md#L11), [README.md](/Users/jon/projects/accrue/README.md#L36), [accrue/README.md](/Users/jon/projects/accrue/accrue/README.md#L13), [accrue/README.md](/Users/jon/projects/accrue/accrue/README.md#L15), [root_readme_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/root_readme_test.exs#L52) |
| T-14-01-03 | T | README.md, accrue/README.md, accrue_admin/README.md | mitigate | CLOSED | [README.md](/Users/jon/projects/accrue/README.md#L21), [accrue/README.md](/Users/jon/projects/accrue/accrue/README.md#L63), [accrue_admin/README.md](/Users/jon/projects/accrue/accrue_admin/README.md#L44), [root_readme_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/root_readme_test.exs#L21) |
| T-14-01-04 | D | README.md | mitigate | CLOSED | [README.md](/Users/jon/projects/accrue/README.md#L34), [root_readme_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/root_readme_test.exs#L52) |
| T-14-02-01 | I | .github/ISSUE_TEMPLATE/*.yml | mitigate | CLOSED | [bug.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/bug.yml#L8), [integration-problem.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/integration-problem.yml#L8), [documentation-gap.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/documentation-gap.yml#L8), [feature-request.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/feature-request.yml#L8), [issue_templates_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/issue_templates_test.exs#L56) |
| T-14-02-02 | T | integration-problem.yml | accept | CLOSED | Accepted risk logged below. [integration-problem.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/integration-problem.yml#L13) routes reporters to public docs while Plans 14-01 and 14-03 harden webhook wording. |
| T-14-02-03 | T | bug.yml, integration-problem.yml, feature-request.yml | mitigate | CLOSED | [bug.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/bug.yml#L13), [integration-problem.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/integration-problem.yml#L13), [feature-request.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/feature-request.yml#L13), [issue_templates_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/issue_templates_test.exs#L80) |
| T-14-02-04 | D | config.yml | accept | CLOSED | Accepted risk logged below. [config.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/config.yml#L1) keeps public routing separate without defining release-lane policy. |
| T-14-03-01 | I | CONTRIBUTING.md, guides/testing-live-stripe.md | mitigate | CLOSED | [CONTRIBUTING.md](/Users/jon/projects/accrue/CONTRIBUTING.md#L65), [testing-live-stripe.md](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L105), [release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L37) |
| T-14-03-02 | T | RELEASING.md, guides/testing-live-stripe.md | mitigate | CLOSED | [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L77), [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L84), [testing-live-stripe.md](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L20), [testing-live-stripe.md](/Users/jon/projects/accrue/guides/testing-live-stripe.md#L105), [release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L8) |
| T-14-03-03 | T | RELEASING.md | mitigate | CLOSED | [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L7), [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L84) keeps release guidance on public lanes and public docs; no private modules are taught as stable release APIs. |
| T-14-03-04 | D | RELEASING.md, scripts/ci/verify_package_docs.sh | mitigate | CLOSED | [RELEASING.md](/Users/jon/projects/accrue/RELEASING.md#L7), [verify_package_docs.sh](/Users/jon/projects/accrue/scripts/ci/verify_package_docs.sh#L108), [package_docs_verifier_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/package_docs_verifier_test.exs#L61), [release_guidance_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/release_guidance_test.exs#L11) |

### Accepted Risks Log

| Threat ID | Rationale |
|-----------|-----------|
| T-14-01-01 | The root README links readers to `SECURITY.md` and `CONTRIBUTING.md` but does not collect secrets or incident details. Secret-bearing public intake is handled by the structured issue forms added in Plan 14-02. |
| T-14-02-02 | The integration form points users to `accrue/guides/first_hour.md` and `accrue/guides/troubleshooting.md` for webhook setup, while webhook-verification wording is enforced in the front-door and release guidance docs. This phase intentionally does not duplicate that wording in the form itself. |
| T-14-02-04 | The issue chooser config owns support/security routing only. Release-lane distinctions are documented and enforced in `README.md`, `RELEASING.md`, and the docs verifier, so this config does not need to carry release-lane wording. |

### Threat Flags

None. The loaded phase summary files do not contain a `## Threat Flags` section, so there were no registered or unregistered execution flags to map.

### Verification Runs

- `cd accrue && mix test test/accrue/docs/root_readme_test.exs test/accrue/docs/package_docs_verifier_test.exs test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/canonical_demo_contract_test.exs`
- `cd accrue && mix test test/accrue/docs/issue_templates_test.exs`
- `cd accrue && mix test test/accrue/docs/release_guidance_test.exs test/accrue/docs/package_docs_verifier_test.exs && bash ../scripts/ci/verify_package_docs.sh`

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-17 | 12 | 12 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-17
