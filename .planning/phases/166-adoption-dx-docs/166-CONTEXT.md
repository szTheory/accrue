# Phase 166: Adoption DX Docs - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Adoption-facing documentation for `examples/accrue_host`: add a clear, persona-framed "Start Here" path to the demo README, make Docker setup prominent, and explain the demo/proof commands in terms of what a Phoenix SaaS adopter can inspect and trust. This phase is documentation and adoption DX only; it must not add new billing primitives or broaden provider support.

</domain>

<decisions>
## Implementation Decisions

### Start Here Narrative
- **D-01:** Replace the current caveat-first opening with a compact `## Start Here` section near the top of `examples/accrue_host/README.md`. The first screen should answer: "Can I boot a realistic Phoenix SaaS billing loop locally and know what it proves?"
- **D-02:** Frame the demo as a realistic B2B devtool SaaS/PingPal-style host with seeded accounts, Fake-backed billing, signed webhook ingest, and mounted admin inspection. Keep this to one short value paragraph, not a marketing page.
- **D-03:** Keep truth boundaries visible but not first. The Sigra note should move after the run path: this demo uses Sigra for reproducible signed-in organization billing, while production Accrue apps integrate through `Accrue.Auth`; non-Sigra teams should follow First Hour and Organization Billing.
- **D-04:** Do not front-load support matrix minutiae, Braintree limitations, `swap_plan/3`, `preview_upcoming_invoice/2`, VERIFY-01 internals, Playwright shards, or CI job details before the first successful run path.

### Docker and Native Command Contract
- **D-05:** Make Docker the primary evaluator path because Phase 164 created the containerized DX and Phase 166 explicitly requires Docker commands to be prominent. The recommended top command shape is:

  ```bash
  cd examples/accrue_host
  docker compose up --build
  ```

- **D-06:** Preserve the idiomatic native Phoenix lane immediately after Docker for contributors who already have Elixir, Node, and Postgres installed:

  ```bash
  cd examples/accrue_host
  mix setup
  mix phx.server
  ```

- **D-07:** Avoid two equal "choose your adventure" paths. Docker should be the primary no-local-Postgres evaluator path; native Phoenix should be the secondary contributor path.
- **D-08:** Before the README promises browser access through Docker, planning must verify or fix the Docker browser contract. Current code context indicates `examples/accrue_host/config/dev.exs` may bind the Phoenix endpoint to `127.0.0.1`; a container-published web service usually needs `0.0.0.0` to be reachable at `http://localhost:4000`.
- **D-09:** The README should mention the main Docker footguns tersely: Docker uses `PGHOST=db`, bare-metal defaults to local Postgres, compose currently publishes `5432:5432` and can collide with a local Postgres, named volumes intentionally isolate container deps/builds/node modules, and `docker compose down --volumes` is a cache reset rather than a normal stop command.
- **D-10:** Do not recommend Alpine or deleting `deps`, `_build`, or `assets/node_modules` casually. Phase 164 chose Debian slim to avoid NIF issues and named volumes to prevent host/container binary conflicts.

### Proof and Evidence Ladder
- **D-11:** Add a compact proof ladder after the happy path, not before it. The cohesive ladder is: Explore -> Focused proof -> Full local gate -> CI wrapper -> Maintainer contracts -> Provider parity.
- **D-12:** Keep existing command names. Do not rename `mix verify`, `mix verify.full`, or `bash scripts/ci/accrue_host_uat.sh`; add plain-English labels around them instead.
- **D-13:** Define command claims precisely:
  - `docker compose up --build` explores the demo app and Postgres locally; it is not a CI-completeness claim.
  - `mix verify` is the fast Fake-backed focused proof of installer boundary, subscription flow, signed webhook ingest, mounted admin, and replay visibility.
  - `mix verify.full` is the CI-equivalent local host gate: install check, bounded proof, compile, assets, full host tests, dev boot smoke, and browser smoke.
  - `bash scripts/ci/accrue_host_uat.sh` is the repo-root CI wrapper used by `host-integration`; it delegates to the full host contract and is not a first-hour adopter step.
  - `scripts/ci/README.md` owns maintainer triage, docs/support/adoption matrix gates, and co-update rules.
  - Live Stripe parity is scheduled/manual provider drift detection; it is not required for everyday local evaluation.
- **D-14:** No live Stripe keys are required for Start Here. The local path should explicitly say it uses `Accrue.Processor.Fake` so Phoenix wiring, database reducers, webhook handling, and admin inspection stay deterministic.
- **D-15:** Link deeper docs by user intent: First Hour = build your own app, Production readiness = ship your own app, Adoption proof matrix = audit proof coverage, `scripts/ci/README.md` = maintainer CI triage.

### Cohesive Recommendation
- **D-16:** Implement one top-of-README adoption flow: a one-paragraph realistic demo frame, Docker-first command, native Phoenix fallback, expected browser destination (`http://localhost:4000`), first walkthrough (`/app/billing` -> start Fake-backed subscription -> `/billing` mounted admin), then `mix verify` as the focused proof.
- **D-17:** Preserve existing proof-lane depth below the Start Here section, but reorganize it so the reader can decide how much confidence they need without confusing first-run setup with maintainer CI evidence.

### the agent's Discretion
Downstream agents may choose exact section headings and final prose, but must preserve the ordering and truth boundaries above. They may add or update focused doc verifier needles if the README top-of-file contract becomes load-bearing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Project Posture
- `.planning/ROADMAP.md` — Phase 166 goal and success criteria for Start Here, Docker commands, and persona-framed docs.
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, DOC-03 definitions.
- `.planning/PROJECT.md` — stable core / demand-driven expansion posture and Accrue's core adopter value.
- `.planning/STATE.md` — current v1.49 position and recent decisions from Phases 164-165.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — adopter-first lens, repo-local truth, idiomatic Elixir/Phoenix comparison, DX/least-surprise preference.

### Prior Phase Decisions
- `.planning/phases/163-realistic-domain-rich-seeds/163-CONTEXT.md` — realistic B2B devtool persona, curated hero accounts, and background seed data.
- `.planning/phases/164-docker-dx-optimized-caching/164-01-SUMMARY.md` — Dockerfile, compose, Debian slim, named volume masking, and NIF/binary conflict decisions.
- `.planning/phases/164-docker-dx-optimized-caching/164-02-SUMMARY.md` — `PGHOST` dual-mode dev database configuration.
- `.planning/phases/165-e2e-automation-shift-left-ci/165-CONTEXT.md` — Fake-first deterministic E2E posture, native Playwright shards, Docker smoke, and live Stripe parity.
- `.planning/phases/165-e2e-automation-shift-left-ci/165-04-SUMMARY.md` — CI E2E integration details and Docker smoke claim boundaries.

### Target Docs and Proof Surfaces
- `examples/accrue_host/README.md` — primary target for Phase 166.
- `examples/accrue_host/docker-compose.yml` — Docker service, port, env, and volume contract that README commands must match.
- `examples/accrue_host/Dockerfile.dev` — dev image contract and Debian slim decision.
- `examples/accrue_host/config/dev.exs` — `PGHOST` and endpoint bind behavior; verify before claiming Docker browser reachability.
- `examples/accrue_host/demo/command_manifest.exs` — existing command taxonomy and proof vocabulary.
- `examples/accrue_host/mix.exs` — `mix setup`, `mix verify`, and `mix verify.full` command definitions.
- `.github/workflows/ci.yml` — `host-docker-smoke`, Playwright E2E, and live Stripe parity CI truth.
- `scripts/ci/README.md` — maintainer CI triage and docs/support contract map.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — proof coverage matrix that should remain linked but not dominate Start Here.
- `accrue/guides/first_hour.md` — canonical build-your-own-app guide.
- `accrue/guides/organization_billing.md` — non-Sigra organization billing path.
- `accrue/guides/production-readiness.md` — ship-your-own-app checklist.

### External Prior Art
- `https://phoenix.hexdocs.pm/up_and_running.html` — Phoenix gets users to a running app quickly, then deeper topics.
- `https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Server.html` — idiomatic native Phoenix `mix phx.server` run path.
- `https://docs.docker.com/compose/gettingstarted/` — Docker Compose foregrounds `docker compose up`/`down` for local multi-service apps.
- `https://playwright.dev/docs/ci` — browser/CI details should be separated from everyday first-run usage.
- `https://docs.stripe.com/testing` — test-mode/provider truth should be explicit without making live credentials part of local evaluation.
- `https://laravel.com/docs/12.x/billing#testing` — Cashier separates billing API usage from testing/provider concerns.
- `https://github.com/pay-rails/pay` — Pay/Rails names provider differences and Fake processor truth while keeping quick adoption paths visible.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/accrue_host/README.md`: already contains capsules, First run, Seeded history, Observability, Production readiness, Proof and verification, and public guide handoff sections. Phase 166 should reorder/summarize, not discard the proof vocabulary.
- `examples/accrue_host/demo/command_manifest.exs`: already defines `first_run`, `seeded_history`, and command modes. Use it as the SSOT for command labels/claims where possible.
- `examples/accrue_host/mix.exs`: defines the user-facing command surface (`mix setup`, `mix verify`, `mix verify.full`) that docs must preserve.

### Established Patterns
- Fake-first deterministic proof is the primary local and merge-blocking story; live Stripe is drift detection, not first-run setup.
- Host app docs should name host-owned boundaries (`Accrue.Auth`, Repo, Oban, runtime secrets, membership policy) without turning the top of the README into a support matrix.
- Docs contracts and verifier needles are common in this repo; if top-level README claims become load-bearing, add or update focused verifier checks rather than relying on prose review.

### Integration Points
- `examples/accrue_host/config/dev.exs` and `examples/accrue_host/docker-compose.yml` must be reconciled with README Docker commands.
- `.github/workflows/ci.yml` Docker smoke should remain aligned with the README's Docker claim.
- `scripts/ci/verify_adoption_proof_matrix.sh` and existing package-doc verifiers may need updates if README wording/anchors change.

</code_context>

<specifics>
## Specific Ideas

- Preferred top flow: "This is the canonical local demo for Accrue and Accrue Admin: a realistic B2B devtool SaaS with seeded accounts, Fake-backed billing, signed webhook ingest, and mounted admin."
- Start Here should direct the reader to open `http://localhost:4000`, use `/app/billing` to start a Fake-backed subscription, inspect `/billing`, then run `mix verify`.
- Keep the Sigra caveat, but make it a concise truth boundary after the run path rather than the README's first impression.
- Use a proof ladder table or compact bullets to distinguish Explore, Focused proof, Full local gate, CI wrapper, Maintainer contracts, and Provider parity.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 166-Adoption DX Docs*
*Context gathered: 2026-06-02*
