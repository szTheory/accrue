# Phase 13: Canonical Demo + Tutorial - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `examples/accrue_host` the canonical local evaluation path for Accrue and document it as a tutorial from clone through first Fake-backed subscription, signed webhook ingest, admin inspection/replay, and focused host tests. This phase clarifies and polishes the local demo/tutorial path; it does not add new billing capability, build a hosted public demo, or make the root README the full adoption front door.

</domain>

<decisions>
## Implementation Decisions

### Demo Entry Path

- **D-01:** Use a hybrid entry architecture with strict ownership: `examples/accrue_host/README.md` is the canonical clone-to-running executable path; `accrue/guides/first_hour.md` is the package-facing tutorial mirror; `scripts/ci/accrue_host_uat.sh` is the CI-equivalent verifier; the root README should only orient and link until Phase 14 expands the adoption front door.
- **D-02:** Do not make the UAT script the first teaching surface. New evaluators should see the Phoenix-order setup steps before being pointed to the full verification command.
- **D-03:** Keep Fake/test/live Stripe positioning visible in the demo docs, but the canonical local demo path must remain Fake-backed and require no live Stripe credentials.

### Seeded Demo Story

- **D-04:** Use two named demo modes: a public-boundary `First run` path and an explicit `Seeded history` evaluation path.
- **D-05:** `First run` is the canonical tutorial story: create a Fake-backed subscription through the host UI/generated facade, post one signed webhook through the real endpoint, then inspect billing state in the mounted admin UI.
- **D-06:** `Seeded history` is allowed for deterministic admin replay/history/browser coverage where the desired state is awkward to create in a short walkthrough, such as a failed/dead webhook ready for replay.
- **D-07:** Seed scripts may use private setup only for evaluation states that users should not imitate. Subscription creation and signed webhook ingest must go through public host boundaries in the tutorial and focused proofs.
- **D-08:** Keep cancellation out of the main tutorial body unless needed as a secondary proof. It can remain in focused tests/browser smoke, but it should not distract from the first subscription, webhook, and admin inspection story.

### Verification Command Contract

- **D-09:** Adopt a `fast + full` verification contract, implemented primarily as package-local Mix aliases in `examples/accrue_host`.
- **D-10:** `cd examples/accrue_host && mix setup` should be the clone-to-ready command for local evaluators.
- **D-11:** Add or preserve a focused `mix verify` alias for the tutorial proof suite: installer boundary, billing facade/subscription flow, signed webhook ingest, admin mount/replay, and other short deterministic host proofs.
- **D-12:** Add or preserve `mix verify.full` as the CI-equivalent local gate that composes the core proof suite plus compile, asset build, dev boot, and browser smoke.
- **D-13:** Keep `bash scripts/ci/accrue_host_uat.sh` as a thin repo-root/GitHub Actions wrapper around the same contract. Do not introduce `make`, `just`, or a sprawl of public split-by-concern commands for this phase.

### Tutorial Drift Guard

- **D-14:** Use a small shared command manifest as the source for canonical ordered command steps and mode labels across host README, First Hour guide, and UAT verification.
- **D-15:** Keep docs human-written. Do not generate large Markdown tutorial sections or adopt Livebook/literate executable docs for this shell-and-Phoenix setup path.
- **D-16:** Expand ExUnit documentation contract tests to verify command order, public API boundary mentions, forbidden private surfaces, and parity between the manifest, `examples/accrue_host/README.md`, `accrue/guides/first_hour.md`, and `scripts/ci/accrue_host_uat.sh`.
- **D-17:** Keep shell/grep-style checks only for narrow fixed invariants such as package versions, links, and required anchors; do not rely on shell grep as the main tutorial drift guard.

### Coherent Recommendation

- **D-18:** The phase should optimize for least surprise in the Phoenix ecosystem: explicit app-local Mix commands, host-owned generated boundaries, Fake-first deterministic local evaluation, human-written ExDoc/README prose, and CI parity available after the user understands the path.

### the agent's Discretion

- Exact name, file format, and location of the shared command manifest.
- Exact implementation shape of `mix verify` and `mix verify.full`, provided the aliases are package-local, documented, and either compose or stay in parity with the root UAT wrapper.
- Exact wording of README/guide labels for `First run` and `Seeded history`.
- Exact ExUnit helper/module names for command-manifest and docs parity checks.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/PROJECT.md` - v1.2 Adoption + Trust goal, Accrue philosophy, brand voice, host-owned integration principles, and current milestone constraints.
- `.planning/REQUIREMENTS.md` - Phase 13 requirements `DEMO-01` through `DEMO-06` and `ADOPT-02`.
- `.planning/ROADMAP.md` - Phase 13 goal and success criteria.
- `.planning/STATE.md` - Current project state and phase position.

### Prior Decisions

- `.planning/phases/10-host-app-dogfood-harness/10-CONTEXT.md` - Canonical `examples/accrue_host` decisions, Fake-backed host flow, signed webhook proof, admin replay proof, and local verification boundary.
- `.planning/phases/12-first-user-dx-stabilization/12-CONTEXT.md` - First Hour guide shape, public API clarity, safe generated-code reruns, setup diagnostics, dependency-mode validation, and host-first docs decisions.

### Demo And Tutorial Surfaces

- `examples/accrue_host/README.md` - Current host example setup path and CI-equivalent command.
- `accrue/guides/first_hour.md` - Package-facing first-hour tutorial that should mirror the canonical host path.
- `accrue/README.md` - Package landing page that currently points to host setup and docs.
- `examples/accrue_host/mix.exs` - Package-local Mix aliases should live here.
- `examples/accrue_host/lib/accrue_host/billing.ex` - Generated host-owned billing facade and public boundary for tutorial examples.
- `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` - User-facing subscription UI used by first-run and browser proof paths.

### Verification And Seeded Evaluation

- `scripts/ci/accrue_host_uat.sh` - Existing full UAT gate and repo-root wrapper.
- `scripts/ci/accrue_host_seed_e2e.exs` - Existing seeded browser/admin replay fixture; should be clearly labeled as evaluation setup, not tutorial API.
- `scripts/ci/accrue_host_browser_smoke.cjs` - Existing browser smoke helper.
- `scripts/ci/accrue_host_hex_smoke.sh` - Existing Hex-mode smoke validation, separate from the canonical local demo.
- `.github/workflows/accrue_host_uat.yml` - CI entrypoint for host UAT.
- `.github/workflows/ci.yml` - Broader CI context and package checks.
- `examples/accrue_host/e2e/phase11-host-gate.spec.js` - Current browser flow that covers subscription, cancel, admin replay, and event history.
- `examples/accrue_host/test/accrue_host/billing_facade_test.exs` - Generated facade proof.
- `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` - User-facing subscription proof.
- `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` - Signed webhook endpoint proof.
- `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` - Admin replay proof.
- `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` - Mounted admin/auth boundary proof.

### Drift Guards And Docs Tests

- `accrue/test/accrue/docs/first_hour_guide_test.exs` - Existing ordered-step and public-boundary docs contract.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Existing package docs verifier test.
- `scripts/ci/verify_package_docs.sh` - Existing fixed-invariant package docs verification script.

### Ecosystem References

- `https://hexdocs.pm/phoenix/mix_phx_gen_auth.html` - Phoenix generator precedent: generated code is host-owned and setup steps are explicit.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` - Mounted Phoenix integration precedent.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` - Router/mount documentation precedent.
- `https://hexdocs.pm/oban/installation.html` - Mature Elixir setup/verification layering precedent.
- `https://hexdocs.pm/elixir/main/writing-documentation.html` - Elixir documentation guidance.
- `https://hexdocs.pm/ex_unit/ExUnit.DocTest.html` - Doctest fit for API examples, not long shell setup flows.
- `https://hexdocs.pm/ex_doc/readme.html` - ExDoc extras and guide structure.
- `https://laravel.com/docs/11.x/billing` - Cashier lessons: concise happy path, webhook caveats, testing guidance.
- `https://github.com/pay-rails/pay` - Pay lessons: fake processor, app-local installation, testing and billing-state setup.
- `https://dj-stripe.dev/docs/dev/installation` - dj-stripe installation lessons around explicit app setup and webhooks.
- `https://dj-stripe.dev/docs/dev/usage/webhooks` - dj-stripe webhook setup lessons.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/accrue_host`: already exists as the single canonical checked-in host app.
- `examples/accrue_host/README.md`: already documents prerequisites, first-hour path, local defaults, and the root UAT command.
- `accrue/guides/first_hour.md`: already follows the Phoenix-order setup path and is covered by docs tests.
- `scripts/ci/accrue_host_uat.sh`: already composes installer idempotence, generated drift detection, compile, assets, focused UAT, full host regression, dev boot, and browser smoke.
- `scripts/ci/accrue_host_seed_e2e.exs`: already creates deterministic browser/admin replay state for the E2E flow.
- `accrue/test/accrue/docs/first_hour_guide_test.exs`: already verifies ordered tutorial steps, public surfaces, and forbidden private surfaces.

### Established Patterns

- Host apps own schemas, Repo, routing, auth/session boundary, and generated `MyApp.Billing`; Accrue owns billing internals and exposes small host-facing facades.
- Fake Processor is the deterministic local test/demo surface; live Stripe remains advisory or explicit and must not be required for the canonical local demo.
- Phoenix/Elixir users expect app-local Mix commands and explicit setup steps over external `make`/`just` wrappers.
- Human-written docs are preferred for teaching; automated checks should enforce command/order/public-boundary drift without turning prose into generated output.
- Private schema inserts are acceptable for test/evaluation fixture setup when clearly labeled, but user-facing tutorial paths should not teach private internals.

### Integration Points

- `examples/accrue_host/mix.exs` should gain or refine package-local aliases such as `setup`, `verify`, and `verify.full`.
- `scripts/ci/accrue_host_uat.sh` should become or remain a thin root wrapper around the full host verification contract.
- Host README and First Hour guide need consistent command ownership and labels for `First run`, `Seeded history`, `mix verify`, and `mix verify.full`.
- Drift checks should connect the shared command manifest, host README, First Hour guide, UAT wrapper, and docs tests.

</code_context>

<specifics>
## Specific Ideas

- Use labels like `First run` for the public-boundary tutorial and `Seeded history` for deterministic replay/history evaluation.
- The first-run path should read like a normal Phoenix app setup: `cd examples/accrue_host`, `mix setup`, `mix phx.server`, then create/inspect billing state.
- The full local gate should stay available as a single command for maintainers and release checks, but not hide the tutorial path from new users.
- Do not add `make`, `just`, generated Markdown sections, or Livebook-based execution for this phase.

</specifics>

<deferred>
## Deferred Ideas

- Root README as the primary public adoption front door belongs to Phase 14.
- Hosted public demo remains out of scope for v1.2 unless a later milestone explicitly adds it.
- Live Stripe tutorial/demo flow remains advisory or later-phase material; Phase 13 canonical path is Fake-backed.

</deferred>

---

*Phase: 13-canonical-demo-tutorial*
*Context gathered: 2026-04-17*
