# Requirements: Accrue — Milestone v1.56 Admin UI Ratchet

**Defined:** 2026-07-03
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI and launch a real SaaS with subscription billing on day one — complete, production-grade, idiomatic Elixir DX. This milestone raises the `accrue_admin` operator UI to award-winning, on-brand graphic design via an automated, forward-only evaluation ratchet.

**Milestone goal:** Build a maintainer-run "UI Ratchet" that automates UI/UX evaluation and iteration — fan-out adversarial evaluation (6 operator personas + a graphic-design lens) → dedup → adversarial verify → batch-fix at root → re-score → loop-until-dry — where the maintainer only batch-approves and signs off, the LLM never gates, and the UI can only move forward. Prove it end-to-end on a representative slice; tee up the full-surface sweep as safe follow-on.

**Authoritative design source:** `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md` (approved 2026-07-03).

**Scope guardrails (binding):** `accrue_admin` + dev/test-only tooling only. No new billing primitives, no breaking API/route changes, no Tailwind migration, `ax-*` stays the styling SSOT, core `accrue` stays LiveView-runtime-free, no `accrue_portal` work, ratchet tooling never leaks into adopter runtime. LLM runs locally (maintainer's key); CI gates the deterministic layer only.

---

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase (205–208).

### Evaluator Harness (EVAL)

- [x] **EVAL-01**: Maintainer can run a local evaluator pass that reads each admin surface's committed screenshots and produces candidate findings for all 6 operator personas, each prompted with its job + entry point (Operator/Founder, Customer Support, Finance/Billing Ops, Recovery/Growth Ops, Developer/Integration, Compliance/Audit).
- [x] **EVAL-02**: Maintainer can run a graphic-design evaluator lens that assesses the design dimensions (hierarchy, spacing-rhythm, responsive, brand-expression; token + contrast supporting) comparatively against named quiet-dev-tooling tier exemplars rather than emitting an absolute "award" score.
- [x] **EVAL-03**: The evaluator harness exits cleanly (exit 0, no failure) when `ANTHROPIC_API_KEY` is absent and enforces the existing per-image size guard, so it is safe to invoke anywhere.
- [x] **EVAL-04**: A committed design sub-rubric plus a curated good/bad exemplar set (sourced from repo history, license-clean) anchors the design lens to the locked brand DNA ("quiet polish, well-made dev tooling, not fintech").
- [x] **EVAL-05**: Each candidate finding records surface, rubric dimension, region tag, overlay tags, severity, and the persona/lens that raised it, plus `cell_refs` pointing into the existing 30,348-cell grammar.

### Dedup & Stable Identity (DEDUP)

- [x] **DEDUP-01**: Each finding is assigned a canonical claim-key derived from surface + dimension + sorted overlay-tags + region (the LLM free-text is stored for humans but excluded from identity), so the same defect yields the same `finding_id` across runs.
- [x] **DEDUP-02**: Running the proposer twice on unchanged screenshots yields an identical `finding_id` set (prose-independence / non-flakiness), proven by an automated test.
- [x] **DEDUP-03**: Findings raised independently by multiple personas/lenses collapse into a single work item carrying a `persona_frequency` count.

### Adversarial Verification (VERIFY)

- [x] **VERIFY-01**: Each candidate finding is judged by a 3-role adversarial skeptic panel (persona advocate, brand purist, operator-density defender) and is dropped unless at least 2 of 3 confirm it is a real defect.
- [x] **VERIFY-02**: The operator-density-defender role refutes any finding whose fix would reduce operator information density or add marketing-style whitespace without a concrete task-completion justification (anti-over-whitespacing guard).
- [x] **VERIFY-03**: A candidate cannot enter the ledger unless it cites an admissible justification token (`rubric-dim-below-bar` | `persona-job-miss:<job>` | `token-bypass`); a "looks nicer / my taste" claim is rejected before any human sees it.

### Forward-Only Finding Ledger & Gate (LEDGER)

- [x] **LEDGER-01**: Confirmed findings persist to a committed finding ledger with an explicit lifecycle (`open → resolved → verified-closed`, or `suppressed` with a reason) and foreign-key `cell_refs` into the existing cell grammar.
- [x] **LEDGER-02**: A committed high-water baseline records `confirmed_open` counts per lens and the `resolved_locked` claim-key set.
- [x] **LEDGER-03**: A deterministic sibling gate emits a regression row when any lens's open count exceeds baseline, when a `resolved` finding's minted guard is missing/deleted, or when a `resolved_locked` claim reopens without an explicit maintainer reopen marker.
- [x] **LEDGER-04**: The gate passes only when `finding-regressions.ndjson` is 0 bytes, and is independently re-verified by a CI script that recomputes counts from raw ledger rows (a hand-edited baseline that disagrees fails).
- [x] **LEDGER-05**: The gate reducer and its verifier each pass a `--self-test` proving that count-increase, missing-guard, and reopened-locked-claim each produce a regression row while a clean ledger produces zero.

### Orchestration & Maintainer Loop (ORCH)

- [ ] **ORCH-01**: Maintainer can run a single command (`mix accrue_admin.ui.round`) that builds assets, boots the admin, seeds, captures, fans out evaluators, dedups, verifies, ranks, and renders a digest.
- [ ] **ORCH-02**: The digest is a rendered HTML gallery grouping screenshots by surface with confirmed findings overlaid on their region, a ranked worklist, and a separate "decisions needed" queue for IA/product-decision items.
- [ ] **ORCH-03**: Maintainer can batch-approve all auto-fixable confirmed findings in one action, or reject an individual finding into a suppress-list with a reason that feeds dedup so it never resurfaces.
- [ ] **ORCH-04**: Maintainer can run a single command (`mix accrue_admin.ui.fix`) that applies the approved batch, rebuilds and commits the CSS bundle, re-captures, re-scores, and updates the ledger.
- [ ] **ORCH-05**: Resolving a finding auto-mints a deterministic guard (a targeted assertion in an existing spec, or a `ledger-count` guard for pure-taste findings) so a closed finding cannot silently reopen.
- [x] **ORCH-06**: The loop detects convergence after K=2 consecutive dry rounds and escalates to the maintainer at a 6-round hard cap instead of looping indefinitely.
- [x] **ORCH-07**: The evaluator fan-out applies Anthropic prompt caching (`cache_control`) to the stable per-call prefix (system preamble, tool schema, and the design-lens exemplar images) so repeated `ui.round` runs reuse cached input instead of re-sending it, cutting per-run token cost, without altering identity (`claim_key`/`finding_id`) or the no-key/`--self-test` paths. *(Folded 2026-07-03 from the Phase 205 live smoke — the proposer currently sends no `cache_control` and re-sends the schema + images on all 7 calls/screenshot.)*
- [x] **ORCH-08**: `mix accrue_admin.ui.round` and the underlying proposer accept a surface/slice filter so a maintainer can scope a run to a bounded subset (the representative slice or a single surface) without manually pruning captured PNGs; capture and fan-out both honor the filter, and an unscoped run still covers the full configured surface set. *(Folded 2026-07-03 from the Phase 205 live smoke — there is currently no subset filter, so a slice run requires hand-pruning `test-results/`.)*

### Convergence Proof, CI & Sign-off (CONV)

- [ ] **CONV-01**: The ratchet is run to convergence on the representative slice (design-system foundation + a few component families, plus dashboard, subscription-detail, and subscriptions-list) with every slice cell scoring ≥ 2 and both `regressions.ndjson` and `finding-regressions.ndjson` empty.
- [ ] **CONV-02**: The first non-empty ledger baseline is frozen as the slice high-water mark.
- [ ] **CONV-03**: A new deterministic-only CI job (`admin-ui-ratchet-guardrails`) passes on a PR with no `ANTHROPIC_API_KEY` and blocks on a synthetic ledger count-increase.
- [ ] **CONV-04**: A change that improves one persona but regresses another is caught by the ledger (the regressed lens's open count rises → gate red), proven by an automated test.
- [ ] **CONV-05**: Existing UI gates (`admin-hardening-guardrails`, `admin-phase200-guardrails`, asset-drift) remain green and the committed `accrue_admin.css` bundle stays fresh.
- [ ] **CONV-06**: A `UI-RATCHET-SIGN-OFF.md` carries the maintainer `ACCEPT` line, enforced by a sign-off verifier mirroring the Phase 200 pattern.
- [ ] **CONV-07**: A documented runbook enables graduating any remaining admin surface under the ratchet as a safe follow-on round (tees up the full sweep).

## Future Requirements

Deferred; tracked but not in the current roadmap's committed scope.

### Full-Surface Sweep (SWEEP)

- **SWEEP-01**: The remaining ~19 admin surfaces are graduated round-by-round to 2 dry rounds each under the ratchet, with no regressions. (Scope-gated Phase 209 — execution teed up as safe follow-on; not required for v1.56 sign-off per the confirmed maintainer decision.)

### Advisory LLM in CI (CIADV)

- **CIADV-01**: CI optionally runs the evaluators as a non-gating advisory signal (uploaded as evidence, never blocks merge). Deferred: the confirmed decision is local-run only for v1.56.

## Out of Scope

Explicitly excluded to prevent scope creep.

| Feature | Reason |
|---------|--------|
| LLM as a hard CI merge gate | Non-deterministic scores would cause flaky false regressions; v1.54 deliberately rejected LLM-as-gate. The LLM is a proposer/ranker only. |
| A 13th "award" rubric dimension | Would fork the frozen cell grammar and the `DIMENSIONS` map across four files; the design lens sharpens existing dims 2/3/5/8 instead. |
| Tailwind migration | Locked out since v1.51; `ax-*` custom CSS stays the SSOT. |
| New billing primitives / API / route changes | Milestone is UI-evaluation tooling + admin polish only, under the stable-core posture. |
| `accrue_portal` work | Out of the admin surface; portal parity readiness is a separate deferred slice. |
| Pixel-diff visual-regression service (Percy/Applitools) | Deferred as TOOL-02 since v1.53; the scored-cell + finding-ledger ratchet is the regression mechanism. |
| Converging all ~23 surfaces this milestone | Confirmed maintainer decision: prove on the slice, tee up the sweep (SWEEP-01) as safe follow-on. |
| Ratchet tooling in adopter runtime | All new code is dev/test-only (`e2e/ratchet/`, `scripts/ci/`, `mix accrue_admin.ui.*`); never shipped to host apps. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVAL-01 | Phase 205 | Complete |
| EVAL-02 | Phase 205 | Complete |
| EVAL-03 | Phase 205 | Complete |
| EVAL-04 | Phase 205 | Complete |
| EVAL-05 | Phase 205 | Complete |
| DEDUP-01 | Phase 205 | Complete |
| DEDUP-02 | Phase 205 | Complete |
| DEDUP-03 | Phase 206 | Complete |
| VERIFY-01 | Phase 206 | Complete |
| VERIFY-02 | Phase 206 | Complete |
| VERIFY-03 | Phase 206 | Complete |
| LEDGER-01 | Phase 206 | Complete |
| LEDGER-02 | Phase 206 | Complete |
| LEDGER-03 | Phase 206 | Complete |
| LEDGER-04 | Phase 206 | Complete |
| LEDGER-05 | Phase 206 | Complete |
| ORCH-01 | Phase 207 | Pending |
| ORCH-02 | Phase 207 | Pending |
| ORCH-03 | Phase 207 | Pending |
| ORCH-04 | Phase 207 | Pending |
| ORCH-05 | Phase 207 | Pending |
| ORCH-06 | Phase 207 | Complete |
| ORCH-07 | Phase 207 | Complete |
| ORCH-08 | Phase 207 | Complete |
| CONV-01 | Phase 208 | Pending |
| CONV-02 | Phase 208 | Pending |
| CONV-03 | Phase 208 | Pending |
| CONV-04 | Phase 208 | Pending |
| CONV-05 | Phase 208 | Pending |
| CONV-06 | Phase 208 | Pending |
| CONV-07 | Phase 208 | Pending |
| SWEEP-01 (deferred) | Phase 209 (scope-gated / optional) | Deferred — not in v1.56 committed set |

**Coverage:**

- v1 requirements: 29 total (EVAL ×5, DEDUP ×3, VERIFY ×3, LEDGER ×5, ORCH ×6, CONV ×7)
- Mapped to phases: **31/31** ✓ — Phase 205 (7: EVAL-01..05, DEDUP-01, DEDUP-02), Phase 206 (9: DEDUP-03, VERIFY-01..03, LEDGER-01..05), Phase 207 (8: ORCH-01..08), Phase 208 (7: CONV-01..07). Each REQ-ID → exactly one phase. *(ORCH-07/08 folded 2026-07-03 from the Phase 205 live smoke — cost/DX enhancements to the proposer, addressed by Phase 207; the original ratified set was 29.)*
- Unmapped: none ✓
- Deferred (not counted in v1): SWEEP-01 → Phase 209 (scope-gated / optional, not required for v1.56 sign-off); CIADV-01 (local-run-only decision; no phase).

---
*Requirements defined: 2026-07-03*
*Last updated: 2026-07-03 after milestone v1.56 initialization*
