---
id: SEED-009
status: backlogged
planted: 2026-10-26
planted_during: new-milestone-questioning-after-v1.67
trigger_when: opening a UI quality, Storybook, component composition, fixture realism, responsive design, Admin or Portal refinement milestone
scope: Large
---

# SEED-009: Production-backed Storybook and realistic UI situations

## Why This Matters

The owner explicitly identifies compositional Storybook coverage as the next major UI quality opportunity: components → small groups → areas → sections → pages per job, using realistic data and reachable scenarios. Mobile-first layout, light/dark, professional typography, clear hierarchy, restrained color, consistent user-facing language, natural navigation and power-user depth are durable quality direction.

## Current proposal

Read [owner direction](../notes/2026-10-26-ui-storybook-quality-direction.md), [recommendations](../research/ui-quality-engine/RECOMMENDATIONS.md) and [proposed v1.68 plus rolling roadmap](../research/ui-quality-engine/MILESTONE-PROPOSAL.md). Research is already complete enough for a scope decision; do not restart broad discovery unless named new evidence changes scope or safety.

Start with production-backed subscription compositions and one real list/detail job, reusing existing scenarios, tokens, Storybook, Playwright, axe and selected visual baselines. Source inspection found group stories describing metadata instead of rendering groups and a copied historical subscription screen. Those are process gaps, not fresh runtime UI verdicts.

## When to Surface

- The next milestone is selected after v1.67.
- UI quality, Storybook, seeds/fixtures, presentation composition or Admin/Portal refinement is proposed.
- A supported adopter situation, responsive failure or stale story reveals a missing equivalence class.

## Guardrails

Keep domain-valid facts shared through narrow dev/test adapters; keep authorization, persistence and lifecycle proof mounted. Prune only with reachability/provenance and surviving regression coverage. Preserve ordinary/held-out seed safety, brand/token ownership, host authority and the retained kitchen renderer. No new billing features, rebrand, paid-critic revival, broad dependency expansion or Cartesian story explosion. Wider horizons remain proposals. This seed does not open or modify a milestone.
