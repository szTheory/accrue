# Phase 254: Recurring Quality, Reviewed Fixes and Curation - Context

**Gathered:** 2026-10-27
**Status:** Ready for planning
**Mode:** Owner-delegated fan-out synthesis. The owner supplied the standing fan-out methodology (breadth+depth across specialist lenses, adversarial pass, primary sources, "another copy-paste beats another dep") and asked for one coherent set of recommendations to follow automatically. Six parallel specialist researchers (selection, visual baselines, cost/budget, accessibility, design review, curation) grounded each area in current source; this file is the reconciled synthesis. No product decision here is one-way; reversible choices are locked so planning need not re-ask.

<domain>
## Phase Boundary

Deliver exactly CIQ-02, CIQ-03, CIQ-04, UXQ-02, UXQ-04, CURATE-01 and CURATE-02 for the subscription job built in Phases 252–253, preserving the phase's five roadmap success criteria:
transparent, fail-closed recurring browser selection with safe scheduling; deterministic Linux visual baselines for selected subscription states; reproducible cost measurements and a frozen budget; accessibility outcomes with narrow explicit dispositions; one bounded source-bound design review/correction/confirmation record; evidence-backed story retirement/merge records; and a refreshed gap map plus adopter briefs that inform (not open) the next UI job.

Not in scope: new Admin rooms or Portal jobs, new dependencies, a universal page schema, re-doing CIQ-01 workflow admission, the `accrue_events.inserted_at` timezone candidate, opening a new milestone, release/merge.
</domain>

<decisions>
## Implementation Decisions

### Cross-cutting (apply to every plan)
- **D-01:** No new dependencies. Reuse Playwright 1.59.1, axe-core 4.11.4 / @axe-core/playwright 4.11.3, existing reporters, Phase 226/227 CI-baseline tools, PhoenixStorybook, the component kitchen. Pinning the CI browser job to the `mcr.microsoft.com/playwright:v1.59.1-noble` image is allowed only if font drift is actually observed (an image, not a package).
- **D-02:** Every new check ships positive controls (injected defect must be caught) and negative controls, following the `scripts/ci/*` `--self-test` convention. A "0 found" is evidence only after the same checker finds a seeded positive. Use `git grep -c -e`, never `-- <pattern>`.
- **D-03:** Automated acceptance only (CLAUDE.md Executable Acceptance Policy). No owner manual UAT, no aesthetic score, no LLM judge on any gate path; screenshot stability is never design evidence.
- **D-04:** CI-read inputs (budget JSON, selection rules, curation ledger, disposition register, visual manifest) live in tracked package paths (`accrue_admin/storybook/`, `accrue_admin/e2e/`, `scripts/ci/`), never under `.planning/phases/`. Planning records that verifiers read go through `scripts/ci/phase_evidence_path.mjs` so milestone archival cannot break them.
- **D-05:** Editing covered/digested files re-mints digests; recompute with the owning module's own tooling (`scanArtifact`/`computeDigest`, manifest generators), never by hand.
- **D-06:** Never weaken existing gates: no widened `threshold`/`maxDiffPixelRatio`, no severity filters added, no retries, no `test.skip` for exclusions, no lowered cell counts to hit a budget. Existing 12 Phase 211 baselines, the 15/151 full-mode counts (as positive controls), and kitchen proof stay.
- **D-07:** A CSS change ships in three artifacts — `assets/css/app.css`, rebuilt committed `priv/static/accrue_admin.css` (`mix accrue_admin.assets.build`), and `storybook.css` which embeds it. Add `storybook.css`/js to the asset rebuild-freshness check and assert served-asset sha256 = committed file at capture time. `AccrueAdmin.Assets` embeds at compile time — a stale `_build` serves old bytes.

### Sequencing (resolves cross-area ordering conflicts)
- **D-08:** Waves:
  1. **W1 Measure:** timing harness + machine fingerprint + positive controls; measure existing Phase 252/253 lanes locally; get first real CI-runner observations.
  2. **W2 Shape the set:** CIQ-02 selector/report/isolation and CURATE-01 ledger (parallel — both change the case set, so they precede the freeze).
  3. **W3 Freeze:** re-measure the selected set on CI; freeze the budget.
  4. **W4 Assess + correct:** UXQ-04 assessment pass and single correction batch, and the UXQ-02 accessibility layer (a11y defects found are fixed in the same lowest-tier correction batch).
  5. **W5 Baselines + confirm:** CIQ-03 mint once, after corrections; UXQ-04 confirmation pass uses the minted/served captures; every changed PNG maps to a finding id.
  6. **W6 Close:** CURATE-02 gap map/briefs using measured maintenance cost; final CI measurement; deviation records closed; acceptance generator.
  Rationale: minting before corrections would freeze the "Visuals 2/4" compressed rhythm; freezing before curation would lock duplicates in or make curation look like dropped coverage.

### CIQ-02 — Selection, sentinels, safe scheduling
- **D-09:** Per-case `depends_on` (source paths) generated into the existing compiled manifests and constrained to be a subset of `source_digests`; a new `scripts/ci/phase254_selection.mjs` (+ test) extends `phase252_paths.mjs` `classifyPath`. Precision is honestly group-level (detail/collection/page); most CSS/admin PRs run `full` — transparency is the primary gain. Do NOT use Playwright `--only-changed`, Nx/Turbo/Bazel/Launchable or flake-based selection.
- **D-10:** Fail-closed rules: FC-1 unmapped and not on an explicit known-irrelevant allowlist → `full` (CIQ-01's `null` means "not focused", never "safe to skip"); FC-2 global roots (tokens/built CSS, brandbook tokens, `storybook.ex`, router, copy, scenario files, Playwright config/helpers, the selector itself, `ci.yml`, lab runner, lockfiles) → `full`; FC-3 missing/zero/unreachable base, shallow clone, diff error, or non-PR event (push to main, dispatch) → `full` — push-to-main is the recurring full sweep (no reliance on `schedule`, which skips `admin-phase200-guardrails`); FC-4 case without `depends_on` always selected (`broaden:no-metadata`), conflicting classes → `full`; FC-5 hard fail on invariant breach. Diffs use `--name-status --no-renames` so old paths of renames/deletes map too. Fix shallow checkout (`fetch-depth: 0`) where the selector runs.
- **D-11:** Selection report `accrue_admin/tmp/phase254/selection-<run_id>.json`, uploaded with existing evidence and rendered to `$GITHUB_STEP_SUMMARY`: run context (event, workflow/job, head/base sha, base_source, diff_status), manifest + selector digests, `changed_paths[]` with class/rule/case_ids, `mode` + `mode_reasons[]`, sorted `total_ids`, `selected[]` with reasons (`changed:<rule>|sentinel|broaden:<FC>`), `excluded[]` with reason, sentinel list + digest, per-case `fixture_class` and schedule, `always_run_mounted[]`. Invariants: selected ∩ excluded = ∅, union = total, selected ⊇ sentinels. Exclusions are report-only (unregistered, never `test.skip`). Selection is bound by case ID, not `--grep` on titles.
- **D-12:** Sentinels: a frozen, committed set of ~8 case IDs covering both themes, 320 and 1280, each tier, one overlay page, the 767/768 edge, synthetic-text stress and the geometry negative control. Changing it is a reviewed edit; contract test pins its digest. Retries stay 0.
- **D-13:** Pure-story isolation is a capability, not a convention: in the review lane, `E2E.Plug` refuses reset and seed (all route variants) with 403; a static contract classifies any spec touching reset/seed or importing `admin-visual-helpers` as mounted and rejects it from the pure-story project. Only then may pure-story cases fan out (per-project `workers` or `--shard`, each with its own lab partition/port/lock). Result ledger becomes one file per case merged at reconciliation (fixes the read-modify-write race); reconciliation runs as a dependent project. Mounted reset/seed specs stay 1 worker per server and are not selected or parallelized this phase.
- **D-14:** Required negative controls: collection-only change → `affected` with non-empty exclusions; `docs/x.md` → sentinels exactly; `accrue/lib/**`, `mix.lock`, `app.css` → `full`; missing metadata → broaden; empty base/shallow/push → `full`; stale sentinel, overlapping/incomplete sets, result row for excluded case, missing selected row → hard fail; review-lane reset → 403 with marker unchanged while test lane → 200; seeding spec in pure-story project → rejected; interleaved-write simulation loses a row in the old ledger, not the new; full mode still yields literal 15/151.

### CIQ-03 — Visual baselines
- **D-15:** Extend the existing Linux owner: a new spec in the `visual-desktop` project of `accrue_admin/playwright.config.js` (same snapshot folder, mint job and set guard), capturing the DB-free Cadence story routes, `.psb-sandbox` element only. No second baseline owner; keep the existing mounted captures (they prove production `accrue_admin.css`). First plan task confirms story routes render on the legacy browser server with a positive control; fall back to re-seeding mounted captures only if they cannot.
- **D-16:** Matrix (24 new PNGs): page variations `active`, `scheduled_cancellation`, `incomplete_evidence`, `review_cancel_now` + collection `multiple_rows`, `partial_cursor_error`; × 320 and 1280 × light and dark. 767/768/640 remain geometry checks from 253. If the frozen budget is exceeded, drop `scheduled_cancellation` first (recorded as a deviation).
- **D-17:** Determinism: `timezoneId: "UTC"`, `locale: "en-US"`, `reducedMotion: "reduce"`, `page.clock.setFixedTime("2026-10-25T12:00:00Z")` before navigation (matches `cadence_subscriptions.exs` `@now`), cleared time-display preference; `fonts.ready` plus assert Geist/Geist Mono FontFace `status === "loaded"` and served woff2 sha256; `document.getAnimations().length === 0`; theme positive control (a computed surface token differs light vs dark). 253 content assertions (identity, exact money, state, actions) run in the same test before the screenshot. New cases use `maxDiffPixels: 0`; stability proved once with `--repeat-each=3` in the mint PR — any diff is a determinism bug.
- **D-18:** Identity manifest `accrue_admin/e2e/__screenshots__/visual-desktop/manifest.json`: per key PNG sha256, case key, served css/js/font sha256, scenario-file sha256, Playwright + `browser.version()`, mint `github.sha` + run_id, reason, finding id. Gate fails on PNG set ≠ manifest keys (missing or extra — upgrade `visual-baseline-set.cjs`), byte mismatch, served ≠ committed asset, Chromium version mismatch, or a PNG changed since merge-base without current asset digests.
- **D-19:** Masks: new cases start with an empty allowlist; any mask needs a declared key, reason and a `<time>` target. Replace the Phase 211 text-regex protected-facts check with a geometry check (identity/amount/status/actions visible inside the capture and not intersecting any mask rect); negative control masks the amount and must fail. No `stylePath`. Also fix the duplicated `case "invoices"` at `admin-visual-regression-phase211.spec.js:62/67`.
- **D-20:** Reviewed changes: mint only via the existing workflow_dispatch job with explicit `--update-snapshots=changed`; upload only `if: success()`; commit PNGs + manifest in a dedicated `test(visual): rebaseline <keys>` commit with per-key reason/finding id. Contract test: `--update-snapshots` appears only in the mint job and thresholds are pinned. Never mint locally on macOS (template has no `{platform}`; manifest sha check catches it).

### CIQ-04 — Measurement and frozen budget
- **D-21:** Protocol: cold start (empty build path, fresh disposable DB, 3 runs; compile/DB/boot-to-health separated); warm preview (`serve` healthy, `page.goto`→ready marker on representative stories, 1 warmup + 10, median/p90); focused check (precompiled selected lane, 1 warmup + 5, median/p90, cell count, per-cell median/p90, overhead = `stats.duration − Σtests`); incremental CI (3 first-attempt runs, no reruns, Phase 227 rules; owner-job added time and workflow critical-path delta vs main baseline; queue excluded; cache hits recorded). Stop discarding per-test durations in `phase252_reporters.mjs`; keep its retry/flaky/skip rejection. Every sample records OS/arch/CPU/cores/RAM, `ImageOS`/`ImageVersion`, OTP/Elixir/Node/Playwright, workers, source revision, manifest sha, dirty flag. Mac numbers never freeze CI budgets.
- **D-22:** Budget artifact (tracked beside `accrue_admin/storybook/phase252-manifest.json`): schema_version, source_revision, manifest_sha256, selection{total, selected, sentinels, exclusions, broad_fallback}, metrics{samples, n, warmup, median, p90, min, max, machine}, provisional_targets, frozen{value, basis}, `warn_at` (frozen p90 × 1.25), `ceiling` (~2.5× frozen, hang guard), deviations[], widening_rule. Visual/a11y cells budgeted from their own measured per-cell cost.
- **D-23:** Enforcement: **fail** on executed identity set ≠ frozen selection, cell-count drop without a CURATE-01 record id, any skip/retry/flaky, budget digest ≠ manifest, missing fingerprint or job summary, ceiling exceeded. **Warn** (`::warning` + summary row) on timing above `warn_at`. Timing is never a hard gate below the ceiling (~20% same-machine noise observed). Re-freeze only via an appended deviation record; CI never rewrites the budget.
- **D-24:** Known deviation to resolve explicitly: local Phase 252+253 gates ≈ 7 min already exceed the provisional 5 min incremental target, and these lanes have never run on a CI runner. Resolution order: attribute (compile/boot/per-cell/queue — the repeated `mix run --no-start` manifest lanes and the 133s isolated production compile are first suspects) → remove duplicated work keeping every assertion → shard only isolated pure-story fixtures (D-13) → move broad sweeps only to an owner that demonstrably runs (push-to-main full, per D-10) → accept with recorded rationale (targets are provisional). Each record: target, measurement, decision, cell/owner counts before/after.
- **D-25:** First CI observations require pushing this branch (no upstream; well ahead of `origin/main`) and opening a draft PR / dispatching workflows. That is an outward-facing step: the plan includes it as an explicit task and execution confirms with the owner before the first push. No merge or release is implied.

### UXQ-02 — Accessibility
- **D-26:** Add an a11y layer to the existing Phase 253 composition cells (`accrue_admin/e2e/phase253-composition-helpers.js`) plus a mounted keyboard-journey test in `admin-interactions.spec.js`, and one committed disposition register `accrue_admin/e2e/a11y-dispositions.json` with a `--self-test` validator. No Storybook addon, pa11y or Lighthouse.
- **D-27:** axe in every selected cell, both themes, tags `wcag2a, wcag2aa, wcag21a, wcag21aa, wcag22aa`, **all severities** for these owners (today's critical/serious filter is a broad suppression), scanning overlay/drawer roots as well as `.psb-sandbox`. Every violation **and every `incomplete`** is either auto-resolved (e.g., contrast by compositing the actual background stack — fix the alpha drop in `foundation-tokens.spec.js` `parseColor` first) or matched to a disposition. Never target the hidden `subscription-action-drawer-test-mirror`. Existing owners outside the subscription scope keep their current behavior (widening them is deferred).
- **D-28:** Deep probes on the named subset (collection: one_row, multiple_rows, page_boundary, unavailable, partial_cursor_error, filtered_empty; page: active, review_cancel_now, awaiting_step_up, result_failed) at 320/1280 × light/dark: exact `getByRole` names (repeated row links unique, including identity); target size measured by bounding box with the 2.5.8 spacing-circle exception and inline auto-classification (other exceptions only via register); focus-visible reached by keyboard with ring ≥3:1 vs composited background and not obscured (2.4.11 via `elementFromPoint`); text spacing 1.4.12 via `adoptedStyleSheets` (scoped `bypassCSP` only for this probe if CSP blocks), verifying computed 0.12em before trusting, then rerun geometry checks; 200% text 1.4.4 via CDP `Page.setFontSizes` verifying ≥1.95× scale (no root-font multiplier as proof); 400% zoom = existing 320 cells (1.4.10); motion under both `reduce` and `no-preference` (normal: drawer has non-zero transition and focus settles after; reduce: ≤1ms, identity transform). 2.3.3 labelled AAA project target, not AA.
- **D-29:** Mounted keyboard journey on the real seeded route: list → row link → detail h1 → Cancel now → drawer; Tab/Shift+Tab N+1 wrap; Escape and "Back to subscription" restore focus to trigger (`expect.poll`, not `waitForTimeout`, because restore follows a LiveView patch); restage → step-up (focus in `#step-up-code`, Enter submits) → `role=status` result; focus never on `body`; return to list with filter preserved. Upgrade the existing trap probe's recorded-but-unasserted `focus-escaped`/`escape-not-dismissed`/`keyboard-flow-incomplete` rows to assertions for this journey.
- **D-30:** Register schema: id, rule_id, result_type (violation|incomplete), incomplete_reason (axe message key), exact cell_ids, exact axe target, expected_node_count, sc, exception_class, rationale, follow_up_assertion_id, review_by. Fails on: unmatched observation; entry whose cells ran but matched zero nodes; broad target (`*`, `html`, `body`, `#main-content`, `.psb-sandbox`, bare tag); node-count mismatch; wildcard cell_ids; expired review_by; any `disableRules`/`exclude`/severity filter in these owners (source-contract test). Positive controls inject: unnamed button, overlapping undersized target, trap escape, `outline:none`, unapplied spacing, unapplied scaling, motion under reduce, undispositioned incomplete; plus validator fixtures for unused/broad/expired entries.

### UXQ-04 — Bounded design review record
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

### CURATE-01 — Retirement/merge ledger
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

### CURATE-02 — Gap map, adopter briefs, next-job input
- **D-41:** Extend `caller_map` rows (no supplements): surface, actor, job, tier, owner, state (+`gated`), covering keys, uncovered states, entry trigger, review trigger. Seed jobs from Admin and Portal router `live` routes so a new route appears uncovered automatically (positive control fixture). Uncovered today: Portal list/detail/mounted journey; trialing, canceled, past-due at page tier.
- **D-42:** Adopter briefs: exactly the five in `SCENARIOS.md` — `launch`, `team` (implemented), `learner`, `operations`, `self_hosted` (labelled synthetic, no seeds/stories). Each names ≥1 equivalence class no other brief claims; verifier rejects overlap. No new industry profiles.
- **D-43:** Next-job scoring: hard filters first (entry trigger met — recovery gated on retry/campaign-history integrity; Portal gated on contract verification + dev/test harness), then ordinal high/medium/low ranking of uncovered reachable states (weighted by safety and frequency) against maintenance cost (new facts/fixtures, browser cells vs the frozen CIQ-04 budget, mounted fixtures); ties by shared-owner reuse then rolling-horizon order. Generated candidate table lives in the guide; the chosen recommendation is recorded in the Phase 254 artifact as a recommendation input only — not a milestone. Expected (not pre-decided) outcome: Admin customer investigation. Adjacency ("finish subscriptions in Portal") must not win while gated. No story-count scoring.

### Claude's Discretion
Plan count/boundaries within the D-08 wave order; exact file names for new verifiers; exact sentinel IDs within D-12's criteria; whether a11y deep probes share helper code with CIQ-03 captures; exact `warn_at`/`ceiling` multipliers if first measurements show they are unworkable (record as deviation). Stop further fan-out when it no longer changes a recommendation, scope, sequence or acceptance; record remaining assumptions explicitly and distinguish source findings from verified runtime behavior (e.g., story routes on the legacy port-4017 server is inferred, not yet run).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and policy
- `.planning/ROADMAP.md` §Phase 254 — goal and five success criteria
- `.planning/REQUIREMENTS.md` — CIQ-02/03/04, UXQ-02/04, CURATE-01/02 and Future Requirements boundaries
- `.planning/STATE.md` — carried items (six unclassified assumptions, source-only UI recommendations, unavailable monetary-source limit)
- `CLAUDE.md` — Executable Acceptance Policy, Agent Working Discipline (positive controls, archive sweep, digest re-mint)

### Approved research
- `.planning/research/ui-quality-engine/RECOMMENDATIONS.md` — gates/performance targets/a11y thresholds/curation ledger
- `.planning/research/ui-quality-engine/MILESTONE-PROPOSAL.md` — Phase 254 row, rolling roadmap
- `.planning/research/ui-quality-engine/DESIGN-AND-VERIFICATION.md`, `ARCHITECTURE.md`, `SCENARIOS.md` (adopter briefs :41-45), `INVENTORY.md`, `ADVERSARIAL-REVIEW.md`

### Prior phase evidence
- `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-REVIEW.md` — the three priority findings dispositioned in D-34
- `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-UI-SPEC.md`, `253-VERIFICATION.md`, `253-RESEARCH.md`
- `.planning/phases/252-production-backed-subscription-stories/252-VERIFICATION.md` — CIQ-01 evidence (do not redo)

### Brand
- `brandbook/` — authoritative (over `prompts/accrue-brand-book.md`); 7-step `--ax-*` type scale in `accrue_admin/assets/css/theme.css`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/phase252_paths.mjs:53-147` `CONSUMED_ROOTS`/`classifyPath` — selector base
- `accrue_admin/e2e/phase253-composition-helpers.js` — case universe (:295-331), `beginCollectionResults` (:364), `reconcileResults` (:409-444), `setTheme` (:512-521), `serveAndVerifyAssets` (:523-556), `runPageCase` (:1226-1290)
- `accrue_admin/playwright.config.js:13-21,50-57` — screenshot defaults, `visual-desktop` project; `accrue_admin/playwright.phase252.config.js:28-31,43` — 1 worker, no reuse
- `accrue_admin/e2e/admin-visual-regression-phase211.spec.js`, `visual-baseline-set.cjs`, `.github/workflows/accrue_admin_browser.yml:100-104,129-197` — Linux owner + mint job
- `scripts/ci/collect_ci_baseline.mjs`, `render_ci_baseline.mjs`, `verify_ci_critical_path.mjs` + `227-ci-contract.json` — CI timing and frozen-budget precedent
- `scripts/ci/verify_phase253_compositions.mjs:865` lane `duration_ms`; `scripts/ci/phase252_reporters.mjs:286-323` (drops per-test durations); `scripts/dev/phase252_lab.mjs` (lab, no warm-preview probe)
- `scripts/ci/verify_sensitive_token_census.mjs:257` — zero-match-entry-fails precedent for the a11y register
- `accrue_admin/storybook/_support/subscription_manifest.ex:194,240,474` — `caller_map`, compatibility set, `coverage_guide`
- `dev_support/ui_scenarios/cadence_subscriptions.exs:4,60` — fixed clock, `:populated` alias
- `accrue_admin/assets/js/hooks/focus_trap.js:27-36` — focus restore after LiveView patch

### Established Patterns
- Generated JSON source of truth + generated markdown view + `--self-test` verifier; red-evidence JSON before fixes
- Fresh lab partition + db/port lock per lane; `E2E.Plug` (`e2e_plug.ex:60,125`) currently exposes reset in every lane
- CSP `style-src 'self' 'nonce-…'` (`csp_plug.ex:22`) blocks injected `<style>`; type scale is rem
- Merge-blocking via `scripts/ci/verify_phase200_admin_guardrails.sh:23-24`; `admin-phase200-guardrails` skipped on `schedule` (`ci.yml:1244`) and shallow checkout (:1271)

### Integration Points
- `.github/workflows/ci.yml` browser/guardrail jobs (step summary, artifacts, checkout depth)
- `guides/subscription-story-coverage.md` (pinned path)
- Admin/Portal routers' `live` routes as gap-map seed

</code_context>

<specifics>
## Specific Ideas

- Owner methodology: fan out across all relevant lenses, adversarial pass, primary sources, coherent one-shot recommendations auto-followed; "another copy-paste is better than another dep".
- Prior-art lessons applied (inverted toward safety): Turborepo treats shallow clones as all-changed; Chromatic TurboSnap rebuilds everything on global/config change and ties baselines to accepted commit history; Bazel selection is sound only because declared inputs are verified (here: `depends_on` ⊆ digests); Playwright docs — automated a11y "cannot detect all types of WCAG violations"; Primer/Material token tiering decides "lowest owning tier".

</specifics>

<deferred>
## Deferred Ideas

- Widening all-severity/incomplete axe handling to non-subscription owners (`admin-a11y.spec.js`, phase200 storybook a11y, entitlements advisory).
- Selecting or parallelizing mounted reset/seed specs.
- `.ax-stack-sm` = md value cleanup (28 uses); `.ax-field-label` caps spilling to form labels; duplicate disclosure-heading selectors.
- Container image pinning for browser jobs (only if font drift is observed).
- Portal subscription jobs, recovery/webhook jobs, customer investigation — next-job candidates scored by CURATE-02, not built here.
- `accrue_events.inserted_at` session-timezone correctness candidate (independent; not authorized for indefinite deferral).

</deferred>

---

*Phase: 254-recurring-quality-reviewed-fixes-and-curation*
*Context gathered: 2026-10-27 via owner-delegated six-lens fan-out synthesis*
