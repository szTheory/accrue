# Requirements: Accrue

**Defined:** 2026-10-24
**Core Value:** A Phoenix developer can install Accrue + its companion admin UI, and launch a real SaaS with subscription billing on day one.

## v1.67 Requirements

Milestone v1.67 Integration & CI Green. Lands the never-CI-validated v1.63–v1.66 work on `origin/main` and makes 1.7.0 release-ready. No new product behavior.

### Local gate parity

- [x] **GREEN-01**: Maintainer can run every planning-doc contract step of the `docs-contracts-shift-left` job locally and see it pass — completion evidence (REQUIREMENTS.md present), PR claims (`WINDOWS.md` measured claim), artifact fixed point (resolvable `current_phase`, digests match), v1.17 friction / roadmap hygiene anchors (ROADMAP Planning Doctrine restored verbatim from `origin/main`), executable UAT contract (245-02 summary), and committed window dispositions (no undisposed ship-window rows) — each fixed at its source, never by weakening the gate.
- [x] **GREEN-02**: `accrue_admin` compiles with `--warnings-as-errors` (unused `subscription` binding at `subscription_live.ex:1286` removed) so the admin group-contract, hardening and Phase 200 jobs reach their real assertions.
- [x] **GREEN-03**: Admin CSS and CI-script contracts pass: every breakpoint `@media` in `accrue_admin/assets/css/app.css` carries its `--ax-bp-*` annotation (DSY-01), and every `scripts/ci/*.mjs` module added since v1.62 carries the shared module-boundary guard (D-32) — without editing sha256-pinned archived evidence scripts in a way that falsifies their recorded receipts.
- [x] **GREEN-04**: The Phase 190 automation contract and Phase 190/192 browser probes pass; each failing probe (3 tests × desktop/mobile) is classified with evidence as a real UI regression (fixed in source) or a contract made stale by intentional v1.63–v1.66 changes (contract updated with the rationale recorded).
- [x] **GREEN-05**: The `accrue`, `accrue_admin` and `accrue_portal` test suites and the host mix test phases pass locally on the integration head. The host dev-boot/browser and Playwright E2E lanes pass in remote CI on the integration head (Phase 250), because they require a preview-free environment (maintainer host preview-custody decision, 2026-10-25). `copy_strings.json` and visual baselines are regenerated only where intentional changes require it.

### Planning truth

- [x] **TRUTH-01**: Planning state is current and honest: stale `.planning/HANDOFF.json` removed, STATE.md reflects v1.67, and resolved debug sessions are filed.
- [x] **TRUTH-02**: The out-of-band 2026-10-11..19 owner-feedback commits (`3d7d949d..b4a7eeac`) are recorded in MILESTONES.md and STATE.md as work done outside GSD, citing `.planning/notes/2026-10-1*-admin-owner-feedback.md` as receipts, with no backdated plans or claimed phase verification; their regression coverage is exercised by the GREEN-05 suites.

### Remote integration

- [x] **LAND-01**: After an explicit maintainer yes, the integration head is pushed to an accurately named branch (`integration/v1.63-v1.66`) with a pre-push publication-hygiene check (secrets, home paths, PII, large binaries) passing across the full pushed history; milestone tags stay local.
- [x] **LAND-02**: One PR to `main` shows every `ci.yml` and `accrue_admin_browser.yml` job that has a `pull_request` run path concluding `success`, not `skipped`. That is checked on the exact 40-hex evidence head SHA recorded in the PR body, and the committed PR-body file matches the live body. Two kinds of job are outside the PR bar: the parked `Admin UI ratchet guardrails [parked]` lane, which is `continue-on-error` by design (WINDOWS.md waiver row 11), and dispatch-only or push/schedule-only jobs (`Mint visual baselines`, `Stripe provider-proof trigger classifier`, `Stripe provider-proof incident reconciliation`, `Stripe test-mode parity (mandatory periodic)`). A commit cannot contain its own SHA. So the PR head may differ from the recorded evidence head by exactly one commit that changes nothing but the committed PR-body file, and that head's runs must meet the same bar.
- [x] **LAND-03**: The PR is merged with a merge commit (no squash, no rebase), so pre-merge commit SHAs and conventional-commit history remain reachable from `main`, and the first post-merge push run on `main` is fully green. The first post-merge push run on `main` meets, job by job, the bar of the last green `main` push run (run 35374333981). Any job that cannot run there, for example one missing a secret, is recorded as such and not claimed.

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
- HIGH priority (v1.68): `accrue_events.inserted_at` is `timestamp without time zone` with `DEFAULT now()`, so it follows the Postgres session TimeZone. A non-UTC adopter database stores local time labelled as UTC, so UTC windows mis-select events. The fix needs a migration or app-side timestamps. Found by Phase 250 research and deferred per D2.

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
| GREEN-01 | Phase 249 | Complete |
| GREEN-02 | Phase 249 | Complete |
| GREEN-03 | Phase 249 | Complete |
| GREEN-04 | Phase 249 | Complete |
| GREEN-05 | Phase 249 | Complete |
| TRUTH-01 | Phase 249 | Complete |
| TRUTH-02 | Phase 249 | Complete |
| LAND-01 | Phase 250 | Complete |
| LAND-02 | Phase 250 | Complete |
| LAND-03 | Phase 250 | Complete |
| RLS-01 | Phase 251 | Pending |
| RLS-02 | Phase 251 | Pending |

**Coverage:**
- v1.67 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-10-24*
*Last updated: 2026-10-25 (Phase 250 close: LAND-02 and LAND-03 Complete after the PR #49 merge commit 3dd5f874 and its post-merge main run passed against run 35374333981; LAND-01 Complete at the pre-merge close ece41e51); previously Phase 249 close (GREEN-01..05 and TRUTH-01..02 Complete after 249-VERIFICATION passed)*
