# Roadmap — v1.45 Multi-channel Dunning (In-App Banners)

**Milestone:** v1.45 — Multi-channel Dunning (In-App Banners)
**Builds on:** v1.44 (Recovered-Revenue Dashboard)
**Granularity:** standard
**Coverage:** 4/4 v1.45 requirements (BAN-01..BAN-04) mapped — 100%
**Phase numbering:** 149–150.

## Phases

- [ ] **Phase 149: Dunning state API & Headless Banner Component** — `Accrue.Dunning.requires_attention?/1` API and `<Accrue.Components.DunningBanner />` headless HEEx component.
- [ ] **Phase 150: Documentation & Adopter Proof** — `guides/dunning.md` integration docs and `examples/accrue_host` banner wiring.

## Phase Details

### Phase 149: Dunning state API & Headless Banner Component

**Goal:** Provide the core state-checking helper and the headless HEEx component so host apps can easily query and display dunning status.
**Depends on:** v1.44
**Requirements:** BAN-01, BAN-02
**Success Criteria** (what must be TRUE):
  1. `Accrue.Dunning.requires_attention?/1` correctly identifies active dunning campaigns without false positives from projection lag.
  2. The headless component correctly renders its inner block or default message when dunning is active, and renders nothing when not.
**Plans:** 0 plans complete
**UI hint:** yes

### Phase 150: Documentation & Adopter Proof

**Goal:** Document the new banner capability and prove it works in the example host app.
**Depends on:** Phase 149
**Requirements:** BAN-03, BAN-04
**Success Criteria** (what must be TRUE):
  1. `guides/dunning.md` contains clear copy/paste instructions for adding the banner to a Phoenix layout.
  2. `examples/accrue_host` displays the banner when the user logs in and their subscription is past due.
**Plans:** 2 plans

Plans:
- [ ] 150-01-PLAN.md — Add the "In-App Banners" section to guides/dunning.md (BAN-03)
- [ ] 150-02-PLAN.md — Wire the dunning banner into examples/accrue_host + seed + adoption-proof row (BAN-04)
**UI hint:** no

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 149. Dunning state API & Headless Banner Component | 0/2 | Planned | |
| 150. Documentation & Adopter Proof | 0/2 | Planned | |
