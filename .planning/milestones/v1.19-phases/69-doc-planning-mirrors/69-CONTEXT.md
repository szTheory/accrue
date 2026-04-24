# Phase 69: Doc + planning mirrors — Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

Close **DOC-01**, **DOC-02**, and **HYG-01** for **v1.19** after **0.3.1** on Hex: **`first_hour.md`** and package README **primary `~>` install lines** match **`mix.exs` `@version`** and **`verify_package_docs`**; **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, and **`.planning/STATE.md`** reflect **actual** published **`accrue` / `accrue_admin`** versions and current phase/milestone posture.

**Out of scope:** **PROC-08** / **FIN-03**; release train mechanics (**68-CONTEXT**); proof-matrix contracts (**67-CONTEXT**); opportunistic prose/voice rewrites across the repo; refactors of doc-contract tests unless a failing check forces the minimum fix.

</domain>

<decisions>

## Implementation decisions

### D-01 — Scope: HYG vs integrator-facing docs (research: planning SSOT vs adopter surfaces)

- **HYG-01 (traceability):** Treat **only** `.planning/PROJECT.md`, `.planning/MILESTONES.md`, and `.planning/STATE.md` as the HYG deliverable — per **`.planning/REQUIREMENTS.md`**. Do **not** expand HYG into an unbounded “version sweep” of the whole tree under that heading.
- **DOC-01 / DOC-02:** Own **integrator-facing** continuity: **`accrue/guides/first_hour.md`**, **`accrue/README.md`**, **`accrue_admin/README.md`**, and anything **`scripts/ci/verify_package_docs.sh`** already enforces (including paths it touches today, e.g. host README capsules, root files where the script asserts needles). Those surfaces are **contract-bound**, not discretionary.
- **Separation of concerns:** Internal **`.planning/`** continuity (HYG) vs **copy-paste / first-hour** truth (DOC) — same numeric facts in both layers, but **reviews stay scoped**: planning PR section vs doc/CI section.
- **Rationale:** Mature Hex libraries keep **`mix.exs` `:version`** and merge-blocking doc checks as the **adopter SSOT**; `.planning/` is **maintainer SSOT**. Mixing “HYG means grep the repo” creates churn and review load without a requirement ID. Expanding **without** an allowlist is a classic scope footgun (Pay/Cashier lesson: **install lines are contracts** — enforce them in **one** verifier, not in three essays).

### D-02 — Tone and structure: minimal facts vs narrative parity (research: cognitive load + contradiction risk)

- **`.planning/PROJECT.md`:** Keeps **long-form** mission, **Current milestone**, **Current State**, and shipped history — this file **owns narrative depth** for maintainers.
- **`.planning/STATE.md`:** **Short**, YAML frontmatter + **Current Position** + pointers. On each publish-aligned update: bump **facts** (dates, versions, phase pointer, `last_updated`) and **one-line position**; **do not** duplicate PROJECT’s full milestone blurb.
- **`.planning/MILESTONES.md`:** **Milestone-level** retrospective (theme, accomplishments, status). For a **patch publish** inside an active milestone: **minimal factual** updates (e.g. v1.19 block: phases complete, “next” line, Hex line). Reserve **large narrative blocks** for **milestone close** / archive moments — do not require **narrative parity** with PROJECT on every doc phase.
- **Contradiction control:** Prefer **links** to **`ROADMAP.md`**, **`REQUIREMENTS.md`**, and phase **`*-VERIFICATION.md`** over repeating the same paragraph in three files. Where a fact appears twice, use the **same wording** (copy from one canonical sentence).
- **Rationale:** Stripe-style split: **reference/behavior** vs **marketing**; for Accrue, **verify_package_docs** + **mix.exs** are behavioral SSOT for pins; planning files **summarize** and must not fork a fourth conflicting story.

### D-03 — DOC-02: `verify_package_docs.sh` ↔ `package_docs_verifier_test.exs` (research: single authority, drift footguns)

- **Single authority:** **`scripts/ci/verify_package_docs.sh`** defines what “verified” means for package docs; **CI and ExUnit both invoke this script** — do **not** reimplement checks in Elixir.
- **ExUnit role:** **Harness + regression**: exit codes, stable **`[verify_package_docs]`** failure prefix, **key path tokens** per negative scenario, and the **success banner** line — **not** a duplicate of every `require_fixed` / `require_regex` needle in bash.
- **Change order:** When contracts move, edit **bash first**, then **ExUnit only** where (a) success banner / high-signal output changed, (b) a **`fail "..."`** message changed, or (c) a **new** `ROOT_DIR` path requires fixture files. Avoid “needle-only” churn in ExUnit that does **not** correspond to script behavior.
- **Footguns to avoid:** Tests that assert stale stdout while the script still exits 0; incomplete **tmp fixture trees** vs real repo layout; different **cwd / `ROOT_DIR`** between local and CI.
- **Future (out of phase unless pain proves):** A small **machine-readable manifest** of named checks could DRY bash and tests — **defer** unless duplication becomes a measured problem.

### D-04 — Capsules: pins vs prose (research: Cashier/Pay/Stripe quickstarts + least surprise)

- **Pins:** **`{:accrue, "~> $version"}`** / **`{:accrue_admin, "~> $version"}`** in **First Hour** and **host README capsules** stay **CI-enforced** and tied to **`mix.exs` `@version`** — **non-negotiable** on every publish-aligned pass.
- **Prose / voice:** **Do not** rewrite capsule narrative for style on each release. Touch prose **only** when integrator **semantics** change (defaults, prerequisites, policy) or to fix **incorrect** claims.
- **Pre-1.0 / semver posture:** Keep **one canonical** short block (already aligned with **first_hour** rules like “pins track Hex-published line”) — **link** to **CHANGELOG** / upgrade guides for labor, not duplicate long warnings in every capsule unless contract-tested.
- **Shape:** Capsules stay **copy-paste minimal**: dep lines + **1–2 lines** of scope + **links** to guides (webhooks, raw body, env) — matches **great DX**: correct resolver behavior first, deep detail behind stable URLs.

### Claude's discretion

- Exact **one-line** wording in **STATE** / **MILESTONES** status bullets as long as facts match **Hex** + **branch `@version`** and **ROADMAP** phase table.
- Whether a given **MILESTONES** update is “one line” vs “short paragraph” for **v1.19** closure — prefer **shorter** unless the milestone is being archived in the same change set.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **DOC-01**, **DOC-02**, **HYG-01**
- `.planning/ROADMAP.md` — Phase **69** row (**v1.19**)

### Contracts (SSOT for integrator-facing pins)

- `scripts/ci/verify_package_docs.sh` — authoritative needles and **`ROOT_DIR`** behavior
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — ExUnit harness + negative scenarios
- `accrue/mix.exs`, `accrue_admin/mix.exs` — **`@version`** pair (must stay lockstep)

### Guides and READMEs (DOC-01 surfaces)

- `accrue/guides/first_hour.md` — Capsule H/M/R + primary pins
- `accrue/README.md`, `accrue_admin/README.md` — primary install lines + Hex vs `main` callouts
- `examples/accrue_host/README.md` — host capsules where enforced by verifier

### Prior phase context

- `.planning/phases/68-release-train/68-CONTEXT.md` — release train boundary; **DOC/HYG deferred** to Phase **69**
- `.planning/phases/67-proof-contracts/67-CONTEXT.md` — proof-first / contract-test discipline

### Project voice

- `.planning/PROJECT.md` — mission, **Current milestone**, **Current State**, Hex callouts

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`verify_package_docs.sh`** already extracts **`accrue_version`** / **`accrue_admin_version`** from **`mix.exs`** and asserts README + **first_hour** lines — Phase **69** aligns content with that machinery; do not bypass it.
- **`PackageDocsVerifierTest`** runs the script and uses **fixture trees** under **`ROOT_DIR`** for negative cases — extend fixtures when the script gains new paths, not ad hoc.

### Established patterns

- **Bash verifier + ExUnit** “contract test” split matches Accrue’s **shift-left** doc posture (**Phase 63** comment in verifier test).
- **Lockstep dual-package** versioning is already enforced in the script (`versions diverged` fail).

### Integration points

- **`docs-contracts-shift-left`** CI job (see **`.github/workflows`** and root **`README.md`** contributor map) must stay green after edits.

</code_context>

<specifics>

## Specific ideas

- User requested **subagent research** across ecosystem (Pay, Cashier, Stripe patterns), **idiomatic Elixir/Hex** SSOT, and **one-shot cohesive recommendations** — captured as **D-01..D-04** above (minimal planning diffs, bash-first verifier changes, pin-first capsules, strict HYG vs DOC boundary per requirements).

</specifics>

<deferred>

## Deferred ideas

- **Machine-readable manifest** for doc needles shared by bash and ExUnit — only if duplication becomes painful (**D-03**).
- **Expanded planning-adjacent sweeps** beyond **HYG-01**’s three files — requires a **new requirement ID**, not Phase **69**.

### Reviewed Todos (not folded)

- None — **`todo.match-phase 69`** returned no matches.

</deferred>

---

*Phase: 69-doc-planning-mirrors*  
*Context gathered: 2026-04-23*
