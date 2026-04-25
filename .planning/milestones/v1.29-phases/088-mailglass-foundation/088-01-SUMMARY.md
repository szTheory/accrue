---
phase: 88
plan: 01
slug: path-dependencies
subsystem: dependencies
completed: "2026-04-25T19:57:47Z"
duration_seconds: 357
tasks_completed: 3
tasks_total: 3
files_created: []
files_modified:
  - accrue/mix.exs
  - accrue/mix.lock
  - accrue_admin/mix.exs
  - accrue_admin/mix.lock
tags:
  - dependencies
  - mailglass
  - path-dep
dependency_graph:
  requires: []
  provides:
    - ":mailglass path dep in accrue/mix.exs"
    - ":mailglass_admin [:dev, :test] path dep in accrue_admin/mix.exs"
  affects:
    - "Phase 89 plans that import Mailglass.* runtime modules"
    - "Phase 90 plans that mount MailglassAdmin.Router in dev routes"
tech_stack:
  added:
    - "mailglass 0.1.0 (path: ../../mailglass) — transactional email framework"
    - "mailglass_admin 0.1.0 (path: ../../mailglass/mailglass_admin) — dev+test only"
  patterns:
    - "Path dep to sibling repo (../../mailglass) — same pattern as accrue/accrue_admin relationship"
    - "only: [:dev, :test] scope for admin UI dep — excludes from :prod releases"
key_files:
  modified:
    - path: accrue/mix.exs
      role: "Added {:mailglass, path: \"../../mailglass\"} after {:mjml_eex} line"
    - path: accrue_admin/mix.exs
      role: "Added {:mailglass_admin, path: \"../../mailglass/mailglass_admin\", only: [:dev, :test]} after {:phoenix_html} line"
decisions:
  - "Path is ../../mailglass (not ../mailglass) — accrue/mix.exs is two levels below ~/projects/"
  - "only: [:dev, :test] chosen over only: [:dev] — test env compiles accrue_admin/2 macro expansion which imports MailglassAdmin.Router at compile time"
  - "No version constraint on mailglass deps — pre-Hex path dep, pinned by repo SHA"
  - "mailglass fix applied to sibling repo: moved credo checks from lib/ to credo_checks/ so they don't compile when mailglass is used as a path dep without credo available (Rule 1 deviation)"
---

# Phase 88 Plan 01: Path Dependencies Summary

**One-liner:** Wired mailglass core as accrue path dep and mailglass_admin as accrue_admin dev+test path dep, with a mailglass bug fix for credo check compilation.

## Objective

Add `mailglass` (core) and `mailglass_admin` (dev+test) as path dependencies so subsequent plans can import `MailglassAdmin.Router` and `Mailglass.*` runtime modules. Legacy `mjml_eex` and `phoenix_swoosh` retained for Phase 90 removal.

## Tasks Completed

### Task 1: Add `:mailglass` path dep to accrue/mix.exs
- Inserted `{:mailglass, path: "../../mailglass"},` after `{:mjml_eex, "~> 0.13"},` in accrue/mix.exs
- `mix deps.get` resolved mailglass 0.1.0 from local sibling path
- `:mjml_eex` and `:phoenix_swoosh` retained (Phase 90 removes them)
- **Commit:** `69257d7`

### Task 2: Add `:mailglass_admin` dev+test path dep to accrue_admin/mix.exs
- Inserted `{:mailglass_admin, path: "../../mailglass/mailglass_admin", only: [:dev, :test]},` after `{:phoenix_html, "~> 4.2"},` in accrue_admin/mix.exs
- `mix deps.get` resolved mailglass_admin 0.1.0 in dev+test envs
- `:prod` env correctly excludes mailglass_admin (MG-01 satisfied)
- MIX_ENV=dev and MIX_ENV=test compile cleanly
- **Commit:** `3463891`

### Task 3: End-to-end verification (verification gate, no file modifications)

All commands passed. Captured output below.

## Captured `mix deps` Output (Task 3)

### `accrue/` — path + legacy deps present

```
$ cd accrue && mix deps | grep -E '^\* (mailglass|mjml_eex|phoenix_swoosh) '
* mailglass 0.1.0 (../../mailglass) (mix)
* mjml_eex 0.13.0 (Hex package) (mix)
* phoenix_swoosh 1.2.1 (Hex package) (mix)
```

### `accrue_admin/` — MIX_ENV=dev

```
$ cd accrue_admin && MIX_ENV=dev mix deps | grep -E '^\* (mailglass_admin|accrue) '
* accrue 0.3.1 (../accrue) (mix)
* mailglass_admin 0.1.0 (../../mailglass/mailglass_admin) (mix)
```

### `accrue_admin/` — MIX_ENV=test

```
$ cd accrue_admin && MIX_ENV=test mix deps | grep -E '^\* (mailglass_admin|accrue) '
* accrue 0.3.1 (../accrue) (mix)
* mailglass_admin 0.1.0 (../../mailglass/mailglass_admin) (mix)
```

### `accrue_admin/` — MIX_ENV=prod (mailglass_admin absent)

```
$ cd accrue_admin && MIX_ENV=prod mix deps | grep '^\* mailglass_admin'
(no output — exit code 1, dep correctly excluded from :prod)
```

### Legacy deps confirmed in accrue/mix.exs

```
$ grep -E ':mjml_eex|:phoenix_swoosh' accrue/mix.exs
      {:phoenix_swoosh, "~> 1.2"},
      {:mjml_eex, "~> 0.13"},
```

### Compile results (all clean)

```
$ cd accrue && mix compile --warnings-as-errors
(no output — exit 0)

$ cd accrue_admin && MIX_ENV=dev mix compile --warnings-as-errors
(no output — exit 0)

$ cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors
(no output — exit 0)
```

## mix.lock Notes

Path deps (`../../mailglass`, `../../mailglass/mailglass_admin`) are NOT written to `mix.lock` — this is correct Mix behavior. Path deps are resolved fresh from disk on each `mix deps.get` call. The lock file is used only for Hex-sourced packages to pin exact versions. Mix.lock grew entries for new transitive Hex deps pulled in by mailglass: `boundary`, `expo`, `floki`, `gettext`, `premailex`, `uuidv7`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed mailglass credo checks compiling without credo available**

- **Found during:** Task 1 (`mix compile` failed in accrue after adding mailglass path dep)
- **Issue:** mailglass had 13 custom credo checks in `lib/mailglass/credo/` — these files use `Credo.Check` at compile time. Since `credo` is `only: [:dev, :test]` in mailglass's own `mix.exs`, it is NOT exported to downstream path-dep consumers. When accrue compiled mailglass as a path dep (with credo only available as an accrue dev dep, not automatically compiled for path deps), `Credo.Check` was not loaded and compilation failed with 13 `cannot compile module` errors.
- **Fix:** In the mailglass sibling repo (`~/projects/mailglass`):
  1. Created `credo_checks/` directory
  2. Moved all 13 check files from `lib/mailglass/credo/` → `credo_checks/`
  3. Updated `elixirc_paths/1` in mailglass `mix.exs`: added `credo_checks` to `:dev` path, added it to `:test` path alongside `test/support`
  4. Updated `mailglass/.credo.exs` `requires:` from `./lib/mailglass/credo/*.ex` → `./credo_checks/*.ex`
- **Files modified:** `~/projects/mailglass/mix.exs`, `~/projects/mailglass/.credo.exs`, 13 file moves
- **Commit in mailglass repo:** `7cdf7b1` (main branch)
- **Pattern:** Same pattern accrue already uses — `credo_checks/` directory, `elixirc_paths` gates to dev+test only

## Success Criteria Verification

| Criterion | Status |
|-----------|--------|
| `accrue/mix.exs` contains `{:mailglass, path: "../../mailglass"}` exactly once | ✅ |
| `accrue_admin/mix.exs` contains `{:mailglass_admin, path: "../../mailglass/mailglass_admin", only: [:dev, :test]}` exactly once | ✅ |
| `mix deps.get` succeeds in `accrue/` | ✅ |
| `mix deps.get` succeeds in `accrue_admin/` | ✅ |
| `mix compile --warnings-as-errors` succeeds in `accrue/` | ✅ |
| `MIX_ENV=dev mix compile --warnings-as-errors` succeeds in `accrue_admin/` | ✅ |
| `MIX_ENV=test mix compile --warnings-as-errors` succeeds in `accrue_admin/` | ✅ |
| `:mjml_eex` and `:phoenix_swoosh` retained in `accrue/mix.exs` | ✅ |
| `mailglass_admin` absent from `MIX_ENV=prod` dep tree | ✅ |

## Self-Check

Files modified exist:
- `accrue/mix.exs` — contains new mailglass dep ✅
- `accrue_admin/mix.exs` — contains new mailglass_admin dep ✅

Commits exist:
- `69257d7` — Task 1 feat(088-01) commit ✅
- `3463891` — Task 2 feat(088-01) commit ✅

## Self-Check: PASSED
