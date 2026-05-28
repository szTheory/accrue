# Phase 147: Per-subscription drill-down route + CampaignLive - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 147-per-subscription-drill-down-route-campaignlive
**Areas discussed:** Invoice context sourcing, Multi-campaign grouping, Timeline component strategy

---

## Invoice context sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| `campaign_timeline/2` raw + new `invoices_for_campaign/2` | `campaign_timeline/2` stays `[Event.t()]` per DAN-05 spec. New `Accrue.Analytics.Dunning.invoices_for_campaign/2` batch-loads invoice context (status, amount, card_last4, card_brand) keyed by invoice_id. CampaignLive calls both in `mount/3`. | ✓ |
| Event payload only, no extra queries | CampaignLive renders only what's already in event data maps. Drops invoice status/amount/payment-method context — fails Phase 147 UX goal. | |

**User's choice:** `campaign_timeline/2` raw + new `invoices_for_campaign/2`

**Notes:** User initially selected this option then requested deeper research across all areas. Second-round research (with ecosystem context from Elixir best-practices docs, Pay/Recurly/Oban Web comparison) confirmed this as the right choice. The cross-package boundary constraint (no Ecto/Repo in accrue_admin) makes this the only conformant option; DAN-05 locking `campaign_timeline/2` to `[Event.t()]` rules out enriched return types.

---

## Multi-campaign grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Flat `[Event.t()]`, grouping in CampaignLive | `campaign_timeline/2` returns flat list; CampaignLive does `Enum.chunk_by` locally. Adopters re-implement the `step_sent`-no-`campaign_anchor` edge case. | |
| `campaign_timeline/2` returns `[{anchor, [Event.t()]}]` | Changes the public API shape — violates DAN-05 "thin wrapper" spec. Step_sent orphan problem bites at the seam. Ruled out. | |
| `campaign_timeline/2` flat + new `campaign_timeline_grouped/2` | Elixir idiom: separate function per return shape. Pure function (~15 LOC, no DB) encapsulates the `step_sent` edge case once in the library. Both functions freeze in Phase 148 API doc pass. | ✓ |

**User's choice:** `campaign_timeline/2` flat + new `campaign_timeline_grouped/2` (after requesting deeper research)

**Notes:** User requested a full ecosystem research pass across all three areas, asking for Elixir/Phoenix idioms, lessons from comparable libs (Pay, Recurly, Oban Web, Stripe Dashboard), and one coherent recommendation set. Research surfaced Option C (`campaign_timeline_grouped/2`) as the missing option — not presented in the initial round. The Elixir best-practices brief explicitly warns against "alternative return types on the same function," and the adopter DX argument for centralizing the `step_sent`-no-`campaign_anchor` edge case in the library was decisive. Claude made the final call per user's profile (minimal_decisive: synthesize one recommendation and proceed).

---

## Timeline component strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `AccrueAdmin.Components.Timeline` with slots | Reuses existing component. Requires dual-mode logic (slots-or-strings), risks SubscriptionLive regression. Three distinct row types (anchor/step/terminal) don't fit uniform slot shape. | |
| New `AccrueAdmin.Components.CampaignTimeline` (purpose-built) | ~80-120 LOC. Full control over 3 row variants. Embeds StatusBadge + format_money/3 as first-class calls. Matches project precedent (KpiCard, AtRiskTable, FunnelChart). Zero risk to existing component. | ✓ |

**User's choice:** New `AccrueAdmin.Components.CampaignTimeline` (purpose-built) — made by Claude per minimal_decisive profile

**Notes:** Research confirmed the existing Timeline component uses plain string-map assigns (no slot/inner_block machinery). Embedding StatusBadge or format_money/3 inline per row requires either unsafe pre-rendered HTML or a structural rewrite. Project component precedent (every domain-specific view has its own component file) and Phoenix 1.8 ecosystem norm (Oban Web, LiveDashboard both use entity-specific renderers) both point to a purpose-built component.

---

## Claude's Discretion

The following implementation details were delegated to the planner:
- Exact Ecto query shape for `campaign_timeline/2` (in-memory filter vs. in-Ecto `where: e.type in ^dunning_types`)
- `invoices_for_campaign/2` join shape (single compound query vs. two-step load)
- Breadcrumb back-link URL construction
- CSS class names for `CampaignTimeline` row variants (`ax-campaign-timeline-*` prefix)
- Step numbering display string ("Attempt N" vs "Step N")
- Whether `invoices_for_campaign/2` opts thread `:since`/`:until` (recommend: no — drill-down is window-agnostic)

## Deferred Ideas

- Window selector on CampaignLive → post-v1.44 if operators request it
- MRR-at-risk per campaign arc → v1.45+
- Direct links from CampaignLive to Invoice/Subscription detail views → follow-on enhancement
- `campaign_timeline/2` `:types` opt for adopter-defined event filtering → when an adopter requests it
