# Phase 166: Adoption DX Docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 166-Adoption DX Docs
**Areas discussed:** Start Here narrative, Docker/local command contract, proof/evidence ladder

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All areas | Covers the Start Here story, Docker commands, and proof/evidence path so the README becomes coherent end to end. | x |
| Narrative only | Focuses on persona/JTBD framing and how the top of the README should invite adopters into the demo. | |
| Commands only | Focuses on Docker, local setup, and verification commands while leaving doc tone to the planner. | |

**User's choice:** Discuss all areas with subagent-backed research, ecosystem prior-art comparison, idiomatic Elixir/Phoenix lens, DX/UX emphasis, and a cohesive one-shot recommendation.

**Notes:** User explicitly requested pros/cons/tradeoffs for each area, lessons from successful libraries/apps in Elixir/Phoenix and other ecosystems, attention to `prompts/`, and recommendations coherent with Accrue's goals and least-surprise engineering posture.

---

## Start Here Narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current caveat-first README | Truthful about Sigra/support boundaries but makes maintainer caveats the first impression. | |
| Command-first only | Fastest path, but misses Phase 166 persona/JTBD requirement. | |
| Persona-first story | Shows the realistic demo value, but can become marketing if it delays commands. | |
| Proof-matrix-first | Strong maintainer truth, but too heavy for adoption DX. | |
| Cohesive Start Here | One short persona frame, prominent run lanes, concise Fake/Sigra truth, deeper proof links after the happy path. | x |

**User's choice:** Agent recommendation accepted via "think deeply one-shot a perfect set of recommendations so I don't have to think."

**Notes:** Research compared Phoenix/Plug/Ecto quickstarts, Stripe Checkout, Laravel Cashier, Rails Pay, and local Accrue planning/docs. The winning pattern is to put the first successful action before caveats while preserving honest support boundaries.

---

## Docker/Local Command Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Docker-first Start Here | Best adoption DX; provisions Postgres/Elixir/Node and matches DOC-02. | x |
| Bare-metal Phoenix-first | Idiomatic for Phoenix contributors but higher setup friction for evaluators. | |
| Equal split lanes | Honest but forces premature choice and increases drift. | |
| Docker-only README | Simple, but bad fit for Phoenix contributors and existing First Hour vocabulary. | |
| CI/proof-first docs | Strong proof posture but too heavy for first run. | |

**User's choice:** Docker-first with native Phoenix as a secondary contributor path.

**Notes:** Research surfaced a planning constraint: verify or fix Docker browser reachability before README claims are finalized because `dev.exs` may bind to `127.0.0.1` while compose publishes `4000:4000`. Also mention `5432` port collision risk and named-volume cache reset semantics tersely.

---

## Proof/Evidence Ladder

| Option | Description | Selected |
|--------|-------------|----------|
| Put all proof commands in Start Here | Transparent but overwhelming; makes every verifier look required. | |
| Keep current structure, add prose | Minimal churn but does not solve first-run DX. | |
| Proof ladder under Start Here | Keeps setup simple while preserving truthful command claims and maintainer evidence. | x |
| Split proof into a separate doc | Clean README but risks hiding existing proof surfaces and breaking verifier pins. | |
| Rename commands heavily | Better semantics in isolation but breaks established command expectations. | |

**User's choice:** Add a compact proof ladder under the Start Here path and keep existing command names.

**Notes:** Recommended ladder: Explore -> Focused proof -> Full local gate -> CI wrapper -> Maintainer contracts -> Provider parity. `mix verify` remains focused Fake-backed proof; `mix verify.full` remains CI-equivalent local host gate; live Stripe parity remains scheduled/manual drift detection, not first-run setup.

---

## the agent's Discretion

- Exact README prose, heading names, and table-vs-bullet formatting are left to downstream planning/execution as long as the ordering and truth boundaries in `166-CONTEXT.md` are preserved.
- Downstream agents may add/update focused docs-contract verifier needles if the new README Start Here section becomes load-bearing.

## Deferred Ideas

None — discussion stayed within phase scope.
