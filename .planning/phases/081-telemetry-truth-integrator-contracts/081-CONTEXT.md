# Phase 81: Telemetry truth + integrator contracts - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Align **`accrue/guides/telemetry.md`**, **`billing_span_coverage_test.exs`** (as defined today: span presence per public **`Accrue.Billing`** function), **`accrue/CHANGELOG.md`**, and **integrator / proof artifacts** (**First Hour**, **`examples/accrue_host` README**, adoption proof matrix, **VERIFY-01**-related docs and coupled verifiers) with **`Accrue.Billing.create_checkout_session`** now that **BIL-06** shipped in Phase **80**. Satisfies **BIL-07** and **INT-12** per **`.planning/REQUIREMENTS.md`**. **Out of scope:** **PROC-08**, **FIN-03**, new **ops** tuples unless already roadmap-owned elsewhere.

**Note:** `gsd-sdk query init.phase-op "81"` may return `phase_found: false` — phase row is authoritative in **`.planning/ROADMAP.md`**.

</domain>

<decisions>
## Implementation Decisions

### INT-12 — Golden-path docs vs verifier needles (research: Pay/Cashier/SDK lag, CI truthfulness)

- **D-01 (default — same PR):** The moment **`create_checkout_session`** is mentioned on any **merge-blocking** or **golden-path** surface (**`accrue/guides/first_hour.md`**, **`examples/accrue_host/README.md`**, **`examples/accrue_host/docs/adoption-proof-matrix.md`**, VERIFY-01-facing prose), update **all** coupled **bash** verifiers and **ExUnit** literal harnesses named in **`scripts/ci/README.md`** triage (**including** **`docs-contracts-shift-left`** members when paths change) in the **same PR** as the doc/guide edits. Rationale: merge-blocking CI must stay **truthful** with evaluator-facing narrative; split PRs are the dominant footgun (second PR never ships, or docs contradict green CI). Matches **INT-11** / ORG-09 culture already in-repo.

- **D-02 (narrow exception — signed deferral):** Use **`.planning/REQUIREMENTS.md`**’s deferral path **only** when Phase **81** ships **without** changing those golden-path surfaces **at all**. Then **`81-VERIFICATION.md`** carries a **signed** deferral: **dated**, names **exact follow-up milestone + phase** (or equivalent roadmap hook), and states what **was / was not** updated so adopters do not infer a golden-path flow from **CHANGELOG** / **`@doc`** that guides still omit (or explicitly frames checkout as **API-level only** until the hook fires). **Never** silent drift.

- **D-03:** Prefer **D-01** for Accrue’s **professional adoption confidence** and **principle of least surprise** — library consumers should not see “depth shipped” in one voice and “integrator spine unchanged” in another without the **traceable bridge** of **D-02**.

### BIL-07 — `guides/telemetry.md` catalog row (research: Phoenix/Ecto/Oban guide + moduledoc split, OTel cardinality, grep-first DX)

- **D-04 (parity row):** Add a **`billing_portal.create`-density** row for **`accrue.billing.checkout_session.create`** / **`[:accrue, :billing, :checkout_session, :create]`** from **`Accrue.Billing.create_checkout_session/2`**, with **Phase / requirement** traceability (**BIL-06** / **80** for emission truth; **BIL-07** / **81** for catalog edit). Include the **explicit allowlist** of span metadata keys: **`checkout_mode`**, **`checkout_ui_mode`**, **`checkout_line_items_count`** — and a **short** reminder they are the **only** checkout-specific merged fields; **no** URLs, **`client_secret`**, or raw attrs (reinforces Phase **80** PII contract next to the event). Add **one line** if needed: span metadata vs **metric tags** (do not promote unbounded dimensions to metric labels) — consistent with existing **Cardinality discipline** in the guide.

- **D-05:** Keep **`Accrue.Billing` `@doc`** as the **API / integrator** SSOT; **duplication** of tuple + OTel dotted name between guide and **`@doc`** is **desirable** (operators grep the guide; developers read Hex).

- **D-06:** **`billing_span_coverage_test.exs`** — **no** structural change for BIL-07 unless the phase **redefines** “inventory”; today it enforces **span presence** per public **`Accrue.Billing`** function. **Do** bump the guide’s **“Last reconciled (billing span examples)”** stamp when the checkout row lands.

- **D-07:** **`checkout_session_facade_test.exs`** remains the **behavioral** SSOT for metadata absence / allowlist presence — catalog prose follows tests + **`merge_checkout_session_create_metadata`**, not the reverse.

### BIL-07 — `operator-runbooks.md` (research: RUN-01 depth vs Stripe-owned error catalogs, billing portal precedent)

- **D-08 (light pointer):** Extend **`accrue/guides/operator-runbooks.md`** in the **same family** as the existing **billing portal** Stripe-verification note: **one short paragraph** (or equivalent) under the existing **Stripe** / revenue-adjacent area that names the **checkout** span / **`operation_id`** / **Fake vs live** configuration pointer and **links** to the **`telemetry.md`** anchor for **`create_checkout_session`**. **Do not** add a **fifth** full mini-playbook or enumerate Stripe Checkout’s error matrix — that is **Stripe-owned**, high-churn, and duplicates vendor docs.

- **D-09 (escalation trigger):** Promote to a **dedicated** checkout mini-playbook **only** when Accrue adds **durable Accrue-specific** checkout failure semantics (e.g. new **`[:accrue, :ops, :*]`** with non-obvious triage comparable to **meter** or **DLQ**). Record that trigger in **`deferred`** if product later demands it.

### CHANGELOG (research: Keep a Changelog, Hex scanner personas)

- **D-10:** Use **Keep a Changelog** sections under **`[Unreleased]`** (or the next release block) with **atomic bullets**: at minimum separable lines for **(a)** telemetry catalog / operator doc, **(b)** integrator-facing doc alignment, **(c)** verifier / CI contract edits — each in **user-outcome language** (what to grep, re-run, or watch in CI), not **only** internal phase ids.

- **D-11 (optional cohesion):** One **short** lead-in sentence under the version header naming the **milestone intent** (observability + integrator honesty + proof tooling in one slice) is allowed **in addition to** **D-10**, not as a substitute for scannable bullets.

### GSD / process (shift-left, low-impact auto-resolve)

- **D-12:** Treat **D-01, D-04, D-08, D-10** as **pre-decided** for **telemetry + integrator contract** phases (same family as **080-CONTEXT D-09** billing-facade defaults). **`discuss_high_impact_confirm`** remains for **semver / Hex publish / security classification / breaking public API** — re-open discuss only when a phase touches those.

### Claude's Discretion

- Exact prose in **`operator-runbooks.md`** pointer and **CHANGELOG** bullet wording.
- If **D-02** is invoked, the precise deferral table row layout in **`81-VERIFICATION.md`** (must still be **falsifiable** and **milestone-linked** per **D-02**).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **BIL-07**, **INT-12**
- `.planning/ROADMAP.md` — Phase **81** row, **v1.25** milestone boundary
- `.planning/PROJECT.md` — Adoption confidence, observability, **no** **PROC-08** / **FIN-03**

### Prior phase coupling

- `.planning/phases/080-checkout-session-on-accrue-billing/080-CONTEXT.md` — Telemetry allowlist, **INT-12** default deferral to **81**
- `.planning/phases/080-checkout-session-on-accrue-billing/080-VERIFICATION.md` — BIL-06 evidence baseline

### CI triage and verifiers

- `scripts/ci/README.md` — Same-PR co-update culture (**INT-12**, **INT-11**, **docs-contracts-shift-left**)
- `scripts/ci/verify_package_docs.sh` — Package doc contract
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README needles
- `scripts/ci/verify_adoption_proof_matrix.sh` — Adoption matrix canonical strings

### Guides and tests (edit targets)

- `accrue/guides/telemetry.md` — Billing span catalog, PII / cardinality policy
- `accrue/guides/operator-runbooks.md` — RUN-01 depth; Stripe verification pointers
- `accrue/guides/first_hour.md` — Golden path (if updated for checkout)
- `examples/accrue_host/README.md` — Host integrator surface
- `examples/accrue_host/docs/adoption-proof-matrix.md` — Matrix needles
- `accrue/CHANGELOG.md` — **`accrue`** package
- `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` — Span presence contract
- `accrue/test/accrue/billing/checkout_session_facade_test.exs` — Checkout telemetry behavior SSOT

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`080`** checkout facade + **`checkout_session_facade_test.exs`** — metadata allowlist and **`[:accrue, :billing, :checkout_session, :create]`** assertions already exist; Phase **81** is **doc + verifier + catalog + changelog** alignment.
- **Billing portal row** in **`telemetry.md`** + **billing portal** short note in **`operator-runbooks.md`** — copy structure, not invent a new doc species.

### Established patterns

- **Guide = operator SSOT** for named **`[:accrue, …]`** tuples; **`@doc`** = integrator / Hex SSOT.
- **Bash needles + thin ExUnit** as merge-blocking contracts co-evolving with prose.

### Integration points

- Any new substring in **First Hour** / host README / matrix triggers **`verify_package_docs`**, **`first_hour_guide_test.exs`**, matrix tests, etc. — triage per **`scripts/ci/README.md`**.

</code_context>

<specifics>
## Specific ideas

- Parallel **research subagents** (2026-04-24): **INT-12** favors same-PR when surfaces move; **Cashier/Pay/SDK** teach “code before long-form docs” is tolerable only with honest **CHANGELOG** / reference docs and **fast** golden-path catch-up — Accrue already invests in needles, so **same-PR** is lower marginal cost than consumer confusion.
- **Telemetry row:** parity with **`billing_portal.create`** — grep-first audits, explicit allowlist reduces OTel bridge footguns.
- **Runbooks:** **Sentry/Honeybadger**-style libraries own **stable fingerprints** and **one-screen triage**, not full third-party error catalogs — **light pointer** matches **`RUN-01`** depth rules already in-repo.

</specifics>

<deferred>
## Deferred ideas

- **Full checkout mini-playbook** in **`operator-runbooks.md`** — when **D-09** escalation trigger fires (Accrue-specific **ops**-level checkout semantics).

### Reviewed Todos (not folded)

- None — `todo.match-phase "81"` returned no matches.

</deferred>

---

*Phase: 081-telemetry-truth-integrator-contracts*  
*Context gathered: 2026-04-24*
