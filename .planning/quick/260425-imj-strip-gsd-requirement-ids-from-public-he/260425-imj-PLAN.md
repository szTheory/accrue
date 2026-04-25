---
quick_id: 260425-imj
slug: strip-gsd-requirement-ids-from-public-he
description: Strip GSD requirement-ID artifacts (AUTH-01, MAIL-04, BILL-12, etc.) from public @moduledoc / @doc strings so hexdocs reads cleanly to outside developers
date: 2026-04-25
status: planned
mode: quick
files_touched_estimate: 62 files in accrue/lib + accrue_admin/lib
must_haves:
  - "Public hexdocs (@moduledoc and @doc) strings no longer contain parenthesized GSD req-IDs like (AUTH-01), (MAIL-03), (BILL-04, BILL-07)"
  - "Module/function descriptions remain accurate and readable after the IDs are dropped"
  - "Internal traceability is preserved by leaving req-ID references in private comments (# ...) and in .planning/ artifacts"
  - "mix compile --warnings-as-errors clean from accrue/ and accrue_admin/"
  - "mix test passes from accrue/ (no behavioural changes; pure docstring edits)"
  - "Cryptographic / encoding constants that LOOK like req-IDs (HMAC-256, SHA-256, UTF-8, ISO-8601, JSON-RPC, HTTP-200) are NOT modified"
---

# Quick Task 260425-imj: Strip GSD requirement IDs from public hexdocs

## Why

User flagged that public hexdocs at https://hexdocs.pm/accrue/api-reference.html#modules
shows internal GSD requirement IDs (AUTH-01, AUTH-02, MAIL-04, BILL-12, etc.)
embedded in module summary strings. Example:

> Accrue.Auth — Behaviour + facade for host-app auth integration (AUTH-01, AUTH-02).

The "(AUTH-01, AUTH-02)" suffix is meaningful internally (traceability to
.planning/REQUIREMENTS.md row IDs) but cryptic to public readers. It must be
removed from the public-facing surfaces while keeping internal traceability
in non-doc comments and planning artifacts.

## Scope

62 files in `accrue/lib/` and `accrue_admin/lib/` have at least one
`@moduledoc` or `@doc` block containing a parenthesized requirement-ID
pattern. File list captured at `/tmp/hexdocs-cleanup-files.txt` and listed
inline in Task 1.

## Task 1: Strip req-ID artifacts from public docstrings

**Affected paths:** `accrue/lib/**/*.ex` and `accrue_admin/lib/**/*.ex` —
specifically the 62 files where `@moduledoc` or `@doc` contains a token
matching the requirement-ID pattern.

### Rewrite rules

1. **Standalone parenthesized IDs at end of sentence:**
   - Before: `Behaviour + facade for host-app auth integration (AUTH-01, AUTH-02).`
   - After:  `Behaviour + facade for host-app auth integration.`
   - Drop the parenthetical entirely.

2. **Parenthesized ID with leading separator inside a sentence:**
   - Before: `Multi-item subscription surface (BILL-12).`
   - After:  `Multi-item subscription surface.`
   - Drop the parenthetical and the trailing period stays.

3. **Inline parenthesized IDs:**
   - Before: `surface (TEST-01): time-sensitive billing logic`
   - After:  `surface: time-sensitive billing logic`
   - Drop the parenthetical without leaving a double-space.

4. **Phase + parenthesized ID:**
   - Before: `deferred to Phase 3 (PROC-02) — Phase 1 only proves the behaviour`
   - After:  `deferred to a later phase — Phase 1 only proves the behaviour`
   - Replace "Phase N (XXX-NN)" with "a later phase" or "this phase" depending
     on tense. Pure phase-number references without IDs (e.g. "Phase 3" alone)
     also need to go since they'll mean nothing publicly. Reword if the surrounding
     prose still makes sense.

5. **Multi-ID lists:**
   - Before: `# subscribe/2..3 (BILL-03, BILL-04, BILL-07)`
   - After:  `# subscribe/2..3`
   - Same rule. Drop the parenthetical entirely.

6. **`@doc "Fixture for X (MAIL-NN)."` pattern (in `accrue/lib/accrue/emails/fixtures.ex`):**
   - Before: `@doc "Fixture for \`Accrue.Emails.Receipt\` (MAIL-03)."`
   - After:  `@doc "Fixture for \`Accrue.Emails.Receipt\`."`

7. **Conversational phase-history references:**
   - Before: `Phase 4 (BILL-27) mirrors only the fields the admin...`
   - After:  Reword to "The admin mirrors only the fields..." — drop the
     phase-history flavour entirely from public docs. (Phase numbers are
     internal scaffolding; readers don't care about them.)

### What to PRESERVE (do NOT modify)

- `# ...` private comments (single-line) inside function bodies — these are
  internal scaffolding and can keep req-IDs for traceability. Only docstrings
  (`@moduledoc`, `@doc`) are publicly rendered.
- Cryptographic / encoding constants and protocol names. The grep regex
  `[A-Z]{2,5}-[0-9]{2,}` matches some legitimate strings:
    - `HMAC-256`, `SHA-256`, `RSA-2048` — cryptographic primitives
    - `UTF-8` (1 digit, won't match), `ISO-8601`, `RFC-7231`, `RFC-3339`
    - `HTTP-200`, `HTTP-401`, etc. — HTTP status codes
    - `JSON-1.0`, `JSON-RPC` — protocol names
  When in doubt, leave the token alone. The req-IDs follow a small finite
  set of prefixes used in `.planning/REQUIREMENTS.md`. Active prefixes
  (verified via grep against actual planning artifacts):
    - `AUTH-`, `BIL-`, `BILL-`, `BHOOK-`, `CHKT-`, `CLDR-`, `DX-`, `EVT-`,
      `INV-`, `MAIL-`, `OBAN-`, `OBS-`, `OPS-`, `PDF-`, `PII-`, `PROC-`,
      `RAW-`, `READ-`, `REPO-`, `ROUTE-`, `SCA-`, `TEST-`, `UI-`, `WH-`,
      `WR-`, `MOUNT-`, `NOT-`, `FND-`, `ADM-`, `ADMIN-`
  Outside this prefix set, treat as a non-req-ID and leave alone.

- Test files in `test/` and any non-`lib/` paths. The grep already scoped
  to `lib/`, but the executor must NOT chase req-IDs into test fixtures
  or assertions.

### Read-first

For each affected file, the executor MUST read the surrounding @moduledoc /
@doc context before editing — many files have multi-paragraph moduledocs
where req-IDs appear in middle-paragraph "## Section" headings or bullet
lists. Mechanical sed will produce broken sentences; thoughtful per-file
edits are required.

### Acceptance criteria

After edits:

1. `rg -nE '@moduledoc|@doc' accrue/lib accrue_admin/lib | rg -E '\([A-Z]{2,5}-[0-9]{2,}'`
   returns ZERO lines (no req-ID parenthetical inside any moduledoc/doc).

2. `rg -nE '@moduledoc|@doc' accrue/lib accrue_admin/lib | rg -E '(AUTH|BIL|BILL|BHOOK|CHKT|EVT|INV|MAIL|OBAN|OBS|OPS|PDF|PII|PROC|RAW|READ|REPO|ROUTE|SCA|TEST|UI|WH|WR|MOUNT|NOT|FND|ADM|ADMIN|DX|CLDR)-[0-9]{2,}'`
   returns ZERO lines (no bare req-ID either).

3. `rg -nE 'HMAC-[0-9]+|SHA-[0-9]+|UTF-[0-9]+|ISO-[0-9]+|RFC-[0-9]+|HTTP-[0-9]+' accrue/lib accrue_admin/lib`
   still returns the same number of lines as before (legit constants preserved).

4. From `accrue/`: `mix compile --warnings-as-errors` exits 0.

5. From `accrue/`: `mix test` passes (no test failures; this is a pure
   docstring change with no behavioural impact).

6. From `accrue/`: `mix docs` runs cleanly (or the pre-existing baseline
   set of doc warnings, no NEW warnings).

## Task 2: Commit atomically

Single commit covering all touched files. Conventional message:
`docs: drop GSD requirement-ID artifacts from public moduledocs`.

## Acceptance evidence

- All 6 acceptance criteria green (capture in SUMMARY.md).
- Hexdocs verification (sample): `rg '@moduledoc' accrue/lib/accrue/auth.ex`
  shows clean prose, no `(AUTH-01, AUTH-02)`.
- Git log shows ONE commit with the docstring changes.
