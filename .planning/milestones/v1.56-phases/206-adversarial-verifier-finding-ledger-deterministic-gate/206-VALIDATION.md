---
phase: 206
slug: adversarial-verifier-finding-ledger-deterministic-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-04
---

# Phase 206 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 206-RESEARCH.md `## Validation Architecture`. The gate/verifier plane is proven on
> synthetic `--self-test` fixtures, NEVER the live LLM (D-37 / phase200 precedent).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node.js built-in `--self-test` blocks (mkdtemp fixtures), twinning `phase200-scorecard.mjs runSelfTest()`; no new test package |
| **Config file** | none — self-test is invoked via `node <script>.mjs --self-test` and `npm run ratchet:*` in `accrue_admin/package.json` |
| **Quick run command** | `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` |
| **Full suite command** | `cd accrue_admin && npm run ratchet:ledger -- --self-test && node ../scripts/ci/verify_ratchet_ledger.mjs --self-test && node e2e/ratchet/region-tags.js --self-test` |
| **Estimated runtime** | ~5 seconds (pure deterministic; no browser, no API) |

---

## Sampling Rate

- **After every task commit:** Run the relevant `--self-test` for the file touched
- **After every plan wave:** Run the full suite command
- **Before `/gsd-verify-work`:** Full suite must be green AND both `--self-test` blocks pass
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

> Mapped to the finalized 4-plan structure (206-01..04). Every deterministic-plane task carries an
> `<automated>` `--self-test` assertion. The three regression kinds are the Nyquist critical samples.
> `File Exists` = ❌ W0 means the target artifact is created by this phase (Wave-0 fixture / new file).

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|--------|
| 206-01 T1 | 01 | 1 | DEDUP-03 | multi-lens collapse → one item, `persona_frequency` = distinct `raised_by_lenses` count | self-test | `node accrue_admin/e2e/ratchet/ratchet-ledger.js` | ⬜ pending |
| 206-01 T2 | 01 | 1 | DEDUP-03/LEDGER-01 | append/fold helper; out-of-order `seq` throws (tamper-evidence) | self-test | `node accrue_admin/e2e/ratchet/ratchet-ledger.js` | ⬜ pending |
| 206-02 T1 | 02 | 2 | VERIFY-01/02/03, LEDGER-01 | median-then-clamp (downgrade-only) + token re-gate + LLM-identity never trusted | self-test | `ANTHROPIC_API_KEY= node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test` | ⬜ pending |
| 206-02 T2 | 02 | 2 | VERIFY-03, LEDGER-01 | sole `open`-row writer; `--self-test` never mutates real ledger; npm wiring | self-test | `node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test` | ⬜ pending |
| 206-03 T1 | 03 | 2 | LEDGER-02 | per-lens (7-enum) `confirmed_open` compare, `fold()` reducer | self-test | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ⬜ pending |
| 206-03 T2 | 03 | 2 | LEDGER-03 | count-increase / guard-missing / illegal-reopen each → 1 regression row | self-test | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ⬜ pending |
| 206-03 T3 | 03 | 2 | LEDGER-05 | clean ledger → `finding-regressions.ndjson` 0 bytes; `--freeze` refusal | self-test | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ⬜ pending |
| 206-04 T1 | 04 | 3 | LEDGER-04 | independent recompute-from-raw-rows; hand-edited baseline disagreement fails | self-test | `node scripts/ci/verify_ratchet_ledger.mjs` | ⬜ pending |
| 206-04 T2 | 04 | 3 | LEDGER-04/05 | verifier `--self-test` fixtures + `ratchet:ledger:self-test` npm pair | self-test | `cd accrue_admin && npm run ratchet:ledger:self-test` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Flip to ✅ during execution as each `--self-test` goes green; set `nyquist_compliant: true` once all rows are ✅.*

---

## Wave 0 Requirements

- [ ] Synthetic ledger fixtures (mkdtemp) for the 3 regression kinds — the live `candidates.ndjson`
      sample has no naturally-colliding `finding_id`s, so DEDUP-03 collapse needs synthetic input.
- [ ] Synthetic vote-array fixtures for the median-clamp truth table (VERIFY-01).
- [ ] `--self-test` harness twinned from `phase200-scorecard.mjs runSelfTest()` (mkdtemp pattern).

*Existing `region-tags.js runSelfTest()` covers identity/token re-validation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Density-defender *voting bias* against `direction:"air"` | VERIFY-02 | The prompt-following behavior of the live Opus panel cannot be proven by `--self-test`; only the deterministic median-clamp math over synthetic votes is fixture-provable | Reviewed at 208 convergence via committed ledger `panel_votes`; not a 206 gate |

*The deterministic half of every requirement has automated `--self-test` verification.*

---

## Validation Sign-Off

- [ ] All deterministic-plane tasks map to a `--self-test` assertion or Wave 0 fixture dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all synthetic-fixture MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
