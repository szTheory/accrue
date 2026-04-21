# Phase 30 — Research

**Phase:** 30 — Audit corpus closure  
**Gathered:** 2026-04-20

## RESEARCH COMPLETE

## Objective

Close `/gsd-audit-milestone` **3-source** gaps documented in `.planning/v1.6-MILESTONE-AUDIT.md`:

1. **COPY-01..03** appear in **no** phase `*-VERIFICATION.md` body today; Phase 27 work is real (summaries already carry `requirements-completed`) but verification corpus lacks REQ-ID rows → **orphan** status.
2. **26-*-SUMMARY.md** and **29-*-SUMMARY.md** omit `requirements-completed` in YAML frontmatter → partial traceability vs **28-* / 27-* / 25-*** pattern.

## Source of truth

| Artifact | Role |
|----------|------|
| `.planning/v1.6-MILESTONE-AUDIT.md` | Gap list, 3-source matrix (lines ~126–134) |
| `.planning/milestones/v1.6-REQUIREMENTS.md` | COPY-01..03 definitions; traceability table |
| `.planning/phases/27-microcopy-and-operator-strings/27-VERIFICATION.md` | Target file for new COPY coverage section |
| `.planning/phases/27-microcopy-and-operator-strings/27-0{1,2,3}-PLAN.md` | Plan-level `requirements:` for mapping text |
| `.planning/phases/26-hierarchy-and-pattern-alignment/26-0{1,2,3,4}-PLAN.md` | UX-01..04 per plan |
| `.planning/phases/29-mobile-parity-and-ci/29-0{1,2,3}-PLAN.md` | MOB-01..03 per plan |
| `.planning/phases/27-microcopy-and-operator-strings/27-01-SUMMARY.md` | Reference YAML: `requirements-completed:` after `patterns-established:` |

## Recommended edits (concrete)

### A. `27-VERIFICATION.md`

Insert a **Coverage (requirements)** section (same heading family as `28-VERIFICATION.md` § “Coverage (requirements)”) **after** the existing `## Automated` block and **before** `## Notes`, containing a markdown table with rows:

| ID | Evidence (must cite shipped paths) |
|----|-------------------------------------|
| **COPY-01** | `AccrueAdmin.Copy` empty-state functions + four money indexes + `data_table.ex` defaults; ExUnit on empty-table paths (`27-01` scope). |
| **COPY-02** | Flash / operator strings aligned in `27-02` / `27-03` touched flows per plan summaries (cite key LiveView / modal files from those summaries). |
| **COPY-03** | `accrue_admin/lib/accrue_admin/copy.ex` as SSOT; tests grep stable literals (`customers_live_test.exs` etc. per 27-01 summary). |

Do **not** change Phase 27 implementation code in Phase 30 — only planning corpus.

### B. Phase 26 summaries

Add to **YAML frontmatter** (mirror `27-01-SUMMARY.md`):

- `26-01-SUMMARY.md` → `requirements-completed: [UX-01]`
- `26-02-SUMMARY.md` → `requirements-completed: [UX-02]`
- `26-03-SUMMARY.md` → `requirements-completed: [UX-03]`
- `26-04-SUMMARY.md` → `requirements-completed: [UX-04]`

Place the key **inside** the opening `---` block, after existing keys (e.g. after `completed:`), preserving valid YAML list syntax.

### C. Phase 29 summaries

- `29-01-SUMMARY.md` → `requirements-completed: [MOB-01]` (matches `29-01-PLAN.md` `requirements:`)
- `29-02-SUMMARY.md` → `requirements-completed: [MOB-01, MOB-02, MOB-03]` (matches `29-02-PLAN.md`)
- `29-03-SUMMARY.md` → `requirements-completed: [MOB-02]` (matches `29-03-PLAN.md`)

### D. Requirements archive (optional follow-up)

`milestones/v1.6-REQUIREMENTS.md` still shows COPY checkboxes as `[ ]` — Phase **30** roadmap text ties COPY closure to verification corpus; toggling checkboxes may belong to **post-execute** audit re-run. Plans below **do not** require editing `v1.6-REQUIREMENTS.md` unless executor chooses to align checkboxes after grep proves VERIFICATION coverage (defer to Phase 31 if scope creep).

## Pitfalls

- **Duplicate `requirements-completed` keys** — invalid YAML; append once per file.
- **Wrong REQ-ID on wrong plan** — always cross-check the sibling `*-PLAN.md` frontmatter `requirements:` list.
- **27-VERIFICATION wording** — must include literal strings `COPY-01`, `COPY-02`, `COPY-03` so audit grep hits `27-VERIFICATION.md`.

## Validation Architecture

**Dimension 8 (Nyquist):** This phase is **documentation-only** (`.planning/**/*.md`). No application runtime or schema push.

| Concern | Strategy |
|---------|----------|
| Feedback signal | After each task: `rg` for expected REQ-ID / YAML key in touched files |
| Wave sampling | After all tasks in a plan: re-run full `rg` corpus checks in `<verification>` |
| Manual | None — all acceptance criteria are grep-based |
| Flake risk | None — no network, no test suite required for deliverables |

**Wave 0:** Not required — no new test files.

---

*Phase 30 — audit corpus closure*
