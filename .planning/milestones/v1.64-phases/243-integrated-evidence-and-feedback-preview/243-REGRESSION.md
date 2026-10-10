---
phase: 243
status: passed
behavior_unverified: 0
recorded: 2026-10-10
source_corrections: [388483ce, 12649d27, 3c5fa035]
---

# Phase 243 prior-phase regression gate

Discovered 49 unique existing paths from Phase 240–242 VERIFICATION/SUMMARY artifacts: 47 test files, the Phase240 ledger verifier, and the executable-UAT contract. The 47 test files and ledger ran below. D-16 requires the executable-UAT project contract after independent verification and generated Phase243 UAT; it belongs to the ordered closeout, not this pre-verifier gate.

Commands ran once-shot under `gsd_run run-with-timeout 600`; the normalization helper retained the explicit bash scripts. The generic language-sniff fallback would choose `true` in this Elixir monorepo, so the gate used its actual package/host owners. No exit 124 occurred.

| Owner | Command / scope | Result |
|---|---|---|
| Admin ExUnit | `cd accrue_admin && mix test <33 discovered test/accrue_admin/*.exs paths>` | 443 tests, zero failures |
| Admin Node | `cd accrue_admin && node --test test/js/command_palette_test.mjs test/js/focus_trap_test.mjs test/js/visual_baseline_set_test.mjs` | 37 passed |
| Package browser | `cd accrue_admin && CI=1 npm run e2e -- e2e/admin-page-flow-phase191.spec.js e2e/admin-spec-detail-phase198.spec.js e2e/admin-spec-list-phase196.spec.js e2e/admin-interaction-overlay-phase199.spec.js --workers=1` | 100 passed, 20 incumbent applicability skips; desktop/mobile |
| Host ExUnit | `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs test/accrue_host_web/phase239_route_coverage_contract_test.exs` | 3 tests, zero failures |
| Mounted host browser | `cd examples/accrue_host && CI=1 npm run e2e -- e2e/phase234-admin-customers-subscriptions.spec.js e2e/phase234-post-layout.spec.js e2e/phase237-admin-billing.spec.js e2e/phase238-admin-events-webhooks.spec.js --project=chromium-desktop --workers=1` | 6 passed; current CSS/JS identity, altered-response rejection, spacing, focus and exact destinations |
| Dedicated search | `cd examples/accrue_host && CI=1 npm run e2e:search -- e2e/phase234-search-completion.spec.js --workers=1` | 1 passed after 3c5fa035 |
| Evidence ledger | `node scripts/ci/verify_phase240_evidence.mjs .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` and `--self-test <same ledger>` | 21 routes, registry 30/42/8; omitted route rejected |
| Post-review proof paths | `node scripts/ci/test_accrue_host_proof_paths.mjs` | 1 passed; unsafe identifiers and four escaped destinations rejected |
| Post-review custody | `node scripts/ci/test_accrue_host_preview_custody.mjs` | 13 passed; caller synthetic fixtures refused by direct setup and wrappers |
| Explicit preview | README `e2e:preview` single-spec command with dedicated instance and existing operator inputs | 1 passed; warm skip-seed recovery and exact snapshot preservation |

The exact 49-path discovery is recorded in `/private/tmp/phase243-regression-files.json`. Execution logs: `/private/tmp/phase243-regression-admin.log`, `/private/tmp/phase243-regression-package-browser.log`, `/private/tmp/phase243-regression-host.log`, `/private/tmp/phase243-regression-search-confirm.log`, and `/private/tmp/phase243-postfix-preview.log`.

## Custody and history

Live preflight ran before mutable host setup. Preview stayed on `accrue-host-phase243-preview` / `accrue-host-phase243-preview_pgdata` / `accrue_host_dev`, loopback 56466. Proof used native `accrue_host_test`; the ordinary desktop owner used port 4101 and absolute per-run host/admin paths with ID 6716. Dedicated search used port 4102 and a separate `phase243-reg-search` build with SQL Sandbox disabled. Phase237 captures went to `/private/tmp/phase243-regression-host-captures`, preserving historical capture destinations. Package fixture used port 4017 and its own test database/output.

The first search attempt reused the ordinary Sandbox-enabled build and was correctly refused at compile-environment validation. The separate build then exposed a stale test assertion: a matching invoice followed the customer, so ArrowDown correctly selected that invoice. Commit 3c5fa035 verifies movement and status, ArrowUp to the exact customer, and Enter navigation. This is a regression-test repair; no production hook was changed or existing scope/stale-result assertion removed. Its confirming run passed.

An authoritative invoice/audit/webhook/dispatch snapshot was captured before these runs and remained byte-equal after the ordinary host checks, explicit warm recovery, failed search attempts, and confirming search. The dedicated preview owner also independently captured and compared its own snapshot. The incumbent full verifier and Ubuntu comparison remain historical at their recorded revisions; this gate makes no new full-suite, Linux-pixel, live-provider, physical-device or screen-reader claim.
