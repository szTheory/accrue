---
phase: 184
slug: design-tokens-specimens
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 184 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 184-RESEARCH.md "## Validation Architecture". All tooling is Node `.mjs`
> in the brandbook harness (mirrors `brandbook/logo/harness/`); no Elixir tests.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node `.mjs` scripts + `git diff --exit-code` (no test runner; assertion scripts exit 0/non-zero) |
| **Config file** | `brandbook/tokens/harness/package.json` (committed lockfile; `node_modules` gitignored) |
| **Quick run command** | `node brandbook/tokens/harness/parity-check.mjs` |
| **Full suite command** | regenerate + parity + determinism: `node …/generate-tokens-css.mjs && node …/gen-specimens.mjs && git diff --exit-code -- brandbook/ && node …/parity-check.mjs && node …/parity-check.mjs --test` |
| **Estimated runtime** | ~5–15 seconds (after `npm ci` in harness) |

---

## Sampling Rate

- **After every task commit:** Run the relevant generator + `git diff --exit-code` on its output
- **After every plan wave:** Run the full suite command above
- **Before `/gsd:verify-work`:** Full suite green AND `parity-check.mjs --test` proves drift detection
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

> Filled concretely by the planner against final task IDs. Success-Criterion → check mapping:

| SC | Requirement | What proves it | Test Type | Automated Command |
|----|-------------|----------------|-----------|-------------------|
| SC#1 | TOK-01 | `tokens.json` (DTCG) + generated `tokens.css` exist and define raw palette + semantic roles + reference-only scales; regeneration is reproducible | file-exists + determinism | `node …/generate-tokens-css.mjs && git diff --exit-code -- brandbook/tokens/tokens.css` |
| SC#2 (match) | TOK-02 | parity check exits **0** when every ax-mapped brandbook token matches theme.css (or carries a documented `$extensions` divergence) | behavior (exit code) | `node …/parity-check.mjs` |
| SC#2 (drift) | TOK-02 | parity check exits **non-zero** on injected undocumented drift (live-derivation, no golden file) — the load-bearing test | behavior (exit code) | `node …/parity-check.mjs --test` |
| SC#3 | TOK-03 | three specimen SVGs exist and render every swatch / type step / spacing step; regeneration is reproducible | file-exists + content + determinism | `node …/gen-specimens.mjs && git diff --exit-code -- brandbook/examples/` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `brandbook/tokens/harness/package.json` + `package-lock.json` — pin `postcss`, `postcss-value-parser`, `culori` (single shared harness install per D-16; gate `npm install` behind a `checkpoint:human-verify` task per research package-legitimacy note)
- [ ] `.gitignore` covers the new harness `node_modules`
- [ ] CI wiring mirrors `accrue_admin_assets.yml` / `ci.yml` determinism-gate shape (npm ci → regenerate → `git diff --exit-code` → parity-check → parity-check --test)

*Existing `brandbook/logo/harness/` is the convention template.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Specimen visual fidelity (swatches legible, AA-fail flags correct, dark surface readable) | TOK-03 | SVG visual correctness is not assertable by exit code | Open `brandbook/examples/*.svg` in a browser; confirm Moss/Cobalt/Amber are flagged AA-FAIL on light body per `contrast-table.txt` |
| `code-block` / `callout` brand hex values (new this phase, no upstream) | TOK-01 | Author judgment — derived from Fog/Slate/Ink family | Ratify chosen hexes at PR review |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers harness install + CI wiring
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter (after planner fills task IDs)

**Approval:** pending
