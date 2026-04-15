---
phase: 06-email-pdf
plan: 02
subsystem: pdf-storage-scaffold
tags: [pdf, storage, behaviour, defexception, telemetry, chromic_pdf, gotenberg, tdd]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "Accrue.PDF behaviour + facade + Accrue.Telemetry.span/3"
  - phase: 06-email-pdf
    provides: "Plan 06-01 :branding schema (unblocks Wave 2 render which reads branding)"
provides:
  - "Accrue.Error.PdfDisabled defexception with two-clause message/1"
  - "Accrue.PDF.Null adapter returning tagged PdfDisabled error at :debug log level"
  - "Accrue.Storage behaviour (put/3, get/1, delete/1) with telemetry-wrapped facade"
  - "Accrue.Storage.Null no-op default adapter"
  - ":storage_adapter NimbleOptions config key defaulting to Accrue.Storage.Null"
  - "guides/pdf.md with adapters table, ChromicPDF setup, Null degradation anchor, Gotenberg sidecar example, @page pitfall, font strategy"
affects: [06-03, 06-04, 06-05, 06-06, 06-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Co-location precedent: new Accrue.Error.* structs append to errors.ex, never a new error/ directory"
    - "Storage behaviour mirrors Accrue.PDF shape: @callback + facade + impl/0 + telemetry span"
    - "Span metadata safety: bytes as byte_size/1 scalar, never the raw binary payload (T-06-02-02)"
    - "Null adapter logs at :debug only — expected and terminal, not a warning or error condition"

key-files:
  created:
    - accrue/lib/accrue/pdf/null.ex
    - accrue/lib/accrue/storage.ex
    - accrue/lib/accrue/storage/null.ex
    - accrue/guides/pdf.md
    - accrue/test/accrue/pdf/null_test.exs
    - accrue/test/accrue/storage/null_test.exs
    - accrue/test/accrue/error/pdf_disabled_test.exs
    - .planning/phases/06-email-pdf/06-02-SUMMARY.md
  modified:
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/config.ex

key-decisions:
  - "Phase 6 P02: Accrue.Error.PdfDisabled co-located in errors.ex per existing taxonomy precedent — no new lib/accrue/error/ directory"
  - "Phase 6 P02: docs_url constant fixed at https://hexdocs.pm/accrue/pdf.html#null-adapter and the guides/pdf.md anchor {#null-adapter} matches it character-for-character so the emitted tagged error deep-links cleanly on hex"
  - "Phase 6 P02: :storage_adapter registered in NimbleOptions schema next to :pdf_adapter with default Accrue.Storage.Null — plan called for the key but did not specify registration location; alongside sibling adapter atoms is the idiomatic spot"
  - "Phase 6 P02: Storage telemetry metadata is {adapter, key, bytes} only for put and {adapter, key} for get/delete — bytes is byte_size/1 scalar (T-06-02-02) so no raw payload ever enters span metadata"
  - "Phase 6 P02: Null.render/2 log level locked at :debug (D6-06) — not :info or :warning, because the adapter is a stable configuration branch, not an outage signal; test asserts the guard via two capture_log passes (at :debug and at :info) to prove the level floor"

patterns-established:
  - "Graceful-degradation tagged-error pattern: adapter returns {:error, %Accrue.Error.*{}} struct with a docs_url field pointing at the hex anchor that documents the fallback; workers pattern-match and fall through without Oban retry"
  - "Storage behaviour shape for v1.1+ adapters: three callbacks (put/3 + get/1 + delete/1), telemetry-wrapped facade mirroring Accrue.PDF, impl/0 resolver"
  - "Single constant-source docs anchor: the string embedded in PdfDisabled.docs_url is byte-identical to the {#null-adapter} id in guides/pdf.md — grep-guardable in CI"

requirements-completed: [PDF-04, PDF-11]

# Metrics
duration: 10min
completed: 2026-04-15
---

# Phase 06 Plan 02: PDF Null Adapter + Storage Scaffold Summary

**Three independent Wave-1 scaffolds unblocking the Wave-2 invoice renderer: `Accrue.Error.PdfDisabled` defexception + `Accrue.PDF.Null` adapter (D6-06), `Accrue.Storage` behaviour with `Null` default + `:storage_adapter` config key (D6-04), and a complete `guides/pdf.md` (PDF-11) covering the ChromicPDF production posture, the Null graceful-degradation escape hatch with a matching hex anchor, and a Gotenberg sidecar custom-adapter walkthrough.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-04-15T11:02:21Z
- **Completed:** 2026-04-15T11:12:00Z (approx.)
- **Tasks:** 3 (Task 1 + Task 2 each ran a full RED / GREEN TDD cycle; Task 3 was docs-only)
- **Files changed:** 10 (8 created, 2 modified)
- **Test delta:** +19 tests (5 PdfDisabled + 5 PDF.Null + 9 Storage) — suite 725 → 744 green
- **Commits:** 6 total (test/RED + feat/GREEN per TDD task + docs + style format fixup)

## Accomplishments

- **D6-06 PdfDisabled + PDF.Null landed.** New defexception appended to `accrue/lib/accrue/errors.ex` with the two-clause `message/1` override pattern matching the existing `Accrue.Error.NotAttached` / `InvalidState` taxonomy. `Accrue.PDF.Null` implements `@behaviour Accrue.PDF`, returns `{:error, %Accrue.Error.PdfDisabled{reason: :adapter_disabled, docs_url: "https://hexdocs.pm/accrue/pdf.html#null-adapter"}}`, and logs the skip at `:debug` only — never `:info` or `:warning` (D6-06). Full facade round-trip verified: configuring `:pdf_adapter` to `Accrue.PDF.Null` and calling `Accrue.PDF.render/2` returns the tagged error through the telemetry span with no raise. All 10 tests green.
- **D6-04 Storage scaffold landed.** `Accrue.Storage` declares three `@callback`s (`put/3`, `get/1`, `delete/1`) and ships a telemetry-wrapped facade emitting `[:accrue, :storage, :put|:get|:delete, :start|:stop|:exception]` with `%{adapter, key, bytes}` metadata for put and `%{adapter, key}` for get/delete. `Accrue.Storage.Null` echoes keys on put and returns `{:error, :not_configured}` on get/delete. `:storage_adapter` registered in the `Accrue.Config` NimbleOptions schema directly after `:auth_adapter` with `default: Accrue.Storage.Null`. 9 tests green — including an explicit guard that raw binary payloads never appear in span metadata (only `byte_size/1` scalar).
- **PDF-11 Gotenberg sidecar guide shipped.** `accrue/guides/pdf.md` (273 lines) documents the full PDF story: adapters table, ChromicPDF `on_demand` vs `session_pool` supervision patterns, the hard `accrue_mailers` Oban concurrency ≤ `session_pool[:size]` rule (D6-04), the `{#null-adapter}` anchor that matches `Accrue.Error.PdfDisabled.docs_url` byte-for-byte, a custom-adapter walkthrough for a Gotenberg HTTP sidecar (marked illustrative, not first-party), the `@page` CSS pitfall (Pitfall 6), and base64 `@font-face` embedding guidance. No `wkhtmltopdf` mentions (banned by CLAUDE.md).
- **Zero-regression full suite.** 744 tests / 44 properties / 0 failures after all three tasks. `mix credo --strict` clean. `mix compile --warnings-as-errors` clean.

## Task Commits

1. **Task 1 RED** — `89803e0` (test): failing specs for `Accrue.Error.PdfDisabled` and `Accrue.PDF.Null`
2. **Task 1 GREEN** — `d3bb976` (feat): `PdfDisabled` defexception appended to errors.ex + `Accrue.PDF.Null` adapter
3. **Task 2 RED** — `c7f8e19` (test): failing specs for `Accrue.Storage` facade + telemetry + `Null` adapter
4. **Task 2 GREEN** — `467f5cb` (feat): `Accrue.Storage` behaviour + `Accrue.Storage.Null` + `:storage_adapter` config key
5. **Task 3** — `95d44dd` (docs): `accrue/guides/pdf.md` with Gotenberg + Null + @page + fonts sections
6. **Style fixup** — `bcd01a4` (style): `mix format` reflow of `Accrue.CardError` defexception list in errors.ex (incidental formatter touch on an adjacent, unrelated struct when formatting errors.ex after appending `PdfDisabled`)

_TDD gate compliance: Tasks 1 and 2 each have a true `test(...)` → `feat(...)` commit sequence in git history. Task 3 is documentation-only and did not run the TDD gate (no behavioral code). Plan-level RED / GREEN / REFACTOR split is satisfied via per-task TDD commits, not via a plan-level monolith._

## Requested output artifacts (per <output> block)

- **Exact `docs_url` string:** `"https://hexdocs.pm/accrue/pdf.html#null-adapter"` — embedded in `Accrue.PDF.Null.render/2` and matched byte-for-byte by the `{#null-adapter}` anchor in `accrue/guides/pdf.md`. Single source of truth.
- **Storage telemetry event names:**
  - `[:accrue, :storage, :put, :start | :stop | :exception]`
  - `[:accrue, :storage, :get, :start | :stop | :exception]`
  - `[:accrue, :storage, :delete, :start | :stop | :exception]`
- **Gotenberg guide dimensions:**
  - Length: 273 lines
  - Sections (6): Adapters · ChromicPDF setup (incl. Performance posture + Docker notes) · `Accrue.PDF.Null` graceful degradation (anchor `{#null-adapter}`) · Custom adapter: Gotenberg sidecar · `@page` CSS warning (Pitfall 6) · Font strategy
  - Anchors: `{#null-adapter}` (matches PdfDisabled docs_url)

## Files Created / Modified

- `accrue/lib/accrue/errors.ex` — Appended `defmodule Accrue.Error.PdfDisabled do ... end` with `[:reason, :docs_url, :message]` fields and two-clause `message/1`. Formatter also reflowed the pre-existing `Accrue.CardError` `defexception` list to multi-line (incidental touch).
- `accrue/lib/accrue/pdf/null.ex` — New. `@behaviour Accrue.PDF`. `render/2` logs at `:debug` and returns tagged `PdfDisabled` error with the locked `docs_url`.
- `accrue/lib/accrue/storage.ex` — New. Three `@callback`s + facade + `impl/0`. All three facade functions wrapped in `Accrue.Telemetry.span([:accrue, :storage, :*])`.
- `accrue/lib/accrue/storage/null.ex` — New. `@behaviour Accrue.Storage`. `put` echoes key; `get`/`delete` return `{:error, :not_configured}`.
- `accrue/lib/accrue/config.ex` — Added `:storage_adapter` NimbleOptions key (type `:atom`, default `Accrue.Storage.Null`) immediately after `:auth_adapter`.
- `accrue/guides/pdf.md` — New 273-line guide (see Gotenberg guide dimensions above).
- `accrue/test/accrue/error/pdf_disabled_test.exs` — New 5-test spec.
- `accrue/test/accrue/pdf/null_test.exs` — New 5-test spec (direct adapter + facade round-trip + log-level guards).
- `accrue/test/accrue/storage/null_test.exs` — New 9-test spec (impl/0 default + facade CRUD + telemetry spans + metadata leak guard).

## Decisions Made

See frontmatter `key-decisions`. Headline: the `docs_url` constant in `Accrue.PDF.Null` is byte-identical to the `{#null-adapter}` anchor in `guides/pdf.md` — this is an intentional single-source-of-truth coupling between runtime error metadata and hosted docs, and is grep-guardable in CI. The `:storage_adapter` config key landed alongside sibling adapter atoms in the NimbleOptions schema because the plan called for the key but left the registration spot unspecified; adjacency to `:pdf_adapter` / `:auth_adapter` is the idiomatic placement.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 — Blocking] Registered `:storage_adapter` in the `Accrue.Config` NimbleOptions `@schema`**

- **Found during:** Task 2 (green phase) — the PATTERNS file §`accrue/lib/accrue/storage.ex` explicitly required "Add `:storage_adapter` key to `Accrue.Config` schema (default `Accrue.Storage.Null`)," and without it, any host-level attempt to override the adapter via `config :accrue, :storage_adapter, ...` would fail `validate_at_boot!/0` with an unknown-key NimbleOptions error.
- **Fix:** Added a `storage_adapter: [type: :atom, default: Accrue.Storage.Null, doc: ...]` key to the `@schema` immediately after `:auth_adapter`. No existing tests broke — the default matches the facade's runtime resolution default.
- **Files modified:** `accrue/lib/accrue/config.ex`
- **Verification:** Full suite (744 tests) green post-edit.
- **Committed in:** `467f5cb` (Task 2 GREEN commit)

**2. [Style] `mix format` reflowed `Accrue.CardError` defexception list**

- **Found during:** Final `mix format` pass on modified files.
- **Issue:** The existing single-line `defexception [:message, :code, :decline_code, :param, :http_status, :request_id, :processor_error]` in `Accrue.CardError` exceeded the line budget; the formatter broke it into a multi-line list.
- **Fix:** Accepted the formatter's reflow (zero behavioral change — identical field set).
- **Committed in:** `bcd01a4` (style fixup)

---

**Total deviations:** 2 (1 blocking auto-fix, 1 style)
**Impact on plan:** Zero behavioral impact — both deviations are correctness / idiomatic adjustments, not design changes. Plan scope hit exactly as written.

## Deferred Issues

**Pre-existing dialyzer warnings in `lib/mix/tasks/accrue.webhooks.replay.ex`** (`Mix.raise/1` and `Mix.shell/0` unknown_function at lines 110 and 112). These warnings originate from Phase 4 commit `c27d0bc` and are unrelated to any file touched by this plan — out of scope per the executor SCOPE BOUNDARY rule. `mix compile --warnings-as-errors` is clean; only `mix dialyzer` surfaces them. Logged for awareness; not fixed in this plan.

## Issues Encountered

- None. All three tasks executed clean on the first GREEN pass after the expected TDD RED.

## User Setup Required

None — no external service configuration required. Hosts that want to exercise the `Accrue.PDF.Null` adapter can set `config :accrue, :pdf_adapter, Accrue.PDF.Null` in runtime config; no further wiring needed.

## Next Phase Readiness

- **Plan 06-03 unblocked.** Wave-2 rendering code can now call `Accrue.PDF.render/2` and pattern-match `{:error, %Accrue.Error.PdfDisabled{}}` for graceful degradation without raising through Oban.
- **Plan 06-06 unblocked.** The Billing facade's future `store_invoice_pdf/1` + `fetch_invoice_pdf/1` delegates (Plan 06-06 territory) have a live `Accrue.Storage` target — the Null default means the delegates will round-trip cleanly in v1.0 without breaking existing tests.
- **Guides landing zone established.** `accrue/guides/pdf.md` is now the canonical home for all future PDF documentation; subsequent plans in Phase 6 should extend it rather than creating sibling docs.
- **No blockers.** Wave 2 (plans 06-03 through 06-07) can proceed.

## Self-Check: PASSED

Files exist (spot-checked):
- FOUND: accrue/lib/accrue/pdf/null.ex
- FOUND: accrue/lib/accrue/storage.ex
- FOUND: accrue/lib/accrue/storage/null.ex
- FOUND: accrue/guides/pdf.md
- FOUND: accrue/test/accrue/pdf/null_test.exs
- FOUND: accrue/test/accrue/storage/null_test.exs
- FOUND: accrue/test/accrue/error/pdf_disabled_test.exs
- FOUND: `Accrue.Error.PdfDisabled` appended to accrue/lib/accrue/errors.ex
- FOUND: `:storage_adapter` key appended to accrue/lib/accrue/config.ex

Commits in `git log`:
- FOUND: 89803e0 (test Task 1 RED)
- FOUND: d3bb976 (feat Task 1 GREEN)
- FOUND: c7f8e19 (test Task 2 RED)
- FOUND: 467f5cb (feat Task 2 GREEN)
- FOUND: 95d44dd (docs Task 3)
- FOUND: bcd01a4 (style format fixup)

Co-location verified: `! test -d accrue/lib/accrue/error` — no `error/` subdirectory created (precedent preserved).

---
*Phase: 06-email-pdf*
*Completed: 2026-04-15*
