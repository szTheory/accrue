---
phase: 207-orchestration-digest-one-command-round-fix-loop
verified: 2026-07-04T22:10:00Z
status: gaps_found
score: 4/7 success criteria verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The digest is a rendered HTML gallery (ORCH-02, SC2) — running the pipeline always produces a digest"
    status: failed
    reason: "CR-01 — validateDigestRows() hard-requires suggested_fix, but the proposer legitimately stores suggested_fix:null when the model omits it (schema requires only dimension/region_tag/severity/defect). That null is carried onto the committed ledger row and reaches generateDigest() on the real (non-self-test) path, which throws → ratchet-digest.mjs exits non-zero → mix accrue_admin.ui.round's digest run_step! raises → the round aborts with NO digest produced. This defeats the load-bearing 'ALWAYS renders the digest before deciding whether to raise' guarantee (ui.round.ex:20-21). Fires on ordinary, non-adversarial LLM output. Self-tests pass only because every fixture supplies a non-null suggested_fix."
    artifacts:
      - path: "accrue_admin/e2e/ratchet/ratchet-digest.mjs"
        issue: "REQUIRED_ROW_FIELDS (line 66-74) includes 'suggested_fix'; validateDigestRows (281-292) throws on null/empty; called in generateDigest() at 947-948"
      - path: "accrue_admin/e2e/ratchet/ratchet-propose.mjs"
        issue: "emitCandidates stores suggested_fix: null when the model omits it (line 852); tool schema requires only dimension/region_tag/severity/defect (line 385)"
    missing:
      - "Drop suggested_fix from REQUIRED_ROW_FIELDS and render it as optional prose, OR default it to a non-empty placeholder at proposer emit time so no null reaches the committed ledger."
  - truth: "Resolving a finding auto-mints a deterministic guard so a closed finding cannot silently reopen (ORCH-05, SC4)"
    status: failed
    reason: "CR-02 — ratchet-fix-probe.spec.js's default branch (every dimension except contrast/6 and motion/9) sets present=false with probed={region_present,text} only — it captures no kind-specific fields. finalizeFixes then routes those present:false findings through mintGuardRow → buildRow, which needs property/expected_token (design-token dim1), property/allowed_values (spacing-scale dim3 inconsistent-rhythm), or expected_text/old_text (microcopy dim12). buildRow reads them as undefined; JSON.stringify drops them; appendMintedRow writes a structurally-incomplete row into a committed guard-home spec (foundation-tokens.spec.js / admin-page-flow-phase200.spec.js) and flips RATCHET_AUTO_GUARDS.length>0, so the previously-skipped loop test now runs against undefined fields and FAILS in CI — corrupting a committed spec. mintGuardRow has no REQUIRED_FIELDS_BY_KIND guard, and checkGuardRef only checks the @ratchet:<id> token substring, not field completeness. Reachable for any resolved dim-1/dim-3-rhythm/dim-12 finding (common kinds)."
    artifacts:
      - path: "accrue_admin/e2e/ratchet-fix-probe.spec.js"
        issue: "default probe branch (lines ~198-213) reports present=false with no kind-specific probed fields for design-token/spacing-scale/microcopy"
      - path: "accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs"
        issue: "buildRow (119-137) and mintGuardRow (148-170) mint a concrete row with undefined kind-fields; no required-field validation before write"
      - path: "accrue_admin/e2e/ratchet/ratchet-fix.mjs"
        issue: "finalizeFixes routes present:false through mintGuardRow/appendMintedRow without checking the row is field-complete"
    missing:
      - "Make mintGuardRow/buildRow refuse a concrete mint when a required kind-field is missing and degrade to the ledger-count sentinel (or leave the finding resolved), OR extend the probe's default branch to capture the design-token/spacing/microcopy fields before reporting present:false."
deferred: []
human_verification:
  - test: "ORCH-07 cache-hit reduction: run ANTHROPIC_API_KEY=... npm run ratchet:propose twice against unchanged PNGs and diff usage.cache_read_input_tokens in the API response."
    expected: "Second run shows non-zero cache_read_input_tokens on the stable system+schema+image prefix; identity (claim_key/finding_id) unchanged."
    why_human: "Requires a live Anthropic API key and network; documented in the plan as a manual smoke, never a CI gate. The request-shape (3 cache_control breakpoints per request) IS self-test-verified; only the measured cost reduction needs a live key."
  - test: "ORCH-08 capture-side filter: run RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js inside accrue_admin/ (needs the e2e server)."
    expected: "Only test-results/admin-visuals/{chromium-desktop,chromium-mobile}/dashboard*.png are written (both themes), no other surface PNGs."
    why_human: "Requires a booted Phoenix e2e server + Playwright browsers. The pure filter predicate (filterPngsBySurfaces) and the SLICES map ARE self-test/structurally verified; only the live capture-directory outcome needs a running server."
---

# Phase 207: Orchestration + digest + one-command round/fix loop — Verification Report

**Phase Goal:** The whole pipeline is driven by two `mix` commands with a rendered digest and minimal maintainer checkpoints, resolutions auto-mint deterministic guards, and the loop provably terminates.
**Verified:** 2026-07-04T22:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (mapped to ROADMAP Success Criteria)

| # | Truth (Success Criterion) | Status | Evidence |
| --- | --- | --- | --- |
| SC1 | `mix accrue_admin.ui.round` runs the whole pipeline in one command and renders a digest (ORCH-01) | ⚠️ PARTIAL | Task + sequence VERIFIED: `accrue_admin.ui.round.ex` sequences next-round→assets.build→capture→propose→verify→seal-round→digest through a swappable Runner; ExUnit `accrue_admin_ui_round_test.exs` proves exact order/args/env threading + marker-driven branches (16 mix tests pass). BUT the "renders a digest" outcome is blocked on the real path by CR-01 (digest crashes on null `suggested_fix`), so the end-to-end guarantee fails. |
| SC2 | Digest is a rendered HTML gallery: per-surface groups, region overlays, ranked worklist, separate decisions-needed queue (ORCH-02) | ✗ FAILED | Self-test green for all 4 banner states, overlay scale math (1280/393), XSS escaping, decisions.json shape. BUT `generateDigest()` throws on a confirmed finding with `suggested_fix: null` (CR-01) — the real pipeline aborts the round with no digest. See gap 1. |
| SC3 | Batch-approve all auto-fixable findings, or reject into a suppress-list with a reason feeding dedup (ORCH-03) | ✓ VERIFIED | `ratchet-fix.mjs --apply-decisions` reuses `appendResolved`/`appendSuppressed`/`isValidSuppressedReason`; `--self-test` proves all-approve happy path, whole-batch abort on any invalid suppressed_reason (zero partial apply), and `--dry-run` zero-mutation. Green. |
| SC4 | `mix accrue_admin.ui.fix` applies batch, rebuilds+commits CSS, re-captures, and auto-mints a deterministic guard per resolved finding (ORCH-04/05) | ✗ FAILED | Apply → assets.build → git-add → git-commit → recapture → probe → finalize sequence proven by ExUnit; D-50 grep clean (no propose/verify/appendOpen in ratchet-fix.mjs). BUT guard-minting mints structurally-incomplete guards for design-token/spacing-scale/microcopy kinds that break committed CI specs (CR-02). See gap 2. WR-02: git-commit lacks a `-- priv/static` pathspec, so it sweeps the whole staged index. |
| SC5 | Loop reports convergence after K=2 consecutive dry rounds and escalates at a 6-round hard cap (ORCH-06) | ✓ VERIFIED | `phase-ratchet-ledger.mjs --seal-round` self-test proves 4-clause dry conjunction, K=2 same-epoch converged, epoch-boundary isolation, round-6 cap-reached, and missing-RATCHET_ROUND non-zero-exit-no-append. `ui.round.ex` raises on `cap-reached` after the digest step. Green. |
| SC6 | Repeated `ui.round` runs reuse a cached prompt prefix via `cache_control`, identity + no-key/self-test paths unchanged (ORCH-07) | ✓ VERIFIED (shape) / human (cost) | Both proposer request builders + verifier panel request carry exactly 3 `cache_control` ephemeral breakpoints (system, tools[0], image block), self-test-proven with no key; identity/no-key guard order unchanged. Measured token-cost reduction is a documented manual live smoke → human verification. |
| SC7 | Scope a round to a surface subset via a documented flag; unscoped still sweeps the full set (ORCH-08) | ✓ VERIFIED (logic) / human (capture) | `SLICES` exported from baseline-manifest.js; `filterPngsBySurfaces` pure + self-tested; `RATCHET_SURFACES` threaded by `ui.round --slice/--surface` (no hardcoded slice contents in Elixir — read from JS SSOT). Live capture-directory filtering needs a running server → human verification. |

**Score:** 4/7 success criteria verified (SC3, SC5, SC6, SC7); SC1 partial; SC2 + SC4 FAILED.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue_admin/e2e/ratchet/rounds.ndjson` | New committed 0-byte append-only round log | ✓ VERIFIED | Exists, 0 bytes, tracked |
| `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | `--next-round`/`--seal-round` + guard-grammar exports | ✓ VERIFIED | Self-test green; `checkGuardRef`/`GUARD_HOME_SPECS`/`isSafeSpecPath` importable |
| `accrue_admin/e2e/ratchet/ratchet-digest.mjs` | Offline HTML digest, 4 banner states, overlays, escaping | ⚠️ STUB-ON-REAL-PATH | Self-test green; real path throws on null suggested_fix (CR-01) |
| `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs` | Kind routing + idempotent sorted append | ⚠️ INCOMPLETE | Self-test green with full fixture fields; no missing-field guard (CR-02) |
| `accrue_admin/e2e/ratchet/ratchet-fix.mjs` | apply-decisions + finalize-fixes, D-50 clean | ✓ WIRED (D-50) / ⚠️ CR-02 | Self-test green; D-50 grep clean; routes incomplete rows to mint (CR-02) |
| `accrue_admin/e2e/ratchet-fix-probe.spec.js` | Scoped per-resolved-finding DOM probe | ⚠️ INCOMPLETE | default branch captures no kind-specific fields (CR-02) |
| `accrue_admin/e2e/baseline-manifest.js` | Exports `SLICES` | ✓ VERIFIED | `{foundation:[component-kitchen,dashboard,subscription-detail,subscriptions]}` |
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex` | Thin Runner-swappable orchestrator | ✓ VERIFIED | Compiles clean; ExUnit proves 7-step sequence |
| `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex` | Thin mutation orchestrator | ✓ VERIFIED / ⚠️ WR-02 | ExUnit proves 6-step sequence; git-commit un-scoped (WR-02) |
| `accrue_admin/e2e/ratchet/ratchet-propose.mjs`/`ratchet-verify.mjs` | cache_control breakpoints | ✓ VERIFIED | 3 breakpoints each, self-tested |
| 4 guard-home spec files | `@ratchet:auto-guards` region + loop test | ✓ VERIFIED | 2 markers each; loop no-ops on empty array |

### Key Link Verification

| From | To | Via | Status |
| --- | --- | --- | --- |
| `ratchet-guard-mint.mjs` | `phase-ratchet-ledger.mjs` | imports GUARD_HOME_SPECS/checkGuardRef/isSafeSpecPath (no re-derived grammar) | ✓ WIRED |
| `ui.round.ex` | `.round-next`/`.round-status` markers | reads scalars written by phase-ratchet-ledger.mjs | ✓ WIRED |
| `ui.round.ex` | `baseline-manifest.js` SLICES | captured `node -e` read (no hardcoded slice contents) | ✓ WIRED |
| `ratchet-fix.mjs` | `ratchet-ledger.js` | appendResolved/appendSuppressed/isValidSuppressedReason | ✓ WIRED |
| `ratchet-fix.mjs --finalize-fixes` | `ratchet-guard-mint.mjs` | mintGuardRow/appendMintedRow | ⚠️ WIRED-BUT-FEEDS-INCOMPLETE-DATA (CR-02) |
| `ratchet-fix.mjs` | propose/verify/appendOpen | must NOT link (D-50) | ✓ CORRECTLY ABSENT (grep clean) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Round ledger self-test | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | exit 0, "self-test passed" | ✓ PASS |
| Proposer cache_control shape | `node e2e/ratchet/ratchet-propose.mjs --self-test` | exit 0 | ✓ PASS |
| Verifier cache_control shape | `node e2e/ratchet/ratchet-verify.mjs --self-test` | exit 0, "self-test passed" | ✓ PASS |
| Guard mint routing/idempotency | `node e2e/ratchet/ratchet-guard-mint.mjs --self-test` | exit 0, "self-test passed" | ✓ PASS |
| Digest 4 banner states + XSS | `node e2e/ratchet/ratchet-digest.mjs --self-test` | exit 0, "self-test passed" | ✓ PASS (happy path only — misses null suggested_fix) |
| Fix apply/finalize | `node e2e/ratchet/ratchet-fix.mjs --self-test` | exit 0, "self-test passed" | ✓ PASS (fixtures supply full probe fields — misses CR-02 path) |
| ui.round + ui.fix ExUnit | `mix test .../accrue_admin_ui_round_test.exs .../accrue_admin_ui_fix_test.exs` | 16 tests, 0 failures | ✓ PASS |
| D-50 isolation | `grep -E "appendOpen\|ratchet-propose\|ratchet-verify" ratchet-fix.mjs ratchet-fix-probe.spec.js` | no matches | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| --- | --- | --- | --- |
| ORCH-01 | 207-05 | ⚠️ PARTIAL | ui.round sequence proven; end-to-end digest render blocked by CR-01 |
| ORCH-02 | 207-04 | ✗ BLOCKED | Digest aborts on null suggested_fix (CR-01) |
| ORCH-03 | 207-06 | ✓ SATISFIED | apply-decisions validated + self-tested |
| ORCH-04 | 207-06 | ⚠️ PARTIAL | ui.fix sequence proven; guard-mint step feeds CR-02; git-commit WR-02 |
| ORCH-05 | 207-03 + 207-06 | ✗ BLOCKED | Mints incomplete guards for common kinds → breaks committed CI specs (CR-02) |
| ORCH-06 | 207-01 | ✓ SATISFIED | seal-round convergence/cap self-tested |
| ORCH-07 | 207-02 | ✓ SATISFIED (shape) | 3 cache_control breakpoints self-tested; cost = manual smoke |
| ORCH-08 | 207-02 | ✓ SATISFIED (logic) | SLICES + filter self-tested; live capture = manual |

All 8 requirement IDs from the PLAN frontmatters (ORCH-01..08) are present in REQUIREMENTS.md, each mapped to Phase 207 and marked Complete. No orphaned or unaccounted IDs. Note: REQUIREMENTS.md/ROADMAP mark ORCH-02 and ORCH-05 "Complete", but codebase evidence shows both are BLOCKED — the tracker is optimistic relative to the code.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `ratchet-digest.mjs` | 66-74, 947 | Over-strict required field aborts real path | 🛑 Blocker | CR-01 — round crashes, no digest |
| `ratchet-guard-mint.mjs` / `ratchet-fix-probe.spec.js` | 119-170 / ~198-213 | Mint with undefined kind-fields; probe default captures none | 🛑 Blocker | CR-02 — corrupts committed CI spec |
| `accrue_admin.ui.fix.ex` | 110-116 | `git commit` without `-- priv/static` pathspec | ⚠️ Warning | WR-02 — sweeps unrelated staged files into CSS commit |
| `ratchet-verify.mjs` | 826-834 | Vacuous ledger-isolation self-test (reads twice, no op between) | ⚠️ Warning | WR-01 — false confidence in single-writer invariant |
| `ratchet-ledger.js` | 303-346 | `appendOpen` has no transition/dedup guard | ⚠️ Warning | WR-03 — non-atomic round re-run can double-append |
| `ratchet-digest.mjs` | 200 | Dead `EFFORT_ORDER` constant | ℹ️ Info | IN-01 |
| `ratchet-propose.mjs` | 873 | Bare `await main()` (no clean-crash wrapper) | ℹ️ Info | IN-02 |
| `ratchet-fix.mjs` | 102-108 | `resolveRound` can yield `round-NaN` on malformed file | ℹ️ Info | IN-03 |

### Human Verification Required

1. **ORCH-07 cache-hit reduction** — run the proposer twice with a live key against unchanged PNGs; diff `usage.cache_read_input_tokens`. (Request shape is already self-test-verified; only the measured cost reduction needs a key.)
2. **ORCH-08 capture-side filter** — `RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js` with the e2e server up; confirm only dashboard PNGs are written. (Filter predicate + SLICES already verified; live capture needs a server.)

### Gaps Summary

The tooling is well-isolated (LLM off the gate path, self-tests target mkdtemp scratch, path-traversal closed, HTML escaped) and every module's `--self-test` / FakeRunner test is green — but two BLOCKER defects break the phase's own load-bearing guarantees on *ordinary, non-adversarial* inputs, and both are invisible to the self-tests because the fixtures only exercise the happy path:

- **CR-01 (ORCH-02 / SC2):** The digest hard-requires `suggested_fix`, which the proposer legitimately leaves `null`. On the real ledger path the digest throws → the `ui.round` digest step raises → the round aborts with **no digest rendered**, directly defeating the "always renders the digest" guarantee that is central to the phase goal.
- **CR-02 (ORCH-05 / SC4):** `finalize-fixes` mints structurally-incomplete guard rows (missing `property`/`expected_token`/`allowed_values`/`expected_text`/`old_text`) into committed guard-home specs for design-token / spacing-scale / microcopy findings — all common kinds — flipping their loop test on and **failing CI against `undefined` fields**, i.e. corrupting a committed spec rather than protecting against silent reopen.

Both are self-contained, low-effort fixes (drop/soften the required field; add a `REQUIRED_FIELDS_BY_KIND` guard that degrades to the `ledger-count` sentinel). Route to `/gsd-plan-phase 207 --gaps`. WR-01/02/03 are warnings worth folding into the same fix pass (WR-02 especially — the un-scoped git commit is a real correctness bug in the mutation command). Neither gap is deferred to a later phase: Phase 208 runs the real pipeline end-to-end and would be the first to trip both.

**Bookkeeping note (INFO):** ROADMAP.md line 241 reads "Plans: 4/6 plans executed" while all six 207-NN checkboxes are checked and all six SUMMARY files exist — stale roadmap text, not a code gap.

---

_Verified: 2026-07-04T22:10:00Z_
_Verifier: Claude (gsd-verifier)_
