# Phase 254: Recurring Quality, Reviewed Fixes and Curation - Research

**Researched:** 2026-10-28
**Domain:** CI test-selection and budgeting for a Playwright/Storybook lane, Linux pixel baselines, WCAG 2.2 AA browser probes, bounded design review, story curation (Elixir/Phoenix LiveView admin, Node `.mjs` verifiers)
**Confidence:** HIGH on repo facts and tooling pins (all read this session); MEDIUM on CI-runner cost (never observed); LOW on three browser behaviours that need a Wave-0 probe (A1-A3)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Cross-cutting (apply to every plan)**
- **D-01:** No new dependencies. Reuse Playwright 1.59.1, axe-core 4.11.4 / @axe-core/playwright 4.11.3, existing reporters, Phase 226/227 CI-baseline tools, PhoenixStorybook, the component kitchen. Pinning the CI browser job to the `mcr.microsoft.com/playwright:v1.59.1-noble` image is allowed only if font drift is actually observed (an image, not a package).
- **D-02:** Every new check ships positive controls (injected defect must be caught) and negative controls, following the `scripts/ci/*` `--self-test` convention. A "0 found" is evidence only after the same checker finds a seeded positive. Use `git grep -c -e`, never `-- <pattern>`.
- **D-03:** Automated acceptance only (CLAUDE.md Executable Acceptance Policy). No owner manual UAT, no aesthetic score, no LLM judge on any gate path; screenshot stability is never design evidence.
- **D-04:** CI-read inputs (budget JSON, selection rules, curation ledger, disposition register, visual manifest) live in tracked package paths (`accrue_admin/storybook/`, `accrue_admin/e2e/`, `scripts/ci/`), never under `.planning/phases/`. Planning records that verifiers read go through `scripts/ci/phase_evidence_path.mjs` so milestone archival cannot break them.
- **D-05:** Editing covered/digested files re-mints digests; recompute with the owning module's own tooling (`scanArtifact`/`computeDigest`, manifest generators), never by hand.
- **D-06:** Never weaken existing gates: no widened `threshold`/`maxDiffPixelRatio`, no severity filters added, no retries, no `test.skip` for exclusions, no lowered cell counts to hit a budget. Existing 12 Phase 211 baselines, the 15/151 full-mode counts (as positive controls), and kitchen proof stay.
- **D-07:** A CSS change ships in three artifacts — `assets/css/app.css`, rebuilt committed `priv/static/accrue_admin.css` (`mix accrue_admin.assets.build`), and `storybook.css` which embeds it. Add `storybook.css`/js to the asset rebuild-freshness check and assert served-asset sha256 = committed file at capture time. `AccrueAdmin.Assets` embeds at compile time — a stale `_build` serves old bytes.

**Sequencing (resolves cross-area ordering conflicts)**
- **D-08:** Waves:
  1. **W1 Measure:** timing harness + machine fingerprint + positive controls; measure existing Phase 252/253 lanes locally; get first real CI-runner observations.
  2. **W2 Shape the set:** CIQ-02 selector/report/isolation and CURATE-01 ledger (parallel — both change the case set, so they precede the freeze).
  3. **W3 Freeze:** re-measure the selected set on CI; freeze the budget.
  4. **W4 Assess + correct:** UXQ-04 assessment pass and single correction batch, and the UXQ-02 accessibility layer (a11y defects found are fixed in the same lowest-tier correction batch).
  5. **W5 Baselines + confirm:** CIQ-03 mint once, after corrections; UXQ-04 confirmation pass uses the minted/served captures; every changed PNG maps to a finding id.
  6. **W6 Close:** CURATE-02 gap map/briefs using measured maintenance cost; final CI measurement; deviation records closed; acceptance generator.
  Rationale: minting before corrections would freeze the "Visuals 2/4" compressed rhythm; freezing before curation would lock duplicates in or make curation look like dropped coverage.

**CIQ-02 — Selection, sentinels, safe scheduling**
- **D-09:** Per-case `depends_on` (source paths) generated into the existing compiled manifests and constrained to be a subset of `source_digests`; a new `scripts/ci/phase254_selection.mjs` (+ test) extends `phase252_paths.mjs` `classifyPath`. Precision is honestly group-level (detail/collection/page); most CSS/admin PRs run `full` — transparency is the primary gain. Do NOT use Playwright `--only-changed`, Nx/Turbo/Bazel/Launchable or flake-based selection.
- **D-10:** Fail-closed rules: FC-1 unmapped and not on an explicit known-irrelevant allowlist → `full` (CIQ-01's `null` means "not focused", never "safe to skip"); FC-2 global roots (tokens/built CSS, brandbook tokens, `storybook.ex`, router, copy, scenario files, Playwright config/helpers, the selector itself, `ci.yml`, lab runner, lockfiles) → `full`; FC-3 missing/zero/unreachable base, shallow clone, diff error, or non-PR event (push to main, dispatch) → `full` — push-to-main is the recurring full sweep (no reliance on `schedule`, which skips `admin-phase200-guardrails`); FC-4 case without `depends_on` always selected (`broaden:no-metadata`), conflicting classes → `full`; FC-5 hard fail on invariant breach. Diffs use `--name-status --no-renames` so old paths of renames/deletes map too. Fix shallow checkout (`fetch-depth: 0`) where the selector runs.
- **D-11:** Selection report `accrue_admin/tmp/phase254/selection-<run_id>.json`, uploaded with existing evidence and rendered to `$GITHUB_STEP_SUMMARY`: run context (event, workflow/job, head/base sha, base_source, diff_status), manifest + selector digests, `changed_paths[]` with class/rule/case_ids, `mode` + `mode_reasons[]`, sorted `total_ids`, `selected[]` with reasons (`changed:<rule>|sentinel|broaden:<FC>`), `excluded[]` with reason, sentinel list + digest, per-case `fixture_class` and schedule, `always_run_mounted[]`. Invariants: selected ∩ excluded = ∅, union = total, selected ⊇ sentinels. Exclusions are report-only (unregistered, never `test.skip`). Selection is bound by case ID, not `--grep` on titles.
- **D-12:** Sentinels: a frozen, committed set of ~8 case IDs covering both themes, 320 and 1280, each tier, one overlay page, the 767/768 edge, synthetic-text stress and the geometry negative control. Changing it is a reviewed edit; contract test pins its digest. Retries stay 0.
- **D-13:** Pure-story isolation is a capability, not a convention: in the review lane, `E2E.Plug` refuses reset and seed (all route variants) with 403; a static contract classifies any spec touching reset/seed or importing `admin-visual-helpers` as mounted and rejects it from the pure-story project. Only then may pure-story cases fan out (per-project `workers` or `--shard`, each with its own lab partition/port/lock). Result ledger becomes one file per case merged at reconciliation (fixes the read-modify-write race); reconciliation runs as a dependent project. Mounted reset/seed specs stay 1 worker per server and are not selected or parallelized this phase.
- **D-14:** Required negative controls: collection-only change → `affected` with non-empty exclusions; `docs/x.md` → sentinels exactly; `accrue/lib/**`, `mix.lock`, `app.css` → `full`; missing metadata → broaden; empty base/shallow/push → `full`; stale sentinel, overlapping/incomplete sets, result row for excluded case, missing selected row → hard fail; review-lane reset → 403 with marker unchanged while test lane → 200; seeding spec in pure-story project → rejected; interleaved-write simulation loses a row in the old ledger, not the new; full mode still yields literal 15/151.

**CIQ-03 — Visual baselines**
- **D-15:** Extend the existing Linux owner: a new spec in the `visual-desktop` project of `accrue_admin/playwright.config.js` (same snapshot folder, mint job and set guard), capturing the DB-free Cadence story routes, `.psb-sandbox` element only. No second baseline owner; keep the existing mounted captures (they prove production `accrue_admin.css`). First plan task confirms story routes render on the legacy browser server with a positive control; fall back to re-seeding mounted captures only if they cannot.
- **D-16:** Matrix (24 new PNGs): page variations `active`, `scheduled_cancellation`, `incomplete_evidence`, `review_cancel_now` + collection `multiple_rows`, `partial_cursor_error`; × 320 and 1280 × light and dark. 767/768/640 remain geometry checks from 253. If the frozen budget is exceeded, drop `scheduled_cancellation` first (recorded as a deviation).
- **D-17:** Determinism: `timezoneId: "UTC"`, `locale: "en-US"`, `reducedMotion: "reduce"`, `page.clock.setFixedTime("2026-10-25T12:00:00Z")` before navigation (matches `cadence_subscriptions.exs` `@now`), cleared time-display preference; `fonts.ready` plus assert Geist/Geist Mono FontFace `status === "loaded"` and served woff2 sha256; `document.getAnimations().length === 0`; theme positive control (a computed surface token differs light vs dark). 253 content assertions (identity, exact money, state, actions) run in the same test before the screenshot. New cases use `maxDiffPixels: 0`; stability proved once with `--repeat-each=3` in the mint PR — any diff is a determinism bug.
- **D-18:** Identity manifest `accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json`: per key PNG sha256, case key, served css/js/font sha256, scenario-file sha256, Playwright + `browser.version()`, mint `github.sha` + run_id, reason, finding id. Gate fails on PNG set ≠ manifest keys (missing or extra — upgrade `visual-baseline-set.cjs`), byte mismatch, served ≠ committed asset, Chromium version mismatch, or a PNG changed since merge-base without current asset digests.
- **D-19:** Masks: new cases start with an empty allowlist; any mask needs a declared key, reason and a `<time>` target. Replace the Phase 211 text-regex protected-facts check with a geometry check (identity/amount/status/actions visible inside the capture and not intersecting any mask rect); negative control masks the amount and must fail. No `stylePath`. Also fix the duplicated `case "invoices"` at `admin-visual-regression-phase211.spec.js:62/67`.
- **D-20:** Reviewed changes: mint only via the existing workflow_dispatch job with explicit `--update-snapshots=changed`; upload only `if: success()`; commit PNGs + manifest in a dedicated `test(visual): rebaseline <keys>` commit with per-key reason/finding id. Contract test: `--update-snapshots` appears only in the mint job and thresholds are pinned. Never mint locally on macOS (template has no `{platform}`; manifest sha check catches it).

**CIQ-04 — Measurement and frozen budget**
- **D-21:** Protocol: cold start (empty build path, fresh disposable DB, 3 runs; compile/DB/boot-to-health separated); warm preview (`serve` healthy, `page.goto`→ready marker on representative stories, 1 warmup + 10, median/p90); focused check (precompiled selected lane, 1 warmup + 5, median/p90, cell count, per-cell median/p90, overhead = `stats.duration − Σtests`); incremental CI (3 first-attempt runs, no reruns, Phase 227 rules; owner-job added time and workflow critical-path delta vs main baseline; queue excluded; cache hits recorded). Stop discarding per-test durations in `phase252_reporters.mjs`; keep its retry/flaky/skip rejection. Every sample records OS/arch/CPU/cores/RAM, `ImageOS`/`ImageVersion`, OTP/Elixir/Node/Playwright, workers, source revision, manifest sha, dirty flag. Mac numbers never freeze CI budgets.
- **D-22:** Budget artifact (tracked beside `accrue_admin/storybook/phase252-manifest.json`): schema_version, source_revision, manifest_sha256, selection{total, selected, sentinels, exclusions, broad_fallback}, metrics{samples, n, warmup, median, p90, min, max, machine}, provisional_targets, frozen{value, basis}, `warn_at` (frozen p90 × 1.25), `ceiling` (~2.5× frozen, hang guard), deviations[], widening_rule. Visual/a11y cells budgeted from their own measured per-cell cost.
- **D-23:** Enforcement: **fail** on executed identity set ≠ frozen selection, cell-count drop without a CURATE-01 record id, any skip/retry/flaky, budget digest ≠ manifest, missing fingerprint or job summary, ceiling exceeded. **Warn** (`::warning` + summary row) on timing above `warn_at`. Timing is never a hard gate below the ceiling (~20% same-machine noise observed). Re-freeze only via an appended deviation record; CI never rewrites the budget.
- **D-24:** Known deviation to resolve explicitly: local Phase 252+253 gates ≈ 7 min already exceed the provisional 5 min incremental target, and these lanes have never run on a CI runner. Resolution order: attribute (compile/boot/per-cell/queue — the repeated `mix run --no-start` manifest lanes and the 133s isolated production compile are first suspects) → remove duplicated work keeping every assertion → shard only isolated pure-story fixtures (D-13) → move broad sweeps only to an owner that demonstrably runs (push-to-main full, per D-10) → accept with recorded rationale (targets are provisional). Each record: target, measurement, decision, cell/owner counts before/after.
- **D-25:** First CI observations require pushing this branch (no upstream; well ahead of `origin/main`) and opening a draft PR / dispatching workflows. That is an outward-facing step: the plan includes it as an explicit task and execution confirms with the owner before the first push. No merge or release is implied.

**UXQ-02 — Accessibility**
- **D-26:** Add an a11y layer to the existing Phase 253 composition cells (`accrue_admin/e2e/phase253-composition-helpers.js`) plus a mounted keyboard-journey test in `admin-interactions.spec.js`, and one committed disposition register `accrue_admin/e2e/a11y-dispositions.json` with a `--self-test` validator. No Storybook addon, pa11y or Lighthouse.
- **D-27:** axe in every selected cell, both themes, tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, **all severities** for these owners (today's critical/serious filter is a broad suppression), scanning overlay/drawer roots as well as `.psb-sandbox`. Every violation **and every `incomplete`** is either auto-resolved (e.g., contrast by compositing the actual background stack — fix the alpha drop in `foundation-tokens.spec.js` `parseColor` first) or matched to a disposition. Never target the hidden `subscription-action-drawer-test-mirror`. Existing owners outside the subscription scope keep their current behavior (widening them is deferred).
- **D-28:** Deep probes on the named subset (collection: one_row, multiple_rows, page_boundary, unavailable, partial_cursor_error, filtered_empty; page: active, review_cancel_now, awaiting_step_up, result_failed) at 320/1280 × light/dark: exact `getByRole` names (repeated row links unique, including identity); target size measured by bounding box with the 2.5.8 spacing-circle exception and inline auto-classification (other exceptions only via register); focus-visible reached by keyboard with ring ≥3:1 vs composited background and not obscured (2.4.11 via `elementFromPoint`); text spacing 1.4.12 via `adoptedStyleSheets` (scoped `bypassCSP` only for this probe if CSP blocks), verifying computed 0.12em before trusting, then rerun geometry checks; 200% text 1.4.4 via CDP `Page.setFontSizes` verifying ≥1.95× scale (no root-font multiplier as proof); 400% zoom = existing 320 cells (1.4.10); motion under both `reduce` and `no-preference` (normal: drawer has non-zero transition and focus settles after; reduce: ≤1ms, identity transform). 2.3.3 labelled AAA project target, not AA.
- **D-29:** Mounted keyboard journey on the real seeded route: list → row link → detail h1 → Cancel now → drawer; Tab/Shift+Tab N+1 wrap; Escape and "Back to subscription" restore focus to trigger (`expect.poll`, not `waitForTimeout`, because restore follows a LiveView patch); restage → step-up (focus in `#step-up-code`, Enter submits) → `role=status` result; focus never on `body`; return to list with filter preserved. Upgrade the existing trap probe's recorded-but-unasserted `focus-escaped`/`escape-not-dismissed`/`keyboard-flow-incomplete` rows to assertions for this journey.
- **D-30:** Register schema: id, rule_id, result_type (violation|incomplete), incomplete_reason (axe message key), exact cell_ids, exact axe target, expected_node_count, sc, exception_class, rationale, follow_up_assertion_id, review_by. Fails on: unmatched observation; entry whose cells ran but matched zero nodes; broad target (`*`, `html`, `body`, `#main-content`, `.psb-sandbox`, bare tag); node-count mismatch; wildcard cell_ids; expired review_by; any `disableRules`/`exclude`/severity filter in these owners (source-contract test). Positive controls inject: unnamed button, overlapping undersized target, trap escape, `outline:none`, unapplied spacing, unapplied scaling, motion under reduce, undispositioned incomplete; plus validator fixtures for unused/broad/expired entries.

**UXQ-04 — Bounded design review record**
- **D-31:** Record = typed `254-DESIGN-REVIEW.json` (single source) + generated, diff-checked `254-DESIGN-REVIEW.md` view + node verifier with `--self-test`. Do not re-run gsd-ui-review scoring (its /24 scores violate "no aesthetic score"). Verifier rejects any score-like key and tmp-path evidence.
- **D-32:** Schema: source_commit, fix_commit; assets (sha256 of app.css, theme.css, priv/static/accrue_admin.css, storybook.css, served `css-<md5>` route); fixed rubric {typography, color, hierarchy, redundancy, affordances, microcopy, journey}; captures[] {id, route, width, theme, state ∈ settled|focus-visible|disclosure-open|review-open, png_sha256, pass}; findings[] {id, origin (253#n or assessment), dimension, claim, source_refs (path, lines, sha), evidence_captures, owning_tier ∈ token|component|group|page|copy|contract, disposition ∈ fixed|contract-amended|deferred|rejected, tests (path, kind, red evidence), confirmation_captures, verdict}; baselines_changed[] → finding ids; deferred[] with tier and trigger.
- **D-33:** Captures (16): collection populated, detail active, detail review-open — each 320/1280 × light/dark (12); detail with disclosure open + summary focused in the same four cells (4). Settled cells reuse CIQ-03 captures where identical; review-open/focus cells come from mounted routes; story routes used only after asserting `storybook.css` contains the `accrue_admin.css` bytes.
- **D-34:** Locked dispositions for the Phase 253 findings (verified against current source):
  - **Spacing (fix, page tier → remove overrides):** delete the page-tier 1px/3px/0 overrides (`app.css` ~2987-2989, 3049-3051, 3059-3061, 6709-6712) so component tokens apply; replace raw `0 0.25rem` (~6719-6724) with `--ax-space-xs`.
  - **H1 (contract-amended):** `.ax-display` is already responsive 24px→28px at 768px; amend the contract to a responsive heading (`--ax-type-xl`→`--ax-type-2xl`) and swap the two rem literals for those tokens with zero visual change (proved by `subscriptions.png` byte-identical). Do not edit shared `.ax-display` semantics.
  - **Field labels (fix, component tier):** `.ax-field-list .ax-field-label { font: var(--ax-type-label-sm-font) }` so detail labels = summary keys = `--ax-type-xs`; do not touch bare `.ax-field-label` (6 form controls share it); `.ax-field-value` keeps `tabular-nums` (never apply `font:` shorthand to values/KPIs).
  - **Disclosure headings 20px (contract-amended):** the brandbook's 7-step theme.css scale is authoritative; add a section-title role to the contract; the identical duplicate rule is a deferred cleanup.
  - **Result-link copy (fix, copy tier):** add `Copy.subscription_action_activity_link_label/0` and public `@doc false` `SubscriptionLive.action_activity_path/3`; story adapter calls both (as it already does for `action_result_message/1`).
  - **Focus/expanded captures:** added to the matrix (D-33).
  - New assessment candidates to judge (not pre-decided): audit heading weight 950 + accent color; dev-sounding "Audit event table: Actor / Action / Timestamp" label.
- **D-35:** Tests, each shown red on the pre-fix commit (`254-*-red-evidence.json`): computed `rowGap` equals resolved `var(--ax-space-*)` read through a probe element (no hard-coded px) + scoped CSS guard with a negative fixture; field-label size = summary-key size = `--ax-type-xs`, form labels unchanged, values keep `tabular-nums`; 767/768 assertions for the heading amendment; ExUnit asserting story label/href come from the owner functions + literal-count guard (`git grep -c -e`, with positive control). Composed `font:` roles pass the FND-01 guard; add no new `ax-type-exception`.
- **D-36:** Bounding: one assessment pass, one correction batch, one confirmation pass. Confirmation may only mark confirmed/not and fix regressions the batch itself caused; anything new is `deferred`. Only fix within the 16 capture cells. Known deferrals: `.ax-stack-sm` equals md (28 uses), `.ax-field-label` caps spilling to form labels, duplicate selectors. The label fix reaches 7 detail LiveViews — expect `subscription-detail`, `invoice-detail`, `component-kitchen` Phase 211 baselines to change in both themes; each changed PNG must map to a finding id or the verifier fails. Phase 198's intentionally dense invoice 2px gap is not a defect (off-scale values are).

**CURATE-01 — Retirement/merge ledger**
- **D-37:** A compiled curation ledger in `SubscriptionManifest` (`accrue_admin/storybook/_support/subscription_manifest.ex`), generated to tracked `accrue_admin/storybook/subscription-curation.json`, rendered into the existing `guides/subscription-story-coverage.md` (do not rename — path pinned at `verify_phase253_compositions.mjs:40`), verified by a new `.mjs` with `--self-test`. No hand-written CURATION.md (pointer only, if any); no tombstones left in story files/discovery.
- **D-38:** Record: id, subject{story_path, variation_id, scenario_id}, disposition ∈ retire|merge|retain|reclassify, reason_class ∈ stale|impossible|duplicate, reachability{state ∈ reachable|historic_supported|unreachable, owner, evidence[{path, marker}]}, reason, survivor{kind, key}, preserved_regressions[{test_ref, protects}], kitchen_impact ("none"), provenance{origin_commit, decided_in}; plus `frozen_baseline` (6 entries, 3 compatibility IDs, registry family/entry/specimen counts, manifest digest).
- **D-39:** Verifier rules: subject exists in frozen baseline; retired/merged ID absent from compiled discovery, `CadenceSubscriptionFacts.list/0`, tests/e2e and the a11y DOM-discovery scan (reference scan shown to find a seeded positive first; match exact `variation_id` — "populated" also hits unrelated `UI-E2-populated`); survivor present in current manifest **and rendered results**; reason evidence is mechanical (duplicate = fact/expected-block equality, never screenshot similarity; stale = names replacing owner; impossible = failing fixture invariant; grep absence alone rejected); preserved regressions exist and run in a required lane; registry counts ≥ baseline, kitchen test digests unchanged, no subject under `/dev/components`; baseline − retired = current, with the pinned literals (`verify_phase252_stories.mjs:436-439`, `generate_phase252_acceptance.mjs:339-345`, `subscription_manifest_test.exs:454`) derived from the ledger as an explicit amendment.
- **D-40:** Initial dispositions (planner verifies before acting):
  - `subscription_detail||populated` → **retire (duplicate)**; `fetch!(:populated)` = `fetch!(:active)`. Survivor `/components/subscription_detail||active` + page `active`. Mind that removing `:populated` from facts alters the shared ordinary list read by host/held-out checks — handle explicitly.
  - `braintree_pruned` → **retain, reclassify** as provider-boundary negative.
  - `dunning_active` → **retain, reclassify**, record claim drift (Phase 195 showed "recovery drill open"; now only a Dunning row); page-tier past-due/recovery becomes an uncovered state gated on retry/campaign-history integrity.
  - `action_menu/provider_pruned` → **merge (duplicate + stale story-local provider rule)**; survivors `action_menu/danger` (shape) and `subscription_detail/braintree_pruned` (provider claim).
  - `detail`, `overlay`, `page_header` stories → **retain** as primitive API regressions (only Storybook coverage of summary_list/overlay/PageHeader).
  - Correct stale gap rows (~:312 detail page, ~:330 list → covered by Phase 253 stories; ~:347 mounted journey → covered by SBK-06) in `caller_map` and update the test that locks the stale state (`subscription_manifest_test.exs:418`); keep the true claim "legacy route does not prove a whole page".

**CURATE-02 — Gap map, adopter briefs, next-job input**
- **D-41:** Extend `caller_map` rows (no supplements): surface, actor, job, tier, owner, state (+`gated`), covering keys, uncovered states, entry trigger, review trigger. Seed jobs from Admin and Portal router `live` routes so a new route appears uncovered automatically (positive control fixture). Uncovered today: Portal list/detail/mounted journey; trialing, canceled, past-due at page tier.
- **D-42:** Adopter briefs: exactly the five in `SCENARIOS.md` — `launch`, `team` (implemented), `learner`, `operations`, `self_hosted` (labelled synthetic, no seeds/stories). Each names ≥1 equivalence class no other brief claims; verifier rejects overlap. No new industry profiles.
- **D-43:** Next-job scoring: hard filters first (entry trigger met — recovery gated on retry/campaign-history integrity; Portal gated on contract verification + dev/test harness), then ordinal high/medium/low ranking of uncovered reachable states (weighted by safety and frequency) against maintenance cost (new facts/fixtures, browser cells vs the frozen CIQ-04 budget, mounted fixtures); ties by shared-owner reuse then rolling-horizon order. Generated candidate table lives in the guide; the chosen recommendation is recorded in the Phase 254 artifact as a recommendation input only — not a milestone. Expected (not pre-decided) outcome: Admin customer investigation. Adjacency ("finish subscriptions in Portal") must not win while gated. No story-count scoring.

### Claude's Discretion
Plan count/boundaries within the D-08 wave order; exact file names for new verifiers; exact sentinel IDs within D-12's criteria; whether a11y deep probes share helper code with CIQ-03 captures; exact `warn_at`/`ceiling` multipliers if first measurements show they are unworkable (record as deviation). Stop further fan-out when it no longer changes a recommendation, scope, sequence or acceptance; record remaining assumptions explicitly and distinguish source findings from verified runtime behavior (e.g., story routes on the legacy port-4017 server is inferred, not yet run).

### Deferred Ideas (OUT OF SCOPE)
- Widening all-severity/incomplete axe handling to non-subscription owners (`admin-a11y.spec.js`, phase200 storybook a11y, entitlements advisory).
- Selecting or parallelizing mounted reset/seed specs.
- `.ax-stack-sm` = md value cleanup (28 uses); `.ax-field-label` caps spilling to form labels; duplicate disclosure-heading selectors.
- Container image pinning for browser jobs (only if font drift is observed).
- Portal subscription jobs, recovery/webhook jobs, customer investigation — next-job candidates scored by CURATE-02, not built here.
- `accrue_events.inserted_at` session-timezone correctness candidate (independent; not authorized for indefinite deferral).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CIQ-02 | Selected/total IDs, sentinels, exclusions, conservative broadening, safe pure-story scheduling | Case universe is 6 detail + 10 collection + 9 page stories (151 cells + 15 phase252 cells). Selector must extend `phase252_paths.mjs`; the Phase 253 manifest is a **gitignored runtime artifact** (see "Findings that change planning"). Result-ledger race at `phase253-composition-helpers.js:390-402` confirmed. |
| CIQ-03 | Deterministic Linux baselines in the existing owner | `visual-desktop` project + mint job + `visual-baseline-set.cjs` located and read; set guard only detects *missing* files today; workflow path filter omits `storybook/**`. |
| CIQ-04 | Reproducible cold/warm/incremental costs, frozen budget, resolved deviations | Local per-lane `duration_ms` already recorded in `accrue_admin/tmp/phase25{2,3}/ci-results/*/results.json` (Phase 252 296.6 s + Phase 253 ~117 s). Phase 227 contract JSON + `verify_ci_critical_path.mjs` is the precedent. |
| UXQ-02 | Keyboard/focus/names/target/contrast/enlargement/motion, with narrow dispositions | axe-core 4.11.4 `target-size` is `enabled:!1` by default and only runs under tag `wcag22aa`; `parseColor` alpha drop confirmed; trap probe rows recorded-but-unasserted confirmed. |
| UXQ-04 | One bounded source-bound assessment/correction/confirmation record | Cited CSS lines verified; `storybook.css` has **no build task** (hand recipe) — a deterministic recompose script is required scope. |
| CURATE-01 | Evidence-backed retirement/merge records | `caller_map` stale rows and the `populated` alias verified; count-literal conflict with D-06 found (Open Question 1). |
| CURATE-02 | Refreshed gap map, adopter briefs, next-job input | `SCENARIOS.md` five-profile table verified; Admin/Portal router seeding feasible from `live(...)` routes. |
</phase_requirements>

## Summary

This phase is overwhelmingly assembly of existing owners, not new technology. Every locked decision in CONTEXT.md was spot-checked against source this session and held: the CSS line numbers, the duplicated `case "invoices"`, the read-modify-write result ledger, the alpha-dropping `parseColor`, the stale `caller_map` rows, the literal `15`/`12`/`3` counts, and the Phase 211 baseline owner. No new package is needed (D-01), so there is no Package Legitimacy surface.

The planning risk is not technology but **sequencing against two external-operation dependencies and several repo facts CONTEXT does not mention**: (1) Linux baselines (CIQ-03) and CI-runner numbers (CIQ-04) both *require* pushing the branch (160 commits ahead of `origin/main`, no upstream) and dispatching/observing workflows, which is the one place the Executable Acceptance Policy permits a human gate; (2) `priv/static/storybook.css` has no build task, so D-07's "freshness check" requires writing a deterministic recompose script first; (3) the Phase 253 compositions manifest is gitignored, so `depends_on`, the sentinel set and the visual case list need a tracked, drift-checked source. Local Phase 252+253 gates measure ~413 s on an M5 Pro, already above the 5 min target before any CI-runner slowdown — expect the D-24 deviation chain to run to its later steps.

**Primary recommendation:** Plan ~8 plans in D-08 wave order, make the owner-confirmed push + workflow dispatch an explicit early task (W1) because three downstream requirements hard-depend on it, build the recompose script and the tracked case-list/`depends_on` source before the selector and the visual spec, and treat every new verifier as `--self-test` + `node --test` pair with a seeded positive.

## Findings That Change Planning (not in CONTEXT.md)

| # | Finding | Evidence | Planning consequence |
|---|---------|----------|----------------------|
| F1 | CONTEXT D-22 says the budget is "tracked beside `accrue_admin/storybook/phase252-manifest.json`", but the tracked Phase 252 manifest is **`storybook/phase252-manifest.json`** (repo root, 6 entries, 12 `source_digests`). The Phase 253 compositions manifest is **gitignored**: `.gitignore:36:accrue_admin/tmp/phase253/manifest.json` and is written at run time. | `git ls-files` → `storybook/phase252-manifest.json`; `git check-ignore -v` output above; `phase253-composition-helpers.js:72-90` requires a launcher `RUN_ID` and reads `MANIFEST_PATH`. | Put new tracked inputs at `accrue_admin/storybook/phase254-*.json` / `subscription-curation.json` (D-04), not "beside" the root manifest. The `depends_on` list must be emitted by `SubscriptionCompositionsManifest` **and** `SubscriptionManifest`, with a committed, drift-checked projection (case-id list + sentinels + depends_on) for CI consumers that run without a launcher (the `visual-desktop` job has none). |
| F2 | `priv/static/storybook.css` is hand-recomposed (PSB CSS + `accrue_admin.css` + dark shim tail). `mix accrue_admin.assets.build` does not touch it; CI freshness only diffs `accrue_admin.css/js` (`ci.yml:994-1000`). | `211-03-SUMMARY.md`: "no mix rebuild task exists for it"; `grep storybook accrue_admin.assets.build.ex` → no match; `storybook.css` header "Composition: (1) PhoenixStorybook sandbox CSS (2) brand.css + accrue_admin.css (3) dark-mode shim". | UXQ-04's CSS fixes cannot ship without a **recompose script** (node, no dep) with `--check` mode and `--self-test`; D-07's freshness gate = embedded-section sha256 == `accrue_admin.css` sha256. Input: `deps/phoenix_storybook/priv/static/css/phoenix_storybook.css`; shim tail starts at marker `/* === D-17 Spike B`. Do this in W4 before any CSS edit. |
| F3 | `accrue_admin_browser.yml` triggers only on `accrue/**`, `accrue_admin/**` and itself. Story sources live at root `storybook/**` and `dev_support/ui_scenarios/**`. | `.github/workflows/accrue_admin_browser.yml:4-13`. | A story-only or scenario-only change never runs the visual owner. Add `storybook/**`, `dev_support/ui_scenarios/**`, `brandbook/tokens/**`, `scripts/ci/phase254_*` to both `paths` lists (the efficiency contract `verify_ci_efficiency_contract.mjs` scopes this workflow — keep it green). |
| F4 | `ci.yml` `pull_request` has **no path filter**, so `admin-phase200-guardrails` already runs on every PR. The CIQ-01 contract `assertCiContract` pins the owner-runner lines with anchored regexes. | `phase252_paths.mjs` `assertCiContract` (`phase252Step`, `phase253Step` regexes with `^...$`). | Append new `run_step` lines **after** the Phase 253 line; never edit the two pinned lines. Any new CI-read file needs a `CONSUMED_ROOTS` entry (and a `classifyPath` test) or the contract/selector treats it as unmapped. |
| F5 | The default Playwright projects `chromium-desktop`/`chromium-mobile` `testIgnore` only the Phase 211 and Phase 252-stories specs. Any new spec in `accrue_admin/e2e/` is picked up by `npm run e2e` unless ignored. | `accrue_admin/playwright.config.js` `testIgnore: [/admin-visual-regression-phase211\.spec\.js/, /subscription-stories-phase252\.spec\.js/]`. | Add the new visual spec to both `testIgnore` lists and to `visual-desktop` `testMatch`; add it to `playwright.phase252.config.js`'s explicit `testMatch` only if it is a pure-story lane spec. Add a contract test that every `e2e/*.spec.js` is matched by exactly one owner project. |
| F6 | Local lane timings are already recorded. Phase 252 total **296,553 ms** (`production-packages` 132,611; `heldout-cleanup` 58,688; `manifest-current` 64,084; `isolation-reset` 11,459; `subscription-render-browser` 10,819). Phase 253 total ≈ **117,000 ms** (`phase253-manifest-contract` 65,360; `phase253-compositions-browser` 43,243 for 151 cells). Sum ≈ 413 s ≈ 6.9 min on Apple M5 Pro, 18 cores, 64 GB. | `accrue_admin/tmp/phase252/ci-results/*/results.json`, `.../phase253/ci-results/*/results.json`, `commands[].duration_ms`. | These are W1 baseline fixtures, not budgets. The two ~65 s manifest lanes look like compile time on first `mix run --no-start`, the first D-24 attribution target. Browser work is cheap: 43 s / 151 cells ≈ 0.29 s per cell including startup. |
| F7 | The Phase 253 composition cells are pure-story and already **never call reset/seed** (`grep reset|seed` over `phase253-composition-helpers.js`, `subscription-compositions-phase253.spec.js`, `subscription-stories-phase252.spec.js` → only `/__e2e__/login` and a "Reset filters" link). The race that matters today is the single result-ledger file. | `phase253-composition-helpers.js:390-402` `appendResult` reads whole file, replaces/pushes row, rewrites (via temp file at :360). | Per-case ledger files + dependent reconcile is a real fix; the E2E.Plug 403 gate is a *capability* guard for future fan-out (D-13), and the static "mounted vs pure" classifier is cheap. Do not implement actual `--shard` fan-out unless D-24 attribution shows per-cell cost dominates — it does not (0.29 s/cell). |
| F8 | `examples/accrue_host/e2e/generated/copy_strings.json` is tracked and exported by `mix accrue_admin.export_copy_strings`. | `git ls-files`; `scripts/ci/accrue_host_verify_browser.sh:147`. | Adding `Copy.subscription_action_activity_link_label/0` (D-34) may drift this file; regenerate and commit if `git diff --exit-code` shows drift (known lesson, see MEMORY "CI green-up 260622"). |
| F9 | `visual-baseline-set.cjs` guards only *missing* files (`EXPECTED_BASELINES.filter(... missing)`), not extras. | `accrue_admin/e2e/visual-baseline-set.cjs:18-25`. | D-18's "PNG set ≠ manifest keys" requires rewriting this guard; `accrue_admin/test/js/*.mjs` tests it (CI step "Test Admin hooks and visual baseline set guard") — update both. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Changed-path to case selection, sentinels, report | CI tooling (`scripts/ci/*.mjs`) | Compiled Elixir manifest (emits `depends_on`) | Selection must run before Playwright starts and be digest-bound to the manifest. |
| Pure vs mounted fixture isolation | Test server (`E2E.Plug`, lab lane identity) | Static contract test | The 403 is a runtime capability; the classifier proves specs are in the right project. |
| Linux pixel baselines + identity manifest | Playwright `visual-desktop` project (CI Linux runner) | Node guard (`visual-baseline-set.cjs`) | Baselines are OS/font specific and mintable only on the CI owner. |
| Timing measurement + frozen budget | Node harness + tracked JSON | CI step summary / artifacts | Must be reproducible locally and on runner; CI never rewrites the budget. |
| Accessibility probes + dispositions | Browser helpers (Playwright + axe) | Node register validator | Browser computes facts; validator proves every observation is accounted for. |
| Design corrections | CSS tiers: token / component / page (`theme.css`, `app.css`), `Copy` owner for copy | Compiled committed bundles (`accrue_admin.css`, `storybook.css`) | Lowest owning tier rule; bundles are what is actually served. |
| Retirement/merge ledger | Elixir `SubscriptionManifest` (compiled, generated JSON) | Node verifier, guide renderer | Source of truth stays with the manifest; verifier proves reachability and survivors. |
| Gap map / briefs / recommendation | `caller_map` rows + generated guide | `SCENARIOS.md` (input) | Extends the existing generated, pinned-path guide. |

## Standard Stack

No new packages. Everything below is already installed and read this session.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@playwright/test` | 1.59.1 `[VERIFIED: accrue_admin/node_modules/@playwright/test/package.json]`; Chromium 147.0.7727.15 revision 1217 `[VERIFIED: node_modules/playwright-core/browsers.json]` | Browser cells, `toHaveScreenshot`, `page.clock`, CDP sessions | Already the owner for Phase 211/252/253. |
| `@axe-core/playwright` / `axe-core` | 4.11.3 / 4.11.4 `[VERIFIED: accrue_admin/node_modules package.json files]` | Rendered a11y scan | `target-size` rule: `id:"target-size",impact:"serious",selector:"*",enabled:!1,... tags:["cat.sensory-and-visual-cues","wcag22aa","wcag258"]` `[VERIFIED: axe-core/axe.js]` — disabled by default, runs when `wcag22aa` is requested. `getRules(["wcag22aa"])` returned exactly `[ 'target-size' ]`. |
| Node `node:test` + TAP reporter | Node 22.14.0 `[VERIFIED: node --version]` | Verifier tests (`node --test --test-reporter=tap`) | Existing convention (`scripts/ci/*.test.mjs`). |
| ExUnit via lab runner | Elixir 1.19.5 / OTP 28 `[VERIFIED: elixir --version]` | Manifest/ledger/story tests | Existing convention. |
| Phase 252 lab (`scripts/dev/phase252_lab.mjs`) | in-repo | Disposable DB/port/lock lanes `admin-test`, `admin-review`, `host-heldout` | Proven verify commands. |

### Verified Playwright API surface (installed 1.59.1 types)
- `updateSnapshots?: "all"|"changed"|"missing"|"none";` `[VERIFIED: playwright/types/test.d.ts:1950]` — D-20's `--update-snapshots=changed` is valid.
- Project-level `workers?: number|string;` `[VERIFIED: test.d.ts:742]` (docs at :708-735 describe "workers: 1, // workers limit for this project") — D-13's per-project workers is valid.
- `page.clock.setFixedTime(...)` `[VERIFIED: playwright-core/types/types.d.ts:19369-19371]`.
- `reducedMotion?: null|"reduce"|"no-preference";` `[VERIFIED: types.d.ts:2663]`.
- CDP `Page.setFontSizes` exists in the typed protocol `[VERIFIED: playwright-core/types/protocol.d.ts:16045,23827]`; its effect on rem text is **not verified** (A1).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-recomposed `storybook.css` | New mix task | A node script is enough and keeps "no new dep"; a mix task would be Elixir work in a package that already owns assets. Either is fine; node script keeps the CI check cheap. |
| Playwright `--only-changed` | (rejected by D-09) | Git-diff based, ignores our manifest/digests. |
| Linux Docker pre-flight (`mcr.microsoft.com/playwright:v1.59.1-noble`) | CI-only mint | Optional local determinism pre-flight (Docker daemon is up locally `[VERIFIED: docker ps]`); never the authoritative mint (D-20). |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed by this phase (D-01). `gsd_run query package-legitimacy check` not applicable.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 PR / push / dispatch event
          |
          v
  git diff --name-status --no-renames  <-- base sha (fetch-depth:0 or explicit fetch)
          |  (any failure => mode=full, FC-3)
          v
  phase254_selection.mjs
     classifyPath (phase252_paths) + depends_on map (from manifest projection)
     + known-irrelevant allowlist + global roots + sentinels (committed, digest-pinned)
          |
          +--> selection-<run_id>.json  --> $GITHUB_STEP_SUMMARY + artifact
          |         (selected / excluded / reasons / invariants)
          v
  selected case IDs (env: PHASE254_SELECTION=<file>, bound by id, not --grep)
          |
          v
  Playwright lane (admin-review, workers=1; pure-story cases)
     per case: load story route -> content asserts -> axe(all severities, 5 tags)
             -> deep probes (names, target size, focus, spacing, 200% text, motion)
             -> write ONE ledger file per case (results/<key>.json)
          |
          v
  dependent reconcile project: merge ledgers, assert executed == selected,
     excluded rows absent, sentinels present, 0 retries/skips/flaky
          |
          +--> durations (per-test, per-lane) --> budget verifier (fail/warn rules, D-23)
          |
  visual-desktop project (legacy server, CI Linux only):
     story routes -> deterministic page (clock/tz/locale/fonts/anim) -> content asserts
       -> toHaveScreenshot(maxDiffPixels:0) -> manifest.json identity gate
          |
  mint job (workflow_dispatch only, --update-snapshots=changed, if: success())
          -> artifact -> reviewed commit "test(visual): rebaseline <keys>"
```

### Recommended Project Structure (new/changed files)
```
scripts/ci/
├── phase254_selection.mjs (+ .test.mjs)        # CIQ-02 selector, report, invariants, --self-test
├── phase254_budget.mjs (+ .test.mjs)           # CIQ-04 budget verifier, fail/warn rules, --self-test
├── phase254_measure.mjs (or scripts/dev/)      # CIQ-04 sample harness + machine fingerprint
├── verify_phase254_curation.mjs (+ test)       # CURATE-01/02 verifier, --self-test
├── verify_phase254_design_review.mjs (+ test)  # UXQ-04 record verifier, --self-test
├── verify_a11y_dispositions.mjs (+ test)       # UXQ-02 register validator, --self-test
├── recompose_storybook_css.mjs (+ test)        # F2: deterministic storybook.css composer, --check/--self-test
├── generate_phase254_acceptance.mjs (+ test)   # acceptance + UAT artifact (mirror generate_phase253_acceptance)
└── phase252_paths.mjs                          # +CONSUMED_ROOTS entries for every new CI-read file
accrue_admin/
├── storybook/phase254-budget.json              # tracked budget (D-22)
├── storybook/phase254-selection.json           # tracked projection: case ids, depends_on, sentinels, fixture_class
├── storybook/subscription-curation.json        # generated ledger (D-37)
├── e2e/a11y-dispositions.json                  # register (D-26)
├── e2e/subscription-visual-phase254.spec.js    # new, visual-desktop only (F5)
├── e2e/__screenshots__/visual-desktop/manifest.json
└── e2e/phase253-composition-helpers.js         # +selection filter, +a11y layer, per-case ledger
.planning/phases/254-.../254-DESIGN-REVIEW.json (+ generated .md), 254-*-red-evidence.json
```

### Pattern 1: Digest-pinned committed projection of a gitignored manifest (resolves F1)
**What:** Generate a small tracked JSON (case ids, `depends_on`, `fixture_class`, sentinels) from the compiled manifests, and add a test that regenerates it and asserts byte-equality (the existing "generated + diff-checked" convention used for `guides/subscription-story-coverage.md`).
**When:** Every CI consumer that runs without the launcher (selector on a fresh checkout, visual spec, budget verifier).
**Example (shape only):**
```jsonc
// accrue_admin/storybook/phase254-selection.json (illustrative keys; values come from the manifests)
{ "schema_version": 1, "manifest_sha256": "<derived>", "source_digests": { "<path>": "<sha>" },
  "cases": [ { "id": "<key>", "tier": "page|collection|detail", "fixture_class": "pure-story",
               "depends_on": ["<subset of source_digests keys>"] } ],
  "sentinels": [ "<ids>" ], "sentinels_sha256": "<derived>" }
```
Constraint from D-09: `depends_on ⊆ source_digests` keys, enforced by test. Today `source_digests` has 8 (collection/page) and 12 (detail) files `[VERIFIED: node read of both manifests]`, so precision is group-level and component/CSS edits will be `full`.

### Pattern 2: Per-case ledger files + dependent reconcile
Replace `appendResult` read-modify-write (`phase253-composition-helpers.js:390-402`) with `<results-dir>/<sanitized-key>.json` writes (atomic temp+rename already exists at :360) and merge in the reconcile project. Keep the reconcile invariants (`reconcileResults` :409-444) and make "expected keys" = the selected set, with full mode still equal to the literal 151.

### Pattern 3: Result of every verifier = `--self-test` + `node --test` pair with seeded positives
Mirror `verify_phase252_transparency.mjs --self-test` and `generate_phase253_acceptance.test.mjs`. For the reference scan of D-39 prove it finds a seeded `populated` hit before accepting zero hits.

### Anti-Patterns to Avoid
- **Selecting by `--grep` on titles:** drift-prone; bind by case id (D-11).
- **`test.skip` for exclusions:** excluded cases are report-only, never registered.
- **Recording durations from macOS in the frozen budget:** fingerprint must show `ImageOS`; reject non-CI samples for `frozen` (D-21).
- **Putting CI-read data under `.planning/phases/`:** archive breaks it (CLAUDE.md milestone-close note); route planning reads through `phase_evidence_path.mjs`.
- **Rewriting `toHaveScreenshot` options globally:** new cases pass `maxDiffPixels: 0` locally in the call, existing config `threshold: 0.2` / `maxDiffPixelRatio: 0.01` stays untouched (D-06).
- **Minting on macOS:** `snapshotPathTemplate` is `e2e/__screenshots__/{projectName}/{arg}{ext}` with no platform token `[VERIFIED: playwright.config.js]`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Changed-path classification | A second path matcher | `classifyPath`/`CONSUMED_ROOTS`/`normalizeRepoPath` in `phase252_paths.mjs` | Already handles traversal rejection and exact/prefix modes. |
| Digest recompute for covered files | Manual sha editing | `scanArtifact` + `computeDigest` / manifest generators | D-05; CLAUDE.md warns hand-minted digests drift. |
| CI timing aggregation | New GitHub API client | `collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, `verify_ci_critical_path.mjs`, Phase 227 contract shape | Existing validation context, immutable-URL checks, rerun rejection. |
| Evidence path resolution across archive | Literal `.planning/phases/...` reads | `resolvePhaseEvidencePath(slug, artifact)` | Archive-aware; run `node scripts/ci/verify_phase230_archive_invariants.mjs --repo .` after any milestone close. |
| Disposable DB/port/lock lanes | Ad-hoc servers | `phase252_lab.mjs exec|serve|browser` | Owns partition/port/role identity checks. |
| Plain accessibility rule engine | Custom WCAG checks for what axe covers | axe with 5 tags | Hand-code only what axe cannot decide (names uniqueness, spacing, enlargement, focus order, motion). |
| Executable UAT artifact | Hand-written UAT | Mirror `generate_phase253_acceptance.mjs --latest --write-uat` + `verify_executable_uat_contract.mjs --phase 254` | Required by Executable Acceptance Policy. |
| Asset embed freshness | Canary-token greps | sha256 of embedded `accrue_admin.css` section vs file (pattern from 211-03) | Canaries missed dead CSS before. |

**Key insight:** The repo's moat is its verifier discipline (self-tests, seeded positives, digest pinning). Another copy-paste of that pattern is cheaper and safer than any new tool.

## Runtime State Inventory

Not a rename/migration phase, but CURATE-01 removes a story variation and possibly a fact alias. Explicit answers:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — stories and facts are compiled, DB-free (`CadenceSubscriptionFacts` is a pure module `[VERIFIED: dev_support/ui_scenarios/cadence_subscriptions.exs]`) | None |
| Live service config | None — no external service holds story ids | None |
| OS-registered state | None | None |
| Secrets/env vars | None new. Selector/lab use existing `PHASE252_E2E_*` env; new `PHASE254_*` env names are introduced by this phase | Document in the lab runner; contract test pins no secrets |
| Build artifacts | `accrue_admin/tmp/phase25{2,3}/**` (gitignored, local), `_build` (compile-time embedded assets, D-07), committed `priv/static/*.css` | Rebuild + recompose bundles after CSS edits; stale `_build` serves old bytes |

Code-edit vs data-migration: **code edits only**. One non-obvious reference set for `:populated`: `CadenceSubscriptionFacts.@ordinary_scenarios` (`:populated` listed, :48), `fetch!(:populated)` alias (:60 region), `subscription_detail.story.exs:34` `variation(:populated, ...)`, `subscription_manifest.ex:240` compatibility list, tests `subscription_scenarios_test.exs:102,167`, `subscription_story_slice_test.exs:186`, and `subscription_collection_transport_test.exs:108-114` (these use the string `"populated"` as a different, collection-side token — **do not conflate**, per D-39's exact `variation_id` rule).

## Common Pitfalls

### Pitfall 1: Retiring `populated` contradicts "15/151 stay"
**What goes wrong:** D-06/D-14 require full mode to yield literal 15/151; D-40 retires `subscription_detail||populated`, which is one of the 3 compatibility cases (`compatibility? = entry.variation_id in ["populated", "braintree_pruned", "dunning_active"]` `[VERIFIED: subscription_manifest.ex:240]`). The pinned checks demand `results.cases.length !== 15` / `canonical.length !== 12 || compatibility.length !== 3` `[VERIFIED: verify_phase252_stories.mjs:436-439; generate_phase252_acceptance.mjs:339-345]`.
**Why:** The two decisions were written by different lenses.
**How to avoid:** Resolve per D-39 ("baseline − retired = current, literals derived from the ledger"): the frozen baseline keeps 15 (6 entries, 3 compat) as a fixture positive control; post-curation full mode is **14 phase252 cells + 151**. See Open Question 1 — the planner should record this as an explicit amendment task in the CURATE-01 plan, not discover it at red CI.

### Pitfall 2: Stale `_build` or `storybook.css` makes captures lie
**What goes wrong:** `AccrueAdmin.Assets` embeds at compile time; `storybook.css` embeds an older `accrue_admin.css`; the captured pixels do not match the source claimed in the record.
**How to avoid:** F2 recompose script + `--check`; capture-time assertion that served css/js/font sha256 == committed files (already done for css/js in `serveAndVerifyAssets` `phase253-composition-helpers.js:523-556`, which reads `priv/static/storybook.css` and `storybook.js`); add woff2.

### Pitfall 3: Visual spec runs in the wrong projects
See F5. Without `testIgnore`, `npm run e2e` runs it on chromium-desktop and chromium-mobile and CI fails on missing baselines.

### Pitfall 4: Selector shallow-clone false "no change"
`actions/checkout@v6` default depth is 1 (admin-phase200-guardrails has no `fetch-depth`). For `pull_request` the checked-out commit is the merge ref; the base sha is absent. D-10 FC-3 makes this `full` — the plan must make `fetch-depth: 0` (or an explicit `git fetch --depth=1 origin <base_sha>`) the happy path and prove the shallow case yields `full` with a negative control.

### Pitfall 5: Widened CSS fixes ripple into other Phase 211 baselines
D-36 already expects `subscription-detail`, `invoice-detail`, `component-kitchen` to change in both themes (7 detail LiveViews share `.ax-field-label` via `.ax-field-list`). The mint must happen once, after the correction batch; every changed PNG maps to a finding id or the verifier fails (D-18/D-32).

### Pitfall 6: CSS cascade order
`.ax-field-label` is declared twice: `app.css:4122` (`font: var(--ax-type-label-font)`) and `app.css:6732` (`font-size: var(--ax-type-sm); font-weight: 600; text-transform: uppercase; ...`) `[VERIFIED: sed of app.css]`. The later rule wins for equal specificity; D-34's `.ax-field-list .ax-field-label` raises specificity, which is why it is scoped. Use a probe element reading computed `font-size` after the change rather than reasoning about order. `font:` shorthand resets `line-height`; `.ax-subscription-detail-page .ax-field-label` sets `line-height: var(--ax-leading-normal)` at higher specificity (:6726-6730) — assert both.

### Pitfall 7: `adoptedStyleSheets` and CSP
The Admin CSP is `style-src 'self' 'nonce-…'` (`csp_plug.ex:22`, per CONTEXT). Constructed stylesheets may or may not be blocked; do not assume. Wave-0 probe with a positive control (inject a visible style and assert computed value changed); fall back to scoped `bypassCSP` only for that probe context (A2).

### Pitfall 8: `Page.setFontSizes` may not scale `rem`
It changes browser default font sizes; whether it multiplies the root `medium` the type scale resolves against is unverified (A1). D-28 already demands a ≥1.95× verification — implement that check *first* with a positive control and a seeded "unapplied scaling" negative; if it fails, the fallback is a context-level `deviceScaleFactor`/browser zoom analog is **not** equivalent to 1.4.4 — record a disposition rather than proving by a root-font multiplier.

### Pitfall 9: Measurement noise and wrong machine
Local noise ≈ 20% (CONTEXT). Cold = empty build path; warm = precompiled. The frozen value must come from `ubuntu-24.04` runner samples (4 vCPU per the workflow comment `MIX_OS_DEPS_COMPILE_PARTITION_COUNT: 4`, "ubuntu-24.04 runners have 4 vCPU" `[CITED: .github/workflows/accrue_admin_browser.yml comment]`), n≥3 first-attempt runs, no reruns.

### Pitfall 10: `$GITHUB_STEP_SUMMARY` markdown injection from path names
Changed paths are attacker-influenced in PRs. Escape backticks/pipes/newlines when rendering the selection table; add a fixture with a hostile path (`|`, backtick, newline-free check) to the self-test.

### Pitfall 11: Planning docs are consumed roots
`CONSUMED_ROOTS` lists Phase 252/253 PLAN/VALIDATION paths as consumed. Adding Phase 254 planning files that CI reads repeats this coupling. Keep CI reads out of `.planning/phases/` (D-04); the only planning-resident reads should be via `phase_evidence_path.mjs` (design review record verified by a node verifier that resolves through it).

## Code Examples

Verified patterns from this repo.

### Lab-run verification commands (proven in Phase 253)
```bash
# Source: .planning/phases/253-.../253-VALIDATION.md (Per-Task Verification Map)
node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/live/subscriptions_live_test.exs
node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js
cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_compositions_manifest_test.exs
node --test --test-reporter=tap scripts/ci/verify_phase253_compositions.test.mjs
```

### Deterministic page setup for visual cases (all APIs verified in installed types)
```js
// Source: Playwright 1.59.1 types (page.clock.setFixedTime, reducedMotion, timezoneId); D-17 values.
test.use({ timezoneId: "UTC", locale: "en-US", reducedMotion: "reduce", colorScheme: "light" });
await page.clock.setFixedTime("2026-10-25T12:00:00Z"); // before page.goto; matches @now in cadence_subscriptions.exs
await page.goto(`/__e2e__/login?to=${encodeURIComponent(entry.iframe_path)}`); // login route pattern used at helpers :740
await page.evaluate(() => document.fonts.ready);
// then assert FontFace status === "loaded" for Geist and Geist Mono, document.getAnimations().length === 0
await expect(sandbox).toHaveScreenshot(`${key}.png`, { maxDiffPixels: 0 });
```
`@now ~U[2026-10-25 12:00:00Z]` `[VERIFIED: cadence_subscriptions.exs:4]`.

### Axe invocation for the subscription owners (all severities)
```js
// Source: @axe-core/playwright 4.11.3 usage in admin-a11y.spec.js (withTags(...).analyze()); D-27 tag set.
const results = await new AxeBuilder({ page })
  .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
  .include(rootSelector)           // narrow, not exclude; never target the hidden test mirror
  .analyze();
// results.violations AND results.incomplete both go through the disposition matcher; no impact filter.
```
Existing broad filter to NOT copy: `return results.violations.filter((v) => v.impact === "critical" || v.impact === "serious");` `[VERIFIED: admin-a11y.spec.js:27]`.

### `parseColor` alpha defect (fix before relying on contrast)
```js
// Source: accrue_admin/e2e/foundation-tokens.spec.js:15-17 (verbatim)
const match = value.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([0-9.]+))?\)/);
if (match) return match.slice(1, 4).map(Number);   // alpha (group 4) is dropped
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Screenshot diff as design evidence | Screenshot stability only proves determinism; design review is a typed source-bound record (D-03, D-31) | Verifier rejects score keys and tmp-path evidence. |
| axe critical/serious filter | All severities + all `incomplete` accounted for via register (D-27, D-30) | New obligation; existing non-subscription owners unchanged (deferred). |
| Single mutable results file | Per-case files + dependent reconcile | Removes the race; enables future fan-out. |
| `--update-snapshots` (all) in mint job | `--update-snapshots=changed`, upload only on success | Prevents silent re-baselining of unchanged cells. |

**Deprecated/outdated:** `schedule`-based sweeps for this owner — `admin-phase200-guardrails` is skipped on `schedule` (`ci.yml:1244 if: github.event_name != 'schedule'`); push-to-main is the recurring full sweep (D-10).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CDP `Page.setFontSizes` makes `rem`-based text scale ≥1.95× in Playwright Chromium (protocol exists; effect unverified) | Pitfall 8 / UXQ-02 | 1.4.4 probe cannot be implemented as written; fall back to a recorded disposition |
| A2 | Constructed stylesheets (`adoptedStyleSheets`) may be blocked or allowed under the admin CSP; behaviour not tested | Pitfall 7 | 1.4.12 probe needs scoped `bypassCSP` |
| A3 | `workflow_dispatch` / `gh workflow run --ref <branch>` can run the existing workflows (present on `main`) against the pushed branch, and a draft PR triggers `ci.yml` without path filters | Sequencing / D-25 | W1/W3/W5 CI evidence cannot be produced; escalate to owner |
| A4 | Story routes for the Phase 253 collection/page stories render on the legacy `mix accrue_admin.e2e.server` (port 4017) exactly as on the lab server. Supporting evidence: `phase200:storybook` runs `admin-storybook-a11y-phase200.spec.js` (rootPath `/billing/dev/storybook`) against that server `[VERIFIED: package.json:45, spec :26]`; the Phase 253 `direct_path`s use the same prefix. Not run this session. | CIQ-03 | D-15 fallback to mounted captures (re-seed) |
| A5 | CI-runner timings will be slower than the M5 Pro by some unknown factor (likely 1.5-3x on compile); the 5 min incremental target is probably unmet | CIQ-04 | D-24 chain proceeds past "remove duplicates" to "accept with rationale"; not a defect |
| A6 | Local Docker Playwright image reproduces the CI runner's Chromium/fonts closely enough for a pre-flight determinism check (Geist is served from woff2, so system-font exposure is small) | CIQ-03 | Pre-flight false confidence; CI mint remains authoritative |
| A7 | The accrue_admin_browser.yml workflow is treated by the owner as merge-blocking by convention; branch protection cannot be read from the API (comment in `collect_ci_baseline.mjs`: endpoints "return empty on this repository") | CIQ-03 | If it is not actually required, a red visual gate does not block merges — surface to owner |
| A8 | WCAG success-criterion semantics cited in D-28 (2.5.8 spacing-circle exception, 2.4.11, 1.4.10/12, 2.3.3 AAA) are applied as described in CONTEXT; not re-fetched from w3.org this session | UXQ-02 | Probe thresholds mis-specified |

## Open Questions (RESOLVED)

All five questions are resolved by the Phase 254 plans; each entry below records the decision the plans take. None remains open.

1. **D-06 "15/151 stay" vs D-40 "retire `populated`"** — RESOLVED
   - Known: retiring removes 1 of the 3 compatibility cases ⇒ phase252 browser cases 15 → 14; collection/page 151 unaffected.
   - Decision taken: D-39 already locks "pinned literals derived from the ledger as an explicit amendment". 15/151 stays as `frozen_baseline` in the curation ledger and as the fixture positive control; the live counts are ledger-derived (14/151 after the retirement). Implemented by 254-04 (ledger, derived count sites) and 254-06 (retirement), and recorded as amendment `AMD-254-01` in `accrue_admin/storybook/subscription-curation.json`, which the 254-18 acceptance generator requires.

2. **Where do CIQ-03 visual captures run relative to the CIQ-01 required owner?** — RESOLVED
   - Decision taken: D-15 holds — one baseline owner, the `visual-desktop` project in `accrue_admin_browser.yml`, with the F3 path filters (254-14). Selection, budget and record checks stay in `ci.yml` `admin-phase200-guardrails` (254-08, 254-09, 254-17). The browser workflow is budgeted as its own job: 254-09 freezes a measured `allowances.visual` against the browser-uat job and records in a budget deviation that this workflow sits outside the `ci.yml` 5 min critical path. Whether branch protection requires it (A7) stays a recorded assumption; it is not asserted.

3. **Mounted vs story-route sources for the 4 focus/disclosure captures** — RESOLVED
   - Decision taken: D-33 (locked) wins over the story-only recommendation. Settled cells (collection populated → story `multiple_rows`, detail active → story page `active`) reuse CIQ-03 story captures; detail review-open (4) and disclosure-open + summary-focused (4) come from mounted routes. All 16 are committed, Linux-minted `toHaveScreenshot` baselines in the one identity manifest — never tmp PNGs. This adds 8 mounted keys to the D-16 matrix (24 story + 8 mounted = 32), recorded as amendment `AMD-254-02` in `accrue_admin/storybook/phase254-visual-cases.json`. The `populated` → `multiple_rows` collection substitution (the Phase 253 collection universe has no `populated` state) is recorded as `AMD-254-03` in the design review record (254-10).

4. **Locally verifying pixel gates** — RESOLVED
   - Decision taken: each case runs its deterministic preparation and content assertions locally with `--update-snapshots=none`; the local gate accepts only Playwright's missing-snapshot error on the screenshot step and asserts the snapshot directory is unchanged (254-14-01). The Linux mint job is authoritative (254-15). No environment flag disables the screenshot assertion; the Docker pre-flight (A6) is optional and never a gate.

5. **First push (D-25)** — RESOLVED
   - Decision taken: a `checkpoint:decision` (gate `blocking-human`) is the first task of 254-03. `push-approved` covers later pushes and workflow dispatches on this branch; `push-declined` halts exactly the push-dependent tasks (254-03-02, 254-09-03, 254-15-01, 254-18-01) at the last locally provable boundary without fabricated runner numbers. Out-of-scope CI reds observed after the push are triaged mechanically and escalated through `checkpoint:decision` tasks 254-03-03, 254-15-02 and 254-18-02.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node | all `.mjs` verifiers, Playwright | ✓ | 22.14.0 | — |
| Elixir / OTP | manifests, ExUnit | ✓ | 1.19.5 / OTP 28 | — |
| PostgreSQL | lab lanes | ✓ (`/tmp:5432 - accepting connections`) | local | — |
| Playwright + Chromium | browser cells | ✓ | 1.59.1 / Chromium 147.0.7727.15 (cache dir has `chromium-1217`) | — |
| `gh` CLI | pushing, dispatch, artifact download | ✓ (logged in as `szTheory`) | — | — |
| Docker daemon | optional Linux pre-flight | ✓ (`docker ps` ok) | 29.5.2 client | skip pre-flight |
| Git remote `origin` | D-25 push | ✓ `https://github.com/szTheory/accrue.git`; branch has 160 commits not on `origin/main` | — | — |
| Linux CI runner timings | CIQ-04 freeze | ✗ never observed | — | None for freeze; local numbers only inform |

**Missing dependencies with no fallback:** CI-runner observations (require the owner-confirmed push + dispatch).
**Missing dependencies with fallback:** Docker image pre-flight (optional).

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` `[VERIFIED: config read]`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Node `node:test` (TAP) for `scripts/ci`; ExUnit for `accrue_admin` (via lab); Playwright 1.59.1 for browser |
| Config file | `accrue_admin/playwright.config.js` (legacy; `visual-desktop`), `accrue_admin/playwright.phase252.config.js` (lab, `workers: 1`, requires `PHASE252_E2E_*` env) |
| Quick run command | `node --test --test-reporter=tap scripts/ci/<new>.test.mjs` and `node scripts/ci/<verifier>.mjs --self-test` |
| Full suite command | `npm --prefix accrue_admin run phase252:check && node scripts/ci/verify_phase253_compositions.mjs` (existing), plus the new Phase 254 aggregate added after them; CI: `bash scripts/ci/verify_phase200_admin_guardrails.sh` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CIQ-02 | collection-only diff → `affected` + non-empty exclusions; `docs/x.md` → sentinels only; `accrue/lib/**`, `mix.lock`, `app.css` → `full`; missing metadata/shallow/empty base/push → broaden/`full`; invariant breaches hard-fail | unit + self-test | `node --test --test-reporter=tap scripts/ci/phase254_selection.test.mjs && node scripts/ci/phase254_selection.mjs --self-test` | ❌ Wave 1/2 |
| CIQ-02 | review-lane reset/seed → 403, marker unchanged; test lane → 200 | ExUnit | `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/e2e_plug_isolation_test.exs` (path illustrative) | ❌ Wave 2 |
| CIQ-02 | pure-story project rejects specs touching reset/seed or `admin-visual-helpers`; every `e2e/*.spec.js` owned by exactly one project | static contract | `node --test --test-reporter=tap scripts/ci/phase254_project_ownership.test.mjs` | ❌ Wave 2 |
| CIQ-02 | per-case ledger loses no row under interleaved writes (old ledger loses one — positive control) | unit | in `verify_phase253_compositions.test.mjs` or new test | ❌ Wave 2 |
| CIQ-02 | full mode still literal counts (14/151 post-curation; 15/151 as frozen baseline fixture) | acceptance | `node scripts/ci/verify_phase253_compositions.mjs` + `npm --prefix accrue_admin run phase252:check` | ✅ (literals amended) |
| CIQ-03 | 24 new + 12 existing PNG set == manifest keys; extra/missing fail; byte/asset/Chromium mismatch fail | node test | `cd accrue_admin && node --test test/js/*.mjs` | ✅ partial (needs new cases) |
| CIQ-03 | determinism: fonts loaded, animations 0, theme token differs, content asserts, mask geometry negative control | browser (Linux) | `cd accrue_admin && npm run e2e:visual-regression` (CI authoritative); `--repeat-each=3` once in mint PR | ❌ Wave 5 |
| CIQ-03 | `--update-snapshots` only in mint job; thresholds pinned; upload `if: success()` | contract | `node --test --test-reporter=tap scripts/ci/phase254_visual_contract.test.mjs` | ❌ Wave 5 |
| CIQ-04 | harness records fingerprint + per-test durations; reporter keeps retry/flaky/skip rejection | unit | `node --test --test-reporter=tap scripts/ci/phase252_reporters.test.mjs` (or the existing suite that covers it) | ✅/❌ confirm in Wave 0 |
| CIQ-04 | budget verifier: identity-set mismatch, count drop w/o record id, skip/retry/flaky, digest mismatch, missing fingerprint/summary, ceiling → fail; above `warn_at` → warn only | unit + self-test | `node --test --test-reporter=tap scripts/ci/phase254_budget.test.mjs && node scripts/ci/phase254_budget.mjs --self-test` | ❌ Wave 3 |
| UXQ-02 | each probe fails on its injected defect and passes on the real cell | browser | `node scripts/dev/phase252_lab.mjs browser -- e2e/subscription-compositions-phase253.spec.js` | ✅ extend |
| UXQ-02 | register validator rejections (unmatched, zero-node, broad target, wildcard, expired, count mismatch) and source-contract (`disableRules|exclude|impact filter` absent in these owners — with seeded positive) | node test | `node --test --test-reporter=tap scripts/ci/verify_a11y_dispositions.test.mjs && node scripts/ci/verify_a11y_dispositions.mjs --self-test` | ❌ Wave 4 |
| UXQ-02 | mounted keyboard journey (focus restore via `expect.poll`) | browser (legacy server) | `cd accrue_admin && env -u NO_COLOR npx playwright test e2e/admin-interactions.spec.js --workers=1` | ✅ extend |
| UXQ-04 | each fix red on pre-fix commit, green after: gaps via token-resolved `rowGap`, label size = key size, 767/768 heading, copy owner functions + literal-count guard | browser + ExUnit | lab `browser` / `exec` commands for new specs/tests; red evidence JSON `254-*-red-evidence.json` | ❌ Wave 4 |
| UXQ-04 | record verifier: no score keys, no tmp-path evidence, every changed PNG maps to a finding, source shas current, MD view in sync | node test | `node --test --test-reporter=tap scripts/ci/verify_phase254_design_review.test.mjs && node scripts/ci/verify_phase254_design_review.mjs --self-test` | ❌ Wave 5 |
| UXQ-04 | `storybook.css` embeds current `accrue_admin.css` | node test | `node scripts/ci/recompose_storybook_css.mjs --check && node --test --test-reporter=tap scripts/ci/recompose_storybook_css.test.mjs` | ❌ Wave 4 |
| CURATE-01 | ledger rules D-39 incl. seeded-positive reference scan, survivor in rendered results, preserved regressions run in required lane | node + ExUnit | `node --test --test-reporter=tap scripts/ci/verify_phase254_curation.test.mjs`; `node scripts/dev/phase252_lab.mjs exec --lane admin-test -- mix test test/accrue_admin/dev/subscription_manifest_test.exs` | ❌/✅ amend |
| CURATE-02 | new route in router fixture appears `uncovered`; five briefs each claim a unique class; overlap rejected; Portal gated candidate cannot win | node + ExUnit | same files as CURATE-01 | ❌ Wave 6 |
| All | executable acceptance + UAT artifact | generator | `node scripts/ci/generate_phase254_acceptance.mjs --latest --write-uat && node scripts/ci/verify_executable_uat_contract.mjs --phase 254` | ❌ Wave 6 |

### Sampling Rate
- **Per task commit:** the task's `node --test` / `--self-test` plus its focused lab command (≤ 60 s target).
- **Per wave merge:** `npm --prefix accrue_admin run phase252:check` and `node scripts/ci/verify_phase253_compositions.mjs` (≈ 7 min locally — consider running at wave boundaries only), plus the new Phase 254 aggregate.
- **Phase gate:** full local aggregate green, then CI observation on the pushed branch (owner-confirmed), `verify_phase230_archive_invariants.mjs --repo .`, and `verify_executable_uat_contract.mjs --phase 254`.

### Wave 0 Gaps
- [ ] Probe spikes (each with positive control, recorded in a spike note): `Page.setFontSizes` scaling (A1), `adoptedStyleSheets` under CSP (A2), story routes on the legacy server (A4).
- [ ] `scripts/ci/phase254_selection.{mjs,test.mjs}` skeleton + `phase254-selection.json` projection generator.
- [ ] Per-test duration retention in `phase252_reporters.mjs` (keep rejection logic) + test.
- [ ] `recompose_storybook_css.mjs` (+ `--check`) before any CSS edit.
- [ ] Project-ownership static contract for `e2e/*.spec.js` (F5).
- [ ] `CONSUMED_ROOTS` entries for every new CI-read path + `classifyPath` tests.

## Security Domain

`security_enforcement` is not set to `false` in config (absent = enabled).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no (test-only login helper unchanged) | existing `/__e2e__/login`; do not extend |
| V4 Access Control | yes (limited) | `E2E.Plug` reset/seed refusal in `admin-review` lane (403), keyed on the lane identity; plug is test-support only (`test/support/e2e_plug.ex`), never compiled into prod |
| V5 Input Validation | yes | `normalizeRepoPath`-style validation for every path read from `git diff`; JSON schema checks on budget/register/ledger inputs; escape output rendered to `$GITHUB_STEP_SUMMARY` |
| V6 Cryptography | no new use | sha256 via `node:crypto` (existing) — never custom |
| V10/V14 Config & CI | yes | No `pull_request_target`; no widened permissions; artifacts uploaded only on success for mint; CI never rewrites the budget |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hostile PR path names injecting markdown/log commands | Tampering | Escape table cells and workflow commands; hostile-path fixture in self-test |
| Selector trusts a forged/stale projection | Tampering/Spoofing | `manifest_sha256` + `source_digests` verified against files; sentinels digest pinned |
| Reset endpoint reachable in a lane used for pure stories | Elevation/DoS | 403 in review lane with unchanged-marker assertion; positive control in test lane |
| Silent suppression of a11y findings | Repudiation | Source-contract test banning `disableRules`/`exclude`/impact filters in these owners; register zero-match entries fail (precedent `verify_sensitive_token_census.mjs:257`) |
| Baseline poisoning by a local macOS mint | Tampering | manifest records `browser.version()` + served asset shas + mint run id; mint only in workflow job |
| Secrets in recorded fingerprints | Information disclosure | Fingerprint allow-list (OS/CPU/versions/revision); no env dump |

## Sources

### Primary (HIGH confidence — read this session)
- `.planning/phases/254-.../254-CONTEXT.md`, `.planning/REQUIREMENTS.md` (lines 34-49, 93-102), `.planning/STATE.md` (Phase 254 entries), `.planning/config.json`
- Repo source: `scripts/ci/phase252_paths.mjs` (lines 40-249), `scripts/ci/phase252_reporters.mjs` (270-330), `scripts/ci/verify_phase253_compositions.mjs` (head), `scripts/ci/verify_phase252_stories.mjs:430-442`, `scripts/ci/generate_phase252_acceptance.mjs:335-348`, `scripts/dev/phase252_lab.mjs` (lanes), `accrue_admin/playwright.config.js`, `accrue_admin/playwright.phase252.config.js`, `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`, `accrue_admin/e2e/visual-baseline-set.cjs`, `accrue_admin/e2e/phase253-composition-helpers.js` (72-110, 285-335, 385-408, 1226-1240), `accrue_admin/e2e/foundation-tokens.spec.js:15-24`, `accrue_admin/e2e/admin-a11y.spec.js:26-27`, `accrue_admin/test/support/e2e_plug.ex`, `accrue_admin/lib/accrue_admin/router.ex:140-195`, `accrue_admin/storybook/_support/subscription_manifest.ex:185-360`, `accrue_admin/assets/css/app.css` (2984-3064, 4120-4135, 6705-6745, 760-785, 2158-2166), `theme.css:25-117`, `dev_support/ui_scenarios/cadence_subscriptions.exs:1-72`, `.github/workflows/accrue_admin_browser.yml`, `.github/workflows/ci.yml` (1-40, 985-1010, 1236-1345), `scripts/ci/verify_phase200_admin_guardrails.sh`, `guides/subscription-story-coverage.md`, `.planning/research/ui-quality-engine/SCENARIOS.md:36-48`
- Local measurements: `accrue_admin/tmp/phase252/ci-results/*/results.json`, `accrue_admin/tmp/phase253/ci-results/*/results.json`, `accrue_admin/tmp/phase253/manifest.json`, `storybook/phase252-manifest.json`
- Installed tooling: `accrue_admin/node_modules/{@playwright/test,@axe-core/playwright,axe-core,playwright,playwright-core}` (versions, `test.d.ts`, `types.d.ts`, `protocol.d.ts`, `axe.js` rule metadata)
- Prior phase evidence: `253-UI-REVIEW.md` (priority fixes), `253-VALIDATION.md`, `.planning/milestones/v1.57-phases/211-.../211-03-PLAN.md`, `211-03-SUMMARY.md`, `211-RESEARCH.md` (Bundle Rebuild)

### Secondary (MEDIUM confidence)
- Phase 227 contract shape: `.planning/milestones/v1.61-phases/227-measured-critical-path-improvement/227-ci-contract.json` and `scripts/ci/verify_ci_critical_path.mjs` (structure read; not re-run)

### Tertiary (LOW confidence — not verified, see Assumptions Log)
- Chromium behaviour for `Page.setFontSizes`, constructable stylesheets vs CSP, `gh workflow run --ref` on a branch, Docker image parity, WCAG nuance (A1-A3, A6, A8)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions and API surface read from installed packages; no new deps.
- Architecture: HIGH for repo structure and seams; MEDIUM for CI-runner cost and the legacy-server story route (A4/A5).
- Pitfalls: HIGH for F1-F9 (each read in source); LOW for A1-A3 browser behaviours until the Wave-0 probes run.

**Research date:** 2026-10-28
**Valid until:** 30 days for tooling pins (Playwright 1.59.1 / axe 4.11.x are locked by the lockfile); repo facts are valid until the next commit touching the cited files — re-grep line numbers before editing.
