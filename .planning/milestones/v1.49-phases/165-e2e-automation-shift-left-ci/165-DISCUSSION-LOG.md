# Phase 165: Discussion Log

*For human reference only. Not consumed by downstream agents.*

## 1. CI Execution Environment
- **Presented options:** Docker environment vs Native Elixir/Node.
- **Selection:** Hybrid Model.
- **Notes:** Use Native Elixir/Node for the main suite to optimize speed/cache, but add a release-blocking Docker job to ensure local DX container works.

## 2. Test State Management
- **Presented options:** DB Reset vs Ecto Sandbox vs Snapshot.
- **Selection:** Ecto Sandbox via Phoenix.Ecto.Sandbox plug.
- **Notes:** Idiomatic Elixir approach. Provides isolation, prevents state bleed, and enables concurrent test execution.

## 3. Processor Fidelity
- **Presented options:** Fake processor vs Live Stripe keys.
- **Selection:** "Fake-First" + Periodic Live Checks.
- **Notes:** Focus on 100% determinism to prevent flaky tests. The Fake processor provides the best DX. Stripe fidelity is caught by a secondary job.

## 4. CI Parallelization
- **Presented options:** Sequential vs Parallel Sharding.
- **Selection:** Playwright Parallel Sharding.
- **Notes:** Achievable because of the Ecto Sandbox decision. Drastically reduces CI time.
