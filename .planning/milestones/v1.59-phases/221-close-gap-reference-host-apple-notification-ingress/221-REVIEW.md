---
phase: 221-close-gap-reference-host-apple-notification-ingress
reviewed: 2026-08-05T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/config/runtime.exs
  - examples/accrue_host/test/accrue_host_web/apple_notification_ingest_test.exs
  - examples/accrue_host/lib/accrue_host/apple_rate_policy.ex
  - examples/accrue_host/lib/accrue_host/application.ex
  - examples/accrue_host/test/accrue_host/apple_rate_policy_test.exs
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/test/accrue_host/recovery_wiring_test.exs
  - examples/accrue_host/README.md
  - examples/accrue_host/docs/adoption-proof-matrix.md
  - accrue/guides/operator-runbooks.md
  - examples/accrue_host/test/install_boundary_test.exs
  - scripts/ci/accrue_host_verify_test_bounded.sh
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 221: Code Review Report

**Reviewed:** 2026-08-05T00:00:00Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The Apple ingress, its runtime wiring, recovery schedule, documentation, and bounded verifier suite were reviewed in context with the underlying Accrue notification/admission APIs. The focused host suite passes (22 tests), but it does not exercise the production reverse-proxy identity boundary or reject a product map pointing to an atom that is real in the VM but absent from the entitlement catalog.

## Critical Issues

### BL-01 [BLOCKER]: Reverse-proxy traffic shares one limiter identity, enabling global Apple delivery denial

**File:** `examples/accrue_host/lib/accrue_host/apple_rate_policy.ex:21-24,70-74`

**Issue:** The limiter keys solely on `conn.remote_ip`. In any public reverse-proxy / load-balancer deployment, `remote_ip` is the proxy's TCP address unless a trusted-proxy peer-resolution layer is configured. The implementation contains no such configuration or proxy allowlist. An Internet client can therefore consume the 120-request bucket belonging to the proxy and cause every subsequent real Apple notification through that proxy to receive `429` for the window. This is an externally triggerable availability/security failure, not merely a per-client backstop. The current tests create direct synthetic peers and cannot detect it.

**Fix:** Make the identity contract deployment-safe: either restrict this endpoint at the trusted edge so only Apple reaches the host, or configure a trusted-proxy-aware peer resolver with an explicit allowlist of proxy CIDRs and use that resolved client address. Do not trust `X-Forwarded-For` directly. Add an integration/configuration test covering a trusted proxy and an untrusted client-supplied forwarded header.

## Warnings

### WR-01 [WARNING]: Product-map validation does not validate configured entitlement plans

**File:** `examples/accrue_host/lib/accrue_host/apple_notification_ingress.ex:34-42,58-61`

**Issue:** `decode_product_map!/1` treats any atom that already happens to exist in the BEAM as an “existing plan.” That is unrelated to the host's actual entitlement catalog. For example, `"pro"` is already an atom because the billing UI defines `:pro`, while the configured entitlement catalog at `config/config.exs:136-141` defines only `:scale`. A deployment typo can consequently pass boot validation and later persist/project an unmapped logical plan instead of failing fast, leaving valid purchases without the intended entitlement. The parser's stated strict/unknown-plan error contract is therefore false, and the tests cover only source shape rather than this behavior.

**Fix:** Validate decoded plan names against the configured entitlement-plan keys (or an explicit host-owned allowlist), then convert only the approved values to atoms. Add unit coverage for an atom that exists in the VM but is absent from `:accrue, :entitlements` and assert startup rejects it.

---

_Reviewed: 2026-08-05T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
