# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- 🚀 **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (current)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. This milestone (v1.49) focuses on adoption evidence, creating a highly realistic, "click-around" demo app with rich seeds, E2E automation, and frictionless Docker DX.

Future feature milestones require at least one of:
- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

## Phases

### v1.49 Realistic Demo App & Adoption Evidence (Current)

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 163 | Realistic Domain & Rich Seeds | Define persona and populate rich database seeds for demo app | EVD-01, EVD-02 | 3 |
| 164 | Docker DX & Optimized Caching | Create a seamless, fast Docker local dev environment | EVD-03, EVD-04 | 3 |
| 165 | E2E Automation & Shift-Left CI | 1/4 | In Progress|  |
| 166 | Adoption DX Docs | Write simple, persona-framed "Start Here" guides | DOC-01, DOC-02, DOC-03 | 3 |

### Phase Details

### Phase 163: Realistic Domain & Rich Seeds
Goal: Define persona and populate rich database seeds for demo app
**Plans:** 1 plans

Plans:
- [x] 163-01-PLAN.md — Extract and seed PingPal persona and background data

Requirements: EVD-01, EVD-02
Success criteria:
1. Persona and JTBD are documented.
2. Seed scripts generate a realistic set of users, plans, and subscriptions.
3. Seeded data successfully showcases the Admin UI features.

### Phase 164: Docker DX & Optimized Caching
Goal: Create a seamless, fast Docker local dev environment
**Plans:** 2 plans

Plans:
- [x] 164-01-PLAN.md — Create Docker environment config and volume masking
- [x] 164-02-PLAN.md — Update app config to support Docker Postgres host

Requirements: EVD-03, EVD-04
Success criteria:
1. Dockerfile and docker-compose.yml are created/updated.
2. Tailwind and Hex dependencies are effectively cached.
3. Developer can spin up the app with one simple command.

### Phase 165: E2E Automation & Shift-Left CI
Goal: Automate happy paths with Playwright and integrate to CI
Requirements: E2E-01, E2E-02, E2E-03, E2E-04
Success criteria:
1. Playwright tests cover onboarding and checkout.
2. Playwright tests cover subscription changes and billing management.
3. Tests run reliably in CI against seeded data.
4. Zero flake in deterministic tests.

### Phase 166: Adoption DX Docs
Goal: Write simple, persona-framed "Start Here" guides
Requirements: DOC-01, DOC-02, DOC-03
Success criteria:
1. README has a clear "Start Here" section.
2. Docker setup commands are prominently documented.
3. Docs are framed around the user persona's goals.

<details>
<summary>✅ v1.48 Release Readiness + Stable Core Posture (Phases 159-162) — SHIPPED 2026-06-01</summary>

- [x] Phase 159: Linked Release Readiness + Publish Proof (2/2 plans) — completed 2026-06-01
- [x] Phase 160: Stable-Core Public Positioning (3/3 plans) — completed 2026-05-31
- [x] Phase 161: Backlog Anchor Closure + Pause Rule (1/1 plan) — completed 2026-06-01
- [x] Phase 162: Close gap: REL-01/REL-03 — linked release proof (4/4 plans) — completed 2026-06-01

Full details: [v1.48 roadmap archive](milestones/v1.48-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 159. Linked Release Readiness + Publish Proof | v1.48 | 2/2 | Complete | 2026-06-01 |
| 160. Stable-Core Public Positioning | v1.48 | 3/3 | Complete | 2026-05-31 |
| 161. Backlog Anchor Closure + Pause Rule | v1.48 | 1/1 | Complete | 2026-06-01 |
| 162. Close gap: REL-01/REL-03 | v1.48 | 4/4 | Complete | 2026-06-01 |
| 163. Realistic Domain & Rich Seeds | v1.49 | 1/1 | Complete | 2026-06-01 |
| 164. Docker DX & Optimized Caching | v1.49 | 0/2 | Pending | |
| 165. E2E Automation & Shift-Left CI | v1.49 | 0/4 | Pending | |
| 166. Adoption DX Docs | v1.49 | 0/3 | Pending | |