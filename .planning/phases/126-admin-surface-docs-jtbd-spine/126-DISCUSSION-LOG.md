# Phase 126: Admin Surface + Docs / JTBD Spine - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-23
**Phase:** 126-admin-surface-docs-jtbd-spine
**Areas discussed:** Admin entitlements view (placement / shape / drift surfacing / data path), `guides/entitlements.md` structure & SSOT-linking, JTBD ⛔→✅ flip + "Start here" spine, Green package-doc verifiers

**Mode:** Cohesive-synthesis (standing user preference, config-enforced: `discuss_auto_all_gray_areas` +
`discuss_high_impact_confirm` + `discuss_auto_resolve_low_impact`). Four parallel `gsd-advisor-researcher`
agents researched the four gray areas (one per success criterion). All decisions grounded against live code
(resolver signature, verifier script, guide anchors). **Zero forks crossed the confirm bar — no user
questions asked, consistent with phases 123–125.**

---

## Admin entitlements view — placement & shape (ENT-11, SC#1)

| Option | Description | Selected |
|--------|-------------|----------|
| Tab on existing CustomerLive | `/customers/:id?tab=entitlements` — clone the proven read-only tabbed pattern; per-customer; zero new route/LiveView wiring; reversible | ✓ |
| Dedicated nested route | `/customers/:id/entitlements` (new LiveView) — breaks the `?tab=` convention; re-plumbs scope/breadcrumbs; YAGNI for read-only | |
| Standalone `/entitlements` index | top-level fleet list — wrong primary unit (entitlements have no identity); heavy build; duplicates CustomersLive | |

**Choice:** Entitlements tab on CustomerLive (D-01).
**Notes:** Matches Stripe Dashboard's "Entitlements section inside customer detail." Lowest-ceremony,
consistent, reversible. A standalone fleet index is deferred to post-v1.0.

---

## Admin view — drift surfacing & data path (ENT-11, SC#1)

| Option | Description | Selected |
|--------|-------------|----------|
| List entitling subs + badge unmapped price_ids | Rebuild the `price_id→plan` reverse-index, badge any active sub missing from it; the only way to show subs the resolver silently drops | ✓ |
| Surface via telemetry `reason: :unmapped_plan` | Reuse the emitted signal — but telemetry is fire-and-forget, not queryable from a mount | |
| Full config-vs-active diff table | Most complete, but information overload defeats "by eye" | |
| Data path: reuse resolver fold via minimal additive helper | No new public `Accrue.*` API (D-07 stays deferred); reuse fold to avoid drift; read entitling subs + config for unmapped | ✓ |
| Data path: re-implement the fold in admin | Rejected — duplicates `LocalMap` logic → SSOT drift | |

**Choice:** Badge unmapped subs (D-03) + reuse the resolver's SSOT fold via a minimal additive helper (D-04).
**Notes:** Grounding fact — `LocalMap.resolve/2` takes a *billable* and looks the Customer up backwards;
admin already holds a `%Customer{}` and the fold/reverse-index/entitling-query are private. Exact helper
shape left to researcher/planner with hard constraints (no drift, no public gate API, one-way dep).
The resolver's silent-drop of unmapped items (`handle_unmapped/3 :deny`) is why drift must be read
independently. Copy/VERIFY-01 discipline applies (D-05).

---

## `guides/entitlements.md` — structure, depth, SSOT-linking (ENT-12, SC#2)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Fail-closed-first narrative spine | gate API → config → Plug → LiveView → trimmed truth table + link → provider prose + link → telemetry → Related guides; defer truth to SSOTs | ✓ |
| B. Reference-card layout | terse API/config tables, link-only to SSOTs — too thin for the "full story" SC | |
| C. Tutorial walkthrough | one running example, tables fully inlined — duplicates SSOTs (drift risk), overlaps first_hour | |

**Choice:** Option A (D-06), with trimmed-inline truth table + link, prose-only provider fact + link
(D-07), hub-and-spoke cross-linking with truth flowing one direction (D-08).
**Notes:** Mirrors `connect.md`/`webhooks.md` peer shape. Auto-globbed into HexDocs (no mix.exs edit).
Truth-table anchor `#lifecycle--entitlement-truth-table` verified to exist in lifecycle_semantics.md.

---

## JTBD ⛔→✅ flip + "Start here" spine (ENT-12, SC#3)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Promote to full body section + first-class day-1 onboarding step | over-claims (entitlements is an integration over billing, not an install step); bloats the verifier-pinned First Hour spine | |
| B. New body section + scope flip + spine as "next, when you need to gate" pointer | honest journey placement; leaves First Hour's pinned spine intact; fits the two-artifact re-run system | ✓ |
| C. Scope/FRONTIER flip only, no body section | under-tells a now-shipped headline capability; body/scope mismatch | |

**Choice:** Option B (D-09..D-12).
**Notes:** New `## Gate access on what they paid for` between "The customer changes their mind" and "When
payments fail." Honest phrasing: core shipped, optional Stripe-native sync deferred (Phase 127, off by
default). Mirror in internal JTBD-FRONTIER.md (move to Shipped + rewrite TL;DR/delta/DoD), Update-log entry
in both. README + quickstart get a pointer bullet; First Hour pinned spine left untouched.

---

## Green package-doc verifiers (ENT-12, SC#4)

| Option | Description | Selected |
|--------|-------------|----------|
| A. Add `gateway subscription core` to PROJECT.md | restores SSOT parity (phrase already pinned in 4 sibling files); greens 6/8 Elixir tests; fold into this phase | ✓ |
| B. Relax/remove the PROJECT.md assertion | creates asymmetric drift the verifier exists to prevent | |
| Tight new-needle set | README→entitlements link, 3 anchors in the guide, JTBD flip-guard | ✓ |
| Broad new-needle set | pin telemetry/gate-fns across many files — brittle, over-pinning | |

**Choice:** Fold the pre-existing needle fix (D-13) + a tight new-needle set (D-14) + mandatory
`seed_tmp_dir!` co-update (D-15).
**Notes:** Verifier is RED on `main` now (`verify_package_docs.sh:220` short-circuit) — SC#4 is literally
unsatisfiable without the fix. The Elixir wrapper shells out to the same bash script, so any NEW file a
needle references (`entitlements.md`, plus the not-yet-seeded `jobs_to_be_done.md`) must be added to the
fixture copy list. Flip-guard absent-regex must account for the historical Update-log "headline gap" line.
Verify green: `bash scripts/ci/verify_package_docs.sh` + `mix test .../package_docs_verifier_test.exs`
(8/0) + `mix docs`.

---

## Claude's Discretion

All five areas auto-resolved via subagent research per the standing cohesive-synthesis preference — no
decision crossed the confirm bar (no irreversible move, no externally-published-maintainer commitment, no
genuine product-vision fork; additive/reversible and coherent-doc-reconciliation decisions auto-resolve).
The one declined irreversible-shaped move: no new public `Accrue.*` gate/diagnostic API (Phase 123 D-07
deferral preserved). The exact admin read-seam helper shape is delegated to the researcher/planner within
hard constraints (D-04).

## Deferred Ideas

- Optional Stripe-native webhook→cache sync + grant/revoke + ledger writes + `native` capability row
  (ENT-10) → Phase 127.
- Public `Accrue.fetch_entitled/2` boolean-diagnostic API (Phase 123 D-07) → still deferred.
- Standalone `/entitlements` fleet drift index → post-v1.0, if operators ask.
- Grant-override admin actions / dedicated drift dashboard → future (this phase is read-only).
- Atomic seat enforcement / membership management → host-owned recipe, never a core API.
