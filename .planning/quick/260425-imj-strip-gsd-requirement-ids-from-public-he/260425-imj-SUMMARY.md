---
status: complete
quick_id: 260425-imj
slug: strip-gsd-requirement-ids-from-public-he
date: 2026-04-25
commit: c855743
files_changed: 51
edits: ~80 individual rewrites across @moduledoc / @doc strings
---

# Quick Task 260425-imj: Strip GSD requirement IDs from public hexdocs — SUMMARY

## What changed

Public hexdocs at https://hexdocs.pm/accrue/api-reference.html#modules
showed internal GSD requirement IDs in module/function summary strings,
e.g. "Accrue.Auth — Behaviour + facade for host-app auth integration
(AUTH-01, AUTH-02)." These IDs are meaningful for internal traceability
to `.planning/REQUIREMENTS.md` but cryptic to external developers
reading the published docs.

The fix:

- Removed parenthesized req-ID artifacts (`(AUTH-01)`, `(MAIL-04)`,
  `(BILL-12, BILL-13)`, etc.) from all `@moduledoc` and `@doc` strings
  across `accrue/lib/` and `accrue_admin/lib/`.
- Reworded surrounding prose where the IDs were load-bearing in the
  sentence structure (e.g. "Phase 3 (PROC-02)" → "deferred", "Phase 1
  ships..." → "default ships...").
- Cleaned up a small set of error-message strings in
  `accrue/lib/accrue/mailer/default.ex` that pointed back into the
  moduledoc with stale ID references.
- Preserved internal traceability: private `# ...` line-comments in
  function bodies and module-internal scaffolding still carry their
  req-IDs, and `.planning/` artifacts are unchanged.
- Preserved cryptographic / encoding constants that look superficially
  similar to req-IDs (`HMAC-256`, `SHA-256`, `UTF-8`, `ISO-8601`,
  `RFC-7231`, `HTTP-200`, etc.).

## Files changed

51 files touched across `accrue/lib/`. Eleven files from the original
`/tmp/hexdocs-cleanup-files.txt` list (62 entries) had no docstring
artifacts in scope — only private `# ...` comments, which were
correctly preserved (notably `accrue/lib/accrue/processor.ex`,
`accrue/lib/accrue/processor/fake.ex`, `accrue/lib/accrue/billing.ex`
top-level, several jobs files, and the three `accrue_admin/lib/copy*`
files which use `@moduledoc false` and inline `# ...` comments).

## Verification transcripts

### 1. Verification 1 — parenthesized req-IDs in @moduledoc/@doc lines

```
$ rg -n -e '@moduledoc|@doc' accrue/lib accrue_admin/lib | rg -e '\([A-Z]{2,5}-[0-9]{2,}'
(no output)
$ echo $?
1
```

PASS — zero matches (rg exit=1 on no-match is the success case).

### 2. Verification 2 — bare req-IDs on @moduledoc/@doc lines

```
$ rg -n -e '@moduledoc|@doc' accrue/lib accrue_admin/lib | \
    rg -e '(AUTH|BIL|BILL|BHOOK|CHKT|EVT|INV|MAIL|OBAN|OBS|OPS|PDF|PII|PROC|RAW|READ|REPO|ROUTE|SCA|TEST|UI|WH|WR|MOUNT|NOT|FND|ADM|ADMIN|DX|CLDR)-[0-9]{2,}'
(no output)
$ echo $?
1
```

PASS — zero matches.

### 3. Verification 3 — legit constants preserved (count)

Baseline (pre-edit): 1 (`UTF-8` in
`accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex:5`).

```
$ rg -n -e 'HMAC-[0-9]+|SHA-[0-9]+|UTF-[0-9]+|ISO-[0-9]+|RFC-[0-9]+|HTTP-[0-9]+' accrue/lib accrue_admin/lib | wc -l
       1
```

PASS — count unchanged at 1; the `UTF-8` reference in
`mix/tasks/accrue_admin.export_copy_strings.ex` is still intact.

### 4. Verification 4 — `mix compile --warnings-as-errors` from `accrue/`

```
$ cd accrue && mix compile --warnings-as-errors
Compiling 52 files (.ex)
Generated accrue app
```

PASS — zero warnings, compiled cleanly.

### 5. Verification 5 — `mix test` from `accrue/`

```
$ cd accrue && mix test
...
Finished in 7.0 seconds (3.1s async, 3.8s sync)
46 properties, 1169 tests, 0 failures (11 excluded)
```

PASS — 1169 tests + 46 property tests pass with zero failures, 11
excluded (pre-existing, unrelated).

### 6. Verification 6 — `mix docs` from `accrue/`

```
$ cd accrue && mix docs 2>&1 | rg -i 'error|warning' | head
(no output)
```

PASS — no doc-generation errors or warnings.

## Bonus: deeper docstring-body scan

The verification regexes above scope to lines starting with `@moduledoc`
or `@doc`, which doesn't catch artifacts on the second-and-later lines
of a multi-line moduledoc body. Belt-and-suspenders Python scan walks
every `@moduledoc/`@doc/`@typedoc` body in `accrue/lib` and
`accrue_admin/lib`:

```
$ python3 -c '...scan code...'
docstring-body req-ID hits: 0
```

PASS — zero req-IDs anywhere inside any docstring body.

## Bonus: also compiles cleanly from `accrue_admin/`

```
$ cd accrue_admin && mix compile --warnings-as-errors
==> accrue
Compiling 52 files (.ex)
Generated accrue app
==> accrue_admin
Compiling 1 file (.ex)
Generated accrue_admin app
```

PASS.

## Commit

`c855743 docs(hexdocs): strip GSD requirement-ID artifacts from public docs`

51 files changed, 186 insertions(+), 195 deletions(-).

## Self-Check: PASSED

All 6 acceptance criteria pass. Internal traceability via private
comments + `.planning/` artifacts is preserved. Hexdocs at
https://hexdocs.pm/accrue/api-reference.html will render clean
prose without internal scaffolding leaks on the next release.
