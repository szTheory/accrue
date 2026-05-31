# Phase 158: Oban Cron Wiring Adopter Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 158-Oban Cron Wiring Adopter Proof
**Areas discussed:** Config proof shape, Queue contract wording, Proof depth, Append-merge teaching

---

## Config Proof Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime env only | Assert `Application.fetch_env!(:accrue_host, Oban)` in `MIX_ENV=test`; simple but accepts `plugins: false` / `queues: false` as pass. | |
| Base config inspection | Read `config/config.exs`, validate with `Oban.Config.validate/1`, and assert queues + cron workers there. | ✓ |
| Shared config helper | Extract reusable helper for cron entries and test it. Cleaner long-term, but too much indirection for this phase. | |

**User's choice:** Selected all areas for subagent-backed advisor research and requested one cohesive recommendation set.
**Notes:** Recommendation is base-config inspection plus separate test-env safety assertion.

---

## Queue Contract Wording

| Option | Description | Selected |
|--------|-------------|----------|
| Keep roadmap literal | Assert only `accrue_webhooks`, `accrue_mailers`, `accrue_meters`, `accrue_scheduled`; minimal churn but omits `accrue_dunning`. | |
| Split queue categories | Separate core runtime queues from cron-wiring queues and correct the proof semantics. | ✓ |
| Assert one broad host-required set | Assert all host-required queues as a unified set; clearer for adopters but slightly broader. | ✓ |

**User's choice:** Selected all areas for subagent-backed advisor research and requested a perfect cohesive recommendation.
**Notes:** Final context combines the two useful parts: split categories for clarity, and assert the host-required set needed for honest example-host background behavior.

---

## Proof Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Config-contract only | Fast, deterministic assertions for queues and cron entries; no runtime smoke. | |
| Hybrid minimal smoke | Config-contract first, with at most one cheap no-op host-call smoke. | ✓ |
| Full smoke suite | Retain/extend all current job execution smoke tests; highest surface confidence but duplicates core behavior and is more brittle. | |

**User's choice:** Selected all areas for subagent-backed advisor research and requested a one-shot recommendation.
**Notes:** Context locks config-contract-first proof and allows at most one minimal smoke at planner discretion.

---

## Append-Merge Teaching

| Option | Description | Selected |
|--------|-------------|----------|
| `config.exs` only | Closest to copy/paste callsite, least doc sprawl, weaker discoverability. | |
| `config.exs` plus matrix pointer | Canonical snippet at callsite, concise adoption-proof matrix note for discoverability. | ✓ |
| Add README too | Maximum discoverability, but higher drift risk across three surfaces. | |

**User's choice:** Selected all areas for subagent-backed advisor research and requested cohesive DX/least-surprise recommendations.
**Notes:** Final context uses `config.exs` as the canonical snippet and `adoption-proof-matrix.md` as the contract pointer; README expansion is deferred.

---

## the agent's Discretion

- Planner may keep one cheap no-op smoke if it remains stable and clearly secondary to config assertions.
- Planner may update roadmap/requirements wording to reconcile `accrue_dunning` because that correction aligns the phase with existing worker reality.
- Planner should decide exact helper-function shape inside `recovery_wiring_test.exs`.

## Deferred Ideas

- Broader installer/First Hour queue taxonomy update.
- Production helper module for reusable host Oban config fragments.
- ENT-10 advisory-cache todo reviewed but not folded into Phase 158.
