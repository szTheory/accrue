---
phase: 126-admin-surface-docs-jtbd-spine
verified: 2026-05-23T23:21:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  # No previous VERIFICATION.md existed — this is initial verification.
notes:
  - "SC#3 literal ROADMAP wording names 'First Hour' as a spine that should reference the entitlements guide. The phase deliberately left First Hour's verifier-pinned numbered spine UNTOUCHED (D-12, chosen in 126-DISCUSSION-LOG Option B over Option A which would 'bloat the verifier-pinned First Hour spine'). Discoverability is satisfied via README 'Start here' + quickstart focused-guides pointers. This is an approved planning-level deviation, explicitly restated in the phase goal handed to verification ('First Hour spine untouched'). Marked VERIFIED with deviation note; optional override below for audit clarity."
overrides:
  # Optional — not required for pass. Add to make the SC#3/First-Hour deviation explicitly auditable.
  - must_have: "The JTBD docs flip entitlements and the First Hour + README Start here spine reference the entitlements guide"
    reason: "D-12 deliberately leaves First Hour's verifier-pinned numbered spine intact to avoid bloating it with an integration (entitlements is a derivation over billing, not an install step). Discoverability satisfied via README 'Start here' + quickstart pointers; honest JTBD flip is complete in both public and internal docs."
    accepted_by: "orchestrator (execute-phase) — D-12 deliberate decision; First Hour spine intentionally untouched, discoverability via README + quickstart"
    accepted_at: "2026-05-23"
---

# Phase 126: Admin Surface + Docs / JTBD Spine Verification Report

**Phase Goal:** An operator can see a customer's resolved entitlements in the admin UI, and the entitlements story is documented end-to-end with the JTBD gap closed and the doc-contract verifiers green.
**Verified:** 2026-05-23T23:21:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|-----------------------------------|--------|----------|
| 1 | An operator can view a customer's currently-active entitlements/features in `accrue_admin` (read-only), surfacing unmapped-plan drift by eye. | ✓ VERIFIED | `Accrue.Entitlements.Admin.resolve_for_customer/1` (admin.ex:47) returns `{resolved, unmapped}`; `CustomerLive` `@tabs` includes `entitlements` (:32), case clause renders resolved plans/features/quantities/grace then a "Plan mapping" drift card with the "⚠ Unmapped plan" amber badge (customer_live.ex:361-441). Seam test 9/0, LiveView test 4/0 (both run, GREEN). |
| 2 | `guides/entitlements.md` documents the full story: gate API, Plug guard, LiveView guard, provider matrix, and lifecycle truth table. | ✓ VERIFIED | 266-line guide; needles present: `entitled?`, `Accrue.Plug.RequireEntitlement`, `[:accrue, :entitlements, :check]`, `Accrue.Live.Entitlements`, `Accrue.Processor.Capabilities`, `lifecycle_semantics.md#lifecycle--entitlement-truth-table`. Fail-closed opener at :27. Builds to `doc/entitlements.html` (35294 bytes). |
| 3 | The JTBD docs flip entitlements ⛔→✅, and the First Hour + README "Start here" spine reference the entitlements guide. | ✓ VERIFIED (with deviation) | Public `jobs_to_be_done.md`: new `## Gate access on what they paid for` section (:156), `entitlements ✅ shipped` marker (:398), flip-guard phrase removed (ABSENT, confirmed). Internal `JTBD-FRONTIER.md`: "6 of 6 shipped" (:21/:23/:151). README pointer (:19), quickstart pointer (:30). **Deviation:** First Hour spine deliberately untouched per D-12 (see notes/override). |
| 4 | Package-doc verifiers stay green after the docs and admin changes land. | ✓ VERIFIED | `bash scripts/ci/verify_package_docs.sh` → **exit 0** (run by verifier). `mix test package_docs_verifier_test.exs` → **8 tests, 0 failures** (run by verifier). `mix docs` → exit 0, entitlements.html present (run by verifier). Both PROJECT.md needles present: `gateway subscription core` + `Accrue.Billing.subscribe/3`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue/lib/accrue/entitlements/admin.ex` | `resolve_for_customer/1` → `{resolved, unmapped}` | ✓ VERIFIED | 50 lines, delegates to both LocalMap seam fns; moduledoc documents not-a-gate-API / one-way / LocalMap-hardcode posture. Wired (consumed by customer_live.ex:547). |
| `accrue/lib/accrue/entitlements/resolver/local_map.ex` | Two `@doc false` delegations | ✓ VERIFIED | `fold_for_customer/1` (:100) literally calls `fold_active/1` (single fold, zero copy); `unmapped_entitling_price_ids/1` (:114) reuses `catalog()`/`active_items()`, excludes `:expired` (WR-01 fix at :119), both `@doc false`. |
| `accrue/test/accrue/entitlements/admin_test.exs` | Wave 0 unit test | ✓ VERIFIED | 9 tests incl. mapped/unmapped/empty/grace + `:raise` (WR-03). Run: 9 tests, 0 failures. |
| `accrue_admin/lib/accrue_admin/copy/entitlements.ex` | Copy submodule | ✓ VERIFIED | 13 `@doc false` 0-arity fns incl. `unmapped_badge` ("⚠ Unmapped plan") and `error_copy` (states "no access is granted on error"). |
| `accrue_admin/lib/accrue_admin/live/customer_live.ex` | entitlements tab clause | ✓ VERIFIED | `@tabs` entry, StatusBadge alias, guarded `entitlements_view/1` (try/rescue → `{:ok,...}`/`:error`), `@entitlements_view` assign computed in `handle_params` (render-pure, WR-04), error card rendered on `:error` (CR-01/IN-01). |
| `accrue_admin/test/accrue_admin/live/entitlements_live_test.exs` | Wave 0 LiveView test | ✓ VERIFIED | 4 tests incl. resolved/unmapped/empty + `:raise` error-copy render (no crash). Run: 4 tests, 0 failures. |
| `accrue/guides/entitlements.md` | authoritative guide | ✓ VERIFIED | 266 lines, all needles, fail-closed-first, summarize-and-link. |
| `accrue/guides/jobs_to_be_done.md` | JTBD public flip | ✓ VERIFIED | Gate section + shipped marker present, flip-guard phrase removed, tracked in git. |
| `.planning/research/JTBD-FRONTIER.md` | internal flip | ✓ VERIFIED | "6 of 6 shipped" across TL;DR/DoD/delta. |
| `accrue/README.md` + `accrue/guides/quickstart.md` | spine pointers | ✓ VERIFIED | Both pointers present byte-matching verifier needles. |
| `.planning/PROJECT.md` | parity needle | ✓ VERIFIED | `gateway subscription core` (D-13) + `Accrue.Billing.subscribe/3` (orchestrator 5635d77) both present. |
| `scripts/ci/verify_package_docs.sh` | 7 spine needles | ✓ VERIFIED | Labeled "Entitlements spine (Phase 126, ENT-12)" block (:111-124), 7 needles. |
| `accrue/test/accrue/docs/package_docs_verifier_test.exs` | 2 seed fixtures | ✓ VERIFIED | `copy_fixture!` for entitlements.md (:262) + jobs_to_be_done.md (:264). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| admin.ex | local_map.ex | `LocalMap.fold_for_customer/1` + `unmapped_entitling_price_ids/1` | ✓ WIRED | admin.ex:48 calls both. |
| local_map.ex `fold_for_customer/1` | `fold_active/1` | thin delegation | ✓ WIRED | :100 body is literally `fold_active(customer)` (single fold). |
| customer_live.ex | `Accrue.Entitlements.Admin.resolve_for_customer/1` | `entitlements_view/1` once | ✓ WIRED | :547, guarded, called once via `assign_entitlements_view` in `handle_params` (:76). |
| copy.ex | `AccrueAdmin.Copy.Entitlements` | 13 defdelegates | ✓ WIRED | 13 `defdelegate entitlements_*`. |
| export task @allowlist | Copy `entitlements_*` fns | allowlist entries | ✓ WIRED | 13 entries. |
| README "Start here" | entitlements.md | markdown link | ✓ WIRED | :19. |
| JTBD Gate section | entitlements.md | deep-dive link | ✓ WIRED | `[Entitlements](entitlements.md)`. |
| verifier needles | doc files | require_fixed/require_absent_regex | ✓ WIRED | 7 needles, all byte-match on-disk docs (verifier exits 0). |
| One-way dependency | (negative) | no reverse ref | ✓ VERIFIED | No `Entitlements.Admin` ref under billing/ or resolver/. |
| Public gate API | (negative) | `entitlements.ex` unchanged | ✓ VERIFIED | Still 4 public defs; no new gate/diagnostic API. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| customer_live.ex entitlements tab | `@entitlements_view` | `Accrue.Entitlements.Admin.resolve_for_customer/1` → `LocalMap.fold_active/1` + `active_items/1` (Repo.all over `accrue_subscriptions`/`accrue_subscription_items`) | ✓ Yes (real DB queries; LiveView test seeds subs and asserts rendered features/badge/empty) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Seam resolves mapped/unmapped/empty/grace/:raise | `mix test admin_test.exs --seed 0` | 9 tests, 0 failures | ✓ PASS |
| Tab renders 3 states + :raise error copy (no crash) | `mix test entitlements_live_test.exs --seed 0` | 4 tests, 0 failures | ✓ PASS |
| Admin suite regression | `cd accrue_admin && mix test` | 132 tests, 0 failures | ✓ PASS |
| Core suite regression (deterministic) | `mix test --seed 0` | 49 properties, 1465 tests, 0 failures | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| Package-doc verifier (phase gate #1) | `bash scripts/ci/verify_package_docs.sh` | exit 0 — "package docs verified for accrue 1.1.2, accrue_admin 1.1.2, and accrue_portal 1.1.2" | PASS |
| Doc verifier test (phase gate #2) | `mix test package_docs_verifier_test.exs --seed 0` | 8 tests, 0 failures | PASS |
| Docs build (phase gate #3) | `mix docs` | exit 0; `doc/entitlements.html` (35294 bytes) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| ENT-11 | 126-01, 126-02 | Operator can view a customer's currently-active entitlements in accrue_admin (read-only) | ✓ SATISFIED | Read seam + LiveView tab; SC#1 truth verified; tests GREEN. |
| ENT-12 | 126-03, 126-04 | entitlements.md documents full story; JTBD flip ⛔→✅; README/spine reference it; verifiers stay green | ✓ SATISFIED | SC#2/#3/#4 truths verified; phase gate GREEN. |

No orphaned requirements: REQUIREMENTS.md maps exactly ENT-11 + ENT-12 to Phase 126; both are claimed by phase plans. No unaccounted IDs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No unreferenced TBD/FIXME/XXX in any phase-modified source file | — | Clean — completion is auditable. |

Deferred review items IN-02 (export_copy_strings silent allowlist drop) and IN-03 (StatusBadge acronym humanize) are pre-existing, cosmetic, and not Phase-126 regressions (per 126-REVIEW.md). They do not affect goal achievement and are correctly deferred.

### Human Verification Required

None. The render states (resolved, unmapped badge, empty, fail-closed error under `:raise`) are all exercised by the automated LiveView test (4/0) and asserted on rendered HTML, so visual behavior is machine-covered. The one documented deviation (First Hour spine) is a deliberate, planning-approved scope decision, not an unverifiable behavior.

### Gaps Summary

No gaps. All four ROADMAP success criteria are observably true in the codebase, both requirements (ENT-11, ENT-12) are satisfied, the code-review BLOCKER (CR-01 render crash) and all four warnings (WR-01..04) are genuinely fixed in code with backing tests, and the doc-contract phase gate is GREEN (verifier exit 0, 8/0 verifier test, mix docs builds entitlements.html).

**One documented deviation, not a gap:** ROADMAP SC#3 literally names "First Hour" among the spines that should reference the entitlements guide, but the phase deliberately left First Hour's verifier-pinned numbered spine untouched (D-12) and instead added pointers to README "Start here" and quickstart. This was an explicit planning decision (126-DISCUSSION-LOG Option B), is restated in the phase goal handed to verification, and preserves the discoverability intent of SC#3. An optional override is recorded in the frontmatter for audit clarity — accept it if you agree First Hour should remain untouched.

---

_Verified: 2026-05-23T23:21:00Z_
_Verifier: Claude (gsd-verifier)_
