---
phase: 15
slug: trust-hardening
status: verified
threats_open: 0
asvs_level: default
created: 2026-04-17
requirements:
  - TRUST-01
  - TRUST-05
  - TRUST-06
---

# Phase 15 - Trust Review

> Evidence-first trust review for webhook, auth, admin, replay, generated-host, retained-artifact, and public-intake boundaries.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| webhook request -> raw-body verification | Untrusted Stripe-style input crosses into Accrue verification, persistence, and queueing. Evidence comes from signed ingest tests and raw-body ordering checks. | Signed payloads, webhook secrets, processor event ids |
| host auth/session -> /billing mount | Host-owned auth/session setup controls who can reach `/billing` and what step-up policy applies. Accrue documents the boundary but does not own session bootstrapping, route placement, or environment-specific MFA/step-up rules. | Session state, route mounts, operator identity |
| admin operator -> replay action | A privileged operator can inspect and replay failed webhook work only through admin-only audited paths. | Replay requests, audit events, webhook status transitions |
| generated installer output -> host-owned code | Generated installer output becomes host-owned code after generation. Hosts own runtime secret storage, final router placement, and any environment-specific edits after installation. | Generated modules, runtime config, secret lookup |
| retained browser artifacts -> repo/CI storage | Playwright traces and screenshots can help diagnose failures, but retained artifacts must stay failure-only and must not capture secrets, customer data, or PII in success-path dumps. | Failure traces, screenshots, CI artifacts |
| public docs/issues -> maintainer intake | Public docs and issue forms route maintainers toward sanitized reproduction data and away from secret-bearing intake. | Public issue bodies, troubleshooting context, support routing |
| public errors/logs -> diagnostic readers | Error messages and telemetry are visible to maintainers and adopters, so diagnostics must name config keys and remediation paths without leaking raw secrets, tokens, customer data, or PII. | Public diagnostics, logs, telemetry attributes |

## Security Verification

**Phase:** 15 - trust-hardening
**ASVS Level:** default
**Block On:** open
**Threats Open:** 0
**Required Evidence:** TRUST-01, TRUST-05, TRUST-06
**Host-owned areas:** session bootstrapping, runtime secret storage, route placement, environment-specific step-up policy
**Advisory areas:** provider-parity Stripe checks remain advisory and do not replace deterministic trust evidence

### Threat Verification

Every item in this section records severity and ASVS mapping. high-severity findings are release-blocking and cannot be accepted in Phase 15. Accepted risks are allowed only when they are low or medium severity and include concrete rationale tied to existing evidence.

| Threat ID | Category | Component | Severity | ASVS | Disposition | Status | Evidence |
|-----------|----------|-----------|----------|------|-------------|--------|----------|
| T-15-01 | T | `.planning/phases/15-trust-hardening/15-TRUST-REVIEW.md` | High | V1.1, V1.14 | mitigate | CLOSED | [webhook_ingest_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs#L1), [admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L1), [trust_review_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/docs/trust_review_test.exs#L1) keep webhook, admin, replay, generated-host, and public issue intake boundaries concrete instead of implied. |
| T-15-02 | E | admin replay boundary | High | V4.1, V4.2 | mitigate | CLOSED | [admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs#L1) proves admin-only replay and audit evidence; host auth/session -> `/billing` mount remains host-owned and environment-specific. |
| T-15-03 | I | webhook and diagnostic surfaces | High | V8.3, V14.2 | mitigate | CLOSED | [plug_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/webhook/plug_test.exs#L1), [errors_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/errors_test.exs#L1), [otel_test.exs](/Users/jon/projects/accrue/accrue/test/accrue/telemetry/otel_test.exs#L1) prove raw-body verification, redacted error messaging, and telemetry allowlisting for public errors/logs. |
| T-15-04 | R | public docs/issues and release language | Medium | V1.9, V14.1 | mitigate | CLOSED | [bug.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/bug.yml#L1), [integration-problem.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/integration-problem.yml#L1), [accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh#L1), [.github/workflows/ci.yml](/Users/jon/projects/accrue/.github/workflows/ci.yml#L1) keep no-secrets intake and required deterministic gates aligned with maintainer workflow. |
| T-15-05 | I | public issue intake | Low | V8.3, V14.2 | accept | CLOSED | Accepted risk logged below. [bug.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/bug.yml#L1) and [integration-problem.yml](/Users/jon/projects/accrue/.github/ISSUE_TEMPLATE/integration-problem.yml#L1) already route users away from production payloads, tokens, webhook secrets, customer data, and PII. |

### Accepted Risks Log

Only low or medium severity items may appear here. High-severity findings are release-blocking and cannot be accepted in Phase 15.

| Threat ID | Severity | ASVS | Rationale |
|-----------|----------|------|-----------|
| T-15-05 | Low | V8.3, V14.2 | Public issue intake remains an accepted risk because Phase 14 already added no-secrets issue forms and this review reuses that evidence. The residual risk is maintainers ignoring the template guidance, not a known Accrue path that requests tokens, webhook secrets, customer data, or PII. |

### Verification Runs

- `cd accrue && mix test test/accrue/docs/trust_review_test.exs --trace`
- `cd accrue && mix test test/accrue/webhook/plug_test.exs test/accrue/errors_test.exs test/accrue/telemetry/otel_test.exs`
- `cd examples/accrue_host && mix test test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_webhook_replay_test.exs`
- `bash scripts/ci/accrue_host_uat.sh`

---

## Sign-Off

- [x] Trust boundaries documented with concrete evidence
- [x] Host-owned and advisory areas explicitly labeled
- [x] Severity and ASVS mapping recorded for each listed threat
- [x] High-severity findings marked release-blocking and non-acceptable in Phase 15
- [x] Accepted risks limited to low or medium severity with concrete rationale

**Approval:** verified 2026-04-17
