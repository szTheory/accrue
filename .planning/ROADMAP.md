# Roadmap: Accrue

## Milestones

- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- ✅ **v1.48 Release Readiness + Stable Core Posture** — Phases 159-162 (shipped 2026-06-01) — [archive](milestones/v1.48-ROADMAP.md)
- ✅ **v1.49 Realistic Demo App & Adoption Evidence** — Phases 163-166 (shipped 2026-06-02) — [archive](milestones/v1.49-ROADMAP.md)
- ✅ **v1.50 Admin UI Foundation** — Phases 167-173 (shipped 2026-06-02 via PR #32; archived 2026-06-03) — [archive](milestones/v1.50-ROADMAP.md)
- ✅ **v1.51 Admin UI: Depth Pass [SHIPPED 2026-06-04 — see milestones/v1.51-ROADMAP.md] (IA + Systematic Polish)** — Phases 174-179 (planning 2026-06-03; second, depth-oriented pass on the same `accrue_admin` surface; persona-driven IA reshape + token gap-closure + systematic rubric uplift + motion + seed expressiveness + screenshot-driven visual-QA; no new billing primitives)
- 🔄 **v1.52 Brand System** — Phases 180-186 (opened 2026-06-11; brand audit + DNA lock, SVG logo tournament, design tokens, voice/copy, standalone HTML brand book; no billing primitives)

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. Future feature milestones require at least one of:

- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- an operational release/support failure,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

After v1.48, broad feature milestones remain closed by default unless reopened by concrete adopter failure, correctness/security/data-loss risk, repeated support issue, operational failure, or explicit strategy change.

No broad feature milestone is currently open. (v1.50 Admin UI Foundation is a quality / design-system / usability investment in an already-shipped surface, justified as adopter-facing DX — it adds no new billing primitives and does not reopen broad feature scope.)

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details open>
<summary>🔄 v1.52 Brand System (Phases 180-186) — OPENED 2026-06-11 (deps 180→181→182→183→186, with 180→{184,185}→186 side-rails)</summary>

**Posture:** Brand/DX investment in adopter-facing presentation surfaces (README, Hex.pm, HexDocs, social previews, admin UI identity) — **not** a broad feature milestone (no new billing primitives). Reopen decision recorded in `PROJECT.md`. Justification class: same as v1.50/v1.51.

**Hard logo constraints (binding on every candidate):** no rectangular background/container shape behind the logomark; logotype sits optically close to the mark; main lockup carries no subtitle (a separate with-subtitle variant ships); fully-integrated custom typemark options required. **Seed latitude is evidence-gated:** Geist + the existing palette are defaults; changes only with a cited failure (contrast, distinctiveness, 16px rendering) and user ratification at the audit checkpoint.

**Guardrails (out of scope):** no admin `ax-*` token changes (admin `theme.css` stays SSOT; brandbook documents the brand layer); no PDF brand book; no website/landing-page build (copy blocks only); no binary-heavy assets beyond platform-required PNG/.ico; exploration artifacts (galleries, rejected candidates, `TOURNAMENT.md`) stay in `.planning/`, not `brandbook/`; no new billing primitives; no breaking changes.

**Authoritative design source:** `.planning/research/v1.52-brand-system-design.md`.

### Phase Summary

- [x] **Phase 180: Brand Audit & DNA Lock** — 14-section pressure test, KEEP/TIGHTEN/REWORK/ADD/REMOVE verdicts, locked BRAND-DNA + binding logo brief (✋ user checkpoint) (completed 2026-06-12)
- [x] **Phase 181: SVG Pipeline + Tournament Round 1 — Divergent** — opentype.js Geist-outline harness, pre-gate lints, Playwright QA, 12–16 candidates across 4 directions, context-matrix gallery (✋ user picks winners) (completed 2026-06-13)
- [x] **Phase 182: Tournament Convergent Refinement** — variation rounds on winners via monotonic TOURNAMENT.md ledger, 3-round default cap, extend-or-settle question (✋ looping checkpoint) (completed 2026-06-13)
- [x] **Phase 183: Logo System Production** — full derived suite in `brandbook/logo/`, outlined paths, svgo-optimized (light checkpoint: derivative-sheet eyeball) (completed 2026-06-13)
- [x] **Phase 184: Design Tokens & Specimens** — `brandbook/tokens/` with documented mapping + automated consistency check vs admin `ax-*` tokens (no checkpoint; depends only on 180) (completed 2026-06-14)
- [ ] **Phase 185: Voice, Microcopy & Marketing Copy** — ready-to-paste copy blocks for all adopter-facing surfaces (light checkpoint: batch copy review; depends only on 180)
- [ ] **Phase 186: HTML Brand Book Assembly & Quality Gate** — self-contained `brandbook/index.html`, ≤2 MB budget, Phase-180 quality-gate checklist (✋ final UAT)

### Phase Details

### Phase 180: Brand Audit & DNA Lock

**Goal:** Maintainer ratifies a locked brand DNA and binding logo design brief before any creative work begins — the cheapest place to disagree and the foundation every downstream phase builds on.
**Depends on:** Nothing (foundation phase)
**Requirements:** AUD-01, AUD-02, AUD-03
**Success Criteria** (what must be TRUE):

  1. Maintainer can open `BRAND-AUDIT.md` and read a 14-section pressure-test of `prompts/accrue-brand-book.md` where every verdict is tagged KEEP / TIGHTEN / REWORK / ADD / REMOVE with a cited justification — no churn entry lacks a failure citation.
  2. Maintainer reads a locked `BRAND-DNA.md` summarising the ratified positioning, palette (with any evidence-gated changes documented), typography, voice tone, and visual personality — and confirms it before Phase 181 begins.
  3. A binding logo design brief exists in the planning artifacts, explicitly recording the 4 hard constraints (no rect background, optically-close logotype, no subtitle in main lockup, fully-integrated typemark options required) plus the Phase-186 quality-gate checklist.
  4. Any proposed palette or font change references a concrete cited failure (contrast ratio, distinctiveness, 16px rendering) and is explicitly ratified or rejected by the user at this checkpoint.

**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 180-01-PLAN.md — Contrast script + evidence table (AUD-03 substrate)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 180-02-PLAN.md — BRAND-AUDIT.md §1–§8 authoring (AUD-01, AUD-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 180-03-PLAN.md — BRAND-AUDIT.md §9–§14 + BRAND-DNA.md + logo-brief.md + quality-gate-checklist.md (AUD-01, AUD-02, AUD-03)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 180-04-PLAN.md — Ratification checkpoint (AUD-01, AUD-02, AUD-03) ✋

### Phase 181: SVG Pipeline + Tournament Round 1 — Divergent

**Goal:** User can judge 12–16 distinct, pre-vetted SVG logo candidates across 4 conceptual directions, rendered in a self-contained gallery, and pick 1–3 winners — the divergent ideation stage with automated quality gates ensuring no candidate violates the hard constraints.
**Depends on:** Phase 180
**Requirements:** LOGO-01, LOGO-02
**Success Criteria** (what must be TRUE):

  1. A reproducible Node harness uses opentype.js to emit exact Geist letterform outlines (one `<path>` per glyph, with IDs) and runs automated pre-gate lints (valid SVG parse, no-rect-background, lockup gap ratio within spec, 16px legibility screenshot, monochrome derivable, no subtitle in main lockup) — no candidate that fails a lint reaches the user.
  2. User can open `round-1-gallery.html` via `file://` in a browser and see 12–16 candidates across 4 conceptual directions (accumulation strata, stepped interval, layered arcs, fully-integrated typemarks), each rendered in a fixed context matrix (paper-light, ink-dark, 32px favicon, 16px favicon, avatar circle-crop, README header mock, social card mock, monochrome row).
  3. Every candidate in the gallery carries a stable ID (A1…D4) and a one-line rationale; the agent has screenshot-reviewed and self-scored each candidate before the user sees them.
  4. User picks 1–3 winners and records per-winner keep/change notes in `TOURNAMENT.md`; the round-1 ledger entry is verbatim.

**Plans:** 7/7 plans complete

Plans:
**Wave 1** *(package legitimacy gate + font spine bootstrap)*

- [x] 181-01-PLAN.md — Package legitimacy checkpoint + harness/package.json + geist-spine.mjs (LOGO-01) ✋

**Wave 2** *(blocked on Wave 1 — lint suite + lockup assembler)*

- [x] 181-02-PLAN.md — lint.mjs (6 pre-gate checks) + assemble-lockup.mjs (LOGO-01)

**Wave 3** *(parallel — blocked on Wave 2; 03 and 04 run in parallel)*

- [x] 181-03-PLAN.md — Direction A/B/C generators (strata, step, arcs) (LOGO-01)
- [x] 181-04-PLAN.md — Direction D integrated typemark generator (path surgery) (LOGO-01)

**Wave 4** *(blocked on Wave 3 — orchestrator + TOURNAMENT.md scaffold)*

- [x] 181-05-PLAN.md — generate.mjs orchestrator + TOURNAMENT.md scaffold (LOGO-01, LOGO-02)

**Wave 5** *(blocked on Wave 4 — screenshots + gallery)*

- [x] 181-06-PLAN.md — render-matrix.mjs + build-gallery.mjs + round-1-gallery.html (LOGO-01, LOGO-02)

**Wave 6** *(blocked on Wave 5 — self-review + user checkpoint)*

- [x] 181-07-PLAN.md — Agent self-review → self-review.ndjson + user picks winners → TOURNAMENT.md (LOGO-02) ✋

### Phase 182: Tournament Convergent Refinement

**Goal:** One locked logo winner emerges from iterative refinement rounds on the round-1 winners — constraints recorded monotonically in `TOURNAMENT.md` so no round re-litigates an earlier verdict, with an explicit settle-or-extend question capping the loop at 3 rounds by default.
**Depends on:** Phase 181
**Requirements:** LOGO-03
**Success Criteria** (what must be TRUE):

  1. Each refinement round is authored from the latest `TOURNAMENT.md` ledger entry and shows 6–9 variants of ≤2 finalists (weight, motif amplitude, lockup spacing/kerning, terminal treatments) in the same context matrix plus increasingly real contexts (actual social-card copy, actual README header text).
  2. The `TOURNAMENT.md` ledger is monotonic — every round appends verdicts verbatim and no constraint recorded in an earlier round is violated or omitted in a later round.
  3. The loop concludes when the user locks a single winner; if 3 rounds complete without a lock, the agent surfaces an explicit "extend one more round or settle on [candidate]?" question.
  4. The final `TOURNAMENT.md` entry records the locked winner with its candidate ID and the ratified mark + lockup geometry frozen.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 182-01-PLAN.md — Harness adaptation: --output-dir parameterization, two-tone assemble-lockup, b-step-r2.mjs, REVIEW fixes WR-01/WR-05/WR-07/IN-04d (LOGO-03)

**Wave 2** *(blocked on Wave 1 — pipeline run + checkpoint)*

- [x] 182-02-PLAN.md — Round 2 pipeline run: 7 variants (R2-1..R2-7), render gallery, agent self-review, user verdict → TOURNAMENT.md append (LOGO-03) ✋

**Wave 3** *(blocked on Wave 2 — LOCK/SETTLE path only)*

- [x] 182-03-PLAN.md — Winner freeze: verify TOURNAMENT.md integrity + write 182-FREEZE.md for Phase 183 (LOGO-03)

*(EXTEND path: planner re-invoked for Round 3 before 182-03 executes; max 3 rounds per ROADMAP.)*

### Phase 183: Logo System Production

**Goal:** The locked winner is mechanically derived into a complete, production-ready logo system committed at `brandbook/logo/` — all formats a SaaS developer needs, all finals as outlined paths, svgo-optimized, with accessible metadata and documented OFL provenance.
**Depends on:** Phase 182
**Requirements:** LOGO-04
**Success Criteria** (what must be TRUE):

  1. `brandbook/logo/` contains the complete required file set: primary lockup, integrated typemark, icon-only mark, monochrome positive/negative, dark/light versions, favicon (SVG + .ico + PNG), social card (SVG + PNG), with-subtitle variant, and clearspace/minimum-size spec sheet — all committed to the repo.
  2. Every final SVG contains outlined paths only (no `<text>` elements, no `@font-face` dependency), passes `svgo` optimization, and includes accessible `<title>` and `<desc>` elements.
  3. A `LICENSE-FONTS.txt` documents OFL 1.1 provenance for any Geist letterform outlines incorporated into the logo finals.
  4. A size-matrix screenshot (all variants at representative sizes and both themes) confirms visual fidelity of every derived file — eyeball checkpoint passed.

**Plans:** 4/4 plans complete

Plans:
**Wave 1** *(harness bootstrap — package.json, svgo.config.mjs, geist-spine-mono.mjs, ico-packer.mjs)*

- [x] 183-01-PLAN.md — Harness bootstrap: package.json (@resvg/resvg-js), svgo.config.mjs, geist-spine-mono.mjs, ico-packer.mjs + unit tests (LOGO-04)

**Wave 2** *(blocked on Wave 1 — SVG suite generation)*

- [x] 183-02-PLAN.md — generate-logo-suite.mjs: all 13 committed SVG brand artifacts + BLOCKING render-fidelity checkpoint (LOGO-04) ✋

**Wave 3** *(blocked on Wave 2 — raster production)*

- [x] 183-03-PLAN.md — generate-rasters.mjs: resvg PNG + ico-packer .ico + determinism assertion (LOGO-04)

**Wave 4** *(blocked on Wave 3 — QA + docs + human checkpoint)*

- [x] 183-04-PLAN.md — size-matrix-qa.mjs, brandbook/README.md, brandbook/LICENSE-FONTS.txt, determinism gate, eyeball checkpoint (LOGO-04) ✋

**UI hint**: yes

### Phase 184: Design Tokens & Specimens

**Goal:** `brandbook/tokens/` establishes the brand-layer token vocabulary (raw palette, semantic roles, typography, spacing, radius, focus-ring, state) with documented mapping to the admin `ax-*` SSOT and an automated consistency check — zero admin code changes, brand layer documented alongside.
**Depends on:** Phase 180
**Requirements:** TOK-01, TOK-02, TOK-03
**Success Criteria** (what must be TRUE):

  1. `brandbook/tokens/tokens.json` and `tokens.css` define raw palette, semantic color roles, typography scale, spacing, radius, focus-ring, code-block, callout, and state tokens per the audit token spec — fully committed to the repo.
  2. An automated consistency check script verifies that every brandbook token value that corresponds to an `ax-*` token in `accrue_admin/assets/css/theme.css` matches (or is explicitly documented as a brand-layer divergence) — the script exits non-zero on undocumented drift.
  3. `brandbook/examples/` contains palette and typography specimen artifacts (SVG or HTML) that render every color swatch, type scale, and spacing step visually.

**Plans:** 5/5 plans complete
Plans:
**Wave 1**

- [x] 184-01-PLAN.md — Harness scaffold + gated dep install + tokens.json SSOT + lib.mjs helpers

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 184-02-PLAN.md — tokens.css generator + reference-only README + completeness check (TOK-01)
- [x] 184-03-PLAN.md — brand↔admin parity check + injected-drift --test (TOK-02)
- [x] 184-04-PLAN.md — palette/typography/spacing specimen SVGs + coverage check (TOK-03)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 184-05-PLAN.md — CI determinism + parity gates (TOK-01/02/03)

### Phase 185: Voice, Microcopy & Marketing Copy

**Goal:** A committed voice system and complete set of ready-to-paste copy blocks exist for every adopter-facing channel, consistent with the ratified brand DNA, and reviewed and approved by the user in one batch.
**Depends on:** Phase 180
**Requirements:** COPY-01, COPY-02
**Success Criteria** (what must be TRUE):

  1. A committed voice system document defines voice principles, tone sliders (formal↔casual, precise↔evocative), vocabulary to use/avoid, and say-this/not-this examples — all consistent with the ratified BRAND-DNA.
  2. Ready-to-paste copy blocks exist (committed to `brandbook/`) for: GitHub repo description + topics, Hex.pm package description, HexDocs intro paragraph, README hero, landing-page sections (hero / problem / solution / install / benefits / comparison / CTAs), release-note and changelog voice templates, and error/empty/success-state microcopy examples.
  3. User reviews all copy blocks in one batch and approves or requests revisions; the final committed copy reflects the approved batch.

**Plans:** 3 plans
Plans:
**Wave 1** *(parallel — no dependencies)*

- [x] 185-01-PLAN.md — Voice system doc: principles, tone sliders, vocabulary, surface dispatch rule, claims posture, CTA canon (COPY-01)
- [x] 185-02-PLAN.md — Copy blocks for all surfaces: GitHub, Hex.pm, HexDocs, README hero, landing page, release notes, microcopy (COPY-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 185-03-PLAN.md — One-batch human review + approval + revision incorporation

### Phase 186: HTML Brand Book Assembly & Quality Gate

**Goal:** All milestone outputs are assembled into one self-contained, professional, standalone HTML brand book at `brandbook/index.html` that opens via `file://` with no build step, and the committed `brandbook/` passes the Phase-180 quality-gate checklist within the ≤2 MB size budget.
**Depends on:** Phase 183, Phase 184, Phase 185
**Requirements:** BOOK-01, BOOK-02
**Success Criteria** (what must be TRUE):

  1. `brandbook/index.html` opens via `file://` in a browser with no build step, no JS frameworks, and no external network requests — all CSS is inlined from the Phase-184 tokens, all SVGs are inlined, and all copy is present.
  2. The brand book renders correctly in both light and dark color schemes and at small viewport widths (≥360px); Playwright screenshots confirm rendering across the matrix.
  3. `du -sh brandbook/` reports ≤2 MB total committed weight.
  4. The Phase-180 quality-gate checklist passes: designer-buildable / engineer-implementable / dark-mode / small-size / specific-to-Accrue / no-thrash — all criteria satisfied and signed off by the user.

**Plans:** 3 plans
Plans:
**Wave 1** *(assembler + verifier harness)*

- [x] 186-01-PLAN.md — brandbook/harness/package.json + assemble.mjs + verify-brandbook.mjs (BOOK-01, BOOK-02)

**Wave 2** *(blocked on Wave 1 — assembly run + automated quality gates)*

- [x] 186-02-PLAN.md — Run assemble.mjs → brandbook/index.html; run verify-brandbook.mjs → VERIFY_BRANDBOOK_OK + 4 screenshots (BOOK-01, BOOK-02)

**Wave 3** *(blocked on Wave 2 — human UAT sign-off)*

- [ ] 186-03-PLAN.md — Quality-gate checklist sign-off + BOOK-02-SIGN-OFF.md + Phase 186 closure (BOOK-02) ✋
**UI hint**: yes

</details>

<details open>
<summary>✅ v1.51 Admin UI: Depth Pass (Phases 174-179) — SHIPPED 2026-06-04 (deps A→B→C→{D,E}→F)</summary>

**Posture:** Quality / adopter-facing operator-DX investment in the already-shipped `accrue_admin` surface — **not** a broad feature milestone (no new billing primitives). The second, depth-oriented pass on v1.50's foundation: re-map IA from entity-shaped to job/persona-shaped, close design-token gaps, lift the under-iterated screen tail to one rubric baseline, add restrained motion, make seed data express every state, and prove it with a screenshot-driven visual-QA loop.

**Anti-churn rule:** every change cites a justification token — (a) a rubric dimension below bar with a before-score, (b) a named persona-job the screen fails to serve, or (c) a concrete token bypass / hardcode eliminated. *"Looks nicer / my taste" is not admissible.* Frozen screens (Home, primary nav, global search) touched only on a rubric-flagged regression or a persona-job miss.

**10-dimension rubric (0–3, pass ≥2):** ① token compliance ② visual hierarchy ③ spacing rhythm ④ state coverage ⑤ responsive/mobile-first (@360px) ⑥ contrast ⑦ focus & semantics ⑧ brand expression ⑨ motion ⑩ reuse/DRY.

**Guardrails (out of scope):** no Tailwind migration (double down on custom `ax-*` CSS + tokens); no churn on frozen screens absent a flagged regression; the demo/host app (`examples/accrue_host`) UI is not a design target (only the screenshot/seed substrate); no new billing primitives; no breaking changes (route reshaping ships with redirects, component public APIs stay backward-compatible).

**Authoritative design source:** `.planning/research/v1.51-admin-ui-depth-design.md`.

### Phase Summary

- [ ] **Phase 174: A — Design-System Gap Closure & Token Completeness** — Add line-height / letter-spacing / breakpoint / transition-bundle / reading-measure tokens, kill the remaining token bypasses, and publish a component-variants reference.
- [ ] **Phase 175: B — Persona-Driven IA Spine** — Re-tier nav into a weighty Billing zone + recessed specialist rooms with attention badges, verb launchers + visible search, Customer-360 tab tiering, mandatory bidirectional threading, work-queue list defaults, and redirected route reshaping.
- [ ] **Phase 176: C — Systematic Per-Screen Rubric Uplift** — Enumerate every screen × 10 dimensions × {light,dark} × {desktop,mobile}, baseline it, and lift the under-iterated tail worst-first with a mobile-first rewrite.
- [ ] **Phase 177: D — Motion & Micro-interaction Design** — Document a token-based interaction spec + antipattern list and apply restrained, reduced-motion-honoring motion to drawers, dropdowns, the command palette, tabs, flash, and skeleton→content.
- [ ] **Phase 178: E — Seed Expressiveness & State Coverage** — Extend E2E seed fixtures + host seeds so every screen's empty/populated/overflow/error/loading and edge states are reachable on a single click-through.
- [ ] **Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off** — Sweep the full inventory across {desktop,mobile}×{light,dark}, LLM-score each PNG against the 10 dimensions, remediate until no dimension <2, and produce the final scorecard + axe sign-off.

### Phase Details

### Phase 174: A — Design-System Gap Closure & Token Completeness

**Goal:** Close every remaining design-token gap so the admin CSS resolves all spacing/type/radius/shadow/line-height/letter-spacing/breakpoint/transition values from named `ax-*` tokens, kill the last token bypasses, and give maintainers a single component-variants reference. This is the substrate the rubric uplift, motion, and seed work all build on.
**Depends on:** Nothing (foundation phase)
**Requirements:** DSY-01, DSY-02, DSY-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can grep `app.css` + components and find no hardcoded px/em line-height, letter-spacing, breakpoint, or transition literals — every such value resolves from an `ax-*` token (including a reading-measure max-width container token and pre-composed transition bundles).
  2. The dunning banner and invoice screens render every brand color through tokens with zero inline-hex fallbacks and zero inline styles; no admin surface bypasses the token system.
  3. A maintainer opening `/dev/components` sees a component-variants reference enumerating every button / badge / status / card variant alongside its token mapping.

**Plans:** 7 plans (4 executed + 3 gap-closure)

Plans:
**Wave 1**

- [x] 174-01-PLAN.md — Add type micro-tokens and transition-bundle tokens to theme.css (DSY-01 substrate)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 174-02-PLAN.md — Migrate app.css literals→tokens + breakpoint registry + dunning bypass kill + guard needle + asset rebuild (DSY-01, DSY-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 174-03-PLAN.md — ComponentRegistry data module + kitchen variant reference extension (DSY-03)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 174-04-PLAN.md — ComponentRegistryTest drift-prevention test + full suite gate (DSY-03)

**Wave 5 — Gap Closure** *(after verification; closes VERIFICATION.md gaps)*

- [x] 174-05-PLAN.md — Fix phantom tokens in ComponentRegistry + add token-validity test (DSY-03, Gap 1)
- [x] 174-06-PLAN.md — Seed adoption-proof-matrix.md in PackageDocsVerifierTest + Stripe-only negative test (DSY-01, Gap 2)
- [x] 174-07-PLAN.md — Resolve .ax-search-trigger stale deferral comment + asset rebuild (DSY-01, Gap 3)

**UI hint**: yes

### Phase 175: B — Persona-Driven IA Spine

**Goal:** Replace the entity-shaped interior with a job/persona-shaped spine — one weighty primary Billing zone plus quiet specialist rooms that light up only when they have work — so each of the six personas reaches its job fast, no detail screen dead-ends, and no existing bookmark breaks. This resolves the v1.50 "disjoint" seam between a job-shaped Home and an entity-shaped interior.
**Depends on:** Phase 174
**Requirements:** IA-01, IA-02, IA-03, IA-04, IA-05, IA-06, IA-07
**Success Criteria** (what must be TRUE):

  1. From Home, each of the six personas can reach their primary job in ≤2 clicks via a verb-labeled task launcher ("Look up a customer," "Clear the invoice queue," "Recover at-risk revenue," "Investigate an incident") or a visible (not hotkey-only) global search field.
  2. The sidebar shows a weighted primary **Billing** zone (Customers · Subscriptions · Invoices · Payments) with **Recovery / Developer / Catalog** as visually-recessed, collapsible specialist zones that surface attention-count badges (dead-letters, at-risk) only when work exists; **Connect** stands alone.
  3. Each work-queue list opens pre-filtered to the persona queue (e.g. invoices → open/uncollectible) with an "All" view one filter-chip away.
  4. Every detail screen renders a Related-billing card with no dead ends, and a dead-lettered webhook threads Webhook → Event → affected entity; Customer-360 shows primary tabs (Subscriptions, Invoices, Payments) with advanced tabs recessed under a quieter "More" grouping.
  5. Every route changed by the IA reshape redirects from its old path (no broken bookmarks), and a compliance/audit user can reach an actor-filtered view of the event log via a saved lens without it occupying a top-level nav group.

**Plans:** 7 plans across 4 waves

Plans:
**Wave 1** *(parallel — foundation data + query fixes)*

- [x] 175-01-PLAN.md — Query multi-status extension + Wave-0 test scaffolds (IA-03, IA-04, IA-06)
- [x] 175-02-PLAN.md — AttentionCounts + NavBadgeHook + Nav/AppShell extension + copy relabels + sidebar_collapse.js (IA-01, IA-02)

**Wave 2** *(parallel — blocked on Wave 1)*

- [x] 175-03-PLAN.md — Sidebar rewrite (collapse + badges) + CSS token-gap classes + RedirectController + route reshaping (IA-02, IA-06)
- [x] 175-04-PLAN.md — Work-queue default filters (invoices/subscriptions/payments) + visible Home search field (IA-01, IA-03)

**Wave 3** *(parallel — blocked on Wave 2)*

- [x] 175-05-PLAN.md — EventLive (/events/:id) + WebhookLive Related card + Webhook→Event→entity threading (IA-04, IA-06)
- [x] 175-06-PLAN.md — Customer-360 tab tiering (More ▾) + compliance actor-lens chip on events (IA-05, IA-07)

**Wave 4** *(blocked on Wave 3)*

- [x] 175-07-PLAN.md — Related cards on 4 missing detail screens + /charges→/payments href fixes + full suite gate (IA-04)

**UI hint**: yes

### Phase 176: C — Systematic Per-Screen Rubric Uplift

**Goal:** Bring every under-iterated screen up to one consistent rubric baseline by enumerating the full touchpoint matrix, capturing baseline scores, and lifting the worst screens first — eliminating the uneven depth left after v1.50. The heavy phase; wave-split per screen-group.
**Depends on:** Phase 174, Phase 175
**Requirements:** SCR-01, SCR-02, SCR-03, SCR-04
**Success Criteria** (what must be TRUE):

  1. Every admin screen scores ≥2 on all 10 rubric dimensions in both light and dark themes.
  2. Every admin screen scores ≥2 on all 10 rubric dimensions at both desktop and mobile (usable @360px) widths.
  3. The under-iterated tail (charges, coupons, promotion-codes, connect, events, webhooks, invoice detail) is lifted to baseline with documented before/after scores per screen.
  4. Dense text/detail screens apply a reading-measure max-width container and a mobile-first responsive layout built on the Phase 174 breakpoint tokens.

**Plans:** 6 plans (5 execution + 1 human checkpoint)

Plans:
**Wave 1** *(dependency root — SCORECARD baseline + CSS fix)*

- [x] 176-01-PLAN.md — Capture 176-SCORECARD.md baseline (all 21 screens × 10 dims) + fix data-table breakpoint --ax-bp-lg→--ax-bp-md + asset rebuild (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 2** *(blocked on Wave 1 — list screen audit)*

- [x] 176-02-PLAN.md — Audit all 9 list screens card_fields/card_title quality against persona criteria; update SCORECARD Wave 1 after-scores (SCR-01, SCR-02, SCR-03)

**Wave 3** *(parallel — blocked on Wave 2 — catalog/specialist detail; 03 and 04 run in parallel)*

- [x] 176-03-PLAN.md — Uplift event_live (semantic dl/dt/dd facts, detail_section body, not-found state) + coupon_live (Detail alias, summary_card hero, DRY projection section) (SCR-01, SCR-02, SCR-03, SCR-04)
- [x] 176-04-PLAN.md — Uplift promotion_code_live (Detail alias, summary_card hero, detail_section parent-coupon) + connect_account_live (.ax-measure prose) + webhook_live (DRY forensic section, .ax-measure) (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 4** *(blocked on Wave 3 — dense financial detail)*

- [x] 176-05-PLAN.md — Apply .ax-measure to invoice_live prose (4 regions) + charge_live prose (3 regions) + audit subscription_live; complete SCORECARD final after-scores (SCR-01, SCR-02, SCR-03, SCR-04)

**Wave 5** *(blocked on Wave 4 — Nyquist gate + final verification)*

- [x] 176-06-PLAN.md — Nyquist breakpoint guard assertions in data_table_test.exs + ax-measure misapplication guard + full suite gate + human spot-check checkpoint (SCR-01, SCR-02, SCR-03, SCR-04)

**UI hint**: yes

### Phase 177: D — Motion & Micro-interaction Design

**Goal:** Add restrained, purposeful, token-based motion to the now-stable layouts — functional feedback, never decoration — governed by a documented spec and a researched antipattern list, and fully honoring reduced-motion. Depends on stable layouts so motion is applied once, not re-thrashed.
**Depends on:** Phase 174, Phase 176
**Requirements:** MOT-01, MOT-02, MOT-03
**Success Criteria** (what must be TRUE):

  1. A documented motion/interaction spec defines what animates, why, which token, and reduced-motion behavior, including an antipattern list grounded in researched best practice (Emil Kowalski principles).
  2. Drawers, dropdowns, the command palette, tabs, flash/toasts, and skeleton→content transitions animate via Phase 174 design-token transition bundles — functional, not decorative — and badge/state changes transition through tokens.
  3. All admin motion honors `prefers-reduced-motion` (no travel/overshoot; crossfades retained), verified by an automated check.

**Plans:** 6 plans across 4 waves
Plans:
**Wave 1**

- [x] 177-01-PLAN.md — motion.md guide + accrue_admin/mix.exs ExDoc registration (MOT-01)
- [x] 177-02-PLAN.md — CSS transitions for dropdown, More ▾, tabs, badge, skeleton classes + sidebar_collapse.js two-step (MOT-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 177-03-PLAN.md — JS.transition for detail_drawer, flash_group, customer_live More ▾, data_table (MOT-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 177-04-PLAN.md — global_search data-open refactor + command_palette.js hook update (MOT-02/MOT-03)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 177-05-PLAN.md — antipattern guard script + paired negative-test fixture coupling (MOT-01)
- [x] 177-06-PLAN.md — Playwright reduced-motion e2e extensions + /dev/components motion section (MOT-01/MOT-03)

**UI hint**: yes

### Phase 178: E — Seed Expressiveness & State Coverage

**Goal:** Make every screen state and edge case reachable from seeded data on a single click-through, so no screen looks good only with hand-picked IDs — and so the visual-QA loop can actually photograph every state. Feeds the QA loop.
**Depends on:** Phase 175, Phase 176
**Requirements:** SEED-01, SEED-02
**Success Criteria** (what must be TRUE):

  1. Every admin screen's empty, populated, overflow/pagination, error, and loading states are reachable from seeded data on a single click-through (via E2E seed fixtures at `/__e2e__/seed/<fixture>` + host `seeds.exs`).
  2. Each edge state (dunning/at-risk, multi-currency, long strings, dark-only contrast traps) has a seeded instance; no screen depends on hand-picked IDs to look right.

**Plans:** 4 plans across 3 waves

Plans:
**Wave 1** *(foundation — matrix + test scaffold)*

- [x] 178-01-PLAN.md — STATE-MATRIX.md (21 screens × 8 state dims) + e2e_fixtures_test.exs RED scaffold (SEED-01, SEED-02)

**Wave 2** *(parallel — E2E fixtures + host dunning bug fix)*

- [x] 178-02-PLAN.md — seed_edge_states!/0 + seed_overflow!/0 + e2e_plug routes (SEED-01, SEED-02)
- [x] 178-03-PLAN.md — host dunning bug fix (hero_accounts.exs phantom UUIDs) + regression test + CI runner allowlists (SEED-02)

**Wave 3** *(blocked on Wave 2 — host dev seed)*

- [x] 178-04-PLAN.md — edge_states.exs (canceling sub, JPY charge, long-name customer) + seeds.exs wire (SEED-01, SEED-02)

**UI hint**: yes

### Phase 179: F — Screenshot-Driven Visual QA Loop & Sign-off

**Goal:** Prove the milestone's "done" with evidence: sweep the full screen inventory across all four matrix cells, score each screenshot against the 10 dimensions, remediate until nothing is below bar, and sign off with a scorecard + before/after evidence + axe in both themes.
**Depends on:** Phase 174, Phase 175, Phase 176, Phase 177, Phase 178
**Requirements:** QA-01, QA-02, QA-03
**Success Criteria** (what must be TRUE):

  1. The Playwright screenshot harness sweeps the full screen inventory (all ~20 screens incl. detail pages) across {desktop, mobile} × {light, dark}.
  2. An LLM-analysis step scores each screenshot against the 10-dimension rubric and emits structured findings (screen, dimension, score, defect, suggested fix), driving a remediation loop until no dimension scores below 2.
  3. A final scorecard shows every dimension ≥2 across all four matrix cells with before/after evidence, and axe passes in both light and dark themes.

**Plans:** 3 plans across 2 waves

Plans:
**Wave 1** *(parallel — independent files)*

- [x] 179-01-PLAN.md — Expand admin-visuals.spec.js shots[] 12→21 (3 fixtures, corrected routes) + @anthropic-ai/sdk devDep + score-visuals npm script (QA-01)
- [x] 179-02-PLAN.md — score-visuals.mjs (LLM scoring, no-op without key, findings schema) + admin-motion-trace.spec.js (4 motion surfaces, trace: "on") (QA-02, QA-03)

**Wave 2** *(blocked on Wave 1)*

- [x] 179-03-PLAN.md — Extend admin-a11y.spec.js to 21 surfaces (full inventory, edge states) + SIGN-OFF.md scaffold aggregating 176/177/178 evidence + axe + before/after scorecard (QA-01, QA-02, QA-03)

**UI hint**: yes

</details>

<details>
<summary>✅ v1.50 Admin UI Foundation (Phases 167-173) — SHIPPED 2026-06-02 (PR #32; archived 2026-06-03)</summary>

- [x] Phase 167: Design Tokens & Motion Foundation — completed 2026-06-02 (AUI-01)
- [x] Phase 168: Typography & Icon System — completed 2026-06-02 (AUI-02)
- [x] Phase 169: IA — Home, Nav & Search — completed 2026-06-02 (AUI-03)
- [x] Phase 170: Cross-Screen Threading & Microcopy — completed 2026-06-02 (AUI-04)
- [x] Phase 171: Shared Detail Components & Refactor — completed 2026-06-02 (AUI-05)
- [x] Phase 172: Seed Enrichment & Component Kitchen — completed 2026-06-02 (AUI-06)
- [x] Phase 173: Rubric Audit & Visual/A11y Coverage — completed 2026-06-02 (AUI-07)

Full details: [v1.50 roadmap archive](milestones/v1.50-ROADMAP.md)

</details>

<details>
<summary>✅ v1.49 Realistic Demo App & Adoption Evidence (Phases 163-166) — SHIPPED 2026-06-02</summary>

- [x] Phase 163: Realistic Domain & Rich Seeds (1/1 plan) — completed 2026-06-01
- [x] Phase 164: Docker DX & Optimized Caching (2/2 plans) — completed 2026-06-01
- [x] Phase 165: E2E Automation & Shift-Left CI (4/4 plans) — completed 2026-06-02
- [x] Phase 166: Adoption DX Docs (3/3 plans) — completed 2026-06-02

Full details: [v1.49 roadmap archive](milestones/v1.49-ROADMAP.md)

</details>

<details>
<summary>✅ v1.48 Release Readiness + Stable Core Posture (Phases 159-162) — SHIPPED 2026-06-01</summary>

- [x] Phase 159: Linked Release Readiness + Publish Proof (2/2 plans) — completed 2026-06-01
- [x] Phase 160: Stable-Core Public Positioning (3/3 plans) — completed 2026-05-31
- [x] Phase 161: Backlog Anchor Closure + Pause Rule (1/1 plan) — completed 2026-06-01
- [x] Phase 162: Close gap: REL-01/REL-03 — linked release proof (4/4 plans) — completed 2026-06-01

Full details: [v1.48 roadmap archive](milestones/v1.48-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 163. Realistic Domain & Rich Seeds | v1.49 | 1/1 | Complete | 2026-06-01 |
| 164. Docker DX & Optimized Caching | v1.49 | 2/2 | Complete | 2026-06-01 |
| 165. E2E Automation & Shift-Left CI | v1.49 | 4/4 | Complete | 2026-06-02 |
| 166. Adoption DX Docs | v1.49 | 3/3 | Complete | 2026-06-02 |
| 167. Design Tokens & Motion Foundation | v1.50 | ✓ | Complete | 2026-06-02 |
| 168. Typography & Icon System | v1.50 | ✓ | Complete | 2026-06-02 |
| 169. IA — Home, Nav & Search | v1.50 | ✓ | Complete | 2026-06-02 |
| 170. Cross-Screen Threading & Microcopy | v1.50 | ✓ | Complete | 2026-06-02 |
| 171. Shared Detail Components & Refactor | v1.50 | ✓ | Complete | 2026-06-02 |
| 172. Seed Enrichment & Component Kitchen | v1.50 | ✓ | Complete | 2026-06-02 |
| 173. Rubric Audit & Visual/A11y Coverage | v1.50 | ✓ | Complete | 2026-06-02 |
| 174. A — Design-System Gap Closure & Token Completeness | v1.51 | 7/7 | Complete   | 2026-06-04 |
| 175. B — Persona-Driven IA Spine | v1.51 | 7/7 | Complete   | 2026-06-04 |
| 176. C — Systematic Per-Screen Rubric Uplift | v1.51 | 6/6 | Complete   | 2026-06-04 |
| 177. D — Motion & Micro-interaction Design | v1.51 | 6/6 | Complete   | 2026-06-04 |
| 178. E — Seed Expressiveness & State Coverage | v1.51 | 4/4 | Complete   | 2026-06-04 |
| 179. F — Screenshot-Driven Visual QA Loop & Sign-off | v1.51 | 3/3 | Complete   | 2026-06-05 |
| 180. Brand Audit & DNA Lock | v1.52 | 4/4 | Complete    | 2026-06-12 |
| 181. SVG Pipeline + Tournament Round 1 — Divergent | v1.52 | 7/7 | Complete    | 2026-06-13 |
| 182. Tournament Convergent Refinement | v1.52 | 3/3 | Complete    | 2026-06-13 |
| 183. Logo System Production | v1.52 | 4/4 | Complete    | 2026-06-13 |
| 184. Design Tokens & Specimens | v1.52 | 5/5 | Complete    | 2026-06-14 |
| 185. Voice, Microcopy & Marketing Copy | v1.52 | 3/3 | Complete   | 2026-06-14 |
| 186. HTML Brand Book Assembly & Quality Gate | v1.52 | 2/3 | In Progress|  |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only as historical, non-active planning context. They do not create milestone scope unless a fresh sourced friction row meets the current stable-core evidence bar.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Historical / non-active Braintree and multi-processor integration anchor; materially shipped across v1.31+ and reflected in the processor support matrix. Reopen only for a concrete adopter failure mode or operational failure in the shipped processor-support contract.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Historical / non-active billing portal configuration anchor; materially shipped via `accrue_portal`, guides, and host proof. Reopen only for a repeated support issue or correctness/data-loss risk in the portal support surface.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Historical / non-active admin UI role-based access anchor; no current broad feature scope follows from this link. Reopen only for a concrete security/compliance requirement or explicit strategy change.

## Deferred Seeds and Ideas (dormant / trigger-bound)

| Item | Status | Reason | Future owner/category | Revisit trigger |
|------|--------|--------|-----------------------|-----------------|
| SEED-001 | resolved historical context | Linked-release purpose was superseded by later linked publish work and Phase 159 release-readiness proof. | Release readiness / archive traceability | operational failure in linked release proof or explicit strategy change in release process |
| SEED-002 | dormant future roadmap | Ecosystem integrations are useful blueprints but are not v1.48 closeout blockers and do not create default milestone scope. | Future roadmap / ecosystem integrations | concrete adopter failure requiring one listed integration, repeated support issue, or explicit strategy change |
| ENT-EXT-01 | deferred | Rich metered, tiered, and range entitlement math is beyond current seat-count support and lacks a sourced adopter contract. | Entitlements extension | concrete adopter failure or explicit adopter contract requiring richer entitlement math |
| FIN-03 | standing non-goal | App-owned finance exports remain outside Accrue's declared billing-library scope. | Strategy non-goal / finance exports | explicit strategy change or correctness/security/data-loss risk that cannot be solved by host-owned exports |
