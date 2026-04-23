# Phase 66: Deferred UAT + evaluator proof - Context

> **Archive path (2026-04-23):** This directory was moved from **`.planning/phases/66-onboarding-confidence/`** to **`.planning/milestones/v1.18-phases/66-onboarding-confidence/`** when **v1.19** opened, so **`phases.clear`** does not delete shipped verification history. **D-01a** below references the pre-move canonical path.

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close deferred **Phase 62** human UAT confidence gaps (**UAT-01..UAT-05**) with explicit **pass / automated / maintainer-signed** outcomes, ship **`66-VERIFICATION.md`** as the proof ledger, and run a **bounded** adoption proof alignment (**PROOF-01**) so matrix, walkthrough, merge-blocking verifiers, and README pointers stay honest. **No** new billing primitives; **no** **PROC-08** / **FIN-03**.

**Execution note:** Canonical phase artifacts live under **`.planning/phases/66-onboarding-confidence/`** (matches **`.planning/ROADMAP.md`** success criteria and milestone name **“Onboarding confidence”**). If GSD `init.phase-op` emits slug `deferred-uat-evaluator-proof`, treat that as tooling noise—**do not** create a second tree; keep one string on disk and in ROADMAP.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Phase directory + path SSOT (research: OSS layout, link rot, Phoenix/Oban patterns)

- **D-01a:** **Canonical directory:** `.planning/phases/66-onboarding-confidence/` for **`66-CONTEXT.md`**, **`66-VERIFICATION.md`**, plans, and related phase files.
- **D-01b:** **Reject** dual directories and **reject** git symlinks for phase aliases—Windows/CI/checkout footguns and split edits.
- **D-01c:** **Contributor-facing SSOT** remains **`guides/`**, package **`README`**, **`CHANGELOG`**, and **`.github/`**; **`.planning/`** is maintainer execution. Do not ask evaluators to reconcile two phase folder names.
- **D-01d:** If tooling defaults to a different slug, **align tooling or ROADMAP once** so glob/link checks have a single target—never maintain parallel paths.

### D-02 — UAT evidence: maintainer sign-off vs automation (research: Accrue verify_* + ExUnit mirrors, Pay/Cashier/Stripe/K8s)

- **D-02a:** **Default for UAT-01..UAT-05:** **Maintainer-signed rows** in **`66-VERIFICATION.md`** with **durable links** (paths, anchors) and short evidence notes—**do not** snapshot full planning prose in tests.
- **D-02b:** **Add automation only** when an invariant is **binary and stable** or **already regressed once**: e.g. existence of **`.planning/milestones/v1.17-REQUIREMENTS.md`**, **STATE** pointer to **`v1.17-FRICTION-INVENTORY.md`**, ROADMAP anchors resolving. Prefer **one `scripts/ci/verify_*.sh`** (CI + local) with optional **ExUnit wrapper** mirroring existing **`package_docs_verifier_test.exs`** / friction-contract pattern—**not** essay-level golden files.
- **D-02c:** **Wrong automation:** full-text snapshots of north-star prose or marketing copy—high churn, low signal.
- **D-02d:** **Right automation:** thin contracts on filenames, required substrings, and alignment with merge-blocking scripts already in **`docs-contracts-shift-left`**.

### D-03 — `62-UAT.md` vs **`REQUIREMENTS.md`** (research: ADR immutability, errata, audit trails)

- **D-03a:** **Normative exit criteria for v1.18** = **`.planning/REQUIREMENTS.md`** only. Evidence = **`66-VERIFICATION.md`** (+ cited CI/commands).
- **D-03b:** **`.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md`** stays a **historical Phase 62 scenario**—**do not rewrite** the body to match v1.18 (preserves “what Phase 62 meant”).
- **D-03c:** **Execute:** add a **short dated banner** at the top of **`62-UAT.md`** stating that **UAT-01..UAT-05** for v1.18 are defined in **`REQUIREMENTS.md`**, and that **test 4** here described **v1.17** FRG traceability against the *then-current* requirements file—**superseded for v1.18 by UAT-04** (link **`.planning/milestones/v1.17-REQUIREMENTS.md`** + current **UAT-04** wording). Optional one-line echo of supersession in **`66-VERIFICATION.md`** UAT-04 row.
- **D-03d:** Prefer **errata/additive** notices over silent edits—matches ADR/changelog norms and avoids audit confusion.

### D-04 — **`66-VERIFICATION.md` shape** (research: minimal vs verbose, Rust/CNCF/GitLab evidence, v1.17 phase style)

- **D-04a:** Use the **v1.17 archived verification spine**: YAML frontmatter + **short scope** + **one matrix**—avoid **`01-VERIFICATION`**-scale prose unless a row truly cannot be automated.
- **D-04b:** **Matrix columns:** **Row ID** (must match **REQUIREMENTS** `UAT-*` / `PROOF-*`); **Acceptance one-liner** (must match linked SSOT, no contradiction); **Merge-blocking proof** (`bash …` / `mix …` semicolon-separated, **same commands CI runs**); **Automation** (`CI (workflow: …; jobs: …)` or `CI + manual`—prefer **job/workflow names** over ephemeral URLs); **Evidence pointer** (test module / script / guide anchor—recommended); **Closure** (`closed` / `deferred` + pointer).
- **D-04c:** **Optional § Spot-checks / deviations** — bullets **only** for rows where CI is incomplete or intentionally manual; omit if empty.
- **D-04d:** **Do not invent new requirement IDs** in verification—only **UAT-01..05**, **PROOF-01**.

### D-05 — **PROOF-01** depth (research: matrix-first per `scripts/ci/README`, OpenAPI/GraphQL drift lessons)

- **D-05a:** **Depth:** **Bounded alignment + one semantic pass**—not exhaustive needle-by-needle inventory of every matrix row vs every test file.
- **D-05b:** **SSOT:** **`adoption-proof-matrix.md`** is authoritative human/evaluator contract; **`verify_adoption_proof_matrix.sh`** is the **regression harness**—on failure, **fix matrix first**, then needles only for **intentional taxonomy edits** (existing triage doctrine).
- **D-05c:** **Definition of done:** (1) Local or CI-equivalent run of **shift-left** scripts including **`verify_adoption_proof_matrix.sh`**; (2) **Single sitting** read of **matrix + evaluator walkthrough + host README** adoption section—resolve **merge-blocking vs advisory** contradictions and command naming; (3) any taxonomy/literal change ships **matrix + script** in **one change set** (and **ExUnit** matrix literals if applicable per **INT-07**); (4) **`66-VERIFICATION.md`** records commands and/or **stable CI job/workflow identifiers** + one-line “reviewed together” statement.
- **D-05d:** **Optional DX sugar:** short **taxonomy map** bullets (e.g. ORG-09 vs ORG-07/08 lanes) in matrix header or verification spot-check—only if evaluators still confuse lanes after the semantic read.

### Cohesion note (cross-decision)

All five decisions reinforce **one filesystem path**, **REQUIREMENTS as law**, **historical artifacts immutable with banners**, **thin mechanical proof**, **matrix-first adoption proof**, and **evaluator-trustworthy CI commands**—aligned with **proof-first onboarding confidence** and **least surprise** for Elixir/OSS contributors.

### Claude's Discretion

- Exact wording of **`62-UAT.md`** banner (tone/length).
- Whether any **new** thin verifier script is worth the merge cost for **UAT-02**/**UAT-04** vs signed rows only—**bias: add script only if a row would rot without it** (per **D-02b**).
- Optional **taxonomy map** placement (**D-05d**).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone obligations

- `.planning/REQUIREMENTS.md` — **UAT-01..UAT-05**, **PROOF-01** exit criteria (normative for v1.18)
- `.planning/ROADMAP.md` — Phase **66** goals, success criteria, milestone boundary
- `.planning/PROJECT.md` — Core value, **v1.18** intent, **PROC-08** / **FIN-03** non-goals
- `.planning/STATE.md` — Pointers, deferred UAT table, session resume

### Archived v1.17 baseline (UAT source material)

- `.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-UAT.md` — Historical human scenarios **1–5** (read with **D-03** banner discipline)
- `.planning/milestones/v1.17-REQUIREMENTS.md` — Shipped **v1.17** obligation record (**UAT-04** archive target)
- `.planning/research/v1.17-FRICTION-INVENTORY.md` — **UAT-01** / **UAT-05** evidence + P0 semantics
- `.planning/research/v1.17-north-star.md` — **UAT-03** S1–S5 stop rules

### PROOF-01 — Adoption proof + verifiers

- `examples/accrue_host/docs/adoption-proof-matrix.md` — Evaluator-facing proof SSOT
- `examples/accrue_host/docs/evaluator-walkthrough-script.md` — Walkthrough checklist
- `examples/accrue_host/README.md` — Links into matrix/walkthrough / VERIFY hops
- `scripts/ci/verify_adoption_proof_matrix.sh` — Merge-blocking matrix contract
- `scripts/ci/README.md` — Verifier map + **matrix-first** triage doctrine
- `.github/workflows/ci.yml` — **`docs-contracts-shift-left`** and job wiring

### Prior phase patterns (verification shape)

- `.planning/milestones/v1.17-phases/63-p0-integrator-verify-docs/63-VERIFICATION.md` — Minimal table + commands exemplar
- `.planning/milestones/v1.17-phases/62-friction-triage-north-star/62-CONTEXT.md` — Research SSOT + FRG-03 firewall context for **UAT-05**

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`scripts/ci/verify_*.sh`** — Doc-contract pattern; extend with new thin scripts only per **D-02b**.
- **`accrue/test/accrue/docs/*_test.exs`** — ExUnit mirrors invoking the same scripts locally (`mix test` DX).
- **`docs-contracts-shift-left`** in **`.github/workflows/ci.yml`** — Stable job bucket name for **66-VERIFICATION.md** “Automation” column.

### Established patterns

- **Matrix-first triage** for adoption proof (`scripts/ci/README.md`) — do not invert script/markdown SSOT (**D-05**).
- **Intentional taxonomy edits** ship **doc + verifier** together (already documented triage).

### Integration points

- **`66-VERIFICATION.md`** rows cite the **same** bash invocations contributors see in **README** / **CONTRIBUTING** / **host README**.
- **`REQUIREMENTS.md`** traceability table → flip checkboxes when **66-VERIFICATION** + **STATE** are consistent.

</code_context>

<specifics>
## Specific Ideas

- User requested **all five** gray areas with **subagent research**; recommendations above synthesize five parallel passes into **one coherent policy** (path, automation posture, archive honesty, verification template, PROOF depth).
- Emphasis: **great DX**, **least surprise**, **evaluator-visible proof**, **no scope creep** toward **PROC-08** / **FIN-03**.

</specifics>

<deferred>
## Deferred Ideas

- **Second processor / finance exports** — remain **PROJECT.md** non-goals until a future milestone explicitly reopens them.
- **Full documentation audit program** beyond **PROOF-01** bounded pass — out of scope for **66**; revisit only with new **FRG-01**-style evidence in a later friction milestone.

</deferred>

---

*Phase: 66-onboarding-confidence*  
*Context gathered: 2026-04-23*
