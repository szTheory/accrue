# Phase 185: Voice, Microcopy & Marketing Copy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 185-voice-microcopy-marketing-copy
**Areas discussed:** Comparison framing, Hero line strategy, Tone slider positions, Claims posture
**Mode:** advisor (minimal_decisive tier; technical owner). 4 parallel advisor-research agents grounded each area in Elixir/Rails/JS OSS positioning idioms; cohesive default package presented; only the public-reputational call (comparison framing) escalated for explicit sign-off per user profile.

---

## Comparison framing  *(escalated — names real OSS projects in public copy)*

| Option | Description | Selected |
|--------|-------------|----------|
| Lock as recommended | Credit Pay/Cashier in prose; table = stripity_stripe + raw Stripe API as factual rows; drop Bling; keep "design regrets" language private | ✓ |
| Include Bling in table | Also name Bling (Elixir) — risks punching down at a same-ecosystem sibling | |
| No named competitors | Oban-style: name zero rivals, differentiate purely on capability | |

**User's choice:** Lock as recommended.
**Notes:** Research convergent across Oban (names no rivals), Prisma/Drizzle (name + concede strengths + conditional steer), Pay/Cashier (credit predecessors graciously). Differentiator stated as verifiable fact (stripity_stripe 2019-pinned API, no Ecto-native modeling), not verdict.

---

## Hero line strategy  *(decisive default — accepted in package)*

| Option | Description | Selected |
|--------|-------------|----------|
| Split by surface | Descriptor leads search-indexed surfaces (GitHub desc, Hex one-liner, OG card); tagline leads engaged surfaces (README H1, landing hero) with descriptor as paired subhead | ✓ |
| Tagline-first everywhere | Lead all surfaces with "Billing state, modeled clearly." — breaks §2.6 audit + omits "Elixir billing library" from indexed strings | |

**User's choice:** Split by surface (accepted as part of the cohesive package).
**Notes:** Universal OSS precedent (Oban, Ash, Prisma, Drizzle all lead indexed one-liners with concrete category, reserve poetic tagline for landing/README). Resolves audit §2.6. Current root README hero already correct.

---

## Tone slider positions  *(decisive default — accepted in package)*

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed positions everywhere | One slider position, no surface variance — risks flat landing copy / over-stiff microcopy | |
| Anchored default + bounded per-surface deltas | Anchor Formal↔Casual=3, Precise↔Evocative=4; ±1-step per-surface deltas; voice adjectives fixed | ✓ |

**User's choice:** Anchored default + bounded deltas (accepted as part of the cohesive package).
**Notes:** "One voice, many tones" (Mailchimp/Atlassian/GOV.UK/Google). Holding tone fixed across a release note and an error string would violate Accrue's own DO list (generous/literate vs calm/precise). ±1-step cap keeps the trusted-maintainer register intact.

---

## Claims posture  *(decisive default — accepted in package)*

| Option | Description | Selected |
|--------|-------------|----------|
| Proof-led / show-don't-claim | Capability as mechanism/artifact, not adjective; substantiate with VERIFY-01, ledger, telemetry; literal-action CTAs | ✓ |
| Calm-adjective (Litestream/SQLite register) | Understated but adjective-anchored ("production-grade, batteries-included") — trips the DON'T list, wastes Accrue's actual proof differentiator | |

**User's choice:** Proof-led (accepted as part of the cohesive package).
**Notes:** Accrue uniquely ships VERIFY-01, so its strongest claim ("launch a real SaaS on day one, production-grade") is re-expressed as verifiable evidence — more credible to devs and auto-compliant with the no-hype rule. CTAs: `Get started`/`Install`, `Read the guide`, `View on Hex`; banned `Start free`/`Try it now`/exclamation marks.

---

## Claude's Discretion

- File organization of voice doc + copy blocks within `brandbook/` (single vs per-surface files).
- Exact wording of each copy block beyond the locked patterns (surfaced in the one-batch review, success criterion #3).
- Comparison table as Markdown vs small structured artifact.

## Deferred Ideas

- Deploying a live landing-page website with this copy — future marketing/site phase.
- Applying approved copy to live repo surfaces (GitHub description, Hex `description:`, README) — downstream host action after approval.
