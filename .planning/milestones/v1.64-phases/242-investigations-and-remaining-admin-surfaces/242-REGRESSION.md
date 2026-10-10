---
phase: 242-investigations-and-remaining-admin-surfaces
status: passed
human_judgment: false
prior_test_files: 21
---

# Phase 242 regression and recurring CI evidence

## Prior-phase scope

The current milestone's Phase 240 and 241 verification reports identify 21 existing test files: 12 Admin ExUnit files, 3 Node files, 4 package browser specs, and 2 mounted host browser specs. Full Admin and Node suites cover the first 15; the fresh browser owners below cover the remaining 6. This is current consumer regression evidence, not a rewrite of historical reports.

## Fresh executed checks — 2026-10-10

| Owner | Result |
|---|---|
| Bounded combined Admin compile/test, Node, host compile/test | Exit 0; both compiles use warnings-as-errors; Admin 679/0, Node 44/0, host 223/0. |
| Package Phase 191 and 199, corrective batch | 29 and 27 passed; 1 and 15 incumbent applicability skips. Full final runs passed; initial Phase 191 failures remain disclosed in EXECUTION-GATES. |
| Host Phase 238 and 234, corrective batch | 2 passed; compiled, served HTTP and browser asset identity assertions passed. |
| `CI=1 npm --prefix accrue_admin run e2e:phase196` | 14 passed, 0 failed. |
| `CI=1 npm --prefix accrue_admin run e2e:phase198` | 28 passed, 4 incumbent applicability skips, 0 failed. |
| Host Phase 237, chromium-desktop, workers=1 | 1 passed, 0 failed. |

Combined one-shot command, normalized through GSD and run under its 600-second timeout:

```sh
cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && node --test test/js/*.mjs && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test
```

The remaining browser commands also ran under the 600-second bound. The first restricted browser attempt failed before application assertions because macOS denied Chromium bootstrap registration; the same commands passed in the authorized local runner. No timeout, assertion weakening, threshold change, or new retry configuration was used.

## Recurring CI closure

Inspection found the existing `browser-uat` job in `accrue_admin_browser.yml` ran only the 12-test visual baseline owner. Its existing Node step now runs `node --test test/js/*.mjs`, including all 44 command-palette, focus and baseline controls. Existing package browser, Admin ExUnit and mounted host jobs retain their owners. No dependency or job/matrix was added. This follows the current [GitHub run-step syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsrun); action versions were unchanged.

The project-local `ci_monitor.cjs` supports repository-bound list/inspect/watch only and rejected the skill's `--help` option. No remote monitor operation was needed for this local step edit. The exact Node command passed locally; remote CI execution and required-check configuration remain unobserved.

## Bounds

No additional visual inspection or correction batch was used. Physical devices, native zoom, screen-reader speech, live providers and Linux pixel baselines are not claimed. Phase 243 retains final reviewed Linux goldens and stable feedback preview ownership. Required human UAT is zero for the executable acceptance in this phase.

The host Phase 237 regression owner emitted one incidental capture batch (five fixture PNGs plus its manifest) at its historical Phase 240 output path. These outputs were preserved in task scratch; only this run's generated files were restored to their pre-run committed bytes, and its newly generated narrow image was moved to task scratch. No images from this batch were inspected, no further UI correction was made, and no Linux pixel proof is claimed. The phase still used one corrective batch and zero confirming inspections. Future regression invocations must inspect capture destinations before running owners that write historical evidence.
