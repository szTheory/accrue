---
phase: 20
slug: organization-billing-with-sigra
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-17
---

# Phase 20 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/admin_mount_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` |
| **Full suite command** | `cd accrue && mix test.all && cd ../accrue_admin && mix test && cd ../examples/accrue_host && mix verify` |
| **Estimated runtime** | ~180 seconds once PostgreSQL is available |

---

## Sampling Rate

- **After every task commit:** Run the smallest focused ExUnit command covering the touched surface.
- **After every plan wave:** Run package-focused suites for every touched package.
- **Before `$gsd-verify-work`:** Full suite must be green across `accrue`, `accrue_admin`, and `examples/accrue_host`.
- **Max feedback latency:** 180 seconds for focused package checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-W0-ORG-01 | TBD | 0 | ORG-01 | T-20-01 / — | Organization billable round-trips through `owner_type: "Organization"` and `owner_id` without core Accrue billing schema changes. | unit/integration | `cd accrue && mix test test/accrue/billable_test.exs --warnings-as-errors` | yes | pending |
| 20-W0-ORG-02 | TBD | 0 | ORG-02 | T-20-02 | Active organization scope and membership drive canonical host billing; client-selected org IDs are ignored or rejected. | integration/LiveView | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/org_billing_live_test.exs` | no, Wave 0 creates it | pending |
| 20-W0-ORG-03 | TBD | 0 | ORG-03 | T-20-03 / T-20-04 | Cross-org host/admin/replay access fails server-side before billing mutation or row disclosure. | integration/LiveView | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host_web/org_billing_access_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` | no, Wave 0 creates it | pending |

---

## Wave 0 Requirements

- [ ] `examples/accrue_host/test/accrue_host_web/org_billing_live_test.exs` - host active-org happy-path proof for ORG-02.
- [ ] `examples/accrue_host/test/accrue_host_web/org_billing_access_test.exs` - cross-org denial coverage for host/admin entry points under ORG-03.
- [ ] `accrue_admin` owner-scope tests for customer/subscription/invoice/webhook detail loaders.
- [ ] Sigra-backed host fixtures or a minimal Sigra test double, because no local Sigra fixture layer exists yet.
- [ ] `cd examples/accrue_host && MIX_ENV=test mix ecto.migrate` after host organization/membership migrations are added.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Concrete Sigra package/API source confirmation | ORG-02 | The local repo has only an Accrue Sigra auth adapter scaffold; no local or Hex Sigra org API was verified during research. | Before execution locks Sigra module names, confirm the dependency source and active-organization/membership APIs or keep the host proof behind a local Sigra-compatible test seam. |

---

## Validation Sign-Off

- [x] All tasks have automated verification targets or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references identified by research.
- [x] No watch-mode flags.
- [x] Feedback latency target is below 180 seconds for focused checks.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
