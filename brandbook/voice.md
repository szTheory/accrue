# Accrue Voice System

Ratified: 2026-06-14 — Phase 185

---

## Voice Principles

*North star: "Sounds like a maintainer you trust."*

**Measured.** Accrue doesn't oversell. Every claim is sized to what the library actually does — no superlatives, no adjective-led marketing copy. A measured sentence names a mechanism. "Every webhook is signature-verified before it touches your database" says more than "secure."

**Exact.** Accrue names things precisely: context functions, append-only ledgers, merge-blocking CI, Fake-backed proof paths. Vague words ("it," "stuff," "various things") never appear in place of the actual noun. When a concept has a canonical name in the Elixir ecosystem, use it.

**Native.** Accrue speaks in Phoenix-developer idioms — Ecto schemas, OTP supervision, mix tasks, plugs, contexts. It doesn't borrow Rails vocabulary, fintech marketing language, or generic SaaS prose. A Phoenix developer should feel the library was built by someone who lives in the same ecosystem.

**Durable.** Accrue copy ages well. It avoids trend words, metaphors that date quickly, and version-specific promises. A sentence written for v1.0 should read as sound in v1.5. Prefer nouns to adjectives; mechanisms to claims.

---

## Do / Don't

| Do | Don't |
|----|-------|
| State the mechanism | Name the benefit without naming the mechanism |
| Use contractions in body copy | Force formality ("one may utilize", "it is recommended") |
| Name the exact artifact: "append-only ledger", "Fake processor", "merge-blocking CI" | Say "robust" or "reliable" without naming what makes it so |
| Lead with a Phoenix developer's vocabulary (Ecto, OTP, plug, context, mix task) | Import Rails or generic SaaS vocabulary |
| Credit predecessors generously (Pay, Laravel Cashier) | Target or compare against them critically |
| Use plain present tense: "Accrue owns the billing engine" | Hedge with "helps you," "makes it easy to," "lets you" |
| Write proof-checkable sentences | Write any sentence that can't be verified by reading the source |
| Keep tone calm across all surfaces | Express enthusiasm with exclamation marks or promotional language |
| Use concrete numbers and version strings: "Elixir 1.17+, Phoenix 1.8+" | Use vague scales: "modern," "latest," "cutting-edge" |

---

## Tone Sliders

Two labeled 5-point scales. Voice adjectives (measured, exact, native, durable) are fixed. Tone shifts per surface within a ±1-step cap so voice never breaks.

**Scale 1: Formal (1) ↔ Casual (5) — anchor = 3**

Anchor 3 means: professional and readable, not stiff. Contractions are fine ("you'll," "it's," "don't"). No slang, no buddy-speak, no filler phrases ("super," "awesome," "honestly"). A senior developer writing a trusted guide, not a salesperson or a friend texting.

**Scale 2: Precise (1) ↔ Evocative (5) — anchor = 4**

Anchor 4 means: literal and exact by default. Evocative language is permitted only in service of clarity — when an analogy or image makes the mechanism more concrete, not when it decorates a vague claim. "Append-only ledger" is precise and specific. "Audit trail" is evocative but still grounded. "Peace of mind" is decoration.

### Per-Surface Tone Deltas

| Surface | Formal ↔ Casual | Precise ↔ Evocative |
|---------|-----------------|---------------------|
| API reference (HexDocs) | 4 | 5 |
| README | 3 (anchor) | 4 (anchor) |
| Landing / marketing | 2 | 3 |
| Release notes | 2–3 | 4 |
| Error / empty-state microcopy | 3 | 5 |

Note: ±1-step cap rule — "Voice adjectives stay fixed; tone shifts within a ±1-step cap so voice never breaks."

---

## Surface Dispatch Rule

**Rule (D-07):** Tagline leads when a human is already on the page (README H1, landing hero). Descriptor leads wherever the string is search-indexed or seen out of context (GitHub repo description, Hex.pm, social/OG card).

**Why:** Search-indexed strings have no surrounding context — a reader who finds them via Google or Hex search needs the concrete category noun first ("Elixir billing library") to know what they are looking at. Scannable and SEO-legible. An engaged reader already on a README or landing page has context; they can receive the tagline ("Billing state, modeled clearly.") and encounter the descriptor as a paired subhead.

**Approved surface assignments:**

- GitHub repo description → descriptor-forward: `Billing state, modeled clearly — the Elixir billing library for Phoenix apps`
- Hex.pm `description:` → descriptor-forward: `The Elixir-native billing library for Phoenix apps. Subscriptions, checkout, invoices, webhooks.`
- Social/OG card → descriptor as headline, tagline as smaller kicker
- README H1 + hero → tagline first, descriptor as paired subhead
- Landing page hero → tagline first, descriptor as paired subhead

---

## Vocabulary

### Use

| Word or phrase | Rationale |
|----------------|-----------|
| billing state | Core noun from the tagline; grounds the domain in what the library actually tracks |
| domain model | Names the engineering artifact — Ecto schemas with explicit state machines |
| Ecto-native | Signals idiomatic integration, not a thin wrapper; preferred over "Ecto-compatible" |
| append-only | Describes the event ledger architecture precisely; implies immutability without claiming it |
| tamper-evident | Names the security property of the ledger in checkable terms |
| context function | Phoenix-idiomatic name for the public API of a context module |
| webhook signature | The exact name of the Stripe verification mechanism; use over "security" |
| merge-blocking | Describes CI enforcement with precision — pull requests are blocked, not "checked" |
| Fake processor | The name of the test double in Accrue's proof path; always capitalize as a proper noun |
| idiomatic | Appropriate when describing Elixir/Phoenix conventions; not a marketing word in this context |
| facade | The host-app boundary: MyApp.Billing is the billing facade |
| proof path | The VERIFY-01 evaluation sequence; use the full phrase when referring to it |
| proof-led | Describes the claims posture: substantiate with verifiable evidence |
| telemetry | Both the `:telemetry` library and the class of observability events; use precisely |

### Avoid

| Word or phrase | Rationale |
|----------------|-----------|
| production-grade | Banned adjective (D-10) — name the mechanism instead |
| batteries-included | Banned adjective (D-10) — list the components instead |
| bank-grade | Banned adjective (D-10) — name the security property instead |
| modern alternative | Banned adjective (D-10) — never positions against other libraries critically |
| seamless | Meaningless filler; every library claims it |
| powerful | Adjective-led; says nothing about what the library does |
| robust | Adjective-led; says nothing checkable |
| easy | Condescending and false — integration has real setup steps |
| effortless | Same as easy; patronizing |
| simple | Same register problem; prefer naming the actual effort |
| best-in-class | Superlative with no referent; not checkable |
| world-class | Same — generic marketing noise |
| wallet | Consumer-finance term; Accrue is a developer billing library |
| money | In marketing copy, use "billing," "invoice," or "subscription"; not "money" |
| funds | Consumer-finance term; use "payment" or "charge" with Stripe context |
| demo | Banned CTA word (D-11); replaced by "Get started" and "View on Hex" |

---

## Claims Posture

State capability as a mechanism or named artifact, not an adjective.

Substantiate strong claims with a verifiable mechanism the reader can inspect (VERIFY-01 proof path, merge-blocking CI, named schema field).

| YES | NO |
|-----|----|
| Every webhook is signature-verified before it touches your database, and can't be bypassed. | bank-grade security |
| Ships complete at v1.0: subscriptions, checkout, invoices, coupons, emails, PDFs, admin UI. | batteries-included |
| A tamper-evident, append-only event ledger records every billing state change. | production-grade |
| Pull requests are merge-blocked until `mix verify.full` passes. | extensively tested |
| Elixir 1.17+, Phoenix 1.8+, PostgreSQL 14+ — the exact floor, not "modern versions." | supports all modern Elixir versions |

---

## CTAs

CTAs are literal next-actions (D-11). Dev-tool norm: "Get started" reads as a docs entry point, not a sales funnel. The sub-CTA spec is an honest statement of compatibility, not a teaser.

### Approved primary CTAs

- `Get started`
- `Install`

### Approved secondary CTAs

- `Read the guide`
- `View on Hex`
- `Browse the source`

### Sub-CTA spec string

`MIT · Elixir 1.17+ · Phoenix 1.8+`

### Banned CTAs

- `Start free` — implies a paid tier that doesn't exist
- `Try it now` — sales funnel tone
- `Get billing in minutes` — false promise; setup has real steps
- Exclamation marks in any CTA
- `demo` — name the actual artifact ("Fake-backed proof path") or the action ("Get started")
