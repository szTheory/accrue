---
schema_version: 1
open_count: 11
waived_count: 6
fixed_count: 17
total_count: 34
last_updated: 2026-10-10T18:19:10.468Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 214.2 | unrun-verify | examples/accrue_host/e2e/verify01-admin-mobile.spec.js |  | Host mobile entitlement contract is skipped because the checked-in Playwright config has no chromium-mobile project. | fixed |  | 2026-07-31T19:21:33.589Z | 2026-09-16T15:00:10.297Z |
| 2 | 215 | deviation | examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift |  | Corrected stale capability case name in the tracer test. | fixed |  | 2026-08-01T01:55:48.046Z | 2026-09-16T15:00:10.384Z |
| 3 | 215 | deviation | examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift |  | Reducer now requires every declared evidence lane before reporting proven. | waived | Superseded by Phase 223-04's package-facade redesign; equivalent safety property verified enforced by scripts/ci/verify_ios_offline_client.sh at the candidate SHA. | 2026-08-01T01:55:48.106Z | 2026-09-16T15:00:10.468Z |
| 4 | 217 | unrun-verify | accrue/test/accrue/docs/package_docs_verifier_test.exs |  | mix test.all could not start because unrelated shared dirty file is not formatted | fixed |  | 2026-08-03T01:52:16.732Z | 2026-09-16T15:00:10.553Z |
| 5 | 220 | unrun-verify | examples/accrue_host/test/accrue_host/billing_facade_test.exs | 160 | Full mix verify could not complete because the pre-existing fake subscription uniqueness test failed. | fixed |  | 2026-08-04T15:43:48.620Z | 2026-09-16T15:00:10.639Z |
| 6 | 220 | deviation | accrue/lib/accrue/entitlements/snapshot.ex |  | Forwarded snapshot :now option to repository folding for frozen expiry-boundary proof. | fixed |  | 2026-08-05T02:02:05.577Z | 2026-09-16T15:00:10.722Z |
| 7 | 221 | unrun-verify | examples/accrue_host |  | mix verify blocked by unrelated tracked formatting violations before its test suite | fixed |  | 2026-08-05T17:28:54.045Z | 2026-09-16T15:00:10.807Z |
| 8 | 221 | unrun-verify | examples/accrue_host/lib/accrue_host_web/components/layouts.ex |  | Full mix format --check-formatted is blocked by unrelated tracked formatting violations in layouts and existing migrations. | fixed |  | 2026-08-05T17:40:05.349Z | 2026-09-16T15:00:10.896Z |
| 9 | 225 | deviation | accrue_admin/mix.lock | 41 | Locked already-declared jose dependency so the Admin Playwright web server starts in a clean checkout. | fixed |  | 2026-08-09T03:32:55.284Z | 2026-09-16T15:00:10.982Z |
| 10 | 227 | unrun-verify | .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson |  | Live three-success critical-path comparison could not run: final bounded cohort had no qualifying successful workflow_dispatch observations. | waived | GATE-02 recorded one real workflow_dispatch observation (failure), not a qualifying success; the three-success bounded comparison still cannot run. No release-blocking effect. | 2026-08-13T03:58:20.522Z | 2026-09-16T15:00:11.069Z |
| 11 | 232 | unmet-truth | accrue_admin/e2e/ratchet/ledger.baseline.json |  | Admin UI ratchet guardrails lane is failing on the merits (not un-run, not advisory by design): ledger.baseline.json is deliberately frozen:false with open findings deferred to v1.57 M3; the deterministic machinery that proves the lane (self-tests, CI contract) is split into the blocking admin-ui-ratchet-selftests job and stays green. | waived | Owner: Accrue maintainer (szTheory). Rationale: the v1.56 Admin UI Ratchet milestone is PARKED (superseded by v1.57 on 2026-07-19); the lane's machinery is proven green in the blocking admin-ui-ratchet-selftests job, and only the two steps whose subject is the deliberately-unfrozen ledger stay parked, non-blocking, and excluded from the release-facing annotation sweep by disposition. Release impact: none -- this lane does not gate the v1.62 release candidate; un-parking (a job rename plus a ledger re-freeze) is scheduled for v1.57 M3, and the Parked-lane expiry trigger (D-26) fails blockingly the moment the ledger freezes while this row still exists, so a stale waiver cannot silently persist past its own justification. | 2026-09-16T21:08:09.584Z | 2026-09-16T21:08:16.470Z |
| 12 | 232 | unmet-truth | accrue/test/accrue/docs/package_docs_verifier_test.exs |  | docs-contracts-shift-left is failing on the merits at the frozen re-cut candidate SHA (c1397fe9127a9b4b2b1d3a0758d57879b14f4604): verify_executable_uat_contract.mjs --all-since 229 caught two human_judgment:true Executable Acceptance Policy violations in 232-08/232-09-SUMMARY.md (now fixed on the milestone line, commit 11d42183), plus a structural, self-resolving gap (phase 232 cannot carry its own closing 232-VERIFICATION.md/232-UAT.md until it completes). | waived | Owner: Accrue maintainer (szTheory). Rationale: both root causes (two human_judgment:true Executable Acceptance Policy violations, plus the phase-232-self-referential missing-VERIFICATION-artifact gap) are real and root-caused, but the frozen candidate SHA integration/v1.62-candidate-recut@c1397fe9 is immutable under this plan's own hard limits (no force-push, no second merge point, no moving that ref); the SUMMARY.md fix is already committed on the milestone line (11d42183) and will land in the next re-cut. Release impact: the human_judgment findings are policy-text corrections with zero behavioral risk; the missing-artifact gap self-resolves the moment phase 232 reaches its own closing plan and mints 232-VERIFICATION.md/232-UAT.md. Neither blocks shipping v1.62 once re-cut. | 2026-09-17T14:50:26.979Z | 2026-09-17T14:50:38.090Z |
| 13 | 232 | unmet-truth | accrue/test/accrue/docs/package_docs_verifier_test.exs |  | release-gate (all required matrix cells: Floor, Primary, Primary+OpenTelemetry) is failing on the merits at the frozen re-cut candidate SHA: package_docs_verifier_test.exs's seed_tmp_dir! fixture never copied the new scripts/ci/main_module.mjs dependency that scripts/ci/verify_foundation_contrast.mjs (introduced by this phase's D-29 shared module-boundary guard) now imports, so every spawned foundation-contrast subprocess crashed with ERR_MODULE_NOT_FOUND. Fixed and verified on the milestone line (commit 11d42183, mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0 now 46/46). | waived | Owner: Accrue maintainer (szTheory). Rationale: root cause is a stale test fixture (missing scripts/ci/main_module.mjs in seed_tmp_dir!) introduced by this phase's own D-29 shared module-boundary guard; fixed and verified on the milestone line (11d42183, mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0 now 46/46 across the whole file). The frozen candidate SHA is immutable under this plan's hard limits, so the fix is not yet incorporated into it. Release impact: none to shipped behavior -- the failure is confined to a CI test-fixture gap in the verifier's own scratch-copy machinery, not a regression in any package's runtime code; the fix will land in the next re-cut. | 2026-09-17T14:50:27.063Z | 2026-09-17T14:50:38.182Z |
| 14 | 232 | unmet-truth | .github/workflows/ci.yml |  | annotation-sweep is failing at the frozen re-cut candidate SHA (run 35232417814) purely as a downstream consequence of the docs-contracts-shift-left and release-gate regressions above -- it sweeps release-facing annotations from those same jobs and has no independent local-equivalent form (its only proof is a real GitHub Actions dispatch, per 231-GATE-01-EVIDENCE.md's established precedent for this exact lane). | waived | Owner: Accrue maintainer (szTheory). Rationale: purely a downstream consequence of ship-window rows 12 and 13 (annotation-sweep sweeps the same jobs that failed for those reasons); no independent defect. Release impact: none beyond rows 12/13 -- resolves automatically once those land in a future re-cut and this lane is re-dispatched. | 2026-09-17T14:50:27.147Z | 2026-09-17T14:50:38.272Z |
| 15 | 234 | deviation | accrue_admin/test/accrue_admin/live/dashboard_live_test.exs |  | Dashboard scope-control tests were added after the initial implementation instead of preceding it in a RED-first cycle. | open |  | 2026-10-08T00:50:59.696Z |  |
| 16 | 234 | deviation | .planning/phases/234-admin-customers-subscriptions/234-03-SUMMARY.md |  | TDD-marked task tests were added after implementation; workflow TDD mode was disabled and no RED commit was produced. | open |  | 2026-10-08T01:20:22.343Z |  |
| 17 | 234 | deviation | accrue_admin/test/accrue_admin/live/subscription_live_test.exs |  | Task 2 delayed review assertions were committed after the overlapping fresh-dispatch implementation, so Task 2 has no separate RED commit. | open |  | 2026-10-08T01:31:43.711Z |  |
| 18 | 234 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress 234 returned missing_phase_details, so the aggregate Phase 234 roadmap entry could not be updated. | open |  | 2026-10-08T01:32:40.174Z |  |
| 19 | 235 | deviation | examples/accrue_host/e2e/phase233-braintree-checkout.spec.js |  | Mock SDK proves the nonce-bearing server denial; live Braintree provider acceptance was not verified because the configured gateway returned HTTP 500. | open |  | 2026-10-08T04:49:19.603Z |  |
| 20 | 235 | deviation |  |  | Added test-only Portal origin and organization shared-billing route after deterministic browser verification exposed the missing runtime context. | open |  | 2026-10-08T12:01:21.609Z |  |
| 21 | 236 | deviation | .planning/ROADMAP.md |  | The roadmap.update-plan-progress SDK writer could not target the active milestone table, so the Phase 236 6/6 In Progress row was reconciled directly. | fixed |  | 2026-10-08T19:16:35.467Z | 2026-10-08T19:16:48.715Z |
| 22 | 238 | deviation | accrue_admin/lib/accrue_admin/live/webhook_live.ex |  | Axe heading-order violation in the webhook replay detail was fixed by correcting the section heading level. | fixed |  | 2026-10-09T04:19:27.287Z | 2026-10-09T04:19:38.013Z |
| 23 | 238 | deviation | accrue_admin/lib/accrue_admin/components/overlay.ex |  | Axe found an invalid article element with dialog role on the step-up modal; the modal panel now uses a div. | fixed |  | 2026-10-09T04:19:34.737Z | 2026-10-09T04:19:39.526Z |
| 24 | 238 | deviation | accrue_admin/test/accrue_admin/components/data_table_test.exs |  | The required warnings-as-errors Admin command was blocked by an unused test binding and unused private helper; both warnings were removed and the suite passed. | fixed |  | 2026-10-09T04:19:36.443Z | 2026-10-09T04:19:40.710Z |
| 25 | 239 | deviation | .planning/phases/239-integrated-quality-handoff/239-COVERAGE.md |  | Phase 239 route ledger duplicate stylesheet row was corrected and deterministic ordering is now enforced by ExUnit. | fixed |  | 2026-10-09T06:55:22.555Z | 2026-10-09T06:55:27.423Z |
| 26 | 239 | deviation | .planning/ROADMAP.md |  | The roadmap progress SDK missed its existing Phase 239 checklist and row; the current plan checkbox and 1/4 In Progress row were reconciled directly. | fixed |  | 2026-10-09T06:56:00.230Z | 2026-10-09T06:56:00.293Z |
| 27 | 240 | unrun-verify | .github/workflows/accrue_admin_browser.yml |  | Linux Phase 211 visual comparison was not run on macOS; the baseline set is Linux-specific. | open |  | 2026-10-09T19:50:49.478Z |  |
| 28 | 241 | deviation | accrue_admin/lib/accrue_admin/live/charge_live.ex | 80 | Renamed the validated return destination value and corrected two related-resource arguments after a focused compile error. | open |  | 2026-10-10T01:36:59.322Z |  |
| 29 | 241 | deviation | accrue_admin/lib/accrue_admin/live/subscription_live.ex |  | Confirmation controls expose disabled/loading state while step-up or dispatch is pending. | open |  | 2026-10-10T01:52:12.988Z |  |
| 30 | 241 | deviation | examples/accrue_host/e2e/generated/copy_strings.json |  | Generated browser copy strings are regenerated to match the updated subscription action labels. | open |  | 2026-10-10T01:52:13.282Z |  |
| 31 | 241 | unrun-verify | .planning/phases/241-billing-operator-journeys/241-07-PLAN.md |  | A separate 200% text-spacing and supported 400% zoom simulation was not run in Plan 241-07; direct narrow-width and long-text evidence ran. | fixed |  | 2026-10-10T03:10:50.370Z | 2026-10-10T03:54:19.174Z |
| 32 | 241 | unrun-verify | accrue_admin/e2e/admin-page-flow-phase191.spec.js |  | Per-variant browser review interactions were not established; the complete Admin suite covers subscription and payment-method review variants at the route owners. | fixed |  | 2026-10-10T03:27:48.492Z | 2026-10-10T06:34:44.612Z |
| 33 | 242 | deviation | accrue_admin/lib/accrue_admin/live/connect_account_live.ex |  | Optimistic-lock races after fee-review reread return stale-review feedback instead of escaping as an error. | fixed |  | 2026-10-10T13:22:18.081Z | 2026-10-10T13:22:22.341Z |
| 34 | 243 | unrun-verify | .github/workflows/accrue_admin_browser.yml |  | Ubuntu mint and normal selected visual comparison were unavailable because the committed phase source ref does not exist on origin. | open |  | 2026-10-10T18:19:10.468Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "214.2",
    "file": "examples/accrue_host/e2e/verify01-admin-mobile.spec.js",
    "line": null,
    "description": "Host mobile entitlement contract is skipped because the checked-in Playwright config has no chromium-mobile project.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-07-31T19:21:33.589Z",
    "resolved_at": "2026-09-16T15:00:10.297Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "215",
    "file": "examples/crosswake_tracer/Tests/AccrueOfflineClientTests/CapabilityReportTests.swift",
    "line": null,
    "description": "Corrected stale capability case name in the tracer test.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-01T01:55:48.046Z",
    "resolved_at": "2026-09-16T15:00:10.384Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "215",
    "file": "examples/crosswake_tracer/Sources/AccrueOfflineClient/AccrueOfflineClient.swift",
    "line": null,
    "description": "Reducer now requires every declared evidence lane before reporting proven.",
    "status": "waived",
    "reason": "Superseded by Phase 223-04's package-facade redesign; equivalent safety property verified enforced by scripts/ci/verify_ios_offline_client.sh at the candidate SHA.",
    "recorded_at": "2026-08-01T01:55:48.106Z",
    "resolved_at": "2026-09-16T15:00:10.468Z"
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "217",
    "file": "accrue/test/accrue/docs/package_docs_verifier_test.exs",
    "line": null,
    "description": "mix test.all could not start because unrelated shared dirty file is not formatted",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-03T01:52:16.732Z",
    "resolved_at": "2026-09-16T15:00:10.553Z"
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "220",
    "file": "examples/accrue_host/test/accrue_host/billing_facade_test.exs",
    "line": 160,
    "description": "Full mix verify could not complete because the pre-existing fake subscription uniqueness test failed.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-04T15:43:48.620Z",
    "resolved_at": "2026-09-16T15:00:10.639Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "220",
    "file": "accrue/lib/accrue/entitlements/snapshot.ex",
    "line": null,
    "description": "Forwarded snapshot :now option to repository folding for frozen expiry-boundary proof.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T02:02:05.577Z",
    "resolved_at": "2026-09-16T15:00:10.722Z"
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "221",
    "file": "examples/accrue_host",
    "line": null,
    "description": "mix verify blocked by unrelated tracked formatting violations before its test suite",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T17:28:54.045Z",
    "resolved_at": "2026-09-16T15:00:10.807Z"
  },
  {
    "id": 8,
    "kind": "unrun-verify",
    "phase": "221",
    "file": "examples/accrue_host/lib/accrue_host_web/components/layouts.ex",
    "line": null,
    "description": "Full mix format --check-formatted is blocked by unrelated tracked formatting violations in layouts and existing migrations.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T17:40:05.349Z",
    "resolved_at": "2026-09-16T15:00:10.896Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "225",
    "file": "accrue_admin/mix.lock",
    "line": 41,
    "description": "Locked already-declared jose dependency so the Admin Playwright web server starts in a clean checkout.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-09T03:32:55.284Z",
    "resolved_at": "2026-09-16T15:00:10.982Z"
  },
  {
    "id": 10,
    "kind": "unrun-verify",
    "phase": "227",
    "file": ".planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson",
    "line": null,
    "description": "Live three-success critical-path comparison could not run: final bounded cohort had no qualifying successful workflow_dispatch observations.",
    "status": "waived",
    "reason": "GATE-02 recorded one real workflow_dispatch observation (failure), not a qualifying success; the three-success bounded comparison still cannot run. No release-blocking effect.",
    "recorded_at": "2026-08-13T03:58:20.522Z",
    "resolved_at": "2026-09-16T15:00:11.069Z"
  },
  {
    "id": 11,
    "kind": "unmet-truth",
    "phase": "232",
    "file": "accrue_admin/e2e/ratchet/ledger.baseline.json",
    "line": null,
    "description": "Admin UI ratchet guardrails lane is failing on the merits (not un-run, not advisory by design): ledger.baseline.json is deliberately frozen:false with open findings deferred to v1.57 M3; the deterministic machinery that proves the lane (self-tests, CI contract) is split into the blocking admin-ui-ratchet-selftests job and stays green.",
    "status": "waived",
    "reason": "Owner: Accrue maintainer (szTheory). Rationale: the v1.56 Admin UI Ratchet milestone is PARKED (superseded by v1.57 on 2026-07-19); the lane's machinery is proven green in the blocking admin-ui-ratchet-selftests job, and only the two steps whose subject is the deliberately-unfrozen ledger stay parked, non-blocking, and excluded from the release-facing annotation sweep by disposition. Release impact: none -- this lane does not gate the v1.62 release candidate; un-parking (a job rename plus a ledger re-freeze) is scheduled for v1.57 M3, and the Parked-lane expiry trigger (D-26) fails blockingly the moment the ledger freezes while this row still exists, so a stale waiver cannot silently persist past its own justification.",
    "recorded_at": "2026-09-16T21:08:09.584Z",
    "resolved_at": "2026-09-16T21:08:16.470Z",
    "milestone": "v1.62"
  },
  {
    "id": 12,
    "kind": "unmet-truth",
    "phase": "232",
    "file": "accrue/test/accrue/docs/package_docs_verifier_test.exs",
    "line": null,
    "description": "docs-contracts-shift-left is failing on the merits at the frozen re-cut candidate SHA (c1397fe9127a9b4b2b1d3a0758d57879b14f4604): verify_executable_uat_contract.mjs --all-since 229 caught two human_judgment:true Executable Acceptance Policy violations in 232-08/232-09-SUMMARY.md (now fixed on the milestone line, commit 11d42183), plus a structural, self-resolving gap (phase 232 cannot carry its own closing 232-VERIFICATION.md/232-UAT.md until it completes).",
    "status": "waived",
    "reason": "Owner: Accrue maintainer (szTheory). Rationale: both root causes (two human_judgment:true Executable Acceptance Policy violations, plus the phase-232-self-referential missing-VERIFICATION-artifact gap) are real and root-caused, but the frozen candidate SHA integration/v1.62-candidate-recut@c1397fe9 is immutable under this plan's own hard limits (no force-push, no second merge point, no moving that ref); the SUMMARY.md fix is already committed on the milestone line (11d42183) and will land in the next re-cut. Release impact: the human_judgment findings are policy-text corrections with zero behavioral risk; the missing-artifact gap self-resolves the moment phase 232 reaches its own closing plan and mints 232-VERIFICATION.md/232-UAT.md. Neither blocks shipping v1.62 once re-cut.",
    "recorded_at": "2026-09-17T14:50:26.979Z",
    "resolved_at": "2026-09-17T14:50:38.090Z",
    "milestone": "v1.62"
  },
  {
    "id": 13,
    "kind": "unmet-truth",
    "phase": "232",
    "file": "accrue/test/accrue/docs/package_docs_verifier_test.exs",
    "line": null,
    "description": "release-gate (all required matrix cells: Floor, Primary, Primary+OpenTelemetry) is failing on the merits at the frozen re-cut candidate SHA: package_docs_verifier_test.exs's seed_tmp_dir! fixture never copied the new scripts/ci/main_module.mjs dependency that scripts/ci/verify_foundation_contrast.mjs (introduced by this phase's D-29 shared module-boundary guard) now imports, so every spawned foundation-contrast subprocess crashed with ERR_MODULE_NOT_FOUND. Fixed and verified on the milestone line (commit 11d42183, mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0 now 46/46).",
    "status": "waived",
    "reason": "Owner: Accrue maintainer (szTheory). Rationale: root cause is a stale test fixture (missing scripts/ci/main_module.mjs in seed_tmp_dir!) introduced by this phase's own D-29 shared module-boundary guard; fixed and verified on the milestone line (11d42183, mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0 now 46/46 across the whole file). The frozen candidate SHA is immutable under this plan's hard limits, so the fix is not yet incorporated into it. Release impact: none to shipped behavior -- the failure is confined to a CI test-fixture gap in the verifier's own scratch-copy machinery, not a regression in any package's runtime code; the fix will land in the next re-cut.",
    "recorded_at": "2026-09-17T14:50:27.063Z",
    "resolved_at": "2026-09-17T14:50:38.182Z",
    "milestone": "v1.62"
  },
  {
    "id": 14,
    "kind": "unmet-truth",
    "phase": "232",
    "file": ".github/workflows/ci.yml",
    "line": null,
    "description": "annotation-sweep is failing at the frozen re-cut candidate SHA (run 35232417814) purely as a downstream consequence of the docs-contracts-shift-left and release-gate regressions above -- it sweeps release-facing annotations from those same jobs and has no independent local-equivalent form (its only proof is a real GitHub Actions dispatch, per 231-GATE-01-EVIDENCE.md's established precedent for this exact lane).",
    "status": "waived",
    "reason": "Owner: Accrue maintainer (szTheory). Rationale: purely a downstream consequence of ship-window rows 12 and 13 (annotation-sweep sweeps the same jobs that failed for those reasons); no independent defect. Release impact: none beyond rows 12/13 -- resolves automatically once those land in a future re-cut and this lane is re-dispatched.",
    "recorded_at": "2026-09-17T14:50:27.147Z",
    "resolved_at": "2026-09-17T14:50:38.272Z",
    "milestone": "v1.62"
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "234",
    "file": "accrue_admin/test/accrue_admin/live/dashboard_live_test.exs",
    "line": null,
    "description": "Dashboard scope-control tests were added after the initial implementation instead of preceding it in a RED-first cycle.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T00:50:59.696Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "234",
    "file": ".planning/phases/234-admin-customers-subscriptions/234-03-SUMMARY.md",
    "line": null,
    "description": "TDD-marked task tests were added after implementation; workflow TDD mode was disabled and no RED commit was produced.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T01:20:22.343Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "234",
    "file": "accrue_admin/test/accrue_admin/live/subscription_live_test.exs",
    "line": null,
    "description": "Task 2 delayed review assertions were committed after the overlapping fresh-dispatch implementation, so Task 2 has no separate RED commit.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T01:31:43.711Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "234",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress 234 returned missing_phase_details, so the aggregate Phase 234 roadmap entry could not be updated.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T01:32:40.174Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "235",
    "file": "examples/accrue_host/e2e/phase233-braintree-checkout.spec.js",
    "line": null,
    "description": "Mock SDK proves the nonce-bearing server denial; live Braintree provider acceptance was not verified because the configured gateway returned HTTP 500.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T04:49:19.603Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "235",
    "file": "",
    "line": null,
    "description": "Added test-only Portal origin and organization shared-billing route after deterministic browser verification exposed the missing runtime context.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-08T12:01:21.609Z",
    "resolved_at": null,
    "milestone": "v1.63"
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "236",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "The roadmap.update-plan-progress SDK writer could not target the active milestone table, so the Phase 236 6/6 In Progress row was reconciled directly.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-08T19:16:35.467Z",
    "resolved_at": "2026-10-08T19:16:48.715Z",
    "milestone": "v1.63"
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "238",
    "file": "accrue_admin/lib/accrue_admin/live/webhook_live.ex",
    "line": null,
    "description": "Axe heading-order violation in the webhook replay detail was fixed by correcting the section heading level.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-09T04:19:27.287Z",
    "resolved_at": "2026-10-09T04:19:38.013Z",
    "milestone": "v1.63"
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "238",
    "file": "accrue_admin/lib/accrue_admin/components/overlay.ex",
    "line": null,
    "description": "Axe found an invalid article element with dialog role on the step-up modal; the modal panel now uses a div.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-09T04:19:34.737Z",
    "resolved_at": "2026-10-09T04:19:39.526Z",
    "milestone": "v1.63"
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "238",
    "file": "accrue_admin/test/accrue_admin/components/data_table_test.exs",
    "line": null,
    "description": "The required warnings-as-errors Admin command was blocked by an unused test binding and unused private helper; both warnings were removed and the suite passed.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-09T04:19:36.443Z",
    "resolved_at": "2026-10-09T04:19:40.710Z",
    "milestone": "v1.63"
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "239",
    "file": ".planning/phases/239-integrated-quality-handoff/239-COVERAGE.md",
    "line": null,
    "description": "Phase 239 route ledger duplicate stylesheet row was corrected and deterministic ordering is now enforced by ExUnit.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-09T06:55:22.555Z",
    "resolved_at": "2026-10-09T06:55:27.423Z",
    "milestone": "v1.63"
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "239",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "The roadmap progress SDK missed its existing Phase 239 checklist and row; the current plan checkbox and 1/4 In Progress row were reconciled directly.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-09T06:56:00.230Z",
    "resolved_at": "2026-10-09T06:56:00.293Z",
    "milestone": "v1.63"
  },
  {
    "id": 27,
    "kind": "unrun-verify",
    "phase": "240",
    "file": ".github/workflows/accrue_admin_browser.yml",
    "line": null,
    "description": "Linux Phase 211 visual comparison was not run on macOS; the baseline set is Linux-specific.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-09T19:50:49.478Z",
    "resolved_at": null,
    "milestone": "v1.64"
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "241",
    "file": "accrue_admin/lib/accrue_admin/live/charge_live.ex",
    "line": 80,
    "description": "Renamed the validated return destination value and corrected two related-resource arguments after a focused compile error.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T01:36:59.322Z",
    "resolved_at": null,
    "milestone": "v1.64"
  },
  {
    "id": 29,
    "kind": "deviation",
    "phase": "241",
    "file": "accrue_admin/lib/accrue_admin/live/subscription_live.ex",
    "line": null,
    "description": "Confirmation controls expose disabled/loading state while step-up or dispatch is pending.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T01:52:12.988Z",
    "resolved_at": null,
    "milestone": "v1.64"
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "241",
    "file": "examples/accrue_host/e2e/generated/copy_strings.json",
    "line": null,
    "description": "Generated browser copy strings are regenerated to match the updated subscription action labels.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T01:52:13.282Z",
    "resolved_at": null,
    "milestone": "v1.64"
  },
  {
    "id": 31,
    "kind": "unrun-verify",
    "phase": "241",
    "file": ".planning/phases/241-billing-operator-journeys/241-07-PLAN.md",
    "line": null,
    "description": "A separate 200% text-spacing and supported 400% zoom simulation was not run in Plan 241-07; direct narrow-width and long-text evidence ran.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-10T03:10:50.370Z",
    "resolved_at": "2026-10-10T03:54:19.174Z",
    "milestone": "v1.64"
  },
  {
    "id": 32,
    "kind": "unrun-verify",
    "phase": "241",
    "file": "accrue_admin/e2e/admin-page-flow-phase191.spec.js",
    "line": null,
    "description": "Per-variant browser review interactions were not established; the complete Admin suite covers subscription and payment-method review variants at the route owners.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-10T03:27:48.492Z",
    "resolved_at": "2026-10-10T06:34:44.612Z",
    "milestone": "v1.64"
  },
  {
    "id": 33,
    "kind": "deviation",
    "phase": "242",
    "file": "accrue_admin/lib/accrue_admin/live/connect_account_live.ex",
    "line": null,
    "description": "Optimistic-lock races after fee-review reread return stale-review feedback instead of escaping as an error.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-10T13:22:18.081Z",
    "resolved_at": "2026-10-10T13:22:22.341Z",
    "milestone": "v1.64"
  },
  {
    "id": 34,
    "kind": "unrun-verify",
    "phase": "243",
    "file": ".github/workflows/accrue_admin_browser.yml",
    "line": null,
    "description": "Ubuntu mint and normal selected visual comparison were unavailable because the committed phase source ref does not exist on origin.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-10-10T18:19:10.468Z",
    "resolved_at": null,
    "milestone": "v1.64"
  }
]
````
