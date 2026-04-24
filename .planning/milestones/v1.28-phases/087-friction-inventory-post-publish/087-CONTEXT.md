# Phase 87: Friction inventory post-publish - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Satisfy **INV-06** after **PPX-05..08** (Phase **86**) land: maintainer pass **(b)** or **(a)** on **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with a **dated subsection** and falsifiable **`087-VERIFICATION.md`** verifier evidence in the **INV-03 / INV-04 / INV-05** family — scoped so **87** owns **INV-06** narrative substance only; **86** never duplicates that body (**086-CONTEXT** **D-05**).

**Out of scope:** **PROC-08**, **FIN-03**, new billing/admin product features, **PPX** substance (Phase **86**).

**Tooling:** `gsd-sdk query init.phase-op "87"` may return `phase_found: false` when phase dirs use **`087-`** tokens vs two-digit phase queries — **`.planning/ROADMAP.md`** and this tree remain authoritative.

</domain>

<decisions>
## Implementation Decisions

### Inventory subsection heading (normative `###` in friction SSOT)

- **D-01:** Canonical heading template: **`### v1.<MILESTONE> INV-06 maintainer pass (<YYYY-MM-DD>)`** — for v1.28 milestone use **`### v1.28 INV-06 maintainer pass (YYYY-MM-DD)`**. **`<MILESTONE>`** is the **planning milestone** slug from **ROADMAP** / **PROJECT** (here **v1.28**), **not** the **`v1.17-`** research filename prefix.
- **D-02:** **Do not** put **Hex SemVer** (`0.x.y`) in the `###` line — SemVer, **`@version`**, and **reviewed SHA** live in the subsection body and **`087-VERIFICATION.md`** (avoids heading churn on patch re-verifies; matches **INV-03..INV-05** grep ergonomics: `rg 'INV-06 maintainer pass'`, `rg '### v1.28 INV-06'`).
- **D-03:** Put thematic prose (**post-publish**, **after PPX**, **billing portal / First Hour** class drift) in the **first paragraph under** the heading, not in the heading — stable pointers from **VERIFICATION** / **PPX-08** row updates.

### `087-VERIFICATION.md` depth (maintainer burden vs audit defensibility)

- **D-04 (default spine):** **085 / INV-05-style** skeleton — Preconditions, **one** reviewed **`main`** merge **SHA**, verifier bundle aligned to **D-08**, normative attestation **pointer** to the inventory subsection as single voice, optional **Sign-off** checklist. Prefer **GitHub Actions run URL + job ids** proving green-at-SHA when transcripts would duplicate Phase **86** (**086-CONTEXT** **D-03** / **D-04**).
- **D-05 (conditional transcript annex):** Add **stdout / log transcript blocks** (or pasted CI excerpts) **only when** merge-blocking **`docs-contracts-shift-left`** contract surface **changed** at or before the **87** reviewed SHA **and** that delta is **not** already captured in **`086-VERIFICATION.md`** transcript annex (or **86** documented an automation exception gap **87** is closing). Otherwise **omit** duplicate shift-left replay — **reference** **86** for PPX machine contract.
- **D-06:** Never **delta-only** local verifier runs — if citing green, align with **086-CONTEXT** **D-06** / **D-07**: full **job** intent or explicit CI replay; **INV-06** does not narrow the shift-left family by hand.

### Verifier bundle enumeration (frozen list vs CI truth)

- **D-07 (footgun addressed):** A **static** list copied from an older **INV** phase can **drift** from **`.github/workflows/ci.yml`** (e.g. **`verify_core_admin_invoice_verify_ids.sh`** added after **085** was written). **Do not** treat **085’s prose list** as eternal law.
- **D-08 (normative rule — hybrid, SHA-pinned):** The **INV-06** maintainer bundle is **exactly** the **`bash scripts/ci/*.sh` steps** declared under merge-blocking job **`docs-contracts-shift-left`** in **`.github/workflows/ci.yml` as at the reviewed commit SHA**, plus merge-blocking **`host-integration`** green at that SHA (cited via transcripts, local runs, or **Actions** link). **`087-VERIFICATION.md`** includes an **enumerated snapshot** of those commands (what was actually run / what CI ran) — falsifiable transcript, not vague “same family.”
- **D-09 (publish-adjacent extension):** When the **Phase 86** / PPX work touched **Release Please manifest** or **`verify_release_manifest_alignment.sh`** semantics, also cite merge-blocking **`release-manifest-ssot`** green at the same reviewed SHA (separate CI job today — see **`ci.yml`** header contract). If **86** already proved it, **87** may **pointer-only** per **D-05**.

### Revisit triggers (subsection tail — signal vs noise)

- **D-10:** Carry **083** **D-11** family verbatim as backbone: next **linked Hex publish**; **adoption proof matrix** / Layer **C** rename without same-PR **`verify_adoption_proof_matrix.sh`** co-update; merge-blocking **`host-integration`** / **`docs-contracts-shift-left`** failure documenting a new integrator stall; **INT-13-class** facade / First Hour / matrix needle drift on **`main`** without a sourced row update.
- **D-11 (single v1.28 high-signal add):** Add **one** bullet — **PPX-08-class planning vs registry mismatch**: **`.planning/`** public-Hex / last-published callouts disagree with **actual** registry versions for shipped **`accrue` / `accrue_admin`** — re-open **INV-06** evidence and fix mirrors per **`.planning/REQUIREMENTS.md` PPX-08** (same change-set discipline as Phase **86** / **87**), **even without** a new publish. **Do not** enumerate **PROJECT.md** / **MILESTONES.md** / **STATE.md** paths in the bullet (avoid copy-paste drift); **requirement id + outcome** only.
- **D-12:** Do **not** duplicate the full **PPX** checklist inside the inventory subsection — triggers are **routing rules**, not essay **PROC-08** scope.

### Path **(a)** vs **(b)** and row-count contract (carried forward)

- **D-13:** Default **path (b)** — dated certification that no new sourced **P1**/**P2** rows were warranted unless **FRG-01** bar cleared (**083** **D-01**, **FRG-02** **S1** / **S5**). **Path (a)** only with stable ids + **`verify_v1_17_friction_research_contract.sh`** co-update in **same PR** (**079** **D-02**, **083** **D-04**).
- **D-14:** Chronological placement: append **`### v1.28 INV-06 maintainer pass (...)`** **after** the latest existing maintainer subsection (currently **v1.27 INV-05** block), mirroring **083** **D-05**.

### Ecosystem and vision alignment (why these defaults)

- **D-15:** **Rails / Laravel / Stripe SDK** culture: merge-blocking **CI** is the integrator-visible contract; planning attestations stay **SHA-grounded** and **non-duplicative**. Accrue adds **falsifiable** bash gates for doc honesty — **enumerated snapshot @ SHA** matches that culture better than a stale frozen list.
- **D-16:** **Cohesion with PROJECT.md** — *billing state, modeled clearly* + **one reality at one commit**: inventory subsection = **attestation voice**; **087-VERIFICATION** = **methodology + evidence**; **no** competing PPX narrative in **87**.

### Claude's Discretion

- Exact prose in **D-11** bullet wording (keep **PPX-08** pointer, ≤2 sentences).
- Whether **087-VERIFICATION** uses one combined transcript block vs per-script subsections — keep **grep-friendly** and reviewer-scannable.

### Folded Todos

- None — `todo.match-phase` for phase **87** returned no matches.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **INV-06**, **PPX-08** (registry mirror discipline)
- `.planning/ROADMAP.md` — Phase **87** row, **v1.28** milestone
- `.planning/PROJECT.md` — Milestone narrative; integrator trust / spine **B**

### Friction SSOT and prior INV phases

- `.planning/research/v1.17-FRICTION-INVENTORY.md` — Evidence SSOT; append **INV-06** subsection after **v1.27 INV-05**
- `.planning/research/v1.17-north-star.md` — **S1**, **S5** stop rules

### Phase precedents (do not re-litigate)

- `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-CONTEXT.md` — **PPX** vs **INV-06** split (**D-05**), shift-left breadth (**D-06**–**D-07**), transcript annex triggers (**D-03**–**D-04**)
- `.planning/milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md` — **INV-05** bundle + transcript layout reference
- `.planning/milestones/v1.26-phases/083-friction-inventory-post-touch/083-CONTEXT.md` — **INV-04** split placement, revisit triggers (**D-11**)
- `.planning/milestones/v1.25-phases/079-friction-inventory-maintainer-pass/079-CONTEXT.md` — **INV-03** baseline

### Normative CI contract (membership drifts here first)

- `.github/workflows/ci.yml` — Merge-blocking job ids **`docs-contracts-shift-left`**, **`host-integration`**, and when publish touches manifest: **`release-manifest-ssot`** (see file header comment)
- `scripts/ci/README.md` — Same-PR co-update triage

### Verifier scripts (membership @ SHA — verify against `ci.yml` at reviewed commit)

- `scripts/ci/verify_package_docs.sh`
- `scripts/ci/verify_v1_17_friction_research_contract.sh`
- `scripts/ci/verify_verify01_readme_contract.sh`
- `scripts/ci/verify_production_readiness_discoverability.sh`
- `scripts/ci/verify_adoption_proof_matrix.sh`
- `scripts/ci/verify_core_admin_invoice_verify_ids.sh`
- `scripts/ci/verify_release_manifest_alignment.sh` — **when** cited per **D-09** (separate job **`release-manifest-ssot`**)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`v1.17-FRICTION-INVENTORY.md`** dated maintainer subsections (**v1.25 INV-03**, **v1.26 INV-04**, **v1.27 INV-05**) — extend with **v1.28 INV-06**.
- **`085-VERIFICATION.md` / `083-VERIFICATION.md`** — Evidence checklist + transcript patterns.
- **`086-VERIFICATION.md`** — PPX evidence to **reference** from **87** when machine contract unchanged.

### Established patterns

- **Single reviewed merge SHA** per pass — not a window (**079** / **083**).
- **Bash gates** for planning/doc contracts; **ExUnit** for runtime — do not move INV honesty into BEAM tests.

### Integration points

- **`.planning/REQUIREMENTS.md`** traceability row **INV-06** ↔ Phase **87**.
- **`PPX-08`** row updates in inventory may **pointer** to **086** / **087** without duplicating **INV-06** body in **86**.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (2026-04-24): headings stay **milestone + INV + date** only; **Pay / Cashier / Stripe**-style “green CI is law” favors **SHA-pinned `ci.yml` membership** over frozen prose lists; **Kubernetes / Rust RFC** culture favors **CI artifact links** over duplicate transcripts unless the **machine contract** moved.

</specifics>

<deferred>
## Deferred Ideas

- **PROC-08** / **FIN-03** — explicit future milestone only (**PROJECT.md** non-goals).
- Automating extraction of shift-left step list from **`ci.yml`** via script — nice-to-have; not required for **87** closure.

</deferred>

---

*Phase: 87-friction-inventory-post-publish*  
*Context gathered: 2026-04-24*
