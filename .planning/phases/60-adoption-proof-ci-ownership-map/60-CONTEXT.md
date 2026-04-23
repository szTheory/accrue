# Phase 60: Adoption proof + CI ownership map - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

**INT-07:** **`examples/accrue_host/docs/adoption-proof-matrix.md`** and **`evaluator-walkthrough-script.md`** stay honest vs the **current** golden path, **VERIFY-01** lanes, and **v1.15** trust signals **where those files are SSOT**; **`scripts/ci/README.md`** (or successor contributor map) names **owning verifiers** for **new/changed merge-blocking checks** touched by milestone **v1.16** (phases **59–61**).

**Not in this phase:** INT-08/09 (Phase **61**), full-repo CI graph rewrite unless a check is **actually** touched, new billing APIs, **PROC-08** / **FIN-03**.

</domain>

<decisions>

## Implementation decisions

Cross-cutting: decisions below are **one package** — they align **Diátaxis** roles (matrix + walkthrough = how-to / evaluation instruments; First Hour + host README = explanation SSOT), **Phase 59** locks (bash trio, no “markdown skips `host-integration`”, Hex vs `main` honesty), and **least surprise** for contributors (registry pattern already established in `scripts/ci/README.md`).

### 1 — `scripts/ci/README.md` ownership layout (INT-07)

- **D-01 (primary — new homogenous section):** Add a dedicated gate-family section for **INT / v1.16 continuity** using the **same column schema** as existing **ADOPT** and **ORG** tables (REQ-ID, primary script(s) or artifact, package ExUnit if any, phase `VERIFICATION.md` owner). Keeps mental model “one registry file, uniform tables” — closer to **explicit OSS registries** (e.g. Kubernetes-style clarity) than median Elixir libs, which matches Accrue’s **existing** choice.

- **D-02 (conditional — extend ADOPT/ORG only when semantically true):** Add rows or columns to **ADOPT** or **ORG** **only** when the new check is genuinely **adoption**- or **org-billing**-shaped. Do **not** stretch ADOPT/ORG for cross-cutting integrity work — avoids taxonomy rot and “wrong bucket” triage.

- **D-03 (supplement only — not sole SSOT):** PR descriptions, changelog callouts, or one-off links are fine **as supplements**; they **must not** replace durable rows in the contributor map for merge-blocking gates.

### 2 — Adoption matrix vs evaluator walkthrough parity

- **D-04 (hybrid — default):** Treat **`adoption-proof-matrix.md`** as the **authoritative claim catalog** (what is proven, which lane: Fake merge-blocking vs advisory, pointers to tests/scripts). Treat **`evaluator-walkthrough-script.md`** as a **human journey / sampling plan** that stays **honest about the same lanes** but **does not** require **command-for-command** duplication of README or CI.

- **D-05 (traceability without false precision):** Require **stable references** from the walkthrough to the matrix (e.g. section anchors / row identifiers / “see matrix §…”) so evaluators can trace claims; avoid implying **stricter** proof than CI provides (classic footgun when prose outruns Fake-backed reality).

- **D-06 (strict parity — deferred unless automated):** Full step↔row↔README-anchor parity is **out of scope** unless paired with **generation or CI link checks** from a single source; otherwise maintenance cost and drift dominate. If the project later adds automation, revisit.

### 3 — v1.15 trust signals inside matrix + walkthrough (SSOT hygiene)

- **D-07 (hybrid thin-but-scannable):** In matrix and walkthrough, repeat **only evaluation-critical atomic claims** as **short, stable** bullets or one-liners (e.g. Hex SemVer vs internal planning labels; demo/optional adapter **not** production default). Use **deep links** to **First Hour**, **host README**, and **`auth_adapters.md`** for full narrative — **no** triplicated long trust essays.

- **D-08 (Diátaxis alignment):** Long “why we’re trustworthy” prose stays in **explanation** SSOT (First Hour / README); matrix and walkthrough stay **scanner-friendly** instruments — **Twilio/MDN-style** boundary stubs where link-only UX would fail an evaluator, **Stripe-style** single canonical deeper pages for policy facts.

### 4 — Scope of the contributor map update (INT-07 literal)

- **D-09 (narrow execution — primary):** Update **owning verifier** rows **only** for merge-blocking checks that phases **59–61** **add, remove, rename, or materially change** (including **successor** scripts named in roadmap/requirements). Matches **INT-07** literal: **new/changed** and **touched by this milestone**.

- **D-10 (honesty without boiling the ocean):** Add an explicit **scope note** in the INT section (or README preface): the map is **delta-maintained** for this milestone’s touched checks; **normative completeness** of required GitHub checks remains **`.github/workflows/ci.yml`** + **branch protection** (per Phase **59**). Prevents **false completeness** when readers treat the markdown registry as the whole graph.

- **D-11 (full-map audit — separate work):** A **whole-repo** re-audit of every merge-blocking job belongs in a **dedicated hygiene phase** if systemic drift is suspected — **not** bundled into Phase **60** under INT-07.

### Claude's discretion

- Exact **section title** for the INT table and **wording** of the scope note (D-10).
- Whether matrix rows gain **explicit stable IDs** (e.g. `CAP-…`) in this phase vs a follow-up — **recommended** if cheap, but not blocking planning if deferred.
- Triage bullet additions per script following the existing ADOPT/ORG pattern.

### Folded todos

*(None.)*

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **INT-07** (adoption proof + CI ownership map)
- `.planning/ROADMAP.md` — Phase **60** goal and success criteria (**v1.16**)
- `.planning/PROJECT.md` — Core value, v1.16 theme, non-goals (**PROC-08**, **FIN-03**)

### Prior phase continuity

- `.planning/phases/59-golden-path-quickstart-coherence/59-CONTEXT.md` — **INT-06** decisions (bash trio order, merge-blocking definition, Hex vs `main`, Sigra vs `Accrue.Auth`, verifier philosophy)

### Proof artifacts and contributor map (SSOT surfaces)

- `examples/accrue_host/docs/adoption-proof-matrix.md` — claim catalog, layers B/C, ORG-09, advisory vs blocking lanes
- `examples/accrue_host/docs/evaluator-walkthrough-script.md` — evaluator screen-recording checklist
- `scripts/ci/README.md` — contributor verifier / triage map (**extend per D-01–D-03, D-09–D-10**)
- `.github/workflows/ci.yml` — normative required-job graph (with branch protection)
- `CONTRIBUTING.md` — contributor routing to `scripts/ci/` map (if present; align cross-links when editing)

### Verifiers (likely touched when docs change)

- `scripts/ci/verify_adoption_proof_matrix.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_package_docs.sh` — when matrix/walkthrough paths or needles change

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`scripts/ci/README.md`:** Established **ADOPT** + **ORG** tables, REQ-ID columns, triage sections (`verify_package_docs`, `verify_adoption_proof_matrix`) — extend with **matching shape** (D-01).
- **`examples/accrue_host/docs/adoption-proof-matrix.md`:** Layer B vs C, ORG-09 primary vs recipe rows, Stripe advisory lane — canonical **claim inventory**.
- **`examples/accrue_host/docs/evaluator-walkthrough-script.md`:** Sections A–E already mirror Fake vs Stripe story — refine against matrix + v1.15 signals without duplicating First Hour.

### Established patterns

- **Registry + triage** in one markdown file beats PR-only folklore for merge-blocking CI (Accrue-specific; stronger than typical Elixir OSS).
- **Phase `VERIFICATION.md` pointers** per REQ row — keep for INT rows.

### Integration points

- **`verify_adoption_proof_matrix.sh`** enforces matrix literals — matrix edits may require **paired** script updates (existing ORG-09 discipline).
- **Phase 61** will own README hop budget + Hex doc SSOT — Phase **60** should **not** pre-empt INT-08/09 wording beyond **consistency** with decisions here.

</code_context>

<specifics>

## Specific ideas

- User requested **all four** gray areas be explored; research was delegated to parallel agents and synthesized into the decisions above — **coherent defaults** so planning can proceed without reopening the same tradeoffs.

</specifics>

<deferred>

## Deferred ideas

- **Full CI contributor-map audit** — separate hygiene phase if drift is systemic (D-11).
- **Machine-generated strict parity** between matrix, walkthrough, and README anchors — only if automation is introduced (D-06).

### Reviewed todos (not folded)

*(None.)*

</deferred>

---

*Phase: 60-adoption-proof-ci-ownership-map*  
*Context gathered: 2026-04-23*
