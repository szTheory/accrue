# Phase 63: P0 integrator / VERIFY / docs - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase **63** closes **INT-10** for the **integrator / VERIFY / docs** axis: every **P0** row in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** tagged for **→63** (**`v1.17-P0-001`**, **`v1.17-P0-002`**) is **shipped** (docs + verifiers + minimal host/CI glue as needed) **or** **explicitly downgraded** with maintainer-signed rationale — without breaking merge-blocking **`verify_package_docs`**, **`host-integration`**, or **VERIFY-01** semantics. **No** billing surface work (**BIL-03**) or admin/LiveView scope (**ADM-12**).

</domain>

<decisions>
## Implementation Decisions

### D-01 — `v1.17-P0-001` (pins / Hex / First Hour / `@version` honesty)

- **D-01a (SSOT):** Keep **one numeric SSOT**: `mix.exs` **`@version`** in **`accrue`** and **`accrue_admin`**, **lockstep**, enforced by **`bash scripts/ci/verify_package_docs.sh`** + **`accrue/test/accrue/docs/package_docs_verifier_test.exs`**. Do **not** relax the verifier to “human review” pins — that trades away billing-adjacent trust.
- **D-01b (integrator mental model):** Carry **Hex vs `main` / `path:`** in **short, skimmable prose** (not a second competing version table): the merge-gated `~>` literals mean **“this branch’s docs artifact matches the release line we cut them with”**; on **`path:`** or unreleased SHAs, integrators align sibling packages and treat the **lockfile** as resolution SSOT for production billing.
- **D-01c (First Hour / README):** After the deps block, state **three facts in plain language**: (1) pins track the **Hex** story for the published line; (2) **workspace / path** users keep versions aligned; (3) **pre-1.0 `~>`** behavior in one sentence + **lockfile** discipline for production — mirroring how **Laravel Cashier / Pay / Stripe** separate “stable install” vs “edge” without implying semver fairy tales on `0.x`.
- **D-01d (optional dual snippet):** A **Hex** block + **`path:`** block (like **nimble_*** / small Hex libs) is **acceptable only** if **`verify_package_docs`** (or a narrow extension) keeps both **honest** — reject hand-maintained **third** SSOTs (badges, version tables) outside the enforced literals.
- **D-01e (anti-patterns):** No divergent `@version` vs README `~>` vs hand “current version”; no **`main`-only** install story without a parallel **Hex** path; no implying **`~> 0.x`** is “safe” for billing without lockfile language.

### D-02 — `v1.17-P0-002` (`host-integration` failure discoverability)

- **D-02a (primary lever):** Keep **`host-integration`** as **one merge-blocking job** (stable `needs:` / semantics). Improve **in-log identity**: ordered sub-invocations (wrapper and/or **`mix verify.full`** phases) emit **consistent stderr prefixes** (same family as **`[verify_package_docs]`**) and a **single final failure banner** (e.g. **`FAILED_GATE=…`**) so the **first scroll** names the broken contract.
- **D-02b (docs lever):** Add a **short** **`scripts/ci/README.md`** subsection — **host-integration log triage**: prefix → meaning → link to **`examples/accrue_host/README.md#proof-and-verification`** for depth. **Do not** duplicate the full normative job manifest; **`.github/workflows/ci.yml`** stays machine SSOT for required jobs.
- **D-02c (defer):** **Split jobs** / heavy **`needs:`** fan-out only if prefix + banner + triage row still fail in practice (minute/cache cost). **GitHub annotations** (`::error`) are **optional** polish on top of **D-02a**, not the first dependency.
- **D-02d (coherence):** **VERIFY-01** stays anchored in the **host README**; **CI README** stays the **contributor map**; prefixes bridge **lane** vs **proof** without three divergent command inventories.

### D-03 — P0 closure vs downgrade (governance + needles)

- **D-03a (default):** **Ship** when the row still matches evidence — closure = **integrator relief** (repro path + green merge gates), not prose-only.
- **D-03b (downgrade):** Allowed only with a **mini-ADR** in inventory **`notes`**: **Evidence** (commits/PRs/verifier lines), **User impact**, **Mitigation** (what shipped or accepted risk), **Revisit trigger** (dated or event-based), **Maintainer (YYYY-MM-DD)** signature — borrowing **RFC disposition** + **Stripe-like severity honesty**.
- **D-03c (needle law):** **`scripts/ci/verify_v1_17_friction_research_contract.sh`** expects **four** inventory rows and **two** **P0** lines with **`| INT-10 |`** and **`| →63 |`**. **True priority demotion** (removing a P0 slot) is an **intentional milestone edit**: relax needles **together with** **REQUIREMENTS** / **ROADMAP** / replacement row — never silent one-cell hacks. **In-place progress** updates **`status`**, **`notes`**, signed text **without** breaking table shape, **`### Backlog — INT-10`** anchors, **FRG-03** slice links, or ambiguous bare **`v1.17-P0-`** audit traps in prose.
- **D-03d (north star):** **FRG-03** stays the firewall; **INT-10** stays honest — no tacit deferrals off inventory.

### D-04 — `63-VERIFICATION.md` shape (ceremony vs coverage)

- **D-04a (lean):** **`63-VERIFICATION.md`** = **scope** (INT-10 only, pointer to inventory **### Backlog — INT-10**) + **traceability table** (one row each **`v1.17-P0-001`**, **`v1.17-P0-002`**, rollup **INT-10**) with **acceptance one-liner** + **merge-blocking proof** (commands / test modules) + **CI vs manual** split + **closure** (**`REQUIREMENTS.md`** checkbox, inventory row disposition). **No** essay-length restatement of **`ci.yml`**.
- **D-04b (verifier-as-test):** Follow **Phase 62** precedent: **bash contract** + thin **ExUnit** wrapper where it already exists (`package_docs_verifier_test.exs`, **`v1_17_friction_research_contract_test.exs`** if planning pointers move).
- **D-04c (handoff):** Explicit note that **64** (**BIL-03**) / **65** (**ADM-12**) own **heavier** ExUnit/LiveView matrices — **63** keeps the **integrator/VERIFY/docs spine** thin.

### D-05 — Research method (this discuss session)

- **D-05a:** Four **parallel** research passes (pins/Hex, CI discoverability, governance, verification shape) were **synthesized** into **D-01–D-04** as one coherent bar — user selected **all** gray areas and requested a **single** maintainer-grade recommendation set.

### Claude's Discretion

- **Prefix strings / exact banner format** for **D-02a** — pick names consistent with existing script output; add a **short** ExUnit or golden-log test if a new prefix contract is introduced.
- **Exact placement** of the **Hex vs `main`** paragraph inside **First Hour** vs package READMEs — follow existing “How to enter” / install flow **as long as** **`verify_package_docs`** needles stay satisfied.

### Folded Todos

- None.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Obligations + backlog

- `.planning/REQUIREMENTS.md` — **INT-10** definition + traceability
- `.planning/ROADMAP.md` — Phase **63** goal, success criteria, **FRG-03** slice link
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — **`v1.17-P0-001`**, **`v1.17-P0-002`**, **### Backlog — INT-10 (Phase 63)**
- `.planning/research/v1.17-north-star.md` — **FRG-02** stop rules + triage-before-sweeps intent

### Prior phase context

- `.planning/phases/62-friction-triage-north-star/62-CONTEXT.md` — SSOT layout, two-axis P0 bar, **FRG-03** firewall, plan ↔ row-id traceability

### Machine contracts (edit only with verifier + tests)

- `scripts/ci/verify_package_docs.sh` — pin / README / **First Hour** literals
- `scripts/ci/verify_v1_17_friction_research_contract.sh` — friction inventory / north-star needles (**INT-10** planning gate)
- `scripts/ci/verify_verify01_readme_contract.sh` — **VERIFY-01** host README depth
- `.github/workflows/ci.yml` — **`host-integration`** job (normative required-job set)
- `scripts/ci/README.md` — INT/ADOPT triage tables, contributor map

### Integrator-facing surfaces

- `accrue/guides/first_hour.md` — golden-path deps + narrative
- `accrue/README.md`, `accrue_admin/README.md` — package install lines
- `examples/accrue_host/README.md` — **#proof-and-verification**, host proof story

### Tests (when touched)

- `accrue/test/accrue/docs/package_docs_verifier_test.exs`
- `accrue/test/accrue/docs/v1_17_friction_research_contract_test.exs`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`scripts/ci/verify_package_docs.sh`** — Parses **`@version`**, enforces sibling **`accrue` / `accrue_admin`** lines and **`first_hour.md`** pins; stderr **`[verify_package_docs]`** prefix pattern to mirror for **D-02a**.
- **`scripts/ci/README.md`** — **INT-06..INT-10** gate table + triage bullets; extend with **host-integration** prefix map (**D-02b**).
- **`accrue_host_uat.sh` / `mix verify.full`** (as wired today) — Integration point for **ordered sub-gate** messaging without YAML split (**D-02a**).

### Established patterns

- **Verifier + ExUnit shell** — Contract lives in bash; tests invoke the same script end-to-end (**Phase 32+** pattern).
- **Single-job `host-integration`** — Proves Phoenix/LiveView stack + host; deep logs are the default failure surface — **prefix discipline** is the lowest-churn fix.

### Integration points

- Inventory row **`status` / `notes`** updates ↔ **`verify_v1_17_friction_research_contract.sh`** needles.
- **`REQUIREMENTS.md`** **INT-10** checkbox ↔ evidence in **`63-VERIFICATION.md`** + committed inventory rows.

</code_context>

<specifics>
## Specific Ideas

- User asked for **all four** gray areas to be researched in parallel (subagents), then **one-shot** cohesive recommendations emphasizing **Elixir/Hex idioms**, **Pay / Cashier / Stripe**-style install clarity, **least surprise**, **great DX**, and **architecture coherence** with **Accrue**’s billing-trust posture — captured in **D-01–D-05**.

</specifics>

<deferred>
## Deferred Ideas

- **Split `host-integration` into multiple GitHub jobs** — only revisit if **D-02a** + **D-02b** prove insufficient (**D-02c**).
- **GitHub `::error` annotations** everywhere — optional after stable prefixes (**D-02c**).

### Reviewed Todos (not folded)

- None.

</deferred>

---

*Phase: 63-p0-integrator-verify-docs*  
*Context gathered: 2026-04-23*
