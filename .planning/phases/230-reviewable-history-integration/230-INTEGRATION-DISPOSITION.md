# Integration Disposition

Sanitized schema-v1 evidence for the reviewable v1.62 integration candidate. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.

## Decisions adopted silently

This merge silently carries three decisions a reviewer should know about before approving: the release-please version line moving to **1.5.1**, the **Decimal 3 / ex_money 6** dependency migration (with Ecto 3.14), and the `:branding` `from_email`/`support_email` relaxation to optional. Hazard-level classification of each is Plan 230-03 scope.

## Candidate identity

**Fact:** merge commit 4d45002cafb3846810b84ff1afd84e7418476c50. **State:** recorded. **Owner:** release-engineering. **Next command:** `git rev-list --parents -n 1 refs/heads/integration/v1.62-candidate`.

| Ref | Object | Tree | Committed at |
| --- | --- | --- | --- |
| refs/heads/integration/v1.62-candidate | `4d45002cafb3846810b84ff1afd84e7418476c50` | `f690beb7c655f2683dd747a548da5a0d7dce0522` | 2026-09-15T14:58:55-04:00 |

## Binding

**Fact:** recomputed at collection time from live SHAs, never transcribed (D-15). **State:** recomputed. **Owner:** release-engineering. **Next command:** `git rev-parse origin/main`.

| Fact | Object |
| --- | --- |
| origin_main | `d30fc25dbf6ba551792c66ff451b4b93c0af4bf1` |
| milestone_tip | `8b248d9cec6531e124b2d05ea796e8a0aa904c93` |
| merge_base | `702dc482df0f65c332be1d4dfb821c4fe60aec49` |

## D-05 ancestry gates

**Fact:** all five gates re-run live against the candidate. **State:** proved. **Owner:** release-engineering. **Next command:** `node scripts/ci/verify_integration_disposition.mjs --require-ancestry`.

| Gate | State | Exit code | Evidence |
| --- | --- | --- | --- |
| closure_commits_ancestor | proved | 0 | closure=8a95fbe8109cf22efac4763f3d209e2e1b1aeba9,9e090eb5c6f3f384d5abe5e149cf5485dc120f9a,7cc501a33ac2d808b3fee9857e72a8c7eabd94e6,57c61a9a48f1ae84f7b3c3f45333eb6e5fb7261c |
| exactly_one_new_commit | proved | 0 | count=1 |
| origin_main_ancestor | proved | 0 | git merge-base --is-ancestor d30fc25dbf6ba551792c66ff451b4b93c0af4bf1 4d45002cafb3846810b84ff1afd84e7418476c50 |
| v1_61_ancestor | proved | 0 | git merge-base --is-ancestor v1.61 4d45002cafb3846810b84ff1afd84e7418476c50 |
| v1_61_identity | proved | 0 | tag=fdb41672dd9240b36623ab22a7a8377a2735e5a3 commit=e3b06794e4dc0d36deb5fc7cb94cbb0b3207d6d9 |

## Changed-file and commit scope

**Fact:** 334 files changed (223 .planning/-only, 111 source); 525 commits (265 .planning/-only). **State:** recomputed. **Owner:** release-engineering. **Next command:** `git diff --name-only \<merge-base\> \<candidate\>`.


## Post-merge commits

**Fact:** 0 commits declared beyond the merge commit itself. **State:** none declared. **Owner:** release-engineering. **Next command:** `git rev-list \<branch-tip\> ^4d45002cafb3846810b84ff1afd84e7418476c50`.

| Commit | Reason | Owner plan |
| --- | --- | --- |
| (none) | — | — |

## Hazards

**Fact:** 0 hazard rows recorded; hazard classification is Plan 230-03 scope. **State:** not yet classified. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Class | State |
| --- | --- |
| (none classified in this plan) | — |

