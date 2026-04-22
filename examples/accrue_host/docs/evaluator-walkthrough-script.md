# Evaluator walkthrough script (screen recording)

Use this as a **checklist** when recording a short demo for stakeholders. It mirrors the same Fake-backed paths CI exercises; no Stripe keys required.

**Prep (once per machine):** Follow `examples/accrue_host/README.md` setup through `mix setup` / DB migrate as documented.

## A. Clone and trust gate (optional cold open, ~60s)

1. Show repository root and `examples/accrue_host`.
2. State that **pull requests** run `host-integration`: shift-left `verify_verify01_readme_contract.sh` and `verify_adoption_proof_matrix.sh`, then `accrue_host_uat.sh` → `mix verify.full`, then the full **`npm run e2e`** suite on CI (mounted-admin axe: `e2e/verify01-admin-a11y.spec.js`).

## B. Local deterministic proof (~3–5 min)

1. `cd examples/accrue_host`
2. Run `mix verify` (bounded slice) — mention it includes **user-billable** facade tests and **org** billing tests.
3. Optionally run full `mix verify.full` if you want the complete maintainer story (longer).

## C. Browser story — org billing + admin (~5–8 min)

1. `npm ci` then `npm run e2e:install` (if not already done).
2. Run the VERIFY-01 Playwright entrypoint from the README (or `npm run e2e:visuals` for screenshots only).
3. Show: log in → **Go to billing** → tax location → start/cancel org subscription path as documented.
4. Open mounted **admin** path used in specs (see `verify01-admin-mounted.spec.js` / README) and show subscription + webhook inspection briefly.

## D. Artifacts

1. If recording CI output: open GitHub Actions run → download **`accrue-host-phase15-screenshots`** when available.
2. Locally after `e2e:visuals`, show `test-results/phase15-trust/**/*.png`.

## E. What to say about “real Stripe”

- **Default story:** Fake processor proves Phoenix wiring, webhooks, DB reducers, admin LiveView — what most regressions break.
- **Stripe test mode:** Maintainer/advisory lane (`mix test.live`, scheduled `live-stripe` job) for API drift — not required for every contributor.

Keep recordings free of real API keys, webhook secrets, or customer PII.
