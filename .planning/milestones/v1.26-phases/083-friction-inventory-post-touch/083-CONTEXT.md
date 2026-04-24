# Phase 83: Friction inventory post-touch - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Satisfy **INV-04** after **INT-13** (Phase **82**) lands: maintainer pass on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** — either **(a)** append **new sourced** **P1** / **P2** rows (full FRG-01 columns, stable **`v1.17-P1-NNN` / `P2-NNN`** ids) when ranked evidence on **`main`** warrants it, **or** **(b)** publish a **dated maintainer certification** that no new sourced rows were warranted, with falsifiable pointers per **`.planning/REQUIREMENTS.md`** (**`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`host-integration`**, **`docs-contracts-shift-left`** green on the reviewed SHA). If **(a)** changes inventory row counts, keep **`scripts/ci/verify_v1_17_friction_research_contract.sh`** green in the **same PR**.

**Out of scope:** **PROC-08**, **FIN-03**, new **`Accrue.Billing`** APIs, admin LiveView unless VERIFY forces it, **INT-13** implementation itself (owned by Phase **82**).

**Tooling note:** `gsd-sdk query init.phase-op "83"` may return `phase_found: false` while the active-milestone table in **`.planning/ROADMAP.md`** remains authoritative — same class of quirk noted in **`082-CONTEXT.md`**.

</domain>

<decisions>
## Implementation Decisions

### Evidence path **(a)** vs **(b)** (INV-04)

- **D-01:** **Default to path (b)** — dated “no new sourced P1/P2 rows warranted” unless ranked evidence clears the FRG-01 bar (primary-tier **`sources`**, **`ci_contract`** / **`integrator_impact`** story, merge-blocking or golden-path stall not better captured by extending an existing row’s **`notes`** / reopen trigger). Aligns with **FRG-02** **S1** / **S5** and Phase **79** **D-01**.
- **D-02:** **Escalate to path (a)** only when a **new** row is strictly better than a paragraph in an existing row — append with stable id; **do not renumber** (Phase **79** **D-02**).

### INV-04 verifier bundle (delta vs INV-03 / Phase 79)

- **D-03:** Every **(b)** certification MUST name, in prose or checklist, that the reviewed SHA was green under: **`verify_package_docs`** (or its CI equivalent), **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`host-integration`**, and **`docs-contracts-shift-left`** — **explicitly** as required by **INV-04** (Phase **79** / **INV-03** named three classes; **INV-04** adds **`docs-contracts-shift-left`**).
- **D-04:** When **(a)** changes P0/P1/P2 row counts, treat **`verify_v1_17_friction_research_contract.sh`** as merge-blocking **paired** change in the **same PR** as the inventory table (**REQUIREMENTS.md** INV-04; Phase **79** **D-08**).

### Where certification lives (SSOT vs phase evidence)

- **D-05:** **Split placement:** Normative dated **INV-04** conclusion (**one** canonical subsection: date + scope + conclusion + **one** reviewed **`main`** merge SHA + pointer to verifier bundle) lives in **`v1.17-FRICTION-INVENTORY.md`** as **`### v1.26 INV-04 maintainer pass (YYYY-MM-DD)`** immediately **after** the existing **`### v1.25 INV-03 maintainer pass`** block (chronological maintainer subsections).
- **D-06:** **`.planning/milestones/v1.26-phases/083-friction-inventory-post-touch/083-VERIFICATION.md`** holds methodology, commands, optional PR links, and verifier transcripts. First line of evidence there must **point to** the inventory subsection as the **single** attestation voice — **no** second independent certification paragraph that could drift (Phase **79** **D-04** / **D-05** pattern).

### Reviewed SHA discipline

- **D-07:** Cite **one** explicit **`main`** merge commit SHA as the reviewed object — not a window (Phase **79** **D-06**).
- **D-08:** Re-certification = **new SHA + new verifier run bundle** in the same change-set ethos as **`scripts/ci/README.md`** same-PR triage (Phase **79** **D-07**).

### Row counts, script contract, longer-term hygiene

- **D-09:** **Do not** merge/replace rows to game row-count asserts — append-only stable ids; co-update the bash script honestly when cardinality changes (Phase **79** **D-08**).
- **D-10 (Claude’s discretion / deferred):** Structural invariants instead of magic row counts — **out of scope** for **83** unless explicitly widened in a future hygiene phase (Phase **79** **D-09**).

### Revisit triggers (content guidance)

- **D-11:** **`### v1.26 INV-04 maintainer pass`** must include **revisit triggers** in the same family as **v1.25 INV-03** (e.g. next linked Hex publish, intentional adoption-matrix taxonomy / Layer C rename without same-PR **`verify_adoption_proof_matrix.sh`** co-update, merge-blocking **`host-integration`** / **`docs-contracts-shift-left`** failure documenting a new stall). Add at least one trigger tied to **INT-13-class** integrator surfaces (**billing portal** facade + First Hour / host README / matrix needles) drifting on **`main`** without a sourced row update.

### Discuss-phase execution note

- **D-12:** Per **`.planning/config.json`** **`workflow.discuss_auto_all_gray_areas`** and **`workflow.research_before_questions`**, this context was captured with **all** gray areas selected and research-informed defaults; planner/executor should still read **REQUIREMENTS.md** before implementation.

### Folded Todos

- None — `todo.match-phase` returned no matches for phase **83**.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **INV-04** (authoritative acceptance)
- `.planning/ROADMAP.md` — Phase **83** row, **v1.26** milestone
- `.planning/PROJECT.md` — Maintenance posture; **no** **PROC-08** / **FIN-03**

### Friction SSOT and doctrine

- `.planning/research/v1.17-FRICTION-INVENTORY.md` — Evidence SSOT; append **INV-04** subsection after **INV-03** block
- `.planning/research/v1.17-north-star.md` — **S1**, **S5** stop rules

### Verifiers and triage

- `scripts/ci/verify_v1_17_friction_research_contract.sh` — Row-count contract; co-update with inventory if **(a)**
- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`
- `scripts/ci/verify_verify01_readme_contract.sh` — When **#proof-and-verification** / VERIFY-01 README contract is in scope for the touched tree
- `.github/workflows/ci.yml` — **`host-integration`**, **`docs-contracts-shift-left`** job names as evidence anchors
- `scripts/ci/README.md` — Same-PR co-update triage

### Prior pattern and INT-13 closure

- `.planning/milestones/v1.25-phases/079-friction-inventory-maintainer-pass/079-CONTEXT.md` — **INV-03** maintainer-pass decisions (baseline for **83**)
- `.planning/milestones/v1.25-phases/079-friction-inventory-maintainer-pass/079-VERIFICATION.md` — Evidence layout reference
- `.planning/milestones/v1.26-phases/082-first-hour-portal-spine/082-VERIFICATION.md` — **INT-13** landed; pre-requisite for **INV-04** pass scope

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`v1.17-FRICTION-INVENTORY.md`** — Maintainer-dated subsections (**v1.20**, **v1.25 INV-03**); extend with **v1.26 INV-04** block.
- **`verify_v1_17_friction_research_contract.sh`** — Fixed P0/P1/P2 row counts; pair edits with any new inventory rows.

### Established patterns

- **Evidence over vibes:** Certification = date + scope + SHA + named verifier greens; rows = full FRG-01 column contract + **`sources`**.
- **Append-only ids:** **`v1.17-P*-NNN`** — never renumber to satisfy the script.

### Integration points

- **`083-VERIFICATION.md`** links up to inventory subsection and down to CI / local verifier transcripts.
- **`.planning/REQUIREMENTS.md`** traceability table — mark **INV-04** complete when **`083-VERIFICATION.md`** and inventory subsection ship.

</code_context>

<specifics>
## Specific Ideas

- Treat **83** as **INV-04**-shaped **79**: same **(b)**-default maintainer culture; **mandatory** inclusion of **`docs-contracts-shift-left`** in the certification bundle per **REQUIREMENTS.md** (not optional “extra”).
- Revisit triggers should explicitly mention **billing portal** / **INT-13** needle drift so the post–**82** world is not invisible to the next maintainer.

</specifics>

<deferred>
## Deferred Ideas

- Structural verifier refactor (checksum / invariants instead of magic row counts) — future hygiene phase (**79** **D-09** family).

**None — discussion stayed within phase scope** for net-new capabilities.

</deferred>

---

*Phase: 83-friction-inventory-post-touch*  
*Context gathered: 2026-04-24*
