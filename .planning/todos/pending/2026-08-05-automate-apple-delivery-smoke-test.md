---
created: 2026-08-05T18:28:09.164Z
title: Automate Apple delivery smoke test
area: tooling
severity: minor
files:
  - .github/workflows/ci.yml
  - examples/accrue_host/README.md
  - .planning/phases/221-close-gap-reference-host-apple-notification-ingress/221-VERIFICATION.md
---

## Problem

The reference host has deterministic, merge-blocking router/PostgreSQL proof, but no repeatable check that Apple's external notification service can reach a configured public endpoint. The live check is currently deferred because no dedicated App Store Connect test app or configured staging endpoint is available.

## Solution

Use a dedicated non-customer App Store Connect app record with its notification URL pointed at the existing stable staging host. Add a scheduled and manually dispatched GitHub Actions lane that requests Apple’s TEST notification, polls delivery status, and stores only privacy-safe outcome metadata. Keep it advisory on pull requests; deterministic `mix verify` remains merge authority. Store Apple API credentials and staging configuration as protected CI secrets.
