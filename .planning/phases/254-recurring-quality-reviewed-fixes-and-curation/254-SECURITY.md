---
phase: "254"
slug: "recurring-quality-reviewed-fixes-and-curation"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-03"
---

# Phase 254 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub Actions and pull request inputs | Workflow event fields and changed paths are untrusted inputs to CI scripts; workflow permissions and tokens remain CI-owned. | PR metadata, repository paths, test results, workflow credentials |
| Repository verification and evidence | Verifiers consume committed plans, source, manifests, generated records, and test results; outputs become phase acceptance evidence. | Source files, manifests, browser captures, per-task results |
| Local browser and test-support routes | Browser tests exercise the local Admin application; destructive reset/seed routes are restricted to the dedicated test lane. | Local app state and synthetic subscription data |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-254-01 | Information disclosure | machineFingerprint | high | mitigate | Allow-list keys only; never serialize process.env; self-test injects a secret-looking env var and asserts it is absent from output. Evidence: [254-01-SUMMARY.md](254-01-SUMMARY.md). | closed |
| T-254-02 | Tampering | phase254-budget.json metrics | medium | mitigate | Local samples carry informs_only true; isFreezeEligible rejects non-ubuntu image_os, dirty and smoke samples, proved by fixtures. Evidence: [254-01-SUMMARY.md](254-01-SUMMARY.md). | closed |
| T-254-03 | Tampering | Guard idiom rewrite in seven verifiers | high | mitigate | Registered tests call real exports with positive and negative fixtures; existing *.test.mjs suites and CLI --self-test paths stay green, proving the CLI branch still runs. Evidence: [254-02-SUMMARY.md](254-02-SUMMARY.md). | closed |
| T-254-04 | Repudiation | Spec-to-project ownership | medium | mitigate | Ownership contract fails on unowned or cross-group double-owned specs and on a mounted spec in the pure-story project, each with a seeded fixture. Evidence: [254-02-SUMMARY.md](254-02-SUMMARY.md). | closed |
| T-254-05 | Information disclosure | Public push of ~165 commits | high | mitigate | Sensitive-token census (scope-lock, ratchet, no-cleartext) and no-home-paths checks pass on the exact commit inside the pre-push gate, and the push is skipped when the gate fails. Evidence: [254-03-SUMMARY.md](254-03-SUMMARY.md). | closed |
| T-254-06 | Elevation of privilege | Workflow edits | medium | mitigate | No pull_request_target, no permission widening, same pinned upload action; efficiency contract green. Evidence: [254-01-SUMMARY.md](254-01-SUMMARY.md). | closed |
| T-254-07 | Repudiation | Curation evidence | high | mitigate | Verifier rejects grep-absence-only and screenshot-similarity evidence; reference scan proven on a seeded positive before accepting zero hits. Evidence: [254-04-SUMMARY.md](254-04-SUMMARY.md). | closed |
| T-254-08 | Tampering | Pinned Phase 252 counts | high | mitigate | Counts derive from the ledger and fail closed when the ledger is missing; mismatch fixtures prove each site still fails. Evidence: [254-04-SUMMARY.md](254-04-SUMMARY.md). | closed |
| T-254-09 | Elevation of privilege / DoS | E2E.Plug reset/seed in review lane | high | mitigate | refuse_in_review_lane returns 403 for every route variant enumerated from the plug's own route list; ExUnit and live two-server tests with unchanged-marker assertions. Evidence: [254-05-SUMMARY.md](254-05-SUMMARY.md). | closed |
| T-254-10 | Tampering | Composition result ledger | medium | mitigate | One file per case via temp plus rename; merge enforces run identity and uniqueness; race control proves the old failure mode. Evidence: [254-05-SUMMARY.md](254-05-SUMMARY.md). | closed |
| T-254-11 | Information disclosure | Shared ordinary facts list vs held-out data | high | mitigate | Held-out refute assertions unchanged; transparency fixtures re-verified after the list change. Evidence: [254-06-SUMMARY.md](254-06-SUMMARY.md). | closed |
| T-254-12 | Repudiation | Merge of provider_pruned | medium | mitigate | Survivors must exist in discovery and preserved regressions must run in a required lane; verifier fails otherwise. Evidence: [254-06-SUMMARY.md](254-06-SUMMARY.md). | closed |
| T-254-13 | Tampering | Step summary rendering of PR path names | high | mitigate | escapeMarkdown copied from render_provider_summary.mjs; hostile-path fixture in self-test. Evidence: [254-07-SUMMARY.md](254-07-SUMMARY.md). | closed |
| T-254-14 | Spoofing | Stale or forged selection projection | high | mitigate | Projection digest verified against regenerated source_digests; stale projection hard-fails; sentinels digest pinned by test. Evidence: [254-07-SUMMARY.md](254-07-SUMMARY.md). | closed |
| T-254-15 | Tampering | Traversal or unsafe changed paths | medium | mitigate | normalizeRepoPath null is classified FC-1 full, never irrelevant. Evidence: [254-07-SUMMARY.md](254-07-SUMMARY.md). | closed |
| T-254-16 | Tampering | Workflow script injection via PR-controlled values | high | mitigate | Event values passed via env variables, never interpolated into run script text; no pull_request_target. Evidence: [254-08-SUMMARY.md](254-08-SUMMARY.md). | closed |
| T-254-17 | Tampering | Shallow checkout producing a false empty diff | high | mitigate | fetch-depth 0 pinned by contract; shallow and missing-base cases yield full (tested in 254-07). Evidence: [254-08-SUMMARY.md](254-08-SUMMARY.md). | closed |
| T-254-18 | Tampering | Budget rewritten by CI or by a favorable rerun | high | mitigate | freeze refuses when CI is set; attempt above 1, mixed SHAs, non-success, macOS, dirty or smoke samples rejected; re-freeze only by appended deviation. Evidence: [254-09-SUMMARY.md](254-09-SUMMARY.md). | closed |
| T-254-19 | Tampering | ::warning command injection from test titles | medium | mitigate | escapeWorkflowCommand with a hostile-title fixture. Evidence: [254-09-SUMMARY.md](254-09-SUMMARY.md). | closed |
| T-254-20 | Tampering | Stale storybook.css or _build making captures lie | high | mitigate | Recompose --check in CI plus served-bytes ExUnit; section sha256 must equal the bundle. Evidence: [254-10-SUMMARY.md](254-10-SUMMARY.md). | closed |
| T-254-21 | Repudiation | Design record evidence | medium | mitigate | Verifier rejects score keys, tmp evidence and stale source shas; Markdown view regenerated and diff-checked. Evidence: [254-10-SUMMARY.md](254-10-SUMMARY.md). | closed |
| T-254-22 | Repudiation | Silent a11y suppression | high | mitigate | Owner source scan bans disableRules/exclude/impact filters (seeded positive); zero-match and broad-target register entries fail. Evidence: [254-11-SUMMARY.md](254-11-SUMMARY.md). | closed |
| T-254-23 | Elevation of privilege | bypassCSP in probes | medium | mitigate | bypassCSP only in a dedicated text-spacing probe context created after the A2 positive control proves CSP blocks constructed stylesheets; never on cell contexts. Evidence: [254-11-SUMMARY.md](254-11-SUMMARY.md). | closed |
| T-254-24 | Tampering | Shared .ax-field-label cascade | medium | mitigate | Scoped selector only; spec asserts form labels unchanged and values keep tabular-nums. Evidence: [254-12-SUMMARY.md](254-12-SUMMARY.md). | closed |
| T-254-25 | Tampering | Host copy_strings drift | medium | mitigate | Regenerate via mix accrue_admin.export_copy_strings; the verify re-exports and requires an unchanged sha256. Evidence: [254-13-SUMMARY.md](254-13-SUMMARY.md). | closed |
| T-254-26 | Tampering | Baseline poisoning by a local macOS mint | high | mitigate | Local runs use --update-snapshots=none with an unchanged-directory assertion; manifest records browser version and mint run; contract restricts updates to the mint job. Evidence: [254-14-SUMMARY.md](254-14-SUMMARY.md). | closed |
| T-254-27 | Repudiation | Masking essential identity/money/state/actions | high | mitigate | Empty mask allowlist for new cases; geometry check with a masked-amount negative control. Evidence: [254-14-SUMMARY.md](254-14-SUMMARY.md). | closed |
| T-254-28 | Tampering | Mint artifact or unreviewed rebaseline | high | mitigate | Upload only on success; manifest check before commit; dedicated rebaseline commit with per-key reasons; unmapped changes fail; one mint without an owner decision, every further mint owner-gated and listed in AMD-254-06, enforced by the distinct-mint-run check. Evidence: [254-15-SUMMARY.md](254-15-SUMMARY.md). | closed |
| T-254-29 | Repudiation | Unattributed pixel changes | medium | mitigate | baselines_changed must map to finding ids or an owner-decided ENV id; subscriptions.png byte-identity to the merge-base proves the H1 swap. Evidence: [254-15-SUMMARY.md](254-15-SUMMARY.md). | closed |
| T-254-30 | Repudiation | Misleading next-job recommendation | medium | mitigate | Hard filters precede ranking; gatedCannotWin verifier rule with two violation fixtures (gated Portal candidate ranked first, gated candidate as recommendation) and a clean fixture in verify_phase254_curation.test.mjs; status recommendation-input only. Evidence: [254-16-SUMMARY.md](254-16-SUMMARY.md). | closed |
| T-254-31 | Repudiation | New route missing from the gap map | medium | mitigate | Rows seeded from router source with an extra-route positive control. Evidence: [254-16-SUMMARY.md](254-16-SUMMARY.md). | closed |
| T-254-32 | Repudiation | Overstated quality, accessibility or demand claims | medium | mitigate | Transparency test over generated outputs with independent violation fixtures and native fail-first proof. Evidence: [254-17-SUMMARY.md](254-17-SUMMARY.md). | closed |
| T-254-33 | Tampering | Record checks skipped in CI | high | mitigate | Single appended runner step pinned by shell and Node contracts with removal and gating mutations. Evidence: [254-17-SUMMARY.md](254-17-SUMMARY.md). | closed |
| T-254-34 | Repudiation | Fabricated or stale acceptance evidence | high | mitigate | Generator rejects missing/failed/skipped/retried/stale evidence and missing amendments with fixtures; UAT generated only after all SUMMARYs with human_judgment false; --expect-pending refuses any other gap. Evidence: [254-18-SUMMARY.md](254-18-SUMMARY.md). | closed |
| T-254-35 | Tampering | Milestone archival breaking evidence reads | medium | mitigate | resolvePhaseEvidencePath for every planning read; archive-invariant sweep in the post-SUMMARY step. Evidence: [254-18-SUMMARY.md](254-18-SUMMARY.md). | closed |
| T-254-36 | Repudiation | Out-of-scope CI reds silently ignored or silently "fixed" | medium | mitigate | Mechanical classifyRed with fixtures; escalation checkpoint records the owner's decision per entry; accept-known-red unavailable for the measured owner jobs. Evidence: [254-03-SUMMARY.md](254-03-SUMMARY.md). | closed |
| T-254-37 | Repudiation | Hand-authored red evidence | medium | mitigate | Red evidence is written and re-checked only through parseRedReport over the Playwright JSON report; setup errors and missing results are rejected by fixtures. Evidence: [254-12-SUMMARY.md](254-12-SUMMARY.md). | closed |
| T-254-38 | Repudiation | Correction batch recorded without tests or contract edits | medium | mitigate | --stage corrected requires tests and red evidence per fixed finding and finds each amended_text inside its contract file. Evidence: [254-13-SUMMARY.md](254-13-SUMMARY.md). | closed |
| T-254-39 | Repudiation | Environmental drift recorded as a design fix | medium | mitigate | Environmental classification is mechanical (same key failing on origin/main's latest Browser UAT run) and routed to the owner checkpoint instead of an automatic rebaseline. Evidence: [254-15-SUMMARY.md](254-15-SUMMARY.md). | closed |
| T-254-40 | Repudiation | Final reds accepted silently | medium | mitigate | Mechanical triage with recorded dispositions; owner jobs must be green; other out-of-scope reds require a recorded owner decision at 254-18-02. Evidence: [254-18-SUMMARY.md](254-18-SUMMARY.md). | closed |
| T-254-41 | Tampering | restamp-manifest used to hide a stale or hand-edited manifest | high | mitigate | restamp only re-reads the committed manifest bytes after its owner regenerated them (the mix verify! fixed-point check runs in the same task), refuses when CI is set, appends a resolved manifest-restamp deviation with from/to/cause from a fixed id block, and --check fails on any mismatch in the required owner; fixtures prove both digest-rule sides. Evidence: [254-09-SUMMARY.md](254-09-SUMMARY.md). | closed |
| T-254-42 | Tampering | Stale committed digest artifacts at the final commit | high | mitigate | Digest fixed-point check (manifest verify!, guide comparison, curation verifier, project --check, restamp-manifest --check) before the final push and in the wave-boundary gate, plus a scoped git status that fails if the aggregates rewrote any tracked digest artifact. Evidence: [254-18-SUMMARY.md](254-18-SUMMARY.md). | closed |
| T-254-SC | Tampering | npm/pip/cargo installs | high | mitigate | No installs or dependency changes (D-01); Playwright is resolved from the existing accrue_admin/node_modules. Evidence: phase summaries and D-01. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the configured high threshold count toward threats_open.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-03 | 43 | 43 | 0 | Codex orchestrator, ASVS L1 evidence review |

Evidence was checked against the executed plan summaries and final Phase 254 gates:
- [254-01-SUMMARY.md](254-01-SUMMARY.md)
- [254-02-SUMMARY.md](254-02-SUMMARY.md)
- [254-03-SUMMARY.md](254-03-SUMMARY.md)
- [254-04-SUMMARY.md](254-04-SUMMARY.md)
- [254-05-SUMMARY.md](254-05-SUMMARY.md)
- [254-06-SUMMARY.md](254-06-SUMMARY.md)
- [254-07-SUMMARY.md](254-07-SUMMARY.md)
- [254-08-SUMMARY.md](254-08-SUMMARY.md)
- [254-09-SUMMARY.md](254-09-SUMMARY.md)
- [254-10-SUMMARY.md](254-10-SUMMARY.md)
- [254-11-SUMMARY.md](254-11-SUMMARY.md)
- [254-12-SUMMARY.md](254-12-SUMMARY.md)
- [254-13-SUMMARY.md](254-13-SUMMARY.md)
- [254-14-SUMMARY.md](254-14-SUMMARY.md)
- [254-15-SUMMARY.md](254-15-SUMMARY.md)
- [254-16-SUMMARY.md](254-16-SUMMARY.md)
- [254-17-SUMMARY.md](254-17-SUMMARY.md)
- [254-18-SUMMARY.md](254-18-SUMMARY.md)

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-03
