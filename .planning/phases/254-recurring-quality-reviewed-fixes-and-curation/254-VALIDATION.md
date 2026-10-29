---
phase: "254"
slug: "recurring-quality-reviewed-fixes-and-curation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-28"
---

# Phase 254 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `254-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node `node:test` (scripts/ci), ExUnit via lab (accrue_admin), Playwright 1.59.1 (browser) |
| **Config file** | `accrue_admin/playwright.config.js`, `accrue_admin/playwright.phase252.config.js` |
| **Quick run command** | `node --test --test-reporter=tap scripts/ci/<new>.test.mjs` + `node scripts/ci/<verifier>.mjs --self-test` |
| **Full suite command** | `npm --prefix accrue_admin run phase252:check && node scripts/ci/verify_phase253_compositions.mjs` + Phase 254 aggregate |
| **Estimated runtime** | ~60 seconds quick; ~420 seconds full |

---

## Sampling Rate

- **After every task commit:** task's `node --test` / `--self-test` + focused lab command (≤ 60 s target)
- **After every plan wave:** full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green, plus `verify_phase230_archive_invariants.mjs --repo .` and `verify_executable_uat_contract.mjs --phase 254`
- **Max feedback latency:** 60 seconds (per task)

---

## Research Validation Architecture (verbatim)

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

---

## Per-Task Verification Map

*Populated by the planner/executor from PLAN.md `<automated>` commands.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Manual-Only Verifications

All phase behaviors have automated verification (Executable Acceptance Policy). The owner-confirmed push (D-25) is a credential/irreversible-operation action, not an acceptance substitute.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
