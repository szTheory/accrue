# Phase 239 preview handoff

## Preview and optional feedback

Start the Fake-backed Cadence preview using the [host README](../../../examples/accrue_host/README.md): `cd examples/accrue_host`, `make proxy` once, then `make up`. Open `http://accrue.localhost/` (or the loopback fallback printed by the banner). Use the existing operator and healthy-customer instructions there; credentials are intentionally not duplicated here.

Optional owner feedback is subjective polish input collected outside the app. There is no in-app feedback widget, feedback loading control, or long-feedback-text behavior in scope. The local processor is `Accrue.Processor.Fake`; this preview does not establish live-provider parity, real customer billing outcomes, or release approval. Stable acceptance is covered by automated local contracts and the recurring CI jobs listed in [the coverage ledger](239-COVERAGE.md); this run observed local evidence only, and remote CI is unobserved.

For a read-only walkthrough, sign in, navigate among the documented routes, inspect/reload them, and record observations outside the app. The Phase 239 browser journey checks current route responses, landmarks, identity, narrow layouts (320 CSS px and 200% zoom), and zero non-GET requests after login, including reload of the host entry (`examples/accrue_host/e2e/phase239-integrated-quality.spec.js`). That no-write evidence applies only to this authenticated walkthrough; production Admin and Portal routes can perform their documented actions. Routine human UAT is not required.

The feedback path contains **no mutation, reset, reseed, or proof action**. In particular, do not run `make reset`, `mix ecto.reset`, `mix verify`, or `mix verify.full` as part of preview feedback. If a route or resource is unavailable, keep it explicitly unavailable and safely restart the preview server with the README startup path (`cd examples/accrue_host`, `make proxy` once, then `make up`) or retry after server readiness; do not label unavailable content empty, successful, or verified.

## Evidence and boundaries

### Change summary

Phase 239 connected package-route ownership to recurring evidence, added a mounted Admin/customer Portal/host current-render smoke, reconciled mounted assets/CSP/SRI/copy exports, and confirmed component, adopter-doc, and state-family evidence owners. See the linked plan summaries for measured local results.

- **Local current-render evidence:** [Plan 01 summary](239-01-SUMMARY.md) records the passing Playwright current-render smoke, route/identity/viewport checks, no-write assertion, and attached screenshots. The screenshots support inspection; assertions determine pass/fail.
- **Resource and package evidence:** [Plan 02 summary](239-02-SUMMARY.md) records local Admin/Portal mounted-resource, CSP/SRI, and copy-export checks.
- **Component and state evidence:** [Plan 03 summary](239-03-SUMMARY.md) and [component parity report](239-COMPONENT-PARITY.md) record registry/doc reconciliation and evidence owners for empty, no-match, unavailable, unsupported, denied, pending, error, and long-content states.
- **Feedback shell limits:** no separate feedback overlay or dedicated loading/unavailable screenshot contract was added. Loading-specific feedback controls and unavailable-resource retry behavior are not claimed as independently verified by the Phase 239 walkthrough. At 320px the current Admin, Portal, and host renders are covered; a standalone long-feedback-text fixture is not part of this handoff.
- **Provider and CI boundary:** the preview is Fake-backed and cannot verify external-provider outcomes. CI workflow definitions identify recurring gates, but no remote CI run was observed for this handoff.

## Separate proof path

`examples/accrue_host/config/dev.exs` and Docker Compose use `accrue_host_dev`. Test configuration uses `accrue_host_test`; the full proof/reset script sets `MIX_ENV=test` before dropping, creating, migrating, and reseeding. Therefore `mix verify.full` uses the distinct test database and may run while the dev preview is open; its destructive test-database lifecycle is never part of feedback. Run it separately from the preview walkthrough:

```bash
cd examples/accrue_host
mix verify.full
```

This is a local proof command. A passing local run does not imply that remote CI or a live provider was exercised.
