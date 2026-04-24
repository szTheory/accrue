# Phase 86: Post-publish contract alignment - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

On the **next linked Hex publish** for **`accrue` / `accrue_admin`**, satisfy **PPX-05..PPX-08** per **`.planning/REQUIREMENTS.md`**: workspace **`@version`** / install-literal honesty (**`verify_package_docs.sh`** + **`package_docs_verifier_test.exs`**), adoption proof matrix + **`verify_adoption_proof_matrix.sh`**, full **`docs-contracts-shift-left`** merge-blocking set (including **`verify_production_readiness_discoverability.sh`** when in that job), **`.planning/`** public-Hex mirrors (**`PROJECT.md`**, **`MILESTONES.md`**, **`STATE.md`**) — with falsifiable **`086-VERIFICATION.md`** in this phase tree. **Out of scope:** **INV-06** maintainer pass **(b)** substance (Phase **87**), **PROC-08**, **FIN-03**, new billing/admin product features.

**Tooling:** `gsd-sdk query init.phase-op "86"` may return `phase_found: false`; **`.planning/ROADMAP.md`** remains authoritative.

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting (research synthesis: Elixir/Hex norms, INT/ADOPT/ORG-09 culture, Laravel Cashier / Pay-class billing libs, Release Please + linked monorepo)

- **D-00 (cohesion):** Treat **post-publish contract** work as **one atomic integrator-trust story**: the SemVer consumers see on **Hex**, the **install literals** enforced by bash gates, the **adoption proof index**, and **`.planning/`** “last published” mirrors must describe **one** reality at **one** SHA. Splitting “version now, honesty later” is how **false-complete** docs happen (Rails **Pay** / early **stripity_stripe** era: README install lines drifting from released API). **Laravel Cashier**-style success is **pinned Stripe API versions + upgrade guide discipline** — we mirror that with **`@version`** + **`upgrade.md`** + **merge-blocking verifiers**, not marketing-only READMEs.

### Area 1 — PR coupling (version bump vs contract evidence)

- **D-01:** **Default path:** land **`086-VERIFICATION.md`**, all **PPX-touching** doc edits, and **every merge-blocking verifier green** in the **same PR as the linked `mix.exs` `@version` bumps** (the combined Release Please PR or a maintainer batch on top of it **before merge to `main`**). Matches **`RELEASING.md`** combined-PR culture, **`scripts/ci/README.md`** same-PR co-update rules, and **principle of least surprise** for contributors (`main` always honest).
- **D-02 (automation edge):** If a **publish automation misfit** ships version without docs (should be rare with **`release-please.yml`** ordering), allow an **immediate same-day follow-up PR on `main`** that only closes the gap — document the exception in **`086-VERIFICATION.md` Preconditions** with **why** split was unavoidable. **Never** treat “we’ll fix verifiers next week” as acceptable for **PPX-05..07**.

### Area 2 — `086-VERIFICATION.md` depth

- **D-03:** Use **Phase 75-style spine** as the default: **Preconditions** (workspace + Hex versions), **Evidence checklist** mapping **PPX-05..08** → concrete commands / artifacts, **Sign-off**. Fast for reviewers, matches **`75-VERIFICATION.md`** precedent.
- **D-04:** Add a **Transcript annex** (stdout snippets, CI run links, or “copy/paste block from Actions log”) **only when** this PR **changes** a merge-blocking script’s expected output, **adds/removes** a script from the **`docs-contracts-shift-left`** family, or **tightens** requirement wording — avoids **bureaucratic bloat** while preserving **audit defensibility** (good DX for maintainers and for future you).

### Area 3 — PPX-08 vs friction inventory (**INV-06** boundary)

- **D-05:** **Phase 86** closes **PPX-08** by: (a) updating **`.planning/PROJECT.md`**, **`MILESTONES.md`**, **`STATE.md`** to **actual** published versions; (b) for friction-inventory rows **reopened by the publish trigger**, apply **minimal closure**: status, one-line rationale, **pointer** to **`086-VERIFICATION.md`** (and **Phase 87** for **INV-06** when that pass is still pending). **Do not** write the **dated maintainer pass (b)** narrative body in **86** — that is **INV-06 / Phase 87** exclusively. **Footgun avoided:** duplicating **INV-06** in **86** creates two competing “source of truth” subsections and confuses traceability.

### Area 4 — `docs-contracts-shift-left` breadth

- **D-06:** **`086-VERIFICATION.md`** MUST record evidence for the **full** merge-blocking **`docs-contracts-shift-left`** bundle **as wired in `.github/workflows/ci.yml`**, not a hand-picked subset. **Phase 75** already established the **multi-script** pattern; **INT-06** in **`scripts/ci/README.md`** names the family. **Rationale:** “delta-only” verification is a known **footgun** in OSS (green locally, red in CI on untouched gates). **Elixir ecosystem** alignment: treat **CI job** as **contract**, library guidelines favor **reproducible** checks — **full bundle** is the honest integrator story.
- **D-07:** When **only** planning mirrors move with **zero** doc/script delta, still **cite** the CI job (or `workflow_dispatch` replay) proving **green** — don’t skip the job because “I didn’t touch those files.”

### Claude's Discretion

- Exact wording in **`086-VERIFICATION.md`** sign-off and optional one-line preambles.
- Whether transcript annex is one combined section vs per-PPX subsections — keep **falsifiable** and **grep-friendly**.

### Folded Todos

- None — `todo.match-phase` returned no matches.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **PPX-05..PPX-08** (v1.28)
- `.planning/ROADMAP.md` — Phase **86** row, **v1.28** milestone
- `.planning/PROJECT.md` — Milestone narrative + public Hex callouts

### Prior PPX / post-publish family

- `.planning/milestones/v1.23-phases/75-post-publish-contract-alignment/75-VERIFICATION.md` — **PPX-01..04** closure pattern (**lean checklist**)
- `.planning/milestones/v1.26-phases/082-first-hour-portal-spine/082-CONTEXT.md` — Same-PR / milestone canonical path culture (**INT-13**)
- `.planning/milestones/v1.25-phases/081-telemetry-truth-integrator-contracts/081-CONTEXT.md` — **INT-12** same-PR default

### Release + CI SSOT

- `RELEASING.md` — Linked Release Please + Hex ordering
- `.github/workflows/ci.yml` — **`docs-contracts-shift-left`** job membership (**normative**)
- `scripts/ci/README.md` — **INT-06**, **INT-10**, **ORG-09**, triage maps, co-update rules
- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`
- `scripts/ci/verify_production_readiness_discoverability.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_v1_17_friction_research_contract.sh`
- `scripts/ci/verify_core_admin_invoice_verify_ids.sh` (if still in the same CI job set — confirm against **`ci.yml`** at execution time)

### Code-adjacent contracts

- `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- `examples/accrue_host/docs/adoption-proof-matrix.md`

### Friction inventory (pointer only in 86)

- `.planning/research/v1.17-FRICTION-INVENTORY.md` — **PPX-08** row hygiene only; **INV-06** body in Phase **87**

### GSD defaults (shift-left)

- `.planning/config.json` — `workflow.discuss_default_post_publish_*`, `workflow.discuss_publish_contracts_research_depth`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Bash verifier suite** under **`scripts/ci/`** — canonical strings and stderr prefixes already standardized (`verify_package_docs`, `verify_adoption_proof_matrix`, etc.).
- **`package_docs_verifier_test.exs`** — ExUnit mirror for **PPX-05** class drift.

### Established patterns

- **Combined Release Please PR** for **`accrue` + `accrue_admin`** — keeps **`verify_package_docs.sh`** internally consistent (**`RELEASING.md`**).
- **Milestone phase trees** under **`.planning/milestones/v1.*-phases/`** — canonical verification home since **v1.25+** phases.

### Integration points

- **GitHub Actions** job **`docs-contracts-shift-left`** defines which gates are merge-blocking for doc/version slices.
- **`.planning/STATE.md`** **Next** pointers — update after **`086-VERIFICATION.md`** exists.

</code_context>

<specifics>
## Specific Ideas

- User directive (2026-04-24): **all four** gray areas discussed; accept **one cohesive default package** emphasizing **DX**, **least surprise**, **audit honesty**, and **Accrue** vision — defer only **high-impact** forks via existing **`workflow.discuss_high_impact_confirm`** when used in future discuss flows.

</specifics>

<deferred>
## Deferred Ideas

- **INV-06** substantive maintainer pass **(b)** + **`087-VERIFICATION.md`** — Phase **87** only.

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 086-post-publish-contract-alignment*  
*Context gathered: 2026-04-24*
