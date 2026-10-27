---
phase: "252"
slug: production-backed-subscription-stories
status: verified
threats_open: 0
threats_open_total: 1
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 252 Security Verification

ASVS L1 audit of the authored threat register. Eighteen of nineteen unique threats are closed. T-252-07 remains open below the high blocking threshold; remediation is underway, not accepted risk. Reserved T-252-SC is counted once across eight plans.

## Trust Boundaries

- Validated synthetic facts enter production presentation without changing mounted authority.
- Disposable lab commands cross process, port and database boundaries under explicit ownership.
- Development assets and evidence remain distinct from production compilation, packages and runtime routes.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-252-01 | Elevation | SubscriptionLive.subscription_area/1 | high | mitigate | accrue_admin/lib/accrue_admin/live/subscription_live.ex:295; subscription_story_slice_test.exs:112; subscription_live_test.exs:918 | closed |
| T-252-02 | Information disclosure | static story metadata | medium | mitigate | storybook/components/subscription_detail.story.exs:5; subscription_scenarios.ex:125 | closed |
| T-252-SC | Tampering | Package boundary | high | mitigate | No dependency declarations/lockfiles changed; installed tools only; verify_phase252_production_boundary.mjs:264,543,557 | closed |
| T-252-03 | Tampering | SubscriptionScenarios.validate!/1 | high | mitigate | accrue_admin/storybook/_support/subscription_scenarios.ex:58; subscription_scenarios_test.exs:171 | closed |
| T-252-04 | Spoofing | shared fact actor and billable identity | medium | mitigate | accrue_admin/storybook/_support/subscription_scenarios.ex:146; subscription_scenarios_test.exs:189 | closed |
| T-252-05 | Spoofing | review HTTP endpoint | high | mitigate | scripts/dev/phase252_lab.mjs:98,119,382,445; phase252_isolation.test.mjs:193 | closed |
| T-252-06 | Tampering | lab DB creation/reset/teardown | high | mitigate | scripts/dev/phase252_lab.mjs:85,521,558,604; phase252_isolation.test.mjs:152,228 | closed |
| T-252-07 | Denial | interrupted lab children | medium | mitigate | scripts/dev/phase252_lab.mjs:184-189,541-546,596-610; synthetic direct-child termination left descendant alive | open — below high threshold (non-blocking) |
| T-252-08 | Tampering | scenario persistence adapter | high | mitigate | accrue_admin/test/support/subscription_scenario_repo.ex:55,129,165; subscription_scenario_repo_test.exs:92,128,143 | closed |
| T-252-09 | Elevation | host cleanup child authority | high | mitigate | examples/accrue_host/priv/repo/seeds/phase248_cleanup_edge.exs:29,34,66,80; phase252_scenario_cleanup_test.exs:103,176 | closed |
| T-252-10 | Information disclosure | ordinary/heldout payloads | medium | mitigate | dev_support/ui_scenarios/cadence_subscriptions.exs:31,98,141; phase252_scenario_cleanup_test.exs:67 | closed |
| T-252-11 | Spoofing | generated story attribution | high | mitigate | accrue_admin/storybook/_support/subscription_manifest.ex:34,77,111,572; phase252-story-helpers.js:666 | closed |
| T-252-12 | Repudiation | caller coverage ledger | medium | mitigate | accrue_admin/storybook/_support/subscription_manifest.ex:427,444,718,733,743 | closed |
| T-252-13 | Spoofing | render coverage results | high | mitigate | accrue_admin/e2e/phase252-story-helpers.js:69,635,725,810; generate_phase252_acceptance.mjs:257-307 | closed |
| T-252-14 | Information disclosure | browser heldout evidence | medium | mitigate | accrue_admin/e2e/phase252-story-helpers.js:368,420,467,592 | closed |
| T-252-15 | Information disclosure | published package contents | high | mitigate | scripts/ci/verify_phase252_production_boundary.mjs:175,200,207,543,557,564; negative controls:485,489,493 | closed |
| T-252-16 | Elevation | dev/test route boundary | high | mitigate | accrue_admin/lib/accrue_admin/router.ex:154,200; subscription_production_boundary_test.exs:79,91,177 | closed |
| T-252-17 | Tampering | workflow admission and command chain | high | mitigate | .github/workflows/ci.yml:25,1242,1316; verify_phase200_admin_guardrails.sh:2,23; verify_phase252_ci_contract.test.mjs:71,85,99 | closed |
| T-252-18 | Repudiation | automated acceptance evidence | high | mitigate | scripts/ci/verify_phase252_stories.mjs:253,468,509; generate_phase252_acceptance.mjs:157-307,312,477 | closed |

## Open Threat Details

T-252-07: `terminateOwnedChild` signals only the direct ChildProcess, while commands may spawn descendants. A synthetic read-only reproduction returned `direct_child_terminated:true` and `owned_descendant_survives:true`; all synthetic processes were then cleaned. The existing tests do not cover signal interruption with descendants. Required remediation is an identity-verified owned process group or tracked descendant set, with interruption coverage proving descendants exit before database teardown.

## Accepted Risks Log

No accepted risks. The medium finding is being fixed under Phase 252 execution.

## Security Audit Trail

| Date | Total | Closed | Open total | Blocking open | Evidence |
|---|---|---|---|---|---|
| 2026-10-27 | 19 | 18 | 1 | 0 | Independent gsd-security-auditor; current acceptance validator passed 18-command bundle; 37 focused Node controls passed; synthetic descendant reproduction confirmed gap |

`dev_asset_routes` summary flag maps to closed T-252-16. No unregistered flags were found. Static rendering evidence does not establish provider completion or mounted action dispatch.
