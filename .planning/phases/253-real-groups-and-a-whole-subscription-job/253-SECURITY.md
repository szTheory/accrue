---
phase: "253"
slug: real-groups-and-a-whole-subscription-job
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 253 — Security

The independent security auditor verified 20 of 21 unique planned threats from source and executed tests. Shared T-253-SC is counted once. The remaining T-253-20 evidence clause was independently rerun through native GSD projection and enforcement; both checks returned green with machine-proven independent violation controls. No accepted risks are used.

## Trust Boundaries

Authenticated route scope and action authority remain in production LiveViews and query/domain owners. Development Storybook transports provide presentation only. Disposable test resources and source-bound execution records remain separate from production and provider evidence.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-253-01 | Elevation of privilege | Scoped production query | high | mitigate | subscription_collection_transport_test.exs; subscriptions_live.ex | closed |
| T-253-02 | Tampering | Connected DataTable targets | high | mitigate | subscription_collection_transport_test.exs; data_table.ex | closed |
| T-253-03 | Information disclosure | Dev/test package boundary | high | mitigate | subscription_production_boundary_test.exs; accrue_admin/mix.exs | closed |
| T-253-04 | Information disclosure | Pagination owner scope | high | mitigate | subscriptions_live_test.exs; queries/subscriptions.ex | closed |
| T-253-05 | Tampering | Cursor validation and stable order | high | mitigate | subscriptions_live_test.exs; queries/subscriptions.ex | closed |
| T-253-06 | Spoofing | Identity/amount/escaping | medium | mitigate | subscriptions_live_test.exs; subscriptions_live.ex | closed |
| T-253-07 | Elevation of privilege | Routed detail authority | high | mitigate | subscription_live_test.exs; subscription_live.ex | closed |
| T-253-08 | Spoofing | Truthful result states | high | mitigate | subscription_page_slice_test.exs; subscription_live.ex | closed |
| T-253-09 | Information disclosure | Lazy disclosure and JSON | medium | mitigate | subscription_page_slice_test.exs; json_viewer.ex | closed |
| T-253-10 | Elevation of privilege | Fresh review and step-up | high | mitigate | subscription_live_test.exs; subscription_live.ex | closed |
| T-253-11 | Tampering | Inert dismissal | high | mitigate | subscription_journey_test.exs; subscription_live.ex | closed |
| T-253-12 | Spoofing | Exact action effects | high | mitigate | subscription_journey_test.exs; subscription_live_test.exs | closed |
| T-253-13 | Information disclosure | Scoped safe return | high | mitigate | subscription_live_test.exs; scoped_path.ex; subscription_live.ex | closed |
| T-253-14 | Spoofing | Per-cell geometry and asset evidence | high | mitigate | subscription-compositions-phase253.spec.js; verify_phase253_compositions.mjs | closed |
| T-253-15 | Spoofing | Bounded presentation claims | high | mitigate | verify_phase252_transparency.mjs; verify_phase253_presentation.test.mjs | closed |
| T-253-16 | Information disclosure | Synthetic attribution and escaping | medium | mitigate | phase253-composition-helpers.js; verify_phase252_transparency.mjs | closed |
| T-253-17 | Tampering | Required CI path admission | high | mitigate | verify_phase252_ci_contract.test.mjs; verify_phase200_admin_guardrails.sh | closed |
| T-253-18 | Spoofing | Executed evidence identity | high | mitigate | verify_phase253_compositions.test.mjs; verify_phase253_compositions.mjs | closed |
| T-253-19 | Denial of service | Serial disposable resources | high | mitigate | verify_phase253_compositions.test.mjs; phase252_lab.mjs | closed |
| T-253-20 | Tampering | Native proof and complete summaries | high | mitigate | 253-NATIVE-PROHIBITION-PROOF.json; generate_phase253_acceptance.mjs | closed |
| T-253-SC | Tampering | No package installs or dependency changes | high | mitigate | Unchanged Mix/npm manifests and locks; retained Phase252 production package lane | closed |

## Native Proof Reconciliation

The original executor summary claimed native enforcement before descriptor promotion, but its native transcript was not retained. This audit does not attest that historical ordering. At audit time the orchestrator read the two descriptors through `parseMustHavesBlock` and `projectProhibitions`, reconstructed them with `descriptorFromProjection`, and executed the installed `gsd-tools.cjs check prohibition-enforcement` command. Both native verdicts were `green`, `flagged: false`, with `passed: true`, `failFirst: true`, and `failFirstProof: violation-fixture`. Each native prover requires the same check to reject its independent violation and accept the clean fixture before current-source GREEN. Requests, projected descriptors and actual native verdicts are retained in `253-NATIVE-PROHIBITION-PROOF.json`.

Complete-summary gating remains in `generate_phase253_acceptance.mjs`. The audit's modified VALIDATION input requires a fresh aggregate before final verification; the stale earlier bundle is not treated as current evidence.

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit date | Threats total | Closed | Open | Run by |
|---|---|---|---|---|
| 2026-10-27 | 21 | 20 | 1 | Independent gsd-security-auditor |
| 2026-10-27 | 21 | 21 | 0 | Orchestrator native proof reconciliation |

## Sign-Off

All unique planned threats have a mitigation disposition and source-backed closure. Native proof is retained. `threats_open: 0`; `status: verified`. Final phase acceptance remains independently verified.
