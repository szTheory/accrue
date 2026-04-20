# Phase 28: Accessibility hardening - Context

**Gathered:** 2026-04-20  
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 28 delivers **A11Y-01..A11Y-04** on **normative mounted `accrue_admin`** surfaces: predictable **focus** for step-up / dialog semantics, **credible table naming** on representative **customers** and **webhooks** grid tables, **WCAG 2.2 AA** contrast evidence for **light and dark** on representative routes, and at least one **CI axe** gate on a **real VERIFY-01-class host path** (or a documented ADR only if a concrete blocker remains after the minimal integration).

It does **not** own full-site WCAG audits, host demo styling outside the admin mount, new third-party UI kits, or **Phase 29** mobile matrix expansion.

Exit is **REQUIREMENTS.md** checkboxes A11Y-01..04 plus evidence pointers consistent with **28-UI-SPEC.md** and this context.

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC)

**Design contract:** `28-UI-SPEC.md` locks A11Y-01..04 emphasis (focus contract, table naming exemplars, contrast obligation, Playwright + axe, copy tweaks such as step-up CTA wording). Downstream agents MUST read **`28-UI-SPEC.md`** before planning or implementing. Requirements text is not duplicated here.

**In scope (from 28-UI-SPEC):** Step-up + `role="dialog"` focus and rings; customers + webhooks table machine-readable name; representative-route contrast in light + dark; automated axe on mounted admin or ADR with follow-up.

**Out of scope (from 28-UI-SPEC):** Full-site WCAG audit of every LiveView; host demo styling outside admin mount; new registries or non-semantic color literals (still governed by Phase 26 UX-04).

</spec_lock>

<decisions>
## Implementation Decisions

### D-01 — A11Y-01: Step-up focus, Escape, and LiveView-safe behavior

- **Default spine (idiomatic LiveView 1.1):** Use **`Phoenix.LiveView.JS.push_focus`** when opening the step-up surface and **`JS.pop_focus`** on every successful dismiss/cancel path so **focus returns to the trigger** (or a documented fallback, e.g. `main`, if the trigger node is gone). Move **initial focus** on open with **`JS.focus_first`** scoped to the dialog container **or** an explicit first-field target—only on **open transitions** (`phx-mounted` on the dialog subtree or a dedicated “became visible” branch), **never** from generic `handle_event` churn (avoids focus theft on validation patches).
- **Keyboard:** **Escape closes / cancels** the step-up **by default** when the flow is interrupting but cancellable—wire with **`phx-window-keydown`** (or equivalent) alongside the JS focus stack. If product semantics require a **non-dismissible** surface, document **why** in phase verification notes, keep a **visible cancel/close** path, and avoid implying a lightweight dialog; consider **`role="alertdialog"`** only when semantics truly match (rare for standard step-up).
- **Trap + modality:** `push_focus` / `pop_focus` **do not** implement full **tab containment** or **`inert`** backdrop. **Pair** the JS stack with either: (a) a **small, namespaced `phx-hook`** shipped and **documented** for hosts to register once in `liveSocket` (tab cycle + optional `inert` on background), or (b) a future refactor to **native `<dialog>` + `showModal()`** with **`JS.ignore_attributes`** on `open` if LiveView patches would fight the browser—pick (a) for v1.6 unless `<dialog>` is already trivially compatible with current markup.
- **Third-party traps / Alpine:** **Do not** require Alpine, Radix, `focus-trap` npm, etc. Hosts may layer their own global trap **only** if documented; Accrue avoids **double-trap** footguns (library hook + host global manager).
- **Verification split (inherits Phase 26):** **LiveViewTest** proves open → focused element, close → restore, Escape wiring where applicable; **host Playwright** proves hook/trap integration on mounted admin if the hook is part of the supported contract.

**Ecosystem rationale:** Filament/Livewire and React dashboards assume **one** frontend runtime; Accrue is a **mountable library**—first-party **`JS.*` focus stack** + minimal documented hook matches Phoenix docs and avoids dependency sprawl that Pay/Rails or Nova hosts solve differently per app.

### D-02 — A11Y-02: Table accessible name (customers + webhooks only)

- **Pattern:** Add a **visually hidden `<caption>`** on the **desktop `<table>`** branch of `DataTable` (card / `<dl>` mobile layout unchanged).
- **Copy source:** Caption text MUST come from the **same semantic source** as the page title—prefer **`AccrueAdmin.Copy`** (or a single assign passed from the LiveView) so caption and `<h1>` do not drift (addresses “Label in Name” / predictability for SR).
- **API:** Expose an **optional assign** on `DataTable` (e.g. `:table_caption` or `:table_caption_fun`) used **only** where A11Y-02 applies (**customers** and **webhooks** indexes in this phase). Default **nil** = no caption for other consumers—avoids churn across coupons/events/etc.
- **`aria-labelledby` / `aria-label`:** Prefer **caption** over **`aria-label` on `<table>`** (string drift). Use **`aria-labelledby`** only if the page already guarantees a **stable, unique `id`** on the heading and the accessible name must be **literally** that node—otherwise caption + Copy is simpler across the LiveComponent boundary.

**Ecosystem rationale:** Native `<caption>` is the HTML-first table naming pattern; Rails/Pay rarely standardize this in engines—Accrue wins DX by **one optional assign + Copy alignment**.

### D-03 — A11Y-04: CI axe gate (host Playwright, VERIFY-01 family)

- **Placement:** Add **one focused spec** under `examples/accrue_host/e2e/` (e.g. `verify01-admin-a11y.spec.js` or a clearly named sibling)—**extend the existing VERIFY-01 / host browser invocation**; **no new CI job** unless maintainers later choose to grep by tag.
- **Journey:** Use **(b) short journey**, not a raw static URL: reuse **`login`**, **org/billing navigation**, and **`waitForLiveView(page)`** (same pattern as mounted admin specs) so the scan hits **session + org context + LV connected**—matches “mounted admin” intent.
- **Target URL:** Primary axe target = **customers index** (or equivalent) with **DataTable + nav chrome**; sufficient for A11Y-04 “at least one path.” Optionally add **webhooks index** in the **same spec file** as a second `test` only if flake budget allows—**not required** for v1.6 exit if timeboxed.
- **Severity:** Assert on violations with **`impact === "critical" || impact === "serious"`** (do not treat “serious-only” as excluding critical—axe uses both as release-worthy). Attach formatted axe output on failure for contributor DX.
- **Runner:** Prefer **desktop Chromium** project already in the host config; do not multiply browser matrices inside `accrue_admin` CI.
- **ADR:** An ADR is **honest** only for a **concrete** blocker (e.g. missing Chromium on a runner class, legally restricted browser deps) with **owner + milestone** to remove. It is **lazy** if `@axe-core/playwright` is already in `package.json` and integration was not attempted.

**Ecosystem rationale:** Mature OSS **libraries** rarely run axe inside the package; **canonical host** (`examples/accrue_host`) owns headed gates—matches Phase 21/26 test-pyramid decisions.

### D-04 — A11Y-03: Contrast evidence (coherent with D-03)

- **Primary:** Satisfy A11Y-03 **largely through the same Playwright harness as D-03**: for each **representative route** (customers index, one money detail, webhooks index per **28-UI-SPEC**), force **light** and **dark** explicitly (theme toggle or `data-theme`—do not rely only on `prefers-color-scheme` unless documented), then run axe and fail on **serious/critical** **`color-contrast`** (and other serious rules already in the gate).
- **Gap checklist (short, phase doc):** Maintain a **small, stable** bullet list for what axe under-resolves: **gradients / background-images**, **layered overlays**, **hover/focus/active/disabled** if not visited in the spec, **Phase 26 theme-exception** hex paths not exercised by the seeded fixture, **host `accent_hex` / branding** not covered by CI defaults. Re-run checklist when tokens or registry entries change—not every PR.
- **Stylelint WCAG plugins:** **Defer** unless stylelint is already a standard tool in this repo; static rules do not resolve **`var()`** composition across light/dark like one mounted axe pass.

**Ecosystem rationale:** Stripe-class UIs verify **computed** appearance; a **single host spec × themes** gives library maintainers maximum signal per CI minute.

### D-05 — Cohesion across decisions (single architecture story)

- **One host browser story:** VERIFY-01 host Playwright owns **mounted axe + light/dark contrast scans** on the same journey; `accrue_admin` ExUnit/LiveViewTest owns **focus/Escape/caption markup** contracts cheaply.
- **Copy alignment:** Step-up visible control label **“Verify identity”** and any new caption strings live in **`AccrueAdmin.Copy`** per Phase 27—no parallel literals.
- **Documentation:** Phase verification doc lists **focus mechanism** (JS stack + hook name), **Escape default**, **table caption assign** pattern, and **Playwright spec path(s)** + theme forcing steps.

### Claude's Discretion

- Exact hook module name and file layout under `accrue_admin` assets once wired.
- Whether webhooks index gets a **second** axe `test` in v1.6 or waits for a follow-up patch if flake budget is tight.
- Precise `testId` / columnheader wait beyond `waitForLiveView` if one extra stable selector reduces flake.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements

- `.planning/ROADMAP.md` — Phase 28 goal, success criteria, canonical refs.
- `.planning/REQUIREMENTS.md` — A11Y-01..04 definitions and traceability.

### Phase 28 contract

- `.planning/phases/28-accessibility-hardening/28-UI-SPEC.md` — Approved UI design contract (A11Y tables, focus, contrast, automation).

### Prior phase context (pyramid + copy)

- `.planning/phases/26-hierarchy-and-pattern-alignment/26-CONTEXT.md` — LiveViewTest default; host Playwright for mounted realism; Phase 28 owns axe.
- `.planning/phases/27-microcopy-and-operator-strings/27-CONTEXT.md` — `AccrueAdmin.Copy` as SSOT; Playwright `getByRole` / `data-role` policy.

### UI contracts

- `.planning/phases/20-organization-billing-with-sigra/20-UI-SPEC.md` — Step-up, org/tax, nesting baseline.
- `.planning/phases/21-admin-and-host-ux-proof/21-UI-SPEC.md` — Money indexes, list/detail, operator density.

### Code integration points

- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` — Step-up dialog markup and submit control.
- `accrue_admin/lib/accrue_admin/components/data_table.ex` — Grid table + card layout; caption assign wiring.
- `accrue_admin/assets/css/theme.css` — Semantic tokens for contrast.
- `examples/accrue_host/e2e/` — VERIFY-01 Playwright specs and fixtures (`support/fixture.js`, `waitForLiveView`).
- Official: [Phoenix.LiveView.JS](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html) — `push_focus`, `pop_focus`, `focus_first`, `ignore_attributes`.
- WAI-ARIA APG: [Dialog (Modal) Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/) — focus, Escape, modality expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`AccrueAdmin.Components.StepUpAuthModal`** — Already exposes `role="dialog"`, `aria-labelledby="step-up-title"`; needs focus stack + Escape + copy alignment to **28-UI-SPEC** (“Verify identity”).
- **`AccrueAdmin.Components.DataTable`** — Central table/card primitive; optional **caption** assign fits without touching every LiveView beyond customers/webhooks.
- **`AccrueAdmin.Copy`** — Phase 27 hub for stable strings; use for caption + step-up CTA DRY with page titles.

### Established patterns

- Host **Playwright** already proves **mounted admin** with **`waitForLiveView`** and fixture login—extend rather than invent.
- **`@axe-core/playwright`** is declared in host `package.json` but not yet wired to specs—minimal integration satisfies A11Y-04.

### Integration points

- Host `liveSocket` **hooks map** must register any **documented** Accrue modal hook once (install guide note).
- CI entry remains **`examples/accrue_host`** browser scripts used by VERIFY-01.

</code_context>

<specifics>
## Specific Ideas

- Subagent research consensus: prefer **LiveView first-party focus stack** + **small documented hook** over heavy JS frameworks; **visually hidden caption** + **Copy** for table names; **one VERIFY-01-class journey** with **critical+serious** axe; **light + dark** forced in the same spec for A11Y-03 overlap.

</specifics>

<deferred>
## Deferred Ideas

- **Native `<dialog>` + `showModal()`** as a future simplification if LiveView/`ignore_attributes` integration becomes cleaner than overlay `section`—not required for v1.6 exit.
- **Second processor / full WCAG program** — out of milestone per REQUIREMENTS.

### Reviewed Todos (not folded)

_None._

**None — discussion stayed within phase scope.**

</deferred>

---

*Phase: 28-accessibility-hardening*  
*Context gathered: 2026-04-20*
