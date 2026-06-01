# Phase 161: Backlog Anchor Closure + Pause Rule - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 161-backlog-anchor-closure-pause-rule
**Areas discussed:** Anchor disposition, Hygiene proof shape, Pause rule wording and placement

---

## Anchor Disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Keep anchors in-place with status labels | Minimal churn and full history, but historical roadmap surfaces can still look active. | |
| Split into Historical Anchors + Deferred Seeds registries | Clear active/non-active boundary, explicit revisit triggers, auditable reopen gates. | ✓ |
| Hard archive everything stale | Strongest clean-roadmap signal, but risks institutional memory loss and repeated re-triage. | |

**User's choice:** User asked the agent to research all areas with subagents and produce one cohesive recommendation so they would not have to decide routine choices.
**Notes:** Advisor research recommended the split-registry approach. It best matches the v1.17 friction-inventory doctrine, stop rules S1/S5, and stable-core posture while preserving useful history.

---

## Hygiene Proof Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Extend current grep-style CI contract | Lowest-friction, matches existing verifier style, but can be brittle if wording changes. | |
| Manifest-driven proof | Strong explicitness, but adds dual-SSOT/process overhead for a small closeout. | |
| Hybrid ledger + grep contract | Human-readable planning ledger plus fast CI verifier, without adding a new data model. | ✓ |

**User's choice:** User asked for a one-shot recommendation emphasizing great architecture, least surprise, and DX.
**Notes:** Advisor research recommended the hybrid proof. It reuses Accrue's existing docs-contract discipline and gives BAK-02 a concrete proof without making planning hygiene more ceremonial than necessary.

---

## Pause Rule Wording and Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Doctrine + mirrors | Canonical rule in `PROJECT.md`, concise mirrors in `ROADMAP.md` and `STATE.md`. | ✓ |
| Roadmap-local rule | Fast and local to milestone closeout, but weaker long-term governance memory. | |
| Hard freeze gate | Strong anti-churn, but risks blocking legitimate adopter pain and sounding bureaucratic. | |

**User's choice:** User asked for cohesive recommendations that move the project toward stable-core goals without overbuilding.
**Notes:** Advisor research recommended doctrine + mirrors. This keeps the rule durable and explicit without turning stable-core into a feature freeze.

---

## the agent's Discretion

- The agent selected the recommended option for each gray area because the user explicitly asked for researched one-shot recommendations rather than choice-by-choice approval.
- The recommendations are intentionally coupled: split registries supply the data model, the hygiene verifier proves it, and doctrine-plus-mirrors make the pause rule durable.

## Deferred Ideas

None.
