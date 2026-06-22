---
id: 260622-admin-page-header-microcopy-audit
created: 2026-06-22
status: pending
area: accrue_admin
kind: ux-microcopy + consistency-audit
---

# Systematic audit: admin page-header microcopy (h1 + subtitle) across all sections

## Request (verbatim intent)

Revenue Recovery (`/admin/analytics/recovery`) has **no subtitle** while other pages do — the app
lacks a consistent feel/UX-microcopy across sections. Systematically audit the **page header** of
every admin section — the `<h1 class="ax-display">` + the `<p class="ax-body ax-page-copy">`
subtitle — and line them all up with the philosophy used on `/admin/customers`.

**Principles for the copy:**
- Consistent **look, feel, and UX microcopy** across every section.
- Oriented to the **user flow / lens / JTBD** that would be done on each page (who's here, what
  they're trying to do) — **user-facing language**, not internal design/backend jargon.
- Useful for orienting the user to **what they're doing** on this page.
- **Not boilerplate** — each subtitle earns its place; avoid filler.
- Every section page should HAVE a subtitle (recovery currently doesn't).

## Scope

All admin section pages — list/index AND the analytics/recovery + dashboard pages. For each:
audit the presence + quality of `h1.ax-display` and `p.ax-body.ax-page-copy`, then rewrite to a
consistent, JTBD-oriented voice modeled on `/admin/customers`. Candidate pages: dashboard/home,
customers, subscriptions, invoices, payments, webhooks, events, coupons, promotion-codes,
recovery (`/admin/analytics/recovery`), connect. Microcopy likely lives in `AccrueAdmin.Copy` +
each `*_live.ex` page header.

## Notes / context

- Pairs naturally with the in-flight list-page redesign (260621-olr: stat strip + filter toolbar)
  and the earlier de-jargon work (260620-qkx promoted each hero to a single `<h1>`); this is the
  **microcopy/voice** consistency pass on top of the structural one.
- Use the JTBD/persona source already mined: `.planning/research/v1.51-admin-ui-depth-design.md`
  (six personas + per-page jobs) and `guides/jobs_to_be_done.md`.
- Likely a `/gsd-quick --discuss` or `--validate` task (voice/microcopy benefits from a quick
  alignment on the customers "philosophy" before rewriting 11 pages).
