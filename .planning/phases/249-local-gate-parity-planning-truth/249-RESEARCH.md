# Phase 249: Local Gate Parity & Planning Truth - Research

**Researched:** 2026-10-24
**Domain:** Repository CI-gate reconciliation (Node/bash planning-doc contracts, Elixir/Phoenix admin build, Playwright contracts), planning-state hygiene
**Confidence:** HIGH for every red re-measured in this session (commands, failure text and file:line captured). MEDIUM for fixes that need a maintainer disposition decision (flagged `[ASSUMED]`). Unreplayed lanes are listed explicitly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Gate integrity
- Fix every red at its source. Never weaken, skip, or make a gate vacuous ("absent is OK" must itself be provable). A gate that finds nothing must be shown able to find a known positive (CLAUDE.md "Agent Working Discipline").
- Never falsify sha256-pinned archived evidence. `scripts/ci/verify_phase248_render_proof.mjs` is pinned in the archived 248 capture manifest, so do not edit it. If the D-32 module-boundary guard must cover a pinned script, find a compliant route: the contract's own exemption mechanism if one exists, or a documented exemption with rationale. Do not edit the pinned bytes.
- Archived phase fingerprints (`covered_digest` under `.planning/milestones/*-phases/`) are frozen by design. Do not re-mint them. Recompute the current phase's digest only through `scanArtifact` + `computeDigest`.

Planning truth
- Delete `.planning/HANDOFF.json` (stale, 2026-10-07).
- Record the out-of-band owner-feedback commits `3d7d949d..b4a7eeac` (2026-10-11..19) in MILESTONES.md (under v1.66, next to "Post-archive tooling") and in STATE.md as work done outside GSD. Cite `.planning/notes/2026-10-1{2,3,4,8}-admin-owner-feedback.md` as receipts. No backdated PLAN/VERIFICATION and no phase verdict claimed.
- File resolved debug sessions (`.planning/debug/phase24{5,8}-*.md`, status resolved) under `debug/resolved/`.
- Keep the 63 `.planning/quick/*` dirs as they are. Keep milestone tags local.

### Claude's Discretion
- Plan/wave decomposition, ordering, and the specific technical fix for each red, provided the gate-integrity rules above hold.
- Whether a red is better fixed in the verifier (archive-awareness) or in the artifact, decided by which one is actually wrong.

### Deferred Ideas (OUT OF SCOPE)
Webhook list multi-status filter, recovery fixture integrity, LiveView 1.1.32 alignment, ExMoney/Storybook notices, Sigra datetime triage, dead `ci.yml:881` alternation, mailglass cap documentation, and re-capture or retirement of the drifted 245/248 evidence verifiers. Out of scope for the phase: pushing, opening a PR, anything remote (Phase 250), release alignment (Phase 251), new product behavior.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GREEN-01 | docs-contracts-shift-left planning-doc steps pass locally | Reds R1-R7 below (SL-E, SL-A, SL-G, DSY-01 doc gate, exec-UAT, D-16, D-32) with root cause and at-source fix |
| GREEN-02 | `accrue_admin` compiles with `--warnings-as-errors` | R8: one-token fix `subscription` -> `_subscription` at `subscription_live.ex:1286` |
| GREEN-03 | DSY-01 annotations + D-32 guard | R4 (5 `@media` lines) and R7 (9 files, exemption design) |
| GREEN-04 | Phase 190 contract + browser probes classified | R9 (regex vs `status: passed`) and R10 (3 probes x 2 projects, all stale contract) |
| GREEN-05 | accrue / accrue_admin / accrue_portal suites, host-integration, Playwright lane pass | Measured suites (R11-R13), commands + prerequisites + cost for the lanes not replayed |
| TRUTH-01 | HANDOFF.json removed, STATE reflects v1.67, debug sessions filed | Section "Planning Truth" |
| TRUTH-02 | Out-of-band 2026-10-11..19 commits recorded | Section "Planning Truth" |
</phase_requirements>

## Summary

I replayed every `run:` block of job `docs-contracts-shift-left` (steps 2-43, 47-50) from the repo root, each written to a temp `.sh` and run with `bash -eo pipefail` (blocks under `/private/tmp/claude-501/.../scratchpad/steps/`). Seven steps are red. Steps 15 (v1.17 friction), 24 (roadmap hygiene), 25 (release notes) and the other 33 steps pass. Step 6 (SL-F PR-body currency) fails closed with `no credential available to read pull request #45`; it needs a GitHub token and a live PR body, so it belongs to Phase 250, not here.

Beyond the CONTEXT list, the broader local replay found three more reds that CONTEXT did not name: `mix format --check-formatted` fails in `accrue` (1 file) and `accrue_admin` (2 files), `mix credo --strict` fails in `accrue_admin` (19 findings, exit 28), and `accrue_portal`'s suite has a seed-order flake (`seed 262447` fails; seeds 0-3 pass). The full `accrue` suite has 24 failures, all in `PackageDocsVerifierTest`, all with the same root as the DSY-01 doc gate. `accrue_admin` ExUnit is 746 tests, 0 failures.

Four findings change what a naive fix would do:
1. **SL-E and SL-G cannot go green until Phase 249 itself closes.** SL-E refuses to pass with zero Complete requirements, and SL-G refuses to pass with zero artifacts or zero edges for the current phase. Both need Phase 249's own tracked `249-VERIFICATION.md` (`status: passed`, `covered_files`, `covered_digest`) and a generated `249-UAT.md`. The last plan must mint them, then mark requirements Complete.
2. **D-16 fails on two layers.** Dispositioning the 12 open ledger rows is necessary (it also fixes SL-A) but not sufficient. The verifier requires exact set equality between the live non-open ledger rows and the frozen 14-row v1.62 record, so after dispositioning, 24 newer rows (ids 15-38) still show `missing`. I proved this with the real parser. The verifier needs an explicit, visible scope bound, or a new record must be minted.
3. **Editing archived v1.66 SUMMARY files would drift their `covered_digest`.** The 245-248 `*-VERIFICATION.md` files list those summaries in `covered_files`. The exec-UAT contract failure is a genuine policy violation (the summaries really do record visual/human inspection), so the compliant route is a narrow, hash-pinned, rationale-bearing recorded-deviation mechanism, not rewriting history.
4. **The D-32 non-vacuity half will also fail for the 9 files** (bare `node --test` of a CLI verifier exits 1 or registers one self-named test). Adding the guard import alone is not enough. The contract's only exemption (`LIBRARY_MODULE_ALLOWLIST`) is guard-coverage only and scoped to library modules.

**Primary recommendation:** Treat this as 13 root-cause reds. Fix each at its source in this order: (1) trivial/independent code fixes (R8, R4, R11, R12, R13), (2) contract-vs-artifact reconciliations (R9, R10, R5, R7, R6/R2 with a maintainer-visible disposition ledger), (3) planning truth (TRUTH-01/02), (4) last plan: set `current_phase: 249`, mint 249 VERIFICATION/UAT, mark GREEN/TRUTH requirements Complete, then re-run the whole job replay plus the lanes below.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Planning-doc contract verifiers (SL-A/E/G, D-16, D-32, exec-UAT) | Repo CI scripts (`scripts/ci/*.mjs`) | `.planning/` artifacts | Verifier decides; artifact is the thing measured. Fix whichever is actually wrong (per red below). |
| Admin compile warning, DSY-01 CSS annotation | `accrue_admin` source | `scripts/ci/verify_package_docs.sh` | The source is wrong; the guard is correct and must not change. |
| Phase 190 browser contract | `accrue_admin/e2e` spec | `accrue_admin/lib` copy | Spec asserts removed copy; spec is stale, source is intentional (owner-feedback commit). |
| Window ledger / dispositions | `.planning/WINDOWS.md` via `gsd-tools windows` | `verify_window_dispositions.mjs` scope | Ledger rows need disposition; verifier join needs an explicit scope bound. |
| Planning truth (HANDOFF, MILESTONES, STATE, debug filing) | `.planning/` docs | contract scripts that re-read them | Docs only; re-run roadmap/friction/release-notes contracts after edits. |

## Standard Stack

No new external packages are needed. This phase edits existing Node ESM scripts, bash verifiers, Elixir source/tests, Playwright specs, and planning docs.

### Core (already in repo, versions measured)
| Tool | Version | Purpose |
|------|---------|---------|
| Elixir / OTP | 1.19.5 / 28 [VERIFIED: `elixir --version` this session] | `mix compile/test/format/credo` |
| Node | 22.14.0 [VERIFIED: `.tool-versions` `nodejs 22.14.0`] | `node --test` contract suites |
| `@playwright/test` | repo-pinned in `accrue_admin/package.json` | Phase 190 gate (`npm run e2e:group-contracts`) |
| Postgres | accepting on `localhost:5432` [VERIFIED: `pg_isready` -> `/tmp:5432 - accepting connections`] | test DB |
| `gsd-tools windows` | `status | append | waive | fixed` [VERIFIED: `gsd-tools.cjs:3426-3442`] | ledger dispositions |

### Package Legitimacy Audit
No external packages are installed or added by this phase. Audit not applicable. **Packages removed due to [SLOP]:** none. **Packages flagged [SUS]:** none.

## Architecture Patterns

### Replay recipe (use verbatim for every re-measure)
```bash
# extract run: blocks of a CI job into temp .sh files (never bash -c on a dumped string)
python3 extract.py <scratch> docs-contracts-shift-left   # yaml.safe_load(.github/workflows/ci.yml)
GITHUB_OUTPUT=/dev/null GITHUB_STEP_SUMMARY=/dev/null bash -eo pipefail <scratch>/steps/<file>.sh
```
The whole docs-contracts job minus npm/mix installs and the token-harness regenerate steps runs in well under 2 minutes locally.

### Dependency/ordering graph (drives plan waves)
```
R8 (compile) --unblocks--> R9/R10 (190 gate) --also gates--> admin-hardening + admin-phase200 jobs (they re-run e2e:group-contracts)
R4 (DSY-01)  --clears---> 24 accrue test failures + docs step 10
R6 (disposition 12 rows) --makes true--> R2 (SL-A claim C1 open_count: 0) ; R6 join-scope fix needed for D-16
R5 (exec UAT) independent ; R7 (D-32) independent
LAST: set current_phase 249 + mint 249 VERIFICATION/UAT + mark Complete --> R1 (SL-E), R3 (SL-G incl. node test 18)
```

### Anti-Patterns to Avoid
- **Passing a dumped string to `bash -c`**: escapes newlines, gives false results (CONTEXT specific).
- **`git grep -c -- "<pat>"`**: `--` before pattern is a pathspec and silently returns zero (CLAUDE.md). Use `-e`.
- **Editing a covered archived file then calling the fingerprint "stale"**: archived digests are frozen by design; the sweep detector for archive literals is `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .`.
- **Weakening a gate to go green**: every fix below keeps or strengthens the assertion and ships a negative control.

## Re-measured Reds (13 root causes)

Legend: `[VERIFIED]` = opened/ran this session. Verbatim failure text is quoted.

### R1. SL-E completion evidence (GREEN-01)
- **Step:** `Completion-mark evidence (SL-E)`. **Command:** `node scripts/ci/verify_completion_evidence.mjs --repo . --require-completion-evidence --require-table-agreement` (third command of the step; the first two pass).
- **Failure now:** `completion evidence: FAIL: zero Complete requirements parsed from the traceability table (12 data rows seen) -- refusing to pass vacuously` [VERIFIED: `verify_completion_evidence.mjs:204`]. (The CONTEXT error `requirements file does not exist` is already resolved by commit 956e5dd5.)
- **Root cause:** the artifact is honest. `.planning/REQUIREMENTS.md` has all 12 rows `Pending`, and the verifier deliberately refuses to pass with zero Complete rows (anti-vacuity, header lines 38-41: "a traceability table that parses data rows but zero Complete rows fails loudly"). On `origin/main` it passes because the v1.62 file has Complete rows.
- **Wrong artifact:** none. Do not change the verifier or add an allowlist (its header: "There is deliberately NO allowlist in this file").
- **Fix:** at phase close, mark the Phase 249 requirements `Complete` in BOTH the checkbox list and the traceability table (`--require-table-agreement` checks both directions), after `249-VERIFICATION.md` carries front-matter `status: passed` and at least one `249-*-SUMMARY.md`/`249-UAT.md` cites each ID literally (`GREEN-01` ... `TRUTH-02`). The verifier resolves the phase by the number in the Phase cell (`Phase 249`) [VERIFIED: `verify_completion_evidence.mjs:208-228`].
- **Touches archived evidence:** no.
- **Positive control:** the fixtures run (`--fixtures ... 12 scenarios`) already proves it can fail and pass; the real-repo run must flip from FAIL to PASS only after the artifacts exist. Also run once with the table marked Complete but VERIFICATION `status` not `passed` to see it fail (scratch copy, not the live tree).
- **Sequencing risk:** Phases 250/251 requirements stay Pending, which is fine (Pending needs no evidence).

### R2. SL-A PR claims, claim C1 (GREEN-01)
- **Step:** `PR claims contract (SL-A)`. **Failure:** `pr claims: FAIL: claim C1 (fixed_string_count) asserts 1 but the measured value is 0` / `reproduce: grep -c -F -- "open_count: 0" .planning/WINDOWS.md`.
- **Where the claim is defined:** the typed sidecar `.planning/milestones/v1.62-phases/232-bounded-hygiene-release-handoff/232-INTEGRATION-PR.json` (resolved by `phase_evidence_path.mjs`). Verbatim:
  ```json
  {"id": "C1", "kind": "fixed_string_count", "path": ".planning/WINDOWS.md", "needle": "open_count: 0", "expected": 1,
   "text": "Every lane's disposition is fixed-and-proved or waived-with-owner-and-cause, never silently red -- the ship-window ledger records no open window."}
  ```
  [VERIFIED: file read this session]. The claims file is archived and pinned (C2 is a `file_sha256`); it must not be edited.
- **Root cause:** `.planning/WINDOWS.md` front matter is `open_count: 12`, `waived_count: 6`, `fixed_count: 20`, `total_count: 38` [VERIFIED: file head]. Twelve rows 15-20, 28-30, 36-38 were recorded `open` by phases 234-247 (the `origin/main` ledger had `open_count: 0`, 14 rows).
- **Wrong artifact:** the ledger (rows left open). The claim is a true statement of the v1.62 invariant ("no open window") and should hold again.
- **Fix:** disposition all 12 rows with `gsd-tools windows fixed <id>` or `windows waive <id> "<reason>"` (reason required; waive rationale should state owner + cause + release impact so the D-16 waiver-completeness vocabulary is respected). Never hand-edit the table: `readShipWindowRows` rejects inconsistent counts (`ship-window ledger counts are inconsistent`) [VERIFIED: ran it against a hand-edited copy].
- **Proposed dispositions** `[ASSUMED]` (maintainer must confirm; the data below is the row text read this session):

  | id | phase | row says | Proposed | Basis |
  |----|-------|----------|----------|-------|
  | 15, 16, 17 | 234 | tests added after implementation / no RED commit | waive | historical TDD-ordering process deviation; the tests exist and pass (admin suite 746/0) |
  | 18 | 234 | `roadmap.update-plan-progress` returned `missing_phase_details` | waive | GSD tool defect, ROADMAP reconciled by hand |
  | 19 | 235 | live Braintree acceptance unverified, gateway HTTP 500 | waive | external-credential-gated; mock SDK proves the denial |
  | 20 | 235 | test-only Portal origin/route added | fixed | covered by portal tests (111 tests) |
  | 28 | 241 | renamed validated return destination in `charge_live.ex` | fixed | compiled and covered by admin suite |
  | 29 | 241 | confirmation controls expose disabled/loading state | fixed | intentional behavior; admin suite |
  | 30 | 241 | `copy_strings.json` regenerated | fixed | I regenerated into scratch and `cmp` shows it byte-identical to committed (`COPY-FRESH`) [VERIFIED] |
  | 36 | 244 | mounted browser read-outage unobserved | waive | focused LiveView tests cover retry; browser-unobservable |
  | 37 | 246 | direct coupon `q` URLs keep default Valid selection | fixed | behavior retained, tests |
  | 38 | 247 | `time_display.js` rejects impossible ISO | fixed | JS node tests (`test/js/*.mjs`) |
- **Touches archived evidence:** no (WINDOWS.md is live; the claims JSON is only read).
- **Positive control:** `grep -c -F -e "open_count: 0" .planning/WINDOWS.md` must print `1` after, and `0` before (already shown). Run the full SL-A step.

### R3. SL-G artifact fixed point (GREEN-01) - two distinct failures
- **Step:** `Artifact fixed-point and derivation-cycle guard (SL-G)`; three sub-commands.
- **3a. Node test 18 (hard-coded phase "232"):** `not ok 18 - the live 232-UAT.md / 232-VERIFICATION.md pair passes all three checks after the cycle is broken at its source` with `.planning/milestones/v1.62-phases/232-.../232-VERIFICATION.md: covered_digest mismatch over 52 covered files -- committed "v1:sha256:726a..." , recomputed "v1:sha256:a516..."`. The same assertion also makes `--fixtures` fail, because `verifyFixtures()` runs all SCENARIOS.
  - **Root cause:** test 18 hard-binds `const phase = "232";` [VERIFIED: `verify_artifact_fixed_point.mjs` ~lines 568-580] and recomputes a live digest over the 52 `covered_files` of an ARCHIVED verification. Four of those covered files are LIVE paths that legitimately changed since v1.62: `.github/workflows/ci.yml`, `.planning/REQUIREMENTS.md`, `.planning/WINDOWS.md`, `scripts/ci/verify_package_docs.sh` (checked each against `origin/main` this session; the other covered scripts are byte-identical). On `origin/main` it passes only because nothing had moved. A test that recomputes an archived digest over live files can never stay green; this contradicts the repo's own rule (archived fingerprints frozen by design; only the current phase is recomputed).
  - **Wrong artifact:** the verifier's test 18, not the archived 232 VERIFICATION. Do not re-mint the archived digest.
  - **Fix:** make test 18 resolve the phase the way `main()` does (`readStateCurrentPhase(repo)`), or restrict 232-pinned assertions to the digest-independent halves (acyclic + fixed-point still pass for 232, because the failure is at the `assertDigestMatch` line 579) and apply digest-match to the current phase only. Keep the "non-empty" asserts (`edges.length > 0`, `pairs.length > 0`, `verificationArtifacts.length > 0`) so it stays non-vacuous. The editable file is not in any archived `covered_files` except the 232 VERIFICATION list; confirm it is absent from the 52 (it is: only the `scripts/ci` files listed above are covered).
- **3b. Real-repo run:** `artifact fixed point: FAIL: .planning/STATE.md: current_phase is missing`.
  - **Root cause:** `readStateCurrentPhase` requires a frontmatter scalar. The v1.67 `STATE.md` (rewritten by commit 1881d7dc) dropped the key; v1.66 left `current_phase: null`; `origin/main` has `current_phase: 232` [VERIFIED: `git show origin/main:.planning/STATE.md` line 16].
  - **Simulated outcome with `current_phase: 249` (scratch repo, `git init` + commit):**
    - only `249-CONTEXT.md` tracked: `artifact fixed point: FAIL: phase 249: zero artifacts discovered -- refusing to report a pass over zero inspected artifacts`
    - plus a bare tracked `249-VERIFICATION.md`: `artifact fixed point: FAIL: zero artifact pairs discovered -- refusing to report a pass over zero inspected edges`
    So the gate is intrinsically red until Phase 249 owns a tracked VERIFICATION with `covered_files` + `covered_digest` and a generated UAT (`source: executable-summary-coverage`). `liveArtifactFiles` uses `git ls-files`, so untracked files do not count (the 249 dir is currently untracked).
  - **Fix (final plan):** set `current_phase: 249` (and `current_phase_name`) in STATE.md frontmatter via GSD state tooling or by hand, keep it at 249 until the phase closes, mint `249-UAT.md` through `verify_executable_uat_contract.mjs`'s writer, write `249-VERIFICATION.md` with `covered_files` (tracked paths only) and compute `covered_digest` ONLY through the module's own `scanArtifact` + `computeDigest` (never by hand), then commit and run the real invocation. Also: whenever Phase 250/251 starts and `current_phase` flips, the gate is red until that phase has its own artifacts.
- **Positive control:** the scratch-repo runs above already show it fails for missing artifacts; additionally flip one byte in a covered file and confirm `covered_digest mismatch`.

### R4. DSY-01 breakpoint annotations (GREEN-03) - also clears 24 accrue test failures
- **Step:** `verify_package_docs.sh`. **Failure:** `<repo>/accrue_admin/assets/css/app.css must not have bare breakpoint @media without an --ax-bp-* annotation comment (DSY-01 — add a /* --ax-bp-NAME ↑/↓ */ comment to every breakpoint @media)`.
- **Guard (do not edit):** `scripts/ci/verify_package_docs.sh:519-524`: `breakpoint_medias=$(grep -E '@media \((min|max)-width: [0-9.]+px\)' "$app_css" || true)` then `grep -v -- '--ax-bp-'`.
- **Offending lines (exact, from the guard's own regex)** [VERIFIED: ran the same grep]:
  ```
  4415:@media (max-width: 599.98px) {
  7205:@media (max-width: 639px) {
  7228:@media (min-width: 640px) {
  7231:@media (min-width: 1000px) {
  7487:@media (max-width: 599.98px) {
  ```
  Lines with `rem` (1523 `30rem`, 7387 `40rem`) and the combined reduced-motion query (2190) do not match the guard regex and need no change.
- **Annotation convention** (existing, verbatim): `@media (min-width: 768px) { /* --ax-bp-md ↑ */`, `@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */`, `@media (max-width: 700px) { /* --ax-bp-700 ↓ */`, `@media (min-width: 640px) { /* --ax-bp-content ↑ */`. Registry comment at `app.css:20-31` (documents `--ax-bp-content: 640px`, `md 768px`, `lg 1024px`, `sm ↓ 599.98px`, `lg ↓ 1023.98px`).
- **Fix:** append the comment on the `{` line: 4415 and 7487 -> `/* --ax-bp-sm ↓ */`; 7228 -> `/* --ax-bp-content ↑ */`; 7205 (639px) -> `/* --ax-bp-content ↓ */` and add a registry line for it; 7231 (1000px, not a registry tier) -> an ad-hoc named tag following the `--ax-bp-700` precedent, e.g. `/* --ax-bp-1000 ↑ */`, plus a registry line. Pure comments: no layout change.
- **Bundle impact:** none expected. `grep -c "ax-bp-" accrue_admin/priv/static/accrue_admin.css` -> `0`; the build strips comments. I rebuilt (`mix accrue_admin.assets.build`) and `cmp` showed the committed `priv/static/accrue_admin.css` and `.js` byte-identical (job `admin-drift-docs` step "Ensure committed bundle is fresh" is currently green). Re-run build + `git diff --exit-code -- accrue_admin/priv/static/...` after the comment edit.
- **Collateral:** `accrue` full suite: `70 properties, 2081 tests, 24 failures (11 excluded)`, all 24 in `Accrue.Docs.PackageDocsVerifierTest`. The `succeeds` test (`package_docs_verifier_test.exs:9`) runs the real script against the live tree and asserts status 0, so every negative test inherits the red baseline. Expect all 24 to clear with the CSS fix. Verify with `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0`.
- **Positive control:** the guard fires today (that is the red); after the fix, temporarily remove one comment in a scratch copy and confirm the script fails again.

### R5. Executable UAT contract (GREEN-01) - archived v1.66 SUMMARY entries
- **Step:** `Executable UAT contract self-test`; the failing command is `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229`. `--self-test` and `--all-opted-in` pass (`2 opted-in phases, 1 complete, 3 summaries, 6 automated UAT tests`).
- **Failure now:** `executable UAT contract: FAIL: 245-02-SUMMARY.md coverage D2: human_judgment must be false`. The verifier throws at the first offender per phase; I enumerated all of them by importing `validatePhaseDirectory` per phase directory (positive: it reports 245, 246, 247, 248):

  | Summary | Entry | Recorded rationale (verbatim, trimmed) | Kind |
  |---|---|---|---|
  | 245-02 | D2 | "Ordinary Unicode-name coverage and some contextual lifecycle/promotion assertions remain open; the phase verifier must assess full requirement coverage." | deferral to phase verifier |
  | 246-01 | (true entry) | "Automated checks verify markup and target sizing rules, while visual hierarchy and responsive touch affordance still need human inspection." | visual inspection |
  | 246-04 | D3 | "...require inspection of the rendered images in addition to DOM and geometry assertions; all four final captures were reviewed." | visual inspection |
  | 246-05 | D2 | "The saved image review is an agent visual inspection and does not represent owner approval." | agent visual inspection |
  | 247-02 | - | `247-02-SUMMARY.md: complete SUMMARY is missing coverage:` | missing coverage block |
  | 247-03 | D1, D2, D3 | "...owned by later Phase 247 plans." / "The phase verifier owns complete consumer inventory and mounted visual proof." | deferral |
  | 247-04 | D1, D2 | "...integrated browser proof." / "mounted rendered proof is reserved for phase 247-07." | deferral |
  | 248-01 | D2 | "The captures were individually inspected at original resolution; the full findings ledger remains Plan 02 work." | agent visual inspection |
  | 248-02 | D2 | "Plan 01 recorded original-resolution inspections for these eight images; ..." | agent visual inspection |

  (The contract also requires every verification `status` to be `pass` and a non-empty `ref`; `--all-since` passes for 229-244.)
- **Why the artifact is truthful and the contract is also right:** these summaries honestly record that part of the acceptance was a visual/agent inspection. The Executable Acceptance Policy (CLAUDE.md) says human interaction must not be a completion gate. So this is a genuine historical policy deviation in v1.66, not a stale regex.
- **Constraint:** `245-VERIFICATION.md`, `246-`, `247-`, `248-VERIFICATION.md` list these summaries in `covered_files` with `covered_digest: "v3:sha256:..."` [VERIFIED: grep of each file's frontmatter]. Rewriting the summaries makes every archived digest untrue. Archived digests are frozen by design (CONTEXT).
- **Recommended route** `[ASSUMED - needs maintainer decision]` (do not flip flags falsely):
  - (a) Add a narrow **recorded-deviation list** to `verify_executable_uat_contract.mjs` `--all-since` mode: each entry = `{summary path, entry id, sha256 of the summary file, rationale, owner}`. The verifier asserts the file still matches the pinned hash (any edit re-fails), the entry still carries `human_judgment: true`, and that a NEW `human_judgment: true` anywhere else still fails. Ship negative controls (unlisted offender fails; hash mismatch fails; listed entry flipped to false is reported as a stale exemption) and make `--self-test` cover them. This is the same shape as the repo's waived-with-owner-and-cause ledger.
  - (b) Alternative for deferral-type entries only (247-03, 247-04, 245-02 D2): if later passed evidence actually satisfies them, document that, but flipping still edits a digest-covered file, so it fails the frozen-fingerprint rule. Not recommended.
  - (c) 247-02 needs a `coverage:` block; the same edit-vs-digest constraint applies, so it also goes into the recorded-deviation list as "missing coverage" (or a verifier carve-out for `status: complete` summaries whose phase verification is `passed` and archived - a bigger weakening; avoid).
  - Also constrain: precedent 232-10 flipped/removed entries in the LIVE 232 summaries before archive; that route is no longer available for archived files.
- **Positive control:** after the change, `node scripts/ci/verify_executable_uat_contract.mjs --all-since 229` passes AND a scratch summary with a fresh `human_judgment: true` fails.

### R6. D-16 committed window dispositions (GREEN-01)
- **Step:** `Committed window dispositions at the pinned candidate SHA (D-16)`. **Failure:** `window dispositions verify: FAIL: ship-window ledger still has 12 open row(s) with no disposition partner: ids=[15, 16, 17, 18, 19, 20, 28, 29, 30, 36, 37, 38]`.
- **What "disposition partner" means:** a row in the committed disposition record `232-WINDOW-DISPOSITIONS.json` (archived, `candidate_object: c1397fe9127a9b4b2b1d3a0758d57879b14f4604`, 14 rows: ids 1-14, dispositions `fixed`/`waived`) [VERIFIED: ran parse]. `assertRowJoin` (`verify_window_dispositions.mjs:48-56`):
  ```js
  const openIds = ledgerRows.filter((row) => row.status === "open")...
  if (openIds.length) fail(`ship-window ledger still has ${openIds.length} open row(s) with no disposition partner: ids=[...]`);
  const nonOpenLedgerRows = ledgerRows.filter((row) => row.status !== "open");
  const authority = exactMap(nonOpenLedgerRows, ... (row) => row.status);
  const candidate = exactMap(dispositionRows, ... (row) => row.disposition);
  assertSameMap("WINDOWS.md non-open rows", authority, "231-WINDOW-DISPOSITIONS rows", candidate);
  ```
  Data source for a partner: the collector `scripts/ci/collect_window_dispositions.mjs --repo --expected-repository --candidate <ref/sha> --records-in <file>`; a `fixed` row must carry `state: "proved"` and a re-derived `current_evidence`; a `waived` row needs non-empty `owner`, `rationale`, `release_impact` [VERIFIED: `collect_window_dispositions.mjs:85-107`].
- **Second, hidden failure (proved):** I simulated the 12 rows -> `fixed` (counts fixed in front matter), then ran the real parser `readShipWindowRows` against the frozen record: `missing from record: 15,16,...,38` (24 ids). The ledger grew by 24 rows after the v1.62 record was frozen, and `assertSameMap` demands exact equality.
- **Wrong artifact:** the verifier invocation. It binds a frozen v1.62 point-in-time record to a live ledger that keeps growing. The frozen record is correct for its candidate SHA.
- **Fix options:**
  1. **(Recommended)** Add an explicit, visible scope bound to the verifier (e.g. `--ledger-through-id 14`, passed in the `ci.yml` step so the scope is in the command text). Keep the global "no open row anywhere" check unscoped, require in-scope non-open rows to join exactly, and reject a record id beyond the scope. Ship fixtures: (i) a later non-open row is ignored; (ii) a later OPEN row still fails; (iii) a missing in-scope partner still fails; (iv) a record id beyond the scope fails. Later rows' truth is then carried by the global open check plus SL-A claim C1.
  2. Mint a new pair at a new candidate SHA with the collector covering ids 1-38 (every fixed row needs `proved` evidence; waived rows owner/rationale/impact) and repoint the step. Honest but heavy and re-breaks the moment Phase 250/251 add a ledger row.
  3. Rejected: filtering by `recorded_at` (rows 12-14 were recorded at 2026-09-17T14:50 after `observed_at` 09:43).
- **Order of operations:** disposition the 12 rows first (R2), then the verifier scope, then re-run the step.
- **Touches archived evidence:** no edit to the record or `.md`. `ci.yml` edit is live.
- **Positive control:** the fixture battery in (1) above; plus the real run must fail if one row is flipped back to `open` in a scratch copy.

### R7. D-32 CI script contract (GREEN-03)
- **Step:** `CI script contract (D-32)`. **Command:** `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor`. **Failure:** `ci script contract: FAIL: missing the shared module-boundary guard: scripts/ci/accrue_host_preview_custody_test_entry.mjs, scripts/ci/test_accrue_host_preview_custody.mjs, scripts/ci/test_accrue_host_proof_paths.mjs, scripts/ci/verify_phase240_evidence.mjs, scripts/ci/verify_phase245_baseline.mjs, scripts/ci/verify_phase246_render_proof.mjs, scripts/ci/verify_phase247_render_proof.mjs, scripts/ci/verify_phase248_integrated_proof.mjs, scripts/ci/verify_phase248_render_proof.mjs`. (`git ls-files 'scripts/ci/*.mjs'` = 67; floor constant 55 passes.)
- **The guard text** (`scripts/ci/main_module.mjs`, `isMainModule(moduleUrl)`; throws on empty `process.argv[1]`). Compliant idiom, verbatim from `verify_artifact_fixed_point.mjs:~645-663` and the contract's own fixture:
  ```js
  import { isMainModule } from "./main_module.mjs";
  let entry = false;
  try { entry = isMainModule(import.meta.url); } catch { entry = false; }
  if (entry && process.env.NODE_TEST_CONTEXT) { test("real name", () => ...); }
  else if (entry) { main(); }
  ```
  The checker enforces the SHAPE (assignment from `isMainModule(` inside try/catch; no bare call in an `if`) [VERIFIED: `assertGuardCoverage`, lines 79-123].
- **Exemption mechanism that exists:** `LIBRARY_MODULE_ALLOWLIST` (a `Map` of path -> one-line reason), consulted ONLY in `assertGuardCoverage` for "a library module with no CLI entrypoint"; its only entry is `scripts/ci/main_module.mjs`. It is NOT consulted by `assertNonVacuity`. There is no exemption list for pinned scripts.
- **Second failure behind the first (measured by `node --test --test-reporter=tap` per file, which is exactly what `assertNonVacuity` spawns):**

  | File | Bare `node --test` | Cause |
  |---|---|---|
  | `accrue_host_preview_custody_test_entry.mjs` | rc 1, 1 test named as its own path | `# usage: ... <fixture.json> <browser|dev>` CLI shim |
  | `test_accrue_host_preview_custody.mjs` | rc 0, 13 named tests | passes; needs only the guard idiom |
  | `test_accrue_host_proof_paths.mjs` | rc 0, 1 named test | passes; needs only the guard idiom |
  | `verify_phase240_evidence.mjs` | rc 1 | `Phase 240 evidence invalid: expected 21 route rows; omitted required route: /admin` (treats `process.argv.at(-1)` as the ledger path) |
  | `verify_phase245_baseline.mjs` | rc 1 | `# FAIL: capture C01 source digest is stale for accrue_admin/assets/css/app.css` (live check against drifted captures) |
  | `verify_phase246_render_proof.mjs` | rc 1 | `usage: node verify_phase246_render_proof.mjs --manifest <repo-relative-path>` |
  | `verify_phase247_render_proof.mjs` | rc 1 | `usage: ... --manifest ...` |
  | `verify_phase248_integrated_proof.mjs` | rc 1 | `usage: ... --proof <path> --manifest <path>` |
  | `verify_phase248_render_proof.mjs` | rc 1 | `usage: ... --manifest <repo-relative-path> [--scenario ordinary]` |
- **Which are actually sha256-pinned (more precise than CONTEXT)** [VERIFIED: capture `manifest.json` `source_digests` vs `shasum -a 256`]:
  - `verify_phase247_render_proof.mjs`: manifest `phase247-current-proof` pins `43b507954d2ddf6b939168e712977e07abb6371213f1735ba1ecd64d79ef0029`; the file today hashes to exactly that. Editing it falsifies the recorded receipt. **CONTEXT only names 248; 247 is also pinned and currently matches.**
  - `verify_phase248_render_proof.mjs`: manifest pins `e6deb8fd...20170`; the file today is `f794edc3...d2351` (already changed by commit 593b8588 "keep proof validation usable after milestone archive", after capture). Treat as pinned/frozen regardless, per the locked decision.
  - `verify_phase246_render_proof.mjs`: manifest pins `976ca7c9...fd6a`; the file today is `a0867d85...59b6` (already drifted).
  - The `source_digests` are recorded receipts of what the capture ran against; the verifiers themselves do NOT re-check them at run time (they check screenshot hashes and served-asset hashes), so editing does not fail any verifier, it only makes a recorded receipt untrue.
  - 240, 245, 248_integrated, the two `test_` files and the custody entry are not hash-pinned in any manifest (full-sha grep found nothing).
- **Recommended compliant route** `[ASSUMED - design decision for the planner]`:
  - Conforming edits (add guard + a hermetic self-test registered under `NODE_TEST_CONTEXT`, bare CLI path unchanged): `test_accrue_host_preview_custody.mjs`, `test_accrue_host_proof_paths.mjs`, `accrue_host_preview_custody_test_entry.mjs` (add a usage-rejection test), `verify_phase248_integrated_proof.mjs` (already has `.test.mjs` sibling; add guard + a fixture test). These files are not pinned.
  - For the archived evidence verifiers whose bytes are frozen or whose live check is intentionally drifted (`verify_phase246_`, `247_`, `248_render_proof`, `verify_phase245_baseline`, `verify_phase240_evidence`): add a new, explicit map in `verify_ci_script_contract.mjs`, e.g. `ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS: path -> { reason, sha256 }`. The contract must (i) require a non-empty reason, (ii) require the file's current sha256 to equal the pin (so the exemption dies the instant someone edits the file), (iii) skip BOTH the guard check and the non-vacuity spawn for exactly those paths, (iv) fail on a stale exemption (listed path that now conforms, or is missing from the cohort), (v) ship fixtures: unlisted CLI file still fails; wrong hash fails; empty reason fails. Reference the deferral ("re-capture or retirement of the drifted 245/248 evidence verifiers", REQUIREMENTS Future) in each reason. Raise `COMMITTED_COHORT_FLOOR` only if the live count genuinely rose (re-measure with `git ls-files 'scripts/ci/*.mjs' | wc -l`; currently 67 vs constant 55).
  - Rejected: appending the guard to the pinned files (falsifies receipts for 247/248/246), and adding them to `LIBRARY_MODULE_ALLOWLIST` (its reason text says "library module"; these have CLI entrypoints; and it would not cover non-vacuity).
- **Positive control:** fixtures above plus `--fixtures` already contains negative controls (`ci script contract fixtures pass every negative control`); add the three new ones to that battery.

### R8. admin compile warning (GREEN-02)
- **Step:** `Compile admin package` (job steps in `admin-group-contracts`, `admin-hardening-guardrails`, `admin-phase200-guardrails`; also `release-gate` step 19). **Command:** `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors`. Re-run with `--force`: exactly one warning, then `Compilation failed due to warnings while using the --warnings-as-errors option`.
- **Evidence:** `accrue_admin/lib/accrue_admin/live/subscription_live.ex:1286`: `defp activity_audit_summary(_events, subscription) do` with body `"Subscription status reviewed · Accrue system"` (the sibling clause at 1282 already uses `_subscription`) [VERIFIED: read lines 1278-1292]. Introduced by `9eea9cce fix(208-04)`; the 2026-10-18 owner-feedback note explicitly records this as a "pre-existing unused `subscription` binding".
- **Fix:** rename to `_subscription`. Nothing else warns.
- **Collateral:** the same warning prints during every dependent compile (`accrue_portal`, `examples/accrue_host`), and `mix test --warnings-as-errors` in `accrue_admin` would fail on it.
- **Positive control:** `mix compile --force --warnings-as-errors` fails before, passes after.

### R9. Phase 190 automation contract (GREEN-04)
- **Step:** `Phase 190 automation contract` (`bash scripts/ci/verify_phase190_automation_contract.sh`). **Failure:** `verify_phase190_automation_contract: missing /^status: complete$/ in .planning/milestones/v1.53-phases/190-navigation-data-display-meta-component-cohesion/190-VERIFICATION.md`.
- **Evidence:** script line 70: `require_regex "$verification_file" '^status: complete$'`. The file front matter is `status: passed`. Commit `2219292b chore(v1.63): finalize verified milestone` changed that one line `status: complete` -> `status: passed` (diff read; same commit normalized ~14 archived VERIFICATION files). `origin/main` still has `status: complete`. The UAT regex at line 59 (`'^status: complete$'`) matches `190-UAT.md` (`status: complete`) and is correct.
- **Wrong artifact:** the verifier. `passed` is the canonical VERIFICATION vocabulary the rest of the system uses (`verify_completion_evidence.mjs` requires `status: passed`). Editing the archived VERIFICATION back would undo the intentional normalization and is not needed.
- **Fix:** change line 70 to accept the canonical value (`'^status: passed$'`). Do NOT drop the other assertions (`score: "5/5 must-haves verified"`, closure strings, absence of `human_needed`). `git grep` found no other `scripts/ci` script asserting `status: complete` on a VERIFICATION file.
- **Archive-path:** the script already falls back from `.planning/phases/190-*` to `.planning/milestones/v1.53-phases/190-*` (lines 4-12), so no path change is needed.
- **Positive control:** feed the script a scratch phase dir whose VERIFICATION says `status: human_needed` (it must still fail via `require_absent_regex`).

### R10. Phase 190 browser gate (GREEN-04) - classification
- **Step:** `Run Phase 190 group-contract browser gate` (`cd accrue_admin && npm run e2e:group-contracts`; run again inside `verify_phase192_admin_guardrails.sh:16` and `verify_phase200_admin_guardrails.sh:17`). I ran it ONCE: `6 failed ... 10 passed (55.0s)`; failures = 3 tests x `chromium-desktop` + `chromium-mobile`.
- **Prereqs used:** Postgres on localhost (user/password `postgres`), `MIX_ENV=test`, `ACCRUE_ADMIN_E2E_PORT=4017`, Playwright chromium already cached. `mix accrue_admin.e2e.server` is started by the Playwright `webServer`.
- **Classification (all three: STALE CONTRACT from intentional owner-feedback commit `b4a7eeac` 2026-10-19 "fix(admin): clarify billing views and recorded evidence"; none is a UI regression):**

  | Spec line | Test | Assertion that fails | What changed |
  |---|---|---|---|
  | 616 (`:269`) | "active filter, selection, sort, and subview cues are visible and named" | `toContainText("30 days UTC")` on `nav[aria-label="Time window (UTC)"] [aria-current="page"]`; got `30 days` | `window_selector.ex` template `<%= label %> UTC` -> `<%= label %>` (diff in b4a7eeac). The 2026-10-18 note: "The compact date selector states UTC once". The `aria-label="Time window (UTC)"` and moduledoc still say UTC. |
  | 626 (`:204` via `GROUP_FINDABILITY`) | "operator-stress group scan..." | `tabs-subviews exposes /30 days UTC/i` | same change; the findability list still lists `/30 days UTC/i` for `tabs-subviews`. |
  | 643 (`:470`) | "samples one list, detail, recovery, overlay, and shell/tabs surface" | `getByRole('heading', { name: /Clear open receivables/i })` on `/billing/invoices` | `Copy.invoices_list_heading` `"Clear open receivables"` -> `"Invoices"` (`accrue_admin/lib/accrue_admin/copy/invoice.ex:34` now `def invoices_list_heading, do: "Invoices"`). Note: "Invoices and Payments use stable destination headings." |
- **Fix (contract, with rationale recorded in the plan summary):** update the spec: replace `"30 days UTC"` with `"30 days"` and add an assertion that the nav `aria-label` still contains `UTC` (keeps the UTC-disclosure intent); update the `GROUP_FINDABILITY['tabs-subviews']` entry the same way; replace the heading regex with the current `Copy.invoices_list_heading()` value. Prefer deriving the heading from the Copy module output or the exact string `Invoices` with an exact-match role query so the assertion stays specific.
- **Caution:** the first failure in test 626 stops that test, so further stale expectations in the other `GROUP_FINDABILITY` slugs may surface after the first fix. Plan for one re-run (about 1 minute) per iteration; do not claim the gate green from the static edit.
- **Not yet run:** the remaining steps of `verify_phase192_admin_guardrails.sh` (`e2e:phase191`, `e2e:a11y`, reduced-motion, component-lab) and `verify_phase200_admin_guardrails.sh` (`phase200:storybook`, page-flow phase200, `e2e:phase199`, reduced-motion, scorecard, signoff). Non-browser pieces measured: `baseline:parse` ok; `verify_phase191_ax187_coverage.mjs` passed; `phase192:component-lab` 16 tests 0 failures. `phase200:scorecard`/`signoff` run standalone are red (`Phase 200 scorecard has blocking regressions`, regressions=36288, lens_inputs=0) because they read evidence generated by the earlier steps of the same job; they are not meaningful out of sequence. The planner must run `bash scripts/ci/verify_phase192_admin_guardrails.sh` and `bash scripts/ci/verify_phase200_admin_guardrails.sh` end-to-end after R8/R9/R10 (cost: several minutes each; Chromium + Postgres). Expect more stale-copy findings of the same class from the 11 owner-feedback commits.

### R11. `mix format --check-formatted` (GREEN-05; not in CONTEXT)
- **Evidence** (release-gate steps 5 and 18): `accrue` -> `accrue/test/accrue/docs/package_docs_verifier_test.exs` (missing blank line after the `)` near line 1003); `accrue_admin` -> `accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs` (blank line near 360) and `accrue_admin/test/support/e2e_fixtures.ex` (map update wrapped, ~line 106). `accrue_portal` and `examples/accrue_host` pass.
- **Fix:** `mix format` on those three files (formatter, not hand edit); verify with `--check-formatted`. Elixir 1.19.5/OTP 28 locally matches the primary CI cell.

### R12. `mix credo --strict` in `accrue_admin` (GREEN-05; not in CONTEXT)
- `found 7 warnings, 1 refactoring opportunity, 11 code readability issues`, exit 28. Warnings: `length/1` comparisons in tests (`webhook_live_test.exs:199`, `invoices_live_test.exs:492,515,553,554,555,583`); readability: alias ordering in `test/support/e2e_fixtures.ex:11`, `webhook_replay_test.exs:8`, `connect_account_live_test.exs:5`, `webhooks_live.ex:13`, `subscription_live.ex:17`, `events_live.ex:14`, `event_live.ex:10`, `customer_live.ex:14`, `coupons_live.ex:14`, `connect_accounts_live.ex:14`, `charges_live.ex:15`; refactor: negated condition at `scoped_path.ex:233`. `accrue` credo exits 0.
- **Fix:** repo code/test cleanup per Credo (no `.credo.exs` loosening). Note the admin tests that use `length/1` should assert the real value (for example `assert [_ | _] = list`) rather than weaken coverage.

### R13. `accrue_portal` suite flake (GREEN-05; not in CONTEXT)
- `cd accrue_portal && mix test --warnings-as-errors`: `111 tests, 1 failure` on a random seed; `--seed 262447` reproduces it deterministically; seeds 0,1,2,3 and the file alone (6 runs) pass.
- **Failure:** `test custom mount with no explicit billable selection does not choose a first record (AccruePortal.ContextContractTest)` at `test/accrue_portal/context_contract_test.exs:240`: `ArgumentError ... the table identifier does not refer to an existing ETS table` from `:ets.lookup(AccruePortal.ContextContractTest.CustomEndpoint, :secret_key_base)`.
- **Root cause:** the file's `setup` (lines 111-130) starts the endpoint with `CustomEndpoint.start_link()` (linked to the test process) and tolerates `{:error, {:already_started, _}}`. The previous test's linked endpoint is still tearing down when the next test hits `already_started`, so its ETS table vanishes mid-test. A test-isolation defect introduced with `d07ffc0c`/`18bbe9ce` (233).
- **Fix:** start the endpoint under ExUnit supervision (`start_supervised!(CustomEndpoint)`) and drop the `already_started` tolerance. **Positive control:** `mix test --seed 262447` fails before and passes after; run a loop of random seeds (20) afterwards.

## Planning Truth (TRUTH-01 / TRUTH-02)

- **HANDOFF.json:** `.planning/HANDOFF.json` (5198 bytes, `"timestamp": "2026-10-07T14:08:28.444Z"`, `"pause_kind": "ready_for_new_milestone"`) is still there. No script reads it (`git grep` over scripts/.github found nothing); only PROJECT/REQUIREMENTS/ROADMAP mention it in prose (the current text describes its deletion). Remove with `git rm`.
- **Debug sessions:** `.planning/debug/phase245-browser-capture-stall.md`, `phase248-edge-fixture-lifecycle.md`, `phase248-ordinary-login.md` all have `status: resolved` [VERIFIED]. `.planning/debug/resolved/` exists with 5 files; there is also an older `debug/completed/` dir (1 file). Use `git mv` into `resolved/`. Trap: archived `248-01-SUMMARY.md:33` (digest-covered, must not be edited) lists `.planning/debug/phase248-ordinary-login.md` as a key file, and the debug file's own `files_changed` line references its path. The moved path will dangle in that frozen receipt; record the move in MILESTONES/STATE rather than editing the summary.
- **Out-of-band commits:** `git log 3d7d949d^..b4a7eeac` = 11 commits (3d7d949d, b493c50e, c9b44fd2, b396fc16, 7e77a01f, d122d53a, 66d5b3ce, a467006f, c5b25640, f23f8e75, b4a7eeac), dates 2026-10-12 -> 2026-10-19. Receipts: `.planning/notes/2026-10-11-`, `-12-`, `-13-`, `-14-`, `-18-admin-owner-feedback.md` (five notes exist; CONTEXT cites `1{2,3,4,8}`, and `2026-10-11` exists too). The `-18` note records "Full admin ExUnit suite ... **746 tests, 0 failures**" and Chrome desktop/mobile verification; that matches the 746/0 I measured on the integration head.
- **MILESTONES.md:** v1.66 block starts `## v1.66 Admin Usability and Visual Consistency (Completed locally:2026-10-12)` (line 3); "Post-archive tooling" is at line 28. Insert the owner-feedback entry directly after it. State that no plan/verification/phase verdict is claimed, cite the notes, and list the commit range.
- **STATE.md:** frontmatter is `milestone: v1.67 ... status: planning` with no `current_phase`. Add the out-of-band note and set `current_phase: 249` per R3. Update "Current Position".
- **Re-run after any planning-doc edit** (they read these docs): steps 15 (v1.17 friction), 24 (roadmap hygiene), 25 (release notes), 23 (no home paths), and the sensitive-token census (step 7). Memory warns that milestone regeneration can skeletonize standing sections; restore verbatim from commit 12f8d519 if a contract flags it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `covered_digest` | hand-typed or shell-computed hash | `scanArtifact` + `computeDigest` from `scripts/ci/verify_artifact_fixed_point.mjs` | digest format is `v3:sha256:` over `path\nhash\n` with canonicalization; hand digests are the exact escape hatch SL-G closes |
| Generated UAT | hand-written `249-UAT.md` | `verify_executable_uat_contract.mjs` writer (`source: executable-summary-coverage`) | the fixed-point gate regenerates and byte-compares it |
| Ledger dispositions | editing `WINDOWS.md` table | `gsd-tools windows fixed <id>` / `windows waive <id> "<reason>"` | the reader rejects inconsistent frontmatter counts |
| Archive path literals | `.planning/phases/<n>-*` literals | `scripts/ci/phase_evidence_path.mjs` | milestone close moves directories |
| Module-boundary guard | `import.meta.url === argv[1]` | `isMainModule` from `./main_module.mjs` inside try/catch | spaces/symlinks/relative argv; the contract checks shape |

## Common Pitfalls

1. **Fixing D-16 by dispositioning rows only.** The 24-row `missing` set appears next. Fix the scope in the same plan (R6).
2. **Editing digest-covered archived summaries/verifications.** Silently invalidates v3 digests (245-248 verifications cover those summaries; 232 verification covers `ci.yml`, `REQUIREMENTS.md`, `WINDOWS.md`, `verify_package_docs.sh`).
3. **Believing the guard fix is "add one import".** D-32 also spawns each file under `node --test` and rejects exit != 0 or a vacuous self-named test.
4. **Marking requirements Complete before VERIFICATION exists.** SL-E checks `status: passed` and an ID citation in a UAT/SUMMARY of the same phase.
5. **Treating `current_phase` as free.** SL-G reads it; flipping it to 250 early re-reds the gate until 250 has artifacts.
6. **Local macOS cannot reproduce the visual-regression pixel baselines.** WINDOWS row 27: "the baseline set is Linux-specific". Do not re-mint on macOS.
7. **Running mutating CI steps in the live tree.** `verify.install` (`accrue.install --yes`) and the tokens `generate`/`specimens` steps rewrite tracked files; run in a scratch checkout or commit first (CLAUDE.md destructive-git rule).

## Code Examples

### Disposition a ledger row
```bash
gsd-tools windows fixed 28
gsd-tools windows waive 15 "Owner: maintainer. Cause: process deviation recorded at phase 234 (tests landed after implementation; no RED commit). Release impact: none; tests exist and pass."
grep -c -F -e "open_count: 0" .planning/WINDOWS.md   # expect 1
```

### Compute the current phase digest (never by hand)
```js
import { scanArtifact, computeDigest } from "./scripts/ci/verify_artifact_fixed_point.mjs";
// computeDigest(repo, coveredFiles) -> "v3:sha256:..." (path string is hashed as recorded, not as resolved)
```

### DSY-01 annotation (comment only)
```css
@media (max-width: 599.98px) { /* --ax-bp-sm ↓ */
```

## State of the Art / Contract vocabulary notes
| Old | Current | Where |
|---|---|---|
| VERIFICATION `status: complete` | `status: passed` (normalized by `2219292b`) | R9 |
| window selector `30 days UTC` | `30 days` + UTC in nav label | R10 |
| Invoices heading `Clear open receivables` | `Invoices` | R10 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Proposed dispositions for ledger rows 15-20, 28-30, 36-38 (fixed vs waive and rationale text) | R2 | Maintainer may want stricter "fixed" proof or different waive rationale; waived rows need owner/rationale/impact |
| A2 | Add a scoped join (`--ledger-through-id`) to the D-16 verifier rather than minting a new 38-row record | R6 | If the maintainer prefers a fresh pinned record, it is a larger collector run and re-breaks with new ledger rows |
| A3 | Recorded-deviation list in the exec-UAT contract for 245-248 summaries instead of editing digest-covered summaries | R5 | Maintainer may judge the visual-inspection entries should be removed/flipped despite digest drift; that touches frozen fingerprints |
| A4 | New hash-pinned `ARCHIVED_EVIDENCE_VERIFIER_EXEMPTIONS` map in the D-32 contract | R7 | If rejected, the only alternative is hermetic self-tests injected into pinned files (falsifies 246/247/248 receipts) |
| A5 | Unique 1000px annotation name `--ax-bp-1000 ↑` and `content ↓` for 639px | R4 | Naming bikeshed only; any `--ax-bp-*` token satisfies the guard |
| A6 | Phase 250/251 will need their own VERIFICATION/UAT before `current_phase` flips | R3 | Gate red on flip if not planned |

## Open Questions

1. **Are all 190/192/200 admin browser steps green after R8-R10?** What we know: only `e2e:group-contracts` was run (6 failed/10 passed, all classified). What's unclear: `e2e:phase191`, `e2e:a11y`, `phase199`, page-flow 200, storybook coverage, reduced-motion. Recommendation: plan a dedicated wave that runs both guardrail scripts end to end and iterates on stale-copy findings.
2. **Do the Linux visual baselines still match?** Baselines last committed `0197f4ba` 2026-10-10 (Phase 243-01); 157 admin lib/asset commits landed since `origin/main`, including 11 UI-changing owner-feedback commits after 2026-10-10. Mint is Linux-only (`accrue_admin_browser.yml` job "Mint visual baselines", artifact `phase211-visual-baselines`, via `workflow_dispatch`). Options: Docker Linux Playwright container locally (Docker daemon is running here) or remote mint in Phase 250. Recommendation: decide in planning; GREEN-05 says baselines regenerate "only where an intentional change requires it", so first measure the diff on Linux, do not blindly re-mint.
3. **Which of host-integration/playwright-e2e pass?** Not run. See table below.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres | accrue / admin / portal / host tests, Playwright | yes | accepting on `/tmp:5432` | none needed |
| Elixir/OTP | all mix lanes | yes | 1.19.5 / OTP 28 | none |
| Node | contracts, Playwright | yes | 22.14.0 | none |
| Playwright Chromium | admin + host browser lanes | yes | cached `chromium-1200..1243` under `~/Library/Caches/ms-playwright` | `npx playwright install chromium` |
| Docker daemon | `host-docker-smoke`, Linux visual baselines | yes | client 29.5.2, a `playstead-server-app-1` container is running (unrelated: do not touch) | CI-only |
| GitHub token / live PR #45 | SL-F step | no | - | Phase 250 |
| Hex network (`mix hex.audit`) | release-gate | yes | `No retired packages found` x3 | - |

### Lanes not replayed here, with commands and estimated cost
| Lane | Local command | Prereqs | Est. cost | Notes |
|------|---------------|---------|-----------|-------|
| release-gate: dialyzer + docs | `cd accrue && mix dialyzer --format github`, `MIX_ENV=dev mix docs --warnings-as-errors`; same in `accrue_admin` | PLT build | 5-20 min cold | not run; no known red |
| release-gate matrix cells | Floor (1.19.0) needs that Elixir; Sigra/OTel cells set `ACCRUE_CI_SIGRA=1` / `ACCRUE_CI_OPENTELEMETRY=1` | extra toolchain | local only covers the primary cell | document which cells ran |
| host-integration | `bash scripts/ci/accrue_host_uat.sh` -> `mix verify.full` (install, bounded tests, full regression, dev boot, browser smoke), then `bash scripts/ci/accrue_host_hex_smoke.sh` | Postgres, `npm ci` in `examples/accrue_host` and `assets`, Chromium, ports 4100/4101 | 20-45 min | `verify.install` runs `accrue.install --yes`, which can rewrite tracked host files; run in a clean scratch clone or commit first |
| playwright-e2e (3 shards) | `cd examples/accrue_host && npx playwright test --shard=N/3` plus the Phase 238/search/Braintree steps in `ci.yml:` job `playwright-e2e` steps 9-24 | compile + `mix assets.build` + seed via `scripts/ci/accrue_host_seed_e2e.exs` | 30-60 min total | `compile --warnings-as-errors` for the host passed |
| host-docker-smoke | `cd examples/accrue_host && docker compose up --build -d` then curl `localhost:4000` | Docker, `docker network create proxy` | 5-15 min | joins shared Traefik network per project notes |
| admin visual regression | `cd accrue_admin && npm run e2e:visual-regression` | Linux Chromium | n/a on macOS | see Open Question 2 |
| Browser UAT job | `cd accrue_admin && npm run e2e` (all desktop+mobile specs) + `node --test test/js/*.mjs` + `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop` | Chromium, Postgres | 10-20 min | expect stale-copy reds like R10 |
| SL-F PR body currency | `node scripts/ci/verify_pr_body_currency.mjs --repo . --expected-repository szTheory/accrue --require-currency --min-declared 1` | token + live PR | - | Phase 250 |
| tokens harness regenerate | steps 44-46 | mutates tracked files | <1 min | steps 47-50 (verify/parity) passed here |

Measured this session: `accrue` suite 38s wall (2081 tests + 70 properties), `accrue_admin` ExUnit 10.6s (746 tests), `accrue_portal` ~3s (111 tests), docs-contracts job replay under 2 minutes, `e2e:group-contracts` 55s.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `node --test` (TAP) for `scripts/ci/*.mjs`; ExUnit for Elixir packages; Playwright for browser contracts |
| Config file | per-script self tests; `accrue_admin/playwright.config.js` |
| Quick run command | `bash -eo pipefail <extracted step .sh>` for the single step under repair |
| Full suite command | the full docs-contracts replay loop (steps 2-43, 47-50) + `mix test` per package + the two admin guardrail scripts |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GREEN-01 | SL-E/SL-A/SL-G/exec-UAT/D-16 pass | contract | per-step commands in R1-R6 | yes (verifiers exist); new negative controls need adding (R5, R6, R7) |
| GREEN-02 | admin compile clean | compile | `cd accrue_admin && MIX_ENV=test mix compile --force --warnings-as-errors` | yes |
| GREEN-03 | DSY-01 + D-32 | contract | `bash scripts/ci/verify_package_docs.sh`; `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` | yes |
| GREEN-04 | Phase 190 contract + probes | script + browser | `bash scripts/ci/verify_phase190_automation_contract.sh`; `cd accrue_admin && npm run e2e:group-contracts` | yes (spec needs edits) |
| GREEN-05 | suites + host + e2e | ExUnit/Playwright | `mix test` in each package; `bash scripts/ci/accrue_host_uat.sh`; playwright shards | yes |
| TRUTH-01/02 | HANDOFF removed, notes recorded | grep-assertion | `test ! -e .planning/HANDOFF.json`; `bash scripts/ci/verify_roadmap_hygiene.sh`; `bash scripts/ci/verify_release_notes_contract.sh` | n/a (add as plan verify commands) |

### Sampling Rate
- **Per task commit:** the single replayed step plus `node --test` for any touched verifier.
- **Per wave merge:** full docs-contracts replay loop + admin compile + the affected package suite.
- **Phase gate:** full replay, all package suites, both admin guardrail scripts, host-integration and the Playwright lanes (Executable Acceptance Policy: no human checkpoints; every item is a command).

### Wave 0 Gaps
- [ ] Negative-control fixtures for: scoped D-16 join; recorded-deviation list in exec-UAT; D-32 exemption map (wrong hash, empty reason, unlisted CLI file).
- [ ] A reusable local replay script that extracts and runs the `ci.yml` job blocks (the recipe in this document) so GREEN gates are one command; keep it in the scratch/plan tooling, do not add it as a new weakened gate.
- [ ] `249-UAT.md` generation path and `249-VERIFICATION.md` covered_files list (tracked paths only).

## Security Domain

`security_enforcement` is absent in `.planning/config.json` (treated as enabled). This phase edits CI contracts, CSS comments, tests, docs; it adds no network surface, auth, or secrets handling.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 | no | n/a |
| V5 Input Validation | yes (small) | verifier CLIs already validate argv; keep new flags allow-listed in the existing `BOOLEAN_FLAGS`/`VALUE_OPTIONS` sets |
| V6 Cryptography | yes (small) | sha256 via `node:crypto` for exemption pins; do not hand-roll |
| V14 Config/Integrity | yes | sha256-pinned exemptions so a silent edit re-fails the gate |

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Gate weakened by an unpinned allowlist | Tampering | exemption entries carry reason + sha256 + stale check |
| Hand-written digest | Spoofing/Tampering | `computeDigest` only |
| PII path leakage in committed notes | Information disclosure | `verify_no_home_paths.sh --repo` (step 23) after every doc edit; do not paste absolute home-directory paths into planning docs |

## Project Constraints (from CLAUDE.md)
- Executable Acceptance Policy: no `type="tracer"`, `checkpoint:human-verify` or `<human-check>` where a command can decide; phase completion requires SUMMARY coverage with `human_judgment: false`, a generated automated UAT artifact, `VERIFICATION.md` with `status: passed` and `behavior_unverified: 0`. Genuine maintainer decisions (A1-A4 above) are product/policy decisions, not recurring UAT.
- Never run destructive git with uncommitted work; commit each green fix immediately; `git reset --soft` to drop commits; never exercise git behavior in the live tree.
- A check that finds nothing must be proved able to find something; use `git grep -e` not `git grep --`.
- A guard must never spell out what it guards against (do not hardcode usernames/tokens in new checks).
- Milestone close breaks contracts that read `.planning/phases/`; use `phase_evidence_path.mjs`; run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` after any change touching archive literals.
- Editing a covered file re-mints a fingerprint: recompute only via `scanArtifact` + `computeDigest`.
- Stack constraints: Elixir 1.19+, OTP 27+, `phoenix_live_view` required but core LiveView-runtime-free; admin keeps committed `priv/static/accrue_admin.css/js` fresh (`mix accrue_admin.assets.build`).
- GSD workflow: edits go through GSD commands.

## Sources

### Primary (HIGH confidence, opened or executed this session)
- `.github/workflows/ci.yml` (job `docs-contracts-shift-left`, `admin-*`, `release-gate`, `host-integration`, `playwright-e2e`, `host-docker-smoke`), `.github/workflows/accrue_admin_browser.yml`
- `scripts/ci/verify_completion_evidence.mjs`, `verify_pr_claims.mjs` via CLI, `verify_artifact_fixed_point.mjs`, `verify_window_dispositions.mjs`, `collect_window_dispositions.mjs`, `verify_executable_uat_contract.mjs`, `verify_ci_script_contract.mjs`, `main_module.mjs`, `verify_package_docs.sh`, `verify_phase190_automation_contract.sh`
- `accrue_admin/lib/accrue_admin/live/subscription_live.ex`, `components/window_selector.ex`, `copy/invoice.ex`, `e2e/admin-group-contracts.spec.js`, `assets/css/app.css`
- `.planning/WINDOWS.md`, archived `232-INTEGRATION-PR.json`, `232-WINDOW-DISPOSITIONS.json`, v1.66 `245-02-SUMMARY.md` and siblings, capture `manifest.json` files, `.planning/notes/2026-10-18-admin-owner-feedback.md`, `.planning/STATE.md`, `.planning/MILESTONES.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` (Phase 249 block)
- git evidence: `git show 2219292b`, `git show b4a7eeac` (window_selector, copy/invoice diffs), `git log origin/main..HEAD`, `git show origin/main:.planning/STATE.md`
- Command output: replay logs under `/private/tmp/claude-501/-Users-jon-projects-accrue/48422f75-2b7f-40b8-aba9-40871881caab/scratchpad/` (`steps/*.log`, `p190.log`, `portal.log`, `accrue_test.log`, `admin_test.log`)

### Secondary / Tertiary
- none (no web research was needed; no external packages involved)

## Metadata
**Confidence breakdown:**
- Red inventory and root causes: HIGH (each reproduced with the CI command, failure text captured)
- Fix design for R5/R6/R7: MEDIUM (design choices needing maintainer confirmation, `[ASSUMED]`)
- Unreplayed lanes: LOW (host-integration, Playwright shards, docker smoke, visual regression, dialyzer/docs not run)

**Research date:** 2026-10-24
**Valid until:** until the integration head moves (any commit touching `scripts/ci`, `.planning/WINDOWS.md`, `accrue_admin/lib|assets`); re-measure with the replay recipe.
