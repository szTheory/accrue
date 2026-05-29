---
phase: 150-documentation-adopter-proof
verified: 2026-05-29T10:20:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "The example host seed produces past-due + healthy demo accounts AND back-dated dunning events idempotently, and `mix ecto.reset` succeeds (exit 0) without an append-only violation."
  gaps_remaining: []
  regressions: []
---

# Phase 150: Documentation & Adopter Proof Verification Report

**Phase Goal:** Document the new banner capability and prove it works in the example host app.
**Verified:** 2026-05-29T10:20:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (commit f26fab9b)

## Re-Verification Summary

The prior verification (2026-05-28) found exactly ONE blocker: the CR-01 seed fix
(commit 7fde9cac) back-dated dunning events via `Repo.update_all` on the append-only
`accrue_events` table, which the `BEFORE UPDATE OR DELETE` immutability trigger rejected
(SQLSTATE 45A01), crashing `mix ecto.reset`.

**Gap closed (commit f26fab9b).** `seeds.exs` now sets `inserted_at` at INSERT time via
`Repo.insert_all(Accrue.Events.Event, ...)`. INSERT is permitted by the trigger (only
UPDATE/DELETE are blocked, migration `20260411000001_create_accrue_events.exs:58`). The fix
was confirmed by **actually running** `mix ecto.reset` (exit 0) and re-running the seed
(exit 0, no duplicate events). All five previously-passing must-haves regression-checked
and remain intact — no regressions.

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | `guides/dunning.md` has a `## In-App Banners` section, correctly placed | ✓ VERIFIED | Section at dunning.md:260; `requires_attention?/1`, `DunningBanner`, "Action Required" needles all present. (regression — unchanged) |
| 2 | Section documents accrue_admin component path (default AND inner_block CTA) | ✓ VERIFIED | `AccrueAdmin.Components.DunningBanner.dunning_banner customer={@customer}` (dunning.md:289); verbatim default copy (dunning.md:295); inner_block CTA block (dunning.md:306-314). (regression — unchanged) |
| 3 | Section documents core-only DIY path via `Accrue.Dunning.requires_attention?/1` with dependency boundary | ✓ VERIFIED | DIY `<%= if Accrue.Dunning.requires_attention?(@customer) %>` (dunning.md:347); dependency-boundary blockquote (dunning.md:274). (regression — unchanged) |
| 4 | Authenticated past-due/dunning org sees the default banner; healthy org sees none | ✓ VERIFIED | `dunning_banner_live_test.exs` re-run: **2 tests, 0 failures** (--seed 0). (regression — unchanged) |
| 5 | Customer resolution reuses host facade and never passes a raw billable (Pitfall 1) | ✓ VERIFIED | `dunning_customer/1` → read-only `AccrueHost.Billing.billing_state_for_scope/1`. (regression — unchanged) |
| 6 | Seed produces past-due + healthy demo accounts AND back-dated dunning events idempotently; `mix ecto.reset` exits 0 without append-only violation | ✓ VERIFIED | **NOW PASSES.** Ran `mix ecto.reset` → exit 0; all 7 dunning events INSERTed with back-dated `inserted_at` (2026-05-24/05-04/03-30), no 45A01. Re-ran seeds → exit 0, seed-dunning event count stable at 7 (idempotent no-op), both `healthy@`/`past-due@` users present. Conflict target `(idempotency_key) WHERE idempotency_key IS NOT NULL` matches `Accrue.Events.insert_opts/1` (events.ex:148-149). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `accrue/guides/dunning.md` | In-App Banners docs (BAN-03) | ✓ VERIFIED | Substantive section, both paths, cross-link, all needles present. |
| `examples/accrue_host/test/accrue_host_web/live/dunning_banner_live_test.exs` | Banner-on/off proof | ✓ VERIFIED | 2 tests pass (--seed 0). |
| `examples/accrue_host/lib/accrue_host_web/components/layouts.ex` | Banner mount + safe resolution | ✓ VERIFIED | Banner first child of `<main>`, guarded by resolved Customer via read-only lookup. |
| `examples/accrue_host/priv/repo/seeds.exs` | Idempotent demo accounts + back-dated dunning events | ✓ VERIFIED | `record_at/3` uses `Repo.insert_all(Accrue.Events.Event, ...)` with `inserted_at` at insert time + matching `on_conflict`/conflict_target. `mix ecto.reset` exits 0; re-run idempotent. |
| `examples/accrue_host/docs/adoption-proof-matrix.md` | BAN-04 row | ✓ VERIFIED | Row references `dunning_banner_live_test.exs`; WR-01 route fix present. |
| `scripts/ci/verify_adoption_proof_matrix.sh` | Drift-gate needle | ✓ VERIFIED | `bash scripts/ci/verify_adoption_proof_matrix.sh` exits 0. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| layouts.ex | AccrueHost.Billing.billing_state_for_scope/1 | dunning_customer/1 resolver | ✓ WIRED | Read-only resolution. |
| layouts.ex | AccrueAdmin.Components.DunningBanner.dunning_banner/1 | guarded mount at top of main | ✓ WIRED | Conditional render. |
| seeds.exs | accrue_events (back-dated inserted_at) | Repo.insert_all(Accrue.Events.Event) | ✓ WIRED | INSERT-time timestamp; trigger-safe; idempotent via partial-unique conflict target. |
| seeds.exs | accrue_subscriptions.dunning_campaign_started_at | force_status_changeset/2 write | ✓ WIRED | Past-due subscription created with dunning anchor. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Seed completion (the gap) | `mix ecto.reset` (dev) | exit 0; 7 dunning events INSERTed, no 45A01 | ✓ PASS |
| Seed idempotency | `mix run priv/repo/seeds.exs` (re-run) | exit 0; seed-dunning event count stable at 7 | ✓ PASS |
| Demo accounts exist post-seed | `mix run -e` DB query | healthy@ + past-due@ users present | ✓ PASS |
| Banner-on/off LiveView proof | `mix test .../dunning_banner_live_test.exs --seed 0` | 2 tests, 0 failures | ✓ PASS |
| Adoption-proof matrix gate | `bash scripts/ci/verify_adoption_proof_matrix.sh` | OK (exit 0) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| BAN-03 | 150-01 | Integration Documentation (guides/dunning.md In-App Banners) | ✓ SATISFIED | Truths 1-3; substantive guide section with both paths + cross-link. |
| BAN-04 | 150-02 | Adopter-proof matrix row + example-host wiring | ✓ SATISFIED | Truths 4-6: banner wiring + test + matrix row + a now-working `mix ecto.reset` adopter onboarding path that seeds both demo accounts and back-dated dunning analytics fixtures. |

No orphaned requirements: both BAN-03 and BAN-04 are claimed by plans and traced in REQUIREMENTS.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | — | — | None. The prior blocker (`Repo.update_all` on append-only `accrue_events`) is removed in commit f26fab9b. No debt markers (TBD/FIXME/XXX) in any phase-modified file. |

### Human Verification Required

None — the previously-failing condition was fully observable programmatically and has been
confirmed PASS by direct execution (`mix ecto.reset` exit 0).

### Gaps Summary

No gaps. All six must-haves are verified. The single prior blocker — the append-only ledger
violation in the seed back-dating path — is closed in commit f26fab9b and confirmed by
actually running `mix ecto.reset` (exit 0) and a re-run for idempotency. SC#1 (BAN-03,
guide documentation) and SC#2 (BAN-04, example-host adopter proof) are both fully achieved.

---

_Verified: 2026-05-29T10:20:00Z_
_Verifier: Claude (gsd-verifier)_
