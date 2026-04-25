---
quick_id: 260425-gr1
slug: drop-deprecated-flat-branding-keys-infra
status: complete
date: 2026-04-25
mode: quick
commit: 50f80db
files_touched:
  - accrue/guides/branding.md
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/application.ex
  - accrue/test/accrue/config_branding_test.exs
  - accrue/test/accrue/config_test.exs
diff_stats:
  files_changed: 5
  insertions: 16
  deletions: 269
---

# Quick Task 260425-gr1: Drop deprecated flat-branding-keys infrastructure — Summary

## What changed

Accrue is unpublished pre-1.0 with zero real users, so the flat-keys → nested-`:branding` deprecation shim, boot warning, docs, and tests are dead weight. Removed across five files:

1. **`accrue/guides/branding.md`** — Deleted the `## Deprecated flat keys` section (and its `### Migration example` subsection). Also stripped the stale "migration from legacy flat top-level keys" phrase from the intro paragraph so the guide no longer alludes to a migration story. The `## Connect note` section that followed is preserved.

2. **`accrue/lib/accrue/config.ex`** —
   - Deleted public function `deprecated_flat_branding_keys/0`.
   - Deleted private function `branding_from_flat_keys/0` and its helper `flat_key_to_nested/1`.
   - Simplified public `branding/0`: when the user has not set `:branding`, it now returns `branding_defaults/0` directly (no flat-key fallback). Docstring rewritten to drop migration / shim language and only describe the current nested behavior.
   - Updated the comment on `branding_defaults/0` to drop the obsolete "the shim returns" wording.
   - Updated the `@schema` `:branding` section comment header from "flat keys; prefer nested :branding" → "top-level legacy keys; prefer nested :branding" (the six top-level keys themselves remain valid schema entries; only the deprecation infrastructure is gone).

3. **`accrue/lib/accrue/application.ex`** —
   - Deleted the `warn_deprecated_branding/0` function (and its inline doc explaining the deprecation shim).
   - Removed the `:ok = warn_deprecated_branding()` call from `start/2`. No other `start/2` logic touched.

4. **`accrue/test/accrue/config_branding_test.exs`** —
   - Deleted the three describe blocks that exercised the removed surfaces: `"deprecated_flat_branding_keys/0"`, `"branding/0 flat-key shim (Task 3)"`, and `"Accrue.Application.warn_deprecated_branding/0"`.
   - Removed the now-unused `import ExUnit.CaptureLog`.
   - Trimmed the `setup` block: it no longer snapshots the six flat keys (no surviving test mutates them), only the nested `:branding` env. The remaining describes (`"branding/0 and branding/1"`, `"validate_hex/1"`, `"validate_at_boot!/0 with branding schema"`) all stay green.
   - Cleaned the moduledoc — dropped "Phase 6 Plan 01 Task 1-3" / "deprecation shim (Task 3)" / "(D6-02)" decision-id wording — and renamed one test description that referenced "D6-02 keys" → "branding keys".

5. **`accrue/test/accrue/config_test.exs`** — Tidied the `@test_branding` helper comment to drop the "Phase 6 (D6-02)" decision-id reference. Functionally identical; needed to satisfy verification step 2 (`rg "D6-02" lib/ test/ guides/` → zero hits).

Net effect: 269 lines removed, 16 lines added (mostly rewritten doc/comment text). The single supported branding shape is now the nested `:branding` keyword list, validated by NimbleOptions at boot, exactly as documented in the remaining `guides/branding.md`.

## Deviations from plan

- **Bonus cleanup beyond the plan's four files** — touched `accrue/test/accrue/config_test.exs` to strip a `D6-02` decision-id reference. This was needed because verification step 2 (`rg "D6-02"`) requires zero hits, and the surviving comment in `config_test.exs` would have failed the verification. Functionally unrelated to runtime behavior — comment-only edit. Folded into the same atomic commit.
- **Bonus cleanup in `accrue/guides/branding.md` intro paragraph** — removed the stale phrase "migration from legacy flat top-level keys" from the opening paragraph. The plan only specified deleting lines 85-122 (the dedicated section), but leaving the intro promising a migration that no longer exists in the doc would be incoherent. One-sentence trim.
- **Bonus cleanup in `accrue/lib/accrue/config.ex`** — also tidied the `@schema` comment header for the top-level brand keys ("flat keys; prefer nested :branding" → "top-level legacy keys; prefer nested :branding") and the `branding_defaults/0` comment ("the shim returns" → "callers get"). Both are stale-language hygiene; comment-only.

All deviations are scope-adjacent and pull in the same direction as the plan's intent. No architectural changes.

## Verification transcripts

All commands run from `accrue/` after the edits and before the commit.

### 1. `rg -n "deprecated_flat_branding_keys|branding_from_flat_keys|warn_deprecated_branding" lib/ test/ guides/`

```
(no output — exit 1, ripgrep's "no matches found")
```

Zero hits. All three deprecated symbols fully removed from the accrue tree.

### 2. `rg -n "Deprecated flat|D6-02" lib/ test/ guides/`

```
(no output — exit 1, ripgrep's "no matches found")
```

Zero hits. All deprecation-language and D6-02 decision-id references removed.

### 3. `mix compile --warnings-as-errors`

```
Compiling 2 files (.ex)
Generated accrue app
```

Exit 0, no warnings. The 2 recompiled files are `lib/accrue/config.ex` and `lib/accrue/application.ex`.

### 4. `mix test test/accrue/config_branding_test.exs`

```
Running ExUnit with seed: 723940, max_cases: 16
Excluding tags: [:live_stripe, :slow, :compile_matrix]

................
Finished in 0.03 seconds (0.00s async, 0.03s sync)
16 tests, 0 failures
```

All 16 surviving tests green. Coverage:
- `branding/0 and branding/1` (6 tests) — defaults + branding/1 lookups
- `validate_hex/1` (7 tests) — hex color custom validator
- `validate_at_boot!/0 with branding schema` (3 tests) — required-keys + hex-validation enforcement

### 5. `mix test`

```
Finished in 7.0 seconds (2.9s async, 4.1s sync)
46 properties, 1169 tests, 0 failures (11 excluded)
```

Full suite green. 1169 tests pass, 46 StreamData properties pass, 11 excluded by the existing `:live_stripe`/`:slow`/`:compile_matrix` tag filters. No regressions from the deletion.

## Acceptance evidence

- All five verification steps pass (transcripts above).
- Single atomic commit `50f80db` covers the change: 5 files changed, 16 insertions, 269 deletions.
- `git log -1`:
  ```
  50f80db refactor(branding): drop deprecated flat-keys infrastructure
  ```

## Files touched

| File | Lines removed | Lines added |
|------|---------------|-------------|
| `accrue/guides/branding.md` | 41 | 2 |
| `accrue/lib/accrue/config.ex` | 49 | 9 |
| `accrue/lib/accrue/application.ex` | 31 | 0 |
| `accrue/test/accrue/config_branding_test.exs` | 142 | 4 |
| `accrue/test/accrue/config_test.exs` | 6 | 5 |

(Counts approximate; net = 16 add / 269 delete per `git show --stat 50f80db`.)
