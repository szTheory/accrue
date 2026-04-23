# Phase 64: P0 billing - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase **64** closes **BIL-03** for **v1.17**: for every **P0** backlog row tagged **billing** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`**, ship bounded **`Accrue.Billing` / `lattice_stripe` / Fake** work with regressions plus **`accrue/guides/telemetry.md`** + **`accrue/CHANGELOG.md`** (+ installer / First Hour pointers when public API or host stub changes) **or** certify **no P0 billing rows** this milestone with **signed rationale in the inventory** and auditable phase closure (**`64-VERIFICATION.md`**). **No PROC-08** / **FIN-03**. Any public **`Accrue.Billing`** surface change ships **Fake** coverage and doc/telemetry/changelog alignment as applicable (**ROADMAP** success criterion).

**Current evidence:** **`### Backlog — BIL-03 (Phase 64)`** lists **no P0 rows** (empty queue unless new evidence is promoted through **FRG-01**).

</domain>

<decisions>
## Implementation Decisions

*Research: four parallel maintainer-grade passes (closure artifacts, empty-queue audit bar, Hex-facing changelog/telemetry policy, late P0 routing) synthesized into one coherent bar — user selected **all** gray areas and asked for a single recommendation set aligned with Accrue’s OSS billing posture, Elixir/Hex norms (signal in CHANGELOG, automate structure not narrative), and ecosystem patterns (Cashier/Pay/Stripe: ship notes reflect artifacts; triage lives in tracker/SSOT; Rust/K8s/Shape Up: traceability + appetite, no silent scope).*

### D-01 — Closure artifacts (inventory + verification + CI)

- **D-01a (REQUIREMENTS floor):** Keep **signed maintainer certification** under **`### Backlog — BIL-03`** in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** — this is the **explicit `or`** branch text in **BIL-03** and must remain the durable **FRG-01/03** statement that the billing P0 queue is empty (or updated if rows appear).
- **D-01b (auditable parity with Phase 63):** Add **lean `64-VERIFICATION.md`** with the same **family** as **`63-VERIFICATION.md`**: phase scope (**BIL-03** only) + pointer to **`#backlog--bil-03-phase-64`** + **traceability table** (rollup **BIL-03**; one row per future billing P0 row if any) + **acceptance one-liner** + **merge-blocking vs manual** proof column + closure steps (**`REQUIREMENTS.md`** checkbox, inventory disposition). **No** essay-length restatement of **`ci.yml`**.
- **D-01c (friction script / SSOT):** **Do not** add **semantic** billing-P0 rules to **`scripts/ci/verify_v1_17_friction_research_contract.sh`** (e.g. billing P0 row counts mirroring INT-10) — that **duplicates** inventory meaning and will fight triage edits. Keep existing **anchor + ROADMAP link** checks. **Optional later:** a **single** intentional milestone edit could add **purely structural** needles (e.g. verification file exists) **only** if applied **symmetrically** to **63/64/65** so CI does not encode one-off prose.
- **D-01d (anti-patterns):** No **checklist theater** (verification doc without commands / trace IDs); no **second taxonomy** in bash; no implying **grep** substitutes for maintainer judgment on P0 quality.

### D-02 — Audit bar when the billing P0 queue is empty

- **D-02a (default bar):** **Inventory certification + thin bounded checklist** in **`64-VERIFICATION.md`**: (1) reconcile **FRG-03** billing slice — **zero** P0 billing rows **or** each candidate explicitly **downgraded** / **`not_v1.17`** with signed **`notes`**; (2) if **no** billing-shaped code/docs shipped this phase — one explicit line (**no** `Accrue.Billing` / Fake / public API / host stub churn); (3) if **code did ship** — explicit ticks for **Fake**, **`accrue/guides/telemetry.md`**, **`CHANGELOG`** per **BIL-03**.
- **D-02b (CI):** **Do not** merge-block on **regex** against inventory **prose** beyond the **existing** friction contract (brittle, trains cosmetic edits, false confidence). **Optional** local/pre-commit helpers are fine; merge-blocking stays **structural** + **tests** + existing verifiers.
- **D-02c (footguns):** A checklist without **FRG-01** reconciliation is **audit theater**; missing a real P0 is fixed by **better evidence in FRG-01**, not by infinite grep.

### D-03 — `CHANGELOG` + `telemetry.md` when nothing ships

- **D-03a (default):** If the queue stays **empty** and **no** bounded **BIL-03** billing work ships — **no required edits** to **`accrue/CHANGELOG.md`** or **`accrue/guides/telemetry.md`**. This matches **BIL-03** grammar: telemetry/changelog are part of the **ship** branch; the **certify empty + signed inventory rationale** branch is the **full alternative**.
- **D-03b (optional doc polish):** If a **concrete** integrator-facing defect exists in the telemetry guide, fix it in a normal PR; if it ships in a release, log under **`### Documentation`** (or equivalent) — describe **what became clearer**, not milestone process (“no P0”).
- **D-03c (consumer signal):** **Do not** add CHANGELOG lines like *“No billing P0 this milestone”* — wrong audience (Hex users care about **artifact deltas**, not **`.planning/`** process). Process closure lives in **inventory + `64-VERIFICATION.md`**.

### D-04 — New billing P0 evidence after planning starts

- **D-04a (no silent absorption):** New evidence → **new or updated row** in **`v1.17-FRICTION-INVENTORY.md`** (stable **`v1.17-P*-NNN`**, **`sources`**, **`ci_contract`**, **`integrator_impact`**, **`req`**, **`frg03_disposition`**). No off-books **`Accrue.Billing`** / Fake / telemetry changes that imply a new P0 without inventory + **FRG-03** alignment.
- **D-04b (re-triage mandatory):** Apply the **Phase 62** two-axis bar; if it is **not** truly P0 for the billing integrator story, **downgrade** with maintainer-signed **`notes`** / mini-ADR (reuse **Phase 63** disposition pattern).
- **D-04c (true P0 + BIL-03):** If the row survives as **P0** with **`req` = BIL-03** and **`→64`**, **Phase 64** executes the **full BIL-03 ship bar** (bounded code + regressions + Fake + telemetry + changelog as applicable) — **not** “defer to informal follow-up” without milestone / **REQUIREMENTS** honesty.
- **D-04d (`not_v1.17`):** Allowed only with **signed rationale + revisit trigger** per **Phase 62**; never as a shadow bypass for real golden-path billing stalls.

### Claude's Discretion

- **`64-VERIFICATION.md`** exact table layout and column headers — mirror **`63-VERIFICATION.md`** closely enough that maintainers recognize one pattern.
- Whether to add **symmetric structural** friction-script checks for **`*-VERIFICATION.md`** existence across **63–65** — **defer** unless a single PR introduces the trilogy intentionally.

### Folded Todos

- None.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Obligations + backlog

- `.planning/REQUIREMENTS.md` — **BIL-03** definition + traceability
- `.planning/ROADMAP.md` — Phase **64** goal, success criteria, **FRG-03** slice link
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — **`### Backlog — BIL-03 (Phase 64)`**, FRG-01 table + disposition rules
- `.planning/research/v1.17-north-star.md` — **FRG-02** stop rules

### Prior phase context

- `.planning/phases/63-p0-integrator-verify-docs/63-CONTEXT.md` — verification shape, downgrade mini-ADR, handoff that **64** owns heavier billing matrices **when** P0 work exists
- `.planning/phases/63-p0-integrator-verify-docs/63-VERIFICATION.md` — template for lean phase verification
- `.planning/phases/62-friction-triage-north-star/62-CONTEXT.md` — **FRG-03** firewall, two-axis P0 bar, **research/** SSOT layout

### Machine contracts (edit only with intent + tests)

- `scripts/ci/verify_v1_17_friction_research_contract.sh` — friction inventory / ROADMAP anchors (**do not** extend with billing P0 semantics per **D-01c** without milestone-wide policy)

### Library surfaces (when BIL-03 code ships)

- `accrue/lib/accrue/billing.ex` and related **`accrue/lib/accrue/billing/**`**
- `accrue/lib/accrue/processor/fake.ex`
- `accrue/guides/telemetry.md`
- `accrue/CHANGELOG.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Accrue.Billing`** and **`Accrue.Processor.Fake`** — primary integration points for any **BIL-03** code work; follow existing Fake coverage patterns when touching public billing surfaces.
- **`scripts/ci/verify_v1_17_friction_research_contract.sh`** — already enforces **BIL-03** backlog **anchor** and **ROADMAP** inventory link; reuse for structural hygiene only.

### Established patterns

- **Phase 63** closure: **`63-VERIFICATION.md`** + inventory row updates + **`REQUIREMENTS`** checkbox; **ExUnit** wrappers only where a verifier contract already exists.
- **FRG-01/03** live in **`research/`**, not only under ephemeral **`phases/`** trees.

### Integration points

- **`REQUIREMENTS.md`** traceability row **BIL-03** ↔ Phase **64**
- **`STATE.md`** / **`PROJECT.md`** milestone pointers after closure

</code_context>

<specifics>
## Specific Ideas

- User requested **subagent-backed** ecosystem desk research (Hex/OSS, Cashier/Pay/Stripe-style release hygiene, Rust RFC / K8s labels / Shape Up appetite) and a **single coherent** maintainer recommendation set — captured as **D-01–D-04**.

</specifics>

<deferred>
## Deferred Ideas

- **Symmetric “verification file exists” CI needle** across **63/64/65** — only if maintainers want one PR to add structural checks without encoding inventory semantics.

**None — discussion stayed within phase scope** beyond the explicit deferral above.

</deferred>

---

*Phase: 64-p0-billing*  
*Context gathered: 2026-04-23*
