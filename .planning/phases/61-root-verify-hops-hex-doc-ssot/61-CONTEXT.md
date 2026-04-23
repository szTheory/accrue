# Phase 61: Root VERIFY hops + Hex doc SSOT - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

**INT-08:** Repository **`README.md`** keeps **v1.7 / ADOPT-01** intent: **VERIFY-01** / **`host-integration`** discoverable within the **documented hop budget** after **v1.15** (and later) README growth; if the contract tightens or moves, **verifiers** and **README** change in the **same change set** (no silent drift).

**INT-09:** **`verify_package_docs`**, **`accrue/guides/first_hour.md`**, **`accrue/README.md`**, and **`accrue_admin/README.md`** stay aligned with **`accrue/mix.exs`** / **`accrue_admin/mix.exs`** **`@version`** on the branch under test; **`.planning/PROJECT.md`** / **`.planning/MILESTONES.md`** “current Hex” callouts follow **HYG-style** honesty when **`@version`** moves during the milestone.

**Not in this phase:** New billing APIs, **PROC-08**, **FIN-03**, VERIFY policy renames, full CI graph rewrites, or new third-party UI.

</domain>

<decisions>

## Implementation decisions

Cross-cutting: these decisions are **one package** — they align **ADOPT-01** (evaluator hop budget), **INT-08** (README ↔ verifier lockstep), **INT-09** (dual timeline: branch vs Hex), **Phase 59** (pins + banners + `verify_package_docs` SSOT), and **Phase 60** (contributor map is registry SSOT, not a fourth bash entrypoint).

### 1 — Root README IA + hop budget (INT-08, ADOPT-01)

- **D-01 (hybrid — recommended default):** Keep the **root `README.md`** **Proof path (VERIFY-01)** block as the **always-visible, copy-pasteable** surface for the **merge-blocking local gate** (`cd examples/accrue_host && mix verify.full`, `host-integration`, named bash shift-left scripts). Treat **`examples/accrue_host/README.md`** (especially **`#proof-and-verification`**) as the **narrative SSOT** for Playwright paths, matrix links, and UAT-shaped detail. Matches common **Elixir OSS** pattern: repo root = product + front-door commands; **example host** = integration lab.

- **D-02 (micro hop map — conditional):** If future README growth **buries** the proof path, add a **tiny** hop map (about **three bullets**, or ≤5–7 lines): root → host proof anchor → (optional) **`CONTRIBUTING.md`** / **`scripts/ci/README.md`** triage — **not** a second copy of the host README. Prefer **heading / ordering** fixes before new prose.

- **D-03 (machine verification — narrow):** Encode **invariants** only: required **substrings**, **merge-blocking job id**, **critical relative links / anchors**, and **copy-paste command** presence. **Do not** enforce arbitrary prose length or “hop counting” semantics beyond what **ADOPT-01** already states in human docs — avoids brittle READMEs and fights good UX.

### 2 — Where README contracts live (INT-08, verifier split)

- **D-04 (`verify_package_docs.sh` owns root + packages + cross-file pins):** **Root `README.md`** VERIFY / `host-integration` discoverability and **package / guide** literal alignment (including **existing** host README **structural** pins already in this script) stay here. Merge-blocking path: **`cd accrue && mix test`** in **`release-gate`** via **`accrue/test/accrue/docs/package_docs_verifier_test.exs`**.

- **D-05 (`verify_verify01_readme_contract.sh` owns host VERIFY-01 depth):** **Dynamic** `e2e/verify01-*.spec.js` discovery, **file existence**, **`sk_live`** semantic guard, and other **host-only** law stay in **`verify_verify01_readme_contract.sh`**, **first** step of **`host-integration`** (shift-left before BEAM/Node/Playwright). Keeps **blast radius** and **cost** appropriate to each job.

- **D-06 (no third user-facing README script):** **Do not** add a separate **`verify_root_readme_*.sh`** (or similar) for Phase **61** — contributor mental model stays **`scripts/ci/README.md`** + Phase **60** INT registry rows, not a longer “bash quartet.” If bash grows unwieldy, **refactor internally** (`source`d helpers), not new CI entrypoints.

- **D-07 (dedupe overlap):** Audit **duplicate `require_fixed`** on the **same** host README line between **`verify_package_docs`** and **`verify_verify01`**. **Rule:** **semantic / dynamic / VERIFY-01 section law** → **`verify_verify01`**; **cross-package doc graph / version pins** → **`verify_package_docs`**. Remove duplicate needles once ownership is clear.

### 3 — Planning doc mirrors: Hex vs `main` (INT-09)

- **D-08 (two claims, two authorities):** Treat **install literals** on the branch under test as authoritative for **`mix.exs` `@version`** (enforced by **`verify_package_docs`**). Treat **“Public Hex (last published)”** (or equivalent) in **`.planning/PROJECT.md`** / **`.planning/MILESTONES.md`** as authoritative for **registry reality** — updated on **successful publish** or explicit **HYG** ritual, **not** on every unrelated doc commit.

- **D-09 (explicit two-line pattern in planning):** Keep (or add) a **short, stable** pattern: workspace **`@version`** may read **X** ahead of Hex; **last published** pair **Y** — so readers never confuse **internal milestone labels**, **SemVer on `main`**, and **Hex artifacts**. Link **https://hex.pm/packages/accrue** (and admin) for browsing.

- **D-10 (no collapsed SSOT):** Do **not** maintain planning prose that implies **Hex == `main`** without saying so. **INT-09** satisfaction is **honesty + mirror updates when the relationship changes**, not deleting the dual-track story.

### 4 — `first_hour` + package READMEs when `@version` leads Hex (INT-09, Phase 59 continuity)

- **D-11 (retain branch-honest pins):** **Continue Phase 59:** **`{:accrue, "~> $version"}`** style pins follow **`extract_version` / `@version`**; **Hex vs `main`** banners stay wherever copy-paste deps appear. **Never** label an unpublished semver as **“released on Hex.”**

- **D-12 (document the sharp edge once):** After a **version bump on `main`** and **before** `mix hex.publish`, it is **expected** that **Hex-only** `mix deps.get` may fail against copy-paste pins — **structural honesty**, not CI noise. Document in **First Hour** (banner already) and optionally **one** **`CONTRIBUTING.md`** line: use **`path:`** / **git ref** or **wait for publish**. Process (release branch, bump timing) can narrow the window; **dual contradictory literals** must not.

### Claude's discretion

- Exact **hop map** wording and placement if D-02 triggers.
- Whether **D-07** dedupe is done in the same PR as INT-08 README tweaks or immediately after — order only.
- Optional follow-up: small **ExUnit** harness invoking **`verify_verify01_readme_contract.sh`** (mirror **`package_docs_verifier_test.exs`**) — **defer** unless that script churns without test safety.

### Folded todos

*(None.)*

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Requirements and planning

- `.planning/REQUIREMENTS.md` — **INT-08**, **INT-09**
- `.planning/ROADMAP.md` — Phase **61** goal and success criteria (**v1.16**)
- `.planning/PROJECT.md` — Core value, v1.16 theme, **Hex vs `main`** positioning
- `.planning/MILESTONES.md` — Milestone narrative; **Public Hex** callouts

### v1.7 adoption contract (hop budget SSOT)

- `.planning/milestones/v1.7-REQUIREMENTS.md` — **ADOPT-01** (two hops from root README to VERIFY-01 runnable instructions)

### Prior phase continuity

- `.planning/phases/59-golden-path-quickstart-coherence/59-CONTEXT.md` — **INT-06** pins, banners, bash trio, **`verify_package_docs`** role
- `.planning/phases/60-adoption-proof-ci-ownership-map/60-CONTEXT.md` — **INT-07** contributor map; explicit handoff that Phase **61** owns INT-08/09

### Verifiers, CI, contributor map

- `scripts/ci/verify_package_docs.sh` — root + package + guide literal SSOT
- `scripts/ci/verify_verify01_readme_contract.sh` — host README VERIFY-01 depth
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` — ExUnit wrapper for package docs verifier
- `.github/workflows/ci.yml` — **`release-gate`** vs **`host-integration`** job split
- `scripts/ci/README.md` — ADOPT / INT / ORG registry (**do not** supersede with ad-hoc bash folklore)
- `README.md` (repository root) — proof path front door
- `examples/accrue_host/README.md` — VERIFY-01 narrative SSOT

### Doc surfaces under INT-09

- `accrue/guides/first_hour.md`
- `accrue/README.md`
- `accrue_admin/README.md`
- `accrue/mix.exs` / `accrue_admin/mix.exs` — **`@version`** SSOT

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`scripts/ci/verify_package_docs.sh`:** Already pins root **`README.md`** proof headings, **`host-integration`**, script paths, **`proof-and-verification`**, and **`Hex vs `main``** blocks across package docs — extend **only** with paired INT-08 intent, not duplicate **`verify_verify01`** semantics.
- **`scripts/ci/verify_verify01_readme_contract.sh`:** Host-only **dynamic** and **semantic** checks — keep as the **cheap first step** of **`host-integration`**.
- **`scripts/ci/README.md` + Phase 60 INT table:** Single contributor-facing map for **which script owns which REQ-ID**.

### Established patterns

- **Split gates by cost and blast radius:** doc needles + **`mix test`** in **`release-gate`** vs host README law before Node/Playwright in **`host-integration`**.
- **Bash needles + optional ExUnit** for cross-cutting markdown — idiomatic for monorepo **doc-as-contract** in this repo.

### Integration points

- Any change to **root proof IA** must update **`verify_package_docs.sh`** (and tests if literals change).
- Any change to **host VERIFY-01** prose, **Playwright** spec inventory, or **dangerous** `sk_live` guidance must update **`verify_verify01_readme_contract.sh`** in lockstep.

</code_context>

<specifics>

## Specific ideas

- Research synthesis (2026-04-23): **Rails/Laravel** patterns favor **dummy/example app** as operational SSOT with **one obvious command** from the gem/package README — Accrue’s **`examples/accrue_host`** matches that. **Stripe/Twilio**-class SDKs emphasize **README quickstart + deep central docs** — aligns with **thin evaluator path + deep host README**. **Phoenix/Oban/LiveView**-style OSS favors **GitHub `main` explicitly “may be ahead”** + **HexDocs for stable reading** — supports **dual-track** messaging without collapsing timelines.

</specifics>

<deferred>

## Deferred ideas

- **Hex API or release-only check** comparing registry latest to planning “last published” — only if manual HYG drift becomes painful (**non-blocking** for Phase **61** unless requirements expand).
- **Internal `source` refactor** of bash fragments if **`verify_package_docs.sh`** grows past maintainability — not a new public script name.

### Reviewed todos (not folded)

*(None.)*

</deferred>

---

*Phase: 61-root-verify-hops-hex-doc-ssot*  
*Context gathered: 2026-04-23*
