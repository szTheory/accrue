# Phase 206: Adversarial verifier + finding ledger + deterministic gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 206-adversarial-verifier-finding-ledger-deterministic-gate
**Areas discussed:** Baseline keying, Skeptic panel structure, 206/207 ledger-write boundary, Lifecycle & guard/reopen contract

**Mode:** User requested a one-shot cohesive synthesis (their standing preference) — all four gray
areas were selected, researched by four parallel `gsd-advisor-researcher` subagents (pros/cons/
tradeoffs, Elixir/Phoenix OSS idiom, lessons from comparable ratchet/baseline/suppression systems,
DX, footguns), then synthesized into a single coherent decision package. No individual forks were
surfaced back to the user because all four converged on ratified-requirement-backed defaults with no
truly-irreversible/published choice among them (per the user's "only flag very impactful forks" rule).

---

## Baseline keying (the LEDGER-02 "per lens" vs design-doc "[bucket]" conflict)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) per-lens totals | One count per lens (7 keys); matches LEDGER-02/03 literally | |
| (b) per-severity-bucket {minor,real} | Two counts; matches design-doc reducer expression | |
| (c) per-lens × severity | Cross product (14 cells); finest granularity | |
| (d) per-lens gated + per-lens×severity stored | Gate on per-lens severity-summed totals; keep {minor,real} as non-gating sub-count | ✓ |

**Choice:** (d) — D-24..D-27. Per-lens wins the gate key (7-value enum: 6 `persona:<id>` + `design`),
severity-summed; `{minor,real}` retained as informational sub-count only. Count over (finding, lens)
pairs via a frozen sticky `raised_by_lenses` set; asymmetric compare like `compareCells()`.
**Notes:** Conflict resolved for per-lens — three ratified sources (LEDGER-02, LEDGER-03/SC-4, CONV-04)
plus the design doc's own §50 prose agree; only its line-43 `[bucket]` shorthand dissented. Same
requirement-wins precedent as Phase 205's D-01. Codecov per-file-not-global-% lesson: a scalar total
masks compensating regressions (option b's failure). D-13 severity honored as sub-count, not overridden.

---

## Skeptic panel structure (VERIFY-01..03)

| Option | Description | Selected |
|--------|-------------|----------|
| A. 3 independent Opus calls / candidate | Highest independence; ~3×N calls, re-sends screenshot each time; worst cost | |
| B. 1 call, 3 roles, shared free-text verdict | Cheapest; roles contaminate, can't cleanly do ≥2-of-3 | |
| C. 1 call/image, 3 role verdicts in strict structured output | Image amortized over all candidates; enforced per-role buckets; cache-ready | ✓ |

**Choice:** C — D-28..D-34. One Opus call per image; median-then-clamp vote aggregation (median ≥ minor
= confirmed; final severity clamped ≤ proposer severity, D-13 downgrade-only); density-defender's D-21
air-ward bar wired into its voting instruction; VERIFY-03 token check is a deterministic parse-time
re-gate (`isAdmissibleToken`); raw verdicts ephemeral/regenerated, only the deterministic ledger effect
committed; injection preamble extended to candidate free-text.
**Notes:** Key API fact — temp-0 is UNAVAILABLE on Opus 4.x (`temperature`/`top_p`/`top_k` → 400);
determinism leans on strict structured output + harness re-gate (the proposer's `supportsSampling()`
posture). Stable-prefix-first request ordering pre-positions ORCH-07 caching for Phase 207.

---

## 206/207 ledger-write boundary (SC-3 "206 persists" vs design-doc "human confirms → open")

| Option | Description | Selected |
|--------|-------------|----------|
| (a) 206 auto-persists open; human layer later | Committed ledger→gate demonstrable; machine rows in committed ledger | |
| (b) 206 stops at verified-candidates.ndjson; all ledger writes wait for 207 human triage | Ledger only ever human-blessed; breaks 206 phase-independence | |
| (c) Hybrid: 206 auto-persists provenance-tagged open; 207 only removes/advances | 206 self-contained AND human can veto | ✓ |

**Choice:** (c) — D-35..D-37. 206's verifier is the single writer of `open` (provenance-tagged
`confirmed_by`/`panel_votes`/token); 207 is a pure superset-layer (reject→suppressed, approve→resolve→
verified-closed), never adds `open`. Baseline non-empty-but-UNFROZEN in 206 (green by construction),
first FROZEN in 208 (CONV-02) behind a `--freeze` flag; CI wired only in 208 so no regression-vs-zero.
**Notes:** SC-3/LEDGER-01 relocate "confirm" from human to the machine panel (VERIFY-01..03) — the D-01
precedent again. Detector-then-baseline idiom (PHPStan/RuboCop-todo/Sobelow). "Non-empty" ≠ "frozen"
(PHPStan-baseline idiom) reconciles SC-3 vs CONV-02.

---

## Lifecycle & guard/reopen contract (LEDGER-01, LEDGER-03, LEDGER-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Append-only NDJSON event log + monotonic seq; latest-event-wins fold | Full audit history, git-legible, tamper-evident | ✓ |
| Mutate-in-place per finding_id | Simpler read; destroys history, harder to diff | |
| guard_ref = inline greppable token in guard-home spec | Existence == token presence; can't claim a deleted guard | ✓ |
| guard_ref = central registry file | Drifts out of sync with the code it references | |

**Choice:** D-38..D-41. Append-only event log (`event ∈ confirm|resolve|verify-close|suppress|reopen`,
monotonic `seq` asserted increasing); `guard_ref = "<spec-path>::@ratchet:<finding_id>"` checked by
static substring read (no test execution) against a `GUARD_HOME_SPECS` allowlist; `ledger-count`
sentinel for the honest residual set; reopen marker = separate epoch-bound `reopen-markers.ndjson`;
`suppressed_reason` closed enum + free `suppressed_note`; pre-ledger machine kills dropped, not suppressed.
**Notes:** Credo/Sobelow/ESLint inline-suppression lesson (inline token beats registry). Substring
presence not whole-file hashing (guard-home specs grow). 206 builds the gate + verifier(open producer) +
append-helper + self-tests; 207 wires resolve/verified-closed/suppress producers.

## Claude's Discretion

Batch granularity (per-image vs per-surface); whether per-role rationale persists; adaptive-thinking on
the panel; DEDUP-03 collapse ordering (recommend before verify); baseline field ordering + epoch format;
LEDGER-04 hand-edit assertions; `resolved_locked` = verified-closed-only vs union; suppress-list
materialization; `GUARD_HOME_SPECS` membership; ratchet file layout + shared `ratchet-ledger.js` helper.

## Deferred Ideas

Orchestration + digest + batch-approve + auto-mint guards + re-capture + dry-round/6-round cap + ORCH-07
caching + ORCH-08 subset filter → Phase 207. Convergence run + baseline FREEZE + CI wiring + maintainer
ACCEPT → Phase 208. Full ~19-surface sweep → Phase 209 (optional).
