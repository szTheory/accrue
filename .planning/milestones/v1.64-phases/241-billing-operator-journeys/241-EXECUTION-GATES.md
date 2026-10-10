# Phase 241 Execution Gates

Executed seven plans in four sequential waves on the existing phase branch. Worktrees and TDD were disabled by project configuration; task commits used normal hooks. This record supplements plan summaries with integrated gates and post-execution corrections.

## Integrated dependency gates

| Boundary | Compile | Full Admin tests |
|---|---|---|
| Wave 1, plans 01–02 | Warnings-as-errors passed | 624 passed |
| Wave 2, plans 03–04 | Warnings-as-errors passed | 630 passed |
| Wave 3, plans 05–06 | Two unused bindings failed the first compile; `e1013955` corrected them, then passed | 642 passed |
| Wave 4, plan 07 | Warnings-as-errors passed | 642 passed |
| Security/UI correction batch | Admin and mounted host warnings-as-errors passed | 646 passed |

No failed compile was treated as acceptance. Plan 07 initially lacked all-review-variant browser coverage, text/spacing/reflow evidence and YAML coverage entries; `1b902e9f` closed those named gaps, including a real Recovery table overflow. The security audit then found stronger scenario gaps; `241-SECURITY-FIX.md` records direct dispatch-count controls and the HTTP500 regression. `241-UI-FIX.md` records the single bounded typography/spacing/Recovery-link correction batch and its confirming captures.

## Required hooks and independent reviews

| Gate | Disposition |
|---|---|
| Schema drift, per wave and final | No schema/ORM paths or drift; not blocking |
| Codebase drift | Explicitly skipped: no `STRUCTURE.md`; no mapper evidence claimed |
| UI contract safety | Contract exists; vocabulary gate is limited and not visual acceptance |
| Nyquist validate-phase | Validated; all 14 planned task owners mapped; 0 manual-only. Security's later stronger checks were added and passed |
| Security secure-phase | Independent final SECURED, 16/16 authored threats closed, 0 blocking, no accepted-risk bypass |
| UI ui-review | Initial 15/24; named findings corrected; scoped confirming review closed them. Broader surface/global-scale migration and Linux goldens remain out of scope |
| Code review | Standard depth, 30 source/test/asset/seam files, clean: 0 critical/warning/info. Required disposition step ran; no finding ledger needed |

The first final-hook CLI attempt supplied the schema gate a directory instead of phase ID and was refused. Correct phase-ID schema and supported `check ui-safety-gate 241` owner invocations succeeded; refused invocations are not pass evidence.

## Current executable acceptance

- Full Admin: 646 passed, 0 failures; SubscriptionLive focused owner: 39 passed.
- Fresh mounted host: 1 passed; exact source, package/compiled/HTTP/browser-served CSS/JS/font evidence and measured Fake invoice action count 0→0. Effective subscription title is 24px/600, named summary gaps are 4px and the no-campaign Recovery link is unique.
- Phase 191 initially passed 28/28. After the UI correction, the broad run was 26 passed/2 failed; both exact owners passed their isolated desktop/mobile rerun (12/12). The Phase 241 review-matrix case passed 1/1 against the final correction, opening ten subscription and two payment-method reviews.
- Phase 199 earlier broad run: 24 passed/15 incumbent skips plus one Chromium launch timeout; that exact case passed 1/1 in isolation. Final focused Phase 241 destination and text/reflow cases passed 2/2. A replaced DOM root initially invalidated the text baseline; atomic snapshot/application/measurement fixed it while retaining finite and exact 2× assertions.
- Text-spacing and measured doubled-text stress span seven changed consumers. A 320 CSSpx reflow simulation is explicitly not physical 400% browser zoom.
- No remote CI result, physical-device, assistive speech, or live-provider observation is asserted by these local runs.

## Prior-phase regression gate

The current milestone's prior verification is Phase 240. Its owner paths include Admin invoice/subscription/fixture tests, Node hook/baseline guards, package invoice layout/detail browsers and mounted host tests. Repository-root sniffing does not recognize this multi-package Elixir project; an empty root command must not count as a green no-op. Actual one-shot owners ran under the existing 600-second GSD timeout:

| Owner | Command | Result |
|---|---|---|
| All Admin tests, including prior owners | `cd accrue_admin && MIX_ENV=test mix test` | 646 passed, 0 failed after final product correction |
| Node hooks and baseline guards | `cd accrue_admin && node --test test/js/*.mjs` | 41 passed, 0 failed/skipped |
| Host server integration owners | `cd examples/accrue_host && MIX_ENV=test mix test` | 223 passed, 0 failed |
| Prior invoice list/detail responsive browsers | `cd accrue_admin && CI=1 npx playwright test e2e/admin-spec-list-phase196.spec.js e2e/admin-spec-detail-phase198.spec.js --project=chromium-desktop --project=chromium-mobile --workers=1` | 42 passed, 4 incumbent skips |

Other browser full-run and isolated-run outcomes are preserved above, not collapsed into an all-green claim. Linux visual baseline review stays with Phase 243.

## Scope and verification-tool limitations

- Registered evaluation scope resolves 21 named task/correction commits, 30 source/test/asset files, zero missing/unreachable/outside-union paths. Summary task rows were normalized so package-browser and follow-up commits participate in the canonical owner union.
- All seven plans author `must_haves.key_links` as prose strings. The generic key-link query selected zero structured links and supplied no wiring evidence. Independent goal verification must inspect real helper/caller/query/mutation wiring and data flow directly.
- Summary 07 retains a 66-minute Performance vs 228-minute metrics discrepancy because available timestamps do not substantiate a correction. Test counts, current artifacts and exact closure commits are the acceptance authority.
