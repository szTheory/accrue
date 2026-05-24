---
phase: 126-admin-surface-docs-jtbd-spine
plan: 03
subsystem: docs
tags: [entitlements, docs, jtbd, ssot, fail-closed]
requirements: [ENT-12]
dependency-graph:
  requires:
    - "Phase 123 fail-closed gate API (Accrue.Entitlements 4-fn) + [:accrue, :entitlements, :check] telemetry"
    - "Phase 124 Accrue.Plug.RequireEntitlement + require_feature/require_plan macros + Accrue.Live.Entitlements on_mount"
    - "Phase 125 entitling?/1 lifecycle SSOT + past_due_grace knob + Processor.Capabilities entitlements row"
    - "Plan 02 admin entitlements tab at /customers/:id?tab=entitlements (the In-admin pointer target)"
  provides:
    - "guides/entitlements.md — authoritative entitlements guide (needles: entitled?, Accrue.Plug.RequireEntitlement, [:accrue, :entitlements, :check])"
    - "Public JTBD ⛔→✅ flip (jobs_to_be_done.md) + internal mirror (JTBD-FRONTIER.md)"
    - "README + quickstart entitlements spine pointers (Plan 04 needles 1 + 6)"
    - "PROJECT.md 'gateway subscription core' phrase (clears verify_package_docs.sh:220 RED holdout, prereq for ENT-12 SC#4)"
    - "Post-flip shipped marker 'entitlements ✅ shipped' (Plan 04 needle 5a — pin byte-for-byte)"
  affects:
    - "126-04 (verifier needles + seed fixtures pin these doc files)"
tech-stack:
  added: []
  patterns:
    - "Summarize-and-link, defer truth one direction (D-07/D-08): truth flows lifecycle_semantics.md/Processor.Capabilities -> entitlements.md, never back"
    - "Fail-closed-first doc voice: the only path to true is an affirmative resolved match"
    - "Append-only dated Update logs: prior dated entries preserved verbatim; new entry supersedes"
key-files:
  created:
    - accrue/guides/entitlements.md
    - .planning/phases/126-admin-surface-docs-jtbd-spine/126-03-SUMMARY.md
  modified:
    - accrue/guides/jobs_to_be_done.md
    - .planning/research/JTBD-FRONTIER.md
    - accrue/README.md
    - accrue/guides/quickstart.md
    - .planning/PROJECT.md
decisions:
  - "Public jobs_to_be_done.md had no entitlements ⛔ table row (entitlements was prose-only there); the prose flip + new 'Gate access' body section fully cover the public scope flip. The ⛔→✅ TABLE-row flips live only in internal JTBD-FRONTIER.md (which has the gap-table + delta-table rows)."
  - "Pinned post-flip shipped marker string: 'entitlements ✅ shipped' (Plan 04 needle 5a). Lives in the dated 2026-05-23 Update-log entry of jobs_to_be_done.md."
  - "Preserved the historical 2026-05-22 'headline gap' Update-log entry in JTBD-FRONTIER.md verbatim (append-only log convention); the active prose + new 2026-05-23 entry carry the flip. jobs_to_be_done.md's 'headline gap' was actively reworded out (Pitfall 4)."
metrics:
  duration: ~10min
  tasks: 3
  files: 7
  completed: 2026-05-23
---

# Phase 126 Plan 03: Entitlements Docs + JTBD Spine Summary

Authored `guides/entitlements.md` (fail-closed-first, summarize-and-link to the lifecycle + provider SSOTs), flipped the entitlements JTBD ⛔→✅ honestly across the public `jobs_to_be_done.md` and the internal `JTBD-FRONTIER.md` mirror, added one entitlements spine pointer each to README and quickstart, and inserted the literal `gateway subscription core` phrase into PROJECT.md that clears the pre-existing `verify_package_docs.sh` RED holdout.

## Post-flip shipped marker (Plan 04 needle 5a — PIN BYTE-FOR-BYTE)

```
entitlements ✅ shipped
```

This exact string lives in the dated **2026-05-23** entry of the `## Update log` in `accrue/guides/jobs_to_be_done.md` (the line begins `- **2026-05-23** — entitlements ✅ shipped (v1.39): ...`). Plan 04's needle 5a must pin this byte-identical marker. Note the leading lowercase `entitlements`, the U+2705 ✅ emoji, and the trailing word `shipped`.

## What shipped

### Task 1 — `guides/entitlements.md` (commit e2a321a)
New 266-line guide (≤ connect.md's ~414), mirroring connect.md's skeleton and webhooks.md's defer-truth voice. Nine sections in D-06 order:
1. `# Entitlements — gate features on what they paid for`
2. Fail-closed easy path leads: `if Accrue.entitled?(user, :pro), do: render_pro(), else: upsell()` — states the only path to `true` is an affirmative resolved match (needle: `entitled?`).
3. `## Configure the catalog` — `plans` / `unmapped_action: :deny` / `past_due_grace`.
4. `## Gate a controller route` — contains `Accrue.Plug.RequireEntitlement` (needle) + `require_feature`/`require_plan` macros + opaque-403 default + `on_deny`/`deny_path`.
5. `## Gate a LiveView` — `Accrue.Live.Entitlements` `on_mount`, conditionally compiled.
6. `## Lifecycle truth` — inlines ~6 reader-critical rows, then defers to `lifecycle_semantics.md#lifecycle--entitlement-truth-table` (grace nuance kept OUT, linked only, D-07).
7. `## Provider honesty` — prose only, links `Accrue.Processor.Capabilities` (NOT the internal `.planning` matrix, A1).
8. `## Telemetry` — contains `[:accrue, :entitlements, :check]` (needle, pinned ONCE here) + metadata keys + "subject_id internal-only never PII; per-check telemetry-only never ledgered".
9. `## Related guides` — links OUT to lifecycle_semantics.md, telemetry.md, auth_adapters.md, and the admin tab (hub-and-spoke, D-08).

### Task 2 — JTBD ⛔→✅ flip in both artifacts + commit the untracked public file (commit 3bab780)
**Public `jobs_to_be_done.md`** (was untracked, now committed — Pitfall 3):
- New `## Gate access on what they paid for` body section inserted between `## The customer changes their mind` and `## When payments fail`, cloning the body-section shape (bold The-job line → prose → elixir snippet → In-admin pointer to the Entitlements tab → Deep dive `[Entitlements](entitlements.md)`).
- Scope-and-maturity prose flipped: dropped the exact `on the table** is **entitlements` flip-guard phrase; replaced with honest "core entitlements ✅ shipped ... optional Stripe-native sync ... deferred, off-by-default (Phase 127)".
- Update log: reworded to drop "headline gap"; appended dated 2026-05-23 entry with the `entitlements ✅ shipped` marker.

**Internal `JTBD-FRONTIER.md`** (D-11, re-verified cells against shipped code):
- TL;DR → "6 of 6 shipped".
- Coverage-map Operator & platform gap row ⛔→✅ with deferred-sync note.
- Delta-table Accrue cell ⛔→✅ (comparator columns left ⛔ — Pay/Cashier genuinely lack it).
- Diminishing-returns reading-of-delta prose, ASCII chart, definition-of-done, honest-summary, and future-JTBD list all rewritten ("6 of 6"; entitlements struck from the ranked list; dunning depth promoted to #1).
- Dated 2026-05-23 Update-log entry appended.

### Task 3 — Spine pointers + PROJECT.md D-13 (commit 22cdbab)
- README "Start here": one peer bullet `[Entitlements](guides/entitlements.md)` (Plan 04 needle 1, byte-for-byte).
- quickstart focused-guides: one bullet `[Entitlements](entitlements.md)` (relative, no `guides/` prefix — Plan 04 needle 6).
- `first_hour.md` numbered spine UNCHANGED (D-12 — confirmed clean in git status).
- PROJECT.md PROC-08 posture: inserted literal `gateway subscription core` (grep -F match for `verify_package_docs.sh:220`).

## Deviations from Plan

None — plan executed exactly as written. One clarification (not a deviation): the public `jobs_to_be_done.md` never contained an entitlements ⛔ *table* row (entitlements was prose-only in that file), so "flip the scope-table row ⛔→✅" was satisfied by the prose flip + new body section. The actual ⛔→✅ table-row flips are in the internal `JTBD-FRONTIER.md` (gap table + delta table), which were flipped.

## Authentication Gates

None — docs-only plan, no external auth required.

## Known Stubs

None. All five docs are complete, runnable-snippet-backed, and SSOT-linked. The deferred optional Stripe-native sync is documented as deferred/off-by-default (Phase 127), which is an intentional, dated scope statement — not a stub.

## Threat-model adherence

- **T-126-08 (fail-open guidance):** entitlements.md LEADS with the fail-closed easy path; no fail-open snippet appears anywhere.
- **T-126-09 (over-claiming / internal leakage):** public docs use the honest "core shipped / optional sync deferred off-by-default (Phase 127)" phrasing; deferred/future roadmap items stay in JTBD-FRONTIER.md (internal) only.
- **T-126-10 (SSOT drift):** lifecycle truth links lifecycle_semantics.md (entitling?/1 SSOT, grace nuance deferred); provider honesty is prose + Processor.Capabilities link — no re-derived truth table.
- **T-126-SC (supply-chain):** zero package installs (docs only).

## Verification

- `cd accrue && mix docs` → exit 0, `doc/entitlements.html` (35 KB) generated (guide auto-globs; no malformed markdown).
- `grep -F 'gateway subscription core' .planning/PROJECT.md` → hit (D-13 holdout cleared).
- `! grep -E 'on the table\*\* is \*\*entitlements' accrue/guides/jobs_to_be_done.md` → flip-guard phrase removed.
- `git ls-files accrue/guides/jobs_to_be_done.md` → tracked (Pitfall 3 satisfied).
- All three needles present in entitlements.md; `6 of 6` present in JTBD-FRONTIER.md.
- Out-of-scope files `maturity-and-maintenance.md` and `SEED-002` confirmed untouched.

## Commits

- `e2a321a` — docs(126-03): add guides/entitlements.md (fail-closed-first, summarize-and-link)
- `3bab780` — docs(126-03): flip JTBD entitlements gap->shipped in both artifacts
- `22cdbab` — docs(126-03): add entitlements spine pointers + PROJECT.md gateway-subscription-core parity (D-13)

## Self-Check: PASSED

All created files (entitlements.md, 126-03-SUMMARY.md), all 5 modified files, and all 3 task commits (e2a321a, 3bab780, 22cdbab) verified present on disk and in git history.
