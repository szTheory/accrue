# Phase 51: Integrator golden path & docs - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>

## Phase boundary

Deliver **INT-01..INT-03**: one coherent **clone → install → Fake subscription → proof** narrative across **`examples/accrue_host/README.md`**, **`accrue/guides/first_hour.md`**, and **`accrue/guides/quickstart.md`**; keep **VERIFY-01** and CI lanes **discoverable** from the repo root within the **two-hop** spirit of prior **ADOPT** work; strengthen **first-run troubleshooting** with **stable, linkable anchors** aligned with **`ACCRUE-DX-*`** diagnostics and installer output.

**Not in this phase:** INT-04/05, auxiliary admin (**52–53**), **PROC-08**, **FIN-03**, VERIFY merge-blocking policy changes, new verification hub sites that split authority with the host README.

</domain>

<decisions>

## Implementation decisions

### 1 — Golden-path spine & sequencing (INT-01)

- **D-01 (canonical pattern):** Adopt a **strict single public spine** (ordered steps: deps → install → runtime config → migrations/Oban → webhook route & raw body → admin mount → first Fake subscription → proof commands) with **Step 0 entry capsules** only—not parallel full narratives:
  - **Capsule H — Hex consumer:** existing Phoenix app → join spine at `deps` / `mix accrue.install`.
  - **Capsule M — Monorepo clone:** `cd examples/accrue_host` → join the **same** host-shaped numbered flow.
  - **Capsule R — Evaluate / read-only:** shortest path to example host + bounded proof (`mix verify`) + link into full spine as needed.
- **D-02 (two-file spine rule):** Treat **`examples/accrue_host/README.md`** and **`accrue/guides/first_hour.md`** as **one logical spine**: same step order and same command vocabulary; **any change to the public integrator story updates both in the same PR** (editorial gate, not optional hygiene).
- **D-03 (`quickstart.md` role):** Keep **`accrue/guides/quickstart.md` as a thin hub/index only**—routes to First Hour, example host, troubleshooting, webhooks, testing, upgrade; **does not** grow a second tutorial body that duplicates the spine.
- **D-04 (ecosystem alignment):** Match Elixir/Hex norms: package **`README`** as router into guides + ExDoc; **`guides/`** for journeys; **example host README** as executable truth; **`mix` task `@moduledoc`** for CLI flags and semantics—not for repeating the full golden path.

### 2 — Command & proof vocabulary (INT-01 honesty + INT-02 discoverability)

- **D-05 (keep command names):** Retain **`mix verify`** (bounded local Fake proof) and **`mix verify.full`** (full host verification stack). Do **not** rename to `verify.fast` / invert defaults in this phase—churn outweighs benefit.
- **D-06 (three-layer vocabulary — mandatory in docs):** Every place that orients integrators or contributors must distinguish:
  1. **Layer A — Package contributor gate** (`CONTRIBUTING.md` / per-package `mix test`, format, Credo, Dialyzer, etc.) → maps to **`release-gate`**, not host proof.
  2. **Layer B — Host Fake proof:** `cd examples/accrue_host` → **`mix verify`** = fast bounded loop; **`mix verify.full`** = full stack the UAT script delegates to.
  3. **Layer C — PR `host-integration` merge contract:** explicitly **≠** `mix verify.full` alone—includes shift-left scripts (e.g. VERIFY-01 README contract, adoption-proof matrix where applicable), then host UAT / `mix verify.full`, plus **documented** conditional steps (e.g. Hex smoke). **Forbidden phrasing:** implying one Mix task equals the entire job unless literally true.
- **D-07 (teaching default):** **First Hour** and the host README **happy path** end by privileging **`mix verify`** as the default “I walked the story” check; **before merging** changes that touch VERIFY-01 docs, host proof, e2e, or CI contracts, authors run **repo-documented** equivalents (see **`scripts/ci/README.md`** triage)—planner wires exact commands from repo.
- **D-08 (CONTRIBUTING bridge):** Add or extend a **short** “Host proof (VERIFY-01)” pointer in **`CONTRIBUTING.md`**: one deep link to **`examples/accrue_host/README.md#proof-and-verification`** + one line classifying **Layers A/B/C**—no second command matrix (avoid drift).

### 3 — VERIFY-01 & repo-root discoverability (INT-02)

- **D-09 (canonical VERIFY surface):** Keep **root `README.md` Proof path block** + **single deep link** to **`examples/accrue_host/README.md#proof-and-verification`** as the **VERIFY-01 front door**. The host README section remains **SSOT** for merge-blocking vs advisory language, Playwright entry points, and command detail.
- **D-10 (two-hop / information scent):** Root stays **intent + lane honesty** (Fake-first, `host-integration` vs `live-stripe`); **first actionable path** should be visually obvious (prefer **one fenced** `cd examples/accrue_host && …` line for the **CI-equivalent host command** where it helps scanners). Extended matrices stay on the host README or **`scripts/ci/README.md`**, not duplicated in long form at root.
- **D-11 (no new verification hub unless triggered):** **Do not** add a standalone top-level verification doc that **duplicates** the host README proof section **unless** future fragmentation forces a **single** collapsed hub (would require **moving** authority, not copying). Optional: **minimal** CI badge on root only if maintainers accept badge noise.
- **D-12 (badges / tables):** Any CI summary table at root must be **maintainable** and **honest**—prefer links to workflow comments + `scripts/ci/README.md` over duplicating job internals that change without docs updates.

### 4 — Troubleshooting placement & stable anchors (INT-03)

- **D-13 (hybrid SSOT):** **`accrue/guides/troubleshooting.md`** remains **SSOT** for the **`ACCRUE-DX-*` matrix**, deep sections, and **how to verify** columns. Narrative spines (**`first_hour.md`**, **`webhooks.md`**, **`first_hour` → upgrade cross-links**) keep **at most one short** “when this fails” callout + **link** to the stable section—**no** second full write-up of raw-body / secrets / pipeline ordering.
- **D-14 (slug convention):** **Document once** in the troubleshooting intro: heading anchors use **lowercase kebab-case** matching the diagnostic (e.g. `ACCRUE-DX-WEBHOOK-RAW-BODY` → **`#accrue-dx-webhook-raw-body`**). **`Accrue.SetupDiagnostic`** ExDoc paths (`/guides/troubleshooting.html#…`) stay aligned with **`{#…}`** anchors in **`troubleshooting.md`**; renames require deprecation or alias strategy (planner details).
- **D-15 (installer / task output):** **`mix accrue.install`** summaries and failure paths should emit **`ACCRUE-DX-*`** where applicable plus **one** stable pointer string (prefer the **same** canonical form used in code: ExDoc fragment path **or** repo-relative `accrue/guides/troubleshooting.md#…`—pick **one** display string per surface and document the mapping in planning if both appear).
- **D-16 (installer rerun / conflicts):** Behavioral SSOT for reruns and conflict sidecars remains **`accrue/guides/upgrade.md`** (installer rerun sections per Phase 33); **`first_hour.md`** and host README carry **pointers only**, not a second spec.
- **D-17 (failure classes for INT-03):** Explicitly cover in or link from the matrix: **webhook signing + raw body ordering**, **missing/wrong secrets**, **`mix accrue.install` rerun + conflict sidecars**—each with **linkable heading** suitable from installer output and host README.

### 5 — Cross-cutting product principles (research synthesis)

- **D-18 (domain isomorphism):** Public doc **order matches billing reality** (Parsers/webhooks before trusting UI; persistence before replay semantics)—same principle as “billing state modeled clearly.”
- **D-19 (honesty over marketing):** Prefer **explicit layering** (local vs CI vs advisory) over implying “green locally = merge-ready” when scripts differ—reduces integrator cynicism and maintainer triage load.
- **D-20 (OSS precedents internalized):** Linear Stripe-style checklists + **stable error codes**; Rails Pay / Cashier **opinionated ordering**; avoid **dual full narratives** (Rails wiki/blog drift class) unless Accrue later splits contributor docs at scale.

### Claude's discretion

- Exact **wording** of the Layer B vs Layer C one-liner and root fenced-block formatting.
- Whether to add a **single** optional CI badge on root after quick maintainer check of flake noise.
- Minor **CONTRIBUTING** subsection title and placement (contributor UX only).

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements

- `.planning/REQUIREMENTS.md` — **INT-01**, **INT-02**, **INT-03**
- `.planning/ROADMAP.md` — Phase **51** + v1.13 milestone criteria
- `.planning/PROJECT.md` — v1.13 integrator goals; non-goals (**PROC-08**, **FIN-03**)

### Prior phase locks (carry-forward)

- `.planning/phases/33-installer-host-contracts-ci-clarity/33-CONTEXT.md` — installer rerun SSOT in **`upgrade.md`**; stable CI job ids; extend existing gates; annotation sweep scope
- `.planning/phases/50-copy-tokens-verify-gates/50-CONTEXT.md` — VERIFY-01 **policy unchanged**; Playwright/Copy discipline (context for adjacent work, not Phase 51 scope expansion)

### Doc spine & host proof (implementation targets)

- `README.md` — repo-root Proof path, lane honesty, Start here routing
- `examples/accrue_host/README.md` — canonical host story + **`#proof-and-verification`**
- `accrue/guides/quickstart.md` — hub index; must stay thin
- `accrue/guides/first_hour.md` — package-facing mirror of host order + pins
- `accrue/guides/troubleshooting.md` — **`ACCRUE-DX-*`** matrix + `{#anchor}` sections
- `accrue/guides/upgrade.md` — installer rerun / generated-file ownership
- `accrue/guides/webhooks.md` — raw body / handler boundary (pointers into troubleshooting)
- `CONTRIBUTING.md` — contributor gates vs host proof (Layer A vs B/C bridge)

### CI truth & scripts (Layer C honesty)

- `.github/workflows/ci.yml` — job ids, merge-blocking vs advisory
- `scripts/ci/README.md` — triage map, script purposes
- `scripts/ci/verify_verify01_readme_contract.sh` — VERIFY-01 README contract
- `examples/accrue_host/mix.exs` — `verify` / `verify.full` aliases (source of truth for Mix chains)

### Diagnostics (INT-03 alignment)

- `accrue/lib/accrue/setup_diagnostic.ex` — `ACCRUE-DX-*` codes + doc fragment paths
- `accrue/lib/mix/tasks/accrue.install.ex` — installer output surfaces (if touched)

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`Accrue.SetupDiagnostic`**: already implements **Stripe-like** `ACCRUE-DX-*` codes with **`/guides/troubleshooting.html#…`** fragments—Phase 51 **aligns prose and installer output** to this instead of inventing a parallel scheme.
- **`accrue/guides/troubleshooting.md`**: matrix + per-code sections with **`{#kebab-case}`** anchors—SSOT for INT-03 depth.

### Established patterns

- **Two README layers**: root positions product + routes; host README holds **executable** commands and VERIFY detail—maintain **single authority** for proof commands.
- **Mix aliases in host `mix.exs`**: `verify` vs `verify.full` composition is the idiomatic place to document **fast vs full**; docs must not contradict alias comments.

### Integration points

- **Installer task output** → troubleshooting / upgrade anchors.
- **Root + CONTRIBUTING + first_hour + host README** → must stay **mutually consistent** on job names, `mix verify` vs `mix verify.full`, and **host-integration** scope.

</code_context>

<specifics>

## Specific ideas

- **Research synthesis (2026-04-22):** Subagent research compared **spine+capsules** vs hub-only vs dual-track docs; **three-layer** CI/proof vocabulary; **minimal root + deep host link** for VERIFY discoverability; **hybrid troubleshooting** with **`ACCRUE-DX-*`** as stable identifiers—all folded into **D-01..D-20** above as the single coherent strategy.

</specifics>

<deferred>

## Deferred ideas

- **Renaming** `mix verify` / `mix verify.full` or introducing **`mix verify.host_ci`** that pretends to reproduce full GitHub Actions locally—deferred unless maintainers explicitly want a breaking rename cycle.
- **Standalone `docs/verification.md` hub** that duplicates host README—only revisit if VERIFY/ADOPT contracts fragment across many files and a **moved** SSOT is agreed.
- **INT-04/05** (adoption matrix / package-doc alignment) and **52–53** auxiliary admin—separate phases.

### Reviewed todos (not folded)

- None — `todo.match-phase` returned no matches for phase **51**.

</deferred>

---

*Phase: 51-integrator-golden-path-docs*  
*Context gathered: 2026-04-22*
