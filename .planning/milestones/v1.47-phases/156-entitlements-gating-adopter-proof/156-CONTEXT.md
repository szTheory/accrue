# Phase 156: Entitlements Gating Adopter Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the checked-in `examples/accrue_host` entitlement-gated LiveView proof safe and copyable for adopters. The phase closes PRF-01 by proving that `Accrue.Live.Entitlements` can be used in a host `live_session` without crashing when the billable association is unloaded, while keeping the existing positive and negative entitlement examples passing.

- **In scope:** defensive handling for `%Ecto.Association.NotLoaded{}` in the entitlement guard path, an explicit `examples/accrue_host` router ordering comment, a host-level regression proving unloaded billable state fails closed instead of raising, and preserving the current entitled/non-entitled route tests.
- **Out of scope:** new public entitlement APIs, new database/schema changes, advisory-cache behavior, a new organization-selection UX branch, changes to billing semantics, or broad documentation rewrites beyond the canonical ordering recipe needed for PRF-01.

</domain>

<decisions>
## Implementation Decisions

### NotLoaded guard placement
- **D-01:** Normalize `%Ecto.Association.NotLoaded{}` defensively in core guard/decision code, preferably inside `Accrue.Entitlements.Guard` where billable resolution and allow/deny decisions already live. Do not put the primary decision logic in `Accrue.Live.Entitlements`; that module should remain the LiveView surface translator.
- **D-02:** Also make the `examples/accrue_host` billable resolver and router comment explicit about the expected host pattern. The example should teach that auth/scope loading must run before `Accrue.Live.Entitlements`, and that unloaded/missing billable state fails closed.
- **D-03:** Treat `Ecto.Association.NotLoaded` as "not a usable billable", not as data to pass into entitlement resolution. The outcome should be a safe denial, not a crash and not accidental entitlement.

### Fail-closed user path
- **D-04:** Keep the entitlement-denial UX generic for Phase 156. Missing/unloaded `active_organization` should fail closed through the entitlement guard rather than adding a new "select organization first" flow.
- **D-05:** Do not add a new pre-entitlement organization-presence `on_mount` hook in this phase. That would be a host UX capability, not required by PRF-01, and it would expand the behavioral surface beyond adopter-proof hardening.
- **D-06:** Preserve the security layering: authenticate/load scope first, authorize entitlement second. The example comment should make the ordering contract clear without changing the user-facing denial semantics.

### Proof shape
- **D-07:** Keep the existing positive and negative host tests in `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` as merge-blocking proof.
- **D-08:** Add an explicit host-level regression for `%Ecto.Association.NotLoaded{}` in the same test module. It should exercise the real `live_session`/`on_mount` route and prove the route redirects/halts safely instead of raising.
- **D-09:** Prefer one focused host regression over duplicative broad unit coverage unless the planner finds the core guard helper needs a tiny unit test to make the implementation straightforward. The adopter-facing proof is the host route behavior.

### Router comment contract
- **D-10:** Use a hybrid documentation shape: a concise inline contract near `live_session :entitled_reports` in `examples/accrue_host/lib/accrue_host_web/router.ex`, plus a canonical guide/doc reference for the fuller recipe.
- **D-11:** The inline comment should state the contract, not become a tutorial: auth/scope-loading `on_mount` first; `Accrue.Live.Entitlements` after; deny target outside the gated session; unloaded/missing billable state fails closed.
- **D-12:** Keep detailed variants and rationale in canonical docs such as `accrue/guides/entitlements.md` and/or the host adoption matrix. Avoid long router comments that drift from docs.

### Folded Todos
- **ENT-10 advisory-cache code-review follow-ups (WR-05 + INFO)** - Filed 2026-05-24 from Phase 127 code review. It originally resolved Phase 154 and informed the v1.47 entitlement-adopter-proof posture, but the Phase 156 slice should not reopen advisory-cache fixes already closed by Phases 154 and 155. Use it only as historical context for preserving fail-closed entitlement proof and support-truth discipline.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/ROADMAP.md` §"Phase 156: Entitlements Gating Adopter Proof" - phase goal and success criteria.
- `.planning/REQUIREMENTS.md` §"Adopter-Proof: Entitlements Gating" - PRF-01 locked requirement.
- `.planning/STATE.md` §"Current Position" and §"Key Planning Decisions for v1.47" - confirms Phase 156 is independent of Phases 154/155 and scoped to adopter proof.

### Research and prompt corpus
- `.planning/research/SUMMARY.md` §"Adopter-Proof: Entitlements Gating" - identifies the `NotLoaded` guard, router ordering comment, and existing test preservation.
- `.planning/research/PITFALLS.md` §"Adopter-Proof Example Pitfalls" - especially PROOF-01 and PROOF-02, the scope-loading/order and local map pitfalls.
- `prompts/MILESTONE-NEXT-STEP-ASSESSMENT.md` - recurring maintainer preference for repo-local truth, adopter-facing proof, idiomatic Elixir/Phoenix, recommendation-first research, and DX/least-surprise.

### Source files
- `accrue/lib/accrue/live/entitlements.ex` - LiveView `on_mount` surface; should remain thin translation over `Accrue.Entitlements.Guard`.
- `accrue/lib/accrue/entitlements/guard.ex` - core entitlement guard decision path and preferred home for `NotLoaded` normalization.
- `examples/accrue_host/config/config.exs` - host `:accrue, :entitlements` billable resolver that reads `current_scope.active_organization` or user fallback.
- `examples/accrue_host/lib/accrue_host_web/router.ex` - `live_session :entitled_reports` ordering and inline comment target.
- `examples/accrue_host/lib/accrue_host_web/user_auth.ex` - host auth/scope `on_mount` implementation that must precede entitlement guard.
- `examples/accrue_host/test/accrue_host_web/live/entitlements_guard_test.exs` - existing positive/negative host route proof and target for the `NotLoaded` regression.
- `accrue/test/accrue/live/entitlements_test.exs` - focused core LiveView guard tests if the planner needs a small supplemental core assertion.
- `examples/accrue_host/docs/adoption-proof-matrix.md` - adopter-proof matrix row for entitlement gating.
- `accrue/guides/entitlements.md` - canonical public entitlement guide and likely home for a fuller ordering recipe if not already sufficient.

### Folded todo origin
- `.planning/todos/pending/2026-05-24-ent10-advisory-cache-followups.md` - historical ENT-10 follow-up source; do not re-scope advisory-cache work into Phase 156.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Accrue.Live.Entitlements.on_mount/4` already delegates to `Accrue.Entitlements.Guard.check/3` and only translates allow/deny into LiveView `{:cont, socket}` / `{:halt, socket}` behavior.
- `examples/accrue_host` already has an entitlement-gated route at `/app/reports/advanced` under `live_session :entitled_reports`.
- `entitlements_guard_test.exs` already proves an entitled org can access the route and a non-entitled org receives the generic deny redirect.

### Established Patterns
- Core entitlement behavior is fail-closed and local-first. Missing, nil, malformed, or unresolved billables should deny rather than raise or grant.
- Phoenix `on_mount` ordering matters: host auth/scope resolution must run before authorization hooks that depend on socket assigns.
- Ecto uses `%Ecto.Association.NotLoaded{}` as the unloaded-association sentinel. It is not equivalent to a loaded billable struct and should be normalized/denied before entitlement resolution.
- Router files should keep comments concise and local to the DSL; longer adopter recipes belong in guides/docs to reduce drift.

### Integration Points
- The planner should inspect `Accrue.Entitlements.Guard` to find the smallest normalization point before entitlement checks call into `Accrue.Entitlements.entitled?/3` or `has_active_plan?/3`.
- The example resolver in `examples/accrue_host/config/config.exs` may need a small defensive branch so the example itself is copyable and obvious.
- The host route regression should go through `/app/reports/advanced` rather than only unit-calling the guard, because PRF-01 is adopter proof for a real `live_session` chain.

</code_context>

<specifics>
## Specific Ideas

- Advisor research recommended the "both" approach for `NotLoaded`: core fail-closed normalization plus explicit example guidance. This balances safe library defaults with copyable adopter DX.
- Advisor research recommended preserving generic fail-closed entitlement denial in this phase. A distinct "select organization first" message is useful product UX, but it is a separate host capability and not required for PRF-01.
- Advisor research recommended one explicit host-level `NotLoaded` regression because successful libraries and frameworks treat bug fixes around auth/authorization as regression-test-worthy, not documentation-only.
- Advisor research recommended a concise router contract plus canonical docs. The router should say what must be ordered, while `accrue/guides/entitlements.md` or the adoption matrix carries the fuller explanation.
- Relevant ecosystem lessons: authorization middleware/hooks should deny safely by default; authentication/scope loading should precede authorization; examples should be copyable but not duplicate entire guides inline.

</specifics>

<deferred>
## Deferred Ideas

- Add a distinct "select an organization first" or "organization scope missing" UX flow before entitlement denial. Useful later, but out of scope for Phase 156 because it adds host UX behavior beyond PRF-01.
- Add broader docs around multi-tenant org-selection flows. Keep Phase 156 focused on the entitlement guard proof and ordering recipe.

</deferred>

---

*Phase: 156-Entitlements-Gating-Adopter-Proof*
*Context gathered: 2026-05-31*
