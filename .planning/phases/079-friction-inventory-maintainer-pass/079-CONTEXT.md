# Phase 79: Friction inventory maintainer pass - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Post–**v1.24** maintainer pass on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** satisfying **INV-03**: either **(a)** new **sourced** P1/P2 rows with full column contract and stable **`v1.17-P*-*`** ids when ranked evidence on **`main`** warrants it, **or** **(b)** a **dated maintainer certification** that no new sourced rows were warranted, with **falsifiable** pointers (named **`main` merge SHA**, **`verify_package_docs`**, **`verify_adoption_proof_matrix.sh`**, **VERIFY-01** / **`host-integration`** green on that tree). If **(a)** changes inventory shape/counts expected by **`scripts/ci/verify_v1_17_friction_research_contract.sh`**, update that script **in the same PR**.

**Out of scope for this phase:** **BIL-06** / checkout facade (**Phase 80**), telemetry catalog / integrator co-updates (**Phase 81**), **PROC-08**, **FIN-03**.

</domain>

<decisions>
## Implementation Decisions

### Evidence path (INV-03 (a) vs (b))

- **D-01:** **Default to path (b)** — dated “no new sourced rows warranted” certification unless **ranked** evidence clears the P1/P2 bar (primary-tier source, merge-blocking / golden-path story, or verifier-named failure). Matches **FRG-02** stop rules **S1** / **S5** and maintenance posture: rows are **high-signal liabilities**, not a vibes backlog.
- **D-02:** **Escalate to path (a)** only when adding a row is **strictly better** than a paragraph in an existing row’s `notes` / reopen trigger: new integrator stall with **sources**, **`ci_contract`**, **`integrator_impact`**, stable new **`v1.17-P1-NNN` / `P2-NNN`** id per inventory rules (**append**, **do not renumber**).
- **D-03:** Certification is **not theater**: every (b) pass must include **date**, **scope** (what was / was not reviewed against the FRG-01 bar), **one reviewed merge SHA**, the **three verifier classes** named in **INV-03**, and **explicit revisit triggers** (e.g. next linked Hex publish, intentional adoption-matrix taxonomy edit) — mirroring the existing **v1.20 evidence refresh** pattern in the inventory.

### Where certification lives (SSOT vs phase evidence)

- **D-04:** **Split placement (canonical + audit trail):** Put the **normative** dated INV-03 certification (**one canonical paragraph**: conclusion + date + scope + SHA pointer) in **`v1.17-FRICTION-INVENTORY.md`** as a new maintainer subsection (same family as `### v1.20 evidence refresh`).
- **D-05:** **`079-VERIFICATION.md`** holds **methodology and evidence** (commands run, optional PR links, checklist). First line of that section must **point to** the inventory subsection as the **single** attestation voice — **no second independent “we certify” paragraph** that could drift (footgun avoided).

### Reviewed SHA discipline

- **D-06:** Cite **one explicit `main` merge commit SHA** as the reviewed object — **not** a fuzzy commit window. Windows are weak forensic evidence (“green at HEAD” ≠ green for every intermediate commit) and surprise integrators; a single SHA is reproducible (`git checkout <sha>` + same verifier bundle).
- **D-07:** Re-certification = **new SHA + new verifier run bundle** in the same documentation change-set ethos as **`scripts/ci/README.md`** same-PR triage: do not move the cited SHA without re-running the named checks against that tree.

### Inventory rows vs `verify_v1_17_friction_research_contract.sh`

- **D-08:** **Do not merge/replace rows** merely to preserve row-count asserts — that fights **append-only stable ids** and blurs audit history. If legitimate new friction requires a **new** row, **append** the row and **update the bash script’s expected counts (and any related asserts) in the same PR** per **INV-03** (current contract is rigid cardinality; least surprise for contributors = **one PR**, table + verifier).
- **D-09 (Claude’s discretion / deferred engineering):** Longer term, prefer **structural invariants** (unique ids, required columns, optional normalized checksum) over magic row counts — **out of scope for Phase 79** unless this phase explicitly chooses to widen the verifier; if done later, do it as a **dedicated** hygiene phase with the same “no silent drift” discipline. Until then, treat the script as part of the **merge-blocking contract** and co-update it honestly.

### Maintainer UX (research synthesis — user preference)

- **D-10:** **Discuss-phase default for this repo:** Prefer **research-before-questions** and **all gray areas** when running `/gsd-discuss-phase` for *process/evidence* phases like **79**, so maintainers get **one-shot** tradeoff synthesis without re-prompting for area selection — **except** when a phase touches **security, semver/Hex publish, or user-visible API contracts** (then require explicit human confirmation in discuss). Recorded in **`.planning/config.json`** via `workflow.research_before_questions` and `workflow.discuss_auto_all_gray_areas`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **INV-03** checkbox (authoritative acceptance for Phase 79)
- `.planning/ROADMAP.md` — Phase **79** row and **v1.25** milestone boundary
- `.planning/PROJECT.md` — Maintenance posture, **FRG-01** / north-star pointers, non-goals (**PROC-08**, **FIN-03**)

### Friction SSOT and doctrine

- `.planning/research/v1.17-FRICTION-INVENTORY.md` — Evidence SSOT; inventory table; maintainer refresh subsection pattern (**v1.20** model)
- `.planning/research/v1.17-north-star.md` — **S1**, **S5** stop rules; marginal dev value definitions

### Verifiers and triage culture

- `scripts/ci/verify_v1_17_friction_research_contract.sh` — Row-count and anchor contract (co-update with inventory edits)
- `scripts/ci/verify_package_docs.sh` — Named in **INV-03** certification
- `scripts/ci/verify_adoption_proof_matrix.sh` — Named in **INV-03** certification
- `scripts/ci/README.md` — Same-PR co-update triage discipline (align INV-03 SHA policy with this culture)

### Prior milestone evidence (pattern reference)

- `.planning/milestones/v1.20-phases/70-friction-evidence-refresh/70-VERIFICATION.md` — Prior **INV-01/INV-02** friction pass evidence style (analog for **79-VERIFICATION.md**)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`v1.17-FRICTION-INVENTORY.md`** already models maintainer-dated evidence blocks and closed-row **`notes`** with milestone pointers — extend that pattern for **v1.25** / **INV-03** rather than inventing a new format.
- **`verify_v1_17_friction_research_contract.sh`** encodes structural anchors (P0/P1/P2 counts, backlog headers, **STATE** / **PROJECT** / **ROADMAP** pointers) — treat edits as **paired** with inventory edits.

### Established Patterns

- **Evidence over vibes:** Rows require **`sources`** and triage axes; certification must be **falsifiable** against named verifiers + SHA (parallel to Stripe-style dated changelogs / K8s-style structured notices: conclusion + pointer, not undifferentiated noise).
- **Append-only ids:** **`v1.17-P*-NNN`** stable namespace — never “replace to keep count”; co-update the verifier when cardinality legitimately changes.

### Integration Points

- **Phase verification:** **`079-VERIFICATION.md`** links upward to inventory certification and downward to any PRs that touched **`verify_v1_17_friction_research_contract.sh`** or inventory rows.
- **STATE.md / MILESTONES.md:** After Phase 79 complete, pointers and “next phase” banners should reflect **INV-03** closure without duplicating inventory tables.

</code_context>

<specifics>
## Specific Ideas

- Subagent research compared maintainer habits to **Stripe API changelog / versioning**, **Kubernetes deprecation/KEP** discipline, and **Go module policy** patterns: **time-stamped, pointer-rich** statements beat continuous low-signal row growth; **named release or SHA** beats ambiguous “we looked at main for a while.”
- User preference (shift-left): **default deep research + all gray areas** in discuss for *low-blast-radius planning phases*; keep human gate for **high-impact** contract phases — encoded in **`.planning/config.json`**.

</specifics>

<deferred>
## Deferred Ideas

- **Verifier evolution:** Replace rigid P0/P1/P2 **row counts** with structural checks (unique `id`, required fields, normalized row checksum) — valuable but **not required** to satisfy **INV-03**; would be its own small hygiene phase if undertaken.

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 79-friction-inventory-maintainer-pass*  
*Context gathered: 2026-04-24*
