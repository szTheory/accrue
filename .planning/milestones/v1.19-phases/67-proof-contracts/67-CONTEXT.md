# Phase 67: Proof contracts — Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning / execution (research synthesis update)

<domain>

## Phase boundary

Deliver **PRF-01** and **PRF-02** for milestone **v1.19**: keep **`examples/accrue_host/docs/adoption-proof-matrix.md`** (human SSOT) and **`scripts/ci/verify_adoption_proof_matrix.sh`** (merge-blocking regression harness) aligned on **taxonomy / archetype / row-level** invariants, and make the **matrix + script + tests co-update** rule obvious in **`scripts/ci/README.md`**. Targets **`v1.17-P1-001`** (matrix vs needles drift on taxonomy edits) **before** Phase **68** Hex publish.

**Out of scope:** Rewriting the matrix for editorial polish without a failing contract; migrating the verifier to a Mix task in this phase; new billing primitives; **REL-** / **DOC-** / **HYG-** work except minimal shared literals if unavoidable.

</domain>

<decisions>

## Implementation decisions

### D-01 — Enforcement architecture (idiomatic for this repo)

- **Keep the bash script as the canonical needle list** for merge-blocking substring invariants. **`docs-contracts-shift-left`** already orchestrates multiple bash gates; staying consistent with **`verify_package_docs.sh`**, **`verify_verify01_readme_contract.sh`**, etc. minimizes contributor surprise and avoids duplicating policy in Mix and shell in one phase.
- **Keep ExUnit as a thin harness** where package-level CI already expects `mix test`: `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` shells out to the script and asserts exit `0` + **`verify_adoption_proof_matrix: OK`**. **Do not** add a second parallel list of the same substrings in Elixir unless a requirement explicitly needs Elixir-side parsing (none today).
- **Rationale (ecosystem):** Successful OSS tends to run **the same checks locally as in CI** and avoid **dual enforcement** with conflicting rules. For Accrue, the orchestration layer is bash; contract logic for this gate stays in one file (`verify_adoption_proof_matrix.sh`).

### D-02 — Needle strategy and diminishing returns

- **Add or tighten `require_substring` only for slow-changing, user-visible invariants** tied to ORG-09 / layering / archetype policy (headings, lane labels, stable script names, row ids like **ORG-07** / **ORG-08**, merge-blocking vs advisory semantics). Prefer **short literals** with **actionable stderr** (`matrix missing … (expected substring: …)` — already the pattern).
- **Stop adding needles** when checks would encode **wording polish**, **synonyms**, or **layout-only** churn — that is a signal to rely on **triage docs** and human review, not more grep.
- **Do not** introduce full-file golden snapshots of the matrix for this phase: high churn, noisy diffs, poor DX for prose editors.
- **Optional later (defer):** Markdown structure tests or codegen from YAML — only if substring caps prove insufficient; not default for **67**.

### D-03 — Single change set and SSOT order (locked with Phase 66)

- **Authoritative order:** Edit **`adoption-proof-matrix.md` first** (SSOT), then update **`verify_adoption_proof_matrix.sh`** in the **same commit/PR** when phrases move or taxonomy changes intentionally.
- **ExUnit:** If a future test embeds matrix literals, ship those updates in the **same change set** as matrix + script (**INT-07** precedent). Current **`OrganizationBillingOrg09MatrixTest`** avoids duplicate literals by delegating to bash — **keep that pattern** unless a new invariant cannot be expressed in bash alone.

### D-04 — Contributor triage and DX (**PRF-02**)

- **`scripts/ci/README.md`** is the right home for ORG-09 / adoption-proof triage (already has **`### Triage: verify_adoption_proof_matrix.sh`**). **Extend** that subsection to state explicitly: **matrix SSOT path**, **script as regression harness**, **one change set** (**matrix + script + any literal-bearing ExUnit**), and **link** to **`examples/accrue_host/docs/adoption-proof-matrix.md`**.
- **Failure UX:** Preserve stderr prefix **`verify_adoption_proof_matrix:`** so logs map cleanly to triage tables (aligns with **`[verify_package_docs]`** pattern elsewhere).

### D-05 — What *not* to do (footguns from other ecosystems)

- **Avoid** maintaining the same invariant as **bash needles + Elixir string asserts + README prose** without a single mechanical owner — trilemma that caused **v1.17-P1-001** class drift.
- **Avoid** CI-only behavior that **`CONTRIBUTING.md`** never mentions; keep “run from repo root” consistent with other shift-left scripts.
- **Avoid** brittle full-doc snapshots and **avoid** regex on free-form prose without stable anchors.

### D-06 — Cohesion with project vision

- Decisions above reinforce **evaluator-trustworthy docs**, **least surprise** for Elixir/OSS contributors, **fast deterministic CI**, and **billing state modeled clearly** (proof matrix honestly describes Fake vs Stripe lanes). No new user-facing UI; **DX** is the primary “UX” surface here via clear failures and one place to update needles.

### Claude's discretion

- **Inventory ordering:** When mapping needles → matrix anchors in **67-01**, any reasonable ordering (by section top-to-bottom vs by risk) is fine.
- **Exact new needles after inventory:** Implementer chooses minimal set that satisfies **PRF-01**; stop at diminishing returns per **D-02**.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and risk

- `.planning/REQUIREMENTS.md` — **PRF-01**, **PRF-02** (v1.19)
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — row **`v1.17-P1-001`**

### SSOT and verifiers

- `examples/accrue_host/docs/adoption-proof-matrix.md` — adoption proof SSOT (ORG-09, layering, archetypes)
- `scripts/ci/verify_adoption_proof_matrix.sh` — merge-blocking needle harness
- `scripts/ci/README.md` — contributor map + triage (**ORG** table, **INT-07** notes)

### Tests and related docs

- `accrue/test/accrue/docs/organization_billing_org09_matrix_test.exs` — ExUnit invokes bash (no duplicate needle list today)
- `accrue/test/accrue/docs/organization_billing_guide_test.exs` — related ORG-09 guide contracts (if touched, same PR discipline)
- `.planning/milestones/v1.18-phases/66-onboarding-confidence/66-CONTEXT.md` — **PROOF-01** / matrix-first precedent (**D-05** series)

### CI

- `.github/workflows/ci.yml` — **`docs-contracts-shift-left`** step ordering for shift-left scripts

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`require_substring` helper** in `verify_adoption_proof_matrix.sh` — extend in-place for new invariants; stderr labels already human-readable.
- **`OrganizationBillingOrg09MatrixTest`** — pattern for “**one bash verifier, ExUnit only checks it runs**”; reuse for any sibling doc gate before adding Elixir-side duplicates.

### Established patterns

- **Bash shift-left family** at repo root (`verify_package_docs.sh`, etc.) + **ExUnit** calling bash for package-level **`mix test`** parity — same architectural split as **`PackageDocsVerifierTest`**.

### Integration points

- **CI:** `docs-contracts-shift-left` already invokes this script; changes must stay green under that job.
- **Contributor path:** `scripts/ci/README.md` ORG gates table already points maintainers from **REQ-ID** → script → ExUnit → milestone archive.

</code_context>

<specifics>

## Specific ideas

- Research synthesis (**2026-04-23**): Cross-ecosystem “do this” themes — **one mechanical owner per invariant**, **default path offline/fast**, **avoid dual bash+Elixir literal lists** — map directly to **D-01**–**D-03**. Substring grep gates are appropriate while invariants stay **stable phrases**; **structural AST / codegen SSOT** deferred until substring approach hits diminishing returns (**D-02**, **D-06**).

</specifics>

<deferred>

## Deferred ideas

- **Mix task replacement** for `verify_adoption_proof_matrix.sh` — out of scope for **67**; would be its own phase if Mix-native ergonomics become a priority.
- **Central `needles.json` consumed by bash and Elixir** — only if needle lists sprawl or duplicate across languages; not required while bash remains sole owner (**D-01**).
- **HTML comment row anchors** in the matrix — optional readability win for future structural checks; skip unless inventory shows clear value.

### Reviewed todos (not folded)

- None from `todo.match-phase` for phase **67**.

</deferred>

---

*Phase: 67-proof-contracts*  
*Context gathered: 2026-04-23*
