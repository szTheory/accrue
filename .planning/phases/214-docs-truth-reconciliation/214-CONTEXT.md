# Phase 214: Docs & truth reconciliation - Context

**Gathered:** 2026-07-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Bring every current public and planning truth surface into agreement with the completed
`lattice_stripe ~> 2.0` bump and the shipped Stripe-native advisory entitlements refresh.
This phase owns documentation, release truth, ExDoc version metadata, and focused
documentation drift contracts for **DOCS-01, DOCS-02, and DOCS-03**.

This phase does not change billing behavior, grant semantics, processor capabilities,
admin/portal UI, or package versions. The Phase 213 implementation is final and passed
13/13 verification truths. Release Please remains the only writer of package `@version`
bumps and numbered changelog sections.

</domain>

<decisions>
## Implementation Decisions

The user asked for all five gray areas to be researched by specialist subagents and
resolved as one coherent recommendation set. The decisions below incorporate Elixir,
ExDoc, Phoenix/Ecto/Plug, Hex and linked-release conventions; successful billing-library
patterns from Stripe, Pay, Cashier, and similar ecosystems; Accrue's local prompts and
latest brand DNA; developer ergonomics; auditability; and stable-core constraints.

### Canonical sync wording

- **D-01:** Use this semantic contract everywhere current behavior is explained:
  **Accrue's local plan→feature map is the canonical authorization gate.
  Stripe-native entitlement sync is optional, off by default, and writes a local
  advisory cache for diagnostics and admin read surfaces only. It never changes
  `entitled?/2`, `has_active_plan?/2`, controller plugs, or LiveView guards.**
  Individual documents may shorten the sentence for their audience, but they must keep
  all four facts: local gate authority, optional/default-off sync, advisory diagnostics,
  and grant invariance. — **Reversibility: one-way** — changing this after publication
  would reverse the v1.x authorization contract and the isolation guarantee on which
  adopter access decisions depend.
- **D-02:** Use drift/reconciliation language only as the secondary explanation of why
  the cache exists: it lets operators compare what Stripe last reported with Accrue's
  local access model. Never call the two layers dual authorities.
- **D-03:** Scope "source of truth" language explicitly. Stripe remains authoritative
  for Stripe-side payment and entitlement objects; the local plan→feature map remains
  authoritative for **Accrue grant decisions**. Unqualified claims that Stripe-native
  entitlements are Accrue's authorization source of truth are forbidden.
- **D-04:** Copy follows the current brand voice: measured, exact, native, durable,
  direct, calm, and practical. Lead with the useful authorization fact, use concrete
  nouns and strong verbs, define "advisory cache" once, and avoid implementation-detail
  dumps or hype.

### Release-note allocation and ownership

- **D-05:** `accrue/CHANGELOG.md` owns the substantive `## Unreleased` entry. It records
  the `lattice_stripe ~> 2.0` dependency bump, the optional advisory refresh path and
  supported public/test contracts, default-off and never-a-gate semantics, shared
  reconcile/isolation proof, and the closed `fetch_entitled/2` decision.
- **D-06:** `accrue_admin/CHANGELOG.md` and `accrue_portal/CHANGELOG.md` each receive a
  short `## Unreleased` linked-version compatibility note. They may say the package
  resolves with the coordinated core dependency/sync release, but must not claim a new
  admin/portal-owned workflow, API, or grant authority.
- **D-07:** `accrue/guides/release-notes.md` remains the hand-authored, plain-language
  cross-package story. Add a next-release story (target `1.5.0`) for core plus
  compatibility-only admin and portal coverage, and add the missing portal changelog
  link beside the core/admin links. Do not hand-edit generated
  `accrue/doc/release-notes.md`; regenerate it through the normal ExDoc build.
- **D-08:** Do not add a numbered `1.5.0` changelog block or bump package versions on
  `main`. Release Please remains the single writer for numbered changelog sections and
  all linked package version bumps. `## Unreleased` is drained into the numbered section
  on the release PR per `RELEASING.md`.

### Public API version metadata

- **D-09:** All Phase 213 adopter-facing additions use `@doc since: "1.5.0"`.
  `accrue-v1.4.0` predates the Phase 213 feature commits, so the existing
  `StripeSync.refresh/2` value of `"1.4.0"` is incorrect and must be changed. The normal
  linked Release Please/semver path makes the next feature release `1.5.0`.
- **D-10:** Annotate exactly these supported contracts:
  `Accrue.Entitlements.StripeSync.refresh/2`;
  `Accrue.Processor.list_active_entitlements/2` at both rendered contract surfaces
  (metadata immediately before the `@callback` and separately before the public facade);
  and `Accrue.Processor.Fake.put_entitlements/2` as the deterministic adopter test
  helper.
- **D-11:** Keep adapter implementations, active-entitlement metadata helpers,
  `Accrue.Entitlements.Reconcile` writers, `StripeSync.summary_for_customer/1`, and the
  Oban worker callback hidden/internal and without `since` badges. Documentation is an
  API contract in Elixir; technical callability alone must not turn plumbing into a
  promised public surface.
- **D-12:** Do not mix `1.4.0` and `1.5.0` metadata across this feature family. If the
  release plan changes from the normal feature release, stop and reconcile every badge,
  changelog, release note, and package version together rather than silently shipping
  contradictory availability claims.

### Current truth versus historical evidence

- **D-13:** Apply a scoped current-truth sweep. Update public/current surfaces that
  answer "what is true now": `CLAUDE.md`, the JTBD guides, active support/adoption
  matrices, package changelogs and release notes, current code docs, and active planning
  status mirrors. In particular, active Phase 213 status must say the final
  re-verification passed; stale intermediate "gaps found" status is not current truth.
- **D-14:** Preserve dated evidence: completed phase plans, contexts, research,
  summaries, reviews, verifications, upgrade evidence, archived milestones,
  retrospectives, and the fired SEED-005 origin record. Old pins or "deferred" wording
  in those files describes what was true at that time and must not be rewritten into
  false history.
- **D-15:** Grep review and automated checks must classify paths before judging a hit.
  Current/public files must agree on `~> 2.0` and shipped/observational status; dated
  phase/archive/seed hits are allowed when explicitly historical. Do not use an
  unscoped repo-wide absence rule.

### Drift prevention

- **D-16:** Extend existing documentation contracts instead of creating a new truth
  verifier. `scripts/ci/verify_package_docs.sh` owns current stack/JTBD/entitlements
  assertions; `scripts/ci/verify_release_notes_contract.sh` owns the next-release story
  and three-package discoverability. Use existing CI wiring and ExUnit shell-out tests.
- **D-17:** Add high-signal positive and negative checks with actionable failure labels.
  Positives cover `~> 2.0`, shipped/observational status, the local canonical
  authorization gate, advisory diagnostics, default-off behavior, the three
  package/changelog paths, and `since: "1.5.0"` on the supported public contracts.
  Negatives reject stale `~> 0.2`/`~> 1.1` only in the current stack/version surfaces,
  current JTBD "sync deferred" claims, Stripe-as-Accrue-grant-authority wording, and
  claims that advisory sync changes a gate decision.
- **D-18:** Test the negative guards with focused ExUnit fixtures so each semantic
  regression demonstrably fails. Do not freeze full paragraphs, enforce one exact prose
  rendering across audience-specific docs, or duplicate the same contract across a new
  script.
- **D-19:** Keep the manual acceptance grep from the roadmap as a final cold-read, but
  make it scoped and explanatory: current surfaces must tell one story; historical
  matches must remain obviously dated rather than being counted as contradictions.

### the agent's Discretion

- Exact audience-appropriate shortening of D-01, provided all four semantic facts remain.
- Exact headings and bullet ordering inside each `## Unreleased` or next-release section.
- Whether existing verifier helpers are extended or one small shared helper is extracted,
  provided no new top-level verifier/CI lane is introduced.
- Exact fixture prose used to prove negative guards.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Binding scope and requirements

- `.planning/ROADMAP.md` — v1.58 scope fence, Phase 214 goal, success criteria, and
  authoritative-source inventory.
- `.planning/REQUIREMENTS.md` — DOCS-01, DOCS-02, DOCS-03, POS-03, and milestone
  exclusions.
- `.planning/seeds/SEED-005-lattice-stripe-entitlements-bump.md` — dated origin,
  promotion trigger, and the old truth that must remain historical.

### Shipped implementation truth

- `.planning/phases/212-lattice-stripe-2-x-bump-green-reconciliation/212-UPGRADE-EVIDENCE.md`
  — auditable 1.x→2.x bump and resolved-version evidence.
- `.planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-CONTEXT.md`
  — locked sync architecture and isolation decisions.
- `.planning/phases/213-stripe-native-advisory-entitlements-sync-observational-only/213-VERIFICATION.md`
  — final passed 13/13 verification; supersedes intermediate gaps-found status.
- `accrue/lib/accrue/entitlements/stripe_sync.ex` — public refresh contract and stale
  `1.4.0` metadata/current moduledoc details to reconcile.
- `accrue/lib/accrue/processor.ex` — behaviour callback and public facade contract.
- `accrue/lib/accrue/processor/fake.ex` — supported deterministic entitlement-seeding
  helper.
- `scripts/ci/verify_entitlement_sync_isolation.sh` — executable never-a-gate contract.

### Current public and planning truth surfaces

- `CLAUDE.md` — Technology Stack and Version Compatibility Matrix pins for DOCS-01.
- `accrue/guides/entitlements.md` — primary adopter explanation of local gates,
  advisory sync, refresh, and `fetch_entitled/2` closure.
- `accrue/guides/jobs_to_be_done.md` — public current capability/JTBD status.
- `.planning/research/JTBD-FRONTIER.md` — current planning mirror of the JTBD frontier.
- `.planning/processor-support-matrix.md` — maintainer-facing processor capability SSOT.
- `examples/accrue_host/docs/adoption-proof-matrix.md` — Fake-first/advisory-lane proof
  contract.
- `.planning/milestones/v1.52-phases/180-brand-audit-dna-lock/BRAND-DNA.md` — current
  measured/exact/native/durable voice; supersedes older prompt-era brand guidance where
  they differ.

### Release and changelog contract

- `accrue/CHANGELOG.md` — core authoritative package history and substantive Unreleased
  entry.
- `accrue_admin/CHANGELOG.md` — admin package history and compatibility-only entry.
- `accrue_portal/CHANGELOG.md` — portal package history and compatibility-only entry.
- `accrue/guides/release-notes.md` — hand-authored plain-language cross-package story.
- `RELEASING.md` — Release Please single-writer boundary, Unreleased drain rule, linked
  package contract, and release review checklist.
- `release-please-config.json` — linked three-package versioning/changelog ownership.
- `.release-please-manifest.json` — current published package line (`1.4.0`) and evidence
  that Phase 213 belongs to the next feature release.

### Existing drift-contract assets

- `scripts/ci/verify_package_docs.sh` — current entitlements and package-doc contract
  owner to extend.
- `scripts/ci/verify_release_notes_contract.sh` — plain-language release freshness and
  linked-package discoverability owner to extend.
- `scripts/ci/verify_processor_support_matrix.sh` — existing semantic positive/negative
  assertion pattern for capability truth.
- `scripts/ci/verify_stable_core_posture.sh` — POS-01..03 current-truth scope.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — package-doc verifier
  success/failure fixture pattern.
- `accrue/test/accrue/docs/release_notes_contract_test.exs` — release-note verifier
  success/failure fixture pattern.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Existing documentation verifiers already provide shell helpers, actionable stderr
  prefixes, CI wiring, and ExUnit shell-out fixture patterns; Phase 214 extends them
  instead of creating a parallel gate.
- The three package changelogs and `accrue/guides/release-notes.md` already separate
  machine-precise package history from the plain-language release story.
- Release Please already links `accrue`, `accrue_admin`, and `accrue_portal`, while
  retaining package-local changelog ownership.

### Established Patterns

- Documentation is a supported API contract in Elixir/ExDoc. `@doc since:` belongs on
  supported public functions/callbacks, while internal plumbing stays hidden.
- Current docs are derived from shipped code and executable tests; dated planning prose
  remains evidence, not current product documentation.
- Accrue's drift gates use narrow semantic positives plus negative regression guards,
  backed by fixtures that prove the guard can fail.
- Public prose leads with user/adopter truth and package ownership, then links to deeper
  implementation detail instead of exposing internal machinery as the interface.

### Integration Points

- Phase 214 changes connect at the current stack/JTBD/support-matrix docs, three
  changelogs, one plain-language release-note source, ExDoc metadata on three supported
  contracts, and two existing documentation verifier families.
- Active roadmap/state/requirements status corrections use registered GSD handlers where
  available; planning archives and the user's unrelated modified
  `213-REVIEW.md` remain untouched.

</code_context>

<specifics>
## Specific Ideas

- One canonical sentence should be recognizable across every audience-specific rendering,
  even when shortened.
- Treat Fake's entitlement seeding helper as first-class test DX, not production API.
- Add the portal changelog link to the release-note introduction so all three linked
  packages are equally discoverable.
- The UI/visual-design portion of the user's requested lens is not applicable because
  Phase 214 contains no UI. The applicable JTBD is developer/maintainer confidence:
  find the current version, understand the access authority boundary, discover the safe
  refresh/test path, and trust that release notes and planning mirrors agree.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 214-docs-truth-reconciliation*
*Context gathered: 2026-07-30*
