---
phase: 204
slug: ranked-hardening-roadmap
status: verified
threats_open: 0
asvs_level: planning-artifact
block_on: open_threats
register_authored_at_plan_time: true
created: 2026-07-03
updated: 2026-07-03
---

# Phase 204 - Security

Per-phase security contract for the roadmap-only Phase 204 artifact. This audit
verifies only the plan-time threat register from `204-01-PLAN.md`; it does not
scan for unrelated product threats.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|---|---|---|
| Phase 201-203 artifacts -> Phase 204 roadmap | Prior audit and ADR evidence becomes prioritized follow-up guidance. | Planning evidence and citations. |
| Phase 204 decisions -> roadmap prose | Locked user decisions constrain rank order, slicing, deferrals, and document shape. | Phase decisions and roadmap requirements. |
| Roadmap -> future planner/executor agents | Roadmap cards may drive later implementation milestones and must not overclaim completed work. | Future implementation guidance. |
| Local evidence paths -> public-facing future work | The roadmap names public docs, CI, release, DB, package, and portal surfaces as future work targets without editing them now. | Local path references and future-work descriptions. |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status | Evidence |
|---|---|---|---|---|---|---|
| T-204-01 | Tampering | Product, CI, release, DB, package, example, script, and public-doc surfaces | mitigate | Tasks modify only `204-HARDENING-ROADMAP.md`; Task 3 verifies no Phase 204 changes under implementation surfaces. | closed | `204-HARDENING-ROADMAP.md:251` lists the no-change surfaces; `204-HARDENING-ROADMAP.md:262` states no release commands, package manifests, workflow files, database migrations, source code, example app code, portal code, or public-facing guides changed. `git show --name-status` for `372c21f8 fa20022a 685cb70b 634cf145 e69bca64 e3dfcc4a` showed only Phase 204 roadmap, summary, and verification artifacts. Product/public surface `git status --short -- README.md CONTRIBUTING.md RELEASING.md .github scripts accrue accrue_admin accrue_portal examples package.json mix.exs` returned empty. |
| T-204-02 | Repudiation | Ranked recommendations | mitigate | Tasks 1-2 require Phase 201, Phase 202, or Phase 203 evidence citations for every ranked row and implementation card. | closed | `204-HARDENING-ROADMAP.md:35-44` includes 10 ranked rows, each citing Phase 201, 202, or 203. Implementation-card `Source evidence` lines appear at `204-HARDENING-ROADMAP.md:50`, `:61`, `:72`, `:83`, `:94`, `:105`, `:116`, `:127`, `:138`, and `:149`. Parser verification returned `{"rankedRows":10,"implementationCards":10,"allCited":true}`. |
| T-204-03 | Information Disclosure | CI/provider/release evidence discussion | mitigate | Discuss secret presence, provider proof, and release recovery only as mechanisms; do not include raw secrets, tokens, or private account identifiers. | closed | Provider and release discussion names states and mechanisms at `204-HARDENING-ROADMAP.md:76-79`, with secret names redacted at `:79`. Milestone output requires secret requirements "named but not exposed" at `204-HARDENING-ROADMAP.md:181`. Negative grep over Phase 204 final artifacts found no common raw credential or account-id patterns (`sk_live`, `sk_test`, `pk_live`, `pk_test`, `whsec_`, `acct_`, AWS keys, GitHub tokens, Slack tokens, or private-key headers). |
| T-204-04 | Spoofing | Audit-only boundary | mitigate | Task 3 requires boundary language that Phase 204 ranks follow-up work and did not implement CI, DB, release, package, UI, docs, or source changes. | closed | `204-HARDENING-ROADMAP.md:6` states the artifact is roadmap-only and does not implement product, CI, release, package, database, documentation, or UI changes. `204-HARDENING-ROADMAP.md:251` and `:262` repeat the no-change boundary. `204-01-SUMMARY.md:60` records that the phase remained roadmap-only and did not modify implementation surfaces. Commit-scope and product/public `git status` checks were clean for implementation paths. |
| T-204-05 | Tampering | Deferred or out-of-scope ideas | mitigate | Task 2 records locked deferrals with reopen triggers so deferred polish is not silently promoted into ranked work. | closed | `204-HARDENING-ROADMAP.md:225-238` records explicit deferrals for test-value classification, portal white-label/design-system redesign, support triage, pixel-diff coverage, schema rename, data movement, premature CI gate/topology/cache/branch-protection work, broad docs rewrite, enterprise governance, i18n/localization, runtime benchmarking, and favicon polish. `204-HARDENING-ROADMAP.md:247` maps RD-04 to deferrals and the boundary. |

## Accepted Risks Log

No accepted risks.

## Transferred Risks

No transferred risks.

## Unregistered Flags

None. `204-01-SUMMARY.md` records `## Threat Flags` as `None`; no Phase 204 threat flag required a new mapping.

## Verification Commands

| Check | Result |
|---|---|
| Citation parser over `Ranked Top 10` and `Implementation Cards` | Passed: 10 ranked rows, 10 implementation cards, all cited Phase 201, 202, or 203 evidence. |
| Raw secret/account-id pattern grep over Phase 204 final artifacts | Passed: no raw credential or private account-id patterns found. |
| Deferral grep over `Explicit Deferrals` | Passed: all locked deferral categories and risk/reopen language found. |
| Boundary grep plus product/public `git status` | Passed: boundary language found and product/public surface status returned empty. |
| Commit-scope review for Phase 204 commits | Passed: task/closure/verification commits touched only Phase 204 planning artifacts. |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---:|---:|---:|---|
| 2026-07-03 | 5 | 5 | 0 | Codex security auditor |

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks documented in Accepted Risks Log.
- [x] Transfer documentation checked; no transfer dispositions were present.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

Approval: verified 2026-07-03
