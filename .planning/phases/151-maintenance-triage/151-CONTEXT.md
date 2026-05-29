# Phase 151: Maintenance & Triage - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Routine maintenance, issue triage, and repository cleanup to prepare Accrue for a stable closure milestone (v1.46). No new functional capabilities are introduced.

</domain>

<decisions>
## Implementation Decisions

### Triage priority
- **D-01:** "Clean Room" Triage & Money-Safety First. Establish a strict priority tier: Tier 1: Core Billing/Money-Safety & Provider Sync drift. Tier 2: `docs-contracts-shift-left` and Adoption Proof Matrix failures. Tier 3: Planning tooling friction. Defer any new feature requests to "Post-1.x".

### Dependency updates
- **D-02:** "Final Stable Bump & Pin" (Conservative Minor/Patch). Run a final `mix deps.update --all` for minor/patch versions. Run the full test suite (`test` + `dialyzer` + `credo`). If green, lock them. Do not bump any major versions. Update `mix.exs` to reflect the latest compatible ranges. This ensures maximum compatibility and shelf-life before BitRot sets in.

### Closure criteria
- **D-03:** "The Three Zeros". Explicitly define closure as: 1. All P0/P1 triage items are closed. 2. Zero audit gaps (successful, clean run of `verify_adoption_proof_matrix.sh` and `verify_package_docs`). 3. Zero Nyquist (test coverage) gaps missing. 4. A final Hex publish patch release with matching Git tags.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)**
  Original Problem: Pending code-review feedback regarding caching logic in webhooks.
  Fit: Resolving technical debt and implementing code-review feedback fits perfectly within the maintenance and triage scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project State & Assessment
- `.planning/PROJECT.md` — Current milestone goal (v1.46 Maintenance & Closure).
- `.planning/STATE.md` — Posture ("Intake-Gated").
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` — Defines "What 'done' means" for an adopter.

### Triage Framework
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — Defines existing tech debt priority axes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix test`, `mix dialyzer`, `mix credo`: Standard Elixir verification tools to validate dependency updates.
- `scripts/ci/verify_adoption_proof_matrix.sh`: Must be used to validate the closure criteria.

### Established Patterns
- The `docs-contracts-shift-left` script bundle in `scripts/ci/` which serves as the final gatekeeper for documentation honesty.

### Integration Points
- `mix.exs` and `mix.lock` at the root of `accrue`, `accrue_admin`, and `accrue_portal`.

</code_context>

<specifics>
## Specific Ideas

The user explicitly requested idiomatic Elixir approaches emphasizing money-safety, stable deterministic dependencies, and "The Three Zeros" closure criteria learned from established billing libraries (like Laravel Cashier/Rails Pay) to ensure robust developer ergonomics.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 151-Maintenance & Triage*
*Context gathered: 2026-05-29*
