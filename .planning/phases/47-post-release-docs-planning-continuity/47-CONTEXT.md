# Phase 47: Post-release docs & planning continuity - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **REL-03**, **DOC-01**, **DOC-02**, and **HYG-01** after the Hex train: **no evaluator confusion** between **Hex-published versions**, **repo `mix.exs` / changelogs**, **primary install docs** (`first_hour` and anything `verify_package_docs` treats as contract), **maintainer runbook** (`RELEASING.md`), and **planning callouts** (`.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/STATE.md`). Phase verification cites **concrete file paths**.

**Explicitly not this phase:** New billing features, release automation redesign (Phase **46**), or choosing the next implementation milestone beyond hygiene.

</domain>

<decisions>
## Implementation Decisions

### 1 — `RELEASING.md` structure (**REL-03**)

- **D-01:** **Routine path first.** The default reader is a maintainer doing the *n*th **pre-1.0 linked** Release Please release, not the one-time bootstrap. Open with a **short ordered happy path**: green checks → Release Please PR review → merge → **publish order** `accrue` then `accrue_admin` → minimal post-publish verification pointers (Hex, tags, HexDocs).
- **D-02:** **Bootstrap narrative second.** Move the **same-day `1.0.0`** (or historic first-ship) story to a **clearly titled appendix** at the end of `RELEASING.md`, *or* to a linked doc (e.g. `guides/releasing-bootstrap.md`) with `RELEASING.md` retaining a one-screen routine spine and a link — **do not** let bootstrap compete visually with the recurring checklist.
- **D-03:** **Mitigate appendix staleness** with a single “last verified against workflow/config at …” line and links to `release-please-config.json` / `.release-please-manifest.json` / `.github/workflows/release-please.yml` rather than duplicating Release Please–owned policy prose.
- **D-04:** **Do not** split into many peer files without a single obvious entry point — discoverability beats micro-files for OSS maintainers.
- **D-05:** **Verifier coupling:** `scripts/ci/verify_package_docs.sh` asserts fixed substrings in `RELEASING.md` (lanes, trust pointer, secrets, `release-gate`, etc.). Any restructure **must** update the script **in the same change** so CI stays green — treat verifier strings as part of the **public contract** of that doc.

### 2 — Primary install snippets (**DOC-01**)

- **D-06:** **`first_hour.md` (and README hero snippets already enforced by the verifier)** use **the same concrete `~>` for both packages**, derived from **`accrue/mix.exs` `@version`** after ship — e.g. `{:accrue, "~> 0.3.2"}` and `{:accrue_admin, "~> 0.3.2"}` when `@version` is `0.3.2`.
- **D-07:** **Prefer three-part `~> X.Y.Z`** (not bare `~> 0.3`) in **getting-started** copy: pre-1.0 `~> 0.3` in Mix allows **`0.3.0` through `< 1.0.0`**, which contradicts strict pre-1.0 discipline and the **lockstep pair** story; three-part pins match “tested together” and still allow **patch** bumps inside the minor.
- **D-08:** Add **one short prose block** near the deps snippet: pre-1.0 minors may be breaking; **admin version should match core** for the shipped train; patch updates within the pinned minor are the expected safe path.
- **D-09:** **`path:` / `github:`** for contributors belongs in **CONTRIBUTING** or a secondary subsection — **not** the default “First Hour” path for evaluators.

### 3 — Planning continuity (**HYG-01**)

- **D-10:** **Atomicity with the release train.** Update `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/STATE.md` lines that state **last published Hex** / current package versions **on the same merged unit** as doc + verifier updates: **prefer the release PR** (or a final docs-only commit **stacked on that PR** before/at the tag), not a “we’ll fix planning next week” follow-up.
- **D-11:** **SSOT remains** `mix.exs` + Hex + tags; planning files are **human/agent-facing mirrors** — they must not be the only place versions live, but they **must not lag** Hex once the tag exists.
- **D-12:** **Exception — allow a fast-follow hygiene PR** only when: release merge was **urgent** and planning edits were not ready **same day**; planning change is **large** (re-roadmap); or policy forbids touching `.planning/` on release branches. If used: **same day**, linked issue, and treat omission as **process debt** not the default.

### 4 — Doc verification depth (**DOC-02**)

- **D-13:** **Mandatory merge-blocking proof** for Phase **47** closure: **`scripts/ci/verify_package_docs.sh`** passes on **`main`** after release merge **and** **`accrue/test/accrue/docs/package_docs_verifier_test.exs`** passes — these encode cross-file invariants (READMEs, guides, host README, `RELEASING.md` anchors, job names, webhook wording, etc.).
- **D-14:** **Treat existing CI `mix docs --warnings-as-errors`** (`.github/workflows/ci.yml` — Accrue + Accrue admin docs jobs) as part of the **DOC-02** “no silent doc rot” bar; Phase **47** verification references those jobs — **no new requirement** unless CI regresses.
- **D-15:** **Do not** require subjective badge HTTP checks or wiki review as **merge-blocking** Phase **47** evidence — badges and off-repo surfaces rot for reasons outside repo control; keep them **optional** maintainer polish.
- **D-16:** **Optional 5-minute maintainer ritual** (not encoded in REQ unless desired later): glance Hex.pm package pages + root README render after tag — catches optics the grep suite cannot see.

### 5 — Cross-cutting coherence (vision + least surprise)

- **D-17:** **One story end-to-end:** “Merged release PR / tag → Hex shows **V** → repo `mix.exs` **V** → `first_hour` **~> V** → planning says **V** → verifier + docs CI agree.” Anything that breaks that chain is **out of scope for “done”**.
- **D-18:** **DX for integrators:** copy-paste from `first_hour` resolves on Hex **today**; no `main` / floating version as the default happy path.
- **D-19:** **DX for maintainers:** `RELEASING.md` answers “what do I do **this** Tuesday?” in the first screen; rare bootstrap is discoverable but not in the way.

### Claude's Discretion

- Exact appendix title and whether bootstrap lives in-repo vs `guides/` only.
- Wording of the pre-1.0 semver + lockstep explainer (tone, length).
- Whether to add a **curated** optional link checker later (stretch, not Phase **47** unless scoped in plan).

### Folded Todos

_None._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — **REL-03**, **DOC-01**, **DOC-02**, **HYG-01** (Phase **47**)
- `.planning/ROADMAP.md` — Phase **47** goal and success criteria (table row + `<details>`)
- `.planning/PROJECT.md` — v1.11 milestone; Hex continuity expectations

### Prior phase (release train — do not contradict)
- `.planning/phases/46-release-train-hex-publish/46-CONTEXT.md` — **REL-01/02/04** boundaries; human gate; partial publish recovery; what Phase **46** already locked

### Maintainer + automation (files Phase **47** edits)
- `RELEASING.md` — runbook structure target (**D-01..D-05**)
- `release-please-config.json` — linked packages, changelog paths
- `.release-please-manifest.json` — per-package released versions
- `.github/workflows/release-please.yml` — publish ordering, outputs
- `accrue/guides/first_hour.md` — primary install story (**DOC-01**)
- `accrue/README.md`, `accrue_admin/README.md` — verifier-enforced install lines
- `scripts/ci/verify_package_docs.sh` — doc/version contract (**DOC-02**)
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — ExUnit harness for verifier
- `.github/workflows/ci.yml` — `mix docs --warnings-as-errors` jobs (**D-14**)

### Planning hygiene targets
- `.planning/MILESTONES.md` — shipped / archive callouts if present
- `.planning/STATE.md` — current phase + “last published Hex” lines

### External
- `https://hex.pm/docs/faq` — immutability / retire (context for “wrong version on Hex” messaging; already referenced from Phase **46**)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets
- **`verify_package_docs.sh`** already enforces **lockstep `@version`**, **`source_ref`** shapes, **README** `~>` lines for both packages, and many **cross-doc fixed strings** — Phase **47** implementation is mostly **content reordering + version bumps + planning lines** with **script updates when strings move**.
- **`package_docs_verifier_test.exs`** copies fixtures and asserts failures — extend when new invariants are added to `first_hour` or `RELEASING.md`.

### Established patterns
- **CI** already runs **`mix docs --warnings-as-errors`** per package — align Phase **47** verification language with existing jobs rather than inventing a parallel doc gate.
- **Release Please + manifest** is the numeric SSOT (Phase **46**); docs and planning are **downstream consumers** of the merged version.

### Integration points
- **`RELEASING.md`** currently includes a **fixed-path** requirement for `15-TRUST-REVIEW.md` via the verifier — if that artifact is **moved or renamed**, Phase **47** (or a tight prerequisite commit) must **reconcile path or verifier** so **`main` stays green**.

</code_context>

<specifics>
## Specific Ideas

- User requested **research-backed, one-shot recommendations** for all four gray areas (subagent synthesis **2026-04-22**): routine-first releasing; **three-part `~>`** lockstep snippets; **atomic** planning updates with the release train; **verifier + existing docs CI** as mandatory bar, optional maintainer glance for optics.

</specifics>

<deferred>
## Deferred Ideas

- **HTTP / shields.io badge verification** in CI — optional stretch; not required for **DOC-02** closure per **D-15**.
- **Splitting `RELEASING.md` into multiple top-level files** without a single front door — deferred unless maintainability forces it (**D-04**).

### Reviewed Todos (not folded)

_None._

</deferred>

---

*Phase: 47-post-release-docs-planning-continuity*  
*Context gathered: 2026-04-22*
