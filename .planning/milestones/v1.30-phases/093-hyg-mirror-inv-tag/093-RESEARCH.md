# Phase 93: Post-publish HYG mirror + INV-07 + tag - Research

**Researched:** 2026-04-28  
**Domain:** Planning closeout, post-publish planning mirrors, friction-inventory certification, and milestone tagging [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]  
**Confidence:** HIGH [VERIFIED: all required phase mechanics are defined in repo-local requirements, roadmap, prior verification artifacts, and current tool availability]

<user_constraints>
## User Constraints

### Locked Decisions

- This phase is **post-publish closeout only**. [VERIFIED: user request]
- Do **not** reopen release-surface work already satisfied in **Phase 92**. [VERIFIED: user request; `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-CONTEXT.md`]
- Focus on **planning-mirror citations**, the dated **INV-07** maintainer pass, the **verification transcript shape**, **milestone close markers in `STATE.md`**, and the planning git tag **`v1.30`**. [VERIFIED: user request]

### Claude's Discretion

- No phase-specific `093-CONTEXT.md` exists, so there are **no additional locked discuss-phase decisions** beyond the explicit scope above. [VERIFIED: `gsd-sdk query init.phase-op "93"` returned `"has_context": false`]

### Deferred Ideas (OUT OF SCOPE)

- Any public-facing docs, package pins, adoption-matrix needles, or release workflow proof already closed in **Phase 92**. [VERIFIED: user request; `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`]
- New billing/admin/product capability, and any reconsideration of **PROC-08** or **FIN-03**. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/STATE.md`; `.planning/PROJECT.md`]
- A repo-wide “version sweep” outside **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** under the HYG requirement. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYG-02 | `.planning/` mirror pass aligns `PROJECT.md`, `MILESTONES.md`, `STATE.md` to the published `1.0.0` pair after the linked publish lands. [VERIFIED: `.planning/REQUIREMENTS.md`] | Scope fence, target-file ownership, and mirror-update pattern are defined below. [VERIFIED: `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`; `.planning/ROADMAP.md`] |
| INV-07 | Post-1.0 dated maintainer pass `(b)` in `.planning/research/v1.17-FRICTION-INVENTORY.md` certifying the inventory remains accurate at `1.0.0`. [VERIFIED: `.planning/REQUIREMENTS.md`] | Path-(b) certification pattern, transcript lean-ness, and verifier expectations are defined below. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`; `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`] |
| REL-08 | Planning git tag `v1.30` after milestone close. [VERIFIED: `.planning/REQUIREMENTS.md`] | Tag timing, close-commit sequencing, and local tool availability are defined below. [VERIFIED: `.planning/ROADMAP.md`; `.planning/MILESTONES.md`; `git tag --list 'v1.*'`; `git --version`] |
</phase_requirements>

## Summary

Phase 93 is a **maintainer-truth closeout** phase, not another release-truth phase. Phase 92 already proved the linked `accrue` / `accrue_admin` `1.0.0` publish, the ordered workflow run, and the six-script docs bundle; Phase 93 should consume that proof as upstream evidence instead of re-running a second release-surface sweep. [VERIFIED: `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-CONTEXT.md`; `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`]

The implementation surface is narrow: update only **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** for HYG-02; append a new dated **`### v1.30 INV-07 maintainer pass (YYYY-MM-DD)`** subsection to **`.planning/research/v1.17-FRICTION-INVENTORY.md`** for INV-07; record a lean **`093-VERIFICATION.md`** that points to the already-proven Phase 92 bundle and reruns only the inventory contract that actually changed; then create planning tag **`v1.30`** on the milestone-closing commit. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`; `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`]

Two repo facts materially affect planning. First, **`MILESTONES.md` currently has no v1.30 section at all**, so HYG-02 is not just a wording touch-up there; it needs a new shipped/closed v1.30 milestone block. [VERIFIED: `rg -n "v1\\.30" .planning/MILESTONES.md` returned no match while `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` already contain v1.30 references] Second, the friction verifier still expects **exactly 5 inventory rows**, so INV-07 should stay on **path (b)** unless there is genuinely new sourced friction severe enough to justify changing the row-count contract and reopening related verifier expectations. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`; `.planning/research/v1.17-FRICTION-INVENTORY.md`; `.planning/ROADMAP.md`]

**Primary recommendation:** Plan Phase 93 as **three tightly scoped workstreams in one closeout slice**: `(1)` three-file planning mirror alignment, `(2)` INV-07 path-(b) certification plus lean verification transcript, `(3)` milestone-close state markers and `v1.30` tag creation only after the close commit exists. [VERIFIED: `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`; `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Planning mirror citations (`PROJECT.md`, `MILESTONES.md`, `STATE.md`) | Static / Repository docs [VERIFIED: `.planning/REQUIREMENTS.md`] | Git metadata [VERIFIED: `git tag --list 'v1.*'`] | HYG-02 is explicitly a planning-doc mirror requirement, but its truth source is the shipped `1.0.0` publish and milestone-close commit. [VERIFIED: `.planning/ROADMAP.md`; `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`] |
| INV-07 maintainer pass in `v1.17-FRICTION-INVENTORY.md` | Static / Repository docs [VERIFIED: `.planning/REQUIREMENTS.md`] | CI contract scripts [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/verify_v1_17_friction_research_contract.sh`] | The inventory file is the sole normative voice; the verifier script only checks that the inventory shape and pointers remain valid. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`; `scripts/ci/verify_v1_17_friction_research_contract.sh`] |
| Lean verification transcript (`093-VERIFICATION.md`) | Static / Repository docs [VERIFIED: `.planning/ROADMAP.md`] | CI contract scripts [VERIFIED: `.github/workflows/ci.yml`] | The proof artifact should cite prior Phase 92 evidence and only add fresh transcripts for the one contract this phase changes. [VERIFIED: `.planning/ROADMAP.md`; `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`] |
| Planning tag `v1.30` | Git metadata [VERIFIED: `.planning/REQUIREMENTS.md`; `git --version`] | Static / Repository docs [VERIFIED: `.planning/STATE.md`; `.planning/MILESTONES.md`] | REL-08 is satisfied by a tag on the milestone-closing commit, but the planning docs must already show the milestone as closed/shipped so the tag points at a truthful state. [VERIFIED: `.planning/ROADMAP.md`; `.planning/MILESTONES.md`; `.planning/STATE.md`] |

## Project Constraints (from CLAUDE.md)

- Use GSD workflow entry points for file-changing work so planning artifacts and execution context stay in sync. [VERIFIED: `CLAUDE.md`]
- Keep the repo’s locked release model intact: two sibling packages in one monorepo, first stable public release at `1.0.0`, coordinated linked release posture. [VERIFIED: `CLAUDE.md`; `.planning/PROJECT.md`] 
- Do not contradict the project’s explicit non-goals: **PROC-08** and **FIN-03** remain out of scope at `1.0.0`. [VERIFIED: `CLAUDE.md`; `.planning/PROJECT.md`; `.planning/REQUIREMENTS.md`] 
- Respect the existing security/observability posture; this phase should not change webhook, logging, or public runtime behavior because it is planning closeout only. [VERIFIED: `CLAUDE.md`; user request; `.planning/ROADMAP.md`] 
- No project-local skills were found under `.claude/` or `.agents/` for this repo. [VERIFIED: `find .claude -maxdepth 2 -type f`; `find .agents -maxdepth 2 -type f`]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `git` | `2.41.0` [VERIFIED: `git --version`] | Create and inspect planning tag `v1.30`; freeze reviewed SHAs in verification. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] | Prior shipped milestones use planning tags `v1.23`, `v1.24`, `v1.25`, `v1.26`, `v1.27`, `v1.29`, so git tagging is the established closeout mechanism. [VERIFIED: `git tag --list 'v1.*'`; `.planning/MILESTONES.md`; `.planning/PROJECT.md`] |
| Repo bash verifier suite | repo-local [VERIFIED: `scripts/ci/*.sh`; `.github/workflows/ci.yml`] | Validate that doc/planning contracts remain honest after the INV-07 edit. [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/verify_v1_17_friction_research_contract.sh`] | The CI job `docs-contracts-shift-left` already treats these scripts as normative; Phase 93 should reuse them rather than invent new proof logic. [VERIFIED: `.github/workflows/ci.yml`] |
| Planning Markdown artifacts | n/a [VERIFIED: `.planning/PROJECT.md`; `.planning/MILESTONES.md`; `.planning/STATE.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] | Carry HYG-02, INV-07, and the phase-local verification ledger. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] | These exact files are the locked Phase 93 edit surface. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rg` | `15.1.0` [VERIFIED: `rg --version`] | Fast, deterministic mirror audits across planning files. [VERIFIED: local command output] | Use for pre/post-edit greps that confirm `1.0.0`, `v1.30`, and phase-state markers landed only where intended. [VERIFIED: `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-02-PLAN.md`] |
| `gh` | `2.89.0` [VERIFIED: `gh --version`] | Optional cross-checks against the already-recorded release run URLs and PR metadata. [VERIFIED: local command output; `092-VERIFICATION.md`] | Use only if the planner wants to reconfirm Phase 92 links; do not make it a hard dependency for HYG-02 or INV-07. [VERIFIED: `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing `092-VERIFICATION.md` as upstream publish proof [VERIFIED: `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`] | Re-run the full Phase 92 release-surface bundle in Phase 93 [ASSUMED] | That would blur the boundary between Phase 92 and Phase 93 and reopen work the user explicitly fenced off. [VERIFIED: user request; `.planning/ROADMAP.md`] |
| Strict HYG scope: `PROJECT.md`, `MILESTONES.md`, `STATE.md` only [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`] | Repo-wide `1.0.0` grep sweep under HYG [ASSUMED] | Repo-wide sweeps create review noise and duplicate Phase 92/public-surface ownership. [VERIFIED: `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`; user request] |
| INV-07 path `(b)` dated certification with unchanged row counts [VERIFIED: `.planning/ROADMAP.md`; `scripts/ci/verify_v1_17_friction_research_contract.sh`] | Add a new inventory row during this pass [ASSUMED] | A new row would force a real friction finding and likely require verifier and matrix contract changes, which is a materially larger scope. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] |

**Installation:** None. `git`, `bash`, `rg`, `gh`, and `node` are already available in the current environment. [VERIFIED: `git --version`; `bash --version`; `rg --version`; `gh --version`; `node --version`]

**Version verification:** For this phase, verify tool availability with:

```bash
git --version
bash --version | head -1
rg --version | head -1
gh --version | head -1
node --version
```

## Architecture Patterns

### System Architecture Diagram

```text
Phase 92 publish proof (092-VERIFICATION.md)
        |
        v
Phase 93 closeout planner
        |
        +--> HYG lane: PROJECT.md / MILESTONES.md / STATE.md
        |         |
        |         v
        |   planning mirror now cites published 1.0.0 pair
        |
        +--> INV lane: v1.17-FRICTION-INVENTORY.md
        |         |
        |         v
        |   append "v1.30 INV-07 maintainer pass" subsection
        |         |
        |         v
        |   rerun verify_v1_17_friction_research_contract.sh
        |
        +--> Verification lane: 093-VERIFICATION.md
        |         |
        |         v
        |   cite unchanged Phase 92 bundle + fresh INV transcript
        |
        +--> Close lane: STATE close markers -> git tag v1.30
                  |
                  v
            milestone-closing commit tagged
```

### Recommended Project Structure

```text
.planning/
├── PROJECT.md                        # long-form current milestone + shipped history
├── MILESTONES.md                     # shipped milestone catalog; v1.30 block must be added here
├── STATE.md                          # current position, frontmatter progress, and close markers
├── REQUIREMENTS.md                   # HYG-02 / INV-07 / REL-08 checkbox + traceability updates
├── research/
│   └── v1.17-FRICTION-INVENTORY.md   # single normative INV-07 voice
└── milestones/v1.30-phases/093-hyg-mirror-inv-tag/
    ├── 093-RESEARCH.md               # this file
    └── 093-VERIFICATION.md           # lean proof artifact for Phase 93
```

### Pattern 1: Three-File Planning Mirror Fence

**What:** Treat HYG-02 as a **three-file mirror update only**: `PROJECT.md`, `MILESTONES.md`, and `STATE.md`. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`]

**When to use:** Whenever a requirement says “planning mirror” or “HYG” and explicitly names the planning files. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`]

**Example:**

```bash
# Source: .planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-02-PLAN.md
rg -n '1\.0\.0|v1\.30|shipped|Phase 93' \
  .planning/PROJECT.md \
  .planning/MILESTONES.md \
  .planning/STATE.md
```

### Pattern 2: Inventory Path-(b) With Single Normative Voice

**What:** Put the actual maintainer conclusion only in `v1.17-FRICTION-INVENTORY.md`, and use `093-VERIFICATION.md` for methodology, SHA pinning, and the fresh verifier transcript. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`; `.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md`]

**When to use:** When the phase goal is to certify “no new sourced friction rows were warranted” rather than to add a new row. [VERIFIED: `.planning/ROADMAP.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]

**Example:**

```markdown
<!-- Source: 087-VERIFICATION.md + v1.17-FRICTION-INVENTORY.md -->
### v1.30 INV-07 maintainer pass (2026-04-28)

**INV-07**: post-`1.0.0` maintainer pass on this inventory. No new sourced P1/P2
rows were appended; the reviewed baseline and existing reopen triggers remain accurate.

**Evidence pointer:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`
```

### Pattern 3: Close Commit First, Tag Second

**What:** Apply the planning mirror updates, inventory certification, and state close markers first; create tag `v1.30` only after that closing commit exists. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]

**When to use:** Whenever the requirement says the planning tag follows milestone close rather than the publish event. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`]

**Example:**

```bash
# Source: .planning/ROADMAP.md success criteria + existing git tags
git rev-parse HEAD
git tag v1.30
git rev-parse v1.30
```

### Anti-Patterns to Avoid

- **Replaying Phase 92:** Do not turn Phase 93 into another package-doc / adoption-matrix / release workflow sweep. That work is already closed in `092-VERIFICATION.md`. [VERIFIED: user request; `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`]
- **Repo-wide HYG expansion:** Do not treat HYG-02 as “grep every file for `1.0.0`.” The requirement names exactly three planning files. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`]
- **Second normative inventory voice:** Do not put the INV-07 conclusion only in `093-VERIFICATION.md`; the normative pass belongs in `v1.17-FRICTION-INVENTORY.md`. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]
- **Tagging too early:** Do not create `v1.30` before `STATE.md` and the other planning mirrors say the milestone is closed/shipped. [VERIFIED: `.planning/ROADMAP.md`; `.planning/STATE.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verifying inventory integrity | A new ad-hoc Phase 93 checker [ASSUMED] | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` [VERIFIED: script file; `.github/workflows/ci.yml`] | The existing verifier already checks inventory row counts, anchor pointers, and canonical file references. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`] |
| Re-proving publish truth | A fresh custom “Phase 93 publish ledger” [ASSUMED] | Reuse `092-VERIFICATION.md` as upstream release proof. [VERIFIED: `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md`] | Phase 92 already captured the run id, PR, ordered publish timestamps, and six-script bundle results. [VERIFIED: `092-VERIFICATION.md`] |
| Milestone status logic | Hand-maintained parallel truth across many planning files [ASSUMED] | Update the three HYG files plus the requirement traceability rows only. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`] | This repo’s established hygiene pattern is to keep planning truth narrow and link outward instead of duplicating prose. [VERIFIED: `69-CONTEXT.md`] |
| Inventory conclusion placement | A second prose copy in `093-VERIFICATION.md` that drifts from the inventory file [ASSUMED] | Keep the maintainer conclusion in `v1.17-FRICTION-INVENTORY.md` and let `093-VERIFICATION.md` be evidence-only. [VERIFIED: `085-VERIFICATION.md`; `087-VERIFICATION.md`] | Prior INV phases explicitly treat the inventory file as the single normative voice. [VERIFIED: `085-VERIFICATION.md`; `087-VERIFICATION.md`] |

**Key insight:** The cheapest truthful plan is to **reuse the existing release proof and only add the proof that Phase 93 itself changes**. [VERIFIED: user request; `092-VERIFICATION.md`; `087-VERIFICATION.md`]

## Common Pitfalls

### Pitfall 1: Treating HYG-02 as a general release cleanup

**What goes wrong:** The phase sprawls into README, guide, or verifier edits that belong to Phase 92. [VERIFIED: `.planning/REQUIREMENTS.md`; user request]

**Why it happens:** “Mirror pass” sounds broader than it is unless the three-file fence is enforced. [VERIFIED: `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md`]

**How to avoid:** Plan HYG-02 as only `PROJECT.md`, `MILESTONES.md`, and `STATE.md`, with any extra `ROADMAP` or `REQUIREMENTS` touch kept purely mechanical for phase-complete bookkeeping. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] 

**Warning signs:** The change list starts including package docs, `scripts/ci/verify_package_docs.sh`, or `examples/accrue_host/*`. [VERIFIED: `092-CONTEXT.md`; `.planning/ROADMAP.md`] 

### Pitfall 2: Breaking the friction verifier by adding or reshaping rows

**What goes wrong:** `verify_v1_17_friction_research_contract.sh` fails because inventory row counts or anchors moved. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`]

**Why it happens:** The script still requires exactly **5** rows and fixed FRG anchors. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`]

**How to avoid:** Keep INV-07 on path `(b)` unless you have evidence strong enough to justify a new sourced row and its downstream contract updates. [VERIFIED: `.planning/ROADMAP.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]

**Warning signs:** You are editing the FRG table itself, not just appending a dated maintainer-pass subsection. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`; `087-VERIFICATION.md`] 

### Pitfall 3: Creating a weak or redundant verification artifact

**What goes wrong:** `093-VERIFICATION.md` either repeats all of Phase 92 or lacks a fresh transcript for the inventory contract that changed. [VERIFIED: `.planning/ROADMAP.md`; `092-VERIFICATION.md`; `087-VERIFICATION.md`]

**Why it happens:** The phase mixes “proof reuse” and “fresh proof” without separating them. [VERIFIED: `.planning/ROADMAP.md`; `087-VERIFICATION.md`]

**How to avoid:** Copy the lean Phase 87 shape: cite the unchanged bundle membership and upstream evidence, then include only the fresh `verify_v1_17_friction_research_contract.sh` transcript plus reviewed SHA/tag pointers. [VERIFIED: `087-VERIFICATION.md`; `.github/workflows/ci.yml`]

**Warning signs:** The verification doc starts replaying `verify_package_docs.sh`, `verify_adoption_proof_matrix.sh`, or `accrue_host_uat.sh` stdout without Phase 93-specific reason. [VERIFIED: `087-VERIFICATION.md`; `092-VERIFICATION.md`] 

### Pitfall 4: Tagging the wrong commit

**What goes wrong:** `v1.30` points at a commit before the milestone-close markers or before the INV-07 subsection exists. [ASSUMED]

**Why it happens:** The tag is created during the phase instead of after the closing commit is finalized. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]

**How to avoid:** Make the tag the final closeout action and record the target commit SHA in `093-VERIFICATION.md`. [VERIFIED: `.planning/ROADMAP.md`; git tag discipline in `.planning/MILESTONES.md`] 

**Warning signs:** `git rev-parse v1.30` and the reviewed SHA in `093-VERIFICATION.md` do not match. [ASSUMED]

## Code Examples

Verified patterns from repo-local sources:

### HYG-02 mirror audit

```bash
# Source: .planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-02-PLAN.md
V=$(sed -n 's/^  @version "\([^"]*\)"/\1/p' accrue/mix.exs | head -1)
rg -F "$V" .planning/PROJECT.md
rg -F "$V" .planning/MILESTONES.md
rg -F "$V" .planning/STATE.md
```

### INV-07 final contract check

```bash
# Source: scripts/ci/verify_v1_17_friction_research_contract.sh
bash scripts/ci/verify_v1_17_friction_research_contract.sh
```

### REL-08 tag proof

```bash
# Source: .planning/ROADMAP.md success criterion 4 + existing git tag discipline
git tag --list 'v1.30'
git rev-parse v1.30
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HYG-01 at `0.3.1`: planning mirror only needed version-consistency callouts after publish. [VERIFIED: `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-VERIFICATION.md`] | HYG-02 at `1.0.0`: still the same three-file mirror fence, but now it also needs milestone-close posture and a new shipped v1.30 entry in `MILESTONES.md`. [VERIFIED: `.planning/ROADMAP.md`; `.planning/MILESTONES.md`; `.planning/STATE.md`] | v1.30 planning opened 2026-04-26; Phase 92 publish proof completed 2026-04-28. [VERIFIED: `.planning/PROJECT.md`; `.planning/STATE.md`] | Phase 93 is more of a milestone-close operation than the earlier v1.19 mirror pass. [VERIFIED: `.planning/ROADMAP.md`] |
| INV-05 used full local transcript replay for several scripts. [VERIFIED: `.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md`] | INV-06 established the leaner pattern: cite unchanged bundle membership, rerun only the inventory contract changed by the phase. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`] | 2026-04-24 in Phase 87. [VERIFIED: `087-VERIFICATION.md`] | Phase 93 should follow the lean Phase 87 shape unless it introduces a real shift-left delta. [VERIFIED: `.planning/ROADMAP.md`; `087-VERIFICATION.md`] |
| Pre-1.0 closure narrative in v1.27. [VERIFIED: `.planning/MILESTONES.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] | Post-1.0 stability posture after the linked `1.0.0` pair in v1.30. [VERIFIED: `.planning/PROJECT.md`; `.planning/STATE.md`; `092-VERIFICATION.md`] | 2026-04-28 publish proof completion. [VERIFIED: `092-VERIFICATION.md`] | INV-07 should certify the inventory against a stable `1.0.0` surface, not a future-bootstrap narrative. [VERIFIED: `.planning/ROADMAP.md`; `.planning/PROJECT.md`] |

**Deprecated/outdated:**

- Treating **v1.28** as the tag model for this phase is outdated; `STATE.md` explicitly says v1.28 was **not separately tagged**, while REL-08 says Phase 93 should mirror **v1.27 / v1.29** tag discipline. [VERIFIED: `.planning/STATE.md`; `.planning/REQUIREMENTS.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | REL-08 is satisfied by creating `v1.30` on the milestone-closing commit and proving it in `093-VERIFICATION.md`; remote push may follow operationally, but it is not part of the requirement-bearing phase contract. [RESOLVED] | Open Questions / REL-08 execution | Low — the roadmap and requirements require tag existence after milestone close, not a separate transport step. |
| A2 | Any archival follow-up (`/gsd-complete-milestone` style moves or archive file generation) is outside the requirement-bearing Phase 93 slice and can happen mechanically after the close commit. [RESOLVED] | Open Questions | Low — Phase 93 only locks HYG-02, INV-07, REL-08, close markers, and `093-VERIFICATION.md`. |

## Open Questions (RESOLVED)

1. **Does REL-08 require a remote-pushed tag or only a local planning tag?**
   - What we know: the requirement says “planning git tag `v1.30` exists after milestone close,” and prior milestones record tags in planning docs. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/MILESTONES.md`; `.planning/PROJECT.md`]
   - Resolved: Phase 93 will treat REL-08 as satisfied when `git tag v1.30` exists on the milestone-closing commit and `093-VERIFICATION.md` records `git tag --list 'v1.30'` plus `git rev-parse v1.30`. A remote push is an operational follow-up, not a separate requirement gate. [RESOLVED]

2. **Is milestone archival expected inside the Phase 93 implementation slice or immediately after it?**
   - What we know: the roadmap only locks HYG-02, INV-07, REL-08, plus `STATE.md` close markers and a `093-VERIFICATION.md` artifact. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]
   - Resolved: keep the requirement-bearing plan scoped to Phase 93 closeout only. Any `/gsd-complete-milestone` archival or later archive generation happens after the close commit and does not add new Phase 93 deliverables. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` | REL-08 tag creation and SHA proof | ✓ [VERIFIED: `git --version`] | `2.41.0` [VERIFIED: `git --version`] | None — blocking if missing. [VERIFIED: phase requires a git tag] |
| `bash` | Existing verifier scripts and local proof commands | ✓ [VERIFIED: `bash --version`] | `5.2.37` [VERIFIED: `bash --version`] | None — blocking if missing because the repo’s contract scripts are bash. [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/*.sh`] |
| `rg` | Fast planning mirror audits during implementation | ✓ [VERIFIED: `rg --version`] | `15.1.0` [VERIFIED: `rg --version`] | `grep` is viable but slower. [ASSUMED] |
| `gh` | Optional re-check of Phase 92 run/PR metadata | ✓ [VERIFIED: `gh --version`] | `2.89.0` [VERIFIED: `gh --version`] | Skip and rely on `092-VERIFICATION.md` if not needed. [VERIFIED: `092-VERIFICATION.md`] |

**Missing dependencies with no fallback:**

- None. [VERIFIED: local command outputs above]

**Missing dependencies with fallback:**

- None in the current environment. [VERIFIED: local command outputs above]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Repo bash contract scripts + manual git/grep closeout checks [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/*.sh`] |
| Config file | `.github/workflows/ci.yml` [VERIFIED: file exists and defines `docs-contracts-shift-left`] |
| Quick run command | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`] |
| Full suite command | Reuse Phase 92’s `092-VERIFICATION.md` for the unchanged six-script publish proof; for fresh Phase 93 proof, rerun `bash scripts/ci/verify_v1_17_friction_research_contract.sh` and verify `git rev-parse v1.30`. [VERIFIED: `092-VERIFICATION.md`; `.planning/ROADMAP.md`] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HYG-02 | Planning mirrors cite the published `1.0.0` pair and closed milestone posture. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`] | manual + grep [VERIFIED: `69-02-PLAN.md`] | `rg -n '1\.0\.0|v1\.30|shipped|Phase 93' .planning/PROJECT.md .planning/MILESTONES.md .planning/STATE.md` [ASSUMED command shape from prior plan] | ✅ [VERIFIED: files exist] |
| INV-07 | Inventory gets a dated path-(b) maintainer pass and keeps the friction contract green. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] | shell contract [VERIFIED: `.github/workflows/ci.yml`] | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` [VERIFIED: script file] | ✅ [VERIFIED: script exists] |
| REL-08 | `v1.30` tag points at the close commit. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] | git metadata check [VERIFIED: phase requirement text] | `git tag --list 'v1.30' && git rev-parse v1.30` [ASSUMED command shape] | ✅ [VERIFIED: git available; tag not yet present] |

### Sampling Rate

- **Per task commit:** `bash scripts/ci/verify_v1_17_friction_research_contract.sh` after any inventory edit. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`]
- **Per wave merge:** Re-run the same inventory script and grep the three HYG files for `1.0.0` / `v1.30` truthfulness. [VERIFIED: `69-02-PLAN.md`; `.planning/ROADMAP.md`]
- **Phase gate:** `093-VERIFICATION.md` must include the reviewed SHA, the INV transcript, the HYG review bullets, and the final `v1.30` tag proof. [VERIFIED: `.planning/ROADMAP.md`; `085-VERIFICATION.md`; `087-VERIFICATION.md`]

### Wave 0 Gaps

- None — Phase 93 can reuse the existing bash verifier and prior verification patterns. [VERIFIED: `.github/workflows/ci.yml`; `085-VERIFICATION.md`; `087-VERIFICATION.md`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 93 is planning closeout only] | No auth surface changes. [VERIFIED: user request; `.planning/ROADMAP.md`] |
| V3 Session Management | no [VERIFIED: Phase 93 is planning closeout only] | No session or cookie surface changes. [VERIFIED: user request; `.planning/ROADMAP.md`] |
| V4 Access Control | no [VERIFIED: Phase 93 is planning closeout only] | No runtime access-control changes. [VERIFIED: user request; `.planning/ROADMAP.md`] |
| V5 Input Validation | yes [VERIFIED: existing shell verifiers validate file shape and anchors] | Reuse `verify_v1_17_friction_research_contract.sh` and fixed-string grep checks; do not loosen the contract. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`; `69-02-PLAN.md`] |
| V6 Cryptography | no [VERIFIED: no secret or crypto handling changes are in scope] | No crypto surface is touched in this phase. [VERIFIED: user request; `.planning/ROADMAP.md`] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Planning docs drift from the actual published `1.0.0` pair | Tampering | Update only the three HYG files against the already-proved Phase 92 release ledger. [VERIFIED: `.planning/REQUIREMENTS.md`; `092-VERIFICATION.md`] |
| Inventory subsection implies a stronger conclusion than the proof actually supports | Repudiation | Keep `v1.17-FRICTION-INVENTORY.md` as the single normative voice and record fresh transcripts in `093-VERIFICATION.md`. [VERIFIED: `085-VERIFICATION.md`; `087-VERIFICATION.md`] |
| Tag points at a non-closing commit | Tampering / Repudiation | Record `git rev-parse v1.30` in `093-VERIFICATION.md` and create the tag only after the close commit exists. [VERIFIED: `.planning/ROADMAP.md`] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md` - project constraints, workflow discipline, and locked repo posture. [VERIFIED: file contents]
- `.planning/REQUIREMENTS.md` - HYG-02, INV-07, REL-08 requirements and traceability. [VERIFIED: file contents]
- `.planning/ROADMAP.md` - Phase 93 scope, success criteria, and definition-of-done artifact. [VERIFIED: file contents]
- `.planning/STATE.md` - current milestone posture, next-step markers, and v1.30 closeout expectations. [VERIFIED: file contents]
- `.planning/PROJECT.md` - current milestone narrative and non-goal reaffirmation. [VERIFIED: file contents]
- `.planning/MILESTONES.md` - shipped milestone/tag precedent and absence of a current v1.30 block. [VERIFIED: file contents; `rg -n "v1\\.30" .planning/MILESTONES.md`]
- `.planning/research/v1.17-FRICTION-INVENTORY.md` - existing INV-03..06 pattern and reopen triggers. [VERIFIED: file contents]
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-CONTEXT.md` - explicit Phase 93 boundary handoff. [VERIFIED: file contents]
- `.planning/milestones/v1.30-phases/092-linked-1-0-0-publish-post-publish-contract-sweep/092-VERIFICATION.md` - canonical `1.0.0` publish proof to reuse. [VERIFIED: file contents]
- `.planning/milestones/v1.19-phases/69-doc-planning-mirrors/69-CONTEXT.md` and `69-VERIFICATION.md` - HYG scope fence and prior planning-mirror proof shape. [VERIFIED: file contents]
- `.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md` and `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md` - INV path-(b) verification precedents. [VERIFIED: file contents]
- `.github/workflows/ci.yml` - normative `docs-contracts-shift-left` membership. [VERIFIED: file contents]
- `scripts/ci/verify_v1_17_friction_research_contract.sh` - inventory shape contract. [VERIFIED: script contents]
- Local commands: `git --version`, `git tag --list 'v1.*'`, `git status --short`, `rg --version`, `gh --version`, `node --version`. [VERIFIED: command outputs]

### Secondary (MEDIUM confidence)

- None. [VERIFIED: all material claims were grounded in repo-local artifacts or local command outputs]

### Tertiary (LOW confidence)

- None. [VERIFIED: no web-search-only claims were required]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - the phase depends on local tools and repo scripts whose presence and versions were verified directly. [VERIFIED: local command outputs; `.github/workflows/ci.yml`]
- Architecture: HIGH - the scope fence, proof reuse pattern, and tag timing are spelled out in the roadmap, requirements, and prior phase artifacts. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `069/085/087/092` artifacts]
- Pitfalls: HIGH - the likely failures are directly exposed by existing repo contracts (`verify_v1_17_*`, HYG scope precedent, missing v1.30 milestone block, and tag sequencing). [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`; `.planning/MILESTONES.md`; `.planning/ROADMAP.md`]

**Research date:** 2026-04-28  
**Valid until:** 2026-05-28 for repo-local planning mechanics, unless the live Phase 93 scope or closeout tooling changes first. [ASSUMED]
