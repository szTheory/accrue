# Integration Disposition

Sanitized schema-v1 evidence for the reviewable v1.62 integration candidate. This is a deterministic projection: no raw payloads, actor identities, secret values, or absolute paths are present.

<!-- phase230-integration-disposition:start -->

## Decisions adopted silently

This merge silently carries three decisions a reviewer should know about before approving: the release-please version line moving to **1.5.1**, the **Decimal 3 / ex_money 6** dependency migration (with Ecto 3.14), and the `:branding` `from_email`/`support_email` relaxation to optional. Each is classified below with an evidence-backed disposition.

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

Recomputed co-touched file count: **6**. Every co-touched file below owes a recorded, machine-recomputable disposition; convergent-identical rows owe nothing and are collapsed last.

## Hazard: disjoint-hunk

**Fact:** 1 co-touched file(s) of class disjoint-hunk. **State:** 1 row(s) classified. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| accrue/lib/accrue/config.ex | proved | 0 | 230-03 | {"command":["git","show","4d45002cafb3846810b84ff1afd84e7418476c50:accrue/lib/accrue/config.ex"],"left_marker_present":true,"right_marker_present":true} |

## Hazard: version-release-train-drift

**Fact:** 0 co-touched file(s) of class version-release-train-drift. **State:** 0 rows. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | — |

## Hazard: version-keyed-contract-script

**Fact:** 0 co-touched file(s) of class version-keyed-contract-script. **State:** 0 rows. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | — |

## Hazard: dependency-lock-drift

**Fact:** 1 co-touched file(s) of class dependency-lock-drift. **State:** 1 row(s) classified. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| accrue/mix.exs | non_run | — | 230-05 | {"command":["mix","deps.get","--check-locked"],"note":"origin/main moved {:decimal, \\"~\> 2.0\\"} -\> \\"~\> 3.0\\" and {:ex_money, \\"~\> 5.24\\"} -\> \\"~\> 6.2\\" (plus explicit ex_cldr/ex_cldr_numbers), with Ecto 3.13.6 -\> 3.14.2. Milestone money-math and StreamData property tests have never compiled against Decimal 3 / ex_money 6 (D-17)."} |

## Hazard: schema-relaxation

**Fact:** 0 co-touched file(s) of class schema-relaxation. **State:** 0 rows. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | — |

## Hazard: doc-rewrite

**Fact:** 1 co-touched file(s) of class doc-rewrite. **State:** 1 row(s) classified. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| accrue/guides/entitlements.md | advisory | — | 230-03 | {"command":["git","diff","--numstat","8b248d9cec6531e124b2d05ea796e8a0aa904c93","d30fc25dbf6ba551792c66ff451b4b93c0af4bf1","--","accrue/guides/entitlements.md"],"insertions":52,"deletions":4} |

## Hazard: archive-path-regression

**Fact:** 0 co-touched file(s) of class archive-path-regression. **State:** 0 rows. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | — |

## Hazard: generated-artifact-staleness

**Fact:** 0 co-touched file(s) of class generated-artifact-staleness. **State:** 0 rows. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | State | Exit code | Owner | Evidence |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | — |

## Phase-231-owned lanes (D-21 boundary)

**Fact:** the mechanical corollary of D-20: a check with the same result on origin/main alone belongs to Phase 231, not Phase 230. **State:** 13 lanes explicitly excluded. **Owner:** release-engineering. **Next command:** `node scripts/ci/verify_integration_disposition.mjs --require-hazard-universe`.

| Lane | State | Owner | Command | Reason |
| --- | --- | --- | --- | --- |
| admin-visual-pixel-diff | non_run | 231 | `npx playwright test --grep visual-regression` | The admin visual pixel-diff gate would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| asset-rebuild | non_run | 231 | `mix accrue_admin.assets.build` | Asset rebuild would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| copy-strings-json-regeneration | non_run | 231 | `mix accrue_admin.copy_strings.generate` | copy_strings.json regeneration would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| dialyzer-plt | non_run | 231 | `mix dialyzer` | Dialyzer/PLT (its ignore-list hazard is discharged by blob identity in this plan) would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| fresh-clone-run | non_run | 231 | `git clone .` | Any fresh-clone run would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| full-mix-test | non_run | 231 | `mix test` | Full \`mix test\` for any project would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| github-actions-dispatch | non_run | 231 | `gh workflow run ci.yml` | Any GitHub Actions dispatch (229's read-only posture still binds) would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| host-docker-smoke | non_run | 231 | `docker compose up --build --abort-on-container-exit` | host-docker-smoke would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| host-integration | non_run | 231 | `mix test --only host_integration` | host-integration would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| mix-hex-publish-dry-run | non_run | 231 | `mix hex.publish --dry-run` | \`mix hex.publish --dry-run\` would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| playwright-e2e | non_run | 231 | `npx playwright test` | Playwright E2E would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| provider-live-stripe-lane | non_run | 231 | `mix test.live` | Any provider/live-Stripe lane would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |
| storybook-specs | non_run | 231 | `npm run test:storybook` | Storybook specs would have the same result on origin/main alone (D-20 mechanical corollary) — belongs to Phase 231's exact-SHA release gate proof (GATE-01..03), not Phase 230. |

## Convergent-identical (owe nothing)

**Fact:** 3 co-touched file(s) blob-identical on both merge parents, proved by SHA equality. **State:** 3 row(s) proved. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Path | Left blob | Right blob |
| --- | --- | --- |
| accrue_admin/test/accrue_admin/live/entitlements_live_test.exs | `3981bbd8dee1131f20122bcde856398077589886` | `3981bbd8dee1131f20122bcde856398077589886` |
| accrue/.dialyzer_ignore.exs | `1536762f0e643af42fc14f6928d4ffe79dbaacaf` | `1536762f0e643af42fc14f6928d4ffe79dbaacaf` |
| accrue/test/accrue/webhook/ingest_test.exs | `425a87f6b5e1d97f938c4d449ef2ef250ffbc863` | `425a87f6b5e1d97f938c4d449ef2ef250ffbc863` |

<!-- phase230-integration-disposition:end -->
