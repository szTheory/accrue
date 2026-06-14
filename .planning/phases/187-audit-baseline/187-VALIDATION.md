---
phase: 187
slug: audit-baseline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 187 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit for Elixir; Playwright Test 1.59.1 for browser E2E; axe via `@axe-core/playwright` 4.11.3 |
| **Config file** | `accrue_admin/playwright.config.js`; `accrue_admin/test/test_helper.exs` |
| **Quick run command** | `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js --project=chromium-desktop -x` after the spec exists |
| **Full suite command** | `cd accrue_admin && npm run e2e` plus `cd accrue_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | TBD after Wave 0 specs exist |

---

## Sampling Rate

- **After every task commit:** Run the narrow Playwright spec or artifact parser touched by that task.
- **After every plan wave:** Run `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js e2e/admin-interactions.spec.js` after both files exist.
- **Before `$gsd-verify-work`:** Run `cd accrue_admin && npm run e2e`, `cd accrue_admin && mix test --warnings-as-errors`, and parse all committed Phase 187 JSON/NDJSON artifacts.
- **Max feedback latency:** TBD after baseline and interaction specs exist.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 187-W0-01 | TBD | 0 | VER-01 | T-187-01 | N/A | artifact smoke | `test -f .planning/phases/187-audit-baseline/187-RUBRIC.md && test -f .planning/phases/187-audit-baseline/baseline.cells.json && test -f .planning/phases/187-audit-baseline/defects.ndjson` | no | pending |
| 187-W0-02 | TBD | 0 | VER-01 | T-187-02 | E2E routes remain test-only | Playwright E2E | `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --project=chromium-desktop -x` | no | pending |
| 187-W0-03 | TBD | 0 | VER-01 | T-187-03 | Trace evidence contains deterministic test data only | Playwright E2E | `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js -x` | no | pending |
| 187-W0-04 | TBD | 0 | VER-01 | T-187-04 | NDJSON and JSON parsing use standard JSON APIs | Node smoke | `node -e 'const fs=require("fs"); JSON.parse(fs.readFileSync(".planning/phases/187-audit-baseline/baseline.cells.json","utf8")); const s=fs.readFileSync(".planning/phases/187-audit-baseline/defects.ndjson","utf8").trim(); if (s) for (const l of s.split("\\n")) JSON.parse(l);'` | no | pending |
| 187-W0-05 | TBD | 0 | VER-01 | T-187-05 | Existing accessibility scan remains runnable | Playwright axe | `cd accrue_admin && npm run e2e:a11y` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/e2e/baseline-manifest.js` or `.json` - canonical cells for VER-01.
- [ ] `accrue_admin/e2e/admin-baseline.spec.js` - manifest-driven static matrix and evidence generation.
- [ ] `accrue_admin/e2e/admin-interactions.spec.js` - modal/drawer/dropdown/scroll/focus/actionability probes with traces.
- [ ] Artifact generator script - emits `baseline.cells.json`, `defects.ndjson`, `artifacts.manifest.json`, and optional schemas.
- [ ] `accrue_admin/e2e/score-visuals.mjs` extension or wrapper - 12 dimensions and stable cell IDs.
- [ ] Permission-denied and disconnected/reconnecting reachability decision - add minimum fixture/probe support or mark explicit gaps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Optional vision scorer execution | VER-01 | It depends on `ANTHROPIC_API_KEY` being available in the execution environment. | If the key is present, run the scorer path produced by the plan and confirm findings are represented in `baseline.cells.json` and `artifacts.manifest.json`. If the key is absent, confirm the scorer skips cleanly and the baseline records that vision scoring was unavailable. |
| Exploratory live interaction observations | VER-01 | Phase 187 must record exploratory defects, but should not encode all broken behavior as permanent assertions before remediation phases. | Use Playwright traces and the defect ledger to verify modal, drawer, dropdown, scroll, focus, overlay, empty/error/permission/disconnected, disabled, and keyboard-only flows were explored and either covered, marked gap, or marked n/a. |

---

## Threat Model

| ID | STRIDE | Threat | Mitigation Required |
|----|--------|--------|---------------------|
| T-187-01 | Tampering | Structured baseline artifacts can drift from the human-readable baseline. | Treat `baseline.cells.json` and `defects.ndjson` as canonical; regenerate or correct `187-BASELINE.md` when they disagree. |
| T-187-02 | Elevation of privilege | Test-only E2E routes or fixture helpers could leak into production paths. | Keep E2E reset/login/seed behavior under existing test-only server paths; do not add production routes. |
| T-187-03 | Information disclosure | Screenshots or traces could capture real secrets or production data. | Use deterministic fake/admin test fixtures only; keep bulky evidence under generated output and reference it through `artifacts.manifest.json`. |
| T-187-04 | Tampering | Artifact generators could accept malformed or model-supplied metadata as authoritative. | Parse JSON/NDJSON with standard JSON APIs and enrich authoritative metadata from the manifest, not model output. |
| T-187-05 | Denial of service | Flaky live probes can block the phase or hide defects behind retries. | Prefer stable contracts and honest `gap` entries over retry loops that mask the baseline. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency recorded after baseline specs exist
- [ ] `nyquist_compliant: true` set in frontmatter after plans map tasks to this strategy

**Approval:** pending
