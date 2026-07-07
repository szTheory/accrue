---
phase: 207-orchestration-digest-one-command-round-fix-loop
verified: 2026-07-07T12:42:16Z
status: human_needed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/7
  gaps_closed:
    - "CR-01: digest accepts suggested_fix:null, renders no literal null/undefined, and preserves required-field strictness"
    - "CR-02: incomplete concrete guard probe data degrades to ledger-count and does not mutate guard-home specs"
    - "WR-02: mix accrue_admin.ui.fix git commit is scoped with -- priv/static"
    - "Post-review CR: applyDecisions() preflights ledger state before any append, preventing partial mutation on later invalid decisions"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "ORCH-07 live cache-cost smoke"
    expected: "Run the proposer twice with ANTHROPIC_API_KEY against unchanged PNGs; the second run reports non-zero usage.cache_read_input_tokens while claim_key/finding_id identity remains stable."
    why_human: "Requires a live Anthropic API key and network. Automated self-tests verify the request shape and no-key path, not measured provider cache hits."
  - test: "ORCH-08 live capture filter"
    expected: "Run RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js inside accrue_admin/ with the e2e server available; only dashboard PNGs are written for both desktop/mobile and light/dark captures."
    why_human: "Requires the Phoenix e2e server and Playwright browser capture output. Automated checks verify the filter predicate and env threading."
---

# Phase 207: Orchestration + digest + one-command round/fix loop Verification Report

**Phase Goal:** The whole pipeline is driven by two `mix` commands with a rendered digest and minimal maintainer checkpoints, resolutions auto-mint deterministic guards, and the loop provably terminates.
**Verified:** 2026-07-07T12:42:16Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| SC1 | `mix accrue_admin.ui.round` drives the measurement pipeline and renders digest in one command | VERIFIED | `accrue_admin.ui.round.ex` sequences next-round, assets.build, capture, propose, verify, seal-round, digest; digest runs before cap-reached raise. Focused ExUnit passed. CR-01 no longer blocks digest. |
| SC2 | Digest renders HTML gallery with worklist, decisions-needed queue, overlays, strict safe rendering | VERIFIED | `ratchet-digest.mjs --self-test` passes banner, sorting, XSS, overlay-scale, decisions contract, and CR-01 null optional field fixtures. |
| SC3 | Maintainer can batch-approve or reject with suppression reason feeding dedup | VERIFIED | `ratchet-fix.mjs --self-test` proves all-approve, invalid reject whole-batch abort, dry-run no mutation, and post-review ledger-state preflight. |
| SC4 | `mix accrue_admin.ui.fix` applies batch, rebuilds/commits CSS, recaptures, probes, finalizes ledger | VERIFIED | `ui.fix` sequence and dry-run covered by ExUnit; D-50 grep clean for no propose/verify fan-out; commit now uses `git commit ... --allow-empty -- priv/static`. |
| SC5 | Resolved findings auto-mint deterministic guards or ledger-count sentinel | VERIFIED | `ratchet-guard-mint.mjs --self-test` verifies routing, imported guard grammar, idempotent sorted append, complete concrete rows, and CR-02 incomplete-row downgrade. |
| SC6 | Loop terminates: K=2 dry rounds converge and round 6 escalates | VERIFIED | `phase-ratchet-ledger.mjs --self-test` passes all four dry clauses, epoch-boundary isolation, K=2 convergence, round-6 cap, and missing-round no-append path. |
| SC7 | ORCH-07/08 cache-control and surface scoping are wired | VERIFIED + HUMAN | Request-shape and filter logic self-tests pass; `ui.round` reads JS `SLICES` and threads `RATCHET_SURFACES`. Live provider cache-hit and live capture-directory outcomes remain human smokes. |

**Score:** 7/7 truths verified by code/test evidence; 2 live smoke checks still require human verification.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | Round counter, dry-round seal, convergence classifier, guard grammar exports | VERIFIED | Exists, substantive, self-tested; exports `GUARD_HOME_SPECS`, `checkGuardRef`, `isSafeSpecPath`, `computeNextRound`. |
| `accrue_admin/e2e/ratchet/ratchet-digest.mjs` | Offline HTML digest + `decisions.json` writer | VERIFIED | CR-01 fixed; `suggested_fix` optional, required fields strict, no literal null/undefined in regression fixture. |
| `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` | Deterministic guard routing and safe append | VERIFIED | Required-field validation before concrete write; incomplete concrete rows downgrade to `ledger-count`. |
| `accrue_admin/e2e/ratchet/ratchet-fix.mjs` | Decision apply/finalize loop | VERIFIED | Batch validation reads ledger before any append; invalid later decision leaves ledger byte-identical. |
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex` | One-command round orchestrator | VERIFIED | Runner-swappable; no hardcoded slice contents; digest always runs before cap handling. |
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` | One-command fix orchestrator | VERIFIED | Runner-swappable; no evaluator fan-out; `git add priv/static` and `git commit -- priv/static`. |
| Guard-home specs | Empty auto-guard regions + loop tests | VERIFIED | All 4 files have marker regions and no-op loop tests over `RATCHET_AUTO_GUARDS`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ui.round.ex` | `ratchet-digest.mjs` | Final `digest` run step | VERIFIED | Manual source check confirms digest runs after seal-round and before reading `.round-status`. |
| `ratchet-propose.mjs` | `ratchet-digest.mjs` | Optional `suggested_fix:null` ledger value | VERIFIED | Proposer may emit null; digest validator no longer requires it and self-test covers the path. |
| `ratchet-fix.mjs` | `ratchet-ledger.js` | `appendResolved`/`appendSuppressed`/`appendVerifiedClosed` + `isValidSuppressedReason` | VERIFIED | Reuses ledger lifecycle helpers; no lifecycle reimplementation. |
| `ratchet-fix.mjs` | `ratchet-guard-mint.mjs` | `mintGuardRow` then `appendMintedRow` before verified-close | VERIFIED | Finalize path calls mint/append, then records the returned `guard_ref`. |
| `ui.fix.ex` | git | `git commit ... --allow-empty -- priv/static` | VERIFIED | Source and ExUnit assert exact argv. |
| `ui.round.ex` | `baseline-manifest.js` | Captured `node -e` reads `SLICES` | VERIFIED | No hardcoded surface list in Elixir; `RATCHET_SURFACES` threaded to capture/propose/seal-round only. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `ratchet-digest.mjs` | `worklist`, `decisionsNeeded`, `galleryGroups` | `findings.ledger.ndjson`, `rounds.ndjson`, copied PNG/`.bbox.json` artifacts | Yes | FLOWING — folds ledger rows, partitions, validates, renders HTML, writes `decisions.json`. |
| `ratchet-fix.mjs` | decisions batch | `test-results/ui-ratchet/round-NN/decisions.json` + current ledger fold | Yes | FLOWING — validates against ledger state before any append. |
| `ratchet-guard-mint.mjs` | guard row | `finding` + `probe.probed` | Yes, when complete; sentinel when incomplete | FLOWING — complete rows write specs; incomplete rows intentionally use `ledger-count`. |
| `ui.round.ex` | surface scope | JS `SLICES` or `--surface` CLI | Yes | FLOWING — env passed only to capture/propose/seal-round. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Ledger lifecycle | `cd accrue_admin && node e2e/ratchet/ratchet-ledger.js` | self-test passed | PASS |
| Round convergence | `cd accrue_admin && node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | self-test passed | PASS |
| Proposer filter/cache shape | `cd accrue_admin && node e2e/ratchet/ratchet-propose.mjs --self-test` | self-test passed | PASS |
| Verifier cache shape | `cd accrue_admin && node e2e/ratchet/ratchet-verify.mjs --self-test` | self-test passed | PASS |
| Digest CR-01 + rendering | `cd accrue_admin && node e2e/ratchet/ratchet-digest.mjs --self-test` | self-test passed | PASS |
| Guard mint CR-02 | `cd accrue_admin && node e2e/ratchet/ratchet-guard-mint.mjs --self-test` | self-test passed | PASS |
| Fix apply/finalize + post-review preflight | `cd accrue_admin && node e2e/ratchet/ratchet-fix.mjs --self-test` | self-test passed | PASS |
| Mix tasks | `cd accrue_admin && mix compile --warnings-as-errors && mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` | 16 tests, 0 failures | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Shell probes | `find scripts -path '*/tests/probe-*.sh'` | No phase-declared `probe-*.sh` scripts found | SKIPPED |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|---|---|---|---|
| ORCH-01 | One-command `ui.round` pipeline renders digest | SATISFIED | Round task sequence tested; digest null field gap closed. |
| ORCH-02 | Rendered HTML gallery/worklist/decisions queue | SATISFIED | Digest self-test covers banner states, ranking, queue split, overlays, escaping, decisions file. |
| ORCH-03 | Batch approve/reject with suppress reason | SATISFIED | Apply-decisions whole-batch validation and suppression enum reuse self-tested. |
| ORCH-04 | One-command `ui.fix` applies, rebuilds/commits CSS, recaptures, finalizes | SATISFIED | Mix task ExUnit and scoped commit pathspec verified. |
| ORCH-05 | Deterministic guard per resolved finding or ledger-count sentinel | SATISFIED | Guard mint complete/incomplete paths self-tested; finalize CR-02 route self-tested. |
| ORCH-06 | K=2 convergence, 6-round cap | SATISFIED | Phase ledger self-test covers clauses and status classification. |
| ORCH-07 | Anthropic prompt caching stable prefix | AUTOMATED SATISFIED; HUMAN SMOKE PENDING | Exactly 3 cache-control breakpoints verified; live token-cost reduction needs key/network. |
| ORCH-08 | Surface/slice filter for capture and fan-out | AUTOMATED SATISFIED; HUMAN SMOKE PENDING | `SLICES`, capture filter, proposer filter, and env threading verified; live capture output needs server/browser run. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| Phase source scope | n/a | No `TBD`/`FIXME`/`XXX` debt markers | INFO | No blocker debt markers found. |
| `ratchet-verify.mjs` | 823 | Ledger-isolation self-test remains weak per code review | WARNING | Does not block Phase 207 goal; worth tightening before relying on that specific assertion. |
| `ratchet-ledger.js` | 303 | `appendOpen` lacks idempotency/lifecycle preflight | WARNING | Crash/retry duplicate-open hardening remains a follow-up risk, not a Phase 207 blocker. |
| `ratchet-propose.mjs` | 51/157/873 | Exported helper lives in a module with CLI import side effects | WARNING | Helper import ergonomics risk; current self-tests and CLI use pass. |
| `ratchet-fix.mjs` | 72/102 | Malformed round can resolve to non-integer artifact path | WARNING | Clearer validation recommended; focused Phase 207 paths pass. |

### Human Verification Required

1. **ORCH-07 cache-hit reduction**

**Test:** Run `ANTHROPIC_API_KEY=... npm run ratchet:propose` twice against unchanged PNGs and compare provider usage.
**Expected:** The second run reports non-zero `usage.cache_read_input_tokens`; identity remains stable.
**Why human:** Requires live Anthropic network/API behavior that deterministic self-tests intentionally do not exercise.

2. **ORCH-08 capture-side filter**

**Test:** Run `RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js` inside `accrue_admin/` with the e2e server/browser environment available.
**Expected:** Only dashboard PNGs are written for both projects/themes; no other surface PNGs are created.
**Why human:** Requires a booted Phoenix e2e server and actual Playwright capture output.

### Gaps Summary

No blocking gaps remain from the prior verification. CR-01, CR-02, the `ui.fix` commit pathspec warning, and the post-review `applyDecisions()` atomicity issue are all closed with source evidence and passing focused tests. The phase is not marked `passed` because two explicitly manual live smokes remain.

---

_Verified: 2026-07-07T12:42:16Z_
_Verifier: the agent (gsd-verifier)_
