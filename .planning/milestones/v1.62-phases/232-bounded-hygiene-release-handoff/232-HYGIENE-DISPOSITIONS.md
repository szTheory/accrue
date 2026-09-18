# Hygiene Dispositions

Sanitized schema-v1 evidence classifying every untracked path, every worktree, every debug session, and every remote maintenance or release branch as retained, committed, archived, superseded, or authorized for removal, before any cleanup touches the repository. No raw payloads, actor identities, secret values, or absolute paths are present.

This document is a deterministic re-render (a projection) of the schema-v1 JSON record identified below; the JSON is the evidence of record, and this Markdown is generated from it, never edited directly.

A `remote_branch` row can only ever carry disposition `retained` or `superseded` and can only ever declare `authorization_required: false` -- this verifier cannot express branch deletion, and no row may express deletion of a remote branch or a tag; the no-deletion decision is a structural invariant, not an intention (D-47).

## Candidate identity

Candidate object: `2cc876c6a74301e23009adb4080af7ba78c3de6c`. Observed at: 2026-09-17T12:13:19-04:00. Rows: **25**.

Evidence command: `git status --porcelain -uall`

## Untracked paths

11 row(s).

| Name | Disposition | Reason | Content hash | Supersedes / duplicates | Authorization required |
| --- | --- | --- | --- | --- | --- |
| .planning/milestone.lock | retained | live GSD session lock for the currently-executing plan (PID-keyed, ephemeral); operational runtime state, not intended for version control. | — | — | — |
| .planning/phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md | authorized_for_removal | Degraded shadow of the committed archive copy at .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md. phase_evidence_path.mjs:29 resolves the active (unarchived) path first, so a local phase-200 verifier run reads this untracked copy instead of the good archived one. This file is byte-identical to its archive counterpart (sha256 re-verified 2026-09-16), but it is part of the same degraded-shadow directory as its four siblings and shares their removal rationale: local reads must resolve to the archive, not a stale duplicate directory. | e18cc311b9157047a1ffd848e8a227564f197c454e1872258397f51604d4ecfa | .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/200-SIGN-OFF.md | — |
| .planning/phases/200-idempotent-verification-sign-off/200-STORYBOOK-COVERAGE.md | authorized_for_removal | Degraded shadow of the committed archive copy. Re-verified 2026-09-16 via sha256 diff: this untracked copy's hash differs from the archived one -- it is a strictly worse, superseded duplicate that shadows the good archive under phase_evidence_path.mjs's active-path-first resolution. | b016d86e4837a0a8a2539273d4687a7ea4c682ad3532aaeebcb3eae35dc4bfd7 | .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/200-STORYBOOK-COVERAGE.md | — |
| .planning/phases/200-idempotent-verification-sign-off/200-VERIFICATION.md | authorized_for_removal | Degraded shadow of the committed archive copy. Re-verified 2026-09-16: the row for \`node accrue_admin/e2e/phase200-judge.mjs\` reads \`pending-after-report-generation\` in this untracked copy versus \`passed\` in the archived one -- a live local-vs-CI truth divergence caused by phase_evidence_path.mjs's active-path-first resolution reading this worse copy locally while CI reads the good archived one. | 27e9a3a62588ac035fa31806a35a4825dafb7637ec32a967fb35777302c9d127 | .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/200-VERIFICATION.md | — |
| .planning/phases/200-idempotent-verification-sign-off/artifacts.manifest.json | authorized_for_removal | Degraded shadow of the committed archive copy. Re-verified 2026-09-16: this untracked copy's evidence array omits the \`200-SCORECARD.md\` entry present in the archived manifest and its own evidence-entry hashes differ, confirming it is the same worse duplicate, not an independent artifact. | a5fec460c239520d47b1b56f250a2698544c70309e7c3866a64f2bfd07c2ceaf | .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/artifacts.manifest.json | — |
| .planning/phases/200-idempotent-verification-sign-off/judge.findings.json | authorized_for_removal | Degraded shadow of the committed archive copy. Re-verified 2026-09-16 via sha256 diff: this untracked copy is byte-identical to the archived one, but it is part of the same degraded-shadow directory as its four siblings and shares their removal rationale: local reads must resolve to the archive, not a stale duplicate directory. | 63f78a1e2140ed090cfb92b94d81632b6559e2b834ce73ae301f095c518db668 | .planning/milestones/v1.54-phases/200-idempotent-verification-sign-off/judge.findings.json | — |
| .planning/state.json | retained | GSD's live per-session state cache, regenerated on each run; operational runtime state alongside STATE.md, not intended for version control. | — | — | — |
| .planning/v1.61-v1.61-MILESTONE-AUDIT.md | superseded | Re-verified 2026-09-16: the doubled \`vX.Y-vX.Y-\` filename prefix is not a typo -- it is an established repo convention (v1.33, v1.34, v1.35, v1.36, v1.39, v1.59 all carry the same doubled prefix and are tracked). This copy (mtime 2026-08-12) is superseded on recency by the committed \`.planning/v1.61-MILESTONE-AUDIT.md\` (last commit 2026-09-12), which postdates it. | — | .planning/v1.61-MILESTONE-AUDIT.md | — |
| .tool-versions | superseded | Acted on 2026-09-16 by plan 232-08 finding 3 (commit 45b26ba5f838984d1f642cd603d5e6837c276b77): now git-tracked on this branch, reversing the prior never-git-tracked intent (D-50). The untracked_path row this record described no longer exists as an untracked item -- it is superseded by the now-tracked file at the same path. Tracking reversal confirmed per this plan's checkpoint task. | — | the now-tracked .tool-versions (commit 45b26ba5f838984d1f642cd603d5e6837c276b77) | — |
| scripts/ci/stripe_test_fixtures.mjs | superseded | Acted on 2026-09-16 by plan 232-08 finding 1 (commit 70ea09b14237f3aa381825ab62ca9de5a32ec738): committed into the tree with the shared main_module.mjs guard applied and a real node:test registration added, per the tracked provider_proof_automation.mjs RELEVANT_PATHS allowlist that already named it. The untracked_path row this record described no longer exists as an untracked item -- it is superseded by the now-tracked, guard-covered file at the same path. | — | the now-tracked scripts/ci/stripe_test_fixtures.mjs (commit 70ea09b14237f3aa381825ab62ca9de5a32ec738) | — |
| scripts/ci/verify_stripe_test_fixtures.mjs | superseded | Acted on 2026-09-16 by plan 232-08 finding 1 (commit 70ea09b14237f3aa381825ab62ca9de5a32ec738): committed into the tree with the shared main_module.mjs guard applied (it previously had no entrypoint guard at all) and its four assertion cases registered as real node:test entries, per the tracked provider_proof_automation.mjs RELEVANT_PATHS allowlist that already named it. The untracked_path row this record described no longer exists as an untracked item -- it is superseded by the now-tracked, guard-covered file at the same path. | — | the now-tracked scripts/ci/verify_stripe_test_fixtures.mjs (commit 70ea09b14237f3aa381825ab62ca9de5a32ec738) | — |

## Worktrees

1 row(s).

| Name | Disposition | Reason | Content hash | Supersedes / duplicates | Authorization required |
| --- | --- | --- | --- | --- | --- |
| gsd/milestone-v1.62-release-integration-hygiene | retained | Re-verified 2026-09-16: \`git worktree list --porcelain\` reports exactly one worktree -- this checkout, on the milestone branch, with a clean working tree apart from the classified untracked paths above. HYG-01's worktree clause is vacuous: there is nothing to clean up here, stated positively rather than left blank. | — | — | — |

## Debug sessions

2 row(s).

| Name | Disposition | Reason | Content hash | Supersedes / duplicates | Authorization required |
| --- | --- | --- | --- | --- | --- |
| tampered-review | retained | Local-only negative-control test artifact (\`tamper: same file count, different content\`) used to prove the D-07 blob-identity revert check catches a same-file-count-different-content class of silent revert. Local-only by design and must stay local; flagged explicitly so a future reader does not wonder why it exists. | — | — | — |
| tampered-review-2 | retained | Local-only negative-control test artifact (\`tamper v2\`), sibling of tampered-review. Local-only by design and must stay local; flagged explicitly so a future reader does not wonder why it exists. | — | — | — |

## Remote branches

11 row(s).

| Name | Disposition | Reason | Content hash | Supersedes / duplicates | Authorization required |
| --- | --- | --- | --- | --- | --- |
| origin/fix/chimeway-opaque-recipient | retained | Active fix branch with an open local tracking branch at the same commit; not superseded by any other ref. | — | — | false |
| origin/fix/chimeway-opaque-recipient-release | retained | Active fix/release branch with an open local tracking branch at the same commit; not superseded by any other ref. | — | — | false |
| origin/fix/adopter-app-1.5.1 | retained | Adopter-named ref. Renaming this branch and its origin peer is maintainer-decided as fail-forward and deferred to a future capsule mint (232-CONTEXT.md deferred list); retained as-is for this phase, not superseded. | — | — | false |
| origin/fix/release-boot-env-resolver | retained | Active fix branch with an open local tracking branch at the same commit; not superseded by any other ref. | — | — | false |
| origin/fix/release-otp-28-1 | retained | Active fix branch with an open local tracking branch at the same commit; not superseded by any other ref. | — | — | false |
| origin/gsd/phase-225-required-lane-signal-repair | retained | Active GSD work branch; local tracking branch is ahead by 4 commits (unpushed local work), not superseded by any other ref. | — | — | false |
| origin/integration/v1.62-candidate | retained | The v1.62 candidate integration branch this same phase's re-cut work actively re-cuts and re-gates (232-CONTEXT.md D-01..D-12); actively governed by this phase, not superseded. | — | — | false |
| origin/integration/v1.62-candidate-recut | retained | Published by plan 232-09 as the fresh-supersession re-cut candidate after this record was first captured; it is the head this phase hands off for review. Retained under the phase-wide classification-only decision -- no remote ref is deleted, renamed, or force-pushed. | — | — | false |
| origin/main | retained | Primary trunk; the repository's default branch. | — | — | false |
| origin/phase-226-baseline-5da8e6b88735 | retained | Re-verified 2026-09-16: actively referenced by tracked automation code -- collect_integration_disposition.mjs:528 exports \`PUBLISHED_ELSEWHERE_REF = "origin/phase-226-baseline-5da8e6b88735"\`, and render_integration_disposition.mjs's own test suite asserts this exact ref name renders. Deleting it would break a live code reference, not just tidy history. | — | — | false |
| origin/release-please--branches--main | retained | Active Release Please working branch; local tracking branch \`release-please--branches--main\` and dependent local branch \`repair/release-pr39\` both track this ref. Per prompts/GSD-REPO-HYGIENE.md, stale release-please branches are only deleted when they have no open PR -- deletion status not evaluated in this classification-only phase. | — | — | false |

