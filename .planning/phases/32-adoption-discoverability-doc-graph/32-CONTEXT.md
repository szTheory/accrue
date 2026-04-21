# Phase 32: Adoption discoverability + doc graph - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Unify how evaluators and contributors discover and run the **Fake-first proof story** (VERIFY-01, `mix verify` / `mix verify.full`, Playwright entry points) from the repo root and across guides—**without** changing merge-blocking CI semantics, **without** new installer behavior (Phase 33), and **without** admin UI work (Phases 34–35).

Success is measured by ROADMAP criteria: root → runnable VERIFY-01 instructions ≤2 hops; one coherent authoritative host subsection; no contradictory “primary proof command” across linked docs.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Root README routing (ADOPT-01)

- **Decision:** Use a **thin hybrid** on the repository root `README.md`: keep “Start here” as the main spine, and add (or tighten) a **named above-the-fold block** (e.g. **Proof path (VERIFY-01)** or **Merge-blocking proof (Fake)**) that states in ≤5 lines: Fake-first default, **exact `cd`**, the **merge-blocking local command** (`cd examples/accrue_host && mix verify.full`), and **one** primary deep link to the host README’s **authoritative anchor** (the single H2 from D-02, with a stable heading slug).
- **Rationale:** Hex/OSS idiom is README-as-index; evaluators still expect a 60-second answer on the root. Host README remains long-form runnable truth—avoids two diverging tutorials (research: Pay/Jumpstart/Cashier footgun = duplicate getting-started).
- **Explicit non-goals:** Root does **not** host the full Playwright matrix, long VERIFY-01 checklists, or a second copy of adoption tables.

### D-02 — Host README information architecture (ADOPT-02)

- **Decision:** Introduce **one** top-level H2 (stable title, avoid phase numbers in the slug users bookmark—e.g. **Proof & verification** or **Verification & VERIFY-01**) that **subsumes** today’s overlapping “Verification modes” + “VERIFY-01” material as **H3 subsections** (e.g. *Mix tasks & CI parity*, *VERIFY-01 checklist*, *Playwright entry points*, *Adoption matrix & walkthrough links*).
- **Opening paragraph (SSOT):** First sentences under that H2 must state, without paraphrase variants: **PR merge-blocking** ↔ GitHub Actions job **`host-integration`** ↔ local **`cd examples/accrue_host && mix verify.full`**; **`mix verify`** = bounded / faster slice, **not** CI-complete unless explicitly qualified.
- **First run / Quickstart:** Stays short (setup, server, human walk, **`mix verify`** as the teaching slice); heavy VERIFY-01 + browser detail lives under the single H2.
- **Visual walkthrough / trust visuals:** Clearly labeled **non-blocking** (or nested under Proof as “Visual artifacts / demo lane”) so it never competes with merge-blocking language.

### D-03 — Cross-guide SSOT policy (ADOPT-03)

- **Decision:** **Two-layer SSOT** with zero contradiction:
  1. **Executable truth** — `examples/accrue_host/README.md` § (D-02 H2): cwd, Mix tasks, npm scripts, CI job mapping, links to matrix + evaluator script.
  2. **Philosophy / lanes** — `accrue/guides/testing.md` (and `guides/testing-live-stripe.md` for Stripe advisory): Fake vs Stripe test vs live framing; **must** open with the **same approved merge-blocking one-liner** (identical wording to host + root) then link into host § for commands—**no second command matrix** with different semantics.
- **`accrue/guides/first_hour.md`:** Pedagogical order; links to host § for runnable parity; does **not** redefine CI job IDs or npm matrices.
- **`examples/accrue_host/docs/adoption-proof-matrix.md`** + **`examples/accrue_host/docs/evaluator-walkthrough-script.md`:** Linked from host Proof H2 as coverage / human walk; matrix remains the place for **row-level** semantics if README tables would rot.
- **Enforcement:** Extend or align existing doc contract coverage (`scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`, and any ExUnit guide contracts) so the **approved one-liner** and stable job id **`host-integration`** cannot drift across high-traffic files.

### D-04 — Playwright / npm naming (coherence with D-01–D-03)

- **Decision:** Outside `examples/accrue_host`, every first mention of an npm script uses **explicit cwd** (`cd examples/accrue_host`, then `npm run …`) **or** `npm --prefix examples/accrue_host run …` in advanced maintainer docs only—pick one house style for root + guides (**prefer `cd` + run** for readability).
- **Umbrella vocabulary (mandatory in prose):** **VERIFY-01 browser lane** = Playwright surface exercised under **`mix verify.full` / `host-integration`** (full `npm run e2e` and documented slices `e2e:a11y`, `e2e:mobile` as labeled subsets). **Trust / demo visuals lane** = `e2e:visuals*` (and related trust walkthrough greps)—**not** a substitute for VERIFY-01 unless CI contract explicitly expands.
- **Windows / POSIX:** Keep **one** canonical escape hatch in host README (`npx playwright test …`); root/guides link to it instead of duplicating shell variants.

### D-05 — Cohesive principles (all decisions above)

- **Principle of least surprise:** One merge-blocking mapping everywhere; `mix verify` never described as “what CI runs” without the bounded qualifier.
- **DX:** Shorter path for evaluators on root; one scroll context on host for “what blocks merge”; guides teach **why** and link for **how**.
- **Architecture:** README = index + contracts; example app README = executable SSOT; matrix = coverage semantics; scripts/tests = anti-drift backstop.

### Claude's Discretion

- Exact heading title for the host H2 (provided it stays stable and slug-friendly).
- Whether the root block is titled “Proof path (VERIFY-01)” vs “Merge-blocking proof (Fake)” — pick whichever reads cleaner next to current README tone.
- Minor table formatting inside host README vs pushing full table only to `docs/adoption-proof-matrix.md` — prefer less duplication even if the host keeps a **small** summary table.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning & requirements

- `.planning/ROADMAP.md` — Phase 32 goal, success criteria, dependencies.
- `.planning/REQUIREMENTS.md` — ADOPT-01, ADOPT-02, ADOPT-03 wording and traceability.
- `.planning/PROJECT.md` — v1.7 milestone intent; VERIFY-01 / Fake-first positioning.

### Docs to edit or align

- `README.md` — Root discoverability; add/tighten proof block + links (D-01).
- `examples/accrue_host/README.md` — Primary IA + SSOT paragraph (D-02, D-04).
- `accrue/guides/first_hour.md` — Cross-links; no duplicate CI matrix (D-03).
- `accrue/guides/testing.md` — Lane philosophy + approved one-liner + deep link (D-03).
- `guides/testing-live-stripe.md` — Advisory Stripe lane; must not contradict Fake SSOT (D-03).
- `examples/accrue_host/docs/adoption-proof-matrix.md` — Coverage / matrix semantics (D-03).
- `examples/accrue_host/docs/evaluator-walkthrough-script.md` — Human walk alignment (D-03).

### CI / enforcement

- `.github/workflows/ci.yml` — Job id `host-integration` and workflow structure (must match documented mapping).
- `scripts/ci/verify_package_docs.sh` — Doc string invariants.
- `scripts/ci/verify_verify01_readme_contract.sh` — README contract for VERIFY-01 paths.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Root README** — Already implements a strong “Start here” hub; extend with a compact proof block rather than new doc trees.
- **Host README** — Already documents `mix verify`, `mix verify.full`, `host-integration`, Playwright scripts, VERIFY-01, and verification modes—restructure rather than rewrite from scratch.
- **Doc contract scripts** — `scripts/ci/verify_package_docs.sh` and `scripts/ci/verify_verify01_readme_contract.sh` are the right mechanical layer to lock approved strings across files.

### Established patterns

- **Mix as orchestrator, npm as Playwright implementation** under `examples/accrue_host` — matches Phoenix + Playwright ecosystem expectations (cwd = directory containing `playwright.config`).
- **Monorepo root as router, example README as command SSOT** — idiomatic for library repos with a canonical host app.

### Integration points

- Any new anchors on the host README should be reflected in root README links and in doc contract tests if paths/headings are asserted.
- Cross-links from package guides into the host Proof H2 complete the doc graph without duplicating matrices.

</code_context>

<specifics>
## Specific Ideas

- **Approved one-liner (draft for planners to normalize verbatim across files):**  
  *Pull requests are merge-blocked on GitHub Actions job `host-integration`, which runs the same contract as `cd examples/accrue_host && mix verify.full`; use `mix verify` for a faster bounded Fake slice that is not CI-complete.*  
  (Finalize wording during implementation; keep job id and task names stable.)

- **Research synthesis:** Hybrid root block + single host H2 + hub-and-spoke guides + umbrella terms for Playwright lanes aligns Pay/Cashier/Jumpstart lessons (one blessed clone path, CI name parity) with Hex culture (short root, guides/example for depth).

</specifics>

<deferred>
## Deferred Ideas

- **Phase 33** — Installer rerun semantics, `mix accrue.install` boundary copy, CI job display naming beyond doc alignment.
- **Phase 34–35** — Operator admin home, summary surfaces, `AccrueAdmin.Copy` literals.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 32-adoption-discoverability-doc-graph*  
*Context gathered: 2026-04-21*
