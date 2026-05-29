# Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Mechanical milestone-closure work for v1.46. Reconcile the v1.46 build milestone
(the unreleased feature batch accumulated across phases 143–151: dunning analytics,
recovery funnel/dashboard, in-app dunning banners, ENT-10 webhook fix, dependency
bumps) into a clean, **published linked Hex release** of the three-package trio
(`accrue`, `accrue_admin`, `accrue_portal`) with matching Git tags.

Three named gaps to close:
1. **`@since` warnings** — fix the malformed `@since` annotations.
2. **Verification** — run the "Three Zeros" closure gate green.
3. **Hex publish + tag** — cut the linked release.

No new functional capability is introduced. Discussion clarified HOW to close
these gaps, not WHETHER to add anything.

</domain>

<decisions>
## Implementation Decisions

### Release version (the one irreversible, published decision)
- **D-01:** Target **`1.3.0`** for the linked publish across all three packages
  (`accrue`, `accrue_admin`, `accrue_portal`). This is the Release Please
  linked-versions computed bump: 16 `feat:` commits and **no breaking changes**
  since `accrue-v1.2.0` ⇒ a single minor bump ⇒ `1.3.0`. Do NOT manually pin to
  `1.4.0`. Let the pipeline compute the version; do not override the manifest.
  (User-confirmed fork — published/irreversible.)

### `@since` annotation fix
- **D-02:** The "warnings" are **malformed docstrings, not real attributes.** All
  7 occurrences are stray `@since "1.4.0"` lines sitting *inside* `@doc """ … """`
  heredocs, so they render as literal junk text in ExDoc output (they are NOT
  `@since` module attributes — there is no compiler-attribute warning to suppress).
  - Locations: `accrue/lib/accrue/analytics/dunning.ex` (5×, near lines 50, 98,
    159, 224, 333) and `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`
    (1× the doc heredoc at line 27; grep reports 2 hits in this file — confirm
    during planning).
  - **Fix:** Convert each stray line to canonical, ExDoc-recognized
    **`@doc since: "1.3.0"`** metadata (placed as a `@doc` option, not inside the
    heredoc). Renders a proper "(since 1.3.0)" badge. **Version must be `1.3.0`**
    to match D-01 — the stray `1.4.0` was wrong on both counts (malformed AND
    wrong number).
  - Do **not** simply delete them — the "introduced-in" metadata is worth keeping
    in canonical form.

### Verification ("The Three Zeros" — carried from Phase 151 D-03)
- **D-03:** Closure gate is the already-locked Three Zeros, run green before
  publish: (1) all P0/P1 triage closed, (2) zero audit gaps — clean
  `verify_package_docs.sh` + `verify_adoption_proof_matrix.sh` (+ the release
  contract / manifest / notes scripts), (3) zero Nyquist/coverage gaps, plus full
  `mix test` / `mix dialyzer` / `mix credo` across the trio. Phase 151-03 already
  WIRED ExCoveralls into `accrue` and set summary thresholds (`accrue_admin` 80,
  `accrue_portal` 75) — these are the ratified baseline, not a masking workaround;
  do not lower them. Known flake: `PdfTest` (dodge with `--seed 0`, per memory).

### Publish + tag mechanism (locked by precedent)
- **D-04:** Publish via the established **Release Please linked-versions pipeline**:
  the release PR (single PR, `separate-pull-requests: false`) bumps `@version` in
  all three `mix.exs` + `.release-please-manifest.json` + CHANGELOGs, then merge
  triggers `mix hex.publish` and the linked tags `accrue-v1.3.0`,
  `accrue_admin-v1.3.0`, `accrue_portal-v1.3.0`. Follow `RELEASING.md`. The
  `accrue_admin`/`accrue_portal` → `accrue` version pins (`== @version` /
  `~> @version`) must resolve to `1.3.0`. Reconcile the hand-written CHANGELOG
  "Unreleased" sections against the Release-Please-generated entries during the
  release PR (do not duplicate).

### Claude's Discretion
- Exact ordering of the closure tasks (fix `@since` → run gate → cut release PR)
  and how the CHANGELOG "Unreleased" content is folded are left to the planner.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Release process & versioning
- `RELEASING.md` — Full linked-release runbook (Release Please flow, `mix hex.publish`, tag scheme).
- `release-please-config.json` — `linked-versions` plugin grouping the 3 packages; `separate-pull-requests: false`, `include-component-in-tag: true`, `release-type: elixir`.
- `.release-please-manifest.json` — Current pinned versions (all `1.2.0`); the file Release Please bumps to `1.3.0`.
- `scripts/ci/verify_release_contract.sh`, `scripts/ci/verify_release_manifest_alignment.sh`, `scripts/ci/verify_release_notes_contract.sh`, `scripts/ci/verify_release_pr_scope.sh` — Release-PR gate scripts.
- `scripts/ci/gh_merge_release_pr.sh`, `scripts/ci/repair_linked_release_pr.sh` — Release PR merge/repair helpers.

### Closure gate ("Three Zeros")
- `.planning/phases/151-maintenance-triage/151-CONTEXT.md` §D-03 — The "Three Zeros" closure definition this phase finishes.
- `.planning/phases/151-maintenance-triage/151-03-SUMMARY.md` — What 151-03 validated (CI scripts + coverage wiring).
- `scripts/ci/verify_package_docs.sh` — Docs-honesty gate (note: a new doc needle here must also be added to `PackageDocsVerifierTest` `seed_tmp_dir!`, per memory).
- `scripts/ci/verify_adoption_proof_matrix.sh` — Adoption-proof matrix gate.

### Version-bearing files (the `@version` + pins to change)
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs` — `@version "1.2.0"`; admin/portal pin core via `== @version` / `~> @version`.
- `accrue/CHANGELOG.md`, `accrue_admin/CHANGELOG.md`, `accrue_portal/CHANGELOG.md` — Hand-written "Unreleased" sections to reconcile.

### `@since` fix targets
- `accrue/lib/accrue/analytics/dunning.ex` — 5 stray `@since "1.4.0"` lines inside `@doc` heredocs.
- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` — stray `@since "1.4.0"` in `@doc` heredoc.

### Project state
- `.planning/PROJECT.md` — v1.46 Maintenance & Closure milestone definition.
- `.planning/STATE.md` — Milestone progress, deferred items, non-goals.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Full `scripts/ci/verify_*.sh` suite — already the closure gatekeeper; reuse as-is, no new scripts needed.
- ExCoveralls already wired in `accrue/mix.exs` (added 151-03) with `preferred_cli_env` for `coveralls.*`.
- Release Please pipeline + `gh_merge_release_pr.sh` / `repair_linked_release_pr.sh` — the publish mechanism already exists end-to-end.

### Established Patterns
- **Conventional commits → linked minor bump:** `feat:` batch with no `feat!`/breaking ⇒ single minor bump for all 3 packages (this is why 1.3.0, not 1.4.0, and not a major).
- **`@doc since:` is the canonical ExDoc convention** for "introduced-in" metadata in this codebase's idiom (bare `@since` is not a recognized attribute).
- **verify_package_docs ↔ test coupling:** doc needles in the script must mirror the verifier test fixture (memory: `project_verify_package_docs_test_coupling`).

### Integration Points
- `@version` attribute + inter-package version pins in the three `mix.exs` files.
- `.release-please-manifest.json` and per-package `CHANGELOG.md`.

</code_context>

<specifics>
## Specific Ideas

User confirmed **1.3.0** as the published target (Recommended option) — let Release
Please compute the version from conventional commits rather than honoring the stray
`1.4.0` written in the docstrings. Everything else accepted as decisive defaults
(no objection raised to the locked mechanical decisions).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 152-Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag*
*Context gathered: 2026-05-29*
