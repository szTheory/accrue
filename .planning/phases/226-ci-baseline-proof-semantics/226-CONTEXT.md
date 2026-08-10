# Phase 226: ci-baseline-proof-semantics - Context

**Gathered:** 2026-08-10
**Status:** Ready for re-planning

<domain>
## Phase Boundary

Repair and publish a durable, privacy-safe, comparable CI-run baseline so maintainers can distinguish the actual critical path, setup ownership, and provider proof state. This is CI evidence and maintainer-DX work: it must not alter CI topology, required-check identity, matrix breadth, branch protection, cache topology, or product/UI behavior. The current phase verification found BASE-01 and BASE-02 incomplete; replanning must close those deterministic contract and evidence gaps before Phase 227 consumes the baseline.

</domain>

<decisions>
## Implementation Decisions

### Comparable Cohort Validity
- **D-01:** A valid baseline is exactly three qualifying green `workflow_dispatch` runs, all attempt 1. The anchor and two new runs must retain explicit ref/SHA provenance, workflow-blob equality, and equality for the six critical-chain lockfile blobs. Reruns are retained only as non-comparable diagnostics and never replace a cohort run. — **Reversibility:** costly — Phase 227 selection, checked-in evidence, and the contract all depend on this stable measurement policy.
- **D-02:** Every eligible run must record queue, root-failure-signature, cache, and setup facts. A provider-omitted fact may be `null` only with a field-specific omission reason; absent facts without that reason reject the baseline. Never estimate a missing timing value.
- **D-03:** Record root failure as a normalized, privacy-safe signature ID with category and affected jobs, not raw logs, traces, test payloads, or excerpts.
- **D-04:** Report `observed-hit` only when an explicit cache-action output proves it. A skipped setup step is at most `inferred setup bypass`; otherwise use `unknown`. Do not equate duration or skipped work with an exact cache-key hit.

### Proof Semantics And Provider Authority
- **D-05:** Preserve three independent lane facts: declared policy (`required`, `advisory`, `conditional`), observed conclusion, and proof state (`proved`, `skipped`, `advisory`, `not-applicable`). Aggregate proof is fail-closed: only qualifying, required, successful, eligible attempt-1 lanes may be `proved`; all other states cannot satisfy release proof. — **Reversibility:** costly — changing it would invalidate published evidence vocabulary and the contract consumers that rely on it.
- **D-06:** Treat GitHub effective-rules and classic branch-protection results as a timestamped provider snapshot only. Workflow YAML expresses the repository proof taxonomy, never external branch-protection enforcement. An old empty/404 snapshot must not be described as a claim about current provider configuration.
- **D-07:** Replace heuristic job-name classification with a checked-in, versioned workflow-policy manifest or snapshot. Unknown identities must reject validation rather than silently defaulting to a proof state. — **Reversibility:** costly — policy mapping is a trusted interpretation boundary for all future baseline records.
- **D-08:** A confirmed authenticated `404` may be `not-found`; permission, network, malformed-response, or provider API errors must be represented as an error state and block a `none-enforced` conclusion.

### Maintainer Experience And Safe Scope
- **D-09:** Keep `scripts/ci/README.md` as the one command-first triage home. Add or preserve a concise “choose your situation” route for baseline/proof validation, host/browser reproduction, package-level host verification, and CI observation. Do not create a dashboard, a competing guide, or a new bootstrap system.
- **D-10:** Keep the ownership matrix as the maintainer interface: owner → first diagnostic → expected signal → bounded safe next action for Node/npm, browser/Playwright, Postgres, fixtures, ports, and server lifecycle. Say local host verification uses the same host verification contract; do not call it CI-equivalent.
- **D-11:** Use precise, non-color-dependent, copyable vocabulary: “repository proof taxonomy,” `proved`, `skipped`, `advisory`, and `not-applicable`. Lead every failure path with the fact and one next command. Raw logs/traces remain Actions artifacts rather than checked-in baseline content.
- **D-12:** Recovery guidance must be bounded and safe: identify prerequisites/fallbacks, remove only local `node_modules` when appropriate, and never prescribe broad destructive cleanup. Phase 226 remains a metadata-only repository-local Bash/`gh`/`jq` adapter; no Plug routes, Ecto schemas, Phoenix telemetry, database persistence, or product UI are warranted.

### the agent's Discretion
- Choose the exact manifest shape, signature normalization algorithm, Markdown layout, and negative-control fixtures, provided D-01 through D-12 are enforced with deterministic tests.
- Preserve the existing stable CI graph, release matrix, advisory Sigra designation, `fail-fast: false`, Phase 192 artifacts, and shift-left contract location established by Phase 225.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, Requirements, And Prior Decisions
- `.planning/PROJECT.md` — v1.61 stable-core maintenance posture, CI-evidence goal, and non-goals.
- `.planning/ROADMAP.md` — Phase 226 goal, BASE-01/BASE-02/OWN-01 success criteria, and Phase 227 boundary.
- `.planning/REQUIREMENTS.md` — binding BASE-01, BASE-02, OWN-01, PATH-01/02, and SAFE-01/02 allocation.
- `.planning/STATE.md` — current project state and CI guardrails.
- `.planning/phases/225-required-lane-signal-repair/225-CONTEXT.md` — stable job identity, matrix, retry, artifact, required/advisory, and no-mask constraints carried into this phase.

### Current Evidence, Research, And Verification
- `.planning/phases/226-ci-baseline-proof-semantics/226-RESEARCH.md` — original comparable-cohort design, privacy contract, proof taxonomy, ownership matrix, and measured baseline research.
- `.planning/phases/226-ci-baseline-proof-semantics/226-VERIFICATION.md` — authoritative 11/14 verification gaps that replanning must close: required root signature, all-run queue evidence, and fail-closed cohort/proof/provenance validation.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json` — machine-readable current cohort record and Phase 227 selection inputs; treat it as evidence to repair, not proof that the verification gaps are closed.
- `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` — human rendering of the current record and staged critical-path interpretation.
- `.planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md` — existing CI/host ownership and diagnostic matrix to preserve and improve.
- `.planning/phases/226-ci-baseline-proof-semantics/226-01-PLAN.md` — original collector/privacy/proof plan and constraints.
- `.planning/phases/226-ci-baseline-proof-semantics/226-02-PLAN.md` — original cohort/provenance and Phase 227 input plan.
- `.planning/phases/226-ci-baseline-proof-semantics/226-03-PLAN.md` — original ownership/documentation and topology-preservation plan.

### CI Implementation And Maintainer Interfaces
- `.github/workflows/ci.yml` — stable CI identities, dependency graph, matrix support semantics, and shift-left location.
- `scripts/ci/capture_ci_baseline.sh` — metadata-only collector; current heuristic classification and provider-error handling must be revised to match D-04, D-07, and D-08.
- `scripts/ci/verify_ci_baseline_contract.sh` — current contract; must become fail-closed for the cohort, required proof, provenance, queue, and root-signature invariants.
- `scripts/ci/README.md` — canonical command-first contributor/maintainer entry point.
- `scripts/ci/accrue_host_uat.sh` — host setup/reproduction owner script.
- `scripts/ci/accrue_host_verify_browser.sh` — browser/server lifecycle diagnostic owner script.
- `examples/accrue_host/README.md` — host prerequisites and local verification framing.

### Project Research, Hygiene, And Voice
- `prompts/GSD-REPO-HYGIENE.md` — local-first validation, deliberate push/watch workflow, and repository-safe hygiene.
- `prompts/accrue-best-practices-deep-research-independent.md` — project-specific engineering, architecture, DX, and quality lenses.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — adopter-first, evidence-led, coherent recommendation lenses.
- `brandbook/voice.md` — authoritative measured, exact, native, durable voice for maintainer-facing copy.
- `brandbook/copy.md` — plain-language microcopy conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/capture_ci_baseline.sh` already has strict shell posture (`set -euo pipefail`), temporary-directory cleanup, numeric input validation, versioned `gh api`, and immediate `jq` allowlist reduction; extend it rather than introduce application code.
- `scripts/ci/verify_ci_baseline_contract.sh` already owns fixture self-tests and stable-CI-topology checks; extend its input invariants and negative controls rather than adding a second validator.
- `scripts/ci/README.md`, `scripts/ci/accrue_host_uat.sh`, and `scripts/ci/accrue_host_verify_browser.sh` already form the contributor triage and host/browser diagnostic path.

### Established Patterns
- The project uses phase-local, checked-in, machine-readable evidence plus concise human Markdown renderings; raw diagnostics remain GitHub artifacts.
- Phase 225 distinguishes required and advisory evidence explicitly and forbids identity/topology/matrix/retry masking as a repair path.
- CI contract scripts protect the existing workflow from accidental semantic or topology drift through static checks and deterministic fixture tests.

### Integration Points
- The collector reads GitHub Actions run/job/artifact and branch-policy metadata; its output is the canonical JSON baseline.
- The contract validates that JSON and runs once in the existing `docs-contracts-shift-left` job without adding a new check identity or changing the dependency graph.
- The ownership runbook links CI-side setup to the existing host scripts and README, not to new wrappers.

</code_context>

<specifics>
## Specific Ideas

- The user asked for breadth-and-depth research synthesized into coherent recommendations across architecture, DevOps/SRE, DX, user journeys, least surprise, privacy, safety, and maintainability; recommendations above are intentionally mutually reinforcing.
- UI/graphic design is not applicable to this phase beyond accessible documentation and CLI ergonomics: semantic status labels, readable tables, exact microcopy, and copyable commands.
- The canonical maintainer jobs are: identify a CI-proof failure and next action; reproduce a host/browser failure safely; and make a defensible Phase 227 optimization decision from measured evidence.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. CI matrix/cache/topology/branch-protection changes and the measured optimization remain Phase 227 work.

</deferred>

---

*Phase: 226-ci-baseline-proof-semantics*
*Context gathered: 2026-08-10*
