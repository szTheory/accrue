# Requirements: Accrue v1.30 — `1.0.0` Declaration (Spine A)

**Defined:** 2026-04-26
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one — complete, production-grade, with idiomatic Elixir DX, strong domain modeling, tamper-evident audit ledger, great observability, and zero breaking-change pain through v1.x.

**Milestone goal:** Cut `accrue` / `accrue_admin` `1.0.0` on a single linked Hex publish, with the final post-publish contract sweep verifying everything is consistent at `1.0.0`, the planning mirror aligned, the stability posture flipped from "pre-1.0 closure" to "1.0.0 stable, post-1.0 cadence," and a dated post-publish friction-inventory maintainer pass certifying the post-1.0 surface. **`PROC-08` (second processor) and `FIN-03` (app-owned finance exports) remain explicitly out of scope at 1.0.0** — calling stable does not lift those non-goals.

**Strategic spine:** Spine A from the v1.27 strategic wrap-up plan (the `1.0.0` declaration), forcing function deferred since v1.28 across v1.27/28/29 (which closed cleanly with no half-finished migrations overhanging the surface).

**Precedent:** v1.11 (`REL-01..04`, `DOC-01..02`, `HYG-01` — first linked Hex publish) and v1.23/v1.28 (`PPX-01..08` — post-publish contract alignment). REQ-IDs continue those families.

## v1.30 Requirements

### Release cut (REL — continues from REL-04 / v1.11)

- [ ] **REL-05**: Linked `1.0.0` Hex publish for `accrue` and `accrue_admin` ships as a single coordinated release (both packages bumped to `1.0.0` in the same PR / on the same day; release-train order matches `RELEASING.md` for the `accrue → accrue_admin` pair)
- [ ] **REL-06**: `CHANGELOG.md` "1.0.0 — Stable" entry per package (`accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md`), Conventional-Commits / Release-Please-rendered, calling out the API stability commitment under v1.x
- [ ] **REL-07**: `RELEASING.md` post-1.0 cadence section documents semver discipline, deprecation policy, and what changes after stable (replaces / supersedes the "pre-1.0 closure" narrative shipped in v1.27 CLS-02)
- [ ] **REL-08**: Planning git tag `v1.30` after milestone close (mirrors v1.27 / v1.29 tag discipline; tag follows the linked Hex publish landing on `main`)

### Post-publish contract alignment at 1.0.0 (PPX — continues from PPX-08 / v1.28)

- [ ] **PPX-09**: `verify_package_docs` re-runs clean at `1.0.0` (install literals / `~>` pins follow `mix.exs @version` for both packages; same merge-blocking discipline as v1.11 DOC-02 + v1.23 PPX-01..04 + v1.28 PPX-05..08)
- [ ] **PPX-10**: `verify_adoption_proof_matrix` re-runs clean at `1.0.0` (matrix rows + needles + per-row evidence refreshed for the `0.3.1 → 1.0.0` jump; merge-blocking)
- [ ] **PPX-11**: `docs-contracts-shift-left` six-script bundle re-runs clean at `1.0.0` (full bundle parity with v1.28 Phase 86 086-VERIFICATION evidence, re-aligned to the new `1.0.0` registry reality)
- [ ] **PPX-12**: First Hour + host README + adoption matrix needles refreshed across the integrator surface for the `0.3.1 → 1.0.0` jump (single-PR co-update discipline from v1.19 PRF; same-PR coupling between needle edits and verifier scripts)

### Planning mirror (HYG — continues from HYG-01 / v1.11)

- [ ] **HYG-02**: `.planning/` mirror pass aligns `PROJECT.md`, `MILESTONES.md`, `STATE.md` to the published `1.0.0` pair after the linked publish lands (read-only context citations updated; no public-facing artifacts touched in this requirement — that's PPX-09..12)

### Stability posture & non-goals reaffirmation (DOC — continues from DOC-02 / v1.11+v1.19)

- [ ] **DOC-03**: `accrue/README.md` Stability section + root README maintenance posture flipped from "pre-1.0 closure" / "intake-gated" framing to "1.0.0 stable, post-1.0 cadence" (cross-linked from `RELEASING.md` REL-07 and `accrue/guides/maturity-and-maintenance.md`)
- [ ] **DOC-04**: PROJECT.md non-goals section retained at 1.0.0 — `PROC-08` (second processor) and `FIN-03` (app-owned finance exports) reaffirmed as explicitly out of scope with written boundaries (calling stable does NOT lift these non-goals; revisit only via explicit later-milestone reprioritization, same posture as v1.27 CLS-03)

### Friction inventory (INV — continues from INV-06 / v1.28)

- [ ] **INV-07**: Post-1.0 dated maintainer pass `(b)` in `.planning/research/v1.17-FRICTION-INVENTORY.md` certifying the inventory remains accurate at `1.0.0` (same path-(b) pattern as INV-03..06, with verifier transcripts under the milestone phase tree)

## Future Requirements (deferred to later milestones)

### Second processor (PROC — long-deferred)

- **PROC-08**: First-party Paddle / Lemon Squeezy / Braintree adapter — explicitly deferred since v1.8; reaffirmed at 1.0.0 (DOC-04). Revisit only with a later milestone that prioritizes it with written boundaries.

### App-owned finance exports (FIN — long-deferred)

- **FIN-03**: App-owned finance exports (revenue recognition, GAAP-aligned reporting, accountant-facing CSV/parquet exports) — explicitly deferred since v1.8; reaffirmed at 1.0.0 (DOC-04). Accrue is a billing/subscription library, not an accounting system. Revisit only with a later milestone that prioritizes it with written boundaries.

## Out of Scope

Explicitly excluded from v1.30 to prevent scope creep on the `1.0.0` declaration milestone.

| Feature | Reason |
|---------|--------|
| New billing primitives (subscriptions, invoices, meters, etc. surface additions) | v1.30 is a stability declaration, not a feature milestone — calling 1.0.0 with new APIs would compromise the stability commitment. |
| Second processor adapter (PROC-08) | Long-standing non-goal (v1.8 onward); reaffirmed at 1.0.0 in DOC-04. |
| App-owned finance exports (FIN-03) | Long-standing non-goal (v1.8 onward); reaffirmed at 1.0.0 in DOC-04. |
| Stripe Dashboard meter setup UX | Non-goal since v1.10 (PROJECT.md line 148); host/Stripe-documented territory unless a future requirement explicitly pulls UI scope in. |
| Post-1.0 deprecation flagging or removal | Out of scope for the cut itself; first deprecations land in a later v1.x milestone after the 1.0.0 surface is published and live. |
| Major-version bump messaging beyond `RELEASING.md` post-1.0 cadence (REL-07) | No marketing / launch-day campaign in this milestone — it's a maintenance release, not a launch event. The Hex registry + CHANGELOG are the authoritative announcement. |
| Multi-database support / dual-license / commercial tier | Long-standing PROJECT.md non-goals; not affected by 1.0.0. |

## Traceability

Populated 2026-04-26 during roadmap creation (`/gsd-new-milestone` Step 10). Phase numbering continues from v1.29's last phase (90); v1.30 spans Phases 91–93.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-05 | Phase 92 | Pending |
| REL-06 | Phase 91 | Pending |
| REL-07 | Phase 91 | Pending |
| REL-08 | Phase 93 | Pending |
| PPX-09 | Phase 92 | Pending |
| PPX-10 | Phase 92 | Pending |
| PPX-11 | Phase 92 | Pending |
| PPX-12 | Phase 92 | Pending |
| HYG-02 | Phase 93 | Pending |
| DOC-03 | Phase 91 | Pending |
| DOC-04 | Phase 91 | Pending |
| INV-07 | Phase 93 | Pending |

**Coverage:**
- v1.30 requirements: 12 total
- Mapped to phases: 12 / Unmapped: 0 ✓
- Phase 91 (Pre-publish prep): REL-06, REL-07, DOC-03, DOC-04 (4)
- Phase 92 (Linked publish + contract sweep): REL-05, PPX-09, PPX-10, PPX-11, PPX-12 (5)
- Phase 93 (HYG mirror + INV + tag): HYG-02, INV-07, REL-08 (3)

---
*Requirements defined: 2026-04-26*
*Last updated: 2026-04-26 — traceability populated by `/gsd-new-milestone` Step 10 (roadmap creation)*
