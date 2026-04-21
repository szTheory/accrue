# Phase 31: Advisory integration alignment - Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 31 closes **advisory** integration gaps from the v1.6 milestone audit: **README VERIFY-01 ↔ CI contract**, **host `npm` scripts**, **`AccrueAdmin.Copy` SSOT** where audit noted partiality, and **alignment between `examples/accrue_host` Playwright (canonical VERIFY-01)** vs **`accrue_admin` fixture browser** — plus **docs** for reseed / axe / mobile scope where touched by that alignment.

It does **not** add billing product scope, new third-party UI kits, full-site i18n/gettext, or a second merge-blocking browser matrix inside `accrue_admin`.

Exit is **audit advisory items cleared or explicitly documented** with **coherent** host-first VERIFY-01 story, **minimal contributor surprise**, and **no regression** to Phases **21 / 27 / 28 / 29** locked postures (desktop-first wide gate; axe on mounted host path; real `chromium-mobile` for MOB; Hex packages stay fast).

</domain>

<decisions>
## Implementation Decisions

### D-01 — README ↔ `verify_verify01_readme_contract.sh` (two-tier contract)

- **Tier A (substring anchors, low churn):** Extend the existing bash contract for **parity** with the a11y anchor: require **at least one stable substring** for the **mobile VERIFY-01 spec** (e.g. `verify01-admin-mobile.spec.js` or the shipped filename) **and/or** a **stable README heading** for the mobile shell subsection, so MOB prose cannot drift while a11y stays locked. Prefer **path + heading** only where they are already canonical in README — avoid dozens of prose substrings.
- **Tier B (mechanical, optional in same phase if cheap):** Add a **filesystem-backed** check: any `e2e/verify01-*.spec.js` path **named in README** must exist on disk (small loop over `grep` output). Reduces **rename false greens** without encoding every future English sentence in bash.
- **Single narrative spine:** Keep evaluator story in **README + adoption proof matrix**; if enumerated spec lists grow again, **move lists** toward `.planning` / `docs/adoption-proof-matrix.md` or a tiny manifest **later** — Phase 31 defaults to **minimal bash + optional file-exists loop**, not a new codegen pipeline.
- **Keep high-severity negatives narrow:** Retain the **`sk_live`** in-section negation pattern; do not grow a large family of “security prose” substring tests here.

### D-02 — `examples/accrue_host` npm scripts (evaluator / maintainer DX)

- **Add `e2e:mobile` parallel to `e2e:a11y`:** Same **`env -u NO_COLOR` + `playwright test <spec>`** shape as `e2e:a11y`, targeting the **canonical mobile VERIFY-01 spec** (the file the phase work standardizes on — today’s tree: `e2e/verify01-admin-mobile.spec.js` or successor with **same contract update** if renamed).
- **Keep `e2e` as the wide Playwright entry** used by `mix verify.full` / `accrue_host_verify_browser.sh`; shortcuts (`e2e:a11y`, `e2e:mobile`, `e2e:visuals*`) are **focused lanes**, not replacements for CI’s default invocation.
- **Naming discipline:** Prefer **`e2e:*`** over `npm test` / `test:*` prefixes that compete with **`mix test`** as the mental “truth” for this monorepo.
- **README honesty:** One short note that **`env -u NO_COLOR`** is POSIX-oriented; Windows contributors may invoke `playwright test` directly if needed (document only if not already present).

### D-03 — `AccrueAdmin.Copy` SSOT sweep scope (governance, not i18n)

- **Default scope = tiered (not a repo-wide “no literals” rule):** Phase 31 finishes **operator-visible** gaps called out by audit — especially **step-up / sensitive-action chrome** and any **VERIFY-01-visible** strings still inline — while **explicitly not** sweeping dev-only, kitchen, or non–INV-03 surfaces “for color.”
- **`AccrueAdmin.Copy` remains the hub; `AccrueAdmin.Copy.Locked` stays contract-grade:** Expand **Locked** only for **verbatim-stable** strings: compliance/security denials, irreversible confirmations, and **explicit VERIFY-01 / cross-surface locks** already treated as API in Phase 27/28.
- **Playwright literal policy (coherent with 27/28/29):** Prefer **`getByRole` / stable test ids** on host specs; use **exact `Copy` / Locked text** only where the **string is the guarantee**. Avoid duplicating marketing literals in **two** Playwright trees (host + admin) — see D-04.
- **gettext:** **Out of scope** for Phase 31 — defer until a deliberate i18n milestone; library gettext imposes host-owned catalog merge semantics and tool churn disproportionate to v1.6 goals.

### D-04 — Dual Playwright locations (`accrue_host` vs `accrue_admin` browser workflow)

- **Single canonical merge-blocking browser truth:** **`examples/accrue_host`** owns **VERIFY-01**, **mounted admin**, **axe** (desktop project per Phase 28), and **real `chromium-mobile` MOB** (Phase 29). CI and README contracts **must not** imply a second “equivalent” release story elsewhere.
- **`accrue_admin` Playwright narrows to “fast fixture smoke” or advisory redundancy:** Either (a) **trim assertions** that duplicate host VERIFY-01 literals / journeys, replacing with **roles / testids / structural checks**, or (b) mark the workflow **advisory** / path-filtered **smoke** with an explicit maintainer note: **host suite is law** — pick the smallest change that clears the **duplicate literal drift** finding without deleting useful **pre-host** signal, if any remains.
- **Hard boundary:** **No** `accrue_admin` → `examples/accrue_host` **source dependencies** (no symlinks of `support/` into the package). Shared code, if ever needed, is a **future** explicit `packages/*` workspace decision — **not** Phase 31 by default.
- **Documentation coherence:** Admin package contributor doc (short) points evaluators to **host README VERIFY-01** for mounted proofs; reduces “which green job counts?” confusion.

### D-05 — Cross-cutting coherence (architecture story)

- **`mix verify.full` remains the human-facing orchestration spine;** npm scripts are **maintainer shortcuts** invoked from that path, not a parallel test system.
- **Contract tests grow symmetrically:** README anchors for **a11y + mobile + npm shortcuts** stay in lockstep with **what CI actually relies on**.
- **Copy + browser + README** move together: changing a **Locked** string updates **`Copy` + host Playwright (+ admin smoke only if it still asserts that literal)** in one accountability unit — avoid two PRs drifting.

### Claude's Discretion

- Exact **bash** implementation for Tier B file-existence loop (grep vs Python vs small Mix task) — smallest shippable wins.
- Whether **`accrue_admin_browser.yml`** becomes **strict smoke** vs **advisory** vs assertion-only edits — choose the **minimum** diff that removes duplicate **verbatim** literals vs host VERIFY-01 while preserving flake attribution.
- Precise **substring set** for README contract after `e2e:mobile` lands (wording-level), provided Tier A stays **short and stable**.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit and requirements (scope authority)

- `.planning/v1.6-MILESTONE-AUDIT.md` — Advisory integration findings (README contract asymmetry, npm scripts, Copy partiality, Playwright duplication, reseed/axe/mobile notes).
- `.planning/ROADMAP.md` — Phase 31 goal row (v1.6 audit gap closure milestone).
- `.planning/milestones/v1.6-REQUIREMENTS.md` — INV/COPY/UX/A11Y/MOB IDs referenced by alignment work (root `.planning/REQUIREMENTS.md` absent until `/gsd-new-milestone`).

### Prior locked postures (do not contradict without ADR)

- `.planning/phases/21-admin-and-host-ux-proof/21-CONTEXT.md` — Host-owned VERIFY-01; desktop-first; where Playwright lives.
- `.planning/phases/27-microcopy-and-operator-strings/27-CONTEXT.md` — `AccrueAdmin.Copy` hub, Locked tier, Playwright literal policy.
- `.planning/phases/28-accessibility-hardening/28-CONTEXT.md` — Axe on mounted host path; desktop Chromium; `28-UI-SPEC.md` contract.
- `.planning/phases/29-mobile-parity-and-ci/29-CONTEXT.md` — Real `chromium-mobile`; project skip patterns; README mobile shell subsection intent.

### Implementation surfaces (expected edit locations)

- `scripts/ci/verify_verify01_readme_contract.sh` — README ↔ CI anchors.
- `examples/accrue_host/README.md` — VERIFY-01 prose, evaluator commands.
- `examples/accrue_host/package.json` — `e2e:*` scripts.
- `examples/accrue_host/playwright.config.js` — projects definitions (reference only if script flags change).
- `.github/workflows/accrue_admin_browser.yml` — admin browser lane posture.
- `accrue_admin/e2e/` — fixture-server Playwright (smoke / dedup literals).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`scripts/ci/verify_verify01_readme_contract.sh`** — Established substring + `awk` negative pattern for VERIFY-01; extend symmetrically rather than new framework.
- **`examples/accrue_host/package.json`** — `e2e:a11y` pattern to mirror for `e2e:mobile`.
- **`AccrueAdmin.Copy` / `AccrueAdmin.Copy.Locked`** — SSOT and contract-grade literals for selective Playwright alignment.

### Established Patterns

- **Host-first browser gate** — `mix verify.full` → shell helpers → `npm run e2e` with seeded DB + Playwright projects (`chromium-desktop`, `chromium-mobile`, `chromium-mobile-tagged`).
- **Project-level skips** — `verify01-admin-a11y.spec.js` desktop-only pattern; mobile specs invert skips per Phase 29.

### Integration Points

- **CI** — `host-integration` / verify scripts must remain the **evaluator-equivalent** path; any README change must remain enforceable by the contract script.
- **Admin package boundary** — No reference from `accrue_admin` lib or package tests into `examples/accrue_host` source trees.

</code_context>

<specifics>
## Specific Ideas

- User requested **“all”** gray areas with **parallel subagent research** (2026-04-21) and a **single cohesive recommendation set** emphasizing Accrue’s **billing-library** positioning, **host-first VERIFY-01**, **least surprise**, strong **maintainer DX**, and **operator-trust UX** on normative surfaces only.

</specifics>

<deferred>
## Deferred Ideas

- **Generated README blocks** or **`verify01-manifest.yaml`** consumed by bash and docs — defer until VERIFY-01 file lists churn enough to justify DRY infrastructure.
- **Root npm workspaces** / shared `@accrue/playwright-support` package — defer; violates “smallest shippable” unless duplication becomes measurable maintainer tax.
- **gettext / full i18n** for `accrue_admin` — explicit future milestone, not v1.6 audit closure.
- **Expanding host Playwright to every money index** — remains out of scope (INV-03 / Phase 21 bounded spine); Phase 31 only **aligns** existing contracts.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 31-advisory-integration-alignment*  
*Context gathered: 2026-04-21*
