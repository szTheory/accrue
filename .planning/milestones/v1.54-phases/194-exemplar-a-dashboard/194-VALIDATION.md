---
phase: 194
slug: exemplar-a-dashboard
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-25
audited: 2026-07-01
verification_report: .planning/phases/194-exemplar-a-dashboard/194-VERIFICATION.md
---

# Phase 194 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (`@playwright/test`) for e2e page-flow invariants · ExUnit for the `verify_package_docs.sh` mirror · bash for the CI source guard |
| **Config file** | `accrue_admin/playwright.config.js` (existing); page-flow helpers `accrue_admin/e2e/phase191-page-flow-helpers.js` (existing — reused, no new helper library) |
| **Quick run command** | `cd accrue_admin && npx playwright test e2e/admin-spec-overview-phase194.spec.js --workers=1` |
| **Full suite command** | `cd accrue_admin && npm run e2e:phase194 && npm run e2e:phase191` + `bash scripts/ci/verify_package_docs.sh` + `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` |
| **Estimated runtime** | Playwright spec is full-browser and slow-by-design (~30–60s); it is NOT a hang. `verify_package_docs.sh` ~2–5s; the ExUnit mirror ~5–10s. Per-task Elixir gates (`mix compile --warnings-as-errors`, grep/awk/perl checks) are sub-second. |

---

## Sampling Rate

- **After every task commit:** Run the per-task `<automated>` command for that task (see map below). For LiveView/CSS tasks this is `mix compile --warnings-as-errors` + the marker/grep check; for guard tasks it is `bash scripts/ci/verify_package_docs.sh`; for spec tasks it is the quick Playwright run.
- **After every plan wave:** Run the full suite command — `npm run e2e:phase194` + `npm run e2e:phase191` (phase191 harness must stay green — zero regression) + `bash scripts/ci/verify_package_docs.sh` + the ExUnit mirror + a fresh `mix accrue_admin.assets.build` diff check.
- **Before `/gsd-verify-work`:** Full suite must be green AND zero `score-downgrade` rows in `regressions.ndjson` for the dashboard + recovery page-flow surfaces (SC3, per 194-04 Task 1 resolution).
- **Max feedback latency:** ~60s (bounded by the full-browser Playwright spec, intrinsically slow for DOM/focus/pointer invariants; mitigated with `--workers=1`). Per-task Elixir/bash gates return in <5s.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|

## Validation Audit 2026-07-01

| Metric | Count |
|--------|-------|
| Requirements audited | 1 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only requirements | 0 |

Phase 194 is Nyquist-compliant for EXE-01. `194-VERIFICATION.md` verifies the Dashboard overview grammar, Recovery work-queue ordering, Guard D, D-08 mirror coverage, and the focused browser contract with no behavior-unverified items. Current audit reran the focused Dashboard LiveView proof successfully.
| 194-01-01 | 01 | 1 | EXE-01 | T-194-01 | Markers carry static enum literals only (no PII/IDs) | unit (compile + grep) | `cd accrue_admin && mix compile --warnings-as-errors; grep -c 'data-ax-zone=...' lib/accrue_admin/live/dashboard_live.ex` | ✅ exists | ⬜ pending |
| 194-01-02 | 01 | 1 | EXE-01 | T-194-02 | Empty hero stays non-interactive (no cursor:pointer / role=button) | unit (grep + perl + guard) | `cd accrue_admin && grep -c 'ax-attention-rail--empty' lib/...dashboard_live.ex assets/css/app.css; perl block-scan; bash ../scripts/ci/verify_package_docs.sh` | ✅ exists | ⬜ pending |
| 194-01-03 | 01 | 1 | EXE-01 | T-194-02 | Served bundle reflects source (no dead CSS) | build + grep + diff | `cd accrue_admin && mix accrue_admin.assets.build && grep -c 'ax-attention-rail--empty' priv/static/accrue_admin.css && git -C .. diff --stat -- accrue_admin/priv/static/accrue_admin.css` | ✅ exists | ⬜ pending |
| 194-02-01 | 02 | 1 | EXE-01 | T-194-04 | Pure render re-order; attributes preserved verbatim | unit (compile + awk order) | `cd accrue_admin && mix compile --warnings-as-errors; awk 'table@<funnel@' lib/...analytics/recovery_live.ex` | ✅ exists | ⬜ pending |
| 194-02-02 | 02 | 1 | EXE-01 | T-194-03 | Markers honest to structure; static enum only | unit (compile + grep) | `cd accrue_admin && mix compile --warnings-as-errors; grep -c 'data-ax-zone' lib/...analytics/recovery_live.ex` | ✅ exists | ⬜ pending |
| 194-03-01 | 03 | 1 | EXE-01 | T-194-05 | Guard reads app.css via fixed grep/perl, no eval | guard (bash, planted violation) | `bash scripts/ci/verify_package_docs.sh` + planted `.ax-attention-rail--empty { cursor: pointer; }` → expect `empty-rail` fire | ✅ host exists; ❌ needle is W0-new | ⬜ pending |
| 194-03-02 | 03 | 1 | EXE-01 | T-194-06 | D-08 mirror keeps guard↔test in sync | unit (ExUnit) | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | ✅ host exists; ❌ negative test is W0-new | ⬜ pending |
| 194-04-01 | 04 | 2 | EXE-01 | — | SC3 baseline keying confirmed before gate wording | scorecard inspection | `cd accrue_admin && node -e '...validP187Id / compareCells...'` + cell-count check on `baseline.page-flow.cells.json` | ✅ exists | ⬜ pending |
| 194-04-02 | 04 | 2 | EXE-01 | T-194-07 | `assertTopPointerTarget` confirms empty hero not a pointer target | page-flow (Playwright) | `cd accrue_admin && node --check e2e/admin-spec-overview-phase194.spec.js && npx playwright test e2e/admin-spec-overview-phase194.spec.js --workers=1` | ❌ W0 (new spec) | ⬜ pending |
| 194-04-03 | 04 | 2 | EXE-01 | T-194-08 | Spec reads only vetted static marker values | page-flow + suite | `cd accrue_admin && grep -c 'e2e:phase194' package.json && npm run e2e:phase194 && npm run e2e:phase191 && bash ../scripts/ci/verify_package_docs.sh` | ❌ W0 (new script) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` — the SPEC-OVERVIEW invariant assertions (covers SC1, SC2 machine parts). Reuses `phase191-page-flow-helpers.js`; no new helper library. (194-04 Task 2)
- [ ] New `require_regex`-style empty-rail guard (Guard D) in `scripts/ci/verify_package_docs.sh` — fails when `.ax-attention-rail--empty` carries `cursor:pointer`; stable fail-message substring `empty-rail` (covers SC1 source-guard). (194-03 Task 1)
- [ ] New negative test in `accrue/test/accrue/docs/package_docs_verifier_test.exs` mirroring Guard D via the append-with-`\n` pattern against the already-seeded app.css fixture (D-08 coupling). (194-03 Task 2)
- [ ] `.ax-attention-rail--empty` class in `accrue_admin/assets/css/app.css` (elevated non-interactive D-06 hero) + rebuilt, committed `accrue_admin/priv/static/accrue_admin.css` bundle. (194-01 Tasks 2–3)
- [ ] `e2e:phase194` npm script in `accrue_admin/package.json`. (194-04 Task 3)

*Wave 0 is satisfied as the Wave-1 plans (194-01..194-03) and the Wave-2 spec (194-04) create these artifacts — there is no separate pre-wave; the new test infra IS the phase deliverable. Flip `wave_0_complete: true` once these five artifacts exist and are green.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Judge-graded 12-dim rubric: exceptions read higher-signal than KPIs; KPIs demoted-not-deleted; Recovery as work-queue not chart wall | SC1/SC2 / EXE-01 | Subjective visual hierarchy graded against `187-RUBRIC.md`, scored into `p193__dashboard__*` / `p193__recovery__*` cells | Score the dashboard + recovery page-flow cells per the 12-dim rubric; cells must read `≥` baseline (covered by the SC3 scorecard `score-downgrade` machine gate once scored). |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (new spec, Guard D, ExUnit mirror, `.ax-attention-rail--empty` class + rebuilt bundle, `e2e:phase194` script)
- [x] No watch-mode flags
- [x] Feedback latency < 60s (full-browser Playwright is slow-by-design, `--workers=1`; per-task gates <5s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-25
