# Accrue

## What This Is

Accrue is an open-source Elixir/Phoenix payments and billing library, inspired by Pay (Rails) and Laravel Cashier but built idiomatically for the Elixir/Ecto/Plug/Phoenix ecosystem. It gives Phoenix SaaS developers a batteries-included "jumpstart" for everything a real SaaS business needs on day one — subscriptions, checkout, invoices, coupons, emails, PDFs, webhooks, admin UI, telemetry — without the migration pain and design regrets earlier libraries accumulated.

Tagline: *"Billing state, modeled clearly."*

## Core Value

**A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one** — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain for at least the first major version. Everything else is in service of that.

## Current milestone

### v1.29 — Mailglass Integration (**planning opened 2026-04-25**)

**Goal:** Replace `mjml_eex` and `phoenix_swoosh` with the [Mailglass](https://github.com/szTheory/mailglass) framework as a path dependency. Mailglass provides HEEx-native components (no Node MJML compile), an append-only event ledger, native database-level idempotency via `idempotency_key`, and a LiveView dev-preview dashboard mounted at `/dev/mail` in `accrue_admin`. **No** **PROC-08** / **FIN-03**.

**Target features:**

- [ ] **MG-01..MG-03** (Phase 88 — Foundation): path-dep `mailglass` in `accrue` and `mailglass_admin` in `accrue_admin`; mount `/dev/mail` LiveView dashboard; verify the three Mailglass migrations execute in host.
- [ ] **MG-04..MG-06** (Phase 89 — Proof of Concept): refactor `Accrue.Workers.Mailer` to dispatch via `Mailglass.deliver/1` with explicit `idempotency_key`; port `Accrue.Emails.Receipt` + `Accrue.Emails.PaymentFailed` from MJML to `Mailglass.Mailable`; verify PDF attachment.
- [ ] **MG-07** (Phase 90 — Cleanup): port the remaining 11 MJML templates; remove `mjml_eex` and `phoenix_swoosh` from `accrue/mix.exs`; retire `mix accrue.mail.preview`.

**Live requirements:** `.planning/REQUIREMENTS.md`. **Phases:** **88–90** (see `.planning/ROADMAP.md`). **Background research:** `.planning/research/v1.29-mailglass-integration.md`.

### v1.28 — Next linked publish continuity (**archived 2026-04-25 — planning complete 2026-04-24**)

**Goal (planning closed):** Post-publish contract work (**PPX-05..08**, same semantics family as **v1.23** **PPX-01..04**) and the dated friction-inventory maintainer pass (**INV-06**). Strategic spine **B** (maintenance / wrap-up plan). **No** **PROC-08** / **FIN-03**.

**Shipped artifacts:**

- [x] **PPX-05..08** — Package docs, adoption matrix + script, `docs-contracts-shift-left`, `.planning/` Hex mirrors aligned to the new `@version` / registry reality. Validated 2026-04-24 — `.planning/milestones/v1.28-phases/086-post-publish-contract-alignment/086-VERIFICATION.md` (re-verification at **0.3.1**).
- [x] **INV-06** — Post-publish `v1.17-FRICTION-INVENTORY.md` maintainer pass (b) with `087-VERIFICATION.md` verifier evidence. Validated 2026-04-24 — `.planning/milestones/v1.28-phases/087-friction-inventory-post-publish/087-VERIFICATION.md`.

**Archived requirements:** `.planning/milestones/v1.28-REQUIREMENTS.md`. **Phases:** **86–87** in `.planning/milestones/v1.28-ROADMAP.md`. **Next forcing function:** linked Hex publish per `RELEASING.md` (outside this in-repo planning milestone).

### v1.27 — Pre-1.0 closure narrative (**archived 2026-04-24**)

**Goal (shipped):** Make the **“parked / intake-gated”** maintainer posture and **pre-1.0 vs 1.0.0** intent legible on integrator front doors and release docs—without new billing primitives. Close with a dated **friction inventory** maintainer pass after the doc touch (**INV-05**). **No** **PROC-08** / **FIN-03**.

**Shipped:**

- [x] **CLS-01** — Root + **`accrue`** README surfaces link **maturity-and-maintenance** + **production-readiness** and state **intake-gated** work (no speculative roadmap implied).
- [x] **CLS-02** — **`RELEASING.md`** documents **pre-1.0 closure** maintainer intent; **`upgrade.md`** adds **wrap-up semantics** pointer to maturity doc.
- [x] **CLS-03** — **`accrue/README.md` Stability** clarifies **`0.x`** ≠ open-ended feature expansion; **PROC-08** / **FIN-03** remain **`PROJECT.md`** non-goals (cross-linked from root **Maintenance posture**).
- [x] **INV-05** — Post-CLS doc touch: maintainer pass **(b)** on **`v1.17-FRICTION-INVENTORY.md`** with **`085-VERIFICATION.md`** verifier transcripts (same bundle family as **INV-03** / **INV-04**).

**Evidence:** **`.planning/milestones/v1.27-ROADMAP.md`**, **`v1.27-REQUIREMENTS.md`**, **`milestones/v1.27-phases/84-pre-1-0-closure-narrative/084-VERIFICATION.md`**, **`milestones/v1.27-phases/85-friction-inventory-post-closure/085-VERIFICATION.md`**; inventory **`### v1.27 INV-05 maintainer pass (2026-04-24)`**; planning git tag **`v1.27`**.

### v1.26 — First-hour billing facade spine (**archived 2026-04-24**)

**Goal (shipped):** Put **`Accrue.Billing.create_billing_portal_session/2`** on the same **First Hour + host README + adoption proof matrix + verifier** plane as **`create_checkout_session`**, then run a **dated friction-inventory maintainer pass** after that doc touch. **No** **PROC-08** / **FIN-03**.

**Shipped:**

- [x] **INT-13** — Guide capsule, host README parity (**D-02** / **INT-11**), matrix row + **`verify_adoption_proof_matrix`** (and coupled doc verifiers in the **same PR** when required). **Validated in Phase 82** (`milestones/v1.26-phases/082-first-hour-portal-spine/082-VERIFICATION.md`).
- [x] **INV-04** — Path **(b)** dated maintainer certification + **`083-VERIFICATION.md`** (`milestones/v1.26-phases/083-friction-inventory-post-touch/083-VERIFICATION.md`).

**Evidence:** **`.planning/milestones/v1.26-ROADMAP.md`**, **`v1.26-REQUIREMENTS.md`**, execution trees **`milestones/v1.26-phases/`**; planning git tag **`v1.26`**.

### v1.25 — Evidence-bound triad (friction + integrator + billing depth) (**archived 2026-04-24**)

**Goal (shipped):** **INV-03** maintainer pass; **`Accrue.Billing.create_checkout_session/2`** (**BIL-06**) with **Fake** + **`:telemetry` / span**; **BIL-07** / **INT-12** telemetry + integrator needles — **no** **PROC-08** / **FIN-03**.

**Evidence:** **`.planning/milestones/v1.25-ROADMAP.md`**, **`v1.25-REQUIREMENTS.md`**, execution trees **`milestones/v1.25-phases/`**; planning git tag **`v1.25`**.

### v1.24 — Billing portal facade + customer PM operator surfaces (**archived 2026-04-24**)

**Goal:** Ship bounded **billing depth** (customer **Billing Portal** session creation on **`Accrue.Billing`** with **Fake**-provable tests and **telemetry** aligned to **`guides/telemetry.md`** / runbooks) plus **admin/operator** quality on the **customer `payment_methods`** tab (**`AccrueAdmin.Copy`**, **`ax-*`**, **VERIFY-01** where routes change materially). **No** **PROC-08** / **FIN-03**; no integrator-milestone or Hex-release theme.

**Shipped (planning):**

- **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) delegating to **`Accrue.BillingPortal.Session`**, with **`:telemetry`** / span parity and catalog/runbook updates (**BIL-04**, **BIL-05**) — **`78-VERIFICATION.md`** under **`milestones/v1.24-phases/78-billing-portal-on-accrue-billing-telemetry-truth/`**.
- **Customer LiveView** payment-methods tab: Copy SSOT burn-down, token discipline, theme exceptions (**ADM-13**, **ADM-14**) — **`76-VERIFICATION.md`**.
- **VERIFY-01** + **axe** on materially touched customer paths; **`export_copy_strings`** / **`copy_strings.json`** hygiene (**ADM-15**, **ADM-16**) — **`77-VERIFICATION.md`**.

**Last closed:** **v1.27** (Phases **84–85**); prior **v1.26** (Phases **82–83**); prior **v1.25** (Phases **79–81**); prior **v1.24** (Phases **76–78**); prior **v1.23** (**2026-04-24**).

### v1.23 — Post-publish contract alignment (Branch A — **archived 2026-04-24**)

**Goal:** After each **linked Hex publish** for **`accrue` / `accrue_admin`**, keep merge-blocking **package docs**, **adoption proof matrix**, and **docs-contracts-shift-left** (including **production-readiness discoverability**) honest, and align **`.planning/`** public-Hex callouts — so integrators on **`main`** and on **Hex** see one coherent pin and doc story.

**Shipped:** **PPX-01..PPX-04**; evidence **`milestones/v1.23-phases/75-post-publish-contract-alignment/75-VERIFICATION.md`**; **`v1.17-P1-002`** **closed** in the friction inventory. Archives: **`.planning/milestones/v1.23-ROADMAP.md`**, **`v1.23-REQUIREMENTS.md`**. Planning git tag **`v1.23`**.

**v1.22 — Production path discoverability** is **archived** (**2026-04-24**). Phase **74**; **PRS-01..PRS-03** validated. Phase tree: **`.planning/milestones/v1.22-phases/74-production-path-discoverability/`**. Archives: **`.planning/milestones/v1.22-ROADMAP.md`**, **`v1.22-REQUIREMENTS.md`**. Planning git tag **`v1.22`**.

**v1.21 — Maturity posture and diminishing returns** is **archived** (**2026-04-23**). Phases **72–73**; **MAT-01..MAT-02**, **INT-11** validated. Phase trees: **`.planning/milestones/v1.21-phases/`**. Archives: **`.planning/milestones/v1.21-ROADMAP.md`**, **`v1.21-REQUIREMENTS.md`**. Planning git tag **`v1.21`**.

**v1.20 — Professional adoption confidence** is **archived** (**2026-04-24**). Phases **70–71**; **INV-01..INV-02**, **PRD-01..PRD-02** validated. Phase trees: **`.planning/milestones/v1.20-phases/`**. Archives: **`.planning/milestones/v1.20-ROADMAP.md`**, **`v1.20-REQUIREMENTS.md`**. Planning git tag **`v1.20`**.

**v1.19 — Release continuity + proof resilience** is **archived** (**2026-04-24**). Phases **67–69**; **PRF-01..PRF-02**, **REL-01..REL-03**, **DOC-01..DOC-02**, **HYG-01** validated. Phase trees: **`.planning/milestones/v1.19-phases/67-proof-contracts/`**, **`68-release-train/`**, **`69-doc-planning-mirrors/`**. Archives: **`.planning/milestones/v1.19-ROADMAP.md`**, **`v1.19-REQUIREMENTS.md`**. Planning git tag **`v1.19`**.

### Library maintenance posture (v1.21)

- **Maintenance mode** — merge-blocking **VERIFY-01**, **`verify_package_docs`**, and **host-integration** stay honest on **`main`**; default work is **intake-gated** (security, correctness, Hex publish, sourced integrator stall) rather than speculative multi-file doc sweeps. See stop rules **S1** / **S5** in [North star](research/v1.17-north-star.md).
- **New friction** — add rows only in [Friction inventory](research/v1.17-FRICTION-INVENTORY.md) using the table **priority bar** and **`sources`**; do not hide scope in **ROADMAP** prose alone.
- **Revisit triggers** — maintainer pass on the inventory after **linked Hex publish** for **`accrue` / `accrue_admin`**, or intentional **adoption-proof-matrix** / **`verify_adoption_proof_matrix.sh`** taxonomy edits (same-PR co-update discipline from **v1.19** **PRF**).
- **Spine for humans** — ship checklist **[`accrue/guides/production-readiness.md`](../accrue/guides/production-readiness.md)**; maintainer-facing summary **[`accrue/guides/maturity-and-maintenance.md`](../accrue/guides/maturity-and-maintenance.md)**.

**Triage doctrine (read-only context, v1.17–v1.18):** [North star + stop rules](research/v1.17-north-star.md) · [Friction inventory](research/v1.17-FRICTION-INVENTORY.md)

**v1.18 — Onboarding confidence** is **archived** (**2026-04-23**). Phase **66**; **UAT-01..UAT-05**, **PROOF-01** validated. Phase tree: **`.planning/milestones/v1.18-phases/66-onboarding-confidence/`**. Archives: **`.planning/milestones/v1.18-ROADMAP.md`**, **`v1.18-REQUIREMENTS.md`**. Planning git tag **`v1.18`**.

**v1.17 — Friction-led developer readiness** is **archived** (**2026-04-23**). Phases **62–65**; **FRG-01..FRG-03**, **INT-10**, **BIL-03**, **ADM-12** validated. Archives: **`.planning/milestones/v1.17-ROADMAP.md`**, **`v1.17-REQUIREMENTS.md`**; planning git tag **`v1.17`**. Phase working trees: **`.planning/milestones/v1.17-phases/`**.

**v1.16 — Integrator + proof continuity** is **archived** (2026-04-23). Phases **59–61**; **INT-06..INT-09** validated. Archives: `.planning/milestones/v1.16-ROADMAP.md`, `v1.16-REQUIREMENTS.md`. Planning git tag **`v1.16`**.

**v1.15 — Release / trust semantics** is **archived** (2026-04-23). Phases **57–58**; **TRT-01..TRT-04** validated. Archives: `.planning/milestones/v1.15-ROADMAP.md`, `v1.15-REQUIREMENTS.md`. Planning git tag **`v1.15`**.

**v1.14 — Companion admin + billing depth** is **archived** (2026-04-23). Phases **54–56**; **ADM-07..ADM-11**, **BIL-01..BIL-02** validated. Archives: `.planning/milestones/v1.14-ROADMAP.md`, `v1.14-REQUIREMENTS.md`. Planning git tag **`v1.14`**.

**v1.13 — Integrator path + secondary admin parity** is **archived** (2026-04-23). Phases **51–53**; **INT-01..INT-05**, **AUX-01..AUX-06** validated. Archives: `.planning/milestones/v1.13-ROADMAP.md`, `v1.13-REQUIREMENTS.md`. Planning git tag **`v1.13`**.

**v1.12 — Admin & operator UX** is **archived** (2026-04-22). Phases **48–50**; **ADM-01..ADM-06** validated. Archives: `.planning/milestones/v1.12-ROADMAP.md`, `v1.12-REQUIREMENTS.md`. Planning git tag **`v1.12`**.

**v1.11 — Public Hex release + post-release continuity** is **archived** (2026-04-22). Phases **46–47**; **REL-01..REL-04**, **DOC-01..DOC-02**, **HYG-01** validated. Archives: `.planning/milestones/v1.11-ROADMAP.md`, `v1.11-REQUIREMENTS.md`. Git tag **`v1.11`**.

**v1.10 — Metered usage + Fake parity** is **archived** (2026-04-22). Phases **43–45**; **MTR-01..MTR-08** validated. Archives: `.planning/milestones/v1.10-ROADMAP.md`, `v1.10-REQUIREMENTS.md`. Spike retained: `.planning/research/v1.10-METERING-SPIKE.md`. Git tag **`v1.10`**.

**v1.9 — Observability & operator runbooks** is **archived** (2026-04-22). Archives: `.planning/milestones/v1.9-ROADMAP.md`, `v1.9-REQUIREMENTS.md`. Gap audit (research): `.planning/research/v1.9-TELEMETRY-GAP-AUDIT.md`. Git tag **`v1.9`**.

**v1.7 Adoption DX + operator admin depth** is **archived** (2026-04-21). Archives: `.planning/milestones/v1.7-ROADMAP.md`, `v1.7-REQUIREMENTS.md`, `v1.7-MILESTONE-AUDIT.md` (**passed**). Git tag **`v1.7`**.

### Non-goals (until reprioritized in a future milestone)

**PROC-08** (second processor) and **FIN-03** (app-owned finance exports) remain **explicitly out of scope** until a later milestone prioritizes them with written boundaries. **Stripe Dashboard** meter setup UX stays host/Stripe documentation unless a future requirement explicitly pulls UI scope in.

## Current State

**Install literals / `{:accrue, "~> …"}` / `{:accrue_admin, "~> …"}`** in package READMEs and **First Hour** follow **`mix.exs` `@version`** on the branch you are reading — enforced by **`verify_package_docs`**.

**Public Hex (last published):** registry reality for consumers — **[`accrue` on Hex](https://hex.pm/packages/accrue)** and **[`accrue_admin` on Hex](https://hex.pm/packages/accrue_admin)** (**0.3.1** each; linked publish **v1.19** Phase **68**, contract pass **v1.23** Phase **75** **2026-04-24**) — updates on **publish** / **HYG**, not on arbitrary doc commits. Workspace **`@version`** on **`main`** matches the published pair.

**Active planning milestone:** **v1.28** — **Next linked publish continuity** (**Phases 86–87** complete per **`086-VERIFICATION.md`** / **`087-VERIFICATION.md`**; **PPX-05..08** + **INV-06** in **`.planning/REQUIREMENTS.md`** **2026-04-24**). Workspace **`@version`** remains **0.3.1** until the **next** linked **Hex** release bumps it.

**Last shipped planning milestone:** **v1.27** — Phases **84–85** (**2026-04-24**): **CLS-01..03**, **INV-05**; **`milestones/v1.27-*`**; execution trees **`milestones/v1.27-phases/`**; planning tag **`v1.27`**. **Prior:** **v1.26** — Phases **82–83** (**2026-04-24**): **INT-13**, **INV-04**; **`milestones/v1.26-*`**; execution trees **`milestones/v1.26-phases/`**; planning tag **`v1.26`**. **Earlier:** **v1.25** — Phases **79–81**; **`v1.25-*`** + **`v1.25-phases/`**; tag **`v1.25`**. **v1.24** — Phases **76–78**; **`v1.24-*`** + **`v1.24-phases/`**; tag **`v1.24`**. **v1.23** — Phase **75** (**PPX-01..04**); **`v1.23-*`** + **`v1.23-phases/`**; **`v1.17-P1-002`** closed; tag **`v1.23`**. **v1.22** — Phase **74**; **`v1.22-*`**; tag **`v1.22`**. **v1.21** — Phases **72–73**; **`v1.21-*`** + **`v1.21-phases/`**; tag **`v1.21`**. **v1.20** — Phases **70–71**; **`v1.20-*`** + **`v1.20-phases/`**; tag **`v1.20`**. **v1.19** — Phases **67–69**; **`v1.19-*`** + **`v1.19-phases/`**; tag **`v1.19`**. **v1.18** — Phase **66**; **`v1.18-phases/`**; tag **`v1.18`**. **v1.17** — **`v1.17-*`** + **`v1.17-phases/`**; tag **`v1.17`**.

**Execution history:** **v1.27** Phases **84–85** under **`milestones/v1.27-phases/`** (**`084-VERIFICATION.md`**, **`085-VERIFICATION.md`**). **v1.26** Phases **82–83** under **`milestones/v1.26-phases/`** (**`082-VERIFICATION.md`**, **`083-VERIFICATION.md`**). **v1.25** Phases **79–81** under **`milestones/v1.25-phases/`** (**`079-VERIFICATION.md`**, **`080-VERIFICATION.md`**, **`081-VERIFICATION.md`**). **v1.24** Phase **78** — billing portal on **`Accrue.Billing`** + telemetry truth (**`milestones/v1.24-phases/78-billing-portal-on-accrue-billing-telemetry-truth/78-VERIFICATION.md`**); **v1.24** Phase **77** — customer PM tab VERIFY + theme + copy export (**`milestones/v1.24-phases/77-customer-pm-tab-verify-theme-copy-export/77-VERIFICATION.md`**); **v1.24** Phase **76** — customer PM inventory + Copy (**`milestones/v1.24-phases/76-customer-pm-tab-inventory-copy-burn-down/76-VERIFICATION.md`**). **v1.23** Phase **75** under **`milestones/v1.23-phases/`**; **v1.22** Phase **74** under **`milestones/v1.22-phases/`**; **v1.21** Phases **72–73** under **`milestones/v1.21-phases/`**; **v1.20** Phases **70–71** under **`milestones/v1.20-phases/`**; **v1.19** Phases **67–69** under **`milestones/v1.19-phases/`**; **v1.18** Phase **66** under **`milestones/v1.18-phases/`**; **v1.17** under **`milestones/v1.17-phases/`**.

## Shipped: v1.7 Adoption DX + operator admin depth (2026-04-21)

**Goal:** Clearer evaluator **VERIFY-01** / adoption doc paths; honest **installer + CI** semantics; **operator-first** admin entry, drill, and nav; **token-safe** dashboard surfaces with **`AccrueAdmin.Copy`** SSOT; **audit corpus** + verifier ownership + dual-contract documentation.

**Delivered (high level):** Phases **32–33** (ADOPT-01..06), **34** (OPS-01..03), **35** (OPS-04..05), **36** (integration hardening + forward-coupling). Evidence: **`.planning/milestones/v1.7-ROADMAP.md`** / **`v1.7-REQUIREMENTS.md`**; granular phase trees were under **`.planning/phases/`** until the **2026-04-23** prune (recoverable from **git history**).

## Shipped: v1.6 Admin UI / UX polish (2026-04-20)

**Goal:** Bring the companion admin (and evaluator-visible mounted paths) to a **consistent, accessible, mobile-credible** bar aligned to Phase 20/21 UI-SPEC contracts—without new billing domain scope or third-party UI kits.

**Delivered:**

- Phase **25** — Route matrix, component coverage notes, and UI-SPEC alignment (v1.6 milestone; **`.planning/milestones/v1.6-ROADMAP.md`**, prior phase path **`25-admin-ux-inventory`** in **git history**).
- Phase **26** — `ax-*` hierarchy on money indexes, detail pages, and webhooks; theme token discipline with documented exceptions.
- Phase **27** — Operator microcopy pass and `AccrueAdmin.Copy` for stable literals in tests.
- Phase **28** — Focus, captions, contrast verification, and mounted-admin axe in VERIFY-01.
- Phase **29** — Mobile Playwright coverage and README mobile shell guidance for mounted admin.

The v1.0 milestone delivered the full billing library, companion admin UI, installer/test DX, release automation, docs, and OSS policy surface.

The v1.1 milestone proved the packages from a real Phoenix user's point of view:

- `examples/accrue_host` is a realistic host app that installs and uses `accrue` and `accrue_admin` through public APIs.
- The host app proves signed-in billing, signed webhook ingest, admin inspection/replay, audit evidence, clean-checkout rebuild, and local boot paths.
- CI runs a Fake-backed host integration gate with Playwright browser coverage, retained failure artifacts, Hex-mode smoke validation, and warning/error annotation sweeps.
- First-user DX is hardened through installer no-clobber reruns, conflict sidecars, shared setup diagnostics, host-first docs, troubleshooting anchors, and package-doc verification.

The v1.2 milestone made Accrue ready for new Phoenix teams to evaluate and trust: `examples/accrue_host` is the canonical local demo/tutorial path, the repository and package docs are host-first, mature OSS support assets are in place, trust evidence is checked in and executable, and expansion discovery ranked Stripe Tax, organization billing, and finance handoff as the next expansion candidates.

## Last Shipped Milestone: v1.3 Tax + Organization Billing

**Goal:** Let Phoenix SaaS teams bill organizations with Stripe Tax enabled, preserve tenant boundaries through Sigra or equivalent host-owned scopes, and hand finance workflows to Stripe-native reporting without Accrue owning accounting semantics.

**Delivered:**

- Stripe Tax on subscriptions and checkout with Fake-backed regression coverage and narrow local tax observability.
- Public tax-location updates, invalid-location recovery, finalization-failure surfacing, and rollout-safety documentation.
- Sigra-first org billing proof, owner-scoped admin queries, webhook replay ambiguity handling, and cross-tenant denial UX.
- VERIFY-01 executable proof (host tests + Playwright + README/CI contract) plus finance handoff guide and doc contract test (Phase 22).

## Earlier milestone: v1.2 Adoption + Trust

**Goal:** Make Accrue feel ready for a new Phoenix team to evaluate, integrate, and trust by polishing the canonical demo/onboarding path, adding mature-library quality signals, and deciding the next expansion bet without partially implementing it.

**Delivered:**
- Canonical local demo path built around `examples/accrue_host`, with documented setup, seeded Fake-backed billing/admin flow, and CI-equivalent verification.
- Host-first tutorial and public docs front door that connect install, first subscription, signed webhook ingest, admin inspection/replay, troubleshooting, production hardening, and package support policy.
- Mature OSS adoption assets: repository README, issue templates, release guidance, and clear Fake vs Stripe test vs live Stripe positioning.
- Trust hardening bundle covering webhook/auth/admin security, seeded performance smoke checks, compatibility, accessibility/responsive browser checks, secret/PII log review, and required-vs-advisory release-gate boundaries.
- Expansion discovery for tax, revenue/export, additional processors, and organization/multi-tenant billing captured as ranked future recommendations only.

## Shipped: v1.5 Adoption proof hardening (2026-04-18)

**Goal:** Make VERIFY-01 + Fake CI + Stripe test-mode parity discoverable for evaluators; ship an evaluator screen-recording checklist; document B2C-shaped API vs org-first LiveView coverage.

**Delivered:**

- `examples/accrue_host/docs/adoption-proof-matrix.md` and `evaluator-walkthrough-script.md`, linked from the host README and enforced by `verify_verify01_readme_contract.sh`.
- `accrue/guides/testing.md` cross-links the matrix and `guides/testing-live-stripe.md`; live-Stripe guide states job id vs Stripe mode.
- GitHub Actions `live-stripe` job **display name** now reads **Stripe test-mode parity (advisory)** (job id unchanged for `act` compatibility).
- `AccrueHost.BillingFacadeTest` module doc references the adoption matrix (PROOF-02 traceability).

## Shipped: v1.4 Ecosystem stability + demo visuals (2026-04-17)

**Goal:** Stay current on published **`lattice_stripe`** within `~> 1.1`, and make the Fake-backed **host + mounted admin** walkthrough trivial to **see** (screenshots + CI artifacts).

**Delivered:**

- `lattice_stripe` lockfiles refreshed across `accrue`, `accrue_admin`, and `examples/accrue_host` (latest on Hex at time of work: **1.1.0**).
- Visual walkthrough docs, `npm run e2e:visuals`, and CI artifact pointers; Playwright trust lane green on desktop + mobile.
- Committed **`accrue_admin` `priv/static` JS/CSS** is a real esbuild bundle so mounted admin LiveView works in the browser; `mix verify.full` rebuilds admin assets before Playwright.

**Explicitly deferred:** **PROC-08** (second processor), **FIN-03** product exports — revisit in a later milestone. **ORG-04** is **in scope for v1.8** (recipes + host integration depth).

Continue to treat `tax rollout correctness`, `cross-tenant billing leakage`, and `wrong-audience finance exports` as release risks regardless of milestone.

## Requirements

### Validated

v1.0 Initial Release shipped and validated on 2026-04-16. Detailed requirement outcomes are archived in `.planning/milestones/v1.0-REQUIREMENTS.md`.

v1.1 Stabilization + Adoption shipped and validated on 2026-04-17. Detailed requirement outcomes are archived in `.planning/milestones/v1.1-REQUIREMENTS.md`.

- ✓ Minimal host-app dogfood harness exercises the real install and user-facing billing/admin paths — v1.1
- ✓ CI runs the host-app integration and browser flows as a release gate — v1.1
- ✓ Focused host-flow proofs are hermetic when run directly after the canonical host UAT wrapper — v1.1
- ✓ Installer, docs, diagnostics, package metadata, and dependency-mode checks are hardened from the host-app experience — v1.1

v1.2 Adoption + Trust shipped and validated on 2026-04-17. Detailed requirement outcomes are archived in `.planning/milestones/v1.2-REQUIREMENTS.md`.

- ✓ Phoenix developers can clone the repository, run the canonical local demo, create a Fake-backed subscription, inspect/replay billing state in admin, and run the focused proof suite without hidden state — v1.2
- ✓ New users can follow a host-first tutorial and docs front door that explains integration order, supported public APIs, production hardening, and Fake/test/live Stripe choices — v1.2
- ✓ Maintainers and adopters have mature OSS support assets, including issue templates and release guidance aligned with the established Accrue voice — v1.2
- ✓ Security, performance, compatibility, accessibility/responsive behavior, and secret/PII safety have explicit checks or review artifacts before the next release — v1.2
- ✓ Tax, revenue/export, additional processor, and organization/multi-tenant billing expansion options are researched and ranked for the next implementation milestone without changing the current billing API — v1.2

### Validated v1.5 (archived in `.planning/milestones/v1.5-REQUIREMENTS.md`; milestone closed 2026-04-18)

- [x] **PROOF-01** — VERIFY-01 / Fake CI cross-linked with Stripe test-mode parity lane; CI + guide naming clarity.
- [x] **PROOF-02** — Host adoption proof matrix documents archetype coverage (including user billable ExUnit vs org-first LiveView).
- [x] **PROOF-03** — Evaluator screen-recording checklist doc linked from host README.

### Validated v1.6 (archived in `.planning/milestones/v1.6-REQUIREMENTS.md`; milestone closed 2026-04-20)

- [x] **INV-01..03** — Admin route matrix, component coverage vs kitchen, Phase 20/21 spec alignment (Phase 25).
- [x] **UX-01..04** — List/detail/webhook hierarchy and theme token discipline (Phase 26).
- [x] **COPY-01..03** — Operator microcopy and stable literals via `AccrueAdmin.Copy` (Phase 27).
- [x] **A11Y-01..04** — Focus, tables, contrast verification, mounted-admin axe in CI (Phase 28).
- [x] **MOB-01..03** — Mobile overflow/nav and admin-heavy `@mobile` / `chromium-mobile` coverage (Phase 29).

### Validated v1.7 (archived in `.planning/milestones/v1.7-REQUIREMENTS.md`; milestone closed 2026-04-21)

- [x] **ADOPT-01..03** — Root README → VERIFY-01 within two hops; host README single proof subsection; guide cross-links (Phase 32).
- [x] **ADOPT-04..06** — Installer rerun docs + anchors; doc contract coverage; merge-blocking vs advisory CI language (Phase 33).
- [x] **OPS-01..03** — Operator home KPIs; customer→invoice drill; `AccrueAdmin.Nav` + README route inventory (Phase 34).
- [x] **OPS-04..05** — Dashboard `ax-*` / token discipline; operator strings via `AccrueAdmin.Copy` + aligned Playwright (Phase 35).

### Validated v1.8 (archived in `.planning/milestones/v1.8-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **ORG-04** — non-Sigra org billing recipes, host integration depth, VERIFY/adoption-proof alignment; **PROC-08** and **FIN-03** not in this milestone.

- [x] **ORG-05** — Single non-Sigra doc spine for session → billable + ORG-03 checklist (`accrue/guides/organization_billing.md` + cross-links). **Validated in Phase 37.**
- [x] **ORG-06** — phx.gen.auth-oriented checklist in that spine (Accrue.Auth, Accrue.Billable, host billing facade). **Validated in Phase 37.**
- [x] **ORG-07** — Pow-oriented recipe + honest maintenance notes. **Validated in Phase 38.**
- [x] **ORG-08** — Custom org model checklist + ORG-03 anti-patterns. **Validated in Phase 38.**
- [x] **ORG-09** — Adoption proof matrix ORG-09 section, merge-blocking bash verifier, contributor map, guide cross-links + ExUnit. **Validated in Phase 39.**

### Validated v1.9 (milestone shipped 2026-04-22)

- [x] **OBS-01, OBS-03, OBS-04** — `guides/telemetry.md` ops catalog + firehose split + gap audit reconciliation. **Validated in Phase 40.**
- [x] **OBS-02, TEL-01** — `MetricsOpsParityTest`, cross-domain host subscription example in guide + `examples/accrue_host`. **Validated in Phase 41.**
- [x] **RUN-01** — `guides/operator-runbooks.md` (Oban topology, Stripe verification pattern, four mini-playbooks) linked from `guides/telemetry.md`. **Validated in Phase 42.**

### Validated v1.10 (archived in `.planning/milestones/v1.10-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **usage metering** + **Fake parity** + **telemetry/docs** alignment; **PROC-08** and **FIN-03** not in this milestone.

- [x] **MTR-01..MTR-03** — Public `report_usage` API, meter event persistence semantics, Fake happy path. **Validated in Phase 43.**
- [x] **MTR-04..MTR-06** — Sync failure + idempotent retry telemetry, reconciler recovery, webhook meter error path. **Validated in Phase 44.**
- [x] **MTR-07..MTR-08** — Metering guide boundaries + telemetry/runbook alignment for `meter_reporting_failed` sources. **Validated in Phase 45.**

### Validated v1.11 (archived in `.planning/milestones/v1.11-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **Hex publish** + **post-release continuity** (docs, verifiers, planning mirrors); **PROC-08** and **FIN-03** not in this milestone.

- [x] **REL-01, REL-02, REL-04** — Maintainer release path, manifest/`mix.exs` SSOT, ship-time tag/Hex evidence. **Validated in Phase 46.**
- [x] **REL-03** — Routine pre-1.0 linked-release narrative in **`RELEASING.md`**. **Validated in Phase 47.**
- [x] **DOC-01, DOC-02** — **`first_hour.md`** install pins; **`verify_package_docs`** + ExUnit on **`main`**. **Validated in Phase 47.**
- [x] **HYG-01** — Planning mirrors (**`PROJECT`**, **`MILESTONES`**, **`STATE`**) match published **0.3.0** pair. **Validated in Phase 47.**

### Validated v1.12 (archived in `.planning/milestones/v1.12-REQUIREMENTS.md`; milestone closed 2026-04-22)

Theme: **admin & operator UX** (**ADM-01..ADM-06**); **PROC-08** and **FIN-03** not in this milestone.

- [x] **ADM-01** — Default admin home shows a **metering-credible** terminal-failed **`MeterEvent`** KPI with honest **`/events`** navigation and **`AccrueAdmin.Copy`** SSOT. **Validated in Phase 48.**
- [x] **ADM-02, ADM-03** — Scoped **customer → subscription → invoice** drill polish with honest links and LiveView tests; nav structure unchanged (**D-08**). **Validated in Phase 49.**
- [x] **ADM-04** — **`SubscriptionLive`** operator chrome routed through **`AccrueAdmin.Copy`** / **`Copy.Subscription`**. **Validated in Phase 50.**
- [x] **ADM-05** — Checked-in **theme exception** register + contributor PR checklist. **Validated in Phase 50.**
- [x] **ADM-06** — Mounted-path inventory + VERIFY-01 expansion with **Copy-derived** Playwright assertions and **`mix accrue_admin.export_copy_strings`** anti-drift gate. **Validated in Phase 50.**

### Validated v1.13 (archived in `.planning/milestones/v1.13-REQUIREMENTS.md`; milestone closed 2026-04-23)

Theme: **integrator golden path** + **auxiliary admin parity**; **PROC-08** and **FIN-03** not in this milestone.

- [x] **INT-01..INT-03** — Single integrator spine (**First Hour** ↔ **`examples/accrue_host`**) with H/M/R capsules; repo-root VERIFY-01 discoverability; troubleshooting anchor SSOT + bounded failure callouts. **Validated in Phase 51.**
- [x] **INT-04** — Adoption proof matrix + evaluator walkthrough honesty vs golden path and CI lanes. **Validated in Phase 52.**
- [x] **INT-05** — **`verify_package_docs`**, package READMEs, and ExDoc install snippets aligned with published **Hex 0.3.0** pair. **Validated in Phase 52.**
- [x] **AUX-01, AUX-02** — **`Coupons*`** / **`PromotionCode*`** operator strings via **`AccrueAdmin.Copy`**; tests avoid divergent literals on touched paths. **Validated in Phase 52.**
- [x] **AUX-03, AUX-04** — **`Connect*`** / **`EventsLive`** meet the same copy + literal discipline. **Validated in Phase 53.**
- [x] **AUX-05** — **`ax-*`** + theme tokens on touched auxiliary surfaces; exceptions recorded in **`theme-exceptions.md`**. **Validated in Phase 53.**
- [x] **AUX-06** — VERIFY-01 **Playwright** + **axe** on materially touched auxiliary mounted paths; **`export_copy_strings`** / **`copy_strings.json`** anti-drift wiring. **Validated in Phase 53.**

### Validated v1.15 (Phases 57–58; docs shipped 2026-04-23)

Theme: **release / trust semantics** (forcing function **B**); **PROC-08** and **FIN-03** not in this milestone.

- [x] **TRT-01..TRT-04** — Hex + **`mix.exs`** baseline in **`upgrade.md`**; **`.planning/` vs SemVer** in **`RELEASING.md`** + root **`README.md`**; **Sigra vs `Accrue.Auth`** + **First Hour** / **organization billing** pointers in **`examples/accrue_host/README.md`**; **`accrue/README.md`** stability + **`RELEASING`** appendix pointer; **`verify_package_docs`** aligned to **`accrue_admin/mix.exs`**. **Validated in Phases 57–58.**

### Validated v1.16 (archived in `.planning/milestones/v1.16-REQUIREMENTS.md`; milestone closed 2026-04-23)

Theme: **integrator + proof continuity** after **v1.15** trust SemVer work; **PROC-08** and **FIN-03** not in this milestone.

- [x] **INT-06** — **First Hour**, **quickstart**, and **CONTRIBUTING** aligned with trust boundary + auth routing narrative; **`verify_package_docs`** enforces quickstart hub + capsule structure; merge-blocking doc trio green. **Validated in Phase 59.**
- [x] **INT-07** — Adoption proof matrix + evaluator walkthrough trust stub + lane honesty; **`scripts/ci/README.md`** INT gates (**INT-06**/**INT-07**) with **CONTRIBUTING** routing. **Validated in Phase 60.**
- [x] **INT-08** — Repo-root **README** preserves **VERIFY-01** / **`host-integration`** discoverability within the documented hop budget; verifier + README updated together when the contract moves. **Validated in Phase 61.**
- [x] **INT-09** — **`verify_package_docs`**, **`first_hour`**, package READMEs, and **`.planning/`** Hex mirror callouts stay aligned with **`mix.exs` `@version`** on the branch under test. **Validated in Phase 61.**

### Validated v1.17 (opened 2026-04-23; shipped 2026-04-23)

Theme: **friction-led developer readiness** — triage before broad doc sweeps; **PROC-08** and **FIN-03** not in this milestone.

- [x] **FRG-01** — Ranked **integrator-facing friction inventory** committed under **`.planning/`** (path recorded in **`.planning/STATE.md`**) with **sources** (e.g. VERIFY lanes, adoption matrix, host README, CI verifiers, maintainer notes) and explicit **P0 / P1 / P2** + **defer** rows. **Validated in Phase 62.**
- [x] **FRG-02** — **North star + diminishing-returns stop rules** for **v1.17** documented and cross-linked from this **Current milestone** section (or **`STATE.md`**). **Validated in Phase 62.**
- [x] **FRG-03** — **Scoped implementation backlog** for Phases **63–65** authored from **FRG-01**: each row either maps to **INT-10** / **BIL-03** / **ADM-12** work **or** is deferred with written rationale (no hidden scope). **Validated in Phase 62.**
- [x] **INT-10** — **P0 integrator / VERIFY / docs closure** — For every **P0** backlog row tagged **integrator**, **VERIFY**, or **docs**, ship the fix (docs, verifiers, tests as needed) **or** downgrade to **P1+** with maintainer rationale in the inventory doc; **`bash scripts/ci/verify_package_docs.sh`** and merge-blocking **`host-integration`** / **VERIFY-01** contracts stay **green** on **`main`** after changes. **Validated in Phase 63.**
- [x] **BIL-03** — **P0 billing closure** — For every **P0** backlog row tagged **billing**, ship the bounded **`Accrue.Billing` / Stripe / Fake** work with regressions + **`guides/telemetry.md`** + **CHANGELOG** alignment **or** certify **no P0 billing rows** with signed rationale (no **PROC-08**). **Validated in Phase 64.**
- [x] **ADM-12** — **P0 admin / operator closure** — For every **P0** backlog row tagged **admin**, ship the scoped **LiveView** / **`AccrueAdmin.Copy`** / **VERIFY-01** work **or** certify **no P0 admin rows** with signed rationale. **Validated in Phase 65.**

### Validated v1.18 (archived in `.planning/milestones/v1.18-REQUIREMENTS.md`; milestone closed 2026-04-23)

Theme: **Onboarding confidence** — deferred **Phase 62** human UAT baseline + evaluator proof alignment; **PROC-08** and **FIN-03** not in this milestone.

- [x] **UAT-01..UAT-05** — Friction inventory / **STATE** / north-star / archive / **ROADMAP** consistency with **`66-VERIFICATION.md`** + **`verify_v1_17_friction_research_contract.sh`** where cited. **Validated in Phase 66.**
- [x] **PROOF-01** — Adoption proof matrix, evaluator walkthrough, **`verify_adoption_proof_matrix.sh`**, host README, and org matrix ExUnit stay aligned. **Validated in Phase 66.**

### Validated v1.21 (Phases 72–73 complete)

Theme: **maintenance posture** + **contributor capsule parity**; **PROC-08** and **FIN-03** not in this milestone.

- [x] **MAT-01** — **`.planning/PROJECT.md`** library maintenance posture (**FRG-01** intake, revisit triggers) with links to north star, friction inventory, **`production-readiness.md`**, **`maturity-and-maintenance.md`**. **Validated in Phase 72.**
- [x] **MAT-02** — **`accrue/guides/maturity-and-maintenance.md`** + cross-links from **First Hour**, **production-readiness**, **CONTRIBUTING**. **Validated in Phase 72.**
- [x] **INT-11** — **`scripts/ci/README.md`** same-PR checklist (**First Hour** H/M/R ↔ host README); **`v1.17-P2-001`** closed in friction inventory. **Validated in Phase 73.**

### Validated v1.23 (Phase 75; milestone closed 2026-04-24)

Theme: **post-publish contract alignment** (**PPX-01..04**); **PROC-08** and **FIN-03** not in this milestone. Archive: **`.planning/milestones/v1.23-REQUIREMENTS.md`**.

- [x] **PPX-01** — **`verify_package_docs.sh`** + **`package_docs_verifier_test.exs`** aligned with workspace **`@version`** at **0.3.1** after linked publish. **Validated in Phase 75.**
- [x] **PPX-02** — **`verify_adoption_proof_matrix.sh`** + adoption matrix needle discipline. **Validated in Phase 75.**
- [x] **PPX-03** — Merge-blocking **`docs-contracts-shift-left`** (including **`verify_production_readiness_discoverability.sh`**) green after doc/version touches. **Validated in Phase 75.**
- [x] **PPX-04** — **`.planning/`** public-Hex callouts + **`v1.17-P1-002`** closed with **75-VERIFICATION** pointer. **Validated in Phase 75.**

### Validated v1.24 (Phases 76–78; planning milestone complete 2026-04-24)

Theme: **billing portal facade + customer PM operator surfaces** (**ADM-13..16**, **BIL-04..05**). **PROC-08** / **FIN-03** not in this milestone.

- [x] **ADM-13, ADM-14** — Customer **`payment_methods`** tab inventory + **`AccrueAdmin.Copy`** burn-down. **Validated in Phase 76** (**`76-VERIFICATION.md`**).
- [x] **ADM-15** — Merge-blocking VERIFY-01 Playwright + **axe** for customer detail **`?tab=payment_methods`** (`examples/accrue_host`); matrix row in **`verify01-v112-admin-paths.md`**. **Validated in Phase 77** (**`77-VERIFICATION.md`**).
- [x] **ADM-16** — **`accrue_admin/guides/theme-exceptions.md`** Phase 77 reviewer note; **`mix accrue_admin.export_copy_strings`** SSOT for **`copy_strings.json`**; closure in **`milestones/v1.24-phases/77-customer-pm-tab-verify-theme-copy-export/77-VERIFICATION.md`**. **Validated in Phase 77**.
- [x] **BIL-04** — **`Accrue.Billing.create_billing_portal_session/2`** (+ **`!`**) with **`span_billing(:billing_portal, :create, …)`**, Fake-backed ExUnit. **Validated in Phase 78** (**`78-VERIFICATION.md`**).
- [x] **BIL-05** — **`guides/telemetry.md`**, **`operator-runbooks.md`**, **`CHANGELOG.md`** aligned with billing portal + payment-method span inventory. **Validated in Phase 78** (**`78-VERIFICATION.md`**).

### Validated v1.25 (archived in `.planning/milestones/v1.25-REQUIREMENTS.md`; milestone closed 2026-04-24)

- [x] **INV-03** — Maintainer pass path **(b)** on **`v1.17-FRICTION-INVENTORY.md`** with **`079-VERIFICATION.md`** verifier evidence. **Validated in Phase 79** (**`079-VERIFICATION.md`** under **`milestones/v1.25-phases/`**).
- [x] **BIL-06** — **`Accrue.Billing.create_checkout_session/2`** (+ **`!`**) with **`span_billing(:checkout_session, :create, …)`**, allowlisted checkout telemetry metadata, Fake-backed **`checkout_session_facade_test.exs`**. **Validated in Phase 80** (**`080-VERIFICATION.md`** under **`milestones/v1.25-phases/`**).
- [x] **BIL-07** — **`guides/telemetry.md`** + **`operator-runbooks.md`** checkout span catalog / triage pointer; **`CHANGELOG`**. **Validated in Phase 81** (**`081-VERIFICATION.md`** under **`milestones/v1.25-phases/`**).
- [x] **INT-12** — **First Hour**, **`examples/accrue_host` README**, adoption proof matrix + **`verify_package_docs.sh`** / **`verify_adoption_proof_matrix.sh`** needles for **`create_checkout_session`**. **Validated in Phase 81** (**`081-VERIFICATION.md`** under **`milestones/v1.25-phases/`**).

### Validated v1.27 (archived in `.planning/milestones/v1.27-REQUIREMENTS.md`; milestone closed 2026-04-24)

- [x] **CLS-01..03** — Pre-1.0 **closure narrative** on repo root **`README.md`**, **`accrue/README.md`**, **`RELEASING.md`**, **`accrue/guides/upgrade.md`**. **Validated in Phase 84** (**`084-VERIFICATION.md`** under **`milestones/v1.27-phases/`**).
- [x] **INV-05** — Post-**CLS** maintainer pass path **(b)** on **`v1.17-FRICTION-INVENTORY.md`** with **`085-VERIFICATION.md`** transcripts. **Validated in Phase 85** (**`085-VERIFICATION.md`** under **`milestones/v1.27-phases/`**).

### Validated v1.26 (archived in `.planning/milestones/v1.26-REQUIREMENTS.md`; milestone closed 2026-04-24)

- [x] **INT-13** — **`create_billing_portal_session`** on **First Hour** + host README + adoption matrix + merge-blocking verifier needles (telemetry anchor **`#billing-billing-portal-create`**). **Validated in Phase 82** (**`082-VERIFICATION.md`** under **`milestones/v1.26-phases/`**).
- [x] **INV-04** — Post-**INT-13** maintainer pass path **(b)** on **`v1.17-FRICTION-INVENTORY.md`** with **`083-VERIFICATION.md`** transcripts. **Validated in Phase 83** (**`083-VERIFICATION.md`** under **`milestones/v1.26-phases/`**).

### Validated v1.20 (Phases 70–71 complete)

- [x] **INV-01** — Post–**0.3.1** friction inventory pass: **`v1.17-P1-001`** closed in **`.planning/research/v1.17-FRICTION-INVENTORY.md`** with **v1.19** **PRF** evidence pointers. **Validated in Phase 70.**
- [x] **INV-02** — Dated maintainer note + **revisit trigger** when no new sourced **P0/P1** rows warranted. **Validated in Phase 70.**
- [x] **PRD-01** — **`accrue/guides/production-readiness.md`** checklist spine (links to existing guides only). **Validated in Phase 71.**
- [x] **PRD-02** — Cross-links from **First Hour**, **configuration**, and **`examples/accrue_host` README**. **Validated in Phase 71.**

### Validated v1.19 (Phases 67–69 complete)

- [x] **PRF-01** — Merge-blocking **`verify_adoption_proof_matrix.sh`** needles track **`adoption-proof-matrix.md`** Layer C script names (including **`verify_core_admin_invoice_verify_ids.sh`**) plus **ORG-05** / **ORG-06** taxonomy tokens alongside existing ORG-09 archetype needles (**addresses `v1.17-P1-001`**). **Validated in Phase 67.**
- [x] **PRF-02** — **`scripts/ci/README.md`** triage subsection documents matrix SSOT path, **`docs-contracts-shift-left`**, same-PR co-update rule for matrix + script + ExUnit literal harness (**`organization_billing_org09_matrix_test.exs`**), and a repo-relative matrix link. **Validated in Phase 67.**
- [x] **REL-01..REL-03** — **`RELEASING.md`** default merge + ordered Hex publish narrative; ship-boundary changelog expectations; **Hex + tag + changelog-at-tag** evidence in **`68-VERIFICATION.md`**. **Validated in Phase 68.**
- [x] **DOC-01..DOC-02** — **`first_hour`**, package README **`~>`** pins, **`verify_package_docs.sh`**, and **`package_docs_verifier_test.exs`** aligned with **`mix.exs` `@version`**; proof in **`69-VERIFICATION.md`**. **Validated in Phase 69.**
- [x] **HYG-01** — **`PROJECT.md`**, **`MILESTONES.md`**, and **`STATE.md`** public-Hex / **`0.3.1`** callouts consistent with shipped **`mix.exs`** pair. **Validated in Phase 69.**

### Validated v1.14 (Phases 54–56; milestone scope delivered 2026-04-23)

Theme: **core admin parity** + **one billing / Stripe read slice**; **PROC-08** and **FIN-03** not in this milestone.

- [x] **ADM-07..ADM-11** — Core admin inventory (**54**), money-primary burn-down (**54**), VERIFY-01 + theme exceptions + copy export hygiene on invoice flows (**55**). **Validated in Phases 54–55.**
- [x] **BIL-01, BIL-02** — `list_payment_methods` on **`Accrue.Billing`** with Fake coverage; telemetry guide + changelog + installer host stub + First Hour pointer (**56**). **Validated in Phase 56.**

### Validated v1.4 (archived here; milestone closed 2026-04-17)

- [x] **STAB-01** — Latest published `lattice_stripe` compatible with `~> 1.1` across monorepo lockfiles; gates green.
- [x] **UX-DEMO-01** — Visual walkthrough docs + optional `npm run e2e:visuals` for the Phase 15 trust Playwright path.

### Validated v1.3 (archived)

v1.3 Tax + Organization Billing shipped and validated on 2026-04-17. Outcomes: `.planning/milestones/v1.3-REQUIREMENTS.md`.

- ✓ TAX-01 through TAX-04 — Phases 18–19
- ✓ ORG-01 through ORG-03 — Phase 20
- ✓ VERIFY-01 — Phases 21–22 (executable proof + finance handoff narrative)
- ✓ FIN-01 and FIN-02 — Phase 22 (`accrue/guides/finance-handoff.md`)

### Validated v1.0 Scope Summary

**Core billing domain**
- [x] Polymorphic `Accrue.Billing.Customer` — any host schema (User, Org, Team) can be billable via `use Accrue.Billable`
- [x] `Accrue.Billing.Subscription` with full lifecycle (trials, proration, pause/resume, swap, cancel-at-period-end, immediate cancel, dunning, grace periods)
- [x] `Accrue.Billing.Invoice` with draft/open/paid/void/uncollectible state machine, line items, discounts, tax
- [x] `Accrue.Billing.Charge` / `PaymentIntent` / `SetupIntent` wrappers with async-state handling (requires_action, 3DS/SCA)
- [x] `Accrue.Billing.PaymentMethod` with default-management, fingerprinting
- [x] `Accrue.Billing.Refund` with Stripe fee awareness (gotcha #14)
- [x] `Accrue.Billing.Coupon` / `PromotionCode` / gift card redemption
- [x] Free-tier / trial / comped subscription support (no PaymentMethod required)
- [x] Multi-currency (including zero-decimal currency safety — JPY/KRW etc)
- [x] Subscription Schedules for multi-phase billing
- [x] Customer Portal Session + Checkout Session helpers
- [x] Stripe Connect (Standard/Express/Custom) support for marketplaces: destination charges, separate charges + transfers, platform onboarding

**Processor abstraction**
- [x] Stripe processor (via `lattice_stripe` dep)
- [x] Fake processor for test-first development (no Stripe API calls, test clock, time advancement, event triggering)
- [x] `Accrue.Processor` behaviour designed so future adapters (Paddle, Lemon Squeezy, Braintree) can implement it without false-parity abstraction over processor-specific capabilities

**Webhooks**
- [x] Raw-body capture Plug (mandatory before `Plug.Parsers`)
- [x] Signature verification
- [x] DB idempotency via `accrue_webhook_events` table with `UNIQUE(processor_event_id)`
- [x] Oban-backed async dispatch with exponential backoff retry, dead-letter after N attempts
- [x] User handler contract with pattern-matchable event types
- [x] Replay tooling (requeue failed / dead-lettered events)

**Event ledger**
- [x] Append-only `accrue_events` table, immutable at the Postgres role/trigger level
- [x] Transactional event recording alongside state mutations (atomicity guarantee)
- [x] `schema_version` inside `data` jsonb + upcaster pattern for evolution
- [x] OpenTelemetry `trace_id` correlation per event
- [x] Query API: timeline for subject, replay/rewind state as-of, analytics bucketing
- [x] Bridge to `Sigra.Audit` when sigra adapter is active

**Email**
- [x] Swoosh-based transactional email via `Accrue.Mailer` facade (behaviour-wrapped so library doesn't leak Swoosh to users)
- [x] Full email type set: receipt, payment_succeeded, payment_failed, trial_ending, trial_ended, invoice_finalized, invoice_paid, invoice_payment_failed, subscription_canceled, subscription_paused, subscription_resumed, refund_issued, coupon_applied, gift_sent, gift_redeemed
- [x] HEEx templates that work in plain-text AND HTML, rendering consistently across major email clients
- [x] Single-point branding config (logo, colors, from-name, from-address) for 80% case
- [x] Per-template override for full customization
- [x] MJML support via `mjml_eex` for responsive templates

**PDF**
- [x] `Accrue.PDF` behaviour with `Accrue.PDF.ChromicPDF` default adapter, `Accrue.PDF.Test` for assertion-based testing, documented path for custom adapters (Gotenberg sidecar, external services)
- [x] Branded invoice PDFs from the same HEEx template that drives the email HTML body (single source of truth)
- [x] Attachment and download paths for generated PDFs

**Admin UI (companion package `accrue_admin`)**
- [x] Phoenix LiveView dashboard: customers, subscriptions, invoices, charges, coupons, webhook events
- [x] Mobile-first responsive layout
- [x] Light + dark mode
- [x] Default theme follows Accrue brand palette (Ink / Slate / Fog / Paper foundation + Moss / Cobalt / Amber accents)
- [x] Branding customization (logo, accent color, app name) for internal-tool style
- [x] Webhook event inspector with raw payload, status, retry history, one-click replay, dead-letter bulk requeue
- [x] Activity feed sourced from `accrue_events`
- [x] Auth protection via `Accrue.Auth` adapter (Sigra-auto-wired when present)
- [x] Released same day as `accrue` v1.0, from the same monorepo

**Auth integration**
- [x] `Accrue.Auth` behaviour (current_user, require_admin_plug, user_schema, log_audit, actor_id)
- [x] `Accrue.Auth.Default` fallback adapter
- [x] `Accrue.Integrations.Sigra` first-party adapter, conditionally compiled, auto-detected by installer
- [x] Documented path for community adapters (`Accrue.Integrations.PhxGenAuth`, `.Pow`, `.Assent`)

**Install + DX**
- [x] `mix accrue.install` task that generates migrations, `MyApp.Billing` context, router mounts, admin LiveView routes; detects sigra and auto-wires auth; uses configurable billable schema
- [x] Discoverable, intuitive configuration with NimbleOptions-backed validation and doc generation
- [x] `Accrue.Billing` context facade hides lattice_stripe from the user-facing API

**Observability**
- [x] First-class `:telemetry` events with consistent `[:accrue, :domain, :action, :start|:stop|:exception]` naming
- [x] OpenTelemetry span helpers with business-meaningful attributes (customer_id, subscription_id, event_type, processor)
- [x] High-signal ops events for SRE/on-call (revenue-loss, webhook DLQ, dunning exhaustion) with low-signal firehose available separately
- [x] Structured, pattern-matchable error hierarchy (`Accrue.Error` → `Accrue.CardError`, `.RateLimitError`, etc.)

**Testing**
- [x] Fake Processor as the primary test surface — not an afterthought
- [x] Test helpers: time advancement, event triggering, state inspection, `assert_email_sent`, `assert_pdf_rendered`
- [x] Mock adapters for `Accrue.Auth`, `Accrue.Mailer`, `Accrue.PDF` so host apps can test billing flows without hitting Stripe / Chrome / real SMTP

**OSS hygiene and release**
- [x] Monorepo with sibling mix projects (`accrue/`, `accrue_admin/`), each published independently to Hex
- [x] GitHub Actions CI: Elixir/OTP matrix, `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`, `mix hex.audit`
- [x] Release Please + Conventional Commits for automated version bumps + CHANGELOG
- [x] ExDoc with guides: quickstart, configuration, testing, Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI setup, upgrade guide
- [x] MIT license, single-root `LICENSE` file, no CLA
- [x] `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md` for vulnerability disclosure
- [x] Semantic versioning with documented deprecation policy; minimize breaking changes through v1.x via stable public API facade

### Out of Scope

- **MVP / iterate-in-public release strategy** — user wants the first public release to be fully complete; no v0.1→v0.2→v0.3 cadence. Phases in this project are internal build milestones, not public releases.
- **Multi-provider at launch** — Stripe-only for v1.0. Processor behaviour is designed to support future adapters (Paddle, Lemon Squeezy, Braintree), but building those actual adapters is post-1.0. If existing Elixir libs exist for other processors they can be wrapped later; if not, those libraries will be built separately in future Jon-owned projects.
- **Multi-database support** — PostgreSQL 14+ only. MySQL and SQLite lose too many load-bearing features (jsonb/GIN, partial indexes, unique-where, advisory locks, exclusion constraints). Revisit only if real user demand emerges post-1.0, using Oban's multi-engine playbook.
- **Dual-license / commercial tier at launch** — MIT only for v1.0. Future commercial paths go through vertical integration (hosted service, compliance/tax bundling) rather than paid features in the core library.
- **Full CQRS/Event Sourcing via Commanded** — rejected in favor of append-only audit log pattern. Commanded is mature but wrong abstraction for billing, which Stripe itself models as mutable state + event notifications.
- **Accrue owning the auth user schema** — Accrue's polymorphic `owner_type`/`owner_id` references host-owned schemas (via sigra, phx.gen.auth, Pow, or other). Accrue never owns `users`.
- **First-party Paddle/Lemon Squeezy/Braintree adapters** — post-1.0.
- **Revenue recognition / GAAP accounting** — out of scope; Accrue is a billing/subscription library, not an accounting system. Users integrate downstream accounting tools themselves.
- **Tax calculation** — out of scope for v1.0; users can surface Stripe Tax through Accrue's existing APIs, but no first-party tax resolution/compliance support at launch.

## Context

**Ecosystem gap.** Elixir/Phoenix has no mature billing library in 2026. Bling is pre-1.0 with single-maintainer risk and depends on stripity_stripe pinned to a 2019 API. The Phoenix community has paid a real cost for this gap — Rails has Pay + Jumpstart, Laravel has Cashier + Spark, Django has dj-stripe. Accrue fills that niche with the benefit of those libraries' lessons learned.

**Lessons learned from prior art** (extracted from Pay/Cashier/dj-stripe research):
- *Pay v2→v3 migration pain* — moving from User-table columns to separate polymorphic tables broke many users. Accrue starts polymorphic from day one.
- *Cashier's separate-package decision* — shared multi-processor abstraction is a beautiful lie; Laravel explicitly split Stripe and Paddle into separate packages because generic abstraction failed. Accrue ships Stripe-first and resists false parity.
- *dj-stripe's JSON blob strategy* — after a decade, dj-stripe converged on storing full Stripe API responses in `data` columns rather than maintaining 1:1 column parity. Accrue adopts this from day one.
- *Webhook handling is the #1 value-add* — every ecosystem's users cite it as the highest-ROI feature a billing lib can provide. Accrue makes it a first-class citizen.
- *The Fake Processor is table stakes, not an edge case* — Pay's fake processor transforms the test story from "slow, flaky, expensive" to "fast, reliable, local". Accrue builds it on day one as the primary test surface.
- *Raw-body gotcha* — most web frameworks (Phoenix included) parse bodies before handler runs, destroying the raw bytes needed for webhook signature verification. This is the single most common webhook integration bug. Accrue provides the plug that solves it.

**Sibling projects** (same author: Jon):
- **`lattice_stripe`** (`/Users/jon/projects/lattice_stripe`, v0.2.0, Stripe API `2026-03-25.dahlia`) — thin Elixir wrapper over the Stripe SDK. Covers Tier 1–2 (payments, customers, payment methods, refunds, checkout, webhooks, errors, telemetry). Accrue depends on it directly. **Gap:** no Billing (Subscription/Product/Price/Invoice/Meter) coverage yet — Accrue will need lattice_stripe to add these, or build them upstream as lattice_stripe contributions. Also lacks v2 include support, Connect context helpers, and event type constants.
- **`sigra`** (`/Users/jon/projects/sigra`, v0.1.0) — authentication library for Phoenix 1.8+, "Devise with lessons learned." Hybrid lib + generator pattern (security-critical code in lib, schemas/contexts/routes generated into host). Local Sigra now ships logical multi-tenancy through organizations, memberships, invitations, active organization scope/session hydration, tenant-aware audit columns, org-aware admin, impersonation, and audit/export surfaces. Accrue's `Accrue.Integrations.Sigra` adapter plugs into it, and v1.3 should use Sigra-first examples while keeping generic host-owned billables supported.

**Brand** (from `prompts/accrue brand book.md`):
- Positioning: Elixir-native, framework-integrated, not a fintech. Calm, measured, technically precise.
- Tagline: *"Billing state, modeled clearly."*
- Palette: Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC foundation; Moss #5E9E84 primary; Cobalt #5D79F6 interactive; Amber #C8923B warnings/grace periods.
- Typography: neutral sans (Inter/Geist/IBM Plex Sans), JetBrains/IBM Plex Mono for code and event labels.
- Visual vocabulary: stacked lines, offset blocks, timelines, state diagrams. No coin/card/wallet clichés.
- Messaging pillars: native to Phoenix, billing as queryable app state (not black-box remote calls), webhooks without chaos, good open-source taste.

**Philosophy:**
- Idiomatic Elixir/OTP: pure functions at core, processes only for real state/concurrency, `{:ok, result} | {:error, exception}` returns with bang variants, behaviours for real extension points, protocols for data-type polymorphism, no macro abuse.
- Idiomatic Ecto: thin schemas, context functions as public API, explicit preloads, database-enforced integrity, `Ecto.Multi` for dynamic multi-step writes, `Repo.transact` for linear, schemas have `redact: true` on sensitive fields.
- Idiomatic Phoenix: business logic in `MyApp.Billing` context, web code in `MyAppWeb`, LiveView function components with `attr`/`slot`, `~p` verified routes, authz on action not just mount, Phoenix optional-not-required for headless core.
- OSS hygiene: small public API, layered façade, clear namespace (`Accrue.*`), runtime options over app env, first-class telemetry, exception hierarchy, ExDoc guides for every non-trivial topic.
- DDD-respecting: Accrue and its admin UI stay inside a `Billing` context so they don't pollute the host app's core domain(s). Same principle Sigra applies to authentication.

## Constraints

- **Tech stack**: Elixir 1.17+, OTP 27+, Phoenix 1.8+, Ecto 3.12+, PostgreSQL 14+. No legacy OTP support.
- **Dependencies (required)**: `lattice_stripe` (Stripe calls), `oban` (webhook async + email async + scheduled jobs), `swoosh` (email), `ecto_sql`, `postgrex`, `nimble_options` (config validation), `telemetry`, `chromic_pdf` (default PDF adapter — pullable via `accrue_admin` and core).
- **Dependencies (optional)**: `sigra` (`optional: true`), `phoenix_live_view` (hard dep in `accrue_admin`, not in core).
- **Release model**: ship complete. No public v0.x iteration cycle. Internal phases are build milestones, not public releases. First public release is v1.0 (or `0.1.0` if strict semver-pre-1 is preferred, but conceptually "complete").
- **Compatibility**: Phoenix 1.8+, LiveView 1.0+. No attempt at backward compatibility with Phoenix 1.7 or earlier.
- **Security**: Webhook signature verification mandatory and non-bypassable. Raw-body plug must run before `Plug.Parsers`. Sensitive Stripe fields never logged. Payment method details stored as Stripe references, never as PII.
- **Performance**: webhook request path <100ms p99 (verify → persist → enqueue → 200); async handler latency budget set by Oban queue config, user-configurable.
- **Observability**: all public entry points emit `:telemetry` start/stop/exception events. OTel span helpers available for every Billing context function.
- **Monorepo**: `accrue/` and `accrue_admin/` as sibling mix projects in one git repo. Shared `.github/workflows/`, shared `guides/`, per-package `mix.exs`, `CHANGELOG.md` per package.
- **License**: MIT for both packages.

## Key Decisions

| Decision | Rationale | Outcome |
|---|---|---|
| Stripe-only for v1.0 (processor behaviour designed for future adapters) | False multi-processor parity was Laravel Cashier's most-cited regret; lessons learned dominate breadth | ✓ Good |
| Polymorphic billable (`owner_type`/`owner_id`) + `use Accrue.Billable` macro | Pay v2→v3 migration pain; future sigra org support flows through with zero schema churn | ✓ Good |
| PostgreSQL 14+ only | 7 load-bearing PG features have no clean fallback; ~0% of serious Phoenix apps use MySQL/SQLite in production | ✓ Good |
| Hybrid lib + `mix accrue.install` generator | Matches sigra's pattern, upgrade-safe, best install DX; Phoenix community already knows this shape via phx.gen.auth | ✓ Good |
| Admin UI as companion `accrue_admin` package (monorepo, same-day release) | Core stays LiveView-free for headless users; `phoenix_live_dashboard` / `oban_web` pattern is idiomatic | ✓ Good |
| Swoosh (wrapped behind `Accrue.Mailer` facade) | Phoenix default since 1.6, larger adapter catalog, better test ergonomics, ecosystem alignment | ✓ Good |
| PDF via `Accrue.PDF` behaviour + `ChromicPDF` default | Seam pays for itself on the testing story alone (no Chrome in tests); escape hatch for Chrome-hostile deploys comes free | ✓ Good |
| Oban-backed async webhook dispatch (Oban required dep) | Retries survive deploys, DB idempotency at layer boundary, Oban is THE Elixir job standard, already needed for async email | ✓ Good |
| `Accrue.Auth` behaviour + `Accrue.Integrations.Sigra` adapter | Centralizes 15+ integration points to one dispatch, matches Plug/Ecto/Swoosh idiom, path for community adapters | ✓ Good |
| Append-only `accrue_events` table + Sigra.Audit bridge (NOT Commanded) | Matches Stripe's mental model (mutable state + events), ~150 LOC vs ~600+ for CQRS, transactional atomicity via Postgres | ✓ Good |
| MIT license, no CLA, single LICENSE file | Matches Elixir ecosystem norm; future commercial path via services not dual-license | ✓ Good |
| Context name `MyApp.Billing` | Industry-standard term, matches Stripe product naming, covers subs + one-time + refunds cleanly | ✓ Good |
| Build complete, ship v1.0 (no MVP-iterate cadence) | User explicit: won't have real users until fully usable; avoids Pay-style v2→v3 migration pain for early adopters | ✓ Good |
| Dogfood through a real Phoenix host app before broader adoption work | Real install, auth, webhook, admin, and clean-checkout paths exposed integration gaps that package-local tests could not catch | ✓ Good |
| Make Fake-backed host browser flow mandatory and live Stripe advisory | Deterministic CI should block regressions while live Stripe remains useful but non-deterministic | ✓ Good |
| Move host UI reads through generated `MyApp.Billing` facade | First-user docs should teach host-owned public boundaries, not private Accrue table queries | ✓ Good |
| Treat adoption, quality, and expansion as next-milestone candidates after stabilization | The v1.1 audit validated HOST/CI/DX scope; remaining ADOPT/QUAL/DISC ideas need fresh prioritization instead of automatic carryover | ✓ Good |
| v1.2 focuses on Adoption + Trust before large feature expansion | The biggest remaining gap is confidence for new users evaluating a billing library, not another core billing primitive; polish should stop once it hits diminishing returns and expansion should be decided deliberately | ✓ Good |
| Keep v1.2 expansion to discovery only | Tax, revenue exports, processors, and org billing are likely next-level features, but partial implementation would distract from onboarding and trust hardening | ✓ Good |
| Record the Phase 16 ranking as recommendation-only planning guidance | `Stripe Tax support` is the recommended `Next milestone`; `Organization / multi-tenant billing` and `Revenue recognition / exports` remain `Backlog`; `Official second processor adapter` remains a `Planted seed`, and no v1.2 billing API, schema, or processor-abstraction implementation is implied | ✓ Good |
| v1.3 combines Stripe Tax with Sigra-first organization billing and finance handoff | Stripe Tax is still the safest first expansion; Sigra org support is now concrete enough for host-proofed org billing; finance should stay Stripe-native before Accrue owns accounting semantics | ✓ Good |
| v1.6 closes admin UX polish without new billing primitives | Operator trust (a11y, mobile, copy) advances adoption without PROC-08/FIN-03 scope creep | ✓ Good |
| Post-ship Phases 30–31 close audit corpus + advisory integration without Hex release churn | Keeps evaluator-facing proof contracts aligned while preserving existing `v1.6` tag semantics | ✓ Good |
| v1.7 combines adoption/DX with operator admin depth without billing primitive expansion | After v1.6 polish, the highest leverage is clearer VERIFY-01 + install/docs matrices plus intentional admin entry flows—not PROC/FIN/ORG scope creep | ✓ Good |
| v1.8 delivers ORG-04 after Sigra-first org proof | Non-Sigra teams need first-class recipes and proof that **ORG-03** boundaries hold; scope stays docs + host patterns + VERIFY alignment—no PROC-08/FIN-03 | ✓ Good |
| v1.9 prioritizes observability + runbooks before meter milestone | Post–v1.8 plan: telemetry discoverability and ops runbooks maximize adoption ROI; metered billing (v1.10+) follows with Fake parity | ✓ Good |
| v1.10 delivers metered usage with Fake parity before second processor | Usage reporting, outbox, reconciler, and webhook error paths must be **host-testable** on Fake with stable telemetry keys; PROC-08 stays out of scope | ✓ Good |
| v1.11 ships Hex before the next feature milestone | Evaluators and hosts need published packages that include metering + accumulated work; release automation and doc verifiers must stay aligned with linked-versions monorepo reality | ✓ Good |
| v1.12 extends companion admin without billing-primitive expansion | Operators need post-metering admin clarity and smoother drills on Hex **0.3.0**; scope stays presentation + gates—not **PROC-08** / **FIN-03** | ✓ Good |
| v1.13 pairs integrator golden-path docs with auxiliary admin parity | First-time hosts still judge the library on README ↔ first_hour ↔ VERIFY-01 coherence; secondary LiveViews must not feel “unshipped” next to customers/subscriptions/invoices | ✓ Good |
| v1.14 sequences core admin parity before integrator/Hex milestones | After auxiliary parity (v1.13), **core** money flows should meet the same Copy/token/VERIFY bar; one billing depth slice ships with Fake + telemetry truth before doc/release milestones return | ✓ Good — **shipped** Phases **54–56** (**2026-04-23**); tag **`v1.14`** |
| v1.15 prioritizes release/trust semantics (forcing function **B**) over feature expansion | Pre-1.0 Hex + internal `v1.x` planning labels risk evaluator confusion; fix with docs + demo README clarity before further polish milestones | ✓ Good — **shipped** Phases **57–58** (**2026-04-23**); archived + planning tag **`v1.15`** |
| v1.16 closes integrator/proof continuity deferred from v1.14–v1.15 | Trust SemVer messaging and v1.13 INT baseline can drift; explicit milestone re-binds golden path, matrix, root VERIFY hops, and package-doc SSOT without billing scope creep | ✓ Good — **shipped** Phases **59–61** (**2026-04-23**); archived + planning tag **`v1.16`** |
| v1.17 uses friction triage before broad doc sweeps | After v1.16 continuity, ranked **FRG-01** evidence + **FRG-03** backlog prevents silent scope expansion; **BIL-03**/**ADM-12** allow signed empty-queue certification | ✓ Good — **shipped** Phases **62–65** (**2026-04-23**); archived + planning tag **`v1.17`** |
| v1.18 closes deferred **62-UAT** confidence with a verification ledger + contracts | Proof-first slice: **REQUIREMENTS** normative over historical **`62-UAT`** body; thin bash/ExUnit for binary invariants; **PROOF-01** keeps matrix ↔ script ↔ README honest | ✓ Good — **shipped** Phase **66** (**2026-04-23**); archived + planning tag **`v1.18`** |
| v1.19 sequences proof-contract hardening before **0.3.1** Hex publish | Workspace **`@version`** already **0.3.1** while public Hex lags **0.3.0**; **PRF-** work closes **v1.17-P1-001** drift class before release train; **HYG** mirrors follow ship | ✓ Good — **shipped** Phases **67–69** (**2026-04-24**); archived + planning tag **`v1.19`** |
| v1.20 closes friction evidence loop + production readiness spine without billing scope | Post–**0.3.1** inventory pass (**INV-**) + **`production-readiness.md`** integrator cross-links (**PRD-**); **PROC-08** / **FIN-03** unchanged | ✓ Good — **shipped** Phases **70–71** (**2026-04-24**); archived + planning tag **`v1.20`** |
| v1.21 codifies maintenance posture + capsule parity without billing scope | **MAT-** docs + **INT-11** checklist close **v1.17-P2-001**; evidence-gated friction intake explicit for maintainers | ✓ Good — **shipped** Phases **72–73** (**2026-04-23**); archived + planning tag **`v1.21`** |
| v1.22 makes production-readiness discoverability merge-blocking | After maintenance posture, root + package README still hid the ship checklist; **PRS-** ties evaluator path to **§1–§10** spine without billing primitive expansion | ✓ Good — **shipped** Phase **74** (**2026-04-24**); archived + planning tag **`v1.22`** |
| v1.23 re-verifies publish-adjacent contracts at **0.3.1** | After **v1.19** publish + **v1.22** discoverability, **PPX-** closes **v1.17-P1-002** with full **`docs-contracts-shift-left`** + friction-inventory alignment | ✓ Good — **shipped** Phase **75** (**2026-04-24**); archived + planning tag **`v1.23`** |
| v1.24 ships **billing portal** facade on **`Accrue.Billing`** + **customer PM** admin parity | After **v1.23** contract pass, bounded **BIL-04..05** + **ADM-13..16** close operator trust on portal entry + **payment_methods** without **PROC-08** / **FIN-03** | ✓ Good — **shipped** Phases **76–78** (**2026-04-24**); archived + planning tag **`v1.24`** |
| v1.25 sequences **friction maintainer pass** + **integrator contracts** + **checkout on `Accrue.Billing`** | After **v1.24**, keep **FRG-01** honest, **PPX-adjacent** proof/docs aligned, and mirror **BIL-04** facade patterns for **Stripe Checkout** via **`Accrue.Checkout.Session`** — still **no** **PROC-08** / **FIN-03** | ✓ Good — **shipped** Phases **79–81** (**2026-04-24**); **`milestones/v1.25-*`** + **`v1.25-phases/`**; tag **`v1.25`** |
| v1.26 extends **INT-12** class proof to **billing portal** on golden-path surfaces | After **v1.25** checkout spine, **INT-13** + **INV-04** keep **First Hour** / matrix / friction SSOT honest without new **`Accrue.Billing`** APIs | ✓ Good — **shipped** Phases **82–83** (**2026-04-24**); **`milestones/v1.26-*`** + **`v1.26-phases/`**; tag **`v1.26`** |
| v1.27 states **pre-1.0 closure** posture on integrator + release docs and re-certifies friction inventory | After **v1.26**, **CLS-** narrative + **INV-05** dated pass keep **FRG-02** / **S5** honest without **PROC-08** / **FIN-03** | ✓ Good — **shipped** Phases **84–85** (**2026-04-24**); **`milestones/v1.27-*`** + **`v1.27-phases/`**; tag **`v1.27`** |
| v1.28 sequences **next linked publish** contracts + **INV-06** inventory pass | After **v1.27**, spine **B** — event-driven **PPX-05..08** on registry bump + **INV-06** per inventory triggers — avoids speculative milestones without publish forcing function | ✓ Good — **planning complete** Phases **86–87** (**2026-04-24**); **`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**; **`REQUIREMENTS.md`** |

## Current Milestone Notes

- **2026-04-24:** **`/gsd-new-milestone` (plan implementation)** — **v1.28** **Next linked publish continuity** (strategic **spine B**); **`REQUIREMENTS.md`** (**PPX-05..08**, **INV-06**); roadmap Phases **86–87**; domain research **skipped** (brownfield **v1.23** pattern).
- **2026-04-24:** **`/gsd-new-milestone` (closure)** — **v1.27** **Pre-1.0 closure narrative**; **`REQUIREMENTS.md`** (**CLS-01..03**, **INV-05**); roadmap Phases **84–85**; domain research **skipped** (maintainer narrative + inventory pass).
- **2026-04-24:** **`/gsd-complete-milestone` v1.27** — archives **`milestones/v1.27-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.27`**; **`audit-open`** all clear (**no** **`v1.27-MILESTONE-AUDIT.md`**); **ROADMAP** v1.27 `<details>` updated to archived requirements links.
- **2026-04-24:** **`/gsd-complete-milestone` v1.26** — archives **`milestones/v1.26-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.26`**; **`audit-open`** all clear; **ROADMAP** v1.26 `<details>` updated to archived requirements links.
- **2026-04-24:** **`/gsd-complete-milestone` v1.25** — archives **`milestones/v1.25-*`**, **`git mv`** Phases **79–81** → **`milestones/v1.25-phases/`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.25`**; **`audit-open`** all clear; **`081-01-SUMMARY.md`** backfilled.
- **2026-04-24:** **`/gsd-new-milestone` v1.25** — **Evidence-bound triad**; domain research completed under **`.planning/research/`** before **`REQUIREMENTS.md`** / **`ROADMAP.md`**; **`v1.24`** phase trees live under **`milestones/v1.24-phases/`**.
- **2026-04-24:** **`/gsd-execute-phase 79`** — **INV-03** path **(b)**; **`### v1.25 INV-03 maintainer pass (2026-04-24)`** in **`v1.17-FRICTION-INVENTORY.md`** + **`079-VERIFICATION.md`**.
- **2026-04-24:** **`/gsd-complete-milestone` v1.24** — archives **`milestones/v1.24-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.24`** (**no** standalone **`v1.24-MILESTONE-AUDIT.md`**; **`audit-open`** clear).
- **2026-04-24:** **`/gsd-complete-milestone` v1.23** — archives **`milestones/v1.23-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.23`**.
- **2026-04-24:** **`/gsd-complete-milestone` v1.22** — archives **`milestones/v1.22-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.22`**.
- **2026-04-23:** **`/gsd-new-milestone` v1.22** — **Production path discoverability**; **`REQUIREMENTS.md`** (**PRS-01..03**); **`verify_production_readiness_discoverability.sh`** + **`docs-contracts-shift-left`**; roadmap Phase **74**.
- **2026-04-23:** **`/gsd-complete-milestone` v1.21** — archives **`milestones/v1.21-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.21`**.
- **2026-04-24:** **`/gsd-complete-milestone` v1.20** — archives **`milestones/v1.20-*`**, **`git mv`** Phases **70–71** → **`milestones/v1.20-phases/`**, **`git rm` `.planning/REQUIREMENTS.md`** for next milestone, planning tag **`v1.20`**.
- **2026-04-23:** **`/gsd-new-milestone` v1.19** — **Release continuity + proof resilience**; **`REQUIREMENTS.md`** (**PRF-01..02**, **REL-01..03**, **DOC-01..02**, **HYG-01**); roadmap Phases **67–69** (proof → Hex **0.3.1** → mirrors); **v1.18** Phase **66** execution tree moved to **`.planning/milestones/v1.18-phases/`** (durable path after **`phases.clear`**).
- Phase 17 verified that v1.2 has no remaining requirement, integration, flow, or cleanup gaps before milestone archival.
- Phase 16 recorded a recommendation, not a feature delivery: `Stripe Tax support` is the recommended next implementation milestone because it deepens the current Stripe-first path without promising any v1.2 schema, API, or processor changes.
- `Organization / multi-tenant billing` remains a recommendation-only backlog candidate until host-owned org semantics, row-scoped tenancy checks, and `cross-tenant billing leakage` protections are explicit.
- `Revenue recognition / exports` remains a recommendation-only backlog candidate until host-authorized export audiences, storage, and delivery rules are explicit, preserving the `wrong-audience finance exports` boundary.
- `Official second processor adapter` remains a recommendation-only planted seed because Accrue is still Stripe-first and host-owned, and future work must avoid a `processor-boundary downgrade`.
- Any future tax milestone must preserve `tax rollout correctness` by requiring `customer location` capture plus `legacy recurring-item migration` planning before maintainers schedule implementation.
- v1.3 planning resolves the Phase 16 backlog tradeoff by implementing Stripe Tax and Sigra-first org billing together, while keeping finance work to Stripe Revenue Recognition, Sigma, and Data Pipeline handoff documentation.
- Phase 18 validated the first Stripe Tax slice: public subscription and checkout tax enablement, Stripe/Fake adapter parity, and narrow local automatic-tax observability.
- Phase 19 validated tax-location capture/update, immediate invalid-location error handling, recurring tax-risk projection/admin visibility, host repair flow, and legacy recurring-item rollout safety guidance.
- v1.6 (Phases 25–29) archived 2026-04-20: admin inventory, visual hierarchy, microcopy registry, a11y gates, and mobile CI without PROC-08/FIN-03/product-schema changes.
- v1.6 planning line closed 2026-04-21: Phases **30–31** remediated milestone audit gaps (verification corpus, SUMMARY traceability) and advisory VERIFY-01 / Copy / Playwright integration notes; audit status **passed** in `milestones/v1.6-MILESTONE-AUDIT.md`.
- v1.7 opened 2026-04-21: **ADOPT** + **OPS** requirements and **Phases 32–36** roadmap; research summarized in `.planning/research/SUMMARY.md`.
- v1.7 archived 2026-04-21: requirements + roadmap + milestone audit under `.planning/milestones/v1.7-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.7`**.
- v1.8 opened 2026-04-21: **ORG-04** (non-Sigra org billing recipes + host integration depth); phases **37+**; **PROC-08** and **FIN-03** remain deferred.
- v1.8 closed 2026-04-22: Phases **37–39** complete; **ORG-05..ORG-09** validated; adoption matrix + `verify_adoption_proof_matrix.sh` + `scripts/ci/README.md` ORG gates shipped; milestone archived under `.planning/milestones/v1.8-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.8`**.
- v1.9 opened 2026-04-21: **Observability & operator runbooks** after post–v1.8 prioritization; phases **40–42**; **PROC-08** / **FIN-03** unchanged as non-goals.
- v1.9 archived 2026-04-22: Phases **40–42** complete; **OBS/RUN/TEL** requirements validated; `.planning/milestones/v1.9-*`; root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.9`**.
- v1.10 opened 2026-04-21: **Metered usage + Fake parity**; phases **43–45**; requirements **MTR-01..MTR-08**; `phases.clear` skipped to preserve **40–42** phase trees.
- Phase **45** closed **2026-04-22**: docs + telemetry/runbook alignment (**MTR-07**, **MTR-08**) — metering guide, telemetry semantics anchor, runbook branches, optional testing/README cross-links.
- **2026-04-22:** `.planning/REQUIREMENTS.md` **MTR-01..MTR-06** checkboxes + traceability table aligned to **Phase 43** / **44** passed verification (was still “Pending” after Phase 45 close).
- **2026-04-22:** **v1.10** milestone archived (`milestones/v1.10-*`); root `REQUIREMENTS.md` removed for next milestone; git tag **`v1.10`**.
- **2026-04-22:** **v1.11** opened — **Hex release + post-release continuity**; Phases **46–47**; requirements **REL-01..REL-04**, **DOC-01..DOC-02**, **HYG-01**.
- **2026-04-22:** **v1.11** archived (`milestones/v1.11-*`); root **`.planning/REQUIREMENTS.md`** removed for next milestone; planning git tag **`v1.11`**.
- **2026-04-22:** **v1.12** opened — **Admin & operator UX**; Phases **48–50**; requirements **ADM-01..ADM-06**; **`phases.clear`** skipped (preserve **40–47** phase trees).
- **2026-04-22:** **v1.12** closed — Phases **48–50** complete; **ADM-01..ADM-06** validated; VERIFY-01 copy export + subscriptions axe coverage shipped in **Phase 50**.
- **2026-04-22:** **v1.12** milestone archived (`milestones/v1.12-*`); root **`.planning/REQUIREMENTS.md`** removed for next milestone; planning git tag **`v1.12`**.
- **2026-04-22:** **v1.13** opened — **Integrator path + secondary admin parity**; Phases **51–53**; requirements **INT-01..INT-05**, **AUX-01..AUX-06**; **`phases.clear`** skipped (preserve **1–50** phase trees).
- **2026-04-23:** **v1.13** milestone archived (`milestones/v1.13-*`); root **`.planning/REQUIREMENTS.md`** removed for next milestone; planning git tag **`v1.13`**.
- **2026-04-22:** **`/gsd-new-milestone`** — **v1.14** opened (**Companion admin + billing depth**); Phases **54–56**; requirements **ADM-07..ADM-11**, **BIL-01..BIL-02**; domain research skipped (brownfield); **`phases.clear`** skipped (preserve **1–53** trees).
- **2026-04-23:** **`/gsd-execute-phase 56`** — **BIL-01** / **BIL-02** delivered (`list_payment_methods`, docs, installer template); v1.14 requirement checklist complete in **`.planning/REQUIREMENTS.md`**.
- **2026-04-23:** **`/gsd-complete-milestone` v1.14** — archives **`milestones/v1.14-*`**, root **`REQUIREMENTS.md`** removed for next milestone, planning tag **`v1.14`**.
- **2026-04-23:** **v1.15** opened — **Release / trust semantics**; forcing function **B** (adoption readiness plan); **`.planning/REQUIREMENTS.md`** recreated (**TRT-01..TRT-04**); roadmap phases **57–58**.
- **2026-04-23:** **`/gsd-complete-milestone` v1.15** — archives **`milestones/v1.15-*`**, **`git rm .planning/REQUIREMENTS.md`**, planning tag **`v1.15`**.
- **2026-04-23:** **`/gsd-new-milestone`** — **v1.16** opened (**Integrator + proof continuity**); **`REQUIREMENTS.md`** (**INT-06..INT-09**); roadmap phases **59–61**.
- **2026-04-23:** **`/gsd-complete-milestone` v1.16** — archives **`milestones/v1.16-*`**, root **`REQUIREMENTS.md`** removed for next milestone, planning tag **`v1.16`**.
- **2026-04-23:** **`/gsd-new-milestone`** — **v1.17** opened (**Friction-led developer readiness**); **`REQUIREMENTS.md`** (**FRG-01..FRG-03**, **INT-10**, **BIL-03**, **ADM-12**); roadmap phases **62–65**; **`phases.clear`** executed (**43** trees).
- **2026-04-23:** **`/gsd-execute-phase 65`** — **`65-VERIFICATION.md`**, inventory **ADM-12** maintainer line, **`REQUIREMENTS.md`** **ADM-12** complete; **v1.17** milestone requirements satisfied.
- **2026-04-23:** **`/gsd-complete-milestone`** (**v1.17**) — archives **`milestones/v1.17-*`**, root **`REQUIREMENTS.md`** removed for next milestone, **`audit-open`** Phase **62** UAT gap acknowledged in **`STATE.md`**, planning tag **`v1.17`**.
- **2026-04-23:** **`/gsd-new-milestone` (trajectory plan)** — **v1.18** opened (**Onboarding confidence**, proof-first); **`REQUIREMENTS.md`** (**UAT-01..UAT-05**, **PROOF-01**); roadmap Phase **66**; **v1.17** phase trees archived under **`milestones/v1.17-phases/`**; **`.planning/phases/`** cleared for new work.
- **2026-04-23:** **`/gsd-complete-milestone` v1.18** — **`66-01..03-SUMMARY.md`** backfilled; archives **`milestones/v1.18-*`**; **`git rm` `.planning/REQUIREMENTS.md`** for fresh next milestone; planning tag **`v1.18`**.
- **2026-04-24:** **`/gsd-discuss-phase 69`** — Subagent-backed **D-01..D-04** locked in **`69-CONTEXT.md`** (HYG vs DOC boundary, planning file SSOT roles, bash-first verifier coupling, pin-first capsules).
- **2026-04-24:** **`/gsd-execute-phase 69`** — **`69-VERIFICATION.md`** (**DOC** + **HYG**); **`REQUIREMENTS.md`** **DOC-01..02** / **HYG-01** **Complete**; **`PROJECT`**, **`MILESTONES`**, **`STATE`** Hex **0.3.1** mirror pass.
- **2026-04-24:** **`/gsd-complete-milestone` v1.19** — archives **`milestones/v1.19-*`**, **`git rm` `.planning/REQUIREMENTS.md`** for fresh next milestone, planning tag **`v1.19`** (**`gsd-sdk query milestone.complete`** still blocked on phases-archive; manual archives).
- **2026-04-24:** **`/gsd-new-milestone` v1.26** — **First-hour billing facade spine**; **`REQUIREMENTS.md`** (**INT-13**, **INV-04**); roadmap Phases **82–83**; domain research **skipped** (integrator parity with v1.24–v1.25 patterns).
- **2026-04-24:** **`v1.20` bootstrap** — **`/gsd-new-milestone` plan implementation** (**A** + **B**): **`v1.17-P1-001`** closed in friction inventory; **`production-readiness.md`** + cross-links; **`REQUIREMENTS.md`** (**INV-01..02**, **PRD-01..02**); Phases **70–71** verification; **v1.19** execution trees moved to **`.planning/milestones/v1.19-phases/`**.
- **2026-04-23:** **`/gsd-new-milestone`** — **v1.21** opened and Phases **72–73** verified (**Maturity posture and diminishing returns**); **`REQUIREMENTS.md`** (**MAT-01..MAT-02**, **INT-11**); **`maturity-and-maintenance.md`** + **PROJECT** maintenance bar + **`scripts/ci/README.md`** capsule checklist (**v1.17-P2-001** closure); commit **`docs: open v1.21 maturity posture (MAT-01..02, INT-11)`**.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-24 — **v1.28** Phases **86–87** complete (**`086-VERIFICATION.md`**, **`087-VERIFICATION.md`**, **PPX-05..08** + **INV-06**); **v1.27** archived + tagged (**CLS-01..03**, **INV-05**).*
