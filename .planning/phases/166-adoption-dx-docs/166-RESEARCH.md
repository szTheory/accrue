# Phase 166: Adoption DX Docs - Research

**Researched:** 2026-06-02
**Status:** Ready for planning

## Research Question

What do I need to know to plan Phase 166 well?

Phase 166 is an adoption-facing documentation phase for `examples/accrue_host`. The planner should treat the primary deliverable as a top-of-README adoption flow, not a broad docs rewrite. The one non-doc prerequisite is Docker reachability: the README cannot honestly make `docker compose up --build` the primary evaluator path until the Phoenix endpoint is reachable through Compose's published `4000:4000` port.

## Local Findings

### Target Surface

- `examples/accrue_host/README.md` currently opens with a Sigra caveat and support-matrix detail before the first successful run path.
- The current `## First run` path is native Phoenix first:
  - `cd examples/accrue_host`
  - `mix setup`
  - `mix phx.server`
- The README already has useful proof vocabulary: `mix verify`, `mix verify.full`, `bash scripts/ci/accrue_host_uat.sh`, `scripts/ci/README.md`, `docs/adoption-proof-matrix.md`, `VERIFY-01`, seeded history, visual walkthrough, and mounted admin mobile shell.
- The plan should preserve these deeper sections but reorder the top so evaluators can boot and understand the demo before reading maintainer proof depth.

### Docker Contract

- `examples/accrue_host/docker-compose.yml` defines:
  - `db` with Postgres 15, published as `5432:5432`.
  - `web`, built from `examples/accrue_host/Dockerfile.dev`, published as `4000:4000`.
  - `PGHOST: db` for container database connectivity.
  - named volumes for `deps`, `_build`, and `assets/node_modules`.
- `examples/accrue_host/Dockerfile.dev` uses `elixir:1.17-slim`, installs build tools, Postgres client, Node, npm, Hex, and Rebar, and runs `mix setup && mix phx.server`.
- `examples/accrue_host/config/dev.exs` already supports Docker database connectivity with `hostname: System.get_env("PGHOST") || "localhost"`.
- `examples/accrue_host/config/dev.exs` currently binds the Phoenix endpoint to loopback only:
  - `http: [ip: {127, 0, 0, 1}]`
- Because Compose publishes `4000:4000`, the web process usually needs to listen on `0.0.0.0` inside the container for `http://localhost:4000` on the host to work. Phase 165's CI Docker smoke polls `http://localhost:4000/`, so the planner should include a task to make this contract explicit and verified before docs lean on it.

### Command Truth

- `examples/accrue_host/mix.exs` defines the command surface:
  - `mix setup`: `deps.get`, database setup, asset setup/build.
  - `mix verify`: bounded Fake-backed proof via `scripts/ci/accrue_host_verify_test_bounded.sh`.
  - `mix verify.full`: install check, bounded proof, compile, assets, full host regression, dev boot smoke, browser gate.
- `examples/accrue_host/demo/command_manifest.exs` already provides a compact taxonomy:
  - `first_run`
  - `seeded_history`
  - `command_modes`
  - `story_artifacts`
- The command manifest still names native `mix setup` / `mix phx.server` as the first-run command lane. Since Phase 166 makes Docker primary, planning should decide whether to update this manifest to include Docker-first evaluator vocabulary or keep it as native command vocabulary only. If README prose begins relying on a new command taxonomy, the manifest should be co-updated.

### Existing Doc Gates

- `scripts/ci/verify_package_docs.sh` pins host README structural sections and command strings:
  - `## First run`
  - `## Seeded history`
  - `## Proof and verification`
  - `### Verification modes`
  - `mix setup`
  - `mix phx.server`
  - `/webhooks/stripe`
- `scripts/ci/verify_verify01_readme_contract.sh` pins VERIFY-01 / proof-depth details in the host README:
  - `VERIFY-01`
  - `accrue_host_seed_e2e.exs`
  - `npx playwright test`
  - `host-integration`
  - `bash scripts/ci/verify_adoption_proof_matrix.sh`
  - `bash scripts/ci/accrue_host_uat.sh`
  - `scripts/ci/README.md`
  - `mix verify.full`
  - provider-honest support wording
- `scripts/ci/README.md` explicitly says edits to `examples/accrue_host/README.md` proof sections should be checked against First Hour and the relevant verifier scripts.
- The plan should include verifier runs for host README edits. It should only update verifier needles when the new Start Here section adds a load-bearing claim that should be pinned.

### Persona and Truth Boundary

- Phase 163 established the realistic demo domain: a B2B devtool SaaS / PingPal-style host with seeded accounts.
- Phase 166 context requires the top of the README to answer: "Can I boot a realistic Phoenix SaaS billing loop locally and know what it proves?"
- The top flow should frame the demo around:
  - realistic seeded SaaS context,
  - Fake-backed billing,
  - signed webhook ingest,
  - mounted admin inspection,
  - no live Stripe keys needed for local evaluation.
- The Sigra truth boundary remains important, but should move after the run path:
  - production apps integrate through `Accrue.Auth`,
  - Sigra is used here for deterministic signed-in org billing,
  - non-Sigra teams should follow First Hour and Organization Billing.

## External Prior Art

- Docker Compose documentation foregrounds `docker compose up` as the single command that creates and starts services, then directs the user to open a localhost URL. It also treats `docker compose down -v` as an intentional volume-removal reset, not a normal stop command.
- Phoenix's `mix phx.server` documentation defines it as the normal task for starting endpoint servers. That supports keeping a native Phoenix lane directly under the Docker evaluator path.
- Playwright CI documentation separates everyday test execution from browser/CI setup. That supports keeping Playwright shards and browser details below the first-run path, not above it.
- Stripe testing documentation reinforces the distinction between test-mode/provider checks and local deterministic proof. For this phase, local README copy should say live Stripe keys are not required for Start Here.

## Planning Implications

### Recommended Plan Shape

Use three focused plans:

1. **Docker truth and command contract**
   - Fix or verify Phoenix endpoint bind behavior for Docker reachability.
   - Verify `docker compose config` and the host-published `http://localhost:4000` claim where feasible.
   - Update command taxonomy only if needed for Docker-first docs.

2. **README Start Here rewrite**
   - Add a compact `## Start Here` near the top.
   - Make Docker primary:
     - `cd examples/accrue_host`
     - `docker compose up --build`
   - Keep native Phoenix directly after it:
     - `cd examples/accrue_host`
     - `mix setup`
     - `mix phx.server`
   - Describe expected browser destination and walkthrough:
     - open `http://localhost:4000`,
     - use `/app/billing`,
     - start a Fake-backed subscription,
     - inspect `/billing`,
     - run `mix verify`.
   - Move Sigra and support-matrix caveats after the run path.

3. **Proof ladder and docs contracts**
   - Reorganize proof depth into Explore -> Focused proof -> Full local gate -> CI wrapper -> Maintainer contracts -> Provider parity.
   - Keep existing command names intact.
   - Update verifier needles only if the new top-level Start Here contract should be protected.
   - Run docs contract scripts plus targeted Markdown checks.

### Risks

- If the planner produces only README prose, Phase 166 can still fail because Docker-first instructions may be false with the current endpoint bind.
- If the top README removes pinned strings, `verify_package_docs.sh` or `verify_verify01_readme_contract.sh` will fail.
- If support-matrix details are moved too aggressively, provider-honest guardrails can regress. The plan should preserve support wording somewhere below Start Here.
- If Docker commands use `docker compose down --volumes` as a normal stop command, users may accidentally wipe local state. Present it as a reset/cleanup command only.

## Validation Architecture

Phase 166 can be validated with a docs-first but behavior-aware strategy:

- Source assertions:
  - `examples/accrue_host/README.md` contains `## Start Here`.
  - The Start Here section contains `docker compose up --build`.
  - The Start Here section mentions `http://localhost:4000`, `/app/billing`, `/billing`, `Accrue.Processor.Fake`, and `mix verify`.
  - The README still contains `### Capsule H`, `### Capsule M`, `### Capsule R`, `## Proof and verification`, `### Verification modes`, and `VERIFY-01`.
  - `examples/accrue_host/config/dev.exs` does not make Docker browser reachability impossible.
- Script assertions:
  - `bash scripts/ci/verify_package_docs.sh`
  - `bash scripts/ci/verify_verify01_readme_contract.sh`
  - `bash scripts/ci/verify_adoption_proof_matrix.sh` if matrix/proof wording moves.
- Docker assertions:
  - `cd examples/accrue_host && docker compose config`
  - Prefer an actual smoke equivalent to Phase 165 CI when local Docker is available:
    `cd examples/accrue_host && docker compose up --build -d`, poll `http://localhost:4000/`, then `docker compose down --volumes --remove-orphans`.
- General docs hygiene:
  - `git diff --check -- examples/accrue_host/README.md scripts/ci/verify_package_docs.sh scripts/ci/verify_verify01_readme_contract.sh examples/accrue_host/config/dev.exs examples/accrue_host/demo/command_manifest.exs`

## Research Complete

Planning should proceed with the Start Here docs as the primary deliverable and the Docker browser contract as a prerequisite correctness task.
