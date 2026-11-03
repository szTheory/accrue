# 254-15 checkpoint log

Evidence note for the continuation agent (precedent: 254-03-CHECKPOINT-LOG.md). Created when 254-15-01 stopped at checkpoint 254-15-02; later owner decisions and follow-up evidence are appended below.

## State at the stop (2026-10-29)

- Branch gsd/phase-252-production-backed-subscription-stories, pushed head `27c6444d2c2de8f07eea3e3ed604e3d1a4bdd742` (PR #58 still a draft). This log is a later local-only commit.
- Pre-push gate on that exact commit: efficiency, script guard coverage, census, no-home-paths, archive invariants, package docs, PR claims, phase254 projection and budget checks, docs-contracts steps (only the known SL-G, SL-F-without-token and Executable UAT steps red), the admin release sequence (format, compile, 786 tests, credo, dialyzer, docs), the assets rebuild and storybook recompose freshness, the full Phase 200 runner including the Phase 252 and 253 aggregates and the budget check, and the whole local `npm run e2e` (all green after the fix below).
- Owner push authorization (254-03-01) covered the push and the one mint dispatch.

## The one mint (D-08)

- Mint run **40876347666** (workflow_dispatch on `27c6444d2`, inputs reason "CIQ-03 mint of the subscription visual baselines after the 254-12/13 correction batch", finding_id "CIQ-03"). Mint job success: repeat-each=3 stability proof, manifest build and the manifest-backed set check all passed. Nothing was committed from it and no second mint was dispatched.
- Artifact `phase211-visual-baselines` downloaded to `accrue_admin/tmp/phase254/mint/40876347666/` (gitignored): `e2e/__screenshots__/visual-desktop/` (44 PNG plus manifest.json) and `tmp/phase254/visual-identity/` (32 identity files). No symlinks. PNGs are Linux-minted only.
- Disposition (`scratchpad` analysis against the committed PNGs): 32 new case PNGs; legacy keys unchanged: component-kitchen, component-kitchen-dark, dashboard, dashboard-dark; legacy keys changed:

| key | before | after | classification |
|-----|--------|-------|----------------|
| subscription-detail, subscription-detail-dark | 1280x1859 | 1280x1879 (+20) | DR-254-03 (label rule) with DR-254-01 (rhythm) and the 254-12 reflow rules: expected |
| invoice-detail, invoice-detail-dark | 1280x1643 | 1280x1637 (-6) | DR-254-03 (field-list label rule): expected |
| subscriptions, subscriptions-dark | 1280x932 | 1280x940 (+8) | A11Y-254-28 (`.ax-data-table-identity-secondary` row gap, 254-12): NOT a design-review finding, the plan says these must stay byte-identical: regression key |
| invoices, invoices-dark | 1280x1032 | 1280x1044 (+12) | A11Y-254-28 (same shared DataTable component): regression key |

- Environmental check: the latest origin/main Browser UAT run (40361348536, push, success) passed the visual gate, so none of the keys is environmental.
- Plan defect found: "subscriptions.png and subscriptions-dark.png equal their merge-base blobs" cannot hold, because 254-03 re-minted both on the runner (commit 365338781, dispatch 40771021813) before this plan. The invariant that matters is equality with the baselines at the start of 254-15 (HEAD c017aeede); they are not equal (above).

## Fixes made while observing (all in the pushed head)

- `ccea86232` the manifest build re-attests a legacy (phase211-committed) PNG that moved since the merge-base (`--base`); without it `check --base` fails for subscriptions and subscriptions-dark whose entries were legacy while their bytes differ from the merge-base (reproduced on the real tree before the fix).
- `c59843a9d` `confirmedCapturesMatchManifest` and the confirmed-stage verdict rules in the design review verifier (23 self-test scenarios); capture route text for pages corrected.
- `b77de3baf` Phase 191 spec: the Connect fee drawer journey now expects the 254-12 scroll-region tab stop (3 of 3 red before, 3 of 3 green after).
- `27c6444d2` JSON report added for the browser jobs so visual per-cell durations are measurable.

## Observation runs on `27c6444d2` (attempt 1, nothing rerun)

- CI 40876348250: Docs and bash contracts red only at SL-G (KR-254-06, accepted). **Admin Phase 200 deterministic guardrails red**: `phase253-compositions-browser`, 22 of 151 cells with undispositioned deep-probe observations that did not reproduce in three local runs: 20 dark cells `probe-focus-visible ring-contrast-1.02` (and 1.12 on `#step-up-code`) on `summary`, `nav a`, drawer panel; 2 light 320px cells `probe-text-spacing clipped-under-text-spacing` on `aside.ax-overlay-panel`. Likely cause: the probe reads the focus ring and the clipped panel while a CSS transition is still in flight on the slower runner (the probe waits for animations once at line 414 of `accrue_admin/e2e/phase254-a11y-probes.js`, not after each Tab). Evidence: artifact `phase200-admin-playwright-evidence` (error-context per cell), `phase253-machine-evidence`.
- Browser UAT 40876348154 (pull_request): "Run browser UAT" and the Admin hooks test passed; red at "Require complete committed visual baseline set" (32 case baselines missing, expected before the rebaseline commit); the manifest check and the visual gate steps were skipped behind it.
- Dispatch run 40876347666 also ran its own Browser UAT job (red on the same set guard, a dispatch artifact not a pull_request observation).

## Open for the owner (254-15-02)

See the checkpoint report: the four list keys (A11Y-254-28 attribution) and the new red in `admin-phase200-guardrails`.

## 254-15-02 Owner disposition (2026-10-29)

- Gate: blocking-human, never auto-answered. The owner answered per item (relayed by the orchestrator, recorded verbatim).
- Item A (subscriptions, subscriptions-dark, invoices, invoices-dark; caused by A11Y-254-28): **"accept-attributable (Rec.)"**. Executed as: commit exactly mint 40876347666 (no second mint, no AMD-254-06); `baselines_changed` maps the four keys to A11Y-254-28; the design review verifier accepts a routed A11Y-254-NN id only when it is a routed-defect of the register at AMD-254-05's register_commit (negative controls: an id outside that scope, a justified exception, an unknown id shape and a record without the amendment are rejected).
- Item B (admin-phase200-guardrails, 22 deep-probe cells): **"fix-in-phase (Rec.)"**. Executed as: reproduce first, prove RED, fix deterministically with no sleep and no timeout bump, prove green under throttling, new commit, full pre-push gate, push, observe a new attempt-1 run, never rerun; if the reds persist or another undecided red appears in an owner job, stop with another checkpoint.
- Plan defect recorded: "subscriptions.png and subscriptions-dark.png equal their merge-base blobs" could never hold after 254-03's runner re-mint (365338781); the real invariant is equality with the baselines at c017aeede, and they differ (+8 px, A11Y-254-28).
- `subscriptions.png` no longer carries the H1 token swap's zero-visual-change proof; `DR-254-02:computed` (767 and 768 CSS px, green before and after) carries it.
- The rebaseline commit adopts a theme-toggle change in the invoices baselines: the previous `invoices.png` shows the System option selected, the current render shows Light. The gate's tolerance hid it before.

## Item B reproduction and fix

- Not reproducible under CDP CPU throttling alone: the three failing dark cells and the 320px light drawer cells passed at 4x and 8x (the Phase 253 cell universe runs fine at 6x with 3 workers). The CI evidence (ring-contrast 1.02 on dark cells only, a start colour of a transition; clipping measured on a panel that was not settled) points at probes reading before in-flight transitions and fonts settle: the `--ax-dur-2` token is 1ms under reduced motion, so a slow frame still shows the start value.
- RED: a new injected control (`transition_in_flight`: a white ring on a wrapper whose background starts a 700ms transition to black) with `settlePage` disabled reads `ring-contrast-1.03` and fails the geometry negative-control cell. GREEN: with the settle in place the ring reads settled. 196 cell executions at 6x CPU throttling, 3 workers, repeat 2 pass.
- Fix: `settlePage` in `phase254-a11y-probes.js` waits on `document.fonts.ready` and the `finished` promises of every finite running animation (strict: a transition that never settles fails), called before axe, target size, every focus read, text spacing and text scale. Commit `79d4c8532`.

## Observation on `a9204d3b3` (2026-10-29, attempt 1, nothing rerun)

- Browser UAT **40890395793: success** (strict set guard, identity manifest check and the Phase 211 visual gate all green on the 44 committed Linux baselines; job 1241 s, added 97 s of the 180 s allowance; 32 visual cells median 828 ms, p90 1234 ms; visual gate step 45 s).
- CI **40890395756: red in `admin-phase200-guardrails` again**, lane `phase253-compositions-browser`, the same 22 cells as run 40876348250 with the same ratios (20 dark `probe-focus-visible` ring-contrast-1.02, 1.12 on `#step-up-code`; 2 light 320px `probe-text-spacing` on `aside.ax-overlay-panel`). The settle fix did not change the CI result, so the cause is not a transition in flight. Docs and bash contracts red only at SL-G (KR-254-06).
- The reds are deterministic on the runner and absent locally under: unthrottled, CDP CPU throttling at 4x, 6x and 8x, 3 workers, repeat-each 2, `CI=true GITHUB_ACTIONS=true`. Stopping per the owner's instruction (reds persist on CI).
- Local-only commit `32c00d2c2` (design review at confirmed, budget metrics and deviations, KR-254-07 open) is not pushed.

## KR-254-07 owner decision, round 2 (2026-11-03)

- Owner response, verbatim: **"1"** (option 1: fix-in-phase with Linux-side diagnosis).
- Scope: diagnose the repeated CI-only failures on Linux before another code change. Any fix must be a new commit followed by a new attempt-1 observation; do not rerun a CI job to obtain green.

## KR-254-07 owner checkpoint, round 3 (2026-11-03)

- Trigger: the Linux diagnosis isolated the original failures to missing focus styles and drawer-footer overflow. The candidate CSS fixes clear five of the six focused reproductions; one active dark page cell still has ten `probe-focus-visible` observations classified `obscured`.
- Linux evidence: Playwright 1.59.1 Noble, amd64, viewport 1280×1000. For each affected app sidebar link, the target center is inside the Storybook host sidebar: target x=128–303, host `#psb-sidebar` x=0–240. The sandbox starts at x=96. The hit test runs in the main HTML document and returns the host sidebar. The saved failure screenshot appears to show the app navigation separately; the coordinate/hit-test discrepancy needs an owner-approved disposition before changing scope.
- Candidate fixes retained locally: a low-specificity `:focus-visible` ring fallback clears dark ring contrast (measured 6.81–8.05:1 across sampled controls); wrapping `.ax-detail-drawer-footer` clears both 320px light text-spacing findings. Clean Linux run: five focused cells pass; `active | viewport | 1280px | dark` remains red with ten obscured-link observations.
- No CI job was rerun, no commit or push was made, and temporary probe instrumentation was reverted. Current source and generated CSS changes remain uncommitted. `.planning/config.json` remains untouched and must not be staged.
- Owner decision required before proceeding: **1. Extend fix-in-phase** to resolve the measured Storybook/app overlap while retaining the unobscured-focus assertion (recommended); or **2. Halt Phase 254 here** and defer the remaining owner-job red. The prior round-2 answer authorized the initial Linux diagnosis and CSS fixes; the plan requires a new checkpoint when a red persists.

## KR-254-07 owner decision, round 3 (2026-11-03)

- Owner response, verbatim: **"follow ur recs"**.
- Mapped to recommended option 1: extend the Phase 254 fix to resolve the remaining measured Storybook/app overlap and retain the focus-obscuration assertion.
- Continue Linux diagnosis and implementation under the existing constraint: prove the selected Linux cells green before the full pre-push gate; then create a new commit, push under the existing authorization, and observe a new attempt-1 CI run. Never rerun CI to obtain green; never stage `.planning/config.json`.
- Linux follow-up resolved the screenshot/geometry discrepancy. Before keyboard traversal, `#psb-live-container` had `scrollWidth=1232`, `clientWidth=1040`, `scrollLeft=0`, the app sidebar link began at x=320, and the app shell began at x=288. Focusing the overflowing Storybook page-tab row moved the whole canvas to `scrollLeft=192`; the same app link then began at x=128 underneath `#psb-sidebar` (x=0–240). The failure screenshot showed the restored initial frame, while the probe sampled the transient shifted frame.
- Fix: make the Storybook page-tab row an internal horizontal scroller and allow its flex ancestors to shrink. After the fix the live container stayed at `scrollWidth=clientWidth=1040` through keyboard traversal and `scrollLeft=0`; the app links remained at x=320. The original active dark cell and five related cells all passed in a clean Linux run; the focus-obscuration assertion remains enabled. No CI job was rerun.
- Verification evidence: `mcr.microsoft.com/playwright:v1.59.1-noble`, linux/amd64, owned disposable `admin-review` lab, partition `2026110314470013`: 6/6 focused Phase 253 cells passed (active dark 1280, filtered-empty dark 1280, review-cancel-now dark 1280 and light 320, awaiting-step-up dark 1280 and light 320). `node scripts/ci/recompose_storybook_css.mjs --check` and `git diff --check` passed. The full pre-push gate and push remain pending.
- The first full pre-push pass stopped at `verify_ci_script_contract --repo .`: the baseline collector and verifier's nested fixture tests failed with 14 vs 19 samples. The synthetic cases use 2026-08-01 timestamps while the cohort helper defaulted to the real clock; on 2026-11-03 the rolling 90-day cutoff excluded five cases. The test-only adapter now freezes its fixture clock at 2026-09-01. The production cohort implementation is unchanged. Red was reproduced with `node --test` for each module; after the fix, `verify_ci_baseline.mjs` passes 6/6 tests and `collect_ci_baseline.mjs` passes 21/21.

## First-attempt observation on `0aad361bf` (2026-11-03, no reruns)

- CI **41673726626: failure**. The `Admin Phase 200 deterministic guardrails` owner job passed in 19m35s; Phase 192, group contracts, drift/docs, Stripe Tax, iOS compatibility and all release matrix jobs passed. The docs/baseline job's only red was `Artifact fixed-point and derivation-cycle guard (SL-G)`: the fixtures passed (18/18), then the aggregate correctly refused to report a pass because Phase 254 had zero completed artifacts. This is retained for Plan 18 as instructed.
- The parked `Admin UI ratchet guardrails` job failed at `Verify frozen ratchet evidence`. `phase254_measure.mjs triage` classified it `pre-existing-on-main` against reference CI run `40387584954`; the failure reports unfrozen baseline/round data and open findings. The adjacent ratchet self-tests passed. This parked, pre-existing CI red is not attributed to Phase 254.
- Browser UAT **41673726764, attempt 1, head `0aad361bfce8a69f1e3477a563f43eb256a699dd`: failure**. The browser command passed (239 expected tests, 43 skipped, zero unexpected); the baseline-set guard passed. `Check visual baseline identity manifest` then failed for all 44 changed entries with `served css_sha256 differs from the committed asset`, so `Phase 211 visual regression gate` was skipped. The PR run correctly skipped the mint job. Machine evidence records the run revision, Linux/amd64, Ubuntu 24.04, Node 22.23.4, Playwright 1.59.1, and a clean tree.
- The mechanical triage entry for the manifest step has no source path and falls into its generic `environmental` bucket. Causal evidence is narrower: the branch CSS and generated served bundles changed in commit `728322fbb`, the recorded baseline CSS fingerprints predate that change, and reference origin/main Browser UAT run `40361348536` succeeded. This is not evidence of an environmental pixel drift; the visual gate never ran, so pixel equality is still unknown. Aligning all 44 identities requires one additional Linux mint/rebaseline beyond the already-used mint `40876347666`.

## 254-15-02 owner disposition, round 4 (2026-11-03)

- Trigger: the new attempt-1 Browser UAT failed the identity-manifest step after the approved CSS correction; the visual comparison was skipped.
- Owner response, verbatim (2026-11-03): **"Why do I have to authorize all these little freaking things? Unless it's particularly controversial or there's big implications in terms of, yeah, you can go ahead and do it. And please remember this going forward. Don't waste my time."**
- Mapped disposition: `fix-in-phase`. The owner authorized exactly one additional Linux mint/rebaseline commit and a new attempt-1 observation, recorded as AMD-254-06. The first-attempt results above are complete; no CI rerun was started.
- Preference correction: routine, reversible and in-scope execution choices should be handled autonomously. Ask only when a choice is materially controversial or has significant implications. Do not interrupt for routine approvals.

## Owner-authorized additional mint and rebaseline (2026-11-03)

- Mint run **41682891880**, attempt 1, head `b6964b53598c8bda81c009f9267fec1b3fdf9e26`. Mint job **126080904913** succeeded: snapshot capture, `--repeat-each=3` stability proof, identity-manifest build/check and success-only artifact upload all passed.
- Artifact downloaded to `accrue_admin/tmp/phase254/mint/41682891880/` (gitignored). The 44-PNG baseline set and manifest verify against the artifact; all 44 identities pass `phase254_visual_manifest.mjs check --base <merge-base>`.
- The checked-in baseline diff has 20 changed PNGs, all Phase 254 cases, all mapped to `A11Y-254-28`: mounted disclosure-focus (320/1280, both themes); mounted review-open (320, both themes); page active and incomplete-evidence (320/1280, both themes); page review-cancel-now (320, both themes); scheduled-cancellation (320/1280, both themes). No Phase 211 PNG changed. `subscriptions.png` and `subscriptions-dark.png` remain byte-identical to the pre-rebaseline committed tree.
- The manifest re-attests 40 minted entries to run `41682891880`; the four unchanged Phase 211 entries retain their legacy provenance. `phase254-visual-cases.json` records AMD-254-06 with the run id and the owner's verbatim decision. The `phase254-selection.json` projection remains byte-identical.
- The confirmed design-review record now points to fix commit `b6964b53598c8bda81c009f9267fec1b3fdf9e26`, whose CSS hashes match the mint identities; all 16 capture hashes and the 20 newly changed `baselines_changed` entries are refreshed. Its 51 tests, 24-scenario self-test and confirmed-stage check pass locally. Final confirmation still depends on the post-rebaseline Browser UAT visual gate.
- Local checks pass: selection projector check/self-test, 41 selection tests, strict 44-baseline-set guard, visual manifest check and budget manifest check. The plan's stale subscription-image assertion now compares with `HEAD^` (the pre-rebaseline commit), because the earlier Phase 254 mint had already changed those images from `origin/main`.
- PR Browser UAT **41682890835** and the dispatch Browser UAT from **41682891880** completed on the old baseline: browser tests and the strict baseline-set guard passed, the identity-manifest check failed as expected because this rebaseline was not yet committed, and pixel comparison was skipped. These are attempt 1 observations; neither was rerun.
- PR CI **41682890822** completed. Docs-contracts had the expected retained SL-G red. Admin Phase 200 guardrails also failed at `subscription-render-browser`: the Phase 252 lab command exited with code 0 and generated 14 render rows, all `passed`, but the evidence parser rejected captured stdout with `Playwright JSON reporter output is not a single valid JSON report`. The wrapper then marked the lane failed; the raw stdout was not uploaded, so its contamination source cannot be determined from this run. The same aggregate and browser lane passed on the immediately preceding PR run **41673726626** (19,130 ms; 15 Playwright tests; 21 commands). This is classified as a reporter/evidence-pipeline observation, not a demonstrated visual regression. No rerun was made; observe the next new-head attempt-1 run for recurrence.
- PR Browser UAT **41682890835** completed on old head `b6964b535`: browser tests and the strict baseline-set guard passed; the manifest identity step failed because the approved rebaseline had not yet been committed, so the pixel gate was skipped. The dispatch Browser UAT for mint **41682891880** had the same expected stale-manifest result. Both remain attempt-1 observations and were not rerun.
- This new `subscription-render-browser` red is an owner-job stop under the prior decision record: the Phase 252 reporter evidence is incomplete, and its raw stdout was not uploaded, so the underlying source cannot be determined from the current artifact. It is not a reported render-row failure. Do not push the prepared rebaseline past this stop until the owner selects `fix-in-phase` or `halt`; no further mint is implicated by either choice.

## 254-15-02 owner disposition, round 5 (2026-11-03)

- Trigger: PR CI 41682890822 exited successfully from the Phase 252 browser process and produced 14 passing render rows, but the aggregate rejected stdout as a malformed Playwright JSON report. The raw child stdout was not retained, so the exact contaminating bytes are unknown.
- Owner response, verbatim (2026-11-03): **"Yeah, we can fix the reporter capture. I want to follow your recommendations. So that sounds good."**
- Mapped disposition: `fix-in-phase`. The owner authorized isolating Playwright's JSON reporter through `PLAYWRIGHT_JSON_OUTPUT_FILE`, keeping unrelated child stdout out of the aggregate's machine-readable stdout, retaining the report as CI evidence, and making a new commit followed by a first-attempt CI observation. Do not rerun CI 41682890822 or mint again.
- Linux-side reproduction: the pinned Playwright 1.59.1 Noble harness prepended `REPORTER_HARNESS_NOISE` to child stdout. Parsing combined stdout failed with the same validator error; setting `PLAYWRIGHT_JSON_OUTPUT_FILE` kept the report valid while the noise remained separate. This proves the contamination mode, not the exact source in CI 41682890822.
- Implementation is committed as `d17710e07` in `phase252_lab.mjs`, both aggregate command plans, their contract tests, and the CI artifact upload paths. The report is read from its dedicated file, validated as JSON, forwarded alone to stdout, and recorded by relative path and SHA-256 in command evidence. A successful process with a missing report fails closed. The original screenshot mint remains run 41682891880; its separate rebaseline commit is `b6a5ec363`.
- Verification: the focused Phase 252/253 reporter and command-plan suite passed 81/81; the CI script-contract suite passed its strict repository check; the Phase 200 shell contract passed; Phase 254 selection tests passed 41/41 and its self-test/project check passed; the budget manifest, strict 44-baseline set, visual manifest and design-review tests (51/51) passed. No prior CI run or mint was repeated.
- User instruction: handle routine, reversible, in-scope work without repeated approval requests; ask only when a choice has material scope, risk, cost, irreversibility, or phase-boundary implications.
- The post-commit selection projection, budget digest, strict 44-baseline set and visual manifest checks passed on `b6a5ec363`. The reporter fix and dedicated rebaseline are ready to push together; no CI rerun or additional mint has occurred.
