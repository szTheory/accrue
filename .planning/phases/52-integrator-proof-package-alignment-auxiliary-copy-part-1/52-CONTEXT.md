# Phase 52: Integrator proof + package alignment + auxiliary copy (part 1) - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>

## Phase boundary

Deliver **INT-04**, **INT-05**, **AUX-01**, and **AUX-02** for **v1.13**: keep **adoption proof** and **evaluator walkthrough** honest vs **golden path + CI lanes** touched by **INT-01..INT-03**; keep **`verify_package_docs`** and **all consumer-facing install lines** aligned with **`mix.exs` `@version`** (numeric SSOT); route **coupon** and **promotion code** admin operator strings through **`AccrueAdmin.Copy`** with tests that **never diverge** from that SSOT on materially touched paths.

**Not in this phase:** **Connect** / **events** copy and VERIFY breadth (**AUX-03..AUX-06** → **Phase 53**); **PROC-08** / **FIN-03**; VERIFY merge-blocking **policy** renames; repo-wide generated-doc machinery beyond extending the **existing** `verify_package_docs` pattern.

</domain>

<decisions>

## Implementation decisions (research-backed, `--all` synthesis)

### 1 — Copy SSOT for coupons & promotion codes (**AUX-01**, **AUX-02**)

- **D-01 (structure — matches Phase 50 D-07):** Add **`lib/accrue_admin/copy/coupon.ex`** and **`lib/accrue_admin/copy/promotion_code.ex`** (`@moduledoc false`), each holding **only** that domain’s operator strings. Expose exclusively via **`alias` + `defdelegate`** blocks on **`AccrueAdmin.Copy`** — same proven pattern as **`AccrueAdmin.Copy.Subscription`**. Do **not** grow **`copy.ex`** with large new `def` bodies for this milestone.
- **D-02 (naming — Phase 50 D-08):** Use **`coupon_*`** and **`promotion_code_*`** prefixes (`coupon_index_eyebrow`, `promotion_codes_breadcrumb_index`, etc.) so **`rg coupon_` / `rg promotion_code_`** maps cleanly to LiveViews and review diffs.
- **D-03 (`Locked` — Phase 50 D-06):** **No** normal coupon/promo UX through **`AccrueAdmin.Copy.Locked`**; reserve `Locked` for verbatim/legal cross-surface strings only.
- **D-04 (tests vs catalog):** Prove **routing** (LiveViews call **`AccrueAdmin.Copy`** / delegated fns) and use **shared Copy calls** (or helpers) in assertions — avoid snapshotting entire copy catalogs in tests (**Rails I18n / Pay** lesson: stable **identifiers**, not duplicated English everywhere).

### 2 — **INT-04** adoption matrix & evaluator walkthrough honesty

- **D-05 (layered truth — extends Phase 51):** **`examples/accrue_host/README.md`** (VERIFY-01 / proof sections) remains **SSOT for executable commands**, **Playwright entrypoints**, and **CI job ids** enforced by **`verify_verify01_readme_contract.sh`**. **`examples/accrue_host/docs/adoption-proof-matrix.md`** is **SSOT for the semantic map** (concern → proof artifact → blocking vs advisory; ORG-09 archetypes) with literals guarded by **`verify_adoption_proof_matrix.sh`** where stable needles exist.
- **D-06 (walkthrough trigger — hybrid):** Update **`evaluator-walkthrough-script.md`** **only when** the same change (or its immediate doc follow-up) alters **commands**, **CI equivalence claims**, **artifact names**, or **blocking vs advisory** language the script tells an evaluator to say or show. Otherwise **do not** rewrite the walkthrough for matrix-only wording tweaks — avoids **Kubernetes-style** four-way command duplication drift.
- **D-07 (“touched lanes”):** **Semantic**, not noisy-strict: a lane is touched when **behavior or naming a reader could act on** changes — job **id**, **merge-blocking vs advisory** semantics, **`mix verify` / `mix verify.full` / Playwright** entrypoints, **script paths**, or **new/renamed** lanes referenced from INT surfaces. Comments-only workflow edits do not automatically force doc rewrites.
- **D-08 (footguns):** Never imply **Layer B** (local host proof) equals **Layer C** (`host-integration` merge contract). Never claim “mirrors full PR CI” unless literally true. Prefer **job id** over display-name drift in contract prose.

### 3 — **INT-05** Hex-facing docs & `verify_package_docs` alignment

- **D-09 (single numeric SSOT):** **`@version` in each package `mix.exs`** is the **only** authority for the **published** SemVer pair; **do not** maintain a competing literal “marketing version” in prose that can drift from `main` after a bump.
- **D-10 (extend existing gate):** Extend **`scripts/ci/verify_package_docs.sh`** (dynamic parse + `require_fixed` / regex needles) to **every install-adjacent consumer surface** Phase 52 touches — at minimum **package READMEs**, **`accrue/guides/first_hour.md`**, and **operator-facing install prose** in **`accrue_admin/README.md`** (and any **ExDoc extras** already in the gate’s spirit) — so **Release Please** bumps `mix.exs` and CI lists **remaining fence edits** (**desirable friction**, not duplicate SSOT).
- **D-11 (Oban-style surprise reduction):** Strengthen or add a **short banner** on **GitHub-facing READMEs**: install lines on **`main`** follow **`@version` on this branch**; **“what Hex has right now”** → **Hex.pm / HexDocs** (reduces **README-on-main vs Hex** footgun seen in mature Elixir libs).
- **D-12 (non-goals):** **No** repo-wide **CI-generated markdown** for v1.13 unless maintainers explicitly choose it later — bash parse + grep gates match Accrue’s **ADOPT** style and stay **cohesive** with the existing script.

### 4 — Verification depth: Phase **52** vs **53** (**AUX-06** boundary)

- **D-13 (primary proof in 52):** Land **Copy correctness** with **`Phoenix.LiveViewTest` / ExUnit** in **`accrue_admin`** (and **host-mounted** tests where already idiomatic) so **no test hand-duplicates** `Copy` literals on touched coupon/promo paths — satisfies **AUX-01/02** “no divergent literals” for **Elixir-layer** assertions.
- **D-14 (Playwright + axe deferral):** **Full** VERIFY-01 **Playwright + axe** coverage for **coupon/promo mounted routes** is **Phase 53** work under **AUX-06** (same posture as roadmap: 53 owns auxiliary VERIFY breadth). Phase **52** does **not** replicate the **v1.12-style** full mounted-path matrix for those URLs.
- **D-15 (exception — minimal browser):** If Phase 52 **already** edits **VERIFY-01** specs or **`export_copy_strings`** / **`accrue_host_verify_browser.sh`**, add **at most** a **narrow** Playwright smoke per touched flow, with every asserted string from **`e2e/generated/copy_strings.json`** after extending the **Mix task allowlist** — follow **Phase 50 D-18–D-23** (**no `networkidle`**, locator-driven readiness, **`getByRole`/`getByLabel`**, `data-test-id` scalpel only). Otherwise **defer** browser specs to **53**.
- **D-16 (D-23 prep without scope creep):** Optionally extend **`mix accrue_admin.export_copy_strings`** allowlist with **coupon/promo keys** in Phase 52 **if** it reduces Phase 53 merge risk — **not** required to ship Phase 52 if no Playwright changes land here.

### 5 — Cross-cutting principles (ecosystem synthesis)

- **D-17 (Stripe / Pay / Cashier):** OSS cannot reproduce **Dashboard-class** QA; **Fake-first** proof + **honest layering** + **small curated** browser contracts beat implied full-product CI coverage.
- **D-18 (least surprise):** One **vocabulary** for versions (`@version` + gates), one **pattern** for copy growth (**`defdelegate` + `copy/<domain>.ex`**), one **policy** for docs (**README commands**, **matrix semantics**, **walkthrough on delta**).

### Claude's discretion

- Exact **function names** inside **`coupon_*`** / **`promotion_code_*`** as long as prefixes stay consistent.
- Whether Phase 52 touches **any** Playwright file at all (**D-15** exception path).
- **Minimal** CONTRIBUTING / PR-template checkbox wording for **INT-04** triggers.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements

- `.planning/REQUIREMENTS.md` — **INT-04**, **INT-05**, **AUX-01**, **AUX-02**
- `.planning/ROADMAP.md` — Phase **52** + **53** boundary; v1.13 success criteria
- `.planning/PROJECT.md` — v1.13 integrator + auxiliary goals; non-goals

### Prior phase locks (carry-forward)

- `.planning/phases/51-integrator-golden-path-docs/51-CONTEXT.md` — INT-01..03 spine; **Layer A/B/C** honesty; VERIFY-01 front door
- `.planning/phases/50-copy-tokens-verify-gates/50-CONTEXT.md` — **`AccrueAdmin.Copy`** public surface; **`defdelegate` + `copy/<domain>.ex`**; **D-23** export + VERIFY-01 patterns; **ADM-06** inventory; **no VERIFY policy change**

### Doc & proof surfaces (**INT-04**)

- `examples/accrue_host/README.md` — VERIFY-01 / proof commands (**contract SSOT**)
- `examples/accrue_host/docs/adoption-proof-matrix.md` — semantic proof map
- `examples/accrue_host/docs/evaluator-walkthrough-script.md` — evaluator narrative (**update on D-06 triggers only**)
- `scripts/ci/verify_verify01_readme_contract.sh` — README literal contract
- `scripts/ci/verify_adoption_proof_matrix.sh` — matrix stable needles (extend when adding literals)

### Version & package docs (**INT-05**)

- `scripts/ci/verify_package_docs.sh` — `@version` parse + README / fence alignment (**extend coverage**, do not fork SSOT)
- `accrue/mix.exs` — **`@version`**
- `accrue_admin/mix.exs` — **`@version`**, sibling **`{:accrue, "~> #{@version}"}`**

### Copy & VERIFY implementation

- `accrue_admin/lib/accrue_admin/copy.ex` — facade + **`defdelegate`** insertion point
- `accrue_admin/lib/accrue_admin/copy/subscription.ex` — reference pattern for new domain modules
- `accrue_admin/lib/accrue_admin/live/coupons_live.ex` — **AUX-01** target
- `accrue_admin/lib/accrue_admin/live/coupon_live.ex` — **AUX-01** target
- `accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex` — **AUX-02** target
- `accrue_admin/lib/accrue_admin/live/promotion_code_live.ex` — **AUX-02** target
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — **D-23** allowlist (**Phase 50**)
- `scripts/ci/accrue_host_verify_browser.sh` — export invocation before browser CI
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — VERIFY-01 extension point (**Phase 53** primary unless **D-15** exception)

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`AccrueAdmin.Copy` + `Copy.Subscription` + `defdelegate`:** Phase 52 **extends** this pattern for **coupon** and **promotion code** domains — no new public modules beyond implementation files behind the facade.
- **`mix accrue_admin.export_copy_strings`:** Already enforces **Playwright ↔ Copy** non-drift for allowlisted keys; extend allowlist when browser specs assert new strings.

### Established patterns

- **Phase 50 D-23:** Generated **`e2e/generated/copy_strings.json`** + CI regeneration — any Phase 52 Playwright must **consume** this, not hand-paste English.
- **VERIFY-01:** Locator-driven LiveView readiness; **avoid `networkidle`**.

### Integration points

- **Coupon/promo LiveViews** under **`accrue_admin/lib/accrue_admin/live/`** → replace inline operator strings with **`AccrueAdmin.Copy.*`** calls.
- **`verify_package_docs.sh`** → add needles for any new version-sensitive prose paths edited for **INT-05**.

</code_context>

<specifics>

## Specific ideas

Research synthesis (parallel agents, 2026-04-22): **Rails I18n**-style stable identifiers without YAML sprawl; **Pay/Cashier** lesson that libraries need **grep-friendly, testable** operator text; **Oban README** pattern for **main vs Hex** clarity; **Kubernetes** lesson that **generated** tables are optional — Accrue instead uses **machine-checked literals** on a small set of high-trust files.

</specifics>

<deferred>

## Deferred ideas

- **Full Playwright + axe** matrix for **coupon/promo** (and other auxiliary routes) → **Phase 53** (**AUX-06**), unless **D-15** minimal exception fires.
- **Connect** / **events** copy (**AUX-03..AUX-05**) → **Phase 53** per roadmap.

</deferred>

---

*Phase: 52-integrator-proof-package-alignment-auxiliary-copy-part-1*  
*Context gathered: 2026-04-22*
