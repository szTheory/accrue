---
phase: 205
slug: persona-design-lens-evaluator-harness
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-03
finalized: 2026-07-03
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

> Finalized against the produced plans (205-01..205-05). Every identity/determinism task maps to a pure, key-free `<automated>` verify (no live API, no watch-mode). Live-model behavior (persona/design-lens prose) is a maintainer live-smoke step, not an automated gate — the LLM never gates CI (EVAL-03/SC#3). No 3-consecutive-task gap: every task below carries an automated verify.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 205-01 T1 | 01 | 1 | DEDUP-01, DEDUP-02 | T-205-02 (identity leak) | closed-enum `claimKey`/`findingId`/normalizers throw on out-of-enum; identity is prose-independent | unit | `node -e "…region-tags.js…claimKey(…)…normalizeOverlays(['nope']) throws"` | ❌ W0 (Plan 01) | ⬜ pending |
| 205-01 T2 | 01 | 1 | DEDUP-02 | T-205-02 (identity leak) | 7 DEDUP-02 assertion classes: idempotence · prose-independence · overlay order/dup invariance · empty-normalization · intended-distinctness negatives · closed-enum-throws · golden-hash snapshot; + byte-identical `slug` parity | unit (self-test) | `node accrue_admin/e2e/ratchet/region-tags.js` | ❌ W0 (Plan 01) | ⬜ pending |
| 205-02 T1 | 02 | 1 | EVAL-04 | — | 5 exemplar PNGs each under 5 MB base64 (per-image guard parity) | unit (fixture) | `node -e "…exemplars/*.png base64 ≤ 5 MB…"` | ❌ (Plan 02) | ⬜ pending |
| 205-02 T2 | 02 | 1 | EVAL-02 | — | rubric anchored to brandbook + tier anchors (Linear/Oban); provenance JSON present | unit (fixture) | `node -e "…DESIGN-LENS-RUBRIC.md + exemplars/PROVENANCE.json…"` | ❌ (Plan 02) | ⬜ pending |
| 205-03 T1 | 03 | 2 | EVAL-03, DEDUP-01, DEDUP-02 | T-205-01 (prompt-injection), T-205-03 (DoS) | self-test-first / no-key `exit 0` before any SDK import; 5 MB per-image guard preserved | smoke + unit | `node …ratchet-propose.mjs --self-test && env -u ANTHROPIC_API_KEY node …ratchet-propose.mjs && echo no-key-ok` | ❌ W0 (Plan 03) | ⬜ pending |
| 205-03 T2 | 03 | 2 | EVAL-01 | T-205-01 (prompt-injection) | untrusted-screenshot-text preamble on every call; forced tool-use; parse reads `tool_use.input.findings`, never `content[0].text` | unit (self-test + static) | `node …--self-test && node --check … && node -e "…assert tool_use parse + preamble…"` | ❌ W0 (Plan 03) | ⬜ pending |
| 205-03 T3 | 03 | 2 | EVAL-05, DEDUP-01, DEDUP-02 | T-205-02 (identity leak) | every identity field harness-re-derived (model `claim_key`/`finding_id` ignored); token-gate + taste denylist drop pre-emit; N=12/image cap | unit (self-test + static) | `node …--self-test && node -e "…assert claimKey/findingId/isAdmissibleToken/cellId/ratchet-candidate/1/persona_frequency…"` | ❌ W0 (Plan 03) | ⬜ pending |
| 205-04 T1 | 04 | 3 | EVAL-02 | — | comparative design lens + archetype-matched exemplar attach (keyed off `surface_type`) | unit (self-test + static) | `node …--self-test && node --check … && node -e "…assert design/exemplar/direction…"` | ❌ (Plan 04) | ⬜ pending |
| 205-04 T2 | 04 | 3 | EVAL-02 | T-205-02 (identity leak) | design candidates flow the SHARED harness identity gate (`lens_kind: design`, `exemplar_ref`) | unit (self-test + static) | `node …--self-test && node -e "…assert lens_kind design + exemplar_ref…"` | ❌ (Plan 04) | ⬜ pending |
| 205-05 T1 | 05 | 2 | EVAL-05 | — | capture-time `.bbox.json` from `REGION_SELECTORS`; null-box fallback for absent selector (non-fatal, D-09) | unit (static) | `node --check …admin-visuals.spec.js && node -e "…assert bbox/boundingBox/region-tags…"` | ❌ (Plan 05) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*"File Exists ❌ W0" = the Wave-0 scaffolding (`region-tags.js` + `ratchet-propose.mjs` guards/self-test) is front-loaded in Plan 01/03 and written at first execution; the verify commands are Nyquist-valid as planned.*

---

## Wave 0 Requirements

> All three are covered by produced plans and front-loaded to the earliest waves (Plan 01 = wave 1, Plan 03 = wave 2). `wave_0_complete: false` because the files are written at first execution, not at plan-finalization; there are no un-planned MISSING references.

- [ ] `accrue_admin/e2e/ratchet/region-tags.js` — closed-enum SSOT (REGION_TAGS, subset map, synonym table, `claimKey()`/`findingId()`); byte-identical `slug()` reimpl (NOT exported from `baseline-manifest.js` — RESEARCH finding) → **Plan 01 Task 1**
- [ ] `--self-test` fixture block — the 7 DEDUP-02 assertion classes + golden-hash snapshot (twin `phase200-scorecard.mjs` `runSelfTest()`/`sha256()`) → **Plan 01 Task 2** (`runSelfTest()` in `region-tags.js`), consumed by `ratchet-propose.mjs --self-test` in **Plan 03 Task 1**
- [ ] no-key `exit 0` guard as FIRST executable statement (before any SDK import) — EVAL-03/SC#3 smoke → **Plan 03 Task 1**

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies — all 10 tasks across 205-01..205-05 carry a key-free `<automated>` verify (see map above)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify — every task has one
- [x] Wave 0 covers all MISSING references — `region-tags.js` (Plan 01) + `ratchet-propose.mjs` guards/self-test (Plan 03); no un-planned MISSING refs
- [x] No watch-mode flags — all verifies are one-shot `node`/`node --check`/`node -e`
- [x] Feedback latency < 5s — pure fixtures, ~2 s self-test
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** finalized 2026-07-03 — Nyquist-compliant as planned; Wave-0 scaffolding builds at first execution.
