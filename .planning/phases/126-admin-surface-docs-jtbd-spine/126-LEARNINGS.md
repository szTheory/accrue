---
phase: 126
phase_name: "admin-surface-docs-jtbd-spine"
project: "Accrue"
generated: "2026-05-24"
counts:
  decisions: 13
  lessons: 9
  patterns: 11
  surprises: 6
missing_artifacts:
  - "UAT.md"
---

# Phase 126 Learnings: admin-surface-docs-jtbd-spine

## Decisions

### Seam returns `{resolved, unmapped}` pair, never a boolean
`Accrue.Entitlements.Admin.resolve_for_customer/1` returns a `{resolved_map, unmapped_price_ids}` tuple. The resolved map can never show drift because `handle_unmapped/3 :deny` silently discards unmapped price_ids, so the unmapped list is re-derived independently and returned alongside.

**Rationale:** Keeps the read-only diagnostic seam clear of the deferred `fetch_entitled/2` gate-API trap (D-04 / D-07) — the admin tab gets resolved entitlement state AND the drift the resolved map can never surface.
**Source:** 126-01-SUMMARY.md

### Single fold, zero copy — `fold_for_customer/1` literally calls `fold_active/1`
The seam's fold helper delegates directly to the private `fold_active/1` rather than re-implementing resolution.

**Rationale:** The admin diagnostic and the gate share one resolution path and structurally cannot drift from grant/deny truth (T-126-02 / PITFALLS #2).
**Source:** 126-01-SUMMARY.md

### LocalMap resolver hard-coded for the diagnostic
The admin seam hard-codes the `LocalMap` resolver; custom resolvers are out of scope for the read-only diagnostic.

**Rationale:** Documented A2 limitation — the read-only diagnostic does not need pluggable-resolver support, and adding it would widen surface area for no operator benefit.
**Source:** 126-01-SUMMARY.md

### No new public `Accrue.*` gate API; two `@doc false` delegations; one-way dependency
`entitlements.ex` stayed unchanged (still 4 public defs). The seam is a new `Accrue.Entitlements.Admin` module plus two `@doc false` LocalMap delegations, with a machine-verified one-way `admin -> billing` dependency (no reverse reference).

**Rationale:** A read-only diagnostic must never widen the gate API or invite a fail-open gate; keeping it additive and one-directional preserves the fail-closed contract (D-04).
**Source:** 126-01-SUMMARY.md

### Resolved-first then drift render order (D-02)
The entitlements tab renders resolved truth first (active plans → granted features → seats & limits → grace) in one card, then a separate "Plan mapping" card badging unmapped price_ids amber. The drift card always renders (an "all clear" note when nothing is unmapped).

**Rationale:** An operator reads grant truth before drift; always rendering the drift card makes "no drift" an explicit, legible state rather than an absence.
**Source:** 126-02-SUMMARY.md

### No count badge on the entitlements tab (D-01)
`tab_counts/1` deliberately omits an `:entitlements` key, so `tabs/4`'s `Map.get` returns `nil` and the `:if`-gated count badge never renders.

**Rationale:** Entitlements are a derivation, not a countable collection like payment methods; a count badge would be meaningless. `:entitlements` already exists as a config atom, so `String.to_existing_atom/1` stays safe.
**Source:** 126-02-SUMMARY.md

### VERIFY-01 three-part copy contract
Every operator string flows through `Copy.Entitlements` (`@doc false` 0-arity fns) → `Copy.entitlements_*` defdelegates → export-task allowlist. Zero hardcoded strings in the template.

**Rationale:** Keeps all UI copy centralized, exportable, and audit-verifiable; the export task is the contract enforcement point.
**Source:** 126-02-SUMMARY.md

### Summarize-and-link, defer truth one direction (D-07 / D-08)
`entitlements.md` inlines only ~6 reader-critical lifecycle rows and links out to the SSOTs (`lifecycle_semantics.md`, `Accrue.Processor.Capabilities`); truth flows toward the guide, never back. Grace nuance kept out, linked only.

**Rationale:** Hub-and-spoke docs prevent SSOT drift (T-126-10) — re-deriving a truth table in the guide would create a second source that can diverge from code.
**Source:** 126-03-SUMMARY.md

### Public JTBD flip done via prose + new body section, not a table-row flip
The public `jobs_to_be_done.md` had no entitlements ⛔ *table* row (entitlements was prose-only there), so the scope flip was satisfied by reworded prose plus a new "Gate access on what they paid for" body section. The literal ⛔→✅ table-row flips live only in the internal `JTBD-FRONTIER.md`.

**Rationale:** Honest flip across both artifacts without fabricating a table row that never existed in the public doc.
**Source:** 126-03-SUMMARY.md

### First Hour spine left untouched (D-12)
ROADMAP SC#3 names "First Hour" among the spines that should reference the entitlements guide, but the phase deliberately left First Hour's verifier-pinned numbered spine intact and added discoverability pointers to README "Start here" and quickstart instead.

**Rationale:** Entitlements is a derivation over billing, not an install step; adding it would bloat the verifier-pinned First Hour spine (126-DISCUSSION-LOG Option B over Option A). Recorded as an explicit override in VERIFICATION frontmatter for audit clarity.
**Source:** 126-VERIFICATION.md

### Byte-for-byte pinned shipped marker `entitlements ✅ shipped`
The post-flip marker string was pinned exactly (leading lowercase `entitlements`, U+2705 ✅ glyph, trailing `shipped`) in the dated 2026-05-23 Update-log entry, so the Plan 04 verifier needle could `grep -F` match it literally.

**Rationale:** A `grep -F` needle must byte-match the authored string; coordinating the exact marker between the doc-authoring plan (03) and the verifier plan (04) prevents a false-fail.
**Source:** 126-03-SUMMARY.md, 126-04-SUMMARY.md

### Flip-guard scoped to the unique removed phrase, not "headline gap" (D-14)
The `require_absent_regex` flip-guard targets the scoped scope-prose phrase `on the table** is **entitlements` rather than the broader "headline gap" wording.

**Rationale:** A broad guard could be defeated by the historical append-only Update log (which legitimately preserves old wording); scoping to the uniquely-removed phrase makes the guard precise and un-defeatable (T-126-12).
**Source:** 126-04-SUMMARY.md

### Seed-co-update invariant (D-15)
Every file a new verifier needle references must be added to `seed_tmp_dir!`'s `copy_fixture!` list in the same plan that adds the needle. Plan 04 added `entitlements.md` and `jobs_to_be_done.md` to the seed list alongside the new needles.

**Rationale:** The negative-drift fixture tests seed then mutate a file; a needle pointing at an unseeded file fails "No such file" rather than testing drift (T-126-11).
**Source:** 126-04-SUMMARY.md

---

## Lessons

### Unmapped re-derivation must exclude `:expired` rows (WR-01)
The independent unmapped-drift list initially included expired-grace rows; the fix (`local_map.ex:119`) excludes `:expired` so the drift surface only reflects genuinely-active-but-unmapped subscriptions.

**Context:** Surfaced by code review (WR-01) after the initial summaries reported GREEN; the drift surface must mirror the same lifecycle filtering the resolver applies.
**Source:** 126-VERIFICATION.md

### A diagnostic tab can crash render on a raising resolver (CR-01 BLOCKER)
With `unmapped_action: :raise`, the resolver raises, and the entitlements tab crashed on render. The fix guards `entitlements_view/1` with try/rescue returning `{:ok, ...}` / `:error` and renders a fail-closed error card on `:error`.

**Context:** Code review found a BLOCKER (CR-01) after summaries reported all-GREEN — the configured `:raise` path was an unhandled render-time failure mode. Fix backed by WR-03 test coverage.
**Source:** 126-VERIFICATION.md

### The `unmapped_action: :raise` path needs explicit coverage at both seam and LiveView (WR-03)
Initial tests covered mapped/unmapped/empty/grace but not the `:raise` configuration. Coverage was added at the seam (`admin_test.exs`) and the LiveView (`entitlements_live_test.exs`, asserting the error copy renders without crash).

**Context:** A configured-but-untested code path (`:raise`) hid the CR-01 render crash; the lesson is to enumerate every config value of a knob as a test case.
**Source:** 126-VERIFICATION.md (commit 7efc449)

### Drift-only customers need a clean empty state (WR-02)
A customer with drift but no resolved entitlements needed a clean empty-state render rather than an awkward half-empty first card.

**Context:** Edge case not anticipated in the resolved-first/drift-second layout; surfaced in review.
**Source:** 126-VERIFICATION.md (commit 8f9ff9b)

### HEEx escapes apostrophes — assert on apostrophe-free fragments
A copy string containing `subscription's` renders as `subscription&#39;s` in HEEx output, so a raw `html =~ Copy.entitlements_unmapped_hint()` assertion fails. Assert on an apostrophe-free tail fragment instead.

**Context:** First test run of the LiveView test failed on this; the badge/price_id/title all rendered correctly — only the apostrophe-bearing assertion broke.
**Source:** 126-02-SUMMARY.md

### JsonViewer mangles raw MapSets — convert to sorted lists before rendering
Passing resolved MapSets straight to JsonViewer renders `%{"__struct__" => "MapSet"}`. A display-map helper (`entitlements_display_map/1`) converts each MapSet to a sorted plain list first.

**Context:** Pitfall 2 — the raw-map disclosure needs clean list output, not struct internals.
**Source:** 126-02-SUMMARY.md

### Sibling `mix.lock` drift between `accrue` and `accrue_admin` blocks compile
`accrue/mix.exs` required `rendro ~> 0.3.0` (lock pinned 0.3.0) but `accrue_admin/mix.lock` pinned a stale 0.1.0, so `accrue_admin` would not compile. `mix deps.get` in `accrue_admin` reconciled the lock.

**Context:** Pre-existing path-dep lockfile drift, not caused by the plan's edits; in a monorepo the admin lock must track the core lock for shared transitive deps.
**Source:** 126-02-SUMMARY.md

### `verify_package_docs.sh` reports only the FIRST missing needle
When two needles were dropped on one PROJECT.md line, the script reported only the first (`gateway subscription core`), masking the second (`Accrue.Billing.subscribe/3`) until the first was fixed.

**Context:** Plan 04's mental model assumed one fix made the verifier green; in fact a second masked needle existed (already restored by the orchestrator in 5635d77). First-failure-only reporting hides co-located drift.
**Source:** 126-04-SUMMARY.md

### Executor cwd is the repo root, not the mix subproject
Verify commands written as `cd accrue && mix ...` must actually `cd` into the subproject; the executor's working directory is `/Users/jon/projects/accrue`. A RED check appeared to misfire on Plan 01 purely because of a missing `cd` into the `accrue` mix project.

**Context:** Recurred across Plan 01 and Plan 02; not a test problem — a working-directory assumption. Always run `cd accrue`/`cd accrue_admin` explicitly.
**Source:** 126-01-SUMMARY.md, 126-02-SUMMARY.md

---

## Patterns

### Internal read-only diagnostic seam
A new dedicated module (`Accrue.Entitlements.Admin`) plus `@doc false` delegations on the resolver, never a new public `Accrue.*` function.

**When to use:** When admin/operator tooling needs to read internal state without widening the public/contract API or risking a fail-open path.
**Source:** 126-01-SUMMARY.md

### Read-through-the-SSOT-fold
The admin diagnostic reuses the resolver's `fold_active/1` directly rather than re-implementing resolution logic.

**When to use:** Whenever a second surface needs the "same answer" as an authoritative computation — delegate to the one fold so the two can never diverge.
**Source:** 126-01-SUMMARY.md

### Independent drift re-derivation
Surface the inputs a computation structurally discards (here, the entitling price_ids dropped under `:deny`) by re-deriving them from the same source data (`catalog()` / `active_items()` + `Enum.reject(Map.has_key?)`).

**When to use:** When the primary result silently drops information an operator needs to see (drift, rejected rows, filtered records).
**Source:** 126-01-SUMMARY.md

### Read-only admin diagnostic tab
Clone the richest existing sibling tab clause (here `payment_methods`), call the core read seam exactly once via a private helper, render-only — reusing only existing components and structural CSS classes. Zero new component, CSS, route, or auth surface.

**When to use:** Adding an operator view over existing data; inherits the parent LiveView's auth mount and visual system for free.
**Source:** 126-02-SUMMARY.md

### VERIFY-01 three-part copy contract
Copy submodule (`@doc false` 0-arity fns) → `defdelegate` shortnames → export-task allowlist entries; zero hardcoded operator strings in templates.

**When to use:** Any admin/UI surface where copy must be centralized, exportable for review/localization, and machine-verifiable.
**Source:** 126-02-SUMMARY.md

### Compute the LiveView view into a socket assign for render purity (WR-04)
Resolve the entitlements result in `handle_params` and store it as `@entitlements_view`, rather than calling the seam from the render function. Render reads the assign only.

**When to use:** When a render path would otherwise call into a context/seam that can be slow or can raise — move the call to a lifecycle callback and keep render pure.
**Source:** 126-VERIFICATION.md

### Summarize-and-link, hub-and-spoke docs
A guide inlines only the few reader-critical facts and links out to the SSOT docs for the rest; truth flows one direction (toward the guide), never re-derived.

**When to use:** Authoring a guide that overlaps an authoritative reference — link instead of copy to prevent drift.
**Source:** 126-03-SUMMARY.md

### Append-only dated Update logs
Prior dated entries are preserved verbatim; each new dated entry supersedes without rewriting history. Active prose carries the current truth; the log carries the trail.

**When to use:** Docs that need an honest evolution trail (scope flips, shipped markers) without losing the historical record.
**Source:** 126-03-SUMMARY.md

### SSOT-mirror discipline — labels and their verifier needles ship together
Doc labels (authored in one plan) and the `verify_package_docs.sh` needles that pin them (authored in a sibling plan) ship in the same phase, with needles re-read from the on-disk docs to byte-match.

**When to use:** Any doc-contract where a CI verifier asserts on literal doc strings — co-ship the assertion with the asserted content.
**Source:** 126-04-SUMMARY.md

### Seed-co-update invariant for fixture-based verifier tests
Every file a new needle references is added to the test's `seed_tmp_dir!` copy list in the same change.

**When to use:** Verifier tests that seed-then-mutate fixtures — a needle on an unseeded file fails "No such file" instead of testing drift.
**Source:** 126-04-SUMMARY.md

### `grep -F` literal needles re-read from on-disk docs
Use `grep -F` (literal, not regex) needles and re-read the actual authored string from disk before pinning, so brackets/parens/emoji glyphs (e.g. U+2705 ✅) match byte-for-byte.

**When to use:** Pinning doc strings that contain regex-significant or non-ASCII characters.
**Source:** 126-04-SUMMARY.md

---

## Surprises

### Plan 04's baseline was already GREEN before it started
The plan assumed Plan 03's D-13 fix alone made the verifier exit 0, but the v1.39 milestone-start rewrite had dropped *two* PROJECT.md needles on one line; the orchestrator had already restored the second (`Accrue.Billing.subscribe/3`) in commit 5635d77 during the Wave 1 post-merge gate.

**Impact:** No PROJECT.md edit was needed in Plan 04; the plan's prerequisite-state note had to be reconciled against reality before Task 1. Verified `verify_package_docs.sh` exit 0 + verifier test 8/0 before touching anything.
**Source:** 126-04-SUMMARY.md

### The 6 pre-existing PackageDocsVerifier failures auto-greened
Each of the 6 RED negative-drift fixtures short-circuited on the missing PROJECT.md phrase *before* reaching its own mutation; once the phrase was restored they all passed without per-test changes.

**Impact:** A single upstream fix (the PROJECT.md phrase) cleared 6 seemingly-independent failing tests — the failures were a shared-precondition artifact, not 6 distinct bugs.
**Source:** 126-04-SUMMARY.md

### The public `jobs_to_be_done.md` was untracked in git
The public JTBD doc had never been committed; it had to be `git add`-ed (Pitfall 3) as part of the flip so the verifier seed and needles could reference a tracked file.

**Impact:** A doc the project treated as "public" was invisible to git/CI until this phase; the flip plan had to commit it before the verifier could pin it.
**Source:** 126-03-SUMMARY.md

### Public JTBD had no entitlements ⛔ table row at all
Entitlements was prose-only in `jobs_to_be_done.md`, so the planned "flip the scope-table row ⛔→✅" instruction had no literal target there.

**Impact:** The flip was satisfied by reworded prose + a new body section; the actual table-row flips happened only in the internal `JTBD-FRONTIER.md` (which does carry gap + delta tables).
**Source:** 126-03-SUMMARY.md

### Code review surfaced a render-crash BLOCKER after summaries reported all-GREEN
All four plan summaries reported clean GREEN execution, but the post-execution code review (126-REVIEW.md) found a BLOCKER (CR-01: tab crashes on a raising resolver) plus four warnings (WR-01..04).

**Impact:** Real fixes landed after the summaries — guarded `entitlements_view/1`, `:expired` exclusion, drift-only empty state, render-purity assign, and `:raise`-path tests. Underscores that "tests GREEN" ≠ "all configured paths covered."
**Source:** 126-VERIFICATION.md

### Test counts drifted upward post-review
The seam test grew from 6 → 9 and the LiveView test from 3 → 4 after the review-driven `:raise`/error-copy coverage was added, and the core suite count shifted (1462 → 1465 at verification).

**Impact:** The verification snapshot does not match the execution summaries' counts — a reminder that the summaries capture initial execution, while verification captures the post-review state. Default-seed runs still surface the one known-flaky PdfTest (dodge with `--seed 0`).
**Source:** 126-VERIFICATION.md (vs 126-01/02/04-SUMMARY.md)
