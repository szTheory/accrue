# Phase 242-07 Execution Gates

This is the local acceptance record for Plan 07's existing browser owners and
combined recurring gate. It does not declare Phase 242 complete; the downstream
owner in `242-EXECUTION-HANDOFF.md` still owns phase verification and executable UAT.

## Current source and asset provenance

| Item | SHA-256 |
|---|---|
| Phase 191 owner `accrue_admin/e2e/admin-page-flow-phase191.spec.js` | `a9e68466d5cf387cd6c0ef295289d69da0a3e19e6735f6799a4fbcb5c85ffe3c` |
| Phase 199 owner `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js` | `0a4b6d8b469d1594ac1b7b6d27ec33cb26213e22ac4559a985179b00391f5ad8` |
| Phase 238 owner `examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js` | `5f4a49603a9e5fda507a7198700818c3d34bba96bf7e738611395e3636eb0d02` |
| Phase 234 owner `examples/accrue_host/e2e/phase234-search-completion.spec.js` | `b727efc0cf8601ed325d03384f1eb329b3c9e4c3f7fbb763e57e7a9bfdad5f10` |
| Disposable host fixture helper `examples/accrue_host/e2e/support/fixture.js` | `f4820cd6be0dc4d4f328f8b782347897d53382ce2f25f4c0af8d3cc3a8ea305f` |
| Package CSS source `assets/css/app.css` | `8a7a6ff3c1b5b2bb22d49a029939699ff7d66945a765d644282993b14c1804a9` |
| Package theme source `assets/css/theme.css` | `079ec99553c73c2df07b6212c1bf9eba18645363e278c3fd7d01374990d1c90e` |
| Search hook source `assets/js/hooks/command_palette.js` | `c23f01da4d8b30693680e48f1fd750d45d0e815984b25c973cb856eab6831f2f` |
| Built package JS (`accrue_admin/priv/static/accrue_admin.js`) | `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085` |
| Built package CSS (`accrue_admin/priv/static/accrue_admin.css`) | `9c78c9f03c0ebbbd8aeb66b5c762dcca3a8e990ccd87d2acf07046c4625ebc93` |
| Host compiled JS (`examples/accrue_host/_build/test/lib/accrue_admin/priv/static/accrue_admin.js`) | `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085` |
| Host compiled CSS (`examples/accrue_host/_build/test/lib/accrue_admin/priv/static/accrue_admin.css`) | `9c78c9f03c0ebbbd8aeb66b5c762dcca3a8e990ccd87d2acf07046c4625ebc93` |

`mix accrue_admin.assets.build` completed before browser acceptance. The host Phase
238 owner compared package bytes with host compiled files, then checked the served
HTTP response and browser resource entry against those same digests. Its assertions
passed on the freshly started host for both JS and CSS. Source files are separately
fingerprinted above; source SHA values are not expected to equal bundled bytes.

## Executed owner commands

| Command | Result |
|---|---|
| `mix accrue_admin.assets.build` (with task-scoped npm cache under `/private/tmp`) | Passed; fresh package bundle above. |
| `CI=1 npm --prefix accrue_admin run e2e:phase191` | 29 passed, 1 incumbent skip, 0 failed. The `@phase242` scenario exercised coupon → filtered promotion code → exact parent coupon, Connect detail → exact fee review account, validation/correction, dismissal and focus return. |
| `CI=1 npm --prefix accrue_admin run e2e:phase199` | 27 passed, 15 incumbent skips, 0 failed. Changed shell consumers exercised 320/768/1280 CSS widths, light/dark/system effective themes, emulated coarse pointer, disclosure/focus, and atomic CSS text/spacing stress before patch checks. Skips are pre-existing project applicability skips. |
| `cd examples/accrue_host && CI=1 npx playwright test e2e/phase238-admin-events-webhooks.spec.js e2e/phase234-search-completion.spec.js --project=chromium-desktop --workers=1` | 2 passed, 0 failed. The mounted host asserted current search selection and scoped destination; event filtered membership and exact source webhook; single/bulk replay review and target; plus package/compiled/HTTP/browser asset identity. |
| `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/live/webhook_replay_test.exs test/accrue_admin/live/webhooks_live_test.exs` | 25 tests, 0 failures. Authoritative job/audit/domain checks cover dismissal/no dispatch, duplicate IDs, stale scope/eligibility and pre-dispatch read failure. |
| Combined gate below | Passed after the two direct blockers were fixed; exact totals and timings are listed below. |

### Combined gate

Exact command:

```sh
cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && node --test test/js/*.mjs && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test
```

- Admin warnings-as-errors compile: passed.
- Admin ExUnit: 679 tests, 0 failures (about 21.7 seconds test runtime).
- Node: 44 tests, 44 passed, 0 failed (about 0.32 seconds).
- Host warnings-as-errors compile: passed.
- Host ExUnit: 223 tests, 0 failures (about 7.4 seconds test runtime).
- Final combined command exited 0. The output included existing dependency locale/exchange-rate and test operation-id warnings; no compiler warning remained.
- First combined attempt exposed two blockers: an unreachable stale-result clause and a host test calling the complete replay-result formatter with a map missing `denied` and `unknown`. The stale result branch now precedes the generic changeset clause; the test fixture supplies all required counters. Fix commit: `ffcfb9be`.

## Visual and evidence bounds

- Batched visual budget: one screenshot inspected, one corrective UI batch used zero, confirming inspection used zero. Inspected capture: `accrue_admin/test-results/admin-page-flow-phase191-P-54cd8-ships-and-fee-review-target-chromium-desktop/test-failed-1.png` (1280×900, system appearance). The rendered Connect summary, saved snapshot note, unknown fields and local fee policy were legible in the viewport. A broken brand logo appeared at top left; it is outside this task's changed UI and was not modified.
- Automated layout assertions exercised CSS viewport widths and Playwright media/device emulation. They are not physical-device proof. CSS text enlargement and spacing stress checks do not claim native browser zoom or 200% physical zoom. No screen-reader speech, live-provider behavior, remote CI result, or Linux golden review is claimed.
- Screenshot observation was a visual check, not human sign-off; this gate has `human_judgment: false` for its deterministic test-proven deliverables. Phase 243 owns final reviewed Linux goldens and stable feedback preview.
- The search key-link helper returned zero structured links for the prose declarations; no claim is made that it proved helper wiring. Acceptance evidence here is from the named Playwright and ExUnit owners.

## Phase 242-07 coverage predicates

| Predicate | Current evidence |
|---|---|
| Exact catalog relationships and route return | Phase 191 mounted coupon/code/coupon path. |
| Exact Connect fee target, valid/invalid correction, dismissal and focus | Phase 191 mounted fee review; persistent fee state remains owned by the existing authoritative LiveView tests. |
| Filtered event membership and exact source delivery relation | Host Phase 238 mounted assertions. |
| Single and bulk replay exact target; dismissal, duplicate, stale and read-failure behavior | Host Phase 238 DOM assertion plus replay/webhook ExUnit assertions over jobs, audit and domain state. |
| Search pointer, Arrow and Enter to current scoped result; no-match/reopen | Host Phase 234 mounted assertion. |
| Partial failure / zero-one-many / loading-error-empty states | Only credited where a specific named existing owner asserts the predicate. The aggregate suite run is not taken as proof of every state on every route. |
| Narrow widths, theme and atomic text stress | Phase 199 assertions in the supported desktop/mobile Playwright projects and viewport/media emulation. No physical device or browser zoom inference. |

## Corrective batch acceptance — 2026-10-10

This dated appendix records the one authorized corrective batch after review. The
prior section remains the original Plan 07 record; its historical counts and
digests are unchanged.

### Fix commits and focused regression

| Change | Commit | Verification |
|---|---|---|
| WR-01 retry retains already successful groups while fetching only failed groups; ordinary full search starts with empty results | `c39cc1c2` | `cd accrue_admin && MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs`; 16 tests, 0 failures. Semantic regression drives the same group lookup reducer with a preserved customer result, successful invoice retry and failing invoice retry. Existing query/generation/owner guards remain in place. |
| Four UI audit corrections: body token, Home coarse-pointer target sizing and recurring geometry assertion, canonical filtered-empty event copy, and dark-table theme tokens | `157ef37d` | `node -c` on both modified Playwright files; focused ExUnit for `global_search_test.exs` and `events_live_test.exs`; 29 tests, 0 failures. |
| Generated package CSS matching corrected source | `16bbcdfe` | `npm_config_cache=/private/tmp/accrue242-npm-cache MIX_ENV=test mix accrue_admin.assets.build`; passed. |

The asset build's first attempt used the host npm cache and failed with EPERM
because it contains root-owned entries. The same build passed with a task-scoped
cache under `/private/tmp`; no dependency or lockfile changed.

### Current browser owners and combined gate

Commands ran in the main checkout. Initial Phase 191 acceptance exposed two
mobile failures after an earlier sandbox-blocked Chromium launch left a test
server behind. The stale server was stopped. A focused rerun of both reported
cases passed (2/2), then the complete incumbent command passed. Assertions and
thresholds were not changed to obtain the pass.

| Command | Result |
|---|---|
| `CI=1 npm --prefix accrue_admin run e2e:phase191` (final run) | 29 passed, 1 incumbent skip, 0 failed. |
| `CI=1 npm --prefix accrue_admin run e2e:phase199` | 27 passed, 15 incumbent skips, 0 failed. New geometry assertion measures all three Home shortcut bounding-box heights at 768 CSS px under emulated coarse pointer. |
| `cd examples/accrue_host && CI=1 npx playwright test e2e/phase238-admin-events-webhooks.spec.js e2e/phase234-search-completion.spec.js --project=chromium-desktop --workers=1` | 2 passed, 0 failed. The owner asserted source/package/host-compiled/HTTP-served/browser resource identity and current route behavior. |
| Combined Admin compile/test, Node, and host compile/test command from Plan 07 | Both warnings-as-errors compiles passed; Admin ExUnit 679 tests, 0 failures; Node 44 passed, 0 failed; host ExUnit 223 tests, 0 failures; command exit 0. Logs are under `/private/tmp/accrue242-{admin-compile,admin-test,node-test,host-compile,host-test}.log`. |

### Corrected source and asset identity

The source CSS was rebuilt after the final source edits. Package output and host
compiled output matched byte-for-byte:

| Item | SHA-256 |
|---|---|
| `accrue_admin/assets/css/app.css` | `59c7f4d0e1a9cee7bb348ff582f393917eef81b51c50123225e53c6db706110d` |
| `accrue_admin/assets/css/theme.css` | `079ec99553c73c2df07b6212c1bf9eba18645363e278c3fd7d01374990d1c90e` |
| `accrue_admin/assets/js/hooks/command_palette.js` | `c23f01da4d8b30693680e48f1fd750d45d0e815984b25c973cb856eab6831f2f` |
| `accrue_admin/priv/static/accrue_admin.css` and host test-compiled CSS | `455bcde681880b2e3225d6e94d4de3e2342618cd95b2b11206af779b7ff6a0ea` |
| `accrue_admin/priv/static/accrue_admin.js` and host test-compiled JS | `36974c751ef3c9df6f40a2ff7fa09c04d85819dac2de74804d8438f6c3be3085` |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | `f10b3820420c207ce9e4859b496341311aef3a62a5818e442a6b7ec05a023d0f` |
| `accrue_admin/lib/accrue_admin/live/events_live.ex` | `7a452b2d286b50a1f3144025de82062a93d31f9261bc89dfe4b2845c06ac6dbb` |
| Phase 199 browser owner after geometry assertion | `5cecde186a208be160fe8783ca1cba8dd6b6eb73163223042d604aab71b3b9b4` |
| Host Phase 238 browser owner after copy assertion | `fd673aab7b2797f9493cb0b347754d1038ec9416616381f75a20abe242b0c2bb` |
| Host disposable fixture helper | `f4820cd6be0dc4d4f328f8b782347897d53382ce2f25f4c0af8d3cc3a8ea305f` |
| Package E2E server source used for logo diagnosis | `a9511a2797c48c0abd0b7cb216451cbe0aee656b2ec01c6352d5e4f0e26fe87b` |

The passing host Playwright owner compared package assets with host compiled
files and checked both served HTTP responses and browser resource entries. CSS
source SHA differs from the compiled CSS SHA as expected for generated bundles.

### Corrective batch and evidence limits

- Shared visual budget: one historical screenshot had already been inspected;
  this corrective batch used no new capture. A confirming inspection was
  attempted against that recorded screenshot path, but the file was absent, so
  no confirming visual inspection is claimed. No capture scan/reset occurred.
- The broken-logo observation is bounded to the disposable package browser
  fixture: its E2E server sets `logo_url` to `https://example.test/logo.svg`,
  while the source fallback for `logo_url: nil` is a self-contained inline SVG.
  The recorded screenshot was unavailable for confirmation, so the cause is a
  source-supported fixture diagnosis, not a fresh visual finding. No logo code
  was changed and no redesign is implied.
- Media queries, CSS viewport widths, and pointer mode are browser emulation.
  No physical-device behavior, native browser zoom, speech-only screen-reader
  behavior, live-provider result, remote CI result, or Linux golden review is
  claimed. Phase 243 retains Linux golden and stable preview ownership.
- Automated assertions decide this batch's acceptance; no human UAT checkpoint
  is required or claimed.

