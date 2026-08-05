---
created: 2026-08-05T18:28:09.164Z
completed: 2026-08-05T20:40:00Z
title: Automate Apple delivery smoke test
area: tooling
status: completed
files:
  - .github/workflows/apple-notification-delivery-smoke.yml
  - scripts/ci/apple_notification_delivery_smoke.mjs
  - examples/accrue_host/README.md
---

## Outcome

Implemented an advisory scheduled/manual GitHub Actions lane that generates an
ES256 App Store Server API JWT, requests Apple’s `TEST` notification, polls its
delivery status, and emits only the result class and attempt count. The protected
`apple-notification-smoke` environment owns the required App Store Connect secrets.
The workflow never runs on pull requests; deterministic credential-free host
verification remains merge authority.

## Operator setup

Use a dedicated non-customer App Store Connect app and configure its notification
URL for the selected production or sandbox endpoint. Populate the protected
environment secrets documented in `examples/accrue_host/README.md` before manually
dispatching the workflow or relying on its weekly schedule.
