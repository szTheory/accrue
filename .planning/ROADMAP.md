# Roadmap: Accrue

## Milestones

- ✅ **v1.0 Initial Release** — Phases 1-9 shipped on 2026-04-16. Public Hex packages: `accrue` 0.1.2 and `accrue_admin` 0.1.2. Full archive: [`milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md).
- 🚧 **v1.1 Stabilization + Adoption** — Phases 10-15. Prove Accrue in a realistic minimal Phoenix host app, wire that proof into CI, then use it to harden first-user DX, docs, adoption assets, quality, and expansion planning.

## Phases

<details>
<summary>✅ v1.0 Initial Release (Phases 1-9) — SHIPPED 2026-04-16</summary>

- [x] Phase 1: Foundations (6/6 plans) — completed 2026-04-11
- [x] Phase 2: Schemas + Webhook Plumbing (6/6 plans) — completed 2026-04-12
- [x] Phase 3: Core Subscription Lifecycle (8/8 plans) — completed 2026-04-14
- [x] Phase 4: Advanced Billing + Webhook Hardening (8/8 plans) — completed 2026-04-14
- [x] Phase 5: Connect (7/7 plans) — completed 2026-04-14
- [x] Phase 6: Email + PDF (7/7 plans) — completed 2026-04-15
- [x] Phase 7: Admin UI (accrue_admin) (12/12 plans) — completed 2026-04-15
- [x] Phase 8: Install + Polish + Testing (9/9 plans) — completed 2026-04-15
- [x] Phase 9: Release (6/6 plans) — completed 2026-04-16

</details>

### 🚧 v1.1 Stabilization + Adoption

- [ ] **Phase 10: Host App Dogfood Harness** — canonical minimal Phoenix app that installs and uses `accrue` + `accrue_admin` through public APIs.
- [ ] **Phase 11: CI User-Facing Integration Gate** — mandatory CI workflows for host-app setup, Fake-backed E2E, browser UAT artifacts, and warning/error annotation sweeps.
- [ ] **Phase 12: First-User DX Stabilization** — installer/docs/error polish driven by dogfood failures and first-hour user setup paths.
- [ ] **Phase 13: Adoption Assets** — maintained example/demo path, tutorial docs, README positioning, and repository issue templates.
- [ ] **Phase 14: Quality Hardening** — security, performance, compatibility, accessibility, responsive admin checks, and release-gate clarity.
- [ ] **Phase 15: Expansion Discovery** — evaluate tax, revenue exports, additional processors, and org/multi-tenant billing as future roadmap candidates.

## Phase Details

### Phase 10: Host App Dogfood Harness

**Goal:** A realistic minimal Phoenix host app proves that a new user can install and use `accrue` and `accrue_admin` through public APIs, without private shortcuts or hidden local state.
**Depends on:** v1.0 archive
**Requirements:** HOST-01, HOST-02, HOST-03, HOST-04, HOST-05, HOST-06, HOST-07, HOST-08
**Success Criteria** (what must be TRUE):
1. A clean checkout can build the host app from documented commands, run migrations, and boot without hidden machine-local state.
2. The host app uses the public installer and generated host-facing billing facade rather than hand-wiring private Accrue internals.
3. A Fake-backed user-facing flow creates or updates realistic billing state through checkout/subscription APIs.
4. The host app mounts a scoped webhook endpoint and processes signed Fake/Stripe-shaped webhook payloads through the normal ingest path.
5. `accrue_admin` is mounted behind a realistic auth/session boundary and can inspect state plus perform one audited admin action.
**Plans:** 1/7 plans executed
Plans:
- [x] 10-01-PLAN.md — Scaffold the Phoenix host app core and host-owned config foundation.
- [ ] 10-02-PLAN.md — Generate the host-owned auth/session scaffold for later signed-in flows.
- [ ] 10-03-PLAN.md — Add host test support and all Wave 0 proof files.
- [ ] 10-04-PLAN.md — Run the public installer, keep generated wiring intact, and prove the host billable facade boundary.
- [ ] 10-05-PLAN.md — Build the signed-in Fake-backed subscription flow through `AccrueHost.Billing`.
- [ ] 10-06-PLAN.md — Prove signed webhook ingest and idempotent normal-path dispatch at `/webhooks/stripe`.
- [ ] 10-07-PLAN.md — Protect `/billing`, prove audited replay, and document clean-checkout commands.
**UI hint:** yes (host app and admin browser flows)

### Phase 11: CI User-Facing Integration Gate

**Goal:** Pull requests and `main` pushes fail when the host-app user experience regresses, making realistic integration coverage part of the release gate instead of an optional local check.
**Depends on:** Phase 10
**Requirements:** CI-01, CI-02, CI-03, CI-04, CI-05, CI-06
**Success Criteria** (what must be TRUE):
1. GitHub Actions runs host-app compile/test/setup and Fake-backed E2E flows on pull requests and pushes to `main`.
2. CI fails on compile warnings, test failures, browser failures, docs-link drift, generated artifact drift, or warning/error annotations.
3. Package-local tests and host-app user-facing flows run in a clear order so failures point at the right layer.
4. Browser failures publish enough artifacts to debug without rerunning locally where practical.
5. Live Stripe remains opt-in/advisory while Fake-backed user-facing flows are mandatory.
**Plans:** TBD
**UI hint:** yes (browser UAT artifacts)

### Phase 12: First-User DX Stabilization

**Goal:** The first-hour experience for a Phoenix developer is tightened using failures and friction discovered by the host app: installer behavior, setup errors, docs, diagnostics, and public API clarity.
**Depends on:** Phase 10
**Requirements:** DX-01, DX-02, DX-03, DX-04, DX-05, DX-06, DX-07
**Success Criteria** (what must be TRUE):
1. Re-running the installer against the host app is idempotent and does not clobber user-owned files.
2. Common setup failures for config, migrations, Oban, webhook secrets, auth, and admin mounts produce actionable messages.
3. Quickstart and troubleshooting docs follow the host-app path without skipped setup steps.
4. The host app validates both path-dependency development and Hex-style dependency modes.
5. Package docs retain correct version snippets, source links, and internal HexDocs guide links.
**Plans:** TBD
**UI hint:** no

### Phase 13: Adoption Assets

**Goal:** New users can evaluate Accrue quickly through a maintained example/demo path, tutorial docs, clearer README positioning, and issue templates that capture useful integration feedback.
**Depends on:** Phase 10 and Phase 12
**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03, ADOPT-04, ADOPT-05, ADOPT-06
**Success Criteria** (what must be TRUE):
1. A new user can run the maintained example/demo path locally and see a complete billing/admin loop.
2. Tutorial docs walk from install through first subscription and admin inspection using the host app.
3. Repository issue templates route bugs, integration problems, docs gaps, and feature requests into useful reports.
4. README guidance clearly separates quickstart, example app, production hardening, and live Stripe guidance.
5. Adoption copy stays consistent with Accrue’s established brand voice and avoids unproven claims.
**Plans:** TBD
**UI hint:** yes (example/demo path and docs screenshots if used)

### Phase 14: Quality Hardening

**Goal:** The user-facing paths exercised by v1.1 are hardened for security, performance, compatibility, accessibility, responsive UI, and release-gate clarity.
**Depends on:** Phase 10 and Phase 11
**Requirements:** QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05, QUAL-06
**Success Criteria** (what must be TRUE):
1. Webhook, auth, admin, and host-app boundaries receive a focused security review with findings fixed or explicitly tracked.
2. Webhook ingest and admin pages have realistic performance checks or budgets.
3. Supported Elixir/OTP/Phoenix/LiveView compatibility is exercised or clearly bounded.
4. Admin flows used by the host app pass responsive and accessibility-oriented browser checks.
5. Logs and error messages avoid leaking Stripe secrets, webhook secrets, tokens, or PII.
**Plans:** TBD
**UI hint:** yes (admin browser accessibility/responsive checks)

### Phase 15: Expansion Discovery

**Goal:** Future product expansion candidates are evaluated and captured as roadmap-ready decisions without pulling implementation into the stabilization milestone.
**Depends on:** Phase 10 and Phase 13
**Requirements:** DISC-01, DISC-02, DISC-03, DISC-04, DISC-05
**Success Criteria** (what must be TRUE):
1. Tax support options are compared with a recommendation for whether and how to pursue them later.
2. Revenue recognition/export options are compared with a recommendation for later milestones.
3. Additional processor candidates are evaluated against the current Stripe-first abstraction without weakening it.
4. Organization and multi-tenant billing flows are evaluated against Sigra and host-owned schema constraints.
5. Accepted ideas are captured as future roadmap candidates, seeds, or backlog entries with clear trigger conditions.
**Plans:** TBD
**UI hint:** no

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundations | v1.0 | 6/6 | Complete | 2026-04-11 |
| 2. Schemas + Webhook Plumbing | v1.0 | 6/6 | Complete | 2026-04-12 |
| 3. Core Subscription Lifecycle | v1.0 | 8/8 | Complete | 2026-04-14 |
| 4. Advanced Billing + Webhook Hardening | v1.0 | 8/8 | Complete | 2026-04-14 |
| 5. Connect | v1.0 | 7/7 | Complete | 2026-04-14 |
| 6. Email + PDF | v1.0 | 7/7 | Complete | 2026-04-15 |
| 7. Admin UI (accrue_admin) | v1.0 | 12/12 | Complete | 2026-04-15 |
| 8. Install + Polish + Testing | v1.0 | 9/9 | Complete | 2026-04-15 |
| 9. Release | v1.0 | 6/6 | Complete | 2026-04-16 |
| 10. Host App Dogfood Harness | v1.1 | 1/7 | In Progress|  |
| 11. CI User-Facing Integration Gate | v1.1 | 0/TBD | Planned | - |
| 12. First-User DX Stabilization | v1.1 | 0/TBD | Planned | - |
| 13. Adoption Assets | v1.1 | 0/TBD | Planned | - |
| 14. Quality Hardening | v1.1 | 0/TBD | Planned | - |
| 15. Expansion Discovery | v1.1 | 0/TBD | Planned | - |

## Parallelization Notes

Phase 10 is the foundation for v1.1 and should run first. Phase 11 depends on Phase 10. Phase 12 can begin once the first host-app path exists. Phase 13 depends on the stabilized host-app story from Phases 10 and 12. Phase 14 can run in parallel with adoption work after CI exists. Phase 15 can run late or in parallel once the host-app experience clarifies real expansion pressure.

---

For full v1.0 phase details, decisions, and requirements traceability, see `.planning/milestones/`.
