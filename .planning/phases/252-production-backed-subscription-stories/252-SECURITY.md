---
phase: "252"
slug: production-backed-subscription-stories
status: verified
threats_open: 0
threats_open_total: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-27"
---

# Phase 252 Security Verification

ASVS L1 audit of the authored threat register. All nineteen unique threats are closed after independent re-audit. No accepted risks were introduced. Reserved T-252-SC is counted once across eight plans.

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
| T-252-07 | Denial | interrupted lab children | medium | mitigate | scripts/dev/phase252_lab.mjs:173,188-191,394,612,625,642,670-715; phase252_isolation.test.mjs:392,413-421,478-492; independent real regressions 2/2 | closed |
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

## Resolved Threat History

T-252-07: `terminateOwnedChild` signals only the direct ChildProcess, while commands may spawn descendants. A synthetic read-only reproduction returned `direct_child_terminated:true` and `owned_descendant_survives:true`; all synthetic processes were then cleaned. The existing tests do not cover signal interruption with descendants. The follow-up implemented an identity-verified owned process group, waits for non-running owned members after TERM/KILL, and refuses database teardown on uncertain ownership. Independent real regressions now prove interruption-before-drop, exited-leader cleanup and unrelated-sentinel preservation. The original audit observation is retained here as resolved history.

## Accepted Risks Log

No accepted risks. The medium finding was fixed and independently re-audited under Phase 252 execution.

## Security Audit Trail

| Date | Total | Closed | Open total | Blocking open | Evidence |
|---|---|---|---|---|---|
| 2026-10-27 | 19 | 18 | 1 | 0 | Independent gsd-security-auditor; current acceptance validator passed 18-command bundle; 37 focused Node controls passed; synthetic descendant reproduction confirmed gap |

`dev_asset_routes` summary flag maps to closed T-252-16. No unregistered flags were found. Static rendering evidence does not establish provider completion or mounted action dispatch.

## Security Re-Audit — 2026-10-27

- Closed: 19/19; open total: 0; blocking open: 0. ASVS L1 / block threshold high.
- Independent acceptance validation passed latest run `25208-1793086410828-22011-2a58bd0a056d` (18 commands, 15 render rows, 4 isolation cases).
- Independent focused controls passed 37/37; real interruption and exited-leader regressions passed 2/2 with scoped process-probe permissions.
- All previous mitigations remain present. The bounded twenty-minute clean compile ceiling preserves warning-as-error, failure propagation and all actual package checks. Bounded theme polling preserves the same expected state assertions.
- Fail-closed limitation: uncertain group identity preserves resources rather than signaling an unverified group or dropping its database.
- No dependencies installed, accepted risks invented, or unregistered summary flags found.

## Security Audit 2026-10-27

| Metric | Count |
|---|---|
| Threats found | 19 |
| Closed | 19 |
| Open | 0 |
