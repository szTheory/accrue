---
phase: 150-documentation-adopter-proof
plan: 02
subsystem: example-host
tags: [dunning, banner, adopter-proof, example-host, seeds, ban-04]
requires:
  - "Accrue.Dunning.requires_attention?/1 (shipped Phase 149)"
  - "AccrueAdmin.Components.DunningBanner.dunning_banner/1 (shipped Phase 149)"
  - "AccrueHost.Billing.billing_state_for_scope/1 (host facade, read-only customer lookup)"
provides:
  - "BAN-04 in-app dunning banner adopter proof in examples/accrue_host (banner-on + banner-off)"
  - "Idempotent healthy@example.com + past-due@example.com demo accounts"
  - "Adoption-proof matrix BAN-04 row + verifier needle"
affects:
  - "examples/accrue_host/lib/accrue_host_web/components/layouts.ex (global banner mount)"
tech-stack:
  added: []
  patterns:
    - "Read-only scope→Customer resolution for render-path components (no get-or-create side effect)"
    - "Conditional banner mount guarded on a resolved Customer struct (component requires non-nil customer)"
key-files:
  created:
    - "examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs"
  modified:
    - "examples/accrue_host/lib/accrue_host_web/components/layouts.ex"
    - "examples/accrue_host/priv/repo/seeds.exs"
    - "examples/accrue_host/docs/adoption-proof-matrix.md"
    - "scripts/ci/verify_adoption_proof_matrix.sh"
decisions:
  - "Resolver uses read-only billing_state_for_scope/1 instead of get-or-create customer_for_scope/1 (T-150-05/Pitfall 1)"
  - "Adoption-proof row added to the HOST matrix, not .planning/processor-support-matrix.md (RESEARCH Assumption A1)"
metrics:
  duration: ~7m
  completed: 2026-05-29
  tasks: 3
  files: 5
---

# Phase 150 Plan 02: In-App Dunning Banner Adopter Proof (BAN-04) Summary

Proved the Phase 149 dunning banner end-to-end in `examples/accrue_host`: the default `AccrueAdmin.Components.DunningBanner` is mounted zero-config at the top of `Layouts.app` and renders for a past-due/dunning org while staying absent for a healthy org, with a side-by-side seeded demo account pair, a banner-on/banner-off LiveView test, and a pinned adoption-proof matrix row + verifier needle.

## What Was Built

- **`dunning_banner_live_test.exs`** — two LiveView tests: banner-ON (past-due org with a written `dunning_campaign_started_at` anchor asserts the verbatim "Action Required" copy + `.accrue-default-dunning-banner` class) and banner-OFF (healthy subscribed org refutes the banner). Hermetic via Fake reset + `cleanup_fake_billing_rows!/0`.
- **`Layouts.app` mount** — the banner is the first child of `<main>` (top, on every authenticated page), zero-config (no inner_block), guarded by a resolved Customer struct. A private `dunning_customer/1` resolver returns only an existing `%Accrue.Billing.Customer{}` or `nil`.
- **Seeds** — idempotent `healthy@example.com` (banner-off) and `past-due@example.com` (banner-on) demo accounts under `mix ecto.reset`, both subscribed via the Fake processor; past-due flipped by writing the single dunning-anchor column via `force_status_changeset/2`. Documented demo credentials (`accrue-demo-password`) so a reviewer can log in side-by-side. Existing dunning-events analytics blocks preserved.
- **Adoption-proof matrix + verifier** — BAN-04 row in the "Blocking: Fake-backed host + browser" table; matching `require_substring` needles pinning `dunning_banner_live_test.exs` and `AccrueAdmin.Components.DunningBanner`.

## Verification

- `mix test test/accrue_host_web/live/dunning_banner_live_test.exs` — 2/2 pass (banner-on + banner-off).
- `mix test` (full host suite) — **185/185 pass**.
- `mix ecto.reset` then re-running `priv/repo/seeds.exs` — both exit 0 (idempotent; demo accounts guarded by `Repo.get_by`).
- `bash scripts/ci/verify_adoption_proof_matrix.sh` — OK (all needles, old + new, satisfied).
- No accrue/accrue_admin source touched — those packages are unaffected.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Banner crashed on nil customer; resolution created a Customer on render**
- **Found during:** Task 2 verification (full host suite — 28 failures, then 1).
- **Issue (a):** The plan's `key_links` directed the resolver to reuse `AccrueHost.Billing.customer_for_scope/1`. On login/registration/settings pages (no active org or no existing customer) that path returned `nil`, which was passed to the banner; `Accrue.Dunning.requires_attention?/1` is **not** nil-safe (its catch-all clause calls `Accrue.Billing.customer(nil)` → `FunctionClauseError`). 28 user_live tests crashed.
- **Issue (b):** `customer_for_scope/1` → `customer_for/1` → `Accrue.Billing.customer/1` is **get-or-create**. Mounting the banner on a plain billing-page render created a Customer row, breaking `org_billing_live_test.exs` "members can review billing state but cannot mutate it" (customer count 1 → 2). This is exactly threat **T-150-05 / Pitfall 1**.
- **Fix:** (a) Conditionally render the banner only when `dunning_customer/1` returns a non-nil Customer (the shipped component requires a customer and was not modified). (b) Resolve via the **read-only** `AccrueHost.Billing.billing_state_for_scope/1` (which uses a pure `Repo.one` lookup, returning the existing Customer or nil) instead of the get-or-create `customer_for_scope/1`.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/components/layouts.ex`
- **Commit:** `bfed965a`
- **Constraint honored:** No change to the Phase 149 component (`accrue_admin`) or core helper (`accrue/lib/accrue/dunning.ex`).

### Documented Divergence (per Task 3 instruction)

- CONTEXT.md's D-discretion literally names `.planning/processor-support-matrix.md`, but the adopter-proof row was added to the **host** matrix `examples/accrue_host/docs/adoption-proof-matrix.md` per Phase 130/132 precedent, the live drift gate (`verify_adoption_proof_matrix.sh`), and RESEARCH Open Question 1 / Assumption A1. The processor-support matrix is a per-provider capability matrix, not a per-feature adopter-proof matrix.

## Authentication Gates

None.

## Known Stubs

None — both demo accounts are fully wired (subscribed via Fake, past-due flipped via a real anchor write), and the banner renders from live billing state.

## TDD Gate Compliance

RED (`test(150-02)` commit `6ea5d826`, banner-ON failing for the documented reason) → GREEN (`feat(150-02)` commit `b22b2287`) → integration fix (`fix(150-02)` commit `bfed965a`). Gate sequence satisfied.

## Self-Check: PASSED

- FOUND: examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs
- FOUND: commit 6ea5d826 (test), b22b2287 (feat), af85ea8d (docs), bfed965a (fix)
- Matrix verifier OK; full host suite 185/185.
