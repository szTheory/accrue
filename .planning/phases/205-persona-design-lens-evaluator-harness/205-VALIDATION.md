---
phase: 205
slug: persona-design-lens-evaluator-harness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-03
---

# Phase 205 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js (`node --test` / bespoke `--self-test` in-file harness, twin of `phase200-scorecard.mjs`) |
| **Config file** | none — `accrue_admin/e2e/ratchet/` is dev/test-only; `--self-test` runs with no key, no live model |
| **Quick run command** | `node accrue_admin/e2e/ratchet/ratchet-propose.mjs --self-test` |
| **Full suite command** | `cd accrue_admin && npm run ratchet:propose -- --self-test` (+ no-key `exit 0` smoke) |
| **Estimated runtime** | ~2 seconds (pure fixtures; no API calls) |

---

## Sampling Rate

- **After every task commit:** Run `node accrue_admin/e2e/ratchet/ratchet-propose.mjs --self-test`
- **After every plan wave:** Run the full `--self-test` suite + no-key `exit 0` smoke
- **Before `/gsd-verify-work`:** Full suite green (all 7 DEDUP-02 assertion classes pass, golden-hash snapshot matches)
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

> Populated by the planner during PLAN.md creation. Every identity/determinism task maps to a pure `--self-test` assertion class (no live API). Live-model behavior (persona/design lens output) is a maintainer live-smoke step, not an automated gate — the LLM never gates CI (EVAL-03/SC#3).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | DEDUP-02 | T-205-01 (prompt-injection) | untrusted screenshot text never enters identity/instructions | unit | `node .../ratchet-propose.mjs --self-test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `accrue_admin/e2e/ratchet/region-tags.js` — closed-enum SSOT (REGION_TAGS, subset map, synonym table, `claimKey()`/`findingId()`); byte-identical `slug()` reimpl (NOT exported from `baseline-manifest.js` — RESEARCH finding)
- [ ] `--self-test` fixture block in `ratchet-propose.mjs` — the 7 DEDUP-02 assertion classes + golden-hash snapshot (twin `phase200-scorecard.mjs` `runSelfTest()`/`sha256()`)
- [ ] no-key `exit 0` guard as FIRST executable statement (before any SDK import) — EVAL-05/SC#3 smoke

*Node + Anthropic SDK (0.100.1) + Playwright already installed — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live persona + design-lens findings on real PNGs | EVAL-01/02/04 | Requires `ANTHROPIC_API_KEY` + live model; non-deterministic prose; the LLM never gates CI | Maintainer runs `npm run ratchet:propose` with key set on captured PNGs; inspects `candidates.ndjson` rows for job-anchored defects + design-lens `direction` flag |
| "Run proposer twice → identical `finding_id` set" (SC#5) live-smoke | DEDUP-02 | Confirms the pure `--self-test` proof holds against real model output | Capture unchanged PNGs, run twice, diff the `finding_id` sets (robustified by temp-0 + enum constraints + harness-injected surface) |

*Automated coverage of identity/determinism is complete via `--self-test`; only live-model output is manual by design.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
