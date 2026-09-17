# Excluded-Commit Ledger

Answers "where did commit X go?" for every commit reachable from local `main` and not reachable from the reviewable v1.62 integration candidate. `grep` any 40-hex commit id below and its row is the answer -- no session memory required.

Candidate: `refs/heads/integration/v1.62-candidate` @ `bab50d92be2695b12d5853e7d578e600376e73d0` (committed 2026-09-15T15:36:35-04:00). Local main: `5c01f4bc38d4d38e8e080bde0e608e26ca9b5442`. Recomputed excluded-commit count: **80**.

## Rejected salvage (excluded-rejected)

**Fact:** landing these commits would put two competing baseline contracts on main and resurrect a rejected shell verifier as a live gate (D-08). **State:** 27 row(s). **Owner:** release-engineering. **Next command:** `node scripts/ci/verify_integration_disposition.mjs --require-excluded-ledger`.

| Commit | Subject | Patch-id occurrences (main) | Patch-id occurrences (candidate) | Published elsewhere |
| --- | --- | --- | --- | --- |
| `0720de884fb02b0b3c782f7a73518fa56f5f3003` | feat(226-05): separate CI queue and proof derivations | 1 | 0 | none |
| `1d438b514006b95d89df6f44c644a5bcdf670e40` | test(226-08): add public forged-job rejection cases | 1 | 0 | none |
| `20d9b008430fb91b3293fe0e02e308d14e4f0185` | feat(226-09): bind CI topology to workflow policy | 1 | 0 | none |
| `23d4453962442e442ee3dabfc7242b1d4b3af7a9` | test(226-07): exhaust canonical contract mutations | 1 | 0 | none |
| `282051d4bea242a3a2429fd427e4c28f8f928275` | feat(226-04): make baseline capture manifest-driven | 1 | 0 | none |
| `2b4686f69d573486ed35389e162981c49168c51d` | test(226-01): lock proof and privacy semantics | 1 | 0 | none |
| `2c440ab5c50f2f4f014b5963c7d3ecd5b1889a9c` | test(226-07): add failing canonical privacy gate | 1 | 0 | none |
| `4dff086a16c8efc75fbc32657b289d2a1aae628b` | feat(226-04): enforce fail-closed CI baseline proof | 1 | 0 | none |
| `57c8aa001f7d2ed2f7d138235b647918cebc6064` | feat(226-07): enforce canonical schema privacy | 1 | 0 | none |
| `5b580ba6b52b89bb299854e63cf6e1b2c6cc4705` | feat(226-10): authenticate staged chain duration | 1 | 0 | none |
| `6540f6e46096a021adbaac41d6296389a7265eeb` | fix(226-06): regenerate corrected CI baseline evidence | 1 | 0 | none |
| `66cf6d8c856dd5c92b229bbb0d1f3f6e6dcf3c7b` | feat(226-01): add metadata-only CI baseline tracer | 1 | 0 | none |
| `6f3e613d61b38e70e8f8aa9501697d683c25b9a0` | test(226-09): add workflow and proof completeness red gates | 1 | 0 | none |
| `6f9d92d94709220952f53f99ce2956019a8a0739` | feat(226-08): bind candidate jobs to workflow policy | 1 | 0 | none |
| `79f463028e38362da3ca29c4b6ed4608d52d143a` | test(226-01): add failing CI baseline contract | 1 | 0 | none |
| `896927fd504e8f100975c8dc4394727493f54270` | feat(226-09): require workflow and complete release proof | 1 | 0 | none |
| `8d7cfbdab5f5ca5c48b70f2670bea1e3f9042f45` | test(226-03): add failing topology contract | 1 | 0 | none |
| `916343bc2e82cd75a96f5c52f4dcc68e9c7b361d` | test(226-10): add derived duration red gates | 1 | 0 | none |
| `9cd5dafc470fad32cb89df2f11c128b9868a3404` | feat(226-11): bind collector proof to main ref | 1 | 0 | none |
| `a9b7f868a1f7db90b3560df7d505509d7cc737c2` | test(226-08): cover policy and proof forgeries | 1 | 0 | none |
| `ad55ae3c5286e3ffba3de65610e9237c4a5e146f` | test(226-05): cover provider failure semantics | 1 | 0 | none |
| `c76198a5574f2de01ef1063afd0ab218f97d99f5` | test(226-09): add policy-driven topology red gates | 1 | 0 | none |
| `dba3633bcc594363c10853abb7790829f2683b16` | ci(226-03): gate baseline semantics without topology drift | 1 | 0 | none |
| `df6f193516e9bc65f40c48a770a5cea17e82add1` | test(226-10): add derived signature red gates | 1 | 0 | none |
| `f4aa40afd0a3475172f6c8ff0c337aa6e8bc5655` | feat(226-05): validate exact collector records | 1 | 0 | none |
| `fd530ea1f655b764f951ae94fc49f5fd6016e26a` | test(226-05): add collector record contract red gate | 1 | 0 | none |
| `ffed6a22f2ce5025ce90c40a4269f5e47b62d105` | feat(226-10): derive failure signatures from jobs | 1 | 0 | none |

## Carried on candidate (carried-on-candidate)

**Fact:** already present on the candidate; recorded so nobody re-cherry-picks it (D-12). **State:** 1 row(s). **Owner:** release-engineering. **Next command:** `git merge-base --is-ancestor \<commit\> \<candidate\>`.

| Commit | Subject | Patch-id occurrences (main) | Patch-id occurrences (candidate) | Published elsewhere |
| --- | --- | --- | --- | --- |
| `afddc87c5245bd1abb97dcac735aef0a2938bdf5` | docs(quick-260915-dpd): Fix eager Mix.env/0 evaluation in Accrue auth modules that crashes OTP releases at boot | 0 | 1 | none |

## Superseded, collapsed (excluded-superseded)

**Fact:** excluded wholesale (D-07): the abandoned line's entire unique non-planning surface is superseded, proved once below and shared by every row in this section. **State:** 53 row(s), one shared supersession proof. **Owner:** release-engineering. **Next command:** `node scripts/ci/collect_integration_disposition.mjs`.

| Commit | Subject | Patch-id occurrences (main) | Patch-id occurrences (candidate) | Published elsewhere |
| --- | --- | --- | --- | --- |
| `0f48298b9f8414ff179d864ea461162d04b44210` | docs(226): plan remaining baseline proof gaps | 1 | 0 | none |
| `18fe2d00d3f0dccd7fea3be8da508c03d31a9421` | docs(226-04): complete CI baseline proof semantics plan | 1 | 0 | none |
| `1a3367bb55ccb06886febb7d72d74c7b4efad5b4` | docs(226): add proof-semantics gap closure plan | 1 | 0 | none |
| `2b20f0019f1e088d90926dbd93134bffff40c6b9` | docs(226): correct phase plan count | 1 | 0 | none |
| `397cd145f022a63b056fda657232c05a69f19ad8` | docs(226-02): complete measured baseline plan | 1 | 0 | none |
| `39b36e1f223a0af0fd73f716175c72fdf4516725` | docs(phase-226): update tracking after wave 3 | 1 | 0 | none |
| `3fecff132b74ed420f4d8fd8523c8b83e060858e` | docs(phase-226): revert premature Complete requirements after gaps found | 3 | 2 | none |
| `42773cb84e70c87f5b72f748817395659bad2d09` | docs(phase-226): revert premature Complete requirements after gaps found | 1 | 0 | none |
| `44f7ca9eb5b80bc3b9f60f193c9c7818217fa01a` | docs(226-02): publish measured three-run baseline | 1 | 0 | none |
| `49f7a2bc54af31db98c3c9392003f306c89d5753` | docs(226): finalize gap closure planning | 1 | 0 | none |
| `4c935c8c1eedaa59e381e5e575f929c55da426d8` | docs(226-08): finalize proof semantics plan | 1 | 0 | none |
| `53d18ba3a98f863b30d49da6fc254e846b57bc5f` | docs(226-08): record policy-binding coverage | 1 | 0 | none |
| `54e5a3f8663bd19836a8065998eff471e888d5c3` | docs(226): create gap closure plan | 1 | 0 | none |
| `55135ce25082934b2f1175eca4b3b084169727c0` | docs(226-10): complete ci baseline proof semantics plan | 1 | 0 | none |
| `557d3f5112231030d43b791aeaf8efe2e8c2caa8` | docs(226): add validation strategy | 1 | 0 | none |
| `5ae535a47391aeacffd2663faaba17b93e17b7f7` | docs(226-06): complete corrected baseline publication plan | 1 | 0 | none |
| `5bf903140248f5d0bf3acdbbbb926deca9e67344` | docs(226): capture phase context | 1 | 0 | none |
| `5c01f4bc38d4d38e8e080bde0e608e26ca9b5442` | docs(226): record failed-cohort verification and diagnosis | 1 | 0 | none |
| `5da8e6b887354eded1b6dc25968ad7679d6bbd83` | docs(226-01): complete CI baseline tracer plan | 1 | 0 | origin/phase-226-baseline-5da8e6b88735 |
| `60910cc3a5fdcf47a5f03f6339366f20a20002d2` | docs(226): finalize gap-closure plans | 1 | 0 | none |
| `657f28ca926752b6561c37568a1e1736cbf6c21c` | docs(226-10): update phase completion state | 1 | 0 | none |
| `661274631d9d5a90ecd522d07adfff75a843c25b` | docs(226): research CI baseline proof semantics | 1 | 0 | none |
| `6707b38e9ff8cabdcca5fe75db602d3977d3ffd7` | docs(226-07): complete canonical privacy plan | 1 | 0 | none |
| `697771824daaaf5f574cd893106072894d6d3a51` | docs(226): create gap closure plan | 1 | 0 | none |
| `6b0e78e5d9d199922f946971440d85469ea03ebb` | docs(state): record phase 226 context session | 1 | 0 | none |
| `70c546a3a83834f3c1b62de312e667d66996cfe5` | docs(phase-226): record verification gaps | 1 | 0 | none |
| `74d8a4668fe10f711609d545ecd15afd62c36e2a` | docs(226): add code review report | 1 | 0 | none |
| `766d16c3e351e20e8c3e903855ce044162728d72` | docs(226): add code review report | 1 | 0 | none |
| `7e353457b0ae4ba539a8243b3d9bafc4188ff197` | docs(phase-226): record verification gaps | 1 | 0 | none |
| `7f74310bfce59b6bf2284987148b1fc5976a30b4` | docs(226): create phase plan | 1 | 0 | none |
| `804f6869cfb787fe25a685de8138d32d918ad13e` | docs(226-05): complete baseline proof semantics plan | 1 | 0 | none |
| `86a982d1ea6738c65d6f459c4909f7e5bce047b3` | fix(226): revise plans based on checker feedback | 1 | 0 | none |
| `88216a2a53ddd643034d1a38a09791027eaa0af1` | docs(226): record CI promotion checkpoint | 1 | 0 | none |
| `8a6f3aa9e1c0d904ad8e193b1d2382209998209d` | docs(226-05): record canonical migration stub | 1 | 0 | none |
| `8b5b9caf22522d8109e5fa0a1a394aa881063c3f` | docs(226-09): complete CI baseline proof semantics plan | 1 | 0 | none |
| `8d4ca2a386f7d7896f46b42c4461a9ca11eab272` | feat(226-04): repair canonical CI evidence cohort | 1 | 0 | none |
| `8fdb2426e71af1efd5e954dd10620c1a9e8b1346` | docs(phase-226): revert premature Complete requirements after gaps found | 3 | 2 | none |
| `90060cbeb4a0b65e04021ce196f715386cc5cb7b` | docs(226): add code review report | 1 | 0 | none |
| `912034a710d16d2e1ad624c6d82effd9f10d3b75` | docs(226): create gap closure plan | 1 | 0 | none |
| `a47c52964cea8329851f2e6af8c6ee5e3bf12a7e` | docs(226): finalize gap closure plan | 1 | 0 | none |
| `b1c12639344034409c3b9a69f227fdadee6ea088` | docs(226-06): certify CI baseline gap closure | 1 | 0 | none |
| `b4937986db263b7ceea6a0aaa777b603aac92fef` | docs(226-09): update phase execution state | 1 | 0 | none |
| `c12af3493b705b4dbc17e80bf5f4298db95b9bf0` | docs(226): create phase plan | 1 | 0 | none |
| `ccdb2b264f49ecfea3374c8fb108a1b4c17f38f1` | docs(226): add code review report | 1 | 0 | none |
| `ccfe752e8400ceaaca5e13aa4cb1ad85d5108289` | docs(phase-226): revert premature Complete requirements after gaps found | 3 | 2 | none |
| `d8579ceb83a40d2613156771111ee4e1b4398432` | docs(226-08): complete proof semantics plan | 1 | 0 | none |
| `dfde44eeb4f559d0f633b0523a6b1498137e1eef` | docs(226-02): record comparable CI dispatch cohort | 1 | 0 | none |
| `e0a31b35a028653dff38f0ca0b17538b9cfbe623` | docs(226): create CI baseline proof semantics plans | 1 | 0 | none |
| `ed7b114d0f42b1502f505d8783c4e2bef977094d` | docs(226-03): complete baseline proof semantics plan | 1 | 0 | none |
| `ee3df1ca181cc8c99deb252b615c9ff9b414444d` | docs(226-03): document CI and host setup ownership | 1 | 0 | none |
| `f1ed0ee07c50b4845b850fcdfde5a04183b2da73` | docs(226): map CI baseline patterns | 1 | 0 | none |
| `fb94b3d959a76015d5c87b1ac94a3a247ba90527` | docs(226): create gap closure plan | 1 | 0 | none |
| `fc6463ee7bab6fac17a93f9d7385872a6ad63855` | docs(226): add code review report | 1 | 0 | none |

## Shared supersession evidence

**Fact:** tree-level file-existence sweep plus the BASE-01/BASE-02 requirement-level completion citation, shared by every excluded-superseded and carried-on-candidate row above. **State:** proved. **Owner:** release-engineering. **Next command:** `git cat-file -e \<candidate\>:\<path\>`.

**Tree level:**

| Path | Exists on candidate | Superseded by |
| --- | --- | --- |
| scripts/ci/capture_ci_baseline.sh | false | scripts/ci/collect_ci_baseline.mjs |
| scripts/ci/ci_baseline_workflow_policy.json | false | — |
| scripts/ci/verify_ci_baseline_contract.sh | false | scripts/ci/verify_ci_baseline.mjs |

Plan inventory: abandoned line reached plan 11, milestone line reached plan 21.

**Requirement level:**

File: `.planning/milestones/v1.61-REQUIREMENTS.md`

| Requirement | Matched text |
| --- | --- |
| BASE-01 | \| BASE-01 \| Phase 226 \| Complete \| |
| BASE-02 | \| BASE-02 \| Phase 226 \| Complete \| |

## PR #44 disposition

**Fact:** head \`fix/release-boot-env-resolver\` @ \`3f8338cdb7ce54d3ca49f703565c1048b68f7646\` is base \`main\` @ \`5c01f4bc38d4d38e8e080bde0e608e26ca9b5442\` plus 4 commit(s), 0 behind; state=closed, mergeable=MERGEABLE. **State:** close-unmerged-no-comment. **Owner:** release-engineering. **Next command:** `gh pr view 44`.

Head is local main plus 4 commits; merging would have permanently published all locally-excluded abandoned Phase-226 commits onto main. All 4 useful commits are already on the milestone branch as exact patch-id matches, so nothing is lost by closing unmerged (D-10). STATE.md prior description of this PR as "four commits cherry-picked off main" described intent, not the pushed branch; the correction to STATE.md is Plan 230-07 Task 3. Closed unmerged by this plan (Task 2) via gh pr close 44. Maintainer-authorized deviation from the D-10 default: NO comment was posted (Plan 230-07 checkpoint resolution) to avoid any possibility of leaking identifiers in public GitHub content; the superseding-SHA evidence instead lives only in this committed ledger (matched_commits below) and in scripts/ci/README.md, never in a public PR comment.

| PR-branch commit | Milestone-branch commit | Patch id |
| --- | --- | --- |
| `3f8338cdb7ce54d3ca49f703565c1048b68f7646` | `5653216c6f5d012eaef71f48a8ffb746c1aee8c3` | `99053db47b51b52ba73b0ec329ffd036bf93b7bb` |
| `88b5b377a4ae901ca78afb172afd3341630a8914` | `2de4389b44f03c512fdc06a23b0ee75156d34314` | `0b4c04dea9a5e82f64289407b85ab367a42234ae` |
| `a08eb5e2aa30e81f1ff8fbe1a3158243b6ecf4b7` | `9eae363a8af44896cba76e7850b220ac5caec0f5` | `e942f8e7922cc423bdbd8ad2e81c563fa949da99` |
| `b3d566c9e58bfea742e16a77c8e48c1ad98a2628` | `173607d9e59b249a2e61ce8fd1d517018c36b1cd` | `8e56e72fe2d757f52dfcbe16d6bc4a6824dd7160` |

