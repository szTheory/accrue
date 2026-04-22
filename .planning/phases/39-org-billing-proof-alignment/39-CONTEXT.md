# Phase 39: Org billing proof alignment - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

**ORG-09:** Evaluators and CI can see **at least one non-Sigra org billing archetype** in the adoption proof story **without diluting what VERIFY-01 means**.

In scope: `examples/accrue_host/docs/adoption-proof-matrix.md` and/or VERIFY-01-adjacent prose; **owning verifier(s)** named in `scripts/ci/README.md` (v1.7 table discipline); **merge-blocking vs advisory** labels **consistent** with the existing matrix (Fake + browser = blocking; live Stripe = advisory).

Out of scope: new billing product features; replacing Sigra in the example host; proving every auth vendor in Playwright; redefining VERIFY-01 as “all org recipes.”

</domain>

<decisions>
## Implementation Decisions

### 1. Archetype(s) for the matrix (`research synthesis`)

- **D-01 (primary archetype row):** Name the **canonical non-Sigra org billing** archetype as the **phx.gen.auth + membership-gated `Organization` billable** mainline (**ORG-05 / ORG-06**), matching `accrue/guides/organization_billing.md` — not Pow and not “custom org” as the **only** row.
- **D-02 (honesty / least surprise):** The matrix row **must** state clearly that **non-Sigra** refers to **identity and active-org resolution per the guide** (`Accrue.Auth`, `Accrue.Billable`, host facade). The **example host may still use Sigra** as a **demo implementation detail** for tenancy; the row must **not** imply “this repository’s default host stack is Sigra-free” unless a future phase actually delivers that slice.
- **D-03 (secondary rows — advisory default):** **Pow (ORG-07)** and **custom org / ORG-08** may appear as **additional matrix rows** framed as **recipe / contract** lanes defaulting to **advisory** (guide anchors + evaluator narrative) until a dedicated executable slice exists — avoids expanding merge-blocking CI to “every auth integration.”
- **D-04 (combo shape):** Satisfy **≥1** ORG-09 row with **D-01** as the **named** archetype; optional **D-03** rows improve breadth without merging them into one vague “custom” label.

### 2. Proof strength — executable vs prose (`research synthesis`)

- **D-05 (VERIFY-01 stays narrow):** **VERIFY-01** remains the **bounded Fake-backed host + Playwright + README runnable contract** (`mix verify.full` / `host-integration`). Do **not** add parallel browser lanes per auth archetype.
- **D-06 (merge-blocking ORG-09 signal):** Prefer a **hybrid**: (1) **thin merge-blocking machine check** on the **matrix doc** (new bash verifier — see D-10); (2) **extend** `accrue/test/accrue/docs/organization_billing_guide_test.exs` with **minimal ORG-09 needles** (cross-links / section anchors between matrix and spine) so **doc truth** stays **ExUnit-fast** in the **accrue** package CI slice — idiomatic for a **library whose product includes integration recipes** (same pattern as Phase 37–38).
- **D-07 (avoid prose-only blocking):** A row labeled **merge-blocking** must have a **named verifier** that **fails CI** when content drifts — not copy-only “blocking” with no gate.
- **D-08 (when to add heavier executable proof):** New host ExUnit or Playwright **only** for a **named gap** (e.g. a regression no unit boundary catches). Default **no** new VERIFY-01 Playwright for Pow/custom in Phase 39.

### 3. Where enforcement lives (`research synthesis`)

- **D-09 (SSOT):** **`adoption-proof-matrix.md`** owns **human-facing** ORG-09 semantics (archetype, lanes, blocking vs advisory).
- **D-10 (primary new gate):** Add **`scripts/ci/verify_adoption_proof_matrix.sh`** (name fixed here for planning) as the **primary machine owner** for ORG-09 **matrix invariants** (required row markers, archetype string, blocking/advisory vocabulary consistency with existing sections — exact needles in plan). Keeps **`verify_verify01_readme_contract.sh`** from becoming a second matrix linter.
- **D-11 (VERIFY-01 script):** **`verify_verify01_readme_contract.sh`** stays **narrow**: existing README + spec-file + `sk_live` rules; **at most one** additional pin if needed (e.g. stable pointer substring from README to matrix subsection) — **not** full archetype taxonomy in bash awk.
- **D-12 (optional harness):** Optional **thin ExUnit** that **invokes** the matrix bash script (mirror `phase_31_nyquist_validation_test.exs` → `verify_verify01` pattern) **only if** we want release-gate to catch “script deleted but workflow still green”; otherwise **one** primary CI surface is enough to avoid triple maintenance.
- **D-13 (CI job placement):** Run the matrix verifier in the **same family** as existing host proof (`host-integration` / root UAT path used today for `verify_verify01_readme_contract.sh`) so failures **triage** like ADOPT-02.

### 4. `scripts/ci/README.md` ownership (`research synthesis`)

- **D-14 (section placement):** Add a **new** subsection **`## ORG gates (v1.8 org billing proof)`** — do **not** fold ORG-09 into **`## ADOPT gates (v1.7 adoption milestone)`** (milestone + REQ-ID namespace stay clear).
- **D-15 (single ORG-09 row):** One table row for **`ORG-09`** with the same **four columns** as ADOPT: REQ-ID | Primary script(s) or artifact | Package ExUnit (if any) | Phase VERIFICATION owner.
- **D-16 (primary column content):** List **`scripts/ci/verify_adoption_proof_matrix.sh`** as the **primary** artifact; include **`verify_verify01_readme_contract.sh`** in the **same cell** only if Phase 39 adds a **minimal README pin**; include **`organization_billing_guide_test.exs`** path when D-06 extends it — mirror **ADOPT-01** density (multiple paths, one row).
- **D-17 (VERIFICATION owner path):** `.planning/phases/39-org-billing-proof-alignment/39-VERIFICATION.md` (create/update during execute).
- **D-18 (triage DX):** Add **`### Triage: verify_adoption_proof_matrix.sh`** (or under a shared ORG bullet list) listing **stderr prefix** and **which substrings / rows** map to ORG-09 — parallel to existing `verify_package_docs` triage.

### Cross-cutting engineering principles (locked)

- **D-19:** **Stripe-like entity clarity** + **Pay/Cashier-style honesty**: separate **library contract proof** (VERIFY-01, org billing ExUnit) from **tenancy recipe proof** (guide + matrix + doc tests) so consumers never assume the demo host is the only valid org topology.
- **D-20:** **Ecosystem idioms:** Prefer **fast ExUnit doc contracts** in `accrue` over **extra Playwright** for recipe coverage; reserve **expensive** proof for **VERIFY-01** semantics.

### Claude's Discretion

- Exact **grep needles** / table row wording in `adoption-proof-matrix.md`.
- Whether **D-12** optional ExUnit harness ships in Phase 39 or is deferred if a single bash gate suffices.
- Exact **README** one-liner vs matrix-only navigation (as long as VERIFY-01 does not absorb full matrix semantics).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — ORG-09 acceptance text; traceability table.
- `.planning/ROADMAP.md` — Phase 39 goal and success criteria (v1.8).

### Prior phase context

- `.planning/phases/37-org-billing-recipes-doc-spine-phx-gen-auth/37-CONTEXT.md` — doc spine, example host hybrid proof layering.
- `.planning/phases/38-org-billing-recipes-pow-custom-org-boundaries/38-CONTEXT.md` — ORG-07/ORG-08 placement; ORG-09 explicitly Phase 39.

### Proof artifacts (edit / extend targets)

- `examples/accrue_host/docs/adoption-proof-matrix.md` — matrix SSOT, blocking vs advisory sections.
- `examples/accrue_host/README.md` — VERIFY-01 narrative; already links matrix.
- `scripts/ci/verify_verify01_readme_contract.sh` — README contract gate.
- `scripts/ci/README.md` — contributor verifier map (add ORG subsection).
- `accrue/guides/organization_billing.md` — non-Sigra org mainline + ORG-07/ORG-08 sections.
- `accrue/test/accrue/docs/organization_billing_guide_test.exs` — merge-friendly guide needles.

### CI workflow

- `.github/workflows/ci.yml` — `host-integration` and related jobs (where verify scripts run).

### ORG-03 anchor

- `.planning/milestones/v1.3-REQUIREMENTS.md` — ORG-03 full wording (context for matrix language).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`verify_verify01_readme_contract.sh`** — pattern for substring + file-existence + awk-window checks; keep ORG-09 logic **out** of this file except minimal cross-links.
- **`organization_billing_guide_test.exs`** — established Phase 37–38 pattern for guide literal anchors; extend for ORG-09 cross-links.
- **`scripts/ci/README.md` ADOPT table** — template for ORG-09 row + triage bullets.

### Established patterns

- **Blocking vs advisory** split already documented in `adoption-proof-matrix.md` (Fake vs live Stripe).
- **Dual-lane testing story** in `accrue/guides/testing.md` (package docs vs VERIFY-01) — ORG-09 should **plug into** that mental model.

### Integration points

- **`host-integration` job** — append or chain `verify_adoption_proof_matrix.sh` next to existing host verify steps (exact wiring in plan).
- **`mix verify.full` / UAT wrappers** — only if milestone policy requires local parity with CI; decide in plan without expanding scope beyond ORG-09.

</code_context>

<specifics>
## Specific Ideas

- **Laravel Cashier / Pay (Rails):** “User vs team” confusion in examples — Accrue’s matrix must **not** imply the **gem/demo** replaces host tenancy enforcement.
- **Stripe docs:** Customer = billable entity clarity is the **north star** for archetype wording.
- **npm README-only contracts:** common but stale — ORG-09 demands **executable** gates, not prose-only merge-blocking.

</specifics>

<deferred>
## Deferred Ideas

- **Sigra-free example host** or **second fixture app** for executable non-Sigra stack proof — **out of scope** for Phase 39 unless explicitly pulled in; note for a future milestone if desired.
- **Dedicated Playwright** per Pow/custom — deferred to avoid VERIFY-01 dilution and CI flake cost.

</deferred>

---

*Phase: 39-org-billing-proof-alignment*  
*Context gathered: 2026-04-22*
