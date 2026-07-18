---
quick_id: 260718-nzm
title: Rebrand demo app CohortFlow (cohort/education) → Cadence (team project tracking)
status: complete
date: 2026-07-18
commit: 11b20b5f
---

# Quick Task 260718-nzm — Summary

## What changed
Rebranded the demo host's fictional customer SaaS from **CohortFlow** (cohort/education) to **Cadence**,
a relatable team **project-tracking** product (Linear/Asana-style), keeping the same visual style. 21 files:
- `demo_brand.ex` — product name, tagline, support/billing emails (`@cadence.test`), personas relabelled:
  Team Lead / Northwind Labs, Ops Manager / Tidewater Systems, Head of Engineering / Meridian Group
  (+ Redwood Studio, Pilot Works). Admin persona kept.
- `plans.ex` — Launch/Studio/Scale eyebrow/summary/features reframed for project tracking (labels + amounts
  unchanged; Scale keeps the usage-based tier as automation/API capacity).
- UI copy (`root.html.heex` monogram Cd + "Project tracking", home/pricing/registration/subscription_live/
  advanced_reports/page_html), `config.exs`+`test.exs` branding block, `dev_banner.ex`, seed org names
  (`hero_accounts.exs`), README + evaluator-walkthrough doc.
- 7 coupled tests updated; also fixed `subscription_flow_test.exs` + `org_billing_live_test.exs` which still
  referenced the tax-location form removed in 260718-iwa (pre-existing debt surfaced by a broader test run).

## Scope discipline
Kept generic **"workspace"**, plan labels (Launch/Studio/Scale), persona emails (`healthy@`…), org slugs,
and invoice numbers → **e2e specs needed no changes**.

## Verification
- `mix compile --warnings-as-errors` EXIT 0; `rg` for cohort/education tokens → 0 hits (lib/config/priv/test/docs).
- Updated tests green (incl. the 2 tax-debt fixes): 5/0 + earlier 15/0.
- `make reset` reseeded; login page shows Cadence / Team Lead · Northwind Labs, enterprise = Meridian Group,
  zero "cohort"; dev banner + FakeHydration (135/123) confirm new org names.

Demo-only; no core `accrue` change. Brand name/companies are picks — easily tweakable.
