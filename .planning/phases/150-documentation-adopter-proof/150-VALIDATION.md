---
phase: 150
slug: documentation-adopter-proof
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
validated: 2026-05-29
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
| 150-DEMO-seed | seed | 1 | BAN-04 | — | Seed produces healthy + past-due demo accounts and 7 back-dated dunning events idempotently; re-run does not crash (no append-only 45A01) or double-count | integration | `mix test test/seeds_idempotency_test.exs` | ✅ `examples/accrue_host/test/seeds_idempotency_test.exs` | ✅ green |
| 150-DEMO-banner-on | wiring | 2 | BAN-04 | — | Past-due org renders banner default copy | LiveView | `mix test .../dunning_banner_live_test.exs` | ✅ `dunning_banner_live_test.exs` (test 1) | ✅ green |
| 150-DEMO-banner-off | wiring | 2 | BAN-04 | — | Healthy org does NOT render banner | LiveView | (same file, 2nd test) | ✅ `dunning_banner_live_test.exs` (test 2) | ✅ green |
| 150-DEMO-matrix | matrix | 2 | BAN-04 | — | Adoption-proof matrix row present + pinned | doc-presence | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ needles at lines 69-70 | ✅ green |
| 150-GUIDE | guide | 1 | BAN-03 | — | Guide has `## In-App Banners` section after "Over-email warning" | doc-presence | `grep -q "## In-App Banners" accrue/guides/dunning.md` | ✅ `accrue/guides/dunning.md:260` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs` — LiveView test (banner-on + banner-off), covers BAN-04 SC#2. **2/2 green.**
- [x] Seed idempotency guard — repeatable automated test (`examples/accrue_host/test/seeds_idempotency_test.exs`) runs `seeds.exs` twice and asserts no crash + stable 7-event count + unique demo accounts + correct banner anchors. Added during validation (see audit trail). **1/1 green.**
- [x] `require_substring` needles in `scripts/ci/verify_adoption_proof_matrix.sh` matching the BAN-04 row tokens — lines 69-70 (`dunning_banner_live_test.exs`, `AccrueAdmin.Components.DunningBanner`). Verifier exits 0.
- [x] Grep-style presence check for `## In-App Banners` in `accrue/guides/dunning.md` — present at line 260; `grep -q` passes. `verify_package_docs.sh` needed no new needle (the four existing dunning.md needles live in the untouched Chimeway section — confirmed in 150-01-SUMMARY).

*Existing infra reused:* `Accrue.Processor.Fake`, `AccountsFixtures`, `ConnCase.log_in_user/3`, `Phoenix.LiveViewTest`, `Subscription.force_status_changeset/2`, `AccrueHost.DataCase` (sandbox).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Side-by-side reviewer proof (login as healthy vs past-due account) | BAN-04 | UX/visual confirmation of the conditional render in a real browser | `mix ecto.setup` in `examples/accrue_host`, log in as healthy account (no banner) then `past-due@example.com` (banner visible) |
| Copy/paste guide instructions are accurate & complete | BAN-03 | Prose quality + copy-paste fidelity is a human judgement | Follow `guides/dunning.md` "In-App Banners" steps against a clean layout; confirm both component path and core-only DIY path compile |

---

## Validation Audit 2026-05-29

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap:** 150-DEMO-seed had no suite-integrated automated test — seed idempotency (the phase's main blocker: the append-only `accrue_events` 45A01 violation fixed in `f26fab9b`) was verified only by manually running `mix ecto.reset` once. The other four tasks were already COVERED and re-confirmed green during this audit.

**Resolution:** `gsd-nyquist-auditor` wrote `examples/accrue_host/test/seeds_idempotency_test.exs` — `Code.eval_file` runs `seeds.exs` twice in one sandboxed `DataCase` test, asserting (a) the second eval does not raise (no 45A01, no unique-constraint crash), (b) stable 7-event `seed-dunning-%` count, (c) unique `healthy@`/`past-due@` demo users, (d) correct banner anchors (past-due has `dunning_campaign_started_at`, healthy does not). 1/1 green; full host suite 186/186, no regression.

> **Load-bearing caveat (from the auditor, recorded for maintainers):** under the **test** env `Accrue.Clock.utc_now/0` returns the Fake clock epoch at *second* precision, which `Repo.insert_all` rejects against the `:utc_datetime_usec` `inserted_at` column. This crash does **not** occur on the path BAN-04 covers — `mix ecto.reset` runs the seed in **dev** env (real `DateTime.utc_now/0`, usec precision). To exercise the real reset path without modifying the seed/impl, the test's `setup` flips `:accrue, :env` to `:dev` for its duration and restores it on `on_exit`. If this coupling is later judged undesirable, the seed could round-trip `Accrue.Clock.utc_now/0` to usec precision — an implementation change out of scope for this validation gap.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (host suite ~2s; doc gate ~2s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-29 — all 5 tasks have passing automated verification; both requirements (BAN-03, BAN-04) automated-covered. Manual-only items below are supplementary human (UX/prose) checks, not sole coverage.
