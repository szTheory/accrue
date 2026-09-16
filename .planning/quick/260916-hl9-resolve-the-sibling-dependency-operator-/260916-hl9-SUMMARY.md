---
task: quick-260916-hl9
title: Resolve the sibling dependency operator inconsistency
status: complete
human_judgment: false
one_liner: accrue_portal moved off an exact-pin `{:accrue, "== #{@version}"}` onto the same-minor `~>` operator already used by accrue_admin; CLAUDE.md's `:accrue` row now states that real contract; the merge-blocking release-manifest script gained a non-vacuous assertion (proven via two required negative controls) that both siblings declare the interpolated same-minor form.
requirements: [HL9-01]
key-files:
  created: []
  modified:
    - accrue_portal/mix.exs
    - CLAUDE.md
    - scripts/ci/verify_release_manifest_alignment.sh
decisions:
  - Left accrue_portal/mix.lock untouched even though `mix deps.get` regenerated it locally (adds a missing `jose` lock entry) — that gap pre-dates this task (confirmed via `git show HEAD~3:accrue_portal/mix.lock`, no `jose` entry present before any of this session's edits) and is unrelated to the `==` → `~>` operator change, so per the SCOPE BOUNDARY rule it is out of scope and was reverted after using it to prove `mix compile` succeeds.
actuals:
  tokens: 9200
  tasks: 3
  commits: 3
  plan_head_before: c597dbf3197130b74a8b7a51cee2be847abcb47
metrics:
  duration: ~25m
  completed: 2026-09-16
---

# Quick Task 260916-hl9: Resolve the sibling dependency operator inconsistency Summary

accrue_portal's Hex-release dependency declaration used an exact-pin operator (`== #{@version}`) while accrue_admin already used the same-minor operator (`~> #{@version}`) for the identical purpose — both declaring the core `:accrue` sibling dependency in a published release. This task standardized accrue_portal onto the same-minor form, corrected CLAUDE.md's stale "exact pin" claim about the `accrue_admin` package's `:accrue` row, and extended the already merge-blocking `scripts/ci/verify_release_manifest_alignment.sh` so this specific divergence can never silently recur.

## Tasks Completed

### Task 1: Standardize accrue_portal on the same-minor sibling operator
- **File:** `accrue_portal/mix.exs`
- **Change:** `{:accrue, "== #{@version}"}` → `{:accrue, "~> #{@version}"}` inside the `ACCRUE_PORTAL_HEX_RELEASE == "1"` branch of `accrue_dep/0`. The `else` branch (`{:accrue, path: "../accrue"}`) is untouched.
- **Verify:** `cd accrue_portal && mix compile` succeeds (see "mix compile verification" below).
- **Commit:** `afff2018`

### Task 2: Correct the CLAUDE.md accrue dependency row
- **File:** `CLAUDE.md`
- **Change:** The `:accrue` row in `### Core Technologies — accrue_admin package` now reads Version Constraint `~> <same version>` and a rewritten Rationale describing the real contract: sibling dep via `path:` in dev, same-minor constraint (`~> #{@version}`) in published releases, release-please `linked-versions` keeping the minor in lockstep across all three packages while allowing core patch releases to flow to adopters, enforced by `scripts/ci/verify_release_manifest_alignment.sh`.
- **Verify:** `grep -c '`~> <same version>`' CLAUDE.md` → `1`. Diff confirmed to touch exactly that one table row (`git diff CLAUDE.md` shows a single `-`/`+` pair).
- **Commit:** `2e55670a`

### Task 3: Assert the sibling operator in the merge-blocking release manifest script
- **File:** `scripts/ci/verify_release_manifest_alignment.sh`
- **Change:** Added `check_sibling_accrue_dep()`, called for both `accrue_admin/mix.exs` and `accrue_portal/mix.exs`, after the existing manifest/@version lockstep assertions and before the final `OK:` echo. For each file it:
  - Selects lines containing `{:accrue, "` whose line, after the `grep -n` prefix, does NOT have `#` as its first non-whitespace character (comment-line exclusion only — inline `#{@version}` interpolation is never touched).
  - Requires exactly one such line (fails naming the file on 0 or >1 matches).
  - Trims the matched line and requires it to equal exactly `{:accrue, "~> #{@version}"}` (a single `EXPECTED_ACCRUE_DEP` variable holds this string so it appears once).
  - Uses the existing `fail()` helper and `[verify_release_manifest_alignment] ...` message style; each failure names the offending file, what was found, and what was expected.
- The closing `OK:` line was extended to also report that both sibling packages declare the interpolated same-minor constraint.
- **Commit:** `9f309871`

## Mandatory Verification (verbatim terminal output)

### 1. Baseline: script exits 0 after the changes

```
$ bash scripts/ci/verify_release_manifest_alignment.sh
OK: release manifest and mix.exs @version aligned at 1.4.0 (accrue, accrue_admin, accrue_portal); accrue_admin and accrue_portal both declare the interpolated same-minor accrue constraint ({:accrue, "~> #{@version}"})
EXIT:0
```

### 2. Negative control A — exact-pin restored in `accrue_portal/mix.exs`

Command: `sed -i '' 's/{:accrue, "~> #{@version}"}/{:accrue, "== #{@version}"}/' accrue_portal/mix.exs`, then:

```
$ bash scripts/ci/verify_release_manifest_alignment.sh
[verify_release_manifest_alignment] accrue_portal/mix.exs: sibling accrue dependency declared as '{:accrue, "== #{@version}"}', expected '{:accrue, "~> #{@version}"}' (same-minor operator interpolating @version, not a hardcoded version literal)
EXIT:1
```

Confirmed: exits non-zero, message names `accrue_portal/mix.exs`. Restored via `git checkout -- accrue_portal/mix.exs`; `git diff --quiet accrue_portal/mix.exs` confirmed clean.

### 3. Negative control B — hardcoded version literal in `accrue_admin/mix.exs`

Command: `sed -i '' 's/{:accrue, "~> #{@version}"}/{:accrue, "~> 1.4.0"}/' accrue_admin/mix.exs`, then:

```
$ bash scripts/ci/verify_release_manifest_alignment.sh
[verify_release_manifest_alignment] accrue_admin/mix.exs: sibling accrue dependency declared as '{:accrue, "~> 1.4.0"}', expected '{:accrue, "~> #{@version}"}' (same-minor operator interpolating @version, not a hardcoded version literal)
EXIT:1
```

Confirmed: exits non-zero, message names `accrue_admin/mix.exs`. Restored via `git checkout -- accrue_admin/mix.exs`; `git diff --quiet accrue_admin/mix.exs` confirmed clean.

### 4. Additional (not required, extra assurance): multi-match decoy line

To confirm the "exactly one match" requirement is itself enforced (not just the content comparison), a second, non-comment `{:accrue, "~> 9.9.9"}` line was temporarily inserted immediately after the real declaration in `accrue_admin/mix.exs`:

```
$ bash scripts/ci/verify_release_manifest_alignment.sh
[verify_release_manifest_alignment] accrue_admin/mix.exs: found 2 sibling accrue dependency declarations matching '{:accrue, "...'; expected exactly 1 matching '{:accrue, "~> #{@version}"}'
EXIT:1
```

Restored via full-file copy from a pre-edit backup; confirmed clean.

### 5. Post-restore re-verification: exit 0 proves clean restores

```
$ git status --porcelain accrue_admin/mix.exs accrue_portal/mix.exs
(no output — both files clean)
$ bash scripts/ci/verify_release_manifest_alignment.sh
OK: release manifest and mix.exs @version aligned at 1.4.0 (accrue, accrue_admin, accrue_portal); accrue_admin and accrue_portal both declare the interpolated same-minor accrue constraint ({:accrue, "~> #{@version}"})
EXIT:0
```

### 6. `mix compile` in accrue_portal (dev `path:` branch unaffected)

`mix` is available (`asdf` shim, Elixir/Erlang per `.tool-versions`). First run required `mix deps.get` (a pre-existing, unrelated gap: the committed `accrue_portal/mix.lock` is missing a lock entry for the transitive `jose` package — present before any of this task's edits, confirmed via `git show HEAD~3:accrue_portal/mix.lock | grep jose` returning nothing). After `mix deps.get`:

```
$ cd accrue_portal && mix compile
==> jose
Compiling 113 files (.erl)
Compiling 8 files (.ex)
Generated jose app
==> accrue
Compiling 96 files (.ex)
Generated accrue app
==> accrue_portal
Compiling 23 files (.ex)
Generated accrue_portal app
```

Re-ran a second time (after the negative controls, with `accrue_portal/mix.exs` back to the Task 1 state) to reconfirm:

```
$ cd accrue_portal && mix deps.get && mix compile
... (deps already resolved from local hex cache)
==> accrue
Generated accrue app
==> accrue_portal
Compiling 9 files (.ex)
Generated accrue_portal app
EXIT:0
```

`accrue_portal/mix.lock` was regenerated by `mix deps.get` as a side effect (adds the missing `jose` entry). Per the SCOPE BOUNDARY rule (only auto-fix issues directly caused by this task's changes; this lock gap pre-dates the task and is unrelated to the `==`→`~>` operator change), `accrue_portal/mix.lock` was reverted via `git checkout -- accrue_portal/mix.lock` and is NOT part of this task's commits. It is logged here as a pre-existing, deferred repo-hygiene item, not fixed by this task.

## Deviations from Plan

None affecting the three committed files — plan executed exactly as written for Tasks 1–3.

**Out-of-scope observation (not fixed, logged only):** `accrue_portal/mix.lock`, as currently committed on this branch, is missing a lock entry for the transitive `jose` Hex package, causing a bare `mix compile` to fail with "the dependency is not locked" until `mix deps.get` is run once. This is unrelated to the sibling-operator change (confirmed present in `mix.lock` three commits prior to this task) and was left untouched per the SCOPE BOUNDARY rule.

## Self-Check

```
$ git log --oneline --all | grep -q afff2018 && echo FOUND || echo MISSING
FOUND
$ git log --oneline --all | grep -q 2e55670a && echo FOUND || echo MISSING
FOUND
$ git log --oneline --all | grep -q 9f309871 && echo FOUND || echo MISSING
FOUND
$ [ "$(grep -c '{:accrue, "~> #{@version}"}' accrue_portal/mix.exs)" -eq 1 ] && echo FOUND || echo MISSING
FOUND
$ [ "$(grep -c '`~> <same version>`' CLAUDE.md)" -eq 1 ] && echo FOUND || echo MISSING
FOUND
$ grep -q 'check_sibling_accrue_dep' scripts/ci/verify_release_manifest_alignment.sh && echo FOUND || echo MISSING
FOUND
```

## Self-Check: PASSED
