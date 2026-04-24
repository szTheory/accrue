# Phase 68: Release train — Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

Execute **REL-01..REL-03** for **v1.19**: ship **`accrue` / `accrue_admin` 0.3.1** (or current manifest version) to Hex via **Release Please** + documented maintainer path so **`accrue` always publishes before `accrue_admin`**; **`mix.exs`**, package **`CHANGELOG.md`**, and Hex agree at the ship boundary; git tags **`accrue-v{version}`** / **`accrue_admin-v{version}`** exist.

**Out of scope:** **DOC-01..02** and **HYG-01** (Phase **69**); **PROC-08** / **FIN-03**; changing release automation architecture unless a task explicitly requires a fix discovered during ship.

</domain>

<decisions>

## Implementation decisions

### D-01 — Release PR merge path (REL-01)

- **Default narrative:** Treat the **combined Release Please PR** like any other PR: **maintainer reviews → required checks green → merge** (human click). That is the **primary** “release train leaves the station” story — least surprise for Elixir/Hex OSS culture and for contributors.
- **Merge queue:** Use GitHub **merge queue** only if the repo already needs it for general **`main`** contention; do not add queue complexity solely for releases.
- **`workflow_dispatch` (`release-pr-automation.yml`):** Document as **optional escape hatch** (e.g. queue merge after review when auto-merge is enabled) — **not** co-equal with manual merge in **`RELEASING.md`**’s default path.
- **Merge strategy:** Pick **one** documented strategy for **`main`** (merge commit vs squash) and keep it stable; Release Please / changelog tooling is sensitive to history shape — avoid undocumented strategy drift.
- **Rationale:** Ecosystems converge on **one obvious artifact = released** (merged version commit + tags + registry). Secondary bots are for **scale/ritual**, not for a small dual-package library unless pain is proven.

### D-02 — REL-03 verification evidence (proof weight)

- **Artifact:** **`68-VERIFICATION.md`** (or equivalent) uses a **single URL-first table** per shipped version — **no screenshots** for routine releases.
- **Columns (minimum):** Package · Version · Hex package URL · Git tag URL · Changelog proof (blob **at tag**, not `main`) · Verified at (UTC) · Optional one-line notes (e.g. admin lagged core).
- **Optional:** HexDocs versioned root URL per package.
- **Do not** rely on ephemeral **Actions run URLs** / logs as primary evidence (rot, login); reserve **rich** evidence (redacted screenshots, incident narrative) for **exceptions** only.
- **Rationale:** Aligns with **Phase 67** verification cadence (checkable, durable) and **Oban-class** infra norms: **registry + tag + changelog** are the proof consumers already trust; screenshots duplicate Hex without increasing falsifiability.

### D-03 — Partial publish / workflow failure (REL-01 order)

- **Normalize:** **`accrue` on Hex, `accrue_admin` not yet`** is a **recoverable** partial state — **not** a revert trigger.
- **Playbook (ordered):** (1) Confirm Hex: core **`V`** present, admin **`V`** absent or failed. (2) **Re-run failed jobs** only (`gh run rerun RUN_ID --failed` or UI). (3) If still broken: **manual `mix hex.publish`** for **`accrue_admin` only** from the **release tag** using the **same steps as CI** (documented in **`RELEASING.md`**). (4) Optional future hardening: **`workflow_dispatch`** “publish admin @ tag” job — only if repeat pain.
- **Hex revert / `--replace`:** Reserve for **genuinely bad core tarball** or policy violation, **inside Hex’s documented time window** when possible; never revert good **`accrue`** because admin failed (strands adopters; repeats **npm left-pad** / **RubyGems yank** lessons: immutability is a supply-chain contract).
- **Communication:** If admin lags core, **changelog or release note** should say so until aligned — integrators must not read “both shipped” when only core is out.
- **Forward-fix:** After consumption is wide, prefer **new patch** over heroic history rewrite.

### D-04 — Changelog boundary (REL-02 + upgrader DX)

- **Single writer for versioned sections:** **Release Please** owns **`mix.exs` bumps** and **new numbered `CHANGELOG.md` sections**; do not maintain a competing manual version block on **`main`**.
- **`Unreleased`:** Allowed only with a strict rule: **freeze or drain when the release PR is cut** so at tag/merge/publish **no `Unreleased` prose describes work already captured under the shipped version** — operational enforcement of REL-02’s “no gap at ship boundary.”
- **Human polish:** **Only on the open release PR branch** (or in **conventional commit bodies** / merge message) — integrators care about **breaking / deprecation / security / Stripe–processor coupling**; put that where RP or reviewers cannot miss it.
- **Per-package paths:** Review **both** `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` on every combined release — **linked-versions** can produce “empty-looking” blocks; that is acceptable noise vs wrong-file logging.
- **Do not** rely on **GitHub Releases alone** as canonical — Hex users expect **`CHANGELOG.md`** in the package tarball.
- **Rationale:** Matches **Keep a Changelog** intent (human-readable, semver-aligned) without fighting RP on every push; aligns with **Pay / Cashier / Stripe** audience expectations: **semver is the contract, changelog + short upgrade note is the labor map.**

### Claude's discretion

- Exact **`68-VERIFICATION.md`** table formatting (extra column order, markdown vs HTML links) as long as every cell is **durable** and **pinned to tag** where applicable.
- Whether to add a **one-command** maintainer check (`mix hex.outdated` / diff helpers) callout in **`RELEASING.md`** vs verification only — whichever fits existing doc tone.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and runbooks

- `.planning/REQUIREMENTS.md` — **REL-01**, **REL-02**, **REL-03**
- `RELEASING.md` — recurring maintainer path, checklist, verification lanes
- `.planning/ROADMAP.md` — Phase **68** row (**v1.19**)

### Automation

- `release-please-config.json` — linked versions, changelog paths, tags
- `.github/workflows/release-please.yml` — publish gates, **`accrue` before `accrue_admin`**
- `.github/workflows/release-pr-automation.yml` — optional merge dispatch (escape hatch)

### Prior phase

- `.planning/phases/67-proof-contracts/67-CONTEXT.md` — proof-first precedent, single-artifact discipline

### Registry

- Hex publish / revert semantics — **`mix hex.publish`** docs on hexdocs.pm and hex.pm publish guide (for recovery playbook wording)

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`RELEASING.md`** + **`release-please-config.json`** already encode linked PR, ordering, and review checklist — Phase **68** implements and verifies, not reinvents.
- **`scripts/ci/gh_merge_release_pr.sh`** — optional merge path already documented.

### Established patterns

- **Human-gated ship** + **automation after intent** matches Accrue’s **trust / evaluator** posture and Elixir OSS norms.
- **Bash + CI gates** elsewhere in repo — recovery playbooks should stay **copy-paste runnable** from **`RELEASING.md`**.

### Integration points

- **GitHub Actions** secrets **`RELEASE_PLEASE_TOKEN`**, **`HEX_API_KEY`** — no changes unless a task discovers a gap.
- **Phase 69** picks up **DOC-** / **HYG-** once Hex reality is **0.3.1**.

</code_context>

<specifics>

## Specific ideas

- Cross-ecosystem research synthesis (**subagents, 2026-04-23**): **Changesets**-style “human merges Version PR” beats **semantic-release surprise** for DX; **Rust tag = release** culture reinforces URL+tag evidence; **npm left-pad** / registry immutability lessons reinforce **never revert good core because admin lagged**.

</specifics>

<deferred>

## Deferred ideas

- **DOC-01..02**, **HYG-01** — Phase **69** only.
- **Idempotent “skip publish if version exists”** in workflows — optional hardening if partial-publish pain repeats; not required to close REL unless CI proves flaky.

</deferred>

---

*Phase: 68-release-train*  
*Context gathered: 2026-04-23*
