# Phase 250: Remote Integration - Context

**Gathered:** 2026-10-25
**Status:** Ready for planning
**Source:** Maintainer decisions in the 2026-10-24/25 session plus the first remote CI measurement of PR #49.

<domain>
## Phase Boundary

Get PR #49 (`integration/v1.63-v1.66` → `main`, https://github.com/szTheory/accrue/pull/49) green on its exact head SHA. Every PR-required job must conclude `success`, not `skipped`. Then merge it with a merge commit, once the maintainer explicitly says yes. Release-please alignment and Hex publishing belong to Phase 251.
</domain>

<decisions>
## Implementation Decisions (locked)

### Already done (LAND-01)
- The maintainer approved the push on 2026-10-25. Before pushing, publication hygiene was re-run over the 91 commits since the first full-history scan (`b4a7eeac..23bee494`): secret, home-path and email patterns all 0 hits, each with a positive control; `verify_no_home_paths` passed `--self-test` and `--repo`; the sensitive-token census passed strictly. The original full-history scan of 850 commits was also clean.
- The branch was pushed as `integration/v1.63-v1.66` at `23bee4949045b7ac9361d954b24497bb749e771b`. No tags were pushed; milestone tags stay local.
- PR #49 is open. Its body was created from a scratch file. There is no committed PR-body file yet (SL-F needs one).

### First remote measurement: CI run 40204835226 (ci.yml) and 40204835309 (accrue_admin_browser.yml) at 23bee494
- **pass:** Admin Phase 200 guardrails, ratchet self-tests, group contracts (190), hardening guardrails (192), Phase 18 tax gate, Release manifest SSOT, iOS offline client.
- **fail:**
  - Docs and bash contracts. The D-32 CI script contract reports "vacuous or failing under node --test: scripts/ci/test_accrue_host_preview_custody.mjs (exit 1), scripts/ci/test_accrue_host_proof_paths.mjs ...". These pass locally, so this is a CI-environment difference; look at docker presence and `GITHUB_ACTIONS`.
  - All 4 release-gate cells. In each, the accrue_admin suite has 746 tests and **8 failures**, all in `test/accrue_admin/live/analytics/recovery_live_test.exs`. The 8 failures are the same under every seed, so this is deterministic in CI. The same file passes locally, 33/0, also with `TZ=UTC`. Orchestrator probe: injecting a 250ms delay into the async recovery query reproduces only 1 of the 8 (the "truthful recurring monthly metric definitions" test). So `render_async`'s default timeout explains part of it at most. The other 7 need root-causing; the CI log truncates the rendered HTML.
  - Annotation sweep (downstream of the release-gate failures).
  - Admin UI ratchet guardrails [parked] (continue-on-error/advisory; confirm it is not required).
  - Browser UAT (accrue_admin_browser.yml): not yet diagnosed. It likely includes the Linux pixel-diff baselines, because the admin CSS bundle changed in 249-01 and 249-09.
- **skipped (dependent on release-gate, so not yet measured):** Host integration, Playwright E2E shards, Host Docker smoke, Admin drift and docs, Mint visual baselines.

### Rules
- Fix every red at its source. Never weaken, skip or make a gate vacuous. Every contract change needs a positive or negative control. These are the same gate-integrity rules as 249-CONTEXT.md.
- Iterate on the same PR branch. For each fix: commit locally, re-run the relevant local check, then push to `integration/v1.63-v1.66`. **Pushes to this already-approved PR branch are authorized** as part of Phase 250. Never force-push. Never push to `main`. Never push tags.
- **Visual baselines:** look at the CI diff artifacts first. Re-mint through the `accrue_admin_browser.yml` `workflow_dispatch` "Mint visual baselines" job and commit the downloaded artifact ONLY for intentional changes (249-01 CSS guard fixes and 249-09 topbar reflow). Any unintended visual change is a regression to fix in source. Record a classification for every surface that changed.
- **SL-F / REL-04:** commit the PR body file and keep it byte-identical to the live body. Use `gh pr edit 49 --body-file <committed file>`. Point the REL-04 "Integration PR body contract" step at the new file if the contract requires it (it currently points at the v1.62 `232-INTEGRATION-PR.md`). Record the exact 40-hex head SHA in the body when claiming green.
- **current_phase handoff:** STATE `current_phase` must flip to 250 in the same step that mints Phase 250's own VERIFICATION and UAT. Otherwise SL-G and SL-E go red. Until then, keep `current_phase: 249` so the docs-contracts job stays green while fixes land.
- **Merge** (LAND-03) requires a separate explicit maintainer yes: a merge commit via `gh pr merge 49 --merge`, never squash or rebase. After the merge, the first push run on `main` must be fully green.
- **Main branch protection:** none exists (`gh api .../branches/main/protection` returns 404), so "required" means every job the PR runs, enforced by discipline.
- No Docker commands on the maintainer's machine. Docker lanes are proven only in CI.
- The shared local Postgres on 5432 is near its connection limit from the maintainer's running dev apps. Don't stop them; use a private scratch Postgres (for example port 5439) when running suites locally.
- Use the GitHub CLI (`gh run view --log-failed`, `gh run download`) to fetch logs and artifacts. Scratch output goes to `$GSD_SCRATCH`.

### Claude's Discretion
- How to decompose the plans and order the fixes. Expect several push → measure → fix iterations. The plans should be loops with a hard success condition: all jobs `success` at the head SHA.
</decisions>

<canonical_refs>
- `.planning/phases/249-local-gate-parity-planning-truth/249-CONTEXT.md`, `249-VERIFICATION.md`, `249-17-SUMMARY.md` (Phase 250 hand-off list), `249-PROBE-CLASSIFICATION.md`
- `.planning/milestones/v1.62-MILESTONE-AUDIT.md` (integration PR precedent: SHA-bound evidence, PR-body drift lessons)
- `.github/workflows/ci.yml`, `.github/workflows/accrue_admin_browser.yml`
- `scripts/ci/verify_pr_body_currency.mjs`, `scripts/ci/verify_pr_claims.mjs`, `scripts/ci/accrue_host_preview_custody.sh`
- Memory: admin visual regression gate re-mint flow (`workflow_dispatch` → download the `phase211-visual-baselines` artifact → commit)
</canonical_refs>

---
*Phase: 250-remote-integration · Context gathered: 2026-10-25*

### Resolved research decisions (orchestrator, 2026-10-25, under maintainer's "follow your plan" authority)
- **D1 LAND-02 scope:** "every job with a `pull_request` run path concludes `success`, excluding the parked `admin-ui-ratchet-guardrails [parked]` lane (continue-on-error by design)". Dispatch-only (`Mint visual baselines`) and push/schedule-only jobs (Stripe provider-proof trio, live-stripe) are excluded from the PR bar. LAND-03 post-merge: the first push run on `main` must meet the bar of the last green main push run (2026-09-18, run 35374333981). Compare job by job, and record any job that cannot run (e.g. a missing secret) honestly instead of claiming it.
- **D2 `accrue_events.inserted_at` session-timezone dependence:** a real correctness risk for adopters running non-UTC Postgres, but the fix needs a migration. DEFER to v1.68 as a HIGH-priority item, recorded in REQUIREMENTS Future + STATE Deferred. In this phase, only fix the test (clock-shift margin) and pin `accrue_admin` test PG `timezone: "UTC"` for CI parity, with the negative control from research.
- **D3 PR body:** add a committed `.planning/phases/250-remote-integration/250-INTEGRATION-PR.md` with the `<!-- pr: https://github.com/szTheory/accrue/pull/49 -->` marker, kept byte-identical via `gh pr edit 49 --body-file`. SL-F only; do not extend SL-A or REL-04.
- **D4 visual baselines:** classify every changed surface from the CI diff PNGs. A change traceable to an owner-feedback commit (3d7d949d..b4a7eeac, see `.planning/notes/2026-10-1*-admin-owner-feedback.md`), a v1.63–v1.66 phase commit, or the 249-01/249-09 CSS fixes = intentional → re-mint. Anything else = regression → fix in source. Record a per-surface classification ledger with the commit receipt and the diff PNG reference, so the maintainer can audit it.
