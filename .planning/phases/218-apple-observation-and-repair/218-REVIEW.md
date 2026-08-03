---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T21:10:19Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - accrue/lib/accrue/entitlements/apple/notification_plug.ex
  - accrue/lib/accrue/router.ex
  - accrue/guides/webhooks.md
  - accrue/test/fixtures/apple/server_evidence.exs
  - accrue/test/accrue/entitlements/apple_notification_test.exs
  - accrue/lib/accrue/entitlements/apple/reconciliation.ex
  - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  - scripts/ci/verify_executable_uat_contract.mjs
  - .github/workflows/ci.yml
  - scripts/ci/README.md
  - CLAUDE.md
findings:
  critical: 4
  warning: 2
  info: 0
  total: 6
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-08-03T21:10:19Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The Apple route and reconciliation code preserve the local-lineage versus provider-transaction distinction in the reviewed path. The new merge-blocking executable-UAT enforcement, however, both blocks CI in the submitted tree and can be satisfied by untrusted hand-authored artifacts. The notification endpoint also persists arbitrary unauthenticated payloads and its advertised body limit is applied after the raw body has already been captured.

## Critical Issues

### CR-01: The new merge-blocking CI job fails on the submitted repository state

**File:** `.github/workflows/ci.yml:104`
**Issue:** The workflow unconditionally runs `--all-since 218`, but Phase 218 has 16 `status: complete` summaries and lacks `218-UAT.md`; its committed `218-VERIFICATION.md` is also `status: gaps_found` with `behavior_unverified: 1`. Running the exact new CI command fails immediately with `missing automated UAT artifact`. Consequently every non-scheduled push/PR is blocked until artifacts outside this change are manually repaired.
**Fix:** Generate and commit the Phase 218 UAT only after correcting its verification report, or defer/condition the project-wide gate until the phase is actually complete. Add a CI fixture that exercises the repository’s current Phase 218 state so this cannot be merged while permanently red.

### CR-02: A hand-written UAT can bypass the executable-coverage policy

**File:** `scripts/ci/verify_executable_uat_contract.mjs:140`
**Issue:** Validation only checks that an existing UAT has syntactically plausible `source: automated`, nonempty `verification:`, and `[pass]` fields (lines 140-156). It never regenerates the expected artifact or compares its tests, results, and references with the completed summary coverage. A contributor can commit a one-test UAT containing a made-up command and `[pass]`, while omitting failed/required coverage, and the zero-human-UAT gate passes.
**Fix:** During validation, derive the expected UAT content from the summary coverage and require byte-for-byte equality (or parse both and require an exact normalized mapping of coverage IDs, refs, and pass statuses). Do not accept author-controlled UAT result fields as independent evidence.

### CR-03: Incomplete plan summaries are silently excluded from phase validation

**File:** `scripts/ci/verify_executable_uat_contract.mjs:119`
**Issue:** Both `coverageEntries` (line 43) and `validatePhaseDirectory` skip every SUMMARY whose frontmatter status is not exactly `complete`. Therefore a phase directory with one incomplete/failed plan summary and one complete summary can still generate a passing UAT and validation result for only the completed plan. This turns an incomplete phase into an apparently passed zero-human-UAT phase.
**Fix:** Treat any SUMMARY in an in-scope phase whose status is not `complete` as a validation failure, and require the generated UAT to cover every SUMMARY. If partial phases need to exist, exclude their directory from CI through an explicit, reviewed lifecycle manifest rather than silently filtering files.

### CR-04: Invalid signatures are durably stored and acknowledged as success

**File:** `accrue/lib/accrue/entitlements/apple/notification_plug.ex:63`
**Issue:** Every verifier error except `:invalid_payload` and the retryable set is sent to `quarantine/4`, which writes an Intake/Lineage row keyed by the submitted body digest and returns HTTP 200 (lines 63-79). This includes `:invalid_signature`, `:invalid_chain`, and `:invalid_header`. An unauthenticated caller can send unbounded unique malformed JWS bodies to consume persistent database rows; the default rate limiter is permissive (line 21). The test at `apple_notification_test.exs:178-220` explicitly codifies this behavior.
**Fix:** Return 400 without persistence for signature, chain, header, algorithm, and application-identity failures. Reserve durable quarantine for authenticated but operationally unprocessable Apple evidence, and require an explicit production rate limiter as defense in depth.

## Warnings

### WR-01: Generated UAT output is nondeterministic when `verified:` is absent

**File:** `scripts/ci/verify_executable_uat_contract.mjs:87`
**Issue:** `generateAutomatedUat` falls back to `new Date().toISOString()` for both output timestamps. A valid verification artifact without optional `verified:` produces a different committed UAT on every `--write` invocation, defeating deterministic artifact generation and creating needless CI/review churn.
**Fix:** Require a valid `verified:` timestamp before generation, or use a deterministic source such as the verification file’s committed timestamp. Add a self-test that generates twice from an artifact without `verified:` and asserts rejection or identical output.

### WR-02: The Apple body-size limit is enforced only after full raw-body capture

**File:** `accrue/lib/accrue/entitlements/apple/notification_plug.ex:134`
**Issue:** The plug reconstructs `conn.assigns[:raw_body]` before applying `max_body_bytes` (lines 135-150). That capture was already read by `CachingBodyReader`; the documented pipeline at `accrue/guides/webhooks.md:23-29` does not set a parser `length` at all. A caller can therefore force substantially more than the advertised 256 KiB to be buffered/decoded before receiving 413, creating avoidable request-memory pressure.
**Fix:** Document and enforce a route-scoped `Plug.Parsers` `length` no greater than the notification maximum (with a small protocol allowance only if necessary), and pass the same configured limit to both parser and plug. Add an integration test proving oversize input is rejected by the parser/body reader without a full raw capture.

---

_Reviewed: 2026-08-03T21:10:19Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
