# Owner direction: Storybook as a UI quality engine

**Recorded:** 2026-10-26, during `$gsd-new-milestone` questioning after v1.67.
**Status:** Durable owner intent and research authorization; no milestone has been opened by this note.
**Sources:** The owner's conversation and supplied UI Storybook stress-test methodology text. This note records direction, not a current UI quality verdict.

## The opportunity

The owner identifies realistic, compositional Storybook scenarios as the next major opportunity to improve Accrue's UI quality and iteration speed. Preserve this direction across milestone boundaries. Storybook should make it easy to zoom into a real situation, inspect it closely, improve its owning components, and see those improvements propagate into the application.

The intended composition ladder is:

**components → small groups → areas within a section → whole sections → whole pages per job.**

This is a hierarchy of actual product compositions, not only a primitive catalogue. Organize it using the application's sections, user-facing nouns, personas, and jobs to be done. Exercise the combinations that can really appear in the application; prune redundant, outdated, impossible, or unrecognizable situations. Exhaustive Cartesian multiplication of props is not the objective.

## What scenarios must represent

- Happy paths, errors, empty/new accounts, realistic boundary conditions, and power-user situations.
- Realistic data and chronology, not attractive but impossible billing records. Sanity-check seeds, fixtures, ownership, money, state transitions, and provider capabilities together.
- Different plausible adopters: B2B and B2C SaaS and, where relevant, self-hosted products. The owner gave a Slack-like collaboration product, language learning, and personal finance as examples to explore, not a requirement to add those products or billing capabilities.
- Distinguish adopter product profiles from the actors doing work: integrators, vendor support/billing operators, engineers, and host customers/billing managers.
- Curated personas and coherent journeys across the whole UI and within each section; natural navigation and preserved context.
- Every realistic viewport width, approached mobile first. Light and dark are both first-class. Fixed test widths are samples of a responsive continuum, not proof of all possible widths.

## Design bar

Aim for an intentionally designed, elegant interface: professional typography, restrained and coherent colors, clear information hierarchy, good grouping and affordances, and no redundant content. The owner's “iPhone-designed” and “award-winning” language describes the desired craft and ease of use, not a request to copy Apple visuals or replace Accrue's established identity.

Routine work should be effortless and predictable while retaining useful depth for power users. Apply the principle of least surprise. Use consistent, precise, user-facing domain language and excellent microcopy; avoid narrating internal modules, database structure, or implementation details during ordinary tasks. Preserve exact technical evidence where investigation requires it.

The design system and component library should compound these improvements. Fix the lowest tier that owns a problem so every real composition benefits. Do not settle for mechanical accessibility or screenshot checks as proof of good visual design.

## Architectural and operating direction

- Favor composable, data-driven Phoenix presentation over hardcoded page examples. Keep behavior, authorization, and data-loading boundaries truthful.
- Share scenario definitions where practical across stories, tests, and demo-seed adapters without making a DB-free story require a database or copying application rendering.
- Keep dependencies small and flat: “another copy and paste is better than another dep.” A genuinely necessary dependency needs a specific written justification; do not duplicate complex accessibility or browser engines.
- Keep Storybook and its fixtures in development/test tooling, outside adopter runtime requirements and published fixture payloads. Adopters must not need Node tooling.
- Reuse existing machinery before introducing a manifest, glossary, judge, token format, ratchet, or test framework.
- Authorize a bounded multi-role fan-out, primary-source research where useful, adversarial challenge, and synthesis into coherent recommendations. Stop when more analysis would not change scope, order, or acceptance.

## Planning boundary and continuity

The supplied methodology says this session ends at a reviewed plan and explicitly excludes product-code/dependency changes and opening or modifying a milestone or canonical REQUIREMENTS/ROADMAP. Use a research-backed milestone proposal and rolling immediate/near/mid/long-term plan here. The active new-milestone workflow also has a milestone-summary confirmation gate before canonical milestone writes.

This direction is an explicit strategy proposal for quality of existing surfaces, not authorization for new billing capabilities, a rebrand, new Admin rooms, or revival of the parked paid evaluator. Preserve other known correctness work, especially the event session-timezone issue, as a separate high-priority candidate rather than silently absorbing or dropping it.

Research and the reviewed proposal live in [`../research/ui-quality-engine/`](../research/ui-quality-engine/). Formal milestone activation requires reconciling that proposal through the new-milestone workflow; future horizons remain directional until selected.
