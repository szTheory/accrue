---
phase: 126-admin-surface-docs-jtbd-spine
plan: 04
subsystem: ci-docs-contract
tags: [entitlements, docs, verifier, ssot, phase-gate]
requirements: [ENT-12]
dependency-graph:
  requires:
    - "Plan 03 doc files: guides/entitlements.md, jobs_to_be_done.md (committed/tracked), README + quickstart spine pointers, PROJECT.md 'gateway subscription core' + 'Accrue.Billing.subscribe/3' parity"
    - "Orchestrator fix 5635d77 (restored Accrue.Billing.subscribe/3 to PROJECT.md — the second masked needle)"
  provides:
    - "verify_package_docs.sh entitlements-spine needle block (D-14): README link, 3 entitlements.md needles, JTBD shipped marker + scoped flip-guard, quickstart pointer"
    - "package_docs_verifier_test.exs seed entries for entitlements.md + jobs_to_be_done.md (D-15)"
    - "GREEN 3-command phase gate closing ENT-12 SC#4"
  affects:
    - "Phase 126 complete — last plan; doc contract is merge-blocking GREEN"
tech-stack:
  added: []
  patterns:
    - "SSOT-mirror discipline: doc labels (Plan 03) + their verifier needles (this plan) ship in the same phase"
    - "Seed-co-update invariant: every file a new needle references must be in seed_tmp_dir!'s copy list, else negative-drift fixtures fail 'No such file'"
    - "grep -F literal needles byte-match the authored doc string (brackets/parens/✅ glyph are literal); flip-guard scoped to the unique removed scope-prose phrase (Pitfall 4)"
key-files:
  created:
    - .planning/phases/126-admin-surface-docs-jtbd-spine/126-04-SUMMARY.md
  modified:
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
decisions:
  - "Needle 5a pinned byte-for-byte as 'entitlements ✅ shipped' (Plan 03's recorded marker; the U+2705 ✅ glyph is matched literally by grep -F)."
  - "No 'gateway subscription core' line added — it already exists at verify_package_docs.sh:220 and Plan 03's PROJECT.md edit (plus orchestrator's subscribe/3 restore in 5635d77) satisfies it."
  - "Flip-guard targets the scoped phrase 'on the table** is **entitlements' (not 'headline gap'), so it cannot be defeated by the historical Update log; Plan 03 already removed the phrase, so the guard does not fire."
  - "Excluded by design (D-14): deny-redirect prose, quota numbers, per-provider matrix wording, gate-fn names replicated across README/first_hour/host."
metrics:
  duration: ~6min
  tasks: 2
  files: 2
  completed: 2026-05-23
---

# Phase 126 Plan 04: Doc-Contract Phase Gate Summary

Closed ENT-12 SC#4 by extending `scripts/ci/verify_package_docs.sh` with the tight entitlements-spine needle set (D-14), co-updating the Elixir verifier-test seed list so every needle-referenced file is seeded (D-15), and proving the whole doc contract GREEN via the 3-command phase gate. This is the last plan of Phase 126.

## Prerequisite-state note (resolved before Task 1)

The plan's mental model assumed Plan 03's D-13 fix alone made the verifier exit 0. In fact the v1.39 milestone-start rewrite had dropped TWO PROJECT.md needles on one line — `gateway subscription core` (Plan 03 restored it) AND `Accrue.Billing.subscribe/3` (masked because the script reports only the first missing needle). The orchestrator already restored `Accrue.Billing.subscribe/3` in commit `5635d77` during the Wave 1 post-merge gate. So the baseline was already GREEN before this plan touched anything (verified: `bash scripts/ci/verify_package_docs.sh` exit 0, verifier test 8/0). No PROJECT.md edit was made or needed here.

## What shipped

### Task 1 — Entitlements-spine needles in the bash verifier (commit 94a305a)
Added a labeled `# Entitlements spine (Phase 126, ENT-12)` block after the README/guide `require_fixed` block, with seven needles, each re-read from the on-disk Plan 03 docs so the `grep -F` literals byte-match:
- `require_fixed accrue/README.md '[Entitlements](guides/entitlements.md)'` (README "Start here" bullet, line 19)
- `require_fixed accrue/guides/entitlements.md 'entitled?'` (matches `entitled?/2` substring; guide lines 15/27/218)
- `require_fixed accrue/guides/entitlements.md 'Accrue.Plug.RequireEntitlement'` (guide line 102)
- `require_fixed accrue/guides/entitlements.md '[:accrue, :entitlements, :check]'` (guide line 232)
- `require_fixed accrue/guides/jobs_to_be_done.md 'entitlements ✅ shipped'` (the dated 2026-05-23 Update-log line 398; ✅ = U+2705 matched literally)
- `require_absent_regex accrue/guides/jobs_to_be_done.md 'on the table\*\* is \*\*entitlements'` (scoped flip-guard; phrase confirmed absent)
- `require_fixed accrue/guides/quickstart.md '[Entitlements](entitlements.md)'` (quickstart focused-guides bullet, line 30)

No `gateway subscription core` line was added (already at :220). The verifier still exits 0 against the current docs.

### Task 2 — Seed co-update + 3-command phase gate (commit 1b8b1ca)
Added exactly two `copy_fixture!` lines to `seed_tmp_dir!/1` (alphabetically placed alongside the other `accrue/guides/*` copies):
- `copy_fixture!("accrue/guides/entitlements.md", tmp_dir)` (brand new)
- `copy_fixture!("accrue/guides/jobs_to_be_done.md", tmp_dir)` (previously unseeded; untracked until Plan 03 committed it)

These are mandatory: the negative-drift fixture tests seed then mutate one file, so any needle referencing an unseeded file would fail "No such file." The 6 previously-RED negative fixtures auto-greened (each short-circuited on the missing PROJECT.md phrase before reaching its mutation, now cleared).

## Phase gate — closing evidence for ENT-12 SC#4

| # | Command | Result |
|---|---------|--------|
| 1 | `bash scripts/ci/verify_package_docs.sh` | **exit 0** — "package docs verified for accrue 1.1.2, accrue_admin 1.1.2, and accrue_portal 1.1.2" |
| 2 | `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | **8 tests, 0 failures** |
| 3 | `cd accrue && mix docs` | **exit 0**; `doc/entitlements.html` present (35294 bytes) |

The 6 pre-existing PackageDocsVerifier failures are resolved (greened via Plan 03's D-13 fix + orchestrator's subscribe/3 restore), confirming SC#4 "verifiers stay green."

## Cross-plan sanity

- `cd accrue && mix test` (default seed): 49 properties, 1462 tests, **1 failure** — the known-flaky PdfTest (per project baseline). Deterministic re-run `mix test --seed 0`: **1462 tests, 0 failures** (flaky PdfTest did not reproduce; no regression).
- Verifier test re-run in isolation: 8 tests, 0 failures.
- `cd accrue_admin && mix test`: **131 tests, 0 failures** (Plan 02's entitlements tab + the rest of the admin suite green).

## Deviations from Plan

None — plan executed exactly as written. The prerequisite-state note (subscribe/3 second masked needle, already fixed in 5635d77 by the orchestrator) required no action here; baseline was confirmed GREEN before Task 1.

## Authentication Gates

None — CI/test edits only, no external auth.

## Known Stubs

None. Both changed files are CI/test scaffolding (a bash verifier and its Elixir wrapper's seed list) with no UI data flow; no placeholders, no hardcoded empty values.

## Threat-model adherence

- **T-126-11 (unseeded needle file → false-fail / hidden drift):** Task 2 added both needle-referenced files to `seed_tmp_dir!`; the phase gate asserts 8/0 with no "No such file" failure. Mitigated.
- **T-126-12 (flip-guard defeated by Update log):** the `require_absent_regex` is scoped to the unique removed scope-prose phrase `on the table** is **entitlements`, not "headline gap"; Plan 03 also reworded the Update log (belt-and-suspenders). The guard targets the scoped phrase and does not fire. Mitigated.
- **T-126-13 (positive needle ≠ authored doc string):** Task 1 re-read all four on-disk docs (and 126-03-SUMMARY.md's recorded marker) before pinning; every literal byte-matches. Mitigated.
- **T-126-SC (supply-chain):** zero package installs (CI/test edits only). N/A by design.

## Commits

- `94a305a` — feat(126-04): pin entitlements spine needles in package-doc verifier
- `1b8b1ca` — test(126-04): seed entitlements.md + jobs_to_be_done.md fixtures (D-15)

## Out-of-scope files (left untouched, as required)

- `accrue/guides/maturity-and-maintenance.md` (pre-existing uncommitted modification) — not staged, not committed, not reverted.
- `.planning/seeds/SEED-002-ecosystem-integrations.md` (pre-existing untracked file) — not staged, not committed, not deleted.

## Self-Check: PASSED

All claims verified — see appended self-check evidence below.
