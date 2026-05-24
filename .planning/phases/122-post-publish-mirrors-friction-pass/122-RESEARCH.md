# Phase 122: Post-publish mirrors + friction pass - Research

**Researched:** 2026-05-08  
**Domain:** Planning-mirror closeout, post-publish maintainer truth, and friction-inventory certification for the linked `1.1.1` trio. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]  
**Confidence:** HIGH [VERIFIED: the governing facts for this phase are repo-local and already proven in canonical verification artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Planning mirror wording
- **D-01:** Use one shared public release-line sentence across active planning mirrors, but only when it explicitly names the package set and only when the statement is true on Hex/tags/workflow proof.
- **D-02:** The canonical wording model is: `Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).`
- **D-03:** Do not restate all three package versions throughout planning prose unless a partial/superseded release forces per-package exception handling. Package-level precision stays in package docs, tags, GitHub releases, Hex, and `121-VERIFICATION.md`.

### Milestone closeout posture
- **D-04:** Keep the milestone in an explicit short post-publish closeout state until Phase 122 lands, then flip `v1.38` to shipped/archive posture. Do not archive immediately after Phase 121.
- **D-05:** Distinguish two truths clearly in live planning docs:
  - public release truth: the `1.1.1` trio shipped on 2026-05-08
  - milestone truth: `v1.38` closeout remained active until mirrors and `INV-08` were recorded
- **D-06:** After Phase 122 is complete, live planning mirrors should no longer imply “ready to begin Phase 121,” “next unused phase is 120,” or any other pre-closeout active-state residue.

### Friction certification posture
- **D-07:** Default `INV-08` to dated certification path `(b)` unless the `1.1.0` failure and `1.1.1` recovery exposed a genuinely new sourced integrator/adoption problem that escaped the release-proof lane.
- **D-08:** Treat maintainer-process roughness as inventory-worthy only if at least one of these becomes true:
  - it left a new user-facing falsehood in docs/Hex/install guidance after recovery
  - it revealed a new non-diagnostic verifier gap that now weakens trust in the published contract
  - it recurs enough to support a real downstream trust story rather than a one-off recovery event
- **D-09:** For the current evidence set, the failed `1.1.0` portal publish and superseding `1.1.1` recovery stay in `121-VERIFICATION.md` and inform future release-gate hardening, but do not create a new friction row by default.

### Cleanup scope
- **D-10:** Use bounded strict cleanup: fix every stale live active-phase marker and contradictory current-public-version/package-scope callout that affects present-tense maintainer reading.
- **D-11:** Strict cleanup is bounded to active maintainer-facing artifacts, especially `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and any live phase directories or closeout pointers that still imply pre-`1.1.1` truth.
- **D-12:** Do not rewrite archived milestone artifacts, `_stale-phase-overflow`, or historical verification trees unless this phase uncovers a concrete archive-integrity bug. History should remain historically accurate even when the live mirrors change.

### Decision philosophy for this phase family
- **D-13:** Favor deep synthesis and cohesive defaults over repeated user arbitration for low-impact release-hygiene choices.
- **D-14:** Escalate only forks that materially change public release truth, milestone auditability, or long-term maintainer trust. Otherwise choose the least-surprising default and document it.

### Claude's Discretion
- Exact wording for active-vs-shipped posture in `PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, and `STATE.md`, as long as the distinction in **D-05** remains explicit.
- Exact `INV-08` dated subsection prose, provided it follows the existing inventory pattern and stays evidence-bound.
- Exact list of stale active-state cues to remove, provided cleanup remains inside the bounded strict scope from **D-10** through **D-12**.

### Deferred Ideas (OUT OF SCOPE)
- Converting the recovered `1.1.0` publish failure into a new friction row without stronger downstream evidence — defer unless future releases show recurrence or a real trust/adoption symptom.
- Broad cleanup of archived milestone trees or `_stale-phase-overflow` — out of scope unless an archive-integrity bug is discovered.
- Additional general-purpose GSD preference plumbing beyond the already-aligned discuss config — unnecessary for this phase unless a future workflow shows the current defaults are insufficient.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HYG-03 | `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` reflect the actual public release line and chosen linked package scope after publish, with no stale contradictions. [VERIFIED: `.planning/REQUIREMENTS.md`] | Summary, Architectural Responsibility Map, Standard Stack, Architecture Patterns, Common Pitfalls, Validation Architecture. |
| INV-08 | After the release and mirror pass, the maintainer performs the required dated post-publish friction certification or adds new sourced friction rows if the release exposed fresh integrator-facing problems. [VERIFIED: `.planning/REQUIREMENTS.md`] | Summary, Architecture Patterns, Don't Hand-Roll, Common Pitfalls, Code Examples, Validation Architecture. |
</phase_requirements>

## Summary

Phase 122 is a **maintainer-truth closeout** phase that consumes Phase 121’s already-proven public release evidence instead of re-proving the release itself. The canonical public truth is fixed in `121-VERIFICATION.md`: PR `#23`, target version `1.1.1`, workflow run `25554198977`, tags for all three packages, GitHub releases for all three packages, and Hex `latest_version` `1.1.1` for `accrue`, `accrue_admin`, and `accrue_portal`, all on 2026-05-08. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] Live `.planning/` files must now mirror that public truth while also stating the separate milestone truth that `v1.38` remained open briefly for closeout after publish. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/ROADMAP.md`]

The current live mirrors still contain contradictory active-state cues. `ROADMAP.md` says the “next unused planning phase is now 120,” `STATE.md` still says Phase 120 is complete and it is “ready to begin Phase 121 publish proof,” and `PROJECT.md` still opens with “No active milestone” even though it also contains a later `v1.38` section. Those are exactly the stale pre-closeout markers Phase 122 must remove. [VERIFIED: `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/PROJECT.md`; `rg -n "next unused planning phase is 120|ready to begin Phase 121|No active milestone" .planning`] The cleanup scope is therefore not a broad version sweep; it is a bounded rewrite of active maintainer-facing planning mirrors plus one dated `INV-08` subsection in the friction inventory. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]

Precedent is consistent across Phase 87, Phase 93, and Phase 121: publish proof lives in the release verification artifact, the inventory file is the single normative voice for dated `(b)` certification, and closeout phases update only active mirrors rather than archived milestone evidence. Phase 93 already separated “published release truth” from “milestone close truth” for `1.0.0`, and Phase 87 established the rule that path `(b)` is the default unless a real new sourced friction row clears the bar. Phase 121’s superseding `1.1.1` recovery now plays the same upstream-proof role that Phase 92 did for Phase 93. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-RESEARCH.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`]

**Primary recommendation:** Plan Phase 122 as one closeout slice with three bounded outputs: `(1)` align only live maintainer-facing `.planning/` mirrors to the canonical `1.1.1` trio sentence plus shipped/closeout posture, `(2)` append an `INV-08` dated path `(b)` subsection that points back to Phase 122 evidence while reusing Phase 121 as the public-proof source, `(3)` flip the milestone from active closeout to shipped/archive posture only after those mirror and inventory updates exist. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public release truth for `1.1.1` trio | Verification artifact | GitHub/Hex provenance | The source of truth is Phase 121’s proof bundle, not branch-local prose. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] |
| Live planning mirror wording | Static / repository docs | Verification artifact | `PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, and `STATE.md` must summarize Phase 121 evidence in maintainer-facing language. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] |
| Milestone closeout posture | Static / repository docs | State frontmatter | Active-vs-shipped status is carried by `ROADMAP.md`, `STATE.md`, `PROJECT.md`, and `MILESTONES.md`, not by public package docs. [VERIFIED: `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/PROJECT.md`; `.planning/MILESTONES.md`] |
| `INV-08` conclusion | Friction inventory SSOT | Phase-local verification | Phase 87 and Phase 93 both keep the normative maintainer conclusion in `v1.17-FRICTION-INVENTORY.md` and use verification files for evidence/methodology only. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`; `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`] |
| Historical failed `1.1.0` publish narrative | Archived/live verification artifact | Future release-hardening work | The failure/recovery history belongs in `121-VERIFICATION.md`, not as a new inventory row by default. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] |

## Project Constraints (from CLAUDE.md)

- Use GSD workflow entry points for file-changing work so planning artifacts stay in sync. [VERIFIED: `CLAUDE.md`]
- The monorepo release model is a coordinated sibling-package release; closeout wording must not contradict that linked release posture. [VERIFIED: `CLAUDE.md`; `RELEASING.md`]
- Security posture and observability claims are already part of the project contract; this phase is planning closeout only and should not edit runtime behavior or public security semantics. [VERIFIED: `CLAUDE.md`; `.planning/ROADMAP.md`]
- The release model is “ship complete,” and internal milestone labels do not replace public package versions. [VERIFIED: `CLAUDE.md`; `RELEASING.md`]
- No project-local skills were found under `.claude/skills/` or `.agents/skills/`. [VERIFIED: `CLAUDE.md`; project skills discovery scan]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Planning Markdown artifacts | n/a [VERIFIED: repo files] | Carry HYG-03 and milestone-close truth across live mirrors. [VERIFIED: `.planning/PROJECT.md`; `.planning/MILESTONES.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`] | These exact files are named in the requirement and context as the bounded cleanup surface. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`] |
| `v1.17-FRICTION-INVENTORY.md` | canonical SSOT [VERIFIED: file contents] | Carry the dated `INV-08` path `(b)` maintainer pass. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`] | Prior INV passes append dated subsections here instead of creating parallel SSOTs. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`] |
| Phase 121 verification ledger | `PR_NUMBER: 23`, `TARGET_VERSION: 1.1.1`, `RUN_ID: 25554198977` [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] | Upstream release-proof artifact for all public-truth claims in Phase 122. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] | This is already the canonical proof for tags, GitHub releases, Hex truth, and the recovered `1.1.1` line. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `git` | `2.39.5` [VERIFIED: `git --version`] | Inspect historical precedent and, if the execution phase later needs it, confirm the closeout tree before archival/tagging. [VERIFIED: local env] | Use for read-only checks in research and later for milestone-close verification, not for redefining release truth. [VERIFIED: Phase 93 precedent in `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`] |
| `rg` | `14.1.1` [VERIFIED: `rg --version`] | Find stale active-state markers and duplicate public-version callouts fast. [VERIFIED: local env] | Use to prove which live files still imply pre-closeout truth. [VERIFIED: `rg` scan of `.planning`] |
| Repo bash verifier suite | repo-local [VERIFIED: `scripts/ci/*.sh`; `.github/workflows/ci.yml`] | Re-run the inventory contract and any mirror-honesty scripts the execution plan touches. [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/verify_v1_17_friction_research_contract.sh`] | Use existing scripts; do not invent a new closeout-only checker. [VERIFIED: Phase 87 precedent] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing Phase 121 as sole public release proof [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] | Re-run tag/Hex/release checks again inside Phase 122 [ASSUMED] | Duplicates the proof ledger and weakens the clear split between publish truth and closeout truth. [VERIFIED: Phase 93 pattern in `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-RESEARCH.md`] |
| Path `(b)` dated `INV-08` certification [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] | Add a new friction row for the failed `1.1.0` / recovered `1.1.1` line [ASSUMED] | Current evidence shows maintainer-process roughness, but not a new persistent integrator-trust failure after recovery. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] |
| Bounded live-mirror cleanup only [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`] | Rewrite archived milestone trees and old verification docs [ASSUMED] | Would destroy historically accurate evidence and violates the locked scope fence. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`] |

**Installation:** None. This phase is repo-local planning closeout and depends only on existing markdown artifacts, shell verifiers, and standard CLI tools already present. [VERIFIED: `.planning/REQUIREMENTS.md`; local env]

**Version verification:** For the tools this phase actually uses:

```bash
git --version
rg --version | head -1
bash --version | head -1
```

## Architecture Patterns

### System Architecture Diagram

```text
Phase 121 public proof
  -> PR 23 / version 1.1.1 / run 25554198977
  -> trio tags + GitHub releases + Hex latest_version
  ->
Phase 122 closeout planner
  ->
  +--> live planning mirrors
  |      -> PROJECT.md
  |      -> MILESTONES.md
  |      -> ROADMAP.md
  |      -> STATE.md
  |      -> one shared public release-line sentence
  |      -> one explicit "milestone stayed open for closeout until INV-08 + mirror pass" sentence
  |
  +--> friction inventory
  |      -> append "v1.38 INV-08 maintainer pass (2026-05-08)"
  |      -> path (b), no new row by default
  |      -> evidence pointer back to Phase 122 verification
  |
  +--> verification artifact
         -> cites Phase 121 as upstream publish proof
         -> proves only fresh closeout work
         -> reruns inventory/mirror honesty checks
  ->
milestone posture flips to shipped/archive
```

### Recommended Project Structure

```text
.planning/
├── PROJECT.md                                         # long-form current state and active/shipped milestone narrative
├── MILESTONES.md                                      # shipped milestone ledger; add v1.38 close block here
├── ROADMAP.md                                         # active milestone block that must stop implying Phase 122 is pending after close
├── STATE.md                                           # frontmatter, current position, milestone progress, and next-step markers
├── REQUIREMENTS.md                                    # mechanical checkbox + traceability completion for HYG-03 / INV-08
├── research/
│   └── v1.17-FRICTION-INVENTORY.md                    # normative INV-08 dated subsection
└── phases/122-post-publish-mirrors-friction-pass/
    ├── 122-CONTEXT.md                                 # locked scope and wording model
    └── 122-RESEARCH.md                                # this file
```

### Pattern 1: Public Release Truth Comes From Phase 121, Not From Branch Prose

**What:** Treat `121-VERIFICATION.md` as the only canonical proof of the shipped trio line, and have closeout mirrors summarize it rather than restate detailed registry/tag/job tables. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

**When to use:** Any post-publish planning closeout where the public line is already proven in an earlier phase. [VERIFIED: Phase 93 precedent in `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-RESEARCH.md`]

**Example:**

```markdown
Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).

Public proof lives in `121-VERIFICATION.md`; this milestone remained active only long enough to align live planning mirrors and record INV-08.
```

### Pattern 2: One Sentence for Public Truth, One Sentence for Milestone Truth

**What:** Every live planning mirror should carry the same public release-line sentence and one brief qualifier that `v1.38` stayed open for post-publish closeout until this phase landed. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

**When to use:** Active `.planning/` mirrors that are meant for present-tense maintainer reading. [VERIFIED: `.planning/PROJECT.md`; `.planning/MILESTONES.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`]

**Example:**

```text
Public release truth: the linked accrue / accrue_admin / accrue_portal 1.1.1 line shipped on 2026-05-08.
Milestone truth: v1.38 remained open briefly after publish to align planning mirrors and record INV-08, then closed.
```

### Pattern 3: `INV-08` Path `(b)` Uses the Inventory File as the Only Normative Voice

**What:** Append a dated `### v1.38 INV-08 maintainer pass (2026-05-08)` subsection to `v1.17-FRICTION-INVENTORY.md`, state that no new sourced P1/P2 row was warranted, and point to the phase verification artifact for methodology. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`; Phase 87 and 93 precedents]

**When to use:** When release recovery exposed process roughness but not a durable new downstream trust/adoption failure. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`]

**Example:**

```markdown
### v1.38 INV-08 maintainer pass (2026-05-08)

**INV-08**: post-`1.1.1` maintainer pass `(b)` on this inventory. No new sourced P1/P2
rows were appended; the failed `1.1.0` portal publish and superseding `1.1.1` recovery
remain release-proof history in `121-VERIFICATION.md`, not a new inventory row.

**Evidence pointer:** `.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md`
```

### Pattern 4: Update Live Mirrors, Leave Historical Proof Alone

**What:** Edit current `.planning/` mirrors and the inventory SSOT, but do not rewrite archived milestone trees or the Phase 121 ledger unless an actual factual defect is found. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

**When to use:** Any closeout phase where the job is present-tense maintainer clarity rather than historical restatement. [VERIFIED: Phase 93 precedent]

**Example:**

```text
Editable in scope:
- .planning/PROJECT.md
- .planning/MILESTONES.md
- .planning/ROADMAP.md
- .planning/STATE.md
- .planning/REQUIREMENTS.md
- .planning/research/v1.17-FRICTION-INVENTORY.md

Read-only historical proof:
- .planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md
- archived milestone trees under .planning/milestones/
```

### Anti-Patterns to Avoid

- **Re-proving the release in Phase 122:** do not duplicate tag/Hex/GitHub release tables already captured in `121-VERIFICATION.md`. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`]
- **Leaving fuzzy “active but shipped” wording:** every mirror must distinguish public release truth from milestone-close truth explicitly. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]
- **Using multiple public-version phrasings across live mirrors:** Phase 122 locks one canonical sentence for the trio line. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]
- **Turning maintainer-process roughness into a friction row automatically:** the inventory bar is higher than “recovery was annoying.” [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; `.planning/research/v1.17-north-star.md`]
- **Editing archived milestone artifacts for cosmetic consistency:** history should stay accurate to the time it was written. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| A second public-proof ledger for `1.1.1` | New ad-hoc publish recap in every live mirror | Pointer to `121-VERIFICATION.md` | One proof artifact avoids drift between “release truth” copies. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] |
| A new friction-classification system for this one phase | Custom Phase 122 scoring rubric | Existing path `(a)` vs `(b)` inventory discipline from Phases 87 and 93 | The repo already has stable revisit triggers and evidence standards. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] |
| Repo-wide archive rewrites | Mass search/replace across historical milestone trees | Bounded live-mirror cleanup only | Closeout should improve present-tense maintainer truth without erasing historical sequence. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`] |
| A bespoke closeout verifier | New one-off script | Existing `verify_v1_17_friction_research_contract.sh` plus focused grep/state checks in the phase verification artifact | Prior closeout phases prove truth with existing verifiers and explicit artifact checks. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`] |

**Key insight:** The hard part of Phase 122 is not discovering new release truth; it is removing the last contradictions between already-shipped public truth and still-active milestone bookkeeping. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/PROJECT.md`]

## Common Pitfalls

### Pitfall 1: Confusing public release truth with milestone-close truth

**What goes wrong:** A mirror says either “the release is still pending” or “the milestone was already shipped” without explaining the short post-publish closeout window. [VERIFIED: current contradictions in `.planning/PROJECT.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`]

**Why it happens:** Publish proof and milestone closeout happen in separate phases, but the prose often collapses them into one event. [VERIFIED: Phase 93 precedent; `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

**How to avoid:** Put one explicit sentence for public release truth and one explicit sentence for milestone truth in every live mirror. [VERIFIED: locked decisions D-01 through D-06 in `122-CONTEXT.md`]

**Warning signs:** phrases like “ready to begin Phase 121,” “next unused planning phase is 120,” or “No active milestone” remain after closeout edits. [VERIFIED: `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/PROJECT.md`]

### Pitfall 2: Letting `INV-08` sprawl into a new friction row without evidence

**What goes wrong:** The phase converts the failed `1.1.0` / recovered `1.1.1` history into a new inventory row even though the public line is now honest and the failure already lives in the release-proof artifact. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

**Why it happens:** Recovery work feels “important,” and maintainers may overfit temporary process pain into the inventory. [ASSUMED]

**How to avoid:** Use the Phase 87 rule: path `(b)` is default unless there is a new sourced downstream trust/adoption problem that survives recovery. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`]

**Warning signs:** editing the ranked inventory table itself instead of appending only a dated subsection. [VERIFIED: `.planning/research/v1.17-FRICTION-INVENTORY.md`]

### Pitfall 3: Updating some mirrors but leaving one stale active-state cue behind

**What goes wrong:** `PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, and `STATE.md` tell mostly the same story, but one old sentence still implies pre-closeout status. [VERIFIED: current live drift]

**Why it happens:** The files play different roles, so maintainers patch the obvious one and miss the less-visible state marker or note bullet. [VERIFIED: current contradictions across live mirrors]

**How to avoid:** Treat `PROJECT.md`, `MILESTONES.md`, `ROADMAP.md`, `STATE.md`, and the phase verification artifact as one review set and grep for old active phrases before calling the phase complete. [VERIFIED: Phase 93 pattern; current `rg` scan]

**Warning signs:** `rg` still finds `next unused planning phase is 120`, `ready to begin Phase 121`, or pre-closeout wording after edits. [VERIFIED: current `rg` scan]

### Pitfall 4: Rewriting history instead of summarizing it

**What goes wrong:** Archived milestone artifacts or `121-VERIFICATION.md` get edited just to make them “match” the new live mirror wording. [VERIFIED: scope fence in `122-CONTEXT.md`]

**Why it happens:** Closeout work tempts maintainers to make everything read as if the end state was always known. [ASSUMED]

**How to avoid:** Leave historical files as proof of what happened; update only present-tense maintainer mirrors and the dated inventory pass. [VERIFIED: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`; Phase 93 precedent]

**Warning signs:** the diff expands into `.planning/milestones/` historical trees or Phase 121 proof tables with no factual correction. [VERIFIED: locked cleanup scope]

## Code Examples

Verified patterns from official repo sources:

### Canonical live-mirror release sentence

```text
Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 (published 2026-05-08).
```

Source: `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`. [VERIFIED: file contents]

### Lean `INV-08` path `(b)` subsection shape

```markdown
### v1.38 INV-08 maintainer pass (2026-05-08)

**INV-08** (`.planning/REQUIREMENTS.md`): post-`1.1.1` maintainer pass `(b)` on this
inventory. No new sourced P1/P2 friction rows were appended; the failed `1.1.0`
portal publish and superseding `1.1.1` recovery remain release-proof history in
`121-VERIFICATION.md`, not a new inventory row.

**Evidence pointer:** `.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md`

**Revisit trigger:**
- Next linked publish for `accrue` / `accrue_admin` / `accrue_portal`.
- A merge-blocking release or docs-contract failure that reveals a new downstream trust stall not covered by an existing row.
- A new `.planning/` public-release mismatch against actual registry truth for the shipped trio.
```

Source pattern: `.planning/research/v1.17-FRICTION-INVENTORY.md` dated maintainer passes for v1.28 and v1.30. [VERIFIED: file contents]

### Grep audit for stale closeout cues

```bash
rg -n "next unused planning phase is 120|ready to begin Phase 121|No active milestone|Current public linked release line" \
  .planning/PROJECT.md \
  .planning/MILESTONES.md \
  .planning/ROADMAP.md \
  .planning/STATE.md
```

Source: Phase 122 research synthesis from current repo state. [VERIFIED: current `rg` results]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pair-only linked release storytelling in some maintainer/public mirrors | Explicit three-package linked release contract and proof | Locked in Phase 120 and publicly proven in Phase 121 on 2026-05-08. [VERIFIED: `.planning/phases/120-release-contract-audit/120-VERIFICATION.md`; `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`] | Phase 122 must finish the live planning mirrors so all maintainer-facing surfaces tell the same trio story. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`] |
| Planning docs could lag behind public package truth after publish | Post-publish closeout phase explicitly repairs live planning mirrors and records a dated inventory pass | Established by Phases 87 and 93. [VERIFIED: `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`] | Maintainers now separate “public proof” from “milestone close” instead of treating them as the same artifact. [VERIFIED: precedent files] |
| Inventory closeout could duplicate release proof | Inventory pass points to the canonical release verification artifact and adds only fresh closeout evidence | Established by Phase 93. [VERIFIED: `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`; `.planning/research/v1.17-FRICTION-INVENTORY.md`] | Phase 122 should stay lean and evidence-bound. [VERIFIED: repo precedent] |

**Deprecated/outdated:**
- `ROADMAP.md` note `The next unused planning phase is now 120.` is outdated once Phase 122 closeout lands. [VERIFIED: `.planning/ROADMAP.md`]
- `STATE.md` text `ready to begin Phase 121 publish proof` is outdated after Phase 121 shipped and Phase 122 became the closeout slice. [VERIFIED: `.planning/STATE.md`]
- `PROJECT.md` opener `No active milestone` is outdated relative to the active `v1.38` section already present later in the file. [VERIFIED: `.planning/PROJECT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The failed `1.1.0` / recovered `1.1.1` sequence did not create a durable new integrator-trust issue beyond the release-proof lane. | Summary; Alternatives Considered; Common Pitfalls | If wrong, `INV-08` should add a new sourced friction row instead of path `(b)` only. |
| A2 | `git --version` returning `2.39.5` in this environment is sufficient for any later milestone-close inspection the execution phase may perform. | Standard Stack | Low; affects tool-version precision, not the closeout approach itself. |
| A3 | Process pain alone, without a surviving downstream falsehood or verifier blind spot, is insufficient for a new friction row. | Common Pitfalls | Medium; if the maintainer interprets the inventory bar differently, Phase 122 planning may need a branch for path `(a)`. |

## Open Questions (RESOLVED)

1. **Should `ROADMAP.md` be rewritten to a shipped/archive milestone block immediately, or should it retain a short “just closed” closeout summary?**
   - Resolution: Rewrite `ROADMAP.md` to shipped/archive truth once Phase 122 artifacts exist on disk, following the Phase 93 closeout model.
   - Basis: Locked decision D-04 requires an explicit post-publish closeout posture only until Phase 122 lands; after that, the milestone should flip to shipped/archive posture and lose all “next” or “remaining” cues. [VERIFIED: `122-CONTEXT.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`]

2. **Does `MILESTONES.md` need a completely new `v1.38` block or only a short inserted ledger entry?**
   - Resolution: Add a full shipped `v1.38` block, not a short inserted ledger entry.
   - Basis: `MILESTONES.md` already records shipped milestones as full blocks, and the closest analog for this closeout family is the v1.30 shipped-block pattern. Phase 122 should mirror that established structure with Phase 120–122 accomplishments, the `1.1.1` trio ship date, and explicit archive/proof pointers. [VERIFIED: `.planning/MILESTONES.md`; `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`]

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified). Phase 122 is a repo-local planning closeout and inventory-certification phase, not a runtime/service integration phase. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Repo bash contract scripts + explicit grep/state checks [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/*.sh`] |
| Config file | `.github/workflows/ci.yml` for merge-blocking job membership; no dedicated test config for planning closeout checks. [VERIFIED: `.github/workflows/ci.yml`] |
| Quick run command | `bash scripts/ci/verify_v1_17_friction_research_contract.sh` [VERIFIED: script exists] |
| Full suite command | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -n "Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 \\(published 2026-05-08\\)" .planning/PROJECT.md .planning/MILESTONES.md .planning/ROADMAP.md .planning/STATE.md && ! rg -n "next unused planning phase is 120|ready to begin Phase 121|No active milestone" .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md` [VERIFIED: repo state + locked wording model] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HYG-03 | Live planning mirrors repeat one truthful `1.1.1` trio line and remove stale active-state residue. | doc truth | `rg -n "Current public linked release line: accrue / accrue_admin / accrue_portal 1.1.1 \\(published 2026-05-08\\)" .planning/PROJECT.md .planning/MILESTONES.md .planning/ROADMAP.md .planning/STATE.md && ! rg -n "next unused planning phase is 120|ready to begin Phase 121|No active milestone" .planning/PROJECT.md .planning/ROADMAP.md .planning/STATE.md` | ✅ |
| INV-08 | Friction inventory contains a dated `v1.38 INV-08` path `(b)` subsection and preserves the existing ranked-row contract unless a new sourced row is intentionally added. | doc truth | `bash scripts/ci/verify_v1_17_friction_research_contract.sh && rg -n "^### v1\\.38 INV-08 maintainer pass \\(2026-05-08\\)$" .planning/research/v1.17-FRICTION-INVENTORY.md` | ✅ |

### Sampling Rate

- **Per task commit:** `bash scripts/ci/verify_v1_17_friction_research_contract.sh`
- **Per wave merge:** quick run plus the mirror grep audit above
- **Phase gate:** both requirement-mapped checks green before `122-VERIFICATION.md` is finalized

### Wave 0 Gaps

- None — existing shell verifier plus explicit grep/state assertions are sufficient for this doc-only closeout phase. [VERIFIED: `.github/workflows/ci.yml`; `scripts/ci/verify_v1_17_friction_research_contract.sh`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: Phase 122 is planning closeout only] | No auth-surface changes. [VERIFIED: `.planning/ROADMAP.md`] |
| V3 Session Management | no [VERIFIED: Phase 122 is planning closeout only] | No session/cookie changes. [VERIFIED: `.planning/ROADMAP.md`] |
| V4 Access Control | no [VERIFIED: Phase 122 is planning closeout only] | No ACL or authorization changes. [VERIFIED: `.planning/ROADMAP.md`] |
| V5 Input Validation | yes [VERIFIED: this phase writes canonical maintainer text and inventory structure] | Reuse existing verifier scripts and explicit grep checks so structure drift fails fast. [VERIFIED: `scripts/ci/verify_v1_17_friction_research_contract.sh`; `.github/workflows/ci.yml`] |
| V6 Cryptography | no [VERIFIED: no crypto/runtime changes in scope] | Not applicable; do not modify release-secret handling or webhook semantics. [VERIFIED: `CLAUDE.md`; `RELEASING.md`] |

### Known Threat Patterns for Planning Closeout

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale mirror contradicts shipped public line | Tampering | Source every live-mirror release claim from `121-VERIFICATION.md` and use one canonical sentence. [VERIFIED: `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md`; `122-CONTEXT.md`] |
| Historical proof rewritten to fit the final story | Repudiation | Keep release-proof artifacts and archived milestone trees immutable unless correcting a factual bug. [VERIFIED: `122-CONTEXT.md`] |
| Inventory row added without evidence | Tampering | Default to path `(b)` and require a sourced downstream trust story before changing the ranked table. [VERIFIED: `122-CONTEXT.md`; `.planning/research/v1.17-north-star.md`] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md` - locked decisions, canonical wording model, cleanup fence, and INV-08 posture.
- `.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md` - canonical public proof for PR `#23`, version `1.1.1`, workflow run `25554198977`, tags, GitHub releases, and Hex truth.
- `.planning/ROADMAP.md` - Phase 122 goal, success criteria, and current stale closeout cues.
- `.planning/REQUIREMENTS.md` - HYG-03 and INV-08 requirement wording and traceability.
- `.planning/STATE.md` - current active-state residue that Phase 122 must remove.
- `.planning/PROJECT.md` - current milestone narrative and contradictory “No active milestone” opener.
- `.planning/MILESTONES.md` - shipped milestone ledger through v1.37 and missing v1.38 shipped block.
- `.planning/research/v1.17-FRICTION-INVENTORY.md` - canonical inventory SSOT and dated maintainer-pass pattern.
- `.planning/research/v1.17-north-star.md` - stop rules and evidence bar for adding friction rows.
- `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md` - path `(b)` default and verifier-bundle discipline.
- `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-RESEARCH.md` and `093-VERIFICATION.md` - closeout pattern separating public proof from milestone-close truth.
- `.planning/phases/120-release-contract-audit/120-VERIFICATION.md` - three-package linked release contract precedent that Phase 121 later fulfilled publicly.
- `RELEASING.md` - current linked-release contract vocabulary distinguishing planning milestones from Hex SemVer.

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None; all substantive claims in this research are grounded in repo-local primary artifacts except items explicitly listed in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - this phase uses repo-local planning artifacts and existing shell verifiers only. [VERIFIED: repo files]
- Architecture: HIGH - the public-proof vs closeout-proof split is directly established by Phases 87, 93, 120, and 121. [VERIFIED: precedent artifacts]
- Pitfalls: HIGH - current stale cues are observable in live files, not inferred. [VERIFIED: current `rg` scan]

**Research date:** 2026-05-08  
**Valid until:** 2026-06-07 for repo-local closeout mechanics, unless Phase 122 scope or the live planning mirrors change first. [ASSUMED]
