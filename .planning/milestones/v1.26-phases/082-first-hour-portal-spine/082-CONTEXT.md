# Phase 82: First-hour portal spine - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **INT-13**: bring **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) to the **same integrator + proof plane** as **`create_checkout_session/2`** — **First Hour** opening spine, **`examples/accrue_host/README.md`** (especially **§ Observability** + **D-02** capsule with **#proof-and-verification**), **`examples/accrue_host/docs/adoption-proof-matrix.md`**, and merge-blocking **bash** needles (**`verify_adoption_proof_matrix.sh`**, **`verify_package_docs.sh`**, and only other verifiers when literals require it), **same PR** per **`scripts/ci/README.md`**. **Out of scope:** new **`Accrue.Billing`** APIs, **PROC-08**, **FIN-03**, admin LiveView unless VERIFY paths force it.

**Tooling note:** `gsd-sdk query init.phase-op "82"` may return `phase_found: false` while the active-milestone table in **`.planning/ROADMAP.md`** remains authoritative — same class of quirk noted in **`081-CONTEXT.md`**.

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting (research synthesis: Stripe/Cashier/Pay patterns, Elixir guide norms, INT-12 / ORG-09 culture)

- **D-00 (cohesion):** Treat **checkout** and **billing portal** as **two Stripe products** with **one Accrue pattern**: server-side session helper on **`Accrue.Billing`** → telemetry tuple → **anchor in `guides/telemetry.md`** → **Fake-backed facade ExUnit** as behavioral SSOT. Never “checkout full / portal shorthand” asymmetry — that violates **INT-13** “same shape” and trains wrong mental models (redirect as source of truth vs webhooks is already established elsewhere; do not regress portal docs into marketing blurbs).

### Area 1 — **`accrue/guides/first_hour.md`** opening block (after `list_payment_methods`, before “How to enter”)

- **D-01:** Use **two parallel paragraphs** (checkout unchanged; **add** portal paragraph **immediately after** checkout) with **optional one-line intro** immediately above them, e.g. that both are server-side Stripe redirect helpers sharing the same documentation shape — **without** merging bodies into one paragraph or replacing with sparse bullets that drop arity, tuple literals, or anchors. First Hour links must use the same **stable `telemetry.md#…` fragment** pattern as checkout — today checkout uses **`#billing-checkout-session-create`**; add **`<a id="billing-billing-portal-create"></a>`** on the **`billing_portal.create`** row in **`accrue/guides/telemetry.md`** (that row currently has no anchor) and link **`#billing-billing-portal-create`** from First Hour + host README bullets.
- **D-02 (rationale, locked):** Parallel blocks maximize **grep-first / reviewer parity** with **INT-13** and match how strong ecosystems document **named entry points** (Cashier/Pay-style repeatability) while keeping **Stripe’s mental separation** (Checkout vs Customer Portal). Merged prose (**B**) blurs tuples and hurts “portal-only” integrators; bare bullets (**C**) invite ellipsis placeholders and **false-complete** docs unless each bullet is a full mini-paragraph (not worth the dialect change).

### Area 2 — **`adoption-proof-matrix.md`** + **`verify_adoption_proof_matrix.sh`**

- **D-03:** Add a **second row** in the same **Blocking / merge-blocking** table family as checkout (**C1 over C2**): leave the checkout row intact; add a dedicated **billing portal facade** row mirroring checkout’s columns — **`Accrue.Billing.create_billing_portal_session/2`**, **`[:accrue, :billing, :billing_portal, :create]`**, **`billing_portal_session_facade_test.exs`**, **First Hour** + **`guides/telemetry.md`**, **`accrue`** package — **ORG-09** culture = **one row ≈ one provable claim**; do not widen a single cell to hold both APIs.
- **D-04:** Extend **`verify_adoption_proof_matrix.sh`** with **three** new **`require_substring`** calls matching **D-03** literals (same spelling discipline as checkout: arity `/2`, tuple spacing, test basename).
- **D-05 (footgun guard):** The matrix + script are an **index** into real proof (**`mix verify`**, **`host-integration`**, facade tests). Tight substrings are **intentional** under **INT-12**; loosening to “mentions portal” only (**B**) creates **false-green** drift — rejected.

### Area 3 — **`examples/accrue_host/README.md`** § **Observability**

- **D-06:** Add a **second sibling bullet** under **`## Observability`**, **parallel** to the existing **Billing checkout facade** bullet: same field order — **`Accrue.Billing.create_billing_portal_session/2`**, tuple **`[:accrue, :billing, :billing_portal, :create]`**, **`telemetry.md`** anchor for billing portal create, ExUnit SSOT **`billing_portal_session_facade_test.exs`**. Do **not** collapse into one combined “Billing facades” bullet (**B**) and do **not** move literals only to First Hour (**C**) without **also** changing **`verify_package_docs.sh`** — today the **package-docs** gate already pins checkout literals in **both** `first_hour.md` **and** `accrue_host/README.md`; **C** would require an explicit contract migration in a **different** phase, not **82**.
- **D-07:** Extend **`verify_package_docs.sh`** with **`require_fixed`** lines for **`create_billing_portal_session/2`**, the **billing_portal** tuple, and **`billing_portal_session_facade_test.exs`** in **`first_hour.md`** and **`examples/accrue_host/README.md`**, mirroring the three checkout lines (lines ~153–158 today).

### Area 4 — **CHANGELOG** + **verification artifact home**

- **D-08 (canonical evidence path):** Primary closure artifact is **`082-VERIFICATION.md`** under **`.planning/milestones/v1.26-phases/082-first-hour-portal-spine/`**, linked from **`.planning/ROADMAP.md`** when the phase row is wired to the tree (same pattern as **079–081**). **`.planning/phases/082-*`** is **not** the canonical OSS/milestone audit home unless you deliberately dual-write; avoid **PR-only** evidence for requirement traceability.
- **D-09 (`CHANGELOG.md`):** Follow **Keep a Changelog** + **Phase 81** culture: **`[Unreleased]`** — short integrator-facing lead when the slice ships; **`### Documentation`** for First Hour / host README / matrix; **`### CI`** only when merge-blocking verifier scripts change; **`### Telemetry`** **only** if emission truth or catalog anchors change (unlikely for pure **INT-13** doc spine — omit empty section).

### Claude's Discretion

- Exact optional **one-line intro** wording before the two session paragraphs in **First Hour**.
- Minor table cell prose in the matrix (so long as **D-03** literals remain for scripts).
- **`082-VERIFICATION.md`** table layout — must stay **falsifiable** and cite verifier transcripts / SHAs.

### Folded Todos

- None — `todo.match-phase` returned no matches.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **INT-13** (in-scope / out-of-scope table)
- `.planning/ROADMAP.md` — Phase **82** row, **v1.26** milestone
- `.planning/PROJECT.md` — Adoption spine, **no** **PROC-08** / **FIN-03**

### Prior phase decisions (same family)

- `.planning/milestones/v1.25-phases/081-telemetry-truth-integrator-contracts/081-CONTEXT.md` — **INT-12** same-PR default, **BIL-07** catalog parity culture, signed deferral narrow exception
- `.planning/milestones/v1.25-phases/080-checkout-session-on-accrue-billing/080-CONTEXT.md` — Facade + PII-safe telemetry test SSOT patterns

### Shipped billing portal truth (code SSOT)

- `.planning/milestones/v1.24-phases/78-billing-portal-on-accrue-billing-telemetry-truth/78-VERIFICATION.md` — **BIL-04** / **BIL-05** emission baseline

### Verifiers and CI triage

- `scripts/ci/README.md` — Same-PR co-update triage
- `scripts/ci/verify_package_docs.sh` — First Hour + host README literals
- `scripts/ci/verify_adoption_proof_matrix.sh` — Matrix substring contract
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README (run if **#proof-and-verification** prose moves)

### Edit targets

- `accrue/guides/first_hour.md`
- `accrue/guides/telemetry.md` — Confirm **`#`** anchor for billing portal row exists or add alongside checkout anchor pattern
- `examples/accrue_host/README.md`
- `examples/accrue_host/docs/adoption-proof-matrix.md`
- `accrue/CHANGELOG.md` — When user-visible doc/CI slice ships

### Tests (reference only; no code change expected unless regression found)

- `accrue/test/accrue/billing/billing_portal_session_facade_test.exs`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`billing_portal_session_facade_test.exs`** + **`Accrue.Billing.create_billing_portal_session/2`** in **`accrue/lib/accrue/billing.ex`** — behavior and telemetry already shipped (**Phase 78**); **82** is **integrator spine + CI needles**.

### Established patterns

- **`verify_package_docs.sh`** pins checkout in **`first_hour.md`** and **`accrue_host/README.md`** — extend symmetrically (**D-07**).
- **`verify_adoption_proof_matrix.sh`** pins checkout row substrings — extend symmetrically (**D-04**).
- **Host README `## Observability`** uses **sibling bullets** per concern — add portal as sibling (**D-06**).

### Integration points

- **First Hour** ↔ **host README** capsule (**D-02** / **INT-11**) must stay **same PR** when spine vocabulary shifts.

</code_context>

<specifics>
## Specific Ideas

- Subagent research consensus: **parallel prose**, **second matrix row**, **sibling Observability bullet**, **milestone-scoped `082-VERIFICATION.md`**, **CHANGELOG** sections only where user-visible surfaces or scripts move.
- Ecosystem lesson to preserve: **named entry point + tuple + guide anchor + test path** per public billing facade — optimizes **on-call grep** and **library consumer** orientation (Phoenix/Elixir docs favor repeatable subsection shape over clever DRY).

</specifics>

<deferred>
## Deferred Ideas

- **Collapsed README / moved literals:** Refactor observability to cross-link-only **only** in a future phase that **explicitly** migrates **`verify_package_docs.sh`** expectations and evaluator docs — out of scope for **INT-13**.

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 82-first-hour-portal-spine*  
*Context gathered: 2026-04-24*
