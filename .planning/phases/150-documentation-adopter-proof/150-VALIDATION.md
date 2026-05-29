---
phase: 150
slug: documentation-adopter-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 150 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `Phoenix.LiveViewTest` (example host) |
| **Config file** | `examples/accrue_host/config/test.exs`; `examples/accrue_host/test/test_helper.exs` |
| **Quick run command** | `cd examples/accrue_host && mix test test/accrue_host_web/live/dunning_banner_live_test.exs` |
| **Full suite command** | `cd examples/accrue_host && mix test` |
| **Doc-presence gate** | `bash scripts/ci/verify_adoption_proof_matrix.sh` (repo root) |
| **Estimated runtime** | ~30 seconds (host suite); doc gate ~2 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command (`mix test .../dunning_banner_live_test.exs`) + `bash scripts/ci/verify_adoption_proof_matrix.sh`
- **After every plan wave:** Run full suite (`cd examples/accrue_host && mix test`)
- **Before `/gsd:verify-work`:** Host `mix test` green + adoption-proof verifier green + `accrue` package `mix test` unaffected
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 150-DEMO-seed | seed | 1 | BAN-04 | — | Seed sets `dunning_campaign_started_at` on a Fake-backed sub; idempotent under `ecto.reset` | integration | `Repo.exists?` for in-active-dunning demo customer (in test setup) | ❌ W0 | ⬜ pending |
| 150-DEMO-banner-on | wiring | 2 | BAN-04 | — | Past-due org renders banner default copy | LiveView | `mix test .../dunning_banner_live_test.exs` | ❌ W0 | ⬜ pending |
| 150-DEMO-banner-off | wiring | 2 | BAN-04 | — | Healthy org does NOT render banner | LiveView | (same file, 2nd test) | ❌ W0 | ⬜ pending |
| 150-DEMO-matrix | matrix | 2 | BAN-04 | — | Adoption-proof matrix row present + pinned | doc-presence | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ verifier exists; needs new needle | ⬜ pending |
| 150-GUIDE | guide | 1 | BAN-03 | — | Guide has `## In-App Banners` section after "Over-email warning" | doc-presence | `grep -q "## In-App Banners" accrue/guides/dunning.md` | ❌ W0 (assertion) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs` — new LiveView test (banner-on + banner-off), covers BAN-04 SC#2.
- [ ] Seed idempotency guard in `examples/accrue_host/priv/repo/seeds.exs` — re-runs cleanly under `mix ecto.reset`.
- [ ] New `require_substring` needle in `scripts/ci/verify_adoption_proof_matrix.sh` matching the BAN-04 row token.
- [ ] Grep-style presence check for `## In-App Banners` in `accrue/guides/dunning.md` (no existing guide-section drift gate — add a lightweight assertion or rely on the doc-presence command above). Verify whether `verify_package_docs.sh` needs a new needle (see MEMORY: verify_package_docs ↔ test coupling).

*Existing infra reused:* `Accrue.Processor.Fake`, `AccountsFixtures`, `ConnCase.log_in_user/3`, `Phoenix.LiveViewTest`, `Subscription.force_status_changeset/2`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Side-by-side reviewer proof (login as healthy vs past-due account) | BAN-04 | UX/visual confirmation of the conditional render in a real browser | `mix ecto.setup` in `examples/accrue_host`, log in as healthy account (no banner) then `past-due@example.com` (banner visible) |
| Copy/paste guide instructions are accurate & complete | BAN-03 | Prose quality + copy-paste fidelity is a human judgement | Follow `guides/dunning.md` "In-App Banners" steps against a clean layout; confirm both component path and core-only DIY path compile |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
