# Phase 59: Golden path + quickstart coherence - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

**INT-06:** **`accrue/guides/first_hour.md`**, **`examples/accrue_host/README.md`**, and **`accrue/guides/quickstart.md`** (plus explicitly linked tutorial sections) stay **free of contradictions** in version pins, command order, and capsule (**H/M/R**) instructions relative to **v1.15** trust / SemVer messaging and current **merge-blocking CI** contracts; **`verify_verify01_readme_contract.sh`** and **`verify_adoption_proof_matrix.sh`** (or successors) stay **green** on **`main`**.

**Not in this phase:** INT-07/08/09 (later phases), new billing APIs, **PROC-08** / **FIN-03**, VERIFY policy renames, rewriting the whole doc set beyond coherence + verifier alignment.

</domain>

<decisions>

## Implementation decisions

Cross-cutting: recommendations below are **one coherent package** — pins, trust copy, verifiers, and capsule structure all reinforce **honest dual-track** (Hex vs `main`), **least surprise**, and **Phase 51** locks (two-file spine, thin quickstart, Layer A/B/C honesty).

### 1 — Hex vs `main` and version pins (SSOT)

- **D-01 (`@version` + three-part `~>`):** Treat **`accrue/mix.exs`** and **`accrue_admin/mix.exs`** **`@version`** as the **only** source of truth for dependency pins in integrator-facing fenced blocks. Snippets use **identical three-part pins** on both packages, e.g. `{:accrue, "~> 0.3.1"}` and `{:accrue_admin, "~> 0.3.1"}`, matching **`verify_package_docs.sh`** / **`Accrue.Docs.PackageDocsVerifierTest`** enforcement. This matches **Mix** semantics for pre-1.0 (**minor** is the intentional breaking boundary on Hex) and avoids misleading **`~> 0.3`**-style floors that read “patch-safe” but mean **&lt; 1.0.0** in Elixir.

- **D-02 (Hex vs `main` banner):** Keep a **prominent** “Hex vs `main`” explanation wherever copy-paste pins appear (First Hour, package READMEs as already governed). **`main`** may be **ahead of last Hex publish** — never imply they are the same artifact without saying so.

- **D-03 (defer doc generation):** Do **not** introduce placeholder/templated install blocks or pre-render pipelines **until** maintainer pain from multi-file pins clearly exceeds the cost of **`verify_package_docs`** needles. Stripe-style **versioned truth** here is the **bash + ExUnit gate**, not a separate doc build.

- **D-04 (post-1.0 evolution):** After a stable **1.x** line and documented SemVer, **optional** relaxation of *displayed* pins (e.g. two-segment `~> 1.y`) is allowed **only if** gates still enforce a **minimum** compatible release — not while pre-1.0 “minor may break API” is the public contract.

### 2 — Sigra vs `Accrue.Auth` (v1.15 trust messaging)

- **D-05 (SSOT split — demo vs contract):** **`examples/accrue_host/README.md`** remains **SSOT** for **why** the checked-in demo uses Sigra, **how** it is wired (`mix.exs`, **`ACCRUE_SIGRA_PATH`**), and **CI reproducibility**. **`accrue/guides/auth_adapters.md`** remains **contract SSOT** for production **`Accrue.Auth`** choices.

- **D-06 (First Hour — one trust paragraph + routing):** Add or keep **exactly one bounded “Trust boundary”** block in **First Hour** (placement: after capsule picker or at start of **§ 1. First run**) stating: production uses **host-owned `Accrue.Auth`**; Sigra is **one optional adapter**; the **demo** uses Sigra for **deterministic org billing / CI**; non-Sigra hosts follow **Capsule H** + **`organization_billing.md`**. Link to **`auth_adapters.md`**, **`organization_billing.md`**, and the host README for demo specifics — **no** second full Sigra install essay in First Hour.

- **D-07 (Per-capsule emphasis, light touch):** **Capsule H** stresses **`Accrue.Auth`** + org billing path for real apps. **Capsule M** may add **one sentence** that Sigra is **demo-tree convenience**, not a library requirement — without duplicating the host README blockquote.

- **D-08 (Quickstart stays thin):** **`quickstart.md`**: **at most one sentence or bullet** pointing integrators to **`auth_adapters.md`** for production auth — **no** full duplicated disclaimer (avoids third narrative + banner fatigue; preserves hub role per **Phase 51 D-03**).

- **D-09 (forbidden pattern):** Never phrase Sigra as **required for production** or imply the demo **`mix.exs`** is the host’s copy-paste target without the demo-vs-production fork.

### 3 — Verifier scope and contributor preflight (INT-06)

- **D-10 (merge-blocking = branch protection):** While **GitHub** runs the **full** required graph on every PR, **do not** document or imply that “markdown-only” PRs can skip **`host-integration`**. **Normative** definition of merge-ready = **required checks** in **`.github/workflows/ci.yml`** + branch protection.

- **D-11 (local minimal doc-contract preflight):** Before opening a PR that touches **First Hour**, **host README**, **quickstart**, or any path **`verify_package_docs`** needles, contributors should run **in order** (fast fail):

  ```bash
  bash scripts/ci/verify_package_docs.sh && \
  bash scripts/ci/verify_verify01_readme_contract.sh && \
  bash scripts/ci/verify_adoption_proof_matrix.sh
  ```

  This does **not** replace **`host-integration`** or **`release-gate`** — it prevents late surprises when **`release-gate`** is green but **`host-integration`** fails.

- **D-12 (close quickstart enforcement gap):** Extend **`scripts/ci/verify_package_docs.sh`** (and **`test/accrue/docs/package_docs_verifier_test.exs`**) to cover **`accrue/guides/quickstart.md`** with a **small stable** set of checks: e.g. required links into First Hour / host proof anchors, **`Hex vs `main``**-class banner consistency if repeated there, and **no accidental second spine** (e.g. forbidden duplicate of full install body). **INT-06** explicitly names quickstart; today the script does **not** grep `quickstart` — that is a **known drift footgun** to fix in this phase.

- **D-13 (CONTRIBUTING bridge):** Add **one short line** in the host-proof / Layer B–C area of **`CONTRIBUTING.md`** listing the **three bash commands** above as the **minimum doc-contract preflight** for golden-path edits.

- **D-14 (pre-commit optional):** If hooks exist or are added, scope to **formatter + the bash trio** only — never Dialyzer, full Playwright, or multi-matrix in pre-commit.

- **D-15 (path-filtered CI):** **Do not** introduce path-only “docs lite” jobs **unless** queue pain forces it **and** a **fallback** runs full matrix when non-doc paths change — otherwise risk missing cross-file interactions.

- **D-16 (needle limits):** Scripted checks prove **structural** and **literal** coherence, not full narrative quality — **human review** remains required for “no contradictory messaging vs v1.15.”

### 4 — Capsule H/M/R and spine ordering (structural coherence)

- **D-17 (D-02 same-PR discipline):** Any change to **ordered spine steps**, **capsule join points**, or **H/M/R vocabulary** in **First Hour** or **host README** ships in the **same PR** as the paired file (and updates **quickstart** if its **outline bullets** restate ordering). This is the **primary** anti-drift mechanism.

- **D-18 (lightweight structural verifier — A + B):** Extend doc verification (same family as **`verify_package_docs`**) with **cheap invariants**: presence of **`### Capsule H` / `M` / `R`** (or equivalent stable headings), a **canonical ordered token list** for the spine (e.g. deps → install → runtime → migrations → Oban → webhooks → admin → proof), and **optional** ordering guards so **webhook / signing** is not taught **after** “trust the subscription UI” in machine-checkable outlines. **Avoid** YAML/codegen dual SSOT (**strategy C**) until repeat PR churn proves it necessary.

- **D-19 (Diátaxis / IA):** **One tutorial spine** (First Hour + mirrored host story); **quickstart** = **hub / navigation**, not a second tutorial; deeper trust, webhooks, upgrade → **linked guides**. Do not let quickstart grow a competing numbered path.

- **D-20 (anchor hygiene):** Renaming headings that **`#proof-and-verification`** or capsule deep-links depend on must include **grep + verifier** updates in the same change.

- **D-21 (reject single-narrative-only host README):** Do **not** move the full ordered spine **only** into First Hour with host README as thin links — that **conflicts** with **Phase 51**’s mirrored public paths for Hex consumers vs monorepo cloners.

### Claude's discretion

- Exact **wording** of the First Hour **Trust boundary** paragraph and capsule **one-liners**.
- **Specific regexes / token lists** for the structural verifier once implementation starts.
- Whether to add **one** optional **pre-commit** hook wiring the bash trio after maintainer consensus.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **INT-06** (golden path coherence)
- `.planning/ROADMAP.md` — Phase **59** goal, success criteria, milestone **v1.16** boundaries
- `.planning/PROJECT.md` — Core value, v1.16 theme, non-goals (**PROC-08**, **FIN-03**)

### Prior integrator locks (carry-forward)

- `.planning/phases/51-integrator-golden-path-docs/51-CONTEXT.md` — **D-02** two-file spine; **D-03** thin quickstart; **Layer A/B/C** vocabulary; VERIFY front door patterns

### Doc surfaces (edit targets)

- `accrue/guides/first_hour.md` — package-facing spine + capsules
- `examples/accrue_host/README.md` — host-facing spine + demo SSOT (Sigra, proof)
- `accrue/guides/quickstart.md` — hub index
- `accrue/guides/auth_adapters.md` — production **`Accrue.Auth`** contract
- `accrue/guides/organization_billing.md` — non-Sigra org billing path
- `CONTRIBUTING.md` — contributor vs host proof layers

### Verifiers and CI truth

- `scripts/ci/verify_package_docs.sh` — Hex pin + doc literal gate (extend for **quickstart** per **D-12**)
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — ExUnit wrapper for package docs script
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README contract
- `scripts/ci/verify_adoption_proof_matrix.sh` — adoption proof matrix coherence
- `scripts/ci/README.md` — script → requirement mapping
- `.github/workflows/ci.yml` — merge-blocking vs advisory jobs

### Version SSOT

- `accrue/mix.exs` — **`@version`**
- `accrue_admin/mix.exs` — **`@version`** (lockstep with **`accrue`**)

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`Accrue.Docs.PackageDocsVerifierTest`** + **`scripts/ci/verify_package_docs.sh`** — extend here for **quickstart.md** and optional **spine/capsule** structural checks (**D-12**, **D-18**).
- **Existing VERIFY-01 and adoption matrix scripts** — already encode merge-blocking “doc contract” truth; preflight order should run them after **`verify_package_docs`** (fastest version pin failures first).

### Established patterns

- **Lockstep dual-package** SemVer on Hex — docs must never show **mismatched** `accrue` / `accrue_admin` pins.
- **Optional `:sigra`** in core vs **demo host** pinning Sigra — architectural fact backing **D-05**–**D-09** messaging.

### Integration points

- **Phase 60** will lean on **`scripts/ci/README.md`** and adoption docs; keep verifier naming and **Layer** vocabulary aligned with decisions here.
- **Phase 61** picks up **INT-08/09** (root VERIFY hops, Hex doc SSOT); do not preempt those requirements in Phase 59, but avoid edits that would **tighten hop budget** or **@version** mirrors without the paired phase work.

</code_context>

<specifics>

## Specific ideas

- User requested **subagent-backed research** for all four gray areas and a **single cohesive** recommendation set — captured above (pins + trust + verifiers + capsules).
- Precedents cited in research: **Hex + ExDoc** dual-track honesty, **Oban-style** main vs Hex framing, **Pay / Cashier / Stripe** lessons (doc drift, double SSOT, versioned reference), **Rails dummy apps** (demo auth ≠ production), **Diátaxis** (one tutorial spine), **Google dev docs style** (sequential numbered paths, local project rules win).

</specifics>

<deferred>

## Deferred ideas

- **YAML / codegen doc spine (strategy C)** — only if capsule drift remains a repeated problem after **D-17** + **D-18**.
- **CI path filtering for docs-only PRs** — only if wall-clock cost forces it, with a safe fallback (**D-15**).
- **Relaxed two-segment `~> 0.minor` display in prose** — deferred until **post-1.0** explicit policy (**D-04**).

### Reviewed todos (not folded)

- None from **`todo.match-phase`**.

**None** — discussion stayed within Phase **59** scope.

</deferred>

---

*Phase: 59-golden-path-quickstart-coherence*  
*Context gathered: 2026-04-23*
