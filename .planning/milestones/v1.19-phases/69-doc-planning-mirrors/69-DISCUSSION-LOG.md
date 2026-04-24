# Phase 69: Doc + planning mirrors — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`69-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 69 — Doc + planning mirrors  
**Areas discussed:** HYG vs DOC scope; Planning file tone/structure; Bash + ExUnit verifier coupling; First Hour / capsule pins vs prose  
**Mode:** User selected **all** areas and requested parallel **subagent research** + one-shot cohesive recommendations (no interactive Q/A per area).

---

## 1. HYG vs integrator-facing doc scope

| Option | Description | Selected |
|--------|-------------|----------|
| A — Strict HYG | Only `.planning/PROJECT.md`, `MILESTONES.md`, `STATE.md` for HYG-01 | ✓ |
| B — Unbounded sweep | Also opportunistically version-sweep unrelated docs under “HYG” | |
| C — Merge HYG into DOC | Drop boundary between planning and README work | |

**Research synthesis (subagent):** Minimal HYG reduces maintainer churn; adopters care about copy-paste surfaces — those belong under **DOC-01/02** and **`verify_package_docs`** allowlist, not ambiguous “HYG = whole repo.” Mature Hex libs keep version SSOT in **`mix.exs`** + enforced README/guide lines.

**User's choice:** **A + explicit DOC lane** — **HYG-01** = three planning files only (**REQUIREMENTS**); **DOC-01/02** = verifier-enforced integrator paths (**D-01** in CONTEXT).

**Notes:** Coherent with **68-CONTEXT** (DOC/HYG explicitly Phase **69**).

---

## 2. Minimal facts vs narrative parity in `.planning/`

| Option | Description | Selected |
|--------|-------------|----------|
| A — Minimal + SSOT roles | PROJECT = narrative; STATE = pointers; MILESTONES = milestone retros; patch updates are factual | ✓ |
| B — Narrative parity | MILESTONES/STATE match PROJECT verbosity on every publish | |

**Research synthesis (subagent):** Triplicated milestone prose maximizes drift (version, date, phase counts). Stripe/Laravel pattern: long-form in **one** intentional surface; elsewhere **links**.

**User's choice:** **A** — locked as **D-02** in CONTEXT.

---

## 3. `verify_package_docs.sh` ↔ ExUnit coupling

| Option | Description | Selected |
|--------|-------------|----------|
| A — Bash authoritative, minimal ExUnit | Script defines truth; tests assert exit codes, failure shape, key scenarios; bash first on change | ✓ |
| B — Mirror every needle in ExUnit | High duplication | |
| C — Big-bang refactor | Shared manifest / codegen — defer | |

**Research synthesis (subagent):** “Green ExUnit, wrong reality” footgun when stdout assertions drift; idiomatic pattern is **`System.cmd`** + behavioral assertions; table-driven dedup is optional later.

**User's choice:** **A** — locked as **D-03** in CONTEXT.

---

## 4. Capsule pins vs prose / voice

| Option | Description | Selected |
|--------|-------------|----------|
| A — Pins mandatory; prose only when semantics change | CI-enforced lines every release; voice stable | ✓ |
| B — Full capsule rewrite each release | Higher drift and review noise | |

**Research synthesis (subagent):** Least surprise for copy-paste is **correct `~>`**; Cashier/Pay teach **install lines as contracts**; pre-1 policy = **one canonical** short block + links.

**User's choice:** **A** — locked as **D-04** in CONTEXT.

---

## Claude's discretion

- Wording of minimal **STATE** / **MILESTONES** lines where CONTEXT grants flexibility.

## Deferred ideas

- Machine-readable needle manifest (**D-03** optional future).
- Repo-wide version prose outside **DOC/HYG** requirements — new phase / requirement.
