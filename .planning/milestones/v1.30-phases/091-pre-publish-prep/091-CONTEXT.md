# Phase 91: Pre-publish 1.0.0 prep — Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the documentation, CHANGELOG, and release-cadence narrative true on `main` **before** Phase 92 bumps `@version` to `1.0.0` and ships the linked Hex publish. Satisfy **REL-06**, **REL-07**, **DOC-03**, **DOC-04** so Phase 92 itself is a mechanical version bump on top of already-honest prose. **`mix.exs @version` stays at `0.3.1`** for both packages at end of phase (success criterion #5 — Phase 92 owns the bump). Verifier discipline: every merge-blocking gate stays green at `0.3.1` after Phase 91 lands; Phase 91 must not touch any install literal pinned by `verify_package_docs.sh` (which extracts `@version` and grep-matches `~> 0.3.1` literals in `accrue/README.md`, `accrue_admin/README.md`, and `accrue/guides/first_hour.md`).

**Out of scope:** the `@version` bump itself (Phase 92), `verify_adoption_proof_matrix` needle refresh for the `0.3.1 → 1.0.0` jump (Phase 92 PPX-12), `.planning/` mirror sweep (Phase 93 HYG-02), friction-inventory dated maintainer pass (Phase 93 INV-07), `release-notes.md` past-tense pre-1.0 references (correctly historical, leave untouched), `production-readiness.md` line 11 `~>` install-mechanics framing (couples to Phase 92's `@version` bump), `first_hour.md` "intake-gated" doctrine (survives 1.0; doctrine, not version-tied).

</domain>

<decisions>
## Implementation Decisions

Cohesive default package — research-backed by parallel advisor agents (Phoenix LiveView 1.0, Ecto 3.0, Oban, Broadway 1.0, Pay/Cashier, Stripe SDK release patterns, Release Please for Elixir, semver.org, Elixir core deprecation policy). All decisions below are auto-applied per `discuss_publish_contracts_research_depth: deep_synthesis_cohesive_defaults_unless_discuss_high_impact_confirm` — no high-impact forks were surfaced.

### PR sequencing vs Phase 92 `@version` bump

- **D-01:** Phase 91 lands as a **separate pre-bump PR** ahead of Phase 92's combined Release Please PR. Honors ROADMAP success criterion #5 (`@version` stays `0.3.1` end-of-phase). Matches v1.27 Phase 84 `pre-1-0-closure-narrative` precedent (docs-only PR ahead of any version move). Phase 91 is independently mergeable to `main`; Phase 92 then opens the Release Please PR that bumps `@version` and renders the public `## [1.0.0]` CHANGELOG heading.
- **D-02:** Use **commitment-level prose**, not claim-level prose, to avoid registry-vs-README mismatch during the Phase 91 → Phase 92 transition window. Acceptable: "Accrue commits to v1.x API stability for the documented integration surface", "the `1.0.x` line treats X as the stability boundary", "post-1.0 cadence follows…". **Not acceptable on `main` until Phase 92 lands:** "Accrue is now at 1.0.x", "Hex shows `accrue 1.0.0`", any sentence whose truth value flips on the registry state. This keeps `main` honest at every commit despite docs declaring v1.x stability commitment.
- **D-03:** All merge-blocking verifiers (`verify_package_docs.sh`, `verify_adoption_proof_matrix.sh`, `verify_v1_17_friction_research_contract.sh`, `verify_verify01_readme_contract.sh`, `verify_production_readiness_discoverability.sh`, `verify_core_admin_invoice_verify_ids.sh`, `host-integration`) must stay green at `@version "0.3.1"` after the Phase 91 PR merges. Phase 91 PR description must include the falsifiable transcript / CI run link proving this — same merge-blocking discipline as v1.28 Phase 86.

### REL-06 — CHANGELOG `1.0.0 — Stable` shape

- **D-04:** **Hybrid shape — short stability-commitment preamble + Release-Please-rendered category sections.** Insert preamble as the first paragraph of each package's `## Unreleased` section (above existing `### Billing`, `### Telemetry`, `### Documentation`, `### CI` subsections in `accrue/CHANGELOG.md`; above `### Host-visible copy (accrue_admin)` subsection in `accrue_admin/CHANGELOG.md`). Release Please carries the preamble verbatim into the rendered `## [1.0.0](compare-link) (DATE)` block when Phase 92's combined release PR opens — no fake `## 1.0.0` heading on `main`, no two-headings collision risk on RP regeneration. Matches Broadway 1.0, LiveView 1.0, Ecto 3.0, and Keep-a-Changelog 1.0.0 idiom (preamble + categorized changes, not narrative wall and not bare one-liner).
- **D-05:** **Concrete preamble text** (locked — planner does not re-derive):

  - **`accrue/CHANGELOG.md`** — first paragraph of `## Unreleased`:

    > **1.0.0 — Stable.** This release commits Accrue to v1.x API stability for the documented integration surface: generated `MyApp.Billing`, `use Accrue.Webhook.Handler`, `use Accrue.Test`, `Accrue.Auth`, and `Accrue.ConfigError`. Breaking changes on that surface go through deprecation, not silent reshuffles. Internal schemas, workers, and demo helpers are not part of the contract. See `accrue/README.md` Stability, `accrue/guides/upgrade.md`, `accrue/guides/maturity-and-maintenance.md`, and root `RELEASING.md` for the v1.x stability commitment and post-1.0 cadence.

  - **`accrue_admin/CHANGELOG.md`** — first paragraph of `## Unreleased` (above `### Host-visible copy (accrue_admin)`):

    > **1.0.0 — Stable.** Released in lockstep with `accrue` 1.0.0. The supported integration surface for the admin package is `AccrueAdmin.Router` and the documented mount/scope helpers; see `accrue/CHANGELOG.md` and `accrue/guides/maturity-and-maintenance.md` for the v1.x stability commitment that governs both packages.

- **D-06:** **Do not** add a literal `## 1.0.0 — Stable` heading on `main` in either CHANGELOG. The heading is rendered by Release Please when Phase 92's release PR opens — pre-creating it on `main` causes duplicate-heading collisions on RP regeneration.

### REL-07 — `RELEASING.md` post-1.0 cadence section

- **D-07:** **Replace `## Pre-1.0 closure (maintainer intent)` (line 11) in place** with `## Post-1.0 cadence (maintainer intent)`. Single voice, smallest diff, matches Phoenix `RELEASE.md` "operational not historical" stance (CHANGELOG owns historical narrative; RELEASING.md owns the runbook). Don't keep the pre-1.0 block as soft-deprecated text — it ossifies into a stale parallel reality.
- **D-08:** **Rename `## Routine pre-1.0 linked releases (Release Please + Hex)` (line 19)** → `## Routine linked releases (Release Please + Hex)`. One-word edit, completes the voice flip REL-07 implies.
- **D-09:** **Top-of-file preamble (lines 3–9)** keeps neutral "linked `accrue` + `accrue_admin` releases via Release Please" framing in Phase 91 (drop "pre-1.0" qualifier). Do **not** convert it to "post-1.0" prose until Phase 92 — keeps the file honest while `@version` is still `0.3.1`.
- **D-10:** **Bootstrap appendix (line 164, `## Appendix: Same-day 1.0.0 bootstrap (exceptional)`) — leave untouched in Phase 91.** Demotion belongs to Phase 92 (after the actual 1.0.0 bootstrap happens). The appendix is still genuinely exceptional until Phase 92 cuts the linked publish.
- **D-11:** **Concrete outline for the new `## Post-1.0 cadence (maintainer intent)` section** (planner uses this verbatim — bullet text may be tightened, structure is locked):

  1. Opening framing paragraph: the documented public façade (`@public_api`, `Accrue.Billing` context, `Accrue.Auth`/`Accrue.PDF`/`Accrue.Mailer` behaviours, public Ecto schemas, public Plug routes, documented Telemetry event contract) is the SemVer boundary. Routine releases tighten correctness, docs, observability, and provider parity within that boundary; breaking the boundary requires a new major. Use **commitment-level voice** ("the `1.0.x` line treats…"), present-progressive only where the section discusses things that activate at Phase 92 publish ("Once `1.0.0` publishes…").
  2. **SemVer discipline.** Patch = bug fixes + doc-only changes inside the documented facade. Minor = additive features, optional config, optional adapters, forward-compatible Telemetry events, soft-deprecations. Major = removal of hard-deprecated symbols, changes to the documented Plug/router contract, breaking schema migrations on `accrue_*` tables, changes to the webhook signature verification contract.
  3. **Deprecation cycle (two-step).** (a) Soft-deprecate in CHANGELOG + `@deprecated` module attribute + `accrue/guides/upgrade.md` entry, no runtime warning. (b) Hard-deprecate in a later minor with `@deprecated` runtime warning. Removal only in the next major. Replacement API must exist for **at least one minor release** before hard-deprecation activates. (Matches Elixir core policy, scaled down.)
  4. **Cadence.** Patches as needed; minors when a coherent additive batch lands; majors are rare and pre-announced via a `2.0.0-rc.N` pre-release tag with at least one RC window before stable.
  5. **Lockstep.** `accrue` and `accrue_admin` continue shipping as a coordinated combined Release Please PR; major versions stay aligned; admin minors may lead core minors when admin-only features ship.
  6. **Supported integration surface.** Pointer (do not duplicate): `accrue/guides/maturity-and-maintenance.md` is the authoritative `@public_api` list, Telemetry event contract, and what is explicitly **not** part of the SemVer boundary (internal modules, generated migrations' historical content, Fake-processor internals).
  7. **Verification expectation.** Every release — patch, minor, or major — passes the merge-blocking `host-integration` (Fake-backed) gate. Majors additionally require the `live-stripe` lane green within the release window (advisory on PRs, gating on majors per maintainer judgment).
  8. **Forward-port policy.** Critical security fixes are forward-ported to the latest minor of the **previous major for 6 months** after a new major ships; older majors are end-of-life and documented in `maturity-and-maintenance.md`. (6-month window matches Elixir core / Oban deprecation rhythm; auto-applied — flag in PR review if a different number is preferred.)
  9. **Pre-release tags.** `1.x.y-rc.N` for opt-in previews of risky changes; `2.0.0-rc.N` for the next major's stabilization window. RC tags publish to Hex with `--pre` and never auto-resolve for `~> 1.0` consumers.
  10. **Last verified line:** `**Last verified against** release-please-config.json, .release-please-manifest.json, and .github/workflows/release-please.yml on YYYY-MM-DD (UTC).` Phase 92 updates the date to its merge date.

### DOC-03 — README Stability flip + companion guide flip scope

- **D-12:** **Two-pass scoped flip** — Phase 91 touches the four user-facing docs the README cross-links explicitly name + REL-07 mandates: `README.md`, `accrue/README.md`, `accrue/guides/maturity-and-maintenance.md`, `accrue/guides/upgrade.md`. Skip `release-notes.md` (correctly historical past-tense), `production-readiness.md` line 11 (`~>` install-mechanics; couple to Phase 92), `first_hour.md` line 22 (intake-gated doctrine survives 1.0). Strict DOC-03 (READMEs only) leaves stale prose one click in — exact "release fights its own docs" footgun. Comprehensive sweep over-reaches into past-tense historical text. Two-pass scoped is the v1.27 CLS precedent shape.
- **D-13:** **Concrete edits per file** (planner uses these as the touch list — exact wording can be tightened, anchors and intent are locked):

  - **`README.md`** (root)
    - Line 17: drop "today's releases are still **`0.x`** on Hex" qualifier; replace with neutral "the public Hex line tracks **`mix.exs @version`**" (Phase 92 will state the actual line in its bump PR).
    - Line 21 `## Maintenance posture`: flip "The **pre-1.0** line treats…" → "The **`1.0.x`** line treats the public façade, Fake-backed proofs, and merge-blocking CI contracts as the stability boundary; post-1.0 cadence follows semver discipline (deprecation cycle for breaking changes, see `RELEASING.md` *Post-1.0 cadence (maintainer intent)*), and new work is intake-gated (security, correctness, linked Hex publishes, or sourced friction in the maintainer inventory), not open-ended feature expansion." Keep the cross-link to `accrue/guides/maturity-and-maintenance.md` and the `PROC-08` / `FIN-03` non-goals callout. **Do not** reword "intake-gated" — it is doctrine, survives 1.0.

  - **`accrue/README.md`**
    - Line 15 ("done enough for the **pre-1.0** line"): flip → "done enough for the **`1.0.x`** line".
    - Line 27 ("while Accrue is pre-1.0"): flip → "while you are tracking a single `~>` line".
    - Line 65 (`## Stability` paragraph): flip "while public SemVer is still **`0.x`**" → "even within the `1.0.x` series, breaking changes on the documented surface go through deprecation, not silent reshuffles." Drop the trailing sentence "When you are ready to coordinate a `1.0.0` pair on Hex, maintainers follow repository root `RELEASING.md` (*Appendix: Same-day `1.0.0` bootstrap*)" — replace with: "Maintainer cadence is documented in `RELEASING.md` *Post-1.0 cadence (maintainer intent)* and `accrue/guides/maturity-and-maintenance.md`."
    - **Install snippet on line ~46 (`{:accrue, "~> 0.3.1"}`) is NOT touched in Phase 91.** That literal is verifier-pinned to `mix.exs @version`; Phase 92's bump touches it.

  - **`accrue/guides/maturity-and-maintenance.md`**
    - Line 8: flip "deciding whether to pin another **pre-1.0 minor**" → "deciding whether to pin another **`1.0.x` minor**".
    - Line 19: flip "the **post–0.3.1** friction table" → "the **post-1.0** friction table" (also reaffirms the v1.30 INV-07 dated pass that Phase 93 will write).
    - Add new authoritative list (top of file or under existing header — planner picks the cleanest insertion point): the canonical `@public_api` symbols + Telemetry event contract + "explicitly not part of the SemVer boundary" disclaimer that REL-07 §"Supported integration surface" pointer expects to find here. If this list already exists in another doc, anchor-link instead of duplicating; otherwise create it.

  - **`accrue/guides/upgrade.md`**
    - Line 35: flip "Until both packages publish **`1.0.0`**, public SemVer stays **`0.x`**" → "`accrue` and `accrue_admin` publish in lockstep on the **`1.0.x`** line. For the 1.0.0 bootstrap story (historical reference for the cut event), see `RELEASING.md` *Appendix: Same-day 1.0.0 bootstrap*."
    - Line 37 (`**Pre-1.0 wrap-up semantics:**`): rename anchor + content → `**Post-1.0 cadence:**` paragraph: "On the `1.0.x` line, expect additive fixes, proof hardening, and integrator-contract tightening within the documented facade; breaking changes go through the deprecation cycle in `RELEASING.md` *Post-1.0 cadence (maintainer intent)*. Maintainer framing lives in [Maturity and maintenance](maturity-and-maintenance.md)."

- **D-14:** **CLS-02 anchor coordination.** `RELEASING.md` heading rename (`Pre-1.0 closure` → `Post-1.0 cadence`) and `accrue/guides/upgrade.md` heading rename (`Pre-1.0 wrap-up semantics` → `Post-1.0 cadence`) ship in the **same Phase 91 PR**. Any cross-link from `accrue/guides/upgrade.md` into `RELEASING.md`'s old `#pre-1-0-closure-maintainer-intent` anchor is updated to `#post-1-0-cadence-maintainer-intent` in the same commit. Anchor stability for an internal repo cross-link is low-value — rename, don't keep an HTML `<a id="…">` shim.

### DOC-04 — PROJECT.md non-goals reaffirmation

- **D-15:** **Add a dated sub-section** under `.planning/PROJECT.md` non-goals (current location: line ~150). Heading: `### Reaffirmed at 1.0.0 (2026-04-26)`. Two bullets:
  - **PROC-08 (second processor):** explicit non-goal at 1.0.0; revisit only via later-milestone reprioritization with written boundaries (same posture as v1.27 CLS-03).
  - **FIN-03 (app-owned finance exports):** explicit non-goal at 1.0.0; Accrue is a billing/subscription library, not an accounting system; revisit only via later-milestone reprioritization with written boundaries.

  Shape rationale: dated sub-section gives DOC-04 a single greppable anchor (`Reaffirmed at 1.0.0`) for falsifiable verification, matches the v1.27 CLS-03 dated-pass pattern and v1.20 INV-01 dated maintainer-pass shape the codebase already uses, and keeps the existing non-goals body as the SSOT (no duplication, no per-row annotation drift).

- **D-16:** **Do not** lift PROC-08 / FIN-03 to a "future-milestone" section in this phase. They stay in non-goals. Calling 1.0.0 stable does **not** lift the non-goals — that's the whole point of DOC-04 (also explicit in the milestone goal in `.planning/PROJECT.md` line 17).

### Verification artifact shape (091-VERIFICATION.md)

- **D-17:** Phase-75 / Phase-86-style spine: **Preconditions** (workspace SHA, `@version "0.3.1"` confirmed in both `mix.exs` files), **Evidence checklist** mapping REL-06 / REL-07 / DOC-03 / DOC-04 → concrete commands or doc anchors, **Sign-off**. Plus a **Verifier transcripts** annex citing the merge-blocking bundle green at the reviewed `0.3.1` SHA (`docs-contracts-shift-left` job link or local-run transcripts). Lean — no narrative wall.
- **D-18:** REL-06 evidence: `git show HEAD -- accrue/CHANGELOG.md accrue_admin/CHANGELOG.md` showing the preamble paragraphs in `## Unreleased`. REL-07 evidence: `RELEASING.md` rendered TOC showing `## Post-1.0 cadence (maintainer intent)` heading. DOC-03 evidence: rendered diff or grep transcripts proving each line edit landed. DOC-04 evidence: `.planning/PROJECT.md` rendered TOC showing `### Reaffirmed at 1.0.0 (2026-04-26)` sub-section.

### Claude's Discretion

- Exact preamble wording in CHANGELOG entries (D-05) — planner may tighten by ≤20% if reviewers want shorter; the structure (3-line `accrue` + 2-line `accrue_admin`, Unreleased-anchored) is locked.
- Bullet wording in the new `## Post-1.0 cadence (maintainer intent)` section (D-11) — planner may rephrase for grep-friendliness; the structure (10 numbered items in the order listed) is locked.
- Exact insertion point for the new `@public_api` list inside `maturity-and-maintenance.md` (D-13) — top-of-file vs under existing header, planner picks based on current doc shape.
- Whether the `091-VERIFICATION.md` transcript annex is one combined block or per-requirement subsections (D-18) — keep grep-friendly.

### Folded Todos

- None — `gsd-sdk query todo.match-phase "91"` returned 0 matches.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — REL-06, REL-07, DOC-03, DOC-04 (v1.30 locked requirements)
- `.planning/ROADMAP.md` — Phase 91 row, v1.30 milestone goal, Phase 91 success criteria 1–5
- `.planning/PROJECT.md` — milestone narrative; non-goals section is the DOC-04 edit target (line ~150)
- `.planning/STATE.md` — current planning position (v1.30, Phase 91 next)

### Phase precedents (do not re-litigate)

- `.planning/milestones/v1.27-phases/84-pre-1-0-closure-narrative/084-VERIFICATION.md` — CLS-01..03 closure pattern (the framing this phase replaces); spine + traceability shape
- `.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md` — INV-05 dated maintainer-pass pattern (DOC-04 sub-section heading shape)
- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-CONTEXT.md` — verifier-bundle discipline, transcript annex triggers, same-PR coupling default (the post-publish analog of D-01..D-03)
- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md` — falsifiable evidence checklist shape (091-VERIFICATION inherits this spine)
- `.planning/milestones/v1.11-…` — first linked Hex publish (DOC-01..02 + HYG-01); precedent for combined Release Please PR + post-publish doc/registry coherence

### Files Phase 91 edits (target list — see decisions D-04..D-15)

- `accrue/CHANGELOG.md` — REL-06 preamble in `## Unreleased`
- `accrue_admin/CHANGELOG.md` — REL-06 preamble in `## Unreleased`
- `RELEASING.md` — REL-07 section replacement + heading rename + preamble flip; bootstrap appendix untouched
- `README.md` (root) — DOC-03 maintenance posture flip
- `accrue/README.md` — DOC-03 Stability flip + adjacent line edits (NOT install snippet)
- `accrue/guides/maturity-and-maintenance.md` — DOC-03 cross-link target flip + canonical `@public_api` list
- `accrue/guides/upgrade.md` — DOC-03 cross-link target flip + anchor rename
- `.planning/PROJECT.md` — DOC-04 dated `### Reaffirmed at 1.0.0 (2026-04-26)` sub-section

### Verifier contract (must stay green at `@version "0.3.1"` after Phase 91 merge)

- `.github/workflows/ci.yml` — merge-blocking job ids `docs-contracts-shift-left`, `host-integration`; normative membership at the reviewed SHA
- `scripts/ci/README.md` — same-PR co-update triage rules
- `scripts/ci/verify_package_docs.sh` — extracts `@version` from `mix.exs`, pins install literals (`~> 0.3.1`) — **Phase 91 must not touch any pinned literal**
- `scripts/ci/verify_adoption_proof_matrix.sh` — matrix needles (Phase 92 PPX-12 owns the `0.3.1 → 1.0.0` refresh; Phase 91 leaves needles alone)
- `scripts/ci/verify_v1_17_friction_research_contract.sh` — friction research contract; no pre-1.0 prose pins (verified 2026-04-26)
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README contract; no pre-1.0 prose pins
- `scripts/ci/verify_production_readiness_discoverability.sh` — production-readiness link from both READMEs + `### 1.` through `### 10.` anchors; no pre-1.0 prose pins
- `scripts/ci/verify_core_admin_invoice_verify_ids.sh` — admin invoice verify ids; unrelated to Phase 91
- `scripts/ci/accrue_host_uat.sh` / `accrue_host_hex_smoke.sh` — host integration gate

### Release Please contract

- `release-please-config.json` — `separate-pull-requests: false` (single combined release PR for both packages); `release-type: "elixir"` (auto-updates `mix.exs @version`)
- `.release-please-manifest.json` — current manifest at `0.3.1` for both packages; Phase 92's PR moves both to `1.0.0`
- `.github/workflows/release-please.yml` — Release Please orchestration; `accrue` publishes before `accrue_admin`

### GSD config knobs (already shifted-left, applied this session)

- `.planning/config.json`
  - `workflow.discuss_auto_all_gray_areas: true`
  - `workflow.discuss_auto_resolve_low_impact: true`
  - `workflow.discuss_high_impact_confirm: true`
  - `workflow.discuss_publish_contracts_research_depth: deep_synthesis_cohesive_defaults_unless_discuss_high_impact_confirm`
  - `workflow.discuss_default_post_publish_pr_coupling: same_pr_as_mix_version_bump_when_human_batchable_immediate_follow_up_same_day_if_automation_edge` — pre-publish analog (Phase 91 ahead of Phase 92) is **D-01**

### Research synthesis sources (advisor agents, 2026-04-26)

- Phoenix LiveView 1.0 release blog + RC announcement; Phoenix `RELEASE.md`
- Ecto 3.0 release notes + categorized CHANGELOG style
- Oban CHANGELOG + v2.0 upgrade guide; Broadway 1.0 CHANGELOG (verbatim 1.0.0 entry shape)
- Pay (Rails) `CHANGELOG.md` + `UPGRADE.md`; Laravel Cashier release docs
- Stripe SDK release patterns; stripity_stripe 3.0 cut
- Keep a Changelog 1.1.0; semver.org 2.0.0
- Release Please for Elixir (Elixir School + googleapis/release-please docs); Release Please customizing (`BEGIN_COMMIT_OVERRIDE`, `Release-As` trailer)
- Elixir core "Compatibility and Deprecations" (forward-port and deprecation cycle precedent)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- v1.27 Phase 84 closure-narrative spine (`084-VERIFICATION.md`) — Phase 91 inherits the per-requirement traceability table shape with REL/DOC ids substituted for CLS ids.
- v1.27 Phase 85 dated maintainer-pass heading (`### v1.27 INV-05 maintainer pass (YYYY-MM-DD)`) — Phase 91 mirrors this for DOC-04 (`### Reaffirmed at 1.0.0 (2026-04-26)`).
- v1.28 Phase 86 verifier-bundle transcript / CI-link evidence shape — `091-VERIFICATION.md` inherits this for the `docs-contracts-shift-left` + `host-integration` green-at-`0.3.1` evidence.
- Release Please's `## Unreleased` → `## [VERSION] (DATE)` rendering on PR open — D-04 / D-05 leverage this so Phase 91 doesn't have to hand-author the public 1.0.0 heading.

### Established Patterns

- **Single-voice runbook.** `RELEASING.md` is operational; CHANGELOG is historical; `maturity-and-maintenance.md` is the maintainer-doctrine SSOT. REL-06 / REL-07 / DOC-03 follow this split: cadence narrative lives in `RELEASING.md`; CHANGELOG points at it; READMEs point at both. No duplication.
- **Verifier-contract-as-truth.** Merge-blocking CI is the integrator-visible contract; planning attestations stay SHA-grounded. Phase 91 maintains this: Phase 91 PR description includes a `0.3.1`-SHA + green CI link.
- **Commitment-level voice during transition windows.** Used in `.planning/PROJECT.md` line 17 ("flipped to '1.0.0 stable, post-1.0 cadence'") even though `@version` is `0.3.1` — the planning doc declares the milestone goal in commitment voice. Phase 91 prose does the same in user-facing docs.
- **Dated sub-section pattern for non-goals / friction reaffirmation.** v1.20 INV-01, v1.25 INV-03, v1.26 INV-04, v1.27 CLS-03 / INV-05 — DOC-04 follows the same pattern.

### Integration Points

- **Phase 92 (Linked 1.0.0 publish + post-publish contract sweep)** consumes Phase 91's docs as the prose layer Release Please bumps over. Phase 92's combined Release Please PR + post-publish verifier sweep relies on Phase 91 having shipped: (a) the CHANGELOG preambles in `## Unreleased`, (b) the `RELEASING.md` post-1.0 cadence section, (c) the README Stability + Maintenance posture flips. Phase 92 then mechanically bumps `@version` and refreshes the `0.3.1 → 1.0.0` install-literal needles + adoption matrix entries.
- **Phase 93 (HYG mirror + INV-07 + tag)** consumes Phase 91's dated DOC-04 sub-section heading (`### Reaffirmed at 1.0.0 (2026-04-26)`) as a `.planning/PROJECT.md` mirror anchor for HYG-02. INV-07 maintainer pass cites Phase 91's "post-1.0 friction table" framing in `maturity-and-maintenance.md` line 19.
- **Verifier contract.** All edits are prose-only or anchor-rename — none of the merge-blocking verifiers pin "pre-1.0", "0.x", "intake-gated", or `## Stability`-section literal prose (verified by reading the 5 named scripts 2026-04-26). Zero merge-blocking breakage expected from Phase 91 at `@version "0.3.1"`.

</code_context>

<deferred>
## Deferred Ideas

- **`accrue/guides/release-notes.md` line 52 ("Minor (pre-1.0)") flip** — past-tense describing 0.x history; correct as-is. Will be naturally superseded when Phase 92 / future minors append a 1.0.0+ entry. Not Phase 91's work.
- **`accrue/guides/production-readiness.md` line 11 ("stability boundary for pre-1.0 minors") flip** — couples to the `~>` install-literal mechanics that Phase 92 owns. Phase 92 PPX-12 (First Hour + host README + adoption matrix needle refresh) is the natural carrier for this edit.
- **`accrue/guides/first_hour.md` line 22 ("intake-gated") flip** — intake-gated is doctrine, not version-tied. Survives 1.0. Not flipped in Phase 91.
- **`RELEASING.md` `## Appendix: Same-day 1.0.0 bootstrap (exceptional)` demotion** — keep as-is in Phase 91 (still genuinely exceptional until Phase 92 cuts the actual 1.0.0 bootstrap). Demotion is Phase 92 territory or a later v1.31 hygiene pass.
- **Forward-port window other than 6 months** — auto-applied 6 months as cohesive default (Elixir core / Oban precedent). User can override at PR review. Not deferred per se — locked, but flagged for visibility.
- **PROC-08 / FIN-03 reconsideration** — explicitly retained as non-goals (DOC-04). Future-milestone-only.

### Reviewed Todos (not folded)

- None — no pending todos matched Phase 91.

</deferred>

---

*Phase: 091-pre-publish-prep*
*Context gathered: 2026-04-26*
