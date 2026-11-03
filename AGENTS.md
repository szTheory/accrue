# Agent instructions

## Execution and approvals

- Carry authorized work through the required implementation, verification, review, and bookkeeping steps without asking for confirmation at each routine step.
- Use judgment for routine, reversible, in-scope choices and apply the user's stated recommendations directly. Ask only when the choice is materially controversial or has significant implications for safety, privacy, cost, public impact, or irreversibility.
- Treat a plain-language instruction such as “go ahead and do it” as authorization for the specific recommended action in context. Do not ask again for that action or its ordinary implementation details.
- When a plan contains a named owner checkpoint, check whether the user's current instruction already selects or clearly authorizes the recommendation. Ask only if authorization remains genuinely ambiguous or the choice introduces a material new consequence.
- Report concrete blockers and consequential decisions plainly. Avoid turning plan steps, test commands, routine commits, or previously authorized pushes into separate approval requests.
- When working on browser or CI paths, inspect the measured critical path and duplicated setup, then apply low-risk, evidence-backed optimizations within the authorized scope while preserving coverage and gate strength.
- Prefer reusing an already available cache or build artifact when measurements show repeated critical-path work; capture before/after timings when a follow-up run can verify the savings.
