# Phase 62: Friction triage + north star - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase **62** delivers **planning artifacts only**: evidence-ranked **FRG-01** inventory, written **FRG-02** north star + stop rules, and **FRG-03** scoped P0 backlog mapping (every P0 → **INT-10** / **BIL-03** / **ADM-12** or explicit **`not_v1.17`**). No product code changes are required to **close** the phase beyond committing markdown and pointers; execution happens in **63–65**.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Artifact layout + SSOT (research synthesis)

- **D-01a:** **FRG-01 + FRG-03** share one durable file: **`.planning/research/v1.17-FRICTION-INVENTORY.md`** (matches existing **`v1.9-*`**, **`v1.10-*`** research naming). Tables + deferrals + **FRG-03** routing live here — **not** only under **`.planning/phases/`** (risk from **`phases.clear`**).
- **D-01b:** **FRG-02** canonical prose lives in **`.planning/research/v1.17-north-star.md`** (policy separated from volatile evidence tables — fewer merge conflicts; skimmers open north star without scrolling the inventory).
- **D-01c:** **`.planning/STATE.md`** holds **pointers only** (paths, cursor) — **no** duplicate P0 tables or backlog counts.
- **D-01d:** **`.planning/REQUIREMENTS.md`** remains obligation + traceability **SSOT** (checkboxes + table); link to research files — **do not** paste the full inventory twice.
- **D-01e:** **`.planning/ROADMAP.md`** stays phase **schedule**; optional **one line per phase 63–65** linking to an **anchor** in the inventory — **never** duplicate row bodies (drift footgun).
- **D-01f:** **Public** integrator docs stay **`accrue/guides/`**, **`CHANGELOG`**, host README; friction **evidence** stays under **`.planning/research/`** unless a guide needs a short “known sharp edges” subsection with a **stable link** back.

**Ecosystem rationale:** Hex libs (Oban, Ecto-style **`guides/`**) separate **ship-facing** docs from **maintainer** process. Pay/Cashier/Stripe teach **predictable navigation** and **avoid duplicating vendor reference** in two places. **Least surprise** for Accrue: **`REQUIREMENTS`** = what must be true, **`research/*`** = evidence + backlog, **`STATE`** = where we are.

### D-02 — P0 / P1 / P2 bar + sources (research synthesis)

- **D-02a:** Use **two axes** per row: **`ci_contract`** (`merge_blocking` | `advisory` | `n/a`) and **`integrator_impact`** (`blocks_golden_path` | `blocks_secondary_path` | `no_workaround` | `workaround_documented`). **Triage P0** is **not** “CI red only” and **not** “any annoyance” — definition is locked in **`v1.17-north-star.md`** + the inventory template.
- **D-02b:** **FRG-03** is a **scope firewall**: only **P0** rows with **`req`** ∈ {**INT-10**, **BIL-03**, **ADM-12**} enter phases **63–65**; everything else stays in **FRG-01** as **P1+**, **`downgraded`**, or **`not_v1.17`** with **maintainer-signed** rationale and **revisit trigger**.
- **D-02c:** **Sources:** ≥1 evidence link per row from an allowed set (verifier + path, CI, issue, doc anchor, matrix row). **`secondary`** tier allowed only with a **promotion/downgrade hypothesis** for the next cycle.
- **D-02d:** **Defer rows** must include: original hypothesis, **why not v1.17**, **future owner** (req id or parking lot), **revisit condition**.

**Ecosystem rationale:** Kubernetes-style **separate dimensions** beat one overloaded priority label. **FRG-03** stays auditable without absorbing every polish item (MoSCoW / SRE-severity borrowing without ceremony).

### D-03 — North star + stop rules voice (research synthesis)

- **D-03a:** **`.planning/PROJECT.md`** § Current milestone carries **short bullets** (north star one-liner + pointer) — **not** the full essay (avoids drift vs checklists).
- **D-03b:** Expanded **principles + exit tests** live in **`v1.17-north-star.md`** (hybrid: **principles** for judgment, **binary / queue-based** stops tied to P0 queues, verifiers, phase boundaries).
- **D-03c:** **Wrong patterns to avoid:** orphan strategy file, vague “quality” without exit tests, duplicate milestone paragraphs across ROADMAP/PROJECT/CONTEXT, stop rules that **add** hidden scope.

**Ecosystem rationale:** Shape Up **appetite + cuts**, light **design-doc** top + appendix — fit **small core team** OSS.

### D-04 — FRG-03 traceability + IDs (research synthesis)

- **D-04a:** **Option A (default):** Row-level **FRG-03** data lives **only** in **`v1.17-FRICTION-INVENTORY.md`**. **ROADMAP** does not hold a second table.
- **D-04b:** **Optional thin index (C):** Under phases **63–65** in **ROADMAP**, at most **one markdown link** per phase to the inventory anchor (e.g. `#backlog--int-10`) — **pointer only**.
- **D-04c:** Row IDs: **`v1.17-P0-NNN`** (and P1/P2) — immutable; **`req`** column mandatory for disposition; do **not** use **FRG-03** as a row prefix (it is a requirement **id**, not a work-item namespace).

**Ecosystem rationale:** Rust **tracking issue** / RFC patterns — **one granular SSOT**, thin index elsewhere, **requirement IDs** for grep and PR titles.

### D-05 — Subagent research (method)

Four parallel researchers covered: OSS layout (Pay, Oban, Phoenix guides, Stripe SDK patterns), prioritization frameworks (RICE, MoSCoW, SRE severity, K8s labels), documentation strategy (PR-FAQ, Shape Up, GDS), and backlog traceability (RFC-style IDs, GitHub vs markdown SSOT). **Synthesis** above is the **coherent** merge — no contradictions: **research/** holds evidence + backlog; **north star** file holds FRG-02; **two-axis** priority; **FRG-03** routing rules; **ROADMAP** index optional only.

### Claude's Discretion

- None for layout: paths and split (**D-01**) are **locked**.
- **Optional ROADMAP anchors** (**D-04b**): add when phase **63** planning starts if navigation helps; not required for **62** completion.

### Folded Todos

- None (`todo.match-phase` returned **0**).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone + obligations

- `.planning/REQUIREMENTS.md` — **FRG-01..FRG-03**, **INT-10**, **BIL-03**, **ADM-12** definitions and traceability table
- `.planning/ROADMAP.md` — Phases **62–65** goals and success criteria
- `.planning/PROJECT.md` — Core value, **v1.17** milestone intent, non-goals (**PROC-08** / **FIN-03**)
- `.planning/STATE.md` — Session pointer + **FRG-01** path (must stay in sync with **D-01**)

### v1.17 triage SSOT (this phase)

- `.planning/research/v1.17-north-star.md` — **FRG-02** north star + stop rules
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — **FRG-01** inventory + **FRG-03** backlog schema

### Evidence sources (non-exhaustive — cite in inventory rows as needed)

- `examples/accrue_host/README.md` — Host golden path / VERIFY hops
- `examples/accrue_host/docs/adoption-proof-matrix.md` — Adoption proof matrix
- `scripts/ci/README.md` — Verifier map
- `scripts/ci/verify_package_docs.sh` — Package doc / `@version` SSOT
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README contract
- `scripts/ci/verify_adoption_proof_matrix.sh` — Matrix contract
- `accrue/guides/first_hour.md` — First-hour journey (integrator-facing)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`**, **`.planning/research/v1.10-METERING-SPIKE.md`** — Precedent for **`v1.*`** research filenames and long-lived planning artifacts outside **`phases/`**.
- **`scripts/ci/*`** — Objective **merge-blocking** and **advisory** checks to cite in **`ci_contract`** column.

### Established Patterns

- **GSD / planning** — **STATE** = cursor + pointers; **REQUIREMENTS** = checkbox contracts; **ROADMAP** = phase table; **`milestones/v*-*.md`** = archives post-ship.

### Integration Points

- Phase **63–65** plans should **link inventory row ids** in plan headers or tasks for traceability to **FRG-03**.

</code_context>

<specifics>
## Specific Ideas

- User asked for **all four** gray areas to be researched via **subagents** and synthesized into **one coherent** recommendation set emphasizing **DX**, **least surprise**, alignment with **billing library** trust + **Phoenix** integrator paths, and lessons from **Pay**, **Cashier**, **Stripe**, **Oban**, **K8s**, **Rust** tracking — captured in **D-01–D-05**.

</specifics>

<deferred>
## Deferred Ideas

- **Automated drift check** between ROADMAP pointer and inventory anchors — only if manual misses become painful (backlog / tooling phase).

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 62-friction-triage-north-star*  
*Context gathered: 2026-04-23*
