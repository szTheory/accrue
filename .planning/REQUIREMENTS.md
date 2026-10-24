# Requirements: Accrue

**Defined:** 2026-10-24
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one.

## v1.67 Requirements

Milestone v1.67 Integration & CI Green. Lands the never-CI-validated v1.63–v1.66 work on `origin/main` and makes 1.7.0 release-ready. No new product behavior.

### Local gate parity

- [ ] **GREEN-01**: Maintainer can run every planning-doc contract step of the `docs-contracts-shift-left` job locally and see it pass — completion evidence (REQUIREMENTS.md present), PR claims (`WINDOWS.md` measured claim), artifact fixed point (resolvable `current_phase`, digests match), v1.17 friction / roadmap hygiene anchors (ROADMAP Planning Doctrine restored verbatim from `origin/main`), executable UAT contract (245-02 summary), and committed window dispositions (no undisposed ship-window rows) — each fixed at its source, never by weakening the gate.
- [ ] **GREEN-02**: `accrue_admin` compiles with `--warnings-as-errors` (unused `subscription` binding at `subscription_live.ex:1286` removed) so the admin group-contract, hardening and Phase 200 jobs reach their real assertions.
- [ ] **GREEN-03**: Admin CSS and CI-script contracts pass: every breakpoint `@media` in `accrue_admin/assets/css/app.css` carries its `--ax-bp-*` annotation (DSY-01), and every `scripts/ci/*.mjs` module added since v1.62 carries the shared module-boundary guard (D-32) — without editing sha256-pinned archived evidence scripts in a way that falsifies their recorded receipts.
- [ ] **GREEN-04**: The Phase 190 automation contract and Phase 190/192 browser probes pass; each failing probe (3 tests × desktop/mobile) is classified with evidence as a real UI regression (fixed in source) or a contract made stale by intentional v1.63–v1.66 changes (contract updated with the rationale recorded).
- [ ] **GREEN-05**: The `accrue`, `accrue_admin` and `accrue_portal` test suites, the host-integration gate and the Playwright E2E lane pass locally on the integration head, with `copy_strings.json` and visual baselines regenerated only where intentional changes require it.

### Planning truth

- [ ] **TRUTH-01**: Planning state is current and honest: stale `.planning/HANDOFF.json` removed, STATE.md reflects v1.67, and resolved debug sessions are filed.
- [ ] **TRUTH-02**: The out-of-band 2026-10-11..19 owner-feedback commits (`3d7d949d..b4a7eeac`) are recorded in MILESTONES.md and STATE.md as work done outside GSD, citing `.planning/notes/2026-10-1*-admin-owner-feedback.md` as receipts, with no backdated plans or claimed phase verification; their regression coverage is exercised by the GREEN-05 suites.

### Remote integration

- [ ] **LAND-01**: After an explicit maintainer yes, the integration head is pushed to an accurately named branch (`integration/v1.63-v1.66`) with a pre-push publication-hygiene check (secrets, home paths, PII, large binaries) passing across the full pushed history; milestone tags stay local.
- [ ] **LAND-02**: One PR to `main` shows every `ci.yml` and `accrue_admin_browser.yml` job that is required for PRs concluding `success` — not `skipped` — on the exact 40-hex head SHA recorded in the PR body, with the committed PR-body file matching the live body.
- [ ] **LAND-03**: The PR is merged with a merge commit (no squash, no rebase), so pre-merge commit SHAs and conventional-commit history remain reachable from `main`, and the first post-merge push run on `main` is fully green.

### Release alignment

- [ ] **RLS-01**: The release-please 1.7.0 PR for `accrue`, `accrue_admin` and `accrue_portal` is aligned on its branch — README version pins, companion notes, and a curated adopter-readable CHANGELOG in place of raw phase-scoped `feat(2xx-yy)` lines — and is green on its exact head.
- [ ] **RLS-02**: Hex publication happens only after an explicit maintainer yes; if not approved in this milestone, the aligned release PR is left open and green with the decision recorded.

## Future Requirements

Deferred to a later milestone (tracked, not in this roadmap):

- Webhook list uses the shared multi-status filter; raw event type no longer duplicates its readable label.
- Recovery demo fixture history is representative for the newer retry cycle.
- LiveView JS/server lock alignment on 1.1.32 across packages and the host.
- ExMoney exchange-rate deprecation and Storybook dev-asset notice silenced at source.
- Sigra wrong-password datetime exception triaged (fix or upstream report).
- Dead phase-190 path alternation at `ci.yml:881` repaired so its gate fires.
- mailglass `~> 1.0` downstream cap documented for adopters (SEED-008 cheap half).
- Re-capture or formally retire drifted phase 245/248 evidence verifiers (not CI-wired).

## Out of Scope

| Item | Reason |
|------|--------|
| New billing, admin or portal behavior | Integration milestone; fixes land at the source of a red only |
| Squash or rebase merge | Destroys SHA-bound evidence, bisectability and per-feat changelog entries |
| Pushing milestone tags v1.63–v1.66 | Owner note 2026-10-11: keep GSD milestone tags local |
| History rewrite to drop screenshot PNGs / temp paths | Full-history scan found no exposure; size alone does not justify rewriting public history |
| Weakening or skipping a gate to go green | Vacuous-gate antipattern; skipped reads as satisfied |
| SEED-004 M2/M3, SEED-002, SEED-007, mailglass 2.x migration | No adopter trigger; stable-core posture |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GREEN-01 | — | Pending |
| GREEN-02 | — | Pending |
| GREEN-03 | — | Pending |
| GREEN-04 | — | Pending |
| GREEN-05 | — | Pending |
| TRUTH-01 | — | Pending |
| TRUTH-02 | — | Pending |
| LAND-01 | — | Pending |
| LAND-02 | — | Pending |
| LAND-03 | — | Pending |
| RLS-01 | — | Pending |
| RLS-02 | — | Pending |

**Coverage:**
- v1.67 requirements: 12 total
- Mapped to phases: 0
- Unmapped: 12 ⚠️

---
*Requirements defined: 2026-10-24*
*Last updated: 2026-10-24 after initial definition*
