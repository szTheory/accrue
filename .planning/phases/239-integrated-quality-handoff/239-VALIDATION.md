---
phase: "239"
slug: "integrated-quality-handoff"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 239 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit / Phoenix LiveView in `accrue`, `accrue_admin`, `accrue_portal`, and `examples/accrue_host`; Playwright Test in the host example |
| **Config file** | Package `mix.exs` files; `examples/accrue_host/playwright.config.js` |
| **Quick run command** | Focused package suites for touched behavior; current render proof: `cd examples/accrue_host && CI=1 npx playwright test e2e/phase239-integrated-quality.spec.js --project=chromium-desktop` |
| **Full suite command** | `cd accrue && mix test`; `cd accrue_admin && mix test --warnings-as-errors`; `cd accrue_portal && mix test --warnings-as-errors`; `cd examples/accrue_host && mix verify.full` |
| **Merge-blocking browser gates** | `.github/workflows/ci.yml` `host-integration` runs the full host ExUnit contract suite; `playwright-e2e` runs the render spec in existing shards and retains its HTML/test-results attachments. |
| **Database safety** | Dev/Docker preview uses `accrue_host_dev`; `config/test.exs` uses `accrue_host_test`; reset/reseed proof runs with `MIX_ENV=test`. Render walkthrough asserts no post-login writes. |
| **Estimated runtime** | Record focused and full-suite timings per plan wave; keep browser coverage to uncovered mounted behavior |

---

## Sampling Rate

- **After each behavior task:** Run its focused ExUnit/LiveView check; run the Phase 239 mounted render spec for actual route, landmark, resource, viewport, and request-boundary behavior.
- **After each plan wave:** Run focused package regressions and the relevant Phase 239 Playwright journey.
- **Before phase verification:** Run all affected package suites, asset/copy parity commands, route and served-resource checks, and Phase 239 browser coverage. Record that local evidence separately from remote CI status.
- **Max feedback latency:** Keep focused checks under 5 minutes where practical; record actual timings during execution.

---

## Per-Requirement Verification Map

This finalized map binds the plan task IDs, waves, requirements, threats, commands, and recurring gate disposition. Every task has an automated check with an adjacent failure signal in its PLAN.md.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 239-01-T1 | 239-01 | 1 | INT-01, INT-02, INT-03, INT-04, SHIP-02 | T-239-01, T-239-02 | Build source-current ownership/evidence rows and enforce the exact compiled package mount set against structured ledger rows. | ExUnit route freshness contract | `cd examples/accrue_host && mix test test/accrue_host_web/phase239_route_coverage_contract_test.exs` | New host ExUnit contract + ledger | Planned; recurring `host-integration` → Run host integration gate → `mix verify.full` |
| 239-01-T2 | 239-01 | 1 | INT-01, INT-02, INT-03, SHIP-02 | T-239-01 | Inspect current mounted Admin, Portal, and host renders; assert route/status/landmark/identity/overflow/no-write behavior and attach PNGs. | Playwright Chromium desktop | `cd examples/accrue_host && CI=1 npx playwright test e2e/phase239-integrated-quality.spec.js --project=chromium-desktop` | New spec + existing HTML/test-results artifacts | Planned; recurring `playwright-e2e` → Run Playwright shard; PNG evidence retained by the adjacent artifact upload step |
| 239-02-T1 | 239-02 | 2 | SHIP-01 | T-239-03, T-239-04 | Reconcile Admin/Portal source, actual served asset/font/mount, CSP nonce/allowlist, and checkout SRI contracts independently. | ExUnit | `cd accrue_admin && mix test test/accrue_admin/assets_test.exs && cd ../accrue_portal && mix test test/accrue_portal/csp_plug_test.exs test/accrue_portal/live/checkout_live_test.exs` | Tracked asset/CSP/SRI tests | Planned; recurring Admin and Portal package test jobs |
| 239-02-T2 | 239-02 | 2 | SHIP-01 | T-239-03 | Compare complete regenerated Admin copy JSON with tracked fixture using temporary output and cleanup. | ExUnit exact export equality | `cd accrue_admin && mix test test/accrue_admin/copy_test.exs` | Tracked copy test/export | Planned; recurring `admin test` → `mix test --warnings-as-errors` |
| 239-03-T1 | 239-03 | 2 | INT-04, SHIP-03 | T-239-05, T-239-06 | Map production component registry to examples and assign each required state family to current evidence. | ExUnit | `cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/storybook_coverage_test.exs` | Tracked derived contracts | Planned; recurring `admin test` → `mix test --warnings-as-errors` |
| 239-03-T2 | 239-03 | 2 | INT-04, SHIP-03 | T-239-05 | Add only a report-confirmed example assertion; rerun suite only if either test file changes, otherwise validate the no-gap report disposition. | Conditional ExUnit / report check | `if git diff --quiet -- accrue_admin/test/accrue_admin/dev/component_registry_test.exs accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs; then node -e 'const fs=require("fs");const s=fs.readFileSync(".planning/phases/239-integrated-quality-handoff/239-COMPONENT-PARITY.md","utf8");if(!s.includes("No additional assertion required"))throw Error("report does not disposition the conditional check");console.log("No code change required; Task 1 contains the passing parity run")'; else cd accrue_admin && mix test test/accrue_admin/dev/component_registry_test.exs test/accrue_admin/dev/storybook_coverage_test.exs; fi` | Existing parity tests; conditional test edit | Planned; recurring `admin test` job and local rerun only after code change |
| 239-04-T1 | 239-04 | 3 | SHIP-03 | T-239-07, T-239-08, T-239-09 | Source-check dev/test/Compose database split and scope no-write claims to the feedback walkthrough. | Handoff + config contract | `node -e 'const fs=require("fs");const p=".planning/phases/239-integrated-quality-handoff/239-HANDOFF.md",d=fs.readFileSync("examples/accrue_host/config/dev.exs","utf8"),t=fs.readFileSync("examples/accrue_host/config/test.exs","utf8"),c=fs.readFileSync("examples/accrue_host/docker-compose.yml","utf8"),b=fs.readFileSync("scripts/ci/accrue_host_verify_browser.sh","utf8");const h=fs.readFileSync(p,"utf8");for(const x of ["Fake-backed","read-only walkthrough","verify.full","accrue_host_dev","accrue_host_test","provider","change summary"]){if(!h.toLowerCase().includes(x.toLowerCase()))throw Error("handoff missing: "+x)}if(!d.includes("accrue_host_dev")||!c.includes("accrue_host_dev")||!t.includes("accrue_host_test")||!b.includes("MIX_ENV=test mix ecto.drop"))throw Error("database boundary changed");console.log("Preview and proof databases are distinct")'` | Handoff + tracked dev/test/Compose/reset sources | Planned; source check local, host reset proof recurring `host-integration` |
| 239-04-T2 | 239-04 | 3 | SHIP-03 | T-239-07, T-239-09 | Verify README link, feedback state evidence, non-GET request assertion, and no unsupported CI claim. | Documentation/source contract | `node -e 'const fs=require("fs");const r="examples/accrue_host/README.md",p=".planning/phases/239-integrated-quality-handoff/239-HANDOFF.md",e="examples/accrue_host/e2e/phase239-integrated-quality.spec.js";const a=fs.readFileSync(r,"utf8"),b=fs.readFileSync(p,"utf8"),s=fs.readFileSync(e,"utf8");if(!a.includes("239-HANDOFF.md"))throw Error("README handoff link missing");if(!/loading|unavailable/i.test(b)||!/320/i.test(b)||!/long/i.test(b))throw Error("host feedback state evidence incomplete");if(!/POST|PUT|PATCH|DELETE/.test(s)||!/nonGetRequests/.test(s))throw Error("walkthrough request-boundary assertion missing");if(/remote CI (?:passed|green|successful)/i.test(b))throw Error("unsupported remote CI claim");console.log("Handoff link and walkthrough source assertions are consistent")'` | README + handoff + render spec | Planned; route/render proof recurring `playwright-e2e` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] 239-01-T1 applies resolved route/persona decisions, writes complete route/interaction evidence rows, and adds the recurring compiled-router-to-ledger contract in the existing host integration test suite.
- [ ] 239-01-T2 always adds the narrow current Admin/Portal/host render journey with deterministic landmark/resource/viewport/no-write assertions, PNG attachments, and existing `playwright-e2e` artifact retention.
- [ ] 239-02-T1 reconciles generated and served Admin/Portal resources, font/mount responses, CSP/SRI boundaries, and exact local tests.
- [ ] 239-02-T2 adds full temp-output exporter/fixture equality and cleanup inside `copy_test.exs`, executed by the existing required Admin test job.
- [ ] 239-03-T1 reconciles the production component registry/examples/state suites; T2 reruns tests only if a test file receives a real gap fix.
- [ ] 239-04-T1 source-checks distinct dev/test databases and restricts read-only/no-write claims to the feedback walkthrough; T2 reconciles the linked handoff.
- [ ] Every task row names its final plan/task, wave, threat references, file status, automated command, and an immediately adjacent `<fails_when>` signal in its plan.
- [ ] No new test framework, package, or hosted visual service is needed unless the coverage ledger proves a concrete gap.

---

## Manual-Only Verifications

All stable in-scope behavior should have deterministic automated verification. No routine human UAT is planned. Optional owner feedback is limited to subjective impressions from the isolated preview; live-provider fidelity is outside fixture-based claims and must be recorded as such if it remains relevant.

---

## Validation Sign-Off

- [ ] Every plan task has an `<automated>` verification and an immediately following `<fails_when>` sibling.
- [ ] Sampling continuity: no three consecutive tasks without automated feedback.
- [ ] Wave 0 covers every missing route/evidence reference.
- [ ] No watch-mode flags.
- [ ] Feedback latency and suite results are recorded during execution.
- [ ] `nyquist_compliant: true` is set only after finalized coverage and passing evidence.

**Approval:** pending plan/check and execution.
