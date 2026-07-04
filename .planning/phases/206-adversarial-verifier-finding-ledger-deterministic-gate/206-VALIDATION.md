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

> Populated by the planner/executor once task IDs exist. Every deterministic-plane task MUST map to a
> `--self-test` assertion. The three regression kinds below are the Nyquist critical samples.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | LEDGER-04/05 | — | count-increase per lens → regression row | self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LEDGER-03/05 | — | missing/deleted minted guard → regression row | self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LEDGER-05 | — | reopened locked claim w/o marker → regression row | self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LEDGER-04 | — | hand-edited baseline disagreeing w/ raw rows → CI verifier fails | self-test | `node scripts/ci/verify_ratchet_ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | LEDGER-01/03 | — | clean ledger → `finding-regressions.ndjson` 0 bytes | self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | DEDUP-03 | — | multi-lens collapse → one item, `persona_frequency`+union `raised_by_lenses` | self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | VERIFY-01/02 | — | median-then-clamp over synthetic vote arrays (2-of-3, downgrade-only) | self-test | `node e2e/ratchet/ratchet-verify.mjs --self-test` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | VERIFY-03 | — | confirmed verdict w/o admissible token dropped before ledger | self-test | `node e2e/ratchet/ratchet-verify.mjs --self-test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

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
