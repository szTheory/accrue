---
phase: 179
slug: f-screenshot-driven-visual-qa-loop-sign-off
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 179 — Validation Strategy

> Per-phase validation contract for the screenshot QA loop & sign-off. From RESEARCH.md `## Validation Architecture`. Explicitly separates what is autonomously testable from the human/CI photographic gate.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (e2e) + ExUnit (regression) + Node (scoring script) |
| **Config** | `accrue_admin/playwright.config.js` (chromium-desktop 1280×900 + chromium-mobile Pixel5 projects already defined) |
| **axe run** | `cd accrue_admin && npm run e2e:a11y` |
| **visual capture** | `cd accrue_admin && npm run e2e:visuals:png-only` (needs live server) |
| **scoring** | `cd accrue_admin && npm run score-visuals` (needs ANTHROPIC_API_KEY; no-ops without) |
| **regression** | `cd accrue_admin && mix test --seed 0` (262 green) |

---

## Sampling Rate

- **After each task commit:** spec files parse (`npx playwright test --list`); scoring script lints/no-ops without key; `mix test` for any remediation
- **After the wave:** full admin suite green; axe spec green (if server up); SIGN-OFF scaffold present
- **Before milestone sign-off (HUMAN/CI gate):** full photographic sweep (4 cells × 21 screens) + vision scoring all ≥2 + axe both themes 0 critical/serious + motion trace reviewed
- **Max feedback latency:** ~60s (autonomous portion)

---

## Per-Task Verification Map

| Area | Requirement | Test Type | What it proves | Automated Command |
|------|-------------|-----------|----------------|-------------------|
| Sweep expanded to 21 screens × 4 cells | QA-01 | spec list/parse | shots[] has 21 entries; both projects iterate; fixtures resolve detail ids | `npx playwright test e2e/admin-visuals.spec.js --list` |
| LLM scoring script structure + no-op-without-key | QA-02 | node run | script parses; exits 0 (skip) when ANTHROPIC_API_KEY unset; emits findings JSON schema when keyed | `node e2e/score-visuals.mjs` (no key → graceful skip) |
| Findings schema {screen,viewport,theme,dimension,score,defect,suggested_fix} | QA-02 | unit/schema | scoring output validates against the schema | schema assertion / sample fixture |
| axe full inventory both themes, mobile | QA-03 | Playwright+axe | 0 critical/serious in light+dark across inventory | `npm run e2e:a11y` (needs server) |
| Motion trace capture (drawer/palette/dropdown/nav) | QA-03 | Playwright trace | trace artifact produced for motion surfaces | `npx playwright test e2e/admin-motion-trace.spec.js --list` |
| SIGN-OFF.md scaffold aggregates 176/177/178 + axe + shots | QA-03 | source assertion | SIGN-OFF.md present with before(176)/after columns + evidence sections | `test -f` + grep section headers |
| Regression | all | full suite | 262 admin tests stay green | `cd accrue_admin && mix test --seed 0` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Confirm exact `data-role`/trigger selectors for the detail-drawer trigger + command-palette trigger (RESEARCH open question — needed before writing admin-motion-trace.spec.js).
- [ ] Confirm `/billing/connect` vs `/billing/connect-accounts` slug and the campaign-detail route from router.ex.
- [ ] Confirm `@anthropic-ai/sdk` (0.100.1) added as a devDependency only; scoring script no-ops without `ANTHROPIC_API_KEY`.
- [ ] Confirm the 3-fixture sweep (operator-flows + dashboard + edge-states) returns all detail ids needed for the 21 shots.

*Playwright + ExUnit infra exists; only the @anthropic-ai/sdk devDependency is new (e2e-only).*

---

## Manual-Only Verifications (the consolidated HUMAN/CI photographic gate)

| Behavior | Requirement | Why Manual/CI | Test Instructions |
|----------|-------------|---------------|-------------------|
| Full 4-cell photographic sweep captured | QA-01 | needs live host server + Chromium | `npm run e2e:visuals:png-only` against a running server |
| Vision-LLM scoring: every dim ≥2 across all 4 cells | QA-02 | needs ANTHROPIC_API_KEY + the captured PNGs | `ANTHROPIC_API_KEY=... npm run score-visuals` → review findings |
| Remediation loop until nothing <2 | QA-02 | depends on scoring output | iterate fix→reshoot→rescore (≤3 rounds) |
| Final SIGN-OFF scorecard human review | QA-03 | milestone "done" judgment | review SIGN-OFF.md scorecard + before/after evidence |
| Motion trace reviewed (177 deferred) | QA-03 | watching the trace/video | open the Playwright trace for the motion surfaces |
| Closes deferred 175–178 visual UATs | — | the consolidation gate | confirm each phase's *-HUMAN-UAT pending items pass |

*This phase ships the runnable system + scaffold; the photographic sign-off RUN is the gate above.*

---

## Validation Sign-Off

- [ ] All build tasks have `<automated>` verify (spec parse, scoring no-op, scaffold present) or Wave 0 dependencies
- [ ] axe spec extended + green where runnable
- [ ] scoring script no-ops cleanly without a key (CI-safe)
- [ ] SIGN-OFF.md scaffold present aggregating prior-phase evidence
- [ ] full suite green (262)
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] (HUMAN/CI) photographic sweep + vision scoring all ≥2 + axe both themes — the milestone sign-off run

**Approval:** pending
