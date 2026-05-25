---
phase: 131-optional-chimeway-engine-adapter-isolated-off-by-default
plan: "06"
subsystem: docs
tags: [dunning, chimeway, docs, verifier, DUN-03]
dependency_graph:
  requires: ["131-02", "131-04"]
  provides: ["dunning.md Chimeway upgrade section", "dunning.engine matrix row", "verify_package_docs needles", "PackageDocsVerifierTest dunning.md seed"]
  affects: ["accrue/guides/dunning.md", ".planning/processor-support-matrix.md", "scripts/ci/verify_package_docs.sh", "accrue/test/accrue/docs/package_docs_verifier_test.exs"]
tech_stack:
  added: []
  patterns: ["require_fixed needle pinning", "seed_tmp_dir! fixture coupling", "opt-in upgrade section pattern (analog: entitlements.md Stripe-native sync)"]
key_files:
  created: []
  modified:
    - accrue/guides/dunning.md
    - .planning/processor-support-matrix.md
    - scripts/ci/verify_package_docs.sh
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
decisions:
  - "Placed '## Upgrading to Chimeway orchestration' section after '## Configuration' (before '## Observability') so engine config key flows naturally from campaign config context"
  - "Used Stripe-native sync section of entitlements.md as structural analog (Prerequisites / Installation / Configuration / What changes / What stays the same)"
  - "Documented actual Chimeway 1.0.0 API surface: Chimeway.trigger/3 + Chimeway.Notifier behaviour (no stop_conditions / Chimeway.Workflow per research override)"
  - "dunning.engine matrix row uses built-in (Oban) x3 + optional adapter (Chimeway v1.0.0) per D-07; added prose paragraph noting engine choice is provider-independent"
  - "Three verify_package_docs.sh needles placed after Phase 127 block, before accrue_admin/mix.exs block, with one-line comment per pattern"
  - "copy_fixture!(accrue/guides/dunning.md) added to seed_tmp_dir! in PackageDocsVerifierTest in same plan (mandatory coupling per project invariant)"
metrics:
  duration: "~10 min"
  completed_date: "2026-05-25"
  tasks: 2
  files: 4
---

# Phase 131 Plan 06: Chimeway Docs + Verifier Needles Summary

**One-liner:** Chimeway opt-in upgrade docs in dunning.md, dunning.engine matrix row, three verify_package_docs.sh needles, and mandatory PackageDocsVerifierTest dunning.md fixture seed (DUN-03 SC#4, D-07).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | dunning.md Chimeway upgrade section + dunning.engine matrix row | 8e003463 | accrue/guides/dunning.md, .planning/processor-support-matrix.md |
| 2 | verify_package_docs.sh needles + PackageDocsVerifierTest fixture coupling | 6080717c | scripts/ci/verify_package_docs.sh, accrue/test/accrue/docs/package_docs_verifier_test.exs |

## What Was Built

### Task 1: dunning.md + matrix

Added `## Upgrading to Chimeway orchestration` section to `accrue/guides/dunning.md` after the `## Configuration` section. Subsections: Prerequisites, Installation, Configuration, What changes, What stays the same. Content:
- States Chimeway is optional and off-by-default; built-in `Accrue.Dunning.Engine.Oban` is always-on default
- Installation: `{:chimeway, "~> 1.0"}` dep + note that host runs Chimeway's own migrations (Accrue does not start Chimeway)
- Configuration: `dunning: [engine: Accrue.Integrations.Chimeway]` config block (all three needle targets present)
- What changes: orchestration via `Chimeway.trigger/3` + bundled `Chimeway.Notifier`; cancel-on-recovery via `Chimeway.Signal.track/4`
- What stays the same: campaign DB state, email templates, ledger events, telemetry, customer/admin surfaces
- v1.40 scope note: email-only, `:immediate` orchestration; multi-channel deferred
- Zero occurrences of `stop_conditions` or `Chimeway.Workflow` (research override honored)

Added `dunning.engine` row to `.planning/processor-support-matrix.md` adjacent to existing dunning rows:
```
| dunning.engine | built-in (Oban) | built-in (Oban) | built-in (Oban) | optional adapter (Chimeway v1.0.0) |
```
Added prose paragraph explaining engine choice is provider-independent (orthogonal to processor).

### Task 2: verify_package_docs.sh + test coupling

Added three `require_fixed` needles to `scripts/ci/verify_package_docs.sh` after the Phase 127 Stripe-native block:
```bash
# Optional Chimeway dunning engine adapter (Phase 131, DUN-03)
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Dunning.Engine'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'Accrue.Integrations.Chimeway'
require_fixed "$ROOT_DIR/accrue/guides/dunning.md" 'dunning: [engine:'
```

Added `copy_fixture!("accrue/guides/dunning.md", tmp_dir)` to `seed_tmp_dir!` in `PackageDocsVerifierTest` — the mandatory coupling that keeps all 6 negative tests green when new needles target dunning.md.

## Verification Results

- `bash scripts/ci/verify_package_docs.sh` — exits 0
- `bash scripts/ci/verify_processor_support_matrix.sh` — exits 0
- `grep -c stop_conditions accrue/guides/dunning.md` — returns 0
- `mix test test/accrue/docs/package_docs_verifier_test.exs --seed 0` — 8 tests, 0 failures (all 6 negative tests green)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all content is wired. The upgrade section documents the actual published Chimeway 1.0.0 API surface.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. All changes are documentation, a CI shell script, and an ExUnit test fixture update.

## Self-Check: PASSED

Files present:
- accrue/guides/dunning.md: contains all required needles + no stale DSL
- .planning/processor-support-matrix.md: contains dunning.engine row
- scripts/ci/verify_package_docs.sh: contains 3 dunning.md require_fixed lines
- accrue/test/accrue/docs/package_docs_verifier_test.exs: contains dunning.md copy_fixture!

Commits present:
- 8e003463: docs(131-06): Chimeway upgrade section in dunning.md + dunning.engine matrix row
- 6080717c: docs(131-06): Chimeway dunning needles in verify_package_docs.sh + test fixture seed
