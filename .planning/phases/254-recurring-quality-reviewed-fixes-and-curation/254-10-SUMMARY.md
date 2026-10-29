---
phase: 254-recurring-quality-reviewed-fixes-and-curation
plan: "10"
subsystem: testing
tags: [css, storybook, design-review, uxq-04, verifier, ci, assessment]

requires:
  - phase: 254-recurring-quality-reviewed-fixes-and-curation
    provides: 254-09 frozen recurring budget and the shared aggregates; 254-04 digest recipe (no source_digests input changed here)
provides:
  - recompose_storybook_css.mjs, a deterministic composer for priv/static/storybook.css with --write, --check and --self-test, and a CI freshness step
  - a storybook.css that embeds the current accrue_admin.css bundle (it was 588 bytes behind)
  - 254-DESIGN-REVIEW.json at stage assessment, its generated Markdown view, and verify_phase254_design_review.mjs
affects: [254-11, 254-12, 254-13, 254-14, 254-15, 254-17, 254-18]

actuals:
  tokens: 33250
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "A source-bound record: every cited line range carries the sha256 of the whole file at source_commit plus a needle that must appear inside the cited lines, so a citation cannot drift silently"
    - "A claim with a mechanical basis: DR-254-01 names a scan (scanSubscriptionDetailSpacing) that must find the overrides at source_commit and none at fix_commit"
    - "Injectable readers (git, contract file, evidence existence) keep every rejection scenario pure and fast while the default readers hit git and the tree"

key-files:
  created:
    - scripts/ci/recompose_storybook_css.mjs
    - scripts/ci/recompose_storybook_css.test.mjs
    - scripts/ci/verify_phase254_design_review.mjs
    - scripts/ci/verify_phase254_design_review.test.mjs
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.json
    - .planning/phases/254-recurring-quality-reviewed-fixes-and-curation/254-DESIGN-REVIEW.md
  modified:
    - .github/workflows/ci.yml
    - accrue_admin/priv/static/storybook.css

key-decisions:
  - "storybook.css keeps its brand.css section: the composer takes accrue/priv/static/brand.css as a third input between the PhoenixStorybook CSS and the admin bundle, because the previous composition carried it and the admin bundle and the dark shim read its --accrue-* tokens (see Deviations, item 1)."
  - "Findings DR-254-06..09 exist beyond the five locked D-34 items: the two new candidates (DR-254-06 audit heading weight and accent, DR-254-07 audit caption) plus two real source observations the rubric needed a finding for (DR-254-08 disclosure summary affordance, DR-254-09 duplicate section title selectors). All four are deferred under D-36."
  - "The spacing scan passes on-scale non-zero rem literals (the breadcrumbs 0.125rem gap) and var(--ax-space-*) tokens, and flags anything off-scale or with a zero component, so 254-12 has to delete exactly the five D-34 overrides and nothing else."

patterns-established:
  - "A contract-amended finding records contract.action (amend-row or add-row); at assessment the verifier proves the row to amend exists and the row to add does not, and from stage corrected on it requires amended_text in the contract file read through resolvePhaseEvidencePath"

requirements-completed: []
requirements-advanced: [UXQ-04]

coverage:
  - id: D1
    description: "storybook.css is reproducible from its inputs, the embedded accrue_admin.css section equals the bundle sha256, and CI fails when it drifts"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node --test scripts/ci/recompose_storybook_css.test.mjs (13 pass, including the one-byte drift case, the exact-composition case, a drifted PSB or brand section, a missing shim tail, an admin bundle without a trailing newline and the real-tree --check) and node scripts/ci/recompose_storybook_css.mjs --self-test (5 scenarios)"
        status: pass
      - kind: integration
        ref: "node scripts/ci/recompose_storybook_css.mjs --check: embedded section sha256 a519a7541d05b74c769dd938e493fc886149585def2ff5bfa00cc7a270f77699 equals the bundle sha256; --write twice left cmp-identical bytes; lab ExUnit storybook_asset_test.exs 4 tests 0 failures; verify_ci_efficiency_contract.mjs and verify_ci_script_contract.mjs pass"
        status: pass
    human_judgment: false
  - id: D2
    description: "The recomposed Storybook bundle does not regress the Phase 252/253 and Phase 200 Storybook owners"
    requirement: UXQ-04
    verification:
      - kind: integration
        ref: "verify_phase253_compositions.mjs (rc 0), npm run phase200:storybook (rc 0), npm run phase252:check (rc 0), plus theme_test.exs and subscription_production_boundary_test.exs (17 tests, 0 failures), all run on the recomposed bundle"
        status: pass
    human_judgment: false
  - id: D3
    description: "One typed source-bound assessment record exists at stage assessment with the fixed rubric, the 16 D-33 captures, every Phase 253 finding with its locked disposition and tier, and judged dispositions for the two new candidates"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node scripts/ci/verify_phase254_design_review.mjs --check --stage assessment exits 0 (9 findings, 16 captures, 7 rubric verdicts, 6 deferrals; every source sha and needle matches the file at source_commit 4a018ce9a; the Markdown view equals the renderer output)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The verifier rejects score-like keys, tmp evidence, stale source shas, unmapped changed baselines, missing or duplicate rubric dimensions, cross-dimension finding verdicts, empty no-finding verdicts, D-33 sourcing violations and contract text that is missing"
    requirement: UXQ-04
    verification:
      - kind: unit
        ref: "node --test scripts/ci/verify_phase254_design_review.test.mjs (37 pass) and --self-test (18 scenarios, each with a passing control); two seeded mutations of the verifier (needle check removed, cross-dimension check removed) both made the self-test fail"
        status: pass
      - kind: integration
        ref: "scanSubscriptionDetailSpacing positive control on the real app.css at source_commit finds exactly the five D-34 overrides (0.0625rem, 0.1875rem, 0.0625rem, 0, 0 0.25rem) and passes a token-only fixture"
        status: pass
    human_judgment: false

duration: 2h
completed: 2026-10-29
status: complete
commits: 4
plan_head_before: dcc3d9a6e7ed892ba5f0b37afc7a65f14d608441
plan_head_after: caf2fa929166371f05c6d2f8d5e4fa2afae8e318
---

# Phase 254 Plan 10: Storybook CSS recompose and the design review assessment (W4) Summary

**storybook.css is now recomposed deterministically and checked in CI against accrue_admin.css (it was 588 bytes behind), and one source-bound design review record opens at stage assessment with nine findings, a seven-dimension rubric and 16 planned captures, guarded by a verifier that rejects scores, tmp evidence and stale citations.**

## Performance

- **Duration:** about 2 h
- **Tasks:** 2 (4 commits: RED and GREEN for each)
- **Files modified:** 8 (6 created)

## Accomplishments

- Task 01: `scripts/ci/recompose_storybook_css.mjs` composes the three-line header, the PhoenixStorybook CSS, the brand.css section, the literal `/* === accrue_admin.css bundle === */` marker, the full admin bundle and the byte-preserved dark-mode shim tail. `--check` recomputes in memory, reports the embedded section sha256 against the bundle sha256 and rejects a drifted PSB, brand or layout section. `ci.yml` `admin-drift-docs` (the job that already runs `mix deps.get` in `accrue_admin` and rebuilds the bundle) runs the check after the rebuild and its `git diff --exit-code` list now includes `storybook.css` and `storybook.js`.
- Task 02: `254-DESIGN-REVIEW.json` (single source), the generated `254-DESIGN-REVIEW.md` and `scripts/ci/verify_phase254_design_review.mjs` with `--render`, `--check --stage` and `--self-test`. The record reads through `resolvePhaseEvidencePath`, so milestone archival cannot break it; the archive sweep stays green.

## Evidence values

- **storybook.css before:** 214278 bytes, sha256 `01523ccd5dbfe4f12b61e65c719be5b465ff70460da5164beca4ed02a1ebb86d`, embedded admin section 146738 bytes. **After:** 214932 bytes, sha256 `3263c1c07eba424ba9b30911353557fc417b4cfe6c2d59939d5fa40233ea7866`.
- **Admin bundle:** `accrue_admin.css` sha256 `a519a7541d05b74c769dd938e493fc886149585def2ff5bfa00cc7a270f77699` (147326 bytes, no trailing newline), served route `css-732833a179d48ed7c62dfbc3b30c8652`. The embedded section sha256 now equals it. `app.css` sha256 `7bd3fbdaad203eeaf50b28c24e6ef063e2aaf118dadb98b2c07d73cfeb22d0aa`, `theme.css` sha256 `165cca6107ddd75782bab339ec1f1612d33cf7cfac9d89132bef64601ec9f05a`.
- **Asset freshness correction (no CSS source edit):** the served Storybook bundle was missing the Phase 253-05 `.ax-data-table[data-ax-list=subscriptions]` identity-wrap rules that `accrue_admin.css` already carried; the diff is that one rule block plus the new markers and blank lines. Storybook story routes now render with the same identity wrapping production does.
- **Record:** `source_commit` `4a018ce9a2ed17a8d8d809b71fee6d34fc423ce2`; stage assessment; `fix_commit` null; all 16 captures `png_sha256` and `pass` null.

### Findings and dispositions

| Id | Origin | Dimension | Tier | Disposition |
|----|--------|-----------|------|-------------|
| DR-254-01 | 253#1 | hierarchy (page-tier 1px/3px/0 gaps and raw `0 0.25rem`) | page | fixed (pending, 254-12) |
| DR-254-02 | 253#2 | typography (H1: contract row, rule already responsive 24px to 28px at 768px) | contract | contract-amended: row `Page heading` |
| DR-254-03 | 253#2 | typography (detail field labels 14px vs summary keys 12px) | component | fixed (pending, 254-12) |
| DR-254-04 | 253#2 | typography (20px disclosure headings are the brandbook title role) | contract | contract-amended: new row `Section title` |
| DR-254-05 | 253#3 | microcopy (result-link label and path duplicated) | copy | fixed (pending, 254-13) |
| DR-254-06 | assessment | typography + color (audit heading weight 950 and accent) | component | deferred (DEF-254-04) |
| DR-254-07 | assessment | microcopy (caption "Audit event table: Actor / Action / Timestamp") | copy | deferred (DEF-254-05) |
| DR-254-08 | assessment | affordances (detail disclosure summaries do not use the shared disclosure summary treatment) | component | deferred (DEF-254-06) |
| DR-254-09 | assessment | redundancy (duplicate detail section title selectors) | component | deferred (DEF-254-03) |

Contract rows (both in `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md`, section Typography, edited by 254-12): the `Page heading` row is amended to a responsive heading (`--ax-type-xl`, 24px, below 768px; `--ax-type-2xl`, 28px, from 768px; Semibold 600; line height 1.2) and a `Section title` row is added (20px, `--ax-type-lg`, Semibold 600, 1.2). The exact `amended_text` strings are in the record. D-36 known deferrals are DEF-254-01 (`.ax-stack-sm` equals `.ax-stack-md`) and DEF-254-02 (bare `.ax-field-label` caps on six form controls). AMD-254-03 (D-33 "collection populated" becomes the Phase 253 `multiple_rows` story) is recorded with `owner_ack` 2026-10-28, owner-accepted at plan time; no checkpoint was raised.

Rubric verdicts: typography, color, hierarchy, redundancy, affordances and microcopy are finding verdicts; journey is assessed-no-finding with eight capture ids and five source refs, assessed from source (rendered keyboard order is the UXQ-02 mounted journey's job).

## Task Commits

1. **Task 254-10-01:** `133a080ed` (test, RED: the composer module did not exist), `4a018ce9a` (feat: composer, recomposed storybook.css, ci.yml step)
2. **Task 254-10-02:** `8df2b307c` (test, RED: verifier and record absent), `caf2fa929` (feat: verifier, record, generated view)

**Plan metadata:** recorded in the docs commit that follows this summary.

## Decisions Made

See key-decisions. No Rule 4 decision arose.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The plan's recompose recipe would have dropped the brand.css section**
- **Found during:** Task 01 (comparing the committed file with the recipe's output)
- **Issue:** the committed `storybook.css` is PhoenixStorybook CSS + `accrue/priv/static/brand.css` (4713 bytes of `--accrue-*` tokens, added in 85ee42df9) + the admin bundle + the shim tail; the plan and the 211-03 recipe list no brand section. Recomposing without it would have removed tokens the admin bundle (`--accrue-ink`, `--accrue-paper`, ...) and the dark shim read (4fed14b43 depends on the brand `:root` paper value).
- **Fix:** `composeStorybookCss` takes an optional `brandCss` and writes a `/* === brand.css === */` section before the bundle marker; the CLI always supplies it and `--check` requires it to match.
- **Files modified:** `scripts/ci/recompose_storybook_css.mjs`, its test
- **Commit:** `4a018ce9a`

**2. [Rule 1 - Bug] The admin bundle has no trailing newline**
- **Found during:** Task 01 (the first `--write` failed my own "must end with a newline" assumption)
- **Fix:** the separator after the bundle is one newline plus a blank line when the bundle lacks a trailing newline, and `--check` strips exactly that separator before hashing; a fixture covers the minified shape.
- **Commit:** `4a018ce9a`

**3. [Rule 3 - Blocking] The plan's lab command does not run from the repository root**
- **Issue:** `phase252_lab.mjs exec --lane admin-test -- mix test ...` fails with "Could not find a Mix.Project" because exec runs in the root.
- **Fix:** ran `phase252_lab.mjs exec --lane admin-test -- sh -c "cd accrue_admin && MIX_ENV=test mix test <file>"` (4 tests, 0 failures).

**4. [Rule 2 - Missing critical] Four findings beyond the five locked items**
- DR-254-06 and DR-254-07 are the two candidates D-34 asked to be judged. DR-254-08 and DR-254-09 were added because the rubric requires a finding or an assessed-no-finding for affordances and redundancy and source reading produced real observations (the detail summaries use `ax-detail-section-head` and not `ax-disclosure-summary`; the section title rule is declared twice). All four are deferred with tier and trigger, so the one correction batch in 254-12/13 is unchanged.

### Schema additions beyond the keys the plan pinned

`also_dimensions[]` (DR-254-06 carries typography and color), per-finding `rationale`, `mechanical_check`, a `needle` on each source ref, `contract.action` and `contract.note`, `deferred[].id` as DEF-254-NN with optional `finding_id`, `assets` as `{path, sha256}` objects with `served_css_route`, and test entries `{path, kind, status, id}`. 254-12, 254-13 and 254-15 extend this verifier (`parseRedReport`, `requireHeadingRedAmendment`, `requireRoutedA11yAmendment`, `confirmedCapturesMatchManifest`) and must keep these shapes.

### TDD note

Each task has a RED commit holding only the test file (it fails on that commit because the module does not exist) and a GREEN commit with the implementation. The implementation and tests were developed together between the two commits, as in 254-08 and 254-09.

### Noted, not changed

- The gate runs created the untracked `.planning/phases/200-idempotent-verification-sign-off/evidence/storybook-a11y.json` (the Phase 200 Storybook a11y run writes it; the only uncommitted work in the tree was the pre-existing `.planning/config.json`, which was left alone). It was removed after the gates finished, as in 254-09 (precedent `d0ea275be`). `accrue_admin/tmp/phase252/render-results.json` was not modified.
- `accrue_admin_assets.yml` (manual dispatch only) has its own copy of the freshness step and was not changed; the plan names only `ci.yml`.

## Known Stubs

None.

## Threat Flags

None. The verifier shells out to `git show` with an argument array (no shell) and reads only repository-relative paths (absolute and `..` paths are rejected); the composer reads four fixed paths. T-254-20 is mitigated by `--check` in `admin-drift-docs` plus the served-bytes ExUnit; T-254-21 by the score, tmp-path and stale-sha rejections and the diff-checked Markdown view. No dependency changed.

## Open flags for later plans

- **254-12 must write the contract rows verbatim** from `findings[DR-254-02|04].contract.amended_text` and keep the section's introductory sentence ("only these four size steps / two weights") consistent; the stage-corrected rule searches the file for those exact strings. DR-254-06 records that the audit heading's 950 weight breaks the two-weight rule, so that sentence needs care.
- **DR-254-08 depends on 254-11:** if the target-size or focus probes route a defect on `summary.ax-detail-section-head`, it is fixed in the 254-12 batch as a routed accessibility defect and DR-254-08 should then be re-dispositioned in 254-13-03; otherwise it stays deferred.
- **`scanSubscriptionDetailSpacing` counts only the five D-34 overrides** at source_commit (line 2988, 3050, 3060, 6710, 6720 of `app.css`); the breadcrumbs `gap: 0.125rem` is on-scale and passes. Line numbers have drifted by +4 from the Phase 253 audit; the record's refs are bound to `4a018ce9a`.
- **No `source_digests` input changed**, so the 254-04 regeneration recipe (R1 to R4) was not needed; `phase254_selection.mjs project --check` and `phase254_budget.mjs check` both stay green after the `storybook.css` change.
- **The verifier is not yet wired into any CI aggregate**; it needs `source_commit` in the fetched history (`fetch-depth: 0`) when 254-18 wires it. The Phase 211 mounted baselines are unaffected (no `app.css` or `accrue_admin.css` change); the Storybook-routed captures planned in 254-14 will be minted against the corrected bundle.
- KR-254-06 (docs-contracts SL-G and Executable UAT) is untouched and owner-accepted until 254-18. UXQ-04 is advanced here, not completed (254-12, 254-13, 254-15, 254-17 and 254-18 also declare it).

## Self-Check: PASSED

Created files exist (`recompose_storybook_css.mjs` and test, `verify_phase254_design_review.mjs` and test, `254-DESIGN-REVIEW.json` and `.md`); commits `133a080ed`, `4a018ce9a`, `8df2b307c` and `caf2fa929` are ancestors of HEAD; `git rev-list --count dcc3d9a6e..HEAD` measured 4 before this summary was committed.

---
*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Completed: 2026-10-29*
