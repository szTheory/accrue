# Phase 185: Voice, Microcopy & Marketing Copy - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a committed **voice system** plus a complete set of **ready-to-paste copy blocks** for every adopter-facing surface, all consistent with the ratified Brand DNA (Phase 180) and reviewed/approved by the user in one batch.

In scope (per ROADMAP success criteria + COPY-01/COPY-02):
- Voice system doc: voice principles, tone sliders, vocabulary use/avoid, say-this/not-this examples.
- Copy blocks committed to `brandbook/`: GitHub repo description + topics, Hex.pm package description, HexDocs intro paragraph, README hero, landing-page sections (hero / problem / solution / install / benefits / comparison / CTAs), release-note + changelog voice templates, and error/empty/success-state microcopy examples.
- One-batch user review/approval of all copy blocks.

Out of scope: HTML brand book assembly (Phase 186); logo/token artifacts (Phases 181–184); actually deploying a landing page (copy is written ready-to-paste, not shipped to a live site this phase); rewriting the live root `README.md` beyond providing the approved hero block (the brand book holds the canonical copy; applying it to repo surfaces is downstream).
</domain>

<decisions>
## Implementation Decisions

### Comparison-block framing  *(user-confirmed — the one public-reputational call)*
- **D-01:** Credit **Pay (Rails)** and **Laravel Cashier (PHP)** graciously **in prose** as cross-ecosystem inspirations — NOT as comparison-table rows. A Phoenix dev never chooses between Accrue and a Rails/PHP lib; the ecosystem norm (Pay/Cashier themselves credit predecessors) is to honor, not target.
- **D-02:** The comparison **table names only `stripity_stripe` + the raw Stripe API** — the things an Elixir dev actually weighs Accrue against. Each row is framed as a **verifiable capability fact** (e.g. stripity_stripe pinned to the 2019 Stripe API; no Ecto-native domain modeling), never a value judgment.
- **D-03:** **Drop Bling entirely.** Naming a small same-ecosystem sibling critically reads as punching down — the opposite of the "generous" voice adjective.
- **D-04:** Keep the internal "migration pain / design regrets earlier libraries accumulated" language as **private motivation only**. Public copy states what Accrue *does*, never what others got wrong.

### Hero line strategy  *(split by surface — universal OSS precedent: Oban, Ash, Prisma, Drizzle)*
- **D-05:** **Search-indexed / out-of-context surfaces lead with the concrete descriptor.** GitHub repo description, Hex `description:`, social/OG card → descriptor-forward, must contain "Elixir billing library" (DNA qualifier rule + SEO).
  - GitHub repo description: `Billing state, modeled clearly — the Elixir billing library for Phoenix apps`
  - Hex `description:`: lead with indexed category + scannable feature nouns, e.g. `The Elixir-native billing library for Phoenix apps. Subscriptions, checkout, invoices, webhooks.`
  - Social/OG card: descriptor as scannable headline, tagline as smaller kicker.
- **D-06:** **Engaged surfaces lead with the tagline.** README H1 + landing hero keep `Billing state, modeled clearly.` with the descriptor as the paired subhead. The current root README hero is already correct — provide it as the approved block, don't restructure it.
- **D-07:** Encode the rule in the voice doc: *tagline leads only when a human is already on the page (README, landing); descriptor leads wherever the string is search-indexed or seen out of context.*

### Tone sliders  *(anchored default + bounded per-surface deltas — "one voice, many tones")*
- **D-08:** Two labeled 5-point scales (1 = far-left pole, 5 = far-right pole). **Formal↔Casual anchor = 3** (professional, not stiff; contractions allowed, no slang/buddy-speak). **Precise↔Evocative anchor = 4** (literal/exact by default; evocative only in service of clarity, never decoration). The high precise + centered-leaning-formal anchors encode the anti-fintech-gloss / anti-hype posture into the numbers.
- **D-09:** Voice adjectives (measured, exact, native, durable) stay **fixed**; tone shifts per surface within a **±1-step cap** so voice never breaks. Per-surface delta table:
  | Surface | Formal↔Casual | Precise↔Evocative |
  |---|---|---|
  | API reference (HexDocs) | 4 | 5 |
  | README | 3 (anchor) | 4 (anchor) |
  | Landing / marketing | 2 | 3 |
  | Release notes | 2–3 | 4 |
  | Error / empty-state microcopy | 3 | 5 |

### Claims posture  *(proof-led / show-don't-claim — Accrue uniquely ships VERIFY-01)*
- **D-10:** State capability as a **mechanism or named artifact, not an adjective.** Substantiate strong claims with evidence the reader can verify (VERIFY-01 Fake-backed proof path, merge-blocking verification suite, tamper-evident append-only ledger, telemetry on every context fn). This is automatically anti-hype compliant — no adjectives to police.
  - YES: "Every webhook is signature-verified before it touches your database, and can't be bypassed." / "Ships complete at v1.0: subscriptions, checkout, invoices, coupons, emails, PDFs, admin UI." (let the list assert completeness) / "A tamper-evident, append-only event ledger records every billing state change."
  - NO: "production-grade", "batteries-included", "bank-grade security", "the modern alternative".
- **D-11:** **CTAs are literal next-actions**, no funnel tone: primary `Get started` (dev-tool norm, reads as docs) or `Install`; secondary `Read the guide`, `View on Hex`, `Browse the source`. Sub-CTA = honest spec (`MIT · Elixir 1.17+ · Phoenix 1.8+`). Banned: `Start free`, `Try it now`, `Get billing in minutes`, exclamation marks, "demo".

### Claude's Discretion
- File organization of the voice doc + copy blocks within `brandbook/` (single `voice.md` + `copy.md` vs per-surface files) — planner/executor decides; keep it browser-readable for Phase 186 assembly.
- Exact wording of each individual copy block beyond the locked patterns above — drafted by executor, surfaced in the one-batch review (success criterion #3).
- Whether the comparison table is Markdown vs a small structured artifact — executor's call.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand foundation (binding — voice + positioning source of truth)
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` — ratified positioning, palette, typography, Voice (adjectives measured/exact/native/durable; DO direct/calm/precise/practical/literate/generous; DON'T hype/sales language/consumer-finance wording), tagline. **All Phase 185 copy must be consistent with this.**
- `.planning/phases/180-brand-audit-dna-lock/BRAND-AUDIT.md` §2.4 (Voice), §2.6 (Tagline — the abstract-vs-scannable split this phase resolves), §2.7, §3 dims 6/12/14 — the gap analysis that scoped Phase 185 ("voice principles exist; voice expressions do not yet").

### Requirements & roadmap
- `.planning/ROADMAP.md` (Phase 185 detail, lines 213–224) — goal + 3 success criteria.
- `.planning/REQUIREMENTS.md` — COPY-01 (voice system) and COPY-02 (copy blocks), lines 58–59.

### Existing copy surfaces to align with (read before drafting)
- `README.md` (root) — current hero (`# Accrue` / `Billing state, modeled clearly.` / descriptor line) — already matches D-06; provide as approved block, don't restructure. Also the source of the internal "billing facade/engine" framing and the VERIFY-01 proof-path language usable as evidence (D-10).
- `accrue/mix.exs` line 17 — current Hex `description:` = "Billing state, modeled clearly." (to be updated per D-05).
- `brandbook/` — destination dir; existing `tokens/`, `logo/`, `examples/`, `README.md` show the established brand-book layout the new voice + copy files join.

### Project north star (for claims posture grounding)
- `CLAUDE.md` (project instructions) — Core Value statement (launch a real SaaS on day one), required/optional deps, security posture (webhook verification non-bypassable, no PII), observability — the substantiated facts behind D-10 proof-led claims.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/README.md` + existing `tokens/`/`logo/`/`examples/` — established brand-book file conventions; new voice/copy files should match register and be self-contained for `file://` rendering (Phase 186 inlines everything).
- Root `README.md` hero + "Proof path (VERIFY-01)" section — already-written, on-brand prose to mine for the hero block and proof-led benefit copy.

### Established Patterns
- Brand DNA → downstream phase consumption: every brand phase (181–184) reads BRAND-DNA.md as binding. Phase 185 continues this — voice copy is the *expression* layer of the same DNA.
- Anti-hype is structurally enforced by the DON'T list; D-10 makes it self-enforcing by banning adjective-led claims in favor of verifiable mechanisms.

### Integration Points
- Phase 186 (HTML Brand Book Assembly) consumes everything this phase commits to `brandbook/` — keep copy blocks in clean, inlinable, ≤2 MB-budget-friendly source.
- Copy blocks are written ready-to-paste; applying them to live repo surfaces (GitHub description, Hex `description:`, README) is a downstream/host action, not this phase.
</code_context>

<specifics>
## Specific Ideas

- Comparison table content is **factual capability rows** (stripity_stripe's 2019-pinned Stripe API, no Ecto-native modeling; raw Stripe API = no domain layer) — falsifiable engineering facts, not verdicts.
- "Sounds like a maintainer you trust" is the memorable voice direction from the audit — use it as the voice-doc north star.
- Proof-led exemplars to emulate in register: Litestream, SQLite, Oban, Tailscale (calm, evidence-forward). Avoid the fintech-gloss/adjective-led register entirely.
</specifics>

<deferred>
## Deferred Ideas

- Deploying an actual landing-page website with this copy — out of scope; this phase produces ready-to-paste blocks only. Candidate for a future marketing/site phase.
- Applying the approved copy to live repo surfaces (rewriting GitHub repo description, Hex `description:`, root README) — downstream host action after approval, not Phase 185 build work.

None of the discussion raised new capabilities — stayed within phase scope.
</deferred>

---

*Phase: 185-voice-microcopy-marketing-copy*
*Context gathered: 2026-06-14*
