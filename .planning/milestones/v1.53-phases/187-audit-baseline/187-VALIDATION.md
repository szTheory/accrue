---
phase: 187
slug: audit-baseline
status: ready
nyquist_compliant: true
wave_0_complete: true
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
| **Estimated runtime** | Recorded by execution in `accrue_admin/test-results/phase187-command-status.json`; planning verification commands are task-scoped and non-watch-mode. |

---

## Sampling Rate

- **After every task commit:** Run the narrow Playwright spec or artifact parser touched by that task.
- **After every plan wave:** Run the narrow verification commands declared in the completed plan files for that wave; after Wave 3, run both baseline and interaction specs in their project-specific narrow modes.
- **Before `$gsd-verify-work`:** Run the Plan 05 non-aborting audit wrapper, `cd accrue_admin && mix test --warnings-as-errors`, `cd accrue_admin && npm run baseline:parse`, and parse all committed Phase 187 JSON/NDJSON artifacts.
- **Max feedback latency:** One task. Every behavior-producing task has an `<automated>` verification command; Plan 05 preserves evidence generation when UI/a11y/interaction defects are discovered.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 187-01-T1 | 187-01 | 1 | VER-01 | T-187-01 | Rubric dimensions and overlay tags are explicit | source + grep gate | `test -f .planning/phases/187-audit-baseline/187-RUBRIC.md && grep -q "11 interaction-integrity" .planning/phases/187-audit-baseline/187-RUBRIC.md && grep -q "12 microcopy" .planning/phases/187-audit-baseline/187-RUBRIC.md` | planned | pending |
| 187-01-T2 | 187-01 | 1 | VER-01 | T-187-01, T-187-04 | Schemas require canonical baseline, targeted breakpoint, and defect fields | Node parse | `node -e 'const fs=require("fs"); const base=JSON.parse(fs.readFileSync(".planning/phases/187-audit-baseline/schemas/baseline-cell.schema.json","utf8")); const defect=JSON.parse(fs.readFileSync(".planning/phases/187-audit-baseline/schemas/defect.schema.json","utf8")); if (!base.required.includes("coverage_status")) throw new Error("missing coverage_status"); if (!base.required.includes("viewport_width")) throw new Error("missing viewport_width"); if (!base.properties.mode.enum.includes("targeted")) throw new Error("missing targeted mode"); const text=JSON.stringify(base); for (const token of ["targeted_label","breakpoint","targeted-320","targeted-1440"]) if (!text.includes(token)) throw new Error("missing targeted token "+token); if (!defect.required.includes("owner_phase")) throw new Error("missing owner_phase");'` | planned | pending |
| 187-02-T1 | 187-02 | 2 | VER-01 | T-187-04 | Manifest exports dimensions, states, overlays, and surfaces | Node require | `node -e 'const m=require("./accrue_admin/e2e/baseline-manifest.js"); for (const k of ["DIMENSIONS","STATE_TAXONOMY","OVERLAY_TAGS","PROJECTS","THEMES","SURFACES"]) if (!m[k]) throw new Error("missing export "+k);'` | planned | pending |
| 187-02-T2 | 187-02 | 2 | VER-01 | T-187-01, T-187-04 | Artifact generator parses canonical JSON/NDJSON and classifies harness failures separately from UI findings | npm script + Node parse | `cd accrue_admin && npm run baseline:artifacts -- --dry-run && npm run baseline:parse` | planned | pending |
| 187-02-T3 | 187-02 | 2 | VER-01 | T-187-05 | Optional vision scorer handles missing credentials cleanly | Node script + grep gate | `cd accrue_admin && node e2e/score-visuals.mjs >/tmp/score-visuals-no-key.log && grep -q "ANTHROPIC_API_KEY not set" /tmp/score-visuals-no-key.log` | planned | pending |
| 187-03-T1 | 187-03 | 3 | VER-01 | T-187-03, T-187-04 | Static baseline writes evidence without committing generated binaries | Playwright E2E | `cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --project=chromium-desktop -x` | planned | pending |
| 187-03-T2 | 187-03 | 3 | VER-01 | T-187-03 | Targeted breakpoint probes are risk-gated and schema-valid | source assertion + Playwright E2E + parser | `node -e "const fs=require('fs'); const src=fs.readFileSync('accrue_admin/e2e/admin-baseline.spec.js','utf8'); for (const token of ['320','1440','viewport_width','breakpoint','targeted_label']) if (!src.includes(token)) throw new Error('missing targeted token '+token); if (src.includes('mode: \"targeted-') || src.includes('mode = \"targeted-') || src.includes(\"mode: 'targeted-\") || src.includes(\"mode = 'targeted-\")) throw new Error('legacy targeted mode');" && cd accrue_admin && npm run e2e -- e2e/admin-baseline.spec.js --project=chromium-mobile -x && npm run baseline:artifacts -- --dry-run && npm run baseline:parse` | planned | pending |
| 187-04-T1 | 187-04 | 3 | VER-01 | T-187-02 | Permission-denied route remains E2E-only | grep + ExUnit | `grep -q "e2e_member" accrue_admin/test/support/e2e_auth_adapter.ex && grep -q "login-member" accrue_admin/test/support/e2e_plug.ex && cd accrue_admin && mix test --warnings-as-errors test/accrue_admin` | planned | pending |
| 187-04-T2 | 187-04 | 3 | VER-01 | T-187-03, T-187-05 | Live interaction observations cover D-13/D-14 plus StepUpAuthModal with trace-backed evidence | source assertion + Playwright E2E + NDJSON parse | `cd accrue_admin && npm run e2e -- e2e/admin-interactions.spec.js --project=chromium-desktop -x` plus Plan 04 source/NDJSON assertions, including `#accrue-admin-step-up-dialog` and `step-up-auth-modal` | planned | pending |
| 187-05-T1 | 187-05 | 4 | VER-01 | T-187-01, T-187-03, T-187-04, T-187-05 | Audit execution always reaches artifact generation unless harness/parser/runtime failure prevents evidence | non-aborting audit wrapper + parse | Plan 05 Task 1 `<automated>` command | planned | pending |
| 187-05-T2 | 187-05 | 4 | VER-01 | T-187-01, T-187-04 | Canonical baseline and defect ledger parse and route owner phases | Node parse + grep gate | Plan 05 Task 2 `<automated>` command | planned | pending |

*Status: pending, green, red, flaky*

---

## Wave Structure

| Wave | Plans | Validation Focus |
|------|-------|------------------|
| 1 | 187-01 | Rubric, overlay tags, severity/owner routing, and schemas exist before harness work. |
| 2 | 187-02 | Manifest, artifact generator, scorer, and package scripts create the data pipeline. |
| 3 | 187-03, 187-04 | Static evidence and live interaction evidence run independently from the shared manifest. |
| 4 | 187-05 | Audit execution reaches committed baseline artifacts and parses canonical outputs. |

## Wave 0 Status

No separate Wave 0 scaffold remains. The previous placeholders are covered by task-level automated verification in Plans 01-05:

- `accrue_admin/e2e/baseline-manifest.js` - Plan 02 Task 1.
- `accrue_admin/e2e/admin-baseline.spec.js` - Plan 03 Tasks 1-2.
- `accrue_admin/e2e/admin-interactions.spec.js` - Plan 04 Task 2.
- Artifact generator script and canonical outputs - Plan 02 Task 2 and Plan 05 Tasks 1-2.
- `accrue_admin/e2e/score-visuals.mjs` 12-dimension support - Plan 02 Task 3.
- Permission-denied and disconnected/reconnecting reachability - Plan 04 Tasks 1-2; remaining unreachable cells become explicit `gap` / `n/a` observations.

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

- [x] All tasks have `<automated>` verify commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 placeholders removed and mapped to concrete plan tasks
- [x] No watch-mode flags
- [x] Feedback latency set to one task
- [x] `nyquist_compliant: true` set in frontmatter after plans map tasks to this strategy

**Approval:** ready for execution
