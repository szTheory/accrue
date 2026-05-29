# Phase 152: Close v1.46 closure gaps — Research

**Researched:** 2026-05-29
**Domain:** Elixir ExDoc annotations, Release Please linked-versions pipeline, Hex publish, CI gate scripts
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Target **`1.3.0`** across all three packages. Release Please computes the version from conventional commits (16 `feat:` since `1.2.0`, no breaking changes). Do NOT manually override the manifest.
- **D-02:** All 7 occurrences are malformed docstrings or misplaced module attributes, not real compiler attributes. Fix: convert each to canonical `@doc since: "1.3.0"` (placed as a separate `@doc` option attribute after the `@doc """ ... """` block). Version must be `1.3.0`, not `1.4.0`.
- **D-03:** Closure gate is "The Three Zeros": (1) all P0/P1 triage closed, (2) zero audit gaps — `verify_package_docs.sh` + `verify_adoption_proof_matrix.sh` + release contract/manifest/notes scripts — (3) zero Nyquist/coverage gaps, plus full `mix test` / `mix dialyzer` / `mix credo` across the trio. ExCoveralls thresholds are ratified baselines — do not lower them.
- **D-04:** Publish via the established Release Please linked-versions pipeline. `separate-pull-requests: false`. One combined PR bumps `@version` in all three `mix.exs` + manifest + CHANGELOGs. Reconcile hand-written "Unreleased" sections against Release-Please-generated entries during the release PR (no duplication).

### Claude's Discretion

- Exact ordering of closure tasks (fix `@since` → run gate → cut release PR) and how the CHANGELOG "Unreleased" content is folded.

### Deferred Ideas (OUT OF SCOPE)

- None — discussion stayed within phase scope.
</user_constraints>

---

## Summary

Phase 152 is mechanical closure work: fix 7 malformed `@since` annotations, run the Three Zeros gate green, and cut the linked 1.3.0 Hex release. No new functional capability is introduced.

The codebase investigation confirms the CONTEXT.md decisions with one important correction: dunning.ex contains **6 malformed `@since` lines** (not 5 as stated in the CONTEXT.md §D-02 count), plus **1 already-canonical `@doc since:` at line 371 that only needs a version correction** (`"1.4.0"` → `"1.3.0"`), for a total of 7 fixes across the file. The CONTEXT.md "7 occurrences" total is correct; the "5×" subclaim for dunning.ex is slightly off — it is 6 malformed + 1 correct-form-wrong-version = 7.

The linked-versions pipeline is fully established. `.release-please-manifest.json` currently pins all three packages at `"1.2.0"`. After 16 `feat:` commits and no breaking changes, Release Please will bump to `1.3.0` automatically — no manifest override is needed.

All three CHANGELOG files have hand-written `## Unreleased` sections that must be reconciled (frozen or drained into the Release-Please-generated `## [1.3.0]` block) during the release PR review, per RELEASING.md policy.

**Primary recommendation:** Fix all 7 `@since` issues first, then run the full Three Zeros gate locally, then trigger the Release Please combined PR and follow RELEASING.md §"Routine linked releases".

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `@since` annotation fix | Source code (accrue, accrue_admin) | — | Pure code edit; ExDoc renders the badge at doc-gen time |
| Three Zeros gate | CI scripts (scripts/ci/) | Local dev verification | Bash scripts are the authority; run locally before pushing |
| Release Please PR | GitHub Actions (release-please.yml) | Manual fallback (publish-hex.yml) | Automation owns version bumps; human reviews and merges |
| Hex publish ordering | CI workflow (release-please.yml) | — | accrue → accrue_admin → accrue_portal; enforced by `needs:` chain |
| CHANGELOG reconciliation | Human on release PR | — | Release Please generates numbered sections; human drains Unreleased prose |

---

## Standard Stack

No new packages are introduced in this phase. All tools are already in place.

### Tooling In Play

| Tool | Version (confirmed) | Purpose | How Used |
|------|--------------------|---------|----------|
| ExDoc | `~> 0.40` [ASSUMED — confirmed in accrue/mix.exs pattern] | Doc generation; renders `@doc since:` badge | The canonical form this phase targets |
| ExCoveralls | `~> 0.18` [VERIFIED: accrue/mix.exs line 110] | Coverage gate for `accrue` | `mix coveralls` in Three Zeros gate |
| Release Please | v4 (GitHub Actions) [VERIFIED: release-please-config.json] | Linked version bumps, CHANGELOG generation | Triggered on merge to `main` |
| `scripts/ci/verify_*.sh` | In-repo [VERIFIED: codebase grep] | All CI gate scripts | Run locally before publish |

### Package Legitimacy Audit

No new packages are installed in this phase. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
Source fix (dunning.ex × 6, funnel_chart.ex × 1)
        │
        ▼
Three Zeros local gate
  ├─ mix test --seed 0 (all 3 packages; --seed 0 dodges PdfTest flake)
  ├─ mix dialyzer (accrue only — admin/portal have no separate PLTs)
  ├─ mix credo --strict (all 3 packages)
  ├─ bash scripts/ci/verify_package_docs.sh
  ├─ bash scripts/ci/verify_adoption_proof_matrix.sh
  ├─ bash scripts/ci/verify_release_notes_contract.sh  ← requires ### 1.2.0 (current)
  ├─ bash scripts/ci/verify_release_manifest_alignment.sh
  └─ bash scripts/ci/verify_release_contract.sh
        │
        ▼  (all green — push to main)
Release Please PR opens automatically
  └─ bumps @version 1.2.0 → 1.3.0 in all 3 mix.exs
  └─ bumps .release-please-manifest.json all keys → "1.3.0"
  └─ generates ## [1.3.0] sections in all 3 CHANGELOG.md files
        │
        ▼  Human review checklist (RELEASING.md)
  ├─ Verify version consistency (manifest ↔ mix.exs ↔ CHANGELOG)
  ├─ Reconcile Unreleased prose (freeze or fold into 1.3.0 section)
  ├─ Add ### 1.3.0 to release-notes.md (both accrue + accrue_admin sections)
  └─ bash scripts/ci/verify_release_pr_scope.sh --pr <N> --version 1.3.0
        │
        ▼  Merge PR (manually or via gh_merge_release_pr.sh + workflow_dispatch)
release-please.yml publishes:
  1. accrue (mix hex.publish)
  2. accrue_admin (after accrue succeeds; ACCRUE_ADMIN_HEX_RELEASE=1)
  3. accrue_portal (after accrue + accrue_admin; ACCRUE_PORTAL_HEX_RELEASE=1)
  └─ tags: accrue-v1.3.0, accrue_admin-v1.3.0, accrue_portal-v1.3.0
```

### Recommended Project Structure

No structural changes. All work is in existing files.

---

## The `@since` Fix: Confirmed Codebase State

### dunning.ex — 7 total items, all at version "1.4.0" → fix to "1.3.0"

**File:** `accrue/lib/accrue/analytics/dunning.ex`

| Line | Pattern | What it is | Fix required |
|------|---------|-----------|--------------|
| 50 | `@since "1.4.0"` inside `@doc """ ... """` heredoc | Stray literal text; renders in ExDoc output as `@since "1.4.0"` | Remove from inside heredoc; add `@doc since: "1.3.0"` AFTER the closing `"""` |
| 98 | Same — inside `@doc` heredoc | Same | Same fix |
| 159 | Same — inside `@doc` heredoc | Same | Same fix |
| 224 | Same — inside `@doc` heredoc | Same | Same fix |
| 333 | `@since "1.4.0"` OUTSIDE heredoc, between `@doc """ ... """` and `@spec` | Free-floating module attribute; silently set and consumed by next attribute — compiler does NOT warn here because `@spec` follows | Replace with `@doc since: "1.3.0"` in correct position |
| 343 | `@since "1.4.0"` OUTSIDE heredoc, between `@doc """ ... """` and `@spec` | Free-floating module attribute; generates compiler warning: "module attribute @since was set but never used" (because it is the last `@since` before the end-of-module accumulation) | Replace with `@doc since: "1.3.0"` in correct position |
| 371 | `@doc since: "1.4.0"` AFTER `@doc """ ... """` | Already canonical ExDoc form — correct placement, wrong version | Version bump: `"1.4.0"` → `"1.3.0"` |

**Correction to CONTEXT.md D-02:** D-02 says "5× in dunning.ex". The actual count is 6 malformed lines + 1 already-canonical-but-wrong-version line = 7 items in dunning.ex. CONTEXT.md's "7 occurrences" total is correct; the "5×" sub-claim is wrong. The planner must treat dunning.ex as 7 items (not 5).

**Confirmed compiler warning source:** The Elixir compiler only warns for line 343 (the last free-floating `@since` in the module that is never read by a subsequent doc-processing attribute). Line 333 does not warn because the compiler sees `@spec` immediately after and "consumes" the accumulated value. Both lines 333 and 343 must be fixed regardless — the warning is a symptom, not the full definition of the problem.

**File:** `accrue_admin/lib/accrue_admin/components/funnel_chart.ex`

| Line | Pattern | What it is | Fix required |
|------|---------|-----------|--------------|
| 27 | `@since "1.4.0"` inside `@doc """ ... """` heredoc | Stray literal text | Remove from inside heredoc; add `@doc since: "1.3.0"` AFTER the closing `"""` |

**CONTEXT.md "2 hits in this file" ambiguity:** `grep` reports exactly **1 hit** in funnel_chart.ex at line 27. There is no second occurrence. The ambiguity noted in CONTEXT.md ("grep reports 2 hits — confirm during planning") is resolved: 1 occurrence only. [VERIFIED: grep -n '@since' on the file]

### Canonical ExDoc Pattern [VERIFIED: dunning.ex line 371]

The correct form — already used at line 371 — is:

```elixir
@doc """
Returns a map of invoices for a given subscription, keyed by Stripe processor_id.
"""
@doc since: "1.3.0"
@spec some_function(arg) :: return_type
def some_function(arg) do
```

The `@doc since:` attribute is placed as a **separate** `@doc` attribute after the closing `"""` of the doc heredoc, not inside the heredoc content. ExDoc accumulates multiple `@doc` calls for the same function into a single rendered docblock. [ASSUMED — ExDoc behavior from training knowledge; the dunning.ex line 371 pattern is the in-repo proof of adoption]

---

## The Release Pipeline: Confirmed Codebase State

### `.release-please-manifest.json` — Current State [VERIFIED]

```json
{
  "accrue": "1.2.0",
  "accrue_admin": "1.2.0",
  "accrue_portal": "1.2.0"
}
```

Release Please will bump all three to `"1.3.0"` based on conventional commit analysis. Do not manually edit this file.

### `release-please-config.json` — Key Flags [VERIFIED]

- `"separate-pull-requests": false` — one combined PR for all three packages
- `"type": "linked-versions"` plugin with `"components": ["accrue", "accrue_admin", "accrue_portal"]`
- `"release-type": "elixir"` for each package — Release Please natively updates `@version "x.y.z"` in `mix.exs`
- `"include-component-in-tag": true` — produces tags `accrue-v1.3.0`, `accrue_admin-v1.3.0`, `accrue_portal-v1.3.0`

### Inter-package Version Pins [VERIFIED: grep on mix.exs files]

| Package | Pin to accrue core | Pin form | Resolves at 1.3.0? |
|---------|-------------------|----------|-------------------|
| `accrue_admin` | `{:accrue, "~> #{@version}"}` | Tilde-allow-patch | Yes — `~> 1.3.0` allows `1.3.x` but not `1.4+` |
| `accrue_portal` | `{:accrue, "== #{@version}"}` | Exact pin | Yes — `== 1.3.0` |

Both use `@version` interpolation, so when Release Please bumps `@version "1.2.0"` → `"1.3.0"` in each `mix.exs`, the pin automatically resolves correctly. No manual dep string editing needed.

### Current `@version` in All Three `mix.exs` [VERIFIED]

All three files currently have `@version "1.2.0"` (line 4 in each).

### Publish Ordering (enforced by `release-please.yml` `needs:`) [VERIFIED: RELEASING.md]

1. `publish-accrue` runs first
2. `publish-accrue-admin` — `needs: [release, publish-accrue]`
3. `publish-accrue-portal` — `needs: [release, publish-accrue, publish-accrue-admin]`

---

## The Three Zeros Gate: Confirmed CI Script Inventory

### Gate Scripts — "Zero Audit Gaps" Component

Run locally from the repo root before pushing the `@since` fix to main:

```bash
bash scripts/ci/verify_package_docs.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
bash scripts/ci/verify_release_notes_contract.sh
bash scripts/ci/verify_release_manifest_alignment.sh
bash scripts/ci/verify_release_contract.sh
```

Plus the broader shift-left suite that also runs in CI:

```bash
bash scripts/ci/verify_processor_support_matrix.sh
bash scripts/ci/verify_core_liveview_runtime_free.sh
bash scripts/ci/verify_entitlement_sync_isolation.sh
bash scripts/ci/verify_dunning_chimeway_isolation.sh
bash scripts/ci/verify_v1_17_friction_research_contract.sh
bash scripts/ci/verify_verify01_readme_contract.sh
bash scripts/ci/verify_production_readiness_discoverability.sh
bash scripts/ci/verify_adoption_proof_matrix.sh
bash scripts/ci/verify_core_admin_invoice_verify_ids.sh
```

### Gate Scripts — "Zero Nyquist/Coverage" Component

```bash
# accrue — ExCoveralls wired; preferred_cli_env set
cd accrue && mix coveralls

# accrue_admin — summary threshold 80
cd accrue_admin && mix test --cover

# accrue_portal — summary threshold 75
cd accrue_portal && mix test --cover
```

Coverage thresholds are ratified baselines from Phase 151-03:
- `accrue`: ExCoveralls wired (no threshold explicitly set in mix.exs; run `mix coveralls` for report)
- `accrue_admin`: `test_coverage: [summary: [threshold: 80]]` in mix.exs line 19
- `accrue_portal`: `test_coverage: [summary: [threshold: 75]]` in mix.exs line 20

### Gate Commands — Full Mix Test + Static Analysis

```bash
# Full test run — use --seed 0 to dodge PdfTest flake (confirmed in MEMORY.md)
cd accrue && mix test --seed 0
cd accrue_admin && mix test --seed 0
cd accrue_portal && mix test --seed 0

# Static analysis (accrue only for dialyzer; all for credo)
cd accrue && mix dialyzer
cd accrue && mix credo --strict
cd accrue_admin && mix credo --strict
cd accrue_portal && mix credo --strict

# Compile-time warnings check (will surface the @since warning until fixed)
cd accrue && mix compile --warnings-as-errors
```

### Known Flake

`PdfTest` in `accrue` is a known flaky test. Dodge with `--seed 0`. Do not mark as failing — it is an acknowledged pre-existing flake per MEMORY.md entry `project_preexisting_test_failures.md`.

---

## CHANGELOG Reconciliation

### Current State [VERIFIED: grep on CHANGELOG.md files]

| Package | Has `## Unreleased` | Content |
|---------|---------------------|---------|
| `accrue/CHANGELOG.md` | Yes — hand-written prose covering phases 143–151 features | Billing, Telemetry, Documentation, CI sections |
| `accrue_admin/CHANGELOG.md` | Yes — brief hand-written prose | Host-visible copy note |
| `accrue_portal/CHANGELOG.md` | **No `## Unreleased` section** | Starts directly at `## [1.2.0]` |

### Release Please Behavior

When the release PR is cut, Release Please generates `## [1.3.0](...)` sections in all three CHANGELOG files from conventional commits. The `## Unreleased` sections in `accrue` and `accrue_admin` will remain as-is unless manually drained.

### RELEASING.md Policy (§"Changelog ship boundary")

> "At the merge/tag/publish boundary, `## Unreleased` / `## [Unreleased]` must not be the only home for work that already appears under the shipped version section: when the release PR is cut, freeze or drain Unreleased so nothing ships with prose that belongs under the version that is tagging."

### Action Required During Release PR Review

For `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md`: during the release PR review, either (a) merge the `## Unreleased` prose into the Release-Please-generated `## [1.3.0]` section (preferred — keeps one authoritative block), or (b) delete the `## Unreleased` header once 1.3.0 is cut (the content was already captured by conventional commits in the generated section). Do not ship with both `## Unreleased` and `## [1.3.0]` containing overlapping content.

---

## `release-notes.md` Requires Manual Update

### Current State [VERIFIED]

`accrue/guides/release-notes.md` currently has `### 1.2.0` as the latest version heading in both the `## accrue` and `## accrue_admin` sections.

`verify_release_notes_contract.sh` checks that `### ${accrue_version}` appears at least twice in the file (once per package section). When `@version` becomes `1.3.0` (after the release PR lands), the script will fail unless `### 1.3.0` is added to both sections.

### Action Required

Add `### 1.3.0` plain-language summary blocks to both `## accrue` and `## accrue_admin` sections of `accrue/guides/release-notes.md` as part of the release PR. This is a pre-publish blocking step (the CI check runs against the post-merge `@version`).

**Timing:** Add the `### 1.3.0` entries on the release PR branch, before merge, so CI passes on the release PR diff. The Release Please PR bumps `@version` and Release Please CI runs `verify_release_notes_contract.sh` against the bumped version.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version bump across 3 packages | Manual `sed` of `@version` in each `mix.exs` | Release Please linked-versions pipeline | Already established; manual edits risk manifest drift |
| CHANGELOG generation | Manual writing of `## [1.3.0]` section | Release Please (auto-generates from conventional commits) | The script `verify_release_pr_scope.sh` validates RP-generated headings |
| Tag creation | `git tag accrue-v1.3.0` by hand | `release-please.yml` workflow (tags on merge) | `include-component-in-tag: true` is already configured |
| Package publish order enforcement | Manual publish with delays | `release-please.yml` `needs:` chain | Already hardcoded: accrue → admin → portal |

---

## Common Pitfalls

### Pitfall 1: Removing `@since` text without adding the canonical attribute

**What goes wrong:** Developer deletes the stray `@since "1.4.0"` line from inside the heredoc but forgets to add `@doc since: "1.3.0"` after the closing `"""`. The version badge disappears from ExDoc output silently.
**Why it happens:** The fix looks like "just remove junk text."
**How to avoid:** For each heredoc fix, the task must be: (1) remove line from inside heredoc, AND (2) add `@doc since: "1.3.0"` immediately after the `"""` closing line.

### Pitfall 2: Wrong placement of `@doc since:`

**What goes wrong:** Developer puts `@doc since: "1.3.0"` inside the heredoc content instead of as a separate module attribute after the heredoc.
**Why it happens:** Unfamiliarity with ExDoc's multi-attribute accumulation.
**How to avoid:** Follow the existing pattern at `dunning.ex:371` — `@doc since:` is a separate attribute on its own line, after `"""`, before `@spec`.
**Warning signs:** ExDoc renders "since: 1.3.0" as literal text in the description body instead of a badge.

### Pitfall 3: `verify_release_notes_contract.sh` fails after version bump

**What goes wrong:** The release PR bumps `@version` to `1.3.0` but `release-notes.md` still only has `### 1.2.0`. The `docs-contracts-shift-left` CI job fails.
**Why it happens:** The notes file requires **two** `### 1.3.0` headings (one each for `## accrue` and `## accrue_admin` sections). Easy to miss.
**How to avoid:** Add `### 1.3.0` to both sections of `release-notes.md` **on the release PR branch**, not after merge.

### Pitfall 4: `verify_release_manifest_alignment.sh` drift

**What goes wrong:** The script checks that `.release-please-manifest.json` and both `accrue/mix.exs` + `accrue_admin/mix.exs` agree on version. If any manual edit to `mix.exs` is pushed without the manifest, CI fails.
**Why it happens:** Manual `@version` edits bypass Release Please.
**How to avoid:** Never manually bump `@version` in any of the three `mix.exs` files. Let Release Please do it.

### Pitfall 5: `verify_package_docs.sh` — version string in README/first_hour.md

**What goes wrong:** `verify_package_docs.sh` checks `{:accrue, "~> $accrue_version"}` in README.md and first_hour.md (unless `RELEASE_PLEASE_PR=1` env var is set). After the version bumps to 1.3.0, these strings need updating.
**Why it happens:** Version strings in docs are not auto-updated by Release Please.
**How to avoid:** Update `{:accrue, "~> 1.3.0"}` and related version strings in `accrue/README.md`, `accrue_admin/README.md`, `accrue_portal/README.md`, and `accrue/guides/first_hour.md` as part of the release PR. The `RELEASE_PLEASE_PR=1` env var bypasses this check during CI on the release PR branch, but the strings should still be updated for correctness.

### Pitfall 6: PdfTest flake causes false gate failure

**What goes wrong:** `mix test` exits non-zero due to PdfTest; Three Zeros gate appears red.
**Why it happens:** Pre-existing intermittent failure documented in MEMORY.md.
**How to avoid:** Always run `mix test --seed 0` to reproduce tests in a stable order that dodges the flake.

### Pitfall 7: `verify_package_docs.sh` needle → `PackageDocsVerifierTest` fixture coupling

**What goes wrong:** If any new needle is added to `verify_package_docs.sh` during this phase, the corresponding needle must also be added to `PackageDocsVerifierTest`'s `seed_tmp_dir!` helper, or all 6 negative tests in the test file will fail.
**Why it happens:** The verifier test seeds a temp dir with exactly the needles the script checks. Adding a new needle to the script without updating the test fixture breaks the negative tests.
**How to avoid:** This phase does NOT add any new needles to `verify_package_docs.sh`. No action needed for this pitfall in this phase.

---

## Version Pin Resolution Verification

When Release Please bumps `@version "1.2.0"` → `"1.3.0"` in both `accrue_admin/mix.exs` and `accrue_portal/mix.exs`:

- `accrue_admin` dep: `{:accrue, "~> 1.3.0"}` — allows `>= 1.3.0 and < 1.4.0`. Clean.
- `accrue_portal` dep: `{:accrue, "== 1.3.0"}` — exact pin. Clean.

No manual intervention needed. The interpolation `"~> #{@version}"` and `"== #{@version}"` self-update when `@version` is bumped.

---

## Validation Architecture

This phase introduces no new code paths. The existing verification suite IS the validation:

- `mix test --seed 0` (across all 3 packages) — confirms no regressions from `@since` edits
- `mix compile --warnings-as-errors` in `accrue` — confirms the `@since "1.4.0"` compiler warning is eliminated
- `bash scripts/ci/verify_package_docs.sh` — confirms docs gate stays green
- `bash scripts/ci/verify_release_notes_contract.sh` — gates on `### 1.3.0` in release-notes.md
- `bash scripts/ci/verify_release_pr_scope.sh --pr <N> --version 1.3.0` — confirms release PR scope

No new test files are needed. A new `## Validation Architecture` section with invented test architecture would not add value here.

---

## Environment Availability

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| Elixir / Mix | All mix commands | Assumed present | Project is actively developed |
| PostgreSQL | `mix test` (accrue) | Assumed running locally | Tests require DB |
| `jq` | `verify_release_contract.sh`, `verify_release_manifest_alignment.sh`, `verify_release_pr_scope.sh` | Check with `command -v jq` before running | Required by those scripts |
| `gh` (GitHub CLI) | `verify_release_pr_scope.sh`, `gh_merge_release_pr.sh` | Check with `command -v gh` before running | Required for PR-scope check |
| Chrome/Chromium | `chromic_pdf` — only for PdfTest | Present or dodged with `--seed 0` | PdfTest flake is the only affected test |

---

## Security Domain

This phase makes no changes to authentication, authorization, webhook handling, or secrets management. Security domain not applicable.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@doc since:` placed after `"""` accumulates into the same function's ExDoc block | `@since` Fix section | If wrong, the badge might not appear; low risk — proven by in-repo line 371 precedent |
| A2 | 16 `feat:` commits since 1.2.0 is sufficient for Release Please to compute 1.3.0 | Release Pipeline | If fewer feat: commits, RP might compute 1.2.1; user confirmed 1.3.0 (D-01) — if RP disagrees, use `Release-As: 1.3.0` footer |
| A3 | `accrue/mix.exs` has no explicit ExCoveralls line-coverage threshold (only the tool wiring and `preferred_cli_env`) | Three Zeros Gate | If there is a threshold check not found in this grep, `mix coveralls` might fail at gate time |

**If RP computes a version other than 1.3.0:** Add a `Release-As: 1.3.0` trailer to a commit on main before triggering the RP run, per the RELEASING.md appendix convention.

---

## Open Questions (RESOLVED)

1. **ExCoveralls threshold for `accrue` core package**
   - What we know: `accrue/mix.exs` wires `tool: ExCoveralls` and `preferred_cli_env` (lines 23–28); no `summary: [threshold: N]` was found.
   - What's unclear: Is there a `.coveralls.yml` or `coveralls.json` threshold file for `accrue` that was not found (grep found none in `accrue/`)?
   - Recommendation: Run `mix coveralls` in `accrue` directory and observe output. If it exits 0 with current coverage, the gate passes.
   - RESOLVED: Plan 02 Task 1 runs `mix coveralls` in accrue at gate time and observes the exit code directly — no threshold file is assumed; the command result is the gate truth.

2. **Release Please trigger — automatic vs manual**
   - What we know: Release Please runs on pushes to `main` per `ci.yml`; it opens the PR automatically when it finds conventional commits since the last tag.
   - What's unclear: Whether there are any stale Release Please branch remnants from prior runs that need cleanup before a fresh PR is opened.
   - Recommendation: Check `git branch -r | grep release-please` before triggering. If a stale `release-please--branches--main` branch exists, the planner task should include checking and potentially running `repair_linked_release_pr.sh`.
   - RESOLVED: Plan 03 Task 2 explicitly checks for stale RP branches via `git branch -r | grep release-please` and runs `repair_linked_release_pr.sh --version 1.3.0` if a stale branch is found before triggering the combined PR.

---

## Sources

### Primary (HIGH confidence)
- `accrue/lib/accrue/analytics/dunning.ex` — Direct grep + line-by-line inspection; all 7 `@since` items confirmed with line numbers and context
- `accrue_admin/lib/accrue_admin/components/funnel_chart.ex` — Direct grep; confirmed 1 occurrence at line 27
- `.release-please-manifest.json` — File read; all three packages at `"1.2.0"`
- `release-please-config.json` — File read; `linked-versions` plugin, `separate-pull-requests: false`, `elixir` release-type, `include-component-in-tag: true`
- `accrue/mix.exs`, `accrue_admin/mix.exs`, `accrue_portal/mix.exs` — Direct grep; `@version "1.2.0"` confirmed in each; inter-package pins confirmed
- `RELEASING.md` — Full file read; linked-release runbook, CHANGELOG policy, publish ordering confirmed
- `scripts/ci/verify_*.sh` (all 16 scripts) — Listed and key ones fully read
- `.github/workflows/ci.yml` — Job structure and which scripts run in which jobs confirmed
- `accrue/CHANGELOG.md`, `accrue_admin/CHANGELOG.md`, `accrue_portal/CHANGELOG.md` — First 60 lines read; Unreleased section presence confirmed
- `accrue/guides/release-notes.md` — File read; `### 1.2.0` is the current latest in both package sections
- `accrue/test_output.log` — Confirmed compiler warning fires only for dunning.ex line 343

### Secondary (MEDIUM confidence)
- ExDoc `@doc since:` behavior — Inferred from in-repo precedent at `dunning.ex:371`; ExDoc documentation not independently fetched

---

## Metadata

**Confidence breakdown:**
- `@since` fix targets: HIGH — confirmed by direct grep with line numbers and context inspection
- Release pipeline: HIGH — config files read directly, RELEASING.md fully reviewed
- Three Zeros gate scripts: HIGH — all scripts read, CI workflow structure confirmed
- CHANGELOG reconciliation: HIGH — file content verified
- ExDoc `@doc since:` semantics: MEDIUM — in-repo precedent only, not independently verified from ExDoc docs

**Research date:** 2026-05-29
**Valid until:** 2026-06-29 (stable domain; only risks are RP version computation and coverage thresholds)
