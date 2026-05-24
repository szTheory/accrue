# Phase 122: Post-publish mirrors + friction pass - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 10
**Analogs found:** 4 strong precedents

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/122-post-publish-mirrors-friction-pass/122-01-PLAN.md` | plan | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md` | exact |
| `.planning/phases/122-post-publish-mirrors-friction-pass/122-02-PLAN.md` | plan | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md` | exact |
| `.planning/phases/122-post-publish-mirrors-friction-pass/122-03-PLAN.md` | plan | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md` | exact |
| `.planning/phases/122-post-publish-mirrors-friction-pass/122-VERIFICATION.md` | verification | request-response | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md` | role-match |
| `.planning/MILESTONES.md` | config | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md` | role-match |
| `.planning/ROADMAP.md` | config | transform | `.planning/phases/121-linked-publish-proof-sweep/121-03-PLAN.md` | partial |
| `.planning/STATE.md` | config | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md` | exact |
| `.planning/research/v1.17-FRICTION-INVENTORY.md` | research | transform | `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md` | exact |

## Pattern Assignments

### `122-01-PLAN.md` - mirror cleanup plan

**Primary analog:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md`

**Frontmatter pattern** ([093-01-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md:1)):
- Keep the standard execution-plan header: `phase`, `plan`, `type: execute`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, then `must_haves.truths/artifacts/key_links`.
- For Phase 122, copy the same narrow file fence style and make `files_modified` only live `.planning/` mirrors.

**Scope fence pattern** ([093-01-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md:67)):
- Use one task to align the maintainer mirrors and one task to normalize `STATE.md`.
- Keep the action text explicit about what not to touch. 093 says "Do not touch any public docs... or non-`.planning/` surfaces" at lines 79-80; Phase 122 should reuse that bounded cleanup posture and extend it with 122 context D-10..D-12.

**Nearer content analog for wording drift cleanup:** `.planning/phases/121-linked-publish-proof-sweep/121-03-PLAN.md`
- Copy the "use recorded release proof as the truth source" pattern from [121-03-PLAN.md:96](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-03-PLAN.md:96).
- Replace package-doc targets with planning-mirror targets: `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`.
- Keep verification grep-exact like [121-03-PLAN.md:100](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-03-PLAN.md:100): prove stale phrases are gone and the new exact release-line sentence is present.

**File targeting to carry forward**
- Live targets come directly from [122-CONTEXT.md](/Users/jon/projects/accrue/.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md:34): `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`.
- Explicit stale cues already visible now:
  - `.planning/ROADMAP.md` note `The next unused planning phase is now 120` at [ROADMAP.md:69](/Users/jon/projects/accrue/.planning/ROADMAP.md:69)
  - `.planning/STATE.md` pre-closeout posture at [STATE.md:24](/Users/jon/projects/accrue/.planning/STATE.md:24) and [STATE.md:29](/Users/jon/projects/accrue/.planning/STATE.md:29)
  - `.planning/PROJECT.md` active milestone framing at [PROJECT.md:267](/Users/jon/projects/accrue/.planning/PROJECT.md:267)

### `122-02-PLAN.md` - inventory certification plan

**Primary analog:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md`

**Split to copy** ([093-02-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md:65)):
- Task 1 appends the dated maintainer-pass subsection to `v1.17-FRICTION-INVENTORY.md`.
- Task 2 creates the verification ledger and keeps it lean.

**Inventory subsection pattern** ([093-02-PLAN.md:76](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md:76), [v1.17-FRICTION-INVENTORY.md:91](/Users/jon/projects/accrue/.planning/research/v1.17-FRICTION-INVENTORY.md:91)):
- Reuse the exact heading shape: `### v1.38 INV-08 maintainer pass (2026-05-08)`.
- Stay on path `(b)` by default, matching [122-CONTEXT.md:29](/Users/jon/projects/accrue/.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md:29).
- Copy the structure from the existing INV-07 subsection:
  - first paragraph states no new sourced P1/P2 rows unless evidence forces it
  - one evidence pointer line to the phase verification artifact
  - short revisit triggers list

**Verification-ledger pattern**
- Start from the lean verification-ledger instruction in [093-02-PLAN.md:99](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md:99).
- Reuse publish proof rather than replaying it. For Phase 122 the upstream proof source is [121-VERIFICATION.md](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md:69), not fresh Hex/workflow reruns.
- Carry forward the 087 rule from [087-CONTEXT.md](/Users/jon/projects/accrue/.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-CONTEXT.md:44): enumerate only the fresh contract transcript needed for the inventory file; do not duplicate the full release-proof bundle if 121 already captured it.

### `122-03-PLAN.md` - closure/state/requirements plan

**Primary analog:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md`

**Dependency pattern** ([093-03-PLAN.md:5](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:5)):
- Make this wave 2.
- Depend on both mirror cleanup and inventory certification plans.

**Closure sequencing pattern** ([093-03-PLAN.md:68](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:68)):
- Do not mark requirements complete until the mirror edits and inventory artifact already exist.
- Keep the verification file evidence-only.
- Flip active-closeout posture to shipped/archived posture in one tracked-state pass.

**Important adaptation**
- Copy the 093 closeout task shape, but drop the git-tag-only Task 2 unless Phase 122 gains a REL requirement. Phase 122 currently maps only `HYG-03` and `INV-08` in [REQUIREMENTS.md:58](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md:58).
- Still copy the state-transition mechanics from 093:
  - `.planning/STATE.md` frontmatter/status/progress update pattern from [093-03-PLAN.md:80](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:80)
  - `.planning/REQUIREMENTS.md` checklist + traceability closeout pattern from [093-03-PLAN.md:92](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:92)

### `122-VERIFICATION.md` - final closeout ledger

**Primary analog:** `.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md`

**Report shape to copy** ([093-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md:1)):
- YAML frontmatter with `phase`, `verified`, `status`, `score`, `gaps`.
- Body sections in this order work well and should be reused:
  - phase goal / verified / status
  - `## Goal Achievement`
  - `### Observable Truths`
  - `### Required Artifacts`
  - `### Key Link Verification`
  - `### Behavioral Spot-Checks`
  - `### Requirements Coverage`
  - `### Gaps Summary`

**What to swap in from Phase 121**
- Use [121-VERIFICATION.md:73](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md:73) through [121-VERIFICATION.md:174](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md:174) as the canonical release-proof source.
- Add a "publish proof reused from Phase 121" truth exactly the way 093 reused Phase 92 at [093-VERIFICATION.md:32](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md:32).
- Record only fresh Phase 122 checks: planning-mirror review, inventory contract transcript, requirements closeout, and stale-state removal.

## Shared Patterns

### 1. Split the phase into three concerns, not one blended cleanup
**Source:** [093-01-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-01-PLAN.md:41), [093-02-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-02-PLAN.md:38), [093-03-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:43)
- Plan 01: live mirror cleanup
- Plan 02: inventory certification + lean verification ledger
- Plan 03: milestone/state/requirements closure

### 2. Treat release proof and closeout proof as separate artifacts
**Source:** [121-VERIFICATION.md](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-VERIFICATION.md:69), [093-VERIFICATION.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-VERIFICATION.md:54)
- Phase 121 proves tags, GitHub releases, Hex truth, and post-publish verifier reruns.
- Phase 122 should cite that proof, not recreate it.

### 3. Frontmatter conventions stay literal and grep-friendly
**Source:** [120-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/120-release-contract-audit/120-01-PLAN.md:1), [121-01-PLAN.md](/Users/jon/projects/accrue/.planning/phases/121-linked-publish-proof-sweep/121-01-PLAN.md:1), [093-03-PLAN.md](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:1)
- Keep `requirements` explicit in frontmatter.
- Use `must_haves.truths`, `artifacts`, and `key_links` with concrete filenames and patterns.
- Acceptance criteria should usually be fixed-string `rg` or one shell verifier, not prose-only review.

### 4. Requirement mapping is mechanical once evidence exists
**Source:** [093-03-PLAN.md:80](/Users/jon/projects/accrue/.planning/milestones/v1.30-phases/093-hyg-mirror-inv-tag/093-03-PLAN.md:80)
- Close checklist rows and traceability rows in the same task that creates final tracked state.
- For Phase 122 this applies to `HYG-03` and `INV-08` only.

### 5. File targeting should stay bounded to live `.planning/` artifacts
**Source:** [122-CONTEXT.md:34](/Users/jon/projects/accrue/.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md:34)
- In scope: `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, `.planning/research/v1.17-FRICTION-INVENTORY.md`, and new Phase 122 artifacts.
- Out of scope by default: archived milestone trees and `_stale-phase-overflow`, per [122-CONTEXT.md:36](/Users/jon/projects/accrue/.planning/phases/122-post-publish-mirrors-friction-pass/122-CONTEXT.md:36).

## Recommended Phase 122 Plan Shape

1. `122-01-PLAN.md`
   Mirror cleanup only. Update `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` to one exact release-line sentence and remove pre-closeout residue.
2. `122-02-PLAN.md`
   Append `### v1.38 INV-08 maintainer pass (2026-05-08)` and create `122-VERIFICATION.md` as a lean closeout ledger that reuses `121-VERIFICATION.md`.
3. `122-03-PLAN.md`
   Finalize shipped/archive posture, close `HYG-03` and `INV-08` in `.planning/REQUIREMENTS.md`, and clean any remaining active-state cues. Reuse 093-03 sequencing, but omit a git-tag task unless scope changes.

## Metadata

**Analog search scope:** `.planning/phases/120-*`, `.planning/phases/121-*`, `.planning/milestones/v1.30-phases/093-*`, `.planning/milestones/v1.28-phases/087-*`, live `.planning/*.md`, `v1.17-FRICTION-INVENTORY.md`

**Key patterns identified:**
- Closeout phases are split by concern, not by file type.
- Verification ledgers reuse upstream publish proof and add only fresh closeout evidence.
- `.planning/` cleanup is bounded to live maintainer mirrors and requirements state.
