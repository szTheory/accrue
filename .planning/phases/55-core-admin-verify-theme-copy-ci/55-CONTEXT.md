# Phase 55: Core admin VERIFY + theme + copy CI - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase boundary

Deliver **ADM-09** (merge-blocking **Playwright + axe** on the **ADM-08** invoice anchor: `/invoices`, `/invoices/:id`), **ADM-10** (honest **`theme-exceptions.md`** for intentional deviations introduced or discovered in this work), and **ADM-11** (**`mix accrue_admin.export_copy_strings`**, **`copy_strings.json`**, CI allowlists — bounded to the **invoice VERIFY closure**, no drive-by churn).

**Out of scope:** new capabilities, VERIFY policy renames, URL-matrix crawls, merge-blocking expansion to other core rows without **54-CONTEXT D-09** amendment, **PROC-08**, **FIN-03**, new UI kits (**55-UI-SPEC**, **54-CONTEXT**).

</domain>

<decisions>

## Implementation decisions

*Cross-agent research synthesis (2026-04-23): VERIFY↔doc traceability, Playwright flake policy, copy-export hygiene, theme SSOT — folded into one coherent maintainer contract aligned with **54-CONTEXT**, **55-UI-SPEC**, and **Phase 53** lessons.*

### 1 — Named VERIFY flow ids + `core-admin-parity.md` sync (**ADM-09**)

- **D-01 (canonical ids — lock to UI-SPEC):** Use exactly **`core-admin-invoices-index`** and **`core-admin-invoices-detail`** as the **Named VERIFY flow id** values for the invoice matrix rows. These are the **machine ids** (grep targets, CI guards), not URLs — reference them in prose with inline code (`` `...` ``) to avoid spurious linkification.
- **D-02 (future ids):** Additional core flows in later work follow **`core-admin-<surface>-<role>`** (lowercase kebab, stable, locale-agnostic) unless **55-UI-SPEC** is amended.
- **D-03 (Playwright binding):** **One** top-level entry per flow id — either a **file** dedicated to that flow suite **or** a top-level `test.describe` whose **title or tag** equals the canonical id (Playwright **tags** `@core-admin-invoices-index` are recommended for HTML report filters). Nested `describe` / `test.step` blocks stay free-form.
- **D-04 (matrix flip rule):** When merge-blocking specs land for a row, set **`Named VERIFY flow id`** to the canonical string and **`VERIFY-01 lane`** to **`merge-blocking`** in the **same** change-set as the tests (**54-CONTEXT D-03** honest inventory).
- **D-05 (CI / drift guard — recommended):** Add a lightweight check (script or `rg`-based in CI docs) that **every** `merge-blocking` invoice row’s id appears in the host VERIFY tree, and that **no orphan** `@core-admin-*` tags exist without a matrix row (direction can start **matrix → tests** until coverage complete; tighten bidirectionally when cheap).
- **D-06 (avoid footguns):** Do not use **English sentences alone** as ids; pick **one** case convention (**lowercase kebab**); do not bind **every** nested `describe` to the matrix — only **verify entrypoints**.

### 2 — PDF / new tab / download in merge-blocking VERIFY (**ADM-09**)

- **D-07 (tiered contract — least surprise for `main`):** **Merge-blocking** proves the **billing record UI** and **accessible wiring** of document actions (names from **Copy** / **`copy_strings.json`**, controls **visible + enabled** after LiveView quiescence, **no thrown errors** on primary click). **axe** remains **serious + critical**, **light + dark**, **desktop** projects only — unchanged posture (**55-UI-SPEC**, match existing customers/subscriptions skips for mobile).
- **D-08 (strict binary / popup / tab — optional layer):** **Popup** (`waitForEvent('popup')` **before** click), **download** (`Promise.all` with `waitForEvent('download')`), or **`%PDF` magic-byte** assertions are **encouraged** when the harness is **deterministic** (Fake-backed fixture data, bounded PDF generation, or static bytes / stubbed route). Prefer **`domcontentloaded`** + web-first assertions over **`networkidle`** as the default wait strategy on LiveView surfaces.
- **D-09 (when *not* merge-blocking):** **Full** PDF layout, pixel/visual diff, ChromicPDF **cold-start** gymnastics, or **Chromium PDF viewer chrome** may **not** block **`main`** if they remain **environment-heavy** after an honest bounded attempt — but **never** silently downgrade: document in **`core-admin-parity.md`** (VERIFY column note), **`examples/accrue_host` README or VERIFY doc**, or an **explicit advisory** step label in the spec. **Silent** `try/catch → pass` is **forbidden**.
- **D-10 (a11y scope):** Merge-blocking **a11y** targets **HTML admin surfaces** + **action control semantics** (roles, names, `aria-describedby` per **55-UI-SPEC**). Do **not** gate **`main`** on **PDF/screen-reader document structure** unless the project later adopts an explicit accessible-PDF pipeline.
- **D-11 (contributor DX):** Use **`test.step`** for **trace readability** and scoped timeouts — **not** as a substitute for correct event ordering. Retain **traces / artifacts on failure** per existing host patterns.

### 3 — `export_copy_strings`, `copy_strings.json`, CI allowlists (**ADM-11**)

- **D-12 (hybrid pipeline — Phase 53 + least churn):** Keep **canonical CI order**: **`assets.build` → `mix accrue_admin.export_copy_strings` → Playwright** (same family as **`scripts/ci/accrue_host_verify_browser.sh`**). **Commit** `examples/accrue_host/e2e/generated/copy_strings.json` **only** when **invoice-anchor VERIFY** keys, **allowlist**, or backing **Copy** sources for those keys change — **no drive-by regeneration** when unrelated Copy modules move (**54-CONTEXT D-15**, **55-UI-SPEC**).
- **D-13 (allowlist as contract):** The Mix task **allowlist** defines which exported keys **VERIFY / host** may consume. Grow it **only** when specs or documented host consumers reference new `copyStrings.*` paths — not “every new Copy function repo-wide.”
- **D-14 (determinism — non-negotiable):** Export output must be **stable** (sorted keys, stable EOF newline, no locale-dependent ordering) so diffs are meaningful and rebases are predictable.
- **D-15 (optional hardening — planner may schedule):** After export in CI, **`git diff --exit-code`** on `copy_strings.json` catches **committed vs generator** drift without relying on “CI always regenerates invisibly” alone — adopt when the team wants **audit-grade** parity between committed artifact and CI output.
- **D-16 (sharding):** Stay on **one** `copy_strings.json` unless merge conflicts on that file become a measured problem — then split **by VERIFY suite** (e.g. invoice shard) rather than ad hoc churn (**research: optional D**).

### 4 — Theme exceptions + contributor doc SSOT (**ADM-10**)

- **D-17 (single SSOT):** **`accrue_admin/guides/theme-exceptions.md`** is the **only** exception **register** for package consumers and Hexdocs. **`.planning/`** carries **decision traceability** only — link **out** to guide anchors / slugs; do **not** maintain a competing living table under `.planning/phases/26-*` as SSOT.
- **D-18 (row discipline):** Add **new** exception rows **only** for **intentional** deviations **introduced or honestly discovered** during **ADM-08 / ADM-09 / ADM-11** work — prefer **token fixes** when trivial (**54-CONTEXT D-10** spirit). Each row keeps **slug, location, deviation, rationale, future_token, status, phase_ref** (**55-UI-SPEC**).
- **D-19 (link hygiene — same phase, not scope creep):** Fix **stale** contributor paths (e.g. **`accrue_admin/guides/admin_ui.md`** still pointing at **`.planning/phases/26-.../26-theme-exceptions.md`**) to **`guides/theme-exceptions.md`** in **Phase 55** — classified as **SSOT / ADM-10 hygiene**, not “new exceptions.”
- **D-20 (footguns):** Avoid **two registers**; avoid **planning-only** SSOT for tokens; avoid **junk-drawer** rows without rationale + exit path.

### 5 — Cross-cutting (coherence with Accrue’s vision)

- **D-21 (operator + evaluator trust):** **`main` green** means **money-primary invoice UI** and **accessibility serious/critical** are trustworthy; **document delivery** depth follows **D-07–D-09** so flakes do not erode confidence.
- **D-22 (OSS / Hex DX):** Every decision above must work for **package-only clones** (guides ship in **`accrue_admin`**, not hidden under **`.planning/`**).
- **D-23 (VERIFY policy unchanged):** Merge-blocking vs advisory **semantics** stay as milestone baseline (**54-CONTEXT D-22**); Phase 55 **implements** planned coverage for the invoice anchor — it does not redefine policy.

### Claude's discretion

- Exact **CI script** structure for **D-05** (`rg` vs small Node/Elixir verifier) as long as **matrix ↔ specs** cannot silently drift.
- Whether **D-15** lands in Phase **55** implementation vs a fast follow — default **off** until a second maintainer pain signal appears.
- Minor **timeout** tuning for **D-08** strict layer once measured on GHA.

</decisions>

<canonical_refs>

## Canonical references

**Downstream agents MUST read these before planning or implementing.**

### Phase 55 design + milestone

- `.planning/phases/55-core-admin-verify-theme-copy-ci/55-UI-SPEC.md` — UI / VERIFY interaction contract (**approved**); **ADM-09..ADM-11** behavior for invoice flows
- `.planning/REQUIREMENTS.md` — **ADM-09**, **ADM-10**, **ADM-11**
- `.planning/ROADMAP.md` — Phase **55** goal + success criteria
- `.planning/PROJECT.md` — v1.14 charter; **PROC-08** / **FIN-03** non-goals

### Prior locks (carry-forward)

- `.planning/phases/54-core-admin-inventory-first-burn-down/54-CONTEXT.md` — invoice anchor (**D-06**), VERIFY boundaries (**D-08**, **D-14**, **D-22**), parity SSOT (**D-01**)
- `.planning/phases/53-auxiliary-admin-connect-events-layout-verify/53-CONTEXT.md` — **`export_copy_strings`** hygiene, CI ordering, VERIFY naming precedent
- `.planning/phases/50-copy-tokens-verify-gates/50-CONTEXT.md` — Copy / **`Locked`**, theme exceptions, named flows (**D-19**)

### Implementation touchpoints

- `accrue_admin/guides/core-admin-parity.md` — matrix **`Named VERIFY flow id`** + **`VERIFY-01 lane`** flip target
- `examples/accrue_host/e2e/verify01-admin-a11y.spec.js` — VERIFY spine to extend
- `examples/accrue_host/e2e/generated/copy_strings.json` — Playwright fixture output (**ADM-11**)
- `accrue_admin/guides/theme-exceptions.md` — exception register (**ADM-10**)
- `accrue_admin/guides/admin_ui.md` — must link to package **`theme-exceptions.md`** after **D-19**
- `scripts/ci/accrue_host_verify_browser.sh` — canonical browser job ordering

</canonical_refs>

<code_context>

## Existing code insights

### Reusable assets

- **`verify01-admin-a11y.spec.js`** — `AxeBuilder`, **serious + critical** filter, **`copy_strings.json`** load at top, **mobile theme-toggle skip** pattern — extend consistently for invoices.
- **`AccrueAdmin.Copy.Invoice`** + **`copy_strings.json`** — stable **accessible names** for **`getByRole`** selectors (**55-UI-SPEC**).
- **`core-admin-parity.md`** — invoice rows already **Copy/token clean**; **`Named VERIFY flow id`** still **`—`**, lane **`planned — Phase 55 (ADM-09)`** until this phase lands.

### Established patterns

- **Named flows only** — no URL-matrix crawls (**54-CONTEXT D-12**, **50-CONTEXT**).
- **Fake-backed host** — deterministic operator paths for VERIFY (**`examples/accrue_host`**).

### Integration points

- **Router-derived surfaces** — **`AccrueAdmin.Router`** `live/3` rows remain the inventory authority (**54-CONTEXT D-16**).
- **Hexdocs** — guides under **`accrue_admin/guides/`** must remain coherent for tarball consumers (**D-19**, **D-22**).

</code_context>

<specifics>

## Specific ideas

- Maintainer asked for **parallel subagent research** across all four gray areas and a **single coherent** policy set — decisions **D-01–D-23** merge Playwright community practice (popup/download ordering, flake tiers), gettext/i18n catalog lessons (deterministic artifacts, allowlist scope), engine-style doc SSOT (Rails guides idiom), and **Stripe-style** separation of **record UI** vs **document delivery** testing depth.

</specifics>

<deferred>

## Deferred ideas

- **Bidirectional matrix↔tag CI** if **D-05** starts as matrix→tests only — tighten when VERIFY suite count grows.
- **Shard `copy_strings.json`** per **D-16** — only if invoice closure work causes repeated merge pain on the single JSON file.
- **`git diff --exit-code` post-export** — optional hardening per **D-15** if drift is observed between CI and committed JSON.
- **Nightly / advisory “full PDF fidelity” suite** — if strict **D-08** layer still flakes after deterministic harness work.

### Reviewed todos (not folded)

- None (`todo.match-phase` returned **0** for phase **55**).

</deferred>

---

*Phase: 55-core-admin-verify-theme-copy-ci*  
*Context gathered: 2026-04-23*
