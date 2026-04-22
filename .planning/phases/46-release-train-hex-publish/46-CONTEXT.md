# Phase 46: Release train & Hex publish - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **REL-01**, **REL-02**, and **REL-04**: an executable maintainer path from green **`main`** → reviewed merged **Release Please** release PR → **`accrue` published on Hex before `accrue_admin`**, with **linked SemVer**, **`mix.exs` `@version`** and **Released** changelog sections matching Hex, and **git tags** `accrue-v{version}` / `accrue_admin-v{version}` verifiable on the merge/release commit.

**Explicitly not this phase:** **REL-03** (routine pre-1.0 `RELEASING.md` narrative vs bootstrap) — Phase **47**. **DOC-01**, **DOC-02**, **HYG-01** — Phase **47**. Deep supply-chain artifacts (SLSA, SBOM generation per release) — optional pointer only; not a Phase 46 deliverable.

</domain>

<decisions>
## Implementation Decisions

### 1 — SemVer target & Release Please (ecosystem: Hex + RP monorepo)

- **D-01:** **Release Please is the sole routine writer** of `@version` bumps and **Released** changelog sections for **`accrue`** and **`accrue_admin`**. Do not hand-edit versions on `main` outside the merged release PR (exceptions only via documented **Release-As** / path-scoped trailers).
- **D-02:** **Operational SSOT pair:** `.release-please-manifest.json` (automation anchor) + **`mix.exs` `@version`** (Hex-facing). After every release merge, manifest, both `mix.exs` files, and changelogs **must agree** — **REL-02** / CI enforce; drift is a blocker.
- **D-03:** **Numeric SemVer is commit-derived** (Conventional Commits + `release-please-config.json` / pre-major rules), not roadmap-derived. **Milestone text** (e.g. “0.3.0 line”) is **comms intent** only; the shipped number is whatever the **merged release PR** contains unless a **documented exceptional** Release-As train is executed.
- **D-04:** **Lockstep dual packages** at the same SemVer for each public train — one combined PR, linked-versions plugin — because **`accrue_admin`** depends on **`accrue`** at the same release line; consumers must not hit “admin without matching core” during a normal ship.
- **D-05:** **Do not** adopt “publish on every green `main` merge without a release PR” for these packages — irreversibility and dual-publish ordering need the **Release PR diff** as the human-readable semver and changelog contract.

### 2 — Human gates vs automation (billing-adjacent blast radius)

- **D-06:** **Human-required merge** for Release Please **release** PRs (**no full auto-merge** of those PRs). Automation drafts versions and changelogs; a **maintainer** owns the irreversible merge decision.
- **D-07:** **All required CI checks green** before merge — no bypasses; flaky tests are **release blockers**, not process noise to override.
- **D-08:** **Per-release PR maintainer checklist** (minimum): (1) changelog accuracy + any migration/breaking callouts, (2) semver classification sanity (`feat!` / `BREAKING CHANGE`), (3) both packages’ `mix.exs` + admin’s **`{:accrue, ...}`** line consistent with lockstep, (4) no unexpected workflow or permission changes in the same PR, (5) secrets / publish path unchanged in a broadening way.
- **D-09:** **Do not** rely on **bot self-approval** to satisfy branch protection for release PRs — that is automation theater for a payments library. Use **real maintainer review** (or org-approved equivalent).
- **D-10:** **Optional:** Merge queue **after** human approval is allowed (Claude discretion) for serialization — still **human-gated** first.

### 3 — Verification evidence (**REL-01** / **REL-02** / **REL-04**) — “Standard” depth

- **D-11:** **`46-VERIFICATION.md` uses “Standard” evidence**, not minimal one-liners and not audit binders: a **durable index card** linking Git + CI + Hex + changelog anchors, plus **short reproducible command blocks**.
- **D-12:** **Required evidence blocks (ordered):** (1) release / phase identifier + **REL** IDs satisfied; (2) **Release Please PR** link + **merge commit SHA**; (3) **tags** `accrue-vX` / `accrue_admin-vX` pointing at that train; (4) **`mix hex.info accrue`** / **`mix hex.info accrue_admin`** (or equivalent) showing published **X**; (5) **changelog anchors** (paths + section headers, no full paste); (6) **CI run link(s)** for the merge commit with **release-gate** / publish job names called out; (7) **minimal consumer smoke** (copy-paste `mix` steps pinned to tags or versions proving install resolves); (8) **one subsection** proving **version coupling** between admin and core for that release; (9) **1–3 bullets** on support posture (retire / forward-fix pointer to runbook, link **`SECURITY.md`** if security-relevant).
- **D-13:** **Do not duplicate** full CI logs, full dependency trees, or per-release SBOM in verification — **link** to CI; centralize deep supply-chain narrative in static docs once (**D-14** pointer only).

### 4 — Partial publish failure (two Hex publishes ≠ one transaction)

- **D-15:** **Design for half-commit:** `accrue` at version **V** may exist on Hex while `accrue_admin` at **V** is still absent — workflows, alerts, and docs assume this topology.
- **D-16:** **Default recovery when core at V is correct:** retry or fix-forward **admin** publish for the **same V** (token, metadata, deps) until admin **V** lands — lowest version churn, preserves single-version narrative.
- **D-17:** **`mix hex.publish --revert`** only for **clear mistakes** on **`accrue`** within Hex’s **short post-publish window**; after that, **retire + forward-fix** (`mix hex.retire`, new **V'** pair) — align messaging with [Hex immutability / retire FAQ](https://hex.pm/docs/faq).
- **D-18:** If admin cannot ship **V** promptly and core **V** should not be consumed alone: **retire core V** with reason + publish coherent **V′** pair + **changelog honesty** (“do not use **V** as a pair”) — avoid silent half-states.
- **D-19:** **GitHub Releases / tags vs Hex:** If tags exist but Hex is partial, **document** partial state in release notes or verification; do not leave **marketing “shipped”** without Hex corroboration for both packages when the milestone claims a pair.
- **D-20:** **Phase 46 closure rule:** Phase **46** is **not complete** until **either** (a) **both** packages at **V** appear on Hex with evidence in **D-12**, **or** (b) a **documented** retire + replacement pair (**V′**) with the same evidence pattern and **no** advertised “supported pair” stuck half-published.

### 5 — Cross-cutting product principles (Accrue vision)

- **D-21:** **Principle of least surprise:** Release train behavior should match **`RELEASING.md`** + **`release-please-config.json`**; verification is **what a skeptical Phoenix integrator would check** before trusting a billing dependency bump.
- **D-22:** **DX for consumers:** Lockstep + honest changelogs matter as much as semver digits (pre-1.0 **`~>`** semantics are subtle — docs and **Released** sections carry the contract).
- **D-23:** **Lessons absorbed:** (1) **npm / left-pad** — immutability wins; never assume unpublish fixes the graph. (2) **RubyGems** — registry + maintainer hygiene + changelog discipline. (3) **Rust workspaces** — treat dual Hex publish like **two crates one train**: one PR, one checklist, explicit partial-failure runbook. (4) **Pay / Cashier** — conservative human gate on **money-shaped** releases beats merge velocity.

### Claude's Discretion

- Exact **`46-VERIFICATION.md`** headings and whether screenshots substitute for pasted `hex.info` output (pick one style and stay consistent).
- Whether merge queue is enabled post-approval.
- Wording of maintainer checklist items beyond the minimum **D-08** set.

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — **REL-01**, **REL-02**, **REL-04** (Phase 46); **REL-03** deferred to Phase 47
- `.planning/ROADMAP.md` — Phase 46 goal and success criteria
- `.planning/PROJECT.md` — v1.11 Hex + continuity vision; lockstep packages

### Release automation (repo)
- `RELEASING.md` — maintainer runbook, publish order, secrets, auto-merge workflow caveats
- `release-please-config.json` — linked-versions, combined PR, package paths
- `.release-please-manifest.json` — per-package released version anchor for RP
- `.github/workflows/release-please.yml` — Release Please + publish job ordering and outputs
- `.github/workflows/release-pr-automation.yml` — auto-merge behavior for release PRs (contrast with **D-06** human gate — planner reconciles docs vs enforced policy)

### Version + dependency sources
- `accrue/mix.exs` — `@version`, `source_ref: "accrue-v#{@version}"`
- `accrue_admin/mix.exs` — `@version`, `source_ref`, `{:accrue, "~> #{@version}"}`

### External (Hex policy)
- `https://hex.pm/docs/faq` — revert window, retire, immutability expectations

### Prior phase tone (doc / verification discipline)
- `.planning/phases/45-docs-telemetry-runbook-alignment/45-CONTEXT.md` — evidence and SSOT split patterns (tone reference for verification brevity)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **Release Please workflow** already encodes **core-first** detection, manifest reads, **`ACCRUE_ADMIN_HEX_RELEASE=1`**, and **lockstep fallback** comments when both packages bump — partial-failure handling in **D-15..D-20** must align with this implementation, not fight it.
- **`source_ref` tags** in both `mix.exs` files match **`accrue-v{version}`** / **`accrue_admin-v{version}`** — verification should assert those tags exist at the shipped SHA.

### Established patterns
- **Linked-versions Release Please** + **single combined PR** is already the repo standard — Phase 46 verifies and documents behavior; minimal workflow redesign unless a plan finds a concrete bug.
- **Pre-1.0** workspace versions (**0.3.0** in manifest at context time) — communicate pre-1.0 semver expectations in verification only where **REL-02** demands clarity for that ship.

### Integration points
- **CI:** `release-gate`, **`verify_package_docs`** (Phase **47** for post-publish doc alignment, but release merge must not knowingly break existing gates on `main`).
- **Hex publish jobs** — second publish depends on first success; treat failures as **D-15** scenarios.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** discuss gray areas in one pass with **subagent research**; decisions above synthesize that research into a **single coherent** maintainer-facing policy aligned with Accrue’s **billing / least-surprise** posture.
- **Human merge** on release PRs (**D-06**) supersedes any “merge when green” convenience if `release-pr-automation` would otherwise auto-merge without maintainer intent — planner should add a **guard** or **doc override** so automation and policy agree.

</specifics>

<deferred>
## Deferred Ideas

- **REL-03** — `RELEASING.md` routine pre-1.0 narrative vs **1.0.0** bootstrap story — **Phase 47**.
- **DOC-01**, **DOC-02**, **HYG-01** — install snippets, `verify_package_docs` outcomes on `main`, planning Hex lines — **Phase 47**.
- **Per-release SBOM / SLSA / signed provenance** as expanded evidence — future hardening milestone unless promoted explicitly; **D-13** / **D-14** keep this out of Phase 46 scope.

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 46-release-train-hex-publish*  
*Context gathered: 2026-04-22*
