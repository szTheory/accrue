# Phase 66: Deferred UAT + evaluator proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`66-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 66 — Deferred UAT + evaluator proof  
**Areas discussed:** Artifact directory + path SSOT; UAT automation vs sign-off; `62-UAT.md` vs `REQUIREMENTS.md`; `66-VERIFICATION.md` shape; PROOF-01 depth  
**Method:** User selected **all** areas; five parallel **generalPurpose** subagents (research synthesis), parent merged into one coherent policy.

---

## 1. Phase artifact directory + `66-VERIFICATION.md` location

| Approach | Description | Selected |
|----------|-------------|----------|
| A | ROADMAP path `66-onboarding-confidence/` only | ✓ (canonical) |
| B | GSD default slug dir only | |
| C | Dual dirs / symlinks | ✗ (explicit reject) |
| D | Rewrite ROADMAP to match slug | Only if tooling cannot follow ROADMAP; prefer A |

**User's choice:** Accept merged recommendation — **single canonical tree `66-onboarding-confidence/`**, no symlinks/dual dirs; public SSOT stays guides/README/changelog.  
**Notes:** Subagent synthesis cited Phoenix/Oban/changelog norms—internal planning must not fork disk truth.

---

## 2. UAT evidence bar (automation vs maintainer sign-off)

| Stance | Description | Selected |
|--------|-------------|----------|
| Signed-first | Rows + links + maintainer closure | ✓ default |
| Thin automation | `verify_*` / optional ExUnit for binary invariants | ✓ when D-02b triggers |
| Heavy prose automation | Golden snapshots of planning markdown | ✗ |

**User's choice:** Merged recommendation — **human closure default**; **bash script SSOT** + optional ExUnit mirror per existing Accrue pattern; automate only stable/binary or post-regression invariants.  
**Notes:** Compared Pay/Cashier (manual docs), Stripe (heavy doc investment), K8s sig-release (few binary gates).

---

## 3. `62-UAT.md` baseline vs v1.18 wording

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite 62-UAT body | Align test 4 to UAT-04 | ✗ |
| Banner + errata | Immutable body + top banner + REQUIREMENTS SSOT | ✓ |
| Separate mapping file | Optional; banner + verification row sufficient | backup |

**User's choice:** **REQUIREMENTS.md normative**; **`62-UAT.md` historical**; **dated banner** + optional echo in **66-VERIFICATION**.  
**Notes:** ADR/changelog immutability analogy; avoids “what did Phase 62 actually certify?” confusion.

---

## 4. `66-VERIFICATION.md` shape

| Shape | Description | Selected |
|-------|-------------|----------|
| Minimal table | Frontmatter + scope + matrix (v1.17 style) | ✓ |
| Verbose multi-section | Full audit narrative | ✗ unless unmappable row |

**User's choice:** **Minimal matrix** with columns: Row ID, Acceptance one-liner, Merge-blocking proof, Automation, Evidence pointer, Closure; optional spot-checks section.  
**Notes:** Rust/CNCF/GitLab pattern = automation first, markdown as index.

---

## 5. PROOF-01 depth

| Depth | Description | Selected |
|-------|-------------|----------|
| Light | Scripts green + citation | Partial |
| Bounded + semantic | CI + one sitting matrix/walkthrough/README + paired taxonomy commits | ✓ |
| Exhaustive | Every row traced to every test | ✗ |

**User's choice:** **Matrix SSOT**, script as harness; **one semantic read**; **definition of done** per **CONTEXT D-05c**; OpenAPI-style “coordinated rename” lesson applied.

---

## Claude's Discretion

- Banner copy nuance; whether to add a **new** thin verifier for specific UAT rows; optional taxonomy map bullets (**66-CONTEXT.md** records these).

## Deferred Ideas

- **PROC-08** / **FIN-03** — future milestone only.  
- Standing full doc audit beyond **PROOF-01** — deferred.
