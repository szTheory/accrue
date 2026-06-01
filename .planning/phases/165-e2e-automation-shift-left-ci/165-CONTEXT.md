# Phase 165: E2E Automation & Shift-Left CI - Context

**Gathered:** 2026-06-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Automating happy-path E2E testing (Playwright) for the realistic demo app (`examples/accrue_host`) and integrating it into GitHub Actions CI to ensure production-readiness, prevent regressions, and enforce a shift-left testing culture.

</domain>

<decisions>
## Implementation Decisions

### CI Execution Environment
- **D-01:** Hybrid Model. The primary CI E2E suite will run natively using Elixir/Node in GitHub Actions to maximize speed, caching, and parallelization. We will also add a separate release-blocking Docker job to ensure the "zero-friction" local container experience (developed in Phase 164) remains fully functional.

### Test State Management
- **D-02:** Ecto Sandbox for E2E. We will configure E2E tests to use `Ecto.Adapters.SQL.Sandbox` via the `Phoenix.Ecto.Sandbox` plug. This is the idiomatic Elixir approach to bridge server and browser tests, allowing us to drop slow sequential DB resets and safely run tests concurrently in isolated transactions.

### Processor Fidelity
- **D-03:** "Fake-First" with Periodic Live Checks. We will rely exclusively on Accrue's built-in `Fake` processor for the primary E2E suite to guarantee 100% network determinism, zero flakiness, and fast local DX. We will promote the existing advisory live-Stripe test job into a mandatory periodic check to catch API drift without slowing down everyday PRs.

### CI Parallelization
- **D-04:** Playwright Parallel Sharding. Because the Ecto Sandbox isolates test state, we will enable `fullyParallel: true` in Playwright and configure GitHub Actions to run tests across multiple workers/shards, slashing CI time.

### Claude's Discretion
The exact configuration of Playwright sharding (number of workers) and GitHub Actions matrix setup is left to the planner to optimize for speed vs cost.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definitions
- `.planning/ROADMAP.md` — Milestones and goals.
- `.planning/REQUIREMENTS.md` — Core requirements for Phase 165 (E2E-01 to E2E-04).

### Prior Context
- `.planning/phases/163-realistic-domain-rich-seeds/163-CONTEXT.md` — Seed context and database volume to account for in test setups.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/accrue_host/playwright.config.js`: Needs updates for workers and `fullyParallel`.
- `Accrue.Processor.Fake`: The deterministic processor already built into Accrue.

### Established Patterns
- `Phoenix.Ecto.Sandbox`: Pattern for passing the sandbox metadata from the browser to the backend via HTTP headers or user-agent to ensure the server runs the request inside the correct Ecto transaction.

### Integration Points
- `.github/workflows/ci.yml`: The primary integration point for adding E2E test steps, parallel shards, and the Docker environment sanity check.

</code_context>

<specifics>
## Specific Ideas

- The goal is zero flake. A test that fails 1% of the time is worse than no test. Prioritize determinism (via `Fake` processor and Ecto Sandbox) over absolute end-to-end network fidelity on every single commit.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 165-E2E Automation & Shift-Left CI*
*Context gathered: 2026-06-01*
