# 254-15 checkpoint log

Evidence note for the continuation agent (precedent: 254-03-CHECKPOINT-LOG.md). Written when 254-15-01 stopped at checkpoint 254-15-02; no owner answer is recorded here yet.

## State at the stop (2026-10-29)

- Branch gsd/phase-252-production-backed-subscription-stories, pushed head `27c6444d2c2de8f07eea3e3ed604e3d1a4bdd742` (PR #58 still a draft). This log is a later local-only commit.
- Pre-push gate on that exact commit: efficiency, script guard coverage, census, no-home-paths, archive invariants, package docs, PR claims, phase254 projection and budget checks, docs-contracts steps (only the known SL-G, SL-F-without-token and Executable UAT steps red), the admin release sequence (format, compile, 786 tests, credo, dialyzer, docs), the assets rebuild and storybook recompose freshness, the full Phase 200 runner including the Phase 252 and 253 aggregates and the budget check, and the whole local `npm run e2e` (all green after the fix below).
- Owner push authorization (254-03-01) covered the push and the one mint dispatch.

## The one mint (D-08)

- Mint run **40876347666** (workflow_dispatch on `27c6444d2`, inputs reason "CIQ-03 mint of the subscription visual baselines after the 254-12/13 correction batch", finding_id "CIQ-03"). Mint job success: repeat-each=3 stability proof, manifest build and the manifest-backed set check all passed. Nothing was committed from it and no second mint was dispatched.
- Artifact `phase211-visual-baselines` downloaded to `accrue_admin/tmp/phase254/mint/40876347666/` (gitignored): `e2e/__screenshots__/visual-desktop/` (44 PNG plus manifest.json) and `tmp/phase254/visual-identity/` (32 identity files). No symlinks. PNGs are Linux-minted only.
- Disposition (`scratchpad` analysis against the committed PNGs): 32 new case PNGs; legacy keys unchanged: component-kitchen, component-kitchen-dark, dashboard, dashboard-dark; legacy keys changed:

| key | before | after | classification |
|-----|--------|-------|----------------|
| subscription-detail, subscription-detail-dark | 1280x1859 | 1280x1879 (+20) | DR-254-03 (label rule) with DR-254-01 (rhythm) and the 254-12 reflow rules: expected |
| invoice-detail, invoice-detail-dark | 1280x1643 | 1280x1637 (-6) | DR-254-03 (field-list label rule): expected |
| subscriptions, subscriptions-dark | 1280x932 | 1280x940 (+8) | A11Y-254-28 (`.ax-data-table-identity-secondary` row gap, 254-12): NOT a design-review finding, the plan says these must stay byte-identical: regression key |
| invoices, invoices-dark | 1280x1032 | 1280x1044 (+12) | A11Y-254-28 (same shared DataTable component): regression key |

- Environmental check: the latest origin/main Browser UAT run (40361348536, push, success) passed the visual gate, so none of the keys is environmental.
- Plan defect found: "subscriptions.png and subscriptions-dark.png equal their merge-base blobs" cannot hold, because 254-03 re-minted both on the runner (commit 365338781, dispatch 40771021813) before this plan. The invariant that matters is equality with the baselines at the start of 254-15 (HEAD c017aeede); they are not equal (above).

## Fixes made while observing (all in the pushed head)

- `ccea86232` the manifest build re-attests a legacy (phase211-committed) PNG that moved since the merge-base (`--base`); without it `check --base` fails for subscriptions and subscriptions-dark whose entries were legacy while their bytes differ from the merge-base (reproduced on the real tree before the fix).
- `c59843a9d` `confirmedCapturesMatchManifest` and the confirmed-stage verdict rules in the design review verifier (23 self-test scenarios); capture route text for pages corrected.
- `b77de3baf` Phase 191 spec: the Connect fee drawer journey now expects the 254-12 scroll-region tab stop (3 of 3 red before, 3 of 3 green after).
- `27c6444d2` JSON report added for the browser jobs so visual per-cell durations are measurable.

## Observation runs on `27c6444d2` (attempt 1, nothing rerun)

- CI 40876348250: Docs and bash contracts red only at SL-G (KR-254-06, accepted). **Admin Phase 200 deterministic guardrails red**: `phase253-compositions-browser`, 22 of 151 cells with undispositioned deep-probe observations that did not reproduce in three local runs: 20 dark cells `probe-focus-visible ring-contrast-1.02` (and 1.12 on `#step-up-code`) on `summary`, `nav a`, drawer panel; 2 light 320px cells `probe-text-spacing clipped-under-text-spacing` on `aside.ax-overlay-panel`. Likely cause: the probe reads the focus ring and the clipped panel while a CSS transition is still in flight on the slower runner (the probe waits for animations once at line 414 of `accrue_admin/e2e/phase254-a11y-probes.js`, not after each Tab). Evidence: artifact `phase200-admin-playwright-evidence` (error-context per cell), `phase253-machine-evidence`.
- Browser UAT 40876348154 (pull_request): "Run browser UAT" and the Admin hooks test passed; red at "Require complete committed visual baseline set" (32 case baselines missing, expected before the rebaseline commit); the manifest check and the visual gate steps were skipped behind it.
- Dispatch run 40876347666 also ran its own Browser UAT job (red on the same set guard, a dispatch artifact not a pull_request observation).

## Open for the owner (254-15-02)

See the checkpoint report: the four list keys (A11Y-254-28 attribution) and the new red in `admin-phase200-guardrails`.

## 254-15-02 Owner disposition (2026-10-29)

- Gate: blocking-human, never auto-answered. The owner answered per item (relayed by the orchestrator, recorded verbatim).
- Item A (subscriptions, subscriptions-dark, invoices, invoices-dark; caused by A11Y-254-28): **"accept-attributable (Rec.)"**. Executed as: commit exactly mint 40876347666 (no second mint, no AMD-254-06); `baselines_changed` maps the four keys to A11Y-254-28; the design review verifier accepts a routed A11Y-254-NN id only when it is a routed-defect of the register at AMD-254-05's register_commit (negative controls: an id outside that scope, a justified exception, an unknown id shape and a record without the amendment are rejected).
- Item B (admin-phase200-guardrails, 22 deep-probe cells): **"fix-in-phase (Rec.)"**. Executed as: reproduce first, prove RED, fix deterministically with no sleep and no timeout bump, prove green under throttling, new commit, full pre-push gate, push, observe a new attempt-1 run, never rerun; if the reds persist or another undecided red appears in an owner job, stop with another checkpoint.
- Plan defect recorded: "subscriptions.png and subscriptions-dark.png equal their merge-base blobs" could never hold after 254-03's runner re-mint (365338781); the real invariant is equality with the baselines at c017aeede, and they differ (+8 px, A11Y-254-28).
- `subscriptions.png` no longer carries the H1 token swap's zero-visual-change proof; `DR-254-02:computed` (767 and 768 CSS px, green before and after) carries it.
- The rebaseline commit adopts a theme-toggle change in the invoices baselines: the previous `invoices.png` shows the System option selected, the current render shows Light. The gate's tolerance hid it before.

## Item B reproduction and fix

- Not reproducible under CDP CPU throttling alone: the three failing dark cells and the 320px light drawer cells passed at 4x and 8x (the Phase 253 cell universe runs fine at 6x with 3 workers). The CI evidence (ring-contrast 1.02 on dark cells only, a start colour of a transition; clipping measured on a panel that was not settled) points at probes reading before in-flight transitions and fonts settle: the `--ax-dur-2` token is 1ms under reduced motion, so a slow frame still shows the start value.
- RED: a new injected control (`transition_in_flight`: a white ring on a wrapper whose background starts a 700ms transition to black) with `settlePage` disabled reads `ring-contrast-1.03` and fails the geometry negative-control cell. GREEN: with the settle in place the ring reads settled. 196 cell executions at 6x CPU throttling, 3 workers, repeat 2 pass.
- Fix: `settlePage` in `phase254-a11y-probes.js` waits on `document.fonts.ready` and the `finished` promises of every finite running animation (strict: a transition that never settles fails), called before axe, target size, every focus read, text spacing and text scale. Commit `79d4c8532`.
